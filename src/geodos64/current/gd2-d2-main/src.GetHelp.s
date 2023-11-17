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

			n	"mod.#109.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	GetHelp

;*** Hilfe aktivieren.
:GetHelp		jsr	DoInfoBox
			PrintStrgV109a0

			LoadW	r0,HelpFileName
			lda	#<$0000
			ldx	#>$0000
			jsr	InstallHelp

			jsr	OpenSysDrive
			jsr	BootHelp
			txa
			pha
			jsr	OpenUsrDrive
			pla
			beq	:101

			DB_OK	V109b0
::101			jmp	InitScreen

;*** Variablen.
:HelpFileName		b "01,GDH_Index",NULL

if Sprache = Deutsch
;*** Infoboxen.
:V109a0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Das Hilfesystem von"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "GeoDOS wird gestartet..."
			b NULL

;*** Dialogboxen.
:V109b0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Hilfesystem nicht auf",NULL
::102			b        "GeoDOS-Systemdiskette!",NULL
endif

if Sprache = Englisch
;*** Infoboxen.
:V109a0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Please wait while"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "loading GeoDOS-help..."
			b NULL

;*** Dialogboxen.
:V109b0			w :101, :102, ISet_Achtung
::101			b BOLDON,"GeoDOS-help not found",NULL
::102			b        "on systemdisk!",NULL
endif
