; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS64.2"
			t "G3_SymMacExt"
			t "G3_V.Cl.64.Boot"

			o BASE_GEOS_SYS -2
			p BASE_GEOS_SYS

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "MegaPatch-Kernal"
			h "Zusatzfunktionen..."
endif

if Sprache = Englisch
			h "MegaPatch-kernal"
			h "extended functions..."
endif

;--- Ladeadresse.
:MainInit		w BASE_GEOS_SYS			;DUMMY-Bytes, da Kernal über
							;BASIC-Load eingelesen wird.

;--- ReBoot-Funktionen.
.ReBoot_SCPU		d "obj.ReBoot.SCPU"
.ReBoot_RL		d "obj.ReBoot.RL"
.ReBoot_REU		d "obj.ReBoot.REU"
.ReBoot_BBG		d "obj.ReBoot.BBG"

;--- Erweiterte GEOS-Funktionen.
.x_EnterDeskTop		d "obj.EnterDeskTop"
.x_ToBASIC		d "obj.NewToBasic"
.x_PanicBox		d "obj.NewPanicBox"
.x_GetNextDay		d "obj.GetNextDay"
.x_DoAlarm		d "obj.DoAlarm"
.x_GetFiles		d "obj.GetFiles"
.x_GetFilesData		d "obj.GetFilesData"
.x_GetFilesIcon		d "obj.GetFilesMenu"
.x_ClrDlgScreen		d "obj.ClrDlgScreen"

			g OS_VARS -1
