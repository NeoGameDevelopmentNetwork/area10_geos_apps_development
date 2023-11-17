; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Neue NewOpenDisk-Routine.
; Datum			: 03.07.97
; Aufruf		: JSR  NewOpenDisk
; Übergabe		: -
; Rückgabe		: xReg	 $00 = Kein Fehler.
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r4
; Variablen		: -
; Routinen		: -NewDisk Diskette initialisieren
;			  -GetDirHead BAM einlesen
;			  -ChkDkGEOS Auf GEOS-Diskette prüfen
;			  -GetPtrCurDkNm									 Zeiger auf Diskettenname
;			  -CopyFString Textstring kopieren
;******************************************************************************

;*** Neue NewOpenDisk-Routine.
.NewOpenDisk		jsr	NewDisk			;Diskette initialisieren.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:101			;Ja, Abbruch.

			jsr	ChkDkGEOS		;GEOS-Diskette ?

			ldx	#r1L			;Diskettenname einlesen.
			jsr	GetPtrCurDkNm
			LoadW	r0,curDirHead +$90
			ldx	#r0L
			ldy	#r1L
			lda	#16
			jsr	CopyFString

			ldx	#$00			;Kein Fehler.
::101			rts
