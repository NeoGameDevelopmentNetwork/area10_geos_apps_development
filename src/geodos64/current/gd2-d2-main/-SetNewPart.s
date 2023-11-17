; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Neue Partition aktivieren.
; Datum			: 05.07.97
; Aufruf		: JSR  SaveNewPart
; Übergabe		: AKKU	Byte Partitions-Nr.
; Rückgabe		: DrivePart +xByte Aktuelle Partition
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -DrivePart4 Byte Partitions-Adressen
;			  -Part_ChangeBefehl Partition aktvieren
;			  -Part_GetInfoBefehl Aktuelle Partition einlesen
;			  -Part_InfoDaten Aktuelle Partition
; Routinen		: -NewOpenDisk Diskette öffnen
;			  -New_CMD_Root NativeMode-Hauptverzeichnis
;			  -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;			  -IsPartOK Partition testen
;			  -ClrPartInfo Partitionsdaten löschen
;******************************************************************************

;******************************************************************************
; Funktion		: Neue Partition aktivieren.
; Datum			: 05.07.97
; Aufruf		: JSR  SetNewPart
; Übergabe		: AKKU	Byte Partitions-Nr.
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -DrivePart4 Byte Partitions-Adressen
;			  -Part_ChangeBefehl Partition aktvieren
;			  -Part_GetInfoBefehl Aktuelle Partition einlesen
;			  -Part_InfoDaten Aktuelle Partition
; Routinen		: -NewOpenDisk Diskette öffnen
;			  -New_CMD_Root NativeMode-Hauptverzeichnis
;			  -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;			  -IsPartOK Partition testen
;			  -ClrPartInfo Partitionsdaten löschen
;******************************************************************************

;*** MegaPatch3-Routinen.
;Für CMD-RL-Partitionswechsel.
:OpenPartition		= $9062

;*** Neue Partition auf Laufwerk anmelden.
.SaveNewPart		ldy	curDrive
			sta	DrivePart  -8,y		;Partitions-Nr. merken.

;*** Partition auf Laufwerk wechseln.
.SetNewPart		sta	Part_Change+4		;Partitions-Nr. merken.

			jsr	ClrPartInfo		;Partitionsdaten löschen.

			bit	curDrvMode		;CMD-Laufwerk ?
			bpl	:102			;Nein, weiter...

			jsr	PurgeTurbo		;GEOS-Turbo deaktivieren.
			jsr	InitForIO		;I/O aktivieren.
			CxSend	Part_Change		;Neue Partition aktivieren.

			lda	#$ff
			sta	Part_GetInfo+5		;Zeiger auf aktuelle Partition.
			CxSend	Part_GetInfo		;Partitions-Informationen einlesen.
			CxReceivePart_Info
			jsr	DoneWithIO		;I/O abschalten.

			jsr	IsPartOK		;Partition testen.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch.

			bit	curDrvMode		;GEOS-RAM-Laufwerk ?
			bvc	:101			;Nein, weiter...

			ldx	curDrive		;Startadresse RAM-Partition setzen.
			lda	Part_Info +22
			sta	ramBase   - 8,x
			lda	Part_Info +23
			sta	driveData + 3

			lda	DriveTypes- 8,x
			cmp	#Drv_CMDRL
			bne	:101

;---  Erkennung MegaPatch-Laufwerkstreiber.
			lda	$906e
			cmp	#"M"
			bne	:101
			lda	$9072
			cmp	#"3"
			bne	:101			; => Kein MP3-Treiber.

			lda	Part_Info + 4		;Partitions-Nr. einlesen.
			sta	r3H			;MegaPatch3-Aufruf zum wechseln
			jsr	OpenPartition		;der RL-Partition.

::101			lda	Part_Info + 2		;Partitionstyp einlesen.
			cmp	#$01			;CMD-NativeMode ?
			bne	:102			;Nein, weiter...
			jsr	New_CMD_Root		;Hauptverzeichnis öffnen.
			ldy	Part_Info + 4
			rts

::102			jsr	NewOpenDisk		;Diskette öffnen.
			ldy	Part_Info + 4
::103			rts
