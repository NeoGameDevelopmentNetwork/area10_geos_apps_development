; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Build-Dateien löschen.
:DEL__BUILD		OPEN_BOOT

;--- Objekt-Dateien löschen.
;(über 'd'-OpCode in Code eingebunden)
:DelObjFiles		b $f1
			lda	#DEL_OBJ_FILES
			cmp	#FALSE
			beq	:5

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
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
::15			b "obj.GD_Kernal64",$00
::17			b "MakeKernal",$00

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

::90			w :15,:17
			w :20,:21,:22,:23
			w :30,:31,:32,:33,:34,:35,:36,:37,:38,:39,:40,:41,:42,:43
			w :53
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

;--- Externe Symboltabellen GDOS64 löschen.
:DelExtFiles		b $f1
			lda	#DEL_EXT_FILES
			cmp	#FALSE
			beq	:3

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
::1			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H

;			lda	r0H
			ora	r0L
			beq	:3
			tya
			pha

			ldy	#$00
			lda	(r0L),y
			beq	:2
			jsr	:doDelete
::2			pla
			tay
			iny
			iny
			bne	:1

::3			LoadW	a0,:NEXT
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

;opt.GDOSl10n
::00			b "opt.GDOSl10n.ext",$00

;s.GD3_KERNAL
::01			b "s.GD3_KERNAL.ext",$00

;e.Register
::10			b "e.Register.ext",$00

;s.GD.CONFIG
::11			b "s.GDC.Config.ext",$00
::11a			b "s.GDC.E.DACC.ext",$00
::11b			b "s.GDC.E.SCRN.ext",$00
::11c			b "s.GDC.E.GEOS.ext",$00
::11d			b "s.GDC.E.SDEV.ext",$00
::11e			b "s.GDC.E.HELP.ext",$00
::11f			b "s.GDC.E.TASK.ext",$00
::11g			b "s.GDC.E.PSPL.ext",$00

;o.Patch_SCPU
::13			b "o.Patch_SCPU.ext",$00

;o.DvRAM_GRAM
::15			b "o.DvRAM_GRAM.ext",$00

;s.GD.BOOT.1/.2/s.GD.BOOT
::21			b "s.GD.BOOT.2.ext",$00
::22			b "s.GD.BOOT.ext",$00

;s.GD.RBOOT.S
::31			b "s.GD.RBOOT.S.ext",$00

;s.64erMove
::70			b "o.SS_64erMov.ext",$00

::90			w :00,:01,:10
			w :11,:11a,:11b,:11c,:11d,:11e,:11f,:11g
			w :13,:15
			w :21,:22
			w :31
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
::811			b PLAINTEXT,"Kann Symbol-Datei nicht löschen:",NULL

::NEXT

;--- Zusatzdateien Laufwerkstreiber löschen.
:DelObjDevFiles		b $f1
			lda	#DEL_OBJ_FILES
			cmp	#FALSE
			beq	:3

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
::1			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H

;			lda	r0H
			ora	r0L
			beq	:3
			tya
			pha

			ldy	#$00
			lda	(r0L),y
			beq	:2
			jsr	:doDelete
::2			pla
			tay
			iny
			iny
			bne	:1

::3			LoadW	a0,:NEXT
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

;s.GD.DISK
::10			b "obj.Turbo41",$00
::11			b "obj.Turbo71",$00
::12			b "obj.Turbo81",$00
::13			b "obj.TurboPP",$00
::14			b "obj.TurboDOS",$00
::15			b "obj.PCDOS",$00
;::16			b "obj.TurboIECB",$00

::54			b "obj.Drv_HD41_PP",$00
::55			b "obj.Drv_HD71_PP",$00
::56			b "obj.Drv_HD81_PP",$00
::57			b "obj.Drv_HDNM_PP",$00

::90			w :10,:11,:12,:13,:14,:15
;			w :16
			w :54,:55,:56,:57

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
::811			b PLAINTEXT,"Kann Treiber-Datei nicht löschen:",NULL

::NEXT

;--- Objektdateien Laufwerkstreiber löschen.
:DelObjDrvFiles		b $f1
			lda	#DEL_OBJ_FILES
			cmp	#FALSE
			beq	:3

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
::1			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H

;			lda	r0H
			ora	r0L
			beq	:3
			tya
			pha

			ldy	#$00
			lda	(r0L),y
			beq	:2
			jsr	:doDelete
::2			pla
			tay
			iny
			iny
			bne	:1

::3			LoadW	a0,:NEXT
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

;s.GD.DISK
::10			b "obj.DiskCore",$00

::20			b "obj.Drv_1541",$00
::21			b "obj.Drv_1571",$00
::22			b "obj.Drv_1581",$00
::23			b "obj.Drv_PCDOS",$00

::30			b "obj.Drv_RAM41",$00
::31			b "obj.Drv_RAM71",$00
::32			b "obj.Drv_RAM81",$00
::33			b "obj.Drv_RAMNM",$00
::34			b "obj.Drv_RAMNMC",$00
::35			b "obj.Drv_RAMNMG",$00
::36			b "obj.Drv_RAMNMS",$00

::40			b "obj.Drv_FD41",$00
::41			b "obj.Drv_FD71",$00
::42			b "obj.Drv_FD81",$00
::43			b "obj.Drv_FDNM",$00

::50			b "obj.Drv_HD41",$00
::51			b "obj.Drv_HD71",$00
::52			b "obj.Drv_HD81",$00
::53			b "obj.Drv_HDNM",$00

::60			b "obj.Drv_RL41",$00
::61			b "obj.Drv_RL71",$00
::62			b "obj.Drv_RL81",$00
::63			b "obj.Drv_RLNM",$00

::70			b "obj.Drv_SD2IEC",$00
;::71			b "obj.Drv_IECBNM",$00

::90			w :10
			w :20,:21,:22,:23
			w :30,:31,:32,:33,:34,:35,:36
			w :40,:41,:42,:43
			w :50,:51,:52,:53
			w :60,:61,:62,:63
			w :70
;			w :71

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
::811			b PLAINTEXT,"Kann Treiber-Datei nicht löschen:",NULL

::NEXT

;--- Externe Symboltabellen Laufwerkstreiber löschen.
:DelExtFilesDisk	b $f1
			lda	#DEL_EXT_FILES
			cmp	#FALSE
			beq	:3

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
::1			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H

;			lda	r0H
			ora	r0L
			beq	:3
			tya
			pha

			ldy	#$00
			lda	(r0L),y
			beq	:2
			jsr	:doDelete
::2			pla
			tay
			iny
			iny
			bne	:1

::3			LoadW	a0,:NEXT
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

;s.GD.DISK
::30			b "s.1541_Turbo.ext",$00
::31			b "s.1571_Turbo.ext",$00
::32			b "s.1581_Turbo.ext",$00
::33			b "s.PP_Turbo.ext",$00
::34			b "s.DOS_Turbo.ext",$00
::35			b "s.PCDOS.ext",$00
::36			b "s.PCDOS_EXT.ext",$00
;::37			b "s.IECB_Turbo.ext",$00
::89			b "o.DiskCore.ext",$00

::90			w :30,:31,:32,:33,:34,:35,:36
;			w :37
			w :89

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
::811			b PLAINTEXT,"Kann Symbol-Datei nicht löschen:",NULL

::NEXT

;--- Externe Symboltabellen GeoDesk löschen.
:DelExtFilesGD		b $f1
			lda	#DEL_EXT_FILES
			cmp	#FALSE
			beq	:3

			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			ldy	#$00
::1			lda	:90 +0,y
			sta	r0L
			lda	:90 +1,y
			sta	r0H

;			lda	r0H
			ora	r0L
			beq	:3
			tya
			pha

			ldy	#$00
			lda	(r0L),y
			beq	:2
			jsr	:doDelete
::2			pla
			tay
			iny
			iny
			bne	:1

::3			LoadW	a0,:NEXT
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

;s.GeoDesk
::10			b "s.GD.00.Boot.ext",$00
::11			b "s.GD.10.Core.ext",$00
::12			b "s.GD.20.WM.ext",$00
::13			b "s.GD.21.Desk.ext",$00

::90			w :10,:11,:12,:13

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
::811			b PLAINTEXT,"Kann Symbol-Datei nicht löschen:",NULL

::NEXT
