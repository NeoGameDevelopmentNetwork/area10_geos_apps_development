; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien für Laufwerksfenster einlesen.
;--- Enthält aktuelles Fenster bereits Daten?
:xGET_ALL_FILES		ldx	WM_WCODE		;Aktuelles Fenster einlesen.
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
::open_drive		jsr	OpenWinDrive		;Laufwerk öffnen.
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
			sta	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			sta	WM_DATA_MAXENTRY +1
endif
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
::get_files_std		lda	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_MAXENTRY +1
endif
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
			sta	WMODE_SLCT_L,x
if MAXENTRY16BIT = TRUE
			sta	WMODE_SLCT_H,x
endif

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
			w	(OS_VARS - BASE_DIR_DATA)
			w	BASE_DIR_DATA
			b	$00

;--- Daten initialisieren.
			lda	#$00			;Dateizähler löschen.
			sta	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			sta	WM_DATA_MAXENTRY +1
endif

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

			jsr	GetNxtDirEntry		;Nächsten Eintrag lesen.

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
			lda	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_MAXENTRY +1
endif
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
:readDir_Done		lda	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_MAXENTRY +1
endif
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
:Set1stDirSek		ldx	WM_WCODE
			lda	WIN_DIR_TR,x		;PagingMode aktiv?
			sta	read1stDirEntry		;Modus speichern.
			bne	:1			; => Ja, weiter...

;--- Dateien ab Anfang einlesen.
			jsr	Get1stDirEntry		;Ersten Verzeichnis-Eintrag lesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			ldx	WM_WCODE
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
::1			jsr	Get1stDirEntry		;Register auf Anfang setzen.
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

;*** Flag für "Get1stDirEntry".
:read1stDirEntry	b $00				;$00 = Verzeichnisanfang.
							;$FF = PagingMode.

;*** Verzeichnisdaten zurücksetzen.
;    Übergabe: XReg = Fenster-Nr.
:resetDirData		;ldx	WM_WCODE
			lda	#$00
			sta	WIN_DIR_TR,x		;Ja, Daten für Verzeichnis-
			sta	WIN_DIR_SE,x		;Position zurücksetzen.
			sta	WIN_DIR_POS,x
			sta	WIN_DIR_NR_L,x
			sta	WIN_DIR_NR_H,x
			rts

;*** Verzeichnis-Eintrag testen und in Speicher übernehmen.
;    Übergabe: r5 = Zeiger auf 30-Byte-Verzeichnis-Eintrag.
;              diskBlkBuf = Verzeichnis-Sektor.
;              WM_DATA_MAXENTRY = Verzeichnis-Eintrag-Nr.
:TestDirEntry		ldy	#$00
			lda	(r5L),y			;Dateityp einlesen.
			bne	:test_sdir		; => Echte Datei, weiter...
			iny
			lda	(r5L),y			;Datenspur gesetzt?
			beq	:exit			; => Nein, kein Datei-Eintrag.

::test_del_file		bit	GD_VIEW_DEL		;Gelöschte Dateien anzeigen?
			bpl	:exit			; => Nein, Ende...
			bmi	:test_buf_full		; => Ja, Datei anzeigen...

::test_sdir		bit	GD_VIEW_DEL		;Nur gelöschte Dateien anzeigen?
			bvs	:exit			; => Ja, Ende...

			and	#FTYPE_MODES		;Dateityp isolieren.
			cmp	#FTYPE_DIR		;CMD-Verzeichnis?
			beq	:test_buf_full		; => Ja, weiter...

::test_filter		ldx	WM_WCODE
			lda	WMODE_FILTER,x		;Filter aktiv?
			bpl	:test_buf_full		; => Nein, weiter...

			ldy	#$16
			lda	(r5L),y			;GEOS-Dateityp einlesen.
			ora	#%10000000		;Bit#7 für Vergleich setzen.
			cmp	WMODE_FILTER,x		;Datei für Filter gültig?
			bne	:exit			; => Nein, nächster Eintrag.

;--- Mehr als 160 Dateien?
::test_buf_full
if MAXENTRY16BIT = TRUE
			lda	WM_DATA_MAXENTRY +1
			cmp	#>MAX_DIR_ENTRIES
			bne	:copy_entry		; => Nein, weiter...
endif
			lda	WM_DATA_MAXENTRY +0
			cmp	#<MAX_DIR_ENTRIES
			bcs	:error			; => Nein, weiter...

;--- Eintrag gültig.
::copy_entry		ldy	#$00
			lda	#GD_MODE_UNSLCT
			sta	(r15L),y		;Flag für "Dateiauswahl" löschen.
			iny
			lda	#GD_MODE_NOICON
			sta	(r15L),y		;Flag für "Icon im Cache" löschen.

::loop1			dey
			lda	(r5L),y			;Verzeichnis-Eintrag kopieren.
			iny
			iny
			sta	(r15L),y
			cpy	#32 -1			;Verzeichnis-Eintrag kopiert?
			bcc	:loop1			; => Nein, weiter...

			lda	r15L			;Zeiger auf nächsten Eintrag.
			sta	r14L
			clc
			adc	#<32
			sta	r15L
			lda	r15H
			sta	r14H
			adc	#>32
			sta	r15H

			inc	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			bne	:exit
			inc	WM_DATA_MAXENTRY +1
endif

::exit			ldx	#$00
			rts

::error			ldx	#$ff
			rts

;*** Datei-Icons in Cache kopieren.
:LoadIconToCache	lda	#$00			;Datei-Zähler löschen.
			sta	r11L
			sta	r11H

			sta	r14L			;Zeiger auf ersten Eintrag
if MAXENTRY16BIT = TRUE
			sta	r14H			;im Cache setzen.
endif
			jsr	SET_POS_CACHE

			jsr	ADDR_RAM_r15		;Anfang Verzeichnis im RAM.

::test_entry		jsr	GetVecIcon_r0		;Icon einlesen.

			lda	r0L
			ora	r0H			;Icon eingelesen?
			beq	:next_entry		; => Nein, weiter...

::save_entry		MoveW	r13,r1
			LoadW	r2,64			;Größe Icon-Eintrag.
			MoveB	r12L,r3L		;Speicherbank (:SET_POS_CACHE).
			jsr	StashRAM		;Icon in Cache kopieren.

::next_entry		AddVBW	32,r15			;Zeiger auf nächsten
							;Verzeichnis-Eintrag im RAM.

			AddVBW	64,r13			;Zeiger auf nächsten
							;Icon-Eintrag im RAM.

			inc	r11L			;Datei-Zähler erhöhen.
if MAXENTRY16BIT = TRUE
			bne	:1
			inc	r11H
endif

::1
if MAXENTRY16BIT = TRUE
			lda	r11H			;Alle Einträge kopiert?
			cmp	WM_DATA_MAXENTRY +1
			bne	:2
endif
			lda	r11L
			cmp	WM_DATA_MAXENTRY +0
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

			and	#FTYPE_MODES		;Dateityp isolieren.
			cmp	#FTYPE_DIR		;Dateityp = "Verzeichnis"?
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

			lda	#<fileHeader+4		;Zeiger auf Icon-Daten.
			ldx	#>fileHeader+4
			bne	:set_icon_vec

::error			lda	#<Icon_Deleted		;Fehler File-Header:
			ldx	#>Icon_Deleted		;Ersatz-icon "Gelöscht" verwenden.

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

::verifyNative		ldy	driveTypeCopy		;Laufwerksmodus einlesen.
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

::updNative		ldy	driveTypeCopy		;Laufwerksmodus einlesen.
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
;			jsr	EnterTurbo		;I/O und GEOS-Turbo aktivieren.
;			jsr	InitForIO

;TurboDOS zurücksetzen.
			jsr	PurgeTurbo
			jsr	NewDisk
;---

			ldx	#$02			;Zeiger auf ersten BAM-Sektor.
::1			txa
			pha
			jsr	GetBAMBlock		;BAM-Sektor einlesen.
			pla
			cpx	#NO_ERROR		;Fehler?
			bne	:exit1			; => Ja, Abbruch...

			ldy	#<dir2Head		;Zeiger auf BAM-Sektor.
			sty	r0L
			ldy	#>dir2Head
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
;			jmp	DoneWithIO
;---

			rts

;*** Zeiger auf Cache-Bereich für BAM-Sektoren.
;--- 1541/1571/1581/Native.
:SetBAMCache1Sek	ldx	curDrive
			lda	driveType -8,x
			and	#FTYPE_MODES		;Laufwerksmodus isolieren.
			sta	driveTypeCopy

			tay
;			ldy	driveTypeCopy		;Laufwerkstyp einlesen.
			ldx	BAMCopySekInfo1,y
			bne	SetBAMCacheExit
			lda	#<curDirHead		;Zeiger auf ersten BAM-Sektor.
			ldx	#>curDirHead
			ldy	#$00
			beq	SetBAMCacheInit

;--- 1571/1581.
:SetBAMCache2Sek	ldy	driveTypeCopy		;Laufwerkstyp einlesen.
			ldx	BAMCopySekInfo2,y
			bne	SetBAMCacheExit
			lda	#<dir2Head		;1571, 1581 oder Native.
			ldx	#>dir2Head		;Zeiger auf 2ten BAM-Sektor.
			ldy	#$01
			bne	SetBAMCacheInit

;--- 1581.
:SetBAMCache3Sek	ldy	driveTypeCopy		;Laufwerkstyp einlesen.
			ldx	BAMCopySekInfo3,y
			bne	SetBAMCacheExit

			cpy	#DrvNative		;NativeMode ?
			bne	:1			; => Nein, Abbruch...
			lda	#<DISK_BASE		; => Native, Variablen testen.
			ldx	#>DISK_BASE
			bne	:2

::1			lda	#<dir3Head		; => 1581, dir3Head testen.
			ldx	#>dir3Head
::2			ldy	#$02
			bne	SetBAMCacheInit

;--- Native.
:SetBAMCache4Sek	lda	#<diskBlkBuf		;1571, 1581 oder Native.
			ldx	#>diskBlkBuf		;Zeiger auf 2ten BAM-Sektor.
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

;*** Temporäe Kopie von driveType.
:driveTypeCopy		b $00

;*** Tabelle mit BAM-Sektor-info.
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
