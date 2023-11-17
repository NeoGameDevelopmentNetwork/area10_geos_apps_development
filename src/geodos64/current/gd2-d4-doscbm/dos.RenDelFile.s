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
			t	"src.DOSDRIVE.ext"
endif

			n	"mod.#309.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaDOS

			jmp	DOS_DelFile
			jmp	DOS_RenFile

			t	"-DOS_SetName"
			t	"-DOS_SlctFiles"

;*** L309: Dateien umbenennen
:DOS_RenFile		lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V309a1
			jsr	SlctFiles		;Dateien auswählen.
			tax
			beq	:102
::101			jmp	L309ExitGD		;Ende.

::102			lda	curDrive
			sta	Target_Drv

			LoadW	a5,FileNTab		;Zeiger auf Namenstabelle nach ":a5".

::103			jsr	L309a0
			cmp	#$03
			beq	:104

			AddVBW	16,a5			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a5L),y			;Tabellen-Ende erreicht ?
			beq	:104			;Ja, Ende.
			jmp	:103			;Nein, weiter...

::104			jmp	L309ExitGD		;Zurück zu GeoDOS.

;*** Dateiname ändern.
:L309a0			ldy	#11
::100			lda	(a5L),y
			sta	V309c0,y
			dey
			bpl	:100

			LoadW	r0,V309c0
			LoadW	r1,V309c1
			LoadB	r2L,$ff
			LoadB	r2H,$ff
			LoadW	r3,V309a0
			jsr	dosSetName
			cmp	#$01
			beq	:101
			rts

::101			MoveW	a5,r0
			ldx	#r0L
			ldy	#r1L
			lda	#16
			jsr	CmpFString
			bne	:102
			lda	#$01
			rts

::102			jsr	DoInfoBox		;Info: "Verzeichnis wird überprüft..."
			PrintStrgV309f1

			LoadW	r10,V309c1		;Prüfen ob Datei schon vorhanden.
			jsr	LookDOSfile
			tay
			bne	:103

			jsr	ClrBox			;Fehler: "Name bereits vergeben..:"

			DB_OK	V309d0
			jmp	L309a0

::103			MoveW	a5,r10			;Datei suchen.
			jsr	LookDOSfile
			tay
			beq	:104
			jsr	ClrBox
			lda	#$02
			rts

::104			ldx	#$00
			ldy	#$00
::105			lda	V309c1,x		;Neuen Dateinamen schreiben.
			beq	:107
			cmp	#"."
			beq	:106
			sta	(a8L),y
			iny
::106			inx
			cpy	#$0b
			bne	:105

::107			cpy	#$0b			;Auf 11 Zeichen mit Leerzeichen
			beq	:108			;auffüllen.
			lda	#" "
			sta	(a8L),y
			inx
			iny
			bne	:107

::108			LoadW	a8,Disk_Sek		;Directory-Sektor schreiben.
			jsr	D_Write
			txa
			beq	:109
			jmp	DiskError		;Disketten-Fehler.

::109			jsr	ClrBox
			lda	#$01
			rts

;*** L309: Dateien löschen.
:DOS_DelFile		lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V309a2
			jsr	SlctFiles		;Dateien auswählen.
			tax
			beq	:102
::101			jmp	L309ExitGD		;Zurück zu GeoDOS.

::102			lda	curDrive
			sta	Target_Drv

			LoadW	a5,FileNTab		;Zeiger auf Datei-Tabelle nach ":a5".
			ClrB	V309b0

:L309b0			lda	V309b0			;Sicherheitsabfrage ?
			bne	L309b2			;Nein, automatisch löschen.
			jsr	AskToDelFile		;Sicherheitsabfrage.
			cmp	#$00
			bne	:101
			jmp	L309c0			;FAT schreiben und Ende.

::101			cmp	#$02			;Datei überspringen.
			bne	:102
			jmp	L309b3

::102			cmp	#$03
			bne	L309b1
			LoadB	V309b0,$ff		;Alle Dateien automatisch löschen.

:L309b1			jsr	DoInfoBox		;Hinweis: "Datei wird gelöscht..."
:L309b2			PrintStrgV309f0
			jsr	PrnFileName

			MoveW	a5,r10			;Datei-Eintrag suchen.
			jsr	LookDOSfile
			tay
			bne	L309b3

			jsr	L309d0			;DOS-Datei löschen.

			jsr	ClrBoxText
			lda	V309b0
			bne	L309b3
			jsr	ClrBox

:L309b3			AddVBW	16,a5			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a5L),y			;Tabellen-Ende erreicht ?
			beq	:101			;Ja, Ende.
			jmp	L309b0			;Nein, weiter...

::101			lda	V309b0
			beq	L309c0
			jsr	ClrBox

;*** Falls Dateien gelöscht, FAT aktualisieren.
:L309c0			jsr	DoInfoBox
			PrintStrgV309f2
			jsr	Save_FAT		;FAT aktualisieren.
			jsr	ClrBox
			jmp	L309ExitGD		;Zurück zu GeoDOS.

;*** Vorhandene DOS-Datei löschen.
:L309d0			ldy	#$00			;Dateiname löschen.
			lda	#$e5
			sta	(a8L),y

			PushW	a8			;Veränderten Dir-Sektor speichern.
			LoadW	a8,Disk_Sek
			jsr	D_Write
			PopW	a8

			ldy	#$1a			;Start-Cluster einlesen.
			lda	(a8L),y
			sta	r1L
			iny
			lda	(a8L),y
			sta	r1H

			ClrW	r4

::101			lda	r1L			;Zeiger auf aktuellen Cluster
			ldx	r1H
			cmp	#$00
			bne	:102
			cpx	#$00
			beq	:103

::102			jsr	Get_Clu			;Link auf nächsten Cluster lesen.
			PushW	r1			;Link-Wert merken.
			lda	r2L
			ldx	r2H
			jsr	Set_Clu			;Aktuellen Cluster freigeben.
			pla				;Nächsten Cluster bestimmen.
			sta	r1L
			tay
			pla
			sta	r1H
			and	#%00001111
			cmp	#$0f			;Datei-Ende erreicht ?
			bne	:101			;Nein, nächsten Cluster löschen.
			cpy	#$f8
			bcc	:101

::103			LoadB	BAM_Modify,$ff
			rts

;*** Frage: "Datei löschen ?"
:AskToDelFile		jsr	ClrBox

			jsr	i_C_DBoxBack
			b	$06,$05,$1c,$0e

			LoadW	r0,V309e0
			DB_RecBoxL309RVec_a
			lda	sysDBData
			rts

;*** Farben setzen.
:L309Win_a		jsr	i_C_DBoxClose
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
if Sprache = Deutsch
			b	PLAINTEXT,"Systemmeldung"
			b	PLAINTEXT,NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"Information"
			b	PLAINTEXT,NULL
endif

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
:L309RVec_a		jsr	i_C_ColorClr
			b	$06,$05,$1c,$0e
			FillPRec$00,$28,$97,$0030,$010f
			rts

:L309Exit_a		lda	#$00			;"Close"-Icon.
			b $2c
:L309Exit_b		lda	#$01			;"JA"-Icon.
			b $2c
:L309Exit_c		lda	#$02			;"NEIN"-Icon.
			b $2c
:L309Exit_d		lda	#$03			;"ALLE"-Icon.
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Dateinamen ausgeben.
:PrnFileName		lda	#$22			;Anführungszeichen ausgeben.
			jsr	SmallPutChar

			lda	#$00			;Dateiname ausgeben.
::101			pha
			tay
			lda	(a5L),y
			beq	:104
			jsr	SmallPutChar
::102			pla
			add	1
::103			cmp	#12
			bne	:101
			pha
::104			pla

			lda	#$22			;Anführungszeichen ausgeben.
			jmp	SmallPutChar

;*** Zurück zu GeoDOS.
:L309ExitGD		jmp	InitScreen		;Ende...

if Sprache = Deutsch
;*** Variablen.
:V309a0			b PLAINTEXT,"Neuer Dateiname",NULL
:V309a1			b PLAINTEXT,"Dateinamen ändern",NULL
:V309a2			b PLAINTEXT,"Dateien löschen",NULL

:V309b0			b $00				;Automatisch löschen.

:V309c0			s 17				;Zwischenspeicher Dateiname.
:V309c1			s 17				;Zwischenspeicher Dateiname.

;*** Fehler: "Datei existiert bereits"
:V309d0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Dieser Dateiname ist",NULL
::102			b        "bereits vergeben !",NULL

;*** Sicherheitsabfrage.
:V309e0			b %00100000
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
			w L309Win_a
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Die folgende Datei auf",NULL
::102			b "Diskette löschen ?",NULL

::103			b "Dateiname:",NULL

::104			w Icon_Close
			b $00,$00,$01,$08
			w L309Exit_a

::105			w Icon_Ja
			b $00,$00,$06,$10
			w L309Exit_b

::106			w Icon_Nein
			b $00,$00,$06,$10
			w L309Exit_c

::107			w Icon_Alle
			b $00,$00,$06,$10
			w L309Exit_d

;*** Texte für Info-Fenster.
:V309f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei wird gelöscht..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

:V309f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "überprüft..."
			b NULL

:V309f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenverzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird aktualisiert..."
			b NULL
endif

if Sprache = Englisch
;*** Variablen.
:V309a0			b PLAINTEXT,"New filename",NULL
:V309a1			b PLAINTEXT,"Edit filename",NULL
:V309a2			b PLAINTEXT,"Delete files",NULL

:V309b0			b $00				;Automatisch löschen.

:V309c0			s 17				;Zwischenspeicher Dateiname.
:V309c1			s 17				;Zwischenspeicher Dateiname.

;*** Fehler: "Datei existiert bereits"
:V309d0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Filename already",NULL
::102			b        "exist on disk !",NULL

;*** Sicherheitsabfrage.
:V309e0			b %00100000
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
			w L309Win_a
			b NULL

::101			b PLAINTEXT,BOLDON
			b "Delete the selected",NULL
::102			b "file on disk ?",NULL

::103			b "Filename :",NULL

::104			w Icon_Close
			b $00,$00,$01,$08
			w L309Exit_a

::105			w Icon_Ja
			b $00,$00,$06,$10
			w L309Exit_b

::106			w Icon_Nein
			b $00,$00,$06,$10
			w L309Exit_c

::107			w Icon_Alle
			b $00,$00,$06,$10
			w L309Exit_d

;*** Texte für Info-Fenster.
:V309f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Deleting file..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

:V309f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Analyzing directory..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

:V309f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Update current"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "disk-directory..."
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
