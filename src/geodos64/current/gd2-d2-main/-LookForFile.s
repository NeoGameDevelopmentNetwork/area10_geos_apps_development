; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Datei nach GEOS-Klasse suchen.
; Datum			: 04.07.97
; Aufruf		: JSR  LookForFile
; Übergabe		: AKKU	Byte GEOS-Dateityp
;			  xReg,yRegWord Zeiger auf GEOS-Klasse
; Rückgabe		: -xReg	Byte $00 = Datei gefunden
;			  -FileNameBuf17 Byte Dateiname
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -FileNameBuf17 Byte Speicher für Dateiname
; Routinen		: -FindFTypes Dateityp suchen
;			  -FindFile Dateieintrag suchen
;******************************************************************************

;*** Dateityp suchen.
.LookForFile		sta	r7L			;GEOS-Dateityp merken.
			stx	r10L			;Zeiger auf GEOS-Klasse merken.
			sty	r10H
			LoadW	r6,FileNameBuf		;Zeiger auf Speicher für Dateiname.
			LoadB	r7H,1			;Nur eine Datei suchen.
			jsr	FindFTypes		;Dateityp suchen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			lda	r7H			;Datei gefunden ?
			bne	:101			;Nein, Ende...

			LoadW	r6,FileNameBuf
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Diskettenfehler ?
			beq	:102			;Nein, weiter...

::101			ldx	#$05			;Fehler, Datei nicht gefunden.
::102			rts

;*** Speicher für Dateiname.
.FileNameBuf		s 17
