; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#205.obj"
			o	ModStart
			r	EndAreaCBM

			jmp	DoCopyError

;*** Kopierfehler anzeigen.
:DoCopyError		stx	ExitToErrBox +1

			ldx	#$ff			;Zurück zur MainLoop.
			txs
			lda	#>MainLoop -1
			pha
			lda	#<MainLoop -1
			pha

			lda	#$00
			sta	appMain        +0
			sta	appMain        +1
			sta	intBotVector   +0
			sta	intBotVector   +1
			sta	keyVector      +0
			sta	keyVector      +1
			sta	inputVector    +0
			sta	inputVector    +1
			sta	mouseFaultVec  +0
			sta	mouseFaultVec  +1
			sta	otherPressVec  +0
			sta	otherPressVec  +1
			sta	StringFaultVec +0
			sta	StringFaultVec +1
			sta	alarmTmtVector +0
			sta	alarmTmtVector +1
			LoadW	RecoverVector,RecoverRectangle
			LoadB	selectionFlash,$0a
			LoadB	alphaFlag,%00000000
			LoadB	iconSelFlag,ST_FLASH

			jsr	InitForIO		;Bildschirm löschen.
			ClrB	$d020
			LoadB	$d027,$0d
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00
			jsr	ClrBitMap

			jsr	UseGDFont		;GeoDOS-Zeichensatz aktivieren.
			ClrB	currentMode

			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0010
			b	$30
			b	RECTANGLETO
			w	$012f
			b	$8f
			b	FRAME_RECTO
			w	$0010
			b	$30
			b	NULL

			jsr	i_ColorBox
			b	$02,$06,$24,$0c,$12

			PrintStrgV205a0			;Fehlermeldung ausgeben.

			jsr	i_ColorBox
			b	$03,$0f,$06,$02,$01

			LoadW	r0,icon_Tab1
			jsr	DoIcons			;Menü starten.
			StartMouse			;Mausabfrage aktivieren.
			NoMseKey			;Warten bis keine Maustaste gedrückt.
			rts

;*** Zurück zu GeoDOS.
:ExitErrDlg		jsr	i_ColorBox
			b	$00,$00,$28,$19,$00
			jsr	ClrBitMap

:ExitToErrBox		ldx	#$ff			;Diskettenfehler anzeigen.
			jmp	DiskError

if Sprache = Deutsch
;*** Variablen & Texte.
:V205a0			b GOTOXY
			w 100
			b 64
			b "! A C H T U N G !"
			b GOTOXY
			w 24
			b 78
			b "Es ist ein Diskettenfehler aufgetreten."
			b GOTOXY
			w 24
			b 86
			b "Nicht alle Dateien wurden kopiert."
			b GOTOXY
			w 24
			b 94
			b "Unter GeoDOS die Funktion 'Diskette"
			b GOTOXY
			w 24
			b 102
			b "aufräumen' ausführen um den bereits"
			b GOTOXY
			w 24
			b 110
			b "belegten Speicher wieder freizugeben!"
			b GOTOXY
			w 80
			b 128
			b "Diskettenfehler anzeigen"
			b NULL
endif

if Sprache = Englisch
;*** Variablen & Texte.
:V205a0			b GOTOXY
			w 100
			b 64
			b "! W A R N I N G !"
			b GOTOXY
			w 24
			b 78
			b "A diskerror has been occured."
			b GOTOXY
			w 24
			b 86
			b "Not all files were copied."
			b GOTOXY
			w 24
			b 94
			b "Select the function 'Validate disk'"
			b GOTOXY
			w 24
			b 102
			b "to free already used diskspace!"
			b GOTOXY
			w 80
			b 128
			b "View diskerror"
			b NULL
endif

;*** Icon-Tabellen.
:icon_Tab1		b $01
			w $0000
			b $00

			w Icon_OK
			b $03,$78,$06,$10
			w ExitErrDlg
