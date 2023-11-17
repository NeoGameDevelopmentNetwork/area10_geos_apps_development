; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#112.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	ParkHD
			jmp	UnParkHD
			jmp	PowerOff

;*** L1063: CMD_HD parken.
:ParkHD			DB_UsrBoxV112a0
			CmpBI	sysDBData,3
			bne	L1063ExitGD

			lda	curDrive
			sta	:101 +1

			jsr	DoInfoBox
			PrintStrgV112b0

			jsr	DoParkHD

			jsr	ClrBox
			lda	V112g0
			beq	:101

			DB_OK	V112a1

::101			lda	#$ff
			jsr	NewDrive

:L1063ExitGD		jsr	ClrScreen
			jmp	InitScreen

;*** Routine zum parken aller HDs.
:DoParkHD		jsr	ResetDrives

::111			jsr	InitForIO		;I/O aktivieren.

			ldx	#8			;Suche ab Adr. #12.
::112			stx	curDevice		;(Adr. 8-11 für GEOS reserviert...)

			ClrB	STATUS			;Laufwerk aktivieren.
			jsr	UNTALK
			lda	curDevice
			jsr	LISTEN
			lda	#$ef
			jsr	SECOND
			jsr	UNLSN

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:113
			jsr	:121

::113			ldx	curDevice		;Zeiger auf nächstes Laufwerk.
			inx
			cpx	#30			;Bis max. Gerät #29 (max. RL) testen.
			bne	:112			;Ende erreicht ? Nein, weiter...

			jmp	DoneWithIO

;*** HD parken.
::121			lda	#$00
			jsr	Send1Com
			lda	#$01
			jsr	Get1Com

			ldy	#$05
::122			lda	V112e1,y
			cmp	V112f0,y
			bne	:124
			dey
			bpl	:122

			lda	#$02
			jsr	Send1Com
::123			lda	#$03
			jsr	Send1Com
			lda	#$04
			jsr	Get1Com
			lda	V112e4
			bmi	:123
			inc	V112g0
::124			rts

;*** L1063: CMD_HD parken.
:UnParkHD		lda	curDrive
			sta	:101 +1

			jsr	DoInfoBox
			PrintStrgV112b1

			jsr	DoUnParkHD

			jsr	ClrBox
			lda	V112g0
			beq	:101

			DB_OK	V112a2

::101			lda	#$ff
			jsr	NewDrive

			jmp	L1063ExitGD 		;(Dürfte nicht vorkommen!)

:DoUnParkHD		jsr	ResetDrives

::111			jsr	InitForIO		;I/O aktivieren.

			ldx	#8			;Suche ab Adr. #12.
::112			stx	curDevice		;(Adr. 8-11 für GEOS reserviert...)

			ClrB	STATUS			;Laufwerk aktivieren.
			jsr	UNTALK
			lda	curDevice
			jsr	LISTEN
			lda	#$ef
			jsr	SECOND
			jsr	UNLSN

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:113
			jsr	:121

::113			ldx	curDevice		;Zeiger auf nächstes Laufwerk.
			inx
			cpx	#30			;Bis max. Gerät #29 (max. RL) testen.
			bne	:112			;Ende erreicht ? Nein, weiter...

			jmp	DoneWithIO		;I/O abschalten.

;*** HD unparken.
::121			lda	#$00
			jsr	Send1Com
			lda	#$01
			jsr	Get1Com

			ldy	#$05
::122			lda	V112e1,y
			cmp	V112f0,y
			bne	:123
			dey
			bpl	:122

			lda	#$05
			jsr	Send1Com
			inc	V112g0
::123			rts

;*** Laufwerk initialisieren
;    und Turbosoftware entfernen.
:ResetDrives		lda	#8
::101			pha
			tax
			lda	DriveTypes-8,x
			beq	:102
			txa
			jsr	SetDevice
			jsr	PurgeTurbo
::102			pla
			add	1
			cmp	#12
			bne	:101

			ClrB	V112g0
			rts

;*** Befehl an Floppy senden (INLINE-Version!)
:Send1Com		sta	:102 +1
			jsr	UNLSN			;Floppy-Laufwerk auf "LISTEN"
			lda	curDevice		;schalten (Datenempfang).
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND

			bit	STATUS			;STATUS-Byte prüfen.
			bpl	:102			;Bit 7=0, OK!

::101			jsr	UNLSN			;Laufwerksfehler!
			ldx	#$ff
			rts

::102			ldx	#$ff
			lda	V112d0,x
			sta	r14H
			txa
			asl
			tax
			lda	V112d1+0,x
			sta	r15L
			lda	V112d1+1,x
			sta	r15H

			ClrB	:103 +1

::103			ldy	#$00			;Byte aus Floppy-Befehl
			lda	(r15L),y		;einlesen.
			jsr	CIOUT			;Zeichen direkt auf Port ausgeben.
			inc	:103 +1			;Zeiger auf nächstes Zeichen.
			dec	r14H			;Anzahl Zeichen -1.
			bne	:103			;Nein, weiter...

			jsr	UNLSN			;Floppy abschalten.
			ldx	#$00
			rts

;*** Daten von Floppy empfangen (INLINE-Version!)
:Get1Com		sta	:102 +1
			jsr	UNTALK			;Floppy-Laufwerk auf "TALK"
			lda	curDevice		;schalten (Daten senden)
			jsr	TALK
			lda	#$ff
			jsr	TKSA

			bit	STATUS			;STATUS-Byte prüfen.
			bpl	:102			;Bit 7=0, OK!

::101			jsr	UNTALK
			ldx	#$ff
			rts

::102			ldx	#$ff
			lda	V112d0,x
			sta	r14H
			txa
			asl
			tax
			lda	V112d1+0,x
			sta	r15L
			lda	V112d1+1,x
			sta	r15H

			ClrB	:104 +1

::103			jsr	ACPTR			;Byte einlesen und in
::104			ldy	#$00			;Datenspeicher schreiben.
			sta	(r15L),y
			inc	:104 +1			;Zeiger auf nächstes Zeichen.
			dec	r14H			;Anzahl Zeichen -1.
			bne	:103			;Nein, weiter...

			jsr	UNTALK			;Laufwerk abschalten.
			ldx	#$00
			rts

;*** Computer abschalten.
:PowerOff		lda	curDrive
			sta	:102 +1

			jsr	InitForIO
			ClrB	$d020
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$e0

			jsr	MouseOff
			jsr	DoParkHD

			jsr	UseGDFont
			PrintStrgV112c0

			php				;IRQ sperren.
			sei
			ldx	$01
			lda	#$35			;I/O aktivieren.
			sta	$01
::101			lda	$dc01			;Maustaste abfragen.
			cmp	#$ff
			beq	:101
			stx	$01
			plp

			jsr	DoUnParkHD

::102			lda	#$ff
			jsr	NewDrive

			jmp	InitScreen

if Sprache = Deutsch
;*** Variablen & Texte.
:V112a0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON, "Das parken der CMD_HD",NULL
::102			b         "deaktiviert das Laufwerk!"
			b GOTOXY
			w $0040
			b $66
			b "Trotzdem durchführen ?",NULL

:V112a1			w :101, :102, ISet_Info
::101			b BOLDON, "Alle CMD-Festplatten",NULL
::102			b         "wurden geparkt",NULL

:V112a2			w :101, :102, ISet_Info
::101			b BOLDON, "Alle CMD-Festplatten",NULL
::102			b         "wurden aktiviert!",NULL

;*** Infoboxen.
:V112b0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Festplatten werden"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "geparkt...",NULL

:V112b1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Festplatten werden"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "aktiviert...",NULL

;*** Abschlußmeldung.
:V112c0			b PLAINTEXT
			b GOTOXY
			w $0008
			b $be
			b "Computer kann abgeschaltet werden!"
			b GOTOXY
			w $0008
			b $c6
			b "Zurück zum Menü mit Mausklick!",NULL
endif

if Sprache = Englisch
;*** Variablen & Texte.
:V112a0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON, "Parking the HD will",NULL
::102			b         "disconnect the drive!"
			b GOTOXY
			w $0040
			b $66
			b "Park CMD HD ?",NULL

:V112a1			w :101, :102, ISet_Info
::101			b BOLDON, "All HD-drives were",NULL
::102			b         "now disconnected!",NULL

:V112a2			w :101, :102, ISet_Info
::101			b BOLDON, "All HD-drives were",NULL
::102			b         "activated!",NULL

;*** Infoboxen.
:V112b0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Parking all"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "HD-device...",NULL

:V112b1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Unparking all"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "HD-device...",NULL

;*** Abschlußmeldung.
:V112c0			b PLAINTEXT
			b GOTOXY
			w $0008
			b $be
			b "Please turn off your computer!"
			b GOTOXY
			w $0008
			b $c6
			b "Press mouse-button for menu!",NULL
endif

;*** Anzahl Bytes/Zeiger auf Befehlsadresse für Floppy-Befehl.
:V112d0			b    $06,    $06
			b    $07,    $06,    $01,    $08
:V112d1			w V112e0, V112e1
			w V112e2, V112e3, V112e4, V112e5

;*** Floppy-Befehle.
:V112e0			b "M-R",$a0,$fe,$06
:V112e1			s $06
:V112e2			b "M-W",$20,$00,$01,$fa
:V112e3			b "M-R",$20,$00,$01
:V112e4			s $01
:V112e5			b "M-W",$20,$00,$01,$f8

;*** Kennung für CMD-Festplatte.
:V112f0			b "CMD HD"

;*** Anzahl CMD HDs.
:V112g0			b $00
