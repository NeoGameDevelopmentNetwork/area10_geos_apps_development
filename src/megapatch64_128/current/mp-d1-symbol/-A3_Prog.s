; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Programme
:PROG__1		OPEN_BOOT
			OPEN_SYMBOL

;--- Laufwerkstreiber für Bootdiskette.
			OPEN_DISK
			t "-A3_Disk#2"

;--- GEOS.Editor.
			OPEN_PROG
			t "-A3_Prog#1"

;--- Vorhandenen GEOS.Editor löschen.
:DelObjFileEditor	b $f1
			lda	a1H
			jsr	SetDevice
			jsr	OpenDisk

			LoadW	r0,:1
			jsr	DeleteFile

;--- MegaLinker aufrufen.
			LoadW	a0,:2
			rts

if COMP_SYS = TRUE_C64
::1			b "GEOS64.Editor",$00
::2			b $f5
			b $f0,"lnk.GEOS64.Edit",$00
			b $f4
endif

if COMP_SYS = TRUE_C128
::1			b "GEOS128.Editor",$00
::2			b $f5
			b $f0,"lnk.GEOS128.Edit",$00
			b $f4
endif

;--- Zusatzprogramme.
;			OPEN_PROG
			t "-A3_Prog#2"
