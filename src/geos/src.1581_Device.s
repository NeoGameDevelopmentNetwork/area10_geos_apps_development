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
			t "src.1581_Tur.ext"
:dir3Head		= $9c80
:BorderBlockTr		= 40
:BorderBlockSe		= 39
endif

			o $9000
			n "DiskDev_1581"
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
:vTurboRoutine_r1	jmp	xTurboRoutine_r1
:vGetDiskError		jmp	xGetDiskError
:vAllocateBlock		jmp	xAllocateBlock
:vReadLink		jmp	xReadLink

;*** Variablen.
:IRQ_RegBuf		b $00
:CPU_RegBuf		b $00
:RegD015_Buf		b $00
:RegD01A_Buf		b $00
:RegD030_Buf		b $00

:TurboRoutineL		b $00
:TurboRoutineH		b $00
:TurboParameter1	b $00
:TurboParameter2	b $00
:StopTurboByte		b $00
:Flag_GetPutBAM		b $00
:SwapByteBuf		b $00
:RepeatFunction		b $00
:ErrorCode		b $00
:FloppyROM_Data		s $02
:Flag_BorderBlock	b $00

:FormatText		b "GEOS format V1.0",NULL

;*** Befehl zum wechseln dr Laufwerksadresse.
:Floppy_U0_x		b "U0",$3e,$08,NULL

:SingleBitTab		b $01,$02,$04,$08,$10,$20,$40,$80

;*** befehl zum einlesen von Floppy-Bytes.
:Floppy_MR		b "M-R"
:FloppyROM_L		b $00
:FloppyROM_H		b $00

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w TD_Start

;*** Befehl für "M-W".
:Floppy_MW		b "M-W"
:Floppy_ADDR_L		b $00
:Floppy_ADDR_H		b $00

;*** Adresse von ":dir3Head" in REU.
:DskDrvBaseL		b < $8300
			b < $9080
			b < $9e00
			b < $ab80
:DskDrvBaseH		b > $8300
			b > $9080
			b > $9e00
			b > $ab80

:ErrCodes		b $01,$05,$02,$08
			b $08,$01,$05,$01
			b $05,$05,$05

:NibbleByteH		b $00,$80,$20,$a0
			b $40,$c0,$60,$e0
			b $10,$90,$30,$b0
			b $50,$d0,$70,$f0

:NibbleByteL		b $00,$20,$00,$20
			b $10,$30,$10,$30
			b $00,$20,$00,$20
			b $10,$30,$10,$30

;*** Zeiger auf ":diskBlkBuf" setzen.
:Set_diskBlkBuf		lda	#< diskBlkBuf
			sta	r4L
			lda	#> diskBlkBuf
			sta	r4H
			rts

;*** Zeiger auf aktuelle BAM im Speicher richten.
:Set_curDirHead		lda	#< curDirHead
			sta	r5L
			lda	#> curDirHead
			sta	r5H
			rts

;*** Zeiger auf ersten Verzeichnis-Sektor.
:Set_1stDirSek		lda	#$28
			sta	r1L
			lda	#$03
			sta	r1H
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

			lda	$dd00
			and	#$07
			sta	$8e
			sta	TurboInitByte_2 +1
			sta	TurboInitByte_3 +1
			ora	#$30
			sta	$8f
			sta	TurboInitByte_1 +1
			lda	$8e
			ora	#$10
			sta	StopTurboByte
			sta	StopTurboMode   +1

			ldy	#$1f
::52			lda	NibbleByteH,y
			and	#$f0
			ora	$8e
			sta	NibbleByteH,y
			dey
			bpl	:52
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
:xOpenDisk		jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa
			bne	:51			;Fehler ? Ja, Abbruch...

			jsr	IsFormatV2		;BorderBlock verschieben.
			jsr	Set_curDirHead		;Zeiger auf BAM richten.
			jsr	xChkDkGEOS		;Auf GEOS-Diskette testen.

			lda	#<curDirHead +$90
			sta	r4L
			lda	#>curDirHead +$90
			sta	r4H
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			ldx	#r4L
			ldy	#r5L
			lda	#18
			jsr	CopyFString		;Disketten-Name kopieren.
			ldx	#$00
::51			rts

;*** Neue Diskette öffnen.
:xNewDisk		jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Laufwerksfehler ?
			bne	:53			;Ja, Abbruch...

			lda	#$00
			sta	RepeatFunction		;Zähler für Versuche auf #0.
			sta	r1L

			jsr	InitForIO		;I/O-Bereich einblenden.

::51			ldx	#> TD_NewDisk		;NewDisk ausführen.
			lda	#< TD_NewDisk
			jsr	xTurboRoutSet_r1

			jsr	xGetDiskError		;Diskettenfehler ?
			beq	:52			;Nein, weiter...

			inc	RepeatFunction		;Anzahl Versuche +1.
			cpy	RepeatFunction		;Alle versuche ausgeführt ?
			beq	:52			;Ja, Abbruch...
			bcs	:51			;Nein, NewDisk nochmal aufrufen...
::52			jmp	DoneWithIO		;I/O-Bereich ausblenden.
::53			rts

;*** Geräteadresse ändern.
;    Übergabe:		AKKU     = Neue Geräteadresse.
;			curDrive = Aktuelle Geräteadresse.
:xChangeDiskDev		sta	Floppy_U0_x +3		;Neue Adresse merken.

			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich einbleden.

			ldx	#> Floppy_U0_x
			lda	#< Floppy_U0_x
			jsr	SendFloppyCom		;Geräteadresse ändern.
			txa				;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...

			ldy	Floppy_U0_x +3		;Geräteadresse einlesen.
			lda	#$00
			sta	turboFlags -8,y		;TurboFlags löschen.
			sty	curDrive		;Neue Adresse an GEOS übergeben.
			sty	curDevice
			jmp	TurnOffCurDrive		;Laufwerk deaktivieren.
::51			jmp	DoneWithIO

;*** Konvertierung der BAM von 1581 nach 1541 und umgekehrt.
:SwapDskNmData		lda	r1L
			cmp	#40
			bne	:52
			lda	r1H
			bne	:52

			ldy	#$04
::51			lda	(r4L),y
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
::52			rts

;*** TurboDOS aktivieren.
:xEnterTurbo		ldx	curDrive
			lda	turboFlags -8,x		;TurboRoutinen in FloppyRAM ?
			bmi	:51			;Ja, weiter...

			jsr	InitTurboDOS		;TuroDOS installieren.
			txa				;Laufwerksfehler ?
			bne	:56			;Ja, Abbruch...

			ldx	curDrive
			lda	#$80			;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags -8,x		;setzen.
::51			and	#$40			;TurboDOS bereits aktiv ?
			bne	:54			;Ja, weiter...

			jsr	InitForIO		;I/O aktivieren.

			ldx	#>ExecTurboDOS
			lda	#<ExecTurboDOS
			jsr	SendFloppyCom		;"M-E" ausführen.
			txa				;Laufwerksfehler ?
			bne	:55			;Ja, Abbruch...

			jsr	$ffae			;Laufwerk abschalten.

			sei				;IRQ sperren.
			ldy	#$21			;Warteschleife.
::52			dey
			bne	:52
			jsr	StopTurboMode
::53			bit	$dd00			;Warten bis Laufwerk aktiv.
			bmi	:53

			jsr	DoneWithIO		;I/O abschalten.

			ldx	curDrive
			lda	turboFlags -8,x
			ora	#$40			;Flag für "TurboDOS in FloppyRAM
			sta	turboFlags -8,x		;ist aktiv" setzen.
::54			ldx	#$00			;Flag "Kein Fehler"...
			rts				;Ende...
::55			jsr	DoneWithIO
::56			rts

;*** TurboDOS deaktivieren.
:xExitTurbo		txa
			pha
			ldx	curDrive
			lda	turboFlags -8,x
			and	#$40			;Aktuelle Diskette geöffnet ?
			beq	:51			;Nein, weiter...

			jsr	TurnOffTurboDOS		;TurboDOS abschalten.

			ldx	curDrive
			lda	turboFlags -8,x
			and	#$bf
			sta	turboFlags -8,x

			bit	sysRAMFlg		;Laufwerkstreiber in REU ?
			bvc	:51			;Nein, Ende...

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

::51			pla
			tax
			rts

;*** TurboDOS in aktuellem Laufwerk abschalten.
:xPurgeTurbo		jsr	ExitTurbo

			ldy	curDrive
			lda	#$00
			sta	turboFlags -8,y
			rts

;*** Aktuelle BAM einlesen.
:xGetDirHead		lda	#$ff
			b $2c

;*** Aktuelle BAM speichern.
:xPutDirHead		lda	#$00
			sta	Flag_GetPutBAM		;Modus: BAM einlesen.

			jsr	EnterTurbo		;Turbo-Software aktivieren.
			txa				;Laufwerksfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	GetPutBAM_TrSe1		;BAM-Sektor #1 einlesen.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	GetPutBAM_TrSe2		;BAM-Sektor #2 einlesen.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			jsr	GetPutBAM_TrSe3		;BAM-Sektor #3 einlesen.
::51			jmp	DoneWithIO		;I/O-Bereich ausblenden.

::52			rts

;*** Sektor nach ":diskBlkBuf" einlesen.
:xGetBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor nach ":r4" einlesen.
:xGetBlock		jsr	EnterTurbo		;Turbo-Software aktivieren.
			txa
			bne	:51			;Fehler ? Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich aktivieren.
			jsr	xReadBlock		;Sektor einlesen.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.
::51			rts

;*** Sektor in ":diskBlkBuf" auf Diskette schreiben.
:xPutBlock_dskBuf	jsr	Set_diskBlkBuf

;*** Sektor in ":r4" auf Diskette schreiben.
:xPutBlock		jsr	EnterTurbo		;Turbo-Software aktivieren.
			txa
			bne	:51			;Fehler ? Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich aktivieren.
			jsr	xWriteBlock		;Sektor speichern.
			jmp	DoneWithIO		;I/O-Bereich ausblenden.
::51			rts

;*** BAM-Sektor #1 bis #3 einlesen.
:GetPutBAM_TrSe1	ldx	#> curDirHead		;Zeiger auf ":curDirHead".
			ldy	#< curDirHead
			lda	#$00			;Sektor #0.
			beq	GetPutBAM_TrSe

:GetPutBAM_TrSe2	ldx	#> dir2Head		;Zeiger auf ":dir2Head".
			ldy	#< dir2Head
			lda	#$01			;Sektor #1.
			bne	GetPutBAM_TrSe

:GetPutBAM_TrSe3	ldx	#> dir3Head		;Zeiger auf ":dir3Head".
			ldy	#< dir3Head
			lda	#$02			;Sektor #2.

:GetPutBAM_TrSe		stx	r4H			;Zeiger auf BAM-Speicher setzen.
			sty	r4L

			sta	r1H			;Zeiger auf BAM-Sektor   setzen.
			lda	#$28
			sta	r1L

			bit	Flag_GetPutBAM		;BAM-Modus testen.
			bmi	:51			; => BAM einlesen.

			jmp	xWriteBlock		;BAM-Sektor schreiben.
::51			jmp	xReadBlock		;BAM-Sektor einlesen.

;*** LinkBytes einlesen.
:xReadLink		jsr	TestTrSe_ADDR		;Sektoradresse testen.
			bcc	:51			;Fehler, Abbruch...

			lda	r1L			;Flag für LinkBytes setzen.
			ora	#$80
			sta	r1L
			jsr	GetLinkBytes		;LinkBytes einlesen
			lda	r1L
			and	#$7f			;Flag für LinkBytes löschen.
			sta	r1L
::51			rts

;*** Sektor einlesen.
:xReadBlock		jsr	TestTrSe_ADDR
			bcc	ExitReadBlock

;*** Einsprung aus ":xReadLink".
:GetLinkBytes		ldx	#> TD_GetSektor
			lda	#< TD_GetSektor
			jsr	xTurboRoutSet_r1

			ldx	#> TD_RdSekData
			lda	#< TD_RdSekData
			jsr	xTurboRoutine

			lda	r4H
			sta	$8c
			lda	r4L
			sta	$8b

			ldy	#$00
			lda	r1L
			bpl	:51
			ldy	#$02
::51			jsr	TurboBytes_GET

			jsr	GetReadError
			beq	:52

			inc	RepeatFunction
			cpy	RepeatFunction
			beq	ExitReadBlock
			bcs	GetLinkBytes

::52			jsr	SwapDskNmData
:ExitReadBlock		ldy	#$00
			rts

;*** Sektor in ":r4" auf Diskette schreiben.
:xWriteBlock		jsr	TestTrSe_ADDR		;Sektor-Adresse testen.
			bcc	:53			; => Fehler, Abbruch...

			jsr	SwapDskNmData		;BAM nach 1581 Konvertieren.

::51			ldx	#> TD_WrSekData
			lda	#< TD_WrSekData
			jsr	xTurboRoutSet_r1

			lda	r4H
			sta	$8c
			lda	r4L
			sta	$8b
			ldy	#$00
			jsr	Turbo_WriteBlock	;256 Byte an Floppy senden.

			jsr	GetReadError		;Diskettenfehler ?
			beq	:52			;Nein, weiter...

			inc	RepeatFunction		;Fehlerzähler korrigieren.
			cpy	RepeatFunction		;Zähler abgelaufen ?
			beq	:52			;Ja, Ende...
			bcs	:51			;Nein, nochmal schreiben...

::52			jsr	SwapDskNmData		;BAM zurückkonvertieren.
::53			rts

;*** Sektor auf Diskette vergleichen.
:xVerWriteBlock		ldx	#$00
			rts

;*** Ist Track/Sektor-Adresse in Ordnung ?
:TestTrSe_ADDR		lda	#$00
			sta	RepeatFunction

			ldx	#$02			;Vorbereiten: "Falsche Sektor-Nr.".
			lda	r1L			;Track-Nummer einlesen.
			beq	CancelTest		; =  0, Fehler...
			cmp	#81
			bcs	CancelTest		; > 80, Fehler...

			lda	r1H			;Sektor-Adresse einlesen.
			cmp	#40			; > 79 ?
			bcs	CancelTest		;Ja, Fehler...

			sec
			rts

:CancelTest		clc
			rts

;*** Anzahl Sektoren auf Diskette belegen.
;    Übergabe:		r2 = Anzahl Bytes.
;			r6 = Zeiger auf Track/Sektor-Tabelle.
:xBlkAlloc		;lda	#1			;Zeiger auf ersten Sektor
			;sta	r3L			;auf Diskette.
			;lda	#0			;*** Kann entfallen, da SetNextFree
			;sta	r3H			;*** diesen Wert selbst definiert!!

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

::51			jsr	Set_curDirHead
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
;    Zuerst auf Tracks #39-#1 abwärts suchen.
;    Dann von Track #41 bis #80 aufwärts suchen.
:xSetNextFree		lda	r3L			;Aktuellen Track einlesen.
			cmp	#40			;Sektor für Verzeichnis belegen ?
			beq	:51			;Ja, weiter...
			lda	#39			;Startwert für Sektorsuche...
::51			sta	r6L

;*** Nächsten freien Sektor suchen.
:FindNextFree		jsr	GetBAM_Offset		;Zeiger auf BAM berechnen.
			tay				;":dir3Head" ?
			bne	:51			;Ja, weiter...

			lda	dir2Head +16,x
			jmp	:52
::51			lda	dir3Head +16,x
::52			bne	GetSekOnTrack

;*** Track mit freiem Sektor suchen.
:FindNextTrack		lda	r6L			;Aktuellen Track einlesen.
			cmp	#40			;Suche nach Verzeichnis-Sektor ?
			bne	:52			;Nein, weiter...
::51			ldx	#$03			;Fehler, Diskette voll!
			rts

::52			cmp	#41			;Track #41-#80 ?
			bcs	:53			;Ja, weiter...
			dec	r6L			;Zeiger auf letzten Track setzen.
			bne	FindNextFree		;Ende erreicht ? Nein, weiter...
			lda	#40			;Zeiger auf Track #41-80 setzen.
			sta	r6L
::53			inc	r6L			;Zeiger auf nächsten track.
			lda	r6L
			cmp	#81			;Track #81 erreicht ?
			bcc	FindNextFree		;Nein, weiter...
			bcs	:51			;Fehler, Diskette voll..

;*** Freien Sektor auf Track suchen.
:GetSekOnTrack		txa
			clc
			adc	#$06 -1			;Zeiger auf letztes BAM-Byte für
			sta	:54  +1			;Track und zwischenspeichern.

			lda	#$00			;Zeiger auf ersten Sektor.
			sta	r6H

::51			inx				;Zeiger auf nächstes BAM-Byte.
			tya				;":dir3Head" ?
			bne	:52			;Ja, weiter...
			lda	dir2Head +16,x
			jmp	:53
::52			lda	dir3Head +16,x
::53			bne	:55			;Sektor gefunden ? => Ja, weiter...

			lda	r6H			;Zeiger auf nächsten Sektor.
			clc
			adc	#$08
			sta	r6H

::54			cpx	#$ff			;Alle BAM-Bytes geprüft ?
			bne	:51			;Nein, weiter...
			ldx	#$03			;Fehler, Diskette voll...
			rts

::55			lsr				;Zeiger auf Sektor berechnen.
			bcs	:56			;BAM-Byte solange verschieben bis
			inc	r6H			;#1-BIT gefunden => freier Sektor
			bne	:55			;auf Track in BAM-Byte gefunden.

::56			jsr	xAllocateBlock		;Block auf Diskette belegen.
			txa				;Diskettenfehler ?
			bne	:57			;Ja, Abbruch...

			MoveB	r6L,r3L			;Sektor nach ":r3" kopieren.
			MoveB	r6H,r3H
			ldx	#$00			;Flag: "Kein Fehler"...
::57			rts				;Ende...

;*** Offest auf BAM berechnen.
;    Übergabe:		r6L  = Track
;    Rückgabe:		xReg = Offset auf Byte.
;			AKKU = $00, dir2Head
;			       $FF, dir3Head
:GetBAM_Offset		lda	#$00
			sta	:53 +1

			lda	r6L
			cmp	#41
			bcc	:51
			sbc	#40
			dec	:53 +1

::51			sec
			sbc	#$01
			asl
			sta	:52 +1
			asl
			clc
::52			adc	#$ff
			tax
::53			lda	#$ff
			rts

;*** Sektor in BAM belegen.
;    Übergabe:		r6 = Track/Sektor.
:xAllocateBlock		jsr	FindBAMBit
			bne	EditBAM_dir3Head
			beq	BAD_BAM_Block

;*** Sektor in BAM freigeben.
;    Übergabe:		r6 = Track/Sektor.
:xFreeBlock		jsr	FindBAMBit
			beq	EditBAM_dir3Head
:BAD_BAM_Block		ldx	#$06
			rts

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
			ldx	#$00			;Flag für "Kein Fehler"...
			rts

::51			inc	dir3Head +16,x		;Anzahl Sektoren +1.
			ldx	#$00			;Flag für "Kein Fehler"...
			rts

;*** Sektor in BAM (":dir2Head") belegen / freigeben.
:EditBAM_dir2Head	lda	r8H			;Bit in BAM wechseln, damit
			eor	dir2Head +16,x		;Sektor belegen/freigeben.
			sta	dir2Head +16,x
			ldx	r7H

			plp				;Sektor freigeben ?
			beq	:51			;Ja, weiter...

			dec	dir2Head +16,x
			ldx	#$00			;Flag für "Kein Fehler"...
			rts

::51			inc	dir2Head +16,x
			ldx	#$00			;Flag für "Kein Fehler"...
			rts

;*** Zeiger auf Sektor in BAM berechnen.
;    Übergabe:		r6 = Track/Sektor.
:xFindBAMBit		lda	r6H			;Sektor einlesen.
			and	#$07
			tax				;8-Bit-Wert berechnen und
			lda	SingleBitTab,x		;Bit-Maske einlesen.
			sta	r8H

			jsr	GetBAM_Offset		;Zeiger auf BAM berechnen.
			stx	r7H
			pha

			lda	r6H
			lsr
			lsr
			lsr
			sec
			adc	r7H
			tax

			pla
			bne	:51

			lda	dir2Head +16,x
			and	r8H
			rts

::51			lda	dir3Head +16,x
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
			tay				;Ende BAM#2 erreicht ?
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
:xGet1stDirEntry	jsr	Set_1stDirSek

			lda	#$00
			sta	Flag_BorderBlock
			beq	GetCurDirSek

;*** Nächsten Verzeichnis-Eintrag einlesen.
;    Übergabe:		r5 = Zeiger auf aktuelle Eintrag in Verzeichnis-Sektor.
;			diskBlkBuf = Aktueller Verzeichnis-Sektor.
:xGetNxtDirEntry	ldx	#$00			;Flag: Kein Fehler...
			ldy	#$00			;Zeiger auf erstes Byte in Eintrag.

			clc				;Zeiger auf nächsten Eintrag.
			lda	#$20
			adc	r5L
			sta	r5L
			bcc	:51
			inc	r5H

::51			lda	r5H			;Alle Einträge aus Sektor ?
			cmp	#> diskBlkBuf +255
			bne	:52
			lda	r5L
			cmp	#< diskBlkBuf +255
::52			bcc	EndGetDirSek		;Nein, weiter...

			ldy	#$ff
			lda	diskBlkBuf +$01		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	diskBlkBuf +$00
			sta	r1L			;Sektor verfügbar ?
			bne	GetCurDirSek		;Ja, weiter...

			lda	Flag_BorderBlock	;Borderblock bereits aktiv ?
			bne	EndGetDirSek		;Ja, Ende...
			dec	Flag_BorderBlock	;Borderblock aktivieren.

			jsr	vGetBorderBlock		;Zeiger auf Borderblock berechnen.
			txa				;Diskettenfehler ?
			bne	EndGetDirSek		;Ja, Abbruch...
			tya				;BorderBlock verfügbar ?
			bne	EndGetDirSek		;Nein, Ende...

;*** Nächsten Verzeichnis-Sektor einlesen.
:GetCurDirSek		jsr	vGetBlock_dskBuf	;Sektor einelesen.

			ldy	#$00			;Zeiger auf erstes Byte in Eintrag.
			LoadW	r5,diskBlkBuf +2	;Zeiger auf Eintrag.

:EndGetDirSek		rts

;*** Zeiger auf Borderblock einlesen.
:xGetBorderBlock	jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			jsr	Set_curDirHead		;Zeiger auf BAM berechnen.
			jsr	xChkDkGEOS		;Auf GEOS-Diskette testen.
			bne	:51			; => Borderblock einlesen...

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

			jsr	Set_1stDirSek		;Zeiger auf ersten Verzeichnis-
							;Sektor setzen.

::51			jsr	vGetBlock_dskBuf	;Sektor von Diskette lesen.
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
			jsr	SetNextFree		;Freien Sektor suchen.

			lda	r3H			;Freien Sektor als LinkBytes in
			sta	diskBlkBuf +$01		;aktuellem Verzeichnis-Sektor
			lda	r3L			;eintragen.
			sta	diskBlkBuf +$00
			jsr	vPutBlock_dskBuf	;Sektor auf Diskette speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			MoveB	r3L,r1L			;Zeiger auf aktuellen Sektor.
			MoveB	r3H,r1H
			jsr	Clr_diskBlkBuf		;Sektor-Inhalt löschen.

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
:xSetGEOSDisk		jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			lda	#40			;Standardwert für Borderblock auf
			sta	r3L			;Track #40, Sektor #39 setzen.
			lda	#39
			sta	r3H
			jsr	SetNextFree		;Nächsten freien Sektor suchen.
			txa				;Ist Sektor frei ?
			bne	:53			;Nein, Abbruch...

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

			jmp	PutDirHead		;BAM auf Diskette schreiben.

::53			rts

;*** Auf CMD-Laufwerk testen.
:TestForCMD_Drive	jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#$00			;Fehler-Flag löschen.
			sta	STATUS

			lda	#> FloppyROM_Data	;Zeiger auf Zwischenspeicher.
			sta	$8e
			lda	#< FloppyROM_Data
			sta	$8d

			lda	#$fe			;Zeiger auf ROM-Adresse.
			sta	FloppyROM_H
			lda	#$a0
			sta	FloppyROM_L

			jsr	GetROM_Bytes		;Bytes aus FloppyROM einlesen.
			txa				;Laufwerksfehler ?
			bne	:52			;Ja, Abbruch...

			lda	FloppyROM_Data +0	;Auf CMD-Kennung testen.
			cmp	#"C"
			bne	:51
			lda	FloppyROM_Data +1
			cmp	#"M"
			bne	:51

			ldx	#$00			;CMD-Laufwerk.
			b $2c
::51			ldx	#$ff			;Kein CMD-Laufwerk.
::52			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			rts

;*** Bytes aus FloppyROM einlesen.
:GetROM_Bytes		ldx	#> Floppy_MR
			lda	#< Floppy_MR
			jsr	SendFloppyCom		;Floppy-Befehl senden.
			txa				;Laufwerksfehler ?
			bne	:52			;Ja, Abbruch...

			lda	#$02			;Datenkanal öffnen.
			jsr	$ffa8
			jsr	$ffae
			lda	curDrive
			jsr	$ffb4

			lda	#$ff
			jsr	$ff96
			ldy	#$00
::51			jsr	$ffa5			;Byte über ser. Bus einlesen.
			sta	($8d),y
			iny
			cpy	#$02
			bcc	:51
			jsr	$ffab			;Datenkanal schließen.
			ldx	#$00
::52			rts

;*** Floppy-Befehl an Laufwerk senden, sendet genau 5 Bytes!
;    Übergabe:		AKKU/xReg, Zeiger auf Floppy-Befehl.
:SendFloppyCom		stx	$8c			;Zeiger auf Floppy-Befehl sichern.
			sta	$8b

			lda	#$00
			sta	STATUS
			lda	curDrive
			jsr	$ffb1			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler ?
			bmi	:52			;Ja, Abbruch...

			lda	#$ff
			jsr	$ff93			;Sekundäradresse senden.
			bit	STATUS			;Laufwerksfehler ?
			bmi	:52			;Ja, Abbruch...

			ldy	#$00
::51			lda	($8b),y			;Befehl senden.
			jsr	$ffa8
			iny
			cpy	#$05
			bcc	:51
			ldx	#$00
			rts

::52			jsr	$ffae			;Laufwerk abschalten.
			ldx	#$0d			;Flag: "Kein Laufwerk"...
			rts

;*** Floppy-Routine ohne Parameter aufrufen.
;    Übergabe:		AKKU/xReg, Low/High-Byte der Turbo-Routine.
:xTurboRoutine		stx	$8c			;Zeiger auf Routine nach $8b/$8c
			sta	$8b			;kopieren.

			ldy	#$02			;2-Byte-Befehl.
			bne	InitTurboData		;Befehl ausführen.

;*** Floppy-Programm mit zwei Byte-Parameter starten.
;    Übergabe:		AKKU/xReg, Low/High-Byte der Turbo-Routine.
;			r1L/r1H  , Parameter-Bytes.
:xTurboRoutSet_r1	stx	$8c			;Zeiger auf Routine nach $8b/$8c
			sta	$8b			;kopieren.

;*** Floppy-Programm mit zwei Byte-Parameter starten.
;    Übergabe:		$8B/$8C  , Low/High-Byte der Turbo-Routine.
;			r1L/r1H  , Parameter-Bytes.
:xTurboRoutine_r1	ldy	#$04			;4-Byte-Befehl.

			lda	r1H			;Parameter-Bytes in Init-Befehl
			sta	TurboParameter2 		;kopieren.
			lda	r1L
			sta	TurboParameter1

;*** Turbodaten initialisieren.
;    Übergabe:		$8B/$8C = Zeiger auf TurboRoutine.
;			yReg	 = Anzahl Bytes (Routine+Parameter)
:InitTurboData		lda	$8c			;Auszuführende Routine in
			sta	TurboRoutineH		;Init-Befehl kopieren.
			lda	$8b
			sta	TurboRoutineL

			lda	#> TurboRoutineL
			sta	$8c
			lda	#< TurboRoutineL
			sta	$8b
			jmp	TurboBytes_SEND

;*** Fehlerstatus über ser. Bus einlesen.
:GetErrorData		ldy	#$01			;Fehlercode
			jsr	TurboBytes_GET		;aus Floppy-Programm abfragen.
			pha				;Anzahl Bytes auf Stack retten und
			tay				;Zähler initialisieren.
			jsr	TurboBytes_GET		;Anzahl Bytes aus FloppyRAM lesen.
			pla				;Anzahl Bytes wieder vom Stack
			tay				;holen und in yReg kopieren.
			rts

;*** Turbo-Modus aktivieren.
:StartTurboMode		sei
			lda	$8e
			sta	$dd00

;*** Warten, bis TurboModus bereit.
:WaitTurboReady		bit	$dd00
			bpl	WaitTurboReady
			rts

;*** Diskettenstatus inlesen.
:xGetDiskError		ldx	#> TD_SendStatus
			lda	#< TD_SendStatus
			jsr	xTurboRoutine

;*** Diskettenstatus nach READ-Job einlesen.
:GetReadError		lda	#> ErrorCode		;Befehlsbyte über ser. Bus
			sta	$8c			;einlesen.
			lda	#< ErrorCode
			sta	$8b
			jsr	GetErrorData

			lda	ErrorCode
			pha
			tay
			lda	ErrCodes -1,y
			tay
			pla
			cmp	#$02			;$00,$01 = Kein Fehlr ?
			bcc	:51			;Ja, Ende...
			clc
			adc	#30			;Fehlercodes berechnen.
			bne	:52
::51			lda	#$00
::52			tax
			rts

;*** Bytes über ser. Bus / TurboDOS einlesen.
;    Übergabe:		$8b/$8c  , Zeiger auf Bytespeicher.
;			yReg     , Anzahl Bytes (0=256 Byte)
:TurboBytes_GET		jsr	StartTurboMode

:Turbo_FetchNxByt	sec				;Warteschleife bis TurboDOS
::51			lda	$d012			;aktiviert ist.
			sbc	#$32
			and	#$07
			beq	:51

:TurboInitByte_1	lda	#$35
			sta	$dd00
			and	#$0f
			sta	$dd00

			lda	$dd00			;High/Low-Nibble einlesen und
			lsr				;Byte-Wert berechnen.
			lsr
			ora	$dd00
			lsr
			lsr
:TurboInitByte_2	eor	#$05
			eor	$dd00
			lsr
			lsr
:TurboInitByte_3	eor	#$05
			eor	$dd00
			dey
			sta	($8b),y			;Nyte speichern und weiter mit
			bne	Turbo_FetchNxByt	;nächstem Byte.

:StopTurboMode		ldx	#$0f
			stx	$dd00
			rts

;*** Bytes über ser. Bus / TurboDOS senden.
;    Übergabe:		$8b/$8c  , Zeiger auf Bytespeicher.
;			yReg     , Anzahl Bytes (0=256 Byte)
:TurboBytes_SEND	jsr	StartTurboMode		;TurboModus aktivieren.

			tya				;Anzal Bytes in AKKU übertragen und
			pha				;zwischenspeichern.
			ldy	#$00			;Anzahl folgender Bytes an TurboDOS
			jsr	Turbo_SendByte		;in Floppy-RAM senden.
			pla
			tay				;Anzahl Bytes zurücksetzen.

;*** Bytes an Floppy senden.
;    Übergabe:		$8b,$8c = Zeiger auf Daten.
;			yReg    = Anzahl Bytes.
:Turbo_WriteBlock	jsr	StartTurboMode

:Turbo_StashNxByt	dey				;Zeiger auf Daten korrigieren.
			lda	($8b),y			;Byte einlesen.

			ldx	$8e			;TurboDOS-Übertragung starten.
			stx	$dd00

;*** Byte an Floppy senden.
:Turbo_SendByte		tax				;LOW-Nibble für Übertragung
			and	#$0f			;berechnen und speichern.
			sta	$8d

			sec
::51			lda	$d012			;Warteschleife bis TurboDOS
			sbc	#$32			;aktiviert ist.
			and	#$07
			beq	:51

			txa

			ldx	$8f			;Startzeichen an TurboRoutine in
			stx	$dd00			;FloppyRAM übergeben.

			and	#$f0			;HIGH-Nibble für Übertragung
			ora	$8e			;berechnen und Byte senden.
			sta	$dd00
			ror
			ror
			and	#$f0
			ora	$8e
			sta	$dd00

			ldx	$8d			;LOW-Nibble senden.
			lda	NibbleByteH,x
			sta	$dd00
			lda	NibbleByteL,x
			cpy	#$00
			sta	$dd00
			bne	Turbo_StashNxByt
			jmp	StopTurboMode

;*** TurboDOS für CBM/CMD-Floppy initialisieren.
:InitTurboDOS		jsr	TestForCMD_Drive	;Auf CMD-Laufwerk testen.
			txa				;Ergebnis testen.
			beq	InitTurboDOS_CMD	; => CMD FD,HD, weiter...
			bpl	:51			; => Abbruch, Laufwerksfehler.
			bmi	InitTurboDOS_CBM	; => C=1581, weiter...
::51			rts

;*** CMD-FD,HD initialisieren.
:InitTurboDOS_CMD	jsr	InitForIO		;I/O-Bereich einbleden.
			ldx	#> Floppy_GEOS
			lda	#< Floppy_GEOS
			jsr	SendFloppyCom		;GEOS-Modus aktivieren.
			txa				;Laufwerksfehler ?
			bne	:51			;Ja, Abbruch...
			jsr	$ffae
			ldx	#$00			;Flag: "Kein Fehler..."
::51			jmp	DoneWithIO		;I/O-Bereich ausblenden.

:Floppy_GEOS		b "GEOS",NULL

;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS_CBM	jsr	InitForIO		;I/O aktivieren.

			lda	#> TurboDOS_1581	;Zeiger auf TurboDOS-Routine in
			sta	$8e			;C64-Speicher.
			lda	#< TurboDOS_1581
			sta	$8d

			lda	#> $0300		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0300
			sta	Floppy_ADDR_L

			lda	#$0f			;26 * 32 Bytes kopieren.
			sta	$8f

::51			jsr	CopyTurboDOSByt		;TurboDOS-Daten an Floppy senden.
			txa				;Laufwerkfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf C64-Speicher
			lda	#$20			;korrigieren.
			adc	$8d
			sta	$8d
			bcc	:52
			inc	$8e

::52			clc				;Zeiger auf Floppy-Speicher
			lda	#$20			;korrigieren.
			adc	Floppy_ADDR_L
			sta	Floppy_ADDR_L
			bcc	:53
			inc	Floppy_ADDR_H

::53			dec	$8f			;Alle Bytes gesendet ?
			bpl	:51			;Nein, weiter...

::54			jmp	DoneWithIO		;I/O abschalten.

;*** Daten aus TurboDOS-Routine in FloppyRAM kopieren.
:CopyTurboDOSByt	ldx	#> Floppy_MW
			lda	#< Floppy_MW
			jsr	SendFloppyCom		;"M-W"-Befehl an Floppy senden.
			txa				;Laufwerksfehler ?
			bne	:53			;Ja, Abbruch...

			lda	#$20			;Anzahl Bytes an Floppy senden.
			jsr	$ffa8			;(Max. 32 Bytes wegen Puffergröße!)

			ldy	#$00
::51			lda	($8d),y			;Byte einlesen und an Floppy senden.
			jsr	$ffa8
			iny
			cpy	#$20			;Alle Bytes gesendet ?
			bcc	:51			;Nein, weiter...

			jsr	$ffae			;Laufwerk abschalten.
::52			ldx	#$00			;Flag: "Kein Fehler..."
::53			rts

;*** TurboDOS-Routine deaktivieren.
:TurnOffTurboDOS	jsr	InitForIO

			ldx	#> TD_ClearCache
			lda	#< TD_ClearCache
			jsr	xTurboRoutine

			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine

			jsr	StartTurboMode

;*** Aktuelles Laufwerk deaktivieren.
:TurnOffCurDrive	lda	curDrive
			jsr	$ffb1
			lda	#$ef
			jsr	$ff93
			jsr	$ffae

			ldx	#$00
			jmp	DoneWithIO

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

			jsr	xGetBlock_dskBuf	;Aktuellen BorderBlock einlesen.
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

;*** TurboDOS-Routine.
:TurboDOS_1581		d "obj.Turbo81"
