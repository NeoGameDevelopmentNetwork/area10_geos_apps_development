; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Original-TurboDOS-Routine.
;    Diese Routine ist in den FD/HD-Laufwerken vom CMD bereits
;    eingebaut. Um die Routine in den CMD-Laufwerken an die richtige
;    Stelle zu kopieren ($0300 ff.) muß der Befehl "GEOS" an das
;    Laufwerk über den ser. Bus gesendet werden.

			n "obj.TurboDOS"
			t "G3_Sys.Author"
			f 3 ;DATA

			o $0500

:JSTJMP			= $ff54				;Jobcode ausführen.
:DTCJMP			= $ff6c				;Cache auf Diskette schreiben.
:WR_FLAG		= $01fa

:BUFFER			= 0
:JOBS_BASE		= $02
:JOBS			= $0002
:HDRS			= $000b
:SIDS			= $01ce
:BUFAREA1		= $0300
:BUFAREA2		= $0400

:l0300			b $0f,$07,$0d,$05,$0b,$03,$09,$01
			b $0e,$06,$0c,$04,$0a,$02,$08
:l030f			b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0

;*** Bytes aus Sektor über ser. Bus einlesen.
.TD_RdSekData		ldy	#$00			;256 Bytes bearbeiten.
			ldx	#>BUFAREA1
			lda	USER_SECTOR		;":ReadLink"-Flag gesetzt ?
			bpl	:51			;Nein, weiter...
			ldx	#>BUFAREA2		;  2 Bytes bearbeiten.
::51			stx	$7f

			jsr	SEND_Bytes		;Daten an Rechner senden.

;*** Fehlerstatus an C64 übergeben.
.TD_SendStatus		lda	#< JOBS			;Zeiger auf Status-Byte für
			sta	$7e			;aktuellen JobCode.
			ldy	#> JOBS
			sty	$7f
			iny				;Zähler auf "1 Byte" setzen.
			jsr	SendByte_STATUS		;Fehlerstatus senden.
			jsr	DRIVE_LED_OFF		;Laufwerks-LED abschalten.
			cli

::51			lda	#$86			;Motor abschalten.
			jsr	DoJob_TrSe

::52			lda	#$04			;Warten bis CLOCK_IN vom C64 auf
			bit	$4001			;HIGH gesetzt wird.
			bne	:51
			sei
			rts

;*** Status-Byte an C64 übertragen.
:SendByte_STATUS	sty	$42			;Anzahl Bytes zwischenspeichern.

			ldy	#$00			;Warten bis CLOCK_IN vom C64
			jsr	CLOCK_IN_HIGH		;auf HIGH gesetzt wird.

			lda	$42			;Anzahl zu übertragender Bytes an
			jsr	SEND_CurByte		;C64 senden.

			ldy	$42			;Anzahl Bytes einlesen.

;*** Anzahl Bytes an C64 übertragen.
;    Übergabe:		yReg    = Anzahl Bytes.
;			$7e,$7f = Zeiger auf Daten.
:SEND_Bytes		jsr	CLOCK_IN_HIGH		;Auf CLOCK_IN = HIGH warten.
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

			jsr	Pause_12		;Warteschleife.
			beq	DATA_OUT_LOW		;Unbedingter Sprung...

			nop				;DUMMY!-Bytes.
			nop
			nop
			nop
			nop
			nop
			nop

;*** Daten von C64 empfangen.
:GET_Bytes		jsr	CLOCK_IN_HIGH		;Warten bis CLOCK_IN con C64 auf
							;HIGH gesetzt wird.

			jsr	Pause_18		;Warteschleife.

			lda	#$00
			sta	$41			;Prüfsummenbyte löschen.
::51			eor	$41			;Neue Prüfsumme berechnen.
			sta	$41

			jsr	Pause_16		;Warteschleife.

			lda	#$04
::52			bit	$4001			;Warten bis CLOCK_IN vom C64 auf
			beq	:52			;LOW gesetzt wird.

			jsr	Pause_14		;Warteschleife.

			lda	$4001			;Byte über ser. Bus einlesen.
			jsr	Pause_16
			asl
			ora	$4001
			php				;Warteschleife.
			plp
			nop
			nop
			and	#$0f
			tax

			lda	$4001
			jsr	Pause_10		;Warteschleife.
			asl
			ora	$4001
			and	#$0f			;Low -Nibble ermitteln und mit
			ora	l030f,x			;High-Nibble verküpfen.
			dey
			sta	($7e),y			;Byte in Speicher übertragen.
			bne	:51

:DATA_OUT_LOW		ldx	#$02			;DATA_OUT auf LOW setzen und
			stx	$4001			;übertragung beenden.

			php				;Warten bis C64 Signal erkannt hat.
			plp
			php
			plp
			php
			plp
			php
			plp
			nop
:Pause_18		nop				;Pause: 18 Taktzyklen.
:Pause_16		nop				;Pause: 16 Taktzyklen.
:Pause_14		nop				;Pause: 14 Taktzyklen.
:Pause_12		nop				;Pause: 12 Taktzyklen.
:Pause_10		nop				;Pause: 10 Taktzyklen.
			nop				;Pause:  8 Taktzyklen.
			rts				;Pause:  6 Taktzyklen.

;*** Warten bis ser. Bus bereit.
:CLOCK_IN_HIGH		lda	#$04
			bit	$4001			;Warten bis CLOCK_IN auf HIGH.
			bne	CLOCK_IN_HIGH		;(Bit #2 = 0)

			lda	#$00			;PortB löschen.
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

			jsr	DATA_OUT_LOW		;DATA_OUT auf LOW setzen.

			lda	#$04
::52			bit	$4001			;Warten bis CLOCK_IN auf LOW.
			beq	:52			;(Bit #2 = 1)

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

			lda	#> BUFAREA1		;Zeiger auf Datenspeicher setzen.
			sta	$7f
			lda	#< BUFAREA1
			sta	$7e

			lda	#> TurboMainLoop -1
			pha
			lda	#< TurboMainLoop -1
			pha
			jmp	(USER_JOB)		;Job-Routine ausführen.

;*** TurboDOS beenden.
.TD_Stop		jsr	CLOCK_IN_HIGH
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
.TD_WrSekData		ldy	#$00			;256 Bytes bearbeiten.
			ldx	#>BUFAREA1
			lda	USER_SECTOR		;":ReadLink"-Flag gesetzt ?
			bpl	:51			;Nein, weiter...
			ldx	#>BUFAREA2		;  2 Bytes bearbeiten.
::51			stx	$7f

			ldy	#$00			;256 Datenbytes einlesen.
			sty	JOBS
			jsr	GET_Bytes

			lda	USER_SECTOR		;":ReadLink"-Flag gesetzt ?
			bpl	:52			;Nein, weiter...

			lda	#$b6			;JobCode: "Schreibschutz testen"
			jsr	DoJob_TrSe		;Schreibschutz auf Diskette testen.

			lda	JOBS			;Fehlerstatus einlesen und
			sta	WR_FLAG			;zwischenspeichern.
			bne	:52			; => Fehler, Abbruch...

			lda	#$a6			;JobCode: "Sektor schreiben"
			jsr	DoJob_TrSe
::52			jmp	TD_SendStatus		;Fehlerstatus an C64 übergeben.

;*** NewDisk-Routine.
.TD_NewDisk		lda	#$92			;JobCode: "Diskette in Laufwerk ?"
			jmp	DoJob_TrSe

;*** Sektor/LinkBytes einlesen.
.TD_GetSektor		lda	#$a4			;JobCode: "Sektor lesen"
			bit	USER_SECTOR
			bpl	DoJob_TrSe
			lda	#$88

;*** Track/Sektor-Job ausführen.
:DoJob_TrSe		sta	JOBS			;JobCode speichern.

			lda	USER_TRACK		;Aktuellen Track  einlesen und
			and	#$80			;":ReadLink"-Flag löschen.
			asl
			rol
			sta	SIDS			;Track- Adresse setzen.

			lda	USER_TRACK		;Aktuellen Track  einlesen und
			and	#$7f			;":ReadLink"-Flag löschen.
			sta	HDRS +0			;Track- Adresse setzen.

			lda	USER_SECTOR		;Aktuellen Sektor einlesen und
			and	#$7f
			sta	HDRS +1			;Sektor-Adresse setzen.

			ldx	#BUFFER			;Puffer-Nr. #3 = $0400-$04FF
			lda	JOBS_BASE,x		;JobCode einlesen und
			jsr	JSTJMP			;ausführen.
:EndJob			rts

:USER_JOB		w $0000
:USER_TRACK		b $00
:USER_SECTOR		b $00

;*** Wurde Diskette gewechselt ?
.WasDiskChanged		ldy	#$ff			;Startwert für Prüfsumme.
			sty	FATSEK
			sty	CurDiskCRC +0
			sty	CurDiskCRC +1
			iny
			sty	HDRS +0
			iny
			sty	HDRS +1
			sty	SIDS

::101			lda	#$a4
			sta	JOBS
::102			lda	JOBS
			bmi	:102

			cmp	#$02
			bcc	:103
			rts

::103			bit	FATSEK
			bpl	:103a
			lda	BUFAREA1   +$16
			sta	FATSEK
			jmp	:105

::103a			ldx	#$00
::104			lda	CurDiskCRC +0
			clc
			adc	BUFAREA1 ,x
			sta	CurDiskCRC +0
			lda	CurDiskCRC +1
			adc	BUFAREA2 ,x
			sta	CurDiskCRC +1
			inx
			bne	:104

::105			inc	HDRS +1
			dec	FATSEK
			bpl	:101
			rts

.CurDiskCRC		w $0000
.FATSEK			b $00
