; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; UCI: $14 DOS_CMD_READ_DIR
;
;Übergabe : r6  = Zeiger auf Verzeichnisspeicher
;           r7L = Bit%7=1: Verzeichnisse
;                 Bit%6=1: Dateien
;                 Bit%5=1: Datei-Informationen
;           r7H = Max. Anzahl
;           r8  = Zeiger auf Tabelle Verzeichniseinträge
;           r10 = .ext (.d64 oder .D64)
;                 $0000: Nicht filtern
;Rückgabe : r6  = Zeiger auf Verzeichnisspeicher
;                 Byte#00: Dateityp
;                 Byte#12: Dateiname
;                 Wenn r7L/Bit%5=1 (Datei-Informationen):
;                 Byte#01: Dateigröße (2 Bytes)
;                 Byte#03: Datum (3 Bytes)
;                 Byte#06: Uhrzeit (3 Bytes)
;                 Byte#09: Erweiterung (3 Bytes)
;           r7H = Rest Anzahl Verzeichniseinträge
;           r8  = Zeiger auf Tabelle Verzeichniseinträge
;                 Tabelle mit 256 Words:
;                 Low-/High-Byte als zeiger auf die
;                 Startadresse der Verzeichniseinträge
;                 Die Tabelle wird zu Beginn mit
;                 $00-Bytes gelöscht = Kein Eintrag.
;           X   = Fehlerstatus, $00=OK
;                 UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r4,r5,r7H,r12,r13,r14,r15L,UCI_DATA_MSG

:_UCID_READ_DIR

			lda	r6L			;Zeiger auf Verzeichnisliste
			sta	r12L			;zwischenspeichern.
			lda	r6H
			sta	r12H

			lda	r8L			;Zeiger auf Verzeichnistabelle
			sta	r13L			;zwischenspeichern.
			lda	r8H
			sta	r13H

			lda	r0H			;Datenregister zwischenspeichern.
			pha
			lda	r0L
			pha

;--- Verzeichnistabelle löschen.
::init			ldx	#2			;Verzeichnistabelle
			ldy	#0			;initialisieren.
			tya
::1			sta	(r13),y
			iny
			bne	:1
			dex
			beq	:2
			inc	r13H
			bne	:1
::2			dec	r13H

;--- Verzeichnis-Befehl senden.
			lda	UCI_TARGET		;Befehl an UCI senden.
			sta	UCI_COMDATA
			lda	#DOS_CMD_READ_DIR
			sta	UCI_COMDATA

			jsr	ULIB_PUSH_CMD		;Befehl ausführen.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			tya
			and	#CMD_STATE_BITS		;Daten vorhanden?
			beq	:ok			; => Nein, Ende...

;--- Verzeichnis-Einträge einlesen.
;Status muss nicht abgefragt werden,
;das Verzeichnisende wird über DATA
;mitgeteilt. DATA_LAST zeigt an das
;noch ein letztes Element folgt.
::next			sty	r0H			;Status IDLE/BUSY/DLAST/DMORE.

;--- Hinweis:
;Zum einlesen des Dateinamen wird ein
;NULL-Byte am Ende benötigt.
;			jsr	ULIB_GEXT_DATA		;Daten einlesen.
			jsr	ULIB_GET_STRING		;Daten einlesen, Ende = NULL-Byte.
;			jsr	ULIB_GET_STATUS		;Status einlesen.
			jsr	ULIB_ACCEPT_DATA	;Datensatz akzeptieren.
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

;			jsr	ULIB_TEST_ERR		;Fehlerstatus auswerten.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

::test			tya				;DLAST/DMORE zwischenspeichern.
			pha

			jsr	readDir_Entry		;Eintrag testen/übernehmen.

			pla
			tay				;DLAST/DMORE zurücksetzen.

			lda	r7H			;Max. Anzahl Dateien gelesen?
			beq	:cancel			; => Ja, Abbruch...

			lda	r12H
			cmp	#> UCI_DATA_MSG -1	;Speicher voll?
			bcs	:cancel			; => Ja, Abbruch...

;--- Weiter mit nächstem Eintrag.
::skip			lda	r0H			;Daten-Status einlesen.
			and	#CMD_STATE_BITS
			cmp	#CMD_STATE_DLAST	;Alle Daten empfangen?
			beq	:done			; => Ja, Ende...

			cmp	#CMD_STATE_DMORE	;Weitere Daten?
			beq	:next			; => Ja, weiter...
			bne	:done

;--- Speicher voll...
::cancel		jsr	ULIB_SEND_ABORT		;Befehl abbrechen...

;--- Datei-Informationen einlesen.
::done			jsr	readDir_Info		;Datei-Informatonen einlesen.

;--- Ende...
::ok			ldx	#NO_ERROR		;Kein Fehler.

::err			pla				;Datenregister zurücksetzen.
			sta	r0L
			pla
			sta	r0H

			rts

;*** Eintrag testen.
:readDir_Entry		bit	r7L			;Bit%7=1 (Verzeichnisse erlaubt) ?
			bmi	:1			; => Ja, weiter...
			lda	UCI_DATA_MSG +0
			and	#%00010000		;Eintrag = Verzeichnis?
			bne	:faulty			; => Ja, Abbruch...

::1			bit	r7L			;Bit%6=1 (Dateien erlaubt) ?
			bvs	:ext			; => Ja, weiter...
			lda	UCI_DATA_MSG +0
			and	#%00010000		;Eintrag = Datei?
			beq	:faulty			; => Ja, Abbruch...

;--- Erweiterung testen.
::ext			lda	r10L
			ora	r10H			;Erweiterung definiert?
			beq	:add			; => Nein, weiter...

			ldx	#1			;Erweiterung in Dateiname suchen.
::loop			lda	UCI_DATA_MSG,x
			cmp	#"."
			bne	:next

			stx	r0L

			ldy	#0
::2			lda	(r10),y
			cmp	#"?"			;Wildcard?
			beq	:3			; => Ja, Zeichen OK...
			eor	UCI_DATA_MSG,x		;Stimmt Zeichen mit Dateifilter
			beq	:3			;überein?
			cmp	#$20
			bne	:skip			; => Nein, weitersuchen...
::3			inx
			iny
			cpy	#4			;4 Zeichen geprüft?
			bcc	:2			; => Nein, weitersuchen...
			bcs	:add			; => Ja, Dateiname übernehmen...

::skip			ldx	r0L

::next			inx
			cpx	#64 -1			;Dateiname überprüft?
			bcc	:loop			; => Nein, weiter...

::faulty		rts

;--- Eintrag gültig, übernehmen.
::add			ldy	#0			;Zeiger auf Dateieintrag
			lda	r12L			;in Verzeichnistabelle übernehmen.
			sta	(r13),y
			iny
			lda	r12H
			sta	(r13),y
			dey

			lda	UCI_DATA_MSG +0		;Dateityp übernehmen.
			sta	(r12),y
			iny

			lda	#NULL			;Header-Bytes löschen:
::clr_hdr		sta	(r12),y			; -> Dateilänge.
			iny				; -> Datum.
			cpy	#12			; -> Uhrzeit.
			bcc	:clr_hdr		; -> Erweiterung.

			ldx	#1			;Dateiname übernehmen.
;			ldy	#12
::copy_name		lda	UCI_DATA_MSG,x
			sta	(r12),y
			beq	:4
			iny
			inx
			cpx	#64
			bcc	:copy_name

			lda	#NULL			;Ende-Kennung setzen.
			sta	(r12),y

::4			iny				;Zeiger auf nächsten
			tya				;Verzeichniseintrag.
			clc
			adc	r12L
			sta	r12L
			bcc	:5
			inc	r12H

::5			lda	r13L			;Zeiger auf nächsten
			clc				;Tabelleneintrag.
			adc	#< 2
			sta	r13L
			bcc	:6
			inc	r13H

::6			dec	r7H			;Max. Anzahl Dateien -1.

			rts

;*** Datei-Informationen einlesen.
:readDir_Info		lda	r7L
			and	#%00100000		;Datei-Informationen einlesen?
			bne	:init			; => Ja, weiter...
::exit			rts

::init			lda	r8L			;Zeiger auf Verzeichnistabelle
			sta	r13L			;zwischenspeichern.
			lda	r8H
			sta	r13H

::get			lda	r13H
			sec
			sbc	r8H
			cmp	#2			;Tabelle voll?
			bcs	:exit			; => Ja, Ende...

			ldy	#1			;Zeiger auf Verzeichniseintrag
			lda	(r13),y			;einlesen.
			sta	r12H
			dey
			lda	(r13),y
			sta	r12L
			ora	r12H
			beq	:exit

;			ldy	#0
			lda	(r12),y			;Dateityp einlesen.
			and	#%00010000		;Verzeichnis?
			bne	:next			; => Ja, ignorieren.

			lda	r12L			;Zeiger auf Dateiname setzen.
			clc
			adc	#< 12
			sta	r6L
			lda	r12H
			adc	#> 12
			sta	r6H

;--- Datei-Informationen einlesen.
;Bei Firmware 3.6a kann es nach MOUNT
;oder WRITE passieren, das eine Datei
;über FILE_STAT nicht gefunden wird.
;Alternativ: FILE_INFO verwenden.
; => Funktioniert nur bei Dateien!
			jsr	_UCID_OPEN_FILE_READ
			txa				;Fehler?
			bne	:next			; => Ja, Nächste Datei...

			jsr	_UCID_FILE_INFO		;Datei-Informationen einlesen.

			jsr	_UCID_CLOSE_FILE	;Datei schliesen.

			ldy	#1			;Anzahl Blocks übernehmen.
			lda	UCI_DATA_MSG +1
			sta	(r12),y
			iny
			lda	UCI_DATA_MSG +2
			sta	(r12),y

			jsr	ULIB_FILE_DATE		;Dateidatum umwandeln.

			ldy	#3			;Dateidatum übernehmen.
			lda	r14L
			sta	(r12),y
			iny
			lda	r14H
			sta	(r12),y
			iny
			lda	r15L
			sta	(r12),y

			jsr	ULIB_FILE_TIME		;Dateizeit umwandeln.

			ldy	#6			;Dateizeit übernehmen.
			lda	r14L
			sta	(r12),y
			iny
			lda	r14H
			sta	(r12),y
			iny
			lda	r15L
			sta	(r12),y

			ldy	#9			;Extension übernehmen.
			lda	UCI_DATA_MSG +8
			sta	(r12),y
			iny
			lda	UCI_DATA_MSG +9
			sta	(r12),y
			iny
			lda	UCI_DATA_MSG +10
			sta	(r12),y

::next			lda	r13L			;Zeiger auf nächsten
			clc				;Verzeichniseintrag.
			adc	#< 2
			sta	r13L
			bcc	:1
			inc	r13H

::1			jmp	:get			; => Nächste Datei...
