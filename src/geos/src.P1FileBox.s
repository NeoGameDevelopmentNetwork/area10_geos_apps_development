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

endif

			n "PatchFileBox.1"
			c "VisionPatch V1.0"
			a "M. Kanet"

			f $06
			z $80

			o DB_GetFiles
			p EnterDeskTop

			i
<MISSING_IMAGE_DATA>

;*** Neue DB_GetFiles-Routine!
:MainInit		ldy	r1L
			lda	(DB_VecDefTab),y	;X-Koordinate für GetFile-
			sta	DB_GetFileX		;Fenster einlesen.
			iny
			lda	(DB_VecDefTab),y	;X-Koordinate für GetFile-
			sta	DB_GetFileY		;Fenster einlesen.
			iny
			tya
			pha

			MoveW	r5,DB_FileTabVec	;Zeiger auf Zwischenspeicher
							;für Dateiname merken.

			jsr	DB_FileWinPos		;GetFile-Fenster berechnen.

			lda	r2H			;Trennlinie berechnen.
			sec
			sbc	#FileWinIconArea
			pha

			lda	r7L			;Register ":r7" und ":r10"
			pha				;zwischenspeichern.
			lda	r10H
			pha
			lda	r10L
			pha

			lda	#$ff			;GetFile-Fenster zeichnen.
			jsr	FrameRectangle

			sec
			lda	r2H
			sbc	#$10
			sta	r11L

			lda	#$ff			;Trennlinie zeichnen.
			jsr	HorizontalLine

			lda	#"1"			;SwapFile-Header
			sta	SwapFileName +5		;erzeugen.

			lda	#$83
			sta	fileHeader+$44
			lda	#> $7900
			sta	fileHeader+$48
			lda	#< $7900
			sta	fileHeader+$47
			sta	fileHeader+$46
			sta	DB_WinLastFile
			sta	DB_WinFirstFile
			sta	fileHeader+$49
			lda	#$7f
			sta	fileHeader+$4a

			jsr	SaveSwapFile		;SwapFile erzeugen.

			lda	#< $c072		;":RstrFrmDialogue" auf neue
			sta	xRstrFrmDialogue +1	;Routine umlenken.
			lda	#> $c072
			sta	xRstrFrmDialogue +2

			pla				;Register ":r7" und ":r10"
			sta	r10L			;zurücksetzen.
			pla
			sta	r10H
			pla
			sta	r7L

			LoadB	r7H,90
			LoadW	r6 ,$7900
			jsr	FindFTypes		;Dateien suchen.

			pla
			sta	r2L

			lda	#$0f
			sta	r3L

			lda	#$5a			;Anzahl gefundener Dateien
			sec				;berechnen.
			sbc	r7H			;Dateien gefunden ?
			beq	lf73f			;Nein, weiter...
			sta	DB_FilesInTab		;Anzahl Dateien merken.

			cmp	#FilesInWindow +1	;Weniger als 6 Dateien ?
			bcc	lf72f			;Ja, weiter...

			LoadW	r5,DB_GetFileIcon	;Rollpfeil-Icon in
			jsr	DB_CopyIconInTab	;Icon-Tabelle kopieren.

:lf72f			lda	#< DB_SlctNewFile	;Mausabfrage installieren.
			sta	otherPressVec  +0
			lda	#> DB_SlctNewFile
			sta	otherPressVec  +1

			jsr	DB_PutFileNames
			jsr	DB_FileInBuf

:lf73f			pla
			sta	r1L
:lf742			rts

;*** Neue Datei wählen.
.DB_SlctNewFile		lda	mouseData		;Maustaste gedrückt ?
			bmi	lf742			;Nein, Ende...

			jsr	DB_FileWinPos		;GetFile-Fenster berechnen.

			clc				;Mauszeiger im
			lda	r2L			;Dateifenster-Bereich ?
			adc	#(FileWinYsize-19)
			sta	r2H
			jsr	IsMseInRegion
			beq	lf742			;Nein, Ende...

			jsr	DB_InvSlctFile
			jsr	DB_FileWinPos		;GetFile-Fenster berechnen.

			lda	mouseYPos		;Zeiger auf Bereich für
			sec				;gewählten Datei-Eintrag
			sbc	r2L			;berechnen.
			sta	r0L
			lda	#$00
			sta	r0H
			sta	r1H
			lda	#FileEntryHigh
			sta	r1L

			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	r0L			;Mausklick auf freiem Bereich
			clc				;des Datei-Fensters ?
			adc	DB_WinFirstFile
			cmp	DB_FilesInTab
			bcc	lf785			;Nein, weiter...

			ldx	DB_FilesInTab		;Letzte Datei in Tabelle
			dex				;wählen.
			txa

:lf785			sta	DB_WinLastFile		;Gewählte Datei speichern.
			cmp	FileDblClick		;Wurde die gleiche Datei
			bne	lf792			;doppelgeklickt ? Nein, weiter.

			lda	dblClickCount		;Doppelklickzähler aktiv ?
			bne	lf79d			;Ja, Datei öffnen.

:lf792			sta	FileDblClick		;Datei für Doppelklick löschen.

			lda	#$3c			;Zähler für Doppelklick
			sta	dblClickCount		;auf Startwert setzen.
			jmp	DB_FileInBuf		;Gewählte datei in Zwischen-
							;speicher kopieren...
:lf79d			jmp	DB_Icon_OPEN

:FileDblClick		b $00				;Dateispeicher nach erstem
							;Doppelklick.

;*** Icon-Eintrag für Rollpfeile.
.DB_GetFileIcon		w DB_ArrowGrafx
			b $0f,$00,$03,$0c
			w DB_MoveFileList

;*** Icon-Grafik für Rollpfeile.
.DB_ArrowGrafx		b $03,$ff,$9e
			b $80,$00,$01,$80
			b $00,$01,$82,$00
			b $e1,$87,$07,$fd
			b $8f,$83,$f9,$9f
			b $c1,$f1,$bf,$e0
			b $e1,$87,$00,$41
			b $80,$00,$01,$80
			b $00,$01,$03,$ff

;*** Mausklick auswerten.
.DB_MoveFileList	jsr	DB_InvSlctFile		;Datei-Eintrag zurücksetzen.

			ldx	#$40			;Pause einfügen.
:lf7d1			ldy	#$00
:lf7d3			dey
			bne	lf7d3
			dex
			bne	lf7d1

			jsr	UpdateMouse		;Maus aktualisieren.

			ldy	#$00
			lda	pressFlag
			and	#%00100000		;Wurde Maustaste gedrückt ?
			beq	lf7e5			;Nein, weiter...
			dey				;Doppelklick!

:lf7e5			ldx	DB_WinFirstFile
			lda	#$00			;Mauszeiger links/rechts
			cmp	mouseXPos +1		;von Rollbalken ?
			bne	lf7f2
			lda	#$84
			cmp	mouseXPos +0

:lf7f2			jsr	DB_DoubleClick		;Doppelklick ?
			bcc	lf7fa			;Zum Anfang ? Nein, weiter...
			dex				;Zeiger auf erste Datei
			bpl	lf806			;berechnen, weiter...

:lf7fa			inx				;Zeiger auf nächste Datei.
			lda	DB_FilesInTab
			sec
			sbc	DB_WinFirstFile
			cmp	#FilesInWindow +1	;Nächste Datei verfügbar ?
			bcc	lf809			;Nein, -> weiter...

:lf806			stx	DB_WinFirstFile		;Neue erste Datei in
							;Tabelle merken.

:lf809			lda	DB_WinFirstFile		;Gewählte Datei noch
			cmp	DB_WinLastFile		;innerhalb des Datei-Fensters ?
			bcc	lf814			;Ja, weiter...
			sta	DB_WinLastFile		;Neue erste Datei merken.

:lf814			clc				;Zeiger auf letzte Datei in
			adc	#FilesInWindow -1	;Datei-Fenster berechnen.
			cmp	DB_WinLastFile		;Gewählte Datei im Fenster ?
			bcs	lf81f			;Ja, weiter...
			sta	DB_WinLastFile		;Neue letzte Datei merken.

:lf81f			jsr	DB_PutFileNames		;Dateinamen ausgeben.

			lda	DB_WinFirstFile		;Zeiger am Anfang der Tabelle ?
			beq	DB_FileInBuf		;Ja, weiter...

			lda	DB_FilesInTab
			sec
			sbc	DB_WinFirstFile
			cmp	#FilesInWindow		;Zeiger am Ende der Tabelle ?
			beq	DB_FileInBuf		;Ja, weiter...

			lda	mouseData		;Dauerfunktion ?
			bpl	lf7e5			;Ja, weiter...

;*** Dateieintrag in Zwischenspeicher.
.DB_FileInBuf		lda	DB_WinLastFile		;Zeiger auf Datei in
			jsr	$c0a6			;Dateitabelle berechnen.

			ldy	#r1L			;Eintrag in Zwischenspeicher
			jsr	CopyString		;kopieren.

;*** Gewählte Datei invertieren.
.DB_InvSlctFile		lda	DB_WinLastFile		;Zeiger auf Eintrag in
			sec				;Dateifenster berechnen.
			sbc	DB_WinFirstFile
			jsr	DB_SetWinEntry		;Grenzen für Eintrag berechnen.
			jmp	InvertRectangle		;Eintrag invertieren.

;*** Doppelklick auf Rollpfeil auswerten.
.DB_DoubleClick		tya				;Doppelklick ?
			beq	lf860			;Nein, weiter...
			bcc	lf858			;Zur letzten Datei ? -> Weiter!
			ldx	#$01			;Zeiger auf erste Datei +1.
			sec				;Zum Anfang der Tabelle.
			rts

:lf858			lda	DB_FilesInTab		;Zeiger auf letzte Datei +1.
			sec
			sbc	#FilesInWindow +1
			tax
			clc				;Zum Ende der Tabelle.
:lf860			rts

;*** Zeiger auf dateinamen berechnen.
.DB_SetFileNam		tay
			lda	#> $7900
			sta	zpage +1,x
			lda	#< $7900
			sta	zpage +0,x

:lf86a			dey
			bmi	lf860

			lda	zpage +0,x
			clc
			adc	#$11
			sta	zpage +0,x
			bcc	lf86a
			inc	zpage +1,x
			bne	lf86a

;*** Dateitabelle anzeigen.
.DB_PutFileNames	lda	#$00			;Zeiger auf ersten Dateieintrag
			jsr	DB_SetWinEntry		;In Dateifenster.

			lda	#$00			;Füllmuster #0 um Bereich
			sta	r15L			;für Datei-Eintrag zu löschen.
			jsr	SetPattern

			lda	DB_WinFirstFile		;Zeiger auf ersten Eintrag
			ldx	#r14L			;in Datei-Fenster berechnen.
			jsr	DB_SetFileNam

			lda	#%01000000		;BOLD für Text-Ausgabe setzen.
			sta	currentMode

:lf892			lda	r15L			;Grenzen für Bereich des
			jsr	DB_SetWinEntry		;Datei-Eintrages in Tabelle.
			jsr	Rectangle		;Bereich löschen...

			lda	r2L			;Zeiger auf Y-Koordinate
			clc				;für Text-Ausgabe berechnen.
			adc	#$09
			sta	r1H
			MoveW	r3 ,r11			;X-Koordinate setzen.
			MoveW	r14,r0			;Zeiger auf Dateiname.
			jsr	PutString		;Dateinamen ausgeben.

			clc				;Zeiger auf nächsten
			lda	#$11			;Dateinamen berechnen.
			adc	r14L
			sta	r14L
			bcc	lf8bf
			inc	r14H

:lf8bf			inc	r15L			;Anzahl Dateien im Fenster +1.
			lda	r15L
			cmp	#FilesInWindow		;Alle Dateien ausgegeben ?
			bne	lf892			;Nein, weiter...
:lf8c7			rts

;*** Grenzen für GetFile-Fenster berechnen.
.DB_FileWinPos		clc				;Position der Dialogbox
			jsr	DB_DefBoxPos		;berechnen.

			clc				;Linke X-Koordinate für
			lda	DB_GetFileX		;GetFile-Fenster berechnen.
			adc	r3L
			sta	r3L
			bcc	:101
			inc	r3H

::101			clc				;Rechte X-Koordinate für
			adc	#< FileWinXsize		;GetFile-Fenster berechnen.
			sta	r4L
			lda	#> FileWinXsize
			adc	r3H
			sta	r4H

			lda	DB_GetFileY		;Obere Y-Koordinate für
			clc				;GetFile-Fenster berechnen.
			adc	r2L
			sta	r2L
			adc	#FileWinYsize		;Untere Y-Koordinate für
			sta	r2H			;GetFile-Fenster berechnen.
			rts

;*** Grenzen für Dateieintrag berechnen.
.DB_SetWinEntry		sta	r0L			;Relative Y-Koordinate für
			lda	#FileEntryHigh		;Datei-Eintrag in Fenster
			sta	r1L			;berechnen.
			ldy	#r1L
			ldx	#r0L
			jsr	BBMult

			jsr	DB_FileWinPos		;GetFile-Fenster berechnen.

			clc				;Obere/Untere Grenze für
			lda	r0L			;Datei-Eintrag berechnen.
			adc	r2L
			sta	r2L
			clc
			adc	#FileEntryHigh
			sta	r2H
			inc	r2L

			inc	r3L			;Linke/Rechte Grenze für
			bne	lf914			;Datei-Eintrag berechnen.
			inc	r3H
:lf914			ldx	#r4L
			jmp	Ddec
