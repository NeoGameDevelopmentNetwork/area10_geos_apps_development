; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
;			t "TopMac"
;			t "Sym128.erg"
			t "ext.BuildMod.ext"

:MAX_DIR_ENTRY = 63
endif

			n "geoUReadDir"
			c "geoUReadDir V0.1"
			a "Markus Kanet"

if BUILD_DEBUG = TRUE
			h "/Usb0/ULIB"
else
			h "/root/dir"
endif

			h "Ultimate-Verzeichnis einlesen..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execReadDir

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ErrUDev"		;Fehler "Kein Ultimate" ausgeben.
			t "ulib._GetStatus"		;UCI-Statusregister abfragen.
			t "ulib._GetData"		;Daten über UCI einlesen.
			t "ulib._AccData"		;Datenempfang bestätigen.
			t "ulib._Push_NAME6"		;Dateiname/Pfad in r6 an UCI senden.
			t "ulib._FileInfo"		;Datei-Informationen konvertieren.

;DOS-Routinen:
			t "_dos.00.Target"		;DOS-Target 1/2 setzen.
			t "_dos.02.FOpen"		;Datei öffnen.
			t "_dos.03.FClose"		;Datei schießen.
			t "_dos.07.FileInfo"		;Datei-Informationen einlesen.
			t "_dos.11.ChDir"		;Verzeichnis wechseln.
			t "_dos.13.OpenDir"		;Verzeichnis öffnen.
			t "_dos.14.ReadDir"		;Verzeichnis einlesen.

;Erweiterte Programmroutinen:
			t "inc.Conf.PathDir"		;Verzeichnisname.

;*** Ultimate-Verzeichnis einlesen
:execReadDir		jsr	ULIB_TEST_UDEV		;Ultimate testen.
;			txa				;Gerät vorhanden?
			beq	:ok			; => Ja, weiter...

;--- Kein Ultimate, Fehler, Ende...
			jsr	ULIB_ERR_NO_UDEV
			jmp	exitDeskTop		; => Ende...

;--- Ultimate vorhanden.
::ok			jsr	getConfigDir		;Konfiguration einlesen.

			lda	uPathDir		;Pfad vorhanden?
			beq	exitDeskTop		; => Nein, Ende...

			jsr	uReadDir		;RAMDisk laden.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Ultimate-Verzeichnis einlesen
;Übergabe : uPathDir = Verzeichnispfad
;Rückgabe : X = Fehlerstatus, $00=OK
;           UCI_STATUS_MSG = Status-Meldung
;Verändert: A,X,Y,r0 bis r2L,r4,r5,r6,r7L,r7H,r8,r10,r12,r13,r14,r15L

:uReadDir		jsr	i_FillRam		;Verzeichnisspeicher löschen.
			w	MAX_DIR_ENTRY *64 + MAX_DIR_ENTRY *2
			w	TAB_DATA_BUF
			b	$00

			jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.
			jsr	ULIB_SEND_ABORT		;Abbruch senden.

			jsr	_UCID_SET_TARGET1	;Target DOS1 verwenden.

			lda	#< uPathDir
			sta	r6L
			lda	#> uPathDir
			sta	r6H
			jsr	_UCID_CHANGE_DIR	;Verzeichnis wechseln.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			jsr	_UCID_OPEN_DIR		;Verzeichnis öffnen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;--- Zeiger auf Verzeichnisliste.
			lda	#< DIR_DATA_BUF
			sta	r6L
			lda	#> DIR_DATA_BUF
			sta	r6H

;--- Verzeichnis-Optionen.
			lda	#%11100000		;Verzeichnis/Datei/Datei-Info.
;			lda	#%01100000		;Datei/Datei-Info.
;			lda	#%11000000		;Verzeichnis/Datei.
;			lda	#%01000000		;Datei.
			sta	r7L
			lda	#MAX_DIR_ENTRY
			sta	r7H

;--- Zeiger auf Verzeichnistabelle.
			lda	#< TAB_DATA_BUF
			sta	r8L
			lda	#> TAB_DATA_BUF
			sta	r8H

;--- Kein Test auf Erweiterung.
			lda	#NULL
			sta	r10L
			sta	r10H

;--- Test auf Erweiterung wie ".d64"
;			lda	#< :ext
;			sta	r10L
;			lda	#> :ext
;			sta	r10H

;--- Verzeichnis einlesen.
			jsr	_UCID_READ_DIR		;Verzeichnis einlesen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

			lda	#MAX_DIR_ENTRY
			sec
			sbc	r7H
			sta	fileCount

::err			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;--- Erweiterung für Verzeichnis-Filter.
;::ext			b ".d64"

;*** Dialogbox: Datei-Information ausgeben.
:prntFile1		ldx	#0
			b $2c
:prntFile2		ldx	#2
			b $2c
:prntFile3		ldx	#4

			lda	fileCount
			beq	exitPrnt
			txa
			lsr
			cmp	fileCount
			bcc	prntName
:exitPrnt		rts

:prntName		lda	TAB_DATA_BUF +0,x
			sta	r14L
			clc
			adc	#< 12
			sta	r0L
			lda	TAB_DATA_BUF +1,x
			sta	r14H
			adc	#> 12
			sta	r0H

			lda	rightMargin +1
			pha
			lda	rightMargin +0
			pha

			lda	#< 165
			sta	rightMargin +0
			lda	#> 165
			sta	rightMargin +1

			jsr	PutString

			pla
			sta	rightMargin +0
			pla
			sta	rightMargin +1

;--- Dateigröße ausgeben.
:prntSize		lda	#< 170
			sta	r11L
			lda	#> 170
			sta	r11H

			ldy	#1
			lda	(r14),y
			sta	r0L
			iny
			lda	(r14),y
			sta	r0H
			ora	r0L
			beq	exitPrnt

			lda	#SET_RIGHTJUST!SET_SUPRESS!24
			jsr	PutDecimal		;Größe ausgeben.

;--- Datum ausgeben.
:prntDate		lda	#< 200
			sta	r11L
			lda	#> 200
			sta	r11H

			ldy	#3
			lda	(r14),y
			ldy	#"."
			sec
			jsr	prntDEZtoASCII

			ldy	#4
			lda	(r14),y
			ldy	#"."
			sec
			jsr	prntDEZtoASCII

			ldy	#5
			lda	(r14),y
			ldy	#NULL
			clc
			jsr	prntDEZtoASCII

;--- Uhrzeit ausgeben.
:prntTime		lda	#< 235
			sta	r11L
			lda	#> 235
			sta	r11H

			ldy	#6
			lda	(r14),y
			ldy	#":"
			sec
			jsr	prntDEZtoASCII

			ldy	#7
			lda	(r14),y
			ldy	#"."
			sec
			jsr	prntDEZtoASCII

			ldy	#8
			lda	(r14),y
;			ldy	#NULL
			clc
			jsr	prntDEZtoASCII

;--- Extension ausgeben.
:prntExt		lda	#< 270
			sta	r11L
			lda	#> 270
			sta	r11H

			ldy	#9
			lda	(r14),y
			beq	:err
			jsr	:prntChar

			ldy	#10
			lda	(r14),y
			jsr	:prntChar

			ldy	#11
			lda	(r14),y

::prntChar		cmp	#NULL
			beq	:none
			cmp	#$20
			bcc	:other
			cmp	#$7f
			bcc	:ok
::other			lda	#"."
			bne	:ok
::none			lda	#"?"
::ok			jsr	SmallPutChar

::err			rts

;*** Dialogbox: Dateianzahl ausgeben.
:prntCount		lda	fileCount
			sta	r0L
			lda	#$00
			sta	r0H

			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal

			lda	#< textCount
			sta	r0L
			lda	#> textCount
			sta	r0H

			jmp	PutString

;*** Dezimalzahl nach ASCII wandeln.
;Übergabe: AKKU   = Dezimal-Zahl 0-99
;          C-Flag = 1 = Trenner in YREG auseben
;          YREG   = Zeichen für Zahlentrenner (":" oder ".")
;Rückgabe: -
:prntDEZtoASCII		sty	r15H

			php

			jsr	ULIB_DEZ_ASCII		;Zahl nach ASCII wandeln.

			pha				;Zahl ausgeben.
			txa
			jsr	SmallPutChar
			pla
			jsr	SmallPutChar

			plp				;Zahlen-Trenner ausgeben?
			bcc	:3			; => Nein, weiter...

			lda	r15H
			jsr	SmallPutChar		;Zahlen-Trenner.

::3			rts

;*** Anzahl Dateien.
:fileCount		b $00

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %00000001
			b $20,$8f
			w $0010,$0127

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w :2
			b DBTXTSTR   ,$10,$2a
			w uPathDir
			b DBTXTSTR   ,$10,$34
			w UCI_STATUS_MSG

			b DBTXTSTR   ,$10,$3e
			w :11
			b DB_USR_ROUT
			w prntFile1

			b DBTXTSTR   ,$10,$48
			w :12
			b DB_USR_ROUT
			w prntFile2

			b DBTXTSTR   ,$10,$52
			w :13
			b DB_USR_ROUT
			w prntFile3

			b DBTXTSTR   ,$10,$60
			w :21
			b DB_USR_ROUT
			w prntCount

			b OK         ,$1a,$58
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "Read Directory:"
			b NULL

::11			b "1:",NULL
::12			b "2:",NULL
::13			b "3:",NULL

::21			b "Anzahl: ",NULL
:textCount		b " Datei(en)",NULL

;*** Beginn Datenspeicher.
:TAB_DATA_BUF		= $2000
:DIR_DATA_BUF		= TAB_DATA_BUF +256*2
			g TAB_DATA_BUF
