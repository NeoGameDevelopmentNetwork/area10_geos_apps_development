; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Dateifenster/Disk-Menü.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
			t "SymbTab_DISK"
			t "SymbTab_CHAR"
;			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"
			t "s.GD.21.Desk.ext"
endif

;*** GEOS-Header.
			n "obj.GD35"
			f DATA

			o BASE_GDMENU

;*** Sprungtabelle.
;:MAININIT		jmp	OpenDiskMenu

;*** PopUp/Dateifenster.
:OpenDiskMenu		lda	#2!VERTICAL		;Anzahl Menüeinträge zurücksetzen.
			sta	menuSub_Other +6

			jsr	GetBorderBlock		;Adresse Borderblock ermitteln.
			txa				;Diskettenfehler?
			bne	:init_disk		; => Ja, kein Borderblock-Menü.
			tya				;Keine GEOS-Diskette?
			bne	:init_disk		; => Ja, kein Borderblock-Menü.

			lda	#3!VERTICAL		;GEOS-Diskette -> Borderblock.
			sta	menuSub_Other +6

::init_disk		ldx	WM_WCODE		;Fenster-Nr. einlesen.

			ldy	#" "			;Anzeige: Größe in KByte/Blocks.
			lda	WMODE_VSIZE,x
			bpl	:1
			ldy	#"*"
::1			sty	t11 +1			;Extra Byte "BOLDON" überspringen!

			ldy	#" "			;Anzeige: Icons/Text.
			lda	WMODE_VICON,x
			bpl	:2
			ldy	#"*"
::2			sty	t12 +1

			ldy	#" "			;Anzeige: Details anzeigen.
			lda	WMODE_VINFO,x
			bpl	:3
			ldy	#"*"
::3			sty	t13 +1

			ldy	#" "			;Anzeige: Ausgabe bremsen.
			lda	GD_SLOWSCR
			bpl	:4
			ldy	#"*"
::4			sty	t14 +1

			ldy	#" "			;Anzeige: Dateifilter.
			lda	WMODE_FILTER,x
			beq	:5
			ldy	#"*"
::5			sty	t04 +1

;			ldx	WM_WCODE		;Fenster-Nr. einlesen.
			lda	WIN_DATAMODE,x		;Partitionsauswahl aktiv?
			beq	:disk
			bmi	:part

;--- PopUp/SD2IEC-Browser.
::dimage		ldx	#GMOD_SD2IEC
			ldy	GD_DACC_ADDR_B,x	;DiskImage-Menü installiert?
			beq	:part			; => Ja, weiter...

			lda	#< menuSD2IEC		; -> SD2IEC.
			ldx	#> menuSD2IEC
			ldy	#widthSD2IEC
			jsr	menuSetSize		;Menügröße definieren.
			jmp	OPEN_MENU		;Menü anzeigen.

;--- PopUp/Partitionsauswahl.
::part			lda	#< menuSub_View		; -> Anzeige.
			ldx	#> menuSub_View
			ldy	#widthSub_View
			jsr	menuSetSize		;Menügröße definieren.
			jmp	OPEN_MENU		;Menü anzeigen.

;--- PopUp/Dateifenster.
::disk			ldx	#GMOD_GPSHOW
			ldy	GD_DACC_ADDR_B,x	;GPShow-Modul installiert?
			beq	:no_gpshow		; => Nein, weiter...
::gpshow		lda	#PLAINTEXT
			b $2c
::no_gpshow		lda	#ITALICON
			sta	t27

			ldx	#GMOD_DIRSORT
			ldy	GD_DACC_ADDR_B,x	;DirSort-Modul installiert?
			beq	:no_dirsort		; => Nein, weiter...
::dirsort		lda	#PLAINTEXT
			b $2c
::no_dirsort		lda	#ITALICON
			sta	t23

			lda	#< menuDisk		; -> Disk.
			ldx	#> menuDisk
			ldy	#widthDiskMenu
			jsr	menuSetSize		;Menügröße definieren.
			jmp	OPEN_MENU		;Menü anzeigen.

;*** Menü definieren.
:menuSetSize		sta	r0L			;Zeiger auf Menü-Tabelle.
			stx	r0H
			sty	r5H			;Menü-Breite.
			jmp	MENU_SET_SIZE		;Menügröße definieren.

;*** PopUp/Dateifenster.
if LANG = LANG_DE
:widthDiskMenu = $4f
endif
if LANG = LANG_EN
:widthDiskMenu = $4f
endif

:menuDisk		b $00,$00
			w $0000,$0000

			b 8!VERTICAL

			w t01				;Verzeichnis neu laden.
			b MENU_ACTION
			w :m1

			w t02				;Neue Ansicht öffnen.
			b MENU_ACTION
			w :m2

			w t03				;>> Auswahl.
			b DYN_SUB_MENU
			w :m3

			w t04				;>> Dateifilter.
			b DYN_SUB_MENU
			w :m4

			w t05				;>> Sortieren.
			b DYN_SUB_MENU
			w :m5

			w t06				;>> Anzeige.
			b DYN_SUB_MENU
			w :m6

			w t07				;>> Diskette.
			b DYN_SUB_MENU
			w :m7

			w t08				;Applink erstellen.
			b MENU_ACTION
			w :m8

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_RELOAD_DISK		;Verzeichnis neu laden.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_NEW_VIEW		;Neue Ansicht öffnen.

::m3			lda	#< menuSub_Slct		; -> Auswahl.
			ldx	#> menuSub_Slct
			ldy	#widthSub_Slct
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

::m4			lda	#< menuSub_Filter	; -> Dateifilter.
			ldx	#> menuSub_Filter
			ldy	#widthSub_Filter
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

::m5			lda	#< menuSub_Sort		; -> Sortieren.
			ldx	#> menuSub_Sort
			ldy	#widthSub_Sort
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

::m6			lda	#< menuSub_View		; -> Anzeige.
			ldx	#> menuSub_View
			ldy	#widthSub_View
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

::m7			lda	#< menuSub_Disk		; -> Diskette.
			ldx	#> menuSub_Disk
			ldy	#widthSub_Disk
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

::m8			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_CREATE_AL		;AppLink erstellen.

if LANG = LANG_DE
:t01			b "Neu laden",NULL
:t02			b "Neue Ansicht",NULL
:t03			b ">> Auswahl",NULL
:t04			b "( ) Dateifilter",NULL
:t05			b ">> Sortieren",NULL
:t06			b ">> Anzeige",NULL
:t07			b ">> Laufwerk",NULL
:t08			b "AppLink erstellen",NULL
endif

if LANG = LANG_EN
:t01			b "Reload files",NULL
:t02			b "New view",NULL
:t03			b ">> Select files",NULL
:t04			b "( ) Filter",NULL
:t05			b ">> Sort mode",NULL
:t06			b ">> View mode",NULL
:t07			b ">> Disk/Drive",NULL
:t08			b "Create AppLink",NULL
endif

;*** PopUp/SD2IEC-Browser.
if LANG = LANG_DE
:widthSD2IEC = $4f
endif
if LANG = LANG_EN
:widthSD2IEC = $4f
endif

:menuSD2IEC		b $00,$00
			w $0000,$0000

			b 2!VERTICAL

::_07			w :t01				;>> Anzeige.
			b DYN_SUB_MENU
			w :m01

::_12			w :t02				;>> Neu.
			b DYN_SUB_MENU
			w :m02

::m01			lda	#< menuSub_View		; -> Anzeige.
			ldx	#> menuSub_View
			ldy	#widthSub_View
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

::m02			lda	#< menuSub_New		; -> Neu.
			ldx	#> menuSub_New
			ldy	#widthSub_New
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

if LANG = LANG_DE
::t01			b ">> Anzeige",NULL
::t02			b ">> Neu",NULL
endif

if LANG = LANG_EN
::t01			b ">> View mode",NULL
::t02			b ">> Create",NULL
endif

;*** PopUp/DiskImage/Neu.
if LANG = LANG_DE
:widthSub_New = $3f
endif
if LANG = LANG_EN
:widthSub_New = $37
endif

:menuSub_New		b $00,$00
			w $0000,$0000

			b 2!VERTICAL

::_07			w :t01				;DiskImage erstellen.
			b MENU_ACTION
			w :m01

::_12			w :t02				;DiskImage umbenennen.
			b MENU_ACTION
			w :m02

::m01			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_CREATE_IMG		;DiskImage erstellen.

::m02			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.

			lda	#$09			;Verzeichnis erstellen.
			ldx	#GMOD_SD2IEC
			jmp	EXEC_MODULE

if LANG = LANG_DE
::t01			b PLAINTEXT
			b "DiskImage",NULL
::t02			b PLAINTEXT
			b "Verzeichnis",NULL
endif
if LANG = LANG_EN
::t01			b PLAINTEXT
			b "Disk image",NULL
::t02			b PLAINTEXT
			b "Directory",NULL
endif

;*** PopUp/Dateifenster -> Auswahl.
if LANG = LANG_DE
:widthSub_Slct = $57
endif
if LANG = LANG_EN
:widthSub_Slct = $3f
endif

:menuSub_Slct		b $00,$00
			w $0000,$0000

			b 2!VERTICAL

			w :t1				;Auswahl: Alle auswählen.
			b MENU_ACTION
			w :m1

			w :t2				;Auswahl: Keine auswählen.
			b MENU_ACTION
			w :m2

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SELECT_ALL		;Alle Dateien auswählen.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SELECT_NONE		;Dateiauswahl aufheben.

if LANG = LANG_DE
::t1			b "Alle auswählen",NULL
::t2			b "Auswahl aufheben",NULL
endif

if LANG = LANG_EN
::t1			b "Select all",NULL
::t2			b "Unselect all",NULL
endif

;*** PopUp/Dateifenster -> Dateifilter.
if LANG = LANG_DE
:widthSub_Filter = $57
endif
if LANG = LANG_EN
:widthSub_Filter = $4f
endif

:menuSub_Filter		b $00,$00
			w $0000,$0000

			b 8!VERTICAL

			w :t1				;Filter: Alle Dateien.
			b MENU_ACTION
			w :m1

			w :t2				;Filter: Anwendungen.
			b MENU_ACTION
			w :m2

			w :t3				;Filter: AutoStart-Programme.
			b MENU_ACTION
			w :m3

			w :t4				;Filter: Dokumente.
			b MENU_ACTION
			w :m4

			w :t5				;Filter: Hilfsmittel.
			b MENU_ACTION
			w :m5

			w :t6				;Filter: Zeichensätze.
			b MENU_ACTION
			w :m6

			w :t7				;Menü: Systemdateien.
			b DYN_SUB_MENU
			w :m7

			w :t8				;Menü: Andere Dateien.
			b DYN_SUB_MENU
			w :m8

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_ALL		;Filter: Alle Dateien.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_APPS		;Filter: Anwendungen.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_EXEC		;Filter: AutoStart-Programme.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_DOCS		;Filter: Dokumente.

::m5			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_DA		;Filter: Hilfsmittel.

::m6			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_FONT		;Filter: Zeichensätze.

::m7			lda	#< menuSub_Device	; -> Gerätetreiber.
			ldx	#> menuSub_Device
			ldy	#widthSub_Device
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

::m8			lda	#< menuSub_Other	; -> Andere Dateien.
			ldx	#> menuSub_Other
			ldy	#widthSub_Other
			jsr	menuSetSize
			jmp	MENU_SETINT_r0

if LANG = LANG_DE
::t1			b "Alle Dateien",NULL
::t2			b "Anwendungen",NULL
::t3			b "Autostart",NULL
::t4			b "Dokumente",NULL
::t5			b "Hilfsmittel",NULL
::t6			b "Zeichensatz",NULL
::t7			b ">> Systemdateien",NULL
::t8			b ">> Andere Dateien",NULL
endif

if LANG = LANG_EN
::t1			b "All files",NULL
::t2			b "Applications",NULL
::t3			b "Autoexec files",NULL
::t4			b "Documents",NULL
::t5			b "DeskAccessories",NULL
::t6			b "Fonts",NULL
::t7			b ">> System files",NULL
::t8			b ">> Other files",NULL
endif

;*** PopUp/Dateifenster -> Filter -> Systemdateien.
if LANG = LANG_DE
:widthSub_Device = $4f
endif
if LANG = LANG_EN
:widthSub_Device = $47
endif

:menuSub_Device		b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w :t1				;Filter: Systemdateien.
			b MENU_ACTION
			w :m1

			w :t2				;Filter: Druckertreiber.
			b MENU_ACTION
			w :m2

			w :t3				;Filter: Eingabetreiber.
			b MENU_ACTION
			w :m3

			w :t4				;Filter: Laufwerkstreiber.
			b MENU_ACTION
			w :m4

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_SYS		;Filter: Systemdateien.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_PRNT		;Filter: Druckertreiber.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_INPT		;Filter: Eingabetreiber.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_DISK		;Filter: Laufwerkstreiber.

if LANG = LANG_DE
::t1			b "Systemdateien",NULL
::t2			b "Druckertreiber",NULL
::t3			b "Eingabetreiber",NULL
::t4			b "Laufwerkstreiber",NULL
endif

if LANG = LANG_EN
::t1			b "System files",NULL
::t2			b "Printer device",NULL
::t3			b "Input device",NULL
::t4			b "Disk device",NULL
endif

;*** PopUp/Dateifenster -> Filter -> Andere...
if LANG = LANG_DE
:widthSub_Other = $57
endif
if LANG = LANG_EN
:widthSub_Other = $4f
endif

:menuSub_Other		b $00,$00
			w $0000,$0000

			b 3!VERTICAL

			w :t1				;Filter: BASIC-Programme.
			b MENU_ACTION
			w :m1

			w :t2				;Filter: Gelöschte Dateien.
			b MENU_ACTION
			w :m2

			w :t3				;Filter: Borderblock.
			b MENU_ACTION
			w :m3

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_BASIC		;Filter: BASIC-Programme.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_DEL		;Filter: Gelöschte Dateien.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FILTER_BORDER	;Filter: Borderblock.

if LANG = LANG_DE
::t1			b "BASIC-Programme",NULL
::t2			b "Gelöschte Dateien",NULL
::t3			b "Borderblock",NULL
endif

if LANG = LANG_EN
::t1			b "BASIC programs",NULL
::t2			b "Deleted files",NULL
::t3			b "Borderblock",NULL
endif

;*** PopUp/Dateifenster -> Sortieren.
if LANG = LANG_DE
:widthSub_Sort = $4f
endif
if LANG = LANG_EN
:widthSub_Sort = $4f
endif

:menuSub_Sort		b $00,$00
			w $0000,$0000

			b 7!VERTICAL

			w :t1				;Sortieren: Name.
			b MENU_ACTION
			w :m1

			w :t2				;Sortieren: Dateigröße.
			b MENU_ACTION
			w :m2

			w :t3				;Sortieren: Datum Alt->Neu.
			b MENU_ACTION
			w :m3

			w :t4				;Sortieren: Datum Neu->Alt.
			b MENU_ACTION
			w :m4

			w :t5				;Sortieren: CBM-Dateityp.
			b MENU_ACTION
			w :m5

			w :t6				;Sortieren: GEOS-Dateityp.
			b MENU_ACTION
			w :m6

			w :t7				;Sortieren: Unsortiert.
			b MENU_ACTION
			w :m7

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SORT_NAME		;Sortieren: Name.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SORT_SIZE		;Sortieren: Dateigröße.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SORT_DATE_OLD	;Sortieren: Datum Alt->Neu.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SORT_DATE_NEW	;Sortieren: Datum Neu->Alt.

::m5			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SORT_TYPE		;Sortieren: CBM-Dateityp.

::m6			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SORT_GEOS		;Sortieren: GEOS-Dateityp.

::m7			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_SORT_NONE		;Sortieren: Unsortiert.

if LANG = LANG_DE
::t1			b "Dateiname",NULL
::t2			b "Dateigröße",NULL
::t3			b "Datum Alt->Neu",NULL
::t4			b "Datum Neu->Alt",NULL
::t5			b "Dateityp",NULL
::t6			b "GEOS-Dateityp",NULL
::t7			b "Unsortiert",NULL
endif

if LANG = LANG_EN
::t1			b "Filename",NULL
::t2			b "Silesize",NULL
::t3			b "Date Old->New",NULL
::t4			b "Date New->Old",NULL
::t5			b "Filetype",NULL
::t6			b "GEOS-Filetype",NULL
::t7			b "Unsorted",NULL
endif

;*** PopUp/Dateifenster -> Anzeige.
if LANG = LANG_DE
:widthSub_View = $67
endif
if LANG = LANG_EN
:widthSub_View = $6f
endif

:menuSub_View		b $00,$00
			w $0000,$0000

			b 4!VERTICAL

			w t11				;Größe in KByte/Blocks.
			b MENU_ACTION
			w :m1

			w t12				;Textmodus.
			b MENU_ACTION
			w :m2

			w t13				;Details zeigen.
			b MENU_ACTION
			w :m3

			w t14				;Anzeige bremsen.
			b MENU_ACTION
			w :m4

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_VIEW_SIZE		;Größe in KByte/Blocks.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_VIEW_ICONS		;Textmodus.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_VIEW_DETAILS		;Details zeigen.

::m4			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_VIEW_SLOWMOVE	;Anzeige bremsen.

if LANG = LANG_DE
:t11			b "( ) Größe in KByte",NULL
:t12			b "( ) Textmodus",NULL
:t13			b "( ) Details zeigen",NULL
:t14			b "( ) Anzeige bremsen",NULL
endif

if LANG = LANG_EN
:t11			b "( ) Size in KBytes",NULL
:t12			b "( ) Textmode",NULL
:t13			b "( ) Show details",NULL
:t14			b "( ) Slow down output",NULL
endif

;*** PopUp/Dateifenster -> Diskette.
if LANG = LANG_DE
:widthSub_Disk = $4f
endif
if LANG = LANG_EN
:widthSub_Disk = $47
endif

:menuSub_Disk		b $00,$00
			w $0000,$0000

			b 7!VERTICAL

			w t21				;Eigenschaften.
			b MENU_ACTION
			w :m1

			w t22				;Validate.
			b MENU_ACTION
			w :m2

			w t23				;Dateien ordnen.
			b MENU_ACTION
			w :m3

			w t24				;Disk löschen.
			b MENU_ACTION
			w :m4

			w t25				;Diskette bereinigen.
			b MENU_ACTION
			w :m5

			w t26				;Disk formatieren.
			b MENU_ACTION
			w :m6

			w t27				;Diashow.
			b MENU_ACTION
			w :m7

::m1			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_DISKINFO		;Eigenschaften.

::m2			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_VALIDATE		;Validate.

::m3			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_DIRSORT		;Dateien ordnen.

::m4			lda	#%01000000		;Andere Fenster schließen.
			sta	drvUpdFlag
			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_CLRDISK		;Disk löschen.

::m5			lda	#%01000000		;Andere Fenster schließen.
			sta	drvUpdFlag
			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_PURGEDISK		;Diskette bereinigen.

::m6			lda	#%01000000		;Andere Fenster schließen.
			sta	drvUpdFlag
			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	PF_FORMAT_DISK		;Disk formatieren.

::m7			jsr	EXIT_POPUP_MENU		;PopUp-Menü beenden.
			jmp	MOD_GPSHOW		;Diashow.

if LANG = LANG_DE
:t21			b "Eigenschaften",NULL
:t22			b "Überprüfen",NULL
:t23			b PLAINTEXT
			b "Dateien ordnen"
			b PLAINTEXT,NULL
:t24			b "Löschen",NULL
:t25			b "Bereinigen",NULL
:t26			b "Formatieren",NULL
:t27			b PLAINTEXT
			b "DiaShow"
			b PLAINTEXT,NULL
endif

if LANG = LANG_EN
:t21			b "Properties",NULL
:t22			b "Validate",NULL
:t23			b PLAINTEXT
			b "Organize files"
			b PLAINTEXT,NULL
:t24			b "Clear drive",NULL
:t25			b "Purge data",NULL
:t26			b "Format disk",NULL
:t27			b PLAINTEXT
			b "Slide show"
			b PLAINTEXT,NULL
endif

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für Menü-Daten verfügbar ist.
			g BASE_GDMENU +SIZE_GDMENU -1
;***
