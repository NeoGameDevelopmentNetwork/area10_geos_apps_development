; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Variablen für Status-Box:
:STATUS_X		= $0040
:STATUS_W		= $00c0
:STATUS_Y		= $30
:STATUS_H		= $40

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_Y1		= STATUS_Y +52
:INFO_Y2		= STATUS_Y +26
:INFO_Y3		= STATUS_Y +36

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	sysPrntInfoBox		;Status-Box anzeigen.

			jsr	UseSystemFont		;GEOS-Font für Titel aktivieren.

			LoadW	r0,jobInfTxValid	;"Diskette überprüfen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxFile		;"Datei"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y3
			jsr	PutString

			LoadW	r0,txtStatusOK		;"Status: OK"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jmp	PutString

;*** Status-Box anzeigen.
:sysPrntInfoBox		lda	#$00			;Füllmuster löschen.
			jsr	SetPattern

			jsr	i_Rectangle		;Status-Box zeichnen.
			b	STATUS_Y
			b	(STATUS_Y + STATUS_H) -1
			w	STATUS_X
			w	(STATUS_X + STATUS_W) -1

			lda	#%11111111		;Rahmen für Status-Box.
			jsr	FrameRectangle

;--- Titelzeile.
			lda	C_RegisterBack		;Farbe für Status-Box.
			jsr	DirectColor

			jsr	i_Rectangle		;Titelzeile löschen.
			b	STATUS_Y
			b	STATUS_Y +15
			w	STATUS_X
			w	(STATUS_X + STATUS_W) -1

			lda	C_DBoxTitel		;Farbe für Titelzeile setzen.
			jsr	DirectColor

			jmp	ResetFontGD		;GD-Font aktivieren.

;*** Aktuelle Datei ausgeben.
;Hinweis:
;r5 darf nicht verändert werden.
:prntStatus		jsr	DoneWithIO		;GEOS-Kernal einblenden.

			lda	r5L			;Zeiger auf Dateiname.
			pha
			clc
			adc	#$03
			sta	r8L
			lda	r5H
			pha
			adc	#$00
			sta	r8H

			LoadW	r0,curFileName		;Zeiger auf Speicher für Dateiname.

			ldx	#r8L
			ldy	#r0L
			jsr	SysCopyName		;Dateiname kopieren.

			lda	#$00			;Anzeigebereich löschen.
			jsr	SetPattern

			jsr	i_Rectangle
			b	INFO_Y3 -6
			b	INFO_Y3 +1
			w	INFO_X0
			w	(STATUS_X + STATUS_W) -8

			LoadW	r0,curFileName
			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y3
			jsr	smallPutString		;Dateiname anzeigen.

			PopB	r5H			;Zeiger auf Verzeichnis-Eintrag
			PopB	r5L			;wieder zurücksetzen.

			jmp	InitForIO		;Disk I/O wieder aktivieren.

;*** Disk-/Verzeichnisname ausgeben.
:prntDiskInfo		jsr	clrDiskInfo		;Anzeigebereich Diskname löschen.

			ldx	curDrive		;Aktuelles Laufwerk einlesen.
			lda	RealDrvMode -8,x	;Laufwersmodus einlesen.

			ldx	#<infoTxDisk		;"Diskette"
			ldy	#>infoTxDisk

			and	#SET_MODE_SUBDIR	;Native-Mode-Laufwerk?
			beq	:2			; => Nein, weiter...

			lda	curDirHead +32		;ROOT-Verzeichnis?
			ora	curDirHead +33
			cmp	#$01
			beq	:2			; => Ja, weiter...

			ldx	#<infoTxDir		;"Verzeichnis"
			ldy	#>infoTxDir

::2			stx	r0L
			sty	r0H
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y2
			jsr	PutString

			ldx	#r1L			;Zeiger auf Diskname setzen.
			jsr	GetPtrCurDkNm

			LoadW	r0,curDiskName		;Diskname in Zwischenspeicher
			ldx	#r1L			;kopieren.
			ldy	#r0L
			jsr	SysCopyName

			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y2
			LoadW	r0,curDiskName
			jmp	smallPutString		;Disk-/Verzeichnisname ausgeben.

;*** Anzeigebereich Diskname löschen.
:clrDiskInfo		lda	#$00
			jsr	SetPattern

			jsr	i_Rectangle
			b	INFO_Y2 -6
			b	INFO_Y2 +1
			w	STATUS_X +8
			w	(STATUS_X + STATUS_W) -8
			rts

;*** Texte.
if LANG = LANG_DE
:jobInfTxValid		b PLAINTEXT,BOLDON
			b "LAUFWERK ÜBERPRÜFEN"
			b PLAINTEXT,NULL

:infoTxFile		b "Datei: ",NULL
:infoTxDir		b "Verzeichnis: ",NULL
:infoTxDisk		b "Diskette: ",NULL
endif
if LANG = LANG_EN
:jobInfTxValid		b PLAINTEXT,BOLDON
			b "VALIDATE DRIVE"
			b PLAINTEXT,NULL

:infoTxFile		b "Filename: ",NULL
:infoTxDir		b "Directory: ",NULL
:infoTxDisk		b "Disk: ",NULL
endif

:curDiskName		s 17
