; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: System-Laufwerk öffnen.
; Datum			: 05.07.97
; Aufruf		: JSR  OpenSysDrive
; Übergabe		: -
; Rückgabe		: -	 Bei Fehler => Abbruch!
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -CMDPartMode3 Byte Laufwerk-Flags
;			  -AppDrvByte System-Laufwerk
;			  -AppModeByte System-Laufwerksmodi
;			  -AppRLPartWord System-Laufwerk  RAM-Partition
; Routinen		: -NewDrive Laufwerk aktivieren
;			  -NewOpenDisk Diskette öffnen
;			  -New_CMD_SubD Unterverzeichnis öffnen
;			  -SetNewPart Neue Partition aktivieren
;			  -Sv1DrvData Laufwerksdaten speichern
;			  -GDDiskError Systemfehler
;******************************************************************************

;*** Startlaufwerk aktivieren.
.OpenSysDrive		lda	curDrive
			sta	SetUserDrive+1

			lda	AppDrv
			jsr	NewDrive

			jsr	Sv1DrvData		;Laufwerksdaten speichern.

;*** Disketten-Partition aktivieren.
;--- Ergänzung: 21.11.18/M.Kanet
;Falls kein CMD-Laufwerk auf NativeMode-Laufwerk testen.
			bit	AppMode			;CMD-Laufwerk ?
			bpl	:101			;Nein, weiter...

			lda	AppPart
			jsr	SetNewPart		;Systempartition öffnen.
			txa				;Fehler ?
			bne	:105			;Ja, Abbruch...

;*** RAM-Partition aktivieren.
			lda	AppMode			;CMD-Laufwerk ?
			and	#%01000000		;RAMLink-Sonderbehandlung ?
			beq	:101			;Nein, weiter...

			ldx	AppDrv			;Aktuelle RAMLink-Partition merken.
			lda	AppRLPart  +0		;Neue RAMLink-Partition aktivieren.
			sta	ramBase    -8,x
			lda	AppRLPart  +1
			sta	driveData  +3

;*** NativeMode-Verzeichnis öffnen.
::101			lda	AppMode
			and	#%00100000		;NativeMode-Laufwerk ?
			bne	:104			;Ja, Sonderbehandlung.

::102			jsr	NewOpenDisk		;System-Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:105			;Ja, Abbruch.
::103			rts				;Ende.

;*** NativeMode-Verzeichnis aktivieren.
::104			MoveW	AppNDir,r1
			jsr	New_CMD_SubD		;Systemverzeichnis öffnen.
			txa				;Diskettenfehler ?
			beq	:103			;Ja, Abbruch.
::105			jmp	GDDiskError		;Systemfehler.

;******************************************************************************
; Funktion		: Anwender-Laufwerk öffnen.
; Datum			: 05.07.97
; Aufruf		: JSR  OpenUsrDrive
; Übergabe		: -
; Rückgabe		: -	 Bei Fehler => Abbruch!
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -NewDrive Laufwerk aktivieren
;			  -Ld1DrvData Laufwerksdaten zurücksetzen
;******************************************************************************

;*** Original Laufwerkskonfiguration wieder herstellen.
.OpenUsrDrive		jsr	Ld1DrvData

;*** Anwender-Laufwerk aktivieren.
:SetUserDrive		lda	#$00			;Anwender-Laufwerk öffnen.
			jmp	NewDrive
