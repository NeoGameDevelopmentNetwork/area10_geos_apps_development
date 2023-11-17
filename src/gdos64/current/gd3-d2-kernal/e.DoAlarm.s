; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
;			t "MacTab"
endif

;*** GEOS-Header.
			n "obj.DoAlarm"
			f DATA

			o LOAD_DOALARM

;*** Warnton "Wecker" ausgeben.
;    Im IRQ wird der Wert "AlarmAktiv" runtergezählt. Ist der Wert = 0, dann
;    wird die Alarm-Routine ausgeführt.
:DoAlarmSound		lda	AlarmAktiv		;IRQ-Zähler abgelaufen ?
			bne	:54			; => Nein, weiter...

			ldy	CPU_DATA		;I/O-Bereich einblenden.
			lda	#IO_IN
			sta	CPU_DATA

			ldx	#$18			;Sound-Daten aktivieren.
::51			lda	AlarmSoundData,x
			sta	$d400         ,x
			dex
			bpl	:51

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

			sty	CPU_DATA

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
			g LOAD_DOALARM + R2S_DOALARM -1
;******************************************************************************
