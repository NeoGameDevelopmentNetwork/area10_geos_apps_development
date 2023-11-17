; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = FD_41!FD_71!FD_81!FD_NM
if :tmp0 = TRUE
;******************************************************************************
;*** Partition wechseln.
:xOpenPartition		jsr	xExitTurbo
			jsr	InitForIO
			jsr	xSwapPartition
			jsr	DoneWithIO
			txa
			bne	exitOpenPart
			jmp	xOpenDisk

;*** Partition wechseln.
;    Übergabe:		r3H	= Partitions-Nr.
:xSwapPartition		ldx	#ILLEGAL_PARTITION
			lda	r3H
			cmp	#PART_MAX +1
			bcs	exitOpenPart

			LoadW	r4,GP_DATA
			jsr	xReadPDirEntry
			txa
			bne	exitOpenPart

			ldx	#NO_PART_FD_ERR
			bit	GP_DATA_TYPE +1
			bpl	exitOpenPart

			ldx	#PART_FORMAT_ERR
			lda	GP_DATA_TYPE
			cmp	#PART_TYPE
			bne	exitOpenPart

			lda	r3H
			sta	CMD_CP +2

			ldx	#> CMD_CP
			lda	#< CMD_CP
			ldy	#$03
			jsr	SendComVLen		;"C-P"-Befehl senden.
			bne	exitOpenPart		;Fehler? => Ja, Abbruch...

			jsr	UNLSN

			jsr	FCom_InitDisk		;"I0:"-Befehl an Laufwerk senden.
			txa				;Fehler?
			bne	exitOpenPart		; => Ja, Abbruch...

			ldx	curDrive
			lda	r3H			;Aktive Partition speichern.
			sta	drivePartData -8,x

			ldx	#NO_ERROR
:exitOpenPart		rts
endif

;******************************************************************************
::tmp1 = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp1 = TRUE
;******************************************************************************
;*** Partition wechseln.
:xOpenPartition		jsr	xExitTurbo
			jsr	InitForIO
			jsr	xSwapPartition
			jsr	DoneWithIO
			txa
			bne	exitOpenPart
			jmp	xOpenDisk

;*** Partition wechseln.
;    Übergabe:		r3H	= Partitions-Nr.
:xSwapPartition		ldx	#ILLEGAL_PARTITION
			lda	r3H
			cmp	#PART_MAX +1
			bcs	exitOpenPart

			LoadW	r4,GP_DATA
			jsr	xReadPDirEntry
			txa
			bne	exitOpenPart

			stx	STATUS

			ldx	#PART_FORMAT_ERR
			lda	GP_DATA_TYPE
			cmp	#PART_TYPE
			bne	exitOpenPart

			lda	r3H
			sta	CMD_CP +2

			ldx	#> CMD_CP
			lda	#< CMD_CP
			ldy	#$03
			jsr	SendComVLen		;"C-P"-Befehl senden.
			bne	exitOpenPart		;Fehler? => Ja, Abbruch...

			jsr	UNLSN

			jsr	FCom_InitDisk		;"I0:"-Befehl an Laufwerk senden.
			txa				;Fehler?
			bne	exitOpenPart		; => Ja, Abbruch...

			ldx	curDrive
			lda	r3H			;Aktive Partition speichern.
			sta	drivePartData -8,x

			ldx	#NO_ERROR
:exitOpenPart		rts
endif

;******************************************************************************
::tmp2 = RL_41!RL_71!RL_81!RL_NM
if :tmp2 = TRUE
;******************************************************************************
;*** Partition wechseln.
:xOpenPartition		jsr	xExitTurbo
			jsr	InitForIO
			jsr	xSwapPartition
			jsr	DoneWithIO
			txa
			bne	exitOpenPart
			jmp	xOpenDisk

;*** Partition wechseln.
;    Übergabe:		r3H	= Partitions-Nr.
:xSwapPartition		ldx	#ILLEGAL_PARTITION
			lda	r3H
			cmp	#PART_MAX +1
			bcs	exitOpenPart

			LoadW	r4,GP_DATA
			jsr	xReadPDirEntry
			txa
			bne	exitOpenPart

			ldx	#PART_FORMAT_ERR
			lda	GP_DATA_TYPE
			cmp	#PART_TYPE
			bne	exitOpenPart

			lda	r3H
			sta	CMD_CP +2

			ldx	#> CMD_CP
			lda	#< CMD_CP
			ldy	#$03
			jsr	SendComVLen		;"C-P"-Befehl senden.
			bne	exitOpenPart		;Fehler? => Ja, Abbruch...

			jsr	UNLSN

;--- Ergänzung: 11.07.21/M.Kanet
;Unter VICE ist es ggf. notwendig den
;"I"-Befehl an das Laufwerk zu senden,
;da sonst die BAM evtl. nicht immer
;aktuell ist.
			jsr	FCom_InitDisk		;"I0:"-Befehl an Laufwerk senden.
			txa				;Fehler?
			bne	exitOpenPart		; => Ja, Abbruch...

			ldx	curDrive
			lda	GP_DATA   +20
			sta	ramBase   - 8,x
			lda	GP_DATA   +21		;Nur um kompatibel zu alten Prg.
			sta	driveData + 3		;zu bleiben. ":driveData" wird von
							;die RL-Treibern nicht benötigt.
							;Die 1571-Treiber ändern dieses
							;Bytes ebenfalls nicht mehr!

			lda	r3H			;Aktive Partition speichern.
			sta	drivePartData -8,x
			sta	RL_PartNr

;--- Ergänzung: 18.10.18/M.Kanet
;Startadresse Partition in Laufwerkstreiber übertragen.
			tay
			ldx	RL_PartADDR_L  ,y
			stx	RL_PartADDR+0
			ldx	RL_PartADDR_H  ,y
			stx	RL_PartADDR+1

			ldx	#NO_ERROR
:exitOpenPart		rts
endif

;******************************************************************************
::tmp3a = FD_41!FD_71!FD_81!FD_NM
::tmp3b = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp3c = RL_41!RL_71!RL_81!RL_NM
::tmp3 = :tmp3a!:tmp3b!:tmp3c
if :tmp3 = TRUE
;******************************************************************************
:CMD_CP			b $43,$d0,$00
endif
