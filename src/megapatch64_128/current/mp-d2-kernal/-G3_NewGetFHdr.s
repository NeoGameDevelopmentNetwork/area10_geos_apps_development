; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

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
			bne	:err			;Ja, Abbruch.

			ldy	#$01 +1			;Zeiger auf VLIR-Sektor
			jsr	Get1stSek		;einlesen. Grund unbekannt.
			jsr	GetLoadAdr		;Zeiger auf Ladeadresse setzen.
::err			rts
