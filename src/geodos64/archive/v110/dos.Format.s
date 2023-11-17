; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L300: Diskette formatieren.

;******************************************************************************
:DOS81Info		= FALSE				;Info-Text für 1581-DOS-Format-Routine ausgeben.
							;FALSE = Nicht ausgeben.
							;TRUE  = Info-Text ausgeben.
;******************************************************************************

:DOS_Format		ldx	curDrive		;Format-Routine auswählen.
			ldy	DriveTypes-8,x
			lda	V300a0,y
			pha
			lda	V300a1,y
			pha
			rts

;*** Laufwerks-Optionen.
:Slct1581		LoadW	r0 ,Types1581		;Auswahlbox mit 1581-Format-Optionen.
			LoadW	r15,Titel1581
			jsr	DoFrmtTypeBox
			lda	Types1581,x
			jsr	DoInsertDisk
			jmp	SlctFormat

:SlctFD2		LoadW	r0 ,Types_FD2		;Auswahlbox mit FD2-Format-Optionen.
			LoadW	r15,Titel_FD2
			jsr	DoFrmtTypeBox
			lda	Types_FD2,x
			jsr	DoInsertDisk
			jmp	SlctFormat

:SlctFD4		LoadW	r0 ,Types_FD4		;Auswahlbox mit FD4-Format-Optionen.
			LoadW	r15,Titel_FD4
			jsr	DoFrmtTypeBox
			lda	Types_FD4,x
			jsr	DoInsertDisk
			jmp	SlctFormat

;*** Formatieren starten...
:SlctFormat		pha				;Info-Box definieren.
			asl
			asl
			clc
			adc	#<V300c0
			sta	r15L
			lda	#$00
			adc	#>V300c0
			sta	r15H
			jsr	DefInfoBox
			pla

			tay				;Format-Art auswählen.
			lda	V300a2,y
			pha
			lda	V300a3,y
			pha
			rts

:DOS_720		LoadW	r0,Boot_720		;720 KByte-Diskette formatieren.
			jsr	MakeBootSek
			lda	#5
			jmp	DOS_Disk

:DOS_1440		LoadW	r0,Boot_1440		;1440 KByte-Diskette formatieren.
			jsr	MakeBootSek
			lda	#6
			jmp	DOS_Disk

:DOS_2880		LoadW	r0,Boot_2880		;2880 KByte-Diskette formatieren.
			jsr	MakeBootSek
			lda	#7

:DOS_Disk		ldx	curDrvType
			cpx	#Drv_1581
			beq	:1
			jsr	FormatDisk		;Formatieren starten.
			jmp	SetDskName
::1			jsr	Format1581

;*** Disketten-Name eingeben.
:SetDskName		jsr	SetName			;Disketten-Name eingeben.
			jsr	PrintInfo		;Abschluß-Infos.

;*** Abfrage zum formatieren weiterer Disketten...
:AskDoFrmtAgn		LoadW	r0,V300f0
			RecDlgBoxCSet_Grau
			lda	sysDBData
			cmp	#$00
			beq	:1
			jmp	L300ExitGD
::1			jmp	DOS_Format

;*** Auswahl "Weitere Disketten formatieren."
:SlctNxtDsk		MoveB	r0L,sysDBData
			jmp	RstrFrmDialogue

;*** Diskette einlegen.
:DoInsertDisk		sta	FrmtMode
			lda	curDrive
			ldx	#$7f
			jsr	InsertDisk
			cmp	#$01
			bne	L300ExitGD
			lda	FrmtMode
			rts

;*** Zurück zu geoDOS.
:L300ExitGD		jmp	InitScreen

;*** Auswahlbox erzeugen.
;    r0 zeigt auf Tabelle mit Format-Texten.
:DoFrmtTypeBox		PushW	r15			;Text für Titel-Zeile merken.
			LoadW	r1,V300d0		;Zeiger auf Anfang Tabelle.

::1			ldy	#$00
			lda	(r0L),y			;Nr. des Format-Textes einlesen.
			bmi	:3			;$FF = Ende der Tabelle.
			asl				;Zeiger auf Text-String berechnen.
			asl
			asl
			asl
			tax
			ldy	#$00
::2			lda	V300b0,x		;Text in Tabelle kopieren.
			sta	(r1L),y
			inx
			iny
			cpy	#$10
			bne	:2
			AddVBW	16,r1
			IncWord	r0
			jmp	:1

::3			ldy	#$00			;Tabellen-Ende kennzeichnen.
			tya
			sta	(r1L),y

			PopW	r14			;Auswahl-Box öffnen.
			LoadW	r15,V300d0
			lda	#$00
			ldx	#$10
			ldy	#$00
			jsr	DoScrTab
			CmpBI	sysDBData,1
			beq	:4
			jmp	L300ExitGD
::4			rts

;*** Info-Box definieren.
;r15 zeigt auf Tabelle für Texte 1 & 2.
:DefInfoBox		jsr	DoInfoBox		;Info-Box aufbauen.
:DefBoxText		jsr	ClrBoxText
			LoadW	r14,V300e2		;Zeiger auf Info-Box-Text.

			ldx	#<V300e0		;Position in Info-Text kopieren.
			ldy	#>V300e0
			jsr	InsPosTxt
			ldy	#$00
			jsr	CopyText		;Text in Info-Text kopieren.

			ldx	#<V300e1		;Position in Info-Text kopieren.
			ldy	#>V300e1
			jsr	InsPosTxt
			ldy	#$02
			jsr	CopyText		;Text in Info-Text kopieren.
			lda	#$00
			tay
			sta	(r14L),y		;Text-Ende kennzeichnen.
			PrintStrgV300e2			;Info-Text ausgeben.
			rts

;*** Position der Texte in Info-Box-Text eintragn.
:InsPosTxt		stx	r0L
			sty	r0H
			ldy	#$00
::1			lda	(r0L),y
			sta	(r14L),y
			iny
			cpy	#$06
			bne	:1
			AddVBW	6,r14
			rts

;*** Text in Info-Box-Text kopieren.
:CopyText		lda	(r15L),y
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H

			ldy	#$00
::1			lda	(r0L),y
			beq	:2
			sta	(r14L),y
			iny
			bne	:1
::2			tya
			clc
			adc	r14L
			sta	r14L
			bcc	:3
			inc	r14H
::3			rts

;*** Boot-Sektor erzeugen.
; r10 = Zeiger auf Boot-Infos.
:MakeBootSek		ldy	#$1d
::1			lda	(r0L),y
			sta	Disk_Sek,y
			sta	Boot_Sektor,y
			dey
			bpl	:1
			jsr	InitForIO		;I/O aktivieren.
			lda	$d012			;Zufalls-Zahl holen.
			and	#%00000011		;Zeiger auf Datenträger-Nummer (0-3).
			tay
			ldx	#$03			;Startwert für 4 Bytes.
::2			jsr	:4			;Zufalls-Zahl in Datenträger-Nummer
			dex				;übertrgen.
			bpl	:2
			jsr	DoneWithIO		;I/O deaktivieren.
			ldy	#$f0
::3			lda	Boot_Info  +  0,y
			sta	Disk_Sek   + 30,y
			sta	Boot_Sektor+ 30,y
			lda	Boot_Info  +241,y
			sta	Disk_Sek   +271,y
			sta	Boot_Sektor+271,y
			dey
			cpy	#$ff
			bne	:3
			rts

::4			lda	$d012
			sta	Boot_Info+ 9,y
			iny
			cpy	#$04
			bcc	:5
			ldy	#$00
::5			rts

;*** Abschluß-Infos.
:PrintInfo		jsr	DOS_GetDskNam		;Disk-Name lesen.

			jsr	InitForBA		;Freie Bytes...
			jsr	Max_Free
			lda	#<Free_Byte
			ldy	#>Free_Byte
			jsr	MOVMF
			jsr	x_FLPSTR
			jsr	DoneWithBA
			LoadW	r0,$0101
			LoadW	r1,V300g3
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

			jsr	InitForBA		;Freie Sektoren...
			LoadFAC	Free_Sek
			jsr	x_FLPSTR
			jsr	DoneWithBA
			LoadW	r0,$0101
			LoadW	r1,V300g5
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

			jsr	InitForBA		;Freie Cluster...
			LoadFAC	Free_Clu
			jsr	x_FLPSTR
			jsr	DoneWithBA
			LoadW	r0,$0101
			LoadW	r1,V300g7
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

			jsr	InitForBA		;Hauptverzeichnis
			lda	Anz_Files
			ldx	Anz_Files+1
			jsr	Word_FAC
			jsr	x_FLPSTR
			jsr	DoneWithBA
			LoadW	r0,$0101
			LoadW	r1,V300g9
			ldx	#r0L
			ldy	#r1L
			jsr	CopyString

;*** Dialogbox aufbauen.
			LoadW	r0,V300g0		;Abschluß-Info.
			RecDlgBoxV300RVec
			rts

;*** Farben setzen und Titel ausgeben.
:L300Col_1		SetColRam23,4*40+9,$61
			Pattern	1
			FillRec	32,39,72,255
			jsr	UseGDFont
			PrintXY	80,38,V300g10
			jmp	UseSystemFont

;*** Farben zurücksetzen.
:V300RVec		PushB	r2L
			SetColRam24,4*40+8,$b1
			PopB	r2L
			rts

;*** Window verlassen.
:V300ExitW		LoadB	sysDBData,1
			jmp	RstrFrmDialogue

;*** Job für Formatieren starten.
:FormatDisk		sta	HDRS
			C_Send	SetHDRS
			lda	#$ea
			jsr	SendJob

			LoadB	HDRS+0,$01		;Start-Track für Format.
			LoadB	HDRS+1,$00
			LoadB	HDRS2+0,"F"		;"Format"-Kennung.
			LoadB	HDRS2+1,"D"
			LoadB	SIDS,$f0

			lda	#$f0			;"Format"-Befehl.
			jsr	SendJobData

;*** Boot-Sektor(en) schreiben
:L300a1			LoadW	r15,V300c4
			jsr	DefBoxText

			lda	#$82
			jsr	SendJob
			lda	#$c0
			jsr	SendJob
			lda	#$b0
			jsr	SendJob

			Load_VReg1,0,1
			SvSekData
			ClrW	V300j1
			LoadW	a8,Disk_Sek

			jsr	D_Write
			txa
			bne	L300a3

			jsr	i_FillRam
			w	512,Disk_Sek
			b	$00

:L300a2			jsr	Inc_Sek
			IncWord	V300j1
			CmpW	V300j1,AreSek
			beq	L300a4

			jsr	D_Write
			txa
			bne	L300a3
			jmp	L300a2

:L300a3			jmp	DiskError

;*** Schreiben der FAT(s)
:L300a4			LoadW	r15,V300c5
			jsr	DefBoxText

			MoveB	Anz_Fat,V300j3
			jsr	i_FillRam
			w	9*512,FAT
			b	$00

::1			ClrW	V300j4
			LoadW	a0,Boot_Sektor
			LoadW	a1,FAT

			MoveB	Media,r4L		;Media-Descriptor
			LoadB	r4H,$ff			;in FAT schreiben.
			lda	#$00			;(1/2 Cluster)
			tax
			jsr	Set_Clu
			LoadW	r4,$ffff
			lda	#$01
			ldx	#$00
			jsr	Set_Clu

			LoadW	a8,FAT
			jsr	D_Write
			txa
			bne	L300a5
			LoadW	a8,Disk_Sek
			LoadW	r0,512
			LoadW	r1,Disk_Sek
			jsr	ClearRam
			lda	#$03
			jsr	WR_Block
			jmp	:3

::2			jsr	F_Write
::3			txa
			bne	L300a5
			jsr	Inc_Sek
			IncWord	V300j4
			CmpW	V300j4,SekFat
			bne	:2

			dec	V300j3
			beq	L300a6
			jmp	:1

:L300a5			jmp	DiskError

;*** Hauptverzeichnis anlegen.
:L300a6			LoadW	r15,V300c6
			jsr	DefBoxText

			jsr	GetMdrSek
			MoveW	MdrSektor,V300j2

			LoadW	r0,512
			LoadW	r1,Disk_Sek
			jsr	ClearRam
			lda	#$03
			jsr	WR_Block

::1			jsr	F_Write
			txa
			bne	L300a5
			jsr	Inc_Sek
			SubVW	1,V300j2
			CmpW0	V300j2
			bne	:1
			rts

;*** 1581-DOS-Format.
:Format1581

;******************************************************************************
if DOS81Info = TRUE
;******************************************************************************
			Pattern	0
			FillRec	128,183,8,310
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec130,181,10,308,%11111111
			FrameRec131,180,11,307,%11111111

			jsr	UseSystemFont
			PrintXY	17,143,V300i0
			PrintXY	17,153,V300i1
			PrintXY	17,163,V300i2
			PrintXY	17,173,V300i3
;******************************************************************************
endif
;******************************************************************************

			jsr	PurgeTurbo		;"1581-DOS-Format"-Routine ins 1581-RAM
			LoadW	a8,DOS_1581		;übertragen.
			lda	#$03
			jsr	WR_Block

			InitSPort
			CxSend	V300k0
::1			CxSend	GetJOBS

			ClrB	STATUS
			DrvTalk	curDrive
			ChkStatus:2
			jsr	$ffa5
			sta	ReturnCode
			DrvUnTalk

			lda	ReturnCode		;Job erledigt ?
			bmi	:1			;Nein, weiter...
			cmp	#$02
			bcs	:2
			jsr	DoneWithIO

			Pattern	2
			FillRec	128,183,8,310
			jmp	L300a1

::2			DrvUnTalk
			jsr	DoneWithIO
			ldx	#$0c
			jmp	DiskError

;*** DOS-Inhaltsverzeichnis löschen.
:ClrDisk		jsr	GetBSek
			jsr	InitFAT
			jsr	L300a4
			jmp	SetDskName

;*** Boot-Informationen 720KB, 1440 KB & 2880 KB.
:Boot_720		b $eb,$3c,$90			;Jump-Befehl zur Boot-Routine.
			b "GEODOS64"			;Herstellername + Version.
			w $0200				;Anzahl Bytes pro Sektor.
			b $02				;Anzahl Sektoren pro Cluster.
			w $0001				;Anzahl reservierter Sektoren.
			b $02				;Anzahl File-Allocation-Tables (FAT).
			w 112				;Anzahl Einträge im Hauptverzeichnis.
			w 1440				;Anzahl Sektoren im Volume.
			b $f9				;Media-Descriptor.
			w $0003				;Anzahl Sektoren pro FAT.
			w $0009				;Anzahl Sektoren pro Spur.
			w $0002				;Anzahl der Schreib-/Lese-Köpfe.
			w $0000				;Entfernung des ersten Sektors im
							;Volume vom ersten Sektor auf dem
							;Speichermedium.

:Boot_1440		b $eb,$3c,$90			;Jump-Befehl zur Boot-Routine.
			b "GEODOS64"			;Herstellername + Version.
			w $0200				;Anzahl Bytes pro Sektor.
			b $01				;Anzahl Sektoren pro Cluster.
			w $0001				;Anzahl reservierter Sektoren.
			b $02				;Anzahl File-Allocation-Tables (FAT).
			w 224				;Anzahl Einträge im Hauptverzeichnis.
			w 2880				;Anzahl Sektoren im Volume.
			b $f0				;Media-Descriptor.
			w $0009				;Anzahl Sektoren pro FAT.
			w $0012				;Anzahl Sektoren pro Spur.
			w $0002				;Anzahl der Schreib-/Lese-Köpfe.
			w $0000				;Entfernung des ersten Sektors im
							;Volume vom ersten Sektor auf dem
							;Speichermedium.

:Boot_2880		b $eb,$3c,$90			;Jump-Befehl zur Boot-Routine.
			b "GEODOS64"			;Herstellername + Version.
			w $0200				;Anzahl Bytes pro Sektor.
			b $02				;Anzahl Sektoren pro Cluster.
			w $0001				;Anzahl reservierter Sektoren.
			b $02				;Anzahl File-Allocation-Tables (FAT).
			w 224				;Anzahl Einträge im Hauptverzeichnis.
			w 5760				;Anzahl Sektoren im Volume.
			b $f0				;Media-Descriptor.
			w $0009				;Anzahl Sektoren pro FAT.
			w $0012				;Anzahl Sektoren pro Spur.
			w $0002				;Anzahl der Schreib-/Lese-Köpfe.
			w $0000				;Entfernung des ersten Sektors im
							;Volume vom ersten Sektor auf dem
							;Speichermedium.

;*** Allgemeine Boot-Informationen.
:Boot_Info		b $00,$00,$00,$00		;Reserviert.
			b $00,$00,$00,$00
			b $29
			b $d9,$0e,$1d,$17		;Volume-Nummer.
			b "GEODOS V1.0"			;Volume-Name.
			b $46,$41,$54,$31		;FAT-Typ         (FAT12).
			b $32,$20,$20,$20

;*** Boot-Routine

			b $fa,$33,$c0,$8e,$d0,$bc,$00,$7c
			b $16,$07,$bb,$78,$00,$36,$c5,$37
			b $1e,$56,$16,$53,$bf,$3e,$7c,$b9
			b $0b,$00,$fc,$f3,$a4,$06,$1f,$c6
			b $45,$fe,$0f,$8b,$0e,$18,$7c,$88
			b $4d,$f9,$89,$47,$02,$c7,$07,$3e
			b $7c,$fb,$cd,$13,$72,$79,$33,$c0
			b $39,$06,$13,$7c,$74,$08,$8b,$0e
			b $13,$7c,$89,$0e,$20,$7c,$a0,$10
			b $7c,$f7,$26,$16,$7c,$03,$06,$1c
			b $7c,$13,$16,$1e,$7c,$03,$06,$0e
			b $7c,$83,$d2,$00,$a3,$50,$7c,$89
			b $16,$52,$7c,$a3,$49,$7c,$89,$16
			b $4b,$7c,$b8,$20,$00,$f7,$26,$11
			b $7c,$8b,$1e,$0b,$7c,$03,$c3,$48
			b $f7,$f3,$01,$06,$49,$7c,$83,$16
			b $4b,$7c,$00,$bb,$00,$05,$8b,$16
			b $52,$7c,$a1,$50,$7c,$e8,$92,$00
			b $72,$1d,$b0,$01,$e8,$ac,$00,$72
			b $16,$8b,$fb,$b9,$0b,$00,$be,$df
			b $7d,$f3,$a6,$75,$0a,$8d,$7f,$20
			b $b9,$0b,$00,$f3,$a6,$74,$18,$be
			b $9e,$7d,$e8,$5f,$00,$33,$c0,$cd
			b $16,$5e,$1f,$8f,$04,$8f,$44,$02
			b $cd,$19,$58,$58,$58,$eb,$e8,$8b
			b $47,$1a,$48,$48,$8a,$1e,$0d,$7c
			b $32,$ff,$f7,$e3,$03,$06,$49,$7c
			b $13,$16,$4b,$7c,$bb,$00,$07,$b9
			b $03,$00,$50,$52,$51,$e8,$3a,$00
			b $72,$d8,$b0,$01,$e8,$54,$00,$59
			b $5a,$58,$72,$bb,$05,$01,$00,$83
			b $d2,$00,$03,$1e,$0b,$7c,$e2,$e2
			b $8a,$2e,$15,$7c,$8a,$16,$24,$7c
			b $8b,$1e,$49,$7c,$a1,$4b,$7c,$ea
			b $00,$00,$70,$00,$ac,$0a,$c0,$74
			b $29,$b4,$0e,$bb,$07,$00,$cd,$10
			b $eb,$f2,$3b,$16,$18,$7c,$73,$19
			b $f7,$36,$18,$7c,$fe,$c2,$88,$16
			b $4f,$7c,$33,$d2,$f7,$36,$1a,$7c
			b $88,$16,$25,$7c,$a3,$4d,$7c,$f8
			b $c3,$f9,$c3,$b4,$02,$8b,$16,$4d
			b $7c,$b1,$06,$d2,$e6,$0a,$36,$4f
			b $7c,$8b,$ca,$86,$e9,$8a,$16,$24
			b $7c,$8a,$36,$25,$7c,$cd,$13,$c3
			b $0d,$0a,$4b,$65,$69,$6e,$20,$53
			b $79,$73,$74,$65,$6d,$20,$6f,$64
			b $65,$72,$20,$4c,$61,$75,$66,$77
			b $65,$72,$6b,$73,$66,$65,$68,$6c
			b $65,$72,$0d,$0a,$57,$65,$63,$68
			b $73,$65,$6c,$6e,$20,$75,$6e,$64
			b $20,$54,$61,$73,$74,$65,$20,$64
			b $72,$81,$63,$6b,$65,$6e,$0d,$0a
			b $00,$49,$4f,$20,$20,$20,$20,$20
			b $20,$53,$59,$53,$4d,$53,$44,$4f
			b $53,$20,$20,$20,$53,$59,$53,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $55,$aa

;*** Variablen.
:FrmtMode		b $00

:V300a0			b >L300ExitGD-1
			b >L300ExitGD-1,>L300ExitGD-1,>Slct1581  -1
			b >L300ExitGD-1,>L300ExitGD-1,>L300ExitGD-1
			b >L300ExitGD-1,>L300ExitGD-1
			b >SlctFD2   -1,>SlctFD4   -1,>L300ExitGD-1
:V300a1			b <L300ExitGD-1
			b <L300ExitGD-1,<L300ExitGD-1,<Slct1581  -1
			b <L300ExitGD-1,<L300ExitGD-1,<L300ExitGD-1
			b <L300ExitGD-1,<L300ExitGD-1
			b <SlctFD2   -1,<SlctFD4   -1,<L300ExitGD-1
:V300a2			b >ClrDisk   -1,>DOS_720   -1,>DOS_1440  -1,>DOS_2880  -1
:V300a3			b <ClrDisk   -1,<DOS_720   -1,<DOS_1440  -1,<DOS_2880  -1

;*** Format-Texte.
:V300b0			b "Inhalt löschen  "
:V300b1			b "MS-DOS DD  720Kb"
:V300b2			b "MS-DOS HD 1.44Mb"
:V300b3			b "MS-DOS ED 2.88Mb"

:V300b10		b "Disk wird formatiert...",NULL
:V300b11		b "(MS-DOS 720 KByte)",NULL
:V300b12		b "(MS-DOS 1.44 MByte)",NULL
:V300b13		b "(MS-DOS 2.88 MByte)",NULL
:V300b14		b "Schreibe Boot-Sektor",NULL
:V300b15		b "Schreibe FAT 1 & 2",NULL
:V300b16		b "auf Diskette...",NULL
:V300b17		b "Hauptverzeichnis",NULL
:V300b18		b "wird angelegt...",NULL
:V300b19		b "Laufwerk wird",NULL
:V300b20		b "initialisiert...",NULL
:V300b21		b NULL

:V300c0			w V300b10,V300b21		;Verzeichnis löschen.
:V300c1			w V300b10,V300b11		;720 KByte.
:V300c2			w V300b10,V300b12		;1.44 MByte.
:V300c3			w V300b10,V300b13		;2.88 MByte.
:V300c4			w V300b14,V300b16		;Schreibe Boot-Sektor...
:V300c5			w V300b15,V300b16		;Schreibe FAT 1 & 2...
:V300c6			w V300b17,V300b18		;Hauptverzeichnis...
:V300c7			w V300b19,V300b20		;Laufwerk wird initialisert...

:Types1581		b 0,1,$ff			;1581
:Types_FD2		b 0,1,2,$ff			;FD 2000
:Types_FD4		b 0,1,2,3,$ff			;FD 4000

:Titel1581		b PLAINTEXT,REV_ON,"1581 - Optionen",NULL
:Titel_FD2		b PLAINTEXT,REV_ON,"FD 2000 - Optionen",NULL
:Titel_FD4		b PLAINTEXT,REV_ON,"FD 4000 - Optionen",NULL

:V300d0			s 4*16
			b NULL

;*** Infobox.
:V300e0			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b PLAINTEXT,BOLDON
:V300e1			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b PLAINTEXT,BOLDON
:V300e2			s 80

;*** Infobox: "Weitere Disketten formatieren ?"
:V300f0			b $01
			b 56,127
			w 64,255
			b DBUSRICON ,  2, 48
			w V300f3
			b DBUSRICON , 16, 48
			w V300f4
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V300f1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V300f2
			b DB_USR_ROUT
			w ISet_Frage
			b NULL

:V300f1			b PLAINTEXT,BOLDON
			b "Weitere Disketten",NULL
:V300f2			b "formatieren ?",NULL

:V300f3			w icon_Ja
			b $00,$00
			b icon_Ja_x,icon_Ja_y
			w SlctNxtDsk

:V300f4			w icon_Nein
			b $00,$00
			b icon_Nein_x,icon_Nein_y
			w SlctNxtDsk

;*** Icons für Dialog-Box.
:icon_Ja
<MISSING_IMAGE_DATA>
:icon_Ja_x		= .x
:icon_Ja_y		= .y

:icon_Nein
<MISSING_IMAGE_DATA>
:icon_Nein_x		= .x
:icon_Nein_y		= .y

;*** Abschluß-Info.
:V300g0			b $81
			b OK         , 16, 72
			b DB_USR_ROUT
			w L300Col_1
			b DBUSRICON  ,  0,  0
			w V300h0
			b DBTXTSTR   , 16, 22
			w V300g1
			b DBTXTSTR   , 70, 22
			w dosDiskName
			b DBTXTSTR   , 16, 32
			w V300g2
			b DBTXTSTR   , 16, 42
			w V300g4
			b DBTXTSTR   , 16, 52
			w V300g6
			b DBTXTSTR   , 16, 62
			w V300g8
			b NULL

:V300g1			b PLAINTEXT,BOLDON
			b "Name"
			b GOTOX
			w 120
			b ": "
			b NULL

:V300g2			b PLAINTEXT,BOLDON
			b "Freie Bytes"
			b GOTOX
			w 175
			b ": "
:V300g3			s $10

:V300g4			b PLAINTEXT,BOLDON
			b "Freie Sektoren"
			b GOTOX
			w 175
			b ": "
:V300g5			s $10

:V300g6			b PLAINTEXT,BOLDON
			b "Freie Cluster"
			b GOTOX
			w 175
			b ": "
:V300g7			s $10

:V300g8			b PLAINTEXT,BOLDON
			b "Dateien/Directory"
			b GOTOX
			w 175
			b ": "
:V300g9			s $10

:V300g10		b PLAINTEXT,REV_ON
			b "Information"
			b NULL

:V300h0			w icon_Close
			b 0,0
			b icon_Close_x,icon_Close_y
			w V300ExitW

;******************************************************************************
if DOS81Info = TRUE
;******************************************************************************

;*** Hinweis: "1581 wird noch nicht unterstützt!"
:V300i0			b PLAINTEXT,BOLDON
			b "Die hier verwendete Format-Routine ist kompatibel",NULL
:V300i1			b "zum 'Big Blue Reader' (C) M. Miller. Beide Routinen",NULL
:V300i2			b "bereiten einigen Laufwerken vom Typ 1581 Probleme!",NULL
:V300i3			b "(PC's können diese Disketten dann nicht bearbeiten.)",NULL

;******************************************************************************
endif
;******************************************************************************

:V300j1			w $0000
:V300j2			w $0000
:V300j3			w $0000
:V300j4			w $0000

;*** 1581-DOS-Format-Routine starten.
:V300k0			w $0005
			b "M-E",$00,$03

;*** 1581-DOS-Format-Routine.
:DOS_1581		lda	#$c0
			sta	$02
::1			lda	$02
			bmi	:1

			lda	#$82
			sta	$02
::2			lda	$02
			bmi	:2

			lda	#$09
			sta	$92
			sta	$93
			lda	#$32
			sta	$9a
			lda	#$00
			sta	$9b

::3			lda	#$00
			sta	$01ce
			lda	#$9c
			sta	$02
::4			lda	$02
			bmi	:4

			lda	$4000
			and	#$fe
			ora	$01ce
			eor	#$01
			sta	$4000

			lda	#$00
			sta	$88
			lda	#$8e
			sta	$02
::5			lda	$02
			bmi	:5

			lda	$01ce
			bne	:6
			lda	#$01
			nop
			jmp	$0320

::6			lda	#$00
			sta	$0b
			lda	#$01
			sta	$0c
			lda	#$01
			sta	$01bc

			lda	#$8c
			sta	$02
::7			lda	$02
			bmi	:7

			inc	$0339
			inc	$0350
			inc	$0358

			lda	$0339
			cmp	#$50
			bne	:3

			lda	#$c0
			sta	$02
::8			lda	$02
			bmi	:8

			lda	#$82
			sta	$02
::9			lda	$02
			bmi	:9

			lda	#$00
			sta	$0b
			lda	#$01
			sta	$0c
			lda	#$01
			sta	$01ce

			lda	#$a8
			sta	$02
::10			lda	$02
			bmi	:10

			rts
