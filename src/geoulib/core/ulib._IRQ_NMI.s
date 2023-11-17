; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; ULIB: IRQ/NMI abschalten.
;
;NMI führt bei Ultimate am C128 im
;80Z-Modus zu Problemen.
;
;Übergabe : -
;Rückgabe : -
;Verändert: A

:ULIB_IRQ_DISABLE

			lda	$d015			;Sprite-Register zwiscenspeichern.
			sta	buf_D015
			lda	#$00			;Sprites abschalten.
			sta	$d015

			lda	$d01a			;Interrupt-Register grirqen
			sta	buf_D01A		;zwischenspeichern.
			lda	#%00000000		;Interrupt-Request: Maske (1=an)
							;Bit7-4: Unbenutzt.
							;Bit3  : IRQ/Lightpen
							;Bit2  : IRQ/S-S-Kollision
							;Bit1  : IRQ/S-H-Kollision
							;Bit0  : IRQ/Rasterstrahl
			sta	$d01a

			lda	#%01111111		;Interrupt-Request grirq: (1=an)
							;Bit7  : Interrupt durch VIC
							;Bit6-4: Unbenutzt.
							;Bit3  : IRQ/Lightpen
							;Bit2  : IRQ/S-S-Kollision
							;Bit1  : IRQ/S-H-Kollision
							;Bit0  : IRQ/Rasterstrahl
			sta	$d019			;Interrupt-Flags löschen (Bit=1).

;			lda	#%01111111
			sta	$dc0d			;CIA#1:
							;Bit7  : 0=Maske 0-4 löschen (Bit=1)
							;Bit6-5: Unbenutzt
							;Bit4  : Enable IRQ FLAG/Positive
							;Bit3  : Byte-Übertragung komplett
							;Bit2  : Uhrzeit-Alarm
							;Bit1  : Timer B Unterlauf
							;Bit0  : Timer A Unterlauf
			sta	$dd0d			;CIA#2:
							;Bit7  : 0=Maske 0-4 löschen (Bit=1)
							;Bit6-5: Unbenutzt
							;Bit4  : Enable NMI FLAG/Positive
							;Bit3  : Byte-Übertragung komplett
							;Bit2  : Uhrzeit-Alarm
							;Bit1  : Timer B Unterlauf
							;Bit0  : Timer A Unterlauf

			lda	#%00111111		;Port A:
							;Bit7-6: Read only
							;Bit5-0: Read/Write
			sta	$dd02

			lda	#$00			;Startwert für Timer A in CIA#2
			sta	$dd05			;für NMI bei Unterlauf Timer A.
			lda	#$01			;Es wird also ein NMI ausgelößt und
			sta	$dd04			;danach kein weiterer mehr.

			lda	#%10000001		;Interrupt-Control:
			sta	$dd0d			;Enable Timer A
			lda	#%00001001		;Timer A-Control:
			sta	$dd0e			;Bit3  : 1=Timer/Stop bei Unterlauf
							;Bit0  : 1=Start Timer

			rts

;
; ULIB: IRQ/NMI zurücksetzen
;
;IRQ/NMI wieder zulassen.
;
;Übergabe : -
;Rückgabe : -
;Verändert: A

:ULIB_IRQ_ENABLE

			lda	#%01111111
			sta	$dd0d			;CIA#2:
							;Bit7  : 0=Maske 0-4 löschen (Bit=1)
							;Bit6-5: Unbenutzt
							;Bit4  : Enable NMI FLAG/Positive
							;Bit3  : Byte-Übertragung komplett
							;Bit2  : Uhrzeit-Alarm
							;Bit1  : Timer B Unterlauf
							;Bit0  : Timer A Unterlauf

			lda	$dd0d			;NMI bestätigen/aktivieren.

			lda	buf_D01A		;Interrupt-Register
			sta	$d01a			;wieder zurücksetzen.

			lda	buf_D015		;Sprites zurücksetzen.
			sta	$d015

			rts

:buf_D015		b $00
:buf_D01A		b $00
