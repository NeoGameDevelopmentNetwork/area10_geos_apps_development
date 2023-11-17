; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion        : I/O aktivieren und Befehl an Floppy senden.
; Datum           : 04.07.97
; Aufruf          : JSR  SendCom
; Übergabe        : AKKU,xReg       Word   Zeiger auf Befehl.
;                                          w (Anzahl Bytes)
;                                          b Befehlsbytes
; Rückgabe        : -
; Verändert       : AKKU,xReg,yReg
;                   r0  bis r3
;                   r14 und r15
; Variablen       : -DriveAdress    Daten  Laufwerksadressen.
; Routinen        : -PurgeTurbo            GEOS-Turbo deaktivieren.
;                   -InitForIO             I/O aktivieren.
;                   -DoneWithIO            I/O abschalten.
;                   -SECOND                Sekundär-Adresse nach LISTEN senden.
;                   -CIOUT                 Byte-Ausgabe auf IEC-Bus.
;                   -UNLSN                 UNLISTEN-Signal auf IEC-Bus senden.
;                   -LISTEN                LISTEN-Signal auf IEC-Bus senden.
;******************************************************************************

;******************************************************************************
; Funktion        : Befehl an Floppy senden.
; Datum           : 04.07.97
; Aufruf          : JSR  SendCom_a
; Übergabe        : AKKU,xReg       Word   Zeiger auf Befehl.
;                                          w (Anzahl Bytes)
;                                          b Befehlsbytes
; Rückgabe        : -
; Verändert       : AKKU,xReg,yReg
;                   r14 und r15
; Variablen       : -DriveAdress    Daten  Laufwerksadressen.
; Routinen        : -SECOND                Sekundär-Adresse nach LISTEN senden.
;                   -CIOUT                 Byte-Ausgabe auf IEC-Bus.
;                   -UNLSN                 UNLISTEN-Signal auf IEC-Bus senden.
;                   -LISTEN                LISTEN-Signal auf IEC-Bus senden.
;******************************************************************************

;******************************************************************************
; Funktion        : I/O aktivieren und Daten von Floppy empfangen.
; Datum           : 04.07.97
; Aufruf          : JSR  GetCom
; Übergabe        : AKKU,xReg       Word   Zeiger auf Befehl.
;                                          w (Anzahl Bytes)
;                                          b Befehlsbytes
; Rückgabe        : -
; Verändert       : AKKU,xReg,yReg
;                   r0  bis r3
;                   r14 und r15
; Variablen       : -DriveAdress    Daten  Laufwerksadressen.
; Routinen        : -PurgeTurbo            GEOS-Turbo deaktivieren.
;                   -InitForIO             I/O aktivieren.
;                   -DoneWithIO            I/O abschalten.
;                   -TKSA                  Sekundär-Adresse nach TALK senden.
;                   -ACPTR                 Byte-Eingabe vom IEC-Bus.
;                   -UNTALK                UNTALK-Signal auf IEC-Bus senden.
;                   -TALK                  TALK-Signal auf IEC-Bus senden.
;******************************************************************************

;******************************************************************************
; Funktion        : Daten von Floppy empfangen.
; Datum           : 04.07.97
; Aufruf          : JSR  GetCom_a
; Übergabe        : AKKU,xReg       Word   Zeiger auf Befehl.
;                                          w (Anzahl Bytes)
;                                          b Befehlsbytes
; Rückgabe        : -
; Verändert       : AKKU,xReg,yReg
;                   r14 und r15
; Variablen       : -DriveAdress    Daten  Laufwerksadressen
; Routinen        : -TKSA                  Sekundär-Adresse nach TALK senden.
;                   -ACPTR                 Byte-Eingabe vom IEC-Bus.
;                   -UNTALK                UNTALK-Signal auf IEC-Bus senden.
;                   -TALK                  TALK-Signal auf IEC-Bus senden.
;******************************************************************************

;******************************************************************************
; Funktion        : LISTEN-Signal an aktuelles Laufwerk senden.
; Datum           : 09.11.18
; Aufruf          : JSR  LISTEN_CURDRV
; Übergabe        : -
; Rückgabe        : -
; Verändert       : AKKU,xReg,yReg
; Variablen       : -curDrive              Aktuelles Laufwerk.
;                   -DriveAdress    Daten  Laufwerksadressen
; Routinen        : -LISTEN                LISTEN-Signal auf IEC-Bus senden.
;******************************************************************************

;******************************************************************************
; Funktion        : TALK-Signal an aktuelles Laufwerk senden.
; Datum           : 09.11.18
; Aufruf          : JSR  TALK_CURDRV
; Übergabe        : AKKU                   Sekundär-Adresse, $f0=0, $ff=15.
; Rückgabe        : -
; Verändert       : AKKU,xReg,yReg
; Variablen       : -curDrive              Aktuelles Laufwerk.
;                   -DriveAdress    Daten  Laufwerksadressen
; Routinen        : -TALK                  TALK-Signal auf IEC-Bus senden.
;                 : -TKSA                  Sekundär-Adresse nach TALK senden.
;******************************************************************************

;*** Daten an Floppy senden.
.SendCom		jsr	SaveComData
			jsr	SendCom_b
			jmp	DoneWithIO

.SendCom_a		sta	r15L
			stx	r15H

:SendCom_b		jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

;--- Ergnäzung: 21.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff			;Befehlskanal #15.
			jsr	SECOND			;Sekundär-Adresse nach LISTEN senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:103			;Nein, Abbruch...

			jsr	ComInit			;Zähler für Anzahl Bytes einlesen.
			jmp	:102

::101			lda	(r15L),y		;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			bne	:102
			inc	r15H
::102			SubVW	1,r14			;Zähler für Anzahl Bytes korrigieren.
			bcs	:101			;Schleife bis alle Bytes ausgegeben.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::103			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** Daten von Floppy empfangen.
.GetCom			jsr	SaveComData
			jsr	GetCom_b
			jmp	DoneWithIO

.GetCom_a		sta	r15L
			stx	r15H

:GetCom_b		jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.

;--- Ergnäzung: 21.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
			lda	#$ff			;Sekundär-Adresse nach TALK senden.
			jsr	TALK_CURDRV		;TALK-Signal auf IEC-Bus senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:103			;Nein, Abbruch...

			jsr	ComInit			;Zähler für Anzahl Bytes einlesen.
			jmp	:102

::101			jsr	ACPTR			;Byte einlesen und in
			sta	(r15L),y		;Speicher schreiben.
			iny
			bne	:102
			inc	r15H
::102			SubVW	1,r14			;Zähler für Anzahl Bytes korrigieren.
			bcs	:101

			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::103			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** Zeiger auf Befehl initialisieren.
:ComInit		ldy	#$01			;Zähler für Anzahl Bytes einlesen.
			lda	(r15L),y
			sta	r14H
			dey
			lda	(r15L),y
			sta	r14L
;--- Ergnäzung: 21.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
			jmp	Add_2_r15		;Zeiger auf Befehlsdaten setzen.

;*** Floppy-Befehl initialisieren.
:SaveComData		sta	r15L
			stx	r15H
			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jmp	InitForIO

;--- Ergnäzung: 21.11.18/M.Kanet
;GeoDOS-Kernal-Speicherplatz einsparen.
;Mehrfache Nutzung der Routinen durch Unterprogramme ersetzen.
;*** LISTEN an aktuelles Laufwerk senden.
.LISTEN_CURDRV		lda	#$00
			sta	STATUS			;Status löschen.
			ldx	curDrive
			lda	DriveAdress-8,x
			jmp	LISTEN			;LISTEN-Signal auf IEC-Bus senden.

;*** TALK an aktuelles Laufwerk senden.
.TALK_CURDRV		pha
			lda	#$00
			sta	STATUS			;Status löschen.
			ldx	curDrive
			lda	DriveAdress-8,x
			jsr	TALK			;TALK-Signal auf IEC-Bus senden.
			pla
			jmp	TKSA			;Sekundär-Adresse nach TALK senden.
