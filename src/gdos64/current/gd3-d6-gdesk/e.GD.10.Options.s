; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aufbau der GeoDesk-Optionen:

;--- Anzeige: 3Bytes
;000
.GD_COL_MODE		= GDA_OPTIONS +0
.GD_COL_DEBUG		= GDA_OPTIONS +1
.GD_COL_CACHE		= GDA_OPTIONS +2

;--- Hinweis:
;003
;Entfällt. Icon-Farbe im S/W-Modus
;entspricht der Textfarbe des Fensters.
; -> ":DoFileEntry" / C_WinBack.
.GD_COL_DISK		= GDA_OPTIONS +3

;--- DeskTop/AppLinks: 2Bytes
;003
.GD_LNK_LOCK		= GDA_OPTIONS +3
.GD_LNK_TITLE		= GDA_OPTIONS +4

;--- Hintergrundbild: 1Byte
;005
.GD_BACKSCRN		= GDA_OPTIONS +5

;--- Optionen/Anzeige: 5Bytes
;006
.GD_SLOWSCR		= GDA_OPTIONS +6
.GD_VIEW_DELETED	= GDA_OPTIONS +7
.GD_HIDE_SYSTEM		= GDA_OPTIONS +8
.GD_ICON_CACHE		= GDA_OPTIONS +9
.GD_ICON_PRELOAD	= GDA_OPTIONS +10

;--- Datei-Eigenschaften: 1Byte
;011
.GD_INFO_SAVE		= GDA_OPTIONS +11

;--- Dateien löschen: 2Bytes
;012
.GD_DEL_MENU		= GDA_OPTIONS +12
.GD_DEL_EMPTY		= GDA_OPTIONS +13

;--- Dateien kopieren: 6Bytes
;014
.GD_REUSE_DIR		= GDA_OPTIONS +14
.GD_OVERWRITE		= GDA_OPTIONS +15
.GD_SKIP_EXIST		= GDA_OPTIONS +16
.GD_SKIP_NEWER		= GDA_OPTIONS +17
.GD_COPY_NM_DIR		= GDA_OPTIONS +18
.GD_OPEN_TARGET		= GDA_OPTIONS +19

;--- DiskImage erstellen: 1Byte
;020
.GD_COMPAT_WARN		= GDA_OPTIONS +20

;--- Systeminfo/TaskInfo anzeigen: 1Byte
;021
.GD_SYSINFO_MODE	= GDA_OPTIONS +21

;--- Hilfsmittel/Hintergrund: 1Byte
;022
.GD_DA_BACKSCRN		= GDA_OPTIONS +22

;--- Standardansicht DeskTop: 4Bytes
;023
.GD_STD_VIEWMODE	= GDA_OPTIONS +23
.GD_STD_TEXTMODE	= GDA_OPTIONS +24
.GD_STD_SORTMODE	= GDA_OPTIONS +25
.GD_STD_SIZEMODE	= GDA_OPTIONS +26

;--- Dual-Fenster-Modus: 3Bytes
;027
.GD_DUALWIN_MODE	= GDA_OPTIONS +27
.GD_DUALWIN_DRV1	= GDA_OPTIONS +28
.GD_DUALWIN_DRV2	= GDA_OPTIONS +29

;--- Fenster neu laden: 1Byte
;030
.GD_DA_UPD_DIR		= GDA_OPTIONS +30

;--- HotCorners: 8Bytes
;031
.GD_HC_CFG1		= GDA_OPTIONS +31
.GD_HC_CFG2		= GDA_OPTIONS +32
.GD_HC_CFG3		= GDA_OPTIONS +33
.GD_HC_CFG4		= GDA_OPTIONS +34
.GD_HC_TIMER1		= GDA_OPTIONS +35
.GD_HC_TIMER2		= GDA_OPTIONS +36
.GD_HC_TIMER3		= GDA_OPTIONS +37
.GD_HC_TIMER4		= GDA_OPTIONS +38

;--- Senden: 6Bytes
;039
.GD_SENDTO_PRN		= GDA_OPTIONS +39
.GD_SENDTO_XPRN		= GDA_OPTIONS +40
.GD_SENDTO_DRV1		= GDA_OPTIONS +41
.GD_SENDTO_XDRV1	= GDA_OPTIONS +42
.GD_SENDTO_DRV2		= GDA_OPTIONS +43
.GD_SENDTO_XDRV2	= GDA_OPTIONS +44

;--- MicroMys: 1Byte
;045
.GD_MWHEEL		= GDA_OPTIONS +45

;--- EOF
;046
;254 ;Max. 254 Bytes!
