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

			MoveW	$0314,IRQ_VEC_buf	;Zeiger auf IRQ-Routine retten

			LoadB	CPU_DATA,$30
			LoadB	RAM_Conf_Reg,$40	;keine Common Area    VIC = Bank 1
			LoadB	MMU,$7e			;nur RAM Bank 1 + IO

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

			LoadB	MMU,$7f			;nur RAM Bank 1

			ldy	#$00
::4			lda	(r0L),y			;Daten nach
			sta	(r1L),y			;$d000 (Bank 1)
			iny	 			;bis $feff verschieben
			bne	:4
			inc	r0H
			inc	r1H
			lda	r1H
			cmp	#$ff
			bne	:4

			ldy	#5			;Bereich $ff05 bis $ffff
::3			lda	(r0L),y			;setzen in Bank 1
			sta	(r1L),y
			iny
			bne	:3

			LoadB	MMU,$7e			;nur RAM Bank 1 + IO

			lda	#16
			jsr	doFetchRAM 		;Kernal Teil #5/BackRAM einlesen.

			LoadW	r0 ,$1000
			LoadW	r1 ,$c000		;$c000 - $efff in Bank 0 setzen

			LoadB	RAM_Conf_Reg,$4b	;16kByte Common Area oben = Bank 0
			LoadB	MMU,$7f			;nur RAM Bank 1

			ldy	#$00
::4a			lda	(r0L),y			;Daten nach
			sta	(r1L),y			;$c000 (Bank 0)
			iny	 			;bis $efff verschieben
			bne	:4a
			inc	r0H
			inc	r1H
			lda	r1H
			cmp	#$f0			;Ende $f000 erreicht?
			bne	:4a			;>nein

			LoadB	RAM_Conf_Reg,$40	;keine Common Area    VIC = Bank 1
			LoadB	MMU,$7e			;nur RAM Bank 1 + IO

			LoadW	r0,$1000
			LoadW	r1,$6900
			LoadW	r2,$1000
			LoadB	r3L,$00
			jsr	SysFetchRAM		;Kernal Teil #6 (Bank 0) einlesen.

			LoadW	r0 ,$1000
			LoadW	r1 ,$f000		;$f000 - $ffff in Bank 0 setzen

			LoadB	RAM_Conf_Reg,$4b	;16kByte Common Area oben = Bank 0
			LoadB	MMU,$7f			;nur RAM Bank 1

			ldy	#$00
::4b			lda	(r0L),y			;Daten nach
			sta	(r1L),y			;$f000 (Bank 0)
			iny	 			;bis $feff verschieben
			bne	:4b
			inc	r0H
			inc	r1H
			lda	r1H
			cmp	#$ff
			bne	:4b

			ldy	#5			;Bereich $ff05 bis $ffff
::3a			lda	(r0L),y			;setzen in Bank 0
			sta	(r1L),y
			iny
			bne	:3a

			LoadB	MMU,$7e			;nur RAM Bank 1 + IO
			LoadB	RAM_Conf_Reg,$40	;keine Common Area    VIC = Bank 1

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
;			lda	Mode_Conf_Reg		;40(1)/80(2) Zeichen Modus
;			and	#$80			;Flag maskieren und umdrehen
;			eor	#$80			;umdrehen und in graphMode
;			sta	graphMode		;speichern 40($00)/80($80)

;--- Ergänzung: 23.04.23/M.Kanet
;Bei RBOOT muss wie bei BOOT der Bildschirm-Modus gesetzt
;werden, da sonst der 80Z-Bildschirm nicht initialisiert wird.
;Auch wenn der 80Z-Modus aktiv ist muss das FarbRAM für
;DeskTop V2 gelöscht werden, da sonst beim Wechsel von
;80Z auf 40Z nach RBOOT die Farben nicht initialisiert sind.
			lda	Old_grMd		;Vorherigen Bildschirm-Modus
			sta	graphMode		;wieder setzen.

;			lda	graphMode
			pha

			eor	#%10000000		;Bildschirm-Modus wechseln.
			sta	graphMode
::sc1			jsr	SetNewMode		;Neuen Modus aktivieren.

			bit	graphMode
			bpl	:sc2
			lda	#2
			jsr	VDC_ModeInit		;VDC-Farbmodus setzen.

::sc2			jsr	xResetScreen		;Inaktiven Bildschirm löschen.

			pla
			sta	graphMode
			jsr	SetNewMode
;---

;--- Hinweis:
;":FirstInit" löscht den Bildschirm...
;
;			LoadB	dispBufferOn,ST_WR_FORE
;
;			bit	graphMode		;40/80-Zeichen ?
;			bmi	:80			; => 80Z, weiter...
;
;			LoadW	r0,$a000		; => 40Z.
;			ldx	#$7d
;::1			ldy	#$3f
;::2			lda	#$55
;			sta	(r0L),y
;			dey
;			lda	#$aa
;			sta	(r0L),y
;			dey
;			bpl	:2
;			lda	r0L
;			clc
;			adc	#$40
;			sta	r0L
;			bcc	:7
;			inc	r0H
;::7			dex
;			bne	:1
;			beq	:weiter
;
;::80			lda	#$02			; => 80Z.
;			jsr	SetPattern
;			jsr	i_Rectangle
;			b	$00,$c7
;			w	$0000,$027f

::weiter		jsr	FirstInit

;--- ":mousePicData" nach FirstInit.
			lda	#15
			jsr	doFetchRAM 		;":spr0pic"

			jsr	SCPU_OptOn		;SCPU optimieren.

			lda	#$ff
			sta	firstBoot

			jsr	InitMouse		;Mausabfrage initialisieren.

;*** Warteschleife.
;    Dabei wird zuerst der I/O-Bereich eingeblendet und anschließend die
;    Original-IRQ-Routine aktiviert. Diese Routine ist beim C64 zwingend
;    notwendig. Fehlt diese Routine ist ohne ein Laufwerk wie z.B. C=1541
;    ein Start über RBOOT nicht möglich (Fehlerhaftes IRQ-verhalten!)
;    Ist kein Gerät am ser. Bus aktiviert, kann GEOS ohne diese Routine
;    nicht gestartet werden!!!
:Wait			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	$dc08
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

::14			w spr0pic     , $fc40              , $003f, $0000
::15			w mousePicData, $fc40              , $003f, $0000

;--- Hinweis:
;Nur C128: BackRAM von $d000-$FFFF.
::16			w $1000       , $3900              , $3000, $0000
