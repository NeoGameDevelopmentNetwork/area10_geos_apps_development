; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichern der Systemvariablen, Programm-Modul und
;    Verzeichnisdaten. Wird verwendet bevor man das Modul
;    wechselt oder eine Anwendung startet.
.UPDATE_GD_CORE		jsr	BACKUP_CURMOD		;Aktuelles Programm-Modul speichern.
			jsr	BACKUP_WMCORE		;Fenstermanager speichern.
			jsr	BACKUP_GDCORE		;GeoDesk-Daten sichern.

			jsr	putGDINI_RAM		;GD.INI im RAM aktualisieren.

			lda	WM_WCODE		;Fenster geöffnet?
			beq	:exit			; => Nein, weiter...

			jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache.
			jsr	StashRAM		;Verzeichnisdaten speichern.

::exit			rts
