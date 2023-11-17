; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Der folgende Datenbereich wird auch von "GEOS.MP3" mitverwendet.
;*** Der Datenbereich wird dazu von "GEOS.MP3" nachgeladen.
;******************************************************************************

;*** Zeiger auf ReBoot-Routinen.
.Vec_ReBoot		w ReBoot_SCPU
			w ReBoot_RL
			w ReBoot_REU
			w ReBoot_BBG

;*** MegaPatch-Kernal-Routinen.
;    Word = Zeiger auf Programmcode.
;    Word = Zeiger auf Adr. in REU.
;    Word = Anzahl Bytes.
.MP3_BANK_1		w x_EnterDeskTop
			w R2_ADDR_ENTER_DT
			w R2_SIZE_ENTER_DT

			w x_GetNextDay
			w R2_ADDR_GETNXDAY
			w R2_SIZE_GETNXDAY

			w x_DoAlarm
			w R2_ADDR_DOALARM
			w R2_SIZE_DOALARM

			w x_PanicBox
			w R2_ADDR_PANIC
			w R2_SIZE_PANIC

			w x_ToBASIC
			w R2_ADDR_TOBASIC
			w R2_SIZE_TOBASIC

			w x_GetFiles
			w R2_ADDR_GETFILES
			w R2_SIZE_GETFILES

			w x_GetFilesData
			w R2_ADDR_GFILDATA
			w R2_SIZE_GFILDATA

			w x_GetFilesIcon
			w R2_ADDR_GFILMENU
			w R2_SIZE_GFILMENU

			w x_ClrDlgScreen
			w R2_ADDR_DB_SCREEN
			w R2_SIZE_DB_SCREEN

.MP3_BANK_2a		w x_TaskSwitch
			w R2_ADDR_TASKMAN_B
			w R2_SIZE_TASKMAN

			w x_ScreenSaver
			w R2_ADDR_SCRSAVER
			w R2_SIZE_SCRSAVER

			w x_GetBackScrn
			w R2_ADDR_GETBSCRN
			w R2_SIZE_GETBSCRN

.MP3_BANK_2b		w x_SpoolMenu
			w R2_ADDR_SPOOLER
			w R2_SIZE_SPOOLER

			w x_SpoolPrint
			w R2_ADDR_PRNSPOOL
			w R2_SIZE_PRNSPOOL

			w x_Register
			w R2_ADDR_REGISTER
			w R2_SIZE_REGISTER

;******************************************************************************
;*** Der folgende Datenbereich wird auch von "GEOS.MP3" mitverwendet.
;*** Der Datenbereich wird dazu von "GEOS.MP3" nachgeladen.
;******************************************************************************
;*** Programmcode der zur Laufzeit installiert wird.

;--- AutoStart-Programme ausführen.
.AutoBoot_a		d "obj.AUTO.BOOT"		;AutoBoot-Routine.
.AutoBoot_b

;--- DoRAMOp-Routinen für CMD RAMLink.
.Code1a			d "obj.DvRAM_RL"
.Code1b
.Code1L			= (Code1b - Code1a)

;--- DoRAMOp-Routinen für C=REU.
.Code2a			d "obj.DvRAM_REU"
.Code2b
.Code2L			= (Code2b - Code2a)

;--- DoRAMOp/Sprungtabelle für GeoRAM.
.Code3a			d "obj.DvRAM_BBG.1"
.Code3b
.Code3L			= (Code3b - Code3a)

;--- DoRAMOp-Routinen für GeoRAM.
.Code4a			d "obj.DvRAM_BBG.2"
.Code4b
.Code4L			= (Code4b - Code4a)

;--- FillRAM/MoveData/InitForIO/DoneWithIO/SuperCPU-Optimierung.
.Code6a			d "obj.Patch_SCPU"
.Code6b
.Code6L			= (Code6b - Code6a)

;--- Srungtabelle für SuperCPU-Funktionen.
.Code8a			jmp	sSCPU_OptOn
			jmp	sSCPU_OptOff
			jmp	sSCPU_SetOpt
.Code8b
.Code8L			= (Code8b - Code8a)

;--- DoRAMOp-16Bit-Routinen für RAMCard.
.Code9a			d "obj.Patch_SRAM"
.Code9b
.Code9L			= (Code9b - Code9a)

;--- DoRAMOp/Sprungtabelle für RAMCard.
.Code10a		d "obj.DvRAM_SCPU"
.Code10b
.Code10L		= (Code10b - Code10a)
