; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L080: Ziel-Datei existiert.
:FileExist		jsr	CSet_Grau
			LoadW	r0,V080a0
			ClrDlgBoxL080RVec
			lda	sysDBData
			rts

;*** Farben setzen.
:L080Col_1		SetColRam23,7*40+9,$61
			Pattern	1
			FillRec	56,63,72,255

			jsr	UseGDFont
			PrintXY	80,62,V080a4
			jsr	UseSystemFont

			jsr	ISet_Frage

			sbBn	currentMode,6
			LoadB	r1H,107
			LoadW	r11,80
			lda	#$22
			jsr	SmallPutChar
			MoveW	r15,r0
			jsr	PutString
			lda	#$22
			jmp	SmallPutChar

;*** Farben zurücksetzen.
:L080RVec		PushB	r2L
			SetColRam23,7*40+9,$b1
			jsr	CSet_Grau
			PopB	r2L
			rts

:L080ExitW_a		lda	#$00			;"Close"-Icon.
			b $2c

:L080ExitW_b		lda	#$01			;"JA"-Icon.
			b $2c

:L080ExitW_c		lda	#$02			;"NEIN"-Icon.
			b $2c

:L080ExitW_d		lda	#$03			;"NAME"-Icon.
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Fehler: "File Exist!"
:V080a0			b $01				;Fenster-Abmessungen.
			b 56,151
			w 64,255
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V080a1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V080a2
			b DBTXTSTR  , 16, 63
			w V080a3

			b DBUSRICON ,  0,  0
			w V080a5
			b DBUSRICON ,  2, 72
			w V080a6
			b DBUSRICON ,  9, 72
			w V080a7
			b DBUSRICON , 16, 72
			w V080a8

			b DB_USR_ROUT			;Icon platzieren.
			w L080Col_1
			b NULL

:V080a1			b PLAINTEXT,BOLDON
			b "Die folgende Datei ist",NULL
:V080a2			b "bereits vorhanden!",NULL
:V080a3			b "Datei auf Ziel-Disk löschen ?",PLAINTEXT,NULL
:V080a4			b PLAINTEXT,REV_ON,"Information",PLAINTEXT,NULL

:V080a5			w icon_Close
			b $00,$00
			b icon_Close_x,icon_Close_y
			w L080ExitW_a

:V080a6			w icon_Ja
			b $00,$00
			b icon_Ja_x,icon_Ja_y
			w L080ExitW_b

:V080a7			w icon_Nein
			b $00,$00
			b icon_Nein_x,icon_Nein_y
			w L080ExitW_c

:V080a8			w icon_Name
			b $00,$00
			b icon_Name_x,icon_Name_y
			w L080ExitW_d

:icon_Ja
<MISSING_IMAGE_DATA>
:icon_Ja_x		= .x
:icon_Ja_y		= .y

:icon_Nein
<MISSING_IMAGE_DATA>
:icon_Nein_x		= .x
:icon_Nein_y		= .y

:icon_Name
<MISSING_IMAGE_DATA>
:icon_Name_x		= .x
:icon_Name_y		= .y
