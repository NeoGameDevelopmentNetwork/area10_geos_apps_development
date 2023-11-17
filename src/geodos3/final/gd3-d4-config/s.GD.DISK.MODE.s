; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "mod.MDD_#100"
			t "G3_Sys.Author"
			t "G3_SymMacExt"
			f SYSTEM
			o $6000

			t "src.Disk.Class"

			i
<MISSING_IMAGE_DATA>

;******************************************************************************
;*** Systemkennung.
;******************************************************************************
;G3(D)isk(C)oreV(x).(y)
::syscode		b "G3DC10"

;--- Angaben aus GD.DISK:
;Bei Änderungen "s.GD.DISK.MODE",
;"s.GDC.Drives" und "s.GD.UPDATE"
;ebenfalls anpassen!

;******************************************************************************
;*** Kennbytes und Namen für Laufwerkstreiber.
;******************************************************************************
:GD_NG_MODE = FALSE
			t "-D3_DrvTypes"
;******************************************************************************

;******************************************************************************
;*** VLIR-Struktur "GEOS.Disk"
;******************************************************************************
			t "-D3_DrvTypesVLIR"
;******************************************************************************
