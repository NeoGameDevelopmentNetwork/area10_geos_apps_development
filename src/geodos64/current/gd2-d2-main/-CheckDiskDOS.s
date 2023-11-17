; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Auf Diskette im DOS-Laufwerk testen
; Datum			: 02.07.97
; Aufruf		: JSR  CheckDiskDOS
; Übergabe		: -
; Rückgabe		: xReg	Byte $00 = Disk im Laufwerk
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r3
;			  r14 und r15
; Variablen		: -curDrvTypeByte Laufwerkstyp
; Routinen		: -SendCom_a Befehl an Floppy senden
;			  -GetCom_a Daten von Floppy einlesen
;			  -PurgeTurbo GEOS-Turbo deaktivieren
;			  -InitForIO I/O aktivieren
;			  -DoneWithIO I/O abschalten
;******************************************************************************

;*** Auf Diskette in DOS-Laufwerk prüfen.
.CheckDiskDOS		lda	#$02			;Job-Speicher für 1581-Laufwerk $02.
			ldx	curDrvType
			cpx	#Drv_1581		;Aktuelles Laufwerk vom Typ 1581 ?
			beq	:101			;Ja, weiter...
			lda	#$28			;Job-Speicher für FD-Laufwerk $28.
::101			sta	SetJobCode +5		;Job-Speicheradresse merken.
			sta	GetJobCode +5

			jsr	PurgeTurbo		;GEOS-Turbo abschalten.
			jsr	InitForIO		;I/O aktivieren.

			CxSend	SetJobCode		;Floppy-Befehl "Disk in Drive" senden.
::102			CxSend	GetJobCode		;Testergebnis einlesen.
			CxReceiveJobCodeData
			bit	JobCodeData +2		;Job erledigt ?
			bmi	:102			;Nein, weitertesten.

			jsr	DoneWithIO		;I/O abschalten.
			ldx	JobCodeData +2		;Testergebnis einlesen und Ende.
			rts

;*** Befehle für DOS-Laufwerk.
:SetJobCode		b $07,$00,"M-W",$02,$00,$01,$92
:GetJobCode		b $06,$00,"M-R",$02,$00,$01
:JobCodeData		b $01,$00,$00
