; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk für Fenster wechseln.
.NewDriveCurWinA	ldx	#$00
			b $2c
.NewDriveCurWinB	ldx	#$01
			b $2c
.NewDriveCurWinC	ldx	#$02
			b $2c
.NewDriveCurWinD	ldx	#$03

			lda	WM_WCODE		;Aktuelles Fenster einlesen.
			cmp	WM_MYCOMP		;Fenster = Arbeitsplatz?
			bne	:1			; => Nein, weiter...

			jsr	MYCOMP_DRVCURWIN	;Laufwerk im Arbeitsplatz öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			rts

::1			jsr	MYCOMP_DRVOPEN		;Laufwerksfenster öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			rts

::error			jmp	doXRegStatus		;Fehler: "Keine Disk im Laufwerk!".

;*** Laufwerk aus Arbeitsplatz öffnen.
:MYCOMP_DRVENTRY	ldx	MyCompEntry

;*** Neue Laufwerks-Ansicht in "MyComputer" öffnen.
;    Übergabe: XReg/LOW und YReg/HIGH = Zähler für
;              Eintrag in MyComputer.
;Im Unterschied zu :MYCOMP_DRVNEWWIN
;wird hier bei Native immer das Haupt-
;Verzeichnis geöffnet.
;Hier muss auch kein leeres Fenster
;gesucht werden da "MyComputer" dazu
;wiederverwendet wird.
:MYCOMP_DRVCURWIN	txa
			pha
			ldx	WM_MYCOMP		;Fenster-Nr. einlesen.
			jsr	defViewMode		;Standardansicht festlegen.
			pla
			tax
			lda	WM_MYCOMP		;Fenster-Nr. für "MyComputer".
			jsr	MYCOMP_DRVOPEN		;Laufwerk öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...
			sta	WM_MYCOMP		;Arbeitsplatz schließen.
::exit			rts

;*** Laufwerk in Arbeitsplatz öffnen.
:MYCOMP_DRVOPEN		sta	:tmpwin			;Fenster-Nr. speichern.

			cpx	#$04			;Laufwerk ausgewählt?
			bcs	:error			; => Nein, Abbruch...

			txa				;Laufwerksadresse speichern.
			pha

			lda	:tmpwin			;Fenster-Nr. einlesen.
			jsr	WM_WIN2TOP		;Fenster nach oben holen.

			pla				;Laufwerksadresse.
			ldx	:tmpwin			;Fenster-Nr.
			ldy	#$ff			;NativeMode: Nicht zu ROOT wechseln.
			jsr	MYCOMP_DRVINIT		;Laufwerksfenster initialisieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	WM_LOAD_WIN_DATA	;Fenster-Daten laden.

			ldy	#$01			;Fenster-Größe von "MyComputer"
::1			lda	WM_DATA_BUF,y		;für neues Laufwerksfenster
			sta	WIN_FILES,y		;kopieren.
			iny
			cpy	#$07
			bcc	:1

			lda	#< WIN_FILES		;Zeiger auf Fenster-Daten.
			sta	r0L
			lda	#> WIN_FILES
			sta	r0H

			lda	#GEXT_WINFILES		;Fenster-Modus: Dateifenster.
			sta	WIN_FILES + (WM_DATA_OPTIONS - WM_DATA_BUF)

			lda	:tmpwin			;Fenster-Nr. einlesen und
			jsr	WM_USER_WINDOW		;Fenster erneut öffnen.

			jsr	clrStdWinSize		;Standard-Fenstergröße zurücksetzen.

			ldx	#NO_ERROR
::error			rts

;*** Temp. Zwischenspeicher für Fenster-Nr.
::tmpwin		b $00

;*** Neue Laufwerks-Ansicht öffnen,
;    Fenster-Optionen sind bereits
;    initialisiert => Nicht löschen.
;    Übergabe: XReg/LOW und YReg/HIGH = Zähler für
;              Eintrag in MyComputer.
:MYCOMP_DRVUSRWIN	lda	#$ff			;Flag setzen: WMODE-Daten
			b $2c				;nicht löschen.

;*** Neue Laufwerks-Ansicht öffnen.
;    Übergabe: XReg/LOW und YReg/HIGH = Zähler für
;              Eintrag in MyComputer.
:MYCOMP_DRVNEWWIN	lda	#$00			;Flag setzen: WMODE-Daten löschen.
			sta	:tmpinit		;WMODE-Flag speichern.

			cpx	#$04			;Eintrag = Laufwerk?
			bcs	:error			; => Nein, Abbruch...

			txa
			pha
			jsr	WM_IS_WIN_FREE		;Leeres Fenster suchen.
			sta	:tmpwin
			pla
			cpx	#NO_ERROR		;Fenster gefunden?
			bne	:error			; => Nein, Abbruch...

;			lda	curDrive		;Laufwerksadresse.
;			sec
;			sbc	#$08
			ldx	:tmpwin			;Fenster-Nr.
			ldy	#$00			;NativeMode: Nicht zu ROOT wechseln.
			jsr	MYCOMP_DRVINIT		;Laufwerksfenster initialisieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			ldx	:tmpinit
			bne	:1
			ldx	:tmpwin			;Fenster-Nr. einlesen.
			jsr	WM_CLR_WINSYSDAT
			jsr	defViewMode		;Standardansicht festlegen.

::1			lda	#< WIN_FILES		;Zeiger auf Fenster-Daten.
			sta	r0L
			lda	#> WIN_FILES
			sta	r0H

			lda	#$ff			;Fenster-Optionen nicht löschen.
			sta	r1L

			lda	#GEXT_WINFILES		;Fenster-Modus: Dateifenster.
			sta	WIN_FILES + (WM_DATA_OPTIONS - WM_DATA_BUF)

			jsr	WM_OPEN_WINDOW		;Neues Fenster öffnen.

			ldx	#NO_ERROR
::error			rts				;Abbruch: "Fenster nicht geöffnet!"

::tmpwin		b $00
::tmpinit		b $00

;*** Laufwerksfenster initialisieren.
;    Übergabe: AKKU = Laufwerk A:-D: (= 0-3).
;              XREG = Fenster-Nr.
;              YREG = $FF = NativeMode/ROOT öffnen.
:MYCOMP_DRVINIT		stx	:tmpwin			;Fenster-Nr. speichern.
			sty	:tmpopenroot

			clc
			adc	#$08
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch.

;--- Hinweis:
;Beim öffnen eines neues Fenster kann
;WIN_DATAMODE bereits im Vorfeld auf
;$80/$40=Partitions-/DiskImage-Auswahl
;gesetzt worden sein. In diesem Fall
;weiter zum öffnen des Fensters.
			ldx	:tmpwin
			lda	WIN_DATAMODE,x		;Partitionsmodus gesetzt?
			bne	:3			; => Ja, weiter...

;--- Arbeitsplatz -> ROOT öffnen.
			bit	:tmpopenroot
			bpl	:1

			ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Laufwerk?
			beq	:1 			; => Nein, weiter...

;--- Bei Native ROOT öffnen.
			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			txa				;Fehler?
			beq	:3			; => Nein, dann Fenster öffnen.
			bne	:2			; => Ja, Abbruch...

;Wenn Partitions-/DiskImage-Auswahl
;nicht aktiv, dann Disk öffnen.
;Beim Öffnen über Rechtsklick auf
;Arbeitsplatz wurde dabei zuvor bereits
;das Hauptverzeichnis aktiviert.
::1			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			beq	:3			; => Nein, weiter...

;--- Fehler beim öffnen des Mediums.
::2			ldx	:tmpwin			;Fenster-Nr. einlesen.
			jsr	testErrSD2IEC		;SD2IEC-Laufwerk?
			beq	:error			; => Nein, Fehler...

;--- Fenster öffnen.
::3			ldx	:tmpwin			;Laufwerksdaten für
			jsr	SaveUserWinDrive	;neues Fenster speichern.

			jsr	SET_LOAD_DISK		;Dateien von Disk neu einlesen.

::ok			ldx	#NO_ERROR
			rts

::error			ldx	#NO_SYNC		;Keine SYNC-Markierung/Keine Disk.
			rts

::tmpwin		b $00
::tmpopenroot		b $00

;*** Bei DiskFehler auf SD2IEC testen.
;    Übergabe: XReg = Fenster-Nr.
;    Rückgabe: Z-Flag = 1 => Kein SD2IEC.
;Evtl. befindet sich das Laufwerk nicht
;in einem DiskImage => DiskImage-Browser starten.
:testErrSD2IEC		ldy	curDrive
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;Typ SD2IEC?
			beq	:1			; => Nein, weiter...
			lda	#%0100 0000		;Browser-Modus setzen.
::1			sta	WIN_DATAMODE,x		;Disk oder Browser-Modus setzen.
			rts

;*** Standard-Fenstergröße zurücksetzen.
;Wird auch von ":testDWinMode" im
;Zwei-Fenster-Modus verwendet.
:clrStdWinSize		ldy	#$07			;Standard-Fenstergröße löschen.
			lda	#$00
::1			sta	WIN_FILES,y
			dey
			bne	:1

			rts

;*** Standardansicht für Fenster setzen.
;    Übergabe: XReg = Fenster-Nr.
:defViewMode		lda	GD_STD_SORTMODE		;Standard-Sortiermodus einlesen.
			sta	WMODE_SORT,x		;Sortierung für Fenster.
			lda	GD_STD_VIEWMODE		;Standard-Anzeigemodus einlesen.
			sta	WMODE_VICON,x		;Icons/Text anzeigen.
			lda	GD_STD_TEXTMODE		;Standard-Textmodus einlesen.
			sta	WMODE_VINFO,x		;Text/Details anzeigen.
			lda	GD_STD_SIZEMODE		;Standard-Größenmodus einlesen.
			sta	WMODE_VSIZE,x		;Blocks/KBytes anzeigen.
			rts

;*** Laufwerksdaten in Fenster-Daten speichern.
:SaveWinDrive		ldx	WM_WCODE		;Aktuelles Fenster einlesen.
:SaveUserWinDrive	stx	:win			;Fenster-Nr. speichern.

			lda	curDrive		;Aktuelles Laufwerk einlesen.
			sta	WIN_DRIVE,x		;Laufwerk speichern.

			tay
			lda	RealDrvType-8,y		;Laufwerkmodus einlesen und
			sta	WIN_REALTYPE,x		;in Fensterdaten speichern.

			jsr	Sys_GetDrv_Part		;Ggf. Partitionsdaten einlesen und
			ldy	:win			;speichern (nicht-CMD = $00).
			sta	WIN_PART,y

			jsr	Sys_GetDrv_SDir		;Ggf. Verzeichnisdaten einlesen und
			ldy	:win			;speichern (nicht-Native = $00).
			sta	WIN_SDIR_T,y		;Verzeichnis-Daten speichern.
			txa
			sta	WIN_SDIR_S,y

			rts

::win			b $00

;*** Aktuelles Fenster schließen.
:EXIT_WIN		ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	#%00000000		;Partitions-Modus für aktuelles
			sta	WIN_DATAMODE,x		;Fenster zurücksetzen.

;--- Ergänzung: 09.05.21/M.Kanet
;Wenn ein Fenster geschlossen wird,
;dann sind die Daten im RAM ungültig.
;Daher muss hier ":getFileWin" gelöscht
;werden um dann die Verzeichnisdaten
;für das neue Fenster einzulesen.
;			lda	#$00			;Verzeichnisdaten für das
			sta	getFileWin		;nächste Fenster neu einlesen.

			rts

;*** Laufwerks-Fenster: Disk-Namen anzeigen.
;    Übergabe: r1H = Zeile (Pixel).
;              r11 = Spalte (Pixel).
:PrntCurDkName		ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	WIN_DATAMODE,x		;Standard-Fenster-Modus?
			beq	:1			; => Ja, weiter...
			bmi	:part

::dimage		lda	#<:txDSlct		; => SD2IEC-DiskImages...
			ldx	#>:txDSlct
			jmp	:create_title

::part			lda	#<:txPSlct		; => SD2IEC-DiskImages...
			ldx	#>:txPSlct
			jmp	:create_title

;--- Standard-Diskname ausgeben.
::1			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode-8,y		;CMD-Laufwerk?
			and	#SET_MODE_PARTITION
			beq	:2			; => Nein, weiter...

			lda	drivePartData-8,y	;Partitions-Nr. einlesen.

::2			ldy	#"0"			;Partitions-Nr. nach
			ldx	#"0"			;ASCII wandeln.
::3			cmp	#100
			bcc	:4
			sbc	#100
			iny
			bne	:3
::4			cmp	#10
			bcc	:5
			sbc	#10
			inx
			bne	:4
::5			adc	#"0"
			sty	:txDkNam +2		;ASCII-Wert der Partition
			stx	:txDkNam +3		;in die Titel-Zeile schreiben.
			sta	:txDkNam +4		;000 = Kein CMD-Laufwerk.

;--- Diskname kopieren.
			ldx	#r0L			;Zeiger auf Disknamen setzen.
			jsr	GetPtrCurDkNm

			LoadW	r4,:txDkNam +6		;Zeiger auf Titelzeile.

			ldx	#r0L			;Diskname aus BAM in Titelzeile
			ldy	#r4L			;kopieren.
			jsr	SysCopyName

			lda	#<:txDkNam
			ldx	#>:txDkNam
			jsr	:create_title

;--- Verzeichnis-Position ausgeben.
			ldx	WM_WCODE		;Verzeichnis-Anfang?
			lda	WIN_DIR_NR,x
			beq	:exit			; => Ja, keine Position ausgeben.

			LoadW	r0,:txFPos		;Text "Position:" ausgeben.
			jsr	PutString

			ldx	WM_WCODE		;Aktuelle Position einlesen und
			lda	WIN_DIR_NR,x		;ausgeben.
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#%11000000
			jmp	PutDecimal
::exit			rts

;--- Fenster-Titel mit Laufwerk ausgeben.
::create_title		sta	r0L			;Zeiger auf Titelzeile.
			stx	r0H

			lda	curDrive		;Laufwerks-Adresse einlesen.
			tax
			clc
			adc	#"A" -8			;Laufwerk nach ASCII wandeln und
			ldy	#$00			;in Titelzeile schreiben.
			sta	(r0L),y

;--- HINWEIS:
;":smallPutString" verwenden um bei
;Disknamen Steuerzeichen zu filtern.
			jmp	smallPutString		;Titelzeile ausgeben.

::txDkNam		b $00				;Laufwerk.
			b "/"
			b "000"				;Partition.
			b ":"
			s 17				;Disk-/Verzeichnis-Name.

if LANG = LANG_DE
::txPSlct		b $00
			b ": PARTITION WÄHLEN"
			b NULL
::txDSlct		b $00
			b ": DISKIMAGE WÄHLEN"
			b NULL
endif
if LANG = LANG_EN
::txPSlct		b $00
			b ": SELECT PARTITION"
			b NULL
::txDSlct		b $00
			b ": SELECT DISK IMAGE"
			b NULL
endif

::txFPos		b " / P:",NULL

;*** Laufwerks-Fenster: Disk-Namen anzeigen.
:PrntCurDkInfo		ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	WIN_DATAMODE,x		;Standard-Fenster-Modus?
			beq	:1			; => Ja, weiter...

;--- Partitions-/DiskImage-Auswahl.
			lda	curType			;Laufwerksmodus einlesen.
			and	#ST_DMODES
			asl
			tax
			lda	:dMode +0,x		;Laufwerkstyp einlesen und
			sta	:pMode +0		;in Statuszeile kopieren.
			lda	:dMode +1,x
			sta	:pMode +1

			LoadW	r0,:pInfo		;Modus ausgeben.
			jsr	PutString

;--- Anzahl Dateien/Partitionen ausgeben.
::prnt_file_count	lda	WM_DATA_MAXENTRY
			sta	r0L
			lda	#$00
			sta	r0H

			lda	#%11000000		;Anzahl Einträge ausgeben.
			jmp	PutDecimal		;Dateien oder Partitionen.

;--- Standard-Dateifenster.
::1			jsr	:prnt_file_count	;Anzahl Dateien ausgeben.

			ldx	WM_DATA_MAXENTRY
			beq	:2
			dex
			bne	:2

			ldx	#10			;"Datei"
			b $2c
::2			ldx	#8			;"Dateien"
			jsr	:prnt_strg

			PushB	r1H			;Y-Koordinate Textausgabe sichern.

;--- Hinweis:
;Evtl. ist ":WM_OPEN_DRIVE" hier nicht
;erforderlich, da Diskette bereits
;geöffnet.
;			jsr	WM_OPEN_DRIVE		;Laufwerk öffnen.
;			txa				;Fehler?
;			bne	:3			; => Ja, Speicherwete löschen.

;--- Hinweis:
;Evtl. ist ":GetDirHead" hier nicht
;erforderlich, da Diskette bereits
;geöffnet.
;			jsr	GetDirHead		;BAM einlesen.
;			txa				;Fehler?
;			beq	:4			; => Nein, weiter...
::skip_open_disk	jmp	:4			;Diskette bereits geöffnet...

::3			lda	#$00			;Diskfehler, Speicherwerte löschen.
			sta	r3L
			sta	r3H
			sta	r4L
			sta	r4H
			beq	:5

::4			LoadW	r5,curDirHead		;Zeiger auf aktuelle BAM.
			jsr	CalcBlksFree		;Freie Blöcke ermitteln.

::5			ldx	WM_WCODE
			lda	WMODE_VSIZE,x		;Blocks oder KByte?
			beq	:6			; => Blocks, weiter...

			lsr	r3H			;Max. Anzahl Blocks in
			ror	r3L			;KByte umrechnen.
			lsr	r3H
			ror	r3L

			lsr	r4H			;Anzahl freie Blocks in
			ror	r4L			;KByte umrechnen.
			lsr	r4H
			ror	r4L

::6			PopB	r1H			;Y-Koordinate zurücksetzen.

			PushB	r3H
			PushB	r3L

;--- Speicher frei ausgeben.
			lda	r4H			;Anzahl freie Blocks für die
			sta	r0H			;Berechnung der belegten Blocks
			pha				;speichern und für die Ausgabe
			lda	r4L			;vorbereiten.
			sta	r0L
			pha

			lda	#%11000000		;Freie Blocks ausgeben.
			jsr	PutDecimal

			ldx	WM_WCODE
			lda	WMODE_VSIZE,x		;Blocks oder KByte?
			bpl	:8			; => Blocks, weiter...
::7			ldx	#0
			b $2c
::8			ldx	#4
			jsr	:prnt_strg		;"frei" ausgeben.

;--- Speicher belegt.
			PopW	r4			;Freie Blocks zurücksetzen.

			pla				;Belegten Speicher berechnen.
			sec
			sbc	r4L
			sta	r0L
			pla
			sbc	r4H
			sta	r0H
			lda	#%11000000		;Belegten Speicher ausgeben.
			jsr	PutDecimal

			ldx	WM_WCODE
			lda	WMODE_VSIZE,x		;Blocks oder KByte?
			bpl	:10			; => Blocks, weiter...
::9			ldx	#2			;KByte belegt ausgeben.
			b $2c
::10			ldx	#6			;Blocks belegt ausgeben.
			jsr	:prnt_strg

			lda	rightMargin +0		;Position für Textausgabe
			clc				;der GEOS-Kennung setzen.
			adc	#< $0001
			sta	r11L
			lda	rightMargin +1
			adc	#> $0001
			sta	r11H

			LoadW	rightMargin,319		;Textgrenzen zurücksetzen.

			bit	isGEOS			;GEOS-Diskette?
			bpl	:11			; => Nein, Ende...

			lda	#"*"			;GEOS-Diskette markieren.
			b $2c
::11			lda	#"-"			;Nicht-GEOS-Diskette markieren.
			jsr	SmallPutChar

			rts

;--- Kb/Blocks frei/belegt, Anzahl Dateien.
::prnt_strg		lda	:tx_adr +0,x		;Textmeldung ausgeben.
			sta	r0L
			lda	:tx_adr +1,x
			sta	r0H
			jmp	PutString

;--- Texte für Statuszeile.
::tx_adr		w :t0,:t1,:t2
			w :t3,:t4,:t5

if LANG = LANG_DE
::t0			b " Kb frei, ",NULL
::t1			b " Kb belegt ",NULL
::t2			b " Blks frei, ",NULL
::t3			b " Blks belegt ",NULL
::t4			b " Dateien, ",NULL
::t5			b " Datei, ",NULL
endif
if LANG = LANG_EN
::t0			b " Kb free, ",NULL
::t1			b " Kb used ",NULL
::t2			b " Blks free, ",NULL
::t3			b " Blks used ",NULL
::t4			b " Files, ",NULL
::t5			b " File, ",NULL
endif

;--- Status-Zeile für Partitionen/DiskImages.
if LANG = LANG_DE
::pInfo			b "Modus: "
endif
if LANG = LANG_EN
::pInfo			b "Mode: "
endif
::pMode			b "??"
			b "/"
			b NULL

::dMode			b "? 417181NM? ? ? "
