; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Andere Laufwerksfenster schließen.
;SD2IEC:
;Andere Fenster für das aktuelle SD2IEC
;schließen, damit keine zwei Fenster
;mit unterschiedlichen DiskImages für
;das Laufwerk geöffnet sind.
;Allgemein:
;Beim löschen eines Laufwerks andere
;Fenster schließen, da Inhalt nach dem
;löschen der Disk veraltet.
:closeDrvWin		ldx	WM_WCODE		;Fenster-Nr. einlesen.
			cpx	WM_MYCOMP		;Fenster = Arbeitsplatz?
			beq	:exit			; => Ja, Ende...

			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			beq	:exit			; => Kein Laufwerk, Ende...

			sty	:curDrive		;Laufwerksadresse speichern und
			ldy	WIN_PART,x		;ggf. Partition speichern.
			sty	:curPart

			ClrB	:saveScreen		;Flag "Bildschirm speichern".

			ldx	#MAX_WINDOWS -1		;Zeiger auf Ende Fenster-Stack.

::1			txa				;StackPointer speichern.
			pha

			lda	WM_STACK,x		;Fenster-Typ einlesen.
			beq	:2			; => Desktop, weiter...
			bmi	:2			; => Kein Fenster, weiter...

			cmp	WM_MYCOMP		;Fenster = Arbeitsplatz?
			beq	:2			; => Ja, nicht schließen...

			tax
			lda	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			beq	:2			; => Kein Laufwerk, weiter...
			cmp	:curDrive		;Laufwerk = Aktuelles Laufwerk?
			bne	:2			; => Nein, weiter...

			lda	WIN_DATAMODE,x		;Partition-/DiskImage-Browser aktiv?
			bne	:2			; => Ja, weiter...

			lda	WIN_PART,x		;Partition einlesen, Nicht-CMD=$00.
			cmp	:curPart		;Partition = Aktuelle Partition?
			bne	:2			; => Nein, weiter...

			txa
			sta	WM_WCODE
			sta	:saveScreen		;Bildschirm speichern.
			jsr	WM_CLOSE_WINDOW		;Fenster schließen.

::2			pla
			tax				;Zeiger auf nächstes Fenster.
			dex				;Alle Fenster durchsucht?
			bne	:1			; => Nein, weiter...

			lda	WM_STACK		;Daten für oberstes Fenster
			sta	WM_WCODE		;wieder einlesen.
			jsr	WM_LOAD_WIN_DATA

			lda	:saveScreen		;Bildschirm speichern?
			beq	:exit			; => Nein, weiter...
			jmp	WM_SAVE_BACKSCR		;Aktuellen Bildschirm speichern.
::exit			rts

::curDrive		b $00
::curPart		b $00
::saveScreen		b $00
