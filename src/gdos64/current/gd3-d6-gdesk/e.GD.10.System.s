; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aufbau der GeoDesk-Optionen:

;--- Aufbau Systemdaten.
.SYSVAR_START		= GDA_SYSTEM

;--- Reservierter Speicher: 5Byte
;000

;64K-Speicherbank für ScreenBuffer:
;$0000-$1fff = ScreenBuffer Fenster #1/Grafik.
;$2000-$3fff = ScreenBuffer Fenster #2/Grafik.
;$4000-$5fff = ScreenBuffer Fenster #3/Grafik.
;$6000-$7fff = ScreenBuffer Fenster #4/Grafik.
;$8000-$9fff = ScreenBuffer Fenster #5/Grafik.
;$a000-$bfff = ScreenBuffer Fenster #6/Grafik.
;$c000-$dfff = ScreenBuffer Fenster #7/Grafik.
;$e000-$e3ff = ScreenBuffer Fenster #1/Farbe.
;$e400-$e7ff = ScreenBuffer Fenster #2/Farbe.
;$e800-$ebff = ScreenBuffer Fenster #3/Farbe.
;$ec00-$efff = ScreenBuffer Fenster #4/Farbe.
;$f000-$f3ff = ScreenBuffer Fenster #5/Farbe.
;$f400-$f7ff = ScreenBuffer Fenster #6/Farbe.
;$f800-$fbff = ScreenBuffer Fenster #7/Farbe.
.GD_SCRN_STACK		= GDA_SYSTEM +0

;64K-Speicherbank für Systemdaten:
;Bildschirmspeicher wird für RecoverRectangle/Menüs verwendet.
;$0000-$1f3f = Bildschirmspeicher /Grafik.
;$1f40-$2327 = Bildschirmspeicher /Farbe.
;Kennung für Hintergrundbild.
;$2380-$238f = Kennung für Hintergrundbild.
;Verzeichnis-Daten Fenster #1 bis #6.
;Hinweis: Fenster #0 ist der DeskTop, max. 6 Dateifenster möglich.
;Byte #00    = $00 - Datei nicht ausgewählt.
;              $FF - Datei ausgewählt.
;Byte #01    = $00 - Datei-Icon im Cache.
;              $FF - Datei-Icon nicht im Cache.
;Byte #02-31 = Datei-Eintrag.
;$2400-$37ff = Verzeichnis-Daten Fenster #1.
;$3800-$4bff = Verzeichnis-Daten Fenster #2.
;$4c00-$5fff = Verzeichnis-Daten Fenster #3.
;$6000-$73ff = Verzeichnis-Daten Fenster #4.
;$7400-$87ff = Verzeichnis-Daten Fenster #5.
;$8800-$9bff = Verzeichnis-Daten Fenster #6.
;Speicher für BAM-CRC-Daten (4x256 Bytes).
;$9c00-$9fff = BAM-CRC für Fenster #1.
;$a000-$a3ff = BAM-CRC für Fenster #2.
;$a400-$a7ff = BAM-CRC für Fenster #3.
;$a800-$abff = BAM-CRC für Fenster #4.
;$ac00-$afff = BAM-CRC für Fenster #5.
;$b000-$b3ff = BAM-CRC für Fenster #6.
;$b400-$ffff = Frei.
.GD_SYSDATA_BUF		= GDA_SYSTEM +1

;64K-Speicherbank für Icon-Daten:
;Hinweis:
;Fenster #0 ist der DeskTop, es sind
;max. 6 Dateifenster möglich.
;$0000-$27ff = Icon-Daten für Fenster #1.
;$2800-$4fff = Icon-Daten für Fenster #2.
;$5000-$77ff = Icon-Daten für Fenster #3.
;$7800-$9fff = Icon-Daten für Fenster #4.
;$a000-$c7ff = Icon-Daten für Fenster #5.
;$c800-$efff = Icon-Daten für Fenster #6.
.GD_ICONDATA_BUF	= GDA_SYSTEM +2

;2x64K-Speicherbank für GeoDesk:
.GD_RAM_GDESK1		= GDA_SYSTEM +3
.GD_RAM_GDESK2		= GDA_SYSTEM +4

;--- VLIR-Informationen: 200Bytes
;005
;Hinweis:
;Wird in "s.GD.00.Boot" über ":FillRam"
;initialisiert, um nicht installierte
;Module beim laden zu überspringen.
.GD_DACC_ADDR		= GDA_SYSTEM +5
.GD_DACC_ADDR_B		= GDA_SYSTEM +5 +GD_VLIR_COUNT*4

;--- Ende.
;205
.SYSVAR_END		= GDA_SYSTEM +5 +GD_VLIR_COUNT*4 +GD_VLIR_COUNT
.SYSVAR_SIZE = SYSVAR_END - SYSVAR_START
