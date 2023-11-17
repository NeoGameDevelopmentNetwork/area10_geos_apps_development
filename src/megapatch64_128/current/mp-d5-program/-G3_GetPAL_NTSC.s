; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prozessortyp ausgeben.
:GetPAL_NTSC		php
			sei
			PushB	CPU_DATA
			LoadB	CPU_DATA,$35

::51			bit	$d011			;Warten bis Rasterzeile 256
			bpl	:51			;erreicht wird.

::52			lda	$d012			;Position Rasterstrahl einlesen.
			beq	:52			; = $00 ? Ja, warten bis Bit #7
							;von $D011 gesetzt ist...
			bit	$d011			;Rasterzeile #0,1,2... erreicht ?
			bpl	:53			; => Ja, weiter...
			tax				;Rasterzeile merken und
			jmp	:52			;warten...

::53			ldy	#$00			;Vorbelegung NTSC.
			cpx	#<280			;Weniger als 280 Rasterzeilen ?
			bcc	:54			; => Ja, NTSC...
			iny				;PAL-C64.
::54			sty	PAL_NTSC		;Systemflag speichern.

			PopB	CPU_DATA
			plp
			rts
