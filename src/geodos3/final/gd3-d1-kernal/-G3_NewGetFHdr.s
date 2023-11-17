; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Infoblock einlesen.
:xGetFHdrInfo		ldy	#$13			;Zeiger auf Sektor für
			jsr	:1			;Infoblock nach r1L/r1H
							;einlesen.

			lda	r1L			;Sektor-Zeiger nach fileTrScTab
			sta	fileTrScTab+0		;kopieren. Grund unbekannt.
			lda	r1H
			sta	fileTrScTab+1

			jsr	Vec_fileHeader
			jsr	GetBlock		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:2			;Ja, Abbruch.

			ldy	#$01			;Zeiger auf VLIR-Sektor
			jsr	:1			;einlesen. Grund unbekannt.
			jmp	GetLoadAdr		;Zeiger auf Ladeadresse setzen.

;*** Vektor aus Infoblock einlesen.
::1			lda	(r9L),y
			sta	r1L
			iny
			lda	(r9L),y
			sta	r1H
::2			rts
