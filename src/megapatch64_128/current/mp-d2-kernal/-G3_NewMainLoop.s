; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Mainloop von GEOS.
:xMainLoop		jsr	ExecMseKeyb		;Maus/Tastatur abfragen.
			jsr	ExecProcTab		;Prozesse ausführen.
			jsr	ExecSleepJobs		;SLEEP-Funktion abfragen.
			jsr	ExecViewMenu		;Aktuelles Menü invertieren.
			jsr	SetGeosClock		;GEOS-Uhrzeit aktualisieren.
			jsr	TaskManager		;TaskManager abfragen.

			lda	appMain +0
			ldx	appMain +1
:InitMLoop1		jsr	CallRoutine		;Anwenderprogramm ausführen.
:InitMLoop2		cli				;IRQ freigeben.

;*** IRQ-Abfrage initialisieren und
;    zurück zur Mainloop.
:EndMainLoop

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA
endif
			lda	InitVICdata +$11	;Register $D011 auf Standard.

if Flag64_128 = TRUE_C128
			bit	graphMode
			bmi	:80
endif

;			lda	grcntrl1		;!!! WICHTIG !!!
;			and	#%01111111		;Register $D011 wird manchmal
							;ohne Grund gelöscht, wenn hier
							;nicht wieder der Standardwert
							;gesetzt wird.
							; => BlackScreen-Bug.

			sta	grcntrl1
::80
if Flag64_128 = TRUE_C64
			stx	CPU_DATA
endif

			bit	alarmSetFlag		;Wird Weckroutine ausgeführt ?
			bmi	:1			; => Ja, Spooler und Bild-
			bvs	:3			;    schirmschoner übergehen.

::1			lda	Flag_ScrSaver		;Bildschirmschoner starten ?
			bne	:2			;Nein, weiter...
			jsr	SetADDR_ScrSaver	;Zeiger auf Routine für
			jsr	SwapRAM			;Bildschirmschoner in REU.
			jsr	LD_ADDR_SCRSAVER	;Routine starten und danach
			jsr	SwapRAM			;Speicher wiederherstellen.

::2			bit	Flag_Spooler
			bvc	:3
			jsr	SetADDR_Spooler		;Zeiger auf Routine für
			jsr	SwapRAM			;Druckerspooler in REU.
			jsr	LD_ADDR_SPOOLER		;Routine starten und danach
			jsr	SwapRAM			;Speicher wiederherstellen.
::3			jmp	xMainLoop		;Weiter mit MainLoop.
