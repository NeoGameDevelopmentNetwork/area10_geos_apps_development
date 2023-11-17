; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Kennbytes für Laufwerkstreiber.
:DskDrvTypes		b $00
			b Drv1541
			b DrvShadow1541
			b Drv1571
			b Drv1581
			b DrvSD2IEC			;Entspricht DrvIECBNM!
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

			e DskDrvTypes +DDRV_MAX

;*** Namen der Laufwerkstreiber.
:DskDrvNames

if LANG = LANG_DE
::d00			b "Kein Laufwerk"
			e :d00 + 17
endif
if LANG = LANG_EN
::d00			b "No drive"
			e :d00 + 17
endif

::d01			b "GD.DISK.C1541"
			e :d01 + 17
::d41			b "GD.DISK.C1541S"
			e :d41 + 17
::d02			b "GD.DISK.C1571"
			e :d02 + 17
::d03			b "GD.DISK.C1581"
			e :d03 + 17
::d04			b "GD.DISK.SDNM"		;Alternativ "IECBus Native".
			e :d04 + 17
::d05			b "GD.DISK.DOS81"
			e :d05 + 17

::d81			b "GD.DISK.RAM41"
			e :d81 + 17
::d82			b "GD.DISK.RAM71"
			e :d82 + 17
::d83			b "GD.DISK.RAM81"
			e :d83 + 17
::d84			b "GD.DISK.RAMNM"
			e :d84 + 17
::d84s			b "GD.DISK.RAMNM_S"
			e :d84s + 17
::d84c			b "GD.DISK.RAMNM_C"
			e :d84c + 17
::d84g			b "GD.DISK.RAMNM_G"
			e :d84g + 17

::d31			b "GD.DISK.RL41"
			e :d31 + 17
::d32			b "GD.DISK.RL71"
			e :d32 + 17
::d33			b "GD.DISK.RL81"
			e :d33 + 17
::d34			b "GD.DISK.RLNM"
			e :d34 + 17

::d11			b "GD.DISK.FD41"
			e :d11 + 17
::d12			b "GD.DISK.FD71"
			e :d12 + 17
::d13			b "GD.DISK.FD81"
			e :d13 + 17
::d14			b "GD.DISK.FDNM"
			e :d14 + 17
::d15			b "GD.DISK.DOSFD"
			e :d15 + 17

::d21			b "GD.DISK.HD41"
			e :d21 + 17
::d22			b "GD.DISK.HD71"
			e :d22 + 17
::d23			b "GD.DISK.HD81"
			e :d23 + 17
::d24			b "GD.DISK.HDNM"
			e :d24 + 17

			e DskDrvNames +DDRV_MAX*17
