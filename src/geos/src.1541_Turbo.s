; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
:ExecJobCode		= $f4ca
:FindCurTrack		= $f3b1
:GetBufferCRC		= $f5e9
:ConvBinary2GCR		= $f78f
:FindSekHeader		= $f510
:GetMaxSekOnTrack	= $f24b
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
.l0320			ldy	#$00
			jsr	l033a

.l0325			ldy	#$00
			sty	$73
			sty	$74
			iny
			sty	$71

			ldy	#$00
			jsr	WaitMotorOff
			lda	$71
			jsr	SendCurByte

			ldy	$71
:l033a			jsr	WaitMotorOff

:SendNxByte		dey
			lda	($73),y
:SendCurByte		tax
			lsr
			lsr
			lsr
			lsr
			sta	$70
			txa
			and	#$0f
			tax
			lda	#$04
			sta	VIA1_PortB_InOut
:l0350			bit	VIA1_PortB_InOut
			beq	l0350
			bit	VIA1_PortB_InOut
			bne	l035a
:l035a			bne	l035c
:l035c			stx	VIA1_PortB_InOut
			txa
			rol
			and	#$0f
			sta	VIA1_PortB_InOut
			ldx	$70
			lda	l0300,x
			sta	VIA1_PortB_InOut
			nop
			rol
			and	#$0f
			cpy	#$00
			sta	VIA1_PortB_InOut
			bne	SendNxByte
			beq	StopTurboData

:l037b			ldy	#$01
			jsr	TurboBytes_GET
			sta	$71
			tay
			jsr	TurboBytes_GET
			ldy	$71
			rts

;*** Bytes über ser. Bus einlesen.
:TurboBytes_GET		jsr	WaitMotorOff

:GetNxByte		pha
			pla
			lda	#$04
::51			bit	VIA1_PortB_InOut
			beq	:51
			nop
			nop
			nop
			lda	VIA1_PortB_InOut
			asl
			nop
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
			and	#$0f
			ora	l0310,x
			dey
			sta	($73),y
			bne	GetNxByte

:StopTurboData		ldx	#$02
			stx	VIA1_PortB_InOut
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
.l03e2			php
			sei
			lda	$49
			pha
			lda	VIA1_DrvControlB
			and	#$df
			sta	VIA1_DrvControlB
			ldy	#$00
:l03f1			dey
			bne	l03f1

			jsr	StopTurboData

			lda	#$04
:l03f9			bit	VIA1_PortB_InOut
			beq	l03f9

:l03fe			jsr	TurnOnLED

			lda	#> l064a
			sta	$74
			lda	#< l064a
			sta	$73
			jsr	l037b

			jsr	TurnOffLED

			lda	#> $0700
			sta	$74
			lda	#< $0700
			sta	$73
			lda	#> l03fe -1
			pha
			lda	#< l03fe -1
			pha
			jmp	(l064a)

;*** TurboDOS-Routine deaktivieren.
.l0420			jsr	WaitMotorOff

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
.l0439			lda	l064c			;Neue Geräteadresse setzen.
			sta	$77
			eor	#$60
			sta	$78
			rts

:l0443			jsr	StartDiskMotor

			lda	$22
			beq	l044f

			ldx	$00
			dex
			beq	l046f

:l044f			lda	$12
			pha
			lda	$13
			pha
			jsr	l04df
			pla
			sta	$13
			tax
			pla
			sta	$12

			ldy	$00
			cpy	#$01
			bne	l048e
			cpx	$17
			bne	Err_WrongDiskID
			cmp	$16
			bne	Err_WrongDiskID
			lda	#$00
:l046f			pha
			lda	$22
			ldx	#$ff
			sec
			sbc	l064c
			beq	l048d
			bcs	l0482
			eor	#$ff
			adc	#$01
			ldx	#$01
:l0482			jsr	l0494
			lda	l064c
			sta	$22
			jsr	GetMaxSek
:l048d			pla
:l048e			rts

:Err_WrongDiskID	lda	#$0b			;Fehler: "Falsche Disk_ID".
			sta	$00
			rts

:l0494			stx	$4a
			asl
			tay
			lda	VIA2_DrvControlA
			and	#$fe
			sta	$70
			lda	#$1e
			sta	$71
:l04a3			lda	$70
			clc
			adc	$4a
			eor	$70
			and	#$03
			eor	$70
			sta	$70
			sta	VIA2_DrvControlA
			lda	$71
			jsr	l04d3
			lda	$71
			cpy	#$05
			bcc	l04c6
			cmp	#$11
			bcc	l04cc
			sbc	#$02
			bne	l04cc
:l04c6			cmp	#$1c
			bcs	l04cc
			adc	#$04
:l04cc			sta	$71
			dey
			bne	l04a3
			lda	#$4b
:l04d3			sta	VIA1_Timer1_High
:l04d6			lda	VIA1_Timer1_High
			bne	l04d6
			rts

;*** Diskette initialisieren.
.l04dc			jsr	StartDiskMotor

:l04df			ldx	$00
			dex
			beq	l04f6

			ldx	#$ff
			lda	#$01
			jsr	l0494

			ldx	#$01
			txa
			jsr	l0494

			lda	#$ff
			jsr	l04d3

:l04f6			lda	#$04
			sta	$70

:l04fa			jsr	l0599

			ldx	$18
			stx	$22

			ldy	$00
			dey
			beq	GetMaxSek_X
			dec	$70
			bmi	l0512

			ldx	$70
			jsr	SetSpeedFlag
			sec
			bcs	l04fa

:l0512			lda	#$00
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
:TurnOnLED		lda	#$f7
			bne	l053e

;*** Laufwerks-LED einschalten.
:TurnOffLED		lda	#$08
			ora	VIA2_DrvControlA
			bne	SetDriveControl

;*** Laufwerksmotor anhalten.
:StopDiskMotor		lda	#$00
			sta	$20
			lda	#$ff
			sta	$3e
			lda	#$fb
:l053e			and	VIA2_DrvControlA
			jmp	SetDriveControl

:TrackSpeedMode		b $00,$20,$40,$60

:l0548			tax
			bit	$20			;Ist Laufwerk bereits ?
			bpl	l0556			;Nein, weiter...

			jsr	l063b
			lda	#$20
			sta	$20

			ldx	#$00
:l0556			cpx	$22
			beq	l057b
			jsr	l04f6
			cmp	#$01
			bne	l057b
			ldy	$19
			iny
			cpy	$43
			bcc	l056a
			ldy	#$00
:l056a			sty	$19
			lda	#$00
			sta	$45
			lda	#$00
			sta	$33
			lda	#$18
			sta	$32
			jsr	l05a5
:l057b			rts

;*** Sektor auf Diskette schreiben.
.l057c			jsr	l0443
			ldx	$00
			dex
			bne	l0587
			jsr	l0548

:l0587			jsr	l037b
			lda	#$10
			bne	l0593

;*** Sektor auf Diskette vergleichen.
.l058e			jsr	l0443
			lda	#$00
:l0593			ldx	$00
			dex
			beq	l059b
			rts

:l0599			lda	#$30
:l059b			sta	$45			;Jobcode speichern.
			lda	#$06
			sta	$33
			lda	#$4c
			sta	$32
:l05a5			lda	#$07
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
			beq	l05c5			;Ja, weiter...
			jmp	ExecJobCode		;Jobcode ausführen.
:l05c5			jmp	FindCurTrack		;Tonkopf auf Spur positionieren.

;*** Sektor nach GCR wandeln und auf Diskette schreiben.
:WrSekOnDisk		jsr	GetBufferCRC		;Prüfsumme des Puffers berechnen.
			sta	$3a

			lda	VIA2_DrvControlA	;Schreibschutz testen.
			and	#$10
			bne	l05d8
			lda	#$08			;Fehler: "Write Protect on Disk".
			bne	l062f			;Abbruch.

:l05d8			jsr	ConvBinary2GCR		;Puffer von Binär nach GCR wandeln.
			jsr	FindSekHeader		;Sektorheader suchen.

			ldx	#$09			;SYNC-Zeichen, Headerblockzeichen,
:l05e0			bvc	l05e0			;Checksumme und Sektor/Track-Adr.
			clv				;überlesen.
			dex
			bne	l05e0

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
:l05fd			bvc	l05fd			;Datenblock-Header übergehen.
			clv
			dex
			bne	l05fd

			ldy	#$bb			;Datenblock Teil #1 auf
:l0605			lda	$0100,y			;Diskette schreiben.
:l0608			bvc	l0608
			clv
			sta	VIA2_PortA_RW
			iny
			bne	l0605

:l0611			lda	($30),y			;Datenblock Teil #2 auf
:l0613			bvc	l0613			;Diskette schreiben.
			clv
			sta	VIA2_PortA_RW
			iny
			bne	l0611
:l061c			bvc	l061c			;Warten bis Schreibvorgang beendet.

			lda	VIA2_PCR_Control	;Tonkopf abstellen.
			ora	#$e0
			sta	VIA2_PCR_Control
			lda	#$00
			sta	VIA2_PortA_Data
			sta	$50

			lda	#$01			;Flag für "Kein Fehler"...
:l062f			sta	$00
			rts

;*** Disketten-Motor starten.
:StartDiskMotor		lda	$20			;Motor-Status einlesen.
			and	#$20			;Ist Motor bereits aktiv ?
			bne	l0645			;Ja, weiter...

			jsr	TurnOnMotor		;Motor einschalten.

:l063b			ldy	#$80			;Warten bis Motor konstant läuft.
:l063d			dex
			bne	l063d
			dey
			bne	l063d

			sty	$3e			;Flag für "Laufwerk aktiv" setzen.

:l0645			lda	#$ff			;Zähler für Nachlaufzeit des
			sta	$48			;motors initialisieren.
			rts

:l064a			b $00,$00
:l064c			b $00,$00
