; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L400: Diskette formatieren.
:CBM_Format		ldx	curDrive		;Format-Routine auswählen.
			ldy	DriveTypes-8,x
			lda	V400a0,y
			pha
			lda	V400a1,y
			pha
			rts

;*** Zurück zu geoDOS.
:L400ExitGD		jmp	SetMenu			;Zurück zu geoDOS.

:Slct1541		LoadW	r0 ,Types1541		;Auswahlbox mit 1541-Format-Optionen.
			LoadW	r15,Titel1541
			jsr	DoFrmtTypeBox
			lda	Types1541,x
			jmp	SlctCBMDisk

:Slct1571		LoadW	r0 ,Types1571		;Auswahlbox mit 1571-Format-Optionen.
			LoadW	r15,Titel1571
			jsr	DoFrmtTypeBox
			lda	Types1571,x
			jmp	SlctCBMDisk

:Slct1581		LoadW	r0 ,Types1581		;Auswahlbox mit 1581-Format-Optionen.
			LoadW	r15,Titel1581
			jsr	DoFrmtTypeBox
			lda	Types1581,x
:SlctCBMDisk		ldx	#$01
			stx	FrmtNxDsk
			jsr	DoInsertDisk
			jmp	SlctFormat

:SlctRAM41		lda	#35			;1541-RAM-Disk löschen.
			ldx	#<V400o0
			ldy	#>V400o0
			jmp	SlctRAM

:SlctRAM71		lda	#70			;1571-RAM-Disk löschen.
			ldx	#<V400o1
			ldy	#>V400o1
			jmp	SlctRAM

:SlctRAM81		lda	#80			;1581-RAM-Disk löschen.
			ldx	#<V400o2
			ldy	#>V400o2

:SlctRAM		sta	AnzTracks		;RAM-Disk löschen.
			stx	VekSekTab+0
			sty	VekSekTab+1

			jsr	AskToClrRAM
			lda	#$02
			jmp	SlctFormat

:SlctRL							;RL-Partition löschen.
:SlctRD							;RD-Partition löschen.
:SlctHD			lda	#$00			;HD-Partition löschen.
			b $2c
:SlctPart		lda	#$01			;FD-Partition löschen.
			sta	FrmtNxDsk		;Partition löschen.
			jsr	AskToClrPart
			lda	#$01
			jmp	SlctFormat

:SlctFD2		LoadW	r0 ,Types_FD2		;Auswahlbox mit FD2-Format-Optionen.
			LoadW	r15,Titel_FD2
			jsr	DoFrmtTypeBox
			lda	Types_FD2,x
			jmp	SlctFD

:SlctFD4		LoadW	r0 ,Types_FD4		;Auswahlbox mit FD4-Format-Optionen.
			LoadW	r15,Titel_FD4
			jsr	DoFrmtTypeBox
			lda	Types_FD4,x
:SlctFD			cmp	#$01
			beq	SlctPart
			jsr	DoInsertDisk
			jmp	SlctFormat

;*** Formatieren starten...
:SlctFormat		pha				;Info-Box definieren.
			asl
			asl
			clc
			adc	#<V400c0
			sta	r15L
			lda	#$00
			adc	#>V400c0
			sta	r15H
			jsr	DefInfoBox
			pla

			tay				;Format-Art auswählen.
			lda	V400a2,y
			pha
			lda	V400a3,y
			pha
			rts

:ClrDir							;Verzeichnis löschen.
:ClrPart		jsr	CBM_GetDskNam		;Partition löschen.
			jsr	SetFrmtName_b
			lda	#$00
			jsr	SetCBMFrmtOpt
			C_Send	V400i1
			jsr	OpenDisk		;Diskette öffnen.
			lda	isGEOS			;GEOS-Diskette ?
			beq	:1			;Nein, weiter.
			lda	curDirHead+$ab		;Border-Block als
			sta	r3L			;"Belegt" kennzeichnen.
			lda	curDirHead+$ac
			sta	r3H
			jsr	SetNextFree
			jsr	PutDirHead		;BAM zurück auf Diskette.
::1			jsr	SetName
			lda	FrmtNxDsk		;Weitere Disketten formatieren ?
			beq	:2			;Nicht bei RL,RD und HD.
			jmp	AskDoFrmtAgn
::2			jmp	L400ExitGD		;Zurück zu geoDOS.

:ClrRam			jmp	ClrRamDisk		;Inhalt der RAM-Disk löschen.

:Std1541						;1541-Diskette formatieren.
:Std1571						;1571-Diskette formatieren.
:Std1581		jsr	SetFrmtName_a		;1581-Diskette formatieren.
			lda	#$01
			jsr	SetCBMFrmtOpt
			C_Send	V400i1
			jsr	SetName
			jmp	AskDoFrmtAgn

:QF1541			jsr	PurgeTurbo		;"QuickFormat"-Routine ins 1541-RAM
			LoadW	a8,FastFormat		;übertragen.
			lda	#$05
			jsr	WR_Block
			C_Send	V400i2			;QuickFormat starten.
			jsr	SetName
			jmp	AskDoFrmtAgn

:Disk1581		lda	#$01			;Standard 1581-Disk erzeugen.
			ldx	#$00
			beq	CMD_Frmt
:CMD_DD			lda	#$01			;CMD-Diskette mit 1x 1581 Partition.
			ldx	#$01
			bne	CMD_Frmt
:CMD_HD			lda	#$02			;CMD-Diskette mit 2x 1581 Partition.
			ldx	#$02
			bne	CMD_Frmt
:CMD_ED			lda	#$04			;CMD-Diskette mit 4x 1581 Partition.
			ldx	#$03
			bne	CMD_Frmt
:CMD_DDNAT		lda	#$01			;CMD Native-Mode-Partition.
			ldx	#$04
			bne	CMD_Frmt
:CMD_HDNAT		lda	#$01			;CMD Native-Mode-Partition.
			ldx	#$05
			bne	CMD_Frmt
:CMD_EDNAT		lda	#$01			;CMD Native-Mode-Partition.
			ldx	#$06

:CMD_Frmt		ldy	#$01
			pha				;Format-Werte merken.
			txa
			pha
			tya
			pha
			jsr	SetFrmtName_a
			pla
			jsr	SetCBMFrmtOpt		;Format-Befehl definieren.
			pla
			jsr	SetCMDFrmtOpt
			C_Send	V400i1			;Diskette formatieren.
			LoadB	V400j2 +4,1
			pla
::1			pha				;Disk- & Partitions-Name ändern.
			C_Send	V400j2
			jsr	SetName
			inc	V400j2 +4
			pla
			sub	1
			bne	:1
			jmp	AskDoFrmtAgn

;*** Ersten Dir-Block löschen.
:ClrRamDisk		jsr	GetDirHead		;BAM einlesen.
			MoveW	VekSekTab,r1		;Sektor-Tabelle nach r1.
			MoveB	AnzTracks,r6L		;Anzahl Tracks nach r6.

::1			ldy	r6L			;Anzahl Sektoren/Track einlesen.
			dey
			lda	(r1L),y
			sub	1
			sta	r6H
::2			jsr	FreeBlock		;Alle Sektoren eines Tracks freigeben.
			dec	r6H
			bpl	:2
			dec	r6L
			bne	:1

			jsr	PutDirHead		;Neue BAM speichern.

			jsr	Get1stDirEntry		;Ersten Verzeichnis-Sektor löschen.
			ldy	#$00
			tya
::3			sta	diskBlkBuf,y
			iny
			bne	:3
			lda	#$ff
			sta	diskBlkBuf+1

			jsr	PutBlock
			jsr	SetName
			jmp	L400ExitGD

;*** Auswahlbox erzeugen.
;    r0 zeigt auf Tabelle mit Format-Texten.
:DoFrmtTypeBox		PushW	r15			;Text für Titel-Zeile merken.
			LoadW	r1,V400d0		;Zeiger auf Anfang Tabelle.

::1			ldy	#$00
			lda	(r0L),y			;Nr. des Format-Textes einlesen.
			bmi	:3			;$FF = Ende der Tabelle.
			asl				;Zeiger auf Text-String berechnen.
			asl
			asl
			asl
			tax
			ldy	#$00
::2			lda	V400b0,x		;Text in Tabelle kopieren.
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
			LoadW	r15,V400d0
			lda	#$00
			ldx	#$10
			ldy	#$00
			jsr	DoScrTab
			CmpBI	sysDBData,1
			beq	:4
			jmp	L400ExitGD

::4			rts

;*** Info-Box definieren.
;r15 zeigt auf Tabelle für Texte 1 & 2.
:DefInfoBox		LoadW	r14,V400g2		;Zeiger auf Info-Box-Text.

			ldx	#<V400g0		;Position in Info-Text kopieren.
			ldy	#>V400g0
			jsr	InsPosTxt
			ldy	#$00
			jsr	CopyText		;Text in Info-Text kopieren.

			ldx	#<V400g1		;Position in Info-Text kopieren.
			ldy	#>V400g1
			jsr	InsPosTxt
			ldy	#$02
			jsr	CopyText		;Text in Info-Text kopieren.
			lda	#$00
			tay
			sta	(r14L),y		;Text-Ende kennzeichnen.
			jsr	DoInfoBox		;Info-Box aufbauen.
			PrintStrgV400g2			;Info-Text ausgeben.
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

;*** Frage: "RAM-Disk löschen ?"
:AskToClrRAM		LoadW	V400e1,V400b41
			jmp	AskToClr

;*** Frage: "Partition löschen ?"
:AskToClrPart		InitSPort			;Partitions-Daten einlesen.
			CxSend	GetCurPart
			CxReceiveCurPartDat
			jsr	DoneWithIO

			lda	CurPartDat+2
			beq	:1
			bpl	:2

::1			pla				;Fehler: "Keine aktive Partition!"
			pla
			lda	curDrive
			add	$39
			sta	V400f2 +12
			LoadW	r0,V400f0
			RecDlgBoxCSet_Grau
			jmp	CBM_Format

::2			LoadW	V400e1,V400b40

;*** Frage: "RAM-Disk/Partition löschen ?"
:AskToClr		lda	curDrive		;Laufwerk in Info-Box.
			add	$39
			sta	V400b42 + 9
			jsr	CBM_GetDskNam		;Disketten-Name einlesen.

			ldy	#$00			;Disketten-Name in Info-Box-Text
::1			lda	cbmDiskName,y		;übertragen.
			cmp	#" "
			bcc	:2
			cmp	#$7f
			bcc	:3
::2			lda	#" "
::3			sta	V400b43 +6,y
			iny
			cpy	#$10
			bne	:1

			LoadW	r0,V400e0		;Info-Box öffnen.
			RecDlgBoxCSet_Grau
			CmpBI	sysDBData,1
			bne	:4
			rts

::4			jmp	L400ExitGD

;*** Abfrage zum formatieren weiterer Disketten...
:AskDoFrmtAgn		LoadW	r0,V400h0
			RecDlgBoxCSet_Grau
			lda	sysDBData
			cmp	#$00
			beq	:1
			jmp	L400ExitGD
::1			jmp	CBM_Format

;*** Auswahl "Weitere Disketten formatieren."
:SlctNxtDsk		MoveB	r0L,sysDBData
			jmp	RstrFrmDialogue

;*** Diskette einlegen.
:DoInsertDisk		sta	FrmtMode
			lda	curDrive
			ldx	#$7f
			jsr	InsertDisk
			cmp	#$01
			bne	:1
			lda	FrmtMode
			rts

::1			jmp	L400ExitGD

;*** Name für Diskette erzeugen.
:SetFrmtName_a		ldx	#<V400i0		;"geoDOS" als Disketten-Name setzen.
			ldy	#>V400i0
			jmp	SetFrmtName

:SetFrmtName_b		ldx	#<cbmDiskName		;Alten Disketten-Namen setzen.
			ldy	#>cbmDiskName

:SetFrmtName		stx	r0L
			sty	r0H

			LoadW	r1,V400i1+4		;Name in Format-Befehl übertragen.
			ldy	#$00
::1			lda	(r0L),y
			sta	(r1L),y
			iny
			cpy	#$10
			bne	:1

			AddVBW	16,r1
			LoadW	V400i1,18		;Länge des Format-Befehls.
			rts

;*** CBM Format-Option definieren.
:SetCBMFrmtOpt		asl				;ID an Format-Befehl anhängen.
			asl
			tax
			ldy	#$00
::1			lda	V400j0,x
			sta	(r1L),y
			inx
			iny
			cpy	#$03
			bne	:1

			AddVBW	3,r1
			LoadW	V400i1,21		;Länge des Format-Befehls.
			rts

;*** CMD Format-Option definieren.
:SetCMDFrmtOpt		asl				;CMD-ID an Format-Befehl anhängen.
			asl
			tax
			ldy	#$00
::1			lda	V400j1,x
			sta	(r1L),y
			inx
			iny
			cpy	#$04
			bne	:1

			LoadW	V400i1,25		;Länge des Format-Befehls.
			rts

;*** Variablen.
:FrmtMode		b $00
:CMDParts		b $00
:AnzTracks		b $00
:VekSekTab		w $0000
:FrmtNxDsk		b $00

:V400a0			b >L400ExitGD-1
			b >Slct1541  -1,>Slct1571  -1,>Slct1581  -1
			b >SlctRAM41 -1,>SlctRAM71 -1,>SlctRAM81 -1
			b >SlctRL    -1,>SlctRD    -1
			b >SlctFD2   -1,>SlctFD4   -1,>SlctHD    -1
:V400a1			b <L400ExitGD-1
			b <Slct1541  -1,<Slct1571  -1,<Slct1581  -1
			b <SlctRAM41 -1,<SlctRAM71 -1,<SlctRAM81 -1
			b <SlctRL    -1,<SlctRD    -1
			b <SlctFD2   -1,<SlctFD4   -1,<SlctHD    -1
:V400a2			b >ClrDir    -1,>ClrPart   -1,>ClrRam    -1
			b >Std1541   -1,>QF1541    -1
			b >Std1571   -1,>Std1581   -1,>Disk1581  -1
			b >CMD_DD    -1,>CMD_HD    -1,>CMD_ED    -1
			b >CMD_DDNAT -1,>CMD_HDNAT -1,>CMD_EDNAT -1
:V400a3			b <ClrDir    -1,<ClrPart   -1,<ClrRam    -1
			b <Std1541   -1,<QF1541    -1
			b <Std1571   -1,<Std1581   -1,<Disk1581  -1
			b <CMD_DD    -1,<CMD_HD    -1,<CMD_ED    -1
			b <CMD_DDNAT -1,<CMD_HDNAT -1,<CMD_EDNAT -1

;*** Format-Texte.
:V400b0			b "Inhalt löschen  "
:V400b1			b "Format Partition"
:V400b2			b "Format RAM-Disk "
:V400b3			b "Standard 170 KB "
:V400b4			b "Quick-Format    "
:V400b5			b "Standard 340 KB "
:V400b6			b "Standard 790 KB "
:V400b7			b "Typ 1581, 790 KB"
:V400b8			b "DD, 1x    790 KB"
:V400b9			b "HD, 2x    790 KB"
:V400b10		b "ED, 4x    790 KB"
:V400b11		b "DD, CMD   800 KB"
:V400b12		b "HD, CMD  1600 KB"
:V400b13		b "ED, CMD  3200 KB"

:V400b20		b "Inhaltsverzeichnis",NULL
:V400b21		b "Inhalt der Partition",NULL
:V400b22		b "Inhalt der RAM-Disk",NULL
:V400b23		b "wird gelöscht...",NULL
:V400b24		b "Disk wird formatiert...",NULL
:V400b25		b "(Standard, 170 KByte)",NULL
:V400b26		b "(QuickFormat, 170 KB)",NULL
:V400b27		b "(Standard, 340 KByte)",NULL
:V400b28		b "(Standard, 790 KByte)",NULL
:V400b29		b "(Standard 1581-Disk)",NULL
:V400b30		b "(DD, 1x 790 KByte)",NULL
:V400b31		b "(HD, 2x 790 KByte)",NULL
:V400b32		b "(ED, 4x 790 KByte)",NULL
:V400b33		b "(DD, CMD 800 KByte)",NULL
:V400b34		b "(HD, CMD 1600 KByte)",NULL
:V400b35		b "(ED, CMD 3200 KByte)",NULL

:V400b40		b PLAINTEXT,BOLDON,"Inhalt der Partition auf",NULL
:V400b41		b PLAINTEXT,BOLDON,"Inhalt der RAM-Disk auf",NULL
:V400b42		b "Laufwerk x: löschen ?",NULL
:V400b43		b "Name: ________________",NULL

:V400c0			w V400b20,V400b23		;Verzeichnis löschen.
:V400c1			w V400b21,V400b23		;Partition löschen.
:V400c2			w V400b22,V400b23		;RAM-Disk löschen.
:V400c3			w V400b24,V400b25		;Standard 1541, 170 KByte.
:V400c4			w V400b24,V400b26		;QuickFormat 1541, 170 KByte.
:V400c5			w V400b24,V400b27		;Standard 1571, 340 KByte.
:V400c6			w V400b24,V400b28		;Standard 1581, 790 KByte.
:V400c7			w V400b24,V400b29		;1581-Diskette.
:V400c8			w V400b24,V400b30		;DD, 1 x 790 KByte.
:V400c9			w V400b24,V400b31		;HD, 2 x 790 KByte.
:V400c10		w V400b24,V400b32		;ED, 4 x 790 KByte.
:V400c11		w V400b24,V400b33		;DD, CMD 800 KByte.
:V400c12		w V400b24,V400b34		;HD, CMD 1600 KByte.
:V400c13		w V400b24,V400b35		;ED, CMD 3200 KByte.

:Types1541		b 0,3,4,$ff			;1541
:Types1571		b 0,5,$ff			;1571
:Types1581		b 0,6,$ff			;1581
:Types_FD2		b 1,7,8,9,11,12,$ff		;FD 2000
:Types_FD4		b 1,7,8,9,10,11,12,13,$ff	;FD 4000

:Titel1541		b PLAINTEXT,REV_ON,"1541 - Optionen",NULL
:Titel1571		b PLAINTEXT,REV_ON,"1571 - Optionen",NULL
:Titel1581		b PLAINTEXT,REV_ON,"1581 - Optionen",NULL
:Titel_FD2		b PLAINTEXT,REV_ON,"FD 2000 - Optionen",NULL
:Titel_FD4		b PLAINTEXT,REV_ON,"FD 4000 - Optionen",NULL

:V400d0			s 8*16
			b NULL

;*** Formatierungs-Befehle.
:V400i0			b "geoDOS          ",NULL
:V400i1			w $0012
			b "N:________________,64,DD8"
:V400i2			w $0005
			b "M-E",$60,$06

:V400j0			b 0,0,0,0,",64 "
:V400j1			b ",81 ,DD8,HD8,ED8,DDN,HDN,EDN"
:V400j2			w $0003
			b 67,208,0

;*** Frage: "RAM-Disk/Partition löschen ?"
:V400e0			b $01
			b 56,143
			w 64,255
			b OK        ,  2, 64
			b CANCEL    , 16, 64
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
:V400e1			w V400b43
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
:V400e2			w V400b42
			b DBTXTSTR  , 16, 52
:V400e3			w V400b43
			b DB_USR_ROUT
			w ISet_Frage
			b NULL

;*** Hinweis: "Keine aktive Partition auf Laufwerk x:"
:V400f0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V400f1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V400f2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V400f1			b PLAINTEXT,BOLDON
			b "Keine aktive Partition",NULL
:V400f2			b "in Laufwerk x: !",NULL

;*** Infobox.
:V400g0			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b PLAINTEXT,BOLDON
:V400g1			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b PLAINTEXT,BOLDON
:V400g2			s 80

;*** Infobox: "Weitere Disketten formatieren ?"
:V400h0			b $01
			b 56,127
			w 64,255
			b DBUSRICON ,  2, 48
			w V400h3
			b DBUSRICON , 16, 48
			w V400h4
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V400h1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V400h2
			b DB_USR_ROUT
			w ISet_Frage
			b NULL

:V400h1			b PLAINTEXT,BOLDON
			b "Weitere Disketten",NULL
:V400h2			b "formatieren ?",NULL

:V400h3			w icon_Ja
			b $00,$00
			b icon_Ja_x,icon_Ja_y
			w SlctNxtDsk

:V400h4			w icon_Nein
			b $00,$00
			b icon_Nein_x,icon_Nein_y
			w SlctNxtDsk

;*** Anzahl Sektoren pro Spur, 1541.
:V400o0			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$13,$13,$13,$13,$13,$13,$13
			b $12,$12,$12,$12,$12,$12,$11,$11
			b $11,$11,$11

;*** Anzahl Sektoren pro Spur, 1571.
:V400o1			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$13,$13,$13,$13,$13,$13,$13
			b $12,$12,$12,$12,$12,$12,$11,$11
			b $11,$11,$11,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$13,$13,$13,$13
			b $13,$13,$13,$12,$12,$12,$12,$12
			b $12,$11,$11,$11,$11,$11

;*** Anzahl Sektoren pro Spur, 1581.
:V400o2			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28
			b $28,$28,$28,$28,$28,$28,$28,$28

;*** Icons für Dialog-Box.
:icon_Ja
<MISSING_IMAGE_DATA>
:icon_Ja_x		= .x
:icon_Ja_y		= .y

:icon_Nein
<MISSING_IMAGE_DATA>
:icon_Nein_x		= .x
:icon_Nein_y		= .y

;*** Fast-Format für 1541.
:FastFormat		nop
			CmpBI	$0a,36			;Spur = 36 ?, Ja, Ende erreicht.
			bcc	l050e			;Aktuelle Spur formatieren.
			LoadB	$43,18			;Kopf auf Spur 18 = Directory.
			jmp	$0513

:l050e			jsr	$f24b			;Anzahl Sektoren pro Spur ermitteln.
			sta	$43

:l0513			LoadB	$1b,0			;Sektor-Nr. löschen.
			ldy	#$00 			;"Binär"-Sektor erzeugen.
			ldx	#$00
:l051b			lda	$39 			;Sektorheader-Kennbyte.
			sta	$0300,y
			iny
			iny
			lda	$1b 			;Sektor-Nummer.
			sta	$0300,y
			iny
			lda	$0a 			;Spur-Nummer.
			sta	$0300,y
			iny
			lda	$13 			;Zweites Zeichen der ID.
			sta	$0300,y
			iny
			lda	$12 			;Erstes Zeichen der ID.
			sta	$0300,y
			iny
			lda	#$0f 			;Zwei Header-Abschluß-Bytes.
			sta	$0300,y
			iny
			sta	$0300,y
			iny
			lda	#$00
			eor	$02fa,y			;Prüfsumme über Sektor-,Spur-Nummer und
			eor	$02fb,y			;ID. Ergebniss in Byte $01 der Sektor-
			eor	$02fc,y			;Daten (hinter Sektorheader-Kennbyte).
			eor	$02fd,y
			sta	$02f9,y
			inc	$1b 			;Header für alle Sektoren erzeugen.
			CmpB	$1b,$43			;Alle Sektoren ?
			bcc	l051b			;Nein, Schleife...

			LoadB	$31,3			;Zeiger auf aktuellen Datenpuffer.

			tya				;yReg zwischenspeichern.	
			pha
			txa				;Puffer ab $0700 löschen.
:l0564			sta	$0700,x
			inx
			bne	l0564
			jsr	$fe30			;Header von Binär nach GCR wandeln.
			pla				;yReg wieder herstellen.
			tay
			dey
			jsr	$fde5			;Bytes in Puffer umkopieren.
			jsr	$fdf5			;GCR-Header umkopieren.

			LoadB	$31,7			;Zeiger auf aktuellen Datenpuffer.

			jsr	$f5e9			;Pufferprüfsumme berechnen.
			sta	$3a
			jsr	$f78f			;Pufferinhalt von Binär -> GCR wandeln.

			LoadB	$32,0			;Zeiger auf ersten Sektor-Header.
			jsr	$fe0e			;Gesamte Spur löschen (mit $55).

:l0589			LoadB	$1c01,$ff		;5x SYNC-Byte.
			ldx	#$05
:l0590			bvc	l0590
			clv
			dex
			bne	l0590

			ldx	#$0a			;Sektor-Header schreiben.
			ldy	$32
:l059a			bvc	l059a
			clv
			lda	$0300,y
			sta	$1c01
			iny
			dex
			bne	l059a

			ldx	#$09			;9x Füllbyte.
:l05a9			bvc	l05a9
			clv
			LoadB	$1c01,$55
			dex
			bne	l05a9

;*** Fast-Format (fortsetzung...)
			lda	#$ff			;5x SYNC-Byte.
			ldx	#$05
:l05b8			bvc	l05b8
			clv
			sta	$1c01
			dex
			bne	l05b8

			ldx	#$bb			;Sektor-Inhalt schreiben.
:l05c3			bvc	l05c3
			clv
			lda	$0100,x
			sta	$1c01
			inx
			bne	l05c3
			ldy	#$00
:l05d1			bvc	l05d1
			clv
			lda	($30),y
			sta	$1c01
			iny
			bne	l05d1

			lda	#$55			;8x Füllbyte.
			ldx	#$08
:l05e0			bvc	l05e0
			clv
			sta	$1c01
			dex
			bne	l05e0

			AddVB	10,$32			;Zeiger auf nächsten Sektor-Header.
			dec	$1b 			;Alle Sektoren geschrieben ?
			bne	l0589			;Nein, Schleife...

:l05f4			bvc	l05f4			;Warten bis alle Bytes geschrieben.
			clv
:l05f7			bvc	l05f7
			clv

			jsr	$fe00			;Kopf auf lesen umschalten.

			LoadB	$1f,$c8			;Anzahl Leseversuche für Sektor-Verify.
:l0601			LoadW	$0030,$0300		;Zeiger auf aktuellen Puffer.
			MoveB	$43,$1b			;Sektor-Zähler initialisieren.

:l060d			jsr	$f556			;Warten auf SYNC.

			ldx	#$0a
			ldy	#$00
:l0614			bvc	l0614			;Warten auf Byte von Disk.
			clv
			lda	$1c01
			cmp	($30),y			;Byte mit GCR-Header-Daten vergleichen.
			bne	l062c			;Nein, Schleife...
			iny
			dex	 			;Kompletten GCR-Header vergleichen.
			bne	l0614			;Alle Bytes verifiziert? Nein,Schleife.
			AddVB	10,$30 			;Zeiger auf nächsten Header.
			jmp	$0635			;Sektor-Inhalte prüfen.

:l062c			dec	$1f 			;Nächster Lese-Versuch.
			bne	l0601
			lda	#$06 			;"FORMAT"-Fehler.
			jmp	$fdd3

:l0635			jsr	$f556			;Warten auf SYNC.

			ldy	#$bb 			;Sektor-Inhalte vergleichen.
:l063a			bvc	l063a
			clv
			lda	$1c01
			cmp	$0100,y
			bne	l062c
			iny
			bne	l063a
			ldx	#$fc
:l064a			bvc	l064a
			clv
			lda	$1c01
			cmp	$0700,y
			bne	l062c
			iny
			dex
			bne	l064a

			dec	$1b 			;Nächsten Sektor suchen und
			bne	l060d			;vergleichen.
			jmp	$fd9e			;Spur formatiert, "OK".

;*** Einsprung für Format-Routine.
:l0660			ldy	#$00 			;Disketten-Name und ID übertragen.
:l0662			lda	$06e0,y
			sta	$0200,y
			iny
			cpy	$06df
			bcc	l0662

			lda	$06df			;Länge Disk-Name + ID.
			sta	$0274
			lda	$06de			;Zeiger auf ID.
			sta	$027b

			LoadB	$7f,0			;Laufwerks-Nr. immer '0'.
			jsr	$c100			;LED einschalten.

;*** Fast-Format (fortsetzung...)
			ldy	$027b			;ID in ID-Speicher übertragen.
			lda	$0200,y
			sta	$12
			lda	$0201,y
			sta	$13

			jsr	$d307			;Floppy-Kanäle schliesen.

			LoadB	$1c05,$1a		;Timer setzen.

			LoadB	$00,$c0			;Kopf auf Spur '0' setzen.
:l069a			lda	$00
			bmi	l069a

			ldx	$06dc			;Erste zu formatierende Spur.
:l06a1			stx	$0a			;Nr. der zu formatierenden Spur merken
			lda	#$e0			;und Spur formatieren.
			sta	$02
:l06a7			lda	$02
			bmi	l06a7
			cmp	#$02			;"FORMAT"-Fehler ?
			bcs	l06bb			;Ja, Abbruch.
			inx				;Zeiger auf nächste Spur.
			cpx	$06dd			;Alle Spuren formatiert ?
			bcc	l06a1			;Nein, Schleife...

			jsr	$ee40			;BAM & Directory erzeugen.
			rts				;Ende.
			nop
			nop

:l06bb			ldx	#$02			;Fehler-Meldung erzeugen.
			jmp	$e60a			;und Ende...

			s	28			;Füllbytes.

:l06dc			b	$01			;Erste Spur.
:l06dd			b	$24			;Letzte Spur +1.
:l06de			b	$07			;Zeiger auf ID.
:l06df			b	$09			;Länge Name + ID.

:l06e0			b	"geoDOS,64"
			s	23
