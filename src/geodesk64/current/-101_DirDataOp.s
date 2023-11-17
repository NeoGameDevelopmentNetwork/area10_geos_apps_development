; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;Routine:   SET_LOAD_DISK
;Parameter: -
;Rückgabe:  GD_RELOAD_DIR = $80 => Verzeichnis von Disk einlesen.
;Verändert: A
;Funktion:  Flag setzen "Verzeichnis von Disk neu einlesen".
;******************************************************************************
.SET_LOAD_DISK		lda	#GD_LOAD_DISK		;Dateien immer von Disk einlesen.
			b $2c

;******************************************************************************
;Routine:   SET_TEST_CACHE
;Parameter: -
;Rückgabe:  GD_RELOAD_DIR = $40 => Verzeichnis von Cache oder Disk einlesen.
;Verändert: A
;Funktion:  Flag setzen "Verzeichnis von Cache oder Disk einlesen".
;******************************************************************************
.SET_TEST_CACHE		lda	#GD_TEST_CACHE		;Dateien aus Cache oder von Disk.
			b $2c

;******************************************************************************
;Routine:   SET_SORT_MODE
;Parameter: -
;Rückgabe:  GD_RELOAD_DIR = $3F => Verzeichnis im Speicher sortieren.
;Verändert: A
;Funktion:  Flag setzen "Verzeichnis im Speicher sortieren".
;******************************************************************************
.SET_SORT_MODE		lda	#GD_SORT_ONLY		;Nur Dateien sortieren.
			b $2c

;******************************************************************************
;Routine:   SET_LOAD_CACHE
;Parameter: -
;Rückgabe:  GD_RELOAD_DIR = $00 => Verzeichnis aus Cache einlesen.
;Verändert: A
;Funktion:  Flag setzen "Verzeichnis aus Cache einlesen".
;******************************************************************************
.SET_LOAD_CACHE		lda	#GD_LOAD_CACHE		;Dateien aus Cache einlesen.
			sta	GD_RELOAD_DIR
			rts

;******************************************************************************
;Routine:   SET_POS_CACHE
;Parameter: WM_WCODE = Fenster-Nr.
;           r14  = Nr. Eintrag in Dateitabelle.
;Rückgabe:  r14  = Zeiger auf Verzeichnis-Cache.
;           r13  = Zeiger auf Icon-Cache oder $0000=Kein Cache.
;           r12L = Speicherbank Icon-Cache.
;           r12H = Speicherbank Verzeichnis-Cache.
;Verändert: A,X,Y,r6-r8,r12-r14
;Funktion:  Zeiger auf Datei-Eintrag im Cache berechnen.
;******************************************************************************
.SET_POS_CACHE		PushB	r14L			;Zeiger auf Eintrag-Nr. speichern.
if MAXENTRY16BIT = TRUE
			PushB	r14H
endif
			ldx	#r14L
			ldy	#5			;Größe Dateieintrag 2^5 = 32 Bytes.
if MAXENTRY16BIT = FALSE
			LoadB	r14H,0			;High-Byte Dateizähler löschen.
endif
			jsr	DShiftLeft		;Anzahl Einträge x 32 Bytes.

if MAXENTRY16BIT = TRUE
			PopB	r13H
endif
			PopB	r13L			;Eintrag-Nr. einlesen.

			ldx	#r13L
			ldy	#6			;Größe Iconeintrag 2^6 = 64 Bytes.
if MAXENTRY16BIT = FALSE
			LoadB	r13H,0
endif
			jsr	DShiftLeft		;Anzahl Einträge x 64 Bytes.

			lda	WM_WCODE
			asl
			tax

			lda	r14L			;Zeiger auf Verzeichnis-Cache
			clc				;in REU berechnen.
			adc	vecDirDataRAM +0,x
			sta	r14L
			lda	r14H
			adc	vecDirDataRAM +1,x
			sta	r14H

			lda	r13L			;Zeiger auf Icon-Cache
			clc				;in REU berechnen.
			adc	vecIconDataRAM +0,x
			sta	r13L
			lda	r13H
			adc	vecIconDataRAM +1,x
			sta	r13H

			lda	GD_SYSDATA_BUF		;64K-Speicher Verzeichnis-Cache.
			sta	r12H

			lda	GD_ICONDATA_BUF		;64K-Speicher Icon-Cache.
			sta	r12L

			rts

;******************************************************************************
;Routine:   SET_POS_RAM
;Parameter: XReg = Zero-Page-Adresse Faktor #1.
;Rückgabe:  Zero-Page Faktor#1 erhält Adresse im RAM.
;Verändert: A,X,Y,r6-r8
;Funktion:  Zeiger auf Eintrag im Speicher berechnen.
;******************************************************************************
.SET_POS_RAM		ldy	#5			;Größe Dateieintrag 2^5 = 32 Bytes.

if MAXENTRY16BIT = FALSE
			lda	#$00			;High-Byte Dateizähler löschen.
			sta	zpage +1,x
endif

			jsr	DShiftLeft		;Anzahl Einträge x 32 Bytes.

			lda	zpage +0,x		;Startadresse Verzeichnisdaten.
			clc
			adc	#<BASE_DIR_DATA
			sta	zpage +0,x
			lda	zpage +1,x
			adc	#>BASE_DIR_DATA
			sta	zpage +1,x
			rts

;******************************************************************************
;Routine:   ADDR_CACHE
;Parameter: XReg = Zero-Page-Adresse für Startadresse Verzeichnis-Cache.
;Rückgabe:  Zero-Page-Adresse enthält Zeiger auf Verzeichnis-Cache.
;Verändert: A,X
;Funktion:  Startadresse Verzeichnis-Cache in REU setzen.
;******************************************************************************
:ADDR_CACHE_r1		ldx	#r1L
:ADDR_CACHE		lda	WM_WCODE
			asl
			tay
			lda	vecDirDataRAM +0,y
			sta	zpage +0,x
			lda	vecDirDataRAM +1,y
			sta	zpage +1,x
			rts

;******************************************************************************
;Routine:   ADDR_RAM_rXX
;Parameter: XReg = Zero-Page-Adresse für ":BASE_DIR_DATA".
;Rückgabe:  Zero-Page-Adresse enthält Zeiger auf ":BASE_DIR_DATA".
;Verändert: A,X
;Funktion:  Zeiger auf ":BASE_DIR_DATA" im Speicher setzen.
;******************************************************************************
.ADDR_RAM_r15		ldx	#r15L
.ADDR_RAM_x		lda	#<BASE_DIR_DATA
			sta	zpage +0,x
			lda	#>BASE_DIR_DATA
			sta	zpage +1,x
			rts

;******************************************************************************
;Routine:   SET_CACHE_DATA
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  r0  = Zeiger auf ":BASE_DIR_DATA".
;           r1  = Zeiger auf Cache in DACC.
;           r2  = Cache-Größe.
;           r3L = 64Kb Speicherbank für Cache.
;Verändert: A,X,r0-r3L
;Funktion:  Zeiger auf ":BASE_DIR_DATA" im Speicher setzen.
;******************************************************************************
.SET_CACHE_DATA		ldx	#r0L
			jsr	ADDR_RAM_x

			jsr	ADDR_CACHE_r1

			LoadW	r2,MAX_DIR_ENTRIES *32

			lda	GD_SYSDATA_BUF
			sta	r3L
			rts

;******************************************************************************
;Routine:   UPDATE_WIN_DATA
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe:  -
;Verändert: A,X,Y,r0-r15
;Funktion:  Speichert Verzeichnisdaten im Cache,
;           speichert Fenster in ScreenBuffer und
;           aktualisiert die Fensterdaten.
;******************************************************************************
.UPDATE_WIN_DATA	jsr	SET_CACHE_DATA		;Verzeichnisdaten aktualisieren.
			jsr	StashRAM

			jsr	WM_SAVE_SCREEN		;ScreenBuffer aktualisieren.
			jmp	WM_SAVE_WIN_DATA	;Fensterdaten aktualisieren.
