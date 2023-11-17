; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if Flag64_128 = TRUE_C64
;*** Beliebige Datei laden.
:xGetFile		jsr	TestPrntFile		;Druckertreiber laden ?
			beq	xLdPrnDrvRAM		;Ja, weiter...

			jsr	SaveFileData		;Datei-Informationen sichern.

			jsr	FindFile		;Datei-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	RTS_01			;Ja, Abbruch...

			jsr	LoadFileData		;Datei-Informationen einlesen.

			lda	#>dirEntryBuf		;Zeiger auf Datei-Eintrag.
			sta	r9H
			lda	#<dirEntryBuf
			sta	r9L

			lda	dirEntryBuf+22		;Dateityp einlesen.
			cmp	#$05			;Hilfsmittel starten ?
			beq	:4			;Ja, weiter...
::1			cmp	#$06			;Applikation starten ?
			beq	:2			;Ja, weiter...
			cmp	#$09			;Druckertreiber ?
			beq	xLdPrnDrv		;Ja, weiter...
			cmp	#$0e			;AutoExec-Datei starten ?
			bne	:3			;Nein, weiter...
::2			jmp	LdApplic		;Applikation/AutoExec starten.
::3			jmp	LdFile
::4			jmp	LdDeskAcc

;*** Druckertreiber laden ?
;    Z-Flag gesetzt, dann Druckertreiber aus RAM laden.
:TestPrntFile		lda	Flag_LoadPrnt		;Druckertreiber aus RAM laden ?
			bne	RTS_01			;Nein, Ende...

			ldy	#$00			;Name des neuen Druckertreibers
::1			lda	(r6L)           ,y	;im Kernal vergleichen.
			cmp	PrntFileNameRAM ,y
			bne	RTS_01			; => Z=0, Falscher Name.
			tax
			beq	RTS_01			; => Z=1, Name identisch.
			iny
			cpy	#$10
			bne	:1			; => Z=1, Name identisch.
:RTS_01			rts

;*** Druckertreiber in RAM laden.
:xLdPrnDrv		ldy	#$03			;Name des neuen Druckertreibers
::1			lda	(r6L)             ,y	;im Kernal speichern.
			sta	PrntFileNameRAM -3,y
			beq	:2
			iny
			cpy	#$13
			bne	:1

::2			jsr	LdFile			;Druckertreiber von Disk laden.

;--- Ergänzung: 30.12.18/M.Kanet
;Größe des Spoolers und Druckertreiber im RAM um 1Byte reduziert.
;geoCalc64 nutzt beim Drucken ab $$5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert. Wird der gesamte Speicher
;getauscht führt das zum Absturz in geoCalc.
;SetADDR_Printer und SetADDR_PrnSpool dürfen max. bis $7F3E reichen.
;Siehe auch Datei "-G3_SetVecRAM".
			jsr	SetADDR_Printer		;Druckertreiber und fileHeader
			jsr	StashRAM		;in REU speichern.
			jsr	SetADDR_PrntHdr
			jsr	StashRAM

;******************************************************************************
;  ACHTUNG!!! MP3 muß hier fortfahren, auch wenn der aktive Treiber zu diesem
;  Zeitpunkt bereits geladen wurde! Ist der Spooler aktiv, so muß dieser hier
;  an Stelle des Original-Druckertreibers geladen werden!!!
;******************************************************************************

;*** Druckertreiber laden.
:xLdPrnDrvRAM		lda	Flag_Spooler
			bmi	xLdPrnSpoolRAM

			jsr	SetADDR_Printer		;Druckertreiber und fileHeader
			jsr	FetchRAM		;aus REU einlesen.
			jsr	SetADDR_PrntHdr
			jmp	FetchRAM		;xReg = $00, Kein Fehler,
							;wird bei StashRAM gesetzt.
;*** Druckertreiber laden.
:xLdPrnSpoolRAM		jsr	SetADDR_PrnSpool	;Druckertreiber und fileHeader
			jsr	FetchRAM		;aus REU einlesen.
			jsr	SetADDR_PrntHdr
			jmp	FetchRAM		;xReg = $00, Kein Fehler,
							;wird bei StashRAM gesetzt.
endif

if Flag64_128 = TRUE_C128
;*** Beliebige Datei laden.
:xGetFile		jsr	TestPrntFile		;Druckertreiber laden ?
			beq	xLdPrnDrvRAM		;Ja, weiter...

			jsr	SaveFileData		;Datei-Informationen sichern.

			jsr	FindFile		;Datei-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	RTS_01			;Ja, Abbruch...

			jsr	LoadFileData		;Datei-Informationen einlesen.

			lda	#>dirEntryBuf		;Zeiger auf Datei-Eintrag.
			sta	r9H
			lda	#<dirEntryBuf
			sta	r9L

			lda	dirEntryBuf+22		;Dateityp einlesen.
			cmp	#$05			;Hilfsmittel starten ?
			beq	:4			;Ja, weiter...
::1			cmp	#$06			;Applikation starten ?
			beq	:2			;Ja, weiter...
			cmp	#$09			;Druckertreiber ?
			beq	xLdPrnDrv		;Ja, weiter...
			cmp	#$0e			;AutoExec-Datei starten ?
			bne	:3			;Nein, weiter...
::2			jmp	LdApplic		;Applikation/AutoExec starten.
::3			jmp	LdFile
::4			jmp	LdDeskAcc

;*** Druckertreiber laden ?
;    Z-Flag gesetzt, dann Druckertreiber aus RAM laden.
:TestPrntFile		lda	sysRAMFlg		;Druckertreiber bereits im C128-RAM?
			and	#$10
			bne	:1			;>ja
			lda	#1			;>nein evtl. von Disk laden
			rts

::1			lda	r6H
			cmp	#>PrntFileName		;vergleiche Pointer r6 mit
			bne	RTS_01			;Adresse 'PrntFileName'
			lda	r6L
			sec
			sbc	#<PrntFileName
			ora	r0L
:RTS_01			rts

;*** Druckertreiber in RAM laden.
:xLdPrnDrv		ldy	#3			;Name des neuen Druckertreibers
::1			lda	(r6L),y			;im Kernal speichern.
			sta	PrntFileName-3,y
			beq	:2
			iny
			cpy	#16+3
			bne	:1

::2			jsr	LdFile			;Druckertreiber von Disk laden.
			jsr	SetADDR_Printer		;Druckertreiber und fileHeader
			jsr	SetR3
			jsr	SwapBData		;ins 128er RAM
			jsr	SetADDR_PrntHdr
			jsr	SetR3
			jsr	SwapBData
			lda	sysRAMFlg
			ora	#%00010000
			sta	sysRAMFlg

;******************************************************************************
;  ACHTUNG!!! MP3 muß hier fortfahren, auch wenn der aktive Treiber zu diesem
;  Zeitpunkt bereits geladen wurde! Ist der Spooler aktiv, so muß dieser hier
;  an Stelle des Original-Druckertreibers geladen werden!!!
;******************************************************************************

;*** Druckertreiber laden.
:xLdPrnDrvRAM		lda	Flag_Spooler
			bmi	xLdPrnSpoolRAM

			jsr	SetADDR_Printer		;Druckertreiber
			jsr	xDoMoveBData		;von $d9c0 nach $7900 verschieben
			jmp	xLdPrnHdr		;InfoBlock des Druckertreibers laden

:xLdPrnSpoolRAM		jsr	SetADDR_PrnSpool
			jsr	FetchRAM

:xLdPrnHdr		jsr	SetADDR_PrntHdr		;InfoBlock des Druckertreibers laden
:xDoMoveBData		jsr	SetR3			;MoveBData muß verwendet werden
			jsr	MoveBData		;da Startbereich unter IO-Bereich!
			ldx	#$00			;OK Kennzeichen
			rts

:SetR3			lda	#1			;Start-Bank und Ziel-Bank = Bank 1
			sta	r3L
			sta	r3H
			rts
endif

;*** Datei laden.
:xLdFile		jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	LdFileExit		;Ja, Abbruch.

			ldy	fileHeader+$46		;Dateistruktur einlesen.
			dey				;VLIR-Datei ?
			bne	:1			;Nein, weiter...

			iny				;VLIR-Header einlesen.
			lda	(r9L),y
			sta	r1L
			iny
			lda	(r9L),y
			sta	r1H
			jsr	GetBlock_dskBuf		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	LdFileExit		;Ja, Abbruch...

			ldx	#$08			;Zeiger auf ersten Datensatz.
			lda	diskBlkBuf +2
			sta	r1L
			beq	LdFileExit		;Fehler, RECORD NOT THERE.

			lda	diskBlkBuf +3
			sta	r1H

::1			lda	LoadFileMode
			lsr				;Programm starten ?
			bcc	:2			;Ja, weiter...

			lda	LoadBufAdr+1		;Ladeadresse setzen.
			sta	r7H
			lda	LoadBufAdr+0
			sta	r7L

::2			lda	#$ff
			sta	r2L
			sta	r2H
			jmp	ReadFile		;Datei laden.
:LdFileExit		rts

;*** Anwendung starten.
:xLdApplic		jsr	SaveFileData		;Programmdaten speichern.

if Flag64_128 = TRUE_C128
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	LdFileExit		;Ja, Abbruch.
			jsr	TestgraphMode		;Korrekter Bildschirmmodus?
			bne	LdFileExit		;>nein, Abbruch
endif
			jsr	LdFile			;Datei laden.
			txa				;Diskettenfehler ?
			bne	LdFileExit		;Ja, Abbruch...

			lda	LoadFileMode
			lsr				;Programm starten ?
			bcs	LdFileExit		;Nein, weiter...

			jsr	LoadFileData		;Variablen wieder einlesen.

			lda	fileHeader+$4b
			sta	r7L
			lda	fileHeader+$4c
			sta	r7H
			jmp	StartAppl		;Applikation starten.

if Flag64_128 = TRUE_C64
;*** Hilfsmittel einlesen.
:xLdDeskAcc		lda	r10L			;Bildschirm-Flag speichern.
			sta	DA_ResetScrn

			jsr	GetFHdrInfo		;Datei-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch.

			lda	r1H			;Zeiger auf ersten Sektor
			pha				;zwischenspeichern.
			lda	r1L
			pha

			lda	fileHeader      +$47
			sta	SetSwapFileData +  1
			lda	fileHeader      +$48
			sta	SetSwapFileData +  3

			lda	fileHeader      +$49
			sec
			sbc	fileHeader      +$47
			sta	SetSwapFileData + 13
			lda	fileHeader      +$4a
			sbc	fileHeader      +$48
			sta	SetSwapFileData + 15

			lda	Flag_ExtRAMinUse	;Zwischenspeicher für
			ora	#%10000000		;SwapFile sperren.
			sta	Flag_ExtRAMinUse

			jsr	SetSwapFileData		;Zeiger auf SwapFile-Bereich.
			bcs	:3
			jsr	StashRAM		;Speicher-Inhalt retten.

			pla
			sta	r1L
			pla
			sta	r1H

			jsr	GetLoadAdr		;Ladeadresse setzen.
			jsr	ReadFile		;DA einlesen.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch...

			jsr	SaveGEOS_Data		;GEOS-Variablen speichern.
			jsr	UseSystemFont		;GEOS initialisieren.

			jsr	GEOS_InitVar		;Kernel-Variablen initialisier.

			lda	DA_ResetScrn		;Bildschirm-Flag zurücksetzen.
			sta	r10L
			pla
			sta	DA_ReturnAdr+0		;LOW  -Byte Rücksprungadresse.
			pla
			sta	DA_ReturnAdr+1		;High -Byte Rücksprungadresse.
			tsx
			stx	DA_RetStackP		;Stackzeiger merken.

			ldx	fileHeader  +$4c
			lda	fileHeader  +$4b
			jmp	InitMLoop1		;Programm starten.
::1			ldx	#$0b
::2			rts
::3			pla
			pla
			rts
endif

if Flag64_128 = TRUE_C64
;*** DA beenden, zurück zur Applikation.
:xRstrAppl		jsr	SetSwapFileData		;Zeiger auf SwapFile-Bereich.
			jsr	FetchRAM		;Speicher-Inhalt zurücksetzen.

			lda	Flag_ExtRAMinUse	;Zwischenspeicher für
			and	#%01111111		;SwapFile wieder freigeben.
			sta	Flag_ExtRAMinUse

			jsr	LoadGEOS_Data		;GEOS-Variablen zurücksetzen.
			ldx	DA_RetStackP		;Rücksprungadresse wieder auf
			txs				;Stapel zurückschreiben.
			lda	DA_ReturnAdr +1
			pha
			lda	DA_ReturnAdr +0
			pha
			ldx	#$00			;Flag für "Kein Diskfehler!"
			rts

;*** Daten für SWAP-File definieren.
:SetSwapFileData	lda	#$ff			;Startadresse SwapFile für
			ldx	#$ff			;StashRAM/FetchRAM festlegen.
			sta	r0L			;(Wird berechnet!)
			stx	r0H
			sta	r1L
			stx	r1H

			lda	#$ff			;Anzahl Bytes festlegen.
			ldx	#$ff			;(Wird berechnet!)
			sta	r2L
			stx	r2H
			ldy	MP3_64K_DATA
			sty	r3L
			cpx	#> $7c00		;Größe für SwapFile testen.
			rts				;Speicher von $0400 - $8000,
							;Mehr ist nicht möglich!!!
endif

if Flag64_128 = TRUE_C128
;*** Hilfsmittel einlesen.
:xLdDeskAcc		lda	r10L			;Bildschirm-Flag speichern.
			sta	DA_ResetScrn

			jsr	GetFHdrInfo		;Datei-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch.

			jsr	TestgraphMode
			bne	:2

			lda	r1H			;Zeiger auf ersten Sektor
			pha				;zwischenspeichern.
			lda	r1L
			pha

			lda	fileHeader      +$47
			sta	SetSwapFileData +  1
			lda	fileHeader      +$48
			sta	SetSwapFileData +  3

			lda	fileHeader      +$49
			sec
			sbc	fileHeader      +$47
			sta	SetSwapFileData + 9
			lda	fileHeader      +$4a
			sbc	fileHeader      +$48
			sta	SetSwapFileData + 11

			lda	Flag_ExtRAMinUse	;Zwischenspeicher für
			ora	#%10000000		;SwapFile sperren.
			sta	Flag_ExtRAMinUse

			jsr	SetSwapFileData		;Zeiger auf SwapFile-Bereich.
			bcs	:3
			jsr	SwapBData		;Speicher-Inhalt retten.

			pla
			sta	r1L
			pla
			sta	r1H

			jsr	GetLoadAdr		;Ladeadresse setzen.
			jsr	ReadFile		;DA einlesen.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch...

			jsr	SaveGEOS_Data		;GEOS-Variablen speichern.
			jsr	UseSystemFont		;GEOS initialisieren.

			jsr	GEOS_InitVar		;Kernel-Variablen initialisier.
			jsr	SetNewModeInit		;40/80 Zeichen-Modus initialisieren

			lda	DA_ResetScrn		;Bildschirm-Flag zurücksetzen.
			sta	r10L
			pla
			sta	DA_ReturnAdr+0		;LOW  -Byte Rücksprungadresse.
			pla
			sta	DA_ReturnAdr+1		;High -Byte Rücksprungadresse.
			tsx
			stx	DA_RetStackP		;Stackzeiger merken.

			ldx	fileHeader  +$4c
			lda	fileHeader  +$4b
			jmp	InitMLoop1		;Programm starten.
::1			ldx	#$0b
::2			rts
::3			pla
			pla
			rts
endif

if Flag64_128 = TRUE_C128
;*** DA beenden, zurück zur Applikation.
:xRstrAppl		jsr	SetSwapFileData		;Zeiger auf SwapFile-Bereich.
			jsr	SwapBData		;Speicher-Inhalt zurücksetzen.

			lda	Flag_ExtRAMinUse	;Zwischenspeicher für
			and	#%01111111		;SwapFile wieder freigeben.
			sta	Flag_ExtRAMinUse

			jsr	LoadGEOS_Data		;GEOS-Variablen zurücksetzen.
			ldx	DA_RetStackP		;Rücksprungadresse wieder auf
			txs				;Stapel zurückschreiben.
			lda	DA_ReturnAdr +1
			pha
			lda	DA_ReturnAdr +0
			pha
			ldx	#$00			;Flag für "Kein Diskfehler!"
			rts

;*** Daten für SWAP-File definieren.
:SetSwapFileData	lda	#$ff			;Startadresse SwapFile für
			ldx	#$ff			;SwapBData festlegen.
			sta	r0L			;(Wird berechnet!)
			stx	r0H

			lda	#$ff			;Anzahl Bytes festlegen.
			ldx	#$ff			;(Wird berechnet!)
			sta	r2L
			stx	r2H
			ldy	#0
			sty	r3H			;Zielbank setzen (Bank 0)
			sty	r1L
			iny
			sty	r3L			;Startbank setzen (Bank 1)
			LoadB	r1H,$20			;r0 = $2000
			cpx	#> $6000		;Größe für SwapFile testen.
			rts
endif

;*** Variablen zurückschreiben.
;    Aufruf durch ":StartAppl",
;    ":GetFile" und ":LdApplic".
:LoadFileData		lda	DA_ResetScrn		;SCREEN-Flag zurücksetzen.
			sta	r10L

			lda	LoadFileMode		;Modus für GetFile setzen.
			sta	r0L
			lsr				;Ladeadresse angegeben ?
			bcc	:1			;Nein, weiter...

			lda	LoadBufAdr +0		;Ladeadresse zurücksetzen.
			sta	r7L
			lda	LoadBufAdr +1
			sta	r7H

::1			lda	#<dataDiskName		;Zeiger auf Diskettenname.
			sta	r2L
			lda	#>dataDiskName
			sta	r2H
			lda	#<dataFileName		;Zeiger auf Dateiname.
			sta	r3L
			lda	#>dataFileName
			sta	r3H
:ExitFileData		rts

;*** Variablen zwischenspeichern.
;    Aufruf durch ":StartAppl",
;    ":GetFile" und ":LdApplic".
:SaveFileData		lda	r7L
			sta	LoadBufAdr +0
			lda	r7H
			sta	LoadBufAdr +1

			lda	r10L
			sta	DA_ResetScrn

			lda	r0L
			sta	LoadFileMode
			and	#%11000000		;Datenfile nachladen bzw.
			beq	ExitFileData		;ausdrucken ? Nein, weiter...

			ldy	#>dataDiskName		;Diskettenname retten.
			lda	#<dataDiskName
			ldx	#r2L
			sty	r4H			;Datei-/Diskname retten.
			sta	r4L
			ldy	#r4L
			lda	#18
			jsr	CopyFString		;String kopieren.

			ldy	#>dataFileName		;Dateiname retten.
			lda	#<dataFileName
			ldx	#r3L
			sty	r4H			;Datei-/Diskname retten.
			sta	r4L
			ldy	#r4L
			lda	#17
			jmp	CopyFString		;String kopieren.
