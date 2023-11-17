; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "obj.GD.AUTOBOOT"
			t "G3_Data.V.Class"

			o BASE_AUTO_BOOT

;*** AutoStart-Routine für AutoExec-Programme.
:MainInit		sei
			cld
			lda	EnterDeskTop +1
			sta	DeskTopVec   +0
			lda	EnterDeskTop +2
			sta	DeskTopVec   +1

			jsr	GEOS_InitSystem		;GEOS-Variablen definieren.

			jsr	GetDirHead		;Akt. BAM einlesen.
			MoveW	curDirHead,r1		;Zeiger auf ersten Sektor des
							;Hauptverzeichnisses einlesen.
			jmp	TestNextEntry		;Ersten Verzeichnis-Eintrag testen.

;*** Nächstes AutoExec-Programm suchen.
:NextAutoExec		jsr	GEOS_InitSystem		;GEOS-Variablen definieren.

			MoveB	curDirTrack ,r1L	;Zeiger auf aktuellen Verzeichnis-
			MoveB	curDirSektor,r1H	;Sektor setzen.

			AddVB	32,Vec2DirEntry		;Zeiger auf nächsten Eintrag in
			bne	TestNextEntry		;Verzeichnis-Sektor.

;*** Nächsten Verzeichnis-Sektor einlesen.
:GetNextSektor		MoveB	NextDirSektor,r1H
			MoveB	NextDirTrack ,r1L	;Sektor verfügbar ?
			bne	TestNextEntry		;Ja, weiter...

			lda	numDrives		;Laufwerksanzahl bereits definiert ?
			bne	ExitAutoBoot		;Ja, weiter...
			inc	numDrives		;Mind. ein Laufwerk ist verfügbar.

;*** AutoBoot verlassen, DeskTop starten.
:ExitAutoBoot		lda	DeskTopVec   +0		;Original-EnterDeskTop-Vektor
			sta	EnterDeskTop +1		;in Sprungtabelle einfügen.
			lda	DeskTopVec   +1
			sta	EnterDeskTop +2
			jsr	CopyKernal2REU		;Aktuelles Kernal in REU speichern.
			jmp	EnterDeskTop		;Zum DeskTop zurück.

;*** Nächsten Verzeichnis-Eintrag auf AutoExec-Datei testen.
:TestNextEntry		MoveB	r1L,curDirTrack		;Aktuellen Sektor merken.
			MoveB	r1H,curDirSektor

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	ExitAutoBoot		;Ja, Abbruch...

			lda	diskBlkBuf    +0	;Zeiger auf nächsten Sektor
			sta	NextDirTrack		;zwischenspeichern.
			lda	diskBlkBuf    +1
			sta	NextDirSektor

;*** Aktuellen Verzeichnis-Eintrag auf AutoExec testen.
:TestCurEntry		ldy	Vec2DirEntry		;Zeiger auf Verzeichnis-Eintrag.
			lda	diskBlkBuf +$02,y	;Datei vorhanden ?
			beq	:51			;Nein, weiter...
			lda	diskBlkBuf +$18,y
			cmp	#AUTO_EXEC		;Datei-Typ "AUTO_EXEC" ?
			beq	StartCurEntry		;Ja, ausführen.

::51			AddVB	32,Vec2DirEntry		;Zeiger auf nächsten Eintrag in
							;Verzeichnis-Sektor.
			bne	TestCurEntry		; => Nächsten Eintrag testen.
			beq	GetNextSektor		; => Nächsten Sektor einlesen.

;*** AutoExec-Datei laden und starten.
:StartCurEntry		ldx	#$00
::51			lda	diskBlkBuf   +2,y	;Verzeichnis-Eintrag in
			sta	dirEntryBuf  +0,x	;Zwischenspeicher kopieren.
			iny
			inx
			cpx	#$1e
			bne	:51

			lda	#> NextAutoExec		;EnterDeskTop-Vektor auf
			sta	EnterDeskTop +2		;AutoBoot-Routine umlenken.
			lda	#< NextAutoExec
			sta	EnterDeskTop +1

			LoadB	r0L,$00
			LoadW	r9 ,dirEntryBuf
			jsr	LdApplic		;Programm laden & starten.

			sei				;Nur bei Fehlermeldung:
			lda	#KRNL_BAS_IO_IN		;RESET ausführen.
			sta	CPU_DATA
			jmp	($fffc)

;******************************************************************************
;*** Kernal in REU kopieren.
;******************************************************************************
			t "-G3_Kernal2REU"
;******************************************************************************

;*** Daten für Zeiger auf Verzeichnis.
:DeskTopVec		w $0000
:curDirTrack		b $00
:curDirSektor		b $00
:NextDirTrack		b $00
:NextDirSektor		b $00
:Vec2DirEntry		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g BASE_AUTO_BOOT + SIZE_AUTO_BOOT
;******************************************************************************
