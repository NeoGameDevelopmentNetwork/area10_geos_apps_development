; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;MegaAssembler
;Initialisierung und Systemvariablen.
if .p
			t "TopSym"
			t "TopMac"

.MAX_LABEL_AREA		= $8000				;Für SymbTabFull bei Src#4 auf $6000 setzen.
.graphMode		= $003f

.SetNewMode		= $c2dd
.MaxOpenMakros		= $05

;MegaAss Version	: 5.1
;Zusätzlich ist die Klasse in der
;Linker-Datei 'lnk.MegaAss' anzupassen.
.VMajor			= "5"
.VMinor			= "1"
;MegaAss Build		: 221226
.VBuild1		= "2"				;Jahr
.VBuild2		= "3"
.VBuild3		= "0"				;Monat
.VBuild4		= "5"
.VBuild5		= "2"				;Tag
.VBuild6		= "1"
endif

			n "mod.#0"
			o $0400
			p BootInit
			f APPLICATION
			z $40
			i
<MISSING_IMAGE_DATA>

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

;*** MegaAssembler-Informationen.
.NameMegaAss		s 17				;Name MegaAssembler.
.ClassMegaAss		b "MegaAss     "		;Klasse MegaAssembler.
			b "V"
			b VMajor
			b "."
			b VMinor
			b NULL
.Flag_FirstBoot		b $ff

;*** Aktueller Bildschirm-Modus (C128).
.ScreenMode		b $00

;*** Gemeinsam genutzter Speicherbereich.
.Vec_EndLabels1		w $0000
.Vec_StartLabels1	w $0000
.Vec_StartLabelTab	w $0000
.Vec_StartLabels2	w $0000				;Frei: Startadresse Labelspeicher.
.Vec_EndLabels2		w $0000				;Frei: Endadresse Labelspeicher.
.Vec_EndLabelTab	w MAX_LABEL_AREA
.Vec_AutoAssText	w $0000

;*** Dateinamenspeicher.
.SelectedFile		s 17				;SourceCode-Datei.
.ErrFileName		s 17				;Name Fehlerdatei.
.SymFileName		s 17				;Name Symboltabelle.
.ObjectFileName		s 17				;Name QuellCode-Datei.
.ExtFileName		s 17				;Name ext. Symboltabelle.
.NameOfDataFile		s 17				;Name Include-Datendatei.
.NameOfTextFile		s 17				;Name der Include-Textdatei.
.NameOfAutoExec		s 17
.NameBuffer		s 17

;*** Parametertabelle.
.Opt_BootDrive		b $08				;MegaAss-Systemlaufwerk.
.Opt_SourceDrive	b $08				;Laufwerk für SourceCode-Datei.
.Opt_SourceDriveOrig	b $08				;Laufwerk für SourceCode-Datei.
.Opt_TargetDrive	b $08				;Laufwerk für QuellCode-Datei.
.Opt_ErrFileDrive	b $08				;Laufwerk für Fehlerdatei.
.Opt_SymbTabDrive	b $08				;Laufwerk für Symboltabellen.
.Opt_AutoTxtDrive	b $08				;Laufwerk für AutoAss-Infotext.
.Opt_SymbTab		b $00				;Symboltabelle erzeugen.
.Opt_ExtSymbTab		b $00				;Ext. Symboltabelle erzeugen.
.Opt_OverWrite		b $00				;Sicherheitsabfrage "File Exist!".
.Opt_POpcodeTest	b $00				;PseudoOpcodes testen.
.Opt_MouseCancel	b $00				;0 = Abbruch durch Tastendruck.
.Opt_AutoMode		b $00				;Modus für AutoAssembler.
.Opt_IgnoreFileMode	b $00				;Modus für Linker.
.Opt_FileLenMode	b $80				;Modus Dateilängen-Korrektur.

;*** Fehlertabelle.
.ErrTypeCode		b $00				;Akt. Fehlercode.
.ErrPageCode		b $00
.ErrCount		b $00				;Anzahl Fehler in Tabelle.
.ErrOverflow		b $00				;$FF = Überlauf.
.EndOfErrCodeTab	b $00				;Zeiger auf letztes Byte in Tabelle.

;*** Informationen QuellCode-Datei.
.AssCodeArea		b " $0400-$5fff ",NULL
.ProgLoadAdr		w $0400				;Programm-Ladeadresse.
.ProgEndAdr		w $0400				;Programm-Endadresse.
.ProgStartAdr		w $0400				;Programm-Startadresse.
.ProgUserEndAdr		w $0000				;Benutzerdefinierte Endadresse.
.ProgMaxEndAdr		w $0000				;Max. erlaubte Endadresse.
.ProgErrAdr		w $0000
.LastTestAdr		w $0000				;Zuletzt getestete Bereichsgrenze.

;*** Assemblierungs-Informationen.
.Flag_StopAssemble	b $00				;$01 = assemblieren abbrechen.
.Flag_AssembleError	b $00				;$01 = Fehler aufgetreten.
.Flag_FatalError	b $00				;$01 = Fataler assemblierungsfehler.
.Flag_FileCreated	b $00				;$01 = Quellcode-Datei wurde erzeugt.
.Flag_SymbFileOK	b $00				;$ff = Symboldatei erzeugen.
.Flag_ExtSFileOK	b $00				;$ff = Ext. Symboldatei erzeugen.
.Flag_ErrFileOK		b $00				;$ff = Fehlerdatei wurde erzeugt.
.Flag_ExtLabelFound	b $00				;$01 = ext. Labels gefunden.
.Flag_AutoAssInWork	b $00				;$ff = AutoAssembler aktiv.

;*** Daten für Zahlenkonvertierung.
.DataTab_DEZ_HEX	b "01234567"
			b "89abcdef",NULL
.BufferHEX 		s $05				;Zwischenspeicher "HEX => ASCII".
.WordBuffer		w $0000

;*** Zwischenspeicher für div. Daten.
.RecVecBuf		w $0000

;*** Zeiger für Textmenü.
.Poi_1stEntryInTab	b $00
.MaxTextFiles		b $00

;*** Zähler für Assembler-Befehle.
.CodeCounter		s $04
.ByteCounter		s $04
.IconCounter		s $04

;*** Start-Assemblierungszeit (hhmmss).
.Flag_SaveTime		b $ff
.StartAssTime		b $00,$00,$00

;*** Zeiger auf Stack.
.StackVector		b $00

;*** Infoblock für QuellCode-Datei.
.Header			b $00,$ff
			b $03,$15
.Hdr_IconData		j
<MISSING_IMAGE_DATA>

.Hdr_CBM_Type		b $80 ! PRG
.Hdr_GEOS_Type		b APPLICATION
.Hdr_FileStruct		b SEQUENTIAL
.Hdr_LoadAdr		w $0400
.Hdr_EndAdr		w $0400
.Hdr_StartAdr		w $0400
.Hdr_Class		s 18
:Hdr_ClassEnd
.Hdr_ClassLen		= Hdr_ClassEnd - Hdr_Class
			b NULL
.Hdr_ScrnMode		b $00
.Hdr_Author		s 19
.Hdr_AuthorPos		= Hdr_Author - Header
:Hdr_AuthorEnd
.Hdr_AuthorLen		= Hdr_AuthorEnd - Hdr_Author
			b NULL
.Hdr_ApplClass		s 18
.Hdr_ApplClassPos	= Hdr_ApplClass - Header
:Hdr_ApplClassEnd
.Hdr_ApplClassLen	= Hdr_ApplClassEnd - Hdr_ApplClass
			b NULL
.Hdr_ApplData		s 24
.Hdr_Info		s 96
.Hdr_InfoPos		= Hdr_Info - Header
:Hdr_InfoEnd
.Hdr_InfoLen		= Hdr_InfoEnd - Hdr_Info -1
.Hdr_EndData

;*** Hauptmenü aktivieren.
.Mod_Menu		lda	#$01			;Menü laden.
			b $2c

.Mod_Assembler		lda	#$04			;Assembler laden.
			b $2c

.Mod_DoSysFile		lda	#$05			;Fehler/Symboltabellen erzeugen.
			b $2c

.Mod_VLink		lda	#$06			;Linker starten.
			pha
			jsr	FindMegaAss		;MegaAssembler suchen.
			txa
			beq	:3
::1			pla
::2			jmp	SystemError		;Nicht gefunden, Fehler.

::3			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock
			txa
			bne	:1

			pla
			asl
			tax
			lda	fileHeader +2,x
			sta	r1L
			lda	fileHeader +3,x
			sta	r1H
			LoadW	r2,$4fff
			LoadW	r7,VLIR_BASE
			jsr	ReadFile		;Programmteil einlesen.
			txa
			bne	:2
			sta	r0L
			lda	#<VLIR_BASE
			sta	r7L
			lda	#>VLIR_BASE
			sta	r7H
			jmp	StartAppl		;Modul starten.

;*** MegaAssembler auf Diskette suchen.
.FindMegaAss		lda	Opt_BootDrive		;Start-Laufwerk aktivieren.
			jsr	NewSetDevice
			jsr	NewOpenDisk
			txa
			bne	:2

			LoadW	r6 ,NameMegaAss
			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,ClassMegaAss
			jsr	FindFTypes		;MegaAssembler suchen.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch.
			lda	r7H			;Datei gefunden ?
			bne	:1			;Nein, Fehler.
			LoadW	r6,NameMegaAss
			jmp	FindFile		;Verzeichnis-Eintrag einlesen.
::1			ldx	#$05			;"MegaAss nicht gefunden".
::2			rts

;*** Kein MegaAss gefunden.
.SystemError		LoadW	r0,DlgMA_Disk		;Fehler: "MegaAss nicht auf
			jsr	DoDlgBox		;         Diskette!".

;*** Zum DeskTop verlassen.
.ExitDT			lda	#$08			;Laufwerk #8 aktivieren.
			jsr	SetDevice
			jmp	EnterDeskTop		;Zum DeskTop zurück.

;*** ":RecoverVector" zwischenspeichern.
.SaveRecVec		lda	RecoverVector +0
			sta	RecVecBuf     +0
			lda	RecoverVector +1
			sta	RecVecBuf     +1
			rts

;*** ":RecoverVector" zwischenspeichern.
.LoadRecVec		lda	RecVecBuf     +0
			sta	RecoverVector +0
			lda	RecVecBuf     +1
			sta	RecoverVector +1
			rts

;*** ":RecoverVector" löschen.
.ClrRecVec		lda	#$00
			sta	RecoverVector +0
			sta	RecoverVector +1
			rts

;*** Bildschirm löschen.
.ClrScreen		lda	#$02
			jsr	SetPattern

			lda	#< $013f
			ldx	#> $013f
			bit	ScreenMode
			bpl	:1
			lda	#< $027f
			ldx	#> $027f
::1			sta	:2 +0
			stx	:2 +1

			jsr	i_Rectangle
			b	$00
			b	$c7
			w	$0000
::2			w	$013f

			lda	screencolors
			sta	:3
			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::3			b	$ff

			rts

;*** Neue "NewSetDevice"-Routine.
.NewSetDevice		cmp	curDrive
			beq	:1
			jmp	SetDevice
::1			ldx	#$00
			rts

;*** Neue NewOpenDisk-Routine.
.NewOpenDisk		jsr	GetDirHead
			txa
			bne	:2

			ldx	#r1L
			jsr	GetPtrCurDkNm

			ldy	#$0f
::1			lda	curDirHead +$90,y
			sta	(r1L),y
			dey
			bpl	:1

			ldx	#$00
::2			rts

;*** Dialogbox: "MegaAssembler fehlt!"
:DlgMA_Disk		b $81
			b DBTXTSTR    ,$10,$1c
			w :1
			b DBTXTSTR    ,$10,$27
			w :2
			b OK          ,$02,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "MegaAssembler nicht",NULL
::2			b "auf Diskette!",NULL

;*** Startadresse VLIR-Module.
.VLIR_BASE

;*** Module laden & starten.
:BootInit		lda	curDrive		;Laufwerke vorbelegen.
			sta	Opt_BootDrive
			sta	Opt_SourceDrive
			sta	Opt_SourceDriveOrig
			sta	Opt_TargetDrive
			sta	Opt_SymbTabDrive
			sta	Opt_ErrFileDrive

;*** Bildschirmmodus ermitteln.
:Init_40_80		lda	#$00
			bit	c128Flag
			bpl	:1
			lda	graphMode
			beq	:1
			lda	#$80
::1			sta	ScreenMode

;*** Startadresse Labelspeicher aus VLIR-Modul einlesen.
:GetAdrLabels		jsr	FindMegaAss		;MegaAss suchen.
			txa				;Gefunden ?
			beq	:2			;Ja, weiter...
::1			jmp	SystemError		;Systemfehler!

::2			LoadW	r0,NameMegaAss
			jsr	OpenRecordFile		;MegaAss-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:1			;Ja, Abbruch.

			lda	fileHeader +10
			ldx	fileHeader +11
			sta	r1L
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten Sektor einlesen.

			lda	diskBlkBuf     +5	;Startadresse Labelspeicher
			sta	Vec_EndLabels1 +0	;einlesen.
			lda	diskBlkBuf     +6
			sta	Vec_EndLabels1 +1

			jsr	CloseRecordFile		;VLIR-Datei schliesen.
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	Mod_Menu		;Menü laden.
