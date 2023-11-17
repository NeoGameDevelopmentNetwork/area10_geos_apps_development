; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Dateien aus Verzeichnis einlesen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_DISK"
			t "SymbTab_DCMD"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"
endif

;*** GEOS-Header.
			n "obj.GD45"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
;:MAININIT		jmp	GET_ALL_FILES

;*** Dateien für Laufwerksfenster einlesen.
;--- Enthält aktuelles Fenster bereits Daten?
:GET_ALL_FILES		ldx	WM_WCODE
			lda	WMODE_FILTER,x		;Filter-Modus einlesen und
			sta	curFilterMode		;zwischenspeichern.

			lda	WIN_DIR_START,x		;Dateien von Beginn an einlesen?
			bne	:test_next		; => Nein, weiter...

;--- WIN_DIR_START: $00
;    Dateien von Beginn an einlesen.
			;ldx	WM_WCODE
			jsr	resetDirData		;Ja, Daten für Verzeichnis-
							;Position zurücksetzen.
			jmp	:open_drive

::test_next		bpl	:open_drive		; => Aktuelle Dateien einlesen.

;--- WIN_DIR_START: $FF
;    Weitere Dateien einlesen.
			lda	WIN_DIR_NX_TR,x		;Verzeichnis-Position auf die
			sta	WIN_DIR_TR,x		;nächsten Dateien setzen.
			lda	WIN_DIR_NX_SE,x
			sta	WIN_DIR_SE,x
			lda	WIN_DIR_NX_POS,x
			sta	WIN_DIR_POS,x

;--- WIN_DIR_START: $7F/$FF
;    Dateien ab Position einlesen.
::open_drive		jsr	WM_OPEN_DRIVE		;Laufwerk öffnen.
			txa				;Fehler?
			bne	exit_disk_err		; => Ja, Abbruch...

;--- Hinweis:
;Bei NativeMode testen ob das aktuelle
;Verzeichnis gültig ist.
;Evtl. wurde das Unterverzeichnis durch
;ein DiskCopy überschrieben.
;In diesem Fall das Verzeichnis auf das
;Hauptverzeichnis zurücksetzen.
			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodi einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:0b			; => Nein, weiter...

			lda	curDirHead +2		;Vezeichniskennung testen.
			cmp	#$48
			bne	:0a
			lda	curDirHead +3
			beq	:0b			; => OK, weiter...

;--- Verzeichnis ungültig.
::0a			lda	#$01			;Verzeichnis ist ungültig.
			sta	WIN_SDIR_T,x		;Hauptverzeichnis für das aktuelle
			sta	WIN_SDIR_S,x		;Fenster aktivieren.

			;ldx	WM_WCODE
			jsr	resetDirData		;Daten für Verzeichnis-
							;Position zurücksetzen.

			jsr	OpenRootDir		;Hauptverz. im Laufwerk öffnen.
			txa				;Fehler?
			bne	exit_disk_err		; => Ja, Abbruch...

::0b			jmp	loadDirectory		; => Weiter, Dateien einlesen.

;--- Laufwerksfehler, Abbruch.
:exit_disk_err		lda	#$00			;Dateizähler löschen.
			sta	WM_DATA_MAXENTRY

			jsr	SET_LOAD_CACHE		;GetFiles-Flag zurücksetzen.
			jmp	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

;*** Dateien einlesen.
;    Übergabe: GD_RELOAD_DIR
;              -> $80: Dateien von Disk einlesen.
;              -> $40: BAM testen, Dateien von Cache oder Disk.
;              -> $3F: Nur Dateien sortieren.
;              -> $00: Dateien aus Cache.
:loadDirectory		lda	#$3f			;AKKU=$3F für BIT-Vergleich.
			bit	GD_RELOAD_DIR		;GetFiles-Modus testen.
			bmi	:get_files_disk		; => Dateien von Disk einlesen.
			bvs	:test_cache		; => BAM testen/Cache, sonst Disk.
			beq	:get_files_std		; => Standardmodus: Cache einlesen.
;Damit Z-Flag=0 für Sortiermodus=$3F
;muss der AKKU=$3F sein! Grund:
;Der BIT-Befehl führt eine Bit-weise
;UND-Verknüpfung mit AKKU+ADRESSE durch.
			jmp	:test_sort_dir		; => Nur Dateien sortieren.

;--- Bereits Dateien im Speicher?
::get_files_std		lda	WM_DATA_MAXENTRY
			beq	:get_files_disk		; => Keine Dateien im Speicher.

;--- Prüfen ob die Laufwerksdaten geändert wurden.
::test_drive		ldx	WM_WCODE
			cpx	getFileWin		;Gleiches Fenster aktiv?
			bne	:get_files_cache	; => Nein, neu einlesen.

			lda	WIN_DRIVE,x
			cmp	getFileDrv		;Anderes Laufwerk?
			bne	:get_files_cache	; => Ja, neu einlesen.

			tay
			lda	RealDrvMode -8,y	;CMD-Laufwerk?
			bpl	:1			; => Nein, weiter...
			lda	WIN_PART,x
			cmp	getFilePart		;Andere Partition?
			bne	:get_files_cache	; => Ja, neu einlesen.

::1			lda	RealDrvMode -8,y
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:2			; => Nein, weiter...

			lda	WIN_SDIR_T,x
			cmp	getFileSDir +0		;Anderes Unterverzeichnis?
			bne	:get_files_cache	; => Ja, neu einlesen.
			lda	WIN_SDIR_S,x
			cmp	getFileSDir +1
			bne	:get_files_cache	; => Ja, neu einlesen.
::2			rts

;--- BAM testen. Wenn OK=Cache, sonst von Disk laden.
::test_cache		jsr	TestCacheBAM		;BAM auf Veränderung testen.
			txa				;BAM geändert?
			bne	:get_files_disk		; => Ja, Dateien von Disk einlesen.
;			beq	:get_files_cache	; => Nein, von Cache laden.

;--- Ergänzung: 09.05.21/M.Kanet
;Hier wurde bisher der aktuelle Inhalt
;des RAM geprüft und ggf. die Daten des
;Fensters im Cache aktualisiert.
;Die Aktualisierung findet jetzt direkt
;beim Wechsel des Fensters statt.

;--- Dateien aus Cache einlesen.
::get_files_cache	jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache.
			jsr	FetchRAM		;Verzeichnis aus Cache einlesen und
			jmp	:test_sort_dir		;ggf. sortieren.

;--- Dateien von Disk einlesen.
::get_files_disk	jsr	readDir_Disk		;Dateien von Disk laden.

			jsr	SaveCacheCRC		;BAM-CRC erzeugen.

;--- Dateiliste initialisieren.
;Wird ausgeführt, wenn Dateien von Disk
;eingelesen wurden:
;* Dateiauswahl löschen.
;* Dateien sortieren.
::6			ldx	WM_WCODE		;Dateiauswahl löschen.
			lda	#$00
			sta	WMODE_SLCT,x

			lda	WMODE_SORT,x		;Fenster sortieren?
			beq	:save_drv_data		; => Nein, Ende...

			and	#%01111111		;Flag löschen: Fenster sortiert.
			sta	WMODE_SORT,x		;Anschließend immer weiter
			bpl	:sort_dir		;zur Sortierroutine -> JMP.

;--- Prüfen auf "Dateien sortieren".
;Wird ausgeführt wenn die Sortierung
;geändert werden soll oder die Dateien
;aus dem Cache eingelesen wurden.
::test_sort_dir		ldx	WM_WCODE
			lda	WMODE_SORT,x		;Fenster sortieren?
			beq	:save_drv_data		; => Nein, Ende...
			bmi	:save_drv_data		; => Bereits sortiert, Ende...

;--- Dateiliste sortieren.
::sort_dir		jsr	xSORT_ALL_FILES		;Falls "Neue Ansicht" oder wenn kein
							;Cache aktiv, dann ist eventuell
							;Sortiermodus für Fenster gesetzt.

;--- Laufwerksdaten für Dateien im RAM speichern.
::save_drv_data		ldx	WM_WCODE		;Aktuelle Fensternummer speichern.
			stx	getFileWin

			lda	WIN_DRIVE,x		;Aktuelles Laufwerk speichern.
			sta	getFileDrv

			tay
			lda	RealDrvMode -8,y	;CMD-Laufwerk?
			bpl	:3			; => Nein, weiter...
			lda	WIN_PART,x		;Aktuelle Partition speichern.
			sta	getFilePart

::3			lda	RealDrvMode -8,y
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:4			; => Nein, weiter...

			lda	WIN_SDIR_T,x		;Zeiger auf Unterverzeichnis
			sta	getFileSDir +0		;speichern.
			lda	WIN_SDIR_S,x
			sta	getFileSDir +1

::4			jsr	SET_LOAD_CACHE		;GetFiles-Flag zurücksetzen.

			ldx	#NO_ERROR
			rts

;*** Dateien von Disk laden.
:readDir_Disk		jsr	i_FillRam		;Verzeichnis-Speicher löschen.
			w	MAX_DIR_ENTRIES * 32
			w	BASE_DIRDATA
			b	$00

;--- Daten initialisieren.
			lda	#$00			;Dateizähler löschen.
			sta	WM_DATA_MAXENTRY

			jsr	ADDR_RAM_r15		;Zeiger auf Verzeichnis im RAM.

;--- Zeiger auf Verzeichnis setzen.
;Dabei wird entweder der erste Sektor
;gesetzt oder aber für "Mehr Dateien"
;das Verzeichnis auf Pos.X gesetzt.
			jsr	Set1stDirSek		;Ersten Verzeichnis-Eintrag lesen.
			jmp	:test_entry		;Laufwerksfehler/Verzeichnis-Ende?

;--- Verzeichnis-Eintrag einlesen.
::test_next_entry	jsr	TestDirEntry		;Verzeichnis-Eintrag testen und
			txa				;ggf. in Speicher kopieren.
			bne	:buffer_full		; => Ende, Puffer voll...

;--- Nächster Eintrag...
			MoveB	r1L,r12L		;Position innerhalb Verzeichnis
			MoveB	r1H,r12H		;zwischenspeichern.
			MoveW	r5,r13

			jsr	usrNxtDirEntry		;Nächsten Eintrag lesen.

;--- Laufwerksfehler/Verzeichnis-Ende?
::test_entry		txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:test_next_entry	; => Weiter mit nächsten Eintrag.

			jmp	readDir_EOD		;Verzeichnis-Ende erreicht.

;--- Laufwerksfehler.
::err			jmp	readDir_Exit		;Laufwerksfehler, Abbruch...

;--- Speicher voll, "Weitere Dateien" hinzufügen.
::buffer_full		ldx	WM_WCODE
			lda	#$7f			;Flag setzen:
			sta	WIN_DIR_START,x		;Die aktuellen Dateien einlesen.

			lda	r12L			;Letzten Verzeichnis-Sektor und
			sta	WIN_DIR_NX_TR,x 		;Eintrag speichern.
			lda	r12H
			sta	WIN_DIR_NX_SE,x
			lda	r13L
			sta	WIN_DIR_NX_POS,x

			ldy	#$1f			;Eintrag "Weitere Dateien"
::1			lda	entryMoreFiles,y	;erstellen.
			sta	(r14L),y
			dey
			bpl	:1

			jmp	readDir_Done		;Seite voll...

;*** Komplettes Verzeichnis eingelesen.
:readDir_EOD		ldx	WM_WCODE		;Keine weiteren Dateien.
			lda	#$00 			;Daten für "Weitere Dateien"
			sta	WIN_DIR_NX_TR,x		;zurücksetzen.
			sta	WIN_DIR_NX_SE,x
			sta	WIN_DIR_NX_POS,x
			lda	#$7f			;Flag setzen:
			sta	WIN_DIR_START,x		;Die aktuellen Dateien einlesen.

;--- Dateien gefunden?
;Falls Nein, dann auf PagingMode testen
;und ggf. das Verzeichnis von Anfang an
;automatisch neu einlesen.
;Werden auf der aktuellen Seite alle
;Dateien gelöscht, dann springt das
;Programm damit zum Anfang zurück.
			lda	WM_DATA_MAXENTRY
			bne	readDir_Done		; => Dateien im Speicher, weiter...

;--- Auf leeres Medium testen.
			lda	read1stDirEntry		;PagingMode aktiv?
			beq	readDir_Done		; => Nein, Ende...

;--- Keine Dateien auf aktueller Seite.
			;ldx	WM_WCODE
			jsr	resetDirData		;Zurück zum Anfang und
			sta	WIN_DIR_START,x		;Verzeichnis neu einlesen.
			jmp	readDir_Disk

;*** Verzeichnis eingelesen.
:readDir_Done		lda	WM_DATA_MAXENTRY
			beq	readDir_Exit		; => Keine Dateien vorhanden...

;--- Auf Icon-Anzeige testen.
			ldx	WM_WCODE
			lda	WMODE_VICON,x		;Anzeige-Modus einlesen.
			bne	:10			; => Keine Icons anzeigen.

;--- Auf Icon-Cache/Preload testen.
			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:10			; => Nein, weiter...

			bit	GD_ICON_PRELOAD		;Icons vorab laden?
			bpl	:10			; => Nein, weiter...

			jsr	LoadIconToCache		;Icons in Cache kopieren.

;--- Hinweis:
;":LoadIconToCache" setzt das Flag
;"Icon im Cache" im Verzeichnis-Eintrag!
::10			jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache.
			jsr	StashRAM		;Verzeichnis in Cache speichern.

;*** Ende, Fensterdaten aktualisieren.
:readDir_Exit		jmp	WM_SAVE_WIN_DATA	; => Ende...

;*** Zeiger auf Anfang Verzeichnis setzen.
:Set1stDirSek		lda	curFilterMode		;Filtermodus einlesen.
			beq	:skip_other		; => Alle Dateien...
			bmi	:skip_other		; => Dateityp...
			and	#%00011111		;GEOS-Borderblock?
			beq	:skip_other		; => Nein, weiter...

;--- Borderblock ab Anfang einlesen.
			jsr	GetBorderBlock		;Adresse Borderblock ermitteln.
			txa				;Diskettenfehler?
			bne	:skip_other		; => Ja, kein Borderblock-Menü.
			tya				;Keine GEOS-Diskette?
			bne	:skip_other		; => Ja, kein Borderblock-Menü.

			jmp	usrGetDirBlock		;Borderblock einlesen.

;--- Standard-Verzeichnis.
::skip_other		ldx	WM_WCODE
			lda	WIN_DIR_TR,x		;PagingMode aktiv?
			sta	read1stDirEntry		;Modus speichern.
			bne	:1			; => Ja, weiter...

;--- Dateien ab Anfang einlesen.
			jsr	usr1stDirEntry		;Ersten Verzeichnis-Eintrag lesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;			lda	#$00			;Borderblock-Flag löschen.
			sta	readBorderBlock

::next_files		ldx	WM_WCODE
			lda	#$7f			;Flag setzen:
			sta	WIN_DIR_START,x		;Die aktuellen Dateien einlesen.

			lda	r1L			;Aktuellen Verzeichnis-Sektor und
			sta	WIN_DIR_TR,x 		;Eintrag speichern.
			lda	r1H
			sta	WIN_DIR_SE,x
			lda	r5L
			sta	WIN_DIR_POS,x

			ldx	#NO_ERROR		;Kein Fehler.
::err			rts

;--- Dateien ab aktueller Position einlesen.
::1			jsr	usr1stDirEntry		;Register auf Anfang setzen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			ldx	WM_WCODE		;Zeiger auf Verzeichnis-Sektor
			lda	WIN_DIR_TR,x		;setzen.
			sta	r1L
			lda	WIN_DIR_SE,x
			sta	r1H

			lda	WIN_DIR_POS,x		;Zeiger auf Verzeichnis-Eintrag in
			sta	r5L			;Verzeichnis-Sektor setzen.
			lda	#>diskBlkBuf
			sta	r5H

			LoadW	r4,diskBlkBuf		;Zeiger auf Verzeichnis-Sektor.
			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#$00			;Verzeichnis-Ende nicht erreicht.
			ldx	#NO_ERROR		;Kein Fehler.
			rts

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
			bne	usrGetDirBlock		; => Nein, weiter.

			lda	readBorderBlock		;Borderblock bereoits aktiv?
			bne	exitNxDirEntry		; => Ja, Ende...

			lda	curFilterMode		;Aktuellen Filtermodus einlesen.
			cmp	#%01000001		;Nur Borderblock?
			beq	exitNxDirEntry		; => Ja, Ende...

			dec	readBorderBlock		;Borderblock-Flag setzen.

			jsr	GetBorderBlock		;Adresse Borderblock ermitteln.
			txa				;Diskettenfehler?
			bne	exitNxDirEntry		; => Ja, kein Borderblock.
			tya				;Keine GEOS-Diskette?
			bne	exitNxDirEntry		; => Ja, kein Borderblock.

:usrGetDirBlock		LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Verzeichnisblock einlesen.
			txa				;Fehler?
			bne	exitNxDirEntry		; => Ja, Abbruch...

			tay				;Verzeichnis-Ende nicht erreicht.
			LoadW	r5,diskBlkBuf +2	;Zeiger auf ersten Eintrag.

:exitNxDirEntry		rts

;*** Verzeichnisdaten zurücksetzen.
;    Übergabe: XReg = Fenster-Nr.
:resetDirData		;ldx	WM_WCODE
			lda	#$00
			sta	WIN_DIR_TR,x		;Ja, Daten für Verzeichnis-
			sta	WIN_DIR_SE,x		;Position zurücksetzen.
			sta	WIN_DIR_POS,x
			sta	WIN_DIR_NR,x
			rts

;*** Verzeichnis-Eintrag testen und in Speicher übernehmen.
;    Übergabe: r5 = Zeiger auf 30-Byte-Verzeichnis-Eintrag.
;              diskBlkBuf = Verzeichnis-Sektor.
;              WM_DATA_MAXENTRY = Verzeichnis-Eintrag-Nr.
:TestDirEntry		ldx	WM_WCODE
			lda	WMODE_FILTER,x		;Filter-Modus einlesen und
			sta	curFilterMode		;zwischenspeichern.

			ldy	#$00
			lda	(r5L),y			;Dateityp einlesen.
			bne	:test_entry		; => Echte Datei, weiter...
			iny
			lda	(r5L),y			;Datenspur gesetzt?
			beq	:exit			; => Nein, kein Datei-Eintrag.

;--- Gelöschte Datei.
::test_deleted		jsr	:test_del		;Gelöschte Datei testen.
			bcc	:exit			; => Ungültig, nächster Eintrag.
			bcs	:test_buf_full		; => Datei übernehmen.

;--- Datei/Verzeichnis.
::test_entry		lda	curFilterMode		;Nur gelöschte Dateien anzeigen?
			cmp	#%01000000
			beq	:exit			; => Ja, nächster Eintrag.

			jsr	:test_dir		;Verzeichnis testen.
			bcs	:test_buf_full		; => Verzeichnis übernehmen.

;--- Dateifilter prüfen.
::test_filter		jsr	:test_file		;Dateityp testen.
			bcc	:exit			; => Ungültig, nächster Eintrag.

;--- Mehr als 160 Dateien?
::test_buf_full		lda	WM_DATA_MAXENTRY
			cmp	#MAX_DIR_ENTRIES
::1			bcs	:error			; => Nein, weiter...

			jsr	:copy_entry		;Eintrag übernehmen.

::exit			ldx	#$00
			rts

::error			ldx	#$ff
			rts

;--- Eintrag testen: Gelöschte Datei.
::test_del		lda	curFilterMode		;Bit%6 = "Gelöscht"-Filter aktiv?
			cmp	#%01000000
			beq	:test_del_ok		; => Ja, Datei anzeigen.

			bit	GD_VIEW_DELETED		;Gelöschte Dateien anzeigen ?
			bpl	:test_del_bad		; => Nein, Ende...

			bit	curFilterMode		;Filter aktiv?
			bpl	:test_del_ok		; => Nein, gelöschte Datei anzeigen.

			jmp	:test_gtype		;GEOS-Dateityp testen.

::test_del_ok		sec				; => Gültig.
			rts

::test_del_bad		clc				; => Ungültig.
			rts

;--- Eintrag testen: Verzeichnis.
::test_dir		ldy	#$00
			lda	(r5L),y			;Dateityp einlesen.
			and	#ST_FMODES		;Dateiformat isolieren.
			cmp	#DIR			;CMD-Verzeichnis?
			bne	:test_dir_bad		; => Ja, weiter...

::test_dir_ok		sec				; => Gültig.
			rts

::test_dir_bad		clc				; => Ungültig.
			rts

;--- Eintrag testen: Datei.
::test_file		ldy	#$16
			lda	(r5L),y			;GEOS-Dateityp einlesen.
			tax

			bit	GD_HIDE_SYSTEM		;Systemdateien ausblenden ?
			bpl	:21			; => Nein, weiter...

			cpx	#SYSTEM			;Systemdatei ?
			beq	:test_file_bad		; => Ja, ignorieren.
			cpx	#SYSTEM_BOOT		;Startdatei ?
			beq	:test_file_bad		; => Ja, ignorieren.
			cpx	#DISK_DEVICE		;Laufwerkstreiber ?
			beq	:test_file_bad		; => Ja, ignorieren.

::21			bit	GD_HIDE_SYSTEM		;Drucker/Eingabe ausblenden ?
			bvc	:22			; => Nein, weiter...

			cpx	#PRINTER		;Druckertreiber ?
			beq	:test_file_bad		; => Ja, nächster Eintrag.
			cpx	#INPUT_DEVICE		;Eingabetreiber ?
			beq	:test_file_bad		; => Ja, nächster Eintrag.
			cpx	#INPUT_128		;Eingabetreiber GEOS128 ?
			beq	:test_file_bad		; => Ja, nächster Eintrag.
			cpx	#GEOFAX_PRINTER		;Druckertreiber GeOFAX ?
			beq	:test_file_bad		; => Ja, nächster Eintrag.

::22			lda	GD_HIDE_SYSTEM		;Schreibgeschütze Dateien
			and	#%00100000		;ausblenden ?
			beq	:23			; => Nein, weiter...

			ldy	#$00
			lda	(r5L),y			;Dateityp einlesen.
			and	#ST_WR_PR		;Schreibschutz aktiv ?
			bne	:test_file_bad		; => Ja, nächster Eintrag.

::23			bit	curFilterMode		;Filter aktiv?
			bpl	:test_file_ok		; => Nein, weiter...

			txa

::test_gtype		ora	#%10000000		;Bit#7 für Vergleich setzen.
			cmp	curFilterMode		;Datei für Filter gültig?
			bne	:test_file_bad		; => Nein, nächster Eintrag.

::test_file_ok		sec				; => Gültig.
			rts

::test_file_bad		clc				; => Ungültig.
			rts

;--- Eintrag übernehmen.
::copy_entry		ldy	#$00
			lda	#GD_MODE_UNSLCT
			sta	(r15L),y		;Flag für "Dateiauswahl" löschen.
			iny
			lda	#GD_MODE_NOICON
			sta	(r15L),y		;Flag für "Icon im Cache" löschen.

::11			dey
			lda	(r5L),y			;Verzeichnis-Eintrag kopieren.
			iny
			iny
			sta	(r15L),y
			cpy	#32 -1			;Verzeichnis-Eintrag kopiert?
			bcc	:11			; => Nein, weiter...

			lda	r15L			;Zeiger auf nächsten Eintrag.
			sta	r14L
			clc
			adc	#< 32
			sta	r15L
			lda	r15H
			sta	r14H
			adc	#> 32
			sta	r15H

			inc	WM_DATA_MAXENTRY

::12			rts

;*** Datei-Icons in Cache kopieren.
:LoadIconToCache	lda	#$00			;Datei-Zähler löschen.
			sta	r11L
			sta	r11H

			sta	r14L			;Zeiger auf ersten Eintrag
			jsr	SET_POS_CACHE

			jsr	ADDR_RAM_r15		;Anfang Verzeichnis im RAM.

::test_entry		jsr	GetVecIcon_r0		;Icon einlesen.

			lda	r0L
			ora	r0H			;Icon eingelesen?
			beq	:next_entry		; => Nein, weiter...

::save_entry		MoveW	r13,r1
			LoadW	r2,64			;Größe Icon-Eintrag.
			lda	r12L			;Speicherbank (:SET_POS_CACHE).
			sta	r3L
			jsr	StashRAM		;Icon in Cache kopieren.

::next_entry		AddVBW	32,r15			;Zeiger auf nächsten
							;Verzeichnis-Eintrag im RAM.

			AddVBW	64,r13			;Zeiger auf nächsten
							;Icon-Eintrag im RAM.

			inc	r11L			;Datei-Zähler erhöhen.

::1			lda	r11L
			cmp	WM_DATA_MAXENTRY
			beq	:exit
::2			jmp	:test_entry		; => Nein, weiter...

::exit			rts				;Ende.

;*** Zeiger auf Datei-Icon einlesen.
;Hier werden nur GEOS-Infoblock-Icons eingelesen!
;    Übergabe: r15 = 32-Byte Verzeichnis-Eintrag.
;    Rückgabe: r0  = $0000 = Kein Icon.
;                  > $0000 = Zeiger auf GEOS-Icon.
:GetVecIcon_r0		lda	#$00			;Zeiger auf Icon löschen.
			sta	r0L
			sta	r0H

			ldy	#$02
			lda	(r15L),y		;Datei "gelöscht"?
			beq	:exit			; => Ja, Ende...

			cmp	#GD_MORE_FILES		;Eintrag "Weitere Dateien"?
			beq	:exit			; => Ja, Ende...

			and	#ST_FMODES		;Dateityp isolieren.
			cmp	#DIR			;Dateityp = "Verzeichnis"?
			beq	:exit			; => Ja, Ende...

			ldy	#$18
			lda	(r15L),y		;GEOS-Datei?
			beq	:exit			; => Nein, Ende...

			ldy	#$15
			lda	(r15L),y		;GEOS-Datei mit FileHeader?
			beq	:exit			; => Nein, Ende...
			sta	r1L
			iny
			lda	(r15L),y
			sta	r1H
			LoadW	r4,fileHeader		;Zeiger auf Zwischenspeicher.

			ldy	#$01
			lda	#GD_MODE_ICACHE
			sta	(r15L),y		;Flag "Icon im Cache" setzen.

			jsr	GetBlock		;GEOS-FileHeader einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			lda	#< fileHeader+4		;Zeiger auf Icon-Daten.
			ldx	#> fileHeader+4
			bne	:set_icon_vec

::error			lda	#< Icon_DEL		;Fehler File-Header:
			ldx	#> Icon_DEL		;Ersatz-icon "Gelöscht" verwenden.

::set_icon_vec		sta	r0L			;Zeiger auf Icon-Daten speichern.
			stx	r0H
::exit			rts

;*** Prüfen ob Dateien aus Cache eingelesen werden können.
;Wird :GD_RELOAD_DIR auf $FF gesetzt werden die Daten immer
;von Disk eingelesen. Evtl. Sinnvoll nach einem Reboot in den
;Desktop wenn andere Programme Daten auf Disk geändert haben.
;Aktuell wird die BAM geprüft, das funktioniert auf NativeMode
;aber nur bedingt (es werden nicht alle BAM-Sektoren getestet).
:TestCacheBAM		bit	GD_RELOAD_DIR		;BAM testen?
			bvc	:cache_fault		; => Nein, Ende...

::verify1541		jsr	SetBAMCache1Sek		;Zeiger auf ersten BAM Sektor.
			bne	:verify1571
			jsr	VerifyRAM		;Mit Kopie im Speicher vergleichen.
			and	#%00100000		;Cache-Fehler?
			bne	:cache_fault		; => Cache veraltet, Disk öffnen.

::verify1571		jsr	SetBAMCache2Sek		;Zeiger auf zweiten BAM Sektor.
			bne	:verify1581		; => 1541, Ende...
			jsr	VerifyRAM		;Mit Kopie im Speicher vergleichen.
			and	#%00100000		;Cache-Fehler?
			bne	:cache_fault		; => Cache veraltet, Disk öffnen.

::verify1581		jsr	SetBAMCache3Sek		;Zeiger auf zweiten BAM Sektor.
			bne	:verifyNative		; => 1541, Ende...
			jsr	VerifyRAM		;Mit Kopie im Speicher vergleichen.
			and	#%00100000		;Cache-Fehler?
			bne	:cache_fault		; => Cache veraltet, Disk öffnen.

::verifyNative		ldy	curDrvMode		;Laufwerksmodus einlesen.
			ldx	BAMCopySekInfo4,y
			bne	:cache_ok

			jsr	CreateNM_CRC		;BAM-CRC prüfen.
			txa				;Disk-Fehler?
			bne	:cache_fault		; => Ja, Disk öffnen.

			jsr	SetBAMCache4Sek		;BAM-CRC erstellen.
			jsr	VerifyRAM		;Mit Kopie im Speicher vergleichen.
			and	#%00100000		;Cache-Fehler
			beq	:cache_ok		; => Nein, Cache gültig...

;--- Verzeichnis geändert,
;    Dateien von Disk laden.
::cache_fault		ldx	#$ff
			rts

;--- Verzeichnis nicht geändert,
;    Dateien aus Cache laden.
::cache_ok		ldx	#$00
			rts

;*** Cache-Modus: Aktuelle BAM sichern.
:SaveCacheCRC
::upd1541		jsr	SetBAMCache1Sek		;Ersten BAM-Sektor sichern?
			bne	:upd1571		; => Nein, weiter...
			jsr	StashRAM

::upd1571		jsr	SetBAMCache2Sek		;Zweiten BAM-Sektor sichern?
			bne	:upd1581		; => Nein, weiter...
			jsr	StashRAM

::upd1581		jsr	SetBAMCache3Sek		;Dritten BAM-Sektor sichern?
			bne	:updNative		; => Nein, weiter...
			jsr	StashRAM

::updNative		ldy	curDrvMode		;Laufwerksmodus einlesen.
			ldx	BAMCopySekInfo4,y	;Native-BAM sichern?
			bne	:exit			; => Nein, Ende...

			jsr	CreateNM_CRC		;BAM-CRC prüfen.
			txa				;Disk-Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	SetBAMCache4Sek		;Native-BAM sichern?.
			jmp	StashRAM
::exit			rts

;*** CRC für Native-Mode BAM erstellen.
:CreateNM_CRC		jsr	i_FillRam		;CRC-Puffer löschen.
			w	256
			w	diskBlkBuf
			b	$00

;--- Hinweis:
;Zum testen auf EnterTurbo/InitForIO
;verzichten. Grund: Am C64 mit TC64
;hängt die Routine GetBAMBlock beim
;warten auf $DD00/DATA_IN_LOW.
;Das Problem tritt aber nicht immer
;auf. GetBlock an Stelle von ReadBlock
;scheint das Timing-Problem zu lösen.
;			jsr	EnterTurbo		;TurboDOS aktivieren.
;			jsr	InitForIO		;I/O-Bereich ausblenden.

;TurboDOS zurücksetzen.
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	NewDisk			;Disk initialisieren.
;---

			ldx	#$02			;Zeiger auf ersten BAM-Sektor.
::1			txa
			pha
			jsr	GetBAMBlock		;BAM-Sektor einlesen.
			pla
			cpx	#NO_ERROR		;Fehler?
			bne	:exit1			; => Ja, Abbruch...

			ldy	#< dir2Head		;Zeiger auf BAM-Sektor.
			sty	r0L
			ldy	#> dir2Head
			sty	r0H
			stx	r1L
			inx
			stx	r1H
			pha
			jsr	CRC			;CRC für BAM-Sektor berechnen.w
			pla
			tax
			asl
			tay
			lda	r2L			;CRC in Puffer kopieren.
			sta	diskBlkBuf +0,y
			lda	r2H
			sta	diskBlkBuf +1,y

			cpx	#$02			;Erster BAM-Sektor?
			bne	:2			; => Nein, weiter...
			lda	dir2Head +8		;Anzahl Tracks einlesen und
			sta	BAMTrackMaxNM		;zwischenspeichern.

::2			inx
			lda	BAMTrackCntNM-2,x
			cmp	BAMTrackMaxNM		;Max. Anzahl Tracks erreicht?
			bcs	:3			; => Ja, Ende...
			cpx	#33			;Max. Anzahl BAM-Sektoren erreicht?
			bcc	:1			; => Nein, weiter...

;--- BAM-CRC erstellt, Ende.
::3			ldx	#NO_ERROR		;Ende...

::exit1

;--- HINWEIS:
;Zum testen auf EnterTurbo/InitForIO
;verzichten. ":DoneWithIO" entfällt.
;			jmp	DoneWithIO		;I/O-Bereich ausblenden.
;---

			rts

;*** Zeiger auf Cache-Bereich für BAM-Sektoren.
;--- 1541/1571/1581/Native.
:SetBAMCache1Sek	ldx	curDrive
			lda	driveType -8,x
			and	#ST_FMODES		;Laufwerksmodus isolieren.
			sta	curDrvMode

			tay
;			ldy	curDrvMode		;Laufwerkstyp einlesen.
			ldx	BAMCopySekInfo1,y
			bne	SetBAMCacheExit
			lda	#< curDirHead		;Zeiger auf ersten BAM-Sektor.
			ldx	#> curDirHead
			ldy	#$00
			beq	SetBAMCacheInit

;--- 1571/1581.
:SetBAMCache2Sek	ldy	curDrvMode		;Laufwerkstyp einlesen.
			ldx	BAMCopySekInfo2,y
			bne	SetBAMCacheExit
			lda	#< dir2Head		;1571, 1581 oder Native.
			ldx	#> dir2Head		;Zeiger auf 2ten BAM-Sektor.
			ldy	#$01
			bne	SetBAMCacheInit

;--- 1581.
:SetBAMCache3Sek	ldy	curDrvMode		;Laufwerkstyp einlesen.
			ldx	BAMCopySekInfo3,y
			bne	SetBAMCacheExit

			cpy	#DrvNative		;NativeMode ?
			bne	:1			; => Nein, Abbruch...
			lda	#< DISK_BASE		; => Native, Variablen testen.
			ldx	#> DISK_BASE
			bne	:2

::1			lda	#< dir3Head		; => 1581, dir3Head testen.
			ldx	#> dir3Head
::2			ldy	#$02
			bne	SetBAMCacheInit

;--- Native.
:SetBAMCache4Sek	lda	#< diskBlkBuf		;1571, 1581 oder Native.
			ldx	#> diskBlkBuf		;Zeiger auf 2ten BAM-Sektor.
			ldy	#$03

:SetBAMCacheInit	sta	r0L			;Zeiger auf CRC-Speicher im RAM.
			stx	r0H

			lda	WM_WCODE		;Zeiger auf CRC-Speicher in
			asl				;GEOS-DACC berechnen.
			tax
			clc
			lda	#$00
			adc	vecBAMDataRAM +0,x
			sta	r1L
			tya
			adc	vecBAMDataRAM +1,x
			sta	r1H

			LoadW	r2,256			;Größe CRC-Speicher.

			lda	GD_SYSDATA_BUF		;64Kb Speicherbank für
			sta	r3L			;CRC-Daten setzen.

			ldx	#$00			;XReg = $00, BAM-Sektor verfügbar.
:SetBAMCacheExit	rts				;XReg = $FF, nicht verfügbar.

;*** Dateien im Speicher sortieren.
;Sortieralgorythmus:
;        a5 = Anfang IconCache/Startwert.
;
;:loop1  a7 = 0
;        a8 = 0
;        a9 = MaxFiles -1
;
;        a1 = Anfang
;        a2 = Anfang +1
;        a3 = Anfang IconCache
;        a4 = Anfang IconCache +1
;
;        a1 > a2 ?
;        FALSE -> loop2
;
;        a2 <=> a1
;        a4 <=> a3
;        a7 = 1
;
;:loop2  a8 < a9 ?
;        TRUE -> loop1
;        a7 = 1 ?
;        TRUE -> loop1
;
:SORTFILES_INFO		= 80				;Ab 80 Dateien Hinweis anzeigen.

:xSORT_ALL_FILES	ldx	WM_WCODE
			ldy	WMODE_SORT,x		;Fenster sortieren?
			beq	:no_sort		; => Nein, Ende...

			lda	WM_DATA_MAXENTRY+0
			cmp	#$02			;Meh als eine Datei?
			bcs	:do_sort		; => Ja, weiter...

::no_sort		ldx	#$ff			;Weniger als 2 Dateien, Ende...
			rts

;--- Zeiger auf Sortierroutine.
::do_sort		tya				;Vektor auf Sortier-Routine.
			asl				;In ":a0" ablegen da die restlichen
			tax				;":rX" Adressen evtl. durch ":BMult"
			lda	vecSortMode+0,x		;in ":SET_POS_CACHE" verändert
			sta	a0L			;werden können.
			lda	vecSortMode+1,x
			sta	a0H

;--- Adressen Eintrag im Icon-Cache.
			lda	#$00			;Zeiger auf aktuellen Verzeichnis-
			sta	r14L			;Eintrag im Cache berechnen.
			jsr	SET_POS_CACHE
			MoveW	r13,a5

;--- Schleifenzähler initialisieren.
			lda	WM_DATA_MAXENTRY
			sec
			sbc	#$01			;Max. Anzahl Durchläufe -1.
			sta	a9L

;--- Hinweis ausgeben.
			jsr	setSortInfo		;"Sortiere Verzeichnis..."

;--- BubbleSort.
:BSort			lda	#$00
			sta	a7L			;Werte zurücksetzen.
			sta	a8L

			LoadW	a1,BASE_DIRDATA +0
			LoadW	a2,BASE_DIRDATA +32
			MoveW	a5,a3			;Zeiger auf Icon-Cache.

;--- Sekundärschleife.
::1			lda	a3L			;Zeiger auf Nachbar-Eintrag.
			clc
			adc	#< 64
			sta	a4L
			lda	a3H
			adc	#> 64
			sta	a4H

			ldy	#$02
			lda	(a2L),y
			cmp	#$ff			;"Weitere Dateien"?
			beq	:3			; => Ja, nicht sortieren.

			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:2			; => Nein, weiter...

			lda	GD_ICON_PRELOAD		;Icons vorab laden?
			bmi	:2			; => Ja, weiter...

			ldy	#$01			;Nur wenn Icons nicht vorab in den
			lda	#GD_MODE_NOICON		;Cache geladen werden dann Cache
			sta	(a1L),y			;Flag löschen -> Schneller.
			sta	(a2L),y			;Flag löschen -> Schneller.

::2			lda	a0L			;Einträge vergleichen.
			ldx	a0H
			jsr	CallRoutine
;			beq	:3			;Nur C-Flag auswerten.
			bcc	:3			; => Nicht sortieren.

			jsr	SwapEntry		;Eintrag tauschen.

;--- Optimierung:
;Für den nächsten Durchgang nur bis
;zum zuletzt getauschten Element
;sortieren, da danach nur größere
;Elemente folgen.
;;;			LoadB	a7L,1
			lda	a8L			;Aktuelle Datei als neues Ende
			clc				;für Primärschleife setzen.
			adc	#$01
			sta	a7L

::3			MoveW	a2,a1			;Zeiger auf nächsten
			AddVBW	32,a2L			;Verzeichnis-Eintrag.

			MoveW	a4,a3			;Zeiger auf nächsten
							;IconCache-Eintrag.
			inc	a8L

::3a			lda	a8L
			cmp	a9L			;Alle Einträge geprüft?
::3b			bcc	:1			; => Nein, weiter...

;--- Optimierung:
;Für den nächsten Durchgang nur bis
;zum zuletzt getauschten Element
;sortieren, da danach nur größere
;Elemente folgen.
			lda	a7L			;Wurden Einträge getauscht?
			sta	a9L
			beq	:done			; => Nein, Ende...
			jmp	BSort			; => Weitersortieren.

;--- Verzeichnisdaten in Cache kopieren.
::done			lda	#$00			;Zeiger auf aktuellen Verzeichnis-
			sta	r14L			;Eintrag im Cache berechnen.
			jsr	SET_POS_CACHE

			LoadW	r0,BASE_DIRDATA		;Daten für Verzeichnis-Cache
			MoveW	r14,r1			;setzen und aktualisieren.
			LoadW	r2,MAX_DIR_ENTRIES*32
			lda	GD_SYSDATA_BUF
			sta	r3L
			jsr	StashRAM

;--- Hinweis löschen.
			jsr	resetSortInfo		;Hinweistext löschen.

;--- Ende.
			ldx	WM_WCODE		;Flag setzen: Verzeichnis sortiert.
			lda	WMODE_SORT,x
			ora	#%10000000
			sta	WMODE_SORT,x

			ldx	#$00			;Dateien sortiert, Ende.
			rts

;*** Einträge vertauschen.
;    a1 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a2 = Zeiger auf nächsten Verzeichnis-Eintrag im Speicher.
;    a3 = Zeiger auf aktuellen Icon-Eintrag im Cache.
;    a4 = Zeiger auf nächsten Icon-Eintrag im Cache.
:SwapEntry		ldy	#$1f			;Einträge im Speicher tauschen.
::101			lda	(a1L),y
			tax
			lda	(a2L),y
			sta	(a1L),y
			txa
			sta	(a2L),y
			dey
			bpl	:101

;--- Swap IconEntry.
			bit	GD_ICON_CACHE		;Icon-Cache aktiv?
			bpl	:no_cache		; => Nein, weiter...

			lda	GD_ICON_PRELOAD		;Icons vorab laden?
			bpl	:no_cache		; => Nein, weiter...

			lda	GD_ICONDATA_BUF		;Zeiger auf 64K-Speicherbank.
			beq	:no_cache		; => Kein Icon-Cache.
			sta	r3L

			LoadW	r0,fileHeader		;Zeiger auf Zwischenspeicher.
			MoveW	a3,r1			;Zeiger auf Icon-Eintrag.
			LoadW	r2,64			;Größe Icon-Eintrag.
			jsr	FetchRAM		;Icon-Eintrag einlesen.

			MoveW	a4,r1			;Zeiger auf Vergleichs-Eintrag und
			jsr	SwapRAM			;mit Icon-Eintrag tauschen.

			MoveW	a3,r1			;Vergleichs-Eintrag zurück
			jsr	StashRAM		;in Cache speichern.

::no_cache		rts

;*** Einträge vergleichen.
;    a1 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a2 = Zeiger auf nächsten Verzeichnis-Eintrag im Speicher.

;*** Modus: Name.
:SortName		ldy	#$05
			lda	(a1L),y			;Zuerst nach Buchstabe a=A
			jsr	:convert_upper		;vergleichen.
			sta	:101 +1
			lda	(a2L),y
			jsr	:convert_upper
::101			cmp	#$ff
			bcc	:106
			beq	:102
			bcs	:109

::102			lda	(a2L),y			;Hier unterscheiden zwischen
			cmp	(a1L),y			;Groß- und Kleinbuchstaben.
			beq	:108
			bcc	:109
::106			sec				;Eintrag tauschen/sortieren.
			rts

::104			ldy	#$05			;Zeichen vergleichen.
::105			lda	(a2L),y
			cmp	(a1L),y
			bcc	:106

::107			bne	:109
::108			iny				;Weitervergleichen bis
			cpy	#$15			;alle 11 Zeichen geprüft.
			bne	:105
::109			clc
			rts

::convert_upper		cmp	#$61			;Kleinbuchstaben in
			bcc	:13			;Großbuchstaben wandeln.
			cmp	#$7e			;Sortieren nach Buchstabe a=A,...
			bcs	:13			;Kein Unterschied Groß/Klein.
::12			sec
			sbc	#$20
::13			rts

;*** Modus: Größe.
:SortSize		ldy	#$1f
			lda	(a2L),y
			cmp	(a1L),y
			bcs	:102
::101			sec				;Eintrag tauschen/sortieren.
			rts

::102			bne	:103
			dey
			lda	(a2L),y
			cmp	(a1L),y
			bcc	:101
			bne	:103
			jmp	SortName		;Größe gleich, nach Name sortieren.

::103			clc
			rts

;*** Modus: Datum/Aufwärts.
:SortDateUp		jsr	ConvertDate		;yy/mm/dd nach yyyy/mm/dd wandeln.

			ldx	#$00
::101			lda	dateFile_a2,x
			cmp	dateFile_a1,x
			bcs	:103
::102			sec				;Eintrag tauschen/sortieren.
			rts

::103			bne	:104
			inx
			cpx	#$06
			bcc	:101
			jmp	SortName		;Datum gleich, nach Name sortieren.

::104			clc
			rts

;*** Modus: Datum/Abwärts.
:SortDateDown		jsr	ConvertDate		;yy/mm/dd nach yyyy/mm/dd wandeln.

			ldx	#$00
::101			lda	dateFile_a2,x
			cmp	dateFile_a1,x
			bcs	:103
::102			clc
			rts

::103			bne	:104
			inx
			cpx	#$06
			bcc	:101
			jmp	SortName		;Datum gleich, nach Name sortieren.

::104			sec				;Eintrag tauschen/sortieren.
			rts

;*** Modus: BASIC-Dateityp.
:SortTyp		ldy	#$02
			lda	(a1L),y			;BASIC-Dateityp #1 einlesen.
			and	#ST_FMODES
			sta	:101 +1
			lda	(a2L),y			;BASIC-Dateityp #2 einlesen.
			and	#ST_FMODES
::101			cmp	#$ff			;BASIC-Dateityp vergleichen.
			beq	:103			; => Identisch, nach Name sortieren.
			bcs	:102			; => Größer, Ende...
			sec				;Eintrag tauschen/sortieren.
			rts

::103			jmp	SortName		;Typ gleich, nach Name sortieren.

::102			clc
			rts

;*** Modus: GEOS-Dateityp/Priorität.
;Anwendungen zuerst, danach Dokumente.
;Systemdateien am Ende.
:SortGEOS		ldy	#$02
			lda	(a1L),y			;CBM-Dateityp einlesen.
			and	#ST_FMODES
			cmp	#DIR			;Typ = Verzeichnis?
			bne	:11			; => Nein, weiter...

			lda	#$ff			;Verzeichnisse an Ende sortieren.
			bne	:12

::11			ldy	#$18
			lda	(a1L),y			;GEOS-Dateityp einlesen und
			jsr	:get_priority		;in GEOS-Priorität konvertieren.
::12			sta	:30 +1

			ldy	#$02
			lda	(a2L),y			;CBM-Dateityp einlesen.
			and	#ST_FMODES
			cmp	#DIR			;Typ = Verzeichnis?
			bne	:21			; => Nein, weiter...
			lda	#$ff			;Verzeichnisse an Ende sortieren.
			bne	:30
::21			ldy	#$18
			lda	(a2L),y			;GEOS-Dateityp einlesen und
			jsr	:get_priority		;in GEOS-Priorität konvertieren.

::30			cmp	#$ff
			beq	:31
			bcs	:32
			sec				;Eintrag tauschen/sortieren.
			rts

::31			jmp	SortName		;GEOS gleich, nach Name sortieren.

::32			clc
			rts

;--- GEOS-Datei nach Priorität sortieren.
::get_priority		cmp	#$10
			bcs	:exit
			tax
			lda	GEOS_Priority,x
::exit			rts

;*** Datum von yy/mm/dd nach yyyy/mm/dd konvertieren.
:ConvertDate		ldy	#$19
			ldx	#$01
::1			lda	(a1L),y			;Datum beider Verzeichnis-
			sta	dateFile_a1,x		;Einträge in Zwischenspeicher
			lda	(a2L),y			;kopieren.
			sta	dateFile_a2,x
			iny
			inx
			cpx	#$06
			bcc	:1

			jsr	chkDateTime_a1
			jsr	chkDateTime_a2

			lda	dateFile_a1 +1		;Jahrhundert für beide Verzeichnis-
			jsr	:century		;Einträge ermitteln.
			stx	dateFile_a1 +0
			lda	dateFile_a2 +1
			jsr	:century
			stx	dateFile_a2 +0
			rts

;--- Jahrhundert ermitteln.
::century		ldx	#19
			cmp	#80			;Jahr >= 80 => 1980.
			bcs	:99
			ldx	#20			;Jahr <  80 => 2000 - 2079.
::99			rts

;*** Auf gültiges Datum/Uhrzeit testen.
:chkDateTime_a1		ldx	#1
			b $2c
:chkDateTime_a2		ldx	#8
			stx	:exit +1

			lda	dateFile_a1,x		;Jahr.
			beq	:exit
			cmp	#99 +1			;Jahr =< 99?
			bcs	:exit			; => Nein, Fehler...

			inx
			lda	dateFile_a1,x		;Monat.
			beq	:exit
			cmp	#12 +1			;Monat =< 12?
			bcs	:exit			; => Nein, Fehler...

			inx
			lda	dateFile_a1,x		;Tag.
			beq	:exit
			cmp	#31 +1			;Tag =< 31?
			bcs	:exit			; => Nein, Fehler...

			inx
			lda	dateFile_a1,x		;Stunde.
			cmp	#24			;Stunde < 24?
			bcs	:exit			; => Nein, Fehler...

			inx
			lda	dateFile_a1,x		;Minute.
			cmp	#60			;Minute < 60?
			bcs	:exit			; => Nein, Fehler...

			rts				;Datum/Uhrzeit gültig.

;--- Fehlerhaftes Datum ersetzen.
::exit			ldx	#$ff

			lda	#80
			sta	dateFile_a1,x		;Jahr.
			inx
			lda	#1
			sta	dateFile_a1,x		;Monat.
			inx
			sta	dateFile_a1,x		;Tag.

;--- Fehlerhafte Uhrzeit ersetzen.
			lda	#00
			inx
			sta	dateFile_a1,x		;Stunde.
			inx
			sta	dateFile_a1,x		;Minute.
			rts

;*** Hinweistext ausgeben.
:setSortInfo		lda	WM_DATA_MAXENTRY
			cmp	#SORTFILES_INFO		;Mehr als eine Datei?
			bcc	:3			; => Ja, weiter...

::0			ldy	#iconSort_x *8 -1	;Grafikdaten speichern.
::1			lda	SCREEN_BASE,y
			sta	iconDataBuf,y
			dey
			bpl	:1

			ldy	#iconSort_x -1		;Farbdaten speichern.
::2			lda	COLOR_MATRIX,y
			sta	iconColorBuf,y
			dey
			bpl	:2

			jsr	i_BitmapUp		;Hinweis ausgeben.
			w	iconSort
			b	$00,$00
			b	iconSort_x,iconSort_y

			lda	#$12
			jsr	i_UserColor
			b	$00,$00,iconSort_x,$01

::3			rts

;*** Hinweistext löschen.
:resetSortInfo		lda	WM_DATA_MAXENTRY+0
			cmp	#SORTFILES_INFO		;Meh als eine Datei?
			bcc	:3			; => Ja, weiter...

::0			ldy	#iconSort_x *8 -1	;Grafikdaten zurücksetzen.
::1			lda	iconDataBuf,y
			sta	SCREEN_BASE,y
			dey
			bpl	:1

			ldy	#iconSort_x -1		;Farbdaten zurücksetzen.
::2			lda	iconColorBuf,y
			sta	COLOR_MATRIX,y
			dey
			bpl	:2

::3			rts

;*** Temporäe Kopie von driveType.
:curDrvMode		b $00

;*** Dateifilter für aktuelles Fenster.
:curFilterMode		b $00				;Bit%7=1: Dateifilter aktiv.
							;Bit%6=1: Andere Dateien...

;*** Flag für "Get1stDirEntry".
:read1stDirEntry	b $00				;$00 = Verzeichnisanfang.
							;$FF = PagingMode.
:readBorderBlock	b $00				;$FF = Borderblock aktiv.

;*** Tabelle mit BAM-Sektor-Info.
;$00 = BAM-Sektor vorhanden.
;$FF = BAM-Sektor nicht vorhanden.
;Type: NoDRV,1541,1571,1581,
;      Native,NoDRV,NoDRV,NoDRV
:BAMCopySekInfo1	b $ff,$00,$00,$00,$00,$ff,$ff,$ff
:BAMCopySekInfo2	b $ff,$ff,$00,$00,$ff,$ff,$ff,$ff
:BAMCopySekInfo3	b $ff,$ff,$ff,$00,$ff,$ff,$ff,$ff
:BAMCopySekInfo4	b $ff,$ff,$ff,$ff,$00,$ff,$ff,$ff

;*** Datentabelle mit Max. Track je BAM-Sektor.
:BAMTrackCntNM		b $01,$08,$10,$18,$20,$28,$30,$38
			b $40,$48,$50,$58,$60,$68,$70,$78
			b $80,$88,$90,$98,$a0,$a8,$b0,$b8
			b $c0,$c8,$d0,$d8,$e0,$e8,$f0,$f8

;*** Puffer für Max. Tracks/NativeMode.
:BAMTrackMaxNM		b $00

;*** Tabelle mit Zeigern auf die Sortier-Routinen.
:vecSortMode		w $0000				;Kein sortieren.
			w SortName
			w SortSize
			w SortDateUp
			w SortDateDown
			w SortTyp
			w SortGEOS

;*** Konvertierungstabelle GEOS-Dateityp.
:GEOS_Priority		b $03 ;$00 = nicht GEOS.
			b $04 ;$01 = BASIC-Programm.
			b $05 ;$02 = Assembler-Programm.
			b $07 ;$03 = Datenfile.
			b $0e ;$04 = Systemdatei.
			b $02 ;$05 = Hilfsprogramm.
			b $00 ;$06 = Anwendung.
			b $06 ;$07 = Dokument.
			b $08 ;$08 = Zeichensatz.
			b $09 ;$09 = Druckertreiber.
			b $0a ;$0a = Eingabetreiber.
			b $0c ;$0b = Laufwerkstreiber.
			b $0d ;$0c = Startprogramm.
			b $0f ;$0d = Temporär.
			b $01 ;$0e = Selbstausführend.
			b $0b ;$0f = Eingabetreiber 128.
			b $10 ;$10 = Unbekannt.

;*** Zwischenspeicher für Datum.
:dateFile_a1		s 07
:dateFile_a2		s 07

;*** Verzeichnis-Eintrag "Mehr Dateien".
:entryMoreFiles		b $00				;Nicht ausgewählt.
			b $ff				;Datei-Icon im Cache.
			b $ff				;Dateityp "More files..."
			b $00,$00			;Kein Track/Sektor für Eintrag.
if LANG = LANG_DE
::s			b ">Mehr Dateien..."		;Dateiname.
::e			s 17 - (:e - :s)
endif
if LANG = LANG_EN
::s			b ">More files..."		;Dateiname.
::e			s 17 - (:e - :s)
endif
			b $00,$00			;Kein Infoblock.
			b $00				;Dateistuktur SEQ/Vlir.
			b $00				;GEOS-Dateityp.
			b 80,1,1			;Datum.
			b 0,0				;Uhrzeit.
			b 0,0				;Dateigröße.

;*** Hinweis-Icons.
if LANG = LANG_DE
:iconSort
<MISSING_IMAGE_DATA>

:iconSort_x		= .x
:iconSort_y		= .y
endif
if LANG = LANG_EN
:iconSort
<MISSING_IMAGE_DATA>

:iconSort_x		= .x
:iconSort_y		= .y
endif

:iconDataBuf		s iconSort_x * 8
:iconColorBuf		s iconSort_x

;*** Endadresse testen:
			g BASE_DIRDATA
;***
