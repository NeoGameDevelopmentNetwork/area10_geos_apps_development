; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Größen für RAMDisk/DiskImage
;
;Übergabe : -
;Rückgabe : -
;Verändert: -

:tabDiskSize		b $00,$00,$00,$00
			b $00,$ab,$02,$00
			b $00,$56,$05,$00
			b $00,$80,$0c,$00
:sizeNative		b $00,$00,$00,$00  ;mhb wird ermittelt.
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
:twoStepCopy		b $00,$00,$11,$00  ;Sonderbehandlung 1571.
			b $00,$00,$00,$00
