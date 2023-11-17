; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Validate.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CXIO"
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

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_Y1		= STATUS_Y +52
:INFO_Y2		= STATUS_Y +26
:INFO_Y3		= STATUS_Y +36
endif

;*** GEOS-Header.
			n "obj.GD64"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xVALIDATE
			jmp	xRECOVERY
			jmp	xPURGEFILES

;*** Programmroutinen.
			t "-Gxx_ClearBAM"		;BAM auf Disk löschen.

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** Diskette aufräumen.
:xVALIDATE		ldy	#$00			;NativeMode-Verz. nicht testen.
			ldx	curDrive		;Aktuelles Laufwerk einlesen.
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen und
			sta	curDrvMode		;zwischenspeichern.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1
			dey				;NativeMode-Verz. testen.
::1			sty	ChkNMSubD		;SubDir-Option festlegen.
			tya
			bne	:2

			lda	#BOX_OPTION_VIEW	;SubDir-Option bei nicht-Native
			b $2c				;Laufwerken deaktivieren.
::2			lda	#BOX_OPTION		;SubDir-Option aktivieren.
			sta	RegTMenu1a

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskCopy ausführen?
			cmp	#$7f
			bne	:exit			; => Nein, Ende...

			jsr	doValidateJob		;Diskette aufräumen.

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

			cpx	#$fe			;Abbruch durch Anwender?
			beq	:cancel

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jmp	:done			;Verzeichnis neu laden.

;--- Abbruch durch Anwender.
::cancel		LoadW	r0,Dlg_CancelMsg
			jsr	DoDlgBox		;Abbruch-Hinweis ausgeben.

;--- Zurück zu GeoDesk.
::done			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::exit			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "VALIDATE" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
			rts

;*** Register-Menü "VALIDATE".
:R1SizeY0 = $28
:R1SizeY1 = $a7
:R1SizeX0 = $0028
:R1SizeX1 = $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "VALIDATE".
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

;*** Icons "OK"/"Abbruch".
:RIcon_Validate		w Icon_Validate
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Validate_x,Icon_Validate_y
			b USE_COLOR_INPUT

:Icon_Validate
<MISSING_IMAGE_DATA>

:Icon_Validate_x	= .x
:Icon_Validate_y	= .y

;*** Daten für Register "VALIDATE".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$18
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $38

:RegTMenu1		b 6

			b BOX_ICON
				w R1T01
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_Validate
				b NO_OPT_UPDATE

			b BOX_FRAME
				w R1T02
				w $0000
				b RPos1_y -$08
				b R1SizeY1 -$24 +$02
				w R1SizeX0 +$08
				w R1SizeX1 -$08

:RegTMenu1a		b BOX_OPTION
				w R1T03
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x
				w ChkNMSubD
				b %11111111

			b BOX_OPTION
				w R1T04
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x
				w ChkFileSize
				b %11111111

			b BOX_OPTION
				w R1T05
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x
				w KillErrorFile
				b %11111111

			b BOX_OPTION
				w R1T06
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x
				w CloseFiles
				b %11111111

;*** Texte für Register "VALIDATE".
if LANG = LANG_DE
:R1T00			b "AKTIONEN",NULL

:R1T01			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Diskette"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "überprüfen",NULL

:R1T02			b "OPTIONEN",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_1 +$06
			b "Verzeichnis-Header überprüfen",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Dateigröße korrigieren",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Beschädigte Dateien löschen"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$0f
			b "Vorgang abbrechen mit RUN/STOP",NULL

:R1T06			w RPos1_x +$10
			b RPos1_y +RLine1_4 +$06
			b "Geöffnete Dateien schließen",NULL
endif
if LANG = LANG_EN
:R1T00			b "ACTIONS",NULL

:R1T01			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Validate"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "disk/drive",NULL

:R1T02			b "OPTIONS",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_1 +$06
			b "Check directory headers",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Fix wrong file size",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Delete corrupt files"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$0f
			b "Cancel operation with RUN/STOP",NULL

:R1T06			w RPos1_x +$10
			b RPos1_y +RLine1_4 +$06
			b "Close files marked as `in use`",NULL
endif

;*** Status-Box anzeigen.
:DrawStatusBox		lda	#$00			;Füllmuster löschen.
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

			jsr	UseSystemFont		;GEOS-Font für Titel aktivieren.

			LoadW	r0,jobInfTxValid	;"Diskette überprüfen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxFile		;"Datei"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y3
			jsr	PutString

			LoadW	r0,txtStatusOK		;"Status: OK"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jmp	PutString

;*** Aktuelle Datei ausgeben.
;Hinweis:
;r5 darf nicht verändert werden.
:updateStatus		jsr	DoneWithIO		;I/O-Bereich ausblenden.

			lda	r5L			;Zeiger auf Dateiname.
			pha
			clc
			adc	#$03
			sta	r8L
			lda	r5H
			pha
			adc	#$00
			sta	r8H

			LoadW	r0,curFileName		;Zeiger auf Speicher für Dateiname.

			ldx	#r8L
			ldy	#r0L
			jsr	SysCopyName		;Dateiname kopieren.

			lda	#$00			;Anzeigebereich löschen.
			jsr	SetPattern

			jsr	i_Rectangle
			b	INFO_Y3 -6
			b	INFO_Y3 +1
			w	INFO_X0
			w	(STATUS_X + STATUS_W) -8

			LoadW	r0,curFileName
			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y3
			jsr	smallPutString		;Dateiname anzeigen.

			PopB	r5H			;Zeiger auf Verzeichnis-Eintrag
			PopB	r5L			;wieder zurücksetzen.

			jmp	InitForIO		;I/O-Bereich einblenden.

;*** Disk-/Verzeichnisname ausgeben.
:prntDiskInfo		lda	#$00			;Anzeigebereich Diskname löschen.
			jsr	SetPattern

			jsr	i_Rectangle
			b	INFO_Y2 -6
			b	INFO_Y2 +1
			w	STATUS_X +8
			w	(STATUS_X + STATUS_W) -8

			ldx	#< infoTxDisk		;"Diskette"
			ldy	#> infoTxDisk

			lda	curDrvMode		;Laufwersmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode-Laufwerk?
			beq	:2			; => Nein, weiter...

			lda	curDirHead +32		;ROOT-Verzeichnis?
			ora	curDirHead +33
			cmp	#$01
			beq	:2			; => Ja, weiter...

			ldx	#< infoTxDir		;"Verzeichnis"
			ldy	#> infoTxDir

::2			stx	r0L
			sty	r0H
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y2
			jsr	PutString

			ldx	#r1L			;Zeiger auf Diskname setzen.
			jsr	GetPtrCurDkNm

			LoadW	r0,curDiskName		;Diskname in Zwischenspeicher
			ldx	#r1L			;kopieren.
			ldy	#r0L
			jsr	SysCopyName

			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y2
			LoadW	r0,curDiskName
			jmp	smallPutString		;Disk-/Verzeichnisname ausgeben.

;*** Texte.
if LANG = LANG_DE
:jobInfTxValid		b PLAINTEXT,BOLDON
			b "LAUFWERK ÜBERPRÜFEN"
			b PLAINTEXT,NULL

:infoTxFile		b "Datei: ",NULL
:infoTxDir		b "Verzeichnis: ",NULL
:infoTxDisk		b "Diskette: ",NULL
endif
if LANG = LANG_EN
:jobInfTxValid		b PLAINTEXT,BOLDON
			b "VALIDATE DRIVE"
			b PLAINTEXT,NULL

:infoTxFile		b "Filename: ",NULL
:infoTxDir		b "Directory: ",NULL
:infoTxDisk		b "Disk: ",NULL
endif

;*** DiskName für StatusBox.
:curDiskName		s 17

;*** Diskette validieren.
:doValidateJob		lda	#$00
			sta	ErrorFiles		;Anzahl gelöschter Dateien = $00.

			jsr	DrawStatusBox		;Statusbox vorbereiten.

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

:StartValid2		lda	curDrvMode		;Laufwersmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Kein NativeMode, weiter...

			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			txa				;Diskettenfehler ?
			bne	:3			; => Ja, Abbruch.
			beq	:2			; => Nein, weiter...

::1			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:3			; => Ja, Abbruch.

::2			jsr	ClearBAM		;Leere BAM im Speicher erzeugen.
			txa				;Diskettenfehler ?
			beq	StartValidDsk		; => Nein, weiter...

::3			rts				;Diskettenfehler, Ende...

;*** Verzeichnis validieren.
:StartValidDsk		jsr	prntDiskInfo		;Diskname ausgeben.

			lda	curDrvMode		;Laufwersmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			bit	ChkNMSubD		;Verzeichnis-Header prüfen?
			bpl	:1			; => Nein, weiter...
			jsr	VerifyNMDir		;Verzeichnis-Header prüfen.

::1			jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Diskettenfehler?
			beq	:2
			rts

::2			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk
::3			jsr	ValidateDir		;Verzeichnis-Sektor in BAM belegen.
			txa				;Diskettenfehler ?
			bne	:4			; => Ja, Abbruch.

			lda	fileHeader+1		;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Sektor richten.
			lda	fileHeader+0
			sta	r1L
			bne	:3			;Nächsten Sektor belegen.

			LoadW	r5,curDirHead
			jsr	ChkDkGEOS
			bit	isGEOS			;GEOS-Diskette ?
			bpl	:5			;Nein, weiter...

			lda	curDirHead+172		;Zeiger auf Borderblock richten.
			sta	r1H
			lda	curDirHead+171
			sta	r1L			;Borderblock verfügbar ?
			beq	:5			;Nein, weiter...

			jsr	ValidateDir		;Borderblock belegen.
			txa				;Diskettenfehler ?
			beq	:5			;Nein, weiter...

;--- Diskettenfehler, Abbruch zum DeskTop.
::4			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			cpx	#$fe			;Abbruch durch Anwender?
			beq	:exit			; => Ja, Ende...
			cpx	#$ff			;Neustart?
			bne	:exit			; => Nein, Ende...

			jsr	SCPU_Pause		;3sec. Pause.
			jsr	SCPU_Pause		;(Funktioniert nicht unter VICE
			jsr	SCPU_Pause		; im WARP-Modus!)

			jsr	DrawStatusBox		;Statusbox vorbereiten.

			jmp	StartValid2		;Validate erneut starten.

;--- Unterverzeichnisse aufräumen.
::5			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			jsr	PutDirHead		;BAM auf Diskette schreiben.

			lda	curDrvMode		;Laufwersmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:7			; => Nein, weiter...

			jsr	ValidSDir		;Unterverzeichnisse validieren.
			txa				;Diskettenfehler ?
			bne	:exit			; => Nein, weiter...

;--- Ende, BAM im Speicher aktualisieren.
::7			jsr	OpenDisk		;Disk öffnen, Ende.
::exit			rts

;*** Unterverzeichnisse Validieren.
:ValidSDir		lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk

			LoadW	r4,fileHeader		;Zeiger auf Zwischenspeicher.
::101			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:105			; => Ja, Abruch.

			ldy	#$02
::102			lda	fileHeader,y		;Dateityp einlesen.
			and	#ST_FMODES		;Dateityp-Flag isolieren.
			cmp	#DIR			;Verzeichnis ?
			beq	:107			; => Ja, Verzeichnis validieren.

::103			tya				;Zeiger auf nächsten Eintrag.
			clc
			adc	#$20
			tay				;Letzter Eintrag überprüft ?
			bcc	:102			;Nein, weiter...

			lda	fileHeader+1		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	fileHeader+0
			sta	r1L			;Ende erreicht ?
			bne	:101			;Nein, weiter...

::104			ldx	curDirHead+$22		;Hauptverzeichnis ?
			ldy	curDirHead+$23
			cpx	#$00
			bne	:106			;Nein, zum vorherigen Verzeichnis.
			cpy	#$00
			bne	:106			;Nein, zum vorherigen Verzeichnis.

			ldx	#$00			; => Ja, Ende...
::105			rts

;*** Übergeordnetes Verzeichnis öffnen.
::106			lda	curDirHead+$24		;Zeiger auf PARENT-Spur merken.
			pha
			lda	curDirHead+$25		;Zeiger auf PARENT-Sektor merken.
			pha
			lda	curDirHead+$26		;Zeiger auf PARENT-Eintrag merken.
			pha
			txa				;Zeiger auf neuen Verzeichniszweig
			pha				;zwischenspeichern.
			tya
			pha
			jsr	PutDirHead		;BAM speichern.
			pla
			sta	r1H
			pla
			sta	r1L
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			pla				;Zeiger auf PARENT-Eintrag
			sta	:106a +1 		;wiederherstellen.
			pla
			sta	r1H
			pla
			sta	r1L

			txa				;Diskettenfehler ?
			bne	:105			; => Ja, Abruch.

			LoadW	r4,fileHeader
			jsr	GetBlock		;PARENT-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:105			; => Ja, Abruch.
::106a			ldy	#$ff
			jmp	:103			;Zeiger auf nächsten Eintrag.

;*** Neues Unterverzeichnis öffnen.
::107			tya
			pha
			jsr	PutDirHead
			pla
			tay
			lda	fileHeader+1,y
			sta	r1L
			lda	fileHeader+2,y
			sta	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Diskettenfehler ?
			bne	:108			; => Ja, Abruch.

			jsr	prntDiskInfo		;Verzeichnisname ausgeben.

			jsr	ValSDirChain		;Verzeichniszweig validieren.
			txa				;Diskettenfehler ?
			bne	:108			;Nein, weiter...
			jmp	ValidSDir		;Dateien im Verzeichnis validieren.
::108			rts				; => Ja, Abbruch.

;*** Verzeichniszweig validieren.
:ValSDirChain		jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch....

			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk
::101			jsr	ValidateDir		;Verzeichnis-Sektor in BAM belegen.
			txa				;Diskettenfehler?
			bne	:102			; => Ja, Abbruch.

			lda	fileHeader+1		;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Sektor richten.
			lda	fileHeader+0
			sta	r1L
			bne	:101			;Nächsten Sektor belegen.
::102			jmp	DoneWithIO		;I/O-Bereich ausblenden.
::103			rts

;*** Alle Dateien im aktuellen Verzeichnis-Sektor belegen.
;    Übergabe: r1 = Tr/Se für Verzeichnis-Sektor.
:ValidateDir		MoveB	r1L,curDirSek +0	;Zeiger auf Track/Sektor merken.
			MoveB	r1H,curDirSek +1
			LoadW	r4,fileHeader		;Dir_Sektor einlesen.
			jsr	ReadBlock
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	r4L			;Zeiger auf Dateityp erzeugen.
			clc
			adc	#2
			sta	r5L
			lda	r4H
			adc	#00
			sta	r5H

::101			bit	KillErrorFile		;Defekte Datei automatisch löschen?
			bpl	:100			; => Nein, weiter...

			php				;Tastaturabfrage:
			sei				;RUN/STOP für "Validate beenden"
			ldx	CPU_DATA		;gedrückt ?
			lda	#$35
			sta	CPU_DATA
			ldy	#%01111111
			sty	cia1base +0
			ldy	cia1base +1
			stx	CPU_DATA
			plp

			cpy	#%01111111		;Validate abbrechen?
			beq	:cancel			; => Ja, Ende...

::100			ldy	#0			;Dateityp einlesen.
			lda	(r5L),y			;Datei korrekt geschlossen ?
			bmi	:103			; => Ja, weiter...
			beq	:102			;Gelöschte Datei ? -> Übergehen.

			bit	CloseFiles		;Dateien schließen ?
			bpl	:102			;Nein, -> löschen.
			ora	#%10000000		;"Closed"-Bit setzen.
			sta	(r5L),y
			jmp	:103

;--- Geöffnete Datei löschen.
::102			lda	#$00			;Eintrag löschen, da geöffnete
			tay				;Datei ggf. beschädigt.
			sta	(r5L),y
			jmp	:105

;--- Dateityp auswerten.
::103			ldy	#22
			lda	(r5L),y			;GEOS-Filetyp einlesen.
			cmp	#TEMPORARY		;TEMPORARY?
			beq	:102			; => Ja, löschen...

::104			jsr	updateStatus		;Aktuelle Datei ausgeben.

			jsr	ValidateFile		;Datei validieren.
			txa				;Diskettenfehler ?
			beq	:105			; => Nein, weiter...

;--- Datei Defekt, Fehlerbehandlung.
			jsr	infoBadFile		;Hinweis: Datei beschädigt.

			bit	KillErrorFile		;Defekte Datei automatisch löschen?
			bpl	:exit			; => Nein, weiter...

			ldy	#$00			;Dateieintrag löschen.
			tya
			sta	(r5L),y

			jsr	:writeDirSek		;Verzeichnis-Sektor schreiben.
			txa				;Disk-/Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...

			inc	ErrorFiles		;Anzahl defekter Dateien +1.

			ldx	#$ff			;Validate wiederholen.
			b $2c
::cancel		ldx	#$fe			;Abbruch durch Anwender.
::exit			rts

;--- Weiter mit nächstem Eintrag.
::105			lda	r5L			;Zeiger auf nächsten Dir_Eintrag.
			clc
			adc	#32
			sta	r5L
			bcs	:writeDirSek
			jmp	:101

;--- Verzeichnis-Sektor auf Disk speichern.
::writeDirSek		MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor einlesen.
			MoveB	curDirSek +1,r1H
			LoadW	r4,fileHeader		;Zeiger auf Dir_Sektor.
			jsr	WriteBlock		;Sektor schreiben.
			txa
			bne	:exit
			jmp	VerWriteBlock		;Sektor-Verify.

;*** Einzelne Datei validieren.
; r1 - Tr/Se für aktuellen Verzeichnis-Sektor.
; r5 - Zeiger auf den Directory-Eintrag
;      (wird aktualisiert)
:ValidateFile		lda	#0
			sta	r2L			;Zähler für belegte Blöcke
			sta	r2H			;löschen.

			ldy	#22
			lda	(r5L),y			;GEOS-Filetyp einlesen.
			beq	:104			;$00 = "nicht GEOS" ? Ja, weiter...

			ldy	#19			;Zeiger auf Track/Sektor Info-Block.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			jsr	AllocChain		;Info-Block belegen.
			txa				;Diskettenfehler ?
			bne	:107			; => Ja, Abbruch.

			jsr	readCurDirSek		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:107			; => Ja, Abbruch.

			ldy	#21
			lda	(r5L),y			;Dateistruktur einlesen.
			beq	:104			;$00 = Seq ? Ja, weiter...

;--- VLIR-Dateien.
;    VLIR-Header einlesen und alle VLIR-Datensätze
;    in der BAM als belegt kennzeichnen.
			ldy	#1			;Zeiger auf Tr/Se VLIR-Header.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			LoadW	r4,fileTrScTab
			jsr	ReadBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:107			; => Ja, Abbruch.

			ldy	#2			;Zeiger auf ersten VLIR-Datensatz.
::101			tya				;Wurden bereits alle 254 VLIR-
			beq	:104			;Datensätze belegt ? yReg = $00/Ja!

			lda	fileTrScTab,y		;Startadresse Track/Sektor des VLIR-
			sta	r1L			;Datensatzes nach ":r1" kopieren.
			iny
			ldx	fileTrScTab,y
			stx	r1H

			iny
			lda	r1L			;VLIR-Datensatz vorhanden ?
			beq	:103			;Nein, weiter...

::102			tya				;yReg sichern.
			pha
			jsr	AllocChain		;VLIR-Datensatz belegen.
			pla
			tay				;yReg zurücksetzen.
			txa				;Diskettenfehler ?
			bne	:107			; => Ja, Abbruch.
			beq	:101			;Nein, nächsten Datensatz belegen.

::103			txa				;Sektor = $FF ? Datensatz übergehen.
			bne	:101			;Sektor = $00 ? Vorzeitig beenden.

;--- Datensatz belegen.
;    VLIR = Nur VLIR-Header belegen.
;    SEQ  = Datei belegen.
::104			jsr	readCurDirSek		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:107			; => Ja, Abbruch.

			ldy	#1			;Zeiger auf Tr/Se Startsektor.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			jsr	AllocChain		;Datei belegen.
			txa				;Diskettenfehler ?
			bne	:107			; => Ja, Abbruch.

;--- Dateigröße korrigieren.
::105			jsr	readCurDirSek		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:107			; => Ja, Abbruch.

			bit	ChkFileSize		;Dateilänge korrigieren ?
			bpl	:106			;Nein, weiter...

			ldy	#28			;Anzahl der belegten Sektoren in
			lda	r2L			;Dateieintrag kopieren.
			sta	(r5L),y
			iny
			lda	r2H
			sta	(r5L),y

::106			ldx	#0
::107			rts

;*** Track/Sektor aus Dateieintrag einlesen.
:CopySekAdr		lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			rts

;*** Verzeichnis-Sektor einlesen.
:readCurDirSek		MoveB	curDirSek +0,r1L
			MoveB	curDirSek +1,r1H
			LoadW	r4,diskBlkBuf
			jmp	ReadBlock		;Verzeichnis-Sektor einlesen.

;*** Unterverzeichnis-Header überprüfen.
;Version #2: Prüft das gesamte Verzeichnis.
:VerifyNMDir		jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:99			; => Ja, Abbruch...

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#$00			;Verzeichnis-Ebene zurücksetzen.
			stx	DirLevel
			txa
			sta	DirParentTr,x		;Tabelle mit Verzeichns-Daten
			sta	DirParentSe,x		;initialisieren.
			sta	DirEntryTr ,x
			sta	DirEntrySe ,x
			sta	DirEntryByt,x
			inx				;Zeiger auf ersten Verzeichnis-
			txa				;Sektor (ROOT) setzen.

;--- Neues Verzeichnis beginnen.
::98			ldy	DirLevel		;Start-Sektor in Tabelle schreiben.
			sta	DirRootTr  ,y		;$01/$01 bei ROOT, sonst Header für
			sta	r1L			;aktuelles Unterverzeichnis.
			txa
			sta	DirRootSe  ,y
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf Datenspeicher.
			jsr	ReadBlock		;Header-Sektor einlesen.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch...

			lda	diskBlkBuf +0		;Zeiger auf ersten vVerzeichnis-
			ldx	diskBlkBuf +1		;Sektor einlesen.

;--- Verzeichnis-Sektoren einlesen.
::101			sta	r1L			;Verzeichnis-Sektor setzen.
			stx	r1H
			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler?
			beq	:102			; => Nein, weiter...
::100			jsr	DoneWithIO		;I/O-Bereich ausblenden.
::99			rts				;Diskettenfehler ausgeben.

;--- Verzeichnis-Einträge überprüfen.
::102			ldy	#$02
			lda	(r4L),y			;Dateityp einlesen.
			beq	:103			; => $00, keine Datei.
			and	#ST_FMODES
			cmp	#DIR			;Typ "Verzeichnis"?
			bne	:103			; => Nein, weiter...

			ldx	#FULL_DIRECTORY		;Fehler: "Full directory?"
			ldy	DirLevel		;Level-Zähler erhöhen.
			cpy	#15			;Max. Schachteltiefe erreicht?
			beq	:99			; => Ja, Fehler...
			iny				;Verschachtelung +1.
			sty	DirLevel		;(In Unterverzeichnis wechseln)
			jsr	UpdateHeader		;Verzeichnis-Header aktualisieren.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch...

			ldx	r1H			;Zeiger auf neuen Verzeichnis-Header
			lda	r1L			;einlesen. Ende erreicht?
			bne	:98			; => Nein, neues Verz. beginnen.
			beq	:104			; => Verzeichnis-Ende erreicht.

::103			clc				;Zeiger auf nächsten Eintrag.
			lda	r4L
			adc	#$20
			sta	r4L			;Sektor-Ende erreicht?
			bne	:102			; => Nein, weiter...

			ldx	diskBlkBuf +1		;Nächsten Sektor einlesen.
			lda	diskBlkBuf +0		;Letzter Verzeichnis-Sektor?
			bne	:101			; => Nein, weiter...

::104			ldx	DirLevel		;ROOT-Verzeichnis?
			beq	:106			; => Ja, Ende...

			lda	DirEntryTr ,x		;Zeiger auf letzte Position im
			sta	r1L			;Eltern-Verzeichnis setzen.
			lda	DirEntrySe ,x
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	ReadBlock		;Sektor wieder einlesen.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch.
			ldx	DirLevel		;Zeiger auf zuletzt geprüften
			lda	DirEntryByt,x		;Verzeichnis-Eintrag.
			sta	r4L
			dec	DirLevel		;Verschachtelung -1.
			jmp	:103			;Verzeichnis weiter testen.

::106			jmp	DoneWithIO		;I/O-Bereich ausblenden, Ende...

;*** Verzeichnis-Header einlesen und anpassen.
:UpdateHeader		ldx	DirLevel		;Zeiger auf Datentabelle einlesen.
			dex
			lda	DirRootTr  ,x		;Header vorheriges Verzeichnis
			inx				;als Zeiger auf Eltern-Verzeichnis
			sta	DirParentTr,x		;setzen.
			dex
			lda	DirRootSe  ,x
			inx
			sta	DirParentSe,x

			lda	r1L			;Position im Eltern-Verzeichnis
			sta	DirEntryTr ,x		;für aktuelles Verzeichnis merken.
			lda	r1H
			sta	DirEntrySe ,x
			lda	r4L
			sta	DirEntryByt,x

			ldy	#$03
			lda	(r4L),y			;Track/Sektor für neuen
			sta	r1L			;Verzeichnis-Header setzen.
			iny
			lda	(r4L),y
			sta	r1H
			LoadW	r4,fileHeader		;Zeiger auf Zwischenspeicher.
			jsr	ReadBlock		;Verzeichnis-Header einlesen.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			lda	r1L			;Tr/Se für Header des aktuellen
			sta	fileHeader +32		;Verz. in Header übertragen.
			lda	r1H
			sta	fileHeader +33

			ldx	DirLevel		;Track/Sektor für Header des Eltern-
			lda	DirParentTr,x		;Verz. in Header übertragen.
			sta	fileHeader +34
			lda	DirParentSe,x
			sta	fileHeader +35

			lda	DirEntryTr ,x		;Zeiger auf zugehörigen Eltern-
			sta	fileHeader +36		;Verzeichnis-Sektor in Header
			lda	DirEntrySe ,x		;übertragen.
			sta	fileHeader +37
			lda	DirEntryByt,x		;Zeiger auf Verzeichnis-Eintrag
			clc				;in Header übertragen.
			adc	#$02			;(Byte zeigt auf Byte#0=Dateityp).
			sta	fileHeader +38

			jmp	WriteBlock		;Verzeichnis-Header schreiben.
::101			rts

;*** Meldung ausgeben: Datei beschädigt!
;Hinweis:
;XReg und r5 nicht verändern.
:infoBadFile		txa				;Fehlercode und Zeiger auf
			pha				;Verzeichnis-Eintrag sichern.
			PushW	r5

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,txtDeleteInfo	;"Datei beschädigt..."
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,curFileName
			jsr	PutString		;Dateiname anzeigen.

			jsr	InitForIO		;I/O-Bereich einblenden.

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag und
			pla				;Fehlercode zurücksetzen.
			tax
			rts

;*** Aktuelle Datei.
:curFileName		s 17

;*** Zwischenspeicher Verzeichnis-Sektor.
:curDirSek		b $00,$00

;*** Texte.
:txtStatusOK		b "Status: OK",NULL
if LANG = LANG_DE
:txtDeleteInfo		b "Datei beschädigt: ",NULL
endif
if LANG = LANG_EN
:txtDeleteInfo		b "File is corrupt: ",NULL
endif

;*** Variablen.
:ErrorFiles		b $00				;Anzahl defekter Dateien.
:ChkNMSubD		b $00				;Unterverzeichnis-Header prüfen.
:ChkFileSize		b $ff				;Dateilängen korrigieren.
:KillErrorFile		b $00				;Defekte Dateien löschen.
:CloseFiles		b $ff				;$FF = Dateien schließen.
:curDrvMode		b $00				;RealDrvMode.

;*** Verzeichnisse prüfen.
:DirLevel		b $00
:DirRootTr		s 16
:DirRootSe		s 16
:DirParentTr		s 16
:DirParentSe		s 16
:DirEntryTr		s 16
:DirEntrySe		s 16
:DirEntryByt		s 16

;*** Gelöschte Dateien wieder herstellen.
:xRECOVERY		lda	#$00
			sta	updateDir		;Verzeichnis-Update zurücksetzen.
			sta	filesRecovered		;Anzahl Dateien zurücksetzen.
			sta	recoveryError		;Anzahl Fehler zurücksetzen.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:findfile		; => Ja, weiter...
			jmp	:cancel			;Ende...

;--- Zeiger auf Anfang Dateiliste.
::findfile		MoveB	r1L,curDirSek +0	;Zeiger auf Track/Sektor
			MoveB	r1H,curDirSek +1	;zwischenspeichern.

			LoadW	a9,BASE_DIRDATA		;Zeiger auf Verzeichnisdaten.

			lda	#$00			;Dateizähler löschen.
			sta	a8L

;--- Verzeichnis-Eintrag auswerten.
::loop			ldy	#$00
			lda	(a9L),y			;Auswahlk-Flag einlesen.
			and	#GD_MODE_MASK		;Datei ausgewählt?
			beq	:skip_file		; => Nein, weiter...
			iny
			iny
			lda	(a9L),y			;Datei gelöscht?
			bne	:skip_file		; => Nein, weiter...

;--- Markierte Datei im Verzeichnis suchen.
			dey
			dey
::2			lda	(r5L),y			;Verzeichnis-Eintrag mit aktuellem
			iny				;Dateieintrag vergleichen.
			iny
			cmp	(a9L),y
			bne	:skip_file
			dey
;			dey
;			iny
			cpy	#30			;Eintrag geprüft?
			bcc	:2			; => Nein, weiter...

			jsr	CopyFName		;Dateiname für Fehlermeldung.

			jsr	chkGeosHeader		;GEOS-Header testen.
			txa				;Header OK?
			bne	:next_file		; => Nein, weiter...

			jsr	recoverFile		;Datei wiederherstellen.
			txa				;Diskettenfehler ?
			beq	:next_file		; => Nein, weiter...

			cpx	#BAD_BAM		;Datei bereits überschrieben ?
			bne	:error			; => Nein, Fehler ausgeben.

			LoadW	r0,Dlg_ErrBadBAM	;BAM belegt / Datei überschrieben.
			jsr	DoDlgBox		;Fehlermeldung anzeigen.

			lda	sysDBData
			cmp	#CANCEL			;VALIDATE ausführen?
			beq	:cancel			; => Nein, Abbruch...
			bne	:next_file		;VALIDATE ausführen.

;--- Laufwerksfehler.
::error			jsr	doXRegStatus		;Fehlermeldung ausgeben.
			jmp	:cancel			;Funktion abbrechen.

;--- Weiter mit nächster Datei.
::skip_file		inc	a8L			;Dateizähler +1.
::3			lda	a8L
			cmp	fileEntryCount
::4			bcs	:next_file		; => Ja, weiter...

			AddVBW	32,a9			;Nächsten Dateieintrag suchen.
			jmp	:loop

;--- Weiter mit nächsten Eintrag.
::next_file		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			beq	:cancel
			jmp	:findfile		; => Nein, weiter...

;--- Verzeichnis bearbeitet.
::cancel		lda	recoveryError		;Dateien wiederhergestellt?
			bne	:5			; => Nein, weiter...
			lda	filesRecovered		;Dateien wiederhergestellt?
			beq	:exit_Recover		; => Nein, weiter...

			lda	#< Dlg_RecoverOK	;Dateien wiederhergestellt.
			ldx	#> Dlg_RecoverOK
			bne	:6
::5			lda	#< Dlg_RecoverErr	;Fehler beim wiederherstellen.
			ldx	#> Dlg_RecoverErr
::6			sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Hinweis: "Validate empfohlen".

			lda	sysDBData
			cmp	#YES			;VALIDATE ausführen?
			bne	:reload			; => Nein, Ende...
			jmp	xVALIDATE		;VALIDATE ausführen.

::exit_Recover		bit	updateDir		;BAM verändert?
			bmi	:reload			; => Ja, weiter...
			jmp	MOD_RESTART		;Zurück zum DeskTop.

::reload		jsr	SET_LOAD_DISK		;Verzeichnis neu einlesen.
			jmp	MOD_UPDATE		;Zurück zum DeskTop.

;*** Verzeichnis-Sektor auf Disk speichern.
:recoverFile		LoadB	updateDir,$ff		;Dateien evtl. wiederhergestellt.
							;":ValidateFile" setzt auch den
							;Dateiauswahl-Modus für die
							;aktuelle Datei zurück!

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	setFileType		;Dateityp temporär setzen.

			jsr	ValidateFile		;Datei validieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	setFileType		;Dateityp erneut setzen, da die
							;Routine ":ValidateFile" am Ende
							;den Verzeichnis-Sektor erneut
							;einlesen muss.
							;":AllocChain" verändert den Inhalt
							;von ":diskBlkBuf"!

;			MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor
;			MoveB	curDirSek +1,r1H	;wieder zurücksetzen.
			LoadW	r4,diskBlkBuf		;Zeiger auf Dir_Sektor.
			jsr	WriteBlock		;Sektor schreiben.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...
			jsr	VerWriteBlock		;Sektor-Verify.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			inc	filesRecovered		;Anzahl Dateien +1.

::exit			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	PutDirHead		;BAM aktualisieren.
;			txa				;Fehler?
;			bne	:error			; => Ja, Abbruch...

			MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor
			MoveB	curDirSek +1,r1H	;wieder zurücksetzen.

;			ldx	#NO_ERROR

::error			cpx	#NO_ERROR
			beq	:x
			inc	recoveryError		;Anzahl Fehler +1.
::x			rts

;*** GEOS-Dateiheader testen.
:chkGeosHeader		PushB	r1L			;Zeiger auf aktuellen
			PushB	r1H			;Verzeichniseintrag
			PushW	r4			;zwischenspeichern.
			PushW	r5

			ldy	#19			;GEOS-Header einlesen.
			lda	(r5L),y
			beq	:ok			; => Kein Header, Ende...
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;Header-Block einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			ldy	#0
::1			lda	fileHeader,y		;GEOS-Headerkennung testen.
			cmp	headerCode,y
			bne	:badHeader		; => Header beschädigt, Abbruch...
			iny
			cpy	#5
			bcc	:1
			bcs	:ok			; => Header OK, Ende...

::badHeader		LoadW	r0,Dlg_BadHdr
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

			ldx	#STRUCT_MISMAT		;Header beschädigt.
			b $2c
::ok			ldx	#NO_ERROR		;Header OK.

::error			cpx	#NO_ERROR
			beq	:x
			inc	recoveryError		;Anzahl Fehler +1.

::x			PopW	r5			;Zeiger auf aktuellen
			PopW	r4			;Verzeichniseintrag wieder
			PopB	r1H			;zurücksetzen.
			PopB	r1L
			rts

;*** Dateityp speichern.
:setFileType		ldy	#1			;Zeiger auf erstenn Datensektor
			jsr	CopySekAdr		;einlesen.
			LoadW	r4,fileHeader
			jsr	ReadBlock		;Datensektor einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	fileHeader +2		;Auf Verzeichnis testen.
			cmp	#$48
			bne	:isFile			; => Datei.
			lda	fileHeader +3
;			cmp	#$00
			beq	:isDir			; => Verzeichnis.

::isFile		ldx	#%10000000 ! PRG	;Standard: Dateityp = PRG.
			ldy	#21
			lda	(r5L),y			;Dateistruktur einlesen.
			beq	:setFType		; => SEQ, weiter...
			ldx	#%10000000 ! USR	;VLIR: Dateityp = USR.
			b $2c
::isDir			ldx	#%10000000 ! $06	;Verzeichnis: Dateityp = DIR.
::setFType		txa
			ldy	#0
			sta	(r5L),y			;CBM-Dateityp setzen.

			MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor
			MoveB	curDirSek +1,r1H	;wieder zurücksetzen.

			ldx	#NO_ERROR
::exit			rts

;*** Dateinamen kopieren.
:CopyFName		ldx	#0
			ldy	#5
::1			lda	(a9L),y
			beq	:2
			cmp	#$a0
			beq	:2
			sta	fileNameBuf,x
			iny
			inx
			cpx	#16
			bcc	:1
::2			lda	#$00
::3			sta	fileNameBuf,x
			iny
			inx
			cpx	#16
			bcc	:3
			rts

;*** Gelöschte Dateieinträge entfernen.
:xPURGEFILES		lda	#$00
			sta	updateDir		;Verzeichnis-Update zurücksetzen.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:findfile		; => Ja, weiter...
			jmp	:cancel

::error			jsr	doXRegStatus		;Fehlermeldung ausgeben.
			jmp	:cancel			;Funktion abbrechen.

;--- Zeiger auf Anfang Dateiliste.
::findfile		LoadW	a9,BASE_DIRDATA		;Zeiger auf Verzeichnisdaten.

			lda	#$00			;Dateizähler löschen.
			sta	a8L

;			MoveB	r1L,curDirSek +0	;Zeiger auf Track/Sektor
;			MoveB	r1H,curDirSek +1	;zwischenspeichern.

;--- Verzeichnis-Eintrag auswerten.
::loop			ldy	#$00
			lda	(a9L),y			;Auswahlk-Flag einlesen.
			and	#GD_MODE_MASK		;Datei ausgewählt?
			beq	:skip_file		; => Nein, weiter...
			iny
			iny
			lda	(a9L),y			;Datei gelöscht?
			bne	:skip_file		; => Nein, weiter...

;--- Markierte Datei im Verzeichnis suchen.
			dey
			dey
::2			lda	(r5L),y			;Verzeichnis-Eintrag mit aktuellem
			iny				;Dateieintrag vergleichen.
			iny
			cmp	(a9L),y
			bne	:skip_file
			dey
;			dey
;			iny
			cpy	#30			;Eintrag geprüft?
			bcc	:2			; => Nein, weiter...
			bcs	:purge_file

;--- Weiter mit nächster Datei.
::skip_file		inc	a8L			;Dateizähler +1.
::3			lda	a8L
			cmp	fileEntryCount
::4			bcs	:next_file		; => Ja, weiter...

			AddVBW	32,a9			;Nächsten Dateieintrag suchen.
			jmp	:loop

;--- Aktuellen Eintrag löschen.
::purge_file		jsr	PurgeEntry		;Verzeichniseintrag löschen.

;--- Weiter mit nächsten Eintrag.
::next_file		lda	r5L
			cmp	#7*32 +2
			bne	:skip_write

			bit	updateDir
			bpl	:skip_write

			jsr	WriteDirSek		;Verzeichnis-Sektor schreiben.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

::skip_write		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:findfile		; => Nein, weiter...

;--- Verzeichnis bearbeitet.
::cancel		jsr	SET_LOAD_DISK		;Verzeichnis neu einlesen.
			jmp	MOD_UPDATE		;Zurück zum DeskTop.

;*** Verzeichniseintrag löschen.
:PurgeEntry		ldy	#$ff
			sty	updateDir

			iny
			tya
::1			sta	(r5L),y			;Verzeichnis-Eintrag mit aktuellem
			iny
			cpy	#30
			bcc	:1

			rts

;*** Verzeichnis-Sektor auf Disk speichern.
:WriteDirSek		jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

;			MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor
;			MoveB	curDirSek +1,r1H	;wieder zurücksetzen.
			LoadW	r4,diskBlkBuf		;Zeiger auf Dir_Sektor.
			jsr	WriteBlock		;Sektor schreiben.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...
			jsr	VerWriteBlock		;Sektor-Verify.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;			lda	#$00
			sta	updateDir

::exit			jsr	DoneWithIO		;I/O-Bereich ausblenden.
;			txa				;Fehler?
;			bne	:error			; => Ja, Abbruch...

;			ldx	#NO_ERROR
::error			rts

;*** Variablen.
:updateDir		b $00
:filesRecovered		b $00
:recoveryError		b $00
:headerCode		b $00,$ff,$03,$15,$bf
:fileNameBuf		s 17

;*** Info: Validate abgebrochen, Diskette fehlerhaft.
:Dlg_CancelMsg		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$08,$1c
			w :2
			b DBTXTSTR   ,$08,$2a
			w :3
			b DBTXTSTR   ,$08,$34
			w :4
			b DBTXTSTR   ,$08,$3e
			w :5
			b DBTXTSTR   ,$08,$4b
			w :6
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Vorgang durch Benutzer abgebrochen!",NULL
::3			b BOLDON
			b "WARNUNG!",NULL
::4			b PLAINTEXT
			b "Das speichern von Daten auf diesem",NULL
::5			b "Laufwerk kann zu Datenverlust führen!",NULL
::6			b "ÜBERPRÜFEN DER DISK ERFORDERLICH!!!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Operation aborted by user!",NULL
::3			b BOLDON
			b "WARNING!",NULL
::4			b PLAINTEXT
			b "Saving data on this drive can result",NULL
::5			b "in data loss!",NULL
::6			b "VALIDATING THE DISK IS RECOMMENDED!!!",NULL
endif

;*** Fehler: Datei konnte nicht wieder hergestellt werden.
:Dlg_ErrBadBAM		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$10,$2c
			w fileNameBuf
			b DBTXTSTR   ,$0c,$44
			w dlgRecoverTx03
			b OK         ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Datei wurde teilweise überschrieben:"
			b BOLDON,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "File was partly overwritten:"
			b BOLDON,NULL
endif

;*** Fehler: Infoblock beschädigt.
:Dlg_BadHdr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$10,$2c
			w fileNameBuf
			b DBTXTSTR   ,$0c,$44
			w dlgRecoverTx03
			b OK         ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Der GEOS-Infoblock ist beschädigt!"
			b BOLDON,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The GEOS infoblock is damaged!"
			b BOLDON,NULL
endif

;*** Hinweis: Dateien wieder hergestellt, Validate ausführen.
:Dlg_RecoverOK		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$3c
			w dlgRecoverTx01
			b DBTXTSTR   ,$0c,$48
			w dlgRecoverTx02
			b YES        ,$01,$50
			b NO         ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Dateien wurden wiederhergestellt.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "File recovery successful.",NULL
endif

;*** Hinweis: Dateien wieder hergestellt, Validate ausführen.
:Dlg_RecoverErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3c
			w dlgRecoverTx01
			b DBTXTSTR   ,$0c,$48
			w dlgRecoverTx02
			b YES        ,$01,$50
			b NO         ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Einige Dateien konnten nicht",NULL
::3			b "wiederhergestellt werden.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Some files could not be recovered.",NULL
::3			b NULL
endif

if LANG = LANG_DE
:dlgRecoverTx01		b PLAINTEXT
			b "Überprüfung des Laufwerks empfohlen!",NULL
:dlgRecoverTx02		b "Laufwerk überprüfen?",NULL
:dlgRecoverTx03		b PLAINTEXT
			b "Wiederherstellen nicht möglich!",NULL
endif
if LANG = LANG_EN
:dlgRecoverTx01		b PLAINTEXT
			b "Validate disk is recommended!",NULL
:dlgRecoverTx02		b "Start disk validate?",NULL
:dlgRecoverTx03		b PLAINTEXT
			b "File recovery is not possible!",NULL
endif

;*** Endadresse testen:
			g RegMenuBase
;***
