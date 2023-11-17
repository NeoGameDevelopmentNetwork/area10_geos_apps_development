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
			t	"src.DOSDRIVE.ext"
endif

			n	"mod.#301.obj",NULL
			f	SYSTEM
			c	"GD_DOS      V2.1",NULL
			a	"M. Kanet",NULL
			i
<MISSING_IMAGE_DATA>

			o	ModStart
			q	EndProgrammCode
			r	EndAreaDOS

			jmp	DOS_Format
			jmp	DOS_Rename

			t	"-DOS_SetName"

;*** L300: Diskette formatieren.
:DOS_Format		ldx	curDrive		;Format-Routine auswählen.
			ldy	DriveTypes-8,x
			lda	V301a0,y
			pha
			lda	V301a1,y
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
			adc	#<V301c0
			sta	r15L
			lda	#$00
			adc	#>V301c0
			sta	r15H
			jsr	DefInfoBox
			pla

			tay				;Format-Art auswählen.
			lda	V301a2,y
			pha
			lda	V301a3,y
			pha
			rts

:DOS_Clear		jsr	GetBSek
			jsr	InitFAT
			jsr	DOS_GetDskNam
			jsr	L300a4
			jsr	ClrBox
			jsr	NewDiskName		;Disketten-Name eingeben.
			jsr	PrintInfo		;Abschluß-Infos.
			jmp	AskDoFrmtAgn

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
			beq	:101
			jsr	FormatDisk		;Formatieren starten.
			jmp	SetDskName

::101			jsr	Format1581

;*** Disketten-Name eingeben.
:SetDskName		jsr	ClrBox
			jsr	NewFrmtName		;Disketten-Name eingeben.
			jsr	PrintInfo		;Abschluß-Infos.

;*** Abfrage zum formatieren weiterer Disketten...
:AskDoFrmtAgn		DB_UsrBoxV301f0
			lda	sysDBData
			cmp	#$03
			beq	:101
			jmp	L300ExitGD
::101			jmp	DOS_Format

;*** Diskette einlegen.
:DoInsertDisk		sta	FrmtMode
			lda	curDrive
			ldx	#$7f
			jsr	InsertDisk
			cmp	#$01
			bne	L300ExitGD
			lda	FrmtMode
			rts

;*** Zurück zu GeoDOS.
:L300ExitGD		jmp	InitScreen

;*** Auswahlbox erzeugen.
;    r0 zeigt auf Tabelle mit Format-Texten.
:DoFrmtTypeBox		PushW	r15			;Text für Titel-Zeile merken.
			LoadW	r1,FileNTab		;Zeiger auf Anfang Tabelle.

::101			ldy	#$00
			lda	(r0L),y			;Nr. des Format-Textes einlesen.
			bmi	:103			;$FF = Ende der Tabelle.
			asl				;Zeiger auf Text-String berechnen.
			asl
			asl
			asl
			tax
			ldy	#$00
::102			lda	V301b0,x		;Text in Tabelle kopieren.
			sta	(r1L),y
			inx
			iny
			cpy	#$10
			bne	:102
			AddVBW	16,r1
			IncWord	r0
			jmp	:101

::103			ldy	#$00			;Tabellen-Ende kennzeichnen.
			tya
			sta	(r1L),y

			PopW	V301e1			;Auswahl-Box öffnen.
			lda	#<V301e0
			ldx	#>V301e0
			jsr	SelectBox

			lda	r13L
			beq	:104
			jmp	L300ExitGD
::104			ldx	r13H
			rts

;*** Info-Box definieren.
;r15 zeigt auf Tabelle für Texte 1 & 2.
:DefInfoBox		jsr	DoInfoBox		;Info-Box aufbauen.
:DefBoxText		jsr	ClrBoxText
			LoadW	r14,V301g2		;Zeiger auf Info-Box-Text.
			ldx	#<V301g0		;Position in Info-Text kopieren.
			ldy	#>V301g0
			jsr	InsPosTxt
			ldy	#$00
			jsr	CopyText		;Text in Info-Text kopieren.
			ldx	#<V301g1		;Position in Info-Text kopieren.
			ldy	#>V301g1
			jsr	InsPosTxt
			ldy	#$02
			jsr	CopyText		;Text in Info-Text kopieren.
			lda	#$00
			tay
			sta	(r14L),y		;Text-Ende kennzeichnen.
			PrintStrgV301g2			;Info-Text ausgeben.
			rts

;*** Position der Texte in Info-Box-Text eintragn.
:InsPosTxt		stx	r0L
			sty	r0H
			ldy	#$00
::101			lda	(r0L),y
			sta	(r14L),y
			iny
			cpy	#$06
			bne	:101
			AddVBW	6,r14
			rts

;*** Text in Info-Box-Text kopieren.
:CopyText		lda	(r15L),y
			sta	r0L
			iny
			lda	(r15L),y
			sta	r0H

			ldy	#$00
::101			lda	(r0L),y
			beq	:102
			sta	(r14L),y
			iny
			bne	:101
::102			tya
			clc
			adc	r14L
			sta	r14L
			bcc	:103
			inc	r14H
::103			rts

;*** Boot-Sektor erzeugen.
; r10 = Zeiger auf Boot-Infos.
:MakeBootSek		ldy	#$1d
::101			lda	(r0L),y
			sta	Disk_Sek,y
			sta	Boot_Sektor,y
			dey
			bpl	:101

			jsr	InitForIO		;I/O aktivieren.
			lda	$d012			;Zufalls-Zahl holen.
			and	#%00000011		;Zeiger auf Datenträger-Nummer (0-3).
			tay
			ldx	#$03			;Startwert für 4 Bytes.
::102			jsr	:104			;Zufalls-Zahl in Datenträger-Nummer
			dex				;übertrgen.
			bpl	:102
			jsr	DoneWithIO		;I/O deaktivieren.

			ldy	#$f0
::103			lda	Boot_Info  +  0,y
			sta	Disk_Sek   + 30,y
			sta	Boot_Sektor+ 30,y
			lda	Boot_Info  +241,y
			sta	Disk_Sek   +271,y
			sta	Boot_Sektor+271,y
			dey
			cpy	#$ff
			bne	:103
			rts

;*** Datenträger-Nummer erzeugen.
::104			lda	$d012
			sta	Boot_Info+ 9,y
			iny
			cpy	#$04
			bcc	:105
			ldy	#$00
::105			rts

;*** Abschluß-Infos.
:PrintInfo		jsr	DOS_GetDskNam		;Disk-Name lesen.
			jsr	Max_Free

			DB_OK	V301i0
			rts

;*** Farben setzen und Titel ausgeben.
:PrintBlocks		jsr	UseGDFont
			PrintStrgV301i1
			PrintStrgdosDiskName

			PrintStrgV301i2
			lda	FreeByte+0
			ldx	FreeByte+1
			ldy	FreeByte+2
			jsr	:102

			PrintStrgV301i3
			lda	FreeSek+0
			ldx	FreeSek+1
			jsr	:101

			PrintStrgV301i4
			lda	FreeClu+0
			ldx	FreeClu+1
			jsr	:101

			PrintStrgV301i5
			lda	Anz_Files+0
			ldx	Anz_Files+1

::101			ldy	#$00
::102			sta	r0L
			stx	r0H
			sty	r1L
			ldy	#$09
			jmp	DoZahl24Bit

;*** Job für Formatieren starten.
:FormatDisk		sta	HDRS
			C_Send	SetHDRS
			lda	#$ea
			jsr	SendJob

			LoadB	HDRS +0,$01		;Start-Track für Format.
			LoadB	HDRS +1,$00
			LoadB	HDRS2+0,"F"		;"Format"-Kennung.
			LoadB	HDRS2+1,"D"
			LoadB	SIDS   ,$f0

			lda	#$f0			;"Format"-Befehl.
			jsr	SendJobData

;*** Boot-Sektor(en) schreiben
:L300a1			LoadW	r15,V301c4
			jsr	DefBoxText

			lda	#$82
			jsr	SendJob
			lda	#$c0
			jsr	SendJob
			lda	#$b0
			jsr	SendJob

			lda	#$01
			ldx	#$00
			tay
			sta	Seite
			stx	Spur
			sty	Sektor

			ClrW	V301d0
			LoadW	a8,Disk_Sek
			jsr	D_Write
			txa
			bne	L300a3

			jsr	i_FillRam
			w	512,Disk_Sek
			b	$00

:L300a2			jsr	Inc_Sek
			IncWord	V301d0
			CmpW	V301d0,AreSek
			beq	L300a4

			jsr	D_Write
			txa
			bne	L300a3
			jmp	L300a2

:L300a3			jmp	DiskError

;*** Schreiben der FAT(s)
:L300a4			LoadW	r15,V301c5
			jsr	DefBoxText

			jsr	InitFAT
			MoveB	Anz_Fat,V301d2
			jsr	i_FillRam
			w	9*512,FAT
			b	$00

::101			ClrW	V301d3
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

			jsr	i_FillRam
			w	512,Disk_Sek
			b	$00

			LoadW	a8,Disk_Sek
			lda	#$03
			jsr	WR_Block
			jmp	:103

::102			jsr	F_Write
::103			txa
			bne	L300a5

			jsr	Inc_Sek
			IncWord	V301d3
			CmpW	V301d3,SekFat
			bne	:102

			dec	V301d2
			beq	L300a6
			jmp	:101
:L300a5			jmp	DiskError

;*** Hauptverzeichnis anlegen.
:L300a6			LoadW	r15,V301c6
			jsr	DefBoxText

			jsr	GetMdrSek
			MoveW	MdrSektor,V301d1

			jsr	i_FillRam
			w	512,Disk_Sek
			b	$00

			LoadW	a8,Disk_Sek
			lda	#$03
			jsr	WR_Block

::101			jsr	F_Write
			txa
			bne	L300a5

			jsr	Inc_Sek
			SubVW	1,V301d1
			CmpW0	V301d1
			bne	:101
			rts

;*** 1581-DOS-Format.
:Format1581		jsr	PurgeTurbo		;"1581-DOS-Format"-Routine ins 1581-RAM

			LoadW	a8,DOS_1581		;übertragen.
			lda	#$03
			jsr	WR_Block

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO
			CxSend	Frmt81Code
::101			CxSend	GetJOBS

			ClrB	STATUS
			DrvTalk	curDrive
			ChkStatus:102
			jsr	$ffa5
			sta	ReturnCode
			DrvUnTalk

			lda	ReturnCode		;Job erledigt ?
			bmi	:101			;Nein, weiter...
			cmp	#$02
			bcs	:102
			jsr	DoneWithIO
			jmp	L300a1

::102			DrvUnTalk
			jsr	DoneWithIO
			ldx	#$0c
			jmp	DiskError

;*** L302: Diskette umbenennen.
:DOS_Rename		jsr	DoInfoBox		;Infobox auf Bildschirm.
			PrintStrgV301h1

			lda	curDrive		;Prüfen ob Disk im
			ldx	#$00			;Laufwerk.
			jsr	InsertDisk
			cmp	#$01
			bne	:102

			jsr	GetBSek			;Boot-Sektor lesen.
			jsr	DOS_GetDskNam		;Disk-Name lesen.
			jsr	ClrBox
			lda	VolNExist
			bpl	:101

			DB_OK	V301f2			;Fehler: "Kein Platz für DiskName!"
			jmp	:102

::101			LoadW	r0,dosDiskName
			LoadB	r2H,%10111111
			jsr	SetName			;Name eingeben.

::102			jmp	InitScreen		;Zurück zu GeoDOS.

;*** Diskettennamen nach formatieren eingeben.
:NewFrmtName		jsr	DOS_GetDskNam		;Disk-Name lesen.
			LoadW	r0,V301j3
			LoadB	r2H,%00111111
			jmp	SetName

:NewDiskName		LoadW	r0,dosDiskName
			LoadB	r2H,%10111111

;*** Name definieren.
:SetName		ldy	#10
::101			lda	(r0L),y			;Zeichen aus Datei-Namen einlesen.
			sta	V301j1,y		;Leerzeichen ersetzen.
			dey
			bpl	:101

			MoveB	r2H,L302a0+1

;*** Eingabe des Disketten-Name.
:GetName		LoadW	r0,V301j1		;Zeiger auf alten Namen.
			LoadW	r1,V301j2		;Zeiger auf Eingabespeicher.
			LoadB	r2L,$ff
:L302a0			lda	#$ff
			sta	r2H
			LoadW	r3,V301j0		;Titel.
			jsr	dosSetName		;Name eingeben.
			cmp	#$01			;"OK"
			beq	:101
			cmp	#$02			;"CLOSE"
			beq	:103
			jmp	L302ExitGD		;"EXIT"

::101			ldy	#10
::102			lda	V301j2,y
			cmp	#" "
			bne	ReWrDkNam
			dey
			bpl	:102

::103			lda	VolNExist
			bne	:104

			DB_UsrBoxV301f1			;Alten Namen löschen?
			lda	sysDBData
			cmp	#$04
			beq	:104
			jmp	DelDkName

::104			jmp	L302ExitGD

;*** Name auf Disk schreiben.
:ReWrDkNam		jsr	DoInfoBox
			PrintStrgV301h2

			lda	#$00
			jmp	WriteDkNm

;*** Disketten-Name löschen.
:DelDkName		jsr	DoInfoBox		;Infobox aufbauen.
			PrintStrgV301h0

			lda	#$ff

;*** Neuen Diskettennamen schreiben.
:WriteDkNm		sta	V301j4

			jsr	GetMdrSek
			MoveW	MdrSektor,V301j5
			jsr	DefMdr

::101			LoadW	a8,Disk_Sek
			jsr	D_Read
			txa
			beq	:103
::102			jmp	DiskError

::103			ldx	#$10
::104			ldy	#$00
			lda	(a8L),y
			beq	:106
			cmp	#$e5
			beq	:106
			ldy	#$0b
			lda	(a8L),y
			and	#%00001000
			bne	:106

::105			AddVBW	32,a8
			dex
			bne	:104

			jsr	Inc_Sek
			SubVW	1,V301j5
			CmpW0	V301j5
			bne	:101

			jsr	ClrBox
			jmp	L302ExitGD

;*** Position für Diskettenname.
::106			bit	V301j4
			bmi	:109

;*** Diskettenname zurückschreiben.
			ldy	#10
::107			lda	V301j2,y		;Zeichen aus Datei-Namen einlesen.
			sta	V301k0,y		;Leerzeichen ersetzen.
			dey
			bpl	:107

			ldy	#31
::108			lda	V301k0,y		;Zeichen aus Datei-Namen einlesen.
			sta	(a8L),y			;Leerzeichen ersetzen.
			dey
			bpl	:108

			jmp	WriteDkSek

;*** Diskettenname löschen.
::109			ldy	#$00
			lda	#$e5
			sta	(a8L),y
			ldy	#$0b
			lda	#$00
			sta	(a8L),y

;*** Sektor mit Diskettenname zurück auf Diskette schreiben.
:WriteDkSek		LoadW	a8,Disk_Sek
			jsr	D_Write
			stx	:101 +1
			jsr	ClrBox

::101			ldx	#$ff
			bne	:102
			jmp	L302ExitGD
::102			jmp	DiskError

;*** Eingabe Diskettenname beenden.
:L302ExitGD		rts

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

;*** DriveType-Datentabelle.
:V301a0			b >L300ExitGD-1
			b >L300ExitGD-1,>L300ExitGD-1,>Slct1581  -1
			b >L300ExitGD-1,>L300ExitGD-1,>L300ExitGD-1,>L300ExitGD-1
			b >L300ExitGD-1
			b >L300ExitGD-1,>L300ExitGD-1
			b >SlctFD2   -1,>SlctFD4   -1,>L300ExitGD-1
			b >L300ExitGD-1
			b >Slct1581  -1,>SlctFD2   -1,>SlctFD4   -1
			b >L300ExitGD-1
:V301a1			b <L300ExitGD-1
			b <L300ExitGD-1,<L300ExitGD-1,<Slct1581  -1
			b <L300ExitGD-1,<L300ExitGD-1,<L300ExitGD-1,<L300ExitGD-1
			b <L300ExitGD-1
			b <L300ExitGD-1,<L300ExitGD-1
			b <SlctFD2   -1,<SlctFD4   -1,<L300ExitGD-1
			b <L300ExitGD-1
			b <Slct1581  -1,<SlctFD2   -1,<SlctFD4   -1
			b <L300ExitGD-1

:V301a2			b >DOS_Clear -1,>DOS_720   -1,>DOS_1440  -1,>DOS_2880  -1
:V301a3			b <DOS_Clear -1,<DOS_720   -1,<DOS_1440  -1,<DOS_2880  -1

;*** Format-Texte.
if Sprache = Deutsch
:V301b0			b "Inhalt löschen  "
:V301b1			b "PCDOS DD  720Kb "
:V301b2			b "PCDOS HD 1.44Mb "
:V301b3			b "PCDOS ED 2.88Mb "

:V301b10		b "Disk wird formatiert...",NULL
:V301b11		b "(PCDOS 720 KByte)",NULL
:V301b12		b "(PCDOS 1.44 MByte)",NULL
:V301b13		b "(PCDOS 2.88 MByte)",NULL
:V301b14		b "Schreibe Boot-Sektor",NULL
:V301b15		b "Schreibe FAT 1 & 2",NULL
:V301b16		b "auf Diskette...",NULL
:V301b17		b "Hauptverzeichnis",NULL
:V301b18		b "wird angelegt...",NULL
:V301b19		b "Laufwerk wird",NULL
:V301b20		b "initialisiert...",NULL
:V301b21		b NULL
endif

if Sprache = Englisch
:V301b0			b "Clear directory "
:V301b1			b "PCDOS DD  720Kb "
:V301b2			b "PCDOS HD 1.44Mb "
:V301b3			b "PCDOS ED 2.88Mb "

:V301b10		b "Formatting disk...",NULL
:V301b11		b "(PCDOS 720 KByte)",NULL
:V301b12		b "(PCDOS 1.44 MByte)",NULL
:V301b13		b "(PCDOS 2.88 MByte)",NULL
:V301b14		b "Writing boot-sector",NULL
:V301b15		b "Writing FAT 1 & 2",NULL
:V301b16		b "to disk...",NULL
:V301b17		b "Creating",NULL
:V301b18		b "root-directory...",NULL
:V301b19		b "Initializing",NULL
:V301b20		b "diskdrive...",NULL
:V301b21		b NULL
endif

:V301c0			w V301b10,V301b21		;Verzeichnis löschen.
:V301c1			w V301b10,V301b11		;720 KByte.
:V301c2			w V301b10,V301b12		;1.44 MByte.
:V301c3			w V301b10,V301b13		;2.88 MByte.
:V301c4			w V301b14,V301b16		;Schreibe Boot-Sektor...
:V301c5			w V301b15,V301b16		;Schreibe FAT 1 & 2...
:V301c6			w V301b17,V301b18		;Hauptverzeichnis...
:V301c7			w V301b19,V301b20		;Laufwerk wird initialisert...

:Types1581		b 0,1,$ff			;1581
:Types_FD2		b 0,1,2,$ff			;FD 2000
:Types_FD4		b 0,1,2,3,$ff			;FD 4000

if Sprache = Deutsch
:Titel1581		b PLAINTEXT,"1581 - Optionen",NULL
:Titel_FD2		b PLAINTEXT,"FD 2000 - Optionen",NULL
:Titel_FD4		b PLAINTEXT,"FD 4000 - Optionen",NULL
endif

if Sprache = Englisch
:Titel1581		b PLAINTEXT,"1581 - Options",NULL
:Titel_FD2		b PLAINTEXT,"FD 2000 - Options",NULL
:Titel_FD4		b PLAINTEXT,"FD 4000 - Options",NULL
endif

;*** Zwischenspeicher / Formatieren.
:V301d0			w $0000
:V301d1			w $0000
:V301d2			w $0000
:V301d3			w $0000

;*** Format-Auswahlbox.
:V301e0			b $00
			b $00
			b $00
			b $10
			b $00
:V301e1			w $ffff
			w FileNTab

if Sprache = Deutsch
;*** Infobox: "Weitere Disketten formatieren ?"
:V301f0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Möchten Sie eine weitere",NULL
::102			b        "Diskette formatieren ?",NULL

;*** Hinweis: "Alten Diskettennamen löschen ?"
:V301f1			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Alten Diskettennamen",NULL
::102			b        "auf Diskette löschen ?",PLAINTEXT,NULL

;*** Hinweis: "Kein Platz für Disketten-Name..."
:V301f2			w :101, :102, ISet_Achtung
::101			b BOLDON,"Kein Platz für Diskname",NULL
::102			b        "im Hauptverzeichnis !",PLAINTEXT,NULL

;*** Infobox.
:V301g0			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b PLAINTEXT,BOLDON
:V301g1			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b PLAINTEXT,BOLDON
:V301g2			s 80

;*** Info: "Diskettenname wird gelöscht..."
:V301h0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenname"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird gelöscht..."
			b NULL

;*** Info: "Diskettenname wird eingelesen..."
:V301h1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenname"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird eingelesen..."
			b NULL

;*** Info: "Schreibe neuen Namen auf Diskette..."
:V301h2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Schreibe neuen Namen"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "auf Diskette..."
			b NULL
endif

if Sprache = Englisch
;*** Infobox: "Weitere Disketten formatieren ?"
:V301f0			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Would you like to",NULL
::102			b        "format another disk ?",NULL

;*** Hinweis: "Alten Diskettennamen löschen ?"
:V301f1			w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Clear existing",NULL
::102			b        "diskname ?",PLAINTEXT,NULL

;*** Hinweis: "Kein Platz für Disketten-Name..."
:V301f2			w :101, :102, ISet_Achtung
::101			b BOLDON,"Cnnot create diskname!",NULL
::102			b        "(Directory full)",PLAINTEXT,NULL

;*** Infobox.
:V301g0			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b PLAINTEXT,BOLDON
:V301g1			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b PLAINTEXT,BOLDON
:V301g2			s 80

;*** Info: "Diskettenname wird gelöscht..."
:V301h0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskname will"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "be deleted..."
			b NULL

;*** Info: "Diskettenname wird eingelesen..."
:V301h1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "current diskname..."
			b NULL

;*** Info: "Schreibe neuen Namen auf Diskette..."
:V301h2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Writing new"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "diskname to disk..."
			b NULL
endif

if Sprache = Deutsch
;*** Abschluß-Info.
:V301i0			w :101, :101, PrintBlocks
::101			b NULL

:V301i1			b PLAINTEXT
			b GOTOXY
			w 56
			b 56
			b "Name"
			b GOTOX
			w 120
			b ": ",NULL

:V301i2			b PLAINTEXT
			b GOTOXY
			w 56
			b 72
			b "Freie Bytes"
			b GOTOX
			w 179
			b ": ",NULL

:V301i3			b PLAINTEXT
			b GOTOXY
			w 56
			b 80
			b "Freie Sektoren"
			b GOTOX
			w 179
			b ": ",NULL

:V301i4			b PLAINTEXT
			b GOTOXY
			w 56
			b 88
			b "Freie Cluster"
			b GOTOX
			w 179
			b ": ",NULL

:V301i5			b PLAINTEXT
			b GOTOXY
			w 56
			b 96
			b "Anzahl Dateien im"
			b GOTOXY
			w 56
			b 104
			b "Hauptverzeichnis"
			b GOTOX
			w 179
			b ": ",NULL

;*** Variablen.
:V301j0			b PLAINTEXT,"Neuer Diskettenname",NULL
:V301j1			s 17
:V301j2			s 17
:V301j3			b "GEO_PCDOS       ",NULL
:V301j4			b $00				;$00 = Diskettename schreiben.
							;$FF = Diskettenname löschen.
:V301j5			w $0000				;Anzahl Sektoren Hauptverzeichnis.

:V301k0			s 11
			b $08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
			w $0000,$0000
			w $0000
			w $0000,$0000
:V301k1			w $0000
endif

if Sprache = Englisch
;*** Abschluß-Info.
:V301i0			w :101, :101, PrintBlocks
::101			b NULL

:V301i1			b PLAINTEXT
			b GOTOXY
			w 56
			b 56
			b "Name"
			b GOTOX
			w 120
			b ": ",NULL

:V301i2			b PLAINTEXT
			b GOTOXY
			w 56
			b 72
			b "Free bytes"
			b GOTOX
			w 179
			b ": ",NULL

:V301i3			b PLAINTEXT
			b GOTOXY
			w 56
			b 80
			b "Free sectors"
			b GOTOX
			w 179
			b ": ",NULL

:V301i4			b PLAINTEXT
			b GOTOXY
			w 56
			b 88
			b "Free cluster"
			b GOTOX
			w 179
			b ": ",NULL

:V301i5			b PLAINTEXT
			b GOTOXY
			w 56
			b 96
			b "No. of files in"
			b GOTOXY
			w 56
			b 104
			b "root-directory"
			b GOTOX
			w 179
			b ": ",NULL

;*** Variablen.
:V301j0			b PLAINTEXT,"New diskname",NULL
:V301j1			s 17
:V301j2			s 17
:V301j3			b "GEO_PCDOS       ",NULL
:V301j4			b $00				;$00 = Diskettename schreiben.
							;$FF = Diskettenname löschen.
:V301j5			w $0000				;Anzahl Sektoren Hauptverzeichnis.

:V301k0			s 11
			b $08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
			w $0000,$0000
			w $0000
			w $0000,$0000
:V301k1			w $0000
endif

;*** 1581-DOS-Format-Routine starten.
:Frmt81Code		w $0005
			b "M-E",$00,$03

;*** 1581-DOS-Format-Routine.
:DOS_1581		lda	#$c0
			sta	$02
::101			lda	$02
			bmi	:101

			lda	#$82
			sta	$02
::102			lda	$02
			bmi	:102

			lda	#$09
			sta	$92
			sta	$93
			lda	#$32
			sta	$9a
			lda	#$00
			sta	$9b

::103			lda	#$00
			sta	$01ce
			lda	#$9c
			sta	$02
::104			lda	$02
			bmi	:104

			lda	$4000
			and	#$fe
			ora	$01ce
			eor	#$01
			sta	$4000

			lda	#$00
			sta	$88
			lda	#$8e
			sta	$02
::105			lda	$02
			bmi	:105

			lda	$01ce
			bne	:106
			lda	#$01
			nop
			jmp	$0320

::106			lda	#$00
			sta	$0b
			lda	#$01
			sta	$0c
			lda	#$01
			sta	$01bc

			lda	#$8c
			sta	$02
::107			lda	$02
			bmi	:107

			inc	$0339
			inc	$0350
			inc	$0358

			lda	$0339
			cmp	#$50
			bne	:103

			lda	#$c0
			sta	$02
::108			lda	$02
			bmi	:108

			lda	#$82
			sta	$02
::109			lda	$02
			bmi	:109

			lda	#$00
			sta	$0b
			lda	#$01
			sta	$0c
			lda	#$01
			sta	$01ce

			lda	#$a8
			sta	$02
::110			lda	$02
			bmi	:110

			rts

:EndProgrammCode

;*** Speicher für DOS-Hauptverzeichnis...
:Memory1
:Memory2		= (Memory1 / 256 +1) * 256
