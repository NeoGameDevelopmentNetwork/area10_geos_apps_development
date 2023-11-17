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

;******************************************************************************
.DskDrvBaseL		b < R1_ADDR_DSKDEV_A
			b < R1_ADDR_DSKDEV_B
			b < R1_ADDR_DSKDEV_C
			b < R1_ADDR_DSKDEV_D
.DskDrvBaseH		b > R1_ADDR_DSKDEV_A
			b > R1_ADDR_DSKDEV_B
			b > R1_ADDR_DSKDEV_C
			b > R1_ADDR_DSKDEV_D

;*** Zusätzliche Variablen für Laufwerkstreiber *******************************
.doubleSideFlg		s $04
.drivePartData		s $04

;******************************************************************************
.RealDrvType		s $04				; C=1541,71,81 = $01,$02,$03
							; C=1541,81 Shadowed = $41,$43
							; C=RAM1541,71,81 = $81,$82,$83
							; CMD FD,HD,RL = $1x,$2x,$3x
.RealDrvMode		s $04				; $80 = Laufwerk unterstützt CMD-Partitionen.
							; $40 = Unterstützt CMD-Verzeichnisse.
							; $20 = FastDisk / RAM-Laufwerk.

;******************************************************************************
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

;******************************************************************************
.Flag_Optimize		b $00				;$00 = GEOS für SCPU       optimieren.
							;$03 = GEOS für SCPU nicht optimieren.

;******************************************************************************
;    Definiert die Jahrtausendangabe da RTC-Uhren nur das Jahr von 0-255
;    erzeugen. Wird über den GEOS.Editor beim setzen der Uhrzeit aktualisiert.
.millenium		b 20

;******************************************************************************
.Flag_LoadPrnt		b $00				;$80 = Druckertreiber von Diskette.
							;$00 = Druckertreiber aus REU laden.

;******************************************************************************
;    Dieser wird beim C64 doppelt verwaltet. Wird der Name nur in ":PrintName"
;    verwaltet, kann das Kernal nicht feststellen, ob dieser Druckertreiber
;    bereits im RAM ist oder ob er zuerst von Diskette nachgeladen und in die
;    Speichererweiterung kopiert werden muß!
.PrntFileNameRAM	s 17

;******************************************************************************
.Flag_Spooler		b $00				;$80 = Spooler installiert.
							;$40 = Spooler-Menü starten.
							;$3f = Zähler für Spooler.
.Flag_SpoolMinB		b $01				;Erste  Bank für Druckerspooler.
.Flag_SpoolMaxB		b $02				;Letzte Bank für Druckerspooler.
.Flag_SpoolADDR		w $0000				;Position in Zwischenspeicher.
			b $01
.Flag_SpoolCount	b $03				;Verzögerung für Druckerspooler.
.Flag_SplCurDok		b $00				;Aktuelles Dokument.
.Flag_SplMaxDok		b $00				;Max. Anzahl Dokumente im Speicher.

;******************************************************************************
.Flag_TaskAktiv		b $80				;$00 = TaskManager aktiv.
.Flag_TaskBank		b $00				;Bank für TaskManager.
.Flag_ExtRAMinUse	b $00				;$80 = SwapFile  aktiv.
							;$40 = Dialogbox aktiv.

;******************************************************************************
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
;******************************************************************************
.Flag_CrsrRepeat	b $02				;Cursorgeschwindigkeit 0-15

;******************************************************************************
;    Modus für Hintergrundbild wird in sysRAMFlg, Bit%3 verwaltet.
.BackScrPattern		b $02				;Füllmuster für Hintergrundgrafik. Dieses Muster wird
							;verwendet wenn keine GeoPaint-Hintergrundgrafik in
							;den Bildspeicher geladen wurde.

;******************************************************************************
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

;******************************************************************************
if Flag64_128 = TRUE_C64
.DB_StdBoxSize		b $20,$7f
			w $0040,$00ff
endif

if Flag64_128 = TRUE_C128
.DB_StdBoxSize		b $20,$7f
			w $0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W
endif

;******************************************************************************
.Flag_SetMLine		b $00				;$00 = Linien nicht zeichnen.
							;$80 = Linien zeichnen.
.Flag_MenuStatus	b $c0				;$00 = Menüs nicht invertieren.
							;$80 = Menüs       invertieren.
							;$40 = Menüs nie   nach unten verlassen.
							;$20 = Menü Doppelflash anzeigen.
							;$10 = Register-Menü: Icon-Status anzeigen.
:DM_LastEntry		s $06
:DM_LastNumEntry	b $00

;******************************************************************************
;Siehe Datei "-G3_MP3_COLOR".
