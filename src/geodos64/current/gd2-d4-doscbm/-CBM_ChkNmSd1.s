; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Unterverzeichnis-Header überprüfen.
;Version #1: Prüft nur das aktuelle Unterverzeichnis.
:VerifyNMDir		lda	curType			;Laufwerkstyp einlesen.
			and	#%00000111
			cmp	#$04			;NativeMode ?
			beq	:98			; => Ja, weiter...
			rts

::98			jsr	ClrBox			;Bildschirm löschen.

			jsr	DoInfoBox		;Infotext ausgeben.
			PrintStrgDlgChkSubD

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:99			; => Ja, Abbruch...

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O aktivieren.

			LoadW	r4,diskBlkBuf

			lda	curDirHead +0		;Zeiger auf ersten vVerzeichnis-
			ldx	curDirHead +1		;Sektor einlesen.

;--- Verzeichnis-Sektoren einlesen.
::101			sta	r1L			;Verzeichnis-Sektor setzen.
			stx	r1H
			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler?
			beq	:102			; => Nein, weiter...
::100			jsr	DoneWithIO		;I/O abschalten und
::99			jmp	DiskError		;Diskettenfehler ausgeben.

;--- Verzeichnis-Einträge überprüfen.
::102			ldy	#$02
			lda	(r4L),y			;Dateityp einlesen.
			beq	:103			; => $00, keine Datei.
			and	#%00001111
			cmp	#$06			;Typ "Verzeichnis"?
			bne	:103			; => Nein, weiter...

			jsr	UpdateHeader		;Verzeichnis-Header aktualisieren.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch...

::103			clc				;Zeiger auf nächsten Eintrag.
			lda	r4L
			adc	#$20
			sta	r4L			;Sektor-Ende erreicht?
			bne	:102			; => Nein, weiter...

			ldx	diskBlkBuf +1		;Zeiger auf nächsten Sektor einlesen.
			lda	diskBlkBuf +0		;Letzter Verzeichnis-Sektor?
			bne	:101			; => Nein, weiter...

			jmp	DoneWithIO		;I/O abschalten und Ende.

;*** Verzeichnis-Header einlesen und anpassen.
:UpdateHeader		MoveB	r1L,r11L		;Zeiger auf aktuellen
			MoveB	r1H,r11H		;Verzeichnis-Eintrag sichern.
			MoveB	r4L,r14L
			MoveB	r4H,r14H

			ldy	#$03
			lda	(r4L),y			;Track/Sektor für neuen
			sta	r1L			;Verzeichnis-Header setzen.
			iny
			lda	(r4L),y
			sta	r1H
			LoadW	r4,fileHeader		;Zeiger auf Zwischenspeicher.
			jsr	ReadBlock		;Verzeichnis-Header einlesen.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			lda	r11L			;Zeiger auf zugehörigen Eltern-
			sta	fileHeader +36		;Verzeichnis-Sektor in Header
			lda	r11H			;übertragen.
			sta	fileHeader +37
			lda	r14L			;Zeiger auf Verzeichnis-Eintrag
			clc				;in Header übertragen.
			adc	#$02			;(Byte zeigt auf Byte#0=Dateityp).
			sta	fileHeader +38

			jsr	WriteBlock		;Verzeichnis-Header schreiben.
			txa
			bne	:101

			MoveB	r11L,r1L		;Zeiger auf aktuellen
			MoveB	r11H,r1H		;Verzeichnis-Eintrag zurücksetzen.
			MoveB	r14L,r4L
			MoveB	r14H,r4H

::101			rts

;*** Texte für Infoboxen.
if Sprache = Deutsch
:DlgChkSubD		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Unterverzeichnisse"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "überprüfen..."
			b NULL
endif

if Sprache = Englisch
:DlgChkSubD		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Checking directory"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "header..."
			b NULL
endif
