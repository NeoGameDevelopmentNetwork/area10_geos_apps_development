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

			n	"mod.#405.obj"
			o	ModStart
			r	EndAreaCBM

			jmp	DSKtoDSK
			jmp	DSKtoDSK_a

;*** Disketten kopieren.
:DSKtoDSK		lda	#$00			;Abfrage für Quelle/Ziel löschen.
			sta	ModBuf +0
			sta	ModBuf +1

			lda	Source_Drv		;Partition Quell-Laufwerk sichern.
			jsr	NewDrive

;--- Hinweis:
;RAMLink-Systemwerte initialisieren.
			jsr	OpenDisk		;Diskette öffnen.
;---

			jsr	GetInfo
			sta	SDrvPart  +0
			stx	SDrvPart  +1
			sty	SDrvPart  +2

			lda	Target_Drv		;Partition Ziel-Laufwerk sichern.
			jsr	NewDrive

;--- Hinweis:
;RAMLink-Systemwerte initialisieren.
			jsr	OpenDisk		;Diskette öffnen.
;---

			jsr	GetInfo
			sta	TDrvPart  +0
			stx	TDrvPart  +1
			sty	TDrvPart  +2
			jmp	DSKtoDSK_a

;*** Partitionsdaten einlesen.
:GetInfo		ldy	curDrive
			lda	DrivePart -8,y
			ldx	ramBase   -8,y
			ldy	driveData +3
			rts

;*** Anzeige initialisieren.
:DSKtoDSK_a		tsx				;Stackpointer merken.
			stx	StackPointer

			lda	Source_Drv		;Konfiguration merken.
			sta	S_Drive
			lda	Target_Drv
			sta	T_Drive

			ldy	#$02
::101			lda	SDrvPart,y
			sta	S_Part  ,y
			lda	TDrvPart,y
			sta	T_Part  ,y
			dey
			bpl	:101

			jsr	CheckConfig		;Laufwerke kompatibel ?

			lda	ModBuf +0		;Rücksprung aus "Ziel formatieren" ?
			beq	DSKtoDSK_b		;Nein, weiter...

			ldy	Target_Drv
			lda	DriveTypes-8,y		;Format auf FD2/4, Partition abfragen.
			cmp	#Drv_CMDFD2
			beq	:102
			cmp	#Drv_CMDFD4
			bne	CMP_AB
::102			jmp	DSKtoDSK_c

;*** Einsprung: Quelle / Ziel wählen.
:DSKtoDSK_b		jsr	GetSource		;Quell-Laufwerk wählen.
:DSKtoDSK_c		jsr	GetTarget		;Ziel -Laufwerk wählen.

;*** Konfiguration testen.
:CMP_AB			lda	S_Drive			;Quell- und Ziel-Laufwerk merken.
			sta	Source_Drv
			lda	T_Drive
			sta	Target_Drv

			ldy	#$02			;Quell- und Ziel-Partition merken.
::101			lda	S_Part  ,y
			sta	SDrvPart,y
			lda	T_Part  ,y
			sta	TDrvPart,y
			dey
			bpl	:101

			jsr	No1DrvCopy		;Kopieren mit einem Laufwerk unmöglich.

;*** Copy-Info anzeigen.
:ShowInfo		jsr	SetSource		;Quell-Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:103			; => Fehler, Abbruch.

::101			jsr	SetTarget		;Ziel-Partition aktivieren.

::102			jsr	Bildschirm_a		;Menü zeichnen.
			jsr	Bildschirm_c		;Daten Quell-Laufwerk ausgeben.
			jsr	Bildschirm_d		;Daten Ziel -Laufwerk ausgeben..

			LoadW	r0,HelpFileName
			lda	#<ShowInfo
			ldx	#>ShowInfo
			jsr	InstallHelp		;Online-Hilfe installieren.

			jsr	i_C_MenuMIcon
			b	$00,$01,$1e,$03

			LoadW	r0,Icon_Tab1
			jmp	DoIcons			;Menü starten.
::103			jmp	DiskError		;Diskettenfehler.

;*** Zurück zu GeoDOS.
:L405ExitGD		jsr	ClrScreen
			jmp	InitScreen

;*** Laufwerke wechseln
:OtherDrive		jsr	ClrScreen
			jmp	vC_DiskCopy

;*** Quell-Diskette wechseln.
:OtherSource		jsr	ClrScreen
			jsr	GetSource
			jmp	CMP_AB

;*** Ziel-Diskette wechseln.
:OtherTarget		jsr	ClrScreen
			jsr	GetTarget
			jmp	CMP_AB

;*** Ziel-Disktete formatieren.
:FrmtTarget		jsr	ClrScreen
			jmp	vC_Format1

;*** Backup-Tabelle erzeugen.
:InitForCopy		jsr	SetTarget		;Ziel -Laufwerk aktivieren.
			txa				;Fehler aufgetreten ?
			bne	:101			;Ja, Abbruch...

			jsr	SetSource		;Quell-Laufwerk aktivieren.
			txa				;Fehler aufgetreten ?
			beq	:102			;Nein, weiter...
::101			rts				;Kopierbefehl ignorieren.

::102			lda	S_Drive			;Laufwerk und Partition an
			sta	Source_Drv		;Kopier-Routine übergeben.
			lda	T_Drive
			sta	Target_Drv

			ldy	#$02
::103			lda	S_Part  ,y
			sta	SDrvPart,y
			lda	T_Part  ,y
			sta	TDrvPart,y
			dey
			bpl	:103

			jsr	InitForIO
			ClrB	$d020
			LoadB	$d027,$0d
			jsr	DoneWithIO
			jsr	i_ColorBox
			b	$00,$00,$28,$19,$00
			jsr	ClrBitMap

			ldx	curDrive		;Laufwerksmodus ermitteln.
			lda	driveType-8,x
			and	#%00000111
			cmp	#$01
			beq	:104
			cmp	#$02
			beq	:105
			cmp	#$03
			beq	:106
			cmp	#$04
			beq	:107
			jmp	L405ExitGD

::104			jmp	Copy1541
::105			jmp	Copy1571
::106			jmp	Copy1581
::107			jmp	CopyCMD

;*** Neue Quell-Diskette öffnen.
:GetSource		ClrB	ModBuf +0
			lda	S_Drive
			jsr	NewDrive
			txa
			bne	:102

			ldy	#$02
::101			lda	S_Part  ,y
			sta	TDrvPart,y
			dey
			bpl	:101

			lda	curDrive		;Zeiger auf Quell-Laufwerk.
			ldx	#<V405a0
			ldy	#>V405a0
			jsr	CMD_GetPart
			txa
			beq	:104			;xReg = $00, OK.
			cpx	#$ff			;xReg = $ff, Abbruch.
			beq	:103
::102			jmp	DiskError		;Disketten-Fehler.
::103			jmp	L405ExitGD		;Zurück zu GeoDOS.

::104			ldy	#$02
::105			lda	TDrvPart,y
			sta	S_Part  ,y
			dey
			bpl	:105

			dec	ModBuf +0
			rts

;*** Neue Ziel-Diskette öffnen.
:GetTarget		ClrB	ModBuf +1

			lda	T_Drive
			jsr	NewDrive
			txa
			beq	:101
			jmp	DiskError

::101			jsr	CheckDiskCBM
			txa
			beq	:103

			ldy	#$02
			lda	#$00
::102			sta	T_Part  ,y
			sta	TDrvPart,y
			dey
			bpl	:102
			jmp	:108

::103			ldy	#$02
::104			lda	T_Part  ,y
			sta	TDrvPart,y
			dey
			bpl	:104

			lda	curDrive		;Zeiger auf Ziel-Laufwerk.
			ldx	#<V405a1
			ldy	#>V405a1
			jsr	CMD_GetPart
			txa
			beq	:106			;xReg = $00, OK.
			cpx	#$ff			;xReg = $ff, Abbruch.
			bne	:108
::105			jmp	L405ExitGD		;Zurück zu GeoDOS.

::106			ldy	#$02
::107			lda	TDrvPart,y
			sta	T_Part  ,y
			dey
			bpl	:107

			dec	ModBuf +1
::108			rts

;*** Bildschirm aufbauen.
:Bildschirm_a		Display	ST_WR_FORE

			jsr	ClrScreen
			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			jsr	UseGDFont
			Print	$0008,$06
if Sprache = Deutsch
			b	PLAINTEXT,"CBM  -  Diskette kopieren",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"CBM  -  Copy disk",NULL
endif

			LoadW	r0,V405h0
			jsr	GraphicsString
			jsr	i_C_Register
			b	$02,$06,$0d,$01
			jsr	i_C_Register
			b	$16,$06,$0d,$01

			Print	$0008,$c4
if Sprache = Deutsch
			b	PLAINTEXT,"Kontrolle der Laufwerksdaten",NULL
endif
if Sprache = Englisch
			b	PLAINTEXT,"Check current configuration",NULL
endif

			lda	#$00
::101			sta	:103 +1
			asl
			asl
			tay
			ldx	#$00
::102			lda	V405h1,y
			beq	:104
			sta	r5L,x
			iny
			inx
			cpx	#$04
			bne	:102
			LoadB	r7L,$01
			jsr	RecColorBox

::103			lda	#$ff
			add	1
			bne	:101
::104			rts

;*** Kopierinformationen anzeigen.
:Bildschirm_c		jsr	SetSource
			lda	#<$0000
			jmp	Bildschirm_e

;*** Kopierinformationen anzeigen.
:Bildschirm_d		jsr	SetTarget
			lda	#<$00a0
			jmp	Bildschirm_e

;*** X-Koordinate setzen.
:SetXPos		clc
			lda	a7L
			adc	V405h2+0,x
			sta	r11L
			lda	a7H
			adc	V405h2+1,x
			sta	r11H
			rts

;*** Kopierinformationen anzeigen.
:Bildschirm_e		sta	a7L
			ClrB	a7H

			ldx	#$00			;GEOS-Laufwerk ausgeben.
			jsr	SetXPos
			LoadB	r1H,$46

			lda	curDrive
			add	$39
			jsr	SmallPutChar
			lda	#":"
			jsr	SmallPutChar

			ldx	#$02			;BASIC-Laufwerk ausgeben.
			jsr	SetXPos

			ldx	curDrive
			lda	DriveAdress-8,x
			sta	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			ldx	#$04			;Diskettentyp ausgeben.
			jsr	SetXPos
			LoadB	r1H,$56

			lda	curType
			and	#%00000111
			asl
			asl
			asl
			tax
			LoadB	:103 +1,$06
::101			stx	:102 +1
			lda	V405b0,x
			jsr	SmallPutChar
::102			ldx	#$ff
			inx
			dec	:103 +1
::103			lda	#$ff
			bne	:101

;*** Laufwerksdaten ausgeben.
			bit	DiskInDrive
			bpl	:103a
			LoadW	r15,V405b1		;Text für "Keine Diskette".
			jmp	:107

::103a			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:106			;Nein, weiter...

			ldx	#$06			;Partitions-Nr. ausgeben.
			jsr	SetXPos
			LoadB	r1H,$6e

			lda	Part_Info +4
			sta	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			ldx	#$08			;Partitions-Namen ausgeben.
			jsr	SetXPos
			LoadB	r1H,$7e

			ldy	#$00
::104			sty	:105 +1
			lda	Part_Info +5,y
			jsr	ConvertChar
			jsr	SmallPutChar
::105			ldy	#$ff
			iny
			cpy	#$10
			bne	:104

::106			ldx	#r15L			;Text für Disketten-Name.
			jsr	GetPtrCurDkNm

::107			ldx	#$0a			;Disketten-Namen ausgeben.
			jsr	SetXPos
			LoadB	r1H,$9e

			ldy	#$00
::108			sty	:109 +1
			lda	(r15L),y
			jsr	ConvertChar
			jsr	SmallPutChar
::109			ldy	#$ff
			iny
			cpy	#$10
			bne	:108
::110			rts

;*** Konfiguration testen.
:CheckConfig		ldx	Source_Drv		;Quell- und Ziel-Laufwerk
			ldy	Target_Drv		;in ASCII umrechnen und merken.
			txa
			add	$39
			sta	V405c1+11
			tya
			add	$39
			sta	V405c1+18

			lda	driveType-8,x		;Partitionen auf Kompatibilität
			and	#%00000111		;prüfen.
			sta	r0L

			lda	driveType-8,y
			and	#%00000111
			cmp	r0L
			bne	:101			;Laufwerkstyp unterschiedlich, Ende.

			cmp	#%00000100		;NativeMode-Copy ?
			bne	:103			; => Nein, OK.

;--- Ergänzung: 22.11.18/M.Kanet
;Quell/Ziel auf GateWay-RAMDisk testen.
;NativeMode-Copy geht nur zwischen Native<->Native oder
;GateWay<->GateWay aber nicht untereinander: GateWay hat eine
;andere BAM--Struktur (weniger BAM-Sektoren).
			lda	DriveTypes-8,x		;Quell-Laufwerk-Typ einlesen.
			cmp	#Drv_GWRD		;RAMDisk-Native kopieren ?
			beq	:100			; => Ja, weiter...

			lda	DriveTypes-8,y		; => Nein, Ziel-Laufwerk-Typ einlesen.
			cmp	#Drv_GWRD		;Typ = RAMDisk-Native?
			beq	:101			; => Ja, Inkompatibel.
			bne	:100a			; => Nein, OK.

::100			lda	DriveTypes-8,y		;Ziel-Laufwerk-typ einlesen.
			cmp	#Drv_GWRD		;Typ = RAMDisk-Native?
			beq	:100a			; => Ja, Laufwerksgröße testen.
			bne	:101			; => Nein, OK.

;--- Ergänzung: 22.11.18/M.Kanet
;Größe von NativeMode-Laufwerken vergleichen.
;Bei unterschiedlicher Größe -> Fehler!
::100a			lda	Source_Drv		;Quell-Laufwerk aktivieren und
			jsr	SetDevice		;BAM einlesen um die Laufwerksgröße
			jsr	GetDirHead		;zu ermitteln.
			txa
			bne	:101
			lda	dir2Head +8		;"Last available track" einlesen und
			pha				;zwischenspeichern.
			lda	Target_Drv		;Ziel-Laufwerk aktivieren und
			jsr	SetDevice		;BAM einlesen um die Laufwerksgröße
			jsr	GetDirHead		;zu ermitteln.
			pla
			cmp	dir2Head +8		;"Last available track" vergleichen.
			beq	:103			; => Gleich groß, OK.

::101			DB_UsrBoxV405c0			;Laufwerke inkompatibel.
							;(z.B. 1541 und RAM1581).

			ldx	StackPointer		;Abbruch...
			txs
			lda	sysDBData
			cmp	#$02
			beq	:102
			jmp	vC_DiskCopy		;"OK".
::102			jmp	L405ExitGD		;"Abbruch".
::103			rts

;*** Auf Copy mit einem Laufwerk testen.
:No1DrvCopy		ldy	Source_Drv
			ldx	Target_Drv
			lda	DriveAdress-8,y
			ora	DriveAdress-8,x
			beq	:101

			lda	DriveAdress-8,y
			cmp	DriveAdress-8,x
			bne	:106
			beq	:102

::101			cpy	Target_Drv
			beq	:104
			bne	:106

::102			ldy	#$02
::103			lda	SDrvPart,y
			cmp	TDrvPart,y		;Quell- und Ziel-Partition gleich ?
			bne	:106			;Nein, weiter...
			dey
			bpl	:103

::104			DB_UsrBoxV405d0			;Quelle & Ziel sind gleich.

			ldx	StackPointer
			txs
			lda	sysDBData
			cmp	#$02
			beq	:105
			jmp	vC_DiskCopy		;"OK".
::105			jmp	L405ExitGD		;"Abbruch".
::106			rts

;*** Track/Sektor-Tabellen für 1541,71,81 erzeugen.
:Copy1541		ldy	#$00
			b $2c
:Copy1571		ldy	#$01
			b $2c
:Copy1581		ldy	#$02

			lda	V405f0,y		;Anzahl Tracks einlesen.
			sta	r10L
			sta	SCREEN_BASE+0
			lda	V405f1,y		;Zeiger auf Sektor-Tabelle einlesen.
			sta	r11L
			lda	V405f2,y
			sta	r11H

			LoadW	r12,SCREEN_BASE+1

			ldx	#$01
::101			ldy	#$00			;Track/Sektor-Tabelle erzeugen.
			txa				;b Track, Erster Sektor, max. Sektor.
			sta	(r12L),y
			iny
			lda	#$00
			sta	(r12L),y
			txa
			tay
			dey
			lda	(r11L),y
			sub	1
			ldy	#$02
			sta	(r12L),y

			AddVBW	3,r12

			cpx	r10L
			beq	:102
			inx
			bne	:101
::102			jmp	JumpToCopy		;...und kopieren.

;*** NativeMode-Partitionen auf Größe testen.
:CopyCMD		jsr	SetSource

			lda	dir2Head+8
			pha
			jsr	SetTarget
			pla
			cmp	dir2Head+8
			beq	:102
			bcc	:102

			DB_UsrBoxV405e0			;Partitionsgröße inkompatibel.

			ldx	StackPointer
			txs
			lda	sysDBData
			cmp	#$02
			beq	:101
			jmp	vC_DiskCopy		;"OK".
::101			jmp	L405ExitGD		;"Abbruch".

::102			sta	r10L
			sta	SCREEN_BASE+0
			LoadW	r12,SCREEN_BASE+1

			ldx	#$01
::103			ldy	#$00			;Track/Sektor-Tabelle erzeugen.
			txa				;b Track, Erster Sektor, max. Sektor.
			sta	(r12L),y
			iny
			lda	#$00
			sta	(r12L),y
			iny
			lda	#$ff
			sta	(r12L),y
			AddVBW	3,r12
			cpx	r10L
			beq	JumpToCopy
			inx
			bne	:103

;*** Kopieren starten.
:JumpToCopy		jmp	vC_DISKtoDISK

;*** Quell-Laufwerk aktivieren.
:SetSource		lda	SDrvPart
			ldx	Source_Drv
			ldy	ModBuf +0
			jmp	OpenNewDrive

;*** Ziel-Laufwerk aktivieren.
:SetTarget		lda	TDrvPart
			ldx	Target_Drv
			ldy	ModBuf +1

;*** Neues Laufwerk und Diskette öffnen.
:OpenNewDrive		pha
			tya
			pha
			txa
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			pla				;Partition wieder einlesen.
			tay
			pla

			cpy	#$00
			beq	:105

			bit	curDrvMode		;CMD-Laufwerk ?
			bmi	:101			;ja, weiter...
			jsr	NewOpenDisk		;Nur Diskette öffnen.
			txa
			bne	:105
			beq	:106

::101			ldx	curDrive
			ldy	curDrvType
			cpy	#Drv_CMDRL
			beq	:102
;--- Ergänzung: 22.11.18/M.Kanet
;RAMDrive ist ähnlich CMD RAMLink, Kennung angepasst.
			cpy	#Drv_CMDRD
			bne	:103
::102			ldx	#$04 +8
::103			cmp	SystemPart-8,x		;Partition bereits aktiviert ?
			bne	:104			;Ja, weiter...

			jsr	GetCurPInfo
			txa
			bne	:105

			jsr	GetDirHead
			txa
			bne	:105
			beq	:106

::104			sta	SystemPart-8,x		;Neue Partition merken und
			jsr	SaveNewPart		;Partition aktivieren.
			txa
			beq	:106

::105			ldx	#$ff
			b $2c
::106			ldx	#$00
			stx	DiskInDrive
			rts

;*** Name der Hilfedatei.
:HelpFileName		b "20,GDH_CBM/Disk",NULL

;*** Variablen.
:StackPointer		b $00
:DiskInDrive		b $ff
:S_Drive		b $00
:T_Drive		b $00
:S_Part			s $03
:T_Part			s $03
:SystemPart		s $05

if Sprache = Deutsch
:V405a0			b PLAINTEXT,"Quell-Partition wählen",NULL
:V405a1			b PLAINTEXT,"Ziel-Partition wählen",NULL
endif

if Sprache = Englisch
:V405a0			b PLAINTEXT,"Select source-partition",NULL
:V405a1			b PLAINTEXT,"Select target-partition",NULL
endif

if Sprache = Deutsch
:V405b0			b "Typ ? ",NULL,NULL
			b "C=1541",NULL,NULL
			b "C=1571",NULL,NULL
			b "C=1581",NULL,NULL
			b "Native",NULL,NULL
			b "Typ ? ",NULL,NULL
			b "Typ ? ",NULL,NULL
			b "Typ ? ",NULL,NULL
:V405b1			b "Keine Diskette ?",NULL

;*** Fehler: "Laufwerke nicht kompatibel!"
:V405c0			w V405c1, V405c2, ISet_Achtung
			b CANCEL,OK
:V405c1			b BOLDON,"Laufwerke x: und x:",NULL
:V405c2			b        "sind nicht kompatibel!",NULL

;*** Fehler: "Laufwerke sind gleich!"
:V405d0			w :101, :102, ISet_Achtung
			b CANCEL,OK
::101			b BOLDON,"Das Quell- und Ziel-",NULL
::102			b        "Laufwerk ist gleich!",NULL

;*** Fehler: "Zielpartition zu klein!"
:V405e0			w :101, :102, ISet_Achtung
			b CANCEL,OK
::101			b BOLDON,"NativeMode Ziel-Partition ist",NULL
::102			b        "kleiner als Quell-Partition!",NULL
endif

if Sprache = Englisch
:V405b0			b "Type ?",NULL,NULL
			b "C=1541",NULL,NULL
			b "C=1571",NULL,NULL
			b "C=1581",NULL,NULL
			b "Native",NULL,NULL
			b "Type ?",NULL,NULL
			b "Type ?",NULL,NULL
			b "Type ?",NULL,NULL
:V405b1			b "No disk ?",NULL

;*** Fehler: "Laufwerke nicht kompatibel!"
:V405c0			w V405c1, V405c2, ISet_Achtung
			b CANCEL,OK
:V405c1			b BOLDON,"Drive    x: and x:",NULL
:V405c2			b        "not compatible!",NULL

;*** Fehler: "Laufwerke sind gleich!"
:V405d0			w :101, :102, ISet_Achtung
			b CANCEL,OK
::101			b BOLDON,"Source- and target-",NULL
::102			b        "drive are identical!",NULL

;*** Fehler: "Zielpartition zu klein!"
:V405e0			w :101, :102, ISet_Achtung
			b CANCEL,OK
::101			b BOLDON,"Not enough diskspace",NULL
::102			b        "available on target-disk!",NULL
endif

;*** Laufwerks-Spezifikationen.
:V405f0			b  35, 70, 80
:V405f1			b <V405g0,<V405g1,<V405g2
:V405f2			b >V405g0,>V405g1,>V405g2

;*** Anzahl Sektoren pro Spur, 1541.
:V405g0			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$13,$13,$13,$13,$13,$13,$13
			b $12,$12,$12,$12,$12,$12,$11,$11
			b $11,$11,$11

;*** Anzahl Sektoren pro Spur, 1571.
:V405g1			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$13,$13,$13,$13,$13,$13,$13
			b $12,$12,$12,$12,$12,$12,$11,$11
			b $11,$11,$11,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$13,$13,$13,$13
			b $13,$13,$13,$12,$12,$12,$12,$12
			b $12,$11,$11,$11,$11,$11

;*** Anzahl Sektoren pro Spur, 1581.
:V405g2			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28

;*** Menügrafik.
:V405h0			b MOVEPENTO
			w $0000
			b $b8
			b FRAME_RECTO
			w $013f
			b $c7

			b MOVEPENTO			;Rahmen Quell-Laufwerk.
			w $0008
			b $38
			b FRAME_RECTO
			w $0097
			b $a7

			b MOVEPENTO			;Rahmen Ziel-Laufwerk.
			w $00a8
			b $38
			b FRAME_RECTO
			w $0137
			b $a7

			b MOVEPENTO			;Rahmen Laufwerksadresse #1/Quelle.
			w $0057
			b $3f
			b FRAME_RECTO
			w $0070
			b $48
			b MOVEPENTO			;Rahmen Laufwerksadresse #2/Quelle.
			w $0077
			b $3f
			b FRAME_RECTO
			w $0090
			b $48

			b MOVEPENTO			;Rahmen Laufwerksadresse #1/Ziel.
			w $00f7
			b $3f
			b FRAME_RECTO
			w $0110
			b $48
			b MOVEPENTO			;Rahmen Laufwerksadresse #2/Ziel.
			w $0117
			b $3f
			b FRAME_RECTO
			w $0130
			b $48

			b MOVEPENTO			;Rahmen Laufwerkstyp/Quelle.
			w $0057
			b $4f
			b FRAME_RECTO
			w $0090
			b $58

			b MOVEPENTO			;Rahmen Laufwerkstyp/Ziel.
			w $00f7
			b $4f
			b FRAME_RECTO
			w $0130
			b $58

			b MOVEPENTO			;Rahmen Partitions-Nr./Quelle.
			w $0067
			b $67
			b FRAME_RECTO
			w $0090
			b $70
			b MOVEPENTO			;Rahmen Partition/Quelle.
			w $000f
			b $77
			b FRAME_RECTO
			w $0090
			b $80

			b MOVEPENTO			;Rahmen Partitions-Nr./Ziel.
			w $0107
			b $67
			b FRAME_RECTO
			w $0130
			b $70
			b MOVEPENTO			;Rahmen Partition/Ziel.
			w $00af
			b $77
			b FRAME_RECTO
			w $0130
			b $80

			b MOVEPENTO			;Rahmen Diskette/Quelle.
			w $000f
			b $97
			b FRAME_RECTO
			w $0090
			b $a0

			b MOVEPENTO			;Rahmen Diskette/Ziel.
			w $00af
			b $97
			b FRAME_RECTO
			w $0130
			b $a0

;*** Menütexte.
if Sprache = Deutsch
			b ESC_PUTSTRING
			w $0012
			b $36
			b PLAINTEXT
			b "Quell-Laufwerk"
			b GOTOX
			w $00b2
			b "Ziel-Laufwerk"

			b GOTOXY			;Laufwerk Quelle.
			w $0010
			b $46
			b "Laufwerk:"

			b GOTOX				;Laufwerk Ziel.
			w $00b0
			b "Laufwerk:"

			b GOTOXY			;Laufwerkstyp Quelle.
			w $0010
			b $56
			b "Typ:"

			b GOTOX				;Laufwerkstyp Ziel.
			w $00b0
			b "Typ:"

			b GOTOXY			;Partition Quelle.
			w $0010
			b $6e
			b "Partition:"

			b GOTOX				;Partition Ziel.
			w $00b0
			b "Partition:"

			b GOTOXY			;Diskette Quelle.
			w $0010
			b $8e
			b "Diskette:"

			b GOTOX				;Diskette Ziel.
			w $00b0
			b "Diskette:"

			b NULL
endif

if Sprache = Englisch
			b ESC_PUTSTRING
			w $0012
			b $36
			b PLAINTEXT
			b "Source-drive"
			b GOTOX
			w $00b2
			b "Target-drive"

			b GOTOXY			;Laufwerk Quelle.
			w $0010
			b $46
			b "Drive   :"

			b GOTOX				;Laufwerk Ziel.
			w $00b0
			b "Drive   :"

			b GOTOXY			;Laufwerkstyp Quelle.
			w $0010
			b $56
			b "Typ:"

			b GOTOX				;Laufwerkstyp Ziel.
			w $00b0
			b "Typ:"

			b GOTOXY			;Partition Quelle.
			w $0010
			b $6e
			b "Partition:"

			b GOTOX				;Partition Ziel.
			w $00b0
			b "Partition:"

			b GOTOXY			;Diskette Quelle.
			w $0010
			b $8e
			b "Disk:"

			b GOTOX				;Diskette Ziel.
			w $00b0
			b "Disk:"

			b NULL
endif

;*** Farbenpositionen für Anzeigefelder.
:V405h1			b $0b,$08,$03,$01
			b $0f,$08,$03,$01
			b $1f,$08,$03,$01
			b $23,$08,$03,$01

			b $0b,$0a,$07,$01
			b $1f,$0a,$07,$01

			b $0d,$0d,$05,$01
			b $02,$0f,$10,$01
			b $21,$0d,$05,$01
			b $16,$0f,$10,$01

			b $02,$13,$10,$01
			b $16,$13,$10,$01

			b NULL

;*** X-Koordinaten für Ausgabe.
:V405h2			w $005c				;Laufwerksadresse #1.
			w $007c				;Laufwerksadresse #2.
			w $005a				;Laufwerkstyp.
			w $006c				;Partitions-Nr.
			w $0012				;Partition.
			w $0012				;Diskette.

;*** Copy-Hinweis.
:Icon_Tab1		b 6
			w $0000
			b $00

			w Icon_05
			b $00,$08,$05,$18
			w L405ExitGD

			w Icon_01
			b $05,$08,$05,$18
			w InitForCopy

			w Icon_04
			b $0a,$08,$05,$18
			w OtherDrive

			w Icon_03
			b $0f,$08,$05,$18
			w OtherSource

			w Icon_06
			b $14,$08,$05,$18
			w OtherTarget

			w Icon_02
			b $19,$08,$05,$18
			w FrmtTarget

;*** Icons.
if Sprache = Deutsch
:Icon_01
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_01
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_02
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_02
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_03
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_03
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_04
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_04
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_05
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_05
<MISSING_IMAGE_DATA>
endif

if Sprache = Deutsch
:Icon_06
<MISSING_IMAGE_DATA>
endif

if Sprache = Englisch
:Icon_06
<MISSING_IMAGE_DATA>
endif
