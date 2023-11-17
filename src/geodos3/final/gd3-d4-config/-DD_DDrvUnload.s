; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk de-installieren.
;Übergabe: XREG = GEOS-Laufwerk #8-#11
;Rückgabe: XReg = Fehlermeldung.
:DskDev_Unload		stx	:tmpdrive
			lda	driveType   -8,x	;RAM-/Shadow-/PCDOS-Laufwerk ?
			cmp	#DrvPCDOS		;PCDOS-Laufwerk ?
			beq	:pcdos			; => Ja, weiter...
			and	#%11000000		;Bit$7=RAM, Bit%6=Shadow
			beq	:done			; => Nein, Ende...

			lda	RealDrvType -8,x
			and	#DrvCMD			;CMD-RAMLink ?
			bne	:done			; => Ja, Ende...

			lda	RealDrvMode -8,x
			and	#SET_MODE_SRAM		;CMD-SuperCPU/RAMCard ?
			bne	:sram			; => Ja, SuperRAM-Laufwerk...

			lda	ramBase     -8,x	;GEOS-DACC reserviert ?
			bne	:ram			; => Ja, RAM-/Shadow-Laufwerk...

::done			ldx	#NO_ERROR		;Kein GEOS-DACC belegt, Ende.
			rts

;--- SuperCPU/RAMCard.
::sram			php				;IRQ sperren.
			sei

			ldy	CPU_DATA		;I/O-Bereich aktivieren.
			lda	#IO_IN
			sta	CPU_DATA

			sta	SCPU_HW_EN		;SuperCPU-Register aktivieren.
;			ldx	:tmpdrive
			lda	ramBase     -8,x	;Erste Speicherbank.
			sta	SRAM_FIRST_BANK		;Freien Speicher zurücksetzen.
			sta	SCPU_HW_DIS		;SuperCPU-Register abschalten.

			sty	CPU_DATA		;I/O-Bereich ausblenden.

			plp				;IRQ-Status zurücksetzen.

			clc
			bcc	:done

;--- PCDOS.
::pcdos			ldy	#1			; => 1x64k
			bne	:disable

;--- RAM41/71/81/NM
::ram			lda	driveType   -8,x	;Anzahl 64K Bänke ermitteln.
			and	#%00000111

::41			cmp	#Drv1541		;RAM1541 / Shadow-1541
			bne	:71
			ldy	#3			; => 3x64k
			bne	:disable

::71			cmp	#Drv1571		;RAM1571
			bne	:81
			ldy	#6			; => 6x64k
			bne	:disable

::81			cmp	#Drv1581		;RAM1581
			bne	:NM
			ldy	#13			; => 13x64k
			bne	:disable

::NM			lda	:tmpdrive		;RAMNative
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Laufwerk initialisieren.

			inx				;Zeiger auf Spur $01/02 setzen
			stx	r1L			;und BAM-Sektor mit Laufwerks-
			inx				;größe einlesen.
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler?
			bne	:exit			;Ja, Speicher kann nicht ermittelt
							;werden => Speicher kann nicht
							;mehr freigegeben werden.
			ldy	diskBlkBuf  +8		;Größe NativeRAM-Laufwerk.

;--- RAM freiegeben, Anzahl im yReg!
::disable		ldx	:tmpdrive
			lda	driveType   -8,x
			and	#%11111000
			cmp	#%01000000		;ShadowRAM-Laufwerk?
			bne	:no_shadow

			lda	driveType   -8,x	;Shadow-Bit löschen.
			and	#%10111111
			sta	driveType   -8,x

::no_shadow		lda	ramBase     -8,x	;Ist GEOS-DACC reserviert ?
			beq	:ok			; => Nein, weiter...
			jsr	FreeBankTab		;RAM-Speicher wieder freigeben.
			b $2c
::ok			ldx	#NO_ERROR
::exit			rts

::tmpdrive		b $00
