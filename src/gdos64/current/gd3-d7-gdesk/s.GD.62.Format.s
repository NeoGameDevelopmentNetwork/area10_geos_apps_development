; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Disk löschen.

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
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"

;--- Standard Disk-ID:
:DISK_ID_1		= "6"
:DISK_ID_2		= "4"

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
			n "obj.GD62"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xCLEARDISK
			jmp	xPURGEDISK
			jmp	xFORMATDISK

;*** Programmroutinen.
			t "-Gxx_ClearBAM"		;BAM auf Disk löschen.
			t "-Gxx_DiskMaxTr"		;Anzahl Track auf Disk ermitteln.
			t "-Gxx_DiskNextSek"		;Zeiger auf nächsten Disk-Sektor.
			t "-Gxx_DiskNewName"		;Diskname ändern.
			t "-Gxx_IBoxCore"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** Diskette bereinigen.
:xPURGEDISK		lda	#$00			;Register-Menü initialisieren.
			b $2c

;*** Disk löschen.
:xCLEARDISK		lda	#$ff			;Register-Menü initialisieren.
			sta	optClearDir

;--- Sonderbehandlung Clear-/PurgeDisk.
			eor	#$ff			;Sektoren nur bei PurgeDisk löschen.
			sta	optClearSek		;Bei ClearDisk nur Verzeichnis.

			lda	#$00			;Modi für CMD-FD zurücksetzen.
			sta	optFrmtModeFD

			jsr	openRootDrive		;Native/ROOT öffnen.

			LoadB	formatMode,$00		;Modus setzen: Disk löschen.

			jsr	copyDiskName		;Diskname einlesen.

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Disk formatieren.
:xFORMATDISK		lda	#$00			;Register-Menü initialisieren.
			sta	optFrmtModeFD
			sta	optFrmtGEOS
			sta	optQuickFrmt

			ldx	#BOX_OPTION
			stx	RegTMenu2d		;Option "QuickFormat" definieren.
			stx	RegTMenu2e		;Option "GEOS-Disk" definieren.

			jsr	TestCMDFD		;Formatoptionen festlegen.
			jsr	copyFrmtText

			jsr	openRootDrive		;Native/ROOT öffnen.

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
::2			sty	RegTMenu2a		;Option aktivieren/deaktivieren.

			LoadB	formatMode,$ff		;Modus setzen: Disk formatieren.

			jsr	copyDiskName		;Diskname einlesen.

			LoadW	r0,RegMenu2		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskCopy ausführen?
			cmp	#$7f
			bne	:exit			; => Nein, Ende...

			LoadB	reloadDir,$ff		;Flag "Verzeichnis neu anzeigen".

			bit	formatMode		;Löschen/Formatieren?
			bmi	:callFrmtDisk		; => Format, weiter...

;--- Diskette löschen.
::callClrDisk		bit	optClearDir		;Verzeichnis löschen?
			bpl	:1			; => Nein, weiter...

			jsr	doDlg_WarnFrmt		;Diskette formatieren?
			bne	:exit			; => Nein, Abbruch...

::1			jsr	doClearDisk		;Disk löschen.
			txa				;Fehler?
			beq	:doneClrDisk		; => Nein, weiter...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
			jsr	PurgeTurbo		;TurboDOS entfernen.

;--- Zurück zum DeskTop.
::doneClrDisk		bit	reloadDir		;Disk-Name/GEOS-Disk geändert?
			bpl	:exit			; => Nein, Ende...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::exit			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;--- Diskette formatieren.
::callFrmtDisk		jsr	doDlg_WarnFrmt		;Diskette formatieren?
			bne	:exit			; => Nein, Abbruch...

			jsr	doFormatDisk		;Disk formatieren.
			txa				;Fehler?
			beq	:doneFrmtDisk		; => Weiter...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.
			jsr	PurgeTurbo		;TurboDOS entfernen.

;--- Zurück zum DeskTop.
::doneFrmtDisk		bit	reloadDir		;Disk-Name/GEOS-Disk geändert?
			bpl	:2			; => Nein, Ende...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.

::2			lda	frmtModeFD		;CMD-FD-Laufwerk ?
			beq	:exit			; => Nein, weiter...

			ldx	#%10000000
			lda	optFrmtModeFD		;Format-Modus CMD-FD einlesen.
			cmp	#4			;HD8 ?
			beq	:3			; => Ja, Partitionsauswahl.
			cmp	#6			;ED8 ?
			beq	:3			; => Ja, Partitionsauswahl.
			ldx	#%00000000
::3			stx	flgSlctPartMode

			lda	MP3_64K_DISK		;"Treiber-im-RAM" aktiv ?
			bne	:slctDrvMode		; => Ja, weiter...

			lda	flgSlctDrvMode		;Laufwerksmodus gewechselt ?
			beq	:slctDrvPart		; => Nein, weiter...

			bit	GD_COMPAT_WARN		;Kompatibilitätswarnung anzeigen ?
			bvc	:slctDrvPart		; => Nein, weiter..

			LoadW	r0,Dlg_InfoFDErr
			jsr	DoDlgBox		;Info: "FD-Disk inkompatibel!"

;--- CMD-FD: Partition wählen.
::slctDrvPart		lda	flgSlctPartMode		;Partition auswählen ?
			beq	:exitFD			; => Nein, Ende...

			lda	drvUpdFlag
			ora	#%10000000		;Fensterdaten aktualisieren.
			sta	drvUpdFlag

			lda	drvUpdMode
			ora	#%10000000		;CMD-Partitionsauswahl.
			sta	drvUpdMode

::exitFD		jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;--- CMD-FD: Laufwerksmodus wechseln.
::slctDrvMode		lda	flgSlctDrvMode		;Laufwerksmodus gewechselt ?
			beq	:slctDrvPart		; => Nein, ggf. Partition wechseln.

			lda	curDrive		;Laufwerk für Modusauswahl
			sta	TempDrive		;vorgeben.
			lda	curFormatType		;Neuen Modus für Laufwerk
			sta	TempMode		;vorgeben.

			lda	flgSlctPartMode		;CMD-FD: Partitionen auswählen.
			sta	TempPart

			jmp	MOD_NEWDRVMODE		;Laufwerksmodus ändern.

;*** Icon "Disk löschen" gewählt.
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
:setReloadDir		lda	#$ff
			sta	reloadDir
			rts

;*** Variablen.
:reloadDir		b $00				;$FF=Verzeichnis aktualisieren.

;*** Abfrage: Diskette löschen/formatieren?
;    Rückgabe: Z-Flag=0 => Abbruch
:doDlg_WarnFrmt		jsr	editFComFormat		;Format-Befehl erstellen.

			ldx	#< warnText0a		;Zeiger auf "Laufwerk formatieren".
			ldy	#> warnText0a

			lda	formatMode		;Laufwerk formatieren?
			bne	:1			; => Ja, weiter...

			ldx	#< warnText0b		;Zeiger auf "Laufwerk löschen".
			ldy	#> warnText0b

::1			stx	warnMsgText +0		;Zeiger auf Text in DialogBox
			sty	warnMsgText +1		;übertragen.

			LoadW	r0,Dlg_WarnFormat
			jsr	DoDlgBox		;Diskette formatieren?

			lda	sysDBData		;Rückmeldung einlesen.
			cmp	#YES			;Löschen/Formatieren?
			rts

;*** Register-Menü "LÖSCHEN".
:R1SizeY0 = $28
:R1SizeY1 = $a7
:R1SizeX0 = $0038
:R1SizeX1 = $00ff

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "LÖSCHEN".
			w RegTMenu1

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIcon1_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif
if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RCardIcon1_1		= (R1SizeX0/8) +3
;RCardIcon1_2		= RCardIcon1_1 + RTabIcon1_x

;*** Icon "Löschen/Formatieren" ausführen.
:RIcon_Format		w Icon_Format
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_Format_x,Icon_Format_y
			b USE_COLOR_INPUT

:Icon_Format
<MISSING_IMAGE_DATA>

:Icon_Format_x		= .x
:Icon_Format_y		= .y

;*** Daten für Register "LÖSCHEN".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RTab1_1  = $0028
if LANG = LANG_DE
:RTab1_2  = $0040
endif
if LANG = LANG_EN
:RTab1_2  = $0048
endif
:RLine1_0 = $00
:RLine1_1 = $10
:RLine1_2 = $20
:RLine1_3 = $30
:RLine1_4 = $40

:RegTMenu1		b 7

			b BOX_ICON
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_Format
				b NO_OPT_UPDATE

			b BOX_FRAME
				w R1T01
				w $0000
				b RPos1_y +RLine1_0 -$05
				b (R1SizeY1 +1) -$18 -$10 +$05
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW
				w R1T02a
				w $0000
				b RPos1_y +RLine1_0
				w RPos1_x +RTab1_2
				w textDrive
				b 2

			b BOX_STRING
				w R1T02b
				w setReloadDir
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1
				w newDiskName
				b 16

			b BOX_OPTION
				w R1T03
				w setReloadDir
				b RPos1_y +RLine1_2
				w RPos1_x
				w optClearDir
				b %11111111

			b BOX_OPTION
				w R1T04
				w setReloadDir
				b RPos1_y +RLine1_3
				w RPos1_x
				w optClearSek
				b %11111111

			b BOX_OPTION
				w R1T05
				w setReloadDir
				b RPos1_y +RLine1_4
				w RPos1_x
				w optFrmtGEOS
				b %11111111

;*** Texte für Register "LÖSCHEN".
if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Diskette"
			b GOTOXY
			w R1SizeX0 +$10 +$14
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
			b "GEOS-Format",NULL
endif
if LANG = LANG_EN
:R1T00			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Clear"
			b GOTOXY
			w R1SizeX0 +$10 +$14
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

;*** Register-Menü "FORMATIEREN".
:R2SizeY0		= $28
:R2SizeY1		= $a7
:R2SizeX0		= $0028
:R2SizeX1		= $010f

:RegMenu2		b R2SizeY0			;Register-Größe.
			b R2SizeY1
			w R2SizeX0
			w R2SizeX1

			b 1				;Anzahl Einträge.

			w RegTName2			;Register: "FORMATIEREN".
			w RegTMenu2

;*** Register-Icons.
:RegTName2		w RTabIcon2
			b RCardIcon2_1,R2SizeY0 -$08
			b RTabIcon2_x,RTabIcon2_y

if LANG = LANG_DE
:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y
endif
if LANG = LANG_EN
:RTabIcon2
<MISSING_IMAGE_DATA>

:RTabIcon2_x		= .x
:RTabIcon2_y		= .y
endif

;*** X-Koordinate der Register-Icons.
:RCardIcon2_1		= (R2SizeX0/8) +3
;RCardIcon2_2		= RCardIcon2_1 + RTabIcon2_x

;*** Icons für Optionen.
:RIcon_Select		w Icon_MSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSelect_x,Icon_MSelect_y
			b USE_COLOR_INPUT

;*** System-Icons einbinden.
if .p
:EnableMSelect		= TRUE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= FALSE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Daten für Register "FORMATIEREN".
:RPos2_x  = R2SizeX0 +$10
:RPos2_y  = R2SizeY0 +$10
:RTab2_1  = $0018
:RTab2_2  = $0068
:RTab2_3  = $00b8
:RTab2_4  = $0080
:RLine2_0 = $08
:RLine2_1 = $18
:RLine2_2 = $28
:RLine2_3 = $38
:RLine2_4 = $40

:RegTMenu2		b 12

			b BOX_ICON
				w R2T00
				w EXEC_REG_ROUT
				b (R2SizeY1 +1) -$18
				w R2SizeX0 +$10
				w RIcon_Format
				b NO_OPT_UPDATE

			b BOX_FRAME
				w R2T01
				w $0000
				b RPos2_y -$05
				b (R2SizeY1 +1) -$18 -$10 +$05
				w R2SizeX0 +$08
				w R2SizeX1 -$08

			b BOX_STRING_VIEW
				w R2T02
				w $0000
				b RPos2_y +RLine2_0
				w RPos2_x
				w textDrive
				b 2

			b BOX_STRING
				w R2T02
				w setReloadDir
				b RPos2_y +RLine2_0
				w RPos2_x +RTab2_1
				w newDiskName
				b 16

			b BOX_STRING
				w R2T03
				w setReloadDir
				b RPos2_y +RLine2_0
				w RPos2_x +RTab2_3
				w newDiskID
				b 2

:RegTMenu2d		b BOX_OPTION
				w R2T04
				w setReloadDir
				b RPos2_y +RLine2_1
				w RPos2_x
				w optQuickFrmt
				b %11111111

:RegTMenu2e		b BOX_OPTION
				w R2T05
				w setReloadDir
				b RPos2_y +RLine2_1
				w RPos2_x +RTab2_2
				w optFrmtGEOS
				b %11111111

:RegTMenu2a		b BOX_OPTION
				w R2T06
				w $0000
				b RPos2_y +RLine2_2
				w RPos2_x
				w optDoubleSided
				b %11111111

;--- CMD-FD Formatauswahl.
			b BOX_FRAME
				w $0000
				w $0000
				b RPos2_y +RLine2_3 -1
				b RPos2_y +RLine2_3 +8
				w R2SizeX1 -$08 -$08 -$08 -$08*4
				w R2SizeX1 -$08 -$08 +$01
:RegTMenu2b		b BOX_STRING_VIEW
				w R2T07
				w copyFrmtText
				b RPos2_y +RLine2_3
				w R2SizeX1 -$08 -$08 -$08 -$08*4 +$01
				w extFormatType +1
				b $04
:RegTMenu2c		b BOX_ICON
				w $0000
				w slctFrmtMode
				b RPos2_y +RLine2_3
				w R2SizeX1 -$08 -$08 -$08 +$01
				w RIcon_Select
				b (RegTMenu2b - RegTMenu2 -1)/11 +1
:RegTMenu2f		b BOX_OPTION
				w R2T08
				w $0000
				b (R2SizeY1 +1) -$18
				w R2SizeX1 -$08 -$08 -$08 +$01
				w GD_COMPAT_WARN
				b %01000000

;*** Texte für Register "FORMATIEREN".
if LANG = LANG_DE
:R2T00			w R2SizeX0 +$10 +$14
			b (R2SizeY1 +1) -$18 +$06
			b "Diskette"
			b GOTOXY
			w R2SizeX0 +$10 +$14
			b (R2SizeY1 +1) -$18 +$08 +$06
			b "formatieren",NULL

:R2T01			b "OPTIONEN",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_0 -$0a +$06
			b "Neuer Name für Diskette/Laufwerk:",NULL

:R2T03			w RPos2_x +RTab2_3 -$14
			b RPos2_y +RLine2_0 +$06
			b "ID:",NULL

:R2T04			w RPos2_x +$0c
			b RPos2_y +RLine2_1 +$06
			b "Quick-Format",NULL

:R2T05			w RPos2_x +RTab2_2 +$0c
			b RPos2_y +RLine2_1 +$06
			b "GEOS-Format",NULL

:R2T06			w RPos2_x +$0c
			b RPos2_y +RLine2_2 +$06
			b "Nur 1571: Doppelseitig",NULL

:R2T07			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "CMD-FD Format-Optionen:"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_3 +$06 +$09
			b "(STD = Aktive Partition)",NULL

:R2T08			w R2SizeX1 -$74
			b (R2SizeY1 +1) -$18 +$06
			b "Kompatibilitäts-"
			b GOTOXY
			w R2SizeX1 -$74
			b (R2SizeY1 +1) -$18 +$08 +$06
			b "warnung zeigen",NULL
endif
if LANG = LANG_EN
:R2T00			w R2SizeX0 +$10 +$14
			b (R2SizeY1 +1) -$18 +$06
			b "Format"
			b GOTOXY
			w R2SizeX0 +$10 +$14
			b (R2SizeY1 +1) -$18 +$08 +$06
			b "disk/drive",NULL

:R2T01			b "OPTIONS",NULL

:R2T02			w RPos2_x
			b RPos2_y +RLine2_0 -$0a +$06
			b "New disk/drive name:",NULL

:R2T03			w RPos2_x +RTab2_3 -$14
			b RPos2_y +RLine2_0 +$06
			b "ID:",NULL

:R2T04			w RPos2_x +$0c
			b RPos2_y +RLine2_1 +$06
			b "Quick format",NULL

:R2T05			w RPos2_x +RTab2_2 +$0c
			b RPos2_y +RLine2_1 +$06
			b "GEOS format",NULL

:R2T06			w RPos2_x +$0c
			b RPos2_y +RLine2_2 +$06
			b "1571 only: Double sided",NULL

:R2T07			w RPos2_x
			b RPos2_y +RLine2_3 +$06
			b "CMD-FD Format options:"
			b GOTOXY
			w RPos2_x
			b RPos2_y +RLine2_3 +$06 +$09
			b "(STD = Current partition)",NULL

:R2T08			w R2SizeX1 -$68
			b (R2SizeY1 +1) -$18 +$06
			b "Compatibility"
			b GOTOXY
			w R2SizeX1 -$68
			b (R2SizeY1 +1) -$18 +$08 +$06
			b "warning note",NULL
endif

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	_ext_InitIBox		;Status-Box anzeigen.
			jsr	_ext_InitStat		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont		;GEOS-Font für Titel aktivieren.

			LoadW	r0,jobInfTxDelete	;"Leere Sektoren löschen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxTrack		;"Spur:"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jmp	PutString

;*** Info-Box "Formatieren" anzeigen.
:DrawFormatBox		jsr	_ext_InitIBox		;Status-Box anzeigen.

			jsr	UseSystemFont		;GEOS-Font aktivieren.

			LoadW	r0,jobInfTxFormat	;"Diskette formatieren"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxDrive		;"Laufwerk"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,textDrive		;"X:"
			LoadW	r11,INFO_X0
			jsr	PutString

			LoadW	r0,infoTxFormat		;"Disk wird formatiert"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y3
			jsr	PutString

			jmp	prntDiskInfo		;Disknamen ausgeben.

;*** Disk-/Verzeichnisname ausgeben.
:prntDiskInfo		LoadW	r0,infoTxDisk		;"Diskette"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y2
			jsr	PutString

			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y2
			LoadW	r0,newDiskName
			jmp	smallPutString		;Disk-/Verzeichnisname ausgeben.

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
:jobInfTxFormat		b PLAINTEXT,BOLDON
			b "DISKETTE FORMATIEREN"
			b PLAINTEXT,NULL

:infoTxFormat		b "Bitte warten, Diskette wird formatierert...",NULL
:infoTxDrive		b "Laufwerk:",NULL

:jobInfTxDelete		b PLAINTEXT,BOLDON
			b "FREIE SEKTOREN LÖSCHEN"
			b PLAINTEXT,NULL

:infoTxDisk		b "Diskette: ",NULL
:infoTxTrack		b "Spur: ",NULL
:infoTxMaxTr		b " von ",NULL
endif
if LANG = LANG_EN
:jobInfTxFormat		b PLAINTEXT,BOLDON
			b "FORMAT DISK"
			b PLAINTEXT,NULL

:infoTxFormat		b "Please wait, disk will be formatted...",NULL
:infoTxDrive		b "Drive:",NULL

:jobInfTxDelete		b PLAINTEXT,BOLDON
			b "CLEAR UNUSED SECTORS"
			b PLAINTEXT,NULL

:infoTxDisk		b "Disk: ",NULL
:infoTxTrack		b "Track: ",NULL
:infoTxMaxTr		b " of ",NULL
endif

;*** Diskname für StatusBox.
:curDiskName		s 17

;*** Diskette formatieren.
:doFormatDisk		jsr	DrawFormatBox		;"Disk wird formatiert..."

;--- Auf 1571 testen.
			ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvType -8,x	;Laufwerkstyp einlesen.
			cmp	#Drv1571		;1571-Laufwerk?
			bne	:send_format		; => Nein, weiter...

			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			bne	:send_format		; => Ja, weiter...

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Set1571Mode		;1571: Einseitig/Doppelseitig.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

;--- HINWEIS:
;Die Abfrage des Fehlerstatus gibt dem
;Laufwerk die Zeit den Init-Befehl
;auszuführen (Format1571-Problem).
;Die Rückantwort aber nicht auswerten,
;da bei nicht formatierten Disketten
;ein Fehler zurückgemeldet wird.
if FALSE
			lda	FComReply +0		;Fehlerstatus prüfen.
			cmp	#"0"
			bne	:1
			lda	FComReply +1
			cmp	#"0"
			beq	:setFormatMode
::1			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			ldx	#DEV_NOT_FOUND		;Fehler beim Initialize.
			rts
endif

;--- Disk formatieren.
::send_format		jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	sendInitDisk		;Diskette intialisieren.
							;Erforderlich für CMD-FD, wenn noch
							;keine Partition aktiv ist.

			lda	FComFormatLen		;Diskette formatieren.
			ldx	#< FComFormat
			ldy	#> FComFormat
			jsr	openFComChan

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

;--- VICE/DD8 Workaround:
;BUGFIX: VICE kann mit einer CMD-FD2/4
;keine DD8-DiskImages formatieren.
;Ergebnis -> FORMAT ERROR.
;Wenn das DiskImage nur aus $00-Bytes
;besteht, dann Disk zusätzlich löschen.
::cont			ldx	curDrive		;Aktive Partition zurücksetzen.
			lda	#NULL
			sta	drivePartData -8,x

			lda	frmtModeFD		;CMD-FD-Laufwerk ?
			beq	:init			; => Nein, weiter...

			lda	curFormatType
			cmp	#Drv1581		;1581 formatieren ?
			bne	:init			; => Nein, weiter...

			lda	optFrmtModeFD
			cmp	#2			;DD8 formatieren ?
			bne	:init			; => Nein, weiter...

			LoadB	r1L,40
			LoadB	r1H,0
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Ersten BAM-Sektor einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	diskBlkBuf		;BAM gültig ?
			bne	:init			; => Ja, weiter...

			jsr	doClearDisk		;Diskette löschen.
;---

;HINWEIS:
;Testen ob Diskette formatiert wurde.
;Dazu Sektor 1/0 einlesen und wieder
;speichern. Abbruch bei Fehler.
;Auch erforderlich für CMD-FD, wenn
;direkt nach dem formatieren die Disk
;erneut formatiert werden soll.
;Aktuell führt das zu einem Fehler:
; -> "DEVICE NOT PRESENT"
;Aufruf der GEOS-MainLoop, Dialogbox,
;Fenster/Laufwerkswechsel oder das
;speichern eines Sektors umgeht den
;Fehler. Weitere Tests erforderlich ?
::init			ldx	#1			;Zeiger auf Sektor #1/0.
			stx	r1L
			dex
			stx	r1H
;			ldx	#< diskBlkBuf
			stx	r4L
			ldx	#> diskBlkBuf
			stx	r4H
			jsr	GetBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch.
			jsr	PutBlock		;Sektor wieder speichern.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch.

			lda	curType
			and	#%00000111
			eor	curFormatType
			sta	flgSlctDrvMode		;Laufwerksmodus wechseln ?
			bne	:exit			; => Ja, Ende...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch.

			bit	optFrmtGEOS		;GEOS-Disk erzeugen?
			bpl	:exit			; => Nein, Ende...

			jsr	SetGEOSDisk		;GEOS-Diskette erzeugen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::exit			ldx	#NO_ERROR
::err			rts

;*** Auf CMD-FD testen
:TestCMDFD		ldx	curDrive
			lda	RealDrvType -8,x
			and	#%11111000
			cmp	#DrvFD			;CMD-FD-Laufwerk ?
			bne	:noFD			; => Nein, weiter...

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#6
			ldx	#< FComGetROM
			ldy	#> FComGetROM
			jsr	SETNAM			;Dateiname = "M-R"-Befehl.

			lda	#10
			ldx	curDrive
			ldy	#15
			jsr	SETLFS			;Daten für Befehlskanal.

			jsr	OPENCHN			;Befehlskanal öffnen.

			lda	#$00			;Fehler-Status löschen.
			sta	STATUS

			ldx	#10
			jsr	CHKIN			;Eingabekanal setzen.

			ldy	#0			;Rückmeldung initialisieren.
			sty	FComReply

::1			lda	STATUS			;Ende erreicht ?
			bne	:2			; => Ja, weiter...
			jsr	GETIN			;ROM-Kennung vom IEC-Bus einlesen
			sta	FComReply		;und speichern.

::2			lda	#10
			jsr	CLOSE			;Befehlskanal schließen.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			lda	FComReply		;ROM-Kennung einlesen.
			cmp	#"2"			;CMD-FD2000 ?
			beq	:cmdFD2			; => Ja, weiter...
			cmp	#"4"			;CMD-FD4000 ?
			bne	:noFD			; => Nein, keine CMD-FD.

::cmdFD4		lda	#%10000000		;CMD-FD4000.
			ldx	#8			;Anzahl Format-Modi.
			bne	:isFD

::cmdFD2		lda	#%01000000		;CMD-FD2000.
			ldx	#6			;Anzahl Format-Modi.

::isFD			ldy	#BOX_ICON		;Format-Optionen CMD-FD aktivieren.
			sty	RegTMenu2c
			ldy	#BOX_OPTION
			sty	RegTMenu2f
			bne	:setMode

::noFD			lda	#$00			;Kein CMD-FD-Laufwerk.
			tax				;Anzahl Format-Modi.

			ldy	#BOX_ICON_VIEW		;Format-Optionen CMD-FD sperren.
			sty	RegTMenu2c
			ldy	#BOX_OPTION_VIEW
			sty	RegTMenu2f

::setMode		sta	frmtModeFD
			stx	maxFormatModes
			rts

;*** Aktuellen Modus übernehmen.
:copyFrmtText		lda	optFrmtModeFD		;Format-Modi = 0/Standard ?
			beq	:1			; => Ja, weiter...
			lda	#","			;Alle anderen Modi: Erweiterung
::1			sta	extFormatType		;für Format-Befehl aktivieren.

			lda	optFrmtModeFD		;Zeiger auf Erweiterung für
			asl				;Format-Befehl berechnen.
			asl
			tax

			ldy	#0			;Erweiterung in Zwischenspeicher
			sty	extFormatType +1
			sty	extFormatType +2
			sty	extFormatType +3

::2			lda	extFormatModes,x	;kopieren.
			beq	:3			; => Ende erreicht, weiter...
			sta	extFormatType +1,y
			inx
			iny
			cpy	#3			;Max. 3 Zeichen kopiert ?
			bcc	:2			; => Nein, weiter...

::3			lda	extFormatModes,x	;Format-Modus zwischenspeichern.
			bne	:4
			lda	curType			;Standard = Aktueller Modus.
			and	#%00000111
::4			sta	curFormatType

			rts

;*** Nächsten Format-Modus wählen.
:slctFrmtMode		ldx	optFrmtModeFD		;Zeiger auf nächsten Modus.
			inx
			cpx	maxFormatModes		;Ende erreicht ?
			bcc	:2			; => Nein, weiter...

::1			ldx	#0			;Laufwerks-Modus zurücksetzen.

::2			cpx	#8
			bcs	:1

			stx	optFrmtModeFD		;Neuen Modus speichern und
			jsr	copyFrmtText

;--- Andere Optionen aktualisieren.
::updOtherOpts		ldx	#BOX_OPTION

			lda	optFrmtModeFD		;Standard-Format ?
			beq	:11			; => Ja, weiter...

			lda	#NULL			;Kein QuickFormat möglich.
			sta	optQuickFrmt

			ldx	#BOX_OPTION_VIEW
::11			stx	RegTMenu2d		;Option "QuickFormat" definieren.

			ldx	#BOX_OPTION

			lda	curType			;Aktueller Laufwerks-Modus.
			and	#%00000111		;Mit neuem Modus vergleichen.
			eor	curFormatType		;Modus unverändert ?
			bne	:12			; => Nein, weiter...

			lda	optFrmtModeFD		;Format-Modus CMD-FD auswerten:

			cmp	#4			;HD8 => Keine GEOS-Disk möglich.
			beq	:12
			cmp	#6			;ED8 => Keine GEOS-Disk möglich.
			bne	:13

::12			lda	#NULL			;Option "GEOS-Disk" deaktivieren.
			sta	optFrmtGEOS

			ldx	#BOX_OPTION_VIEW
::13			stx	RegTMenu2e		;Option "GEOS-Disk" definieren.

;--- Optionen im Menü aktualisieren.
			LoadW	r15,RegTMenu2d
			jsr	RegisterUpdate

			LoadW	r15,RegTMenu2e
			jmp	RegisterUpdate

;*** Format-Befehl definieren.
:editFComFormat		ldx	#3
			ldy	#0			;Disk-Name in Befehl kopieren.
::1			lda	newDiskName,y
			beq	:2
			sta	FComFormat,x
			inx
			iny
			cpy	#16
			bcc	:1

::2			bit	optQuickFrmt		;QuickFormat?
			bmi	:4			; => Ja, Ende...

			lda	#","
			sta	FComFormat,x
			inx

			lda	newDiskID +0		;Disk-ID in Format-Befehl
			beq	:2a			;übertragen.
			ldy	newDiskID +1
			beq	:2b
			bne	:2c

::2a			lda	#DISK_ID_1		;Vorgabe wenn Benutzer-ID = Leer.
			ldy	#DISK_ID_2
			b $2c
::2b			ldy	#"A"			;Vorgabe wenn 2tes Zeichen = Leer.

::2c			sta	FComFormat,x		;Format-ID speichern.
			inx
			tya
			sta	FComFormat,x
			inx

			lda	frmtModeFD		;CMD-FD formatieren ?
			beq	:4			; => Nein, Ende...

			ldy	#0			;CMD-FD-Format in Befehl kopieren.
::3			lda	extFormatType,y
			beq	:4
			cmp	#" "
			beq	:4
			sta	FComFormat,x
			inx
			iny
			cpy	#4
			bcc	:3

::4			stx	FComFormatLen		;Länge Format-Befehl speichern.
			rts

;*** Zurück zu ROOT.
:openRootDrive		ldy	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			jsr	OpenRootDir		; => Hauptverzeichnis öffnen.

			lda	drvUpdFlag		;Laufwerksdaten aktualisieren.
			ora	#%10000000
			sta	drvUpdFlag

			lda	#$01			;Hauptverzeichnis für
			sta	drvUpdSDir +0		;aktuelles Fenster aktivieren.
			sta	drvUpdSDir +1

::1			rts

;*** 1571: Laufwerksmodus festlegen.
:Set1571Mode		bit	optDoubleSided		;1571: Doppelseitig?
			bmi	:set1571S2		; => Ja, weiter...

::set1571S1		ldx	#< FCom1571S1		;1571: SingleSided.
			ldy	#> FCom1571S1
			bne	:setMode

::set1571S2		ldx	#< FCom1571S2		;1571: DoubleSided.
			ldy	#> FCom1571S2

::setMode		lda	#5
:openFComChan		jsr	SETNAM			;Dateiname = "U0>Mx"-Befehl.

			lda	#10
			ldx	curDrive
			ldy	#15
			jsr	SETLFS			;Daten für Befehlskanal.

			jsr	OPENCHN			;Befehlskanal öffnen.

			lda	#10
			jmp	CLOSE

;*** Laufwerk initialisieren.
:sendInitDisk		lda	#3
			ldx	#< FComInitDisk
			ldy	#> FComInitDisk
			jmp	openFComChan

;*** Rückmeldung von Floppy empfangen.
:getDrvStatus		lda	#$00
			tax
			tay
			jsr	SETNAM			;Kein Dateiname.

			lda	#10
			ldx	curDrive
			ldy	#15
			jsr	SETLFS			;Daten für Befehlskanal.

			jsr	OPENCHN			;Befehlskanal öffnen.

			lda	#$00
			sta	STATUS

			ldx	#10
			jsr	CHKIN

			ldy	#0
			sty	FComReply +0
			sty	FComReply +1
			sty	FComReply +2

::1			lda	STATUS
			bne	:2
			jsr	GETIN
			sta	FComReply,y
			iny
			cpy	#3
			bcc	:1

::2			lda	#10
			jmp	CLOSE

;*** Diskette löschen.
:doClearDisk		ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:2			; => Kein NativeMode, weiter...

			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch.

::2			jsr	getMaxTracks		;Max. Anzahl Tracks einlesen.

			bit	optClearDir		;Verzeichnis löschen?
			bpl	:3			; => Nein, weiter...

			jsr	ClearDirHead		;GEOS-Kennung löschen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;HINWEIS:
;Zuerst das Verzeichnis löschen, da
;":ClearBAM" nach dem löschen der BAM
;Verzeichnisblöcke als belegt markiert.
			jsr	ClearDirSek		;Verzeichnis löschen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	ClearBAM		;BAM löschen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

::3			LoadW	r10,newDiskName
			jsr	saveDiskName		;Neuen Disknamen speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			bit	optFrmtGEOS		;GEOS-Disk erzeugen?
			bpl	:4			; => Nein, weiter...

			jsr	SetGEOSDisk		;GEOS-Disk erstellen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch.

::4			bit	optClearSek		;Leere Sektoren löschen?
			bpl	:5			; => Nein, weiter...

			jsr	ClearDataSek		;Freie Sektoren mit 0-Bytes füllen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch.

::5			ldx	#NO_ERROR		;Kein Fehler...
::err			rts				;Ende.

;*** Diskname kopieren.
:copyDiskName		lda	curDrive		;Laufwerksadresse in Optionen
			clc				;übernehmen.
			adc	#"A" -8
			sta	textDrive

			lda	#DISK_ID_1		;Vorgabe-ID definieren.
			ldx	#DISK_ID_2
			sta	newDiskID +0
			stx	newDiskID +1

			jsr	NewDisk			;Diskette öffnen.
			txa				;Fehler?
			bne	:1			; => Ja, Standardname setzen.

			jsr	OpenDisk		;Disk öffnen / Diskname einlesen.
			txa				;Fehler ?
			beq	:2			; => Nein, weiter...

::1			lda	#< textEmptyDisk	;Zeiger auf Standard-Diskname.
			sta	r0L
			lda	#> textEmptyDisk
			sta	r0H
			bne	:5

::2			lda	curDirHead +162		;Disk-ID übernehmen.
			beq	:4
			ldx	curDirHead +163
			bne	:3
			ldx	#"A"
::3			sta	newDiskID +0
			stx	newDiskID +1

::4			ldx	#r0L			;Zeiger auf Diskname einlesen.
			jsr	GetPtrCurDkNm

::5			LoadW	r1,newDiskName		;Zeiger auf Zwischenspeicher.

			ldx	#r0L
			ldy	#r1L
			jmp	SysCopyName		;Diskname kopieren.

;*** GEOS-Header löschen.
:ClearDirHead		ldx	#$ab			;GEOS-Kennung löschen.
			lda	#$00
::1			sta	curDirHead,x
			inx
			cpx	#$be
			bcc	:1

			jmp	PutDirHead		;BAM speichern.

;*** Verzeichnis-Sektoren löschen.
:ClearDirSek		ClrB	firstDirSek		;Erster Sektor.

			lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::err			rts

::1			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
::2			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	diskBlkBuf +0		;Zeiger auf nächsten Verzeichnis-
			pha				;Sektor zwischenspeichern.
			lda	diskBlkBuf +1
			pha

;			ldx	#$00			;Verzeichnis-Sektor löschen.
			txa
::3			sta	diskBlkBuf,x
			inx
			bne	:3

			bit	firstDirSek		;Erster Verzeichnis-Sektor?
			bmi	:4			; => Nein, weiter...
			dec	diskBlkBuf +1		;$00/$FF = Verzeichnis-Ende.
			dec	firstDirSek

::4			jsr	PutBlock		;Verzeichnis-Sektor speichern.

			pla				;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Sektor einlesen.
			pla
			sta	r1L

			cpx	#NO_ERROR		;Fehler?
			bne	:err			; => Ja, Abbruch...

			tax				;Weitere Verzeichnis-Sektor?
			bne	:2			; => Ja, weiter...

;			ldx	#NO_ERROR		;Kein Fehler.
			rts				;Ende.

;*** Datensektoren löschen.
:ClearDataSek		LoadB	statusPos,$00		;Zeiger auf erste Spur.
			lda	maxTrack
			sta	statusMax
			jsr	DrawStatusBox		;Status-Box anzeigen.
			jsr	prntDiskInfo		;Disk-/Verzeichnisname ausgeben.

			ClrB	lastTrack		;Aktuellen Track löschen.

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#$00			;Datensektor löschen.
			txa
;			lda	#$fd			;Dummy-Wert für Debugging.
::1			sta	diskBlkBuf,x
			inx
			bne	:1

			ldx	#$01			;Zeiger auf ersten Disksektor.
			stx	r1L
			dex
			stx	r1H

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.

::loop			lda	r1L
			cmp	lastTrack		;Track anzeigen?
			beq	:2			; => Nein, weiter...

			sta	lastTrack		;Neuen Track speichern.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			jsr	updateStatus		;Status aktualisieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			inc	statusPos

::2			MoveB	r1L,r6L
			MoveB	r1H,r6H
			jsr	FindBAMBit		;Ist Sektor frei?
			beq	:3			; => Nein, weiter...

			jsr	WriteBlock		;Sektor löschen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch..

::3			jsr	GetNextSekAdr		;Zeiger auf nächsten Sektor.
			txa				;Weiterer Sektor verfügbar?
			beq	:loop			; => Ja, weiter...

			ldx	#NO_ERROR		;Kein Fehler.

::exit			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Variablen für Format-/ClearDisk.
:formatMode		b $00				;$00=Disk löschen / $FF=Formatieren.
:newDiskName		s 17
:newDiskID		b "64",NULL

;*** Variablen für FormatDisk.
:frmtModeFD		b $00
:flgSlctDrvMode		b $00
:flgSlctPartMode	b $0

:optQuickFrmt		b $00 ;$FF = QuickFormat ohne ID.
:optFrmtGEOS		b $00 ;$FF = GEOS-Disk erstellen.
:optDoubleSided		b $ff ;$FF = 1571/Doppelseitig.

;*** Floppy-Befehle.
:FCom1571S1		b "U0>M0"
:FCom1571S2		b "U0>M1"

:FComInitDisk		b "I0:"
:FComReply		s $03

:FComGetROM		b "M-R"
			w $fef0
			b 1

;*** Format-Befehl.
:FComFormat
::formatCom		b "N0:"
:frmtString
::formatName		s 16
::formatID		s 3
::formatFD		s 4
			b NULL
:FComFormatLen		b $00

;*** CMD-FD Format-Optionen.
:maxFormatModes		b $00
:extFormatType		b ",HD8"
			b NULL

:extFormatModes		b "STD",NULL
			b "81" ,NULL,Drv1581
			b "DD8"     ,Drv1581
			b "DDN"     ,DrvNative
			b "HD8"     ,Drv1581
			b "HDN"     ,DrvNative
			b "ED8"     ,Drv1581
			b "EDN"     ,DrvNative

:optFrmtModeFD		b $00
:curFormatType		b $00

;*** Variablen für ClearDisk.
:optClearDir		b $ff
:optClearSek		b $00
:firstDirSek		b $00
:lastTrack		b $00

;*** Texte für Format/ClearDisk-Warnung.
:textDrive		b "A:"
			b PLAINTEXT
			b NULL

if LANG = LANG_DE
:textEmptyDisk		b "LEERDISK",NULL
endif
if LANG = LANG_EN
:textEmptyDisk		b "EMPTY",NULL
endif

;*** Dialogbox: Diskette formatieren/löschen?
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
			b DBTXTSTR   ,$26,$2e
			w frmtString
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
:warnText1		b BOLDON
			b "WARNUNG: "
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
:warnText1		b BOLDON
			b "WARNING: "
			b PLAINTEXT
			b "",NULL
:warnText2		b "This operation cannot be undone!",NULL
endif

;*** Info: DiskImage erstellt, nicht kompatibel!
:Dlg_InfoFDErr		b %01100001
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
			b "CMD-Disk erfolgreich erstellt!",NULL
::3			b PLAINTEXT
			b "Das erstellte CMD-Format ist nicht mit",NULL
::4			b "dem Laufwerk kompatibel!",NULL
::5			b "GD.CONFIG starten und Laufwerk ändern",NULL
::6			b "oder 'Treiber-in-RAM' aktivieren.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT,BOLDON
			b "CMD disk successfully created!",NULL
::3			b PLAINTEXT
			b "The created CMD format is not",NULL
::4			b "compatibel with the current drive!",NULL
::5			b "Open GD.CONFIG and change disk drive",NULL
::6			b "or enable 'Load drivers into RAM'.",NULL
endif

;*** Endadresse testen:
			g RegMenuBase
;***
