; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Vorhandene Treiber-Datei löschen.
:DelDiskDrvFile		b $f1
			lda	#DvAdr_Target
			jsr	SetDevice
			jsr	OpenDisk

			LoadW	r0,:1
			jsr	DeleteFile

;--- MegaLinker aufrufen.
::0			LoadW	a0,:NEXT
			rts

::1			b "GD.DISK",$00
::NEXT
