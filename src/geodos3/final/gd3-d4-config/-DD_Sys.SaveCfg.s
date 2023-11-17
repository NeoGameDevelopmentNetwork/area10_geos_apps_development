; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Name Laufwerkstreiber kopieren.
:SaveDrvAppName		lda	curDrive		;Startlaufwerk zwischenspeichern.
			sta	GD_APPDRV_DEV

			ldy	#0
			lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			cmp	#$82			;PRG ?
			bne	:2			; => Nein, Dateieintrag ungültig.
			lda	dirEntryBuf +21		;GEOS/SEQ-Datei ?
			bne	:2			; => Nein, Dateieintrag ungültig.
			lda	dirEntryBuf +22		;GEOS-Dateityp einlesen.
			cmp	#APPLICATION		;Anwendung ?
			beq	:1			; => Ja, weiter...
			cmp	#AUTO_EXEC		;AUTO_EXEC ?
			bne	:2			; => Nein, Dateieintrag ungültig.

::1			lda	dirEntryBuf +3,y	;Dateiname kopieren.
			cmp	#$a0			;Ende erreicht ?
			beq	:2			; => Ja, weiter...
			sta	GD_APPDRV_NAME,y
			iny
			cpy	#16			;Dateiname kopiert ?
			bcc	:1			; => Nein, weiter...

::2			lda	#$00			;Rest des Zwischenspeichers für
			sta	GD_APPDRV_NAME,y	;Dateiname löschen.
			iny
			cpy	#17
			bcc	:2
			rts

;*** Laufwerksdaten speichern.
:UpdateDskDrvData	lda	GD_APPDRV_DEV
			beq	:exit
			cmp	DrvAdrGEOS
			beq	:exit

			ldx	GD_APPDRV_NAME
			beq	:exit

;			lda	GD_APPDRV_DEV
			jsr	SetDevice
			txa
			bne	:error

			jsr	OpenDisk
			txa
			bne	:error

			LoadW	r6,GD_APPDRV_NAME
			jsr	FindFile
			txa
			bne	:error

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:error

			ldy	#0
::1			lda	DDRV_VAR_START,y
			sta	diskBlkBuf +2 +(DDRV_VAR_START - BASE_DDRV_DATA_NG),y
			iny
			cpy	#DDRV_VAR_SIZE
			bcc	:1

			jsr	PutBlock
			txa
			beq	:exit

::error			LoadW	r0,:dlg_SaveCfgErr
			jsr	DoDlgBox

::exit			lda	DrvAdrGEOS
			jsr	SetDevice

			rts

;--- Dialogbox: Konfiguration konnte nicht gespeichert werden.
::dlg_SaveCfgErr	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DlgBoxTitle
			b DBTXTSTR   ,$0c,$20
			w :t01
			b DBTXTSTR   ,$0c,$2a
			w :t02
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::t01			b "Die Konfiguration konnte",NULL
::t02			b "nicht aktualisiert werden!",NULL
endif

if Sprache = Englisch
::t01			b "Unable to update the",NULL
::t02			b "driver configuration!",NULL
endif

;*** Name Laufwerkstreiberdatei.
;Wird benötigt wenn die Datei vom
;DeskTop aus gestartet wird um die
;Einstellungen zu speichern.
:GD_APPDRV_DEV		b $00
:GD_APPDRV_NAME		s 17
