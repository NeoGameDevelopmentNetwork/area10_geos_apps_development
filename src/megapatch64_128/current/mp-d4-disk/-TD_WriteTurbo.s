; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!PC_DOS!IEC_NM
::tmp0b = HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** 32 Byte-Daten aus TurboDOS-Routine in FloppyRAM kopieren.
;Übergabe: d0      : Zeiger auf Daten.
;Rückgabe: Z-Flag=1: Kein Fehler.
;--- Ergänzung: 17.10.18/M.Kanet
;Diese Routine wird für SD2IEC nicht mehr benötigt. Im IECBus-NM Treiber
;aus Kompatibilitätsgründen für CMD-FD noch vorhanden.
:CopyTurboDOSByt	ldx	#> :com_MW_TDOS
			lda	#< :com_MW_TDOS
			ldy	#$06
			jsr	SendComVLen		;"M-W"-Befehl an Floppy senden.
			bne	:err			;Fehler? => Ja, Abbruch...

			ldy	#$00
::loop			lda	(d0L),y			;Byte einlesen und an Floppy senden.
			jsr	CIOUT
			iny
			cpy	#$20			;Alle Bytes gesendet ?
			bcc	:loop			;Nein, weiter...

			jsr	UNLSN			;Laufwerk abschalten.

			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::err			rts

;*** Befehl für "M-W".
::com_MW_TDOS		b "M-W"
:Floppy_ADDR_L		b $00				;Wird durch ":InitTurboDOS"
:Floppy_ADDR_H		b $00				;modifiziert = Startadresse RAM.
			b $20				;Anzahl Bytes an Floppy senden.
							;(Max. 32 Bytes wegen Puffergröße!)
endif
