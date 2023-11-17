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
;*** Bytes über ser. Bus / TurboDOS einlesen.
;    Übergabe:		d0L/d0H  , Zeiger auf Bytespeicher.
;			yReg     , Anzahl Bytes.
:Turbo_GetBytes		jsr	waitDataIn_HIGH		;Warten bis TurboDOS bereit.

			pha				;Verzögerung???
			pla
			pha
			pla

			sty	d1L			;Anzahl Bytes speichern.

:Turbo_GetNxByte	sec
::51			lda	$d012			;Warten bis der VIC den oberen
			sbc	#$31			;Bildrand aufbaut.
			bcc	:52
			and	#$06
			beq	:51

::52			lda	d2H			;CLOCK_OUT auf HIGH setzen.
			sta	$dd00

			lda	d0L			;Verzögerung???

			lda	d2L			;CLOCK_OUT zurück auf LOW.
			sta	$dd00

			dec	d1L			;Byte-Zähler -1.

			nop				;Verzögerung???
			nop
			nop

			lda	$dd00			;Byte über TurboDOS einlesen und
			lsr				;Low/High-Nibble berechnen.
			lsr
			nop				;Verzögerung???
			ora	$dd00
			lsr
			lsr
			lsr
			lsr
			ldy	$dd00
			tax
			tya
			lsr
			lsr
			ora	$dd00
			and	#%11110000
			ora	NibbleByteL,x

			ldy	d1L			;Zeiger auf Byte-Speicher lesen.
			sta	(d0L),y			;Byte in Floppy-Speicher schreiben.
			bne	Turbo_GetNxByte		;Alle Bytes gelsen ? Nein, weiter...

			jmp	setClkOut_HIGH		;TurboDOS abschalten.
endif

;******************************************************************************
::tmp1 = C_71
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Bytes über ser. Bus / TurboDOS einlesen.
;    Übergabe:		d0L/d0H  , Zeiger auf Bytespeicher.
;			yReg     , Anzahl Bytes.
:Turbo_GetBytes		lda	r0L			;Register ":r0L" zwischenspeichern.
			pha
			jsr	waitDataIn_HIGH		;Warten bis TurboDOS bereit.
			sty	r0L			;Anzahl Bytes zwischenspeichern.

:Turbo_GetNxByte	sec
::51			lda	$d012			;Warten bis der VIC den oberen
			sbc	#$31			;Bildrand aufbaut.
			bcc	:52
			and	#$06
			beq	:51

::52			lda	d2H			;CLOCK_OUT auf HIGH setzen.
			sta	$dd00
			lda	d2L			;CLOCK_OUT zurück auf LOW.
			sta	$dd00

			dec	r0L			;Byte-Zähler -1.

			lda	$dd00			;High/Low-Nibble einlesen und
			lsr				;Byte-Wert berechnen.
			lsr
			nop				;Verzögerung???
			ora	$dd00
			lsr
			lsr
			lsr
			lsr
			ldy	$dd00
			tax
			tya
			lsr
			lsr
			ora	$dd00
			and	#%11110000
			ora	DefNibbleData,x

			ldy	r0L			;Zeiger auf Byte-Speicher lesen.
:Def_AssCode1		sta	(d0L),y			;Byte speichern. ACHTUNG! Diese
			ora	d1L			;Befehle werden modifiziert!
:Def_AssCode2		ora	d1L
			tya				;Alle Bytes eingelesen ?
			bne	Turbo_GetNxByte		;Nein, weiter...

			jsr	setClkOut_HIGH

			pla				;Register ":r0L" zurücksetzen.
			sta	r0L
			lda	(d0L),y			;Erstes Byte aus Speicher in AKKU.
			rts				;Ende.
endif

;******************************************************************************
::tmp2a = C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!HD_41!HD_71!HD_81!HD_NM
::tmp2b = IEC_NM!S2I_NM
::tmp2 = :tmp2a!:tmp2b
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Bytes über ser. Bus / TurboDOS einlesen.
;    Übergabe:		d0L/d0H  , Zeiger auf Bytespeicher.
;			yReg     , Anzahl Bytes.
:Turbo_GetBytes		jsr	waitDataIn_HIGH		;Warten bis TurboDOS bereit.

:Turbo_GetNxByte	sec
::51			lda	$d012			;Warten bis der VIC den oberen
			sbc	#$32			;Bildrand aufbaut.
			and	#$07
			beq	:51

			lda	d2H			;CLOCK_OUT auf HIGH setzen.
			sta	$dd00
			and	#%00001111		;CLOCK_OUT zurück auf LOW.
			sta	$dd00

			lda	$dd00			;High/Low-Nibble einlesen und
			lsr				;Byte-Wert berechnen.
			lsr
			ora	$dd00
			lsr
			lsr
			eor	d2L
			eor	$dd00
			lsr
			lsr
			eor	d2L
			eor	$dd00

			dey				;Zeiger auf Byte-Speicher lesen.
			sta	(d0L),y			;Byte in Floppy-Speicher schreiben.
			bne	Turbo_GetNxByte		;Alle Bytes gelsen ? Nein, weiter...

			jmp	setClkOut_HIGH		;TurboDOS abschalten.
endif

;******************************************************************************
::tmp3 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp3!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Daten über HD-Kabel empfangen.
;    Übergabe:		d0L/d0H  , Zeiger auf Bytespeicher.
;			yReg     , Zeiger auf erstes Byte.
:Turbo_GetBytes		jsr	HD_MODE_SEND

			jsr	waitDataIn_HIGH

::0			jsr	waitDataIn_LOW

			lda	$df40			;Byte über HD-Kabel einlesen und
			dey				;zwischenspeichern.
			sta	(d0L),y

			jsr	waitDataIn_HIGH

			tya				;Alle Bytes eingelesen ?
			beq	:1			; => Ja, Ende...

			lda	$df40			;Byte über HD-Kabel einlesen und
			dey				;zwischenspeichern.
			sta	(d0L),y
			bne	:0

::1			jsr	waitDataIn_LOW

			rts
endif
