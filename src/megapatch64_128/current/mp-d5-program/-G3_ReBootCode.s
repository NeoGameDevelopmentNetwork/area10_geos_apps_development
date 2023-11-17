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
			lda	#$30
			sta	CPU_DATA

			MoveW	$0314,IRQ_VEC_buf	;Zeiger auf IRQ-Routine retten

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

			ldx	#$30
			ldy	#$00
::51			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:51
			inc	r0H
			inc	r1H
			dex
			bne	:51

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

;--- Hinweis:
;Wird über Interrupt und ":DrawSprite"
;aus ":mousePicData" initialisiert.
;			lda	#14
;			jsr	doFetchRAM 		;":spr0pic"

;--- Ergänzung: 24.12.22/M.Kanet
;In VIC-Bank#0 ist der Bereich von
;$07E8-$07F7 "unused". Für die in GEOS
;aktive VIC-Bank#2 = $8FE8-$8FF7.
;Es gibt im Kernal an keiner Stelle
;einen Zugriff auf diese Adressen, die
;Spritepointer liegen ab $8FF8 und
;werden durch GEOS_Init1 gesetzt.
;
; -> sysApplData
;
;GEOS V2 mit DESKTOP V2 legt hier über
;das Programm "pad color mgr" Farben
;für den DeskTop und Datei-Icons ab.
;Ab $8FE8 finden sich in 8 Byte bzw.
;16 Halb-Nibble die Farben für GEOS-
;Dateitypen 0-15, und ab $8FF0 findet
;sich die Farbe für den Arbeitsplatz.
;
;*** "pad color mgr"-Vorgaben setzen.
::DefPadCol		ldx	#6			;Ungenutzte Bytes
			lda	#$00			;initialisieren.
::50			sta	sysApplData +9,x
			dex
			bpl	:50

;--- Hinweis:
;Wird durch ":FirstInit" initialisiert.
;			lda	#$bf			;Standardfarbe Arbeitsplatz.
;			sta	sysApplData +8
;
;			ldx	#7			;Standardfarbe für die ersten
;			lda	#$bb			;16 GEOS-Dateitypen.
;::1			sta	sysApplData +0,x
;			dex
;			bpl	:1
;---

;*** GEOS initiailisieren.
;
;--- Hinweis:
;":FirstInit" löscht den Bildschirm...
;
;			LoadB	dispBufferOn,ST_WR_FORE
;
;			lda	#$02			;Bildschirm löschen.
;			jsr	SetPattern
;
;			jsr	i_Rectangle
;			b	$00,$c7
;			w	$0000,$013f

			jsr	FirstInit		;GEOS initialisieren.

;--- ":mousePicData" nach FirstInit.
			lda	#15
			jsr	doFetchRAM 		;":spr0pic"

			jsr	SCPU_OptOn		;SCPU optimieren.

			lda	#$ff			;GEOS-Boot-Vorgang.
			sta	firstBoot

			jsr	InitMouse		;Mausabfrage initialisieren.

;*** Warteschleife.
;    Dabei wird zuerst der I/O-Bereich eingeblendet und anschließend die
;    Original-IRQ-Routine aktiviert. Diese Routine ist beim C64 zwingend
;    notwendig. Feht diese Routine ist ohne ein Laufwerk wie z.B. C=1541
;    ein Start über RBOOT nicht möglich (Fehlerhaftes IRQ-verhalten!)
;    Ist kein Gerät am ser. Bus aktiviert, kann GEOS ohne diese Routine
;    nicht gestartet werden!!!
:Wait			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	$dc08			;Uhrzeit starten.
			sta	$dc08

			MoveW	IRQ_VEC_buf,$0314	;Zeiger auf IRQ-Routine setzen.

			cli				;IRQ aktivieren und warten bis
			lda	$dc08			;IRQ ausgeführt wurde...
::51			cmp	$dc08
			beq	:51

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

;*** Laufwerke aktivieren.
:InstallDrives		lda	curDrive		;Aktuelles Laufwerk merken.
			pha

			lda	#$00			;Anzahl Laufwerke löschen.
			sta	numDrives

			ldy	#8			;Zeiger auf Laufwerk #8.
::51			sty	:52 +1
			lda	driveType -8,y		;Laufwerk verfügbar ?
			beq	:53			;Nein, weiter...

			inc	numDrives		;Anzahl Laufwerke +1.
			lda	:52 +1
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
:SYS_REU_DATA
::00			w DISK_BASE   , $8300              , $0d80, $0000
::01			w $9d80       , $b900              , $0280, $0000
::02			w $bf40       , $bb80              , $00c0, $0000
;--- Hinweis:
;RBOOT kopiert bereits beim Start die
;ersten 256Bytes nach $c000.
::03			w $c100       , $bd40              , $0f00, $0000
;--- Hinweis:
;Der Bereich ab $D000 kann nur manuell
;in den Speicher kopiert werden. Daher
;den Bereich temporär nach $1000 laden.
::04			w $1000       , $cc40              , $3000, $0000

::05			w ramExpSize  , ramExpSize   -$0b00, $0001, $0000
::06			w year        , year         -$0b00, $0003, $0000
::07			w driveType   , driveType    -$0b00, $0004, $0000
::08			w ramBase     , ramBase      -$0b00, $0004, $0000
::09			w driveData   , driveData    -$0b00, $0004, $0000
::10			w PrntFileName, PrntFileName -$0b00, $0011, $0000
::11			w inputDevName, inputDevName -$0b00, $0011, $0000
::12			w curDrive    , curDrive     -$0b00, $0001, $0000
::13			w sysRAMFlg   , sysRAMFlg    -$0b00, $0001, $0000

::14			w SPRITE_PICS , $fc40              , $003f, $0000
::15			w mousePicData, $fc40              , $003f, $0000

;--- Hinweis:
;Nur C128: BackRAM von $d000-$FFFF.
;::16			w $1000       , $3900              , $3000, $0000
