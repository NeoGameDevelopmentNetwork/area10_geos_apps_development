; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"
:dir3Head		= $9c80
endif

			o $9000
			n "DiskDev_RAM1581"
			a "M. Kanet"

:vInitForIO		w xInitForIO
:vDoneWithIO		w xDoneWithIO
:vExitTurbo		w xExitTurbo
:vPurgeTurbo		w xPurgeTurbo
:vEnterTurbo		w xEnterTurbo
:vChangeDiskDev		w xChangeDiskDev
:vNewDisk		w xNewDisk
:vReadBlock		w xReadBlock
:vWriteBlock		w xWriteBlock
:vVerWriteBlock		w xVerWriteBlock
:vOpenDisk		w xOpenDisk
:vGetBlock		w xGetBlock
:vPutBlock		w xPutBlock
:vGetDirHead		w xGetDirHead
:vPutDirHead		w xPutDirHead
:vGetFreeDirBlk		w xGetFreeDirBlk
:vCalcBlksFree		w xCalcBlksFree
:vFreeBlock		w xFreeBlock
:vSetNextFree		w xSetNextFree
:vFindBAMBit		w xFindBAMBit
:vNxtBlkAlloc		w xNxtBlkAlloc
:vBlkAlloc		w xBlkAlloc
:vChkDkGEOS		w xChkDkGEOS
:vSetGEOSDisk		w xSetGEOSDisk

:vGet1stDirEntry	jmp	xGet1stDirEntry
:vGetNxtDirEntry	jmp	xGetNxtDirEntry
:vGetBorderBlock	jmp	GetBorderBlock
:vCreateNewDirBlk	jmp	xCreateNewDirBlk
:vGetBlock_dskBuf	jmp	GetBlock_dskBuf
:vPutBlock_dskBuf	jmp	PutBlock_dskBuf
			ldx	#$00			;1541: TurboRoutine_r1
			rts
			ldx	#$00			;1541: GetDiskError
			rts
:vAllocateBlock		jmp	xAllocateBlock
:vReadLink		jmp	xReadLink

;*** Tabellen & Texte.
:FormatText		b "GEOS format V1.0",NULL
:SingleBitTab		b $01,$02,$04,$08,$10,$20,$40,$80

;*** Variablen.
:IRQ_RegBuf		b $00
:CPU_RegBuf		b $00
:RegD015_Buf		b $00
:RegD01A_Buf		b $00
:RegD030_Buf		b $00
:RepeatFunction		b $00
:SwapByteBuf		b $00
:BlkAllocMode		b $00
:Flag_BorderBlock	b $00

;*** Ladeadressen der Laufwerkstreiber.
:DskDrvBaseL		b < $8300
			b < $9080
			b < $9e00
			b < $ab80
:DskDrvBaseH		b > $8300
			b > $9080
			b > $9e00
			b > $ab80

;*** Zeiger auf ":diskBlkBuf" richten.
:Set_diskBlkBuf		lda	#> diskBlkBuf
			sta	r4H
			lda	#< diskBlkBuf
			sta	r4L
			rts

;*** Zeiger auf ":curDirHead" richten.
:Set_curDirHead		lda	#> curDirHead
			sta	r5H
			lda	#< curDirHead
			sta	r5L
			rts

;*** Zeiger auf BAM-Sektor und BAM-Speicher setzen.
:SetBAM_TrSe1		ldx	#> curDirHead		;Zeiger auf ":curDirHead".
			ldy	#< curDirHead
			lda	#$00			;Sektor #0.
			beq	SetBAM_TrSe

:SetBAM_TrSe2		ldx	#> dir2Head		;Zeiger auf ":dir2Head".
			ldy	#< dir2Head
			lda	#$01			;Sektor #1.
			bne	SetBAM_TrSe

:SetBAM_TrSe3		ldx	#> dir3Head		;Zeiger auf ":dir3Head".
			ldy	#< dir3Head
			lda	#$02			;Sektor #2.

:SetBAM_TrSe		stx	r4H			;Zeiger auf BAM-Speicher setzen.
			sty	r4L
			sta	r1H			;Zeiger auf BAM-Sektor   setzen.
			lda	#$28
			sta	r1L
			rts

;*** Sektor in ShadowRAM bereits gespeichert ?
;    Übergabe:		r1 = Track/Sektor.
:TestTrSe_ADDR		lda	#$00
			sta	RepeatFunction

			ldx	#$02			;Vorbereiten: "Falsche Sektor-Nr.".

			lda	r1L			;Track-Nummer einlesen.
			beq	CancelTest		; =  0, Fehler...
			cmp	#81
			bcs	CancelTest		; > 35, Fehler...
			sec				;Sektor-Adresse in Ordnung, Ende...
			rts

:CancelTest		clc
			rts

;*** Sektorspeicher ":diskBlkBuf" löschen.
;    Übergabe:		r1 = Track/Sektor.
:Clr_diskBlkBuf		lda	#$00
			tay
::51			sta	diskBlkBuf,y		;Sektor-Inhalt löschen.
			iny
			bne	:51
			dey
			sty	diskBlkBuf +1		;Link-Zeiger definieren.
			jmp	vPutBlock_dskBuf	;Sektor auf Disk schreiben.

;*** I/O aktivieren.
:xInitForIO		php
			pla
			sta	IRQ_RegBuf		;IRQ-Status speichern.

			sei
			lda	CPU_DATA
			sta	CPU_RegBuf		;CPU-Status speichern.

			lda	#$36			;I/O + Kernal einblenden.
			sta	CPU_DATA

			lda	$d01a			;IRQ-Maskenregister speichern.
			sta	RegD01A_Buf
			lda	$d030
			sta	RegD030_Buf

			ldy	#$00
			sty	$d030
			sty	$d01a

			lda	#%01111111		;VIC-Interrupt sperren.
			sta	$d019
			sta	$dc0d			;IRQs sperren.
			sta	$dd0d			;NMIs sperren.

			lda	#> NewIRQ		;IRQ-Routine abschalten.
			sta	$0315
			lda	#< NewIRQ
			sta	$0314

			lda	#> NewNMI		;NMI-Routine abschalten.
			sta	$0319
			lda	#< NewNMI
			sta	$0318

			lda	#$3f			;Datenrichtungsregister A setzen.
			sta	$dd02			;(Serieller Bus)

			lda	$d015			;Aktive Sprites zwischenspeichern.
			sta	RegD015_Buf
			sty	$d015			;Sprites abschalten.

			sty	$dd05			;Timer A löschen.
			iny
			sty	$dd04

			lda	#$81			;NMI-Register initialisieren.
			sta	$dd0d
			lda	#$09			;Timer A starten.
			sta	$dd0e

			ldy	#$2c			;Warteschleife bis Ser. Bus
::51			lda	$d012			;initialisiert (Turbo-Routinen!)
			cmp	$8f
			beq	:51
			sta	$8f
			dey
			bne	:51

			rts

;*** Neue IRQ/NMI-Routine.
:NewIRQ			pla
			tay
			pla
			tax
			pla
:NewNMI			rti

;*** I/O abschalten.
:xDoneWithIO		sei
			lda	RegD030_Buf
			sta	$d030
			lda	RegD015_Buf		;Sprites wieder aktivieren.
			sta	$d015

			lda	#$7f			;NMIs sperren.
			sta	$dd0d

			lda	$dd0d

			lda	RegD01A_Buf		;IRQ-Maskenregister zurücksetzen.
			sta	$d01a

			lda	CPU_RegBuf		;CPU-Register zurücksetzen.
			sta	CPU_DATA

			lda	IRQ_RegBuf		;IRQ-Status zurücksetzen.
			pha
			plp
			rts

;*** Neue Diskette öffnen.
:xOpenDisk		jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	ExitOpenDisk		;Ja, Abbruch...

			jsr	Set_curDirHead		;Zeiger auf BAM richten und
			jsr	ChkDkGEOS		;auf GEOS-Diskette testen.

			lda	#> curDirHead +$90
			sta	r4H
			lda	#< curDirHead +$90
			sta	r4L
			ldx	#r5L			;Zeiger auf Speicher für
			jsr	GetPtrCurDkNm		;Diskettenname setzen.

			ldx	#r4L
			ldy	#r5L
			lda	#18
			jsr	CopyFString		;Diskettenname kopieren.

;*** Neue Diskette öffnen.
:xNewDisk
:ExitOpenDisk		ldx	#$00
			rts

;*** Neue Geräteadresse setzen.
:xChangeDiskDev		sta	curDrive
			sta	curDevice
			ldx	#$00
			rts

;*** Konvertierung von 1581 nach 1541 und umgekehrt.
:SwapDskNmData		php
			pha
			lda	r1L			;Track 40, Sektor #0 ?
			cmp	#$28
			bne	:52			;Nein, Ende...
			lda	r1H
			bne	:52			;Nein, Ende...

			ldy	#$04			;Disketten-Name an richtige Stelle
::51			lda	(r4L),y			;(1541-kompatibel) kopieren.
			sta	SwapByteBuf
			tya
			clc
			adc	#$8c
			tay
			lda	(r4L),y
			pha
			lda	SwapByteBuf
			sta	(r4L),y
			tya
			sec
			sbc	#$8c
			tay
			pla
			sta	(r4L),y
			iny
			cpy	#$1d
			bne	:51

::52			pla				;Ende.
			plp
			rts

;*** TurboDOS deaktivieren.
;    Ist bei RAMLink nicht notwendig, allerdings muß der Bereich von
;    ":dir3Head" zwischengespeichert werden, da SetDevice in der Regel nicht
;    ":curDirHead" und ":dir2Head" verändert und die BAM bei einer 1541 und
;    1571 nicht verändert wird. Um bei einer 1581 die BAM im Speicher
;    ebenfalls nicht zu verändern, wird ":dir3Head" im RAM aktualisiert und
;    beim nächsten Aufruf des Laufwerks die BAM wieder korrekt hergestellt.
:xExitTurbo		bit	sysRAMFlg		;Laufwerkstreiber in REU ?
			bvc	EndTurbo		;Nein, Ende...

			txa
			pha

			PushW	r0			;Register ":r0" bis "r3L"
			PushW	r1			;zwischenspeichern.
			PushW	r2
			PushB	r3L

			lda	#> dir3Head		;Bereich von ":dir3Head" im
			sta	r0H			;erweiterten Speicher aktualisieren.
			lda	#< dir3Head		;Notwendig, da beim Laufwerkswechsel
			sta	r0L			;über SetDevice dieser Bereich
							;verändert wird.
			ldx	curDrive
			lda	DskDrvBaseL  -8,x
			clc
			adc	#< (dir3Head - DISK_BASE)
			sta	r1L
			lda	DskDrvBaseH  -8,x
			adc	#> (dir3Head - DISK_BASE)
			sta	r1H

			ldy	#$00
			sty	r3L
			sty	r2L
			iny
			sty	r2H
			jsr	StashRAM

			PopB	r3L
			PopW	r2
			PopW	r1
			PopW	r0

			pla
			tax

;*** TurboModus-Routinen.
;    RAMLink verfügt nicht übe Turbo-Routinen,
;    daher werden alle Routinen mit "RTS" beendet.
:xEnterTurbo
:xPurgeTurbo
:EndTurbo		rts

;*** Aktuelle BAM einlesen.
:xGetDirHead		php				;IRQ sperren.
			sei
			jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xGetBlock		;BAM-Sektor einlesen/konvertieren.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	SetBAM_TrSe2		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xGetBlock		;BAM-Sektor einlesen/konvertieren.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	SetBAM_TrSe3		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xGetBlock		;BAM-Sektor einlesen/konvertieren.
::51			plp
			rts

;*** Sektor nach ":diskBlkBuf" einlesen.
:GetBlock_dskBuf	jsr	Set_diskBlkBuf		;Zeiger auf ":diskBlkBuf" setzen.

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xGetBlock
:xReadBlock		php				;IRQ sperren.
			sei
			jsr	TestTrSe_ADDR
			bcc	:51
			ldy	#$91
			jsr	GetDataBytes
			jsr	SwapDskNmData
::51			ldy	#$00
			plp				;IRQ-Status zurücksetzen.
			rts

;*** LinkBytes von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink		jsr	TestTrSe_ADDR
			bcc	:51
			ldy	#$91
			jsr	GetLinkBytes
::51			rts

;*** Aktuelle BAM auf Diskette schreiben.
:xPutDirHead		php				;IRQ sperren.
			sei
			jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	WriteBlock		;BAM-Sektor konvertieren/speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	SetBAM_TrSe2		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	WriteBlock		;BAM-Sektor konvertieren/speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	SetBAM_TrSe3		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	WriteBlock		;BAM-Sektor konvertieren/speichern.
::51			plp				;IRQ-Status zurücksetzen.
			rts

;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
:PutBlock_dskBuf	jsr	Set_diskBlkBuf		;Zeiger auf ":diskBlkBuf" setzen.

;*** Sektor in ":r4" auf Diskette schreiben.
:xPutBlock
:xWriteBlock		php				;IRQ sperren.
			sei
			jsr	TestTrSe_ADDR
			bcc	:51
			jsr	SwapDskNmData
			ldy	#$90
			jsr	GetDataBytes
			jsr	SwapDskNmData
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	VerWriteBlock		;Sektor vergleichen.
::51			plp				;IRQ-Status zurücksetzen.
			rts

;*** Sektor auf Diskette vergleichen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xVerWriteBlock		jsr	TestTrSe_ADDR
			bcc	:51
			ldx	#$00
::51			rts

;*** Die ersten zwei Bytes eines Sektors einlesen.
:GetLinkBytes		lda	r2H
			pha
			lda	r2L
			pha
			lda	#$00
			sta	r2H
			lda	#$02
			sta	r2L
			bne	DoRAMOp_Job

;*** 256 Byte eines Sektors einlesen.
:GetDataBytes		lda	r2H
			pha
			lda	r2L
			pha
			lda	#$01
			sta	r2H
			lda	#$00
			sta	r2L

;*** RAM-Transfer ausführen.
:DoRAMOp_Job		PushW	r0			;Register ":r0", ":r1" und ":r3L"
			PushW	r1			;zwischenspeichern.
			PushB	r3L

			tya				;DoRAMOp-Job zwischenspeichern.
			pha

			PushW	r2			;Anzahl Bytes zwischenspeichern.

			PushW	r7			;Register ":r7" und ":r8"
			PushW	r8			;zwischenspeichern.

			dec	r1L			;Zeiger auf 64K-Bank berechnen.
			lda	r1H
			sta	r2H
			lda	#$28
			sta	r2L
			ldx	#r1L
			ldy	#r2L
			jsr	BBMult

			clc
			lda	r1L
			adc	r2H
			sta	r1L
			lda	r1H
			adc	#$00
			sta	r1H

			ldy	curDrive
			clc
			lda	r1L
			adc	driveData +3
			sta	r1L
			lda	r1H
			adc	ramBase   -8,y
			sta	r3L
			lda	r1L
			sta	r1H

			PopW	r8			;Register ":r7" und ":r8" wieder
			PopW	r7			;zurücksetzen.

			PopW	r2			;Anzahl Bytes zurücksetzen.

			lda	#$00			;Adresse in Partition korrigieren.
			sta	r1L

			lda	r4H			;Zeiger auf Speicher für Sektor.
			sta	r0H
			lda	r4L
			sta	r0L
			pla				;DoRAMJob einlesen.
			tay
			jsr	DoRAMOp			;Sektor aus/in RAM lesen/schreiben.
			tax				;Transferstatus zwischenspeichern.

			PopB	r3L			;Register ":r0" bis ":r3L"
			PopW	r1			;wieder auf Ausgangswerte
			PopW	r0			;zurücksetzen.
			PopW	r2

			txa				;Transferstatus zurücksetzen.
			ldx	#$00			;Flag: "Kein Fehler..."
			rts

;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2 = Anzahl Bytes.
;			r6 = Zeiger auf Track/Sektor-Tabelle.
:xBlkAlloc		ldy	#$01			;Zeiger auf ersten Sektor
			sty	r3L			;auf Diskette.
			dey
			sty	r3H

;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2 = Anzahl Bytes.
;			r3 = Erster Sektor für Suche nach freiem Sektor,
;			r6 = Zeiger auf Track/Sektor-Tabelle.
:xNxtBlkAlloc		PushW	r9
			PushW	r3

			lda	#0			;Anzahl Bytes in Anzahl Sektoren
			sta	r3H			;umrechnen.
			lda	#254
			sta	r3L
			ldx	#r2L
			ldy	#r3L
			jsr	Ddiv

			lda	r8L			;Bytes / 254, Rest = 0 ?
			beq	:51			;Ja, weiter...
			inc	r2L			;Anzahl Sektoren +1.
			bne	:51
			inc	r2H

::51			lda	#> curDirHead
			sta	r5H
			lda	#< curDirHead
			sta	r5L
			jsr	CalcBlksFree

			PopW	r3			;Register ":r3" zurücksetzen.

			ldx	#$03			;Fehler "Kein Platz auf Diskette!"
			lda	r2H			;Genügend Speicher frei ?
			cmp	r4H
			bne	:52
			lda	r2L
			cmp	r4L
::52			beq	:53
			bcs	:58			;Nein, Fehler, Abbruch...

::53			lda	r6H			;Zeiger auf Track/Sektor-Tabelle
			sta	r4H			;nach ":r4" kopieren.
			lda	r6L
			sta	r4L

			lda	r2H			;Anzahl Sektoren nach ":r5"
			sta	r5H			;kopieren.
			lda	r2L
			sta	r5L

::54			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:58			;Ja, Abbruch...

			ldy	#$00
			lda	r3L			;Sektor in Track/Sektor-Tabelle
			sta	(r4L),y			;kopieren.
			iny
			lda	r3H
			sta	(r4L),y

			clc				;Zeiger auf Track/Sektor-Tabelle
			lda	#$02			;korrigieren.
			adc	r4L
			sta	r4L
			bcc	:55
			inc	r4H

::55			lda	r5L			;Anzahl Sektoren -1.
			bne	:56
			dec	r5H
::56			dec	r5L
			lda	r5L
			ora	r5H			;Alle Sektoren belegt ?
			bne	:54			;Nein, weiter...

			ldy	#$00
			tya
			sta	(r4L),y
			iny
			lda	r8L			;Anzahl Bytes in letztem Sektor
			bne	:57			;in Track/Sektor-Tabelle kopieren.
			lda	#$fe
::57			clc
			adc	#$01
			sta	(r4L),y
			ldx	#$00			;Kein Fehler, Ende...

::58			PopW	r9			;Register ":r9" zurücksetzen.
			rts

;*** Nächsten freien Sektor auf Diskette belegen.
:xSetNextFree		lda	r3H			;Zeiger auf nächsten Sektor.
			clc
			adc	#$01
			sta	r6H

			lda	r3L			;Zeiger auf aktuellen Track setzen.
			sta	r6L

			cmp	#40			;Verzeichnis-Spur erreicht ?
			beq	:52			;Ja, weiter...

::51			lda	r6L			;Aktuellen Track einlesen.
			cmp	#40			;Track #40 erreicht ?
			beq	:57			;Ja, weiter...

::52			cmp	#41			;Zeiger auf Track #1-40
			bcc	:53			;zurücksetzen.
			sec
			sbc	#40

::53			sec				;Zeiger auf BAM berechnen.
			sbc	#$01
			asl
			sta	:53a +1
			asl
			clc
::53a			adc	#$ff
			tax

			lda	r6L			;Speicher für BAM ermitteln.
			cmp	#41			;Track #1 - #40 ?
			bcc	:54			;Ja, weiter...

			lda	dir3Head +16,x		;Anzahl freie Sektoren einlesen.
			jmp	:55

::54			lda	dir2Head +16,x		;Anzahl freie Sektoren einlesen.
::55			beq	:57			; => Track belegt, weitersuchen.

			lda	#40			;Max. Anzahl Sektoren auf Track
			sta	r7L			;zwischenspeichern.
			tay				;Anzahl Sektoren als Zähler setzen.

::56			jsr	TestCurSekFree
			txa
			beq	:60

			inc	r6H
			dey
			bne	:56

::57			inc	r6L
::59			lda	r6L
			cmp	#81
			bcs	:61

			lda	#$00
			sta	r6H
			beq	:51

::60			lda	r6L			;Freien Sektor in ":r3"
			sta	r3L			;übergeben.
			lda	r6H
			sta	r3H
			ldx	#$00			;Kein Fehler...
			rts
::61			ldx	#$03			;Fehler: "Diskette voll".
			rts

;*** Aktuellen Sektor auf Gültigkeit testen.
;    Anschließend testen ob Sektor frei ist.
:TestCurSekFree		lda	r6H
::51			cmp	r7L
			bcc	:52
			sec
			sbc	r7L
			jmp	:51

::52			sta	r6H

;*** Sektor in BAM belegen.
:xAllocateBlock		jsr	xFindBAMBit
			bne	EditBAM_dir3Head
:Error_BAD_BAM		ldx	#$06
			rts

;*** Sektor in BAM freigeben.
;    Übergabe:		r6 = Track/Sektor.
:xFreeBlock		jsr	xFindBAMBit
			bne	Error_BAD_BAM

;*** Sektor in BAM (":dir3Head") belegen / freigeben.
:EditBAM_dir3Head	php				;Z-Flag sichern.

			lda	r6L			;Aktuellen Track einlesen.
			cmp	#41			; < #41 ?
			bcc	EditBAM_dir2Head	;Ja, Sektor in ":dir2Head".

			lda	r8H			;Bit in BAM wechseln, damit
			eor	dir3Head +16,x		;Sektor belegen/freigeben.
			sta	dir3Head +16,x
			ldx	r7H

			plp				;Sektor freigeben ?
			beq	:51			;Ja, weiter...

			dec	dir3Head +16,x		;Anzahl Sektoren -1.
			clv				;AllocateBlock/FreeBlock beenden.
			bvc	EndEditBAM

::51			inc	dir3Head +16,x		;Anzahl Sektoren +1.
			clv				;AllocateBlock/FreeBlock beenden.
			bvc	EndEditBAM

;*** Sektor in BAM (":dir2Head") belegen / freigeben.
:EditBAM_dir2Head	lda	r8H			;Bit in BAM wechseln, damit
			eor	dir2Head +16,x		;Sektor belegen/freigeben.
			sta	dir2Head +16,x
			ldx	r7H

			plp				;Sektor freigeben ?
			beq	:51			;Ja, weiter...

			dec	dir2Head +16,x
			clv				;AllocateBlock/FreeBlock beenden.
			bvc	EndEditBAM

::51			inc	dir2Head +16,x
:EndEditBAM		ldx	#$00			;Flag für "Kein Fehler"...
			rts

;*** Zeiger auf Sektor in BAM berechnen.
;    Übergabe:		r6 = Track/Sektor.
:xFindBAMBit		lda	r6H
			and	#$07
			tax
			lda	SingleBitTab,x
			sta	r8H

			lda	r6L
			cmp	#41
			bcc	:51
			sec
			sbc	#$28

::51			sec
			sbc	#1
			asl
			sta	r7H
			asl
			clc
			adc	r7H
			sta	r7H

			lda	r6H
			lsr
			lsr
			lsr
			sec
			adc	r7H
			tax

			lda	r6L
			cmp	#41
			bcc	:52

			lda	dir3Head +16,x
			and	r8H
			rts

::52			lda	dir2Head +16,x
			and	r8H
			rts

;*** Anzahl freier Blocks auf Diskette berechnen.
:xCalcBlksFree		lda	#$00			;Zähler für freie Sektoren löschen.
			sta	r4L
			sta	r4H

			ldy	#$10
::51			lda	dir2Head,y		;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:52
			inc	r4H
::52			tya
			clc
			adc	#$06
			tay
			cpy	#$fa			;Directory-Track erreicht ?
			beq	:52			;Ja, weiter...
			cpy	#$00			;Ende BAM#2 erreicht ?
			bne	:51			;Nein, weiter...

			ldy	#$10
::53			lda	dir3Head,y		;Freie Sektoren auf aktuellem Track
			clc				;einlesen und addieren.
			adc	r4L
			sta	r4L
			bcc	:54
			inc	r4H
::54			tya
			clc
			adc	#$06
			tay				;Ende BAM#3 erreicht ?
			bne	:53			;Nein, weiter...

			lda	#> 3160
			sta	r3H
			lda	#< 3160
			sta	r3L
			rts

;*** Zeiger auf ersten Verzeichnis-Eintrag richten.
:xGet1stDirEntry	jsr	SetBAM_TrSe3		;Zeiger auf letzten BAM-Sektor.
			inc	r1H			;Zeiger auf ersten  DIR-Sektor.

			lda	#$00			;Flag für "Aktueller Sektor ist
			sta	Flag_BorderBlock	;BorderBlock" löschen.
			beq	GetCurDirSek

;*** Nächsten Verzeichnis-Eintrag einlesen.
;    Übergabe:		r5 = Zeiger auf aktuelle Eintrag in Verzeichnis-Sektor.
;			diskBlkBuf = Aktueller Verzeichnis-Sektor.
:xGetNxtDirEntry	ldx	#$00
			ldy	#$00
			clc				;Register ":r5" auf nächsten
			lda	#$20			;Eintrag richten.
			adc	r5L
			sta	r5L
			bcc	:51
			inc	r5H

::51			lda	r5H			;Alle Einträge eines Sektors
			cmp	#$80			;eingelesen.
			bne	:52
			lda	r5L
			cmp	#$ff
::52			bcc	EndDirSekJob		;Nein, weiter...

			ldy	#$ff
			lda	diskBlkBuf +$01		;Zeiger auf nächsten
			sta	r1H			;Verzeichnis-Sektor richten.
			lda	diskBlkBuf +$00
			sta	r1L			;Sektor verfügbar ?
			bne	GetCurDirSek		;Ja, weiter...

			lda	Flag_BorderBlock	;Ist BorderBlock im Speicher ?
			bne	EndDirSekJob		;Ja, weiter...
			lda	#$ff			;Borderblock als letzten
			sta	Flag_BorderBlock	;Verzeichnis-Block einlesen.

			jsr	vGetBorderBlock		;Zeiger auf BorderBlock richten.
			txa				;Diskettenfehler ?
			bne	EndDirSekJob		;Ja, Abbruch...
			tya				;BorderBlock verfügbar ?
			bne	EndDirSekJob		;Nein, Ende...

:GetCurDirSek		jsr	vGetBlock_dskBuf	;Verzeichnissektor einlesen.

			ldy	#$00
			lda	#> diskBlkBuf +2	;Zeiger auf ersten Eintrag.
			sta	r5H
			lda	#< diskBlkBuf +2
			sta	r5L
:EndDirSekJob		rts

;*** Zeiger auf Borderblock einlesen.
:GetBorderBlock		jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			jsr	Set_curDirHead		;Zeiger auf aktuelle BAM.
			jsr	ChkDkGEOS		;Auf GEOS-Diskette testen.
			bne	:51			; => GEOS-Diskette, weiter...

			ldy	#$ff			;Flag: "Keine GEOS-Diskette" und
			bne	:52			;Ende...

::51			lda	curDirHead +172		;Zeiger auf Borderblock setzen.
			sta	r1H
			lda	curDirHead +171
			sta	r1L
			ldy	#$00			;Flag: "GEOS-Diskette" und
::52			ldx	#$00			;Kein Fehler...
::53			rts

;*** Freien Verzeichnis-Sektor suchen.
;    Übergabe:		r10L = Erste Seite für Suche nach freiem Eintrag.
:xGetFreeDirBlk		php
			sei

			lda	r6L			;Register ":r6L" speichern.
			pha

			lda	r2H			;Register ":r2"  speichern.
			pha
			lda	r2L
			pha

			ldx	r10L			;Erste Verzeichnis-Seite
			inx				;festlegen.
			stx	r6L

			lda	#$28			;Zeiger auf ersten Verzeichnis-
			sta	r1L			;Sektor setzen.
			lda	#$03
			sta	r1H

::51			jsr	GetBlock_dskBuf		;Sektor von Diskette lesen.
::52			txa				;Diskettenfehler ?
			bne	:57			;Ja, Abbruch...

			dec	r6L			;Verzeichnis-Seite erreicht ?
			beq	:55			;Ja, weiter...

::53			lda	diskBlkBuf +$00		;Nächster Sektor verfügbar ?
			bne	:54			;Ja, weiter...

			jsr	vCreateNewDirBlk
			clv
			bvc	:52

::54			sta	r1L			;Zeiger auf nächsten Sektor
			lda	diskBlkBuf +$01		;setzen und Sektor von Diskette
			sta	r1H			;einlesen.
			clv
			bvc	:51

::55			ldy	#$02			;Freien Verzeichnis-Eintrag
			ldx	#$00			;innerhalb des Sektors suchen.
::56			lda	diskBlkBuf +$00,y	;Eintrag frei ?
			beq	:57			;Ja, weiter...
			tya
			clc
			adc	#$20			;Zeiger auf nächsten Eintrag.
			tay				;Alle Einträge geprüft ?
			bcc	:56			;Nein, weiter...

			lda	#$01			;Flag: "Nächsten Sektor suchen".
			sta	r6L

			ldx	#$04
			ldy	r10L			;Zeiger auf nächste
			iny				;Verzeichnis-Seite setzen.
			sty	r10L
			cpy	#144/8			;18 Seiten/8 Dateien = 144 Einträge.
			bcc	:53

::57			pla				;Register ":r2"  zurücksetzen.
			sta	r2L
			pla
			sta	r2H

			pla				;Register ":r6L" zurücksetzen.
			sta	r6L
			plp
			rts

;*** Neuen Verzeichnis-Sektor erstellen.
;    Übergabe:		r1 = Aktueller Verzeichnis-Track/Sektor.
:xCreateNewDirBlk	ldx	#$04			;Vorbereiten: "Verzeichnis voll".
			lda	dir2Head +$fa		;Freie Verzeichnis-Sektoren testen.
			beq	:52			; => Abbruch wenn kein Sektor frei.

			PushW	r6			;Register ":r6" zwischenspeichern.

			lda	r1H			;Aktuellen Verzeichnis-Sektor als
			sta	r3H			;Startwert für Suche nach freien
			lda	r1L			;Verzeichnis-Sektor setzen.
			sta	r3L
			jsr	xSetNextFree		;Freien Sektor suchen.

			lda	r3H			;Freien Sektor als LinkBytes in
			sta	diskBlkBuf +$01		;aktuellem Verzeichnis-Sektor
			lda	r3L			;eintragen.
			sta	diskBlkBuf +$00
			jsr	PutBlock_dskBuf		;Sektor auf Diskette speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			MoveB	r3L,r1L			;Zeiger auf aktuellen Sektor.
			MoveB	r3H,r1H
			jsr	Clr_diskBlkBuf		;Sektor-Speicher löschen.

::51			PopW	r6			;Register ":r6" zurücksetzen.
::52			rts

;*** Auf GEOS-Diskette testen.
;    Übergabe:		r5 = Zeiger auf aktuelle BAM (":curDirHead").
:xChkDkGEOS		ldy	#$ad			;Zeiger auf BAM.
			ldx	#$00
			stx	isGEOS			;Flag: "Keine GEOS-Diskette".

::51			lda	(r5L)     ,y		;Format-Text vergleichen.
			cmp	FormatText,x
			bne	:52			;Fehler, keine GEOS-Diskette.
			iny
			inx
			cpx	#$0b
			bne	:51
			lda	#$ff			;Flag: "GEOS-Diskette".
			sta	isGEOS
::52			lda	isGEOS
			rts

;*** Diskette in GEOS-Diskette wandeln.
:xSetGEOSDisk		jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	#40			;Standardwert für Borderblock auf
			sta	r6L			;Track #40, Sektor #38 setzen.
			lda	#39			;SetNextFree korrigiert dann die
			sta	r6H			;Sektor-Adresse auf #39.
			jsr	xFindBAMBit		;Sektor bereits belegt ?
			php
			ldx	#$04
			plp
			beq	:53			;Ja, Abbruch...

			jsr	xAllocateBlock
			txa
			bne	:53

			MoveW	r6,r3

::51			lda	r3H			;Zeiger auf neuen Sektor nach
			sta	r1H			;":r1" kopieren ? Zeiger auf Sektor
			lda	r3L			;auf Diskette.
			sta	r1L
			jsr	Clr_diskBlkBuf		;Sektor löschen/auf Disk schreiben.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	r1H			;Zeiger auf BorderBlock in BAM
			sta	curDirHead +172		;übertragen.
			lda	r1L
			sta	curDirHead +171

			ldx	#$0f
::52			lda	FormatText     ,x	;GEOS-Formatkennung in BAM
			sta	curDirHead +173,x	;übertragen.
			dex
			bpl	:52

			jsr	xPutDirHead		;BAM auf Diskette schreiben.

::53			rts
