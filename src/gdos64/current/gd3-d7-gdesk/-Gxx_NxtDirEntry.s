; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Zeiger auf Anfang Verzeichnis.
;Hinweis:
;":Get1stDirEntry" / ":GetNxtDirEntry"
;durch eigene Routinen ersetzt, da GEOS
;beim Laufwerkswechsel das Flag für den
;Borderblock zurücksetzt.
;":GetNxtDirEntry" liefert dann beim
;kopieren von Quelle nach Ziel und bei
;einem aktiven Borderblock die Datei-
;Einträge des Borderblocks in einer
;Endlosschleife, da am Verzeichnis-Ende
;der Borderblock angehängt wird.
;Beim löschen eines Unterverzeichnisses
;werden durch ":GetNxtDirEntry" auch
;die Dateien im Borderblock gelöscht.

;*** Zeiger auf Verzeichnis-Anfang.
:usr1stDirEntry		lda	curDirHead +0		;Zeiger auf ersten Verzeichnis-
			sta	r1L			;block setzen.
			lda	curDirHead +1
			sta	r1H
			jmp	usrGetDirBlock

;*** Zeiger auf nächsten Verzeichnis-Eintrag.
:usrNxtDirEntry		ldy	#$00			;Verzeichnis-Ende nicht erreicht.
			ldx	#NO_ERROR		;Flag: Kein Fehler.

			lda	r5L			;Zeiger auf nächsten Verzeichnis-
			clc				;Eintrag berechnen.
			adc	#$20
			sta	r5L			;Verzeichnis-Block durchsucht?
			bcc	exitNxDirEntry		; => Nein, weiter...

			dey				;Flag setzen: Verzeichnis-Ende.
			lda	diskBlkBuf +1		;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Block setzen.
			lda	diskBlkBuf +0
			sta	r1L			;Verzeichnis-Ende erreicht?
			beq	exitNxDirEntry		; => Ja, Ende.

:usrGetDirBlock		LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Verzeichnisblock einlesen.
			txa				;Fehler?
			bne	exitNxDirEntry		; => Ja, Abbruch...

			tay				;Verzeichnis-Ende nicht erreicht.
			LoadW	r5,diskBlkBuf +2	;Zeiger auf ersten Eintrag.

:exitNxDirEntry		rts
