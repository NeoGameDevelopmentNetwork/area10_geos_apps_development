; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskname aktualisieren.
:saveDiskName		jsr	OpenDisk		;Disk öffnen / BAM einlesen.
			txa				;Fehler?
			bne	:5			; => Ja, Abbruch...

			ldy	#0			;Disk-Name in BAM kopieren.
::1			lda	targetDrvDisk,y		;Name innerhalb GEOS immer an
			beq	:2			;Position $90 für Kompatibilität
			sta	curDirHead +$90,y	;mit 1541-Modus.
			iny
			cpy	#16			;Max. 16 Zeichen für Name kopiert?
			bcc	:1			; => Nein, weiter...
			bcs	:4			; => Ja, Ende...

::2			lda	#$a0			;Disk-Name mit $A0 auffüllen.
::3			sta	curDirHead +$90,y
			iny
			cpy	#16
			bcc	:3

::4			jsr	PutDirHead		;BAM auf Disk speichern.
			txa				;Fehler?
			bne	:5			; => Ja, Abbruch...

			jsr	OpenDisk		;BAM im Speicher aktualisieren.
;			txa				;Erforderlich für internen Cache
;			bne	:5			;des 1581-Treibers.

::5			rts
