; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** TurboDOS abschalten.
;    Übergabe: AKKU = Ziel-Laufwerk.
:purgeAllDrvTurbo	pha

			ldx	#8			;TurboDOS auf allen Laufwerken
::1			lda	driveType -8,x		;abschalten, da ggf. über die
			beq	:2			;Kernal-Routinen auf die Laufwerke
			lda	turboFlags -8,x		;zugegriffen wird.
			bpl	:2

			txa
			pha
			jsr	SetDevice
			jsr	PurgeTurbo
			pla
			tax

::2			inx
			cpx	#12
			bcc	:1

			pla
			tax
			lda	driveType -8,x		;Ziel-Laufwerk installiert ?
			beq	:3			; => Nein, weiter...
			txa
			jsr	SetDevice
			jmp	PurgeTurbo

::3			stx	curDevice		;Nur Laufwerksadresse setzen.
			stx	curDrive
			rts
