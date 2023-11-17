; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** IECBus-NM oder IECBus-NM-Treiber wählen.
:IECBNM = $ff00		; -> Kompatibel mit CMD-FD für Test unter VICE.
:SD2IEC = $7f00		; -> Erfordert SD2IEC da Firmware-spezifische Aufrufe genutzt werden.

if .p
;IEC_DRV_TYPE 		= IECBNM
:IEC_DRV_TYPE 		= SD2IEC
endif

			n "mod.MDD_#100"
			t "G3_SymMacExt"
			f SYSTEM
			o $6000

if Flag64_128 = TRUE_C64
			t "src.Disk.Cl.64"
			a "Markus Kanet"
endif

if Flag64_128 = TRUE_C128
			t "src.Disk.Cl.128"
			a "M.Kanet/W.Grimm"
endif

			i
<MISSING_IMAGE_DATA>

;*** Kennbytes für installiert Laufwerkstreiber.
:DskDrvTypes		b $00
			b Drv1541
			b DrvShadow1541
			b Drv1571
			b Drv1581
			b Drv81DOS
			b DrvRAM1541
			b DrvRAM1571
			b DrvRAM1581
			b DrvRAMNM
			b DrvRAMNM_SCPU
			b DrvRAMNM_CREU
			b DrvRAMNM_GRAM
			b DrvRL41
			b DrvRL71
			b DrvRL81
			b DrvRLNM
			b DrvFD41
			b DrvFD71
			b DrvFD81
			b DrvFDNM
			b DrvFDDOS
			b DrvHD41
			b DrvHD71
			b DrvHD81
			b DrvHDNM
if IEC_DRV_TYPE = IECBNM
			b DrvIECBNM
endif
if IEC_DRV_TYPE = SD2IEC
			b DrvSD2IEC
endif

			e DskDrvTypes +64

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

; 15 - ++PLATZHALTER++ / Verwendet Init 1581
; 16 - Laufwerkstreiber FD41
; 17 - ++PLATZHALTER++ / Verwendet Init 1581
; 18 - Laufwerkstreiber FD71
; 19 - ++PLATZHALTER++ / Verwendet Init 1581
; 20 - Laufwerkstreiber FD81
; 21 - ++PLATZHALTER++ / Verwendet Init 1581
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

; 47 - Init IECBus-NM
; 48 - Laufwerkstreiber IECBus-NM/SD2IEC

;*** Datensätze für installiert Laufwerkstreiber.
:DskDrvVLIR		b $00,$00			;Kein Laufwerk.
			b $01,$02			;C=1541
			b $01,$02			;C=1541 Cache
			b $03,$04			;C=1571
			b $05,$06			;C=1581
			b $27,$28			;C=1581_DOS
			b $07,$08			;RAM 1541
			b $09,$0a			;RAM 1571
			b $0b,$0c			;RAM 1581
			b $0d,$0e			;RAM Native
			b $29,$2a			;SCPU RAM Native
			b $2b,$2c			;CREU RAM Native
			b $2d,$2e			;GRAM RAM Native
			b $1f,$20			;CMD RL 1541
			b $1f,$22			;CMD RL 1571
			b $1f,$24			;CMD RL 1581
			b $1f,$26			;CMD RL NativeMode
			b $0f,$10			;CMD FD 1541
			b $0f,$12			;CMD FD 1571
			b $0f,$14			;CMD FD 1581
			b $0f,$16			;CMD FD Native
			b $27,$28			;CMD FD DOS
			b $17,$18			;CMD HD 1541
			b $19,$1a			;CMD HD 1571
			b $1b,$1c			;CMD HD 1581
			b $1d,$1e			;CMD HD Native
			b $2f,$30 ;IECBus/SD2IEC Native

			e DskDrvVLIR +64*2

if Sprache = Deutsch
;*** Installierte Laufwerkstreiber.
:DiskDrivers		b "Kein Laufwerk"
			e DiskDrivers + 1*17
endif

if Sprache = Englisch
;*** Installierte Laufwerkstreiber.
:DiskDrivers		b "No drive"
			e DiskDrivers + 1*17
endif

			b "C=1541"
			e DiskDrivers + 2*17
			b "C=1541 (Cache)"
			e DiskDrivers + 3*17
			b "C=1571"
			e DiskDrivers + 4*17
			b "C=1581"
			e DiskDrivers + 5*17
			b "C=1581/DOS"
			e DiskDrivers + 6*17
			b "RAM 1541"
			e DiskDrivers + 7*17
			b "RAM 1571"
			e DiskDrivers + 8*17
			b "RAM 1581"
			e DiskDrivers + 9*17
			b "RAM Native"
			e DiskDrivers +10*17
			b "SuperRAM Native"
			e DiskDrivers +11*17
			b "C=REU Native"
			e DiskDrivers +12*17
			b "GeoRAM Native"
			e DiskDrivers +13*17
			b "CMD RL 1541"
			e DiskDrivers +14*17
			b "CMD RL 1571"
			e DiskDrivers +15*17
			b "CMD RL 1581"
			e DiskDrivers +16*17
			b "CMD RL Native"
			e DiskDrivers +17*17
			b "CMD FD 1541"
			e DiskDrivers +18*17
			b "CMD FD 1571"
			e DiskDrivers +19*17
			b "CMD FD 1581"
			e DiskDrivers +20*17
			b "CMD FD Native"
			e DiskDrivers +21*17
			b "CMD FD PCDOS"
			e DiskDrivers +22*17
			b "CMD HD 1541"
			e DiskDrivers +23*17
			b "CMD HD 1571"
			e DiskDrivers +24*17
			b "CMD HD 1581"
			e DiskDrivers +25*17
			b "CMD HD Native"
			e DiskDrivers +26*17
if IEC_DRV_TYPE = IECBNM
			b "IECBus Native"
			e DiskDrivers +27*17
endif
if IEC_DRV_TYPE = SD2IEC
			b "SD2IEC Native"
			e DiskDrivers +27*17
endif
			b NULL

			e DiskDrivers +64*17
