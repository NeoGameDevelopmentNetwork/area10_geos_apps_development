; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerkstreiber-Operationen durchführen.
.InitForDskDvJob	ldy	curDrive		;yReg unverändert!!!
.InitCurDskDvJob	jsr	DoneWithDskDvJob	;RAM-Register zurücksetzen.

			lda	DskDrvBaseL -8,y	;Zeiger auf Laufwerkstreiber
			sta	r1L			;in REU in ZeroPage kopieren.
			lda	DskDrvBaseH -8,y
			sta	r1H
:NoFunc7		rts

;*** Zeiger auf Laufwerkstreiber in REU setzen/löschen.
.DoneWithDskDvJob	ldx	#$06
::1			lda	r0L ,x
			pha
			lda	:2  ,x
			sta	r0L ,x
			pla
			sta	:2  ,x
			dex
			bpl	:1
			rts

;*** Transferdaten für ":SetDevice".
::2			w $9000				;RAM-Adresse Laufwerkstreiber.
			w $0000				;REU-Adresse Laufwerkstreiber.
			w $0d80				;Länge Laufwerkstreiber.
			b $00				;BANK in REU.
