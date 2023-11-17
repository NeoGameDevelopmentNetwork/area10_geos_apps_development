; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Laufwerkstreiber/Installation.
			b $f0,"s.GD.DISK.MODE",$00
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
