; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Alle Laufwerkstreiber kopieren.
:CopyDskDev		jsr	CalcAllDkDev

			lda	TargetNeedB +1		;Genügend Speicher frei?
			cmp	TargetFreeB +1
			bne	:51
			lda	TargetNeedB +0
			cmp	TargetFreeB +0
::51			bcc	:52			; => Ja, weiter...

			LoadW	r0,DLG_INSUFFSPACE
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			jmp	CopySlctDkDv		;Laufwerkstreiber auswählen.

::52			jsr	CopyDskDevFile		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.

:CopyDskDevFile		lda	#$ff
			sta	CopyFlgDskDrive
			lda	#< Inf_CopyDskDrv
			ldx	#> Inf_CopyDskDrv
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$03			;Laufwerkstreiber aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** Zu kopierende Laufwerkstreiber wählen.
:CopySlctDkDv		jsr	ClearScrnArea		;Menü-/Status-Fenster löschen.
			jsr	ClearInfoArea		;Anzeigebereich löschen.
			jsr	PrntCurDkSpace		;Freien Speicher ausgeben.

			jsr	CalcDkDevSpace		;Benötigten Speicher berechnen.
			jsr	PrntRequiredKB		;Speicherbedarf anzeigen.

			LoadW	r0,mnuSlctDisk		;Menü ausgeben.
			jsr	DoColorIcons
			LoadW	r0,txSlctDisk1
			jsr	PutString

			jsr	SetVecTopArchiv		;Zeiger auf erste Setup-Datei.

;--- Aktuellen Treiber anzeigen und Abfrage starten.
:PrntCurDkDev		lda	EntryPosInArchiv
			asl
			tax
			lda	FileModeTab +0,x
			cmp	#$03			;Datei vom Typ Laufwerkstreiber ?
			bne	SkipDkDrv		; => Nein, weiter...

::found			lda	FileNameTab +0,x	;Zeiger Dateiname setzen.
			sta	a1L
			lda	FileNameTab +1,x
			sta	a1H

			jmp	PrntDkDrvName		;Dateiname anzeigen.

;--- Treiber nicht kopieren.
:ReSlctDkDrv		lda	#$ff
			b $2c

;--- Zeiger auf nächste Datei.
:NextDkDrv		lda	#$00

			ldy	#$00
			sta	(a7L),y			;Auswahl speichern.
			pha

			lda	EntryPosInArchiv
			asl
			tax
			lda	FileModeTab +1,x	;Laufwerkstreiber erforderlich ?
			bne	:1			; => Nein, weiter...

			lda	TargetNeedB +0		;Speicherbedarf korrigieren.
			sec
			sbc	a2L
			sta	TargetNeedB +0
			lda	TargetNeedB +1
			sbc	a2H
			sta	TargetNeedB +1

::1			pla				;Laufwerkstreiber kopieren ?
			bne	:2			; => Nein, weiter...

			lda	TargetNeedB +0		;Speicherbedarf korrigieren.
			clc
			adc	a2L
			sta	TargetNeedB +0
			lda	TargetNeedB +1
			adc	a2H
			sta	TargetNeedB +1

::2			jsr	PrntRequiredKB		;Benötigten Speicher anzeigen.

:SkipDkDrv		jsr	SetVecNxEntry		;Alle Laufwerkstreiber gewählt ?
			bne	PrntCurDkDev		; => Nein, weiter...

			jmp	InitCopyDkDv		;Ausgewählte Treiber kopieren.

;*** Speicherbedarf berechnen.
:CalcDkDevSpace		lda	#$00			;Nur empfohlene Laufwerkstreiber.
			b $2c
:CalcAllDkDev		lda	#$ff			;Alle Laufwerkstreiber.
			sta	a3L

			lda	#$00			;Benötigten Speicher löschen.
			sta	TargetNeedB +0
			sta	TargetNeedB +1

			jsr	SetVecTopArchiv		;Zeiger auf erste Datei.

::loop			lda	EntryPosInArchiv
			asl
			tax
			lda	FileModeTab +0,x
			cmp	#$03			;Datei vom Typ Laufwerkstreiber ?
			bne	:next			; => Nein, weiter...

			ldy	#$00
			tya
			bit	a3L			;Max. Speicher ermitteln ?
			bmi	:1			; => ja, weiter...
			lda	FileModeTab +1,x
::1			sta	(a7L),y			;Empfohlener Laufwerkstreiber ?
			cmp	#$00
			bne	:next			; => Nein, weiter...

			ldy	#30			;Dateigröße addieren.
			lda	(a7L),y
			clc
			adc	TargetNeedB +0
			sta	TargetNeedB +0
			iny
			lda	(a7L),y
			adc	TargetNeedB +1
			sta	TargetNeedB +1

::next			jsr	SetVecNxEntry		;Alle Laufwerkstreiber geprüft ?
			bne	:loop			; => Nein, weiter...

			rts

;*** Name Laufwerkstreiber ausgeben.
:PrntDkDrvName		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$68,$77
			w	$0020,$011f

			LoadW	r11,$0020
			LoadB	r1H,$70
			MoveW	a1,r0
			jsr	PutString

;--- Größe Laufwerkstreiber ausgeben.
::prntDkDrvSize		LoadW	r0,txSlctDisk2
			jsr	PutString

			ldy	#30
			lda	(a7L),y
			sta	r0L
			iny
			lda	(a7L),y
			sta	r0H

			lsr	r0H
			ror	r0L
			lsr	r0H
			ror	r0L

			MoveW	r0,a2

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			LoadW	r0,txSlctDisk3
			jsr	PutString

			lda	EntryPosInArchiv
			asl
			tax
			lda	FileModeTab +1,x	;Empfohlener Laufwerkstreiber?
			bne	:1			; => Nein, weiter...

			lda	#"*"			;Markierung für "Empfohlen".
			jsr	SmallPutChar

::1			rts

;*** Freien Speicher ausgeben.
:PrntRequiredKB		LoadW	r0,InfoText6a
			jsr	PutString

			MoveW	TargetNeedB,r0

			lsr	r0H			;Anzahl Blocks in KByte umrechnen.
			ror	r0L
			lsr	r0H
			ror	r0L

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Freien Speicher ausgeben.

			lda	#"K"
			jsr	SmallPutChar
			lda	#" "
			jmp	SmallPutChar

;*** Ausgewählte Laufwerkstreiber entpacken.
:InitCopyDkDv		lda	TargetNeedB +1		;Genügend Speicher frei?
			cmp	TargetFreeB +1
			bne	:51
			lda	TargetNeedB +0
			cmp	TargetFreeB +0
::51			bcc	:52

			LoadW	r0,DLG_INSUFFSPACE
			jsr	DoDlgBox
			jmp	CopySlctDkDv

::52			lda	#$ff
			sta	CopyFlgDskDrive
			lda	#< Inf_CopyDskDrv
			ldx	#> Inf_CopyDskDrv
			jsr	ViewInfoBox		;Infomeldung ausgeben.

			jsr	SetVecTopArchiv

;--- Aktuellen Treiber anzeigen und Abfrage starten.
::loop			lda	EntryPosInArchiv
			asl
			tax
			lda	FileModeTab +0,x
			cmp	#$03
			bne	:next

			ldy	#$00
			lda	(a7L),y
			bne	:next

			jsr	Decode1File		;Treiber entpacken.
			txa
			bne	:error

			lda	EntryPosInArchiv	;Gruppenkennung löschen.
			asl
			tax
			lda	#$00
			sta	FileModeTab +0,x

;--- Zeiger auf nächste Datei.
::next			jsr	SetVecNxEntry
			bne	:loop

			jmp	CopyMenu		;zurück zum Hauptmenü.

::error			jmp	EXTRACT_ERROR

;*** Systemvariablen.
:SelectDrvSize		w $0000

:InfoText6a		b PLAINTEXT
			b GOTOXY
			w $0018
			b $44
if LANG = LANG_DE
			b "Für aktuelle Auswahl erforderlich: "
endif
if LANG = LANG_EN
			b "Required for current selection: "
endif
			b NULL

;*** Dialogbox: Nicht genügend freier Speicher.
:DLG_INSUFFSPACE	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w :11
			b DBTXTSTR ,$10,$20
			w :12
			b DBTXTSTR ,$10,$2c
			w :13
			b OK       ,$10,$48
			b NULL

if LANG = LANG_DE
::11			b PLAINTEXT, BOLDON
			b "FEHLER!"
			b PLAINTEXT
			b NULL
::12			b "Nicht genügend Speicher frei, um",NULL
::13			b "alle Laufwerkstreiber zu kopieren!",NULL
endif
if LANG = LANG_EN
::11			b PLAINTEXT, BOLDON
			b "ERROR!"
			b PLAINTEXT
			b NULL
::12			b "Not enough disk space available",NULL
::13			b "to copy all disk drivers!",NULL
endif

;*** Laufwerkstreiber auswählen.
:mnuSlctDisk		b $04
			w $0000
			b $00

			w Icon_10
			b Icon4x1 ,Icon4y
			b Icon_10x,Icon_10y
			w NextDkDrv

			w Icon_11
			b Icon4x2 ,Icon4y
			b Icon_11x,Icon_11y
			w ReSlctDkDrv

			w Icon_07
			b Icon4x3 ,Icon4y
			b Icon_07x,Icon_07y
			w InitCopyDkDv

			w Icon_14
			b Icon4x4 ,Icon4y
			b Icon_12x,Icon_12y
			w SlctDskCopyMode

;*** Laufwerkstreiber auswählen.
:txSlctDisk1		b PLAINTEXT
			b GOTOXY
			w $0018
			b $58
if LANG = LANG_DE
			b "Soll der folgende Laufwerkstreiber auf der"
endif
if LANG = LANG_EN
			b "Should the following disk-driver be installed"
endif
			b GOTOXY
			w $0018
			b $60
if LANG = LANG_DE
			b "Startdiskette installiert werden ?"
endif
if LANG = LANG_EN
			b "to the bootdisk ?"
endif
			b GOTOXY
			w $0018
			b $80
if LANG = LANG_DE
			b "* = Installation empfohlen"
endif
if LANG = LANG_EN
			b "* = Installation recommended"
endif

			b GOTOXY
			w IconT4x1
			b IconT4y1
if LANG = LANG_DE
			b "Kopieren"
endif
if LANG = LANG_EN
			b "Copy"
endif

			b GOTOXY
			w IconT4x2
			b IconT4y1
if LANG = LANG_DE
			b "Nicht"
endif
if LANG = LANG_EN
			b "Do not"
endif
			b GOTOXY
			w IconT4x2
			b IconT4y2
if LANG = LANG_DE
			b "Kopieren"
endif
if LANG = LANG_EN
			b "Copy"
endif

			b GOTOXY
			w IconT4x3
			b IconT4y1
if LANG = LANG_DE
			b "Installation"
endif
if LANG = LANG_EN
			b "Continue with"
endif
			b GOTOXY
			w IconT4x3
			b IconT4y2
if LANG = LANG_DE
			b "fortsetzen"
endif
if LANG = LANG_EN
			b "installation"
endif

			b GOTOXY
			w IconT4x4
			b IconT4y1
if LANG = LANG_DE
			b "Auswahl"
endif
if LANG = LANG_EN
			b "Restart"
endif
			b GOTOXY
			w IconT4x4
			b IconT4y2
if LANG = LANG_DE
			b "ändern"
endif
if LANG = LANG_EN
			b "menu"
endif
			b NULL

if LANG = LANG_DE
:txSlctDisk2		b "  ( Dateigröße: ",NULL
:txSlctDisk3		b "K ) ",NULL
endif
if LANG = LANG_EN
:txSlctDisk2		b "  ( File size: ",NULL
:txSlctDisk3		b "K ) ",NULL
endif
