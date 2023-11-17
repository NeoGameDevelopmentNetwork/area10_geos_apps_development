; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Systemlabels.
;******************************************************************************

;*** Definition der Laufwerkstypen.
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

;*** Laufwerksmodi für RealDrvMode.
:SET_MODE_PARTITION	= %10000000
:SET_MODE_SUBDIR	= %01000000
:SET_MODE_FASTDISK	= %00100000
:SET_MODE_SRAM		= %00010000
:SET_MODE_CREU		= %00001000
:SET_MODE_GRAM		= %00000100
:SET_MODE_SD2IEC	= %00000010

;--- Ergänzung: 16.11.19/M.Kanet
;DDX ergänzt. Standardisierung von ":Flag_SD2IEC" und ":GeoRAMBSize",
;sowie Ergänzung zweier zusätzlicher Adressen für künftige Anwendungen.

;*** Kennung für "DiskDriver Xtended"
;    Nur für DDX-Treiber ab Nov.2019!
:DiskDrvTypeExt		= $9074				;"DDX"+NULL

;*** Daten innerhalb der Laufwerkstreiber.
;    Nicht für externe Anwendung bestimmt!
;--- Wird intern von 1541/71/81/SD2IEC zum setzen von RealDrvMode genutzt.
:Flag_SD2IEC		= $9078
;--- Wird von RAMNM_GRAM genutzt um die Bankgröße zu speichern.
;    Adresse siehe s.RAMNM_GRAM.ext!!!
:GeoRAMBSize		= $9079

;*** Reserviert für künftige Erweiterungen.
;    Nur für DDX-Treiber ab Nov.2019!
:DDRV_EXT_DATA1		= $907a
:DDRV_EXT_DATA2		= $907b

;*** Erweiterte Einsprungadressen.
;    Nur für DDX-Treiber ab Nov.2019!
:InitForDskDvOp		= $907c				;Zeiger auf Treiber im RAM.
:DoneWithDskDvOp	= $907f				;Register r0 bis r3L zurücksetzen.

;*** Ende DDX-Funktionen.
:EndOfDDX		= $9082

;*** Fehlermeldungen.
:NO_ERROR		= $00
:NO_BLOCKS		= $01
:INV_TRACK		= $02
:INSUFF_SPACE		= $03
:FULL_DIRECTORY		= $04
:FILE_NOT_FOUND		= $05
:BAD_BAM		= $06
:UNOPENED_VLIR		= $07
:INV_RECORD		= $08
:OUT_OF_RECORDS		= $09
:STRUCT_MISMAT		= $0a
:BFR_OVERFLOW		= $0b
:CANCEL_ERR		= $0c
:DEV_NOT_FOUND		= $0d
:INCOMPATIBLE		= $0e
:HDR_NOT_THERE		= $20
:NO_SYNC		= $21
:DBLK_NOT_THERE		= $22
:DAT_CHKSUM_ERR		= $23
:WR_VER_ERR		= $25
:WR_PR_ON		= $26
:HDR_CHKSUM_ERR		= $27
:DSK_ID_MISMAT		= $29
:BYTE_DEC_ERR		= $2e
:NO_PARTITION		= $30
:PART_FORMAT_ERR	= $31
:ILLEGAL_PARTITION	= $32
:NO_PART_FD_ERR		= $33
:ILLEGAL_DEVICE		= $40
:NO_FREE_RAM		= $60
:DOS_MISMATCH		= $73

;*** Laufwertsreiber-Register.
;Werden u.a. von den TurboDOS-Routinen
;der Laufwerkstreiber verwendet. Die
;Verwendung der Register ist aber nicht
;standardisiert. Die hier aufgeführte
;Verwendung gilt nur exemplarisch!
:d0			= $008b				;Zeiger auf Zwischenspeicher.
:d0L			= $8b
:d0H			= $8c
:d1L			= $8d				;Anzahl Datenbytes.
:d2L			= $8e				;TurboDOS/Modus-Flag #1.
:d2H			= $8f				;TurboDOS/Modus-Flag #2.
