; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Mausabfrage installieren.
; Datum			: 19.07.97
; Aufruf		: jsr  InitMseTest
; Übergabe		: -AKKU,xRegWord Zeiger auf Bereichstabelle
;				 Ende mit $FF-Byte!
; Rückgabe		: -
; Verändert		: -AKKU
; Variablen		: -
; Routinen		: -
;******************************************************************************

;******************************************************************************
; Funktion		: Mausabfrage durchführen.
; Datum			: 19.07.97
; Aufruf		: jsr  TestMseArea
; Übergabe		: -AKKU,xRegWord Zeiger auf Bereichstabelle
;				 Ende mit $FF-Byte!
; Rückgabe		: -	 Einsprung in Anwender-Routine.
; Verändert		: -AKKU,xReg,yReg
;			  -r0,r2 bis r4
; Variablen		: -
; Routinen		: -IsMseInRegion									 Mausgrenzen überprüfen.
;******************************************************************************

;*** Mausabfrage installieren.
.InitMseTest		sta	:101 +1			;Zeiger auf Bereichstabelle speichern.
			stx	:101 +3

			lda	#<:101			;Mausabfrage installieren.
			sta	otherPressVec+0
			lda	#>:101
			sta	otherPressVec+1
			rts

::101			lda	#$ff
			ldx	#$ff
			jsr	TestMseArea
			rts

;*** Mausbereiche testen.
.TestMseArea		sei				;IRQ sperren.

			sta	r0L			;Zeiger auf Bereichstabelle speichern.
			stx	r0H

::101			jsr	:104			;Mausbereich einlesen.

			CmpBI	r2L,$ff			;Ende erreicht ?
			beq	:103			;Ja, Maus in keinem Bereich.

			jsr	IsMseInRegion		;Maus innerhalb Bereich ?
			tax
			beq	:102			;Nein, weiter...
			pla
			pla
			cli				;IRQ wieder freigeben.
			jmp	(r5)			;Ja, Anwender-Routine aufrufen.

::102			AddVBW	8,r0			;Zeiger auf nächsten Bereich.
			jmp	:101			;Weitertesten.

::103			cli				;IRQ wieder freigeben.
			rts				;Ja, Abbruch...

;*** Bereichsdaten einlesen.
::104			ldy	#$07
::105			lda	(r0L),y
			sta	 r2  ,y
			dey
			bpl	:105
			rts
