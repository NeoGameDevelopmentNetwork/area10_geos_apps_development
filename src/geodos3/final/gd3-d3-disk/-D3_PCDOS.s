; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** RAM-Bereiche aktivieren.
.Swap_ExtData		sta	:52 +1
			sty	:52 +2

			txa
			pha

			ldx	#$06
::51			lda	r0L,x
			pha
			dex
			bpl	:51

			ldx	#$05
::52			lda	$ffff,x
			sta	r0L  ,x
			dex
			bpl	:52

			jsr	SetDOS_Area
			jsr	SwapRAM

			ldx	#$00
::53			pla
			sta	r0L,x
			inx
			cpx	#$07
			bcc	:53

			pla
			tax
			rts

;*** Register ":r0" bis ":r4" zwischenspeichern.
.Load_Reg_r0_r4		pha
			txa
			pha

			ldx	#$09
::51			lda	RegCopyBuf,x
			sta	r0L,x
			dex
			bpl	:51

			pla
			tax
			pla
			rts

;*** Register ":r0" bis ":r4" zwischenspeichern.
.Save_Reg_r0_r4		pha
			txa
			pha

			ldx	#$09
::51			lda	r0L,x
			sta	RegCopyBuf,x
			dex
			bpl	:51

			pla
			tax
			pla
			rts

:RegCopyBuf		s 10

;*** FAT laden/zurücksetzen.
.SwapFAT_Buffer		lda	Data_SekFat
			asl
			sta	:51 +5
			lda	#<:51
			ldy	#>:51
			jmp	Swap_ExtData

::51			w	TMP_AREA_FAT
			w	RAM_AREA_FAT
			w	$1200

;*** DOS-Speicher freimachen.
.SwapDOS_Buffer		lda	#<:51
			ldy	#>:51
			jmp	Swap_ExtData

::51			w	TMP_AREA_SEKTOR
			w	RAM_AREA_SEKTOR
			w	$0200

;*** BOOT-Speicher freimachen.
.SwapBOOT_Buffer	lda	#<:51
			ldy	#>:51
			jmp	Swap_ExtData

::51			w	TMP_AREA_BOOT
			w	RAM_AREA_BOOT
			w	$0200

;*** DOS-Speicher freimachen.
.SwapTMP_Buffer		lda	#<:51
			ldy	#>:51
			jmp	Swap_ExtData

::51			w	TMP_AREA_BUFFER
			w	RAM_AREA_BUFFER
			w	$0200

;*** Zeiger auf BOOT-Sektor setzen.
.SetBOOT_Area		lda	#$00
			sta	r0L
			sta	r1L
			sta	r2L
			lda	#>diskBlkBuf
			sta	r0H
			lda	#$02
			sta	r1H
			sta	r2H

;*** Zeiger auf externe Speicherbank setzen.
.SetDOS_Area		ldx	curDrive
			lda	ramBase -8,x
			sta	r3L
			rts

;*** Laufwerkstreiber aktualisieren.
.UpdateDriver		jsr	Save_Reg_r0_r4

			ldx	curDrive
			lda	DskDrvBaseL -8,x
			sta	r1L
			lda	DskDrvBaseH -8,x
			sta	r1H
			LoadW	r0 ,DISK_BASE
			LoadW	r2 ,(E_DRIVER_DATA - DISK_BASE)
			LoadB	r3L,$00
			jsr	StashRAM

			jmp	Load_Reg_r0_r4

;*** TurboDOS-Routine für !DOS.
:TurboDOS_DOS		d "obj.TurboDOS"

;*** Externe Routinen laden.
:xReadDirectory		ldy	#$00
			b $2c
:xCalcBlksFree		ldy	#$03
			b $2c
:xOpenRootDir		ldy	#$06
			b $2c
:xOpenSubDir		ldy	#$09
			b $2c
:xTestNewDisk		ldy	#$0c
			b $2c
:xGetDirHead		ldy	#$0f
			sty	DOS_VEC_BYTE

			jsr	SET_VEC_DOS_ROUT

			lda	DOS_VEC_BYTE
			ldx	#> APP_RAM
			jsr	CallRoutine
			stx	:53 +1

			jsr	SET_VEC_DOS_ROUT

::53			ldx	#$ff
			rts

;*** Zeiger auf DOS-Routinbe in REU.
:SET_VEC_DOS_ROUT	ldx	#$07
::50			lda	r0L,x
			pha
			dex
			bpl	:50

			ldx	#$05
::51			lda	DOS_SYS_VEC,x
			sta	r0L,x
			dex
			bpl	:51

			jsr	SetDOS_Area
			jsr	SwapRAM

			ldx	#$00
::52			pla
			sta	r0L,x
			inx
			cpx	#$08
			bcc	:52
			rts

;*** Bereichsangaben für DOS-Routinen in RAM.
:DOS_VEC_BYTE		b $00
:DOS_SYS_VEC		w $0400
			w $f000
			w $0800

;*** BorderBlock einlesen.
;    Übergabe:		-
;    Rückgabe:		r1	= Track/Sektor für Borderblock.
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xGetBorderBlock	ldy	#$ff
			ldx	#NO_ERROR
			rts

;*** Auf GEOS-Diskette testen.
;    Übergabe:		r5	= Zeiger auf BAM (":curDirHead").
;    Rückgabe:		AKKU	= $00, Keine GEOS-Diskette.
;    Geändert:		AKKU,xReg
:xChkDkGEOS		ldx	#NO_ERROR
			stx	isGEOS
			lda	isGEOS
			rts

;*** Sektor-Adresse testen.
:TestTrSe_ADDR		lda	#$00			;Wiederholungszähler löschen.
			sta	RepeatFunction

			ldx	#INV_TRACK		;Vorbereiten: "Falsche Sektor-Nr.".
			lda	r1L			;Track-Nummer einlesen.
			and	#$7f
			cmp	#81
			bcs	:51			; > 80, Fehler...
			sec
			rts
::51			clc
			rts

;*** Sektor nach ":diskBlkBuf" einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xGetBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jmp	DoneWithIO		;I/O abschalten
::51			rts				;Ende...

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadBlock		jsr	TestTrSe_ADDR		;Sektor-Adresse testen.
			bcc	:51			; => Fehler, Abbruch...

			lda	r1L			;Track-Adresse auswerten.
			cmp	#Tr_1stDataSek		;$01,$02 = Verzeichnis-Sektor.
			bcs	:52			; => Daten-Sektor einlesen.
			jmp	xReadDirBlock		; => Verzeichnis-Sektor einlesen.
::51			rts

::52			jsr	LoadAliasData		;Alias-Daten einlesen.

			jsr	SwapTMP_Buffer		;Zwischenspeicher einblenden.

			ldx	Data_AliasSektor +5	;Sektor-Status einlesen.
			cpx	#$ff			;Letzter Sektor ?
			bne	:53			; =>J Ja, letzten Sektor lesen.

;--- Nächster Sektor.
			lda	Data_AliasSektor +8	;Zeiger auf nächsten Sektor.
			ldx	Data_AliasSektor +9
			ldy	#$fe			;Anzahl Bytes zum kopieren.
			jmp	:54			; => Weiter...

;--- Letzter Sektor.
::53			lda	#$00			;Letzter Sektor, Anzahl Bytes in
			inx				;Sektor berechnen.
			ldy	Data_AliasSektor +5	;Anzahl Bytes zum kopieren.
::54			sty	Bytes2Copy		;Anzahl Bytes zwischenspeichern.

;--- Sektorverkettung.
			pha				;Sektorverkettung erzeugen.
			ldy	#$01
			txa
			sta	(r4L),y
			pla
			dey
			sta	(r4L),y

			jsr	ReadBytes2Buf		;Sektordaten einlesen.
			jmp	SwapTMP_Buffer		;Zwischenspeicher ausblenden.

;*** Bytes aus Puffer einlesen.
;    Übergabe:		r3  = Quelle
;			r4  = Ziel
:ReadBytes2Buf		jsr	Save_Reg_r0_r4		;Register zwischenspeichern.

			AddVBW	2,r4			;Zeiger auf Sektor-Speicher.

			lda	#$00			;Zeiger auf Byte in DOS-Sektor.
			sta	VecDOS_Sektor +1
			lda	Data_AliasSektor    +4
			asl
			sta	VecDOS_Sektor +0
			rol	VecDOS_Sektor +1

			lda	VecDOS_Sektor +0
			clc
			adc	#< curDirHead
			sta	r3L
			lda	VecDOS_Sektor +1
			adc	#> curDirHead
			sta	r3H

			lda	#$ff			;Zeiger auf DOS-Sektor setzen.
			sta	Flag_1stSektor

			lda	Data_AliasSektor +2
			ldx	Data_AliasSektor +3
			sta	r1L
			stx	r1H

			lda	CurDOS_Sek +0		;Sektor bereits im Speicher ?
			cmp	r1L
			bne	:55			; => Nein, Sektor einlesen.
			lda	CurDOS_Sek +1
			cmp	r1H
			bne	:55			; => Nein, Sektor einlesen.

			ldx	#$00			;Flag für "Sektor-lesen" löschen.
			stx	Flag_1stSektor

::50			ldy	#$00			;Sektordaten kopieren.
::51			lda	(r3L),y
			sta	(r4L),y
			iny

			inc	VecDOS_Sektor +0	;Zähler für Bytes in DOS-Sektor
			bne	:52			;korrigieren.
			inc	VecDOS_Sektor +1

::52			dec	Bytes2Copy		;Alle Bytes kopiert ?
			bne	:53			; => Nein, weiter...
			jsr	Load_Reg_r0_r4		;Register zurücksetzen.
			jsr	UpdateDriver		;Variablen in REU aktualisieren.
			ldx	#NO_ERROR		;Ende...
			rts

::53			lda	VecDOS_Sektor +1
			cmp	#$02			;Ende DOS-Sektor erreicht ?
			bne	:51			; => Nein, weiterkopieren...

			tya				;Zeiger auf Datenspeicher
			clc				;korrigieren.
			adc	r4L
			sta	r4L
			bcc	:54
			inc	r4H

::54			lda	Data_AliasSektor +10	;Zeiger auf nächsten
			ldx	Data_AliasSektor +11	;DOS-Sektor setzen.
			sta	r1L
			stx	r1H

::55			lda	r1L			;Sektoradresse speichern.
			ldx	r1H
			sta	CurDOS_Sek +0
			stx	CurDOS_Sek +1

			PushW	r4			;DOS-Sektor einlesen.
			LoadW	r4,curDirHead
			jsr	xReadBlock_DOS
			PopW	r4

			txa				;Diskettenfehler ?
			bne	:57			; => Ja, Abbruch...

			lda	Flag_1stSektor		;Zeiger auf Byte in DOS-Sektor
			ldx	#$00			;zurücksetzen ?
			stx	Flag_1stSektor
			tax
			bne	:56			; => Nein, weiter...

			LoadW	r3,curDirHead		;Zeiger auf erstes Byte
							;in neuem DOS-Sektor setzen.
			lda	#$00
			sta	VecDOS_Sektor +0
			sta	VecDOS_Sektor +1
::56			jmp	:50
::57			jmp	Load_Reg_r0_r4		;Fehler, Ende...

;*** Alias-Eintrag für Sektor einlesen.
;    Im Alias-Eintrg stehen die Werte für DOS-Track/Sektor/Cluster.
.LoadAliasData		jsr	Save_Reg_r0_r4		;Register speichern.

			lda	r1L			;Zeiger auf Alias-Tabelle
			sec				;berechnen.
			sbc	#Tr_1stDataSek
			ldx	r1H
			stx	r1L
			sta	r1H
			ldx	#r1L
			ldy	#$03
			jsr	DShiftLeft

			lda	r1L
			clc
			adc	#< TMP_AREA_ALIAS
			sta	r1L
			lda	r1H
			adc	#> TMP_AREA_ALIAS
			sta	r1H

			LoadW	r0,Data_AliasSektor
			LoadW	r2,16
			jsr	SetDOS_Area
			jsr	FetchRAM		;Alias-Daten einlesen.

			jmp	Load_Reg_r0_r4		;Register zurücksetzen.

;*** Verzeichnis-Sektor aus REU einlesen.
;    Übergabe:		r1  = Track/Sektor
;			      $01,x = Hauptverzeichnis.
;			      $02,x = Unterverzeichnis.
;			      Track wird jedoch nicht beachtet!
;			r4  = Zeiger auf 256-Byte-Sektorspeicher
:xReadDirBlock		jsr	Save_Reg_r0_r4		;Register speichern.

			lda	r4L			;Zeiger auf verzeichnis-Sektor
			sta	r0L			;in RAM berechnen.
			lda	r4H
			sta	r0H

			ldx	#$00
			stx	r1L
			lda	r1H
			clc
			adc	#> RAM_AREA_DIR
			sta	r1H

			stx	r2L
			inx
			stx	r2H
			jsr	SetDOS_Area
			jsr	FetchRAM		;Verzeichnis-Sektor einlesen.

			jmp	Load_Reg_r0_r4		;Register zurücksetzen.

;*** Sektor von MSDOS-Diskette einlesen.
;    Übergabe:		r1L = Track  (0-79)
;			r1H = Sektor (1-18, ab Se.19 = Seite #2)
;			r4  = Zeiger auf 512-Byte-Sektorspeicher
:xReadBlock_DOS		PushW	r1			;Sektor-Zeiger speichern.

			lda	Data_SekSpr +0
			ora	Data_SekSpr +1
			beq	:51

			ldx	r1H			;Relative Adresse (Tr/Se) in
			dex
			cpx	Data_SekSpr		;absolute Adresse (Seite/Tr/Se)
			bcc	:51			;umrechnen.

			lda	r1H			;Relative Adresse (Tr/Se) in
			sec
			sbc	Data_SekSpr
			sta	r1H
			lda	#%10000000
			ora	r1L
			sta	r1L

::51			lda	r1L
			eor	#%10000000
			sta	r1L

			jsr	GetLinkBytes		;Bytes #000 bis #255 einlesen.
			txa
			bne	:52

			lda	#%10000000
			ora	r1H
			sta	r1H
			inc	r4H
			jsr	GetLinkBytes		;Bytes #256 bis #511 einlesen.
			dec	r4H

::52			PopW	r1			;Zektor-Zeiger zurücksetzen.
			rts

;*** Einsprung aus ":ReadLink".
:GetLinkBytes		ldx	#> TD_GetSektor
			lda	#< TD_GetSektor
			jsr	xTurboRoutSet_r1
			ldx	#> TD_RdSekData
			lda	#< TD_RdSekData
			jsr	xTurboRoutine

			MoveB	r4L,d0L			;Zeiger auf Daten an
			MoveB	r4H,d0H			;GET-Routine übergeben.

			ldy	#$00
::51			jsr	Turbo_GetBytes
			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;			txa				;Fehler?
			beq	:52			; => Nein, Ende...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
			beq	ExitRead		; => Ja, Abbruch...
			bcs	GetLinkBytes		;Sektor nochmal schreiben.
;			bcc	ExitRead		;Wird durch BEQ bereits abgefangen.

::52			ldy	#$00
:ExitRead		rts

;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r4
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xPutBlock		jsr	xEnterTurbo		;Turbo aktivieren.
;			txa				;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...
			jsr	InitForIO		;I/O aktivieren.
			jsr	xWriteBlock		;Sektor auf Diskette schreiben.
			jmp	DoneWithIO		;I/O abschalten.
::51			rts				;Ende...

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xWriteBlock		ldx	#WR_PR_ON
			rts

;--- Hinweis:
;Code wird nicht verwendet, da ein
;schreiben auf eine DOS-Disk nicht im
;Treiber enthalten.
;;			jsr	TestTrSe_ADDR		;Sektor-Adresse testen.
;;			bcc	:52			; => Fehler, Abbruch...
;;
;;::51			ldx	#> TD_WrSekData
;;			lda	#< TD_WrSekData
;;			jsr	xTurboRoutSet_r1
;;
;;			MoveB	r4L,d0L			;Zeiger auf Daten an
;;			MoveB	r4H,d0H			;SEND-Routine übergeben.
;;			ldy	#$00
;;			jsr	Turbo_PutBytes		;256 Byte an Floppy senden.
;;
;;			jsr	readErrByte		;Fehler/Wiederholungszähler holen.
;;;			txa				;Fehler?
;;			beq	:52			; => Nein, Ende...
;;
;;			inc	RepeatFunction		;Wiederholungszähler setzen.
;;			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen ?
;;			beq	:52			; => Ja, Abbruch...
;;			bcs	:51			;Sektor nochmal schreiben.
;;;			bcc	:52			;Wird durch BEQ bereits abgefangen.
;;
;;::52			rts

;*** Zeiger auf FAT berechnen.
;a/x     = Cluster-Nummer
;Ergebniss:
;r0L/r0H = Zeiger auf Eintrag in FAT
;r1L,r1H = Fat-Eintrag
.SearchEntryFAT		sta	r2L
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

			AddVW	TMP_AREA_FAT,r0 		;Offset zur Startadresse der FAT
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
;r0L/r0H = Zeiger auf Eintrag
;r1L/r1H = Wert
;r3L     = Cluster gerade/ungerade
.GetClusterLink		jsr	SearchEntryFAT		;Zeiger auf Cluster in FAT.
			lda	r3L			;Sonderbehandlung für
			bne	:1			;ungerade Cluster-Nummern.

			lda	r1H
			and	#%00001111
			sta	r1H			;12Bit/gerade
			rts

::1			ldx	#r1L
			ldy	#4
			jmp	DShiftRight

;*** Zeiger auf Anfang Datenbereich berechnen.
.Def1stDataSek		jsr	Def1stRDirSek

			jsr	GetMaxSekRDir
			AddW	Data_NumRDirSek,DOS_DataArea
			lda	DOS_DataArea+0
			ldx	DOS_DataArea+1
			rts

;*** Zeiger auf Hauptverzeichnis berechnen (logisch).
.Def1stRDirSek		MoveW	Data_AreSek,DOS_DataArea
			ldx	Data_Anz_Fat
::1			AddW	Data_SekFat,DOS_DataArea
			dex
			bne	:1
			rts

;*** Max. Anzahl Dateien im Hauptverzeichniss ermitteln.
:GetMaxSekRDir		lda	Data_Anz_Files +0
			sta	Data_NumRDirSek+0
			lda	Data_Anz_Files +1
			lsr
			ror	Data_NumRDirSek+0
			lsr
			ror	Data_NumRDirSek+0
			lsr
			ror	Data_NumRDirSek+0
			lsr
			ror	Data_NumRDirSek+0
			sta	Data_NumRDirSek+1
			rts

;*** Zeiger auf Hauptverzeichnis berechnen (logisch).
.DefAdrRootDir		ldx	Data_AreSek
			inx
			txa
			ldx	Data_Anz_Fat
::1			clc
			adc	Data_SekFat
			dex
			bne	:1

			stx	r1L
			sta	r1H

			asl	Data_SekSpr +0
			rol	Data_SekSpr +1

::2			lda	r1H
			cmp	Data_SekSpr
			beq	:3
			bcc	:3
			sec
			sbc	Data_SekSpr
			inc	r1L
			bne	:2

::3			lsr	Data_SekSpr +1
			ror	Data_SekSpr +0

			lda	r1L
			sta	Data_1stRDirSek +0
			lda	r1H
			sta	Data_1stRDirSek +1
			rts

;*** Sektor-Zähler erhöhen.
.Inc_Sek		lda	Seite
			ldx	Spur
			ldy	Sektor
			cpy	Data_SekSpr
			beq	:1
			iny
			bne	:2
::1			ldy	#$01
			eor	#%00000001
			bne	:2
			inx
::2			sta	Seite
			stx	Spur
			sty	Sektor
			rts

;*** Aus Cluster-Nr. die physikalischen Werte berechnen.
;    Übergabe:		a/x	= Cluster lo/hi
;    Rückgabe:			= Seite,Spur,Sektor
.ConvClu2Sek		lda	r1L
			sec				;Cluster #0 definieren.
			sbc	#$02
			sta	r1L
			lda	r1H
			sbc	#$00
			sta	r1H

			lda	Data_SekSpr +0
			sta	Data_NumSekPCyl+0
			lda	Data_SekSpr +1
			sta	Data_NumSekPCyl+1

			CmpBI	Data_AnzSLK,1		;Ein oder zwei
			beq	:2			;Schreib-/Lese-Köpfe?

			asl	Data_NumSekPCyl		;Zwei Schreib-/Lese-Köpfe, Anzahl
			rol	Data_NumSekPCyl+1	;Sektoren pro Spur x2.

::2			lda	#0			;Startwerte auf ersten Sektor
			ldx	#0			;setzen.
			ldy	#1
			sta	Seite
			stx	Spur
			sty	Sektor

			lda	Data_SpClu		;Cluster mit Anzahl
::3			lsr				;Sektoren pro Cluster
			tax				;verknüpfen.
			beq	:4
			asl	r1L
			rol	r1H
			txa
			jmp	:3

::4			jsr	Def1stDataSek		;Anzahl reservierter
							;Sektoren berechnen.
			clc
			adc	r1L
			sta	r1L
			txa
			adc	r1H
			sta	r1H

::5			CmpW	r1,Data_NumSekPCyl
			bcc	:6

			sec
			lda	r1L
			sbc	Data_NumSekPCyl
			tax
			lda	r1H
			sbc	Data_NumSekPCyl+1
			bcc	:6

			stx	r1L
			sta	r1H
			inc	Spur
			jmp	:5

::6			lsr	Data_NumSekPCyl+1	;Anzahl Sektoren/Seite/Spur.
			ror	Data_NumSekPCyl

			CmpW	r1,Data_NumSekPCyl
			bcc	:7
			inc	Seite
			SubW	Data_NumSekPCyl,r1

::7			MoveB	r1L,Sektor
			jsr	Inc_Sek

.ConvDOS2CBMsek		lda	Data_SekSpr
			ldx	Seite
			bne	:8
			lda	#$00
::8			clc
			adc	Sektor
			sta	r1H
			lda	Spur
			sta	r1L
			rts

;******************************************************************************
			g DISK_BASE + DISK_DRIVER_SIZE -1
;******************************************************************************
