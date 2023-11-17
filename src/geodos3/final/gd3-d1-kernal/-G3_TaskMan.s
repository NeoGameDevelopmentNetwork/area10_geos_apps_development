; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Maustasten prüfen.
.TaskManager		bit	Flag_TaskAktiv		;Taskmanager aktiv ?
			bmi	ExitTaskManager		; => Nein, weiter...

			php
			sei
			ldx	CPU_DATA		;CPU-Register merken.
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

.TaskManKey1		ldy	#%01111111		;CBM+CTRL
;			ldy	#%01111011		;CTRL+T
;			ldy	#%10111111		;Hochpfeil.
			sty	$dc00
			ldy	$dc01			;Maustasten einlesen.

			stx	CPU_DATA		;CPU-Register zurücksetzen.
			plp				;IRQ-Register zurücksetzen.

.TaskManKey2		cpy	#%11011011		;CBM+CTRL
;			cpy	#%10111011		;CTRL+T
;			cpy	#%10111111		;Hochpfeil.
							;%11101111 für linke Taste,
							;%11111101 für mittlere Taste,
							;%11111110 für rechte Taste.
							;Kombinationen möglich!
			bne	ExitTaskManager
			jmp	TaskMan_NewJob
:ExitTaskManager	rts				;Keine Taste, weiter...
