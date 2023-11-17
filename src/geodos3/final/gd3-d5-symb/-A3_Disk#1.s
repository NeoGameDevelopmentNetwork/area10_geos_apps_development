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
;			b $f0,"s.IECB_Turbo",$00
;			b $f0,"s.IECBNM",$00

			b $f0,"s.SD2IEC",$00
