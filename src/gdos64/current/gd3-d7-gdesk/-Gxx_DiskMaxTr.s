; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Verwendung in:
;* G60 = Disk Info.
;* G62 = Disk löschen.
;* G63 = Disk kopieren.

;*** Max. Anzahl Tracks einlesen.
:getMaxTracks		lda	curType			;Max. Anzahl Tracks einlesen.
			and	#ST_DMODES		;Laufwerkstyp isolieren.

			ldx	#35			;1541=35 Tracks.
			cmp	#Drv1541 +1		;1541?
			bcc	:0			; => Ja, weiter...

			ldx	#70			;1571=70 Tracks.
			cmp	#Drv1571		;1571?
			bne	:6			; => Nein, weiter...

			ldy	curDrive		;Disk Doppelseitig?
			lda	doubleSideFlg -8,y
			bmi	:0			; => Ja, weiter...
			ldx	#35			;1571/Einseitig=35 Tracks.
			bne	:0

::6			ldx	#80			;1581=80 Tracks.
			cmp	#Drv1581		;1571?
			beq	:0			; => Ja, weiter...

			ldx	dir2Head +8		;NativeMode, Max. Tracks aus BAM.

::0			stx	maxTrack		;Max.Anzahl Tracks speichern.
			rts

;*** Variablen.
:maxTrack		b $00
