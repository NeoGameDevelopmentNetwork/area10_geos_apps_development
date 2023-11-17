; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

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
