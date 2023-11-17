; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GeoDOS 64/128 (40 Zeichen) V2.0
; (w) by Markus Kanet
;******************************************************************************

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n "GD_DOSDRIVE",NULL
			f SYSTEM
			c "GD_DOSDRIVE V2.2",NULL
			a "M. Kanet",NULL
			o DOS_Driver
			p EnterDeskTop
			r PRINTBASE -1
			i
<MISSING_IMAGE_DATA>
			z $00

			h "MSDOS-Gerätetreiber"
			h "für GeoDOS 64 V2.x"
			h ""
			h "(c) 1995,96,97: M.Kanet"

;*** Einsprungadresse zum initialisieren der JobCode-Befehle.
			jmp	xJobCodeInit

;*** Speicher für Disketten-Namen.
:DiskNameDOS		s 17

;*** Jobs initialisieren.
;    (Einsprung nur von GeoDOS aus über
;    Vektor ":DOS_Driver"
.xJobCodeInit		ldx	#$00
			lda	curDrvMode
			bpl	:1
			ldx	#$0a
::1			ldy	#$00
::2			lda	DrvCodeAdr+0,x
			sta	GetJOBS   +5,y
			lda	DrvCodeAdr+1,x
			sta	GetJOBS   +6,y
			tya
			add	10
			tay
			inx
			inx
			cpy	#50
			bne	:2
			rts

;*** Job-Daten an Floppy übertragen.
.SendJobData		pha				;Job-Code merken.
			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO
			CxSend	SetHDRS			;Sektor addressieren.
			CxSend	SetHDRS2		;Sektor addressieren.
			CxSend	SetSIDS			;Seite definieren.
			jsr	DoneWithIO
			pla

.SendJob		sta	JOBS			;Job definieren.
			lda	#<SetJOBS
			ldx	#>SetJOBS

;*** Warten bis Floppy-Job erledigt.
.Wait_Job		jsr	SendCom			;Job ausführen.

			jsr	InitForIO
::1			CxSend	GetJOBS			;Job-Ergebniss einlesen.

			ClrB	STATUS
			DrvTalk	curDrive
			ChkStatus:2
			jsr	ACPTR
			sta	ReturnCode
			DrvUnTalk

			lda	ReturnCode		;Job erledigt ?
			bmi	:1			;Nein, weiter...
			bpl	:3			;Ja, ende...

::2			DrvUnTalk			;Laufwerk "AUS".
			lda	#$ff
			sta	ReturnCode

::3			pha				;Job-Ergebniss merken.
			jsr	DoneWithIO		;I/O abschalten.
			pla				;Job-Ergebniss wieder einlesen.
			rts

;*** Sektor (512 Byte) von Disk lesen.
.D_Read			LdSekData			;Sektor-Werte lesen.
.Read			SvJSekData			;Job-Werte setzen.
			lda	#$a4			;Code: Read Sektor.
			jsr	SendJobData
			cmp	#$02
			bcc	:1
			ldx	#$43			;Sektor kann nicht gelesen werden.
			rts

::1			lda	#$03			;Floppy-RAM $0300.
.RD_Block		sta	DskMem +1		;Bytes 0-255 lesen.

			jsr	InitForIO
			ClrB	STATUS

			jsr	L050a0
			txa
			bne	:1
			inc	DskMem +1		;Bytes 256-511 lesen.
			inc	a8H
			jsr	L050a0
			dec	a8H
::1			jmp	DoneWithIO

:L050a0			CxSend	Read_Mem
			txa
			bne	:2

			DrvTalk	curDrive		;Laufwerk "EIN".
			ChkStatus:2			;Laufwerks-Fehler.

			ldy	#$00			;Daten aus Floppy
::1			jsr	ACPTR			;einlesen.
			sta	(a8L),y
			iny
			bne	:1

			DrvUnTalk

			ldx	#$00
			b $2c
::2			ldx	#$43
			rts

;*** Sektor (512 Byte) auf Disk schreiben.
.D_Write		LdSekData			;Sektor-Werte lesen.
.Write			SvJSekData			;Job-Werte setzen.
			lda	#$03			;Floppy-RAM $0300.
			jsr	WR_Block
			jmp	L050b0

.F_Write		LdSekData			;Sektor-Werte lesen.
			SvJSekData			;Job-Werte setzen.
:L050b0			lda	#$a6			;Code: Write Sektor.
			jsr	SendJobData
			cmp	#$02
			bcs	:1
			ldx	#$00
			rts
::1			ldx	#$44
			rts

.WR_Block		sta	DskMem2 +1		;Bytes 0-255 schreiben.

			jsr	InitForIO
			ClrB	STATUS

			jsr	L050b1
			txa
			bne	:1
			inc	DskMem2 +1		;Bytes 256-511 schreiben.
			inc	a8H
			jsr	L050b1
			dec	a8H

::1			jmp	DoneWithIO

:L050b1			ldy	#$07
::1			tya
			pha
			lda	V050a2,y
			sta	DskMem2
			sta	Var_0a
			jsr	:3
			pla
			tay
			txa
			bne	:2
			dey
			bpl	:1
::2			rts

::3			DrvListencurDrive
			ChkStatus:7

			ldy	#$00			;"M-W" an Floppy.
::4			lda	Write_Mem,y
			jsr	CIOUT
			iny
			cpy	#$06
			bne	:4

			ldy	Var_0a
			ldx	#$20
::6			lda	(a8L),y
			jsr	CIOUT
			iny
			dex
			bne	:6
			b $2c
::7			ldx	#$44
			jmp	UNLSN

;*** DOS-Verzeichnis.
.DOS_GetSys		jsr	DoInfoBox
			PrintStrgGetSysTxt
			jsr	GetBSek			;Boot-Sektor lesen.
			jmp	Load_FAT		;FAT einlesen.

;*** Boot-Sektor in Zwischenspeicher einlesen.
.GetBSek		lda	#<Boot_Sektor		;Zeiger auf Boot-Sektor im
			sta	a0L			;Speicher setzen.
			sta	a8L
			lda	#>Boot_Sektor
			sta	a0H
			sta	a8H
			lda	#$01
			tay
			ldx	#$00			;Zeiger auf Boot-Sektor.
			jsr	Read			;Sektor lesen.
			txa
			bne	DOS_BOOT_ERR

;--- Ergänzung: 31.01.19/M.Kanet
;Zuerst prüfen ob gültiger Boot-Sektor vorliegt da sonst
;geoDOS bei eingelegter CBM-Diskette abstürzen kann.
			lda	Media
			cmp	#$f0			;3,5" 18/36 Sek./Spur = 1.44/2.88Mb.
			beq	:1
			cmp	#$f9			;3,5" 9 Sek./Spur = 720Kb.
			bne	DOS_BOOT_ERR

::1			lda	SekSpr
			cmp	#9			;3,5" = 720Kb.
			beq	:2
			cmp	#18			;3,5" = 1.44Mb.
			bne	DOS_BOOT_ERR

::2			lda	AnzSLK			;Anzahl Schreib-/Leseköpfe 1 oder 2.
			beq	DOS_BOOT_ERR
			cmp	#3
			bcs	DOS_BOOT_ERR
			rts

:DOS_BOOT_ERR		ldx	#$40			;Fehler: Boot-Sektor nicht lesbar!
			b $2c
:DOS_FAT_ERR		ldx	#$42			;16Bit-FAT oder mehr als 9 Sektoren
			jmp	DiskError		;pro FAT -> FAT zu groß.

;*** FAT-Typ prüfen.
.Chk_FatTyp		MoveW	Anz_Sektor,r0		;Gesamtanzahl der Sektoren auf Disk.
			lda	SpClu			;Anzahl Sektoren je Cluster.
::1			lsr				;Anzahl Cluster berechnen.
			tax
			beq	:2
			lsr	r0H
			ror	r0L
			jmp	:1

::2			CmpBI	r0H,$10			;Mehr als 1024 Cluster ?
			bcs	DOS_FAT_ERR		;Ja => Fehler.

			CmpBI	SekFat,10		;FAT mit mehr als 9 Sektoren?
			bcs	DOS_FAT_ERR		;Ja => Fehler.
			rts

;*** FAT in Speicher einlesen.
.Load_FAT		jsr	InitFAT			;Zeiger auf FAT berechnen.
			jsr	InitFAT2

			ClrB	V050a0			;Anzahl FAT-Sektoren auf 0.
::1			jsr	D_Read			;FAT-Sektor lesen.
			txa
			bne	:3
			jsr	InitFAT3
			lda	V050a0
			cmp	SekFat			;FAT komplett eingelesen?
			beq	:2			; Ja, => Ende.
			jmp	:1			;Nein => weiter.

::2			ClrB	BAM_Modify		;Flag "BAM verändert" löschen.
			rts

::3			ldx	#$41			;FAT kann nicht geladen werden.
			jmp	DiskError

;*** FAT in Speicher einlesen.
.Save_FAT		lda	BAM_Modify
			bne	:1
			rts

::1			MoveB	Anz_Fat,V050a1		;Anzahl FATs in Speicher.
			jsr	InitFAT
::2			jsr	InitFAT2

			ClrB	V050a0			;Anzahl FAT-Sektoren auf 0.
::3			jsr	D_Write			;FAT-Sektor schreiben.
			txa
			bne	:4
			jsr	InitFAT3
			CmpB	V050a0,SekFat		;Letzter FAT-Sektor geschrieben ?
			bne	:3			;Nein, weiter.
			dec	V050a1			;Noch eine FAT schreiben ?
			bne	:2
			ClrB	BAM_Modify		;Flag "BAM verändert" löschen.
			rts

::4			ldx	#$46			;FAT kann nicht geschrieben werden.
			jmp	DiskError

;*** FAT-Zeiger initialisieren.
.InitFAT		jsr	Chk_FatTyp		;FAT-Typ ermitteln.
			lda	AreSek			;Zeiger auf FAT berechnen.
			ldx	AreSek+1
			jmp	Log_Sek

:InitFAT2		lda	#<FAT			;Zeiger auf Anfang FAT im
			sta	a1L			;Speicher setzen.
			sta	a8L
			lda	#>FAT
			sta	a1H
			sta	a8H
			rts

:InitFAT3		inc	a8H
			inc	a8H
			inc	V050a0
			jmp	Inc_Sek			;Zeiger auf nächsten Sektor.

;*** Sektor-Zähler erhöhen.
.Inc_Sek		LdSekData
			cpy	SekSpr
			beq	:1
			iny
			bne	:2
::1			ldy	#$01
			sub	$01
			bcs	:2
			lda	#$01
			inx
::2			SvSekData
			rts

;*** Aus logischer Sektor-Nr. die physikalischen Werte berechnen.
.Log_Sek		sta	r0L
			stx	r0H

			Load_VReg1,0,1
			SvSekData

::1			lda	r0L
			bne	:2
			lda	r0H
			bne	:2
			rts

::2			SubVW	1,r0
			jsr	Inc_Sek
			jmp	:1

;*** Aus Cluster-Nr. die physikalischen Werte berechnen.
;a/x			= Cluster lo/hi
;Ergebniss in Seite,Spur,Sektor
.Clu_Sek		sub	$02			;Cluster #0 definieren.
			sta	V050a3
			bcs	:1
			dex
::1			stx	V050a3+1

			MoveW	SekSpr,V050a4
			CmpBI	AnzSLK,1		;Ein oder zwei
			beq	:2			;Schreib-/Lese-Köpfe?

			ROLWord	V050a4

::2			Load_VReg1,0,1
			SvSekData

			lda	SpClu			;Cluster mit Anzahl
::3			lsr				;Sektoren pro Cluster
			tax				;verknüpfen.
			beq	:4
			ROLWord	V050a3
			txa
			jmp	:3

::4			jsr	DefDbr			;Anzahl reservierter
							;Sektoren berechnen.
			clc
			adc	V050a3
			sta	V050a3
			txa
			adc	V050a3+1
			sta	V050a3+1

::5			CmpW	V050a3,V050a4
			bcc	:6

			sec
			lda	V050a3
			sbc	V050a4
			tax
			lda	V050a3+1
			sbc	V050a4+1
			bcc	:6

			stx	V050a3
			sta	V050a3+1
			inc	Spur
			jmp	:5

::6			RORWord	V050a4

			CmpW	V050a3,V050a4
			bcc	:7
			dec	Seite
			SubW	V050a4,V050a3

::7			MoveB	V050a3,Sektor
			jmp	Inc_Sek			;Logische Sektor-Nr.

;*** Zeiger auf FAT berechnen.
;a/x     = Cluster-Nummer
;a1L/a1H = Startadr. FAT in RAM
;Ergebniss:
;r0L/r0H = Zeiger auf Eintrag in FAT
;r1L,r1H = Fat-Eintrag
.Pos_Clu		sta	r2L
			stx	r2H

			lda	r2H			;Offset berechnen
			lsr				;(12Bit-FAT)
			sta	r3L
			lda	r2L
			ror
			php
			clc
			adc	r2L
			sta	r0L
			lda	r2H
			adc	r3L
			sta	r0H
			pla
			and	#%00000001
			sta	r3L

			AddW	a1,r0 			;Offset zur Startadresse der FAT
							;im RAM addieren.
			ldy	#$00			;FAT-Eintrag nach r1L/r1H kopieren.
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			rts

;*** FAT-Eintrag fuer Cluster lesen.
;a/x     = Cluster-Nummer
;a1L/a1H = Startadr. FAT in RAM
;r0L/r0H = Zeiger auf Eintrag
;r1L/r1H = Wert
;r3L     = Cluster gerade/ungerade
.Get_Clu		jsr	Pos_Clu			;Zeiger auf Cluster in FAT.
			lda	r3L			;Sonderbehandlung für
			bne	:1			;ungerade Cluster-Nummern.

			AndB	r1H,%00001111		;12Bit/gerade
			rts

::1			RORZWordr1L,4			;12Bit/ungerade
			rts				;16Bit/Ende

;*** Cluster in FAT belegen.
;a/x     = Cluster-Nummer
;a1L/a1H = Startadr. FAT in RAM
;r4L/r4H = Wert fuer Eintrag
.Set_Clu		jsr	Pos_Clu			;Zeiger auf Cluster in FAT.
			lda	r3L			;Sonderbehandlung für
			bne	:1			;ungerade Cluster-Nummern.

			MoveB	r4L,r1L			;Low-Byte übertragen.
			AndB	r1H,%11110000
			lda	r4H
			and	#%00001111
			ora	r1H			;High-Byte mit Eintrag koppeln.
			sta	r1H
			jmp	:2			;Zurück in FAT.

::1			ROLZWordr4L,4			;12Bit/ungerade Wert berechnen.
			AndB	r1L,%00001111
			lda	r4L
			and	#%11110000
			ora	r1L
			sta	r1L
			MoveB	r4H,r1H

::2			ldy	#$00			;Cluster-Eintrag in FAT
			lda	r1L			;zurücschreiben.
			sta	(r0L),y
			iny
			lda	r1H
			sta	(r0L),y
			rts

;*** Max. Anzahl Dateien im Hauptverzeichniss ermitteln.
.GetMdrSek		lda	Anz_Files
			sta	MdrSektor
			lda	Anz_Files+1
			lsr
			ror	MdrSektor
			lsr
			ror	MdrSektor
			lsr
			ror	MdrSektor
			lsr
			ror	MdrSektor
			sta	MdrSektor+1
			rts

;*** Zeiger auf Hauptverzeichniss berechnen.
.DefMdr			jsr	DefLogMdr

			lda	V050a5+0
			ldx	V050a5+1
			jmp	Log_Sek

;*** Zeiger auf Anfang Datenbereich berechnen.
.DefDbr			jsr	DefLogMdr

			jsr	GetMdrSek
			AddW	MdrSektor,V050a5
			lda	V050a5+0
			ldx	V050a5+1
			rts

;*** Zeiger auf Hauptverzeichnis berechnen (logisch).
:DefLogMdr		MoveW	AreSek,V050a5
			ldx	Anz_Fat
::1			AddW	SekFat,V050a5
			dex
			bne	:1
			rts

;*** L350: Datenträgername ermitteln.
.DOS_GetDskNam		jsr	i_FillRam
			w	$0011
			w	DiskNameDOS
			b	$00

			jsr	GetMdrSek		;Anzahl Sektoren im Hautpverzeichnis.
			MoveW	MdrSektor,Var_0b
			lda	#$00
			sta	VolNExist
			sta	DskNamSekNr+0
			sta	DskNamSekNr+1
			jsr	DefMdr			;Zeiger auf Hauptverzeichnis.

::101			ClrW	DskNamEntry
			LoadW	a8,Disk_Sek		;Directory-Sektor lesen.
			jsr	D_Read
			txa
			beq	:102
			jmp	DiskError

::102			ldx	#$10
::103			ldy	#$00
			lda	(a8L),y			;Auf Disketten-Namen prüfen.
			beq	:106
			cmp	#$e5
			beq	:106
			ldy	#$0b
			lda	(a8L),y
			and	#%00001000
			bne	:107

::104			AddVBW	32,DskNamEntry		;Nicht gefunden.
			AddVBW	32,a8
			dex
			bne	:103			;Weitersuchen...

			jsr	Inc_Sek			;Zeiger auf nächsten Sektor
			IncWord	DskNamSekNr		;im Hauptverzeichnis.
			SubVW	1,Var_0b
			CmpW0	Var_0b
			beq	:105
			jmp	:101

::105			lda	#$ff			;Kein Platz im
			b	$2c			;Directory für Name.

::106			lda	#$7f			;Kein Disk-Name.
			sta	VolNExist
			LoadW	r0,Var_0c
			jmp	:108

::107			MoveW	a8,r0			;Name gefunden.
::108			ldy	#$00
::109			lda	(r0L),y
			beq	:110
			jsr	ConvertChar
::110			sta	DiskNameDOS,y
			iny
			cpy	#$0b
			bne	:109

			rts

;*** L351: Anzahl freier Bytes berechnen.
.Max_Free		jsr	DefDbr
			sta	FreeClu+0
			stx	FreeClu+1

			sec
			lda	Anz_Sektor
			sbc	FreeClu+0
			sta	FreeClu+0
			lda	Anz_Sektor+1
			sbc	FreeClu+1
			sta	FreeClu+1

			MoveW	BpSek,CluByte

			lda	SpClu
::101			lsr				;Anz. Byte pro Cluster
			tax				;und Anzahl Cluster
			beq	:102			;berechnen.
			RORWord	FreeClu
			ROLWord	CluByte
			txa
			jmp	:101

::102			lda	#$00
			sta	FreeByte+0
			sta	FreeByte+1
			sta	FreeByte+2

			MoveW	FreeClu,r0
			jmp	:104

::103			clc
			lda	FreeByte+0
			adc	CluByte +0
			sta	FreeByte+0
			lda	FreeByte+1
			adc	CluByte +1
			sta	FreeByte+1
			lda	FreeByte+2
			adc	#$00
			sta	FreeByte+2
			SubVW	1,r0
::104			CmpW0	r0
			bne	:103

::105			MoveW	FreeClu,FreeSek

			ldx	SpClu			;Anz. Byte proCluster
::106			dex				;und anzahl Cluster
			beq	:107			;berechnen.
			ROLWord	FreeSek
			jmp	:106

::107			rts

;******************************************************************************
.DOS_End
;******************************************************************************

;*** Zwischenspeicher für Sektordaten.
:Var_0a			b $00
:Var_0b			w $0000
:Var_0c			s 12

.Seite			b $00
.Spur			b $00
.Sektor			b $00
.ReturnCode		b $00
.MdrSektor		w $0000

.FreeByte		b $00,$00,$00
.FreeSek		w $0000
.FreeClu		w $0000
.CluByte		w $0000

:V050a0			b $00
:V050a1			b $00
:V050a2			b $e0,$c0,$a0,$80,$60,$40,$20,$00
:V050a3			w $0000
:V050a4			w $0000
:V050a5			w $0000

;*** Befehle für 1581 und CMD FDx000 für DOS-Read/Write.
.GetJOBS		w $0006
			b "M-R",$02,$00,$01
			b $00,$00

.SetJOBS		w $0007
			b "M-W",$02,$00,$01
.JOBS			b $00,$00

.SetHDRS		w $0008
			b "M-W",$0b,$00,$02
.HDRS			b $00,$00

.SetHDRS2		w $0008
			b "M-W",$bc,$01,$02
.HDRS2			b "FD"

.SetSIDS		w $0007
			b "M-W",$ce,$01,$01
.SIDS			b $00,$00

:DrvCodeAdr		w $0002,$0002,$000b,$01bc,$01ce
			w $0028,$0028,$2800,$28c0,$2840

;*** Befehle für Lesen/Schreiben Floppy-RAM.
.Read_Mem		w $0006
			b "M-R"
.DskMem			w $0000
			b $00

.Write_Mem		b "M-W"
.DskMem2		w $0000
			b $20

;*** Speicher für Directory-Eintrag.
.Dir_Entry		s $20

;*** Angaben zur Position des DOS-Disketten-Name auf Diskette.
.DskNamSekNr		w $0000
.DskNamEntry		w $0000
.VolNExist		b $00

if Sprache = Deutsch
;*** Info: "Disketten-Daten werden eingelesen..."
:GetSysTxt		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenverzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird eingelesen..."
			b NULL
endif

if Sprache = Englisch
;*** Info: "Disketten-Daten werden eingelesen..."
:GetSysTxt		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Load current"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "disk-directory..."
			b NULL
endif
