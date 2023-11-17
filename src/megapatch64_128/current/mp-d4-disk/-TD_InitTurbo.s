; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O aktivieren.

			lda	#< TurboDOS_1541	;Zeiger auf TurboDOS-Routine in
			sta	d0L			;C64-Speicher.
			lda	#> TurboDOS_1541
			sta	d0H

			lda	#> $0300		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0300
			sta	Floppy_ADDR_L

			lda	#$1a			;(26+1) * 32 Bytes kopieren.
			sta	d1L
::51			jsr	CopyTurboDOSByt		;TurboDOS-Daten an Floppy senden.
;			txa				;Laufwerkfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf C64-Speicher
			lda	#$20			;korrigieren.
			adc	d0L
			sta	d0L
			bcc	:52
			inc	d0H
::52			clc				;Zeiger auf Floppy-Speicher
			lda	#$20			;korrigieren.
			adc	Floppy_ADDR_L
			sta	Floppy_ADDR_L
			bcc	:53
			inc	Floppy_ADDR_H
::53			dec	d1L			;Alle Bytes gesendet ?
			bpl	:51			;Nein, weiter...

;			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::54			jmp	DoneWithIO		;I/O abschalten.
endif

;******************************************************************************
::tmp1 = C_71
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O aktivieren.

			lda	#< TurboDOS_1571	;Zeiger auf TurboDOS-Routine in
			sta	d0L			;C64-Speicher.
			lda	#> TurboDOS_1571
			sta	d0H

			lda	#> $0300		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0300
			sta	Floppy_ADDR_L

			lda	#$1f			;(31+1) * 32 Bytes kopieren.
			sta	d1L
::51			jsr	CopyTurboDOSByt		;TurboDOS-Daten an Floppy senden.
;			txa				;Laufwerkfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf C64-Speicher
			lda	#$20			;korrigieren.
			adc	d0L
			sta	d0L
			bcc	:52
			inc	d0H
::52			clc				;Zeiger auf Floppy-Speicher
			lda	#$20			;korrigieren.
			adc	Floppy_ADDR_L
			sta	Floppy_ADDR_L
			bcc	:53
			inc	Floppy_ADDR_H
::53			dec	d1L			;Alle Bytes gesendet ?
			bpl	:51			;Nein, weiter...

;			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::54			jmp	DoneWithIO		;I/O abschalten.
endif

;******************************************************************************
::tmp2 = C_81
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O aktivieren.

			lda	#< TurboDOS_1581	;Zeiger auf TurboDOS-Routine in
			sta	d0L			;C64-Speicher.
			lda	#> TurboDOS_1581
			sta	d0H

			lda	#> $0300		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0300
			sta	Floppy_ADDR_L

			lda	#$0f			;(15+1) * 32 Bytes kopieren.
			sta	d1L
::51			jsr	CopyTurboDOSByt		;TurboDOS-Daten an Floppy senden.
;			txa				;Laufwerkfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf C64-Speicher
			lda	#$20			;korrigieren.
			adc	d0L
			sta	d0L
			bcc	:52
			inc	d0H
::52			clc				;Zeiger auf Floppy-Speicher
			lda	#$20			;korrigieren.
			adc	Floppy_ADDR_L
			sta	Floppy_ADDR_L
			bcc	:53
			inc	Floppy_ADDR_H
::53			dec	d1L			;Alle Bytes gesendet ?
			bpl	:51			;Nein, weiter...

;			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::54			jmp	DoneWithIO		;I/O abschalten.
endif

;******************************************************************************
::tmp3 = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81
if :tmp3!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O-Bereich einbleden.

			ldx	#> CMD_LdTurboDOS
			lda	#< CMD_LdTurboDOS
			jsr	SendCom5Byt		;GEOS-Modus aktivieren.
			bne	:51			;Fehler? => Ja, Abbruch...

			jsr	UNLSN

			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::51			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Befehl zum installieren des TurboDOS in CMD-Laufwerken.
:CMD_LdTurboDOS		b "GEOS",NULL
endif

;******************************************************************************
::tmp4 = HD_NM
if :tmp4!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O-Bereich einbleden.

			ldx	#> CMD_LdTurboDOS
			lda	#< CMD_LdTurboDOS
			jsr	SendCom5Byt		;GEOS-Modus aktivieren.
			bne	:51			;Fehler? => Ja, Abbruch...

			jsr	UNLSN

			lda	#< $0327		;Routinen in CMD-HD
			ldx	#> $0327		;patchen um den Native-8Mb-Bug
			ldy	#$00			;zu beheben. ReadLink wird dabei
			jsr	PatchCMD_Dos		;durch ReadBlock ersetzt!!!

			lda	#< $04d7
			ldx	#> $04d7
			ldy	#$ff
			jsr	PatchCMD_Dos

			lda	#< $04ed
			ldx	#> $04ed
			ldy	#$ff
			jsr	PatchCMD_Dos

			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::51			jmp	DoneWithIO		;I/O-Bereich ausblenden.

:PatchCMD_Dos		sta	CMD_Patch +3
			stx	CMD_Patch +4
			sty	CMD_Patch +6
			lda	#<CMD_Patch
			ldx	#>CMD_Patch
			ldy	#$07
			jsr	SendComVLen		;GEOS-Modus aktivieren.
			jmp	UNLSN

;*** Befehl zum installieren des TurboDOS in CMD-Laufwerken.
:CMD_LdTurboDOS		b "GEOS",NULL
:CMD_Patch		b "M-W",$27,$05,$01,$00
endif

;******************************************************************************
::tmp5 = PC_DOS
if :tmp5!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O aktivieren.

			lda	#< TurboDOS_DOS		;Zeiger auf TurboDOS-Routine in
			sta	d0L			;C64-Speicher.
			lda	#> TurboDOS_DOS
			sta	d0H

			lda	#> $0500		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0500
			sta	Floppy_ADDR_L

			lda	#$13			;(19+1) * 32 Bytes kopieren.
			sta	d1L
::51			jsr	CopyTurboDOSByt		;TurboDOS-Daten an Floppy senden.
			txa				;Laufwerkfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf C64-Speicher
			lda	#$20			;korrigieren.
			adc	d0L
			sta	d0L
			bcc	:52
			inc	d0H
::52			clc				;Zeiger auf Floppy-Speicher
			lda	#$20			;korrigieren.
			adc	Floppy_ADDR_L
			sta	Floppy_ADDR_L
			bcc	:53
			inc	Floppy_ADDR_H
::53			dec	d1L			;Alle Bytes gesendet ?
			bpl	:51			;Nein, weiter...

;			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::54			jmp	DoneWithIO		;I/O abschalten.
endif

;******************************************************************************
::tmp6 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp6!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O aktivieren.

			lda	#< TurboPP		;Zeiger auf TurboDOS-Routine in
			sta	d0L			;C64-Speicher.
			lda	#> TurboPP
			sta	d0H

			lda	#> $0300		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0300
			sta	Floppy_ADDR_L

			lda	#$0b			;(11+1) * 32 Bytes kopieren.
			sta	d1L
::51			jsr	CopyTurboDOSByt		;TurboDOS-Daten an Floppy senden.
			txa				;Laufwerkfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf C64-Speicher
			lda	#$20			;korrigieren.
			adc	d0L
			sta	d0L
			bcc	:52
			inc	d0H
::52			clc				;Zeiger auf Floppy-Speicher
			lda	#$20			;korrigieren.
			adc	Floppy_ADDR_L
			sta	Floppy_ADDR_L
			bcc	:53
			inc	Floppy_ADDR_H
::53			dec	d1L			;Alle Bytes gesendet ?
			bpl	:51			;Nein, weiter...

;			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::54			jmp	DoneWithIO		;I/O abschalten.
endif

;******************************************************************************
::tmp7 = IEC_NM
if :tmp7!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O aktivieren.

			lda	#< TurboDOS_IECB	;Zeiger auf TurboDOS-Routine in
			sta	d0L			;C64-Speicher.
			lda	#> TurboDOS_IECB
			sta	d0H

			lda	#> $0300		;Zeiger auf TurboDOS-Routine in
			sta	Floppy_ADDR_H		;Floppy-Speicher.
			lda	#< $0300
			sta	Floppy_ADDR_L

			lda	#$0f			;(15+1) * 32 Bytes kopieren.
			sta	d1L
::51			jsr	CopyTurboDOSByt		;TurboDOS-Daten an Floppy senden.
			txa				;Laufwerkfehler ?
			bne	:54			;Ja, Abbruch...

			clc				;Zeiger auf C64-Speicher
			lda	#$20			;korrigieren.
			adc	d0L
			sta	d0L
			bcc	:52
			inc	d0H
::52			clc				;Zeiger auf Floppy-Speicher
			lda	#$20			;korrigieren.
			adc	Floppy_ADDR_L
			sta	Floppy_ADDR_L
			bcc	:53
			inc	Floppy_ADDR_H
::53			dec	d1L			;Alle Bytes gesendet ?
			bpl	:51			;Nein, weiter...

;			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::54			jmp	DoneWithIO		;I/O abschalten.
endif

;******************************************************************************
::tmp8 = S2I_NM
if :tmp8!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** Turbo-Routine in FloppyRAM kopieren.
:InitTurboDOS		jsr	InitForIO		;I/O-Bereich einbleden.

			ldx	#> SD2IEC_InitTD
			lda	#< SD2IEC_InitTD
			ldy	#$08
			jsr	SendComVLen		;GEOS-Modus aktivieren.
			bne	:51			;Fehler? => Ja, Abbruch...

			jsr	UNLSN

			ldx	#NO_ERROR		;Flag: "Kein Fehler..."
::51			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Befehl zum aktivieren des TurboDOS in SD2IEC-Laufwerken.
;--- Ergänzung: 17.10.18/M.Kanet
;Das SD2IEC nutzt kein TurboDOS, sendet aber die passenden Daten zu
;TurboDOS-Befehlen des Treibers. Damit das SD2IEC in den TurboDOS-Modus
;schaltet muss die TurboDOS-Routine an das Laufwerk gesendet werden.
;An Hand einer 16Bit-CRC/Prüfsumme erkennt das SD2IEC das TurboDOS
;emuliert werden soll.
;Der Wert $6309 entspricht CRC16 von TurboDOS/1581, aufgefüllt mit $00
;auf 512Byte (InitTD für 1581 sendet 16x32Bytes an die 1581 = 512Bytes).
:SD2IEC_InitTD		b "M-W"
			w $0300				;Startadresse "RAM".
			b $02				;Anzahl Datenbytes.
			w $6309				;16Bit CRC für TurboDOS/1581.
endif
