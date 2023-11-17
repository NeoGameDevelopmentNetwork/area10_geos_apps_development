; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Bootlaufwerk übernehmen.
:InitBootDevice		php				;IRQ sperren.
			sei

			lda	CPU_DATA
			pha
			lda	#KRNL_BAS_IO_IN		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA

			lda	#< DiskText		;"LAUFWERK:"
			ldy	#> DiskText
			jsr	ROM_OUT_STRING

			ldx	curDevice
			jsr	_SER_GETCURDRV		;Aktuelles Laufwerk testen.
			txa				;Laufwerksfehler ?
			beq	:ok			; => Nein, weiter...

			ldx	#DEV_NOT_FOUND		;Fehler: Laufwerk nicht erkannt.
			jmp	:exit			; => Abbruch...

::ok			ldx	curDevice		;Laufwerkstyp übernehmen.
			lda	_PRG_DEVTYPE -8,x
			sta	Boot_Type

;--- Auf CMD-Laufwerk testen.
;Bei CMD-Laufwerken ist der Emulations-
;Modus nicht gesetzt (Bit%0-3 = 0).
			and	#%00001111		;CMD-Laufwerk ?
			bne	:noCMD			; => Nein, weiter...

;--- CMD-Laufwerksdaten ermitteln.
;			lda	#$00			;Partitionsdaten löschen.
			sta	Boot_Part +0
			sta	Boot_Part +1

			lda	#$ff			;$FF = Aktive Partition.
			jsr	_SER_GETCMDPART		;Partitionsdaten einlesen.

			lda	devDataBuf +0		;Partitionsformat von CMD
			sec				;nach CBM wandeln.
			sbc	#1
			beq	:setNative
			cmp	#5
			bcc	:setMode
::setNative		lda	#DrvNative
::setMode		ora	Boot_Type		;Mit CMD-Laufwerk verbinden.
			sta	Boot_Type		;Laufwerkstyp speichern.

			ldx	devDataBuf +2		;Partitionsnummer merken.
			stx	Boot_Part +0

			and	#DrvCMD
			cmp	#DrvRAMLink		;Startlaufwerk = RAMLink ?
;			bne	:setDrive		; => Nein, weiter...
			bne	:noCMD

			lda	devDataBuf +20		;High-Byte der Startadresse für
			sta	Boot_Part +1		;Partition speichern.

;--- Geräteadresse speichern.
;Bereits im Hauptprogramm gespeichert.
;			lda	curDevice		;RL-Geräteadresse speichern.
;			sta	RL_BootAddr
;			cmp	#12			;Adresse #8 bis #11 ?
;			bcs	:noCMD			; => Nein, weiter...
;
;::setDrive		lda	curDevice		;Boot-Laufwerk speichern.
;			sta	Boot_Drive

;--- Auf SD2IEC testen...
::noCMD			lda	Boot_Type
			and	#%01000000		;SD2IEC-Laufwerk ?
			beq	:initMode		; => Nein, weitere...
			lda	Boot_Type
			and	#%10111111
			sta	Boot_Type
			lda	#SET_MODE_SD2IEC	;SD2IEC-Modus für RealDrvMode.
::initMode		sta	Boot_Mode		;Laufwerksmodus initialisieren.

;--- Laufwerkstreiber suchen.
::skip			LoadW	r0,DskDrvNames +17

			ldy	#1
::11			lda	DskDrvTypes,y		;Ende Tabelle erreicht ?
			beq	:error			; => Ja, Fehler...
			cmp	Boot_Type		;Laufwerkstreiber gefunden ?
			beq	:found			; => Ja, weiter...

			AddVBW	17,r0			;Zeiger auf nächsten Treiber.

			iny				;Tabelle durchsucht ?
			bne	:11			; => Nein, weiter...

::error			ldx	#DEV_NOT_FOUND		;Fehler: Laufwerk nicht erkannt.
			bne	:exit

;--- Name Laufwerkstreiber kopieren.
::found			lda	DskDrvModes,y		;Laufwerksmodus einlesen und
			ora	Boot_Mode		;zwischenspeichern.
			sta	Boot_Mode

			ldy	#0			;Name Laufwerkstreiber
::21			lda	(r0L),y			;übernehmen.
			beq	:22
			sta	FNamGDISK,y
			iny
			cpy	#16
			bcc	:21
			lda	#NULL
::22			sta	FNamGDISK,y
			iny
			cpy	#17
			bcc	:22

			lda	r0L
			ldy	r0H
			jsr	ROM_OUT_STRING		;Name Laufwerkstreiber ausgeben.

			ldx	#NO_ERROR		;Ende, Kein Fehler.

::exit			pla
			sta	CPU_DATA		;RAM-Konfiguration zurücksetzen.

			plp
			rts

;*** Systemtexte.
:DiskText		b CR
if LANG = LANG_DE
			b "LAUFWERK : "
endif
if LANG = LANG_EN
			b "DRIVE    : "
endif
			b NULL
