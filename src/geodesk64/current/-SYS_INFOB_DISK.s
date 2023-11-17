; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

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
