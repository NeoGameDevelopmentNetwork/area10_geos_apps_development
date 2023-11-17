; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GeoDOS-Systemvariablen einlesen.
:LoadSysVar		jsr	OpenSysDrive		;Startlaufwerk aktivieren.

			lda	#$00
			sta	DDrvInstall		;als "Installiert" kennzeichnen.
			sta	DOS_Install
			sta	CBM_Install
			sta	CopyInstall

;*** DOS-Laufwerkstreiber laden.
			lda	#SYSTEM			;DOS-Laufwerkstreiber suchen.
			ldx	#<DDrvClass
			ldy	#>DDrvClass
			jsr	LookForFile
			bne	:101
			jsr	LoadDriverDOS

			bit	DDrvInstall
			bpl	:101

			lda	#SYSTEM			;DOS-Menü suchen.
			ldx	#<DOS_Class
			ldy	#>DOS_Class
			jsr	LookForFile
			bne	:101
			dec	DOS_Install

::101			lda	#SYSTEM			;CBM-Menü suchen.
			ldx	#<CBM_Class
			ldy	#>CBM_Class
			jsr	LookForFile
			bne	:102
			dec	CBM_Install

::102			lda	#SYSTEM			;Copy-Menü suchen.
			ldx	#<CopyClass
			ldy	#>CopyClass
			jsr	LookForFile
			bne	INI_COLOR
			dec	CopyInstall

;*** Farben installieren.
:INI_COLOR		LoadB	r0L,%00000001		;Datei "COLOR.INI" nachladen.
			LoadW	r6 ,:102
			LoadW	r7 ,PRINTBASE
			jsr	GetFile
			txa				;Diskettenfehler ?
			beq	:103			;Nein, weiter...
			cpx	#$05			;Fehler = "File not found" ?
			bne	:101			;Nein, Systemfehler.
			jmp	INI_OPTION
::101			jmp	GDDiskError

::102			b "COLOR.INI",NULL

::103			jsr	i_MoveData
			w	PRINTBASE
			w	colSystem
			w	(GD_OS_VARS2-colSystem)

;*** Optionen installieren.
:INI_OPTION		LoadB	r0L,%00000001		;Datei "OPTION.INI" nachladen.
			LoadW	r6 ,:102
			LoadW	r7 ,PRINTBASE
			jsr	GetFile
			txa				;Diskettenfehler ?
			beq	:103			;Nein, weiter...
			cpx	#$05			;Fehler = "File not found" ?
			bne	:101			;Nein, Systemfehler.
			jmp	DOS_DRIVER
::101			jmp	GDDiskError

::102			b "OPTION.INI",NULL

::103			jsr	i_MoveData
			w	PRINTBASE
			w	OptionData
			w	(EndOptionData-OptionData)

;*** MSDOS-Laufwerkstreiber laden.
:DOS_DRIVER		bit	DDrvInstall
			bpl	:101
			jsr	LoadDriverDOS
::101			jmp	StartInfo

;*** MSDOS-Laufwerkstreiber einlesen.
:LoadDriverDOS		lda	#SYSTEM			;DOS-Laufwerkstreiber suchen.
			ldx	#<DDrvClass
			ldy	#>DDrvClass
			jsr	LookForFile
			bne	:101

			LoadW	r6 ,FileNameBuf		;DOS-Laufwerkstreiber einladen.
			LoadW	r7 ,DOS_Driver
			LoadB	r0L,%00000001
			jsr	GetFile
			txa
			bne	:101
			ldx	#$ff
			b $2c
::101			ldx	#$00			;Nachladefehler.
			stx	DDrvInstall
			rts

;*** Infobildschirm starten.
:StartInfo		jsr	InitForIO		;GeoDOS-Farben aktivieren.
			lda	C_ScreenBack
			and	#%00001111
			sta	$d020
			lda	C_Mouse
			sta	$d027
			lda	C_GEOS_BACK
			sta	screencolors
			jsr	DoneWithIO

			jsr	ClrScreen		;Bildschirm löschen.

			LoadW	r6,AppNameBuf		;GeoDOS-Datei öffnen.
			jsr	FindFile
			txa
			beq	:102
::101			jmp	GDDiskError		;Systemfehler.

::102			LoadW	r9,dirEntryBuf		;Datei-Infoblock laden.
			jsr	GetFHdrInfo
			txa				;Diskettenfehler ?
			bne	:101			;Nein, weiter...

			lda	SYS_DrvTarget
			sta	TargetMode
			lda	SYS_Copy_Mode
			sta	CopyMod
			lda	SYS_Bubble_OK
			sta	BubbleMod
			lda	SYS_MKey2Mode
			sta	MseKey2Mode
;--- Ergänzung: 22.12.18/M.Kanet
;Unterstützung für Option D'n'D On/Off ergänzt.
;Kann im Menü TOOLS ein-/ausgeschaltet werden.
			lda	SYS_EnableDnD
			sta	EnableDnD

			lda	SYS_Installed
			beq	:103			;Nicht installiert, weiter...
			jsr	OpenUsrDrive		;Anwenderlaufwerk öffnen.
			ldx	#$ff
			rts

::103			dec	SYS_Installed

			lda	dirEntryBuf+19		;Neuen Infoblock schreiben.
			sta	r1L
			lda	dirEntryBuf+20
			sta	r1H
			LoadW	r4,fileHeader
			jsr	PutBlock
			jsr	OpenUsrDrive		;Anwenderlaufwerk öffnen.
			ldx	#$00
			rts

;******************************************************************************
;*** Ende!
;******************************************************************************
