; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskette aufräumen.
:xVALIDATE		ldy	#$00			;NativeMode-Verz. nicht testen.
			ldx	curDrive		;Aktuelles Laufwerk einlesen.
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1
			dey				;NativeMode-Verz. testen.
::1			sty	ChkNMSubD		;SubDir-Option festlegen.
			tya
			bne	:2

			lda	#BOX_OPTION_VIEW	;SubDir-Option bei nicht-Native
			b $2c				;Laufwerken deaktivieren.
::2			lda	#BOX_OPTION		;SubDir-Option aktivieren.
			sta	RTabMenu1_1a

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	WM_LOAD_BACKSCR		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskCopy ausführen?
			cmp	#$7f
			bne	:exit			; => Nein, Ende...

			jsr	doValidateJob		;Diskette aufräumen.
			txa				;Fehler?
			beq	:done			; => Nein, Ende...

			cpx	#$fe			;Abbruch durch Anwender?
			beq	:cancel

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
;			txa				;Fehlercode zwischenspeichern.
;			pha
;			jsr	WM_LOAD_BACKSCR		;Bildschirminhalt zurücksetzen.
;			pla
;			tax				;Fehlercode wiederherstellen.

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.
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

;*** Variablen.
:autoOpenDir		b $00
:createNextDir		b $00
:newDirName		s 17

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
			b "Operation was aborted by user!",NULL
::3			b BOLDON
			b "WARNING!",NULL
::4			b PLAINTEXT
			b "Saving data on this drive can result",NULL
::5			b "in data loss!",NULL
::6			b "VALIDATING THE DISK IS RECOMMENDED!!!",NULL
endif

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $28
:R1SizeY1		= $a7
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RTabName1_1			;Register: "VALIDATE".
			w RTabMenu1_1

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

;*** Icons "OK"/"Abbruch".
:RIcon_Start		w IconStart
			b $00,$00
			b IconStart_x,IconStart_y
			b $01

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "VALIDATE".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$18
:RWidth1  = $0050
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $20
:RLine1_4 = $38

:RTabMenu1_1		b 6

			b BOX_ICON			;----------------------------------------
				w R1T01
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_Start
				b $00

			b BOX_FRAME			;----------------------------------------
				w R1T02
				w $0000
				b RPos1_y -$08
				b R1SizeY1 -$24 +$02
				w R1SizeX0 +$08
				w R1SizeX1 -$08

:RTabMenu1_1a		b BOX_OPTION			;----------------------------------------
				w R1T03
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x
				w ChkNMSubD
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T04
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x
				w ChkFileSize
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T05
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x
				w KillErrorFile
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T06
				w $0000
				b RPos1_y +RLine1_4
				w RPos1_x
				w CloseFiles
				b %11111111

if LANG = LANG_DE
:R1T00			b "AKTIONEN",NULL

:R1T01			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Diskette"
			b GOTOXY
			w R1SizeX0 +$10 +$18
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

:R1T01			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Validate"
			b GOTOXY
			w R1SizeX0 +$10 +$18
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

;*** Icons für Registerkarten.
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;RTabIcon2

;RTabIcon2_x		= .x
;RTabIcon2_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** Register-Funktions-Icons.
:IconStart
<MISSING_IMAGE_DATA>

:IconStart_x		= .x
:IconStart_y		= .y
