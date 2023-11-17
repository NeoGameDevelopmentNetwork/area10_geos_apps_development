; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Treiberdatei auf aktuellem Laufwerk suchen.
:FindDiskCore		bit	firstBoot
			bpl	:loadDisk

::loadRAM		jsr	:testDiskCore
			txa
			beq	:2

::loadDisk		LoadW	r6,:fNameGDcore		;Verzeichniseintrag einlesen.
			jsr	FindFile
			txa
			bne	:1

			MoveB	dirEntryBuf +1,r1L
			MoveB	dirEntryBuf +2,r1H
			LoadW	r7,BASE_DDRV_INIT
			LoadW	r2,SIZE_DDRV_INIT
			jsr	ReadFile		;GD.DISK.CORE einlesen.
			txa				;Laufwerksfehler ?
			bne	:1			; => Ja, Abbruch...

			jsr	:setDDrvCore		;GD.DISK.CORE in REU speichern.
			jsr	StashRAM

			jsr	:chkSysCore
			txa
			beq	:2

::1			ldx	#FILE_NOT_FOUND		;Fehler: "FILE NOT FOUND!".
::2			rts

::fNameGDcore		b "GD.DISK.CORE",NULL

;--- GD.DISK.CORE im Speicher ?
::testDiskCore		jsr	:chkSysCore		;DISK.CORE bereits geladen ?
			txa
			beq	:done			; => Ja, Ende...

			jsr	:setDDrvCore		;GD.DISK.CORE in REU speichern.
			jsr	FetchRAM

::chkSysCore		ldx	#FILE_NOT_FOUND		;Kennung für DISK.CORE
			ldy	#5			;überprüfen.
::3			lda	:sysCode,y
			cmp	BASE_DDRV_INIT,y
			bne	:done			;Kennung nicht gefunden.
			dey
			bpl	:3
			ldx	#NO_ERROR		;Kennung geunden.
::done			rts

;--- Systemkennung für GD.DISK.CORE.
::sysCode		b "G3DC10"

;--- Zeiger auf GD.DISK.CORE in REU.
::setDDrvCore		LoadW	r0,BASE_DDRV_INIT	;GD.DISK.CORE in REU speichern.
			LoadW	r1,R2_ADDR_DDRVCORE
			LoadW	r2,R2_SIZE_DDRVCORE
			MoveB	MP3_64K_SYSTEM,r3L
			rts
