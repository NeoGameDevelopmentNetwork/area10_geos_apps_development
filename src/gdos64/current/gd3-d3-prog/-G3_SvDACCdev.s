; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichererweiterung in Startprogramme übertragen.
;--- Ergänzung: 03.03.21/M.Kanet:
;Wird von GD.BOOT und GD.UPDATE
;gemeinsam verwendet.
:SaveConfigDACC		LoadW	r6,FNamGDINI		;"GD.INI" modifizieren.
			jsr	FindFile
			txa
			bne	:err

			lda	dirEntryBuf +1		;Ersten Programmsektor einlesen.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:err

;			ldx	#0
::1			lda	ExtRAM_Type,x
			sta	diskBlkBuf +2 +2,x
			inx
			cpx	#5
			bcc	:1

			jsr	PutBlock
;			txa
;			bne	:err

::err			rts
