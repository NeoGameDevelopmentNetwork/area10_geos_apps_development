; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


;*** Neue OpenDisk-Routine.
:NewOpenDisk		jsr	NewDisk
			txa
			bne	:101

			jsr	GetDirHead
			txa
			bne	:101

			jsr	ChkDkGEOS

			ldx	#r1L
			jsr	GetPtrCurDkNm
			LoadW	r0,curDirHead +$90
			ldx	#r0L
			ldy	#r1L
			lda	#16
			jsr	CopyFString

			ldx	#$00
::101			rts
