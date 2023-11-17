; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Boot-Laufwerk öffnen.
; Datum			: 05.07.97
; Aufruf		: JSR  OpenBootDrive
; Übergabe		: -
; Rückgabe		: -	 Bei Fehler => Abbruch!
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -BootDriveByte Boot-Laufwerk
;			  -BootModeByte Boot-Laufwerksmodi
;			  -BootPartByte Boot-Partition
; Routinen		: -NewDrive Laufwerk aktivieren
;			  -NewOpenDisk Diskette öffnen
;			  -New_CMD_SubD Unterverzeichnis öffnen
;			  -SetNewPart Neue Partition aktivieren
;******************************************************************************

;*** Startlaufwerk aktivieren.
.OpenBootDrive		lda	BootDrive
			jsr	NewDrive		;Boot-Laufwerk aktivieren.

;--- Ergänzung: 28.11.2018/M.Kanet
;Mit SD2IEC/RAMNative können auch Unterverzeichnisse auf
;nicht-CMD-Laufwerken genutzt werden.
			lda	BootMode		;Geräte-Typ.
;			bpl	:101			;Kein CMD-Drive, weiter...
			bpl	:100			;Kein CMD-Drive, Keine Partitionen...

			lda	BootPart
			jsr	SetNewPart		;Partition aktivieren.

::100			lda	BootMode		;Geräte-Typ.
			and	#%00100000		;NativeDir-Partition ?
			beq	:101			;Nein, weiter...

			MoveW	BootNDir,r1		;Zeiger auf Verzeichnis zurücksetzen.
			jmp	New_CMD_SubD		;Verzeichnis öffnen.

::101			jmp	NewOpenDisk
::102			rts
