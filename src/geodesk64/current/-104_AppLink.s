; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konfiguration aus Datei laden.
:xLNK_LOAD_DATA		jsr	TempLinkDrive		;AppLink.cfg-Laufwerk aktivieren.
			txa				;Laufwerksfehler?
			bne	:1			; => Ja, Abbruch...

			jsr	LNK_FIND_CONFIG		;Konfigurationsdatei suchen.
			txa				;Datei gefunden?
			beq	:2			; => Ja, weiter...
::1			rts				; => Abbruch...

::2			jsr	LNK_GET_VHEADER		;VLIR-Header einlesen.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			jsr	LNK_INIT_VLIR		;VLIR-Daten initialisieren.

			lda	#$01			;$00="MyComputer / Nicht speichern.
			sta	LinkData		;Zeiger auf ersten AppLink.

;--- Hinweis:
;Laufwerk bereits aktiv...
;			jsr	OpenLinkDrive		;AppLink.cfg-Laufwerk öffnen.
;			txa				;Fehler?
;			bne	:1			; => Ja, Abbruch...

::3			lda	ND_Record		;Zeiger auf AppLink einlesen.
			cmp	#LINK_COUNT_MAX		;Max. 25 AppLinks gespeichert?
			bcs	:5			; => Ja, Ende. (Max. Notitzblock).
			jsr	LNK_SET_VLIRDAT		;Zeiger auf VLIR-Datensatz setzen.
			cpx	#$00			;Datensatz vorhanden?
			beq	:4			; => Nein, weiter...
			jsr	GetBlock		;VLIR-Datensektor einlesen.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			lda	ND_Data +2		;AppLink definiert?
			beq	:4			; => Nein, weiter...

			jsr	ReadALinkData		;AppLink-Daten einlesen.

			jsr	LNK_SET_NEXT_VEC	;Zeiger auf nächsten AppLink.
			inc	LinkData		;Zähler für AppLinks.

::4			inc	ND_Record		;Zeiger auf nächsten Datensatz.
			jmp	:3

::5			jmp	BackTempDrive		;Laufwerk zurücksetzen.

;*** Konfigurationsdatei suchen.
:LNK_FIND_CONFIG	LoadB	r7L,SYSTEM		;Typ: Systemdatei.
			LoadB	r7H,1			;Nur erste Datei finden.
			LoadW	r6,GD_APPLNAME		;Dateiname.
			LoadW	r10,GD_APPLCLASS	;GEOS-Klasse.
			jsr	FindFTypes		;AppLink-Konfiguration suchen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			lda	r7H			;Datei gefunden?
			bne	:not_found		; => Nein, Abbuch...

			LoadW	r6,GD_APPLNAME		;Datei suchen um ":dirEntryBuf"
			jmp	FindFile		;auf Datei zu setzen.

::not_found		ldx	#FILE_NOT_FOUND
::error			rts

;*** VLIR-Header der Konfigurationsdatei einlesen.
;    Übergabe: ":dirEntryBuf" = Verzeichnis-Eintrag.
:LNK_GET_VHEADER	jsr	LNK_SET_VHEADER		;VLIR-Header-Daten setzen.
			jmp	GetBlock

;*** VLIR-Daten initialisieren.
:LNK_INIT_VLIR		LoadB	ND_Record,0		;Zeiger auf ersten Datensatz.
			LoadW	r14,LinkData +LINK_DATA_BUFSIZE +1
			LoadW	r15,appLinkIBufU
			rts

;*** Zeiger auf nächsten AppLink-Datenpuffer.
:LNK_SET_NEXT_VEC	AddVBW	LINK_DATA_BUFSIZE,r14
			AddVBW	64,r15
			rts

;*** Daten für VLIR-Datensatz setzen.
;    Übergabe: AKKU = ND_Record.
;    Rückgabe: XREG = Spur VLIR-Header.
:LNK_SET_VLIRDAT	asl				;Zeiger auf VLIR-Sektor einlesen.
			tay
			ldx	ND_VLIR +2,y
			stx	r1L
			lda	ND_VLIR +3,y
			sta	r1H
			LoadW	r4,ND_Data
			rts

;*** Daten für VLIR-Header setzen.
;    Übergabe: dirEntryBuf = Zeiger auf Verzeichniseintrag.
:LNK_SET_VHEADER	lda	dirEntryBuf +1		;VLIR-Header einlesen.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,ND_VLIR
			rts

;*** Icon von Disk einlesen.
;Hinweis:
;Aus Kompatibilitätsgründen verbleibt
;die Variante im Programm.
;Neue Version ab 29.06.2019 speichern
;das Icon in der AppLink.cfg.
:loadIconDisk		jsr	AL_SET_DEVICE		; => Datei-Icon.

			MoveW	r14,r6
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:link_unknown		; => Ja, Unknown-Icon anzeigen.

			lda	dirEntryBuf +19		;Info-Block vorhanden?
			beq	:link_cbm		; => Nein, BASIC-Datei.

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Info-Block einlesen.
			txa				;Fehler?
			bne	:link_unknown		; => Ja, Unknown-Icon anzeigen.

			lda	#<fileHeader +4		;Zeiger auf Fileheader und
			ldx	#>fileHeader +4		;GEOS-Datei-Icon.
			bne	:CopyIconData

::link_cbm		lda	#<Icon_CBM		; => System-Icon: CBM.
			ldx	#>Icon_CBM
			bne	:CopyIconData

::link_unknown		lda	#<Icon_Deleted		; => System-Icon: Unknown.
			ldx	#>Icon_Deleted

::CopyIconData		sta	r0L
			stx	r0H

			ldy	#$3f
::loop1			lda	(r0L),y			;Icon-Daten in Link-Daten
			sta	(r15L),y		;kopieren.
			dey
			bpl	:loop1

			jmp	OpenLinkDrive		;AppLink.cfg-Laufwerk öffnen.

;*** AppLink-Daten einlesen.
:ReadALinkData		ldx	#$02			;Zeiger auf ersten Datenbyte.

			ldy	#LINK_DATA_FILE
			jsr	ReadFNameData		; => Dateiname.
			ldy	#LINK_DATA_NAME
			jsr	ReadFNameData		; => AppLink-Name.

			ldy	#LINK_DATA_TYPE
			jsr	ReadHexData		; => AppLink-Typ.

			inx
			ldy	#LINK_DATA_XPOS
			jsr	ReadHexData		; => Icon-XPos.
			ldy	#LINK_DATA_YPOS
			jsr	ReadHexData		; => Icon-YPos.

			inx
			ldy	#LINK_DATA_COLOR	;Farbdaten einlesen.
::loop1			jsr	ReadHexData		; => Farbe (3x3 Cards).
			iny
			cpy	#LINK_DATA_COLOR +9
			bcc	:loop1

			inx
			lda	ND_Data,x
			sec
			sbc	#$39
			ldy	#LINK_DATA_DRIVE
			sta	(r14L),y		; => AppLink-Laufwerk.
			inx

			ldy	#LINK_DATA_DVTYP
			jsr	ReadHexData		; => RealDrvType.
			ldy	#LINK_DATA_DPART
			jsr	ReadHexData		; => CMD-Partition.

			inx
			ldy	#LINK_DATA_DSDIR +0
			jsr	ReadHexData		; => CMD-Verzeichnis/Spur.
			ldy	#LINK_DATA_DSDIR +1
			jsr	ReadHexData		; => CMD-Verzeichnis/Sektor.

			inx
			ldy	#LINK_DATA_ENTRY +0
			jsr	ReadHexData		; => Zeiger auf Verzeichnis-Eintrag.
			ldy	#LINK_DATA_ENTRY +1
			jsr	ReadHexData		; => Verzeichnis-Eintrag/Spur.
			ldy	#LINK_DATA_ENTRY +2
			jsr	ReadHexData		; => Verzeichnis-Eintrag/Sektor.

			inx
			ldy	#LINK_DATA_WMODE
			jsr	ReadHexData		; => Fenstermodi.
			ldy	#LINK_DATA_FILTER
			jsr	ReadHexData		; => Dateifilter.
			ldy	#LINK_DATA_SORT
			jsr	ReadHexData		; => Sortiermodus.

			jsr	testIconType		;Auf System-Icon testen.
			cpy	#$00 			;System-Icon?
			bne	:copySysIcon		; => Ja, nicht kopieren.

;--- Hinweis:
;Kompatibel mit früheren Versionen der
;AppLink.cfg: Falls Icon nicht in Datei
;gespeichert, dann von Disk laden.
			inx
			lda	ND_Data,x		;Icon in AppLink.cfg gespeichert?
			bne	:copyUsrIcon		; => Ja, weiter...
			jmp	loadIconDisk		;Icon von Disk einlesen.

;--- Benutzerdefiniertes Icon.
::copyUsrIcon		ldy	#0
::loop2			jsr	ReadDataByte		;Icon-Daten in Link-Daten
			sta	(r15L),y		;speichern.
			iny
			cpy	#64 +9
			bcc	:loop2
			rts

;--- System-Icon.
::copySysIcon		sta	r0L			;Zeiger auf System-Icon speichern.
			sty	r0H

			ldy	#$3f
::loop3			lda	(r0L),y			;Icon-Daten in Link-Daten
			sta	(r15L),y		;kopieren.
			dey
			bpl	:loop3
			rts

;*** Icon-Typ ermitteln.
:testIconType		ldy	#LINK_DATA_TYPE
			lda	(r14L),y		;AppLink-Typ einlesen.
;			cmp	#AL_TYPE_FILE		;Datei?
			beq	:link_fileicon		; => Ja, weiter...
			cmp	#AL_TYPE_DRIVE		;Laufwerk?
			beq	:link_drive		; => Ja, weiter...
			cmp	#AL_TYPE_PRNT		;Drucker?
			beq	:link_printer		; => Ja, weiter...
			cmp	#AL_TYPE_SUBDIR		;Verzeichnis?
			beq	:link_subdir		; => Ja, weiter...

::link_unknown		lda	#<Icon_Deleted		; => System-Icon: Unknown.
			ldy	#>Icon_Deleted
			rts

::link_cbm		lda	#<Icon_CBM		; => System-Icon: CBM.
			ldy	#>Icon_CBM
			rts

::link_subdir		lda	#<Icon_Map		; => System-Icon: Verzeichnis.
			ldy	#>Icon_Map
			rts

::link_printer		lda	#<Icon_Printer		; => System-Icon: Drucker.
			ldy	#>Icon_Printer
			rts

::link_drive		lda	#<Icon_Drive		; => System-Icon: Laufwerk.
			ldy	#>Icon_Drive
			rts

::link_fileicon		lda	#$00
			tay
			rts

;*** Datei- und AppLink-Name einlesen.
:ReadFNameData		lda	#$10			;Max. 16 Zeichen einlesen.
			sta	r0L

::loop1			lda	ND_Data,x		;Zeichen aus Name einlesen.
			cmp	#CR			;#CR = Zeilenende?
			beq	:end			; => Ja, Ende...

			sta	(r14L),y		;Zeichen in Link-Daten speichern.
			inx				;Zeiger auf nächstes Zeichen.
			iny
			dec	r0L			;Max. 16 Zeichen gelesen?
			bne	:loop1			; => Nein, weiter...

::end			lda	#$00			;Name mit $00-Bytes auf
::loop2			sta	(r14L),y		;17 Zeichen auffüllen.
			iny
			dec	r0L
			bpl	:loop2
			inx
			rts

;*** 2-Byte-Hexzahl einlesen und in Puffer schreiben.
:ReadHexData		jsr	ReadDataByte		;2-Byte-Hexzahl einlesen und
			sta	(r14L),y		;in Puffer speichern.
			rts

;*** 2-Byte-Hexzahl einlesen.
:ReadDataByte		jsr	:ReadChar		;ASCII-Zeichen einlesen und
							;nach HEX-Nibble wandeln.
			asl
			asl
			asl
			asl
			sta	r0L			;High-Nibble speichern.

			jsr	:ReadChar		;ASCII-Zeichen einlesen und
							;nach HEX-Nibble wandeln.
			ora	r0L			;LOW-Nibble mit HIGH-Nibble
			rts

;--- ASCII-Zeichen einlesen und konvertieren.
::ReadChar		lda	ND_Data,x		;ASCII-Zeichen einlesen.
			sec				;Zeichen nach Zahl 0-9 wandeln.
			sbc	#$30
			cmp	#10			;Zahl > 10?
			bcc	:1			; => Nein, weiter...
			sbc	#$07			;Zeichen nach Zahl 10-15 wandeln.
::1			inx				;Zeiger auf nächstes Link-Byte.
			rts

;*** Konfiguration in Datei speichern.
:xLNK_SAVE_DATA		jsr	TempLinkDrive		;AppLink-Konfig-Laufwerk öffnen.
			txa				;Laufwerksfehler?
			bne	:err_linkdrv		; => Ja, Abbruch...

			jsr	LNK_FIND_CONFIG		;AppLink-Datei suchen.
			txa				;Fehler?
			beq	:init_save		; => Nein, weiter...

			jsr	LNK_NEW_CONFIG		;Neue Konfigurationsdatei schreiben.
			txa				;Fehler?
			beq	:init_save		; => Nein, weiter...

;--- Fehlermeldungen.
::err_newconf		lda	#<Dlg_ErrNewCfg		;Neue Konfigurationsdatei kann
			ldx	#>Dlg_ErrNewCfg		;nicht erstellt werden.
			bne	:error
::err_linkdrv		lda	#<Dlg_ErrLnkDrv		;Konfigurationslaufwerk kann
			ldx	#>Dlg_ErrLnkDrv		;nicht aktiviert werden.
			bne	:error
::err_openconf		lda	#<Dlg_ErrOpenCfg	;Die Konfigurationsdatei kann
			ldx	#>Dlg_ErrOpenCfg	;nicht geöffnet werden.
			bne	:error
::err_savedata		lda	#<Dlg_ErrSvData		;Die Konfiguration kann nicht
			ldx	#>Dlg_ErrSvData		;gespeichert werden.
			;bne	:error
::error			sta	r0L
			stx	r0H
			jmp	DoDlgBox

;--- Initialisierung.
::init_save		jsr	LNK_GET_VHEADER		;VLIR-Header einlesen.
			txa				;Fehler?
			bne	:err_openconf		; => Ja, Abbruch...

			jsr	LNK_INIT_VLIR		;VLIR-Daten initialisieren.

			lda	#$01			;$00="MyComputer / Nicht speichern.
			sta	r13H			;Zähler für AppLink zurücksetzen.

;--- AppLinks in Datensätzen speichern.
::begin_save		lda	ND_Record		;Datensatz-Nr. einlesen.
			cmp	#LINK_COUNT_MAX		;Max. Anzahl AppLinks erreicht?
			bcs	:close_config		; => Ja, Ende...

			lda	#$00			;Datenpuffer löschen.
			tax
::clr_data		sta	ND_Data,x
			inx
			bne	:clr_data

;			lda	#$00			;Daten-Ende-Kennung schreiben.
;			sta	ND_Data +2
;			sta	ND_Data +0		;Ende Datensatz Track=$00.
			lda	#$02			;Zeiger auf letztes Byte im Sektor.
			sta	ND_Data +1

			jsr	CopyCfg2Buf		;Daten für AppLink in Puffer.

			lda	ND_Data +2		;Daten gespeichert?
			bne	:save_data		; => Ja, weiter...

			jsr	LNK_DEL_VLIRSEK		;Sektor freigeben.
			txa				;Fehler?
			bne	:err_savedata		; => Ja, Abbruch...
			beq	:next_data		;Weiter...

::save_data		lda	ND_Record		;Datensatz-Nr. einlesen.
			asl
			tax
			lda	ND_VLIR +2,x		;Existiert Datensatz bereits?
			bne	:do_data_set		; => Ja, weiter...

			jsr	LNK_NEW_VLIRSEK		;Freien Sektor suchen.
			txa				;Fehler?
			bne	:err_savedata		; => Ja, Abbruch...

::do_data_set		lda	ND_Record		;VLIR-Datensatz mit AppLink-Daten.
			jsr	LNK_SET_VLIRDAT		;Zeiger auf VLIR-Datensatz setzen.
			jsr	PutBlock		;VLIR-Datensatz speichern.
			txa				;Fehler?
			bne	:err_savedata		; => Ja, Abbruch...

::next_data		inc	r13H			;Zähler AppLinks +1.

			jsr	LNK_SET_NEXT_VEC	;Zeiger auf nächsten AppLink.
			inc	ND_Record		;Zeiger auf nächsten Datensatz.
			jmp	:begin_save		;Nächsten AppLink speichern.

;--- Konfiguration gespeichert, Ende...
::close_config		jsr	LNK_SET_VHEADER		;VLIR-Header-Daten setzen.
			jsr	PutBlock		;VLIR-Header speichern.
			txa				;Fehler?
			bne	:err_savedata		; => Ja, Abbruch...

;--- BAM schreiben falls Datensatz angelegt/gelöscht wurde.
			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Fehler?
			bne	:err_savedata		; => Ja, Abbruch...

			jmp	BackTempDrive		;Original-Laufwerk wieder setzen.

;*** Freien Sektor für neuen VLIR-Datensatz reservieren.
:LNK_NEW_VLIRSEK	ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode-Laufwerk?
			beq	:initNxFree		; => Nein, weiter...
			lda	#64			;Suche ab $01/$40 = CMD-Standard.
::initNxFree		sta	r3H
			lda	#1
			sta	r3L
			jsr	SetNextFree		;Freien Sektor suchen.
			txa				;Sektor gefunden?
			bne	:err			; => Nein, Abbruch...

			lda	ND_Record		;Freien Sektor in VLIR-Header
			asl				;schreiben.
			tay
			lda	r3L
			sta	ND_VLIR +2,y
			lda	r3H
			sta	ND_VLIR +3,y

;			ldx	#NO_ERROR		; => Kein Fehler.
::err			rts

;*** VLIR-Datensatz löschen.
:LNK_DEL_VLIRSEK	ldx	#NO_ERROR
			lda	ND_Record		;Zeiger auf aktuellen Datensatz und
			asl				;Datensatz löschen (VLIR=$00/$FF).
			tay
			lda	ND_VLIR +2,y		;Datensatz angelegt?
			beq	:exit			; => Nein, Ende...
			sta	r6L
			lda	#$00			;Track löschen = $00.
			sta	ND_VLIR +2,y
			lda	ND_VLIR +3,y		;Sektor einlesen.
			sta	r6H
			lda	#$ff			;Sektor löschen = $FF.
			sta	ND_VLIR +3,y
			jmp	FreeBlock		;Sektor freigeben.
::exit			rts

;*** AppLink-Daten in Datenpuffer kopieren.
;Die Daten werden nach Hex/ASCII gewandelt.
:CopyCfg2Buf		lda	r13H			;Anzahl AppLinks testen.
			cmp	LinkData		;Weiterer AppLink vorhanden?
			bcc	:save_data		; => Ja, weiter...
;			lda	#$00			;VLIR-Daten löschen.
;			sta	ND_Data +2
			rts

::save_data		ldx	#$02			;Zeiger auf Anfang Datenpuffer.

			ldy	#LINK_DATA_FILE
			jsr	WriteFNameData		;AppLink-Name speichern.

			ldy	#LINK_DATA_NAME
			jsr	WriteFNameData		;Datei-Name speichern.

			stx	r13L			;Zeiger auf Datenpuffer speichern.

;--- AppLink-Typ.
			ldy	#LINK_DATA_TYPE
			lda	(r14L),y
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII_CR		;Hex-Zahl in Puffer schreiben.

;--- Icon XPos/YPos.
			ldy	#LINK_DATA_XPOS
			lda	(r14L),y
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.

			ldy	#LINK_DATA_YPOS
			lda	(r14L),y
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII_CR		;Hex-Zahl in Puffer schreiben.

;--- Farbdaten speichern.
			ldy	#LINK_DATA_COLOR
::loop1			lda	(r14L),y		;Farbdaten einlesen.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.
			iny
			cpy	#LINK_DATA_COLOR +9
			bcc	:loop1
			lda	#CR			;Zeilenende-Kennung.
			sta	ND_Data,x
			inx

;--- Laufwerk, RealDrvType und Partition.
			ldy	#LINK_DATA_DRIVE
			lda	(r14L),y		;Laufwerksadresse einlesen.
			clc
			adc	#$39
			sta	ND_Data,x
			inx
			stx	r13L

			ldy	#LINK_DATA_DVTYP
			lda	(r14L),y		;Laufwerkstyp einlesen.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.

			ldy	#LINK_DATA_DPART
			lda	(r14L),y		;CMD-Partition einlesen.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII_CR		;Hex-Zahl in Puffer schreiben.

;--- CMD-Verzeichnis Spur/Sektor.
			ldy	#LINK_DATA_DSDIR +0
			lda	(r14L),y		;Tr/NativeMode-Verzeichnis.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.

			ldy	#LINK_DATA_DSDIR +1
			lda	(r14L),y		;Tr/NativeMode-Verzeichnis.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII_CR		;Hex-Zahl in Puffer schreiben.

;--- Zeiger Verzeichnis-Eintrag.
			ldy	#LINK_DATA_ENTRY +0
			lda	(r14L),y		;Zeiger Verzeichnis-Eintrag.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.

;--- Verzeichnis-Eintrag/Sektor.
			ldy	#LINK_DATA_ENTRY +1
			lda	(r14L),y		;Tr/Verzeichnis-Eintrag.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.

;--- Verzeichnis-Eintrag/Zeiger.
			ldy	#LINK_DATA_ENTRY +2
			lda	(r14L),y		;Zeiger/Verzeichnis-Eintrag.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII_CR		;Hex-Zahl in Puffer schreiben.

;--- Fenstermodi/Filter/Sortiermodus.
			ldy	#LINK_DATA_WMODE
			lda	(r14L),y		;Fenstermodi.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.
			ldy	#LINK_DATA_FILTER
			lda	(r14L),y		;Dateifilter.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.
			ldy	#LINK_DATA_SORT
			lda	(r14L),y		;Sortiermodus.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII_CR		;Hex-Zahl in Puffer schreiben.

;--- Icon-Daten.
			jsr	testIconType		;Auf System-Icon testen.
			cpy	#$00 			;System-Icon?
			bne	:endData		; => Ja, nicht kopieren.

;--- Icon-Daten speichern.
::copyUsrIcon		ldy	#0
::loop2			lda	(r15L),y		;Icon-Daten einlesen.
			jsr	Hex2ASCII		;Zahl nach ASCII wandeln.
			jsr	WriteASCII		;Hex-Zahl in Puffer schreiben.
			iny
			cpy	#64			;Alle Daten kopiert?
			bcc	:loop2			; => Nein, weiter...
			lda	#CR
			sta	ND_Data,x
			inx

;--- Ende Datensatz markieren.
::endData		lda	#NULL
			sta	ND_Data,x
			sta	ND_Data +0
			stx	ND_Data +1		;Anzahl Bytes im Datensatz.
			rts

;*** Datei- und AppLink-Name schreiben.
;    Übergabe: XReg = Zeiger auf Puffer.
;              YReg = Zeiger auf AppLink-Daten.
:WriteFNameData		lda	(r14L),y		;Zeichen aus Dateinamen einlesen.
			beq	:end			;Ende erreicht? => Ja, weiter...
			sta	ND_Data,x		;Zeichen in Puffer kopieren.
			iny
			inx
			bne	WriteFNameData		;Weiter bis Name kopiert.
::end			lda	#CR			;Ende Name markieren.
			sta	ND_Data,x
			inx
			rts

;*** Hex-Zahl nach ASCII wandeln.
;    Übergabe: AKKU = Hex-Zahl.
:Hex2ASCII		pha
			lsr				;High-Nibble erzeugen.
			lsr
			lsr
			lsr
			jsr	:Conv2ASCII
			tax				;High-Bibble merken.

			pla
			and	#%00001111		;Low-Nibble erzeugen.

::Conv2ASCII		cmp	#10			;Zahl < 10?
			bcc	:1			; => Ja, weiter...
			clc
			adc	#$07			;Nibble ist Zahl von 10-15.
::1			adc	#$30			;Nach ASCII wandeln.
			rts

;*** 2-stellige ASCII-Hex-Zahl in Datensatz schreiben.
;    Übergabe: AKKU = Hex-Zahl/Low-Nibble.
;              XReg = Hex-Zahl/High-Nibble.
;Hinweis: YReg darf nicht geändert werden.
:WriteASCII		pha
			lda	#NULL			;Nur HEX-Zahl schreiben.
			beq	WriteData

:WriteASCII_CR		pha
			lda	#CR			;HEX-Zahl und CR schreiben.

:WriteData		sta	:0 +1
			txa
			ldx	r13L
			sta	ND_Data,x		;High-Nibble schreiben.
			inx
			pla
			sta	ND_Data,x		;Low-Nibble schreiben.
			inx

::0			lda	#$ff			;CR/Zeilenende schreiben?
			beq	:1			; => Nein, weiter...

			sta	ND_Data,x
			inx

::1			stx	r13L			;Position Datenpuffer speichern.
			rts

;*** Leere Konfigurationsdatei erstellen.
:LNK_NEW_CONFIG		jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
::1			rts				;Abbruch.

::2			LoadB	r10L,0			;Zeiger auf Infoblock für
			LoadW	r9,HdrB000		;neue Konfigurationsdatei.
			jsr	SaveFile		;Datei speichern.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			jsr	LNK_FIND_CONFIG		;Konfigurationsdatei suchen.
			txa				;Datei gefunden?
			bne	:1

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			lda	HdrB160			;SaveFile löscht Byte #160,
			sta	fileHeader +160		;Byte wieder herstellen.

			lda	dirEntryBuf+19		;Infoblock schreiben.
			sta	r1L
			lda	dirEntryBuf+20
			sta	r1H
			LoadW	r4,fileHeader
			jmp	PutBlock

;*** Info-Block für Konfigurationsdatei.
:HdrB000		w GD_APPLINK
:HdrB002		b $03,$15
			b $bf
			b %11111111,%11111111,%11111111
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00011001
			b %10011100,%00111000,%00100101
			b %10011100,%00111000,%00111101
			b %10011100,%00111000,%00100101
			b %10000000,%00000000,%00100101
			b %10111110,%01111100,%00000001
			b %10000000,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10011100,%00000000,%00000001
			b %10000000,%00000011,%00111001
			b %10111110,%00000100,%00100101
			b %10000000,%00000101,%10100101
			b %10000000,%00000100,%10100101
			b %10000000,%00000011,%10111001
			b %10000000,%00000000,%00000001
			b %10101010,%10101010,%10101011
			b %11010101,%01010101,%01010101
			b %11111111,%11111111,%11111111

:HdrB068		b $83				;USR.
:HdrB069		b SYSTEM			;GEOS-Systemdatei.
:HdrB070		b VLIR				;GEOS-Dateityp VLIR.
:HdrB071		w $0000,$ffff,$0000		;Programm-Anfang/-Ende/-Start.
:HdrB077		b "GD_AppLinks "		;Klasse
:HdrB089		b "V1.1"			;Version
:HdrB093		b NULL
:HdrB094		b $00,$00			;Reserviert
:HdrB096		b $00				;Bildschirmflag
:HdrB097		b "GeoDesk64"			;Autor
:HdrB106		s 11				;Reserviert
:HdrB117		t "-SYS_CLASS"  		;Anwendung/Klasse/Version/NULL
:HdrB134		s 26				;Reserviert.

if LANG = LANG_DE
:HdrB160		b "Konfigurationsdatei",CR
			b "für GeoDesk AppLinks",NULL
endif
if LANG = LANG_EN
:HdrB160		b "Configuration file",CR
			b "for GeoDesk AppLinks",NULL
endif
:HdrEnd			s (HdrB000+256)-HdrEnd

:ND_Record		b $00
:ND_Class		= HdrB077 ;b "Notes       V1.0",NULL
:GD_APPLINK		b "GeoDesk.lnk",NULL
:GD_APPLNAME		s 17

;*** Fehler: Neue Konfiguration konnte nicht gespeichert werden.
:Dlg_ErrNewCfg		b %01100001
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
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Die neue Konfigurationsdatei",NULL
::3			b "konnte nicht erstellt werden!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The new configuration file",NULL
::3			b "could not be created!",NULL
endif

;*** Fehler: Laufwerk konnte nicht gewechselt werden.
:Dlg_ErrLnkDrv		b %01100001
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
			b DBTXTSTR   ,$0c,$3c
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Laufwerk mit der AppLink-",NULL
::3			b "Konfigurationsdatei konnte",NULL
::4			b "nicht geöffnet werden.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The drive with the AppLink",NULL
::3			b "configuration file could not",NULL
::4			b "be opened.",NULL
endif

;*** Fehler: Konfigurationsdatei konnte nicht geöffnet werden.
:Dlg_ErrOpenCfg		b %01100001
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
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Die Konfigurationsdatei konnte",NULL
::3			b "konnte nicht geöffnet werden!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The configuration file could",NULL
::3			b "not be opened!",NULL
endif

;*** Fehler: Datensatz konnte nicht gespeichert werden.
:Dlg_ErrSvData		b %01100001
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
			b DBTXTSTR   ,$0c,$3c
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Die Konfigurationsdatei",NULL
::3			b "konnte nicht gespeichert",NULL
::4			b "werden.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The configuration file",NULL
::3			b "could not be saved.",NULL
::4			b "",NULL
endif

;*** AppLink umbennen.
:xLNK_RENAME		ldy	#LINK_DATA_NAME		;Titel des AppLinks in
			ldx	#$00			;Zwischenspeicher kopieren.
::loop1			lda	(r14L),y
			sta	AppLinkName,x
			beq	:rename
			iny
			inx
			cpx	#16
			bcc	:loop1

::rename		LoadW	a0,AppLinkName		;Zeiger auf Zwischenspeicher.
			LoadW	r0,Dlg_InputName
			jsr	DoDlgBox		;AppLink umbennen.

			lda	sysDBData
			cmp	#CANCEL			;Abbruch gewählt?
			beq	:exit

			lda	AppLinkName		;Neuer Name gültig?
			beq	:exit			; => Nein, Abbruch...

			ldy	#LINK_DATA_NAME		;Neuen Namen in AppLink speichern.
			ldx	#$00
::loop2			lda	AppLinkName,x
			beq	:loop3
			sta	(r14L),y
			iny
			inx
			cpx	#16
			bcc	:loop2

::end_name		lda	#$00			;Name bis 16Zeichen mit
::loop3			sta	(r14L),y		;$00-Bytes auffüllen.
			iny
			inx
			cpx	#16 +1
			bcc	:loop3

			ldx	#OK			;OK, Ende...
			b $2c
::exit			ldx	#CANCEL			;Abbruch, Ende...
			rts

:AppLinkName		s 17

;*** Neuen Namen für AppLink eingeben.
:Dlg_InputName		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBGETSTRING,$10,$30
			b a0L, 16
;HINWEIS:
;GetString muss mit RETURN beendet
;werden, da "OK" kein NULL-Byte setzt!
;			b OK         ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Bitte neuen Namen eingeben:",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "Please enter a new name:",NULL
endif
