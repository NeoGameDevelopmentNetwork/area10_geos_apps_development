; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** FBoot initilaisieren.
:MainInit		lda	#14
			sta	extclr
			lda	#6
			sta	bakclr0

			lda	#$00
			jsr	SETMSG			;Keine Anzeige von STATUS-Meldungen.

			lda	#<:bootinf
			ldy	#>:bootinf
			jsr	ROM_OUT_STRING		;Fehlermeldung ausgeben.
			jmp	INIT_GEOS_BOOT

::bootinf		b $93
			b $11,$11,$11,$11
			b $11,$11,$11,$11
			b $1d,$1d,$1d,$1d
			b $1d,$1d,$1d,$1d
			b $1d,$1d,$1d,$1d
			b "BOOTING GEOS ..."
			b NULL

;*** BOOT-Vorgang intialisieren.
:INIT_GEOS_BOOT		sei				;IRQ sperren.
			cld				;Dezimal-Flag löschen.
			ldx	#$ff			;Stack-Pointer löschen.
			txs

			MoveW	IRQ_VEC,IRQ_VEC_buf

			lda	BOOT_DEVICE		;Boot-Laufwerk definiert ?
			bne	:1			; => Ja, weiter...
			lda	curDevice		; => Nein, aktuelles Laufwerk.
::1			cmp	#12			;Vorgabe-Laufwerk gültig ?
			bcs	:2
			cmp	#8
			bcs	:3
::2			lda	#8			; => Nein, Laufwerk #8 setzen...
::3			sta	BOOT_DEVICE		;Aktuelles Laufwerk = Boot-Laufwerk.

			sec
			sbc	#$08
			asl
			tax
			lda	SYS_DISK_DATA +0,x
			sta	SYS_REU_DATA +2
			lda	SYS_DISK_DATA +1,x
			sta	SYS_REU_DATA +3

			jsr	TEST_DACC_DEV		;GEOS-DACC testen.
			txa				;DACC gefunden ?
			bne	NoRAMfound		; => Nein, Fehler...
			jmp	START_GEOS_BOOT		; => Ja, weiter...

;*** Keine Speichererweiterung, Ende...
:NoRAMfound		lda	#KRNL_BAS_IO_IN		;Standard-RAM-Bereiche einblenden.
			sta	CPU_DATA
			cli

			lda	#<:errmsg
			ldy	#>:errmsg
			jsr	ROM_OUT_STRING		;Fehlermeldung ausgeben.

			jmp	ROM_BASIC_READY		;Zurück zum C64-BASIC.

;*** Fehlermeldung.
::errmsg		b $93
			b CR
			b "ERROR!",CR
			b CR
			b "RAM-EXPANSION-UNIT NOT DETECTED.",CR
			b "BOOTING GEOS CANCELLED...",CR
			b CR
			b NULL

;*** GEOS-Boot ausführen.
:START_GEOS_BOOT	sei

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

			LoadW	r0 ,$2000
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

			lda	#12
			jsr	doFetchRAM 		;":curDrive"

			lda	#13
			jsr	doFetchRAM 		;":sysRAMFlg"

			lda	#14
			jsr	doFetchRAM 		;":spr0pic"

			lda	#15
			jsr	doFetchRAM 		;":mousePicData"

;*** GEOS-Version testen.
:TEST_GEOS_VER		ldx	#$00
			lda	MP3_CODE +0
			cmp	#"M"
			bne	:setver
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:setver
			dex
::setver		stx	BOOT_GEOS_VER

;*** Warteschleife.
;    Dabei wird zuerst der I/O-Bereich eingeblendet und anschließend die
;    Original-IRQ-Routine aktiviert. Diese Routine ist beim C64 zwingend
;    notwendig. Fehlt diese Routine ist ohne ein Laufwerk wie z.B. C=1541
;    ein Start über RBOOT nicht möglich (Fehlerhaftes IRQ-verhalten!)
;    Ist kein Gerät am ser. Bus aktiviert, kann GEOS ohne diese Routine
;    nicht gestartet werden!!!
:Wait			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	cia1tod_t		;Uhrzeit starten.
			sta	cia1tod_t

			MoveW	IRQ_VEC_buf,IRQ_VEC

			cli				;IRQ aktivieren und warten bis
			lda	cia1tod_t		;IRQ ausgeführt wurde...
::sleep			cmp	cia1tod_t
			beq	:sleep

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			bit	BOOT_GEOS_VER
			bpl	:skip_mp3data1

			jsr	i_FillRam		;GEOS-DACC Speicherbelegung löschen:
			w	RAM_SIZE / 8 *2		;Die Tabelle wird durch den
			w	RamBankInUse		;GEOS.Editor neu erstellt.
			b	$00

::skip_mp3data1		lda	#IO_IN			;I/O-Bereiche einblenden.
			sta	CPU_DATA

			lda	cia1base +15		;I/O-Register initialisieren.
			and	#$7f
			sta	cia1base +15
			lda	#$81
			sta	cia1base +11
			lda	#$00
			sta	cia1base +10
			sta	cia1base + 9
			sta	cia1base + 8

			lda	#RAM_64K		;GEOS-RAM aktivieren.
			sta	CPU_DATA

			ldx	#$07			;Sprite-Pointer setzen.
			lda	#$bb
::51			sta	$8fe8,x
			dex
			bpl	:51

			lda	#$bf
			sta	$8ff0

::NEW			lda	#$00
			sta	firstBoot

			jsr	FirstInit		;GEOS initialisieren.

			bit	BOOT_GEOS_VER
			bpl	:skip_mp3data2

			jsr	SCPU_OptOn		;SCPU aktivieren (auch wenn keine
							;SCPU verfügbar ist!)
::skip_mp3data2		jsr	InitMouse		;Mausabfrage starten (nur temporär
							;notwendig, da gewünschter Treiber
							;erst später geladen wird!)

			lda	#$08			;Sektor-Interleave #8.
			sta	interleave

			LoadB	year ,21		;Startdatum setzen.
			LoadB	month,01		;Das Jahrtausendbyte wird in
			LoadB	day  ,01		;":millenium" im Kernal gesetzt.
							;(siehe Kernal/-G3_GD3_VAR)

			lda	#$01			;Anzahl Laufwerke löschen.
			sta	numDrives

;*** Laufwerksvariablen initialisieren.
:InitSys_GEOSDDrv	ldy	BOOT_DEVICE		;Startlaufwerk aktivieren.
			sty	curDrive

			lda	#$00			;GEOS-Laufwerkswechsel
			sta	curDevice		;erzwingen.

			lda	BOOT_DEVICE		;Startlaufwerk aktivieren. Dabei
			jsr	SetDevice		;werden bei der RAMLink auch die
			jsr	OpenDisk		;Laufwerkstreiber-Variablen gesetzt.

;*** Standard-Gerätetreiber laden.
			jsr	LoadDev_Printer		;Druckertreiber laden.
			jsr	LoadDev_Mouse		;Eingabetreiber laden.

;--- Ergänzung: 09.02.21/M.Kanet
;Maustreiber nach dem laden initialisieren.
			jsr	InitMouse		;Maustreiber initialisieren.

;*** Konfiguration speichern.
; ** OFF **		jsr	SaveConfigDACC

;*** AutoBoot-Programme ausführen.
:AUTO_INSTALL		jsr	i_MoveData		;AutoBoot-Routine kopieren.
			w	AutoBoot_a
			w	BASE_AUTO_BOOT
			w	(AutoBoot_b - AutoBoot_a)

			jmp	BASE_AUTO_BOOT		;AutoBoot starten.

:AutoBoot_a		d "obj.AUTOBOOT"
:AutoBoot_b

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

			jmp	execFetchRAM

;*** Ersten Druckertreiber auf Diskette suchen/laden.
:LoadDev_Printer	lda	#$ff			;Druckername in RAM löschen.
			sta	PrntFileNameRAM

			LoadW	r6 ,PrntFileName
			LoadB	r7L,PRINTER
			jsr	LoadDev_InitFn		;Druckertreiber suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			lda	r7H			;Treiber gefunden ?
			bne	:51			; => Nein, Abbruch...

			lda	Flag_LoadPrnt		;Druckertreiber in REU laden ?
			bne	:51			;Nein, weiter...

			LoadB	r0L,%00000001
			LoadW	r6 ,PrntFileName
			LoadW	r7 ,PRINTBASE
			jsr	GetFile			;Druckertreiber laden.
::51			rts

;*** Ersten Maustreiber auf Diskette suchen/laden.
:LoadDev_Mouse		LoadW	r6 ,inputDevName
			LoadB	r7L,INPUT_DEVICE
			jsr	LoadDev_InitFn		;Eingabetreiber suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			lda	r7H			;Treiber gefunden ?
			bne	:51			; => Nein, Abbruch...

			LoadB	r0L,%00000001
			LoadW	r6 ,inputDevName
			LoadW	r7 ,MOUSE_BASE
			jsr	GetFile			;Eingabetreiber laden.
::51			rts

;*** Dateisuche initialisieren.
:LoadDev_InitFn		ldx	#$01
			stx	r7H
			dex
			stx	r10L
			stx	r10H
			jmp	FindFTypes		;Eingabetreiber suchen.

;*** Speicherbelegung GEOS-DACC.
:SYS_DISK_DATA		w $8300
			w $8300 +($0d80 *1)
			w $8300 +($0d80 *2)
			w $8300 +($0d80 *3)

:SYS_REU_DATA		w DISK_BASE   , $8300              , $0d80, $0000
			w $9d80       , $b900              , $0280, $0000
			w $bf40       , $bb80              , $00c0, $0000
			w $c000       , $bc40              , $1000, $0000
			w $2000       , $cc40              , $3000, $0000

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
