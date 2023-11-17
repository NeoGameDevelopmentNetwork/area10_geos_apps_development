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
			n "GD.BOOT.2"
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
			h "GDOS64-Kernal"
			h "Zusatzfunktionen..."
endif
if LANG = LANG_EN
			h "GDOS64 kernal"
			h "Additional functions..."
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
.x_InitSystem		d "obj.InitSystem"
.x_EnterDeskTop		d "obj.EnterDeskTop"
.x_ToBASIC		d "obj.NewToBasic"
.x_PanicBox		d "obj.NewPanicBox"
.x_GetNextDay		d "obj.GetNextDay"
.x_DoAlarm		d "obj.DoAlarm"
.x_GetFiles		d "obj.GetFiles"
.x_GetFilesData		d "obj.GetFilesData"
.x_GetFilesIcon		d "obj.GetFilesMenu"
.x_ClrDlgScreen		d "obj.ClrDlgScreen"
.x_GetBackScrn		d "obj.GetBackScrn"
.x_Register		d "obj.Register"
.x_GeoHelp		d "obj.GeoHelp"
.x_ScrSaver		d "obj.ScreenSaver"
.x_DiskCore		d "obj.DiskCore"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g OS_BASE -1
;******************************************************************************
