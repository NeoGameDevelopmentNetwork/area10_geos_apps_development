; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp01a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp01b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp01c = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!RL_41!RL_71!RL_81!RL_NM
::tmp01d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp01  = :tmp01a!:tmp01b!:tmp01c!:tmp01d
if :tmp01 = TRUE
;******************************************************************************
;*** Sprungtabelle.
:vInitForIO		w xInitForIO
:vDoneWithIO		w xDoneWithIO
:vExitTurbo		w xExitTurbo
:vPurgeTurbo		w xPurgeTurbo
:vEnterTurbo		w xEnterTurbo
:vChangeDiskDev		w xChangeDiskDev
:vNewDisk		w xNewDisk
:vReadBlock		w xReadBlock
:vWriteBlock		w xWriteBlock
:vVerWriteBlock		w xVerWriteBlock
:vOpenDisk		w xOpenDisk
:vGetBlock		w xGetBlock
:vPutBlock		w xPutBlock
:vGetDirHead		w xGetDirHead
:vPutDirHead		w xPutDirHead
:vGetFreeDirBlk		w xGetFreeDirBlk
:vCalcBlksFree		w xCalcBlksFree
:vFreeBlock		w xFreeBlock
:vSetNextFree		w xSetNextFree
:vFindBAMBit		w xFindBAMBit
:vNxtBlkAlloc		w xNxtBlkAlloc
:vBlkAlloc		w xBlkAlloc
:vChkDkGEOS		w xChkDkGEOS
:vSetGEOSDisk		w xSetGEOSDisk
endif

;******************************************************************************
::tmp02 = PC_DOS
if :tmp02 = TRUE
;******************************************************************************
;*** Sprungtabelle.
:vInitForIO		w xInitForIO
:vDoneWithIO		w xDoneWithIO
:vExitTurbo		w xExitTurbo
:vPurgeTurbo		w xPurgeTurbo
:vEnterTurbo		w xEnterTurbo
:vChangeDiskDev		w xChangeDiskDev
:vNewDisk		w xNewDisk
:vReadBlock		w xReadBlock
:vWriteBlock		w xIllegalCommand
:vVerWriteBlock		w xIllegalCommand
:vOpenDisk		w xOpenDisk
:vGetBlock		w xGetBlock
:vPutBlock		w xIllegalCommand
:vGetDirHead		w xGetDirHead
:vPutDirHead		w xIllegalCommand
:vGetFreeDirBlk		w xIllegalCommand
:vCalcBlksFree		w xCalcBlksFree
:vFreeBlock		w xIllegalCommand
:vSetNextFree		w xIllegalCommand
:vFindBAMBit		w xIllegalCommand
:vNxtBlkAlloc		w xIllegalCommand
:vBlkAlloc		w xIllegalCommand
:vChkDkGEOS		w xChkDkGEOS
:vSetGEOSDisk		w xIllegalCommand
endif

;******************************************************************************
::tmp11a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp11b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp11  = :tmp11a!:tmp11b
if :tmp11 = TRUE
;******************************************************************************
;*** Erweiterte Laufwerksfunktionen.
:vGet1stDirEntry	jmp	xGet1stDirEntry
:vGetNxtDirEntry	jmp	xGetNxtDirEntry
:vGetBorderBlock	jmp	xGetBorderBlock
:vCreateNewDirBlk	jmp	xCreateNewDirBlk
:vGetBlock_dskBuf	jmp	xGetBlock_dskBuf
:vPutBlock_dskBuf	jmp	xPutBlock_dskBuf
:vTurboRoutine_r1	jmp	xTurboRoutine_r1
:vGetDiskError		jmp	xGetDiskError
:vAllocateBlock		jmp	xAllocateBlock
:vReadLink		jmp	xReadLink
endif

;******************************************************************************
::tmp12 = PC_DOS
if :tmp12 = TRUE
;******************************************************************************
;*** Erweiterte Laufwerksfunktionen.
:vGet1stDirEntry	jmp	xGet1stDirEntry
:vGetNxtDirEntry	jmp	xGetNxtDirEntry
:vGetBorderBlock	jmp	xIllegalCommand
:vCreateNewDirBlk	jmp	xIllegalCommand
:vGetBlock_dskBuf	jmp	xGetBlock_dskBuf
:vPutBlock_dskBuf	jmp	xIllegalCommand
:vTurboRoutine_r1	jmp	xTurboRoutine_r1
:vGetDiskError		jmp	xGetDiskError
:vAllocateBlock		jmp	xIllegalCommand
:vReadLink		jmp	xIllegalCommand
endif

;******************************************************************************
::tmp13 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp13 = TRUE
;******************************************************************************
;*** Erweiterte Laufwerksfunktionen.
:vGet1stDirEntry	jmp	xGet1stDirEntry
:vGetNxtDirEntry	jmp	xGetNxtDirEntry
:vGetBorderBlock	jmp	xGetBorderBlock
:vCreateNewDirBlk	jmp	xCreateNewDirBlk
:vGetBlock_dskBuf	jmp	xGetBlock_dskBuf
:vPutBlock_dskBuf	jmp	xPutBlock_dskBuf
:vTurboRoutine_r1	ldx	#NO_ERROR
			rts
:vGetDiskError		jmp	xGetDiskError
:vAllocateBlock		jmp	xAllocateBlock
:vReadLink		jmp	xReadLink
endif

;******************************************************************************
::tmp14a = RL_41!RL_71!RL_81!RL_NM
::tmp14b = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp14  = :tmp14a!:tmp14b
if :tmp14 = TRUE
;******************************************************************************
;*** Erweiterte Laufwerksfunktionen.
:vGet1stDirEntry	jmp	xGet1stDirEntry
:vGetNxtDirEntry	jmp	xGetNxtDirEntry
:vGetBorderBlock	jmp	xGetBorderBlock
:vCreateNewDirBlk	jmp	xCreateNewDirBlk
:vGetBlock_dskBuf	jmp	xGetBlock_dskBuf
:vPutBlock_dskBuf	jmp	xPutBlock_dskBuf
:vTurboRoutine_r1	ldx	#NO_ERROR		;1541: TurboRoutine ausführen.
			rts
:vGetDiskError		ldx	#NO_ERROR		;1541: TurboDOS-Fehler einlesen.
			rts
:vAllocateBlock		jmp	xAllocateBlock
:vReadLink		jmp	xReadLink
endif

;*** Kennbyte für Laufwerkstreiber.
:xDiskDrvType		b DiskDrvMode
:xDiskDrvVersion	b DriverVersion

;******************************************************************************
::tmp21a = C_41!C_71!C_81
::tmp21b = FD_41!FD_71!FD_81!HD_41!HD_71!HD_81
::tmp21c = HD_41_PP!HD_71_PP!HD_81_PP!RL_41!RL_71!RL_81
::tmp21d = RD_41!RD_71!RD_81
::tmp21  = :tmp21a!:tmp21b!:tmp21c!:tmp21d
if :tmp21 = TRUE
;******************************************************************************
;*** Einsprungtabelle für NativeMode-Funktionen.
:vOpenRootDir		ldx	#ILLEGAL_DEVICE
			rts
:vOpenSubDir		ldx	#ILLEGAL_DEVICE
			rts
:vGetBAMBlock		ldx	#ILLEGAL_DEVICE
			rts
:vPutBAMBlock		ldx	#ILLEGAL_DEVICE
			rts
endif

;******************************************************************************
::tmp22 = PC_DOS
if :tmp22 = TRUE
;******************************************************************************
;*** Einsprungtabelle für NativeMode-Funktionen.
:vOpenRootDir		jmp	xOpenRootDir
:vOpenSubDir		jmp	xOpenSubDir
:vGetBAMBlock		ldx	#ILLEGAL_DEVICE
			rts
:vPutBAMBlock		ldx	#ILLEGAL_DEVICE
			rts
endif

;******************************************************************************
::tmp23a = FD_NM!HD_NM!HD_NM_PP!RL_NM!IEC_NM!S2I_NM
::tmp23b = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp23  = :tmp23a!:tmp23b
if :tmp23 = TRUE
;******************************************************************************
;*** Einsprungtabelle für NativeMode-Funktionen.
:vOpenRootDir		jmp	xOpenRootDir
:vOpenSubDir		jmp	xOpenSubDir
:vGetBAMBlock		jmp	xGetBAMBlock
:vPutBAMBlock		jmp	xPutBAMBlock
endif

;******************************************************************************
::tmp31 = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp31 = TRUE
;******************************************************************************
;*** Erweiterte Funktionen.
:vGetPDirEntry		ldx	#ILLEGAL_DEVICE
			rts
:vReadPDirEntry		ldx	#ILLEGAL_DEVICE
			rts
:vOpenPartition		ldx	#ILLEGAL_DEVICE
			rts
:vSwapPartition		ldx	#ILLEGAL_DEVICE
			rts
:vGetPTypeData		ldx	#ILLEGAL_DEVICE
			rts
:vSendCommand		ldx	#ILLEGAL_DEVICE
			rts
endif

;******************************************************************************
::tmp32 = C_41!C_71!C_81!PC_DOS!IEC_NM!S2I_NM
if :tmp32 = TRUE
;******************************************************************************
;*** Erweiterte Funktionen.
:vGetPDirEntry		ldx	#ILLEGAL_DEVICE
			rts
:vReadPDirEntry		ldx	#ILLEGAL_DEVICE
			rts
:vOpenPartition		ldx	#ILLEGAL_DEVICE
			rts
:vSwapPartition		ldx	#ILLEGAL_DEVICE
			rts
:vGetPTypeData		ldx	#ILLEGAL_DEVICE
			rts
:vSendCommand		jmp	xSendCommand
endif

;******************************************************************************
::tmp33a = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp33b = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!RL_41!RL_71!RL_81!RL_NM
::tmp33  = :tmp33a!:tmp33b
if :tmp33 = TRUE
;******************************************************************************
;*** Erweiterte CMD-Funktionen.
:vGetPDirEntry		jmp	xGetPDirEntry
:vReadPDirEntry		jmp	xReadPDirEntry
:vOpenPartition		jmp	xOpenPartition
:vSwapPartition		jmp	xSwapPartition
:vGetPTypeData		jmp	xGetPTypeData
:vSendCommand		jmp	xSendCommand
endif

;*** Kennung für erweiterte Laufwerkstreiber.
:vDiskDrvTypeCode	b "MPDD3",NULL			;High-Performance-DiskDriver V3.
