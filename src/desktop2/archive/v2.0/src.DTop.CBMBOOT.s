; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** CBM-Bootsektor retten.
;Falls die Kennung gefunden wird, dann
;Block 1/0 in der BAM reservieren.
.cbmBootSek		jsr	testCBMBootSek
			bne	:exit
			jsr	allocCurBlock
::exit			rts

;*** Auf CBM-Bootsektor testen.
:testCBMBootSek		ldy	#$01
			sty	r1L
			dey
			sty	r1H
			jsr	getDiskBlock
			jsr	exitOnDiskErr

			ldy	#$00
			lda	(r4L),y
			cmp	#"C"
			bne	:exit
			iny
			lda	(r4L),y
			cmp	#"B"
			bne	:exit
			iny
			lda	(r4L),y
			cmp	#"M"
::exit			rts
