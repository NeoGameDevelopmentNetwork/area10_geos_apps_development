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
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_DISK"
			t "SymbTab_SCPU"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Interne Version von DiskCore.
.DISKCORE_VER_HI	= "2"
.DISKCORE_VER_LO	= "5"

;--- Ergänzung: 09.04.21/M.Kanet
;Speicher DiskImage-Verzeichnisliste.
;$6D00-$7FFF = Bereich Registermenü.
;Auf 127 Dateinamen begrenzt, max. sind
;255 Dateien möglich.
:MaxFileN		= 127				;SizeNTab/17
:FileNTab		= LOAD_REGISTER
:SizeNTab		= MaxFileN * 17			;OS_BASE - FileNTab = $1300
:FileNTabBuf		= FileNTab + SizeNTab

;--- Variablenspeicher Laufwerkstreiber.
.DDRV_JMP_SIZE		= 3*3
.DDRV_VAR_START		= BASE_DDRV_DATA +DDRV_JMP_SIZE
;DrvAdrGEOS		= DDRV_VAR_START +0
;DrvMode		= DDRV_VAR_START +1
;DrvType		= DDRV_VAR_START +2
;--- Konfigurationsregister:
;%1xxxxxxx = CMDHD-PP-Modus aktiv.
;%x1xxxxxx = CMDHD-PP-Modus wählen.
;%xx1xxxxx = Keine Partition wählen.
.DDRV_VAR_CONF		= DDRV_VAR_START +3
.DDRV_VAR_SIZE		= 20 -DDRV_JMP_SIZE
;--- Titel für Treiber-Installation.
.DDRV_SYS_TITLE		= (BASE_DDRV_DATA +DDRV_JMP_SIZE +DDRV_VAR_SIZE)
;--- Start Laufwerkstreiber.
.DDRV_SYS_DEVDATA	= (BASE_DDRV_DATA +64)
endif

;*** GEOS-Header.
			n "obj.DiskCore"
			f DATA

			o BASE_DDRV_CORE

;******************************************************************************
;*** Systemkennung.
;******************************************************************************
;G3(D)isk(C)ore(x)(y)
			b "G3DC"
			b DISKCORE_VER_HI
			b DISKCORE_VER_LO
;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
._DDC_SLCTGEOSADR	jmp	SlctGEOSadr

._DDC_UPDATEKERNAL	jmp	CopyKernal2REU

._DDC_DRVBACKUP		jmp	xDrvBackup
._DDC_DRVRESTORE	jmp	xDrvRestore

._DDC_DEVCLRDATA	jmp	DskDev_ClrData
._DDC_DEVUNLOAD		jmp	DskDev_Unload
._DDC_DEVPREPARE	jmp	DskDev_Prepare

._DDC_RAMALLOC		jmp	DACC_ALLOC_RAM
._DDC_RAMFIND		jmp	DACC_FIND_RAM

._DDC_TESTDEVADR	jmp	FindSBusDevice
._DDC_DETECTDRV		jmp	_SER_GETCURDRV
._DDC_DETECTALL		jmp	GetAllSerDrives
._DDC_FINDDEVTYP	jmp	FindDriveType
._DDC_TURNONDEV		jmp	TurnOnNewDrive
._DDC_SWAPDEVADR	jmp	SwapDiskDevAdr
._DDC_GETFREEADR	jmp	GetFreeDrvAdr
._DDC_SENDCOMVLEN	jmp	serSendComVLen
._DDC_OPENMEDIA		jmp	OpenNewDisk
;******************************************************************************

;******************************************************************************
;*** Aktuelles Laufwerke am ser. Bus ermitteln.
;******************************************************************************
:DETECT_MODE = %10000000
			t "-D3_DriveDetect"		;Laufwerkserkennung.
;******************************************************************************

;******************************************************************************
;*** Shared code.
;******************************************************************************
:DrawDBoxTitel		t "-G3_DBoxTitel"		;Titel für Dialogboxen.
			t "-G3_Kernal2REU"		;Kernal in REU aktualisieren.
;******************************************************************************
			t "-DA_FindRAM"			;Freien Speicher suchen.
			t "-DA_GetBankByte"		;Status Speicherbank ermitteln.
			t "-DA_AllocBank"		;Speicherbank reservieren.
			t "-DA_AllocRAM"		;Speicher reservieren.
			t "-DA_FreeBank"		;Speicherbank freiegeben.
			t "-DA_FreeRAM"			;Speicher freiegeben.
;******************************************************************************

;*** Laufwerk de-installieren.
;Übergabe: XREG = GEOS-Laufwerk #8-#11
;Rückgabe: XReg = Fehlermeldung.
:DskDev_Unload		stx	tempDrive

			lda	driveType -8,x		;RAM-/Shadow-/PCDOS-Laufwerk ?
			cmp	#DrvPCDOS		;PCDOS-Laufwerk ?
			beq	:pcdos			; => Ja, weiter...
			and	#%11000000		;Bit$7=RAM, Bit%6=Shadow
			beq	:done			; => Nein, Ende...

			lda	RealDrvType -8,x
			and	#DrvCMD			;CMD-RAMLink ?
			bne	:done			; => Ja, Ende...

			lda	RealDrvMode -8,x
			and	#SET_MODE_SRAM		;CMD-SuperCPU/RAMCard ?
			bne	:sram			; => Ja, SuperRAM-Laufwerk...

			lda	ramBase -8,x		;GEOS-DACC reserviert ?
			bne	:ram			; => Ja, RAM-/Shadow-Laufwerk...

::done			ldx	#NO_ERROR		;Kein GEOS-DACC belegt, Ende.
			rts

;--- SuperCPU/RAMCard.
::sram			php				;IRQ sperren.
			sei

			ldy	CPU_DATA		;I/O-Bereich aktivieren.
			lda	#IO_IN
			sta	CPU_DATA

			sta	SCPU_HW_EN		;SuperCPU-Register aktivieren.

;			ldx	tempDrive
			lda	ramBase -8,x		;Erste Speicherbank.
			sta	SRAM_FIRST_BANK		;Freien Speicher zurücksetzen.

			sta	SCPU_HW_DIS		;SuperCPU-Register abschalten.

			sty	CPU_DATA		;I/O-Bereich ausblenden.

			plp				;IRQ-Status zurücksetzen.

			clc
			bcc	:done

;--- PCDOS.
::pcdos			ldy	#1			; => 1x64k
			bne	:disable

;--- RAM41/71/81/NM
::ram			lda	driveType -8,x		;Anzahl 64K Bänke ermitteln.
			and	#%00000111

::41			cmp	#Drv1541		;RAM1541 / Shadow-1541
			bne	:71
			ldy	#3			; => 3x64k
			bne	:disable

::71			cmp	#Drv1571		;RAM1571
			bne	:81
			ldy	#6			; => 6x64k
			bne	:disable

::81			cmp	#Drv1581		;RAM1581
			bne	:NM
			ldy	#13			; => 13x64k
			bne	:disable

;HINWEIS:
;Für NativeMode wird auf die aktuelle
;Disk zugegriffen um die Laufwerks-
;größe zu ermitteln.
;TurboDOS ist zuvor bereits deaktiviert
;und muss daher am Ende auch wieder
;deaktiviert sein!
::NM			lda	tempDrive		;RAMNative
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			txa
			bne	:NMerr			; => Ja, Abbruch...

			jsr	getBlockNMdata		;Zeiger auf Sektor $01/02 setzen
							;und BAM-Sektor/Größe einlesen.

			txa				;Diskettenfehler?
::NMerr			pha
			jsr	PurgeTurbo		;TurboDOS entfernen.
			pla
			tax				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...
							;Größe kann nicht ermittelt und
							;nicht mehr freigegeben werden.

			ldy	diskBlkBuf +8		;Größe NativeRAM-Laufwerk.

;--- RAM freiegeben, Anzahl im yReg!
::disable		ldx	tempDrive
			lda	driveType -8,x
			and	#%11111000
			cmp	#%01000000		;ShadowRAM-Laufwerk?
			bne	:no_shadow

			lda	driveType -8,x		;Shadow-Bit löschen.
			and	#%10111111
			sta	driveType -8,x

::no_shadow		lda	ramBase -8,x		;Ist GEOS-DACC reserviert ?
			beq	:ok			; => Nein, weiter...
			jsr	DACC_FREE_RAM		;RAM-Speicher wieder freigeben.
			b $2c
::ok			ldx	#NO_ERROR
::exit			rts

;*** NativeMode-Systeminfo einlesen.
:getBlockNMdata		ldx	#$01 			;Zeiger auf Spur $01/02 setzen
			stx	r1L			;und BAM-Sektor mit Laufwerks-
			inx				;größe einlesen.
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;BAM-Block einlesen.
;			txa				;Fehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;*** Laufwerk deinstallieren.
;Übergabe: XReg = Laufwerk #8-#11
;Rückgabe: XReg = NO_ERROR.
:DskDev_ClrData		lda	#$00
			sta	ramBase       -8,x
			sta	driveType     -8,x
			sta	driveData     -8,x
			sta	turboFlags    -8,x
			sta	RealDrvType   -8,x
			sta	RealDrvMode   -8,x
			sta	drivePartData -8,x
			sta	doubleSideFlg -8,x
			tax
			rts

;*** Laufwerkstreiber vorbereiten.
;Übergabe: Akku = DrvMode     / Laufwerksmodus $01=1541, $33=RL81...
;          XReg = DrvAdrGEOS  / GEOS-Laufwerk A-D/8-11.
;          YReg = RealDrvMode
;          DDRV_SYS_DEVDATA = Laufwerkstreiber.
;Rückgabe: -
:DskDev_Prepare		stx	curDevice
			stx	curDrive

			sta	RealDrvType -8,x
			sta	DDRV_SYS_DEVDATA + (diskDrvType - DISK_BASE)
			pha

			tya
			sta	RealDrvMode -8,x

			pla
			tay

;--- Hinweis:
;Nicht auf #DrvCMD testen, da auch ein
;ExtendedRAM-Drive installiert werden
;kann, was die Bits #5+#4 verwendet.
;			and	#DrvCMD			;Auf CMD-Laufwerk testen.
			and	#%11111000		;Modus-Bits isolieren.
			cmp	#DrvRAMLink		;CMD-RAMLink ?
			bne	:no_ramlink		; => Nein, weiter...
			tya
			ora	#%10000000		;RAM-Bit setzen.
			bne	:ram_drive		;Laufwerk = RAM-Laufwerk.

::no_ramlink		tya
			bmi	:ram_drive		;RAM-Laufwerk ? => Ja, weiter...

;--- Ergänzung: 28.08.21/M.Kanet
;Für 1541/Shadow muss hier das Shadow-
;Bit gelöscht werden, da der Speicher
;evtl. noch nicht reserviert ist.
::disk_drive		and	#%00000111		;Laufwerksformat isolieren.
			bne	:set_drive_type

::ram_drive		and	#%10000111		;RAM-Bit und Format isolieren.

::set_drive_type	sta	driveType -8,x		;GEOS-Laufwerkstyp setzen.
			sta	curType

			lda	#$00			;TurboFlags initialisieren.
			sta	turboFlags -8,x

;--- Treiber installieren.
:DskDev_CopyDrv		jsr	i_MoveData		;Laufwerkstreiber aktivieren.
			w	DDRV_SYS_DEVDATA
			w	DISK_BASE
			w	DISK_DRIVER_SIZE

			rts

;** Daten/Treiber zwsichenspeichern.
;Übergabe: YReg = Laufwerk A:-D:
:xDrvBackup		lda	driveType -8,y
			sta	driveType_buf		;Laufwerk vorhanden ?
			beq	:exit			; => Nein, Ende...

			lda	RealDrvType -8,y	;Laufwerksdaten zwischenspeichern.
			sta	RealDrvType_buf
			lda	ramBase -8,y
			sta	ramBase_buf

			tya				;Ziel-Laufwerk aktivieren um den
			jsr	SetDevice		;Laufwerkstreiber einzulesen.

			jsr	i_MoveData		;Laufwerkstreiber für Ziel-Laufwerk
			w	DISK_BASE		;zwischenspeichern.
			w	BACK_SCR_BASE
			w	DISK_DRIVER_SIZE

;--- Speicherbedarf ermitteln.
;HINWEIS:
;Aktuell gibt es keine Speicheradresse
;die darüber Auskunft gibt wieviele
;64K-Speicherbänke ein Treiber belegt.
;Vorrübergehend ersetzt durch eine
;reine Analyse-Logik des Treibertyps.
			lda	#NULL			;Speichergröße löschen.
			sta	ramSize_buf

			ldx	curDrive
			lda	driveType -8,x		;Laufwerkstyp einlesen.
			and	#%11000000		;RAM-/Shadow-Bits isolieren.
			bne	:isram			; => Laufwerk mit RAM, weiter...

;--- Kein RAM/Shadow-Laufwerk.
			lda	driveType -8,x
			and	#ST_DMODES		;Laufwerksmodus einlesen.
			cmp	#DrvPCDOS		;PCDOS-Laufwerk ?
			bne	:exit

;--- PCDOS.
::pcdos			ldy	#1			;PCDOS = 1x64K.
			bne	:setsize

;--- RAM-/Shadow-Laufwerke.
::isram			lda	RealDrvType -8,x	;RAM-Laufwerk ?
			bmi	:ramdisk		; => Ja, weiter...
::1541s			ldy	#3			;1541/Shadow = 3x64K.
			bne	:setsize		; => Speicher reservieren.

;--- RAM-Laufwerke.
::ramdisk		ldy	RealDrvMode -8,x
			and	#%00011100		;Ext.RAM-Laufwerk ?
			bne	:exit			; => Ja, Ende...

;--- RAM41/71/81.
::ram41			ldy	#3
			cmp	#DrvRAM1541		;RAM1541 ?
			beq	:setsize		; => Ja, Speicher reservieren.
::ram71			ldy	#6
			cmp	#DrvRAM1571		;RAM1571 ?
			beq	:setsize		; => Ja, Speicher reservieren.
::ram81			ldy	#13
			cmp	#DrvRAM1581		;RAM1581 ?
			beq	:setsize		; => Ja, Speicher reservieren.

;--- Größe RAMNative ermitteln.
::ramnm			jsr	getBlockNMdata		;Zeiger auf Sektor $01/02 setzen
							;und BAM-Sektor/Größe einlesen.

;			ldy	diskBlkBuf +8
::setsize		sty	ramSize_buf		;Größe RAM-Laufwerk speichern.

::exit			rts

;*** Daten/Treiber zurücksetzen.
;Übergabe: YReg = Laufwerk A:-D:
:xDrvRestore		lda	driveType_buf		;War Laufwerk zuvor installiert ?
			beq	:exit			; => Nein, weiter...

			sta	driveType -8,y		;Laufwerksdaten für Ziel-Laufwerk
			lda	RealDrvType_buf		;wieder herstellen.
			sta	RealDrvType -8,y
			lda	ramBase_buf
			sta	ramBase -8,y
			lda	#NULL
			sta	turboFlags -8,y

			tya
			pha

			ldy	ramSize_buf		;Größe RAM-Laufwerk einlesen und
			beq	:noram			;RAM-Speicher reservieren.
			tax
			lda	ramBase -8,x
			ldx	#%10000000

			jsr	_DDC_RAMALLOC		;DACC-RAM reservieren.

::noram			jsr	i_MoveData		;Laufwerkstreiber für Ziel-Laufwerk
			w	BACK_SCR_BASE		;wieder herstellen.
			w	DISK_BASE
			w	DISK_DRIVER_SIZE

			pla
			tay
;			ldy	curdrive
			jsr	InitCurDskDvJob		;Laufwerkstreiber für Ziel-Laufwerk
			jsr	StashRAM		;zurück in DACC kopieren.
			jsr	DoneWithDskDvJob

::exit			rts

;--- Zwischenspeicher Laufwerksdaten.
:driveType_buf		b $00
:RealDrvType_buf	b $00
:ramBase_buf		b $00
:ramSize_buf		b $00

;*** Alle Laufwerke am ser.Bus erkennen.
:GetAllSerDrives	jsr	_SER_GETALLDRV		;Alle Laufwerke erkennen.

			ldx	#8
::1			lda	_DDC_DEVTYPE -8,x	;Laufwerk vorhanden ?
			beq	:3			; => Nein, weiter...
			cmp	#DrvVICEFS		;VICE/FS-Laufwerk ?
			beq	:2			; => Ja, weiter...

			cpx	#12			;GEOS-Laufwerk A: bis D:?
			bcs	:2			; => Nein, weiter..

			lda	driveType -8,x		;GEOS-Laufwerk aktiv ?
			beq	:2			; => Nein, weiter...
			bmi	:2			; => RAM-Laufwerk, weiter...

;--- Ergänzung: 02.04.21/M.Kanet
;Beim ersten Startvorgang können noch
;keine Laufwerke eingerichtet sein.
;--- Ergänzung: 12.06.21/M.Kanet
;Mit Ausnahme des Boot-Laufwerks wenn
;das neue Treiber-Modell genutzt wird:
;Ist eine 1581 als A: und B: im System
;gespeichert, Laufwerk 8: aber eine
;1541, dann wird die erste freie 1581
;auf die Adresse A: getauscht.
;Wird das Boot-Laufwerk nicht als GEOS-
;Laufwerk reserviert, dann wird hier
;das Boot-Laufwerk getauscht und fehlt
;dann für die weitere Installation.
;			bit	firstBoot		;GEOS-BootUp ?
;			bpl	:2			; => Ja, weiter...

			lda	#$ff			;Laufwerk als belegt markieren.
			b $2c
::2			lda	#$00			;Nicht durch GEOS belegt.
			sta	_DDC_DEVUSED -8,x

			tay				;GEOS-Laufwerk ?
			beq	:3			; => Nein, weiter...

;--- Bei SD2IEC-Laufwerk aktiven GEOS-Modus übernehmen.
;Bei der Erkennung wird bei aktiver
;"M-R"-Emulation das Laufwerk z.B. als
;1581 erkannt, auch wenn aktuell als
;SD2IEC-Native konfiguriert.
			lda	_DDC_DEVTYPE -8,x
			and	#%01000000		;SD2IEC-Laufwerk ?
			beq	:3			; => Nein, weiter...

			lda	driveType -8,x		;GEOS-Laufwerksmodus einlesen.
			and	#%00001111
			ora	#%01000000		;SD2IEC-Flag wieder setzen.
			sta	_DDC_DEVTYPE -8,x	;Laufwerkstyp speichern.

::3			inx
			cpx	#29 +1			;Alle Laufwerke getestet?
			bcc	:1			; => Nein, weiter...
			rts

;*** Laufwerk am seriellen Bus suchen.
;    Übergabe: AKKU = Laufwerksadresse.
;    Rückgabe: AKKU = $00: OK.
:FindSBusDevice		pha				;Laufwerksadresse sichern.

			lda	#$00
			sta	STATUS			;Status-Flag löschen.
			jsr	UNTALK			;Alle Laufwerke => UNTALK.
			pla
			tax

			lda	STATUS			;Fehler aufgetreten?
			bne	:1			; => Ja, Abbruch...

			txa
			jsr	LISTEN			;Laufwerk aktiveren => LISTEN.

			lda	STATUS			;Fehler aufgetreten?
			bmi	:1			; => Ja, Abbruch...

			lda	#$ff			;Sekundäradresse auf Bus senden.
			jsr	SECOND

			lda	STATUS			;Fehlerstatus einlesen.
::1			pha
			jsr	UNLSN			;Alle Laufwerke => UNLISTEN.
			pla				;Fehlerstatus im AKKU.
			rts

;Reference: "Serial bus control codes"
;https://codebase64.org/doku.php?id=base:how_the_vic_64_serial_bus_works
;$20-$3E : LISTEN  , device number ($20 + device number #0-30)
;$3F     : UNLISTEN, all devices
;$40-$5E : TALK    , device number ($40 + device number #0-30)
;$5F     : UNTALK  , all devices
;$60-$6F : REOPEN  , channel ($60 + secondary address / channel #0-15)
;$E0-$EF : CLOSE   , channel ($E0 + secondary address / channel #0-15)
;$F0-$FF : OPEN    , channel ($F0 + secondary address / channel #0-15)

;*** Geräteadresse swappen.
;Übergabe: YReg = Neue Geräteadresse.
;          XReg = Alte Geräteadresse.
;Rückgabe:		-
;Geändert:		AKKU,xReg,yReg
:SwapDiskDevAdr		lda	_DDC_DEVTYPE -8,x	;Laufwerkstyp zwischenspeichern.
			pha
			lda	#$00			;GEOS-Laufwerksstatus in jedem
			sta	_DDC_DEVUSED -8,x	;Fall löschen. Wird nach der
			sta	_DDC_DEVUSED -8,y	;Installation neu gesetzt.
			sta	_DDC_DEVTYPE -8,x
			pla
			sta	_DDC_DEVTYPE -8,y	;Laufwerkstyp zurücksetzen.

if FALSE
			cmp	#Drv1541
			beq	:swapDskAdrMW
			cmp	#DrvShadow1541
			beq	:swapDskAdrMW
			cmp	#Drv1571
			bne	:swapDskAdrU0
endif

;--- Geräteadresse ändern.
;Nur für 1541/1571.
::swapDskAdrMW		tya
			ora	#%00100000
			sta	:com_DevAdr1		;Ziel-Adresse #1 berechnen.
			eor	#%01100000
			sta	:com_DevAdr2		;Ziel-Adresse #2 berechnen.

			tya				;Neue Laufwerksadresse
			pha				;zwischenspeichern.
			stx	curDevice

			ldx	#> :com_SwapAdr
			lda	#< :com_SwapAdr
			ldy	#8
			jsr	serSendComVLen		;Geräteadresse ändern.
			jsr	UNLSN			;Laufwerk abschalten.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

			rts

;Befehl zum wechseln der Geräteadresse.
::com_SwapAdr		b "M-W",$77,$00,$02
::com_DevAdr1		b $00
::com_DevAdr2		b $00

if FALSE
;--- Geräteadresse ändern.
;Nur für 1581/CMD/SD2IEC.
::swapDskAdrU0		sty	:com_SwapAdrU0 +3	;Neue Adresse merken.

			lda	curDevice		;Aktuelle Laufwerksadresse
			pha				;zwischenspeichern.
			stx	curDevice

			ldx	#> :com_SwapAdrU0
			lda	#< :com_SwapAdrU0
			ldy	#4
			jsr	SendComVLen		;Geräteadresse ändern.
			jsr	UNLSN			;Laufwerk abschalten.

			pla
			sta	xcurDevice		;Aktuelles Laufwerk zurücksetzen.

			rts

;Befehl zum wechseln der Geräteadresse.
::com_SwapAdrU0		b "U0",$3e,$08
endif

;*** Laufwerk auf neue Adresse setzen.
;    Übergabe:		r14L = Quell-Laufwerk.
;			r15L = Ziel -Laufwerk.
;    Rückgabe:    XReg = Fehler.
:SetDiskDrvAdr		ldx	#NO_ERROR		;Ende...
			lda	r15L			;Hat Laufwerk bereits die
			cmp	r14L			;korrekte Laufwerksadresse ?
			beq	:3			; => Ja, Ende...

			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	r15L			;Existiert ein Laufwerk mit neuer
			jsr	_DDC_TESTDEVADR		;Geräteadresse ?
			bne	:1			; => Nein, weiter...

			jsr	GetFreeDrvAdr		;Freie Geräteadresse suchen.
			txa				;XReg = STATUS/$0090 >0 = N.V.
			beq	:err			; => Keine Adresse #20-29 frei.

;			ldy	r14H 			;Neue Adresse.
			ldx	r15L			;Alte Adresse.
			jsr	_DDC_SWAPDEVADR		;Aktuelles Gerät auf eine neue
							;Adresse umschalten, damit die
							;Geräteadresse für neues Laufwerk
							;freigegeben wird.

			lda	r15L
			jsr	_DDC_TESTDEVADR		;Adresse erfolgreich gewechselt?
			beq	:err			; => Nein, Fehler...

::1			ldy	r15L			;Ziel-Laufwerk auf die neue GEOS-
			ldx	r14L			;Adresse umschalten.
			jsr	_DDC_SWAPDEVADR

			ldx	#NO_ERROR		;Ende...
			b $2c
::err			ldx	#ILLEGAL_DEVICE

::2			jsr	DoneWithIO		;I/O-Bereich ausblenden.

::3			rts

;*** Dialogbox: "Neues Laufwerk einschalten!".
;    Übergabe:		AKKU = Adresse des Ziel-Laufwerks #8 - #11.
:TurnOnNewDrive		ldx	#DEV_NOT_FOUND
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:err			; => Ja, Abbruch...

			sta	tempDrive		;Laufwerksadr. speichern und
			clc				;Text für Dialogbox initialisieren.
			adc	#"A" -8
			sta	dt4

;--- Laufwerksadressen im Bereich #8 - #11 "deaktivieren".
			jsr	FreeDrvAdrGEOS		;Laufwerke #8 bis #11 auf
			txa				;Addresse #20 bis #23 umstellen
			bne	:err

;--- Dialogbox ausgeben.
::wait			LoadW	r0,Dlg_SetNewDev
			jsr	DoDlgBox		;Dialogbox: Laufwerk einschalten.

			lda	sysDBData
			cmp	#OK			;Wurde "OK"-Icon gewählt ?
			bne	:cancel			; => Nein, Abbruch...

;--- Laufwerksadressen wieder zurücksetzen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#8			;Nach neuem Laufwerk mit Adresse
::1			sta	r15H			;von #8 bis #19 suchen.
			jsr	FindSBusDevice		;Laufwerk vorhanden ?
			bne	:1a			; => Nein, weiter...

			ldx	r15H
			lda	_DDC_DEVTYPE -8,x	;Laufwerk vorhanden ?
			beq	:2			; => Nein, weiter...
			cmp	#DrvRAMLink		;CMD-RAMlink ?
			beq	:1a			; => Ja, ignorieren...
			cmp	#DrvVICEFS		;VICE/FS-Laufwerk ?
			bne	:2			; => Nein, neues Laufwerk gefunden.

::1a			lda	r15H
			clc
			adc	#$01			;Zeiger auf nächstes Laufwerk.
			cmp	#20			;Alle Laufwerke getestet ?
			bcc	:1			; => Nein, weiter...

			ldx	#DEV_NOT_FOUND
			bne	:3			;Kein neues Laufwerk gefunden...

::2			ldx	r15H			;Geräteadresse auf Ziel-Laufwerk.
			cpx	tempDrive		;Neues Laufwerk mit Ziel-Adresse?
			beq	:2a			; => Ja, weiter...
			ldy	tempDrive		;Das neue Laufwerk auf die
			jsr	_DDC_SWAPDEVADR		;benötigte GEOS-Adresse umschalten!

::2a			ldy	tempDrive		;Evtl. vorhandenes Ziel-Laufwerk
			jsr	ClrDrvAdrGEOS		;nicht auf alte Adresse setzen.

			ldx	#NO_ERROR
::3			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			txa				;Neues Laufwerk gefunden ?
			bne	:wait			; => Nein, Dialogbox anzeigen.

;			lda	#NO_ERROR		; => Neues Laufwerk eingeschaltet.
			b $2c
::cancel		lda	#CANCEL_ERR		; => Abbruch...
			pha

			jsr	ResetDrvAdrGEOS		;Die restlichen Laufwerksadressen
				 			;wieder auf die alten Adressen
							;zurücksetzen.

			pla
			cpx	#NO_ERROR		;Fehler bei Laufwerks-Reset ?
			bne	:err			; => Ja, Abbruch...

			tax				;Auswertung Dialogbox zurückmelden.

::err			rts

;*** GEOS-Laufwerksadresse wählen.
;Übergabe: r5   = Zeiger auf Treibername.
;Rückgabe: XReg = $00, OK
;               > $00, Abbruch
;          AKKU = Laufwerk #8-#11
:SlctGEOSadr		ldx	#3			;Für Laufwerksauswahl alle
::1			lda	driveType ,x		;Typen als "Vorhanden" markieren.
			bne	:2			;Wichtig für Dialogbox-Code
			lda	#$ff			;"DRIVE" = $07.
			sta	driveType ,x
::2			dex
			bpl	:1

			LoadW	r0,Dlg_SlctGEOSadr
			jsr	DoDlgBox		;Laufwerksadresse wählen.

			ldx	#0			;Änderungen an ":driveType" wieder
::3			ldy	driveType ,x		;Rückgängig machen.
			iny
			bne	:4
			lda	#$00
			sta	driveType ,x
::4			inx
			cpx	#4
			bcc	:3

			ldx	sysDBData		;"Abbruch" gewählt ?
			bpl	:dlg_cancel		; => Ja, Ende...

			txa
			and	#%00001111		;Gewähltes Laufwerk ermitteln.

			ldx	#NO_ERROR
			b $2c
::dlg_cancel		ldx	#CANCEL_ERR
			rts

;*** Laufwerke #8 bis #11 auf freie Adressen legen.
:FreeDrvAdrGEOS		jsr	InitForIO		;I/O-Bereich einblenden.

			ldy	#8
::1			jsr	ClrDrvAdrGEOS		;Tabelle mit Geräteadressen löschen.
			iny
			cpy	#12
			bcc	:1

			ldx	#8
::2			stx	r15H
			lda	_DDC_DEVTYPE -8,x	;Laufwerk vorhanden ?
			beq	:3			; => Nein, weiter...
			cmp	#DrvRAMLink		;CMD-RAMLink ?
			beq	:3			; => Ja, weiter...
			cmp	#DrvVICEFS		;VICE/FS-Laufwerk ?
			beq	:3			; => Ja, weiter...

			jsr	GetFreeDrvAdr		;Freie Geräteadresse suchen.
			txa				;XReg = STATUS/$0090 >0 = N.V.
			beq	:err			; => Keine Adresse #20-29 frei.

			ldx	r15H			;Alte Adresse.
			txa
			sta	OldDrvAdrTab -8,x
;			ldy	r14H 			;Neue Adresse.
			tya
			sta	NewDrvAdrTab -8,x
			jsr	SwapDiskDevAdr		;Gerät auf neue Adresse umschalten.
			txa				;Fehler aufgetreten ?
			bne	:err			; => Ja, Abbruch...

::3			ldx	r15H
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getauscht ?
			bcc	:2			;Nein, weiter...

			ldx	#NO_ERROR
			b $2c
::err			ldx	#ILLEGAL_DEVICE
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Geräteadressen zurücksetzen.
:ResetDrvAdrGEOS	jsr	InitForIO		;I/O-Bereich einblenden.

			ldy	#8
::1			sty	r15H
			lda	NewDrvAdrTab -8,y	;Laufwerk gewechselt ?
			beq	:2			; => Nein, weite...
			tax
			lda	_DDC_DEVTYPE -8,x	;Laufwerk noch verfügbar ?
			beq	:2			; => Nein, weiter...

			ldx	OldDrvAdrTab -8,y	;Alte Laufwerksadresse einlesen.
			lda	_DDC_DEVTYPE -8,x	;Alte Adresse in Verwendung ?
			bne	:2			; => Ja, weiter...

			ldy	r15H
			ldx	NewDrvAdrTab -8,y	;Getauschte Adresse.
			lda	OldDrvAdrTab -8,y	;Alte/Originale Adresse.
			tay
			jsr	SwapDiskDevAdr		;Gerät auf neue Adresse umschalten.
			txa				;Fehler aufgetreten ?
			bne	:err			; => Ja, Abbruch...

::2			ldy	r15H
			iny
			cpy	#12
			bcc	:1

			ldx	#NO_ERROR
			b $2c
::err			ldx	#ILLEGAL_DEVICE
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** GEOS-Laufwerksadresse aus Tabelle löschen.
;Übergabe: YReg = GEOS-Laufwerksadresse.
:ClrDrvAdrGEOS		lda	#$00
			sta	OldDrvAdrTab -8,y
			sta	NewDrvAdrTab -8,y
			rts

;*** Freie Geräteadresse im Bereich #20 bis #29 suchen.
;Rückgabe: XReg = NULL / Keine Adresse mehr frei.
;          YReg = Freie Geräteadresse.
:GetFreeDrvAdr		lda	#20
::1			sta	r14H

			jsr	_DDC_TESTDEVADR		;Laufwerksadresse testen.

			ldy	r14H
			tax				;Ist Adresse frei ?
			bne	:2			; => Ja, weiter...

			iny
			tya
			cmp	#29 +1			;Max. #29! Sonst kommt es zu
			bcc	:1			;Problemen am ser. Bus!!!

			ldx	#NULL			;Hier: NULL = Fehler!
::2			rts

;*** Suche nach Laufwerkstyp starten.
;    Übergabe:		AKKU =	Laufwerkstyp.
;				Bei CMD-Geräten muß Bit %0-%3 = NULL sein!
;			yReg =	Laufwerksadresse #8 bis #11.
;				(Geräteadresse wird automatisch umgestellt).
:FindDriveType		sty	r15L
			sta	r15H

;--- Laufwerkstyp erkennen. ($01,$02,$03... $10,$20,$30....)
::51			lda	#$08			;Zeiger auf Laufwerk #8.
::52			sta	r14L
			tax
			lda	_DDC_DEVUSED -8,x	;Aktives GEOS-Laufwerk ?
			bne	:57			; => Ja, weiter...

			lda	_DDC_DEVTYPE -8,x	;Laufwerk vorhanden ?
			beq	:57			; => Nein, weiter...
			cmp	#DrvVICEFS		;VICE/FS-Laufwerk ?
			beq	:57			; => Ja, weiter...

			tay
			and	#%01000000		;SD2IEC ?
			beq	:53			; => Nein, weiter...

			lda	r15H			;Laufwerkstyp einlesen.
			and	#DrvCMD			;Wird CMD-Laufwerk gesucht ?
			bne	:57			; => Ja, weiter...
			beq	:54			; => Nein, Laufwerk verwenden.

::53			cpy	r15H			;Laufwerkstyp gefunden ?
			bne	:57			; => Nein, weiter...

;--- Geräteadresse festlegen.
::54			jsr	SetDiskDrvAdr		;Geräteadresse umstellen.

;			ldx	#NO_ERROR		;Fehler bereits im XReg...
			rts

;--- Nächstes Laufwerk.
::57			ldx	r14L			;Zeiger auf nächstes Laufwerk.
			inx
			txa
			cmp	#29 +1			;Alle Laufwerksadresse durchsucht ?
			bcc	:52			; => Nein, weiter...

			ldx	#DEV_NOT_FOUND
			rts

;*** Partition oder DiskImage öffnen.
:OpenNewDisk		ldx	curDrive
			lda	RealDrvMode -8,x	;Partitioniertes Laufwerk ?
			and	#SET_MODE_PARTITION!SET_MODE_SD2IEC
			beq	:exit
			bpl	:SD2IEC

;--- CMD-Laufwerk: Partition wechseln.
::CMD			jsr	NewDisk			;Diskette/Laufwerk initialisieren.

			LoadW	r4,diskBlkBuf
			jsr	GetPTypeData		;Partitionstypen einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			tay
;			ldx	#0
;			ldy	#0
			lda	curType			;Partitions-Typ ermitteln-
			and	#ST_DMODES
::1			cmp	diskBlkBuf,y		;Gültige Partitionen suchen.
			bne	:2
			inx				;Anzahl Partitionen +1.
::2			iny				;Liste durchsucht ?
			bne	:1			; => Nein, weiter...

			txa				;Partitionen gefundne ?
			beq	:exit			; => Nein, Ende... XReg=NO_ERROR!

			LoadW	r0,Dlg_SlctPart
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Partition auswählen.
			jsr	OpenDisk		;Diskette öffnen.
;			txa				;Fehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;--- SD2IEC: DiskImage öffnen.
::SD2IEC		jsr	bufStashData		;SwapFile erstellen und ggf.
							;Registermenü sichern.

			jsr	sdSelectDImg		;DiskImage wechseln.

;			jmp	bufFetchData		;Speicherbereich aus SwapFile
;							;wieder herstellen.

;*** Zwischenspeicher verwalten.
:bufFetchData		ldy	#jobFetch
			b $2c
:bufStashData		ldy	#jobStash
			LoadW	r0,FileNTab
			LoadW	r1,R3A_SWAPFILE
			LoadW	r2,SizeNTab
			lda	MP3_64K_DATA
			sta	r3L
			jmp	DoRAMOp			;Zwischenspeicher laden/speichern.

;*** Befehl an Laufwerk senden.
;Übergabe: XReg/YReg = Zeiger auf Befehl.
;          AKKU      = Länge Befehl.
:openFComChan		jsr	SETNAM			;Dateiname enthält Floppy-Befehl.

			lda	#10			;OPEN 10,dv,15,"..."
			ldx	curDevice
			ldy	#15
			jsr	SETLFS			;Daten für Befehlskanal setzen.

			jsr	OPENCHN			;Befehlskanal öffnen. Dadurch wird
							;der Floppy-Befehl ausgeführt.

			lda	#10
			jmp	CLOSE			;Befehlskanal schließen.

;*** DiskImage-Auswahl initialisieren.
:sdSelectDImg		jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler ?
			pha				;Status zwischenspeichern.

;------------------------------------------------------------------------------
; DISKIMAGE-AUSWAHL
;
;Vor dem Aufruf der DiskImage-Auswahl-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.
;------------------------------------------------------------------------------

			pla				;Fehlerstatus wieder einlesen.
			bne	sdNextDImg		; => Weiter, kein DiskImage aktiv.

;--- Aktuelles DiskImage verlassen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType -8,y		;Laufwerk ermitteln.
			and	#%00000111
			cmp	#DrvNative		;NativeMode ?
			bne	:exit_img		; => Nein, weiter...

			ldx	#< FComCDRoot		;DNP: Hauptverzeichnis öffnen.
			ldy	#> FComCDRoot		;Dabei muss auch auf der DOS-Ebene
			lda	#4			;das Hauptverzeichnis aktiviert
			jsr	openFComChan		;werden!

::exit_img		ldx	#< FComExitDImg		;DNP: DiskImage verlassen.
			ldy	#> FComExitDImg
			lda	#3
			jsr	openFComChan

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

;*** Neues DiskImage wählen
:sdNextDImg		jsr	sdCreateList		;Verzeichnis einlesen.
			txa				;Fehler ?
			bne	:cancel			; => Ja, Abbruch...

			jsr	i_MoveData		;Speicher für Verzeichniswechsel
			w	FileNTab + 0		;reservieren.
			w	FileNTab +34
			w	MaxFileN * 17

			ldy	#16 -1			;"<=" und ".." - Einträge erzeugen.
::1			lda	Text_DirNavEntry  + 0,y
			sta	FileNTab+ 0,y
			lda	Text_DirNavEntry  +16,y
			sta	FileNTab+17,y
			dey
			bpl	:1

			inc	maxDirCount		;Anzahl "ActionFiles" korrigieren.
			inc	maxDirCount		;(Verzeichnisse und "<=" und "..")

			lda	#$00			;Dateiauswahl zurücksetzen.
			sta	slctEntryName
			LoadW	r5,slctEntryName
			LoadW	r0,Dlg_SlctDImg
			jsr	DoDlgBox		;Dateiauswahlbox öffnen.

			lda	sysDBData
			cmp	#OPEN			;OPEN-Button.
			bne	:cancel			; => Nein, Abbruch.

			lda	slctEntryName		;Eintrag ausgewählt ?
			bne	sdOpenDImg		; => Ja, Auswahl auswerten.

;HINIWEIS:
;Bei Fehler oder Abbruch versuchen das
;erste gefundene DiskImage zu öffnen.
::cancel		lda	FCom1stDImgLen		;DiskImage im aktuellen Verzeichnis?
			beq	:exit			; => Nein, Ende...

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#< FCom1stDImg
			ldy	#> FCom1stDImg
			lda	FCom1stDImgLen
			jsr	openFComChan 		;Erstes DiskImage aktivieren.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			jmp	sdInitImage		;DiskImage initialisieren.

::exit			rts

;*** DiskImage öffnen.
:sdOpenDImg		jsr	sdFindDImg		;Nummer des Eintrages ermitteln.
			txa				;Gefunden?
			bne	:restart		; => Nein, Auswahl erneut starten.

			jsr	InitForIO		;I/O-Bereich einblenden.

;--- Hauptverzeichnis öffnen.
::test_cd_root		lda	slctEntryNum		;"<= (ROOT)" Eintrag gewählt?
			bne	:test_cd_up		; => Nein, weiter...

			ldx	#< FComCDRoot		;SD2IEC-Root aktivieren.
			ldy	#> FComCDRoot
			lda	#4
			bne	:send_cd

;--- Elternverzeichnis öffnen.
::test_cd_up		cmp	#$01			;".. (UP)" Eintrag gewählt?
			bne	:test_dir_img		; => Nein, weiter...

			ldx	#< FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldy	#> FComExitDImg
			lda	#3

::send_cd		jsr	openFComChan
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
::restart		jmp	sdNextDImg		;Verzeichnis neu einlesen.

;--- Verzeichnis oder DiskImage öffnen.
::test_dir_img		ldx	#0
			ldy	#3
::1			lda	slctEntryName,x		;Verzeichnisname in "CD"-Befehl
			beq	:2			;übertragen...
			sta	FComCDir,y
			iny
			inx
			cpx	#16
			bcc	:1

::2			tya
			ldx	#< FComCDir
			ldy	#> FComCDir
			jsr	openFComChan		;Verzeichnis/DiskImage öffnen.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			lda	slctEntryNum
			cmp	maxDirCount		;Verzeichnis oder DiskImage gewählt?
			bcc	:restart		; => Verzeichnis, Auswahl starten.

;*** Neues DiskImage initialisieren.
:sdInitImage		lda	curType
			and	#%00000111
			cmp	#DrvNative		;NativeMode-Laufwerk ?
			beq	:open_native		; => Ja, weiter...

::open_std		jmp	OpenDisk		;D64/D71/D81 öffnen.

::open_native		jmp	OpenRootDir		;DNP öffnen. OpenRootDir notwendig
							;um max.Track einulesen und das
							;Hauptverzeichnis zu aktivieren.

;*** Gewählten Eintrag in der Dateiliste suchen.
:sdFindDImg		lda	cntEntries +0		;Anzahl Einträge berechnen.
			clc
			adc	cntEntries +1
			clc
			adc	#$02
			sta	r14L
			LoadB	r14H,0			;Zähler auf ersten Eintrag.
			LoadW	r0,slctEntryName	;Zeiger auf gewählten Eintrag.
			LoadW	r15,FileNTab		;Zeiger auf Datentabelle.

::1			ldx	#r0L
			ldy	#r15L
			jsr	CmpString		;Eintrag vergleichen.
			beq	:2			;Gefunden? => Ja, Ende...

			AddVBW	17,r15			;Zeiger auf nächsten Eintrag.

			inc	r14H			;Zähler erhöhen.
			lda	r14H
			cmp	r14L			;Alle Einträge verglichen?
			bcc	:1			; => Nein, weiter...

			ldx	#FILE_NOT_FOUND		;Fehler: Nicht gefunden.
			rts

::2			lda	r14H			;Nummer des Eintrages in der Liste.
			sta	slctEntryNum

			ldx	#NO_ERROR		;OK, Eintrag gefunden.
			rts

;*** Kompatible DiskImages einlesen.
:sdCreateList		ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType -8,y		;Laufwerk ermitteln.
			and	#%00000111
			asl
			tay
			lda	DImgTypeList +0,y	;Kennung D64/D71/D81/DNP in
			sta	FComDImgList +5		;Verzeichnis-Befehl eintragen.
			lda	DImgTypeList +1,y
			sta	FComDImgList +6

			lda	#$00
			sta	maxDirCount		;Anzahl "ActionFiles" löschen.

			sta	FCom1stDImg +3		;Name für erstes DiskImage löschen.
			sta	FCom1stDImgLen

			sta	cntEntries +0		;Anzahl DiskImages löschen.
			sta	cntEntries +1		;Anzahl Verzeichnisse löschen.

;--- DiskImages einlesen.
::readListImg		ldx	#< FComDImgList		;Verzeichnis mit gültigen DiskImages
			ldy	#> FComDImgList		;einlesen.
			lda	#9
			jsr	sdLoadList
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	curDirCount		;Anzahl DiskImages in
			sta	r13H			;Zwischenspeicher übertragen.
			sta	cntEntries +0		;Mind. ein Eintrag gefunden?
			beq	:done_img		; => Nein, weiter...

			ldy	#3
;			ldx	#0			;Erstes gefundenes DiskImage
::1			lda	FileNTab,x		;merken. Wird dazu verwendet bei
			beq	:2			;Abbruch der Auswahlbox ein
			sta	FCom1stDImg,y		;gültiges DiskImage wieder zu
			iny				;aktivieren.
			inx
			cpx	#16
			bcc	:1
::2			sty	FCom1stDImgLen		;Länge CD:-Befehl speichern.

::done_img		jsr	i_MoveData		;Liste mit DiskImages speichern.
			w	FileNTab		;Mit "<=" und ".." sind max.
			w	FileNTabBuf		;253 weitere Einträge möglich.
			w	17 * MaxFileN

;--- Verzeichnisse einlesen.
::readListDir		ldx	#< FComSDirList		;Verzeichnisse einlesen.
			ldy	#> FComSDirList
			lda	#5
			jsr	sdLoadList
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			ldx	curDirCount
			stx	cntEntries +1		;Anzahl Verzeichnisse merken.
			stx	maxDirCount		;Vorgabe Anzahl "ActionFiles".

;--- Liste der DiskImages übernehmen.
::copyListImg		lda	r13H			;DiskImages gefunden?
			beq	:done			; => Nein, weiter...

			lda	#< FileNTabBuf		;Zeiger auf Zwischenspeicher
			sta	r14L			;mit DiskImages.
			lda	#> FileNTabBuf
			sta	r14H

;			ldx	cntEntries +1
::11			cpx	#MaxFileN		;Dateispeicher voll?
			bcs	:done			; => Ja, weiter...

			ldy	#16 -1			;DiskImage in Auswahlliste kopieren.
::12			lda	(r14L),y
			sta	(r15L),y
			dey
			bpl	:12

			AddVBW	17,r14			;Zeiger auf nächsten Eintrag.
			AddVBW	17,r15

			inx

			dec	r13H			;Alle DiskImages übernommen?
			bne	:11			; => Nein, weiter...

::done			ldx	#NO_ERROR		;Kein Fehler.
::exit			rts

;*** Aktuelles Verzeichnis einlesen.
;Das Verzeichnis wird über den "$"-Befehl über den seriellen
;Bus eingelesen und in den Dateinamenspeicher übertragen.
:sdLoadList		stx	r0L			;Zeiger auf Directory-Befehl.
			sty	r0H
			sta	r2L			;Anzahl Zeichen Directory-Befehl.

			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00			;Fehlerstatus löschen.
			sta	STATUS

			ldx	r0L
			ldy	r0H
			lda	r2L
			jsr	SETNAM			;Dateiname = Directory-Befehl.

			lda	#2			;OPEN 2,dv,0,"$..."
			ldx	curDevice
			ldy	#0
			jsr	SETLFS			;Daten für Datenkanal setzen.

			jsr	OPENCHN			;Datenkanal öffnen.

			bit	STATUS			;Status-Byte prüfen.
			bmi	:err_dev		; => Fehler, Abbruch...

			ldx	#2
			jsr	CHKIN			;Eingabekanal setzen.

			jsr	GETIN			;Test-Byte einlesen.

			lda	STATUS			;Status erneut testen.
			bne	:err_data		; => Fehler, Abbruch...

			ldy	#31			;Verzeichnis-Header überlesen.
::skiphdr		jsr	GETIN			;Byte einlesen.
			dey
			bne	:skiphdr

			jsr	i_FillRam		;Speicher für Dateinamen löschen.
			w	MaxFileN * 17
			w	FileNTab
			b	$00

			lda	#$00
			sta	curDirCount		;Anzahl Einträge löschen.

			lda	#< FileNTab		;Zeiger auf Speicher für Daten.
			sta	r15L
			lda	#> FileNTab
			sta	r15H

;*** Partitionen aus Verzeichnis einlesen.
::loop			jsr	GETIN			;Auf Verzeichnis-Ende
			cmp	#$00			;testen.
			beq	:end
			jsr	GETIN			;(2 Byte Link-Verbindung überlesen).

			jsr	GETIN			;Low-Byte der Zeilen-Nr. überlesen.
			jsr	GETIN			;High-Byte Zeilen-Nr. überlesen.

::1			jsr	GETIN			;Weiterlesen bis zum
			cmp	#$00			;Dateinamen.
			beq	:4
			cmp	#$22			; " - Zeichen erreicht ?
			bne	:1			; => Nein, weiter...

			ldy	#$00			;Zeichenzähler löschen.
::2			jsr	GETIN			;Byte aus Dateinamen einlesen.
			cmp	#$22			;Ende erreicht ?
			beq	:3			; => Ja, Ende...
			sta	(r15L),y		;Byte in Tabelle übertragen.
			iny
			bne	:2

::3			AddVBW	17,r15			;Zeiger auf nächsten Eintrag.
			inc	curDirCount		;Dateinamen, Zähler +1.
			lda	curDirCount
			cmp	#MaxFileN		;Speicher voll ?
			beq	:end			; => Ja, Ende...

::4			jsr	GETIN			;Rest der Zeile überlesen.
			cmp	#$00			;Ende erreicht ?
			bne	:4			; => Nein, weiter...

			jmp	:loop			;Nächsten Dateinamen einlesen.

;--- Verzeichnis-Ende oder Fehler.
::err_dev		lda	#DEV_NOT_FOUND		;Fehler: "Laufwerk nicht bereits".
			b $2c
::err_data		lda	#FILE_NOT_FOUND		;Fehler: "Nicht gefunden".
			b $2c
::end			lda	#NO_ERROR		;Kein Fehler.
			pha

			lda	#2
			jsr	CLOSE			;Datenkanal schließen.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			tax				;Fehlerstatus in XReg.

			rts				;Ende.

;*** Variablen.
:tempDrive		b $00
:OldDrvAdrTab		s $04
:NewDrvAdrTab		s $04

;*** Variablen zum DiskImage-Wechsel.
:DImgTypeList		b "??647181NP??????"
:FComDImgList		b "$:*.D??=P",NULL
:FComSDirList		b "$:*=B",NULL
:FComCDRoot		b "CD//"
:FComExitDImg		b "CD",$5f
:FComCDir		b "CD:"
			s 17
:FCom1stDImgLen		b $00
:FCom1stDImg		b "CD:"
			s 17

;*** DiskImage-Eintrag.
:slctEntryName		s 17      ;Ausgewählter Eintrag im Verzeichnis.
:slctEntryNum		b $00     ;Nummer des gewählten Eintrags in Liste.
:curDirCount		b $00     ;Anzahl DiskImages.
:cntEntries		b $00,$00 ;Anzahl Dateien/Verzeichnisse.
:maxDirCount		b $00     ;Anzahl Einträge (inkl. "<=" und "..")

;*** Systemtexte.
if LANG = LANG_DE
:Text_DirNavEntry	b "<=        (ROOT)"
			b "..      (ZURÜCK)"
endif
if LANG = LANG_EN
:Text_DirNavEntry	b "<=        (ROOT)"
			b "..          (UP)"
endif

;*** Dialogbox: "Laufwerk einschalten. Geräteadresse = #8 bis #19"
:Dlg_SetNewDev		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$0c,$0b
			w dt1
			b DBTXTSTR ,$0c,$20
			w dt2
			b DBTXTSTR ,$0c,$2a
			w dt3
			b DBTXTSTR ,$0c,$40
			w dt5
			b OK       ,$01,$50
			b CANCEL   ,$11,$50
			b NULL

if LANG = LANG_DE
:dt1			b PLAINTEXT,BOLDON
			b "ACHTUNG",0
:dt2			b PLAINTEXT
			b "Bitte schalten Sie jetzt",NULL
:dt3			b "das neue Laufwerk "
:dt4			b "x: ein!",NULL
:dt5			b "(Geräteadresse #8 bis #19)",NULL
endif

if LANG = LANG_EN
:dt1			b PLAINTEXT,BOLDON
			b "ATTENTION",0
:dt2			b PLAINTEXT
			b "Please switch on the new",NULL
:dt3			b "disk-drive "
:dt4			b "x: now!",NULL
:dt5			b "(Set address from #8 to #19)",NULL
endif

;*** Dialogbox: "GEOS-Laufwerksadresse wählen:"
:Dlg_SlctGEOSadr	b %01100001
			b $30,$8f
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$0c,$0b
			w :t1
			b DBTXTSTR ,$0c,$20
			w :t2
			b DBTXTSTR ,$0c,$2a
			w :t3
			b DBVARSTR ,$10,$3a
			b r5L
			b DRIVE    ,$02,$48
			b CANCEL   ,$11,$48
			b NULL

if LANG = LANG_DE
::t1			b PLAINTEXT,BOLDON
			b "LAUFWERK INSTALLIEREN",0
::t2			b PLAINTEXT
			b "Bitte Adresse für das neue",NULL
::t3			b "Laufwerk unter GEOS wählen:"
			b BOLDON,0
endif

if LANG = LANG_EN
::t1			b PLAINTEXT,BOLDON
			b "INSTALL DISK DRIVE",0
::t2			b PLAINTEXT
			b "Please select the GEOS",NULL
::t3			b "address for the disk drive:"
			b BOLDON,0
endif

;*** Dialogbox: Partition wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** Dialogbox: DiskImage wählen.
:Dlg_SlctDImg		b %10000001
			b DBUSRFILES
			w FileNTab
			b CANCEL    ,$00,$00
			b OPEN      ,$00,$00
			b NULL

;******************************************************************************
;*** Ladeadresse Laufwerkstreiber.
;******************************************************************************
:END_DISK_CORE		g ( BASE_DDRV_CORE + SIZE_DDRV_CORE )
.DKDRV_LOAD_ADDR	= BASE_DDRV_DATA
;******************************************************************************
