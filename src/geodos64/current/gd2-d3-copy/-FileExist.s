; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L080: Ziel-Datei existiert.
:FileExist		jsr	ClrBox

			jsr	i_C_DBoxBack
			b	$06,$05,$1c,$0e

			LoadW	r0,:900
			DB_RecBox:200
			lda	sysDBData
			rts

;*** Farben setzen.
::100			jsr	i_C_DBoxClose
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
			Print	$0040,$2e
			b	PLAINTEXT,"Information"
			b	GOTOXY
			w	$0040
			b	$66

if Sprache = Deutsch
			b	"Datei:"
endif

if Sprache = Englisch
			b	"File:"
endif
			b	NULL

			LoadB	r1H,$66
			LoadW	r11,$0083

			ldy	#$00
::101			sty	:102 +1
			lda	(r15L),y
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
::200			jsr	i_C_ColorClr
			b	$06,$05,$1c,$0e
			FillPRec$00,$28,$97,$0030,$010f
			rts

;*** Dialogbox verlassen.
::300			lda	#$00			;"Close"-Icon.
			b $2c

::301			lda	#$01			;"JA"-Icon.
			b $2c

::302			lda	#$02			;"NEIN"-Icon.
			b $2c

::303			lda	#$03			;"NAME"-Icon.
			sta	sysDBData

			jmp	RstrFrmDialogue

if Sprache = Deutsch
;*** Fehler: "File Exist!"
::900			b %00100000
			b 40,151
			w 48,271
			b DBTXTSTR  ,DBoxLeft,DBoxBase1 +8
			w :901
			b DBTXTSTR  ,DBoxLeft,DBoxBase2 +8
			w :902
			b DBTXTSTR  , 16, 78
			w :903
			b DBUSRICON ,  0,  0
			w :905
			b DBUSRICON ,  2, 88
			w :906
			b DBUSRICON , 11, 88
			w :907
			b DBUSRICON , 20, 88
			w :908
			b DB_USR_ROUT
			w :100
			b NULL

::901			b PLAINTEXT,BOLDON
			b "Die folgende Datei ist bereits",NULL
::902			b "auf Diskette vorhanden!",NULL
::903			b "Datei auf der Zieldiskette löschen ?",NULL
::904			b "Dateiname",NULL
endif

if Sprache = Englisch
;*** Fehler: "File Exist!"
::900			b %00100000
			b 40,151
			w 48,271
			b DBTXTSTR  ,DBoxLeft,DBoxBase1 +8
			w :901
			b DBTXTSTR  ,DBoxLeft,DBoxBase2 +8
			w :902
			b DBTXTSTR  , 16, 78
			w :903
			b DBUSRICON ,  0,  0
			w :905
			b DBUSRICON ,  2, 88
			w :906
			b DBUSRICON , 11, 88
			w :907
			b DBUSRICON , 20, 88
			w :908
			b DB_USR_ROUT
			w :100
			b NULL

::901			b PLAINTEXT,BOLDON
			b "File already exist",NULL
::902			b "on targetdisk!",NULL
::903			b "Delete file on targetdisk ?",NULL
::904			b "Filename",NULL
endif

::905			w Icon_Close
			b $00,$00,$01,$08
			w :300

::906			w Icon_Ja
			b $00,$00,$06,$10
			w :301

::907			w Icon_Nein
			b $00,$00,$06,$10
			w :302

::908			w Icon_Name
			b $00,$00,$06,$10
			w :303

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

:Icon_Name
<MISSING_IMAGE_DATA>
