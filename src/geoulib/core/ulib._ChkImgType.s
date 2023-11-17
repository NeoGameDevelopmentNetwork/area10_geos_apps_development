; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Laufwerksformat testen
;
;Übergabe : r6  = (Verzeichnispfad/)Dateiname
;           r7L = GEOS-Laufwerk 8 bis 11
;Rückgabe : X = Fehlerstatus, $00=OK
;               UCI_STATUS_MSG = Status-Meldung
;               UCI_DATA_MSG   = Datei-Informationen
;Verändert: A,X,Y

:ULIB_DIMG_TYPE		jsr	_UCID_OPEN_FILE_READ
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	_UCID_FILE_INFO		;Datei-Informationen einlesen.
			jsr	_UCID_CLOSE_FILE	;Datei schließen.

			ldy	r7L			;Dateityp überprüfen.
			lda	driveType -8,y
			and	#ST_DMODES
			tay
			tax
			lda	:modes1 ,x
			cmp	UCI_DATA_MSG +9
			bne	ULIB_BAD_IMAGE		; => Ungültig...
			lda	:modes2 ,x
			cmp	UCI_DATA_MSG +10
			bne	ULIB_BAD_IMAGE		; => Ungültig...

;			ldy	r7L
;			lda	driveType -8,x
;			and	#ST_DMODES
			tya
			asl
			asl
			tax

			ldy	#0			;Dateigröße überprüfen.
::1			lda	UCI_DATA_MSG,y
			cmp	tabDiskSize,x
			bne	ULIB_BAD_IMAGE		; => Ungültig...
			inx
			iny
			cpy	#4
			bcc	:1

::no_error		ldx	#NO_ERROR		;DiskImage is gültig.
::err			rts

;--- Laufwerksformate.
;Mögliche Formate von 0 bis 7
;Formate 0 und 5-7 = nicht definiert
::modes1		b ":678n:::"
::modes2		b ":411p:::"

;
; ULIB: DiskImage ungültig.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK
;Verändert: A,X,Y

:ULIB_BAD_IMAGE		ldy	#0			;Fehlertext setzen.
::1			lda	:errType,y
			sta	UCI_STATUS_MSG,y
			iny
			cpy	#:errTypeLen
			bcc	:1

			ldx	#INCOMPATIBLE		;DiskImage inkompatibel.
			rts

;--- Fehlermeldung.
::errType		b "FF,WRONG DISK FORMAT",NULL
::errTypeEnd
::errTypeLen		= :errTypeEnd - :errType
