; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;Reference: "Serial bus control codes"
;https://codebase64.org/doku.php?id=base:how_the_vic_64_serial_bus_works
;$20-$3E : LISTEN  , device number ($20 + device number #0-30)
;$3F     : UNLISTEN, all devices
;$40-$5E : TALK    , device number ($40 + device number #0-30)
;$5F     : UNTALK  , all devices
;$60-$6F : REOPEN  , channel ($60 + secondary address / channel #0-15)
;$E0-$EF : CLOSE   , channel ($E0 + secondary address / channel #0-15)
;$F0-$FF : OPEN    , channel ($F0 + secondary address / channel #0-15)

;*** Geräteadresse swappen.
;Übergabe: YReg = Neue Geräteadresse.
;          XReg = Alte Geräteadresse.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:SwapDiskDevAdr		lda	devInfo -8,x		;Laufwerkstyp zwischenspeichern.
			pha
			lda	#$00			;GEOS-Laufwerksstatus in jedem
			sta	devGEOS -8,x		;Fall löschen. Wird nach der
			sta	devGEOS -8,y		;Installation neu gesetzt.
			sta	devInfo -8,x
			pla
			sta	devInfo -8,y		;Laufwerkstyp zurücksetzen.

if FALSE
			cmp	#Drv1541
			beq	:swapDskAdrMW
			cmp	#DrvShadow1541
			beq	:swapDskAdrMW
			cmp	#Drv1571
			bne	:swapDskAdrU0
endif

;--- Geräteadresse ändern.
;Nur für 1541/1571.
::swapDskAdrMW		tya
			ora	#%00100000
			sta	:com_DevAdr1		;Ziel-Adresse #1 berechnen.
			eor	#%01100000
			sta	:com_DevAdr2		;Ziel-Adresse #2 berechnen.

			tya				;Neue Laufwerksadresse
			pha				;zwischenspeichern.
			stx	curDevice

			ldx	#> :com_SwapAdr
			lda	#< :com_SwapAdr
			ldy	#8
			jsr	SendComVLen		;Geräteadresse ändern.
			jsr	UNLSN			;Laufwerk abschalten.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

			rts

;Befehl zum wechseln der Geräteadresse.
::com_SwapAdr		b "M-W",$77,$00,$02
::com_DevAdr1		b $00
::com_DevAdr2		b $00

if FALSE
;--- Geräteadresse ändern.
;Nur für 1581/CMD/SD2IEC.
::swapDskAdrU0		sty	:com_SwapAdrU0 +3	;Neue Adresse merken.

			lda	curDevice		;Aktuelle Laufwerksadresse
			pha				;zwischenspeichern.
			stx	curDevice

			ldx	#> :com_SwapAdrU0
			lda	#< :com_SwapAdrU0
			ldy	#4
			jsr	SendComVLen		;Geräteadresse ändern.
			jsr	UNLSN			;Laufwerk abschalten.

			pla
			sta	xcurDevice		;Aktuelles Laufwerk zurücksetzen.

			rts

;Befehl zum wechseln der Geräteadresse.
::com_SwapAdrU0		b "U0",$3e,$08
endif
