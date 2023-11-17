; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

.SYSVAR_START

;*** 64K-Speicherbank für ScreenBuffer:
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
.GD_SCRN_STACK		b $00				;64K Speicher für ScreenBuffer #1-7.

;*** 64K-Speicher für Systemdaten:
;--- Bildschirmspeicher wird für RecoverRectangle/Menüs verwendet.
;$0000-$1f3f = Bildschirmspeicher /Grafik.
;$1f40-$2327 = Bildschirmspeicher /Farbe.
;--- Kennung für Hintergrundbild.
;$2380-$238f = Kennung für Hintergrundbild.
;--- Verzeichnis-Daten Fenster #1 bis #6.
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
;--- Speicher für BAM-CRC-Daten (4x256 Bytes).
;$9c00-$9fff = BAM-CRC für Fenster #1.
;$a000-$a3ff = BAM-CRC für Fenster #2.
;$a400-$a7ff = BAM-CRC für Fenster #3.
;$a800-$abff = BAM-CRC für Fenster #4.
;$ac00-$afff = BAM-CRC für Fenster #5.
;$b000-$b3ff = BAM-CRC für Fenster #6.
;$b400-$ffff = Frei.
.GD_SYSDATA_BUF		b $00				;64K Speicher für Systemdaten.
.vecDirDataRAM		w $ffff				;Fenster #0 = Desktop.
			w $2400				;Dateifenster #1.
			w $3800				;Dateifenster #2.
			w $4c00				;Dateifenster #3.
			w $6000				;Dateifenster #4.
			w $7400				;Dateifenster #5.
			w $8800				;Dateifenster #6.
.vecBAMDataRAM		w $ffff				;Fenster #0 = Desktop.
			w $9c00				;BAM-CRC Fenster #1.
			w $a000				;BAM-CRC Fenster #2.
			w $a400				;BAM-CRC Fenster #3.
			w $a800				;BAM-CRC Fenster #4.
			w $ac00				;BAM-CRC Fenster #5.
			w $b000				;BAM-CRC Fenster #6.

;--- Prüfcode für Hintergrundbild.
.backScrCode		b "MP3-BackScreen",NULL
:backScrCodeEnd
.backScrCodeLen		= ( backScrCodeEnd - backScrCode )
.backScrCodeRAM		= $2380

;*** 64K-Speicher für Icon-Daten:
;--- Icon/Grafik-Daten für Dateien.
;Hinweis: Fenster #0 ist der DeskTop, max. 6 Dateifenster möglich.
;$0000-$27ff = Icon-Daten für Fenster #1.
;$2800-$4fff = Icon-Daten für Fenster #2.
;$5000-$77ff = Icon-Daten für Fenster #3.
;$7800-$9fff = Icon-Daten für Fenster #4.
;$a000-$c7ff = Icon-Daten für Fenster #5.
;$c800-$efff = Icon-Daten für Fenster #6.
.GD_ICONDATA_BUF	b $00				;64K Speicher für Systemdaten.
.vecIconDataRAM		w $ffff				;Fenster #0 = Desktop.
			w $0000				;Dateifenster #1.
			w $2800				;Dateifenster #2.
			w $5000				;Dateifenster #3.
			w $7800				;Dateifenster #4.
			w $a000				;Dateifenster #5.
			w $c800				;Dateifenster #6.

;*** 2x64K-Speicher für GeoDesk:
.GD_RAM_GDESK1		b $00				;64K Speicher #1 für GeoDesk.
.GD_RAM_GDESK2		b $00				;64K Speicher #2 für GeoDesk.

;*** Systeminformationen.
.GD_CLASS		t "-SYS_CLASS"

;*** AppLink-Konfigurationsdatei.
.GD_APPLCLASS		b "GD_AppLinks V1.1",NULL

;*** Startadresse VLIR im DACC.
;Bereich $0000-$01FF ist reserviert für
;Original EnterDeskTop-Routine.
.GD_START_DACC		= $0200

;*** Speicher für VLIR-Informationen RAM-GeoDesk.
.GD_DACC_ADDR		s GD_VLIR_COUNT * 4		;Start/Größe.
.GD_DACC_ADDR_B		s GD_VLIR_COUNT * 1		;Speicherbank.

;*** VLIR-Module.
.GD_VLIR_ACTIVE		b $00

;*** Name Hauptprogramm.
.GD_SYS_NAME		s 17

;*** Laufwerk, von dem GeoDesk gestartet wurde.
.BootDrive		b $00
.BootPart		b $00
.BootType		b $00
.BootMode		b $00
.BootSDir		b $00,$00
.BootRBase		b $00

;*** Zwischenspeicher für Laufwerkswechsel.
.TempDrive		b $00
.TempMode		b $00
.TempPart		b $00
.TempSDir		b $00,$00

;*** Laufwerk für AppLink-Konfigurationsdatei.
.LinkDrive		b $00
.LinkPart		b $00
.LinkType		b $00
.LinkMode		b $00
.LinkSDir		b $00,$00
.LinkRBase		b $00

;*** Quelle/Ziel.
;Für DiskCopy:
;Laufwerk 8-11, CMD-Part,Tr/Se-SubDir.
;
.sysSource		b $00,$00,$00,$00
.sysTarget		b $00,$00,$00,$00

;Bei Datei-Operationen:
;Quelle und Ziel zwischen zwei Fenster,
;z.B. Kopieren/Verschieben.
;Enthält die Fenster-Nr. aus WM_STACK.
;
.winSource		b $00
.winTarget		b $00

;Disk-/Dateien kopieren:
;Quell-/Ziel-Fenster aktualisieren.
;Der Wert wird für GD_RELOAD_DIR beim
;aktualisieren des Fensters gesetzt.
;Siehe TopSym.GD -> SET_LOAD-Flag.
;
.updateSource		b $00
.updateTarget		b $00

.SYSVAR_END
.SYSVAR_SIZE = SYSVAR_END - SYSVAR_START
