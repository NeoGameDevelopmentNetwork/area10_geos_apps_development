; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Diskette kopieren.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_DISK"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"

;--- Variablen für Status-Box:
:STATUS_X		= $0040
:STATUS_W		= $00c0
:STATUS_Y		= $30
:STATUS_H		= $40

;--- Fortschrittsbalken.
:STATUS_CNT_X1		= STATUS_X +16
:STATUS_CNT_X2		= (STATUS_X + STATUS_W) -24 -1
:STATUS_CNT_W		= (STATUS_CNT_X2 - STATUS_CNT_X1) +1
:STATUS_CNT_Y1		= (STATUS_Y + STATUS_H) -16
:STATUS_CNT_Y2		= (STATUS_Y + STATUS_H) -16 +8 -1

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_Y1		= STATUS_Y +26
:INFO_Y2		= STATUS_Y +36
:INFO_Y3		= STATUS_Y +48
endif

;*** GEOS-Header.
			n "obj.GD63"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xDISK_COPY

;*** Programmroutinen.
			t "-Gxx_DiskNewName"		;Diskname ändern.
			t "-Gxx_DiskMaxTr"		;Anzahl Track auf Disk ermitteln.
			t "-Gxx_DiskNextSek"		;Zeiger auf nächsten Disk-Sektor.
			t "-Gxx_IBoxCore"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** Diskette kopieren.
:xDISK_COPY		jsr	initDiskCopy		;DiskCopy initialisieren.
			txa				;Konfiguration OK?
			bne	:error			; => Nein, weiter...

;--- Hinweis:
;Standard: Diskname ersetzen.
;Bei gleichen Disknamen kommt GEOS beim
;starten von Dokumenten durcheinander,
;da hier der Diskname als Ziel-Laufwerk
;verwendet wird.
			lda	#$ff			;Optionn setzen:
			sta	flagRenameDisk		;Diskname ersetzen.

			jsr	getDiskNames		;Disknamen einlesen.

			lda	sysSource
			jsr	SetDevice		;Source-Laufwerk aktivieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	OpenDisk		;Diskette öffnen (BAM für Native).
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	getMaxTracks		;Max. Anzahl Tracks einlesen.

;--- Register-Menü anzeigen.
			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;--- Kopieren abbrechen.
::error			cpx	#$ff			;Konfigurationsfehler?
			beq	:exit			; => Ja, Ende...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.

			ldx	#$ff
::exit			stx	exitCode		;Zurück zum DeskTop.
;			jmp	ExitRegMenuUser

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskCopy ausführen?
			cmp	#$7f
			bne	:2			; => Nein, Ende...

			lda	#NULL			;DiskCopy überschreibt die Dateien
			sta	getFileWin		;im Speicher eines evtl. geöffneten
			sta	getFileDrv		;Fensters.

			jsr	doCopyJob		;Diskette kopieren.

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
			txa				;Fehlercode zwischenspeichern.
			pha
			jsr	sys_LdBackScrn		;Bildschirminhalt zurücksetzen.
			pla
			tax				;Fehlercode wiederherstellen.
			beq	:1			; => Kein Fehler, weiter...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.

::1			lda	#$00			;Source-Laufwerk löschen, damit
			sta	sysSource		;Fenster nicht aktualisiert wird.
			sta	winSource
			sta	updateSource

			lda	#GD_LOAD_DISK		;Ziel: Dateien von Disk laden.
			sta	updateTarget

			jmp	MOD_UPDATE_WIN		;Hauptmenü / Fenster aktualisieren.
::2			jmp	MOD_UPDATE		;Zurück zum DeskTop.

;*** Icon "Diskette kopieren" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
;Hinweis:
;Funktioniert nur wenn RegisterMenü im
;Speicher nicht überschrieben wird.
;In diesem Fall RegisterMenü beenden
;und über ExitRegMenuUser das DiskCopy
;ausführen.
;Hinweis2:
;Ausserdem wird die letzte Register-
;Option (Hier: das DiskCopy-Icon) am
;Bildschirm aktualisiert und bleibt bis
;zum Ende der Routine sichtbar/TODO!
:ExecRegMenuUser	ldx	#$7f			;Flag: DiskCopy ausführen.
			rts

;*** Variablen.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.

;*** Register-Menü.
:R1SizeY0 = $20
:R1SizeY1 = $a7
:R1SizeX0 = $0028
:R1SizeX1 = $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "DISKCOPY".
			w RegTMenu1

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** Icon "DiskCopy".
:RIcon_DiskCopy		w Icon_DiskCopy
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_DiskCopy_x,Icon_DiskCopy_y
			b USE_COLOR_INPUT

:Icon_DiskCopy
<MISSING_IMAGE_DATA>

:Icon_DiskCopy_x	= .x
:Icon_DiskCopy_y	= .y

;*** Daten für Register "DISKCOPY".
:DIGIT_2_BYTE = $03 ! NUMERIC_RIGHT ! NUMERIC_SET0 ! NUMERIC_BYTE
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RTab1_1  = $0030
:RTab1_2  = $0048
:RTab1_3  = $00b0
:RTab1_4  = $0058
:RLine1_1 = $08
:RLine1_2 = $08
:RLine1_3 = $38
:RLine1_4 = $38
:RLine1_5 = $18
:RLine1_6 = $48

:RegTMenu1		b 12

			b BOX_ICON
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_DiskCopy
				b NO_OPT_UPDATE

::source		b BOX_FRAME
				w R1T01
				w $0000
				b RPos1_y +RLine1_1 -$05
				b RPos1_y +RLine1_2 +$18 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW
				w R1T02
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1
				w sourceDrvText
				b 2

			b BOX_STRING_VIEW
				w $0000
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_2
				w sourceDrvDisk
				b 16

			b BOX_NUMERIC_VIEW
				w R1T06
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_3
				w sysSource +1
				b DIGIT_2_BYTE

::target		b BOX_FRAME
				w R1T04
				w $0000
				b RPos1_y +RLine1_3 -$05
				b RPos1_y +RLine1_4 +$20 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_USER_VIEW
				w $0000
				w initTargetDkNm
				b RPos1_y +RLine1_3
				b RPos1_y +RLine1_3 +$07
				w RPos1_x +RTab1_1
				w RPos1_x +RTab1_1 +$0f

			b BOX_STRING_VIEW
				w R1T05
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_1
				w targetDrvText
				b 2

:RegTMenu1b		b BOX_STRING
				w $0000
				w setFlagDskName
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_2
				w targetDrvDisk
				b 16

			b BOX_NUMERIC_VIEW
				w R1T07
				w $0000
				b RPos1_y +RLine1_6
				w RPos1_x +RTab1_3
				w sysTarget +1
				b DIGIT_2_BYTE

:RegTMenu1a		b BOX_OPTION
				w R1T08
				w updateDiskName
				b RPos1_y +RLine1_6
				w RPos1_x +RTab1_1 +$08
				w flagRenameDisk
				b %11111111

:RegTMenu1c		b BOX_OPTION
				w R1T09
				w $0000
				b (R1SizeY1 +1) -$10
				w RPos1_x +RTab1_4
				w flagVerify
				b %11111111

;*** Texte für Register "DISKCOPY".
if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Diskette"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "kopieren",NULL

:R1T01			b "QUELLE:",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Disk:",NULL

:R1T04			b "ZIEL:",NULL

:R1T05			w RPos1_x
			b RPos1_y +RLine1_3 +$06
			b "Disk:",NULL

:R1T06			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_5 +$06
			b "CMD-Partition:",NULL

:R1T07			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_6 +$06
			b "CMD-Partition:",NULL

:R1T08			w RPos1_x
			b RPos1_y +RLine1_6 +$06
			b "Diskname"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_6 +$08 +$06
			b "behalten",NULL

:R1T09			w RPos1_x +RTab1_4 +$08 +$06
			b (R1SizeY1 +1) -$10 -$08 +$06
			b "Nur 1541/1571:"
			b GOTOXY
			w RPos1_x +RTab1_4 +$08 +$06
			b (R1SizeY1 +1) -$10 +$06
			b "Verify aktivieren",NULL
endif
if LANG = LANG_EN
:R1T00			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Copy"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "Disk/drive",NULL

:R1T01			b "SOURCE:",NULL

:R1T02			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Disk:",NULL

:R1T04			b "TARGET:",NULL

:R1T05			w RPos1_x
			b RPos1_y +RLine1_3 +$06
			b "Disk:",NULL

:R1T06			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_5 +$06
			b "CMD partition:",NULL

:R1T07			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_6 +$06
			b "CMD partition:",NULL

:R1T08			w RPos1_x
			b RPos1_y +RLine1_6 +$06
			b "Keep old"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_6 +$08 +$06
			b "disk name",NULL

:R1T09			w RPos1_x +RTab1_4 +$08 +$06
			b (R1SizeY1 +1) -$10 -$08 +$06
			b "1541/1571 only:"
			b GOTOXY
			w RPos1_x +RTab1_4 +$08 +$06
			b (R1SizeY1 +1) -$10 +$06
			b "Enable verify",NULL
endif

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	_ext_InitIBox		;Status-Box anzeigen.
			jsr	_ext_InitStat		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont		;GEOS-Font für Titel aktivieren.

			LoadW	r0,jobInfTxCopy		;"Diskette kopieren"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxTrack		;"Spur:"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jmp	PutString

;*** Disk-/Verzeichnisname ausgeben.
:prntDiskInfo		LoadW	r0,infoTxDisk		;"Diskette"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y2
			jsr	PutString

			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y2
			LoadW	r0,sourceDrvDisk
			jmp	smallPutString		;Diskname ausgeben.

;*** Status-Zeile aktualisieren.
;    Übergabe: r1L = Aktueller Track.
;              maxTrack = Max.Anzahl an Tracks auf Medium.
;
;Hinweis:
;r1/r4 dürfen nicht verändert werden:
;Enthalten Werte für WriteBlock!
;
:updateStatus		PushW	r1			;Zeiger Verzeichnis-Eintrag sichern.
			PushW	r4			;Adr. Zwischenspeicher sichern.

			MoveB	r1L,r0L			;Track-Adresse kopieren.
			ClrB	r0H

			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y1
			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal

			LoadW	r0,infoTxMaxTr		;" von " ausgeben.
			jsr	PutString

			MoveB	maxTrack,r0L		;Max. Track einlesen.
			ClrB	r0H
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Max. Track ausgeben.

			lda	#" "
			jsr	SmallPutChar		;Anzeige korrigieren.

			jsr	_ext_PrntStat		;Fortschrittsbalken aktulisieren.

			PopW	r4			;Zeiger Verz.Eintrag zurücksetzen.
			PopW	r1			;Adr. Zwischenspeicher zurücksetzen.

			rts

;*** Texte.
if LANG = LANG_DE
:jobInfTxCopy		b PLAINTEXT,BOLDON
			b "DISKETTE KOPIEREN"
			b PLAINTEXT,NULL

:infoTxDisk		b "Diskette: ",NULL
:infoTxTrack		b "Spur: ",NULL
:infoTxMaxTr		b " von ",NULL
endif
if LANG = LANG_EN
:jobInfTxCopy		b PLAINTEXT,BOLDON
			b "COPYING DISK/DRIVE"
			b PLAINTEXT,NULL

:infoTxDisk		b "Disk: ",NULL
:infoTxTrack		b "Track: ",NULL
:infoTxMaxTr		b " of ",NULL
endif

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
			beq	:1			; => Nein, weiter...
			rts				; => Ja, Ende...

::1			MoveB	r1L,readDataTr		;Zeiger auf nächsten Sektor
			MoveB	r1H,readDataSe		;zwischenspeichern.

			lda	lastTrack		;Aktuelle Position für
			pha				;Verify zwischenspeichern.
			lda	statusPos
			pha

			lda	#$00
			jsr	WriteDataBuf		;Daten auf Disk schreiben.

			pla
			tay
			pla

			bit	flagVerify
			bpl	:3

			cpx	#$ff			;Daten-Ende?
			beq	:2			; => Ja, weiter...
			cpx	#$00			;Diskfehler?
			bne	:exit			; => Ja, Abbruch...

::2			sta	lastTrack		;Aktuelle Position für
			sty	statusPos		;Verify zurücksetzen.

			lda	statusPat		;Füllmuster für Statusanzeige
			eor	#%00000100		;anpassen.
			sta	statusPat

			lda	#$ff
			jsr	WriteDataBuf		;Daten auf Disk überprüfen.

			lda	statusPat		;Füllmuster für Statusanzeige
			eor	#%00000100		;wieder zurücksetzen.
			sta	statusPat

::3			MoveB	r1L,writeDataTr		;Zeiger auf nächsten Sektor
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

			LoadW	r10,targetDrvDisk
			jsr	saveDiskName		;Neuen Disknamen schreiben.

::done			ldx	#NO_ERROR		;Flag: Kein Fehler.
::exit			rts				;Ende...

;*** Sektoren in Speicher einlesen.
:ReadDataBuf		jsr	OpenDrvSource		;Source-Laufwerk öffnen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;TurboDOS durch NewDisk bereits aktiv.
;			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			MoveB	readDataTr,r1L		;Zeiger auf ersten Sektor
			MoveB	readDataSe,r1H		;einlesen.
			LoadW	r4,diskCopyBuf		;Zeiger auf Anfang Datenspeicher.

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
::exit			jsr	DoneWithIO		;I/O-Bereich ausblenden, Ende...
::err			rts

;*** Sektoren aus Speicher schreiben.
;Übergabe: A = $00:Write, $FF:Verify
:WriteDataBuf		sta	flagWriteMode

			jsr	OpenDrvTarget		;Target-Laufwerk öffnen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;TurboDOS durch NewDisk bereits aktiv.
;			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			MoveB	writeDataTr,r1L		;Zeiger auf ersten Sektor
			MoveB	writeDataSe,r1H		;einlesen.
			LoadW	r4,diskCopyBuf		;Zeiger auf Anfang Datenspeicher.

::loop			lda	r1L
			cmp	lastTrack		;Aktuellen Track anzeigen?
			beq	:2			; => Nein, weiter...

			sta	lastTrack		;Neuen Track speichern.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			jsr	updateStatus		;Status aktualisieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			inc	statusPos		;Fortschrittszähler erhöhen.

::2			lda	#< WriteBlock		;Block auf Disk schreiben.
			ldx	#> WriteBlock
			bit	flagWriteMode		;Verify?
			bpl	:3			; => Nein, weiter...
			lda	#< VerWriteBlock	;Block auf Disk überprüfen.
			ldx	#> VerWriteBlock
::3			jsr	CallRoutine
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
::no_more_track		ldx	#$ff			;Flag: Ende erreicht.
::exit			jsr	DoneWithIO		;I/O-Bereich ausblenden, Ende...
::err			rts

;*** Konfiguration testen.
:initDiskCopy		lda	#$00			;Flag löschen: "Partitionsgröße".
			sta	updateNMSize		;(Nur für NativeMode)

			sta	flagVerify		;Verify abschalten.
			lda	#BOX_OPTION_VIEW	;Option "Verify" abschalten.
			sta	RegTMenu1c

			ldx	sysTarget
			lda	RealDrvType -8,x
			cmp	#Drv1541		;Target = 1541?
			beq	:1			; => Ja, Verify einschalten.
			cmp	#Drv1571		;Target = 1571?
			bne	:2			; => Nein, weiter...

::1			dec	flagVerify		;Verify für 1541/1571 einschalten.
			lda	#BOX_OPTION		;Option "Verify" einschalten.
			sta	RegTMenu1c

::2			lda	sysSource
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

			lda	#< sourceDrvDisk	;Zeiger auf Speicher für Name
			ldx	#> sourceDrvDisk	;Source-Laufwerk.

			jsr	copyDiskName		;Diskname kopieren.

:getDkNmTarget		jsr	OpenDrvTarget		;Target-Laufwerk öffnen.

			lda	#< targetDrvDisk	;Zeiger auf Speicher für Name
			ldx	#> targetDrvDisk	;Target-Laufwerk.

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
;Hinweis:
;Zumindest auf 1571 muss die Routine
;NewDisk ausgeführt werden, da sonst
;beim schreiben der Blocks auf Disk
;der erste Block aus dem Buffer nicht
;korrekt gespeichert wird und dabei
;keine Fehlermeldung erzeugt wird.
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
			jmp	OpenPartition		;Partition öffnen.
::1			jmp	NewDisk			;Diskette öffnen.

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
			jmp	OpenPartition		;Partition öffnen.
::1			jmp	NewDisk			;Diskette öffnen.

;*** Diskname initialisieren.
;Aufruf aus Registermenü.
:updateDiskName		jsr	setDiskName		;Ziel-Diskname definieren.

			LoadW	r15,RegTMenu1b		;Option aktualisieren:
			jmp	RegisterUpdate		;"Name Target-Disk"

;*** Diskname manuell ändern.
;--- Hinweis:
;Wenn der Name des Ziel-Laufwerks
;geändert wird, dann den neuen Namen
;für das Ziel-Laufwerk verwenden.
:setFlagDskName		lda	#$00			;Option löschen:
			sta	flagRenameDisk		;"Diskname behalten".

			LoadW	r15,RegTMenu1a		;Option aktualisieren:
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
:flagRenameDisk		b $00
:flagVerify		b $00
:flagWriteMode		b $00
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
			w Dlg_Titel_Err
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
			w Dlg_Titel_Err
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
			w Dlg_Titel_Err
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

;*** Startadresse Kopierspeicher.
:Memory1
:Memory2		= (Memory1 / 256 +1)*256
:diskCopyBuf		= Memory2
:endCopyBuf		= OS_BASE

;*** Endadresse testen:
;Sicherstellen das genügend Speicher
;für DiskCopy verfügbar ist.
			g OS_BASE -$2000
;***
