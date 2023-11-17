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
			t "src.P1FileBo.ext"
endif

			n "PatchFileBox.2"
			c "VisionPatch V1.0"
			a "M. Kanet"

			f $06
			z $80

			o $c072
			p EnterDeskTop

			i
<MISSING_IMAGE_DATA>

;*** Swap-Datei auf Diskette löschen.
:lc072			LoadW	r6,SwapFileName		;SwapFile einladen.
			LoadB	r0L,$00
			jsr	GetFile

			LoadW	r0,SwapFileName		;SwapFile löschen.
			LoadW	r3,fileTrScTab
			jsr	FastDelFile

			lda	#" "			;Name zurücksetzen.
			sta	SwapFileName +5

			lda	#> $f441		;Zeiger innerhalb Routine
			sta	xRstrFrmDialogue +2	;":RstrFrmDialogue" setzen.
			lda	#< $f441
			sta	xRstrFrmDialogue +1
			jmp	RstrFrmDialogue

:lc0a6			ldx	#$02
			jsr	DB_SetFileNam
			lda	DB_FileTabVec +1
			sta	r1H
			lda	DB_FileTabVec +0
			sta	r1L
			rts
