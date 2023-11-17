; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
;Routine  : SET_POS_CACHE
;Parameter: WM_WCODE = Fenster-Nr.
;           r14  = Nr. Eintrag in Dateitabelle.
;Rückgabe : r14  = Zeiger auf Verzeichnis-Cache.
;           r13  = Zeiger auf Icon-Cache oder $0000=Kein Cache.
;           r12L = Speicherbank Icon-Cache.
;           r12H = Speicherbank Verzeichnis-Cache.
;Verändert: A,X,Y,r6-r8,r12-r14
;Funktion : Zeiger auf Datei-Eintrag im Cache berechnen.
;
.SET_POS_CACHE		lda	r14L			;Zeiger auf Eintrag-Nr. speichern.
			pha

			lda	#$00			;High-Byte Dateizähler löschen.
			sta	r14H

			ldx	#r14L
			ldy	#5			;Größe Dateieintrag 2^5 = 32 Bytes.
			jsr	DShiftLeft		;Anzahl Einträge x 32 Bytes.

			pla				;Eintrag-Nr. einlesen.
			sta	r13L

			lda	#$00			;High-Byte Eintrag-Nr. löschen.
			sta	r13H

			ldx	#r13L
			ldy	#6			;Größe Iconeintrag 2^6 = 64 Bytes.
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

;
;Routine  : ADDR_CACHE
;Parameter: XReg = Zero-Page-Adresse für Startadresse Verzeichnis-Cache.
;Rückgabe : Zero-Page-Adresse enthält Zeiger auf Verzeichnis-Cache.
;Verändert: A,X
;Funktion : Startadresse Verzeichnis-Cache in REU setzen.
;
:ADDR_CACHE_r1		ldx	#r1L
:ADDR_CACHE		lda	WM_WCODE
			asl
			tay
			lda	vecDirDataRAM +0,y
			sta	zpage +0,x
			lda	vecDirDataRAM +1,y
			sta	zpage +1,x
			rts

;
;Routine  : ADDR_RAM_rXX
;Parameter: XReg = Zero-Page-Adresse für ":BASE_DIRDATA".
;Rückgabe : Zero-Page-Adresse enthält Zeiger auf ":BASE_DIRDATA".
;Verändert: A,X
;Funktion : Zeiger auf ":BASE_DIRDATA" im Speicher setzen.
;
.ADDR_RAM_r15		ldx	#r15L
.ADDR_RAM_x		lda	#< BASE_DIRDATA
			sta	zpage +0,x
			lda	#> BASE_DIRDATA
			sta	zpage +1,x
			rts

;
;Routine  : SET_CACHE_DATA
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : r0  = Zeiger auf ":BASE_DIRDATA".
;           r1  = Zeiger auf Cache in DACC.
;           r2  = Cache-Größe.
;           r3L = 64Kb Speicherbank für Cache.
;Verändert: A,X,r0-r3L
;Funktion : Zeiger auf ":BASE_DIRDATA" im Speicher setzen.
;
.SET_CACHE_DATA		ldx	#r0L
			jsr	ADDR_RAM_x

			jsr	ADDR_CACHE_r1

			lda	#< MAX_DIR_ENTRIES *32
			sta	r2L
			lda	#> MAX_DIR_ENTRIES *32
			sta	r2H

			lda	GD_SYSDATA_BUF
			sta	r3L
			rts
