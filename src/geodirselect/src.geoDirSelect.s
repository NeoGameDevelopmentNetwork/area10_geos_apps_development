; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"TopMac"
			t	"Sym128.erg"

;*** MegaPatch-Adressen.
:DBUSRFILES		= $09
:DBSETDRVICON		= %01000000
:DBSELECTPART		= %10000000
:OpenRootDir		= $9050
:OpenSubDir		= $9053
:SendCommand		= $906b
:RealDrvType		= $9f8e
:RealDrvMode		= $9f92
:GetBackScreen		= $c0e8
:ResetScreen		= $c0eb
:GEOS_InitSystem	= $c0ee
:C_DBoxTitel		= $9fef
:C_InputFieldOff	= $9ffc
:DirectColor		= $c0e2
:MP3_Code		= $c014
:DB_DblBit		= $8871

;*** Fehlermdldungen.
:DEV_NOT_FOUND		= $0d
:NO_ERROR		= $00
:SD2IEC_DISKIMAGE	= $0e
:SD2IEC_BROWSER		= $00
:SD2IEC_NOSDCARD	= $0d

;*** Einsprünge im C64/C128-Kernal.
:IOINIT			= $fda3
:CINT			= $ff81				;Reset: Timer, IO, PAL/NTSC, Bildschirm.
:SETMSG			= $ff90				;Dateiparameter definieren.
:SECOND			= $ff93				;Sekundär-Adresse nach LISTEN senden.
:TKSA			= $ff96				;Sekundär-Adresse nach TALK senden.
:ACPTR			= $ffa5				;Byte-Eingabe vom IEC-Bus.
:CIOUT			= $ffa8				;Byte-Ausgabe auf IEC-Bus.
:UNTALK			= $ffab				;UNTALK-Signal auf IEC-Bus senden.
:UNLSN			= $ffae				;UNLISTEN-Signal auf IEC-Bus senden.
:LISTEN			= $ffb1				;LISTEN-Signal auf IEC-Bus senden.
:TALK			= $ffb4				;TALK-Signal auf IEC-Bus senden.
:SETLFS			= $ffba				;Dateiparameter setzen.
:SETNAM			= $ffbd				;Dateiname setzen.
:OPENCHN		= $ffc0				;Datei öffnen.
:CLOSE			= $ffc3				;Datei schließen.
:CHKIN			= $ffc6				;Eingabefile setzen.
:CKOUT			= $ffc9				;Ausgabefile setzen.
:CLRCHN			= $ffcc				;Standard-I/O setzen.
:BSOUT			= $ffd2				;Zeichen ausgeben.
:LOAD			= $ffd5				;Datei laden.
:GETIN			= $ffe4				;Tastatur-Eingabe.
:CLALL			= $ffe7				;Alle Kanäle schließen.

;*** Macros.
:AddVBW			m
			lda	#§0
			clc
			adc	§1
			sta	§1
			bcc	:Exit
			inc	§1+1
::Exit
			/

endif

			n	"geoDirSelect"
			c	"geoDirSelectV1.8",NULL
			a	"Markus Kanet",NULL
			o	$0400
			z	$40

h "Wechseln von DiskImages auf SD2IEC, Partitionen und Verzeichnisse auf CMD-Laufwerken..."

;*** Programm initialisieren
;SD2IEC suchen, Dialogbox starten und
;danach zurück zum Desktop.
:Start			jsr	Test_GEOS_MP		;Auf GEOS-MegaPatch testen.
			txa				;Fehler ?
			bne	:1			; => Ja, Ende...

;--- Sonderbehandlung C128.
			bit	c128Flag		;C64?
			bpl	:40x80			; => Ja, weiter...
			lda	graphMode		;C128 imm 40Z-Modus?
			bpl	:40x80			; => Ja, weiter...
::80			lda	Icon_Disk+4		;Icon-Breite doppeln.
			ora	#DOUBLE_B
			sta	Icon_Disk+4
			lda	Icon_Unlock+4
			ora	#DOUBLE_B
			sta	Icon_Unlock+4
			lda	#<Dlg_NewDisk
			ldx	#>Dlg_NewDisk
			jsr	DB_Double
			lda	#<Dlg_OpenErr
			ldx	#>Dlg_OpenErr
			jsr	DB_Double
			lda	#<Dlg_Editor
			ldx	#>Dlg_Editor
			jsr	DB_Double
			lda	#<Dlg_Preview
			ldx	#>Dlg_Preview
			jsr	DB_Double

			lda	graphMode
			sta	DB_DblBit

::40x80			jsr	GetBackScreen		;Hintergrundbild setzen.
			jsr	FindAllSD2IEC		;SD2IEC suchen.
			jsr	SlctDiskImg		;Dateiauswahlbox.

::1			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** C128: X-Koordinate und Breite DOUBLE_B/ADD1_B
:DB_Double		sta	r0L
			stx	r0H
			ldy	#$04
			lda	(r0L),y
			ora	#%1000 0000
			sta	(r0L),y
			iny
			iny
			lda	(r0L),y
			ora	#%1010 0000
			sta	(r0L),y
			rts

;*** Auf GEOS-MegaPatch testen.
:Test_GEOS_MP		lda	MP3_Code +0
			cmp	#"M"
			bne	:1
			lda	MP3_Code +1
			cmp	#"P"
			beq	:2

::1			LoadW	r0,Dlg_NoMP		;Kein GEOS-MegaPatch.
			jsr	DoDlgBox		;Fehler ausgeben.

			ldx	#$ff
			b $2c
::2			ldx	#$00
			rts

;*** Kein GEOS-MegaPatch.
:Dlg_NoMP		b $81

			b DBTXTSTR   ,$10,$10
			w :1
			b DBTXTSTR   ,$10,$24
			w :2
			b DBTXTSTR   ,$10,$30
			w :3
			b CANCEL     ,$02,$48
			b NULL

::1			b PLAINTEXT, BOLDON
			b "FEHLER!",NULL

::2			b PLAINTEXT
			b "Dieses Programm ist nur mit",NULL
::3			b "GEOS-MegaPatch V3 lauffähig!",NULL

;*** DiskImage-Auswahl SD2IEC initialisieren.
:SlctDiskImg		jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:2			; => Nein, weiter...

			jsr	CkSD2IECMode		;SD2IEC: Verzeichnis oder DiskImage?
			cpx	#DEV_NOT_FOUND
			beq	:2
			cpx	#SD2IEC_NOSDCARD
			beq	:2
			cpx	#SD2IEC_BROWSER
			beq	:1

			lda	#<FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldx	#>FComExitDImg
			jsr	SendCom

;*** Neues DiskImage wählen
::1			lda	#$00
			b $2c
::2			lda	#$ff
			sta	DirListMode
			sta	DiskImgTyp
			tax
			beq	:3

			ldx	curDrive		;Aktuellen Laufwerkstyp für
			lda	driveType -8,x		;DiskImage-Vergleich speichern.
			and	#%0000 0111
::3			sta	DiskImgTyp

;*** Dateiauswahlbox öffnen.
:DoSlctFileBox		jsr	SetFileList		;Verzeichnis einlesen.
			txa				;Fehler ?
			bne	:0			; => Ja, Abbruch...
			jsr	PrintDImgInfo
			jsr	ModifyDlgBox		;DialogBox anpassen.

			lda	#$00			;Rückgabefeld leeren.
			sta	SlctDEntry
			LoadW	r5,SlctDEntry
			LoadW	r0,Dlg_SlctDImg
			jsr	DoDlgBox		;Dateiauswahlbox öffnen.

			lda	sysDBData
			cmp	#$07			;"UNLOCK"-Button?
			beq	DoSlctFileBox		; => Ja, zurück zur Auswahl.
			cmp	#$08			;"EDITOR"-Button?
			beq	:6			; => Ja, Editor starten.
			cmp	#$05			;"OPEN"-Button?
			beq	:2			; => Ja, auswerten...
			cmp	#$88			;Laufwerk A: bis D: ausgewählt?
			bcc	:1
			cmp	#$8c
			bcc	:3			; => Ja, auswerten...
::1			cmp	#$06			;"DISK"-Button ?
			beq	:5			; => Ja, auswerten...

;--- "OK"
::0			rts				;Diskettenfehler ausgeben.

;--- "OPEN"
::2			ldx	SlctDEntry		;Datei ausgewählt?
			beq	:0			; => Nein, Ende...
			jmp	ChangeSDImg		;Auswahl auswerten.

;--- "A", "B", "C", "D"
::3			pha
			jsr	ChkDImgMode
			cpx	#$00
			beq	:3a

			lda	#<FComExitDImg		;SD2IEC-DiskImage verlassen.
			ldx	#>FComExitDImg
			jsr	SendCom

::3a			pla
			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.
			jmp	SlctDiskImg		;Zurück zur Dateiauswahl.

;--- "DISK"
::5			jmp	DB_GetNewDsk

;--- "EDITOR"
::6			jsr	FindEditor
			txa				;Disk-Fehler?
			bne	:9			; => Ja, Abbruch...

			lda	FNameEditPtr +0		;Editor öffnen.
			ldx	FNameEditPtr +1
			jmp	NewGetFile

::9			jsr	GetBackScreen		;Hintergrundbild setzen.
			LoadW	r0,Dlg_Editor		;Editor nicht gefunden.
			jsr	DoDlgBox		;Fehler ausgeben.

			jmp	DoSlctFileBox		;Zurück zur DialogBox.

;*** Disk-Information ausgeben.
:PrintDImgInfo		jsr	ClrHead			;Bildschirm vorbereiten.
			jsr	ClrBottom
			jsr	UseSystemFont

			jsr	PrntIsSD2IEC		;SD2IEC-Info.
			jsr	PrntSDFCom		;Letzter SD2IEC-Befehl.

			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:1			; => Nein, weiter...
			bit	DirListMode		;ImageBrowser aktiv?
			bpl	:0			; => Ja, weiter...
			bit	UnlockedMode		;Vorschau-Modus ?
			bpl	:1			; => Nein, GEOS-Modus.
			jsr	TestDImgTyp		;Zum Laufwerk passendes DiskImage?
			beq	:1			; => Ja, weiter...
			jmp	PrntSDPrev		;Vorschau-Modus.

::0			jmp	PrntSDMode		;SD2IEC-Verzeichnis.

::1			jsr	PrntDskName		;Diskname.
			jmp	PrntDskSize		;Freier Speicher.

;*** Obere Status-Zeile löschen.
:ClrHead		lda	#$00			;Y-Koordinaten für oben/unten
			b $2c				;berechnen.
:ClrBottom		lda	#$b8
			sta	:1
			clc
			adc	#15
			sta	:1 +1

			lda	#$00			;Füllmuster setzen.
			jsr	SetPattern

;--- Sonderbehandlung C128.
			bit	c128Flag		;C128 ?
			bpl	:0			; => Nein, weiter...
			lda	graphMode		;40Z-Modus?
			bpl	:0			; => Ja, weiter...

			lda	:2 +1			;80Z-Modus: DOUBLE-Flag setzen.
			ora	#%1000 0000		;DOUBLE_W
			sta	:2 +1
			lda	:2 +3
			ora	#%1010 0000		;DOUBLE_W ! ADD1_W
			sta	:2 +3

::0			jsr	i_Rectangle		;Bereich löschen.
::1			b	$b8,$c7
::2			w	$0000,$013f

			lda	#%11111111		;Rahmen zeichnen.
			jsr	FrameRectangle

			lda	C_InputFieldOff		;Farbe setzen.
			jmp	DirectColor

;*** X/Y-Koordinate für Textausgabe setzen.
;Für C128 DOUBLE-Bit setzen.
:PrntXPos1		lda	#10
			b $2c
:PrntXPos2		lda	#190
			b $2c
:PrntXPos3		lda	#220
			b $2c
:PrntXPos4		lda	#90
			b $2c
:PrntXPos5		lda	#255
			sta	r11L
			lda	#0
			bit	c128Flag
			bpl	:0
			lda	graphMode
			bpl	:0
			ora	#%1000 0000
::0			sta	r11H
			rts

:PrntYPos1		lda	#11
			b $2c
:PrntYPos2		lda	#195
			sta	r1H
			rts

;*** SD2IEC-Info ausgeben.
:PrntIsSD2IEC		jsr	PrntXPos1
			jsr	PrntYPos2
			LoadW	r0,DiskInfTxt2		;"SD2IEC:" ausgeben
			jsr	PutString
			jsr	TestSD2IEC
			beq	:6

			ldx	curDrive
			lda	RealDrvMode -8,x
			bmi	:5
			lda	driveType   -8,x
			bmi	:4
			lda	#<DevTextDisk		; => Disketten-Laufwerk.
			ldx	#>DevTextDisk
			bne	:7
::4			lda	#<DevTextRAM		; => RAM-Laufwerk.
			ldx	#>DevTextRAM
			bne	:7
::5			lda	#<DevTextCMD		; => CMD-Laufwerk.
			ldx	#>DevTextCMD
			bne	:7
::6			lda	#<DevTextSD		; => SD2IEC-Laufwerk.
			ldx	#>DevTextSD
::7			sta	r0L
			stx	r0H
			jmp	PutString

;*** Letzten SD2IEC-Befehl ausgeben.
:PrntSDFCom		ldx	FComCDirDev		;Befehl vorhanden?
			beq	:1			; => Nein, weiter...

			jsr	PrntXPos4		;Laufwerksadresse ausgeben.
			jsr	PrntYPos2
			LoadW	r0,SD2IEC_INFO
			jsr	PutString
			jsr	PrntDrvFCom

			LoadW	r0,FComCDir+2		;Letzten Befehl ausgeben.
			jsr	PutString
::1			rts

;*** SD2IEC-Info "VERZEICHNIS" ausgeben.
:PrntSDMode		jsr	PrntDrvAdrXY
			LoadW	r0,SD2IEC_ROOT
			jmp	PutString

;*** SD2IEC-Info "VORSCHAU-MODUS" ausgeben.
:PrntSDPrev		jsr	PrntDrvAdrXY
			LoadW	r0,SD2IEC_PREV
			jmp	PutString

;*** Laufwerks-Adresse A: bis D: ausgeben.
:PrntDrvAdrXY		jsr	PrntXPos1
			jsr	PrntYPos1

:PrntDrvAdr		lda	curDrive
			bne	PrntDrvAdrASC
:PrntDrvFCom		lda	FComCDirDev
:PrntDrvAdrASC		clc
			adc	#$39
			jsr	PutChar
			lda	#":"
			jsr	PutChar
			lda	#" "
			jmp	PutChar

;*** Diskettenname anzeigen.
:PrntDskName		jsr	PrntDrvAdrXY		;Laufwerks-Adresse ausgeben.

			ldx	#r0L			;Zeiger auf Diskettenname setzen.
			jsr	GetPtrCurDkNm

			ldy	#$00			;Diskettenname ausgeben.
::1			tya
			pha
			lda	(r0L),y
			beq	:3
			cmp	#$a0
			beq	:3
			jsr	PutChar
::2			pla
			tay
			iny
			cpy	#16
			bcc	:1
			bcs	:4
::3			pla
::4			rts

;*** Diskettengröße ausgeben.
:PrntDskSize		jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler?
			bne	:5			; => Ja, Abbruch...

			LoadW	r5,curDirHead		;Freien Speicher berechnen.
			jsr	CalcBlksFree

			PushW	r3			;Gesamt-Speicher retten.
			PushW	r4			;Freien Speicher retten.

			jsr	PrntXPos2		;Info-Text "Frei:" ausgeben.
			jsr	PrntYPos1

			LoadW	r0,DiskInfTxt1
			jsr	PutString

			PopW	r0			;Freien Speicher ausgeben.
			jsr	:PrntSize

			lda	#"/"
			jsr	PutChar

			PopW	r0			;Gesamten Speicher ausgeben.

;--- Zahl ausgeben.
::PrntSize		lsr	r0H			;Anzahl Blocks in KB umrechnen.
			ror	r0L
			lsr	r0H
			ror	r0L
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal
			lda	#"K"
			jsr	PutChar
			lda	#"b"
			jsr	PutChar

::5			rts

;*** Aktuelles Laufwerk auf SD2IEC testen.
;    Übergabe: curDrive = Aktuelles Laufwerk.
;    Rückgabe: XREG = $00, Verzeichnis.
;                   = $0e, DiskImage.
;                   = $0d, Kein SD2IEC.

if FALSE
;--- HINWEIS:
;Das ist Version#1 die aber nur die
;Anzahl der freien Cluster auf der SD-
;Karte prüft, was schnell dazu führen
;kann das weniger als "65535" Blocks
;frei zurückgemeldet werden.
;
;Durch Version#2 ersetzt.
;
:CkSD2IECMode		jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:2			; => Nein, weiter...

			lda	#$00			;Anzahl "BlocksFree" löschen.
			sta	Blocks +0
			sta	Blocks +1

			LoadW	r13,FComCkSDMode	;Nur Verzeichnis-Info einlesen.
			LoadW	r15,DataBuf
			jsr	GetDir_BASIC

			lda	Blocks +0		;"BlocksFree" = 65535 ?
			cmp	#$ff
			bne	:1
			lda	Blocks +1
			cmp	#$ff
			bne	:1
			ldx	#SD2IEC_BROWSER		; => Ja, SD2IEC-Verzeichnis.
			b $2c
::1			ldx	#SD2IEC_DISKIMAGE	; => Nein, SD2IEC-DiskImage.
			b $2c
::2			ldx	#DEV_NOT_FOUND		; => Kein SD2IEC.
			rts

:FComCkSDMode		b "$:",$ff,NULL
endif

;*** Aktuelles Laufwerk auf SD2IEC testen.
;    Übergabe: curDrive = Aktuelles Laufwerk.
;    Rückgabe: XREG = $00, Verzeichnis.
;                   = $0e, DiskImage.
;                   = $0d, Kein SD2IEC/Keine SD-Karte.

if TRUE
;--- HINWEIS:
;Das ist Version#2. Hierbei wird ein
;"U1"-Befehl an das Laufwerk gesendet.
;Bei Rückmeldung "00,(OK,00,00)" ist
;es ein SD2IEC im DiskImage-Modus.
;Imm Browser-Modus wird der Befehl vom
;SD2IEC nicht unterstützt -> Fehler.
:CkSD2IECMode		jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			beq	:isSD2IEC		; => Nein, weiter...
::noSD2IEC		ldx	#DEV_NOT_FOUND		; => Kein SD2IEC.
			rts

::isSD2IEC		lda	#"7"			;Fehlermeldung initialisieren.
			sta	FComReply +0
			lda	#"0"
			sta	FComReply +1
			lda	#","
			sta	FComReply +2

			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O aktivieren.

			lda	#1
			ldx	#<FComName
			ldy	#>FComName
			jsr	SETNAM			;Datenkanal, Name "#".

			lda	#5
			tay
			ldx	curDrive
			jsr	SETLFS			;Daten für Datenkanal.

			jsr	OPENCHN			;Datenkanal öffnen.
			bcs	:error

			lda	#10
			ldx	#<FComTestU1
			ldy	#>FComTestU1
			jsr	SETNAM			;"U1"-Befehl.

			lda	#15
			tay
			ldx	curDrive
			jsr	SETLFS			;Daten für Befehlskanal.

			jsr	OPENCHN			;Befehlskanal #15 öffnen.
			bcs	:error

			lda	#<FComReply		;Antwort empfangen.
			ldx	#>FComReply
			ldy	#3
			jsr	GetFData

::error			lda	#15			;Befehlskanal schließen.
			jsr	CLOSE

			lda	#5			;Datenkanal schließen.
			jsr	CLOSE

			jsr	CLRCHN

			lda	FComReply +0		;Rückmeldung auswerten.
			cmp	#"0"			;"00," ?
			bne	:101			; => Nein, Verzeichnis-Modus.
			lda	FComReply +1
			cmp	#"0"
			bne	:101
			lda	FComReply +2
			cmp	#","
			beq	:103

::101			lda	FComReply +0		;Rückmeldung auswerten.
			cmp	#"7"			;"70," ?
			bne	:102			; => Ja, Keine SD-Karte.
			lda	FComReply +1
			cmp	#"0"
			bne	:102
			lda	FComReply +2
			cmp	#","
			bne	:102

			ldx	#SD2IEC_NOSDCARD
			b $2c
::102			ldx	#SD2IEC_BROWSER		;SD2IEC: Verzeichnis.
			b $2c
::103			ldx	#SD2IEC_DISKIMAGE	;SD2IEC: DiskImage.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

:FComName		b "#"
:FComTestU1		b "U1 5 0 1 1"
;FComReply		s $03
endif

;*** Bei SD2IEC Laufwerksmodus/DiskImage-yp testen.
:ChkDImgMode		jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:1			; => Nein, weiter...
			bit	DirListMode		;ImageBrowser aktiv?
			bpl	:1			; => Ja, weiter...
			bit	UnlockedMode		;Vorschau-Modus ?
			bpl	:1			; => Nein, GEOS-Modus.
			jsr	TestDImgTyp		;Zum Laufwerk passendes DiskImage?
			beq	:1			; => Ja, weiter...
			ldx	#$ff			;Kein passendes DiskImage aktiv.
			b $2c
::1			ldx	#$00			;Ende, OK.
			rts

;*** GEOS.Editor auf Disk suchen.
:FindEditor		lda	#<FNameEdit64		;Name für "GEOS64.Editor".
			ldx	#>FNameEdit64
			bit	c128Flag
			bpl	:1
			lda	#<FNameEdit128		;Name für "GEOS128.Editor".
			ldx	#>FNameEdit128
::1			sta	FNameEditPtr +0
			stx	FNameEditPtr +1

			lda	#%10000000		;GEOS.Editor auf
			jsr	FindEditFile		;RAM-Laufwerken suchen.
			txa
			beq	:2
			lda	#%00000000		;GEOS.Editor auf
			jsr	FindEditFile		;Disk-Laufwerken suchen.
::2			rts

;*** Datei auf den Laufwerken A: bis D: suchen.
:FindEditFile		sta	:2 +1

			ldx	curDrive
			stx	r15L
::1			stx	r15H
			lda	driveType -8,x		;Laufwerk verfügbar?
			beq	:3			; => Nein, weiter...
			and	#%10000000
::2			cmp	#$ff			;Gesuchter Laufwerkstyp?
			bne	:3			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:6			; => Nein, weiter...
			bit	DirListMode		;ImageBrowser aktiv?
			bpl	:6			; => Ja, weiter...

			jsr	TestDImgTyp		;Zum Laufwerk passendes DiskImage?
			bne	:3			; => Nein, weiter...

::6			jsr	OpenDisk		;Diskette öffnen.
			txa				;Disk-Fehler?
			bne	:3			; => Ja, weiter...

			MoveW	FNameEditPtr,r6
			jsr	FindFile		;Editor-Datei-Eintrag suchen.
			txa				;Gefunden?
			beq	:5			; => Ja, Ende...

::3			ldx	r15H			;Zeiger auf nächstes Laufwerk.
			inx
			cpx	#12			;Laufwerk > 11?
			bcc	:8			; => Nein, weiter...
			ldx	#$08			;Auf Laufwerk #8 zurücksetzen.
::8			cpx	r15L			;Alle Laufwerke durchsucht?
			bne	:1			;Auf nächsten Laufwerk weitersuchen.

::4			ldx	#$ff			;Nicht gefunden.

;--- Falls Editor nicht gefunden, Laufwerk zurücksetzen.
::5			txa
			beq	:7
			pha
			lda	r15L 			;Vorheriges Laufwerk wieder
			jsr	SetDevice		;aktivieren.
			pla
			tax
::7			rts

;*** C64/C128: 40/80Z-Modus testen.
:ChkFlag_40_80		LoadW	r9,dirEntryBuf		;Infoblock einlesen.
			jsr	GetFHdrInfo
			txa				;Info-Block gefunden ?
			bne	:4			; => Nein, BASIC-File, Abbruch...

			lda	fileHeader+$60		;40/80Z-Flag einlesen.
			ldx	c128Flag		;C64/C128?
			bne	:1			; => C128, Weiter...
;--- Ergänzung: 15.03.19/M.Kanet
;Unter GEOS gibt es kein Flag für "Nur GEOS128". Eine Anwendung die für den
;40+80Z-Modus entwickelt wurde kann auch für GEOS64 existieren. Es kannn aber
;auch eine reine GEOS128-Anwendung sein.
;Unter GEOS64 werden daher GEOS64, 40ZOnly und 40/80Z akzeptiert.
			cmp	#$c0			;Nur 80Z?
			beq	:2			; => GEOS128-App auf GEOS64... Abbruch.
			bne	:3			;Evtl. GEOS64 App... weiter...

;--- Ergänzung: 15.03.19/M.Kanet
;Unter GEOS128 werden 40ZOnly, 80ZOnly und 40/80Z akzeptiert.
::1			cmp	#%00000000		;40/80Z-Flag einlesen.
			beq	:40
			cmp	#%01000000		;40/80Z ?
			beq	:80			;Ja -> 80Z-Modus setzen.
			cmp	#%10000000		;GEOS64 Only ?
			beq	:2			;Ja -> Abbruch.
			cmp	#%11000000		;Nur 80Z ?
			beq	:80			;Ja -> 80Z-Modus setzen.
::2			ldx	#INCOMPATIBLE		; -> Nur GEOS64, Abbruch.
			bne	:4
::80			lda	#%10000000		;80Z-Modus setzen.
			b $2c
::40			lda	#%00000000		;40Z-Modus setzen.
			cmp	graphMode		;Neuer Modus bereits aktiv?
			beq	:doubleOff		; -> Ja, weiter...
			sta	graphMode
			jsr	SetNewMode		;Neuen Modus aktivieren.

::doubleOff		lda	#%00000000		;Verdopplung abschalten.
			sta	DB_DblBit

::3			ldx	#$00
::4			rts

;*** Routine zum starten einer 40/80Z-Anwendung.
:NewGetFile		sta	a0L			;Zeiger auf Dateiname sichern.
			stx	a0H

			jsr	ChkFlag_40_80		;40/80Z testen.
			txa				;Fehler?
			bne	:9			; -> Ja, Abbruch (Nur GEOS64).

			sei				;GEOS-Reset #0.
			cld
			ldx	#$ff
			txa

			jsr	GEOS_InitSystem		;GEOS-Reset #1.
			jsr	UseSystemFont		;Standardzeichensatz.
			jsr	ResetScreen		;Bildschirm löschen.

			ldx	#r15H			;ZeroPage löschen.
			lda	#$00
::7			sta	$0000,x
			dex
			cpx	#r0L
			bcs	:7

			lda	#> EnterDeskTop -1
			pha
			lda	#< EnterDeskTop -1
			pha
			MoveW	a0,r6
;			LoadB	r0L,%00000000		;Datei laden/starten.
			jmp	GetFile

::9			jmp	DoSlctFileBox		;Zurück zur DialogBox.

;*** "UNLOCK"/"EDITOR" gewählt, Dialogbox beenden.
;"07"/"UNLOCK" oder "08"/"EDITOR" in sysDBData zurückmelden.
:DB_Unlock		lda	UnlockedMode		;Bereits im "UNLOCKED" Modus?
			bmi	:1			; => Ja, Editor starten.

			dec	UnlockedMode		;"UNLOCK"-Modus setzen.
			lda	#<IconGfx_Editor	;"UNLOCK" durch "EDITOR" ersetzen.
			sta	Icon_Unlock +0
			lda	#>IconGfx_Editor
			sta	Icon_Unlock +1

			lda	#$07			;Rückgabe "UNLOCK" gedrückt.
			b $2c
::1			lda	#$08			;Rückgabe "EDITOR" gedrückt.
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** "DISK" gewählt, Dialogbox beenden.
;"06" für "DISK" in sysDBData zurückmelden.
:DB_SlctDisk		lda	#$06
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Prüfen ob innerhalb Hauptverzeichnis.
:TestRootDir		jsr	TestNative		;NativeMode ?
			bne	:0			; => Nein, weiter...

			jsr	GetDirHead		;BAM einlesen.
			txa				;Disk-Fehler?
			bne	:0			; => Ja, Abbruch...

			lda	curDirHead +32
			ora	curDirHead +33
			cmp	#$01 			;Bereits im Hauptverzeichnis ?
			bne	:1			; => Nein, weiter...

::0			ldx	#$00			; => Hauptverzeichnis.
			b $2c
::1			ldx	#$ff			; => Unterverzeichnis.
			rts

;*** Auf NativewMode testen.
:TestNative		ldy	curDrive
			lda	driveType -8,y		;Laufwerk ermitteln.
			and	#%00000111
			cmp	#$04
			rts

;*** Auf SD2IEC testen.
:TestSD2IEC		ldy	curDrive
			lda	DrvTypeSD -8,y
			rts

;*** Auf passendes DiskImage testen.
:TestDImgTyp		ldy	curDrive
			lda	driveType -8,y
			and	#%0000 0111
			cmp	DiskImgTyp
			rts

;*** Dialogbox anpassen.
;"DISK"-Icon bei RAM-Laufwerken ausblenden.
;Bei SD2IEC kann man damit den ImageBrowser starten, bei CMD-Laufwerken
;erscheint die Partitionsauswahl und bei Disketten erscheint der DiskWechsel.
:ModifyDlgBox		jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			beq	:0			; => Ja, weiter...

;			ldy	curDrive
			lda	RealDrvMode -8,y	;CMD-Laufwerk?
			bmi	:1			; => Ja, weiter...
			lda	driveType   -8,y	;RAM-Laufwerk?
			bpl	:1			; => Ja, weiter...
::0			lda	#NULL			;"DISK"-Icon ausblenden.
			b $2c
::1			lda	#DBUSRICON		;"DISK"-Icon einblenden.
			sta	DlgDisk

			lda	UnlockedMode		;UNLOCKED-Modus aktiv?
			bne	:3			; => Ja, Editor immer anzeigen.
			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:2			; => Nein, weiter...
			lda	DirListMode		;Disk-Inhalt anzeigen?
			bne	:2			; => Ja, "UNLOCK" nicht anzeigen.

;--- "UNLOCK"/"EDITOR" anzeigen.
::3			lda	#DBUSRICON
			sta	DlgUnlock +0
			lda	#$00
			sta	DlgUnlock +1
			sta	DlgUnlock +2
			lda	#<Icon_Unlock
			sta	DlgUnlock +3
			lda	#>Icon_Unlock
			sta	DlgUnlock +4
			rts

;--- "UNLOCK"/"EDITOR" ausblenden.
::2			lda	#$08
			sta	DlgUnlock +0
			sta	DlgUnlock +1
			sta	DlgUnlock +2
			sta	DlgUnlock +3
			sta	DlgUnlock +4
			rts

;*** Titelzeile in Dialogbox löschen.
;Erzeugt in der "Bitte Disk einlegen"-Dialogbox
;eine Überschriften-Zeile.
:Dlg_DrawTitel		lda	#$00			;Füllmuster setzen.
			jsr	SetPattern

;--- Sonderbehandlung C128.
			bit	c128Flag
			bpl	:40
			lda	graphMode
			bpl	:40
::80			jsr	i_Rectangle
			b	$20,$2f
			w	$0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W
			jmp	:40x80

::40			jsr	i_Rectangle		;Bereich löschen.
			b	$20,$2f
			w	$0040,$00ff

::40x80			lda	C_DBoxTitel		;Farbe setzen.
			jsr	DirectColor
			jmp	UseSystemFont		;Zeichensatz festlegen.

;*** "DISK" gewählt, Partition, DiskImage oder Disk wechseln.
:DB_GetNewDsk		jsr	GetBackScreen		;Hintergrundbild setzen.

			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			beq	SlctSD2IEC		; => Ja, weiter...
;			ldy	curDrive
			lda	RealDrvMode -8,y	;CMD/Partition-Laufwerk ?
			bmi	SlctCMD			; => Ja, weiter...
			lda	driveType   -8,y	;Disketten-Laufwerk ?
			bpl	SlctCBM			; => Ja, weiter...
			jmp	SlctDiskImg

;--- Reales Disketten-Laufwerk, Dialobox anzeigen.
:SlctCBM		lda	curDrive
			clc
			adc	#$39
			sta	DlgText4

			LoadW	r0,Dlg_NewDisk
			jsr	DoDlgBox
			jmp	SlctDiskImg

;--- CMD-Laufwerk, Partition wechseln.
;Dazu wird DBGETFILES mit DBSELECTPART verwendet.
:SlctCMD		LoadW	r0,Dlg_SlctPart
			jsr	DoDlgBox		;Dateiauswahlbox öffnen.
			jmp	SlctDiskImg

;--- SD2IEC-Laufwerk, DiskImage verlassen.
:SlctSD2IEC		jsr	TestNative		;NativeMode ?
			bne	:1			; => Nein, weiter...
			jsr	OpenRootDir		;Zurück zum Hauptverzeichnis.

::1			lda	#<FComExitDImg		;SD2IEC-DiskImage verlassen.
			ldx	#>FComExitDImg
			jsr	SendCom
			jmp	SlctDiskImg

;*** DiskImage öffnen.
:ChangeSDImg		jsr	FindSlctEntry		;Nummer des Eintrages ermitteln.
			cpx	#$00			;Gefunden?
			bne	:2			; => Nein, Fehler...

			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:1			; => Nein, weiter...
			bit	DirListMode		;ImageBrowser aktiv?
			bpl	:0			; => Ja, dann BASIC-Modus.

			jsr	TestDImgTyp		;Zum Laufwerk passendes DiskImage?
			beq	:1			; => Ja, weiter...

			lda	SlctFileNum
			cmp	#$02			;ROOT/UP ausgewählt?
			bcc	:0			; => Ja, weiter...

			jsr	GetBackScreen		;Hintergrundbild setzen.
			LoadW	r0,Dlg_Preview		;Vorschaumodus.
			jsr	DoDlgBox		;Fehler ausgeben.

::0			jmp	SlctDir_BASIC		;Verzeichnis im BASIC-Modus auflisten.
::1			jmp	SlctDir_GEOS		;Verzeichnis im GEOS-Modus auflisten.
::2			jmp	DoSlctFileBox		;Zurück zur DialogBox.

;*** Gewählten Eintrag in der Dateiliste suchen.
:FindSlctEntry		lda	#0			;Zähler auf ersten Eintrag.
			sta	SlctFileNum

			LoadW	r0,SlctDEntry		;Zeiger auf gewählten Eintrag.
			LoadW	r15,DataBuf		;Zeiger auf Datentabelle.

::2			ldx	#r0L
			ldy	#r15L
			jsr	CmpString		;Eintrag vergleichen.
			beq	:3			;Gefunden? => Ja, Ende...

			AddVBW	17,r15			;Zeiger auf nächsten Eintrag.

			inc	SlctFileNum		;Zähler erhöhen.
			lda	SlctFileNum
			cmp	ListEntries		;Alle Einträge verglichen?
			bcc	:2			; => Nein, weiter...

::3a			ldx	#$ff			;Fehler: Nicht gefunden.
			rts

::3			LoadW	r0,DirSeparator		;Zeiger auf Listen-Trenner.
			ldx	#r0L
			ldy	#r15L
			jsr	CmpString		;Eintrag vergleichen.
			beq	:3a			;Trenner gefunden? => Ja, Ende...

			ldx	#$00			;OK, Eintrag gefunden.
			rts

;*** DiskImage-Typ feststellen.
:GetDImgTyp		ldx	#$00			;.Dxx imm DiskImage Name suchen und
::1			lda	SlctDEntry +0,x		;in GEOS-Disktyp $01-$04 wandeln.
			cmp	#"."
			bne	:4
			lda	SlctDEntry +1,x
			cmp	#"D"
			bne	:4
			ldy	#$02
::2			lda	DImgTypeList +0,y
			cmp	SlctDEntry   +2,x
			bne	:3
			lda	DImgTypeList +1,y
			cmp	SlctDEntry   +3,x
			beq	:5
::3			iny
			iny
			cpy	#10
			bcc	:2
::4			inx
			cpx	#16
			bcc	:1

			lda	#$00			;DiskImage-Typ nicht erkannt.
			sta	DiskImgTyp

			ldx	#$ff
			rts

::5			tya
			lsr
			sta	DiskImgTyp		;DiskImage-Typ nach GEOS konvertieren.

			ldx	#$00
			rts

;*** Verzeichnis über KERNAL-Routinen wechseln.
;Wird nur bei SD2IEC verwendet da die GEOS-Routinen ausserhalb eines
;DiskImage nicht funktionieren.
:SlctDir_BASIC		lda	SlctFileNum
			cmp	#$00			;"<= (ROOT)" Eintrag gewählt?
			beq	:SlctROOT		; => Ja, weiter...
			cmp	#$01			;".. (UP)" Eintrag gewählt?
			beq	:SlctUP			; => Nein, weiter...

			bit	DirListMode		;ImageBrowser aktiv?
			bmi	:3			; => Nein, weiter...

;--- BASIC/Verzeichnis oder DiskImage öffnen.
::SlctFILE		lda	curDrive		;Laufwerk merken.
			sta	FComCDirDev

			ldy	#$00
			ldx	#$03
::1			lda	SlctDEntry,y		;Verzeichnisname in "CD"-Befehl
			beq	:2			;übertragen...
			sta	FComCDir+2,x
			inx
			iny
			cpy	#16
			bne	:1
			lda	#$00
::2			sta	FComCDir+2,x
			stx	FComCDir+0

			lda	#<FComCDir		;Verzeichnis/Image wechseln.
			ldx	#>FComCDir
			jsr	SendCom

			lda	SlctFileNum
			cmp	cntEntries +1		;Verzeichnis oder DiskImage gewählt?
			bcc	:3			; => Verzeichnis.

			jsr	GetDImgTyp
			jsr	TestDImgTyp		;Zum Laufwerk passendes DiskImage?
			bne	:4			; => Nein, weiter...

			jsr	OpenDisk		;Neues DiskImage öffnen. OpenDisk ist
							;notwendig bei DNP damit max.Track im
							;DiskImage aktualisiert wird.
::4			lda	#$ff			;Verzeichnis-Modus aktivieren.
			sta	DirListMode

::3			jmp	DoSlctFileBox		;Neues Verzeichnis einlesen.

;--- BASIC/SD-ROOT-Verzeichnis öffnen.
::SlctROOT		bit	DirListMode		;ImageBrowser aktiv?
			bpl	:5			; => Ja, weiter...
			lda	#<FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldx	#>FComExitDImg
			jsr	SendCom
::5			lda	#<FComCDRoot		;Root aktivieren.
			ldx	#>FComCDRoot
			jsr	SendCom
			jmp	SlctDiskImg		;Neues Verzeichnis einlesen.

;--- BASIC/Ein SD-Verzeichnis zurück.
::SlctUP		lda	#<FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldx	#>FComExitDImg
			jsr	SendCom
			jmp	SlctDiskImg		;Neues Verzeichnis einlesen.

;*** Verzeichnis über GEOS-Routinen wechseln.
;Wird innerhalb eines DiskImages, Partition oder Diskette verwendet.
:SlctDir_GEOS		jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			beq	:1			; => Nein, weiter...
			jsr	TestNative		;NativeMode ?
			bne	:2			; => Nein, weiter...

::1			lda	SlctFileNum
			cmp	#$00			;"<= (ROOT)" Eintrag gewählt?
			beq	:SlctROOT		; => Ja, weiter...
			cmp	#$01			;".. (UP)" Eintrag gewählt?
			beq	:SlctUP			; => Nein, weiter...
			cmp	cntEntries +1		;Verzeichnis gewählt?
			bcs	:2			; => Nein, Ende...
			jmp	:SlctDIR		;Verzeichnis öffnen.
::2			jmp	:SlctFILE

;--- GEOS/Native-ROOT-Verzeichnis öffnen.
::SlctROOT		jsr	TestRootDir		;BAM einlesen.
			txa				;Disk-Fehler?
			beq	:11			; => Ja, weiter...

			jsr	OpenRootDir		;MegaPatch: Hauptverzeichnis öffnen.
::10			jmp	DoSlctFileBox		;Zurück zur Dateiauswahl.

::11			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:10			; => Nein, weiter...

			bit	DirListMode		;ImageBrowser aktiv?
			bpl	:12			; => Ja, weiter...

			lda	#<FComExitDImg		;SD2IEC-DiskImage verlassen.
			ldx	#>FComExitDImg
			jsr	SendCom

::12			lda	#<FComCDRoot		;Root aktivieren.
			ldx	#>FComCDRoot
			jsr	SendCom
			jmp	SlctDiskImg		;Zurück zur Dateiauswahl.

;--- GEOS/Ein Native-Verzeichnis zurück.
::SlctUP		jsr	TestRootDir		;BAM einlesen.
			txa				;Disk-Fehler?
			beq	:21			; => Ja, weiter...

			MoveB	curDirHead+34,r1L	;Link zum Elternverzeichnis
			MoveB	curDirHead+35,r1H	;einlesen.
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
::20			jmp	DoSlctFileBox		;Zurück zur Dateiauswahl.

::21			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:20			; => Nein, weiter...

			lda	#<FComExitDImg		;SD2IEC-DiskImage verlassen.
			ldx	#>FComExitDImg
			jsr	SendCom
			jmp	SlctDiskImg		;Zurück zur Dateiauswahl.

;--- GEOS/Native-Verzeichnis öffnen.
::SlctDIR		LoadW	r6,SlctDEntry
			jsr	FindFile		;Verzeichnis-Eintrag suchen.
			txa				;Disk-Fehler?
			bne	:31			; => Ja, Abbruch...

			lda	dirEntryBuf +1		;Link zum Verzeichnis-Header einlesen.
			ldx	dirEntryBuf +2
			sta	r1L
			stx	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
::31			jmp	DoSlctFileBox		;Zurück zur Dateiauswahl.

;--- GEOS/Anwendung starten.
::SlctFILE		LoadW	r6,SlctDEntry
			jsr	FindFile		;Verzeichnis-Eintrag suchen.
			txa				;Disk-Fehler?
			bne	:42			; => Ja, Abbruch...

			lda	dirEntryBuf +22		;Dateityp = Anwendung/AutoExec?
			cmp	#APPLICATION
			beq	:40
			cmp	#AUTO_EXEC
			bne	:41			; => Nein, Fehler ausgeben.

::40			lda	#<SlctDEntry		;Anwendung starten.
			ldx	#>SlctDEntry
			jmp	NewGetFile

::41			jsr	GetBackScreen		;Hintergrundbild setzen.
			LoadW	r0,Dlg_OpenErr		;Nur Anwendungen starten.
			jsr	DoDlgBox		;Fehler ausgeben.

::42			jmp	DoSlctFileBox		;Zurück zur Dateiauswahl.

;*** Verzeichnis einlesen.
:SetFileList		jsr	i_FillRam		;Speicher löschen.
			w	18*256
			w	DataBuf
			b	$00

			lda	#$00			;Anzahl Einträge löschen.
			sta	ListEntries

			sta	cntEntries +0		;Anzahl Dateien = 0.
			sta	cntEntries +1		;Anzahl Verzeichnisse = 0.

			jsr	SetDImgType		;Image-Typ D64/71/81/DNP festlegen.

			LoadW	r15,DataBuf		;Zeiger auf Speicher für Daten.

			jsr	AddListHdr		;Bei Bedarf ROOT/UP hinzufügen.
			jsr	AddDirData		;Verzeichnisse hinzufügen.
;--- DiskFehler ignorieren und leere Box anzeigen.
;			txa				;Disk-Fehler?
;			bne	:1			; => Ja, Abbruch.
			jsr	AddFileHdr		;Bei Bedarf Listen-Trenner hinzufügen.
			jsr	AddFileData		;Dateien hinzufügen.
;			txa				;Disk-Fehler?
;			bne	:1			; => Ja, Abbruch.

			lda	cntEntries +0		;Dateien gefunden?
			bne	:2			; => Ja, weiter...
			jsr	DelFileHdr		;Listen-Trenner löschen...

::2			ldx	#$00			;Kein Fehler.
::1			rts

;*** DiskImage-Typ wählen.
:SetDImgType		ldy	#$00			;Zeiger auf "??".
			bit	UnlockedMode		;"UNLOCK"-Modus?
			bmi	:1			; => Ja, weiter...
			ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			asl
			tay
::1			lda	DImgTypeList +0,y	;Kennung D64/D71/D81/DNP in
			sta	FComDImgList +5		;Verzeichnis-Befehl eintragen.
			lda	DImgTypeList +1,y
			sta	FComDImgList +6
			rts

;*** ROOT/Up zu Verzeichnissen hinzufügen.
;Bei SD2IEC/Image-Verzeichnis und NativeMode ist es damit möglich
;zum ROOT-Verzeichnis bzw. eine Verzeichnisebene Höher zu wechseln.
:AddListHdr		bit	DirListMode 		;ImageBrowser aktiv?
			bpl	:1			; => Ja, Einträge hinzufügen.

			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			beq	:1			; => Nein, weiter...
			jsr	TestNative		;SD2IEC-Laufwerk ?
			bne	:2			; => Nein, Ende...

::1			lda	#<DirNavEntry		;"ROOT" hinzufügen.
			ldx	#>DirNavEntry
			jsr	AddEntry
			inc	cntEntries +1

			lda	#<DirNavEntry+16	;"UP" hinzufügen.
			ldx	#>DirNavEntry+16
			jsr	AddEntry
			inc	cntEntries +1

			lda	#$ff
			b $2c
::2			lda	#$00
			sta	Flag_DirHdr		;Flag setzen: Header aktiv Ja/Nein.
			rts

;*** ">> Dateien" zur Dateiliste hinzufügen.
:AddFileHdr		lda	#$00
			sta	Flag_FileHdr		;Flag setzen: Trenner aktiv=Nein.

			bit	DirListMode		;ImageBrowser aktiv?
			bpl	:1			; => Ja, weiter...

			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			beq	:1			; => Nein, weiter...
			jsr	TestNative		;SD2IEC-Laufwerk ?
			bne	:2			; => Nein, Ende...

::1			dec	Flag_FileHdr		;Flag setzen: Trenner aktiv=Ja.

			inc	cntEntries +1

			bit	DirListMode		;ImageBrowser aktiv?
			bpl	:3			; => Ja, weiter...
			bit	UnlockedMode		;"UNLOCK"-Mode?
			bpl	:3			; => Nein, GEOS-Browser.

			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:3			; => Nein, weiter...
			jsr	TestDImgTyp		;Zum Laufwerk passendes DiskImage?
			beq	:3			; => Nein, weiter...

			lda	#<PreviewMode		;Hinweis "VORSCHAU" einfügen.
			ldx	#>PreviewMode		;Image-Typ passt nicht zum Laufwerk,
			jmp	AddEntry		;Daher nur Verzeichnis-Anzeige.

::3			lda	#<DirSeparator		;Hinweis "DATEIEN" ausgeben.
			ldx	#>DirSeparator		;Trennt Verzeichnisse und Dateien.
			jmp	AddEntry
::2			rts

;*** ">> Dateien" aus Dateiliste löschen.
:DelFileHdr		bit	Flag_FileHdr		;Listen-Trenner gesetzt?
			bpl	:2			; =>> Nein, Ende...

			dec	cntEntries +1

			lda	r15L
			sec
			sbc	#17
			sta	r15L
			bcs	:1
			dec	r15H

::1			lda	#$00
			tay
			sta	(r15L),y
			sta	Flag_FileHdr
::2			rts

;*** Eintrag in Dateiliste speichern.
:AddEntry		sta	r14L			;Zeiger auf Eintrag.
			stx	r14H

			ldy	#$00
::1			lda	(r14L),y		;Eintrag in Dateiliste kopieren.
			sta	(r15L),y
			iny
			cpy	#16
			bcc	:1

:SetNxEntry		AddVBW	17,r15			;Zeiger auf nächsten Eintrag.
			inc	ListEntries		;Anzahl Einträge +1.
			rts

;*** Verzeichnisse hinzufügen.
:AddDirData		lda	#<FComSDirList		;Liste mit Verzeichnissen einlesen.
			ldx	#>FComSDirList
			ldy	#$ff
			jmp	GetDirList

;*** Dateienn hinzufügen.
:AddFileData		lda	#<FComDirList		;Liste mit Dateien einlesen.
			ldx	#>FComDirList
			bit	DirListMode 		;ImageBrowser aktiv?
			bmi	:1			; => Nein, weiter...
			lda	#<FComDImgList		;Liste mit DiskImages einlesen.
			ldx	#>FComDImgList
::1			ldy	#$00
			jmp	GetDirList

;*** Verzeichnis-Liste einlesen.
:GetDirList		sty	ReadDirMode		;$00=Dateien, $FF=Verzeichnisse.

			sta	r13L			;Zeiger auf "$"-Befehl.
			stx	r13H

			bit	DirListMode		;ImageBrowser aktiv?
			bpl	:0			; => Ja, weiter...

			jsr	TestSD2IEC		;SD2IEC-Laufwerk ?
			bne	:2			; => Nein, weiter...
			bit	UnlockedMode		;"UNLOCK"-Mode?
			bpl	:2			; => NEIN, GEOS-Browser.

			bit	ReadDirMode		;Dateien einlesen?
			bpl	:1			; => Ja, weiter...
			ldx	#$00			;Im Vorschaumodus nicht notwendig.
			rts

::1			jsr	TestDImgTyp		;Zum Laufwerk passendes DiskImage?
			bne	:0			; => Nein, weiter...

::2			jmp	GetDir_GEOS		;Verzeichnis über GEOS einlesen.
::0			jmp	GetDir_BASIC		;Verzeichnis über KERNAL einlesen.

;*** Prüfen ob Dateiliste voll ist.
:ChkListFull		jsr	SetNxEntry		;Zeiger auf nächsten Eintrag.

			lda	ListEntries		;Anzahl Einträge einlesen.
			bit	ReadDirMode		;Verzeichnisse oder Dateien suchen?
			bpl	:1			; => Dateien, weiter...

			inc	cntEntries +1		;Anzahl Verzeichnise +1.
			cmp	#100			;Speicher voll ( Anzahl = 100 ) ?
			beq	:3			; => Ja, Ende...
			bne	:2			; => Nein, weitersuchen...

::1			inc	cntEntries +0		;Anzahl Dateien +1.
			cmp	#255			;Speicher voll ( Anzahl = 255 ) ?
			beq	:3			; => Ja, Ende...

::2			ldx	#$00			;List ready...
			b $2c
::3			ldx	#$ff			;List full...
			rts

;*** Eintrag in Verzeichnis-Liste suchen.
:FindDirFile		ldx	cntEntries +1		;Verzeichnisse vorhanden?
			beq	:9			; => Nein, Ende...
			stx	r11L

			LoadW	r10,DataBuf		;Zeiger auf Anfang Dateiliste.

::1			ldx	#r10L
			ldy	#r15L
			jsr	CmpString		;Eintrag vergleichen.
			beq	:8			;Gefunden? => Ja, Ende...

			AddVBW	17,r0			;Zeiger auf nächsten Eintrag.
			dec	r11L			;Alle Einträge verglichen?
			bne	:1			; => Nein, weiter...

			ldx	#$00			;OK.
			b $2c
::8			ldx	#$ff			;Fehler.
::9			rts

;*** Aktuelles Verzeichnis einlesen.
;Das Verzeichnis wird über den "$"-Befehl über den seriellen
;Bus eingelesen und in den Dateinamenspeicher übertragen.
:GetDir_BASIC		jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO

			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.

			bit	STATUS			;Status-Byte prüfen.
			bpl	:102			;OK, weiter...
::101			ldx	#$0d			;Fehler: "Laufwerk nicht bereits".
			jmp	GetDirListEnd		;Abbruch.

::102			lda	#$f0			;Datenkanal aktivieren.
			jsr	SECOND
			bit	STATUS			;Status-Byte prüfen.
			bmi	:101			;Fehler, Abbruch.

::103			ldy	#$00
::104			lda	(r13L),y		;Byte aus Befehl einlesen und
			beq	:104a
			jsr	CIOUT			;an Floppy senden.
			iny
			bne	:104			;Nein, weiter...
::104a			jsr	UNLSN			;Befehl abschliesen.

			lda	#$f0			;Datenkanal öffnen.
			jsr	TALK_CURDRV		;TALK-Signal auf IEC-Bus senden.

			jsr	ACPTR			;Byte einlesen.

			bit	STATUS			;Status testen.
			bpl	:105			;OK, weiter...
			ldx	#$05			;Fehler: "Verzeichnis nicht gefunden".
			jmp	GetDirListEnd

::105			ldy	#$1f			;Verzeichnis-Header
::106			jsr	ACPTR			;überlesen.
			dey
			bne	:106

;*** Partitionen aus Verzeichnis einlesen.
::200			jsr	ACPTR			;Auf Verzeichnis-Ende
			cmp	#$00			;testen.
			beq	:300
			jsr	ACPTR			;(2 Byte Link-Verbindung überlesen).

			jsr	ACPTR			;Low-Byte der Zeilen-Nr. überlesen.
			sta	Blocks +0
			jsr	ACPTR			;High-Byte Zeilen-Nr. überlesen.
			sta	Blocks +1

::201			jsr	ACPTR			;Weiterlesen bis zum
			cmp	#$00			;Dateinamen.
			beq	:205
			cmp	#$22			; " - Zeichen erreicht ?
			bne	:201			;Nein, weiter...

			ldy	#$00			;Zeichenzähler löschen.
::202			jsr	ACPTR			;Byte aus Dateinamen einlesen.
			cmp	#$22			;Ende erreicht ?
			beq	:203			;Ja, Ende...
			sta	(r15L),y		;Byte in Tabelle übertragen.
			iny
			bne	:202

::203			jsr	FindDirFile		;Prüfen ob Eintrag bereits als
			txa				;Verzeichnis eingelesen wurde.
			bne	:205			; => Verzeichnis, überspringen...

			jsr	ChkListFull		;Zeiger auf nächsten Eintrag.
			txa				;Liste voll?
			bne	:300			; => Ja, Ende...

::205			jsr	ACPTR			;Rest der Verzeichniszeile überlesen.
			cmp	#$00
			bne	:205
			jmp	:200			;Nächsten Dateinamen einlesen.

;*** Verzeichnis-Ende.
::300			jsr	UNTALK			;Datenkanal schließen.

			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.
			lda	#$e0			;Laufwerk abschalten.
			jsr	SECOND
			jsr	UNLSN

			ldx	#$00			;Kein Fehler.

;*** Verzeichnis abschließen.
:GetDirListEnd		txa
			pha
			jsr	DoneWithIO		;I/O deaktivieren.
			pla
			tax
			rts				;Ende.

;*** Aktuelles Verzeichnis einlesen.
;Das Verzeichnis wird über die GEOS-Routinen
;eingelesen und in den Dateinamenspeicher übertragen.
:GetDir_GEOS		jsr	Get1stDirEntry		;Ersten Verzeichniseintrag suchen.
			txa				;Disk-Fehler?
			beq	:11			; => Nein, weiter...
::2			rts				;Ende.

::11			lda	#$00			;Zeiger auf ersten Eintrag.
			sta	r14L

::12			ldy	r14L			;CBM-Dateityp einlesen.
			lda	(r5L),y			;Datei vorhanden?
			beq	:21			; => Nein, weiter...

			and	#%00001111		;CBM-Dateityp isloieren.

			bit	ReadDirMode		;Dateien oder Verzeichnisse suchen?
			bpl	:13			; => Dateien, weiter...

;--- Verzeichnisse suchen.
			cmp	#$06			;Verzeichnis ?
			bne	:21			; => Nein, überspringen.
			beq	:14			; => Ja, Eintrag speichern.

;--- Dateien suchen.
::13			cmp	#$06			;CBM-Typ = Verzeichnis ?
			beq	:21			; => Ja, überspringen.

::14			iny				;Zeiger auf Dateiname
			iny				;berechnen.
			iny
			tya
			clc
			adc	r5L
			sta	r0L
			lda	r5H
			adc	#$00
			sta	r0H

			ldy	#$00			;Dateiname in
::15			lda	(r0L),y			;Zwischenspeicher übernehmen.
			cmp	#$a0
			beq	:16
			sta	(r15L),y
			iny
			cpy	#16
			bcc	:15
::16			lda	#$00
::17			sta	(r15L),y
			iny
			cpy	#16 +1
			bcc	:17

			jsr	ChkListFull		;Zeiger auf nächsten Eintrag.
			txa				;Liste voll?
			bne	:30			; => Ja, Ende...

::21			lda	r14L			;Zeiger auf nächsten
			clc				;Verzeichnis-Eintrag.
			adc	#32
			sta	r14L			;Aktueller Sektor geprüft?
			bcc	:12			; => Nein, weiter...

			ldx	diskBlkBuf +0		;Letzter Verzeiichnis-Sektor?
			beq	:32			; => Ja, Ende...
			stx	r1L
			lda	diskBlkBuf +1
			sta	r1H
			jsr	GetBlock		;Nächsten Verzeichnis-Sektor lesen.
			txa				;Disk-Fehler?
			bne	:32			; => Ja, Abbruch...
			beq	:12			;Nein, weiter...

::30			ldx	#$00
::32			rts				;Ende.

;*** Daten an Floppy senden.
:SendCom		sta	r15L
			stx	r15H

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO
			jsr	:100			;Befehl senden.
			jmp	DoneWithIO

::100			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff			;Befehlskanal #15.
			jsr	SECOND			;Sekundär-Adresse nach LISTEN senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:103			;Nein, Abbruch...

			ldy	#$01			;Zähler für Anzahl Bytes einlesen.
			lda	(r15L),y
			sta	r14H
			dey
			lda	(r15L),y
			sta	r14L
			AddVBW	2,r15			;Zeiger auf Befehlsdaten setzen.
			jmp	:102

::101			lda	(r15L),y		;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			bne	:102
			inc	r15H
::102			SubVW	1,r14			;Zähler für Anzahl Bytes korrigieren.
			bcs	:101			;Schleife bis alle Bytes ausgegeben.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::103			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** LISTEN an aktuelles Laufwerk senden.
:LISTEN_CURDRV		lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jmp	LISTEN			;LISTEN-Signal auf IEC-Bus senden.

;*** TALK an aktuelles Laufwerk senden.
:TALK_CURDRV		pha
			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	TALK			;TALK-Signal auf IEC-Bus senden.
			pla
			jmp	TKSA			;Sekundär-Adresse nach TALK senden.

;*** Auf 1581 oder SD2IEC testen.
;Dazu den Befehl "M-R",$00,$03,$03 senden.
;Die Rückmeldung "00,(OK,00,00)" deutet auf ein SD2IEC hin.
:FindAllSD2IEC		lda	curDrive
			pha

			ldx	#8
::100			stx	curDrvTest		;Aktuelles Laufwerk merken.
			lda	driveType -8,x		;Laufwerk installiert?
			beq	:103			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	TestDevSD2IEC		;SD2IEC-Laufwerk?
			b $2c
::103			ldx	#$ff
			txa
			ldx	curDrvTest		;SD2IEC-Flag speichern.
			sta	DrvTypeSD -8,x
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke geprüft?
			bcc	:100			; => Nein, weiter...

			pla
			jmp	SetDevice

;*** Aktuelles Laufwerk auf SD2IEC testen.
:TestDevSD2IEC		ldx	curDrive
			lda	RealDrvType -8,x
			beq	:103
			and	#%10111111
			cmp	#$10			;CMD/RAM-Laufwerk?
			bcs	:103			; => Ja, kein SD2IEC.

			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O aktivieren.

			lda	#$0f
			tay
			ldx	curDrive
			jsr	SETLFS			;Befehlskanal öffnen.

			jsr	OPENCHN

			lda	#<FComTest		;"M-R"-Befehl senden.
			ldx	#>FComTest
			ldy	#$06
			jsr	SendFCom

			lda	#<FComReply		;Antwort empfangen.
			ldx	#>FComReply
			ldy	#$03
			jsr	GetFData

			lda	#$0f			;Befehlskanal schließen.
			jsr	CLOSE

			ldx	#$00			;Vorgabe: SD2IEC.
			lda	FComReply +0		;Rückmeldung auswerten.
			cmp	#"0"			;"00," ?
			bne	:101			; => Nein, Ende...
			lda	FComReply +1
			cmp	#"0"
			bne	:101
			lda	FComReply +2
			cmp	#","
			beq	:102
::101			ldx	#$ff			;Kein SD2IEC.
::102			jmp	DoneWithIO

::103			ldx	#$ff
			rts

;*** Floppy-Befehl senden.
:SendFCom		sta	r0L
			stx	r0H
			sty	r1L

			ldx	#$0f
			jsr	CKOUT

			lda	#$00
			sta	:101 +1
::101			ldy	#$ff
			cpy	r1L
			beq	:102
			lda	(r0L),y
			jsr	BSOUT
			inc	:101 +1
			jmp	:101

::102			jmp	CLRCHN

;*** Rückmeldung von Floppy empfangen.
:GetFData		sta	r0L
			stx	r0H
			sty	r1L

			lda	#NO_ERROR
			sta	STATUS

			ldx	#15
			jsr	CHKIN

			lda	#$00
			sta	:101 +4
::101			jsr	GETIN
			ldy	#$ff
			cpy	r1L
			beq	:102
			sta	(r0L),y
			inc	:101 +4
			jmp	:101

::102			jmp	CLRCHN

;*** variablen.
:DirListMode		b $00				;$00=SD2IEC, $FF=Verzeichnis.
:ReadDirMode		b $00				;$00=Dateien einlesen.
:UnlockedMode		b $00				;$00=Nur passende DiskImages.
:Flag_DirHdr		b $00				;ROOT/UP aktiv.
:Flag_FileHdr		b $00				;DATEIEN aktiv.
:Blocks			w $0000				;Anzahl Blocks des letzten Eintrages.

;*** Anzahl Dateien und Verzeichnisse.
:cntEntries		b $00,$00			;Dateien/Verzeichnisse getrennt.
:ListEntries		b $00				;Anzahl Gesamteinträge.

;*** Gewählter Eintrag aus Liste.
:SlctDEntry		s 17				;Gewählter Eintrag.
:SlctFileNum		b $00				;Nummer in der Liste.
:DiskImgTyp		b $00				;$01-$04 für DiskImage-Typ.

;*** Einträge zur Verzeichnis-Navigation.
:DirNavEntry		b "<=        (ROOT)"
			b "..      (ZURÜCK)"

;*** Trennung zwischen Verzeichnissen/Dateien.
:DirSeparator		b "======== DATEIEN",NULL

;*** Unlocked-Mode: Hinweis auf "Nur Dateivorschau".
:PreviewMode		b "======= VORSCHAU",NULL

;*** Befehle zum DiskImage-Wechsel.
:DImgTypeList		b "??647181NP??????"
:FComDImgList		b "$:*.D??=P",NULL		;Nur DiskImages.
:FComSDirList		b "$:*=B",NULL			;Nur Verzeichnisse.
:FComDirList		b "$:*",NULL			;Alle Dateien (Vorschaumodus).

:FComCDRoot		w $0004				;Befehl: Zu "ROOT" wechseln.
			b "CD//"
:FComExitDImg		w $0003				;Befehl: Eine Ebene zurück.
			b "CD",$5f

;*** SD2IEC-Laufwerk/Verzeichnis-Befehl
:FComCDirDev		b $00
:FComCDir		w $0000				;Befehl: Verzeichnis/Image wechseln.
			b "CD:"
			s 17

;*** Befehle zum erkennen von SD2IEC.
:FComTest		b "M-R",$00,$03,$03
:FComReply		s $03
:curDrvTest		b $00
:DrvTypeSD		s $04

;*** GEOS-Editor starten.
:FNameEditPtr		w $0000				;Zeiger auf Dateiname.
:FNameEdit64		b "GEOS64.Editor",NULL
:FNameEdit128		b "GEOS128.Editor",NULL

;*** Ausgabe von Disk-Informationen.
:DiskInfTxt1		b "Frei: ",NULL
:DiskInfTxt2		b PLAINTEXT,BOLDON
			b "Device: ",NULL
:DevTextSD		b "SD2IEC",NULL
:DevTextCMD		b "CMD",NULL
:DevTextRAM		b "RAM",NULL
:DevTextDisk		b "DISK",NULL

:SD2IEC_ROOT		b "SD2IEC-VEZEICHNIS",NULL
:SD2IEC_PREV		b "VORSCHAU-MODUS",NULL
:SD2IEC_INFO		b "Befehl ",NULL

;*** "VORSCHAU"-Fehler.
:Dlg_Preview		b %01100001
			b $20,$87
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$10,$0b
			w DlgTextP1
			b DBTXTSTR   ,$10,$20
			w DlgTextP2
			b DBTXTSTR   ,$10,$2c
			w DlgTextP3
			b DBTXTSTR   ,$10,$3a
			w DlgTextP4
			b DBTXTSTR   ,$10,$46
			w DlgTextP5
			b OK         ,$02,$50
			b NULL

:DlgTextP1		b PLAINTEXT, BOLDON
			b "FEHLER",NULL

:DlgTextP2		b PLAINTEXT
			b "Im Vorschau-Modus können keine",NULL
:DlgTextP3		b "Anwendungen gestartet werden.",NULL
:DlgTextP4		b "Bitte GEOS.Editor starten um den",NULL
:DlgTextP5		b "passenden Treiber zu installieren!",NULL

;*** Neue Diskette öffnen.
:Dlg_NewDisk		b %01100001
			b $20,$87
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$10,$0b
			w DlgText1
			b DBTXTSTR   ,$10,$20
			w DlgText2
			b DBTXTSTR   ,$10,$2c
			w DlgText3
			b OK         ,$02,$50
			b NULL

:DlgText1		b PLAINTEXT, BOLDON
			b "INFORMATION",NULL

:DlgText2		b PLAINTEXT
			b "Bitte neue Diskette in",NULL
:DlgText3		b "Laufwerk "
:DlgText4		b "A: einlegen",NULL

;*** "ÖFFNEN"-Fehler.
:Dlg_OpenErr		b %01100001
			b $20,$87
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$10,$0b
			w DlgTextE1
			b DBTXTSTR   ,$10,$20
			w DlgTextE2
			b DBTXTSTR   ,$10,$2c
			w DlgTextE3
			b DBTXTSTR   ,$10,$38
			w DlgTextE4
			b OK         ,$02,$50
			b NULL

:DlgTextE1		b PLAINTEXT, BOLDON
			b "FEHLER",NULL

:DlgTextE2		b PLAINTEXT
			b "Es können nur SD-DiskImages,",NULL
:DlgTextE3		b "Verzeichnisse und Anwendungen",NULL
:DlgTextE4		b "geöffnet werden!",NULL

;*** "EDITOR"-Fehler.
:Dlg_Editor		b %01100001
			b $20,$87
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$10,$0b
			w DlgTextF1
			b DBTXTSTR   ,$10,$28
			w DlgTextF2
			b DBTXTSTR   ,$10,$34
			w DlgTextF3
			b OK         ,$02,$50
			b NULL

:DlgTextF1		b PLAINTEXT, BOLDON
			b "FEHLER",NULL

:DlgTextF2		b PLAINTEXT
			b "Kann `GEOS.Editor` nicht auf",NULL
:DlgTextF3		b "Laufwerk A: bis D: finden!",NULL

;*** Partitions-Auswahlbox.
:Dlg_SlctPart		b %10000001
			b DBGETFILES!DBSELECTPART
			w $0000
			b OPEN      ,$00,$00
			b CANCEL    ,$00,$00
			b NULL

;*** Datei-Auswahlbox.
:Dlg_SlctDImg		b %10000001
			b DBUSRFILES!DBSETDRVICON
			w DataBuf
			b OK        ,$00,$00
			b OPEN      ,$00,$00
:DlgUnlock		b DBUSRICON ,$00,$00
			w Icon_Unlock
:DlgDisk		b DBUSRICON ,$00,$00
			w Icon_Disk
			b NULL

:Icon_Disk		w IconGfx_Disk
			b $00,$00
			b $06,$10
			w DB_SlctDisk

:Icon_Unlock		w IconGfx_Unlock
			b $00,$00
			b $06,$10
			w DB_Unlock

;Beim Einsatz von DBUSRFILES in einer Dateiauswahlbox kann
;der "DISK"-Button nicht verwendet werden. Damit kann man bei DBGETFILES
;die CMD-Partition wechseln.
;Da hier aber auch SD2IEC-Images gewechselt werden können muss der
;"DISK"-Button nachgebildet werden.
:IconGfx_Disk
<MISSING_IMAGE_DATA>

:IconGfx_Unlock
<MISSING_IMAGE_DATA>

:IconGfx_Editor
<MISSING_IMAGE_DATA>

;*** Beginn Ablagespeicher.
:DataBuf		b NULL
