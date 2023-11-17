; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Laufwerkstypen.
;******************************************************************************
:Drv1541		= $01
:Drv1571		= $02
:Drv1581		= $03
:DrvIECBNM		= $04
:DrvSD2IEC		= $04
:DrvNative		= $04
:DrvPCDOS		= $05
:Drv81DOS		= $05
:DrvFDDOS		= $15
:DrvShadow1541		= $41
;DrvShadow1571		= $42				;Reserviert für künftige Erweiterungen.
;DrvShadow1581		= $43				;Reserviert für künftige Erweiterungen.
;DrvShadowNM		= $44				;Reserviert für künftige Erweiterungen.
:DrvRAM1541		= $81
:DrvRAM1571		= $82
:DrvRAM1581		= $83
:DrvRAMNM		= $84
:DrvRAMNM_CREU		= $a4
:DrvRAMNM_GRAM		= $b4
:DrvRAMNM_SCPU		= $c4
:DrvFD			= $10
:DrvFD41		= $11
:DrvFD71		= $12
:DrvFD81		= $13
:DrvFD2			= $13
:DrvFD4			= $13
:DrvFDNM		= $14
:DrvHD			= $20
:DrvHD41		= $21
:DrvHD71		= $22
:DrvHD81		= $23
:DrvHDNM		= $24
:DrvRAMLink		= $30
:DrvRL41		= $31
:DrvRL71		= $32
:DrvRL81		= $33
:DrvRLNM		= $34
:DrvCMD			= %00110000

;*** Dummy-Device für VICE/FS.
:DrvVICEFS		= $7f

;*** Laufwerksmodi für RealDrvMode.
:SET_MODE_PARTITION	= %10000000
:SET_MODE_SUBDIR	= %01000000
:SET_MODE_FASTDISK	= %00100000
:SET_MODE_SRAM		= %00010000
:SET_MODE_CREU		= %00001000
:SET_MODE_GRAM		= %00000100
:SET_MODE_SD2IEC	= %00000010

;*** Filter Laufwerksmodi.
:ST_DMODES		= %00000111
