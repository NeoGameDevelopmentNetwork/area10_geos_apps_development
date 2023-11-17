; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Routine:   SetFileSlctMode
;Parameter: AKKU= Auswahlmodus:
;                 $00 -> Nicht ausgewählt.
;                 $FF -> Ausgewählt.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Auswahlflag für alle Dateien setzen/löschen.
;******************************************************************************
:SetFileSlctMode	sta	r10L			;Markierungsmodus merken.

			lda	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_MAXENTRY +1
endif
			bne	:1			; => Dateien vorhanden, weiter.
			rts				;Keine Dateien, Ende.

::1			LoadW	r0,BASE_DIR_DATA	;Zeiger auf Verzeichnisdaten.

			lda	WM_DATA_MAXENTRY +0
			sta	r11L
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_MAXENTRY +1
			sta	r11H			;Dateizähler initialisieren.
endif

::2			ldy	#$02
			lda	(r0L),y			;Dateityp-Byte einlesen.
			cmp	#GD_MORE_FILES		;"Weitere Dateien"?
			beq	:3			; => Ja, Ende...

			ldy	#$00
			lda	r10L			;Markierungsmodus in Speicher
			sta	(r0L),y			;schreiben.

::3			AddVBW	32,r0			;Zeiger auf nächsten Eintrag/Cache.

if MAXENTRY16BIT = TRUE
			lda	r11L			;Zähler Dateien -1.
			bne	:4
			dec	r11H
endif
::4			dec	r11L

if MAXENTRY16BIT = TRUE
			lda	r11L
			ora	r11H			;Alle Dateien bearbeitet?
endif
			bne	:2			; => Nein, weiter...

			jmp	UPDATE_WIN_DATA		;Fensterdaten speichern.
