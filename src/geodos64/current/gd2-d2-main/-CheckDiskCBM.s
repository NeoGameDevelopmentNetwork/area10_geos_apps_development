; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Auf Diskette im CBM-Laufwerk testen
; Datum			: 02.07.97
; Aufruf		: JSR  CheckDiskCBM
; Übergabe		: -
; Rückgabe		: xReg	Byte $00 = Disk im Laufwerk
; Verändert		: AKKU,xReg,yReg
; Variablen		: -
; Routinen		: -GetBlock Sektor von Diskette lesen
;******************************************************************************

;*** Auf Diskette in CBM-Laufwerk prüfen.
.CheckDiskCBM		lda	#$01
			sta	r1L
			sta	r1H
			LoadW	r4,diskBlkBuf
			jmp	GetBlock
