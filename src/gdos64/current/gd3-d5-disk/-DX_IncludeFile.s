; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Include-Dateien.
;Hinweis#1:
;Die Reihenfolge nicht verändern, da
;einige Dateien andere Dateien für den
;Assembler-Vorgang benötigen.
;
;Hinweis#2:
;Ob ein Treiber TurboDOS oder KernalDOS
;verwendet wird über die Include-Datei
;"opt.Disk.Config" definiert.
;
;TD-Includes für TurboDOS werden
;mit "TDOS_ENABLED" eingebunden.
;
;FD-Includes für KernalDOS werden
;mit "TDOS_DISABLED" eingebunden.
;
:D01			t "-D3_FindRAMLink"
:D02			t "-D3_GetRLPData"
:D03			t "-D3_SvLd_dir3Hd"
:D04			t "-D3_SwapDkNmDat"
:D05			t "-D3_TestTrSeAdr"
:D06			t "-D3_ClrDkBlkBuf"
:D07			t "-D3_SvLd_RegDat"
:D08			t "-D3_DefSkAdrREU"
:D10			t "-D3_Dsk_DoSekOp"
:D11			t "-D3_1541_Cache"
:D12			t "-D3_SdiskBlkBuf"
:D13			t "-D3_ScurDirHead"
:D14			t "-D3_S1stDirSek"
:D15			t "-D3_Sdir3Head"
:D16			t "-D3_InitForIO"
:D17			t "-D3_DoneWithIO"
:D18			t "-D3_PurgeTurbo"
:D19t			t "-TD_ExitTurbo"
:D19f			t "-FD_ExitTurbo"
:D20t			t "-TD_EnterTurbo"
:D20f			t "-FD_EnterTurbo"
:D21			t "-D3_OpenDir"
:D22			t "-D3_OpenDisk"
:D23			t "-D3_OpenPart"
:D25			t "-D3_LogNewPart"
:D26t			t "-TD_NewDisk"
:D26f			t "-FD_NewDisk"
:D27			t "-D3_CalcBlkFree"
:D28			t "-D3_GetDiskSize"
:D29			t "-D3_ChkDkGEOS"
:D30			t "-D3_SetGEOSDisk"
:D31			t "-D3_ChangeDDev"
:D32t			t "-TD_GetBlock"
:D32f			t "-FD_GetBlock"
:D33t			t "-TD_PutBlock"
:D33f			t "-FD_PutBlock"
:D34t			t "-TD_VerWrBlock"
:D34f			t "-FD_VerWrBlock"
:D35			t "-D3_DirHeadJob"
:D38			t "-D3_GetFreeDirB"
:D39			t "-D3_CreateNewDB"
:D40			t "-D3_GetDirEntry"
:D41			t "-D3_GetBorderB"
:D42			t "-D3_GetPDEntry"
:D43			t "-D3_GetPTypes"
:D45			t "-D3_BlkAlloc"
:D46			t "-D3_AllocFreBlk"		;AllocFreBlk und SwapBlkMode wegen
:D48			t "-D3_SwapBlkMode"		;BEQ/BNE-Befehlen nicht trennen!
:D49			t "-D3_FindBAMBit"
:D50			t "-D3_SetNextFree"
:D51			t "-D3_GetDirHead"
:D52			t "-D3_PutDirHead"
:D53			t "-D3_BAMBlockJob"
:D54			t "-D3_SetBAM_TrSe"
:D55			t "-D3_IsDirSkFree"
:D56			t "-D3_GetMaxSekTr"
:D57t			t "-TD_InitTurbo"
:D59			t "-D3_GetBAMOffst"
:D60t			t "-TD_ExecTurbo"
:D60f			t "-FD_ExecTurbo"
:D61t			t "-TD_TurboPutByt"
:D61f			t "-FD_TurboPutByt"
:D62t			t "-TD_TurboGetByt"
:D62f			t "-FD_TurboGetByt"
:D62v			t "-FD_TurboVerByt"
:D63t			t "-TD_WriteTurbo"
:D64t			t "-TD_TPutGetBlk"
:D65t			t "-TD_DataClkRout"
:D66t			t "-TD_GetDskError"
:D66f			t "-FD_GetDskError"
:D67			t "-D3_SendFCom"
:D68			t "-D3_FComInitDsk"
:D69			t "-D3_StashDrvDat"
:D70t			t "-TD_ComDevice"
:D70f			t "-FD_ComDevice"
:D71f			t "-FD_DevChannel"
:D72f			t "-FD_Functions"
