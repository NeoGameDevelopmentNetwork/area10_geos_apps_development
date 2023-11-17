; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DeskTop-Menü:

;--- Hauptmenü.
if LANG = LANG_DE
:dmtx_geos		b "geos",NULL
:dmtx_file		b "Datei",NULL
:dmtx_view		b "Anzeige",NULL
:dmtx_select		b "Wahl",NULL
:dmtx_page		b "Seite",NULL
:dmtx_disk		b "Diskette",NULL
:dmtx_options		b "Opt",NULL
endif
if LANG = LANG_EN
:dmtx_geos		b "geos",NULL
:dmtx_file		b "file",NULL
:dmtx_view		b "view",NULL
:dmtx_select		b "select",NULL
:dmtx_page		b "page",NULL
:dmtx_disk		b "disk",NULL
:dmtx_options		b "options",NULL
endif
;---

;--- geos-Menü.
if LANG = LANG_DE
:dmtx_info_g		b "GEOS-Info",NULL
:dmtx_info_d		b "deskTop-Info",NULL
:dmtx_info		b "Info"
			b GOTOX
			w  4*8 +11*8 -26
			b $80,BOLDON,"Q",PLAINTEXT,NULL
:dmtx_printer		b "Drucker wählen",NULL
:dmtx_input		b "Eingabe wählen"
			b GOTOX
			w  0*8 +12*8 -20
			b $80,BOLDON,"I",PLAINTEXT,NULL
endif
if LANG = LANG_EN
:dmtx_info_g		b "GEOS info",NULL
:dmtx_info_d		b "deskTop "
:dmtx_info		b "info"
			b GOTOX
			w  4*8 +11*8 -28
			b $80,BOLDON,"Q",PLAINTEXT,NULL
:dmtx_printer		b "select printer",NULL
:dmtx_input		b "select input"
			b GOTOX
			w  0*8 +10*8 -20
			b $80,BOLDON,"I",PLAINTEXT,NULL
endif
;---

;--- Menü: Datei.
if LANG = LANG_DE
:dmtx_fopen		b "Öffnen"
			b GOTOX
			w  4*8 +11*8 -26
			b $80,BOLDON,"Z",PLAINTEXT,NULL
:dmtx_frename		b "umbenennen"
			b GOTOX
			w  4*8 +11*8 -26
			b $80,BOLDON,"M",PLAINTEXT,NULL
:dmtx_fcopy		b "duplizieren"
			b GOTOX
			w  4*8 +11*8 -26
			b $80,BOLDON,"H",PLAINTEXT,NULL
:dmtx_fprint		b "drucken"
			b GOTOX
			w  4*8 +11*8 -26
			b $80,BOLDON,"P",PLAINTEXT,NULL
:dmtx_fdelete		b "löschen"
			b GOTOX
			w  4*8 +11*8 -26
			b $80,BOLDON,"D",PLAINTEXT,NULL
:dmtx_fundelete		b "Datei retten"
			b GOTOX
			w  4*8 +11*8 -26
			b $80,BOLDON,"U",PLAINTEXT,NULL
endif
if LANG = LANG_EN
:dmtx_fopen		b "open"
			b GOTOX
			w  4*8 +11*8 -28
			b $80,BOLDON,"Z",PLAINTEXT,NULL
:dmtx_fcopy		b "duplicate"
			b GOTOX
			w  4*8 +11*8 -28
			b $80,BOLDON,"H",PLAINTEXT,NULL
:dmtx_frename		b "rename"
			b GOTOX
			w  4*8 +11*8 -28
			b $80,BOLDON,"M",PLAINTEXT,NULL
:dmtx_fprint		b "print"
			b GOTOX
			w  4*8 +11*8 -28
			b $80,BOLDON,"P",PLAINTEXT,NULL
:dmtx_fdelete		b "delete"
			b GOTOX
			w  4*8 +11*8 -28
			b $80,BOLDON,"D",PLAINTEXT,NULL
:dmtx_fundelete		b "undo delete"
			b GOTOX
			w  4*8 +11*8 -28
			b $80,BOLDON,"U",PLAINTEXT,NULL
endif
;---

;--- Menü: Anzeige.
if LANG = LANG_DE
:dmtx_viewpic		b "Piktogramme",NULL
:dmtx_viewname		b "nach Namen",NULL
:dmtx_viewdate		b "nach Datum",NULL
:dmtx_viewsize		b "nach Größe",NULL
:dmtx_viewtype		b "nach Typ",NULL
endif
if LANG = LANG_EN
:dmtx_viewpic		b "by icon",NULL
:dmtx_viewname		b "by name",NULL
:dmtx_viewdate		b "by date",NULL
:dmtx_viewsize		b "by size",NULL
:dmtx_viewtype		b "by type",NULL
endif
;---

;--- Menü: Diskette.
if LANG = LANG_DE
:dmtx_dopen		b "Öffnen"
			b GOTOX
			w 12*8 +11*8 -27
			b $80,BOLDON,"O",PLAINTEXT,NULL
:dmtx_dclose		b "Schließen"
			b GOTOX
			w 12*8 +11*8 -27
			b $80,BOLDON,"C",PLAINTEXT,NULL
:dmtx_drename		b "Umbenennen"
			b GOTOX
			w 12*8 +11*8 -27
			b $80,BOLDON,"N",PLAINTEXT,NULL
:dmtx_dcopy		b "Kopieren"
			b GOTOX
			w 12*8 +11*8 -27
			b $80,BOLDON,"K",PLAINTEXT,NULL
:dmtx_dvalidate		b "Aufräumen"
			b GOTOX
			w 12*8 +11*8 -27
			b $80,BOLDON,"V",PLAINTEXT,NULL
:dmtx_ddelete		b "löschen"
			b GOTOX
			w 12*8 +11*8 -27
			b $80,BOLDON,"E",PLAINTEXT,NULL
:dmtx_dformat		b "Formatieren"
			b GOTOX
			w 12*8 +11*8 -27
			b $80,BOLDON,"F",PLAINTEXT,NULL
endif
if LANG = LANG_EN
:dmtx_dopen		b "open"
			b GOTOX
			w 10*8 +8*8 -23
			b $80,BOLDON,"O",PLAINTEXT,NULL
:dmtx_dclose		b "close"
			b GOTOX
			w 10*8 +8*8 -23
			b $80,BOLDON,"C",PLAINTEXT,NULL
:dmtx_drename		b "rename"
			b GOTOX
			w 10*8 +8*8 -23
			b $80,BOLDON,"N",PLAINTEXT,NULL
:dmtx_dcopy		b "copy"
			b GOTOX
			w 10*8 +8*8 -23
			b $80,BOLDON,"K",PLAINTEXT,NULL
:dmtx_ddelete		b "erase"
			b GOTOX
			w 10*8 +8*8 -23
			b $80,BOLDON,"E",PLAINTEXT,NULL
:dmtx_dvalidate		b "validate"
			b GOTOX
			w 10*8 +8*8 -23
			b $80,BOLDON,"V",PLAINTEXT,NULL
:dmtx_dformat		b "format"
			b GOTOX
			w 10*8 +8*8 -23
			b $80,BOLDON,"F",PLAINTEXT,NULL
endif
;---

;--- Menü: Seite.
if LANG = LANG_DE
:dmtx_pageadd		b "anhängen"
			b GOTOX
			w 21*8 +9*8 -22
			b $80,BOLDON,"S",PLAINTEXT,NULL
:dmtx_pagedel		b "entfernen"
			b GOTOX
			w 21*8 +9*8 -22
			b $80,BOLDON,"T",PLAINTEXT,NULL
endif
if LANG = LANG_EN
:dmtx_pageadd		b "append"
			b GOTOX
			w 17*8 +8*8 -23
			b $80,BOLDON,"S",PLAINTEXT,NULL
:dmtx_pagedel		b "delete"
			b GOTOX
			w 17*8 +8*8 -23
			b $80,BOLDON,"T",PLAINTEXT,NULL
endif
;---

;--- Menü: Wahl.
if LANG = LANG_DE
:dmtx_slctall		b "alle Seiten"
			b GOTOX
			w 17*8 +14*8 -24
			b $80,BOLDON,"W",PLAINTEXT,NULL
:dmtx_slctpage		b "diese Seite"
			b GOTOX
			w 17*8 +14*8 -24
			b $80,BOLDON,"X",PLAINTEXT,NULL
:dmtx_slctborder	b "Dateien vom Rand"
			b GOTOX
			w 17*8 +14*8 -24
			b $80,BOLDON,"Y",PLAINTEXT,NULL
endif
if LANG = LANG_EN
:dmtx_slctall		b "all pages"
			b GOTOX
			w 13*8 +10*8 -23
			b $80,BOLDON,"W",PLAINTEXT,NULL
:dmtx_slctpage		b "page files"
			b GOTOX
			w 13*8 +10*8 -23
			b $80,BOLDON,"X",PLAINTEXT,NULL
:dmtx_slctborder	b "border files"
			b GOTOX
			w 13*8 +10*8 -23
			b $80,BOLDON,"Y",PLAINTEXT,NULL
endif
;---

;--- Menü: Options.
if LANG = LANG_DE
:dmtx_optclock		b "Uhr setzen",NULL
:dmtx_optbasic		b "BASIC",NULL
:dmtx_optreset		b "RESET"
			b GOTOX
			w 24*8 +8*8 -24
			b $80,BOLDON,"R",PLAINTEXT,NULL
:dmtx_optkeys		b "Tastenkürzel",NULL
endif
if LANG = LANG_EN
:dmtx_optclock		b "set clock",NULL
:dmtx_optbasic		b "BASIC",NULL
:dmtx_optreset		b "RESET"
			b GOTOX
			w 20*8 +9*8 -23
			b $80,BOLDON,"R",PLAINTEXT,NULL
:dmtx_optkeys		b "shortcuts",NULL
endif
;---
