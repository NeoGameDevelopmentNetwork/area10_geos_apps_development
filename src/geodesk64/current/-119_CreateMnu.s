; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DiskImage erstellen.
:xCREATE_DIMG		ldx	curDrive		;Format-Mode ermitteln.
			lda	driveType -8,x		;Dazu Laufwerksmodus einlesen und
			and	#%0000 1111		;in Option für das Register-Menü
			tay				;konvertiere.
			lda	formatModeTab,y
			sta	formatMode

			jsr	createDiskName		;Vorgabe Name DiskImage erzeugen.

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	WM_LOAD_BACKSCR		;Bildschirm zurücksetzen.

			lda	exitCode		;DiskImage erstellen?
			cmp	#$7f
			bne	:2			; => Nein, Ende...

			jsr	doCreateJob		;DiskImage erstellen.
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

;*** Icon "DiskImmage erstellen" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#$7f
			rts

;*** Variablen.
:reloadDir		b $00				;GeoDesk/Verzeichnis neu laden.

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

			w RTabName1_1			;Register: "LÖSCHEN".
			w RTabMenu1_1

;*** Registerkarten-Icons.
:RTabName1_1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

;*** Icons "Image erstellen".
:RIcon_Delete		w IconCreate
			b $00,$00
			b IconCreate_x,IconCreate_y
			b $01

:RIcon_Add64K		w IconAdd64K
			b $00,$00
			b IconAdd64K_x,IconAdd64K_y
			b $01
:RIcon_Sub64K		w IconSub64K
			b $00,$00
			b IconSub64K_x,IconSub64K_y
			b $01
:RIcon_NextStd		w IconNext
			b $00,$00
			b IconNext_x,IconNext_y
			b $01

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Daten für Register "DISK IMAGE".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$08
:RWidth1  = $0050
:RWidth2  = $0068
:RWidth3  = $0068
:RLine1_1 = $00
:RLine1_2 = $20
:RLine1_3 = $30
:RLine1_4 = $50

:RTabMenu1_1		b 15

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
				w diskImgName
				b 12

			b BOX_FRAME			;----------------------------------------
				w R1T02
				w $0000
				b RPos1_y +RLine1_2 -$08
				b RPos1_y +RLine1_3 +$08 +$04
				w R1SizeX0 +$08
				w R1SizeX1 -$08

:modeD64		b BOX_OPTION			;----------------------------------------
				w R1T03
				w SlctD64
				b RPos1_y +RLine1_2
				w RPos1_x
				w formatMode
				b %00000001

:modeD71		b BOX_OPTION			;----------------------------------------
				w R1T04
				w SlctD71
				b RPos1_y +RLine1_2
				w RPos1_x +RWidth2
				w formatMode
				b %00000010

:modeD81		b BOX_OPTION			;----------------------------------------
				w R1T05
				w SlctD81
				b RPos1_y +RLine1_3
				w RPos1_x
				w formatMode
				b %00000100

			b BOX_FRAME			;----------------------------------------
				w R1T06
				w $0000
				b RPos1_y +RLine1_4 -$08
				b R1SizeY1 -$24 +$02
				w R1SizeX0 +$08
				w R1SizeX1 -$08

:modeDNP		b BOX_OPTION			;----------------------------------------
				w R1T07
				w SlctDNP
				b RPos1_y +RLine1_4
				w RPos1_x
				w formatMode
				b %00001000

			b BOX_FRAME			;----------------------------------------
				w $0000
				w $0000
				b RPos1_y +RLine1_4 -$01
				b RPos1_y +RLine1_4 +$08
				w RPos1_x +RWidth3 -$01
				w R1SizeX1 -$08 -$08 +$01
			b BOX_USER			;----------------------------------------
				w R1T08
				w $0000 ;printImgSize
				b RPos1_y +RLine1_4 -$01
				b RPos1_y +RLine1_4 +$08
				w RPos1_x +RWidth3
				w R1SizeX1 -$08 -$08 -$18
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PrntCurSize
				b RPos1_y +RLine1_4
				b RPos1_y +RLine1_4 +$07
				w RPos1_x +RWidth3
				w R1SizeX1 -$08 -$08 -$18
			b BOX_ICON			;----------------------------------------
				w $0000
				w Sub64K
				b RPos1_y +RLine1_4
				w R1SizeX1 -$08 -$08 -$18 +$01
				w RIcon_Sub64K
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w NextStd
				b RPos1_y +RLine1_4
				w R1SizeX1 -$08 -$08 -$10 +$01
				w RIcon_NextStd
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w Add64K
				b RPos1_y +RLine1_4
				w R1SizeX1 -$08 -$08 -$08 +$01
				w RIcon_Add64K
				b $00

			b BOX_OPTION			;----------------------------------------
				w R1T09
				w $0000
				b (R1SizeY1 +1) -$18
				w R1SizeX1 -$08 -$08 +$01
				w GD_SD_COMPAT_WARN
				b %11111111

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
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

:R1T08			w RPos1_x +RWidth3 -$40
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

:R1T08			w RPos1_x +RWidth3 -$40
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

:R1T04			w RPos1_x +RWidth2 +$10
			b RPos1_y +RLine1_2 +$06
			b "D71 1571/340Kb",NULL

:R1T05			w RPos1_x +$10
			b RPos1_y +RLine1_3 +$06
			b "D81 1581/790Kb",NULL

:R1T06			b "NATIVE MODE",NULL

:R1T07			w RPos1_x +$10
			b RPos1_y +RLine1_4 +$06
			b "DNP",NULL

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
:IconCreate
<MISSING_IMAGE_DATA>

:IconCreate_x		= .x
:IconCreate_y		= .y

:IconSub64K
<MISSING_IMAGE_DATA>

:IconSub64K_x		= .x
:IconSub64K_y		= .y

:IconAdd64K
<MISSING_IMAGE_DATA>

:IconAdd64K_x		= .x
:IconAdd64K_y		= .y

:IconNext
<MISSING_IMAGE_DATA>

:IconNext_x		= .x
:IconNext_y		= .y
