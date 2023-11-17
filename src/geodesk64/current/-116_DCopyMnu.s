; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

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

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

			ldx	#$ff
::exit			stx	exitCode		;Zurück zum DeskTop.
;			jmp	ExitRegMenuUser

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	WM_LOAD_BACKSCR		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskCopy ausführen?
			cmp	#$7f
			bne	:2			; => Nein, Ende...

			jsr	doCopyJob		;Diskette kopieren.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
;			txa				;Fehlercode zwischenspeichern.
			pha
			jsr	WM_LOAD_BACKSCR		;Bildschirminhalt zurücksetzen.
			pla
			tax				;Fehlercode wiederherstellen.

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

::1			lda	#$00			;Source-Laufwerk löschen, damit
			sta	sysSource		;Fenster nicht aktualisiert wird.
			sta	winSource
			sta	updateSource

			bit	reloadDir		;Verzeichnis neu laden?
			bpl	:2			; => Nein, weiter...

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

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Register-Tabelle.
:R1SizeY0		= $20
:R1SizeY1		= $a7
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RTabName1_1			;Register: "DISKCOPY".
			w RTabMenu1_1

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

;*** Icon "DiskCopy".
:RIcon_DiskCopy		w IconDiskCopy
			b $00,$00
			b IconDiskCopy_x,IconDiskCopy_y
			b $01

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DISKCOPY".
:DIGIT_2_BYTE		= $03 ! NUMERIC_RIGHT ! NUMERIC_SET0 ! NUMERIC_BYTE
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RWidth1a  = $0030
:RWidth1b  = $0048
:RWidth1c  = $00b0
:RLine1_1 = $08
:RLine1_2 = $08
:RLine1_3 = $38
:RLine1_4 = $38
:RLine1_5 = $18
:RLine1_6 = $48

:RTabMenu1_1		b 11

			b BOX_ICON			;----------------------------------------
				w R1T00
				w EXEC_REG_ROUT
				b (R1SizeY1 +1) -$18
				w R1SizeX0 +$10
				w RIcon_DiskCopy
				b $00

::source		b BOX_FRAME			;----------------------------------------
				w R1T01
				w $0000
				b RPos1_y +RLine1_1 -$05
				b RPos1_y +RLine1_2 +$18 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_STRING_VIEW		;----------------------------------------
				w R1T02
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RWidth1a
				w sourceDrvText
				b 2

			b BOX_STRING_VIEW		;----------------------------------------
				w $0000
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth1b
				w sourceDrvDisk
				b 16

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R1T06
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RWidth1c
				w sysSource +1
				b DIGIT_2_BYTE

::target		b BOX_FRAME			;----------------------------------------
				w R1T04
				w $0000
				b RPos1_y +RLine1_3 -$05
				b RPos1_y +RLine1_4 +$20 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

			b BOX_USER_VIEW			;----------------------------------------
				w $0000
				w initTargetDkNm
				b RPos1_y +RLine1_3
				b RPos1_y +RLine1_3 +$07
				w RPos1_x +RWidth1a
				w RPos1_x +RWidth1a +$0f

			b BOX_STRING_VIEW		;----------------------------------------
				w R1T05
				w $0000
				b RPos1_y +RLine1_3
				w RPos1_x +RWidth1a
				w targetDrvText
				b 2

:RTabMenu1_1b		b BOX_STRING			;----------------------------------------
				w $0000
				w setFlagDskName
				b RPos1_y +RLine1_4
				w RPos1_x +RWidth1b
				w targetDrvDisk
				b 16

			b BOX_NUMERIC_VIEW		;----------------------------------------
				w R1T07
				w $0000
				b RPos1_y +RLine1_6
				w RPos1_x +RWidth1c
				w sysTarget +1
				b DIGIT_2_BYTE

:RTabMenu1_1a		b BOX_OPTION			;----------------------------------------
				w R1T08
				w updateDiskName
				b RPos1_y +RLine1_6
				w RPos1_x +RWidth1a +$08
				w flagRenameDisk
				b %11111111

if LANG = LANG_DE
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Diskette"
			b GOTOXY
			w R1SizeX0 +$10 +$18
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

:R1T06			w RPos1_x +RWidth1b
			b RPos1_y +RLine1_5 +$06
			b "CMD-Partition:",NULL

:R1T07			w RPos1_x +RWidth1b
			b RPos1_y +RLine1_6 +$06
			b "CMD-Partition:",NULL

:R1T08			w RPos1_x
			b RPos1_y +RLine1_6 +$06
			b "Diskname"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_6 +$08 +$06
			b "behalten",NULL
endif
if LANG = LANG_EN
:R1T00			w R1SizeX0 +$10 +$18
			b (R1SizeY1 +1) -$18 +$06
			b "Copy"
			b GOTOXY
			w R1SizeX0 +$10 +$18
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

:R1T06			w RPos1_x +RWidth1b
			b RPos1_y +RLine1_5 +$06
			b "CMD-Partition:",NULL

:R1T07			w RPos1_x +RWidth1b
			b RPos1_y +RLine1_6 +$06
			b "CMD-Partition:",NULL

:R1T08			w RPos1_x
			b RPos1_y +RLine1_6 +$06
			b "Keep old"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_6 +$08 +$06
			b "disk name",NULL
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
:IconDiskCopy
<MISSING_IMAGE_DATA>

:IconDiskCopy_x		= .x
:IconDiskCopy_y		= .y
