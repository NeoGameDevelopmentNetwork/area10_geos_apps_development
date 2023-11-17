; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!PC_DOS
::tmp0b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM!IEC_NM!S2I_NM
::tmp0 = :tmp0a!:tmp0b
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** Diskettenstatus einlesen.
:xGetDiskError		jsr	initDevTALK		;Laufwerk auf Senden schalten.
			bne	:err			;Fehler? => Ja, Abbruch...

::1			jsr	ACPTR			;1.Zeichen aus Status einlesen.

			sec				;High-Nibble nach HEX wandeln.
			sbc	#$30
			asl
			asl
			asl
			asl
			sta	:err_code

			jsr	ACPTR			;2.Zeichen aus Status einlesen.

			sec				;Low-Nibble nach HEX wandeln.
			sbc	#$30
			ora	:err_code		;HEX-Wert erzeugen.

			pha
::skip_status		jsr	ACPTR			;Reset des Fehlerstatus
			lda	STATUS			;überspringen.
			beq	:skip_status
			pla

::err			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla				;Fehlerstatus wieder einlesen.

;--- Achtung!
;Der Fehlercode wird als HEX-Wert über
;den Fehlerkanal eingelesen!!!
			cmp	#$02			;Status 00/01?
			bcc	:ok			; => Ja, weiter...

;Test auf SD2IEC-Lesefehler.
			cmp	#$20			;20,READ ERROR = SD2IEC-Verzeichnis.
			beq	:error			; => Keine Wiederholung.

;Test auf READ/WRITE oder sonstiger Fehler.
			cmp	#$30			;Kein READ/WRITE Fehler?
			bcs	:error			; => Ja, keine Wiederholung.

;Test READ oder WRITE Fehler?
			cmp	#$25			;Lesefehler?
			bcc	:read			; => Ja, weiter...

::write			ldy	#$03			;Max. 3x Schreibversuche.
			tax
			rts

::read			ldy	#$02			;Max. 2x Leseversuche.
			tax
			rts

::error			ldy	#$01			;Fehler, nicht wiederholen.
			tax
			rts

::ok			ldy	#$01			;Kein Fehler, nicht wiederholen.
			ldx	#NO_ERROR
			rts

::err_code		b $00
endif
