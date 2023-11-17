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
			t "SymbTab_CSYS"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_GERR"
			t "SymbTab_APPS"
			t "SymbTab_MMAP"
			t "SymbTab_SCPU"
			t "SymbTab_RLNK"
			t "SymbTab_GRAM"
			t "SymbTab_GRFX"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- GD.INI-Version.
			t "opt.INI.Version"
endif

;*** GEOS-Header.
			n "GD.FBOOT"
			c "GDOSBOOT    V3.0"
			t "opt.Author"
;--- Hinweis:
;Startprogramme können von DESKTOP 2.x
;nicht kopiert werden.
;			f SYSTEM_BOOT ;Typ Startprogramm.
			f APPLICATION ;Typ Anwendung.
			z $80 ;nur GEOS64

			o $0801 -2
			p APP_INSTALL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "FBOOT-Startprogramm"
			h "für GDOS64..."
endif
if LANG = LANG_EN
			h "FBOOT start utility"
			h "for GDOS64..."
endif

;*** Ladeadresse für BASIC-Programm.
:BASIC_LOAD		b $01,$08

;*** Kopfdaten BASIC-Zeile.
;    Nur wirksam, wenn die Startdatei über "LOAD'name',8" an den Beginn
;    des BASIC-Speichers geladen wird.
::L0801			w $080b				;Link-Pointer auf nächste Zeile.
::L0803			w $0040				;Zeilen-Nr.

;*** BASIC-Zeile: SYS 2061
::L0805			b $9e,$32,$30,$36,$31,$00

;*** Ende BASIC-Programm markieren.
::L080B			w $0000

;*** Start-Programm für GEOS aufrufen.
:JMPTAB			jmp FASTBOOT

;*** Angaben zum Startlaufwerk.
:BOOT_DEVICE		b $00				;Laufwerksadresse.
:OFFSET_DRIVE		= (BOOT_DEVICE   - BASIC_LOAD)

;*** Angaben zur Speichererweiterung.
;BOOT_RAM_TYPE: $00 = RAM nicht gewählt.
;               $10 = RAMCard gewählt.
;               $20 = BBGRAM  gewählt.
;               $40 = C=REU   gewählt.
;               $80 = RAMLink gewählt.
;               $FF = DACC neu wählen.
:BOOT_RAM_TYPE		b $00    ;DACC-Speicher: Typ.
:BOOT_RAM_SIZE		b $00    ;DACC-Speicher: Größe.
:BOOT_RAM_BANK		w $0000  ;Adresse erste Speicherbank RAMLink/RAMCard.
:BOOT_RAM_PART		b $00    ;Nicht verwendet.
:OFFSET_RAM		= (BOOT_RAM_TYPE - BASIC_LOAD)

;*** Externe Routinen.
			t "-G3_LdDACCdev"

;--- Standard-Gerätetreiber laden.
;Wird durch GD.CONFIG ausgeführt.
;Der Kernal beinhaltet standardmäßig
;den Mouse1351-Treiber.
;			t "-G3_LdPrntInpt"		;Drucker-/Eingabetreiber laden.

;*** FBOOT als Anwendung gestartet.
:APP_INSTALL		jsr	SlctGEOSadr		;GEOS-Laufwerksadresse wählen.
			cpx	#NO_ERROR		;Konfiguration speichern?
			bne	:exit			; => Nein, Ende...

			sta	FBootDrive		;Ziel-Laufwerk speichern.

			LoadW	r6,FNamFBOOT
			jsr	FindFile		;FBOOT-Datei suchen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten Programmsektor einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	FBootDrive		;Startlaufwerk.
			sta	diskBlkBuf +2 +OFFSET_DRIVE

			lda	GEOS_RAM_TYP		;GEOS-DACC-Typ.
			sta	diskBlkBuf +2 +OFFSET_RAM +0

			lda	ramExpSize		;GEOS-DACC-Größe.
			sta	diskBlkBuf +2 +OFFSET_RAM +1

			lda	RamBankFirst +0		;GEOS-DACC-Startadresse.
			sta	diskBlkBuf +2 +OFFSET_RAM +2
			lda	RamBankFirst +1
			sta	diskBlkBuf +2 +OFFSET_RAM +3

			jsr	PutBlock		;Programmblock wieder speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	#< Dlg_OK		;Dialogbox "OK".
			ldx	#> Dlg_OK
			bne	:dlgbox

::err			lda	#< Dlg_Error		;Dialogbox "Fehler".
			ldx	#> Dlg_Error

::dlgbox		sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Dialogbox ausgeben.

::exit			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** GEOS-Laufwerksadresse wählen.
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

;*** Dialogbox-Titel löschen.
:DrawDBoxTitel		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$28,$37
			w	$0040,$00ff
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** Laufwerk-Icons "schattieren".
:updDrvColor		LoadW	appMain,setDrvCol	;Farben über MainLoop setzen.
			rts

;--- Hinweis:
;Die Icons werden erst am Ende der
;Dialogbox gezeichnet, daher werden die
;Farben für "Nicht-RAM-Laufwerke" über
;die MainLoop nachträglich gesetzt.
:setDrvCol		ldx	#0
			stx	appMain +0		;appMain-Vektor zurücksetzen.
			stx	appMain +1
::1			lda	RealDrvType,x		;RAM-Laufwerk?
			bmi	:2			; => Ja, weiter...

			txa
			pha

			asl				;Icon-X-Position berechnen.
			clc
			adc	#10
			sta	r5L
			LoadB	r5H,16			;Farben für Nicht-RAM-Laufwerke
			LoadB	r6L,2			;setzen.
			LoadB	r6H,2
			lda	C_InputFieldOff
			sta	r7L

			jsr	RecColorBox		;Laufwerk "schattieren".

			pla
			tax

::2			inx
			cpx	#4
			bcc	:1

			rts

;*** Dialogbox: "GEOS-Laufwerksadresse wählen:"
:Dlg_SlctGEOSadr	b %01100001
			b $28,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$0c,$0b
			w :t1
			b DBTXTSTR ,$0c,$20
			w :t2
			b DBTXTSTR ,$0c,$2a
			w :t3
			b DBTXTSTR ,$0c,$38
			w :t4
			b DBTXTSTR ,$0c,$46
			w :t5
			b DBTXTSTR ,$0c,$50
			w :t6
			b DRIVE    ,$02,$58
			b CANCEL   ,$11,$58
			b DB_USR_ROUT			;Farben für Laufwerk-Icons werden
			w updDrvColor			;über die MainLoop gesetzt!
			b NULL

if LANG = LANG_DE
::t1			b PLAINTEXT,BOLDON
			b "LAUFWERK FÜR GDOS/FASTBOOT"
			b PLAINTEXT,0
::t2			b "Bitte RAM-Laufwerk mit den GDOS64-",NULL
::t3			b "Startdateien für FASTBOOT wählen:",NULL
::t4			b "(Typ RAM1541/1571/1581 oder RAMNM)",NULL
::t5			b "Info: FASTBOOT lädt beim Start die",NULL
::t6			b "GDOS64-Dateien vom RAM-Laufwerk.",NULL
endif
if LANG = LANG_EN
::t1			b PLAINTEXT,BOLDON
			b "DRIVE FOR GDOS/FASTBOOT"
			b PLAINTEXT,0
::t2			b "Please select RAM drive with the",NULL
::t3			b "GDOS64 startup files for FASTOOT:",NULL
::t4			b "(Type RAM1541/1571/1581 or RAMNM)",NULL
::t5			b "Note: FASTBOOT loads the GDOS64",NULL
::t6			b "files from the RAM drive during startup.",NULL
endif

;*** Dialogbox: Konfiguration nicht gespeichert.
:Dlg_Error		b %01100001
			b $28,$87
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR,$10,$0b
			w :1
			b DBTXTSTR,$10,$24
			w :2
			b DBTXTSTR,$10,$30
			w :3
			b CANCEL  ,$11,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "FEHLER!"
			b PLAINTEXT,NULL
::2			b "Die Konfiguration konnte nicht",NULL
::3			b "im Programm gespeichert werden.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "ERROR!"
			b PLAINTEXT,NULL
::2			b "Unable to save configuration",NULL
::3			b "for the program.",NULL
endif

;*** Dialogbox: Konfiguration gespeichert.
:Dlg_OK			b %01100001
			b $28,$87
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR,$10,$0b
			w :1
			b DBTXTSTR,$10,$24
			w :2
			b OK      ,$11,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "INFORMATION"
			b PLAINTEXT,NULL
::2			b "Konfiguration gespeichert.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "INFORMATION"
			b PLAINTEXT,NULL
::2			b "Configuration saved.",NULL
endif

;*** FBOOT initilaisieren.
:FASTBOOT		lda	#%00010101		;%0001xxxx: screenmem is at $0400
			sta	grmemptr		;%xxxx010x: charmem is at $1000

			jsr	CLEAR			;Bildschirm löschen.

			jsr	PrintBootInfo		;Boot-Meldungen ausgeben.

			lda	#$00
			sta	$02
			jsr	SETMSG			;Keine Anzeige von STATUS-Meldungen.

;--- INI-Datei auswerten.
:INIT_GDOS_INI		jsr	LoadConfigDACC		;Speichererweiterung einlesen.

;--- Hinweis:
;Nur Test auf inkompatible GD.INI,
;damit FBOOT auch von einem TC64-SD-
;Laufwerk gestartet werden kann!
			cpx	#INCOMPATIBLE		;Fehler?
			beq	BOOT_ERROR		; => Ja, Abbruch...

;--- BOOT-Vorgang intialisieren.
:INIT_GEOS_BOOT		sei				;IRQ sperren.
			cld				;Dezimal-Flag löschen.
			ldx	#$ff			;Stack-Pointer löschen.
			txs

			MoveW	irqvec,irqvec_buf

			lda	BOOT_DEVICE		;Boot-Laufwerk definiert ?
			bne	:1			; => Ja, weiter...
			lda	curDevice		; => Nein, aktuelles Laufwerk.
::1			cmp	#12			;Vorgabe-Laufwerk gültig ?
			bcs	:2
			cmp	#8
			bcs	:3
::2			lda	#8			; => Nein, Laufwerk #8 setzen...
::3			sta	BOOT_DEVICE		;Aktuelles Laufwerk = Boot-Laufwerk.

			sec
			sbc	#$08
			asl
			tax
			lda	SYS_DISK_DATA +0,x
			sta	SYS_REU_DATA +2
			lda	SYS_DISK_DATA +1,x
			sta	SYS_REU_DATA +3

			jsr	testRAMexp		;GEOS-DACC testen.
			txa				;DACC gefunden ?
			beq	START_GEOS_BOOT		; => Ja, weiter...

;--- Keine Speichererweiterung, Ende...
:BOOT_ERROR		lda	#KRNL_BAS_IO_IN		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA
			cli				;Interrupt freigeben.

			lda	#< bootErrMsg
			ldy	#> bootErrMsg
			jsr	ROM_OUT_STRING		;Fehlermeldung ausgeben.

			jmp	ROM_BASIC_READY		;Zurück zum C64-BASIC.

;--- GEOS-Boot ausführen.
:START_GEOS_BOOT	sei

			lda	#RAM_64K		;I/O-Bereiche einblenden.
			sta	CPU_DATA

			lda	BOOT_RAM_SIZE		;Größe GEOS-DACC initialisieren.
			sta	ramExpSize

			lda	BOOT_RAM_BANK +0	;Adresse erste Speicherbank für
			sta	RamBankFirst  +0	;RAMLink/RAMCard initialisieren.
			lda	BOOT_RAM_BANK +1
			sta	RamBankFirst  +1

			lda	#0
			jsr	doFetchRAM		;Laufwerkstreiber A: einlesen.

			lda	#1
			jsr	doFetchRAM 		;Kernal Teil #1 einlesen.

			lda	#2
			jsr	doFetchRAM 		;Kernal Teil #2 einlesen.

			lda	#3
			jsr	doFetchRAM 		;Kernal Teil #3 einlesen.

			lda	#4
			jsr	doFetchRAM 		;Kernal Teil #4 einlesen.

			LoadW	r0 ,$2000
			LoadW	r1 ,$d000

			ldx	#$30			;Teil #4 liegt im RAM ab
			ldy	#$00			;$D000-$FFFF.
::1			lda	(r0L),y			;Daher kann der Bereich nicht über
			sta	(r1L),y			;FetchRAM eingelesen werden.
			iny
			bne	:1
			inc	r0H
			inc	r1H
			dex
			bne	:1

;--- GEOS-Variablenspeicher löschen.
:CLEAR_GEOS_VAR		LoadW	r0,$8400		;Speicher $8400-$88FF löschen.

			ldx	#$05
			ldy	#$00
			tya
::1			sta	(r0L),y
			iny
			bne	:1
			inc	r0H
			dex
			bne	:1

;--- GEOS-Variablen aus REU einlesen.
			lda	#5
			jsr	doFetchRAM 		;":ramExpSize"

			lda	#6
			jsr	doFetchRAM 		;":year"

			lda	#7
			jsr	doFetchRAM 		;":driveType"

			lda	#8
			jsr	doFetchRAM 		;":ramBase"

			lda	#9
			jsr	doFetchRAM 		;":driveData"

			lda	#10
			jsr	doFetchRAM 		;":PrntFileName"

			lda	#11
			jsr	doFetchRAM 		;":inputDevName"

			lda	#12
			jsr	doFetchRAM 		;":curDrive"

			lda	#13
			jsr	doFetchRAM 		;":sysRAMFlg"

;			lda	#14			;Bei FBOOT nicht erforderlich.
;			jsr	doFetchRAM 		;":spr0pic"

;--- Warteschleife.
;    Dabei wird zuerst der I/O-Bereich eingeblendet und anschließend die
;    Original-IRQ-Routine aktiviert. Diese Routine ist beim C64 zwingend
;    notwendig. Fehlt diese Routine ist ohne ein Laufwerk wie z.B. C=1541
;    ein Start über RBOOT nicht möglich (Fehlerhaftes IRQ-verhalten!)
;    Ist kein Gerät am ser. Bus aktiviert, kann GEOS ohne diese Routine
;    nicht gestartet werden!!!
:Wait			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	cia1tod_t		;Uhrzeit starten.
			sta	cia1tod_t

			MoveW	irqvec_buf,irqvec

			cli				;IRQ aktivieren und warten bis
			lda	cia1tod_t		;IRQ ausgeführt wurde...
::sleep			cmp	cia1tod_t
			beq	:sleep

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			jsr	i_FillRam		;GEOS-DACC Speicherbelegung löschen:
			w	RAM_MAX_SIZE/8*2	;Die Tabelle wird durch den
			w	RamBankInUse		;GD.CONFIG neu erstellt.
			b	$00

			lda	#IO_IN			;I/O-Bereiche einblenden.
			sta	CPU_DATA

			lda	cia1base +15		;I/O-Register initialisieren.
			and	#%01111111
			sta	cia1base +15		;CIA#1/TOD: Alarm-Flag löschen.
			lda	#%10000001
			sta	cia1base +11		;CIA#1/TOD: 1pm
			lda	#$00
			sta	cia1base +10
			sta	cia1base + 9
			sta	cia1base + 8		;CIA#1/TOD: min/sec=0, Uhr starten.

			lda	#RAM_64K		;64K-GEOS-RAM aktivieren.
			sta	CPU_DATA

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

::NEW			lda	#$00
			sta	firstBoot		;GEOS-BootUp.

			jsr	FirstInit		;GEOS initialisieren.

;--- ":mousePicData" nach FirstInit.
;			lda	#15			;Bei FBOOT nicht erforderlich.
;			jsr	doFetchRAM 		;":mousePicData"

			jsr	SCPU_OptOn		;SCPU aktivieren (auch wenn keine
							;SCPU verfügbar ist!)
			jsr	InitMouse		;Mausabfrage starten (nur temporär
							;notwendig, da gewünschter Treiber
							;erst später geladen wird!)

			lda	#$08			;Sektor-Interleave #8.
			sta	interleave

			LoadB	year ,22		;Startdatum setzen.
			LoadB	month,01		;Das Jahrtausendbyte wird in
			LoadB	day  ,01		;":millenium" im Kernal gesetzt.
							;(siehe Kernal/-G3_GD3_VAR)

;--- Laufwerksvariablen initialisieren.
:InitSys_GEOSDDrv	ldy	BOOT_DEVICE		;Startlaufwerk aktivieren.
			sty	curDrive

			lda	#$00			;GEOS-Laufwerkswechsel
			sta	curDevice		;erzwingen.
			sta	sysRAMLink		;RAMLink-Adresse zurücksetzen.

			lda	#$01			;Anzahl Laufwerke zurücksetzen.
			sta	numDrives

			lda	BOOT_DEVICE		;Startlaufwerk aktivieren. Dabei
			jsr	SetDevice		;werden bei der RAMLink auch die
			jsr	OpenDisk		;Laufwerkstreiber-Variablen gesetzt.

;--- Standard-Gerätetreiber laden.
;Wird durch GD.CONFIG ausgeführt.
;Der Kernal beinhaltet standardmäßig
;den Mouse1351-Treiber.
;			jsr	LoadDev_Printer		;Druckertreiber laden.
;			jsr	LoadDev_Mouse		;Eingabetreiber laden.

;--- Maustreiber nach dem laden initialisieren.
			jsr	InitMouse		;Eingabetreiber initialisieren.

;--- EnterDeskTop-Routine zurücksetzen.
;Erforderlich da ein RAM-DeskTop wie
;bei GeoDesk Speicherbänke reserviert
;hat, diese aber nach FBOOT als "Frei"
;initialisiert werden.
;Nach dem FBOOT könnten die Bänke aber
;bereits durch andere Funktionen evtl.
;belegt/überschrieben sein.
;Daher RAM-DeskTop löschen und die
;Standard-Routine installieren.
			jsr	SetADDR_EnterDT		;Zeiger auf Kernal-Routine setzen.

			LoadW	r0,sysEnterDT		;Original-Routine in Speicher
			jsr	StashRAM		;übertragen.

;--- AutoBoot-Programme ausführen.
:AUTO_INSTALL		jsr	i_MoveData		;AutoBoot-Routine kopieren.
			w	AutoBoot_a
			w	BASE_AUTO_BOOT
			w	(AutoBoot_b - AutoBoot_a)

			sei				;System initialisieren.
			cld

			ldx	#$ff			;Stack löschen.
			txs

			jmp	BASE_AUTO_BOOT		;AutoBoot starten.

;*** Kernal-Routine "EnterDeskTop".
:sysEnterDT		d "obj.EnterDeskTop"

;*** Speichererweiterung testen.
:testRAMexp		lda	BOOT_RAM_TYPE		;DACC-Typ einlesen.
			beq	:err			; => Nicht definiert, Fehler...
			cmp	#$ff			;DACC neu wählen?
			beq	:err			; => Ja, nicht möglich, Fehler.
			asl				;RAMLink?
			bcs	:ram_rlnk		; => Ja, weiter...
			asl				;C=REU?
			bcs	:ram_creu		; => Ja, weiter...
			asl				;GeoRAM?
			bcs	:ram_gram		; => Ja, weiter...
			asl				;SuperCPU/RAMCard?
			bcs	:ram_scpu		; => Ja, weiter...

::err			ldx	#DEV_NOT_FOUND
			rts

::ram_scpu		ldx	#0			;SuperCPU.
			b $2c
::ram_gram		ldx	#2			;GeoRAM/BBGRAM.
			b $2c
::ram_creu		ldx	#4			;C=REU.
			b $2c
::ram_rlnk		ldx	#6			;RAMLink.

			lda	tabRAMexp +0,x		;Adresse Testroutine einlesen.
			sta	adrTestDACC +1
			lda	tabRAMexp +1,x
			sta	adrTestDACC +2

			lda	tabRAMop +0,x		;Adresse FetchRAM-Routine einlesen.
			sta	adrFetchRAM +1
			lda	tabRAMop +1,x
			sta	adrFetchRAM +2

:adrTestDACC		jmp	$ffff			;Testroutine starten.

;*** Daten aus GEOS-DACC einlesen.
:doFetchRAM		asl				;Zeiger auf FetchRAM-Daten
			asl				;berechnen.
			asl
			tay
			ldx	#0
::1			lda	SYS_REU_DATA,y		;FetchRAM-Daten nach
			sta	r0,x			;":r0" bis ":r3L".
			iny
			inx
			cpx	#7			;7 Bytes kopiert?
			bcc	:1			; => Nein, weiter...

:adrFetchRAM		jmp	$ffff			;FetchRAM ausführen.

;******************************************************************************
;*** Zusatzroutinen C=REU.
;******************************************************************************
			t "-R3_DetectCREU"
			t "-R3_DoRAMOpCREU"
;******************************************************************************

;*** Speichererweiterung testen.
:TEST_DACC_CREU		= DetectCREU			;Speichererweiterung testen.

;*** FetchRAM-Routine für ReBoot.
:FetchRAM_CREU		php
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_CREU
			tay

			pla
			sta	CPU_DATA		;I/O deaktivieren.

			tya
			plp
			rts

;******************************************************************************
;*** Zusatzroutinen GeoRAM/BBGRAM.
;******************************************************************************
			t "-R3_DetectGRAM"
			t "-R3_DoRAMOpGRAM"
			t "-R3_GetSBnkGRAM"

;--- Größe der Speicherbänke in der GeoRAM 16/32/64Kb.
;Dieser Variablenspeicher muss im Hauptprogramm an einer Stelle
;definiert werden, der nicht durch das nachladen weiterer Programmteile
;überschrieben wird!
:GRAM_BANK_SIZE		b $00
;******************************************************************************

;*** Speichererweiterung testen.
:TEST_DACC_GRAM		jsr	DetectGRAM		;Speichererweiterung testen.
			txa				;BBGRAM installiert ?
			bne	:no_gram		; => Nein, Abbruch...

			php
			sei				;Interrupt sperren.

			jsr	GRamGetBankSize		;Bank-Größe für GeoRAM ermitteln.

			plp				;IRQ-Status zurücksetzen.

			txa				;Speicherfehler?
			bne	:no_gram

			ldx	#NO_ERROR		;ReBoot initialisieren.
			rts

::no_gram		ldx	#DEV_NOT_FOUND
			rts

;*** FetchRAM-BBG-Routine für ReBoot.
:FetchRAM_GRAM		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	GRAM_BANK_SIZE
			ldy	#%10010001		;JobCode "FetchRAM".
			jsr	DoRAMOp_GRAM
			tay

			pla
			sta	CPU_DATA		;I/O deaktivieren.

			tya
			plp
			rts

;******************************************************************************
;*** Zusatzroutinen SuperCPU/RAMCard.
;******************************************************************************
			t "-R3_DetectSCPU"
			t "-R3_DoRAMOpSRAM"
			t "-R3_SRAM16Bit"
;******************************************************************************

;*** Speichererweiterung testen.
:TEST_DACC_SCPU = DetectSCPU;Speichererweiterung testen.

;*** FetchRAM-Routine für ReBoot.
:FetchRAM_SCPU		sei
			php

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#%10010001		;JobCode "FetchRAM".
			lda	RamBankFirst +1		; -> RamBankFirst +1
			jsr	DoRAMOp_SRAM		;Job ausführen.

			pla
			sta	CPU_DATA

			tya
			plp				;I/O deaktivieren.
			rts

;******************************************************************************
;*** Zusatzroutinen RAMLink.
;******************************************************************************
			t "-R3_DetectRLNK"
;******************************************************************************

;*** Speichererweiterung testen.
:TEST_DACC_RLNK = DetectRLNK;Speichererweiterung testen.

;*** FetchRAM-Routine für ReBoot.
:FetchRAM_RLNK		php
			sei

			lda	CPU_DATA
			pha
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			jsr	EN_SET_REC		;RL-Hardware aktivieren.

			lda	r0L			;Computer Address Pointer.
			sta	EXP_BASE2 + 2
			lda	r0H
			sta	EXP_BASE2 + 3

			lda	r1L			;RAMLink System Address Pointer.
			sta	EXP_BASE2 + 4
			lda	r1H
			clc				;Start-Adresse der Partition
			adc	RamBankFirst +0		;zu RAMCard-Adresse addieren.
			sta	EXP_BASE2 + 5
			lda	r3L
			adc	RamBankFirst +1
			sta	EXP_BASE2 + 6

			lda	r2L			;Transfer Length.
			sta	EXP_BASE2 + 7
			lda	r2H
			sta	EXP_BASE2 + 8

			lda	#$00
;			sta	EXP_BASE2 + 9		;Not used.
			sta	EXP_BASE2 +10		;Address Control.

			lda	#$91			;Job-Code.
			sta	EXP_BASE2 + 1

			jsr	EXEC_REC_REU		;Job ausführen und
			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			pla
			sta	CPU_DATA		;I/O-Bereich deaktivieren.

			ldy	#%01000000		;Job-Status.
			plp				;Interrupt zurücksetzen.
			rts

;*** Dateinamen.
:FNamGDINI		b "GD.INI",NULL
:FNamFBOOT		b "GD.FBOOT",NULL
:FBootDrive		b $00

;*** Zwischenspeicher IRQ-Vektor.
:irqvec_buf		w $0000				;Zwischenspeicher IRQ-Routine.

;*** Routinen für Hardware-Test.
:tabRAMexp		w TEST_DACC_SCPU
			w TEST_DACC_GRAM
			w TEST_DACC_CREU
			w TEST_DACC_RLNK

;*** Routinen für DoRAMOp.
:tabRAMop		w FetchRAM_SCPU
			w FetchRAM_GRAM
			w FetchRAM_CREU
			w FetchRAM_RLNK

;*** Speicherbelegung GEOS-DACC.
:SYS_DISK_DATA		w $8300 +(DISK_DRIVER_SIZE *0)
			w $8300 +(DISK_DRIVER_SIZE *1)
			w $8300 +(DISK_DRIVER_SIZE *2)
			w $8300 +(DISK_DRIVER_SIZE *3)

:SYS_REU_DATA		w DISK_BASE   , $8300              , $0d80, $0000
			w $9d80       , $b900              , $0280, $0000
			w $bf40       , $bb80              , $00c0, $0000
			w $c000       , $bc40              , $1000, $0000
			w $2000       , $cc40              , $3000, $0000

			w ramExpSize  , ramExpSize   -$0b00, $0001, $0000
			w year        , year         -$0b00, $0003, $0000
			w driveType   , driveType    -$0b00, $0004, $0000
			w ramBase     , ramBase      -$0b00, $0004, $0000
			w driveData   , driveData    -$0b00, $0004, $0000
			w PrntFileName, PrntFileName -$0b00, $0011, $0000
			w inputDevName, inputDevName -$0b00, $0011, $0000
			w curDrive    , curDrive     -$0b00, $0001, $0000
			w sysRAMFlg   , sysRAMFlg    -$0b00, $0001, $0000

;--- Wird bei FBOOT nicht benötigt:
;SPRITE_PIC wird beim ersten Aufruf von
;":InitMouseData" / ":xInterruptMain"
;initialisiert.
;mousePicData wird durch ":FirstInit"
;aus mouseSysData initialisiert.
;			w SPRITE_PICS , $fc40              , $003f, $0000
;			w mousePicData, $fc40              , $003f, $0000

;*** Startmeldung.
			t "-G3_GetPAL_NTSC"
			t "-G3_PrntBootInf"
			t "-G3_PrntCoreInf"

;*** Fehlermeldung.
:bootErrMsg		b $93
			b CR
if LANG = LANG_DE
			b "FEHLER!",CR
endif
if LANG = LANG_EN
			b "ERROR!",CR
endif
			b CR
if LANG = LANG_DE
			b "SPEICHERERWEITERUNG NICHT ERKANNT.",CR
			b "GEOS-START ABGEBROCHEN...",CR
endif
if LANG = LANG_EN
			b "RAM-EXPANSION-UNIT NOT DETECTED.",CR
			b "BOOTING GEOS CANCELLED...",CR
endif
			b CR
			b NULL

;*** AutoStart-Programm.
:AutoBoot_a		d "obj.GD.AUTOBOOT"
:AutoBoot_b
