; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Verzeichnisdaten einlesen.
;* SD2IEC Hauptverzeichnis öffnen.
;* SD2IEC Elternverzeichnis öffnen.
;* SD2IEC DiskImage verlassen.
;* SD2IEC Eintrag öffnen.
;* SD2IEC Modus Dir/DImg testen.

;*** Symboltabellen.
if .p
			t "SymbTab_CROM"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_RLNK"
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
			n "obj.GD40"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xGET_DISK_DATA
			jmp	xDIR_SD_ROOT
			jmp	xDIR_SD_PARENT
			jmp	xDIR_SD_EXIT
			jmp	xDIR_SD_OPEN
			jmp	xGET_SD_MODE

;*** Aktuelles Laufwerk auf SD2IEC testen.
;    Übergabe: curDrive = Aktuelles Laufwerk.
;    Rückgabe: XREG = $00, DiskImage.
;                   = $FF, Verzeichnis.
:xGET_SD_MODE		ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			bne	:init			; => Nein, kein SD2IEC.

			ldx	#NO_ERROR
			rts

::init			lda	#"7"			;Fehlermeldung initialisieren.
			sta	FComReply +0
			lda	#"0"
			sta	FComReply +1
			lda	#","
			sta	FComReply +2

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#1
			ldx	#< FComName
			ldy	#> FComName
			jsr	SETNAM			;Datenkanal, Name "#".

			lda	#5
			tay
			ldx	curDrive
			jsr	SETLFS			;Daten für Datenkanal.

			jsr	OPENCHN			;Datenkanal öffnen.
			bcs	:error

			lda	#10
			ldx	#< FComTest
			ldy	#> FComTest
			jsr	SETNAM			;"U1"-Befehl.

			lda	#15
			tay
			ldx	curDrive
			jsr	SETLFS			;Daten für Befehlskanal.

			jsr	OPENCHN			;Befehlskanal #15 öffnen.
			bcs	:error

			lda	#< FComReply		;Antwort empfangen.
			ldx	#> FComReply
			ldy	#3
			jsr	:readStatByt

::error			lda	#15			;Befehlskanal schließen.
			jsr	CLOSE

			lda	#5			;Datenkanal schließen.
			jsr	CLOSE

			jsr	CLRCHN

			lda	FComReply +0		;Rückmeldung auswerten.
			cmp	#"0"			;"00," ?
			bne	:check_sd		; => Nein, Verzeichnis-Modus.
			lda	FComReply +1
			cmp	#"0"
			bne	:check_sd
			lda	FComReply +2
			cmp	#","
			beq	:mode_dimg

::check_sd		lda	FComReply +0		;Rückmeldung auswerten.
			cmp	#"7"			;"70," ?
			bne	:mode_dir		; => Ja, Keine SD-Karte.
			lda	FComReply +1
			cmp	#"0"
			bne	:mode_dir
			lda	FComReply +2
			cmp	#","
			bne	:mode_dir

			ldx	#DEV_NOT_FOUND		;SD2IEC: Keine Karte im Laufwerk.
			b $2c
::mode_dir		ldx	#$ff			;SD2IEC: Verzeichnis.
			b $2c
::mode_dimg		ldx	#$00			;SD2IEC: DiskImage.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Rückmeldung von Floppy empfangen.
;Übergabe: AKKU/XReg = Zeiger auf Zwischenspeicher.
;          YReg = Anzahl Bytes.
::readStatByt		sta	r0L
			stx	r0H
			sty	r1L

			lda	#$00
			sta	STATUS

			ldx	#15
			jsr	CHKIN

			lda	#$00
			sta	r1H

::11			jsr	READST
			bne	:12

			jsr	CHRIN

			ldy	r1H
			cpy	r1L
			bcs	:11
			sta	(r0L),y
			inc	r1H
			jmp	:11

::12			rts

;*** BASIC/SD-ROOT-Verzeichnis öffnen.
:xDIR_SD_ROOT		jsr	xGET_SD_MODE		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:image			; => DiskImage-Modus aktiv.
			cpx	#$ff
			beq	:directory		; => Verzeichnis-Modus aktiv.
			rts				;Fehler, Abbruch...

::image			lda	#< FComExitDImg		;Aktives DiskImage verlassen.
			ldx	#> FComExitDImg
			jsr	sendComIECbus

::directory		lda	#< FComCDRoot		;Root aktivieren.
			ldx	#> FComCDRoot
			jsr	sendComIECbus
			jmp	xGET_DISK_DATA		;Neues Verzeichnis einlesen.

;*** BASIC/Ein SD-Verzeichnis zurück.
:xDIR_SD_PARENT		jsr	xGET_SD_MODE		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:1			; => DiskImage-Modus aktiv.
			cpx	#$ff
			beq	:1			; => Verzeichnis-Modus aktiv.
			rts				;Fehler, Abbruch...

::1			lda	#< FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldx	#> FComExitDImg
			jsr	sendComIECbus
			jmp	xGET_DISK_DATA		;Neues Verzeichnis einlesen.

;*** BASIC/DiskImage verlassen.
:xDIR_SD_EXIT		jsr	xGET_SD_MODE		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:1			; => DiskImage-Modus aktiv.
			rts				;Fehler, Abbruch...

::1			lda	#< FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldx	#> FComExitDImg
			jmp	sendComIECbus

;*** Verzeichnis oder DiskImage öffnen.
:xDIR_SD_OPEN		jsr	xGET_SD_MODE		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:0			; => DiskImage-Modus aktiv.
			cpx	#$ff
			beq	:0			; => Verzeichnis-Modus aktiv.
			rts				;Fehler, Abbruch...

::0			ldy	#$05
			ldx	#$03
::1			lda	(a0L),y			;Verzeichnisname in "CD"-Befehl
			beq	:2			;übertragen...
			cmp	#$a0
			beq	:2
			sta	FComCDir+2,x
			inx
			iny
			cpy	#$05+16
			bne	:1
::2			lda	#$00			;Befehl abschließen.
			sta	FComCDir+2,x
			stx	FComCDir+0		;Länge Befehl setzen.

			lda	#< FComCDir		;Verzeichnis/Image wechseln.
			ldx	#> FComCDir
			jsr	sendComIECbus

			ldy	#$02
			lda	(a0L),y
			and	#ST_FMODES		;Dateityp isolieren.
			cmp	#DIR			;Verzeichnis-Wechsel?
			beq	:exit			; => Nein weiter...

			lda	curType
			and	#ST_DMODES		;Laufwerksmodus einlesen.
			cmp	#DrvNative		;NativeMode?
			bne	:3			; => Ja, weiter...
			jmp	OpenRootDir		;Native: Hauptverzeichnis öffnen.
::3			jmp	OpenDisk		;Disk öffnen/CalcBlksFree.

::exit			ldx	#$ff			;Flag setzen: "Dateien einlesen".
::error			rts

;*** Partitionen oder DiskImages einlesen.
:xGET_DISK_DATA		lda	#$00			;Fenster für Cache löschen.
			sta	getFileWin

			ldx	WM_WCODE		;Laufwerk einlesen.
			ldy	WIN_DRIVE ,x		;Laufwerk verfügbar?
			beq	:error			; => Nein, Ende...

			lda	driveType -8,y		;GEOS-Laufwerk definiert?
			beq	:error			; => Nein, Ende...

			tya
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			beq	:get_data		; => Nein, weiter...

;--- Laufwerksfehler, Abbruch.
::error			lda	#$00			;Dateizähler löschen.
			sta	WM_DATA_MAXENTRY +0

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			ldx	#$00			;Flag setzen "Dateien einlesen".
			rts

;--- Partitionen/DiskImages einlesen.
::get_data		ldx	curDrive		;Aktuellen Laufwerkstyp für
			lda	driveType -8,x		;DiskImage-Vergleich speichern.
			and	#ST_DMODES
			sta	DiskImgTyp

			jsr	i_FillRam		;Verzeichnis-Speicher löschen.
			w	MAX_DIR_ENTRIES * 32
			w	BASE_DIRDATA
			b	$00

			ldy	curDrive
			lda	RealDrvMode -8,y	;CMD-Laufwerk ?
			bmi	:disk_cmd		; => Ja, weiter...

			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:error			; => Nein, Laufwerk unbekannt.

;--- DiskImages von SD2IEC-Laufwerk einlesen.
::disk_sd2iec		jsr	readDataSD2IEC		;SD2IEC-DiskImages einlesen.
			jmp	:saveDiskInfo

;--- Partitionen von CMD-Laufwerken einlesen.
::disk_cmd		jsr	readDataCMD		;CMD-Partitionen einlesen.

;--- Neue Verzeichnis-Daten speichern.
::saveDiskInfo		lda	ListEntries		;Anzahl Einträge speichern.
			sta	WM_DATA_MAXENTRY +0

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

			jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache.
			jsr	StashRAM		;Verzeichnis in Cache speichern.

			jsr	SET_LOAD_CACHE		;GetFiles-Flag zurücksetzen.

			lda	WM_WCODE		;Fenster-Nr. für Cache speichern.
			sta	getFileWin

			ldx	#$ff			;Flag setzen "Part/Img anzeigen".
			rts

;*** CMD-Partitionen über GDOS einlesen.

;--- Hinweis:
;Am Anfang immer "I0:"-Befehl senden!
;Bei einer CMD-HD mit einem externen
;SCSI-Laufwerk wird damit bei einem
;Medien-Wechsel die Partitionstabelle
;von Disk neu eingelesen.

:readDataCMD		lda	#< FComI0Disk		;Aktives DiskImage verlassen.
			ldx	#> FComI0Disk
			jsr	sendComIECbus

if FALSE
;--- Hinweis:
;Lokale Routine statt Kernal verwenden.
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			LoadW	r0,FComI0Disk +2	;"I0:"-Befehl senden.
			MoveB	FComI0Disk,r2L
			jsr	SendCommand
			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.
endif

;--- Hinweis:
;Partitionen einlesen, ":OpenDisk"
;hier wirklich erforderlich ?
;			jsr	OpenDisk		;Diskette öffnen. Bei CMD-HD/FD
;							;wird dabei auch eine gültige
;							;Partition aktiviert.

			jsr	i_FillRam		;Speicher initialisieren.
			w	partTypeBuf_S
			w	partTypeBuf
			b	$00

			LoadW	r4,partTypeBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetPTypeData		;CMD-Partitionsdaten abrufen.

;			jsr	PurgeTurbo		;TurboDOS entfernen (Nicht aktiv!).
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00			;Anzahl Einträge löschen.
			sta	ListEntries

			LoadB	r3H,1			;Zeiger auf Partition #1.
			LoadW	r4,partEntryBuf		;Zeiger auf Zwischenspeicher.

			jsr	ADDR_RAM_r15		;Zeiger auf Speicher für Daten.

::read_part		ldx	r3H
			lda	partTypeBuf,x		;Partitionstyp einlesen.
			cmp	DiskImgTyp		;Mit Laufwerkstyp vergleichen.
			bne	:next_part		; => Fehler, weiter...

			jsr	ReadPDirEntry		;Partitionseintrag einlesen.
			txa				;Fehler?
			bne	:next_part		; => Ja, nächste Partition.

			lda	partEntryBuf		;Partition definiert?
			beq	:next_part		; => Nein, nächste Partition.

			ldy	#$02
			lda	DiskImgTyp		;Partitions-Typ speichern.
			sta	(r15L),y
			iny
			lda	r3H			;Partitions-Nr. speichern.
			sta	(r15L),y

			ldy	#$05
			ldx	#$03
::loop_name		lda	partEntryBuf,x		;Partitions-Name speichern.
			cmp	#$a0
			beq	:exit_loop_name
			sta	(r15L),y
			iny
			inx
			cpx	#$03+16
			bcc	:loop_name

::exit_loop_name	jsr	:getPartSize		;Partitionsgröße einlesen.

			ldy	#$1e			;Partitionsgröße in
			sta	(r15L),y		;Eintrag kopieren.
			iny
			txa
			sta	(r15L),y

			jsr	ChkListFull		;Zeiger auf nächsten Eintrag.
			txa				;Liste voll?
			bne	:exit			; => Ja, Ende...

::next_part		inc	r3H			;Zeiger auf nächsten Eintrag.
			lda	r3H
			cmp	#255			;Alle Partitionen geeprüft?
			bcc	:read_part		; => Nein, weitere...

::exit			ldx	#NO_ERROR		;Kein Fehler.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;--- CMD-Partitionsgröße ermitteln.
::getPartSize		ldy	#$02
			lda	(r15L),y		;Partitionstyp einlesen.
			cmp	#DrvNative		;NativeMode?
			beq	:native			; => Nein, weiter...

;--- 1541/71/81.
			sec				;Zeiger auf Partitionsgröße
			sbc	#$01			;berechnen.
			asl
			tay
			lda	partSizeData+0,y	;Low-Byte.
			ldx	partSizeData+1,y	;High-Byte.
			rts

;--- Native.
::native		ldy	#$03			;Bei NativeMode Cluster-Anzahl
			lda	(r15L),y		;einlesen.
			sta	r3H
			jsr	ReadPDirEntry
			txa				;Fehler?
			beq	:get_native_size	; => Nein, weiter...

			lda	#$00
			tax				;Partitionsgröße löschen.
			beq	:done			; => Ende...

::get_native_size	lda	partEntryBuf+29		;Partitionsgröße in 512Byte Cluster
			asl				;in 256Byte Blocks umrechnen.
			pha
			lda	partEntryBuf+28
			rol
			tax
			pla
::done			rts

;*** SD2IEC-DiskImages/Verzeichnisse einlesen.
:readDataSD2IEC		lda	#$00			;Anzahl Einträge löschen.
			sta	ListEntries

			sta	cntEntries +0		;Anzahl Dateien = 0.
			sta	cntEntries +1		;Anzahl Verzeichnisse = 0.

			jsr	xGET_SD_MODE		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:sd_img_mode		; => DiskImage-Modus aktiv.
			cpx	#$ff
			beq	:sd_dir_mode		; => Verzeichnis-Modus aktiv.
			rts				;Fehler, Abbruch...

::sd_img_mode		lda	#< FComExitDImg		;Aktives DiskImage verlassen.
			ldx	#> FComExitDImg
			jsr	sendComIECbus

::sd_dir_mode		lda	DiskImgTyp
			asl
			tay
			lda	DImgTypeList +0,y	;Kennung D64/D71/D81/DNP in
			sta	FComDImgList +5		;Verzeichnis-Befehl eintragen.
			lda	DImgTypeList +1,y
			sta	FComDImgList +6

			jsr	ADDR_RAM_r15		;Anfang Verzeichnis im RAM.

;*** Verzeichnisse hinzufügen.
::addDirData		PushW	r15			;Zeiger auf Dateiliste speichern.

			lda	#< FComSDirList		;Liste mit Verzeichnissen einlesen.
			ldx	#> FComSDirList
			ldy	#$ff
			jsr	GetDirList

			PopW	a1			;Zeiger auf Dateiliste.
			lda	cntEntries +1		;Anzahl Verzeichnisse.
			sta	a0L
			ClrB	a0H
			jsr	sortListSD2IEC		;Verzeichnisse sortieren.

;*** Dateienn hinzufügen.
::addFileData		PushW	r15			;Zeiger auf Dateiliste speichern.

			lda	#< FComDImgList		;Liste mit DiskImages einlesen.
			ldx	#> FComDImgList
			ldy	#$00
			jsr	GetDirList

			PopW	a1			;Zeiger auf Dateiliste.
			lda	cntEntries +0		;Anzahl Dateien.
			sta	a0L
			ClrB	a0H
			jmp	sortListSD2IEC		;Disk-Images sortieren.

;*** Dateien im Speicher sortieren.
;Sortieralgorythmus:
;       a4 = Ende
;:loop1 a2 = Aktuell
;       a4 -> a3
;:loop3 a2 = a3? -> loop2
;       a0/compare
;           a3 < a2? ->swap
;       a3  -32
;       -> loop3
;:loop2 a2 +32
;       a2 = a4? -> loop1
;
;    a0   = Anzahl Einträge.
;    a1   = Startadresse Einträge im Speicher.
;    a2   = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a3   = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
;    a4   = Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
;
;    a5   = Anzahl Dateien -1.
;
:sortListSD2IEC		lda	a0L
			ldx	a0H
			bne	:do_sort
			cmp	#$02
			bcs	:do_sort

::no_sort		ldx	#$ff			;Weniger als 2 Dateien, Ende...
			rts

::do_sort		sec				;Zeiger auf letzten Eintrag
			sbc	#$01			;berechnen.
			sta	a5L
			bcs	:1
			dex
::1			stx	a5H

;--- Adressen Verzeichnis im Speicher.
			MoveW	a5,a4
			ldx	#a4L			;Zeiger auf letzten Verzeichnis-
			jsr	setDataPos		;Eintrag im Speicher berechnen.

			ClrW	a2
			ldx	#a2L			;Zeiger auf ersten Verzeichnis-
			jsr	setDataPos		;Eintrag im Speicher berechnen.

::do_compare		MoveW	a4,a3			;Temporärer Zähler auf letzten

::next_entry		CmpW	a3,a2			;Aktueller Zähler = temp. Zähler?
			beq	:do_next		; => Ja, weiter...

			jsr	SortName		;Einträge vergleichen.

			SubVW	32,a3			;Temporären Zähler Speicher.

			jmp	:next_entry		;Weiter mit nächstem Vergleich.

::do_next		AddVBW	32,a2			;Nächster Eintrag Speicher.

			CmpW	a2,a4			;Ende erreicht?
			beq	:exit			; => Ja, Ende...

			jmp	:do_compare		; => Nein, weiter...

::exit			ldx	#$00			;Dateien sortiert, Ende.
			rts

;*** Einträge vergleichen.
;    a2 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a3 = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.

;*** Modus: Name.
:SortName		ldy	#$05
			lda	(a2L),y			;Zuerst nach Buchstabe a=A
			jsr	:convert_upper		;vergleichen.
			sta	:101 +1
			lda	(a3L),y
			jsr	:convert_upper
::101			cmp	#$ff
			bcc	:106
			beq	:102
			bcs	:109

::102			lda	(a3L),y			;Hier unterscheiden zwischen
			cmp	(a2L),y			;Groß- und Kleinbuchstaben.
			beq	:108
			bcc	:103
			jmp	SwapEntry		;Eintrag tauschen/sortieren.
::103			rts

::104			ldy	#$05			;Zeichen vergleichen.
::105			lda	(a3L),y
			cmp	(a2L),y
			bcs	:107
::106			jmp	SwapEntry		;Eintrag tauschen/sortieren.

::107			bne	:109
::108			iny				;Weitervergleichen bis
			cpy	#$15			;alle 11 Zeichen geprüft.
			bne	:105
::109			rts

::convert_upper		cmp	#$61			;Kleinbuchstaben in
			bcc	:13			;Großbuchstaben wandeln.
			cmp	#$7e			;Sortieren nach Buchstabe a=A,...
			bcs	:13			;Kein Unterschied Groß/Klein.
::12			sec
			sbc	#$20
::13			rts

;*** Einträge vertauschen.
;    a2 = Zeiger auf aktuellen Verzeichnis-Eintrag im Speicher.
;    a3  = Temporärer Zeiger auf letzten Verzeichnis-Eintrag im Speicher.
:SwapEntry		ldy	#$1f			;Einträge im Speicher tauschen.
::101			lda	(a2L),y
			tax
			lda	(a3L),y
			sta	(a2L),y
			txa
			sta	(a3L),y
			dey
			bpl	:101
			rts

;*** Zeiger auf Eintrag im Speicher berechnen.
;Übergabe: XReg = Zero-Page-Adresse Faktor #1.
;Rückgabe: Zero-Page Faktor#1 erhält Adresse im RAM.
:setDataPos		ldy	#5			;Größe Dateieintrag 2^5 = 32 Bytes.
			jsr	DShiftLeft		;Anzahl Einträge x 32 Bytes.

			lda	zpage +0,x
			clc
			adc	a1L
			sta	zpage +0,x
			lda	zpage +1,x
			adc	a1H
			sta	zpage +1,x
			rts

;*** Verzeichnis-Liste einlesen.
;    Übergabe: YReg      = $00=Dateien.
;                          $FF=Verzeichnisse.
;              AKKU/XREG = Zeiger auf "$"-Befehl.
;              r15       = Zeiger auf Eintragstabelle.
:GetDirList		sty	ReadDirMode

			sta	r13L			;Zeiger auf
			stx	r13H			;Verzeichnis-Befehl.

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.

			bit	STATUS			;Status-Byte prüfen.
			bpl	:sendDirCmd		;OK, weiter...
::err_no_device		ldx	#DEV_NOT_FOUND		;Fehler: "Laufwerk nicht bereits".
			jmp	GetDirListEnd		;Abbruch.

::sendDirCmd		lda	#$f0			;Datenkanal aktivieren.
			jsr	SECOND
			bit	STATUS			;Status-Byte prüfen.
			bmi	:err_no_device		;Fehler, Abbruch.

			ldy	#$00
::loopCMD		lda	(r13L),y		;Byte aus Befehl einlesen und
			beq	:endCMD
			jsr	CIOUT			;an Floppy senden.
			iny
			bne	:loopCMD		;Nein, weiter...
::endCMD		jsr	UNLSN			;Befehl abschliesen.

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	TALK			;TALK-Signal auf IEC-Bus senden.
			lda	#$f0			;Datenkanal öffnen.
			jsr	TKSA			;Sekundär-Adresse nach TALK senden.

			jsr	ACPTR			;Byte einlesen.

			bit	STATUS			;Status testen.
			bpl	:skipHeader		;OK, weiter...
			ldx	#FILE_NOT_FOUND		;Fehler: "Verz. nicht gefunden".
			jmp	GetDirListEnd

::skipHeader		ldy	#$1f			;Verzeichnis-Header
::loop1			jsr	ACPTR			;überlesen.
			dey
			bne	:loop1

;*** Partitionen aus Verzeichnis einlesen.
::next_line		jsr	ACPTR			;Auf Verzeichnis-Ende
			cmp	#$00			;testen.
			beq	:EOD
			jsr	ACPTR			;(2 Byte Link-Verbindung überlesen).

			jsr	ACPTR			;Low-Byte der Zeilen-Nr. überlesen.
			sta	Blocks +0
			jsr	ACPTR			;High-Byte Zeilen-Nr. überlesen.
			sta	Blocks +1

::startFileName		jsr	ACPTR			;Weiterlesen bis zum
			cmp	#$00			;Dateinamen.
			beq	:next_line		; => Ende der Zeile erreicht.
			cmp	#$22			; " - Zeichen erreicht ?
			bne	:startFileName		;Nein, weiter...

			ldy	#$05			;Zeichenzähler löschen.
::loopFileName		jsr	ACPTR			;Byte aus Dateinamen einlesen.
			cmp	#$22			;Ende erreicht ?
			beq	:testFileExist		;Ja, Ende...
			sta	(r15L),y		;Byte in Tabelle übertragen.
			iny
			cpy	#$05 +16
			bcc	:loopFileName

::testFileExist		jsr	FindDirFile		;Prüfen ob Eintrag bereits als
			txa				;Verzeichnis eingelesen wurde.
			bne	:findEOL		; => Verzeichnis, überspringen...

			ldy	#$02
			lda	DiskImgTyp		;Laufwerkstyp einlesen.
			bit	ReadDirMode		;Verzeichnis-Modus testen.
			bpl	:wrFileType		; => Dateien einlesen.
			lda	#DIR			;"Verzeichnis".
::wrFileType		sta	(r15L),y		;Dateityp speichern.

			ldy	#$03			;Zeiger auf Partitions-Nr.
			lda	ReadDirMode		;Verzeichnis-Modus testen.
			cmp	#$7f			;CMD-Partitionen?
			beq	:wrPartSize		; => Ja, weitere...
			ldy	#$1e			;Zeiger auf Größe setzen.

;--- Partitions-Nr. / Größe speichern.
;An dieser Stelle wird beim einlesen
;der Partitionen über den "$"-Befehl die
;Partitions-Nr. ab $03/$04 gespeichert,
;oder im GEOS-Modus / SD2IEC-DiskImages
;die Größe ab $1e/$1f gespeichert.
;Im ersten Fall wird die Größe der
;Partition im zweiten Schritt ergänzt.
::wrPartSize		lda	Blocks +0		;Größe DiskImage/Partition in
			sta	(r15L),y		;Verzeichnis-Eintrag übernehmen.
			iny
			lda	Blocks +1
			sta	(r15L),y

			jsr	ChkListFull		;Zeiger auf nächsten Eintrag.
			txa				;Liste voll?
			bne	:EOD			; => Ja, Ende...

::findEOL		jsr	ACPTR			;Rest der Zeile überlesen.
			cmp	#$00
			bne	:findEOL
			jmp	:next_line		;Nächsten Dateinamen einlesen.

;*** Verzeichnis-Ende.
::EOD			jsr	UNTALK			;Datenkanal schließen.

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.
			lda	#$e0			;Laufwerk abschalten.
			jsr	SECOND
			jsr	UNLSN

			ldx	#$00			;Kein Fehler.

;*** Verzeichnis abschließen.
:GetDirListEnd		txa
			pha
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			pla
			tax
			rts				;Ende.

;*** Eintrag in Verzeichnis-Liste suchen.
:FindDirFile		ldx	cntEntries +1		;Verzeichnisse vorhanden?
			beq	:file_ok		; => Nein, Ende...
			stx	r11L

			ldx	#r10L
			jsr	ADDR_RAM_x		;Anfang Verzeichnis im RAM.

::next_entry		CmpW	r10,r15			;Aktuellen Eintrag erreicht?
			beq	:set_next_entry		; => Ja, überspringen...

			ldy	#$05			;Dateiname vergleichen.
::loop_compare		lda	(r10L),y
			bne	:compare
			lda	(r15L),y
			beq	:file_exist
			bne	:set_next_entry
::compare		cmp	(r15L),y
			bne	:set_next_entry
			iny
			cpy	#$05 +16
			bcc	:loop_compare
			bcs	:file_exist

::set_next_entry	AddVBW	32,r10			;Zeiger auf nächsten Eintrag.
			dec	r11L			;Alle Einträge verglichen?
			bne	:next_entry		; => Nein, weiter...

			ldx	#$00			;OK.
			b $2c
::file_exist		ldx	#$ff			;Fehler.
::file_ok		rts

;*** Prüfen ob Dateiliste voll ist.
:ChkListFull		AddVBW	32,r15			;Zeiger auf nächsten Eintrag.
			inc	ListEntries

			lda	ListEntries		;Anzahl Einträge einlesen.
			bit	ReadDirMode		;Verzeichnisse oder Dateien suchen?
			bpl	:files			; => Dateien, weiter...

			inc	cntEntries +1		;Anzahl Verzeichnise +1.
			cmp	#100			;Speicher voll ( Anzahl = 100 ) ?
			beq	:list_full		; => Ja, Ende...
			bne	:list_ok		; => Nein, weitersuchen...

::files			inc	cntEntries +0		;Anzahl Dateien +1.
			cmp	#MAX_DIR_ENTRIES	;Speicher voll ( Anzahl = 224 ) ?
			beq	:list_full		; => Ja, Ende...

::list_ok		ldx	#$00			;List ready...
			b $2c
::list_full		ldx	#$ff			;List full...
			rts

;*** Daten an Floppy senden.
;Übergabe: AKKU/XReg = Zeiger auf Befehlsdaten:
;          Byte#0/1  = Anzahl Bytes.
;          Byte#2/.. = Floppy-Befehl.
:sendComIECbus		sta	r0L
			stx	r0H

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			ldy	#$00
			lda	(r0L),y			;Länge Floppy-Befehl einlesen.
			sta	r2L

			lda	r0L			;Zeiger auf Floppy-Befehl setzen.
			clc
			adc	#$02
			sta	r0L
			bcc	:1
			inc	r0H

::1			jsr	SendCommand		;Floppy-Befehl senden.

			txa				;Fehlerstatus zwischenspeichern.
			pha

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			pla
			tax				;Fehlerstatus in XReg übergeben.

::done			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Liste mit Partitions-Typen.
:DImgTypeList		b "??647181NP??????"		;SD2IEC.

;*** DiskImage-Typ.
:DiskImgTyp		b $00				;$01-$04 für DiskImage-Typ.

;*** Partitions-Verzeichnis abrufen.
:FComDImgList		b "$:*.D??=P",NULL		;Nur DiskImages.
:FComSDirList		b "$:*=B",NULL			;Nur Verzeichnisse.

;*** Medium initialisieren.
:FComI0Disk		w $0003
			b "I0:"

;*** Anzahl Dateien und Verzeichnisse.
:cntEntries		b $00,$00			;Dateien/Verzeichnisse getrennt.
:ListEntries		b $00				;Anzahl Gesamteinträge.

;*** Verzeichnis-Typ.
:ReadDirMode		b $00				;$00=Dateien, $FF=Verzeichnisse.

;*** Befehle zum DiskImage-Wechsel.
:FComCDRoot		w $0004				;Befehl: Zu "ROOT" wechseln.
			b "CD//"
:FComExitDImg		w $0003				;Befehl: Eine Ebene zurück.
			b "CD",$5f

;*** SD2IEC-DiskImage/Verzeichnis-Befehl.
:FComCDir		w $0000				;Befehl: Verzeichnis/Image wechseln.
			b "CD:"
			s 17

;*** Abfrage SD-Modus Dir/DImg.
:FComName		b "#"
:FComTest		b "U1 5 0 1 1"
:FComReply		s $03

;*** Größe für 1541/71/81-Partitionen.
:partSizeData		w 684				;Anzahl Blocks: 1541.
			w 1368				;Anzahl Blocks: 1571.
			w 3200				;Anzahl Blocks: 1581.

;*** Partitionsgröße.
:Blocks			w $0000				;Anzahl Blocks letzter Eintrag.

;*** Reservierter Speicher.
;--- Hinweis:
;Der reservierte Speicher ist nicht
;initialisiert!

:sysMem
:sysMemA		= (sysMem / 256 +1)*256

:partTypeBuf_S		= 256				;Liste mit Partitionstypen.
:partTypeBuf		= sysMemA

:partEntryBuf_S		= 30				;Partitionseintrag.
:partEntryBuf		= partTypeBuf + partTypeBuf_S

:sysMemE		= partEntryBuf + partEntryBuf_S
:sysMemS		= (sysMemE - sysMem)

;*** Endadresse testen:
			g BASE_DIRDATA - sysMemS
;***
