; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Diskette einlegen.
; Datum			: 02.07.97
; Aufruf		: JSR  InsertDisk
; Übergabe		: Akku	Byte Laufwerksadresse
;			  xReg	Byte $00: Testen, wenn OK, dann
;				      zurück, sonst Hinweis.
;				 $7F: Nur Hinweis, nicht testen.
;				 $FF: Hinweis, danach testen.
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r15
; Variablen		: -curDrvModeByte Laufwerksmodi
; Routinen		: -NewDrive Neues Laufwerk anmelden
;			  -CheckDiskCBM Diskette im CBM-Laufwerk
;			  -CheckDiskDOS Diskette im DOS-Laufwerk
;******************************************************************************

;*** Diskette einlegen.
.InsertDisk		stx	TestDiskMode		;Testmodus merken.
			jsr	NewDrive		;Laufwerk aktivieren.

			lda	curDrive
			add	$39
			sta	TestInfo2 + 9		;Laufwerk nach ASCII wandeln.

			ldx	TestDiskMode		;Laufwerk zuerst testen ?
			beq	:103			;Ja, auf Disk im Laufwerk testen.

::101			DB_UsrBoxTestDiskInfo		;Infobox: "Diskette einlegen!".

			lda	sysDBData
			ldx	TestDiskMode		;Auf Disk im Laufwerk testen ?
			cpx	#$7f
			beq	:102			;Nein, Ende.
			cmp	#$02			;"Abbruch" gewählt ?
			bne	:103			;Nein, weiter.
::102			rts				;Ende.

::103			lda	curDrvMode
			and	#%00010000
			bne	:104
;--- Ergänzung: 09.12.18/M.Kanet
;In einigen Fällen kann es passieren das eine C=1541 nicht mehr reagiert.
;Z.B. DiskCopy C=1541 nach SD2IEC oder nach Partitionswechsel auf SD2IEC.
;Vorläufig bei C=-Laufwerken daher den "NewDisk" Befehl über TurboDOS an
;das Laufwerk senden.
			jsr	NewDisk
			jsr	CheckDiskCBM		;Auf Disk im CBM-Laufwerk testen.
			txa				;Diskette vorhanden ?
			bne	:101			;Nein, Infobox ausgeben.
			lda	#$01			;"OK", Diskette verfügbar.
			rts

::104			jsr	CheckDiskDOS		;Auf Disk im DOS-Laufwerk testen.
			txa				;Diskette vorhanden ?
			bne	:101			;Nein, Infobox ausgeben.
			lda	#$01			;"OK", Diskette verfügbar.
			rts

if Sprache = Deutsch
;*** Daten für "InsertDisk"
:TestDiskMode		b $00

:TestDiskInfo		w TestInfo1, TestInfo2, ISet_Achtung
			b CANCEL,OK
:TestInfo1		b BOLDON,"Bitte eine Diskette in",NULL
:TestInfo2		b        "Laufwerk x: einlegen!",NULL
endif

if Sprache = Englisch
;*** Daten für "InsertDisk"
:TestDiskMode		b $00

:TestDiskInfo		w TestInfo1, TestInfo2, ISet_Achtung
			b CANCEL,OK
:TestInfo1		b BOLDON,"Please insert disk",NULL
:TestInfo2		b        "in drive x:!",NULL
endif
