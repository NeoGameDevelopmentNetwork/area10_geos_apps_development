; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** A C H T U N G !!!
;    Die Adressen ":a0" bis ":a9" werden als Sprungtabelle für die
;    Laufwerkstreiber verwendet. Diese Tabelle wird beim Programmstart
;    definiert und darf während der GEOS.Editor aktiv ist, von keiner
;    Anwendung/Laufwerkstreiber verändert werden.
;    Desweiteren wird beim Tauschen von Geräteadressen für jedes Laufwerk im
;    Bereich #8 bis #19 eine freie Adresse im Bereich #20 bis #29 benötigt.
;******************************************************************************

			n "mod.GE_#100"
			t "G3_SymMacExt"

			f AUTO_EXEC

			t "src.Edit.Class"

if Flag64_128 = TRUE_C64
			a "Markus Kanet"
			z $80
endif

if Flag64_128 = TRUE_C128
			a "M.Kanet/W.Grimm"
			z $40
endif

			o BASE_EDITOR_MAIN
			p MainInit

			i
<MISSING_IMAGE_DATA>

if Flag64_128 = TRUE_C128
;*** Max. Größe der SD-Tools.
;Die SD-Tools sind beim C128 in Vlir#3
;ausgelagert und werden nach dem Start
;von GEOS.Editor nach Bank#0 kopiert.
;Die Größe hier wird für ReadRecord und
;MoveBData verwendet und ist auf die
;max. Größe des Datensatzes anzupassen.
;
.SizeSDTools		= $0500
.Base1SDTools		= BASE_EDITOR_DATA - SizeSDTools
;
;--- Hinweis:
;Von $2000-$7fff befindet sich in
;Bank#0 der SwapFile-Bereich.
;
;.Base0SDTools		= $4000 - SizeSDTools
;
;--- Hinweis:
;Der Bereich von $8000-$abff scheint
;frei für Applications zu sein.
;GeoPaint legt hier z.B. Daten ab.
;Daher wurde ":Base0SDTools" aus dem
;Bereich für das SwapFile testweise
;nach $8000 verschoben.
;
.Base0SDTools		= $8000
;
endif

if .p
;*** Treiber-Informationen.
.DiskDataRAM_A		= BASE_EDITOR_DATA
.DiskDataRAM_S		= BASE_EDITOR_DATA +256
.VLIR_Types		= BASE_EDITOR_DATA +256 +256
.VLIR_Entry		= BASE_EDITOR_DATA +256 +256 +64
.VLIR_Names		= BASE_EDITOR_DATA +256 +256 +64 +64*2

;*** Variablen für Speicherbank-Belegung.
.BankCode_GEOS		= %10000000
.BankCode_Disk		= %01000000
.BankCode_Task		= %00100000
.BankCode_Spool		= %00010000
.BankCode_Block		= %00001000
.BankCode_Free		= %00000000

;*** Variablen für Hintergrundbild-Routine.
:ByteCopyBuf		= BASE_DDRV_INIT		;s $08
:GrfxData		= BASE_DDRV_INIT +8		;s (640 * 2) + 8 + (80 * 2)
endif

;*** Die folgenden Daten müssen am Beginn des Programms stehen.
;    Sie werden über den Punkt "Konfiguration speichern" im Hauptmenü
;    direkt im Programm auf Diskette geändert.
.BootVarStart

.BootConfig		b $00,$00,$00,$00
.BootPartRL		b $00,$00,$00,$00
.BootPartRL_I		b $00,$00,$00,$00
.BootPartType		b $00,$00,$00,$00
.BootRamBase		b $00,$00,$00,$00

;*** Flag für "GEOS.Editor installiert".
.BootInstalled		b $00

;*** MP3-Statusvariablen.
;    Bit#7: 0=Kein REU-MoveData
;    Bit#6: 1=Laufwerkstreiber in REU
;    Bit#5: 1=ReBoot-Daten in REU
;    Bit#4: 1=ReBoot-Kernal in REU
;    Bit#3: 1=Hintergrundbild aktiv
.BootRAM_Flag		b %01001000

.BootScrSaver		b %01000000
.BootScrSvCnt		b $06
.BootSaverName		s 17
.BootCRSR_Repeat	b $03
.BootSpeed		b $00
.BootOptimize		b $00
.BootPrntMode		b $00
.BootColsMode		b $80
.BootMenuStatus		b %11100000
.BootMLineMode		b $00
.BootTaskMan		b $00				;$00 = TaskManager aktivieren.
.BootSpooler		b $80				;$80 = Spooler aktivieren.
.BootSpoolCount		b $03				;Aktivierungszeit Spooler.
.BootSpoolSize		b $00				;Größe Spooler beim ersten Start automatisch setzen!
.BootBankBlocked	s RAM_MAX_SIZE
.BootRTCdrive		b $ff				;$fe=-,$10=FD,$20=HD,$30=RL,$FE=SmartMouse,$FF=Auto
.BootLoadDkDv		b $00

;*** Variablen für TaskManager.
.TASK_BANK_ADDR		b $00				;TaskManager-Systembank.
			s $08				;Bank für Task #1 bis Task #8.
.TASK_BANK_USED		b $00				;TaskManager-Systembank belegen.
			s $08				;Flag für Bank #1 bis #8 belegt.
.TASK_COUNT		b $00				;Anzahl verfügbarer Tasks.

if Flag64_128 = TRUE_C128
;*** Bank-Adressen für Tasks VDC Verwaltung
.TASK_VDC_ADDR		b $00				;TaskManager-Systembank für VDC
			s $08				;Bank für Task #1 bis Task #8.
.TASK_BANK0_ADDR	b $00				;TaskManager-Systembank für Bank 0
			s $08				;Bank für Task #1 bis Task #8.
endif

;*** Name der Hintergrundgrafik.
if Flag64_128 = TRUE_C64
.BootGrfxFile		b "GEOSMP64.PIC",NULL
endif
if Flag64_128 = TRUE_C128
.BootGrfxFile		b "GEOSMP128.PIC",NULL
endif
;*** Sicherstellen das genügend Speicher verfügbar
;    ist für lange Dateinamen.
			e BootGrfxFile+17

;*** Name des Druckertreibers.
.BootPrntName		s 17
if Flag64_128 = TRUE_C64
.BootGCalcFix		b $80
endif

;*** Name des Eingabetreibers.
.BootInptName		s 17

;*** Option QWERTZ-Tastatur (Nur MP3/Deutsch)
if Sprache = Deutsch
.BootQWERTZ		b $ff
endif

;*** Modus für HD-Kabel.
;--- Ergänzung: 22.12.18/M.Kanet
;Falls eine HD nur über den IEC-Bus angeschlossen ist kann es unter bestimmten
;Umständen (z.B. C128) zu Problemen bei der Hardware-Erkennung kommen.
;Parallel-Kabel standardmäßig deaktivieren.
;.BootUseFastPP		b $80
.BootUseFastPP		b $00
.BootVarEnd

;*** Programm initialisieren.
:MainInit

if Flag64_128 = TRUE_C128
;--- Ergänzung: 11.09.18/M.Kanet
;Unter GEOS128v2 wird beim Umschalten mit DESKTOPv2 von 40Z auf 80Z das
;DB_DblBit nicht passend zu graphMode gesetzt. Dadurch werden Icons in
;Dialogboxen nicht automatisch an den 80Z-Modus angepasst.
			lda	graphMode		;Grafikmodus einlesen.
			beq	:40			; ->40 Zeichen.
			lda	#%10000000		;80Z-Modus setzen und neuen
			sta	graphMode		;neuen Modus aktivieren.
			jsr	SetNewMode

			lda	#2
			jsr	VDC_ModeInit		;VDC-Farbmodus aktivieren

			LoadW	r3,0
			LoadW	r4,639
			LoadB	r2L,0
			LoadB	r2H,199
			lda	#$00
			jsr	ColorRectangle		;GEOS 2.0 DirectColor-Routine !

			lda	graphMode		;DB_DblBit passend zu 40/80Z setzen.
::40			sta	DB_DblBit
endif

			lda	firstBoot		;Boot-Flag zwischenspeichern.
			sta	firstBootCopy

			lda	BootInstalled		;Erst-Start erkennen. Flag
			sta	Flag_ME1stBoot		;ist notwendig für die Laufwerks-
			ldx	#$ff			;erkennung, TaskMan- und Spooler-
			stx	BootInstalled		;installation. Wird die aktuelle
							;Konfiguration gespeichert, ist das
							;Flag für immer $FF.
			tax				;Erstinstallation/Update ?
			bne	:51			; => Nein, weiter...
			sta	BootPrntName		;Ersten Drucker/Eingabetreiber
			sta	BootInptName		;auf Diskette suchen.

;--- Sicherstellen das "ramExpBase" nicht größer ist als
;    Bytes in "RamBankInUse" reserviert sind!!!
::51			lda	#RAM_MAX_SIZE
			cmp	ramExpSize
			bcs	:52
			sta	ramExpSize

;--- Start-Laufwerkstyp zwischenspeichern.
::52			ldy	curDrive		;Start-Laufwerk speichern.
			sty	SysDrive
			lda	driveType   -8,y	;Start-Laufwerkstyp speichern.
			sta	SysDrvType
			lda	RealDrvType -8,y	;Start-Laufwerkstyp speichern.
			sta	SysRealDrvType

			jsr	ChkBootConf		;Startlaufwerk korrigieren.
			jsr	StashRAM_DkDrv		;Laufwerkstreiber speichern.

if Flag64_128 = TRUE_C128
;--- Ergänzung: 05.03.19/M.Kanet
;Bis zur Version r4 wurde der SD-Code am C128 als VLIR-Modul nachgeladen.
;Wenn das Systemlaufwerk gewechselt wurde führt das aber zu einem Fehler da
;dann der Code nicht mehr nachgeladen werden kann.
;Mit der Version r5 wird das VLIR-Modul nachgeladen und in Bank#0
;gespeichert und bei Bedarf nach Bank#1 eingelesen.
;Die folgende Routine installiert die SD-Tools in Bank#0.
			jsr	LoadSDTools
endif

;--- Vorraussetzungen für GEOS.Editor testen.
			jsr	FindMegaPatch		;MegaPatch verfügbar ?
			jsr	ChkTaskMan		;TaskManager aktiv ?

;--- Reservierte Speicherbänke vorbelegen.
			bit	firstBoot		;GEOS-BootUp ?
			bmi	:53			; => Nein, weiter...
			jsr	Stash_AutoBoot		;AutoBoot-Routine speichern.

;--- Hintergrundbild einlesen.
::53			jsr	LdBackScrn		;Hintergrundbild einlesen und

;******************************************************************************
;*** Initialisierungsroutine für Erstinstallation und Boot-Vorgang.
;******************************************************************************

			t "-G3_Editor.Init"

;*** Konfiguration überprüfen.
;    Ist die Konfiguration ungültig, dann wird das GEOS.Editor-Menü
;    gestartet und der Anwender kann die Konfiguration korrigieren.
.ExitToDeskTop		jsr	CheckDrvConfig
			txa
			beq	:52
::51			jmp	Err_IllegalConf		;Konfiguration ungültig.

::52			jsr	CountDrives		;Laufwerke zählen.

			lda	numDrives		;Laufwerk A: installiert ?
			beq	:51			; => Nein, Fehler ausgeben.

;*** Boot-Flag zurücksetzen.
.PrepareExitDT		lda	firstBootCopy		;Boot-Flag zurücksetzen.
			sta	firstBoot		;War Konfiguration während des Boot-
							;vorganges ungültig, wird das Menü
							;geladen und ":firstBoot" gelöscht.

;--- Konfiguration ist gültig, Boot-Laufwerk wieder aktivieren.
::51			jsr	SetSystemDevice		;Startlaufwerk aktivieren.

;--- RAM-Bänke für TaskManager und Spooler freigeben.
::52			jsr	ClrBank_TaskMan		;TaskManager-Speicher freigeben.
			jsr	ClrBank_Spooler		;TaskManager-Speicher freigeben.

;--- TaskManager installieren.
:Install_TaskMan	jsr	InitTaskManager		;TaskManager installieren.

;--- Spooler installieren.
:Install_Spooler	jsr	InitPrntSpooler

;--- Bank-Tabelle an GEOS übergeben.
:Install_RAM		jsr	BankUsed_2GEOS		;Belegtes RAM an GEOS übergeben.

;--- GEOS.Editor beenden.
:Install_End		jsr	StdClrScrn		;Bildschirm löschen.

			bit	firstBoot		;GEOS-BootUp ?
			bmi	Update_Kernel		; => Nein, weiter...

;******************************************************************************
;Beim GEOS-BootUp wird das aktuelle Kernel erst am Ende des Bootvorgangs von
;der AutoBoot-Routine in der REU gespeichert.
;Wird der Editor als Applikation gestartet, dann muß am Ende des Editors das
;Kernel in der REU gespeichert werden, da sonst änderungen beim RBOOT nicht
;berücksichtigt werden!
;******************************************************************************
			jsr	Fetch_AutoBoot		;AutoBoot-Routine einlesen.
			jmp	EnterDeskTop		;Zurück zum DeskTop/Boot-Routine.

;--- Ende, zum DeskTop zurück.
:Update_Kernel		jsr	CopyKernel2REU		;Kernal in REU kopieren.
			jmp	EnterDeskTop		;Zurück zum DeskTop/Boot-Routine.

;*** Laufwerkskonfiguration überprüfen.
.CheckDrvConfig		ldy	#11
::51			lda	driveType   -8,y
			bne	:53
			dey
			cpy	#8
			bcs	:51
::52			ldx	#$ff
			rts

::53			lda	driveType   -8,y
			beq	:52
			dey
			cpy	#8
			bcs	:53
			ldx	#$00
			rts

;******************************************************************************
;*** Kernel in REU kopieren.
;******************************************************************************
			t "-G3_Kernel2REU"
;******************************************************************************

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** Hintergrundgrafik darstellen.
;    Boot-Vorgang :	Grafik von Diskette nachladen.
;    Programmstart:	Grafik aktiv ? Ja  => Grafik aus RAM einlesen.
;				               Nein=> Füllmuster ausgeben.
:LdBackScrn		bit	firstBoot		;GEOS-BootUp ?
			bmi	LdBootScrn		; => Nein, weiter...

			lda	BootRAM_Flag		;Statusbyte einlesen.
			and	#%00001000		;Hintergrundbild anzeigen ?
			bne	:1			; => Ja, weiter...
;--- Ergänzung: 29.07.18/M.Kanet
;Wird kein Hintergrundbild verwendet sind die Farben im 80Z-Modus des
;C128 zu Beginn nicht initialisiert.
;In diesem Fall direkt auf 80Z. umschalten und den Bildschirm löschen.
if Flag64_128 = TRUE_C128
			lda	#$80			;Auf 80Z. umschalten.
			sta	graphMode
			jsr	SetNewMode
			lda	#$02			;VDC initialisieren.
			jsr	VDC_ModeInit
endif
			jmp	StdClrScrn		;Bildschirm löschen.
::1			jmp	LdScrnFrmDisk		;Hintergrundbild von Disk einlesen.

;*** Hintergrundgrafik aus RAM / Füllmuster darstellen.
.LdBootScrn		lda	sysRAMFlg		;Statusbyte einlesen.
			and	#%00001000		;Hintergrundbild laden ?
			beq	StdClrScrn		; => Nein, weiter...

			lda	#ST_WR_FORE		;Nur Vordergrund-Bildschirm.
			sta	dispBufferOn
			jmp	GetBackScreen		;Hintergrundbild von Ram einlesen.

;*** Bildschirm (Farbe/Grafik) löschen.
.StdClrScrn		lda	screencolors		;Farben löschen.

if Flag64_128 = TRUE_C128
			bit	graphMode		;Welcher Grafikmodus ?
			bpl	:40			; => 40-Zeichen.
			lda	scr80colors
::40
endif
			jsr	i_UserColor
			b	$00 ! DOUBLE_B,$00,$28 ! DOUBLE_B,$19

			lda	BackScrPattern		;Bildschirm löschen.
			jsr	SetPattern

;*** Bildschirm (nur Grafik) löschen.
.StdClrGrfx		lda	#ST_WR_FORE		;Nur Vordergrundgrafik.
			sta	dispBufferOn
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000 ! DOUBLE_W,$013f ! DOUBLE_W ! ADD1_W
			rts

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** Hintergrundbild einlesen.
;    Name muß in ":BootGrfxFile" übergeben werden!
.LdScrnFrmDisk		lda	BootGrfxFile		;Name definiert ?
			beq	:1			; => Nein, kein Startbild.

			LoadW	r6,BootGrfxFile
			jsr	FindFile		;Startbild auf Diskette suchen.
			txa				;Diskettenfehler ?
			beq	:2			; => Nein, weiter...
::1			jmp	NoBackScrn		; => Ja, kein Startbild.

::2			php				;Hintergrundfarbe löschen.
			sei

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
endif

			lda	$d020
			sta	r0L
			lsr	r0L
			rol
			lsr	r0L
			rol
			lsr	r0L
			rol
			lsr	r0L
			rol

if Flag64_128 = TRUE_C64
			stx	CPU_DATA
endif

			plp

			jsr	i_UserColor
			b	$00 ! DOUBLE_B
			b	$00
			b	$28 ! DOUBLE_B
			b	$19

			jsr	ViewPaintFile		;Hintergrundbild anzeigen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, kein Startbild.

if Flag64_128 = TRUE_C128
			jsr	xGetBackScreenVDC
endif

;*** Hintergrundgrafik speichern.
;    Grafik wird immer aus der REU eingelesen! Ist keine "Grafik" aktiv,
;    wird der Hintergrund durch ein Füllmuster definiert und diese Grafik
;    als Hintergrundgrafik gespeichert.
:SvBackScrn		lda	MP3_64K_SYSTEM		;Zeiger auf MP3-Systembank.
			sta	r3L

			LoadW	r0,SCREEN_BASE
			LoadW	r1,R2_ADDR_BS_GRAFX
			LoadW	r2,R2_SIZE_BS_GRAFX
			jsr	StashRAM		;Grafik speichern.
			LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2_ADDR_BS_COLOR
			LoadW	r2,R2_SIZE_BS_COLOR
			jsr	StashRAM

			lda	BootRAM_Flag
			ora	#%00001000
			sta	BootRAM_Flag
			lda	sysRAMFlg		;Achtung! BootRAM_Flag und
			ora	#%00001000		;sysRAM_Flag getrennt bearbeiten,
			sta	sysRAMFlg		;da diese Routine auch im laufenden
			sta	sysFlgCopy		;GEOS-Betrieb aufgerufen wird!
			rts

;*** Kein Startbild, Hintergrund löschen.
:NoBackScrn		lda	BootRAM_Flag		;Startbild nicht gefunden,
			and	#%11110111		;Kein Hintergrundbild verwenden.
			sta	BootRAM_Flag
			lda	sysRAMFlg		;Achtung! BootRAM_Flag und
			and	#%11110111		;sysRAM_Flag getrennt bearbeiten,
			sta	sysRAMFlg		;da diese Routine auch im laufenden
			sta	sysFlgCopy		;GEOS-Betrieb aufgerufen wird!
			jmp	StdClrScrn

;*** Neue Datei anzeigen.
:ViewPaintFile		LoadW	r0,BootGrfxFile
			jsr	OpenRecordFile
			txa
			bne	:53

			LoadW	r14,SCREEN_BASE
			LoadW	r15,COLOR_MATRIX

			lda	#$00
::51			sta	a9H
			jsr	Get80Cards
			jsr	Prnt_Grfx_Cols
			inc	a9H
			lda	a9H
			cmp	usedRecords
			bcs	:52
			cmp	#13
			bcc	:51
::52			ldx	#$00
::53			txa
			pha
			jsr	CloseRecordFile
			pla
			tax
			rts

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** Grafikdaten ausgeben.
:Prnt_Grfx_Cols		lda	#<GrfxData +   0
			ldx	#>GrfxData +   0
			jsr	MoveGrfx
			lda	#<GrfxData +1288
			ldx	#>GrfxData +1288
			jsr	MoveCols

			lda	a9H			;12*2 +1 Zeilen.
			cmp	#12
			bcs	:51

			lda	#<GrfxData + 640
			ldx	#>GrfxData + 640
			jsr	MoveGrfx
			lda	#<GrfxData +1368
			ldx	#>GrfxData +1368
			jmp	MoveCols

::51			rts

;*** Grafikdaten in Bildschirm kopieren.
:MoveGrfx		sta	r0L
			stx	r0H
			MoveW	r14,r1
			AddVW	320,r14
			LoadW	r2 ,$0140
			jmp	MoveData

;*** Grafikdaten in Bildschirm kopieren.
:MoveCols		sta	r0L
			stx	r0H
			MoveW	r15,r1
			AddVW	40 ,r15
			LoadW	r2 ,$0028
			jmp	MoveData

;*** Eine Grafikzeile (80 Cards/8 Pixel hoch) einlesen.
:Get80Cards		jsr	PointRecord
			txa
			bne	NoGrfxData
			tya
			bne	LoadVLIR_Data

:NoGrfxData		jsr	i_FillRam
			w	1280
			w	GrfxData +   0
			b	$00
			jsr	i_FillRam
			w	160
			w	GrfxData +1288
			b	$bf
			rts

;*** Grafikbytes aus Datensatz einlesen.
:LoadVLIR_Data		LoadW	r4,diskBlkBuf		;Zeiger auf Diskettenspeicher.
			jsr	GetBlock		;Ersten Sektor des aktuellen
			txa				;Datensatzes einlesen. Fehler ?
			bne	NoGrfxData		;Nein, weiter...

			LoadW	r0 ,GrfxData		;Zeiger auf Grafikdatenspeicher.

			ldx	#$01			;Zeiger auf erstes Byte in Datei.
			stx	r5H
:GetNxDataByte		jsr	GetNxByte		;Nächstes Byte einlesen.
			sta	r2H			;Byte zwischenspeichern.

			ldy	#$00
			bit	r2H			;Gepackte Daten ?
			bmi	GetPackedBytes		;Ja, weiter...

			lda	r2H
			and	#$3f			;Anzahl Bytes ermitteln.
			beq	EndOfData		;$00 = Keine Daten.
			sta	r2H			;Anzahl Bytes merken.
			bvs	Repeat8Byte		;Bit #6 = 1, 8-Byte-Packformat.

::51			jsr	GetNxByte		;Byte einlesen und in Grafikdaten-
			sta	(r0L),y			;speicher kopieren.
			iny
			cpy	r2H			;Alle Bytes gelesen ?
			bne	:51			;Nein, weiter...

;*** Zeiger auf Grafikdatenspeicher korrigieren.
:SetNewMemPos		tya				;Zeiger auf Grafikdatenspeicher
			clc				;korrigieren.
			adc	r0L
			sta	r0L
			bcc	GetNxDataByte
			inc	r0H
			bne	GetNxDataByte		;Nächstes Byte einlesen.
:EndOfData		rts

;******************************************************************************
;*** Hintergrundbild laden/darstellen.
;******************************************************************************
;*** 8-Byte-Daten wiederholen.
:Repeat8Byte		jsr	GetNxByte		;Nächstes Byte aus Datensatz
			sta	ByteCopyBuf,y		;einlesen und in Zwischenspeicher.
			iny				;Zeiger auf nächstes Byte.
			cpy	#$08			;8 Byte eingelesen ?
			bne	Repeat8Byte		;Nein, weiter...

			ldx	#$00
::51			ldy	#$07			;8 Byte in Grafikdatenspeicher.
::52			lda	ByteCopyBuf,y
			sta	(r0L),y
			dey
			bpl	:52
			lda	r0L			;Zeiger auf Grafikdatenspeicher
			clc				;korrigieren.
			adc	#$08
			sta	r0L
			bcc	:53
			inc	r0H
::53			inx				;Anzahl Wiederholungen +1.
			cpx	r2H			;Wiederholungen beendet ?
			bne	:51			;Nein, weiter...
			beq	GetNxDataByte		;Weiter mit nächstem Byte.

;*** Gepackte Daten einlesen.
:GetPackedBytes		lda	r2H			;Anzahl gepackte Daten berechnen.
			and	#$7f
			beq	EndOfData		;$00 = Keine Daten, Ende...
			sta	r2H			;Anzahl Bytes merken.
			jsr	GetNxByte		;Datenbyte einlesen.

			ldy	r2H
			dey				;Byte in Grafikdatenspeicher
::51			sta	(r0L),y			;kopieren (Anzahl in ":r2H")
			dey
			bpl	:51

			ldy	r2H			;Zeiger auf Grafikdatenspeicher
			bne	SetNewMemPos		;korrigieren.

;*** Nächstes Byte aus Paint-Datei einlesen.
:GetNxByte		ldx	r5H
			inx
			bne	RdBytFromSek
			lda	r1L
			bne	GetNxSektor
:GetByteError		pla
			pla
			rts

;*** Nächsten Sektor aus Paint-Datensatz einlesen.
:GetNxSektor		lda	diskBlkBuf +$00
			sta	r1L
			lda	diskBlkBuf +$01
			sta	r1H
			sty	a9L
			jsr	GetBlock		;Sektor einlesen.
			ldy	a9L
			txa				;Diskettenfehler ?
			beq	:51			;Ja, Abbruch...
			pla
			pla
			jmp	NoBackScrn

::51			ldx	#$02			;Zeiger auf erstes Byte in Sektor.

;*** Nächstes Byte aus Sektor einlesen.
:RdBytFromSek		lda	r1L
			bne	:51
			cpx	r1H
			bcc	:51
			beq	:51
			bne	GetByteError
::51			lda	diskBlkBuf +$00,x	;Byte aus Sektor einlesen.
			stx	r5H			;Bytezeiger speichern.
			rts

;******************************************************************************
;*** Startlaufwerk aktivieren / ":sysRAMFlg" korrigieren.
;******************************************************************************
;*** Start-Laufwerk aktivieren.
;    Übergabe:		-
;    Rückgabe:		xReg	= Fehlermeldung.
.SetSystemDevice	jsr	ExitTurbo		;Turbo-DOS abschalten.

			ldx	#DEV_NOT_FOUND
			ldy	SysDrive
			lda	driveType -8,y		;Ist Laufwerk verfügbar ?
			beq	:51			; => Nein, Abbruch...

			sty	curDevice		;Variablen aktualisieren.
			sty	curDrive
			sta	curType

			jsr	FetchRAM_DkDrv		;Treiber aus REU nach RAM.

			ldx	#NO_ERROR		;OK!
::51			rts

;*** Laufwerkstreiber "in REU kopieren" / "aus REU einlesen."
.FetchRAM_DkDrv		ldy	#%10010001
			b $2c
.StashRAM_DkDrv		ldy	#%10010000
			lda	#< DISK_BASE
			sta	r0L
			lda	#> DISK_BASE
			sta	r0H
			ldx	SysDrive
			lda	DskDrvBaseL -8,x
			sta	r1L
			lda	DskDrvBaseH -8,x
			sta	r1H
			LoadW	r2 ,DISK_DRIVER_SIZE
			LoadB	r3L,$00
			jmp	DoRAMOp

;*** Laufwerkstreiber abschalten.
:Set_NoDskDvInRAM	lda	BootRAM_Flag		;SystemFlag einlesen und
			and	#%10101000		;Bit "Laufwerkstreiber in RAM"
			sta	sysRAMFlg		;löschen und zwischenspeichern.
			sta	sysFlgCopy
			rts

;*** Laufwerkstreiber aktivieren.
:Set_DskDvInRAM		lda	sysRAMFlg		;SystemFlag einlesen und
			ora	#%01000000		;Bit "Laufwerkstreiber in RAM"
			sta	sysRAMFlg		;setzen und zwischenspeichern.
			sta	sysFlgCopy
			sta	BootRAM_Flag
			rts

;*** AutoBoot-Routine laden/speichern.
:Fetch_AutoBoot		ldy	#%10010001
			b $2c
:Stash_AutoBoot		ldy	#%10010000
			LoadW	r0 ,BASE_AUTO_BOOT
			LoadW	r1 ,R3_ADDR_AUTOBBUF
			LoadW	r2 ,SIZE_AUTO_BOOT
			lda	MP3_64K_DATA
			sta	r3L
			jmp	DoRAMOp

;******************************************************************************
;*** Startlaufwerk aktivieren / ":sysRAMFlg" korrigieren.
;******************************************************************************
;*** Laufwerkstreiber-Datei suchen.
.FindDiskDrvFile	bit	firstBoot		;GEOS-BootUp ?
			bpl	:51			; => Ja, Laufwerkstreiber immer
							;    vom Startlaufwerk laden.

			ldx	DiskFileDrive		;Laufwerk definiert ?
			beq	:51			; => Nein, weiter...
			lda	driveType -8,x		;Laufwerk noch verfügbar ?
			beq	:51			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Wurde Laufwerk aktiviert ?
			beq	:52			; => Ja, weiter...

::51			jsr	SetSystemDevice		;Startlaufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	FindDkDvAllDrv		; => Ja, anderes Laufwerk wählen.

::52			jsr	LookForDkDvFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	FindDkDvAllDrv		; => Nein, anderes Laufwerk wählen.

			lda	curDrive		;Laufwerk mit Treiberdatei
			sta	DiskFileDrive		;zwischenspeichern.
			rts

;*** Laufwerk mit Treiberdatei suchen.
.FindDkDvAllDrv		ldy	#8			;Zeiger auf erstes Laufwerk.
::51			lda	driveType -8,y		;Ist RAM-Laufwerk definiert ?
			bpl	:52			; => Nein, weiter...
			jsr	:61			;Treiber-Datei suchen.
			txa				;Datei gefunden ?
			beq	:55			; => Ja, Ende...
::52			iny				;Zeiger auf nächstes Laufwerk.
			cpy	#12			;Alle Laufwerke durchsucht ?
			bcc	:51			; => Nein, weiter...

			ldy	#8			;Zeiger auf erstes Laufwerk.
::53			lda	driveType -8,y		;Ist Disk-Laufwerk definiert ?
			beq	:54			; => Nein, weiter...
			bmi	:54			; => RAM-Laufwerk, weiter...
			jsr	:61			;Treiber-Datei suchen.
			txa				;Datei gefunden ?
			beq	:55			; => Ja, Ende...
::54			iny				;Zeiger auf nächstes Laufwerk.
			cpy	#12			;Alle Laufwerke durchsucht ?
			bcc	:53			; => Nein, weiter...

			ldx	#FILE_NOT_FOUND		;Fehler: "FILE NOT FOUND!".
			rts

::55			lda	curDrive		;Laufwerk mit Treiberdatei
			sta	DiskFileDrive		;zwischenspeichern.
			rts

;--- Treiberdatei suchen.
;    Übergabe:		yReg = Laufwerk.
::61			tya
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:62			; => Ja, Abbruch...
			jsr	LookForDkDvFile		;Treiberdatei suchen.
::62			ldy	curDrive
			rts

;*** Treiberdatei auf aktuellem Laufwerk suchen.
.LookForDkDvFile	LoadW	r6 ,DiskDriver_FName
			LoadB	r7L,SYSTEM
			LoadB	r7H,1
			LoadW	r10,DiskDriver_Class
			jsr	FindFTypes		;Treiber-Datei suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			ldx	r7H			;Datei gefunden ?
			beq	:52			; => Nein, weiter...
::51			ldx	#FILE_NOT_FOUND		;Fehler: "FILE NOT FOUND!".
::52			rts

;******************************************************************************
;*** Laufwerkstreiber einlesen.
;******************************************************************************
.LoadDiskDrivers	bit	firstBoot		;GEOS-BootUp ?
			bmi	:52			; => Nein, weiter...
			ldx	BootLoadDkDv		;Treiber in RAM kopieren ?
			beq	:51			; => Nein, weiter...
			ldx	MP3_64K_DATA		;Speicherbank für Laufwerks-
			dex				;treiber berechnen.
			dex
::51			stx	MP3_64K_DISK		;Flag setzen: "Treiber in RAM".

::52			lda	MP3_64K_DISK		;"Treiber von Diskette laden ?"
			beq	:53			; => Ja, weiter...
			lda	#$ff			;Flag in Bootkonfiguration
::53			sta	BootLoadDkDv		;übertragen.

			jsr	InstallJumpTab		;Sprungtabelle für die Laufwerks-

			lda	MP3_64K_DISK		;"Treiber von Diskette laden ?"
			beq	InitDkDrv_Disk		; => Ja, weiter...

			bit	firstBoot		;GEOS-BootUp ?
			bpl	InitDkDrv_RAM		; => Ja, weiter...
			lda	Flag_ME1stBoot		;GEOS-Erststart ?
			beq	InitDkDrv_RAM		; => Ja, weiter...

			jsr	SetDiskDatReg		;Treiber bereits im RAM. Treiber-
			jmp	FetchRAM		;Informationen einlesen.

;*** Laufwerkstreiber im RAM installieren.
.InitDkDrv_RAM		jsr	InitDkDrv_Disk		;Treiberinformationen einlesen und
			jmp	UpdateDiskDriver	;Treiber in RAM kopieren.

;*** Laufwerkstreiber von Diskette installieren.
.InitDkDrv_Disk		jsr	FindDiskDrvFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			beq	LoadDskDrvInfo		; => Ja, weiter...
			rts

;*** Informationen für Laufwerkstreiber einlesen.
:LoadDskDrvInfo		LoadW	r0 ,DiskDriver_FName
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			jsr	PointRecord		;Zeiger auf ersten Datensatz.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			LoadW	r2,64 + 64*2 + 64*17
			LoadW	r7,VLIR_Types
			jsr	ReadRecord		;Infos über verfügbare Treiber
			txa				;einlesen. Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			jmp	CloseRecordFile
::51			rts

;*** Laufwerkstreiber-Datei fehlt.
:Err_LdDskFile		lda	#< Dlg_NoDskFile	;Fehler: "Konfigurationsdatei ist
			ldx	#> Dlg_NoDskFile	;         nicht zu finden!".
			jsr	SystemDlgBox
			jmp	EnterDeskTop		;Installationsfehler, Abbruch...

;******************************************************************************
;*** Laufwerkstreiber einlesen.
;******************************************************************************
;*** Laufwerkstreiber in REU kopieren.
.UpdateDiskDriver	LoadW	r0 ,DiskDriver_FName
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa
			beq	:52
::51			rts

::52			LoadW	r13 ,SIZE_EDITOR_DATA

			lda	MP3_64K_DISK
			sta	r15L
			lda	#$01
			sta	r15H

::54			lda	r15H
			jsr	PointRecord		;Zeiger auf nächsten Datensatz.
			txa				;Datensatz verfügbar ?
			bne	:55			; => Nein, weiter...
			tya				;Datensatz leer ?
			beq	:55			; => Ja, weiter...

			LoadW	r2,SIZE_DDRV_INIT + SIZE_DDRV_DATA
			LoadW	r7,BASE_DDRV_INIT
			jsr	ReadRecord		;Datensatz einlesen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, weiter...

			lda	r7L			;Größe des eingelesenen
			sec				;Datensatzes berechnen.
			sbc	#<BASE_DDRV_INIT
			sta	r2L
			lda	r7H
			sbc	#>BASE_DDRV_INIT
			sta	r2H

			LoadW	r0 ,BASE_DDRV_INIT
			MoveW	r13,r1

			lda	r15L
			sta	r3L
			jsr	StashDskDrv		;Datensatz in RAM kopieren.

			lda	r15H			;Position des aktuellen Datensatz
			asl				;in REU zwischenspeichern.
			tax
			lda	r1L
			sta	DiskDataRAM_A +0,x
			lda	r1H
			sta	DiskDataRAM_A +1,x
			lda	r2L
			sta	DiskDataRAM_S +0,x
			lda	r2H
			ldy	r3L
			cpy	MP3_64K_DISK
			beq	:53
			ora	#%10000000
::53			sta	DiskDataRAM_S +1,x

			AddW	r2,r13			;Position für nächsten Datensatz.
			bcc	:55
			inc	r15L

::55			inc	r15H			;Alle Datensätze eingelesen ?
			CmpBI	r15H,127
			bne	:54			; => Nein, weiter...

			jsr	CloseRecordFile		;Treiber-Datei wieder schließen und
			jsr	SetDiskDatReg		;Treiberinformationen in
			jmp	StashRAM		;REU zwischenspeichern.

;*** Zeiger auf Zwischenspeicher für Laufwerksdaten.
:SetDiskDatReg		LoadW	r0,BASE_EDITOR_DATA
			LoadW	r1,$0000
			LoadW	r2,SIZE_EDITOR_DATA
			lda	MP3_64K_DISK
			sta	r3L
			rts

;*** Laufwerkstreiber in Speicher kopieren.
:StashDskDrv		lda	r3L
			pha
			lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha
			lda	r1H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r1L
			pha

			lda	r1L			;Über 64K-Speichergrenze hinweg
			clc				;Datenbytes in REU speichern ?
			adc	r2L
			sta	r3H
			lda	r1H
			adc	r2H
			bcc	:51			; => Nein, weiter...
			ora	r3H
			beq	:51			; => Nein, weiter...

			lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha

			lda	#$00			;Anzahl Bytes innerhalb
			sec				;aktueller 64K-Speicherbank
			sbc	r1L			;berechnen.
			sta	r2L
			lda	#$00
			sbc	r1H
			sta	r2H

			jsr	StashRAM		;Daten in REU speichern.

			lda	r2L
			clc
			adc	r0L
			sta	r0L
			lda	r2H
			adc	r0H
			sta	r0H

			lda	#$00			;Zeiger auf anfang der nächsten
			sta	r1L			;Speicherbank.
			sta	r1H

			pla				;Anzahl Bytes in nächster
			sec				;Speicherbank berechnen.
			sbc	r2L
			sta	r2L
			pla
			sbc	r2H
			sta	r2H

			inc	r3L			;Zeiger auf nächste Speicherbank

::51			jsr	StashRAM		;Bytes in REU kopieren.

			pla
			sta	r1L
			pla
			sta	r1H
			pla
			sta	r2L
			pla
			sta	r2H
			pla
			sta	r3L
			rts

;*** Laufwerkstreiber aus Speicher einlesen.
:FetchDskDrv		lda	r1L			;Über 64K-Speichergrenze hinweg
			clc				;Datenbytes in REU speichern ?
			adc	r2L
			sta	r3H
			lda	r1H
			adc	r2H
			bcc	:51			; => Nein, weiter...
			ora	r3H
			beq	:51			; => Nein, weiter...

			lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha

			lda	#$00			;Anzahl Bytes innerhalb
			sec				;aktueller 64K-Speicherbank
			sbc	r1L			;berechnen.
			sta	r2L
			lda	#$00
			sbc	r1H
			sta	r2H

			jsr	FetchRAM		;Daten in REU speichern.

			lda	r2L
			clc
			adc	r0L
			sta	r0L
			lda	r2H
			adc	r0H
			sta	r0H

			lda	#$00			;Zeiger auf anfang der nächsten
			sta	r1L			;Speicherbank.
			sta	r1H

			pla				;Anzahl Bytes in nächster
			sec				;Speicherbank berechnen.
			sbc	r2L
			sta	r2L
			pla
			sbc	r2H
			sta	r2H

			inc	r3L			;Zeiger auf nächste Speicherbank

::51			jmp	FetchRAM		;Bytes in REU kopieren.

;******************************************************************************
;*** Verfügbare Laufwerkstypen/Treiber aktualisieren.
;******************************************************************************
;*** Nr. des Laufwerkstreibers berechnen.
;    Übergabe:		AKKU	= Laufwerkstyp ($01,$41,$83,$23 usw...)
;    Rückgabe:		AKKU	= Nr. des Treibers in VLIR-Datei #0-#62.
;				  $FF = unbekanntes Laufwerk.
;			xReg	= Nr. Eintrag in Typentabelle.
.GetDrvModVec		sta	CurDriveMode		;Aktuellen Modus speichern.
			tax				;Typ = $00 ?
			bne	:52			; => Nein, weiter...
::51			lda	#$00			;Modus: "Kein Laufwerk".
			rts

::52			ldx	#$01			;Zeiger auf Typen-Tabelle.
::53			lda	VLIR_Types  ,x		;Typ aus Tabelle einlesen.
			beq	:51			; => Ende erreicht ? Ja, Ende...
			cmp	CurDriveMode		;Mit aktuellem Modus vergleichen.
			beq	:54			; => Gefunden ? Ja, weiter...
			inx				;Zeiger auf nächsten Typ.
			cpx	#63			;Max. Anzahl Typen durchsucht ?
			bne	:53			; => Nein, weiter...
			lda	#$ff			;Unbekanntes Laufwerk!
			rts

::54			txa
			asl
			tax
			lda	VLIR_Entry +0,x		;Zeiger auf VLIR-Tabelle einlesen.
			ldy	VLIR_Entry +1,x
			pha
			txa
			lsr
			tax
			pla
			rts

;*** Installationsroutine auf Diskette aktualisieren.
;    Übergabe:		AKKU	= Laufwerkstyp
;			r2	= Größe der Installationsroutine.
;    Rückgabe:		xReg	= Fehlermeldung.
:SaveDskDrvData		sta	DiskDriver_TYPE		;Variablen zwischenspeichern.
			lda	r2L
			sta	DiskDriver_SIZE +0
			lda	r2H
			sta	DiskDriver_SIZE +1

			jsr	FindDiskDrvFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	:52			; => Nein, Abbruch...

			lda	DiskDriver_TYPE
			jsr	GetDrvModVec		;Vektor auf Datensatz mit Treiber
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:53			; => Ja, Ende...
			sta	DiskDriver_INIT		;Datensätze speichern.
			sty	DiskDriver_DISK

			lda	MP3_64K_DISK		;Treiber in RAM ?
			beq	:50			; => Nein, weiter...

			LoadW	r0,BASE_DDRV_INIT	;Treiber im RAM aktualisieren.
			lda	DiskDriver_INIT
			jsr	SetVecDskInREU
			jsr	StashDskDrv

::50			LoadW	r0 ,DiskDriver_FName
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	DiskDriver_INIT
			jsr	PointRecord		;Zeiger auf Installationsroutine.

			lda	DiskDriver_SIZE +0
			sta	r2L
			lda	DiskDriver_SIZE +1
			sta	r2H
			LoadW	r7,BASE_DDRV_INIT
			jsr	WriteRecord		;Installationsroutine speichern.
			txa				;Diskettenfehler ?
			beq	:54			; => Ja, Abbruch...

::51			jsr	CloseRecordFile		;Treiberdatei schließen.
::52			jsr	PurgeTurbo		;GEOS-Turbo abschalten und
::53			ldx	#DEV_NOT_FOUND		;Fehlermeldung übergeben.
			rts

::54			jsr	UpdateRecordFile
			txa
			bne	:51

			jsr	CloseRecordFile		;Treiber-Datei wieder schließen und
			jmp	PurgeTurbo		;GEOS-Turbo abschalten, Ende...

;******************************************************************************
;*** Laufwerkstreiber laden.
;******************************************************************************
;*** Installationsroutine und Laufwerkstreiber einlesen.
;    Übergabe:		AKKU	= Laufwerkstyp.
;    Rückgabe:		xReg	= Fehlermeldung.
.LoadDskDrvData		tax				;Laufwerkstyp = $00 ?
			beq	:52

			jsr	GetDrvModVec		;Vektor auf Datensatz mit Treiber
			ldx	#DEV_NOT_FOUND
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:52			; => Ja, Ende...
			sta	DiskDriver_INIT		;ermitteln und speichern.
			sty	DiskDriver_DISK
			tax				;Kein Treiber gefunden ?
			beq	:52			; => Ja, Ende...

			lda	MP3_64K_DISK		;Treiber in RAM ?
			bne	:51			; => Nein, weiter...

			jsr	FindDiskDrvFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	:52			; => Nein, Abbruch...
			jmp	LoadDkDvDisk		;Treiber von Diskette laden.
::51			jmp	LoadDkDvRAM		;Treiber aus RAM einlesen.
::52			rts

;*** Treiber von Diskette laden.
:LoadDkDvDisk		LoadW	r0 ,DiskDriver_FName
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa
			bne	:51

			lda	DiskDriver_INIT
			jsr	PointRecord		;Zeiger auf Installationsroutine.
			txa				;Datensatz verfügbar ?
			bne	:51			; => Nein, abbruch...
			ldx	#DEV_NOT_FOUND
			tya				;Datensatz leer ?
			beq	:51			; => Ja, Abbruch...

			LoadW	r2,SIZE_DDRV_INIT
			LoadW	r7,BASE_DDRV_INIT
			jsr	ReadRecord		;Installationsroutine einlesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Nein, weiter...

			lda	DiskDriver_DISK
			jsr	PointRecord		;Zeiger auf Laufwerkstreiber.
			txa				;Datensatz verfügbar ?
			bne	:51			; => Nein, abbruch...
			ldx	#DEV_NOT_FOUND
			tya				;Datensatz leer ?
			beq	:51			; => Ja, Abbruch...

			LoadW	r2,SIZE_DDRV_DATA
			LoadW	r7,BASE_DDRV_DATA
			jsr	ReadRecord		;Laufwerkstreiber einlesen.

::51			txa
			pha
			jsr	CloseRecordFile
			jsr	PurgeTurbo
			pla
			tax
			rts

;*** Treiber aus RAM laden.
:LoadDkDvRAM		LoadW	r0,BASE_DDRV_INIT
			lda	DiskDriver_INIT
			jsr	SetVecDskInREU
			jsr	FetchDskDrv

			LoadW	r0,BASE_DDRV_DATA
			lda	DiskDriver_DISK
			jsr	SetVecDskInREU
			jmp	FetchDskDrv

;*** Zeiger auf VLIR-Datensatz in REU.
:SetVecDskInREU		asl
			tax
			lda	DiskDataRAM_A +0,x
			sta	r1L
			lda	DiskDataRAM_A +1,x
			sta	r1H
			lda	DiskDataRAM_S +0,x
			sta	r2L
			lda	DiskDataRAM_S +1,x
			pha
			and	#%01111111
			sta	r2H
			lda	MP3_64K_DISK
			sta	r3L
			pla
			and	#%10000000
			beq	:1
			inc	r3L
::1			rts

;******************************************************************************
;*** Unterprogramme.
;******************************************************************************
;*** Fehler, Konfiguration ungültig.
.Err_IllegalConf	lda	#<Dlg_IllegalCfg	;Dialogbox "Konfiguration ungültig"
			ldx	#>Dlg_IllegalCfg
			jsr	SystemDlgBox
			jsr	LdBootScrn		;Startbild anzeigen. Notwendig falls
							;Diagnosemodus aktiv war.

;--- Ergänzung: 25.12.18/M.Kanet
;Beim C128 muss der Programmteil zum wechseln von SD2IEC DiskImages aus
;VLIR-Datensatz #3 nachgeladen werden.
;Die folgenden Routinen wurden angepasst um neben dem Hauptmenü auch den
;SD2IEC-Code nachladen zu können.
;*** Hauptmenü nachladen.
:LoadMainMenu		jsr	FindSystemFile		;Systemdatei suchen.
			txa				;Diskettenfehler ?
			bne	LdMenuError		; => Ja, Abbruch...

			LoadW	r2,VLIR_SIZE
			LoadW	r7,VLIR_BASE
			lda	#$01
			jsr	LoadSysRecord		;Zeiger auf Hauptmenü.
			txa				;Diskettenfehler ?
			bne	LdMenuError		; => Ja, Abbruch...
			jmp	VLIR_BASE		;Hauptmenü starten.

;*** Systemdatei suchen.
.FindSystemFile		jsr	SetSystemDevice		;Systemlaufwerk aktivieren.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

			LoadW	r6 ,SysFileName
			LoadB	r7L,AUTO_EXEC
			LoadB	r7H,1
			LoadW	r10,SystemClass
			jsr	FindFTypes		;GEOS.Editor-Datei suchen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...
			lda	r7H			;Datei gefunden ?
			bne	:1			;Nein, Fehler => "FILE NOT FOUND"
			rts				;OK.

::1			ldx	#FILE_NOT_FOUND		;Fehler aufgetreten, Ende.
::2			rts

;*** VLIR-Datensatz laden.
;Übergabe:		AKKU = Datensatz
;			r2   = VLIR_SIZE
;			r7   = VLIR_BASE
.LoadSysRecord		sta	:1 +1			;VLIR-Datensatz merken.
			LoadW	r0 ,SysFileName
			jsr	OpenRecordFile		;GEOS.Editor-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

::1			lda	#$ff			;Zeiger auf VLIR-Datensatz.
			jsr	PointRecord
			jsr	ReadRecord		;Datensatz einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...
			jsr	CloseRecordFile		;GEOS.Editor-Datei schließen.
::2			rts

;*** Fehler beim öffnen der Konfigurieren-Datei.
.LdMenuError		lda	#<Dlg_LdMenuErr
			ldx	#>Dlg_LdMenuErr
			jsr	SystemDlgBox
			jmp	PrepareExitDT

;*** Fehler beim öffnen der Konfigurieren-Datei.
:SysDrvNotFound		lda	#<Dlg_LdDskDrv
			ldx	#>Dlg_LdDskDrv

;*** Dialogbox anzeigen.
;    Bildschirm wird beim MegaPatch automatisch restauriert!
.SystemDlgBox		sta	r0L			;Zeiger auf Dialogbox-Daten.
			stx	r0H
			jmp	DoDlgBox		;Dialogbox öffnen.

;*** Titelzeile in Dialogbox löschen.
.Dlg_DrawTitel		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$30,$3f
			w	$0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** Sprungtabelle installieren.
;    Wichtige Routinen, die auch von den Installationsroutinen der
;    Laufwerkstreiber aufgerufen werden können, sind in einer Sprungtabelle
;    im Bereich ":a0" bis ":a9" gespeichert. Der Einsprung erfolgt über
;    einen "JMP (a0)"-Befehl... Rouinen siehe Tabelle bei ":JumpTable".
:InstallJumpTab		ldx	#0
::51			lda	JumpTable,x		;Zeiger auf Register einlesen.
			sta	r0L			;(":a0" bis ":a9").
			inx
			lda	JumpTable,x
			sta	r0H
			inx
			ldy	#$00
			lda	JumpTable,x		;Vektor auf Installationsroutine
			sta	(r0L),y			;einlesen und in Sprungtabelle
			inx				;kopieren.
			iny
			lda	JumpTable,x
			sta	(r0L),y
			inx
			cpx	#4*10
			bne	:51
			rts

;******************************************************************************
;*** Unterprogramme.
;******************************************************************************
;*** Taktfrequenz für SCPU erkennen.
;    Übergabe:		-
;    Rückgabe:		AKKU	= $40, SuperCPU =>  1Mhz.
;			        = $00, SuperCPU => 20Mhz.
.CheckForSpeed		php
			sei

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			ldx	MMU
			lda	#$7e
			sta	MMU
endif

			lda	$d0b8

if Flag64_128 = TRUE_C64
			stx	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			stx	MMU
endif

			plp
			and	#%01000000		;Bit 6=0, SCPU mit 20 Mhz.
			rts

;*** Laufwerke zählen.
;    Übergabe:		-
;    Rückgabe:		-
.CountDrives		lda	#$00			;Anzahl Laufwerke löschen.
			sta	numDrives
			ldy	#$03
::51			lda	RealDrvType,y		;Laufwerk verfügbar ?
			beq	:52			;Nein, weiter...
			inc	numDrives		;Anzahl Laufwerke +1.
::52			dey
			bpl	:51
			rts

;*** Diskettenbezeichnung löschen.
;    Übergabe:		-
;    Rückgabe:		-
.ClearDiskName		ldx	#r1L
			jsr	GetPtrCurDkNm
			LoadW	r0,StdDiskName
			ldy	#$10
::51			lda	(r0L),y
			sta	(r1L),y
			dey
			bpl	:51
			rts

;*** Laufwerksdaten löschen.
;    Übergabe:		NewDrive = Zeiger auf zu löschendes Laufwerk.
;    Rückgabe:		-
.ClearDriveData		ldy	NewDrive
:ClearDriveDataY	lda	#$00
			sta	driveType     -8,y
			sta	driveData     -8,y
			sta	ramBase       -8,y
			sta	BootConfig    -8,y
			sta	turboFlags    -8,y
			sta	RealDrvType   -8,y
			sta	drivePartData -8,y
			sta	doubleSideFlg -8,y
			sta	NewDriveMode
			sta	DriveInUseTab -8,y
			rts

;******************************************************************************
;*** Laufwerke in ":BootConfig" oder angeschlossene Laufwerke installieren.
;******************************************************************************
;*** Laufwerke installieren.
:InstallDkDev		jsr	Set_NoDskDvInRAM	;Flag  "Laufwerkstreiber in RAM"
							;löschen (":sysRAMFlg").
			ldx	#$08
::51			stx	NewDrive		;Zeiger auf nächstes Laufwerk.
			lda	BootConfig -8,x		;Laufwerk bereits festgelegt ?
			bne	:52			; => Ja, weiter...

			bit	Flag_ME1stBoot		;Erster Start von GEOS.Editor ?
			bmi	:52			; => Nein, kein Laufwerk waehlen.

			lda	NewDrive		;Erststart von GEOS.Editor,
			jsr	TestDriveType		;aktuelles Laufwerk testen.
			cpx	#NO_ERROR		;Fehler ?
			bne	:52			; => Ja, Ende...

			ldx	NewDrive		;Laufwerks-Adresse einlesen und
			and	#%00001111		;Partitionsformat isolieren und
			sta	BootConfig -8,x		;Ziel-Laufwerk speichern.
			tya
			ora	BootConfig -8,x
			sta	BootConfig -8,x

::52			ldx	NewDrive		;Laufwerkstyp für aktuelles
			lda	BootConfig -8,x		;Laufwerk einlesen.
			beq	:52a			;Ist Laufwerk konfiguriert ?
;			pha				; => Nein, nicht aktivieren.
			jsr	InstallDskDevice	;Treiber laden und installieren.
;			pla
;			cpx	#NO_ERROR		;Installationsfehler ?
			txa				;Installationsfehler ?
			beq	:53			; => Nein, weiter...

::52a			ldy	NewDrive		;Installation fehlgeschlagen,
			jsr	ClearDriveDataY		;Laufwerk deaktivieren.

::53			ldx	NewDrive		;Zeiger auf nächstes Laufwerk.
			inx
			cpx	#12			;Alle Laufwerke installiert ?
			bcs	:54			; => Ja, weiter...
			jmp	:51			; => Nächstes Laufwerk...

::54			jsr	Set_DskDvInRAM		;Laufwerkstreiber in RAM aktivieren.

::55			jsr	SetSystemDevice		;Start-Laufwerk aktivieren.
			txa				;Diskettenfehler ?
			beq	:56			; => Nein, weiter...
			jmp	SysDrvNotFound
::56			jmp	PurgeTurbo		;GEOS-Turbo abschalten.

;******************************************************************************
;*** Laufwerke in ":BootConfig" oder angeschlossene Laufwerke installieren.
;******************************************************************************
;*** Aktuellen Laufwerkstreiber testen/installieren.
;    Übergabe:		AKKU	= Laufwerkstyp.
;			xReg	= Laufwerksadresse.
;    Rückgabe:		xReg	= Fehlermeldung.
:InstallDskDevice	stx	:curDrive		;Laufwerksadresse speichern.

			cmp	#$00			;Laufwerk deaktivieren ?
			beq	:52			; => Ja, weiter...

			pha				;Laufwerkstyp merken.
			jsr	LoadDskDrvData		;Daten für Treibertyp einlesen.
			pla				;Laufwerkstyp zurücksetzen.
			cpx	#NO_ERROR		;Laufwerktreiber eingelesen ?
			bne	:53			;Nein, Abbruch...

::51			ldx	:curDrive		;Aktuelles Laufwerk.

;--- Ergänzung: 15.06.18/M.Kanet
;Der RAMNative-Treiber erkennt bei der Laufwerksinstallation ob
;bereits einmal ein RAMNative-Laufwerk installiert war. Dazu wird die
;BAM geprüft. Ist diese gültig wird daraus die Größe des Laufwerks ermittelt
;und im GEOS.Editor dann als Größe vorgeschlagen. Damit dies funktioniert
;sollte in :ramBase die frühere Startadresse übergeben werden.
;Wird die Konfiguration im Editor gespeichert wird jetzt auch die :ramBase
;Adresse der RAMLaufwerke gesichert und an dieser Stelle vor der Laufwerks-
;Installation als Vorschlag an die Installationsroutine übergeben.
			pha
;--- Ergänzung: 06.08.18/M.Kanet
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU nutzen die
;Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
			and	#%11110000
			bpl	:51b			; => Kein RAM-Laufwerk, weiter..
			and	#%01110000		;RAM41/71/81/NM ?.
			bne	:51b			; => Nein, weiter...
			lda	ramBase -8,x		;ramBase bereits definiert?
			bne	:51b			; => Ja, weiter...
			lda	BootRamBase -8,x	;Neues RAMLaufwerk.
			sta	ramBase -8,x		;Startadresse vorschlagen.
::51b			pla
			jsr	DoInstallDskDev		;Treiberinstallation starten.
			txa				;Laufwerk installiert ?
			bne	:53			;Nein, Abbruch...

			ldx	:curDrive
			lda	driveType -8,x		;RAM-Laufwerk ?
			bmi	:51a			; => Ja, weiter...
			lda	#$ff
			sta	DriveInUseTab -8,x

;--- Hinweis:
;Hier muss OpenDisk ausgeführt werden.
;OpenDisk führt zu Beginn die Routine
;"FindRAMLink" aus um die Geräteadresse
;der RAMLink zu ermitteln.
;In älteren MP3-Versionen führte das
;dazu, das ":xSwapPartition" für die RL
;die Geräteadresse RL_DEV_ADDR=0
;verwendet => Fehler bei ":xReadBlock":
;Hier wird über ":RL_DataCheck" geprüft
;ob die aktive Partition gültig ist und
;ggf. über die Routine ":xSwapartition"
;die Partition gewechselt.
;":RL_DataCheck" testet jetzt vorher
;die Geräteadresse und sucht dann ggf.
;das RAMLink-Laufwerk am ser.Bus.
::51a			lda	RealDrvMode-8,x		;CMD-Laufwerk ?
			bpl	:51c			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	OpenDisk		;Treiber initialisieren...
;--- Hinweis:
;Für CMD-Laufwerke die Boot-Partition
;einstellen. Für RAMLink/Boot zwingend
;erforderlich, da durch OpenDisk evtl.
;eine andere Partition als "Aktiv"
;eingestellt wurde.
			ldx	:curDrive
			lda	BootPartRL  -8,x
			sta	r3H			;Partitions-Nr. einlesen und
			jsr	OpenPartition		;Partition öffnen.
			txa				;Diskettenfehler ?
			beq	:51c			; => Nein, weiter...
			cpx	#NO_PART_FD_ERR		;Keine FD-Diskette im Laufwerk ?
			beq	:51c			; => Ja, weiter...

			jsr	OpenDisk		;Diskette öffnen, dabei nach
							;gültiger Partition suchen...
::51c			jsr	PurgeTurbo
::52			ldx	#NO_ERROR		;Laufwerk installiert.
			rts

::53			ldx	#DEV_NOT_FOUND		;Laufwerk nicht möglich.
			rts

::curDrive		b $00

;*** Variablen für Installation des aktuellen Treibers definieren und
;    Installationsroutine starten.
.DoInstallDskDev	stx	curDrive 		;Aktuelles Laufwerk merken.
			sta	:2 +1 			;Laufwerksmodus zwischenspeichern.

			lda	#$00			;Lauafwerksdaten löschen. Diese
			sta	RealDrvMode -8,x	;werden über die neuen Laufwerks-
			sta	RealDrvType -8,x	;treiber später aktualisiert.

;--- Ergänzung: 07.12.19/M.Kanet
;Für die aktuellen Treiber ist es nicht
;mehr erforderlich die Adresse des
;Treibers in der REU in ":r1" zu
;übergeben, da die Treiber die Kernal-
;Routine ":InitForDskDvJob" nutzen.
;			lda	DskDrvBaseL -8,x	;Zeiger auf Laufwerkstreiber
;			sta	r1L			;in GEOS-Systemspeicherbank setzen.
;			lda	DskDrvBaseH -8,x
;			sta	r1H
;---

			lda	:2 +1			;Übergabeparameter definieren.
			and	#%11110000		;Laufwerkstyp bestimmen.
			cmp	#DrvHD			;Laufwerk CMD-HD ?
			bne	:1			; => Nein, weiter...
			lda	BootUseFastPP		;PP-Modus übergeben.
			b $2c
::1			lda	#$00
::2			ora	#$ff			;Übergabeparameter definieren.
			jmp	DDrv_Install		;Treiber installieren.

;******************************************************************************
;*** Angeschlossenes Laufwerk erkennen.
;******************************************************************************
;*** Laufwerkstyp ermitteln  (GEOS: #8 - #11).
;    Übergabe:		AKKU	= Geräteadresse.
;    Rückgabe:		AKKU	= 41=$01, 71=$02, 81=$03, FD=$1x, HD=$2x, RL=$3x
;			yReg	= 41=$01, 71=$02, 81=$03, FD=$10, HD=$20, RL=$30
:TestDriveType		sta	r14L
			tax
			lda	DriveInfoTab-8,x
			bne	:51
::50			lda	#$00			;Kein Laufwerk installiert.
			tay
			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk gefunden.
::51			lda	#$00			;Partitionsformat löschen.
			sta	BootPartType-8,x
			sta	BootPartRL_I-8,x

			lda	DriveInfoTab -8,x
			ldy	DriveInUseTab-8,x
			bne	:50
			tay
			and	#%11110000		;CMD-Laufwerk gefunden ?
			bne	:53			; => Ja, weiter...
::52			ldx	#NO_ERROR
			tya				;Standard-Laufwerk, Ende...
			rts

;--- CMD-Laufwerk gefunden.
::53			lda	r14L
			sta	NewDrive
			jsr	GetPartType		;Partitionsdaten einlesen.
							;Rückgabe: AKKU = Typ, YREG = PNr.
			cpx	#NO_ERROR		;Laufwerksfehler ?
			bne	:55			; => Ja, Abbruch...

			ldx	r14L
			sta	BootPartType-8,x	;Partitionsformat speichern.
			lda	DriveInfoTab-8,x
			cmp	#DrvRAMLink		;CMD-RAMLink-Laufwerk ?
			bne	:54			; => Nein, weiter...
			pha
			tya
			sta	BootPartRL_I-8,x	;Partitions-Nr. speichern.
			stx	DriveRAMLink		;RL-Adresse speichern.
			pla				;CMD-Laufwerkstyp wieder einlesen.

::54			tay
			ora	BootPartType-8,x
			ldx	#NO_ERROR		;Flag: "Kein Fehler!".
			rts				;Ende...

::55			pla				;Stack zurücksetzen, Ende...
			rts

;******************************************************************************
;*** Laufwerks-Erkennung
;******************************************************************************
			t "-G3_DetectDrive"
;******************************************************************************

;******************************************************************************
;*** Neues Laufwerk aktivieren.
;******************************************************************************
;*** Dialogbox: "Neues Laufwerk einschalten!".
;    Übergabe:		AKKU =	Adresse des Ziel-Laufwerks #8 - #11.
:TurnOnNewDrive		ldx	#$ff
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:54			; => Ja, Abbruch...

			sta	TurnOnDriveAdr		;Laufwerksadr. speichern und
			clc				;Text für Dialogbox initialisieren.
			adc	#$39
			sta	TxNDrv1

;--- Laufwerksadressen im Bereich #8 - #11 "deaktivieren".
			jsr	FreeDrvAdrGEOS		;Laufwerke #8 bis #11 auf
							;Addresse #20 bis #23 umstellen

;--- Dialogbox ausgeben.
			lda	#<Dlg_SetNewDev
			ldx	#>Dlg_SetNewDev
			jsr	SystemDlgBox		;Dialogbox: Laufwerk einschalten.

;--- Laufwerksadressen wieder zurücksetzen.
			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O aktivieren.
			jsr	InitForIO

			lda	#8			;Nach neuem Laufwerk mit Adresse
::51			sta	r15H			;von #8 bis #19 suchen.
			jsr	IsDrvAdrFree		;Laufwerk vorhanden ?
			beq	:52			; => Ja, weiter...

			lda	r15H
			clc
			adc	#$01			;Zeiger auf nächstes Laufwerk.
			cmp	#20			;Alle Laufwerke getestet ?
			bcc	:51			; => Nein, weiter...

			jsr	DoneWithIO		;I/O abschalten.
			jmp	:53			;Kein neues Laufwerk, Ende...

::52			ldx	r15H			;Geräteadresse auf Ziel-Laufwerk
			ldy	TurnOnDriveAdr		;umschalten. Das neue Laufwerk hat
			jsr	SwapDskAdr		;nun die benötigte GEOS-Adresse!
			ldy	TurnOnDriveAdr
			lda	#$00
			sta	OldDrvAdrTab -8,y
			sta	NewDrvAdrTab -8,y
			jsr	DoneWithIO

::53			jsr	ResetDrvAdrGEOS		;Die restlichen Laufwerksadressen
							;wieder auf die alten Adressen
							;zurücksetzen.
;--- Dialogbox auswerten.
			ldx	#$00
			lda	sysDBData
			cmp	#OK			;Wurde "OK"-Icon gewählt ?
			beq	:54			; => Nein, weiter...
			dex
::54			rts

;******************************************************************************
;*** Bestimmtes Laufwerk suchen.
;******************************************************************************
;*** Suche nach Laufwerkstyp starten.
;    Übergabe:		AKKU =	Laufwerkstyp.
;				Bei CMD-Geräten muß Bit %0-%3 = NULL sein!
;			yReg =	Laufwerksadresse #8 bis #11.
;				(Geräteadresse wird automatisch umgestellt).
.FindDriveType		sty	r15L
			sta	r15H

			jsr	GetAllSerDrive		;<*> Alle Laufwerke erkennen.

;--- Laufwerkstyp erkennen. ($01,$02,$03... $10,$20,$30....)
::51			lda	#$08			;Zeiger auf Laufwerk #8.
::52			sta	r14L
			tax
			lda	DriveInUseTab-8,x
			bne	:57
			lda	DriveInfoTab-8,x
			beq	:57
			cmp	r15H			;Laufwerkstyp gefunden ?
			bne	:57			; => Nein, weiter...

;--- Geräteadresse festlegen.
::54			lda	r15L			;Hat Laufwerk bereits die
			cmp	r14L			;korrekte Laufwerksadresse ?
			beq	:56			; => Ja, Ende...

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O aktivieren.
			jsr	InitForIO

			lda	r15L			;Existiert ein Laufwerk mit neuer
			jsr	IsDrvAdrFree		;Geräteadresse ?
			bne	:55			; => Nein, weiter...

			jsr	GetFreeDrvAdr		;Freie Geräteadresse suchen.

			ldx	r15L			;Aktuelles Gerät auf eine neue
			jsr	SwapDskAdr		;Adresse umschalten, damit die
							;Geräteadresse für neues Laufwerk
							;freigegeben wird.

::55			ldy	r15L			;Ziel-Laufwerk auf die neue GEOS-
			ldx	r14L			;Adresse umschalten.
			jsr	SwapDskAdr
			jsr	DoneWithIO		;I/O abschalten.

::56			ldx	#NO_ERROR		;Ende...
			rts

::57			ldx	r14L			;Zeiger auf nächstes Laufwerk.
			inx
			txa
			cmp	#29 +1			;Alle Laufwerksadresse durchsucht ?
			bcc	:52			; => Nein, weiter...

			ldx	#DEV_NOT_FOUND
			rts

;******************************************************************************
;*** Laufwerksadressen tauschen.
;******************************************************************************
;*** Laufwerke #8 bis #11 auf freie Adressen legen.
:FreeDrvAdrGEOS		jsr	PurgeTurbo		;GEOS-Turbo aus und I/O aktivieren.
			jsr	InitForIO

			ldy	#$03
			lda	#$00			;Tabelle mit Geräteadressen löschen.
::51			sta	OldDrvAdrTab,y
			sta	NewDrvAdrTab,y
			dey
			bpl	:51

			lda	#8
::52			sta	r15H
			tax
			lda	DriveInfoTab-8,x	;Laufwerk vorhanden ?
			beq	:53			;Nein, weiter...

			jsr	GetFreeDrvAdr		;Freie Geräteadresse suchen.

			lda	r15H
			tax
			sta	OldDrvAdrTab-8,x
			tya
			sta	NewDrvAdrTab-8,x
			jsr	SwapDskAdr		;Gerät auf neue Adresse umschalten.

::53			lda	r15H
			clc
			adc	#$01			;Zeiger auf nächstes Laufwerk.
			cmp	#12			;Alle Laufwerke getauscht ?
			bcc	:52			;Nein, weiter...

::54			jmp	DoneWithIO		;I/O abschalten.

;*** Geräteadressen zurücksetzen.
:ResetDrvAdrGEOS	jsr	PurgeTurbo		;GEOS-Turbo aus und I/O aktivieren.
			jsr	InitForIO

			ldy	#8
::51			sty	r15H
			lda	NewDrvAdrTab -8,y
			beq	:52
			tay
			lda	DriveInfoTab -8,y
			beq	:52

			ldy	r15H
			ldx	NewDrvAdrTab -8,y
			lda	OldDrvAdrTab -8,y
			tay
			jsr	SwapDskAdr		;Gerät auf neue Adresse umschalten.

::52			ldy	r15H
			iny
			cpy	#12
			bcc	:51
			jmp	DoneWithIO		;I/O abschalten.

;*** Geräteadresse swappen.
;    Übergabe:		yReg = Neue Geräteadresse.
;			xReg = Alte       "
:SwapDskAdr		lda	DriveInfoTab -8,x
			pha
			lda	DriveInUseTab-8,x
			sta	DriveInUseTab-8,y
			lda	#$00
			sta	DriveInUseTab-8,x
			sta	DriveInfoTab -8,x
			pla
			sta	DriveInfoTab -8,y

			tya
			add	32
			sta	NewDrvAdr1		;Ziel-Adresse #1 berechnen.
			tya
			add	64
			sta	NewDrvAdr2		;Ziel-Adresse #2 berechnen.
			stx	CurDrvAdr		;Laufwerksadresse merken.

			lda	#$00
			sta	STATUS			;Gerät aktivieren.
			jsr	$ffae
			lda	CurDrvAdr
			jsr	$ffb1
			lda	#$ff
			jsr	$ff93

			ldy	#$00			;Neue Laufwerksadresse senden.
::51			lda	SwapCommand,y
			jsr	$ffa8
			iny
			cpy	#$08
			bne	:51

			jmp	$ffae			;OK!

;******************************************************************************
;*** Laufwerksadressen tauschen.
;******************************************************************************
;*** Freie Geräteadresse im Bereich #20 bis #29 suchen.
:GetFreeDrvAdr		lda	#20
::51			sta	r14H
			jsr	IsDrvAdrFree		;Laufwerksadresse testen.
			ldy	r14H
			tax				;Ist Adresse frei ?
			bne	:52			; => Ja, weiter...
			iny
			tya
			cmp	#29			;Max. #29! Sonst kommt es zu Pro-
			bcc	:51			;blemen am ser. Bus!!!
			ldy	r15L
::52			rts

;*** Ist Laufwerk verfügbar ?
.IsDrvOnline		pha
			jsr	InitForIO
			pla
			jsr	IsDrvAdrFree
			pha
			jsr	DoneWithIO
			pla
			rts

;*** Ist Laufwerksadresse belegt ?
;    Die Routine ":DetectDrive" ist Teil der Laufwerkserkennung und
;    befindet sich im Quelltext "-G3_DetectDrive"!
.IsDrvAdrFree		= DetectDrive

;******************************************************************************
;*** Partitionsformat auf aktuellem Laufwerk ermitteln.
;******************************************************************************
;*** Partitionstyp einlesen.
;    Aus dem Partitionstyp (1=41, 2=71, 3=81, 4=Native) und dem Laufwerkstyp
;    ($10=FD, $20=HD, $30=RAMLink) wird das Laufwerksformat erzeugt.
;    ($13,FD81, $31=RAMLink41 usw...)
;    Rückgabe:		AKKU	= Partitionstyp 41/71/81/NM.
;			YREG	= Partitionsnummer.
;			XREG	= Status, $00 = NO_ERROR.
:GetPartType		lda	#$00			;System-Partitionsdaten einlesen.
			sta	GP_Command +3
			jsr	GetPartData

			lda	PartitionData		;Partitonstyp einlesen.
			cmp	#$ff			;Systempartition vorhanden?
			bne	:53			; => Nein, Keine Disk, weiter...
			sta	GP_Command +3		;Aktive Partitionsdaten einlesen.
			jsr	GetPartData

			ldx	PartitionData		;CMD-Partitionsformat einlesen.
			beq	:52			; $00 => Nicht erstellt.
			dex				;CMD-Format nach GEOS wandeln.
			bne	:51
			ldx	#$04
::51			txa				;Partitionsformat.
			ldy	PartitionData +2
			ldx	#NO_ERROR		;Flag für kein Fehler.
			rts

::52			ldx	NewDrive		;Partitionsformat aus letztem
			lda	BootPartType-8,x	;Startvorgang einlesen.
			bne	:54			; => Formatvorgabe übernehmen.
::53			lda	#$03			;Vorgabewert, wenn bei einer CMD FD
							;keine partitionierte Diskette im
							;Laufwerk liegt!
::54			ldy	BootPartRL  -8,x	;Startpartition definiert ?
			bne	:55			; => Ja, weiter...
			ldy	#$01			;Vorgabewert für RL-Partition.
::55			ldx	#NO_ERROR		;Flag: "Kein Fehler".
			rts

;*** Partitionsdaten einlesen.
:GetPartData		jsr	InitForIO		;I/O-Bereich einblenden.

			LoadW	r0,GP_Command
			jsr	SendFloppyCom_5		;"G-P"-Befehl an Floppy senden.
			bne	:53			;Kein Fehler, weiter...

::51			lda	NewDrive		;Laufwerk auf "Senden" umschalten.
			jsr	$ffb4
			lda	#$ff
			jsr	$ff96

			ldy	#$00
::52			jsr	$ffa5			;Partitionsinformationen einlesen.
			sta	PartitionData,y
			iny
			cpy	#$1f
			bcc	:52

			jsr	$ffab			;Laufwerk abschalten.
			lda	NewDrive
			jsr	$ffb1
			lda	#$ef
			jsr	$ff93
			jsr	$ffae

::53			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;******************************************************************************
;*** Speicherbelegung.
;******************************************************************************
;*** Bank-Belegungstabelle erstellen.
:Make64KRamTab		ldx	#$00
::51			stx	:52 +1			;Bank-Adresse speichern.

			jsr	BankUsed_GetByte	;Bank-Status einlesen.
			jsr	BankUsed_Type		;Bank-Typ definieren.
			tay				;Bank frei ?
			beq	:52			; => Ja, freigeben...
			lda	#BankCode_Block
			cpy	#$01			;Bank durch Applikation belegt ?
			beq	:52			; => Ja, reservieren.
			lda	#BankCode_Disk
			cpy	#$02			;Bank durch Disk-Laufwerk belegt ?
			beq	:52			; => Ja, reservieren.
			lda	#BankCode_GEOS		;Bank durch GEOS/TaskMan/Spooler
							;belegt und freigeben.
::52			ldx	#$ff
			sta	BankUsed ,x		;Bank-Modus in Tabelle übertragen.
			inx				;Zeiger auf nächste Bank.
			cpx	ramExpSize		;Alle Bänke überprüft ?
			bcc	:51			; => Nein, weiter...

			jsr	AllocBankGEOS		;Speicherbänke für GEOS/MP3 belegen.

			bit	firstBoot		;GEOS-BootUp ?
			bmi	CreateBankTask		; => Nein, weiter...
			rts

;--- Freigeben der belegten Bänke für TaskManager.
:CreateBankTask		bit	BootTaskMan		;TaskManager aktiv ?
			bmi	:53			; => Nein, weiter...

			ldy	#$00			;GEOS-Speicherbänke in TaskManager-
::51			ldx	TASK_BANK_ADDR,y	;Speicherbänke konvertieren.
			beq	:52
			lda	#BankCode_Task
			sta	BankUsed      ,x

if Flag64_128 = TRUE_C128
			ldx	TASK_VDC_ADDR,y
			beq	:52
			lda	#BankCode_Task
			sta	BankUsed      ,x
			ldx	TASK_BANK0_ADDR,y
			beq	:52
			lda	#BankCode_Task
			sta	BankUsed      ,x
endif

::52			iny
			cpy	#MAX_TASK_ACTIV
			bcc	:51

::53			jsr	GetMaxTask		;Installierte Anzahl Tasks

if Flag64_128 = TRUE_C128
			ldx	#0
::2			cpy	#0
			beq	:1
			inx
			dey
			dey
			dey
			jmp	:2
::1			stx	TASK_COUNT		;Druckerspooler bestimmen.
endif

if Flag64_128 = TRUE_C64
			sty	TASK_COUNT		;Druckerspooler bestimmen.
endif

;--- Freigeben der belegten Bänke für Spooler.
:CreateBankSpool	bit	BootSpooler		;Spooler aktiv ?
			bpl	:52			; => Nein, weiter...

			ldx	Flag_SpoolMinB
			beq	CreateBank_End

			lda	#BankCode_Spool		;GEOS-Speicherbänke in Spooler-
::51			sta	BankUsed ,x		;Speicherbänke konvertieren.
			inx
			cpx	Flag_SpoolMaxB
			bcc	:51
			beq	:51

::52			jsr	GetMaxSpool		;Installierte Spoolergröße
			sty	BootSpoolSize		;einlesen und speichern.
:CreateBank_End		rts

;******************************************************************************
;*** Speicherbelegung.
;******************************************************************************
;*** Bank-Tabelle an GEOS übergeben.
.BankUsed_2GEOS		ldx	#$00
::51			stx	:58 +1			;Bank-Adresse speichern.

			lda	BankUsed ,x		;Speicherbank frei ?
			bne	:53			; => Nein, weiter...
::52			jsr	BankUsed_GetByte	;Aktuelle Speicherbank freigeben.
			and	BankCodeTab2,y
			jmp	:57

::53			cmp	#BankCode_GEOS		;Bank durch GEOS belegt ?
			beq	:54			; => Ja, weiter...
			cmp	#BankCode_Task		;Bank durch TaskManager belegt ?
			beq	:54			; => Ja, weiter...
			cmp	#BankCode_Spool		;Bank durch Spooler belegt ?
			bne	:55			; => Nein, weiter...
::54			jsr	BankUsed_GetByte	;Speicherbank durch GEOS belegt.
			and	BankCodeTab2,y
			ora	BankType_GEOS,y
			jmp	:57

::55			cmp	#BankCode_Disk		;Bank durch Laufwerke belegt ?
			bne	:56			; => Nein, weiter...
			jsr	BankUsed_GetByte
			and	BankCodeTab2,y
			ora	BankType_Disk,y
			jmp	:57

::56			cmp	#BankCode_Block		;Bank durch Anwendungen belegt ?
			bne	:52			; => Nein, weiter...
			jsr	BankUsed_GetByte
			and	BankCodeTab2,y
			ora	BankType_Block,y

::57			sta	RamBankInUse,x
::58			ldx	#$ff
			inx				;Zeiger auf nächste Bank.
			cpx	ramExpSize		;Alle Bänke überprüft ?
			bcc	:51			; => Nein, weiter...
			rts

;******************************************************************************
;*** Speicherbelegung.
;******************************************************************************
;*** Erste Speicherbank suchen, die nicht durch GEOS belegt ist und
;    als "Reserviert" markieren.
:BlockFreeBank		ldy	#$00
::51			lda	BankUsed,y
			beq	:53
::52			iny
			cpy	ramExpSize
			bcc	:51
			rts

::53			lda	#BankCode_Block
			sta	BankUsed,y
			rts

;*** Speicherbänke löschen: TaskMan.
.ClrBank_TaskMan	lda	#BankCode_Task
			b $2c

;*** Speicherbänke löschen: Spooler.
.ClrBank_Spooler	lda	#BankCode_Spool
			b $2c

;*** Speicherbänke löschen: Reserviert.
.ClrBank_Blocked	lda	#BankCode_Block
			sta	:52 +1

			ldx	#$00
			txa
::51			ldy	BankUsed ,x
::52			cpy	#$ff
			bne	:53
			sta	BankUsed ,x
::53			inx
			cpx	ramExpSize
			bcc	:51
			rts

;*** Speicherbank suchen: TaskMan.
:GetBank_TaskMan	lda	#BankCode_Task
			b $2c

;*** Speicherbank suchen: Spooler.
:GetBank_Spooler	lda	#BankCode_Spool
			sta	:52 +1

			ldy	ramExpSize
			beq	:53
::51			dey
			beq	:53
			lda	BankUsed ,y
::52			cmp	#$ff
			bne	:51
::53			rts

;*** Anzahl belegter Task-/Spooler-Bänke ermitteln.
.GetMaxFree		lda	#$00
			b $2c
.GetMaxTask		lda	#BankCode_Task
			b $2c
.GetMaxSpool		lda	#BankCode_Spool
			sta	:52 +1

			ldy	#$00			;Anzahl 64K-Bänke löschen.
			ldx	#$00			;Zeiger auf Bank #1.
::51			lda	BankUsed ,x		;Bank-Modus einlesen und auf
::52			cmp	#$ff			;gesuchten Typ testen.
			bne	:53			; => Stimmt nicht, weiter...
			iny				;Anzahl RAM-Bänke +1.
::53			inx
			cpx	ramExpSize		;Alle Bänke durchsucht ?
			bcc	:51			;Nein, weiter...
			rts

;*** Freie Speicherbank suchen.
:FindNxFreeBank		ldx	ramExpSize
			beq	:52
::51			dex
			beq	:52
			lda	BankUsed,x		;Ist Bank belegt ?
			bne	:51 			;Ja, weitersuchen.
::52			rts

if Flag64_128 = TRUE_C128
;*** Zwei freie Banks suchen
:FindNxFreeBank2	ldy	#0			;Flag für Durchlauf
			ldx	ramExpSize
			beq	:52
::51			dex
			beq	:52
			lda	BankUsed,x		;Ist Bank belegt ?
			bne	:51 			;Ja, weitersuchen.
			cpy	#0			;schon eine Bank gefunden?
			bne	:52			;>ja
			txa				;>nein dann
			tay				;erste freie Bank sichern
			bne	:51			;und weiter suchen
::52			rts				;Y= 1.freie Bank,  X= 2.freie Bank.
endif

;******************************************************************************
;*** Speicherbelegung.
;******************************************************************************
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

;*** RAM für GEOS/MP3 belegen.
:AllocBankGEOS		lda	#$00
			jsr	AllocBank_GEOS
			lda	MP3_64K_SYSTEM
			jsr	AllocBank_GEOS
			lda	MP3_64K_DATA
			jsr	AllocBank_GEOS
			lda	MP3_64K_DISK
			beq	:51
			jsr	AllocBank_GEOS
			lda	MP3_64K_DISK
			clc
			adc	#$01
			jmp	AllocBank_GEOS
::51			rts

;*** RAM für Anwender belegen.
:AllocBankUser		ldy	#$00			;Reservierte Speicherbänke für
::51			lda	BootBankBlocked,y	;Anwendungsprogramme in Tabelle
			beq	:52			;belegen.
			tya
			jsr	AllocBank_Block
::52			iny
			cpy	ramExpSize
			bcc	:51
			rts

;*** Freie Bank suchen.
;    Übergabe:		yReg	= Anzahl Bänke.
;    Rückgabe:		xReg	= Fehlermeldung.
:GetFreeBank		ldy	#$01			;Nur eine freie Bank suchen.
:GetFreeBankTab		sty	r1L			;Anzahl freier Bänke suchen.
			sty	r1H

			lda	#$00			;Bankzähler löschen.
			sta	r0L
			sta	r0H
::51			ldx	r0L
			lda	BankUsed ,x
			beq	:53			; => Bank verfügbar, weiter...

			lda	#$00			;Flag "Freie Bank gefunden" löschen.
			sta	r0H
			lda	r1L			;Bankzähler wieder zurücksetzen.
			sta	r1H
::52			inc	r0L			;Zeiger auf nächste Bank.
			CmpB	r0L,ramExpSize		;RAM-Erweiterung durchsucht ?
			bcc	:51			;Nein, weiter...
			ldx	#NO_FREE_RAM		;Nicht genügend Speicherbänke frei.
			rts

::53			lda	r0H			;Freie Bank bereits gefunden ?
			bne	:54			;Ja, weiter...
			lda	r0L			;Erste freie RAM-Bank speichern.
			sta	r0H

::54			dec	r1H			;Genügend Bänke gefunden ?
			bne	:52			;Nein, weitersuchen.
			lda	r0H			;Erste freie Bank.
			ldy	r1L			;Anzahl benötigter Speicherbänke.
			ldx	#NO_ERROR		;Kein Fehler.
			rts

;******************************************************************************
;*** Speicherbelegung.
;******************************************************************************
;*** Mehrere Bänke in REU blegen.
;    Übergabe:		AKKU	= Zeiger auf erste Bank.
;			yReg	= Anzahl Bänke.
;    Rückgabe:		xReg	= Fehlermeldung.
:AllocBankT_GEOS	ldx	#BankCode_GEOS
			b $2c
:AllocBankT_Disk	ldx	#BankCode_Disk
			b $2c
:AllocBankT_Task	ldx	#BankCode_Task
			b $2c
:AllocBankT_Spool	ldx	#BankCode_Spool
			b $2c
:AllocBankT_Block	ldx	#BankCode_Block
:AllocateBankTab	sta	r0L
			sty	r0H
			stx	:51a +1
			tya
			beq	:52
::51			lda	r0L			;Zeiger auf aktuelle Bank und
::51a			ldx	#$ff
			jsr	AllocateBank		;Bank in Tabelle belegen.
			txa				;War Bank bereits belegt ?
			bne	:53			;Ja, Abbruch...
			inc	r0L			;Zeiger auf nächste Bank.
			dec	r0H			;Alle Bänke belegt ?
			bne	:51			;Nein, weiter...
::52			ldx	#NO_ERROR		;Kein Fehler...
::53			rts

;*** Bank in Belegungstabelle belegen.
;    Übergabe:		AKKU	= Bank-Adresse.
;    Rückgabe:		xReg	= Fehlermeldung.
:AllocBank_GEOS		ldx	#BankCode_GEOS
			b $2c
:AllocBank_Disk		ldx	#BankCode_Disk
			b $2c
:AllocBank_Task		ldx	#BankCode_Task
			b $2c
:AllocBank_Spool	ldx	#BankCode_Spool
			b $2c
:AllocBank_Block	ldx	#BankCode_Block
:AllocateBank		cmp	ramExpSize
			bcs	:51
			stx	:50 +1
			tax
::50			lda	#$ff
			ldy	BankUsed,x		;Bank bereits belegt ?
			bne	:51			; => Ja, Fehler.
			sta	BankUsed,x
			ldx	#NO_ERROR
			rts
::51			ldx	#NO_FREE_RAM
			rts

;*** Mehrere Bänke in REU freigeben.
;    Übergabe:		AKKU	= Zeiger auf erste Bank.
;			yReg	= Anzahl Bänke.
;    Rückgabe:		xReg	= Fehlermeldung.
:FreeBankTab		sta	r0L
			sty	r0H
			tya
			beq	:52
::51			lda	r0L
			jsr	FreeBank		;Bank freigeben.
			inc	r0L			;Zeiger auf nächste Bank.
			dec	r0H			;Alle Bänke freigegeben ?
			bne	:51			;Nein, weiter...
::52			ldx	#NO_ERROR		;Kein Fehler...
			rts

;*** Bank in Belegungstabelle freigeben.
;    Übergabe:		AKKU	= Bank-Adresse.
;    Rückgabe:		xReg	= Fehlermeldung.
:FreeBank		cmp	ramExpSize
			bcs	:51
			tax
			lda	#$00
			sta	BankUsed,x
::51			ldx	#NO_ERROR
			rts

;******************************************************************************
;*** TaskManager.
;******************************************************************************
;*** TaskManager installieren.
:InitTaskManager	bit	BootTaskMan		;TaskManager installieren ?
			bpl	:52			; => Ja, weiter...
::51			lda	#$ff
			sta	Flag_TaskAktiv
			rts

::52			lda	TASK_COUNT		;Anzahl Tasks > 0 ?
			beq	:51			; => Nein, Abbruch...

			jsr	AutoInitTaskMan		;Automatisch konfigurieren.

			lda	TASK_COUNT		;Konfiguriert ?
			beq	:51			; => Nein, Ende...

			lda	#$ff			;TaskMan-Systembank als "Belegt"
			sta	TASK_BANK_USED		;markieren.
			lda	TASK_BANK_ADDR
			sta	Flag_TaskBank		;TaskMan-Systembank speichern.

			lda	#%00000000		;TaskMan starten.
			sta	BootTaskMan
			sta	Flag_TaskAktiv

			jsr	SetTaskBank
			jsr	FetchRAM

			ldy	#18
::53			lda	TASK_BANK_ADDR      ,y
			sta	R2_ADDR_TASKMAN_E +3,y
			dey
			bpl	:53

if Flag64_128 = TRUE_C128
			ldy	#8
::53a			lda	TASK_BANK0_ADDR      ,y
			sta	R2_ADDR_TASKMAN_E +22+9,y
			lda	TASK_VDC_ADDR      ,y
			sta	R2_ADDR_TASKMAN_E +22,y
			dey
			bpl	:53a
endif

			LoadW	r0,R2_ADDR_TASKMAN_E
			LoadW	r1,R2_ADDR_TASKMAN
			LoadW	r2,R2_SIZE_TASKMAN
			lda	Flag_TaskBank
			sta	r3L
			jmp	StashRAM

;******************************************************************************
;*** TaskManager.
;******************************************************************************
if Flag64_128 = TRUE_C64
;*** TaskMan automatisch installieren.
.AutoInitTaskMan	ldy	#$00
			sty	r0L
			cpy	TASK_COUNT		;Tasks installiert ?
			beq	:52			; => Nein, weiter...

			jsr	FindNxFreeBank		;Freie Bank suchen.
			txa				;Gefunden ?
			beq	:52			; => Nein, Ende...
			sta	TASK_BANK_ADDR		;TaskManager-Systembank definieren.
			lda	#$ff			;Systembank belegen.
			sta	TASK_BANK_USED
			lda	#BankCode_Task		;Bank als belegt kennzeichnen.
			sta	BankUsed      ,x

::51			inc	r0L
			ldy	r0L
			cpy	TASK_COUNT		;TaskManager-RAM reserviert ?
			beq	:52			; => Ja, weiter...

			jsr	FindNxFreeBank		;Freie Bänke für TaskManager
			txa				;belegen.
			beq	:52
			lda	#BankCode_Task
			sta	BankUsed      ,x
			txa
			ldx	r0L
			sta	TASK_BANK_ADDR,x
			jmp	:51

::52			sty	TASK_COUNT
::53			cpy	#MAX_TASK_ACTIV		;Nicht installierte Tasks löschen.
			beq	:54
			lda	#$00
			sta	TASK_BANK_ADDR,y
			sta	TASK_BANK_USED,y
			iny
			bne	:53
::54			rts
endif

;*** Zeiger auf TaskMan in Systemspeicherbank setzen.
:SetTaskBank		lda	#$00
			sta	r0L
			sta	r1L
			sta	r2L
			lda	#> R2_ADDR_TASKMAN_E
			sta	r0H
			lda	#> R2_ADDR_TASKMAN_B
			sta	r1H
			lda	#> R2_SIZE_TASKMAN
			sta	r2H
			lda	MP3_64K_SYSTEM
			sta	r3L
			rts

;******************************************************************************
;*** TaskManager.
;******************************************************************************
if Flag64_128 = TRUE_C128
;*** TaskMan automatisch installieren.
.AutoInitTaskMan	ldy	#$00
			sty	r0L
			cpy	TASK_COUNT		;Tasks installiert ?
			beq	:52a

			jsr	FindNxFreeBank		;Freie Bank suchen.
			txa				;Gefunden ?
			beq	:52a			; => Nein, Ende...
			sta	TASK_BANK_ADDR1		;sichern
			lda	#BankCode_Task		;Bank als belegt kennzeichnen.
			sta	BankUsed      ,x

			jsr	FindNxFreeBank		;Freie Bank suchen.
			txa				;Gefunden ?
			beq	:52b			; => Nein, Ende...
			sta	TASK_VDC_ADDR1		;sichern
			lda	#BankCode_Task		;Bank als belegt kennzeichnen.
			sta	BankUsed      ,x

			jsr	FindNxFreeBank		;Freie Bank suchen.
			txa				;Gefunden ?
			beq	:52c			; => Nein, Ende...
			sta	TASK_BANK0_ADDR1	;sichern
			lda	#BankCode_Task		;Bank als belegt kennzeichnen.
			sta	BankUsed      ,x

			lda	TASK_BANK_ADDR1
			sta	TASK_BANK_ADDR		;TaskManager-Systembank definieren.
			lda	TASK_BANK0_ADDR1
			sta	TASK_BANK0_ADDR		;TaskManager-Systembank definieren.
			lda	TASK_VDC_ADDR1
			sta	TASK_VDC_ADDR		;TaskManager-Systembank definieren.
			lda	#$ff			;Systembank belegen.
			sta	TASK_BANK_USED
			jmp	:51

::52c			ldx	TASK_VDC_ADDR1
			lda	#0			;Bank wieder freigeben
			sta	BankUsed      ,x
::52b			ldx	TASK_BANK_ADDR1
			lda	#0			;Bank wieder freigeben
			sta	BankUsed      ,x
::52a			jmp	:52

::51			inc	r0L
			ldy	r0L
			cpy	TASK_COUNT		;TaskManager-RAM reserviert ?
			beq	:52			; => Ja, weiter...

			jsr	FindNxFreeBank		;Freie Bank suchen.
			txa				;Gefunden ?
			beq	:52			; => Nein, Ende...
			sta	TASK_BANK_ADDR1		;sichern
			lda	#BankCode_Task		;Bank als belegt kennzeichnen.
			sta	BankUsed      ,x

			jsr	FindNxFreeBank		;Freie Bank suchen.
			txa				;Gefunden ?
			beq	:52f			; => Nein, Ende...
			sta	TASK_VDC_ADDR1		;sichern
			lda	#BankCode_Task		;Bank als belegt kennzeichnen.
			sta	BankUsed      ,x

			jsr	FindNxFreeBank		;Freie Bank suchen.
			txa				;Gefunden ?
			beq	:52e			; => Nein, Ende...
			sta	TASK_BANK0_ADDR1	;sichern
			lda	#BankCode_Task		;Bank als belegt kennzeichnen.
			sta	BankUsed      ,x

			ldx	r0L
			lda	TASK_BANK_ADDR1
			sta	TASK_BANK_ADDR,x
			lda	TASK_BANK0_ADDR1
			sta	TASK_BANK0_ADDR,x
			lda	TASK_VDC_ADDR1
			sta	TASK_VDC_ADDR,x
			jmp	:51

::52e			ldx	TASK_VDC_ADDR1
			lda	#0			;Bank wieder freigeben
			sta	BankUsed      ,x
::52f			ldx	TASK_BANK_ADDR1
			lda	#0			;Bank wieder freigeben
			sta	BankUsed      ,x
::52			sty	TASK_COUNT
::53			cpy	#MAX_TASK_ACTIV		;Nicht installierte Tasks löschen.
			beq	:54
			lda	#$00
			sta	TASK_BANK_ADDR,y
			sta	TASK_BANK0_ADDR,y
			sta	TASK_VDC_ADDR,y
			sta	TASK_BANK_USED,y
			iny
			bne	:53
::54			rts
endif

;******************************************************************************
;*** Druckerspooler.
;******************************************************************************
;*** Spooler aktivieren.
:InitPrntSpooler	bit	BootSpooler		;TaskManager installieren ?
			bmi	:52			; => Ja, weiter...
::51			lda	#$00
			sta	Flag_Spooler
			rts

::52			lda	BootSpoolSize		;Anzahl Tasks > 0 ?
			beq	:51			; => Nein, Abbruch...

			jsr	AutoInitSpooler		;Spooler-RAM installieren.

			lda	BootSpooler
			sta	Flag_Spooler
			lda	BootSpoolCount
			sta	Flag_SpoolCount
			lda	Flag_SpoolMinB
			sta	Flag_SpoolADDR +2
			lda	#$00
			sta	Flag_SpoolADDR +1
			sta	Flag_SpoolADDR +0
			rts

;*** Spooler automatisch installieren.
.AutoInitSpooler	lda	BootSpoolSize
			sta	r0L			;Spooler-RAM installiert ?
			beq	:53			; => Nein, weiter...

			jsr	FindNxFreeBank		;Freie Speicherbank suchen.
			txa				;Speicherbank gefunden ?
			beq	:53			; => Nein, Ende...

			stx	Flag_SpoolMaxB		;Mind. 64K für Spooler reservieren.
			bne	:52

::51			jsr	FindNxFreeBank		;Freie Speicherbank suchen.
			txa				;Speicherbank gefunden ?
			beq	:53			; => Nein, Ende...

::52			stx	Flag_SpoolMinB
			lda	#BankCode_Spool
			sta	BankUsed ,x

			dec	r0L
			bne	:51

::53			jsr	GetMaxSpool		;Größe SpoolerRAM ermitteln und
			sty	BootSpoolSize		;zwischenspeichern.
			tya
			beq	:54
			lda	#%10000000
::54			sta	BootSpooler
			tax
			bne	:55
			sta	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
::55			rts

;******************************************************************************
;*** Bildschirmschoner.
;******************************************************************************
;*** Neuen Bildschirmschoner installieren.
;    r6 = Zeiger auf Dateiname.
.InitScrSaver		jsr	OpenDisk		;Wichtig wegen Native-LW
			jsr	FindFile		;Datei suchen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	SwapScrSaver		;RAM im Bereich ScreenSaver
							;zwischenspeichern.
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r2,R2_SIZE_SCRSAVER
			LoadW	r7,LD_ADDR_SCRSAVER
			jsr	ReadFile		;ScreenSaver einlesen.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	LD_ADDR_SCRSVINIT	;ScreenSaver initialisieren.
;--- Ergänzung: 20.07.18/M.Kanet
;In der Version von 1999-2003 wurde nicht auf Initialisierungsfehler
;geprüft. 64erMove kann z.B. nicht verwendet werden wenn kein freier
;Speicher verfügbar ist.
			txa				;Initialisierung OK?
			beq	:50			;Ja, weiter...
			pha
			LoadW	r0,Dlg_IntScrSvEr
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			pla				;Fehler-Register zurücksetzen.
			tax
			lda	Flag_ScrSaver		;ScreenSaver abschalten, da die
			ora	#%10000000		;Initialisierung fehlgeschlagen
			sta	Flag_ScrSaver		;ist (z.B. kein freier Speicher).
			jmp	:51

;--- Ergänzung: 01.07.18/M.Kanet
;In der Version von 1999-2003 wurde hier der Bildschirmschoner grundsätzlich
;neu gestartet auch wenn dieser deaktiviert war.
;An dieser Stelle sollte nur das "Neustart"-Bit gesetzt werden.
::50			lda	Flag_ScrSaver		;Dazu nur das "Initialize"-Bit
			ora	#%01000000		;setzen, da ggf. Bit#7 "On/Off"
			sta	Flag_ScrSaver		;gesetzt ist.

			ldx	#NO_ERROR

::51			txa
			pha
			jsr	SwapScrSaver		;ScreenSaver in RAM kopieren.
			pla
			tax
::52			rts

;*** Aktuellen Bildschirmschoner einlesen.
.SwapScrSaver		jsr	SetADDR_ScrSaver
			jmp	SwapRAM

;******************************************************************************
;*** Eingabe-/Druckertreiber.
;******************************************************************************
;*** Ersten Druckertreiber auf Diskette suchen/laden.
:InitPrntDevice		lda	#$ff			;Druckername in RAM löschen.
			sta	PrntFileNameRAM

			lda	#<BootPrntName
			ldx	#>BootPrntName
			ldy	BootPrntName		;Druckername definiert ?
			bne	:52			; => Ja, weiter...

			sta	r6L
			stx	r6H
			LoadB	r7L,PRINTER
			jsr	FindSysDevice
			txa
			beq	:51

			lda	#<NoPrntName
			ldx	#>NoPrntName
			bne	:52			; => Nein, Abbruch...

::51			lda	#<BootPrntName
			ldx	#>BootPrntName
::52			sta	r0L
			stx	r0H

;*** Druckertreiber laden.
;    Übergabe:		r0 = Zeiger auf Dateiname.
.LoadPrntDevice		lda	#<BootPrntName
			ldx	#>BootPrntName
			jsr	CopyStrg_Device

:BootPrntDevice		lda	#<PrntFileName
			ldx	#>PrntFileName
			jsr	CopyStrg_Device

;*** Druckertreiber laden.
;    Beim C64 wird damit automatisch der Treiber auch in die
;    Speichererweiterung kopiert.
.GetPrntDrvFile		LoadW	r6 ,PrntFileName
			LoadW	r7 ,PRINTBASE
			LoadB	r0L,%00000001
			jmp	GetFile			;Druckertreiber einlesen.

;--- Ergänzung: 31.12.18/M.Kanet
;*** GeoCalc BugFix aktivieren.
;Die Option reduziert die erlaubte Größe von Druckertreibern im RAM/Spooler
;um 1Byte da GeoCalc ab $7F3F Programmcode nutzt. Dieses Byte ist aber noch
;für Druckertreiber reserviert.
if Flag64_128 = TRUE_C64
.InitGCalcFix		ldx	#$40
			lda	BootGCalcFix
			beq	:1
			dex
::1			stx	GCalcFix1 +4
			stx	GCalcFix2 +4
			rts
endif

;--- Ergänzung: 03.01.19/M.Kanet
;*** QWERTZ-Tastatur aktivieren.
;Damit kann die Tastenbelegung Y/Z getauscht werden.
if Sprache = Deutsch
.InitQWERTZ		lda	BootQWERTZ
			bne	:1
			ldx	#"Z"
			ldy	#"Y"
			jsr	:11
			ldx	#"z"
			ldy	#"y"
			jmp	:10

::1			ldx	#"Y"
			ldy	#"Z"
			jsr	:11
			ldx	#"y"
			ldy	#"z"

::10			stx	key0z
			sty	key0y
			rts
::11			stx	key1z
			sty	key1y
			rts
endif

;*** Ersten Druckertreiber auf Diskette suchen/laden.
:InitInptDevice		lda	#<BootInptName
			ldx	#>BootInptName
			ldy	BootInptName		;Eingabegerät definiert ?
			bne	:52			; => Ja, weiter...

			sta	r6L
			stx	r6H
if Flag64_128 = TRUE_C128
			LoadB	r7L,INPUT_128
else
			LoadB	r7L,INPUT_DEVICE
endif
			jsr	FindSysDevice
			txa
			beq	:51

			lda	#<NoInptName
			ldx	#>NoInptName
			bne	:52			; => Nein, Abbruch...

::51			lda	#<BootInptName
			ldx	#>BootInptName
::52			sta	r0L
			stx	r0H

;*** Eingabetreiber laden.
;    Übergabe:		r0 = Zeiger auf Dateiname.
.LoadInptDevice		lda	#<BootInptName
			ldx	#>BootInptName
			jsr	CopyStrg_Device

:BootInptDevice		lda	#<inputDevName
			ldx	#>inputDevName
			jsr	CopyStrg_Device

;*** Eingabegerät laden.
.GetInpDrvFile		LoadW	r6 ,inputDevName
			LoadB	r0L,%00000001
			LoadW	r7 ,MOUSE_BASE
			jsr	GetFile
			jmp	InitMouse

;*** Dateiname für Eingabe-/Druckertreiber kopieren.
.CopyStrg_Device	sta	r1L
			stx	r1H
			ldx	#r0L
			ldy	#r1L
			jmp	CopyString

;******************************************************************************
;*** Eingabe-/Druckertreiber.
;******************************************************************************
;*** Druckertreiber/Eingabetreiber auf Diskette suchen.
:FindSysDevice		jsr	SetSystemDevice		;Startlaufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:51			; => Ja, weiter...
			jsr	FindDevice		;Treiber suchen.
			txa				;Diskettenfehler ?
			beq	:56			; => Nein, weiter...

;--- Auf allen Laufwerken nach erstem Treiber suchen.
::51			ldx	#8			;Suche initialisieren.
::52			cpx	SysDrive		;Systemlaufwerk untersuchen ?
			beq	:54			; => Ja, übergehen.

			lda	driveType -8,x		;Ist Laufwerk definiert ?
			beq	:54			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, nächstes Laufwerk.

			jsr	FindDevice		;Treiber suchen.
			txa				;Diskettenfehler ?
			beq	:56			; => Nein, weiter...

::53			ldx	curDrive		;Aktuelles Laufwerk einlesen.
::54			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke durchsucht ?
			bcc	:52			; => Nein, weiter...

::55			ldx	#FILE_NOT_FOUND
			rts
::56			ldx	#NO_ERROR
			rts

;*** Druckertreiber-Datei uchen.
:FindDevice		PushW	r6
			PushB	r7L

			LoadB	r7H,$01
			LoadW	r10,$0000
			jsr	FindFTypes		;Druckertreiber suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			lda	r7H
			beq	:51
			ldx	#FILE_NOT_FOUND

::51			PopB	r7L
			PopW	r6
			rts

;******************************************************************************
;*** GEOS-Uhrzeit setzen.
;******************************************************************************
			t "-G3_SetRTC"

;******************************************************************************
;*** Variablen.
;******************************************************************************
.SystemClass		t "src.Edit.Build"

if Flag64_128 = TRUE_C64
.DiskDriver_Class	t "src.Disk.Bld.64"
endif
if Flag64_128 = TRUE_C128
.DiskDriver_Class	t "src.Disk.Bld.128"
endif

.SysDrive		b $00
.SysDrvType		b $00
.SysRealDrvType		b $00
.SysFileName		s 17
.DiskFileDrive		b $00
.DiskDriver_TYPE	b $00
.DiskDriver_INIT	b $00
.DiskDriver_DISK	b $00
.DiskDriver_SIZE	w $0000
.DiskDriver_FName	s 17

if Flag64_128 = TRUE_C64
.Class_ScrSaver		b "ScrSaver64  V1.0",NULL
endif
if Flag64_128 = TRUE_C128
.Class_ScrSaver		b "ScrSaver128 V1.0",NULL
endif
.Class_GeoPaint		b "Paint Image ",NULL

;*** Laufwerksinstallation.
.NewDrive		b $00
.NewDriveMode		b $00
.TurnOnDriveAdr		b $00
.DriveRAMLink		b $00
.CurDriveMode		b $00
.firstBootCopy		b $00
.Flag_ME1stBoot		b $00

;*** Variablen für Laufwerkstausch.
:CurDrvAdr		b $00
:SwapCommand		b "M-W",$77,$00,$02
:NewDrvAdr1		b $00
:NewDrvAdr2		b $00
:OldDrvAdrTab		s $04
:NewDrvAdrTab		s $04
.DriveInUseTab		s $18

;*** Variablen zum Partitionswechsel.
:GP_Command		b "G-P",$ff,$0d
:PartitionData		s 32

;*** Speicher für Belegungstabelle der 64K-Speicherbänke.
.BankUsed		s RAM_MAX_SIZE
.BankCodeTab1		b %11000000,%00110000,%00001100,%00000011
.BankCodeTab2		b %00111111,%11001111,%11110011,%11111100
.BankCode_Move		b $03,$02,$01,$00
.BankType_GEOS		b %11000000,%00110000,%00001100,%00000011
.BankType_Disk		b %10000000,%00100000,%00001000,%00000010
.BankType_Block		b %01000000,%00010000,%00000100,%00000001

;*** RTC-Uhr-Befehle.
:RTC_GetTime		b "T-RD"
:RTC_Type		b $00
:RTC_Drive		b $00
:RTC_DATA		s $09

;*** SmartMouse-Zwischenspeicher.
:RTC_SM_DATA		s $08				;Uhrzeit-Daten.
:RTC_SM_BUF		s $04

if Flag64_128 = TRUE_C128
:TASK_BANK_ADDR1	b $00
:TASK_BANK0_ADDR1	b $00
:TASK_VDC_ADDR1		b $00
endif

;******************************************************************************
;*** Variablen.
;******************************************************************************
;*** Variablen für TaskManager.
.LastSpeedMode		b $00				;$00 =  1 Mhz.
							;$40 = 20 Mhz.
.RL_Aktiv		b $00				;$FF = RAMLink verfügbar.
.SCPU_Aktiv		b $00				;$00 = SuperCPU nicht aktiv.
							;$FF = SuperCPU aktiv.

;*** Installationstexte wenn keine Drucker/Eingabegerät/Diskette verfügbar.
if Sprache = Deutsch
.NoPrntName		b "Kein Drucker!",NULL
.NoInptName		b "Keine Maus!",NULL
.StdDiskName		b "(Keine Diskette)",NULL
endif

if Sprache = Englisch
.NoPrntName		b "No printer!",NULL
.NoInptName		b "No mouse!",NULL
.StdDiskName		b "(No disk found) ",NULL
endif

;*** Sprungtabelle für Installationsroutinen der Laufwerkstreiber.
:JumpTable		w a0,TestDriveType
			w a1,TurnOnNewDrive
			w a2,GetFreeBank
			w a3,GetFreeBankTab
			w a4,AllocBank_Disk
			w a5,AllocBankT_Disk
			w a6,FreeBank
			w a7,FreeBankTab
			w a8,SaveDskDrvData
			w a9,FindDriveType

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;*** Dialogbox: Laufwerkstreiber nicht gefunden.
.Dlg_NoDskFile		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$20,$36
			w :3
			b DBTXTSTR   ,$0c,$42
			w :4
			b OK         ,$01,$50
			b NULL

if Sprache ! Flag64_128 = Deutsch ! TRUE_C64
::1			b "Laden der Laufwerkstreiber",NULL
::2			b "ist nicht möglich. Die Datei:",NULL
::3			b "GEOS64.Disk",NULL
::4			b "wurde nicht gefunden!",NULL
endif

if Sprache ! Flag64_128 = Deutsch ! TRUE_C128
::1			b "Laden der Laufwerkstreiber",NULL
::2			b "ist nicht möglich. Die Datei:",NULL
::3			b "GEOS128.Disk",NULL
::4			b "wurde nicht gefunden!",NULL
endif

if Sprache ! Flag64_128 = Englisch ! TRUE_C64
::1			b "Unable to load disk drivers.",NULL
::2			b "The system-file:",NULL
::3			b "GEOS64.Disk",NULL
::4			b "was not found on any drive!",NULL
endif

if Sprache ! Flag64_128 = Englisch ! TRUE_C128
::1			b "Unable to load disk drivers.",NULL
::2			b "The system-file:",NULL
::3			b "GEOS128.Disk",NULL
::4			b "was not found on any drive!",NULL
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;*** Dialogbox: "Startlaufwerk wurde nicht gefunden".
.Dlg_LdDskDrv		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR ,$0c,$20
			w :1
			b DBTXTSTR ,$0c,$2a
			w :2
			b DBTXTSTR ,$0c,$36
			w :3
			b OK       ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Das Startlaufwerk konnte",NULL
::2			b "nicht konfiguriert werden.",NULL
::3			b "Startvorgang abgebrochen!",NULL
endif

if Sprache = Englisch
::1			b "Not able to configure",NULL
::2			b "the systemdrive.",NULL
::3			b "Systemstart cancelled!",NULL
endif

;*** Dialogbox: "Aktuelle Konfiguration ist ungültig".
.Dlg_IllegalCfg		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR,$0c,$20
			w :1
			b DBTXTSTR,$0c,$2a
			w :2
			b DBTXTSTR,$0c,$36
			w :3
			b OK      ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Die aktuelle Konfiguration",NULL
::2			b "für GEOS ist ungültig.",NULL
::3			b "Bitte Konfiguration ändern!",NULL
endif

if Sprache = Englisch
::1			b "The current configuration",NULL
::2			b "for GEOS is not valid.",NULL
::3			b "Please change configuration!",NULL
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
;*** Dialogbox: Hauptmenü konnte nicht geladen werden!
.Dlg_LdMenuErr		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$0c,$0b
			w Dlg_Titel1
			b DBTXTSTR ,$0c,$20
			w :1
			b DBTXTSTR ,$0c,$2a
			w :2
			b OK       ,$01,$50
			b NULL

if Sprache ! Flag64_128 = Deutsch ! TRUE_C64
::1			b "Programm 'GEOS64.Editor' ist",NULL
::2			b "beschädigt und wird beendet!",NULL
endif

if Sprache ! Flag64_128 = Deutsch ! TRUE_C128
::1			b "Programm 'GEOS128.Editor' ist",NULL
::2			b "beschädigt und wird beendet!",NULL
endif

if Sprache ! Flag64_128 = Englisch ! TRUE_C64
::1			b "Application 'GEOS64.Editor' is",NULL
::2			b "corrupt and will be terminated!",NULL
endif

if Sprache ! Flag64_128 = Englisch ! TRUE_C128
::1			b "Application 'GEOS128.Editor' is",NULL
::2			b "corrupt and will be terminated!",NULL
endif

;*** Dialogbox: Laufwerk einschalten. Geräteadresse = #8 bis #19
.Dlg_SetNewDev		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$0c,$0b
			w Dlg_Titel2
			b DBTXTSTR ,$0c,$20
			w :1

if Sprache = Deutsch
			b DBTXTSTR ,$0c,$2a
			w :2
			b DBTXTSTR ,$0c,$40
			w TxNDrv2
			b OK       ,$01,$50
			b CANCEL   ,$11,$50
			b NULL

::1			b "Bitte schalten Sie jetzt",NULL
::2			b "das neue Laufwerk "
:TxNDrv1		b "x: ein!",NULL
:TxNDrv2		b PLAINTEXT
			b "(Geräteadresse #8 bis #19)",NULL
endif

if Sprache = Englisch
			b DBTXTSTR,$0c,$40
			w TxNDrv2
			b OK      ,$01,$50
			b CANCEL  ,$11,$50
			b NULL

::1			b "Please switch on drive "
:TxNDrv1		b "x: !",NULL
:TxNDrv2		b PLAINTEXT
			b "(Set adress from #8 to #19)",NULL
endif

if Sprache = Deutsch
.Dlg_Titel1		b PLAINTEXT,BOLDON
			b "Fehlermeldung",NULL
.Dlg_Titel2		b PLAINTEXT,BOLDON
			b "Information",NULL
endif

if Sprache = Englisch
.Dlg_Titel1		b PLAINTEXT,BOLDON
			b "Systemerror",NULL
.Dlg_Titel2		b PLAINTEXT,BOLDON
			b "Information",NULL
endif

;*** Bildschirmschoner - Installation fehlgeschlagen.
:Dlg_IntScrSvEr		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$10,$0b
			w Dlg_Titel2
			b DBTXTSTR   ,$10,$20
			w :1
			b DBTXTSTR   ,$10,$2b
			w :2
			b DBTXTSTR   ,$10,$3b
			w :3
			b OK         ,$02,$50
			b NULL

if Sprache = Deutsch
::1			b PLAINTEXT
			b "Der Bildschirmschoner konnte",NULL
::2			b "nicht installiert werden!",NULL
::3			b "Installation abgebrochen.",NULL
endif
if Sprache = Englisch
::1			b PLAINTEXT
			b "Unable to install the",NULL
::2			b "screen saver!",NULL
::3			b "Installation cancelled.",NULL
endif

;******************************************************************************
;*** Ladeadresse für Hauptmenü.
;*** Die folgenden Routinen werden nur beim Programmstart benötigt. Danach
;*** werden die Routinen durch das Hauptmenü überschrieben.
;******************************************************************************
.VLIR_BASE
.VLIR_SIZE		= LD_ADDR_REGISTER - VLIR_BASE

;******************************************************************************
;*** MegaPatch installiert ?
;******************************************************************************
			t "-G3_FindMP"
;******************************************************************************

if Flag64_128 = TRUE_C128
;---Ergänzung: 05.03.19/M.Kanet
;Der Code zum testen auf SD2IEC-Laufwerke und DiskImage-Wechsel
;wird beim C128 als Vlir#3-Datensatz eingebunden, beim Start
;eingelesen und nach Bank#0 ab $3x00-$4000 verschoben.
;Von hier aus wird die Routine in Bank#1 eingelesen und ausgeführt.
;Der gewählte Bereich ab $3x00 scheint aktuell nicht genutzt zu
;werden, ist aber nicht dokumentiert.
:LoadSDTools		jsr	FindSystemFile		;Systemdatei suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			LoadW	r2,SizeSDTools
			LoadW	r7,Base1SDTools
			lda	#$02
			jsr	LoadSysRecord		;Zeiger auf SD-Tools.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			LoadW	r0,Base1SDTools
			LoadW	r1,Base0SDTools
			LoadW	r2,SizeSDTools
			LoadB	r3L,$01			;SD-Routinen aus Bank#1 nach
			LoadB	r3H,$00			;Bank#0 sichern.
			jmp	MoveBData
::1			jmp	LdMenuError
endif

;******************************************************************************
;*** TaskManager.
;******************************************************************************
;*** Ist TaskManager aktiv ?
;    Ja, dann Warnung ausgeben...
:ChkTaskMan		bit	firstBoot		;GEOS-BootUp ?
			bpl	:54			; => Ja, weiter...
			bit	Flag_TaskAktiv		;Ist TaskManager installiert ?
			bmi	:54			; => Nein, weiter...

			jsr	SetTaskBank		;Zeiger auf TaskManager und
							;Variablen einlesen.
			lda	#> R2_ADDR_TASKMAN
			sta	r1H
			lda	Flag_TaskBank
			sta	r3L
			jsr	FetchRAM

			ldy	#$01
			ldx	#$00
::51			lda	R2_ADDR_TASKMAN_E +3 +9,y
			beq	:52
			inx
::52			iny
			cpy	#MAX_TASK_ACTIV
			bne	:51
			txa
			beq	:54

			lda	#<Dlg_TaskAktiv		;Fehlermeldung ausgeben.
			ldx	#>Dlg_TaskAktiv
			jsr	SystemDlgBox

			lda	sysDBData
			cmp	#YES
			beq	:53
			jmp	EnterDeskTop

;--- TaskManager abschalten.
::53			lda	#< xEnterDeskTop	;Vector in ":EnterDeskTop" wieder
			sta	EnterDeskTop +1		;zurücksetzen. Bei geöffneten Tasks
			lda	#> xEnterDeskTop	;zeigt diese Routine auf den Task-
			sta	EnterDeskTop +2		;Manager...
::54			rts

;*** Dialogbox: Konfiguration kann nicht gespeichert werden.
:Dlg_TaskAktiv		b %01100001
			b $30,$97
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$0c,$0b
			w Dlg_Titel2
			b DBTXTSTR ,$0c,$20
			w :52
			b DBTXTSTR ,$0c,$2a
			w :53
			b DBTXTSTR ,$0c,$38
			w :54
			b DBTXTSTR ,$0c,$46
			w :55
			b YES      ,$01,$50
			b CANCEL   ,$11,$50
			b NULL

if Sprache = Deutsch
::52			b "Es sind weitere Anwendungen",NULL
::53			b "im TaskManager geöffnet!",NULL
::54			b "Alle Anwendungen beenden ?",NULL
::55			b "Achtung evtl. Datenverlust!",NULL
endif

if Sprache = Englisch
::52			b "No other Applications can be",NULL
::53			b "open when starting the GEOS.Editor!",NULL
::54			b "Close all Applications ?",NULL
::55			b "All unsaved data will be lost!",NULL
endif

;******************************************************************************
;*** Startlaufwerk aktualisieren.
;******************************************************************************
;*** Startlaufwerk in Konfigurationsdaten einbinden.
;    Wenn Startlaufwerk nicht korrekt in ":BootConfig" angegeben ist (wenn z.B.
;    von der RAMLink mit einer anderen Geräteadresse gebootet wurde) dann
;    kann es zu Problemen bei der Laufwerksinstallation kommen.
;    Deshalb sucht der Editor hier in der Konfigurationstabelle nach dem
;    Startlaufwerkstyp. Stimmt die Adresse, wird die Routine beendet.
;    Im anderen Fall wird nach dem Laufwerkstyp gesucht. Wird dieser in der
;    Tabelle gefunden, so werden die beiden Laufwerke getauscht.
;    Die Laufwerksadresse des zweiten Laufwerks wird später automatisch
;    geändert.
:ChkBootConf		bit	firstBoot		;GEOS-BootUp ?
			bpl	:52			; => Ja, weiter...
::51			rts

;--- Startpartition auf RAMLink ermitteln.
::52			lda	SysRealDrvType		;Laufwerkstyp einlesen.
			and	#%11110000		;RAMLink-Laufwerk ?
			cmp	#DrvRAMLink
			bne	:53			; => Nein, weiter...

			jsr	FindCurRLPart		;Aktive RAMLink-Partition suchen.

;--- Startlaufwerk mit Bootkonfiguration vergleichen.
::53			ldy	SysDrive		;Stimmt Startlaufwerk mit
			lda	SysRealDrvType		;gespeicherter Konfiguration im
			cmp	BootConfig  -8,y	;GEOS.Editor überein ?
			bne	:53a			; => Nein, Konfiguration ändern...

			and	#%11110000		;Startlaufwerk stimmt.
			cmp	#DrvRAMLink		;RAMLink-Laufwerk ?
			bne	:51			; => Nein, Ende...

			lda	BootPartRL  -8,y
			cmp	r5L			;Stimmt Start-Partition ?
			beq	:51			; => Ja, Ende...

;--- Startlaufwerk in Bootkonfiguration anpassen.
::53a			lda	#$00			;Suchen des Startlaufwerktyps in der
			sta	r0H			;Konfigurationstabelle.

			ldx	#8
::54			lda	BootConfig  -8,x
			cmp	SysRealDrvType
			bne	:56

			lda	r0H
			bne	:55
			stx	r0H

::55			lda	BootConfig  -8,x
			and	#%11110000
			cmp	#DrvRAMLink		;RAMLink ?
			bne	:57			; => Nein, Laufwerke tauschen...

			lda	BootPartRL  -8,x	;Stimmt Partition mit Startpartition
			cmp	r5L			;überein ?
			beq	:57			; => Ja, Laufwerke tauschen...

::56			inx
			cpx	#12			;Alle Laufwerke untersucht ?
			bcc	:54			; => Nein, weiter...

			ldx	r0H			;Startlaufwerk gefunden ?
			beq	:59			; => Nein, Ende...

::57			lda	BootConfig  -8,x	;Laufwerkstyp gefunden.
			pha				;Konfiguration anpassen.
			lda	BootPartRL  -8,x
			pha
			lda	BootConfig  -8,y
			sta	BootConfig  -8,x
			lda	BootPartRL  -8,y
			sta	BootPartRL  -8,x
			pla
			sta	BootPartRL  -8,y
			pla
			sta	BootConfig  -8,y

::58			ldx	SysDrive
			lda	SysRealDrvType
			sta	BootConfig  -8,x
			lda	r5L
			sta	BootPartRL  -8,x
::59			rts

;******************************************************************************
;*** Aktive Partition finden.
;******************************************************************************
;*** Partition suchen.
;    Übergabe:		AKKU = Laufwerk.
;    Rückgabe:		r5L  = Aktive Partition.
.FindCurRLPart		ldx	#$01			;Zeiger auf ersten Sektor des
			stx	RLtr			;Partitions-Verzeichnisses.
			dex
			stx	RLse
			stx	r5L			;Flag "Partition gefunden" löschen.
			dex				;System-Partition aktivieren.
			stx	RLcp
			lda	#>diskBlkBuf
			sta	RLC64hi
			lda	#<diskBlkBuf
			sta	RLC64lo

;*** Verzeichnis-Sektoren nach Partitionen durchsuchen.
:GetNxPDirSek		jsr	GetRL_Sektor		;Sektor einlesen.

			lda	#$00			;Zeiger auf ersten Eintrag.
			sta	r0L
			sta	r0H
:TestNxEntry		lda	r5L			;Partition #0 ?
			beq	Pos2NxEntry		; => Ja, übergehen...

			lda	r0L
			asl
			asl
			asl
			asl
			asl
			tay
			ldx	#$00			;Partitionseintrag kopieren.
::51			lda	diskBlkBuf  +2,y
			sta	dirEntryBuf +0,x
			iny
			inx
			cpx	#30
			bne	:51

			ldx	dirEntryBuf		;Partitionstyp nach GEOS
			beq	Pos2NxEntry		;konvertieren.
			dex
			bne	:52
			ldx	#$04
::52			stx	dirEntryBuf

			ldx	SysDrive		;Startadresse Partition in RAMLink
			lda	dirEntryBuf +20		;mit aktiver GEOS-Partition ver-
			cmp	ramBase     - 8,x	;gleichen. Abbruch wenn Partition
			bne	Pos2NxEntry		;gefunden wurde.
			rts

;*** Zeiger auf nächsten Verzeichnis-Eintrag setzen.
:Pos2NxEntry		inc	r5L
			inc	r0L			;Zeiger auf nächsten Eintrag im
			lda	r0L			;Partitions-Verzeichnis.
			cmp	#$08			;Verzeichnis-Sektor durchsucht ?
			bne	TestNxEntry		;Nein, weiter...
			inc	RLse
			lda	RLse
			cmp	#$05			;Letzter Verzeichnis-Sektor ?
			bne	GetNxPDirSek		;Nein, weiter...

			lda	#$00			;Flag setzen:
			sta	r5L			;"Erste Partition suchen".
			rts

if Flag64_128 = TRUE_C64
;******************************************************************************
;*** Aktive Partition finden.
;******************************************************************************
;*** Sektor aus RAMLink einlesen.
:GetRL_Sektor		php
			sei
			lda	CPU_DATA
			pha
			lda	#$36			;ROM aktivierern.
			sta	CPU_DATA

			jsr	$e0a9			;RL-Kernal aktivieren.

			lda	RLtr			;Track/Sektor.
			sta	$de21
			lda	RLse
			sta	$de22
			lda	RLC64lo			;Ziel-Addresse.
			sta	$de23
			lda	RLC64hi
			sta	$de24

			lda	RLcp			;RL-Partition.
			sta	$de25
			lda	#$01			;Bank für C128.
			sta	$de26

			lda	#$80			;RL-Job.
			sta	$de20
			asl				;Keine Ahnung wozu...
			sta	$de1a			;Evtl. für alte RAMLinks nötig.

			jsr	$fe09			;Job ausführen und
			jsr	$fe0f			;RL-Kernal abschalten.

			pla
			sta	CPU_DATA		;GEOS-Kernal wieder einschalten.

			plp
			rts
endif

if Flag64_128 = TRUE_C128
;******************************************************************************
;*** Aktive Partition finden.
;******************************************************************************
;*** Sektor aus RAMLink einlesen.
:GetRL_Sektor		php				;IRQ-Status zwischenspeichern
			sei				;und IRQs sperren.
			PushB	MMU			;Konfiguration sichern
			LoadB	MMU,%01001110		;Ram1 bis $bfff + IO + Kernal
							;I/O-Bereich und Kernal für
							;RAMLink-Transfer aktivieren.
			PushB	RAM_Conf_Reg		;Konfiguration sichern
			and	#%11110000
			ora	#%00000100		;Common Area $0000 bis $0400
			sta	RAM_Conf_Reg

			jsr	$e0a9			;RL-Kernal aktivieren.

			lda	RLtr			;Track/Sektor.
			sta	$de21
			lda	RLse
			sta	$de22
			lda	RLC64lo			;Ziel-Addresse.
			sta	$de23
			lda	RLC64hi
			sta	$de24

			lda	RLcp			;RL-Partition.
			sta	$de25
			lda	#$01			;Bank für C128.
			sta	$de26

			lda	#$80			;RL-Job.
			sta	$de20
			asl				;Keine Ahnung wozu...
			sta	$de1a			;Evtl. für alte RAMLinks nötig.

			jsr	$fe09			;Job ausführen und
			jsr	$fe0f			;RL-Kernal abschalten.

			PopB	RAM_Conf_Reg		;Konfiguration rücksetzen
			PopB	MMU			;Konfiguration rücksetzen
			plp				;IRQ-Status zurücksetzen.
			rts
endif

;*** Sektordaten für RL-Sektor-Transfer.
:RLtr			b $00
:RLse			b $00
:RLcp			b $00
:RLC64lo		b $00
:RLC64hi		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_AUTO_BOOT
;******************************************************************************
