; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateieintrag für Icon schreiben.
.writeDirEntry		cmp	#ICON_BORDER
			bcc	updateCurDirPage

;*** Borderblock aktualisieren.
.updateBorderBlk	ldx	#NO_ERROR

			lda	isGEOS
			beq	:exit

			jsr	prepGetBorderB
			jsr	PutBlock

::exit			rts

;*** Verzeichnisseite speichern.
.updateCurDirPage	lda	a0L

;*** Verzeichnisblock aktualisieren.
:updateDirBlock		pha
			clc
			adc	#> dirDiskBuf -256
			sta	r4H
			ldy	#< dirDiskBuf -256
;			ldy	#$00
			sty	r4L
			iny
			jsr	get1stDirTrSe

			pla
			bne	:1

			tya
			bne	:2

::1			ldy	#$01
			lda	(r4L),y
::2			sta	r1H

			inc	r4H
			jmp	PutBlock
