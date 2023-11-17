; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;


;***  D64-Format entpacken.
:D64toDISK		jsr	GotoFirstMenu		;Hauptmenü aktivieren.
			jsr	ClrScreen		;Bildschirm löschen.

::100			LoadW	r0,DlgSlctTgtDrv
			jsr	DoDlgBox

			lda	sysDBData
			bmi	:101
			jmp	StartMenü

::101			and	#%01111111
			tay
			lda	driveType-8,y
			and	#%00000111
			cmp	#DRV_1541
			beq	:102
			cmp	#DRV_1571
			bne	:101a

			tya
			jsr	SetDevice
			jsr	NewOpenDisk

			ldy	curDrive
			lda	curDirHead+3
			beq	:102

::101a			LoadW	r5,No41DrvTxt
			jsr	ErrDiskError
			jmp	:100

::102			sty	TargetDrive

			jsr	GetSekOfD64File

;*** Verzeichnis einlesen.
:DeCodeD64Disk		lda	SourceDrive
			jsr	SetDevice
			jsr	EnterTurbo
			jsr	InitForIO

			LoadW	r15,diskBlkBuf
			ldx	#$12
			lda	#$00
			jsr	PosToSektor
			jsr	GetSektor
			jsr	DoneWithIO

;*** Bildschirm-Informationen ausgeben.
			jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
:D64_a1			w	$0040
			b	$58
			b	RECTANGLETO
:D64_a2			w	$00ff
			b	$6f
			b	FRAME_RECTO
:D64_a3			w	$0040
			b	$58
			b	MOVEPENTO
:D64_a4			w	$0042
			b	$5a
			b	FRAME_RECTO
:D64_a5			w	$00fd
			b	$6d
			b	NULL

			LoadW	r0,V300a0
			jsr	PutString

			ldy	#$00
::103			lda	diskBlkBuf +$90,y
			cmp	#$a0
			beq	:107
			sty	:106 +1
			cmp	#$20
			bcc	:104
			cmp	#$7f
			bcc	:105
::104			lda	#"*"
::105			jsr	SmallPutChar
::106			ldy	#$ff
			iny
			cpy	#$10
			bne	:103

::107			jsr	ScreenInfo1

;*** Dekodierung initialisieren.
			lda	#$01
			sta	a3L
			lda	#$00
			sta	a3H

;*** Daten von Quelldatei einlesen.
:ReadD64SekData		lda	SourceDrive
			jsr	SetDevice
			jsr	EnterTurbo
			jsr	InitForIO

::101			LoadW	r15,BACK_SCR_BASE

			MoveB	a3L,a4L
			MoveB	a3H,a4H
			lda	#$20
			sta	a5L
			sta	a5H

;*** 32 Sektoren aus D64-Datei einlesen.
::102			ldx	a3L
			lda	a3H
			jsr	PosToSektor
			jsr	GetSektor
			dec	a5L

			jsr	SetNextSek
			bne	:103

			inc	r15H
			lda	a5L
			bne	:102

::103			jsr	DoneWithIO

			CmpBI	a5L,$20
			beq	EndOfImage

;*** Daten auf Zieldatei schreiben.
:Write1541SekData	lda	TargetDrive
			jsr	SetDevice
			jsr	EnterTurbo
			jsr	InitForIO

			LoadW	r4,BACK_SCR_BASE
			MoveB	a4L,a3L
			MoveB	a4H,a3H

;*** max. 32 Sektoren auf 1541-Diskette schreiben.
::101			MoveB	a3L,r1L
			MoveB	a3H,r1H
			jsr	WriteBlock
			dec	a5H

			jsr	SetNextSek
			bne	EndOfImage

			inc	r4H
			lda	a5H
			bne	:101

			jsr	DoneWithIO
			jmp	ReadD64SekData

;*** Image kopiert.
:EndOfImage		jsr	DoneWithIO
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	OpenMain

if Sprache = Deutsch
;*** Variablen.
:V300a0			b PLAINTEXT,BOLDON
			b GOTOXY
:V300a1			w $0048
			b $66
			b "Diskette" ,GOTOX
:V300a2			b $78,$00,": ",NULL
endif

if Sprache = Englisch
;*** Variablen.
:V300a0			b PLAINTEXT,BOLDON
			b GOTOXY
:V300a1			w $0048
			b $66
			b "Disk" ,GOTOX
:V300a2			b $78,$00,": ",NULL
endif
