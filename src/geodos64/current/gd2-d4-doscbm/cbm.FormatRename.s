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

:sysGet1stDirEntry	= $c9f7				;Ersten Verzeichniseintrag lesen
:sysFreeBlock		= $9844				;Ersten Verzeichniseintrag lesen
:OpenRootDir		= $9050

:dir3Head		= $9c80				;3.BAM-Sektor für 1581.

:DRIVE_MASK		= %00001111
:INV_TRACK		= $02

:Drv1541		= $01
:Drv1571		= $02
:Drv1581		= $03
:DrvNative		= $04
endif

			n	"mod.#401.obj",NULL
			f	SYSTEM
			c	"GD_CBM      V2.2",NULL
			a	"M. Kanet",NULL
			i
<MISSING_IMAGE_DATA>

			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM

			jmp	CBM_Format
			jmp	CBM_Rename
			jmp	CBM_FrmtCurDk

			t	"-CBM_GetDskNam"
			t	"-CBM_SetName"
			t	"-CBM_GetSizeNM"

;*** L401: Diskette formatieren.
:CBM_Format		ClrB	DiskFrmtMode
			ClrW	ReturnAddress
			jsr	FrmtDrvMode
			jmp	InitScreen

:CBM_FrmtCurDk		LoadB	DiskFrmtMode,$ff
			PopW	ReturnAddress
			jsr	FrmtDrvMode
			PushW	ReturnAddress
			rts

;*** Zurück zu GeoDOS.
:L401ExitGD		ldx	StackPointer
			txs
			rts

;*** Formatmodus wählen.
:FrmtDrvMode		tsx
			stx	StackPointer

;*** Formatauswahlbox definieren.
:GetDrvType		lda	curDrive
			jsr	NewDrive

;--- Ergänzung: 22.11.18/M.Kanet
;Bei SD2IEC spezielle Format-Optionen anzeigen.
;Gilt für 1541/71/81 und SD2IEC-Native.
			ldx	curDrive
;--- Ergänzung: 27.11.18/M.Kanet
;Prüfen ob Formatieren auf dem Systemlaufwerk möglich ist.
			lda	FrmtSysDrive,x		;Kann Systemlaufwerk formatiert werden?
			bne	:100			; => Ja, weiter...
			cpx	AppDrv			;Systemlaufwerk?
			bne	:100			; => Nein, weiter...

			DB_OK	V401i3			;Fehler: Das Systemlaufwerk
			jmp	L401ExitGD		;kann nicht formatiert werden!

;--- Ergönzung: 03.03.19/M.Kanet
;Bei NativeMode das Hauptverzeichnis
;öffnen oder es wird nur das aktuelle
;Unterverzeichnis formatiert.
::100			jsr	Test4Native		;Auf NativeMode ":ROOT" öffnen.

			ldx	curDrive
			lda	DriveModes-8,x
			and	#%00000001		;SD2IEC-Laufwerk?
			beq	:101			; => Nein, weiter...

			lda	driveType -8,x
			and	#%00000111
			tay
			lda	VecSD2ITabH,y
			pha
			lda	VecSD2ITabL,y
			pha
			rts

::101			ldy	DriveTypes-8,x
			lda	VecSlctTabH,y
			pha
			lda	VecSlctTabL,y
			pha
			rts

;*** Bei NativeMode ROOT öffnen.
:Test4Native		ldx	curDrive
			lda	driveType-8,x
			and	#%00000111
			cmp	#DrvNative
			bne	:end
			jsr	OpenRootDir
::end			rts

;*** Formatieren starten...
;--- Ergänzung: 22.11.18/M.Kanet
;Bei DNP erstellen keine Info-Box anzeigen da zuerst die
;Größe gewählt wird.
:SlctFormat		sta	FrmtModeType
			cmp	#22			;DNP erstellen?
			beq	:101			; => Ja, Info-Box überspringen.
			pha				;Info-Box definieren.
			jsr	SetIBoxData
			jsr	DefInfoBox
			pla
::101			tay				;Format-Art auswählen.
			lda	VecFrmtModeH,y
			pha
			lda	VecFrmtModeL,y
			pha
			rts

:SetIBoxData		asl
			asl
			clc
			adc	#<TabFrmtInfo
			sta	r15L
			lda	#$00
			adc	#>TabFrmtInfo
			sta	r15H
			rts

;--- Ergänzung: 10.12.18/M.Kanet
;Bisher wurde standardmäßig die Diskette als "GEOS-Disk" mit
;zusätzlichem Borderblock erstellt. Da dieser aktuell weder von GeoDOS
;oder TopDesk genutzt wird ist das vorerst nutzlos.
:FrmtGEOSDisk		ldx	#$00
			rts
if FALSE
			jsr	SetGEOSDisk		;GEOS-Diskette erstellen.
			txa				;Diskettenfehler?
			beq	:101			; => Nein, OK.
			jmp	DiskError		;Fehler anzeigen.
::101			rts
endif

;*** Verzeichnis-Auswahl SD2IEC initialisieren.
:InitSDirSlct		jsr	CheckDiskCBM		;Neue Diskette öffnen.
			txa				;Diskette im Laufwerk ?
			bne	NewSlctDImg		;Nein, weiter...

			ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			cmp	#%00000100		;NativeMode ?
			bne	:101			; => Nein, weiter...

			C_Send	V401b1			;Auf DNP zurück zum Hauptverzeichnis.
			jsr	New_CMD_Root

::101			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler?
			bne	NewSlctDImg		; => Ja, weiter...
			jsr	PutDirHead		;BAM aktualisieren (Cache im Treiber).

::102			C_Send	V401b0			;Aktives DiskImage verlassen.

;*** Neues DiskImage wählen
:NewSlctDImg		jsr	SD_Image		;Verzeichnis einlesen.
			txa				;Fehler ?
			bne	ExitDiskError		; => Ja, Abbruch...

			jsr	i_MoveData		;Speicher für Verzeichniswechsel
			w	FileNTab + 0		;reservieren.
			w	FileNTab +48
			w	252 * 16

			ldy	#$0f			;"<=" und ".." - Einträge erzeugen.
::101			lda	V401c4  + 0,y
			sta	FileNTab+ 0,y
			lda	V401c4  +16,y
			sta	FileNTab+16,y
			lda	V401c4  +32,y
			sta	FileNTab+32,y
			dey
			bpl	:101

			lda	V401k3			;Anzahl "ActionFiles" korrigieren.
			clc
			adc	#$03
			sta	V401k3

			lda	#<V401k2		;DiskImage auswählen.
			ldx	#>V401k2
			jsr	SelectBox

;*** Auswahl auswerten.
:CheckSelect		lda	r13L			;Rückmeldung Dialogbox auswerten.
			beq	ChangeSDImg		; => Eintrag gewählt, weiter...

::101			cmp	#$02
			bcs	EndSDImgExit		;ein DiskImage aktiv ist.

;*** Verzeichnis-Auswahl verlassen.
:EndSDImgOK		ldy	#$00
			b $2c
:EndSDImgExit		ldy	#$ff
			rts

;*** Diskettenfehler.
:ExitDiskError		jmp	DiskError		;Diskettenfehler ausgeben.

;*** Verzeichnis öffnen.
:ChangeSDImg		lda	r13H
			cmp	#$00
			bne	:101
			C_Send	V401b1			;SD2IEC-Root aktivieren.
			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

::101			cmp	#$01
			bne	:102
			C_Send	V401b0			;Ein SD2IEC-Verzeichnis zurück.
			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

::102			cmp	#$02
			bne	:102a
			jmp	CreateNewDir		;Neues Verzeichnis erstellen.

::102a			pha				;Gewählten Eintrag merken.

			ldy	#$00
::103			lda	(r15L),y		;Verzeichnisname in "CD"-Befehl
			beq	:104			;übertragen...
			sta	V401b2a,y
			iny
			cpy	#16
			bne	:103
			lda	#$00
::104			sta	V401b2a,y
			tya
			clc
			adc	#$03
			sta	V401b2

			C_Send	V401b2			;Verzeichnis wechseln.

			pla
			cmp	V401k3			;Verzeichnis gewählt?
			bcc	:105			; => Verzeichnis.
			jmp	EndSDImgOK
::105			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

;*** Kompatible DiskImages einlesen.
:SD_Image		lda	#$00			;Speicher für zuletzt gefundenen
			sta	V401b2 +5		;DiskImage Namen löschen.
if FALSE
			ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			sec
			sbc	#$01
			asl
			tay
			lda	V401a1 +0,y		;Kennung D64/D71/D81/DNP in
			sta	V401b6 +5		;Verzeichnis-Befehl eintragen.
			lda	V401a1 +1,y
			sta	V401b6 +6
endif
			lda	#$00			;Anzahl "ActionFiles" löschen.
			sta	V401k3

			jsr	DoInfoBox		;Meldung "DiskImages einlesen..."
			PrintStrgV401j3

;--- DiskImages einlesen.
			lda	#<V401b6		;Verzeichnis mit gültigen DiskImages
			ldx	#>V401b6		;einlesen.
			ldy	#$09
			jsr	InitDir
			cpx	#$00			;Fehler ?
			bne	:100			; => Ja, weiter...

			sta	EntryCnt_File		;Anzahl gefundener DiskImages merken.
			cmp	#$00			;Mind. ein Eintrag gefunden?
			beq	:101

			ldy	#$00			;Erstes gefundenes DiskImage
::99			lda	FileNTab +32,y		;merken. Wird dazu verwendet bei
			beq	:100			;Abbruch der Auswahlbox ein
			sta	V401b2 +5,y		;gültiges DiskImage wieder zu
			iny				;aktivieren.
			cpy	#$10
			bcc	:99
			lda	#$00
::100			sta	V401b2 +5,y
			iny
			iny
			iny
			sty	V401b2

			jsr	i_MoveData		;Liste mit DiskImages speichern.
			w	FileNTab		;Mit "<=" und ".." sind max.
			w	TempDataBuf		;253 weitere Einträge möglich.
			w	16 * 253

;--- Verzeichnisse einlesen.
::101			lda	#<V401b7		;Verzeichnisse einlesen.
			ldx	#>V401b7
			ldy	#$05
			jsr	InitDir
			sta	EntryCnt_SDir		;Anzahl Verzeichnisse merken.
			cpx	#$00
			bne	:106

			sta	V401k3			;Anzahl Verzeichnisse merken.

			ldy	EntryCnt_File		;DiskImages gefunden?
			beq	:105			; => Nein, weiter...

			ldx	#<TempDataBuf		;Zeiger auf Zwischenspeicher
			stx	r14L			;mit DiskImages.
			ldx	#>TempDataBuf
			stx	r14H

			tax
::102			cpx	#255 -2			;Dateispeicher voll?
			bcs	:104			; => Ja, weiter...

			ldy	#$0f			;DiskImage in Auswahlliste kopieren.
::103			lda	(r14L),y
			sta	(r15L),y
			dey
			bpl	:103
			AddVBW	16,r14			;Zeiger auf nächsten Eintrag.
			jsr	Add_16_r15
			inx
			dec	EntryCnt_File		;Alle DiskImages übernommen?
			bne	:102			; => Nein, weiter...

::104			txa
::105			ldx	#$00
::106			rts

;*** Verzeichnis-Name eingeben.
:CreateNewDir		jsr	InfUpperCase		;Hinweis: Großbuchstaben.

			lda	#$00			;Eingabespeicher löschen.
			sta	V401b3a

			LoadW	r1,V401b3a
			LoadB	r2L,$00
			LoadB	r2H,$00
			LoadW	r3,V401c2
			jsr	cbmSetName		;Verzeichnisname eingeben.
			cmp	#$01			;"OK" ?
			bne	:101			; => Nein, Abbruch...

::201			ldy	#$00
::202			lda	V401b3a,y		;Name in überprüfen und in
			beq	:204			;"CD"-Befehl kopieren.
			cmp	#$61
			bcc	:203
			cmp	#$7f
			bcs	:203
			sec
			sbc	#$20
::203			sta	V401b2a,y
			sta	V401b3a,y
			iny
			cpy	#16
			bcc	:202
			lda	#$00
::204			sta	V401b2a,y
			sta	V401b3a,y
			tya
			beq	:101

			clc				;Länge Verzeichnisbefehl berechnen.
			adc	#$03
			sta	V401b2
			sta	V401b3

			C_Send	V401b3			;Verzeichnis erstellen.
			C_Send	V401b2			;In neues Verzeichnis wechseln.

::101			jsr	ClrScreen		;Bildschirmfarben zurücksetzen.
			jmp	NewSlctDImg		;Verzeichnis anzeigen.

;*** Hinweisfenster oben ausgeben.
:InfoTop		jsr	i_C_DBoxTitel
			b	$00,$00,$28,$01
			jsr	i_C_DBoxBack
			b	$00,$01,$28,$03

			FillPRec0,$00,$1f,$0000,$013f
			FrameRec$08,$1f,$0000,$013f,%11111111

			jmp	UseGDFont

;*** Hinweisfenster unten ausgeben.
:InfoBottom		jsr	i_C_DBoxTitel
			b	$00,$15,$28,$01
			jsr	i_C_DBoxBack
			b	$00,$16,$28,$03

			FillPRec0,$a8,$c7,$0000,$013f
			FrameRec$b0,$c7,$0000,$013f,%11111111

			jmp	UseGDFont

;*** Hinweis: Laufwerks-ROM laden.
:InfLdDrvROM		jsr	InfoBottom
			Print	$0006,$ae
			b	PLAINTEXT
if Sprache = Deutsch
			b	"HINWEIS:"
endif
if Sprache = Englisch
			b	"NOTE:"
endif
			b	NULL
			jsr	UseSystemFont
			Print	$0006,$b9
if Sprache = Deutsch
			b	BOLDON
			b	"Um das Laufwerks-ROM laden zu können wird die Datei"
			b	GOTOXY
			w	$0006
			b	$c3
			b	"`DOS15xx.BIN` im Hauptverzeichniss des SD2IEC benötigt!"
			b	NULL
endif
if Sprache = Englisch
			b	BOLDON
			b	"The file `DOS15xx.BIN` must be available in the ROOT-"
			b	GOTOXY
			w	$0006
			b	$c3
			b	"directory of your SD2IEC device!"
			b	NULL
endif
			rts

;*** Hinweis: GEOS-Laufwerkstreiber laden.
:InfLdGEOSDrv		jsr	InfoBottom
			Print	$0006,$ae
			b	PLAINTEXT
if Sprache = Deutsch
			b	"HINWEIS:"
endif
if Sprache = Englisch
			b	"NOTE:"
endif
			b	NULL
			jsr	UseSystemFont
			Print	$0006,$b9
if Sprache = Deutsch
			b	BOLDON
			b	"Um das neue DiskImage nutzen zu können muss der"
			b	GOTOXY
			w	$0006
			b	$c3
			b	"passende GEOS-Laufwerkstreiber geladen werden !"
			b	NULL
endif
if Sprache = Englisch
			b	BOLDON
			b	"To mount the new disk-image the matching"
			b	GOTOXY
			w	$0006
			b	$c3
			b	"GEOS disk-driver must be loaded manually !"
			b	NULL
endif

			rts

;*** Hinweis: Name wird nach Großbuchstaben konvertiert.
:InfUpperCase		jsr	InfoTop
			Print	$0006,$06
			b	PLAINTEXT
if Sprache = Deutsch
			b	"HINWEIS:"
endif
if Sprache = Englisch
			b	"NOTE:"
endif
			b	NULL
			jsr	UseSystemFont
			Print	$0006,$11
if Sprache = Deutsch
			b	BOLDON
			b	"Neue SD2IEC-Verzeichnisse und DiskImages werden zur"
			b	GOTOXY
			w	$0006
			b	$1b
			b	"besseren Kompatibilität in Großbuchstaben erstellt !"
			b	NULL
endif
if Sprache = Englisch
			b	BOLDON
			b	"For better compatibility new SD2IEC directories and"
			b	GOTOXY
			w	$0006
			b	$1b
			b	"disk-images will be created with upper-case names !"
			b	NULL
endif

			rts

;*** Format-Auswahl.
:Slct1541		ldx	#$00			;Auswahlbox mit 1541-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	Types1541,x
			jmp	SlctCBMDisk

:Slct1571		ldx	#$04			;Auswahlbox mit 1571-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	Types1571,x
			jmp	SlctCBMDisk

:Slct1581		ldx	#$08			;Auswahlbox mit 1581-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	Types1581,x
:SlctCBMDisk		ldx	#$01
			stx	FrmtNxDsk
			jsr	DoInsertDisk
			jmp	SlctFormat

:SlctRAM41						;RAM41 löschen.
:SlctRAM71						;RAM71 löschen.
:SlctRAM81						;RAM81 löschen.
:SlctRAMNM		jsr	AskToClrRAM		;RAMNM löschen.
			lda	#$02
			jmp	SlctFormat

:SlctRAMGW		jsr	AskToClrRAM		;GateWay RAMDisk.
			lda	#$03
			jmp	SlctFormat

:SlctRL							;RL-Partition löschen.
:SlctRD							;RD-Partition löschen.
:SlctHD			lda	#$00			;HD-Partition löschen.
			b $2c
:SlctPart		lda	#$01			;FD-Partition löschen.
			sta	FrmtNxDsk		;Partition löschen.
			jsr	AskToClrPart
			lda	#$01
			jmp	SlctFormat

:SlctFD2		ldx	#$0c			;Auswahlbox mit FD2-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	Types_FD2,x
			jmp	SlctFD

:SlctFD4		ldx	#$10			;Auswahlbox mit FD4-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	Types_FD4,x
:SlctFD			cmp	#$01
			beq	SlctPart
			jsr	DoInsertDisk
			jmp	SlctFormat

:Slct64Net		lda	#$00			;64Net-Partition löschen.
			sta	FrmtNxDsk		;Partition löschen.
			LoadW	V401g0,FrmtMode_52
			jsr	AskToClr

			ldx	curDrive
			lda	driveType-8,x
			and	#%00000011
			clc
			adc	#15 -1			;Mode #15-17.
			jmp	SlctFormat

;*** GEOS-MegaPatch IECBus-NativeMode-Treiber.
:SlctIECNM		jsr	AskToClrIECNM		;IECBusNM/SD2IEC.
			lda	#$12
			jmp	SlctFormat

;*** GEOS-MegaPatch 1541/71/81/SD2IEC-NM-Treiber.
:SlctSD41		ldx	#$14			;Auswahlbox mit SD41-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	TypesSD41,x
			jmp	SlctDImgDisk

:SlctSD71		ldx	#$18			;Auswahlbox mit SD71-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	TypesSD71,x
			jmp	SlctDImgDisk

:SlctSD81		ldx	#$1c			;Auswahlbox mit SD81-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	TypesSD81,x
			jmp	SlctDImgDisk

:SlctSDNM		ldx	#$20			;Auswahlbox mit SDNM-Format-Optionen.
			jsr	DoFrmtTypeBox
			lda	TypesSDNM,x

:SlctDImgDisk		ldx	#$01			;Weitere Diskette formatieren?
			stx	FrmtNxDsk
			tay
			ldx	SDSlctSDir,y		;Verzeichnis wählen?
			beq	:102			; => Nein, weiter...
			pha
			jsr	InitSDirSlct		;Verzeichnis für neues Image wählen.
			pla
			cpy	#$00			;"OK" ?
			bne	:101			; => Nein, Ende.
::102			jmp	SlctFormat
::101			jmp	L401ExitGD		;Zurück zu GeoDOS.

;*** Diskette löschen.
:ClrDir			jsr	CBM_GetDskNam		;Partition löschen.
			jsr	SetFrmtName_b

			lda	#$00
			jsr	SetCBMFrmtOpt

			ldx	curDrive		;Verzeichnis löschen.
			lda	DriveTypes-8,x
			cmp	#Drv_1571		;1571-Laufwerk ?
			bne	:101			;Nein, weiter...
			jsr	Set1571Mode		;Auf 1571-Modus umschalten.
::101			jmp	InitClrPart

;*** Partition löschen.
:ClrPart		jsr	CBM_GetDskNam		;Partition löschen.
			jsr	SetFrmtName_b

			lda	#$00
			ldx	curDrive
			ldy	DriveTypes-8,x
			cpy	#Drv_CMDRL
			beq	:101
;--- Ergänzung: 22.11.18/M.Kanet
;RAMDrive ist ähnlich CMD RAMLink, Kennung angepasst.
			cpy	#Drv_CMDRD
			bne	:102
::101			lda	#$01
::102			jsr	SetCBMFrmtOpt

:InitClrPart		jsr	RealDiskFrmt		;Echte Diskette formatieren.
			jsr	NewDiskName
			lda	FrmtNxDsk		;Weitere Disketten formatieren ?
			beq	:103			;Nicht bei RL,RD und HD.
			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?
::103			jmp	L401ExitGD		;Zurück zu GeoDOS.

;*** Partitionen löschen.
:Clr64Net						;64Net-Partition löschen (RAM-Disk!).
:ClrRam			jmp	ClrRamDisk		;Inhalt der RAM-Disk löschen.
:ClrGW_RAM		jmp	ClrGW_RDisk

;*** Standard 1541-Format.
:Std1541		jsr	Set1541Mode		;Auf 1541-Modus umschalten.
			jsr	StdFrmt			;1541-Diskette formatieren.

			ldx	curDrive
			ldy	DriveTypes-8,x
			cmp	#Drv_1571		;1571-Laufwerk ?
			bne	:101			;Nein, weiter...
			jsr	Set1571Mode		;Auf 1571-Modus umschalten.
::101			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?

;*** Standard 1571-Format.
:Std1571		jsr	Set1571Mode		;Auf 1571-Modus umschalten.
			jsr	StdFrmt			;1571-Diskette formatieren.
			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?

;*** Auf einseitigen Modus schalten.
:Set1541Mode		jsr	PurgeTurbo		;Auf 1541 umschalten.
			jsr	InitForIO
			CxSend	SwitchTo1541
			CxSend	InitNewDisk
			jmp	DoneWithIO

;*** Auf doppelseitigen Modus schalten.
:Set1571Mode		jsr	PurgeTurbo		;Auf 1571 umschalten.
			jsr	InitForIO
			CxSend	SwitchTo1571
			CxSend	InitNewDisk
			jmp	DoneWithIO

;*** Standard 1581/Native-Format.
:Std1581
:StdNative		jsr	StdFrmt			;1581-Diskette formatieren.
			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?

;*** Standard-Format ausführen.
:StdFrmt		jsr	SetFrmtName_a
			lda	#$01
			jsr	SetCBMFrmtOpt
			jsr	RealDiskFrmt		;Echte Diskette formatieren.
			jmp	NewFrmtName

;*** QuickFormat 1541.
:QF1541			jsr	InitFastFrmt
			C_Send	ExecFastFrmt		;QuickFormat starten.
			jsr	TestDiskFrmt		;Format-Ergebnis testen.
			jsr	NewFrmtName
			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?

;*** Physikalische Disketten formatieren.
:RealDiskFrmt		C_Send	ExecFormat

:TestDiskFrmt		jsr	NewOpenDisk
			txa
			beq	:102
::101			jmp	DiskError
::102			jmp	FrmtGEOSDisk

;*** CMD-Format-Optionen.
:CMD_81			lda	#$01			;Standard 1581-Disk erzeugen.
			ldx	#$00
			beq	CMD_Frmt

:CMD_DD			lda	#$01			;CMD-Diskette mit 1x 1581 Partition.
			ldx	#$01
			bne	CMD_Frmt

:CMD_HD			lda	#$02			;CMD-Diskette mit 2x 1581 Partition.
			ldx	#$02
			bne	CMD_Frmt

:CMD_ED			lda	#$04			;CMD-Diskette mit 4x 1581 Partition.
			ldx	#$03
			bne	CMD_Frmt

:CMD_DDNAT		lda	#$01			;CMD Native-Mode-Partition.
			ldx	#$04
			bne	CMD_Frmt

:CMD_HDNAT		lda	#$01			;CMD Native-Mode-Partition.
			ldx	#$05
			bne	CMD_Frmt

:CMD_EDNAT		lda	#$01			;CMD Native-Mode-Partition.
			ldx	#$06

:CMD_Frmt		sta	CurRenamePart		;Anzahl Partitionen merken.

;--- Ergänzung: 27.11.18/M.Kanet
;Prüfen ob Formatieren auf dem Systemlaufwerk möglich ist.
			ldy	curDrive
			cpy	AppDrv
			bne	:100

			DB_OK	V401i3			;Fehler: Das Systemlaufwerk
			jmp	L401ExitGD		;kann nicht formatiert werden!

::100			txa
			pha
			jsr	SetFrmtName_a

			lda	#$01
			jsr	SetCBMFrmtOpt		;Format-Befehl definieren.

			pla
			pha
			jsr	SetCMDFrmtOpt		;CMD-Optionen definieren.
			jsr	RealDiskFrmt		;Echte Diskette formatieren.
			pla				;Diskette im 1581-Format erzeugen ?
			bne	:101			;Nein, weiter...

			lda	#$01
			jsr	SaveNewPart		;Partition #1 aktivieren.
			jsr	NewFrmtName		;Neuen Disketten-Namen eingeben.
			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?

::101			lda	#$01
			sta	MaxRenamePart		;Zeiger auf erste Partition.

::102			lda	MaxRenamePart
			jsr	SetNewPart		;Partition aktivieren.

			jsr	NewFrmtName 		;Disk- & Partitions-Name ändern.

			inc	MaxRenamePart		;Zeiger auf nächste Partition.
			dec	CurRenamePart		;Alle Partitionen bearbeitet ?
			bne	:102			;Nein, weiter...

			lda	#$01
			jsr	SaveNewPart		;Partition #1 aktivieren.
			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?

;*** IECBus-NativeMode löschen.
;--- Ergänzung: 22.11.18/M.Kanet
;Getrennte Routine zu ClrRamDisk da bei IECBus-Native und einer CMDFD die
;Diskette gewechselt und eine weitere Diskette formatiert werden kann.
; -> Diskwechsel erlauben.
:ClrIECNM		jsr	CBM_GetDskNam		;Partition löschen.
			jsr	SetFrmtName_b
			jsr	NewOpenDisk
			jsr	ClrGEOSDisk
			jsr	ClearBAM
			jsr	PutDirHead
			jsr	FrmtGEOSDisk
			jsr	ClrDirectory
			txa
			bne	:101
			jsr	NewDiskName		;Neuer Disketten-Name.
			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?
::101			jmp	DiskError

;*** Ersten Dir-Block löschen.
:ClrRamDisk						;RAM1541,71,81 löschen.
:ClrGW_RDisk		jsr	NewOpenDisk		;GW_RAM löschen.
			jsr	ClrGEOSDisk
			jsr	ClearBAM
			jsr	PutDirHead
			jsr	FrmtGEOSDisk
			jsr	ClrDirectory
			txa
			bne	:101
			jsr	NewDiskName		;Neuer Disketten-Name.
			jmp	L401ExitGD
::101			jmp	DiskError

;*** Verzeichnis löschen.
:ClrDirectory		jsr	NewOpenDisk
			txa
			bne	:104

			lda	curType
			jsr	Get1stDirBlk
			LoadW	r4,diskBlkBuf

::102			jsr	GetBlock
			txa
			bne	:104

			ldy	#$00			;Programmtyp-Bytes löschen.
::103			lda	#$00
			sta	diskBlkBuf +2,y
			tya
			clc
			adc	#$20
			tay
			bne	:103

			lda	diskBlkBuf +0		;Zeiger auf nächsten DIR-Sektor
			pha				;zwischenspeichern.
			lda	diskBlkBuf +1
			pha

			ldx	#$00			;Zeiger auf nächsten DIR-Sektor
			stx	diskBlkBuf +0		;löschen.
			dex
			stx	diskBlkBuf +1

			jsr	PutBlock		;DIR-Sektor speichern.
			txa
			bne	:104

			pla				;Zeiger auf nächsten DIR-Sektor
			sta	r1H			;wiederherstellen.
			pla
			sta	r1L
			bne	:102			;Nächsten DIR-Sektor löschen.

::104			rts

;--- Ergänzung: 22.11.18/M.Kanet
;Code zum erstellen von Dxx-DiskImages ergänzt.
;Zum erstellen der DskImages wird der "P"-Befehl verwendet der ausserhalb
;eines DiskImages auch für Dateien verwendet werden kann um den Zeiger auf
;ein bestimmtes Byte zu setzen.
;*** SD2IEC DiskImage erstellen.
:CreateD64		ldx	#Drv1541
			stx	SD2IEC_DType
			ldx	#$00
			jsr	GetDImgName
			txa
			bne	:101
			lda	#35			;Anzahl Tracks 1541 = 35.
			ldx	#<170			;Größe in KBytes für Info-Anzeige.
			ldy	#>170
			jmp	DoCreateDImg
::101			jmp	L401ExitGD

:CreateD71		ldx	#Drv1571
			stx	SD2IEC_DType
			ldx	#$02
			jsr	GetDImgName
			txa
			bne	:101
			lda	#70			;Anzahl Tracks 1571 = 70.
			ldx	#<340			;Größe in KBytes für Info-Anzeige.
			ldy	#>340
			jmp	DoCreateDImg
::101			jmp	L401ExitGD

:CreateD81		ldx	#Drv1581
			stx	SD2IEC_DType
			ldx	#$04
			jsr	GetDImgName
			txa
			bne	:101
			lda	#80			;Anzahl Tracks 1581 = 80.
			ldx	#<790			;Größe in KBytes für Info-Anzeige.
			ldy	#>790
			jmp	DoCreateDImg
::101			jmp	L401ExitGD

:CreateDNP		ldx	#DrvNative
			stx	SD2IEC_DType
			ldx	#$06
			jsr	GetDImgName
			txa
			bne	:101
			jsr	ClrScreen		;Bildschirmfarben zurücksetzen.
			LoadB	MaxSizeRRAM,255
			LoadB	SetSizeRRAM,64
			jsr	DoDlg_RDrvNMSize
			txa
			bne	:101
			lda	SetSizeRRAM		;Anzahl Tracks Native = Variabel.
			pha				;Größe in KBytes für Info-Anzeige.
			sta	r0L
			ldx	#$00
			stx	r0H
			stx	r1L
			inx
			stx	r1H
			ldx	#r0L
			ldy	#r1L
			jsr	DMult
			lsr	r0H
			ror	r0L
			lsr	r0H
			ror	r0L
			pla
			ldx	r0L
			ldy	r0H
			jmp	DoCreateDImg
::101			jmp	L401ExitGD

;*** DiskImage erstellen.
;Übergabe:		AKKU = Anzahl Tracks 1-255.
;			XReg = Low  DiskImage-Größe.
;			YReg = High DiskImage-Größe.
:DoCreateDImg		sta	a0H
			stx	a2L
			sty	a2H

			jsr	InitForIO		;Bildschirm schwärzen.
			ClrB	$d020
			LoadB	$d027,$0d
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00

			jsr	ClrBitMap		;Bildschirm löschen.

			jsr	UseGDFont
			Display	ST_WR_FORE

			FillPRec$00,$b8,$c7,$0000,$013f
			jsr	i_ColorBox
			b	$00,$00,$28,$17,$00
			jsr	i_ColorBox
			b	$00,$17,$28,$02,$36

			PrintXY	6,190,V401c0		;Status-Anzeige vorbereiten.
			PrintXY	6,198,V401c1

			LoadW	r11,6			;Disk-Größe anzeigen.
			LoadB	r1H,198
			MoveW	a2,r0
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal
			lda	#" "
			jsr	SmallPutChar
			lda	#"K"
			jsr	SmallPutChar
			lda	#"b"
			jsr	SmallPutChar

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler?
			bne	:100			;Ja => Kein Image aktiv.

			jsr	PurgeTurbo		;Eine Ebene im SD2IEC-Verzeichnis
			jsr	InitForIO		;zurück / aktuelles Image verlassen.
			ClrB	STATUS
			CxSend	V401b0
			ldx	STATUS
			jsr	DoneWithIO
			txa
			bne	:101

::100			jsr	OpenDImgFile		;Neues DiskImage anlegen.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...
			jsr	CloseDImgFile		;DiskImage schließen.

			ldx	V401a7			;OPEN-Befehl auf "APPEND" ändern.
			dex
			lda	#"A"
			sta	FComSDImgNm,x

			jsr	WriteTracks		;DiskImage mit $00-Bytes füllen.

			C_Send	V401b2			;In DiskImage wechseln.

			jsr	ClrScreen		;Bildschirmfarben zurücksetzen.
			jsr	SetGDScrnCol

			lda	FrmtModeType		;Infobox "Diskette formatieren"
			jsr	SetIBoxData		;anzeigen.
			jsr	DefInfoBox

			C_Send	V401b4			;ID-Format-Befehl senden.

			jsr	NewOpenDisk		;Diskette öffnen.
							;NewOpenDisk erforderlich um den
							;Format-Befehl abzuwarten...

;--- Ergänzung: 10.12.18/M.Kanet
;Wird die Disk nicht neu initialisiert geht erhält GEOS beim lesen der BAM
;vom SD2IEC evtl. noch Reste des vorherigen DiskImage mit der falschen
;Anzahl an Tracks im DiskImage.
			C_Send	InitNewDisk		;Disk initialisieren da sonst BAM des
							;vorherigen DiskImages noch aktiv.

			jsr	LoadDriveROM		;Laufwerks-ROM laden?
			txa
			bne	:102			; => Nein, weiter...

			jsr	OpenDisk		;OpenDisk aktualisiert bei NativeMode
			txa				;die Anzahl der Tracks auf Disk.
			bne	:101			;DiskError => Ja, Abbruch...

::102			jsr	ClrScreen		;Bildschirmfarben zurücksetzen.
			lda	FrmtNxDsk		;Weitere Disketten formatieren ?
			beq	:103			; => Nein, Ende...
			jmp	AskDoFrmtAgn		;Weitere Diskette formatieren ?
::103			jmp	L401ExitGD		;Zurück zu GeoDOS.
::101			jmp	DiskError		;Diskettefehler anzeigen.

;*** DiskImage mit $00-Bytes füllen.
;Zum erstellen der DskImages wird der "P"-Befehl verwendet der ausserhalb
;eines DiskImages auch für Dateien verwendet werden kann um den Zeiger auf
;ein bestimmtes Byte zu setzen.
:WriteTracks		ldx	#$00			;"P"-Befehl initialisieren.
			stx	FCom_SetPos +2
			stx	FCom_SetPos +3
			stx	FCom_SetPos +4
			stx	FCom_SetPos +5
			inx
			stx	a0L

::101			MoveB	a0L,r1L
			jsr	GetMaxSek		;Anzahl Sektoren für Track ermitteln.
			MoveB	r1H,a1L
			jsr	CopyInfo		;Status-Meldung ausgeben.
			jsr	OpenDImgFile		;DiskImage-Datei öffnen.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch...

::102			inc	FCom_SetPos +3		;Byte-Zähler anpassen.
			bne	:102a
			inc	FCom_SetPos +4
			beq	:105
::102a			dec	a1L			;Zeiger auf letztes Byte gesetzt?
			bne	:102			; => Nein, nächster Sektor.

::104			lda	#15			;"P"-Befehl an SD2IEC senden.
			ldx	curDrive
			tay
			jsr	SETLFS
			lda	#$00
			jsr	SETNAM
			jsr	OPENCHN			;Befehlskanal öffnen.

			jsr	UNTALK

			lda	curDrive		;Aktuelles Laufwerk auf Befehls-
			jsr	LISTEN			;empfang vorbereiten.

			lda	#15 ! %11110000
			jsr	SECOND			;Daten über Befehls-Kanal senden.
			ldy	#$00
::106			tya
			pha
			lda	FCom_SetPos,y
			jsr	$ffd2
			pla
			iny
			cpy	#7
			bcc	:106

			jsr	UNLSN

			lda	#15			;Befehls- und Datenkanal schließen.
			jsr	CLOSE
			jsr	CloseDImgFile

			lda	a0L
			inc	a0L
			cmp	a0H			;Alle Tracks erzeugt?
			bcc	:101			; => Nein, weiter...
			jmp	CopyInfo		;Status aktualisieren und Ende.

::103			jsr	CloseDImgFile
::105			jmp	DiskError

:FCom_SetPos		b "P",$02,$00,$00,$00,$00,$0d

;*** DiskImage öffnen.
;Beim ersten aufruf wird der Modus "W" = schreiben aktiviert.
;Danach wird "A" für APPEND = Anhängen verwendet.
:OpenDImgFile		lda	curDrive
			jsr	SetDevice
			jsr	PurgeTurbo		;Auf 1541 umschalten.
			jsr	InitForIO

			ClrB	STATUS

;--- Ergänzung: 26.11.18/M.Kanet
;SETBNK ist im GEOS-Kernal nicht vohanden, da beim C128 die
;Einsprungadressen im KERNAL durch eine BANK-Switch-Routine ersetzt
;wurden. Die Routine muss daher manuell nachgebildet werden!
			bit	c128Flag
			bpl	:80
			lda	#1
			ldx	#1
;			jsr	SETBNK
			sta	$c6
			stx	$c7

::80			lda	V401a7			;Dateiname setzen.
			ldx	#<FComSDImgNm
			ldy	#>FComSDImgNm
			jsr	SETNAM
			lda	STATUS
			bne	:90

			lda	#2			;Datenkanal festlegen.
			ldx	curDrive
			ldy	#2
			jsr	SETLFS
			lda	STATUS
			bne	:90

			jsr	OPENCHN			;Datenkanal öffnen.
			bcc	:101
::90			jsr	CloseDImgFile
			ldx	#$0d
			rts

::101			ldx	#$02			;Ausgabekanal festlegen.
			jsr	CKOUT
			ldx	#$00
			rts

;*** DiskImage öffnen.
:CloseDImgFile		lda	#$02
			jsr	CLOSE
			jsr	CLRCHN
			jmp	DoneWithIO

;*** CopyInfo ausgeben.
:CopyInfo		ldx	a0L			;Track beginnt ab #01, für die
			dex				;Prozent-Anzeige Track -1 setzen.
			stx	r0L			;Sonst startet Copy mit >0% und
			LoadB	r1L,100			;Kopiert mit 100% den letzten Track.
			lda	#$00
			sta	r0H
			sta	r1H
			ldx	#r0L
			ldy	#r1L
			jsr	DMult
			MoveB	a0H,r1L
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			LoadB	r1H,198
			LoadW	r11,83

			lda	#%11000000
			jsr	PutDecimal

			lda	#"%"
			jmp	SmallPutChar

;*** DiskImage-Name eingeben.
;    Übergabe: XReg = Zeiger auf Typ-Kennung.
:GetDImgName		lda	V401a1 +0,x
			sta	V401a3 +0
			lda	V401a1 +1,x
			sta	V401a3 +1

			ldy	#$00
::101			lda	DiskImgName,y
			beq	:102
			sta	V401a4,y
			iny
			cpy	#16
			bcc	:101
			lda	#$00
::102			sta	V401a4,y

			jsr	ClrScreen

			jsr	InfUpperCase		;Hinweis: Großbuchstaben.

			lda	curType			;Format für neues DiskImage einlesen.
			and	#%00000111
			cmp	SD2IEC_DType		;Gleicher Typ wie Laufwerkstyp?
			beq	:103			; => Ja, weiter...

			jsr	InfLdGEOSDrv		;Hinweis: GEOS-Treiber laden.

::103			LoadW	r0,V401a4
			LoadW	r1,InpDiskName
			LoadB	r2L,$ff
			LoadB	r2H,$00
			LoadW	r3,TitelNewName
			jsr	cbmSetName
			cmp	#$01
			beq	:201
			ldx	#$ff
			rts

;--- Name aus Eingabepuffer in Zwischenspeicher kopieren.
::201			ldy	#$00
			ldx	#$00
::202			lda	InpDiskName,y
			beq	:204
			cmp	#$61
			bcc	:203
			cmp	#$7f
			bcs	:203
			sec
			sbc	#$20
::203			sta	V401a6,y
			iny
			cpy	#16
			bcc	:202
			lda	#$00
::204			sta	V401a6,y
			tya
			tax
			bne	:401

;--- Leeres Eingabefeld, Standardname kopieren.
::301			ldx	#$00
::302			lda	V401a4,x
			beq	:401
			sta	V401a6,x
			inx
			cpx	#16
			bcc	:302

;--- Nach Erweiterung .Dxx suchen und löschen.
::401			dex
			lda	V401a6,x
			cmp	#"."
			bne	:402
			lda	V401a6+1,x
			cmp	#"D"
			bne	:402
			lda	V401a6+2,x
			cmp	V401a3 +0
			bne	:402
			lda	V401a6+3,x
			cmp	V401a3 +1
			bne	:402
			lda	#$00
			sta	V401a6,x
			beq	:501
::402			cpx	#$00
			bne	:401

;--- Name in OPEN-Befehl eintragen.
::501			ldy	#$00
::502			lda	V401a6,y
			beq	:503
			jsr	:601
			cpy	#12
			bcc	:502
::503			lda	#"."
			jsr	:601
			lda	#"D"
			jsr	:601
			lda	V401a3 +0
			jsr	:601
			lda	V401a3 +1
			jsr	:601

			lda	#$00
			sta	V401c0a,y
			sta	V401b2a,y
			tya
			clc
			adc	#$03
			sta	V401b2
			lda	#","
			sta	V401b4a +0,y
			lda	#"0"
			sta	V401b4a +1,y
			lda	#"1"
			sta	V401b4a +2,y
			lda	#$00
			sta	V401b4a +3,y
			tya
			clc
			adc	#$06
			sta	V401b4

			lda	#","
			jsr	:602
			lda	#"P"
			jsr	:602
			lda	#","
			jsr	:602
			lda	#"W"
			jsr	:602
			iny
			iny
			iny
			sty	V401a7
			ldx	#$00
			rts

::601			sta	V401c0a,y
			sta	V401b2a,y
			sta	V401b4a,y
::602			sta	FComSDImgFNm,y
			iny
			rts

;*** Laufwerksrom für SD2IEC laden.
:LoadDriveROM		lda	curType			;Format für neues DiskImage einlesen.
			and	#%00000111
			cmp	SD2IEC_DType		;Gleicher Typ wie Laufwerkstyp?
			bne	:102			; => Nein, weiter...
::101			ldx	#$00
			rts

::102			lda	SD2IEC_DType		;Bei NativeMode ist kein ROM notwendig.
			cmp	#$04			;NativeMode?
			beq	:103			; => Ja, weiter...

			asl				;Laufwerkstyp in Hinweistext und
			tax				;"XR"-Befehl eintragen.
			lda	V401a2 +0,x
			sta	V401i5 +2
			sta	V401b5 +10
			lda	V401a2 +1,x
			sta	V401i5 +3
			sta	V401b5 +11

			jsr	ClrScreen

			jsr	InfLdDrvROM		;Hinweis: ROM laden?

			DB_UsrBoxV401i4
			jsr	ClrScreen		;Bildschirmfarben zurücksetzen.

			CmpBI	sysDBData,3		;"JA" ?
			bne	:103			; => Nein, weiter...

			C_Send	V401b5			;"XR:DOS15xx.BIN"-Befehl senden.

			DB_OK	V401i6			;Hinweis: GEOS-Treiber laden.

			lda	#$00			;Keine weitere Disk formatieren, erst
			sta	FrmtNxDsk		;muss der Treiber gewechselt werden!

::103			ldx	#$ff
			rts

;*** BAM löschen.
:ClearBAM		lda	curType
			and	#DRIVE_MASK
			cmp	#%0000 0011
			beq	Is1581
			cmp	#%0000 0100
			beq	:101
			jmp	No1581

::101			lda	curDrvType
;--- Ergänzung: 22.11.18/M.Kanet
;Drv_RDisk nach Drv_GWRD = GateWay-RAMDisk geändert.
			cmp	#Drv_GWRD
			beq	:102
			jmp	IsNative

::102			jmp	IsRAMDisk

;*** BAM für 1581 erzeugen.
:Is1581			ldy	#16
::101			lda	#40
			sta	dir2Head,y
			sta	dir3Head,y
			iny
			ldx	#4
			lda	#$ff
::102			sta	dir2Head,y
			sta	dir3Head,y
			iny
			dex
			bpl	:102
			tya
			bne	:101

			LoadB	dir2Head+  0,$28
			LoadB	dir2Head+  1,$02
			LoadB	dir3Head+  0,$00
			LoadB	dir3Head+  1,$ff
			LoadB	dir2Head+250,%00100101
			LoadB	dir2Head+251,%11111000

			jsr	ClrGEOSDisk		;GEOS-Kennung löschen.

;*** Verzeichnis in BAM belegen.
:AllocDir		lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk

			MoveW	r1,curDirHead
			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			jsr	InitForIO		;IO aktivieren.
			jsr	AllocChain		;Verzeichnis belegen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			bit	isGEOS			;GEOS-Diskette ?
			bpl	:101			;Nein, weiter...

			lda	curDirHead+172		;Zeiger auf Borderblock richten.
			sta	r6H
			lda	curDirHead+171
			sta	r6L
			jsr	AllocAllDrv		;Borderblock belegen.

::101			jsr	DoneWithIO		;IO abschalten.
::102			rts

;*** BAM für 1541/1571 erzeugen.
:No1581			pha

			LoadB	r1L,1

			ldy	#4
::101			sty	r0L
			jsr	GetSectors

			ldy	r0L
			lda	r1H
			sta	curDirHead+0,y

			lda	#$ff
			sta	curDirHead+1,y
			sta	curDirHead+2,y

			lda	r1H
			sec
			sbc	#16
			tax
			lda	BAM_BitTab-1,x
			sta	curDirHead+3,y
			iny
			iny
			iny
			iny
			inc	r1L
			cpy	#144
			bcc	:101

			dec	curDirHead+72
			LoadB	curDirHead+73,%1111 1110

			jsr	ClrGEOSDisk		;GEOS-Kennung löschen.

			pla
			cmp	#2			;1571?
			bne	AllocDir		; => Nein, weiter...

			lda	curDirHead+3		;Doppelseitige Disk?
			beq	AllocDir		; => Nein, weiter...

			jsr	i_FillRam
			w	256,dir2Head
			b	0

			jsr	i_FillRam
			w	105,dir2Head
			b	$ff

			LoadB	r1L,36
			LoadB	r0H,2

			ldy	#221
::102			sty	r0L
			jsr	GetSectors

			ldy	r0L
			lda	r1H
			sta	curDirHead,y

			lda	r1H
			sec
			sbc	#16
			tax
			lda	BAM_BitTab-1,x
			ldx	r0H
			sta	dir2Head,x

			AddVB	3,r0H
			inc	r1L
			iny
			bne	:102

			LoadB	curDirHead+238,0
			sta	dir2Head+51
			sta	dir2Head+52
			sta	dir2Head+53

			jmp	AllocDir

;*** Native-BAM erzeugen.
:IsNative		jsr	InitSek1BAM
			jsr	InitForIO

			LoadB	r6L,$01
			LoadB	r6H,$00
::102			jsr	AllocAllDrv
			inc	r6H
;--- Ergänzung: 23.04.19/M.Kanet
;Ursprünglich wurde hier auf r6H < 32 geprüft. Die BAM reicht
;aber von Sektor #2 bis einschließlich #33.
;Daher Vergleich auf < 34 geändert.
			CmpBI	r6H,34
			bcc	:102

			jsr	DoneWithIO
			jsr	PutDirHead
			txa
			beq	:104
::103			jmp	DiskError

::104			jsr	EnterTurbo
			txa
			bne	:103

			jsr	InitForIO
			jsr	InitSek2BAM

			LoadB	r1L,$01
			LoadB	r1H,$03
			LoadW	r4,diskBlkBuf
::106			jsr	WriteBlock
			txa
			beq	:107
			jsr	DoneWithIO
			jmp	DiskError

::107			inc	r1H
			CmpBI	r1H,34
			bcc	:106

			jsr	DoneWithIO
			jsr	GetDirHead
			txa
			bne	:103

			jsr	ClrGEOSDisk		;GEOS-Kennung löschen.

;--- Ergänzung: 01.11.18/M.Kanet
;Ursprünglich wurden nur 32 Sektoren belegt. Die BAM reicht aber von
;Sektor #2 bis einschließlich #33. Daher wurden hier im Original-Code
;die letzten beiden Sektoren manuell als belegt markiert.
;Befehl entfällt...
;			lda	#%00111111		;Sektor #32/33 belegt.
;			sta	dir2Head+$24		;BAM-Byte Track #1, Sektor 32-39.
			jmp	AllocDir

;*** RAMDisk validieren (gateWay-NativeRAMDisk)
:IsRAMDisk		jsr	InitSek1BAM
			jsr	InitForIO

			LoadB	r6L,$01
			LoadB	r6H,$00
::102			jsr	AllocAllDrv
			inc	r6H
			CmpBI	r6H,$05
			bcc	:102

			jsr	DoneWithIO
			jsr	PutDirHead
			txa
			beq	:104
::103			jmp	DiskError

::104			jsr	EnterTurbo
			txa
			bne	:103

			jsr	InitForIO
			jsr	InitSek2BAM

			LoadB	r1L,$01
			LoadB	r1H,$03
			LoadW	r4,diskBlkBuf
::106			jsr	WriteBlock
			txa
			beq	:107
			jsr	DoneWithIO
			jmp	DiskError

::107			inc	r1H
			CmpBI	r1H,6
			bcc	:106

			jsr	DoneWithIO
			jsr	GetDirHead
			txa
			bne	:103

			jsr	ClrGEOSDisk		;GEOS-Kennung löschen.

			jmp	AllocDir

;*** BAM-Sektor #1 löschen.
:InitSek1BAM		ldy	#$20
			lda	#$ff
::101			sta	dir2Head,y
			iny
			bne	:101
			rts

:InitSek2BAM		ldy	#$00
			lda	#$ff
::101			sta	diskBlkBuf,y
			iny
			bne	:101
			rts

;*** Sektor-Kette in der BAM belegen.
:AllocChain		lda	r1L			;Track = $00 ?
			beq	:104			;Ja, Ende...

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.

;*** Link-Bytes des ersten Datenblocks einlesen.
::101			ldx	#>ReadLink		;Routine für 1571/1581/Native etc...
			ldy	#<ReadLink
			lda	curType
			and	#DRIVE_MASK
			cmp	#$01
			bne	:102

			ldx	#>ReadBlock		;Routine für 1541...
			ldy	#<ReadBlock
::102			tya
			jsr	CallRoutine		;"ReadLink" (71,81..) "ReadBlock" (41).
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch.

			MoveW	r1,r6			;Sektor in BAM belegen.
			jsr	AllocAllDrv
			txa				;Diskettenfehler ?
			bne	:104			;Ja, Abbruch.

			inc	r2L			;Zähler für Sektoren +1.
			bne	:103
			inc	r2H

::103			lda	diskBlkBuf+1		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	diskBlkBuf+0
			sta	r1L
			bne	:101			;Ende erreicht ? Nein, weiter...
::104			rts

;*** Sektor auf allen Laufwerken belegen.
:AllocAllDrv		jsr	DoneWithIO

			lda	curType			;Lafwerk vom Typ 1541 ?
			and	#DRIVE_MASK
			cmp	#$01
			beq	:101			;Ja, weiter...
			jsr	AllocateBlock		;Sektor in BAM belegen.
			jmp	:103

;*** Sonderbehandlung 1541.
::101			jsr	FindBAMBit		;Prüfen, ob Sektor bereits belegt.
			beq	:102			;Ja, Fehler "BAD BAM", Abbruch.

			lda	r8H			;Sektor in BAM belegen.
			eor	#$ff
			and	curDirHead,x
			sta	curDirHead,x
			ldx	r7H			;Anzahl freie Sektoren auf Track -1.
			dec	curDirHead,x

			ldx	#0			;Kein Fehler.
			b $2c
::102			ldx	#6			;Fehler "BAD_BAM".
::103			txa
			pha
			jsr	InitForIO
			pla
			tax
			rts

;*** Ersten Directory-Sektor ermitteln.
:Get1stDirBlk		and	#DRIVE_MASK		;Laufwerkstyp ermtteln.
			cmp	#$03
			beq	:101
			cmp	#$04
			beq	:102

			lda	#18			;1541/1571-Laufwerk:
			ldy	#01			;Sektor 18/1.
			bne	:103

::101			lda	#40			;1581-Laufwerk:
			ldy	#03			;Sektor 40/3.
			bne	:103

::102			lda	curDirHead+0		;Native-Laufwerk:
			ldy	curDirHead+1		;Sektor aus ":curDirHead" entnehmen.
::103			sta	r1L			;Zeiger auf ersten Sektor
			sty	r1H			;im Verzeichnis merken.
			rts

;--- Ergänzung: 22.11.18/M.Kanet
;Für DiskImage erstellen wird für alle Laufwerks-Modi die max. Anzahl
;an Sektoren für jeden Track ermitteln.
;*** Sektor-Anzahl für Spur-Nr. bestimmen (1541/71/81/Native).
:GetMaxSek		ldx	SD2IEC_DType
			beq	:102
			dex
			beq	GetSectors
			dex
			beq	GetSectors
			dex
			bne	:101
			LoadB	r1H,40
			ldx	#$00
			rts
::101			dex
			bne	:102
			stx	r1H
			rts
::102			ldx	#$0d
			rts

;*** Sektor-Anzahl für Spur-Nr. bestimmen (1541/71).
:GetSectors		lda	r1L			;Track = $00 ?
			beq	:101			;Ja, Abbruch.

			ldy	SD2IEC_DType		;Laufwerkstyp festlegen.
			dey				;1541-Laufwerk ?
			bne	:102			;Nein, weiter...

			CmpBI	r1L,36			;Track von $01 - $33 ?
			bcc	:103			;Ja, weiter...
::101			ldx	#INV_TRACK		;Fehler "Invalid Track".
			rts				;Abbruch.

::102			dey				;1571-Laufwerk ?
			bne	:107			;Nein, weiter...

			CmpBI	r1L,71			;Track von $00 - $46 ?
			bcs	:101			;Nein, Abbruch.

::103			ldy	#7			;Zeiger auf Track-Tabelle.
::104			cmp	Tracks,y		;Track > Tabellenwert ?
			bcs	:105			;Ja, max. Anzahl Sektoren einlesen.
			dey				;Zeiger auf nächsten Tabellenwert.
			bpl	:104			;Weiteruchen.
			bmi	:101			;Ungültige Track-Adresse.

::105			tya				;Bei 1571 auf Track $01-$33 begrenzen.
			and	#%0000 0011
			tay
			lda	Sectors,y		;Anzahl Sektoren einlesen
::106			sta	r1H			;und merken...
			ldx	#0			;"Kein Fehler"...
			rts

::107			ldx	#$0d			;Routine wird nur bei 1541/1571
			rts				;aufgerufen. Bei 1581/Native -> Fehler.

;*** Auswahlbox erzeugen.
;    r0 zeigt auf Tabelle mit Format-Texten.
:DoFrmtTypeBox		lda	VecToTypeTab+0,x
			sta	V401k1+0
			lda	VecToTypeTab+1,x
			sta	V401k1+1
			lda	VecToTypeTab+2,x
			sta	r0L
			lda	VecToTypeTab+3,x
			sta	r0H

			LoadW	r1,FileNTab		;Zeiger auf Anfang Tabelle.

::101			ldy	#$00
			lda	(r0L),y			;Nr. des Format-Textes einlesen.
			bmi	:103			;$FF = Ende der Tabelle.
							;Zeiger auf Text-String berechnen.
			tax
			LoadW	r15,FrmtModeText
::101a			dex
			cpx	#$ff
			beq	:101b
			jsr	Add_16_r15
			jmp	:101a
::101b			ldy	#$00
::102			lda	(r15L),y		;Text in Tabelle kopieren.
			sta	(r1L),y
			iny
			cpy	#$10
			bne	:102
			AddVBW	16,r1
			IncWord	r0
			jmp	:101

::103			ldy	#$00			;Tabellen-Ende kennzeichnen.
			tya
			sta	(r1L),y

			lda	#<V401k0
			ldx	#>V401k0
			jsr	SelectBox

			lda	r13L			;Dateiauswahl ?
			beq	:104			;Nein, weiter...
			jmp	L401ExitGD
::104			rts

;*** Info-Box definieren.
;r15 zeigt auf Tabelle für Texte 1 & 2.
:DefInfoBox		LoadW	r14,V401j2		;Zeiger auf Info-Box-Text.

			ldx	#<V401j0		;Position in Info-Text kopieren.
			ldy	#>V401j0
			jsr	InsPosTxt
			ldy	#$00
			jsr	CopyText		;Text in Info-Text kopieren.
			ldx	#<V401j1		;Position in Info-Text kopieren.
			ldy	#>V401j1
			jsr	InsPosTxt
			ldy	#$02
			jsr	CopyText		;Text in Info-Text kopieren.
			lda	#$00
			tay
			sta	(r14L),y		;Text-Ende kennzeichnen.
			jsr	DoInfoBox		;Info-Box aufbauen.
			PrintStrgV401j2			;Info-Text ausgeben.
			rts

;*** GEOS-Diskettenmarkierung löschen und GEOS-Disk erzeugen.
:ClrGEOSDisk		ldy	#$ab
			lda	#$00
::101			sta	curDirHead,y
			iny
			cpy	#$be
			bne	:101
			sta	isGEOS
			rts

;*** Position der Texte in Info-Box-Text eintragn.
:InsPosTxt		stx	r0L
			sty	r0H
			ldy	#$00
::101			lda	(r0L),y
			sta	(r14L),y
			iny
			cpy	#$06
			bne	:101
			AddVBW	6,r14
			rts

;*** Text in Info-Box-Text kopieren.
:CopyText		lda	(r15L),y
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			ldy	#$00
::101			lda	(r0L),y
			beq	:102
			sta	(r14L),y
			iny
			bne	:101
::102			tya
			clc
			adc	r14L
			sta	r14L
			bcc	:103
			inc	r14H
::103			rts

;*** Diskette einlegen.
:DoInsertDisk		sta	FrmtMode
			lda	curDrive
			ldx	#$7f
			jsr	InsertDisk
			cmp	#$01
			bne	:101
			lda	FrmtMode
			rts

::101			jmp	L401ExitGD

;*** Partition setzen.
:DoGetPart		jsr	CMD_GetPart		;Partition wählen, falls CMD-Laufwerk.
			txa
			beq	:102			;xReg = $00, OK.
			pla				;Rücksprungadresse vom Stapel holen.
			pla
			cpx	#$ff			;xReg = $ff, Abbruch.
			beq	:101
			jmp	DiskError		;Disketten-Fehler.
::101			jmp	L401ExitGD		;Zurück zu GeoDOS.

::102			rts

;*** Frage: "IECNM löschen ?"
:AskToClrIECNM		LoadW	V401g0,FrmtMode_55
			jmp	AskToClr

;*** Frage: "RAM-Disk löschen ?"
:AskToClrRAM		LoadW	V401g0,FrmtMode_51
			jmp	AskToClr

;*** Frage: "Partition löschen ?"
:AskToClrPart		lda	curDrive
			sta	Target_Drv
			bit	DiskFrmtMode		;Aktive Disk formatieren?
			bmi	:101			; => Ja, weiter...

			ldx	#<Titel_Part		;Partition auswählen.
			ldy	#>Titel_Part
			jsr	DoGetPart

			jsr	GetCurPInfo		;Partitionsdaten einlesen.
			txa				;Fehler?
			beq	:104			; => Nein, weiter...
			bne	:103			; => Ja, Abbruch...

::101			ldx	curDrive
			lda	DrivePart -8,x
			jsr	SetNewPart
			txa
			beq	:104

::103			pla				;Fehler: "Keine aktive Partition!"
			pla
			lda	curDrive
			add	$39
			sta	V401i2    +12
			DB_OK	V401i0
			jmp	GetDrvType

::104			ldx	curDrive
;--- Ergänzung: 27.11.18/M.Kanet
;Prüfen ob Formatieren auf dem Systemlaufwerk möglich ist.
			cpx	AppDrv
			bne	:105
			lda	DriveModes-8,x
			bpl	:105
			lda	DrivePart -8,x
			cmp	AppPart
			bne	:105

			DB_OK	V401i3			;Fehler: Das Systemlaufwerk
			jmp	L401ExitGD		;kann nicht formatiert werden!

::105			lda	DrivePart -8,x

			LoadW	V401g0,FrmtMode_50
			LoadW	r0,Part_Info +5
			jmp	InitDskName

;*** Frage: "RAM-Disk/Partition löschen ?"
:AskToClr		jsr	CBM_GetDskNam		;Disketten-Name einlesen.
			LoadW	r0,cbmDiskName

:InitDskName		lda	curDrive		;Laufwerk in Info-Box.
			add	$39
			sta	FrmtMode_53 + 9

			ldy	#$00			;Disketten-Name in Info-Box-Text
::101			lda	(r0L),y			;übertragen.
			jsr	ConvertChar
			sta	FrmtMode_54,y
			iny
			cpy	#$10
			bne	:101

			DB_UsrBoxV401g0
			CmpBI	sysDBData,YES
			beq	:102
			jmp	L401ExitGD
::102			rts

;*** Partitionsnamen anzeigen.
:PrintPart		jsr	UseGDFont
			Print	$0040,$66
			b	PLAINTEXT,"Name :",NULL
			FrameRec$5f,$68,$007f,$0100,%11111111
			FillPRec$00,$60,$67,$0080,$00ff
			jsr	i_ColorBox
			b	$10,$0c,$10,$01,$01
			PrintXY	$0082,$66,FrmtMode_54
			jmp	ISet_Frage

;*** Abfrage zum formatieren weiterer Disketten...
:AskDoFrmtAgn		ldx	ReturnAddress+1
			bne	:101

			DB_UsrBoxV401h0
			CmpBI	sysDBData,3
			bne	:101
			jmp	GetDrvType
::101			jmp	L401ExitGD

;*** Name für Diskette erzeugen.
:SetFrmtName_a		ldx	#<StdFrmtName		;"GeoDOS" als Disketten-Name setzen.
			ldy	#>StdFrmtName
			bne	SetFrmtName

:SetFrmtName_b		ldx	#<cbmDiskName		;Alten Disketten-Namen setzen.
			ldy	#>cbmDiskName
			bne	SetFrmtName

:SetFrmtName_c		ldx	#<DiskImgName		;Alten Disketten-Namen setzen.
			ldy	#>DiskImgName

:SetFrmtName		stx	r0L
			sty	r0H

			LoadW	r1,ExecFormat+4		;Name in Format-Befehl übertragen.

			ldy	#$00
::101			lda	(r0L),y
			bne	:102
			lda	#" "
::102			sta	(r1L),y
			iny
			cpy	#$10
			bne	:101

			AddVBW	16,r1
			LoadW	ExecFormat,18		;Länge des Format-Befehls.
			rts

;*** CBM Format-Option definieren.
:SetCBMFrmtOpt		asl				;ID an Format-Befehl anhängen.
			asl
			tax
			ldy	#$00
::101			lda	Format_ID1,x
			sta	(r1L),y
			inx
			iny
			cpy	#$03
			bne	:101

			AddVBW	3,r1
			LoadW	ExecFormat,21		;Länge des Format-Befehls.
			rts

;*** CMD Format-Option definieren.
:SetCMDFrmtOpt		asl				;CMD-ID an Format-Befehl anhängen.
			asl
			tax
			ldy	#$00
::101			lda	Format_ID2,x
			sta	(r1L),y
			inx
			iny
			cpy	#$04
			bne	:101

			LoadW	ExecFormat,25		;Länge des Format-Befehls.
			rts

;*** "QuickFormat"-Routine ins 1541-RAM übertragen.
:InitFastFrmt		LoadW	a8,FastFormat
			LoadB	FD_MWa +1,$05

			jsr	PurgeTurbo
			jsr	InitForIO
			ClrB	STATUS

			jsr	L401a0
			txa
			bne	:101
			inc	FD_MWa +1		;Bytes 256-511 schreiben.
			inc	a8H
			jsr	L401a0

::101			jmp	DoneWithIO

;*** Speicherbereich an Floppy ünertragen.
:L401a0			ldy	#$07
::101			tya
			pha
			lda	FD_MWc,y
			sta	FD_MWa
			sta	FD_MWb
			jsr	:103
			pla
			tay
			txa
			bne	:102
			dey
			bpl	:101
::102			rts

;*** 32 Byte in Floppy-RAM übertragen.
::103			DrvListencurDrive
			ChkStatus:106

			ldy	#$00			;"M-W" an Floppy.
::104			lda	FD_MW,y
			jsr	CIOUT
			iny
			cpy	#$06
			bne	:104

			ldy	FD_MWb
			ldx	#$20
::105			lda	(a8L),y
			jsr	CIOUT
			iny
			dex
			bne	:105
			b $2c
::106			ldx	#$44
			jmp	UNLSN

;*** Variablen.
:FD_MW			b "M-W"
:FD_MWa			w $0500
			b $20
:FD_MWb			b $00
:FD_MWc			b $e0,$c0,$a0,$80
			b $60,$40,$20,$00

;*** L401: Diskette (CBM) umbenennen.
:CBM_Rename		jsr	CMD_OtherPart		;Auf CMD-Laufwerken die Partition
			txa				;wechseln und ROOT-Verzeichnis öffnen.
			bne	:103

;--- Ergänzung: 04.12.18/M.Kanet
;Auf Nicht-CMD-Laufwerken das Hauptverzeichnis aktivieren. Sonst wird
;nur der Unterverzeichnis-Header umbenannt.
::101			lda	curDrvMode		;CMD-Laufwerk?
			bmi	:101a			; => Ja, weiter...
			and	#%00100000		;NativeMode?
			beq	:101a			; => Nein, weiter...
			jsr	New_CMD_Root		;Hauptverzeichnis öffnen.
			txa
			beq	:102
::101b			jmp	DiskError		;Disk-Fehler.

::101a			jsr	NewOpenDisk		;Diskette öffnen.
			txa
			bne	:101b

::102			jsr	CBM_GetDskNam		;Name einlesen.
			LoadW	r0,cbmDiskName
			LoadB	r2H,$ff
			jsr	SetName
			txa
			bne	:103

			jsr	Test1581Disk
			txa
			bne	:103

;--- Ergänzung: 04.12.18/M.Kanet
;Nur bei CMD-Laufwerken mit mehr als einer Partition
;das umbenennen weiterer Partitionen ermöglichen.
			bit	curDrvMode
			bpl	:103
			jsr	CMD_Part
			cpx	#$00
			bne	:103
			cmp	#$02
			bcc	:103
			jmp	CBM_Rename
::103			jmp	InitScreen

;*** FORMAT: Neuen Namen definieren.
:NewFrmtName		jsr	CBM_GetDskNam
			LoadW	r0,StdFrmtName
			LoadB	r2H,$00
			jmp	SetName

;*** FORMAT: Alten Name ändern.
:NewDiskName		LoadW	r0,cbmDiskName
			LoadB	r2H,$ff

;*** Neuen Namen definieren.
:SetName		ldy	#15
::101			lda	(r0L),y
			sta	CurDiskName,y
			dey
			bpl	:101

			MoveB	r2H,L401b0 +1

;*** Eingabe des Disketten-Name.
:GetName		jsr	ClrBox

			LoadW	r0,CurDiskName
			LoadW	r1,InpDiskName
			LoadB	r2L,$ff
:L401b0			lda	#$ff
			sta	r2H
			LoadW	r3,TitelNewName
			jsr	cbmSetName
			cmp	#$01			;Nochmal eingeben.
			beq	:101

			ldx	#$ff			;Eingabe Diskname abgebrochen.
			rts

::101			ldx	#$00
::102			lda	InpDiskName,x
			beq	:103
			inx
			cpx	#$10
			bne	:102
			jmp	SetCBMName

::103			lda	#$a0
::104			sta	InpDiskName,x
			inx
			cpx	#$10
			bne	:104
			jmp	SetCBMName

;*** Auf 1581-Disk im Laufwerk testen.
:Test1581Disk		bit	curDrvMode
			bpl	:103

			jsr	GetCurPInfo		;Partitionsdaten einlesen.
			txa
			bne	:103

			lda	curDrvType
			cmp	#Drv_CMDFD2
			beq	:101
			cmp	#Drv_CMDFD4
			bne	:102
::101			lda	Part_Info +3
			and	#%00010000
			bne	:103

::102			ldx	#$00
			rts

::103			ldx	#$ff
			rts

;*** Name wieder auf Disk schreiben.
:SetCBMName		jsr	DoInfoBox
			PrintStrgInfo_PutName

			jsr	GetDirHead
			txa
			bne	ErrRename

			ldy	#15
::101			lda	InpDiskName,y
			sta	curDirHead + $90,y
			dey
			bpl	:101

			ldx	curDrive		;Sektor mit Disketten-Name
			lda	driveType-8,x		;ermitteln.
			and	#%00000111
			beq	EndRename		;Typ unbekannt.
			cmp	#$01			;Typ 1541.
			beq	:102
			cmp	#$02			;Typ 1571.
			beq	:102
			cmp	#$03			;Typ 1581.
			beq	:103
			cmp	#$04			;Typ Native.
			beq	:104
			jmp	EndRename		;Typ unbekannt.

::102			lda	#$12			;Spur $12, Sektor $00.
			ldx	#$00
			jmp	:105
::103			lda	#$28			;Spur $28, Sektor $00.
			ldx	#$00
			jmp	:105
::104			lda	#$01			;Spur $01, Sektor $01.
			ldx	#$01

;*** Sektor mit Name zurück auf Diskette schreiben.
::105			sta	r1L
			stx	r1H
			LoadW	r4,curDirHead
			jsr	PutBlock
			txa
			bne	ErrRename

			bit	curDrvMode
			bmi	RenPartNam		;Partitions-Namen ändern.
:EndRename		jsr	ClrBox
			ldx	#$00
			rts

:ErrRename		jsr	ClrBox
			jmp	DiskError

;*** Partitionsname ändern.
:RenPartNam		jsr	Test1581Disk
			txa
			bne	EndRename

			jsr	ClrBoxText
			PrintStrgInfo_NewPName

			ldy	#$06
			ldx	#$00			;Name aus Eingabepuffer in "Rename"-
::103			lda	InpDiskName,x		;Befehl kopieren.
			beq	:104
			cmp	#$a0
			beq	:104
			sta	ExecRenPart,y
			iny
			inx
			cpx	#$10
			bne	:103
::104			cpx	#$00			;Neuer Partitionsname > 0 Zeichen ?
			beq	:107			;Nein, Ende.

			lda	#"="			;"=" als Trennzeichen.
			sta	ExecRenPart,y
			iny
			ldx	#$00
::105			lda	Part_Info +5,x		;Alten Partitions-Namen einfügen.
			cmp	#$a0
			beq	:106
			sta	ExecRenPart      ,y
			iny
			inx
			cpx	#$10
			bne	:105
::106			dey
			dey
			sty	ExecRenPart

			C_Send	ExecRenPart		;"R-P"-Befehl senden.
::107			jsr	ClrBox
			ldx	#$00
			rts

;*** Variablen.
:StackPointer		b $00
:ReturnAddress		w $0000
:FrmtMode		b $00
:CMDParts		b $00
:FrmtNxDsk		b $00
:FrmtModeType		b $00

;*** Variablen für SD-Image-Wechsel.
:EntryCnt_File		b $00
:EntryCnt_SDir		b $00
:SD2IEC_DType		b $00				;Format-Typ (41/1, 71/2, 81/3, NM/4)

;*** Dateiname für neues DiskImage.
:FComSDImgNm		b $40,"0:"
:FComSDImgFNm		b "1234567890123456"
			b ",P,W",NULL

;*** Aufruf aus Disk-2-Disk.
;    $FF = TRUE -> Nur aktuelle Disk formatieren.
:DiskFrmtMode		b $00

;*** Format-Auswahl und Diskname.
:V401a1			b "647181NP"
:V401a2			b "??417181"
:V401a3			b "64"
:V401a4			s 17
:V401a6			s 17
:V401a7			b $00

;*** Floppy-Befehle.
:V401b0			w $0003
			b "CD",$5f
:V401b1			w $0004
			b "CD//"
:V401b2			w $0000
			b "CD:"
:V401b2a		s 17
:V401b3			w $0000
			b "MD:"
:V401b3a		s 17
:V401b4			w $0000
			b "N0:"
:V401b4a		s 20
:V401b5			w $000e
			b "XR:DOS15xx.BIN"
:V401b6			b "$:*.D??=P",NULL
:V401b7			b "$:*=B",NULL

;*** Allgemeine Texte.
:V401c0			b PLAINTEXT
			b "DiskImage: "
:V401c0a		b "1234567890123456",NULL
:V401c1			b "         : ",NULL

if Sprache = Deutsch
;*** Neuen Verzeichnisnamen eingeben.
:V401c2			b PLAINTEXT
			b "Verzeichnisname:"
			b PLAINTEXT,BOLDON,NULL

;*** Texte für Dateiauswahlbox.
:V401c3			b PLAINTEXT,"Verzeichnis wählen",NULL
:V401c4			b "<=        (ROOT)"
			b "..      (ZURÜCK)"
			b "=>   (ERSTELLEN)"
endif

if Sprache = Englisch
;*** Neuen Verzeichnisnamen eingeben.
:V401c2			b PLAINTEXT
			b "Directory name:"
			b PLAINTEXT,BOLDON,NULL

;*** Texte für Dateiauswahlbox.
:V401c3			b PLAINTEXT,"Select Directory",NULL
:V401c4			b "<=        (ROOT)"
			b "..          (UP)"
			b "=>      (CREATE)"
endif

;*** Format auf Systemlaufwerk möglich?
;*** DriveType-Datentabelle.
:FrmtSysDrive		b FALSE
			b FALSE,FALSE,FALSE
			b FALSE,FALSE,FALSE,FALSE
			b FALSE
			b TRUE,TRUE
			b TRUE,TRUE,TRUE
			b FALSE
			b FALSE,FALSE,FALSE
			b FALSE

;*** Format-Auswahl für Laufwerkstypen.
;*** DriveType-Datentabelle.
:VecSlctTabH		b >L401ExitGD-1
			b >Slct1541  -1,>Slct1571  -1,>Slct1581  -1
			b >SlctRAM41 -1,>SlctRAM71 -1,>SlctRAM81 -1,>SlctRAMNM -1
			b >SlctRAMGW -1
			b >SlctRL    -1,>SlctRD    -1
			b >SlctFD2   -1,>SlctFD4   -1,>SlctHD    -1
			b >Slct64Net -1
			b >Slct1581  -1,>SlctFD2   -1,>SlctFD4   -1
			b >SlctIECNM -1
:VecSlctTabL		b <L401ExitGD-1
			b <Slct1541  -1,<Slct1571  -1,<Slct1581  -1
			b <SlctRAM41 -1,<SlctRAM71 -1,<SlctRAM81 -1,<SlctRAMNM -1
			b <SlctRAMGW -1
			b <SlctRL    -1,<SlctRD    -1
			b <SlctFD2   -1,<SlctFD4   -1,<SlctHD    -1
			b <Slct64Net -1
			b <Slct1581  -1,<SlctFD2   -1,<SlctFD4   -1
			b <SlctIECNM -1

:VecSD2ITabH		b >L401ExitGD-1
			b >SlctSD41  -1,>SlctSD71  -1,>SlctSD81  -1,>SlctSDNM  -1
			b >L401ExitGD-1,>L401ExitGD-1,>L401ExitGD-1
:VecSD2ITabL		b <L401ExitGD-1
			b <SlctSD41  -1,<SlctSD71  -1,<SlctSD81  -1,<SlctSDNM  -1
			b <L401ExitGD-1,<L401ExitGD-1,<L401ExitGD-1

;*** Format-Modus für Laufwerkstypen.
:VecFrmtModeH		b >ClrDir    -1,>ClrPart   -1,>ClrRam    -1
			b >ClrGW_RAM -1
			b >Std1541   -1,>QF1541    -1
			b >Std1571   -1,>Std1581   -1,>CMD_81    -1
			b >CMD_DD    -1,>CMD_HD    -1,>CMD_ED    -1
			b >CMD_DDNAT -1,>CMD_HDNAT -1,>CMD_EDNAT -1
			b >Clr64Net  -1,>Clr64Net  -1,>Clr64Net  -1
			b >ClrIECNM  -1
			b >CreateD64 -1,>CreateD71 -1,>CreateD81 -1,>CreateDNP -1
			b >StdNative -1
:VecFrmtModeL		b <ClrDir    -1,<ClrPart   -1,<ClrRam    -1
			b <ClrGW_RAM -1
			b <Std1541   -1,<QF1541    -1
			b <Std1571   -1,<Std1581   -1,<CMD_81    -1
			b <CMD_DD    -1,<CMD_HD    -1,<CMD_ED    -1
			b <CMD_DDNAT -1,<CMD_HDNAT -1,<CMD_EDNAT -1
			b <Clr64Net  -1,<Clr64Net  -1,<Clr64Net  -1
			b <ClrIECNM  -1
			b <CreateD64 -1,<CreateD71 -1,<CreateD81 -1,<CreateDNP -1
			b <StdNative -1

if Sprache = Deutsch
;*** Format-Texte.
:FrmtModeText		b "Inhalt löschen  "		;#0
			b "Format Partition"		;#1
			b "Format RAM-Disk "		;#2
			b "Format NativeRAM"		;#3
			b "Standard  170 KB"		;#4
			b "Quick-Format    "		;#5
			b "Standard  340 KB"		;#6
			b "Standard  790 KB"		;#7
			b "Typ 1581, 790 KB"		;#8
			b "DD, 1x    790 KB"		;#9
			b "HD, 2x    790 KB"		;#10
			b "ED, 4x    790 KB"		;#11
			b "DD, CMD   800 KB"		;#12
			b "HD, CMD  1600 KB"		;#13
			b "ED, CMD  3200 KB"		;#14
			b "64Net     170 KB"		;#15
			b "64Net     340 KB"		;#16
			b "64Net     790 KB"		;#17
			b "IECBus Native   "		;#18
			b "D64 erstellen   "		;#19
			b "D71 erstellen   "		;#20
			b "D81 erstellen   "		;#21
			b "DNP erstellen   "		;#22
			b "Format DiskImage"		;#23

:FrmtMode_20		b "Inhaltsverzeichnis",NULL
:FrmtMode_21		b "Inhalt der Partition",NULL
:FrmtMode_22		b "Inhalt der RAM-Disk",NULL
:FrmtMode_23		b "wird gelöscht...",NULL
:FrmtMode_24		b "Disk wird formatiert...",NULL
:FrmtMode_25		b "(Standard, 170 KByte)",NULL
:FrmtMode_26		b "(QuickFormat, 170 KB)",NULL
:FrmtMode_27		b "(Standard, 340 KByte)",NULL
:FrmtMode_28		b "(Standard, 790 KByte)",NULL
:FrmtMode_29		b "(Standard 1581-Disk)",NULL
:FrmtMode_30		b "(DD, 1x 790 KByte)",NULL
:FrmtMode_31		b "(HD, 2x 790 KByte)",NULL
:FrmtMode_32		b "(ED, 4x 790 KByte)",NULL
:FrmtMode_33		b "(DD, CMD 800 KByte)",NULL
:FrmtMode_34		b "(HD, CMD 1600 KByte)",NULL
:FrmtMode_35		b "(ED, CMD 3200 KByte)",NULL
:FrmtMode_36		b "(64Net, 170 Kbyte)",NULL
:FrmtMode_37		b "(64Net, 340 Kbyte)",NULL
:FrmtMode_38		b "(64Net, 790 Kbyte)",NULL
:FrmtMode_39		b "(IECBus NativeMode)",NULL
:FrmtMode_40		b "(SD2IEC/D64, 170 Kbyte)",NULL
:FrmtMode_41		b "(SD2IEC/D71, 340 Kbyte)",NULL
:FrmtMode_42		b "(SD2IEC/D81, 790 Kbyte)",NULL
:FrmtMode_43		b "(SD2IEC/DNP)",NULL
:FrmtMode_50		b PLAINTEXT,BOLDON,"Inhalt der Partition auf",NULL
:FrmtMode_51		b PLAINTEXT,BOLDON,"Inhalt der RAM-Disk auf",NULL
:FrmtMode_52		b PLAINTEXT,BOLDON,"64Net-Partition auf",NULL
:FrmtMode_53		b "Laufwerk x: löschen ?",NULL
:FrmtMode_54		b "________________",NULL
:FrmtMode_55		b PLAINTEXT,BOLDON,"Inhalt des DiskImage auf",NULL
endif

if Sprache = Englisch
;*** Format-Texte.
:FrmtModeText		b "Clear directory "		;#0
			b "Format Partition"		;#1
			b "Format RAM-Disk "		;#2
			b "Format NativeRAM"		;#3
			b "Standard  170 KB"		;#4
			b "Quick-Format    "		;#5
			b "Standard  340 KB"		;#6
			b "Standard  790 KB"		;#7
			b "Typ 1581, 790 KB"		;#8
			b "DD, 1x    790 KB"		;#9
			b "HD, 2x    790 KB"		;#10
			b "ED, 4x    790 KB"		;#11
			b "DD, CMD   800 KB"		;#12
			b "HD, CMD  1600 KB"		;#13
			b "ED, CMD  3200 KB"		;#14
			b "64Net     170 KB"		;#15
			b "64Net     340 KB"		;#16
			b "64Net     790 KB"		;#17
			b "IECBus Native   "		;#18
			b "Create D64      "		;#19
			b "Create D71      "		;#20
			b "Create D81      "		;#21
			b "Create DNP      "		;#22
			b "Format DiskImage"		;#23

:FrmtMode_20		b "Directory",NULL
:FrmtMode_21		b "Files in partition",NULL
:FrmtMode_22		b "Files in RAM-Disk",NULL
:FrmtMode_23		b "will be deleted...",NULL
:FrmtMode_24		b "Formatting disk...",NULL
:FrmtMode_25		b "(Standard, 170 KByte)",NULL
:FrmtMode_26		b "(QuickFormat, 170 KB)",NULL
:FrmtMode_27		b "(Standard, 340 KByte)",NULL
:FrmtMode_28		b "(Standard, 790 KByte)",NULL
:FrmtMode_29		b "(Standard 1581-Disk)",NULL
:FrmtMode_30		b "(DD, 1x 790 KByte)",NULL
:FrmtMode_31		b "(HD, 2x 790 KByte)",NULL
:FrmtMode_32		b "(ED, 4x 790 KByte)",NULL
:FrmtMode_33		b "(DD, CMD 800 KByte)",NULL
:FrmtMode_34		b "(HD, CMD 1600 KByte)",NULL
:FrmtMode_35		b "(ED, CMD 3200 KByte)",NULL
:FrmtMode_36		b "(64Net, 170 Kbyte)",NULL
:FrmtMode_37		b "(64Net, 340 Kbyte)",NULL
:FrmtMode_38		b "(64Net, 790 Kbyte)",NULL
:FrmtMode_39		b "(IECBus NativeMode)",NULL
:FrmtMode_40		b "(SD2IEC/D64, 170 Kbyte)",NULL
:FrmtMode_41		b "(SD2IEC/D71, 340 Kbyte)",NULL
:FrmtMode_42		b "(SD2IEC/D64, 790 Kbyte)",NULL
:FrmtMode_43		b "(SD2IEC/DNP)",NULL
:FrmtMode_50		b PLAINTEXT,BOLDON,"Delete files on partition",NULL
:FrmtMode_51		b PLAINTEXT,BOLDON,"Delete files on RAMDisk",NULL
:FrmtMode_52		b PLAINTEXT,BOLDON,"Delete files on 64Net",NULL
:FrmtMode_53		b "in drive x: ?",NULL
:FrmtMode_54		b "________________",NULL
:FrmtMode_55		b PLAINTEXT,BOLDON,"Delete files on disk image",NULL
endif

:TabFrmtInfo		w FrmtMode_20,FrmtMode_23	;Verzeichnis löschen.
			w FrmtMode_21,FrmtMode_23	;Partition löschen.
			w FrmtMode_22,FrmtMode_23	;RAM-Disk löschen.
			w FrmtMode_22,FrmtMode_23	;NativeRAM-Disk löschen.
			w FrmtMode_24,FrmtMode_25	;Standard 1541, 170 KByte.
			w FrmtMode_24,FrmtMode_26	;QuickFormat 1541, 170 KByte.
			w FrmtMode_24,FrmtMode_27	;Standard 1571, 340 KByte.
			w FrmtMode_24,FrmtMode_28	;Standard 1581, 790 KByte.
			w FrmtMode_24,FrmtMode_29	;1581-Diskette.
			w FrmtMode_24,FrmtMode_30	;DD, 1 x 790 KByte.
			w FrmtMode_24,FrmtMode_31	;HD, 2 x 790 KByte.
			w FrmtMode_24,FrmtMode_32	;ED, 4 x 790 KByte.
			w FrmtMode_24,FrmtMode_33	;DD, CMD 800 KByte.
			w FrmtMode_24,FrmtMode_34	;HD, CMD 1600 KByte.
			w FrmtMode_24,FrmtMode_35	;ED, CMD 3200 KByte.
			w FrmtMode_24,FrmtMode_36	;64Net, 170 KByte.
			w FrmtMode_24,FrmtMode_37	;64Net, 340 KByte.
			w FrmtMode_24,FrmtMode_38	;64Net, 790 KByte.
			w FrmtMode_24,FrmtMode_39	;IECBus NativeMode.
			w FrmtMode_24,FrmtMode_40	;Neu SD2IEC/D64, 170 KByte.
			w FrmtMode_24,FrmtMode_41	;Neu SD2IEC/D71, 340 KByte.
			w FrmtMode_24,FrmtMode_42	;Neu SD2IEC/D81, 790 KByte.
			w FrmtMode_24,FrmtMode_43	;Neu SD2IEC/DNP.
			w FrmtMode_24,FrmtMode_43	;Format SD2IEC/DNP.

;*** Daten für Auswahlbox.
:VecToTypeTab		w Titel1541,Types1541		;#0
			w Titel1571,Types1571		;#4
			w Titel1581,Types1581		;#8
			w Titel_FD2,Types_FD2		;#12
			w Titel_FD4,Types_FD4		;#16
			w TitelSD41,TypesSD41		;#20
			w TitelSD71,TypesSD71		;#24
			w TitelSD81,TypesSD81		;#28
			w TitelSDNM,TypesSDNM		;#32

;*** Einträge für Laufwerkstabellen.
:Types1541		b 0,4,5,$ff			;1541
:Types1571		b 0,4,6,$ff			;1571
:Types1581		b 0,7,$ff			;1581
:Types_FD2		b 1,8,9,10,12,13,$ff		;FD 2000
:Types_FD4		b 1,8,9,10,11,12,13,14,$ff	;FD 4000
:TypesSD41		b 0,4,19,20,21,22,$ff		;SD2IEC/D64.
:TypesSD71		b 0,6,19,20,21,22,$ff		;SD2IEC/D71.
:TypesSD81		b 0,7,19,20,21,22,$ff		;SD2IEC/D81.
:TypesSDNM		b 0,23,19,20,21,22,$ff		;SD2IEC/DNP.
:SDSlctSDir		b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$ff
			b $ff,$ff,$ff,$00

if Sprache = Deutsch
:Titel1541		b PLAINTEXT,"1541 - Optionen",NULL
:Titel1571		b PLAINTEXT,"1571 - Optionen",NULL
:Titel1581		b PLAINTEXT,"1581 - Optionen",NULL
:Titel_FD2		b PLAINTEXT,"FD 2000 - Optionen",NULL
:Titel_FD4		b PLAINTEXT,"FD 4000 - Optionen",NULL
:TitelSD41		b PLAINTEXT,"SD2IEC/D64 - Optionen",NULL
:TitelSD71		b PLAINTEXT,"SD2IEC/D71 - Optionen",NULL
:TitelSD81		b PLAINTEXT,"SD2IEC/D81 - Optionen",NULL
:TitelSDNM		b PLAINTEXT,"SD2IEC/DNP - Optionen",NULL
endif

if Sprache = Englisch
:Titel1541		b PLAINTEXT,"1541 - Options",NULL
:Titel1571		b PLAINTEXT,"1571 - Options",NULL
:Titel1581		b PLAINTEXT,"1581 - Options",NULL
:Titel_FD2		b PLAINTEXT,"FD 2000 - Options",NULL
:Titel_FD4		b PLAINTEXT,"FD 4000 - Options",NULL
:TitelSD41		b PLAINTEXT,"SD2IEC/D64 - Options",NULL
:TitelSD71		b PLAINTEXT,"SD2IEC/D71 - Options",NULL
:TitelSD81		b PLAINTEXT,"SD2IEC/D81 - Options",NULL
:TitelSDNM		b PLAINTEXT,"SD2IEC/DNP - Options",NULL
endif

;*** Tabelle mit Tracks, bei denen ein Wechsel der
;    Sektoranzahl/Track stattfindet.
:Tracks			b $01,$12,$19,$1f,$24,$35,$3c,$42
:Sectors		b $15,$13,$12,$11

;*** Tabelle zum belegen von Sektoren in der BAM.
:BAM_BitTab		b %00000001
			b %00000011
			b %00000111
			b %00001111
			b %00011111

if Sprache = Deutsch
;*** Formatierungs-Befehle.
:StdFrmtName		b "Arbeitsdiskette",NULL,NULL
:DiskImgName		b "DISKIMAGE",NULL
:ExecFormat		w $0012
			b "N:________________,64,DD8"
:ExecFastFrmt		w $0005
			b "M-E",$60,$06
:SwitchTo1541		w $0006
			b "U0>M0",CR
:InitNewDisk		w $0004
			b "I0:",CR
:SwitchTo1571		w $0006
			b "U0>M1",CR

:Format_ID1		b 0,0,0,0
			b ",64 "
:Format_ID2		b ",81 ,DD8,HD8,ED8,DDN,HDN,EDN"

:MaxRenamePart		b $00				;Aktuelle Partition für Rename.
:CurRenamePart		b $00				;Max. Partitionen auf neuer Diskette.

;*** Frage: "RAM-Disk/Partition löschen ?"
:V401g0			w FrmtMode_50, FrmtMode_53, PrintPart
			b NO,YES

;*** Infobox: "Weitere Disketten formatieren ?"
:V401h0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Möchten Sie eine weitere",NULL
::102			b        "Diskette formatieren ?",NULL

;*** Hinweis: "Keine aktive Partition auf Laufwerk x:"
:V401i0			w V401i1, V401i2, ISet_Achtung
:V401i1			b BOLDON,"Keine aktive Partition",NULL
:V401i2			b        "in Laufwerk x: !",NULL

;*** Hinweis: "Kann Systemlaufwerk nicht formatieren!"
:V401i3			w :101, :102, ISet_Achtung
::101			b BOLDON,"Das GeoDOS-Systemlaufwerk",NULL
::102			b        "kann nicht formatiert werden!",NULL

;*** Infobox: "Laufwerks-ROM laden?"
:V401i4			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Soll das Laufwerks-ROM",NULL
::102			b        "für "
:V401i5			b        "15xx geladen werden ?",NULL

;*** Hinweis: "Laufwerk über GEOS/Configure oder GEOS.Editor ändern!"
:V401i6			w :101, :102, ISet_Info
::101			b BOLDON,"Hinweis: GEOS-Laufwerkstreiber",NULL
::102			b        "muss manuell geladen werden!",NULL
endif

if Sprache = Englisch
;*** Formatierungs-Befehle.
:StdFrmtName		b "Workdisk",NULL,NULL
:DiskImgName		b "DISKIMAGE",NULL
:ExecFormat		w $0012
			b "N:________________,64,DD8"
:ExecFastFrmt		w $0005
			b "M-E",$60,$06
:SwitchTo1541		w $0006
			b "U0>M0",CR
:InitNewDisk		w $0004
			b "I0:",CR
:SwitchTo1571		w $0006
			b "U0>M1",CR

:Format_ID1		b 0,0,0,0
			b ",64 "
:Format_ID2		b ",81 ,DD8,HD8,ED8,DDN,HDN,EDN"

:MaxRenamePart		b $00				;Aktuelle Partition für Rename.
:CurRenamePart		b $00				;Max. Partitionen auf neuer Diskette.

;*** Frage: "RAM-Disk/Partition löschen ?"
:V401g0			w FrmtMode_50, FrmtMode_53, PrintPart
			b NO,YES

;*** Infobox: "Weitere Disketten formatieren ?"
:V401h0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Would you like to format",NULL
::102			b        "another disk ?",NULL

;*** Hinweis: "Keine aktive Partition auf Laufwerk x:"
:V401i0			w V401i1, V401i2, ISet_Achtung
:V401i1			b BOLDON,"No active partition",NULL
:V401i2			b        "on drive    x: !",NULL

;*** Hinweis: "Kann Systemlaufwerk nicht formatieren!"
:V401i3			w :101, :102, ISet_Achtung
::101			b BOLDON,"The GeoDOS system drive",NULL
::102			b        "can not be formatted!",NULL

;*** Infobox: "Laufwerks-ROM laden?"
:V401i4			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Load the matching drive",NULL
::102			b        "ROM for a "
:V401i5			b        "15xx drive ?",NULL

;*** Hinweis: "Laufwerk über GEOS/Configure oder GEOS.Editor ändern!"
:V401i6			w :101, :102, ISet_Info
::101			b BOLDON,"Note: The GEOS disk-driver",NULL
::102			b        "must be loaded manually!",NULL
endif

;*** Infobox: Diskette wird formatiert.
:V401j0			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b PLAINTEXT,BOLDON
:V401j1			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b PLAINTEXT,BOLDON
:V401j2			s 80

;*** Infoxbox: Verzeichnisse einlesen.
if Sprache = Deutsch
:V401j3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnisse auf"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "SD-Karte einlesen..."
			b NULL
endif
if Sprache = Englisch
:V401j3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching SD card"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "for directories..."
			b NULL
endif

;*** Auswahlbox für Formattyp.
:V401k0			b $00
			b $00
			b $00
			b $10
			b $00
:V401k1			w $ffff
			w FileNTab

;*** Auswahlbox für Verzeichnisse.
:V401k2			b $00
			b $00
			b $00
			b $10
:V401k3			b $02
			w V401c3
			w FileNTab

;*** Variablen für RENAME.
:CurDiskName		s 17
:InpDiskName		s 17

if Sprache = Deutsch
:TitelNewName		b PLAINTEXT
			b "Neuer Diskettenname"
			b PLAINTEXT,BOLDON,NULL

:ExecRenPart		w $0006
			b "R-P:________________=________________",NULL

;*** Info: "Diskettenname wird eingelesen..."
:Info_GetName		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenname"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird eingelesen..."
			b NULL

;*** Info: "Schreibe neuen Namen auf Diskette..."
:Info_PutName		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Schreibe neuen Namen"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "auf Diskette..."
			b NULL

;*** Info: "Partitions-Name wird geändert..."
:Info_NewPName		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Name der CMD-Partition"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird geändert..."
			b NULL
endif

if Sprache = Englisch
:TitelNewName		b PLAINTEXT
			b "New diskname"
			b PLAINTEXT,BOLDON,NULL

:ExecRenPart		w $0006
			b "R-P:________________=________________",NULL

;*** Info: "Diskettenname wird eingelesen..."
:Info_GetName		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Load current"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "diskname..."
			b NULL

;*** Info: "Schreibe neuen Namen auf Diskette..."
:Info_PutName		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Write new diskname"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "to disk..."
			b NULL

;*** Info: "Partitions-Name wird geändert..."
:Info_NewPName		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Write new diskname"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "to partition..."
			b NULL
endif

;*** Fast-Format für 1541.
:FastFormat		nop
			CmpBI	$0a,36			;Spur = 36 ?, Ja, Ende erreicht.
			bcc	l050e			;Aktuelle Spur formatieren.
			LoadB	$43,18			;Kopf auf Spur 18 = Directory.
			jmp	$0513

:l050e			jsr	$f24b			;Anzahl Sektoren pro Spur ermitteln.
			sta	$43

:l0513			LoadB	$1b,0			;Sektor-Nr. löschen.
			ldy	#$00 			;"Binär"-Sektor erzeugen.
			ldx	#$00
:l051b			lda	$39 			;Sektorheader-Kennbyte.
			sta	$0300,y
			iny
			iny
			lda	$1b 			;Sektor-Nummer.
			sta	$0300,y
			iny
			lda	$0a 			;Spur-Nummer.
			sta	$0300,y
			iny
			lda	$13 			;Zweites Zeichen der ID.
			sta	$0300,y
			iny
			lda	$12 			;Erstes Zeichen der ID.
			sta	$0300,y
			iny
			lda	#$0f 			;Zwei Header-Abschluß-Bytes.
			sta	$0300,y
			iny
			sta	$0300,y
			iny
			lda	#$00
			eor	$02fa,y			;Prüfsumme über Sektor-,Spur-Nummer und
			eor	$02fb,y			;ID. Ergebniss in Byte $01 der Sektor-
			eor	$02fc,y			;Daten (hinter Sektorheader-Kennbyte).
			eor	$02fd,y
			sta	$02f9,y
			inc	$1b 			;Header für alle Sektoren erzeugen.
			CmpB	$1b,$43			;Alle Sektoren ?
			bcc	l051b			;Nein, Schleife...

			LoadB	$31,3			;Zeiger auf aktuellen Datenpuffer.

			tya				;yReg zwischenspeichern.	
			pha
			txa				;Puffer ab $0700 löschen.
:l0564			sta	$0700,x
			inx
			bne	l0564
			jsr	$fe30			;Header von Binär nach GCR wandeln.
			pla				;yReg wieder herstellen.
			tay
			dey
			jsr	$fde5			;Bytes in Puffer umkopieren.
			jsr	$fdf5			;GCR-Header umkopieren.

			LoadB	$31,7			;Zeiger auf aktuellen Datenpuffer.

			jsr	$f5e9			;Pufferprüfsumme berechnen.
			sta	$3a
			jsr	$f78f			;Pufferinhalt von Binär -> GCR wandeln.

			LoadB	$32,0			;Zeiger auf ersten Sektor-Header.
			jsr	$fe0e			;Gesamte Spur löschen (mit $55).

:l0589			LoadB	$1c01,$ff		;5x SYNC-Byte.
			ldx	#$05
:l0590			bvc	l0590
			clv
			dex
			bne	l0590

			ldx	#$0a			;Sektor-Header schreiben.
			ldy	$32
:l059a			bvc	l059a
			clv
			lda	$0300,y
			sta	$1c01
			iny
			dex
			bne	l059a

			ldx	#$09			;9x Füllbyte.
:l05a9			bvc	l05a9
			clv
			LoadB	$1c01,$55
			dex
			bne	l05a9

			lda	#$ff			;5x SYNC-Byte.
			ldx	#$05
:l05b8			bvc	l05b8
			clv
			sta	$1c01
			dex
			bne	l05b8

;*** Fast-Format (fortsetzung...)
			ldx	#$bb			;Sektor-Inhalt schreiben.
:l05c3			bvc	l05c3
			clv
			lda	$0100,x
			sta	$1c01
			inx
			bne	l05c3
			ldy	#$00
:l05d1			bvc	l05d1
			clv
			lda	($30),y
			sta	$1c01
			iny
			bne	l05d1

			lda	#$55			;8x Füllbyte.
			ldx	#$08
:l05e0			bvc	l05e0
			clv
			sta	$1c01
			dex
			bne	l05e0

			AddVB	10,$32			;Zeiger auf nächsten Sektor-Header.
			dec	$1b 			;Alle Sektoren geschrieben ?
			bne	l0589			;Nein, Schleife...

:l05f4			bvc	l05f4			;Warten bis alle Bytes geschrieben.
			clv
:l05f7			bvc	l05f7
			clv

			jsr	$fe00			;Kopf auf lesen umschalten.

			LoadB	$1f,$c8			;Anzahl Leseversuche für Sektor-Verify.
:l0601			LoadW	$0030,$0300		;Zeiger auf aktuellen Puffer.
			MoveB	$43,$1b			;Sektor-Zähler initialisieren.

:l060d			jsr	$f556			;Warten auf SYNC.

			ldx	#$0a
			ldy	#$00
:l0614			bvc	l0614			;Warten auf Byte von Disk.
			clv
			lda	$1c01
			cmp	($30),y			;Byte mit GCR-Header-Daten vergleichen.
			bne	l062c			;Nein, Schleife...
			iny
			dex	 			;Kompletten GCR-Header vergleichen.
			bne	l0614			;Alle Bytes verifiziert? Nein,Schleife.
			AddVB	10,$30 			;Zeiger auf nächsten Header.
			jmp	$0635			;Sektor-Inhalte prüfen.

:l062c			dec	$1f 			;Nächster Lese-Versuch.
			bne	l0601
			lda	#$06 			;"FORMAT"-Fehler.
			jmp	$fdd3

:l0635			jsr	$f556			;Warten auf SYNC.

			ldy	#$bb 			;Sektor-Inhalte vergleichen.
:l063a			bvc	l063a
			clv
			lda	$1c01
			cmp	$0100,y
			bne	l062c
			iny
			bne	l063a
			ldx	#$fc
:l064a			bvc	l064a
			clv
			lda	$1c01
			cmp	$0700,y
			bne	l062c
			iny
			dex
			bne	l064a

			dec	$1b 			;Nächsten Sektor suchen und
			bne	l060d			;vergleichen.
			jmp	$fd9e			;Spur formatiert, "OK".

;*** Einsprung für Format-Routine.
:l0660			ldy	#$00 			;Disketten-Name und ID übertragen.
:l0662			lda	$06e0,y
			sta	$0200,y
			iny
			cpy	$06df
			bcc	l0662

			lda	$06df			;Länge Disk-Name + ID.
			sta	$0274
			lda	$06de			;Zeiger auf ID.
			sta	$027b

			LoadB	$7f,0			;Laufwerks-Nr. immer '0'.
			jsr	$c100			;LED einschalten.

			ldy	$027b			;ID in ID-Speicher übertragen.
			lda	$0200,y
			sta	$12
			lda	$0201,y
			sta	$13
			jsr	$d307			;Floppy-Kanäle schliesen.

;*** Fast-Format (fortsetzung...)
			LoadB	$1c05,$1a		;Timer setzen.

			LoadB	$00,$c0			;Kopf auf Spur '0' setzen.
:l069a			lda	$00
			bmi	l069a

			ldx	$06dc			;Erste zu formatierende Spur.
:l06a1			stx	$0a			;Nr. der zu formatierenden Spur merken
			lda	#$e0			;und Spur formatieren.
			sta	$02
:l06a7			lda	$02
			bmi	l06a7
			cmp	#$02			;"FORMAT"-Fehler ?
			bcs	l06bb			;Ja, Abbruch.
			inx				;Zeiger auf nächste Spur.
			cpx	$06dd			;Alle Spuren formatiert ?
			bcc	l06a1			;Nein, Schleife...

			jsr	$ee40			;BAM & Directory erzeugen.
			rts				;Ende.
			nop
			nop

:l06bb			ldx	#$02			;Fehler-Meldung erzeugen.
			jmp	$e60a			;und Ende...

			s	28			;Füllbytes.

:l06dc			b	$01			;Erste Spur.
:l06dd			b	$24			;Letzte Spur +1.
:l06de			b	$07			;Zeiger auf ID.
:l06df			b	$09			;Länge Name + ID.

:l06e0			b	"GeoDOS,64"
			s	23

:EndProgrammCode

;*** Speicher für Verzeichnisdaten/SD2IEC.
:TempDataBuf		b	NULL
