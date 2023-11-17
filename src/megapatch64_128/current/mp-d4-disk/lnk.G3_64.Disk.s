; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** VLIR-Struktur "GEOS.Disk":
;  0 - Laufwerksinformationen

;  1 - Init 1541
;  2 - Laufwerkstreiber 1541
;  3 - Init 1571
;  4 - Laufwerkstreiber 1571
;  5 - Init 1581
;  6 - Laufwerkstreiber 1581

;  7 - Init RAM41
;  8 - Laufwerkstreiber RAM41
;  9 - Init RAM71
; 10 - Laufwerkstreiber RAM71
; 11 - Init RAM81
; 12 - Laufwerkstreiber RAM81
; 13 - Init RAMNM
; 14 - Laufwerkstreiber RAMNM

; 15 - Init FD
; 16 - Laufwerkstreiber FD41
; 17 - ++PLATZHALTER++ / Verwendet Init FD
; 18 - Laufwerkstreiber FD71
; 19 - ++PLATZHALTER++ / Verwendet Init FD
; 20 - Laufwerkstreiber FD81
; 21 - ++PLATZHALTER++ / Verwendet Init FD
; 22 - Laufwerkstreiber FDNM

; 23 - Init HD41
; 24 - Laufwerkstreiber HD41
; 25 - Init HD71
; 26 - Laufwerkstreiber HD71
; 27 - Init HD81
; 28 - Laufwerkstreiber HD81
; 29 - Init HDNM
; 30 - Laufwerkstreiber HDNM

; 31 - Init RL81
; 32 - Laufwerkstreiber RL41
; 33 - ++PLATZHALTER++ / Verwendet Init RL41
; 34 - Laufwerkstreiber RL71
; 35 - ++PLATZHALTER++ / Verwendet Init RL41
; 36 - Laufwerkstreiber RL81
; 37 - ++PLATZHALTER++ / Verwendet Init RL41
; 38 - Laufwerkstreiber RLNM

; 39 - Init PCDOS
; 40 - Laufwerkstreiber PCDOS

; 41 - Init SuperRAM-NM
; 42 - Laufwerkstreiber SuperRAM-NM

; 43 - Init C=REU-NM
; 44 - Laufwerkstreiber C=REU-NM

; 45 - Init GeoRAM-NM
; 46 - Laufwerkstreiber GeoRAM-NM

; 47 - Init IECBUS
; 48 - Laufwerkstreiber IECBus-NM/SD2IEC-NM

			n "GEOS64.Disk"

			h "Laufwerkstreiber"

			m
			- "mod.MDD_#100"		;Info

			- "mod.MDD_#110"		;INIT 1541
			- "DiskDev_1541"
			- "mod.MDD_#112"		;INIT 1571
			- "DiskDev_1571"
			- "mod.MDD_#114"		;INIT 1581
			- "DiskDev_1581"

			- "mod.MDD_#120"		;INIT RAM41
			- "DiskDev_RAM41"
			- "mod.MDD_#122"		;INIT RAM71
			- "DiskDev_RAM71"
			- "mod.MDD_#124"		;INIT RAM81
			- "DiskDev_RAM81"
			- "mod.MDD_#126"		;INIT RAMNM
			- "DiskDev_RAMNM"

			- "mod.MDD_#130"		;INIT FD41  => INIT FD
			- "DiskDev_FD41"
			- 				;INIT FD71  => INIT FD
			- "DiskDev_FD71"
			- 				;INIT FD81  => INIT FD
			- "DiskDev_FD81"
			- 				;INIT FDNM  => INIT FD
			- "DiskDev_FDNM"

			- "mod.MDD_#140"		;INIT HD41
			- "DiskDev_HD41"
			- "mod.MDD_#142"		;INIT HD71
			- "DiskDev_HD71"
			- "mod.MDD_#144"		;INIT HD81
			- "DiskDev_HD81"
			- "mod.MDD_#146"		;INIT HDNM
			- "DiskDev_HDNM"

			- "mod.MDD_#150"		;INIT RL41
			- "DiskDev_RL41"
			- 				;INIT RL71  => INIT RL41
			- "DiskDev_RL71"
			- 				;INIT RL81  => INIT RL41
			- "DiskDev_RL81"
			- 				;INIT RLNM  => INIT RL41
			- "DiskDev_RLNM"

			- "mod.MDD_#160"		;INIT PCDOS
			- "DiskDev_PCDOS"

			- "mod.MDD_#170"		;INIT RAMNM SCPU
			- "DiskDev_RAMNMS"

			- "mod.MDD_#172"		;INIT RAMNM C=REU
			- "DiskDev_RAMNMC"

			- "mod.MDD_#174"		;INIT RAMNM BBG/GeoRAM
			- "DiskDev_RAMNMG"

;--- Ergänzung: 17.10.18/M.Kanet
;IECBNM -> Kompatibel mit CMD-FD für Test unter VICE.
;SD2IEC -> Erfordert SD2IEC da Firmware-spezifische Aufrufe genutzt werden.
			- "mod.MDD_#180"		;INIT IECBUS.
;			- "DiskDev_IECBNM"		;Entweder IECBus-NM oder
			- "DiskDev_SD2IEC"		;SD2IEC-NM da gleiche ID.
			/
