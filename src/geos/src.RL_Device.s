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
			n "DiskDev_RAMLink"
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
:vGetBorderBlock	jmp	xGetBorderBlock
:vCreateNewDirBlk	jmp	xCreateNewDirBlk
:vGetBlock_dskBuf	jmp	xGetBlock_dskBuf
:vPutBlock_dskBuf	jmp	xPutBlock_dskBuf
:vTurboRoutine_r1	ldx	#$00			;1541: TurboRoutine ausführen.
			rts
:vGetDiskError		ldx	#$00			;1541: TurboDOS-fehler einlesen.
			rts
:vAllocateBlock		jmp	xAllocateBlock
:vReadLink		jmp	xReadLink

;*** Einsprungtabelle für NativeMode-Funktionen.
			e $9050
:vSetCMD_Root		ldx	#$00
			rts
:vSetCMD_SubD		ldx	#$00
			rts

;*** Einsprungtabelle für RAMLink-Funktionen.
:vTestForRL		jmp	xTestForRL
:vResetGEOS_Part	jmp	xResetGEOS_Part
:vGetPartInfo		jmp	xGetPartInfo
:vOpenPartition		jmp	xOpenPartition
:vSetNewGEOS_Part	jmp	xSetNewGEOS_Part
:vDoRAMLinkOp		jmp	xDoRAMLinkOp
:vDoRAMLinkPartOp	jmp	xDoRAMLinkPartOp
:vPartGetBlock		jmp	xPartGetBlock
:vPartPutBlock		jmp	xPartPutBlock
:vRL_VerifyRAM		jmp	xRL_VerifyRAM
:vRL_StashRAM		jmp	xRL_StashRAM
:vRL_SwapRAM		jmp	xRL_SwapRAM
:vRL_FetchRAM		jmp	xRL_FetchRAM
:vRL_DoRAMOp		jmp	xRL_DoRAMOp

;*** Variablen für aktuelle Partition.
:CurrentPart		b $ff
:PartStart_ADDR		w $ffff
:OffsetVarData		= (CurrentPart - DISK_BASE)

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
:RL_SekBuf		s 256
:RL_PartBuf		b $00
:RL_PartADDR		b $00

;*** Ladeadressen der Laufwerkstreiber.
:DskDrvBaseL		b < $8300
			b < $9080
			b < $9e00
			b < $ab80
:DskDrvBaseH		b > $8300
			b > $9080
			b > $9e00
			b > $ab80

:SingleBitTab		b $01,$02,$04,$08,$10,$20,$40,$80
:FormatText		b "GEOS format V1.0",NULL

;*** Ist RAMLink vorhanden ?
:xTestForRL		php
			sei
			ldx	CPU_DATA
			ldy	#$36
			sty	CPU_DATA
			ldy	$e0a9
			stx	CPU_DATA
			ldx	#$00
			cpy	#$78
			beq	:51
			ldx	#$0d
::51			plp
			rts

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

;*** Sektorspeicher ":diskBlkBuf" löschen.
;    Übergabe:		r1 = Track/Sektor.
:Clr_diskBlkBuf		lda	#$00
			tay
::51			sta	diskBlkBuf,y		;Sektor-Inhalt löschen.
			iny
			bne	:51
			dey
			sty	diskBlkBuf +1		;Link-Zeiger definieren.
			jmp	xPutBlock_dskBuf	;Sektor auf Disk schreiben.

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

;*** Sektor-Adresse gültig ?
;    Übergabe:		r1H = Track.
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

;*** Neue Partition öffnen.
;    Übergabe:		AKKU = Partitions-Nr.
:xOpenPartition		pha
			jsr	xGetPartInfo
			pla
			tay
			txa
			bne	:52

			ldx	dirEntryBuf +0
			bne	:53
::51			ldx	#$05
::52			rts

::53			cpx	#255
			beq	:51
			dex
			bne	:54
			ldx	#$04
::54			stx	:55 +1

			ldx	curDrive
			lda	driveType -8,x
			and	#%00000111
::55			cmp	#$ff
			bne	:51

			lda	dirEntryBuf +21
			sta	r2L
			lda	dirEntryBuf +20
			sta	r2H
			sty	r3L
			jsr	xSetNewGEOS_Part

;*** Neue Diskette öffnen.
:xOpenDisk		jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	ExitOpenDisk		;Ja, Abbruch...

			jsr	IsFormatV2		;Borderblock überprüfen.
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
:xNewDisk		ldx	#$00
:ExitOpenDisk		rts

;*** Neue Geräteadresse setzen.
:xChangeDiskDev		sta	curDrive
			sta	curDevice
			ldx	#$00
			rts

;*** Konvertierung von 1581 nach 1541 und umgekehrt.
:SwapDskNmData		php
			pha
			lda	r1L			;Track 40, Sektor #0 ?
			cmp	#40
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
			cpy	#$1a
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
			jsr	xRL_StashRAM

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
:xPurgeTurbo		ldx	#$00
:EndTurbo		rts

;*** Aktuelle BAM einlesen.
:xGetDirHead		php
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

;*** Aktuelle BAM auf Diskette schreiben.
:xPutDirHead		php				;IRQ sperren.
			sei
			jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xWriteBlock		;BAM-Sektor konvertieren/speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	SetBAM_TrSe2		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xWriteBlock		;BAM-Sektor konvertieren/speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	SetBAM_TrSe3		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xWriteBlock		;BAM-Sektor konvertieren/speichern.
::51			plp				;IRQ-Status zurücksetzen.
			rts

;*** Sektor nach ":diskBlkBuf" einlesen.
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf		;Zeiger auf ":diskBlkBuf" setzen.

;*** Sektor von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xGetBlock
:xReadBlock		jsr	TestTrSe_ADDR
			bcc	:51
			jsr	xPartGetBlock
			jsr	SwapDskNmData
::51			ldy	#$00
			rts

;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf		;Zeiger auf ":diskBlkBuf" setzen.

;*** Sektor auf Diskette schreiben.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xPutBlock
:xWriteBlock		jsr	TestTrSe_ADDR
			bcc	:51
			jsr	SwapDskNmData
			jsr	xPartPutBlock
			jsr	SwapDskNmData
::51			rts

;*** Sektor auf Diskette vergleichen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xVerWriteBlock		jsr	TestTrSe_ADDR
			bcc	:51
			ldx	#$00
::51			rts

;*** LinkBytes von Diskette einlesen.
;    Übergabe:		r1 = Track/Sektor.
;			r4 = Zeiger auf Sektorspeicher.
:xReadLink		jsr	TestTrSe_ADDR
			bcs	GetLinkBytes
:ExitReadLink		rts

;*** Die ersten zwei Bytes eines Sektors einlesen.
:GetLinkBytes		jsr	xTestForRL
::51			txa
			bne	ExitReadLink

::52			ldx	curDrive
			lda	ramBase -8,x
			cmp	PartStart_ADDR +1
			beq	:53

			jsr	xResetGEOS_Part
			txa
			bne	ExitReadLink

::53			php
			sei

			jsr	SaveReg_r0_r3L		;Register ":r0" - ":r3L" sichern.

			lda	#$00			;Startadresse für Sektor
			sta	r0L			;in Partition berechnen.
			sta	r0H

			ldx	r1L			;Aktuellen Track einlesen.
			dex				;Track = #0 ?
			beq	:56			;Ja, weiter...
::54			lda	r0L			;Zeiger auf nächsten Track
			clc				;berechnen.
			adc	#40
			sta	r0L
			bcc	:55
			inc	r0H
::55			dex
			bne	:54

::56			lda	r1H			;Sektoradresse addieren.
			clc
			adc	r0L
			bcc	:57
			inc	r0H
::57			clc
			adc	PartStart_ADDR +0
			sta	r1H
			lda	r0H
			adc	PartStart_ADDR +1
			sta	r3L
			lda	#$00
			sta	r1L
			ldx	#2
			stx	r2L
			sta	r2H
			MoveW	r4,r0
			jsr	xRL_FetchRAM

			jsr	LoadReg_r0_r3L		;Register ":r0" - ":r3L" einlesen.

			ldx	#$00
			plp				;IRQ-Status zurücksetzen.
			rts

;*** Sektor aus aktueller Partition einlesen.
;    Übergabe:		r1   = Track/Sektor.
;			r4   = Sektorspeicher.
:xPartGetBlock		lda	#$80
			b $2c

;*** Sektor in aktuelle Partition kopieren.
;    Übergabe:		r1   = Track/Sektor.
;			r4   = Sektorspeicher.
:xPartPutBlock		lda	#$90

;*** Sektor aus aktueller Partitions einlesen.
;    Übergabe:		AKKU = Jobcode: $80 = lesen.
;				         $90 = schreiben.
;				         $A0 = vergleichen.
;				         $B0 = tauschen.
;			r1   = Track/Sektor.
;			r4   = Sektorspeicher.
:xDoRAMLinkOp		jsr	xTestForRL		;Testen ob RAMLink verfügbar.
			cpx	#$00			;RAMLink angeschlossen ?
			beq	:52			;Ja, weiter...
::51			rts				;Fehler: "Device not present".

::52			ldx	curDrive
			ldy	ramBase -8,x
			cpy	PartStart_ADDR +1	;Ist Partition noch aktiv ?
			beq	:53			;Ja, weiter...

			pha				;RAMLink-Job merken.
			jsr	xResetGEOS_Part		;Aktuelle Partition suchen.
			pla
			cpx	#$00			;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch.

::53			tay
			lda	r3H			;Register ":r3H" auf Stack retten,
			pha				;da für Partitionsadr. benötigt.
			lda	CurrentPart		;Zeiger auf aktive Partition.
			sta	r3H
			tya				;Jobcode zurück in AKKU.
			jsr	xDoRAMLinkPartOp	;Sektor lesen/schreiben.
			pla
			sta	r3H			;Register ":r3H" zurücksetzen.
			rts

;*** Sektor über Partitions-Register einlesen.
;    Übergabe:		AKKU = Jobcode: $80 = lesen.
;				         $90 = schreiben.
;				         $A0 = vergleichen.
;				         $B0 = tauschen.
;			r1   = Track/Sektor.
;			r4   = Sektorspeicher.
;			r3H  = Partition.
:xDoRAMLinkPartOp	sta	:51 +1

			php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich einblenden.
			pha
			lda	#$36
			sta	CPU_DATA

			jsr	$e0a9			;RL-Hardware aktivieren.

::51			lda	#$ff
			sta	$de20
			lda	r1L
			sta	$de21
			lda	r1H
			sta	$de22
			lda	r4L
			sta	$de23
			lda	r4H
			sta	$de24
			lda	r3H
			sta	$de25
			lda	#$01
			sta	$de26

			jsr	$fe09			;Sektor-Jobcode ausführen.

			lda	$de20			;Fehlerstatus einlesen und
			pha				;zwischenspeichern.
			jsr	$fe0f			;RL-Hardware abschalten.
			pla
			tax

			pla				;I/O ausblenden.
			sta	CPU_DATA
			plp				;IRQ zurücksetzen.
			rts

;*** Aktive Partition ermitteln.
:xResetGEOS_Part	lda	#$ff
			ldy	curDrive
			ldx	ramBase -8,y
			jmp	FindPartition

;*** Partitions-Informationen einlesen.
;    Übergabe:		AKKU = Partitions-Nr.
;			       $00 = Aktive Partition.
:xGetPartInfo		ldx	#$ff
			tay
			bne	FindPartition
			lda	CurrentPart

;*** Partition suchen/aktivieren.
;    Übergabe:		AKKU = Partitions-Nr.
;			xReg = $FF: Partitionseintrag nach ":dirEntryBuf".
;			       $xy: HighByte-Adr. der zu aktivierenden Partition.
:FindPartition		sta	RL_PartBuf		;Parameter speichern.
			stx	RL_PartADDR

			jsr	xTestForRL		;Testen ob RAMLink verfügbar.
			txa				;RAMLink angeschlossen ?
			beq	:52			;Ja, weiter...
::51			rts				;Fehler: "Device not present".

::52			jsr	SetRL_Data		;Register zwischenspeichern.

			lda	RL_PartADDR		;Partitions-Adresse einlesen.
			cmp	#$ff			;HighByte = $ff
			beq	:53			;Ja, Partitionsdaten einlesen.

			jsr	FindCurPart		;Aktive Partition suchen.
			txa				;Partition gefunden ?
			bne	ResetRL_Data		;Nein, Abbruch...

			jsr	xSetNewGEOS_Part	;Partition aktivieren.

			ldx	#$00			;Flag: "Kein Fehler..:"
			beq	ResetRL_Data		;Register zurücksetzen.

::53			jsr	LoadPartInfo		;Partitionsdaten einlesen.

;*** Variablen zurücksetzen.
:ResetRL_Data		PopW	r4
			PopW	r3
			PopW	r2
			PopW	r1
			plp
			rts

;*** Variablen zwischenspeichern.
:SetRL_Data		pla
			tax
			pla
			tay

::51			php				;IRQ sperren.
			sei

			PushW	r1
			PushW	r2
			PushW	r3
			PushW	r4

			lda	#$00			;Zeiger für Partitions-Zähler
			sta	r3L			;initialisieren.
			lda	#$ff			;Zeiger auf System-Partition.
			sta	r3H

			lda	#$01			;Zeiger auf ersten Sektor des
			sta	r1L			;Partitions-Verzeichnisses.
			lda	#$00
			sta	r1H
			LoadW	r4,RL_SekBuf		;Speicher für Partitions-Sektor.

			tya
			pha
			txa
			pha
			rts

;*** Aktuelle Partition ermitteln.
:FindCurPart		lda	#$80
			jsr	xDoRAMLinkPartOp	;Sektor aus RL einlesen.
			txa				;Diskettenfehler ?
			beq	:52			;Nein, weiter...
			b $2c				;Nächsten Befehl übergehen.
::51			ldx	#$05			;Partition nicht gefunden,
			rts				;Fehler: "File not found".

::52			ldy	#$00
::53			lda	RL_SekBuf  + 2,y	;Partition erstellt ?
			beq	:54			;Nein, weiter...
			lda	RL_PartADDR
			cmp	RL_SekBuf  +22,y	;Partitions-Adresse vergleichen.
			beq	:55			; => Partition gefunden.

::54			inc	r3L			;Partitions-Zähler korrigieren.
			tya
			clc
			adc	#$20			;Zeiger auf nächsten Eintrag.
			tay				;Alle Partitionen geprüft ?
			bne	:53			;Nein, weiter...

			inc	r1H			;Zeiger auf nächsten Sektor.
			CmpBI	r1H,4			;Alle Sektoren geprüft ?
			bcc	FindCurPart		;Nein, weiter...
			bcs	:51			;Fehler, Partition nicht gefunden.

::55			sta	r2H			;HighByte-Adresse speichern.
			lda	RL_SekBuf  +23,y
			sta	r2L			;LowByte -Adresse speichern.
			ldx	#$00			;Flag: "Kein Fehler".
			rts

;*** Partitions-Nr. suchen und Eintrag nach ":dirEntryBuf" kopieren.
:LoadPartInfo		lda	RL_PartBuf		;Partitions-Nr. einlesen.
			cmp	#$ff			;Systempartition ?
			bne	:51			;Nein, weiter...
			lda	#$00			;Partitions-Nr. korrigieren.

::51			lsr				;Zeiger auf Verzeichnissektor
			lsr				;berechnen.
			lsr
			sta	r1H
			lda	#$80
			jsr	xDoRAMLinkPartOp	;Sektor von Diskette einlesen.
			txa				;Diskettenfehler ?
			beq	:53			;Nein, weiter...
::52			rts

::53			lda	RL_PartBuf		;Zeiger auf Eintrag berechnen.
			and	#%00000111
			asl
			asl
			asl
			asl
			asl
			tay
			ldx	#$00
::54			lda	RL_SekBuf   +2,y	;Eintrag nach ":dirEntryBuf"
			sta	dirEntryBuf   ,x	;kopieren.
			iny
			inx
			cpx	#30
			bcc	:54

			ldx	#$00			;Flag: "Kein Fehler"...
			rts

;*** Neue Partition in GEOS-Kernal für aktuelles Laufwerk aktivieren.
;    Übergabe:		r2  = Startadresse Partition (low/middle-Byte).
;			r3L = Partitions-Nr.
:xSetNewGEOS_Part	ldy	curDrive		;Partitions-Adresse setzen.
			lda	r2L			;Damit ist Treiber kompatibel zu
			sta	driveData +3		;anderen RAMLink-Programmen.
			sta	PartStart_ADDR +0	;Adresse für Vergleichszwecke
			lda	r2H			;intern zwischenspeichern.
			sta	ramBase   -8,y
			sta	PartStart_ADDR +1
			lda	r3L			;Partition intern
			sta	CurrentPart		;zwischenspeichern.

			jsr	SaveReg_r0_r3L		;Register ":r0" - ":r3L" speichern.

			lda	#< CurrentPart		;Startadresse Variablen.
			sta	r0L
			lda	#> CurrentPart
			sta	r0H

			ldx	curDrive
			lda	DskDrvBaseL -8,x	;Startadresse Variablen innerhalb
			clc				;Laufwerkstreiber in GEOS-RAM.
			adc	#< OffsetVarData
			sta	r1L
			lda	DskDrvBaseH -8,x
			adc	#> OffsetVarData
			sta	r1H

			lda	#3			;Anzahl Bytes.
			sta	r2L
			lda	#0
			sta	r2H
			sta	r3L			;Zeiger auf GEOS-RAM-Bank.

			jsr	xRL_StashRAM		;Variablen sichern.

			jsr	LoadReg_r0_r3L		;Register ":r0" - ":r3L" einlesen.

::51			rts

;*** Register ":r0" bis ":r3L" zwischenspeichern.
:SaveReg_r0_r3L		pla
			tax
			pla
			tay
			PushW	r0
			PushW	r1
			PushW	r2
			PushB	r3L
			tya
			pha
			txa
			pha
			rts

;*** Register ":r0" bis ":r3L" zurücksetzen.
:LoadReg_r0_r3L		pla
			tax
			pla
			tay
			PopB	r3L
			PopW	r2
			PopW	r1
			PopW	r0
			tya
			pha
			txa
			pha
			rts

;*** Einsprungtabelle RAM-Funktionen.
:xRL_VerifyRAM		ldy	#%10010011		;RAM-Bereich vergleichen.
			b $2c
:xRL_StashRAM		ldy	#%10010000		;RAM-Bereich speichern.
			b $2c
:xRL_SwapRAM		ldy	#%10010010		;RAM-Bereich tauschen.
			b $2c
:xRL_FetchRAM		ldy	#%10010001		;RAM-Bereich laden.

:xRL_DoRAMOp		tya
			jsr	xTestForRL
			tay
			txa
			bne	:52

			ldx	#$0d
			lda	ramExpSize
			beq	:52

			php
			sei

			lda	CPU_DATA
			pha
			lda	#$36
			sta	CPU_DATA

			tya
			pha

			jsr	$e0a9

			pla
			sta	$de01
			lda	r0L
			sta	$de02
			lda	r0H
			sta	$de03
			lda	r1L
			sta	$de04
			lda	r1H
			sta	$de05
			lda	r3L
			sta	$de06
			lda	r2L
			sta	$de07
			lda	r2H
			sta	$de08
			lda	#$00
			sta	$de0a

			jsr	$fe06			;Job ausführen und
			jsr	$fe0f			;RL-Hardware abschalten.

			pla
			sta	CPU_DATA

			plp
			lda	#%01000000
			ldx	#$00
::52			rts

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

:GetCurDirSek		jsr	xGetBlock_dskBuf	;Verzeichnissektor einlesen.

			ldy	#$00
			lda	#> diskBlkBuf +2	;Zeiger auf ersten Eintrag.
			sta	r5H
			lda	#< diskBlkBuf +2
			sta	r5L
:EndDirSekJob		rts

;*** Zeiger auf Borderblock einlesen.
:xGetBorderBlock	jsr	xGetDirHead		;Aktuelle BAM einlesen.
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

::51			jsr	xGetBlock_dskBuf	;Sektor von Diskette lesen.
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
			cpy	#36			;36 Seiten/8 Dateien = 288 Einträge.
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
			jsr	xPutBlock_dskBuf	;Sektor auf Diskette speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			MoveB	r3L,r1L			;Zeiger auf aktuellen Sektor.
			MoveB	r3H,r1H
			jsr	Clr_diskBlkBuf		;Sektor-Speicher löschen.

::51			PopW	r6			;Register ":r6" zurücksetzen.
::52			rts

;*** Auf GEOS-Diskette testen.
;    Übergabe:		r5 = Zeiger auf aktuelle BAM (":curDirHead").
:xChkDkGEOS		ldy	#173			;Zeiger auf BAM.
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

;*** BorderBlock nach Track #40, Sektor #39 verschieben.
:IsFormatV2		ldx	curDirHead +171		;Track für BorderBlock einlesen.
			beq	:51			; => Kein BorderBlock, Ende...
			cpx	#40			;Liegt Borderblock auf Track #40 ?
			bne	:52			;Nein, neu positionieren.
			ldy	curDirHead +172		;Sektor für BorderBlock einlesen.
			cpy	#39			;Liegt Borderblock auf Sektor #39 ?
			bne	:52			;Nein, neu positionieren.
::51			rts				;Ende...

::52			PushW	r1			;Register zwischenspeichern.
			PushW	r4

			PushW	r3			;Register zwischenspeichern.
			PushW	r5

			txa				;Zeiger auf aktuellen BorderBlock
			pha				;zwischenspeichern.
			tya
			pha
			jsr	xSetGEOSDisk		;Neuen BorderBlock auf Track #40,
			pla				;Sektor #39 erstellen.
			sta	r1H
			pla
			sta	r1L			;Zeiger auf aktuellen BorderBlock.

			PopW	r5			;Register zurücksetzen.
			PopW	r3

			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			LoadW	r4,RL_SekBuf
			jsr	xGetBlock		;Aktuellen BorderBlock einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	r1L			;Zeiger auf aktuellen BorderBlock
			pha				;zwischenspeichern.
			lda	r1H
			pha

			lda	curDirHead +171		;Zeiger auf neuen BorderBlock.
			sta	r1L
			lda	curDirHead +172
			sta	r1H

			jsr	xPutBlock		;Alten BorderBlock speichern.

			pla				;Zeiger auf alten BorderBlock
			tax				;wieder einlesen.
			pla
			tay

			PushW	r6			;Register zwischenspeichern.

			sty	r6L			;Zeiger auf alten BorderBlock.
			stx	r6H

			PushW	r7			;Register zwischenspeichern.
			PushW	r8
			jsr	xFreeBlock		;Alten BorderBlock freigeben.
			PopW	r8			;Register zurücksetzen.
			PopW	r7

			PopW	r6			;Register zurücksetzen.

::53			PopW	r4			;Register zurücksetzen.
			PopW	r1
			rts
