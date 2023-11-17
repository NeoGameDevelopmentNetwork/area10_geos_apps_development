; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GDOS64-Systemkonfiguration.
:GDOS_DEFAULT_CONFIG

;--- GD.INI-Kennung:2Bytes
;000
::GDINI_VER_CODE	b GDINI_VER
			b $c0

;--- DACC-Typ:5Bytes
;Direkt nach BASIC-LOAD, wird von der
;Datei GD.BOOT beim Systemstart über
;Kernal-Routinen aus GD.INI eingelesen.
;BOOT_RAM_TYPE:
;  $00 = RAM nicht gewählt.
;  $10 = CMD-SuperCPU/RAMCard.
;  $20 = BBGRAM/GeoRAM/NeoRAM.
;  $40 = C=REU.
;  $80 = CMD-RAMLink.
;002
			b $00               ;BOOT_RAM_TYPE: DACC-Speicher: Typ.
			b $00               ;BOOT_RAM_SIZE: DACC-Speicher: Größe.
			w $0000             ;BOOT_RAM_BANK: Erste Speicherbank.
			b $00               ;BOOT_RAM_PART: Nicht verwendet.

;--- GDC.DRIVES:16Bytes
;Direkt nach DACC-Typ. Wird in INITSYS
;an dieser Stelle in der GD.INI-Datei
;nach dem Update gespeichert.
;007
			b $00,$00,$00,$00   ;BootConfig
			b $00,$00,$00,$00   ;BootPartRL
			b $00,$00,$00,$00   ;BootPartType
			b $00,$00,$00,$00   ;BootRamBase

;--- GEOS-Einstellungen:
;Bit%7: 0=Kein REU-MoveData
;Bit%6: 1=Laufwerkstreiber in REU
;Bit%5: 1=ReBoot-Daten in REU
;Bit%4: 1=ReBoot-Kernal in REU
;Bit%3: 1=Hintergrundbild aktiv
;023
			b %00001000  ;BootRAM_Flag

;--- Laufwerkstreiber in REU.
;Bit%7: 1=1541/71/81
;Bit%6: 1=SD2IEC/IECBus
;Bit%5: 1=CMD FD41/71/81/NM
;Bit%4: 1=CMD HD41/71/81/NM
;Bit%3: 1=CMD RL41/71/81/NM
;Bit%2: 1=RAM 41/71/81/NM
;Bit%1: 1=GRAM/CRAM/SRAM NM
;Bit%0: 1=DOSFD/DOS81
;024
			b %10000100  ;C=- und RAM-Laufwerke in RAM laden.

;--- CMD-HD-Kabel.
;Falls eine HD nur über den IEC-Bus
;angeschlossen ist, dann kann es unter
;bestimmten Umständen zu Problemen bei
;der Hardware-Erkennung kommen.
;Daher Parallel-Kabel standardmäßig
;deaktivieren.
;025
::BootUseFastPP		b %00000000  ;Bit%7=1: HD-Kabel aktivieren.

;--- Startoptionen.
;026
;Startlaufwerk anpassen:
; $FF = Start von #8 bis #11 = A: bis D: ersetzen.
; $00 = Tauschen wenn in Konfiguration vorhanden.
::BootDrvReplace	b $ff
;RAMLink-Laufwerk anpassen:
; $00 = AUTO oder $08-$0B für GEOS-Laufwerk A: bis D:.
::BootDrvRAMLink	b $00

;--- GD.CONFIG:0Bytes
;028

;--- GDC.RAM:65Bytes (RAM_MAX_SIZE)
;028
;--- Reservierter Speicher beim Start.
::BootBankAppl		b $06        ;6x64K für GDOS64/GEODESK reservieren.
;--- Blockierter Speicher.
::BootBankBlocked	s RAM_MAX_SIZE

;--- GDC.GEOS:30Bytes
;093
;--- SuperCPU:
;Bit%6 = 1: 1MHz-Modus
::BootSpeed		b %00000000
;Bit%01=11: Optimierung aus.
::BootOptimize		b %00000000
;--- Menü-Status:
;Bit%7 = Aktuellen Eintrag invertieren.
;Bit%6 = Menü nach unten begrenzen.
;Bit%5 = Doppelflash bei Auswahl.
;Bit%4 = Register-Menü: Icon-Status anzeigen.
::BootMenuStatus	b %11100000
;Bit%7 = 1: Trennlinien zeichnen.
::BootMLineMode		b %00000000
;--- Dialogboxen:
;Bit%7 = Immer in Farbe.
;Bit%6 = Farbe nur bei Standard-Bit.
;$00   = Farbe aus.
::BootColsMode		b %10000000
;--- Texteingabe:
::BootCRSR_Repeat	b $03
;--- QWERTZ-Tastatur:
;Bit%7 = 1: QWERTZ aktiv.
::BootQWERTZ		b %10000000
;--- RTC-Gerät:
;RTC-Geräte:
;  $fe: -
;  $10: CMD-FD
;  $20: CMD-HD
;  $30: CMD-RL
;  $FE: CMD-SmartMouse
;  $FF: Automatik-Modus
::BootRTCdrive		b $ff

;--- DeskTop:
;101
if LANG = LANG_DE
;BootNameDT/DE = max. 7 Zeichen +NULL.
;RULER --------------1234567---------
::BootNameDT		b "GEODESK"
endif
if LANG = LANG_EN
;BootNameDT/EN = max.12 Zeichen +NULL.
;RULER --------------123456789012----
::BootNameDT		b "GEODESK V1.0"
endif

;Auf 12 Zeichen + NULL-Byte begrenzen!
			e :BootNameDT +12 +1

;BootFileDT    = max. 8 Zeichen +NULL.
;RULER --------------12345678--------
::BootFileDT		b "GEODESK"

;Auf  8 Zeichen + NULL-Byte begrenzen.
			e :BootFileDT +8 +1

;--- GDC.SCREEN:61Bytes
;123
::BootColorGEOS		t "-G3_StdColors"
;145
::BootSaveColors	b %10000000  ;$80 = Beim "Speichern" Farbprofil erstellen.
;--- Hintergrundbild:
;146
::BootGrfxFile		b "GD64.LOGO"
			e :BootGrfxFile+17
::BootGrfxRandom	b %00000000  ;Bit%7 = Zufallsmodus aktivieren.
			             ;Bit%6 = Inkl. Farbprofil.
			             ;Bit%5 = Standardfarben verwenden.
::BootPattern		b $02        ;Hintergrundmuster.
;--- Bildschirmschoner:
;165
::BootScrSaver		b %01000000  ;Bit%7=1: Inaktiv, Bit%6=1:Neustart.
::BootScrSvCnt		b $0f
::BootSaverName		b "Starfield"
			e :BootSaverName+17

;--- GDC.PRNINPT:36Bytes
;BootInptName wird bei einem Update
;gelöscht, damit der neu installierte
;Eingabetreiber verwendet wird.
;Siehe dazu auch "-G3_InitInpDev"!
;184
;--- Gerätetreiber.
::BootInptName		s 17
::BootPrntName		s 17
;--- Optionen für Druckertreiber.
::BootPrntMode		b $00        ;$80 = Drucker von Diskette laden.
::BootGCalcFix		b $80        ;$80 = GCalcFix aktiv.

;--- GDC.GEOHELP:3Bytes
;220
::BootHelpSysMode	b $ff        ;$FF = HilfeSystem installieren.
::BootHelpSysDrv	b $00
::BootHelpSysPart	b $00

;--- GDC.TASKMAN:3Bytes
;223
::BootTaskMan		b $00        ;$00 TaskMan installieren.
::BootTaskSize		             ;Max. Anzahl Tasks.
			b MAX_TASK_STD
::BootTaskStart		b $00        ;$00 = CBM+CTRL, $FF=Linke/Rechte Maustaste.

;--- GDC.SPOOLER:3Byte
;226
::BootSpooler		b $80        ;$80 = Spooler aktivieren.
::BootSpoolDelay	             ;Aktivierungszeit Spooler ca.15sec.
			b STD_SPOOL_DELAY
::BootSpoolSize		             ;$00 = Größe beim Start automatisch setzen.
			b MAX_SPOOL_STD

;--- EOF
;229
;254 ;Max. 254 Bytes!

;******************************************************************************
;*** Endadresse für CONFIG testen.
;******************************************************************************
			g GDOS_DEFAULT_CONFIG +254
;******************************************************************************
