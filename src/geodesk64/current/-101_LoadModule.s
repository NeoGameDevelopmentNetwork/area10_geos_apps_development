; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** VLIR-Module nachladen.
;Hierbei wird das Modul geladen und mittels JMP-Befehl die
;entsprechende Routine angesprungen.
;Diese Routinen sollten nur mittels JMP-Befehl angesprungen werden da
;kein Rücksprung zur vorherigen Programm-Adresse erfolgt!
.MOD_OPEN_FILE		lda	#$00			;Datei öffnen.
			b $2c
.MOD_OPEN_EDITOR	lda	#$03			;GEOS/Editor starten.
			b $2c
.MOD_OPEN_APPL		lda	#$12			;GEOS/Anwendung auswählen.
			b $2c
.MOD_OPEN_AUTO		lda	#$15			;GEOS/AutoExec auswählen.
			b $2c
.MOD_OPEN_DOCS		lda	#$18			;GEOS/Dokument auswählen.
			b $2c
.MOD_OPEN_WRITE		lda	#$1b			;GEOS/Write-Dokument auswählen.
			b $2c
.MOD_OPEN_PAINT		lda	#$1e			;GEOS/Paint-Dokument auswählen.
			b $2c
.MOD_OPEN_BACKSCR	lda	#$21			;GEOS/Hintergrundbild auswählen.
			b $2c
.MOD_OPEN_EXITG		lda	#$24			;GEOS/nach GEOS verlassen.
			b $2c
.MOD_OPEN_EXIT64	lda	#$27			;GEOS/nach BASIC verlassen.
			b $2c
.MOD_OPEN_EXITB		lda	#$2a			;GEOS/BASIC-Programm auswählen.
			b $2c
.MOD_OPEN_DA		lda	#$2d			;GEOS-Hilfsmittel auswählen.
			b $2c
.MOD_FIND_ALFILE	lda	#$30			;AppLink-Datei suchen.
			ldx	#VLIR_FILE_OPEN
			bne	EXEC_MODULE

.MOD_SAVE_CONFIG	lda	#$00			;Konfiguration speichern.
			b $2c
.MOD_OPTIONS		lda	#$03			;Optionen ändern.
			ldx	#VLIR_SAVE_CONFIG
			bne	EXEC_MODULE

.MOD_FILE_INFO		lda	#$00			;Datei-Eigenschaften anzeigen.
			ldx	#VLIR_FILE_INFO
			bne	EXEC_MODULE

.MOD_FILE_DELETE	lda	#$00			;Dateien löschen.
			ldx	#VLIR_FILE_DELETE
			bne	EXEC_MODULE

.MOD_CREATE_DIR		lda	#$00			;NM-Verzeichnis erstellen.
			ldx	#VLIR_NM_DIR
			bne	EXEC_MODULE

.MOD_VALIDATE		lda	#$00			;Validate.
			b $2c
.MOD_UNDELFILE		lda	#$03			;Datei wiederherstellen.
			b $2c
.MOD_CLEANUP		lda	#$06			;Dateieintrag bereinigen.
			ldx	#VLIR_VALIDATE
			bne	EXEC_MODULE

.MOD_DISKINFO		lda	#$00			;DiskInfo.
			ldx	#VLIR_DISKINFO
			bne	EXEC_MODULE

.MOD_CLRDISK		lda	#$00			;Disk löschen.
			b $2c
.MOD_PURGEDISK		lda	#$03			;Bereinigen.
			b $2c
.MOD_FRMTDISK		lda	#$06			;Disk formatieren.
			ldx	#VLIR_CLRDISK
			bne	EXEC_MODULE

.MOD_COPYMOVE		lda	#$00			;Dateien kopieren/verschieben.
			ldx	#VLIR_COPYMOVE
			bne	EXEC_MODULE

.MOD_COLSETUP		lda	#$00			;Systemfarben ändern.
			ldx	#VLIR_COLORSETUP
			bne	EXEC_MODULE

.MOD_DISKCOPY		lda	#$00			;Diskette kopieren.
			ldx	#VLIR_DISKCOPY
			bne	EXEC_MODULE

.MOD_CONVERT		lda	#$00			;GEOS/CVT konvertieren.
			ldx	#VLIR_CONVERT
			bne	EXEC_MODULE

.MOD_CREATE_IMG		lda	#$00			;SD-DiskImage erstellen.
			ldx	#VLIR_CREATEIMG
			bne	EXEC_MODULE

.MOD_DIRSORT		lda	#$00			;Verzeichnis ordnen.
			b $2c
.MOD_SWAPENTRIES	lda	#$03			;Dateien tauschen.
			ldx	#VLIR_DIRSORT
			bne	EXEC_MODULE

.MOD_SYSTIME		lda	#$00			;Systemzeit setzen.
			ldx	#VLIR_SYSTIME
			bne	EXEC_MODULE

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
			ldx	#VLIR_DESKTOP
			;bne	EXEC_MODULE

:EXEC_MODULE		clc				;Einsprungadresse berechnen.
			adc	#<VLIR_BASE
			sta	:JmpAdr +1
			lda	#$00
			adc	#>VLIR_BASE
			sta	:JmpAdr +2

			stx	:VlirMod +1 		;Hauptmenü nachladen?
			dex
			beq	:VlirMod		; => Ja, weiter...

			lda	#$00			;Systemvektoren zurücksetzen.
			sta	appMain +0		;Uhrzeit aktualisieren abschalten.
			sta	appMain +1		;Routine Verändert aktuellen Font,
							;Probleme im Register-Menü.

			sta	RecoverVector +0	;Hintergrundroutine abschalten.
			sta	RecoverVector +1

			sta	mouseFaultVec +0	;Andere Programm-Module können
			sta	mouseFaultVec +1	;Maus- und Tastaturabfragen
			sta	otherPressVec +0	;aus dem Hauptmodul nicht nutzen!
			sta	otherPressVec +1

			sta	keyVector +0		;Tastenabfrage löschen.
			sta	keyVector +1

			jsr	WM_NO_MARGIN		;Textgrenzen zurücksetzen.
			jsr	WM_NO_MOUSE_WIN		;Mausgrenzen zurücksetzen.
			jsr	WM_SAVE_BACKSCR		;Aktuellen Bildschirm speichern.

;--- Programm-Modul nachladen.
;    Im AKKU befindet sich hier die
;    Nummer des Programm-Moduls.
::VlirMod		lda	#$ff
			jsr	LOAD_MODULE_RAM		;Neues Modul laden.

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
			ldx	#VLIR_APPLINK
			bne	swapVlirProg

.SUB_SLCT_PRNT		lda	#$06			;Drucker auswählen.
			b $2c
.SUB_SLCT_INPT		lda	#$09			;Eingabegerät auswählen.
			b $2c
.SUB_OPENPRNT_ERR	lda	#$0c			;Drucker auswählen/Fehler ausgeben.
			b $2c
.SUB_OPENPRNT_OK	lda	#$0f			;Drucker auswählen/OK ausgeben.
			b $2c
.SUB_OPEN_PRNT		lda	#$33			;Druckertreiber wechseln.
			b $2c
.SUB_OPEN_INPT		lda	#$36			;Eingabetreiber wechseln.
			ldx	#VLIR_FILE_OPEN
			bne	swapVlirProg

;--- Hinweis:
;Adresse der Routine ":SUB_GETFILES"
;wird in ":WM_CHK_MSE_KBD" verwendet um
;Verzeichnis aus dem Cache einzulesen.
.SUB_GETFILES		ldx	WM_WCODE
			lda	WIN_DATAMODE,x		;Partitionen/DiskImages aktiv?
			bne	SUB_GETPART		; => Ja, Part./DiskImages laden.
							;Wenn kein Cache aktiv dann müssen
							;die Partitionen oder DiskImages
							;neu eingelesen werden.

			lda	#$00			;Dateien von Disk/Cache einlesen.
			ldx	#VLIR_LOAD_FILES
			bne	swapVlirProg

.SUB_GETPART		lda	#$00			;Partitionen/DiskImages wechseln.
			b $2c
.SUB_OPEN_SD_ROOT	lda	#$03			;SD2IEC: Hauptverzeichnis öffnen.
			b $2c
.SUB_OPEN_SD_DIR	lda	#$06			;SD2IEC: Verzeichnis zurück.
			b $2c
.SUB_OPEN_SD_DIMG	lda	#$09			;SD2IEC: Image/Verzeichnis öffnen.
			b $2c
.SUB_GET_SD_MODE	lda	#$0c			;SD2IEC: Laufwerksmodus testen.
			ldx	#VLIR_PARTITION
			bne	swapVlirProg

.SUB_SHOWHELP		lda	#$00			;Info anzeigen.
			ldx	#VLIR_INFO
			bne	swapVlirProg

.SUB_SYSINFO		lda	#$00			;Systeminfo anzeigen.
			ldx	#VLIR_SYSINFO
			bne	swapVlirProg

.SUB_STATMSG		lda	#$00			;Statusmeldung ausgeben.
			ldx	#VLIR_STATMSG
			;bne	swapVlirProg

:swapVlirProg		cpx	GD_VLIR_ACTIVE		;Modul bereits im Speicher?
			bne	:load			; => Nein, weiter...

			clc				;Einsprungadresse berechnen.
			adc	#<VLIR_BASE
			ldx	#>VLIR_BASE
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

			ldx	#$1f			;ZeroPage-Register ":r0" bis ":r15"
::1			lda	r0L,x			;zwischenspeichern.
			pha
			dex
			bpl	:1

			jsr	UPDATE_CURMOD		;Aktuelles Programm-Modul speichern.

			lda	GD_VLIR_ACTIVE		;Aktuelles Modul merken.
;			sta	:curVlirMod		;Auf Stack ablegen, für den Fall
			pha				;das Sub-Modul ein Sub-Modul öffnet.

			lda	:JmpAdr			;Einsprungadresse und VLIR-Modul
			ldx	:VlirMod		;wieder einlesen.
			jsr	EXEC_MODULE		;Neues Modul nachladen/starten.
;			stx	:XReg +1		;XReg kann Fehlerstatus enthalten!

;			lda	:curVlirMod		;Zurück zum vorherigen Modul.
			pla
			jsr	LOAD_MODULE_RAM		;Anfangsmodul wieder einlesen.
			stx	:XReg +1		;Fehlernummer sichern.

			ldx	#$00			;ZeroPage-Register ":r0" bis ":r15"
::2			pla				;wieder zurücksetzen.
			sta	r0L,x
			inx
			cpx	#$20
			bcc	:2

			PopW	keyVector		;Systemvektoren zurücksetzen.
			PopW	otherPressVec
			PopW	mouseFaultVec
			PopW	RecoverVector
			PopW	appMain

::XReg			ldx	#$00			;Fehlerstatus zurücksetzen.
			rts

::JmpAdr		b $00
::VlirMod		b $00
;:curVlirMod		b $00

;*** Programm-Modul aus erweitertem
;    Speicher nachladen.
:LOAD_MODULE_RAM	sta	GD_VLIR_ACTIVE		;Modul-Nummer speichern.

			txa				;Evtl. Fehlerregister sichern.
			pha

			ldx	#$06			;ZeroPage-Register ":r0" bis ":r3L"
::1			lda	r0L,x			;zwischenspeichern.
			pha
			dex
			bpl	:1

			lda	GD_VLIR_ACTIVE		;Modul-Nummer speichern.
			jsr	SetVecModule		;Zeiger auf Modul im Speicher.
			jsr	FetchRAM		;Modul einlesen.

			ldx	#$00			;ZeroPage-Register ":r0" bis ":r3L"
::2			pla				;wieder zurücksetzen.
			sta	r0L,x
			inx
			cpx	#$07
			bcc	:2

			pla
			tax				;Fehlerregister zurücksetzen.

			rts

;*** Zeiger auf Speicherbereich setzen.
;    Übergabe: AKKU = VLIR-Modul-Nr.
;                     $00 = Variablen.
:SetVecModule		pha

			asl
			asl
			tay
			lda	#<APP_RAM		;Hauptmodul #0:
			ldx	#>APP_RAM		;Speicher ab APP_RAM.
			cpy	#$00
			beq	:1
			lda	#<VLIR_BASE		;Alle anderen VLIR-Module:
			ldx	#>VLIR_BASE		;Speicher ab VLIR_BASE.
::1			sta	r0L
			stx	r0H

			ldx	#$00
::2			lda	GD_DACC_ADDR,y		;Adresse des Moduls in der REU und
			sta	r1L,x			;Größe des Moduls kopieren.
			iny
			inx
			cpx	#$04
			bcc	:2

			pla
			tax
			lda	GD_DACC_ADDR_B,x	;Speicherbank für VLIR-Modul
			sta	r3L			;einlesen.
			rts
