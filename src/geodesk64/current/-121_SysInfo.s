; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konfiguration aus Datei laden.
:xSYSINFO		lda	GD_SYSINFO_MODE		;Infomodus einlesen.
			bne	:1
			jmp	prntSysInfo		;Drucker/Eingabe/Laufwerkinfo.
::1			jmp	prntTaskInfo		;Taskinfo anzeigen.

;*** Anzeigebereich löschen.
:resetInfoArea		lda	C_GTASK_PATTERN		;Füllmuster setzen.
			jsr	SetPattern

			jsr	i_Rectangle		;Infobereich löschen.
			b	TASKBAR_MIN_Y
			b	TASKBAR_MAX_Y
			w	TASKBAR_MIN_X
			w	TASKBAR_MAX_X

			jmp	ResetFontGD		;Zeichensatz zurücksetzen.

;*** TaskManager-Info anzeigen.

;--- TaskManager-Angaben.
;Die Informationen werden aus der
;TaskManager-Routine eingelesen.
:infoTaskData		= diskBlkBuf			;Zwischenspeicher.
:infoMaxTask		= infoTaskData +21		;Max. verfügbare Tasks.
:infoTActive		= infoTaskData +12
:infoTask00		= infoTaskData +22
:infoTask01		= infoTask00 +17
:infoTask02		= infoTask01 +17
:infoTask03		= infoTask02 +17
:infoTask04		= infoTask03 +17
:infoTask05		= infoTask04 +17
:infoTask06		= infoTask05 +17
:infoTask07		= infoTask06 +17
:infoTask08		= infoTask07 +17

:prntTaskInfo		jsr	SetADDR_TaskMan		;Zeiger auf TaskManager in DACC.

			LoadW	r0,infoTaskData		;Tabelle mit Taskdaten einlesen.
			LoadW	r2,$0100
			jsr	FetchRAM

			ldx	infoMaxTask		;Anzahl Tasks einlesen.
			cmp	#2			;Mehr als ein Task möglich?
			bcs	:0			; => Ja, weiter...
			rts				;Ende, nichts anzeigen.

::0			txa				;Anzahl zusätzlicher Tasks
			sec				;berechnen.
			sbc	#$01
			sta	:maxTask +1

			cpx	#8			;Zeiger auf Datentabelle
			bcs	:setTask8		;einlesen. Je nach Zahl der
			cpx	#6			;zusätzlichen Tasks in einer oder
			bcs	:setTask6		;mehreren Spalten anzeigen.
			cpx	#4
			bcs	:setTask4

::setTask2		ldx	#<infoTaskTab2		;Eine Spalte.
			ldy	#>infoTaskTab2
			bne	:setTaskDat

::setTask4		ldx	#<infoTaskTab4		;Zwei Spalten.
			ldy	#>infoTaskTab4
			bne	:setTaskDat

::setTask6		ldx	#<infoTaskTab6		;Drei Spalten.
			ldy	#>infoTaskTab6
			bne	:setTaskDat

::setTask8		ldx	#<infoTaskTab8		;Vier Spalten.
			ldy	#>infoTaskTab8
::setTaskDat		stx	r15L
			sty	r15H

			jsr	resetInfoArea		;Anzeigebereich löschen.

			lda	#0			;Zeiger auf Anfang.
::1			pha
			asl				;Zeiger auf Datentabelle berechnen.
			asl
			asl
			tay

			lda	(r15L),y		;X-Koordinate für Ausgabe.
			sta	r11L
			iny
			lda	(r15L),y
			sta	r11H
			iny
			lda	(r15L),y		;Y-Koordinate für Ausgabe.
			sta	r1H
			iny

			lda	(r15L),y		;Textbegrenzung rechts setzen.
			sta	rightMargin +0
			iny
			lda	(r15L),y
			sta	rightMargin +1
			iny

			lda	(r15L),y		;Zeiger auf Taskinfo.
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H
			iny
			lda	(r15L),y		;Zeiger auf Tabelle mit
			sta	r14H			;aktiven Tasks einlesen.
;			iny

			pla				;Taskadresse einlesen.
			pha
			clc				;Task 1: bis 8: ausgeben.
			adc	#"1"
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			ldx	r14H
			lda	infoTActive,x		;Ist Task belegt?
			bne	:2			; => Ja, weiter...

			LoadW	r0,freeTask		;Task frei: "-Frei -" anzeigen.

::2			jsr	PutString		;Infotext ausgeben.

			pla
			clc
			adc	#$01
::maxTask		cmp	#8			;Alle Infotexte ausgegeben?
			bcc	:1			; => Nein, weiter...

			jmp	WM_NO_MARGIN		;Textgrenzen löschen.

;*** Variablen.
if LANG = LANG_DE
:freeTask		b "-Frei -", NULL
endif
if LANG = LANG_EN
:freeTask		b "-Free -", NULL
endif

:infoTaskTab8		w TASKBAR_MIN_X +$0000 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MIN_X +$0032
			w infoTask01
			b 1

			w TASKBAR_MIN_X +$0000 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MIN_X +$0032
			w infoTask02
			b 2

			w TASKBAR_MIN_X +$0034 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MIN_X +$0066
			w infoTask03
			b 3

			w TASKBAR_MIN_X +$0034 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MIN_X +$0066
			w infoTask04
			b 4

			w TASKBAR_MIN_X +$0068 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MIN_X +$009a
			w infoTask05
			b 5

			w TASKBAR_MIN_X +$0068 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MIN_X +$009a
			w infoTask06
			b 6

			w TASKBAR_MIN_X +$009c +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MAX_X -2
			w infoTask07
			b 7

			w TASKBAR_MIN_X +$009c +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MAX_X -2
			w infoTask08
			b 8

:infoTaskTab6		w TASKBAR_MIN_X +$0000 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MIN_X +$0043
			w infoTask01
			b 1

			w TASKBAR_MIN_X +$0000 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MIN_X +$0043
			w infoTask02
			b 2

			w TASKBAR_MIN_X +$0045 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MIN_X +$0088
			w infoTask03
			b 3

			w TASKBAR_MIN_X +$0045 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MIN_X +$0088
			w infoTask04
			b 4

			w TASKBAR_MIN_X +$008a +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MAX_X -2
			w infoTask05
			b 5

			w TASKBAR_MIN_X +$008a +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MAX_X -2
			w infoTask06
			b 6

:infoTaskTab4		w TASKBAR_MIN_X +$0000 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MIN_X +$007e
			w infoTask01
			b 1

			w TASKBAR_MIN_X +$0000 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MIN_X +$007e
			w infoTask02
			b 2

			w TASKBAR_MIN_X +$0068 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MAX_X -2
			w infoTask03
			b 3

			w TASKBAR_MIN_X +$0068 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MAX_X -2
			w infoTask04
			b 4

:infoTaskTab2		w TASKBAR_MIN_X +$0000 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MAX_X -2
			w infoTask01
			b 1

			w TASKBAR_MIN_X +$0000 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MAX_X -2
			w infoTask02
			b 2

;*** Systeminformationen anzeigen.
:prntSysInfo		jsr	resetInfoArea		;Anzeigebereich löschen.

			jsr	i_BitmapUp		;Drucker/Maustreiber-Icon.
			w	devInfoIcon
			b	TASKBAR_MIN_X / 8
			b	TASKBAR_MIN_Y
			b	devInfoIcon_x
			b	devInfoIcon_y

			lda	#0			;Zeiger auf Anfang.
::1			pha
			asl				;Zeiger auf Datentabelle berechnen.
			asl
			asl
			tay

			lda	infoDataTab +0,y	;X-Koordinate für Ausgabe.
			sta	r11L
			lda	infoDataTab +1,y
			sta	r11H
			lda	infoDataTab +2,y	;Y-Koordinate für Ausgabe.
			sta	r1H

			lda	infoDataTab +3,y	;Textbegrenzung rechts setzen.
			sta	rightMargin +0
			lda	infoDataTab +4,y
			sta	rightMargin +1

			lda	infoDataTab +5,y	;Info-Typ einlesen.
			bne	:2			; => Laufwerk, weiter...

;--- Drucker/Eingabetreiber anzeigen.
			lda	infoDataTab +6,y	;Zeiger auf Name für Drucker
			sta	r0L			;oder Eingabetreiber.
			lda	infoDataTab +7,y
			sta	r0H

			jmp	:3			;Weiter zu Textausgabe.

;--- Laufwerksinfo anzeigen.
::2			pha				;Laufwerksadresse speichern.

			clc				;Laufwerk A: bis D: ausgeben.
			adc	#"A" -8
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			pla
			tay				;Laufwerksadresse zurücksetzen.

			PushW	r11			;Position für Textausgabe
			PushB	r1H			;zwischenspeichern.

			jsr	doGetDevType		;Laufwerkstyp ermitteln.

			PopB	r1H			;Position für Textausgabe
			PopW	r11			;zurücksetzen.

;--- Infotext ausgeben.
::3			jsr	PutString		;Infotext ausgeben.

			pla
			clc
			adc	#$01
			cmp	#6			;Alle Infotexte ausgegeben?
			bcc	:1			; => Nein, weiter...

			jmp	WM_NO_MARGIN		;Textgrenzen löschen.

;*** Variablen.
:infoDataTab

;--- Druckername.
			w TASKBAR_MIN_X +$0010 +2
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MIN_X +$004e
			b 0
			w PrntFilename

;--- Eingabetreiber.
			w TASKBAR_MIN_X +$0010 +2
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MIN_X +$004e
			b 0
			w inputDevName

;--- Laufwerkstyp #8-#11.
			w TASKBAR_MIN_X +$0050 +4
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MIN_X +$008e
			b 8
			w NULL

			w TASKBAR_MIN_X +$50 +4
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MIN_X +$008e
			b 9
			w NULL

			w TASKBAR_MIN_X +$90 +4
			b TASKBAR_MIN_Y +$00 +6
			w TASKBAR_MAX_X -2
			b 10
			w NULL

			w TASKBAR_MIN_X +$90 +4
			b TASKBAR_MIN_Y +$08 +6
			w TASKBAR_MAX_X -2
			b 11
			w NULL

;*** Icons.
:devInfoIcon
if FALSE
<MISSING_IMAGE_DATA>

endif
if TRUE
<MISSING_IMAGE_DATA>

endif

:devInfoIcon_x		= .x
:devInfoIcon_y		= .y
