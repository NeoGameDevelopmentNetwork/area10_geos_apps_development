; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Vektor auf Typ/Farb-Tabelle definieren.
:DefGTypeID		ldy	#$02
			lda	(r15L),y		;CBM-Dateityp einlesen.
			and	#FTYPE_MODES		;Dateityp isolieren.
			cmp	#FTYPE_DIR		;Typ = Verzeichnis?
			bne	:0			; => Nein, weiter...
			lda	#24			;GEOS-Dateityp "Verzeichnis".
			bne	:1

::0			ldy	#$18
			lda	(r15L),y		;GEOS-Dateityp einlesen.
			cmp	#24			;Unbekannter Typ?
			bcc	:1			; => Nein, weiter...
			lda	#23			;Typ "Unknown" setzen.
::1			rts

;*** Zeiger auf GEOS-Dateityp.
:GetGeosType		jsr	DefGTypeID		;Zeiger auf Tabelle mit
			asl				;GEOS-Texten setzen.
			tax
			lda	vecGTypeText +0,x	;Zeiger auf Text für
			ldy	vecGTypeText +1,x
			rts
