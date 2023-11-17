; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zwischenspeicher für Sektordaten.
.Seite			b $00
.Spur			b $00
.Sektor			b $00

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
			b $40

;*** Jobs initialisieren.
.JobCodeInit		ldx	#$00
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

;*** Zeiger auf Befehl initialisieren.
.ComInit		ldy	#$01			;Zähler für Anzahl Bytes einlesen.
			lda	(r15L),y
			sta	r14H
			dey
			lda	(r15L),y
			sta	r14L
			AddVBW	2,r15
			rts

;*** L030: Daten an Floppy senden.
;    r15 = Zeiger auf Befehl ($`Anzahl-Word`, Befehl).
.SendCom		sta	r15L
			stx	r15H
			InitSPort			;GEOS-Turbo aus und I/O einschalten.
			jsr	SendCom_b
			jmp	DoneWithIO

.SendCom_a		sta	r15L
			stx	r15H
:SendCom_b		ClrB	STATUS			;Status löschen.
			DrvListencurDrive		;Laufwerk aktivieren.
			ChkStatus:3			;Laufwerks-Fehler.
			jsr	ComInit			;Zähler für Anzahl Bytes einlesen.
			jmp	:2

::1			lda	(r15L),y		;Byte aus Speicher
			jsr	$ffa8			;lesen & ausgeben.
			iny
			bne	:2
			inc	r15H
::2			SubVW	1,r14			;Zähler für Anzahl Bytes korrigieren.
			bcs	:1			;Schleife bis alle Bytes ausgegeben.

			DrvUnLstn			;Laufwerk "AUS".
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::3			DrvUnLstn			;Laufwerk "AUS".
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** L031: Daten von Floppy empfangen.
.GetCom			sta	r15L
			stx	r15H
			InitSPort			;GEOS-Turbo aus und I/O einschalten.
			jsr	GetCom_b
			jmp	DoneWithIO

.GetCom_a		sta	r15L
			stx	r15H
:GetCom_b		ClrB	STATUS			;Status löschen.
			DrvTalk	curDrive		;Laufwerk "EIN".
			ChkStatus:3			;Laufwerks-Fehler.
			jsr	ComInit			;Zähler für Anzahl Bytes einlesen.
			jmp	:2

::1			jsr	$ffa5			;Byte einlesen und in
			sta	(r15L),y		;Speicher schreiben.
			iny
			bne	:2
			inc	r15H
::2			SubVW	1,r14			;Zähler für Anzahl Bytes korrigieren.
			bcs	:1

			DrvUnTalk			;Laufwerk "AUS".
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::3			DrvUnTalk			;Laufwerk "AUS".
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** Job-Daten an Floppy übertragen.
.SendJobData		pha				;Job-Code merken.
			InitSPort			;GEOS-Turbo aus und I/O einschalten.
			CxSend	SetHDRS			;Sektor addressieren.
			CxSend	SetHDRS2		;Sektor addressieren.
			CxSend	SetSIDS			;Seite definieren.
			jsr	DoneWithIO
			pla

.SendJob		sta	JOBS			;Job definieren.
			lda	#<SetJOBS
			ldx	#>SetJOBS

;*** L032: Warten bis Floppy-Job erledigt.
.Wait_Job		jsr	SendCom			;Job ausführen.

			jsr	InitForIO

::1			CxSend	GetJOBS			;Job-Ergebniss einlesen.

			ClrB	STATUS
			DrvTalk	curDrive
			ChkStatus:2
			jsr	$ffa5
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

.ReturnCode		b $00

;*** L033: Boot-Sektor in Zwischenspeicher einlesen.
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
			beq	:1
			ldx	#$40			;Fehler: Boot-Sektor nicht lesbar!
			jmp	DiskError
::1			rts

;*** L034: FAT-Typ definieren.
.Get_FatTyp		MoveW	Anz_Sektor,r0
			lda	SpClu
::1			lsr
			tax
			beq	:2
			lsr	r0H
			ror	r0L
			txa
			jmp	:1
::2			ldx	#$00
			CmpBI	r0H,$10
			bcc	:3
			dex
::3			stx	FAT_Typ			;FAT-Typ speichern.
			rts

;*** L035: FAT in Speicher einlesen.
.Load_FAT		jsr	InitFAT			;Zeiger auf FAT berechnen.
			jsr	InitFAT2

			ClrB	V035a0			;Anzahl FAT-Sektoren auf 0.
::1			jsr	D_Read			;FAT-Sektor lesen.
			txa
			bne	:2
			jsr	InitFAT3
			lda	V035a0
			cmp	SekFat
			beq	:1a
			cmp	#$09			;Platz für 12 FAT-Sektoren.
			beq	:3			;FAT zu groß, Fehler!
			jmp	:1			;Nein, weiter.

::1a			ClrB	BAM_Modify		;Flag "BAM verändert" löschen.
			rts

::2			ldx	#$41			;FAT kann nicht geladen werden.
			jmp	DiskError

::3			ldx	#$42			;FAT zu groß.
			jmp	DiskError

:V035a0			b $00

;*** L036: FAT in Speicher einlesen.
.Save_FAT		lda	BAM_Modify
			bne	:1
			rts

::1			MoveB	Anz_Fat,V036a0		;Anzahl FATs in Speicher.
			jsr	InitFAT
::1a			jsr	InitFAT2

			ClrB	V035a0			;Anzahl FAT-Sektoren auf 0.
::2			jsr	D_Write			;FAT-Sektor schreiben.
			txa
			bne	:3
			jsr	InitFAT3
			CmpB	V035a0,SekFat		;Letzter FAT-Sektor geschrieben ?
			bne	:2			;Nein, weiter.
			dec	V036a0			;Noch eine FAT schreiben ?
			bne	:1a
			ClrB	BAM_Modify		;Flag "BAM verändert" löschen.
			rts

::3			ldx	#$46			;FAT kann nicht geschrieben werden.
			jmp	DiskError

:V036a0			b $00

;*** L037: FAT-Zeiger initialisieren.
.InitFAT		jsr	Get_FatTyp		;FAT-Typ ermitteln.
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
			inc	V035a0
			jmp	Inc_Sek			;Zeiger auf nächsten Sektor.

;*** L038: Sektor (512 Byte) von Disk lesen.
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
			jsr	L038a0
			txa
			bne	L038a1
			inc	DskMem +1		;Bytes 256-511 lesen.
			inc	a8H
			jsr	L038a0
			txa
			bne	L038a1
			dec	a8H
			rts

:L038a0			jsr	InitForIO		;IO aktivieren.
			CxSend	Read_Mem

			ClrB	STATUS			;Status löschen.
			DrvTalk	curDrive		;Laufwerk "EIN".
			ChkStatusL038a1			;Laufwerks-Fehler.
			ldy	#$00			;Daten aus Floppy
::1			jsr	$ffa5			;einlesen.
			sta	(a8L),y
			iny
			bne	:1
			DrvUnTalk

			ldx	#$00
			beq	:3
::2			ldx	#$43
::3			jmp	DoneWithIO

:L038a1			ldx	#$43			;Sektor kann nicht gelesen werden.
			rts

;*** L039: Sektor (512 Byte) auf Disk schreiben.
.D_Write		LdSekData			;Sektor-Werte lesen.
.Write			SvJSekData			;Job-Werte setzen.
			lda	#$03			;Floppy-RAM $0300.
			jsr	WR_Block
			jmp	L039a0

.F_Write		LdSekData			;Sektor-Werte lesen.
			SvJSekData			;Job-Werte setzen.
:L039a0			lda	#$a6			;Code: Write Sektor.
			jsr	SendJobData
			cmp	#$02
			bcs	L039b0
			ldx	#$00
			rts

.WR_Block		sta	DskMem2 +1		;Bytes 0-255 schreiben.
			jsr	L039b1
			cpx	#$00
			bne	L039b0
			inc	DskMem2 +1		;Bytes 256-511 schreiben.
			inc	a8H
			jsr	L039b1
			cpx	#$00
			bne	L039b0
			dec	a8H

			ldx	#$00			;Kein Fehler.
			rts
:L039b0			ldx	#$44			;Kann Sektor nicht schreiben.
			rts

:L039b1			ClrB	L039b2+1		;8x 32 Bytes in
			jsr	L039b2			;Floppy-Speicher
			jsr	L039b2			;schreiben.
			jsr	L039b2
			jsr	L039b2
			jsr	L039b2
			jsr	L039b2
			jsr	L039b2
;			jsr	L039b2			;(Entfällt da Routine direkt
;			rts				; aufgerufen wird...)

:L039b2			ldx	#$00
			lda	V039a0,x
			sta	DskMem2
			jsr	InitForIO		;IO aktivieren.
			ClrB	STATUS			;Status löschen.
			DrvListencurDrive
			ChkStatusL039b3			;Laufwerks-Fehler.

			ldy	#$00			;"M-W" an Floppy.
::1			lda	Write_Mem,y
			jsr	$ffa8
			iny
			cpy	#$06
			bne	:1
			ldx	L039b2+1		;Daten an Floppy.
			inc	L039b2+1
			ldy	V039a0,x
			ldx	#$20
::2			lda	(a8L),y
			jsr	$ffa8
			iny
			dex
			bne	:2

			DrvUnLstn
			ldx	#$00
			beq	L039b4
:L039b3			pla
			pla
			ldx	#$44
:L039b4			jmp	DoneWithIO

:V039a0			b $00,$20,$40,$60,$80,$a0,$c0,$e0

;*** L040: Sektor-Zähler erhöhen.
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

;*** L041: Aus logischer Sektor-Nr. die physikalischen Werte berechnen.
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

;*** L042: Aus Cluster-Nr. die physikalischen Werte berechnen.
;a/x			= Cluster lo/hi
;Ergebniss in Seite,Spur,Sektor
.Clu_Sek		sub	$02			;Cluster #0 definieren.
			sta	V042a0
			bcs	:1
			dex
::1			stx	V042a0+1
			MoveW	SekSpr,V042a1
			CmpBI	AnzSLK,1		;Ein oder zwei
			beq	:2			;Schreib-/Lese-Köpfe?
			ROLWord	V042a1
::2			Load_VReg1,0,1
			SvSekData

			lda	SpClu			;Cluster mit Anzahl
::3			lsr				;Sektoren pro Cluster
			tax				;verknüpfen.
			beq	:4
			ROLWord	V042a0
			txa
			jmp	:3

::4			jsr	DefDbr			;Anzahl reservierter
							;Sektoren berechnen.
			clc
			adc	V042a0
			sta	V042a0
			txa
			adc	V042a0+1
			sta	V042a0+1

::5			CmpW	V042a0,V042a1
			bcc	:6

			sec
			lda	V042a0
			sbc	V042a1
			tax
			lda	V042a0+1
			sbc	V042a1+1
			bcc	:6

			stx	V042a0
			sta	V042a0+1
			inc	Spur
			jmp	:5

::6			RORWord	V042a1
			CmpW	V042a0,V042a1
			bcc	:7
			dec	Seite
			SubW	V042a1,V042a0
::7			MoveB	V042a0,Sektor
			jmp	Inc_Sek			;Logische Sektor-Nr.
							;umrechnen.
:V042a0			w $0000
:V042a1			w $0000

;*** L043: Zeiger auf FAT berechnen.
;a/x     = Cluster-Nummer
;a1L/a1H = Startadr. FAT in RAM
;Ergebniss:
;r0L/r0H = Zeiger auf Eintrag in FAT
;r1L,r1H = Fat-Eintrag
.Pos_Clu		sta	r2L
			stx	r2H
			jsr	Get_FatTyp		;FAT-Typ testen.
			lda	FAT_Typ			;Sonderbehandlung
			bmi	:2			;fuer 16Bit-FAT.

::1			lda	r2H			;Offset berechnen
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
			jmp	:3

::2			lda	r2L			;Offset berechnen
			asl				;(16Bit-FAT)
			sta	r0L
			lda	r2H
			rol
			sta	r0H

::3			AddW	a1,r0 			;Offset zur Startadresse der FAT
							;im RAM addieren.
			ldy	#$00			;FAT-Eintrag nach r1L/r1H kopieren.
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			rts

;*** L044: FAT-Eintrag fuer Cluster lesen.
;a/x     = Cluster-Nummer
;a1L/a1H = Startadr. FAT in RAM
;r0L/r0H = Zeiger auf Eintrag
;r1L/r1H = Wert
;r3L     = Cluster gerade/ungerade
.Get_Clu		jsr	Pos_Clu			;Zeiger auf Cluster in FAT.
			lda	FAT_Typ			;Sonderbehandlung 16Bit-FAT.
			bmi	:2
			lda	r3L			;Sonderbehandlung für
			bne	:1			;ungerade Cluster-Nummern.

			AndB	r1H,%00001111		;12Bit/gerade
			rts

::1			RORZWordr1L,4			;12Bit/ungerade
::2			rts				;16Bit/Ende

;*** L045: Cluster in FAT belegen.
;a/x     = Cluster-Nummer
;a1L/a1H = Startadr. FAT in RAM
;r4L/r4H = Wert fuer Eintrag
.Set_Clu		jsr	Pos_Clu			;Zeiger auf Cluster in FAT.
			lda	FAT_Typ			;Sonderbehandlung 16Bit-FAT.
			bmi	:2
			lda	r3L			;Sonderbehandlung für
			bne	:1			;ungerade Cluster-Nummern.

			MoveB	r4L,r1L			;Low-Byte übertragen.
			AndB	r1H,%11110000
			lda	r4H
			and	#%00001111
			ora	r1H			;High-Byte mit Eintrag koppeln.
			sta	r1H
			jmp	:3			;Zurück in FAT.

::1			ROLZWordr4L,4			;12Bit/ungerade Wert berechnen.
			AndB	r1L,%00001111
			lda	r4L
			and	#%11110000
			ora	r1L
			sta	r1L
			MoveB	r4H,r1H
			jmp	:3			;Zurück in FAT.

::2			MoveW	r4,r1			;16Bit

::3			ldy	#$00			;Cluster-Eintrag in FAT
			lda	r1L			;zurücschreiben.
			sta	(r0L),y
			iny
			lda	r1H
			sta	(r0L),y
			rts

;*** L046: Max. Anzahl Dateien im Hauptverzeichniss ermitteln.
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

.MdrSektor		w	$0000

;*** L047: Zeiger auf Hauptverzeichniss berechnen.
.DefMdr			jsr	DefLogMdr

			lda	V049a0+0
			ldx	V049a0+1
			jmp	Log_Sek

;*** L048: Zeiger auf Anfang Datenbereich berechnen.
.DefDbr			jsr	DefLogMdr

			jsr	GetMdrSek
			AddW	MdrSektor,V049a0
			lda	V049a0+0
			ldx	V049a0+1
			rts

;*** L049: Zeiger auf Hauptverzeichnis berechnen (logisch).
:DefLogMdr		MoveW	AreSek,V049a0
			ldx	Anz_Fat
::1			AddW	SekFat,V049a0
			dex
			bne	:1
			rts

:V049a0			w $0000
