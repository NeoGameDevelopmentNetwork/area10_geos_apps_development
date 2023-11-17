; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Nicht verwendet?
:l2580			lda	r5H
			beq	openErrBox1Line

;*** Fehlermeldung mit Dateiname.
:openErrBox_File	txa
			pha

			lda	r5L			;Zeiger auf
			clc				;Dateiname in
			adc	#$03			;Verzeichniseintrag.
			sta	r5L
			bcc	:1
			inc	r5H

::1			ldx	#r5L			;NULL-Byte setzen.
			ldy	#r5L
			jsr	copyNameA0_16

			pla
			tax
			clv
			bvc	openErrBox

;*** Fehlermeldung mit nur einer Zeile.
.openErrBox1Line	lda	#> dbtx_EmptyLine
			sta	r5H
			lda	#< dbtx_EmptyLine
			sta	r5L

;*** Fehlermeldung ausgeben.
:openErrBox		lda	#$00			;Papierkorb leer.
			sta	a8H

;--- Kein Fehler?
			cpx	#$ff
			beq	:no_error

;--- Abbruch-Fehler?
			cpx	#CANCEL_ERR
			beq	:no_error

			txa
			beq	:no_error

			jsr	makeDiskErrMsg
			txa
			sta	tabErrCodesOther

			ldy	#$00
::1			cmp	tabErrCodes,y
			beq	:2
			iny
			iny
			iny
			bne	:1

::2			lda	tabErrCodes +1,y
			sta	r6L
			lda	tabErrCodes +2,y
			sta	r6H
			ldx	#> dbox_ErrorMsg
			lda	#< dbox_ErrorMsg
			jsr	openDlgBox

::no_error		ldx	#NO_ERROR
			rts

;*** Dialogbox: Diskfehler.
:dbox_ErrorMsg		b %10000001
			b DBTXTSTR,$0c,$16
			w dbtxCancelErr
			b DBTXTSTR,$0c,$26
			w dbtxDiskFullErr
			b DBVARSTR,$0c,$36
			b r6L
			b DBVARSTR,$0c,$46
			b r5L
			b OK,$11,$48
:dbtx_EmptyLine		b NULL

;*** Text für Diskfehler erzeugen.
:makeDiskErrMsg		txa
			ldy	#$02
			jsr	:addASCII

			lda	curDrive
			clc
			adc	#"A" -8
			sta	txErrDrvAdr

			lda	r1L
			ldy	#txErrAdrTr - txErrInit
			jsr	:addASCII

			lda	r1H
			ldy	#txErrAdrSe - txErrInit
::addASCII		pha
			jsr	convHex2ASCII_H
			sta	txErrInit +0,y
			pla
			jsr	convHex2ASCII_L
			sta	txErrInit +1,y
			rts

;*** Hexadezimal nach ASCII wandeln.
:convHex2ASCII_H	lsr				;High-Nibble.
			lsr
			lsr
			lsr
:convHex2ASCII_L	and	#%00001111		;Low-Nibble.
			ora	#"0"
			cmp	#"9" +1
			bcc	:1
			clc
			adc	#$07
::1			rts

;*** Diskettenfehler.
:txErrInit		b "I:"

:txErrDrive		b "23  "
			b PLAINTEXT
if LANG = LANG_DE
			b "Lfwk. "
endif
if LANG = LANG_EN
			b "Drive "
endif
:txErrDrvAdr		b "A"
			b " track "
:txErrAdrTr		b "02"
			b " sector "
:txErrAdrSe		b "06"
			b " (hex)"
			b NULL

;*** Liste mit Fehlercodes.
:tabErrCodes		b INSUFF_SPACE			;Fehler: $03
			w dbtxErrDiskFull		;Disk full.
			b FULL_DIRECTORY		;Fehler: $04
			w dbtxErrDirFull		;Full directory.
			b $21				;Fehler: $21
			w dbtxErrNoDisk			;Read error.
			b $26				;Fehler: $26
			w dbtxErrWrProt			;Write protect on.
			b DBLSIDED_DISK			;Fehler: $80
			w dbtxErrDiskDS			;Double sided disk.
:tabErrCodesOther	b $00				;Fehler: Allgemein
			w txErrInit			;Initialisierung.
