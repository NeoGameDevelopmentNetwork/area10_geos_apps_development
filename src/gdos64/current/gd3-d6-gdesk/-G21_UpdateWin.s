; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Andere Fenster aktualisieren.
:updateOtherWin		bit	GD_RELOAD_DIR		;Fenster von Disk neu einlesen?
			bpl	:exit			; => Nein, Ende...

			ldx	#MAX_WINDOWS -1		;Zeiger auf Ende Fenster-Stack.

::1			txa				;StackPointer speichern.
			pha

			lda	WM_STACK,x		;Fenster-Typ einlesen.
			beq	:2			; => Desktop, weiter...
			bmi	:2			; => Kein Fenster, weiter...

			tax
			lda	WIN_DATAMODE,x		;Partition-/DiskImage-Browser aktiv?
			bne	:2			; => Ja, weiter...

			ldy	WM_WCODE		;Aktuelles Fenster.

			lda	WIN_DRIVE,x		;Laufwerk vergleichen.
			cmp	WIN_DRIVE,y
			bne	:2			; => Unterschiedlich, weiter...

			lda	WIN_PART,x		;Partition vergleichen.
			cmp	WIN_PART,y
			bne	:2			; => Unterschiedlich, weiter...

			lda	WIN_SDIR_T,x		;NativeMode-Verzeichnis vergleichen.
			cmp	WIN_SDIR_T,y
			bne	:2			; => Unterschiedlich, weiter...
			lda	WIN_SDIR_S,x		;NativeMode-Verzeichnis vergleichen.
			cmp	WIN_SDIR_S,y
			bne	:2			; => Unterschiedlich, weiter...

			txa				;Fenster-Nr. zwischenspeichern.
			pha
			lda	WIN_DRIVE,x		;Laufwerksadresse einlesen und
			jsr	Sys_SetDrv_Open		;Laufwerk wechseln und
							;Diskette öffnen.

;--- Hinweis:
;":SetDevice" und ":OpenDisk" durch
;die neue Routine ":Sys_SetDrv_Open"
;ersetzet.
;			jsr	SetDevice		;Laufwerk aktivieren.
;			jsr	OpenDisk		;Disk öffnen, wegen Diskname.
							;Keine Prüfung auf Fehler, da es
							;hier nur darum geht das Medium
							;zu aktivieren, falls ggf. der
							;Diskname geändert wurde.

			pla
			tax				;Fenster-Nr. zurücksetzen.

			lda	GD_RELOAD_DIR		;ReLoad-Flag zwischenspeichern.
			pha
			stx	WM_WCODE
			jsr	SET_LOAD_DISK
			jsr	WM_CALL_REDRAW		;Fenster von Disk aktualisieren.
			pla
			sta	GD_RELOAD_DIR		;ReLoad-Flag zurücksetzen.

::2			pla
			tax				;Zeiger auf nächstes Fenster.
			dex				;Alle Fenster durchsucht?
			bne	:1			; => Nein, weiter...

			lda	WM_STACK		;Wurde ein anderes Fenster
			cmp	WM_WCODE		;aktualisiert?
			beq	:exit			; => Nein, Ende...
			sta	WM_WCODE 		;Daten für oberstes Fenster
			jsr	WM_LOAD_WIN_DATA	;wieder einlesen.
			jsr	WM_WIN2TOP		;Fenster nach oben holen.

			jsr	sys_SvBackScrn		;Aktuellen Bildschirm speichern.

::exit			rts
