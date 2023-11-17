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

;*** Register für RAMLink-Routinen/C128.
:MMU			= $ff00
:RAM_Conf_Reg		= $d506
endif

			n	"mod.#101.obj"
			o	$4000

;*** Hardware testen.
:GD_Hardware		jsr	UseGDFont
			jsr	i_C_ColorClr
			b	$00,$00,$28,$19

			Display	ST_WR_FORE
			Pattern	0
			FillRec	0,199,0,319		;Bildschirm löschen.
			jsr	ClrBackCol		;GeoDOS-Standard-Farben.

			Pattern	0
			FillRec	8,23,8,311
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec 10, 21, 11,308,%11111111
			FrameRec 11, 20, 12,307,%11111111
			jsr	i_C_MenuBack
			b	$01,$01,$26,$02
			Print	 48,18
			b	PLAINTEXT,"GeoDOS 64 - ",NULL
			PrintStrgVersion
			Print	181,18
			b	PLAINTEXT,"(c) 1995-2023",NULL

			Pattern	0
			FillRec	176,191,8,311
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec178,189, 11,308,%11111111
			FrameRec179,188, 12,307,%11111111
			jsr	i_C_MenuBack
			b	$01,$16,$26,$02

			Print	 48,186			;Versions-Nr. ausgeben.
			b	"Revision :    ",NULL
			PrintStrgVersionCode

			Window	40,151,48,271
			jsr	i_BitmapUp
			w	Icon_Close
			b	$06,$28,$01,$08

if Sprache = Deutsch
			Print	64,46
			b	"Initialisierung...",NULL
			Print	64,64
			b	"Hardware wird getestet,"
			b	GOTOXY
			w	64
			b	73
			b	"bitte etwas Geduld...",NULL

endif

if Sprache = Englisch
			Print	64,46
			b	"Initialising...",NULL
			Print	64,64
			b	"Testing hardware,"
			b	GOTOXY
			w	64
			b	73
			b	"please wait...",NULL

endif

;******************************************************************************
			t	"-HardwareTest"
;******************************************************************************
