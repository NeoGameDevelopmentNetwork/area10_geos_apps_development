; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** GeoDOS64-Dateien.
;******************************************************************************
if GD_NG_MODE = FALSE
:FILES_G1		= 26
endif
if GD_NG_MODE = TRUE
:FILES_G1		= 27
endif
:FILES_G2		= 2
if GD_NG_MODE = FALSE
:FILES_G3		= 1
endif
if GD_NG_MODE = TRUE
:FILES_G3		= 26
endif
:FILES_G4		= 1
:FILES_G5		= 5
:GD3_FILES_NUM		= FILES_G1 +FILES_G2 +FILES_G3 +FILES_G4 +FILES_G5

;--- Gruppe #1
:File_GD3_GEOS		b "GD",NULL
:File_GD3_GEOSr		b "GD.RESET",NULL
:File_GD3_GEOSb		b "GD.BOOT",NULL
:File_GD3_1		b "GD.BOOT.1",NULL
:File_GD3_2		b "GD.BOOT.2",NULL
:File_GD3_MP3		b "GD.UPDATE",NULL
:File_GD3_MBoot		b "GD.MAKEBOOT",NULL
:File_GD3_SETUP1	b "GD.CONFIG",NULL
:File_GD3_SETUP2	b "GD.CONF.RAM",NULL
:File_GD3_SETUP3	b "GD.CONF.DRIVES",NULL
:File_GD3_SETUP4	b "GD.CONF.SCREEN",NULL
:File_GD3_SETUP5	b "GD.CONF.GEOS",NULL
:File_GD3_SETUP6	b "GD.CONF.PRNINPT",NULL
:File_GD3_SETUP7	b "GD.CONF.GEOHELP",NULL
:File_GD3_SETUP8	b "GD.CONF.TASKMAN",NULL
:File_GD3_SETUP9	b "GD.CONF.SPOOLER",NULL
:File_GD3_HELP1		b "GD.GEOHELP.DA",NULL
:File_GD3_HELP2		b "GD.GEOHELP",NULL
:File_GD3_HELP3		b "GD.GEOHELP.PRN",NULL
if Sprache = Deutsch
:File_GD3_HELP4		b "DHS_Index.001",NULL
:File_GD3_HELP5		b "DHS_HilfeSystem",NULL
endif
if Sprache = Englisch
:File_GD3_HELP4		b "EHS_Index.001",NULL
:File_GD3_HELP5		b "EHS_HelpSystem",NULL
endif

:File_GD3_Arrow		b "NewMouse64",NULL
:File_GD3_Mouse		b "SuperMouse64",NULL
:File_GD3_Stick1	b "SuperStick64.1",NULL
:File_GD3_Stick2	b "SuperStick64.2",NULL

:File_GD3_DTOP		b "GEODESK",NULL

if GD_NG_MODE = TRUE
:File_GD3_DCore		b "GD.DISK.CORE",NULL
endif

;--- Gruppe #2
:File_GD3_RBOOT		b "GD.RBOOT",NULL
:File_GD3_RBOOTb	b "GD.RBOOT.SYS",NULL

;--- Gruppe #3
if GD_NG_MODE = FALSE
:File_GD3_Disk		b "GD.DISK",NULL
endif
if GD_NG_MODE = TRUE
:File_GD3_Dv41		b "GD.DISK.C1541",NULL
:File_GD3_Dv41S		b "GD.DISK.C1541S",NULL
:File_GD3_Dv71		b "GD.DISK.C1571",NULL
:File_GD3_Dv81		b "GD.DISK.C1581",NULL
:File_GD3_DvR41		b "GD.DISK.RAM41",NULL
:File_GD3_DvR71		b "GD.DISK.RAM71",NULL
:File_GD3_DvR81		b "GD.DISK.RAM81",NULL
:File_GD3_DvRNM		b "GD.DISK.RAMNM",NULL
:File_GD3_DvRNMS	b "GD.DISK.RAMNM_S",NULL
:File_GD3_DvRNMC	b "GD.DISK.RAMNM_C",NULL
:File_GD3_DvRNMG	b "GD.DISK.RAMNM_G",NULL
:File_GD3_DvRL41	b "GD.DISK.RL41",NULL
:File_GD3_DvRL71	b "GD.DISK.RL71",NULL
:File_GD3_DvRL81	b "GD.DISK.RL81",NULL
:File_GD3_DvRLNM	b "GD.DISK.RLNM",NULL
:File_GD3_DvFD41	b "GD.DISK.FD41",NULL
:File_GD3_DvFD71	b "GD.DISK.FD71",NULL
:File_GD3_DvFD81	b "GD.DISK.FD81",NULL
:File_GD3_DvFDNM	b "GD.DISK.FDNM",NULL
:File_GD3_DvHD41	b "GD.DISK.HD41",NULL
:File_GD3_DvHD71	b "GD.DISK.HD71",NULL
:File_GD3_DvHD81	b "GD.DISK.HD81",NULL
:File_GD3_DvHDNM	b "GD.DISK.HDNM",NULL
:File_GD3_DvSDNM	b "GD.DISK.SDNM",NULL
:File_GD3_DvD81		b "GD.DISK.DOS81",NULL
:File_GD3_DvDFD		b "GD.DISK.DOSFD",NULL
endif

;--- Gruppe #4
:File_GD3_Pic		b "GD.LOGO",NULL

;--- Gruppe #5
:File_GD3_ScrSv1	b "PacMan",NULL
:File_GD3_ScrSv2	b "PuzzleIt!",NULL
:File_GD3_ScrSv3	b "Starfield",NULL
:File_GD3_ScrSv4	b "Rasterbars",NULL
:File_GD3_ScrSv5	b "64erMove",NULL

;*** Datei-Informationen.
;    Word #1 		= Zeiger auf Dateiname.
;    Word #2 		= Datei-Information.
;			Low -Byte = Dateigruppe #1 bis #5.
;			High-Byte = $00 = Bootfile für GD3-Startdiskette.
;			            $FF = Zum GD3-Start nicht notwendig.
;--- Gruppe #1
:FileDataTab		w File_GD3_GEOS     ,$0001
			w File_GD3_GEOSr    ,$ff01
			w File_GD3_GEOSb    ,$0001
			w File_GD3_1        ,$0001
			w File_GD3_2        ,$0001
			w File_GD3_MP3      ,$0001
			w File_GD3_MBoot    ,$0001
			w File_GD3_SETUP1   ,$0001
			w File_GD3_SETUP2   ,$0001
			w File_GD3_SETUP3   ,$0001
			w File_GD3_SETUP4   ,$0001
			w File_GD3_SETUP5   ,$0001
			w File_GD3_SETUP6   ,$0001
			w File_GD3_SETUP7   ,$0001
			w File_GD3_SETUP8   ,$0001
			w File_GD3_SETUP9   ,$0001
			w File_GD3_HELP1    ,$0001
			w File_GD3_HELP2    ,$0001
			w File_GD3_HELP3    ,$0001
			w File_GD3_HELP4    ,$0001
			w File_GD3_HELP5    ,$0001

			w File_GD3_Arrow    ,$ff01
			w File_GD3_Mouse    ,$ff01
			w File_GD3_Stick1   ,$ff01
			w File_GD3_Stick2   ,$ff01

			w File_GD3_DTOP     ,$0001

if GD_NG_MODE = TRUE
			w File_GD3_DCore    ,$0001
endif

;--- Gruppe #2
			w File_GD3_RBOOT    ,$ff02
			w File_GD3_RBOOTb   ,$ff02

;--- Gruppe #3
if GD_NG_MODE = FALSE
			w File_GD3_Disk     ,$0003
endif
if GD_NG_MODE = TRUE
			w File_GD3_Dv41     ,$0003
			w File_GD3_Dv41S    ,$ff03
			w File_GD3_Dv71     ,$0003
			w File_GD3_Dv81     ,$0003
			w File_GD3_DvR41    ,$0003
			w File_GD3_DvR71    ,$0003
			w File_GD3_DvR81    ,$0003
			w File_GD3_DvRNM    ,$0003
			w File_GD3_DvRNMS   ,$ff03
			w File_GD3_DvRNMC   ,$ff03
			w File_GD3_DvRNMG   ,$ff03
			w File_GD3_DvRL41   ,$ff03
			w File_GD3_DvRL71   ,$ff03
			w File_GD3_DvRL81   ,$ff03
			w File_GD3_DvRLNM   ,$ff03
			w File_GD3_DvFD41   ,$ff03
			w File_GD3_DvFD71   ,$ff03
			w File_GD3_DvFD81   ,$ff03
			w File_GD3_DvFDNM   ,$ff03
			w File_GD3_DvHD41   ,$ff03
			w File_GD3_DvHD71   ,$ff03
			w File_GD3_DvHD81   ,$ff03
			w File_GD3_DvHDNM   ,$ff03
			w File_GD3_DvSDNM   ,$ff03
			w File_GD3_DvD81    ,$ff03
			w File_GD3_DvDFD    ,$ff03
endif

;--- Gruppe #4
			w File_GD3_Pic      ,$ff04

;--- Gruppe #5
			w File_GD3_ScrSv1   ,$ff05
			w File_GD3_ScrSv2   ,$ff05
			w File_GD3_ScrSv3   ,$ff05
			w File_GD3_ScrSv4   ,$ff05
			w File_GD3_ScrSv5   ,$ff05

			w $0000,$0000
