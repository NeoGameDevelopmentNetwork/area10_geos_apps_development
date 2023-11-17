; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prüfen ob Laufwerk installiert werden kann.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk kann installiert werden.
:INIT_DEV_TEST		ldx	#NO_ERROR
			txa
			tay
			rts

;*** Laufwerk installieren.
;    Übergabe:		AKKU = Laufwerkmodus.
;			xReg = Laufwerksadresse.
;    Rückgabe:		xReg = $00, Laufwerk installiert.
;			     = $0D, Laufwerkstyp nicht verfügbar.
:INIT_DEV_INSTALL	pha				;Laufwerksdaten speichern.
			and	#%00111111
			sta	DrvMode
			pla
			and	#%10000000
			sta	FastPPmode
			stx	DrvAdrGEOS

			jsr	DskDev_Prepare		;Treiber temporär installieren.

;--- Angeschlossenes Laufwerk testen.
::51			lda	DrvAdrGEOS		;Aktuelles Laufwerk feststellen.
			jsr	a_TestDriveType
			cpx	#NO_ERROR		;Installationsfehler ?
			bne	:53			; => Ja, Abbruch...
			eor	DrvMode			;Laufwerkstyp erkannt ?
			beq	:56			; => Ja, weiter...
			and	#%11110000		;CMD-Laufwerk angeschlossen ?
			beq	:56			; => Ja, Laufwerk installieren.
							;    Hier stimmt nur das Partitions-
							;    format nicht. Dieses wird von
							;    ":OpenDisk" aktiviert.
;--- Kompatibles Laufwerk suchen.
::53			lda	DrvMode
			and	#%11110000		;CMD-HD-Laufwerkskennung isolieren.
			ldy	DrvAdrGEOS
			jsr	a_FindDrive		;15x1-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:56			; => Ja, weiter...

			lda	DrvAdrGEOS
			jsr	a_TurnOnNewDrive	;Dialogbox ausgeben.
			txa				;Lauafwerk eingeschaltet ?
			beq	:53			; => Ja, Laufwerk suchen...

;--- Kein passendes Laufwerk gefunden.
::55			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk installieren.
::56			lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	DskDev_Prepare		;Treiber installieren.

			ldx	DrvAdrGEOS		;Laufwerksdaten setzen.
			lda	DrvMode
			and	#%00001111
			sta	driveType -8,x
			sta	curType
			txa				;Aktuelles Laufwerk feststellen.
			jsr	a_TestDriveType
			cpx	#NO_ERROR		;Installationsfehler ?
			bne	:55			; => Ja, Abbruch...
			tya
			ldx	DrvAdrGEOS		;Laufwerksdaten setzen.
			and	#%11110000
			ora	curType
			sta	RealDrvType -8,x
			sta	DDRV_SYS_DEVDATA + (diskDrvType - DISK_BASE)

			ldy	#SET_MODE_PARTITION
			lda	RealDrvType -8,x
			and	#%00001111
			cmp	#DrvNative
			bne	:58
			tya
			ora	#SET_MODE_SUBDIR
			tay
::58			tya
			sta	RealDrvMode -8,x

;--- Parallelkabel testen.
			bit	FastPPmode
			bpl	:61
			jsr	TestHDcable		;Auf PP-Kabel testen.
			bne	:61			; => Kein PP-Kabel, Ende...

			jsr	i_MoveData		;Laufwerkstreiber für FF-Kabel
			w	HD_PP			;aktivieren.
			w	DISK_BASE
			w	SIZE_DDRV_DATA

			ldx	DrvAdrGEOS
			lda	RealDrvMode -8,x
			ora	#SET_MODE_FASTDISK
			sta	RealDrvMode -8,x

;--- Laufwerkstreiber speichern.
::61			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Ende, kein Fehler...
			ldx	#NO_ERROR
			rts

;*** Laufwerk deinstallieren.
;    Übergabe:		xReg = Laufwerksadresse.
:INIT_DEV_REMOVE	stx	DrvAdrGEOS

;			ldx	DrvAdrGEOS
;			jsr	DskDev_Unload		;RAM-Speicher freigeben.

;			ldx	DrvAdrGEOS
			jmp	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

;Reference: "Serial bus control codes"
;https://codebase64.org/doku.php?id=base:how_the_vic_64_serial_bus_works
;$20-$3E : LISTEN  , device number ($20 + device number #0-30)
;$3F     : UNLISTEN, all devices
;$40-$5E : TALK    , device number ($40 + device number #0-30)
;$5F     : UNTALK  , all devices
;$60-$6F : REOPEN  , channel ($60 + secondary address / channel #0-15)
;$E0-$EF : CLOSE   , channel ($E0 + secondary address / channel #0-15)
;$F0-$FF : OPEN    , channel ($F0 + secondary address / channel #0-15)

;*** Floppy-Befehl mit variabler Länge an Laufwerk senden.
;    Übergabe:		AKKU	= Low -Byte, Zeiger auf Floppy-Befehl.
;			xReg	= High-Byte, Zeiger auf Floppy-Befehl.
;			yReg	= Länge (Zeichen) Floppy-Befehl.
;    Rückgabe:    Z-Flag = 1: OK
;                 Z-Flag = 0: Fehler
;                 xReg   = Fehler-Status
:SendComVLen		sta	:51 +1			;Zeiger auf Floppy-Befehl sichern.
			stx	:51 +2
			sty	:52 +1

;			jsr	UNTALK			;Aufruf durch ":initDevLISTEN".

			jsr	initDevLISTEN		;Laufwerk auf Empfang schalten.
			bne	:53			;Fehler? => Ja, Abbruch...

			ldy	#$00
::51			lda	$ffff,y			;Bytes an Floppy-Laufwerk senden.
			jsr	CIOUT
			iny
::52			cpy	#$ff
			bcc	:51

			ldx	#NO_ERROR
::53			rts

;*** Laufwerk auf Empfang schalten.
;Rückgabe: Z-Flag = 1: OK
;          Z-Flag = 0: Fehler
:initDevLISTEN		jsr	UNLSN			;Laufwerk abschalten.

			jsr	:startLISTEN		;Laufwerk aktivieren.
			beq	:exitLISTEN		;OK? => Ja, Ende.
							;Nein, zweiter Versuch...

::startLISTEN		ClrB	STATUS			;Status-Byte löschen.

			lda	curDevice		;Laufwerksadresse verwenden.
			jsr	LISTEN			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	#15 ! %01100000		;Befehlskanal -> "REOPEN".
			jsr	SECOND			;Laufwerk auf Empfang schalten.
			ldx	STATUS			;Fehler aufgetreten ?
			beq	:exitLISTEN		; => Nein, Ende...

::error			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#DEV_NOT_FOUND
::exitLISTEN		rts
