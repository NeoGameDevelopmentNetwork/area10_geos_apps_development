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

			n	"mod.#111.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	PrnDiskError

;*** Disk-Fehler abfangen.
:PrnDiskError		stx	DskErrCode

:SetErrorMenu		ldx	#$ff			;Zurück zur MainLoop.
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

			jsr	InitForIO
			ClrB	$d020
			LoadB	$d027,$0d
			jsr	DoneWithIO

			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00
			jsr	ClrBitMap
			jsr	UseGDFont
			ClrB	currentMode

			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0008
			b	$28
			b	RECTANGLETO
			w	$0137
			b	$8f
			b	FRAME_RECTO
			w	$0008
			b	$28
			b	NULL

			PrintStrgV111c0

			jsr	i_ColorBox
			b	$01,$05,$26,$0d,$12
			jsr	i_ColorBox
			b	$02,$0a,$24,$01,$01
			jsr	i_ColorBox
			b	$14,$0c,$04,$01,$01

			lda	DskErrCode
			bpl	:101
			lda	#15
::101			asl
			tax
			lda	V111a0+0,x
			sta	r0L
			lda	V111a0+1,x
			sta	r0H

			LoadW	r11,$0012
			LoadB	r1H,$56

			jsr	PutString

			LoadW	r11,$00a2
			LoadB	r1H,$66
			MoveB	DskErrCode,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			LoadW	r0,HelpFileName
			lda	#<SetErrorMenu
			ldx	#>SetErrorMenu
			jsr	InstallHelp

			jsr	i_ColorBox
			b	$02,$0f,$06,$02,$01

			LoadW	r0,Icon_Tab1
			jsr	DoIcons
			StartMouse
			NoMseKey
			rts

;*** Fehlerausgabe beenden.
:ExitError		jsr	SetGDScrnCol
			jsr	ClrScreen
			jmp	InitScreen

;*** Variablen.
:HelpFileName		b "04,GDH_Grundlagen",NULL

:DskErrCode		b $00

:V111a0			w V111b0 ,V111b1 ,V111b2 ,V111b3;$00-$0f
			w V111b4 ,V111b5 ,V111b6 ,V111b7
			w V111b8 ,V111b9 ,V111b10,V111b11
			w V111b12,V111b13,V111b14,V111b15
			w V111b15,V111b15,V111b15,V111b15;$10-$1f
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b32,V111b33,V111b34,V111b35;$20-$2f
			w V111b15,V111b37,V111b38,V111b39
			w V111b40,V111b41,V111b42,V111b15
			w V111b15,V111b15,V111b46,V111b15
			w V111b15,V111b15,V111b15,V111b15;$30-$3f
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b64,V111b65,V111b66,V111b67;$40-$4f
			w V111b68,V111b69,V111b70,V111b71
			w V111b72,V111b73,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15;$50-$5f
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15;$60-$6f
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b115;$70-$7f
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15
			w V111b15,V111b15,V111b15,V111b15

;*** Icon-Menü.
:Icon_Tab1		b $01
			w $0000
			b $00

			w Icon_OK
			b $02,$78,$06,$10
			w ExitError

if Sprache = Deutsch
;*** Menü-Texte.
:V111c0			b GOTOXY
			w 100
			b 56
			b "! A C H T U N G !"
			b GOTOXY
			w 18
			b 76
			b "Es ist ein Diskettenfehler aufgetreten:"
			b GOTOXY
			w 18
			b 102
			b "GeoDOS-Fehlercode:"
			b GOTOXY
			w 72
			b 128
			b "Zum GeoDOS-Hauptmenü"
			b NULL
endif

if Sprache = Englisch
;*** Menü-Texte.
:V111c0			b GOTOXY
			w 100
			b 56
			b "! W A R N I N G !"
			b GOTOXY
			w 18
			b 76
			b "A disk-error has occured:"
			b GOTOXY
			w 18
			b 102
			b "Errorcode:"
			b GOTOXY
			w 72
			b 128
			b "Back to GeoDOS"
			b NULL
endif

;*** Fehlermeldungen im Klartext.
if Sprache = Deutsch
:V111b0			b "Kein Fehler",NULL
:V111b1			b "Diskette ist voll"									,NULL
:V111b2			b "Ungültige Sektoradresse"								,NULL
:V111b3			b "Nicht genügend freier Speicher"							,NULL
:V111b4			b "Inhaltsverzeichnis ist voll"								,NULL
:V111b5			b "Datei nicht gefunden"								,NULL
:V111b6			b "BAM ist defekt"									,NULL
:V111b7			b "VLIR-Datei nicht geöffnet"								,NULL
:V111b8			b "Ungültiger VLIR-Datensatz"								,NULL
:V111b9			b "Zu viele VLIR-Datensätze"								,NULL
:V111b10		b "Falsche Dateistruktur"								,NULL
:V111b11		b "Speicherüberlauf beim laden"								,NULL
:V111b12		b "Absichtlicher Abbruch-Fehler"							,NULL
:V111b13		b "Gerät nicht ansprechbar"								,NULL
:V111b14		b "C128: Falscher Grafikmodus"								,NULL
:V111b15		b "Unbekannter Fehler"									,NULL
:V111b32		b "Datei-Header nicht gefunden"								,NULL
:V111b33		b "Keine SYNC-Markierung auf Diskette"							,NULL
:V111b34		b "Datenblock nicht gefunden"								,NULL
:V111b35		b "Daten-Prüfsummenfehler"								,NULL
:V111b37		b "Fehler beim schreiben auf Diskette"							,NULL
:V111b38		b "Diskette ist schreibgeschützt"							,NULL
:V111b39		b "Header-Prüfsummenfehler"								,NULL
:V111b40		b "Falsches Diskettenformat"								,NULL
:V111b41		b "Falsche Disketten-ID"								,NULL
:V111b42		b "Falsches Diskettenformat"								,NULL
:V111b46		b "Byte-Dekodierungsfehler"								,NULL
:V111b64		b "MSDOS: Bootsektor nicht gefunden"							,NULL
:V111b65		b "MSDOS: FAT kann nicht gelesen werden"						,NULL
:V111b66		b "MSDOS: Inkompatibles FAT-Format"							,NULL
:V111b67		b "MSDOS: Lesefehler (Sektor)"								,NULL
:V111b68		b "MSDOS: Schreibfehler (Sektor)"							,NULL
:V111b69		b "MSDOS: Lesefehler (Cluster)"								,NULL
:V111b70		b "MSDOS: FAT kann nicht gespeichert werden"						,NULL
:V111b71		b "MSDOS: Hauptverzeichnis voll"							,NULL
:V111b72		b "MSDOS: Unterverzeichnis voll"							,NULL
:V111b73		b "MSDOS: Diskette voll"								,NULL
:V111b115		b "Diskette mit falscher DOS-Markierung"						,NULL
endif

if Sprache = Englisch
;*** Fehlermeldungen im Klartext.
:V111b0			b "No error",NULL
:V111b1			b "Disk full",NULL
:V111b2			b "illegal sector"									,NULL
:V111b3			b "Not enough free memory"								,NULL
:V111b4			b "Directory full"									,NULL
:V111b5			b "File not found"									,NULL
:V111b6			b "BAM is corrupt"									,NULL
:V111b7			b "VLIR-file not opened"								,NULL
:V111b8			b "Illegal VLIR-entry"									,NULL
:V111b9			b "Too much VLIR-entries"								,NULL
:V111b10		b "Wrong file-structure"								,NULL
:V111b11		b "Overflow while loading data"								,NULL
:V111b12		b "Operation cancelled"									,NULL
:V111b13		b "Device not found"									,NULL
:V111b14		b "C128: Wrong graphicmode"								,NULL
:V111b15		b "Unknown error"									,NULL
:V111b32		b "File-header not found"								,NULL
:V111b33		b "SYNC not found"									,NULL
:V111b34		b "Data not found"									,NULL
:V111b35		b "checksumm-error"									,NULL
:V111b37		b "Error while writing to disk"								,NULL
:V111b38		b "Disk is write-protected"								,NULL
:V111b39		b "Checksumm-error"									,NULL
:V111b40		b "Wrong diskformat"									,NULL
:V111b41		b "Wrong disk-ID"									,NULL
:V111b42		b "Wrong diskformat"									,NULL
:V111b46		b "Byte-error",NULL
:V111b64		b "MSDOS: Bootsector not found"								,NULL
:V111b65		b "MSDOS: FAT could not be loaded"							,NULL
:V111b66		b "MSDOS: FAT-format inkompatible"							,NULL
:V111b67		b "MSDOS: Read-error (sector)"								,NULL
:V111b68		b "MSDOS: Write-error (sector)"								,NULL
:V111b69		b "MSDOS: Read-error (cluster)"								,NULL
:V111b70		b "MSDOS: FAT could not be saved"							,NULL
:V111b71		b "MSDOS: Root-directory full"								,NULL
:V111b72		b "MSDOS: Sub-directory full"								,NULL
:V111b73		b "MSDOS: disk full"									,NULL
:V111b115		b "Disk with wrong DOS-code"								,NULL
endif
