; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* GeoDesk Systemroutinen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_MMAP"
			t "SymbTab_DCMD"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- AppLink-Definition.
			t "e.GD.10.AppLink"

;--- GeoDesk-Optionen.
			t "e.GD.10.Options"

;--- GeoDesk-Systemdaten.
			t "e.GD.10.System"
endif

;*** GEOS-Header.
			n "obj.GD10"
			f DATA

			o BASE_GEODESK

;*** Einsprungtabelle.
:VlirJumpTable		jmp	MOD_BOOT		;Erst-Start.
			jmp	MOD_REBOOT		;EnterDeskTop.

;*** Konfiguration, wird nicht gespeichert.
;Hinweis:
;Der BootLoader speichert die GeoDesk-
;Informationen (Dateiname, Laufwerk...)
;direkt im Hauptmodul.
;Offset zu ":VlirJumpTable" = 6Bytes!
			t "-G10_ConfTemp"

;*** Spezieller Zeichensatz (7x8)
.FontG3			v 7,"fnt.GeoDesk"

;*** Icons für Fenster-Manager.
.Icon_Drive
			j
<MISSING_IMAGE_DATA>

if FALSE
;Icon_MapGD
			j
<MISSING_IMAGE_DATA>
endif

.Icon_Map
			j
<MISSING_IMAGE_DATA>
if FALSE
;Icon_Map
			j
<MISSING_IMAGE_DATA>

;Icon_Map
			j
<MISSING_IMAGE_DATA>
endif

.Icon_Printer
			j
<MISSING_IMAGE_DATA>

.Icon_Input
			j
<MISSING_IMAGE_DATA>

.Icon_DEL
			j
<MISSING_IMAGE_DATA>

.Icon_CBM
			j
<MISSING_IMAGE_DATA>

if FALSE
;Icon_Drv41
			j
<MISSING_IMAGE_DATA>

;Icon_Drv71
			j
<MISSING_IMAGE_DATA>

;Icon_Drv81
			j
<MISSING_IMAGE_DATA>

;Icon_DrvNM
			j
<MISSING_IMAGE_DATA>
endif

.Icon_41_71
			j
<MISSING_IMAGE_DATA>

.Icon_81_NM
			j
<MISSING_IMAGE_DATA>

.Icon_MoreFiles
			j
<MISSING_IMAGE_DATA>

;*** Farb-Tabelle für "MyComputer"-Icons.
.sysIconColorTab
.Color_Drive		b $05,$05,$05,$0f,$0f,$0f,$09,$09,$09
.Color_Prnt		b $15,$15,$05,$bf,$bf,$b5,$b9,$b9,$b9
.Color_Inpt		b $05,$05,$05,$05,$01,$05,$b9,$09,$b9
.Color_SDir		b $75,$75,$75,$75,$75,$75,$79,$79,$79
;--- Hinweis:
;Standardfarbe für AppLinks wird durch
;C_GDesk_ALIcon gesetzt.
;Color_Std		b $01,$01,$01,$01,$01,$01,$01,$01,$01

;*** WindowManager-Modul nachladen.
.MOD_WM			jsr	ResetFontGD		;GeoDesk-Zeichensatz und
							;Vordergrund-Grafik aktivieren.
			lda	#GMOD_WMCORE
			jsr	SetVecModule
			jsr	FetchRAM		;Modul einlesen.

			lda	#$00
			sta	GD_HIDEWIN_MODE		;Modus "Fenster ausblenden" beenden.
			rts

;*** VLIR-Module nachladen.
;Hierbei wird das Modul geladen und mittels JMP-Befehl die
;entsprechende Routine angesprungen.
;Diese Routinen sollten nur mittels JMP-Befehl angesprungen werden da
;kein Rücksprung zur vorherigen Programm-Adresse erfolgt!

.MOD_BOOT		lda	#$00			;Oberfläche initialisieren.
			b $2c
.MOD_REBOOT		lda	#$03			;Rückkehr zum DeskTop.
			b $2c
.MOD_UPDATE		lda	#$06			;Rückkehr, Update oberstes Fenster.
			b $2c
.MOD_UPDATE_WIN		lda	#$09			;Rückkehr, Update Source/Target.
			b $2c
.MOD_RESTART		lda	#$0c			;Menu/FensterManager neu starten.
			b $2c
.MOD_INITWM		lda	#$0f			;FensterManager starten.
			ldx	#GMOD_DESKTOP
			jmp	EXEC_MODULE

.MOD_SEND_MENU		lda	#$00			;Senden an: Menü.
			b $2c
.MOD_SEND_PRNT		lda	#$03			;Senden an: Drucker.
			b $2c
.MOD_SEND_DRV1		lda	#$06			;Senden an: Laufwerk#1.
			b $2c
.MOD_SEND_DRV2		lda	#$09			;Senden an: Laufwerk#2.
			ldx	#GMOD_SENDTO
			jmp	EXEC_MODULE

;--- Nur s.GD.35.MenuDisk:
;.MOD_CBM_DIR		lda	#$00			;Verzeichnis anzeigen.
;			b $2c
;.MOD_CBM_COM		lda	#$03			;Befehl senden.
;			ldx	#GMOD_CBMDISK
;			jmp	EXEC_MODULE

;--- Nur s.GD.37.MenuTWin:
;.MOD_CMDPART		lda	#$00			;Partition umbenennen.
;			ldx	#GMOD_CMDPART
;			jmp	EXEC_MODULE

.MOD_OPEN_FILE		lda	#$00			;Datei öffnen.
			b $2c
.MOD_OPEN_CONFIG	lda	#$03			;GEOS/GD.CONFIG starten.
			b $2c
.MOD_OPEN_APPL		lda	#$06			;GEOS/Anwendung auswählen.
			b $2c
.MOD_OPEN_AUTO		lda	#$09			;GEOS/AutoExec auswählen.
			b $2c
.MOD_OPEN_DOCS		lda	#$0c			;GEOS/Dokument auswählen.
			b $2c
.MOD_OPEN_WRITE		lda	#$0f			;GEOS/Write-Dokument auswählen.
			b $2c
.MOD_OPEN_PAINT		lda	#$12			;GEOS/Paint-Dokument auswählen.
			b $2c
.MOD_OPEN_EXITG		lda	#$15			;GEOS/nach GEOS verlassen.
			b $2c
.MOD_OPEN_EXIT64	lda	#$18			;GEOS/nach BASIC verlassen.
			b $2c
.MOD_OPEN_EXITB		lda	#$1b			;GEOS/BASIC-Programm auswählen.
			b $2c
.MOD_OPEN_DA		lda	#$1e			;GEOS-Hilfsmittel auswählen.
			b $2c
.MOD_FIND_ALFILE	lda	#$21			;AppLink-Datei suchen.
			b $2c
.MOD_GDESKMOD		lda	#$27			;GEODESK-Module ändern.
			ldx	#GMOD_FILE_OPEN
			jmp	EXEC_MODULE

;--- Nur s.GD.30.MenuGEOS:
;.MOD_ICONMAN		lda	#$00			;Icon-Manager.
;			ldx	#GMOD_ICONMAN
;			jmp	EXEC_MODULE

.MOD_BACKSCRN		lda	#$00			;Hintergrundbild wechseln.
			ldx	#GMOD_BACKSCRN
			bne	EXEC_MODULE

.MOD_GPSHOW		lda	#$00			;GeoPaint-Diashow starten.
			ldx	#GMOD_GPSHOW
			bne	EXEC_MODULE

.MOD_SAVE_CONFIG	lda	#$00			;Konfiguration speichern.
			b $2c
.MOD_OPTIONS		lda	#$03			;Optionen ändern.
			ldx	#GMOD_SAVE_CONFIG
			bne	EXEC_MODULE

;--- Einsprung aus Unterprogramm.
;Die Format-Routine kann für die CMD-FD
;den Laufwerksmodus anpassen, wenn z.B.
;bei FD81 eine HDN-Diskette formatiert
;wird. Da hier aber auch das Register-
;Menü geladen wird, muss der WM hier
;vorher wieder eingelesen werden, da
;sonst beim aktualisieren Fensterdaten
;der WM im DACC überschrieben wird.
.MOD_NEWDRVMODE		jsr	MOD_WM			;FensterManager einlesen.

;--- Einsprung aus Menü-Rotuine.
.MOD_SETDRVMODE		lda	#$00			;Laufwerksmodus wechseln.
			ldx	#GMOD_SETDRVMODE
			bne	EXEC_MODULE

.MOD_FILE_INFO		lda	#$00			;Datei-Eigenschaften anzeigen.
			ldx	#GMOD_FILE_INFO
			bne	EXEC_MODULE

.MOD_FILE_DELETE	lda	#$00			;Dateien löschen.
			ldx	#GMOD_FILE_DELETE
			bne	EXEC_MODULE

.MOD_CREATE_DIR		lda	#$00			;NM-Verzeichnis erstellen.
			ldx	#GMOD_NM_DIR
			bne	EXEC_MODULE

.MOD_VALIDATE		lda	#$00			;Validate.
			b $2c
.MOD_UNDELFILE		lda	#$03			;Datei wiederherstellen.
			b $2c
.MOD_CLEANUP		lda	#$06			;Dateieintrag bereinigen.
			ldx	#GMOD_VALIDATE
			bne	EXEC_MODULE

.MOD_DISKINFO		lda	#$00			;DiskInfo.
			ldx	#GMOD_DISKINFO
			bne	EXEC_MODULE

.MOD_CLRDISK		lda	#$00			;Disk löschen.
			b $2c
.MOD_PURGEDISK		lda	#$03			;Bereinigen.
			b $2c
.MOD_FRMTDISK		lda	#$06			;Disk formatieren.
			ldx	#GMOD_CLRDISK
			bne	EXEC_MODULE

.MOD_COPYMOVE		lda	#$00			;Dateien kopieren/verschieben.
			ldx	#GMOD_COPYMOVE
			bne	EXEC_MODULE

.MOD_DISKCOPY		lda	#$00			;Diskette kopieren.
			ldx	#GMOD_DISKCOPY
			bne	EXEC_MODULE

.MOD_FILECVT		lda	#$00			;GEOS/CVT konvertieren.
			ldx	#GMOD_FILECVT
			bne	EXEC_MODULE

.MOD_CREATE_IMG		lda	#$00			;SD-DiskImage erstellen.
			ldx	#GMOD_CREATEIMG
			bne	EXEC_MODULE

.MOD_DIRSORT		lda	#$00			;Verzeichnis ordnen.
			b $2c
.MOD_SWAPENTRIES	lda	#$03			;Dateien tauschen.
			ldx	#GMOD_DIRSORT
			bne	EXEC_MODULE

.MOD_SYSTIME		lda	#$00			;Systemzeit setzen.
			ldx	#GMOD_SYSTIME
;			bne	EXEC_MODULE

;*** Modul laden und starten.
.EXEC_MODULE		ldy	GD_DACC_ADDR_B,x	;Ist Modul installiert ?
			bne	:get			; => Ja, weiter...

::err			LoadB	errDrvCode,$87		;"GMOD_NOT_FOUND"
			jsr	SUB_STATMSG		;Statusmeldung ausgeben.

			jsr	SET_LOAD_CACHE		;Verzeichnis neu laden.
			jmp	MOD_UPDATE		;Zurück zum Menü.

;--- GeoDesk-Modul laden.
::get			clc				;Einsprungadresse berechnen.
			adc	#< VLIR_BASE
			sta	:JmpAdr +1
			lda	#$00
			adc	#> VLIR_BASE
			sta	:JmpAdr +2

			stx	:VlirMod +1 		;Hauptmenü nachladen?
			dex
			beq	:VlirMod		; => Ja, weiter...

			lda	#$00			;Systemvektoren zurücksetzen.
			sta	appMain +0		;Uhrzeit aktualisieren abschalten.
			sta	appMain +1		;Routine verändert aktuellen Font,
							;Probleme im Register-Menü.

			sta	intBotVector +0
			sta	intBotVector +1

			sta	RecoverVector +0	;Hintergrundroutine abschalten.
			sta	RecoverVector +1

			sta	mouseFaultVec +0	;Andere Programm-Module können
			sta	mouseFaultVec +1	;Maus- und Tastaturabfragen
			sta	otherPressVec +0	;aus dem Hauptmodul nicht nutzen!
			sta	otherPressVec +1

			sta	keyVector +0		;Tastenabfrage löschen.
			sta	keyVector +1

			jsr	MAIN_RESETAREA		;Textgrenzen zurücksetzen.

;--- Programm-Modul nachladen.
;    Im AKKU befindet sich hier die
;    Nummer des Programm-Moduls.
::VlirMod		lda	#$ff
			jsr	GET_MODULE		;Neues Modul laden.

::JmpAdr		jmp	$ffff			;Unterprogrammm starten.

;*** VLIR-Module nachladen.
;Hierbei wird das Modul geladen und mittels JSR-Befehl die
;entsprechende Routine angesprungen. Anschließend wird das
;vorherige VLIR-Modul wieder eingelesen und es erfolgt die
;Rückkehr zur vorherigen Programm-Adresse.
.SUB_LNK_LD_DATA	lda	#$00			;AppLink-Daten laden.
			b $2c
.SUB_LNK_SV_DATA	lda	#$03			;AppLink-Daten speichern.
			b $2c
.SUB_LNK_RENAME		lda	#$06			;AppLink umbenennen.
			ldx	#GMOD_APPLINK
			bne	swapVlirProg

.SUB_FIND_STDICON	lda	#$24			;Standard-Icons suchen/laden.
			ldx	#GMOD_FILE_OPEN
			bne	swapVlirProg

;--- Hinweis:
;Adresse der Routine ":SUB_GETFILES"
;wird in ":WM_CHK_MSE_KBD" verwendet um
;Verzeichnis aus dem Cache einzulesen.
.SUB_GETFILES		lda	#$00			;Dateien von Disk/Cache einlesen.
			ldx	#GMOD_LOAD_FILES
			bne	swapVlirProg

.SUB_GETPART		lda	#$00			;Partitionen/DiskImages wechseln.
			b $2c
.SUB_OPEN_SD_ROOT	lda	#$03			;SD2IEC: Hauptverzeichnis öffnen.
			b $2c
.SUB_OPEN_SD_DIR	lda	#$06			;SD2IEC: Verzeichnis zurück.
			b $2c
.SUB_OPEN_SD_EXIT	lda	#$09			;SD2IEC: DiskImage verlassen.
			b $2c
.SUB_OPEN_SD_DIMG	lda	#$0c			;SD2IEC: Image/Verzeichnis öffnen.
			b $2c
.SUB_GET_SD_MODE	lda	#$0f			;SD2IEC: Laufwerksmodus testen.
			ldx	#GMOD_PARTITION
			bne	swapVlirProg

.SUB_SWAPBORDER		lda	#$00			;Datei mit Borderblock tauschen.
			ldx	#GMOD_SWAPBORDER
			bne	swapVlirProg

.SUB_SHOWHELP		lda	#$00			;Info anzeigen.
			ldx	#GMOD_INFO
			bne	swapVlirProg

.SUB_SYSINFO		lda	#$00			;Systeminfo anzeigen.
			ldx	#GMOD_SYSINFO
			bne	swapVlirProg

.SUB_STATMSG		lda	#$00			;Statusmeldung ausgeben.
			ldx	#GMOD_STATMSG
			bne	swapVlirProg

.SUB_SAVECOL		lda	#$00			;Farbprofil in DACC speichern.
			b $2c
.SUB_LOADCOL		lda	#$03			;Farbprofil aus DACC laden.
			ldx	#GMOD_COLORSETUP
;			bne	swapVlirProg

:swapVlirProg		cpx	GD_VLIR_CORE		;Modul bereits im Speicher?
			bne	:load			; => Nein, weiter...

			clc				;Einsprungadresse berechnen.
			adc	#< VLIR_BASE
			ldx	#> VLIR_BASE
			bcc	:jmp
			inx
::jmp			jmp	CallRoutine		;Unterprogramm aufrufen.

::load			sta	:JmpAdr			;Einsprungadresse und Modul-
			stx	:VlirMod		;Nummer zwischenspeichern.

			PushW	appMain			;Systemvektoren zwischenspeichern.
			PushW	RecoverVector
			PushW	mouseFaultVec
			PushW	otherPressVec
			PushW	keyVector
			PushW	intBotVector

			ldx	#$1f			;ZeroPage-Register ":r0" bis ":r15"
::1			lda	r0L,x			;zwischenspeichern.
			pha
			dex
			bpl	:1

			jsr	BACKUP_CURMOD		;Aktuelles Programm-Modul speichern.

			lda	GD_VLIR_CORE		;Aktuelles Modul merken.
			pha				;Auf Stack ablegen, für den Fall
							;das Sub-Modul ein Sub-Modul öffnet.

			lda	:JmpAdr			;Einsprungadresse und VLIR-Modul
			ldx	:VlirMod		;wieder einlesen.
			jsr	EXEC_MODULE		;Neues Modul nachladen/starten.
			stx	:ModErr			;XReg kann Fehlerstatus enthalten!

			pla				;Zurück zum vorherigen Modul.
			jsr	GET_MODULE		;Anfangsmodul wieder einlesen.

			ldx	#$00			;ZeroPage-Register ":r0" bis ":r15"
::2			pla				;wieder zurücksetzen.
			sta	r0L,x
			inx
			cpx	#$20
			bcc	:2

			PopW	intBotVector
			PopW	keyVector		;Systemvektoren zurücksetzen.
			PopW	otherPressVec
			PopW	mouseFaultVec
			PopW	RecoverVector
			PopW	appMain

::XReg			ldx	:ModErr			;Fehlerstatus zurücksetzen.
			rts

::JmpAdr		b $00
::VlirMod		b $00
::ModErr		b $00

;*** Programm-Modul aus erweitertem
;    Speicher nachladen.
:GET_MODULE		sta	GD_VLIR_CORE		;Modul-Nummer speichern.

			jsr	SetVecModule		;Zeiger auf Modul im Speicher.
			jsr	FetchRAM		;Modul einlesen.

			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Zeiger auf Speicherbereich setzen.
;    Übergabe: AKKU = VLIR-Modul-Nr.
;                     $00 = Variablen.
:SetVecModule		pha
			cmp	#GMOD_GDCORE
			beq	:core
			cmp	#GMOD_WMCORE
			beq	:wm

::default		ldx	#NULL
			stx	GD_VLIR_MODX

			ldx	#< VLIR_BASE		;Alle anderen VLIR-Module:
			ldy	#> VLIR_BASE		;Speicher ab VLIR_BASE.
			bne	:set

::core			ldx	#< GDA_SYSTEM		;Hauptmodul #0:
			ldy	#> GDA_SYSTEM		;Speicher ab GDA_SYSTEM.
			bne	:set

::wm			ldx	#< BASE_WMCORE		;WindowManager #1:
			ldy	#> BASE_WMCORE		;Speicher ab BASE_WM.
;			bne	:set

::set			stx	r0L
			sty	r0H

			asl
			asl
			tay
			ldx	#$00
::1			lda	GD_DACC_ADDR,y		;Adresse des Moduls in der REU und
			sta	r1L,x			;Größe des Moduls kopieren.
			iny
			inx
			cpx	#$04
			bcc	:1

			pla
			tax
			lda	GD_DACC_ADDR_B,x	;Speicherbank für VLIR-Modul
			sta	r3L			;einlesen.
			rts

;*** Aktuelles Programm-Modul speichern.
;Sichert u.a. Variablen des Fenstermanagers.
.BACKUP_CURMOD		ldy	GD_VLIR_CORE		;Aktuelles VLIR-Modul sichern.
			b $2c

;*** WM-Modul speichern.
.BACKUP_WMCORE		ldy	#GMOD_WMCORE		;WindowManager sichern.
			b $2c

;*** GeoDesk-Modul speichern.
.BACKUP_GDCORE		ldy	#GMOD_GDCORE		;GeoDesk-Daten sichern.

			pha				;AKKU/XReg sichern.
			txa				;Beinhaltet ggf. Programm-Modul
			pha				;und Einsprungadresse.

			tya
			jsr	SetVecModule		;Sichert u.a. Variablen des
			jsr	StashRAM		;Fenstermanagers.

			pla
			tax
			pla

:UpdateExit		rts

;*** Variablen speichern.
.putGDINI_RAM		ldy	#jobStash
			b $2c
.getGDINI_RAM		ldy	#jobFetch
			jsr	setVecGDINI		;Zeiger auf GD.INI setzen.
			jmp	DoRAMOp			;GeoDesk-Einstellungen speichern.

;*** Zeiger auf GD.INI-Daten für GeoDesk.
.setVecGDINI		LoadW	r0,GDA_OPTIONS
			LoadW	r1,R3A_CFG_GDSK
			LoadW	r2,GDS_OPTIONS
			lda	MP3_64K_DATA
			sta	r3L
			rts

;*** Laufwerk und Diskette öffnen.
;    Übergabe: AKKU = Laufwerk
;    Rückgabe: XREG = $00/Fehler
.Sys_SetDrv_Open	jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch.

			jsr	QuickOpenDisk
;			txa
;			bne	:err

;			ldx	#NO_ERROR
::err			rts

;*** Einfaches "Diskette öffnen".
.QuickOpenDisk		jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler ?
			beq	:getname		; => Nein, weiter...

			jmp	OpenDisk		;Vollständiges OpenDisk ausführen.

::getname		ldx	#r0L			;Zeiger auf Speicher für
			jsr	GetPtrCurDkNm		;Diskname aktuelles Laufwerk.

			ldy	#18 -1			;Diskname kopieren.
::1			lda	curDirHead +$90,y
			sta	(r0L),y
			dey
			bpl	:1

			ldx	#NO_ERROR		;Kein Fehler...
::err			rts

;*** Partition ermitteln.
;    Übergabe: curDrive = Laufwerk.
;    Rückgabe: $00 oder Partitions-Nr.
.Sys_GetDrv_Part	ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,x	;CMD-Laufwerk?
			and	#SET_MODE_PARTITION
			beq	:1			; => Nein, Ende...
			lda	drivePartData-8,x	;Aktive Partition einlesen.
::1			rts

;*** Verzeichnis ermitteln.
;    Übergabe: curDrive = Laufwerk.
;    Rückgabe: AKKU/XREG = Verzeichnis.
.Sys_GetDrv_SDir	ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,x	;NativeMode-Laufwerk?
			and	#SET_MODE_SUBDIR
			tax
			beq	:1			; => Nein, Ende...
			jsr	GetDirHead		;Verzeichnis-Header einlesen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
			lda	#$00			;Kein Verzeichnis aktivieren.
			tax
			rts
::2			lda	curDirHead +32		;Aktives Verzeichnis einlesen.
			ldx	curDirHead +33
::1			rts

;*** Source-Laufwerk.
;    Übergabe: AKKU = Laufwerk 8-11
.Sys_SetDvSource	sta	sysSource		;Laufwerksadresse speichern und
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	Sys_GetDrv_Part		;Ggf. Partitionsdaten einlesen und
			sta	sysSource +1		;speichern (nicht-CMD = $00).
			jsr	Sys_GetDrv_SDir		;Ggf. SubDir einlesen und
			sta	sysSource +2		;speichern (nicht-Native = $00).
			stx	sysSource +3
			rts

;*** Target-Laufwerk.
;    Übergabe: AKKU = Laufwerk 8-11
.Sys_SetDvTarget	sta	sysTarget		;Laufwerksadresse speichern und
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	Sys_GetDrv_Part		;Ggf. Partitionsdaten einlesen und
			sta	sysTarget +1		;speichern (nicht-CMD = $00).
			jsr	Sys_GetDrv_SDir		;Ggf. SubDir einlesen und
			sta	sysTarget +2		;speichern (nicht-Native = $00).
			stx	sysTarget +3
			rts

;*** Aktuelles Laufwerk speichern.
;Hinweis:
;Einsprungsadresse wird aktuell
;nicht verwendet.
::SaveTempDrive		lda	curDrive		;Aktuelles Laufwerk speichern.

;*** Partition setzen.
;    Übergabe: AKKU = Laufwerk.
;    Rückgabe: XREG = $00/Fehler
.Sys_SvTempDrive	pha

			ldy	curDrive		;Aktuelles Laufwerk speichern.
			sty	TempDrive

			lda	RealDrvMode -8,y	;Laufwerksmodus speichern.
			sta	TempMode

			jsr	Sys_GetDrv_Part		;Partition einlesen und
			sta	TempPart		;zwischenspeichern.

			jsr	Sys_GetDrv_SDir		;Verzeichnis einlesen und
			sta	TempSDir +0		;zwischenspeichern.
			stx	TempSDir +1

			pla
			jsr	Sys_SetDrv_Open		;Laufwerk/Diskette öffnen.
;			txa				;Laufwerkfehler?
;			bne	:error			; => Ja, Abbruch...

;			ldx	#NO_ERROR
::error			rts

;*** Aktuelles Laufwerk speichern und
;    Startlaufwerk öffnen.
.TempBootDrive		jsr	FindBootDrive		;Boot-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden?
			bne	:error			; => Nein, Abbruch...

			jsr	Sys_SvTempDrive		;Aktuelles Laufwerk speichern.
			txa				;Laufwerkfehler?
			bne	:error			; => Ja, Abbruch...

			ldx	curDrive		;Zusätzlich ramBase sichern.
			lda	ramBase -8,x
			sta	BootRBase

			jmp	OpenBootDrive		;Boot-Laufwerk aktivieren.

::error			rts

;*** Zurück zum Quell-Laufwerk.
.BackTempDrive		lda	TempDrive
			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Laufwerkfehler?
			bne	:exit			; => Ja, Abbruch...

			bit	TempMode		;Laufwerks-Modus einlesen.
			bmi	:open_part		; => Partitioniertes Laufwerk.
			bvs	:open_sdir		; => NativeMode-Laufwerk.
			jmp	QuickOpenDisk		; => Standard-Laufwerk.

::open_part		lda	TempPart
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	TempMode		;NativeMode-Laufwerk?
			bvs	:open_sdir		; => Ja, weiter...
::exit			rts

::open_sdir		lda	TempSDir +0
			sta	r1L
			lda	TempSDir +1
			sta	r1H
			jmp	OpenSubDir		;Verzeichnis öffnen.

;*** Startlaufwerk öffnen.
.OpenBootDrive		jsr	FindBootDrive		;Boot-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden?
			bne	:exit			; => Nein, Abbruch...

			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Laufwerkfehler?
			bne	:exit			; => Ja, Abbruch...

			bit	BootMode		;Laufwerks-Modus einlesen.
			bmi	:open_part		; => Partitioniertes Laufwerk.
			bvs	:open_sdir		; => NativeMode-Laufwerk.
			jmp	QuickOpenDisk		; => Standard-Laufwerk.

::open_part		lda	BootPart
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	BootMode		;NativeMode-Laufwerk?
			bvs	:open_sdir		; => Ja, weiter...
::exit			rts

::open_sdir		lda	BootSDir +0
			sta	r1L
			lda	BootSDir +1
			sta	r1H
			jmp	OpenSubDir		;Verzeichnis öffnen.

;*** Startlaufwerk suchen.
:FindBootDrive		ldx	BootDrive		;Boot-Laufwerk einlesen.
			jsr	:test_drive		;Laufwerk = Boot-Laufwerk?
			beq	:found			; => Ja, Ende...

			ldx	#8			;Zeiger auf erstes Laufwerk und
::loop			cpx	BootDrive		;Laufwerk bereits getestet?
			beq	:skip			; => Ja, überspringen.
			jsr	:test_drive		;Boot-Laufwerkstyp suchern.
			beq	:found			; => Gefunden, Ende...
::skip			inx				;Nächstes Laufwerk.
			cpx	#11 +1			;Laufwerk 8-11 durchsucht?
			bcc	:loop			; => Nein, weiter...

			ldx	#DEV_NOT_FOUND		;Boot-Laufwerk nicht mehr gefunden.
			rts

::found			txa
			ldx	#NO_ERROR		;Boot-Laufwerk gefunden.
			rts

::test_drive		lda	RealDrvType -8,x	;RealDrvType vergleichen.
			cmp	BootType		;Stimmt Laufwerkstyp?
			bne	:failed			; => Nein, Fehler.

			lda	driveType -8,x		;RAM-Laufwerk?
			bpl	:ok			; => Nein, weiter....
			lda	ramBase -8,x		;RAM-Adresse vergleichen.
			cmp	BootRBase		;Stimmt RAM-Adresse?
			bne	:failed			; => Nein, Fehler.

::ok			lda	#$00
			rts

::failed		lda	#$ff
			rts

;
;Routine  : SET_LOAD_DISK
;Parameter: -
;Rückgabe : GD_RELOAD_DIR = $80 => Verzeichnis von Disk einlesen.
;Verändert: A
;Funktion : Flag setzen "Verzeichnis von Disk neu einlesen".
;
.SET_LOAD_DISK		lda	#GD_LOAD_DISK		;Dateien immer von Disk einlesen.
			b $2c

;
;Routine  : SET_TEST_CACHE
;Parameter: -
;Rückgabe : GD_RELOAD_DIR = $40 => Verzeichnis von Cache oder Disk einlesen.
;Verändert: A
;Funktion : Flag setzen "Verzeichnis von Cache oder Disk einlesen".
;
.SET_TEST_CACHE		lda	#GD_TEST_CACHE		;Dateien aus Cache oder von Disk.
			b $2c

;
;Routine  : SET_SORT_MODE
;Parameter: -
;Rückgabe : GD_RELOAD_DIR = $3F => Verzeichnis im Speicher sortieren.
;Verändert: A
;Funktion : Flag setzen "Verzeichnis im Speicher sortieren".
;
.SET_SORT_MODE		lda	#GD_SORT_ONLY		;Nur Dateien sortieren.
			b $2c

;
;Routine  : SET_LOAD_CACHE
;Parameter: -
;Rückgabe : GD_RELOAD_DIR = $00 => Verzeichnis aus Cache einlesen.
;Verändert: A
;Funktion : Flag setzen "Verzeichnis aus Cache einlesen".
;
.SET_LOAD_CACHE		lda	#GD_LOAD_CACHE		;Dateien aus Cache einlesen.
			sta	GD_RELOAD_DIR
			rts

;
;Routine  : ResetFontGD
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y,r0
;Funktion : Aktiviert GeoDesk-Zeichensatz.
;
.ResetFontGD		lda	#ST_WR_FORE		;Nur in Vordergrund schreiben.
			sta	dispBufferOn

			lda	#%00000000
			sta	currentMode		;PLAINTEXT.

			LoadW	r0,FontG3		;Zeichensatz aktivieren.
			jmp	LoadCharSet

;*** Titelzeile in Dialogbox löschen.
.Dlg_DrawTitel		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$30,$3f
			w	$0040,$00ff
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;
;Routine  : sys_SvBackScrn
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y
;Funktion : Speichert gesamten Bildschirm-Inhalt in ScreenBuffer.
;           Wird verwendet für Menüs usw.
;
.sys_SvBackScrn		ldy	#jobStash		;Job-Code für ":StashRAM"
			b $2c

;
;Routine  : sys_LdBackScrn
;Parameter: -
;Rückgabe : -
;Verändert: A,X,Y
;Funktion : Lädt gesamten Bildschirm-Inhalt in ScreenBuffer.
;           Wird verwendet für Menüs usw.
;
.sys_LdBackScrn		ldy	#jobFetch		;Job-Code für ":FetchRAM"

			ldx	#0			;Register ":r0" bis ":r3L"
::1			lda	r0L,x			;zwischenspeichern.
			pha
			inx
			cpx	#8
			bcc	:1

			lda	GD_SYSDATA_BUF		;64Kb Speicherbank für
			sta	r3L			;Bildschirm-Speicher setzen.
			sty	r3H 			;JobCode zwischenspeichern.

			ldy	#6			;Zeiger auf Farbdaten setzen.
			jsr	:copy			;Farbdaten kopieren.

			ldy	#0			;Zeiger auf Grafikdaten setzen.
			jsr	:copy			;Grafikdaten kopieren.

			ldx	#8 -1			;Register ":r0" bis ":r3L"
::2			pla				;zwischenspeichern.
			sta	r0L,x
			dex
			bpl	:2

			rts

;--- Grafik-/Farb-Daten kopieren.
::copy			ldx	#0
::21			lda	:data,y
			sta	r0L,x
			iny
			inx
			cpx	#6
			bcc	:21

			ldy	r3H
			jmp	DoRAMOp			;Daten speichern/einlesen.

::data			w SCREEN_BASE			;Grafikdaten.
			w   GD_BACKSCR_BUF
			w   8000
			w COLOR_MATRIX			;Farbdaten.
			w   GD_BACKCOL_BUF
			w   1000

;
;Routine  : waitNoMseKey
;Parameter: -
;Rückgabe : -
;Verändert: A
;Funktion : Warten bis keine Maustaste gedrückt.
;
.waitNoMseKey		lda	mouseData		;Maustaste gedrückt?
			bpl	waitNoMseKey		; => Ja, warten...
			lda	#NULL
			sta	pressFlag		;Tastenstatus löschen.
			rts				;Ende.

;*** Grenzen für Textausgabe/Mauszeiger zurücksetzen.
.MAIN_RESETAREA		ldx	#5
::1			lda	:default,x
			sta	windowTop,x
			sta	mouseTop,x
			dex
			bpl	:1
			rts

::default		b $00
			b SCRN_HEIGHT -1
			w $0000
			w SCRN_WIDTH -1

;*** Text ausgebene.
;    Übergabe: r0  = Zeiger auf String.
;              r1H = Y-Position.
;              r11 = X-Position.
;Hinweis:
;Im Gegensatz zu PutString werden hier
;Sonderzeichen ersetzt.
.smallPutString		ldy	#$00			;Zeiger auf nächstes Zeichen.
			lda	(r0L),y			;Zeichen einlesen.
			beq	:exit			; => String-Ende...
			cmp	#$a0			;SHIFT+SPACE?
			beq	:3			; => Zeichen überspringen.
							;Umgeht Problem mit $A0 im Namen.
			and	#%01111111		;Unter GEOS nur Zeichen $20-$7E.
			cmp	#$20			;ASCII < $20?
			bcc	:1			; => Ja, Zeichen ersetzen.
			cmp	#$7f			;ASCII < $7F?
			bcc	:2			; => Ja, weiter...

::1			lda	#GD_REPLACE_CHAR	;Zeichen ersetzen.
::2			jsr	SmallPutChar		;Zeichen ausgeben.

::3			inc	r0L			;Zeiger auf nächstes Zeichen.
			bne	smallPutString
			inc	r0H
			jmp	smallPutString		;Nächstes Zeichen ausgeben.

::exit			rts

;*** Dateiname aus Verzeichniseintrag kopieren.
;    Übergabe: XReg = ZeroPage-Register/Zeiger Verzeichnis-Eintrag.
;              YReg = ZeroPage-Register/Zeiger auf 17Byte-Puffer.
.SysCopyFName		lda	zpage +0,x		;Zeiger auf Dateiname korrigieren.
			pha				;Original-Adresse speichern.
			clc
			adc	#$05
			sta	zpage +0,x
			lda	zpage +1,x
			pha
			adc	#$00
			sta	zpage +1,x

			txa				;Zeiger auf Quelle sichern.
			pha

			jsr	SysCopyName		;Dateiname kopieren.

			pla				;Zeiger auf Quelle zurücksetzen.
			tax

			pla				;Zeiger auf Verzeichnis-
			sta	zpage +1,x		;Eintrag zurücksetzen.
			pla
			sta	zpage +0,x
			rts

;*** Name kopieren.
;--- HINWEIS:
;Name rückwärts auf $00/$A0 testen, da
;modifizierte Dateien mit $A0 im Namen
;sonst nicht kopiert werden können.
.SysFilterName		lda	#$ff			;Ungültige Zeichen filtern.
			b $2c
.SysCopyName		lda	#$00			;Name ungefiltert kopieren.
			sta	:filter_mode		;Filtermodus speichern.

			stx	:read1 +1
			stx	:read2 +1
			sty	:write1 +1
			sty	:write2 +1

			ldy	#15			;Letztes Zeichen im Dateinamen
::read1			lda	(r0L),y			;suchen das nicht $00/$A0 ist.
			beq	:1
			cmp	#$a0
			bne	:copy
::1			dey
			bpl	:read1

			iny				;Mind. 1 Zeichen kopieren.

::copy			iny				;Position zwischenspeichern.
			tya
			pha
			dey

::read2			lda	(r0L),y			;Zeichen aus Dateiname einlesen.
			bit	:filter_mode		;Ungültige zeichen filtern?
			bpl	:write1
			and	#%01111111		;Unter GEOS nur Zeichen $20-$7E.
			cmp	#$20			;ASCII < $20?
			bcc	:filter			; => Ja, Zeichen ersetzen.
			cmp	#$7f			;ASCII < $7F?
			bcc	:write1			; => Ja, weiter...
::filter		lda	#GD_REPLACE_CHAR	;Zeichen ersetzen.
::write1		sta	(r0L),y			;Zeichen in Puffer kopieren.
			dey				;Puffer voll?
			bpl	:read2			; => Nein, weiter...

			pla				;Zeiger auf letztes Byte im
			tay				;Dateinamen setzen.

;--- Ende, Puffer mit $00-Bytes auffüllen.
::end			lda	#NULL			;Dateiname auf 17 Zeichen mit
::write2		sta	(r0L),y			;$00-Bytes auffüllen.
			iny
			cpy	#16 +1
			bcc	:write2

			rts

::filter_mode		b $00

;*** Dezimalzahl nach ASCII wandeln.
;    Übergabe: AKKU = Dezimal-Zahl 0-99.
;    Rückgabe: XREG/AKKU = 10er/1er Dezimalzahl.
.DEZ2ASCII		ldx	#"0"
::1			cmp	#10			;Restwert < 10?
			bcc	:2			; => Ja, weiter...
;			sec
			sbc	#10			;Restwert -10.
			inx				;10er-Zahl +1.
			cpx	#"9" +1			;10er-Zahl > 9?
			bcc	:1			; => Nein, weiter...
			dex				;Wert >99, Zahl auf
			lda	#9			;99 begrenzen.
::2			clc				;1er-Zahl nach ASCII wandeln.
			adc	#"0"
			rts

;*** HEX-Zahl nach ASCII wandeln.
;Übergabe: AKKU = Hex-Zahl.
;Rückgabe: AKKU/XREG = LOW/HIGH-Nibble Hex-Zahl.
.HEX2ASCII		pha				;HEX-Wert speichern.
			lsr				;HIGH-Nibble isolieren.
			lsr
			lsr
			lsr
			jsr	:1			;HIGH-Nibble nach ASCII wandeln.
			tax				;Ergebnis zwischenspeichern.

			pla				;HEX-Wert zurücksetzen und
							;nach ASCII wandeln.
::1			and	#%00001111
			clc
			adc	#"0"
			cmp	#$3a			;Zahl größer 10?
			bcc	:2			;Ja, weiter...
			clc				;Hex-Zeichen nach $A-$F wandeln.
			adc	#$07
::2			rts

;*** AppLink-Laufwerk öffnen.
.AL_SET_DEVICE		lda	#$00			;Flag löschen: "Disk öffnen".
			sta	Flag_ALOpenDisk

			ldy	#LINK_DATA_DRIVE	;Laufwerksadresse einlesen.
			lda	(r14L),y
			tax

			ldy	#LINK_DATA_DVTYP
			lda	(r14L),y		;RealDrvType für AppLink einlesen.
			ldy	driveType   -8,x	;Laufwerk verfügbar?
			beq	:1			; => Nein, Suche starten...
			cmp	RealDrvType -8,x	;Passt Laufwerk zu AppLink?
			beq	:OpenAppLPart		; => Ja, weiter...

::1			ldx	#$08			;Passendes Laufwerk suchen.
::2			lda	driveType   -8,x	;Laufwerk verfügbar?
			beq	:3			; => Nein, weiter...
			cmp	RealDrvType -8,x	;Passt Laufwerk zu AppLink?
			beq	:OpenAppLPart		; => Ja, weiter...
::3			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#$0c			;Alle Laufwerke durchsucht?
			bcc	:2			; => Nein, weiter...

;--- AppLink-Laufwerk nicht gefunden.
::error			ldx	#$ff
			rts

;--- CMD-Partitionen.
::OpenAppLPart		txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			ldx	curDrive		;CMD-Laufwerk mit Partitionen?
			lda	RealDrvMode -8,x
			and	#SET_MODE_PARTITION
			beq	:OpenAppLSubD		; => Nein, weiter...

			ldy	#LINK_DATA_DPART
			lda	(r14L),y		;Partiton definiert?
			beq	:OpenAppLSubD		; => Nein, weiter...
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...
			dex
			stx	Flag_ALOpenDisk		;Flag setzen "Disk geöffnet".

;--- NativeMode-Unterverzeichnisse.
::OpenAppLSubD		ldx	curDrive		;CMD-Laufwerk mit Verzeichnissen?
			lda	RealDrvMode -8,x
			and	#SET_MODE_SUBDIR
			beq	:OpenStdDisk		; => Nein, weiter...

			ldy	#LINK_DATA_DSDIR
			lda	(r14L),y		;Verzeichnis definiert?
			beq	:OpenStdDisk		; => Nein, weiter...
			sta	r1L
			iny
			lda	(r14L),y
			sta	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...
			dex
			stx	Flag_ALOpenDisk		;Flag setzen "Disk geöffnet".

::OpenStdDisk		ldx	#$00
			bit	Flag_ALOpenDisk		;Diskette bereits geöffnet?
			bmi	:end			; => Ja, Ende...

			jsr	OpenDisk		;GEOS/OpenDisk.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...
::end			rts

;*** Variablen.
:Flag_ALOpenDisk	b $00				;$00 = OpenDisk aufrufen.
							;$FF = OpenDisk nicht nötig.

;*** Verknüpfungen für DeskTop
.LinkData		b $01

if LANG = LANG_DE
::1a			b "Arbeitsplatz"		;17Z. AppLink-Name.
::1b			s 17 - (:1b - :1a)
::2a			b "Arbeitsplatz"		;17Z. Dateiname.
::2b			s 17 - (:2b - :2a)
endif
if LANG = LANG_EN
::1a			b "My Computer"			;17Z. AppLink-Name.
::1b			s 17 - (:1b - :1a)
::2a			b "My Computer"			;17Z. Dateiname.
::2b			s 17 - (:2b - :2a)
endif

			b $80				;Typ: $00=Anwendung.
							;     $80=Arbeitsplatz.
							;     $FF=Laufwerk.
							;     $FE=Drucker.
							;     $FD=Verzeichnis.
			b $02				;Icon XPos (Cards).
			b $01				;Icon YPos (Cards).
			b $ff,$ff,$ff			;Farbdaten (3x3 Bytes).
			b $ff,$ff,$ff			; => C_GDesk_MyComp
			b $ff,$ff,$ff
			b $00				;Laufwerk: Adresse.
			b $00				;Laufwerk: RealDrvType.
			b $00				;Laufwerk: Partition.
			b $00,$00			;Laufwerk: SubDir Tr/Se.
			b $00,$00,$00			;Verzeichnis-Eintrag.
			b $00				;Fensteroptionen.
							; Bit#7 = 1 : Gelöschte Dateien
							; Bit#6 = 1 : Icons anzeigen
							; Bit#5 = 1 : Größe in Kb
							; Bit#4 = 1 : Details anzeigen

;--- Hinweis:
;Wenn der AppLink-Datensatz vergrößert
;wird, dann genügend Speicher für den
;Arbeitsplatz-AppLink bereitstellen.
:LinkDataCheck		= (LinkData + LINK_DATA_BUFSIZE) +1
			e LinkDataCheck

;--- Speicher für AppLink-Daten.
			s (LINK_COUNT_MAX-1)*LINK_DATA_BUFSIZE
.LinkDataEnd

;*** Desktop-Icons.
.appLinkIBufA

;--- Arbeitsplatz-Icon.
			j
<MISSING_IMAGE_DATA>

;--- Benutzer-AppLink-Icons.
.appLinkIBufU		s (LINK_COUNT_MAX-1)*LINK_ICON_BUFSIZE
.appLinkIBufE

;------------------------------------------------------------------------------

;*** Beginn Speicher für VLIR-Module.
.VLIR_BASE
