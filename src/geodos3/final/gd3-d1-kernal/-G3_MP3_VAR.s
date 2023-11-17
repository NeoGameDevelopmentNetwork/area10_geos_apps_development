; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Speicher bis $9F7E mit $00-Bytes auffüllen.
;******************************************************************************
.Mem_9F7E_Temp		e $9f7e
.Mem_9F7E
;******************************************************************************

;******************************************************************************
;*** Neue MP3-Variablen, gültig für alle Tasks!
;******************************************************************************
; Anzahl der Bytes in SymbTab_1, Variable ":R3_SIZE_MPVARBUF" eintragen!
.OS_VAR_MP

;*** Ladeadressen der Laufwerkstreiber.
.DskDrvBaseL		b < R1_ADDR_DSKDEV_A
			b < R1_ADDR_DSKDEV_B
			b < R1_ADDR_DSKDEV_C
			b < R1_ADDR_DSKDEV_D
.DskDrvBaseH		b > R1_ADDR_DSKDEV_A
			b > R1_ADDR_DSKDEV_B
			b > R1_ADDR_DSKDEV_C
			b > R1_ADDR_DSKDEV_D

;*** Zusätzliche Variablen für Laufwerkstreiber.
.doubleSideFlg		s $04
.drivePartData		s $04

;*** Echte Laufwerksbezeichnungen.
.RealDrvType		s $04				; C=1541,71,81 = $01,$02,$03
							; C=1541,81 Shadowed = $41,$43
							; C=RAM1541,71,81 = $81,$82,$83
							; CMD FD,HD,RL = $1x,$2x,$3x
.RealDrvMode		s $04				; $80 = Laufwerk unterstützt CMD-partitionen.
							; $40 = Laufwerk unterstützt CMD-Verzeichnisse.
							; $20 = Physikalisches Laufwerk mit 20Mhz.

;*** Speicherbelegung.
.RamBankInUse		s RAM_SIZE / 8 *2
							; 128 Bit, je 2 Bit für eine 64K-Bank = 4MByte.
							; Bits #7,6 = Bank #0, Bits #5,4 = Bank #1, usw...
							; %00 = Frei, %01 = Appl., %10 = Disk, %11 = GEOS.
.RamBankFirst		w $0000				;Lage des GEOS-DACC in REU/RL/RCARD.
.GEOS_RAM_TYP		b $00				;Typ Speichererweiterung
							;(Bit 7 = RL; Bit 6 = REU, Bit 5 = BBG; Bit 4 = SCPU)
.MP3_64K_SYSTEM		b $0f				;Bank für GEOS-System #2.
.MP3_64K_DATA		b $0e				;Bank für SwapFile u.ä.
.MP3_64K_DISK		b $00				;Bank für Laufwerkstreiber.

;*** SuperCPU.
.Flag_Optimize		b $00				;$00 = GEOS für SCPU       optimieren.
							;$03 = GEOS für SCPU nicht optimieren.

;*** Jahrtausend-Byte.
.millenium		b 20

;*** Druckertreiber.
.Flag_LoadPrnt		b $00				;$80 = Druckertreiber von Diskette.
							;$00 = Druckertreiber aus REU laden.

;*** Name des Druckertreibers im RAM.
;    Dieser wird beim C64 doppelt verwaltet. Wird der Name nur in ":PrintName"
;    verwaltet, kann das Kernal nicht feststellen, ob dieser Druckertreiber
;    bereits im RAM ist oder ob er zuerst von Diskette nachgeladen und in die
;    Speichererweiterung kopiert werden muß!
.PrntFileNameRAM	s 17

;*** Spooler.
.Flag_Spooler		b $00				;$80 = Spooler installiert.
							;$40 = Spooler-Menü starten.
							;$3f = Zähler für Spooler.
.Flag_SpoolMinB		b $00				;Erste  Bank für Druckerspooler.
.Flag_SpoolMaxB		b $00				;Letzte Bank für Druckerspooler.
.Flag_SpoolADDR		w $0000				;Position in Zwischenspeicher.
			b $00
.Flag_SpoolCount	b $00				;Verzögerung für Druckerspooler.
.Flag_SplCurDok		b $00				;Aktuelles Dokument.
.Flag_SplMaxDok		b $00				;Max. Anzahl Dokumente im Speicher.

;*** TaskManager.
.Flag_TaskAktiv		b $80				;$00 = TaskManager aktiv.
.Flag_TaskBank		b $00				;Bank für TaskManager.
.Flag_ExtRAMinUse	b $00				;$80 = SwapFile  aktiv.
							;$40 = Dialogbox aktiv.

;*** Bildschirmschoner.
.Flag_ScrSvCnt		b $0f				;Aktivierungszeit ScreenSaver.
.Flag_ScrSaver		b $80				;$00 = ScreenSaver aktivieren.
							;$20 = ScreenSaver runterzählen.
							;$40 = ScreenSaver initialisieren.
							;$80 = ScreenSaver abschalten.
:OS_VAR_MP_END

;******************************************************************************
;*** Speicher bis $A000 mit $00-Bytes auffüllen.
;******************************************************************************
.Mem_OSMP_Temp		g OS_VAR_MP + R3_SIZE_MPVARBUF
.Mem_OSMP
;******************************************************************************

;******************************************************************************
;*** Neue MP3-Variablen, werden für jeden Task getrennt verwaltet.
;******************************************************************************
;*** Variablen Tastatur.
.Flag_CrsrRepeat	b $02				;Cursorgeschwindigkeit 0-15

;*** Variablen Hintergrund.
;    Modus für Hintergrundbild wird in sysRAMFlg, Bit%3 verwaltet.
.BackScrPattern		b $02				;Füllmuster für Hintergrundgrafik. Dieses Muster wird
							;verwendet wenn keine GeoPaint-Hintergrundgrafik in
							;den Bildspeicher geladen wurde.

;*** Variablen Dialogbox.
.Flag_SetColor		b $80				;$00 = Nicht setzen.
							;$40 = Farbe nur bei Standard-Bit.
							;$80 = Immer setzen.
.Flag_ColorDBox		b $00				;$80 = Farbe in Dialogbox unterdrücken.
.Flag_IconMinX		b $05				;Mindestgröße für Icons mit Farbe.
							;Sollen alle Icons ohne Farbe dargestellt werdeb, so
							;ist hier Bit #7 zu setzen. Damit wird die IconGröße
							;nie erreicht => Keine Farbe.
.Flag_IconMinY		b $10				;Mindestgröße für Icons mit Farbe.
.Flag_IconDown		b $05				;Ab xyz Pixel über #0 Icon nach unten verschieben,
							;sonst auf 8x8 Pixel nach oben verschieben.
.Flag_DBoxType		b $00				;Kopfbyte der Dialogboxtabelle.
.Flag_GetFiles		b $00				;$00 = GetFiles nicht aktiv.
							;      (Wird berechnet!)
.DB_GFileType		b $00
.DB_GFileClass		w $0000
.DB_GetFileEntry	b $00

;*** Größe der Standardbox.
.DB_StdBoxSize		b $20,$7f
			w $0040,$00ff

;*** Variablen Menu.
.Flag_SetMLine		b $00				;$00 = Linien nicht zeichnen.
							;$80 = Linien zeichnen.
.Flag_MenuStatus	b $c0				;$00 = Menüs nicht invertieren.
							;$80 = Menüs       invertieren.
							;$40 = Menüs nie   nach unten verlassen.
							;$20 = Menü Doppelflash anzeigen.
:DM_LastEntry		s $06
:DM_LastNumEntry	b $00

;*** Farbtabelle.
.C_FarbTab						;Beginn der Farbtabelle.
.C_Balken		b $01				;Scrollbalken.
.C_Register		b $0e				;Karteikarten: Aktiv.
.C_RegisterOff		b $03				;Karteikarten: Inaktiv.
.C_RegisterBack		b $0e				;Karteikarten: Hintergrund.
.C_Mouse		b $66				;Mausfarbe.
.C_DBoxTitel		b $16				;Dialogbox: Titel.
.C_DBoxBack		b $0e				;Dialogbox: Hintergrund + Text.
.C_DBoxDIcon		b $01				;Dialogbox: System-Icons.
.C_FBoxTitel		b $16				;Dateiauswahlbox: Titel.
.C_FBoxBack		b $0e				;Dateiauswahlbox: Hintergrund + Text.
.C_FBoxDIcon		b $01				;Dateiauswahlbox: System-Icons.
.C_FBoxFiles		b $03				;Dateiauswahlbox: Dateifenster.
.C_WinTitel		b $10				;Fenster: Titel.
.C_WinBack		b $0f				;Fenster: Hintergrund.
.C_WinShadow		b $00				;Fenster: Schatten.
.C_WinIcon		b $0d				;Fenster: System-Icons.
.C_PullDMenu		b $03				;PullDown-Menu.
.C_InputField		b $01				;Text-Eingabefeld.
.C_InputFieldOff	b $0f				;Inaktives Optionsfeld.
.C_GEOS_BACK		b $bf				;GEOS-Standard: Hintergrund.
.C_GEOS_FRAME		b $00				;GEOS-Standard: Rahmen.
.C_GEOS_MOUSE		b $66				;GEOS-Standard: Mauszeiger.
.C_FarbTabEnd
