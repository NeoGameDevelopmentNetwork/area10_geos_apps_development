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

;--- TurboDOS / Treiber.
			OPEN_DISK

			b $f0,"s.1541_Turbo",$00
			b $f0,"s.1571_Turbo",$00
			b $f0,"s.1581_Turbo",$00
			b $f0,"s.DOS_Turbo",$00
			b $f0,"s.PP_Turbo",$00

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
;IECBNM ->
;Kompatibel mit CMD-FD für Test unter
;VICE nutzbar.
;
;SD2IEC ->
;Erfordert ein SD2IEC da Firmware-
;spezifische Aufrufe genutzt werden.
;
;Es kann nur ein Treiber eingebunden
;werden, denn beide Treiber nutzen die
;gleiche Laufwerks-ID.
;			b $f0,"s.IECB_Turbo",$00
;			b $f0,"s.IECBNM",$00

			b $f0,"s.SD2IEC",$00

;--- Laufwerksinstallation.
			OPEN_CONFIG

			b $f0,"o.DiskCore",$00
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
