; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; geoULib - Assembler-Bibliothek für
;           GEOS-Programmierer
;
;           Für GEOS/MegaAssembler V4
;
; Version : 0.2
; Release : 2023/05/19
;
;           by M.Kanet
;

;
; ULIB: Auf Ultimate testen
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK.
;Verändert: A,X,Y

:ULIB_TEST_UDEV

			jsr	ULIB_IO_ENABLE		;1MHz, IRQ sperren, I/O ein.

			ldy	UCI_IDENTIFY		;Kennbyte einlesen.

			jsr	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

			ldx	#NO_ERROR
			cpy	#UCI_IDENTIFIER		;Ultimate vorhanden?
			beq	:ok			; => Ja, weiter...

			ldx	#DEV_NOT_FOUND		;Kein Ultimate vorhanden...
::ok			rts

;
; ULIB: I/O-Bereich einblenden
;
;Schaltet den I/O-Bereich unter GEOS64
;ein und sperrt den Interrupt.
;
;Übergabe : -
;Rückgabe : -
;Verändert: A

:ULIB_IO_ENABLE

			php
			sei

			pla				;Interrupt-Status speichern.
			sta	buf_ProcStatus

			lda	CPU_DATA		;Nur C64 (bei C128 ohne Funktion):
			sta	buf_CPU_DATA		;RAM-Konfiguration speichern.
			lda	#IO_IN
			sta	CPU_DATA

			bit	c128Flag		;C128?
			bpl	:exit			; => Nein, Ende...

			lda	MMU128
			sta	buf_MMU128
			lda	#%01111110		;MMU:
							;Bit7/6: 01 = Bank#1
							;Bit5/4: 11 = $C000-$FFFF = RAM
							;Bit3/2: 11 = $8000-$BFFF = RAM
							;Bit1  : 1  = $4000-$7FFF = RAM
							;Bit0  : 0  = $D000-$DFFF = I/O
			sta	MMU128			;RAM-Konfiguration speichern.

			lda	RAMCONF128		;Nur C128:
			sta	buf_RAMCONF128		;Konfiguration speichern.
			lda	#%01000000		;Bit1/0=00: Common Area 1Kb
							;Bit3/2=00: Keine Common Area
							;Bit5/4=00: Unused
							;Bit6  =1 : VIC in Bank1
							;Bit7  =0 : Unused
			sta	RAMCONF128		;Konfiguration speichern.

::exit			rts

;
; ULIB: I/O-Bereich ausblenden
;
;Schaltet den I/O-Bereich unter GEOS64
;aus und setzt den Interrupt zurück.
;
;Übergabe : -
;Rückgabe : -
;Verändert: A

:ULIB_IO_DISABLE

			bit	c128Flag		;C128?
			bpl	:skip			; => Nein, Ende...

			lda	buf_RAMCONF128		;Nur C128:
			sta	RAMCONF128		;RAM-Konfiguration zurücksetzen.

			lda	buf_MMU128		;Nur C128:
			sta	MMU128			;RAM-Konfiguration zurücksetzen.

::skip			lda	buf_CPU_DATA		;Nur C64 (bei C128 ohne Funktion):
			sta	CPU_DATA		;RAM-Konfiguration zurücksetzen.

			lda	buf_ProcStatus		;Interrupt-Status zurücksetzen.
			pha

			plp
			rts

:buf_MMU128		b $00  ;$FF00
:buf_RAMCONF128		b $00  ;$D506
:buf_CPU_DATA		b $00  ;$01
:buf_ProcStatus		b $00

;
; ULIB: Abbruch-Befehl senden
;
;Sendet ABORT an das Ultimate-Gerät.
;Sollte zu Beginn eines Programms
;ausgeführt werden, damit das Ultimate
;in einem definierten Zustand ist.
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK.
;           Y = Status-Bits (IDLE/BUSY/DATALAST/DATAMORE)
;Verändert: A,X,Y

:ULIB_SEND_ABORT

			lda	UCI_STATUS
			and	#CMD_STATE_BITS
			cmp	#CMD_STATE_IDLE		;IDLE-Status?
			beq	:ok			; => Ja, Ende...

			lda	#CMD_ABORT		;Abbruch senden.
			sta	UCI_CONTROL

			ldx	#CMD_TIMEOUT		;Timeout-Zähler über X/Y-Register
			ldy	#0			;initialisieren.

::wait_abort		lda	UCI_STATUS
			and	#CMD_ABORT		;Abbruch ausgeführt?
			beq	:ok			; => Ja, Ende...

			jsr	ULIB_WAIT		;Timeout-Verzögerung.

			dey
			bne	:wait_abort
			dex				;Timeout?
			bne	:wait_abort		; => Nein, warten...

			tay				;Status-Bits.
			ldx	#UCI_ERR_TIMEOUT	;Fehler.
			rts

::ok			jsr	ULIB_CLEAR_ERR		;Fehler-Status löschen.

			tay				;Status-Bits.
			ldx	#UCI_NO_ERROR		;Kein Fehler.
			rts

;
; ULIB: Status-Register/Fehler löschen
;
;Übergabe : -
;Rückgabe : -
;Verändert: -

:ULIB_CLEAR_ERR

			pha

			lda	#CMD_ERROR
			sta	UCI_CONTROL

			pla
			rts

;
; ULIB: Befehl ausführen
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK.
;           Y = Status-Bits (IDLE/BUSY/DATALAST/DATAMORE)
;Verändert: A,X,Y

:ULIB_PUSH_CMD

			jsr	ULIB_WAIT_IDLE		;Auf Ultimate warten...
			txa				;Timeout?
			bne	:err			; => Ja, Abbruch...

			lda	#CMD_NEW_CMD		;Aktuellen Befehl
			sta	UCI_CONTROL		;ausführen.

			jsr	ULIB_WAIT_IDLE		;Auf Status IDLE oder DATA warten.
;			txa				;Timeout?
;			bne	:err			; => Ja, Abbruch...

::err			rts				;Ende...

;
; ULIB: Ende von Status=BUSY abwarten
;
;Übergabe : -
;Rückgabe : X = Fehlerstatus, $00=OK.
;           Y = Status-Bits (IDLE/BUSY/DATALAST/DATAMORE)
;Verändert: A,X,Y

:ULIB_WAIT_IDLE

			lda	#CMD_TIMEOUT		;Timeout-Zähler einlesen.
			beq	:err			; => Wert ungültig, Fehler...

			tax				;Timeout-Zähler über X/Y-Register
			ldy	#0			;initialisieren.

::wait_idle		lda	UCI_STATUS
			and	#CMD_STATE_BITS
			cmp	#CMD_STATE_BUSY		;IDLE/LAST/MORE-Status?
			bne	:ok			; => Ja, Ende...

			jsr	ULIB_WAIT		;Timeout-Verzögerung.

			dey
			bne	:wait_idle
			dex				;Timeout?
			beq	:err			; => Ja, Abbruch...
			cpx	#5			;Timeout fast abgelaufen?
			bcs	:wait_idle		; => Nein, weiter...

;--- Hinweis:
;Bei 2MHz/48MHz kann der Timeout evtl.
;ungewollt ablaufen. Daher am Ende das
;Sekunden-Register verwenden.
			lda	cia1tod_s		;1/10 Sekunde Pause für
::delay			cmp	cia1tod_s		;C128/2MHz und Ultimate64/48MHz.
			beq	:delay

			bne	:wait_idle		; => Warten...

::err			tay				;Status-Bits.
			jsr	ULIB_ERR_TIMEOUT	;Status-Meldung erzeugen.
			ldx	#UCI_ERR_TIMEOUT	;Fehler.
			rts

::ok			tay				;Status-Bits.
			ldx	#UCI_NO_ERROR		;Kein Fehler.
			rts

;
; ULIB: Timeout-Fehler
;
;Status-Meldung "41,TIMEOUT" erzeugen.
;
;Übergabe : -
;Rückgabe : UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,r5
;Hinweis  : Y nicht verändern!

:ULIB_ERR_TIMEOUT

			ldx	#:terr_len -1
::1			lda	:terr,x
			sta	UCI_STATUS_MSG,x
			dex
			bpl	:1

			lda	#< UCI_STATUS_MSG
			sta	r5L
			lda	#> UCI_STATUS_MSG
			sta	r5H

			rts

;--- Fehler: Timeout!
::terr			b "41,TIMEOUT",NULL
::terr_end
::terr_len		= (:terr_end - :terr)

;*** Speicher für Status-Meldung.
:UCI_STATUS_MSG		s 80 +1

;
; ULIB: Warteschleife für Timeout
;
;Übergabe : -
;Rückgabe : -
;Verändert: -

;--- Hinweis:
;Der Inhalt on AKKU und X-Register
;darf hier nicht verändert werden!
;
;Ein zu kurzer TIMEOUT-Wert führt dazu,
;das SAVE_REU einen TIMEOUT erzeugt:
;Das speichern dauert ein paar Sek. und
;beim C128 läuft der Zähler schneller
;ab => C64: OK, C128: TIMEOUT!
;

:ULIB_WAIT

if TRUE
;#399 Taktzyklen Verzögerung.
;Mit LDY#0 (256x) und dem Zähler
;':CMD_TIMEOUT' (100x) ergibt das
;ca.10.000.000 Taktzyklen.
;C64/10s und C128/5s plus zusätzlich
;5s am Ende bis zum Timeout.
;Durch die kürzere dritte Schleife
;wird das STATUS-Register häufiger
;und schneller abgefragt.
			pha				;3 Takte
			lda	#CMD_DELAY -1		;2 Takte
			sec				;2 Takte
::1			nop				;2 Takte
			sbc	#1			;2 Takte
			bcs	:1			;2 Takte
			pla				;4 Takte
			rts				;6 Takte
endif

if FALSE
;--- Alternative:
;Die Verwendung der RTC im CIA ist
;zwar unabhängig vom Systemtakt, aber
;deutlich langsamer.
			ldy	cia1tod_t
::1			cpy	cia1tod_t
			beq	:1
			rts
endif
