; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Dateien löschen die über 'd'-OpCode
;in den Objektcode eingebunden wurden.
:DelObjFiles		b $f1
			lda	#DEL_OBJ_FILES
			cmp	#FALSE
			beq	:5

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			lda	:10
			beq	:1

			LoadW	r0,:10			;TurboDOS löschen.
			jsr	:doDelete

::1			lda	:11
			beq	:2

			LoadW	r0,:11			;Treiber für Boot-Vorgang löschen.
			jsr	:doDelete

::2			ldy	#$00
::3			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H

;			lda	r0H
			ora	r0L
			beq	:5
			tya
			pha

			ldy	#$00
			lda	(r0L),y
			beq	:4
			jsr	:doDelete
::4			pla
			tay
			iny
			iny
			bne	:3

::5			LoadW	a0,:NEXT
			rts

::doDelete		MoveW	r0,:801
			jsr	DeleteFile
			txa
			beq	:exitDlg
			lda	#DEL_ENABLE_WARN
			beq	:exitDlg
			LoadW	r0,:800
			jsr	DoDlgBox
::exitDlg		rts

;s.GD.BOOT.1

if (ENABLE_DISK_NG = FALSE) ! (ENABLE_DISK_ALL = BUILD_EVERYTHING)
;Laufwerkstreiber für Standard 1541/71/81.
;Treiberabhängig ist auch das TurboDOS-Modul zu kompilieren!
;::10			b "obj.Turbo41",$00
;;::11			b "DiskDev_1541",$00
;::10			b "obj.Turbo71",$00
;;::11			b "DiskDev_1571",$00
;::10			b "obj.Turbo81",$00
;;::11			b "DiskDev_1581",$00

;CMD-FD verwendet TurboDOS für 1581.
;::10			b "obj.Turbo81",$00
;;::11			b "DiskDev_FD41",$00
;;::11			b "DiskDev_FD71",$00
;;::11			b "DiskDev_FD81",$00
;;::11			b "DiskDev_FDNM",$00

;CMD-HD-Kabel wird nur innerhalb GEOS unterstützt.
;Beim Boot-Vorgang wird TurboDOS verwendet.
;::10			b "obj.Turbo81",$00
;;::11			b "DiskDev_HD41",$00
;;::11			b "DiskDev_HD71",$00
;;::11			b "DiskDev_HD81",$00
;;::11			b "DiskDev_HDNM",$00

;RamLink benötigt kein TurboDOS.
::10			b $00
;;::11			b "DiskDev_RL41",$00
;;::11			b "DiskDev_RL71",$00
::11			b "DiskDev_RL81",$00
;;::11			b "DiskDev_RLNM",$00
endif

if (ENABLE_DISK_NG = TRUE) & (ENABLE_DISK_ALL = BUILD_SELECTED)
::10			b $00
::11			b $00
endif

::15			b "obj.GD_Kernal64",$00
::16			b "obj.BuildID",$00
::17			b "MP_MakeKernal",$00

;s.GD.BOOT.2
::20			b "obj.ReBoot.SCPU",$00
::21			b "obj.ReBoot.RL",$00
::22			b "obj.ReBoot.REU",$00
::23			b "obj.ReBoot.BBG",$00
;
::30			b "obj.InitSystem",$00
::31			b "obj.EnterDeskTop",$00
::32			b "obj.NewToBasic",$00
::33			b "obj.NewPanicBox",$00
::34			b "obj.GetNextDay",$00
::35			b "obj.DoAlarm",$00
::36			b "obj.GetFiles",$00
::37			b "obj.GetFilesData",$00
::38			b "obj.GetFilesMenu",$00
::39			b "obj.ClrDlgScreen",$00
::40			b "obj.GetBackScrn",$00
::41			b "obj.Register",$00
::42			b "obj.GeoHelp",$00
::43			b "obj.ScreenSaver",$00

;s.GDC.Spooler
::50			b "obj.SpoolPrinter",$00
::51			b "obj.SpoolMenu",$00

;s.GDC.TaskMan
::52			b "obj.TaskSwitch",$00

;s.GD.UPDATE
::53			b "obj.GD.INITSYS",$00

;s.GD.BOOT
::60			b "obj.GD.AUTOBOOT",$00
::61			b "obj.DvRAM_RLNK",$00
::62			b "obj.DvRAM_CREU",$00
::63			b "obj.DvRAM_GRAM",$00
::64			b "obj.DvRAM_GSYS",$00
::65			b "obj.Patch_SCPU",$00
::66			b "obj.Patch_SRAM",$00
::67			b "obj.DvRAM_SRAM",$00

;s.64erMove
::70			b "obj.SS_64erMove",$00

::90			w :15,:16,:17
			w :20,:21,:22,:23
			w :30,:31,:32,:33,:34,:35,:36,:37,:38,:39,:40,:41,:42,:43
			w :50,:51,:52,:53
			w :60,:61,:62,:63,:64,:65,:66,:67
			w :70

			w $0000

::800			b $01
			b $30,$72
			w $0040,$00ff
			b DBTXTSTR,$10,$0e
			w :810
			b DBTXTSTR,$10,$1e
			w :811
			b DBTXTSTR,$10,$28
::801			w $ffff
			b OK,$02,$30
			b NULL
::810			b BOLDON,"DATEIFEHLER!",NULL
::811			b PLAINTEXT,"Kann Objekt-Datei nicht löschen:",NULL

::NEXT
