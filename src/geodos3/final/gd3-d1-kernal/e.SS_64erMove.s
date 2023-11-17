; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "64erMove"
			c "ScrSaver64  V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o LD_ADDR_SCRSAVER

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Bildschirmschoner für GeoDOS..."
endif
if Sprache = Englisch
			h "Screensaver for GeoDOS..."
endif

;*** ScreenSaver aufrufen.
:MainInit		jmp	InitScreenSaver

;*** ScreenSaver installieren.
;    Laufwerk von dem ScreenSaver geladen wurde muß noch aktiv sein!
;    Rückgabe eines Fehlers im xReg ($00=Kein Fehler).
;    ACHTUNG! Nur JMP-Befehl oder "LDX #$00:RTS", da direkt im Anschluß
;    der Name des ScreenSavers erwartet wird! (Addr: G3_ScrSave +6)
:InstallSaver		jmp	FindFreeBank

;*** Name des ScreenSavers.
;    Direkt nach dem JMP-Befehl, da über GD.CONFIG der Name
;    an dieser Stelle ausgelesen wird.
;    Der Name muss mit dem Dateinamen übereinstimmen, da der
;    Bildschirmschoner über diesen Namen beim Systemstart geladen wird.
:SaverName		b "64erMove",NULL

;*** ScreenSaver aufrufen.
:InitScreenSaver	jsr	FindFreeBank		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;64K-Bank gefunden ?
			beq	:50			; => Ja, weiter...
			lda	#%10000000		;Bildschirmschoner abschalten,
			sta	Flag_ScrSaver		;da kein RAM frei ist...
			rts

::50			sty	RAM_BANK		;Bank für Zwischenspeicher setzen.

			php				;IRQ sperren.
			sei				;Screener läuft in der MainLoop!

			ldx	#$1f			;Register ":r0" bis ":r3"
::51			lda	r0L,x			;zwischenspeichern.
			pha
			dex
			bpl	:51

			jsr	SaveRamData

			jsr	i_MoveData
			w	ScrSaverCode
			w	$0a00
			w	EndSaverCode - ScrSaverCode

			lda	RAM_BANK
			jsr	$0a00			;Bildschirmschoner aktivieren.

			jsr	LoadRamData

			lda	#%01000000		;Bildschirmschoner neu starten.
			sta	Flag_ScrSaver

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

;*** Freie 64K-Speicherbank suchen.
;Rückgabe: xReg = Fehlermeldung.
;          yReg = Speicherbank.
:FindFreeBank		ldy	#$00
::51			jsr	GetBankByte
			beq	:52
			iny
			cpy	ramExpSize
			bne	:51
			ldx	#NO_FREE_RAM
			rts

::52			ldx	#NO_ERROR
			rts

;*** Tabellenwert für Speicherbank finden.
:GetBankByte		tya
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			pha
			tya
			and	#%00000011
			tax
			pla
::51			cpx	#$00
			beq	:52
			asl
			asl
			dex
			bne	:51
::52			and	#%11000000
			rts

;*** Variablen für 64K-Speicher.
:RAM_BANK		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_SCRSAVER + R2_SIZE_SCRSAVER -1
;******************************************************************************
