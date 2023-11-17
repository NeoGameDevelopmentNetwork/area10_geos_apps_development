; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskette kopieren.
:doCopyJob		LoadB	reloadDir,$ff		;GeoDesk: Verzeichnis neu laden.

			lda	#$00
			sta	statusPos		;Aktueller Track für Statusanzeige.
			lda	maxTrack
			sta	statusMax		;Max. Track für Statusanzeige.
			jsr	DrawStatusBox		;Status-Box anzeigen.
			jsr	prntDiskInfo		;Diskname ausgeben.

			ClrB	lastTrack		;Aktuellen Track löschen.

			ldx	#$01			;Zeiger auf ersten Disk-Sektor.
			stx	readDataTr
			stx	writeDataTr
			dex
			stx	readDataSe
			stx	writeDataSe

::loop			jsr	ReadDataBuf		;Daten in Puffer einlesen.
			txa				;Fehler oder keine Daten mehr?
			beq	:1			; => Nein, weiter...
			cpx	#$ff			;Diskfehler?
			bne	:exit			; => Ja, Ende...

::1			MoveB	r1L,readDataTr		;Zeiger auf nächsten Sektor
			MoveB	r1H,readDataSe		;zwischenspeichern.

			jsr	WriteDataBuf		;Daten auf Disk schreiben.

			MoveB	r1L,writeDataTr		;Zeiger auf nächsten Sektor
			MoveB	r1H,writeDataSe		;zwischenspeichern.

			txa				;Fehler oder Daten-Ende?
			beq	:loop			; => Nein, weiter...
			cpx	#$ff			;Diskfehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	OpenDrvTarget		;Target-Laufwerk aktivieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- Ergänzung: 11.07.20/M.Kanet
;Wenn Quelle < Ziel, dann am Ende die
;Partitionsgröße korrigieren.
			lda	updateNMSize		;NativeMode: Partition anpassen?
			beq	:dskname		; => Nein, weiter...

::dsksize		jsr	OpenDisk		;Disk öffnen/BAM einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			ldx	#$01
			stx	r1L
			inx
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	updateNMSize
			sta	diskBlkBuf +8		;Partitionsgröße korrigieren.

			jsr	PutBlock		;BAM auf Disk speichern.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- Hinweis:
;Diskname auf Ziel-Laufwerk immer
;speichern, falls der Name manuell im
;Menü geändert wurde.
::dskname
;			bit	flagRenameDisk		;Diskette umbenennen?
;			beq	:done			; => Nein, weiter...

			jsr	saveDiskName		;Neuen Disknamen schreiben.

::done			ldx	#NO_ERROR		;Flag: Kein Fehler.
::exit			rts				;Ende...

;*** Sektoren in Speicher einlesen.
:ReadDataBuf		jsr	OpenDrvSource		;Source-Laufwerk öffnen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
			rts

::1			MoveB	readDataTr,r1L		;Zeiger auf ersten Sektor
			MoveB	readDataSe,r1H		;einlesen.
			LoadW	r4,diskCopyBuf		;Zeiger auf Anfang Datenspeicher.

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

::loop			jsr	ReadBlock		;Sektor von Disk lesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	GetNextSekAdr		;Zeiger auf nächsten Sektor.
			txa				;Weiterer Sektor vorhanden?
			bne	:no_more_track		; => Nein, Ende...

			inc	r4H			;Zeiger Kopierspeicher erhöhen.
			lda	r4H
			cmp	#>endCopyBuf		;Speicher voll?
			bne	:loop			; => Ja, Ende...

;			ldx	#NO_ERROR		;Flag: Kein Fehler.
			b $2c
::no_more_track		ldx	#$ff
::exit			jmp	DoneWithIO		;I/O ausblenden, Ende.

;*** Sektoren aus Speicher schreiben.
:WriteDataBuf		jsr	OpenDrvTarget		;Target-Laufwerk öffnen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
			rts

::1			MoveB	writeDataTr,r1L		;Zeiger auf ersten Sektor
			MoveB	writeDataSe,r1H		;einlesen.
			LoadW	r4,diskCopyBuf		;Zeiger auf Anfang Datenspeicher.

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

::loop			lda	r1L
			cmp	lastTrack		;Aktuellen Track anzeigen?
			beq	:2			; => Nein, weiter...

			sta	lastTrack		;Neuen Track speichern.

			jsr	DoneWithIO		;I/O ausschalten.
			jsr	prntStatus		;Status aktualisieren.
			jsr	InitForIO		;I/O einschalten.

			inc	statusPos		;Fortschrittszähler erhöhen.

::2			jsr	WriteBlock		;Block auf Disk schreiben.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	GetNextSekAdr		;Zeiger auf nächsten Sektor.
			txa				;Weiterer Sektor vorhanden?
			bne	:no_more_track		; => Nein, Ende...

			inc	r4H			;Zeiger Kopierspeicher erhöhen.
			lda	r4H
			cmp	#>endCopyBuf		;Speicher voll?
			bne	:loop			; => Ja, Ende...

;			ldx	#NO_ERROR		;Flag: Kein Fehler.
			b $2c
::no_more_track		ldx	#$ff
::exit			jmp	DoneWithIO		;I/O ausblenden, Ende.

;*** Konfiguration testen.
:initDiskCopy		lda	#$00			;Flag löschen: "Partitionsgröße".
			sta	updateNMSize		;(Nur für NativeMode)

			lda	sysSource
			cmp	sysTarget		;Source- und Target Laufwerk gleich?
			bne	:11			; => Nein, weiter...

			lda	sysSource +1		;CMD-Partition definiert?
			beq	:err_samedrive		; => Nein, weiter...
			cmp	sysTarget +1		;Source-/Target-Partition gleich?
			bne	:11			; => Nein, weiter...

;--- Fehler: Gleiches Laufwerk.
::err_samedrive		LoadW	r0,Dlg_SameDrive	;Fehler: Gleiches Laufwerk.
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			ldx	#$ff			;Abbruch.
			rts

::11			ldx	sysSource		;Source-Laufwerk in Menütext
			txa				;speichern.
			clc
			adc	#"A" -8
			sta	sourceDrvText
			ldy	sysTarget		;Target-Laufwerk in Menütext
			tya				;speichern.
			clc
			adc	#"A" -8
			sta	targetDrvText

;--- Kompatibilitätstest.
			lda	driveType-8,x		;Laufwerke auf Kompatibilität
			and	#%00000111		;prüfen: 1541/71/81 oder Native.
			sta	r0L

			lda	driveType-8,y
			and	#%00000111
			cmp	r0L			;Laufwerke kompatibel?
			beq	:31			; => Ja, weiter...

;--- Sonderbehandlung: 1541/71.
			cmp	#Drv1541		;Bei 1571 <-> 1541 testen ob Disk
			beq	:21			;in 1571 einseitig ist.
			cmp	#Drv1571
			bne	:23

::21			lda	r0L
			cmp	#Drv1541
			beq	:22
			cmp	#Drv1571
			bne	:23

::22			lda	doubleSideFlg -8,x
			cmp	doubleSideFlg -8,y
			beq	:32			; => Ja, weiter...

;--- Fehler: Inkompatible Laufwerke.
::23			LoadW	r0,Dlg_Incompat
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			ldx	#$ff			;Abbruch.
			rts

;--- Sonderbehandlung: NativeMode.
::31			cmp	#%00000100		;NativeMode-Copy ?
			beq	:41			; => Ja, Größe testen...

::32			ldx	#NO_ERROR		;Kein Fehler, Ende...
			rts

;--- Ergänzung: 22.11.18/M.Kanet
;Größe von NativeMode-Laufwerken vergleichen.
;Bei unterschiedlicher Größe -> Fehler!
::41			jsr	OpenDrvSource		;Source-Laufwerk aktivieren und
			txa				;BAM einlesen um die Laufwerksgröße
			bne	:42			;zu ermitteln.
			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			lda	#$02
			jsr	GetBAMBlock		;BAM-Sektor mit Diskgröße einlesen.
			txa				;Fehler?
			bne	:42			; => Ja, Abbruch...

			lda	dir2Head +8		;"Last available track" einlesen und
			pha				;zwischenspeichern.
			jsr	OpenDrvTarget		;Target-Laufwerk aktivieren und
			txa				;BAM einlesen um die Laufwerksgröße
			bne	:42			;zu ermitteln.
			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			lda	#$02
			jsr	GetBAMBlock		;BAM-Sektor mit Diskgröße einlesen.
			pla
			cpx	#NO_ERROR		;Fehler?
			bne	:42			; => Ja, Abbruch...

;--- Ergänzung: 11.07.20/M.Kanet
;Nur gleiche große oder kleinere
;Quell-Partition kopieren.
;Wenn Quelle < Ziel, dann am Ende die
;Partitionsgröße korrigieren.
			cmp	dir2Head +8		;"Last available track" vergleichen.
			beq	:42			; => Gleich groß, OK.
			bcs	:43

			lda	dir2Head +8		;Quelle < Ziel:
			sta	updateNMSize		;Partitionsgröße korrigieren.
			bne	:42

;--- Fehler: Größe unterschiedlich.
::43			LoadW	r0,Dlg_NMDiffSize	;Laufwerksgröße inkompatibel.
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			ldx	#$ff			;Abbruch.
::42			rts

;*** Disknamen einlesen.
:getDiskNames		jsr	OpenDrvSource		;Source-Laufwerk öffnen.

			lda	#<sourceDrvDisk		;Zeiger auf Speicher für Name
			ldx	#>sourceDrvDisk		;Source-Laufwerk.

			jsr	copyDiskName		;Diskname kopieren.

:getDkNmTarget		jsr	OpenDrvTarget		;Target-Laufwerk öffnen.

			lda	#<targetDrvDisk		;Zeiger auf Speicher für Name
			ldx	#>targetDrvDisk		;Target-Laufwerk.

			jsr	copyDiskName		;Diskname kopieren.

			lda	targetDrvDisk		;Ziel-Name definiert?
			bne	:1			; => Ja, weiter...

;--- Hinweis:
;Evtl. Diskfehler, kein Ziel-Name
;definiert (z.B. unformatierte Disk).
;In diesem Fall DummyName erzeugen.
			jsr	createDiskName		;Dummy-Diskname erzeugen.

::1			rts

;*** Neuen Disknamen erzeugen.
;    Übergabe: r10 = Zeiger auf Speicher Diskname.
;Hinweis:
;Der erzeiugte name hat das Format:
; "DISKCOPY-hhmmss"
:createDiskName		lda	hour			;Aktuelle Uhrzeit
			jsr	DEZ2ASCII		;in Vorgabename kopieren.
			stx	stdDiskNameID +0
			sta	stdDiskNameID +1
			lda	minutes
			jsr	DEZ2ASCII
			stx	stdDiskNameID +2
			sta	stdDiskNameID +3
			lda	seconds
			jsr	DEZ2ASCII
			stx	stdDiskNameID +4
			sta	stdDiskNameID +5

			LoadW	r0,stdDiskName		;Zeiger auf Vorgabename.
;			LoadW	r10,targetDrvDisk	;Zeiger auf Speicher Diskname.

			ldx	#r0L
			ldy	#r10L
			jmp	SysCopyName		;Diskname kopieren.

;*** Diskname kopieren.
:copyDiskName		sta	r10L			;Zeiger auf Speicher Diskname.
			stx	r10H

			ldy	#$00			;Speicher für Diskname löschen.
			tya
			sta	(r10L),y

			jsr	NewDisk			;Diskette öffnen.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			ldx	#r0L			;Zeiger auf Diskname einlesen.
			jsr	GetPtrCurDkNm

			ldx	#r0L
			ldy	#r10L
			jmp	SysCopyName		;Diskname kopieren.
::1			rts

;*** Source-Laufwerk/Partition öffnen.
;Hinweis:
;Kein ":OpenDisk" ausführen, da sonst
;bei jedem Laufwerkswechsel während dem
;Kopiervorgang die Disk geöffnet wird,
;inkl. ":CalcBlksFree" und ":IsGEOS".
:OpenDrvSource		lda	sysSource
			jsr	SetDevice		;Source-Laufwerk aktivieren.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...
			lda	sysSource +1		;CMD-Partition definiert?
			beq	:1			; => Nein, weiter...
			ldy	curDrive
			cmp	drivePartData-8,y	;Partition noch aktiv?
			beq	:1			; => Ja, weiter...
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
::1			rts

;*** Target-Laufwerk/Partition öffnen.
:OpenDrvTarget		lda	sysTarget
			jsr	SetDevice		;Target-Laufwerk aktivieren.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...
			lda	sysTarget +1		;CMD-Partition definiert?
			beq	:1			; => Nein, weiter...
			ldy	curDrive
			cmp	drivePartData-8,y	;Partition noch aktiv?
			beq	:1			; => Ja, weiter...
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
::1			rts

;*** Diskname initialisieren.
;Aufruf aus Registermenü.
:updateDiskName		jsr	setDiskName		;Ziel-Diskname definieren.

			LoadW	r15,RTabMenu1_1b	;Option aktualisieren:
			jmp	RegisterUpdate		;"Name Target-Disk"

;*** Diskname manuell ändern.
;--- Hinweis:
;Wenn der Name des Ziel-Laufwerks
;geändert wird, dann den neuen Namen
;für das Ziel-Laufwerk verwenden.
:setFlagDskName		lda	#$00			;Option löschen:
			sta	flagRenameDisk		;"Diskname behalten".

			LoadW	r15,RTabMenu1_1a	;Option aktualisieren:
			jmp	RegisterUpdate		;"Diskname behalten"

;*** Diskname initialisieren.
;Aufruf aus Registermenü.
:initTargetDkNm		lda	#$ff			;Option setzen:
			sta	flagRenameDisk		;"Diskname behalten".

;*** Diskname definieren.
:setDiskName		lda	flagRenameDisk		;Diskname ersetzen?
			bne	:keepcurname		; => Ja, weiter...

::keeporigname		LoadW	r0,sourceDrvDisk	;Diskname Source-Disk als Vorgabe
			LoadW	r10,targetDrvDisk	;für Target-Disk verwenden.

			ldx	#r0L
			ldy	#r10L
			jmp	SysCopyName		;Diskname kopieren.

::keepcurname		jmp	getDkNmTarget		;Aktuellen Disknamen einlesen.

;*** Variablen.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.
:flagRenameDisk		b $00
:updateNMSize		b $00

:readDataTr		b $00
:readDataSe		b $00
:writeDataTr		b $00
:writeDataSe		b $00
:lastTrack		b $00

:sourceDrvText		b "X:",NULL
:targetDrvText		b "X:",NULL
:sourceDrvDisk		s 17
:targetDrvDisk		s 17

:stdDiskName		b "DISKCOPY-"
:stdDiskNameID		b "000000",NULL

;*** Fehler: Laufwerke sind nicht kompatibel.
:Dlg_Incompat		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3e
			w textCancelCopy
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Quell- und Ziel-Laufwerk sind",NULL
::3			b "nicht kompatibel!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Source and target drives are",NULL
::3			b "not compatible!",NULL
endif

;*** Fehler: NativeMode-Größe unterschiedlich.
:Dlg_NMDiffSize		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3e
			w textCancelCopy
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Quell- und Ziel-Laufwerk haben",NULL
::3			b "eine unterschiedliche Größe!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Source and target drives have",NULL
::3			b "a different disk size!",NULL
endif

;*** Fehler: 1-Drive-Copy nicht unterstützt.
:Dlg_SameDrive		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3e
			w textCancelCopy
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Quell- und Ziel-Laufwerk dürfen",NULL
::3			b "nicht gleich sein!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The source and target drive",NULL
::3			b "must be different!",NULL
endif

if LANG = LANG_DE
:textCancelCopy		b "Kopiervorgang wird abgebrochen!",NULL
endif
if LANG = LANG_EN
:textCancelCopy		b "Copy operation will be canceled!",NULL
endif
