; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
:GetMaxSekOnTrack	= $f24b
:FindCurTrack		= $f3b1
:ExecJobCode		= $f4ca
:FindSekHeader		= $f510
:GetBufferCRC		= $f5e9
:ConvBinary2GCR		= $f78f
:TurnOnMotor		= $f97e
:TurnOffMotor		= $f98f
:VIA1_PortB_InOut	= $1800
:VIA1_Timer1_High	= $1805
:VIA1_DrvControlB	= $180f
:VIA2_DrvControlA	= $1c00
:VIA2_PortA_RW		= $1c01
:VIA2_PortA_Data	= $1c03
:VIA2_PCR_Control	= $1c0c
endif

			o $0300
			n "obj.Turbo41"

;*** High und Low-Nibbles für Datenübertragung im TurboMode.
:l0300			b $0f,$07,$0d,$05,$0b,$03,$09,$01
			b $0e,$06,$0c,$04,$0a,$02,$08,$00
:l0310			b $00,$80,$20,$a0,$40,$c0,$60,$e0
			b $10,$90,$30,$b0,$50,$d0,$70,$f0

;*** Bytes über ser. Bus senden.
.TD_RdSekData		ldy	#$00
			jsr	SEND_DataBlock

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

;*** Einsprung: datenblock (256 Bytes) an C64 senden.
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
			bit	VIA1_PortB_InOut
			bne	:52
::52			bne	:53
::53			stx	VIA1_PortB_InOut
			txa
			rol
			and	#$0f
			sta	VIA1_PortB_InOut
			ldx	$70
			lda	l0300,x			;Übertragungsbyte einlesen und
			sta	VIA1_PortB_InOut	;Byte senden.
			nop				;Warteschleife.
			rol
			and	#$0f
			cpy	#$00			;Letztes Byte gesendet ?
			sta	VIA1_PortB_InOut	;Aktuelles High-Nibble senden.
			bne	SEND_GetNxByte		;Nächstes Byte senden.
			beq	DATA_OUT_LOW		;Unbedingter Sprung, Ende...

;*** Job-Daten vom C64 empfangen.
:GET_UserJobData	ldy	#$01
			jsr	GET_Bytes
			sta	$71
			tay
			jsr	GET_Bytes
			ldy	$71
			rts

;*** Bytes über ser. Bus einlesen.
:GET_Bytes		jsr	WaitMotorOff		;Warten bis Motor abgeschaltet ist.

:GetNxByte		pha				;Warteschleife.
			pla

			lda	#$04
::51			bit	VIA1_PortB_InOut	;Warten bis CLOCK_IN vom C64 auf
			beq	:51			;LOW gesetzt wird.

			nop				;Warteschleife.
			nop
			nop

			lda	VIA1_PortB_InOut	;Byte über ser. Bus einlesen.
			asl
			nop				;Warteschleife.
			nop
			nop
			nop
			ora	VIA1_PortB_InOut
			and	#$0f
			tax
			nop
			nop
			nop
			lda	VIA1_PortB_InOut
			asl
			pha
			lda	$70
			pla
			ora	VIA1_PortB_InOut
			and	#$0f			;LOW -Nibble ermitteln und mit
			ora	l0310,x			;High-Nibble verknüpfen.
			dey
			sta	($73),y			;Byte in Speicher übertragen.
			bne	GetNxByte

:DATA_OUT_LOW		ldx	#$02			;DATA_OUT auf LOW setzen und
			stx	VIA1_PortB_InOut	;Übertragung beenden.
			rts

;*** Prüfen ob Motor abgeschaltet werden kann.
:TestMotorOff		dec	$48			;Nachlaufzeit des Motors abgelaufen?
			bne	WaitMotorOff		;Nein, weiter...
			jsr	StopDiskMotor		;Motor abschalten.

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

			lda	VIA1_DrvControlB
			and	#$df
			sta	VIA1_DrvControlB

			ldy	#$00
::51			dey
			bne	:51

			jsr	DATA_OUT_LOW

			lda	#$04
::52			bit	VIA1_PortB_InOut
			beq	:52

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

			jsr	TurnOnLED		;Laufwerks-LED einschalten.

			lda	#> $0700		;Zeiger auf Datenspeicher setzen.
			sta	$74
			lda	#< $0700
			sta	$73
			lda	#> TD_MainLoop -1
			pha
			lda	#< TD_MainLoop -1
			pha
			jmp	(USER_JOB)		;Job-Routine ausführen.

;*** TurboDOS-Routine deaktivieren.
.TD_Stop		jsr	WaitMotorOff

			lda	#$00
			sta	$33
			sta	VIA1_PortB_InOut

			jsr	TurnOffMotor		;Laufwerksmotor abschalten.

			lda	#$ec
			sta	VIA2_PCR_Control

			pla
			pla
			pla
			sta	$49
			plp
			rts

;*** Neue Geräteadresse setzen.
.TD_NewDrvAdr		lda	USER_TRACK		;Neue Geräteadresse setzen.
			sta	$77
			eor	#$60
			sta	$78
			rts

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
			sbc	USER_TRACK
			beq	:54
			bcs	:53
			eor	#$ff
			adc	#$01
			ldx	#$01
::53			jsr	Move_RW_Head
			lda	USER_TRACK		;Track für aktuellen Jobcode
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
			lda	#$1e
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
			lda	$71
			cpy	#$05
			bcc	:52
			cmp	#$11
			bcc	:53
			sbc	#$02
			bne	:53
::52			cmp	#$1c
			bcs	:53
			adc	#$04
::53			sta	$71
			dey				;Tonkopf positioniert ?
			bne	:51			;Nein, weiter...

			lda	#$4b			;Warteschleife.

;*** Warten bis TonKopf positioniert.
:MoveRW_Wait		sta	VIA1_Timer1_High
::51			lda	VIA1_Timer1_High
			bne	:51
			rts

;*** Diskette initialisieren.
.TD_NewDisk		jsr	StartDiskMotor

;*** Diskette in aktuellem Laufwerk testen.
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

;*** Track-Adresse testen, Anzahl Sektoren/Track berechnen und
;    SpeedFlags setzen.
:SetTrackData		lda	#$04
			sta	$70

::51			jsr	Job_FindSek

			ldx	$18
			stx	$22

			ldy	$00
			dey
			beq	GetMaxSek_X
			dec	$70
			bmi	:52

			ldx	$70
			jsr	SetSpeedFlag
			sec
			bcs	:51

::52			lda	#$00
			sta	$22
			rts

;*** Anzahl Sektoren/Spur einlesen.
:GetMaxSek_X		txa
:GetMaxSek		jsr	GetMaxSekOnTrack	;Anzahl Sektoren/Spur einlesen.
			sta	$43			;Anzahl merken.

;*** Speedflag für aktuelle Spur einstellen.
:SetSpeedFlag		lda	VIA2_DrvControlA	;Bitrate am Tonkopf setzen.
			and	#%10011111		;(Speedflag).
			ora	TrackSpeedMode,x
:SetDriveControl	sta	VIA2_DrvControlA
			rts

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

;*** SpeedFlags für Disketten-Bereiche #1 bis #4.
:TrackSpeedMode		b $00,$20,$40,$60

;*** Job initialisieren.
:InitJob		tax
			bit	$20			;Ist Motor abgeschaltet ?
			bpl	:51			;Ja, weiter...
			jsr	WaitMotorAktiv
			lda	#$20			;Flag "Motor abgeschaltet setzen".
			sta	$20
			ldx	#$00

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

;*** Sektor auf Diskette schreiben.
.TD_WrSekData		jsr	PosHeadOnTrack
			ldx	$00
			dex
			bne	:51
			jsr	InitJob

::51			jsr	GET_UserJobData
			lda	#$10
			bne	Job_Write

;*** Sektor auf Diskette vergleichen.
.TD_VerSekData		jsr	PosHeadOnTrack
			lda	#$00
:Job_Write		ldx	$00
			dex
			beq	DoNewJob
			rts

;*** Sektor auf Diskette suchen.
:Job_FindSek		lda	#$30
:DoNewJob		sta	$45			;Jobcode speichern.
			lda	#$06
			sta	$33
			lda	#$4c
			sta	$32

;*** Einsprung mit JobCode in ":$45" = $00:
;    Reset der Systemregister.
:ResetJobData		lda	#$07
			sta	$31
			tsx				;Stackpointer zwischenspeichern.
			stx	$49

			ldx	#$01
			stx	$00
			dex
			stx	$3f

			lda	#$ee
			sta	VIA2_PCR_Control

			lda	$45
			cmp	#$10			;Sektor schreiben ?
			beq	WrSekOnDisk		;Ja, weiter...
			cmp	#$30			;Sektor suchen ?
			beq	:51			;Ja, weiter...
			jmp	ExecJobCode		;Jobcode ausführen.
::51			jmp	FindCurTrack		;Tonkopf auf Spur positionieren.

;*** Sektor nach GCR wandeln und auf Diskette schreiben.
:WrSekOnDisk		jsr	GetBufferCRC		;Prüfsumme des Puffers berechnen.
			sta	$3a

			lda	VIA2_DrvControlA	;Schreibschutz testen.
			and	#$10
			bne	:51
			lda	#$08			;Fehler: "Write Protect on Disk".
			bne	:59			;Abbruch.

::51			jsr	ConvBinary2GCR		;Puffer von Binär nach GCR wandeln.
			jsr	FindSekHeader		;Sektorheader suchen.

			ldx	#$09			;SYNC-Zeichen, Headerblockzeichen,
::52			bvc	:52			;Checksumme und Sektor/Track-Adr.
			clv				;überlesen.
			dex
			bne	:52

			lda	#$ff			;Tonkopf auf "schreiben" umschalten.
			sta	VIA2_PortA_Data
			lda	VIA2_PCR_Control
			and	#$1f
			ora	#$c0
			sta	VIA2_PCR_Control
			lda	#$ff
			ldx	#$05
			sta	VIA2_PortA_RW

			clv
::53			bvc	:53			;Datenblock-Header übergehen.
			clv
			dex
			bne	:53

			ldy	#$bb			;Datenblock Teil #1 auf
::54			lda	$0100,y			;Diskette schreiben.
::55			bvc	:55
			clv
			sta	VIA2_PortA_RW
			iny
			bne	:54

::56			lda	($30),y			;Datenblock Teil #2 auf
::57			bvc	:57			;Diskette schreiben.
			clv
			sta	VIA2_PortA_RW
			iny
			bne	:56
::58			bvc	:58			;Warten bis Schreibvorgang beendet.

			lda	VIA2_PCR_Control	;Tonkopf abstellen.
			ora	#$e0
			sta	VIA2_PCR_Control
			lda	#$00
			sta	VIA2_PortA_Data
			sta	$50

			lda	#$01			;Flag für "Kein Fehler"...
::59			sta	$00
			rts

;*** Disketten-Motor starten.
:StartDiskMotor		lda	$20			;Motor-Status einlesen.
			and	#$20			;Ist Motor bereits aktiv ?
			bne	MotorAktivDelay		;Ja, weiter...

			jsr	TurnOnMotor		;Motor einschalten.

;*** Warten bis Motor aktiv ist.
:WaitMotorAktiv		ldy	#$80			;Warten bis Motor konstant läuft.
::51			dex
			bne	:51
			dey
			bne	:51

			sty	$3e			;Flag für "Laufwerk aktiv" setzen.

;*** Nachlaufzeit für Motor setzen.
:MotorAktivDelay	lda	#$ff			;Zähler für Nachlaufzeit des
			sta	$48			;motors initialisieren.
			rts

;*** Variablen.
:USER_JOB		w $0000
:USER_TRACK		b $00
:USER_SEKTOR		b $00
