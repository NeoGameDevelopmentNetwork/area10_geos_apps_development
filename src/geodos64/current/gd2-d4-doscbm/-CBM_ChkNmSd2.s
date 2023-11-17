; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Unterverzeichnis-Header überprüfen.
;Version #2: Prüft das gesamte Verzeichnis.
:VerifyNMDir		lda	curType			;Laufwerkstyp einlesen.
			and	#%00000111
			cmp	#$04			;NativeMode ?
			beq	:97			; => Ja, weiter...
			rts

::97			jsr	ClrBox			;Bildschirm löschen.

			jsr	DoInfoBox		;Infotext ausgeben.
			PrintStrgDlgChkSubD

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:99			; => Ja, Abbruch...

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O aktivieren.

			ldx	#$00			;Verzeichnis-Ebene zurücksetzen.
			stx	DirLevel
			txa
			sta	DirParentTr,x		;Tabelle mit Verzeichns-Daten
			sta	DirParentSe,x		;initialisieren.
			sta	DirEntryTr ,x
			sta	DirEntrySe ,x
			sta	DirEntryByt,x
			inx				;Zeiger auf ersten Verzeichnis-
			txa				;Sektor (ROOT) setzen.

;--- Neues Verzeichnis beginnen.
::98			ldy	DirLevel		;Start-Sektor in Tabelle schreiben.
			sta	DirRootTr  ,y		;$01/$01 bei ROOT, sonst Header für
			sta	r1L			;aktuelles Unterverzeichnis.
			txa
			sta	DirRootSe  ,y
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf Datenspeicher.
			jsr	ReadBlock		;Header-Sektor einlesen.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch...

			lda	diskBlkBuf +0		;Zeiger auf ersten vVerzeichnis-
			ldx	diskBlkBuf +1		;Sektor einlesen.

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

			ldx	#$04			;Fehler: "Full directory?"
			ldy	DirLevel		;Level-Zähler erhöhen.
			cpy	#15			;Max. Schachteltiefe erreicht?
			beq	:99			; => Ja, Fehler...
			iny				;Verschachtelung +1.
			sty	DirLevel		;(In Unterverzeichnis wechseln)
			jsr	UpdateHeader		;Verzeichnis-Header aktualisieren.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch...

			ldx	r1H			;Zeiger auf neuen Verzeichnis-Header
			lda	r1L			;einlesen. Ende erreicht?
			bne	:98			; => Nein, neues Berzeichnis beginnen.
			beq	:104			; => Verzeichnis-Ende erreicht.

::103			clc				;Zeiger auf nächsten Eintrag.
			lda	r4L
			adc	#$20
			sta	r4L			;Sektor-Ende erreicht?
			bne	:102			; => Nein, weiter...

			ldx	diskBlkBuf +1		;Zeiger auf nächsten Sektor einlesen.
			lda	diskBlkBuf +0		;Letzter Verzeichnis-Sektor?
			bne	:101			; => Nein, weiter...

::104			ldx	DirLevel		;ROOT-Verzeichnis?
			beq	:106			; => Ja, Ende...

			lda	DirEntryTr ,x		;Zeiger auf letzte Position im
			sta	r1L			;Eltern-Verzeichnis setzen.
			lda	DirEntrySe ,x
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	ReadBlock		;Sektor wieder einlesen.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch.
			ldx	DirLevel		;Zeiger auf zuletzt geprüften
			lda	DirEntryByt,x		;Verzeichnis-Eintrag.
			sta	r4L
			dec	DirLevel		;Verschachtelung -1.
			jmp	:103			;Aktuelles Verzeichnis weiter testen.

::106			jmp	DoneWithIO		;I/O abschalten und Ende.

;*** Verzeichnis-Header einlesen und anpassen.
:UpdateHeader		ldx	DirLevel		;Zeiger auf Datentabelle einlesen.
			dex
			lda	DirRootTr  ,x		;Header des vorherigen Verzeichnisses
			inx				;als Zeiger auf Eltern-Verzeichnis
			sta	DirParentTr,x		;setzen.
			dex
			lda	DirRootSe  ,x
			inx
			sta	DirParentSe,x

			lda	r1L			;Position im Eltern-Verzeichnis
			sta	DirEntryTr ,x		;für aktuelles Verzeichnis merken.
			lda	r1H
			sta	DirEntrySe ,x
			lda	r4L
			sta	DirEntryByt,x

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

			lda	r1L			;Track/Sektor für Header des aktuellen
			sta	fileHeader +32		;Verzeichnisses in Header übertragen.
			lda	r1H
			sta	fileHeader +33

			ldx	DirLevel		;Track/Sektor für Header des Eltern-
			lda	DirParentTr,x		;Verzeichnisses in Header übertragen.
			sta	fileHeader +34
			lda	DirParentSe,x
			sta	fileHeader +35

			lda	DirEntryTr ,x		;Zeiger auf zugehörigen Eltern-
			sta	fileHeader +36		;Verzeichnis-Sektor in Header
			lda	DirEntrySe ,x		;übertragen.
			sta	fileHeader +37
			lda	DirEntryByt,x		;Zeiger auf Verzeichnis-Eintrag
			clc				;in Header übertragen.
			adc	#$02			;(Byte zeigt auf Byte#0=Dateityp).
			sta	fileHeader +38

			jmp	WriteBlock		;Verzeichnis-Header schreiben.
::101			rts

:DirLevel		b $00
:DirRootTr		s 16
:DirRootSe		s 16
:DirParentTr		s 16
:DirParentSe		s 16
:DirEntryTr		s 16
:DirEntrySe		s 16
:DirEntryByt		s 16

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
