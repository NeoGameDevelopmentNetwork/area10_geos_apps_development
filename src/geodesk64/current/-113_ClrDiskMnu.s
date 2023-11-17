; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskette bereinigen.
:xPURGEDISK		lda	#$00
			b $2c

;*** Disk löschen.
:xCLEARDISK		lda	#$ff
			sta	optClearDir
			eor	#$ff
			sta	optClearSek

			jsr	openRootDrive		;Native/ROOT öffnen.

			LoadB	formatMode,$00		;Modus setzen: Disk löschen.

			jsr	copyDiskName		;Diskname einlesen.

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Disk formatieren.
:xFORMATDISK		jsr	openRootDrive		;Native/ROOT öffnen.

			ClrB	optDoubleSided		;Doppelseitig-Option zurücksetzen.

			ldy	#BOX_OPTION_VIEW
			ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvType -8,x
			cmp	#Drv1571		;1571-Laufwerk?
			bne	:2			; => Nein, weiter...

			lda	RealDrvMode -8,x
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk.
			bne	:2			; => Nein, weiter...

			ldy	#BOX_OPTION		;1571:
			dec	optDoubleSided		;Standard: Doppelseitig.
::2			sty	RTabMenu2_1a		;Option aktivieren/deaktivieren.

			LoadB	formatMode,$ff		;Modus setzen: Disk formatieren.

			jsr	copyDiskName		;Diskname einlesen.

			LoadW	r0,RegMenu2		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zu ROOT.
:openRootDrive		ldy	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			jsr	OpenRootDir		; => Hauptverzeichnis öffnen.

			ldx	WM_WCODE		;Aktuelles Fenster =
			cpx	WM_MYCOMP		;Arbeitsplatz?
			beq	:1			; => Ja, Ende...

			lda	#$01			;Hauptverzeichnis für
			sta	WIN_SDIR_T,x		;aktuelles Fenster aktivieren.
			sta	WIN_SDIR_S,x

			lda	#$00			;PagingMode: Verzeichnis von
			sta	WIN_DIR_START,x		;Anfang neu anzeigen.

::1			rts

;*** Diskname kopieren.
:copyDiskName		lda	curDrive		;Laufwerksadresse in Optionen
			clc				;übernehmen.
			adc	#$39
			sta	textDrive

			jsr	NewDisk			;Diskette öffnen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...

			LoadW	r0,textEmptyDisk	;Zeiger auf Standard-Diskname.
			jmp	:2

::1			ldx	#r0L			;Zeiger auf Diskname einlesen.
			jsr	GetPtrCurDkNm

::2			LoadW	r1,textDrvName		;Zeiger auf Zwischenspeicher.

			ldx	#r0L
			ldy	#r1L
			jmp	SysCopyName		;Diskname kopieren.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	WM_LOAD_BACKSCR		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskCopy ausführen?
			cmp	#$7f
			bne	:exit			; => Nein, Ende...

			LoadB	reloadDir,$ff		;Flag "Verzeichnis neu anzeigen".

			jsr	closeDrvWin		;Andere Laufwerksfenster schließen.

			bit	formatMode		;Löschen/Formatieren?
			bmi	:callFrmtDisk		; => Format, weiter...

			bit	optClearDir		;Verzeichnis löschen?
			bpl	:callClrDisk		; => Nein, weiter...

			jsr	doDlg_WarnFrmt		;Diskette formatieren?
			bne	:exit			; => Nein, Abbruch...

;--- Diskette löschen.
::callClrDisk		jsr	doClearDisk		;Disk löschen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			beq	:done			; => Weiter...

;--- Diskette formatieren.
::callFrmtDisk		jsr	doDlg_WarnFrmt		;Diskette formatieren?
			bne	:exit			; => Nein, Abbruch...

			jsr	doFormatDisk		;Disk formatieren.
			txa				;Fehler?
;			bne	:error			; => Ja, Abbruch...
			beq	:done			; => Weiter...

;--- Fehlermeldung ausgeben.
::error			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

;--- Zurück zum DeskTop.
::done			bit	reloadDir		;Disk-Name/GEOS-Disk geändert?
			bpl	:exit			; => Nein, Ende...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::exit			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "Disk löschen" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
			rts

;*** Abfrage: Diskette löschen/formatieren?
;    Rückgabe: Z-Flag=0 => Abbruch
:doDlg_WarnFrmt		ldx	#<warnText0a		;Zeiger auf "Laufwerk formatieren".
			ldy	#>warnText0a
			lda	formatMode		;Laufwerk formatieren?
			bne	:1			; => Ja, weiter...
			ldx	#<warnText0b		;Zeiger auf "Laufwerk löschen".
			ldy	#>warnText0b
::1			stx	warnMsgText +0		;Zeiger auf Text in DialogBox
			sty	warnMsgText +1		;übertragen.

			LoadW	r0,Dlg_WarnFormat
			jsr	DoDlgBox		;Diskette formatieren?

			lda	sysDBData		;Rückmeldung einlesen.
			cmp	#YES			;Löschen/Formatieren?
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.
:formatMode		b $00				;$00=Disk löschen / $FF=Formatieren.
:textDrive		b "A:",NULL

if LANG = LANG_DE
:textEmptyDisk		b "LEERDISK",NULL
endif
if LANG = LANG_EN
:textEmptyDisk		b "EMPTY",NULL
endif

;*** Frage: Diskette formatieren?
:Dlg_WarnFormat		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
:warnMsgText		w warnText0a
			b DBTXTSTR   ,$18,$2e
			w textDrive
			b DBTXTSTR   ,$22,$2e
			w textDrvName
			b DBTXTSTR   ,$0c,$3e
			w warnText1
			b DBTXTSTR   ,$0c,$48
			w warnText2
			b CANCEL     ,$01,$50
			b YES        ,$11,$50
			b NULL

if LANG = LANG_DE
:warnText0a		b PLAINTEXT
			b "Diskette/Laufwerk formatieren?"
			b BOLDON,NULL
:warnText0b		b PLAINTEXT
			b "Inhalt des Laufwerks löschen?"
			b BOLDON,NULL
:warnText1		b "WARNUNG: "
			b PLAINTEXT
			b "Dieser Vorgang kann",NULL
:warnText2		b "nicht rückgängig gemacht werden!",NULL
endif
if LANG = LANG_EN
:warnText0a		b PLAINTEXT
			b "Format diskette/drive?"
			b BOLDON,NULL
:warnText0b		b PLAINTEXT
			b "Erase content of the drive?"
			b BOLDON,NULL
:warnText1		b "WARNING: "
			b PLAINTEXT
			b "",NULL
:warnText2		b "This operation cannot be undone!",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $28
:R1SizeY1		= $a7
:R1SizeX0		= $0038
:R1SizeX1		= $00ff

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RTabName1_1			;Register: "LÖSCHEN".
			w RTabMenu1_1

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

;*** Icon "Löschen/Formatieren" ausführen.
:RIcon_Format		w IconFormat
			b $00,$00
			b IconFormat_x,IconFormat_y
			b $01

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "LÖSCHEN".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RWidth1a = $0028
if LANG = LANG_DE
:RWidth1b = $0040
endif
if LANG = LANG_EN
:RWidth1b = $0048
endif
:RLine1_0 = $00
:RLine1_1 = $10
:RLine1_2 = $20
:RLine1_3 = $30
:RLine1_4 = $40

:RTabMenu1_1		b 7

			b BOX_ICON			;----------------------------------------
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_Format
				b $00

			b BOX_FRAME			;----------------------------------------
				w R1T01
				w $0000
				b RPos1_y +RLine1_0 -$05
				b (R1SizeY1 +1) -$18 -$10 +$05
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW		;----------------------------------------
				w R1T02a
				w $0000
				b RPos1_y +RLine1_0
				w RPos1_x +RWidth1b
				w textDrive
				b 2

			b BOX_STRING			;----------------------------------------
				w R1T02b
				w setReloadDir
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1a
				w textDrvName
				b 16

			b BOX_OPTION			;----------------------------------------
				w R1T03
				w setReloadDir
				b RPos1_y +RLine1_2
				w RPos1_x
				w optClearDir
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T04
				w setReloadDir
				b RPos1_y +RLine1_3
				w RPos1_x
				w optClearSek
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T05
				w setReloadDir
				b RPos1_y +RLine1_4
				w RPos1_x
				w curDiskGEOS
				b %11111111

if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Diskette"
			b GOTOXY
			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "löschen",NULL

:R1T01			b "OPTIONEN",NULL

:R1T02a			w RPos1_x
			b RPos1_y +RLine1_0 +$06
			b "Laufwerk:",NULL

:R1T02b			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Name:",NULL

:R1T03			w RPos1_x +$0c
			b RPos1_y +RLine1_2 +$06
			b "Verzeichnis löschen",NULL

:R1T04			w RPos1_x +$0c
			b RPos1_y +RLine1_3 +$06
			b "Freie Sektoren löschen",NULL

:R1T05			w RPos1_x +$0c
			b RPos1_y +RLine1_4 +$06
			b "GEOS Format",NULL
endif
if LANG = LANG_EN
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Clear"
			b GOTOXY
			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "Disk/Drive",NULL

:R1T01			b "OPTIONS",NULL

:R1T02a			w RPos1_x
			b RPos1_y +RLine1_0 +$06
			b "Disk/Drive:",NULL

:R1T02b			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Name:",NULL

:R1T03			w RPos1_x +$0c
			b RPos1_y +RLine1_2 +$06
			b "Delete directory",NULL

:R1T04			w RPos1_x +$0c
			b RPos1_y +RLine1_3 +$06
			b "Clear unused disk sectors",NULL

:R1T05			w RPos1_x +$0c
			b RPos1_y +RLine1_4 +$06
			b "GEOS format",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R2SizeY0		= $28
:R2SizeY1		= $97
:R2SizeX0		= $0038
:R2SizeX1		= $00ff

:RegMenu2		b R2SizeY0			;Register-Größe.
			b R2SizeY1
			w R2SizeX0
			w R2SizeX1

			b 1				;Anzahl Einträge.

			w RTabName2_1			;Register: "FORMATIEREN".
			w RTabMenu2_1

;*** Registerkarten-Icons.
:RTabName2_1		w RTabIcon2
			b RCardIconX_2,R2SizeY0 -$08
			b RTabIcon2_x,RTabIcon2_y

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "FORMATIEREN".
:RPos2_x  = R2SizeX0 +$10
:RPos2_y  = R2SizeY0 +$10
:RWidth2a = $0028
:RWidth2b = $0060
if LANG = LANG_DE
:RWidth2c = $0040
endif
if LANG = LANG_EN
:RWidth2c = $0048
endif
:RLine2_0 = $00
:RLine2_1 = $10
:RLine2_2 = $20
:RLine2_3 = $30
:RLine2_4 = $40

:RTabMenu2_1		b 7

			b BOX_ICON			;----------------------------------------
				w R2T00
				w EXEC_REG_ROUT
				b (R2SizeY1 +1) -$18
				w R2SizeX0 +$10
				w RIcon_Format
				b $00

			b BOX_FRAME			;----------------------------------------
				w R2T01
				w $0000
				b RPos2_y +RLine2_0 -$05
				b (R2SizeY1 +1) -$18 -$10 +$05
				w R2SizeX0 +$08
				w R2SizeX1 -$08

			b BOX_STRING_VIEW		;----------------------------------------
				w R2T02
				w $0000
				b RPos2_y +RLine2_0
				w RPos2_x +RWidth2c
				w textDrive
				b 2

			b BOX_STRING			;----------------------------------------
				w R2T03
				w setReloadDir
				b RPos2_y +RLine2_1
				w RPos2_x +RWidth2a
				w textDrvName
				b 16

			b BOX_OPTION			;----------------------------------------
				w R2T04
				w setReloadDir
				b RPos1_y +RLine1_2
				w RPos1_x
				w optQuickFrmt
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R2T05
				w setReloadDir
				b RPos2_y +RLine1_2
				w RPos2_x +RWidth2b
				w curDiskGEOS
				b %11111111

:RTabMenu2_1a		b BOX_OPTION			;----------------------------------------
				w R2T06
				w $0000
				b RPos2_y +RLine1_3
				w RPos2_x
				w optDoubleSided
				b %11111111

if LANG = LANG_DE
:R2T00			w R2SizeX0 +$10 +$18
			b (R2SizeY1 +1) -$18 +$06
			b "Diskette"
			b GOTOXY
			w R2SizeX0 +$10 +$18
			b (R2SizeY1 +1) -$18 +$08 +$06
			b "formatieren",NULL

:R2T01			b "OPTIONEN",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_0 +$06
			b "Laufwerk:",NULL

:R2T03			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Name:",NULL

:R2T04			w RPos2_x +$0c
			b RPos2_y +RLine2_2 +$06
			b "Quick-Format",NULL

:R2T05			w RPos2_x +RWidth2b +$0c
			b RPos2_y +RLine2_2 +$06
			b "GEOS Format",NULL

:R2T06			w RPos2_x +$0c
			b RPos2_y +RLine2_3 +$06
			b "Nur 1571: Doppelseitig",NULL
endif
if LANG = LANG_EN
:R2T00			w R2SizeX0 +$10 +$18
			b (R2SizeY1 +1) -$18 +$06
			b "Format"
			b GOTOXY
			w R2SizeX0 +$10 +$18
			b (R2SizeY1 +1) -$18 +$08 +$06
			b "disk/Drive",NULL

:R2T01			b "OPTIONS",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_0 +$06
			b "Disk/Drive:",NULL

:R2T03			w RPos2_x
			b RPos2_y +RLine2_1 +$06
			b "Name:",NULL

:R2T04			w RPos2_x +$0c
			b RPos2_y +RLine2_2 +$06
			b "Quick-Format",NULL

:R2T05			w RPos2_x +RWidth2b +$0c
			b RPos2_y +RLine2_2 +$06
			b "GEOS format",NULL

:R2T06			w RPos2_x +$0c
			b RPos2_y +RLine2_3 +$06
			b "1571 only: Double sided",NULL
endif

;*** Icons für Registerkarten.
:RTabIcon1
if LANG = LANG_DE
<MISSING_IMAGE_DATA>
endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>
endif

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

:RTabIcon2
if LANG = LANG_DE
<MISSING_IMAGE_DATA>
endif
if LANG = LANG_EN
<MISSING_IMAGE_DATA>
endif

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_2		= (R2SizeX0/8) +3
;RCardIconX_3		= RCardIconX_1 + RTabIcon1_x

;*** Register-Funktions-Icons.
:IconFormat
<MISSING_IMAGE_DATA>

:IconFormat_x		= .x
:IconFormat_y		= .y
