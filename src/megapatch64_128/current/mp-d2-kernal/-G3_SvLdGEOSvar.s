; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aktuelle GEOS-Variabln speichern und auf Standard zurücksetzen.
;    Wird verwendet beim starten eines DAs und einer Dialogbox.
.SaveGEOS_Data		lda	#r2L
			ldx	#r4L
			ldy	#$00			;$00-Byte, Flag zum löschen des
			beq	SwapBytes		;Sprite-Registers.

;*** GEOS-Variablen zurücksetzen.
;    Wird verwendet beim starten eines DAs und einer Dialogbox.
.LoadGEOS_Data		lda	#r4L
			ldx	#r2L
			ldy	#$ff			;Flag für "Kein GEOS-Reset".

;*** Bytes speichern/einlesen.
:SwapBytes		sta	:52 +1			;Zeiger auf Speicher setzen.
			stx	:52 +3

			php				;IRQ-Status retten und
			sei				;IRQs abschalten.

if Flag64_128 = TRUE_C64
			lda	CPU_DATA		;CPU-Register speichern.
			pha
			lda	#$35			;I/O-Bereich aktivieren.
			sta	CPU_DATA
else
			lda	MMU			;MMU-Register speichern.
			pha
			and	#%11111110		;I/O-Bereich aktivieren.
			sta	MMU
endif

			lda	#>dlgBoxRamBuf		;GEOS-Variablen im Bereich
			sta	r4H			;":dlgBoxRamBuf" speichern.
			lda	#<dlgBoxRamBuf
			sta	r4L

			tya				;Reset-Flag speichern.
			pha

			ldx	#$00			;GEOS-Variablen im Bereich
::51			lda	DB_SaveMemTab,x		;Zeiger auf Bereich Original-
			sta	r2L			;Daten einlesen.
			inx
			lda	DB_SaveMemTab,x
			sta	r2H
			inx
			ora	r2L			;Ist Adresse = $0000 = Ende ?
			beq	:54			;Ja, Ende...
			lda	DB_SaveMemTab,x		;Anzahl Bytes einlesen.
			sta	r3L
			inx

			ldy	#$00
::52			lda	(r2L),y			;Bytes kopieren.
			sta	(r4L),y
			iny
			dec	r3L
			bne	:52

			tya				;Zeiger auf Zwischenspeicher
			clc				;korrigieren.
			adc	r4L
			sta	r4L
			bcc	:53
			inc	r4H
::53			jmp	:51

::54			pla				;Reset-Flag einlesen und
			tax				;zwischenspeichern.
			bne	:55			; => Kein "GEOS-Reset".
			sta	mobenble		;Sprites löschen.

::55			pla

if Flag64_128 = TRUE_C64
			sta	CPU_DATA		;CPU-Status zurücksetzen.
else
			sta	MMU			;MMU-Status zurücksetzen.
endif
			txa				;"GEOS-Reset" auslösen ?
			bne	:56			;Nein, weiter...
			sta	sysDBData		;DB_Box-Status löschen.
			jsr	GEOS_InitVar		;GEOS-Variablen auf Standard.

::56			plp				;IRQ-Status zurücksetzen.
			rts

;*** Zeiger auf die zu sichernden Speicherbereiche für ":DoDlgBox".
:DB_SaveMemTab		w curPattern
			b $17
			w appMain
			b $26
			w DI_VecDefTab
			b $02
			w DM_MenuType
			b $31
			w ProcCurDelay
			b $e3
			w obj0Pointer
			b $08
			w mob0xpos
			b $11
			w mobenble
			b $01
			w mobprior
			b $03
			w mcmclr0
			b $02
			w mob1clr
			b $07
			w moby2
			b $01
			w $0000
