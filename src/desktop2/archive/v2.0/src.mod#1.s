; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Source code for DESK TOP V2
;
; Reassembled (w)2020-2023:
;   Markus Kanet
;
; Original authors:
;   Brian Dougherty
;   Doug Fults
;   Jim Defrisco
;   Tony Requist
; (c)1986,1988 Berkeley Softworks
;
; DeskTop GE V2.0 - 11.10.1988 / 17:02
;
; Revision V0.4
; Date: 23/03/25
;
; History:
; V0.1 - Initial reassembled code.
;
; V0.2 - Initial code analysis.
;
; V0.3 - Source code analysis complete.
;
; V0.4 - Added english translation.
;

if .p
			t "TopSym"
;			t "TopMac"
			t "SymTab.rom"
			t "src.DESKTOP.ext"
			t "lang.DESKTOP.ext"
endif

			n "obj.mod#1"
			o vlirModBase

;*** Sprungtabelle.
:vlirJumpTab		jmp	doFilePrint		;File/Print.
			jmp	doFilePrntDnD		;File/Print-DnD.
			jmp	doFileDelete		;File/Delete.
			jmp	doTrashUndel		;Trash/Undelete.
			jmp	doDiskValid		;Disk/Validate.
			jmp	doDiskFormat		;Disk/Format.
			jmp	doCopyFormat		;DiskCopy/Format.
			jmp	doFileUndel		;File/Undelete.
			jmp	doDiskErase		;Disk/Erase.
			jmp	doSwapDirEntry		;Swap Dir-Entry.
			jmp	doSlctAllFiles		;Select/AllFiles.
			jmp	doSlctCurPage		;Select/Page.
			jmp	doSlctBorder		;Select/Border.

;*** Datei über DnD drucken.
:doFilePrntDnD		bit	a2H			;Datei-DnD aktiv?
			bvc	errPrint		; => Nein, Fehler.

;*** Datei/Drucken.
:doFilePrint		jsr	testDiskChanged
			jsr	disableFileDnD

			bit	a2H			;Dateiwahl aktiv?
			bpl	errPrint		; => Nein, Fehler...
			lda	a6L			;Mehr als 1 Datei?
			beq	:1			; => Nein, weiter...
			jmp	doErrMultiFile

::1			jsr	findLastFSlct

			lda	a4L			;Datei auf Disk?
			bne	:2			; => Ja, weiter...
			jsr	doErrFOtherDk
			jmp	unselectJobIcon

::2			lda	a5H			;Zeiger auf Datei-
			sta	r9H			;Eintrag speichern.
			lda	a5L
			sta	r9L

			ldy	#$16
			lda	(r9L),y			;GEOS-Dateityp.
			cmp	#APPL_DATA		;Dokument?
			beq	:3			; => Ja, weiter...

			ldy	#ERR_FILEPRNT
			jsr	openMsgDlgBox
			jmp	unselectJobIcon

::3			lda	#%01000000		;Datenfile drucken.
			jmp	prntFileApplData
:errPrint		rts

;*** Diskette/Validate.
:doDiskValid		lda	diskOpenFlg		;Disk geöffnet?
			beq	errValidate		; => Nein, Fehler...

			jsr	unselectIcons

			jsr	OpenDisk		;Diskette öffnen.
			jsr	exitOnDiskErr

;*** Validate ausführen.
:execValidate		jsr	testDiskMode
			cmp	#Drv1581 +1		;Unbekanntes Format?
			bcs	errValidate		; => Ja, Abbruch...
			sta	dvTypSource		;Laufwerk speichern.

			jsr	jobValidateDisk
			jsr	chkErrRestartDT

			jmp	MainInit		;Zum Hauptmenü.

:errValidate		rts

;*** Diskette/Formatieren.
:doDiskFormat		jsr	unselectIcons

			jsr	get_DrvY_TypeA
			bmi	:exit			; => RAMDisk, Ende.

			jsr	closeCurDisk

			jsr	execFormatDisk
			cpx	#CANCEL_ERR		;Abbruch?
			beq	:exit			; => Ja, Ende..
			txa				;Diskfehler?
			beq	:ok			; => Nein, weiter...

			jsr	openErrBox1Line
::ok			jmp	MainInit		;Zum Hauptmenü.
::exit			rts

;*** Zieldisk für DiskCopy löschen.
:doCopyFormat		jsr	drawEmptyDeskPad

			lda	a2L
			jsr	setNewDevice
			jsr	getIconNumCurDrv
			jsr	clrDeskPadIcon
			jsr	resetDriveData

;*** Diskette formatieren.
:execFormatDisk		lda	curDrive
			clc
			adc	#"A" -8
			sta	dbtxDrvEmptyDk

			lda	#$00
			sta	buf_TempName
			jsr	r5_buf_TempName

			ldx	#> dbox_EnterDkNm
			lda	#< dbox_EnterDkNm
			jsr	openDlgBox		;Name Zieldisk.
			cmp	#CANCEL			;Abbruch?
			beq	:cancel			; => Ja, Ende...

			lda	buf_TempName
			beq	:exit			; => Kein Name.

			jsr	NewDisk			;Disk öffnen.
			txa				;Unformatiert?
			bne	:exec			; => Ja, weiter...

			jsr	GetDirHead		;BAM einlesen.
			txa				;Unformatiert?
			bne	:exec			; => Ja, weiter...

			lda	curDirHead +$bd
			beq	:exec			;Arbeitsdiskette...

			jsr	doErrNotAllowed

::cancel		ldx	#CANCEL_ERR
			rts

::exec			ldy	curDrive
			lda	driveType -8,y
			and	#%00001111
			sta	dvTypTarget
			cmp	#Drv1571
			bne	:setname

			ldx	#> dbox_FrmtDblS
			lda	#< dbox_FrmtDblS
			jsr	openDlgBox		;Doppel-/Einseitig?
			cmp	#CANCEL			;Abbruch?
			beq	:cancel			; => Ja, Ende...
			cmp	#YES			;Doppelseitig?
			beq	:setname		; => Ja, weiter...

			lda	#Drv1541		;Einseitig, nur
			sta	dvTypTarget		;1541-Modus.

::setname		jsr	r0_buf_TempName
			jmp	jobFormatDisk

::exit			rts

;*** Dialogbox: Doppelseitig formatieren?
:dbox_FrmtDblS		b %10000001
			b DBTXTSTR   ,$08,$10
			w dbtxFrmtDbl1
			b DBTXTSTR   ,$08,$20
			w dbtxFrmtDbl2
			b DBTXTSTR   ,$08,$30
			w dbtxFrmtDbl3
			b YES        ,$01,$48
			b NO         ,$09,$48
			b CANCEL     ,$11,$48
			b NULL

;*** Dialogbox: Diskname eingeben.
:dbox_EnterDkNm		b %10000001
			b DBTXTSTR   ,$08,$20
			w dbtxGetEmptyDk
			b DBTXTSTR   ,$08,$30
			w dbtxGetDiskNm
			b DBGETSTRING,$08,$40
			b r5L,16
			b CANCEL     ,$11,$48
			b NULL

;*** Diskette aufräumen.
:jobValidateDisk	lda	#$00
			sta	r5H			;???

			jsr	NewDisk			;Diskete öffnen.
			jsr	exitOnDiskErr

			jsr	GetDirHead		;BAM einlesen.
			jsr	exitOnDiskErr

			jsr	clearCurBAM		;BAM löschen.

			lda	drv1stDirTr		;Verzeichnis belegen.
			sta	r1L
			lda	#$00
			sta	r1H

			jsr	vjobFileSEQ
			jsr	exitOnDiskErr

			lda	dvTypSource
			cmp	#Drv1581		;1581?
			bne	:1			; => Nein, weiter...

			lda	drv1stDirTr		;40/1 und 40/2
			sta	r1L			;belegen.
			lda	#$01
			sta	r1H
			jsr	vjobFileSEQ
			jsr	exitOnDiskErr

::1			jsr	move_border_r1

			lda	r1L			;Borderblock?
			beq	:2			; => Nein, weiter...

			jsr	vjobFileSEQ		;Borderblock belegen.
			jsr	exitOnDiskErr

::2			jsr	cbmBootSek		;CBM-BootSek belegen.
			jsr	exitOnDiskErr

			lda	drv1stDirTr		;Zeiger auf Anfang
			sta	r1L			;Verzeichnis setzen.
			lda	drv1stDirSe
			sta	r1H

;--- Dateien im aktuellen Verzeichnisblock in BAM belegen.
::next			jsr	jobValidDirBlk
			jsr	exitOnDiskErr

			lda	buf_diskSek1 +1
			sta	r1H
			lda	buf_diskSek1 +0
			sta	r1L			;Makro-Madness!

			lda	r1L			;Verzeichnis-Ende?
			bne	:next			; => Nein, weiter...

			jsr	move_border_r1

			lda	r1L			;BorderBlock?
			beq	:3			; => Nein, Ende...

			jsr	jobValidDirBlk
			jsr	exitOnDiskErr

::3			sta	r5H			;???
			jsr	PutDirHead		;BAM speichern.
			rts

;*** Zeiger auf BorderBlock nach r1L/r1H.
:move_border_r1		lda	curDirHead +$ac
			sta	r1H
			lda	curDirHead +$ab
			sta	r1L
			rts

;*** Dateien im aktuellen Verzeichnisblock in BAM belegen.
:jobValidDirBlk		lda	#$00
			sta	r5H			;???

			jsr	r4_bufDiskSek1
			jsr	GetBlock
			jsr	exitOnDiskErr

			lda	#> buf_diskSek1 +2
			sta	r5H
			lda	#< buf_diskSek1 +2
			sta	r5L

			lda	#$08			;Max. 8 Dateien im
			sta	r10L			;Verzeichnis-Block.

			lda	r1H			;Zeiger auf
			pha				;Verzeichnis
			lda	r1L			;zwischenspeichern.
			pha

::loop			jsr	jobValidateFile
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			clc				;Zeiger auf nächste
			lda	#$20			;atei setzen.
			adc	r5L
			sta	r5L
			bcc	:1
			inc	r5H

::1			dec	r10L			;Ende?
			bne	:loop			; => Nein, weter...

			pla				;Zeiger auf
			sta	r1L			;Verzeichnis wieder
			pla				;zurücksetzen.
			sta	r1H

			jsr	r4_bufDiskSek1
			jmp	PutBlock		;Block speichern.

::err			pla				;Dir-Validate
			pla				;abbrechen.
			rts

;*** Dateieintrag validieren.
:jobValidateFile	ldx	#NO_ERROR

			ldy	#$00			;Anzahl Blocks
			sty	r9H			;auf 0 setzen.
			sty	r9L

			lda	(r5L),y			;Datei vorhanden?
			beq	:exit			; => Nein, Ende...
			bmi	:file			; => Datei gültig.

			tya				;Datei ungültig:
			sta	(r5L),y			;Eintrag löschen.
			tax
			beq	:exit			; => Ende...

::file			and	#%00001111
			cmp	#CBMDIR			;CBM-Directory?
			beq	vjobCBMDir		; => Ja, weiter...

			jsr	vjobFileHdr		;VLIR-Datensätze.
			txa				;Diskfehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#$01			;Zeiger auf ersten
			lda	(r5L),y			;Block oder den
			sta	r1L			;VLIR-Header.
			iny
			lda	(r5L),y
			sta	r1H

			jsr	vjobFileSEQ		;Datei/VLIR belegen.
			txa				;Diskfehler?
			bne	:exit			; => Ja, Abbruch...

			ldy	#$13
			lda	(r5L),y			;Infoblock?
			beq	:exit			; => Nein, Ende...
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			jsr	vjobFileSEQ		;InfoBlock belegen.

::exit			cpx	#NO_ERROR
			bne	:err

			ldy	#28			;Dateigröße in
			lda	r9L			;Verzeichnis-Eintrag
			sta	(r5L),y			;übernehmen.
			iny
			lda	r9H
			sta	(r5L),y

::err			rts

;*** CBM-Verzeichnis belegen.
:vjobCBMDir		lda	dvTypSource
			cmp	#Drv1581
			beq	:1

			ldx	#NO_ERROR
			rts

::1			ldy	#$01
			lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sec
			sbc	#$01
			sta	r1H

			ldy	#28
			lda	(r5L),y
			sta	r12L
			iny
			lda	(r5L),y
			sta	r12H

::loop			ldx	#NO_ERROR
			lda	r12H
			ora	r12L
			beq	:exit

			inc	r1H
			lda	r1H
			cmp	#40
			bcc	:2

			lda	#$00
			sta	r1H
			inc	r1L

::2			ldx	#INV_TRACK
			lda	r1L
			beq	:exit
			cmp	#80 +1
			bcs	:exit

			jsr	allocCurBlock

			ldx	#r12L
			jsr	Ddec
			clv
			bvc	:loop

::exit			rts

;*** Datensätze in VLIR-Datei belegen.
:vjobFileHdr		ldx	#NO_ERROR

			ldy	#$15
			lda	(r5L),y
			cmp	#VLIR			;VLIR-Datei?
			bne	:exit			; => Nein, Ende...

			ldy	#$01			;Zeiger auf
			lda	(r5L),y			;VLIR-Header.
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H

			lda	#> fileHeader
			sta	r4H
			lda	#< fileHeader
			sta	r4L

			jsr	GetBlock		;VLIR-Header laden.
			jsr	exitOnDiskErr

			ldy	#$02
::loop			tya
			pha
			lda	fileHeader,y
			sta	r1L
			iny
			lda	fileHeader,y
			sta	r1H

			ldx	#NO_ERROR
			lda	r1L
			beq	:next

			jsr	vjobFileSEQ		;Datensatz belegen.

::next			pla
			tay

			jsr	exitOnDiskErr

			iny				;Nächster Datensatz.
			iny				;Ende?
			bne	:loop			; => Nein, weiter...

::exit			rts

;*** Sequentiellen Datenstream belegen.
:vjobFileSEQ		jsr	EnterTurbo
			txa
			bne	:err

			jsr	InitForIO

::loop			lda	#> diskBlkBuf
			sta	r4H
			lda	#< diskBlkBuf
			sta	r4L

			lda	dvTypSource
			cmp	#Drv1571
			bcc	:is1541

			jsr	ReadLink		;1571/1581.
			clv
			bvc	:test_err

::is1541		jsr	ReadBlock		;1541.
::test_err		txa
			bne	:err

			inc	r9L			;Blockzähler +1.
			bne	:1
			inc	r9H

::1			jsr	allocCurBlock
			txa
			bne	:err

			lda	diskBlkBuf +1
			sta	r1H
			lda	diskBlkBuf +0
			sta	r1L			;Ende Datei?
			bne	:loop			; => Nein, weiter...

			ldx	#NO_ERROR
::err			jmp	DoneWithIO

;*** Speicher für FORMAT-Befehl.
:com_FrmtDisk		s 32

;*** Diskette formatieren.
:jobFormatDisk		ldy	curDrive
			lda	driveType -8,y
			and	#%00001111
			pha
			cmp	#Drv1541
			beq	:1
			bcs	:2

;--- 1541.
::1			lda	#$23			;Kopf auf Track 35
			sta	r1L			;positionieren.
			lda	#$00
			sta	r1H
			jsr	getDiskBlock

;--- 1541/1571/1581.
::2			ldy	#$00			;Format-Befehl
			lda	#"N"			;definieren.
			sta	com_FrmtDisk,y
			iny
			lda	#"0"
			sta	com_FrmtDisk,y
			iny
			lda	#":"			;"N0:"
			sta	com_FrmtDisk,y

			ldy	#$00			;Name an Format-
::name			lda	(r0L),y			;Befehl anhängen.
			sta	com_FrmtDisk +3,y
			beq	:setid
			iny
			bne	:name

::setid			lda	#","			;Format-ID.
			sta	com_FrmtDisk +3,y
			iny

			lda	minutes			;ID1.
			and	#%00001111
			adc	#"A"
			sta	com_FrmtDisk +3,y
			iny
			lda	seconds			;ID2.
			and	#%00001111
			adc	#"A"
			sta	com_FrmtDisk +3,y
			iny

			lda	#$ff			;Ende Floppy-Befehl.
			sta	com_FrmtDisk +3,y

			jsr	PurgeTurbo
			jsr	InitForIO

			pla
			sta	r4L

;;--- 1571: 1S oder 2S?
			cmp	#Drv1571		;1571?
			bne	:3			; => Nein, weiter...

			lda	dvTypTarget		;1S(41) oder 2S(71)?
			clc
			adc	#"0" -1			;0(41) oder 1(71)
			sta	com_DblSideDk +4

			ldy	#> com_DblSideDk
			lda	#< com_DblSideDk
			jsr	sendDrvCom
			txa
			bne	:err

;--- 1541/1571: Kopf positionieren.
::3			lda	r4L
			cmp	#Drv1581
			bcs	:4

			ldy	#> com_SetDrvHead
			lda	#< com_SetDrvHead
			jsr	sendDrvCom		;Kopf positionieren.
			txa
			bne	:err

;--- Diskette formatieren.
::4			ldy	#> com_FrmtDisk
			lda	#< com_FrmtDisk
			jsr	sendDrvCom		;Format senden.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Ende...

			jsr	getDrvStatus

::err			jsr	DoneWithIO
			txa				;Laufwerksfehler?
			bne	:exit			; => Ja, Ende...

			jsr	NewDisk			;Disk öffnen.
			txa				;Laufwerksfehler?
			bne	:exit			; => Ja, Ende...

			jsr	SetGEOSDisk		; => GEOS-Disk.
::exit			rts

;*** 1571: Auf ein- oder doppelseitig umschalten.
:com_DblSideDk		b "U0>M1"
			b $ff				;End-of-Command.

;*** 1541/1571: Kopf positionieren.
:com_SetDrvHead		b "M-W"
			w $0022				;Current track/sector address.
			b $01				;Current track  for drive 0.
			b $00				;Current sector for drive 0.
			b $ff				;End-of-Command.

;Reference: "Serial bus control codes"
;https://codebase64.org/doku.php...
;   ?id=base:how_the_vic_64_serial_bus_works
;
;$20-$3E LISTEN
;device number ($20 + device number #0-30)
;
;$3F     UNLISTEN
;all devices stop listen to data
;
;$40-$5E TALK
;device number ($40 + device number #0-30)
;
;$5F     UNTALK
;all devices stop sending data
;
;$60-$6F REOPEN
;channel ($60 + secondary address / channel #0-15)
;
;$E0-$EF CLOSE
;channel ($E0 + secondary address / channel #0-15)
;
;$F0-$FF OPEN
;channel ($F0 + secondary address / channel #0-15)

;*** Befehl an Laufwerk senden.
:sendDrvCom		sty	r0H
			sta	r0L

			lda	#$00
			sta	STATUS

			lda	curDrive
			jsr	LISTEN			;Laufwerksadresse.

			bit	STATUS			;Laufwerksfehler?
			bmi	:err			; => Ja, Abbruch...

			lda	#$f0 ! 15
			jsr	SECOND			;Befehlskanal.

			bit	STATUS			;Laufwerksfehler?
			bmi	:err			; => Ja, Abbruch...

			ldy	#$00
::1			lda	(r0L),y			;Zeichen einlesen.
			cmp	#$ff			;Ende Floppy-Befehl?
			beq	:2			; => Ja, Ende...
			jsr	CIOUT			;Zeichen auf IEC-Bus.
			iny
			bne	:1			;Nächstes Zeichen.

::2			jsr	UNLSN

			lda	curDrive
			jsr	LISTEN

			lda	#$e0 ! 15
			jsr	SECOND
			jsr	UNLSN

			ldx	#NO_ERROR
			rts

::err			jsr	UNLSN
			ldx	#DEV_NOT_FOUND
			rts

;*** Fehlerstatus von Laufwerk einlesen.
:getDrvStatus		lda	#$00
			sta	STATUS

			lda	curDrive
			jsr	TALK

			bit	STATUS
			bmi	:err

			lda	#$f0 ! 15
			jsr	TKSA

			bit	STATUS
			bmi	:err

			jsr	ACPTR			;High-Nibble.
			and	#%00001111
			asl
			asl
			asl
			asl
			sta	bufDrvErrCode

			jsr	ACPTR			;Low-Nibble.
			and	#%00001111
			ora	bufDrvErrCode
			sta	bufDrvErrCode

			jsr	UNTALK

			lda	curDrive
			jsr	LISTEN

			lda	#$e0 ! 15
			jsr	SECOND
			jsr	UNLSN

			ldx	bufDrvErrCode
			rts

::err			jsr	UNTALK
			ldx	#DEV_NOT_FOUND
			rts

;*** Zwischenspeicher Fehlercode.
:bufDrvErrCode		b NULL

;*** Systemtexte.
if LANG = LANG_DE
:dbtxFrmtDbl1		b BOLDON
			b "Sollen beide Seiten der Diskette"
			b NULL
:dbtxFrmtDbl2		b "formatiert werden?  Vorsicht: "
			b NULL
:dbtxFrmtDbl3		b "Daten auf der Rückseite"
			b GOTOXY
			w $0048
			b $60
			b "gehen hierbei verloren."
			b NULL

:dbtxNoUndel1		b BOLDON
			b "Im Moment keine wiederher-"
			b NULL
:dbtxNoUndel2		b "stellbare Datei vorhanden."
			b PLAINTEXT,NULL

:dbtxFormat1		b BOLDON
			b "Bitte Diskette zum Löschen"
			b NULL
:dbtxFormat2		b "in Laufwerk "
:txFrmtDrvAdr		b $00
			b " einlegen."
			b NULL

:dbtxClrRAMDk		b BOLDON
			b "Inhalt der RAM-Disk löschen?"
			b NULL

:dbtxDelSlcted		b BOLDON
			b "Ausgewählte Dateien löschen?"
			b NULL

:dbtxWrProt1		b BOLDON
			b "Datei schreibgeschützt und"
			b NULL
:dbtxWrProt2		b "nicht löschbar."
			b NULL
endif
if LANG = LANG_EN
:dbtxFrmtDbl1		b BOLDON
			b "Format both sides of disk?  Be"
			b NULL
:dbtxFrmtDbl2		b "careful, as this will destroy any"
			b NULL
:dbtxFrmtDbl3		b "data on the flip side of the disk."
			b NULL

:dbtxNoUndel1		b BOLDON
			b "There is currently no"
			b NULL
:dbtxNoUndel2		b "recoverable file."
			b PLAINTEXT,NULL

:dbtxFormat1		b BOLDON
			b "Please insert disk to erase in"
			b NULL
:dbtxFormat2		b "drive "
:txFrmtDrvAdr		b $00
			b "."
			b NULL

:dbtxClrRAMDk		b BOLDON
			b "Erase contents of RAM disk?"
			b NULL

:dbtxDelSlcted		b BOLDON
			b "Delete selected files?"
			b NULL

:dbtxWrProt1		b BOLDON
			b "is write protected and can't"
			b NULL
:dbtxWrProt2		b "be deleted."
			b NULL
endif

;*** Mausklick auf Trash auswerten.
:doTrashUndel		jsr	testDiskChanged

			bit	a2H			;Datei-DND aktiv?
			bvs	jobDelete		; => Ja, weiter...

;--- Datei wiederherstellen.
			jmp	keybFileUndel

;*** Datei/Löschen.
:doFileDelete		jsr	testDiskChanged

			bit	a2H			;Dateiwahl aktiv?
			bmi	jobDelete		; => Ja, weiter...

			rts

;*** Aktuelle Datei löschen.
:jobDelete		lda	a2H
			and	#%00100000		;Dateiwahl Border?
			bne	:1			; => Ja, weiter...

			lda	curDirHead +$bd
			beq	:1			;Arbeitsdiskette...

			jsr	doErrNotAllowed
			jmp	unselectIcons

::1			lda	a6L			;Mehrfach-Auswahl?
			beq	:2			; => Nein, weiter...

			ldx	#> dbox_FileDelete
			lda	#< dbox_FileDelete
			jsr	openDlgBox		;Dateien löschen?
			cmp	#CANCEL			;Abbruch?
			bne	:2			; => Nein, weiter...

;--- Abbruch, Auswahl aufheben.
			jmp	unselectIcons

;--- Dateien löschen.
::2			ldx	#> batchJobDelete
			lda	#< batchJobDelete
			jmp	execBatchJob

;*** Einzelne Datei löschen.
:batchJobDelete		lda	a3L
			sta	a3H
			jsr	testFileOtherDk

			lda	a3H
			ldx	#ICON_DRVA
			jsr	setVecIcon2File

			ldy	#$00
			lda	(r9L),y
			and	#%01000000
			beq	:2

			jsr	move_r9_r0

			clc				;Zeiger auf
			lda	#$03			;Dateiname.
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H

::1			jsr	getIconTitle

			ldx	#> dbox_FileWrProt
			lda	#< dbox_FileWrProt
			jsr	openDlgBox		;Schreibschutz!
			jmp	unselectJobIcon

::2			ldy	#$00
			lda	(r9L),y
			and	#%00001111
			cmp	#CBMDIR			;CBM-Directory?
			beq	:3			; => Ja, weiter...

			lda	r9H			;Zeiger auf Datei
			pha				;zwischenspeichern.
			lda	r9L
			pha

;--- Zuletzt gelöschte Datei merken.
			lda	#$ff			;Datei im Papierkorb.
			sta	a8H

			lda	r9H			;Aktuelle Datei.
			sta	r4H
			lda	r9L
			sta	r4L

			lda	#> bufLastDelEntry
			sta	r5H
			lda	#< bufLastDelEntry
			sta	r5L

			jsr	doCopyDirEntry

;--- Zuletzt gelöschte Datei anzeigen.
			jsr	clearTrashName

			jsr	move_r9_r0
			jsr	setLastDelFile

			pla				;Zeiger auf Datei
			sta	r9L			;zurücksetzen.
			pla
			sta	r9H
			jsr	FreeFile		;Datei löschen.

::3			lda	a3H			;Eintrag löschen.
			jsr	removeFileEntry

			lda	a3H			;Block speichern.
			jsr	writeDirEntry
			jsr	chkErrRestartDT

			jsr	removeJobIcon
			jmp	testCurDiskReady

;*** Zeiger auf Verzeichnis-Eintrag nach r0 kopieren.
:move_r9_r0		lda	r9H
			sta	r0H
			lda	r9L
			sta	r0L
			rts

;*** Dialogbox: Datei löschen?
:dbox_FileDelete	b %10000001
			b DBTXTSTR   ,$10,$20
			w dbtxDelSlcted
			b OK         ,$01,$48
			b CANCEL     ,$11,$48
			b NULL

;*** Dialogbox: Datei schreibgeschützt.
:dbox_FileWrProt	b %10000001
			b DBTXTSTR   ,$10,$10
			w txString_File
if LANG = LANG_DE
			b DBVARSTR   ,$2e,$10
endif
if LANG = LANG_EN
			b DBVARSTR   ,$42,$10
endif
			b r6L
			b DBTXTSTR   ,$10,$20
			w dbtxWrProt1
			b DBTXTSTR   ,$10,$30
			w dbtxWrProt2
			b OK         ,$11,$48
			b NULL

;*** Datei/Undelete.
:doFileUndel		lda	diskOpenFlg		;Diskette geöffnet?
			beq	:exit			; => Nein, Ende...

			jsr	testCurViewMode
			bcc	:exit			; => Kein Icons...

			jsr	testDiskChanged
			jsr	chkErrReopenDisk
			jsr	unselectIcons

			lda	a8H			;Datei im Papierkorb?
			bne	:1			; => Ja, weiter...

;--- Fehler: Keine gelöschte Datei!
			lda	#> dbtxNoUndel1
			sta	r5H
			lda	#< dbtxNoUndel1
			sta	r5L

			lda	#> dbtxNoUndel2
			sta	r6H
			lda	#< dbtxNoUndel2
			sta	r6L

			jmp	openMsgDBox_r5r6

::1			lda	#$00			;Papierkorb leer.
			sta	a8H

			jsr	clearTrashName

			lda	a0L			;Freien Verzeichnis-
			sta	r10L			;Eintrag suchen.
			jsr	GetFreeDirBlk
			jsr	chkErrRestartDT

;--- Datei wiederherstellen.
			tya
			clc
			adc	#< dirDiskBuf
			sta	r5L
			lda	r10L
			adc	#> dirDiskBuf
			sta	r5H

			lda	#> bufLastDelEntry
			sta	r4H
			lda	#< bufLastDelEntry
			sta	r4L
			jsr	doCopyDirEntry

;--- Datei überprüfen.
			jsr	jobValidateFile

			jsr	PutDirHead		;BAM speichern.
			jsr	chkErrRestartDT

;--- DeskPad aktualisieren.
			lda	r10L			;Aktuelle Seite
			sta	a0L			;Verzeichnis setzen.
			jsr	updDTopViewData
			jmp	reopenCurDisk

;--- Abbruch...
::exit			rts

;*** Diskette/Löschen.
:doDiskErase		jsr	closeCurDisk

			jsr	get_DrvY_TypeA
			bpl	:disk			; => Keine RAM-Disk.

			ldx	#> dbox_ClrRAMDk
			lda	#< dbox_ClrRAMDk
			jsr	openDlgBox		;RAMDisk löschen?
			cmp	#CANCEL			;Abbruch?
			bne	:exec			; => Nein, weiter...

			jmp	openNewDisk		;Diskette öffnen.

;--- Diskette löschen.
::disk			lda	curDrive
			clc
			adc	#"A" -8

			sta	txFrmtDrvAdr
			ldx	#> dbox_Format
			lda	#< dbox_Format
			jsr	openDlgBox		;Diskette löschen?
			cmp	#CANCEL			;Abbruch?
			bne	:exec			; => Nein, weiter...
			rts

;--- Diskette/RAMDisk löschen.
::exec			jsr	OpenDisk		;Diskette öffnen.
			jsr	chkErrRestartDT

			lda	curDirHead +$bd
			beq	:1			;Arbeitsdiskette...

			jmp	doErrNotAllowed

::1			lda	#$00			;Zeiger auf erste
			sta	a0L			;Verzeichnis-Seite.
			jsr	setVecDirBlock

			lda	r0H			;Zeiger auf
			sta	r4H			;Verzeichnis-Block
			lda	r0L			;übertragen.
			sta	r4L

			ldy	#$00
			tya
			sta	(r0L),y			;Link-Zeiger löschen.
			iny
			lda	#$ff
			sta	(r0L),y

;--- Einträge in aktuellem Block löschen.
			jsr	delFilesCurDirB

			jsr	get1stDirTrSe
			sty	r1H

			jsr	PutBlock		;Dir-Block speichern.
			jsr	chkErrRestartDT

;--- Dateien im Borderblock löschen.
			lda	#> buf_diskSek3
			sta	r0H
			lda	#< buf_diskSek3
			sta	r0L
			jsr	delFilesCurDirB

			jsr	updateBorderBlk

;--- Diskette/Validate ausführen.
			lda	#$00			;Keine Dateien im
			sta	a1L			;Speicher.
			jmp	execValidate

;*** Dateien im Verzeichnisblock löschen.
:delFilesCurDirB	clc				;Zeiger auf ersten
			lda	#$02			;Verzeichnis-Eintrag
			adc	r0L			;setzen.
			sta	r0L
			bcc	:1
			inc	r0H

::1			ldy	#0

			ldx	#8 -1			;Max. 8 Einträge.

::2			lda	#NULL			;Dateityp löschen.
			sta	(r0L),y

			clc				;Zeiger auf nächsten
			lda	#$20			;Eintrag setzen.
			adc	r0L
			sta	r0L
			bcc	:3
			inc	r0H

::3			dex				;Einträge gelöscht?
			bpl	:2			; => Nein, weiter...

			rts

;*** Nicht verwendet?
;1541: BAM-Bit für den aktuellen
;      Sektor invertieren.
;Evtl. direkt in ":allocCurBlock"
;übernommen und hier nicht gelöscht?
:l630a			jsr	FindBAMBit
			lda	curDirHead,x
			eor	r8H
			sta	curDirHead,x
			rts

;*** Dialogbox: Diskette formatieren?
:dbox_Format		b %10000001
			b DBTXTSTR   ,$10,$20
			w dbtxFormat1
			b DBTXTSTR   ,$10,$30
			w dbtxFormat2
			b OK         ,$01,$48
			b CANCEL     ,$11,$48
			b NULL

;*** Dialogbox: RAMDisk löschen?
:dbox_ClrRAMDk		b %10000001
			b DBTXTSTR   ,$10,$20
			w dbtxClrRAMDk
			b OK         ,$01,$48
			b CANCEL     ,$11,$48
			b NULL

;*** Icon-Abmessungen für ":IsMseInRegion" setzen.
:getIconCoords		tay

			lda	tabYPosFiles,y
			sta	r2L			;Y-Koordinate oben.
			clc
			adc	#21			;Icon-Höhe.
			sta	r2H			;Y-Koordinate unten.

			lda	tabXPosFiles,y
			sta	r3L
			lda	#$00
			sta	r3H			;X-Koordinate links.

			ldx	#$03
::1			clc				;Warum nicht ASL oder
			rol	r3L			;DShiftLeft ?
			rol	r3H
			dex
			bne	:1

			lda	r3L
			clc
			adc	#24			;Icon-Breite.
			sta	r4L
			lda	r3H
			adc	#$00
			sta	r4H			;X-Koordinate rechts.

			rts

;*** Auf DnD über DeskPad-Icon testen.
;Rückgabe: N-Flag = 1 : Kein DnD.
;                   0 : DnD auf Datei.
:testDnDPadIcon		lda	#8 -1			;Max. 8 Icons...

::1			pha

			jsr	getIconCoords
			jsr	IsMseInRegion
			bne	:2			;Icon gefunden...

			pla
			sec
			sbc	#1			;Alle Icons getestet?
			bpl	:1			; => Nein, weiter...
			rts				;N-Flag = 1.

::2			pla				;Werte von 0-7:
			rts				;N-Flag = 0.

;*** Zwei Verzeichnis-Einträge tauschen.
:doSwapDirEntry		jsr	testDnDPadIcon
			bmi	:exit			;Kein tauschen...

			sta	r4L			;Ziel-Icon/Seite.

			lda	a6L			;Mehrfach-Auswahl?
			bne	:exit			; => Ja, Abbruch...

			lda	r4L			;Datei-DnD auf die
			cmp	a3L			;gleiche Datei?
			beq	:exit			; => Ja, Abbruch...

			jsr	getFTypeGEOS
			cmp	#SYSTEM_BOOT
			bne	:1			;Tauschen möglich...

;--- Fehler: Swap mit SystemBoot nicht möglich.
::err			jmp	doErrStartFile

;--- Dateien tauschen.
::1			lda	r4L
			ldx	#r4L
			jsr	setVecIcon2File

			ldy	#$16
			lda	(r4L),y
			cmp	#SYSTEM_BOOT
			beq	:err			;Fehler, SYSTEM_BOOT!

;--- Quell- und Ziel-Datei tauschen.
			lda	#> tempDirEntry
			sta	r5H
			lda	#< tempDirEntry
			sta	r5L
			jsr	doCopyDirEntry

			lda	r4H
			sta	r5H
			lda	r4L
			sta	r5L

			jsr	move_a5_r4

			jsr	doCopyDirEntry

			lda	#> tempDirEntry
			sta	r4H
			lda	#< tempDirEntry
			sta	r4L

			lda	a5H
			sta	r5H
			lda	a5L
			sta	r5L

			jsr	doCopyDirEntry

;--- PadPage/Border/Icons aktualisieren.
			jsr	updDTopViewData
			txa
			bne	:exit

			jsr	removeJobIcon

;--- DeskPad aktualisieren.
			jsr	prntCurPadPage

			ldx	#NO_ERROR
			rts

::exit			ldx	#$ff
			rts

;*** Alle Dateien auswählen.
:doSlctAllFiles		lda	diskOpenFlg		;Diskette geöffnet?
			beq	:exit			; => Nein, Abbruch...

			jsr	disableFileDnD
			jsr	testCurViewMode
			bcc	:exit			; => Keine Icons...

			lda	#$00			;Erste Seite.
::loop			pha
			jsr	openNewPadPage
			jsr	doSlctCurPage
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

			jsr	chkStopKey		;RUN/STOP?
			bne	:next			; => Nein, weiter...

::err			pla				;Abbruch...
::exit			rts

::next			pla
			clc
			adc	#$01			;Nächste Seite?
			cmp	a1L			;Letzte Seite?
			bcc	:loop
			beq	:loop			; => Nein, weiter...

			bit	a2H			;Dateiwahl aktiv?
			bpl	:1			; => Nein, weiter...

;--- Zur ersten gewählten Datei.
			jmp	keybGo1stSlct

;--- Zur ersten Seite wechseln.
::1			lda	#$00
			jmp	openNewPadPage

;*** Dateien im Border wählen.
:doSlctBorder		lda	#ICON_BORDER
			b $2c

;*** Dateien auf aktueller Seite wählen.
:doSlctCurPage		lda	#ICON_PAD

;--- Dateien auf Seite/Border wählen.
			pha
			jsr	disableFileDnD
			pla
			tay

			lda	diskOpenFlg
			beq	:exit

			jsr	testCurViewMode
			bcc	:exit

			tya
			pha
			clc
			adc	#$07
			sta	poiFileSelect
			pla

::loop			pha
			jsr	isIconGfxInTab
			beq	:next

			pla
			pha
			jsr	isIconInSlctTab
			bne	:next

			sta	r0L
			jsr	slctNewFile

::next			pla
			clc
			adc	#$01
			cmp	poiFileSelect
			bcc	:loop
			beq	:loop

			ldx	#NO_ERROR
::exit			rts

:poiFileSelect		b $00

;Endadresse VLIR-Modul testen:
			g vlirModEnd
