; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS128.1"
			t "G3_SymMacExt"
			t "G3_V.Cl.128.Boot"

;			o BASE_GEOS_SYS -2
;			p BASE_GEOS_SYS

			o $2000 -2
			p $2000

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "MegaPatch-Kernal Bank 1"
			h "Grundfunktionen..."
endif

if Sprache = Englisch
			h "MegaPatch-kernal bank 1"
			h "mainprogramm..."
endif

;--- Ladeadresse.
:MainInit		w BASE_GEOS_SYS			;DUMMY-Bytes, da Kernal über
							;BASIC-Load eingelesen wird.
;--- Diskettentreiber für Bootvorgang.
.DiskDriver		t "-G3_BootDskDrv"
;			e BASE_GEOS_SYS + DISK_DRIVER_SIZE
			e $2000 + DISK_DRIVER_SIZE

;--- GEOS128-Kernal.
.GEOS_Kernal1		d "obj.G3_K128_B1"
