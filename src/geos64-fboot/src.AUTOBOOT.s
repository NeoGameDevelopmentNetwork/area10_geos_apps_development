; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "TopSym"
			t "TopMac"
			t "TopSym.FBoot"
endif

;*** GEOS-Header.
			n "obj.AUTOBOOT"
			f DATA
			c "AUTOBOOT    V0.1"
			a "Markus Kanet"

			o BASE_AUTO_BOOT

;*** AutoStart-Routine für AutoExec-Programme.
:MainInit		sei
			cld
			lda	EnterDeskTop +1
			sta	DeskTopVec   +0
			lda	EnterDeskTop +2
			sta	DeskTopVec   +1

			jsr	doInit			;GEOS initialisieren.

			jsr	GetDirHead		;Akt. BAM einlesen.
			MoveW	curDirHead,r1		;Zeiger auf ersten Sektor des
							;Hauptverzeichnisses einlesen.
			jmp	TestNextEntry		;Ersten Verzeichnis-Eintrag testen.

;*** Nächstes AutoExec-Programm suchen.
:NextAutoExec		jsr	doInit			;GEOS initialisieren.

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

;*** GEOS initialisieren.
:doInit			lda	MP3_CODE +0
			cmp	#"M"
			bne	:no_mp3
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:no_mp3

			jmp	GEOS_InitSystem		;GEOS/MP3 initialisieren.

::no_mp3		jsr	$c436			;Kernal-Variablen initialisieren.
			jmp	$c40d			;GEOS initialisieren.

;*** Aktuellen GEOS-Kernal in REU kopieren.
:CopyKernal2REU		lda	sysRAMFlg
			ora	#%00100000		;Flag "Kernal in REU gespeichert".
			sta	sysRAMFlg		;(für ReBoot-Funktion).

			LoadW	r0 ,$8400		;Systemvariablen in REU kopieren.
			LoadW	r1 ,$7900		;C64: $8400-$88FF
			LoadW	r2 ,$0500		;REU: $7900-$7DFF
			LoadB	r3L,$00
			jsr	StashRAM

;			LoadW	r0 ,$9000		;Laufwerkstreiber in REU kopieren.
;			LoadW	r1 ,$8300		;C64: $9000-$9D7F
;			LoadW	r2 ,$0d80		;REU: $8300-$907F
;			LoadB	r3L,$00			;(Entfällt, alle Treiber sind
;			jsr	StashRAM		; bereits in der REU!)

			LoadW	r0 ,$9d80		;Kernal Teil #1 in REU kopieren.
			LoadW	r1 ,$b900		;C64: $9D80-$9FFF
			LoadW	r2 ,$0280		;REU: $B900-$BB7F
;			LoadB	r3L,$00
			jsr	StashRAM

			LoadW	r0 ,$bf40		;Kernal Teil #2 in REU kopieren.
			LoadW	r1 ,$bb80		;C64: $BF40-$CFFF
			LoadW	r2 ,$10c0		;REU: $BB80-$CC3F
;			LoadB	r3L,$00
			jsr	StashRAM

			LoadW	r0 ,$8000		;Kernal Teil #3 in REU kopieren.
			LoadW	r1 ,$cc40		;C64: $D000-$FFFF
			LoadW	r2 ,$0100		;REU: $CC40-$FC3F
;			LoadB	r3L,$00

			LoadB	r4L,$30			;$30 x 256 Bytes kopieren.
			LoadW	r5 ,$d000		;Startadresse.

;--- Kernal sichern.
;Dazu die Daten aus dem Kernal in einen
;Zwischenspeicher kopieren, damit auch
;Daten unterhalb des I/O-Bereichs von
;StashRAM gesichert werden können.
::loop			php				;Kernaldaten in temporären
			sei				;Zwischenspeicher kopieren.
			ldy	#$00
::1			lda	(r5L),y
			sta	diskBlkBuf +$00,y
			iny
			bne	:1
			plp

			jsr	StashRAM		;Zwischenspeicher nach REU.

			inc	r5H
			inc	r1H
			dec	r4L			;Alle Kernaldaten kopiert ?
			bne	:loop			; => Nein, weiter...

			LoadW	r0 ,mousePicData	;Mauszeiger in REU kopieren.
			LoadW	r1 ,$fc40		;C64: mousePicData
			LoadW	r2 ,$003f		;REU: $fc40-$fc7f
;			LoadB	r3L,$00
			jmp	StashRAM

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
