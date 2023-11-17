; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Laufwerkstreiber.
:DISK__1		OPEN_BOOT
			OPEN_SYMBOL

			OPEN_DISK
			t "-A3_Disk#1"

;--- Vorhandene Treiber-Datei löschen.
:DelObjFileDiskD	b $f1
			lda	#DvAdr_Target
			jsr	SetDevice
			jsr	OpenDisk

			LoadW	r0,:1
			jsr	DeleteFile

;--- MegaLinker aufrufen.
::0			LoadW	a0,:2
			rts

if COMP_SYS = TRUE_C64
::1			b "GEOS64.Disk",$00
::2			b $f5
			b $f0,"lnk.G3_64.Disk",$00
			b $f4
endif

if COMP_SYS = TRUE_C128
::1			b "GEOS128.Disk",$00
::2			b $f5
			b $f0,"lnk.G3_128.Disk",$00
			b $f4
endif
