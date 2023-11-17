; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			o $0300
			n "obj.Turbo81"
			a "M. Kanet"

:JSTJMP			= $ff54				;Jobcode ausführen.
:DTCJMP			= $ff6c				;Cache auf Diskette schreiben.
:WR_FLAG		= $01fa

:l0300			b $0f,$07,$0d,$05,$0b,$03,$09,$01
			b $0e,$06,$0c,$04,$0a,$02,$08
:l030f			b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0

;*** Bytes aus Sektor über ser. Bus einlesen.
.TD_RdSekData		ldy	#$00			;256 Bytes bearbeiten.
			lda	USER_TRACK		;":ReadLink"-Flag gesetzt ?
			bpl	:51			;Nein, weiter...
			ldy	#$02			;  2 Bytes bearbeiten.

::51			jsr	SEND_Bytes		;Daten an Rechner senden.

;*** Fehlerstatus an C64 übergeben.
.TD_SendStatus		lda	#< $0005		;Zeiger auf Status-Byte für
			sta	$7e			;aktuellen JobCode.
			ldy	#> $0005
			sty	$7f
			iny				;Zähler auf "1 Byte" setzen.
			jsr	SendByte_STATUS		;Fehlerstatus senden.
			jsr	DRIVE_LED_OFF		;Laufwerks-LED abschalten.
			cli

::51			lda	Flag_CacheFull		;Daten in Cache ?
			beq	:52			;Nein, weiter...
			dex
			bne	:52
			dec	Flag_CacheFull
			bne	:52

			jsr	DoWriteCache		;Cache auf Diskette schreiben.

::52			lda	#$04
			bit	$4001
			bne	:51
			sei
			rts

;*** Status-Byte an C64 übertragen.
:SendByte_STATUS	sty	$42			;Anzahl Bytes zwischenspeichern.

			ldy	#$00			;Warten bis ser. BUS bereit.
			jsr	WaitATN_Ready

			lda	$42			;Anzahl zu übertragender Bytes an
			jsr	SEND_CurByte		;C64 senden.

			ldy	$42			;Anzahl Bytes einlesen.

;*** Anzahl Bytes an C64 übertragen.
;    Übergabe:		yReg    = Anzahl Bytes.
;			$7e,$7f = Zeiger auf Daten.
:SEND_Bytes		jsr	WaitATN_Ready
:SEND_GetNxByte		dey
			lda	($7e),y
:SEND_CurByte		sta	$41
			and	#$0f
			tax				;Nibble zwischenspeichern.

			lda	#$04			;CLOCK_IN-Signal setzen.
			sta	$4001

::51			bit	$4001			;Serieller Bus Empfangsbereit ?
			beq	:51			;Nein, warten...

			lda	l0300,x			;Übertragungsbyte einlesen und
			sta	$4001			;Byte senden.
			nop
			nop

			ldx	$41
			rol
			and	#$0f
			sta	$4001

			txa				;High-Nibble berechnen.
			lsr
			lsr
			lsr
			lsr
			tax
			lda	l0300,x			;Übertragungsbyte einlesen und
			sta	$4001			;Byte senden.
			nop
			nop
			nop
			nop
			rol
			and	#$0f
			cpy	#$00			;Letztes Byte gesendet ?
			sta	$4001			;Aktuelles High-Nibble senden.
			bne	SEND_GetNxByte		;Nächstes Byte senden.

			jsr	Dummy_l03fe		;DUMMY! Ohne Funktion!
			beq	Set_DATA_OUT		;Unbedingter Sprung...

			nop				;DUMMY! Ohne Funktion!
			nop
			nop
			nop
			nop
			nop
			nop

;*** Daten von C64 empfangen.
:GET_Bytes		jsr	WaitATN_Ready		;Warten bis ser. Bus bereit.

			jsr	Dummy_l03fb		;Warteschleife.

			lda	#$00
			sta	$41			;Prüfsummenbyte löschen.
::51			eor	$41			;Neue Prüfsumme berechnen.
			sta	$41

			jsr	Dummy_l03fc

			lda	#$04
::52			bit	$4001			;Warten bis ser. Bus bereit.
			beq	:52

			jsr	Dummy_l03fd

			lda	$4001			;Byte über ser. Bus einlesen.
			jsr	Dummy_l03fc
			asl
			ora	$4001
			php
			plp
			nop
			nop
			and	#$0f
			tax

			lda	$4001
			jsr	Dummy_l03ff
			asl
			ora	$4001
			and	#$0f			;Low -Nibble ermitteln und mit
			ora	l030f,x			;High-Nibble verküpfen.
			dey
			sta	($7e),y			;Byte in Speicher übertragen.
			bne	:51

:Set_DATA_OUT		ldx	#$02			;Ser. Bus auf Ausgabe schalten.
			stx	$4001

			php				;Dummy! Ohne Funktion!
			plp
			php
			plp
			php
			plp
			php
			plp
			nop
:Dummy_l03fb		nop
:Dummy_l03fc		nop
:Dummy_l03fd		nop
:Dummy_l03fe		nop
:Dummy_l03ff		nop
			nop
			rts

;*** Warten bis ser. Bus bereit.
:WaitATN_Ready		lda	#$04
			bit	$4001			;Warten bis ser. Bus bereit.
			bne	WaitATN_Ready

			lda	#$00			;ATN_IN-Signal löschen.
			sta	$4001
			rts

;*** TurboDOS starten.
.TD_Start		sei

			lda	$41			;Register zwischenspeichern.
			pha
			lda	$42
			pha

			lda	$7f			;Datenregister sichern.
			pha
			lda	$7e
			pha

			ldx	#$02
			ldy	#$00			;Warteschleife.
::51			dey
			bne	:51
			dex
			bne	:51

			jsr	Set_DATA_OUT

			lda	#$04
::52			bit	$4001			;Warten bis ser. Bus bereits.
			beq	:52

;*** TurboDOS-Mainloop.
;    Diese Routine wird nicht verlassen und läuft so lange ab,
;    bis ExitTurbo aufgerufen wird. Daher "hängt" das Laufwerk wenn der
;    C64 ins BASIC abstürzt.
:TurboMainLoop		lda	#> USER_JOB		;Zeiger auf Job-Daten.
			sta	$7f			;(Routine, Track, Sektor).
			lda	#< USER_JOB
			sta	$7e

			ldy	#$01
			jsr	GET_Bytes
			sta	$42
			tay
			jsr	GET_Bytes

			jsr	DRIVE_LED_ON		;Laufwerks-LED einschalten.

			lda	#> $0600		;Zeiger auf Datenspeicher setzen.
			sta	$7f
			lda	#< $0600
			sta	$7e

			lda	#> TurboMainLoop -1
			pha
			lda	#< TurboMainLoop -1
			pha
			jmp	(USER_JOB)		;Job-Routine ausführen.

;*** TurboDOS beenden.
.TD_Stop		jsr	WaitATN_Ready
			pla
			pla
			pla
			sta	$7e			;Datenregister zurücksetzen.
			pla
			sta	$7f
			pla
			sta	$42			;Register zurücksetzen.
			pla
			sta	$41
			cli				;IRQ freigeben,
			rts				;Ende...

;*** LED ausschalten.
:DRIVE_LED_OFF		lda	#$bf
			bne	SetLED_OFF

;*** LED einschalten.
:DRIVE_LED_ON		lda	#$40
			ora	$4000
			bne	SetLED_Mode

:SetLED_OFF		and	$4000
:SetLED_Mode		sta	$4000
			rts

;*** Sektor auf Diskette speichern.
.TD_WrSekData		jsr	WriteCacheOnDisk

			ldy	#$00
			jsr	GET_Bytes

			lda	#$b6			;JobCode: "Schreibschutz testen"
			jsr	DoJob_TrSe		;Schreibschutz auf Diskette testen.

			lda	$05			;Fehlerstatus einlesen und
			sta	WR_FLAG			;zwischenspeichern.
			bne	:51			; => Fehler, Abbruch...

			lda	#$90			;JobCode: "Sektor schreiben"
			sta	Flag_CacheFull
			jsr	DoJob_TrSe
::51			jmp	TD_SendStatus		;Fehlerstatus an C64 übergeben.

;*** NewDisk-Routine.
.TD_NewDisk		jsr	TD_ClearCache
			lda	#$92			;JobCode: "Diskette in Laufwerk ?"
			jsr	DoJob_TrSe
			lda	$05			;Fehlerstatus einlesen.
			cmp	#$02			;Diskette im Laufwerk ?
			bcc	:51			;Ja, weiter...
			nop
			nop
			rts

::51			lda	#$b0			;JobCode: "Sektor auf Disk suchen"
			bne	DoJob_TrSe

;*** Cache-Speicher auf Diskette schreiben.
:WriteCacheOnDisk	lda	USER_TRACK		;Aktuellen track einlesen.
			and	#$7f			;":ReadLink"-Flag löschen.
			cmp	$11			;Noch auf aktueller Spur ?
			beq	EndJob			;Ja, nicht ausführen.

;*** Disketten-Cache löschen.
.TD_ClearCache		lda	Flag_CacheFull		;Ist Cache leer ?
			beq	EndJob			;Ja, Ende...

;*** Cache immer auf Diskette schreiben.
:DoWriteCache		ldx	#$03			;Puffer #3 = $0400 - $04FF.
			jsr	DTCJMP			;Cache auf Diskette schreiben.

			lda	#$00			;Flag löschen.
			sta	Flag_CacheFull

			lda	#$86			;Motor abschalten.
			bne	DoJob_TrSe

;*** Sektor/LinkBytes einlesen.
.TD_GetSektor		jsr	WriteCacheOnDisk

			lda	#$80			;JobCode: "Sektor lesen"

;*** Track/Sektor-Job ausführen.
:DoJob_TrSe		sta	$05			;JobCode speichern.
			lda	USER_TRACK		;Aktuellen Track  einlesen und
			and	#$7f			;":ReadLink"-Flag löschen.
			sta	$11			;Track- Adresse setzen.
			lda	USER_SECTOR		;Aktuellen Sektor einlesen und
			sta	$12			;Sektor-Adresse setzen.

			ldx	#$03			;Puffer-Nr. #3 = $0400-$04FF
			lda	$02,x			;JobCode einlesen und
			jsr	JSTJMP			;ausführen.
:EndJob			rts

			b $00
:Flag_CacheFull		b $00

:USER_JOB		w $0000
:USER_TRACK		b $00
:USER_SECTOR		b $00
