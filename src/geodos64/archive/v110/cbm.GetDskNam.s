; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L450: Datenträgername ermitteln.
:CBM_GetDskNam		jsr	GetDirHead
			txa
			beq	:1
			jmp	DiskError

::1			LoadW	r0,curDirHead + $90

			ldy	#$0f
::2			lda	(r0L),y
			sta	cbmDiskName,y
			dey
			bpl	:2

			rts
