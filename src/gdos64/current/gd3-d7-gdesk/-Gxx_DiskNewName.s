; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Verwendung in:
;* G60 = Disk-Info.
;* G62 = Disk formatieren.
;* G63 = Disk kopieren.

;*** Diskname aktualisieren.
;Übergabe: r10 = Diskname.
:saveDiskName		ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.

			ldy	#< OpenDisk		;C=15x1: Diskette öffnen.
			ldx	#> OpenDisk

			and	#SET_MODE_SUBDIR	;Native-Mode?
			beq	:open			; => Nein, weiter...

			ldy	#< OpenRootDir		;Native: ROOT-Verzeichnis öffnen.
			ldx	#> OpenRootDir

::open			tya
			jsr	CallRoutine		;Disk öffnen / BAM einlesen.
			txa				;Fehler?
			bne	:5			; => Ja, Abbruch...

			ldy	#0			;Disk-Name in BAM kopieren.
::1			lda	(r10L),y		;Name innerhalb GEOS immer an
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
