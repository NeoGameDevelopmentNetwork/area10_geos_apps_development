; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#106.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	RunBASIC

;*** BASIC-Programm laden/starten.
;--- Ergänzung: 24.04.19/M.Kanet
;Bis MegaPatch V3.3r4 war die ToBASIC
;Routine nicht voll funktionsfähig.
;Mit V3.3r5 funktioniert das nachladen
;von BASIC-Dateien wieder problemlos.
;Routine C64BootFile durch Code aus
;GeoDesk64 ersetzt...
:RunBASIC		jsr	LookForFiles		;Dateien suchen.
			jsr	ConvertFNames

			lda	#<GetFileTab
			ldx	#>GetFileTab
			jsr	SelectBox		;Dateiauswahlbox.

			lda	r13L			;Datei ausgewählt?
			beq	:103			; => Ja, weiter...
			cmp	#$80			;Abbruch gewählt?
			bcc	:102			; => Ja, Ende...
			cmp	#$90			;artition wechweln?
			beq	:101			; => Ja, weiter...

			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	RunBASIC		;Datei auswählen.

::101			jsr	CMD_NewTarget		;Partition wechseln.
			jmp	RunBASIC		;Datei auswählen.
::102			jmp	InitScreen		;Zurück zu GeoDOS.

::103			bit	c128Flag		;C128?
			bpl	:104			; => Nein, weiter...

			ldx	curDrive		;Bei RAM-Laufwerk kein laden
			lda	driveType -8,x		;mit GEOS128/GeoDOS möglich.
			bpl	:104			; => Kein RAM-Laufwerk, weiter.
			lda	curDrvMode		;CMD-Laufwerk/RAMLink?
			bmi	:104			; => Ja, BASIC-laden möglich.

			jsr	ClrScreen		;Fenster aufbauen.

			DB_OK	V1060v3			;Hinweis: RAM-Laufwerk/GEOS128.
			jmp	RunBASIC		;Zurück zu RunBASIC.

::104			jmp	C64BootFile		;BASIC/Laden vorbereiten.

;*** Dateien suchen.
:LookForFiles		jsr	ClrScreen		;Fenster aufbauen.

			jsr	DoInfoBox
			PrintStrgDB_RdFile

			jsr	NewOpenDisk
			txa
			bne	:102

			LoadW	r6,FileNTab
			ClrB	r7L
			LoadB	r7H,255
			ClrW	r10
			jsr	FindFTypes
			txa
			bne	:102
			CmpBI	r7H,255
			beq	:102
			rts

;*** Keine Dateien gefunden, Speicher löschen.
::102			jsr	i_FillRam
			w	17*255
			w	FileNTab
			b	$00
			rts

;*** Dateienamen nach 16Z. konvertieren.
:ConvertFNames		lda	#<FileNTab
			sta	r14L
			sta	r15L
			lda	#>FileNTab
			sta	r14H
			sta	r15H

::101			lda	r7H
			cmp	#255
			beq	:103

			ldy	#0
::102			lda	(r15L),y		;GEOS 17 Zeichen nach
			sta	(r14L),y		;GeoDOS 16 Zeichen.
			iny
			cpy	#16
			bne	:102

			AddVBW	17,r15
			AddVBW	16,r14

			inc	r7H
			jmp	:101

::103			ldy	#0			;Ende der Tabelle merkieren
			tya
			sta	(r14L),y
			rts

;*** Routine zum starten eines BASIC-Files.
;    Übergabe: r15 = Dateiname.
:C64BootFile		ldy	#$00			;Dateiname in Zwischenspeicher
::loop1			lda	(r15L),y		;und in Dialogbox schreiben.
			beq	:exit_loop1
			sta	AppFName,y
			sta	V1060v0 +17,y
			iny
			cpy	#$10
			bne	:loop1
::exit_loop1		lda	#$22
			sta	V1060v0 +17,y
			lda	#$00
			sta	AppFName,y
			iny
			sta	V1060v0 +17,y

			jsr	ClrScreen		;Fenster aufbauen.

			DB_UsrBoxV1060v0			;"BASIC-Datei öffnen ?"
			CmpBI	sysDBData,YES		;"Ja" gewählt ?
			beq	:do_load
			jmp	RunBASIC		;Nein, Verzeichnis wieder anzeigen.

::exit_dskerr		jmp	DiskError		;Diskfehler anzeigen.

::do_load		LoadW	r6,AppFName
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:exit_dskerr		; => Ja, Abbruch...

			bit	c128Flag		;C128?
			bmi	:load_c128		; => Ja, weiter...

;--- Ladeadresse prüfen.
			lda	dirEntryBuf+1		;Zeiger auf ersten Datenblock.
			sta	r1L
			lda	dirEntryBuf+2
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Ersten Datenblock einlesen.
			txa				;Fehler?
			bne	:exit_dskerr		; => Ja, Abbruch...

			lda	diskBlkBuf+2		;Laeadresse = $0801?
			cmp	#$01
			bne	:ask_load_abs		; => Nein, Absolut laden?
			lda	diskBlkBuf+3
			cmp	#$08
			beq	:load_std		; => Ja, weiter...

::ask_load_abs		ldx	curDrive		;Bei RAM-Laufwerk kein absolutes
			lda	driveType -8,x		;laden mit ",dev,1" möglich.
			bpl	:0			; => Kein RAM-Laufwerk, weiter.
			lda	curDrvMode		;CMD-Laufwerk/RAMLink?
			bmi	:0			; => Ja, BASIC-laden möglich.

			jsr	ClrScreen		;Fenster aufbauen.

			DB_UsrBoxV1060v2			;Fragen ob von RAM normal geladen
			lda	sysDBData		;werden soll...
			cmp	#YES			;"Ja" ?
			beq	:load_std		; => Normal laden.
			bne	:cancel			;Abbruch.

::0			jsr	ClrScreen		;Fenster aufbauen.

			DB_UsrBoxV1060v1			;Fragen ob Absolut geladen
			lda	sysDBData		;werden soll...
			cmp	#NO
			beq	:load_std		; => Nein, normal laden/starten.
			cmp	#YES
			beq	:load_abs		; => Ja, absolut laden.
::cancel		jmp	RunBASIC		;Nein, Verzeichnis wieder anzeigen.

;--- C128: Programm laden/starten.
::load_c128		jmp	C128BootFile

;--- Programm normal laden/starten.
::load_std		LoadW	r0,RunBASICcom		;"RUN"-Befehl.
			LoadW	r5,dirEntryBuf		;Zeiger auf Verzeichnis-Eintrag.
			LoadW	r7,$0801		;Ladeadresse.

			jmp	ToBasic			;Nach BASIC beenden.

;--- Programm absolut laden/manuell starten.
::load_abs		LoadW	r1,LoadBASIC64

			ldx	#$00
			ldy	#$05			;Dateiname kopieren.
::2			lda	AppFName,x		;Ende erreicht?
			beq	:3
			sta	(r1L),y			;Ende Dateiname suchen.
			iny
			inx
			cpx	#$10
			bne	:2

::3			lda	#$22			;",dev,1" an den Dateinamen
			sta	(r1L),y			;anhängen.
			iny
			lda	#$2c			;","
			sta	(r1L),y
			iny

			ldx	curDrive		;Laufwerk 8,9,10,11 in
			lda	driveAdr1 -8,x		;Befehl eintragen.
			beq	:4
			sta	(r1L),y
			iny
::4			lda	driveAdr2 -8,x
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

;*** Nach BASIC verlassen und Befehl ausführen.
;    Übergabe: r0 = Zeiger auf Befehl.
			LoadW	r0,LoadBASIC64		;"LOAD"-Befehl.

			lda	#$00			;Kein Programm laden.
			sta	r5L
			sta	r5H

			sta	$0800			;Kein Programm starten.
			sta	$0801
			sta	$0802
			sta	$0803
			LoadW	r7,$0803
			jmp	ToBasic			;Nach BASIC beenden.

;*** Routine zum starten eines BASIC-Files.
;    Übergabe: r15 = Dateiname.
:C128BootFile		LoadW	r1,RunBASIC128

			ldx	#$00
			ldy	#$04			;Dateiname kopieren.
::2			lda	AppFName,x		;Ende erreicht?
			beq	:3
			sta	(r1L),y			;Ende Dateiname suchen.
			iny
			inx
			cpx	#$10
			bne	:2

::3			lda	#$22			;",dev,1" an den Dateinamen
			sta	(r1L),y			;anhängen.
			iny
			lda	#$2c			;","
			sta	(r1L),y
			iny
			lda	#"U"			;","
			sta	(r1L),y
			iny

			ldx	curDrive		;Laufwerk 8,9,10,11 in
			lda	driveAdr1 -8,x		;Befehl eintragen.
			beq	:4
			sta	(r1L),y
			iny
::4			lda	driveAdr2 -8,x
			sta	(r1L),y
			iny

			lda	#NULL			;Befehlsende.
			sta	(r1L),y

;*** Nach BASIC verlassen und Befehl ausführen.
;    Übergabe: r0 = Zeiger auf Befehl.
			LoadW	r0,SCREEN_BASE
			LoadW	r1,RunBASIC128		;"RUN"-Befehl.

			ldy	#$00
::1			lda	(r1L),y
			sta	(r0L),y
			beq	:5
			iny
			bne	:1

::5			lda	#$00			;Kein Programm laden.
			sta	r5L
			sta	r5H

			sta	$1c00			;Kein Programm starten.
			sta	$1c01
			sta	$1c02
			sta	$1c03
			LoadW	r7,$1c03
			jmp	ToBasic			;Nach BASIC beenden.

;*** Variablen.
if Sprache = Deutsch
:V1060a0		b PLAINTEXT,"BASIC-Programm wählen",NULL
endif
if Sprache = Englisch
:V1060a0		b PLAINTEXT,"Select BASIC file",NULL
endif

;*** Dialogboxen.
:GetFileTab		b $04
			b $ff
			b $00
			b $10
			b $00
:GetFileTitel		w V1060a0
			w FileNTab

:AppFName		s 17

:RunBASICcom		b "RUN",NULL

:LoadBASIC64		b "LOAD",$22
			s 17
			b $22,",8,1",NULL

:RunBASIC128		b "RUN",$22
			s 17
			b $22,",8,1",NULL

:driveAdr1		b NULL,NULL,"1","1"
:driveAdr2		b "8" ,"9" ,"0","1"

;*** Frage: "BASIC-Datei starten?
if Sprache = Deutsch
:V1060v0		w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Datei: ",$22,"1234567890123456",$22,NULL
::102			b        "Die BASIC-Datei starten ?",NULL
endif
if Sprache = Englisch
:V1060v0		w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"File : ",$22,"1234567890123456",$22,NULL
::102			b        "Run BASIC file ?",NULL
endif

;*** Frage: "BASIC-Datei absolut laden?
if Sprache = Deutsch
:V1060v1		w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Keine Standard-Ladeadresse.",NULL
::102			b        "Absolut mit ,dev,1 laden ?",NULL
endif
if Sprache = Englisch
:V1060v1		w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"No standard load adress.",NULL
::102			b        "Load absolute with ,dev,1 ?",NULL
endif

;*** Frage: "BASIC-Datei absolut laden?
if Sprache = Deutsch
:V1060v2		w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"RAM-Laufwerk: Absolutes laden",NULL
::102			b        "nicht möglich. Normal laden ?",NULL
endif
if Sprache = Englisch
:V1060v2		w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Absolute loading from RAM-drive",NULL
::102			b        "not supported. Load normal ?",NULL
endif

;*** Hinweis: "Starten von RAM-Laufwerk nicht möglich!"
if Sprache = Deutsch
:V1060v3		w :101, :102, ISet_Achtung
::101			b BOLDON,"Starten von RAM-Laufwerk",NULL
::102			b        "mit GEOS128 nicht möglich!",NULL
endif
if Sprache = Englisch
:V1060v3		w :101, :102, ISet_Achtung
::101			b BOLDON,"Loading files from a RAM-",NULL
::102			b        "drive supported for GEOS128!",NULL
endif
