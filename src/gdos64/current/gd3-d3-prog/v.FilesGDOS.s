; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** GDOS64-Dateien.
;******************************************************************************
:FILES_G1		= 21				;System
:FILES_G2		= 3				;RBOOT
:FILES_G3		= 26				;Disk
:FILES_G4		= 17				;Extras
:FILES_G5		= 7				;Hilfe
:GD3_FILES_NUM		= FILES_G1 +FILES_G2 +FILES_G3 +FILES_G4 +FILES_G5

;--- Gruppe #1: System
:File_GD3_GEOS		b "GD",NULL
:File_GD3_GEOSr		b "GD.RESET",NULL
:File_GD3_GEOSb		b "GD.BOOT",NULL
:File_GD3_1		b "GD.BOOT.1",NULL
:File_GD3_2		b "GD.BOOT.2",NULL
:File_GD3_UPDATE	b "GD.UPDATE",NULL
:File_GD3_SETUP1	b "GD.CONFIG",NULL
:File_GD3_SETUP2	b "GD.CONF.RAM",NULL
:File_GD3_SETUP3	b "GD.CONF.DRIVES",NULL
:File_GD3_SETUP4	b "GD.CONF.SCREEN",NULL
:File_GD3_SETUP5	b "GD.CONF.GEOS",NULL
:File_GD3_SETUP6	b "GD.CONF.PRNINPT",NULL
:File_GD3_SETUP7	b "GD.CONF.GEOHELP",NULL
:File_GD3_SETUP8	b "GD.CONF.TASKMAN",NULL
:File_GD3_SETUP9	b "GD.CONF.SPOOLER",NULL
:File_GD3_Arrow		b "NewMouse64",NULL
:File_GD3_Mouse		b "Mouse1351",NULL
:File_GD3_MMysX0	b "MicroMysX0",NULL
:File_GD3_Stick1	b "SuperStick64.1",NULL
:File_GD3_Stick2	b "SuperStick64.2",NULL
:File_GD3_DTOP		b "GEODESK",NULL

;--- Gruppe #2: RBoot
:File_GD3_RBOOT		b "GD.RBOOT",NULL
:File_GD3_RBOOTb	b "GD.RBOOT.SYS",NULL
:File_GD3_FBOOT		b "GD.FBOOT",NULL

;--- Gruppe #3: Disk
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

;--- Gruppe #4: Extras
:File_GD3_Pic1		b "GD64.LOGO",NULL
:File_GD3_Col1		b "GeoDesk.stdcol",NULL
:File_GD3_Col2		b "GeoDesk.grey",NULL
:File_GD3_Col3		b "GeoDesk.green",NULL
:File_GD3_Col4		b "GeoDesk.yellow",NULL
:File_GD3_Col5		b "GeoDesk.blue",NULL
:File_GD3_ScrSv1	b "PacMan",NULL
:File_GD3_ScrSv2	b "PuzzleIt!",NULL
:File_GD3_ScrSv3	b "Starfield",NULL
:File_GD3_ScrSv4	b "Rasterbars",NULL
:File_GD3_ScrSv5	b "64erMove",NULL
:File_GD3_GDmod		b "GEODESK.mod",NULL
:File_GD3_SmartM	b "SmartMouse",NULL
:File_GD3_SMouse	b "SuperMouse64",NULL
:File_GD3_MMysX1	b "MicroMysX1",NULL
:File_GD3_MMysX2	b "MicroMysX2",NULL
:File_GD3_MMysX3	b "MicroMysX3",NULL

;--- Gruppe #5: Hilfe
:File_GD3_HELP1		b "GD.GEOHELP.DA",NULL
:File_GD3_HELP2		b "GD.GEOHELP",NULL
:File_GD3_HELP3		b "GD.GEOHELP.PRN",NULL
if LANG = LANG_DE
:File_GD3_HELP4		b "de.Index.001",NULL
:File_GD3_HELP5		b "de.HilfeSystem",NULL
:File_GD3_HELP6		b "de.geoWrite",NULL
:File_GD3_HELP7		b "de.News",NULL
endif
if LANG = LANG_EN
:File_GD3_HELP4		b "en.Index.001",NULL
:File_GD3_HELP5		b "en.HelpSystem",NULL
:File_GD3_HELP6		b "en.geoWrite",NULL
:File_GD3_HELP7		b "en.News",NULL
endif

;*** Datei-Informationen.
;--- Gruppe #1: System
:FileNameTab		w File_GD3_GEOS
			w File_GD3_GEOSr
			w File_GD3_GEOSb
			w File_GD3_1
			w File_GD3_2
			w File_GD3_UPDATE
			w File_GD3_SETUP1
			w File_GD3_SETUP2
			w File_GD3_SETUP3
			w File_GD3_SETUP4
			w File_GD3_SETUP5
			w File_GD3_SETUP6
			w File_GD3_SETUP7
			w File_GD3_SETUP8
			w File_GD3_SETUP9
			w File_GD3_Arrow
			w File_GD3_Mouse
			w File_GD3_MMysX0
			w File_GD3_Stick1
			w File_GD3_Stick2
			w File_GD3_DTOP

;--- Gruppe #2: RBoot
			w File_GD3_RBOOT
			w File_GD3_RBOOTb
			w File_GD3_FBOOT

;--- Gruppe #3: Disk
			w File_GD3_Dv41
			w File_GD3_Dv41S
			w File_GD3_Dv71
			w File_GD3_Dv81
			w File_GD3_DvR41
			w File_GD3_DvR71
			w File_GD3_DvR81
			w File_GD3_DvRNM
			w File_GD3_DvRNMS
			w File_GD3_DvRNMC
			w File_GD3_DvRNMG
			w File_GD3_DvRL41
			w File_GD3_DvRL71
			w File_GD3_DvRL81
			w File_GD3_DvRLNM
			w File_GD3_DvFD41
			w File_GD3_DvFD71
			w File_GD3_DvFD81
			w File_GD3_DvFDNM
			w File_GD3_DvHD41
			w File_GD3_DvHD71
			w File_GD3_DvHD81
			w File_GD3_DvHDNM
			w File_GD3_DvSDNM
			w File_GD3_DvD81
			w File_GD3_DvDFD

;--- Gruppe #4: Extras
			w File_GD3_Pic1
			w File_GD3_Col1
			w File_GD3_Col2
			w File_GD3_Col3
			w File_GD3_Col4
			w File_GD3_Col5
			w File_GD3_ScrSv1
			w File_GD3_ScrSv2
			w File_GD3_ScrSv3
			w File_GD3_ScrSv4
			w File_GD3_ScrSv5
			w File_GD3_GDmod
			w File_GD3_SmartM
			w File_GD3_SMouse
			w File_GD3_MMysX1
			w File_GD3_MMysX2
			w File_GD3_MMysX3

;--- Gruppe #5: Hilfe
			w File_GD3_HELP1
			w File_GD3_HELP2
			w File_GD3_HELP3
			w File_GD3_HELP4
			w File_GD3_HELP5
			w File_GD3_HELP6
			w File_GD3_HELP7

			w $0000

;*** Gruppen-Informationen.
;    Word = Datei-Information.
;           Low -Byte = Dateigruppe #1 bis #5.
;           High-Byte = $00 = Erforderlich für GD3-Startdiskette.
;                             Laufwerkstreiber: Installtion empfohlen.
;                       $FF = Zum GD3-Start nicht notwendig.
;--- Gruppe #1: System
:FileModeTab		w $0001 ;File_GD3_GEOS
			w $ff01 ;File_GD3_GEOSr
			w $0001 ;File_GD3_GEOSb
			w $0001 ;File_GD3_1
			w $0001 ;File_GD3_2
			w $0001 ;File_GD3_UPDATE
			w $0001 ;File_GD3_SETUP1
			w $0001 ;File_GD3_SETUP2
			w $0001 ;File_GD3_SETUP3
			w $0001 ;File_GD3_SETUP4
			w $0001 ;File_GD3_SETUP5
			w $0001 ;File_GD3_SETUP6
			w $0001 ;File_GD3_SETUP7
			w $0001 ;File_GD3_SETUP8
			w $0001 ;File_GD3_SETUP9
			w $ff01 ;File_GD3_Arrow
			w $ff01 ;File_GD3_Mouse
			w $ff01 ;File_GD3_MMysX0
			w $ff01 ;File_GD3_Stick1
			w $ff01 ;File_GD3_Stick2
			w $0001 ;File_GD3_DTOP

;--- Gruppe #2: RBoot
			w $ff02 ;File_GD3_RBOOT
			w $ff02 ;File_GD3_RBOOTb
			w $ff02 ;File_GD3_FBOOT

;--- Gruppe #3: Disk
			w $0003 ;File_GD3_Dv41
			w $ff03 ;File_GD3_Dv41S
			w $0003 ;File_GD3_Dv71
			w $0003 ;File_GD3_Dv81
			w $0003 ;File_GD3_DvR41
			w $0003 ;File_GD3_DvR71
			w $0003 ;File_GD3_DvR81
			w $0003 ;File_GD3_DvRNM
			w $ff03 ;File_GD3_DvRNMS
			w $ff03 ;File_GD3_DvRNMC
			w $ff03 ;File_GD3_DvRNMG
			w $ff03 ;File_GD3_DvRL41
			w $ff03 ;File_GD3_DvRL71
			w $ff03 ;File_GD3_DvRL81
			w $ff03 ;File_GD3_DvRLNM
			w $ff03 ;File_GD3_DvFD41
			w $ff03 ;File_GD3_DvFD71
			w $ff03 ;File_GD3_DvFD81
			w $ff03 ;File_GD3_DvFDNM
			w $ff03 ;File_GD3_DvHD41
			w $ff03 ;File_GD3_DvHD71
			w $ff03 ;File_GD3_DvHD81
			w $ff03 ;File_GD3_DvHDNM
			w $ff03 ;File_GD3_DvSDNM
			w $ff03 ;File_GD3_DvD81
			w $ff03 ;File_GD3_DvDFD

;--- Gruppe #4: Extras
			w $ff04 ;File_GD3_Pic1
			w $ff04 ;File_GD3_Col1
			w $ff04 ;File_GD3_Col2
			w $ff04 ;File_GD3_Col3
			w $ff04 ;File_GD3_Col4
			w $ff04 ;File_GD3_Col5
			w $ff04 ;File_GD3_ScrSv1
			w $ff04 ;File_GD3_ScrSv2
			w $ff04 ;File_GD3_ScrSv3
			w $ff04 ;File_GD3_ScrSv4
			w $ff04 ;File_GD3_ScrSv5
			w $ff04 ;File_GD3_GDmod
			w $ff04 ;File_GD3_SmartM
			w $ff04 ;File_GD3_SMouse
			w $ff04 ;File_GD3_MMysX1
			w $ff04 ;File_GD3_MMysX2
			w $ff04 ;File_GD3_MMysX3

;--- Gruppe #5: Hilfe
			w $ff05 ;File_GD3_HELP1
			w $ff05 ;File_GD3_HELP2
			w $ff05 ;File_GD3_HELP3
			w $ff05 ;File_GD3_HELP4
			w $ff05 ;File_GD3_HELP5
			w $ff05 ;File_GD3_HELP6
			w $ff05 ;File_GD3_HELP7

			w $0000
