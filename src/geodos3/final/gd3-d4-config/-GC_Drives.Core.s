; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Menü initialisieren.
:InitMain		jsr	StashRAM_DkDrv		;Aktuellen Treiber in REU sichern.

if GD_NG_MODE = FALSE
			jsr	InstallJumpTab		;Sprungtabelle für Installation der
							;Laufwerkstreiber aktivieren.
endif

;--- Ergänzung: 27.02.21/M.Kanet
;Die Treiberdatei muss hier nicht
;gesucht werden, da sowohl bei AutoBoot
;und Programmstart ":GetDrvInfo"
;aufgerufen wird. Hier wird dann auch
;die Treiberdatei gesucht.
;if GD_NG_MODE = FALSE
;			jsr	FindDiskDrvFile		;Laufwerkstreiber-Datei suchen.
;			txa				;Datei gefunden ?
;			bne	exitAppl		; => Nein, Ende...
;endif

;--- GeoDOS64 V3-Kernal aktiv ?
;GD.CONFIG kann auch von MP3 aus gestartet werden.
			lda	SysName +1		;GeoDOS64-Kernal aktiv ?
			cmp	#"D"			;"GDOS64-V3"
			bne	:1			; => Nein, weiter...
			lda	SysName +7
			cmp	#"V"
			beq	:2			; => Ja, GeoDOS64-V3.

::1			LoadB	RegTMenu_3a,BOX_OPTION_VIEW

::2			bit	firstBoot		;GEOS-BootUp ?
			bpl	DoAutoBoot		; => Automatisch installieren.

;*** Setup-Menü aufbauen.
:DoAppStart		lda	BootRAM_Flag		;Aktuellen Modus für "Alle Treiber
			and	#%10111111		;in RAM kopieren" übernehmen.
			ldx	MP3_64K_DISK
			beq	:1
			ora	#%01000000
::1			sta	BootRAM_Flag

			jsr	GetDrvInfo		;Treiber-Informationen einlesen.

if GD_NG_MODE = TRUE
			jsr	GetBootRAMLink		;RAMLink-Bootmodus einlesen.
endif

			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			LoadW	r0,RegisterTab		;Register-Menü installieren.
			jmp	DoRegister

:exitAppl		rts

;*** System-Boot.
:DoAutoBoot		lda	#$c0
			jsr	i_UserColor
			b	10,22,5,3

			LoadW	r11,82			;Init-Meldung ausgeben...
			LoadB	r1H,186
			LoadW	r0,TxBootInit
			jsr	PutString

			lda	sysRAMFlg		;Verhindern das SetDevice den
			and	#%10111111		;Treiber wechselt, bevor Treiber in
			sta	sysRAMFlg		;GEOS-Speicherbank installiert.

if GD_NG_MODE = TRUE
			jsr	FindDiskCore		;GD.DISK.CORE von Disk laden.
			txa				;Fehler ?
			bne	:booterr		; => Ja, Abbruch...
endif

			jsr	ChkBootConf		;Boot-Laufwerk anpassen.

			lda	BootRAM_Flag		;Treiber in RAM kopieren ?
			and	#%01000000		; => Nein, weiter...
			beq	:1

			jsr	AllocRAMDskDrv		;Speicherbereich reservieren.
			txa				;Speicher verfügbar ?
			bne	:err			; => Nein, weiter...

			LoadW	r11,100			;Load-Meldung ausgeben...
			LoadB	r1H,186
			LoadW	r0,TxBootLoad
			jsr	PutString

			jsr	LoadDkDv2RAM		;Laufwerkstreiber einlesen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...

::err			jsr	FreeRAMDskDrv		;Speicher wieder freigeben.

::1			jsr	GetDrvInfo		;Treiber-Informationen einlesen.
							;Erst nach ":ChkBootConf", da hier
							;evtl. das Startlaufwerk getauscht
							;werden muss! (RAMLink/HD >= 12).

			jsr	PurgeTurbo		;TurboDOS abschalten.
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

			lda	#$ff			;Aktive Partition einlesen.
			sta	r3H
			LoadW	r4,dirEntryBuf
			jsr	GetPDirEntry

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

::2			lda	#< Dlg_IllegalCfg	;"Konfiguration ungültig!"
			ldx	#> Dlg_IllegalCfg
			jsr	DoSysDlgBox		;Fehler ausgeben.

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

if GD_NG_MODE = TRUE
;--- Boot-Laufwerk übernehmen?
			jsr	:applyBootDrv		;Boot-Laufwerk übernehmen ?
			bcc	:update			; => Ja, weiter...
endif

;--- Startlaufwerk in Boot-Konfiguration suchen.
			jsr	:searchBootDrv		;Boot-Laufwerk in Config enthalten ?
			bcc	:swapbtcfg		; => Ja, Laufwerke tauschen...

			ldx	curDrive		;Aktuelles Laufwerk einlesen.

if GD_NG_MODE = TRUE
;--- RAMLink-Laufwerksadresse anpassen.
			bit	:bDrvRAMLink		;Start von RAMLink-Laufwerk ?
			bpl	:no_ramlink		; => Nein, weiter...

			jsr	:testRLadr		;RAMLink tauschen / Übernehmen.
			bcc	:update			;RAMLink als Laufwerk X: übernehmen.
endif

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
::updDisk		ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerkstyp einlesen.

			ldy	#< OpenDisk		;Standard: Diskette öffnen.
			ldx	#> OpenDisk
			and	#%10000000		;CMD-Laufwerk ?
			bpl	:open			; => Nein, weiter...

			lda	:bPart			;Aktive Partition setzen.
			sta	r3H

			ldy	#< OpenPartition	;CMD: Partition öffnen.
			ldx	#> OpenPartition

::open			tya
			jsr	CallRoutine		;Diskette/Partition öffnen.
			jsr	PurgeTurbo		;TurboDOS deaktivieren.

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

			jsr	PurgeTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O aktivieren.
			lda	r15H
			jsr	FindSBusDevice		;Ist neue Adresse belegt ?
			pha
			jsr	DoneWithIO		;I/O deaktivieren.
			pla
			bne	:free			; => Nein, weiter...

			jsr	InitForIO		;I/O aktivieren.
			jsr	GetFreeDrvAdr		;Freie Adresse #20-29 suchen.
			txa
			pha
			jsr	DoneWithIO		;I/O deaktivieren.
			pla
;--- Hinweis:
;Nur theoretisch kann man >20 Laufwerke
;an den ser.Bus anschließen. In der
;Praxis hat man schon bei mehr als vier
;Laufwerken Probleme.
;Daher wird hier auf die Abfrage nach
;einer freien Adresse verzichtet.
;			tax
;			beq	:err
;---
			lda	r15H			;Vorhandenes Laufwerk einlesen.
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

if GD_NG_MODE = TRUE
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
endif

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

if GD_NG_MODE = TRUE
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
endif

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
:Auto_InstallDrv	bit	Copy_BootInstalled
			bmi	:start			;Kein GEOS2-Update => Weiter...

;--- GEOS-Update, Konfiguration vorgeben.
::update		lda	#$08
::1			sta	:tmpdrive		;Adresse für aktuelles Laufwerk.

			jsr	TestDriveType		;Aktuelles Laufwerk ermitteln.
			cpx	#NO_ERROR		;Laufwerk gefunden?
			bne	:2			; => Nein, weiter...

			ldx	:tmpdrive
			and	#%00001111		;Partitionsformat isolieren und
			sta	BootPartType -8,x	;Ziel-Laufwerk speichern.
			tya
			ora	BootPartType -8,x
			sta	BootConfig -8,x

::2			lda	:tmpdrive
			clc
			adc	#$01
			cmp	#12			;Alle Laufwerke getestet?
			bcc	:1			; => Nein, weiter...

			ldx	SystemDevice		;Konfiguration Systemlaufwerk
			lda	RealDrvType -8,x	;in Boot-Konfiguration speichern.
			sta	BootConfig -8,x

;--- Installation starten.
::start			jsr	ChkRAMLinkDev		;RAMLink-Konfiguration
							;überprüfen und korrigieren.
;--- Ergänzung: 20.07.21/M.Kanet
;Wird GD3 über GD.UPDATE installiert,
;dann sind die Laufwerke in :driveType
;bereits definiert.
			ldx	#$08
::11			stx	DrvAdrGEOS		;Zeiger auf Laufwerk speichern.

			lda	:infoxl -8,x
			sta	r11L
			lda	:infoxh -8,x
			sta	r11H
			lda	#196
			sta	r1H
			txa
			clc
			adc	#"A" -8
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			ldx	DrvAdrGEOS
;			lda	driveType -8,x		;Laufwerk bereits installiert ?
;			bne	:15			; => Ja, überspringen.

			lda	BootConfig -8,x		;Ist Laufwerk konfiguriert ?
			beq	:13			; => Nein, nicht aktivieren.

			sta	InstallDrvType		;Laufwerkstyp speichern.

;--- Installation vorbereiten.
::prepare		and	#%11111000		;RAM-Laufwerk ?
			bmi	:init			; => Ja, weiter...
			cmp	#DrvRAMLink		;CMD-RAMLink ?
			beq	:init			; => Ja, weiter...

;--- Hinweis:
;":devInfo" ist hier nocht nicht mit
;Laufwerksdaten gefüllt!
;			ldx	DrvAdrGEOS
;			lda	devInfo -8,x		;Gültiges Laufwerk gefunden ?
;			cmp	#127			;VICE/VDRIVE ?
;			beq	:13			; => Nein, Fehler ausgeben. /VICE-FS

;--- Laufwerk einrichten.
::init			jsr	InstallDrive		;Laufwerk installieren.
			txa				;Installationsfehler?
			bne	:13

;--- Ergänzung: 12.09.21/M.Kanet:
;TurboDOS während der Installation
;immer deaktivieren.
			jsr	PurgeTurbo		;TurboDOS wieder abschalten.
			jmp	:14			; => Nächstes Laufwerk...

::13			ldx	DrvAdrGEOS
			jsr	DskDev_ClrData		;Laufwerk deaktivieren.

::14			ldx	DrvAdrGEOS		;Zeiger auf nächstes Laufwerk.
::15			inx
			cpx	#12			;Alle Laufwerke installiert ?
			bcc	:11			; => Nächstes Laufwerk...

;--- Laufwerke installiert.
::end			lda	sysFlgCopy		;Laufwerkstreiber A: bis D: in
			sta	sysRAMFlg		;GEOS-Speicherbank installiert.

			jsr	numDrivesInit		;Laufwerke zählen.

;--- Partitionen installieren.
::partition		ldx	#8			;Zeiger auf Laufwerk #8.
::21			stx	:tmpdrive		;Laufwerk speichern.
			lda	driveType -8,x
			beq	:22
			lda	RealDrvMode -8,x	;CMD-Laufwerk ?
			bpl	:22			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			ldx	:tmpdrive
			lda	BootPartRL -8,x
			beq	:22
			sta	r3H			;Partitions-Nr. einlesen und
			jsr	OpenPartition		;Partition öffnen.

::22			ldx	:tmpdrive		;Aktuelles Laufwerk einlesen.
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getestet ?
			bcc	:21			;Nein, weitertesten...

;--- Installation beendet.
::done			jsr	SetBootDevice		;Start-Laufwerk aktivieren.
			txa				;Diskettenfehler ?
			beq	:31			; => Nein, weiter...
			jmp	Err_NoSysDrive
::31			jmp	PurgeTurbo		;GEOS-Turbo abschalten.

;--- Variablen.
::tmpdrive		b $00
::infoxl		b < 82, < 92, < 101, < 110
::infoxh		b > 82, > 92, > 101, > 110

;*** Laufwerk installieren.
;Übergabe: DrvAdrGEOS     = Laufwerksadresse.
;          InstallDrvType = Laufwerkstyp.
:InstallDrive		lda	InstallDrvType
			jsr	LoadDkDvData		;Benötigten Treiber einlesen.
			txa				;Diskettenfehler ?
			beq	:start			; => Nein, weiter...

if GD_NG_MODE = FALSE
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:exit_load		; => Ja, weiter...

			lda	InstallDrvType
			jsr	DrvInstErrLdDrv		;Fehler: Treiber nicht gefunden.
endif

::exit_load		ldx	#DEV_NOT_FOUND		;Laufwerk nicht installiert.
			rts

;*** Laufwerk installieren.
;Übergabe: DrvAdrGEOS     = Laufwerksadresse.
;          InstallDrvType = Laufwerkstyp.
;Laufwerkstreiber muss bereits zur
;Installation bereitstehen!
::start			jsr	PurgeTurbo		;TurboDOS abschalten.
							;Der Treiber könnte von Disk
							;nachgeladen worden sein.

			bit	firstBoot		;GEOS-BootUp ?
			bpl	:prepare		; => Ja, Laufwerk nicht "löschen".
			bit	InstallDrvType		;RAM-Laufwerk installieren ?
			bpl	:skipram		; => Nein, weiter...

			ldx	DrvAdrGEOS		;":ramBase" für erneute
			lda	ramBase -8,x		;Laufwerksinstalation sichern.
			pha

::skipram		ldx	DrvAdrGEOS
			jsr	DskDev_Unload		;Ggf. RAM freigeben (RAM-Laufwerk).
			ldx	DrvAdrGEOS
			jsr	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

			bit	InstallDrvType		;RAM-Laufwerk installieren ?
			bpl	:prepare		; => Nein, weiter...

			ldx	DrvAdrGEOS		;":ramBase" wieder herstellen.
			pla
			sta	ramBase -8,x

;--- Ergänzung: 15.06.18/M.Kanet
;Der RAMNative-Treiber erkennt bei der Laufwerksinstallation ob
;bereits einmal ein RAMNative-Laufwerk installiert war. Dazu wird die
;BAM geprüft. Ist diese gültig wird daraus die Größe des Laufwerks ermittelt
;und im GD.CONFIG dann als Größe vorgeschlagen. Damit dies funktioniert
;sollte in :ramBase die frühere Startadresse übergeben werden.
;Wird die Konfiguration im Editor gespeichert wird jetzt auch die :ramBase
;Adresse der RAMLaufwerke gesichert und an dieser Stelle vor der Laufwerks-
;Installation als Vorschlag an die Installationsroutine übergeben.
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

if GD_NG_MODE = FALSE
			lda	BootUseFastPP		;PP-Modus übergeben.
			b $2c
::no_cmdhd		lda	#$00
			ora	InstallDrvType		;Übergabeparameter definieren.
			ldx	DrvAdrGEOS
endif
if GD_NG_MODE = TRUE
			lda	BootUseFastPP		;PP-Modus übergeben.
			sta	DDRV_VAR_HDPP
::no_cmdhd
endif

			jsr	DDrv_Install		;Treiber installieren.
			txa				;Installationsfehler ?
			beq	:cont 			; => Nein, weiter...

;--- Ergänzung: 07.08.21/M.Kanet
;Die NG-Laufwerkstreiber geben keine Fehlermeldung über GD.CONFIG aus.
;Daher muss hier jetzt der Fehlercode ausgewertet werden.
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:exit_inst		; => Ja, weiter...

			tay
			cpy	#ILLEGAL_DEVICE		;Fehler "Laufwerk ungültig" ?
			bne	:e0			; => Nein, weiter...

			lda	#<DrvInstErrAdr		; => Adresse belegt / VICE-FS.
			ldx	#>DrvInstErrAdr
			bne	:inst_err

::e0			cpy	#NO_FREE_RAM		;Fehler "Zu wenig Speicher" ?
			bne	:e1			; => Nein, weiter...

			lda	#<DrvInstErrNoRAM	; => Nicht genügend Speicher.
			ldx	#>DrvInstErrNoRAM
			bne	:inst_err

::e1			lda	#<DrvInstallError	; => Installationsfehler.
			ldx	#>DrvInstallError
::inst_err		jsr	CallRoutine		;Fehlermeldung ausgeben.
;---

			ldx	#DEV_NOT_FOUND
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
;			sta	devInfo -8,x		;Ser.Bus-Laufwerk abmelden.
			sta	devGEOS -8,x		;GEOS-Laufwerk freigeben.

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
			sta	devInfo -8,x		;Laufwerkstyp speichern.
			lda	#$ff
			sta	devGEOS -8,x		;GEOS-Laufwerk reservieren.

::3			bit	firstBoot		;GEOS-BootUp ?
			bpl	:initBoot		; => Ja, weiter...

;--- Installation abschließen, neuen Laufwerksmodus anzeigen.
if GD_NG_MODE = FALSE
::done			ldx	DrvAdrGEOS		;Aktuelles Laufwerk einlesen und
			jmp	SlctPart		;Partition/DiskImage wählen.
endif
if GD_NG_MODE = TRUE
::done			ldx	#NO_ERROR		;Ende.
			rts
endif

;--- CMD-Partitionen initialisieren.
::initBoot		ldx	curDrive
			lda	RealDrvMode -8,x	;Partitioniertes Laufwerk ?
			bpl	:ok			; => Nein, Ende...

;--- Hinweis:
;Hier muss OpenDisk ausgeführt werden.
;OpenDisk führt zu Beginn die Routine "FindRAMLink" aus um die Geräteadresse
;der RAMLink zu ermitteln.
;In älteren MP3-Versionen führte das dazu, das ":xSwapPartition" für die RL
;die Geräteadresse RL_DEV_ADDR=0 verwendet => Fehler bei ":xReadBlock":
;Hier wird über ":RL_DataCheck" geprüft ob die aktive Partition gültig ist und
;ggf. über die Routine ":xSwapartition" die Partition gewechselt.
;":RL_DataCheck" testet jetzt vorher die Geräteadresse und sucht dann ggf.
;das RAMLink-Laufwerk am ser.Bus.
			jsr	OpenDisk		;Treiber initialisieren...

;--- Hinweis:
;Für CMD-Laufwerke die Boot-Partition einstellen. Für RAMLink/Boot zwingend
;erforderlich, da durch OpenDisk evtl. eine andere Partition als "Aktiv"
;eingestellt wurde.
			ldx	DrvAdrGEOS
			lda	BootPartRL -8,x
			sta	r3H			;Partitions-Nr. einlesen und
			jsr	OpenPartition		;Partition öffnen.
			jsr	PurgeTurbo		;TurboDOS abschalten.

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

;--- Kopie der Laufwerkstreiber-Datei suchen.
;Wird das Laufwerk gewechselt, dann
;steht die Treiberdatei nicht mehr zur
;Verfügung. Ausnahme: Treiber im RAM.
if GD_NG_MODE = FALSE
			ldx	DrvAdrGEOS		;Kopie der Treiberdatei auf
			jsr	FindCopyDkDvFile	;anderem Laufwerk suchen.
			txa				;Gefunden ?
			bne	:exit			; => Nein, Abbruch...
endif

;--- Laufwerksauswahl.
::select		jsr	SlctNewDrvMode
			txa
			bne	:exit
			sty	InstallDrvType		;Laufwerksmodus speichern.
			tya				;Neues Laufwerk gewählt ?
			bne	:prepare		; => Ja, weiter...

;--- Kein Laufwerk einrichten.
::remove

;--- Ergänzung: 12.09.21/M.Kanet:
;TurboDOS während der Installation
;immer deaktivieren.
;Für ":UninstallDrive" muss nur das
;aktuelle Laufwerk deaktiviert werden.
			;lda	DrvAdrGEOS		;Auf allen Laufwerken das TurboDOS
			;jsr	purgeAllDrvTurbo	;abschalten.

			ldx	DrvAdrGEOS
			lda	driveType -8,x		;Laufwerk installiert ?
			beq	:no_turbo		; => Nein, weiter...
			lda	turboFlags -8,x		;TurboDOS aktiv ?
			bpl	:no_turbo		; => Nein, weiter...

			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	PurgeTurbo		;TurboDOS abschalten.

::no_turbo		jsr	UninstallDrive		;Laufwerk deinstallieren.

			rts

;--- Installation vorbereiten.
::prepare		and	#%11110000
			bmi	:init
			cmp	#DrvRAMLink
			beq	:init

			ldx	DrvAdrGEOS
			lda	devInfo -8,x		;Gültiges Laufwerk gefunden ?
			cmp	#127			;VICE/VDRIVE ?
			bne	:init			; => Nein, Fehler ausgeben. /VICE-FS

			jmp	Err_DvAdrInUse		;Fehler ausgeben.

;--- Laufwerk einrichten.
::init			jsr	ClrRAM_TaskMan		;Speicherbänke für TaskMan und
			jsr	ClrRAM_Spooler		;Spooler löschen, da Laufwerke die
							;höchste Priorität haben!
			jsr	InstallDrive		;Laufwerk installieren.

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

			jsr	OpenNewDisk		;Disk, Partition, DiskImage öffnen.

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
			PushB	r1H

			jsr	SetDrvNmVec		;Zeiger auf Laufwerkstyp berechnen.

			PopB	r1H			;Laufwerkstyp ausgeben.
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

			lda	#$ff
			sta	r3H
			LoadW	r4,dirEntryBuf
			jsr	GetPDirEntry		;Aktive Partition suchen.

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

;*** Laufwerke ausgeben.
:PrntDrvList		lda	r1L			;Aufbau Register-Menü ?
			beq	:draw			; => Ja, weiter...
			jmp	SlctNewDrv		; => Nein, Mausklick auswerten.

::draw			lda	tmpDrvCount		;Tabelle bereits definiert ?
			bne	:0			; => Ja, weiter...

			jsr	GetAllSerDrives		;Laufwerke am ser.Bus erkennen.

::0			jsr	:setDrvData		;Laufwerkstabelle erzeugen.

			lda	#$56			;Y-Koordinate festlegen.
			sta	r1H

			ldx	#0			;Laufwerkszähler löschen.
			stx	tmpDrvCount
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

::2			inc	tmpDrvCount		;Laufwerkszähler korrigieren.
			ldx	tmpDrvCount
			cpx	#11			;Gesamte Tabelle durchsucht ?
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
			cpx	#11
			bcc	:10

;			lda	#$00			;Laufwerkszähler löschen.
			sta	tmpDrvCount

			ldx	#$08
::loop			lda	devInfo -8,x		;Laufwerk verfügbar ?
			beq	:next			; => Nein, weiter...

			tay
			cmp	#127			;VICE/VDRIVE ?
			beq	:14			; => Ja, übernehmen...
			and	#%00001111		;C= oder SD2IEC-Laufwerk ?
			bne	:12			; => Ja, weiter...

;--- CMD-Laufwerk.
			lda	devGEOS -8,x		;Laufwerk reserviert ?
			bne	:11			; => Ja, weiter...

;--- Laufwerk nicht in Verwendung.
			tya
			ora	#%00000100		;CMD-Native-Laufwerk als
			tay				;Vorgabe setzen.
			bne	:14			; => Laufwerkstyp speichern.

;--- Laufwerk in Verwendung.
::11			lda	driveType -8,x
			and	#%00001111		;Aktuellen GEOS-Modus als
			ora	devInfo -8,x		;Vorgabe setzen.
			tay
			bne	:14			; => Laufwerkstyp speichern.

;--- C=Laufwerk oder SD2IEC.
::12			lda	devGEOS -8,x		;Laufwerk reserviert ?
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
			ldy	tmpDrvCount		;(Adresse und Typ) speichern.
			sta	SysDrvTab,y
			pha
			txa
			sta	SysDrvAdrTab,y
			pla
			tay

			inc	tmpDrvCount		;Laufwerkszähler korrigieren.
			lda	tmpDrvCount		;Laufwerkszähler einlesen.
			cmp	#11			;Ist Tabelle voll ?
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

			cpy	#127			;VICE/VDrive ?
			beq	:20			; => Ja, weiter...

			tya
			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Laufwerkstyp erkannt ?
			bne	:21			; => Ja, weiter...

			ldy	tmpDrvCount		;Laufwerk aus Tabelle löschen.
			lda	#$00
			sta	SysDrvTab,y
			sta	SysDrvAdrTab,y

			ldx	#<$006a			;Text "Unbekannt" ausgeben.
			lda	#<TxUNKNOWN
			ldy	#>TxUNKNOWN
			jmp	:prntStrg

::20			ldx	#<$006a			;Text "VICE/VDrive" ausgeben.
			lda	#<TxVICEFS
			ldy	#>TxVICEFS
			jmp	:prntStrg

::21			PushB	r1H

			jsr	SetDrvNmVec		;Zeiger auf Laufwerkstyp berechnen.

			PopB	r1H
			LoadW	r11,$006a
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

			ldx	#<$00d4			;Text "(SD2IEC)" ausgeben.
			lda	#<TxSD2IEC
			ldy	#>TxSD2IEC

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

			lda	devGEOS -8,x		;GEOS-Laufwerk reserviert ?
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

;--- Kopie der Laufwerkstreiber-Datei suchen.
;Wird das Laufwerk gewechselt, dann
;steht die Treiberdatei nicht mehr zur
;Verfügung. Ausnahme: Treiber im RAM.
if GD_NG_MODE = FALSE
			lda	newDrvUsed		;Als GEOS-Laufwerk reserviert ?
			beq	:select			; => Nein, weiter...

			ldx	newDrvAdr		;Kopie der Treiberdatei auf
			jsr	FindCopyDkDvFile	;anderem Laufwerk suchen.
			txa				;Gefunden ?
			bne	:exit			; => Nein, Abbruch...
endif

;--- Laufwerksauswahl.
::select		lda	InstallDrvType
			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Laufwerkstyp erkannt ?
			beq	:exit			; => Nein, Ende...

			jsr	SetDrvNmVec		;Zeiger auf Laufwerkstyp berechnen.
			MoveW	r0,r5

			jsr	SlctGEOSadr		;GEOS-Adresse wählen.
			cpx	#NO_ERROR		;"Abbruch" ?
			bne	:exit			; => Ja, Ende...
			sta	DrvAdrGEOS		;GEOS-Adresse speichern.

			lda	newDrvMode
			cmp	#DrvRAMLink
			beq	:slctemu

			ldx	DrvAdrGEOS
			lda	devInfo -8,x		;Aktuelles Laufwerk einlesen.
			cmp	#127			;VICE/VDRIVE ?
			bne	:slctemu		; => Nein, weiter...

			jmp	Err_DvAdrInUse		;Fehler ausgeben.

;--- Ggf. Emulationsformat wählen.
::slctemu		jsr	:setEmuMode		;Emulationsmodus wählen.
			txa				;"Abbruch" ?
			bne	:exit			; => Ja, Ende...

;--- Installation vorbereiten.
::prepare		jsr	prepareInstall		;Installation vorbereiten.
			txa				;Fehler aufgetreten ?
			beq	:init			; => Nein, weiter...

::err_install		jmp	Err_DrvInstall

;--- Laufwerk einrichten.
::init			jsr	ClrRAM_TaskMan		;Speicherbänke für TaskMan und
			jsr	ClrRAM_Spooler		;Spooler löschen, da Laufwerke die
							;höchste Priorität haben!
			jsr	InstallDrive		;Laufwerk installieren.

			jsr	SetRAM_TaskMan		;Speicher für TaskManager und
			jsr	SetRAM_Spooler		;Spooler reservieren.

			jsr	UpdTaskBank		;TaskMan-Bankadressen speichern.

			jsr	RegisterAllOpt		;Register aktualisieren.

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
			cmp	#127			;VICE/VDRIVE ?
			beq	:11			; => Ja, Ende...

			stx	newDrvSlct
			sta	InstallDrvType		;Laufwerkstyp speichern.
			lda	SysDrvAdrTab,x		;Aktuelle Geräteadresse für
			sta	newDrvAdr		;Laufwerk einlesen.
			tax
			lda	devGEOS -8,x		;Status für "Laufwerk unter GEOS
			sta	newDrvUsed		;bereits installiert" einlesen.
			lda	devInfo -8,x		;Laufwerksmodus (mit gesetztem
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

::51			LoadW	r0,Dlg_SlctDevMode
			jsr	DoDlgBox		;Emulationsmodus auswählen.

			ldx	sysDBData
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

;*** Laufwerk installieren.
;Übergabe: DrvAdrGEOS     = Laufwerksadresse.
;          InstallDrvType = Laufwerksmodus.
:prepareInstall

if GD_NG_MODE = FALSE
			ldx	DrvAdrGEOS		;Geräteadresse einlesen und
			jsr	FindCopyDkDvFile	;Treiberdatei suchen.
			txa				;Fehler ?
			bne	:errExit		; => Ja, Abbruch...
endif

;--- Vorhandenes Laufwerk entfernen.
::remove		lda	newDrvUsed		;Als GEOS-Laufwerk reserviert ?
			beq	:setGEOSadr		; => Nein, weiter...

			lda	DrvAdrGEOS
			cmp	newDrvAdr		;Neue Adresse = aktuelles Laufwerk ?
			beq	:setGEOSadr		; => Ja, weiter...

			pha				;Ziel-Laufwerk zwischenspeichern.
			lda	newDrvAdr		;GEOS-Laufwerk als Aktuell setzen.
			sta	DrvAdrGEOS		;TurboDOS in allen Laufwerken
							;abschalten.
;--- Ergänzung: 12.09.21/M.Kanet:
;TurboDOS während der Installation
;immer deaktivieren.
;Für ":prepareInstall" muss nur das
;aktuelle Laufwerk deaktiviert werden.
			tax
			lda	turboFlags -8,x
			bpl	:no_turbo

			;jsr	purgeAllDrvTurbo
			jsr	PurgeTurbo		;TurboDOS abschalten.

::no_turbo		jsr	UninstallDrive		;Laufwerk deinstallieren.

			pla
			sta	DrvAdrGEOS		;Ziel-Laufwerk zurücksetzen.

;--- Geräteadresse für GEOS wechseln.
::setGEOSadr		ldx	DrvAdrGEOS		;Ziel-Laufwerk als GEOS-Laufwerk
			lda	#$00			;in Tabelle abmelden.
			sta	devGEOS -8,x

			ldx	#NO_ERROR
			lda	newDrvMode
			cmp	#DrvRAMLink		;Neues Laufwerk vom Typ RAMLink ?
			beq	:errExit		; => Ja, weiter...

if GD_NG_MODE = FALSE
;			ldx	#NO_ERROR
			lda	newDrvAdr		;Geräteadresse einlesen.
			cmp	DrvAdrGEOS		;Aktuelle Adr. = GEOS-Adresse ?
			beq	:errExit		; => Ja, Ende...
			sta	r14L
			lda	DrvAdrGEOS		;Zieladresse speichern.
			sta	r15L
			jsr	SetDiskDrvAdr		;Laufwerksadresse tauschen.
;			txa				;Fehler?
;			bne	:errExit		; => Ja, Abbruch...
endif

if GD_NG_MODE = TRUE
			jsr	PurgeTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O aktivieren.

			ldx	DrvAdrGEOS
			lda	devInfo -8,x		;Laufwerk vorhanden ?
			beq	:nodrv			; => Nein, weiter...

			lda	DrvAdrGEOS
			cmp	newDrvAdr		;Neue Adresse = aktuelles Laufwerk ?
			beq	:ok			; => Ja, weiter...

			jsr	GetFreeDrvAdr		;Freie Adresse am ser.Bus suchen.
			cmp	#$00			;Freie Adresse gefunden ?
			beq	:err			; => Nein, Fehler (AKKU=0).
			ldx	DrvAdrGEOS
			jsr	SwapDiskDevAdr		;Aktuelles GEOS-Laufwerk tauschen.

::nodrv			ldy	DrvAdrGEOS		;Gewähltes Laufwerk auf neue
			ldx	newDrvAdr		;Adresse für GEOS-Laufwerk setzen.
			jsr	SwapDiskDevAdr

::ok			ldx	#NO_ERROR		;Kein Fehler...
			b $2c
::err			ldx	#DEV_NOT_FOUND		;Fehler...
			jsr	DoneWithIO		;I/O deaktivieren.
;			txa				;Fehler?
;			bne	:errExit		; => Ja, Abbruch...
endif

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

			lda	#$00			;Emulatonsmodus für SD2IEC setzen.
			b $2c
::1			and	#%11110000		;CMD-Typ isolieren und
			ora	r0L			;Emulationsmodus ergänzen.
			sta	InstallDrvType

			lda	#$80
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Vorhandenes Laufwerk deinstallieren.
:UninstallDrive		ldx	DrvAdrGEOS
			jsr	DskDev_Unload		;Ggf. RAM freigeben (RAM-Laufwerk).

			ldx	DrvAdrGEOS
			jsr	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

			ldx	DrvAdrGEOS
			lda	#$00
			sta	BootConfig -8,x		;Zusätzliche Laufwerksdaten
			sta	devGEOS -8,x		;initialisieren.

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
;******************************************************************************

;--- Ergänzung: 18.03.21/M.Kanet
;Alter Deinstallations-Code: Hier wird
;der aktive Laufwerkstreiber genutzt,
;um das Laufwerk zu deinstallieren.
;Der Code wurde durch eine neue Routine
;ersetzt, die universell ist:
;Es muss nur RAM wieder freigegeben und
;die Laufwerksdaten gelöscht werden.
;
if FALSE
;*** Altes Laufwerk deinstallieren.
:UninstallDrive		ldx	DrvAdrGEOS
			lda	RealDrvType -8,x	;Laufwerk installiert ?
			beq	:done			; => Nein, weiter...

			jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:done			; => Ja, weiter...

			ldx	DrvAdrGEOS
			lda	RealDrvType -8,x	;Vorhandenes Laufwerk abschalten.
			jsr	LoadDkDvData		;Aktiven Treiber einlesen.
			txa				;Diskettenfehler ?
			bne	:done			; => Ja, Abbruch...

;--- Ergänzung: 21.02.21/M.Kanet
;Auf allen Laufwerken das TurboDOS
;zur Sicherheit abschalten.
;Hier sollte das TurboDOS bereits
;deaktiviert sein.
			;lda	DrvAdrGEOS
			;jsr	purgeAllDrvTurbo

			lda	InstallDrvType
			and	#%11110000		;Laufwerkstyp bestimmen.
			cmp	#DrvHD			;Laufwerk CMD-HD ?
			bne	:1			; => Nein, weiter...
			lda	BootUseFastPP		;PP-Modus übergeben.
			b $2c
::1			lda	#$00
			ora	InstallDrvType		;Übergabeparameter definieren.
			ldx	DrvAdrGEOS
			jsr	DDrv_DeInstall		;Aktuelles Laufwerk De-Installieren.

;------------------------------------------------------------------------------
;--- Ergänzung: 21.02.21/M.Kanet
;Das Original-CONFIGURE fordert hier
;zum abschalten des alten Laufwerks
;auf. Aktuell nicht mehr notwendig.
;<*>			ldx	DrvAdrGEOS
;<*>			jsr	TurnOffDrive		;Laufwerk abschalten.
;------------------------------------------------------------------------------

			ldx	DrvAdrGEOS
			jsr	DskDev_ClrData		;Laufwerk löschen.

::done			rts

;*** Laufwerksdaten löschen.
;    Übergabe:		xReg = Zeiger auf zu löschendes Laufwerk.
:DskDev_ClrData		lda	#$00
			sta	driveType -8,x
			sta	driveData -8,x
			sta	ramBase -8,x
			sta	BootConfig -8,x
			sta	turboFlags -8,x
			sta	RealDrvType -8,x
			sta	drivePartData -8,x
			sta	doubleSideFlg -8,x
			sta	devGEOS -8,x

			ldy	#$00			;Anzahl Laufwerke löschen.
			sty	numDrives
::1			lda	RealDrvType,y
			beq	:3			;Nein, weiter...
			inc	numDrives		;Anzahl Laufwerke +1.
::2			iny
			cpy	#$04
			bcc	:1
::3			rts
endif

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

::ok			jsr	SetRAM_TaskMan		;Speicher für TaskManager und
			jsr	SetRAM_Spooler		;Spooler reservieren.

;--- TaskManager verschieben.
			lda	Flag_TaskBank		;Systembank für TaskManager
			cmp	BankTaskAdr		;geändert ?
			beq	:load			; => Nein, weiter...

			LoadW	r0,diskBlkBuf		;":diskBlkBuf"+":fileHeader"
			LoadW	r1,RT_ADDR_TASKMAN
			LoadW	r2,$0200		;Puffergröße $0200 Bytes.
			LoadB	r3H,16			;16x$0200 = $2000 = RT_SIZE_TASKMAN

::loop			lda	Flag_TaskBank		;Zeiger auf TaskManager.
			sta	r3L
			jsr	FetchRAM		;Programmcode einlesen.

			lda	BankTaskAdr		;Zeiger auf neue Speicherbank.
			sta	r3L
			jsr	StashRAM		;Programmcode speichern.

			inc	r1H			;Adresse innerhalb der
			inc	r1H			;Speicherbank korrigieren.

			dec	r3H			;Programmcode Taskmanager kopiert ?
			bne	:loop			; => Nein, weiter...

			lda	BankTaskAdr		;Neue Systembank für
			sta	Flag_TaskBank		;TaskManager setzen.

			jsr	UpdTaskBank		;TaskMan-Bankadressen speichern.

;--- Treiber in RAM einlesen.
::load			lda	BootRAM_Flag		;Alle Laufwerkstreiber in RAM
			and	#%01000000		;einlesen ?
			beq	:exit			; => Nein, weiter...

			jsr	LoadDkDv2RAM		;Laufwerkstreiber einlesen.
			txa				;Fehler?
			beq	:exit			; => Nein, weiter...

			lda	BootRAM_Flag		;"Treiber-in-RAM"-Flag löschen.
			and	#%10111111
			sta	BootRAM_Flag
			jmp	SwapDkRAMmode		;Option deaktivieren.

::exit			rts

;*** Alle Laufwerkstreiber/RAM abschalten.
:TurnOffDskDvRAM	lda	BootRAM_Flag		;Modus "Treiber in RAM"
			and	#%10111111		;zurücksetzen.
			sta	BootRAM_Flag

			jmp	FreeRAMDskDrv		;Speicher wieder freigeben.

;*** Boot-Laufwerk nicht mehr verfügbar.
:Err_NoSysDrive		lda	#<Dlg_ErrNoSysDrv
			ldx	#>Dlg_ErrNoSysDrv
			jsr	DoSysDlgBox
			ldx	#DEV_NOT_FOUND
			rts

;*** Keine Datei mit Laufwerkstreibern gefunden.
:Err_NoDkCopy		lda	#<Dlg_NoDskCopy
			ldx	#>Dlg_NoDskCopy
			jsr	DoSysDlgBox
			ldx	#DEV_NOT_FOUND
			rts

;*** Keine Datei mit Laufwerkstreibern gefunden.
:Err_NoDkFile		lda	#<Dlg_NoDskFile
			ldx	#>Dlg_NoDskFile
			jsr	DoSysDlgBox
			ldx	#DEV_NOT_FOUND
			rts

;*** Laufwerksadresse bereits belegt.
:Err_DvAdrInUse		lda	#<Dlg_DvAdrInUse
			ldx	#>Dlg_DvAdrInUse
			jsr	DoSysDlgBox
			ldx	#DEV_NOT_FOUND
			rts

;*** Laufwerk konnte nicht installiert werden!
:Err_DrvInstall		lda	#<Dlg_InstallError
			ldx	#>Dlg_InstallError
			jsr	DoSysDlgBox
			ldx	#DEV_NOT_FOUND
			rts

;*** Dialogbox: "Nicht genügend freier Speicher!".
:DrvInstErrNoRAM	lda	#<Dlg_InstErrNoRAM
			ldx	#>Dlg_InstErrNoRAM
			jmp	DoInstErrDlgBox

;*** Dialogbox: "Treiber nicht gefunden!".
:DrvInstErrLdDrv	jsr	GetDrvModVec		;Zeiger auf Typen-Tabelle berechnen.
			jsr	SetDrvNmVec		;Zeiger auf Laufwerkstyp berechnen.
			MoveW	r0,r15			;Zeiger für DoDlgBox nach ":r15".

			lda	#<Dlg_InstErrLdDrv
			ldx	#>Dlg_InstErrLdDrv
			bne	DoInstErrDlgBox

;*** Dialogbox: "Laufwerksadresse bereits belegt!".
:DrvInstErrAdr		lda	#<Dlg_DvAdrInUse
			ldx	#>Dlg_DvAdrInUse
			bne	DoInstErrDlgBox

;*** Dialogbox: "Laufwerk konnte nicht installiert werden!".
:DrvInstallError	lda	#<Dlg_InstallError
			ldx	#>Dlg_InstallError
:DoInstErrDlgBox	jsr	DoSysDlgBox

			ldx	DrvAdrGEOS
			jsr	DskDev_ClrData		;Laufwerksdaten löschen.

			jsr	SetRAM_TaskMan		;Speicher für TaskManager und
			jsr	SetRAM_Spooler		;Spooler reservieren.

			jsr	UpdTaskBank		;TaskMan-Bankadressen speichern.

			rts

;*** Dialogbox aufrufen.
:DoSysDlgBox		sta	r0L
			stx	r0H
			jmp	DoDlgBox

;*** TaskManager-RAM freigeben.
:ClrRAM_TaskMan		bit	BootTaskMan		;TaskManager installiert ?
			bmi	:3			; => Nein, weiter...

			LoadW	r0 ,BankTaskAdr
			LoadW	r1 ,RT_ADDR_TASKMAN +3
			LoadW	r2 ,2*9 +1
			lda	Flag_TaskBank
			sta	r3L
			jsr	FetchRAM		;TaskManager-Variablen einlesen.

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
			lda	#$ff			;TaskManager deaktivieren.
			sta	BootTaskMan
::4			rts

;*** TaskMan-Bankadressen speichern.
:UpdTaskBank		bit	BootTaskMan		;TaskManager installiert ?
			bmi	:1			; => Nein, weiter...

			LoadW	r0 ,BankTaskAdr
			LoadW	r1 ,RT_ADDR_TASKMAN +3
			LoadW	r2 ,2*9 +1
			lda	Flag_TaskBank
			sta	r3L
			jsr	StashRAM		;TaskManager-Variablen setzen.

::1			rts

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

;*** Mehrere Bänke in REU belegen.
;    Übergabe:		AKKU	= Zeiger auf erste Bank.
;			yReg	= Anzahl Bänke.
;    Rückgabe:		xReg	= Fehlermeldung.
:AllocBankT_Disk	ldx	#%10000000
			jmp	AllocateBankTab

;*** Einzelne Bank in REU belegen.
;    Übergabe:		AKKU	= Zeiger auf erste Bank.
;    Rückgabe:		xReg	= Fehlermeldung.
:AllocBank_Disk		ldx	#%10000000
			jmp	AllocateBank

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
:SetBootDevice		jsr	ExitTurbo		;Turbo-DOS abschalten.

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

;*** Laufwerkstreiber-Datei suchen.
:FindDiskDrvFile	bit	firstBoot		;GEOS-BootUp ?
			bmi	:appl			; => Nein, Laufwerkstreiber
							;    auf allen Laufwerken suchen.

;--- AutoBoot.
;Bei den neuen Laufwerkstreibern das
;Startlaufwerk nicht aktivieren oder
;wechseln, da sonst ggf. curDevice =
;Boot-Laufwerk geändert wird.
if GD_NG_MODE = FALSE
			lda	DDRV_FDRV		;Laufwerk bereits definiert ?
			beq	:1			; => Nein, Treiberdatei suchen.
			cmp	SystemDevice		;Startlaufwerk ?
			bne	:appl			; => Nein, weiter...
			jsr	SetBootDevice		;Startlaufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:search			; => Ja, anderes Laufwerk wählen.
			beq	:exit			; => Kein Fehler, Ende.

::1			jsr	SetBootDevice		;Startlaufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:search			; => Ja, anderes Laufwerk wählen.
endif

			jsr	LookForDkDvFile		;Treiberdatei suchen.
			txa				;Laufwerksfehler ?
			bne	:search			; => Ja, anderes Laufwerk wählen.

::set_drv		lda	curDrive		;Laufwerk mit Treiberdatei
			sta	DDRV_FDRV		;zwischenspeichern.
::exit			rts

;--- GEOS-Anwendung.
::appl			ldx	DDRV_FDRV		;Laufwerk definiert ?
			beq	:2			; => Nein, weiter...
			lda	driveType -8,x		;Laufwerk noch verfügbar ?
			beq	:2			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Wurde Laufwerk aktiviert ?
			beq	:3			; => Ja, weiter...

::2			jsr	SetBootDevice		;Startlaufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:search			; => Ja, anderes Laufwerk wählen.

::3			jsr	LookForDkDvFile		;Treiberdatei suchen.
			txa				;Laufwerksfehler ?
			beq	:set_drv		; => Nein, Laufwerk gefunden.

;--- Treiberdatei suchen.
::search		jmp	FindDkDvAllDrv		;Treiberdatei auf allen Laufwerken
							;suchen. Dabei auch ":DDRV_FDRV"
							;aktualisieren.

;*** Laufwerk mit Treiberdatei suchen.
:FindDkDvAllDrv		ldy	#8			;Zeiger auf erstes Laufwerk.
::1			lda	driveType -8,y		;Ist RAM-Laufwerk definiert ?
			bpl	:2			; => Nein, weiter...
			jsr	:search			;Treiber-Datei suchen.
			txa				;Datei gefunden ?
			beq	:5			; => Ja, Ende...
::2			iny				;Zeiger auf nächstes Laufwerk.
			cpy	#12			;Alle Laufwerke durchsucht ?
			bcc	:1			; => Nein, weiter...

			ldy	#8			;Zeiger auf erstes Laufwerk.
::3			lda	driveType -8,y		;Ist Disk-Laufwerk definiert ?
			beq	:4			; => Nein, weiter...
			bmi	:4			; => RAM-Laufwerk, weiter...
			jsr	:search			;Treiber-Datei suchen.
			txa				;Datei gefunden ?
			beq	:5			; => Ja, Ende...
::4			iny				;Zeiger auf nächstes Laufwerk.
			cpy	#12			;Alle Laufwerke durchsucht ?
			bcc	:3			; => Nein, weiter...
			ldx	#FILE_NOT_FOUND
			rts

::5			lda	curDrive		;Laufwerk mit Treiberdatei
			sta	DDRV_FDRV		;zwischenspeichern.
			ldx	#NO_ERROR
			rts

;--- Treiberdatei suchen.
;    Übergabe:		yReg = Laufwerk.
::search		tya
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler ?
			bne	:err			; => Ja, Abbruch...
			jsr	LookForDkDvFile		;Treiberdatei suchen.
::err			ldy	curDrive
			rts

;*** Laufwerkstyp ermitteln  (GEOS: #8 - #11).
;    Übergabe:		AKKU	= Geräteadresse.
;    Rückgabe:		AKKU	= 41=$01, 71=$02, 81=$03, FD=$1x, HD=$2x, RL=$3x
;			yReg	= 41=$01, 71=$02, 81=$03, FD=$10, HD=$20, RL=$30
:TestDriveType		sta	r14L
			tax
			lda	devInfo -8,x
			bne	:found
::nodrv			lda	#$00			;Kein Laufwerk installiert.
			tay
			ldx	#DEV_NOT_FOUND
			rts

;--- Laufwerk gefunden.
::found			lda	#$00			;Partitionsformat löschen.
			sta	BootPartType -8,x
			sta	BootPartRL_I -8,x

			lda	devInfo -8,x
			ldy	devGEOS -8,x		;Laufwerk unter GEOS installiert ?
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

			lda	devInfo -8,x
			cmp	#DrvRAMLink		;CMD-RAMLink-Laufwerk ?
			bne	:1			; => Nein, weiter...

			pha
			tya
			sta	BootPartRL_I -8,x	;Partitions-Nr. speichern.
			stx	DriveRAMLink		;RL-Adresse speichern.
			pla				;CMD-Laufwerkstyp wieder einlesen.

::1			tay
			ora	BootPartType -8,x
			ldx	#NO_ERROR		;Flag: "Kein Fehler!".
::err			rts				;Ende...

;*** Partitionstyp einlesen.
;    Aus dem Partitionstyp (1=41, 2=71, 3=81, 4=Native) und dem Laufwerkstyp
;    ($10=FD, $20=HD, $30=RAMLink) wird das Laufwerksformat erzeugt.
;    ($13,FD81, $31=RAMLink41 usw...)
;Rückgabe:		AKKU = Partitionstyp 41/71/81/NM.
;			YREG = Partitionsnummer.
;			XREG = Status, $00 = NO_ERROR.
:GetPartType		stx	:tmpdrive		;Laufwerk zwischenspeichern.

			lda	#$00			;Systempartition-Daten einlesen.
			sta	GP_Command +3
			ldx	:tmpdrive		;Laufwerksadr. einlesen.
			jsr	GetPartData		;Partitionsformat bestimmen.

			lda	PartitionData		;Partitionstyp einlesen.
			cmp	#$ff			;Systempartition vorhanden?
			bne	:3			; => Nein, keine Disk, weiter...
			sta	GP_Command +3		;Aktive Partition einlesen.
			ldx	:tmpdrive		;Laufwerksadr. einlesen.
			jsr	GetPartData

			ldx	PartitionData		;CMD-Partitionsformat einlesen.
			beq	:2			; $00 => Nicht erstellt.
			dex				;CMD-Format nach GEOS wandeln.
			bne	:1
			ldx	#$04
::1			txa				;Partitionsformat.
			ldy	PartitionData +2
			ldx	#NO_ERROR		;Flag für kein Fehler.
			rts

::2			ldx	:tmpdrive		;Laufwerksadr. einlesen.
			lda	BootPartType -8,x	;Startvorgang einlesen.
			bne	:4			; => Formatvorgabe übernehmen.
::3			lda	#$03			;Vorgabewert, wenn bei einer CMD FD
							;keine partitionierte Diskette im
							;Laufwerk liegt!
::4			ldy	BootPartRL -8,x		;Startpartition definiert ?
			bne	:5			; => Ja, weiter...
			ldy	#$01			;Vorgabewert für RL-Partition.
::5			ldx	#NO_ERROR		;Flag: "Kein Fehler".
			rts

::tmpdrive		b $00

;*** Partitionsdaten einlesen.
:GetPartData		stx	:tmpdrive		;Laufwerk zwischenspeichern.

			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00
			sta	STATUS			;Gerät aktivieren.

			jsr	UNLSN

			lda	:tmpdrive
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

			lda	:tmpdrive		;Laufwerksadr. einlesen und
			jsr	TALK			;Laufwerk auf "TALK" umschalten.
			lda	#$ff
			jsr	TKSA

			ldy	#$00
::2			jsr	ACPTR			;Partitionsinformationen einlesen.
			sta	PartitionData,y
			iny
			cpy	#30 +1
			bcc	:2

			jsr	UNTALK

			lda	:tmpdrive		;Laufwerksadr. einlesen und
			jsr	LISTEN			;Laufwerk abschalten.
			lda	#$ef
			jsr	SECOND
			jsr	UNLSN

::3			jmp	DoneWithIO		;I/O-Bereich ausblenden.

::tmpdrive		b $00

;*** Boot-RAMLink-Modus übernehmen.
if GD_NG_MODE = TRUE
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
endif

;*** Systemvariablen.
:DrvAdrGEOS		b $00
:InstallDrvType		b $00
:tmpDrvCount		b $00

:SysDrvTab		s 12
:SysDrvAdrTab		s 12

;*** Laufwerksinstallation.
:RL_Aktiv		b $00
:DriveRAMLink		b $00
:firstBootCopy		b $00
:Flag_ME1stBoot		b $00
:TxSD2IEC		b "(SD2IEC)",NULL		;Kennung für SD2IEC-Laufwerke.
:TxVICEFS		b "VICE/VDrive",NULL

;*** Variablen zum Partitionswechsel.
:GP_Command		b "G-P",$ff,$0d
:PartitionData		s 32

;*** Systemtexte.
if Sprache = Deutsch
:TxNODRIVE		b "Kein Laufwerk!",NULL
:TxUNKNOWN		b "Unbekannt!",NULL
:TxNODKNAME		b "(Keine Diskette)",NULL
endif
if Sprache = Englisch
:TxNODRIVE		b "No drive!",NULL
:TxUNKNOWN		b "Unknown drive!",NULL
:TxNODKNAME		b "(No disk found!)",NULL
endif
:TxBootInit		b PLAINTEXT,"Init...",NULL
:TxBootLoad		b PLAINTEXT,"RAM",NULL

;*** RAMLink-Boot-Laufwerk.
if GD_NG_MODE = TRUE
:curBootDrvRL		s $05
:TxBootRL		b "AUTO"
			b "A:",0,0
			b "B:",0,0
			b "C:",0,0
			b "D:",0,0
endif

;******************************************************************************
;*** Dialogboxen.
;******************************************************************************
if Sprache = Deutsch
:DLG_T_ERR		b PLAINTEXT,BOLDON
			b "Fehlermeldung",0
:DLG_T_INF		b PLAINTEXT,BOLDON
			b "Information",0
endif
if Sprache = Englisch
:DLG_T_ERR		b PLAINTEXT,BOLDON
			b "Systemerror",0
:DLG_T_INF		b PLAINTEXT,BOLDON
			b "Information",0
endif

;*** Dialogbox: Datei wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Dialogbox: "Laufwerk konnte nicht installiert werden!"
:Dlg_InstallError	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Das Laufwerk konnte nicht",NULL
::2			b "installiert werden!",NULL
endif
if Sprache = Englisch
::1			b "Unable to install drive!",NULL
::2			b NULL
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
			w :1
			b DBTXTSTR   ,$0c,$2c
			w :2
			b DBTXTSTR   ,$0c,$36
			w :3
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Installation abgebrochen!",NULL
::2			b "Es ist nicht ausreichend",NULL
::3			b "freier Speicher verfügbar.",NULL
endif
if Sprache = Englisch
::1			b "Unable to install drive!",NULL
::2			b "Not enough free extended",NULL
::3			b "memory available!",NULL
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
			w :1
			b DBTXTSTR ,$0c,$2a
			w :2
			b DBTXTSTR ,$0c,$36
			w :3
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

;*** Dialogbox: "Startlaufwerk kann nicht geändert werden!"
:Dlg_NoDskCopy		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$0c,$34
			w :3
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Das Systemlaufwerk mit den",NULL
::2			b "Laufwerkstreibern kann",NULL
::3			b "nicht gewechselt werden!",NULL
endif
if Sprache = Englisch
::1			b "The Systemdrive including",NULL
::2			b "the diskdriver can not",NULL
::3			b "be changed!",NULL
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
			w :1
			b DBTXTSTR   ,$0c,$2c
			w :2
			b DBTXTSTR   ,$0c,$36
			w :3
			b DBVARSTR   ,$18,$46
			b r15L
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Installation abgebrochen!",NULL
::2			b "Der folgende Laufwerkstreiber",NULL
::3			b "konnte nicht geladen werden:",NULL
endif
if Sprache = Englisch
::1			b "Unable to install drive!",NULL
::2			b "The following diskdriver",NULL
::3			b "could not be loaded:",NULL
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

;*** Dialogbox: "Fehler beim kopieren der Treiber!"
:Dlg_ErrLdDk2RAM	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2c
			w :2
			b DBTXTSTR   ,$0c,$36
			w :3
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Kopiervorgang abgebrochen!",NULL
::2			b "Die Systemdatei 'GD.DISK' ist",NULL
::3			b "fehlerhaft oder beschädigt!",NULL
endif
if Sprache = Englisch
::1			b "Installation failure!",NULL
::2			b "The systemfile 'GD.DISK' is",NULL
::3			b "corrupt or not valid!",NULL
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
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$0c,$34
			w :3
			b OK         ,$01,$50
			b NULL
if Sprache = Deutsch
::1			b "Die GEOS-Laufwerksadresse ist",NULL
::2			b "bereits durch ein anderes Gerät",NULL
::3			b "am seriellen Bus belegt!",NULL
endif
if Sprache = Englisch
::1			b "The GEOS drive address is",NULL
::2			b "already used by another",NULL
::3			b "device on the serial bus!",NULL
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

::i1			w Icon_02
			b $00,$00,Icon_02x,Icon_02y
			w SetMode41

::i2			w Icon_03
			b $00,$00,Icon_02x,Icon_02y
			w SetMode71

::i3			w Icon_04
			b $00,$00,Icon_02x,Icon_02y
			w SetMode81

::i4			w Icon_05
			b $00,$00,Icon_02x,Icon_02y
			w SetModeNM

if Sprache = Deutsch
::1			b PLAINTEXT,BOLDON
			b "Emulationsmodus wählen:",NULL
::2			b "1541-Emulation",NULL
::3			b "1571-Emulation",NULL
::4			b "1581-Emulation",NULL
::5			b "CMD NativeMode",NULL
endif
if Sprache = Englisch
::1			b PLAINTEXT,BOLDON
			b "Select emulation-mode:",NULL
::2			b "1541-emulation",NULL
::3			b "1571-emulation",NULL
::4			b "1581-emulation",NULL
::5			b "CMD NativeMode",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 4				;Anzahl Einträge.

			w RegTName_1			;Register: "Laufwerke".
			w RegTMenu_1

			w RegTName_2			;Register: "Laufwerke".
			w RegTMenu_2

			w RegTName_3			;Register: "Laufwerke".
			w RegTMenu_3

			w RegTName_4			;Register: "Laufwerke".
			w RegTMenu_4

:RegTName_1		w Icon_20
			b RegCardIconX_1,$28,Icon_20x,Icon_20y

:RegTName_2		w Icon_21
			b RegCardIconX_2,$28,Icon_21x,Icon_21y

:RegTName_3		w Icon_22
			b RegCardIconX_3,$28,Icon_22x,Icon_22y

:RegTName_4		w Icon_23
			b RegCardIconX_4,$28,Icon_23x,Icon_23y

;*** Daten für Register "Laufwerke".
:RegTMenu_1		b 17

			b BOX_FRAME			;----------------------------------------
				w RegTText_1_01
				w $0000
				b $40,$b7
				w $0040,$012f

::u01			b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_1_02
				w PrntDrvA
				b $48,$57
				w $0060,$0117
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $47,$58
				w $0118,$0120
			b BOX_ICON			;----------------------------------------
				w $0000
				w SlctDrvA
				b $48
				w $0118
				w RegTIcon1_1_01
				b (:u01 - RegTMenu_1 -1)/11 +1
			b BOX_ICON			;----------------------------------------
				w $0000
				w SlctPartA
				b $50
				w $0118
				w RegTIcon1_1_01
				b (:u01 - RegTMenu_1 -1)/11 +1

::u02			b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_1_03
				w PrntDrvB
				b $60,$6f
				w $0060,$0117
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $5f,$70
				w $0118,$0120
			b BOX_ICON			;----------------------------------------
				w $0000
				w SlctDrvB
				b $60
				w $0118
				w RegTIcon1_1_01
				b (:u02 - RegTMenu_1 -1)/11 +1
			b BOX_ICON			;----------------------------------------
				w $0000
				w SlctPartB
				b $68
				w $0118
				w RegTIcon1_1_01
				b (:u02 - RegTMenu_1 -1)/11 +1

::u03			b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_1_04
				w PrntDrvC
				b $78,$87
				w $0060,$0117
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $77,$88
				w $0118,$0120
			b BOX_ICON			;----------------------------------------
				w $0000
				w SlctDrvC
				b $78
				w $0118
				w RegTIcon1_1_01
				b (:u03 - RegTMenu_1 -1)/11 +1
			b BOX_ICON			;----------------------------------------
				w $0000
				w SlctPartC
				b $80
				w $0118
				w RegTIcon1_1_01
				b (:u03 - RegTMenu_1 -1)/11 +1

::u04			b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_1_05
				w PrntDrvD
				b $90,$9f
				w $0060,$0117
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $8f,$a0
				w $0118,$0120
			b BOX_ICON			;----------------------------------------
				w $0000
				w SlctDrvD
				b $90
				w $0118
				w RegTIcon1_1_01
				b (:u04 - RegTMenu_1 -1)/11 +1
			b BOX_ICON			;----------------------------------------
				w $0000
				w SlctPartD
				b $98
				w $0118
				w RegTIcon1_1_01
				b (:u04 - RegTMenu_1 -1)/11 +1

:RegTIcon1_1_01		w Icon_10
			b $00,$00,$01,$08
			b $ff

if Sprache = Deutsch
:RegTText_1_01		b	 "KONFIGURATION",0
:RegTText_1_02		b	$50,$00,$4d, "A:",0
:RegTText_1_03		b	$50,$00,$65, "B:",0
:RegTText_1_04		b	$50,$00,$7d, "C:",0
:RegTText_1_05		b	$50,$00,$95, "D:",0
endif
if Sprache = Englisch
:RegTText_1_01		b "CONFIGURATION",0
:RegTText_1_02		b	$50,$00,$4d, "A:",0
:RegTText_1_03		b	$50,$00,$65, "B:",0
:RegTText_1_04		b	$50,$00,$7d, "C:",0
:RegTText_1_05		b	$50,$00,$95, "D:",0
endif

;*** Daten für Register "System".
:RegTMenu_2		b 5

			b BOX_FRAME			;----------------------------------------
				w RegTText_2_01
				w $0000
				b $40,$b7
				w $0040,$012f

			b BOX_USEROPT_VIEW		;----------------------------------------
				w RegTText_2_02
				w $0000
				b $50,$a7
				w $0050,$005f

			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w $0000
				b $50,$a7
				w $0068,$0107

			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w $0000
				b $50,$a7
				w $0110,$011f

			b BOX_USER			;----------------------------------------
				w $0000
				w PrntDrvList
				b $50,$a7
				w $0068,$0107

if Sprache = Deutsch
:RegTText_2_01		b	 "VERFÜGBARE LAUFWERKE",0
:RegTText_2_02		b	$4d,$00,$4d, "GEOS"
			b GOTOX,$90,$00, "Laufwerkstypen"
			b GOTOX,$0f,$01, "Adr",0
endif
if Sprache = Englisch
:RegTText_2_01		b	 "AVAILABLE DISKDRIVES",0
:RegTText_2_02		b	$4d,$00,$4d, "GEOS"
			b GOTOX,$a4,$00, "Drivetype"
			b GOTOX,$0f,$01, "Adr",0
endif

;*** Daten für Register "Einstellungen".
if GD_NG_MODE = FALSE
:RegTMenu_3_cnt		= 2
:RegTMenu_3_F1b		= $b7
endif
if GD_NG_MODE = TRUE
:RegTMenu_3_cnt		= 7
:RegTMenu_3_F1b		= $5f
endif
:RegTMenu_3		b RegTMenu_3_cnt

			b BOX_FRAME			;----------------------------------------
				w RegTText_3_01
				w $0000
				b $40,RegTMenu_3_F1b
				w $0040,$012f

:RegTMenu_3a		b BOX_OPTION			;----------------------------------------
				w RegTText_3_02
				w SwapDkRAMmode
				b $48
				w $0048
				w BootRAM_Flag
				b %01000000

if GD_NG_MODE = TRUE
			b BOX_FRAME			;----------------------------------------
				w RegTText_3_03
				w $0000
				b $70,$b7
				w $0040,$012f

			b BOX_OPTION			;----------------------------------------
				w RegTText_3_04
				w $0000
				b $78
				w $0048
				w BootDrvReplace
				b %11111111

::u01			b BOX_STRING_VIEW		;----------------------------------------
				w RegTText_3_05
				w GetBootRAMLink
				b $98
				w $0100
				w curBootDrvRL
				b 4
			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b $97,$a0
				w $00ff,$0128
			b BOX_ICON			;----------------------------------------
				w $0000
				w SetBootRAMLink
				b $98
				w $0120
				w RegTIcon1_3_01
				b (:u01 - RegTMenu_3 -1)/11 +1

:RegTIcon1_3_01		w Icon_10
			b $00,$00,$01,$08
			b $ff
endif

if Sprache = Deutsch
:RegTText_3_01		b	 "EINSTELLUNGEN",0
:RegTText_3_02		b	$58,$00,$4e, "Alle Laufwerkstreiber beim Start"
			b GOTOXY,$58,$00,$56, "in Zwischenspeicher kopieren",0
endif
if GD_NG_MODE!Sprache = TRUE!Deutsch
:RegTText_3_03		b	 "BOOT-LAUFWERK",0
:RegTText_3_04		b	$58,$00,$7e, "EIN:"
			b GOTOXY,$70,$00,$7e, "Automatisch anpassen"
			b GOTOXY,$58,$00,$86, "AUS:"
			b GOTOXY,$70,$00,$86, "GEOS-Laufwerk übernehmen"
			b GOTOXY,$70,$00,$8e, "Adresse >= 12 = Laufwerk A:",0
:RegTText_3_05		b	$48,$00,$9e, "RAMLink: Geräteadresse >=12:"
			b GOTOXY,$48,$00,$a6, "Laufwerk automatisch anpassen"
			b GOTOXY,$48,$00,$ae, "oder Boot-Laufwerk vorgeben",0
endif
if Sprache = Englisch
:RegTText_3_01		b	 "SETTINGS",0
:RegTText_3_02		b	$58,$00,$4e, "Copy all diskdrivers into"
			b GOTOXY,$58,$00,$56, "RAM when booting GEOS",0
endif
if GD_NG_MODE!Sprache = TRUE!Englisch
:RegTText_3_03		b	 "BOOT_DRIVE",0
:RegTText_3_04		b	$58,$00,$7e, "ON:"
			b GOTOXY,$70,$00,$7e, "Adjust automatically"
			b GOTOXY,$58,$00,$86, "OFF:"
			b GOTOXY,$70,$00,$86, "Replace GEOS drive"
			b GOTOXY,$70,$00,$8e, "Address >= 12 = Drive A:",0
:RegTText_3_05		b	$48,$00,$9e, "RAMLink: Device address >12 :"
			b GOTOXY,$48,$00,$a6, "Automatically adjust drive or"
			b GOTOXY,$48,$00,$ae, "specify boot drive address",0
endif

;*** Daten für Register "CMD-HD".
:RegTMenu_4		b 2

			b BOX_FRAME			;----------------------------------------
				w RegTText_4_01
				w $0000
				b $40,$b7
				w $0040,$012f

			b BOX_OPTION			;----------------------------------------
				w RegTText_4_02
				w $0000
				b $48
				w $0048
				w BootUseFastPP
				b %10000000

if Sprache = Deutsch
:RegTText_4_01		b	 "ÜBERTRAGUNGSMODUS",0
:RegTText_4_02		b	$58,$00,$4e, "Parallelkabel für Übertragung mit"
			b GOTOXY,$58,$00,$56, "einer CMD-HD Festplatte verwenden."
endif
if GD_NG_MODE!Sprache = TRUE!Deutsch
			b GOTOXY,$48,$00,$9e, "Hinweis:"
			b GOTOXY,$48,$00,$a6, "Ist kein Parallelkabel installiert, dann"
			b GOTOXY,$48,$00,$ae, "wird das serielle Kabel verwendet."
endif
if GD_NG_MODE!Sprache = FALSE!Deutsch
			b GOTOXY,$48,$00,$86, "Hinweis:"
			b GOTOXY,$48,$00,$8e, "Zum erstellen einer Bootpartition auf"
			b GOTOXY,$48,$00,$96, "der CMD-HD diese Option deaktivieren"
			b GOTOXY,$48,$00,$9e, "und den Treiber neu installieren."
			b GOTOXY,$48,$00,$a6, "Die Bootpartition ist sonst nur mit"
			b GOTOXY,$48,$00,$ae, "dem Parallelkabel startfähig!"
endif
			b NULL

if Sprache = Englisch
:RegTText_4_01		b	 "TRANSFER-MODE",0
:RegTText_4_02		b	$58,$00,$4e, "Use parallelport cable to transfer"
			b GOTOXY,$58,$00,$56, "data when using CMD-HD hard disk."
endif
if GD_NG_MODE!Sprache = TRUE!Englisch
			b GOTOXY,$48,$00,$9e, "Note:"
			b GOTOXY,$48,$00,$a, "If no parallel cable is connected,"
			b GOTOXY,$48,$00,$ae, "then the serial cable will be used."
endif
if GD_NG_MODE!Sprache = FALSE!Englisch
			b GOTOXY,$48,$00,$86, "Note:"
			b GOTOXY,$48,$00,$8e, "To create a bootable partition on"
			b GOTOXY,$48,$00,$96, "your CMD-HD please deactivate this"
			b GOTOXY,$48,$00,$9e, "option and re-install the disk driver."
			b GOTOXY,$48,$00,$a6, "If not your partition will boot only"
			b GOTOXY,$48,$00,$ae, "with a connected parallelport cable!"
endif
			b NULL

;*** Icons.
:Icon_01
<MISSING_IMAGE_DATA>
:Icon_01x		= .x
:Icon_01y		= .y

:Icon_02
<MISSING_IMAGE_DATA>
:Icon_02x		= .x
:Icon_02y		= .y

:Icon_03
<MISSING_IMAGE_DATA>

:Icon_03x		= .x
:Icon_03y		= .y

:Icon_04
<MISSING_IMAGE_DATA>

:Icon_04x		= .x
:Icon_04y		= .y

:Icon_05
<MISSING_IMAGE_DATA>

:Icon_05x		= .x
:Icon_05y		= .y

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

:Icon_21
<MISSING_IMAGE_DATA>
:Icon_21x		= .x
:Icon_21y		= .y

if Sprache = Deutsch
:Icon_22
<MISSING_IMAGE_DATA>
:Icon_22x		= .x
:Icon_22y		= .y
endif

if Sprache = Englisch
:Icon_22
<MISSING_IMAGE_DATA>
:Icon_22x		= .x
:Icon_22y		= .y
endif

:Icon_23
<MISSING_IMAGE_DATA>
:Icon_23x		= .x
:Icon_23y		= .y

;*** X-Koordinate der Register-Icons.
:RegCardIconX_1		= $07
:RegCardIconX_2		= RegCardIconX_1 + Icon_20x
:RegCardIconX_3		= RegCardIconX_2 + Icon_21x
:RegCardIconX_4		= RegCardIconX_3 + Icon_22x
