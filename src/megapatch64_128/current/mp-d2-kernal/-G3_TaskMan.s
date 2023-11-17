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

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;CPU-Register merken.
			lda	#$35			;I/O-Bereich einblenden.
			sta	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			ldx	MMU			;MMU-Register merken.
			lda	#$7e			;I/O-Bereich einblenden.
			sta	MMU
endif

.TaskManKey1
;			ldy	#%01111011		;CTRL+T
;			cpy	#%10111111		;Hochpfeil.
			ldy	#%01111111		;CBM+CTRL
			sty	$dc00
			ldy	$dc01			;Maustasten einlesen.

if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;CPU-Register zurücksetzen.
endif

if Flag64_128 = TRUE_C128
			stx	MMU			;MMU-Register zurücksetzen.
endif

			plp				;IRQ-Register zurücksetzen.

.TaskManKey2
;			cpy	#%10111011		;CTRL+T
			cpy	#%11011011		;CBM+CTRL
;			cpy	#%10111111		;Hochpfeil.
;			cpy	#%11011011		;linke Taste,
;			cpy	#%11011011		;mittlere Taste,
;			cpy	#%11011011		;rechte Taste.
							;Kombinationen möglich!
			beq	TaskMan_NewJob
:ExitTaskManager	rts				;Keine Taste, weiter...

;*** Einsprungtabelle für TaskManager-Menü.
.TaskMan_NewJob		lda	#$00			;TaskMenü starten.
			b $2c
.TaskMan_QuitJob	lda	#$ff			;Aktuellen Task beenden.
			b $2c
.TaskMan_Quit_DA	lda	#$7f			;DeskAccessorie beenden.
.TaskMan_LoadMenu	pha				;IRQ-Register speichern.

			sei
			ldx	#$ff			;TaskManager deaktivieren.
			stx	Flag_TaskAktiv
			jsr	SetADDR_TaskMan		;Zeiger auf TaskMan-Menü und
			jsr	SwapRAM			;Routine in RAM einlesen.
			pla
			jsr	LD_ADDR_TASKMAN		;TaskManager starten.
			jmp	SwapRAM			;Speicher zurücksetzen.
