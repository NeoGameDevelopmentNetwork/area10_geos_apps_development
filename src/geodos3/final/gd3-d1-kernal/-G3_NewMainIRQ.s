; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** IRQ-Routine von GEOS.
:xInterruptMain		jsr	InitMouseData		;Mausabfrage.
			jsr	IntScrnSave		;Bildschirmschoner testen.
			jsr	IntPrnSpool		;Druckerspooler testen.
			jsr	PrepProcData		;Prozessabfrage.
			jsr	DecSleepTime		;"SLEEP"-Abfrage.
			jsr	SetCursorMode		;Cursormodus festlegen.
			jmp	GetRandom		;Zufallszahlen berechnen.
