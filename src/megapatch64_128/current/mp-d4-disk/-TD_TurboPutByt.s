; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Bytes über ser. Bus / TurboDOS senden.
;    Übergabe:		d0L,d0H = Zeiger auf Datenspeicher.
;			yReg    = Anzahl Bytes (0=256 Bytes).
:Turbo_PutInitByt	jsr	waitDataIn_HIGH		;DATA_OUT, CLOCK_OUT, ATN-Signal
							;löschen, warten auf DATA_IN = LOW.

			tya				;Anzal Bytes in AKKU übertragen und
			pha				;zwischenspeichern.
			ldy	#$00			;Anzahl folgender Bytes an TurboDOS
			jsr	Turbo_SendByte		;in Floppy-RAM senden.
			pla
			tay				;Anzahl Bytes zurücksetzen.

;*** Bytes an Floppy senden.
;    Übergabe:		d0L,d0H = Zeiger auf Daten.
;			yReg    = Anzahl Bytes.
:Turbo_PutBytes		jsr	waitDataIn_HIGH
:Turbo_PutNxByte	dey				;Zeiger auf Daten korrigieren.
			lda	(d0L),y			;Byte einlesen.

			ldx	d2L			;TurboDOS-Übertragung starten.
			stx	$dd00

;*** Byte an Floppy senden.
:Turbo_SendByte		tax				;LOW-Nibble für Übertragung
			and	#%00001111		;berechnen und speichern.
			sta	d1L

::51			sec
			lda	$d012			;Warten bis der VIC den oberen
			sbc	#$31			;Bildrand aufbaut.
			bcc	:52
			and	#$06
			beq	:51

::52			txa

			ldx	d2H			;Startzeichen an TurboRoutine in
			stx	$dd00			;FloppyRAM übergeben.

			and	#%11110000		;HIGH-Nibble für Übertragung
			ora	d2L			;berechnen.
			sta	$dd00			;Bit #5 und #4 senden.
			ror
			ror
			and	#%11110000
			ora	d2L
			sta	$dd00			;Bit #7 und Bit #6 senden.

			ldx	d1L			;LOW-Nibble senden.
			lda	NibbleByteH,x
			ora	d2L
			sta	$dd00
			ror
			ror
			and	#%11110000
			ora	d2L
			cpy	#$00
			sta	$dd00
			bne	Turbo_PutNxByte

			nop				;Verzögerung???
			nop

			jmp	setClkOut_HIGH
endif

;******************************************************************************
::tmp1a = C_71!C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!IEC_NM!S2I_NM
::tmp1b = HD_41!HD_71!HD_81!HD_NM
::tmp1  = :tmp1a!:tmp1b
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Bytes über ser. Bus / TurboDOS senden.
;    Übergabe:		d0L,d0H = Zeiger auf Datenspeicher.
;			yReg    = Anzahl Bytes (0=256 Bytes).
:Turbo_PutInitByt	jsr	waitDataIn_HIGH		;DATA_OUT, CLOCK_OUT, ATN-Signal
							;löschen, warten auf DATA_IN = LOW.

			tya				;Anzal Bytes in AKKU übertragen und
			pha				;zwischenspeichern.
			ldy	#$00			;Anzahl folgender Bytes an TurboDOS
			jsr	Turbo_SendByte		;in Floppy-RAM senden.
			pla
			tay				;Anzahl Bytes zurücksetzen.

;*** Bytes an Floppy senden.
;    Übergabe:		d0L,d0H = Zeiger auf Daten.
;			yReg    = Anzahl Bytes.
:Turbo_PutBytes		jsr	waitDataIn_HIGH
:Turbo_PutNxByte	dey				;Zeiger auf Daten korrigieren.
			lda	(d0L),y			;Byte einlesen.

			ldx	d2L			;TurboDOS-Übertragung starten.
			stx	$dd00

;*** Byte an Floppy senden.
:Turbo_SendByte		tax				;LOW-Nibble für Übertragung
			and	#%00001111		;berechnen und speichern.
			sta	d1L

::51			sec
			lda	$d012			;Warten bis der VIC den oberen
			sbc	#$31			;Bildrand aufbaut.
			bcc	:52
			and	#$06
			beq	:51

::52			txa

			ldx	d2H			;Startzeichen an TurboRoutine in
			stx	$dd00			;FloppyRAM übergeben.

			and	#%11110000		;HIGH-Nibble für Übertragung
			ora	d2L			;berechnen.
			sta	$dd00			;Bit #5 und #4 senden.
			ror
			ror
			and	#%11110000
			ora	d2L
			sta	$dd00			;Bit #7 und Bit #6 senden.

			ldx	d1L			;LOW-Nibble senden.
			lda	NibbleByteH,x
			sta	$dd00
			lda	NibbleByteL,x
			cpy	#$00
			sta	$dd00
			bne	Turbo_PutNxByte

			jmp	setClkOut_HIGH
endif

;******************************************************************************
::tmp2 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Bytes über ser. Bus / TurboDOS senden.
;    Übergabe:		d0L,d0H = Zeiger auf Datenspeicher.
;			yReg    = Anzahl Bytes (0=256 Bytes).
;*** Daten über HD-Kabel senden.
:Turbo_PutBytes		jsr	HD_MODE_RECEIVE

			jsr	waitDataIn_HIGH

::0			dey				;Datenbyte einlesen und über
			lda	(d0L),y			;HD-Kabel senden.
			sta	$df40

			jsr	waitDataIn_LOW

			tya				;Alle Bytes gesendet?
			beq	:1			; => Ja, Ende...

			dey				;Datenbyte einlesen und über
			lda	(d0L),y			;HD-Kabel senden.
			sta	$df40

			jsr	waitDataIn_HIGH

			tya				;Alle Bytes gesendet?
			bne	:0			; => Nein, weiter...

			jsr	waitDataIn_LOW

::1			rts
endif
