; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien löschen.
:xFILE_DELETE		php				;Tastaturabfrage:
			sei				;Linke/Rechte SHIFT-Taste für
			ldx	CPU_DATA		;Dateien duplizieren.
			lda	#$35
			sta	CPU_DATA
			ldy	#%00111101
			sty	CIA_PRA
			ldy	CIA_PRB
			stx	CPU_DATA
			plp

			sty	keyMode			;Tastenstatus zwischenspeichern.

			cpy	#%11011111		;C= Taste gedrückt?
			bne	:1

			lda	#$00			;C= Taste gedrückt...
			sta	GD_DEL_MENU		;AutoDelete-Flag löschen.

::1			jsr	COPY_FILE_NAMES		;Dateinamen in Speicher kopieren.

			LoadB	switchFile,$00		;Zeiger auf erste Datei.
			LoadW	curFileVec,SYS_FNAME_BUF

			ldx	slctFiles		;Dateien ausgewählt?
			beq	ExitRegMenuUser		; => Nein, Ende...
			dex				;Mehr als 1 Datei?
			beq	:do_single		; => Ja, weiter...

;--- Mehrere Dateien löschen.
::do_multiple		jsr	i_MoveData		;Vorgabe: "Mehrere Dateien löschen".
			w	multipleFiles
			w	curFileName
			w	16

			lda	#$ff
			bne	:2

;--- Einzelne Datei löschen.
::do_single		jsr	i_MoveData		;Vorgabe: "Einzelne Datei löschen".
			w	SYS_FNAME_BUF
			w	curFileName
			w	16

			lda	#$00

;--- Register-Menü initialisieren.
::2			sta	switchFile		;Einzelne Datei/Mehrere Dateien.

			lda	keyMode			;Tastenstatus wieder einlesen.
			and	#%10010000		;SHIFT Links oder Rechts gedrückt?
			cmp	#%10010000
			bne	:2a			; => Ja, direkt löschen...

			bit	GD_DEL_MENU		;Ohne Nachfragen löschen?
			bpl	:3			; => Nein, weiter...

::2a			jsr	ExecRegMenuUser		;Dateien löschen.
			stx	exitCode		;Rückgabewert speichern.
			jmp	ExitRegMenuUser		;Zurück zum DeskTop.

::3			ClrB	reloadDir		;Flag löschen "Verzeichnis laden".

;--- Register-Menü anzeigen.
			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	WM_LOAD_BACKSCR		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskCopy ausführen?
			cmp	#$7f
			bne	:2			; => Nein, Ende...

			jsr	doDeleteJob		;Dateien löschen.
			txa				;Fehler?
			beq	:1			; => Nein, Ende...

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

::1			bit	reloadDir		;Verzeichnis neu laden?
			bpl	:2			; => Nein, weiter...

			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::2			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "Dateien löschen" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
			rts

;*** Variablen.
:keyMode		b $00

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $28
:R1SizeY1		= $9f
:R1SizeX0		= $0028
:R1SizeX1		= $010f

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

;*** Icons "Löschen"/"Abbruch".
:RIcon_Delete		w IconDelete
			b $00,$00
			b IconDelete_x,IconDelete_y
			b $01

;*** Icon für Seitenwechsel.
:RIcon_Page		w IconSlctPage
			b $00,$00
			b IconSlctPage_x,IconSlctPage_y
			b $01

:PosSlctPage_x		= (R1SizeX1 +1) -$10
:PosSlctPage_y		= (R1SizeY1 +1) -$10

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "LÖSCHEN".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RWidth1  = $0048
:RLine1_1 = $00
:RLine1_2 = $20
:RLine1_3 = $30

:RTabMenu1_1		b 6

			b BOX_ICON			;----------------------------------------
				w $0000
				w SwitchPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_Page
				b $00

			b BOX_ICON			;----------------------------------------
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_Delete
				b $00

			b BOX_STRING			;----------------------------------------
				w R1T01
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1
				w curFileName
				b 16

			b BOX_FRAME			;----------------------------------------
				w R1T02
				w $0000
				b RPos1_y +RLine1_2 -$08
				b R1SizeY1 -$24 +$02
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_OPTION			;----------------------------------------
				w R1T03
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x
				w GD_DEL_EMPTY
				b %11111111

			b BOX_OPTION			;----------------------------------------
				w R1T04
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x
				w GD_DEL_MENU
				b %11111111

if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Dateien"
			b GOTOXY
			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "löschen",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Dateiname:",NULL

:R1T02			b "OPTIONEN",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Nur leere Verzeichnisse löschen",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Dateien ohne Nachfragen löschen"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$0f
			b "Im PopUp-Menü C=Taste drücken"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$18
			b "um Nachfragen einzuschalten.",NULL
endif
if LANG = LANG_EN
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Delete"
			b GOTOXY
			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$08 +$06
			b "files",NULL

:R1T01			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Filename:",NULL

:R1T02			b "OPTIONS",NULL

:R1T03			w RPos1_x +$10
			b RPos1_y +RLine1_2 +$06
			b "Delete empty directories only",NULL

:R1T04			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "Delete files without prompting"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$0f
			b "Press C= key in popup menu to"
			b GOTOXY
			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$18
			b "enable asking for delete files.",NULL
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

;RTabIcon2

;RTabIcon2_x		= .x
;RTabIcon2_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
;RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** Register-Funktions-Icons.
:IconDelete
<MISSING_IMAGE_DATA>

:IconDelete_x		= .x
:IconDelete_y		= .y

:IconSlctPage
<MISSING_IMAGE_DATA>

:IconSlctPage_x		= .x
:IconSlctPage_y		= .y
