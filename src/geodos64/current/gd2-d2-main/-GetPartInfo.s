; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Aktuelle Partition einlesen.
; Datum			: 05.07.97
; Aufruf		: JSR  GetCurPInfo
; Übergabe		: -
; Rückgabe		: xReg	Byte $00 = Partition OK
;			  yReg	Byte Partitions-Nr.
;			  Part_InfoDaten Partitions-Informationen
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -Part_GetInfoBefehl Aktuelle Partition einlesen
;			  -Part_InfoDaten Aktuelle Partition
; Routinen		: -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;			  -ClrPartInfo Partitionsdaten löschen
;******************************************************************************

;******************************************************************************
; Funktion		: Partitionsdaten einlesen.
; Datum			: 04.07.97
; Aufruf		: JSR  GetPartInfo
; Übergabe		: AKKU	Byte Partitions-Nr.
; Rückgabe		: xReg	Byte $00 = Partition OK
;			  yReg	Byte Partitions-Nr.
;			  Part_InfoDaten Partitions-Informationen
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -Part_GetInfoBefehl Aktuelle Partition einlesen
;			  -Part_InfoDaten Aktuelle Partition
; Routinen		: -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;			  -ClrPartInfo Partitionsdaten löschen
;******************************************************************************

;******************************************************************************
; Funktion		: Neue Partition aktivieren.
; Datum			: 03.07.97
; Aufruf		: JSR  IsPartOK
; Übergabe		: -
; Rückgabe		: xReg	Byte $00 = Partition OK
;			  yReg	Byte Partitions-Nr.
; Verändert		: AKKU,xReg,yReg
; Variablen		: -Part_InfoDaten Aktuelle Partition
; Routinen		: -
;******************************************************************************

;*** Partition auf Laufwerk wechseln.
.GetCurPInfo		lda	#$ff
.GetPartInfo		sta	Part_GetInfo +5

			jsr	ClrPartInfo		;Partitionsdaten löschen.

			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	Part_OK			;Nein, weiter...

			jsr	PurgeTurbo		;GEOS-Turbo deaktivieren.
			jsr	InitForIO		;I/O aktivieren.
			CxSend	Part_GetInfo		;Partitions-Informationen einlesen.
			CxReceivePart_Info
			jsr	DoneWithIO		;I/O abschalten.

.IsPartOK		ldy	Part_Info +4		;Partitions-Nr. einlesen.
			lda	Part_Info +2		;Partitionstyp einlesen.
			beq	Part_NotOK		;Partition vorhanden ? Nein, weiter...
			cmp	#$ff			;System-Partition ?
			bcc	Part_OK			;Nein, weiter...
:Part_NotOK		ldx	#$05			;Partition nicht gefunden.
			b $2c
:Part_OK		ldx	#$00			;Partition OK.
			rts
