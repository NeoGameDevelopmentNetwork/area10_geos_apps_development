; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Name Laufwerkstreiber kopieren.
:SaveDrvAppName		ldx	curDrive		;Startlaufwerk zwischenspeichern.
			stx	GD_APPDRV_DEV

			lda	RealDrvType -8,x	;Laufwerkstyp zwischenspeichern.
			sta	GD_APPDRV_TYPE

			ldy	#$00			;Aktive Partition auf CMD-
			lda	RealDrvMode -8,x	;Laufwerken zwischenspeichern.
			and	#SET_MODE_PARTITION
			beq	:1
			ldy	drivePartData -8,x
::1			sty	GD_APPDRV_PART

;--- Dateityp auf Gültigkeit testen.
			ldy	#0
			lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			cmp	#$82			;PRG ?
			bne	:2			; => Nein, Dateieintrag ungültig.
			lda	dirEntryBuf +21		;GEOS/VLIR-Datei ?
			bne	:2			; => Ja, Dateieintrag ungültig.
			lda	dirEntryBuf +22		;GEOS-Dateityp einlesen.
			cmp	#DISK_DEVICE		;Laufwerkstreiber ?
			bne	:3			; => Nein, Dateieintrag ungültig.

;--- Dateiname Laufwerkstreiber kopieren.
::2			lda	dirEntryBuf +3,y	;Dateiname kopieren.
			cmp	#$a0			;Ende erreicht ?
			beq	:3			; => Ja, weiter...
			sta	GD_APPDRV_NAME,y
			iny
			cpy	#16			;Dateiname kopiert ?
			bcc	:2			; => Nein, weiter...

;-- Rest Dateiname mit $00 löschen.
::3			lda	#$00			;Rest des Zwischenspeichers für
::4			sta	GD_APPDRV_NAME,y	;Dateiname löschen.
			iny
			cpy	#17
			bcc	:4
			rts

;*** Laufwerksdaten speichern.
:UpdDDrvFile		ldx	GD_APPDRV_DEV		;Laufwerk gültig ?
			beq	:no_update		; => Nein, Ende...

			lda	GD_APPDRV_NAME		;Dateiname gültig ?
			beq	:no_update		; => Nein, Ende...

			lda	GD_APPDRV_TYPE
			cmp	RealDrvType -8,x	;Laufwerk geändert ?
			bne	:no_update		; => Ja, Ende...

;			lda	GD_APPDRV_DEV
			txa
			jsr	SetDevice		;Treiber-Laufwerk aktivieren.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch..

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch..

			ldx	curDrive
			lda	RealDrvMode -8,x
			and	#SET_MODE_PARTITION
			beq	:search

			lda	drivePartData -8,x
			cmp	GD_APPDRV_PART		;Partition gewechselt ?
			bne	:exit			; => Ja, Abbruch...

::search		LoadW	r6,GD_APPDRV_NAME
			jsr	FindFile		;Laufwerkstreiber suchen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch..

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Konfigurationsbereich einlesen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch..

			ldy	#0
::1			lda	DDRV_VAR_START,y
			sta	diskBlkBuf +2 +(DDRV_VAR_START - BASE_DDRV_DATA),y
			iny
			cpy	#DDRV_VAR_SIZE
			bcc	:1

			jsr	PutBlock		;Konfigurationsbereich speichern.
			txa				;Fehler ?
			beq	:exit			; => Nein, weiter...

::error			LoadW	r0,:dlg_SaveCfgErr
			jsr	DoDlgBox		;Fehler ausgeben.

::exit			lda	DrvAdrGEOS		;Neues Laufwerk wieder aktivieren.
			jsr	SetDevice

;--- Keine Fehlerauswertung.
::no_update		rts				;Ende...

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

if LANG = LANG_DE
::t01			b PLAINTEXT
			b "Die Konfiguration konnte",NULL
::t02			b "nicht gespeichert werden!",NULL
endif

if LANG = LANG_EN
::t01			b PLAINTEXT
			b "Unable to update the",NULL
::t02			b "driver configuration!",NULL
endif

;*** Name Laufwerkstreiberdatei.
;Wird benötigt wenn die Datei vom
;DeskTop aus gestartet wird um die
;Einstellungen zu speichern.
:GD_APPDRV_DEV		b $00
:GD_APPDRV_NAME		s 17
:GD_APPDRV_TYPE		b $00
:GD_APPDRV_PART		b $00
:flgUpdDDrvFile		b $00
