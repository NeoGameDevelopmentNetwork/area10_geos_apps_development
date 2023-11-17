; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungtabelle RAM-Funktionen.
;    Übergabe:		r0	= Startadresse C128-RAM.
;			r1	= Startadresse REU.
;			r2	= Anzahl Bytes.
;			r3L	= Speicherbank.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:DoRAMOp_SRAM		cpy	#%10010000		;StashRAM ?
			bne	:51			; => Nein, weiter...
			jsr	SCPU_STASH_RAM		;StashRAM für SCPU ausführen.
			jmp	:54

::51			cpy	#%10010001		;FetchRAM ?
			bne	:52			; => Nein, weiter...
			jsr	SCPU_FETCH_RAM		;FetchRAM für SCPU ausführen.
			jmp	:54

::52			cpy	#%10010010		;SwapRAM ?
			bne	:53			; => Nein, weiter...
			jsr	SCPU_SWAP_RAM		;SwapRAM für SCPU ausführen.
			jmp	:54

::53			cpy	#%10010011		;SwapRAM ?
			bne	:54			; => Nein, weiter...
			jsr	SCPU_VERIFY_RAM		;SwapRAM für SCPU ausführen.
			txa				;Verify-Error ?
			beq	:54			; => Nein, weiter...

			ldx	#%00100000
			b $2c
::54			ldx	#%01000000		;Kein Fehler...
			txa
			ldx	#NO_ERROR
			rts

;*** Speicherbank berechnen.
;Der GEOS-DACC beginnt ab der ersten freien Speicherbank in der RAMCard.
;Das muss nicht unbedingt Bank#0 sein!
;Bank#0/#1 sind SuperCPU-System-RAM, auch wenn keine RAMCard installiert ist.
;Ab Bank#2 beginnt der freie Speicher, dieser kann aber zuvor durch andere
;Anwendungen eingeschränkt worden sein.
;Beim Systemstart wird in RamBankFirst die erste freie Speicherbank abgelegt.
:DefBankAdr		lda	RamBankFirst +1		;Speicherbank berechnen.
			clc
			adc	r3L
			rts
