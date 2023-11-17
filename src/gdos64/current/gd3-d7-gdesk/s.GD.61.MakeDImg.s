; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* SD2IEC DiskImage erstellen.

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
:STATUS_H		= $30

;--- Fortschrittsbalken.
:STATUS_CNT_X1		= STATUS_X +16
:STATUS_CNT_X2		= (STATUS_X + STATUS_W) -24 -1
:STATUS_CNT_W		= (STATUS_CNT_X2 - STATUS_CNT_X1) +1
:STATUS_CNT_Y1		= (STATUS_Y + STATUS_H) -16
:STATUS_CNT_Y2		= (STATUS_Y + STATUS_H) -16 +8 -1

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_Y1		= STATUS_Y +26
endif

;*** GEOS-Header.
			n "obj.GD61"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xCREATE_DIMG

;*** Programmroutinen.
			t "-Gxx_IBoxCore"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** DiskImage erstellen.
:xCREATE_DIMG		ldx	curDrive		;Format-Mode ermitteln.
			lda	driveType -8,x		;Dazu Laufwerksmodus einlesen und
			and	#%0000 1111		;in Option für das Register-Menü
			tay				;konvertiere.
			lda	formatModeTab,y
			sta	formatMode

			lda	#$00			;Flag löschen:
			sta	flgSlctDrvMode		;"Laufwerksmodus wechseln"

			jsr	createDiskName		;Vorgabe Name DiskImage erzeugen.

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskImage erstellen?
			cmp	#$7f
			bne	:desktop		; => Nein, Ende...

			jsr	doCreateJob		;DiskImage erstellen.

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
			beq	:done			; => Kein Fehler, weiter...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.

;--- Zurück zum DeskTop.
::done			bit	reloadDir		;Disk-Name/GEOS-Disk geändert?
			bpl	:exit			; => Nein, Ende...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.

::exit			lda	MP3_64K_DISK		;"Treiber-im-RAM" aktiv ?
			beq	:desktop		; => Nein, weiter...

			lda	flgSlctDrvMode		;Laufwerksmodus gewechselt ?
			bne	:slctDrvMode		; => Ja, weiter...

::desktop		jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

::slctDrvMode		lda	curDrive		;Laufwerk für Modusauswahl
			sta	TempDrive		;vorgeben.
			lda	dImgType		;Neuen Modus für Laufwerk
			sta	TempMode		;vorgeben.

			lda	#%00000000		;CMD/SD2IEC:
			sta	drvUpdMode		;Partition/DiskImage nicht wählen.

::update		lda	drvUpdFlag		;Laufwerksdaten aktualisieren.
			ora	#%10000000
			sta	drvUpdFlag

			lda	drvUpdMode		;SD2IEC: DiskImage-Modus festlegen.
			sta	TempPart

			jmp	MOD_NEWDRVMODE		;Laufwerksmodus ändern.

;*** Icon "X" oder "DiskImmage erstellen" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
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

			w RegTName1			;Register: "LÖSCHEN".
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

;*** Icons "Image erstellen".
:RIcon_Create		w Icon_Create
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Create_x,Icon_Create_y
			b USE_COLOR_INPUT

:Icon_Create
<MISSING_IMAGE_DATA>

:Icon_Create_x		= .x
:Icon_Create_y		= .y

:RIcon_Add64K		w Icon_Add64K
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Add64K_x,Icon_Add64K_y
			b USE_COLOR_INPUT

:Icon_Add64K
<MISSING_IMAGE_DATA>

:Icon_Add64K_x		= .x
:Icon_Add64K_y		= .y

:RIcon_Sub64K		w Icon_Sub64K
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Sub64K_x,Icon_Sub64K_y
			b USE_COLOR_INPUT

:Icon_Sub64K
<MISSING_IMAGE_DATA>

:Icon_Sub64K_x		= .x
:Icon_Sub64K_y		= .y

:RIcon_NextStd		w Icon_NextStd
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_NextStd_x,Icon_NextStd_y
			b USE_COLOR_INPUT

:Icon_NextStd
<MISSING_IMAGE_DATA>

:Icon_NextStd_x		= .x
:Icon_NextStd_y		= .y

;*** Daten für Register "DISK IMAGE".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RTab1_1  = $0050
:RTab1_2  = $0068
:RTab1_3  = $0068
:RLine1_1 = $00
:RLine1_2 = $20
:RLine1_3 = $30
:RLine1_4 = $50

:RegTMenu1		b 15

			b BOX_ICON
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_Create
				b NO_OPT_UPDATE

			b BOX_STRING
				w R1T01
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1
				w diskImgName
				b 12

			b BOX_FRAME
				w R1T02
				w $0000
				b RPos1_y +RLine1_2 -$08
				b RPos1_y +RLine1_3 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

:modeD64		b BOX_OPTION
				w R1T03
				w SlctD64
				b RPos1_y +RLine1_2
				w RPos1_x
				w formatMode
				b %00000001

:modeD71		b BOX_OPTION
				w R1T04
				w SlctD71
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_2
				w formatMode
				b %00000010

:modeD81		b BOX_OPTION
				w R1T05
				w SlctD81
				b RPos1_y +RLine1_3
				w RPos1_x
				w formatMode
				b %00000100

			b BOX_FRAME
				w R1T06
				w $0000
				b RPos1_y +RLine1_4 -$08
				b R1SizeY1 -$24 +$02
				w R1SizeX0 +$08
				w R1SizeX1 -$08

:modeDNP		b BOX_OPTION
				w R1T07
				w SlctDNP
				b RPos1_y +RLine1_4
				w RPos1_x
				w formatMode
				b %00001000

			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_4 -$01
				b RPos1_y +RLine1_4 +$08
				w RPos1_x +RTab1_3 -$01
				w R1SizeX1 -$08 -$08 +$01
			b BOX_USER
				w R1T08
				w $0000 ;printImgSize
				b RPos1_y +RLine1_4 -$01
				b RPos1_y +RLine1_4 +$08
				w RPos1_x +RTab1_3
				w R1SizeX1 -$08 -$08 -$18
			b BOX_USEROPT_VIEW
				w $0000
				w PrntCurSize
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +$07
				w RPos1_x +RTab1_3
				w R1SizeX1 -$08 -$08 -$18
			b BOX_ICON
				w $0000
				w Sub64K
				b RPos1_y +RLine1_4
				w R1SizeX1 -$08 -$08 -$18 +$01
				w RIcon_Sub64K
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w NextStd
				b RPos1_y +RLine1_4
				w R1SizeX1 -$08 -$08 -$10 +$01
				w RIcon_NextStd
				b NO_OPT_UPDATE
			b BOX_ICON
				w $0000
				w Add64K
				b RPos1_y +RLine1_4
				w R1SizeX1 -$08 -$08 -$08 +$01
				w RIcon_Add64K
				b NO_OPT_UPDATE

			b BOX_OPTION
				w R1T09
				w $0000
				b (R1SizeY1 +1) -$18
				w R1SizeX1 -$08 -$08 +$01
				w GD_COMPAT_WARN
				b %10000000

;*** Texte für Register "DISK IMAGE".
if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "DiskImage"
			b GOTOXY
			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "erstellen",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "DiskImage:"
			b GOTOXY
			w R1SizeX1 -$08 -$18
			b RPos1_y +RLine1_1 +$06
			b ".Dxx",NULL

:R1T02			b "STANDARD DISK-IMAGES",NULL

:R1T08			w RPos1_x +RTab1_3 -$40
			b RPos1_y +RLine1_4 +$06
			b "Kapazität:",NULL

:R1T09			w R1SizeX1 -$70
			b (R1SizeY1 +1) -$18 +$06
			b "Kompatibilitäts-"
			b GOTOXY
			w R1SizeX1 -$70
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "warnung zeigen",NULL
endif
if LANG = LANG_EN
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Create"
			b GOTOXY
			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "DiskImage",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "DiskImage:"
			b GOTOXY
			w R1SizeX1 -$08 -$18
			b RPos1_y +RLine1_1 +$06
			b ".Dxx",NULL

:R1T02			b "DEFAULT DISK-IMAGES",NULL

:R1T08			w RPos1_x +RTab1_3 -$40
			b RPos1_y +RLine1_4 +$06
			b "Capacity:",NULL

:R1T09			w R1SizeX1 -$68
			b (R1SizeY1 +1) -$18 +$06
			b "Compatibility"
			b GOTOXY
			w R1SizeX1 -$68
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "warning note",NULL
endif

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "D64 1541/170Kb",NULL

:R1T04			w RPos1_x +RTab1_2 +$10
			b RPos1_y +RLine1_2 +$06
			b "D71 1571/340Kb",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "D81 1581/790Kb",NULL

:R1T06			b "NATIVE MODE",NULL

:R1T07			w RPos1_x +$10
			b RPos1_y +RLine1_4 +$06
			b "DNP",NULL

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	_ext_InitIBox		;Status-Box anzeigen.
			jsr	_ext_InitStat		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont

			LoadW	r0,jobInfTxCreate	;"DiskImage erstellen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxFile		;"DiskImage:"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,newImageName
			jmp	PutString

;*** Status-Box "Formatieren" anzeigen.
:DrawFormatBox		jsr	_ext_InitIBox		;Status-Box anzeigen.

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
			b "DISKIMAGE ERSTELLEN"
			b PLAINTEXT,NULL

:infoTxFile		b "DiskImage: ",NULL
:infoTxFormat		b "DiskImage wird formatiert...",NULL
:infoTxWait		b "Bitte etwas Geduld!",NULL
endif
if LANG = LANG_EN
:jobInfTxCreate		b PLAINTEXT,BOLDON
			b "CREATING DISK IMAGE"
			b PLAINTEXT,NULL

:infoTxFile		b "DiskImage: ",NULL
:infoTxFormat		b "Formatting disk image...",NULL
:infoTxWait		b "Please be patient!",NULL
endif

;*** DiskImage erstellen.
:doCreateJob		LoadB	reloadDir,$ff		;Laufwerksinhalt neu laden.

			lda	diskImgName		;DiskImage-Name definiert?
			bne	:0			; => Ja, weiter...

			jsr	createDiskName		;Standard-Name erzeugen.

::0			ldx	#$00			;Name DiskImage kopieren.
::1			lda	diskImgName,x
			beq	:2
			sta	newImageName,x
			inx
			cpx	#12
			bcc	:1

::2			lda	#"."			;Suffix für DiskImage schreiben.
			sta	newImageName,x
			inx
			lda	#"D"
			sta	newImageName,x
			inx

			ldy	#$00			;Format-Mode in Zeiger auf
			lda	formatMode		;Datentabelle umwandeln.
::3			lsr
			bcs	:4
			iny
			iny
			bne	:3

::4			lda	dImgSuffix +0,y		;Suffix für Image-Typ einlesen und
			sta	newImageName,x		;in DiskImage-Name speichern.
			inx
			lda	dImgSuffix +1,y
			sta	newImageName,x
			inx
			lda	#NULL
			sta	newImageName,x

			tya
			lsr
			clc
			adc	#$01
			sta	dImgType		;Modus 1-4 für 1541/71/81/NM.

			lda	curType			;Wenn Modus nicht passend zum
			and	#%00000111		;aktuellen Laufwerk, dann
			eor	dImgType		;Flag setzen:
			sta	flgSlctDrvMode		;"Laufwerksmodus wechseln".

			ClrB	statusPos		;Track-Zähler löschen.
			jsr	DrawStatusBox		;Status-Box anzeigen.

			ldy	dImgType
			beq	:5
			dey				;1541-Modus?
			beq	CreateD64		; => Ja, D64 erstellen.
			dey				;1571-Modus?
			beq	CreateD71		; => Ja, D71 erstellen.
			dey				;1581-Modus?
			beq	CreateD81		; => Ja, D81 erstellen.
			dey				;Native-Modus?
			beq	CreateDNP		; => Ja, DNP erstellen.

::5			ldx	#DEV_NOT_FOUND
			rts

;*** SD2IEC DiskImage erstellen.
;Zum erstellen der DskImages wird der
;"P"-Befehl verwendet der ausserhalb
;eines DiskImages auch für Dateien
;verwendet werden kann um den Zeiger
;auf ein bestimmtes Byte zu setzen.
:CreateD64		lda	#35			;Anzahl Tracks 1541 = 35.
			bne	DoCreateDImg		;Größe in KBytes für Info-Anzeige.

:CreateD71		lda	#70			;Anzahl Tracks 1571 = 70.
			bne	DoCreateDImg		;Größe in KBytes für Info-Anzeige.

:CreateD81		lda	#80			;Anzahl Tracks 1581 = 80.
			bne	DoCreateDImg		;Größe in KBytes für Info-Anzeige.

:CreateDNP		lda	dImgSize		;Anzahl Tracks Native = Variabel.
			cmp	#2			;Größe in KBytes für Info-Anzeige.
			bcs	DoCreateDImg		; => Mehr als 2Tracks, weiter...
			lda	#2			;Mindestens 2Tracks für DNP setzen.

;*** DiskImage erstellen.
;    Übergabe: AKKU = Anzahl Tracks 1-255.
:DoCreateDImg		sta	statusMax		;Anzahl Tracks speichern.

			jsr	doSDCom_New		;Befehl für "Neues DiskImage".

			jsr	OpenDImgFile		;Neues DiskImage anlegen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	CloseDImgFile		;DiskImage schließen.

			jsr	doSDCom_Append		;Befehl für "An DiskImage anhängen".

			jsr	WriteTracks		;DiskImage mit $00-Bytes füllen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	DrawFormatBox		;"DiskImage wird formatiert..."

			jsr	doSDCom_CD		;"CD:DiskImage"
			jsr	doSDCom_NEW		;"N0:DiskImage,01"

			jsr	NewDisk			;Diskette öffnen.
							;NewDisk erforderlich um den
							;Format-Befehl abzuwarten...

;--- Hinweis:
;Wird die Disk nicht neu initialisiert
;dann erhält GEOS beim lesen der BAM
;vom SD2IEC evtl. noch Reste des
;vorherigen DiskImage mit der falschen
;Anzahl an Tracks im DiskImage.
			lda	#< initNewDisk		;Disk initialisieren, sonst BAM des
			ldx	#> initNewDisk		;vorherigen DiskImages noch aktiv.
			jsr	SendCom			;ID-Format-Befehl senden.

;HINWEIS:
;Ab hier ist das DiskImage erstellt und
;formatiert. Auch ist das DiskImage
;bereits geöffnet.
;			ldy	curDrive		;Ist erstelles DiskImage kompatibel
;			lda	driveType -8,y		;mit dem aktuellen Laufwerk?
;			and	#%0000 1111
;			cmp	dImgType
;			beq	:askopen		; => Ja, weiter...

			lda	flgSlctDrvMode		;Laufwerksmodus gewechselt ?
			beq	:askopen		; => Nein, weiter...

;HINWEIS:
;Wenn "Treiber-im-RAM" aktiv, dann kann
;der Laufwerksmodus gewechselt werden.
			lda	MP3_64K_DISK		;"Treiber-im-RAM" aktiv ?
			bne	:dimgopen		; => Ja, Laufwerksmodus wechseln.

			bit	GD_COMPAT_WARN		;Warnung anzeigen?
			bpl	:exitimg		; => Nein, weiter...

			LoadW	r0,Dlg_InfoDImgErr
			jsr	DoDlgBox		;Info: "DiskImage inkompatibel!"

;HINIWEIS:
;Ist das DiskImage aber nicht mit dem
;Laufwerk kompatibel muss ein "CD<-"
;erfolgen um das Image zu verlassen.
;GEOS kann das DiskImage ohne den
;passenden Treiber nicht nutzen.
::exitimg		lda	#< exitDImg		;DiskImage wieder verlassen.
			ldx	#> exitDImg		;Falsches Image-Format, GD.CONFIG
			jsr	SendCom			;muss manuell gestartet werden.

			lda	#%01000000		;SD2IEC:
			sta	drvUpdMode		;DiskImage auswählen.

			ldx	#NO_ERROR
			rts				;Diskettefehler anzeigen.

;--- Dialogbox: DiskImage öffnen ?
::askopen		LoadW	r0,Dlg_InfoDImgOK
			jsr	DoDlgBox		;Abfrage: "DiskImage öffnen?"
			lda	sysDBData		;Rückmeldung einlesen.
			cmp	#YES			;"JA"?
			bne	:exitimg		; => Nein, Browser-Mode.

			jsr	OpenDisk		;Aktualisiert bei NativeMode die
			txa				;Anzahl der Tracks auf Disk.
			bne	:exitimg

::dimgopen		lda	#%00000000		;SD2IEC:
			sta	drvUpdMode		;DiskImage nicht wählen.

::update		lda	drvUpdFlag		;Laufwerksdaten aktualisieren.
			ora	#%10000000
			sta	drvUpdFlag

			ldx	#NO_ERROR
::err			rts				;Diskettefehler anzeigen.

;*** DiskImage öffnen.
;Beim ersten Aufruf wird der Modus "W" = schreiben aktiviert.
;Danach wird "A" für APPEND = Anhängen verwendet.
:OpenDImgFile		lda	curDrive
			jsr	SetDevice
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			ClrB	STATUS			;Fehler-Flag löschen.

			lda	FComSDImgFLen		;Dateiname setzen.
			ldx	#< FComSDImgNm
			ldy	#> FComSDImgNm
			jsr	SETNAM
			lda	STATUS			;Fehler?
			bne	:1			; => Ja, Abbruch...

			lda	#2			;Datenkanal festlegen.
			ldx	curDrive
			ldy	#2
			jsr	SETLFS
			lda	STATUS			;Fehler?
			bne	:1			; => Ja, Abbruch...

			jsr	OPENCHN			;Datenkanal öffnen.
			bcc	:2			; => OK, kein Fehler...

::1			jsr	CloseDImgFile		;Datenkanal schließen.
			ldx	#DEV_NOT_FOUND		;Fehler/DiskImage nicht erstellt.
			rts

::2			ldx	#$02			;Ausgabekanal festlegen.
			jsr	CKOUT
			ldx	#NO_ERROR
			rts

;*** DiskImage öffnen.
:CloseDImgFile		lda	#$02			;Datenkanal schließen.
			jsr	CLOSE
			jsr	CLRCHN
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** SDImage-Befehl erzeugen.
:doSDCom_New		lda	#"W"			;Datei erstellen.
			b $2c
:doSDCom_Append		lda	#"A"			;An Datei anhängen.
			pha

			ldx	#0			;Name DiskImage kopieren.
::1			lda	newImageName,x
			beq	:2
			sta	FComSDImgFNm,x
			inx
			cpx	#16
			bcc	:1
::2			lda	#","			;",P,W/A" anhängen.
			sta	FComSDImgFNm,x
			inx
			lda	#"P"
			sta	FComSDImgFNm,x
			inx
			lda	#","
			sta	FComSDImgFNm,x
			inx
			pla
			sta	FComSDImgFNm,x
			inx
			lda	#NULL
			sta	FComSDImgFNm,x
			inx
			inx
			inx
			stx	FComSDImgFLen		;Länge Dateiname.
			rts

;*** CD-Befehl erzeugen.
:doSDCom_CD		ldx	#$00			;Name DiskImage kopieren.
::1			lda	newImageName,x
			beq	:2
			sta	cdDiskImage0,x
			inx
			cpx	#16
			bcc	:1
::2			txa				;Länge Befehl berechnen.
			clc
			adc	#3
			sta	cdDiskImage +0		;Länge Befehl speichern.
			lda	#$00
			sta	cdDiskImage +1

			lda	#< cdDiskImage
			ldx	#> cdDiskImage
			jmp	SendCom			;In DiskImage wechseln.

;*** ID-Befehl erzeugen.
:doSDCom_NEW		ldx	#$00			;Name DiskImage kopieren.
::1			lda	newImageName,x
			beq	:2
			sta	idDiskImage0,x
			inx
			cpx	#16
			bcc	:1
::2			lda	#","
			sta	idDiskImage0,x
			inx
			lda	#"0"
			sta	idDiskImage0,x
			inx
			lda	#"1"
			sta	idDiskImage0,x
			inx

			txa				;Länge Befehl berechnen.
			clc
			adc	#2
			sta	idDiskImage +0		;Länge Befehl speichern.
			lda	#$00
			sta	idDiskImage +1

			lda	#< idDiskImage
			ldx	#> idDiskImage
			jmp	SendCom			;ID-Format-Befehl senden.

;*** DiskImage mit $00-Bytes füllen.
;Zum erstellen der DiskImages wird der
;"P"-Befehl verwendet der ausserhalb
;eines DiskImages auch für Dateien
;verwendet werden kann um den Zeiger
;auf ein bestimmtes Byte zu setzen.
:WriteTracks		ldx	#$00			;"P"-Befehl initialisieren.
			stx	FCom_SetPos +2		;Bytes.
			stx	FCom_SetPos +3		;Sektoren.
			stx	FCom_SetPos +4		;Tracks.
			stx	FCom_SetPos +5		;Ungenutzt (Max. 16Mb möglich).
			inx
			stx	statusPos		;Zeiger auf Track #1.

::101			jsr	GetMaxSek		;Anzahl Sektoren / Track ermitteln.

			jsr	_ext_PrntStat		;Fortschrittsbalken aktualisieren.

			jsr	OpenDImgFile		;DiskImage-Datei öffnen.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch...

::102			inc	FCom_SetPos +3		;Byte-Zähler anpassen.
			bne	:102a
			inc	FCom_SetPos +4		;Mehr als 65536 Sektoren?
			beq	:103			; => Ja, Abbruch...
::102a			dec	curTrackSek		;Zeiger auf letztes Byte gesetzt?
			bne	:102			; => Nein, nächster Sektor.

::104			lda	#15			;"P"-Befehl an SD2IEC senden.
			ldx	curDrive
			tay
			jsr	SETLFS
			lda	#$00
			jsr	SETNAM
			jsr	OPENCHN			;Befehlskanal öffnen.

			jsr	UNTALK

			lda	curDrive		;Aktuelles Laufwerk auf Befehls-
			jsr	LISTEN			;empfang vorbereiten.

			lda	#15 ! %11110000
			jsr	SECOND			;Daten über Befehls-Kanal senden.
			ldy	#$00
::106			tya
			pha
			lda	FCom_SetPos,y
			jsr	BSOUT
			pla
			iny
			cpy	#7
			bcc	:106

			jsr	UNLSN

			lda	#15			;Befehls- und Datenkanal schließen.
			jsr	CLOSE
			jsr	CloseDImgFile

			lda	statusPos
			inc	statusPos
			cmp	statusMax		;Alle Tracks erzeugt?
			bcc	:101			; => Nein, weiter...
			jsr	_ext_PrntStat		;Fortschrittsbalken aktualisieren.
			ldx	#NO_ERROR
			rts

::103			jsr	CloseDImgFile
			ldx	#DEV_NOT_FOUND
			rts

:FCom_SetPos		b "P",$02,$00,$00,$00,$00,$0d

;*** Sektor-Anzahl für Spur-Nr. bestimmen (1541/71/81/Native).
;    Übergabe: statusPos   = Track-Adresse.
;    Rückgabe: curTrackSek = Anzahl Sektoren.
:GetMaxSek		ldx	dImgType		;Laufwerkstyp einlesen.
			beq	:102			; => 0 = Fehler.
			dex				;1541?
			beq	GetSectors		; => Ja, Sektoranzahl ermitteln.
			dex				;1571?
			beq	GetSectors		; => Ja, Sektoranzahl ermitteln.
			dex				;1581?
			bne	:101			; => Nein, weiter...

			LoadB	curTrackSek,40		;Immer 80Sek/Track.
			ldx	#NO_ERROR		;Kein Fehler.
			rts

::101			dex				;NativeMode?
			bne	:102			; => Nein, Abbruch...

			stx	curTrackSek		;Immer 256/Sek/Track.
;			ldx	#NO_ERROR		;Kein Fehler.
			rts

::102			ldx	#DEV_NOT_FOUND		;Unbekanntes Laufwerk.
			rts

;*** Sektor-Anzahl für Spur-Nr. bestimmen (1541/71).
:GetSectors		lda	statusPos		;Track = $00 ?
			beq	:101			; => Ja, Abbruch.

			ldy	dImgType		;Laufwerkstyp festlegen.
			dey				;1541-Laufwerk ?
			bne	:102			; => Nein, weiter...

			CmpBI	statusPos,36		;Track von $01 - $33 ?
			bcc	:103			; => Ja, weiter...

::101			ldx	#INV_TRACK		;Fehler "Invalid Track".
			rts				;Abbruch.

::102			dey				;1571-Laufwerk ?
			bne	:107			; => Nein, weiter...

			CmpBI	statusPos,71		;Track von $00 - $46 ?
			bcs	:101			; => Nein, Abbruch.

::103			ldy	#7			;Zeiger auf Track-Tabelle.
::104			cmp	Tracks,y		;Track > Tabellenwert ?
			bcs	:105			;Ja, max. Anzahl Sektoren einlesen.
			dey				;Zeiger auf nächsten Tabellenwert.
			bpl	:104			;Weiteruchen.
			bmi	:101			;Ungültige Track-Adresse.

::105			tya				;1571: Auf Track $01-$33 begrenzen.
			and	#%0000 0011
			tay
			lda	Sectors,y		;Anzahl Sektoren einlesen
::106			sta	curTrackSek		;und merken...

			ldx	#NO_ERROR		;"Kein Fehler"...
			rts

::107			ldx	#DEV_NOT_FOUND		;Routine wird nur bei 1541/1571
			rts				;aufgerufen. 1581/Native -> Fehler.

;*** Neuen Disknamen erzeugen.
;    Übergabe: r10 = Zeiger auf Speicher Diskname.
;Hinweis:
;Der erzeugte Name hat das Format:
; "SDIMG-hhmmss"
:createDiskName		ldx	#$00			;Prefix für neuen Namen kopieren.
::1			lda	dImgPrefix,x
			sta	diskImgName,x
			inx
			cpx	#6
			bcc	:1

::2			lda	hour			;Aktuelle Uhrzeit
			jsr	DEZ2ASCII		;in Vorgabename kopieren.
			stx	diskImgID +0
			sta	diskImgID +1
			lda	minutes
			jsr	DEZ2ASCII
			stx	diskImgID +2
			sta	diskImgID +3
			lda	seconds
			jsr	DEZ2ASCII
			stx	diskImgID +4
			sta	diskImgID +5
			rts

;*** Daten an Floppy senden.
;    Übergabe: AKKU/XREG lo/hi Zeiger auf Befehlsdaten:
;              w $xxxx = Anzahl Bytes.
;              b xx    = Befehlsbytes.
:SendCom		sta	r0L			;Zeiger auf Befehl speichern.
			stx	r0H

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	:sendcom		;Befehl senden.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;--- Befehlsbytes an Laufwerk senden.
::sendcom		jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff			;Befehlskanal #15.
			jsr	SECOND			;Sekundär-Adr. nach LISTEN senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:3			;Nein, Abbruch...

			ldy	#$01			;Zähler für Anzahl Bytes einlesen.
			lda	(r0L),y
			sta	r1H
			dey
			lda	(r0L),y
			sta	r1L
			AddVBW	2,r0			;Zeiger auf Befehlsdaten setzen.
			jmp	:2

::1			lda	(r0L),y			;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			bne	:2
			inc	r0H
::2			SubVW	1,r1			;Zähler Anzahl Bytes korrigieren.
			bcs	:1			;Schleife bis alle Bytes ausgegeben.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::3			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** DiskImage-Format wählen.
;Im RegisterMenü wird dabei immer nur
;eine Option aktiviert und die anderen
;Optionen deaktiviert.
:SlctD64		lda	#%00000001
			b $2c
:SlctD71		lda	#%00000010
			b $2c
:SlctD81		lda	#%00000100
			b $2c
:SlctDNP		lda	#%00001000
			sta	formatMode		;Neuen Format-Modus speichern.

;--- RegisterMenü-Optionen aktuelisieren.
			LoadW	r15,modeD64
			jsr	RegisterUpdate

			LoadW	r15,modeD71
			jsr	RegisterUpdate

			LoadW	r15,modeD81
			jsr	RegisterUpdate

			LoadW	r15,modeDNP
			jmp	RegisterUpdate

;*** Button invertieren und Laufwerksgröße ausgeben.
;    Übergabe: AKKU = 0: 64Kb weniger.
;                     1: 64Kb mehr.
;                     2: Stdandard-Größen.
;              Der Wert wird für das invertieren des
;              Icons verwendet.
:PrntNewSize		pha
			jsr	SetIconArea		;Icon-Bereich definieren.
			jsr	InvertRectangle		;Icon invertieren.
			jsr	PrntCurSize		;Neue Größe anzeigen.
			jsr	SCPU_Pause		;Pause...
			pla
			jsr	SetIconArea		;Icon-Bereich definieren.
			jmp	InvertRectangle		;Anzeige zurücksetzen.

;*** Laufwerksgröße ausgeben.
:PrntCurSize		lda	#$00			;Füllmuster setzem.
			jsr	SetPattern

			jsr	i_Rectangle		;Anzeigebereich löschen.
			b	RPos1_y +RLine1_4
			b	RPos1_y +RLine1_4 +$07
			w	RPos1_x +RTab1_3
			w	R1SizeX1 -$08 -$08 -$18

;--- Größe in KBytes.
			lda	dImgSize		;Anzahl Spuren in freien
			sta	r0L			;Speicher umrechnen.
			LoadB	r0H,0
			ldx	#r0L
			ldy	#6			;2^6 = 64.
			jsr	DShiftLeft		;Jede Spur = 64Kb.

			LoadB	r1H,RPos1_y +RLine1_4 +$06
			LoadW	r11,RPos1_x +RTab1_3 +$02
			lda	#%11000000
			jsr	PutDecimal

			lda	#"K"			;"Kb" ausgeben.
			jsr	SmallPutChar
			lda	#"b"
			jsr	SmallPutChar

;--- Anzahl Tracks.
			lda	dImgSize
			sta	r0L
			lda	#$00
			sta	r0H
			LoadB	r1H,RPos1_y +RLine1_4 +$06
			LoadW	r11,R1SizeX1 -$08 -$08 -$10 -$20
			lda	#%11000000
			jsr	PutDecimal

			lda	#"T"			;"T" ausgeben für "Tracks".
			jmp	SmallPutChar

;*** Grenzen für +/- Icons festlegen.
;    Übergabe: AKKU = 0: 64Kb weniger.
;                     1: 64Kb mehr.
;                     2: Stdandard-Größen.
:SetIconArea		tax

;--- Y-Position setzen.
			LoadB	r2L,RPos1_y +RLine1_4
			LoadB	r2H,RPos1_y +RLine1_4 +$07

			txa				;64Kb weniger?
			bne	:1			; => Nein, weiter...

;--- "<" / 64Kb weniger.
			LoadW	r3,R1SizeX1 -$08 -$08 -$18 +$01
			LoadW	r4,R1SizeX1 -$08 -$08 -$18 +$08
			rts

::1			dex				;64Kb mehr?
			bne	:2			; => Nein, weiter...

;--- ">" / 64Kb mehr.
			LoadW	r3,R1SizeX1 -$08 -$08 -$08 +$01
			LoadW	r4,R1SizeX1 -$08 -$08 -$08 +$08
			rts

;--- "+>" / Standardformate.
::2			LoadW	r3,R1SizeX1 -$08 -$08 -$10 +$01
			LoadW	r4,R1SizeX1 -$08 -$08 -$10 +$08
			rts

;*** DiskImage +64K.
:Add64K			ldx	dImgSize
			cpx	#$ff			;Weiterer Speicher verfügbar?
			bcc	:1			; => Ja, weiter...
			rts

::1			inx
			stx	dImgSize		;Neue Imagegröße speichern.

			lda	#1 			;Position für ">"-Icon.
			jsr	PrntNewSize		;Neue Größe anzeigen.
			jmp	SlctDNP			;DNP-Option aktivieren.

;*** DiskImage -64K.
:Sub64K			ldx	dImgSize		;Speicher weiter reduzierbar?
			cpx	#$03			;Mind 2x64K erforderlich.
			bcs	:1			; => Ja, weiter...
			rts

::1			dex
			stx	dImgSize		;Neue Größe festlegen.

			lda	#0 			;Position für "<"-Icon.
			jsr	PrntNewSize		;Neue Größe anzeigen.
			jmp	SlctDNP			;DNP-Option aktivieren.

;*** Nächste Standardgröße setzen.
:NextStd		lda	dImgSize		;Aktuelle Größe einlesen.
			cmp	#$10			; > 1Mb?
			bcs	:1			; => Ja, weiter...
			lda	#$10			;1Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::1			cmp	#$20			; > 2Mb?
			bcs	:2			; => Ja, weiter...
			lda	#$20			;2Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::2			cmp	#$40			; > 4Mb?
			bcs	:3			; => Ja, weiter...
			lda	#$40			;4Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::3			cmp	#$80			; > 8Mb?
			bcs	:4			; => Ja, weiter...
			lda	#$80			;8Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::4			cmp	#$c0			; > 12Mb?
			bcs	:5			; => Ja, weiter...
			lda	#$c0			;12Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::5			cmp	#$ff			; > 16Mb?
			bcs	:6			; => Ja, weiter...
			lda	#$ff			;16Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::6			lda	#$02			;Auf Minimum zurücksetzen.

;--- Neue größe speichern/anzeigen.
::newsize		sta	dImgSize		;Neue Imagegröße speichern.

			lda	#2 			;Position für "+"-Icon.
			jsr	PrntNewSize		;Neue Größe anzeigen.
			jmp	SlctDNP			;DNP-Option aktivieren.

;*** Variablen.
:dImgType		b $00				;Image-Modus 1/D64, 2/D71, 3/D81, 4/DNP.
:flgSlctDrvMode		b $00

;--- Name für DiskImage mit Suffix.
:newImageName		s 17

;--- Suffix für DiskImages.
:dImgSuffix		b "647181NP"

;--- Standard max. 6Zeichen +Uhrzeit.
:dImgPrefix		b "SDIMG-",NULL

;--- Name für DiskImage ohne Suffix.
:diskImgName		b "SDIMG-"
:diskImgID		b "xxxxxx"
			b NULL

;--- Format-Modus für Register-Menü.
:formatMode		b %00000100			;%00000001 D64
							;%00000010 D71
							;%00000100 D81
							;%00001000 DNP
:formatModeTab		b %0000 0100			;???
			b %0000 0001			;D64
			b %0000 0010			;D71
			b %0000 0100			;D81
			b %0000 1000			;DNP
			b %0000 0100			;???
			b %0000 0100			;???
			b %0000 0100			;???

;--- NativeMode:
;    Gewählte DiskImage-Größe.
:dImgSize		b $40

;--- Datei erstellen/anhängen.
:FComSDImgFLen		b $00
:FComSDImgNm		b $40,"0:"
:FComSDImgFNm		b "1234567890123456"
			b ",P,W",NULL

;--- DiskImage öffnen.
:cdDiskImage		w $0000
			b "CD:"
:cdDiskImage0		s 17

;--- DiskImage formatieren.
:idDiskImage		w $0000
			b "N:"
:idDiskImage0		b "1234567890123456"
			b ",01"
			b NULL

;--- BAM aktualisieren.
:initNewDisk		w $0004
			b "I0:",CR

;--- DiskImage verlassen.
:exitDImg		w $0003
			b "CD",$5f

;*** Tabelle mit Tracks, bei denen ein Wechsel der
;    Sektoranzahl/Track stattfindet.
:Tracks			b $01,$12,$19,$1f,$24,$35,$3c,$42
:Sectors		b $15,$13,$12,$11
:curTrackSek		b $00				;Anzahl Sektoren für aktuellen Track.

;*** Info: DiskImage erstellt, öffnen?
:Dlg_InfoDImgOK		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w newImageName
			b DBTXTSTR   ,$0c,$40
			w :4
			b YES        ,$01,$50
			b NO         ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "DiskImage erfolgreich erstellt!",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Das erstellte DiskImage öffnen?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Disk image successfully created!",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Open the created disk image?",NULL
endif

;*** Info: DiskImage erstellt, nicht kompatibel!
:Dlg_InfoDImgErr	b %01100001
			b $30,$9f
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$30
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b DBTXTSTR   ,$0c,$48
			w :5
			b DBTXTSTR   ,$0c,$52
			w :6
			b OK         ,$01,$58
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT,BOLDON
			b "DiskImage erfolgreich erstellt!",NULL
::3			b PLAINTEXT
			b "Das erstellte DiskImage ist nicht mit",NULL
::4			b "dem Laufwerk kompatibel!",NULL
::5			b "GD.CONFIG starten und Laufwerk ändern",NULL
::6			b "oder 'Treiber-in-RAM' aktivieren.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT,BOLDON
			b "Disk image successfully created!",NULL
::3			b PLAINTEXT
			b "The created disk image is not",NULL
::4			b "compatibel with the current drive!",NULL
::5			b "Open GD.CONFIG and change disk drive",NULL
::6			b "or enable 'Load drivers into RAM'.",NULL
endif

;*** Endadresse testen:
			g RegMenuBase
;***
