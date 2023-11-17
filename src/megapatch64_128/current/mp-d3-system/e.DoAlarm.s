; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.DoAlarm"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o LD_ADDR_DOALARM

;*** Warnton "Wecker" ausgeben.
;    Im IRQ wird der Wert "AlarmAktiv" runtergezählt. Ist der Wert = 0, dann
;    wird die Alarm-Routine ausgeführt.
:DoAlarmSound		lda	AlarmAktiv		;IRQ-Zähler abgelaufen ?
			bne	:54			; => Nein, weiter...

if Flag64_128 = TRUE_C64
			ldy	CPU_DATA		;I/O-Bereich einblenden.
			lda	#%00110101
			sta	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			ldy	MMU			;I/O-Bereich einblenden.
			lda	#$7e
			sta	MMU
endif
			ldx	#$18			;Sound-Daten aktivieren.
::51			lda	AlarmSoundData,x
			sta	$d400         ,x
			dex
			bpl	:51

if Flag64_128 = TRUE_C128
			ldx	graphMode
			bpl	:40Z

;--- C128: 80-Zeichen.
			ldx	#26
			jsr	GetVDC			;Rahmenfarbe holen und sichern.
			pha

			clc				;Farbe ändern.
			adc	#1

			jsr	SetVDC			;Neue Farbe setzen.
			jsr	SCPU_Pause

			pla				;Alte Rahmenfarbe wiederherstellen.
			ldx	#26
			jsr	SetVDC
::40Z
endif
			inc	$d020			;Rahmenfarbe ändern.
			jsr	SCPU_Pause
			dec	$d020

			ldx	#$21
			lda	alarmSetFlag
			and	#$3f			;Alarm-Routine beendet ?
			bne	:53			; => Nein, weiter...

			ldx	#$18			;Sound-Daten löschen.
::52			sta	$d400,x
			dex
			bpl	:52

			tax
::53			stx	$d404

if Flag64_128 = TRUE_C64
			sty	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			sty	MMU
endif

			lda	#%00011110		;IRQ-Warteschleife initialisieren.
			sta	AlarmAktiv
			dec	alarmSetFlag		;Zähler für Anzahl Warnton-Signale
							;korrigieren.
::54			jmp	SwapRAM

;*** Sound-Daten für Alarm-Ton.
:AlarmSoundData		b $00,$10,$00,$08,$40,$08,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $0f

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_DOALARM + R2_SIZE_DOALARM -1
;******************************************************************************
