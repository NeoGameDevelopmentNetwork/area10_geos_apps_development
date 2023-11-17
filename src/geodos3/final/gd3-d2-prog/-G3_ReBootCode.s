; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-ReBoot-Routine.
:GEOS_ReBootSys		sei
			cld
			ldx	#$ff
			txs

			MoveW	irqvec,IRQ_VEC_buf

			lda	#RAM_64K		;I/O-Bereiche einblenden.
			sta	CPU_DATA

			lda	#0
			jsr	doFetchRAM		;Laufwerkstreiber A: einlesen.

			lda	#1
			jsr	doFetchRAM 		;Kernal Teil #1 einlesen.

			lda	#2
			jsr	doFetchRAM 		;Kernal Teil #2 einlesen.

			lda	#3
			jsr	doFetchRAM 		;Kernal Teil #3 einlesen.

			lda	#4
			jsr	doFetchRAM 		;Kernal Teil #4 einlesen.

			LoadW	r0 ,$1000
			LoadW	r1 ,$d000

			ldx	#$30			;Teil #4 liegt im RAM ab
			ldy	#$00			;$D000-$FFFF.
::50			lda	(r0L),y			;Daher kann der Bereich nicht über
			sta	(r1L),y			;FetchRAM eingelesen werden.
			iny
			bne	:50
			inc	r0H
			inc	r1H
			dex
			bne	:50

;*** GEOS-Variablenspeicher löschen.
;			jsr	i_FillRam
;			w	$0500
;			w	$8400
;			b	$00

			LoadW	r0,$8400

			ldx	#$05
			ldy	#$00
			tya
::clrvar		sta	(r0L),y
			iny
			bne	:clrvar
			inc	r0H
			dex
			bne	:clrvar

;*** GEOS-Variablen aus REU einlesen.
			lda	#5
			jsr	doFetchRAM 		;":ramExpSize"

			lda	#6
			jsr	doFetchRAM 		;":year"

			lda	#7
			jsr	doFetchRAM 		;":driveType"

			lda	#8
			jsr	doFetchRAM 		;":ramBase"

			lda	#9
			jsr	doFetchRAM 		;":driveData"

			lda	#10
			jsr	doFetchRAM 		;":PrntFileName"

			lda	#11
			jsr	doFetchRAM 		;":inputDevName"

;			lda	#12
;			jsr	doFetchRAM 		;":curDrive"
			lda	#8			;Laufwerk A: aktivieren, da nur der
			sta	curDrive		;Laufwerkstreiber geladen wird.

			lda	#13
			jsr	doFetchRAM 		;":sysRAMFlg"
			lda	sysRAMFlg		;System-Flag speichern.
			sta	sysFlgCopy

			lda	#14
			jsr	doFetchRAM 		;":spr0pic"

			lda	#15
			jsr	doFetchRAM 		;":mousePicData"

;*** GEOS initiailisieren.
			jsr	FirstInit		;GEOS initialisieren.
			jsr	SCPU_OptOn		;SCPU optimieren.

			lda	#$ff			;GEOS-Boot-Vorgang.
			sta	firstBoot

			jsr	InitMouse		;Mausabfrage initialisieren.

			LoadB	dispBufferOn,ST_WR_FORE

			lda	#$02			;Bildschirm löschen.
			jsr	SetPattern

			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

;*** Warteschleife.
;Dabei wird zuerst der I/O-Bereich eingeblendet und anschließend die
;Original-IRQ-Routine aktiviert. Diese Routine ist beim C64 zwingend
;notwendig. Fehlt diese Routine ist ohne ein Laufwerk wie z.B. C=1541
;ein Start über RBOOT nicht möglich (Fehlerhaftes IRQ-verhalten!)
;Ist kein Gerät am ser. Bus aktiviert, kann GEOS ohne diese Routine
;nicht gestartet werden!!!
:Wait			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	cia1tod_t		;Uhrzeit starten.
			sta	cia1tod_t

			MoveW	IRQ_VEC_buf,irqvec

			cli				;IRQ aktivieren und warten bis
			lda	cia1tod_t		;IRQ ausgeführt wurde...
::sleep			cmp	cia1tod_t
			beq	:sleep

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

;*** Laufwerke aktivieren.
:InstallDrives		lda	curDrive		;Aktuelles Laufwerk merken.
			pha

			lda	#$00			;Anzahl Laufwerke löschen.
			sta	numDrives

			ldy	#8			;Zeiger auf Laufwerk #8.
::51			sty	:52 +1
			lda	driveType -8,y		;Laufwerk verfügbar ?
			beq	:53			; => Nein, weiter...

			inc	numDrives		;Anzahl Laufwerke +1.

			tya				;Laufwerksadresse.
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	NewDisk			;Diskette öffnen.

::52			ldy	#$ff
::53			iny				;Zeiger auf nächstes Laufwerk.
			cpy	#12			;Alle Laufwerke getestet ?
			bcc	:51			;Nein, weiter...

			pla
			jsr	SetDevice		;Laufwerk zurücksetzen.
			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Daten aus GEOS-DACC einlesen.
:doFetchRAM		asl
			asl
			asl
			tay
			ldx	#0
::1			lda	SYS_REU_DATA,y
			sta	r0L,x
			iny
			inx
			cpx	#7
			bcc	:1

			jmp	SysFetchRAM

;*** IRQ-Vektor.
:IRQ_VEC_buf		w $0000

;*** Speicherbelegung GEOS-DACC.
:SYS_REU_DATA		w DISK_BASE   , $8300              , $0d80, $0000
			w OS_LOW      , $b900              , $0280, $0000
			w $bf40       , $bb80              , $00c0, $0000
			w GD_JUMPTAB  , $bd40              , $0f00, $0000
			w $1000       , $cc40              , $3000, $0000

			w ramExpSize  , ramExpSize   -$0b00, $0001, $0000
			w year        , year         -$0b00, $0003, $0000
			w driveType   , driveType    -$0b00, $0004, $0000
			w ramBase     , ramBase      -$0b00, $0004, $0000
			w driveData   , driveData    -$0b00, $0004, $0000
			w PrntFileName, PrntFileName -$0b00, $0011, $0000
			w inputDevName, inputDevName -$0b00, $0011, $0000
			w curDrive    , curDrive     -$0b00, $0001, $0000
			w sysRAMFlg   , sysRAMFlg    -$0b00, $0001, $0000

			w SPRITE_PICS , $fc40              , $003f, $0000
			w mousePicData, $fc40              , $003f, $0000
