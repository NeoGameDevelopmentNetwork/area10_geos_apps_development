; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: System auf Speichererweiterung testem.
; Datum			: 05.07.97
; Aufruf		: jsr  CheckRAM
; Übergabe		: -
; Rückgabe		: xReg	Byte $00 = OK
;				 $FF = Abbruch
; Verändert		: -
; Variablen		: -AppDrvByte Systemlaufwerk
; Routinen		: -
;******************************************************************************

;*** Test auf RAM-Erweiterung.
:CheckRAM		lda	ramExpSize		;RAM-Erweiterung ?
			beq	:102			;Nein, Konfiguration testen.
::101			ldx	#$00			;Ja, weiter...
			rts

::102			lda	AppDrv			;GeoDOS-Laufwerk aktivieren.
			jsr	NewDrive

			ldx	curDrive		;Systemlaufwerkstyp ermitteln.
			lda	driveType -8,x

			ldx	#$00
			ldy	#$00			;Unterschiedliche Laufwerke zählen.
::103			cmp	driveType,x
			beq	:104
			iny
::104			inx
			cpx	#$04
			bcc	:103
			cpy	#$02			;Mehr als ein Laufwerkstyp ?
			bcc	:101			;Nein, weiter...

			DB_UsrBoxDlgNoRAM		;Abfrage: "Konfiguration anpassen ?"
			CmpBI	sysDBData,YES
			beq	:105			;Ja, weiter...
			ldx	#$ff			;Nein, Ende.
			rts

::105			lda	curDrvType
			sta	:106 +4

			ldx	#$08			;Alle Laufwerke löschen, die nicht dem
::106			lda	driveType-8,x		;GeoDOS-Laufwerkstyp entsprechen.
			cmp	#$ff
			beq	:107
			txa
			pha
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	PurgeTurbo		;GEOS-Turbo-Routinen entfernen.
			pla
			tax
			lda	#$00			;Laufwerk unter GEOS abmelden.
			sta	driveType-8,x
::107			inx
			cpx	#$0c
			bne	:106

			ldx	#$00
			rts

if Sprache = Deutsch
;*** Hinweis: "Keine RAM-Erweiterung!"
:DlgNoRAM		w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"Keine RAM-Erweiterung!",NULL
::102			b        "Konfiguration anpassen?",NULL
endif

if Sprache = Englisch
;*** Hinweis: "Keine RAM-Erweiterung!"
:DlgNoRAM		w :101, :102, ISet_Frage
			b NO,YES
::101			b BOLDON,"No RAM-expansion found!",NULL
::102			b        "Autoconfigure system?",NULL
endif
