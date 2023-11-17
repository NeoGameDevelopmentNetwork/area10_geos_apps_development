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

			ldy	DrvAdrGEOS
			lda	DrvMode
			cmp	#Drv81DOS
			beq	:1581

::cmd_fd		lda	devInfo -8,y
			and	#DrvCMD
			cmp	#DrvFD			;CMD-FD-Laufwerk ?
			beq	:found			;Laufwerk gefunden => Ja, weiter...
			bne	:find_drive		; => Nein, Laufwerk suchen.

::1581			lda	devInfo -8,y
			and	#%01000000		;Bit#6 = SD2IEC .
			cmp	#Drv1581		;1581-Laufwerk ?
			beq	:found			;Laufwerk gefunden => Ja, weiter...

::find_drive		jsr	xGetAllSerDrives	;Laufwerke am ser.Bus suchen.

			lda	DrvMode			;1581/CMD-FD-Laufwerk.
			ldy	DrvAdrGEOS
			jsr	FindDriveType		;Freies Laufwerk suchen.

			cpx	#NO_ERROR		;Laufwerk gefunden ?
			bne	:next			; => Nein, weitersuchen.

			ldy	DrvAdrGEOS
			lda	devInfo -8,y		;Bei DOS81: Auf SD2IEC testen.
			and	#%01000000		;SD2IEC-Laufwerk ?
			beq	:found			; => Nein, weiter...

::next			lda	DrvAdrGEOS
			jsr	TurnOnNewDrive		;Dialogbox ausgeben.
			txa				;Laufwerk eingeschaltet ?
			beq	:find_drive		; => Ja, Laufwerk suchen...
			bne	:error			; => Nein, Abbruch...

::found			ldx	#NO_ERROR
::error			rts				;Ende.
