; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk A/B wechseln.
.swapCurDrive		lda	curDrive
			eor	#$01

;*** Neues Laufwerk setzen.
;Übergabe: Akku = Laufwerksadresse.
.setNewDevice		pha
			jsr	SetDevice
			pla

			cmp	#8			;Laufwerk?
			bcc	:1			; => Nein, weiter...

;--- Hinweis:
;Diese Routine wechselt ggf. auch den
;Laufwerkstreiber, der ggf. im RAM
;zwischengespeichert wird. Ohne REU
;ist sonst nur ein Laufwerk möglich.
			cmp	bufDskDrvAdr
			beq	:1			; => Anderes Lfwk.
			sta	bufDskDrvAdr

			lda	flagDriverReady
			beq	:1			; => Kein Treiber.

			jsr	swapDiskDriver

::1			ldy	curDrive
			lda	driveType -8,y
			sta	curType

			ldx	#NO_ERROR
			rts

;*** Laufwerk setzen / Diskette öffnen.
;Übergabe: Akku = Laufwerksadresse.
:setDevOpenDisk		jsr	setNewDevice
			jmp	OpenDisk

;*** Laufwerkstreiber wechseln.
;Dabei wird der Treiber im RAM von
;DeskTopß mit dem Systemtreiber von
;GEOS ab ":DISK_BASE" getauscht.
:swapDiskDriver		jsr	swapTmpDrvData
			jsr	swapBufDskDrv

;*** Zeiger für zweiten Laufwerkstreiber setzen.
:swapTmpDrvData		ldy	#6 -1
::1			lda	r0,y
			tax
			lda	:tmpdrv,y
			sta	r0,y
			txa
			sta	:tmpdrv,y
			dey
			bpl	:1
			rts

::tmpdrv		w DISK_BASE
			w bufDiskDriver
			w DISK_SIZE

;*** Systemtreiber mit Zwischenspeicher tauschen.
:swapBufDskDrv		lda	r0H			;Register auf
			pha				;Stack retten.
			lda	r1H
			pha
			lda	r2H
			pha

			ldy	#$00
::1			lda	r2H			;Seiten kopiert?
			beq	:3			; => Ja, weiter...

::2			lda	(r0L),y			;13 x 256 Bytes
			tax				;tauschen.
			lda	(r1L),y			;Entspricht $0D00
			sta	(r0L),y			;Bytes, ein Treiber
			txa				;hat $0D80 Bytes.
			sta	(r1L),y
			iny
			bne	:2
			inc	r0H			;Zeiger auf nächste
			inc	r1H			;Seite setzen.
			dec	r2H			;Seitenzähler -1.
			clv
			bvc	:1

::3			cpy	r2L			;Restbytes getauscht?
			beq	:4			; => Ja, Ende...

			lda	(r0L),y			;$0080 = Rest von
			tax				;$0D80 tauschen.
			lda	(r1L),y
			sta	(r0L),y
			txa
			sta	(r1L),y
			iny
			bne	:3

::4			pla				;Register wieder
			sta	r2H			;zurücksetzen.
			pla
			sta	r1H
			pla
			sta	r0H
			rts
