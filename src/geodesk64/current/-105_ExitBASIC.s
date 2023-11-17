; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Nach GEOS beenden.
:ExitGEOS		jsr	WM_CLOSE_ALL_WIN	;Alle Fenster schließen.

			jsr	SetADDR_EnterDT		;Original EnterDeskTop-Routine
			lda	#$00			;aus dem Speicher holen und
			sta	r1L			;wieder im System installieren.
			sta	r1H
			lda	GD_RAM_GDESK1		;Zeiger auf GeoDesk-Speicherbank #1.
			sta	r3L
			jsr	FetchRAM
			jsr	SetADDR_EnterDT
			jsr	StashRAM

			ldy	GD_SCRN_STACK		;Reservierten Speicher freiegeben.
			jsr	FreeBank
			ldy	GD_SYSDATA_BUF
			jsr	FreeBank

			ldy	GD_RAM_GDESK1		;GeoDesk/Speicherbank #1 belegt?
			beq	:1			; => Nein, weiter...
			jsr	FreeBank		;Speicher freigeben.

::1			ldy	GD_RAM_GDESK2		;GeoDesk/Speicherbank #2 belegt?
			beq	:2			; => Nein, weiter...
			jsr	FreeBank		;Speicher freigeben.

::2			ldy	GD_ICONDATA_BUF		;Icon-Cache aktiv?
			beq	:3			; => Nein, weiter...
			jsr	FreeBank		;Speicher freigeben.

::3			jmp	EnterDeskTop		;Zurück zu GEOS.

;*** Nach BASIC beenden.
:NoBASIC		b NULL
:ExitBASIC		LoadW	r0,Dlg_ExitBasic
			jsr	DoDlgBox

			lda	sysDBData		;GEOS wirklich beenden?
			cmp	#YES			;"Ja" ?
			beq	:exit			; => Nein, Abbruch...
			jmp	MOD_RESTART		;Menü/FensterManager neu starten.

::exit			LoadW	r0,NoBASIC

;*** Nach BASIC verlassen und Befehl ausführen.
;    Übergabe: r0 = Zeiger auf Befehl.
:ExitBASIC_NoLoad	lda	#$00			;Kein Programm laden.
			sta	r5L
			sta	r5H

			sta	$0800			;Kein Programm starten.
			sta	$0801
			sta	$0802
			sta	$0803
			LoadW	r7,$0803

			jmp	ToBasic			;Nach BASIC beenden.

;*** Dialogboxen.
:Dlg_ExitBasic		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "GEOS wirklich beenden und",NULL
::3			b "den BASIC-Modus starten?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Do you really want to quit",NULL
::3			b "GEOS and start BASIC mode?",NULL
endif

;*** BASIC-Programm starten.
:ExitBAppl		lda	#NOT_GEOS		;Dateityp "BASIC/Nicht GEOS".
			sta	r7L

			lda	#$00			;Keine GEOS-Klasse.
			sta	r10L
			sta	r10H

			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			beq	:openfile
::exit			jmp	MOD_RESTART		;Menü/FensterManager neu starten.

::openfile		LoadW	r6,dataFileName
:ExitBApplRUN		jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- Ladeadresse prüfen.
			lda	dirEntryBuf+1		;Zeiger auf ersten Datenblock.
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Ersten Datenblock einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	diskBlkBuf+2		;Laeadresse = $0801?
			cmp	#$01
			bne	:ask_load_abs		; => Nein, Absolut laden?
			lda	diskBlkBuf+3
			cmp	#$08
			beq	:load_std		; => Ja, weiter...

::ask_load_abs		ldx	curDrive		;Bei RAM-Laufwerk kein absolutes
			lda	RealDrvType -8,x	;laden mit ",dev,1" möglich.
			bpl	:0			; => Kein RAM-Laufwerk, weiter.

			LoadW	r0,Dlg_LoadAbsRAM	;Fragen ob von RAM normal geladen
			jsr	DoDlgBox		;werden soll...

			lda	sysDBData
			cmp	#YES			;"Ja" ?
			beq	:load_std		; => Normal laden.
			bne	:cancel			;Abbruch.

::0			LoadW	r0,Dlg_LoadAbs		;Fragen ob Absolut geladen
			jsr	DoDlgBox		;werden soll...

			lda	sysDBData
			cmp	#NO
			beq	:load_std		; => Nein, normal laden/starten.
			cmp	#YES
			beq	:load_abs		; => Ja, absolut laden.
::cancel		jmp	MOD_RESTART		;Menü/FensterManager neu starten.

;--- Programm normal laden/starten.
::load_std		LoadW	r0,:RunBASIC		;"RUN"-Befehl.
			LoadW	r5,dirEntryBuf		;Zeiger auf Verzeichnis-Eintrag.
			LoadW	r7,$0801		;Ladeadresse.

			jmp	ToBasic			;Nach BASIC beenden.

::exit			lda	#<dataFileName		;Zeiger auf Dateiname für
			sta	errDrvInfoF +0		;"FILE_NOT_FOUND"-Fehler.
			lda	#>dataFileName
			sta	errDrvInfoF +1
			jmp	OpenDiskError		;Fehlermeldung ausgeben.

;--- Programm absolut laden/manuell starten.
::load_abs		LoadW	r0,dirEntryBuf -2	;Dateiname in LOAD-Befehl kopieren.
			LoadW	r1,:FileNameBuf
			ldx	#r0L
			ldy	#r1L
			jsr	SysCopyFName

			ldy	#$00
::2			lda	(r1L),y			;Ende Dateiname suchen.
			beq	:3
			iny
			cpy	#$10
			bne	:2

::3			lda	#$22			;",dev,1" an den Dateinamen
			sta	(r1L),y			;anhängen.
			iny
			lda	#$2c			;","
			sta	(r1L),y
			iny

			ldx	curDrive		;Laufwerk 8,9,10,11 in
			lda	:driveAdr1 -8,x		;Befehl eintragen.
			beq	:4
			sta	(r1L),y
			iny
::4			lda	:driveAdr2 -8,x
			sta	(r1L),y
			iny

			lda	#$2c			;","
			sta	(r1L),y
			iny
			lda	#"1"			;"1"
			sta	(r1L),y
			iny
			lda	#NULL			;Befehlsende.
			sta	(r1L),y

			LoadW	r0,:LoadBASIC		;"LOAD"-Befehl.
			jmp	ExitBASIC_NoLoad	;Nach BASIC beenden.

::RunBASIC		b "RUN",NULL
::LoadBASIC		b "LOAD",$22
::FileNameBuf		s 17
			b $22,",8,1",NULL
::driveAdr1		b NULL,NULL,"1","1"
::driveAdr2		b "8" ,"9" ,"0","1"

;*** Dialogboxen.
:Dlg_LoadAbs		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3c
			w :4
			b YES        ,$01,$50
			b NO         ,$08,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Programm verwendet nicht",NULL
::3			b "die Standard-Ladeadresse.",NULL
::4			b "Absolut mit `,x,1` laden?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The program does not use the",NULL
::3			b "default load address.",NULL
::4			b "Load absolut with `,x,1` ?",NULL
endif

;*** Dialogboxen.
:Dlg_LoadAbsRAM		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$1c
			w :2
			b DBTXTSTR   ,$0c,$28
			w :3
			b DBTXTSTR   ,$0c,$38
			w :4
			b DBTXTSTR   ,$0c,$44
			w :5
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Programm verwendet nicht",NULL
::3			b "die Standard-Ladeadresse.",NULL
::4			b "Absolutes Laden nicht unterstützt.",NULL
::5			b "Von RAM-Laufwerk laden/starten?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The program does not use the",NULL
::3			b "default load address.",NULL
::4			b "Absolute loading is not supported.",NULL
::5			b "Load and run from RAM drive?",NULL
endif
