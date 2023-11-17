; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
;			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
;			t "MacTab"
endif

;*** GEOS-Header.
			n "GD.BOOT.1"
			c "GDOSBOOT    V3.0"
			t "opt.Author"
;--- Hinweis:
;Startprogramme können von DESKTOP 2.x
;nicht kopiert werden.
;			f SYSTEM_BOOT ;Typ Startprogramm.
			f SYSTEM      ;Typ Systemdatei.
			z $80 ;nur GEOS64

			o BASE_GEOS_SYS -2
			p BASE_GEOS_SYS

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "GEOS-Kernal"
			h "Grundfunktionen..."
endif
if LANG = LANG_EN
			h "GEOS-kernal"
			h "Core functions..."
endif

;--- Ladeadresse.
:MainInit		w BASE_GEOS_SYS			;DUMMY-Bytes, da Kernal über
							;BASIC-Load eingelesen wird.

;******************************************************************************
;*** GD.BOOT.1 - Kernal
;******************************************************************************
;--- GEOS-Kernal.
::GEOS_Kernal		d "obj.GD_Kernal64"
;******************************************************************************
