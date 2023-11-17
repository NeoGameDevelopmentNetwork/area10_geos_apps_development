; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk am ser.Bus initialisieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk am ser.Bus vorhanden.
:InitDiskDrive		jsr	PurgeTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich und Kernal einblenden.

			lda	DrvAdrGEOS		;Ziel-Laufwerk testen.
			jsr	DetectCurDrive

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			txa				;Laufwerk erkannt?
			bne	:find_drive		; => Nein, Laufwerk suchen.

			lda	DrvAdrGEOS		;TurboDOS abschalten.
			jsr	purgeAllDrvTurbo

			ldx	#NO_ERROR
			ldy	DrvAdrGEOS
			lda	devInfo -8,y
			and	#%01000000		;CMD-Laufwerk ?
			bne	:found			;Laufwerk gefunden => Ja, weiter...

::find_drive		jsr	xGetAllSerDrives	;Laufwerke am ser.Bus suchen.

			lda	DrvMode
			ldy	DrvAdrGEOS
			jsr	FindDriveType		;Freies Laufwerk suchen.

			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:found			; => Ja, weiter...

			lda	DrvAdrGEOS
			jsr	TurnOnNewDrive		;Dialogbox ausgeben.
			txa				;Laufwerk eingeschaltet ?
			beq	:find_drive		; => Ja, Laufwerk suchen...
			bne	:error			; => Nein, Abbruch...

::found			ldy	DrvAdrGEOS
			lda	devInfo -8,y
			and	#%01000000
			beq	:set_sd2iec
			lda	#$ff
::set_sd2iec		sta	drvMode_SD2IEC

;			ldx	#NO_ERROR
::error			rts
