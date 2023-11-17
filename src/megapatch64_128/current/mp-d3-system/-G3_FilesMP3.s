; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** MegaPatch-Dateien.
;******************************************************************************
:MP3_CoreFiles		= 26

;*** C64: Alle Dateien.
if Flag64_128 = TRUE_C64
:MP3_Files		= MP3_CoreFiles
endif

;*** C128: Weniger ScreenSaver, Extra Boot-Datei.
if Flag64_128 = TRUE_C128
:MP3_Files		= MP3_CoreFiles -3 +1
endif

;--- Gruppe #1
if Flag64_128 = TRUE_C64
:File_MP3_GEOS		b "GEOS64",NULL
:File_MP3_GEOSr		b "GEOS64.RESET",NULL
:File_MP3_GEOSb		b "GEOS64.BOOT",NULL
:File_MP3_1		b "GEOS64.1",NULL
:File_MP3_2		b "GEOS64.2",NULL
:File_MP3_3		b "GEOS64.3",NULL
:File_MP3_4		b "GEOS64.4",NULL
:File_MP3_MP3		b "GEOS64.MP3",NULL
:File_MP3_MBoot		b "GEOS64.MakeBoot",NULL
:File_MP3_TkMse		b "GEOS64.TaskMse",NULL
:File_MP3_Editor	b "GEOS64.Editor",NULL
:File_MP3_CEdit		b "GEOS64.EditCol",NULL
:File_MP3_Arrow		b "NewMouse64",NULL
:File_MP3_Mouse		b "SuperMouse64",NULL
:File_MP3_Stick1	b "SuperStick64.1",NULL
:File_MP3_Stick2	b "SuperStick64.2",NULL
endif
if Flag64_128 = TRUE_C128
:File_MP3_GEOS		b "GEOS128",NULL
:File_MP3_GEOSr		b "GEOS128.RESET",NULL
:File_MP3_GEOSb		b "GEOS128.BOOT",NULL
:File_MP3_0		b "GEOS128.0",NULL
:File_MP3_1		b "GEOS128.1",NULL
:File_MP3_2		b "GEOS128.2",NULL
:File_MP3_3		b "GEOS128.3",NULL
:File_MP3_4		b "GEOS128.4",NULL
:File_MP3_MP3		b "GEOS128.MP3",NULL
:File_MP3_MBoot		b "GEOS128.MakeBoot",NULL
:File_MP3_TkMse		b "GEOS128.TaskMse",NULL
:File_MP3_Editor	b "GEOS128.Editor",NULL
:File_MP3_CEdit		b "GEOS128.EditCol",NULL
:File_MP3_Arrow		b "NewMouse128",NULL
:File_MP3_Mouse		b "SuperMouse128",NULL
:File_MP3_Stick1	b "SuperStick128.1",NULL
:File_MP3_Stick2	b "SuperStick128.2",NULL
endif

;--- Gruppe #2
if Flag64_128 = TRUE_C64
:File_MP3_RBOOT		b "RBOOT64",NULL
:File_MP3_RBOOTb	b "RBOOT64.BOOT",NULL
endif
if Flag64_128 = TRUE_C128
:File_MP3_RBOOT		b "RBOOT128",NULL
:File_MP3_RBOOTb	b "RBOOT128.BOOT",NULL
endif

;--- Gruppe #3
if Flag64_128 = TRUE_C64
:File_MP3_Disk		b "GEOS64.Disk",NULL
endif
if Flag64_128 = TRUE_C128
:File_MP3_Disk		b "GEOS128.Disk",NULL
endif

;--- Gruppe #4
if Flag64_128 = TRUE_C64
:File_MP3_Pic1		b "GEOSMP64.PIC",NULL
endif
if Flag64_128 = TRUE_C128
:File_MP3_Pic1		b "GEOSMP128.PIC",NULL
endif
:File_MP3_Pic2		b "GEOSMP.PIC",NULL

;--- Gruppe #5
;Bildschirmschoner PacMan, Rasterbars und 64erMove
;funktionieren unter MP128 nicht.
:File_MP3_ScrSv2	b "PuzzleIt!",NULL
:File_MP3_ScrSv3	b "Starfield",NULL
if Flag64_128 = TRUE_C64
:File_MP3_ScrSv1	b "PacMan",NULL
:File_MP3_ScrSv4	b "Rasterbars",NULL
:File_MP3_ScrSv5	b "64erMove",NULL
endif

;*** Datei-Informationen.
;    Word #1 		= Zeiger auf Dateiname.
;    Word #2 		= Datei-Information.
;			Low -Byte = Dateigruppe #1 bis #5.
;			High-Byte = $00 = Bootfile für MP3-Startdiskette.
;			            $FF = Zum MP3-Start nicht notwendig.

:FileDataTab
;--- Gruppe #1
if Flag64_128 = TRUE_C64
:FileCount_1		= 16
endif
if Flag64_128 = TRUE_C128
:FileCount_1		= 17
endif
:FileGroup_1		w File_MP3_GEOS     ,$0001
			w File_MP3_GEOSr    ,$ff01
			w File_MP3_GEOSb    ,$0001
if Flag64_128 = TRUE_C128
			w File_MP3_0        ,$0001
endif
			w File_MP3_1        ,$0001
			w File_MP3_2        ,$0001
			w File_MP3_3        ,$0001
			w File_MP3_4        ,$0001
			w File_MP3_MP3      ,$0001
			w File_MP3_MBoot    ,$0001
			w File_MP3_TkMse    ,$0001
			w File_MP3_Editor   ,$0001
			w File_MP3_CEdit    ,$ff01
			w File_MP3_Arrow    ,$ff01
			w File_MP3_Mouse    ,$ff01
			w File_MP3_Stick1   ,$ff01
			w File_MP3_Stick2   ,$ff01

;--- Gruppe #2
:FileCount_2		= 2
:FileGroup_2		w File_MP3_RBOOT    ,$ff02
			w File_MP3_RBOOTb   ,$ff02

;--- Gruppe #3
:FileCount_3		= 1
:FileGroup_3		w File_MP3_Disk     ,$0003

;--- Gruppe #4
:FileCount_4		= 2
:FileGroup_4		w File_MP3_Pic1     ,$ff04
			w File_MP3_Pic2     ,$ff04

;--- Gruppe #5
if Flag64_128 = TRUE_C64
:FileCount_5		= 5
endif
if Flag64_128 = TRUE_C128
:FileCount_5		= 2
endif
:FileGroup_5		w File_MP3_ScrSv2   ,$ff05
			w File_MP3_ScrSv3   ,$ff05
if Flag64_128 = TRUE_C64
			w File_MP3_ScrSv1   ,$ff05
			w File_MP3_ScrSv4   ,$ff05
			w File_MP3_ScrSv5   ,$ff05
endif

			w $0000,$0000

;*** Zeiger auf Datei-Gruppen-Informationen.
:VecFileGroupL		b < FileDataTab
			b < FileGroup_1
			b < FileGroup_2
			b < FileGroup_3
			b < FileGroup_4
			b < FileGroup_5
:VecFileGroupH		b > FileDataTab
			b > FileGroup_1
			b > FileGroup_2
			b > FileGroup_3
			b > FileGroup_4
			b > FileGroup_5

;*** Anzahl Dateien in Dateigruppe.
:FilesInGroup		b MP3_Files
			b FileCount_1
			b FileCount_2
			b FileCount_3
			b FileCount_4
			b FileCount_5
