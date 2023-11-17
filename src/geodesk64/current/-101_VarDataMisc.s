; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Gemeinsam genutzte Variablen.

;--- Verzeichnis laden.
.GD_RELOAD_DIR		b $00				;$80 = Dateien von Disk laden.
							;$40 = BAM testen/Cache oder Disk.
							;$3F = Nur Dateien sortieren.
							;$00 = Dateien aus Cache.

;--- Gewählter Eintrag im Arbeitsplatz.
.MyCompEntry
if MAXENTRY16BIT = FALSE
			b $00
endif
if MAXENTRY16BIT = TRUE
			w $0000
endif

;--- Zeiger auf 32 Byte Verzeichnis-Eintrag.
.fileEntryVec		w $0000

;--- Gewählter Datei-Eintrag in Dateiliste.
.fileEntryPos
if MAXENTRY16BIT = FALSE
			b $00
endif
if MAXENTRY16BIT = TRUE
			w $0000
endif

;--- GetFileData: Datenlaufwerk.
.getFileWin		b $00
.getFileDrv		b $00
.getFilePart		b $00
.getFileSDir		b $00,$00

;--- SortDir: Eintrag tauschen.
;--- DoFileEntry: Verzeichnis-Eintrag.
.dataBufDir		s 32
.dataBufIcon		s 64

;--- Dialogbox-Titel.
if LANG = LANG_DE
.Dlg_Titel_Info		b PLAINTEXT,BOLDON
			b "HINWEIS"
			b NULL

.Dlg_Titel_Error	b PLAINTEXT,BOLDON
			b "FEHLER"
			b NULL
endif
if LANG = LANG_EN
.Dlg_Titel_Info		b PLAINTEXT,BOLDON
			b "INFORMATION"
			b NULL

.Dlg_Titel_Error	b PLAINTEXT,BOLDON
			b "ERROR"
			b NULL
endif

;--- Laufwerksfehler.
.errDrvCode		b $00
.errDrvInfoT		b $00
.errDrvInfoS		b $00
.errDrvInfoP		b $00
.errDrvInfoF		w $0000
