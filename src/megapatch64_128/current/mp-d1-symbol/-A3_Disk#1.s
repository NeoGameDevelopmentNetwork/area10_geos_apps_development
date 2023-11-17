; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Laufwerkstreiber.
			b $f0,"s.1541_Turbo",$00
			b $f0,"s.1571_Turbo",$00
			b $f0,"s.1581_Turbo",$00
			b $f0,"s.DOS_Turbo",$00
			b $f0,"s.PP_Turbo",$00
			b $f0,"s.IECB_Turbo",$00

			b $f0,"s.1541",$00
			b $f0,"s.1571",$00
			b $f0,"s.1581",$00
			b $f0,"s.RAM41",$00
			b $f0,"s.RAM71",$00
			b $f0,"s.RAM81",$00
			b $f0,"s.RAMNM",$00
			b $f0,"s.RAMNM_SRAM",$00
			b $f0,"s.RAMNM_CREU",$00
			b $f0,"s.RAMNM_GRAM",$00
			b $f0,"s.FD41",$00
			b $f0,"s.FD71",$00
			b $f0,"s.FD81",$00
			b $f0,"s.FDNM",$00
			b $f0,"s.PCDOS",$00
			b $f0,"s.PCDOS_EXT",$00
			b $f0,"s.HD41",$00
			b $f0,"s.HD71",$00
			b $f0,"s.HD81",$00
			b $f0,"s.HDNM",$00
			b $f0,"s.HD41_PP",$00
			b $f0,"s.HD71_PP",$00
			b $f0,"s.HD81_PP",$00
			b $f0,"s.HDNM_PP",$00
			b $f0,"s.RL41",$00
			b $f0,"s.RL71",$00
			b $f0,"s.RL81",$00
			b $f0,"s.RLNM",$00
;--- Ergänzung: 17.10.18/M.Kanet
;IECBNM -> Kompatibel mit CMD-FD für Test unter VICE.
;SD2IEC -> Erfordert SD2IEC da Firmware-spezifische Aufrufe genutzt werden.
;Es werden beide Treiber assembliert, aber nur ein Treiber kann
;in GEOS.Disk eingebunden werden: beide Treiber nutzen die gleiche
;Laufwerks-Typ-ID.
;			b $f0,"s.IECBNM",$00
			b $f0,"s.SD2IEC",$00

			b $f0,"s.Info.DTypes",$00
			b $f0,"s.INIT 1541",$00
			b $f0,"s.INIT 1571",$00
			b $f0,"s.INIT 1581",$00
			b $f0,"s.INIT PCDOS",$00
			b $f0,"s.INIT FD",$00
			b $f0,"s.INIT HD41",$00
			b $f0,"s.INIT HD71",$00
			b $f0,"s.INIT HD81",$00
			b $f0,"s.INIT HDNM",$00
			b $f0,"s.INIT RAM41",$00
			b $f0,"s.INIT RAM71",$00
			b $f0,"s.INIT RAM81",$00
			b $f0,"s.INIT RAMNM",$00
			b $f0,"s.INIT RAMNM_S",$00
			b $f0,"s.INIT RAMNM_C",$00
			b $f0,"s.INIT RAMNM_G",$00
			b $f0,"s.INIT RL",$00
;			b $f0,"s.INIT IECBUS",$00
			b $f0,"s.INIT SD2IEC",$00

;Dateien löschen die über 'd'-OpCode
;in den Objektcode eingebunden wurden.
:DelObjFilesDisk	b $f1
			lda	#DEL_OBJ_FILES
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

;s.1541/1571/1581_Turbo/PP_Turbo
::10			b "obj.Turbo41",$00
::11			b "obj.Turbo71",$00
::12			b "obj.Turbo81",$00
::13			b "obj.TurboPP",$00
::14			b "obj.TurboIECB",$00

;s.INIT HD41/71/81/NM
::20			b "DiskDev_HD41_PP",$00
::21			b "DiskDev_HD71_PP",$00
::22			b "DiskDev_HD81_PP",$00
::23			b "DiskDev_HDNM_PP",$00

;s.PCDOS
::30			b "obj.PCDOS",$00
::31			b "obj.TurboDOS",$00

::90			w :10,:11,:12,:13,:14
			w :20,:21,:22,:23
			w :30,:31
			w $0000
::99

;Externe Symboltabellen löschen.
:DelExtFilesDisk	b $f1
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

;s.1541/1571/1581_Turbo/PP_Turbo/DOS_Turbo
::10			b "s.1541_Turbo.ext",$00
::11			b "s.1571_Turbo.ext",$00
::12			b "s.1581_Turbo.ext",$00
::13			b "s.PP_Turbo.ext",$00
::14			b "s.DOS_Turbo.ext",$00
::15			b "s.IECB_Turbo.ext",$00

;s.PCDOS
::20			b "s.PCDOS.ext",$00
::21			b "s.PCDOS_EXT.ext",$00

::90			w :10,:11,:12,:13,:14,:15
			w :20,:21
			w $0000
::99
