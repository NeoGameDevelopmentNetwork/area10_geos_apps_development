; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Dieses Programm installiert das MegaPatch im laufwenden GEOS-System.
;Wird das Programm über das Setup gestartet, so wird im Anschluß die
;Konfiguration gespeichert und die Diskette bootfähig gemacht.
;Wichtig: Das Programm ermittelt die Größe des verfügbaren Speichers
;         automatisch. Ist eine 2Mb-REU angeschlossen, aber das aktuelle
;         GEOS verwendet nur 1Mb, dann darf während des Updates nicht mehr
;         als 1Mb Speicher für MP3 bereitgestellt werden.
;         Der andere Speicher oberhalb des für GEOS verfügbaren Speichers
;         könnte durch eine andere Anwendung (evtl. BASIC) belegt sein!!!
;         Der volle Speicher wird erst beim GEOS-Neustart über BASIC
;         für MP3 freigegeben!!!
;******************************************************************************

			n "GEOS128.MP3"

			t "G3_SymMacExt"
			t "G3_V.Cl.128.Apps"

			o $0400				;BASIC-Start beachten!
			p MainInit

			z $40				;40Z und 80Z.

			i
<MISSING_IMAGE_DATA>

;--- Infoblock definieren.
;Hinweis: Die ersten beiden Zeichen geben darüber Auskunft ob
;die Laufwerkskonfiguration über den Editor gespeichert werden soll (+) und
;ob GEOS.MakeBoot ausgeführt werden soll (+).
;Nach dem Update sind beide Flags gelöscht (-).
if Sprache = Deutsch
			h "++: MegaPatch installieren"
			h "+/- Laufwerke speichern"
			h "+/- Bootdisk erstellen"
endif
if Sprache = Englisch
			h "++: Install MegaPatch"
			h "+/- Configure disk drives"
			h "+/- Create Bootdisk"
endif

if .p
			t "s.GEOS128.1.ext"
			t "s.GEOS128.2.ext"
			t "s.GEOS128.3.ext"
			t "s.GEOS128.4.ext"
			t "s.GEOS128.BO.ext"
			t "o.Patch_SCPU.ext"
			t "o.DvRAM_GRAM.ext"
endif

;*** Bildschirm-Ausgabe initialisieren.
:MainInit		jsr	GetUpdateConfig		;Benutzerkonfiguration einlesen.

			jsr	GetAllSerDrive		;Alle Laufwerke erkennen.

			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
			b	$00

;--- Ergänzung: 02.09.18/M.Kanet
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

			LoadW	r0,ScreenInitData	;Bildschirm löschen.
			jsr	GraphicsString

			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
			b	$03

			jsr	i_FillRam
			w	40 * 2
			w	COLOR_MATRIX +40 * 0
			b	$16

			bit	graphMode
			bpl	:40a			;>40 Zeichen
			LoadW	r3,0
			LoadW	r4,639
			LoadB	r2L,0
			LoadB	r2H,199
			lda	#$07
			jsr	ColorRectangle		;GEOS 2.0 DirectColor-Routine !

			LoadW	r3,0
			LoadW	r4,639
			LoadB	r2L,0
			LoadB	r2H,2*8-1
			lda	#$f2
			jsr	ColorRectangle		;GEOS 2.0 DirectColor-Routine !

;--- Dialogbox-Routine korrigieren.
::40a			lda	RecoverVector +0
			sta	RecoverVecBuf +0
			lda	RecoverVector +1
			sta	RecoverVecBuf +1

			lda	#< ClrDlgBoxArea
			sta	RecoverVector +0
			lda	#> ClrDlgBoxArea
			sta	RecoverVector +1

;--- Update initialisieren.
			lda	curDrive		;Startlaufwerk einlesen und
			sta	Device_Boot		;zwischenspeichern.
			jsr	SetDevice
			jsr	PurgeTurbo

			jsr	GetRandom		;Zufallszahl ermitteln. Wird später
							;zur Erkennung der REU benötigt.
			ldx	#$02			;Aktuelles Datum zwischenspeichern.
::51			lda	year      ,x
			sta	DateBuffer,x
			dex
			bpl	:51

;*** RAMLink/SuperCPU erkennen.
			sei				;IRQ sperren.
			cld				;Dezimal-Flag löschen.
			ldx	#$ff			;Stack-Pointer löschen.
			txs

;--- Ergänzung: 21.07.18/M.Kanet
;Setzen der MMU Register vor der Abfrage in $d0bc.
;I/O-Bereich sollte bereits aktiv sein, nur zur Sicherheit.
			lda	MMU
			pha
			lda	#%01001110		;ROM ab $c000 aktiv + IO
			sta	MMU

			ldx	#$ff			;SuperCPU verügbar ?
			lda	$d0bc
			bpl	:52			; => Ja, weiter...
			inx
::52			stx	Device_SCPU		;SCPU-Flag speichern.

			ldx	#$ff			;RAMLink verügbar ?
			lda	EN_SET_REC
			cmp	#$78
			beq	:53			; => Ja, weiter...
			inx
::53			stx	Device_RL		;RAMLink-Flag speichern.

;*** Erkennen der Speichererweiterung initialisieren.
:DetectCurRAM		ldy	#$0f			;Prüfsumme für Suche nach der
::51			tya				;Speichererweiterung definieren.
			eor	random +0		;Achtung! Unbedingt bei jedem
			eor	$d012			;Start neu und zufällig definieren!
			sta	RAM_TEST_CODE,y
			lda	random +1
			eor	$d012
			eor	RAM_TEST_CODE,y
			sta	RAM_TEST_CODE,y
			dey
			bpl	:51

			pla				;GEOS-RAM-Bereich wieder einblenden.
			sta	MMU

			LoadW	r0 ,RAM_TEST_BUF	;Für die RAM-Erkennung wird hier der
			LoadW	r1 ,$0000		;Testbereich in der REU mit einer
			LoadW	r2 ,$10			;Kennung versehen. Sind mehrere
			LoadB	r3L,$00			;RAMs vorhanden, kann so die aktive
			jsr	FetchRAM		;REU erkannt werden.
			LoadW	r0 ,RAM_TEST_CODE
			jsr	StashRAM

			jsr	FindActiveDACC		;Speichererweiterung feststellen.

			LoadW	r0 ,RAM_TEST_BUF	;Inhalt der REU wieder herstellen.
			LoadW	r1 ,$0000
			LoadW	r2 ,$10
			LoadB	r3L,$00
			jsr	StashRAM

;*** GEOS-Kernel installieren.
:InstallMP3		ldx	ExtRAM_Size		;Genügend erweiterter Speicher für
			bne	:50			;MP3 verfügbar ?
			jmp	ExitUpdate		; => Nein, zurück zum DeskTop.

::50			jsr	CheckSizeRAM		;Genügend erweiterter Speicher für
							;RAM-Laufwerke verfügbar ?

			ldx	ExtRAM_Size		;Speicherbank für MP3-Kernel
			dex				;definieren
			stx	InstallBank64K

			jsr	resetSCPU_RAM		;SuprCPU-RAMLaufwerk freigeben.

			jsr	RetainInpDev		;Eingabetreiber suchen.

			lda	Device_Boot		;Startlaufwerk aktivieren.
			jsr	SetDevice

			jsr	LoadSysDiskDev		;Laufwerkstreiber aktualisieren.

			jsr	LoadSysBootData		;Datei "GEOS128.BOOT" nachladen.
							;Diese Datei enthält die Daten für
							;ReBoot und die Installationsdaten
							;für das ext. MP3-kernel.

			ldx	#8			;TurboDOS in allen Laufwerken
::51			lda	driveType -8,x		;deaktivieren.
			beq	:52
			txa
			jsr	SetDevice
			jsr	OpenDisk
			jsr	PurgeTurbo
			ldx	curDrive
::52			inx
			cpx	#12
			bcc	:51

			lda	Device_Boot
			jsr	SetDevice		;Startlaufwerk aktivieren.
			jsr	PurgeTurbo		;TurboDOS abschalten.

			ldy	#$03			;Laufwerksinformationen in
::53			lda	driveType     ,y	;Zwischenspeicher retten, da
			sta	driveType_buf ,y	;während des Updatevorgangs der
			lda	ramBase       ,y	;Speicher von $8000-$8FFF komplett
			sta	ramBase_buf   ,y	;gelöscht wird.
			lda	driveData     ,y
			sta	driveData_buf ,y
			lda	doubleSideFlg ,y
			sta	doubleSide_buf,y
			lda	turboFlags    ,y
			sta	turboFlags_buf,y
			dey
			bpl	:53

			jsr	LoadKernel_EXT1		;Kernel-Teil #1 laden.
			jsr	InitKernel_EXT1		;(MP3-Speicherbank)

			jsr	LoadKernel_EXT2a	;Kernel-Teil #2 laden.
			jsr	InitKernel_EXT2a	;(MP3-Speicherbank)

			jsr	LoadKernel_EXT2b	;Kernel-Teil #3 laden.
			jsr	InitKernel_EXT2b	;(MP3-Speicherbank)

			jsr	LoadKernel_RAM0		;Kernel-Teil #4 laden.
			jsr	ProtectKernel_RAM0	;und im Back-Ram zwischenspeichern

			jsr	LoadKernel_RAM		;Kernel-Teil #3 laden.
			jsr	InitKernel_RAM		;(64K RAM Bank 1)

			jsr	InitKernel_RAM0		;64K RAM Bank 0 installieren

			ldy	#$03			;Laufwerksinformationen wieder
::54			lda	driveType_buf ,y	;zurückschreiben.
			sta	driveType     ,y
			lda	ramBase_buf   ,y
			sta	ramBase       ,y
			lda	driveData_buf ,y
			sta	driveData     ,y
			lda	doubleSide_buf,y
			sta	doubleSideFlg ,y
			lda	turboFlags_buf,y
			sta	turboFlags    ,y
			dey
			bpl	:54

;*** Kernel initialisieren.
:InitMP3_Kernel		ldx	InstallBank64K		;Speicherbänke für
			stx	MP3_64K_SYSTEM		;MP3-Kernel festlegen.
			dex
			stx	MP3_64K_DATA
			ldx	#$00			;Laufwerkstreiber von
			stx	MP3_64K_DISK		;Diskette installieren.

			jsr	InitDeviceRAM		;RAM-Patches installieren.
			txa				;Speichertest OK?
			beq	:1			; => Ja, weiter.
			jmp	Err_RamVerErr		;Fehler ausgeben, Ende.

::1			jsr	InitDeviceSCPU		;SuperCPU patchen.

			lda	#%01110000		;Kein MoveData, DiskDriver in REU,
			sta	sysRAMFlg		;ReBoot-Kernel in REU.

			ldy	Device_Boot		;StashRAM erst nachdem neuer
			jsr	InitCurDskDvJob		;RAM-Treiber installiert wurde!
			jsr	StashRAM
			jsr	DoneWithDskDvJob

;--- Ergänzung: 24.12.22/M.Kanet
;In VIC-Bank#0 ist der Bereich von
;$07E8-$07F7 "unused". Für die in GEOS
;aktive VIC-Bank#2 = $8FE8-$8FF7.
;Es gibt im Kernal an keiner Stelle
;einen Zugriff auf diese Adressen, die
;Spritepointer liegen ab $8FF8 und
;werden durch GEOS_Init1 gesetzt.
;
; -> sysApplData
;
;GEOS V2 mit DESKTOP V2 legt hier über
;das Programm "pad color mgr" Farben
;für den DeskTop und Datei-Icons ab.
;Ab $8FE8 finden sich in 8 Byte bzw.
;16 Halb-Nibble die Farben für GEOS-
;Dateitypen 0-15, und ab $8FF0 findet
;sich die Farbe für den Arbeitsplatz.
;
;*** "pad color mgr"-Vorgaben setzen.
::DefPadCol		ldx	#6			;Ungenutzte Bytes
			lda	#$00			;initialisieren.
::50			sta	sysApplData +9,x
			dex
			bpl	:50

;--- Hinweis:
;Wird durch ":FirstInit" initialisiert.
if FALSE
			lda	#$bf			;Standardfarbe Arbeitsplatz.
			sta	sysApplData +8

			ldx	#7			;Standardfarbe für die ersten
			lda	#$bb			;16 GEOS-Dateitypen.
::51			sta	sysApplData +0,x
			dex
			bpl	:51
endif
;---

			lda	#$ff			;TaskSwitcher deaktivieren (da noch
			sta	Flag_TaskAktiv		;nicht installiert... Erst über
							;GEOS64.Editor!!!)
			jsr	FirstInit		;MP3-Kernel initialisieren.
			jsr	SCPU_OptOn		;SCPU aktivieren (auch wenn keine
							;SCPU verfügbar ist!)

			jsr	UseSystemFont		;GEOS-Font aktivieren.

			lda	#$08			;Sektor-Interleave #8.
			sta	interleave

			ldx	#$02			;Aktuelles Datum zwischenspeichern.
::2			lda	DateBuffer,x
			sta	year      ,x
			dex
			bpl	:2

			lda	Device_Boot
			jsr	SetDevice		;Startlaufwerk aktivieren und

			ldx	Device_Boot
			lda	UserPConfig -8,x	;CMD-Partition definiert?
			beq	:skip			; => Nein, weiter...
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.

;--- Ergänzung: 24.03.21/M.Kanet
;Bei 1571 auf Doppelseitig umschalten.
::skip			ldx	curDrive
			lda	driveType -8,x		;RAM-Laufwerk ?
			bmi	:3			; => Ja, weiter...
			lda	DriveInfoTab -8,x
			cmp	#Drv1571		;1571-Laufwerk ?
			bne	:3			; => Nein, weiter...
			lda	doubleSideFlg -8,x
			jsr	Set1571DkMode		;1571-Laufwerksmodus festlegen.

::3			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:4			; => Nein, weiter...
			jmp	Err_DiskError		;Fehlermeldung ausgeben.

;--- RAM-Konfiguration speichern.
::4			jsr	SaveConfigRAM		;GEOS128.BOOT/RBOOT128.BOOT ändern.

;--- Ersten Druckertreiber auf Diskette suchen/laden.
			jsr	Get1stPrntDrv

;--- Ersten Maustreiber auf Diskette suchen/laden.
			jsr	Get1stInputDev

;---  Routine nachladen, welche GEOS128.Editor konfiguriert und die
;     Laufwerke installiert.
			jsr	i_MoveData
			w	obj_Updater
			w	BASE_AUTO_BOOT
			w	(end_Updater - obj_Updater)

			jmp	BASE_AUTO_BOOT

;*** SuperCPU-RAMLaufwerk freigeben.
:resetSCPU_RAM		lda	Device_SCPU		;SCPU Verfügbar ?
			beq	:exit			; => Nein, weiter...

			ldx	#0
::1			lda	UserConfig ,x		;Laufwerksmodus einlesen.
			cmp	#DrvRAMNM_SCPU		;Typ SuperRAM-Laufwerk ?
			beq	:found			; => Ja, weiter...
			inx				;Nächstes Laufwerk testen.
			cpx	#4			;Alle Laufwerke getestet ?
			bcc	:1			; => Nein weiter...
::exit			rts				; => Kein SuperRAM-Laufwerk.

::found			lda	MMU
			pha
			lda	#%01001110		;ROM ab $c000 aktiv + IO
			sta	MMU

			sta	$d07e			;SuperCPU-Register aktivieren.

			lda	#$00			;Erste freie Speicherbank auf
			sta	$d27c			;erste Speicherbank des SuperRAM-
			lda	UserRamBase ,x		;Laufwerks zurücksetzen.
			sta	$d27d

			sta	$d07f			;SuperCPU-Register deaktivieren.

			pla				;GEOS-RAM-Bereich wieder einblenden.
			sta	MMU

			rts

;*** Ersten Druckertreiber auf Diskette laden.
:Get1stPrntDrv		lda	#$ff			;Druckername in RAM löschen.
			sta	PrntFileNameRAM

			LoadW	r6 ,PrntFileName
			LoadB	r7L,PRINTER
			LoadB	r7H,$01
			LoadW	r10,$0000
			jsr	FindFTypes		;Ersten Druckertreiber suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...
			lda	r7H			;Druckertreiber gefunden ?
			bne	:1			; => Nein, Abbruch...

			lda	Flag_LoadPrnt		;Druckertreiber in RAM laden ?
			bne	:1 			; => Nein, Abbruch...

			LoadB	r0L,%00000001
			LoadW	r6 ,PrntFileName
			LoadW	r7 ,PRINTBASE
			jsr	GetFile			;Druckertreiber in RAM kopieren.

::1			rts

;*** Ersten Eingabetreiber auf Diskette suchen.
:Get1stInputDev		LoadW	r6 ,inputDevName
			LoadB	r7L,INPUT_128
			LoadB	r7H,$01
			LoadW	r10,$0000
			jsr	FindFTypes		;Ersten Eingabetreiber suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...
			lda	r7H			;Eingabetreiber gefunden ?
			bne	:1			; => Nein, Abbruch...

			LoadB	r0L,%00000001
			LoadW	r6 ,inputDevName
			LoadW	r7 ,MOUSE_BASE
			jsr	GetFile			;Eingabetreiber installieren.

::1			jsr	InitMouse		;Treiber im Speicher initialisieren.
			rts

;*** Aktuellen Laufwerkstreiber durch MP3-Treiber ersetzen.
;    Wichtig da alte Treiber oder neuere Wheels-Treiber Funktionen im Kernel
;    aufrufen, das neue MP3-Kernel aber bereits installiert ist. Das führt
;    dann zum Systemabsturz. Deshalb wird hier der aktive Treiber durch den
;    MP3-Treiber ersetzt. Die anderen Laufwerke erhalten die neuen Treiber
;    durch den GEOS.Editor.
:LoadSysDiskDev		LoadW	r0 ,FNamGDISK
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...
			jsr	PointRecord		;Zeiger auf ersten Datensatz.
			txa				;Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			LoadW	r2,64 + 64*2 + 64*17
			LoadW	r7,VLIR_Types
			jsr	ReadRecord		;Infos über verfügbare Treiber
			txa				;einlesen. Diskettenfehler ?
			bne	:53			; => Ja, Abbruch...

			ldx	Device_Boot		;In Tabelle Treiber für aktuelles
			lda	UserConfig -8,x		;Laufwerk suchen. Der korrekte
			ldy	#$00			;Laufwerkstyp wird zuvor über
::51			ldx	VLIR_Types,y		;":CheckSizeRAM/:Get_UserConfig"
			beq	:52			;ermittelt und gespeichert.
			cmp	VLIR_Types,y
			beq	:54
::52			iny
			cpy	#63
			bcc	:51

::53			jsr	CloseRecordFile

			LoadW	r0,Dlg_NoDkDvErr	;Treiber nicht gefunden,
			jmp	DoDlgBox		;Installation abbrechen.

::54			tya				;Laufwerkstreiber für aktuelles
			asl				;Laufwerk laden und in REU
			tay				;zwischenspeichern. Der Treiber
			lda	VLIR_Entry +1,y		;darf erst aktiviert werden, wenn
			jsr	PointRecord		;das MP3-Kernel aktiv ist!
			txa
			bne	:53

			LoadW	r2,R1_SIZE_DSKDEV_A
			LoadW	r7,END_OF_FILE
			jsr	ReadRecord
			txa
			bne	:53

			jsr	CloseRecordFile

;--- Ergänzung: 15.09.18/M.Kanet
;Der GeoRAMNative-Treiber benötigt einen Wert zur Bank-Größe der aktuellen
;GeoRAM. Der Wert wird bei der Installation über den GEOS.Editor im Treiber
;gespeichert. An dieser Stelle wird der Treiber aber direkt aus der System-
;datei eingelesen.  Daher muss der Wert für die Bank-Größe hier manuell an
;den Treiber übergeben werden.
;Vorher auf ein aktives MegaPatch-System testen. Ausserhalb von MegaPatch
;gibt es keinen GeoRAMNative-Treiber!
;Ohne diese Anpassung wird bei der Installtion unter MegaPatch von einem
;GeoRAMNative-Laufwerk auf das gleiche GeoRAMNative-Laufwerk einn Wert von
;#00 als BankGröße angesetzt da dies der Standardwert im Treiber ist.
			lda	END_OF_FILE + (DiskDrvTypeCode - $9000) +0
			cmp	#"M"
			bne	:55
			lda	END_OF_FILE + (DiskDrvTypeCode - $9000) +4
			cmp	#"3"
			bne	:55
			ldx	Device_Boot
			lda	UserConfig -8,x		;Aktuellen Laufwerkstyp einlesen.
			cmp	#DrvRAMNM_GRAM		;GeoRAMNative-Laufwerk?
			bne	:55			; => Nein, weiter...

;--- Ergänzung: 27.09.19/M.Kanet
;Die Bank-Größe wird bei der Erkennung des aktuellen GEOS-DACC von der
;Routine ":FindActiveDACC" in "-G3_FindActDACC" gesetzt. Daher muss in
;dieser Routine auch zuerst auf eine GeoRAM getestet werden, damit dieser
;Wert in jedem Fall ermittelt wird.
			lda	GRAM_BANK_SIZE		;Bank-Größe speichern.
			sta	END_OF_FILE + (GeoRAMBSize - $9000)

::55			lda	#<END_OF_FILE
			sta	r0L
			lda	#>END_OF_FILE
			sta	r0H
			ldx	#$00
			stx	r1L
			stx	r1H
			lda	#<R1_SIZE_DSKDEV_A
			sta	r2L
			lda	#>R1_SIZE_DSKDEV_A
			sta	r2H
			stx	r3L
			jmp	StashRAM

;*** Datei "GEOS128.BOOT" nachladen.
;    Diese Datei enthält wichtige Teile für die Installation!
;    Die Startadresse von "GEOS128.BOOT" überschreibt die max. Endadresse
;    dieses Installationsprogramms. Deshalb wird die Datei zuerst an eine
;    freie Stelle im RAM geladen und anschließend nur die benötigten
;    Programmteile an die korrekte Speicheradresse zurückgeschrieben.
;    Benötigter Bereich: 'S_KernelData' bis 'E_KernelData'.
:LoadSysBootData	lda	#<FNamGBOOT		;Systemdatei suchen.
			ldx	#>FNamGBOOT
			jsr	InitLoadSysFile

;--- Bytes bis Systemdaten überlesen.
			LoadW	r4 ,diskBlkBuf
			LoadW	r5 ,$0000
			LoadW	r15,(S_KernelData - L_KernelData)
::51			jsr	ReadByte
			txa
			bne	:54

			ldx	#r15L
			jsr	Ddec
			bne	:51

;--- Systemdaten einlesen.
			LoadW	r14,S_KernelData
			LoadW	r15,(E_KernelData - S_KernelData)
::52			jsr	ReadByte
			cpx	#$00
			bne	:54

			ldy	#$00
			sta	(r14L),y

			inc	r14L
			bne	:53
			inc	r14H

::53			ldx	#r15L
			jsr	Ddec
			bne	:52
			rts

::54			jmp	Err_DiskError

;*** Systemdatei nachladen.
:LoadKernel_RAM0	lda	#<FNamGEOS0		;Datei "GEOS128.0" nachladen.
			ldx	#>FNamGEOS0
			bne	SystemFile
:LoadKernel_RAM		lda	#<FNamGEOS1		;Datei "GEOS128.1" nachladen.
			ldx	#>FNamGEOS1
			bne	SystemFile
:LoadKernel_EXT1	lda	#<FNamGEOS2		;Datei "GEOS128.2" nachladen.
			ldx	#>FNamGEOS2
			bne	SystemFile
:LoadKernel_EXT2a	lda	#<FNamGEOS3		;Datei "GEOS128.3" nachladen.
			ldx	#>FNamGEOS3
			bne	SystemFile
:LoadKernel_EXT2b	lda	#<FNamGEOS4		;Datei "GEOS128.4" nachladen.
			ldx	#>FNamGEOS4

:SystemFile		jsr	InitLoadSysFile
			LoadW	r2,(OS_VARS - BASE_GEOS_SYS128)
			LoadW	r7,BASE_GEOS_SYS128 -2
:SysFile		jsr	ReadFile		;Datei von Diskette laden.
			txa				;Diskettenfehler ?
			bne	Err_DiskError
			jmp	PurgeTurbo		; => Nein, weiter...

;*** Systemdatei suchen.
:InitLoadSysFile	sta	r6L
			stx	r6H
			sta	VecFileName +0
			stx	VecFileName +1
			lda	Device_Boot		;Startlaufwerk aktivieren.
			jsr	SetDevice
			txa				;Laufwerksfehler ?
			bne	Err_DiskError		; => Ja, Abbruch...
			jsr	OpenDisk		;Diskette öffnen und
			txa				;Diskettenfehler ?
			bne	Err_DiskError		; => Ja, Abbruch...

			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			beq	:51			; => Nein, weiter...
			cpx	#$05			;Datei nicht gefunden ?
			beq	Err_FNotFound		;"Datei nicht gefunden".
			bne	Err_DiskError		;"Diskettenfehler".

::51			lda	dirEntryBuf +1		;Zeiger auf ersten Sektor der
			sta	r1L			;Datei setzen.
			lda	dirEntryBuf +2
			sta	r1H
			rts

;*** Fehler: Diskettenfehler.
:Err_DiskError		stx	DskErrCode
			LoadW	r0,Dlg_DiskError
			jmp	DoDlgBox

;*** Fehler: Datei nicht gefunden.
:Err_FNotFound		MoveW	VecFileName,r9
			LoadW	r0,Dlg_FNotFound
			jmp	DoDlgBox

;*** Fehler, zurück zum BASIC.
:Err_RamVerErr		LoadW	r0,Dlg_RamVerError
			jmp	DoDlgBox

;*** Dialogbox-Hintergrund löschen.
:ClrDlgBoxArea		lda	#$01
			jsr	SetPattern
			jmp	Rectangle

;*** Kernel-Teil #1 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS128" im Speicher und wird
;    nach $C000-$FFFF (Bank0) kopiert.
:ProtectKernel_RAM0	LoadW	r0,BASE_GEOS_SYS128	;Kernel Bank 0 im Back-Ram
			LoadW	r1,$2000		;zwischenspeichern
			LoadW	r2,$4000		;Bank 0 kann erst installiert werden
			LoadB	r3L,1			;wenn Bank 1 geladen wurde!
			LoadB	r3H,0
			jmp	MoveBData

:InitKernel_RAM0	sei				;Kernel Bank 0 Installieren
			LoadW	r0,$2000		;Kann nicht direkt mit MoveBData
			LoadW	r1,BASE_GEOS_SYS128	;installiert werden da sonst MoveBData
			LoadW	r2,$4000		;sich selbst überschreibt
			LoadB	r3L,0
			LoadB	r3H,1
			jsr	MoveBData

			LoadB	RAM_Conf_Reg,$4b
			lda	#$7f			;64K-RAM-Bereich einblenden.
			sta	MMU

			LoadW	r0,BASE_GEOS_SYS128	;GEOS-Kernal Bank 0 aus Startdatei
			LoadW	r1,$c000		;nach $C000 kopieren.
			ldy	#$00
::4			lda	(r0L),y			;Daten nach
			sta	(r1L),y			;$c000 (Bank 0)
			iny	 			;bis $feff verschieben
			bne	:4
			inc	r0H
			inc	r1H
			lda	r1H
			cmp	#$ff
			bne	:4

			ldy	#5			;Bereich $ff05 bis $ffff
::3			lda	(r0L),y			;setzen in Bank 0
			sta	(r1L),y
			iny
			bne	:3

			lda	#$7e
			sta	MMU
			LoadB	RAM_Conf_Reg,$40

			rts

;*** Kernel-Teil #1 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS128" im Speicher und wird
;    nach $9000-$9C7F und $BF40-$FFFF kopiert.
:InitKernel_RAM		lda	Device_Boot		;Turbo-Dos entfernen
			jsr	SetDevice
			jsr	PurgeTurbo

			LoadW	r0,BASE_GEOS_SYS128	;Zeiger auf Laufwerkstreiber in
			LoadW	r1,$0000		;Zwischenspeicher Bank#0 setzen.
			LoadW	r2,R1_SIZE_DSKDEV_A
			LoadB	r3L,$00
			jsr	FetchRAM		;Laufwerkstreiber übernehmen.

			sei
			MoveB	screencolors,Sv40ColData
			MoveB	scr80colors ,Sv80ColData

;--- GEOS-Variablenspeicher löschen.
			LoadW	r0,$8000		;Zeiger auf Variablenspeicher.

			ldx	#$10			;Speicherbereich löschen. ACHTUNG!
			ldy	#$00			;Nicht über FillRam, da das GEOS-
			tya				;Kernel zu diesem Zeitpunkt noch
::51			sta	(r0L),y			;nicht wieder installiert ist!
			iny
			bne	:51
			inc	r0H
			dex
			bne	:51

			lda	Sv40ColData		;Bildschirmfarbe löschen.
			ldy	#$00
::52			sta	COLOR_MATRIX +$0000,y
			sta	COLOR_MATRIX +$0100,y
			sta	COLOR_MATRIX +$0200,y
			sta	COLOR_MATRIX +$02e8,y
			iny
			bne	:52

			bit	graphMode
			bpl	:40
			lda	#0
			sta	r3L
			sta	r3H
			sta	r2L
			LoadW	r4,639
			LoadB	r2H,199
			lda	Sv80ColData
			jsr	ColorRectangle

::40			LoadW	r0,BASE_GEOS_SYS128 	;Laufwerkstreiber aus Startdatei
			LoadW	r1,DISK_BASE		;nach $9000 kopieren.

			ldx	#$10
			ldy	#$00
::53			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:53
			inc	r0H
			inc	r1H
			dex
			bne	:53

			lda	#$7f			;64K-RAM-Bereich einblenden.
			sta	MMU
							;GEOS-Kernal Bank 1 aus Startdatei
			LoadW	r1,$c000		;nach $C000 kopieren.
			ldy	#$00
::4			lda	(r0L),y			;Daten nach
			sta	(r1L),y			;$c000 (Bank 1)
			iny	 			;bis $feff verschieben
			bne	:4
			inc	r0H
			inc	r1H
			lda	r1H
			cmp	#$ff
			bne	:4

			ldy	#5			;Bereich $ff05 bis $ffff
::3			lda	(r0L),y			;setzen in Bank 1
			sta	(r1L),y
			iny
			bne	:3

			lda	#$7e
			sta	MMU

			lda	ExtRAM_Type		;RAM-Typ an GEOS übergeben.
			sta	GEOS_RAM_TYP

			lda	ExtRAM_Bank  +0
			sta	RamBankFirst +0
			lda	ExtRAM_Bank  +1
			sta	RamBankFirst +1

			lda	ExtRAM_Size		;Max. RAM-Speicher begrenzen.
			cmp	#RAM_MAX_SIZE		;Wichtig damit nicht mehr RAM-Bänke
			bcc	:56			;aktiviert werden können als in
			lda	#RAM_MAX_SIZE		;":RamBankInUse" reserviert sind.
			sta	ExtRAM_Size
::56			sta	ramExpSize
			rts

;*** Kernel-Teil #2 installieren,ReBoot-Routine in REU kopieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS128" im Speicher und wird
;    in die Speicherbank #1 kopiert.
;--- Ausgelagerte Kernel-Funktionen in RAM kopieren.
:InitKernel_EXT1	lda	#<MP3_BANK_1
			ldx	#>MP3_BANK_1
			ldy	#$09
			jsr	InitKernel_1_2

;--- ReBoot-Kernel in RAM kopieren.
			ldx	#$00			;Zeiger auf ReBoot-Datentabelle.
			lda	GEOS_RAM_TYP		;RAM-Typ einlesen.
			cmp	#RAM_SCPU		;SuperCPU ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_RL			;RAMLink ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_REU		;C=REU ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_BBG		;BBGRAM ?
			beq	:51			;Ja, weiter...
			ldx	#$00

::51			lda	Vec_ReBoot +0,x		;Startadresse für ReBoot-Routine
			sec
			sbc	#<(BASE_GEOS_SYS-BASE_GEOS_SYS128)
			sta	r0L			;einlesen.
			lda	Vec_ReBoot +1,x
			sbc	#>(BASE_GEOS_SYS-BASE_GEOS_SYS128)
			sta	r0H

			lda	#$00
			sta	r1L
			sta	r2L
			sta	r3L
			lda	#>R1_ADDR_REBOOT	;Startadresse in REU.
			sta	r1H
			lda	#>R1_SIZE_REBOOT	;Anzahl Bytes.
			sta	r2H
			jsr	MP3StashRAM		;ReBoot-Routine speichern.
			jsr	MP3VerifyRAM		;ReBoot-Code überprüfen.
			and	#%00100000		;Daten korrekt gespeichert ?
			bne	:52			;Nein, Abbruch...
			rts				;Ende...

::52			jmp	Err_RamVerErr

;*** Kernel-Teil #3 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS128" im Speicher und wird
;    in die Speicherbank #1 kopiert.
:InitKernel_EXT2a	lda	#<MP3_BANK_2a
			ldx	#>MP3_BANK_2a
			ldy	#$03
			jmp	InitKernel_1_2

;*** Kernel-Teil #3 installieren.
;    Programmcode liegt ab ":BASE_GEOS_SYS128" im Speicher und wird
;    in die Speicherbank #1 kopiert.
:InitKernel_EXT2b	lda	#<MP3_BANK_2b
			ldx	#>MP3_BANK_2b
			ldy	#$03

;*** Programmdaten in Speicherbank #1 kopieren.
;    Übergabe:		AKKU = LowByte -Tabelle,
;			xReg = HighByte-Tabelle,
;			yReg = Anyahl Datenblöcke.
:InitKernel_1_2		sta	:53 +1			;Tabellenzeiger speichern.
			stx	:53 +2
			sty	:54 +1

			lda	#$00			;Kernel-Funktionen in REU
::51			pha				;kopieren.
			asl
			sta	:52 +1
			asl
			clc
::52			adc	#$ff
			tay
			ldx	#$00
::53			lda	$ffff,y			;Zeiger auf Position in Startdatei
			sta	r0L  ,x			;einlesen.
			iny
			inx
			cpx	#$06
			bcc	:53

			SubVW	(BASE_GEOS_SYS-BASE_GEOS_SYS128),r0

			lda	InstallBank64K		;Speicherbank festlegen.
			sta	r3L

			jsr	MP3StashRAM		;Daten in REU kopieren.
			jsr	MP3VerifyRAM
			and	#%00100000
			bne	:55

			pla
			clc
			adc	#$01
::54			cmp	#$ff			;Alle Datenblöcke kopiert ?
			bcc	:51			; => Nein, weiter...
			rts				;Installationsmeldung ausgeben.

::55			jmp	Err_RamVerErr

;--- Ergänzung: 25.10.18/M.Kanet
;******************************************************************************
;*** Ersatz für GEOS 2.0r-StashRAM.
;*** Siehe G3_UpdStashRAM für weitere Informationen.
;******************************************************************************
			t "-G3_UpdRAMOp"
;******************************************************************************
;*** DoRAMOp-Routine für GeoRAM.
;******************************************************************************
			t "-R3_DoRAM_GRAM"
			t "-R3_DoRAMOpGRAM"
;******************************************************************************

;******************************************************************************
;*** GEOS64/128.MP3 Shared Code Part #1.
;******************************************************************************
			t "-G3_UpdShared1"		;Update-Routinen.
			t "-G3_1571Mode"		;1571-Modus setzen.
			t "-G3_InitDevRAM"		;RAM-Treiber installieren.
			t "-G3_InitDevSCPU"		;SCPU-Treiber installieren.
;			t "-G3_GetPAL_NTSC"		;PAL/NTSC-Erkennung (Nur C64).
;******************************************************************************

;*** Variablen.
:Device_Boot		b $00
:DevAdr_RL		b $00
:Device_SCPU		b $00
:Device_RL		b $00
:DateBuffer		s $03
:RecoverVecBuf		w $0000
:DskErrCode		b $00
:VecFileName		w $0000

;*** Bank für MP3.
:InstallBank64K		b $00

;*** Angaben zur Speichererweiterung.
:ExtRAM_Type		b $00				;$00 = keine RAM-Erweiterung.
							;$80 = RAMLink / RAMDrive.
							;$40 = Commodore REU.
							;$20 = BBG/GEORAM.
							;$10 = SuperCPU/RAMCard.
:ExtRAM_Size		b $00				;Anzahl 64K-Bänke.
:ExtRAM_Bank		w $0000
:ExtRAM_Part		b $00

;*** Dateinamen für Systemdateien.
:FNamGBOOT		b "GEOS128.BOOT",NULL
:FNamGEOS0		b "GEOS128.0",NULL
:FNamGEOS1		b "GEOS128.1",NULL
:FNamGEOS2		b "GEOS128.2",NULL
:FNamGEOS3		b "GEOS128.3",NULL
:FNamGEOS4		b "GEOS128.4",NULL
:FNamRBOOT		b "RBOOT128.BOOT",NULL
:FNamGDISK		b "GEOS128.Disk",NULL
:FNamMPUPD		b "GEOS128.MP3",NULL

;*** Zwischenspeicher Laufwerksdaten.
:driveType_buf		s $04
:ramBase_buf		s $04
:driveData_buf		s $04
:turboFlags_buf		s $04
:doubleSide_buf		s $04

;*** Zeiger auf Laufwerkstreiber in RAM.
:VecToDskDvPos		w R1_ADDR_DSKDEV_A
			w R1_ADDR_DSKDEV_B
			w R1_ADDR_DSKDEV_C
			w R1_ADDR_DSKDEV_D

;*** Bildschirmfarbwerte zwischenspeichern.
:Sv40ColData		b $00
:Sv80ColData		b $00

;*** Programmcodes.
:obj_Updater		d "obj.Update2MP3"
:end_Updater		b NULL
:UserConfig		= obj_Updater +3
:UserPConfig		= obj_Updater +7
:UserRamBase		= obj_Updater +11

;*** Konfiguartionsparameter für GEOS.MP3
:UserTools		= obj_Updater +15

;******************************************************************************
;*** Fehlermeldungen.
;******************************************************************************
			t "-G3_DlgErrTxt"
;******************************************************************************

;******************************************************************************
;*** Endadresse testen.
;*** Ab ":S_KernelData" werden die Kernel-Daten des MP3-Systems geladen!
;******************************************************************************
			g S_KernelData
;******************************************************************************

;******************************************************************************
;*** Die folgenden Routinen sind nur zu Beginn verfügbar und werden im Verlauf
;*** Installation überschrieben.
;******************************************************************************

;******************************************************************************
;*** GEOS64/128.MP3 Shared Code Part #2.
;******************************************************************************
			t "-G3_UpdShared2"
;******************************************************************************

;******************************************************************************
;*** Laufwerks-Erkennung.
;******************************************************************************
			t "-G3_DetectDrive"
;******************************************************************************

;******************************************************************************
;*** InputDevice-Treiber installieren.
;******************************************************************************
			t "-G3_InitInpDev"
;******************************************************************************

;******************************************************************************
;*** RAM-Erweiterung erkennen.
;******************************************************************************
			t "-R3_DetectRLNK"
			t "-R3_DetectSRAM"
			t "-R3_DetectCREU"
			t "-R3_DetectGRAM"
			t "-R3_GetSBnkGRAM"
			t "-G3_GetRLPEntry"
			t "-G3_FindActDACC"
			t "-G3_PrntActDACC"
			t "-G3_ChkRAMSize"
;******************************************************************************

;*** Variablen für Laufwerkserkennung.
:DetectCurDrive		b $00

;*** Texte für alle Dialogboxen.
if Sprache = Deutsch
:Dlg_Information	b PLAINTEXT,BOLDON
			b "Information:",NULL
:Dlg_CancelUpdate	b "(Zurück zu GEOS)",NULL
endif

if Sprache = Englisch
:Dlg_Information	b PLAINTEXT,BOLDON
			b "Information:",NULL
:Dlg_CancelUpdate	b "(Back to GEOS)",NULL
endif

;*** Speicher für Daten über verfügbare Laufwerkstreiber.
:VLIR_Types
:VLIR_Entry		= VLIR_Types +64
:VLIR_Names		= VLIR_Types +64 +64*2
:END_OF_FILE		b NULL

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g	BASE_GEOS_SYS128
;******************************************************************************
