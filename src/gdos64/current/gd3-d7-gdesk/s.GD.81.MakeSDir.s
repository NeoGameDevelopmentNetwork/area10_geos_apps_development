; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* NativeMode-Verzeichnis erstellen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
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
endif

;*** GEOS-Header.
			n "obj.GD81"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xCREATE_NM_DIR

;*** Programmroutinen.
			t "-Gxx_MakeDir"

;*** Systemroutinen.
			t "-SYS_DISKFILE"
			t "-SYS_STATMSG"

;*** Verzeichnis erstellen.
:xCREATE_NM_DIR		LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	bit	exitCode		;Weiteres Verzeichnis erstellen?
			bpl	:1			; => Nein, Ende...
			jmp	xCREATE_NM_DIR		;Weiter mit nächstem Verzeichnis.

::1			jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;--- HINWEIS:
;Hier wird nur das aktuelle Fenster
;aktualisiert. Alternativ kann man auch
;alle Fenster des gleichen Laufwerks
;aktualisieren (wegen Statuszeile).
if FALSE
			lda	curDrive		;Laufwerksadresse einlesen und
			sta	sysSource		;alle Fenster aktualisieren.
			jmp	MOD_UPDATE_WIN		;Zurück zum Hauptmenü.
endif

;*** Icon "DiskInfo" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	lda	newDirName		;Verzeichnisname vorhanden?
			beq	:cancel			; => Nein, Ende...

			jsr	doDirJob		;Verzeichnis erstellen.
			cpx	#$ff			;Zurück zum RegisterMenü?
			beq	:exit			; => Ja, weiter...

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
			beq	:1			; => Kein Fehler, weiter...

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;TurboDOS entfernen.

::cancel		ldx	#$00			;Kein weiteres Verzeichnis.
			rts

::1			;ldx	#$00			;XReg ist bereits = $00.
			bit	createNextDir		;Weitere Verzeichnisse erstellen?
			bpl	:exit			; => Nein, Ende...

			ldx	#$ff			;Nächstes Verzeichnis erstellen.
::exit			rts

;*** Register-Menü.
:R1SizeY0 = $28
:R1SizeY1 = $9f
:R1SizeX0 = $0028
:R1SizeX1 = $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "VERZEICHNIS".
			w RegTMenu1

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
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
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** System-Icons.
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

;*** Daten für Register "VERZEICHNIS".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RTab1_1  = $0048
:RLine1_1 = $00
:RLine1_2 = $30
:RLine1_3 = $40

:RegTMenu1		b 5

			b BOX_ICON
				w R1T01
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_Create
				b NO_OPT_UPDATE

			b BOX_FRAME
				w R1T02
				w $0000
				b RPos1_y +$28
				b R1SizeY1 -$24 +$02
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING
				w R1T03
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_1
				w newDirName
				b 16

			b BOX_OPTION
				w R1T04
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x
				w autoOpenDir
				b %11111111

			b BOX_OPTION
				w R1T05
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x
				w createNextDir
				b %11111111

;*** Texte für Register "VERZEICHNIS".
if LANG = LANG_DE
:R1T00			b "AKTIONEN",NULL

:R1T01			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Neues Verzeichnis"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "erstellen",NULL

:R1T02			b "OPTIONEN",NULL

:R1T03			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Verzeichnis:"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_1 +$11
			b "BASIC-kompatible Verzeichnisse"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_1 +$1a
			b "nur mit Großbuchstaben erstellen!",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Verzeichnis automatisch öffnen",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Weitere Verzeichnisse erstellen",NULL
endif
if LANG = LANG_EN
:R1T00			b "ACTIONS",NULL

:R1T01			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$06
			b "Create new"
			b GOTOXY
			w R1SizeX0 +$10 +$14
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "directory",NULL

:R1T02			b "OPTIONS",NULL

:R1T03			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Directory:"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_1 +$11
			b "Create BASIC-compatible directories"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_1 +$1a
			b "with uppercase letters only!",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Automatically open directory",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Create additional directories",NULL
endif

;*** Verzeichnisse erstellen.
:doDirJob		LoadW	r6,newDirName		;Zeiger auf Verzeichnis-Name.
			jsr	FindFile		;Datei auf Disk suchen.
			cpx	#FILE_NOT_FOUND		;Datei nicht vorhanden?
			beq	:1			; => Ja, weiter...
			cpx	#NO_ERROR		;Datei vorhanden?
			bne	:exit			; => Nein, Abbruch...

			LoadW	r0,Dlg_ErrExist		;Fehler:
			jsr	DoDlgBox		;Datei existiert bereits.

			ldx	#$ff			;Zurück zum RegisterMenü.
::exit			rts

::1			jsr	MakeNDir		;Verzeichnis erstellen.
			txa				;Fehler?
			bne	:exit			; => Ja, Ende...

;--- Verzeichnis automatisch öffnen.
			bit	autoOpenDir		;Verzeichnis automatisch öffnen?
			bpl	:exit			; => Nein, weiter...

			LoadW	r6,newDirName
			jsr	FindFile		;Verzeichnis auf Disk suchen.
			txa				;Gefunden?
			bne	:exit			; => Nein, Abbruch...

			lda	drvUpdFlag		;Fensterdaten aktualisieren.
			ora	#%10000000
			sta	drvUpdFlag

			lda	dirEntryBuf +1		;Verzeichnis-Track/Sektor einlesen
			sta	r1L			;und Verzeichnis in System anmelden.
			sta	drvUpdSDir +0
			lda	dirEntryBuf +2
			sta	r1H
			sta	drvUpdSDir +1

			jmp	OpenSubDir		;Verzeichnis öffnen.

;*** Variablen.
:autoOpenDir		b $00
:createNextDir		b $00
:newDirName		s 17

;*** Fehler: Verzeichnis-Name bereits vergeben.
:Dlg_ErrExist		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w newDirName
			b DBTXTSTR   ,$0c,$40
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Kann das Verzeichnis nicht erstellen!",NULL
::3			b BOLDON
			b "Name:",PLAINTEXT,NULL
::4			b "Verzeichnisname bereits vergeben!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Cannot create directory!",NULL
::3			b BOLDON
			b "Name:",PLAINTEXT,NULL
::4			b "Directory name already exist!",NULL
endif

;*** Endadresse testen:
			g RegMenuBase
;***
