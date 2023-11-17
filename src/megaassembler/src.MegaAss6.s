; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;MegaAssembler
;Mehrere Objektdateien zu einer
;VLIR-Datei verbinden.
if .p
			t "TopSym"
			t "TopMac"
			t "src.MegaAss0.ext"

:MP3_CODE		= $c014
:RealDrvMode		= $9f92
:DBSELECTPART		= %10000000

:MaxTextEntry		= 13
endif

			n "mod.#6"
			o VLIR_BASE
			q StartVLinkVarArea

;*** Parameter-Bytes im Infoblock.
;    $90 = Opt_SourceDrive
;    $91 = Opt_TargetDrive
;    $92 = Opt_ErrFileDrive
;    $93 = Opt_SymbTabDrive
;    $94 = Opt_AutoTxtDrive
;    $95 = Opt_AutoMode
;    $96 = Opt_SymbTabMode
;    $97 = Opt_ExtSTabMode
;    $98 = Opt_OverWrite
;    $99 = Opt_IgnoreFileMode
;    $9a = Opt_FileLenMode
;    $9b = Opt_POpcodeTest
;    $9c = Opt_MouseCancel

;*** Programmstart.
:StartVLink		lda	screencolors
			and	#$0f
			sta	r0L
			lda	screencolors
			asl
			asl
			asl
			asl
			ora	r0L
			sta	:1

			jsr	i_FillRam
			w	920
			w	COLOR_MATRIX +2*40
::1			b	$bf

			jsr	i_FillRam
			w	(EndVLinkVarArea - StartVLinkVarArea)
			w	StartVLinkVarArea
			b	$00

			lda	#$00
			sta	Poi_1stEntryInTab

;*** Bildschirm aufbauen.
:DoInfoScreen		jsr	SetXpos40_80		;Menüs initialisieren.

			LoadB	dispBufferOn,ST_WR_FORE ! ST_WR_BACK
			jsr	ClrScreen

			lda	#$01
			jsr	SetPattern
			jsr	i_Rectangle
			b	$02,$0e
:X103			w	$00c3,$013b
			jsr	i_Rectangle
			b	$03,$0e
:X104			w	$00c1,$013d
			jsr	i_Rectangle
			b	$04,$0e
:X105			w	$00c0,$013e

			lda	#$09
			jsr	SetPattern
			jsr	i_Rectangle
			b	$02,$0e
:X100			w	$00c4,$013a
			jsr	i_Rectangle
			b	$03,$0e
:X101			w	$00c2,$013c
			jsr	i_Rectangle
			b	$04,$0e
:X102			w	$00c1,$013d

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$03,$0d
:X106			w	$00c8,$0136

			jsr	i_PutString
:X107			w	$00d0
			b	$0b
			b	PLAINTEXT,BOLDON
			b	"* MegaLinker *",NULL

			bit	Flag_AutoAssInWork
			bpl	:1
			jmp	GetNextCom

::1			jsr	PrepareScreen

			jsr	i_PutString
:X14			w	$000f
			b	$16
			b	PLAINTEXT,BOLDON
			b	" Systeminformationen "
			b	PLAINTEXT,NULL

			lda	mouseXPos    +0
			sta	DummyIconTab +1
			lda	mouseXPos    +1
			sta	DummyIconTab +2
			lda	mouseYPos
			sta	DummyIconTab +3
			LoadW	r0,DummyIconTab
			jsr	DoIcons

;*** Hauptmenü aktivieren.
:StartMenu		bit	Flag_AutoAssInWork
			bpl	:1
			jmp	GetNextCom

::1			jsr	DefMenuEntrys_GEOS	;DAs einlesen.
			jsr	GetMenuEntrys_Text	;Texte einlesen.

			jsr	SetMenParData

			LoadW	r0,DM_MainMenu
			lda	#$01
			jmp	DoMenu

;*** Infobox über MegaAss.
:InfoBox		jsr	GotoFirstMenu
			LoadW	r0,DlgInfoBox
			jmp	DoDlgBox

;*** Bildschirm löschen.
:PrepareScreen		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$0e,$c7
:X11			w	$0000,$013f
			lda	#$09
			jsr	SetPattern
			LoadB	r2H,$1a
			jmp	Rectangle

;*** Zurück zum BASIC des C64/C128.
:ExitBASIC		jsr	GotoFirstMenu

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
::1			lda	L8000,y			;kopieren.
			sta	$8000,y
			iny
			bne	:1

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

;*** Einträge für Menü "GEOS" berechnen.
:DefMenuEntrys_GEOS	lda	Opt_BootDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			lda	DM_geos  +0
			clc
			adc	#29
			sta	DM_geos  +1
			LoadB	DM_geos  +6,$02 ! VERTICAL ! UN_CONSTRAINED

			LoadW	a0 ,DM_geos
			LoadW	r6 ,MT02c
			LoadB	r7L,DESK_ACC
			LoadB	r7H,8

;			LoadW	r10,$0000
			lda	#$00
			sta	r10L
			sta	r10H

			jsr	FindFTypes
			lda	#$08
			sec
			sbc	r7H
			cmp	#$01
			bcs	:1
			sec
			rts

;*** Länge für Menü "geos" berechnen.
::1			sta	a2L

			ldy	#$06
			lda	(a0L),y
			and	#%00111111
			clc
			adc	a2L
			ora	#VERTICAL ! UN_CONSTRAINED
			sta	(a0L),y			;Anzahl Dateien berechnen.

			LoadB	a2H,$00			;Länge des Menüs berechnen.
			LoadW	a3 ,$000e
			ldx	#a2L
			ldy	#a3L
			jsr	DMult

			ldy	#$01
			lda	(a0L),y
			clc
			adc	a2L
			sta	(a0L),y
			clc
			rts

;*** Textdateien einlesen.
:DefMenuEntrys_Text	lda	#$00
			sta	Poi_1stEntryInTab
:GetMenuEntrys_Text	lda	#$00
			sta	LinkTextOnDisk

			lda	Opt_SourceDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadB	DM_Texte +6,$00 ! VERTICAL ! UN_CONSTRAINED
			LoadW	r6 ,$4000
			LoadB	r7L,APPL_DATA
			LoadB	r7H,144
			LoadW	r10,ClassWriteImage
			jsr	FindFTypes
			lda	#144
			sec
			sbc	r7H
			sta	MaxTextFiles
			cmp	#$00
			bne	CopyNewFiles

			LoadW	r4,NoTextOnDisk
			LoadW	r5,MT03a
			ldx	#r4L
			ldy	#r5L
			jsr	CopyString

			LoadB	DM_Texte +1,$1d
			LoadB	DM_Texte +6,$01 ! VERTICAL ! UN_CONSTRAINED
			LoadB	SelectedFile,NULL
			inc	LinkTextOnDisk
			rts

:CopyNewFiles		lda	Poi_1stEntryInTab
			cmp	MaxTextFiles
			bcc	:1
			lda	#$00
			sta	Poi_1stEntryInTab

::1			lda	Poi_1stEntryInTab
			sta	r0L
			LoadB	r0H,$00
			LoadW	r1 ,$0011
			ldx	#r0L
			ldy	#r1L
			jsr	DMult
			AddVW	$4000,r0
			LoadW	r1,MT03a
			LoadB	r2L,$00
			LoadB	r2H,$0f

			lda	Poi_1stEntryInTab
			sta	r3L

			lda	MaxTextFiles
			cmp	#MaxTextEntry
			bcc	:3

			lda	MaxTextFiles
			sec
			sbc	r3L
			cmp	#MaxTextEntry -1
			bcs	:2

			LoadW	r4,Go1stTextFile
			ldx	#r4L
			jsr	AddTextToList
			jmp	:3

::2			LoadW	r4,MoreTextFiles
			ldx	#r4L
			jsr	AddTextToList

::3			ldy	#$00
			lda	(r0L),y
			beq	:4

			ldx	#r0L
			jsr	AddTextToList
			AddVW	17,r0
			inc	r3L

			lda	r2L
			cmp	#MaxTextEntry
			beq	:4
			lda	r3L
			cmp	MaxTextFiles
			bcc	:3

::4			lda	r2L
			ora	#VERTICAL ! UN_CONSTRAINED
			sta	DM_Texte +6
			lda	r2H
			sta	DM_Texte +1
			rts

;** Eintrag in Tabelle kopieren.
:AddTextToList		ldy	#r1L
			jsr	CopyString
			AddVW	17,r1
			AddVB	14,r2H
			inc	r2L
			rts

;*** Aktuelle Parameter speichern.
:SaveParameter		jsr	FindMegaAss
			txa
			beq	:2
::1			jmp	ExitDT

::2			lda	dirEntryBuf +19
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Infoblock einlesen.
			txa
			bne	:1

			lda	Opt_SourceDrive		;Akt. Laufwerk.
			sta	diskBlkBuf +$90
			lda	Opt_TargetDrive		;Ausgabelaufwerk.
			sta	diskBlkBuf +$91
			lda	Opt_IgnoreFileMode	;Sicherheitsabfrage.
			sta	diskBlkBuf +$99
			lda	Opt_FileLenMode		;Dateilänge anpassen.
			sta	diskBlkBuf +$9a

			lda	dirEntryBuf +19
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Infoblock speichern.

			jmp	GotoFirstMenu		;Hauptmenü aktivieren.

;*** Laufwerk wählen.
:SlctSourceDrv		ldx	#$00
			b $2c
:SlctTargetDrv		ldx	#$01
			stx	DrvSlctMode
			lda	DrvMenuYPos,x
			sta	DM_SlctDrive +0
			clc
			adc	#4*14 +1
			sta	DM_SlctDrive +1
			LoadW	r0,DM_SlctDrive
			rts

:DefDriveA		lda	#$08
			b $2c
:DefDriveB		lda	#$09
			b $2c
:DefDriveC		lda	#$0a
			b $2c
:DefDriveD		lda	#$0b
			ldx	DrvSlctMode
			bne	:1
			sta	Opt_SourceDrive
			jsr	DefMenuEntrys_Text
			jmp	:5

::1			sta	Opt_TargetDrive

::5			jsr	SetMenParData
			jmp	DoPreviousMenu

;*** Aktuelles Laufwerk wechseln.
:DefInputDrvA		ldy	#$08
			b $2c
:DefInputDrvB		ldy	#$09
			b $2c
:DefInputDrvC		ldy	#$0a
			b $2c
:DefInputDrvD		ldy	#$0b
			lda	driveType-8,y
			bne	:1
			jmp	ReDoMenu

::1			tya
			sta	Opt_SourceDrive
			jsr	NewSetDevice		;Laufwerk aktivieren.
			jsr	SetMenParData
			jsr	DefMenuEntrys_Text	;Texte einlesen.
			jmp	DoPreviousMenu

;*** Diskette wechseln.
:ChangeSrcDisk		ldx	Opt_SourceDrive
			bne	ChangeDisk

:ChangeTgtDisk		ldx	Opt_TargetDrive
:ChangeDisk		cpx	Opt_BootDrive		;Diskwechsel möglich ?
			beq	:exit			; => Nein, Abbruch...

			lda	MP3_CODE +0
			cmp	#"M"
			bne	:skip
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:skip

			lda	RealDrvMode -8,x
			bpl	:skip

			txa
			jsr	SetDevice
			jsr	NewDisk
			txa
			bne	:skip

			lda	#< Dlg_SlctPart
			sta	r0L
			lda	#> Dlg_SlctPart
			sta	r0H
			lda	#< dataFileName
			sta	r5L
			lda	#> dataFileName
			sta	r5H
			jsr	DoDlgBox

::skip			jsr	GotoFirstMenu		;Hauptmenü aktivieren.
			jmp	DefMenuEntrys_Text	;Texte einlesen.
::exit			jmp	ReDoMenu

;*** Aktuelles Laufwerk wechseln.
:DefOutputDrvA		ldy	#$08
			b $2c
:DefOutputDrvB		ldy	#$09
			b $2c
:DefOutputDrvC		ldy	#$0a
			b $2c
:DefOutputDrvD		ldy	#$0b
			lda	driveType-8,y
			bne	:1
			jmp	ReDoMenu

::1			tya
			sta	Opt_TargetDrive
			jsr	NewSetDevice		;Laufwerk aktivieren.
			jsr	SetMenParData
			jmp	DoPreviousMenu

;*** Modus für "Sicherheitsabfrage" festlegen.
:DefIgnoreFileMode	lda	Opt_IgnoreFileMode
			eor	#$ff
			sta	Opt_IgnoreFileMode
			jsr	SetMenParData
			jmp	ReDoMenu

;*** Modus für "Dateilänge anpassen" festlegen.
:DefFileLenMode		lda	Opt_FileLenMode
			eor	#$ff
			sta	Opt_FileLenMode
			jsr	SetMenParData
			jmp	ReDoMenu

;*** Menüanzeige initialisieren.
:SetMenParData		lda	#PLAINTEXT
			bit	c128Flag
			bmi	:1
			lda	#ITALICON
::1			sta	MT02b

			lda	Opt_SourceDrive
			clc
			adc	#$39
			sta	MT04a +10		;Aktuelles Laufwerk anzeigen.

			lda	#ITALICON
			ldx	Opt_SourceDrive
			cpx	Opt_BootDrive
			beq	:2
			lda	#PLAINTEXT
::2			sta	MT04b

			lda	#ITALICON
			ldx	Opt_TargetDrive
			cpx	Opt_BootDrive
			beq	:3
			lda	#PLAINTEXT
::3			sta	MT04g

			lda	Opt_IgnoreFileMode
			jsr	DefCurrentMode
			sta	MT04c

			lda	Opt_FileLenMode
			jsr	DefCurrentMode
			sta	MT04d

			lda	Opt_TargetDrive
			clc
			adc	#$39
			sta	MT04e +9		;Laufwerk A: aktivieren.

			ldy	#$00
			ldx	#$00
::4			lda	#PLAINTEXT
			sta	DriveTextA,x
			lda	driveType,y
			bne	:5
			lda	#ITALICON
			sta	DriveTextA,x
::5			txa
			clc
			adc	#13
			tax
			iny
			cpy	#$04
			bne	:4
			rts

;*** Modus für Menüanzeige festlegen.
:DefCurrentMode		cmp	#$00
			beq	:1
			lda	#"*"
			b $2c
::1			lda	#" "
			rts

;*** GeoWrite auf Diskette suchen.
:FindGeoWrite		jsr	GotoFirstMenu

			LoadB	r7L,APPLICATION
			LoadW	r6,$6000
			LoadB	r7H,1
			LoadW	r10,ClassGeoWrite
			jsr	FindFTypes
			txa
			bne	:1
			ldx	#r2L
::1			jmp	GetPtrCurDkNm

;*** Link-Text öffnen.
:OpenLinkText		jsr	FindGeoWrite
			LoadW	r3,LinkTextName
			LoadW	r6,$6000
			LoadB	r0L,%10000000
			jmp	GetFile

;*** GeoWrite starten.
:OpenGeoWrite		jsr	FindGeoWrite
			LoadW	r6,$6000
			LoadB	r0L,%00000000
			jmp	GetFile

;*** Icon-Modus "Nicht invertieren".
:ClrIconMode		LoadB	iconSelFlag,NULL
			rts

;*** Zurück zum MegaAss.
:RUN_MegaAss		jsr	GotoFirstMenu
			jmp	Mod_Menu

;*** Programm starten.
:RUN_VLIR_File		jsr	GotoFirstMenu

			lda	Opt_TargetDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadW	r6,VLIR_FileName
			jsr	FindFile
			txa
			bne	:2

::1			jsr	ClrScreen

			LoadW	r9,dirEntryBuf		;Applikation laden.
			LoadB	r0L,%00000000
			jsr	LdApplic
			cpx	#$0e			;Bildschirmfehler ?
			bne	:2			;Nein, Ende...

			lda	graphMode		;Grafikmodus umschalten.
			eor	#$80
			sta	graphMode
			jsr	SetNewMode
			jmp	:1

::2			rts

;*** Desk Accessory laden.
:LoadDA_File		sec
			sbc	#$02
			sta	a0L

			jsr	GotoFirstMenu

			LoadB	a0H,$00
			LoadW	a1 ,$0011
			ldx	#a0L
			ldy	#a1L
			jsr	DMult

			AddVW	MT02c,a0
			LoadW	a1,$5f00
			ldx	#a0L
			ldy	#a1L
			jsr	CopyString

			lda	Opt_BootDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadB	r0L ,%00000000
			LoadW	r6  ,$5f00
			LoadB	r10L,$00
			jsr	GetFile
			jmp	DoInfoScreen

;*** Nächsten Befehl auswerten.
:GetNextCom		jsr	FindAutoAssFile
			txa
			beq	CheckCommand

;Zurück zum MegaaAssembler.
;Quelltext-Laufwerk auf Benutzer-Einstellung
;zurücksetzen falls über $f2='Quelltext-Laufwerk wechseln'
;das Laufwerk verändert wurde.
:ExitAutoAss		lda	#$00
			sta	Flag_AutoAssInWork
			lda	Opt_SourceDriveOrig
			sta	Opt_SourceDrive
			jmp	StartMenu

:CheckCommand		MoveW	Vec_AutoAssText,a0

			ldy	#$00
			lda	(a0L),y
			inc	a0L
			bne	:1
			inc	a0H

::1			cmp	#$f0
			bne	:2
			jmp	AutoSelectFile

::2			cmp	#$f1
			bne	:3
			jmp	AutoUserJob

::3			cmp	#$f2
			bne	:4
			jmp	AutoUserJob

::4			cmp	#$f4
			bne	:5
			jmp	AutoAssembler

::5			jmp	ExitAutoAss

;*** Nächste Datei assemblieren.
:AutoSelectFile		ldy	#$00
::1			lda	(a0L),y
			sta	LinkTextName,y
			beq	:2
			iny
			cpy	#17
			bcc	:1
			jmp	ExitAutoAss

::2			iny
			tya
			clc
			adc	a0L
			sta	a0L
			bcc	:3
			inc	a0H
::3			MoveW	a0,Vec_AutoAssText
			jmp	InitLinkProc

;*** Anwender-Routine ausführen.
:AutoUserJob		jsr	:1
			MoveW	a0,Vec_AutoAssText
			jmp	StartVLink

::1			MoveB	Opt_SourceDrive ,a1L
			MoveB	Opt_TargetDrive,a1H
			jmp	(a0)

;*** Quelltext-Laufwerk wechseln.
:AutoSwitchSrcDrv	ldy	#$00
			lda	(a0L),y
			inc	a0L
			bne	:1
			inc	a0H
::1			tax
			bne	:2
			lda	Opt_SourceDrive
::2			sta	Opt_SourceDrive
			jsr	NewSetDevice
			txa
			bne	:3
			jsr	NewOpenDisk
			txa
			bne	:3
			MoveW	a0,Vec_AutoAssText
			jmp	StartVLink
::3			jmp	ExitAutoAss

;*** Assembler starten.
:AutoAssembler		MoveW	a0,Vec_AutoAssText
			jmp	Mod_Menu

;*** AutoExec-Datei suchen.
:FindAutoAssFile	lda	Opt_AutoTxtDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadW	r6,NameOfAutoExec
			jsr	FindFile
			txa
			bne	:1

			LoadW	r7,$4000
			LoadW	r2,16384
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			jsr	ReadFile
::1			rts

;*** Link-Datei wählen.
:SlctTextFile		pha
			lda	LinkTextOnDisk
			beq	:1
			pla
			rts

::1			pla
			jsr	CopyLinkTxtNam		;Dateiname einlesen.

			ldy	#$01
			lda	(a0L),y
			cmp	#BOLDON
			beq	:2
			jsr	GotoFirstMenu
			jmp	InitLinkProc

::2			jsr	RecoverMenu

			lda	DM_Texte +6
			and	#%00111111
			sec
			sbc	#$02
			adc	Poi_1stEntryInTab
			sta	Poi_1stEntryInTab

			jsr	CopyNewFiles
			jmp	ReDoMenu

;*** Name des Linktextes kopieren.
:CopyLinkTxtNam		sta	a0L			;Zeiger auf Dateiname der
			LoadB	a0H,$00			;Textdatei berechnen.
			LoadW	a1 ,$0011
			ldx	#a0L
			ldy	#a1L
			jsr	DMult
			AddVW	MT03a,a0
			LoadW	a1,LinkTextName		;Zeiger auf Speicher für Name.
			ldx	#a0L
			ldy	#a1L
			jmp	CopyString		;Dateiname kopieren.

;*** VLIR-Linkvorgang initialisieren.
:InitLinkProc		lda	Opt_SourceDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk		;Diskette öffnen.

			LoadW	r6,LinkTextName
			jsr	FindFile
			txa
			beq	:1

			LoadW	r0,Dlg_SourceNotFound
			jsr	DoDlgBox

			ldx	#$ff
			sta	LinkTextNotOK
			inx
			stx	Flag_AutoAssInWork
			jmp	StartMenu

::1			LoadW	r0,StdVLIR_Name
			LoadW	r1,VLIR_FileName
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString		;Standard-Dateiname kopieren.

;*** Infoblock definieren.
			jsr	i_MoveData
			w	 Hdr_IconDataOrg
			w	 Hdr_IconData
			w	(Hdr_IconDataEnd - Hdr_IconDataOrg)

			lda	#$00
			ldx	#$04
			sta	ProgLoadAdr    +0
			stx	ProgLoadAdr    +1
			sta	ProgEndAdr     +0
			stx	ProgEndAdr     +1
			sta	ProgStartAdr   +0
			stx	ProgStartAdr   +1
			sta	ProgUserEndAdr +0
			sta	ProgUserEndAdr +1
			sta	ProgMaxEndAdr  +0
			sta	ProgMaxEndAdr  +1

			sta	Hdr_LoadAdr    +0
			stx	Hdr_LoadAdr    +1
			sta	Hdr_EndAdr     +0
			stx	Hdr_EndAdr     +1
			sta	Hdr_StartAdr   +0
			stx	Hdr_StartAdr   +1

			jsr	i_FillRam
			w	(Hdr_EndData - Hdr_Class)
			w	 Hdr_Class
			b	$00

			lda	#$80 ! USR
			sta	Hdr_CBM_Type
			lda	#APPLICATION
			sta	Hdr_GEOS_Type
			lda	#VLIR
			sta	Hdr_FileStruct
			lda	#$00
			sta	Hdr_ScrnMode
			lda	#"?"
			sta	Hdr_Class  +0
			sta	Hdr_Class  +1
			sta	Hdr_Class  +2
			sta	Hdr_Author +0
			sta	Hdr_Author +1
			sta	Hdr_Author +2
			sta	Hdr_Info +0
			sta	Hdr_Info +1
			sta	Hdr_Info +2

			lda	#$00
			sta	FileInfoTextVec

			jsr	PrepareScreen

			LoadW	r11,$0008		;Name des Linktextes anzeigen.
			LoadB	r1H,$16
			LoadW	r0,LinkInfo04
			jsr	PutString_40_80

			LoadW	r0,LinkTextName
			jsr	PutString_40_80

			jsr	i_FillRam		;Speicher für Moduldateinamen
			w	128 * 17		;löschen (max. 145 Dateinamen).
			w	ModulFileNames
			b	$00

			LoadW	r0,LinkTextName		;Zeiger auf Linktextdatei.
			LoadB	LinkTextNotOK,NULL	;Flag: "Kein Fehler".
			jsr	OpenRecordFile		;Textdatei öffnen.

			lda	#$00			;Zeiger auf ersten Datensatz.
			jsr	PointRecord

;*** Seite mit Moduldefinitionen suchen.
:FindModDefPage		LoadB	ModDefOpenFlag,NULL	;Flag: "Keine Moduldefinition".

			lda	curRecord		;Track/Sektor der ersten Seite
			asl				;einlesen.
			tay
			lda	fileHeader +$02,y
			tax
			iny
			lda	fileHeader +$02,y
			tay
			cpx	#$00			;Seite vorhanden ?
			bne	InitFirstPage		;Ja, weiter...
			jmp	ExitModDef		;VLIR-Datei suchen.

;*** Erste Seite initialisieren.
:InitFirstPage		stx	r1L			;Track/Sektor der ersten Seite
			sty	r1H			;speichern und in
			stx	CurSekAdr_Tr		;Zwischenspeicher übertragen.
			sty	CurSekAdr_Se
			LoadB	ByteInCurSek,$01	;Zeiger auf erstes Byte.
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten Sektor einlesen.

			jsr	DefFirstGWbyte		;Zeiger auf erstes Byte.
							;Unterschiede zwischen V1.0 und
							;V2.x beachten.

:ReadNextGW_Line	jsr	GetGW_TextLine		;Textzeile aus Linktextdatei
							;einlesen.

			lda	ModDefOpenFlag		;Moduldefinition gestartet ?
			beq	TestGW_TextLine		;Nein, weiter...

			inc	curRecord		;Zeiger auf nächsten Record.
			inc	curRecordCopy
			jmp	FindModDefPage

;*** Modulnamen eingelesen, VLIR-Datei suchen.
:ExitModDef		jmp	FindVLIR_File

;*** Textzeile auswerten.
:TestGW_TextLine	jsr	PackTextLine
			jsr	FindOpcode
			lda	LinkTextNotOK		;Linktext OK ?
			beq	:1			;Ja, weiter...
			jmp	StartMenu		;Hauptmenü aktivieren.
::1			jmp	ReadNextGW_Line		;Nächste Zeile auswerten.

;*** Opcodes aus Textzeile suchen.
:FindOpcode		lda	VLinkCommand
			bne	:1
			rts

::1			lda	VLinkCommand
			cmp	#$22
			bne	:2

			jmp	VLinkTextError_09	;Fehler: "Befehl fehlt!"

::2			lda	VLinkCommand +1
			bne	:8

::3			lda	VLinkCommand
			cmp	#"n"			;Name definieren.
			bne	:4
			jmp	DefFileName

::4			cmp	#"m"			;Moduldefinition einleiten.
			bne	:5
			jmp	StartModDef

::5			cmp	#"a"			;Autor definieren.
			bne	:6
			jmp	DefAutorName

::6			cmp	#"c"			;Klasse definieren.
			bne	:7
			jmp	DefFileClass

::7			cmp	#"i"			;Icon einbinden.
			bne	:8
			jmp	DefFileIcon

::8			cmp	#"h"			;Infotext einbinden.
			bne	:9
			jmp	DefFileInfoText

::9			jmp	VLinkTextError_08	;Fehler: "Befehl unbekannt!"

;*** Dateiname aus Linktext einlesen.
:DefFileName		LoadW	r0,VLIR_FileName
			LoadB	r1L,16
			jmp	CopyNameToVec		;Dateiname einlesen.

;*** Autor aus Linktext einlesen.
:DefAutorName		LoadW	r0,Hdr_Author
			LoadB	r1L,Hdr_AuthorLen
			jmp	CopyNameToVec

;*** Infotext aus Linktext einlesen.
:DefFileInfoText	LoadB	HeaderDef,$01
			LoadW	r0,Hdr_Info

			ldx	#95
			lda	FileInfoTextVec
			beq	:2

			cmp	#95
			bcc	:1
			lda	#$00

::1			tay
			lda	#CR
			sta	(r0L),y
			iny

			tya
			clc
			adc	r0L
			sta	r0L
			lda	#$00
			adc	r0H
			sta	r0H

			sty	r1L
			lda	#95
			sec
			sbc	r1L
			tax

::2			stx	r1L
			jsr	CopyNameToVec
			lda	FileInfoTextVec
			beq	:3
			iny
::3			tya
			clc
			adc	FileInfoTextVec
			sta	FileInfoTextVec
			rts

;*** GEOS-Klasse aus Linktext einlesen.
:DefFileClass		LoadW	r0,Hdr_Class
			LoadB	r1L,Hdr_ClassLen
			jmp	CopyNameToVec

;*** Icon aus Linktext einlesen.
:DefFileIcon		rts

;*** Ist VLIR-Datei bereits vorhanden ?
:FindVLIR_File		lda	Opt_TargetDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadW	r6,VLIR_FileName
			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Gefunden ?
			beq	:1			;Ja, weiter...

			LoadW	r11,$0081		;Neue VLIR-Datei wird erzeugt.
			LoadB	r1H,$16
			LoadW	r0,LinkInfo02
			jsr	PutString_40_80

			jmp	PrintLinkFile1		;Neue Größe für VLIR-Dateien.

::1			LoadW	r0,Dlg_FileExist	;VLIR-Datei vorhanden.
			jsr	DoDlgBox		;Linkvorgang fortsetzen ?

			lda	sysDBData
			cmp	#YES			;Ja, weiter.
			beq	ModifyVLIR_File

			cmp	#CANCEL			;Löschen.
			beq	:2

			LoadW	r0,VLIR_FileName	;Bestehende VLIR-Datei löschen.
			jsr	DeleteFile
			jmp	FindVLIR_File
::2			jmp	StartMenu 		;Abbruch.

;*** Alte Datei löschen.
:DelOldFile		lda	#$f0
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** VLIR-File wird verändert.
:ModifyVLIR_File	LoadW	r11,$0081
			LoadB	r1H,$16
			LoadW	r0,LinkInfo03
			jsr	PutString_40_80

			lda	dirEntryBuf +28
			ldx	dirEntryBuf +29

			bit	Opt_FileLenMode
			bmi	PrintLinkFile2

:PrintLinkFile1		lda	#< 2			;Größe für VLIR-Dateien mit
			ldx	#> 2			;Infoblock setzen.

:PrintLinkFile2		sta	VLIR_FileLen +0
			stx	VLIR_FileLen +1

			bit	ScreenMode
			bpl	:1
			lsr	r11H
			ror	r11L
::1			LoadW	r0,VLIR_FileName
			jsr	PutString_40_80

			jsr	FindLinkFiles		;Dateien prüfen.
			bcc	:2			;Test ok ? Ja, weiter...
			rts				;Linkvorgang abgebrochen.

::2			lda	ModulFileNames		;Dateien zum linken vorhanden ?
			bne	:3			;Ja, weiter...
			jmp	AddInfoHeader

::3			cmp	#$ff			;Ersten VLIR-Eintrag ersetzen ?
			bne	:4			;Ja, weiter...

			jsr	i_MoveData		;Standard-VLIR-Infoblock in
			w	Header			;Zwischenspeicher kopieren.
			w	diskBlkBuf
			w	$00ff

			jmp	SaveVLIR_Data
::4			jmp	FindFirstModul

;*** Prüfen ob alle Dateien verfügbar.
:FindLinkFiles		lda	#$00			;Zeiger auf Datei in
			sta	a0L			;VLIR-Dateitabelle.

:FindNextFile		lda	#$00			;Zeiger auf Tabelle mit
			sta	r0H			;Linkfiles berechnen.
			lda	a0L
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H			;Eingefügt!!! Dieser Befehl
							;behebt den VLink-Bug #1.
			clc
			adc	a0L
			sta	r0L
			lda	r0H
			adc	#$00
			sta	r0H

			AddVW	ModulFileNames,r0

			ldy	#$00
			lda	(r0L),y			;Ende Tabelle erreicht ?
			bne	:1			;Nein, weiter...
			clc				;OK.
			rts

::1			cmp	#$ff			;Entrag übergehen ?
			beq	SetVecToNxFile		;Ja, weiter...

			MoveW	r0,r6
			MoveW	r0,a1
			MoveW	r0,VecToCurFile+0
			jsr	FindFile		;VLIR-Eintrag auf Diskette
			txa				;suchen. Gefunden ?
			beq	TestWP_Flag		;Ja, weiter...

			cmp	#$05			;Nicht gefunden ?
			beq	EntryNotFound		;Ja, Fehler anzeigen.

			jsr	VLinkFileErr		;Diskettenfehler anzeigen.
			sec				;Abbruch!
			rts

;*** Datei aus Tabelle mit Linkfilenamen nicht gefunden.
:EntryNotFound		bit	Opt_IgnoreFileMode
			bpl	:2

			LoadW	r0,Dlg_FileNotFound	;Dialogbox anzeigen.
			jsr	DoDlgBox

			lda	sysDBData
			cmp	#CANCEL
			bne	:1
			sec				;Abbruch.
			rts

::1			cmp	#YES			;"Alle ignorieren" ?
			bne	:2			;Nein, weiter...

			lda	#$ff			;Alle nicht gefundenen
			sta	Opt_IgnoreFileMode	;Dateien ignorieren.

::2			MoveW	VecToCurFile,r0		;Dateieintrag übergehen.

			ldy	#$00
			lda	#$ff
			sta	(r0L),y
			bne	SetVecToNxFile

;*** Datei auf Schreibschutz testen.
:TestWP_Flag		lda	dirEntryBuf +$00	;Datei-Eintrag schreibge
			and	#$40			;schützt ?
			beq	SetVecToNxFile		;Nein, weiter...

			LoadW	r0,Dlg_WriteProtect
			jsr	DoDlgBox

			lda	sysDBData
			cmp	#CANCEL
			bne	SetVecToNxFile
			sec				;Abbruch!
			rts

:SetVecToNxFile		inc	a0L			;Zeiger auf nächste Datei.
			jmp	FindNextFile

;*** Ersten VLIR-Datei-Eintrag einlesen.
:FindFirstModul		LoadW	r6,ModulFileNames
			jsr	FindFile		;Datei suchen.
			txa				;Gefunden ?
			beq	:1			;Ja, weiter...
			rts

::1			jsr	LoadInfoBlock		;Infoblock einlesen.

:SaveVLIR_Data		lda	diskBlkBuf  +$45	;Programmparameter aus erster
			sta	GEOS_FileType		;VLIR-Datei einlesen.
			lda	diskBlkBuf  +$47
			sta	FileLoadAdr +  0
			lda	diskBlkBuf  +$48
			sta	FileLoadAdr +  1
			lda	diskBlkBuf  +$49
			sta	FileEndAdr  +  0
			lda	diskBlkBuf  +$4a
			sta	FileEndAdr  +  1
			lda	diskBlkBuf  +$4b
			sta	FileRunAdr  +  0
			lda	diskBlkBuf  +$4c
			sta	FileRunAdr  +  1
			lda	diskBlkBuf  +$60
			sta	FileScrnMode
			jsr	SaveFileIcon

			LoadW	Hdr_LoadAdr ,$0000	;Programm-Adressen löschen.
			LoadW	Hdr_EndAdr  ,$0000
			LoadW	Hdr_StartAdr,$0000

			lda	#"?"
			cmp	Hdr_Author +$00
			bne	:1
			cmp	Hdr_Author +$01
			bne	:1
			cmp	Hdr_Author +$02
			bne	:1
			jsr	i_MoveData		;Autoren-Name kopieren.
			w	diskBlkBuf +$61
			w	Hdr_Author
			w	Hdr_AuthorLen

::1			lda	#"?"
			cmp	Hdr_Class  +$00
			bne	:2
			cmp	Hdr_Class  +$01
			bne	:2
			cmp	Hdr_Class  +$02
			bne	:2
			jsr	i_MoveData		;GEOS-Klasse kopieren.
			w	diskBlkBuf +$4d
			w	Hdr_Class
			w	Hdr_ClassLen

::2			lda	#"?"
			cmp	Hdr_Info +$00
			bne	:2a
			cmp	Hdr_Info +$01
			bne	:2a
			cmp	Hdr_Info +$02
			bne	:2a
			jsr	i_MoveData		;GEOS-Infotext kopieren.
			w	diskBlkBuf +Hdr_InfoPos
			w	Hdr_Info
			w	Hdr_InfoLen

			LoadB	HeaderDef,$01

::2a			LoadW	r6,VLIR_FileName
			jsr	FindFile		;VLIR-Datei suchen.
			txa				;Gefunden ?
			bne	:4			;Nein, weiter...

			lda	ModulFileNames
			cmp	#$ff			;Ersten Eintrag aktualisieren ?
			bne	:3			;Ja, weiter...

			lda	dirEntryBuf +$13	;Infoblock einlesen.
			sta	r1L
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			lda	diskBlkBuf  +$45	;Programmparameter aus der
			sta	GEOS_FileType		;aktuellen VLIR-Datei einlesen.
			lda	diskBlkBuf  +$47
			sta	FileLoadAdr +  0
			lda	diskBlkBuf  +$48
			sta	FileLoadAdr +  1
			lda	diskBlkBuf  +$49
			sta	FileEndAdr  +  0
			lda	diskBlkBuf  +$4a
			sta	FileEndAdr  +  1
			lda	diskBlkBuf  +$4b
			sta	FileRunAdr  +  0
			lda	diskBlkBuf  +$4c
			sta	FileRunAdr  +  1
			lda	diskBlkBuf  +$60
			sta	FileScrnMode
			jsr	SaveFileIcon
::3			jsr	AddInfoHeader
			jmp	AddModToVLIR

::4			cmp	#$05			;Datei nicht gefunden ?
			beq	:5			;Ja, ignorieren. Weiter...
			jmp	VLinkError		;Diskettenfehler anzeigen.
::5			jmp	StartLinkJob

;*** Text für InfoHeader korrigieren.
:AddInfoHeader		lda	HeaderDef
			bne	:2
::1			rts

::2			LoadW	r6,VLIR_FileName
			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Gefunden ?
			bne	:1			;Ja, weiter...

			jsr	LoadInfoBlock
			jsr	i_MoveData
			w	Hdr_Info
			w	diskBlkBuf +Hdr_InfoPos
			w	Hdr_InfoLen

			jmp	SaveInfoBlock

;*** Infoblock einlesen.
:LoadInfoBlock		lda	dirEntryBuf +$13	;Zeiger auf Infoblock
			sta	r1L			;einlesen.
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jmp	GetBlock

;*** Infoblock speichern.
:SaveInfoBlock		lda	dirEntryBuf +$13	;Zeiger auf Infoblock
			sta	r1L			;einlesen.
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jmp	PutBlock

;*** Icon im Infoblock speichern.
:SaveFileIcon		ldy	#$3e
::1			lda	diskBlkBuf +$05,y
			sta	FileIconBuf,y
			dey
			bpl	:1
			rts

;*** Icon in Infoblock übertragen.
:SetFileIcon		ldy	#$3e
::1			lda	FileIconBuf,y
			sta	diskBlkBuf +$05,y
			dey
			bpl	:1
			rts

;*** Textfehler anzeigen und Fehler-Flag setzen.
:VLinkTextError_05	lda	#$05
			b $2c
:VLinkTextError_08	lda	#$08
			b $2c
:VLinkTextError_09	lda	#$09
			b $2c
:VLinkTextError_10	lda	#$0a
			b $2c
:VLinkTextError_11	lda	#$0b
			b $2c
:VLinkTextError_12	lda	#$0c
			jsr	VLinkError
			LoadB	LinkTextNotOK,$01
			rts

;*** Link-Fehler anzeigen.
:VLinkError		cmp	#$0d
			bcc	:1
			lda	#$07
::1			asl
			tay
			lda	FileErrAdr-2,y
			sta	a0L
			lda	FileErrAdr-1,y
			sta	a0H
			LoadW	r0,Dlg_LinkErr
			jmp	DoDlgBox

;*** Dateifehler ausgeben.
:VLinkFileErr		cmp	#$0d
			bcc	:1
			lda	#$07
::1			asl
			tay
			lda	FileErrAdr-2,y
			sta	a0L
			lda	FileErrAdr-1,y
			sta	a0H
			LoadW	r0,Dlg_FileErr
			jmp	DoDlgBox

;*** Dateien verbinden.
:StartLinkJob		LoadW	Header,VLIR_FileName
			LoadW	r9 ,Header
			LoadB	r10L,$00
			jsr	SaveFile

			LoadW	r6,VLIR_FileName	;VLIR-Datei suchen.
			jsr	FindFile

			jsr	LoadInfoBlock		;Infoblock einlesen.

			jsr	i_MoveData		;Infotext kopieren.
			w	Hdr_Info
			w	diskBlkBuf +160
			w	95

			jsr	SaveInfoBlock		;Infoblock speichern.

:AddModToVLIR		lda	dirEntryBuf +1		;Zeiger auf VLIR-Header
			ldx	dirEntryBuf +2		;einlesen.

			sta	VLIR_HeaderTr		;Zeiger auf VLIR-Header
			stx	VLIR_HeaderSe		;zwischenspeichern.

			sta	r1L			;VLIR-Header einlesen.
			stx	r1H
			LoadW	r4,VLIR_Header
			jsr	GetBlock

			lda	#$00
			sta	a0L			;Zeiger auf ersten Datensatz.

:AddNextMod		lda	#$00			;Zeiger auf Tabelle mit
			sta	r0H			;Linkfiles berechnen.
			lda	a0L
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			clc
			adc	a0L
			sta	r0L
			lda	r0H
			adc	#$00
			sta	r0H

			AddVW	ModulFileNames,r0

			ldy	#$00
			lda	(r0L),y			;Ende der Tabelle erreicht ?
			bne	:1			;Nein, weiter...
			jmp	EndLinkJob		;Ende.

::1			cmp	#$ff			;Eintrag übergehen ?
			bne	AddVLIR_File		;Ja, weiter...

			lda	a0L
			clc
			adc	#$01
			asl
			tay
			lda	VLIR_Header,y		;Eintrag bereits vorhanden ?
			bne	:2			;Ja, weiter...

			lda	#$00			;Eintrag löschen $00/$FF.
			sta	VLIR_Header,y
			iny
			lda	#$ff
			sta	VLIR_Header,y
::2			jmp	ViewCurEntry

;*** Neue Datei in VLIR-Header einbinden.
:AddVLIR_File		MoveW	r0,r6
			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			beq	:1			;Nein, weiter...
			jmp	VLinkError		;Diskettenfehler anzeigen.

::1			lda	VLIR_FileLen+  0	;Dateigröße addieren.
			clc
			adc	dirEntryBuf +$1c
			sta	VLIR_FileLen+  0
			lda	VLIR_FileLen+  1
			adc	dirEntryBuf +$1d
			sta	VLIR_FileLen+  1

			lda	dirEntryBuf +19		;Infoblock vorhanden?
			beq	:skip			; => Nein, weiter...

			SubVW	1,VLIR_FileLen		;Länge des Infoblocks abziehen.

::skip			lda	a0L
			clc
			adc	#$01
			asl
			tay
			lda	VLIR_Header  +  0,y	;Alten Eintrag aus VLIR-Header
			sta	OldVLIR_Entry+  0	;zwischenspeichern.
			sta	OldVLIR_Data +  0
			lda	VLIR_Header  +  1,y
			sta	OldVLIR_Entry+  1
			sta	OldVLIR_Data +  1

			lda	dirEntryBuf  +$01	;Neuen Eintrag in VLIR-Header
			sta	VLIR_Header  +  0,y	;übertragen.
			lda	dirEntryBuf  +$02
			sta	VLIR_Header  +  1,y

;*** Vorbereitungen zum löschen der
;    seq. Datei (VLIR-Eintrag).
			lda	OldVLIR_Entry+  0	;War Eintrag vorher bereits
			bne	:2			;vorhanden ? Ja, weiter...

			lda	dirEntryBuf  +$13	;Zeiger auf Infoblock des
			sta	OldVLIR_Entry+  0	;VLIR-Eintrages in Zwischen-
			lda	dirEntryBuf  +$14	;speicher kopieren.
			sta	OldVLIR_Entry+  1

			lda	#$00			;Zeiger auf Infoblock löschen
			sta	dirEntryBuf  +$13	;und Dateityp auf "BASIC"
			sta	dirEntryBuf  +$14	;zurücksetzen.
			sta	dirEntryBuf  +$16

::2			ldy	r5L			;Daten für VLIR-Eintrag in
			lda	dirEntryBuf  +$16	;Verzeichniseintrag zurück-
			sta	diskBlkBuf   +$16,y	;schreiben.
			lda	dirEntryBuf  +$13
			sta	diskBlkBuf   +$13,y
			lda	dirEntryBuf  +$14
			sta	diskBlkBuf   +$14,y

			lda	OldVLIR_Entry+  0	;Zeiger auf ersten Sektor
			sta	diskBlkBuf   +$01,y	;des VLIR-Eintrages setzen.
			lda	OldVLIR_Entry+  1
			sta	diskBlkBuf   +$02,y

			LoadW	r4,diskBlkBuf		;Verzeichnissektor
			jsr	PutBlock		;zurückschreiben.

			bit	Opt_FileLenMode		;Dateilänge korrigieren?
			bpl	ViewCurEntry		; => Nein, weiter...

			ldx	OldVLIR_Data +  0
			beq	ViewCurEntry
			ldy	OldVLIR_Data +  1
			jsr	SubOldFileLen

:ViewCurEntry		lda	#$01			;Eintrag auf Bildschirm
			ldx	a0L			;invertieren.
			jsr	Prn1FileOnScrn
			inc	a0L
			jmp	AddNextMod

;*** Dateien löschen und vom Bildschirm entfernen.
:EndLinkJob		lda	VLIR_HeaderTr		;VLIR-Header speichern.
			sta	r1L
			lda	VLIR_HeaderSe
			sta	r1H
			LoadW	r4,VLIR_Header
			jsr	PutBlock

			LoadW	r6,VLIR_FileName	;VLIR-Datei auf Diskette
			jsr	FindFile		;suchen.

			ldy	r5L
			lda	GEOS_FileType
			sta	diskBlkBuf  +$16,y

			lda	year
			sta	diskBlkBuf  +$17,y
			lda	month
			sta	diskBlkBuf  +$18,y
			lda	day
			sta	diskBlkBuf  +$19,y

			lda	hour
			sta	diskBlkBuf  +$1a,y
			lda	minutes
			sta	diskBlkBuf  +$1b,y

			lda	VLIR_FileLen+  0
			sta	diskBlkBuf  +$1c,y
			lda	VLIR_FileLen+  1
			sta	diskBlkBuf  +$1d,y

			LoadW	r4,diskBlkBuf
			jsr	PutBlock

			lda	dirEntryBuf +$13	;Aktuellen Infoblock der
			sta	r1L			;Link-Datei einlesen.
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			lda	GEOS_FileType		;Werte für Programmparameter
			sta	diskBlkBuf  +$45	;in Infoblock kopieren.
			lda	FileLoadAdr +  0
			sta	diskBlkBuf  +$47
			lda	FileLoadAdr +  1
			sta	diskBlkBuf  +$48
			lda	FileEndAdr  +  0
			sta	diskBlkBuf  +$49
			lda	FileEndAdr  +  1
			sta	diskBlkBuf  +$4a
			lda	FileRunAdr  +  0
			sta	diskBlkBuf  +$4b
			lda	FileRunAdr  +  1
			sta	diskBlkBuf  +$4c
			lda	FileScrnMode
			sta	diskBlkBuf  +$60

			jsr	SetFileIcon		;Datei-Icon kopieren.

			lda	dirEntryBuf +$13	;Neuen Infoblock speichern.
			sta	r1L
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	PutBlock

;*** Modul-Dateien löschen.
			lda	#$00			;Zeiger auf ersten VLIR-Datei.
			sta	a0L

:DelNextFile		lda	#$00			;Zeiger auf Tabelle mit
			sta	r0H			;Linkfiles berechnen.
			lda	a0L
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			clc
			adc	a0L
			sta	r0L
			lda	r0H
			adc	#$00
			sta	r0H

			AddVW	ModulFileNames,r0

			ldy	#$00
			lda	(r0L),y			;Alle Dateien gelöscht ?
			beq	EndLinkFiles		;Ja  , Ende...
			jmp	DelCurFile		;Nein, weiter...

;*** Abschlußmeldung.
:EndLinkFiles		LoadW	r11,$0032
			LoadB	r1H,$64
			LoadW	r0,LinkInfo01
			jsr	PutString_40_80

			LoadW	r0,VLIR_FileName
			LoadW	r1,MT05d
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString
			jmp	StartMenu

;*** Datei-Eintrag löschen.
:DelCurFile		cmp	#$ff
			beq	ClrFileEntry
			jsr	DeleteFile

;*** Eintrag vom Bildschirm löschen.
:ClrFileEntry		lda	#$02
			ldx	a0L
			jsr	Prn1FileOnScrn
			inc	a0L
			jmp	DelNextFile

;*** Dateilänge des alten Datensatzes berechnen.
:SubOldFileLen		PushB	r1L
			PushB	r1H
			PushB	r5L

::1			stx	r1L
			sty	r1H

			SubVW	1,VLIR_FileLen

			LoadW	r4,$7f00
			jsr	GetBlock

			ldy	$7f01
			ldx	$7f00
			bne	:1

::2			PopB	r5L
			PopB	r1H
			PopB	r1L

			rts

;*** Dezimalzahl einlesen.
:GetDecimal		LoadW	a6,NULL

			ldy	#$00
::1			lda	PackedTextLine,y
			beq	:2

			and	#%00001111
			clc
			adc	a6L
			sta	a6L
			lda	#$00
			adc	a6H
			sta	a6H

			iny
			lda	PackedTextLine,y
			beq	:2
			cmp	#$20
			beq	:2

			sty	a8L
			LoadW	a7,$000a
			ldx	#a6L
			ldy	#a7L
			jsr	DMult

			ldy	a8L
			jmp	:1

::2			rts

;*** Dezimalzahl suchen.
:FindDezCode		ldy	#$09
::1			cmp	DataTab_DEZ_HEX,y
			beq	:2
			dey
			bpl	:1
::2			tya
			rts

;*** Dateiname/Autor/GEOS-Klasse/Modulname kopieren.
:CopyNameToVec		ldy	#$00
::1			lda	PackedTextLine,y
			beq	:2
			cmp	#$22
			beq	:3
			iny
			bne	:1
::2			sec
			rts

::3			tya
			tax
			inx
			ldy	#$00
::4			lda	PackedTextLine,x
			sta	(r0L),y
			beq	:6
			cmp	#$22
			beq	:5
			dec	r1L
			beq	:6
			inx
			iny
			bne	:4
			iny
::5			lda	#$00
			sta	(r0L),y
::6			clc
			rts

;*** Ersten Sektor aus Linktext-Seite einlesen.
:OpenNewPage		LoadB	ModDefOpenFlag,$00	;Moduldefinition abschalten.

			inc	curRecord		;Zeiger auf nächste Seite.
			lda	curRecord
			asl
			tay
			lda	fileHeader +$02,y
			tax
			iny
			lda	fileHeader +$02,y
			tay
			cpx	#$00
			bne	:1
			sec
			rts

::1			stx	r1L
			sty	r1H

			MoveB	r1L,CurSekAdr_Tr	;Sektor merken.
			MoveB	r1H,CurSekAdr_Se

			LoadB	ByteInCurSek,$01	;Zeiger auf erstes Byte.
			LoadW	r4,diskBlkBuf		;Sektor einlesen.
			jsr	GetBlock
			jsr	DefFirstGWbyte		;Startbyte berechnen.
			clc
			rts

;*** Anzahl zu überlesender Bytes zu Beginn einer GeoWrite-Seite berechnen.
:DefFirstGWbyte		lda	#$19			;GeoWrite V1.1:
							;2  Byte Sektorverkettung,
							;20 Byte Seitendefinition,
							;4  Byte Zeichensatz.
			ldy	diskBlkBuf +$02
			cpy	#$11			;Erstes Byte = "ESC_RULER" ?
			bne	:1			;Nein, weiter...
			lda	#$1c			;GeoWrite V2.x:
							;2  Byte Sektorverkettung,
							;27 Byte Seitendefinition.
::1			sta	ByteInCurSek
			rts

;*** Byte aus Text einlesen.
:GetByteFromText	bcc	SetVecToNxByte

			stx	r1L
			sty	r1H

			MoveB	r1L,CurSekAdr_Tr
			MoveB	r1H,CurSekAdr_Se

			LoadB	ByteInCurSek,$01
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			jmp	SetVecToNxByte

:NoMoreBytes		sec
			rts

;*** Nächsten Sektor aus Linktext einlesen.
:GetNextSek		lda	diskBlkBuf +$00
			beq	NoMoreBytes
			ldy	diskBlkBuf +$01
			sta	r1L
			sty	r1H

			MoveB	r1L,CurSekAdr_Tr
			MoveB	r1H,CurSekAdr_Se

			LoadB	ByteInCurSek,$01
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

:SetVecToNxByte		inc	ByteInCurSek
			beq	GetNextSek

			lda	diskBlkBuf +$00
			bne	:1
			ldx	diskBlkBuf +$01
			inx
			cpx	ByteInCurSek
			beq	GetNextSek
::1			ldy	ByteInCurSek
			lda	diskBlkBuf +$00,y
			clc
			rts

;*** Neue Textzeile einlesen.
:GetGW_TextLine		lda	ModDefOpenFlag
			bne	:1
			lda	EndOfTextFile
			beq	StartNewTextLine
			lda	#$01
			sta	ModDefOpenFlag
			lda	#$00
			sta	EndOfTextFile
::1			lda	#$00
			sta	CurTextLine
			rts

;*** Neue Textzeile beginnen.
:StartNewTextLine	lda	#$00
			sta	AddByteFlag
			sta	LenOfTextLine
			sta	StringOpenFlag

;*** Nächstes Byte aus Linktext auswerten.
:ChkNextByte		clc
			jsr	GetByteFromText
			bcc	:1
			jmp	SetEndText

::1			cmp	#NEWCARDSET
			bne	ContTestByte
			jmp	Ignore3Bytes
:Byte_EOT		jmp	DefEndOfText
:Byte_EOL		jmp	SetEndTextLine

:ContTestByte		cmp	#ESC_RULER
			bne	:1
			jmp	Ignore26Bytes

::1			cmp	#ESC_GRAPHICS
			bne	:2
			jmp	CopyGraphics

::2			cmp	#CR
			beq	Byte_EOT
			cmp	#PAGE_BREAK
			beq	Byte_EOT
			cmp	#NULL
			beq	Byte_EOT

			ldx	StringOpenFlag
			bne	:3
			cmp	#";"
			beq	Byte_EOL

::3			cmp	#$22
			bne	:4
			lda	StringOpenFlag
			eor	#$ff
			sta	StringOpenFlag
			lda	#$22

::4			cmp	#TAB
			bne	:5
			lda	#" "

::5			ldy	LenOfTextLine
			sta	CurTextLine,y
			cmp	#" "
			beq	:6

			LoadB	AddByteFlag,$01

::6			lda	AddByteFlag
			bne	:7
			dec	LenOfTextLine
::7			inc	LenOfTextLine
			lda	#$a0
			cmp	LenOfTextLine
			bne	ChkNextByte

;*** Auf Zeilenende testen.
:CheckEndOfLine		clc
			jsr	GetByteFromText
			bcs	SetEndText

			cmp	#NEWCARDSET
			beq	Ignore_NEWCARDSET
			cmp	#CR
			bne	CheckEndOfLine
			lda	#$00
			sta	VLinkCommand +1
			rts

;*** Text-Ende erreicht.
:SetEndText		lda	#$01
			sta	EndOfTextFile
			jmp	DefEndOfText

;*** Die näöchsten 3 Bytes aus Text überlesen.
:Ignore3Bytes		jsr	Get3BytFromText
			jmp	ChkNextByte

:Ignore_NEWCARDSET	jsr	Get3BytFromText
			jmp	CheckEndOfLine

;*** 3 Byte aus Text einlesen.
:Get3BytFromText	clc
			jsr	GetByteFromText
			clc
			jsr	GetByteFromText
			clc
			jsr	GetByteFromText
			rts

;*** ESC_RULER überlesen.
:Ignore26Bytes		lda	#$1a
			sta	IgnoreCounter
::1			clc
			jsr	GetByteFromText
			dec	IgnoreCounter
			bne	:1
			jmp	ChkNextByte

;*** ESC_GRAPHICS-Daten kopieren.
:CopyGraphics		ldy	#$05
			sty	CopyCounter
			lda	#" "
			ldy	LenOfTextLine
			sta	CurTextLine,y
			inc	LenOfTextLine
			lda	#ESC_GRAPHICS
			bne	WriteBytInBuf

;*** Ein Byte aus Text einlesen.
:Copy1Byte		clc
			jsr	GetByteFromText

;*** Byte in Zwischenspeicher kopieren.
:WriteBytInBuf		ldy	LenOfTextLine
			sta	CurTextLine,y
			inc	LenOfTextLine
			dec	CopyCounter
			bne	Copy1Byte
			jmp	DefEndOfText

;*** Textzeile aus GeoWrite-Text komprimieren.
:PackTextLine		lda	#$00
			sta	VLinkCommand   +0
			sta	VLinkCommand   +1
			sta	PackedTextLine
			sta	VecToCurLine
			sta	VecToPackedData

			lda	CurTextLine
			cmp	#"/"
			bne	:1
			sta	VLinkCommand
			rts

::1			ldy	VecToCurLine
			lda	CurTextLine,y
			cmp	#$00
			bne	:2
			rts

::2			cmp	#" "
			bne	:3
			inc	VecToCurLine
			jmp	:1

::3			LoadW	a0,VLinkCommand
			jsr	ConvertTextLine
			bcc	:4
			rts

::4			ldy	VecToCurLine
			lda	CurTextLine,y
			cmp	#$00
			bne	:5
			rts

::5			cmp	#" "
			bne	:6
			inc	VecToCurLine
			jmp	:4

::6			LoadW	a0,PackedTextLine

			lda	#$00
			sta	VecToPackedData

::7			ldy	VecToCurLine
			lda	CurTextLine,y
			cmp	#$00
			bne	:8
			rts

::8			ldy	VecToPackedData
			sta	(a0L),y
			inc	VecToPackedData
			inc	VecToCurLine
			iny
			lda	#$00
			sta	(a0L),y
			jmp	:7

;*** Textzeile konvertieren.
:ConvertTextLine	lda	#$00
			sta	VecToPackedData

:ConvNextByte		ldy	VecToCurLine
			lda	CurTextLine,y
			cmp	#$20
			beq	:1
			cmp	#$a0
			beq	:1
			cmp	#$10
			beq	CopyESC_GRAPHICS
			cmp	#NULL
			bne	:2
			sec
			rts
::1			clc
			rts

::2			ldy	VecToPackedData
			sta	(a0L),y
			inc	VecToPackedData
			inc	VecToCurLine
			iny
			lda	#$00
			sta	(a0L),y
			jmp	ConvNextByte

;*** ESC_GRAPHICS kopieren.
:CopyESC_GRAPHICS	ldy	#$05
			sty	CopyCodeBytes

::1			ldy	VecToPackedData
			sta	(a0L),y
			inc	VecToPackedData
			inc	VecToCurLine

			ldy	VecToCurLine
			lda	CurTextLine,y
			dec	CopyCodeBytes
			bne	:1

			ldy	VecToPackedData
			lda	#$00
			sta	(a0L),y
			jmp	ConvNextByte

;*** Ende Text markieren.
:DefEndOfText		ldy	LenOfTextLine
			lda	#$00
			sta	CurTextLine,y
			rts

;*** Ende Textzeile markieren.
:SetEndTextLine		ldy	LenOfTextLine
			lda	#$00
			sta	CurTextLine,y
			jmp	CheckEndOfLine

;*** Moduldefinition einleiten.
:StartModDef		lda	#$00
			sta	ModulCount
			sta	CountEmptyMod

:GetNextModName		lda	CountEmptyMod		;Module-Einträge übergehen ?
			beq	FindModDefEntry		;Nein, weiter...

			dec	CountEmptyMod		;Leeres Modul einfügen.
			LoadB	PackedTextLine,NULL
			jmp	TestSyntax

:FindModDefEntry	jsr	GetGW_TextLine		;Textzeile einlesen.

			lda	ModDefOpenFlag		;Moduldefinition gestartet ?
			beq	:1			;Nein, weiter...
			jsr	OpenNewPage		;Definitionsseite öffnen.
			bcc	:1			;Seite gefunden, weiter...

			jmp	VLinkTextError_12	;Fehler: "Ende Mod.Def. fehlt!"

::1			jsr	PackTextLine		;Textzeile konvertieren.

;*** Syntax in Befehlszeile testen.
:TestSyntax		lda	VLinkCommand +0		;Leerzeile ?
			beq	GetNextModName		;Ja, weiter...

			lda	VLinkCommand +1
			bne	:1

			lda	VLinkCommand
			cmp	#"-"			;Modul-Eintrag ?
			beq	CopyModName		;Ja, auswerten.
			cmp	#"/"			;Definition beendet ?
			beq	CopyModName		;Ja, weiter...

::1			jmp	VLinkTextError_10	;Fehler: "Modulname falsch!"

;*** Zeiger auf Speicher für Modulname berechnen.
:CopyModName		lda	#$00
			sta	a0H
			lda	ModulCount
			asl
			rol	a0H
			asl
			rol	a0H
			asl
			rol	a0H
			asl
			rol	a0H
			clc
			adc	ModulCount
			bcc	:1
			inc	a0H
::1			sta	a0L

			AddVW	ModulFileNames,a0

			lda	VLinkCommand
			cmp	#"/"			;Moduldefinition abschließen ?
			bne	:2			;Nein, weiter...

			lda	#$00			;Ende Datei-Tabelle definieren.
			tay
			sta	(a0L),y
			rts

::2			MoveW	a0,r0
			LoadB	r1L,16
			jsr	CopyNameToVec		;Dateiname in Modultabelle
			bcc	:3			;übertragen.

			jsr	GetNotUsedMod

			ldy	#$00
			lda	#$ff
			sta	(r0L),y

::3			MoveW	r0,VecToFNameBuf	;Zeiger auf Modulnamen
							;zwischenspeichern.

			lda	#$00
			ldx	ModulCount
			jsr	Prn1FileOnScrn		;Modulname ausgeben.
			inc	ModulCount

			lda	#$80
			cmp	ModulCount		;Mehr als 127 Module ?
			bne	GetNextModEntry		;Nein, weiter...

			MoveW	VecToFNameBuf,a0	;Fehler: "Zu viele Module!".
			LoadW	r0,Dlg_TooManyVLIR
			jsr	DoDlgBox
			LoadB	LinkTextNotOK,$01
			rts

:GetNextModEntry	jmp	GetNextModName

;*** Anzahl "Nicht belegter VLIR-Datensatz" einlesen.
:GetNotUsedMod		lda	CountEmptyMod
			bne	:1
			lda	PackedTextLine
			beq	:1
			jsr	FindDezCode
			bpl	:2
::1			rts

::2			jsr	GetDecimal		;Anzahl leere Module einlesen.

			lda	a6L
			clc
			adc	ModulCount
			bcs	:3
			cmp	#$80
			bcs	:3

			lda	a6L			;Anzahl merken.
			sta	CountEmptyMod
			dec	CountEmptyMod
			bpl	:1

			lda	#$00
			sta	CountEmptyMod
			rts

::3			jmp	VLinkTextError_11

;*** Datei-Eintrag auf Bildschirm ausgeben.
;    AKKU = $00, Name Anzeigen
;           $01, Name invertieren
;           $02, Name löschen
;    xReg = Nummer in Tabelle.
:Prn1FileOnScrn		pha
			txa
			and	#%11000000		;Abfrage unsinnig, da nur die
			beq	:1			;Werte $00,$01,$02 übergeben
			pla				;werden.
			rts

::1			stx	CurFileNum		;Dateinummer merken.

			lda	a0L			;Zeile berechnen.
			pha
			txa
			and	#%00001111
			sta	a0L
			LoadB	a0H,$00
			LoadW	a1 ,$000a
			ldx	#a0L
			ldy	#a1L
			jsr	DMult

			lda	a0L
			clc
			adc	#$28
			sta	FileScrnYpos

			lda	CurFileNum		;Spalte berechnen.
			and	#%11110000
			lsr
			lsr
			lsr
			lsr
			sta	a0L
			LoadB	a0H,$00
			LoadW	a1 ,$0050

			ldx	#a0L
			ldy	#a1L
			jsr	DMult
			lda	a0L
			sta	FileScrnXpos+0
			lda	a0H
			sta	FileScrnXpos+1
			pla
			sta	a0L
			pla
			bne	SetRecToFile

			MoveW	FileScrnXpos,r11	;Dateiname ausgeben.
			MoveB	FileScrnYpos,r1H
			jmp	PutString_40_80

;*** Dateieintrag auf Bildschirm
;    AKKU = $01, Name invertieren
;           $02, Name löschen
:SetRecToFile		pha

			MoveW	FileScrnXpos,r3
			MoveW	FileScrnXpos,r4

			lda	FileScrnYpos
			sec
			sbc	#$07
			sta	r2L
			clc
			adc	#$09
			sta	r2H

			AddVW	$004f,r4

			pla
			cmp	#$01
			bne	:1
			jmp	InvertRec_40_80		;Dateiname invertieren.

::1			lda	#$00
			jsr	SetPattern
			jmp	Rectangle_40_80		;Dateiname löschen.

;*** Zwischen 40 und 80-Zeichen-Modus wechseln.
:Switch40_80		jsr	GotoFirstMenu		;Hauptmenü aktivieren.

			lda	c128Flag		;C128-Modus ?
			bpl	:1			;Nein, Abbruch...

			jsr	SwapGrfxMode		;Grafikmodus umschalten.

			lda	Opt_BootDrive		;MegaAssembler-Laufwerk
			jsr	NewSetDevice		;aktivieren.
			jsr	NewOpenDisk
			jmp	DoInfoScreen

::1			rts

;*** Grafikmodus wechseln, X-Koordinaten anpassen.
:SwapGrfxMode		lda	graphMode		;Grafikmodus umschalten.
			eor	#$80
			sta	graphMode
			sta	ScreenMode

			jsr	SetNewMode

;*** 40/80-Zeichen initialisieren.
:SetXpos40_80		lda	c128Flag
			bpl	:1
			lda	graphMode
			bmi	:2

;*** Dialogboxen für 40-Zeichen definieren.
::1			LoadW	r0,Word40_Data
			jsr	DefWordData
			LoadW	r0,Byte40_Data
			jmp	DefByteData

;*** Dialogboxen für 80-Zeichen definieren.
::2			LoadW	r0,Word80_Data
			jsr	DefWordData
			LoadW	r0,Byte80_Data
			jmp	DefByteData

;*** 40/80-Zeichen: Rechteck zeichnen.
:Rectangle_40_80	bit	ScreenMode
			bpl	:1
			asl	r3L
			rol	r3H
			asl	r4L
			rol	r4H
			inc	r4L
			bne	:1
			inc	r4H
::1			jmp	Rectangle

;*** 40/80-Zeichen: Linie zeichen.
:DrawLine_40_80		jmp	DrawLine

;*** 40/80-Zeichen: Zahl ausgeben.
:PutDecimal_40_80	bit	ScreenMode
			bpl	:1
			asl	r11L
			rol	r11H
::1			jmp	PutDecimal

;*** 40/80-Zeichen: Text ausgeben.
:PutString_40_80	bit	ScreenMode
			bpl	:1
			asl	r11L
			rol	r11H
::1			jmp	PutString

;*** 40/80-Zeichen: Zeichen ausgeben.
:PutChar_40_80		bit	ScreenMode
			bpl	:1
			asl	r11L
			rol	r11H
::1			jmp	PutChar

;*** 40/80-Zeichen: Rechteck invertieren.
:InvertRec_40_80	bit	ScreenMode
			bpl	:1
			asl	r3L
			rol	r3H
			asl	r4L
			rol	r4H
::1			jmp	InvertRectangle

;*** 40/80-Zeichen: Rahmen zeichnen.
:FrameRec_40_80		bit	ScreenMode
			bpl	:1
			asl	r3L
			rol	r3H
			asl	r4L
			rol	r4H
::1			jmp	FrameRectangle

;*** Word-Wert in Adresse kopieren.
:DefWordData		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			ora	r1L
			beq	:1

			iny
			lda	(r0L),y
			sta	r2L
			iny
			lda	(r0L),y
			sta	r2H

			ldy	#$00
			lda	r2L
			sta	(r1L),y
			iny
			lda	r2H
			sta	(r1L),y

			AddVW	4,r0
			jmp	DefWordData

::1			rts

;*** Byte-Wert in Adresse kopieren.
:DefByteData		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			ora	r1L
			beq	:1

			iny
			lda	(r0L),y
			ldy	#$00
			sta	(r1L),y

			AddVW	3,r0
			jmp	DefByteData

::1			rts

;*** Dummy-Icon.
:DummyIconTab		b $01
			w $0000
			b $00

			w $0000
			b $00,$00,$01,$01
			w $0000

;*** Vorgabe für VLIR-Dateinamen.
:StdVLIR_Name		b "VLIR-Datei",NULL
:VLIR_FileName		s 17

;** Menüeintrag falls keine Linktexte verfügbar.
:NoTextOnDisk		b "Kein Linktext!",NULL

:MoreTextFiles		b PLAINTEXT,BOLDON,">> Weiter",PLAINTEXT,NULL
:Go1stTextFile		b PLAINTEXT,BOLDON,"<< Anfang",PLAINTEXT,NULL

;*** Zeiger auf VLIR_Header bestehendes Link-File.
:VLIR_HeaderTr		b $00
:VLIR_HeaderSe		b $00

;*** Daten für Programmparameter.
:GEOS_FileType		b $00
:FileLoadAdr		w $0000
:FileEndAdr		w $0000
:FileRunAdr		w $0000
:FileScrnMode		b $00
:FileInfoTextVec	b $00

;*** Infotexte.
:LinkInfo01		b PLAINTEXT,BOLDON
			b "Linkvorgang erfolgreich abgeschlossen!",NULL
:LinkInfo02		b PLAINTEXT,BOLDON
			b " Erzeugte Datei: ",PLAINTEXT,NULL
:LinkInfo03		b PLAINTEXT,BOLDON
			b " Korrigiere Datei: ",PLAINTEXT,NULL
:LinkInfo04		b PLAINTEXT,BOLDON
			b " Text: ",PLAINTEXT,NULL

;*** GeoWrite-Informationen.
:ClassGeoWrite		b "geoWrite    " ,NULL
:ClassWriteImage	b "Write Image V",NULL

;*** Tabelle mit Zeigern auf Fehlertexte.
:FileErrAdr		w FileErrTxt01,FileErrTxt05
			w FileErrTxt01,FileErrTxt02
			w FileErrTxt03,FileErrTxt04
			w FileErrTxt05,FileErrTxt06
			w FileErrTxt07,FileErrTxt08
			w FileErrTxt09,FileErrTxt10

;*** Fehlermeldungen.
:FileErrTxt01		b "Diskette voll",NULL
:FileErrTxt02		b "Directory voll",NULL
:FileErrTxt03		b "Datei nicht gefunden",NULL
:FileErrTxt04		b "Diskette fehlerhaft",NULL
:FileErrTxt05		b "Diskettenfehler",NULL
:FileErrTxt06		b "Befehl unbekannt",NULL
:FileErrTxt07		b "Befehl fehlt",NULL
:FileErrTxt08		b "Modulname falsch angegeben",NULL
:FileErrTxt09		b "Wert zu groß",NULL
:FileErrTxt10		b "Moduldefinition nicht abgeschlossen!",NULL

;*** Aktuelle Textzeile/Aktuelle Labelbezeichnung.
:CurTextLine		s 200

;*** 40/80-Zeichen-Daten.
:Word40_Data		w DM_MainMenu+4 ,$009d
			w DM_geos+4 ,$0060
			w DM_Texte+2 ,$001c
			w DM_Texte+4 ,$007c
			w DM_Parameter+2 ,$003b
			w DM_Parameter+4 ,$00bf
			w DM_SlctDrive+2 ,$0090
			w DM_SlctDrive+4 ,$00cf
			w DM_Verlassen+2 ,$006d
			w DM_Verlassen+4 ,$00f3
			w DM_GeoWrite+2 ,$00b0
			w DM_GeoWrite+4 ,$0127
			w X11	+0 ,$0000
			w X11	+2 ,$013f
			w X14	 ,$000f
			w X100	+0 ,$00c4
			w X100	+2 ,$013a
			w X101	+0 ,$00c2
			w X101	+2 ,$013c
			w X102	+0 ,$00c1
			w X102	+2 ,$013d
			w X103	+0 ,$00c3
			w X103	+2 ,$013b
			w X104	+0 ,$00c1
			w X104	+2 ,$013d
			w X105	+0 ,$00c0
			w X105	+2 ,$013e
			w X106	+0 ,$00c8
			w X106	+2 ,$0136
			w X107	 ,$00d4
			w $0000

:Byte40_Data		w IconData3 +4
			b $06
			w $0000

:Word80_Data		w DM_MainMenu+4 ,$00d4
			w DM_geos+4 ,$0090
			w DM_Texte+2 ,$0024
			w DM_Texte+4 ,$00b4
			w DM_Parameter+2 ,$004f
			w DM_Parameter+4 ,$0107
			w DM_SlctDrive+2 ,$00a0
			w DM_SlctDrive+4 ,$00ff
			w DM_Verlassen+2 ,$0094
			w DM_Verlassen+4 ,$0154
			w DM_GeoWrite+2 ,$0100
			w DM_GeoWrite+4 ,$01b7
			w X11	+0 ,$0000
			w X11	+2 ,$027f
			w X14	 ,$001e
			w X100	+0 ,$80c4
			w X100	+2 ,$813a
			w X101	+0 ,$80c2
			w X101	+2 ,$813c
			w X102	+0 ,$80c1
			w X102	+2 ,$813d
			w X103	+0 ,$80c3
			w X103	+2 ,$813b
			w X104	+0 ,$80c1
			w X104	+2 ,$813d
			w X105	+0 ,$80c0
			w X105	+2 ,$813e
			w X106	+0 ,$80c8
			w X106	+2 ,$8136
			w X107	 ,$80d4
			w $0000

:Byte80_Data		w IconData3 +4
			b $86
			w $0000

;*** Dialogbox: "Zuviele VLIR-Datensätze"
:Dlg_SourceNotFound	b $81
			b DBTXTSTR   ,$10,$0e
			w :1
			b DBTXTSTR   ,$10,$1c
			w :2
			b DBTXTSTR   ,$10,$27
			w :3
			b DBTXTSTR   ,$10,$34
			w LinkTextName
			b CANCEL     ,$10,$48
			b DBSYSOPV
			b NULL

::1			b BOLDON
			b "Schwerer Fehler!",PLAINTEXT,NULL
::2			b "Die LinkText-Datei wurde",NULL
::3			b "nicht auf Diskette gefunden!",BOLDON,NULL

;*** Dialogbox: "Datei ist schreibgeschützt!"
:Dlg_WriteProtect	b $81
			b DBTXTSTR ,$10,$0e
			w :1
			b DBTXTSTR ,$10,$1c
			w :2
			b DBVARSTR ,$18,$29
			b a1L
			b DBTXTSTR ,$10,$36
			w :3
			b OK       ,$02,$48
			b CANCEL   ,$10,$48
			b NULL

::1			b BOLDON   ,"Warnung!",NULL
::2			b PLAINTEXT,"Die Datei",BOLDON,NULL
::3			b PLAINTEXT,"ist schreibgeschützt.",NULL

;*** Dialogbox: "Datei nicht gefunden!"
:Dlg_FileNotFound	b $81
			b DBTXTSTR ,$10,$0e
			w :1
			b DBTXTSTR ,$10,$1c
			w :2
			b DBVARSTR ,$18,$29
			b a1L
			b DBTXTSTR ,$10,$36
			w :3
			b DBTXTSTR ,$10,$41
			w :4
			b OK       ,$02,$48
			b YES      ,$09,$48
			b CANCEL   ,$10,$48
			b NULL

::1			b BOLDON   ,"Warnung!",NULL
::2			b PLAINTEXT,"VLIR-Modul nicht gefunden:",BOLDON,NULL
::3			b PLAINTEXT,"Diese Warnung und alle weiteren",NULL
::4			b           "Meldungen dieser Art ignorieren?",NULL

;*** Dialogbox: "Zuviele VLIR-Datensätze"
:Dlg_TooManyVLIR	b $81
			b DBTXTSTR   ,$10,$0e
			w :1
			b DBTXTSTR   ,$10,$1c
			w :2
			b DBTXTSTR   ,$10,$27
			w :3
			b DBTXTSTR   ,$10,$32
			w :4
			b DBVARSTR   ,$18,$3f
			b a0L
			b CANCEL     ,$10,$48
			b DBSYSOPV
			b NULL

::1			b BOLDON
			b "Schwerer Fehler!",PLAINTEXT,NULL
::2			b "Mehr als 127 Datensätze kann",NULL
::3			b "eine VLIR-Datei nicht aufnehmen!",NULL
::4			b "Fehler aufgetreten bei Modul:",BOLDON,NULL

;*** Dialogbox: "Datei bereits vorhanden"
:Dlg_FileExist		b $81
			b DBTXTSTR   ,$10,$0e
			w :1
			b DBTXTSTR   ,$10,$1c
			w :2
			b DBTXTSTR   ,$10,$27
			w :3
			b DBTXTSTR   ,$10,$36
			w :4
			b DBTXTSTR   ,$10,$41
			w :5
			b YES        ,$02,$48
			b DBUSRICON  ,$09,$48
			w IconData3
			b CANCEL     ,$10,$48
			b NULL

::1			b BOLDON
			b "Warnung!",PLAINTEXT,NULL
::2			b "Die VLIR-Datei existiert bereits",NULL
::3			b "auf dieser Diskette.",NULL
::4			b "Linkvorgang fortsetzen ?",NULL
::5			b "(VLIR-Module werden aktualisiert)",NULL

;*** Daten für "Löschen"-Icon.
:IconData3		w Icon_DelFile
			b $00,$00,Icon_03x,Icon_03y
			w DelOldFile

;*** Dialogbox: Link-Fehler.
:Dlg_LinkErr		b $81
			b DBTXTSTR   ,$10,$0e
			w :1
			b DBTXTSTR   ,$10,$1c
			w :2
			b DBVARSTR   ,$18,$28
			b a0L
			b DBTXTSTR   ,$10,$35
			w :3
			b DBTXTSTR   ,$18,$41
			w CurTextLine
			b OK         ,$02,$48
			b NULL

::1			b BOLDON   ,"Schwerer Fehler!",NULL
::2			b PLAINTEXT,"Ein Fehler ist aufgetreten:",BOLDON,NULL
::3			b PLAINTEXT,"in Zeile:",BOLDON,NULL

;*** Dialogbox: Datei-Fehler.
:Dlg_FileErr		b $81
			b DBTXTSTR   ,$10,$0e
			w :1
			b DBTXTSTR   ,$10,$1c
			w :2
			b DBVARSTR   ,$18,$28
			b a0L
			b DBTXTSTR   ,$10,$35
			w :3
			b DBVARSTR   ,$18,$41
			b a1L
			b OK         ,$02,$48
			b NULL

::1			b BOLDON   ,"Schwerer Fehler!",NULL
::2			b PLAINTEXT,"Ein Fehler ist aufgetreten:",BOLDON,NULL
::3			b PLAINTEXT,"bei Datei:",BOLDON,NULL

;*** Dialogbox: Partition wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Infobox MegaAssembler.
:DlgInfoBox		t "src.MegaAss.info"

;*** GEOS-Hauptmenü.
:DM_MainMenu		b $00
			b $0e
			w $0000
			w $009d

			b $04 ! HORIZONTAL ! UN_CONSTRAINED

			w MT01a
			b SUB_MENU
			w DM_geos

			w MT01b
			b SUB_MENU
			w DM_Texte

			w MT01c
			b SUB_MENU
			w DM_Parameter

			w MT01d
			b SUB_MENU
			w DM_Verlassen

:MT01a			b "geos",NULL
:MT01b			b "Texte",NULL
:MT01c			b "Parameter",NULL
:MT01d			b "Verlassen",NULL

;*** GEOS-Menü.
:DM_geos		b $0e
			b $2b
			w $0000
			w $0055

			b $02 ! VERTICAL ! UN_CONSTRAINED

			w MT02a
			b MENU_ACTION
			w InfoBox

			w MT02b
			b MENU_ACTION
			w Switch40_80

			w MT02c
			b MENU_ACTION
			w LoadDA_File

			w MT02d
			b MENU_ACTION
			w LoadDA_File

			w MT02e
			b MENU_ACTION
			w LoadDA_File

			w MT02f
			b MENU_ACTION
			w LoadDA_File

			w MT02g
			b MENU_ACTION
			w LoadDA_File

			w MT02h
			b MENU_ACTION
			w LoadDA_File

			w MT02i
			b MENU_ACTION
			w LoadDA_File

			w MT02j
			b MENU_ACTION
			w LoadDA_File

:MT02a			b PLAINTEXT,"Info MegaAss",NULL
:MT02b			b PLAINTEXT,"40/80-Zeichen",PLAINTEXT,NULL
:MT02c			s 17
:MT02d			s 17
:MT02e			s 17
:MT02f			s 17
:MT02g			s 17
:MT02h			s 17
:MT02i			s 17
:MT02j			s 17

;*** GEOS Quelltext-Menü.
:DM_Texte		b $0e
			b $1d
			w $001c
			w $0071

			b $00 ! VERTICAL ! UN_CONSTRAINED

			w MT03a
			b MENU_ACTION
			w SlctTextFile

			w MT03b
			b MENU_ACTION
			w SlctTextFile

			w MT03c
			b MENU_ACTION
			w SlctTextFile

			w MT03d
			b MENU_ACTION
			w SlctTextFile

			w MT03e
			b MENU_ACTION
			w SlctTextFile

			w MT03f
			b MENU_ACTION
			w SlctTextFile

			w MT03g
			b MENU_ACTION
			w SlctTextFile

			w MT03h
			b MENU_ACTION
			w SlctTextFile

			w MT03i
			b MENU_ACTION
			w SlctTextFile

			w MT03j
			b MENU_ACTION
			w SlctTextFile

			w MT03k
			b MENU_ACTION
			w SlctTextFile

			w MT03l
			b MENU_ACTION
			w SlctTextFile

			w MT03m
			b MENU_ACTION
			w SlctTextFile

:MT03a			s 17
:MT03b			s 17
:MT03c			s 17
:MT03d			s 17
:MT03e			s 17
:MT03f			s 17
:MT03g			s 17
:MT03h			s 17
:MT03i			s 17
:MT03j			s 17
:MT03k			s 17
:MT03l			s 17
:MT03m			s 17

;*** GEOS-Parameter-Menü.
:DM_Parameter		b $0e
			b $0e +7*14 +1
			w $003b
			w $00ba

			b $07 ! VERTICAL ! UN_CONSTRAINED

			w MT04a
			b DYN_SUB_MENU
			w SlctSourceDrv

			w MT04b
			b MENU_ACTION
			w ChangeSrcDisk

			w MT04e
			b DYN_SUB_MENU
			w SlctTargetDrv

			w MT04g
			b MENU_ACTION
			w ChangeTgtDisk

			w MT04c
			b MENU_ACTION
			w DefIgnoreFileMode

			w MT04d
			b MENU_ACTION
			w DefFileLenMode

			w MT04f
			b MENU_ACTION
			w SaveParameter

:MT04a			b PLAINTEXT,"Laufwerk A: Linktexte",NULL
:MT04b			b PLAINTEXT,"Quelldiskette wechseln",PLAINTEXT,NULL
:MT04e			b           "Laufwerk A: Programmcode",NULL
:MT04g			b PLAINTEXT,"Zieldiskette wechseln",PLAINTEXT,NULL
:MT04c			b           "  Alle Module linken",NULL
:MT04d			b           "  Dateilänge anpassen",NULL
:MT04f			b           "Parameter speichern",NULL

;*** Daten für Menü.
:DM_SlctDrive		b $15
			b $15 +4*14 +1
			w $003b
			w $00ba

			b $04 ! VERTICAL ! UN_CONSTRAINED

			w DriveTextA
			b MENU_ACTION
			w DefDriveA

			w DriveTextB
			b MENU_ACTION
			w DefDriveB

			w DriveTextC
			b MENU_ACTION
			w DefDriveC

			w DriveTextD
			b MENU_ACTION
			w DefDriveD

:DriveTextA		b PLAINTEXT,"Laufwerk A:",NULL
:DriveTextB		b PLAINTEXT,"Laufwerk B:",NULL
:DriveTextC		b PLAINTEXT,"Laufwerk C:",NULL
:DriveTextD		b PLAINTEXT,"Laufwerk D:",NULL

:DrvMenuYPos		b $15,$31

;*** GEOS-Verlassen-Menü.
:DM_Verlassen		b $0e
			b $0e +5*14 +1
			w $006e
			w $00e0

			b $05 ! VERTICAL ! UN_CONSTRAINED

			w MT05a
			b MENU_ACTION
			w RUN_MegaAss

			w MT05b
			b SUB_MENU
			w DM_GeoWrite

			w MT05c
			b MENU_ACTION
			w RUN_VLIR_File

			w MT05e
			b MENU_ACTION
			w ExitDT

			w MT05f
			b MENU_ACTION
			w ExitBASIC

:MT05a			b BOLDON,">> ",PLAINTEXT,"MegaAssembler",NULL
:MT05b			b BOLDON,">> ",PLAINTEXT,"GeoWrite aufrufen",NULL
:MT05c			b BOLDON,">> ",PLAINTEXT
:MT05d			b        "(Kein Programm!)",NULL
:MT05e			b BOLDON,">> ",PLAINTEXT,"DeskTop",NULL
:MT05f			b BOLDON,">> ",PLAINTEXT,"BASIC aufrufen",NULL

;*** GEOS-Menü Verlassen/geoWrite.
:DM_GeoWrite		b $20
			b $20 +2*14 +1
			w $00c2
			w $010e

			b $02 ! VERTICAL ! UN_CONSTRAINED

			w MT06a
			b MENU_ACTION
			w OpenLinkText

			w MT06b
			b MENU_ACTION
			w OpenGeoWrite

:MT06a			b BOLDON,">> ",PLAINTEXT,"Linktext öffnen",NULL
:MT06b			b BOLDON,">> ",PLAINTEXT,"Ohne Text starten",NULL

;*** Dialogbox-Icons.
:Icon_DelFile
<MISSING_IMAGE_DATA>

:Icon_03x		= .x
:Icon_03y		= .y

;*** Original-Icon für QuellCode-Datei.
:Hdr_IconDataOrg	j
<MISSING_IMAGE_DATA>

:Hdr_IconDataEnd

;******************************************************************************
;Variablenspeicher
;******************************************************************************
:StartVLinkVarArea

:DrvSlctMode		b $00				;Menü für Laufwerkswahl.

;*** Speicher für Name der Linktext-Datei.
:LinkTextName		s 18

;*** Speicher für VLink-Kommandozeile.
:VLinkCommand		s 256

;*** Speicher für gepackte GeoWrite-Textzeile.
:PackedTextLine		s 256

;*** Systemvariablen.
:VecToCurLine		b $00
:VecToPackedData	b $00
:LenOfTextLine		b $00
:ModDefOpenFlag		b $00
:CurSekAdr_Tr		b $00
:CurSekAdr_Se		b $00
:ByteInCurSek		b $00
:LinkTextOnDisk		b $00
:LinkTextNotOK		b $00
:curRecordCopy		b $00
:OldVLIR_Entry		w $0000
:OldVLIR_Data		w $0000
:VLIR_FileLen		w $0000
:VecToCurFile		w $0000
:FileIconBuf		s 64
:CurFileNum		b $00
:FileScrnXpos		w $0000
:FileScrnYpos		b $00
:ModulCount		b $00
:VecToFNameBuf		w $0000
:CountEmptyMod		b $00
:IgnoreCounter		b $00
:CopyCounter		b $00
:AddByteFlag		b $00
:CopyCodeBytes		b $00
:StringOpenFlag		b $00
:EndOfTextFile		b $00

;*** Infotext definieren.
:HeaderDef		b $00

;*** VLIR-Header.
:VLIR_Header		s 256

;*** Speicher für Modulnamen.
:ModulFileNames		s 2176

;******************************************************************************
:EndVLinkVarArea
;******************************************************************************
