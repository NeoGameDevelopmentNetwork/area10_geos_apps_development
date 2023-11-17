; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Achtung: Bei GEOS128 im Bereich ab $d000 unter IO-Bereich

;*** Zeiger auf Diskettenname einlesen.
:xGetPtrCurDkNm		ldy	curDrive
			lda	DrvNmVecL -8,y
			sta	zpage     +0,x
			lda	DrvNmVecH -8,y
			sta	zpage     +1,x
			rts

;*** Zeiger auf Positionen der Namen aller Disketten (A: bis D:)
:DrvNmVecL		b <DrACurDkNm,<DrBCurDkNm,<DrCCurDkNm,<DrDCurDkNm
:DrvNmVecH		b >DrACurDkNm,>DrBCurDkNm,>DrCCurDkNm,>DrDCurDkNm
