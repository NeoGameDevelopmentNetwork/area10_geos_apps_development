; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk deinstallieren.
;Übergabe: XReg = Laufwerk #8-#11
;Rückgabe: XReg = NO_ERROR.
:DskDev_ClrData		lda	#$00
			sta	ramBase       -8,x
			sta	driveType     -8,x
			sta	driveData     -8,x
			sta	turboFlags    -8,x
			sta	RealDrvType   -8,x
			sta	RealDrvMode   -8,x
			sta	drivePartData -8,x
			sta	doubleSideFlg -8,x
			tax
			rts
