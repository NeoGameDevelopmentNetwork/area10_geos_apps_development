﻿; UTF-8 Byte Order Mark (BOM), do not remove!
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
:initTestDevice		jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	DrvAdrGEOS		;Ziel-Laufwerk testen.
			jsr	_DDC_DETECTDRV

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			txa				;Laufwerk erkannt?
			bne	:find_drive		; => Nein, Laufwerk suchen.

			ldy	DrvAdrGEOS
			lda	_DDC_DEVTYPE -8,y
			beq	:find_drive		; => Nein, weiter...

			ldx	#ILLEGAL_DEVICE
			cmp	#DrvVICEFS		;VICE/FS-Laufwerk ?
			beq	:error			; => Ja, Abbruch...

			and	#DrvCMD			;CMD-Laufwerk ?
			bne	:find_drive		; => Nein, weiter...

			ldx	#NO_ERROR
			lda	_DDC_DEVTYPE -8,y
			and	#%01000000		;SD2IEC-Laufwerk ?
			bne	:found			; => Ja, weiter...

::find_drive		jsr	_DDC_DETECTALL		;Laufwerke am ser.Bus suchen.

			lda	DrvMode
			ldy	DrvAdrGEOS
			jsr	_DDC_FINDDEVTYP		;Freies Laufwerk suchen.

			cpx	#NO_ERROR		;Laufwerk gefunden ?
			beq	:found			; => Ja, weiter...

			lda	DrvAdrGEOS
			jsr	_DDC_TURNONDEV		;Dialogbox ausgeben.
			txa				;Laufwerk eingeschaltet ?
			beq	:find_drive		; => Ja, Laufwerk suchen...
			bne	:error			; => Nein, Abbruch...

::found			ldy	DrvAdrGEOS		;turboFlags löschen, damit für das
			lda	#$00			;neue Laufwerk TurboDOS immer neu
			sta	turboFlags -8,y		;installiert werden muss.

			sta	driveData -8,y		;Zusätzlich Laufwerksdaten löschen.
			sta	drivePartData -8,y

;			ldy	DrvAdrGEOS
			lda	_DDC_DEVTYPE -8,y
			and	#%01000000
			beq	:set_sd2iec
			lda	#$ff
::set_sd2iec		sta	drvMode_SD2IEC

;			ldx	#NO_ERROR
::error			rts
