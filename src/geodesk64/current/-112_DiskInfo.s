; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Disk-Info einlesen.
; Info:
; - Laufwerkstyp
; - Disketten-Name
; - GEOS-Disk
; - Gesamt/Freier Speicher
; Statistik:
; - Anzahl Dateien/Verzeichnisse
; - Anzahl Schreibgeschütze Dateien
; - Anzahl Nicht-GEOS/GEOS-Dateien
:doGetDiskInfo		ldx	WM_WCODE		;Fenster-Nummer einlesen.
			ldy	WIN_DRIVE,x		;Laufwerks-Adresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerks-Modus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Verzeichnis?
			beq	:1a			; => Nein, weiter...
			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			txa				;Fehler?
			beq	:1b			; => Nein weiter...
::0			rts				;Ende.

::1a			jsr	OpenDisk		;Diskette öffnen?
			txa				;Fehler.
			bne	:0			; => Ja, Ende...

::1b			lda	curDirHead +162		;Aktuelle Disk-ID einlesen.
			sta	targetDrvDkID +0
			lda	curDirHead +163
			sta	targetDrvDkID +1

			lda	curType
			and	#%00000111
			cmp	#Drv1581		;1581-kompatibles Laufwerk ?
			bne	:1c			; => Nein, weiter...

			jsr	test1581DOS		;DOS-Kennung testen.

::1c			jsr	setStatusIcon		;Status-Icon für Laufwerk setzen.

			ldx	WM_WCODE		;Fenster-Nummer einlesen.
			ldy	WIN_DRIVE,x		;Laufwerks-Adresse einlesen.
			jsr	doGetDevType		;Zeiger auf Laufwerkstyp einlesen.

			LoadW	r1,targetDrvType	;Zeiger auf Zwischenspeicher.

			ldx	#r0L			;Laufwerkstyp in Zwischenspeicher
			ldy	#r1L			;kopieren.
			jsr	SysCopyName

			ldx	#r0L			;Zeiger auf Disk-Name setzen.
			jsr	GetPtrCurDkNm

			LoadW	r1,targetDrvDisk

			ldx	#r0L			;Disk-Name in Zwischenspeicher
			ldy	#r1L			;kopieren.
			jsr	SysCopyName

			lda	isGEOS			;Status "GEOS-Diskette" kopieren.
			sta	geosDiskFlg
			bne	:2

			tax
			beq	:3

::2			lda	curDirHead +171
			ldx	curDirHead +172

::3			sta	adrBorderBlock +0
			stx	adrBorderBlock +1

			jsr	getMaxTracks		;Max. Anzahl Tracks einlesen.

			jsr	getDiskFileInfo		;Datei-Statistiken einlesen.
;			txa				;Fehler?
;			bne	:4			; => Ja, Ende...

;			ldx	#NO_ERROR		; => Kein Fehler...
::4			rts				;Ende.

;*** Datei-Statistiken einlesen.
:getDiskFileInfo	jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			beq	:testEndOfDir		; => Ja, weiter...

;--- Verzeichnis-Eintrag auswerten.
::loop			ldy	#$00
			lda	(r5L),y			;Dateityp einlesen.
			and	#FTYPE_MODES		;"Gelöscht"?
			beq	:next_file		; => Ja, nächste Datei...

			ldy	#30 -1			;Verzeichnis-Eintrag in
::1			lda	(r5L),y			;Zwischenspeicher kopieren.
			sta	dirEntryBuf,y
			dey
			bpl	:1

			jsr	getFileStats		;Daten auswerten.

			ldx	WM_WCODE		;Fenster-Nummer einlesen.
			ldy	WIN_DRIVE,x		;Laufwerks-Adresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerks-Modus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Verzeichnis?
			beq	:next_file		; => Nein, nächste Datei.

			lda	dirEntryBuf
			and	#FTYPE_MODES		;Dateityp einlesen.
			cmp	#FTYPE_DIR		;Verzeichnis?
			bne	:next_file		; => Nein, nächste Datei.

;--- Unterverzeichnis öffnen.
			lda	dirEntryBuf +1		;Tr/Se auf Verzeichnis-Header
			sta	r1L			;einlesen.
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			beq	getDiskFileInfo		; => Nein, weiter...
::error			rts				;Fehler, Abbruch.

;--- Weiter mit nächsten Eintrag.
::next_file		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:loop			; => Nein, weiter...

;--- Ende ROOT-Verzeichnis erreicht?
::testEndOfDir		ldx	WM_WCODE		;Fenster-Nummer einlesen.
			ldy	WIN_DRIVE,x		;Laufwerks-Adresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerks-Modus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Verzeichnis?
			beq	:exit			; => Nein, Ende...

			lda	curDirHead +32		;Aktuelles Verzeichnis gleich
			cmp	#$01			;ROOT-Verzeichnis?
			bne	:2
			lda	curDirHead +33
			cmp	#$01
			beq	:exit			; => Ja, Ende...

::2			lda	curDirHead +36		;Zeiger auf Tr/Se im Verzeichnis-
			sta	r1L			;Eintrag Elternverzeichnis setzen.
			lda	curDirHead +37
			sta	r1H

			lda	curDirHead +38		;Zeiger auf Byte für Verzeichnis-
			sta	r5L			;Eintrag in Sektor setzen.
			lda	#>diskBlkBuf
			sta	r5H

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			lda	curDirHead +34		;Zurück zum vorherigen
			sta	r1L			;Verzeichnis.
			lda	curDirHead +35
			sta	r1H
			jsr	OpenSubDir

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag
			PopB	r1H			;zurücksetzen.
			PopB	r1L

			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Verzeichnis-Ende erreicht.
::exitDirectory		jmp	:next_file		; => Weiter im Unterverzeichnis.

;--- Verzeichnis bearbeitet.
::exit			ldx	#NO_ERROR
			rts				;Ende.

;*** Verzeichnis-Eintrag auswerten.
; Statistik:
; - Anzahl Dateien/Verzeichnisse
; - Anzahl Schreibgeschütze Dateien
; - Anzahl Nicht-GEOS/GEOS-Dateien
:getFileStats		lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			and	#%0100 0000		;Schreibschutz aktiv?
			beq	:1			; => Nein, weiter...

			IncW	countWrProt		;Zähler Schreibschutz +1.

::1			lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			and	#FTYPE_MODES		;Dateityp-Bits isolieren.
			cmp	#FTYPE_DIR		;Verzeichnis?
			bne	:2			; => Nein, weiter...

			IncW	countDir		;Zähler Verzeichnisse +1.
			rts

::2			IncW	countFiles		;Zähler Dateien +1.

			lda	dirEntryBuf +22		;GEOS-Dateityp einlesen.
			bne	:3			; => GEOS-Datei, weiter...

			IncW	countBASIC		;Zähler BASIC-Dateien +1.
			jmp	:4			; => Weiter...

::3			IncW	countGEOS		;Zähler GEOS-Dateien +1.

::4			rts				;Ende.

;*** Speichernutzung ausgeben.
;
;Größe für Balken/Speichernutzung:
:minBarX = R1SizeX0 +$20
:maxBarX = R1SizeX1 -$28
;
:prntDiskFree		jsr	OpenDisk		;Diskette für CalcBlksFree öffnen.
			txa				;Fehler?
			bne	:err			; => Ja, Ende...

;--- Hinweis:
;OpenDisk ist hier erforderlich um
;sicherzustellen das BAM im Speicher
;aktuell ist. Sonst liefert die
;Routine CalcBlksFree falsche Werte.
			LoadW	r5,curDirHead		;Zeiger auf aktuelle BAM.
			jsr	CalcBlksFree		;Anzahl freie Blocks berechnen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::err			rts

::1			lda	r3L			;Anzahl belegte Blocks
			sec				;berechnen.
			sbc	r4L
			sta	r5L
			lda	r3H
			sbc	r4H
			sta	r5H

			PushW	r4			;Anzahl belegte Blocks/Gesamt für
			PushW	r3			;Ausgabe KBytes zwischenspeichern.

			PushW	r4			;Anzahl belegte Blocks/Gesamt für
			PushW	r3			;Ausgabe Blocks zwischenspeichern.

			CmpW	r3,r4			;Anzahl Frei = Gesamt?
			bne	:2			; => Nein, weiter...
			jmp	prntSekInfo		;Disk leer, nur Werte ausgeben.

;--- Speicherübersicht ausgeben.
::2			lda	r4L			;Disk voll?
			ora	r4H
			bne	:3			; => Nein, weiter...

			sta	r8L			;Rest-Wert Infobalken löschen für
			sta	r8H			;"Ganzen Balken füllen".
			beq	:4			;Infobalken darstellen.

;--- Prozentwert für Infobalken berechnen.
::3			LoadW	r6,(maxBarX-minBarX)
			ldx	#r3L
			ldy	#r6L
			jsr	Ddiv			;Gesamt/Breite_Balken.

			PushW	r8			;Restwert sichern.

			ldx	#r5L
			ldy	#r3L
			jsr	Ddiv			;Belegt/(Gesamt/Breite_Balken)

			PopW	r8			;Restwert zurücksetzen.

			lda	r5L			;Prozentwert = 0?
			ora	r5H
			beq	prntSekInfo		; => Ja, Nur Gesamt/Frei ausgeben.

			lda	r5L			;Ende Füllwert für Infobalken
			clc				;berechnen.
			adc	#< minBarX
			sta	r4L
			lda	r5H
			adc	#> minBarX
			sta	r4H

			CmpWI	r4,maxBarX		;Füllwert > Breite_Balken?
			bcc	:5			; => Nein, weiter...

::4			LoadW	r4,maxBarX		;Max. Breite Füllwert setzen.

::5			CmpWI	r4,minBarX		;Rechter Rand = Linker Rand ?
			beq	prntSekInfo		; => Ja, keinen Balken anzeigen.

			LoadB	r2L,RPos1_y +RLine1_4
			LoadB	r2H,RPos1_y +RLine1_4 +$07
			LoadW	r3,minBarX

			lda	#$02			;Füllmuster setzen.
			jsr	SetPattern

			jsr	Rectangle		;Infobalken füllen.

;--- Gsamt/Freier Speicher ausgeben.
:prntSekInfo		PopW	r0			;Max. Blocks.
			LoadB	r1H,RPos1_y +RLine1_4 +$08 +$08
			LoadW	r11,R1SizeX0 +$2c
			jsr	:doBlocks

			PopW	r0			;Freie Blocks.
			LoadW	r11,R1SizeX0 +$60 +$38
			jsr	:doBlocks

			PopW	r0			;Max. KByte.
			LoadB	r1H,RPos1_y +RLine1_4 +$08 +$12
			LoadW	r11,R1SizeX0 +$2c
			jsr	:doKByte

			LoadW	r0,textSpacer
			jsr	PutString

			lda	maxTrack
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal		;Zahl ausgeben.

			LoadW	r0,textTR
			jsr	PutString

			PopW	r0			;Freie KByte.
			LoadW	r11,R1SizeX0 +$60 +$38
			jmp	:doKByte

;--- Zahl "0 Blks" ausgeben.
::doBlocks		lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal		;Zahl ausgeben.

			LoadW	r0,textBlks		;Text "Blks" ausgeben.
			jmp	PutString

;--- Zahl "0 Kb" ausgeben.
::doKByte		ldx	#r0L			;Blocks in KByte umrechnen.
			ldy	#$02
			jsr	DShiftRight

			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal		;Zahl ausgeben.

			LoadW	r0,textKB		;Text "KByte" ausgeben.
			jmp	PutString

;*** Flag setzen "Disk aktualisieren".
;
;Wird durch das Registermenü gesetzt
;wenn Disk-Name oder Status GEOS-Disk
;geändert wird.
;
:setReloadDir		lda	#$ff
			sta	reloadDir
			rts

;*** Diskette aktualiseren.
:UpdateDisk		ldx	WM_WCODE		;Fenster-Nummer einlesen.
			ldy	WIN_DRIVE,x		;Laufwerks-Adresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerks-Modus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Verzeichnis?
			beq	:1a			; => Nein, weiter...
			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			txa				;Fehler?
			beq	:1b			; => Nein weiter...
::0			rts				;Ende.

::1a			jsr	OpenDisk		;Diskette öffnen?
			txa				;Fehler.
			bne	:0			;; => Ja, Ende...

::1b			jsr	saveDiskName		;Disk-name in BAM übertragen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	idUpdateFlg		;Disk-ID aktualisieren ?
			bpl	:1c			; => Nein, weiter...
			jsr	saveDiskID		;Disk-ID/DOS-Kennung aktualisieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

::1c			lda	geosDiskFlg		;GEOS-Disk-Status geändert?
			cmp	isGEOS
			beq	:exit			; => Nein, Ende..

::updateGEOS		tax				;GEOS-Disk erstellen?
			bne	:makeGEOS		; => Ja, weiter...

::clrGEOS		jmp	delGEOSHdr		;GEOS-Disk löschen.

::makeGEOS		jmp	SetGEOSDisk		;GEOS-Disk erzeugen.

::exit			rts				;Ende.

;*** BorderBlock: GEOS-Header löschen.
:delGEOSHdr		ldy	#173			;GEOS-Disk-Kennung löschen.
::1			sta	curDirHead,y
			iny
			cpy	#188 +1
			bcc	:1

			ldx	curDirHead +171		;Border-Block vorhanden?
			beq	:2			; => Nein, weiter...
			stx	r1L
			lda	curDirHead +172
			sta	r1H
			LoadW	r4,borderBlock
			jsr	GetBlock		;Border-Block einlesen.
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...

			jsr	delBorderFiles		;Dateien im BorderBlock löschen.
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...

			lda	curDirHead +171
			sta	r6L
			lda	curDirHead +172
			sta	r6H
			jsr	FreeBlock		;BorderBlock freigeben.
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...

::2			jmp	PutDirHead		;BAM speichern.

::3			rts				;Abbruch...

;*** BorderBlock: Dateien löschen.
:delBorderFiles		ldy	#2
::1			lda	borderBlock,y
			beq	:2

			tya				;Datei-Zeiger zwischenspeichern.
			pha

			clc				;Zeiger auf Verzeichnis-Eintrag
			adc	#<borderBlock		;berechnen.
			sta	r9L
			lda	#$00
			adc	#>borderBlock
			sta	r9H
			jsr	FreeFile		;Datei löschen.

			pla				;Datei-Zeiger zurücksetzen.
			tay

			cpx	#NO_ERROR		;Fehler?
			bne	:3			; => Ja, Abbruch...

::2			tya
			clc
			adc	#32			;Zeiger auf nächste Datei.
			tay				;Letzte Datei?
			bcc	:1			; => Nein, weiter...

::3			rts				;Ende.

;*** Disk-ID geändert.
:chkDiskID		bit	r1L
			bpl	:exit

			jsr	setReloadDir		;Verzeichnis neu laden.

;			lda	#$ff
			sta	idUpdateFlg		;Disk-ID aktualisieren.
			sta	dosReadyFlg		;DOS-Kennung ungültig.

			jsr	setStatusIcon		;Status-Icon für Laufwerk setzen.

			LoadW	r15,RTabMenu1_1c	;Status-Icon aktualisieren.
			jsr	RegisterUpdate

::exit			rts

;*** Disk-ID aktualisieren.
:saveDiskID		jsr	GetDirHead		;Aktuelle BAM einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	targetDrvDkID +0	;Disk-ID aktualisieren.
			sta	curDirHead +162
			lda	targetDrvDkID +1
			sta	curDirHead +163

			jsr	PutDirHead		;BAM auf Disk speichern.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	curType
			and	#%00000111
			cmp	#Drv1581		;1581-kompatibles Laufwerk ?
			bne	:exit			; => Nein, weiter...

			jsr	write1581DOS		;DOS-Kennung auf Disk ändern.
;			txa				;Fehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;*** Status-Icon setzen/löschen.
:setStatusIcon		ldx	#< IconOff		;Bei 1541/71/Native kein
			ldy	#> IconOff		;Status-Icon anzeigen.
			lda	dosReadyFlg		;Laufwerk gültig ?
			beq	:set			; => Nein, weiter...
			bmi	:bad			; => Status auf "BAD" setzen.

::ok			ldx	#< IconStatus		;Status: OK
			ldy	#> IconStatus
			bne	:set

::bad			ldx	#< IconWarn		;Status: BAD
			ldy	#> IconWarn

::set			stx	RIcon_Status +0		;Status-Icon speichern.
			sty	RIcon_Status +1
			rts

;*** DOS-Status auf Diskette testen.
:test1581DOS		jsr	getBlockBAM1		;BAM-Block 40/0 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	testBlockBAM1		;DOS-Kennung testen.
			txa				;Gültig ?
			bne	:DOS_BAD		; => Nein, Status = "BAD".

			jsr	getBlockBAM2		;BAM-Block 40/1 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	testBlockBAM2		;DOS-Kennung testen.
			txa				;Gültig ?
			bne	:DOS_BAD		; => Nein, Status = "BAD".

			jsr	getBlockBAM3		;BAM-Block 40/2 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	testBlockBAM2		;DOS-Kennung testen.
			txa				;Gültig ?
			bne	:DOS_BAD		; => Nein, Status = "BAD".

::DOS_OK		lda	#$7f			;Status: OK
			b $2c
::DOS_BAD		lda	#$ff			;Status: BAD
			sta	dosReadyFlg		;Status speichern.
::exit			rts

;*** DOS-Status auf Diskette reparieren.
:repair1581DOS		bit	r1L			;Aufbau Registermenü ?
			bpl	:exit			; => Ja, Ende...
			bit	dosReadyFlg		;DOS-Status "BAD" ?
			bpl	:exit			; => Nein, Ende...

			jsr	setReloadDir		;Verzeichnis neu laden.

			jsr	write1581DOS		;DOS-Kennung auf Disk ändern.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	#$7f			;DOS-Kennung gültig.
			sta	dosReadyFlg
			lda	#$00			;Disk-ID ist aktuell.
			sta	idUpdateFlg
			jsr	setStatusIcon		;Status-Icon für Laufwerk setzen.

			LoadW	r15,RTabMenu1_1c	;Status-Icon aktualisieren.
			jsr	RegisterUpdate

			LoadW	r0,Dlg_UpdateDOS	;Dialogbox anzeigen:
			jsr	DoDlgBox		;"Reparatur erfolgreich!"

::exit			rts

;*** Neue DOS-Kennung speichern.
:write1581DOS		jsr	getBlockBAM1		;BAM-Block 40/0 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	fixBlockBAM1		;DOS-Kennung schreiben.
			jsr	PutBlock		;BAM-Block speichern.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	getBlockBAM2		;BAM-Block 40/1 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	fixBlockBAM2		;DOS-Kennung schreiben.
			jsr	PutBlock		;BAM-Block speichern.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	getBlockBAM3		;BAM-Block 40/2 einlesen.
			txa				;Fehler ?
			bne	:exit			; => Ja, Abbruch...

			jsr	fixBlockBAM2		;DOS-Kennung schreiben.
			jsr	PutBlock		;BAM-Block speichern.
;			txa				;Fehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts

;*** BAM-Block einlesen.
:getBlockBAM1		lda	#0			;BAM-Block #40/0.
			b $2c
:getBlockBAM2		lda	#1			;BAM-Block #40/1.
			b $2c
:getBlockBAM3		lda	#2			;BAM-Block #40/2.
			sta	r1H
			LoadB	r1L,40
			LoadW	r4,diskBlkBuf
			jmp	GetBlock		;BAM-Block einlesen.

;*** BAM-Block 40/0 testen.
;Byte $02 = "D"
;     $03 = $00
;     $19 = "3" -> Achtung! Unter GEOS ab Byte $A5!
;     $1A = "D" -> Achtung! Unter GEOS ab Byte $A6!
:testBlockBAM1		lda	diskBlkBuf +2
			cmp	#"D"
			bne	:failed
			lda	diskBlkBuf +3
			cmp	#NULL
			bne	:failed
			lda	diskBlkBuf +25 +140
			cmp	#"3"
			bne	:failed
			lda	diskBlkBuf +26 +140
			cmp	#"D"
			bne	:failed

::ok			ldx	#NO_ERROR
			b $2c
::failed		ldx	#BAD_BAM
			rts

;*** BAM-Block 40/1 und 40/2 testen.
;Byte $02 = "D"
;     $03 = "B"       -> "D" EOR %11111111
;     $04 = ID1
;     $05 = ID2
;     $06 = %11000000 -> I/O-Byte (Verify ON, check header CRC ON)
;     $07 = %00000000 -> AutoLoad (OFF)
;     $08-$0F = Unused
:testBlockBAM2		lda	diskBlkBuf +2
			cmp	#"D"
			bne	:failed
			eor	#%11111111
			cmp	diskBlkBuf +3
			bne	:failed
			lda	diskBlkBuf +4
			cmp	targetDrvDkID +0
			bne	:failed
			lda	diskBlkBuf +5
			cmp	targetDrvDkID +1
			bne	:failed

			lda	diskBlkBuf +6
			cmp	#%11000000		;Verify + Check Header = ON.
			bne	:failed
			lda	diskBlkBuf +7
			cmp	#%00000000		;AutoLoad = OFF.
			bne	:failed

			ldy	#8
::1			lda	diskBlkBuf,y
			bne	:failed
			iny
			cpy	#16
			bcc	:1

::ok			ldx	#NO_ERROR
			b $2c
::failed		ldx	#BAD_BAM
			rts

;*** BAM-Block 40/0 reparieren.
;Byte $02 = "D"
;     $03 = $00
;     $16 = ID1 -> Achtung! Unter GEOS ab Byte $A2!
;     $17 = ID2 -> Achtung! Unter GEOS ab Byte $A3!
;     $19 = "3" -> Achtung! Unter GEOS ab Byte $A5!
;     $1A = "D" -> Achtung! Unter GEOS ab Byte $A6!
:fixBlockBAM1		lda	#"D"
			sta	diskBlkBuf +2
			lda	#NULL
			sta	diskBlkBuf +3
			lda	#"3"
			sta	diskBlkBuf +25 +140
			lda	#"D"
			sta	diskBlkBuf +26 +140

			lda	targetDrvDkID +0
			sta	diskBlkBuf +22 +140
			lda	targetDrvDkID +1
			sta	diskBlkBuf +23 +140

			lda	#NULL
			ldy	#$04
::1			sta	diskBlkBuf,y
			iny
			cpy	#$90
			bcc	:1

;			lda	#NULL
			ldy	#$bd			;$AB-$AC = GEOS-Info.
::2			sta	diskBlkBuf,y
			iny
;			cpy	#$ff +1
			bne	:2

			rts

;*** BAM-Block 40/1 und 40/2 reparieren.
;Byte $02 = "D"
;     $03 = "B"       -> "D" EOR %11111111
;     $04 = ID1
;     $05 = ID2
;     $06 = %11000000 -> I/O-Byte (Verify ON, check header CRC ON)
;     $07 = %00000000 -> AutoLoad (OFF)
;     $08-$0F = Unused
:fixBlockBAM2		lda	#"D"
			sta	diskBlkBuf +2
			eor	#%11111111
			sta	diskBlkBuf +3
			lda	targetDrvDkID +0
			sta	diskBlkBuf +4
			lda	targetDrvDkID +1
			sta	diskBlkBuf +5

			lda	#%11000000		;Verify + Check Header = ON.
			sta	diskBlkBuf +6
			lda	#%00000000		;AutoLoad = OFF.
			sta	diskBlkBuf +7

;			lda	#NULL			;Ungenutzte Datenbytes löschen.
			ldy	#$08
::1			sta	diskBlkBuf,y
			iny
			cpy	#$10
			bne	:1

			rts

;*** Variablen.
:countFiles		w $0000
:countDir		w $0000
:countBASIC		w $0000
:countGEOS		w $0000
:countWrProt		w $0000

:adrBorderBlock		b $00,$00

:targetDrvType		s 17
:targetDrvDisk		s 17
:targetDrvDkID		s 3

:idUpdateFlg		b $00
:dosReadyFlg		b $00
:geosDiskFlg		b $00

:textBlks		b " Blks",NULL
:textKB			b " Kb",NULL
:textSpacer		b " / ",NULL
:textTR			b " Tr",NULL

;*** GEOS-Header-Kennung.
:textHeader		b "GEOS format V1.0"

;*** Dialogboxen.
:Dlg_UpdateDOS		b %01100001
			b $30,$87
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b OK         ,$11,$40
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "DOS-Kennung auf der Diskette",NULL
::3			b "oder Partition wurde repariert!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "DOS version type on diskette",NULL
::3			b "or partition has been repaired!",NULL
endif

;*** Reservierter Speicher.
;Hinweis:
;Der reservierte Speicher ist nicht
;initialisiert!

;--- Zwischenspeicher für Borderblock.
;borderBlock		s 256
