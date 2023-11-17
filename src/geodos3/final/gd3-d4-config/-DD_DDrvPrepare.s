; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerkstreiber vorbereiten.
;Übergabe: Akku = DrvMode    / Laufwerksmodus $01=1541, $33=RL81...
;          XReg = DrvAdrGEOS / GEOS-Laufwerk A-D/8-11.
;          DDRV_SYS_DEVDATA = Laufwerkstreiber.
;Rückgabe: -
:DskDev_Prepare		sta	:tmpDrvMode +1		;Laufwerksdaten zwischenspeichern.
			stx	:tmpDrvAdr  +1

			ldx	curDrive		;Vor dem wechseln des
			lda	turboFlags -8,x		;aktiven Laufwerks TurboDOS
			beq	:tmpDrvAdr		;testen und ggf. abschalten.
			jsr	PurgeTurbo

::tmpDrvAdr		ldx	#$ff			;Laufwerksdaten setzen.
			stx	curDevice
			stx	curDrive

::tmpDrvMode		lda	#$ff
			sta	RealDrvType -8,x
			sta	DDRV_SYS_DEVDATA + (diskDrvType - DISK_BASE)
			tay
;--- Hinweis:
;Nicht auf #DrvCMD testen, da auch ein
;ExtendedRAM-Drive installiert werden
;kann, was die Bits #5+#4 verwendet.
;			and	#DrvCMD			;Auf CMD-Laufwerk testen.
			and	#%11111000		;Modus-Bits isolieren.
			cmp	#DrvRAMLink		;CMD-RAMLink ?
			bne	:no_ramlink		; => Nein, weiter...
			tya
			ora	#%10000000		;RAM-Bit setzen.
			bne	:ram_drive		;Laufwerk = RAM-Laufwerk.

::no_ramlink		tya
			bmi	:ram_drive		;RAM-Laufwerk ? => Ja, weiter...

;--- Ergänzung: 28.08.21/M.Kanet
;Für 1541/Shadow muss hier das Shadow-
;Bit gelöscht werden, da der Speicher
;evtl. noch nicht reserviert ist.
::disk_drive		and	#%00000111		;Laufwerksformat isolieren.
			bne	:set_drive_type

::ram_drive		and	#%10000111		;RAM-Bit und Format isolieren.

::set_drive_type	sta	driveType   -8,x	;GEOS-Laufwerkstyp setzen.
			sta	curType

			lda	#$00			;RealDrvMode initialisieren.
			sta	RealDrvMode -8,x

;			lda	#$00			;TurboFlags initialisieren.
			sta	turboFlags  -8,x

;--- Treiber installieren.
			jsr	i_MoveData		;Laufwerkstreiber aktivieren.
			w	DDRV_SYS_DEVDATA
			w	DISK_BASE
			w	SIZE_DDRV_DATA

			rts
