; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_CHAR"
			t "SymbTab_SCPU"
			t "SymbTab_RLNK"
			t "SymbTab_DISK"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "MacTab"

;--- Externe Labels.
			t "e.Register.ext"
			t "s.GDC.Config.ext"
			t "o.DiskCore.ext"

;--- Zusätzliche Labels.
:MAX_SERBUS_DRV		= 10
:STATUS_BASE_Y		= 23
:STATUS_BASE_X		= CFG_MOD_DRIVE*5
:STATUS_BASE		= STATUS_BASE_Y*40 +STATUS_BASE_X

:MAX_DIR_SEARCH		= 128
:ERR_COL_DEBUG		= $15
:ERR_COL_INSTALL	= $12
:ERR_COL_CACHE		= $16
:ERR_COL_DRV2RAM	= $14

;--- Hinweis:
;TaskMan wird während der Installation
;von Laufwerken deaktiviert.
;Die Menü-Routine könte aber bei der
;Installation überschrieben werden.
;Daher Programmcode zu Beginn retten
;und aus dem SwapFile-Speicher in die
;neue Speicherbank übertragen.
:TMAN_SWAPFILE		= $4000				;Zwischenspeicher für TaskMan.
;R3A_SWAPFILE		= $0000				;MP3_64K_DATA: SwapFile-Speicher.
;			= $0000-$11FF			;GD.CONFIG: SwapFile für Dateiliste.
;			= $4000-$5FFF			;GD.CONFIG: SwapFile für TaskMan.

endif

;*** GEOS-Header.
			n "GD.CONF.DRIVES"
			c "GDC.DRIVES  V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Laufwerke konfigurieren"
endif
if LANG = LANG_EN
			h "Configure drive"
endif

;*** Zusätzliche Symbole.
if .p
;--- Verfügbare Laufwerkstreiber.
;Verwendet den Speicher für Laufwerks-
;treiber um eine Liste für ":GetFiles"
;zu erstellen.
:SlctDvNameTab		= BASE_DDRV_DATA
:SlctDvTypeTab		= BASE_DDRV_DATA +DDRV_MAX*17

;--- Sprungtabelle für Installationsroutine.
:DDrv_ApplInstall	= BASE_DDRV_DATA +0
:DDrv_ConfInstall	= BASE_DDRV_DATA +3
:DDrv_TestInstall	= BASE_DDRV_DATA +6

;--- Laufwerksvariablen.
:DDrv_AdrGEOS		= DDRV_VAR_START +0
:DDrv_Type		= DDRV_VAR_START +1
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	InitMain
:SaveData		jmp	SaveConfig
:CheckData		jmp	CheckConfig
;******************************************************************************
;*** Systemkennung.
;******************************************************************************
			b "GDCONF10"
;******************************************************************************

;*** Daten für Taskmanager.
			t "-G3_TaskManData"

;*** Menü initialisieren.
:InitMain		jsr	StashRAM_DkDrv		;Aktuellen Treiber in REU sichern.

;--- Dialogboxen testen...
if FALSE
			LoadW	r0,Dlg_InstallError
			jsr	DoDlgBox

			LoadW	r0,Dlg_InstErrNoRAM
			jsr	DoDlgBox

;			LoadW	r0,Dlg_ErrNoSysDrv
;			jsr	DoDlgBox

			LoadW	r0,Dlg_SwapDskDrv
			jsr	DoDlgBox

			LoadW	r0,Dlg_InstErrLdDrv
			jsr	DoDlgBox

			LoadW	r0,Dlg_IllegalCfg
			jsr	DoDlgBox

			LoadW	r0,Dlg_ErrLdDk2RAM
			jsr	DoDlgBox

			LoadW	r0,Dlg_DvAdrInUse
			jsr	DoDlgBox

			LoadW	r0,Dlg_SlctDevMode
			jsr	DoDlgBox
endif

;--- Hinweis:
;":firstBoot" verwenden, falls beim
;Startvorgang ein Fehler aufgetreten
;ist und das Menü gestartet wurde.
;Siehe ":LoadErrCfgMenu"/S.GDC.Config.
			bit	firstBoot		;GEOS-BootUp ?
			bpl	DoAutoBoot		; => Automatisch installieren.

;*** Setup-Menü aufbauen.
:DoAppStart		ldy	#DDRV_MAX -1		;Treiberinformationen überprüfen.
::1			lda	DRVINF_NG_FOUND,y
			bne	:2
			dey
			bpl	:1

::2			iny				;Treiberinformation vorhanden?
			bne	:init			; => Ja, weiter...

			lda	BootRAM_Flag		;Aktuellen Modus für "Alle Treiber
			and	#%10111111		;in RAM kopieren" übernehmen.
			ldx	MP3_64K_DISK
			beq	:setram
			pha

			LoadW	r0,BootDrvToRAM		;Status "Treiber in RAM" einlesen.
			LoadW	r1,(DRVINF_NG_RAMB - BASE_DDRV_INFO)
			LoadW	r2,1
			stx	r3L
			jsr	FetchRAM

			pla
			ora	#%01000000
::setram		sta	BootRAM_Flag		;"Treiber in RAM"-Modus speichern.

			jsr	GetDrvInfo		;Treiber-Informationen einlesen.

::init			jsr	GetBootRAMLink		;RAMLink-Bootmodus einlesen.

;--- Hinweis:
;TaskManager immer aus der aktuellen
;Speicherbank einlesen, da über das
;TaskMan-Modul die Lage des Menüs im
;DACC verändert worden sein könnte.
			bit	BootTaskMan		;TaskManager installiert?
			bmi	:3			; => Nein, weiter...

			ldx	Flag_TaskBank		;Zeiger auf aktuelle Speicherbank.
			ldy	#jobFetch		;Speichertransfer: Laden.
			jsr	DoRAMOpTMenu		;TaskManager einlesen.

			ldx	MP3_64K_DATA		;Zeiger auf Zwischenspeicher.
			ldy	#jobStash		;Speichertransfer: Speichern.
			jsr	DoRAMOpTMenu		;TaskManager im SwapRAM speichern.

::3			lda	#< RegisterTab		;Register-Menü installieren.
			ldx	#> RegisterTab
			jmp	EnableRegMenu

:exitAppl		rts

;*** System-Boot.
:DoAutoBoot		lda	#$c0
			jsr	i_UserColor
			b	CFG_MOD_DRIVE *5,22,5,3

			jsr	i_BitmapUp		;Init-Meldung ausgeben...
			w	TxBootInit
			b	STATUS_BASE_X +0
			b	STATUS_BASE_Y *8 -8
			b	TxBootInit_x
			b	TxBootInit_y

			lda	sysRAMFlg		;Verhindern das SetDevice den
			and	#%10111111		;Treiber wechselt, bevor Treiber in
			sta	sysRAMFlg		;GEOS-Speicherbank installiert.

			jsr	ChkBootConf		;Boot-Laufwerk anpassen.

			lda	BootRAM_Flag		;Treiber in RAM kopieren ?
			and	#%01000000		; => Nein, weiter...
			beq	:1

			jsr	AllocRAMDskDrv		;Speicherbereich reservieren.
			txa				;Speicher verfügbar ?
			bne	:err			; => Nein, weiter...

			jsr	GetDrvInfoDisk		;Treiberliste aktualisieren.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	i_BitmapUp		;Load2RAM-Meldung ausgeben...
			w	TxBootRAM
			b	STATUS_BASE_X +3
			b	STATUS_BASE_Y *8 -8
			b	TxBootRAM_x
			b	TxBootRAM_y

			jsr	LoadDkDv2RAM		;Laufwerkstreiber einlesen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...

::err			jsr	FreeRAMDskDrv		;Speicher wieder freigeben.

::1			jsr	GetDrvInfo		;Treiber-Informationen einlesen.
							;Erst nach ":ChkBootConf", da hier
							;evtl. das Startlaufwerk getauscht
							;werden muss! (RAMLink/HD >= 12).

::2			jsr	PurgeTurbo		;TurboDOS entfernen.
			jmp	Auto_InstallDrv		;Laufwerke installieren.
::booterr		jmp	Err_NoSysDrive

;*** Aktuelle Konfiguration speichern.
:SaveConfig		jsr	CheckConfig		;Laufwerkskonfiguration testen.
			txa				;Konfiguration gültig?
			bne	:5			; => Nein, Abbruch...

;--- Konfiguration übernehmen.
			ldy	#8
::1			tya
			pha

			lda	#$00			;Aktuelles Laufwerk in
			sta	BootConfig -8,y		;Konfiguration löschen.
			sta	BootPartRL -8,y
			sta	BootPartType -8,y
			sta	BootRamBase -8,y

			lda	driveType -8,y		;Ist Laufwerk definiert ?
			beq	:4			; => Nein, weiter...
;--- Ergänzung: 06.08.18/M.Kanet
;Für RAM41/71/81/NM auch ":ramBase" als
;Zielvorgabe speichern.
;			and	#%11110000		;RAM-Laufwerk?
			bpl	:no_ram			; => Nein, weiter...

;--- Ergänzung: 06.08.18/M.Kanet
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU nutzen die
;Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
			lda	RealDrvType -8,y	;Laufwerkstyp in
			and	#%01110000		;Bits für Extended-RAM-Laufwerke
			bne	:no_ram			;ausblenden.
			lda	ramBase -8,y		;Bei RAMNative Startadresse in
			sta	BootRamBase -8,y

::no_ram		lda	RealDrvType -8,y	;Laufwerkstyp in
			sta	BootConfig -8,y		;Konfiguration übertragen.

			lda	RealDrvMode -8,y	;Laufwerk partitioniert ?
			bpl	:4			; => Nein, weiter...

			tya
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	NewDisk			;Diskette/Partition öffnen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, weiter...

			jsr	getCurPart		;Aktive Partition einlesen.

::2			lda	#$00
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:3			; => Ja, weiter...
			lda	dirEntryBuf +2		;Partitions-Nr. einlesen.

::3			ldy	curDrive
			sta	BootPartRL -8,y		;Partition auf RAMLink speichern.
			lda	RealDrvType -8,y	;Partitionsformat speichern.
			and	#%00001111
			sta	BootPartType -8,y

::4			pla
			tay
			iny
			cpy	#12
			bcc	:1

			jsr	numDrivesInit		;Laufwerke zählen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
::5			rts

;*** RAMLink-Konfiguration überprüfen.
:ChkRAMLinkDev		lda	#$00			;Flag: "Keine RAMLink".
			sta	RL_Aktiv

			php
			sei

			ldy	CPU_DATA
			lda	#KRNL_IO_IN
			sta	CPU_DATA
			ldx	EN_SET_REC		;Byte aus C64-Kernal einlesen.
			sty	CPU_DATA

			plp
			cpx	#$78			;"SEI"-Befehl ?
			bne	:1			;Nein, weiter...
			dec	RL_Aktiv		;RAMLink verfügbar.

;--- Keine RAMLink, RLxy-Laufwerke nach RAMxy konvertieren.
::1			lda	RL_Aktiv		;RAMLink verfügbar ?
			bne	:4			; => Ja, weiter...

			ldx	#$00			;RAMLink-Laufwerke in RAM-Laufwerke
::2			lda	BootConfig,x		;umwandeln, da keine RAMLink
			and	#%11110000		;verfügbar ist. Damit wird versucht
			cmp	#DrvRAMLink		;die Konfiguration beizubehalten!
			bne	:3
			lda	BootConfig,x
			and	#%00001111		;Emulationsmodus isolieren und
			ora	#%10000000		;"RAM-Laufwerk"-Flag setzen.
			sta	BootConfig,x
::3			inx
			cpx	#$04
			bcc	:2
::4			rts

;*** Laufwerkskonfiguration überprüfen.
:CheckConfig		ldy	#11
::1			lda	driveType -8,y		;GEOS-Laufwerk suchen.
			bne	:3			; => Gefunden, weiter...
			dey
			cpy	#8
			bcs	:1

			iny
::2			tya				;Fehlendes Laufwerk in
			clc				;Dialogbox übernehmen.
			adc	#"A" -8
			sta	Dlg_NoDrvTxt1b

			lda	#DEV_NOT_FOUND
			ldx	#< Dlg_IllegalCfg	;"Konfiguration ungültig!"
			ldy	#> Dlg_IllegalCfg
			jsr	openDlgBox		;Fehler ausgeben.

			ldx	#CANCEL_ERR		;Konfiguration ungültg.
			rts

::3			lda	driveType -8,y		;Nicht konfiguriertes Laufwerk?
			beq	:2			; => Ja, Fehler ausgeben...
			dey
			cpy	#8
			bcs	:3

			ldx	#NO_ERROR		;Konfiguration gültg.
			rts

;*** Startlaufwerk überprüfen.
:ChkBootConf		jsr	:getBootConf		;Boot-Konfiguration einlesen.
			jsr	:verifyBootDrv		;Boot-Laufwerk überprüfen.
			bcc	:exit			; => Laufwerk identisch, Ende...

;--- Boot-Laufwerk übernehmen?
			jsr	:applyBootDrv		;Boot-Laufwerk übernehmen ?
			bcc	:update			; => Ja, weiter...

;--- Startlaufwerk in Boot-Konfiguration suchen.
			jsr	:searchBootDrv		;Boot-Laufwerk in Config enthalten ?
			bcc	:swapbtcfg		; => Ja, Laufwerke tauschen...

			ldx	curDrive		;Aktuelles Laufwerk einlesen.

;--- RAMLink-Laufwerksadresse anpassen.
			bit	:bDrvRAMLink		;Start von RAMLink-Laufwerk ?
			bpl	:no_ramlink		; => Nein, weiter...

			jsr	:testRLadr		;RAMLink tauschen / Übernehmen.
			bcc	:update			;RAMLink als Laufwerk X: übernehmen.

;--- Kompatibles Laufwerk gefunden.
::no_ramlink		lda	r0H			;Kompatibles Laufwerk gefunden ?
			beq	:update			; => Nein, Laufwerk ersetzen...
			tax				;Kompatibles Laufwerk übernehmen.
			bne	:update

;--- Laufwerk in Boot-Konfiguration tauschen.
::swapbtcfg		cpy	#12
			bcs	:update
			jsr	:swapBootData		;Boot-Konfiguration tauschen.

;--- Neues Start-Laufwerk festlegen.
::update		stx	SystemDevice		;Neues Startlaufwerk speichern.

;--- Start-Laufwerk speichern.
::replace		jsr	:replaceBootDrv		;Boot-Konfiguration aktualisieren.

;--- Alte/Neue Adresse vergleichen.
			cpx	curDevice		;Wurde Laufwerk gewechselt ?
			beq	:exit			; => Nein, Ende...

;--- Ziel-Adresse prüfen.
			ldy	curDrive
			bit	:bDrvRAMLink		;Start von RAMLink-Laufwerk ?
			bmi	:skipSwapAdr		; => Ja, Ende...

			jsr	:testTarget		;Ziel-Adresse testen.

;--- Laufwerks-Adresse/-Daten tauschen.
::swapAdr		jsr	:swapBootAdr		;Geräteadresse anpassen.
::skipSwapAdr		cpy	SystemDevice		;Wurde Geräteadresse geändert ?
			beq	:updDisk		; => Nein, weiter...

			ldx	SystemDevice		;GEOS-Laufwerkskonfiguration
			jsr	:swapDevData		;an neues Laufwerk anpassen.

;--- CMD-Partition öffnen, BAM neu einlesen.
::updDisk		ldx	curDrive		;Laufwerksadresse.
			ldy	:bPart			;Partition.
			jsr	updDiskPart		;Diskette/Partition öffnen.

			jsr	PurgeTurbo		;TurboDOS entfernen.

::exit			rts				;Ende.

;--- Variablen.
::bRDrvType		b $00
::bPart			b $00
::bDrvRAMLink		b $00

;--- Boot-Konfiguration einlesen.
::getBootConf		ldx	curDrive
			lda	RealDrvType -8,x	;Laufwerkstyp
			sta	:bRDrvType		;zwischenspeichern.

			and	#%11111000		;CMD-Laufwerk ?
			beq	:2			; => Nein, weiter...
			cmp	#DrvRAMLink		;CMD-RAMLink ?
			bne	:1			; => Nein, weiter...
			lda	#$ff
			b $2c
::1			lda	#$00
::2			sta	:bDrvRAMLink		;RAMLink-Flag setzen.

			lda	drivePartData -8,x
			sta	:bPart			;Aktive Partition zwischenspeichern.
			rts

;--- Ziel-Adresse testen.
;Wenn von einem Laufwerk mit Adresse
;>=12 gestartet wird oder wenn das
;Start-Laufwerk innerhalb von GEOS auf
;eine andere Adresse verlegt werden
;soll, dann wird hier die Ziel-Adresse
;geprüft. Ist die Adresse belegt, dann
;wird das Laufwerk auf eine temporäre
;Adresse >=20 geändert.
::testTarget		lda	curDevice
			sta	r15L			;Adresse Start-Laufwerk.
			stx	r15H			;Neue Adresse GEOS-Laufwerk.

			lda	curDrive		;Aktuelles GEOS-Laufwerk
			sta	r14L			;zwischenspeichern.

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.
			lda	r15H
			jsr	_DDC_TESTDEVADR		;Ist neue Adresse belegt ?
			pha
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			pla
			bne	:free			; => Nein, weiter...

			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	_DDC_GETFREEADR		;Freie Adresse #20-29 suchen.
;--- Hinweis:
;Nur theoretisch kann man >20 Laufwerke
;an den ser.Bus anschließen. In der
;Praxis hat man schon bei mehr als vier
;Laufwerken Probleme.
;Daher wird hier auf die Abfrage nach
;einer freien Adresse verzichtet.
;			txa
;			pha
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
;			pla
;			tax
;			beq	:err
;---
			lda	r15H			;Alte Laufwerksadresse einlesen.
			sta	curDevice
			lda	r14H			;Neue temp.Adresse einlesen.
			jsr	ChangeDiskDevice	;Geräteadresse ändern.

			lda	r14L			;Aktuelles GEOS-Laufwerk
			sta	curDrive		;zurücksetzen.

::free			lda	r15L			;Start-Laufwerk zurücksetzen.
			sta	curDevice
			ldx	r15H			;Neue Adresse einlesen.

			rts

;--- Startlaufwerk mit Bootkonfiguration vergleichen.
;Rückgabe: C-Flag=0 : Boot-Laufwerk = Konfiguration.
;          C-Flag=1 : Boot-Laufwerk stimmt nicht.
::verifyBootDrv		ldy	SystemDevice		;Adresse Start-Laufwerk einlesen.
			cpy	#12			;Start von Adresse >= 12 ?
			bcs	:12			; => Ja, Abbruch...

			ldx	curDrive		;Stimmt die gespeicherte
			lda	:bRDrvType		;Konfiguration in GD.CONFIG
			cmp	BootConfig -8,x		;überein ?
			beq	:11			; => Ja, weiter...

			ora	#%01000000		;Shadow-Bit für 1541 setzen.
			cmp	BootConfig -8,x		;Übereinstimmung mit Konfiguration ?
			bne	:12			; => Nein, Konfiguration ändern...
			sta	:bRDrvType		;Shadow-Bit übernehmen.
			beq	:13			; => Laufwerk gefunden, Ende...

::11			and	#%11111000		;Laufwerkstyp testen.
			bmi	:13			; => RAM-Laufwerk, Ende...
			and	#DrvCMD			;CMD-Laufwerk ?
			beq	:13			; => Kein CMD-Laufwerk, Ende...
			lda	BootPartRL -8,x
			cmp	:bPart			;Stimmt Start-Partition ?
			beq	:13			; => Ja, Ende.

::12			sec				; => Konfiguration stimmt nicht.
			rts
::13			clc				; => Konfiguration stimmt.
			rts

;--- Start-Laufwerk übernehmen?
;Rückgabe: C-Flag=0 : Start-Laufwerk übernehmen.
;          C-Flag=1 : Start-Laufwerk automatisch anpassen.
::applyBootDrv		ldy	SystemDevice		;Adresse Start-Laufwerk einlesen.
			cpy	#12			;Start von Adresse >= 12 ?
			bcs	:no_geos_drv		; => Ja, weiter...

			bit	BootDrvReplace		;Laufwerk automatisch anpassen ?
			bmi	:22			; => Ja, Ende...
			bpl	:21			; => Nein, Laufwerk übernehmen.

;--- Start-Laufwerk > 8-11.
::no_geos_drv		bit	:bDrvRAMLink		;Start von RAMLink-Laufwerk ?
			bpl	:22			; => Nein, Laufwerk übernehmen...

			lda	BootDrvRAMLink		;$00 = Laufwerk suchen.
			beq	:22			; => AUTO-Mode, Laufwerk suchen...
			cmp	#8			;Bei #8 bis #11 Laufwerk
			bcc	:22			;für CMD-RAMLink vorgeben, sonst
			cmp	#12			;Laufwerk suchen...
			bcs	:22
			tax

::21			clc				;Laufwerk in Konfiguration suchen.
			rts
::22			sec				;Laufwerk übernehmen.
			rts

;--- Startlaufwerk in Boot-Konfiguration suchen.
;Rückgabe: C-Flag=1 : Start-Laufwerk nicht in Konfiguration gefunden.
;          C-Flag=0 : Start-Laufwerk in Konfiguration gefunden -> XReg.
;          XReg = Neues Start-Laufwerk.
::searchBootDrv		lda	#$00			;Suchen des Start-Laufwerktyps in
			sta	r0H			;der Konfigurationstabelle.

			ldx	#8
::31			lda	BootConfig -8,x		;Konfiguration einlesen.
			cmp	:bRDrvType		;Laufwerkstyp gefunden ?
			beq	:32			; => Ja, weiter...

			cmp	#DrvShadow1541		;1541/Shadow ?
			bne	:34			; => Nein, weiter...
			eor	#%01000000		;Shadow-Bit invertieren.
			cmp	:bRDrvType		;Laufwerkstyp gefunden ?
			bne	:34			; => Nein, weiter...
			ora	#%01000000		;Shadow-Bit setzen.
			sta	:bRDrvType		;Neues Boot-Laufwerk speichern.

::32			lda	r0H			;Erstes Laufwerk gefunden ?
			bne	:33			; => Nein, weiter...
			stx	r0H			;Kompatibles Laufwerk speichern.

::33			lda	BootConfig -8,x
			bmi	:36
			and	#DrvCMD			;CMD-Laufwerk ?
			beq	:36			; => Nein, Laufwerk übernehmen...
			lda	BootPartRL -8,x		;Stimmt Startpartition mit aktiver
			cmp	:bPart			;Partition überein ?
			beq	:36			; => Ja, Laufwerk übernehmen...

::34			inx				;Nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke untersucht ?
			bcc	:31			; => Nein, weiter...

::35			sec				; => Laufwerk nicht gefunden.
			rts
::36			clc				; => Laufwerk gefunden.
			rts

;--- RAMLink-Laufwerksadresse anpassen.
::testRLadr		lda	BootDrvRAMLink		;$00 = RAMLink-Laufwerk suchen ?
			beq	:52			; => Ja, Ende...
			cmp	#8			;Bei #8 bis #11 Laufwerk
			bcc	:52			;für CMD-RAMLink vorgeben.
			cmp	#12
			bcs	:52
			tax				;RAMLink-GEOS-Adresse setzen.
::51			clc				; => RAMLink-Adresse geändert.
			rts
::52			sec				; => RAMLink-Laufwerk suchen.
			rts

;--- Laufwerk in Konfiguration tauschen.
;Übergabe: XReg = Laufwerk in Konfiguration.
;          YReg = Adresse Start-Laufwerk.
;Rückgabe: XReg = Neue Adresse Start-Laufwerk.
::swapBootData		tya				;Neue/Alte-Adresse tauschen.
			pha
			txa
			tay
			pla
			tax

			lda	BootConfig -8,x		;Laufwerk in Konfiguration tauschen.
			pha
			lda	BootPartRL -8,x
			pha
			lda	BootConfig -8,y
			sta	BootConfig -8,x
			lda	BootPartRL -8,y
			sta	BootPartRL -8,x
			pla
			sta	BootPartRL -8,y
			pla
			sta	BootConfig -8,y
			rts

;--- Boot-Laufwerk speichern.
::replaceBootDrv	ldx	SystemDevice		;Daten für Start-Laufwerk in
			lda	:bRDrvType		;Boot-Konfiguration übernehmen.
			sta	BootConfig -8,x
			lda	:bPart
			sta	BootPartRL -8,x
			rts

;--- Adresse Boot-Laufwerk anpassen.
;Übergabe: XReg = Neue Laufwerksadresse.
;Rückgabe: YReg = Alte Adresse Start-Laufwerk.
::swapBootAdr		lda	curDevice		;Aktuelle Geräteadresse
			pha				;zwischenspeichern.
			txa
			jsr	ChangeDiskDevice	;Geräteadresse ändern.
			pla
			cmp	#12			;Start-Adresse 8-11 ?
			bcc	:61			; => Ja, weiter...
			lda	#8			;Vorgabe-Laufwerk zurücksetzen.
::61			tay
			rts

;--- Laufwerksinformationen tauschen.
;Übergabe: YReg = Alte Laufwerksadresse.
;          XReg = Neue Laufwerksadresse.
::swapDevData		lda	driveType -8,y
			sta	driveType -8,x
			sta	curType
			lda	drivePartData -8,y
			sta	drivePartData -8,x
;			lda	RealDrvType -8,y	;Durch ":ChangeDiskDevice" gesetzt.
;			sta	RealDrvType -8,x
			lda	RealDrvMode -8,y
			sta	RealDrvMode -8,x

			lda	#$00			;Daten des temp. Boot-Laufwerks
			sta	driveType -8,y		;löschen.
			sta	drivePartData -8,y
			sta	RealDrvType -8,y
			sta	RealDrvMode -8,y

			stx	curDevice		;Aktuelles Laufwerk setzen.
			stx	curDrive

			jsr	InitForDskDvJob		;Laufwerkstreiber in REU kopieren.
			jsr	StashRAM
			jsr	DoneWithDskDvJob

			rts

;*** Laufwerke installieren.
:Auto_InstallDrv	ldx	SystemDevice		;Systemlaufwerk einlesen.
			lda	BootConfig -8,x		;Boot-Konfiguration gespeichert?
			bne	:start			; => Ja, weiter...

;--- GD.CONFIG-Erststart, Konfiguration vorgeben.
::update		lda	#8
::1			sta	DrvAdrGEOS		;Adresse für aktuelles Laufwerk.

			jsr	TestDriveType		;Aktuelles Laufwerk ermitteln.
			cpx	#NO_ERROR		;Laufwerk gefunden?
			bne	:2			; => Nein, weiter...

			ldx	DrvAdrGEOS
			and	#%00001111		;Partitionsformat isolieren und
			sta	BootPartType -8,x	;Ziel-Laufwerk speichern.
			tya
			ora	BootPartType -8,x
			sta	BootConfig -8,x

::2			inc	DrvAdrGEOS
			lda	DrvAdrGEOS
			cmp	#12			;Alle Laufwerke getestet?
			bcc	:1			; => Nein, weiter...

			ldx	SystemDevice		;Konfiguration Systemlaufwerk
			lda	RealDrvType -8,x	;in Boot-Konfiguration speichern.
			sta	BootConfig -8,x

;--- Installation starten.
::start			jsr	ChkRAMLinkDev		;RAMLink-Konfiguration prüfen.

			lda	#$00
			sta	drvInstErr

;--- Ergänzung: 20.07.21/M.Kanet
;Wird GDOS über GD.UPDATE installiert,
;dann sind die Laufwerke in :driveType
;bereits definiert.
			ldx	#$08
::11			stx	DrvAdrGEOS		;Zeiger auf Laufwerk speichern.

;			lda	#ERR_COL_DEBUG		;Debug-Farbe setzen.
;			sta	COLOR_MATRIX +STATUS_BASE -8,x

			lda	drvNameL -8,x		;Laufwerksadresse ausgeben.
			sta	r0L
			lda	drvNameH -8,x
			sta	r0H

			txa
			clc
			adc	# (STATUS_BASE_X -8)
			sta	r1L
			lda	# (STATUS_BASE_Y *8)
			sta	r1H

			lda	#1
			sta	r2L
			lda	#8
			sta	r2H

			jsr	BitmapUp

			ldx	DrvAdrGEOS
;			lda	driveType -8,x		;Laufwerk bereits installiert ?
;			bne	:15			; => Ja, überspringen.

			lda	BootConfig -8,x		;Ist Laufwerk konfiguriert ?
			beq	:13			; => Nein, nicht aktivieren.

			sta	InstallDrvType		;Laufwerkstyp speichern.

;--- Installation vorbereiten.
::prepare		and	#%11111000		;RAM-Laufwerk ?
			bmi	:load			; => Ja, weiter...
			cmp	#DrvRAMLink		;CMD-RAMLink ?
			beq	:load			; => Ja, weiter...

;--- Hinweis:
;":_DDC_DEVTYPE" ist hier nocht nicht mit
;Laufwerksdaten gefüllt!
;			ldx	DrvAdrGEOS
;			lda	_DDC_DEVTYPE -8,x	;Gültiges Laufwerk gefunden ?
;			cmp	#DrvVICEFS		;VICE/VDRIVE ?
;			beq	:13			; => Nein, Fehler ausgeben. /VICE-FS

;--- Laufwerk installieren.
::load			lda	InstallDrvType
			jsr	LoadDkDvData		;Benötigten Treiber einlesen.
			txa				;Diskettenfehler ?
			bne	:instErr		; => Ja, Abbruch...

			ldx	DrvAdrGEOS
			lda	drvNotCached -8,x	;Ladefehler durch CacheLoad?
			bne	:err2			; => Ja, Warnung anzeigen.
			lda	drvNotInRAM -8,x	;"Treiber-im-RAM"-Fehler?
			beq	:init			; => Nein, weiter...

::err1			lda	#ERR_COL_DRV2RAM	;Fehlerfarbe für Laufwerk setzen.
							;"Treiber-im-RAM"-Fehler.

			b $2c
::err2			lda	#ERR_COL_CACHE		;Fehlerfarbe für Laufwerk setzen:
							;Datei über FindFile gesucht.

			sta	COLOR_MATRIX +STATUS_BASE -8,x

			inc	drvInstErr		;Anzahl Fehler +1.

;--- Laufwerk einrichten.
::init			jsr	InitNewDevice		;Laufwerk installieren.
			txa				;Installationsfehler?
			beq	:14

::instErr		ldx	DrvAdrGEOS
			lda	#ERR_COL_INSTALL	;Fehlerfarbe für Laufwerk setzen.
							;Installationsfehler.

			sta	COLOR_MATRIX +STATUS_BASE -8,x

			inc	drvInstErr		;Anzahl Fehler +1.

;--- Laufwerk nicht installiert.
::13			ldx	DrvAdrGEOS
			jsr	_DDC_DEVCLRDATA		;Laufwerk deaktivieren.

;--- Nächstes Laufwerk.
::14			ldx	DrvAdrGEOS		;Zeiger auf nächstes Laufwerk.
::15			inx
			cpx	#12			;Alle Laufwerke installiert ?
			bcc	:11			; => Nächstes Laufwerk...

;--- Status anzeigen.
			lda	#< drvStatOK		;Status: OK.
			ldx	#> drvStatOK
			ldy	drvInstErr
			beq	:16
			lda	#< drvStatErr		;Status: Fehler.
			ldx	#> drvStatErr
::16			sta	r0L
			stx	r0H

			lda	# (STATUS_BASE_X +4)
			sta	r1L
			lda	# (STATUS_BASE_Y *8)
			sta	r1H

			lda	#1
			sta	r2L
			lda	#8
			sta	r2H

			jsr	BitmapUp

			lda	drvInstErr		;Fehler aufgetreten?
			beq	:end			; => Nein, weiter...

			ldx	#0			;Fehler-Modus anzeigen.
::17			jsr	SCPU_Pause
			jsr	SCPU_Pause
			lda	COLOR_MATRIX +STATUS_BASE +4
			eor	#$d0
			sta	COLOR_MATRIX +STATUS_BASE +4
			inx
			cpx	#7
			bcc	:17

;--- Laufwerke installiert.
::end			lda	sysFlgCopy		;Laufwerkstreiber A: bis D: in
			sta	sysRAMFlg		;GEOS-Speicherbank installiert.

			jsr	numDrivesInit		;Laufwerke zählen.

;--- Partitionen installieren.
::partition		ldx	#8			;Zeiger auf Laufwerk #8.
::21			stx	DrvAdrGEOS		;Laufwerk speichern.
			lda	driveType -8,x
			beq	:22
			lda	RealDrvMode -8,x	;CMD-Laufwerk ?
			bpl	:22			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			ldx	DrvAdrGEOS		;Laufwerksadresse.
			ldy	BootPartRL -8,x		;Partitions-Nr. einlesen.
			jsr	updDiskPart		;Partition öffnen.

::22			ldx	DrvAdrGEOS		;Aktuelles Laufwerk einlesen.
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getestet ?
			bcc	:21			;Nein, weitertesten...

;--- Installation beendet.
::done			jsr	SetBootDevice		;Start-Laufwerk aktivieren.
			txa				;Diskettenfehler ?
			beq	:31			; => Nein, weiter...
			jmp	Err_NoSysDrive
::31			jmp	PurgeTurbo		;TurboDOS entfernen.

;*** Laufwerk installieren.
;Übergabe: DrvAdrGEOS     = Laufwerksadresse.
;          InstallDrvType = Laufwerkstyp.
;Laufwerkstreiber muss bereits zur
;Installation bereitstehen!

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Installations-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
:InitNewDevice		jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	DDrv_TestInstall	;Treiber-Installation testen.
;------------------------------------------------------------------------------
			txa				;Fehler ?
			beq	:prepare		; => Nein, weiter...
			jmp	:error

;--- Ergänzung: 15.06.18/M.Kanet
;Der RAMNative-Treiber erkennt bei der
;Laufwerksinstallation ob bereits ein
;RAMNative-Laufwerk installiert war.
;Dazu wird die BAM geprüft. Ist diese
;gültig wird daraus die Größe des
;Laufwerks ermittelt und im GD.CONFIG
;dann als Größe vorgeschlagen.
;Damit dies funktioniert sollte in
;":ramBase" die frühere Startadresse
;übergeben werden.
;Wenn die Konfiguration in GD.CONFIG
;gespeichert wird jetzt auch die
;":ramBase"-Adresse der RAMLaufwerke
;gesichert und an dieser Stelle vor der
;Laufwerksinstallation als Vorschlag
;an die Installationsroutine übergeben.
::prepare		lda	InstallDrvType		;Laufwerksmodus einlesen.

;--- Ergänzung: 06.08.18/M.Kanet
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU nutzen die
;Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
			and	#%11110000		;RAM-Laufwerk ?
			bpl	:init			; => Kein RAM-Laufwerk, weiter...
			and	#%01110000		;RAM41/71/81/NM ?
			bne	:init			; => Nein, weiter...

			ldx	DrvAdrGEOS
			lda	ramBase -8,x		;":ramBase" bereits definiert?
			bne	:init			; => Ja, weiter...
			lda	BootRamBase -8,x	;Neues RAM-Laufwerk. Für RAMNative
			sta	ramBase -8,x		;Startadresse vorschlagen.

;--- Neues Laufwerk aktivieren.
::init			lda	InstallDrvType		;Übergabeparameter definieren.
			and	#%11110000		;Laufwerkstyp bestimmen.
			cmp	#DrvHD			;Laufwerk CMD-HD ?
			bne	:no_cmdhd		; => Nein, weiter...

			lda	DDRV_VAR_CONF		;FastPP-Modus übergeben.
			and	#%00111111
			ora	BootUseFastPP
			sta	DDRV_VAR_CONF

::no_cmdhd		lda	DDRV_VAR_CONF		;Anwendung  : Auswahl anzeigen.
			and	#%11011111
			bit	firstBoot		;GEOS-BootUp ?
			bmi	:part			; => Nein, weiter...
			ora	#%00100000		;Keine Partitionsauswahl.
::part			sta	DDRV_VAR_CONF

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Installations-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	DDrv_ConfInstall	;Treiber installieren.
;------------------------------------------------------------------------------
			txa				;Installationsfehler ?
			beq	:cont 			; => Nein, weiter...
			cpx	#CANCEL_ERR		;Vom Anwender beendet ?
			beq	:exit_inst		; => Ja, Abbruch...

;HINWEIS:
;Nach einem Fehler ":curDevice" immer
;zurücksetzen. Kann z.B. Laufwerk C:
;nicht installiert werden, dann steht
;in ":curDevice" $0A = Laufwerk #10.
;Beim nächsten Aufruf von ":SetDevice"
;wird dann versucht das TurboDOS zu
;beenden obwohl das Laufwerk nicht im
;System installiert ist -> Absturz.
::error			lda	#$00			;curDevice zurücksetzen.
			sta	curDevice

;--- Ergänzung: 07.08.21/M.Kanet
;Die Laufwerkstreiber geben beim Start
;über GD.CONFIG keine Fehlermeldung
;mehr aus.
;Daher muss hier jetzt der Fehlercode
;ausgewertet werden.
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:exit_inst		; => Ja, weiter...

			cpx	#ILLEGAL_DEVICE		;Fehler "Laufwerk ungültig" ?
			bne	:e0			; => Nein, weiter...

			lda	#< Err_DvAdrInUse	; => Adresse belegt / VICE-FS.
			ldx	#> Err_DvAdrInUse
			bne	:inst_err

::e0			cpx	#NO_FREE_RAM		;Fehler "Zu wenig Speicher" ?
			bne	:e1			; => Nein, weiter...

			lda	#< Err_InstNoRAM	; => Nicht genügend Speicher.
			ldx	#> Err_InstNoRAM
			bne	:inst_err

::e1			cpx	#DEV_NOT_FOUND		;Fehler "Laufwerk nicht gefunden" ?
			bne	:e2			; => Nein, weiter...

			lda	#< Err_DevNotFound	; => Laufwerk nicht gefunden.
			ldx	#> Err_DevNotFound
			bne	:inst_err

::e2			lda	#< Err_InstFailed	; => Installationsfehler.
			ldx	#> Err_InstFailed
::inst_err		jsr	CallRoutine		;Fehlermeldung ausgeben.
;---

;			ldx	#DEV_NOT_FOUND
::exit_inst		rts

;--- Variablen aktualisieren.
::cont			lda	DrvAdrGEOS
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	ClearDiskName		;Diskettenname löschen.

;--- Hinweis:
;Hier nur die Nutzung als GEOS-Laufwerk
;freigeben. Das Gerät am ser.Bus nicht
;abmelden!
			ldx	curDrive
			lda	#$00
;			sta	_DDC_DEVTYPE -8,x	;Ser.Bus-Laufwerk abmelden.
			sta	_DDC_DEVUSED -8,x	;GEOS-Laufwerk freigeben.

			lda	driveType -8,x		;RAM- oder RAMLink-Laufwerk?
			bmi	:3			; => Ja, weiter...
			and	#%00001111		;Emulationsmodus ermitteln.
			tay

			lda	RealDrvType -8,x	;Laufwerkstyp einlesen.
			and	#DrvCMD			;CMD-Laufwerk ?
			bne	:1			; => Ja, weiter...
			lda	RealDrvMode -8,x
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk ?
			beq	:2			; => Nein, weiter...

			tya
			ora	#%01000000		;SD2IEC-Flag setzen.
::1			tay				;CMD/SD2IEC.
::2			tya
			sta	_DDC_DEVTYPE -8,x	;Laufwerkstyp speichern.
			lda	#$ff
			sta	_DDC_DEVUSED -8,x	;GEOS-Laufwerk reservieren.

::3			bit	firstBoot		;GEOS-BootUp ?
			bmi	:ok			; => Nein, Ende...

;--- CMD-Partitionen initialisieren.
;Für CMD-Laufwerke die Boot-Partition
;einstellen. Für RAMLink/Boot zwingend
;erforderlich, da durch ":OpenDisk" bei
;der Treiber-Installation evtl. eine
;andere Partition als aktive Partition
;eingestellt wurde.
::initBoot		ldx	DrvAdrGEOS		;Laufwerksadresse.
			lda	BootPartRL -8,x		;Partitions-Nr. einlesen.
			jsr	updDiskPart		;Partition öffnen.
;			jsr	PurgeTurbo		;TurboDOS entfernen.

;--- Installation abschließen, neuen Laufwerksmodus anzeigen.
::ok			ldx	#NO_ERROR
			rts

;*** Neuen Laufwerksmodus wählen.
:SlctDrvA		ldx	#8
			b $2c
:SlctDrvB		ldx	#9
			b $2c
:SlctDrvC		ldx	#10
			b $2c
:SlctDrvD		ldx	#11
			stx	DrvAdrGEOS		;Laufwerksadresse speichern.

			lda	MP3_64K_DISK		;Treiber im RAM ?
			bne	:select			; => Ja, weiter...

			cpx	SystemDevice		;Start-Laufwerk wechseln ?
			bne	:select			; => Nein, weiter...

			jmp	Err_SwapSysDrv		;Fehler ausgeben.

;--- Laufwerksauswahl.
::select		jsr	SlctNewDrvMode
			txa
			bne	:exit
			sty	InstallDrvType		;Laufwerksmodus speichern.
			tya				;Neues Laufwerk gewählt ?
			bne	:prepare		; => Ja, weiter...

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Deinstallations-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	UninstallDrive		;Laufwerk deinstallieren.
;------------------------------------------------------------------------------

			rts

;--- Installation vorbereiten.
::prepare		and	#%11110000
			bmi	:load
			cmp	#DrvRAMLink
			beq	:load

			ldx	DrvAdrGEOS
			lda	_DDC_DEVTYPE -8,x	;Gültiges Laufwerk gefunden ?
			cmp	#DrvVICEFS		;VICE/VDRIVE ?
			bne	:load			; => Nein, Fehler ausgeben. /VICE-FS

			jmp	Err_DvAdrInUse		;Fehler ausgeben.

;--- Laufwerk installieren.
::load			lda	InstallDrvType
			jsr	LoadDkDvData		;Benötigten Treiber einlesen.
			txa				;Diskettenfehler ?
			beq	:init			; => Nein, weiter...

			jmp	Err_LoadDrv		;Fehler: Treiber nicht gefunden.

;--- Laufwerk einrichten.
::init			jsr	ClrRAM_TaskMan		;Speicherbänke für TaskMan und
			jsr	ClrRAM_Spooler		;Spooler löschen, da Laufwerke die
							;höchste Priorität haben!
			jsr	InitNewDevice		;Laufwerk installieren.
			txa				;Installation erfolgreich?
			beq	:cont			; => Ja, weiter...

;--- Laufwerk nicht installiert.
			ldx	DrvAdrGEOS
			jsr	_DDC_DEVCLRDATA		;Laufwerk deaktivieren.

;--- Installation abschließen.
::cont			bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:exit			; => Ja, keine Parameterübernahme.

			jsr	SetRAM_TaskMan		;Speicher für TaskManager und
			jsr	SetRAM_Spooler		;Spooler reservieren.

			jsr	UpdTaskBank		;TaskMan-Bankadressen speichern.

::exit			rts

;*** Neue Partition aktivieren.
:SlctPartA		ldx	#8
			b $2c
:SlctPartB		ldx	#9
			b $2c
:SlctPartC		ldx	#10
			b $2c
:SlctPartD		ldx	#11
:SlctPart		lda	driveType -8,x		;Laufwerk verfügbar ?
			beq	:exit			; => Nein, Ende...

			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:exit			; => Nein, Ende...

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Partitionsauswahl-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	_DDC_OPENMEDIA		;Disk, Partition, DiskImage öffnen.
;------------------------------------------------------------------------------

::exit			rts

;*** Laufwerks-/Partitionsname ausgeben.
:PrntDrvA		ldx	#8
			b $2c
:PrntDrvB		ldx	#9
			b $2c
:PrntDrvC		ldx	#10
			b $2c
:PrntDrvD		ldx	#11
			lda	driveType -8,x		;Laufwerk definiert ?
			bne	:2			; => Ja, weiter...

;--- Kein Laufwerk.
::1			LoadW	r0,TxNODRIVE		;Text "Kein Laufwerk!" ausgeben.
			jmp	PutString

::2			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler ?
			bne	:1			; => Ja, kein Laufwerk.

;--- Auf unbekanntes Laufwerk testen.
			ldx	curDrive
			lda	RealDrvType -8,x	;Ist Laufwerk installiert ?
			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Unbekanntes Laufwerk ?
			bne	:3			; => Nein, weiter...
			LoadW	r0,TxUNKNOWN
			jmp	PutString		;Text "Laufwerk unbekannt!"

;--- Laufwerkstyp ausgeben.
::3			PushW	r11			;X-Koordinate zwischenspeichern.
			jsr	PutString

;--- Native/PCDOS: Partitionsgröße ausgeben.
			ldx	curDrive
			lda	driveType -8,x
			and	#%00001111
			cmp	#DrvNative		;PCDOS/NATIVE-Laufwerk ?
			bne	:noSize			; => Nein, weiter...

			lda	#","			;Diskettenkapazität ausgeben.
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			PushW	r11
			PushB	r1H

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:noDisk			; => Ja, Abbruch...

;--- Ergänzung: 01.03.19/M.Kanet
;Der HD-NM-PP-Treiber verwendet nicht dir3Head, daher den BAM-Sektor
;$01/$02 mit Track-Anzahl nach ":diskBlkBuf" einlesen.
;			LoadW	r5,curDirHead
;			jsr	CalcBlksFree		;Freien Speicher berechnen.
;			txa				;Diskettenfehler ?
;			beq	:prntSize		; => Nein, weiter...

;			ldx	#$00
			stx	r4L
			inx
			stx	r1L
			inx
			stx	r1H
			lda	#>diskBlkBuf
			sta	r4H
			jsr	GetBlock
			txa
			bne	:noDisk

;--- Ergänzung: 15.12.18/M.Kanet
;Laufwerksgröße in KByte ausgeben und nicht mehr die Anzahl
;der max. Verfügbaren Blocks.
			lda	diskBlkBuf +8
			b $2c
::noDisk		lda	#$00			;Keine Diskette im Laufwerk.
			sta	r0L
			lda	#64			;64Kb je Track.
			sta	r1L
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult

::prntSize		PopB	r1H
			PopW	r11

;--- Ergänzung: 15.12.18/M.Kanet
;Laufwerksgröße in KByte ausgeben und nicht mehr die Anzahl
;der max. Verfügbaren Blocks.
;			ldx	#r3L			;Blocks in KByte umrechnen.
;			ldy	#$02
;			jsr	DShiftRight
;			MoveW	r3,r0
			lda	#%11000000
			jsr	PutDecimal

			lda	#"K"
			jsr	SmallPutChar
			lda	#"b"
			jsr	SmallPutChar

;--- CMD/SD2IEC: Partition anzeigen.
::noSize		PopW	r11
			AddVB	8,r1H

			ldx	curDrive		;Laufwerksadresse einlesen und
			lda	RealDrvMode -8,x	;CMD-Laufwerk gefunden ?
			bmi	:6			; => Nein, weiter...

;--- Ergänzung: 16.12.18/M.Kanet
;Bei SD2IEC Textkennung ausgeben.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk ?
			beq	:9			; => Nein, weiter...
			LoadW	r0,TxSD2IEC
			jmp	PutString		;Text "Laufwerk unbekannt!"

::6			PushW	r11
			PushB	r1H

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Disk im Laufwerk ?
			bne	:7			; => Nein, Abbruch...

			jsr	getCurPart		;Aktive Partition einlesen.

::7			PopB	r1H
			PopW	r11

			txa				;Diskettenfehler ?
			bne	:9			; => Ja, Abbruch...

			ldy	#$00			;Partitionsname ausgeben.
::8			ldx	dirEntryBuf +3,y
			beq	:9
			cmp	#$a0
			beq	:9
			tya
			pha
			txa
			jsr	SmallPutChar
			pla
			tay
			iny
			cpy	#$10
			bcc	:8
::9			rts

;*** Geräteliste neu laden.
:ReloadDrvList

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor der Laufwerkserkennung auf dem
;IECBus darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	_DDC_DETECTALL		;Geräte am ser.Bus erkennen.
;------------------------------------------------------------------------------

			jmp	RegisterAllOpt		;Register aktualisieren.

;*** Laufwerke ausgeben.
:PrntDrvList		lda	r1L			;Aufbau Register-Menü ?
			beq	:draw			; => Ja, weiter...
			jmp	SlctNewDrv		; => Nein, Mausklick auswerten.

::draw			lda	drvListCount		;Tabelle bereits definiert ?
			bne	doPrntList		; => Ja, weiter...

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor der Laufwerkserkennung auf dem
;IECBus darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
:getDevList		jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	_DDC_DETECTALL		;Geräte am ser.Bus erkennen.
;------------------------------------------------------------------------------

:doPrntList		jsr	:setDrvData		;Laufwerkstabelle erzeugen.

			lda	#$56			;Y-Koordinate festlegen.
			sta	r1H

			ldx	#0			;Laufwerkszähler löschen.
			stx	drvListCount
::1			ldy	SysDrvTab,x		;Laufwerk verfügbar ?
			beq	:2			; => Nein, weiter...
			lda	SysDrvAdrTab,x		;Laufwerksadresse einlesen.
			tax

;			ldy	SysDrvTab...
;			ldx	SysDrvAdrTab...
			jsr	:prntDAdr		;Ser.Bus-Adresse ausgeben.
			jsr	:prntDType		;Laufwerkstyp ausgeben.
			jsr	:prntGAdr		;GEOS-Adresse ausgeben.

			AddVB	8,r1H			;Y-Koordinate korrigieren.

::2			inc	drvListCount		;Laufwerkszähler korrigieren.
			ldx	drvListCount
			cpx	#MAX_SERBUS_DRV		;Gesamte Tabelle durchsucht ?
			bcc	:1			; => Nein, weiter...

			rts

;--- Laufwerksmodus ermitteln.
;Übergabe: XReg = Laufwerksadresse.
;          YReg = Laufwerkstyp.
::setDrvData		ldx	#0			;Laufwerkstabelle löschen.
			txa
::10			sta	SysDrvTab,x
			sta	SysDrvAdrTab,x
			inx
			cpx	#MAX_SERBUS_DRV
			bcc	:10

;			lda	#$00			;Laufwerkszähler löschen.
			sta	drvListCount

			ldx	#$08
::loop			lda	_DDC_DEVTYPE -8,x	;Laufwerk verfügbar ?
			beq	:next			; => Nein, weiter...

			tay
			cmp	#DrvVICEFS		;VICE/VDRIVE ?
			beq	:14			; => Ja, übernehmen...
			and	#%00001111		;C= oder SD2IEC-Laufwerk ?
			bne	:12			; => Ja, weiter...

;--- CMD-Laufwerk.
			lda	_DDC_DEVUSED -8,x	;Laufwerk reserviert ?
			bne	:11			; => Ja, weiter...

;--- Laufwerk nicht in Verwendung.
			tya
			ora	#%00000100		;CMD-Native-Laufwerk als
			tay				;Vorgabe setzen.
			bne	:14			; => Laufwerkstyp speichern.

;--- Laufwerk in Verwendung.
::11			lda	driveType -8,x
			and	#%00001111		;Aktuellen GEOS-Modus als
			ora	_DDC_DEVTYPE -8,x	;Vorgabe setzen.
			tay
			bne	:14			; => Laufwerkstyp speichern.

;--- C=Laufwerk oder SD2IEC.
::12			lda	_DDC_DEVUSED -8,x	;Laufwerk reserviert ?
			beq	:13			; => Nein, weiter...

;--- Laufwerk in Verwendung.
			tya
			and	#%00001111		;SD2IEC-Laufwerk ?
			tay
			bne	:14			; => Laufwerkstyp speichern.

;--- Laufwerk nicht in Verwendung.
::13			tya
			and	#%01000000		;SD2IEC-Laufwerk ?
			beq	:14			; => Nein, weiter...

			ldy	#DrvNative		;Vorgabe für SD2IEC-Laufwerk.

;--- Laufwerkstyp in Liste speichern.
::14			tya				;Systemwerte für Laufwerk
			ldy	drvListCount		;(Adresse und Typ) speichern.
			sta	SysDrvTab,y
			pha
			txa
			sta	SysDrvAdrTab,y
			pla
			tay

			inc	drvListCount		;Laufwerkszähler korrigieren.
			lda	drvListCount		;Laufwerkszähler einlesen.
			cmp	#MAX_SERBUS_DRV		;Ist Tabelle voll ?
			bcs	:exit			; => Ja, Ende...

::next			inx
			cpx	#29 +1
			bcc	:loop

::exit			rts

;--- Geräteadresse ausgeben.
;Übergabe: XReg = Laufwerksadresse.
;          YReg = Laufwerkstyp.
::prntDAdr		txa
			pha
			tya
			pha
			stx	r0L
			LoadB	r0H,0
			LoadW	r11,$0112
			lda	#%11000000
			jsr	PutDecimal
			pla
			tay
			pla
			tax
			rts

;--- Laufwerkstyp ausgeben.
;Übergabe: XReg = Laufwerksadresse.
;          YReg = Laufwerkstyp.
::prntDType		txa
			pha

			cpy	#DrvVICEFS		;VICE/VDrive ?
			beq	:20			; => Ja, weiter...

			tya
			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Laufwerkstyp erkannt ?
			bne	:21			; => Ja, weiter...

			ldy	drvListCount		;Laufwerk aus Tabelle löschen.
			lda	#$00
			sta	SysDrvTab,y
			sta	SysDrvAdrTab,y

			ldx	#< $006a		;Text "Unbekannt" ausgeben.
			lda	#< TxUNKNOWN
			ldy	#> TxUNKNOWN
			jmp	:prntStrg

::20			ldx	#< $006a		;Text "VICE/VDrive" ausgeben.
			lda	#< TxVICEFS
			ldy	#> TxVICEFS
			jmp	:prntStrg

::21			LoadW	r11,$006a
			jsr	PutString		;Laufwerkstyp ausgeben.

			pla
			pha
			tax				;Laufwerksadresse einlesen und
			lda	RealDrvMode -8,x	;CMD-Laufwerk gefunden ?
			bmi	:22			; => Ja, weiter...
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk ?
			beq	:22			; => Nein, weiter...

			lda	driveType -8,x		;Bei SD2IEC-Native keine
			and	#%00001111		;zusätzliche Kennung ausgeben.
			cmp	#DrvNative		;SD2IEC-Native ?
			beq	:22			; => Ja, weiter...

			ldx	#< $00d4		;Text "(SD2IEC)" ausgeben.
			lda	#< TxSD2IEC
			ldy	#> TxSD2IEC

::prntStrg		stx	r11L
			ldx	#$00
			stx	r11H
			sta	r0L
			sty	r0H
			jsr	PutString

::22			pla
::23			tax
			rts

;--- GEOS-Laufwerk markieren.
::prntGAdr		txa
			pha

			LoadW	r11,$0055

			lda	_DDC_DEVUSED -8,x	;GEOS-Laufwerk reserviert ?
			beq	:31			; => Ja, weiter...
			txa
			clc
			adc	#"A" -8
			b $2c
::31			lda	#"-"
			pha
			jsr	SmallPutChar		;GEOS-Adresse ausgeben.
			pla
			cmp	#"-"
			beq	:32

			lda	r1H
			sec
			sbc	#$06
			sta	r2L
			clc
			adc	#$07
			sta	r2H
			LoadW	r3,$0068
			LoadW	r4,$0107
			lda	#$12
			jsr	DirectColor		;Reserviertes Laufwerk markieren.

::32			pla
			tax
			rts

;*** Vorhandenes Laufwerk installieren.
:SlctNewDrv		lda	mouseData		;Warten bis keine Maustaste
			bpl	SlctNewDrv		;mehr gedrückt.
			ClrB	pressFlag

			jsr	:testEntry		;Gültiger Eintrag gewählt ?
			bcs	:exit			; => Nein, weiter...

;--- Laufwerksauswahl.
::select		lda	InstallDrvType
			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Laufwerkstyp erkannt ?
			beq	:exit			; => Nein, Ende...

			MoveW	r0,r5			;Dateiname in ":r5" übergeben.
			jsr	_DDC_SLCTGEOSADR	;GEOS-Adresse für Laufwerk wählen.
			cpx	#NO_ERROR		;"Abbruch" ?
			bne	:exit			; => Ja, Ende...
			sta	DrvAdrGEOS		;GEOS-Adresse speichern.

			lda	newDrvMode
			cmp	#DrvRAMLink
			beq	:slctemu

			ldx	DrvAdrGEOS
			lda	_DDC_DEVTYPE -8,x	;Aktuelles Laufwerk einlesen.
			cmp	#DrvVICEFS		;VICE/VDRIVE ?
			bne	:slctemu		; => Nein, weiter...

			jmp	Err_DvAdrInUse		;Fehler ausgeben.

;--- Ggf. Emulationsformat wählen.
::slctemu		jsr	:setEmuMode		;Emulationsmodus wählen.
			txa				;"Abbruch" ?
			bne	:exit			; => Ja, Ende...

;--- Laufwerk installieren.
::load			lda	InstallDrvType
			jsr	LoadDkDvData		;Benötigten Treiber einlesen.
			txa				;Diskettenfehler ?
			beq	:prepare		; => Nein, weiter...

			jmp	Err_LoadDrv		;Fehler: Treiber nicht gefunden.

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Installations-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
;--- Installation vorbereiten.
::prepare		jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	prepareInstall		;Installation vorbereiten.
;------------------------------------------------------------------------------
			txa				;Fehler aufgetreten ?
			beq	:init			; => Nein, weiter...

::err_install		jmp	Err_InstFailed

;--- Laufwerk einrichten.
::init			jsr	ClrRAM_TaskMan		;Speicherbänke für TaskMan und
			jsr	ClrRAM_Spooler		;Spooler löschen, da Laufwerke die
							;höchste Priorität haben!
			jsr	InitNewDevice		;Laufwerk installieren.
			txa				;Installation erfolgreich?
			beq	:cont			; => Ja, weiter...

;--- Laufwerk nicht installiert.
			ldx	DrvAdrGEOS
			jsr	_DDC_DEVCLRDATA		;Laufwerk deaktivieren.

;--- Installation abschließen.
::cont			bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:updmenu		; => Ja, keine Parameterübernahme.

			jsr	SetRAM_TaskMan		;Speicher für TaskManager und
			jsr	SetRAM_Spooler		;Spooler reservieren.

			jsr	UpdTaskBank		;TaskMan-Bankadressen speichern.

::updmenu		jsr	RegisterAllOpt		;Register aktualisieren.

;--- Installation abbrechen.
::exit			rts

;--- Gewählten Eintrag testen.
;Übergabe: mousePos   = Zeiger auf Eintrag.
;Rückgabe: newDrvSlct = Gewählter Eintrag in Tabelle.
;          newDrvAdr  = Ser.Bus-Adresse neues Laufwerk.
;          newDrvUsed = GEOS-Adresse des neuen Laufwerks.
;          newDrvMode = Laufwerkstyp (bei CMDohne Emulationsformat).
::testEntry		lda	mouseYPos		;Position Mauszeiger speichern.
			sec				;Gewählten Eintrag berechnen.
			sbc	#$50
			lsr
			lsr
			lsr
			tax
			lda	SysDrvTab,x		;Laufwerk definiert ?
			beq	:11			; => Nein, Ende...
			cmp	#DrvVICEFS		;VICE/VDRIVE ?
			beq	:11			; => Ja, Ende...

			stx	newDrvSlct
			sta	InstallDrvType		;Laufwerkstyp speichern.
			lda	SysDrvAdrTab,x		;Aktuelle Geräteadresse für
			sta	newDrvAdr		;Laufwerk einlesen.
			tax
			lda	_DDC_DEVUSED -8,x	;Status für "Laufwerk unter GEOS
			sta	newDrvUsed		;bereits installiert" einlesen.
			lda	_DDC_DEVTYPE -8,x	;Laufwerksmodus (mit gesetztem
			sta	newDrvMode		;Bit#6 für SD2IEC) einlesen.
			clc
			rts
::11			sec
			rts

;--- Emulationsmodus bestimmen.
::setEmuMode		lda	newDrvMode		;Installationsmodus einlesen.
			and	#%01000000		;SD2IEC-Lauwerk ?
			bne	:51			; => Ja, weiter...
			lda	newDrvMode
			and	#DrvCMD			;CMD-Laufwerk ?
			beq	:dlg_ok			; => Nein, weiter...

::51			ldx	#< Dlg_SlctDevMode
			ldy	#> Dlg_SlctDevMode
;			lda	#NULL
			jsr	openDlgBox		;Emulationsmodus auswählen.

			lda	sysDBData
			bpl	:dlg_cancel

::dlg_ok		ldx	#NO_ERROR
			rts

::dlg_cancel		ldx	#CANCEL_ERR
			rts

;--- Variablen.
:newDrvAdr		b $00
:newDrvUsed		b $00
:newDrvMode		b $00
:newDrvSlct		b $00

;*** Geräteliste aktualisieren.
:UpdateDrvList		lda	#$00			;Füllmuster setzen.
			jsr	SetPattern

			jsr	i_Rectangle		;GEOS-Adressen löschen.
			b	$50,$50 +MAX_SERBUS_DRV*8 -1
			w	$0050,$005f
			lda	C_InputField
			jsr	DirectColor

			jsr	i_Rectangle		;Laufwerksliste löschen.
			b	$50,$50 +MAX_SERBUS_DRV*8 -1
			w	$0068,$0107
			lda	C_InputField
			jsr	DirectColor

			jsr	i_Rectangle		;Laufwerksadressen löschen.
			b	$50,$50 +MAX_SERBUS_DRV*8 -1
			w	$0110,$011f
			lda	C_InputField
			jsr	DirectColor

			jmp	getDevList		;Geräteliste aktualisieren.

;*** Laufwerk installieren.
;Übergabe: DrvAdrGEOS     = Laufwerksadresse.
;          InstallDrvType = Laufwerksmodus.
:prepareInstall		lda	newDrvUsed		;Als GEOS-Laufwerk reserviert ?
			beq	:setGEOSadr		; => Nein, weiter...

			lda	DrvAdrGEOS
			cmp	newDrvAdr		;Neue Adresse = aktuelles Laufwerk ?
			beq	:setGEOSadr		; => Ja, weiter...

			pha				;Ziel-Laufwerk zwischenspeichern.
			lda	newDrvAdr		;GEOS-Laufwerk als Aktuell setzen.
			sta	DrvAdrGEOS

;			jsr	PurgeTurbo		;TurboDOS entfernen (Nicht aktiv!).
			jsr	UninstallDrive		;Laufwerk deinstallieren.

			pla
			sta	DrvAdrGEOS		;Ziel-Laufwerk zurücksetzen.

;--- Geräteadresse für GEOS wechseln.
::setGEOSadr		ldx	DrvAdrGEOS		;Ziel-Laufwerk als GEOS-Laufwerk
			lda	#$00			;in Tabelle abmelden.
			sta	_DDC_DEVUSED -8,x

			ldx	#NO_ERROR
			lda	newDrvMode
			cmp	#DrvRAMLink		;Neues Laufwerk vom Typ RAMLink ?
			beq	:errExit		; => Ja, weiter...

;			jsr	PurgeTurbo		;TurboDOS entfernen (Nicht aktiv!).
			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	DrvAdrGEOS
			lda	_DDC_DEVTYPE -8,x	;Laufwerk vorhanden ?
			beq	:nodrv			; => Nein, weiter...

			lda	DrvAdrGEOS
			cmp	newDrvAdr		;Neue Adresse = aktuelles Laufwerk ?
			beq	:ok			; => Ja, weiter...

			jsr	_DDC_GETFREEADR		;Freie Adresse am ser.Bus suchen.
;--- Hinweis:
;Nur theoretisch kann man >20 Laufwerke
;an den ser.Bus anschließen. In der
;Praxis hat man schon bei mehr als vier
;Laufwerken Probleme.
;Daher wird hier auf die Abfrage nach
;einer freien Adresse verzichtet.
;			txa				;Freie Adresse gefunden ?
;			beq	:err			; => Nein, Fehler (AKKU=0).
;---
;			ldy	r14H			;Neue temp.Adresse.
			ldx	DrvAdrGEOS		;Adresse installiertes Laufwerk.
			jsr	_DDC_SWAPDEVADR		;Aktuelles GEOS-Laufwerk tauschen.

::nodrv			ldy	DrvAdrGEOS		;Gewähltes Laufwerk auf neue
			ldx	newDrvAdr		;Adresse für GEOS-Laufwerk setzen.
			jsr	_DDC_SWAPDEVADR

::ok			ldx	#NO_ERROR		;Kein Fehler...
			b $2c
::err			ldx	#DEV_NOT_FOUND		;Fehler...
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
;			txa				;Fehler?
;			bne	:errExit		; => Ja, Abbruch...

::errExit		rts

;*** Emulationsmodus definieren.
;    Aufruf aus Dialogbox innerhalb ":SlctNewDrv"
:SetMode41		lda	#Drv1541
			b $2c
:SetMode71		lda	#Drv1571
			b $2c
:SetMode81		lda	#Drv1581
			b $2c
:SetModeNM		lda	#DrvNative
			sta	r0L

			lda	InstallDrvType
			cmp	#DrvNative		;SD2IEC?
			bne	:1			; =? Nein, weiter...

			lda	#NULL			;Emulationsmodus für SD2IEC setzen.
			b $2c
::1			and	#%11110000		;CMD-Typ isolieren und
			ora	r0L			;Emulationsmodus ergänzen.
			sta	InstallDrvType

			lda	#$80
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Vorhandenes Laufwerk deinstallieren.
:UninstallDrive		ldx	DrvAdrGEOS
			jsr	_DDC_DEVUNLOAD		;Ggf. RAM freigeben (RAM-Laufwerk).

			ldx	DrvAdrGEOS
			jsr	_DDC_DEVCLRDATA		;Laufwerksdaten zurücksetzen.

			ldx	DrvAdrGEOS
			lda	#$00
			sta	BootConfig -8,x		;Zusätzliche Laufwerksdaten
			sta	_DDC_DEVUSED -8,x	;initialisieren.

;*** Anzahl Laufwerke ermitteln.
:numDrivesInit		ldy	#0			;Anzahl Laufwerke löschen.
			sty	numDrives
::1			lda	RealDrvType,y
			beq	:3			;Nein, weiter...
			inc	numDrives		;Anzahl Laufwerke +1.
::2			iny
			cpy	#4
			bcc	:1

::3			rts

;*** Laufwerkstreiber erneut in RAM laden.
:ReloadDkDv2RAM		lda	BootRAM_Flag
			and	#%01000000		;Laufwerkstreiber im RAM ?
			beq	:load			; => Nein, Ende...

			jsr	TurnOffDskDvRAM		;Treiber-in-RAM abschalten.

::load			lda	BootRAM_Flag		;Laufwerkstreiber in RAM einlesen
			ora	#%01000000		;wieder aktivieren.
			sta	BootRAM_Flag

;			jmp	SwapDkRAMmode		;Treiber einlesen.

;*** Laufwerkstreiber in RAM installieren.
:SwapDkRAMmode		jsr	ClrRAM_TaskMan		;Speicher für TaskManager/Spooler
			jsr	ClrRAM_Spooler		;zurücksetzen.

			lda	BootRAM_Flag		;Alle Laufwerkstreiber in RAM
			and	#%01000000		;einlesen ?
			beq	:off			; => Nein, weiter...

;--- Speicher reservieren.
			jsr	AllocRAMDskDrv		;Speicherbereich reservieren.
			txa				;Fehler ?
			beq	:ok			; => Nein, weiter...

::off			jsr	TurnOffDskDvRAM		;Treiber-in-RAM abschalten.
			jsr	GetDrvInfoDisk		;Laufwerkstreiber auf Disk suchen.

::ok			bit	Copy_firstBoot		;GEOS-Bootup - Menüauswahl ?
			bpl	:load			; => Ja, keine Parameterübernahme.

			jsr	SetRAM_TaskMan		;Speicher für TaskManager und
			jsr	SetRAM_Spooler		;Spooler reservieren.

;--- TaskManager aktualisieren.
			jsr	UpdTaskBank		;TaskMan-Bankadressen speichern.

;--- Treiber in RAM einlesen.
::load			lda	BootRAM_Flag		;Alle Laufwerkstreiber in RAM
			and	#%01000000		;einlesen ?
			beq	:exit			; => Nein, weiter...

			jsr	GetDrvInfoDisk		;Treiberliste aktualisieren.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	LoadDkDv2RAM		;Laufwerkstreiber einlesen.
			txa				;Fehler?
			beq	:exit			; => Nein, weiter...

;--- Fehler, Option deaktivieren.
::err			lda	BootRAM_Flag		;"Treiber-in-RAM"-Flag löschen.
			and	#%10111111
			sta	BootRAM_Flag
			jmp	SwapDkRAMmode		;Option deaktivieren.

::exit			jmp	GetDrvInfo		;Treiberliste im RAM aktualisieren.

;*** Alle Laufwerkstreiber/RAM abschalten.
:TurnOffDskDvRAM	lda	BootRAM_Flag		;Modus "Treiber in RAM"
			and	#%10111111		;zurücksetzen.
			sta	BootRAM_Flag

			jmp	FreeRAMDskDrv		;Speicher wieder freigeben.

;*** Dialogbox: "Treiber nicht gefunden!".
:Err_LoadDrv		lda	InstallDrvType		;Laufwerkstyp einlesen und
			jsr	GetDrvModVec		;Zeiger auf Dateiname berechnen.
			MoveW	r0,r5 			;Dateiname in ":r5" übergeben.

			lda	#FILE_NOT_FOUND
			ldx	#< Dlg_InstErrLdDrv
			ldy	#> Dlg_InstErrLdDrv
			bne	openDlgBox

;*** Boot-Laufwerk nicht mehr verfügbar.
:Err_NoSysDrive		lda	#INCOMPATIBLE
			ldx	#< Dlg_ErrNoSysDrv
			ldy	#> Dlg_ErrNoSysDrv
			bne	openDlgBox

;*** Boot-Laufwerk kann nicht gewechselt werden.
:Err_SwapSysDrv		lda	#INCOMPATIBLE
			ldx	#< Dlg_SwapDskDrv
			ldy	#> Dlg_SwapDskDrv
			bne	openDlgBox

;*** Laufwerksadresse bereits belegt.
:Err_DvAdrInUse		lda	#ILLEGAL_DEVICE
			ldx	#< Dlg_DvAdrInUse
			ldy	#> Dlg_DvAdrInUse
			bne	openDlgBox

;*** Laufwerk konnte nicht installiert werden!
:Err_InstFailed		lda	#DEV_NOT_FOUND
			ldx	#< Dlg_InstallError
			ldy	#> Dlg_InstallError
			bne	openDlgBox

;*** Dialogbox: "Nicht genügend freier Speicher!".
:Err_InstNoRAM		lda	#NO_FREE_RAM
			ldx	#< Dlg_InstErrNoRAM
			ldy	#> Dlg_InstErrNoRAM
			bne	openDlgBox

;*** Dialogbox: "Laufwerk nicht gefunden!".
:Err_DevNotFound	lda	#DEV_NOT_FOUND
			ldx	#< Dlg_DevNotFound
			ldy	#> Dlg_DevNotFound
;			bne	openDlgBox

;*** Dialogbox aufrufen.
;Übergabe: AKKU = Fehlernummer für XREG.
;          X/Y  = Zeiger auf Dialogboxdaten.
;Rückgabe: XREG = Fehlernummer.
:openDlgBox		pha
			stx	r0L
			sty	r0H
			jsr	DoDlgBox
			pla
			tax
			rts

;*** TaskManager-RAM freigeben.
:ClrRAM_TaskMan		bit	BootTaskMan		;TaskManager installiert ?
			bmi	:3			; => Nein, weiter...

			jsr	fetchTaskData		;TaskManager-Variablen einlesen.

			ldy	#$00
::1			ldx	BankTaskAdr,y		;Task installiert ?
			beq	:2			; => Nein weiter...

			tya
			pha
			txa
			jsr	FreeBank		;Bank für aktuellen Task freigeben.
			pla
			tay

::2			iny				;Zeiger auf nächsten Task.
			cpy	#MAX_TASK_ACTIV		;Alle Tasks überprüft ?
			bcc	:1			; => Nein, weiter...

::3			rts

;*** TaskManager-RAM reservieren.
:SetRAM_TaskMan		bit	BootTaskMan		;TaskManager installiert ?
			bmi	:4			; => Nein, weiter...

			ldy	#$00
::1			ldx	BankTaskAdr,y		;Task installiert ?
			beq	:3			; => Nein weiter...

			tya
			pha
			jsr	GetFreeBankL		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;Bank gefunden ?
			bne	:2			; => Nein, Task löschen...

			tax				;Speicherbank für TaskManager
			pla				;reservieren.
			pha
			tay
			txa
			sta	BankTaskAdr,y
			ldx	#%11000000
			jsr	AllocateBank
			pla
			tay
			jmp	:3

::2			pla				;Task freigeben.
			tay
			lda	#$00
			sta	BankTaskAdr,y
			dec	MaxTaskInstalled

::3			iny				;Zeiger auf nächsten Task.
			cpy	#MAX_TASK_ACTIV		;Alle Tasks überprüft ?
			bcc	:1			; => Nein, weiter...

			lda	MaxTaskInstalled	;Tasks installiert ?
			bne	:4			; => Ja, weiter...
			lda	#%10000000		;TaskManager deaktivieren.
			sta	BootTaskMan
::4			rts

;*** TaskMan-Bankadressen speichern.
:UpdTaskBank		bit	BootTaskMan		;TaskManager installiert ?
			bmi	:1			; => Nein, weiter...

			lda	BankTaskAdr		;Neue Systembank für
			sta	Flag_TaskBank		;TaskManager setzen.

			ldx	MP3_64K_DATA		;Zeiger auf SwapFile-Speicher.
			ldy	#jobFetch		;Speichertransfer: Laden.
			jsr	DoRAMOpTMenu

			ldx	Flag_TaskBank		;Zeiger auf TaskMan-Speicherbank.
			ldy	#jobStash		;Speichertransfer: Speichern.
			jsr	DoRAMOpTMenu

			jsr	stashTaskData		;TaskManager-Variablen setzen.

::1			rts

;*** TaskMan-Daten laden/speichern.
:stashTaskData		ldy	#jobStash
			b $2c
:fetchTaskData		ldy	#jobFetch

			LoadW	r0,BankTaskAdr
			LoadW	r1,RTA_TASKMAN +3
			LoadW	r2,2*9 +1

			lda	Flag_TaskBank		;Zeiger auf Speicherbank.
			sta	r3L

			jmp	DoRAMOp			;StashRAM/FetchRAM ausführen.

;*** TaskManager-Menu laden/speichern.
;Übergabe: YReg = Job-Code.
;          XReg = Speicherbank.
:DoRAMOpTMenu		LoadW	r0,BASE_DDRV_DATA	;Adresse C64-RAM  (max.$2100 Bytes).
			LoadW	r1,RTA_TASKMAN		;Adresse GEOS-DACC.
			LoadW	r2,RTS_TASKMAN		;Größe TaskManager    ($2000 Bytes).

			stx	r3L			;Speicherbank setzen.

			jmp	DoRAMOp			;StashRAM/FetchRAM ausführen.

;*** TaskManager-RAM freigeben.
:ClrRAM_Spooler		lda	Flag_Spooler		;Spooler aktiviert ?
			bpl	:1			; => Nein, weiter...
			lda	Flag_SpoolMinB		;SpoolerRAM belegt ?
			ora	Flag_SpoolMaxB
			beq	:1			; => Nein, weiter...

			lda	Flag_SpoolMaxB		;Größe SpoolerRAM berechnen.
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			tay
			lda	Flag_SpoolMinB
			jsr	FreeBankTab		;Speicher freigeben.
::1			rts

;*** SpoolerRAM reservieren.
:SetRAM_Spooler		lda	Flag_Spooler		;Spooler aktiviert ?
			bpl	:3			; => Nein, weiter...
			lda	Flag_SpoolMinB		;SpoolerRAM belegt ?
			ora	Flag_SpoolMaxB
			beq	:3			; => Nein, weiter...

			lda	Flag_SpoolMaxB		;Größe SpoolerRAM berechnen.
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			sta	BootSpoolSize

::1			ldy	BootSpoolSize		;Speicher für Spooler suchen.
			jsr	GetFreeBankLTab
			cpx	#NO_ERROR		;Speicher frei ?
			beq	:2			; => Ja, weiter...
			dec	BootSpoolSize		;SpoolerRAM -64K
			bne	:1			; => weitersuchen.

			lda	#$00			;Kein Speicher für Spooler frei.
			sta	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
			sta	Flag_Spooler
			sta	BootSpooler
			rts

::2			ldx	#$00
			stx	Flag_SpoolADDR +0
			stx	Flag_SpoolADDR +1
			sta	Flag_SpoolMinB
			sta	Flag_SpoolADDR +2
			ldx	#%11000000
			jsr	AllocateBankTab		;SpoolerRAM belegen.

			ldy	BootSpoolSize
			dey
			tya
			clc
			adc	Flag_SpoolMinB
			sta	Flag_SpoolMaxB
::3			rts

;*** Diskettenbezeichnung löschen.
:ClearDiskName		ldx	#r1L
			jsr	GetPtrCurDkNm
			LoadW	r0,TxNODKNAME
			ldy	#$10
::1			lda	(r0L),y
			sta	(r1L),y
			dey
			bpl	:1
			rts

;*** Start-Laufwerk aktivieren.
;    Übergabe:		-
;    Rückgabe:		xReg	= Fehlermeldung.
:SetBootDevice		jsr	PurgeTurbo		;TurboDOS entfernen.

			ldx	#DEV_NOT_FOUND
			ldy	SystemDevice
			lda	driveType -8,y		;Ist Laufwerk verfügbar ?
			beq	:51			; => Nein, Abbruch...

			sty	curDevice		;Variablen aktualisieren.
			sty	curDrive
			sta	curType

			jsr	FetchRAM_DkDrv		;Treiber aus REU nach RAM.

			ldx	#NO_ERROR		;OK!
::51			rts

;*** Partition aktualisieren.
;Übergabe: XREG = Laufwerksadresse.
;          YREG = Partition.
:updDiskPart		cpy	#$00
			beq	:cbm

			lda	RealDrvMode -8,x	;Laufwerkstyp einlesen.
;			and	#%10000000		;CMD-Laufwerk ?
			bpl	:cbm			; => Nein, weiter...

			sty	r3H			;Aktive Partition setzen.

::cmd			jmp	OpenPartition		;CMD: Partition öffnen.
::cbm			jmp	OpenDisk		;Standard: Diskette öffnen.

;*** Laufwerkstreiber "in REU kopieren" / "aus REU einlesen."
:FetchRAM_DkDrv		ldy	#%10010001
			b $2c
:StashRAM_DkDrv		ldy	#%10010000
			lda	#< DISK_BASE
			sta	r0L
			lda	#> DISK_BASE
			sta	r0H
			ldx	SystemDevice
			lda	DskDrvBaseL -8,x
			sta	r1L
			lda	DskDrvBaseH -8,x
			sta	r1H
			LoadW	r2 ,DISK_DRIVER_SIZE
			LoadB	r3L,$00
			jmp	DoRAMOp

;*** Laufwerkstyp ermitteln  (GEOS: #8 - #11).
;    Übergabe:		AKKU	= Geräteadresse.
;    Rückgabe:		AKKU	= 41=$01, 71=$02, 81=$03, FD=$1x, HD=$2x, RL=$3x
;			yReg	= 41=$01, 71=$02, 81=$03, FD=$10, HD=$20, RL=$30
:TestDriveType		sta	r14L
			tax
			lda	_DDC_DEVTYPE -8,x
			bne	:found
::nodrv			lda	#$00			;Kein Laufwerk installiert.
			tay
			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk gefunden.
::found			lda	#$00			;Partitionsformat löschen.
			sta	BootPartType -8,x

			lda	_DDC_DEVTYPE -8,x
			ldy	_DDC_DEVUSED -8,x	;Laufwerk unter GEOS installiert ?
			bne	:nodrv			; => Ja, kein Laufwerk.

			tay
			and	#DrvCMD			;CMD-Laufwerk gefunden ?
			bne	:cmd			; => Ja, weiter...

			ldx	#NO_ERROR
			tya				;Standard-Laufwerk, Ende...
			rts

;--- CMD-Laufwerk gefunden.
::cmd			ldx	r14L
			jsr	GetPartType		;Partitionsdaten einlesen.
							;Rückgabe: AKKU = Typ, YREG = PNr.
			cpx	#NO_ERROR		;Laufwerksfehler ?
			bne	:err			; => Ja, Abbruch...

::cmdpart		ldx	r14L
			sta	BootPartType -8,x	;Partitionsformat speichern.

			lda	_DDC_DEVTYPE -8,x
			cmp	#DrvRAMLink		;CMD-RAMLink-Laufwerk ?
			bne	:1			; => Nein, weiter...

			stx	DriveRAMLink		;RL-Adresse speichern.

::1			tay
			ora	BootPartType -8,x
			ldx	#NO_ERROR		;Flag: "Kein Fehler!".
::err			rts				;Ende...

;*** Partitionstyp einlesen.
;    Aus dem Partitionstyp (1=41, 2=71, 3=81, 4=Native) und dem Laufwerkstyp
;    ($10=FD, $20=HD, $30=RAMLink) wird das Laufwerksformat erzeugt.
;    ($13,FD81, $31=RAMLink41 usw...)
;Übergabe: r14L = Laufwerksadresse.
;Rückgabe: AKKU = Partitionstyp 41/71/81/NM.
;          YREG = Partitionsnummer.
;          XREG = Status, $00 = NO_ERROR.
:GetPartType		lda	#$00			;Systempartition-Daten einlesen.
			sta	GP_Command +3

;			ldx	r14L			;Laufwerksadr. einlesen.
			jsr	GetPartData		;Partitionsformat bestimmen.

			lda	dirEntryBuf +0		;Partitionstyp einlesen.
			cmp	#$ff			;Systempartition vorhanden?
			bne	:3			; => Nein, keine Disk, weiter...
			sta	GP_Command +3		;Aktive Partition einlesen.

;			ldx	r14L			;Laufwerksadr. einlesen.
			jsr	GetPartData

			ldx	dirEntryBuf +0		;CMD-Partitionsformat einlesen.
			beq	:2			; $00 => Nicht erstellt.
			dex				;CMD-Format nach GEOS wandeln.
			bne	:1
			ldx	#DrvNative
::1			txa				;Partitionsformat.
			ldy	dirEntryBuf +2
			ldx	#NO_ERROR		;Flag für kein Fehler.
			rts

::2			ldx	r14L			;Laufwerksadr. einlesen.
			lda	BootPartType -8,x	;Startvorgang einlesen.
			bne	:4			; => Formatvorgabe übernehmen.
::3			lda	#Drv1581		;Vorgabewert, wenn bei einer CMD FD
							;keine partitionierte Diskette im
							;Laufwerk liegt!
::4			ldy	BootPartRL -8,x		;Startpartition definiert ?
			bne	:5			; => Ja, weiter...
			ldy	#$01			;Vorgabewert für RL-Partition.
::5			ldx	#NO_ERROR		;Flag: "Kein Fehler".
			rts

;*** Partitionsdaten einlesen.
;Übergabe: r14L = Laufwerksadresse.
;Rückgabe: dirEntryBuf = 30 Byte Partitionsdaten.
:GetPartData		jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00
			sta	STATUS			;Gerät aktivieren.

			jsr	UNLSN

			lda	r14L
			jsr	LISTEN
			lda	#$ff			;OPEN#15.
			jsr	SECOND

			ldy	#0			;Partitionstyp abfragen.
::1			lda	GP_Command,y
			jsr	CIOUT
			iny
			cpy	#5
			bne	:1

			jsr	UNLSN			;Gerät deaktivieren.

			lda	r14L			;Laufwerksadr. einlesen und
			jsr	TALK			;Laufwerk auf "TALK" umschalten.
			lda	#$ff
			jsr	TKSA

			ldy	#$00
::2			jsr	ACPTR			;Partitionsinformationen einlesen.
			sta	dirEntryBuf,y
			iny
			cpy	#30
			bcc	:2

			jsr	ACPTR			;Abschlussbyte ($0d) überlesen.

			jsr	UNTALK

			lda	r14L			;Laufwerksadr. einlesen und
			jsr	LISTEN			;Laufwerk abschalten.
			lda	#$ef
			jsr	SECOND
			jsr	UNLSN

::3			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Aktuelle Partition abfragen.
:getCurPart		lda	#$ff			;Aktive Partition einlesen.
			sta	r3H

			lda	#< dirEntryBuf
			sta	r4L
			lda	#> dirEntryBuf
			sta	r4H

			jmp	GetPDirEntry

;*** Boot-RAMLink-Modus übernehmen.
:SetBootRAMLink		lda	BootDrvRAMLink
			bne	:1
			lda	#7
::1			clc
			adc	#1
			cmp	#12
			bcc	:2
			lda	#$00
::2			sta	BootDrvRAMLink

:GetBootRAMLink		lda	BootDrvRAMLink
			beq	:1
			and	#%00000011
			clc
			adc	#$01
::1			asl
			asl
			tax
			ldy	#0
::2			lda	TxBootRL,x
			sta	curBootDrvRL,y
			inx
			iny
			cpy	#4
			bcc	:2
			rts

;*** Nr. des Laufwerkstreibers berechnen.
;Übergabe: AKKU   = Laufwerkstyp ($01,$41,$83,$23 usw...)
;Rückgabe: r0     = Zeiger auf Dateiname.
;          AKKU   = $00 = Kein Laufwerk.
;                 = $xx = Laufwerk erkannt.
;                   $FF = Laufwerk unbekannt.
;          xReg   = Nr. Eintrag in Typentabelle.
:GetDrvModVec		tax				;Typ = $00 ?
			beq	:exit			; => Ja, Ende...

			ldx	#1			;Zeiger auf Typen-Tabelle.
::loop			ldy	DRVINF_NG_TYPES,x	;Typ aus Tabelle einlesen.
			beq	:unknown		; => Ende erreicht ? Ja, Ende...
			cmp	DRVINF_NG_TYPES,x	;Mit aktuellem Modus vergleichen.
			beq	:found			; => Gefunden ? Ja, weiter...
			inx				;Zeiger auf nächsten Typ.
			cpx	#DDRV_MAX		;Max. Anzahl Typen durchsucht ?
			bne	:loop			; => Nein, weiter...

::unknown		lda	#$ff			;Modus: "Kein Laufwerk".
::exit			rts				;Ende.

::found			stx	InstallDrvNum		;Nummer in Treiberliste merken.
			pha				;Laufwerkstyp zwischenspeichern.

			stx	r0L			;Zeiger auf Dateiname für
			lda	#$00			;Laufwerkstreiber berechnen.
			sta	r0H

			txa
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			clc
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H

::1			AddVW	DRVINF_NG_NAMES,r0

			pla				;Laufwerkstyp wieder einlesen.
			rts

;*** Installationsroutine und Laufwerkstreiber einlesen.
;    Übergabe:		AKKU	= Laufwerkstyp.
;    Rückgabe:		xReg	= Fehlermeldung.
:LoadDkDvData		pha
			ldx	DrvAdrGEOS
			lda	#$00			;"Treiber-im-RAM"-Status
			sta	drvNotInRAM -8,x	;zurücksetzen.
			sta	drvNotCached -8,x	;Kein Ladefehler durch CacheLoad.
			pla

			bit	firstBoot		;GEOS-BootUp ?
			bmi	:0			; => Nein, weiter...

;			ldx	DrvAdrGEOS
			cpx	#$08			;Erstes Laufwerk installieren ?
			beq	:1			; => Ja, weiter...
::0			cmp	DDrv_Type		;Treiber bereits geladen ?
			beq	:load_skip		; => Ja, weiter...

::1			tax				;Laufwerkstyp = $00 ?
			beq	:exit			; => Ja, Ende...

			jsr	GetDrvModVec		;Vektor auf Datensatz mit Treiber
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:err			; => Ja, Ende...
			tay				;Laufwerk deinstallieren?
			beq	:ok			; => Ja, Ende...

			lda	MP3_64K_DISK		;Alle Treiber in RAM ?
			bne	:load_ram		; => Nein, weiter...

::load_disk		jmp	LoadDkDvDisk		;Treiber von Diskette laden.
::load_ram		jmp	LoadDkDvRAM		;Treiber aus RAM einlesen.

::load_skip		lda	DrvAdrGEOS		;Ziel-Laufwerk für die
			sta	DDrv_AdrGEOS		;Laufwerksinstallation festlegen.

::ok			ldx	#NO_ERROR
::exit			rts

::err			ldx	#DEV_NOT_FOUND
			rts

;*** Treiber aus RAM laden.
:LoadDkDvRAM		lda 	InstallDrvNum		;Nummer in Treiberliste einlesen.
			tax
			asl
			tay
			lda	DRVINF_NG_START +0,y
			sta	r1L
			lda	DRVINF_NG_START +1,y
			sta	r1H
			lda	DRVINF_NG_SIZE +0,y
			sta	r2L
			lda	DRVINF_NG_SIZE +1,y
			sta	r2H
			lda	DRVINF_NG_RAMB,x
			sta	r3L

;			lda	r3L			;Speicherbank definiert ?
			bne	:1			; => Ja, aus RAM laden.

			ldy	DrvAdrGEOS		;Treiber nicht im RAM.
			lda	#$ff
			sta	drvNotInRAM -8,y	;Fehler-Flag setzen und
			bne	LoadDkDvDisk		;Treiber von Disk laden.

::1			LoadW	r0,BASE_DDRV_DATA
			jsr	FetchRAM		;Treiber aus REU einlesen.

			lda	DrvAdrGEOS		;Ziel-Laufwerk für die
			sta	DDrv_AdrGEOS		;Laufwerksinstallation festlegen.

			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Treiber von Diskette laden.
:LoadDkDvDisk		ldx 	InstallDrvNum		;Nummer in Treiberliste einlesen.
			lda	DRVINF_NG_FOUND,x	;Ist Treiber verfügbar ?
			beq	:search

			cmp	curDrive
			beq	:1

			jsr	SetDevice		;Treiberlaufwerk aktivieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

;--- Auf Boot-Laufwerk suchen.
::1			lda	InstallDrvNum		;Zeiger auf ersten Datenblock aus
			asl				;aus Systemtabelle/Cache einlesen.
			tax
			lda	DRVINF_NG_START +0,x
			ldy	DRVINF_NG_START +1,x
			jsr	readDDrvData		;Treiberdatei einlesen.
			txa				;Fehler ?
			beq	:done			; => Nein, Ende...

;--- Auf anderen Laufwerken suchen.
::search		lda	SystemDevice		;Startlaufwerk aktivieren.
			jsr	SetDevice

			ldx	DrvAdrGEOS
			lda	drvNotInRAM -8,y	;Fehler-Flag setzen und
			bne	:2
			lda	#$ff
			sta	drvNotCached -8,x	;Ladefehler durch CacheLoad.

::2			lda	InstallDrvType
			jsr	GetDrvModVec		;Zeiger auf Dateiname berechnen.
			cmp	#$00
			beq	:err
			cmp	#$ff
			beq	:err

			lda	r0L			;Zeiger auf Dateiname.
			sta	r6L
			lda	r0H
			sta	r6H

			jsr	FindFile		;Datei auf Disk suchen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			lda	dirEntryBuf +1 		;Zeiger auf ersten Datenblock
			ldy	dirEntryBuf +2		;der Treiberdatei einlesen.
			jsr	readDDrvData		;Treiberdatei einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Ende...

::done			lda	DrvAdrGEOS		;Ziel-Laufwerk für die
			sta	DDrv_AdrGEOS		;Laufwerksinstallation festlegen.

;			ldx	#NO_ERROR		;Kein Fehler.
			rts

::err			ldx	#DEV_NOT_FOUND		;Treiber nicht gefunden.
::exit			rts

;*** Treiberdaten einlesen.
;Übergabe: A/Y = Zeiger auf ersten Datenblock.
;Rückgabe: X = Fehlercode.
:readDDrvData		sta	r1L
			sty	r1H

			lda	#< BASE_DDRV_DATA
			sta	r7L
			lda	#> BASE_DDRV_DATA
			sta	r7H

			lda	#< SIZE_DDRV_DATA
			sta	r2L
			lda	#> SIZE_DDRV_DATA
			sta	r2H

			jmp	ReadFile		;Treiberdatei einlesen.

;*** Speicher für RAM-Laufwerkstreiber reservieren.
:AllocRAMDskDrv		ldx	#$00			;Tabelle mit Adresse der
			txa				;Speicherbank für Laufwerkstreiber
::1			sta	DRVINF_NG_RAMB,x	;löschen.
			inx
			cpx	#DDRV_MAX
			bcc	:1

			jsr	AllocRAMDsk64K		;Speicher reservieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			lda	r0L			;Erste Speicherbank für
			sta	MP3_64K_DISK		;Laufwerkstreiber in REU speichern.

::err			rts

;*** Nächste Speicher für RAM-Laufwerkstreiber reservieren.
:AllocRAMDsk64K		jsr	GetFreeBankL		;Freie Speicherbank suchen.
			cpx	#NO_ERROR		;Speicher frei ?
			bne	:err			; => Nein, Abbruch...

;			lda	r0L
			ldx	#%11000000		;GEOS/System-Speicherbank.
			jsr	AllocateBank		;Speicher reservieren.

::err			rts

;*** Speicher für RAM-Laufwerkstreiber reservieren.
:FreeRAMDskDrv		ldx	MP3_64K_DISK		;Auf MP3-Speicher für
			inx				;"Alle Treiber in REU" testen.
			inx
			cpx	MP3_64K_DATA
			bne	:ng			; => GD3/NG, weiter...

;--- Standard-Laufwerkstreiber.
			lda	MP3_64K_DISK		;2x64K Speicher freigeben.
			ldy	#$02
			jsr	FreeBankTab
			jmp	:off			;Funktion abschalten.

;--- NextGeneration-Laufwerkstreiber.
::ng			lda	MP3_64K_DISK
			sta	r0L
			jsr	FreeBank		;Erste Speicherbank freigeben.

			ldx	#$00			;Weitere Treiberanwendungen suchen.
::1			txa
			pha
			lda	DRVINF_NG_RAMB,x	;Treiberanwendung gespeichert ?
			beq	:2			; => Nein, weiter...
			cmp	r0L			;Speicher bereits freigegeben ?
			beq	:2			; => Ja, weiter...
			jsr	FreeBank		;Speicher freigeben.
::2			pla
			tax
			inx
			cpx	#DDRV_MAX		;Alle Speicherbänke geprüft ?
			bcc	:1			; => Nein, weiter...

;--- "Treiber in RAM" deaktivieren.
::off			lda	#$00
			sta	MP3_64K_DISK
			rts

;*** Laufwerkstreiber in REU kopieren.
:LoadDkDv2RAM		ldx	#NULL			;Keine Treiber im RAM.
			stx	DRVINF_NG_RAMB

			jsr	loadDrvFiles		;Treiber in RAM laden.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			lda	BootDrvToRAM		;Status "Treiber in RAM" speichern.
			sta	DRVINF_NG_RAMB

			jsr	SetDiskDatReg		;Treiberinformationen in
			jsr	StashRAM		;REU zwischenspeichern.

			ldx	#NO_ERROR		;Kein Fehler.
			rts

::err			ldx	#< Dlg_ErrLdDk2RAM
			ldy	#> Dlg_ErrLdDk2RAM
;			lda	#NULL
			jsr	openDlgBox

			ldx	#CANCEL_ERR
			rts

;*** Laufwerkstreiber laden und in Speicher kopieren.
;Übergabe: r12H = Max.Anzahl Laufwerkstreiber.
:loadDrvFiles		LoadW	r14,SIZE_DDRV_INFO

			lda	MP3_64K_DISK		;Speicherbank festlegen.
			sta	r15L

			lda	#0			;Zeiger auf ersten Laufwerkstreiber.
			sta	r15H
			jmp	:next			;Eintrag #0 überspringen.

::loop			lda	DRVINF_NG_FOUND,x	;Treiber gefunden?
			beq	:next			; => Nein, überspringen...

			lda	BootDrvToRAM
			and	dataDrvToRAM,x		;Gruppe in RAM kopieren ?
			beq	:next			; => Ja, weiter...

			txa				;Zeiger auf ersten Track/Sektor
			asl				;aus Systemtabelle/Cache einlesen.
			tax
			lda	DRVINF_NG_START +0,x
			ldy	DRVINF_NG_START +1,x
			jsr	readDDrvData		;Treiberdatei einlesen.
			txa				;Fehler ?
			bne	:err			; => Nein, Ende...

			lda	r7L			;Größe des eingelesenen
			sec				;Datensatzes berechnen.
			sbc	#< BASE_DDRV_DATA
			sta	r2L
			lda	r7H
			sbc	#> BASE_DDRV_DATA
			sta	r2H

			LoadW	r0,BASE_DDRV_DATA	;Startadresse im Speicher.
			MoveW	r14,r1			;Startadresse in REU.

			lda	r15L			;64K-Speicherbank in REU.
			sta	r3L

;--- Hinweis:
;":StashDskDrv" prüft ob der aktuelle
;Treiber noch in die aktuelle 64K-Bank
;passt. Falls nicht wird die Speicher-
;bank entsprechend korrigiert.
			jsr	StashDskDrv		;Treiber in DACC kopieren.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			ldx	r15H
			lda	r3L			;Speicherbank.
			sta	r15L
			sta	DRVINF_NG_RAMB,x

			txa				;Position des aktuellen Datensatz
			asl				;in REU zwischenspeichern.
			tax
			lda	r1L			;Startadresse.
			sta	DRVINF_NG_START +0,x
			lda	r1H
			sta	DRVINF_NG_START +1,x
			lda	r2L			;Größe.
			sta	DRVINF_NG_SIZE +0,x
			lda	r2H
			sta	DRVINF_NG_SIZE +1,x

			lda	r1L			;Position für nächsten Datensatz.
			clc
			adc	r2L
			sta	r14L
			lda	r1H
			adc	r2H
			sta	r14H

::next			inc	r15H			;Nächste Treiberdatei.
			ldx	r15H
			cpx	r12H			;Alle Treiber getestet?
			bcs	:ok			; => Ja, Ende...
			jmp	:loop			; => Nein, weiter...

::ok			ldx	#NO_ERROR
::err			rts

;*** Laufwerkstreiber in Speicher kopieren.
:StashDskDrv		lda	r1L			;Über 64K-Speichergrenze hinweg
			clc				;Datenbytes in REU speichern ?
			adc	r2L
			sta	r3H
			lda	r1H
			adc	r2H
			bcc	:1			; => Nein, weiter...
			ora	r3H
			beq	:1			; => Nein, weiter...

			lda	r0L			;":r0" zwischenspeichern.
			pha
			lda	r0H
			pha

			jsr	AllocRAMDsk64K		;Mehr Speicher reservieren.
			ldy	r0L			;Neue Speicherbank einlesen.

			pla				;":r0" zurücksetzen.
			sta	r0H
			pla
			sta	r0L

			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			sty	r3L			;Neue Speicherbank setzen.

			lda	#$00			;Zeiger auf Anfang der nächsten
			sta	r1L			;Speicherbank.
			sta	r1H

::1			jsr	StashRAM		;Treiber in REU kopieren.

::err			rts

;*** Zeiger auf DACC für Laufwerksdaten setzen.
:SetDiskDatReg		lda	#< BASE_DDRV_INFO
			sta	r0L
			lda	#> BASE_DDRV_INFO
			sta	r0H

			lda	#$00
			sta	r1L
			sta	r1H

			lda	#< SIZE_DDRV_INFO
			sta	r2L
			lda	#> SIZE_DDRV_INFO
			sta	r2H

			lda	MP3_64K_DISK
			sta	r3L
			rts

;*** Informationen zu den Laufwerkstreibern laden.
;
; Speicheraufteilung:
;
;Bank#0:
;$0000-$02FF : Treiber-Informationen.
;  $0000     : Treiber-Startadresse in DACC.
;  $0040     : Treiber-Größe in Bytes.
;  $0080     : Treiber-Bank.
;  $0080     : Treiber #0: Kopie von ":BootDrvToRAM".
;              Das Byte ist ungenutzt da nur Treiber von 1-31 gültig sind.
;              Beim Start von GD.CONFIG wird mit dem Inhalt dieses Bytes
;              die Option ":BootDrvToRAM" initialisiert.
;  $00A0     : Treiber verfügbar.
;  $00C0     : Treiber-Typ.
;  $00E0     : Treiber-Name.
;$0300-$FFFF : Treiber Teil #1.
;
;Bank#1:
;$0000-$FFFF : Treiber Teil #2.
;
:GetDrvInfo		lda	MP3_64K_DISK		;"Treiber von Diskette laden ?"
			beq	GetDrvInfoDisk		; => Ja, weiter...

;*** Laufwerkstreiber aus RAM installieren.
:GetDrvInfoRAM		jsr	SetDiskDatReg		;Treiber bereits im RAM. Treiber-
			jsr	FetchRAM		;Informationen einlesen.

			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Laufwerkstreiber auf Diskette suchen.
:GetDrvInfoDisk		lda	SystemDevice		;Startlaufwerk aktivieren.
			jsr	SetDevice

			php				;IRQ sperren.
			sei

			lda	#$00
			sta	r12H
			ldy	#DDRV_MAX -1
::1			ldx	dataDrvToRAM,y		;Anzahl Laufwerkstreiber
			beq	:2			;ermitteln.

			ldx	r12H
			bne	:2
			sty	r12H
			inc	r12H

;			lda	#NULL			;Treiberinformationen löschen.
::2			sta	DRVINF_NG_START + 0,y
			sta	DRVINF_NG_START +32,y
			sta	DRVINF_NG_SIZE  + 0,y
			sta	DRVINF_NG_SIZE  +32,y
			sta	DRVINF_NG_RAMB     ,y
			sta	DRVINF_NG_FOUND    ,y
			dey
			bpl	:1

			lda	r12H			;Max. Anzahl Treiber.
			sta	r12L

			lda	#MAX_DIR_SEARCH		;Max. Anzahl Dateien testen.
			sta	r15H

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch.

			jsr	Get1stDirEntry		;Erster DIR-Sektor lesen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch.

			lda	#$00
::loop			tay				;yReg=$00.
			lda	(r5L),y			;Gelöschter Eintrag?
			beq	:next			; => Ja, weiter...
			iny
			lda	(r5L),y			;Sektoradresse gültig?
			beq	:next			; => Nein, weiter...

			ldy	#21
			lda	(r5L),y			;VLIR-Datei?
			bne	:next			; => Ja, weiter...
			iny
			lda	(r5L),y			;GEOS-Dateityp einlesen.
			cmp	#DISK_DEVICE		;Laufwerkstreiber?
			bne	:next			; => Nein, weiter...

			ldy	#3			;"GD.D..." ?
			lda	(r5L),y
			cmp	#"G"
			bne	:next
			iny
			lda	(r5L),y
			cmp	#"D"
			bne	:next
			iny
			iny
			lda	(r5L),y
			cmp	#"D"
			bne	:next			; => Nein, weiter...

			jsr	testDrvNames		;Dateiname testen.
			txa				;Laufwerkstreiber?
			bne	:next			; => Nein, weiter...

			dec	r12L			;Alle Treiberdateien gefunden?
			beq	:done			; => Ja, Ende...

::next			bit	firstBoot		;Start als Anwendung?
			bmi	:skip			; => Ja, alle Dateien durchsuchen.

			dec	r15H			;Max. Anzahl Dateien getestet?
			beq	:done			; => Ja, Ende...

::skip			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...
			tya				;Verzeichnis-Ende erreicht?
			beq	:loop			; => Nein, weiter...

::done			ldx	#NO_ERROR

::err			plp
			rts

;*** Auf Laufwerkstreiber testen.
;Übergabe: r12H = Max.Anzahl Laufwerkstreiber.
;          r5   = Zeiger auf Verzeichniseintrag.
;Ändert  : A,X,Y,r14,r15L
:testDrvNames		lda	#< DRVINF_NG_NAMES
			sec
			sbc	#< 3
			sta	r14L
			lda	#> DRVINF_NG_NAMES
			sbc	#> 3
			sta	r14H			;Zeiger auf Treibernamen.

			lda	#0			;Zähler zurücksetzen.
			sta	r15L
			beq	:next			;Eintrag #0 überspringen.

::loop			lda	DRVINF_NG_FOUND,x	;Treiber bereits gefunden?
			bne	:next			; => Ja, weiter...

			ldy	#$03
::1			lda	(r14L),y		;Dateinamen vergleichen.
			beq	:2			; => Ende Modul-Name erreicht...
			cmp	(r5L),y
			bne	:next			; => Falsche Datei...
			iny				;Kompletter Modul-Name geprüft?
			bne	:1			; => Nein, weiter...

::2			cpy	#$13
			beq	:found			; => Richtige Datei...
			lda	(r5L),y
			iny
			cmp	#$a0
			beq	:2
			bne	:next			; => Falsche Datei...

::found			lda	r15L			;Zeiger auf ersten Track/Sektor
			asl				;in Systemtabelle/Cache kopieren.
			tax
			ldy	#1			;Zeiger auf ersten Track/Sektor
			lda	(r5L),y			;in Cache zwischenspeichern.
			sta	DRVINF_NG_START +0,x
			iny
			lda	(r5L),y
			sta	DRVINF_NG_START +1,x

			ldx	r15L
			lda	curDrive		;Laufwerksadresse
			sta	DRVINF_NG_FOUND,x	;in Cache zwischenspeichern.

			ldx	#NO_ERROR
			rts

::next			jsr	add_17_r14		;Zeiger auf nächsten Namen.

			inc	r15L			;Nächste Treiberdatei.
			ldx	r15L
			cpx	r12H			;Alle Treiber getestet?
			bcc	:loop			; => Nein, weiter...

			ldx	#FILE_NOT_FOUND
			rts

;*** Neuen Laufwerksmodus auswählen.
:SlctNewDrvMode		lda	MP3_64K_DISK
			bne	:1
			lda	BootRAM_Flag
			and	#%01000000
			beq	reloadList
::1			lda	#DBUSRICON		;"DISK" in DialogBox einbinden.
			b $2c
:reloadList		lda	#NULL			;"DISK"-Icon ausblenden.
			sta	dlgSlctDisk

			jsr	i_FillRam
			w	DDRV_MAX*17 +DDRV_MAX
			w	SlctDvNameTab
			b	$00

			lda	#< SlctDvNameTab
			sta	r10L
			lda	#> SlctDvNameTab
			sta	r10H

			lda	#< DRVINF_NG_NAMES
			sta	r11L
			lda	#> DRVINF_NG_NAMES
			sta	r11H

			lda	#0
			sta	r12L			;Anzahl verfügbare Laufwerkstreiber.
			sta	r12H			;Zähler Laufwerkstreiber.

			beq	:2			;Modus "Kein Laufwerk" übernehmen.

::1			lda	DRVINF_NG_FOUND,x	;Laden von Laufwerk definiert ?
			beq	:4			; => Nein, weiter...
			lda	DRVINF_NG_TYPES,x	;Laufwerksmodus definiert ?
			beq	:4			; => Nein, weiter...

::2			ldy	r12L			;Laufwerksmodus in
			sta	SlctDvTypeTab,y		;Tabelle übernehmen.

			ldy	#0			;Laufwerksname in
::3			lda	(r11L),y		;Tabelle übernehmen.
			sta	(r10L),y
			iny
			cpy	#16
			bcc	:3

			inc	r12L			;Anzahl verfügbare
			jsr	add_17_r10		;Laufwerkstreiber +1.

::4			jsr	add_17_r11		;Nächster Laufwerkstreiber.

			inc	r12H
			ldx	r12H
			cpx	#DDRV_MAX		;Alle Treiber durchsucht?
			bcc	:1			; => Nein, weiter...

			lda	#< dataFileName		;Wird nicht verwendet, muss aber
			sta	r5L			;für die Dateiauswahlbox auf einen
			lda	#> dataFileName		;gültigen Bereich gesetzt werden.
			sta	r5H

			ldx	#< Dlg_SlctDMode
			ldy	#> Dlg_SlctDMode
;			lda	#NULL
			jsr	openDlgBox		;Laufwerkstyp auswählen.

			ldx	#CANCEL_ERR
			lda	sysDBData
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:exit			; => Ja, Ende...
			cmp	#DISK
			bne	:5

			jsr	GetDrvInfoDisk		;Treiberliste aktualisieren.
			jmp	reloadList		;Auswahl erneut anzeigen.

::5			ldx	DB_GetFileEntry
			ldy	SlctDvTypeTab,x

			ldx	#NO_ERROR
::exit			rts

;*** Zeiger auf nächsten Namen setzen.
:add_17_r10		ldx	#r10L
			b $2c
:add_17_r11		ldx	#r11L
			b $2c
:add_17_r14		ldx	#r14L
			lda	zpage +0,x
			clc
			adc	#17
			sta	zpage +0,x
			bcc	:1
			inc	zpage +1,x
::1			rts

;*** Farben für Info-Bildschirm ausgeben.
:DrawInfoColor		lda	#$f0
			jsr	i_UserColor
			b	$09,$09,$03,$01

			lda	#$f0
			jsr	i_UserColor
			b	$09,$0b,$03,$01

			lda	#ERR_COL_INSTALL
			jsr	i_UserColor
			b	$09,$0d,$03,$01

			lda	#ERR_COL_DRV2RAM
			jsr	i_UserColor
			b	$09,$0f,$03,$01

			lda	#ERR_COL_CACHE
			jsr	i_UserColor
			b	$09,$11,$03,$01

			lda	#$10
			jsr	i_UserColor
			b	$09,$14,$03,$02

			jsr	i_BitmapUp
			w	drvStatErr
			b	$09 +1
			b	$14 *8
			b	$01
			b	$08

			jsr	i_BitmapUp
			w	drvStatOK
			b	$09 +1
			b	$15 *8
			b	$01
			b	$08

			rts

;*** Systemvariablen.
:DrvAdrGEOS		b $00
:InstallDrvType		b $00
:InstallDrvNum		b $00
:drvListCount		b $00

;*** Laufwerksinstallation.
:drvNotInRAM		s $04				;$FF = "Treiber-in-RAM"-Fehler.
:drvNotCached		s $04				;$FF = Treiber nicht im Cache.
:drvInstErr		b $00				;Anzahl Fehler.

:drvStatOK		; OK
<MISSING_IMAGE_DATA>

:drvStatErr		; Error
<MISSING_IMAGE_DATA>

:drvNameL		b < drvNameInfA
			b < drvNameInfB
			b < drvNameInfC
			b < drvNameInfD
:drvNameH		b > drvNameInfA
			b > drvNameInfB
			b > drvNameInfC
			b > drvNameInfD

:drvNameInfA		; A:
<MISSING_IMAGE_DATA>

:drvNameInfB		; B:
<MISSING_IMAGE_DATA>

:drvNameInfC		; C:
<MISSING_IMAGE_DATA>

:drvNameInfD		; D:
<MISSING_IMAGE_DATA>

;*** Systemübersicht Laufwerke.
:SysDrvTab		s MAX_SERBUS_DRV
:SysDrvAdrTab		s MAX_SERBUS_DRV

;*** Laufwerksinstallation.
:RL_Aktiv		b $00
:DriveRAMLink		b $00
:TxSD2IEC		b "(SD2IEC)",NULL		;Kennung für SD2IEC-Laufwerke.
:TxVICEFS		b "VICE/VDrive",NULL

;*** Variablen zum Partitionswechsel.
:GP_Command		b "G-P",$ff,$0d

;*** Systemtexte.
if LANG = LANG_DE
:TxNODRIVE		b "Kein Laufwerk!",NULL
:TxUNKNOWN		b "Unbekannt!",NULL
:TxNODKNAME		b "(Keine Diskette)",NULL
endif
if LANG = LANG_EN
:TxNODRIVE		b "No drive!",NULL
:TxUNKNOWN		b "Unknown drive!",NULL
:TxNODKNAME		b "(No disk found!)",NULL
endif

:TxBootInit		; INIT...
<MISSING_IMAGE_DATA>

:TxBootInit_x		= .x
:TxBootInit_y		= .y

:TxBootRAM		; RAM
<MISSING_IMAGE_DATA>

:TxBootRAM_x		= .x
:TxBootRAM_y		= .y

;*** RAMLink-Boot-Laufwerk.
:curBootDrvRL		s $05
:TxBootRL		b "AUTO"
			b "A:",0,0
			b "B:",0,0
			b "C:",0,0
			b "D:",0,0

;*** Treiber in RAM laden.
;Die Reihenfolge der Daten entspricht
;der Treiberliste in "-D3_DrvTypes".
:dataDrvToRAM		b %00000000 ;NULL

			b %10000000 ;C=1541
			b %10000000 ;C=1541/Shadow
			b %10000000 ;C=1571
			b %10000000 ;C=1581

			b %01000000 ;SD2IEC
			b %00000001 ;81DOS

			b %00000100 ;RAM41
			b %00000100 ;RAM71
			b %00000100 ;RAM81
			b %00000100 ;RAMNM

			b %00000010 ;RAMNM_SRAM
			b %00000010 ;RAMNM_CREU
			b %00000010 ;RAMNM_GRAM

			b %00001000 ;RL41
			b %00001000 ;RL71
			b %00001000 ;RL81
			b %00001000 ;RLNM

			b %00100000 ;FD41
			b %00100000 ;FD71
			b %00100000 ;FD81
			b %00100000 ;FDNM

			b %00000001 ;FDDOS

			b %00010000 ;HD41
			b %00010000 ;HD71
			b %00010000 ;HD81
			b %00010000 ;HDNM

			e dataDrvToRAM +DDRV_MAX

;*** Dialogboxen.
if LANG = LANG_DE
:DLG_ERR_TEXT1		b "Vorgang abgebrochen!",NULL
:DLG_ERR_TEXT2		b "Installation abgebrochen!",NULL
:DLG_ERR_TEXT3		b "Startvorgang abgebrochen!",NULL
:DLG_ERR_TEXT4		b "Bitte Konfiguration ändern!",NULL
endif
if LANG = LANG_EN
:DLG_ERR_TEXT1		b "Operation canceled!",NULL
:DLG_ERR_TEXT2		b "Unable to install drive!",NULL
:DLG_ERR_TEXT3		b "System start cancelled!",NULL
:DLG_ERR_TEXT4		b "Please change configuration!",NULL
endif

;*** Dialogbox: "Laufwerksmodus wählen:"
:Dlg_SlctDMode		b %10000001
			b DBUSRFILES
			w BASE_DDRV_DATA
			b CANCEL    ,$00,$00
			b DBUSRICON ,$00,$00
			w iconSlctMode
:dlgSlctDisk		b DBUSRICON ,$00,$00
			w iconSlctDisk
			b NULL

:iconSlctDisk		w Icon_NewDisk
			b $00,$00,Icon_NewDisk_x,Icon_NewDisk_y
			w :exit

::exit			lda	#DISK
			sta	sysDBData
			jmp	RstrFrmDialogue

:iconSlctMode		w Icon_Install
			b $00,$00,Icon_Install_x,Icon_Install_y
			w :exit

::exit			lda	#OPEN
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Dialogbox: "Laufwerk konnte nicht installiert werden!"
:Dlg_InstallError	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w DLG_ERR_TEXT1
			b DBTXTSTR   ,$0c,$2c
			w :1
			b DBTXTSTR   ,$0c,$36
			w :2
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Das Laufwerk konnte nicht im",NULL
::2			b "System installiert werden!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "The drive could not be installed",NULL
::2			b "in the system!",NULL
endif

;*** Dialogbox: "Laufwerk nicht gefunden!"
:Dlg_DevNotFound	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w DLG_ERR_TEXT1
			b DBTXTSTR   ,$0c,$2c
			w :1
			b DBTXTSTR   ,$0c,$36
			w :2
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Die erforderliche Hardware für das",NULL
::2			b "Laufwerk ist nicht vorhanden!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "The required hardware for that",NULL
::2			b "device is not available!",NULL
endif

;*** Dialogbox: "Nicht genügend freier Speicher!"
:Dlg_InstErrNoRAM	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w DLG_ERR_TEXT2
			b DBTXTSTR   ,$0c,$2c
			w :1
			b DBTXTSTR   ,$0c,$36
			w :2
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Es ist nicht ausreichend erweiteter",NULL
::2			b "Speicher für das Laufwerk verfügbar.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "There is not enough extended",NULL
::2			b "memory available for the drive!",NULL
endif

;*** Dialogbox: "Startlaufwerk wurde nicht gefunden".
:Dlg_ErrNoSysDrv	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR ,$0c,$20
			w DLG_ERR_TEXT3
			b DBTXTSTR ,$0c,$2c
			w :1
			b DBTXTSTR ,$0c,$36
			w :2
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Das Startlaufwerk konnte nicht im",NULL
::2			b "System installiert werden.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "The boot drive could not be installed",NULL
::2			b "in the system.",NULL
endif

;*** Dialogbox: "Startlaufwerk kann nicht geändert werden!"
:Dlg_SwapDskDrv		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w DLG_ERR_TEXT1
			b DBTXTSTR   ,$0c,$2c
			w :1
			b DBTXTSTR   ,$0c,$36
			w :2
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Das Systemlaufwerk mit den Treibern",NULL
::2			b "kann nicht gewechselt werden!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "The system drive with disk device",NULL
::2			b "files can not be changed!",NULL
endif

;*** Dialogbox: "Laufwerkstreiber xyz nicht gefunden!"
:Dlg_InstErrLdDrv	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w DLG_ERR_TEXT2
			b DBTXTSTR   ,$0c,$2c
			w :1
			b DBTXTSTR   ,$0c,$36
			w :2
			b DBVARSTR   ,$18,$46
			b r5L
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Der folgende Laufwerkstreiber konnte",NULL
::2			b "nicht geladen werden:"
			b BOLDON,NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "The following disk driver could",NULL
::2			b "not be loaded:"
			b BOLDON,NULL
endif

;*** Dialogbox: "Aktuelle Konfiguration ist ungültig".
:Dlg_IllegalCfg		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR,$0c,$20
			w DLG_ERR_TEXT4
			b DBTXTSTR,$0c,$2c
			w :1
			b DBTXTSTR,$0c,$36
			w :2
			b DBTXTSTR,$0c,$46
			w Dlg_NoDrvTxt1a
			b OK      ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Die Konfiguration der Laufwerke für",NULL
::2			b "GEOS ist ungültig.",NULL
:Dlg_NoDrvTxt1a		b PLAINTEXT
			b "(Laufwerk "
:Dlg_NoDrvTxt1b		b "X: nicht definiert)",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "The current drive configuration for",NULL
::2			b "GEOS is not valid.",NULL
:Dlg_NoDrvTxt1a		b PLAINTEXT
			b "(Drive "
:Dlg_NoDrvTxt1b		b "X: not installed)",NULL
endif

;*** Dialogbox: "Fehler beim kopieren der Treiber!"
:Dlg_ErrLdDk2RAM	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w DLG_ERR_TEXT1
			b DBTXTSTR   ,$0c,$2c
			w :1
			b DBTXTSTR   ,$0c,$36
			w :2
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Beim laden der Laufwerkstreiber in",NULL
::2			b "den Speicher ist ein Fehler aufgetreten.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "A disk error occured while loading",NULL
::2			b "the disk drivers into RAM!",NULL
endif

;*** Dialogbox: "Adresse durch anderes Laufwerk belegt!"
:Dlg_DvAdrInUse		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w DLG_ERR_TEXT1
			b DBTXTSTR   ,$0c,$2c
			w :1
			b DBTXTSTR   ,$0c,$36
			w :2
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "GEOS-Laufwerksadresse ist am",NULL
::2			b "seriellen Bus bereits belegt!",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "The GEOS drive address on the",NULL
::2			b "serial bus is already in use!",NULL
endif

;*** Dialogbox: "Emulationsmodus wählen:"
:Dlg_SlctDevMode	b %01100001
			b $30,$a7
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$0c,$0b
			w :1

			b DBTXTSTR ,$40,$25
			w :2
			b DBUSRICON,$01,$18
			w :i1

			b DBTXTSTR ,$40,$35
			w :3
			b DBUSRICON,$01,$28
			w :i2

			b DBTXTSTR ,$40,$45
			w :4
			b DBUSRICON,$01,$38
			w :i3

			b DBTXTSTR ,$40,$55
			w :5
			b DBUSRICON,$01,$48
			w :i4

			b CANCEL   ,$11,$60
			b NULL

::i1			w Icon_1541
			b $00,$00,Icon_1541_x,Icon_1541_y
			w SetMode41

::i2			w Icon_1571
			b $00,$00,Icon_1541_x,Icon_1541_y
			w SetMode71

::i3			w Icon_1581
			b $00,$00,Icon_1541_x,Icon_1541_y
			w SetMode81

::i4			w Icon_Native
			b $00,$00,Icon_1541_x,Icon_1541_y
			w SetModeNM

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "Laufwerks-Modus wählen:",NULL
::2			b "C=1541-Modus",NULL
::3			b "C=1571-Modus",NULL
::4			b "C=1581-Modus",NULL
::5			b "CMD NativeMode",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "Select drive mode:",NULL
::2			b "C=1541-mode",NULL
::3			b "C=1571-mode",NULL
::4			b "C=1581-mode",NULL
::5			b "CMD NativeMode",NULL
endif

;*** Register-Menü.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 6				;Anzahl Einträge.

			w RegTName1			;Register: "Laufwerke".
			w RegTMenu1

			w RegTName2			;Register: "System".
			w RegTMenu2

			w RegTName3			;Register: "Treiber".
			w RegTMenu3

			w RegTName4			;Register: "CMD-HD".
			w RegTMenu4

			w RegTName5			;Register: "Start".
			w RegTMenu5

			w RegTName6			;Register: "?".
			w RegTMenu6

:RegTName1		w RTabIcon1
			b RegCardIconX_1,$28,RTabIcon1_x,RTabIcon1_y

:RegTName2		w RTabIcon2
			b RegCardIconX_2,$28,RTabIcon2_x,RTabIcon2_y

:RegTName3		w RTabIcon5
			b RegCardIconX_3,$28,RTabIcon5_x,RTabIcon5_y

:RegTName4		w RTabIcon4
			b RegCardIconX_4,$28,RTabIcon4_x,RTabIcon4_y

:RegTName5		w RTabIcon3
			b RegCardIconX_5,$28,RTabIcon3_x,RTabIcon3_y

:RegTName6		w RTabIcon6
			b RegCardIconX_6,$28,RTabIcon6_x,RTabIcon6_y

;*** System-Icons.
:RIcon_Select		w Icon_MSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSelect_x,Icon_MSelect_y
			b USE_COLOR_INPUT

:RIcon_Button		w Icon_MButton
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MButton_x,Icon_MButton_y
			b USE_COLOR_INPUT

;*** Daten für Register "Laufwerke".
:RegTMenu1		b 18

			b BOX_FRAME
				w RegTText1_01
				w $0000
				b $40,$b7
				w $0040,$012f

::u01			b BOX_USEROPT_VIEW
				w RegTText1_02
				w PrntDrvA
				b $48,$57
				w $0060,$0117
			b BOX_FRAME
				w $0000
				w $0000
				b $47,$58
				w $0118,$0120
			b BOX_ICON
				w $0000
				w SlctDrvA
				b $48
				w $0118
				w RIcon_Select
				b (:u01 - RegTMenu1 -1)/11 +1
			b BOX_ICON
				w $0000
				w SlctPartA
				b $50
				w $0118
				w RIcon_Select
				b (:u01 - RegTMenu1 -1)/11 +1

::u02			b BOX_USEROPT_VIEW
				w RegTText1_03
				w PrntDrvB
				b $60,$6f
				w $0060,$0117
			b BOX_FRAME
				w $0000
				w $0000
				b $5f,$70
				w $0118,$0120
			b BOX_ICON
				w $0000
				w SlctDrvB
				b $60
				w $0118
				w RIcon_Select
				b (:u02 - RegTMenu1 -1)/11 +1
			b BOX_ICON
				w $0000
				w SlctPartB
				b $68
				w $0118
				w RIcon_Select
				b (:u02 - RegTMenu1 -1)/11 +1

::u03			b BOX_USEROPT_VIEW
				w RegTText1_04
				w PrntDrvC
				b $78,$87
				w $0060,$0117
			b BOX_FRAME
				w $0000
				w $0000
				b $77,$88
				w $0118,$0120
			b BOX_ICON
				w $0000
				w SlctDrvC
				b $78
				w $0118
				w RIcon_Select
				b (:u03 - RegTMenu1 -1)/11 +1
			b BOX_ICON
				w $0000
				w SlctPartC
				b $80
				w $0118
				w RIcon_Select
				b (:u03 - RegTMenu1 -1)/11 +1

::u04			b BOX_USEROPT_VIEW
				w RegTText1_05
				w PrntDrvD
				b $90,$9f
				w $0060,$0117
			b BOX_FRAME
				w $0000
				w $0000
				b $8f,$a0
				w $0118,$0120
			b BOX_ICON
				w $0000
				w SlctDrvD
				b $90
				w $0118
				w RIcon_Select
				b (:u04 - RegTMenu1 -1)/11 +1
			b BOX_ICON
				w $0000
				w SlctPartD
				b $98
				w $0118
				w RIcon_Select
				b (:u04 - RegTMenu1 -1)/11 +1

			b BOX_ICON
				w RegTText2_03
				w ReloadDrvList
				b $a8
				w $0050
				w RIcon_Button
				b NO_OPT_UPDATE

;*** Texte für Register "Laufwerke".
if LANG = LANG_DE
:RegTText1_01		b	 "KONFIGURATION",0
:RegTText1_02		b	$50,$00,$4d, "A:",0
:RegTText1_03		b	$50,$00,$65, "B:",0
:RegTText1_04		b	$50,$00,$7d, "C:",0
:RegTText1_05		b	$50,$00,$95, "D:",0
endif
if LANG = LANG_EN
:RegTText1_01		b "CONFIGURATION",0
:RegTText1_02		b	$50,$00,$4d, "A:",0
:RegTText1_03		b	$50,$00,$65, "B:",0
:RegTText1_04		b	$50,$00,$7d, "C:",0
:RegTText1_05		b	$50,$00,$95, "D:",0
endif

;*** Daten für Register "System".
:RegTMenu2		b 6

			b BOX_FRAME
				w RegTText2_01
				w $0000
				b $40,$b7
				w $0040,$012f

			b BOX_USEROPT_VIEW
				w RegTText2_02
				w $0000
				b $50,$50 +MAX_SERBUS_DRV*8 -1
				w $0050,$005f

			b BOX_USEROPT_VIEW
				w $0000
				w $0000
				b $50,$50 +MAX_SERBUS_DRV*8 -1
				w $0068,$0107

			b BOX_USEROPT_VIEW
				w $0000
				w $0000
				b $50,$50 +MAX_SERBUS_DRV*8 -1
				w $0110,$011f

			b BOX_USER
				w $0000
				w PrntDrvList
				b $50,$50 +MAX_SERBUS_DRV*8 -1
				w $0068,$0107

			b BOX_ICON
				w RegTText2_03
				w UpdateDrvList
				b $a8
				w $0050
				w RIcon_Button
				b NO_OPT_UPDATE

;*** Texte für Register "System".
if LANG = LANG_DE
:RegTText2_01		b	 "VERFÜGBARE LAUFWERKE",0
:RegTText2_02		b	$4d,$00,$4d, "GEOS"
			b GOTOX,$90,$00, "Laufwerkstypen"
			b GOTOX,$0f,$01, "Adr",0
:RegTText2_03		b	$60,$00,$ae, "Geräteliste aktualisieren",0
endif
if LANG = LANG_EN
:RegTText2_01		b	 "AVAILABLE DISKDRIVES",0
:RegTText2_02		b	$4d,$00,$4d, "GEOS"
			b GOTOX,$a4,$00, "Drivetype"
			b GOTOX,$0f,$01, "Adr",0
:RegTText2_03		b	$60,$00,$ae, "Reload device list",0
endif

;*** Daten für Register "Treiber".
:RegTMenu3		b 11

			b BOX_FRAME
				w RegTText3_01
				w $0000
				b $40,$b7
				w $0040,$012f

::u01			b BOX_OPTION
				w RegTText3_02
				w SwapDkRAMmode
				b $48
				w $0048
				w BootRAM_Flag
				b %01000000

			b BOX_ICON
				w RegTText3_03
				w ReloadDkDv2RAM
				b $58
				w $0048
				w RIcon_Button
				b (:u01 - RegTMenu3 -1)/11 +1

::g7			b BOX_OPTION
				w RegTText3_10
				w $0000
				b $78
				w $0048
				w BootDrvToRAM
				b %10000000
::g3			b BOX_OPTION
				w RegTText3_14
				w $0000
				b $88
				w $0048
				w BootDrvToRAM
				b %00001000
::g5			b BOX_OPTION
				w RegTText3_12
				w $0000
				b $98
				w $0048
				w BootDrvToRAM
				b %00100000
::g4			b BOX_OPTION
				w RegTText3_13
				w $0000
				b $a8
				w $0048
				w BootDrvToRAM
				b %00010000

::g6			b BOX_OPTION
				w RegTText3_11
				w $0000
				b $78
				w $00b8
				w BootDrvToRAM
				b %01000000
::g2			b BOX_OPTION
				w RegTText3_15
				w $0000
				b $88
				w $00b8
				w BootDrvToRAM
				b %00000100
::g1			b BOX_OPTION
				w RegTText3_16
				w $0000
				b $98
				w $00b8
				w BootDrvToRAM
				b %00000010
::g0			b BOX_OPTION
				w RegTText3_17
				w $0000
				b $a8
				w $00b8
				w BootDrvToRAM
				b %00000001

;*** Texte für Register "Treiber".
if LANG = LANG_DE
:RegTText3_01		b	 "EINSTELLUNGEN"
			b GOTOXY,$48,$00,$72, "Folgende Treiber "
			b	 "in Speicher laden:",0
:RegTText3_02		b	$58,$00,$4e, "Laufwerkstreiber beim Start in"
			b GOTOXY,$58,$00,$56, "den Zwischenspeicher kopieren",0
:RegTText3_03		b	$58,$00,$5e, "Aktuelle Auswahl in Speicher laden",0
endif
if LANG = LANG_EN
:RegTText3_01		b	 "SETTINGS"
			b GOTOXY,$48,$00,$72, "Load disk drivers into RAM:",0
:RegTText3_02		b	$58,$00,$4e, "Load disk drivers into RAM during"
			b GOTOXY,$58,$00,$56, "system startup",0
:RegTText3_03		b	$58,$00,$5e, "Load selected drivers into RAM now",0
endif

:RegTText3_10		b	$58,$00,$7e, "C=/SD-41/71/81",0
:RegTText3_14		b	$58,$00,$8e, "CMD-RL",0
:RegTText3_12		b	$58,$00,$9e, "CMD-FD",0
:RegTText3_13		b	$58,$00,$ae, "CMD-HD",0
:RegTText3_11		b	$c8,$00,$7e, "SD2IEC-NM",0
:RegTText3_15		b	$c8,$00,$8e, "RAM-41/71/81/NM",0
:RegTText3_16		b	$c8,$00,$9e, "CRAM/GRAM/SRAM",0
:RegTText3_17		b	$c8,$00,$ae, "DOS-81/FD",0

;*** Daten für Register "CMD-HD".
:RegTMenu4		b 2

			b BOX_FRAME
				w RegTText4_01
				w $0000
				b $40,$b7
				w $0040,$012f

			b BOX_OPTION
				w RegTText4_02
				w $0000
				b $48
				w $0048
				w BootUseFastPP
				b %10000000

;*** Texte für Register "CMD-HD".
if LANG = LANG_DE
:RegTText4_01		b	 "ÜBERTRAGUNGSMODUS",0
:RegTText4_02		b	$58,$00,$4e, "Parallelkabel für Übertragung mit"
			b GOTOXY,$58,$00,$56, "einer CMD-HD Festplatte verwenden."
			b GOTOXY,$48,$00,$9e, "Hinweis:"
			b GOTOXY,$48,$00,$a6, "Ist kein Parallelkabel installiert, dann"
			b GOTOXY,$48,$00,$ae, "wird das serielle Kabel verwendet.",0
endif

if LANG = LANG_EN
:RegTText4_01		b	 "TRANSFER-MODE",0
:RegTText4_02		b	$58,$00,$4e, "Use parallelport cable to transfer"
			b GOTOXY,$58,$00,$56, "data when using CMD-HD hard disk."
			b GOTOXY,$48,$00,$9e, "Note:"
			b GOTOXY,$48,$00,$a6, "If no parallel cable is connected,"
			b GOTOXY,$48,$00,$ae, "then the serial cable will be used.",0
endif

;*** Daten für Register "Start".
:RegTMenu5		b 5

			b BOX_FRAME
				w RegTText5_01
				w $0000
				b $40,$b7
				w $0040,$012f

			b BOX_OPTION
				w RegTText5_02
				w $0000
				b $48
				w $0048
				w BootDrvReplace
				b %11111111

::u01			b BOX_STRING_VIEW
				w RegTText5_03
				w GetBootRAMLink
				b $68
				w $0100
				w curBootDrvRL
				b 4
			b BOX_FRAME
				w $0000
				w $0000
				b $67,$70
				w $00ff,$0128
			b BOX_ICON
				w $0000
				w SetBootRAMLink
				b $68
				w $0120
				w RIcon_Select
				b (:u01 - RegTMenu5 -1)/11 +1

;*** Texte für Register "Start".
if LANG = LANG_DE
:RegTText5_01		b	 "BOOT-LAUFWERK",0
:RegTText5_02		b	$58,$00,$4e, "EIN:"
			b GOTOXY,$70,$00,$4e, "Adresse automatisch anpassen"
			b GOTOXY,$58,$00,$56, "AUS:"
			b GOTOXY,$70,$00,$56, "GEOS-Laufwerk übernehmen"
			b GOTOXY,$70,$00,$5e, "Adresse >= 12 = Laufwerk A:",0
:RegTText5_03		b	$48,$00,$6e, "RAMLink: Geräteadresse >=12:"
			b GOTOXY,$48,$00,$76, "Laufwerk automatisch anpassen"
			b GOTOXY,$48,$00,$7e, "oder Boot-Laufwerk vorgeben"
			b GOTOXY,$48,$00,$8e, "Hinweis:"
			b GOTOXY,$48,$00,$96, "GEOS unterstützt nur die Laufwerke"
			b GOTOXY,$48,$00,$9e, "#8-11/A:-D:. Startet das System von"
			b GOTOXY,$48,$00,$a6, "einem Laufwerk >=12, dann regeln"
			b GOTOXY,$48,$00,$ae, "diese Optionen das Startverhalten.",0
endif
if LANG = LANG_EN
:RegTText5_01		b	 "BOOT_DRIVE",0
:RegTText5_02		b	$58,$00,$4e, "ON:"
			b GOTOXY,$70,$00,$4e, "Adjust address automatically"
			b GOTOXY,$58,$00,$56, "OFF:"
			b GOTOXY,$70,$00,$56, "Replace GEOS drive"
			b GOTOXY,$70,$00,$5e, "Address >= 12 = Drive A:",0
:RegTText5_03		b	$48,$00,$6e, "RAMLink: Device address >=12:"
			b GOTOXY,$48,$00,$76, "Automatically adjust drive or"
			b GOTOXY,$48,$00,$7e, "specify boot drive address"
			b GOTOXY,$48,$00,$8e, "Note:"
			b GOTOXY,$48,$00,$96, "GEOS does only support disk drives with"
			b GOTOXY,$48,$00,$9e, "address #8-11/A:-D:. If the system is"
			b GOTOXY,$48,$00,$a6, "booting from a drive address >=12 these"
			b GOTOXY,$48,$00,$ae, "options will control the boot behaviour.",0
endif

;*** Daten für Register "?".
:RegTMenu6		b 1

			b BOX_FRAME
				w RegTText6_01
				w DrawInfoColor
				b $40,$b7
				w $0040,$012f

;*** Texte für Register "?".
if LANG = LANG_DE
:RegTText6_01		b	 "HINWEISE ZUM STARTVORGANG"
			b GOTOXY,$49,$00,$4e, "INIT"
			b GOTOXY,$68,$00,$4e, "Installation wird vorbereitet"
			b GOTOXY,$49,$00,$5e, "RAM"
			b GOTOXY,$68,$00,$5e, "Laufwerkstreiber in RAM kopieren"
			b GOTOXY,$4a,$00,$6e, " X:"
			b GOTOXY,$68,$00,$6e, "Laufwerk nicht installiert"
			b GOTOXY,$4a,$00,$7e, " X:"
			b GOTOXY,$68,$00,$7e, "Laufwerkstreiber nicht im RAM"
			b GOTOXY,$4a,$00,$8e, " X:"
			b GOTOXY,$68,$00,$8e, "Der Laufwerkstreiber wurde von"
			b GOTOXY,$68,$00,$96, "einem anderen Laufwerk geladen"
			b GOTOXY,$68,$00,$a6, "Konfigurationsproblem erkannt /"
			b GOTOXY,$68,$00,$ae, "Konfiguration erfolgreich"
			b NULL
endif
if LANG = LANG_EN
:RegTText6_01		b	 "NOTES DURING BOOT PROCESS"
			b GOTOXY,$49,$00,$4e, "INIT"
			b GOTOXY,$68,$00,$4e, "Installation is being prepared"
			b GOTOXY,$49,$00,$5e, "RAM"
			b GOTOXY,$68,$00,$5e, "Copying disk drivers to RAM"
			b GOTOXY,$4a,$00,$6e, " X:"
			b GOTOXY,$68,$00,$6e, "Drive was not installed"
			b GOTOXY,$4a,$00,$7e, " X:"
			b GOTOXY,$68,$00,$7e, "Disk driver not found in RAM"
			b GOTOXY,$4a,$00,$8e, " X:"
			b GOTOXY,$68,$00,$8e, "Disk driver was loaded from"
			b GOTOXY,$68,$00,$96, "another drive"
			b GOTOXY,$68,$00,$a6, "Configuration problem detected /"
			b GOTOXY,$68,$00,$ae, "Configuration successful"
			b NULL
endif

;*** System-Icons einbinden.
if .p
:EnableMSelect		= TRUE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= FALSE
:EnableMButton		= TRUE
endif
			t "-SYS_ICONS"

;*** Icons.
:Icon_Install
<MISSING_IMAGE_DATA>

:Icon_Install_x		= .x
:Icon_Install_y		= .y

:Icon_1541
<MISSING_IMAGE_DATA>

:Icon_1541_x		= .x
:Icon_1541_y		= .y

:Icon_1571
<MISSING_IMAGE_DATA>

:Icon_1571_x		= .x
:Icon_1571_y		= .y

:Icon_1581
<MISSING_IMAGE_DATA>

:Icon_1581_x		= .x
:Icon_1581_y		= .y

:Icon_Native
<MISSING_IMAGE_DATA>

:Icon_Native_x		= .x
:Icon_Native_y		= .y

:Icon_NewDisk
<MISSING_IMAGE_DATA>

:Icon_NewDisk_x		= .x
:Icon_NewDisk_y		= .y

;*** Register-Icons.
if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y

if LANG = LANG_DE
:RTabIcon3
<MISSING_IMAGE_DATA>

:RTabIcon3_x		= .x
:RTabIcon3_y		= .y
endif

if LANG = LANG_EN
:RTabIcon3
<MISSING_IMAGE_DATA>

:RTabIcon3_x		= .x
:RTabIcon3_y		= .y
endif

:RTabIcon4
<MISSING_IMAGE_DATA>

:RTabIcon4_x		= .x
:RTabIcon4_y		= .y

if LANG = LANG_DE
:RTabIcon5
<MISSING_IMAGE_DATA>

:RTabIcon5_x		= .x
:RTabIcon5_y		= .y
endif

if LANG = LANG_EN
:RTabIcon5
<MISSING_IMAGE_DATA>

:RTabIcon5_x		= .x
:RTabIcon5_y		= .y
endif

:RTabIcon6
<MISSING_IMAGE_DATA>

:RTabIcon6_x		= .x
:RTabIcon6_y		= .y

;*** X-Koordinate der Register-Icons.
:RegCardIconX_1		= $07
:RegCardIconX_2		= RegCardIconX_1 + RTabIcon1_x
:RegCardIconX_3		= RegCardIconX_2 + RTabIcon2_x
:RegCardIconX_4		= RegCardIconX_3 + RTabIcon5_x
:RegCardIconX_5		= RegCardIconX_4 + RTabIcon4_x
:RegCardIconX_6		= RegCardIconX_5 + RTabIcon3_x

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g RegMenuBase
;******************************************************************************
