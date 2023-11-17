; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Der folgende Datenbereich wird auch von "GD.UPDATE" mitverwendet.
;*** Der Datenbereich wird dazu von "GD.UPDATE" nachgeladen.
;******************************************************************************

;*** Zeiger auf ReBoot-Routinen.
.Vec_ReBoot		w ReBoot_SCPU
			w ReBoot_RL
			w ReBoot_REU
			w ReBoot_BBG

;*** GeoDOS64-Kernal-Routinen.
;    Word = Zeiger auf Programmcode.
;    Word = Zeiger auf Adr. in REU.
;    Word = Anzahl Bytes.
.MP3_BANK_1		w x_InitSystem
			w R2_ADDR_INIT_SYS
			w R2_SIZE_INIT_SYS

			w x_EnterDeskTop
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

			w x_GetBackScrn
			w R2_ADDR_GETBSCRN
			w R2_SIZE_GETBSCRN

			w x_Register
			w R2_ADDR_REGISTER
			w R2_SIZE_REGISTER

			w x_GeoHelp
			w R2_ADDR_GEOHELP
			w R2_SIZE_GEOHELP

;--- Ergänzung: 16.02.21/M.Kanet
;Bildschirmschoner immer installieren,
;damit der Speicherbereich gültig
;initialisiert wird. Sonst treten evtl.
;Probleme beim auslesen des Names des
;aktuellen Bildschirmschoners auf.
			w x_ScrSaver
			w R2_ADDR_SCRSAVER
			w R2_SIZE_SCRSAVER

;******************************************************************************
;*** Der folgende Datenbereich wird auch von "GEOS64.MP3" mitverwendet.
;*** Der Datenbereich wird dazu von "GEOS64.MP3" nachgeladen.
;******************************************************************************
;*** Programmcodes.
.AutoBoot_a		d "obj.GD.AUTOBOOT"		;AutoBoot-Routine.
.AutoBoot_b

.Code1a			d "obj.DvRAM_RLNK"		;RAM-Treiber für CMD.
.Code1b
.Code1L			= (Code1b - Code1a)

.Code2a			d "obj.DvRAM_CREU"		;RAM-Treiber für REU.
.Code2b
.Code2L			= (Code2b - Code2a)

.Code3a			d "obj.DvRAM_GRAM"		;RAM-Treiber für BBGRAM.
.Code3b
.Code3L			= (Code3b - Code3a)

.Code4a			d "obj.DvRAM_GSYS"		;RAM-Treiber für BBGRAM.
.Code4b
.Code4L			= (Code4b - Code4a)

.Code6a			d "obj.Patch_SCPU"		;Patches für SCPU.
.Code6b
.Code6L			= (Code6b - Code6a)

.Code8a			jmp	sSCPU_OptOn
			jmp	sSCPU_OptOff
			jmp	sSCPU_SetOpt
.Code8b
.Code8L			= (Code8b - Code8a)

.Code9a			d "obj.Patch_SRAM"		;Patches für RAMCard.
.Code9b
.Code9L			= (Code9b - Code9a)

.Code10a		d "obj.DvRAM_SRAM"		;RAM-Treiber für SuperCPU.
.Code10b
.Code10L		= (Code10b - Code10a)
