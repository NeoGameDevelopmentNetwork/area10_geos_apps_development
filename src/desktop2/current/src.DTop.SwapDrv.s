; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerke tauschen.
:keybSwapDrvAC		lda	#8
			b $2c
:keybSwapDrvBC		lda	#9
			ldx	driveType +2
			beq	:exit			; => Kein Lfwk. C...

			bit	sysRAMFlg		;REU verfügbar?
			bvc	:exit			; => Nein, Ende...

			pha				;Auswahl aufheben.
			jsr	unselectIcons
			pla
			sta	r10L			;Quell-Laufwerk.
			jsr	setNewDevice

;--- Hinweis:
;Bei einem Laufdwerk D: kann das
;Laufwerk nicht mehr getauscht werden!
			lda	driveType +3
			bne	:exit			; => Lfwk. D, Ende...

;--- Laufwerk 8/9 nach 11, 10 nach 8/9.
			lda	#11
			jsr	:swapCurDrive
			lda	#10
			jsr	setNewDevice
			lda	r10L
			jsr	:swapCurDrive

;--- Laufwerk 11 nach 10.
			lda	#11
			jsr	setNewDevice
			lda	#10
			jsr	:swapCurDrive

;--- Laufwerk 8/9 wieder öffnen.
			lda	r10L
			jsr	setNewDevice

;--- RBoot aktualisieren, Neustart.
			jsr	updateRBootData
			jmp	MainInit

::exit			rts

;--- Laufwerk auf neue Adresse ändern.
::swapCurDrive		pha
			tay

			lda	tabREUAdrDrvL -8,y
			sta	r1L
			lda	tabREUAdrDrvH -8,y
			sta	r1H

			lda	#> DISK_BASE
			sta	r0H
			lda	#< DISK_BASE
			sta	r0L

			lda	#> DISK_SIZE
			sta	r2H
			lda	#< DISK_SIZE
			sta	r2L

			lda	#$00			;Speicherbank
			sta	r3L			;immer #0.

			jsr	StashRAM		;Update REU-RBoot.

			pla
			sta	r0L

			lda	curDrive
			pha
			tay
			lda	ramBase -8,y
			pha
			lda	driveType -8,y
			pha
			bpl	:1

			lda	r0L			;Laufwerk aktivieren.
			jsr	setNewDevice
			clv
			bvc	:2

::1			lda	r0L			;Neue Geräteadresse.
			jsr	ChangeDiskDevice

::2			ldy	curDrive
			pla
			sta	driveType -8,y
			pla
			sta	ramBase -8,y

			pla
			tay
			lda	#$00
			sta	ramBase -8,y
			sta	driveType -8,y
			rts

;*** Zeiger auf Laufwerkstreiber in REU.
:tabREUAdrDrvL		b < $8300  ;Laufwerk A:
			b < $9080  ;Laufwerk B:
			b < $9e00  ;Laufwerk C:
			b < $ab80  ;Laufwerk D:
:tabREUAdrDrvH		b > $8300
			b > $9080
			b > $9e00
			b > $ab80
