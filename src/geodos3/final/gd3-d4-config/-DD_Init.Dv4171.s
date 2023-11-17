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
:InitDiskDrive		lda	#$00			;1541/1571-Modus zurücksetzen.
			sta	drvMode_4171

			jsr	PurgeTurbo		;TurboDOS abschalten.
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
			and	#DrvCMD			;CMD-Laufwerk ?
			beq	:no_cmd			; => Nein, weiter...

::cmd_drive		lda	devInfo -8,y
			eor	DrvMode
			and	#%11111000		;Format-Bits löschen.
			beq	:found			;Laufwerk gefunden => Ja, weiter...
			bne	:find_drive		; => Nein, Laufwerk suchen.

::no_cmd		lda	devInfo -8,y
			and	#%01000000		;SD2IEC-Laufwerk ?
			bne	:found			; => Ja, weiter...
::no_sd2iec		lda	devInfo -8,y
			eor	DrvMode
			and	#%10111111		;SD2IEC-Flag/Shadow-Bit löschen.
			beq	:found			;Laufwerk gefunden => Ja, weiter...

			lda	DrvMode			;Sonderbehandlung für 1541:
			and	#%10111111		;Auch eine echte 1571 akzeptieren,
			cmp	#Drv1541		;da dieses Laufwerk auch als 1541
			bne	:find_drive		;genutzt werden kann.
			lda	devInfo -8,y
			cmp	#Drv1571
			beq	:found

::find_drive		jsr	xGetAllSerDrives	;Laufwerke am ser.Bus suchen.

			lda	DrvMode
			ldy	DrvAdrGEOS
			jsr	FindDriveType		;Freies Laufwerk suchen.

			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:found			; => Ja, weiter...

			lda	DrvMode
			and	#%10111111
			cmp	#Drv1541
			bne	:no_1541

			lda	#Drv1571
			ldy	DrvAdrGEOS
			jsr	FindDriveType		;Freies Laufwerk suchen.

			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:found_1571		; => Ja, weiter...

::no_1541		lda	DrvAdrGEOS
			jsr	TurnOnNewDrive		;Dialogbox ausgeben.
			txa				;Laufwerk eingeschaltet ?
			beq	:find_drive		; => Ja, Laufwerk suchen...
			bne	:error			; => Nein, Abbruch...

::found_1571		dec	drvMode_4171

::found			ldy	DrvAdrGEOS		;SD2IEC-Modus definieren.
			lda	devInfo -8,y
			and	#%01000000
			beq	:set_sd2iec
			lda	DrvMode
			ora	#%01000000
			sta	devInfo -8,y
			lda	#$ff
::set_sd2iec		sta	drvMode_SD2IEC

;			ldx	#NO_ERROR
::error			rts
