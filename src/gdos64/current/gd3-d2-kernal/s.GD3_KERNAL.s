; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;   GEOS-Systemkernal
;   (c)1985-1997 BSW
;   (w)1997-2023 Markus Kanet
;******************************************************************************

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "opt.GDOS.Rev"
			t "SymbTab_1"
			t "SymbTab_CSYS"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_DISK"
			t "SymbTab_GRFX"
			t "SymbTab_GSPR"
			t "SymbTab_DBOX"
			t "SymbTab_FBOX"
endif

;*** GEOS-Header.
			n "tmp.GD_Kernal64"
			c "GD_KERNAL   V3.0"
			t "opt.Author"
			f DATA
			z $80 ;nur GEOS64

			o OS_LOW ; = $9D80

;******************************************************************************
;*** GEOS-Kernal-Konfiguration.
;******************************************************************************
; Definiert den Assemblierungsvorgang
; für den aktuellen GEOS-Kernal.

;--- RAM-Treiber:
; Mögliche Optionen:
; :_BUILD_RAM = RAM_REU
; :_BUILD_RAM = RAM_BBG
; :_BUILD_RAM = RAM_RL
; :_BUILD_RAM = RAM_SCPU
;               => _BUILD_SCPU = TRUE
;
; Hinweis: RAM_TYPE=RAM_RL benötigt den
;          meisten Speicher!
:_BUILD_RAM		= RAM_RL

;--- SCPU-Treiber:
; Wenn _BUILD_SCPU = TRUE, dann wird
; der GEOS-Kernal für die CMD-SuperCPU
; optimiert und funktioniert nicht mehr
; ohne eine SuperCPU!
if _BUILD_RAM = RAM_SCPU
:_BUILD_SCPU		= TRUE
else
:_BUILD_SCPU		= FALSE
endif

;*** Zusätzliche RAM-Symboltabellen:
if _BUILD_RAM = RAM_SCPU
			t "SymbTab_SCPU"
endif
if _BUILD_RAM = RAM_RL
			t "SymbTab_RLNK"
endif

;*** GEOS-Version. Nicht $30, da kein echtes GEOS 3.0!!!
;    $20 belassen, damit Programme für GEOSV2 auch unter GDOS64 laufen.
:_BUILD_VER		= $20

;******************************************************************************
;*** System-Variablen.
;******************************************************************************
if .p
:RAM_MAX_SIZE     = $40          ;64 * 64K = 4096K = 4Mb -> SymbTab_GDOS!
.MAX_SPOOL_DOC    = $0f          ;Max. 15 Dokumente im Spoolerspeicher.
.MAX_SPOOL_STD    = $04          ;Vorgabe für Größe Spoolerspeicher.
.STD_SPOOL_DELAY  = $06          ;Verzögerungszeit für Spooler: 15sec.
.MAX_TASK_STD     = $03          ;Wert darf nicht größer "9 Tasks" sein!
.MAX_FILES_BROWSE = 255          ;Anzahl Dateien in Dialogbox.
endif

;*** Datei einlesen.
:xReadFile		jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Laufwerksfehler?
			beq	:0			; => Nein, weiter...
			rts

::0			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Vec_diskBlkBuf		;Zeiger auf Zwischenspeicher.

			lda	#$02
			sta	r5L

			lda	r1H			;Ersten Sektor in Tabelle
			sta	fileTrScTab+3		;eintragen.
			lda	r1L
			sta	fileTrScTab+2

::1			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:7			;Ja, Abbruch...

			ldy	#$fe			;Anzahl Bytes in Sektor
			lda	diskBlkBuf+0		;berechnen.
			bne	:2
			ldy	diskBlkBuf+1
			dey
			beq	:6

::2			lda	r2H			;Buffer voll ?
			bne	:3			;Nein, weiter...
			cpy	r2L
			bcc	:3
			beq	:3
			ldx	#$0b			;Fehler "Buffer full" setzen
			bne	:7			;und Abbruch...
::3			sty	r1L			;Anzahl Bytes merken.

			lda	#RAM_64K		;64Kb RAM einblenden.
			sta	CPU_DATA

::4			lda	diskBlkBuf+1,y		;Daten in RAM übertragen.
			dey
			sta	(r7L),y
			bne	:4

			lda	#KRNL_IO_IN		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	r1L			;Startadresse für näachste
			clc				;Daten vorbereiten.
			adc	r7L
			sta	r7L
			bcc	:5
			inc	r7H
::5			lda	r2L			;Buffergröße korrigieren.
			sec
			sbc	r1L
			sta	r2L
			bcs	:6
			dec	r2H
::6			inc	r5L			;Sektorzähler korrigieren.
			inc	r5L

			ldy	r5L
			lda	diskBlkBuf +1		;Sektor-Adresse in Tabelle
			sta	r1H			;eintragen.
			sta	fileTrScTab+1,y
			lda	diskBlkBuf +0
			sta	r1L
			sta	fileTrScTab+0,y
			bne	:1			;Max. 127 Sektoren lesen.
			tax				;xReg = $00, OK!
::7			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Zeiger auf Sektorspeicher setzen.
:Vec_diskBlkBuf		lda	#> diskBlkBuf		;Zeiger auf Zwischenspeicher.
			sta	r4H
			lda	#< diskBlkBuf
			sta	r4L
			rts

;*** Datei auf Diskette speichern.
:xWriteFile		jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Laufwerksfehler?
			bne	:2			; => Ja, Abbruch...
			sta	VerWriteFlag		;Datei schreiben.

			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#> diskBlkBuf
			sta	r4H
			lda	#< diskBlkBuf
			sta	r4L

			lda	r6H
			pha
			lda	r6L
			pha
			lda	r7H
			pha
			lda	r7L
			pha
			jsr	VerWriteFile		;Datei speichern.
			pla
			sta	r7L
			pla
			sta	r7H
			pla
			sta	r6L
			pla
			sta	r6H
			txa
			bne	:1
			dec	VerWriteFlag		;Flag für "Datei vergleichen".
			jsr	VerWriteFile		;Datei vergleichen.
::1			jmp	DoneWithIO		;I/O-Bereich ausblenden.
::2			rts

;*** Sektor schreiben/vergleichen.
:VerWriteSek		lda	VerWriteFlag		;Datei schreiben/vergleichen ?
			beq	:1			; -> Datei schreiben.
			jmp	VerWriteBlock		; -> Datei vergleichen.
::1			jmp	WriteBlock

;*** Datei schreiben oder vergleichen.
;    Abhängig von ":VerWriteFlag".
;    ":r6" zeigt auf Tr/Se-Tabelle.
:VerWriteFile		ldy	#$00
			lda	(r6L),y			;Letzer Sektor erreicht ?
			beq	:3			;Ja, Ende...
			sta	r1L			;Sektor-Adresse kopieren.
			iny
			lda	(r6L),y
			sta	r1H
			dey
			jsr	SetVecToSek		;Zeiger auf nächsten Sektor.

			lda	(r6L),y			;Verkettungszeiger berechnen.
			sta	(r4L),y			;(Für den letzten Sektor auch
			iny				; Anzahl der Bytes eintragen!)
			lda	(r6L),y
			sta	(r4L),y

			ldy	#$fe			;Immer 255 Bytes schreiben.
			lda	#RAM_64K		;64Kb-RAM aktivieren.
			sta	CPU_DATA

::1			dey
			lda	(r7L),y			;Daten aus Speicher lesen und
			sta	diskBlkBuf+2,y		;in Zwischenspeicher kopieren.
			tya
			bne	:1

			lda	#KRNL_IO_IN		;I/O-Bereich aktivieren.
			sta	CPU_DATA

			jsr	VerWriteSek		;Sektor schreiben/vergleichen.
			txa				;Diskettenfehler ?
			bne	:4			;Ja, Abbruch...

			clc				;Zeiger auf Speicher
			lda	#$fe			;korrigieren.
			adc	r7L
			sta	r7L
			bcc	:2
			inc	r7H
::2			jmp	VerWriteFile		;Nächster Sektor.

::3			tax
::4			rts

;*** Zeiger auf ":fileTrSeTab".
:SetVecToSek		clc				;Externes Label wegen C128!
			lda	#$02
			adc	r6L
			sta	r6L
			bcc	:1
			inc	r6H
::1			rts

;******************************************************************************
;*** Speicher bis $9E9F mit $00-Bytes auffüllen.
;******************************************************************************
:_60T			e $9e9f
:_60
;******************************************************************************

;*** Seriennummer des GEOS-Systems.
;Wird nur dann benötigt wenn eine
;bootfähige GDOS64-Version erstellt
;werden soll.
;
;Wird GDOS über das Update installiert,
;dann wird die ID des laufenden GEOS-
;Systems automatisch übernommen.
;
:SerialNumber		w $0c64  ;Neue Standard-ID.
;			w $962b  ;Markus Kanet

;******************************************************************************
;*** Speicher bis $9E9F mit $00-Bytes auffüllen.
;******************************************************************************
:_61T			e $9ea1
:_61
;******************************************************************************

;*** Laufwerkstreiber-Aktionen vorbereiten.
:InitForDskDvJob	ldy	curDrive		;yReg unverändert!!!
:InitCurDskDvJob	jsr	DoneWithDskDvJob	;RAM-Register zurücksetzen.

			lda	DskDrvBaseL -8,y	;Zeiger auf Laufwerkstreiber
			sta	r1L			;in REU in ZeroPage kopieren.
			lda	DskDrvBaseH -8,y
			sta	r1H
:NoFunc7		rts

;*** Laufwerkstreiber-Aktionen abschließen.
:DoneWithDskDvJob	ldx	#$06
::1			lda	r0L ,x
			pha
			lda	:2  ,x
			sta	r0L ,x
			pla
			sta	:2  ,x
			dex
			bpl	:1
			rts

;*** Transferdaten für ":SetDevice".
::2			w $9000				;RAM-Adresse Laufwerkstreiber.
			w $0000				;REU-Adresse Laufwerkstreiber.
			w $0d80				;Länge Laufwerkstreiber.
			b $00				;BANK in REU.

;*** Auf <F1>-Taste prüfen.
:TestHelpSystem		ldy	keyData
			dey
			bne	xCallRoutine
			bit	HelpSystemActive
			bmi	NoFunc7

;*** GEOS-Routine aufrufen.
; AKKU = Zeiger auf LOW -Byte.
; xReg = Zeiger auf HIGH-Byte.
:xCallRoutine		cmp	#$00
			bne	:1
			cpx	#$00			;Adresse = $0000 ?
			beq	NoFunc7			;Ja, nicht ausführen.
::1			sta	CallRoutVec +0
			stx	CallRoutVec +1
			jmp	(CallRoutVec)

;*** GEOS-Systeminterrupt!
:GEOS_IRQ		cld
			sta	IRQ_BufAkku
			pla
			pha
			and	#%00010000		;Standard IRQ ?
			beq	:1			;Ja, weiter...
			pla
			jmp	(BRKVector)		;BRK-Abbruch.

::1			txa				;Register zwischenspeichern.
			pha
			tya
			pha

			lda	CallRoutVec   +1	;Variablen zwischenspeichern.
			pha
			lda	CallRoutVec   +0
			pha
			lda	returnAddress +1
			pha
			lda	returnAddress +0
			pha

			ldx	#$00
::2			lda	r0L,x
			pha
			inx
			cpx	#$20
			bne	:2

			lda	CPU_DATA		;CPU-Register speichern.
			pha
			lda	#IO_IN			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	dblClickCount		;Auf Doppelklick testen ?
			beq	:3			;Nein, weiter...
			dec	dblClickCount		;Zähler korrigieren.
::3			ldy	keyMode			;Erste Taste einlesen ?
			beq	:4			;Ja, weiter...
			iny				;Taste in ":currentKey" ?
			beq	:4			;Nein, weiter...
			dec	keyMode
::4			jsr	GetMatrixCode

			lda	AlarmAktiv		;Zähler für Alarm-Wiederholung
			beq	:5			;gesetzt ?  => Nein, weiter...
			dec	AlarmAktiv		;Zähler korrigieren.

::5			lda	intTopVector +0		;IRQ/GEOS.
			ldx	intTopVector +1
			jsr	CallRoutine
			lda	intBotVector +0		;IRQ/Anwender.
			ldx	intBotVector +1
			jsr	CallRoutine

			lda	#$01			;Raster-IRQ-Flag setzen.
			sta	grirq

			pla				;CPU-Register wieder
			sta	CPU_DATA		;zurücksetzen.

			ldx	#$1f			;Variablen zurückschreiben.
::6			pla
			sta	r0L,x
			dex
			bpl	:6

			pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1
			pla
			sta	CallRoutVec   +0
			pla
			sta	CallRoutVec   +1

			pla				;Register wieder einlesen.
			tay
			pla
			tax
			lda	IRQ_BufAkku

;*** Einsprung bei RESET/NMI.
:IRQ_END		rti

;******************************************************************************
;*** Speicher bis $9F68 mit $00-Bytes auffüllen.
;******************************************************************************
:_01T			e $9f68
:_01
;******************************************************************************
:HelpSystemActive	b $00
:HelpSystemBank		b $01
:HelpSystemDrive	b $00
:HelpSystemPart		b $00
:HelpSystemFile		s 17
:HelpSystemPage		b $00

;******************************************************************************
;*** Speicher bis $9F7E mit $00-Bytes auffüllen.
;******************************************************************************
:_15T			e $9f7e
:_15
;******************************************************************************

;******************************************************************************
;*** GDOS-Variablen Teil #1.
;*** Gültig für alle Tasks!
;******************************************************************************
; Anzahl der Bytes in SymbTab_GDOS bei
; Variable ":EXTVAR_SIZE" setzen!
;:EXTVAR_BASE

;*** Ladeadressen der Laufwerkstreiber.
:DskDrvBaseL		b < R1A_DSKDEV_A
			b < R1A_DSKDEV_B
			b < R1A_DSKDEV_C
			b < R1A_DSKDEV_D
:DskDrvBaseH		b > R1A_DSKDEV_A
			b > R1A_DSKDEV_B
			b > R1A_DSKDEV_C
			b > R1A_DSKDEV_D

;*** Zusätzliche Variablen für Laufwerkstreiber.
:doubleSideFlg		s $04
:drivePartData		s $04

;*** Echte Laufwerksbezeichnungen.
:RealDrvType		s $04				;C=1541,71,81 = $01,$02,$03
							;C=1541,81 Shadowed = $41,$43
							;C=RAM1541,71,81 = $81,$82,$83
							;CMD FD,HD,RL = $1x,$2x,$3x
:RealDrvMode		s $04				;$80 = Laufwerk unterstützt CMD-partitionen.
							;$40 = Laufwerk unterstützt CMD-Verzeichnisse.
							;$20 = Physikalisches Laufwerk mit 20Mhz.

;*** Speicherbelegung.
:RamBankInUse		s RAM_MAX_SIZE / 8 *2
							;128 Bit, je 2 Bit für eine 64K-Bank = 4MByte.
							;Bits #7,6 = Bank #0, Bits #5,4 = Bank #1, usw...
							;Banktyp: %00 = Frei.
							;         %01 = Anwendung.
							;         %10 = Laufwerk.
							;         %11 = System.
:RamBankFirst		w $0000				;Lage des GEOS-DACC in REU/RL/RCARD.
:GEOS_RAM_TYP		b $00				;Typ Speichererweiterung
							;(Bit 7 = RL; Bit 6 = REU, Bit 5 = BBG; Bit 4 = SCPU)
:MP3_64K_SYSTEM		b $0f				;Bank für GEOS-System #2.
:MP3_64K_DATA		b $0e				;Bank für SwapFile u.ä.
:MP3_64K_DISK		b $00				;Bank für Laufwerkstreiber.

;*** SuperCPU.
:Flag_Optimize		b $00				;$00 = GEOS für SCPU       optimieren.
							;$03 = GEOS für SCPU nicht optimieren.

;*** Jahrtausend-Byte.
:millenium		b 20

;*** Druckertreiber.
:Flag_LoadPrnt		b $00				;$80 = Druckertreiber von Diskette.
							;$00 = Druckertreiber aus REU laden.

;*** Name des Druckertreibers im RAM.
;    Dieser wird beim C64 doppelt verwaltet. Wird der Name nur in ":PrintName"
;    verwaltet, kann das Kernal nicht feststellen, ob dieser Druckertreiber
;    bereits im RAM ist oder ob er zuerst von Diskette nachgeladen und in die
;    Speichererweiterung kopiert werden muß!
:PrntFileNameRAM	s 17

;*** Spooler.
:Flag_Spooler		b $00				;$80 = Spooler installiert.
							;$40 = Spooler-Menü starten.
							;$3f = Zähler für Spooler.
:Flag_SpoolMinB		b $00				;Erste  Bank für Druckerspooler.
:Flag_SpoolMaxB		b $00				;Letzte Bank für Druckerspooler.
:Flag_SpoolADDR		w $0000				;Position in Zwischenspeicher.
			b $00
:Flag_SpoolCount	b $00				;Verzögerung für Druckerspooler.
:Flag_SplCurDok		b $00				;Aktuelles Dokument.
:Flag_SplMaxDok		b $00				;Max. Anzahl Dokumente im Speicher.

;*** TaskManager.
:Flag_TaskAktiv		b $80				;$00 = TaskManager aktiv.
:Flag_TaskBank		b $00				;Bank für TaskManager.
:Flag_ExtRAMinUse	b $00				;$80 = SwapFile  aktiv.
							;$40 = Dialogbox aktiv.

;*** Bildschirmschoner.
:Flag_ScrSvCnt		b $0f				;Aktivierungszeit ScreenSaver.
:Flag_ScrSaver		b $80				;$00 = ScreenSaver aktivieren.
							;$20 = ScreenSaver runterzählen.
							;$40 = ScreenSaver initialisieren.
							;$80 = ScreenSaver abschalten.

;******************************************************************************
;*** Speicher bis $9FCE mit $00-Bytes auffüllen.
;******************************************************************************
:_17T			g EXTVAR_BASE + EXTVAR_SIZE
:_17
;******************************************************************************

;******************************************************************************
;*** GDOS-Variablen Teil #2.
;*** Für jeden Task getrennt verwaltet.
;******************************************************************************
;*** Variablen Tastatur.
:Flag_CrsrRepeat	b $02				;Cursor-Geschwindigkeit 0-15

;*** Variablen Hintergrund.
;    Modus für Hintergrundbild wird in sysRAMFlg, Bit%3 verwaltet.
:BackScrPattern		b $02				;Füllmuster für Hintergrundgrafik. Dieses Muster wird
							;verwendet wenn keine GeoPaint-Hintergrundgrafik in
							;den Bildspeicher geladen wurde.

;*** Variablen Dialogbox.
:Flag_SetColor		b $80				;$00 = Nicht setzen.
							;$40 = Farbe nur bei Standard-Bit.
							;$80 = Immer setzen.
:Flag_ColorDBox		b $00				;$80 = Farbe in Dialogbox unterdrücken.
:Flag_IconMinX		b $05				;Mindestgröße für Icons mit Farbe.
							;Sollen alle Icons ohne Farbe dargestellt werdeb, so
							;ist hier Bit #7 zu setzen. Damit wird die IconGröße
							;nie erreicht => Keine Farbe.
:Flag_IconMinY		b $10				;Mindestgröße für Icons mit Farbe.
:Flag_IconDown		b $05				;Ab xyz Pixel über #0 Icon nach unten verschieben,
							;sonst auf 8x8 Pixel nach oben verschieben.
:Flag_DBoxType		b $00				;Kopfbyte der Dialogboxtabelle.
:Flag_GetFiles		b $00				;$00 = GetFiles nicht aktiv.
							;      (Wird berechnet!)

:DB_GFileType		b $00
:DB_GFileClass		w $0000
:DB_GetFileEntry	b $00

;*** Größe der Standardbox.
:DB_StdBoxSize		b $20,$7f
			w $0040,$00ff

;*** Variablen Menu.
:Flag_SetMLine		b $00				;$00 = Linien nicht zeichnen.
							;$80 = Linien zeichnen.
:Flag_MenuStatus	b $c0				;$80 = Menüs einfach invertieren.
							;$40 = Menüs nie nach unten verlassen.
							;$20 = Menüs doppelt invertieren.
							;$10 = Register-Menü: Icon-Status anzeigen.
:DM_LastEntry		s $06
:DM_LastNumEntry	b $00

;******************************************************************************
;*** Speicher bis $9FEA mit $00-Bytes auffüllen.
;******************************************************************************
:_18T			e COLVAR_BASE
:_18
;******************************************************************************

;*** Farbtabelle.
;:COLVAR_BASE						;Beginn der Farbtabelle.
:C_Balken		b $01				;Scrollbalken.
:C_Register		b $0e				;Karteikarten: Aktiv.
:C_RegisterOff		b $03				;Karteikarten: Inaktiv.
:C_RegisterBack		b $0e				;Karteikarten: Hintergrund.
:C_Mouse		b $66				;Mausfarbe.
:C_DBoxTitel		b $16				;Dialogbox: Titel.
:C_DBoxBack		b $0e				;Dialogbox: Hintergrund + Text.
:C_DBoxDIcon		b $01				;Dialogbox: System-Icons.
:C_FBoxTitel		b $16				;Dateiauswahlbox: Titel.
:C_FBoxBack		b $0e				;Dateiauswahlbox: Hintergrund + Text.
:C_FBoxDIcon		b $01				;Dateiauswahlbox: System-Icons.
:C_FBoxFiles		b $03				;Dateiauswahlbox: Dateifenster.
:C_WinTitel		b $10				;Fenster: Titel.
:C_WinBack		b $0f				;Fenster: Hintergrund.
:C_WinShadow		b $00				;Fenster: Schatten.
:C_WinIcon		b $0d				;Fenster: System-Icons.
:C_PullDMenu		b $03				;PullDown-Menu.
:C_InputField		b $01				;Text-Eingabefeld.
:C_InputFieldOff	b $0f				;Inaktives Optionsfeld.
:C_GEOS_BACK		b $bf				;GEOS-Standard: Hintergrund.
:C_GEOS_FRAME		b $00				;GEOS-Standard: Rahmen.
:C_GEOS_MOUSE		b $66				;GEOS-Standard: Mauszeiger.

;******************************************************************************
;*** Speicher bis $A000 mit $00-Bytes auffüllen.
;******************************************************************************
:_02T			e COLVAR_BASE + COLVAR_SIZE
:_02
;******************************************************************************

;******************************************************************************
;*** Speicher bis $BF40 mit $00-Bytes auffüllen.
;******************************************************************************
:_81T			e $bf40
:_81
;******************************************************************************
:mouseSysData		b %11111100,%00000000,%00000000
			b %11111000,%00000000,%00000000
			b %11110000,%00000000,%00000000
			b %11111000,%00000000,%00000000
			b %11011100,%00000000,%00000000
			b %10001110,%00000000,%00000000
			b %00000111,%00000000,%00000000
			b %00000010

;******************************************************************************
;*** System-Icons #1.
;******************************************************************************
			t "-G3_SysIcon1"
;******************************************************************************

;******************************************************************************
;*** Speicher bis $BFFE mit $00-Bytes auffüllen.
;******************************************************************************
:_83T			e $bffe
:_83
;******************************************************************************
:sysRAMLink		b $00				;>$00 = RAMLink-Geräeadresse.
:Flag_BackScrn		b $00				;$FF/TRUE = Hintergrundbild geladen.

;******************************************************************************
;*** Speicher bis $C000 mit $00-Bytes auffüllen.
;*** ACHTUNG!
;*** Wenn möglich, Systemvariablen im Bereich $C000-$CFFF ablegen, da dieser
;*** Bereich über den Switcher beim Task-Wechsel gerettet wird.
;*** Beispiel ist ":keyVectorMain". Würde diese Adresse im Bereich ab
;*** $E000-$FFFF abgelegt (bei der ":GetString"-Routine), würde die Adresse
;*** evtl. von einem anderen Task zerstört. Im unteren RAM wird der Inhalt
;*** der Adresse bei der Rückkehr zum aktuellen Task wieder korrekt gesetzt,
;*** da der Speicher aus dem RAM wieder eingelesen wird.
;******************************************************************************
:_80T			e OS_HIGH ; = $C000
:_80
;******************************************************************************

;*** Beginn des GEOS-Kernals ab $c000
:SystemReBoot		jmp	ReBootGEOS		;GEOS wieder einlesen.
:ResetHandle		jmp	BASE_AUTO_BOOT		;RESET-Routine.

:bootName		b "GDOS64-V3"			;Kennung für GDOS64 und GeoDesk64.
;bootName		b "GEOS.BOOT"			;Nicht verwendet.
:version		b _BUILD_VER			;Versions-Nr.

if LANG = LANG_DE
:nationality		b $01				;Landessprache.
endif

if LANG = LANG_EN
:nationality		b $00				;Landessprache.
endif

;--- Hinweis:
;Es gab bisher keine Möglichkeit die
;genaue System-Version zu ermitteln.
;Das Byte an dieser Stelle ist laut dem
;GEOS Reference Guide "Reserved" = $00.
;Zukünftig findet man hier die Version
;von GDOS64 und GEOS/MegaPatch:
;
;  $00 = GEOS V2 oder ältere Versionen
;        von GDOS64 und GEOS/MegaPatch.
;  $3a = GEOS/MegaPatch 3.3r10.
;  $3b = GEOS/MegaPatch 3.3r11.
;>=$80 = GDOS64.
;
:sysVersion		b SYSREV			;System-Version.

:sysFlgCopy		b %01110000
:c128Flag		b $00				;C64-Modus.

:MP3_CODE		b "MP"				;GEOS/MegaPatch.

:keyVectorMain		w $0000				;Zeiger auf Tastaturabfrage.

;******************************************************************************
;*** Speicher bis $C018 mit $00-Bytes auffüllen.
;******************************************************************************
:_16T			e $c018
:_16
;******************************************************************************
:dateCopy		b $58,$07,$06			;Nur Kopie des Datums.
;			b $07,$06			;Frühere GDOS64-Versionen.
			b $00,$00			;Reserviert.

;*** GEOS neu starten.
:ReBootGEOS		ldx	#$06
::1			lda	RamBootData,x
			sta	r0L        ,x
			dex
			bpl	:1

			ldy	#jobFetch		;Code für RAM-Bereich laden.
			jsr	xDoRAMOp_NoChk		;Direkteinsprung "FetchRAM".
			jmp	BASE_REBOOT

;*** Speicherdaten für RBOOT.
:RamBootData		w	BASE_REBOOT
			w	R1A_REBOOT
			w	R1S_REBOOT
			b	$00

;******************************************************************************
;*** ReBoot/DoRamOp-Funktionen.
;*** Funktionen befinden sich in separatem Quelltext und werden beim
;*** booten durch das StartProgramm an die Speichererweiterung angepaßt.
;******************************************************************************
.BASE_RAM_DRV

;******************************************************************************

if _BUILD_RAM = RAM_SCPU
			t "-R3_DoRAM_SRAM"
endif

if _BUILD_RAM = RAM_RL
			t "-R3_DoRAM_RLNK"
endif

if _BUILD_RAM = RAM_REU
			t "-R3_DoRAM_CREU"
			t "-R3_DoRAMOpCREU"
endif

if _BUILD_RAM = RAM_BBG
			t "-R3_DoRAM_GRAM"
endif

;******************************************************************************
;*** Die max. Endadresse hängt von der
;*** Größe der RAM-Treiber ab:
;*** DvRAM_RLNK $C036-$c093 = 94 Bytes
;*** DvRAM_SRAM $C036-$c08C = 86 Bytes
;*** DvRAM_CREU $C036-$c08C = 87 Bytes
;*** DvRAM_GRAM $C036-$c087 = 82 Bytes
;******************************************************************************
.SIZE_RAM_DRV		= 94

;******************************************************************************
;*** Speicher mit $00-Bytes auffüllen.
;******************************************************************************
:_62T			e BASE_RAM_DRV +SIZE_RAM_DRV
:_62
;******************************************************************************
.BASE_RAM_DRV_END
;******************************************************************************

;*** Datenfelder.
:BitData1		b $80,$40,$20,$10,$08,$04,$02
:BitData2		b $01,$02,$04,$08,$10,$20,$40,$80
:BitData3		b $00,$80,$c0,$e0,$f0,$f8,$fc,$fe
:BitData4		b $7f,$3f,$1f,$0f,$07,$03,$01,$00

;*** Zeiger auf Positionen der Namen aller Disketten (A: bis D:)
:DrvNmVecL		b <DrACurDkNm,<DrBCurDkNm,<DrCCurDkNm,<DrDCurDkNm
:DrvNmVecH		b >DrACurDkNm,>DrBCurDkNm,>DrCCurDkNm,>DrDCurDkNm

;*** Pause von 1/10sec ausführen.
:xSCPU_Pause		php
			sei

			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA
			lda	$dc08			;Sekunden/10 - Register.
::51			cmp	$dc08
			beq	:51
			pla
			sta	CPU_DATA

			plp
			rts

;******************************************************************************
;*** Speicher bis $C0DC mit $00-Bytes auffüllen.
;*** ACHTUNG! Sprungtabelle darf nur nach "hinten" mit neuen
;*** Sprungbefehlen aufgefüllt werden.
;******************************************************************************
:_14T			e GD_JUMPTAB
:_14
;******************************************************************************
;*** Einsprungtabelle für neue Kernal-Routinen.
:i_UserColor		jmp	xi_UserColor
:i_ColorBox		jmp	xi_ColorBox
:DirectColor		jmp	xDirectColor
:RecColorBox		jmp	xRecColorBox
:GetBackScreen		jmp	xGetBackScreen
:ResetScreen		jmp	xResetScreen
:GEOS_InitSystem	jmp	GEOS_Init1
:PutKeyInBuffer		jmp	NewKeyInBuf

;*** Einsprungtabelle für SCPU-Routinen.
:SCPU_Pause		jmp	xSCPU_Pause

;*** Erweiterte SCPU-Routinen.
;Hier wird variabler Code eingetragen.
;Beim booten mit SCPU stehen hier
;Vektoren auf die Optimierungsroutinen.
;Wird beim booten von GEOS modifiziert
;wenn SCPU vorhanden.

.SCPU_PATCH_JMPTAB

if _BUILD_SCPU = FALSE
:SCPU_OptOn		rts
			b $00,$00
:SCPU_OptOff		rts
			b $00,$00
:SCPU_SetOpt		rts
			b $00,$00
endif

if _BUILD_SCPU = TRUE
:SCPU_OptOn		jmp	xSCPU_OptOn
:SCPU_OptOff		jmp	xSCPU_OptOff
:SCPU_SetOpt		jmp	xSCPU_SetOpt
endif

;******************************************************************************
;*** Speicher bis $C100 mit $00-Bytes auffüllen.
;******************************************************************************
:_03T			e OS_JUMPTAB ; = $C100
:_03
;******************************************************************************

;*** GEOS-Sprungtabelle.
:InterruptMain		jmp	xInterruptMain
:InitProcesses		jmp	xInitProcesses
:RestartProcess		jmp	xRestartProcess
:EnableProcess		jmp	xEnableProcess
:BlockProcess		jmp	xBlockProcess
:UnblockProcess		jmp	xUnblockProcess
:FreezeProcess		jmp	xFreezeProcess
:UnfreezeProcess	jmp	xUnfreezeProcess
:HorizontalLine		jmp	xHorizontalLine
:InvertLine		jmp	xInvertLine
:RecoverLine		jmp	xRecoverLine
:VerticalLine		jmp	xVerticalLine
:Rectangle		jmp	xRectangle
:FrameRectangle		jmp	xFrameRectangle
:InvertRectangle	jmp	xInvertRectangle
:RecoverRectangle	jmp	xRecoverRec
:DrawLine		jmp	xDrawLine
:DrawPoint		jmp	xDrawPoint
:GraphicsString		jmp	xGraphicsString
:SetPattern		jmp	xSetPattern
:GetScanLine		jmp	xGetScanLine
:TestPoint		jmp	xTestPoint
:BitmapUp		jmp	xBitmapUp
:PutChar		jmp	xPutChar
:PutString		jmp	xPutString
:UseSystemFont		jmp	xUseSystemFont
:StartMouseMode		jmp	xStartMouseMode
:DoMenu			jmp	xDoMenu
:RecoverMenu		jmp	xRecoverMenu
:RecoverAllMenus	jmp	xRecoverAllMenus
:DoIcons		jmp	xDoIcons
:DShiftLeft		jmp	xDShiftLeft
:BBMult			jmp	xBBMult
:BMult			jmp	xBMult
:DMult			jmp	xDMult
:Ddiv			jmp	xDdiv
:DSdiv			jmp	xDSdiv
:Dabs			jmp	xDabs
:Dnegate		jmp	xDnegate
:Ddec			jmp	xDdec
:ClearRam		jmp	xClearRam
:FillRam		jmp	xFillRam
:MoveData		jmp	xMoveData
:InitRam		jmp	xInitRam
:PutDecimal		jmp	xPutDecimal
:GetRandom		jmp	xGetRandom
:MouseUp		jmp	xMouseUp
:MouseOff		jmp	xMouseOff
:DoPreviousMenu		jmp	xDoPreviousMenu
:ReDoMenu		jmp	xReDoMenu
:GetSerialNumber	jmp	xGetSerialNumber
:Sleep			jmp	xSleep
:ClearMouseMode		jmp	xClearMouseMode
:i_Rectangle		jmp	xi_Rectangle
:i_FrameRectangle	jmp	xi_FrameRec
:i_RecoverRectangle	jmp	xi_RecoverRec
:i_GraphicsString	jmp	xi_GraphicsStrg
:i_BitmapUp		jmp	xi_BitmapUp
:i_PutString		jmp	xi_PutString
:GetRealSize		jmp	xGetRealSize
:i_FillRam		jmp	xi_FillRam
:i_MoveData		jmp	xi_MoveData
:GetString		jmp	xGetString
:GotoFirstMenu		jmp	xGotoFirstMenu
:InitTextPrompt		jmp	xInitTextPrompt
:MainLoop		jmp	xMainLoop
:DrawSprite		jmp	xDrawSprite
:GetCharWidth		jmp	xGetCharWidth
:LoadCharSet		jmp	xLoadCharSet
:PosSprite		jmp	xPosSprite
:EnablSprite		jmp	xEnablSprite
:DisablSprite		jmp	xDisablSprite
:CallRoutine		jmp	xCallRoutine
:CalcBlksFree		jmp	 ($9020)
:ChkDkGEOS		jmp	 ($902c)
:NewDisk		jmp	 ($900c)
:GetBlock		jmp	 ($9016)
:PutBlock		jmp	 ($9018)
:SetGEOSDisk		jmp	 ($902e)
:SaveFile		jmp	xSaveFile
:SetGDirEntry		jmp	xSetGDirEntry
:BldGDirEntry		jmp	xBldGDirEntry
:GetFreeDirBlk		jmp	 ($901e)
:WriteFile		jmp	xWriteFile
:BlkAlloc		jmp	 ($902a)
:ReadFile		jmp	xReadFile
:SmallPutChar		jmp	xSmallPutChar
:FollowChain		jmp	xFollowChain
:GetFile		jmp	xGetFile
:FindFile		jmp	xFindFile
:CRC			jmp	xCRC
:LdFile			jmp	xLdFile
:EnterTurbo		jmp	 ($9008)
:LdDeskAcc		jmp	xLdDeskAcc
:ReadBlock		jmp	 ($900e)
:LdApplic		jmp	xLdApplic
:WriteBlock		jmp	 ($9010)
:VerWriteBlock		jmp	 ($9012)
:FreeFile		jmp	xFreeFile
:GetFHdrInfo		jmp	xGetFHdrInfo
:EnterDeskTop		jmp	xEnterDeskTop
:StartAppl		jmp	xStartAppl
:ExitTurbo		jmp	 ($9004)
:PurgeTurbo		jmp	 ($9006)
:DeleteFile		jmp	xDeleteFile
:FindFTypes		jmp	xFindFTypes
:RstrAppl		jmp	xRstrAppl
:ToBasic		jmp	xToBasic
:FastDelFile		jmp	xFastDelFile
:GetDirHead		jmp	 ($901a)
:PutDirHead		jmp	 ($901c)
:NxtBlkAlloc		jmp	 ($9028)
:ImprintRectangle	jmp	xImprintRec
:i_ImprintRectangle	jmp	xi_ImprintRec
:DoDlgBox		jmp	xDoDlgBox
:RenameFile		jmp	xRenameFile

;******************************************************************************
;*** Neue SuperCPU-I/O-Routinen.
;******************************************************************************
if _BUILD_SCPU = FALSE
:InitForIO		jmp	($9000)			;I/O-Bereich einblenden.
:DoneWithIO		jmp	($9002)			;I/O-Bereich ausblenden.
endif
if _BUILD_SCPU = TRUE
:InitForIO		jmp	xInitForIO		;I/O-Bereich einblenden.
:DoneWithIO		jmp	xDoneWithIO		;I/O-Bereich ausblenden.
endif
;******************************************************************************

:DShiftRight		jmp	xDShiftRight
:CopyString		jmp	xCopyString
:CopyFString		jmp	xCopyFString
:CmpString		jmp	xCmpString
:CmpFString		jmp	xCmpFString
:FirstInit		jmp	xFirstInit
:OpenRecordFile		jmp	xOpenRecordFile
:CloseRecordFile	jmp	xCloseRecordFile
:NextRecord		jmp	xNextRecord
:PreviousRecord		jmp	xPreviousRecord
:PointRecord		jmp	xPointRecord
:DeleteRecord		jmp	xDeleteRecord
:InsertRecord		jmp	xInsertRecord
:AppendRecord		jmp	xAppendRecord
:ReadRecord		jmp	xReadRecord
:WriteRecord		jmp	xWriteRecord
:SetNextFree		jmp	 ($9024)
:UpdateRecordFile	jmp	xUpdateRecFile
:GetPtrCurDkNm		jmp	xGetPtrCurDkNm
:PromptOn		jmp	xPromptOn
:PromptOff		jmp	xPromptOff
:OpenDisk		jmp	 ($9014)
:DoInlineReturn		jmp	xDoInlineReturn
:GetNextChar		jmp	xGetNextChar
:BitmapClip		jmp	xBitmapClip
:FindBAMBit		jmp	 ($9026)
:SetDevice		jmp	xSetDevice
:IsMseInRegion		jmp	xIsMseInRegion
:ReadByte		jmp	xReadByte
:FreeBlock		jmp	 ($9022)
:ChangeDiskDevice	jmp	 ($900a)
:RstrFrmDialogue	jmp	xRstrFrmDialogue
:Panic			jmp	xPanic
:BitOtherClip		jmp	xBitOtherClip
:StashRAM		jmp	xStashRAM
:FetchRAM		jmp	xFetchRAM
:SwapRAM		jmp	xSwapRAM
:VerifyRAM		jmp	xVerifyRAM
:DoRAMOp		jmp	xDoRAMOp

;******************************************************************************
;*** Speicher bis $C2D7 mit $00-Bytes auffüllen.
;******************************************************************************
:_04T			e $c2d7
:_04
;******************************************************************************

;*** IRQ-Routine von GEOS.
;Feste Adr.= $C2D7! Notwendig da einige Programme nicht über ":InterruptMain"
;einspringen, sondern nach $C2D7 = ":MainIRQ" um die Mausinformationen zu
;initialisieren (z.B. GeoWrite 64)
:xInterruptMain		jsr	InitMouseData		;Mausabfrage.
			jsr	IntScrnSave		;Bildschirmschoner testen.
			jsr	IntPrnSpool		;Druckerspooler testen.
			jsr	PrepProcData		;Prozessabfrage.
			jsr	DecSleepTime		;"SLEEP"-Abfrage.
			jsr	SetCursorMode		;Cursormodus festlegen.
			jmp	GetRandom		;Zufallszahlen berechnen.
;******************************************************************************

;*** GEOS-Variablen löschen.
:xFirstInit		sei
			cld
			jsr	GEOS_Init1

			lda	#> xEnterDeskTop
			sta	EnterDeskTop   +2
			lda	#< xEnterDeskTop
			sta	EnterDeskTop   +1

			lda	#$7f
			sta	maxMouseSpeed
			sta	mouseAccel
			lda	#$1e
			sta	minMouseSpeed

			jsr	xResetScreen

			ldx	#0
::2			lda	mouseSysData,x		;Daten für Mauszeiger ab
			sta	mousePicData,x		;":mouseSysData" kopieren.
			inx
			cpx	#22			;Original Mauszeiger hält nur
			bcc	:2			;die ersten 22 Bytes vor.

			lda	#$00			;Die restlichen 41 Bytes
::3			sta	mousePicData,x		;mit $00 auffüllen/löschen.
			inx
			cpx	#63
			bcc	:3

;--- Ergänzung: 24.12.22/M.Kanet
;In VIC-Bank#0 ist der Bereich von
;$07E8-$07F7 "unused". Für die in GEOS
;aktive VIC-Bank#2 = $8FE8-$8FF7.
;Es gibt im Kernal an keiner Stelle
;einen Zugriff auf diese Adressen, die
;Spritepointer liegen ab $8FF8 und
;werden durch GEOS_Init1 gesetzt.
;
; -> sysApplData
;
;GEOS V2 mit DESKTOP V2 legt hier über
;das Programm "pad color mgr" Farben
;für den DeskTop und Datei-Icons ab.
;Ab $8FE8 finden sich in 8 Byte bzw.
;16 Halb-Nibble die Farben für GEOS-
;Dateitypen 0-15, und ab $8FF0 findet
;sich die Farbe für den Arbeitsplatz.
;
;*** "pad color mgr"-Vorgaben setzen.
::DefPadCol		lda	#$bf			;Standardfarbe Arbeitsplatz.
			sta	sysApplData +8

			ldx	#7			;Standardfarbe für die ersten
			lda	#$bb			;16 GEOS-Dateitypen.
::1			sta	sysApplData +0,x
			dex
			bpl	:1
;---
			rts

;*** Prüfsumme bilden.
:xCRC			ldy	#$ff			;Startwert für Prüfsumme.
			sty	r2L
			sty	r2H
			iny
::1			lda	#$80			;Bit-Maske auf Startwert.
			sta	r3L

::2			asl	r2L			;Prüfsumme um 1 Bit nach
			rol	r2H			;links verschieben.

			lda	(r0L),y			;Byte aus CRC-Bereich lesen.
			and	r3L			;Mit Bit-Maske verknüpfen.
			bcc	:3			;War Prüfsummen-Bit #15 = 0 ?
							;Ja, weiter...
			eor	r3L			;Bit-Ergebnis invertieren.
::3			beq	:4			;Ergebnis = $00 ? Ja, weiter...

			lda	r2L			;Prüfsumme ergänzen.
			eor	#%00100001
			sta	r2L
			lda	r2H
			eor	#%00010000
			sta	r2H

::4			lsr	r3L			;Alle Bits eines Bytes ?
			bcc	:2			;Nein, weiter...

			iny				;Zeiger auf nächstes Byte
			bne	:5			;berechnen.
			inc	r0H

::5			ldx	#r1L			;Länge des CRC-Bereichs
			jsr	xDdec			;korrigieren.
			lda	r1L
			ora	r1H			;Prüfsumme erstellt ?
			bne	:1			;Nein, weiter...
			rts

;*** Neue ToBasic-Routine.
:xToBasic		lda	r0H			;Register ":r0"
			pha				;zwischenspeichern.
			lda	r0L
			pha

			jsr	SetADDR_ToBASIC		;Zeiger auf RAM-Routine setzen.
			jsr	FetchRAM		;ToBASIC-Routine einlesen.

			pla				;Register ":r0"
			sta	r0L			;zurücksetzen.
			pla
			sta	r0H

			jmp	LOAD_TOBASIC		;ToBASIC ausführen.

;*** PANIC!-Routine.
:xPanic			jsr	SetADDR_PANIC		;Panic-Routine einlesen.
			jsr	FetchRAM
			jmp	LOAD_PANIC		;Panic-Routine ausführen.

;*** Zurück zum DeskTop
:xEnterDeskTop		jsr	SetADDR_EnterDT
			jsr	FetchRAM
			jmp	LOAD_ENTER_DT

;*** Routine zum einlesen des Hintergrundbildes.
:xGetBackScreen		jsr	SetADDR_BackScrn	;Zeiger auf RAM-Routine für
			jsr	SwapRAM			;Hintegrund-Bild einlesen.
			jmp	LOAD_GETBSCRN		;Hintegrund darstellen.

;*** GEOS-Serien-Nummer einlesen.
:xGetSerialNumber	lda	SerialNumber+0
			sta	r0L
			lda	SerialNumber+1
			sta	r0H
			rts

;******************************************************************************
;*** Speicher bis $C3A8 mit $00-Bytes auffüllen.
;******************************************************************************
:_05T			e $c3a8
:_05
;******************************************************************************

;*** Applikation starten.
:xStartAppl		sei				;IRQ sperren.
			cld				;"DEZIMAL"-Flag löschen.
			ldx	#$ff			;Stackzeiger löschen.
			txs
			jsr	SaveFileData		;Startwerte speichern.
			jsr	GEOS_Init0		;GEOS initialisieren.
			jsr	xUseSystemFont		;GEOS-Zeichensatz aktivieren.
			jsr	LoadFileData		;Startwerte zurückschreiben.
			ldx	r7H
			lda	r7L
			jmp	InitMLoop1		;Programm starten.

;*** Dialogbox: Bootdisk einlegen.
.DlgBoxDTdisk		b %11100001
			b DBTXTSTR,$10,$16
			w DBoxDTopMsg1
			b DBTXTSTR,$10,$26
			w DBoxDTopMsg2
			b OK      ,$11,$48
			b NULL

;.DeskTopName		b "DESK TOP"
.DeskTopName		b "GEODESK",$00
.DeskTopNameEnd		b NULL
.DTopFileNmLen		= 8

;******************************************************************************
;*** Speicher bis $C3D8 mit $00-Bytes auffüllen. Feste Adresse!
;******************************************************************************
:_06T			e $c3d8
:_06
;******************************************************************************

if LANG = LANG_DE
.DBoxDTopMsg1		b $18 ;BOLDON
			b "Bitte eine Diskette einlegen"
.DBoxDTopMsg1End	b NULL
.DBoxDTopMsg2		b "die GEODESK enthält"
.DBoxDTopMsg2End	b NULL
.DBoxDTopName		= DBoxDTopMsg2 +4
.DBoxDTopNmLen		= 7
endif

if LANG = LANG_EN
;			b $1b ;PLAINTEXT
.DBoxDTopMsg1		b $18 ;BOLDON
			b "Please insert a disk"
.DBoxDTopMsg1End	b NULL
.DBoxDTopMsg2		b "with GEODESK V1.0 or higher"
.DBoxDTopMsg2End	b NULL
.DBoxDTopName		= DBoxDTopMsg2 +5
.DBoxDTopNmLen		= 12
endif

;******************************************************************************
;*** Speicher bis $C40C mit $00-Bytes auffüllen. Feste Adresse!
;******************************************************************************
:_07T			e $c40c
:_07
;******************************************************************************

;*** Mainloop von GEOS.
;Feste Adresse bei $C40C!
:xMainLoop		jsr	ExecMseKeyb		;Maus/Tastatur abfragen.
			jsr	ExecProcTab		;Prozesse ausführen.
			jsr	ExecSleepJobs		;SLEEP-Funktion abfragen.
			jsr	ExecViewMenu		;Aktuelles Menü invertieren.
			jsr	SetGeosClock		;GEOS-Uhrzeit aktualisieren.
			jsr	TaskManager		;TaskManager abfragen.

			lda	appMain +0
			ldx	appMain +1
:InitMLoop1		jsr	CallRoutine		;Anwenderprogramm ausführen.
:InitMLoop2		cli				;IRQ freigeben.

;*** IRQ-Abfrage initialisieren und
;    zurück zur Mainloop.
:EndMainLoop		ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

;			lda	grcntrl1		;!!! WICHTIG !!!
;			and	#%01111111		;Register $D011 wird manchmal
							;ohne Grund gelöscht, wenn hier
							;nicht wieder der Standardwert
							;gesetzt wird.
							; => BlackScreen-Bug.

			lda	InitVICdata +$11	;Register $D011 auf Standard.
			sta	grcntrl1

			stx	CPU_DATA

			bit	alarmSetFlag		;Wird Weckroutine ausgeführt ?
			bmi	:1			; => Ja, Spooler und Bild-
			bvs	:3			;    schirmschoner übergehen.

::1			lda	Flag_ScrSaver		;Bildschirmschoner starten ?
			bne	:2			;Nein, weiter...
			jsr	SetADDR_ScrSaver	;Zeiger auf Routine für
			jsr	SwapRAM			;Bildschirmschoner in REU.
			jsr	LOAD_SCRSAVER		;Routine starten und danach
			jsr	SwapRAM			;Speicher wiederherstellen.

::2			bit	Flag_Spooler
			bvc	:3
			jsr	SetADDR_Spooler		;Zeiger auf Routine für
			jsr	SwapRAM			;Druckerspooler in REU.
			jsr	LOAD_SPOOLER		;Routine starten und danach
			jsr	SwapRAM			;Speicher wiederherstellen.

::3			bit	HelpSystemActive	;System-Hilfe aktiv?
			bpl	:4			;Nein, Ende...

			lda	keyData
			cmp	#$01			;"KEY_F1" im Puffer?
			bne	:4			;Nein, weiter...

;--- Füllbyte.
;Der direkte vergleich mit "cmp #$01"
;sollte durch einen Vergleich mit einer
;Registeradresse ersetzt werden.
;Um Speicher für den Befehl "cmp $xxxx"
;zu reservieren wird "NOP" eingefügt.
			nop

			sei				;Interrupt sperren.
			jsr	SetADDR_GeoHelp		;Systemhilfe öffnen.
			jsr	SwapRAM
			jsr	LOAD_GEOHELP
			jsr	SwapRAM

::4			jmp	xMainLoop		;Weiter mit MainLoop.

;*** Grafikspeicher (Vordergrund!) löschen, Farben zurücksetzen.
:xResetScreen		php
			sei

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	C_GEOS_MOUSE
			sta	mob0clr
			sta	mob1clr

			lda	C_GEOS_FRAME
			sta	extclr

			stx	CPU_DATA

			lda	#ST_WR_FORE
			sta	dispBufferOn

			lda	#$02
			jsr	SetPattern

			lda	C_GEOS_BACK
			sta	screencolors

			jsr	i_UserColor
			b	$00,$00,$28,$19

			jsr	i_Rectangle
:MaxScrnArea		b	$00,$c7			;Wird auch in DoMenu als
			w	$0000,$013f		;als Datentabelle verwendet!

			plp
			rts

;*** Kernal-Variablen initialisieren.
:InitGEOS		ldx	#$00			;ZeroPage-Adressen r0-r3L
::1			lda	r0L,x			;zwischenspeichern.
			pha
			inx
			cpx	#$07
			bcc	:1

			jsr	SetADDR_InitSys		;InitSys-Routine einlesen.
			jsr	SwapRAM
			jsr	LOAD_INIT_SYS

			ldx	#$06			;ZeroPage-Adressen r0L-r3L
::2			pla				;wieder herstellen.
			sta	r0L,x
			dex
			bpl	:2
			rts

;*** Kernal-Variablen initialisieren.
.SetKernalVec		ldx	#$20
::1			lda	$fd30  -1,x
			sta	irqvec -1,x
			dex
			bne	:1
			rts

;*** Tabelle zum Initialisieren der GEOS-Variablen. Aufruf über ":InitRam".
:InitVarData		w currentMode
			b $0c
			b $00				;currentMode
			b $c0				;dispBufferOn
			b $00				;mouseOn
			w mousePicData			;mousePicPtr
			b $00				;windowTop
			b $c7				;windowBottom
			w $0000				;leftMargin
			w $013f				;rightMargin
			b $00				;pressFlag

			w appMain
			b $1c
			w $0000				;appMain
			w InterruptMain			;intTopVector
			w $0000				;intBotVector
			w $0000				;mouseVector
			w $0000				;keyVector
			w $0000				;inputVector
			w $0000				;mouseFaultVec
			w $0000				;otherPressVec
			w $0000				;StringFaultVec
			w $0000				;alarmTmtVector
			w Panic				;BRKVector
			w RecoverRectangle		;RecoverVector
			b $0a				;selectionFlash
			b $00				;alphaFlag
			b $80				;iconSelFlag
			b $00				;faultData

			w MaxProcess
			b $02
			b $00,$00

			w DI_VecToEntry
			b $01
			b $00

			w DI_VecDefTab +1		;Zeiger auf DoIcon-Tabelle
			b $01				;löschen!
			b $00

			w obj0Pointer			;VIC-Bank#2, Screen=$8C00-$8FFF:
			b $08				;Spritepointer bei $8FF8.
			b $28				;obj0Pointer
			b $29				;obj1Pointer
			b $2a				;obj2Pointer
			b $2b				;obj3Pointer
			b $2c				;obj4Pointer
			b $2d				;obj5Pointer
			b $2e				;obj6Pointer
			b $2f				;obj7Pointer

;HINWEIS:
;Name der Hilfedatei über die Routine
;":EnterDeskTop" löschen, da ":Init"
;auch von ":StartAppl" verwendet wird.
;Damit würde der Name der Hilfedatei
;automatisch gelöscht, auch wenn zuvor
;von GeoDesk auf die Anwendung gesetzt.
if FALSE		;6 Bytes.
			w HelpSystemFile		;Name Hilfedatei löschen.
			b $01
			b $00

			w $0000				;Ende-Kennung.
endif
if TRUE			;6 Bytes.
			w $0000				;Ende-Kennung.

			s 4				;Füllbytes.
endif

;*** Initialisierungswerte für VIC.
; $aa = Adresse wird übergangen.
.InitVICdata		b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$3b,$fb,$aa,$aa,$01,$08,$00
			b $38,$0f,$01,$00,$00,$00
.InitVICend		;Zur Berechnung Anzahl Bytewerte.

;*** Zufallszahl berechnen.
:xGetRandom		inc	random+0
			bne	:1
			inc	random+1
::1			asl	random+0
			rol	random+1
			bcc	:3
			lda	#$0e
			adc	random+0
			sta	random+0
			bcc	:2
			inc	random+1
::2			rts

::3			lda	random+1
			cmp	#$ff
			bcc	:4
			lda	random+0
			sbc	#$f1
			bcc	:4
			sta	random+0
			lda	#$00
			sta	random+1
::4			rts

;*** GEOS initialisieren.
:GEOS_Init0		lda	#$00			;Flag für Dialogbox/SwapFile
			sta	Flag_ExtRAMinUse	;zurücksetzen.

:GEOS_Init1		jsr	InitGEOS		;GEOS-Register definieren.

;*** GEOS-Variablen initialisieren.
.GEOS_InitVar		lda	#> InitVarData		;RAM-Bereiche initialisieren.
			sta	r0H
			lda	#< InitVarData
			sta	r0L

;*** Speicherbereich initialisieren.
:xInitRam		ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			ora	(r0L),y			;Nächste Adressen = $0000 ?
			beq	ExitInit		;Ja, Ende...

			lda	(r0L),y
			sta	r1H
			iny
			lda	(r0L),y			;Anzahl zu initialisierender
			sta	r2L			;Bytes einlesen.
			iny
::1			tya
			tax
			lda	(r0L),y			;Bytewert aus Tabelle lesen und
			ldy	#$00			;in Zielspeicherbereich über-
			sta	(r1L),y			;tragen.
			inc	r1L
			bne	:2
			inc	r1H
::2			txa
			tay
			iny
			dec	r2L
			bne	:1
			tya
			clc				;Zeiger auf nächsten Tabellen-
			adc	r0L			;bereich richten.
			sta	r0L
			bcc	:3
			inc	r0H
::3			jmp	xInitRam		;Nächsten Bereich füllen.
:ExitInit		rts

;*** Mauszeiger abfragen über System-IRQ! Setzt Variablen und Mauszeiger.
:InitMouseData		jsr	xUpdateMouse		;Mausposition einlesen.
			bit	mouseOn			;Mauszeiger aktiv ?
			bpl	ExitInit		;Nein, weiter...
			jsr	SetMseToArea
			lda	#$00			;Zeiger auf Sprite #0 für
			sta	r3L			;Mauszeiger.
			lda	msePicPtr+1		;Zeiger auf Grafik-Daten für
			sta	r4H			;Sprite #0 = Mauszeiger.
			lda	msePicPtr+0
			sta	r4L
			jsr	DrawSprite		;Maus-Sprite erstellen.
			lda	mouseXPos+1
			sta	r4H
			lda	mouseXPos+0
			sta	r4L
			lda	mouseYPos
			sta	r5L
			jsr	PosSprite		;Mauszeiger positionieren.
			jmp	EnablSprite		;Sprite einschalten.

;*** Inline: Speicherbereich löschen.
:xi_FillRam		pla				;Rücksprungadresse vom Stapel
			sta	returnAddress +0	;einlesen und als Zeiger auf
			pla				;Inline-Daten verwenden.
			sta	returnAddress +1
			jsr	Get2Word1Byte		;Zwei WORDs und ein BYTE holen.
			jsr	FillRam			;Speicher füllen.

			php
			lda	#$06

;*** Inline-Routine beenden.
:xDoInlineReturn	clc
			adc	returnAddress +0
			sta	returnAddress +0
			bcc	:1
			inc	returnAddress +1
::1			plp
			jmp	(returnAddress)

;******************************************************************************
;*** 8-Bit/16-Bit-Routinen.
;******************************************************************************
.BASE_SCPU_DRV
;******************************************************************************

;*** ClearRAM/FillRAM/MoveData-Routine.
if _BUILD_SCPU = FALSE
;--- 8-Bit-Routinen einlesen.
			t "-G3_FillRam"
			t "-G3_MoveData"
endif

if _BUILD_SCPU = TRUE
;--- 16-Bit-Routinen einlesen.
			t "-R3_SCPU16Bit"

;--- Labels für Sprungtabelle definieren.
:xClearRam		= s_ClearRam
:xFillRam		= s_FillRam
:xi_MoveData		= s_i_MoveData
:xMoveData		= s_MoveData
:xInitForIO		= s_InitForIO
:xDoneWithIO		= s_DoneWithIO
:xSCPU_OptOn		= s_SCPU_OptOn
:xSCPU_OptOff		= s_SCPU_OptOff
:xSCPU_SetOpt		= s_SCPU_SetOpt
endif

;******************************************************************************
;*** Die max. Endadresse hängt von der
;*** Größe der 8Bit/16Bit-Routinen ab:
;***
;*** _BUILD_SCPU = FALSE
;*** 8Bit  : $C60C-$C6D8 = 205 Bytes
;***
;*** _BUILD_SCPU = TRUE
;*** 16Bit : $C60C-$C6C3 = 184 Bytes
;******************************************************************************
.SIZE_SCPU_DRV		= 205

;--- Ergänzung: 24.07.21
;Damit ist sichergestellt, das der Code
;immer an der gleichen Stelle liegt,
;egal ob _BUILD_SCPU = TRUE/FALSE ist.
;******************************************************************************
;*** Speicher mit $00-Bytes auffüllen.
;******************************************************************************
:_13T			e BASE_SCPU_DRV +SIZE_SCPU_DRV
:_13
;******************************************************************************

;*** Zeiger auf nächstes Byte setzen.
:SetNxByte_r0		inc	r0L
			bne	:1
			inc	r0H
::1			rts

;*** Register ":r3" auf nächstes Byte setzen.
:SetNxByte_r3		inc	r3L
			bne	:1
			inc	r3H
::1			rts

;*** Infoblock einlesen.
:xGetFHdrInfo		ldy	#$13 +1			;Zeiger auf Sektor für
			jsr	Get1stSek		;Infoblock nach r1L/r1H
							;einlesen.

			lda	r1L			;Sektor-Zeiger nach fileTrScTab
			sta	fileTrScTab+0		;kopieren. Grund unbekannt.
			lda	r1H
			sta	fileTrScTab+1

			jsr	Vec_fileHeader
			jsr	GetBlock		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	RTS_02			;Ja, Abbruch.

			ldy	#$01 +1			;Zeiger auf VLIR-Sektor
			jsr	Get1stSek		;einlesen. Grund unbekannt.
			jmp	GetLoadAdr		;Zeiger auf Ladeadresse setzen.

;*** Spritedaten in Spritespeicher kopieren.
:xDrawSprite		ldy	r3L
			lda	sprPicAdrL,y
			sta	r5L
			lda	sprPicAdrH,y
			sta	r5H

			ldy	#$3f
::51			lda	(r4L),y
			sta	(r5L),y
			dey
			bpl	:51
:RTS_02			rts

;*** Zeiger auf Sprite-Speicher.
:sprPicAdrL		b < spr0pic,< spr1pic,< spr2pic,< spr3pic
			b < spr4pic,< spr5pic,< spr6pic,< spr7pic
:sprPicAdrH		b > spr0pic,> spr1pic,> spr2pic,> spr3pic
			b > spr4pic,> spr5pic,> spr6pic,> spr7pic

;*** C64: Sprite positionieren.
:xPosSprite		lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	r3L
			asl
			tay

			lda	r5L
			clc
			adc	#$32
			sta	mob0ypos,y
			lda	r4L
			clc
			adc	#$18
			sta	r6L
			lda	r4H
			adc	#$00
			sta	r6H

			lda	r6L
			sta	mob0xpos,y

			ldx	r3L
			lda	BitData2,x
			eor	#$ff
			and	msbxpos
			tay
			lda	#$01
			and	r6H
			beq	:51
			tya
			ora	BitData2,x
			tay
::51			sty	msbxpos
			jmp	ExitSprPicIO

;*** Sprite einschalten.
:xEnablSprite		ldx	r3L
			lda	BitData2,x
			tax
			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA
			txa
			ora	mobenble
			jmp	SetMobExitIO

;*** Sprite abschalten.
:xDisablSprite		ldx	r3L
			lda	BitData2,x
			eor	#$ff
			tax
			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA
			txa
			and	mobenble
:SetMobExitIO		sta	mobenble
:ExitSprPicIO		pla
			sta	CPU_DATA
			rts

;******************************************************************************
;*** String/Arithmetik-Routinen.
;*** Müssen im Bereich $C000-$CFFF liegen da beim Update noch alte RAM-Treiber
;*** aktiv sind, welche mit diesen Routinen bei aktiviertem I/O hantieren.
;******************************************************************************

;*** String kopieren. (Akku =$00 bis zum $00-Byte, <>$00 = Anzahl Zeichen).
;    Akku =  $00, Ende durch $00-Byte.
;    Akku <> $00, Anzahl Zeichen.
:xCopyString		lda	#$00
:xCopyFString		stx	:1 +1
			sty	:2 +1
			tax
			ldy	#$00
::1			lda	(r4L),y
::2			sta	(r5L),y
			bne	:3
			txa
			beq	:4
::3			iny
			beq	:4
			txa
			beq	:1
			dex
			bne	:1
::4			rts

;*** String + NULL-Byte vergleichen.
;    Akku =  $00, Ende durch $00-Byte.
;    Akku <> $00, Anzahl Zeichen.
:xCmpString		lda	#$00
:xCmpFString		stx	:1 +1
			sty	:2 +1
			tax
			ldy	#$00
::1			lda	(r5L),y
::2			cmp	(r1L),y
			bne	:4
			cmp	#$00
			bne	:3
			txa
			beq	:4
::3			iny
			beq	:4
			txa
			beq	:1
			dex
			bne	:1
			txa
::4			rts

;*** ZeroPage-Adresse * 2^y
:xDShiftLeft		dey
			bmi	DShiftExit
			asl	zpage +0,x
			rol	zpage +1,x
			jmp	xDShiftLeft

;*** ZeroPage-Adresse : 2^y
:xDShiftRight		dey
			bmi	DShiftExit
			lsr	zpage +1,x
			ror	zpage +0,x
			jmp	xDShiftRight

;*** Zwei Bytes multiplizieren.
:xBBMult		lda	zpage,y
			sta	r8H
			sty	r8L
			ldy	#$08
			lda	#$00
::1			lsr	r8H
			bcc	:2
			clc
			adc	zpage +0,x
::2			ror
			ror	r7L
			dey
			bne	:1
			sta	zpage +1,x
			lda	r7L
			sta	zpage +0,x
			ldy	r8L
:DShiftExit		rts

;*** Bytes mit Word multiplizieren.
:xBMult			lda	#$00
			sta	zpage +1,y

;*** Word mit Word multiplizieren.
:xDMult			lda	#$10
			sta	r8L
			lda	#$00
			sta	r7L
			sta	r7H
::1			lsr	zpage +1,x
			ror	zpage +0,x
			bcc	:2
			lda	r7L
			clc
			adc	zpage +0,y
			sta	r7L
			lda	r7H
			adc	zpage +1,y
::2			lsr
			sta	r7H
			ror	r7L
			ror	r6H
			ror	r6L
			dec	r8L
			bne	:1
			lda	r6L
			sta	zpage +0,x
			lda	r6H
			sta	zpage +1,x
			rts

;*** Ohne Vorzeichen dividieren.
:xDdiv			lda	#$00
			sta	r8L
			sta	r8H
			lda	#$10
			sta	r9L
::1			asl	zpage +0,x
			rol	zpage +1,x
			rol	r8L
			rol	r8H
			lda	r8L
			sec
			sbc	zpage +0,y
			sta	r9H
			lda	r8H
			sbc	zpage +1,y
			bcc	:2
			inc	zpage +0,x
			sta	r8H
			lda	r9H
			sta	r8L
::2			dec	r9L
			bne	:1
:DdivExit		rts

;*** Vorzeichen ermitteln.
:xDabs			lda	zpage +1,x
			bmi	xDnegate
			rts

;*** Mit Vorzeichen dividieren.
:xDSdiv			lda	zpage +1,x
			eor	zpage +1,y
			php
			jsr	xDabs
			stx	r8L
			tya
			tax
			jsr	xDabs
			ldx	r8L
			jsr	xDdiv
			plp
			bpl	DdivExit
;			jmp	xDnegate

;*** Word negieren.
:xDnegate		lda	zpage +1,x
			eor	#$ff
			sta	zpage +1,x
			lda	zpage +0,x
			eor	#$ff
			sta	zpage +0,x
			inc	zpage +0,x
			bne	:1
			inc	zpage +1,x
::1			rts

;*** Word-Adresse -1.
:xDdec			lda	zpage +0,x
			bne	:1
			dec	zpage +1,x
::1			dec	zpage +0,x
			lda	zpage +0,x
			ora	zpage +1,x
			rts

;*** Prozesstabelle initialisieren.
:xInitProcesses		ldx	#$00			;Prozesse in Tabelle löschen.
			stx	MaxProcess
			sta	r1L			;Anzahl Prozesse merken.
			sta	r1H			;Zähler für Prozesse auf Start.
			tax
			lda	#%00100000		;Alle Prozesse auf "FROZEN"
::1			sta	ProcStatus-1,x		;zurückstellen.
			dex
			bne	:1

			ldy	#$00
::2			lda	(r0L),y			;Prozess-Routine in Tabelle.
			sta	ProcRout  +0,x
			iny
			lda	(r0L),y
			sta	ProcRout  +1,x
			iny
			lda	(r0L),y			;Prozess-Zähler in Tabelle.
			sta	ProcDelay +0,x
			iny
			lda	(r0L),y
			sta	ProcDelay +1,x

;--- Ergänzung: 23.12.22/M.Kanet
; Die Routine ":PrepProcData" testet
; neben FROZEN auch NOTIMER (Bit%4).
; Es gab aber im Kernal keine Stelle,
; die das NOTIMER-Bit setzen könnte.
; Es wäre denkbar, das die Funktion
; fallengelassen wurde, denn man kann
; einen manuellen Prozess auch als
; normale Sub-Routine ausführen. Da
; aber der Kernal das Bit testet und
; die Konstanten existieren, wurde die
; Funktion hier umgesetzt, da es damit
; keine Kompatibilitätsprobleme gibt.
; Logisch wäre es das Bit%4 zu setzen,
; wenn der Timer den Wert 0 hat.
; Das ist die einzige Änderung, um die
; Funktion umzusetzen. Der Prozess
; kann nur über EnableProcess aktiviert
; und über MainLoop gestartet werden.
; Die Funktion ist erst ab der Version
; sysVersion=$81 in GDOS64 enthalten.
;
			ora	ProcDelay +0,x		;Delay=0 ?
			bne	:3			; => Nein, weiter...

			txa				;x-Register zwischenspeichern.
			pha

			lsr				;Zeiger auf ProcStatus berechnen.
			tax
			lda	ProcStatus,x		;NOTIMER-Status setzen.
			ora	#%00010000		; => NOTIMER_BIT
			sta	ProcStatus,x

			pla
			tax				;x-Register zurücksetzen.
;---
::3			iny
			inx
			inx
			dec	r1H			;Alle Prozesse eingelesen ?
			bne	:2			;Nein, weiter...
			lda	r1L			;Anzahl Prozesse merken.
			sta	MaxProcess
			rts

;*** Prozesse ausführen.
:ExecProcTab		ldx	MaxProcess		;Prozesse aktiv ?
			beq	:3			;Nein, weiter...
			dex				;Zeiger auf letzten Prozess.
::1			lda	ProcStatus,x		;Aktueller Prozess aktiv ?
			bpl	:2			;Nein, weiter...
			and	#%01000000		;Prozess-Pause aktiv ?
			bne	:2			;Ja, übergehen.
			lda	ProcStatus,x
			and	#%01111111
			sta	ProcStatus,x
			txa
			pha
			asl
			tax
			lda	ProcRout+0,x		;Adresse für Prozessroutine
			sta	r0L			;einlesen.
			lda	ProcRout+1,x
			sta	r0H
			jsr	ExecProcRout		;Prozessroutine ausführen.
			pla
			tax
::2			dex				;Zeiger auf nächsten
			bpl	:1			;Prozess.
::3			rts

;*** Prozesstabelle korrigieren.
:PrepProcData		lda	#$00
			tay
			tax
			cmp	MaxProcess		;Prozesse definiert ?
			beq	:4			;Nein, Ende...

::1			lda	ProcStatus,x
			and	#%00110000		;Prozess FROZEN oder NOTIMER ?
			bne	:3			;Ja, übergehen.

			lda	ProcCurDelay+0,y	;Zähler korrigieren.
			bne	:2			;(Zähler besteht aus 1 Word!)
			pha
			lda	ProcCurDelay+1,y
			sec
			sbc	#$01
			sta	ProcCurDelay+1,y
			pla
::2			sec
			sbc	#$01
			sta	ProcCurDelay+0,y
			ora	ProcCurDelay+1,y	;Zähler = $0000 ?
			bne	:3			;Nein, weiter...

			jsr	ResetProcDelay		;Prozess aktivieren.

			lda	ProcStatus,x
			ora	#%10000000
			sta	ProcStatus,x

::3			iny
			iny
			inx
			cpx	MaxProcess		;Alle Prozesse geprüft ?
			bne	:1			; => Nein, weiter...

::4			rts

;*** Prozess wieder starten.
:xRestartProcess	lda	ProcStatus,x
			and	#%10011111
			sta	ProcStatus,x
:ResetProcDelay		txa
			pha
			asl
			tax
			lda	ProcDelay   +0,x
			sta	ProcCurDelay+0,x
			lda	ProcDelay   +1,x
			sta	ProcCurDelay+1,x
			pla
			tax
			rts

;*** Prozess sofort starten.
:xEnableProcess		lda	ProcStatus,x
			ora	#%10000000
			bne	NewProcStatus

;*** Prozess nicht mehr ausführen.
:xBlockProcess		lda	ProcStatus,x
			ora	#%01000000
			bne	NewProcStatus

;*** Prozess wieder ausführen.
:xUnblockProcess	lda	ProcStatus,x
			and	#%10111111
			jmp	NewProcStatus

;*** Prozess-Zähler einfrieren.
:xFreezeProcess		lda	ProcStatus,x
			ora	#%00100000
			bne	NewProcStatus

;*** Prozess-Zähler freigeben.
:xUnfreezeProcess	lda	ProcStatus,x
			and	#%11011111
:NewProcStatus		sta	ProcStatus,x
			rts

;*** Sleep-Wartezeit korrigieren.
:DecSleepTime		ldx	MaxSleep		;Sleep-Routinen aktiv ?
			beq	:4			;Nein, Ende...
			dex
::1			lda	SleepTimeL,x		;Wartezeit (Word)
			bne	:2			;korrigieren.
			ora	SleepTimeH,x
			beq	:3
			dec	SleepTimeH,x
::2			dec	SleepTimeL,x
::3			dex
			bpl	:1
::4			rts

;*** Alle Sleep-Routinen ausführen wenn Wartezeit = $0000.
:ExecSleepJobs		ldx	MaxSleep		;Sleep-Routinen aktiv ?
			beq	:3			;Nein, Ende...
			dex
::1			lda	SleepTimeL,x
			ora	SleepTimeH,x		;Wartezeit abgelaufen ?
			bne	:2			;Nein, weiter...
			lda	SleepRoutH,x		;Sleep-Routine einlesen.
			sta	r0H
			lda	SleepRoutL,x
			sta	r0L
			txa
			pha
			jsr	Del1stSleep		;Ersten Eintrag löschen.
			jsr	DoSleepJob		;Sleep-Routine aufrufen.
			pla
			tax
::2			dex
			bpl	:1			;Nächsten Sleep testen.
::3			rts

;*** SLEEP-Routine aufrufen.
:DoSleepJob		jsr	SetNxByte_r0

;*** Prozess-Routine ausführen.
:ExecProcRout		jmp	(r0)

;*** Eintrag aus SLEEP-Tabelle löschen.
:Del1stSleep		php
			sei
::1			inx
			cpx	MaxSleep
			beq	:2
			lda	SleepTimeL  ,x
			sta	SleepTimeL-1,x
			lda	SleepTimeH  ,x
			sta	SleepTimeH-1,x
			lda	SleepRoutL  ,x
			sta	SleepRoutL-1,x
			lda	SleepRoutH  ,x
			sta	SleepRoutH-1,x
			jmp	:1

::2			dec	MaxSleep
			plp
			rts

;*** GEOS-Pause einlegen.
:xSleep			php
			pla
			tay
			sei
			ldx	MaxSleep
			lda	r0L
			sta	SleepTimeL,x
			lda	r0H
			sta	SleepTimeH,x
			pla
			sta	SleepRoutL,x
			pla
			sta	SleepRoutH,x
			inc	MaxSleep
			tya
			pha
			plp
			rts

;******************************************************************************
;*** Grafikroutinen C64.
;******************************************************************************
			t "-G3_GetScanLine"
			t "-G3_Grafx64"
;******************************************************************************

;******************************************************************************
;*** Die Sprungtabelle zum setzen der RAM-Vektoren für die externen
;*** GDOS-Routinen liegt unveränderlich am Ende des Bereichs $C000-$CFFF!!!
;******************************************************************************
:_EXT_ROUT		= 22
:_EXT_TabBytes		= _EXT_ROUT *6
:_EXT_VecBytes		= _EXT_ROUT *3 -2
:_90T			e $d000 - _EXT_TabBytes - _EXT_VecBytes -22
:_90
;******************************************************************************

;--- MgeaPatch/GDOS-Routinen.
;Zeiger auf externe Routinen in REU.
;
;--- Ergänzung: 21.07.21/M.Kanet
;TaskMan und GeoHelp liegt nicht in
;der GDOS-Speicherbank, sondern in der
;TaskMan/GeoHelp-Speicherbank!
:_EXT_GDOS_ADDR		w LOAD_TASKMAN    ,RTA_TASKMAN    ,RTS_TASKMAN
			w LOAD_REGISTER   ,R2A_REGISTER   ,R2S_REGISTER
			w LOAD_ENTER_DT   ,R2A_ENTER_DT   ,R2S_ENTER_DT
			w LOAD_TOBASIC    ,R2A_TOBASIC    ,R2S_TOBASIC
			w LOAD_PANIC      ,R2A_PANIC      ,R2S_PANIC
			w LOAD_GETNXDAY   ,R2A_GETNXDAY   ,R2S_GETNXDAY
			w LOAD_DOALARM    ,R2A_DOALARM    ,R2S_DOALARM
			w LOAD_GETFILES   ,R2A_GETFILES   ,R2S_GETFILES
			w LOAD_GFILDATA   ,R2A_GFILDATA   ,R2S_GFILDATA
			w LOAD_GFILMENU   ,R2A_GFILMENU   ,R2S_GFILMENU
			w LOAD_DB_SCREEN  ,R2A_DB_SCREEN  ,R2S_DB_SCREEN
			w SCREEN_BASE        ,R2A_DB_GRAFX   ,R2S_DB_GRAFX
			w COLOR_MATRIX       ,R2A_DB_COLOR   ,R2S_DB_COLOR
			w LOAD_GETBSCRN   ,R2A_GETBSCRN   ,R2S_GETBSCRN
			w LOAD_SCRSAVER   ,R2A_SCRSAVER   ,R2S_SCRSAVER
			w LOAD_SPOOLER    ,R2A_SPOOLER    ,R2S_SPOOLER

;--- Ergänzung: 30.12.18/M.Kanet
;Größe des Spoolers und Druckertreiber im RAM um 1Byte reduziert.
;geoCalc64 nutzt beim Drucken ab $$5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert. Wird der gesamte Speicher
;getauscht führt das zum Absturz in geoCalc.
;Mit der folgenden Anpassung dürfen Spooler+Treiber max. bis $7F3E reichen.
.GCalcFix1		w PRINTBASE          ,R2A_PRNSPOOL   ,R2S_PRNSPOOL -1
			w fileHeader         ,R2A_PRNSPHDR   ,R2S_PRNSPHDR
.GCalcFix2		w PRINTBASE          ,R2A_PRINTER    ,R2S_PRINTER -1
			w fileHeader         ,R2A_PRNTHDR    ,R2S_PRNTHDR

;--- Ergänzung: 02.03.21/M.Kanet
;--- GDOS-Routinen.
;Neue Einsprünge für GDOS64.
			w LOAD_INIT_SYS   ,R2A_INIT_SYS   ,R2S_INIT_SYS
			w LOAD_GEOHELP    ,R2A_GEOHELP    ,R2S_GEOHELP

;--- Hinweis:
;Neue Vektoren hier einfügen und nicht
;am Ende, da sonst die Sprungtabelle
;verschoben wird.
;
;--- Ergänzung: 02.03.21/M.Kanet
;Neue Einsprünge für GDOS64.
;
:SetADDR_GeoHelp	ldy	#$16 *6 -1		;GeoHelp-Menü.
			b $2c
:SetADDR_InitSys	ldy	#$15 *6 -1		;GEOS-Initialisierung.
			b $2c
;
;--- Ergänzung: 02.03.21/M.Kanet
;Einsprünge für GEOS/MP3.
;
:SetADDR_PrntHdr	ldy	#$14 *6 -1		;Drucker #2.
			b $2c
:SetADDR_Printer	ldy	#$13 *6 -1		;Drucker #1.
			b $2c
:SetADDR_PrnSpHdr	ldy	#$12 *6 -1		;Drucker-Spooler #1.
			b $2c
:SetADDR_PrnSpool	ldy	#$11 *6 -1		;Drucker-Spooler #2.
			b $2c
:SetADDR_Spooler	ldy	#$10 *6 -1		;Spooler-Routine.
			b $2c
:SetADDR_ScrSaver	ldy	#$0f *6 -1		;Bildschirmschoner.
			b $2c
:SetADDR_BackScrn	ldy	#$0e *6 -1		;Hintegrundbild.
			b $2c
:SetADDR_DB_COLS	ldy	#$0d *6 -1		;Farben.
			b $2c
:SetADDR_DB_GRFX	ldy	#$0c *6 -1		;Grafik.
			b $2c
:SetADDR_DB_SCRN	ldy	#$0b *6 -1		;Dialogbox-Bildschirm löschen.
			b $2c
:SetADDR_GFilMenu	ldy	#$0a *6 -1		;GetFile - Box/Icons ausgeben.
			b $2c
:SetADDR_GFilData	ldy	#$09 *6 -1		;GetFile - Dateien einlesen.
			b $2c
:SetADDR_GetFiles	ldy	#$08 *6 -1		;GetFile
			b $2c
:SetADDR_DoAlarm	ldy	#$07 *6 -1		;DoAlarm
			b $2c
:SetADDR_GetNxDay	ldy	#$06 *6 -1		;GetNextDay
			b $2c
:SetADDR_PANIC		ldy	#$05 *6 -1		;PANIC!-Box
			b $2c
:SetADDR_ToBASIC	ldy	#$04 *6 -1		;ToBASIC
			b $2c
:SetADDR_EnterDT	ldy	#$03 *6 -1		;EnterDeskTop.
			b $2c
:SetADDR_Register	ldy	#$02 *6 -1		;Register.
			lda	MP3_64K_SYSTEM
			bne	SetADDR

:SetADDR_TaskMan	ldy	#$01 *6 -1		;TaskManager.
			lda	Flag_TaskBank
:SetADDR		sta	r3L

			ldx	#$05
::1			lda	_EXT_GDOS_ADDR,y
			sta	r0L,x
			dey
			dex
			bpl	:1
			rts

;******************************************************************************
;*** Speicher bis $D000 mit $00-Bytes auffüllen.
;******************************************************************************
:_08T			e $d000
:_08
;******************************************************************************

;******************************************************************************
;*** GEOS-Füllpatterns.
;******************************************************************************
			t "-G3_Patterns"
;******************************************************************************

;******************************************************************************
;*** Zeichensatz-Daten.
;******************************************************************************

;*** Tabelle zum berechnen der Daten für Buchstaben in Fettschrift!
;    Jedes Byte in PLAINTEXT wird durch ein Byte in BOLD ersetzt. Dabei
;    dient das PLAINTEXT-Byte als Zeiger auf die BoldData-Tabelle.
;    Bsp: %00010000 wird zu %00011000
:BoldData		b $00,$01,$03,$03,$06,$07,$07,$07
			b $0c,$0d,$0f,$0f,$0e,$0f,$0f,$0f
			b $18,$19,$1b,$1b,$1e,$1f,$1f,$1f
			b $1c,$1d,$1f,$1f,$1e,$1f,$1f,$1f
			b $30,$31,$33,$33,$36,$37,$37,$37
			b $3c,$3d,$3f,$3f,$3e,$3f,$3f,$3f
			b $38,$39,$3b,$3b,$3e,$3f,$3f,$3f
			b $3c,$3d,$3f,$3f,$3e,$3f,$3f,$3f
			b $60,$61,$63,$63,$66,$67,$67,$67
			b $6c,$6d,$6f,$6f,$6e,$6f,$6f,$6f
			b $78,$79,$7b,$7b,$7e,$7f,$7f,$7f
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $70,$71,$73,$73,$76,$77,$77,$77
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $78,$79,$7b,$7b,$7e,$7f,$7f,$7f
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $c0,$c1,$c3,$c3,$c6,$c7,$c7,$c7
			b $cc,$cd,$cf,$cf,$ce,$cf,$cf,$cf
			b $d8,$d9,$db,$db,$de,$df,$df,$df
			b $dc,$dd,$df,$df,$de,$df,$df,$df
			b $f0,$f1,$f3,$f3,$f6,$f7,$f7,$f7
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $e0,$e1,$e3,$e3,$e6,$e7,$e7,$e7
			b $ec,$ed,$ef,$ef,$ee,$ef,$ef,$ef
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f0,$f1,$f3,$f3,$f6,$f7,$f7,$f7
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff

;*** GEOS-Font in Quellcode einbinden.
if LANG = LANG_DE
:BSW_Font		v 9,"fnt.GEOS 64.de"
endif

if LANG = LANG_EN
:BSW_Font		v 9,"fnt.GEOS 64.us"
endif

;******************************************************************************

;*** Zeicheninformationen ermitteln.
:DefCharData		ldy	r1H
			iny
			sty	BaseUnderLine
			sta	r5L			;Zeichencode merken.
			ldx	#$00			;Schriftart "PLAINTEXT".
			clc				;ASCII-Code berechnen.
			adc	#$20
			jsr	GetRealSize		;Zeichenbreite berechnen.
			tya				;Zeichenbreite speichern.
			pha

			lda	r5L			;Zeichencode einlesen.
			asl				;Zeiger auf Beginn der Daten
			tay				;in Bit-Streamtabelle.
			lda	(curIndexTable),y	;Startadresse einlesen und
			sta	r2L			;speichern.
			and	#%00000111
			sta	BitStr1stBit		;Zeiger auf erstes Bit merken.

			lda	r2L			;Startadresse auf erstes
			and	#%11111000		;Byte in Bit-Stream umrechnen.
			sta	r3L
			iny
			lda	(curIndexTable),y
			sta	r2H

			pla				;Zeichenbreite einlesen.

			clc				;Breite zu Beginn der Bit-
			adc	r2L			;Streamdaten addieren und
			sta	r6H			;zwischenspeichern.
			clc
			sbc	r3L
			lsr				;Anzahl Bytes mit 8 Bit
			lsr				;Grafikdaten berechnen.
			lsr
			sta	r3H
			tax
			cpx	#$03			;Mehr als 4 Datenbyte ?
			bcc	:1			;Nein, weiter...
			ldx	#$03			;Geht nicht! Da Startbyte +
							;4x Datenbyte + Abschlußbyte
							;zusammen bereits 48 Bit sind!
::1			lda	CalcBitDataL,x		;Berechnungsroutine für
			sta	r13L			;Anzahl Bytes definieren.
			lda	CalcBitDataH,x		;Vektor nach ":r13".
			sta	r13H

			lda	r2L			;Bit-Streamlänge bis zum
			lsr	r2H			;Beginn der Grafikdaten in
			ror				;Bytes umrechnen.
			lsr	r2H
			ror
			lsr	r2H
			ror
			clc				;Zeiger auf erstes Byte mit
			adc	cardDataPntr+0		;Grafikdaten in Zeichensatz
			sta	r2L			;nach ":r2" kopieren.
			lda	r2H
			adc	cardDataPntr+1
			sta	r2H

			ldy	BitStr1stBit
			lda	BitData3,y
			eor	#%11111111		;Bitmaske für Bits in erstem
			sta	BitStrDataMask		;Datenbyte berechnen.

			ldy	r6H
			dey
			tya
			and	#%00000111
			tay
			lda	BitData4,y
			eor	#%11111111		;Bitmaske für Bits in letztem
			sta	r7H			;Datenbyte berechnen.

			lda	currentMode		;Schriftart einlesen und
			tax				;in xReg kopieren.
			and	#%00001000		;"Outline" aktiv ?
			beq	:2			;Nein, weiter...
			lda	#%10000000
::2			sta	r8H			;Outline-Modus merken.

			lda	r5L
			clc				;ASCII-Code berechnen.
			adc	#$20
			jsr	GetRealSize		;Zeichenbreite berechnen.
			sta	r5H			;Abstand zur Baseline merken.

			lda	r1H			;Zeiger auf erste Grafikzeile
			sec				;für Zeichenausgabe.
			sbc	r5H
			sta	r1H

			stx	r10H			;Zeichenhöhe merken.

;*** Zeicheninformationen ermitteln (Fortsetzung).
			tya				;Zeichenbreite merken.
			pha

			lda	r11H			;Auf Bereichsüberschreitung
			bmi	:4			;testen ? Nein, weiter...

			lda	rightMargin+1		;Zeichen innerhalb
			cmp	r11H			;Textfenster ?
			bne	:3
			lda	rightMargin+0
			cmp	r11L
::3			bcc	RightOver		;Nein, nicht ausgeben.

::4			lda	currentMode
			and	#%00010000		;Schriftstil einlesen.
			bne	:5			;Kursiv ? Ja, weiter...
			tax				;Versatzmaß für Kursiv = $00.

::5			txa				;Versatzmaß für Kursiv = $08.
			lsr
			sta	r3L			;Versatzmaß merken.

			clc				;Versatzmaß zu aktueller
			adc	r11L			;X-Koordinate addieren.
			sta	StrBitXposL
			lda	r11H
			adc	#$00
			sta	StrBitXposH

			pla				;Zeichenbreite einlesen und
			sta	CurCharWidth		;in Zwischenspeicher kopieren.

			clc				;Zeichenbreite zu Versatzmaß
			adc	StrBitXposL		;und X-Koordinate addieren.
			sta	r11L
			lda	#$00
			adc	StrBitXposH
			sta	r11H			;Auf Bereichsüberschreitung
			bmi	LeftOver		;testen ? Nein, weiter...

			jsr	TestLeftMargin
			bcs	LeftOver		;Ja, Fehlerbehandlung.

			jsr	StreamInfo

			ldx	#$00			;Zeichen nicht invertieren.
			lda	currentMode
			and	#%00100000		;REVERS-Modus aktiv ?
			beq	:7			;Nein, weiter...
			dex				;Zeichen invertieren.
::7			stx	r10L			;REVERS-Modus speichern.
			clc				;Kein Fehler, OK...
			rts

;*** Berechnungsroutinen für Zeichenausgabe.
:CalcBitDataL		b < Char24Bit,< Char32Bit,< Char40Bit,< Char48Bit
:CalcBitDataH		b > Char24Bit,> Char32Bit,> Char40Bit,> Char48Bit

;*** Rechte Grenze überschritten,
;    Zeichen nicht ausgeben.
:RightOver		pla				;Zeichenbreite einlesen und
			sta	CurCharWidth		;Zwischenspeicher kopieren.
			clc				;Neue X-Koordinate berechnen.
			adc	r11L
			sta	r11L
			bcc	SetOverFlag
			inc	r11H
			sec
			rts

;*** Linke Grenze unterschritten.
:LeftOver		lda	r11L			;X-Koordinate korrigieren.
			sec
			sbc	r3L
			sta	r11L
			bcs	SetOverFlag
			dec	r11H
:SetOverFlag		sec
			rts

;*** Linken Rand prüfen.
:TestLeftMargin		lda	leftMargin+1
			cmp	r11H
			bne	:1
			lda	leftMargin+0
			cmp	r11L
::1			rts

;*** Bit-Stream-Infos einlesen.
;    Startbyte = Teilweise Bits setzen.
;    Datenbyte = 8 Bit-Stream-Byte.
;    Endbyte   = Teilweise Bits setzen.
:StreamInfo		ldx	r1H			;Grafikzeile berechnen.
			jsr	GetScanLine

;*** Erstes Byte bestimmen.
			lda	StrBitXposL		;X-Koordinate einlesen.
			ldx	StrBitXposH		;Auf Bereichsüberschreitung
			bmi	:2			;testen ? Nein, weiter...
			cpx	leftMargin+1
			bne	:1
			cmp	leftMargin+0
::1			bcs	:3			;Bereich nicht überschritten.

::2			ldx	leftMargin+1		;Wert für linken Rand als neue
			lda	leftMargin+0		;X-Koordinate setzen.

::3			pha				;LOW-Byte merken.
			and	#%11111000		;Zeiger auf erstes Byte für
			sta	r4L			;Grafikdaten berechnen.
			cpx	#$00
			bne	:4
			cmp	#%11000000
			bcc	:6

::4			sec
			sbc	#$80
			pha
			lda	r5L
			clc
			adc	#$80
			sta	r5L
			sta	r6L
			bcc	:5
			inc	r5H
			inc	r6H
::5			pla

::6			sta	r1L			;Zeiger auf Grafikspeicher.

			lda	StrBitXposH		;X-Koordinate in CARDs
			sta	r3L			;umrechnen.
			lsr	r3L
			lda	StrBitXposL
			ror
			lsr	r3L
			ror
			lsr	r3L
			ror
			sta	r7L			;CARD-Position merken.

			lda	leftMargin+1		;Wert für den linken Rand
			lsr				;des aktuellen Textfensters
			lda	leftMargin+0		;in CARDs umrechnen.
			ror
			lsr
			lsr
			sec				;Textausgabe links vom Rand
			sbc	r7L			;des aktuellen Textfensters ?
			bpl	:7			;Nein, weiter...
			lda	#$00			;X-Koordinate auf linken Rand.
::7			sta	CurStreamCard		;CARD-Position merken.

			lda	StrBitXposL
			and	#%00000111		;Anzahl ungültige Bits im
			sta	r7L			;ersten Grafik-Byte berechnen.

			pla
			and	#%00000111
			tay
			lda	BitData3,y		;Bit-Maske für die zu
			sta	r3L			;übernehmenden Bits berechnen.
			eor	#%11111111		;Bit-Maske für die zu
			sta	r9L			;setzenden Bits berechnen.

			ldy	r11L
			dey

;*** Letztes Byte bestimmen.
			ldx	rightMargin+1		;Rechte Grenze überschritten ?
			lda	rightMargin+0
			cpx	r11H
			bne	:8
			cmp	r11L
::8			bcs	:9			;Nein, weiter...

			tay
::9			tya
			and	#%00000111
			tax
			lda	BitData4,x		;Bit-Maske für die zu
			sta	r4H			;übernehmenden Bits berechnen.
			eor	#%11111111		;Bit-Maske für die zu
			sta	r9H			;setzenden Bits berechnen.

			tya
			sec
			sbc	r4L
			bpl	:10
			lda	#$00

::10			lsr
			lsr
			lsr
			clc
			adc	CurStreamCard
			sta	r8L			;Anzahl Stream-Bytes merken.
			cmp	r3H			;Muß größer als die Anzahl der
			bcs	:11			;Datenbytes sein!
			lda	r3H

::11			cmp	#$03			;Mind. 1 Datenbyte ?
			bcs	:13			;Ja, weiter...
			cmp	#$02			;Nur Start/Endbyte ?
			bne	:12			;Nein, weiter... (1 Byte!)
			lda	#$01			;Immer nur 1 Byte setzen.

::12			asl				;Anzahl Bits berechnen.
			asl				;Nur Werte $00 und $10 !!!
			asl
			asl
			sta	r12L

;*** Anzahl der Bit-Verschiebungen
;    berechnen.
			lda	r7L			;Anzahl Bits in erstem
							;Grafik-Byte auf Bildschirm.
			sec				;Anzahl Bits im erstem
			sbc	BitStr1stBit		;Bit-Stream-Byte.

			clc				;Zeiger auf Tabelle berechnen.
			adc	#$08
			clc
			adc	r12L
			tax
			lda	BitMoveRout,x		;Einsprungadresse berechnen.
			clc
			adc	#< A1
			tay
			lda	#$00
			adc	#> A1
			bne	:14

::13			lda	#> PrepBitStream
			ldy	#< PrepBitStream
::14			sta	r12H
			sty	r12L
:CurModusOK		clc
			rts

;*** Einsprungadressen in die
;    Berechnungsroutinen.
:BitMoveRout		b (D0a - A1), (C1 - A1)
			b (C2 - A1), (C3 - A1)
			b (C4 - A1), (C5 - A1)
			b (C6 - A1), (C7 - A1)
			b (A8 - A1), (A7 - A1)
			b (A6 - A1), (A5 - A1)
			b (A4 - A1), (A3 - A1)
			b (A2 - A1), (A1 - A1)

			b (D0a - A1), (D1 - A1)
			b (D2 - A1), (D3 - A1)
			b (D4 - A1), (D5 - A1)
			b (D6 - A1), (D7 - A1)
			b (B8 - A1), (B7 - A1)
			b (B6 - A1), (B5 - A1)
			b (B4 - A1), (B3 - A1)
			b (B2 - A1), (B1 - A1)

;*** Baseline und Kursivmöglichkeit überprüfen.
:ChkBaseItalic		lda	currentMode		;Unterstreichen aktiv ?
			bpl	:2			;Nein, weiter...

			ldy	r1H
			cpy	BaseUnderLine		;Unterstreichen möglich ?
			beq	:1			;Ja, weiter...
			dey				;Auf Baseline testen.
			cpy	BaseUnderLine		;Unterstreichen möglich ?
			bne	:2			;Nein, weiter...

::1			lda	r10L			;Baseline möglich,
			eor	#%11111111		;Invertieren der letzten
			sta	r10L			;Zeichensatz-Zeile.

::2			lda	currentMode
			and	#%00010000		;Kursiv-Modus aktiv ?
			beq	CurModusOK		;Nein, weiter...

			lda	r10H			;Zähler für Pixelverschiebung
			lsr				;bei Kursivschrift einlesen.
			bcs	:5			;Verschieben ? Nein, weiter...

			ldx	StrBitXposL		;X-Koordinate korrigieren.
			bne	:3
			dec	StrBitXposH
::3			dex
			stx	StrBitXposL

			ldx	r11L
			bne	:4
			dec	r11H
::4			dex
			stx	r11L

			jsr	StreamInfo

::5			lda	rightMargin+1
			cmp	StrBitXposH
			bne	:6
			lda	rightMargin+0
			cmp	StrBitXposL
::6			bcc	:8
			jmp	TestLeftMargin

::8			sec
:StreamOverRun		rts

;*** Neue Grafikdaten in Grafikdatenspeicher kopieren.
:WriteNewStream		ldy	r1L			;Zeiger auf Grafikspeicher.
			ldx	CurStreamCard
			lda	SetStream,x
			cpx	r8L			;Nur 1 CARD berechnen ?
			beq	:5			;Ja, weiter...
			bcs	StreamOverRun		;Überlauf, Ende...

;*** Startbyte definieren.
			eor	r10L			;Zeichen invertieren.
			and	r9L			;Die zu übernehmenden Bits
			sta	StreamByteData +1	;isolieren und merken.
			lda	r3L			;Bits aus Grafikspeicher
			jsr	AddStreamByte		;einlesen und isolieren.
							;Daten verknüpfen.

;*** Datenbytes definieren.
::2			tya				;Zeiger auf nächstes CARD
			clc				;setzen.
			adc	#$08
			tay
			inx
			cpx	r8L			;Letztes CARD erreicht ?
			beq	:3			;Ja, weiter...

			lda	SetStream,x		;Datenbyte einlesen.
			eor	r10L			;Invertieren.
			jsr	ByteIn_r5_r6		;In Grafikspeicher kopieren.
			jmp	:2			;Nächstes Card setzen.

;*** Bits im letzten CARD bestimmen.
::3			lda	SetStream,x		;Letztes CARD bestimmen.
			eor	r10L			;Zeichen invertieren.
			and	r9H			;Die zu übernehmenden Bits
			sta	StreamByteData +1	;isolieren und merken.
			lda	r4H			;Bits aus Grafikspeicher
			jmp	AddStreamByte		;einlesen und merken.

;*** Nur 1 CARD bestimmen.
::5			eor	r10L			;Invertieren.
			and	r9H			;Die zu übernehmenden Bits
			eor	#$ff			;isolieren und merken.
			ora	r3L
			ora	r4H
			eor	#$ff
			sta	StreamByteData +1
			lda	r3L			;Die ersten und letzten Bits
			ora	r4H			;im CARD isolieren und merken.

;*** Grafikdaten in aktuellem Byte einlesen und mit
;    den neuen Grafikdaten verküpfen.
:AddStreamByte		and	(r6L),y
:StreamByteData		ora	#$00			;Neue Grafikdaten addieren.

;*** Ein Byte in Vektor ":r5" und ":r6" kopieren.
;    yReg dient als Zeiger auf Speicherstelle.
:ByteIn_r5_r6		sta	(r6L),y
			sta	(r5L),y
			rts

;*** Neuen Bit-Stream initialisieren.
:InitNewStream		ldx	r8L			;Anzahl Bit-Stream-Bytes.

			lda	#$00
::1			sta	NewStream,x		;Datenspeicher für die neuen
			dex				;Bit-Stream-Daten löschen.
			bpl	:1

			lda	r8H
			and	#%01111111		;Schriftstil definiert ?
			bne	:5			;Ja, weiter...
::2			jsr	DefBitOutBold

::3			ldx	r8L
::4			lda	NewStream,x		;Neue Bit-Stream-Daten in
			sta	SetStream,x		;Zwischenspeicher kopieren.
			dex
			bpl	:4
			inc	r8H
			rts

::5			cmp	#$01
			beq	:6
			ldy	r10H
			dey				;Kursivschrift aktiv ?
			beq	:2			;Nein, weiter...

			dey				;Daten für Kursiv vorbereiten.
			php				;Dabei werden die oberen
			jsr	DefBitOutBold		;Pixelzeilen jeweils um 1 Bit
			jsr	AddFontWidth		;nach links zurückgesetzt.
			plp
			beq	:7

::6			jsr	AddFontWidth		;Zeiger auf Daten richten.
			jsr	CopyCharData		;Zeichendaten einlesen.
			jsr	DefBitOutBold		;Rahmen für Outline berechnen.
			lda	r2L			;Zeiger auf Daten wieder
			sec				;zurücksetzen.
			sbc	curSetWidth+0
			sta	r2L
			lda	r2H
			sbc	curSetWidth+1
			sta	r2H
::7			jsr	CopyCharData
			jsr	DefBitOutBold		;Rahmen für Outline berechnen.
			jsr	DefOutLine		;Fläche löschen -> Outline.
			jmp	:3			;Neuen Stream übertragen.

;*** Zeichensatzbreite addieren.
:AddFontWidth		lda	curSetWidth+0
			clc
			adc	r2L
			sta	r2L
			lda	curSetWidth+1
			adc	r2H
			sta	r2H
			rts

;*** Daten für Outline berechnen.
:DefOutLine		ldy	#$ff
::1			iny
			ldx	#$07
::2			lda	SetStream,y
			and	BitData2 ,x		;Bit gesetzt ?
			beq	:3			;Nein, weiter...
			lda	BitData2 ,x		;Bitmaske isolieren.
			eor	#%11111111
			and	NewStream,y		;Bit löschen und
			sta	NewStream,y		;zurückschreiben.
::3			dex				;8 Bit überprüft ?
			bpl	:2			;Nein, weiter...
			cpy	r8L			;Alle Cards geprüft ?
			bne	:1			;Nein, weiter...
			rts

;*** Bit-Verschiebung für Funktionen
;    Outline/Bold berechnen.
:DefBitOutBold		jsr	MovBitStrData

			ldy	#$ff
::1			iny

			ldx	#$07
::2			lda	SetStream  ,y
			and	BitData2   ,x
			beq	:7

			jsr	AddOutBoldData
			inx
			cpx	#$08
			bne	:3

			lda	NewStream-1,y
			ora	#%00000001
			sta	NewStream-1,y
			bne	:4

::3			jsr	AddOutBoldData
::4			dex
			dex
			bpl	:5

			lda	NewStream+1,y
			ora	#%10000000
			sta	NewStream+1,y
			bne	:6

::5			jsr	AddOutBoldData
::6			inx
::7			dex
			bpl	:2
			cpy	r8L
			bne	:1
			rts

;*** BIT-Stream für aktuelle Zeile um 1 Pixel verschieben.
:MovBitStrData		lsr	SetStream+0
			ror	SetStream+1
			ror	SetStream+2
			ror	SetStream+3
			ror	SetStream+4
			ror	SetStream+5
			ror	SetStream+6
			ror	SetStream+7
			rts

;*** Daten für Outline/Bold addieren.
:AddOutBoldData		lda	NewStream  ,y
			ora	BitData2   ,x
			sta	NewStream  ,y
			rts

;*** Zeichen ausgeben. Achtung! ASCII-Code ist um #$20 reduziert!
:PrntCharCode		tay				;ASCII-Code merken.
			lda	r1H			;Y-Koordinate speichern.
			pha

			tya				;ASCII-Code zurücksetzen.
			jsr	DefCharData		;Zeichendaten definieren.
			bcs	:9			;Gültig ? Nein, übergehen.

::1			clc
			lda	currentMode
			and	#%10010000		;Kursiv/Unterstreichen ?
			beq	:2			;Nein, weiter...
			jsr	ChkBaseItalic		;Daten für Kursiv und
							;unterstreichen berechnen.
::2			php				;Schriftstile möglich ?
			bcs	:3			;Nein, übergehen.
			jsr	CopyCharData

::3			bit	r8H			;Outline-Modus aktiv ?
			bpl	:4			;Nein, weiter...
			jsr	InitNewStream
			jmp	:5

::4			jsr	AddFontWidth		;Zeiger auf näcste Bit-Stream-
							;datenzeile setzen.
::5			plp
			bcs	:7

			lda	r1H			;Ist Pixelzeile innerhalb des
			cmp	windowTop		;aktuellen Textfensters ?
			bcc	:7			;Nein, übergehen...
			cmp	windowBottom
			bcc	:6			;Ja, Daten ausgeben...
			bne	:7			;Nein, übergehen...
::6			jsr	WriteNewStream		;Grafikdaten ausgeben.

::7			inc	r5L			;Zeiger auf Grafikspeicher
			inc	r6L			;korrigieren.
			lda	r5L
			and	#$07
			bne	:8
			inc	r5H
			inc	r6H

			lda	r5L
			clc
			adc	#$38
			sta	r5L
			sta	r6L
			bcc	:8
			inc	r5H
			inc	r6H

::8			inc	r1H			;Zeiger auf nächste Pixelzeile.
			dec	r10H			;Alle Zeilen ausgegeben ?
			bne	:1			;Nein, weiter...
::9			pla				;Y-Koordinate zurücksetzen.
			sta	r1H
			rts

;*** Bit-Stream vorbereiten.
;    Nur bei max. 16 Pixel breiten Zeichen (gleich 2 Byte).
:A1			lsr
:A2			lsr
:A3			lsr
:A4			lsr
:A5			lsr
:A6			lsr
:A7			lsr
:A8			jmp	DefBitStream2

:B1			lsr
			ror	SetStream+1
			ror	SetStream+2
:B2			lsr
			ror	SetStream+1
			ror	SetStream+2
:B3			lsr
			ror	SetStream+1
			ror	SetStream+2
:B4			lsr
			ror	SetStream+1
			ror	SetStream+2
:B5			lsr
			ror	SetStream+1
			ror	SetStream+2
:B6			lsr
			ror	SetStream+1
			ror	SetStream+2
:B7			lsr
			ror	SetStream+1
			ror	SetStream+2
:B8			jmp	DefBitStream2

:C1			asl
:C2			asl
:C3			asl
:C4			asl
:C5			asl
:C6			asl
:C7			asl
			jmp	DefBitStream2

:D1			asl	SetStream+2
			rol	SetStream+1
			rol
:D2			asl	SetStream+2
			rol	SetStream+1
			rol
:D3			asl	SetStream+2
			rol	SetStream+1
			rol
:D4			asl	SetStream+2
			rol	SetStream+1
			rol
:D5			asl	SetStream+2
			rol	SetStream+1
			rol
:D6			asl	SetStream+2
			rol	SetStream+1
			rol
:D7			asl	SetStream+2
			rol	SetStream+1
			rol
			jmp	DefBitStream2

;*** Bit-Stream vorbereiten.
;    Einügen/Löschen von Bits.
:PrepBitStream		sta	SetStream		;Erstes Byte speichern.

			lda	r7L			;Anzahl der zu löschenden
			sec				;Bits berechnen.
			sbc	BitStr1stBit
			beq	:2			;Bits löschen ? Nein, weiter...
			bcc	DefBitStream		;Ja, Bits löschen.

			tay				;Anzahl Bits als Zähler.
::1			jsr	MovBitStrData		;Bit-Stream um 1 Bit nach
							;rechts verschieben.
			dey				;Bits gelöscht ?
			bne	:1			;Nein, weiter...

::2			lda	SetStream
			jmp	DefBitStream2

;*** Überflüssige Bits in Bit-Stream
;    für aktuelles Zeichen löschen.
:DefBitStream		lda	BitStr1stBit		;Zeiger auf erstes Bit.
			sec				;Anzahl zu setzender Bits
			sbc	r7L			;abziehen und als Bit-Zähler
			tay				;in yReg kopieren.

::1			asl	SetStream+7		;Bit-Stream um 1 Bit nach
			rol	SetStream+6		;links verschieben.
			rol	SetStream+5
			rol	SetStream+4
			rol	SetStream+3
			rol	SetStream+2
			rol	SetStream+1
			rol	SetStream+0
			dey
			bne	:1

			lda	SetStream

;*** Bit-Stream-Daten bearbeiten.
:DefBitStream2		sta	SetStream

			bit	currentMode		;Schriftstil "Fett" ?
			bvc	D0a			;Nein, weiter...

			lda	#$00			;Bit #7 in aktuellem Bit-Stream
			pha				;nicht setzen.

			ldy	#$ff
::1			iny
			ldx	SetStream,y		;Bit-Stream-Byte einlesen.
			pla				;Bit #7-Wert einlesen.
			ora	BoldData ,x		;"Fettschrift"-Wert addieren.
			sta	SetStream,y		;Neues Bit-Stream-Byte setzen.
			txa
			lsr
			lda	#$00			;Bit #7 im nächstes Bytes des
			ror				;Bit-Streams definieren.
			pha
			cpy	r8L			;Alle Bytes des Bit-Streams
			bne	:1			;verdoppelt ? Nein, weiter...

			pla
:D0a			rts

;*** Erstes Datenbyte auswerten.
;    Einsprung in ":CharXYBit"
:CopyCharData		ldy	#$00
			jmp	(r13)

;*** Max. 24 Bit-Breites Zeichen.
:Char24Bit		sty	SetStream+1
			sty	SetStream+2
			lda	(r2L),y			;Datenbyte einlesen.
			and	BitStrDataMask		;Ungültige Bits am Anfang und
			and	r7H			;Ende entfernen.
			jmp	(r12)

;*** Max. 32 Bit-Breites Zeichen.
:Char32Bit		sty	SetStream+2
			sty	SetStream+3
			lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
			iny
			lda	(r2L),y
			and	r7H
			sta	SetStream+1
:le356			lda	SetStream+0
			jmp	(r12)

;*** Max. 40 Bit-Breites Zeichen.
:Char40Bit		sty	SetStream+3
			sty	SetStream+4
			lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
			iny
			lda	(r2L),y
			sta	SetStream+1
			iny
			lda	(r2L),y
			and	r7H
			sta	SetStream+2
			jmp	le356

;*** Max. 48 Bit-Breites Zeichen.
:Char48Bit		lda	(r2L),y
			and	BitStrDataMask
			sta	SetStream+0
::1			iny
			cpy	r3H
			beq	:2
			lda	(r2L),y
			sta	SetStream,y
			jmp	:1

::2			lda	(r2L),y
			and	r7H
			sta	SetStream+0,y
			lda	#$00
			sta	SetStream+1,y
			sta	SetStream+2,y
			beq	le356

;*** Variablen/Zwischenspeicher für Zeichenausgabe über PutChar.
:CurStreamCard		b $00
:StrBitXposL		b $34
:StrBitXposH		b $01

;*** Zeichen ausgeben.
:xPutChar		cmp	#$20
			bcs	:1
			tay
			lda	PrintCodeL -$08,y
			ldx	PrintCodeH -$08,y
			jmp	CallRoutine

::1			pha				;ASCII-Zeichen merken.
			ldy	r11H			;X-Koordinate speichern.
			sty	r13H
			ldy	r11L
			sty	r13L
			ldx	currentMode		;Zeichenbreite berechnen.
			jsr	xGetRealSize
			dey				;Breite -1 und zur
			tya				;aktuellen X-Koordinate
			clc				;addieren.
			adc	r13L
			sta	r13L
			bcc	:2
			inc	r13H

::2			lda	rightMargin+1		;Zeichen noch innerhalb
			cmp	r13H			;des Textfensters ?
			bne	:3
			lda	rightMargin+0
			cmp	r13L
::3			bcc	:7			;Nein, Fehlerbehandlung.

			jsr	TestLeftMargin
			beq	:5			;Ja, weiter...
			bcs	:6			;Nein, Fehlerbehandlung.

::5			pla
			sec
			sbc	#$20			;Zeichencode umrechnen und
			jmp	PrntCharCode		;Zeichen ausgeben.

::6			lda	r13L
			clc
			adc	#$01
			sta	r11L
			lda	r13H
			adc	#$00
			sta	r11H

::7			pla
			ldx	StringFaultVec+1
			lda	StringFaultVec+0
			jmp	CallRoutine

;*** Einsprung für Steuercodes.
:PrintCodeL		b < xBACKSPACE,          < xFORWARDSPACE
			b < xSetLF,              < xHOME
			b < xUPLINE,             < xSetCR
			b < xULINEON,            < xULINEOFF
			b < xESC_GRAPHICS,       < xESC_RULER
			b < xREVON,              < xREVOFF
			b < xGOTOX,              < xGOTOY
			b < xGOTOXY,             < xNEWCARDSET
			b < xBOLDON,             < xITALICON
			b < xOUTLINEON,          < xPLAINTEXT

:PrintCodeH		b > xBACKSPACE,          > xFORWARDSPACE
			b > xSetLF,              > xHOME
			b > xUPLINE,             > xSetCR
			b > xULINEON,            > xULINEOFF
			b > xESC_GRAPHICS,       > xESC_RULER
			b > xREVON,              > xREVOFF
			b > xGOTOX,              > xGOTOY
			b > xGOTOXY,             > xNEWCARDSET
			b > xBOLDON,             > xITALICON
			b > xOUTLINEON,          > xPLAINTEXT

;*** Textzeichen ausgeben.
:xSmallPutChar		sec
			sbc	#$20
			jmp	PrntCharCode

;*** Cursor nach rechts bewegen.
:xFORWARDSPACE		lda	#$00
			clc
			adc	r11L
			sta	r11L
			bcc	:1
			inc	r11H
::1			rts

;*** Cursor nach links/oben.
:xHOME			lda	#$00
			sta	r11L
			sta	r11H
			sta	r1H
			rts

;*** Eine Zeile höher.
:xUPLINE		lda	r1H
			sec
			sbc	curSetHight
			sta	r1H
			rts

;*** Zum Anfang der nächsten Zeile.
:xSetCR			lda	leftMargin+1
			sta	r11H
			lda	leftMargin+0
			sta	r11L
;			jmp	xSetLF

;*** Eine Zeile tiefer.
:xSetLF			lda	r1H
			sec
			adc	curSetHight
			sta	r1H
			rts

;*** Neue X-Koordinate setzen.
:xGOTOX			jsr	GetXYbyte
			sta	r11L
			jsr	GetXYbyte
			sta	r11H
			rts

;*** Neue X und Y-Koordinate setzen.
:xGOTOXY		jsr	xGOTOX

;*** Neue Y-Koordinate setzen.
:xGOTOY			jsr	GetXYbyte
			sta	r1H
			rts

;*** Koordinatenbyte einlesen.
:GetXYbyte		jsr	SetNxByte_r0
			ldy	#$00
			lda	(r0L),y
			rts

;*** Drei Byte überlesen.
:xNEWCARDSET		lda	#$03
			jmp	Add_A_r0

;*** Unterstreichen aus.
:xULINEOFF		lda	#%01111111
			b $2c

;*** Inversdarstellung aus.
:xREVOFF		lda	#%11011111
			and	currentMode
			sta	currentMode
			rts

;*** Unterstreichen ein.
:xULINEON		lda	#%10000000
			b $2c

;*** Fettschrift ein.
:xBOLDON		lda	#%01000000
			b $2c

;*** Inversdarstellung ein.
:xREVON			lda	#%00100000
			b $2c

;*** Kursivschrift ein.
:xITALICON		lda	#%00010000
			b $2c

;*** "Outline"-Sschrift ein.
:xOUTLINEON		lda	#%00001000
			ora	currentMode
			b $2c

;*** Standard-Schrift ein.
:xPLAINTEXT		lda	#$00
			sta	currentMode
			rts

;*** Letztes Zeichen löschen.
:RemoveChar		ldx	currentMode
			jsr	xGetRealSize
			sty	CurCharWidth

;*** Ein Zeichen zurück.
:xBACKSPACE		lda	r11L
			sec
			sbc	CurCharWidth
			sta	r11L
			bcs	:1
			dec	r11H
::1			lda	r11H			;X-Koordinate merken.
			pha
			lda	r11L
			pha
			lda	#$5f			;Delete-Code ausgeben. Ist
			jsr	PrntCharCode		;normalerweise $7F, Wert wurde
			pla				;aber um $20 reduziert!
			sta	r11L			;X-Koordinate zurücksetzen.
			pla
			sta	r11H
			rts

;*** Grafikbefehle ausführen.
:xESC_GRAPHICS		jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			jsr	xGraphicsString
			jsr	:2
::2			ldx	#r0L
			jmp	Ddec

;******************************************************************************
;*** String-Routinen Teil #2.
;******************************************************************************
			t "-G3_iPutString"
;******************************************************************************

;*** Zeichenkette ausgeben.
:xPutString		ldy	#$00
			lda	(r0L),y			;Zeichen einlesen.
			beq	:1			;$00 gefunden ? Ja, Ende...
			jsr	xPutChar		;Zeichen ausgeben.
			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.
			bne	xPutString		;Endadresse $0000 erreicht ?
							; => Nächstes Zeichen ausgeben.

::1			rts

;******************************************************************************
;*** PutDecimal-Routine.
;******************************************************************************
			t "-G3_PutDecimal"
;******************************************************************************

;*** Zahl in ASCII umwandeln.
:ConvDEZtoASCII		sta	r2L
			lda	#$04			;Zeiger auf 10000er.
			sta	r2H
			lda	#$00
			sta	r3L
			sta	r3H

::1			ldy	#$00
			ldx	r2H
::2			lda	r0L			;Wert 10^x von Dezimal-Zahl
			sec				;subtrahieren.
			sbc	DEZ_DATA_L,x
			sta	r0L
			lda	r0H
			sbc	DEZ_DATA_H,x
			bcc	:3			;Unterlauf ? Ja, weiter...
			sta	r0H
			iny
			jmp	:2

::3			lda	r0L			;Zahl auf letzten Wert
			adc	DEZ_DATA_L,x		;zurücksetzen.
			sta	r0L
			tya				;Stelle in ASCII-Zahl > $00 ?
			bne	:4			;Ja, weiter...
			cpx	#$00			;Linker Rand erreicht ?
			beq	:4			;Ja, weiter...
			bit	r2L			;Führende Nullen ausgeben ?
			bvs	:5			;Nein, weiter...

::4			ora	#$30			;Zahl in Zwischenspeicher
			ldx	r3L			;übertragen.
			sta	SetStream,x

			ldx	currentMode		;Zeichenbreite des
			jsr	xGetRealSize		;aktuellen Zeichen berechnen.
			tya				;Zeichenbreite addieren.
			clc
			adc	r3H
			sta	r3H
			inc	r3L

			lda	#%10111111
			and	r2L
			sta	r2L
::5			dec	r2H			;Nächste Ziffer des
			bpl	:1			;ASCII-Strings berechnen.
			rts

;*** Tabelle für Umrechnung DEZ->ASCII.
;Wird auch von e.Register verwendet.
.DEZ_DATA_L		b < 1,< 10,< 100,< 1000,< 10000
.DEZ_DATA_H		b > 1,> 10,> 100,> 1000,> 10000

;*** Standardzeichensatz aktivieren.
:xUseSystemFont		lda	#> BSW_Font
			sta	r0H
			lda	#< BSW_Font
			sta	r0L

;*** Benutzerzeichensatz aktivieren.
:xLoadCharSet		ldy	#$00
::1			lda	(r0L),y
			sta	baselineOffset,y
			iny
			cpy	#$08
			bne	:1

			lda	r0L
			clc
			adc	curIndexTable+0
			sta	curIndexTable+0
			lda	r0H
			adc	curIndexTable+1
			sta	curIndexTable+1

			lda	r0L
			clc
			adc	cardDataPntr +0
			sta	cardDataPntr +0
			lda	r0H
			adc	cardDataPntr +1
			sta	cardDataPntr +1
::2			rts

;*** Breite des aktuellen Zeichens
;    (im Akku) ermitteln.
:xGetCharWidth		sec
			sbc	#$20			;Zeichencode berechnen.
			bcs	GetCodeWidth		;Steuercode ? Nein -> weiter..
			lda	#$00			;Steuercode, Breite = $00.
			rts

;*** Auf "Delete"-Code testen.
;    ASCII-Code um $20 reduziert!
:GetCodeWidth		cmp	#$5f			;Delete-Code ?
			bne	:1			;Nein, weiter...
			lda	CurCharWidth		;Breite des letzten Zeichens.
			rts

::1			asl
			tay
			iny
			iny
			lda	(curIndexTable),y
			dey
			dey
			sec
			sbc	(curIndexTable),y
			rts

;*** Zeichenbreite ermitteln.
;    ":currentMode" im xReg übergeben!
:xGetRealSize		sec				;Zeichencode berechnen.
			sbc	#$20
			jsr	GetCodeWidth		;Zeichenbreite ermitteln.
			tay
			txa				;Schriftstil merken.
			ldx	curSetHight		;Zeichensatzhöhe einlesen.
			pha				;Schriftstil zwischenspeichern.
			and	#%01000000		;Schriftstil "BOLD" ?
			beq	:1			;Nein, weiter...
			iny				;Ja, Zeichenbreite +1.
::1			pla
			and	#%00001000		;Schriftstil "OUTLINE" ?
			beq	:2			;Nein, weiter...
			inx				;Ja, Zeichenbreite und
			inx				;Zeichenhöhe +2 Pixel.
			iny
			iny
			lda	#$02
::2			clc				;Differenz Oberkante Zeichen
			adc	baselineOffset		;und Baseline +(AKKU) Pixel.
			rts

;*** Linie zeichnen.
;    r11L/r11H = yLow/yHigh
;    r3  /r4   = xLow/xHigh
:xDrawLine		php				;Statusbyte merken.

			lda	r11H			;Y_Länge der Linie berechnen.
			sec
			sbc	r11L
			sta	r7L
			lda	#$00
			sta	r7H
			bcs	:1
			sec				;umrechnen.
			sbc	r7L
			sta	r7L

::1			lda	r4L			;X_Länge der Linie berechnen.
			sec
			sbc	r3L
			sta	r12L
			lda	r4H
			sbc	r3H
			sta	r12H
			ldx	#r12L			;Länge in Absolut-Wert
			jsr	Dabs			;umrechnen.

			lda	r12H			;X_Länge größer Y_Länge ?
			cmp	r7H
			bne	:2
			lda	r12L
			cmp	r7L
::2			bcs	SetVarHLine		;Ja, X_Linie zeichnen.
			jmp	SetVarVLine		; -> Y_Linie zeichnen.

;*** Linie zwischen +45 und -45 Grad
;    zeichnen. Y-Abstand zwischen zwei
;    X-Punkten max. 1 Pixel.
:SetVarHLine		lda	r7L			;Y-Delta-Wert zwischen zwei
			asl				;Punkten berechnen.
			sta	r9L
			lda	r7H
			rol
			sta	r9H

			lda	r9L
			sec
			sbc	r12L
			sta	r8L
			lda	r9H
			sbc	r12H
			sta	r8H

			lda	r7L
			sec
			sbc	r12L
			sta	r10L
			lda	r7H
			sbc	r12H
			sta	r10H

			asl	r10L
			rol	r10H

			lda	#$ff
			sta	r13L

;*** Linen-Richtung bestimmen.
			jsr	Compare_r3_r4
			bcc	:3			; -> Links nach rechts.

			lda	r11L
			cmp	r11H
			bcc	:2			; -> Oben nach unten.
			lda	#$01
			sta	r13L

::2			ldy	r3H			;X-Koordinaten vertauschen.
			ldx	r3L
			lda	r4H
			sta	r3H
			lda	r4L
			sta	r3L
			sty	r4H
			stx	r4L
			lda	r11H			;Y-Startwert setzen.
			sta	r11L
			jmp	:4

;*** Linie zeichnen (Fortsetzung).
::3			ldy	r11H
			cpy	r11L
			bcc	:4			; -> Unten nach oben.
			lda	#$01
			sta	r13L

::4			plp
			php				;Statusbyte einlesen.
			jsr	xDrawPoint		;Punkt setzen.

			jsr	Compare_r3_r4		;Ende der Linie erreicht ?
			bcs	:8			;Ja, Ende...

			jsr	SetNxByte_r3		;Zeiger auf nächsten Punkt
							;der Linie berechnen.

			bit	r8H			;Y-Koordinate ändern ?
			bpl	:7			;Ja, weiter...

			ldy	#r9L			;Zeiger auf nächstes Pixel
			ldx	#r8L			;setzen.
			jsr	AddVec_Y_X
			jmp	:4

::7			clc				;Y-Koordinate ändern.
			lda	r13L
			adc	r11L
			sta	r11L

			ldy	#r10L			;Zeiger auf nächstes Pixel
			ldx	#r8L			;setzen.
			jsr	AddVec_Y_X
			jmp	:4

::8			plp
			rts

;*** Linie größer +45 oder -45 Grad
;    zeichnen. Y-Abstand zwischen zwei
;    X-Punkten größer als 1 Pixel.
:SetVarVLine		lda	r12L			;X-Delta-Wert zwischen zwei
			asl				;Punkten berechnen.
			sta	r9L
			lda	r12H
			rol
			sta	r9H

			lda	r9L
			sec
			sbc	r7L
			sta	r8L
			lda	r9H
			sbc	r7H
			sta	r8H

			lda	r12L
			sec
			sbc	r7L
			sta	r10L
			lda	r12H
			sbc	r7H
			sta	r10H
			asl	r10L
			rol	r10H

			lda	#$ff
			sta	r13H
			sta	r13L

;*** Linien-Richtung bestimmen.
			lda	r11L
			cmp	r11H
			bcc	:3			; -> Oben nach unten.

			jsr	Compare_r3_r4
			bcc	:2			; -> Links nach rechts.

			ldx	#$00
			stx	r13H
			inx
			stx	r13L

::2			lda	r4H			;X-Startwert setzen.
			sta	r3H
			lda	r4L
			sta	r3L
			ldx	r11L			;Y-Koordinaten vertauschen.
			lda	r11H
			sta	r11L
			stx	r11H
			jmp	:5

::3			jsr	Compare_r3_r4
			bcs	:5			; -> Rechts nach links.

			ldx	#$00
			stx	r13H
			inx
			stx	r13L

::5			plp
			php				;Statusbyte einlesen.
			jsr	xDrawPoint		;Punkt zeichnen.

			lda	r11L
			cmp	r11H			;Ende der Linie erreicht ?
			bcs	:7			;Ja, Ende...
			inc	r11L			;Zeiger auf nächstes Byte.
			bit	r8H			;X-Koordinate ändern ?
			bpl	:6			;Ja, weiter...

			ldy	#r9L			;Zeiger auf nächstes Pixel
			ldx	#r8L			;setzen.
			jsr	AddVec_Y_X

			jmp	:5

::6			ldy	#r13L			;X/Koordinate ändern.
			ldx	#r3L
			jsr	AddVec_Y_X

			ldy	#r10L			;Zeiger auf nächstes Pixel
			ldx	#r8L			;setzen.
			jsr	AddVec_Y_X
			jmp	:5

::7			plp
			rts

;*** Zeiger auf nächstes Pixel setzen.
:AddVec_Y_X		lda	zpage +0,y
			clc
			adc	zpage +0,x
			sta	zpage +0,x
			lda	zpage +1,y
			adc	zpage +1,x
			sta	zpage +1,x
			rts

;*** Einzelnen Punkt setzen.
:xDrawPoint		php				;Statusflag merken.
			jsr	xGetScanLine_r11	;Grafikzeile berechnen.

			lda	r3L			;Absoluten Bytewert ermitteln.
			and	#%11111000
			tay
			lda	r3H
			beq	:1
			inc	r5H
			inc	r6H

::1			lda	r3L
			and	#%00000111
			tax				;Zu setzendes Bit
			lda	BitData1,x		;berechnen.

			plp				;Statusflag einlesen.
			bmi	:4			;Hintergrund nach Vordergrund.
			bcc	:2			; -> Punkt löschen.
			ora	(r5L),y			; -> Punkt setzen.
			jmp	:3

::2			eor	#$ff
			and	(r5L),y

::3			jmp	ByteIn_r5_r6		;In Grafikspeicher kopieren.

::4			pha				;Pixel aus Hintergrundgrafik
			eor	#$ff			;einlesen und in Vordergrund-
			and	(r5L),y			;grafik kopieren.
			sta	(r5L),y
			pla
			and	(r6L),y
			ora	(r5L),y
			sta	(r5L),y
			rts

;*** Punkt-Zustand ermitteln.
:xTestPoint		jsr	xGetScanLine_r11	;Grafikzeile berechnen.

			lda	r3L			;Absoluten Bytewert ermitteln.
			and	#%11111000		;Achtung! Bei GEOS-V2 wird das
			tay				;Register ":r6" zum Auslesen
			lda	r3H			;verwendet, aber bei Front/
			beq	:1			;BackGrafxScrn sind die Daten
			inc	r5H			;im Normalfall im FrontScreen!
							;Deshalb ":r5" verwenden!!!!!
::1			lda	r3L
			and	#%00000111
			tax				;Zu testendes Bit
			lda	BitData1,x		;berechnen.
			and	(r5L),y
			beq	:2
			sec				; -> Punkt ist gesetzt.
			rts
::2			clc				; -> Punkt ist gelöscht.
			rts

;*** Bitmap-Ausschnitt ausgeben.
:xBitOtherClip		ldx	#$ff			;Flag setzen: BitOtherClip.
			b $2c
:xBitmapClip		ldx	#$00			;Flag setzen: BitmapClip.
:BitAllClip		stx	r9H

			lda	#$00
			sta	r3L
			sta	r4L

::1			lda	r12L			;Pixelzeilen am Anfang überlesen?
			ora	r12H
			beq	:3			; => Nein, weiter...

			lda	r11L			;Anzahl CARDs Links überlesen.
			jsr	:4

			lda	r2L			;Anzahl CARDs Ausschnitt überlesen.
			jsr	:4

			lda	r11H			;Anzahl CARDs Rechts überlesen.
			jsr	:4

			lda	r12L			;Zähler Pixelzeilen überlesen -1.
			bne	:2
			dec	r12H
::2			dec	r12L
			jmp	:1

::3			lda	r11L			;Anzahl CARDs Links überlesen.
			jsr	:4

			jsr	PrnPixelLine		;Bitmap anzeigen.

			lda	r11H			;Anzahl CARDs Rechts überlesen.
			jsr	:4

			inc	r1H
			dec	r2H			;Alle Pixelzeilen ausgegeben?
			bne	:3			; => Nein, weiter...
			rts

;--- Anzahl Cards überlesen.
::4			cmp	#$00			;Anzahl CARDs = 0 ?
			beq	:5			; => Ja, Ende...
::4a			pha				;Zähler zwischenspeichern.
			jsr	GetGrafxByte		;Nächstes CARD einlesen.
			pla
			sec
			sbc	#$01			;Alle CARDs übersprungen?
			bne	:4a			; => Nein, weiter...
::5			rts

;*** Bitmap darstellen.
:xi_BitmapUp		pla				;Zeiger auf Inline-Daten
			sta	returnAddress+0		;einlesen.
			pla
			sta	returnAddress+1

			ldy	#$06
::1			lda	(returnAddress),y	;Bitmap-Daten einlesen.
			sta	r0 -1,y			;r0 : Zeiger auf Grafikdaten
			dey				;r1L: X-Position in CARDs
			bne	:1			;r1H: Y-Position in Pixel
							;r2L: Breite in CARDs einlesen.
							;r2H: Höhe in Pixel einlesen.
			jsr	xBitmapUp		;Grafik darstellen.
			jmp	Exit7ByteInline		;Routine beenden.

;*** Bitmap darstellen.
:xBitmapUp		lda	r9H			;Register ":r9H" speichern.
			pha

			lda	#$00			;Flag für gepackte Daten löschen.
			sta	r9H

			sta	r3L			;LOW-Byte der X-Koordinaten
			sta	r4L			;löschen.

::1			jsr	PrnPixelLine

			inc	r1H
			dec	r2H			;Alle Pixelzeilen ausgegeben?
			bne	:1			; => Nein, weiter...

			pla
			sta	r9H			;Register ":r9H" zurücksetzen.
			rts

;*** Pixelzeile ausgeben.
:PrnPixelLine		ldx	r1H			;Grafikzeile berechnen.
			jsr	xGetScanLine

			lda	r2L			;Breite in CARDs merken.
			sta	r3H

			lda	r1L
			cmp	#$20			;x-Position größer 32 CARDs ?
			bcc	:1			; => Nein, weiter...
			inc	r5H			;Highbyte für Vorder-/Hintergrund-
			inc	r6H			;Adresse anpassen => 32*8=256

::1			asl				;Zeiger auf CARD berechnen.
			asl
			asl
			tay

::2			sty	r9L			;Zeiger auf CARD merken.
			jsr	GetGrafxByte		;Byte einlesen und in
			ldy	r9L			;Grafikspeicher schreiben.
			jsr	ByteIn_r5_r6

			tya				;Zeiger auf nächstes CARD.
			clc
			adc	#$08			;Zeiger auf nächstes CARD. Überlauf?
			bcc	:3			; => Nein, weiter...
			inc	r5H			;Highbyte für Vorder-/Hintergrund-
			inc	r6H			;Adressen +256.
::3			tay

			dec	r3H			;Pixelzeile berechnet ?
			bne	:2			; => Nein, weiter...
			rts

;*** Byte aus gepackten Daten einlesen.
:GetGrafxByte		lda	r3L
			and	#%01111111		;Alle Bytes verarbeitet?
			beq	:2			; => Ja, weiter...

			bit	r3L			;Einfach gepackte Daten?
			bpl	:1			; => Ja, weiter...

;--- Daten ungepackt / doppelt gepackt.
			jsr	GetPackedByte		;Byte einlesen.
			dec	r3L			;Anzahl Bytes -1.
			rts

;--- Daten einfach gepackt.
::1			lda	r7H			;Einfach gepacktes Byte einlesen.
			dec	r3L			;Anzahl Bytes -1.
			rts

;---
::2			lda	r4L			;Zähler doppelt gepackte Daten = 0?
			bne	:3			; => Nei, weiter...

			bit	r9H			;BitOtherClip?
			bpl	:3			; => Nein, weiter...

			jsr	extSyncBuffer		;r0 über externe Routine auf
							;Anfang 134-Byte-Puffer setzen.

::3			jsr	GetPackedByte		;Byte einlesen.
			sta	r3L			;Neues Einleitungsbyte speichern.

			cmp	#$dc			;Doppelt gepackte Daten ?
			bcc	:4			; => Nein, weiter...

			sbc	#$dc			;Anzahl doppelt gepackter
			sta	r7L			;Daten berechnen.
			sta	r4H
			jsr	GetPackedByte
			sec
			sbc	#$01			;Anzahl Wiederholungen für
			sta	r4L			;doppelt gepackte Daten ermitteln.

			lda	r0H			;Zeiger auf Beginn der doppelt
			sta	r8H			;gepackten Daten zwischenspeichern.
			lda	r0L
			sta	r8L

			jmp	:2			;Doppelt gepackte Daten einlesen.

::4			cmp	#$80			;Ungepackte Daten ?
			bcs	GetGrafxByte		; => Ja, nächstes Byte einlesen.

			jsr	GetPackedByte		;Gepacktes Byte einlesen und
			sta	r7H			;zwischenspeichern.

			jmp	GetGrafxByte		;Nächstes Byte einlesen.

;*** Byte aus gepackten Daten einlesen.
:GetPackedByte		bit	r9H			;BitOtherClip?
			bpl	:1			; => Nein, weiter...

			jsr	extReadByte		;Byte über externe Routine nach
							;r0 einlesen.

::1			ldy	#$00
			lda	(r0L),y			;Nächstes Byte einlesen.

			jsr	SetNxByte_r0		;Zeiger auf nächstes Byte.

			ldx	r4L			;Doppelt gepackte Daten in Arbeit?
			beq	:3			; => Nein, weiter...
			dec	r4H			;Wiederholungen abgeschlossen?
			bne	:3			; => Nein, weiter...

			ldx	r8H			;Zeiger auf Anfang der doppelt
			stx	r0H			;gepackten Daten zurücksetzen.
			ldx	r8L
			stx	r0L

			ldx	r7L			;Zähler für doppelt gepackte
			stx	r4H			;Bytes initialisieren.

			dec	r4L			;Anzahl Wiederholungen -1.

::3			rts

:extReadByte		jmp	(r13)			;Byte einlesen.
:extSyncBuffer		jmp	(r14)			;r0 auf Anfang 134-Byte-Puffer.

;******************************************************************************
;*** Disketten-Routinen Teil #2.
;*** Müssen im Bereich $E000-$FFFF liegen da die Routinen Diskettenfunktionen
;*** bei aktiviertem I/O benutzen (ReadBlock/ReadLink).
;******************************************************************************

;*** Neues Gerät aktivieren.
:xSetDevice		nop				;Füllbefehl wichtig, da einige
							;Programme daran die Version
							;von GEOS erkennen!

			cmp	curDevice		;Aktuelles Laufwerk ?
			beq	:102			;Ja, weiter...
			pha				;Neue Adresse speichern.
			lda	curDevice		;Aktuelles Laufwerk lesen.
			cmp	#$08			;Diskettenlaufwerk ?
			bcc	:101			;Nein, weiter...
			cmp	#$0c
			bcs	:101			;Nein, weiter...
			jsr	ExitTurbo		;TurboDOS abschalten.

::101			pla				;Neues Laufwerk festlegen.
			sta	curDevice

::102			cmp	#$08			;Diskettenlaufwerk ?
			bcc	:103			;Nein, Ende...
			cmp	#$0c
			bcs	:103			;Nein, Ende...

			tay
			lda	driveType   -8,y	;GEOS-Variablen aktualisieren.
			sta	curType
			cpy	curDrive		;War Laufwerk bereits aktiv ?
			beq	:103			;Ja, weiter...
			sty	curDrive

;--- Ergänzung: 24.01.21/M.Kanet
;DESKTOP2 wechselt bei zwei im System
;installierten Laufwerken auch auf das
;Laufwerk #10, auch wenn das Laufwerk
;nicht im System installiert ist.
;Wenn zuvor kein Treiber für dieses
;Laufwerk verwendet wurde, wird der
;Bereich für den Laufwerkstreiber im
;RAM mit $00-Bytes gefüllt wenn der
;Treiber aus der REU für das Laufwerk
;eingelesen werden soll.
			cmp	#$00			;Laufwerk installiert?
			beq	:103			; => Nein, weiter...

;--- Hinweis:
;Abfrage auf REU entfernt, da GDOS
;immer eine REU vorraussetzt.
;<*>			bit	sysRAMFlg		;REU verfügbar ?
;<*>			bvc	:103			;Nein, weiter...

			jsr	InitForDskDvJob 		;REU-Register einlesen.
			jsr	FetchRAM		;Treiber aus REU nach RAM.
			jsr	DoneWithDskDvJob

::103			lda	Flag_ScrSaver		;Status für Bilschirmschoner.
			bmi	:104
			lda	#%01000000		;Bildschirmschoner neu starten.
			sta	Flag_ScrSaver

::104			ldx	#$00			;OK!
			rts

;*** Datei umbenennen.
:xRenameFile		lda	r0H			;Zeiger auf neuen Dateinamen
			pha				;zwischenspeichern.
			lda	r0L
			pha
			jsr	FindFile		;Datei suchen.
			pla				;Zeiger auf neuen Dateinamen
			sta	r0L			;zurückschreiben.
			pla
			sta	r0H
			txa				;Diskettenfehler ?
			bne	:55			;Ja, Abbruch...

			clc				;Zeiger auf Dateiname innerhalb
			lda	#$03			;Verzeichniseintrag berechnen.
			adc	r5L
			sta	r5L
			bcc	:51
			inc	r5H

::51			ldy	#$00			;Neuen Dateinamen in
::52			lda	(r0L),y			;Verzeichniseintrag kopieren.
			beq	:53
			sta	(r5L),y
			iny
			cpy	#$10
			bcc	:52
			bcs	:54

::53			lda	#$a0			;Dateiname auch 16 Zeichen
			sta	(r5L),y			;mit $A0-Codes auffüllen.
			iny
			cpy	#$10
			bcc	:53
::54			jmp	PutBlock_dskBuf		;Sektor zurückschreiben.
::55			rts

;*** Byte aus Datensatz einlesen.
:xReadByte		ldy	r5H
			cpy	r5L
			beq	:52
			lda	(r4L),y
			inc	r5H
			ldx	#$00
::51			rts

::52			ldx	#$0b
			lda	r1L
			beq	:51

			jsr	GetBlock
			txa
			bne	:51

			ldy	#$02
			sty	r5H
			dey
			lda	(r4L),y
			sta	r1H
			tax
			dey
			lda	(r4L),y
			sta	r1L
			beq	:53
			ldx	#$ff
::53			inx
			stx	r5L
			jmp	xReadByte

;*** Datei löschen.
:xDeleteFile		jsr	DelFileEntry		;Dateieintrag löschen.
			txa				;Diskettenfehler ?
			bne	DelFileExit1		;Ja, Abbruch...

			lda	#> dirEntryBuf		;Zeiger auf Dateieintrag.
			sta	r9H
			lda	#< dirEntryBuf
			sta	r9L

;*** Belegte Blocks einer Datei freigeben.
:xFreeFile		jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	DelFileExit1		;Ja, Abbruch...

			ldy	#$14
			jsr	Get1stSek		;Infoblock freigeben.
			beq	:1			; => Keine Daten, weiter...
			jsr	FreeSeqChain
			txa				;Diskettenfehler ?
			bne	DelFileExit1		; => Ja, Abbruch...

::1			ldy	#$02
			jsr	Get1stSek		;Programmdaten freigeben.
			beq	:3			; => Keine Daten, weiter...
			jsr	FreeSeqChain
			txa				;Diskettenfehler ?
			bne	DelFileExit1		; => Ja, Abbruch...

			ldy	#$15
			lda	(r9L),y
			cmp	#$01			;VLIR-Datei freigeben ?
			bne	:3			;Nein, weiter...

			ldy	#$02
			jsr	Get1stSek		;Programmdaten freigeben.
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	DelFileExit1		; => Ja, Abbruch...

			ldy	#$02
::2			tya				;Alle Datensätze gelöscht ?
			beq	:3			;Ja, Ende...
			lda	fileHeader +0,y		;Zeiger VLIR-Eintrag und
			sta	r1L			;Track/Sektor einlesen.
			iny
			lda	fileHeader +0,y
			sta	r1H
			iny
			lda	r1L
			beq	:2
			tya
			pha
			jsr	FreeSeqChain		;Datensatz freigeben.
			pla				;Zeiger auf Datensatz
			tay				;zurücksetzen.
			txa				;Diskettenfehler ?
			beq	:2			;Nein, weiter...
			bne	DelFileExit1

::3			jmp	PutDirHead		;BAM aktualisieren.

;*** Sektorkette freigeben.
;    yReg Offset auf Verzeichnis-Eintrag in ":r9".
:Get1stSek		lda	(r9L),y
			sta	r1H
			dey
			lda	(r9L),y
			sta	r1L
:DelFileExit1		rts

;*** Datei löschen, nur für SEQ-Dateien.
;    ":r3" zeigt auf Tr/Se-Tabelle.
:xFastDelFile		jsr	DelFileEntry		;Datei-Eintrag löschen.
			txa				;Diskettenfehler ?
			bne	DelFileExit2		;Ja, Abbruch...

;*** Sektoren in ":fileTrSeTab" freigeben.
:FreeSekTab		jsr	GetDirHead		;BAM einlesen.

::1			ldy	#$00
			lda	(r3L),y			;Noch ein Sektor ?
			beq	:3			;Nein, weiter...
			sta	r6L
			iny
			lda	(r3L),y
			sta	r6H
			jsr	FreeBlock		;Sektor freigeben.
			txa				;Diskettenfehler ?
			bne	DelFileExit2		;Ja, Abbruch...

;--- Ergänzung: 01.02.21/M.Kanet
;Durch diverse Fehlerbehebungen wurde
;zusätzlicher Speicherplatz benötigt,
;z.B. der ":SetDevice"-Fix.
;Da es bereits eine SetNxByte_r3-
;Routine gibt wurde hier die Addition
;durch zwei Funktionsaufrufe ersetzt.
;Einsparung: 5 Bytes.
			jsr	SetNxByte_r3		;Zeiger auf nächsten Eintrag.
			jsr	SetNxByte_r3

;			clc				;Zeiger auf nächsten Eintrag.
;			lda	#$02
;			adc	r3L
;			sta	r3L
;			bcc	:2
;			inc	r3H
;---

::2			jmp	:1			;Nächsten Sektor freigeben.
::3			jmp	PutDirHead		;BAM zurückschreiben.

;*** Dateieintrag suchen, Aufruf durch ":FastDelFile" und ":DeleteFile".
:DelFileEntry		lda	r0H
			sta	r6H
			lda	r0L
			sta	r6L
			jsr	FindFile		;Datei-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	:1			;Ja, Abbruch...
			tay
			sta	(r5L),y			;Datei-Eintrag löschen.
			jmp	PutBlock_dskBuf		;Sektor zurückschreiben.

;*** SwapFile soll gelöscht werden, SwapRAM wieder freigeben.
::1			ldy	#$00
			lda	(r0L),y
			cmp	#$1b			;SwapFile löschen ?
			bne	DelFileExit2		; => Ja, weiter...

			pla				;Rücksprungadresse aus
			pla				;"DeleteFile" und "FastDelFile"
			lda	Flag_ExtRAMinUse	;löschen und SwapRAM freigeben.
			bpl	DelFileExit2		;=> Bereits freigegeben, dann
							;Fehler "FILE NOT FOUND"!!!
			and	#%01111111
			sta	Flag_ExtRAMinUse
			ldx	#$00			;SwapFile "gelöscht".
:DelFileExit2		rts

;*** VLIR-Datei öffnen.
:xOpenRecordFile	lda	r0H			;Darf nicht geändert werden!
			sta	r6H			;GeoPublish übergeht diese
			lda	r0L			;Befehlsbytes.
			sta	r6L
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Diskettenfehler ?
			bne	NoRecordFlag		;Ja, Abbruch...

;*** Hier Einsprung der von GeoPublish errechnet wird!!!
			ldx	#$0a			;$0a = STRUCT_MISMAT.
			ldy	#$00
			lda	(r5L),y			;Dateityp-Byte einlesen.
			and	#$3f
			cmp	#$03			;"USR"-Datei ?
			bne	NoRecordFlag		;Nein, Fehler...

			ldy	#$15
			lda	(r5L),y			;VLIR-Datei ?
			cmp	#$01			;Nein, Fehler...
			bne	NoRecordFlag

			tay
			lda	(r5L),y			;Track/Sektor des VLIR-Headers
			sta	VLIR_HeaderTr		;in Zwischenspeicher.
			iny
			lda	(r5L),y
			sta	VLIR_HeaderSe
			lda	r1H			;Verzeichniseintrag der VLIR-
			sta	VLIR_HdrDirSek+1	;Datei in Zwischenspeicher.
			lda	r1L
			sta	VLIR_HdrDirSek+0
			lda	r5H
			sta	VLIR_HdrDEntry+1
			lda	r5L
			sta	VLIR_HdrDEntry+0
			lda	dirEntryBuf+29		;Dateigröße zwischenspeichern.
			sta	fileSize+1
			lda	dirEntryBuf+28
			sta	fileSize+0
			jsr	VLIR_GetHeader		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	NoRecordFlag		;Ja, Abbruch...
			sta	usedRecords		;Anzahl Records löschen.

			ldy	#$02			;Anzahl belegter Records
::51			lda	fileHeader +0,y		;in VLIR-Datei zählen.
			ora	fileHeader +1,y
			beq	:52
			inc	usedRecords
			iny
			iny
			bne	:51

::52			ldy	#$00
			lda	usedRecords		;Datei leer ?
			bne	:53			;Nein, weiter...
			dey				;Flag: "Leere VLIR-Datei".
::53			sty	curRecord
			ldx	#$00
			stx	fileWritten
			rts

;*** VLIR-Datei schließen.
:xCloseRecordFile	jsr	xUpdateRecFile
:NoRecordFlag		lda	#$00
			sta	VLIR_HeaderTr
			rts

;*** VLIR-Datei aktualisieren.
:xUpdateRecFile		lda	fileWritten		;Daten geändert ?
			beq	noUpdate		; => Nein, weiter... ACHTUNG!
							;Sprung nach ":51" notwendig,
							;damit AKKU auf $00 gesetzt
							;wird wie im Orginal GEOSV2!

			jsr	VLIR_PutHeader		;VLIR-Header speichern.
			txa				;Diskettenfehler ?
			bne	errVlir			;Ja, Abbruch...

			lda	VLIR_HdrDirSek+1
			sta	r1H
			lda	VLIR_HdrDirSek+0
			sta	r1L
			jsr	GetBlock_dskBuf		;Verzeichnissektor lesen.
			txa				;Diskettenfehler ?
			bne	errVlir			;Ja, Abbruch...

			lda	VLIR_HdrDEntry+1	;Zeiger auf Verzeichniseintrag.
			sta	r5H
			lda	VLIR_HdrDEntry+0
			sta	r5L
			jsr	SetFileDate

			ldy	#$1c
			lda	fileSize+0		;Dateigröße zurückschreiben.
			sta	(r5L),y
			iny
			lda	fileSize+1
			sta	(r5L),y
			jsr	PutBlock_dskBuf
			txa				;Diskettenfehler ?
			bne	errVlir			;Ja, Abbruch...
			sta	fileWritten		;Daten aktualisiert,
			jmp	PutDirHead		;BAM auf Diskette speichern.

;******************************************************************************
;*** Zeiger auf nächsten Datensatz der VLIR-Datei.
;:xNextRecord		lda	curRecord
;			clc
;			adc	#$01
;			jmp	xPointRecord

;*** Zeiger auf vorherigen Datensatz der VLIR-Datei.
;:xPreviousRecord	lda	curRecord
;			sec
;			sbc	#$01
;******************************************************************************

;*** Zeiger auf nächsten Datensatz der VLIR-Datei.
:xNextRecord		lda	#$01
			b $2c

;*** Zeiger auf vorherigen Datensatz der VLIR-Datei.
:xPreviousRecord	lda	#$ff
			clc
			adc	curRecord

;*** Zeiger auf Datensatz der VLIR-Datei positionieren.
:xPointRecord		tax
			bmi	errInvRec
			cmp	usedRecords		;Record verfügbar ?
			bcs	errInvRec		;Nein, Fehler...
			sta	curRecord		;Neuen Record merken.

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.

			ldy	r1L			;Track=$00 = Nicht angelegt.
			lda	curRecord
:noUpdate		ldx	#$00			;$00 = NO_ERROR.
			rts

:errInvRec		ldx	#$08			;$08 = INV_RECORD.
:errVlir		rts

;*** Datensatz in VLIR-Datei einfügen.
:xInsertRecord		lda	curRecord		;Record verfügbar ?
			bmi	errInvRec2		;Nein, Fehler ausgeben...

			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	errVlir2		;Ja, Abbruch...

			lda	curRecord		;Zeiger auf Record in
			sta	r0L 			;VLIR-Header.
			jmp	VLIR_InsRecEntry	;Record-Eintrag einfügen.

;*** Datensatz an VLIR-Datei anhängen.
:xAppendRecord		jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	errVlir2		;Ja, Abbruch...

			ldx	curRecord		;Zeiger hinter aktuellen
			inx				;Record positionieren.
			stx	r0L
			jsr	VLIR_InsRecEntry	;Record-Eintrag einfügen.
			txa				;Diskettenfehler ?
			bne	errVlir2		;Ja, Abbruch...

			lda	r0L			;Zeiger auf aktuellen Record
			sta	curRecord		;korrigieren.
			rts

;*** Datensatz aus VLIR-Datei löschen.
:xDeleteRecord		ldx	#$08			;$08 = INV_RECORD.
			lda	curRecord		;Record verfügbar ?
			bmi	errInvRec2		;Nein, -> Fehler ausgeben...

			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			txa				;Diskettenfehler ?
			bne	errVlir2		;Ja, Abbruch...

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.

			lda	curRecord		;Zeiger auf Record in
			sta	r0L 			;VLIR-Header.
			jsr	VLIR_DelRecEntry	;Record-Eintrag löschen.
			txa				;Diskettenfehler ?
			bne	errVlir2		;Ja, Abbruch...

			lda	curRecord		;Zeiger auf aktuellen Record
			cmp	usedRecords		;korrigieren.
			bcc	:51
			dec	curRecord

::51			ldx	r1L			;War Record angelegt ?
			beq	errVlir2		;Nein, Ende...
			jsr	FreeSeqChain		;Sektorkette freigeben.
			txa				;Diskettenfehler ?
			bne	errVlir2		;Ja, Abbruch...

			jsr	SubFileSize		;Dateigröße korrigieren.
::52			ldx	#$00			;$00 = NO_ERROR.
			rts

:errInvRec2		ldx	#$08			;$08 = INV_RECORD.
:errVlir2		rts

;*** Datensatz einlesen.
:xReadRecord		lda	curRecord		;Record verfügbar ?
			bmi	errInvRec2		;Nein, Abbruch...

			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.
			lda	r1L
			tax				;Record angelegt ?
			beq	errVlir2		;Nein, Ende...

			jsr	ReadFile		;Record in Speicher einlesen.
			lda	#$ff			;$FF = Daten gelesen.
			rts

;*** Datensatz schreiben.
:xWriteRecord		lda	curRecord		;Record verfügbar ?
			bmi	errInvRec2		;Nein, Abbruch...

			lda	r2H			;Anzahl zu schreibender
			pha				;Bytes zwischenspeichern.
			lda	r2L
			pha
			jsr	VLIR_GetCurBAM		;BAM im Speicher aktualisieren.
			pla				;Anzahl zu schreibender
			sta	r2L			;Bytes zurückschreiben.
			pla
			sta	r2H
			txa				;Diskettenfehler ?
			bne	errVlir2		;Ja, Abbruch...
			jsr	VLIR_Get1stSek		;Zeiger auf ersten Sektor.
			lda	r1L			;Sektor bereits angelegt ?
			bne	:51			;Ja, weiter...
			ldx	#$00
			lda	r2L
			ora	r2H			;Sind Daten im Record ?
			beq	errVlir2		;Nein, Ende...
			bne	:53			;Ja, Daten schreiben.

;*** Bestehenden Record löschen.
;    (Record wird später ersetzt)
::51			lda	r2H			;Anzahl zu schreibender
			pha				;Bytes zwischenspeichern.
			lda	r2L
			pha
			lda	r7H			;Startadresse Speicherbereich
			pha				;zwischenspeichern.
			lda	r7L
			pha
			jsr	FreeSeqChain		;Sektorkette freigeben.
			jsr	SubFileSize		;Dateigröße korrigieren.
			pla				;Startadresse Speicherbereich
			sta	r7L			;zurückschreiben.
			pla
			sta	r7H
			pla				;Anzahl zu schreibender
			sta	r2L			;Bytes zurückschreiben.
			pla
			sta	r2H
			txa				;Diskettenfehler ?
			bne	errVlir2		;Ja, Abbruch...

::52			lda	r2L
			ora	r2H			;Sind Daten im Record ?
			beq	VLIR_ClrHdrEntry	;Nein, Record-Eintrag löschen.
::53			jmp	VLIR_SaveRecData	;Speicherbereich schreiben.

;*** Leeren Record-Eintrag in
;    VLIR-Header erzeugen.
:VLIR_ClrHdrEntry	ldy	#$ff
			sty	r1H
			iny
			sty	r1L
			jmp	VLIR_Set1stSek

;*** VLIR-Header einlesen.
:VLIR_GetHeader		jsr	VLIR_SetHdrData		;Zeiger auf VLIR-Header setzen.
			txa				;Fehler ?
			bne	errVlir2		;Ja, Abbruch...
			jmp	GetBlock		;Sektor lesen.

;*** VLIR-Header speichern.
:VLIR_PutHeader		jsr	VLIR_SetHdrData		;Zeiger auf VLIR-Header setzen.
			txa				;Fehler ?
			bne	errVlir2		;Ja, Abbruch...
			jmp	PutBlock		;Sektor schreiben.

;*** Zeiger auf VLIR-Header setzen.
:VLIR_SetHdrData	ldx	#$07			;$07 = UNOPENED_VLIR.
			lda	VLIR_HeaderTr		;VLIR-Datei geöffnet ?
			beq	:51			;Nein, Fehler...
			sta	r1L			;Zeiger auf Sektor VLIR-Header.
			lda	VLIR_HeaderSe
			sta	r1H
			jsr	Vec_fileHeader		;Zeiger auf Header-Speicher.
			ldx	#$00
::51			rts

;*** Record-Eintrag aus VLIR-Header
;    löschen. Anzahl Records -1.
:VLIR_DelRecEntry	ldx	#$08			;$08 = INV_RECORD.
			lda	r0L			;Record verfügbar ?
			bmi	:53			;Nein, Fehler ausgeben.
			asl				;Zeiger auf Record berechnen.
			tay
			lda	#$7e			;Anzahl Records berechnen.
			sec
			sbc	r0L
			asl
			tax
			beq	:52
::51			lda	fileHeader +4,y		;Ersten Record in Tabelle
			sta	fileHeader +2,y		;löschen, folgende Records
			iny				;verschieben.
			dex
			bne	:51
::52			stx	fileHeader+$fe		;Ende VLIR-Datei markieren.
			stx	fileHeader+$ff		;(über Tr/Se = $00/$00!)
			dec	usedRecords		;Anzahl Records -1.
::53			rts

;*** Record-Eintrag in VLIR-Header
;    einfügen. Anzahl Records +1.
:VLIR_InsRecEntry	ldx	#$09			;$09 = OUT_OF_RECORDS.

			lda	usedRecords		;Bereits alle Records
			cmp	#$7f			;in VLIR-Datei belegt ?
			bcs	:53			;Ja, Abbruch...

			ldx	#$08			;$08 = INV_RECORD.
			lda	r0L			;Record verfügbar ?
			bmi	:53			;Nein, Abbruch...

			ldy	#$fe			;Zeiger auf letzten Record.
			lda	#$7e			;Anzahl Records berechnen.
			sec
			sbc	r0L
			asl
			tax
			beq	:52

::51			lda	fileHeader -1,y		;Record-Zeiger ab gewünschtem
			sta	fileHeader +1,y		;Record um 2 Byte verschieben.
			dey
			dex
			bne	:51

::52			txa				;Leeren Record-Eintrag in
			sta	fileHeader +0,y		;VLIR-Header erzeugen.
			lda	#$ff			;(Durch Tr/Se = $00/$FF!)
			sta	fileHeader +1,y
			inc	usedRecords		;Anzahl Records +1.
::53			rts

;*** Tr/Se des aktuellen Record lesen.
:VLIR_Get1stSek		lda	curRecord
			asl
			tay
			lda	fileHeader +2,y
			sta	r1L
			lda	fileHeader +3,y
			sta	r1H
			rts

;*** Tr/Se in VLIR-Header eintragen.
:VLIR_Set1stSek		lda	curRecord
			asl
			tay
			lda	r1L
			sta	fileHeader +2,y
			lda	r1H
			sta	fileHeader +3,y
			rts

;*** Speicherbereich in BAM belegen
;    und auf Disk speichern.
:VLIR_SaveRecData	jsr	Vec_fileTrScTab
			lda	r7H			;Startadresse Speicherbereich
			pha				;zwischenspeichern.
			lda	r7L
			pha
			jsr	BlkAlloc		;Sektoren belegen.
			pla				;Startadresse Speicherbereich
			sta	r7L			;zurückschreiben.
			pla
			sta	r7H
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...
			lda	r2L			;Anzahl Sektoren merken.
			pha
			jsr	Vec_fileTrScTab
			jsr	WriteFile		;Speicher auf Disk schreiben.
			pla				;Anzahl Sektoren wieder
			sta	r2L			;zurückschreiben.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...
			lda	fileTrScTab+1		;Zeiger auf ersten Sektor
			sta	r1H			;in VLIR-Header eintragen.
			lda	fileTrScTab+0
			sta	r1L
			jsr	VLIR_Set1stSek
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...
			lda	r2L			;Dateigröße korrigieren.
			clc
			adc	fileSize+0
			sta	fileSize+0
			bcc	:51
			inc	fileSize+1
::51			rts

;*** BAM im Speicher aktualisieren.
:VLIR_GetCurBAM		ldx	#$00			;$00 = NO_ERROR.
			lda	fileWritten		;Record bereits aktualisiert ?
			bne	:1			;Nein, weiter...
			jsr	GetDirHead		;Disketten-BAM einlesen.
			txa				;Fehler ?
			bne	:1			;Ja, Abbruch...
			lda	#$ff			;Record als "aktualisiert"
			sta	fileWritten		;markieren.
::1			rts

;*** Dateilänge korrigieren.
:SubFileSize		lda	fileSize+0		;Dateigröße korrigieren.
			sec
			sbc	r2L
			sta	fileSize+0
			bcs	:51
			dec	fileSize+1
::51			rts

;*** GEOS-Verzeichniseintrag erzeugen.
:xBldGDirEntry		ldx	#30 -1
			lda	#$00			;Verzeichnis-Eintrag löschen.
::1			sta	dirEntryBuf,x
			dex
			bpl	:1

			tay
			lda	(r9L),y
			sta	r3L
			iny
			lda	(r9L),y
			sta	r3H
			sty	r1H
			dey
			sty	fileHeader +0		;Sektorverkettung im
			stx	fileHeader +1		;Infoblock löschen.

			ldx	#$03			;Dateiname kopieren.
::2			lda	(r3L),y
			bne	:4
			sta	r1H
::3			lda	#$a0
::4			sta	dirEntryBuf,x
			inx
			iny
			cpy	#$10
			beq	:5
			lda	r1H
			bne	:2
			beq	:3

::5			ldy	#$44
			lda	(r9L),y			;CBM -Dateityp.
			sta	dirEntryBuf + 0
			iny
			lda	(r9L),y			;GEOS-Dateityp.
			sta	dirEntryBuf +22
			iny
			lda	(r9L),y			;Datei-Struktur.
			sta	dirEntryBuf +21

;--- Ergänzung: 30.12.22/M.Kanet
;":BldGDirEntry" greift direkt auf
;":fileTrScTab" zu, anstatt den
;Speicherbereich in r6 zu verwenden.
;			ldy	fileTrScTab + 2		;Ersten Sektor merken.
;			sty	dirEntryBuf + 1
;			ldy	fileTrScTab + 3
;			sty	dirEntryBuf + 2
;
;			ldy	fileTrScTab + 0		;Zeiger auf Infoblock.
;			sty	dirEntryBuf +19
;			ldy	fileTrScTab + 1
;			sty	dirEntryBuf +20
;---
			pha				;Datei-Struktur speichern.

			ldy	#0
			lda	(r6L),y			;Zeiger auf Infoblock.
			sta	dirEntryBuf +19
			iny
			lda	(r6L),y
			sta	dirEntryBuf +20
			iny
			lda	(r6L),y			;Ersten Sektor merken.
			sta	dirEntryBuf + 1
			iny
			lda	(r6L),y
			sta	dirEntryBuf + 2

			ldy	r2L			;Dateigröße übernehmen.
			sty	dirEntryBuf +28
			ldy	r2H
			sty	dirEntryBuf +29

			pla				;Datei-Struktur einlesen.
;---
;			tay				;VLIR-Datei ?
			beq	:6			; => Nein, weiter...

;--- VLIR-Header reservieren.
			jsr	SetVecToSek		;Zeiger auf nächsten Sektor
							;in Sektortabelle setzen.

;--- Infoblock reservieren.
::6			jmp	SetVecToSek		;Zeiger auf nächsten Sektor
							;in Sektortabelle setzen.

;*** GEOS-Verzeichniseintrag speichern.
:xSetGDirEntry		jsr	BldGDirEntry		;Verzeichnis-Eintrag erzeugen.
			jsr	GetFreeDirBlk		;Freien Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	SetDirExit		;Ja, Abbruch...

			tya				;Zeiger auf Verzeichnis-Eintrag
			clc				;in ":diskBlkBuf" berechnen.
			adc	#< diskBlkBuf
			sta	r5L
			lda	#$00
			adc	#> diskBlkBuf
			sta	r5H

			ldy	#30 -1
::1			lda	dirEntryBuf,y		;Verzeichnis-Eintrag kopieren.
			sta	(r5L)      ,y
			dey
			bpl	:1

			jsr	SetFileDate
			jmp	PutBlock_dskBuf

;*** Aktuelles Datum in Verzeichnis-
;    eintrag schreiben.
:SetFileDate		ldy	#$17
::1			lda	year -$17,y
			sta	(r5L)    ,y
			iny
			cpy	#$1c
			bne	:1
:SetDirExit		rts

;*** Dateitypen suchen.
;    Neuer Dateityp #255 zeigt alle Dateien an!
:xFindFTypes		php
			sei

			lda	r6H			;Zeiger auf Tabelle für
			sta	r1H			;Dateinamen.
			lda	r6L
			sta	r1L

			lda	#$00			;Größe der Tabelle für
			sta	r0H			;Dateinamen berechnen.

			lda	r7H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			asl
			rol	r0H
			adc	r7H
			sta	r0L
			bcc	:1
			inc	r0H
::1			jsr	ClearRam		;Dateinamen-Tabelle löschen.
			jsr	Sub3_r6

			jsr	Get1stDirEntry		;Ersten DIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch...

::2			ldy	#$00
			lda	(r5L),y			;Datei-Eintrag vorhanden ?
			beq	:7			;Nein, weiter...

			ldy	#$16
			lda	r7L			;Dateityp einlesen.
			cmp	#255			;Alle Dateien einlesen ?
			beq	:3			;Ja, weiter...
			cmp	(r5L),y			;Gesuchter Dateityp ?
			bne	:7			;Nein, übergehen.

			jsr	CheckFileClass		;GEOS-Klasse vergleichen.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch...

			tya				;GEOS-Klasse OK ?
			bne	:7			;Nein, weiter...

::3			ldy	#$03
::4			lda	(r5L),y			;Dateinamen in Tabelle
			cmp	#$a0			;kopieren.
			beq	:5
			sta	(r6L),y
			iny
			cpy	#$13
			bne	:4

::5			clc				;Zeiger auf Position für
			lda	#$11			;Dateinamen in Tabelle
			adc	r6L			;korrigieren.
			sta	r6L
			bcc	:6
			inc	r6H

::6			dec	r7H			;Dateizähler -1.
			beq	:8			;Speicher voll ? Ja, Ende...

::7			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch...
			tya				;Ende erreicht ?
			beq	:2			;Nein, weiter...
::8			plp
			rts

;*** Zeiger auf Ablagebereich korrigieren.
;FindFTypes und FindFile arbeiten mit einem Index der um
;3 Byte versetzt ist, deshalb muß die Zieladresse angepaßt werden.
:Sub3_r6		sec
			lda	r6L
			sbc	#$03
			sta	r6L
			bcs	:1
			dec	r6H
::1			rts

;*** GEOS-Klasse vergleichen.
:CheckFileClass		lda	r10L
			ora	r10H
			tax				;xReg=$00, Kein Fehler...
			beq	:2			; => Kein Klasse, Ende...

			ldy	#$13
			lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			jsr	Vec_fileHeader
			jsr	GetBlock
			txa
			bne	:4

			tay
::1			lda	(r10L),y
			beq	:2
			cmp	fileHeader+$4d,y
			bne	:3
			iny
			bne	:1

::2			ldy	#$00
			rts

::3			ldy	#$ff
::4			rts

;*** Datei suchen.
;    Wenn der aktive Druckertreiber kopiert werden soll, zeigt ":r6" nicht
;    auf ":PrntFileName" und FindFile sucht die datei auf Diskette.
;    Zeigt ":r6" jedoch auf ":PrntFileName", dann soll der aktive Drucker-
;    treiber gesucht werden (z.B. beim Start von GeoWrite um die Seitenlänge
;    festzulegen...). In diesem Fall mit xReg = $00 beenden.
:xFindFile		php
			sei

			lda	r6H			;Suche nach aktuellem Drucker-
			cmp	#> PrntFileName		;treiber in ":PrntFileName" ?
			bne	:0			;Nein, Treiber auf Disk suchen.
			lda	r6L
			cmp	#< PrntFileName
			bne	:0

			jsr	TestPrntFile		;Druckertreiber suchen ?
			beq	:7			;Ja, weiter...

::0			jsr	Sub3_r6
			jsr	Get1stDirEntry		;Erster DIR-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch.

::1			tay				;yReg=$00.
			lda	(r5L),y			;Gelöschter Eintrag ?
			beq	:4			;Ja, weiter...

			ldy	#$03
::2			lda	(r6L),y			;Dateinamen vergleichen.
			beq	:3
			cmp	(r5L),y
			bne	:4			; -> Falsche Datei,...
			iny
			bne	:2
::3			cpy	#$13
			beq	:5			; -> Richtige Datei...
			lda	(r5L),y
			iny
			cmp	#$a0
			beq	:3

::4			jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Diskettenfehler ?
			bne	:8			;Ja, Abbruch...
			tya				;Verzeichnis-Ende erreicht ?
			beq	:1			;Nein, weiter...
			ldx	#$05			;Fehler: "File not found"
			bne	:8

::5			ldy	#30 -1
::6			lda	(r5L)      ,y		;Datei-Eintrag kopieren.
			sta	dirEntryBuf,y
			dey
			bpl	:6

::7			ldx	#$00			;Kein Fehler...
::8			plp
			rts

;*** Beliebige Datei laden.
:xGetFile		jsr	TestPrntFile		;Druckertreiber laden ?
			beq	loadPrnDrvRAM		;Ja, weiter...

			jsr	SaveFileData		;Datei-Informationen sichern.

			jsr	FindFile		;Datei-Eintrag suchen.
			txa				;Diskettenfehler ?
			bne	RTS_01			;Ja, Abbruch...

			jsr	LoadFileData		;Datei-Informationen einlesen.

			lda	#> dirEntryBuf		;Zeiger auf Datei-Eintrag.
			sta	r9H
			lda	#< dirEntryBuf
			sta	r9L

			lda	dirEntryBuf+22		;Dateityp einlesen.
			cmp	#$05			;Hilfsmittel starten ?
			beq	:4			;Ja, weiter...
::1			cmp	#$06			;Applikation starten ?
			beq	:2			;Ja, weiter...
			cmp	#$09			;Druckertreiber ?
			beq	loadPrnDrvDisk		;Ja, weiter...
			cmp	#$0e			;AutoExec-Datei starten ?
			bne	:3			;Nein, weiter...
::2			jmp	LdApplic		;Applikation/AutoExec starten.
::3			jmp	LdFile
::4			jmp	LdDeskAcc

;*** Druckertreiber laden ?
;    Z-Flag gesetzt, dann Druckertreiber aus RAM laden.
:TestPrntFile		ldy	Flag_LoadPrnt		;Druckertreiber aus RAM laden ?
			bne	RTS_01			;Nein, Ende...

;			ldy	#$00			;Name des neuen Druckertreibers
::1			lda	(r6L)           ,y	;im Kernal vergleichen.
			cmp	PrntFileNameRAM ,y
			bne	RTS_01			; => Z=0, Falscher Name.
			tax
			beq	RTS_01			; => Z=1, Name identisch.
			iny
			cpy	#$10
			bne	:1			; => Z=1, Name identisch.
:RTS_01			rts

;*** Druckertreiber in RAM laden.
:loadPrnDrvDisk		ldy	#$03			;Name des neuen Druckertreibers
::1			lda	(r6L)             ,y	;im Kernal speichern.
			sta	PrntFileNameRAM -3,y
			beq	:2
			iny
			cpy	#$13
			bne	:1

::2			jsr	LdFile			;Druckertreiber von Disk laden.

;--- Ergänzung: 30.12.18/M.Kanet
;Größe des Spoolers und Druckertreiber im RAM um 1Byte reduziert.
;geoCalc64 nutzt beim Drucken ab $$5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert. Wird der gesamte Speicher
;getauscht führt das zum Absturz in geoCalc.
;SetADDR_Printer und SetADDR_PrnSpool dürfen max. bis $7F3E reichen.
;Siehe auch Datei "-G3_SetVecRAM".
			jsr	SetADDR_Printer		;Druckertreiber und fileHeader
			jsr	StashRAM		;in REU speichern.
			jsr	SetADDR_PrntHdr
			jsr	StashRAM

;******************************************************************************
;  ACHTUNG!!! MP3 muß hier fortfahren, auch wenn der aktive Treiber zu diesem
;  Zeitpunkt bereits geladen wurde! Ist der Spooler aktiv, so muß dieser hier
;  an Stelle des Original-Druckertreibers geladen werden!!!
;******************************************************************************

;*** Druckertreiber aus RAM laden.
:loadPrnDrvRAM		lda	#< SetADDR_Printer
			ldx	#> SetADDR_Printer

			bit	Flag_Spooler		;Spooler aktiv?
			bpl	:1			; => Nein, weiter...

			lda	#< SetADDR_PrnSpool
			ldx	#> SetADDR_PrnSpool

::1			jsr	CallRoutine		;Zeiger auf Drucker oder Spooler.
			jsr	FetchRAM		;Treiber aus REU einlesen.
			jsr	SetADDR_PrntHdr		;Zeiger auf Infoblock Drucker.
			jmp	FetchRAM		;Infoblock einlesen.
							;xReg = $00, Kein Fehler,
							;wird bei FetchRAM gesetzt.

;*** Datei laden.
:xLdFile		jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	LdFileExit		;Ja, Abbruch.

			ldy	fileHeader+$46		;Dateistruktur einlesen.
			dey				;VLIR-Datei ?
			bne	:1			;Nein, weiter...

			ldy	#$01 +1			;VLIR-Header einlesen.
			jsr	Get1stSek
			jsr	GetBlock_dskBuf		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	LdFileExit		;Ja, Abbruch...

			ldx	#$08			;Zeiger auf ersten Datensatz.
			lda	diskBlkBuf +2
			sta	r1L
			beq	LdFileExit		;Fehler, RECORD NOT THERE.

			lda	diskBlkBuf +3
			sta	r1H

::1			lda	LoadFileMode
			lsr				;Programm starten ?
			bcc	:2			;Ja, weiter...

			lda	LoadBufAdr+1		;Ladeadresse setzen.
			sta	r7H
			lda	LoadBufAdr+0
			sta	r7L

::2			lda	#$ff
			sta	r2L
			sta	r2H
			jmp	ReadFile		;Datei laden.
:LdFileExit		rts

;*** Anwendung starten.
:xLdApplic		jsr	SaveFileData		;Programmdaten speichern.
			jsr	LdFile			;Datei laden.
			txa				;Diskettenfehler ?
			bne	LdFileExit		;Ja, Abbruch...

			lda	LoadFileMode
			lsr				;Programm starten ?
			bcs	LdFileExit		;Nein, weiter...

			jsr	LoadFileData		;Variablen wieder einlesen.

			lda	fileHeader+$4b
			sta	r7L
			lda	fileHeader+$4c
			sta	r7H
			jmp	StartAppl		;Applikation starten.

;*** Hilfsmittel einlesen.
:xLdDeskAcc		lda	r10L			;Bildschirm-Flag speichern.
			sta	DA_ResetScrn

			jsr	GetFHdrInfo		;Datei-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch.

			lda	r1H			;Zeiger auf ersten Sektor
			pha				;zwischenspeichern.
			lda	r1L
			pha

			lda	fileHeader      +$47
			sta	SetSwapFileData +  1
			lda	fileHeader      +$48
			sta	SetSwapFileData +  3

			lda	fileHeader      +$49
			sec
			sbc	fileHeader      +$47
			sta	SetSwapFileData + 13
			lda	fileHeader      +$4a
			sbc	fileHeader      +$48
			sta	SetSwapFileData + 15

			lda	Flag_ExtRAMinUse	;Zwischenspeicher für
			ora	#%10000000		;SwapFile sperren.
			sta	Flag_ExtRAMinUse

			jsr	SetSwapFileData		;Zeiger auf SwapFile-Bereich.
			bcs	:3
			jsr	StashRAM		;Speicher-Inhalt retten.

			pla
			sta	r1L
			pla
			sta	r1H

			jsr	GetLoadAdr		;Ladeadresse setzen.
			jsr	ReadFile		;DA einlesen.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch...

			jsr	SaveGEOS_Data		;GEOS-Variablen speichern.
			jsr	UseSystemFont		;GEOS initialisieren.

			jsr	GEOS_InitVar		;Kernel-Variablen initialisier.

			lda	DA_ResetScrn		;Bildschirm-Flag zurücksetzen.
			sta	r10L
			pla
			sta	DA_ReturnAdr+0		;LOW  -Byte Rücksprungadresse.
			pla
			sta	DA_ReturnAdr+1		;High -Byte Rücksprungadresse.
			tsx
			stx	DA_RetStackP		;Stackzeiger merken.

			ldx	fileHeader  +$4c
			lda	fileHeader  +$4b
			jmp	InitMLoop1		;Programm starten.
::1			ldx	#$0b
::2			rts
::3			pla
			pla
			rts

;*** DA beenden, zurück zur Applikation.
:xRstrAppl		jsr	SetSwapFileData		;Zeiger auf SwapFile-Bereich.
			jsr	FetchRAM		;Speicher-Inhalt zurücksetzen.

			lda	Flag_ExtRAMinUse	;Zwischenspeicher für
			and	#%01111111		;SwapFile wieder freigeben.
			sta	Flag_ExtRAMinUse

			jsr	LoadGEOS_Data		;GEOS-Variablen zurücksetzen.
			ldx	DA_RetStackP		;Rücksprungadresse wieder auf
			txs				;Stapel zurückschreiben.
			lda	DA_ReturnAdr +1
			pha
			lda	DA_ReturnAdr +0
			pha
			ldx	#$00			;Flag für "Kein Diskfehler!"
			rts

;*** Daten für SWAP-File definieren.
:SetSwapFileData	lda	#$ff			;Startadresse SwapFile für
			ldx	#$ff			;StashRAM/FetchRAM festlegen.
			sta	r0L			;(Wird berechnet!)
			stx	r0H
			sta	r1L
			stx	r1H

			lda	#$ff			;Anzahl Bytes festlegen.
			ldx	#$ff			;(Wird berechnet!)
			sta	r2L
			stx	r2H
			ldy	MP3_64K_DATA
			sty	r3L
			cpx	#> $7c00		;Größe für SwapFile testen.
							;Speicher von $0400 - $8000,
							;Mehr ist nicht möglich!!!
			rts

;*** Variablen zurückschreiben.
;    Aufruf durch ":StartAppl",
;    ":GetFile" und ":LdApplic".
:LoadFileData		lda	DA_ResetScrn		;SCREEN-Flag zurücksetzen.
			sta	r10L

			lda	LoadFileMode		;Modus für GetFile setzen.
			sta	r0L
			lsr				;Ladeadresse angegeben ?
			bcc	:1			;Nein, weiter...

			lda	LoadBufAdr +0		;Ladeadresse zurücksetzen.
			sta	r7L
			lda	LoadBufAdr +1
			sta	r7H

::1			lda	#< dataDiskName		;Zeiger auf Diskettenname.
			sta	r2L
			lda	#> dataDiskName
			sta	r2H
			lda	#< dataFileName		;Zeiger auf Dateiname.
			sta	r3L
			lda	#> dataFileName
			sta	r3H
:ExitFileData		rts

;*** Variablen zwischenspeichern.
;    Aufruf durch ":StartAppl",
;    ":GetFile" und ":LdApplic".
:SaveFileData		lda	r7L
			sta	LoadBufAdr +0
			lda	r7H
			sta	LoadBufAdr +1

			lda	r10L
			sta	DA_ResetScrn

			lda	r0L
			sta	LoadFileMode
			and	#%11000000		;Datenfile nachladen bzw.
			beq	ExitFileData		;ausdrucken ? Nein, weiter...

			ldy	#> dataDiskName		;Diskettenname retten.
			lda	#< dataDiskName
			ldx	#r2L
			sty	r4H			;Datei-/Diskname retten.
			sta	r4L
			ldy	#r4L
			lda	#18
			jsr	CopyFString		;String kopieren.

			ldy	#> dataFileName		;Dateiname retten.
			lda	#< dataFileName
			ldx	#r3L
			sty	r4H			;Datei-/Diskname retten.
			sta	r4L
			ldy	#r4L
			lda	#17
			jmp	CopyFString		;String kopieren.

;*** Datei speichern.
:xSaveFile		ldy	#$00
::1			lda	(r9L)      ,y		;Infoblock zwischenspeichern.
			sta	fileHeader ,y
			iny
			bne	:1

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	GetFileSize		;Dateigröße berechnen.
			jsr	Vec_fileTrScTab

			jsr	BlkAlloc		;Sektor belegen.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	Vec_fileTrScTab

			jsr	SetGDirEntry		;Verzeichnis-Eintrag erzeugen.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	PutDirHead		;BAM aktualisieren.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			sta	fileHeader+$a0
			lda	dirEntryBuf+20
			sta	r1H
			lda	dirEntryBuf+19
			sta	r1L
			jsr	Vec_fileHeader

			jsr	PutBlock		;Sektor schreiben.
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	SaveVLIR
			txa				;Diskettenfehler ?
			bne	SaveExit		;Ja, Abbruch...

			jsr	GetLoadAdr		;Ladeadresse ermitteln.
			jmp	WriteFile		;Speicher auf Disk schreiben.
:SaveExit		rts

;*** VLIR-Header speichern.
:SaveVLIR		ldx	#$00
			ldy	dirEntryBuf+21
			dey				;VLIR-Datei ?
			bne	SaveExit		;Nein, weiter...

			lda	dirEntryBuf+2
			sta	r1H
			lda	dirEntryBuf+1
			sta	r1L

			tya
::1			sta	diskBlkBuf +0,y
			iny
			bne	:1
			dey
			sty	diskBlkBuf +1
			jmp	PutBlock_dskBuf		;Sektor auf Diskette schreiben.

;*** Dateigröße berechnen.
:GetFileSize		lda	fileHeader+$49		;Programmgröße berechnen.
			sec
			sbc	fileHeader+$47
			sta	r2L
			lda	fileHeader+$4a
			sbc	fileHeader+$48
			sta	r2H

			jsr	:1			;254 Bytes für Infoblock.

			ldx	fileHeader+$46
			dex				;VLIR-Datei ?
			bne	:2			;Nein, weiter...

::1			clc				;254 Bytes für VLIR-Header.
			lda	#$fe
			adc	r2L
			sta	r2L
			bcc	:2
			inc	r2H
::2			rts

;*** Sektorkette auf Disk freigeben.
:FreeSeqChain		lda	r1H
			ldx	r1L
			beq	:3

			ldy	#$00
			sty	r2L			;Blocks löschen.
			sty	r2H

::1			sta	r1H
			stx	r1L

			sta	r6H
			stx	r6L
			jsr	FreeBlock		;Sektor freigeben.
			txa				;Diskettenfehler ?
			bne	:3			;Ja, Abbruch...

			inc	r2L			;Anzahl gelöschte Blocks
			bne	:2			;um 1 erhöhen.
			inc	r2H

::2			jsr	GetBlock_dskBuf		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:3			;Ja, Abbruch...

			lda	diskBlkBuf +1		;Noch ein Sektor ?
			ldx	diskBlkBuf +0
			bne	:1			;Nächsten Sektor freigeben.

::3			rts

;--- Ergänzung: 01.07.18/M.Kanet
;Neue FollowChain-Routine.
;Bei der Original-Version wurde in :r3 keine gültige Sektortabelle
;erzeugt wenn der erste Sektor in :r1L/:r1H=$0/Bytes (letzter Sektor) ist.
;Ausserdem wird bei erfolgreichem anlegen der Tabelle in :r1L/:r1H
;nicht das letzte Spur/Sektor-Paar übergeben (:r1L=$0/Ende, :r1H=Bytes)
;
;Benötigter Speicher: 51Bytes
;
;*** Sektorkette verfolgen und
;    Track/Sektor-Tabelle anlegen.
;    Übergabe: r1L/r1H Spur/Sektor
;              r3      Zeiger auf Tabellenspeicher
:xFollowChain		lda	r3H
			pha

			ldy	#$00
			lda	r1H			;Erste Spur/Sektor-Adresse in
			ldx	r1L			;Sektortabelle kopieren.
::1			iny
			sta	(r3L),y			;Sektor-Adresse eintragen.
			dey
			txa
			sta	(r3L),y			;Spur-Adresse eintragen.
							;Spur = $00 ?
			beq	:4			;Ja, Ende...
			iny
			iny
			bne	:2			;Block-Ende erreicht?
			inc	r3H			;Zeiger auf nächsten Block.
::2			tya
			pha
			jsr	GetBlock_dskBuf		;Sektor einlesen.
			pla
			tay
			txa				;Diskettenfehler ?
			bne	:4			;Ja, Abbruch...

			lda	diskBlkBuf +1		;Zeiger auf nächsten Sektor.
			sta	r1H
			ldx	diskBlkBuf +0
			stx	r1L
			jmp	:1

::4			pla
			sta	r3H
			rts

;--- Ergänzung: 01.07.18/M.Kanet
;Alte FollowChain-Routine.
;
;Benötigter Speicher: 50Bytes
;
;*** Sektorkette verfolgen und
;    Track/Sektor-Tabelle anlegen.
;:xFollowChain		lda	r3H
;			pha
;
;			lda	r1H
;			ldx	r1L
;			beq	:4
;
;			ldy	#$00
;::1			iny
;			sta	(r3L),y			;eintragen.
;			dey
;			txa
;			sta	(r3L),y
;			iny
;			iny
;			bne	:2
;			inc	r3H
;
;::2			txa				;Sektor verfügbar ?
;			beq	:4			;Nein, Ende...
;			tya
;			pha
;
;			jsr	GetBlock_dskBuf		;Sektor einlesen.
;			pla
;			tay
;			txa				;Diskettenfehler ?
;			bne	:4			;Ja, Abbruch...
;
;			lda	diskBlkBuf +1		;Zeiger auf nächsten Sektor.
;			ldx	diskBlkBuf +0
;			jmp	:1
;
;::4			pla
;			sta	r3H
;			rts

;*** Ladeadresse einer Datei einlesen.
:GetLoadAdr		lda	fileHeader+$48
			sta	r7H
			lda	fileHeader+$47
			sta	r7L
			rts

;*** Zeiger auf ":fileHeader" = $8100.
:Vec_fileHeader		lda	#> fileHeader
			sta	r4H
			lda	#< fileHeader
			sta	r4L
:NoCallRout		rts

;*** Zeiger auf ":fileTrScTab" = $8300.
:Vec_fileTrScTab	lda	#> fileTrScTab
			sta	r6H
			lda	#< fileTrScTab
			sta	r6L
			rts

;*** Mausabfrage starten.
:xStartMouseMode	bcc	:1			;Mauszeiger positionieren ?
							; -> Nein, weiter...
			lda	r11L
			ora	r11H			;X-Koordinate gesetzt ?
			beq	:1			; -> Nein, weiter...

			lda	r11H			;Neue Mausposition setzen.
			sta	mouseXPos+1
			lda	r11L
			sta	mouseXPos+0
			sty	mouseYPos
			jsr	xSlowMouse

::1			lda	#> ChkMseButton		;Zeiger auf Mausabfrage
			sta	mouseVector+1		;installieren.
			lda	#< ChkMseButton
			sta	mouseVector+0
			lda	#> IsMseOnMenu
			sta	mouseFaultVec+1		;Zeiger auf Fehlerroutine bei
			lda	#< IsMseOnMenu		;verlassen des Mausbereichs.
			sta	mouseFaultVec+0
			lda	#$00			;Flag: "Mauszeiger im Bereich".
			sta	faultData
;			jmp	MouseUp			;Mauszeiger darstellen.

;*** Mauzeiger einschalten.
:xMouseUp		lda	#%10000000
			ora	mouseOn
			sta	mouseOn
			rts

;*** Mauszeiger abschalten.
:xMouseOff		lda	#%01111111
			and	mouseOn
;			sta	mouseOn			;Befehle können entfallen!
;			jmp	MouseSpriteOff		;Beide Befehle werden durch
			b $2c				;den $2C-BIT-Befehl ersetzt.

;*** Maus abschalten.
:xClearMouseMode	lda	#$00			;Mausabfrage unterbinden.
			sta	mouseOn
:MouseSpriteOff		lda	#$00			;Sprite #0 = Mauszeiger
			sta	r3L			;abschalten.
			jmp	xDisablSprite

;*** Ist Maus in Bildschirmbereich ?
:xIsMseInRegion		lda	mouseYPos
			cmp	r2L
			bcc	:5
			cmp	r2H
			beq	:1
			bcs	:5

::1			lda	mouseXPos+1
			cmp	r3H
			bne	:2
			lda	mouseXPos+0
			cmp	r3L
::2			bcc	:5

			lda	mouseXPos+1
			cmp	r4H
			bne	:3
			lda	mouseXPos+0
			cmp	r4L
::3			beq	:4
			bcs	:5
::4			lda	#$ff
			rts
::5			lda	#$00
			rts

;*** Mauszeiger in Bereich festsetzen.
:SetMseToArea		ldy	mouseLeft  +0
			ldx	mouseLeft  +1
			lda	mouseXPos  +1		;Mauszeiger über linken Rand ?
			bmi	:2			;Ja, Fehler anzeigen.
			cpx	mouseXPos  +1		;Mauszeiger links von
			bne	:1			;aktueller Bereichsgrenze ?
			cpy	mouseXPos  +0
::1			bcc	:3			;Nein, weiter...
			beq	:3			;Nein, weiter...

::2			jsr	:setFaultLeft
;			lda	#%00100000		;Mauszeiger hat linke Grenze
;			ora	faultData		;überschritten. Mauszeiger auf
;			sta	faultData		;linke Grenze setzen.
			sty	mouseXPos  +0
			stx	mouseXPos  +1

::3			ldy	mouseRight +0
			ldx	mouseRight +1
			cpx	mouseXPos  +1		;Mauszeiger über rechten Rand ?
			bne	:4
			cpy	mouseXPos  +0
::4			bcs	:5			;Nein, weiter...

			jsr	:setFaultRight
;			lda	#%00010000		;Mauszeiger hat rechte Grenze
;			ora	faultData		;überschritten. Mauszeiger auf
;			sta	faultData		;rechte Grenze setzen.
			sty	mouseXPos  +0
			stx	mouseXPos  +1

::5			ldy	mouseTop
			lda	mouseYPos		;Hat Mauszeiger die untere
			cmp	#$e4			;Bildgrenze überschritten ?
			bcs	:6			;Ja, Fehler anzeigen.
			cpy	mouseYPos		;Mauszeiger über obere Grenze ?
			bcc	:7			;Nein, weiter...
			beq	:7			;Nein, weiter...

::6			jsr	:setFaultTop
;			lda	#%10000000		;Mauszeiger hat obere Grenze
;			ora	faultData		;überschritten. Mauszeiger auf
;			sta	faultData		;obere Grenze setzen.
			sty	mouseYPos

::7			ldy	mouseBottom
			cpy	mouseYPos		;Mauszeiger über untere Grenze?
			bcs	:8			;Nein, weiter...

			jsr	:setFaultBottom
;			lda	#%01000000		;Mauszeiger hat untere Grenze
;			ora	faultData		;überschritten. Mauszeiger auf
;			sta	faultData		;untere Grenze setzen.
			sty	mouseYPos

;--- PullDown-Menüs testen.
::8			bit	mouseOn			;PullDown-Menü aktiv ?
			bvc	:exit			; => Nein, Ende...

			lda	mouseYPos		;Ist Mauszeiger zwischen oberer
			cmp	DM_MenuRange+0		;und untere Grenze des Menü-
			bcc	:setFaultMenu		;fensters ?
			cmp	DM_MenuRange+1
			beq	:9
			bcc	:9

			lda	menuNumber		;Hauptmenü ?
			beq	:setFaultMenu		; => Ja, Menü beenden.
			bit	Flag_MenuStatus		;Menüs nach unten verlassen ?
			bvc	:setFaultMenu		; => Ja, Menü beenden.

			lda	DM_MenuRange+1
			sta	mouseYPos		;Mauszeiger festsetzen.

::9			lda	mouseXPos+1		;Ist Mauszeiger zwischen linker
			cmp	DM_MenuRange+3		;und rechter Grenze des Menü-
			bne	:10			;fensters ?
			lda	mouseXPos+0
			cmp	DM_MenuRange+2
::10			bcc	:setFaultMenu		; => Nein, Menü beenden.
			lda	mouseXPos+1
			cmp	DM_MenuRange+5
			bne	:11
			lda	mouseXPos+0
			cmp	DM_MenuRange+4
::11			bcc	:exit			; => Ja, Ende...
			beq	:exit			; => Ja, Ende...

;*** Bereichsgrenzen erreicht.
::setFaultMenu		lda	#%00001000		;Aktuelles Menü verlassen.
			b $2c
::setFaultLeft		lda	#%00100000		;Grenze erreicht: Links.
			b $2c
::setFaultRight		lda	#%00010000		;Grenze erreicht: Rechts.
			b $2c
::setFaultTop		lda	#%10000000		;Grenze erreicht: Oben.
			b $2c
::setFaultBottom	lda	#%01000000		;Grenze erreicht: Unten.
			ora	faultData		;":faultData" aktualisieren.
			sta	faultData
::exit			rts

;*** Maustaste auswerten.
:ChkMseButton		lda	mouseData		;Maustaste gedrückt ?
			bmi	:2			;Nein, Ende...

			bit	mouseOn			;Mauszeiger/Menüs aktiv ?
			bpl	:2			;Kein Mauszeiger, Ende.
			bvc	:1			;Keine Menüs, weiter...

			jsr	DM_TestMenuPos
			bcs	:1
			jmp	DM_ExecMenuJob		;Menüeintrag ausgewählt.

::1			lda	mouseOn
			and	#%00100000		;Icons aktiv ?
			beq	:2			;Nein, weiter...
			jmp	DI_ChkMseClk		;Iconeintrag auswerten.

::2			lda	otherPressVec+0
			ldx	otherPressVec+1
			jmp	CallRoutine

;*** Mauszeiger hat Bereich verlassen.
:IsMseOnMenu		lda	#%11000000
			bit	mouseOn			;Mauszeiger und Menüs aktiv ?
			bpl	:3			;Nein, Ende...
			bvc	:3			;Nein, Ende...
			lda	menuNumber		;Hauptmenü aktiv ?
			beq	:3			;Ja, übergehen.

			lda	faultData		;Hat Mauszeiger aktuelles Menü
			and	#%00001000		;verlassen ?
			bne	:2			;Ja, ein Menü zurück.
			ldx	#%10000000
			lda	#%11000000
			tay
			bit	DM_MenuType
			bmi	:1
			ldx	#%00100000
::1			txa				;Hat Mauszeiger obere/linke
			and	faultData		;Grenze verlassen ?
			bne	:2			;Ja, ein Menü zurück.
			tya
			bit	DM_MenuType		;Mauszeiger einschränken ?
			bvs	:3			;Nein, weiter...
::2			jmp	xDoPreviousMenu		;Ein Menü zurück.
::3			rts

;*** Bildschirmschoner aktivieren ?
:IntScrnSave		bit	Flag_ScrSaver		;ScreenSaver-Modus testen.
			bmi	:5			; => Nicht aktiv.
			bvs	:6			; => Neu initialisieren.
			beq	:6			; => ScreenSaver aufrufen.

			lda	inputData
			eor	#%11111111		;Mausbewegung ?
			bne	:6			;Ja, Zähler neu setzen.

			lda	pressFlag		;Taste gedrückt ?
			and	#%11100000		;Nein, Zähler korrigieren.
			beq	:1

;--- Zähler korrigieren.
;Original-Routine aus MP3/GeoDOS V3.
if FALSE		;36 Bytes
::6			ldx	Flag_ScrSvCnt		;Zähler neu initialisieren.
			stx	:1 +1
			stx	:3 +1
			ldx	#%00100000		;Flag für "Zähler läuft".
			bne	:4

::1			ldx	#$06
			beq	:2
			dec	:1 +1
			rts

::2			dec	:1 +1
::3			ldx	#$06
			beq	:4
			dec	:3 +1
			rts

::4			stx	Flag_ScrSaver		;$00 = ScreenSaver starten.
::5			rts
endif

;--- Zähler korrigieren.
;Geänderte Routine füpr GDOS64:
;Abfrage ob Startwert für ScreenSaver
; = 255 -> Kein automatischer Start.
if TRUE			;36 Bytes
::6			ldx	Flag_ScrSvCnt		;Zähler neu initialisieren.
			stx	:scount +0
			stx	:scount +1
			ldx	#%00100000		;Flag für "Zähler läuft".
			bne	:4

::1			bit	Flag_ScrSvCnt
			bmi	:5
			dec	:scount +0
			bne	:5
::3			dec	:scount +1
			bne	:5

			ldx	#%00000000
::4			stx	Flag_ScrSaver		;$00 = ScreenSaver starten.
::5			rts

::scount		w $0000				;Counter für ScreenSaver.
endif

;*** Druckerspooler aktivieren ?
:IntPrnSpool		bit	Flag_Spooler		;DruckerSpooler-Modus testen.
			bpl	:5			; => Nicht aktiv.
			bvs	:5			; => Menü wird gestartet.

			lda	Flag_SpoolCount		;Spooler manuell starten ?
			bmi	:5			; => Ja, Ende...

			lda	Flag_Spooler		;DruckerSpooler-Modus testen.
			and	#%00111111		;Zähler abgelaufen ?
			beq	:5			; => SpoolerMenü starten.

			lda	pressFlag		;Taste gedrückt ?
			and	#%11100000		;Nein, Zähler korrigieren.
			beq	:2

::1			lda	#$00			;Verzögerungsschleife
			sta	:2 +1			;neu initialisieren.
			lda	Flag_SpoolCount		;Zähler für DruckerSpooler
			jmp	:3			;initialisieren.

::2			ldx	#$00			;Verzögerungsschleife.
			dec	:2 +1			;Verzögerung abgelaufen ?
			dec	:2 +1			;Verzögerung abgelaufen ?
			bne	:5			;Nein, weiter...

			lda	Flag_Spooler		;Zähler für DruckerSpooler
			and	#%00111111		;einlesen.
			sec
			sbc	#$01			;Zähler korrigieren.
			beq	:4			; => Abgelaufen, Menü starten.
::3			ora	#%10000000		;Spooler-Flag setzen und Ende.
			b $2c
::4			lda	#%11000000		;Menü-Flag setzen und Ende.
			sta	Flag_Spooler
::5			rts

;******************************************************************************
;*** Menü/System-Routinen.
;******************************************************************************
			t "-G3_GetString"
			t "-G3_DoMenu"
			t "-G3_DoIcons"
			t "-G3_DoDlgBox"
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  i_UserColor
; Übergabe		: AKKU              Byte  Farbwert
;			  b xl,yl,xb,yb     Daten Koordinaten des Rechtecks
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  i_ColorBox
; Übergabe		: b xl,yl,xb,yb,f   Daten Koordinaten + Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  DirectColor
; Übergabe		: AKKU              Byte  Farbwert
;			  r2L,r2H,r3,r4     Daten Koordinaten + Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
;			  r5,r6,r7
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Farben für Grafikbildschirm setzen.
; Datum			: 02.07.97
; Aufruf		: JSR  RecColorBox
; Übergabe		: r5L,r5H,r6L,r6H   Daten     Koordinaten des Rechtecks
;			= (xl, yl, xb, yb)  wie bei i_ColorBox oder i_UserColor
;			  r7L               Byte      Farbwert
; Rückgabe		: Bildschirmausgabe
; Verändert		: AKKU,xReg,yReg
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** Farbe definieren.
:xi_UserColor		sta	r7L
			ldy	#$05			;Zeiger auf Inline-Daten ohne Farbe.
			b $2c
:xi_ColorBox		ldy	#$06			;Zeiger auf Inline-Daten mit  Farbe.
			pla
			sta	returnAddress +0
			pla
			sta	returnAddress +1

			tya				;Überlesende Bytes merken.
			pha

			dey				;Zeiger auf letztes Datenbyte.
::1			lda	(returnAddress),y
			sta	r5 -1,y
			dey
			bne	:1

			jsr	RecColorBox		;Farbrechteck darstellen.

			pla				;Anzahl Inlinebytes einlesen.

			php				;Prozessor-Status auf Stack.
			jmp	DoInlineReturn		;Zurück zur aufrufenden Routine.

;*** Farbe über register r2 bis r4 zeichnen.
:xDirectColor		pha

			ldx	#$01
::1			lda	r2L,x
			lsr
			lsr
			lsr
			sta	r5L,x			;r5L = r2L/8
			dex				;r5H = r2H/8
			bpl	:1

			ldx	#$02
::2			lda	r3H,x
			sta	r6H,x
			lda	r3L,x
			ldy	#$02
::3			lsr	r6H,x
			ror
			dey
			bpl	:3
			sta	r6L,x			;r6L = r3/8
			dex				;r7L = r4/8
			dex
			bpl	:2

			ldx	r5H
			inx
			txa
			sec
			sbc	r5L
			sta	r6H			;r6H = Höhe Y
			lda	r5L
			sta	r5H			;r5H = Y-Anfang

			ldx	r7L
			inx
			txa
			sec
			sbc	r6L
			ldx	r6L
			stx	r5L			;r5L = r6L (X-Anfang)
			sta	r6L			;r6L = Breite X
			pla
			sta	r7L			;Farbe nach r7L

;*** Farbe zeichnen.
:xRecColorBox		lda	r5H			;Y-Anfang (in r5L ist X-Anfang)
			ldx	#> COLOR_MATRIX		;r5H auf COLOR_MATRIX-high setzen
			stx	r5H			;COLOR_MATRIX-low ist immer 0!
			tax				;Y-Anfang ins X-Register
::1			jsr	:10			;Zeiger auf erste Zeile (+ X-Anfang)
			bne	:1			;für Farbdaten berechnen.

::2			ldx	r6H			;Höhe des Rechtecks.
::3			ldy	r6L			;Breite des Rechtecks.
			dey
			lda	r7L			;Farbe einlesen und
::4			sta	(r5L),y			;in Farbspeicher kopieren.
			dey
			bpl	:4
			jsr	:11
			bne	:3
			rts

;*** Zeiger auf Datenzeile berechnen.
::10			beq	:13
::11			clc
			lda	r5L
			adc	#40
			sta	r5L
			bcc	:12
			inc	r5H
::12			dex
::13			rts

;*** Aktuelle GEOS-Variabln speichern und auf Standard zurücksetzen.
;    Wird verwendet beim starten eines DAs und einer Dialogbox.
.SaveGEOS_Data		lda	#r2L
			ldx	#r4L
			ldy	#$00			;$00-Byte, Flag zum löschen des
			beq	SwapBytes		;Sprite-Registers.

;*** GEOS-Variablen zurücksetzen.
;    Wird verwendet beim starten eines DAs und einer Dialogbox.
.LoadGEOS_Data		lda	#r4L
			ldx	#r2L
			ldy	#$ff			;Flag für "Kein GEOS-Reset".

;*** Bytes speichern/einlesen.
:SwapBytes		sta	:2 +1			;Zeiger auf Speicher setzen.
			stx	:2 +3

			php				;IRQ-Status retten und
			sei				;IRQs abschalten.

			lda	CPU_DATA		;CPU-Register speichern.
			pha
			lda	#IO_IN			;I/O-Bereich aktivieren.
			sta	CPU_DATA

			lda	#> dlgBoxRamBuf		;GEOS-Variablen im Bereich
			sta	r4H			;":dlgBoxRamBuf" speichern.
			lda	#< dlgBoxRamBuf
			sta	r4L

			tya				;Reset-Flag speichern.
			pha

			ldx	#$00			;GEOS-Variablen im Bereich
::1			lda	DB_SaveMemTab,x		;Zeiger auf Bereich Original-
			sta	r2L			;Daten einlesen.
			inx
			lda	DB_SaveMemTab,x
			sta	r2H
			inx
			ora	r2L			;Ist Adresse = $0000 = Ende ?
			beq	:4			;Ja, Ende...
			lda	DB_SaveMemTab,x		;Anzahl Bytes einlesen.
			sta	r3L
			inx

			ldy	#$00
::2			lda	(r2L),y			;Bytes kopieren.
			sta	(r4L),y
			iny
			dec	r3L
			bne	:2

			tya				;Zeiger auf Zwischenspeicher
			clc				;korrigieren.
			adc	r4L
			sta	r4L
			bcc	:3
			inc	r4H
::3			jmp	:1

::4			pla				;Reset-Flag einlesen und
			tax				;zwischenspeichern.
			bne	:5			; => Kein "GEOS-Reset".
			sta	mobenble		;Sprites löschen.

::5			pla
			sta	CPU_DATA		;CPU-Status zurücksetzen.

			txa				;"GEOS-Reset" auslösen ?
			bne	:6			;Nein, weiter...
			sta	sysDBData		;DB_Box-Status löschen.
			jsr	GEOS_InitVar		;GEOS-Variablen auf Standard.

::6			plp				;IRQ-Status zurücksetzen.
			rts

;*** Zeiger auf die zu sichernden Speicherbereiche für ":DoDlgBox".
:DB_SaveMemTab		w curPattern
			b $17
			w appMain
			b $26
			w DI_VecDefTab
			b $02
			w DM_MenuType
			b $31
			w ProcCurDelay
			b $e3
			w obj0Pointer
			b $08
			w mob0xpos
			b $11
			w mobenble
			b $01
			w mobprior
			b $03
			w mcmclr0
			b $02
			w mob1clr
			b $07
			w moby2
			b $01
			w $0000

;******************************************************************************
;*** System-Icons #2.
;******************************************************************************
			t "-G3_SysIcon2"
;******************************************************************************

;*** Maustasten prüfen.
.TaskManager		bit	Flag_TaskAktiv		;Taskmanager aktiv ?
			bmi	ExitTaskManager		; => Nein, weiter...

			php
			sei
			ldx	CPU_DATA		;CPU-Register merken.
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

.TaskManKey1		ldy	#%01111111		;CBM+CTRL
;			ldy	#%01111011		;CTRL+T
;			ldy	#%10111111		;Hochpfeil.
			sty	$dc00
			ldy	$dc01			;Maustasten einlesen.

			stx	CPU_DATA		;CPU-Register zurücksetzen.
			plp				;IRQ-Register zurücksetzen.

.TaskManKey2		cpy	#%11011011		;CBM+CTRL
;			cpy	#%10111011		;CTRL+T
;			cpy	#%10111111		;Hochpfeil.
							;%11101111 für linke Taste,
							;%11111101 für mittlere Taste,
							;%11111110 für rechte Taste.
							;Kombinationen möglich!
			bne	ExitTaskManager
			jmp	TaskMan_NewJob
:ExitTaskManager	rts				;Keine Taste, weiter...

;******************************************************************************
;*** Speicher bis $FB36 mit $00-Bytes auffüllen.
;******************************************************************************
:_09T			e $fb36
:_09
;******************************************************************************

;******************************************************************************
;*** Tastaturmatrix für Abfrage über
;    Register $DC00/$DC01
;
;-----------------------------------------------------------------------------
;Spalte      #0      #1      #2      #3      #4      #5      #6      #7
;-----------------------------------------------------------------------------
;Reihe
; #0         DEL     RET     CRSR/LR F1      F3      F7      F5      CRSR/UD
;
; #1         3       W       A       4       Z       S       E       SHIFT/L
;
; #2         5       R       D       6       C       F       T       X
;
; #3         7       Y       G       8       B       H       U       V
;
; #4         9       I       J       0       M       K       O       N
;
; #5         +       P       L       -       .       :       (at)    ,
;
; #6         E       *       ;       HOME    SHIFTR  =       ^       /
;
; #7         1       <-      CTRL    2       SPACE   C=      Q       RSTOP
;
;-----------------------------------------------------------------------------
;
;
;******************************************************************************

;*** Wurde Taste gedrückt ?
:GetMatrixCode		lda	keyMode			;Taste in ":currentKey" ?
			bne	:1			;Nein, weiter...
			lda	currentKey
			jsr	NewKeyInBuf
			lda	Flag_CrsrRepeat		;Repeat-Geschwindigkeit neu
			sta	keyMode			;initialisieren.

::1			lda	#$00			;Keine Taste gedrückt.
			sta	r1H
			jsr	CheckKeyboard		;Wurde Taste gedrückt ?
			bne	:5			;Nein, Ende...
			jsr	SHIFT_CBM_CTRL		;SHIFT/CBM/CTRL auswerten.
							;In r1H steht das Ergebnis!

			ldy	#$07
::2			jsr	CheckKeyboard		;Wurde Taste gedrückt ?
			bne	:5			;Nein, Ende...

			lda	KeyMatrixData,y		;Reihe #0 bis #7 durchsuchen.
			sta	$dc00

			lda	$dc01			;Spaltenregister einlesen und
			cmp	KB_LastKeyTab,y		;mit letztem Wert vergleichen.
			sta	KB_LastKeyTab,y		;Neuen Wert merken.
			bne	:4			;Wurde Taste gedrückt ?
							;Ja, weiter...

			cmp	KB_MultipleKey,y	;Mit letzter Taste vergleichen.
			beq	:4			;Übereinstimmung, weiter...
			pha
			eor	KB_MultipleKey,y	;War vorher Taste gedrückt ?
			beq	:3			;Ja, -> Dauerfunktion.
			jsr	MultipleKeyMod		;Neue Taste einlesen.
::3			pla
			sta	KB_MultipleKey,y	;Neue Taste merken.
::4			dey
			bpl	:2			;Nächste Reihe testen.
::5			rts

;*** Tastatur abfragen.
;    Wurde Taste gedrückt ?
:CheckKeyboard		lda	#$ff
			sta	$dc00
			lda	$dc01
			cmp	#$ff
			rts

;*** Taste auswerten, auf Dauerfunktion testen.
:MultipleKeyMod		sta	r0L
			lda	#$07
			sta	r1L

::1			lda	r0L
			ldx	r1L
			and	BitData2,x
			beq	:a
			tya
			asl
			asl
			asl
			adc	r1L
			tax

			bit	r1H			;Wurde SHIFT/CBM gedrückt ?
			bpl	:2			;Nein, weiter...
			lda	keyTab1,x		;Taste mit SHIFT einlesen.
			clv
			bvc	:3

::2			lda	keyTab0,x		;Taste ohne SHIFT einlesen.
::3			sta	r0H			;Taste speichern.

			lda	r1H
			and	#%00100000		;Wurde CTRL-Taste gedrückt ?
			beq	:4			;Nein, weiter...

			lda	r0H			;Tastencode einlesen.
			jsr	TestForLowChar		;Zeichenwert isolieren.
			cmp	#$41			;Buchstabentaste gedrückt ?
			bcc	:4			;Nein, weiter...
			cmp	#$5b
			bcs	:4			;Nein, weiter...

			sec				;Ja, CTRL-Taste erzeugen.
			sbc	#$40			;(Codes von $01-$1A)
			sta	r0H

::4			bit	r1H			;Wurde CBM-Taste gedrückt ?
			bvc	:5			;Nein, weiter...
			lda	r0H			;Ja, Bit #7 aktivieren.
			ora	#%10000000
			sta	r0H

::5			lda	r0H
			sty	r0H

if LANG = LANG_DE
			ldy	#$02			;Wurde Taste "<",">" oder "^"
endif

if LANG = LANG_EN
			ldy	#$08			;Wurde Taste "<",">" oder "^"
endif

::6			cmp	SpecialKeyTab,y		;gedrückt ?
			beq	:7			;Ja, weiter...
			dey
			bpl	:6
			bmi	:8			;Keine Sondertaste.

::7			lda	ReplaceKeyTab,y		;Ersatzcode für Tasten "<",

::8			ldy	r0H
			sta	r0H
			and	#$7f			;Tastencode isolieren.
			cmp	#%00011111		;Taste SHIFT/CBM/CTRL ?
			beq	:9			;Ja, übergehen...

			ldx	r1L
			lda	r0L
			and	BitData2,x
			and	KB_MultipleKey,y
			beq	:9

			lda	#%00001111		;Dauerfunktion, Taste max. 16x
			sta	keyMode			;ausführen -> Puffer voll.
			lda	r0H
			sta	currentKey		;Neue Taste merken und
			jsr	NewKeyInBuf		;in Tastaturpuffer schreiben.
			clv
			bvc	:a

::9			lda	#%11111111		;Keine Taste in
			sta	keyMode			;":currentKey" gespeichert.
			lda	#$00
			sta	currentKey

::a			dec	r1L			;Nächste Spalte testen.
			bmi	:b
			jmp	:1

::b			rts

;*** Tabelle mit Tastaturabfrage-
;    adressen für Reihe #0 bis #7.
:KeyMatrixData		b $fe,$fd,$fb,$f7
			b $ef,$df,$bf,$7f

;******************************************************************************
;*** C64:Deutsch:Beta (Y/Z vertauscht, Stop=TAB)
;*** Da es künftig keine BETA-Versionen mehr geben wird,
;*** ist diese Tastaturmatrix deaktiviert.
;*** Zur Dokumentation verbleibt die Matrix hier erhalten.
;******************************************************************************
;
;if LANG = LANG_DE
;*** Spezialtasten, werden von GEOS
;    durch GEOS-spezifische Tasten
;    ersetzt.
;:SpecialKeyTab		b $bb,$ba,$e0
;:ReplaceKeyTab		b $3c,$3e,$5e
;			s 12				;Dummy-Bytes Englisch/Deutsch!
;
;*** Tastaturtabelle #0.
;    Tasten ohne SHIFT/CBM/CTRL.
;    Entsprechend Tastaturmatrix!
;:keyTab0		b $1d,$0d,$1e,$0e,$01,$03,$05,$11
;			b $33,$77,$61,$34,$7a,$73,$65,$1f
;			b $35,$72,$64,$36,$63,$66,$74,$78
;			b $37,$79,$67,$38,$62,$68,$75,$76
;			b $39,$69,$6a,$30,$6d,$6b,$6f,$6e
;			b $7e,$70,$6c,$27,$2e,$7c,$7d,$2c
;			b $1f,$2b,$7b,$12,$1f,$23,$1f,$2d
;			b $31,$14,$1f,$32,$20,$1f,$71,$09
;
;*** Tastaturtabelle #1.
;    Tasten mit SHIFT.
;    Entsprechend Tastaturmatrix!
;:keyTab1		b $1c,$0d,$08,$0f,$02,$04,$06,$10
;			b $40,$57,$41,$24,$5a,$53,$45,$1f
;			b $25,$52,$44,$26,$43,$46,$54,$58
;			b $2f,$59,$47,$28,$42,$48,$55,$56
;			b $29,$49,$4a,$3d,$4d,$4b,$4f,$4e
;			b $3f,$50,$4c,$60,$3a,$5c,$5d,$3b
;			b $5e,$2a,$5b,$13,$1f,$27,$1f,$5f
;			b $21,$14,$1f,$22,$20,$1f,$51,$17
;endif

;******************************************************************************
;*** C64:Deutsch (DIN)
;******************************************************************************

if LANG = LANG_DE
;*** Spezialtasten, werden von GEOS
;    durch GEOS-spezifische Tasten
;    ersetzt.
:SpecialKeyTab		b $bb,$ba,$e0
:ReplaceKeyTab		b $3c,$3e,$5e
			s 12				;Dummy-Bytes Englisch/Deutsch!

;*** Tastaturtabelle #0.
;    Tasten ohne SHIFT/CBM/CTRL.
;    Entsprechend Tastaturmatrix!
:keyTab0		b $1d,$0d,$1e,$0e,$01,$03,$05,$11
			b $33,$77,$61,$34,$79,$73,$65,$1f
			b $35,$72,$64,$36,$63,$66,$74,$78
			b $37,$7a,$67,$38,$62,$68,$75,$76
			b $39,$69,$6a,$30,$6d,$6b,$6f,$6e
			b $7e,$70,$6c,$27,$2e,$7c,$7d,$2c
			b $1f,$2b,$7b,$12,$1f,$23,$1f,$2d
			b $31,$14,$1f,$32,$20,$1f,$71,$16

;Zusätzliche Label um im GD.CONFIG die Umschaltung
;zwischen QWERTZ/QWERTY zu ermöglchen.
.key0z = keyTab0+12
.key0y = keyTab0+25

;*** Tastaturtabelle #1.
;    Tasten mit SHIFT.
;    Entsprechend Tastaturmatrix!
:keyTab1		b $1c,$0d,$08,$0f,$02,$04,$06,$10
			b $40,$57,$41,$24,$59,$53,$45,$1f
			b $25,$52,$44,$26,$43,$46,$54,$58
			b $2f,$5a,$47,$28,$42,$48,$55,$56
			b $29,$49,$4a,$3d,$4d,$4b,$4f,$4e
			b $3f,$50,$4c,$60,$3a,$5c,$5d,$3b
			b $5e,$2a,$5b,$13,$1f,$27,$1f,$5f
			b $21,$14,$1f,$22,$20,$1f,$51,$17

;--- Ergänzung: 03.01.19/M.Kanet
;Zusätzliche Label um im GEOS.Editor die Umschaltung
;zwischen QWERTZ/QWERTY zu ermöglchen.
.key1z = keyTab1+12
.key1y = keyTab1+25
endif

;******************************************************************************
;*** C64:Englisch (Standard)
;******************************************************************************

if LANG = LANG_EN
;*** Spezialtasten, werden von GEOS
;    durch GEOS-spezifische Tasten
;    ersetzt.
:SpecialKeyTab		b $db,$dd,$de,$ad,$af,$aa,$c0,$ba,$bb
:ReplaceKeyTab		b $7b,$7d,$7c,$5f,$5c,$7e,$60,$7b,$7d

;*** Tastaturtabelle #0.
;    Tasten ohne SHIFT/CBM/CTRL.
;    Entsprechend Tastaturmatrix!
:keyTab0		b $1d,$0d,$1e,$0e,$01,$03,$05,$11
			b $33,$77,$61,$34,$7a,$73,$65,$1f
			b $35,$72,$64,$36,$63,$66,$74,$78
			b $37,$79,$67,$38,$62,$68,$75,$76
			b $39,$69,$6a,$30,$6d,$6b,$6f,$6e
			b $2b,$70,$6c,$2d,$2e,$3a,$40,$2c
			b $18,$2a,$3b,$12,$1f,$3d,$5e,$2f
			b $31,$14,$1f,$32,$20,$1f,$71,$16

;*** Tastaturtabelle #1.
;    Tasten mit SHIFT.
;    Entsprechend Tastaturmatrix!
:keyTab1		b $1c,$0d,$08,$0f,$02,$04,$06,$10
			b $23,$57,$41,$24,$5a,$53,$45,$1f
			b $25,$52,$44,$26,$43,$46,$54,$58
			b $27,$59,$47,$28,$42,$48,$55,$56
			b $29,$49,$4a,$30,$4d,$4b,$4f,$4e
			b $2b,$50,$4c,$2d,$3e,$5b,$40,$3c
			b $18,$2a,$5d,$13,$1f,$3d,$5e,$3f
			b $21,$14,$1f,$22,$20,$1f,$51,$17
endif

;*** Neue Taste in Tastaturpuffer.
:NewKeyInBuf		php
			sei
			pha
			lda	#$80
			ora	pressFlag
			sta	pressFlag
			ldx	MaxKeyInBuf
			pla
			sta	keyBuffer,x
			jsr	Add1Key
			cpx	keyBufPointer
			beq	:1
			stx	MaxKeyInBuf
::1			plp
			rts

;*** Zeichen aus Tastaturpuffer holen.
:GetKeyFromBuf		php
			sei
			ldx	keyBufPointer
			lda	keyBuffer,x
			sta	keyData
			jsr	Add1Key
			stx	keyBufPointer
			cpx	MaxKeyInBuf
			bne	:1
			pha
			lda	#$7f
			and	pressFlag
			sta	pressFlag
			pla
::1			plp
			rts

;*** Zähler für ":MaxKeyInBuf" und
;    ":keyBufPointer" korrigieren.
:Add1Key		inx
			cpx	#$10
			bne	:1
			ldx	#$00
::1			rts

;*** Zeichen über Tastatur einlesen.
:xGetNextChar		bit	pressFlag
			bpl	:1
			jmp	GetKeyFromBuf
::1			lda	#$00			;Keine Taste gedrückt.
			rts

;*** Gedrückte Taste aus Matrix mit
;    SHIFT/CBM/CTRL verknüpfen.
:SHIFT_CBM_CTRL		lda	#%11111101		;Linke SHIFT-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #1.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%10000000		;Bit #7 = Spalte 7 gesetzt ?
			bne	:1			;Ja, SHIFT-Taste gedrückt.

			lda	#%10111111		;Rechte SHIFT-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #6.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00010000		;Bit #4 = Spalte 4 gesetzt ?
			beq	:2			;Nein, weiter...

::1			lda	#%10000000		;Zeichen in Tastenspeicher
			ora	r1H			;mit SHIFT verknüpfen.
			sta	r1H

::2			lda	#%01111111		;CBM-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #7.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00100000		;Bit #5 = Spalte 5 gesetzt ?
			beq	:3			;Nein, weiter...

			lda	#%01000000		;Zeichen in Tastenspeicher
			ora	r1H			;mit CBM verknüpfen.
			sta	r1H

::3			lda	#%01111111		;CTRL-Taste abfragen.
			sta	$dc00			;Tastaturabfrage Reihe #7.
			lda	$dc01			;Spaltenregister einlesen.
			eor	#%11111111
			and	#%00000100		;Bit #2 = Spalte 2 gesetzt ?
			beq	:4

			lda	#%00100000		;Zeichen in Tastenspeicher
			ora	r1H			;mit CTRL verknüpfen.
			sta	r1H
::4			rts

;*** Auf Taste für Kleinbuchstaben testen.
:TestForLowChar		pha				;Zeichen merken.
			and	#%01111111		;GEOS nur von $20 - $7F !!!
			cmp	#$61			;Kleinbuchstabe ?
			bcc	:1			;Nein, weiter...
			cmp	#$7b
			bcs	:1			;Nein, weiter...
			pla
			sec				;Ja, in Großbuchstaben
			sbc	#$20			;umrechnen.
			pha
::1			pla
			rts

;******************************************************************************
;*** Speicher bis $FD68 mit $00-Bytes auffüllen.
;******************************************************************************
:_10T			e $fd68
:_10
;******************************************************************************

;*** Maus- und Tastatur abfragen.
:ExecMseKeyb		bit	pressFlag		;Eingabetreiber geändert ?
			bvc	:1			;Nein, weiter...

			lda	#%10111111
			and	pressFlag
			sta	pressFlag
			lda	inputVector   +0
			ldx	inputVector   +1
			jsr	CallRoutine

::1			lda	pressFlag
			and	#%00100000		;Wurde Mausknopf gedrückt ?
			beq	:2			;Nein, weiter...

			lda	#%11011111
			and	pressFlag
			sta	pressFlag
			lda	mouseVector  +0		;Mausklick ausführen.
			ldx	mouseVector  +1
			jsr	CallRoutine

::2			bit	pressFlag		;Wurde Taste gedrückt ?
			bpl	:3			;Nein, weiter...

			jsr	GetKeyFromBuf		;Taste aus Tastaturpuffer.
			lda	keyVector    +0		;Tastaturabfrage des Anwenders
			ldx	keyVector    +1		;aufrufen.
			jsr	TestHelpSystem		;vorher ":CallRoutine"

::3			lda	faultData		;Hat Maus Bereich verlassen ?
			beq	xESC_RULER		;Nein, weiter...

			lda	mouseFaultVec+0		;Maus hat bereich verlassen,
			ldx	mouseFaultVec+1		;zugehörige Anwender-Routine
			jsr	CallRoutine		;aufrufen.
			lda	#$00
			sta	faultData
:xESC_RULER		rts

;*** GEOS-Uhrzeit aktualisieren.
:SetGeosClock		sei

			lda	CPU_DATA
			pha
			lda	#IO_IN
			sta	CPU_DATA

			lda	$dc0f			;Uhrzeit aktivieren.
			and	#$7f
			sta	$dc0f

			lda	$dc0b			;Stundenregister
			and	#$1f			;Einer-/Zehnerstd. ausblenden
			cmp	#$12			;12 Uhr?
			bne	:1			;>nein
			bit	$dc0b			;am/pm Flag testen
			bmi	:2			;>nachmittags (pm) 12 Uhr
			lda	hour			;Stunden auf 0 Uhr ?
			beq	:2			;>ja dann Datum nicht erhöhen

			jsr	SetADDR_GetNxDay	;Zeiger auf ":G3_GetNextDay".
			jsr	SwapRAM			;Routine in Speicher holen.
			jsr	LOAD_GETNXDAY		;Neuen Tag beginnen.

			lda	#$00			;>auf 0 Uhr stellen
::1			bit	$dc0b			;am/pm Flag testen
			bpl	:2			;>vormittags (am)
			sed				;>nachmittags (pm)
			clc				;12 addieren
			adc	#$12
			cld
::2			ldx	#$00
			ldy	#$02
::3			jsr	BCDtoDEZ		;Datum kopieren.
			bpl	:3

			ldx	#19
			lda	year			;Jahrtausendbyte festlegen.
			cmp	#99
			bcs	:56
			inx
::56			stx	millenium

			ldx	$dc0d			;Alarm-Zustand einlesen.
			pla
			sta	CPU_DATA		;I/O abschalten.

			txa
			bit	alarmSetFlag		;Weckzeit aktiviert ?
			bpl	:5			; => Ja, weiter...
			and	#%00000100		;"CIA-Timer"-Weckzeit erreicht?
			beq	:6			; => Nein, Ende...

			lda	#%01001010		;Anzahl Signale initialisieren.
			sta	alarmSetFlag		;Vorgabewert: 10 Alarm-Signale.
			lda	alarmTmtVector +1	;User-Weckroutine definiert ?
			beq	:5			; => Nein, Weckton ausgeben.
			jmp	(alarmTmtVector)	;Weckroutine anspringen.

::5			bit	alarmSetFlag		;Alarm-Routine ausführen ?
			bvc	:6			; => Nein, weiter...
			jsr	SetADDR_DoAlarm		;Zeiger auf DoAlarm-Routine.
			jsr	SwapRAM			;Routine in Speicher einlesen.
			jsr	LOAD_DOALARM		;Weckton aktivieren.
::6			cli
			rts

;*** BCD-Zahl nach DEZ wandeln.
:BCDtoDEZ		sty	:3 +1
			pha
			lsr
			lsr
			lsr
			lsr
			tay
			pla
			and	#%00001111
			clc
::1			dey
			bmi	:2
			adc	#10
			bne	:1
::2			sta	hour,x
			inx
::3			ldy	#$ff
			lda	year    ,y		;Aktuelles Datum in
			sta	dateCopy,y		;Zwischenspeicher kopieren.
			lda	$dc08   ,y
			dey
			rts

;*** Zeiger auf Diskettenname einlesen.
:xGetPtrCurDkNm		ldy	curDrive
			lda	DrvNmVecL -8,y
			sta	zpage     +0,x
			lda	DrvNmVecH -8,y
			sta	zpage     +1,x
			rts

;******************************************************************************
;*** Speicher bis $FE64 mit $00-Bytes auffüllen.
;******************************************************************************
:_82T			e $fe64
:_82
;******************************************************************************

;*** Einsprungtabelle für TaskManager-Menü.
;--- Hinweis:
;TopDesk V4/V5 nutzt die Adresse als
;Einsprung in den TaskManager für das
;"GEOS"-Menüicon.
.TaskMan_NewJob		lda	#$00			;TaskMenü starten.
			b $2c
.TaskMan_QuitJob	lda	#$ff			;Aktuellen Task beenden.
			b $2c
.TaskMan_Quit_DA	lda	#$7f			;DeskAccessorie beenden.
.TaskMan_LoadMenu	pha				;IRQ-Register speichern.

			sei
			ldx	#%10000000		;TaskManager deaktivieren.
			stx	Flag_TaskAktiv
			jsr	SetADDR_TaskMan		;Zeiger auf TaskMan-Menü und
			jsr	SwapRAM			;Routine in RAM einlesen.
			pla
			jsr	LOAD_TASKMAN		;TaskManager starten.
			jmp	SwapRAM			;Speicher zurücksetzen.

;******************************************************************************
;*** Speicher bis $FE80 mit $00-Bytes auffüllen.
;******************************************************************************
:_11T			e MOUSE_BASE
:_11
;******************************************************************************

			d "Mouse1351"			;1351-Standard-Treiber.
;			d "SmartMouse"			;CMD SmartMouse.
;			d "SuperMouse64"		;SuperMouse64.
;			d "MicroMysX1"			;MicroMys: Zeile.
;			d "MicroMysX2"			;MicroMys: Seite.
;			d "SuperStick.1"		;Joystick: Port1.
;			d "SuperStick.2"		;Joystick: Port2.

:xInitMouse		= MOUSE_BASE +0
:xSlowMouse		= MOUSE_BASE +3
:xUpdateMouse		= MOUSE_BASE +6
:xSetMouse		= MOUSE_BASE +9

;******************************************************************************
;*** Speicher bis $FFFA mit $00-Bytes auffüllen.
;******************************************************************************
:_12T			e IRQ_BASE
:_12
;******************************************************************************

			w IRQ_END
			w IRQ_END
			w GEOS_IRQ
