; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: Disk-Größe NativeMode einlesen
;
;Übergabe : r7L = GEOS-Laufwerk 8 bis 11
;Rückgabe : X   = Fehlerstatus, $00=OK
;                 sizeNative = Größe Laufwerk in Bytes
;                              NULL: Nicht definiert
;Verändert: A,X,Y,r1,r4 und r0/r2/r3 durch OpenDisk

:ULIB_GETS_NATIVE	ldx	r7L
			lda	driveType -8,x
			and	#ST_DMODES
			cmp	#DrvNative		;Ziel-Laufwerk = NativeMode?
			bne	:exit			; => Nein, Ende...

			txa
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	#$01			;Track 1/Sektor 2 enthält
			sta	r1L			;Anzahl Tracks im Laufwerk.
			lda	#$02
			sta	r1H

			lda	#< UCI_DATA_MSG
			sta	r4L
			lda	#> UCI_DATA_MSG
			sta	r4H

			jsr	GetBlock		;Block einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	UCI_DATA_MSG +8		;Offset +8 enthält Anzahl Tracks.
			tay
			ldx	curDrive
			clc
			adc	ramBase -8,x		;Startadresse Laufwerk addieren.
			bcs	:err_image		; => Fehler, Abbruch...

			sty	sizeNative +2		;Größe Laufwerk speichern.

::exit			ldx	#NO_ERROR
			rts

::err_image		ldx	#INCOMPATIBLE
::err			rts
