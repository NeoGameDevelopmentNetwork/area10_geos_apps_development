; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = FD_41!FD_71!FD_NM
if :tmp0 = TRUE
;******************************************************************************
;*** Neue Diskette öffnen.
:xLogNewPart		jsr	xExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

::51			ldx	#> :com_GetDisk
			lda	#< :com_GetDisk
			ldy	#$03
			jsr	:getByte		;Diskstatus einlesen.
			cpx	#NO_ERROR 		;Fehler?
			bne	:56			; => Ja, Abbruch...

::52			tax				;Neue Disk eingelegt?
			beq	:53			; => Nein, weiter...

			jsr	FCom_InitDisk		;"I0:"-Befehl an Laufwerk senden.
			txa				;Fehler?
			bne	:56			; => Ja, Abbruch...

::53			jsr	dir3Head_r4
			jsr	xReadPTypeData
			txa
			bne	:56

			ldx	#> :com_PartNr
			lda	#< :com_PartNr
			ldy	#$06
			jsr	:getByte
			cpx	#NO_ERROR
			bne	:56

			ldy	curDrive
			sta	drivePartData-8,y
			tay
			lda	(r4L),y
			cmp	#PART_TYPE
			beq	:56

			ldy	#$01
::54			lda	(r4L),y
			cmp	#PART_TYPE
			beq	:55
			iny
			cpy	#PART_MAX +1
			bne	:54

			ldx	#NO_PARTITION		;Keine Fehlermeldung ausgeben, da
			bne	:56			;sonst DOS-Disk nicht erkannt wird!

::55			tya
			ldy	curDrive
			sta	r3H
			sta	drivePartData-8,y
			jsr	xSwapPartition

::56			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;--- Datenbyte von Floppy einlesen.
;    Übergabe:		AKKU	= Low -Byte, Zeiger auf Floppy-Befehl.
;			xReg	= High-Byte, Zeiger auf Floppy-Befehl.
;			yReg	= Länge (Zeichen) Floppy-Befehl.
::getByte		jsr	SendComVLen		;Befehl an Laufwerk senden.
			bne	:61			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK		;Laufwerk auf Senden schalten.
			bne	:61			;Fehler? => Ja, Abbruch...

			jsr	ACPTR			;Byte von Laufwerk empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla

			ldx	#NO_ERROR
::61			rts

::com_GetDisk		b "G-D"
::com_PartNr		b "M-R",$68,$2c,$01
endif

;******************************************************************************
::tmp1 = FD_81
if :tmp1 = TRUE
;******************************************************************************
;*** Neue Diskette öffnen.
:xLogNewPart		jsr	xExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

::51			ldx	#> :com_GetDisk
			lda	#< :com_GetDisk
			ldy	#$03
			jsr	:getByte		;Diskstatus einlesen.
			cpx	#NO_ERROR 		;Fehler?
			bne	:56			; => Ja, Abbruch...

::52			tax				;Neue Disk eingelegt?
			beq	:53			; => Nein, weiter...

			jsr	FCom_InitDisk		;"I0:"-Befehl an Laufwerk senden.
			txa				;Fehler?
			bne	:56			; => Ja, Abbruch...

::53			jsr	dir3Head_r4
			jsr	xReadPTypeData
			txa
			bne	:56

			ldx	#> :com_PartNr
			lda	#< :com_PartNr
			ldy	#$06
			jsr	:getByte
			cpx	#NO_ERROR
			bne	:56

			ldy	curDrive
			sta	drivePartData-8,y
			tay
			lda	(r4L),y
			cmp	#PART_TYPE
			beq	:56

			ldy	#$01
::54			lda	(r4L),y
			cmp	#PART_TYPE
			beq	:55
			iny
			cpy	#PART_MAX +1
			bne	:54

			ldx	#NO_PARTITION		;Keine Fehlermeldung ausgeben, da
			bne	:56			;sonst DOS-Disk nicht erkannt wird!

::55			tya
			ldy	curDrive
			sta	r3H
			sta	drivePartData-8,y
			jsr	xSwapPartition

::56			jsr	Load_dir3Head

			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;--- Datenbyte von Floppy einlesen.
;    Übergabe:		AKKU	= Low -Byte, Zeiger auf Floppy-Befehl.
;			xReg	= High-Byte, Zeiger auf Floppy-Befehl.
;			yReg	= Länge (Zeichen) Floppy-Befehl.
::getByte		jsr	SendComVLen		;Befehl an Laufwerk senden.
			bne	:61			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK		;Laufwerk auf Senden schalten.
			bne	:61			;Fehler? => Ja, Abbruch...

			jsr	ACPTR			;Byte von Laufwerk empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla

			ldx	#NO_ERROR
::61			rts

::com_GetDisk		b "G-D"
::com_PartNr		b "M-R",$68,$2c,$01
endif

;******************************************************************************
::tmp2 = HD_41!HD_71!HD_41_PP!HD_71_PP
if :tmp2 = TRUE
;******************************************************************************
;*** Neue Diskette öffnen.
:xLogNewPart		jsr	xPurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

			lda	#$ff			;Aktive Partition einlesen.
			sta	r3H
			LoadW	r4,GP_DATA
			jsr	xReadPDirEntry
			txa				;Diskettenfehler ?
			bne	:54			; => Ja, Abbruch...

			ldy	curDrive		;Partitions-Nr. speichern.
			lda	GP_DATA_PNR
			sta	drivePartData-8,y

			lda	GP_DATA_TYPE
			cmp	#PART_TYPE		;Stimmt Partitions-Format ?
			beq	:53			; => Ja, weiter...

			jsr	dir3Head_r4
			jsr	xReadPTypeData		;Erste gültige Partition suchen.
			txa
			bne	:54

			ldy	#$00
::51			lda	(r4L),y
			cmp	#PART_TYPE
			beq	:52
			iny
			cpy	#PART_MAX +1
			bne	:51

			ldx	#NO_PARTITION
			bne	:54

::52			sty	r3H			;Neue Partition speichern.

::53			ldx	#NO_ERROR
			lda	r3H
			cmp	#255			;Wurde Partition gewechselt ?
			beq	:54			; => Nein, weiter...

			ldy	curDrive
			sta	drivePartData-8,y
			jsr	xSwapPartition		;Neue Partition aktivieren.

::54			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.
endif

;******************************************************************************
::tmp3 = HD_81!HD_81_PP
if :tmp3 = TRUE
;******************************************************************************
;*** Neue Diskette öffnen.
:xLogNewPart		jsr	xExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

			lda	#$ff			;Aktive Partition einlesen.
			sta	r3H
			LoadW	r4,GP_DATA
			jsr	xReadPDirEntry
			txa				;Diskettenfehler ?
			bne	:54			; => Ja, Abbruch...

			ldy	curDrive		;Partitions-Nr. speichern.
			lda	GP_DATA_PNR
			sta	drivePartData-8,y

			lda	GP_DATA_TYPE
			cmp	#PART_TYPE		;Stimmt Partitions-Format ?
			beq	:53			; => Ja, weiter...

			jsr	dir3Head_r4
			jsr	xReadPTypeData		;Erste gültige Partition suchen.
			txa
			bne	:54

			ldy	#$01
::51			lda	(r4L),y
			cmp	#PART_TYPE
			beq	:52
			iny
			cpy	#PART_MAX +1
			bne	:51

			ldx	#NO_PARTITION
			bne	:54

::52			sty	r3H			;Neue Partition speichern.

::53			ldx	#NO_ERROR
			lda	r3H
			cmp	#255			;Wurde Partition gewechselt ?
			beq	:54			; => Nein, weiter...

			ldy	curDrive
			sta	drivePartData-8,y
			jsr	xSwapPartition		;Neue Partition aktivieren.

::54			jsr	Load_dir3Head

			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.
endif

;******************************************************************************
::tmp4 = HD_NM
if :tmp4 = TRUE
;******************************************************************************
;*** Neue Diskette öffnen.
:xLogNewPart		jsr	xPurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

			lda	#$ff			;Aktive Partition einlesen.
			sta	r3H
			LoadW	r4,GP_DATA
			jsr	xReadPDirEntry
			txa				;Diskettenfehler ?
			bne	:54			; => Ja, Abbruch...

			ldy	curDrive		;Partitions-Nr. speichern.
			lda	GP_DATA_PNR
			sta	drivePartData-8,y

			lda	GP_DATA_TYPE
			cmp	#PART_TYPE		;Stimmt Partitions-Format ?
			beq	:53			; => Ja, weiter...

			jsr	dir3Head_r4
			jsr	xReadPTypeData		;Erste gültige Partition suchen.
			txa
			bne	:54

			ldy	#$00
::51			lda	(r4L),y
			cmp	#PART_TYPE
			beq	:52
			iny
			cpy	#PART_MAX +1
			bne	:51

			ldx	#NO_PARTITION
			bne	:54

::52			sty	r3H			;Neue Partition speichern.

::53			ldx	#NO_ERROR
			lda	r3H
			cmp	#255			;Wurde Partition gewechselt ?
			beq	:54			; => Nein, weiter...

			ldy	curDrive
			sta	drivePartData-8,y
			jsr	xSwapPartition		;Neue Partition aktivieren.

::54			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.
endif

;******************************************************************************
::tmp5 = HD_NM_PP
if :tmp5 = TRUE
;******************************************************************************
;*** Neue Diskette öffnen.
:xLogNewPart		jsr	xPurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

			lda	#$ff			;Aktive Partition einlesen.
			sta	r3H
			LoadW	r4,GP_DATA
			jsr	xReadPDirEntry
			txa				;Diskettenfehler ?
			bne	:54			; => Ja, Abbruch...

			ldy	curDrive		;Partitions-Nr. speichern.
			lda	GP_DATA_PNR
			sta	drivePartData-8,y

			lda	GP_DATA_TYPE
			cmp	#PART_TYPE		;Stimmt Partitions-Format ?
			beq	:53			; => Ja, weiter...

			jsr	dir3Head_r4
			jsr	xReadPTypeData		;Erste gültige Partition suchen.
			txa
			bne	:54

			ldy	#$00
::51			lda	(r4L),y
			cmp	#PART_TYPE
			beq	:52
			iny
			cpy	#PART_MAX +1
			bne	:51

			ldx	#NO_PARTITION
			bne	:54

::52			sty	r3H			;Neue Partition speichern.

::53			ldx	#NO_ERROR
			lda	r3H
			cmp	#255			;Wurde Partition gewechselt ?
			beq	:54			; => Nein, weiter...

			ldy	curDrive
			sta	drivePartData-8,y
			jsr	xSwapPartition		;Neue Partition aktivieren.

::54			jsr	Load_dir3Head		;Bereich $9C80-$9D7F zurücksetzen.

			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.
endif
