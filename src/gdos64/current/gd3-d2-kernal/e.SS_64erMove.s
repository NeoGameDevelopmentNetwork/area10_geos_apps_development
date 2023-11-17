; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "SymbTab_GERR"
			t "SymbTab_MMAP"
			t "MacTab"

;--- Externe Labels:
			t "o.SS_64erMov.ext"
endif

;*** GEOS-Header.
			n "64erMove"
			c "ScrSaver64  V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o LOAD_SCRSAVER

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Bildschirmschoner für GDOS64..."
endif
if LANG = LANG_EN
			h "Screensaver for GDOS64..."
endif

;*** ScreenSaver aufrufen.
:MainInit		jmp	InitScreenSaver

;*** ScreenSaver installieren.
;Das Laufwerk, von welchem ScreenSaver
;geladen wurde, muss noch aktiv sein!
;Rückgabe eines Installationsfehlers
;im xReg ($00=Kein Fehler).
;ACHTUNG!
;Nur JMP-Befehl oder "LDX #$00:RTS",
;da direkt im Anschluss der Name des
;ScreenSavers erwartet wird!
;(Addresse: LOAD_SCRSAVER +6)
:InstallSaver		jmp	DACC_FIND_BANK		;Freie Speicherbank suchen.

;*** Name des ScreenSavers.
;Direkt nach dem JMP-Befehl, da über
;GD.CONFIG der Name an dieser Stelle
;ausgelesen wird.
;Der Name muss mit dem Dateinamen
;übereinstimmen, da der ScreenSaver
;über diesen Namen beim Systemstart
;geladen wird.
:SaverName		b "64erMove",NULL

;*** ScreenSaver aufrufen.
:InitScreenSaver	jsr	DACC_FIND_BANK		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;64K-Bank gefunden ?
			beq	:50			; => Ja, weiter...
			lda	#%10000000		;Bildschirmschoner abschalten,
			sta	Flag_ScrSaver		;da kein RAM frei ist...
			rts

::50			sty	RAM_BANK		;Bank für Zwischenspeicher setzen.

			php				;IRQ sperren.
			sei				;ScreenSaver läuft in der MainLoop!

			ldx	#$1f			;Register ":r0" bis ":r3"
::51			lda	r0L,x			;zwischenspeichern.
			pha
			dex
			bpl	:51

			lda	RAM_BANK		;Freie Speicherbank einlesen.
			ldx	#%11000000		;Bank-Typ: System.
			jsr	DACC_ALLOC_BANK		;Speicher reservieren.

			jsr	SaveRamData

			jsr	i_MoveData
			w	ScrSaverCode
			w	BASE_SV64MOVE
			w	EndSaverCode - ScrSaverCode

			lda	RAM_BANK
			jsr	BASE_SV64MOVE		;Bildschirmschoner aktivieren.

			jsr	LoadRamData

			lda	#%01000000		;Bildschirmschoner neu starten.
			sta	Flag_ScrSaver

			lda	RAM_BANK		;Reservierte Speicherbank.
			jsr	DACC_FREE_BANK		;Speicher wieder freigeben.

			ldx	#$00			;Register ":r0" bis ":r3"
::52			pla				;zurückschreiben.
			sta	r0L,x
			inx
			cpx	#$20
			bne	:52

			sei				;IRQ abschalten.
			ldx	CPU_DATA		;CPU-Register zwischenspeichern und
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

::53			lda	#$00
			sta	$dc00			;Tastenregister aktivieren.
			lda	$dc01			;Tastenstatus einlesen.
			eor	#$ff			;Taste noch gedrückt ?
			bne	:53			;Ja, Warteschleife...

			lda	$d011
			ora	#%00010000
			sta	$d011

			stx	CPU_DATA		;CPU-Register zurücksetzen.
			plp				;IRQ zurücksetzen und
			rts

;*** GEOS-Kernel zwischenspeichern.
:SaveRamData		jsr	SetRamVec1		;Zeiger auf $0400-$BFFF setzen.
			jsr	StashRAM		;Speicher in REU sichern.

;--- Ergänzung: 20.07.18/M.Kanet
;Um den Speicher unterhalb des I/O-Bereichs zu sichern muss
;CPU_DATA auf $30 gesetzt werden.
			php				;Prozessor-Status speichern.
			sei
			lda	CPU_DATA		;CPU-Register zwischenspeichern und
			pha				;64KRAM-Bereich einblenden.
			lda	#$30
			sta	CPU_DATA

;--- Ergänzung: 20.07.18/M.Kanet
;Die bisherige i_MoveData Routine wurde durch eine manuelle Routine
;ersetzt um evtl. Probleme mit einer REU/MOVE_DATA zu umgehen.
			jsr	SetRamVec2		;Zeiger auf $C000-$FFFF setzen.

			ldy	#$00			;Speicher von $C000-$FFFF nach
::51			lda	(r1L),y			;$2000 kopieren um den Bereich
			sta	(r0L),y			;später in die REU zu kopieren.
			iny
			bne	:51
			inc	r0H
			inc	r1H
			dec	r2H
			bne	:51

;--- Ergänzung: 20.07.18/M.Kanet
;CPU_DATA zurücksetzen.
			pla				;CPU-Register und Prozessorstatus
			sta	CPU_DATA		;wieder herstellen.
			plp

			jsr	SetRamVec2		;Zeiger auf $C000-$FFFF setzen.
			jmp	StashRAM		;Speicher in REU sichern.

;*** GEOS-Kernel wieder einlesen.
:LoadRamData		jsr	SetRamVec2		;Zeiger auf $C000-$FFFF setzen.
			jsr	FetchRAM		;Speicher aus REU zurücksetzen.

;--- Ergänzung: 20.07.18/M.Kanet
;Um den Speicher unterhalb des I/O-Bereichs wieder herzustellen muss
;CPU_DATA auf $30 gesetzt werden.
			php				;Prozessor-Status speichern.
			sei
			lda	CPU_DATA		;CPU-Register zwischenspeichern und
			pha				;64KRAM-Bereich einblenden.
			lda	#$30
			sta	CPU_DATA

			jsr	SetRamVec2		;Zeiger auf $C000-$FFFF setzen.

			ldy	#$00			;Speicher von $2000-$5FFF zurück
::51			lda	(r0L),y			;nach $C000-$FFFF kopieren.
			sta	(r1L),y
			iny
			bne	:51
			inc	r0H
			inc	r1H
			dec	r2H
			bne	:51

;--- Ergänzung: 20.07.18/M.Kanet
;CPU_DATA zurücksetzen.
			pla				;CPU-Register und Prozessorstatus
			sta	CPU_DATA		;wieder herstellen.
			plp

			jsr	SetRamVec1		;Zeiger auf $0400-$BFFF setzen.
			jmp	FetchRAM		;Speicher aus REU zurücksetzen.

;*** Zeiger auf Kernelspeicher setzen.
:SetRamVec1		LoadW	r0 ,$0400
			LoadW	r1 ,$0400
			LoadW	r2 ,$bc00
			lda	RAM_BANK
			sta	r3L
			rts

:SetRamVec2		LoadW	r0 ,$2000
			LoadW	r1 ,$c000
			LoadW	r2 ,$4000
			lda	RAM_BANK
			sta	r3L
			rts

;*** Grafikeffekt.
:ScrSaverCode		d "obj.SS_64erMove"
:EndSaverCode

;*** Speicherverwaltung.
			t "-DA_FindBank"
			t "-DA_FreeBank"
			t "-DA_AllocBank"
			t "-DA_GetBankByte"

;*** Variablen für 64K-Speicher.
:RAM_BANK		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_SCRSAVER + R2S_SCRSAVER -1
;******************************************************************************
