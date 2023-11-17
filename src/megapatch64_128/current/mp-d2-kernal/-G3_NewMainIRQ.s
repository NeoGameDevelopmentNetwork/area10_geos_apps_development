; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** IRQ-Routine von GEOS.
:xInterruptMain

;--- C64: Maus/Bildschirmschoner/Druckerspooler aktualisieren.
if Flag64_128 = TRUE_C64
			jsr	InitMouseData		;Mausabfrage.
			jsr	IntScrnSave		;Bildschirmschoner testen.
			jsr	IntPrnSpool		;Druckerspooler testen.
endif

if Flag64_128 = TRUE_C128
;--- C128: Bildschirmschoner/Druckerspooler aktualisieren.
;Beide Routinen befinden sich unter IO-Bereich!
;jsr InitMouseData liegt in der Haupt-IRQ-Routine!
			jsr	dIntScrnSave		;Bildschirmschoner testen.
			jsr	dIntPrnSpool		;Druckerspooler testen.
endif

			jsr	PrepProcData		;Prozessabfrage.
			jsr	DecSleepTime		;"SLEEP"-Abfrage.
			jsr	SetCursorMode		;Cursormodus festlegen.

			jmp	GetRandom		;Zufallszahlen berechnen.
							;(Bei C128 im $d000-Bereich!!!)
