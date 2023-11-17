; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Partitionen oder DiskImages einlesen.
:getDiskData		ldx	WM_WCODE		;Laufwerk einlesen.
			ldy	WIN_DRIVE ,x		;Laufwerk verfügbar?
			beq	:error			; => Nein, Ende...

			lda	driveType -8,y		;GEOS-Laufwerk definiert?
			beq	:error			; => Nein, Ende...

			tya
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			beq	:get_data		; => Nein, weiter...

;--- Laufwerksfehler, Abbruch.
::error			lda	#$00			;Dateizähler löschen.
			sta	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			sta	WM_DATA_MAXENTRY +1
endif

			jsr	WM_SAVE_WIN_DATA	;Fensterdaten speichern.

			ldx	#$00			;Flag setzen "Dateien einlesen".
			rts

;--- Partitionen/DiskImages einlesen.
::get_data		ldx	curDrive		;Aktuellen Laufwerkstyp für
			lda	driveType -8,x		;DiskImage-Vergleich speichern.
			and	#DRIVE_MODES
			sta	DiskImgTyp

			jsr	i_FillRam		;Verzeichnis-Speicher löschen.
			w	(OS_VARS - BASE_DIR_DATA)
			w	BASE_DIR_DATA
			b	$00

			ldy	curDrive		;Auf CMD-Laufwerk testen.
			lda	RealDrvMode -8,y	;Bit %7 gesetzt = CMD?
			bmi	:drive_cmd		; => Ja, weiter...

			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:drive_unknown		; => Nein, Laufwerk unbekannt.

::drive_sd2iec		lda	#%01000000		; => DiskImages einlesen.
			b $2c
::drive_cmd		lda	#%10000000		; => Partitionen einlesen.
			b $2c
::drive_unknown		lda	#%00000000		; => Fehler, Abbruch,

			ldx	WM_WCODE
			sta	WIN_DATAMODE,x		;Fenstermodus speichern.
			tax				;Fehlermodus gültig?
			beq	:error			; => Nein, Abbruch...
			bpl	:disk_sd2iec		; => Ja, weiter...

;--- Partitionen von CMD-Laufwerken einlesen.
::disk_cmd		jsr	READ_PART_DATA		;CMD-Partitionen einlesen.
			jmp	:saveDiskInfo

;--- SD2IEC-Modus testen.
::disk_sd2iec		jsr	READ_SD2IEC_DATA	;SD2IEC-DiskImages einlesen.

;--- Neue Verzeichnis-Daten speichern.
::saveDiskInfo		lda	ListEntries		;Anzahl Einträge speichern.
			sta	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			lda	#$00
			sta	WM_DATA_MAXENTRY +1
endif
			jsr	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.

			jsr	SET_CACHE_DATA		;Zeiger auf Dateien im Cache.
			jsr	StashRAM		;Verzeichnis in Cache speichern.

::exit			ldx	#$ff			;Flag setzen "Part/Img anzeigen".
			rts
