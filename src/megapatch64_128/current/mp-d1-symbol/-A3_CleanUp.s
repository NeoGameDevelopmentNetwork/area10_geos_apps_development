; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Dateien löschen die über 'd'-OpCode
;in den Objektcode eingebunden wurden.
:DelObjFilesSys		b $f1
			lda	#DEL_OBJ_FILES
			cmp	#FALSE
			beq	:3

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			lda	:10
			beq	:1
			LoadW	r0,:10			;TurboDOS löschen.
			jsr	DeleteFile
::1			LoadW	r0,:11			;Treiber für Boot-Vorgang löschen.
			jsr	DeleteFile

			ldy	#$00
::2			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H
			ora	r0L
			beq	:3
			tya
			pha
			jsr	DeleteFile
			pla
			tay
			iny
			iny
			bne	:2
::3			LoadW	a0,:99
			rts

;s.GEOS64.1/s.GEOS128.1

;Laufwerkstreiber für Standard 1541/71/81.
;Treiberabhängig ist auch das TurboDOS-Modul zu kompilieren!
;::10			b "obj.Turbo41",$00
;::11			b "DiskDev_1541",$00
;::10			b "obj.Turbo71",$00
;::11			b "DiskDev_1571",$00
::10			b "obj.Turbo81",$00
::11			b "DiskDev_1581",$00

;CMD-FD verwendet TurboDOS für 1581.
;::10			b "obj.Turbo81",$00
;::11			b "DiskDev_FD41",$00
;::11			b "DiskDev_FD71",$00
;::11			b "DiskDev_FD81",$00
;::11			b "DiskDev_FDNM",$00

;CMD-HD-Kabel wird nur innerhalb GEOS unterstützt.
;Beim Boot-Vorgang wird TurboDOS verwendet.
;::10			b "obj.Turbo81",$00
;::11			b "DiskDev_HD41",$00
;::11			b "DiskDev_HD71",$00
;::11			b "DiskDev_HD81",$00
;::11			b "DiskDev_HDNM",$00

;RamLink benötigt kein TurboDOS.
;::10			b $00
;::11			b "DiskDev_RL41",$00
;::11			b "DiskDev_RL71",$00
;::11			b "DiskDev_RL81",$00
;::11			b "DiskDev_RLNM",$00

if COMP_SYS = TRUE_C64
::15			b "obj.G3_Kernal64",$00
::16			b "MP_MakeKernal",$00
endif
if COMP_SYS = TRUE_C128
::15			b "obj.G3_K128_B0",$00
::16			b "obj.G3_K128_B1",$00
::17			b "obj.ResetBasic",$00
::18			b "MP_MakeKernal",$00
endif

;s.GEOS64.2/s.GEOS128.2
::20			b "obj.ReBoot.SCPU",$00
::21			b "obj.ReBoot.RL",$00
::22			b "obj.ReBoot.REU",$00
::23			b "obj.ReBoot.BBG",$00
::30			b "obj.EnterDeskTop",$00
::31			b "obj.NewToBasic",$00
::32			b "obj.NewPanicBox",$00
::33			b "obj.GetNextDay",$00
::34			b "obj.DoAlarm",$00
::35			b "obj.GetFiles",$00
::36			b "obj.GetFilesData",$00
::37			b "obj.GetFilesMenu",$00
::38			b "obj.ClrDlgScreen",$00

;s.GEOS64.3/s.GEOS128.3
::40			b "obj.TaskSwitch",$00
::41			b "obj.ScreenSaver",$00
::42			b "obj.GetBackScrn",$00
::43			b "obj.SpoolPrinter",$00
::44			b "obj.SpoolMenu",$00
::45			b "obj.Register",$00

;s.GEOSS64.MP3/s.GEOS128.MP3
::50			b "obj.Update2MP3",$00

;s.StartMP3_64/s.StartMP3_128
::60			b "obj.BuildID",$00

;s.GEOS64.BOOT/s.GEOS128.BOOT
::70			b "obj.AUTO.BOOT",$00
::71			b "obj.DvRAM_RL",$00
::72			b "obj.DvRAM_REU",$00
::73			b "obj.DvRAM_BBG.1",$00
::74			b "obj.DvRAM_BBG.2",$00
::75			b "obj.Patch_SCPU",$00
::76			b "obj.Patch_SRAM",$00
::77			b "obj.DvRAM_SCPU",$00

;s.64erMove
if COMP_SYS = TRUE_C64
::80			b "obj.SS_64erMove",$00
endif

if COMP_SYS = TRUE_C64
::90			w :15,:16
endif
if COMP_SYS = TRUE_C128
::90			w :15,:16,:17,:18
endif
			w :20,:21,:22,:23
			w :30,:31,:32,:33,:34,:35,:36,:37,:38
			w :40,:41,:42,:43,:44,:45
			w :50
			w :60
			w :70,:71,:72,:73,:74,:75,:76,:77
if COMP_SYS = TRUE_C64
			w :80
endif
			w $0000
::99

;Externe Symboltabellen löschen.
:DelExtFilesProg	b $f1
			lda	#DEL_EXT_FILES
			cmp	#FALSE
			beq	:2

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
::1			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H
			ora	r0L
			beq	:2
			tya
			pha
			jsr	DeleteFile
			pla
			tay
			iny
			iny
			bne	:1
::2			LoadW	a0,:99
			rts

;e.Register
::10			b "e.Register.ext",$00

;s.MP3.Edit.1/s.MP3.Edit.2
::11			b "s.MP3.Edit.1.ext",$00
::12			b "s.MP3.Edit.2.ext",$00

;o.Patch_SCPU/_SRAM/o.DvRAM_GRAM
::13			b "o.Patch_SCPU.ext",$00
::14			b "o.Patch_SRAM.ext",$00
::15			b "o.DvRAM_GRAM.ext",$00

;src.GEOS_MP3.64/src.GEOS_MP3.128
::16			b "src.GEOS_MP3.ext",$00

if COMP_SYS = TRUE_C64
;s.GEOS64.1/.2/.3/s.GEOS64.BOOT
::20			b "s.GEOS64.1.ext",$00
::21			b "s.GEOS64.2.ext",$00
::22			b "s.GEOS64.3.ext",$00
::23			b "s.GEOS64.4.ext",$00
::24			b "s.GEOS64.BOO.ext",$00
endif

if COMP_SYS = TRUE_C128
;src.G3_B0_128/s.GEOS128.0/.1/.2/.3/s.GEOS128.BOOT
::20			b "src.G3_B0_12.ext",$00
::21			b "s.GEOS128.0.ext",$00
::22			b "s.GEOS128.1.ext",$00
::23			b "s.GEOS128.2.ext",$00
::24			b "s.GEOS128.3.ext",$00
::25			b "s.GEOS128.4.ext",$00
::26			b "s.GEOS128.BO.ext",$00
endif

;s.GEOS64/128.1
;Bootlaufwerk: 1541
;::30			b "s.1541_Turbo.ext",$00
;Bootlaufwerk: 1571
;::30			b "s.1571_Turbo.ext",$00
;Bootlaufwerk: 1581/CMD-FD/CMD-HD
::30			b "s.1581_Turbo.ext",$00

::90			w :10,:11,:12
			w :13,:14,:15
			w :16
if COMP_SYS = TRUE_C64
			w :20,:21,:22,:23
			w :24
endif
if COMP_SYS = TRUE_C128
			w :20,:21,:22,:23
			w :24,:25,:26
endif
			w :30
			w $0000
::99
