; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "64erMove"
			t "G3_SymMacExt"

			a "M. Kanet"
			f SYSTEM
			o LD_ADDR_SCRSAVER

			i
<MISSING_IMAGE_DATA>

if Flag64_128 = TRUE_C64
			c "ScrSaver64  V1.0"
			z $80				;nur GEOS64 bei MP3-64
endif

if Flag64_128 = TRUE_C128
			c "ScrSaver128 V1.0"
			z $40				;40 und 80 Zeichen-Modus bei MP3-128
endif

;*** ScreenSaver aufrufen.
:MainInit		jmp	InitScreenSaver

;*** ScreenSaver installieren.
;    Laufwerk von dem ScreenSaver geladen wurde muß noch aktiv sein!
;    Rückgabe eines Fehlers im xReg ($00=Kein Fehler).
;    ACHTUNG! Nur JMP-Befehl oder "LDX #$00:RTS", da direkt im Anschluß
;    der Name des ScreenSavers erwartet wird! (Addr: G3_ScrSave +6)
:InstallSaver		jmp	ChkInstallScrSv

;*** Name des ScreenSavers.
;    Direkt nach dem JMP-Befehl, da über den GEOS.Editor der Name
;    an dieser Stelle ausgelesen wird.
;    Der Name muss mit dem Dateinamen übereinstimmen, da der
;    Bildschirmschoner über diesen Namen beim Systemstart geladen wird.
:SaverName		b "64erMove",NULL

;*** ScreenSaver aufrufen.
:InitScreenSaver	jsr	GetFreeBank		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;64K-Bank gefunden ?
			beq	:50			; => Ja, weiter...
			lda	#%10000000
			sta	Flag_ScrSaver
			rts

::50			sta	RAM_BANK		;Bank für Zwischenspeicher setzen.

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
			lda	#$35			;I/O-Bereich einblenden.
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
			plp				;IRQ zurücksetzen.
			ldx	#NO_ERROR
			rts

;*** Überprüfen ob Bildschirmschoner installiert werden kann.
:ChkInstallScrSv	jsr	GetFreeBank		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;64K-Bank gefunden ?
			beq	:50			; => Ja, weiter...
			ldx	#NO_FREE_RAM
			rts
::50			ldx	#NO_ERROR
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

;--- Ergänzung: 20.07.18/M.Kanet
;Die bisherigen Routinen zur Suche nach einer freien Speicherbank wurden
;durch entsprechende Routinen aus dem GEOS.Editor ersetzt.
;
;*** Zeiger auf Bank-Bitpaar berechnen.
;    Ein Byte der MP3-RAM-Tabelle enthält 4 Bitpaare. Jedes Bitpaar
;    entspricht dabei einer Speicherbank.
:BankUsed_GetByte	txa
			and	#$03
			tay
			txa
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			rts

;*** Bank-Modus ermitteln.
;    Das Bitpaar aus der MP3-RAM-Tabelle wird in einen Bytewert umgewandelt:
;    Byte $00 = Frei, $01 = Anwendung, $02 = Disk, $03 = GEOS/Task/Spooler
:BankUsed_Type		and	BankCodeTab1,y
			stx	:52 +1
			ldx	BankCode_Move,y
			beq	:52
::51			lsr
			lsr
			dex
			bne	:51
::52			ldx	#$ff
			rts

;*** Freie Bank suchen.
;    Rückgabe:    xReg   = Fehlermeldung.
;                 Akku   = Freie Speicherbank.
:GetFreeBank		ldx	#$00
::51			stx	:52 +1
			jsr	BankUsed_GetByte
			jsr	BankUsed_Type
::52			ldx	#$ff
			tay
			beq	:53
			inx
			cpx	ramExpSize
			bcc	:51
			ldx	#NO_FREE_RAM
			rts
::53			txa
			ldx	#NO_ERROR
			rts

;*** Variablen für 64K-Speicher.
:RAM_BANK		b $00
:BankCodeTab1		b %11000000,%00110000,%00001100,%00000011
:BankCode_Move		b $03,$02,$01,$00

;*** Grafikeffekt.
:ScrSaverCode		d "obj.SS_64erMove"
:EndSaverCode

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_SCRSAVER + R2_SIZE_SCRSAVER -1
;******************************************************************************
