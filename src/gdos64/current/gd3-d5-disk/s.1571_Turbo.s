; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
:FindCurTrack		= $944f
:ExecJobCode		= $9606
:FindSekHeader		= $970f
:Wait_70		= $a483
:GetMaxSekOnTrack	= $f24b
:GetBufferCRC		= $f5e9
:ConvBinary2GCR		= $f78f
:TurnOnMotor		= $f97e
:TurnOffMotor		= $f98f
:SetMode1541		= $ff82
:VIA1_PortB_InOut	= $1800
:VIA1_PortB_Data	= $1802
:VIA1_Timer1_High	= $1805
:VIA1_DrvControlB	= $180f
:VIA2_DrvControlA	= $1c00
:VIA2_PortA_RW		= $1c01
:VIA2_PortA_Data	= $1c03
:VIA2_PCR_Control	= $1c0c
endif

			n "obj.Turbo71"
;			t "opt.Author"
			f 3 ;DATA

			o $0300

;*** Tabellen für TurboDOS-Übertragung.
:l0300			b $0f,$07,$0d,$05,$0b,$03,$09,$01
			b $0e,$06,$0c,$04,$0a,$02,$08
:l030f			b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0

;*** Job-Status an C64 übertragen.
.TD_SendStatus		ldy	#$00
			sty	$73
			sty	$74
			iny
			sty	$71

			ldy	#$00
			jsr	WaitMotorOff
			lda	$71
			jsr	SEND_CurByte

			ldy	$71

;*** Einsprung: Datenblock (256 Bytes) an C64 senden.
:SEND_DataBlock		jsr	WaitMotorOff

;*** Datenbytes an C64 senden.
:SEND_GetNxByte		dey				;Zeiger auf nächstes Byte.
			lda	($73),y			;Byte aus Speicher einlesen.
:SEND_CurByte		tax				;Aktuelles Byte merken.
			lsr				;High-Nibble berechnen und
			lsr				;zwischenspeichern.
			lsr
			lsr
			sta	$70
			txa
			and	#$0f			;Low -Nibble berechnen und
			tax				;zwischenspeichern.
			lda	#$04
			sta	VIA1_PortB_InOut
::51			bit	VIA1_PortB_InOut
			beq	:51
			nop
			nop
			nop
			nop
			stx	VIA1_PortB_InOut	;LOW-Nibble senden.
			jsr	Pause_6			;Warteschleife.
			txa
			rol
			and	#$0f
			sta	VIA1_PortB_InOut	;LOW-Nibble senden.
			php
			plp
			nop
			nop
			nop
			ldx	$70
			lda	l0300,x			;Übertragungsbyte einlesen und
			sta	VIA1_PortB_InOut	;Byte senden.
			jsr	Pause_8			;Warteschleife.
			rol
			and	#$0f
			cpy	#$00			;Letztes Byte gesendet ?
			sta	VIA1_PortB_InOut	;Aktuelles High-Nibble senden.
			jsr	Pause_10		;Warteschleife.
			bne	SEND_GetNxByte		;Nächstes Byte senden.

			jsr	Pause_18		;Warteschleife.
			beq	DATA_OUT_LOW		;Unbedingter Sprung, Ende...

;*** Job-daten von C64 empfangen.
:GET_UserJobData	ldy	#$01
			jsr	GET_Bytes
			sta	$71
			tay
			jsr	GET_Bytes
			ldy	$71
			rts

;*** Daten von C64 empfangen.
:GET_Bytes		jsr	WaitMotorOff		;Warten bis Motor abgeschaltet ist.

			jsr	Pause_16		;Warteschleife.

			lda	#$00
			sta	$70			;Prüfsumme löschen.
::51			eor	$70			;Neue Prüfsumme berechnen.
			sta	$70

			jsr	Pause_16		;Warteschleife.

			lda	#$04
::52			bit	VIA1_PortB_InOut	;Warten bis COCK_IN vom C64 auf
			beq	:52			;LOW gesetzt wird.

			jsr	Pause_14		;Warteschleife.

			lda	VIA1_PortB_InOut	;Byte über ser. Bus einlesen.
			jsr	Pause_16		;Warteschleife.
			asl
			ora	VIA1_PortB_InOut
			php
			plp
			nop
			nop
			and	#$0f
			tax

			lda	VIA1_PortB_InOut
			jsr	Pause_10		;Warteschleife.
			asl
			ora	VIA1_PortB_InOut
			and	#$0f			;Low -Nibble ermitteln und mit
			ora	l030f,x			;High-Nibble verknüpfen.
			dey
			sta	($73),y			;Byte in Speicher übertragen.
			bne	:51

:DATA_OUT_LOW		ldx	#$02			;DATA_OUT auf LOW setzen und
			stx	VIA1_PortB_InOut	;Übertragung beenden.

			jsr	Pause_20		;Warten bis C64 Signal erkannt hat.

			nop
:Pause_20		nop				;Pause: 20 Taktzyklen.
:Pause_18		nop				;Pause: 18 Taktzyklen.
:Pause_16		nop				;Pause: 16 Taktzyklen.
:Pause_14		nop				;Pause: 14 Taktzyklen.
			nop
:Pause_10		nop				;Pause: 10 Taktzyklen.
:Pause_8		nop				;Pause:  8 Taktzyklen.
:Pause_6		rts				;Pause:  6 Taktzyklen.

;*** Prüfen ob Laufwerksmotor abgeschaltet werden kann.
:TestMotorOff		dec	$48
			bne	WaitMotorOff
			jsr	StopDiskMotor

;*** Warten bis Motor abgeschaltet ist.
:WaitMotorOff		lda	#$c0
			sta	VIA1_Timer1_High

::51			bit	VIA1_Timer1_High
			bpl	TestMotorOff

			lda	#$04
			bit	VIA1_PortB_InOut
			bne	:51
			lda	#$00
			sta	VIA1_PortB_InOut
			rts

;*** TurboDOS aktivieren.
.TD_Start		php
			sei
			lda	$49
			pha

			ldy	#$00
::51			dey
			bne	:51
			ldy	#$00
::52			dey
			bne	:52

			jsr	SetDrvTo1541Mode

			lda	VIA1_DrvControlB
			ora	#$20
			sta	VIA1_DrvControlB

			jsr	Wait_70

			lda	#$00
			sta	VIA1_PortB_InOut
			lda	#$1a
			sta	VIA1_PortB_Data

			jsr	DATA_OUT_LOW

			lda	#$04
::53			bit	VIA1_PortB_InOut
			beq	:53

;*** TurboDOS-Mainloop.
;    Diese Routine wird nicht verlassen und läuft so lange ab,
;    bis ExitTurbo aufgerufen wird. Daher "hängt" das Laufwerk wenn der
;    C64 ins BASIC abstürzt.
:TD_MainLoop		jsr	TurnOffLED

			lda	#> USER_JOB
			sta	$74
			lda	#< USER_JOB
			sta	$73

			jsr	GET_UserJobData		;Job-Daten einlesen.

			lda	USER_TRACK
			sta	Flag_HeadOnTrack
			cmp	#$24			;Track #36 bis #70 ?
			bcs	:51			;Ja, weiter...

			lda	VIA1_DrvControlB	;Seite #1 aktivieren.
			and	#$fb
			sta	VIA1_DrvControlB
			jmp	:52

::51			sec				;Kopf-Position berechnen und
			sbc	#$23			;zwischenspeichern.
			sta	Flag_HeadOnTrack

			lda	VIA1_DrvControlB	;Seite #2 aktivieren.
			ora	#$04
			sta	VIA1_DrvControlB

::52			jsr	TurnOnLED		;Laufwerks-LED einschalten.

			lda	#> $0700		;Zeiger auf Datenspeicher setzen.
			sta	$74
			lda	#< $0700
			sta	$73
			lda	#> TD_MainLoop -1
			pha
			lda	#< TD_MainLoop -1
			pha
			jmp	(USER_JOB)		;Job-Routine ausführen.

;*** TurboDOS abschalten.
.TD_Stop		jsr	WaitMotorOff

			lda	#$00
			sta	$33

			jsr	TurnOffMotor

			lda	#$ec
			sta	VIA2_PCR_Control

			jsr	SetDrvTo1541Mode

			pla
			pla
			pla
			sta	$49
			plp
			rts

;*** Laufwerk auf 1541-Modus umschalten.
:SetDrvTo1541Mode	lda	VIA1_DrvControlB
			and	#$df
			sta	VIA1_DrvControlB
			jsr	Wait_70
			jsr	SetMode1541		;Laufwerk auf 1541-Modus umschalten.
			lda	$02af			;Flag setzen: "Modus 1541 aktiv".
			ora	#$80
			sta	$02af			;Neuen Betriebsmodus speichern.
			rts

;*** Neue Geräteadresse festlegen.
.TD_NewDrvAdr		lda	USER_TRACK
			sta	$77
			eor	#$60
			sta	$78
			rts

;*** Sektor an C64 übertragen.
.TD_RdSekData		jsr	Job_Read
			ldy	#$00
			jsr	SEND_DataBlock
			jmp	TD_SendStatus

;*** Laufwerks-LED ausschalten.
:TurnOffLED		lda	#$f7
			bne	SetVIA2_DrvCtrlA

;*** Laufwerks-LED einschalten.
:TurnOnLED		lda	#$08
			ora	VIA2_DrvControlA
			bne	SetDriveControl

;*** Laufwerksmotor anhalten.
:StopDiskMotor		lda	#$00
			sta	$20
			lda	#$ff
			sta	$3e
			lda	#$fb
:SetVIA2_DrvCtrlA	and	VIA2_DrvControlA
			jmp	SetDriveControl

;*** SpeedFlag für aktuellen Track einstellen.
:SetSpeedFlag		lda	VIA2_DrvControlA	;Bitrate am Tonkopf setzen.
			and	#$9f			;(SpeedFlag).
			ora	TrackSpeedMode,x
:SetDriveControl	sta	VIA2_DrvControlA
			rts

;*** Speedflags für Disketten-Bereiche #1 bis #4.
:TrackSpeedMode		b $00,$20,$40,$60

;*** Schreib/Lese-Kopf auf Track positionieren.
:PosHeadOnTrack		jsr	StartDiskMotor		;Laufwerksmotor starten.

			lda	$22			;Adresse in Track-Speicher ?
			beq	:51			;Nein, weiter...

			ldx	$00			;JobCode-Ergebnis einlesen.
			dex				;Fehler aufgetreten ?
			beq	:52			;Nein, weiter...

::51			lda	$12			;Aktuelle Disketten-ID speichern.
			pha
			lda	$13
			pha
			jsr	TestCurDisk
			pla				;Disketten-ID zurückschreiben.
			sta	$13
			tax
			pla
			sta	$12

			ldy	$00			;Job-Ergebnis einlesen und
			cpy	#$01			;Fehler aufgetreten ?
			bne	:55			;Ja, Abbruch...

			cpx	$17			;Disketten-ID vergleichen.
			bne	Err_WrongDiskID		; => Fehler: "Falsche Disk-ID".
			cmp	$16
			bne	Err_WrongDiskID		; => Fehler: "Falsche Disk-ID".

			lda	#$00
::52			pha
			lda	$22			;Aktuelle Track-Adresse einlesen.
			ldx	#$ff
			sec
			sbc	Flag_HeadOnTrack
			beq	:54
			bcs	:53
			eor	#$ff
			adc	#$01
			ldx	#$01
::53			jsr	Move_RW_Head
			lda	Flag_HeadOnTrack	;Track für aktuellen Jobcode
			sta	$22			;zwischenspeichern.
			jsr	GetMaxSek		;Anzahl Sektoren/Track einlesen.
::54			pla
::55			rts

;*** Fehler: Falsche Disketten-ID.
:Err_WrongDiskID	lda	#$0b
			sta	$00
			rts

;*** Steppermotor bewegen.
:Move_RW_Head		stx	$4a			;Bewegungsrichtung speichern.
			asl				;Anzahl Halbspuren berechnen und
			tay				;als Zähler in yReg kopieren.
			lda	VIA2_DrvControlA
			and	#$fe
			sta	$70
			lda	#$2f
			sta	$71

::51			lda	$70
			clc
			adc	$4a
			eor	$70
			and	#$03
			eor	$70
			sta	$70
			sta	VIA2_DrvControlA

			lda	$71
			jsr	MoveRW_Wait
			cpy	#$06
			bcc	:52
			cmp	#$1b
			bcc	:53
			sbc	#$03
			bne	:53
::52			cmp	#$2f
			bcs	:53
			adc	#$04
::53			sta	$71
			dey				;Tonkopf positioniert ?
			bne	:51			;Nein, weiter...

			lda	#$96			;Warteschleife.

;*** Warten bis Tonkopf positioniert.
:MoveRW_Wait		pha
			sta	VIA1_Timer1_High
::51			lda	VIA1_Timer1_High
			bne	:51
			pla
			rts

;***  Neue Diskette öffnen.
.TD_NewDisk		jsr	StartDiskMotor

;*** Diskette im aktuellen Laufwerk testen.
:TestCurDisk		ldx	$00
			dex
			beq	SetTrackData

			ldx	#$ff
			lda	#$01
			jsr	Move_RW_Head

			ldx	#$01
			txa
			jsr	Move_RW_Head

			lda	#$ff
			jsr	MoveRW_Wait
			jsr	MoveRW_Wait

;*** Track-Adresse testen, Anzahl Sektoren/Track berechnen und
;    SpeedFlags setzen.
:SetTrackData		lda	#$04
			sta	$70

::51			jsr	Job_FindSek

			lda	$18			;Letzte gelesene Track-Adresse.
			cmp	#$24			;War Adresse gültig ?
			bcc	:52			;Ja, weiter...
			sbc	#$23
::52			sta	$22

			ldy	$00
			dey
			beq	GetMaxSek
			dec	$70
			bmi	:53

			ldx	$70
			jsr	SetSpeedFlag
			sec
			bcs	:51

::53			lda	#$00
			sta	$22
			rts

;*** Anzahl Sektoren auf Spur einlesen.
:GetMaxSek		jsr	GetMaxSekOnTrack
			sta	$43
			jmp	SetSpeedFlag

;*** Job initialisieren.
:InitJob		tax
			bit	Flag_MotorAktiv		;Ist Motor abgeschaltet ?
			bpl	:51			;Ja, weiter...
			jsr	WaitMotorAktiv
			ldx	#$00			;Flag "Motor abgeschaltet" setzen.
			stx	Flag_MotorAktiv

::51			cpx	$22			;Ist Tonkopf auf Track ?
			beq	:53			;Ja, Ende...

			jsr	SetTrackData		;Track-Daten setzen.
			cmp	#$01			;OK ?
			bne	:53			;Nein, Fehler...

			ldy	$19			;Sektor-Adresse testen.
			iny
			cpy	$43			;Adresse gültig ?
			bcc	:52			;Ja, weiter...
			ldy	#$00			;Zeiger auf Sektor #0 setzen.
::52			sty	$19			;Sektor-Adresse speichern.
			lda	#$00			;JobCode löschen.
			sta	$45
			lda	#> $0018		;Zeiger auf Track/Sektor-Tabelle.
			sta	$33
			lda	#< $0018
			sta	$32
			jsr	ResetJobData
::53			rts

;*** Sektor von C64 empfangen und auf Diskette schreiben.
.TD_WrSekData		jsr	PosHeadOnTrack		;Kopf auf Spur positionieren.
			ldx	$00			;Fehlerstatus einlesen.
			dex				;Fehler aufgetreten ?
			bne	:51			;Ja, Abbruch...
			jsr	InitJob			;Job initialisieren.

::51			ldy	#$00
			jsr	GET_Bytes
			eor	$70
			sta	$3a

			ldy	$00
			dey
			bne	:52

			lda	VIA2_DrvControlA	;Schreibschutz testen.
			and	#$10
			bne	:52
			lda	#$08			;Fehler: "Write Protect on Disk".
			sta	$00

::52			jsr	TD_SendStatus
			lda	#$10			;JobCode für "Sektor schreiben".
			jmp	Job_Write

;*** Sektor von Diskette einlesen.
:Job_Read		jsr	PosHeadOnTrack
			lda	#$00
:Job_Write		ldx	$00			;Fehlerstatus einlesen.
			dex				;Fehler aufgetreten ?
			beq	DoNewJob		;Nein, weiter...
			rts

;*** Sektor auf Diskette suchen.
:Job_FindSek		lda	#$30			;Jobcode für "Sektor suchen".
:DoNewJob		sta	$45			;Jobcode speichern.
			lda	#> USER_TRACK
			sta	$33
			lda	#< USER_TRACK
			sta	$32

;*** Einsprung mit JobCode in ":$45" = $00:
;    Reset der Systemregister.
:ResetJobData		lda	#$07			;Zeiger auf Datenpuffer #7 = $0700.
			sta	$31
			tsx				;Stackpointer zwischenspeichern.
			stx	$49

			ldx	#$01
			stx	$00
			dex
			stx	$02ab			;Zähler für Anlaufzeit des Motors.
			stx	$02fe			;Parameter für Kopftransport.
			stx	$3f

			lda	#$ee
			sta	VIA2_PCR_Control

			lda	$45			;Jobcode wieder einlesen.
			cmp	#$10			;Sektor schreiben ?
			beq	WrSekOnDisk		;Ja, weiter...
			cmp	#$30			;Sektor suchen ?
			beq	:51			;Ja, weiter...
			jmp	ExecJobCode
::51			jmp	FindCurTrack

;*** Sektor auf Diskette schreiben.
:WrSekOnDisk		jsr	ConvBinary2GCR		;Puffer von Binär nach GCR wandeln.
			jsr	FindSekHeader		;Sektorheader suchen.

			ldy	#$09			;SYNC-Zeichen, Headerblockzeichen,
::51			bit	VIA1_DrvControlB	;Checksumme und Sektor/Track-Adr.
			bmi	:51			;überlesen.
			bit	VIA2_DrvControlA
			dey
			bne	:51

			lda	#$ff			;Tonkopf auf "schreiben" umstellen.
			sta	VIA2_PortA_Data
			lda	VIA2_PCR_Control
			and	#$1f
			ora	#$c0
			sta	VIA2_PCR_Control
			lda	#$ff
			ldy	#$05
			sta	VIA2_PortA_RW

::52			bit	VIA1_DrvControlB	;Datenblock-Header übergehen.
			bmi	:52
			bit	VIA2_DrvControlA
			dey
			bne	:52

			ldy	#$bb			;Datenblock Teil #1 auf
::53			lda	$0100,y			;Diskette schreiben.
::54			bit	VIA1_DrvControlB
			bmi	:54
			sta	VIA2_PortA_RW
			iny
			bne	:53

::55			lda	($30),y			;Datenblock Teil #2 auf
::56			bit	VIA1_DrvControlB	;Diskette schreiben.
			bmi	:56
			sta	VIA2_PortA_RW
			iny
			bne	:55

::57			bit	VIA1_DrvControlB	;Warten bis Schreibvorgang beendet.
			bmi	:57

			lda	VIA2_PCR_Control	;Tonkopf abstellen.
			ora	#$e0
			sta	VIA2_PCR_Control
			lda	#$00
			sta	VIA2_PortA_Data
			sta	$50

			lda	#$01			;Flag: "Kein Fehler..."
			sta	$00
			rts

;*** Diskettenmotor starten.
:StartDiskMotor		lda	$20			;Motor-Status einlesen.
			and	#%00100000		;Ist Motor bereits aktiv ?
			bne	MotorAktivDelay		;Ja, weiter...

			jsr	TurnOnMotor

			lda	#$ff
			sta	Flag_MotorAktiv

;*** Warten bis Motor aktiv ist.
:WaitMotorAktiv		ldy	#$c8			;Warten bis Motor konstant läuft.
::51			dex
			bne	:51
			dey
			bne	:51

			sty	$3e			;Flag für "Laufwerk aktiv" setzen.
			lda	#%00100000		;Flag für "Motor läuft" setzen.
			sta	$20

;*** nachlaufzeit für Motor setzen.
:MotorAktivDelay	lda	#$ff			;Zähler für Nachlaufzeit des
			sta	$48			;Motors setzen.
			rts

;*** Variablen.
:Flag_MotorAktiv	b $00
:Flag_HeadOnTrack	b $00
:USER_JOB		w $0000
:USER_TRACK		b $00
:USER_SEKTOR		b $00
