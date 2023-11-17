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

			n	"mod.#409.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM

			jmp	CBM_DelFile
			jmp	CBM_RenFile

			t	"-CBM_SetName"
			t	"-CBM_SlctFiles"

;*** L409: Dateien umbenennen
:CBM_RenFile		lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V409a1
			jsr	SlctFiles		;Dateien auswählen.
			tax
			beq	:102
::101			jmp	L409ExitGD		;Zurück zu GeoDOS.

::102			LoadW	a5,FileNTab		;Zeiger auf Datei-Tabelle nach ":a5".

::103			jsr	L409m0
			cmp	#$03
			beq	:104

			AddVBW	16,a5			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a5L),y			;Tabellen-Ende erreicht ?
			bne	:103			;Nein, weiter...

::104			jmp	L409ExitGD		;Ja, zurück zu GeoDOS.

;*** Dateiname ändern.
:L409m0			jsr	L409m1

			LoadW	r0 ,V409c0
			LoadW	r1 ,V409c1
			LoadB	r2L,$ff
			LoadB	r2H,$ff
			LoadW	r3,V409a0
			jsr	cbmSetName
			cmp	#$01
			beq	:101
			rts

::101			MoveW	a5,r0
			LoadW	r1,V409c1
			ldx	#r0L
			ldy	#r1L
			lda	#16
			jsr	CmpFString
			bne	:102
			lda	#$01
			rts

::102			jsr	DoInfoBox		;Info: "Verzeichnis wird überprüft..."
			PrintStrgV409f1

			LoadW	r14,V409c1		;Prüfen ob Datei schon vorhanden.
			jsr	LookCBMfile
			tay
			bne	:103

			jsr	ClrBox

			DB_OK	V409d0			;Fehler: "Name bereits vergeben..."
			jmp	L409m0

::103			MoveW	a5,r14
			jsr	LookCBMfile
			tay
			beq	:104
			jsr	ClrBox
			lda	#$02
			rts

::104			ldy	#$00
::105			lda	V409c1,y		;Neuen Dateinamen schreiben.
			beq	:106
			sta	diskBlkBuf+5,x
			inx
			iny
			cpy	#$10
			bne	:105

::106			cpy	#$10			;Auf 16 Zeichen mit "SHIFTSPACE"
			beq	:107			;auffüllen.
			lda	#$a0
			sta	diskBlkBuf+5,x
			inx
			iny
			bne	:106

::107			LoadW	r4,diskBlkBuf		;Directory-Sektor schreiben.
			jsr	PutBlock
			txa
			beq	:108
			jmp	DiskError		;Disketten-Fehler.

::108			jsr	ClrBox
			lda	#$01
			rts

;*** Dateinamen in Zwischenspeicher kopieren.
:L409m1			ldy	#15
::101			lda	(a5L),y
			sta	V409c0,y
			dey
			bpl	:101
			rts

;*** CBM-Dateien löschen.
:CBM_DelFile		lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V409a2
			jsr	SlctFiles		;Dateien auswählen.
			tax
			beq	:102
::101			jmp	L409ExitGD		;Zurück zu GeoDOS.

::102			LoadW	a5,FileNTab		;Zeiger auf Datei-Tabelle nach ":a5".
			ClrB	V409b0

:L409n0			lda	V409b0			;Sicherheitsabfrage ?
			bne	L409n2			;Nein, automatisch löschen.

			jsr	AskToDelFile		;Sicherheitsabfrage.
			cmp	#$00
			bne	:101
			jmp	L409ExitGD		;Zurück zu GeoDOS.

::101			cmp	#$02			;Datei überspringen.
			bne	:102
			jmp	L409n3

::102			cmp	#$03
			bne	L409n1
			LoadB	V409b0,$ff		;Alle Dateien automatisch löschen.

:L409n1			jsr	DoInfoBox		;Hinweis: "Datei wird gelöscht..."
:L409n2			PrintStrgV409f0

			jsr	PrnFileName

			MoveW	a5,r14			;Datei-Eintrag suchen.
			jsr	LookCBMfile
			tay
			bne	L409n3

			txa				;CBM-Datei löschen.
			pha
			ldy	#$00
::101			lda	diskBlkBuf+2,x
			sta	dirEntryBuf,y
			inx
			iny
			cpy	#$1e
			bne	:101
			pla
			tax

			lda	#$00
			sta	diskBlkBuf+$02,x
			lda	diskBlkBuf+$18,x
			sta	:103 +1
			jsr	PutBlock
			txa
			beq	:103
::102			jmp	DiskError		;Disketten-Fehler.

::103			lda	#$ff
			pha
			LoadW	r9,dirEntryBuf		;Sektoren freigeben.
			jsr	FreeFile
			pla				;Dateityp wieder einlesen.
			cmp	#TEMPORARY		;Typ Swap_File ?
			bne	:104			;Nein, weiter...
			cpx	#$06			;Fehler "BAD_BAM" ?
			beq	:105			;Ja, ignorieren.
::104			txa				;Diskettenfehler aufgetreten ?
			bne	:102			;Ja, Abbruch.

::105			jsr	ClrBoxText		;Infobox löschen.

			lda	V409b0
			bne	L409n3
			jsr	ClrBox

:L409n3			AddVBW	16,a5			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a5L),y			;Tabellen-Ende erreicht ?
			beq	:101			;Ja, Ende...
			jmp	L409n0			;Nein, weiter...

::101			lda	V409b0
			beq	:102
			jsr	ClrBox
::102			jmp	L409ExitGD		;Zurück zu GeoDOS.

;*** Frage: "Datei löschen ?"
:AskToDelFile		jsr	ClrBox

			jsr	i_C_DBoxBack
			b	$06,$05,$1c,$0e

			LoadW	r0,V409e0
			DB_RecBoxL409RVec_a
			lda	sysDBData
			rts

;*** Farben setzen.
:L409Win_a		jsr	i_C_DBoxClose
			b	$06,$05,$01,$01
			jsr	i_C_DBoxTitel
			b	$07,$05,$1b,$01

			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0030
			b	$28
			b	RECTANGLETO
			w	$010f
			b	$2f

			b	MOVEPENTO
			w	$007f
			b	$5f
			b	FRAME_RECTO
			w	$0100
			b	$68
			b	NULL

			jsr	i_ColorBox
			b	$10,$0c,$10,$01,$01

			jsr	UseGDFont
			Print	$40,$2e
			b	PLAINTEXT,"Information"
			b	PLAINTEXT,NULL

			LoadB	r1H,$66
			LoadW	r11,$0083

			ldy	#$00
::101			sty	:102 +1
			lda	(a5L),y
			beq	:103
			jsr	ConvertChar
			jsr	SmallPutChar
::102			ldy	#$ff
			iny
			cpy	#$10
			bne	:101

::103			jsr	UseSystemFont

			jsr	i_C_DBoxDIcon
			b	$08,$10,$06,$02
			jsr	i_C_DBoxDIcon
			b	$11,$10,$06,$02
			jsr	i_C_DBoxDIcon
			b	$1a,$10,$06,$02
			jmp	ISet_Frage

;*** Farben zurücksetzen.
:L409RVec_a		jsr	i_C_ColorClr
			b	$06,$05,$1c,$0e
			FillPRec$00,$28,$97,$0030,$010f
			rts

:L409Exit_a		lda	#$00			;"Close"-Icon.
			b $2c
:L409Exit_b		lda	#$01			;"JA"-Icon.
			b $2c
:L409Exit_c		lda	#$02			;"NEIN"-Icon.
			b $2c
:L409Exit_d		lda	#$03			;"ALLE"-Icon.
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Dateinamen ausgeben.
:PrnFileName		lda	#$22			;Anführungszeichen ausgeben.
			jsr	SmallPutChar

			ldy	#$00			;Dateiname ausgeben.
::101			sty	:102 +1

			lda	(a5L),y
			beq	:103
			jsr	ConvertChar
			jsr	SmallPutChar

::102			ldy	#$ff
			iny
			cpy	#16
			bne	:101

::103			lda	#$22			;Anführungszeichen ausgeben.
			jmp	SmallPutChar

;*** Zurück zu GeoDOS.
:L409ExitGD		jmp	InitScreen		;Ende...

;*** Variablen.
if Sprache = Deutsch
:V409a0			b PLAINTEXT,"Neuer Dateiname",NULL
:V409a1			b PLAINTEXT,"Dateinamen ändern",NULL
:V409a2			b PLAINTEXT,"Dateien löschen",NULL

:V409b0			b $00				;Automatisch löschen.

:V409c0			s 17				;Zwischenspeicher Dateiname.
:V409c1			s 17				;Zwischenspeicher Dateiname.

;*** Fehler: "Datei existiert bereits"
:V409d0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Dieser Dateiname ist",NULL
::102			b        "bereits vergeben !",NULL

;*** Sicherheitsabfrage.
:V409e0			b %00100000
			b 40,151
			w 48,271
			b DBTXTSTR  ,DBoxLeft,DBoxBase1 +8
			w :101
			b DBTXTSTR  ,DBoxLeft,DBoxBase2 +8
			w :102
			b DBTXTSTR  , 16, 62
			w :103
			b DBUSRICON ,  0,  0
			w :104
			b DBUSRICON ,  2, 88
			w :105
			b DBUSRICON , 11, 88
			w :106
			b DBUSRICON , 20, 88
			w :107
			b DB_USR_ROUT
			w L409Win_a
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Die folgende Datei auf",NULL
::102			b "Diskette löschen ?",NULL

::103			b "Dateiname:",NULL

::104			w Icon_Close
			b $00,$00,$01,$08
			w L409Exit_a

::105			w Icon_Ja
			b $00,$00,$06,$10
			w L409Exit_b

::106			w Icon_Nein
			b $00,$00,$06,$10
			w L409Exit_c

::107			w Icon_Alle
			b $00,$00,$06,$10
			w L409Exit_d

;*** Texte für Info-Fenster.
:V409f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei wird gelöscht..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

:V409f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "überprüft..."
			b NULL
endif

;*** Variablen.
if Sprache = Englisch
:V409a0			b PLAINTEXT,"New filename",NULL
:V409a1			b PLAINTEXT,"Edit filename",NULL
:V409a2			b PLAINTEXT,"Delete files",NULL

:V409b0			b $00				;Automatisch löschen.

:V409c0			s 17				;Zwischenspeicher Dateiname.
:V409c1			s 17				;Zwischenspeicher Dateiname.

;*** Fehler: "Datei existiert bereits"
:V409d0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Filename always",NULL
::102			b        "exist on disk !",NULL

;*** Sicherheitsabfrage.
:V409e0			b %00100000
			b 40,151
			w 48,271
			b DBTXTSTR  ,DBoxLeft,DBoxBase1 +8
			w :101
			b DBTXTSTR  ,DBoxLeft,DBoxBase2 +8
			w :102
			b DBTXTSTR  , 16, 62
			w :103
			b DBUSRICON ,  0,  0
			w :104
			b DBUSRICON ,  2, 88
			w :105
			b DBUSRICON , 11, 88
			w :106
			b DBUSRICON , 20, 88
			w :107
			b DB_USR_ROUT
			w L409Win_a
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Delete current file",NULL
::102			b "on target-disk ?",NULL

::103			b "Filename :",NULL

::104			w Icon_Close
			b $00,$00,$01,$08
			w L409Exit_a

::105			w Icon_Ja
			b $00,$00,$06,$10
			w L409Exit_b

::106			w Icon_Nein
			b $00,$00,$06,$10
			w L409Exit_c

::107			w Icon_Alle
			b $00,$00,$06,$10
			w L409Exit_d

;*** Texte für Info-Fenster.
:V409f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Deleting file..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

:V409f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Analyzing current"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory..."
			b NULL
endif

;*** Icons.
if Sprache = Deutsch
:Icon_Ja
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_Ja
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_Nein
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_Nein
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_Alle
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_Alle
<MISSING_IMAGE_DATA>
endif

:EndProgrammCode
