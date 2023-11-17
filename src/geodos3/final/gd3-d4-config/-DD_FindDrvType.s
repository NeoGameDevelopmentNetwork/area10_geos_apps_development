; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Suche nach Laufwerkstyp starten.
;    Übergabe:		AKKU =	Laufwerkstyp.
;				Bei CMD-Geräten muß Bit %0-%3 = NULL sein!
;			yReg =	Laufwerksadresse #8 bis #11.
;				(Geräteadresse wird automatisch umgestellt).
:FindDriveType		sty	r15L
			sta	r15H

;--- Laufwerkstyp erkennen. ($01,$02,$03... $10,$20,$30....)
::51			lda	#$08			;Zeiger auf Laufwerk #8.
::52			sta	r14L
			tax
			lda	devGEOS -8,x
			bne	:57
			lda	devInfo -8,x
			and	#%10111111		;SD2IEC-Flag löschen.
			beq	:57
			cmp	r15H			;Laufwerkstyp gefunden ?
			bne	:57			; => Nein, weiter...

;--- Geräteadresse festlegen.
::54			jsr	SetDiskDrvAdr		;Geräteadresse umstellen.

;			ldx	#NO_ERROR		;Fehler bereits im XReg...
			rts

;--- Nächstes Laufwerk.
::57			ldx	r14L			;Zeiger auf nächstes Laufwerk.
			inx
			txa
			cmp	#29 +1			;Alle Laufwerksadresse durchsucht ?
			bcc	:52			; => Nein, weiter...

			ldx	#DEV_NOT_FOUND
			rts
