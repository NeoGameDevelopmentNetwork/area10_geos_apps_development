; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"

.zpage			= $0000
.DB_VecDefTab		= $0043
.DB_FilesInTab		= $8856
.DB_GetFileX		= $8857
.DB_GetFileY		= $8858
.DB_FileTabVec		= $8859
.DB_SelectedFile	= $885c
.DB_GetFiles		= $f688
.SwapFileName		= $d82d
.SaveSwapFile		= $d839
.DB_DefBoxPos		= $f3d8
.DB_CopyIconInTab	= $f52e
.DB_Icon_OPEN		= $f5a0
.DA_ResetScrn		= $885d
.DB_WinLastFile		= DA_ResetScrn
.DB_WinFirstFile	= DB_SelectedFile
.FilesInWindow		= $05
.FileEntryHigh		= $0e
.FileWinXsize		= $007c
.FileWinYsize		= $58
.FileWinIconArea	= $0e
.xRstrFrmDialogue	= $f429
.graphMode		= $3f

endif

			n "PatchFileBox"
			c "VisionPatch V1.0"
			a "M. Kanet"

			f $06
			z $80

			o $0400
			p $0400

			i
<MISSING_IMAGE_DATA>

;*** Hauptprogramm
:MainInit		lda	version			;GEOS-Version testen.
			cmp	#$20			;GEOS 2.0 aktiv ?
			bne	AbortInstall		;Nein, weiter...

			lda	c128Flag		;C128er-Modus ?
			bmi	AbortInstall		;Ja, Abbruch...

			lda	$f68a			;Kernal-Einsprung prüfen.
			cmp	#$b1			;Stimmt Kernal-Prüfbyte ?
			bne	AbortInstall		;Nein, Kernal nicht Original...

			jsr	InstallPatch		;Kernal-Patch installieren.

			LoadW	r0,InstallBox1		;Installations-Hinweis #1.
			jsr	DoDlgBox

			lda	firstBoot		;Boot-Vorgang aktiv ?
			beq	:101			;Ja, weiter...

			LoadW	r0,InstallBox2		;Installations-Hinweis #2.
			jsr	DoDlgBox
::101			jmp	EnterDeskTop		;Zurück zum DeskTop.

:AbortInstall		jmp	WrongKernal		;Falsches Kernal!!!

;*** Dialogbox für Installationsmeldung #1.
:InstallBox1		b $81
			b DB_USR_ROUT
			w :101
			b DBSYSOPV
			b NULL

::101			LoadB	r1H,$38
			LoadW	r11,$00a0
			LoadW	r0 ,IB1_Text1
			jsr	PrintCenter

			LoadB	r1H,$47
			LoadW	r11,$00a0
			LoadW	r0 ,IB1_Text2
			jsr	PrintCenter

			LoadB	r1H,$56
			LoadW	r11,$00a0
			LoadW	r0 ,IB1_Text3
			jsr	PrintCenter

			LoadB	r1H,$6a
			LoadW	r11,$00a0
			LoadW	r0 ,IB1_Text4
			jsr	PrintCenter

			jmp	SleepJob

:IB1_Text1		b PLAINTEXT,OUTLINEON
			b "DB_GetFile Patch v3.0"
			b PLAINTEXT,NULL

:IB1_Text2		b "has been "
			b PLAINTEXT,NULL

:IB1_Text3		b "Installed in your Kernal"
			b PLAINTEXT,NULL

:IB1_Text4		b "by ",BOLDON," "
			b "Jean F. Major"
			b PLAINTEXT,NULL

;*** Patch installieren.
:InstallPatch		LoadW	RecoverVector,Rectangle

			lda	#$02
			jsr	SetPattern

			LoadB	r2L,0
			LoadB	r2H,199
			LoadW	r3 ,0
			LoadW	r4,319
			jsr	Rectangle

			LoadW	r0,PatchCode1		;Teil #1 nach $F688
			LoadW	r1,DB_GetFiles		;kopieren.
			LoadW	r2,$0291
			jsr	MoveData

			lda	#$30			;Assembler-Befehl "bmi $c0b7"
			sta	$c070			;in Programm-Code eintragen.
			lda	#$45
			sta	$c071

			LoadW	r0,PatchCode2		;Teil #2 nach $C072
			LoadW	r1,$c072		;kopieren. Nachladen einer
			LoadW	r2,$0044		;BASIC-Datei nicht mehr
			jsr	MoveData		;möglich!
			rts

;*** Dialogbox für Installationsmeldung #2.
:InstallBox2		b $81
			b DBTXTSTR,$11,$11
			w IB2_Text1
			b DBTXTSTR,$1b,$28
			w IB2_Text2
			b DBTXTSTR,$1b,$32
			w IB2_Text3
			b DBTXTSTR,$1b,$3c
			w IB2_Text4
			b DBTXTSTR,$1b,$48
			w IB2_Text5
			b DB_USR_ROUT
			w SleepJob
			b DBSYSOPV
			b NULL

:IB2_Text1		b "Send comments "
			b "and suggestions to :"
			b NULL

:IB2_Text2		b BOLDON
			b "Jean F. Major"
			b NULL

:IB2_Text3		b "119 Terrasse Eardley"
			b NULL

:IB2_Text4		b "Aylmer, Quebec, Canada"
			b NULL

:IB2_Text5		b "J9H 6B5"
			b PLAINTEXT,NULL

;*** Wartezeit bis zum Abbau der Dialogbox.
:SleepJob		LoadW	r0,$00f0
			jsr	Sleep
			jmp	RstrFrmDialogue

;*** Hinweis: Falsches Kernal!
:WrongKernal		LoadW	r0,InstallBox3
			jsr	DoDlgBox
			jmp	EnterDeskTop

;*** Dialogbox für Installationsmeldung #2.
:InstallBox3		b $81
			b DB_USR_ROUT
			w :101
			b DBSYSOPV
			b $00

::101			LoadB	r1H,$3d
			LoadW	r11,$00a0
			LoadW	r0 ,IB3_Text1
			jsr	PrintCenter

			LoadB	r1H,$51
			LoadW	r11,$00a0
			LoadW	r0 ,IB3_Text2
			jsr	PrintCenter

			LoadB	r1H,$65
			LoadW	r11,$00a0
			LoadW	r0 ,IB3_Text3
			jmp	PrintCenter

:IB3_Text1		b PLAINTEXT
			b "Cannot install",NULL

:IB3_Text2		b PLAINTEXT
			b "DBGetFile Patch v3.0",NULL

:IB3_Text3		b PLAINTEXT
			b "in your Kernal...",NULL

;*** Einbinden der Patch-Texte.
:PatchCode1		d "PatchFileBox.1"
:PatchCode2		d "PatchFileBox.2"

;*** Version testen.
:TestVerGEOS		lda	#$12
			cmp	version
			bpl	:101
			lda	c128Flag
::101			rts

;*** Bildschirm-Auflösung feststellen.
:Test80ZMode		jsr	TestVerGEOS		;GEOS 64 ?
			bpl	:102			;Ja, weiter...
			lda	graphMode		;40/80-Zeichen-Flag C128.
::102			rts

;*** Text zentriert ausgeben.
:PrintCenter		lda	r2H
			pha
			lda	r2L
			pha
			lda	r1H
			pha

			ldy	#$00
			sty	r2L
			sty	r2H

;*** Länge des Textstrings in Pixel berechnen.
:GetStringLen		tya
			pha

			lda	(r0L),y
			beq	:103
			cmp	#$20
			bcs	:101

			jsr	DoPrntCode
			clv
			bvc	:102

::101			ldx	currentMode
			jsr	GetRealSize
			tya
			clc
			adc	r2L
			sta	r2L
			bcc	:102
			inc	r2H

::102			pla
			tay
			iny
			clv
			bvc	GetStringLen

::103			pla

			ldx	#r2L
			ldy	#$01
			jsr	DShiftRight

			jsr	Test80ZMode		;80-Zeichen-Modus ?
			bpl	:104			;Nein, weiter...

			ldx	#r11L			;X-Koordinate verdoppeln.
			ldy	#$01
			jsr	DShiftLeft

::104			lda	r11L			;X-Koordinate berechnen.
			sec
			sbc	r2L
			sta	r11L
			lda	r11H
			sbc	r2H
			sta	r11H

			pla				;Y-Koordinate zurücksetzen.
			sta	r1H

			jsr	PutString		;Text-String ausgeben.
			pla
			sta	r2L
			pla
			sta	r2H
			rts

;*** Steuercodes ausfiltern...
:DoPrntCode		cmp	#$1b
			bne	:102
::101			jmp	PutChar

::102			cmp	#$18
			beq	:101
			cmp	#$1a
			beq	:101
			rts
