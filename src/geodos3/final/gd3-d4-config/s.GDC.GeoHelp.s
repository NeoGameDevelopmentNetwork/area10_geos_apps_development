; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtEdit"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
endif

;*** GEOS-Header.
			n "GD.CONF.GEOHELP"
			c "GDC.GEOHELP V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "HilfeSystem konfigurieren"
endif
if Sprache = Englisch
			h "Configure HelpSystem"
endif

;*** Sprungtabelle.
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts

;*** Menü initialisieren.
:InitMenu		bit	firstBoot		;GEOS-BootUp ?
			bpl	DoAutoBoot		; => Ja, automatisch installieren.

;--- GeoDOS64 V3-Kernal aktiv ?
;GD.CONFIG kann auch von MP3 aus gestartet werden.
			lda	SysName +1		;GeoDOS64-Kernal aktiv ?
			cmp	#"D"			;"GDOS64-V3"
			bne	:1			; => Nein, weiter...
			lda	SysName +7
			cmp	#"V"
			beq	DoAppStart		; => Ja, weiter...

::1			LoadB	RegTMenu_1a,BOX_OPTION_VIEW
			LoadW	RegTMenu_1b,NoHelpActive
			LoadB	RegTMenu_2b,BOX_ICON_VIEW

;*** Menü starten.
:DoAppStart		jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			LoadW	r0,RegisterTab		;Register-Menü installieren.
			jmp	DoRegister

;*** System-Boot.
:DoAutoBoot		lda	SysName +1		;GeoDOS64-Kernal aktiv ?
			cmp	#"D"			;"GDOS64-V3"
			bne	:6			; => Nein, Ende...
			lda	SysName +7
			cmp	#"V"
			bne	:6			; => Nein, Ende...

::1			lda	#$00
			sta	HelpSystemActive	;HilfeSystem deaktivieren.

			lda	BootHelpSysMode		;HilfeSystem aktivieren ?
			bpl	:6			; => Nein, Ende...

			jsr	InstallHelpSys		;GeoHelp nachladen.
			txa				;System installiert ?
			bne	:6			; => Nein, Ende...

			lda	BootHelpSysMode		;HilfeSystem-Status festlegen.
			sta	HelpSystemActive

			lda	BootHelpSysDrv		;Hilfe-Laufwerk definiert ?
			bne	:3			; => Ja, weiter...
			ldx	SystemDevice		;Start-Laufwerk übernehmen.
			lda	RealDrvType -8,x	;Bei CMD-FD/HD/RL Laufwerkstyp, bei
			and	#%11110000		;anderen Laufwerken die Adresse
			beq	:2			;als Hilfe-Laufwerk vordefinieren.
			lda	RealDrvType -8,x
::2			txa
::3			sta	HelpSystemDrive

			lda	BootHelpSysPart		;Hilfe-Partition definiert ?
			bne	:5			; => Ja, weiter...

			lda	HelpSystemDrive
			jsr	CheckDrive		;Hilfe-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden ?
			bne	:4			; => Nein, weiter...
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler ?
			bne	:4			; => Ja, Ende...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:4			; => Ja, Abbruch...

			ldx	curDrive
			lda	drivePartData-8,x	;Hilfe-Partition vorbelegen.
			b $2c
::4			lda	#$00
::5			sta	HelpSystemPart
::6			rts

;*** Laufwerkstyp mit gültiger Partition suchen.
:CheckDrive		sta	:DriveType		;Laufwerkstyp speichrn.
			tax
			and	#%11110000
			beq	:5

			ldx	#$08
::1			lda	driveType   -8,x	;Laufwerk verfügbar ?
			beq	:3			; => Nein, weiter...

			lda	RealDrvType -8,x	;Laufwerkstyp überprüfen.
			cmp	:DriveType		;Stimmt Laufwerksformat ?
			beq	:5			; => Nein, weiter...

::3			inx
			cpx	#$0c			;Alle Laufwerke durchsucht ?
			bcc	:1			; => Nein, weiter...

::4			ldx	#DEV_NOT_FOUND
			rts

::5			txa
			ldx	#NO_ERROR
			rts

::DriveType		b $00

;*** Aktuelle Konfiguration speichern.
:SaveConfig		lda	HelpSystemActive
			sta	BootHelpSysMode
			lda	HelpSystemDrive
			sta	BootHelpSysDrv
			lda	HelpSystemPart
			sta	BootHelpSysPart
			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;******************************************************************************
;*** HilfeSystem-Routinen.
;******************************************************************************
;*** HilfeSystem de-/aktivieren.
:Swap_HelpSystem	lda	HelpSystemActive	;HilfeSystem aktiviert ?
			bpl	:1			; => Nein, weiter...

			jsr	InstallHelpSys		;HilfeSystem nachladen.
			txa				;System installiert ?
			beq	:3			; => Ja, Ende...

::1			lda	HelpSystemBank		;Bereits belegte Speicherbank
			beq	:2			;für Hilfesystem wieder freigeben.
			jsr	FreeBank

::2			lda	#$00			;Hilfesystem kann nicht
			sta	HelpSystemActive	;aktiviert werden.
::3			rts

;*** HilfeSystem nachladen und installieren.
;    (Sektorweise da nicht genügend RAM verfügbar!)
:InstallHelpSys		jsr	GetFreeBankL		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;Speicher frei ?
			beq	:1			; => Ja, weiter...
::0			rts				; => Abbruch.

::1			sta	HelpSystemBank		;Bank-Adresse speichern.
			ldx	#%11000000		;Speicherbank reservieren.
			jsr	AllocateBank

			lda	SystemDevice		;Systemlaufwerk aktivieren und
			jsr	SetDevice		;Diskette öffnen.
			jsr	OpenDisk
			txa				;Diskettenfehler ?
			bne	:0			; => Ja, Abbruch...

			LoadW	r6 ,dataFileName
			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,Class_GeoHelp
			jsr	FindFTypes		;HilfeSystem suchen.
			txa				;Diskettenfehler ?
			bne	:0			; => Ja, Abbruch...

			ldx	#FILE_NOT_FOUND
			lda	r7H			;Datei gefunden ?
			bne	:0			; => Nein, Abbruch...

			LoadW	r6,dataFileName
			jsr	FindFile		;Verzeichnis-Eintrag einlesen.
			txa				;Diskettenfehler ?
			bne	:0			; => Ja, Abbruch...

			lda	dirEntryBuf+1		;Zeiger auf ersten Daten-Sektor.
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H

			lda	#< diskBlkBuf
			sta	r4L
			lda	#> diskBlkBuf
			sta	r4H			;Zeiger auf C64-Adresse.

			lda	#< RH_ADDR_HELPSYS
			sta	r15L
			lda	#> RH_ADDR_HELPSYS
			sta	r15H			;Zeiger auf RAM-Adresse.

::2			jsr	GetBlock		;Sektor von Diskette lesen.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

			LoadW	r0 ,diskBlkBuf +2	;Zeiger für StashRAM definieren.
			MoveW	r15,r1

			ldx	#254			;Anzahl Bytes.
			lda	diskBlkBuf +0
			bne	:3
			ldx	diskBlkBuf +1
			dex
::3			stx	r2L
			ldx	#$00
			stx	r2H

			lda	HelpSystemBank		;Speicherbank festlegen.
			sta	r3L
			jsr	StashRAM		;Sektor in RAM kopieren.

			AddVBW	254,r15			;Zeiger auf RAM korrigieren.

			lda	diskBlkBuf +0		;Alle Sektoren gelesen ?
			beq	:4			; => Ja, Ende...
			sta	r1L
			lda	diskBlkBuf +1
			sta	r1H
			jmp	:2

::4			ldx	#NO_ERROR
::5			rts

;******************************************************************************
;*** HilfeSystem-Routinen.
;******************************************************************************
;*** Hilfe-Laufwerk wechseln.
:Swap_HelpDrive		lda	#$00			;Aktive Partition einlesen und
			ldx	curDevice		;zwischenspeichern. Bei CBM-
			ldy	RealDrvMode -8,x	;Laufwerken Partition = #0 setzen.
			bpl	:1
			jsr	OpenDisk
			lda	#$00
			cpx	#NO_ERROR
			bne	:1
			ldx	curDevice
			lda	drivePartData -8,x
::1			sta	:CurPart

			LoadW	r0,Dlg_SlctPart
			jsr	DoDlgBox		;Partition/Laufwerk wählen.

			lda	sysDBData		;Laufwerk wechseln ?
			bpl	:2			; =>: Nein, weiter...
			and	#%00001111
			pha
			jsr	:11			;Partition auf aktivem Laufwerk
							;wieder zurücksetzen.
			pla
			jsr	SetDevice		;Neues Laufwerk aktivieren und
			jmp	Swap_HelpDrive		;Partition wählen.

::2			cmp	#CANCEL			;"ABBRUCH" gewählt ?
			beq	:11			; => Ja, Ende...

			ldx	curDrive
			lda	RealDrvMode -8,x	;Partitioniertes Laufwerk ?
			bpl	:3			; => Ja, Partition auswerten.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			beq	:4			; => Nein, weiter...

::3			ldx	curDrive		;Aktives Laufwerk und
			lda	#$00			;Keine Partition.
			jmp	:5			; => Ende...

::4			ldx	curDrive		;Partitioniertes Laufwerk.
			lda	drivePartData-8,x	;Laufwerkstyp und Partition
			tay				;übernehmen.
			lda	RealDrvType  -8,x
			tax
			tya

::5			sta	HelpSystemPart		;Partition und Laufwerk
			stx	HelpSystemDrive		;festlegen.

::11			ldx	curDevice		;Partition auf Laufwerk
			lda	RealDrvMode -8,x	;wieder zurücksetzen.
			bpl	:12
			lda	:CurPart
			beq	:12
			sta	r3H
			jsr	OpenPartition
::12			rts

;--- Zwischenspeicher.
::CurPart		b $00

;******************************************************************************
;*** HilfeSystem-Routinen.
;******************************************************************************
;*** Aktive Partition anzeigen.
:PrintCurDrvName	lda	HelpSystemDrive
			bne	:2
			lda	#$08
			sta	HelpSystemDrive
			bne	:2
::1			rts

::2			and	#%11110000
			bne	:PrintDriveCMD
			jmp	:PrintDriveABCD

::PrintDriveCMD		lda	HelpSystemDrive
			jsr	CheckDrive		;Hilfe-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden ?
			bne	:1			; => Nein, weiter...

			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler ?
			bne	:1			; => Ja, Ende...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			lda	HelpSystemPart		;Partitionsdaten einlesen.
			bne	:11
			lda	#$ff
::11			sta	r3H
			LoadW	r4,dirEntryBuf
			jsr	GetPDirEntry
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			LoadW	r11,$0072
			LoadB	r1H,$56

			ldy	#$00			;Laufwerkstyp suchen um
::21			lda	HelpSystemDrive		;Text für Ausgabe zu ermitteln.
			and	#DrvCMD
			cmp	CMDNameTab,y
			beq	:22
			iny
			iny
			iny
			iny
			cpy	#$0c
			bne	:21
			beq	:1

::22			iny				;Laufwerkstyp ausgeben.
			tya
			clc
			adc	#< CMDNameTab
			sta	r0L
			lda	#$00
			adc	#> CMDNameTab
			sta	r0H
			jsr	PutString
			lda	#":"
			jsr	SmallPutChar

			ldy	#$00			;Partitions-Name ausgeben.
::31			tya
			pha
			lda	dirEntryBuf +3,y
			beq	:41
			cmp	#$a0
			beq	:41
			cmp	#$20
			bcc	:32
			jsr	SmallPutChar
::32			pla
			tay
			iny
			cpy	#$10
			bcc	:31
			rts

::41			pla
			rts

;--- GEOS-Laufwerkstyp ausgeben.
::PrintDriveABCD	lda	HelpSystemDrive		;Zeiger auf Laufwerkstext
			sec				;berechnen und ausgeben.
			sbc	#$08
			asl
			asl
			asl
			asl
			clc
			adc	#< DrvNameTab
			sta	r0L
			lda	#$00
			adc	#> DrvNameTab
			sta	r0H
			jmp	PutString

;*** Variablen.
:Class_GeoHelp		b "GD.HELP     V2",0

:DrvNameTab		b "Laufwerk A:    ",0
			b "Laufwerk B:    ",0
			b "Laufwerk C:    ",0
			b "Laufwerk D:    ",0

:CMDNameTab		b DrvFD     ,"FD",0
			b DrvHD     ,"HD",0
			b DrvRAMLink,"RL",0

:NoHelpActive		b $00

;*** Dialogbox: Datei wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART!DBSETDRVICON ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 2				;Anzahl Einträge.

			w RegTName1_1			;Register: "TaskManager".
			w RegTMenu_1

			w RegTName1_2			;Register: "Einstellungen".
			w RegTMenu_2

:RegTName1_1		w Icon_20
			b RegCardIconX_1,$28,Icon_20x,Icon_20y

:RegTName1_2		w Icon_21
			b RegCardIconX_2,$28,Icon_21x,Icon_21y

;*** Daten für Register "HILFESYSTEM".
:RegTMenu_1		b 2

			b BOX_FRAME			;----------------------------------------
				w RegTText_1_01
				w $0000
				b $40,$af
				w $0040,$012f
:RegTMenu_1a		b BOX_OPTION			;----------------------------------------
				w RegTText_1_02
				w Swap_HelpSystem
				b $50
				w $0048
:RegTMenu_1b			w HelpSystemActive
				b %11111111

if Sprache = Deutsch
:RegTText_1_01		b	 "HILFESYSTEM",0
:RegTText_1_02		b	$58,$00,$56, "Hilfesystem installieren"
			b GOTOXY,$48,$00,$86, "Diese Option benötigt 64K des"
			b GOTOXY,$48,$00,$8e, "erweiterten Speichers"
			b GOTOXY,$48,$00,$9e, "Über <F1> ist dann das HilfeSystem"
			b GOTOXY,$48,$00,$a6, "von GeoDOS jederzeit erreichbar.",0
endif
if Sprache = Englisch
:RegTText_1_01		b	 "HELPSYSTEM",0
:RegTText_1_02		b	$58,$00,$56, "Install HelpSystem"
			b GOTOXY,$48,$00,$86, "This option need 64K of your"
			b GOTOXY,$48,$00,$8e, "extended memory"
			b GOTOXY,$48,$00,$9e, "At any time you can hit <F1> to"
			b GOTOXY,$48,$00,$a6, "start the GeoDOS-HelpSystem.",0
endif

;*** Daten für Register "EINSTELLUNGEN".
:RegTMenu_2		b 4

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_01
				w $0000
				b $40,$af
				w $0040,$012f
:RegTMenu_2a		b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_2_02
				w PrintCurDrvName
				b $50,$57
				w $0070,$010f
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $4f,$58
				w $0110,$0118
:RegTMenu_2b		b BOX_ICON			;----------------------------------------
				w $0000
				w Swap_HelpDrive
				b $50
				w $0110
				w RegTIcon1_1_01
				b (RegTMenu_2a - RegTMenu_2 -1)/11 +1

:RegTIcon1_1_01		w Icon_10
			b $00,$00,$01,$08
			b $ff

if Sprache = Deutsch
:RegTText_2_01		b	 "HILFETEXT-LAUFWERK",0
:RegTText_2_02		b	$48,$00,$56, "Typ:"
			b GOTOXY,$48,$00,$7e, "Auf diesem Laufwerk wird nach den"
			b GOTOXY,$48,$00,$86, "benötigten Hilfetexten gesucht."
			b GOTOXY,$48,$00,$96, "Bei Standard-Laufwerken wird die"
			b GOTOXY,$48,$00,$9e, "aktuelle Diskette verwendet, bei CMD"
			b GOTOXY,$48,$00,$a6, "Laufwerken die angegebene Partition."
			b NULL
endif
if Sprache = Englisch
:RegTText_2_01		b	 "HELPFILE-DRIVE",0
:RegTText_2_02		b	$48,$00,$56, "Type:"
			b GOTOXY,$48,$00,$7e, "GeoDOS will search onb this drive"
			b GOTOXY,$48,$00,$86, "for the needed help-dokuments."
			b GOTOXY,$48,$00,$96, "When using standard-diskdrives the"
			b GOTOXY,$48,$00,$9e, "current disk is used. CMD-drives"
			b GOTOXY,$48,$00,$a6, "will use the selected partition.",0
endif

;*** Icons.
:Icon_10
<MISSING_IMAGE_DATA>
:Icon_10x		= .x
:Icon_10y		= .y

if Sprache = Deutsch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y
endif

if Sprache = Englisch
:Icon_20
<MISSING_IMAGE_DATA>
:Icon_20x		= .x
:Icon_20y		= .y
endif

if Sprache = Deutsch
:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y
endif

if Sprache = Englisch
:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RegCardIconX_1		= $07
:RegCardIconX_2		= RegCardIconX_1 + Icon_20x

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
