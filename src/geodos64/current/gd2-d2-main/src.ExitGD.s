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

			n	"mod.#113.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	ExitGD

;*** Boot-Laufwerk öffnen.
			t   "-BootDrive"

;*** GeoDOS beenden.
:ExitGD			cpx	#$00			;Nach BASIC verlassen ?
			bne	:101			;Nein, weiter...
			jmp	ExitBASIC		;BASIC direkt starten.

::101			ldx	#$ff			;Zurück zur MainLoop.
			txs
			lda	#>MainLoop -1
			pha
			lda	#<MainLoop -1
			pha

			jsr	InitIconTab		;Laufwerk-Icons initialisieren.

:ExitMenu		Display	ST_WR_FORE
			jsr	UseGDFont		;GeoDOS-Font aktivieren.

			jsr	ClrScreen		;Bildschirm löschen.

			ldy	#$03
			ldx	#$00			;CMD-Laufwerke zählen.
::101			lda	DriveModes,y
			bpl	:102
			inx
::102			dey
			bpl	:101

			txa				;CMD-Laufwerke verfügbar ?
			bne	InitCMD_Menu		;Ja, weiter...

			LoadB	Icon_Tab1,4		;Keine CMD-Optionen, Icon-Menü
			jsr	i_C_MenuTitel		;definieren und Menü starten.
			b	$05,$05,$14,$01
			jmp	StartMenu

;*** CMD-Partitionen anzeigen.
:InitCMD_Menu		bit	OptMenuAktiv		;CMD-Optionen bereits aktiv ?
			bmi	OpenCMD_Menu		;Ja, weiter...
			LoadB	Icon_Tab1,5		;Icon-Menü definieren.
			jsr	i_C_MenuTitel
			b	$05,$05,$19,$01

			lda	#$05 * 5
			sta	MenuIconColor +5
			jmp	StartMenu		;Menü starten.

;*** CMD-Optionen anbieten.
:OpenCMD_Menu		LoadB	OptMenuAktiv,$ff

			jsr	SetGDScrnCol		;GeoDOS-Farben setzen und
			jsr	ClrScreen		;Bildschirm löschen.

			lda	#$00			;"CMD-Partition"-Icon löschen.
			sta	Icon_Tab1a +0
			sta	Icon_Tab1a +1
			sta	Icon_Tab1a +6
			sta	Icon_Tab1a +7

			LoadB	Icon_Tab1,10		;Icon-Menü definieren.

			jsr	i_C_MenuTitel		;Farben für Options-Menü.
			b	$05,$05,$1e,$01
			jsr	i_C_MenuBack
			b	$05,$06,$1e,$0f
			jsr	i_C_Register
			b	$07,$0a,$08,$01
			jsr	i_ColorBox
			b	$08,$0c,$01,$01,$01
			jsr	i_ColorBox
			b	$09,$0e,$17,$04,$01

			lda	#$05 * 4
			sta	MenuIconColor +5

			LoadW	r0,MenuGrafx1
			jsr	GraphicsString		;Bildchirmgrafik zeichnen.

			jsr	PrintPartName		;Partitionen anzeigen.

;*** "Verlassen"-Menü starten,
:StartMenu		LoadW	r0,HelpFileName
			lda	#<ExitMenu
			ldx	#>ExitMenu
			jsr	InstallHelp		;Online-Hilfe installieren.

			PrintStrgMenuGrafx2		;Titelzeile ausgeben.

			StartMouse			;Maus aktivieren und warten
			NoMseKey			;bis keine Maustaste gedrückt.

:MenuIconColor		jsr	i_C_MenuMIcon
			b	$05,$06,$14,$03
			LoadW	r0,Icon_Tab1
			jmp	DoIcons			;Menü starten.

;*** Startpartition zurücksetzen.
:ResetBootPart		jsr	OpenBootDrive		;Boot-Laufwerk öffnen.

			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	PrintPartName		;Nein, weiter...
			jsr	GetCurPInfo		;Aktive Partition einlesen und
			txa				;im System als neue Partition für
			bne	PrintPartName		;aktuelles Laufwerk anmelden.
			tya
			jsr	SaveNewPart

;*** Alle partitionen anzeigen.
:PrintPartName		ldy	#$08			;Zeiger auf erstes Laufwerk.
::101			tya
			pha
			jsr	NewDrive		;Laufwerk aktivieren.

			jsr	SetTextPos1		;X-Koordinate für Textausgabe.

			lda	curDrive		;Laufwerksbuchstabe ausgeben.
			clc
			adc	#$39
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			pla
			pha
			tay
			lda	driveType -8,y		;Laufwerk verfügbar ?
			beq	:103			;Nein, weiter...
			lda	DriveModes-8,y
			bpl	:103

			jsr	CheckDiskCBM
			txa				;Diskette im Laufwerk ?
			bne	:103			;Nein, Abbruch...

::102			ldy	curDevice
			lda	DrivePart -8,y
			jsr	GetPartInfo		;Partitionsdaten einlesen und
			LoadW	r0,Part_Info+5;Zeiger auf Disketten-Name für
			jmp	:104			;Textausgabe richten.

::103			LoadW	r0,NoPartText		;Text "Keine Diskette!".
::104			jsr	SetTextPos2		;X-Koordinate definieren.

			ldy	#$00
::105			sty	:106 +1			;Disketten-/Partitions-Name ausgeben.
			lda	(r0L),y
			beq	:107
			jsr	ConvertChar
			jsr	SmallPutChar
::106			ldy	#$ff
			iny
			cpy	#$10
			bne	:105

::107			pla
			tay
			iny
			cpy	#$0c			;Alle Laufwerke ausgegeben ?
			bne	:101			;Nein, weiter...
			rts

;*** X-Koordinate für textausgabe definieren.
:SetTextPos1		lda	#$4c			;X-Koordinate für Laufwerksbuchstabe.
			b $2c
:SetTextPos2		lda	#$5c			;X-Koordinate für Disketten-Name.
			sta	r11L
			ClrB	r11H

			lda	curDrive
			sec
			sbc	#$08
			asl
			asl
			asl
			clc
			adc	#$76
			sta	r1H
			rts

;*** Icons für Partitionsauswahl konfigurieren.
:InitIconTab		LoadW	r0,Icon_Tab1b

			lda	#$00
::101			pha
			tay
			lda	DriveModes,y		;Aktuelles Laufwerk von CMD ?
			bmi	:102			;Ja, weiter...
			ldy	#$00			;Keine Partitionsauswahl möglich,
			jsr	:103			;Icon- und Einsprungsadresse löschen.
			ldy	#$06
			jsr	:103
::102			AddVBW	8,r0			;Zeiger auf nächstes Laufwerk.
			pla
			clc
			adc	#$01
			cmp	#$04			;Alle Laufwerke getestet ?
			bcc	:101			;Nein, weiter...
			rts

::103			lda	#$00			;Vektor löschen.
			sta	(r0L),y
			iny
			sta	(r0L),y
			rts

;*** Aktive Partition einlesen.
:ChDrvPartA		ldy	#$08			;Partition auf Laufwerk A: wechseln.
			b $2c
:ChDrvPartB		ldy	#$09			;Partition auf Laufwerk B: wechseln.
			b $2c
:ChDrvPartC		ldy	#$0a			;Partition auf Laufwerk C: wechseln.
			b $2c
:ChDrvPartD		ldy	#$0b			;Partition auf Laufwerk D: wechseln.
			lda	driveType -8,y		;Laufwerk verfügbar ?
			bne	:102			;Ja, weiter...
::101			rts				;Keine Funktion...

::102			lda	DriveModes-8,y		;CMD-Laufwerk ?
			bpl	:101			;Ja, weiter...

			tya
			jsr	NewDrive		;Laufwerk aktivieren.

			jsr	CheckDiskCBM
			txa				;Diskette im Laufwerk ?
			beq	:103			;Ja, weiter...

			jsr	PrintPartName		;Partitionsnamen anzeigen.
			jmp	StartMenu		;Menu erneut starten.

::103			jsr	ClrScreen		;Bildschirm löschen.
			jsr	CMD_NewTarget		;CMD-Partition wechseln.
::104			jmp	ExitMenu		;Verlassen-Menü erneut aufbauen.

;*** Einsprung für "Exit"-Funktionen.
:ExitGeoDOS		jsr	SetGDScrnCol		;GeoDOS-Farben setzen.
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	InitScreen		;Zum Hauptmenü zurück.

:ExitTurnOff		jsr	SetGDScrnCol		;GeoDOS-Farben setzen.
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	vPowerOff		;System parken.

;*** DeskTop starten.
:RunDeskTop		NoMseKey			;Warten bis keine Maustaste gedrückt.

			lda	#<$c3cf
			ldx	#>$c3cf
			bit	c128Flag
			bpl	:101
			lda	#<$c9bb
			ldx	#>$c9bb
::101			sta	r0L
			stx	r0H
			LoadW	r1,BootName

			ldx	#r0L
			ldy	#r1L
			jsr	CmpString		;GeoDOS als DeskTop ?
			bne	:102			;Nein, weiter...
			jmp	OtherDeskTop		;DeskTop-Auswahlbox.
::102			jmp	OpenDeskTop		;DeskTop starten.

;*** Anderen DeskTop aktivieren.
:OtherDeskTop		jsr	SetGDScrnCol		;GeoDOS-Farben setzen.
			jsr	ClrScreen		;Bildschirm löschen.

			jsr	OpenSysDrive		;Systemlaufwerk öffnen.

			LoadW	r6 ,FileNTab
			LoadB	r7L,AUTO_EXEC
			LoadB	r7H,255
			LoadW	r10,BootClass
			jsr	FindFTypes		;DeskTop-Startdateien suchen.
			txa				;Diskettenfehler ?
			beq	:101			;Nein, weiter...
			jsr	OpenUsrDrive
			jmp	GDDiskError		;Systemfehler.

::101			CmpBI	r7H,255			;Startdateien gefunden ?
			bne	SelectDeskTop		;Ja, weiter...
			jsr	OpenUsrDrive

			DB_CANCELV108e0			;Fehler: "Keine Startdateien".
			jmp	InitScreen		;Zurück zu GeoDOS.

;*** Dateienamen nach 16Z. konvertieren.
:SelectDeskTop		lda	#<FileNTab		;Dateinamen konvertieren.
			sta	r14L
			sta	r15L
			lda	#>FileNTab
			sta	r14H
			sta	r15H

::101			CmpB	r7H,255
			beq	:103

			ldy	#0
::102			lda	(r15L),y		;GEOS 17 Zeichen nach
			sta	(r14L),y		;GeoDOS 16 Zeichen.
			iny
			cpy	#16
			bne	:102

			AddVBW	17,r15
			AddVBW	16,r14
			inc	r7H
			jmp	:101

::103			ldy	#0			;Ende der Tabelle merkieren
			tya
			sta	(r14L),y

			lda	#<V108c0		;GO-Datei wählen.
			ldx	#>V108c0
			jsr	SelectBox

			lda	r13L
			beq	:105			; => Datei gewählt.
			cmp	#$02
			beq	:104			; => "Abbruch" gewählt.
			jmp	ExitMenu		; "Exit"-Menü aufbauen.
::104			jmp	InitScreen		; Zurück zu GeoDOS.

::105			ldy	#$00
::106			lda	(r15L),y		;GO-Dateiname kopieren.
			sta	LoadDeskName,y
			beq	:107
			cpy	#$10
			iny
			bne	:106

::107			LoadW	r6,LoadDeskName
			jsr	FindFile		;GO-Datei suchen.
			txa				;Gefunden ?
			beq	:109			;Ja, weiter...

::108			txa
			pha
			jsr	OpenUsrDrive		;Zurück zum Anwender-Laufwerk.
			pla
			tax
			jmp	DiskError		;Diskettenfehler !

::109			lda	dirEntryBuf +1		;Zeiger auf ersten Sektor.
			ldx	dirEntryBuf +2
			sta	r1L
			stx	r1H
			LoadW	r2 ,$0700		;Max. $700 Bytes einlesen.
			LoadW	r7 ,PRINTBASE		;Zeiger auf Ladeadresse.
			jsr	ReadFile		;Programm einlesen.
			txa				;Diskettenfehler ?
			bne	:108			;Ja, Abbruch.

			jsr	OpenUsrDrive		;Zurück zum Anwender-Laufwerk.

			jsr	PrepareExit		;Farben zurücksetzen.
			jmp	PRINTBASE		;GO-Datei starten.

;*** Zurück zum BASIC des C64/C128.
:ExitBASIC		jsr	SetGDScrnCol		;GeoDOS-Farben setzen.
			jsr	ClrScreen		;Bildschirm löschen.

			NoMseKey			;Warten bis keine Maustaste gedrückt.

			lda	curDrive		;Laufwerk aktivieren.
			jsr	SetDevice
			jsr	PurgeTurbo		;TurboDOS desktivieren, sonst ist
							;kein BASIC-Zugriff möglich!

			bit	c128Flag		;C64 / C128 ?
			bpl	C64BASIC		; -> C64-Reset!

;*** Nach BASIC verlassen: C128.
:C128BASIC		sei
			LoadB	$ff00,%01001111
			lda	#$00
			sta	$fff5
			sta	$1c00
			sta	$1c01
			sta	$1c02
			sta	$1c03
			jmp	($fffc)

;*** Nach BASIC verlassen: C64.
:C64BASIC		sei				;IRQ abschalten.

			lda	$01			;Sicherstellen, das neben dem Kernal
			and	#%11000000		;auch das BASIC-ROM eingeblendet ist.
			ora	#%00110111		;Bit 6/7 für SuperCPU - nicht ändern!
			sta	$01

			ldy	#$00			;Neue Boot-Routine nach $8000
::101			lda	L8000,y			;kopieren.
			sta	$8000,y
			iny
			bne	:101

			lda	$e394 +1		;Einsprung zur Initialisierung der
			sta	$801c +1		;Vektoren ab ":$0300" aus Original-
			lda	$e394 +2		;Kernal entnehmen. Ist bei einem:
			sta	$801c +2		;Jiffy-DOS ROM = $E4B7.
							;Original  ROM = $E453.
			jmp	($fffc)			;C64-Reset auslösen.

;*** Neue Boot-Routine.
:L8000			w	$8009			;Zeiger auf RESET-Routine.
:L8002			w	$8009			;Zeiger auf RESET-Routine.
:L8004			b	$c3,$c2,$cd		;":CBM80"  Kennung "CBM80" für
:L8007			b	$38,$30			;          Neue Boot-Routine.
:L8009			sei
:L800A			ldx	#$ff			;          VIC-Register löschen.
:L800C			stx	$d016
:L800F			jsr	$fda3			;":IOINIT" CIA-Register löschen.
:L8012			jsr	$fd50			;":RAMTAS" RAM-Reset
							;          Kassettenpuffer einrichten.
							;          Bildschirm auf $0400.
:L8015			jsr	$fd15			;":RESTOR" Standard I/O-Vektoren.
:L8018			jsr	$ff5b			;":CINT"   Bildschirm-Editor-Reset.
:L801B			cli				;          IRQ freigeben.
:L801C			jsr	$e453			;":INIVEC" Vektoren ab $0300 setzen.
							;          Bei Jiffy-DOS zusätzlich
							;          F-Tasten und JD-Befehle
							;          wieder aktivieren.
:L801F			jsr	$e3bf			;":INITMP" Reset RAM-Hilfsspeicher.
:L8022			jsr	$e422			;":MSGNEW" Einschaltmeldung/NEW.
:L8025			ldx	#$fb			;          Stapelzeiger löschen.
:L8027			txs
:L8028			stx	$8005			;          CBM80-Kennung löschen.
:L802B			jmp	$e386			;          BASIC-Warmstart/READY.

;*** Variablen.
:BasicCommand		b NULL
:BootName		b "BootGD",NULL
:BootClass		b "InstallDT   V",NULL
:LoadDeskName		s $11
:HelpFileName		b "04,GDH_Spezial",NULL
:NoPartText		b "???",NULL
:OptMenuAktiv		b $00

:V108a0			b $70,$77
			w $0040,$0047
:V108a1			b $80,$87
			w $0040,$0047

;*** Auswahbox für DeskTop-Auswahl.
:V108c0			b $00
			b $ff
			b $00
			b $10
			b $00
			w V108d0
			w FileNTab

;*** Icon-Tabelle.
:Icon_Tab1		b $00
			w $0000
			b $00

			w Icon_00
			b $05,$30,$05,$18
			w ExitGeoDOS

			w Icon_01
			b $0a,$30,$05,$18
			w RunDeskTop

			w Icon_02
			b $0f,$30,$05,$18
			w ExitBASIC

			w Icon_03
			b $14,$30,$05,$18
			w ExitTurnOff

:Icon_Tab1a		w Icon_04
			b $19,$30,$05,$18
			w OpenCMD_Menu

;*** Icons nur aktiv wenn CMD-Laufwerke verfügbar sind.
			w Icon_05
			b $08,$60,$01,$08
			w ResetBootPart

:Icon_Tab1b		w Icon_DOWN
			b $08,$70,$01,$08
			w ChDrvPartA

:Icon_Tab1c		w Icon_DOWN
			b $08,$78,$01,$08
			w ChDrvPartB

:Icon_Tab1d		w Icon_DOWN
			b $08,$80,$01,$08
			w ChDrvPartC

:Icon_Tab1e		w Icon_DOWN
			b $08,$88,$01,$08
			w ChDrvPartD

if Sprache = Deutsch
;*** Titel für Dialogboxen.
:V108d0			b PLAINTEXT,"DeskTop wählen",NULL

;*** Hinweis: "Systemfehler".
:V108e0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Keine Startdateien für",NULL
::102			b        "DeskTop gefunden!",NULL
endif

if Sprache = Englisch
;*** Titel für Dialogboxen.
:V108d0			b PLAINTEXT,"Select DeskTop",NULL

;*** Hinweis: "Systemfehler".
:V108e0			w :101, :102, ISet_Achtung
::101			b BOLDON,"No bootfiles found",NULL
::102			b        "for other deskTop!",NULL
endif

;*** Text für "GD beenden".
:MenuGrafx1		b MOVEPENTO			;Rahmen.
			w $0028
			b $30
			b LINETO
			w $0028
			b $a7
			b LINETO
			w $0117
			b $a7
			b LINETO
			w $0117
			b $30

			b MOVEPENTO			;Optionsfeld.
			w $0030
			b $58
			b FRAME_RECTO
			w $010f
			b $9f

			b MOVEPENTO			;Partitionsfeld.
			w $0047
			b $6f
			b FRAME_RECTO
			w $0100
			b $90

if Sprache = Deutsch
			b ESC_PUTSTRING
			w $003c
			b $56
			b PLAINTEXT
			b "Optionen"
			b GOTOXY
			w $0050
			b $66
			b "Startpartition einstellen"
			b NULL

:MenuGrafx2		b PLAINTEXT
			b GOTOXY
			w $0030
			b $2e
			b "GeoDOS verlassen"
			b NULL
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $003c
			b $56
			b PLAINTEXT
			b "Options"
			b GOTOXY
			w $0050
			b $66
			b "Open boot-partition"
			b NULL

:MenuGrafx2		b PLAINTEXT
			b GOTOXY
			w $0030
			b $2e
			b "Exit GeoDOS"
			b NULL
endif

;*** Icons.
:Icon_00
<MISSING_IMAGE_DATA>

:Icon_01
<MISSING_IMAGE_DATA>

:Icon_02
<MISSING_IMAGE_DATA>

:Icon_03
<MISSING_IMAGE_DATA>

:Icon_04
<MISSING_IMAGE_DATA>

:Icon_05
<MISSING_IMAGE_DATA>
