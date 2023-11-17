; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Diskettenname einlesen.
; Datum			: 02.07.97
; Aufruf		: JSR  CBM_GetDskNam
; Übergabe		: -
; Rückgabe		: xReg	Byte $00 = Disk im Laufwerk
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r4
; Variablen		: -
; Routinen		: -NewOpenDisk Neue Diskette öffnen
;			  -DiskError Diskettenfehler anzeigen
;			  -GetPtrCurDkNm									 Zeiger auf Diskettenname
;			  -ConvertChar ASCII nach GEOS-ASCII wandeln
;******************************************************************************

;*** L450: Datenträgername ermitteln.
.CBM_GetDskNam		jsr	NewOpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:101			;Nein, weiter...
			jmp	DiskError		;Abbruch.

::101			ldx	#r0L			;Zeiger auf Diskettenname einlesen.
			jsr	GetPtrCurDkNm

			ldy	#$0f
::102			lda	(r0L),y			;Diskettenname kopieren.
			jsr	ConvertChar		;ASCII nach GEOS-ASCII wandeln.
			sta	cbmDiskName,y
			dey
			bpl	:102
			rts

;*** Speicher für Disketten-Namen.
.cbmDiskName		s 16 +1
