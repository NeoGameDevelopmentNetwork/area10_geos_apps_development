; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Stand-Alone-Laufwerkstreiber.
			b $f0,"s.GD.DRV.Core",$00
			b $f0,"s.GD.DRV.C1541",$00
			b $f0,"s.GD.DRV.C1541S",$00
			b $f0,"s.GD.DRV.C1571",$00
			b $f0,"s.GD.DRV.C1581",$00
			b $f0,"s.GD.DRV.RAM41",$00
			b $f0,"s.GD.DRV.RAM71",$00
			b $f0,"s.GD.DRV.RAM81",$00
			b $f0,"s.GD.DRV.RAMNM",$00
			b $f0,"s.GD.DRV.RAMNM_S",$00
			b $f0,"s.GD.DRV.RAMNM_C",$00
			b $f0,"s.GD.DRV.RAMNM_G",$00
			b $f0,"s.GD.DRV.FD41",$00
			b $f0,"s.GD.DRV.FD71",$00
			b $f0,"s.GD.DRV.FD81",$00
			b $f0,"s.GD.DRV.FDNM",$00
			b $f0,"s.GD.DRV.HD41",$00
			b $f0,"s.GD.DRV.HD71",$00
			b $f0,"s.GD.DRV.HD81",$00
			b $f0,"s.GD.DRV.HDNM",$00
			b $f0,"s.GD.DRV.RL41",$00
			b $f0,"s.GD.DRV.RL71",$00
			b $f0,"s.GD.DRV.RL81",$00
			b $f0,"s.GD.DRV.RLNM",$00
			b $f0,"s.GD.DRV.DOS81",$00
			b $f0,"s.GD.DRV.DOSFD",$00
;			b $f0,"s.GD.DRV.IECBNM",$00
			b $f0,"s.GD.DRV.SDNM",$00
