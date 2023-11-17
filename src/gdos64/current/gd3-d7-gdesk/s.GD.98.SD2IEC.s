; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* DiskImage-Utilities

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_APPS"
			t "SymbTab_DISK"
			t "SymbTab_GRFX"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "SymbTab_KEYS"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "s.GD.20.WM.ext"
			t "e.Register.ext"

;--- Variablen für Status-Box:
:STATUS_X		= $0060
:STATUS_W		= $0080
:STATUS_Y		= $30
:STATUS_H		= $30

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_Y1		= STATUS_Y +26
endif

;*** GEOS-Header.
			n "obj.GD98"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xDIMG_RENAME		;Rename DiskImage.
			jmp	xDIMG_DELETE		;Delete DiskImage.
			jmp	xDIMG_DUPLICATE		;Duplicate DiskImage.
			jmp	xDIMG_MAKEDIR		;Create Directory.
			jmp	xDIMG_DELDIR		;Delete empty Directory.

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** Verzeichnis löschen.
:xDIMG_DELDIR		jsr	copyDImgData		;DiskImage-Daten einlesen.

			LoadW	r0,Dlg_AskDelDir
			LoadW	r5,dImgName
			jsr	DoDlgBox		;Verzeichnis löschen?

			lda	sysDBData
			cmp	#YES			;Löschen bestätigt?
			bne	:exit			; => Nein, Ende...

			jsr	doDelDirJob		;Verzeichnis löschen.

			jmp	reloadDisk		;Verzeichnis aktualisieren.
::exit			jmp	exitMod			;Ende...

;*** Verzeichnis erstellen.
:xDIMG_MAKEDIR		LoadW	r0,Dlg_DirCreate
			LoadW	r5,dImgName
			jsr	DoDlgBox		;Verzeichnisname eingeben.

			lda	sysDBData
			cmp	#CANCEL			;Abbruch?
			beq	:exit			; => Ja, Ende...

			lda	dImgName		;Name definiert?
			beq	:exit			; => Nein, Ende...

			jsr	doMakeDirJob		;Verzeichnis erstellen.

			jmp	reloadDisk		;Verzeichnis aktualisieren.
::exit			jmp	exitMod			;Ende...

;*** DiskImage löschen.
:xDIMG_DELETE		jsr	copyDImgData		;DiskImage-Daten einlesen.

			LoadW	r0,Dlg_AskDelete
			jsr	DoDlgBox		;DiskImage löschen?

			lda	sysDBData
			cmp	#YES			;Löschen bestätigt?
			bne	:exit			; => Nein, Ende...

			jsr	doDeleteJob		;DiskImage löschen.

			jmp	reloadDisk		;Verzeichnis aktualisieren.
::exit			jmp	exitMod			;Ende...

;*** DiskImage duplizieren.
:xDIMG_DUPLICATE	jsr	copyDImgData		;DiskImage-Daten einlesen.

			jsr	getDImgInfo		;Name definieren.
			cpx	#FALSE			;Fehler?
			beq	:exit			; => Ja, Abbruch...

			jsr	defaultDImgName		;Vorgabe für Namen definieren.

			lda	#TRUE			;Modus: Duplizieren.
			sta	flagDuplicate

			LoadW	RegTMenu1a +1,R1T01b
			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.
::exit			jmp	exitMod			;Ende...

;*** DiskImage/Verzeichnis umbenennen.
:xDIMG_RENAME		jsr	copyDImgData		;DiskImage-Daten einlesen.

			lda	dImgData +0
			cmp	#DIR			;Verzeichnis?
			beq	:renameDir		; => Ja, weiter...

;--- DiskImage umbenennen.
::renameFile		jsr	getDImgInfo		;Name definieren.
			cpx	#FALSE			;Fehler?
			beq	:exit			; => Ja, Abbruch...

			jsr	defaultDImgName		;Vorgabe für Namen definieren.

			lda	#FALSE			;Modus: Umbenennen.
			sta	flagDuplicate

			LoadW	RegTMenu1a +1,R1T01a
			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.
::exit			jmp	exitMod			;Ende...

;--- Verzeichnis umbenennen.
::renameDir		LoadW	r0,Dlg_DirRename
			LoadW	r5,dImgName
			jsr	DoDlgBox		;Verzeichnisname eingeben.

			lda	sysDBData
			cmp	#CANCEL			;Abbruch?
			beq	:exit			; => Ja, Ende...

			lda	dImgName		;Name definiert?
			beq	:exit			; => Nein, Ende...

			jsr	doRenDirJob		;Verzeichnis umbenennen.
			jmp	reloadDisk		; => Ende...

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			lda	exitCode		;Befehl ausführen?
			cmp	#$7f
			bne	exitMod			; => Nein, Ende...

			jsr	makeNewDImgName		;Neuen Namen erzeugen.
			cpx	#TRUE			;Name gültig?
			bne	exitMod			; => Nein, Ende...

			jsr	doDiskImgJob		;DiskImage duplizieren/umbenennen.

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
			txa				;Fehlercode zwischenspeichern.
;			pha
;			jsr	sys_LdBackScrn		;Bildschirminhalt zurücksetzen.
;			pla
;			tax				;Fehlercode wiederherstellen.
			beq	reloadDisk		; => Kein Fehler, weiter...

:doError		jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	ExitTurbo		;TurboDOS abschalten.

:reloadDisk		bit	flagReloadDir		;Verzeichnis neu laden?
			bpl	exitMod			; => Nein, weiter...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.

:exitMod		jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "X" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
			rts

;*** Flag setzen "Disk aktualisieren".
;
;Wird durch das Registermenü gesetzt
;wenn Disk-Name oder Status GEOS-Disk
;geändert wird.
;
:setReloadDir		lda	#TRUE
			sta	flagReloadDir
			rts

;*** Variablen.
:flagReloadDir		b $00				;$FF=Verzeichnis aktualisieren.

;*** Register-Menü.
:R1SizeY0		= $28
:R1SizeY1		= $8f
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

:RegMenu1a		b 1				;Anzahl Einträge.

			w RegTName1			;Register: "CMD".
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
;:RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** Icons.
:RIcon_Name		w Icon_Name
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Name_x,Icon_Name_y
			b USE_COLOR_INPUT

:Icon_Name
<MISSING_IMAGE_DATA>

:Icon_Name_x		= .x
:Icon_Name_y		= .y

;*** Daten für Register "SD2IEC".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RPos1_r  = R1SizeX1 -$24
:RTab1_1  = $0028
:RTab1_2  = $0078
:RTab1_3  = $00a0
:RTab1_4  = $0048
:RTab1_5  = $0048

:RLine1_1 = $00		;Name.
:RLine1_2 = $10		;Options
:RLine1_3 = $30		;DiskImage.
:RLine1_4 = $40		;Type/Size.

:RegTMenu1		b 10

;--- Umbenennen.
:RegTMenu1a		b BOX_FRAME
				w R1T01a
				w $0000
				b RPos1_y +RLine1_1 -$05
				b RPos1_y +RLine1_1 +$18 +$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

;--- Name.
::02			b BOX_STRING
				w R1T01
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1
				w dImgFName
				b 12
::03			b BOX_FRAME
				w $0000
				w drawImageType
				b RPos1_y +RLine1_1 -1
				b RPos1_y +RLine1_1 +8
				w RPos1_x +RTab1_1 -1
				w RPos1_x +RTab1_1 +12*8 +4*8
::04			b BOX_ICON
				w $0000
				w EXEC_REG_ROUT
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1 +12*8
				w RIcon_Name
				b NO_OPT_UPDATE

;--- Optionen.
::05			b BOX_OPTION
				w R1T04
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x
				w optSetDName
				b %10000000

::06			b BOX_OPTION
				w R1T06
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_2
				w optOpenImage
				b %10000000

;--- Info.
::07			b BOX_FRAME
				w R1T07
				w $0000
				b RPos1_y +RLine1_3 -$05
				b RPos1_y +RLine1_3 +$18 +$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08

::08			b BOX_STRING_VIEW
				w R1T05
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x +RTab1_4
				w dImgName
				b 16

::09			b BOX_STRING_VIEW
				w R1T02
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_5
				w dImgType
				b 4

::10			b BOX_NUMERIC
				w R1T03
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x +RTab1_3
				w dImgSize
				b 5!NUMERIC_RIGHT!NUMERIC_WORD

;*** Texte für Register "SD2IEC".
if LANG = LANG_DE
:R1T01a			b "UMBENENNEN",NULL
:R1T01b			b "DUPLIZIEREN",NULL
:R1T07			b "INFO",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Name:",NULL
:R1T02			w RPos1_x
			b RPos1_y +RLine1_4 +$06
			b "Image-Typ:",NULL
:R1T03			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_4 +$06
			b "Größe:",NULL
:R1T04			w RPos1_x +12
			b RPos1_y +RLine1_2 +$06
			b "Diskname anpassen",NULL
:R1T05			w RPos1_x
			b RPos1_y +RLine1_3 +$06
			b "DiskImage:",NULL
:R1T06			w RPos1_x +RTab1_2 +12
			b RPos1_y +RLine1_2 +$06
			b "Disk öffnen",NULL
endif
if LANG = LANG_EN
:R1T01a			b "RENAME",NULL
:R1T01b			b "DUPLICATE",NULL
:R1T07			b "INFO",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Name:",NULL
:R1T02			w RPos1_x
			b RPos1_y +RLine1_4 +$06
			b "Image type:",NULL
:R1T03			w RPos1_x +RTab1_2
			b RPos1_y +RLine1_4 +$06
			b "Size:",NULL
:R1T04			w RPos1_x +12
			b RPos1_y +RLine1_2 +$06
			b "Update disk name",NULL
:R1T05			w RPos1_x
			b RPos1_y +RLine1_3 +$06
			b "Disk image:",NULL
:R1T06			w RPos1_x +RTab1_2 +12
			b RPos1_y +RLine1_2 +$06
			b "Open disk",NULL
endif

;*** Daten für DiskImage kopieren.
:copyDImgData		lda	fileEntryPos
			sta	r0L

			ldx	#r0L			;Zeiger auf Eintrag
			jsr	WM_SETVEC_ENTRY		;berechnen.

			ldy	#2			;Daten für DiskImage/Verzeichnis
			ldx	#0			;einlesen.
::1			lda	(r0L),y
			sta	dImgData,x
			iny
			inx
			cpx	#30
			bcc	:1

;--- DiskImage-Name einlesen.
			ldx	#3
			ldy	#0			;Name DiskImage oder Verzeichnis
::2			lda	dImgData,x		;einlesen.
			sta	dImgNameOrig,y
			beq	:6
			bpl	:3
			cmp	#$a0			;Ende erreicht?
			beq	:6			; => Ja, weiter...

			sec				;Name nach GEOS konvertieren.
			sbc	#128
::3			cmp	#" "
			bcc	:4
			cmp	#$7f
			bcc	:5
::4			lda	#"."			;Zeichen ungültig.

::5			sta	dImgName,y
			inx
			iny
			cpy	#16
			bcc	:2

::6			lda	#NULL			;Rest des Namens mit $00 füllen.
::7			sta	dImgName,y
			sta	dImgNameOrig,y
			iny
			cpy	#16 +1
			bcc	:7

			rts

;*** DiskImage-Daten einlesen.
:getDImgInfo		lda	dImgData +28		;Sonderbehandlung für 16M-Partition
			ora	dImgData +29		;erforderlich?
			bne	:1			; => Nein, weiter...

			lda	#$ff			;Größe auf 65535 reduzieren.
			tax
			bne	:2

::1			lda	dImgData +28
			ldx	dImgData +29
::2			sta	dImgSize +0		;Partitionsgröße setzen.
			stx	dImgSize +1

;--- DiskImage-Typ einlesen.
			ldx	dImgData		;Zeiger auf Partitionstyp
			beq	:err			;berechnen.
			cpx	#5
			bcs	:err
			dex
			txa
			asl
			asl
			tax

			ldy	#0
::3			lda	dImgTypeList,x		;Partitionstyp setzen.
			sta	dImgType,y
			lda	dImgExtList,x		;Extension für DiskImage setzen.
			sta	dImgFNamExt,y
			inx
			iny
			cpy	#4
			bcc	:3

			ldx	#TRUE
			b $2c
::err			ldx	#FALSE
			rts

;*** Vorgabe für Name DiskImage definieren.
:defaultDImgName	ldy	#0
			ldx	#0
::1			lda	dImgName,x
			beq	:3
			cmp	#$a0
			beq	:2
			cmp	#"."
			beq	:2
			sta	dImgFName,y
			inx
			iny
			cpy	#12
			bcc	:1

::2			lda	#NULL
::3			sta	dImgFName,y
			iny
			cpy	#12 +1
			bcc	:3

			rts

;*** DiskImage-Typ anzeigen.
;Extension kann nicht geändert werden!
;Bei einer falschen Extension würde das
;DiskImage nicht mehr angezeigt werden.
:drawImageType		ldx	#< RPos1_r
			stx	r11L
			ldx	#> RPos1_r
			stx	r11H

			ldy	#RPos1_y +RLine1_1 +6
			sty	r1H

			lda	#< dImgFNamExt
			sta	r0L
			lda	#> dImgFNamExt
			sta	r0H

			jmp	PutString

;*** Neuen Namen für DiskImage erzeugen.
:makeNewDImgName	lda	dImgFName		;Name definiert?
			beq	:old			; => Nein, Abbruch...

			ldy	#0
			ldx	#0
::1			lda	dImgFName,y		;Dateiname übernehmen.
			beq	:2
			sta	dImgName,x
			inx
			iny
			cpy	#12
			bcc	:1

::2			ldy	#0
::3			lda	dImgFNamExt,y		;Erweiterung übernehmen.
			beq	:4
			sta	dImgName,x
			inx
			iny
			cpy	#4
			bcc	:3

			lda	#NULL
::4			sta	dImgName,x		;Ende Dateiname.

			LoadW	r0,dImgNameOrig
			LoadW	r1,dImgName
			ldx	#r0L
			ldy	#r1L
			jsr	CmpString		;Neuer Name?
			bne	:new			; => Ja, weiter...

::old			ldx	#FALSE			;Abbruch.
			b $2c
::new			ldx	#TRUE			;OK.
			rts

;*** DiskImage umbenennen/duplizieren.
:doDiskImgJob		ldy	#0			;Befehl für SD2IEC erstellen.
::1			lda	dImgName,y
			beq	:2
			sta	com_REN +2,y		;Neuer Name.
			sta	com_CD +3,y		;Verzeichnis-Befehl.
			iny
			cpy	#16
			bcc	:1

::2			lda	#"="
			sta	com_REN +2,y

			tya
			clc
			adc	#3
			sta	com_CD_len		;Länge Verzeichnis-Befehl.

			lda	#NULL
			sta	com_CD +3,y
			iny

			ldx	#0			;Alten Namen für DiskImage
::3			lda	dImgNameOrig,x		;übernehmen.
			beq	:4
			sta	com_REN +2,y
			iny
			inx
			cpx	#16
			bcc	:3

::4			lda	#NULL
			sta	com_REN +2,y

			tya
			clc
			adc	#2
			sta	com_REN_len		;Länge des Befehls speichern.

			lda	#"R"			;Modus: Umbenennen.

			bit	flagDuplicate
			bpl	:5

			jsr	msgDuplicate

			lda	#"C"			;Modus: Duplizieren.
::5			sta	com_REN +0

;--- Befehl senden.
::send			ldx	#< com_REN
			ldy	#> com_REN
			lda	com_REN_len
			jsr	sendCommand		;Befehl senden.

			jsr	queryStatus		;Fehlerstatus abfragen.
;			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			ldx	#< com_CD
			ldy	#> com_CD
			lda	com_CD_len
			jsr	sendCommand		;DiskImage öffnen.

;--- Diskname anpassen.
::rename_disk		bit	optSetDName		;Diskname/Header anpassen?
			bpl	:test_open		; => Nein, weiter...

			jsr	OpenDisk		;Diskette öffnen.
			txa
			bne	:exit

			ldx	#0			;Original Partitionsname für
::31			lda	dImgFName,x		;"R-P"-Befehl übernehmen.
			beq	:32
			cmp	#$a0
			beq	:32
			cmp	#"."
			beq	:32
			sta	curDirHead +$90,x
			inx
			cpx	#12
			bcc	:31

::32			lda	#$a0
::33			sta	curDirHead +$90,x
			inx
			cpx	#18
			bcc	:33

			jsr	PutDirHead
			txa
			bne	:exit

			jsr	OpenDisk		;Diskette erneut öffnen um den
			txa				;Disknamen zu aktualisieren.
			bne	:exit

;--- DiskImage öffnen?
::test_open		bit	optOpenImage		;DiskImage geöffnet lassen?
			bpl	:exit_image		; => Nein, weiter...

;--- SD2IEC-Browser beenden.
::exit_browser		ldx	WM_WCODE		;Image-Browser beenden.
			lda	WIN_DATAMODE,x
			and	#%10111111
			sta	drvUpdMode

			lda	#%11000000		;Fensterdaten aktualisieren,
			sta	drvUpdFlag		;andere Fenster schließen.

			lda	#NULL			;Fenster für Cache löschen.
			sta	getFileWin
			beq	:exit

;--- DiskImage verlassen.
::exit_image		ldx	#< com_CDX
			ldy	#> com_CDX
			lda	com_CDX_len
			jsr	sendCommand		;"CD<-" = DiskImage verlassen.

;--- Fenster aktualisieren.
::exit			jsr	setReloadDir		;GeoDesk: Verzeichnis neu laden.

			ldx	#NO_ERROR
::err			rts

;*** Infobox anzeigen.
:msgDuplicate		lda	#$00			;Füllmuster löschen.
			jsr	SetPattern

			jsr	i_Rectangle		;Status-Box zeichnen.
			b	STATUS_Y
			b	(STATUS_Y + STATUS_H) -1
			w	STATUS_X
			w	(STATUS_X + STATUS_W) -1

			lda	#%11111111		;Rahmen für Status-Box.
			jsr	FrameRectangle

;--- Titelzeile.
			lda	C_RegisterBack		;Farbe für Status-Box.
			jsr	DirectColor

			jsr	i_Rectangle		;Titelzeile löschen.
			b	STATUS_Y
			b	STATUS_Y +15
			w	STATUS_X
			w	(STATUS_X + STATUS_W) -1

			lda	C_DBoxTitel		;Farbe für Titelzeile setzen.
			jsr	DirectColor

			jsr	UseSystemFont

			LoadW	r0,jobInfTxCreate	;"DiskImage erstellen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxFormat		;"DiskImage wird formatiert..."
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,infoTxWait		;"Bitte etwas Geduld!"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1 +10
			jmp	PutString

;*** Texte.
if LANG = LANG_DE
:jobInfTxCreate		b PLAINTEXT,BOLDON
			b "SD2IEC"
			b PLAINTEXT,NULL

:infoTxFormat		b "DiskImage wird dupliziert...",NULL
:infoTxWait		b "Bitte etwas Geduld!",NULL
endif
if LANG = LANG_EN
:jobInfTxCreate		b PLAINTEXT,BOLDON
			b "SD2IEC"
			b PLAINTEXT,NULL

:infoTxFormat		b "Duplicating disk image...",NULL
:infoTxWait		b "Please be patient!",NULL
endif

;*** DiskImage löschen.
:doDeleteJob		ldy	#0			;Name für SD2IEC-Befehl
::1			lda	dImgName,y		;übernehmen.
			beq	:2
			sta	com_DEL +2,y
			iny
			cpy	#16
			bcc	:1

::2			tya
			clc
			adc	#2
			sta	com_DEL_len		;Länge Befehl speichern.

			ldx	#< com_DEL
			ldy	#> com_DEL
			lda	com_DEL_len		;DiskImage löschen.

;*** Befehl ausführen, Status auswerten.
:execCommand		jsr	sendCommand		;Befehl senden.

:execQuery		jsr	queryStatus		;Fehlerstatus abfragen.
;			txa				;Fehler?
			beq	:ok			; => Nein weiter...

			cpx	#$01			;FILES SCRATCHED?
			beq	:ok			; => Ja, weiter...

			LoadW	r0,Dlg_DiskStatus
			jsr	DoDlgBox		;Fehlerstatus anzeigen.

			ldx	#CANCEL_ERR		;Abbruch.
			rts

::ok			jsr	setReloadDir		;GeoDesk: Verzeichnis neu laden.

			ldx	#NO_ERROR
			rts

;*** Befehl senden.
;Übergabe: X/Y = Zeiger auf Befehl.
;          A   = Anzahl Zeichen.
:sendCommand		stx	r0L			;Zeiger auf Befehl setzen.
			sty	r0H
			sta	r2L

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	SendCommand		;Befehl senden.
			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			jmp	DoneWithIO		;I/O-Bereich abschalten.

;*** Verzeichnis umbenennen.
:doRenDirJob		ldy	#0			;Name für SD2IEC-Befehl
::1			lda	dImgName,y		;übernehmen.
			beq	:2
			sta	com_REN +2,y
			iny
			cpy	#16
			bcc	:1

::2			lda	#"="
			sta	com_REN +2,y
			iny

			ldx	#0			;Original Name übernehmen.
::3			lda	dImgNameOrig,x
			beq	:4
			sta	com_REN +2,y
			iny
			inx
			cpx	#16
			bcc	:3

::4			lda	#NULL
			sta	com_REN +2,y

			tya
			clc
			adc	#2
			sta	com_REN_len		;Länge Befehl speichern.

			ldx	#< com_REN
			ldy	#> com_REN
			lda	com_REN_len		;Verzeichnis umbenennen.

			jmp	execCommand		;Befehl senden.

;*** Neues Verzeichnis erstellen.
:doMakeDirJob		ldy	#0			;Name für SD2IEC-Befehl
::1			lda	dImgName,y		;übernehmen.
			beq	:2
			sta	com_DIR +3,y
			iny
			cpy	#16
			bcc	:1

::2			lda	#NULL
			sta	com_DIR +3,y

			tya
			clc
			adc	#3
			sta	com_DIR_len		;Länge Befehl speichern.

			lda	#"M"			;"MD" = Make Directory.
			sta	com_DIR +0

			ldx	#< com_DIR
			ldy	#> com_DIR
			lda	com_DIR_len		;Verzeichnis erstellen.

			jmp	execCommand		;Befehl senden.

;*** Leeres Verzeichnis löschen.
:doDelDirJob		ldy	#0			;Name für SD2IEC-Befehl
::1			lda	dImgName,y		;übernehmen.
			beq	:2
			sta	com_DIR +3,y
			iny
			cpy	#16
			bcc	:1

::2			lda	#NULL
			sta	com_DIR +3,y

			tya
			clc
			adc	#3
			sta	com_DIR_len		;Länge Befehl speichern.

			lda	#"R"			;"RD" = Remove Directory.
			sta	com_DIR +0

			ldx	#< com_DIR
			ldy	#> com_DIR
			lda	com_DIR_len		;Verzeichnis löschen.

			jmp	execCommand		;Befehl senden.

;*** Status einlesen.
;Rückgabe: X = Fehlerstatus.
:queryStatus		jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	#0
;			ldx	#< DRIVE_COM
;			ldy	#> DRIVE_COM
			jsr	SETNAM			;Befehl als Dateiname.

			lda	#12
			ldx	curDevice
			ldy	#15
			jsr	SETLFS			;Daten für Befehlskanal.
			jsr	OPENCHN			;Befehlskanal öffnen.

			ldx	#12			;Eingabe von Befehlskanal.
			jsr	CHKIN

			ldy	#$00
::loop			jsr	READST			;Ende erreicht?
			bne	:end			; => Ja, Ende...

			jsr	CHRIN			;Zeichen einlesen.
			cpy	#63			;Speicher voll?
			bcs	:loop			; => Ja, Zeichen ignorieren.

			sta	DRIVE_STATUS,y		;Zeichen in Puffer speichern.
			iny
			bne	:loop			; => Weiter, nächstes Zeichen...

;--- Ende Status-Meldung.
::end			lda	#NULL			;Ende Fehler-Status markieren.
			sta	DRIVE_STATUS,y

			jsr	CLRCHN			;Standard-I/O herstellen.

			lda	#12			;Befehlskanal schließen.
			jsr	CLOSE

			jsr	DoneWithIO		;I/O-Bereich abschalten.

			lda	DRIVE_STATUS +0		;Fehlerstatus von ASCII
			sec				;nach HEX wandeln.
			sbc	#"0"
;			and	#%00001111
			asl
			asl
			asl
			asl
			sta	r0L
			lda	DRIVE_STATUS +1
			sec
			sbc	#"0"
			and	#%00001111
			ora	r0L
			tax

			rts

;*** Variablen.
:flagDuplicate		b $00

;--- Bit%7=1: Diskname anpassen.
:optSetDName		b %10000000

;--- Bit%7=1: Disk öffnen.
:optOpenImage		b %00000000

;--- DiskImage-Daten.
:dImgData		s 30

;--- Name für DiskImage (16Z).
:dImgName		b NULL
			e dImgName +16 +1

;--- Name (12Z) und Extension (4Z).
:dImgFName		b "123456789012"
			e dImgFName +12 +1

:dImgFNamExt		b ".D64"
			e dImgFNamExt +4 +1

;--- Originaler Dateiname.
:dImgNameOrig		b NULL
			e dImgNameOrig +16 +1

;--- Format DiskImage.
:dImgType		b "NATM"
			e dImgType +4 +1

;--- Dateigröße DiskImage.
:dImgSize		w $ffff

;--- Liste mit DiskImage-Formaten.
:dImgTypeList		b "1541"
			b "1571"
			b "1581"
			b "NATM"
:dImgExtList		b ".D64"
			b ".D71"
			b ".D81"
			b ".DNP"

;--- Befehl: Umbenennen.
:com_REN_len		b $00
:com_REN		b "R:"
			b "1234567890123456"
			b "="
			b "1234567890123456"
			b NULL

;--- Befehl: DiskImage wechseln.
:com_CD_len		b $00
:com_CD			b "CD:"
			b "1234567890123456"
			b NULL

;--- Befehl: DiskImage löschen.
:com_DEL_len		b $00
:com_DEL		b "S:"
			b "1234567890123456"
			b NULL

;--- Befehl: Verzeichnis erstellen/löschen.
:com_DIR_len		b $00
:com_DIR		b "MD:"
			b "1234567890123456"
			b NULL

;--- Befehl: DiskImage verlassen.
:com_CDX_len		b $03
:com_CDX		b "CD",$5f
			b NULL

:DRIVE_STATUS		s 64

;*** Dialogbox: DiskImage löschen?
:Dlg_AskDelete		b %00000001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$2e
			w dImgName
			b DBTXTSTR   ,$0c,$3c
			w :4
			b DBTXTSTR   ,$0c,$46
			w :5
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das DiskImage wirklich löschen?"
			b BOLDON,NULL
::4			b PLAINTEXT
			b "Dieser Vorgang kann nicht mehr",NULL
::5			b "rückgängig gemacht werden!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Really delete this disk image?"
			b BOLDON,NULL
::4			b PLAINTEXT
			b "Deleting the disk image can",NULL
::5			b "not be undone!",NULL
endif

;*** Dialogbox: Laufwerk-Status anzeigen.
:Dlg_DiskStatus		b %00000001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$34
			w :1
			b DBTXTSTR   ,$18,$40
			w DRIVE_STATUS
			b DBTXTSTR   ,$0c,$20
			w dImgName
			b OK         ,$11,$50
			b NULL

if LANG = LANG_DE
::1			b "Laufwerk-Status:"
			b PLAINTEXT,NULL
endif
if LANG = LANG_EN
::1			b "Drive status message:"
			b PLAINTEXT,NULL
endif

;*** Dialogbox: Verzeichnis umbenennen.
:Dlg_DirRename		b %00000001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w dImgName
			b DBTXTSTR   ,$0c,$40
			w :4
			b DBGETSTRING,$30,$40 -6
			b r5L
			b 16
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "VERZEICHNIS UMBENENNEN",NULL
::2			b PLAINTEXT
			b "Neuen Namen für Verzeichnis eingeben:"
			b BOLDON,NULL
::4			b "Name:",PLAINTEXT,NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "RENAME DIRECTORY",NULL
::2			b PLAINTEXT
			b "Enter new name for the directory:"
			b BOLDON,NULL
::4			b "Name:",PLAINTEXT,NULL
endif

;*** Dialogbox: Verzeichnis erstellen.
:Dlg_DirCreate		b %00000001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$40
			w :4
			b DBGETSTRING,$30,$40 -6
			b r5L
			b 16
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "VERZEICHNIS ERSTELLEN",NULL
::2			b PLAINTEXT
			b "Neuen Namen für Verzeichnis eingeben:",NULL
::3			b "(max. 16 Zeichen)",NULL
::4			b BOLDON
			b "Name:",PLAINTEXT,NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "CREATE DIRECTORY",NULL
::2			b PLAINTEXT
			b "Enter new name for the directory:",NULL
::3			b "(max. 16 characters)",NULL
::4			b BOLDON
			b "Name:",PLAINTEXT,NULL
endif

;*** Dialogbox: Leeres Verzeichnis löschen?
:Dlg_AskDelDir		b %00000001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$2e
			w dImgName
			b DBTXTSTR   ,$0c,$3c
			w :4
			b DBTXTSTR   ,$0c,$46
			w :5
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Das Verzeichnis wirklich löschen?"
			b BOLDON,NULL
::4			b PLAINTEXT
			b "Hinweis: Nur leere Verzeichnisse",NULL
::5			b "können gelöscht werden!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Really delete this directory?"
			b BOLDON,NULL
::4			b PLAINTEXT
			b "Note: Only empty directories can",NULL
::5			b "be deleted!",NULL
endif

;*** Endadresse testen:
			g BASE_DIRDATA
;***
