; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Makros: Register/Arithmetik/Stack/Vergleiche.
;******************************************************************************

:LoadB			m
			lda	#§1
			sta	§0
			/

:LoadW			m
			lda	#>§1
			sta	§0 +1
			lda	#<§1
			sta	§0
			/

:MoveB			m
			lda	§0
			sta	§1
			/

:MoveW			m
			lda	§0
			sta	§1
			lda	§0 +1
			sta	§1 +1
			/

:ClrB			m
			lda	#$00
			sta	§0
			/

:ClrW			m
			lda	#$00
			sta	§0
			sta	§0 +1
			/

:incW			m
			inc	§0
			bne	:Exit
			inc	§0 +1
::Exit
			/

:decW			m
			lda	§0
			bne	:Exit0
			dec	§0 +1
::Exit0			dec	§0
::Exit
			/

:add			m
			clc
			adc	#§0
			/

:adda			m
			clc
			adc	§0
			/

:AddB			m
			clc
			lda	§0
			adc	§1
			sta	§1
			/

:AddW			m
			lda	§0
			clc
			adc	§1
			sta	§1
			lda	§0 +1
			adc	§1+1
			sta	§1+1
			/

:AddVB			m
			lda	§1
			clc
			adc	#§0
			sta	§1
			/

:AddVBW			m
			lda	#§0
			clc
			adc	§1
			sta	§1
			bcc	:Exit
			inc	§1+1
::Exit
			/

:AddVW			m
			lda	#<§0
			clc
			adc	§1
			sta	§1
			lda	#>§0
			adc	§1+1
			sta	§1+1
			/

:sub			m
			sec
			sbc	#§0
			/

:suba			m
			sec
			sbc	§0
			/

:SubB			m
			sec
			lda	§1
			sbc	§0
			sta	§1
			/

:SubW			m
			lda	§1
			sec
			sbc	§0
			sta	§1
			lda	§1+1
			sbc	§0 +1
			sta	§1+1
			/

:SubVB			m
			sec
			lda	§1
			sbc	#§0
			sta	§1
			/

:SubVW			m
			lda	§1
			sec
			sbc	#<§0
			sta	§1
			lda	§1+1
			sbc	#>§0
			sta	§1+1
			/

:CmpB			m
			lda	§0
			cmp	§1
			/

:CmpBI			m
			lda	§0
			cmp	#§1
			/

:CmpW			m
			lda	§0 +1
			cmp	§1+1
			bne	:ende
			lda	§0
			cmp	§1
::ende
			/

:CmpWI			m
			lda	§0 +1
			cmp	#>§1
			bne	:Exit
			lda	§0
			cmp	#<§1
::Exit
			/

:CmpW0			m
			lda	§0 +1
			bne	:Exit
			lda	§0+0
::Exit
			/

:PushB			m
			lda	§0
			pha
			/

:PushW			m
			lda	§0 +1
			pha
			lda	§0
			pha
			/

:PopB			m
			pla
			sta	§0
			/

:PopW			m
			pla
			sta	§0
			pla
			sta	§0 +1
			/

;*** Text ausgeben.
:PrintStrg		m
			lda	#<§0
			sta	r0L
			lda	#>§0
			sta	r0H
			jsr	PutString
			/

;*** Text an Pos x,y ausgeben.
:PrintXY		m
			lda	#<§0
			sta	r11L
			lda	#>§0
			sta	r11H
			lda	#§1
			sta	r1H
			lda	#<§2
			sta	r0L
			lda	#>§2
			sta	r0H
			jsr	PutString
			/

;*** Inline-Textausgabe.
:Print			m
			jsr	i_PutString
			w	§0
			b	§1
			/

;*** Füllmuster wählen
:Pattern		m
			lda	#§0
			jsr	SetPattern
			/

;*** Rechteck zeichnen.
:FillRec		m
			jsr	i_Rectangle
			b	§0,§1
			w	§2,§3
			/

;*** Rechteck zeichnen.
:FillPRec		m
			jsr	i_GraphicsString
			b	NEWPATTERN,§0
			b	MOVEPENTO
			w	§3
			b	§1
			b	RECTANGLETO
			w	§4
			b	§2
			b	NULL
			/

;*** Rechteck zeichnen.
:FrameRec		m
			jsr	i_FrameRectangle
			b	§0,§1
			w	§2,§3
			b	§4
			/

;*** Anzeige-Bitmap wählen.
:Display		m
			lda	#§0
			sta	dispBufferOn
			/

;*** Warten bis keine Maustaste gedrückt.
:NoMseKey		m
::Loop			lda	mouseData
			bpl	:Loop
			lda	#$00
			sta	pressFlag
			/

;*** Neue Maus-Position setzen.
:MseXYPos		m
			lda	#<§0
			sta	r11L
			lda	#>§0
			sta	r11H
			ldy	#§1
			sei
			sec
			jsr	StartMouseMode
			cli
			/

;*** Maus-Modus aktivieren.
:StartMouse		m
			sei
			clc
			jsr	StartMouseMode
			cli
			/
