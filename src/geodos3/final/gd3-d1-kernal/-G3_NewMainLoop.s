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
:EndMainLoop		ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

;			lda	grcntrl1		;!!! WICHTIG !!!
;			and	#%01111111		;Register $D011 wird manchmal
							;ohne Grund gelöscht, wenn hier
							;nicht wieder der Standardwert
							;gesetzt wird.
							; => BlackScreen-Bug.

			lda	InitVICdata +$11	;Register $D011 auf Standard.
			sta	grcntrl1

			stx	CPU_DATA

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

::3			bit	HelpSystemActive	;System-Hilfe aktiv?
			bpl	:4			;Nein, Ende...

			lda	keyData
			cmp	#$01			;"KEY_F1" im Puffer?
			bne	:4			;Nein, weiter...

;--- Füllbyte.
;Der direkte vergleich mit "cmp #$01"
;sollte durch einen Vergleich mit einer
;Registeradresse ersetzt werden.
;Um Speicher für den Befehl "cmp $xxxx"
;zu reservieren wird "NOP" eingefügt.
			nop

			sei				;Interrupt sperren.
			jsr	SetADDR_GeoHelp		;Systemhilfe öffnen.
			jsr	SwapRAM
			jsr	LD_ADDR_GEOHELP
			jsr	SwapRAM

::4			jmp	xMainLoop		;Weiter mit MainLoop.
