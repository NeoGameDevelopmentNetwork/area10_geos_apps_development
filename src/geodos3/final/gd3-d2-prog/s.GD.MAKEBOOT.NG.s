; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_DBOX"

;--- Laufwerkstreiber-Modus:
;Modus: GD.DISK.xx
;Verwendet StandAlone Laufwerkstreiber.
:GD_NG_MODE		= TRUE
endif

;*** GEOS-Header.
			n "GD.MAKEBOOT"
			t "G3_Appl.V.Class"
			z $80				;nur GEOS64

			o APP_RAM

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Installiert auf der"
			h "Startdiskette einen neuen"
			h "Laufwerkstreiber..."
endif
if Sprache = Englisch
			h "Install new diskdriver"
			h "on your bootdisk..."
endif

;*** Auf GEOS-MegaPatch testen.
;    GEOS-Boot mit MP3: Rückkehr zum Hauptprogramm.
;    GEOS-Boot mit V2x: Sofortiges Programm-Ende.
;    Programmstart V2x: Fehler ausgeben, zurück zum DeskTop.
:MainInit		jsr	FindGD3			;GD3/M3-Kernal suchen.
			jsr	ClearScreen		;Bildschirm löschen und

::done			LoadW	r0,Dlg_PatchOK		;Abschlußmeldung ausgeben.
			jsr	DoDlgBox

			jmp	EnterDeskTop		;Ende...

;*** Bildschirm löschen.
:ClearScreen		lda	#ST_WR_FORE		;Bildschirm löschen.
			sta	dispBufferOn

			jmp	GetBackScreen

;*** Dialogbox: Titelzeile ausgeben.
:Dlg_DrawTitle		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$20,$2f
			w	$0040,$00ff
			lda	#$10
			jmp	DirectColor

;******************************************************************************
;*** GD.MAKEBOOT- Systemroutinen
;******************************************************************************
			t "-G3_FindGD"
;******************************************************************************

;*** Dialogbox für "Startdiskette konfiguriert".
:Dlg_PatchOK		b %01100001
			b $20,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitle
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$20
			w :52
			b DBTXTSTR   ,$10,$2a
			w :53
			b DBTXTSTR   ,$10,$34
			w :54
			b DBTXTSTR   ,$10,$44
			w :60
			b DBTXTSTR   ,$10,$4e
			w :61
			b DBTXTSTR   ,$10,$58
			w :62
			b OK         ,$02,$60
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT,BOLDON
			b "GD.MAKEBOOT",NULL
::52			b "NICHT MEHR ERFORDERLICH!",NULL
::53			b PLAINTEXT
			b "Sie können GeoDOS64 jederzeit von",NULL
::54			b "dieser Diskette starten.",NULL
::60			b BOLDON
			b "HINWEIS: ",PLAINTEXT
			b "Eine Startdiskette benötigt",NULL
::61			b "zusätzlich eine DeskTop-Anwendung,",NULL
::62			b "z.B. eine Datei `GEODESK` !",NULL
endif

if Sprache = Englisch
::51			b PLAINTEXT,BOLDON
			b "GD.MAKEBOOT",NULL
::52			b "NOT NEEDED ANYMORE!",NULL
::53			b PLAINTEXT
			b "You can boot GeoDOS64 from this",NULL
::54			b "boot disk at any time.",NULL
::60			b BOLDON
			b "NOTE: ",PLAINTEXT
			b "A full bootdisk also requires",NULL
::61			b "a desktop application, for example",NULL
::62			b "a file called `GEODESK` !",NULL
endif
