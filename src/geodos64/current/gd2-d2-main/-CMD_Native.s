; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: NativeMode-Hauptverzeichnis aktivieren.
; Datum			: 03.07.97
; Aufruf		: JSR  New_CMD_Root
; Übergabe		: -
; Rückgabe		: xReg	 $00 = Kein Fehler.
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -$9050!!!!!! GateWay: Native-RootDir
;			  -GetDirHead BAM einlesen
;******************************************************************************

;*** Routine zum setzen des Root-Verzeichnisses auf CMD-Geräten.
.New_CMD_Root		lda	$9050			;Prüfen ob der Befehl existiert.
			cmp	#$4c
			bne	:1
			jsr	$9050			;Nur gateWay/MegaPatch!
							;Hauptverzeichnis aktivieren.
::1			jmp	GetDirHead		;BAM einlesen. Der Grund ist der Bug
							;in div. Laufwerkstreibern der beim
							;Aufruf von OpenDisk die BAM zerstört.

;******************************************************************************
; Funktion		: NativeMode-Unterverzeichnis aktivieren.
; Datum			: 03.07.97
; Aufruf		: JSR  New_CMD_SubD
; Übergabe		: -
; Rückgabe		: xReg	 $00 = Kein Fehler.
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -
; Routinen		: -$9053!!!!!! GateWay: Native-SubDir
;			  -GetDirHead BAM einlesen
;******************************************************************************

;*** Routine zum setzen eines Unterverzeichnisses auf CMD-Geräten.
.New_CMD_SubD		lda	$9053			;Prüfen ob der Befehl existiert.
			cmp	#$4c
			bne	:1
			jsr	$9053			;Nur gateWay/MegaPatch!
							;Unterverzeichnis aktivieren.
::1			jmp	GetDirHead		;BAM einlesen. Der Grund ist der Bug
							;in div. Laufwerkstreibern der beim
							;Aufruf von OpenDisk die BAM zerstört.
