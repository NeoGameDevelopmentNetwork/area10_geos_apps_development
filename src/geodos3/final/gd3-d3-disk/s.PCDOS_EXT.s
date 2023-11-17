; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtDDrv"

;*** GEOS-Header.
			n "obj.PCDOS"
			t "G3_Sys.Author"
			f 3 ;DATA

;*** Zusätzliche Symboltabellen.
if .p
			t "s.PCDOS.ext"
			t "s.DOS_Turbo.ext"
endif

			o APP_RAM

:vReadDirectory		jmp	xReadDirectory
:vCalcBlksFree		jmp	xCalcBlksFree
:vOpenRootDir		jmp	xOpenRootDir
:vOpenSubDir		jmp	xOpenSubDir
:vTestNewDisk		jmp	xTestNewDisk
:vGetDirHead		jmp	xGetDirHead

;*** Aktuelles Verzeichnis einlesen und konvertieren.
:xReadDirectory		jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Laufwerksfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	Save_Reg_r0_r4

			jsr	SwapDOS_Buffer
			jsr	SwapFAT_Buffer

			jsr	InitForIO		;I/O aktivieren.

			lda	#$00
			sta	CountEntrys
			jsr	ReadDirEntrys

			jsr	DoneWithIO

			jsr	SwapFAT_Buffer
			jsr	SwapDOS_Buffer

			jmp	Load_Reg_r0_r4
::51			rts

;*** Verzeichniseinträge einlesen.
:ReadDirEntrys		jsr	ClrDirSekBuf		;Verzeichnis-Speicher löschen.

			lda	#$00			;Zeiger auf virtuelles
			sta	SelectedEntry		;Verzeichnis setzen.

			lda	#Tr_1stDataSek
			sta	VecDataSektor +0
			lda	#Se_1stDataSek
			sta	VecDataSektor +1

			lda	#< RAM_AREA_ALIAS
			sta	VecRamBuffer  +0
			lda	#> RAM_AREA_ALIAS
			sta	VecRamBuffer  +1

			bit	Flag_DirType
			bpl	:51
			jmp	ReadSDirEntrys
::51			jmp	ReadRDirEntrys

;*** Hauptverzeichnis einlesen.
:ReadRDirEntrys		ldy	#$11			;Diskettenname zurücksetzen.
::51			lda	DummyDiskName  ,y	;Wichtig für
			sta	CurrentDiskName,y
			dey
			bpl	:51

			ldx	#Tr_1stDirSek
			stx	CurDOS_DIR_Tr
			ldx	#Se_1stDirSek
			stx	CurDOS_DIR_Se

			lda	Data_1stRDirSek +0
			sta	r1L
			lda	Data_1stRDirSek +1
			sta	r1H

::52			jsr	Set_diskBlkBuf
			jsr	ReadBlock_DOS
			txa
			bne	:55
			sta	CurDOS_Entry

::53			jsr	ConvCurDirSek
			cmp	#$00
			beq	:54
			inc	r1H
			jmp	:52

::54			jsr	StashLastDirSek		;letzten Verzeichnis-Sektor

			ldx	#NO_ERROR
::55			rts

;*** Unterverzeichnis einlesen.
:ReadSDirEntrys		ldx	#Tr_1stDirSek		;Zeiger auf ersten temporären
			inx				;SubDir-Verzeichnis-Sektor.
			stx	CurDOS_DIR_Tr
			ldx	#Se_1stDirSek
			stx	CurDOS_DIR_Se

			lda	Data_1stSDirClu+0	;Zeiger auf ersten Cluster einlesen.
			sta	r1L
			lda	Data_1stSDirClu+1
			sta	r1H

::51			lda	#$00			;Zeiger auf ersten Sektor
			sta	CurSekInClu		;in aktuellem Cluster.

			lda	r1L			;Zeiger auf aktuellen
			sta	Data_CurSDirClu+0	;Cluster berechnen und Sektor
			lda	r1H			;einlesen.
			sta	Data_CurSDirClu+1
			jsr	ConvClu2Sek

::52			jsr	ConvDOS2CBMsek		;Seite/Track/Sektor in ein
							;gültiges CBM-Format konvertieren.
			jsr	Set_diskBlkBuf
			jsr	ReadBlock_DOS
			txa
			bne	:56
			sta	CurDOS_Entry

::53			jsr	ConvCurDirSek		;Sektor konvertieren.
			cmp	#$00			;Ende erreicht ?
			beq	:55			; => Ja, Ende...

			inc	CurSekInClu
			CmpB	CurSekInClu,Data_SpClu
			beq	:54

			jsr	Inc_Sek			;Zeiger auf nächsten Sektor
			jmp	:52			;in Cluster und weiterlesen.

::54			lda	Data_CurSDirClu+0	;Zeiger auf nächsten Cluster.
			ldx	Data_CurSDirClu+1
			jsr	GetClusterLink

			CmpWI	r1,$0ff0		;Ende erreicht ?
			bcc	:51			; => Nein, weiter...

::55			jsr	StashLastDirSek		;Letzten Sektor speichern.

			ldx	#NO_ERROR
::56			rts

;*** Aktuellen DOS-Verzeichnis-Sektor konvertieren.
:ConvCurDirSek		ldy	#$00
			lda	(r4L),y
			bne	:51			; => Verzeichnis-Ende erreicht.
			rts

::51			cmp	#$e5
			beq	:53			; => Gelöschte Datei übergehen.

			cmp	#"."
			bne	:51a
			iny
			lda	(r4L),y
			cmp	#"."
			bne	:53

			ldy	#$1a
			lda	(r4L),y
			sta	Data_ParentSDir+0
			iny
			lda	(r4L),y
			sta	Data_ParentSDir+1
			jmp	:53

::51a			ldy	#$0b
			lda	(r4L),y
			cmp	#%00001000		;Diskettenname ?
			bne	:51b			; => Nein, weiter...

			dey				;Diskettenname kopieren.
::51c			lda	(r4L),y
			sta	CurrentDiskName,y
			dey
			bpl	:51c
			bmi	:53

::51b			and	#%00001000		;WIN9x/NT "LongFileName" ?
			bne	:53			; => Ja, übergehen.

			ldy	#$1f
::52			lda	(r4L)       ,y
			sta	dirDEntryBuf,y
			dey
			bpl	:52

			PushW	r1
			PushW	r4
			jsr	SelectDirEntry		;Eintrag kopieren.
			PopW	r4
			PopW	r1

			lda	#$00			;Flag:"Verzeichnis-Ende erreicht"
			inc	CountEntrys		;256 Einträge im Speicher ?
			beq	:54			; => Ja, Ende...

::53			AddVBW	32,r4			;Zeiger auf nächsten Eintrag.

			inc	CurDOS_Entry
			CmpBI	CurDOS_Entry,16		;Alle Einträge kopiert ?
			bcs	:53a			; => Ja, Ende...
			jmp	ConvCurDirSek		; => Nein, weiter...

::53a			lda	#$ff			;Flag:"Verzeichnis wird fortgesetzt"
::54			rts

;*** Zwischenspeicher löschen.
:ClrDirSekBuf		ldy	#$00
			tya
::51			sta	dir2Head   ,y
			iny
			bne	:51
			dey
			sty	dir2Head +1
			rts

;*** Verzeichnis-Eintrag konvertieren und kopieren.
:SelectDirEntry		lda	SelectedEntry
			cmp	#$08
			bne	:51

			jsr	StashDirSek

			lda	dir2Head +0
			sta	CurDOS_DIR_Tr
			lda	dir2Head +1
			sta	CurDOS_DIR_Se

			jsr	ClrDirSekBuf

			lda	#$00
			sta	SelectedEntry

::51			jsr	ConvertDirEntry

			lda	SelectedEntry
			asl
			asl
			asl
			asl
			asl
			tax
			ldy	#$00
::52			lda	dirCEntryBuf,y
			sta	dir2Head    ,x
			inx
			iny
			cpy	#$20
			bcc	:52

			inc	SelectedEntry
::53			rts

:StashDirSek		lda	CurDOS_DIR_Tr
			ldx	CurDOS_DIR_Se
			inx
			bne	StashCurDirSek

:StashLastDirSek	ldx	#$ff
			lda	#$00
:StashCurDirSek		sta	dir2Head +0
			stx	dir2Head +1

			PushW	r0
			PushW	r1
			PushW	r2
			PushB	r3L

			lda	#< dir2Head
			sta	r0L
			lda	#> dir2Head
			sta	r0H

			lda	#$00
			sta	r1L
			lda	CurDOS_DIR_Se
			clc
			adc	#> RAM_AREA_DIR
			sta	r1H

			ldx	#$00
			stx	r2L
			inx
			stx	r2H

			jsr	SetDOS_Area
			jsr	StashRAM

			PopB	r3L
			PopW	r2
			PopW	r1
			PopW	r0
			rts

:SelectedEntry		b $00
:CurDOS_DIR_Tr		b 01
:CurDOS_DIR_Se		b 00

;*** Verzeichnis-Sektor konvertieren.
:ConvertDirEntry	ldy	#$1f
			lda	#$00
::50			sta	dirCEntryBuf,y
			dey
			bpl	:50

;--- Dateityp, Cluster.
			ldx	#$c1
			lda	dirDEntryBuf +11
			and	#%00010000
			beq	:50a
			ldx	#$c6
::50a			stx	dirCEntryBuf + 2
			tax
			beq	:52

			lda	dirDEntryBuf +27
			clc
			adc	#$10
			sta	dirCEntryBuf + 3
			lda	dirDEntryBuf +26
			adc	#$00
			sta	dirCEntryBuf + 4
			jmp	:52a

::52			lda	VecDataSektor+ 0
			sta	dirCEntryBuf + 3
			lda	VecDataSektor+ 1
			sta	dirCEntryBuf + 4

;--- Dateiname.
::52a			ldy	#$00
::53			lda	(r4L),y
			sta	dirCEntryBuf + 5,y
			iny
			cpy	#$0b
			bcc	:53

			lda	#$a0
::54			sta	dirCEntryBuf + 5,y
			iny
			cpy	#$10
			bcc	:54

;--- Datum.
			ldy	#$18
			lda	(r4L),y
			sta	d0L
			iny
			lda	(r4L),y
			sta	d0H

			lda	d0L
			and	#%00011111
			sta	dirCEntryBuf +27

			ldx	#d0L
			ldy	#$05
			jsr	DShiftRight

			lda	d0L
			and	#%00001111
			sta	dirCEntryBuf +26

			ldx	#d0L
			ldy	#$04
			jsr	DShiftRight

			lda	d0L
			and	#%01111111
			clc
			adc	#80
			sta	dirCEntryBuf +25

;--- Zeit.
			ldy	#$16
			lda	(r4L),y
			sta	d0L
			iny
			lda	(r4L),y
			sta	d0H

			ldx	#d0L
			ldy	#$05
			jsr	DShiftRight

			lda	d0L
			and	#%00111111
			sta	dirCEntryBuf +29

			ldx	#d0L
			ldy	#$06
			jsr	DShiftRight

			lda	d0L
			and	#%00011111
			sta	dirCEntryBuf +28

;--- Dateigröße.
			ldy	#$1c
			clc
			lda	(r4L),y
			beq	:55
			sec
::55			iny
			lda	(r4L),y
			adc	#$00
			sta	dirCEntryBuf +30
			iny
			lda	(r4L),y
			adc	#$00
			sta	dirCEntryBuf +31

			lda	dirCEntryBuf + 2	;Unterverzeichnis ?
			and	#%00001111		;Datei-Status isolieren.
			cmp	#$06			;Unterverzeichnis ?
			bne	CreateSekAlias		; => Nein, weiter...
			rts				;Ende.

;*** Sektortabelle erzeugen.
:CreateSekAlias		lda	#$00			;Zeiger auf Byte innerhalb 512-Byte-
			sta	VecDosSektor  +0	;Sektor löschen.
			sta	VecDosSektor  +1
			sta	CountBlocks +0
			sta	CountBlocks +1

			lda	dirDEntryBuf +$1a	;Zeiger auf ersten Cluster.
			ldx	dirDEntryBuf +$1b
			sta	CurCluster +0
			stx	CurCluster +1

;--- Nächsten DOS-Cluster lesen.
::51			lda	#$00			;Zeiger auf ersten Sektor
			sta	CurSekInClu		;in aktuellem Cluster.

			lda	CurCluster +0
			ldx	CurCluster +1
			sta	r1L			;Aktuellen Cluster einlesen und
			stx	r1H			;Sektoradresse berechnen.
			jsr	ConvClu2Sek

;--- Nächsten Alias erstellen.
::52			jsr	CreateNxtAlias		;Alias-Eintrag für aktuellen CBM-
							;Sektor erstellen.

;--- Auf letzten Sektor testen.
			ldx	CurSekDataBuf +3	;Länge Restbereich ermitteln.
			cpx	#$ff
			bne	:53
			dex
::53			stx	:54 +1
			cpx	#$fe
			beq	:53a

;--- Letzter Sektor, auf Vollständigkeit prüfen.
			lda	#$00			;Zeiger auf Byte in DOS-Sektor.
			sta	r0H
			lda	CurSekDataBuf +2
			asl
			sta	r0L
			rol	r0H
			txa
			clc
			adc	r0L
			lda	r0H
			adc	#$00			;Bytes in letzten CBM-Sektor noch
			cmp	#$02			;alle in aktuellem DOS-Sektor ?
			bcc	:53c			; => Ja, Ende erreicht.

;--- Abschluß-Sektor lesen.
			inc	CurSekInClu
			CmpB	CurSekInClu,Data_SpClu
			beq	:53b

			jsr	Inc_Sek
			jsr	CreateNxtAlias		;Alias-Eintrag für aktuellen CBM-
							;Sektor erstellen.
			jmp	:56

;--- Abschluß-Cluster lesen.
::53b			lda	CurCluster +0
			ldx	CurCluster +1
			jsr	GetClusterLink

			CmpWI	r1,$0ff0
			bcs	:53c

			lda	r1L			;Aktuellen Cluster einlesen und
			ldx	r1H			;Sektoradresse berechnen.
			sta	CurCluster +0
			stx	CurCluster +1
			jsr	ConvClu2Sek

			jsr	CreateNxtAlias		;Alias-Eintrag für aktuellen CBM-
::53c			jmp	:56

;--- Zeiger auf nächsten CBM-Sektor berechnen.
::53a			AddVBW	1  ,CountBlocks

			lda	dirDEntryBuf +$1c
			sec
::54			sbc	#$01
			sta	dirDEntryBuf +$1c
			lda	dirDEntryBuf +$1d
			sbc	#$00
			sta	dirDEntryBuf +$1d
			lda	dirDEntryBuf +$1e
			sbc	#$00
			sta	dirDEntryBuf +$1e

;--- Zeiger auf nächsten DOS-Sektor berechnen.
			CmpWI	VecDosSektor,512
			bcc	:54a

			SubVW	512,VecDosSektor

			inc	CurSekInClu
			CmpB	CurSekInClu,Data_SpClu
			beq	:55
			jsr	Inc_Sek
::54a			jmp	:52

;--- Zeiger auf nächsten DOS-Cluster berechnen.
::55			lda	CurCluster +0
			ldx	CurCluster +1
			jsr	GetClusterLink

			CmpWI	r1,$0ff0
			bcs	:56

			lda	r1L			;Aktuellen Cluster einlesen und
			ldx	r1H			;Sektoradresse berechnen.
			sta	CurCluster +0
			stx	CurCluster +1
			jmp	:51

;--- Datei-Ende erreicht.
::56			lda	CountBlocks  + 0
			sta	dirCEntryBuf +30
			lda	CountBlocks  + 1
			sta	dirCEntryBuf +31
			rts

;*** Alias-Eintrag für temporären CBM-Sektor erstellen und speichern.
:CreateNxtAlias		jsr	ConvDOS2CBMsek		;Seite/Track/Sektor in ein
							;gültiges CBM-Format konvertieren.

			lda	r1L			;Sektoradresse in Sektortabellen-
			sta	CurSekDataBuf +0	;speicher kopieren.
			lda	r1H
			sta	CurSekDataBuf +1

			lda	VecDosSektor  +1	;Zeiger auf Byte in DOS-Sektor
			lsr				;durch zwei teilen um 1-Byte-Wert
			lda	VecDosSektor  +0	;zu erhalten. Zeiger ist immer
			ror				;gerade und wird später verdoppelt.
			sta	CurSekDataBuf +2

			lda	dirDEntryBuf +$1e	;Anzahl Bytes in aktuellen CBM-
			bne	:51			;Sektor ermitteln. Wert #$ff steht
			lda	dirDEntryBuf +$1d	;für "nicht letzter Sektor". Werte
			bne	:51			;von #1 bis #254 kennzeichnen den
			lda	dirDEntryBuf +$1c	;letzten Sektor.
			cmp	#255
			bcs	:52
			b $2c
::51			lda	#$ff
::52			sta	CurSekDataBuf +3

			LoadW	r0,VecDataSektor	;Sektordaten in REU kopieren.
			MoveW	VecRamBuffer,r1
			LoadW	r2,8
			jsr	SetDOS_Area
			jsr	StashRAM

			AddVBW	  8,VecRamBuffer
			AddVBW	254,VecDosSektor

			inc	VecDataSektor +1
			bne	:53
			inc	VecDataSektor +0
::53			rts

;*** Frien Speicher berechnen.
:xCalcBlksFree		PushW	r0
			PushW	r1
			PushW	r2

			jsr	SwapFAT_Buffer		;Zwischenspeicher retten.

			jsr	Def1stDataSek
			sta	FreeClu+0		;Zeiger auf reservierte Sektoren
			stx	FreeClu+1		;zwischenspeichern.

			sec				;Anzahl Datensektoren ermitteln.
			lda	Data_Anz_Sektor
			sbc	FreeClu+0
			sta	FreeClu+0
			lda	Data_Anz_Sektor+1
			sbc	FreeClu+1
			sta	FreeClu+1

			lda	Data_SpClu		;Anzahl Sektoren/Cluster.
::51			lsr
			tax
			beq	:52
			lsr	FreeClu+1
			ror	FreeClu
			txa
			jmp	:51

::52			lda	#$00
			sta	CountClu+0		;Zähler Cluster Initialisieren.
			sta	CountClu+1
			sta	CountFreeClu+0		;Zähler freie Cluster
			sta	CountFreeClu+1		;Initialisieren.

::53			clc				;Zeiger auf Cluster in FAT setzen
			lda	CountClu		;und Zeiger einlesen.
			adc	#$02
			tay
			lda	CountClu+1
			adc	#$00
			tax
			tya
			jsr	GetClusterLink

			CmpW0	r1			;Cluster frei ?
			bne	:54			;Nein, weiter...

			AddVBW	1,CountFreeClu		;Anzahl freie Cluster um 1 erhöhen.
::54			AddVBW	1,CountClu		;Zähler +1 bis alle Cluster geprüft.
			CmpW	CountClu,FreeClu
			bne	:53

			ldx	Data_SpClu		;Anzahl Blocks berechnen.
::55			asl	CountFreeClu+0		;(1 DOS-Sektor = 2 CBM-Blocks)
			rol	CountFreeClu+1
			asl	CountClu+0
			rol	CountClu+1
			txa
			lsr
			tax
			bne	:55

			jsr	SwapFAT_Buffer		;Zwischenspeicher retten.

			MoveW	CountFreeClu,r4		;Freier Speicher.
			MoveW	CountClu    ,r3		;Max. verfügbarer Speicher.

			PopW	r2
			PopW	r1
			PopW	r0

			ldx	#NO_ERROR
			rts

;*** Unterverzeichnis öffnen.
:xOpenSubDir		lda	r1L
			cmp	#Tr_1stDirSek
			beq	xOpenRootDir

			lda	r1H
			sta	Data_1stSDirClu + 0
			lda	r1L
			sec
			sbc	#$10
			sta	Data_1stSDirClu + 1

			lda	#$ff
			b $2c

;*** Hauptverzeichnis öffnen.
:xOpenRootDir		lda	#$00
			sta	Flag_DirType

			lda	#$ff
			sta	Flag_UpdateDir

			pla
			tax
			pla
			tay

			lda	#>OpenDisk -1
			pha
			lda	#<OpenDisk -1
			pha

			tya
			pha
			txa
			pha
			rts

;*** Wurde Diskette gewechselt ?
:xTestNewDisk		jsr	ExitTurbo
			jsr	InitForIO

			lda	#< com_ME_CRC
			ldx	#> com_ME_CRC
			jsr	SendFCom_CRC1
			jsr	UNLSN

			ldx	#> com_MR_CRC
			lda	#< com_MR_CRC
			ldy	#$06
			jsr	SendFCom_CRC2
			jsr	UNLSN

			lda	#$00
			sta	STATUS
			lda	curDrive
			jsr	TALK
			lda	#$ff
			jsr	TKSA

			jsr	ACPTR
			pha
			jsr	ACPTR
			pha
			jsr	UNTALK
			jsr	DoneWithIO
			pla
			tax
			pla
			tay
			lda	#$ff
			cpy	LastCRC +0
			bne	:201
			cpx	LastCRC +1
			bne	:201
			lda	#$00
::201			sty	LastCRC +0
			stx	LastCRC +1
			tax

			lda	Data_Boot +0
			ora	Data_Boot +1
			ora	Data_Boot +2		;Boot-Sektor schon im Speicher ?
			bne	:202			; => Nein, Diskette öffnen.
			ldx	#$ff
::202			rts

:com_ME_CRC		b "M-E"
			w WasDiskChanged

:com_MR_CRC		b "M-R"
			w CurDiskCRC
			b $02

:LastCRC		w $0000

;*** FAT nach Diskettenwechsel neu einlesen.
:xGetDirHead		jsr	PrintInfIcon

			jsr	xTestNewDisk
			txa
			bne	:52

			bit	Flag_UpdateDir		;Verzeichnis einlesen ?
			bmi	:52a			; => Nein, weiter...
			bpl	:53

::52			jsr	GetDirHeadOpen		; => Ja  , neu einlesen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch...

::52a			jsr	xReadDirectory		;Verzeichnis einlesen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch...

::53			jsr	UpdateDriver		;Variablen aktualisieren.

::54			ldx	#NO_ERROR		;Flag: "Kein Fehler",
			jsr	SetDiskName

::55			lda	#$00
			sta	Flag_UpdateDir
			jmp	PrintInfIcon

;*** FAT immer von Diskette lesen.
.GetDirHeadOpen		jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Diskettenfehler ?
			beq	:51			; => Nein, weiter...
			rts

::51			jsr	InitForIO		;I/O aktivieren.

			jsr	SwapBOOT_Buffer		;BOOT-Sektor-Bereich einblenden.

			LoadB	r1L,$00			;Boot-Sektor einlesen und
			LoadB	r1H,$01			;zwischenspeichern.
			jsr	Set_diskBlkBuf
			jsr	ReadBlock_DOS

			ldy	#$1d			;DOS-Variablen in Zwischenspeicher
::52			lda	diskBlkBuf,y		;kopieren.
			sta	Data_Boot ,y
			dey
			bpl	:52

			jsr	SwapBOOT_Buffer		;BOOT-Sektor zwischenspeichern.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch...

			jsr	DefAdrRootDir		;Zeiger auf Verzeichnis berechnen.

			jsr	SwapFAT_Buffer		;FAT-Bereich einblenden.

			lda	#$00			;Zeiger auf ersten FAT-Sektor
			sta	r1L			;berechnen.
			lda	Data_AreSek
			sta	r1H
			inc	r1H
			LoadW	r4,TMP_AREA_FAT
::53			jsr	ReadBlock_DOS		;FAT-Sektor laden.
			txa				;Diskettenfehler ?
			bne	:54			; => Ja, Abbruch...

			inc	r4H			;Zeiger auf FAT-Speicher
			inc	r4H			;korrigieren.

			inc	r1H			;Nächster FAT-Sektor.

			lda	Data_AreSek
			clc
			adc	Data_SekFat
			clc
			adc	#$01
			cmp	r1H			;Alle FAT-Sektoren eingelesen ?
			bne	:53			; => Nein, weiter...

			ldx	#NO_ERROR
::54			jsr	SwapFAT_Buffer		;FAT-bereich ausblenden.
::55			jmp	DoneWithIO		;I/O deaktivieren.

;*** Diskettenname und BAM erstellen.
:SetDiskName		txa				;X-Register speichern.
			pha				;(Enthält evtl. Fehlercode).

			ldy	#$00			;BAM-Sektor löschen.
			tya
::51			sta	curDirHead,y
			iny
			bne	:51

			ldx	#Tr_1stDirSek		;Zeiger auf ersten Verzeichnis-
			ldy	#Se_1stDirSek		;sektor in BAM eintragen.
			lda	Flag_DirType		;Hauptverzeichnis ?
			bpl	:52			; => Ja, weiter...
			inx
::52			stx	curDirHead   +0		;Verzeichnis-Zeiger speichern.
			sty	curDirHead   +1

			ldy	#$00			;Diskettenname kopieren.
::53			lda	CurrentDiskName,y
			sta	curDirHead +$90,y
			iny
			cpy	#$12
			bne	:53

			lda	#Tr_1stDirSek		;Zeiger auf ROOT-Verzeichnis.
			ldx	#Se_1stDirSek
			sta	curDirHead + 32
			stx	curDirHead + 33

			lda	#$00			;Dummy für Hauptverzeichnis.
			tax
			ldy	Flag_DirType
			beq	:55

			lda	Data_ParentSDir+ 0
			ora	Data_ParentSDir+ 1
			bne	:54
			lda	#Tr_1stDirSek		;Zeiger auf ROOT-Verzeichnis.
			ldx	#Se_1stDirSek
			jmp	:55

::54			lda	Data_ParentSDir+ 1
			clc
			adc	#$10
			ldx	Data_ParentSDir+ 0
::55			sta	curDirHead     +34
			stx	curDirHead     +35

			pla
			tax				;X-Register zurücksetzen.

::56			rts

;*** Informationsgrafik anzeigen.
:PrintInfIcon		pha
			txa
			pha
			tya
			pha

			ldy	#$00
			ldx	#$00
::51			cpx	#$05
			bcs	:52
			lda	COLOR_MATRIX+24*40  ,x
			pha
			lda	COL_LOAD_FAT        ,x
			sta	COLOR_MATRIX+24*40  ,x
			pla
			sta	COL_LOAD_FAT        ,x

::52			lda	SCREEN_BASE +24*40*8,y
			pha
			lda	PIC_LOAD_FAT        ,x
			sta	SCREEN_BASE +24*40*8,y
			pla
			sta	PIC_LOAD_FAT        ,x
			inx
			tya
			clc
			adc	#$08
			tay
			cpy	#40
			bcc	:51
			sbc	#40
			tay
			iny
			cpx	#$28
			bcc	:51

			pla
			tay
			pla
			tax
			pla
			rts

;******************************************************************************
;*** Include-Dateien.
;******************************************************************************
;*** Zeiger auf ":diskBlkBuf" setzen.
:Set_diskBlkBuf		LoadW	r4,diskBlkBuf
			rts
;******************************************************************************

;*** Variablen.
:FreeClu		w $0000
:CountClu		w $0000				;Zähler Cluster Initialisieren.
:CountFreeClu		w $0000				;Zähler freie Cluster Initialisieren.
:CurSekInClu		b $00

:CurDOS_Entry		b $00
:dirDEntryBuf		s 32
:dirCEntryBuf		s 32
:CountBlocks		w $0000
:CountEntrys		b $00

:VecDataSektor		b $00,$00
:CurSekDataBuf		b $00,$00,$00,$00
:CurCluster		w $0000

:VecDosSektor		w $0000
:VecRamBuffer		w $0000

:Data_CurSDirClu	w $0000

;*** Infoicons.
:PIC_LOAD_FAT		b %11111111,%11111111,%11111111,%11111111,%11111111
			b %10000000,%00000000,%00000000,%00000000,%00000001
			b %10100001,%10001100,%11100001,%11001001,%10101001
			b %10100010,%01010010,%10010001,%00101011,%00110001
			b %10100010,%01011110,%10010001,%00101000,%10110001
			b %10111001,%10010010,%11100001,%11001011,%00101001
			b %10000000,%00000000,%00000000,%00000000,%00000001
			b %11111111,%11111111,%11111111,%11111111,%11111111
:COL_LOAD_FAT		b $07,$07,$07,$07,$07
