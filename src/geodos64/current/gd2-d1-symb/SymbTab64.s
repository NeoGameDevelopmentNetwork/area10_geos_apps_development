﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Startadressen der Ladeprogramme.
:BASE_GEOSBOOT		= $1000				;startadress geosboot-code.
:BASE_GEOS_SYS		= $2e00				;startadress geos-sys-files.
:BASE_REBOOT		= $4000				;startadress reboot-code.

;Variablen für 64/128er Anpassung
:ADD1_W			=	$0000			;$2000 bei 128er
:DOUBLE_B		=	$00			;$80 bei 128er
:DOUBLE_W		=	$0000			;$8000 bei 128er

;*** Speicherbelegung.
:MOUSE_JMP		= $fe80				;start of mouse jump table
:MOUSE_BASE		= $fe80				;start of input driver
:END_MOUSE		= $fffa				;end of input driver

;*** Einsprünge im Maustreiber.
:InitMouse		= $fe80
:SlowMouse		= $fe83
:UpdateMouse		= $fe86
:SetMouse		= $fe89

;*** ROM-Routinen.
:ROM_BASIC_READY	= $a474
:ROM_OUT_STRING		= $ab1e
:ROM_OUT_NUMERIC	= $bdcd

;*** Variablen im C64-Kernal.
:CLEAR			= $e544				;Bildschirm löschen
:VARTAB			= $002b
:TAPE1			= $00b2
:PNTR			= $00d3
:NDX			= $00c6
:KEYD			= $0277
:MEMSTR			= $0281
:MEMSIZ			= $0283
:COLOR			= $0286
:HIBASE			= $0288
:PAL_NTSC		= $02a6
:TBUFFR			= $033c
:NMIINV			= $0318

;Systemvariablen.
:DI_VecDefTab		= $003f				;   1 Word Nur C64  !!!
:CallRoutVec		= $0041				;   1 Word
:DB_VecDefTab		= $0043				;   1 Word
:SetStream		= $0045				;   8 Byte;Zwischenspeicher Zeichensatz.

:DM_MenuType		= $86c0				;   1 Byte
:DM_MenuRange		= $86c1				;   6 Byte
:DM_MenuTabL		= $86c7				;   4 Byte
:DM_MenuTabH		= $86cb				;   4 Byte
:DM_MseOnEntry		= $86cf				;   4 Byte
:DM_MenuPosL		= $86d3				;  15 Byte
:DM_MenuPosH		= $86e2				;  15 Byte
:ProcCurDelay		= $86f1				;  40 Byte Prozesse/20 Zähler   /Aktuell
:ProcStatus		= $8719				;  20 Byte Prozesse/20 Statusbytes
:ProcRout		= $872d				;  40 Byte Prozesse/20 Routinen x 2 Byte
:ProcDelay		= $8755				;  40 Byte Prozesse/20 Zähler   x 2 Byte
:MaxProcess		= $877d				;   1 Byte
:MaxSleep		= $877e				;   1 Byte
:SleepTimeL		= $877f				;  20 Byte Sleep/20 Zähler für Wartezeit
:SleepTimeH		= $8793				;  20 Byte Sleep/20 Zähler für Wartezeit
:SleepRoutL		= $87a7				;  20 Byte Sleep/20 Low -Bytes-Programmadresse
:SleepRoutH		= $87bb				;  20 Byte Sleep/20 High-Bytes-Programmadresse
:InpStrMaxKey		= $87cf				;   1 Byte
:InpStrgLen		= $87d0				;   1 Byte
:InpStrgKVecBuf		= $87d1				;   1 Word
:InpStrgFault		= $87d3				;   1 Byte
:CurCrsrPos		= $87d1				;   1 Byte  GetString: Cursor-Position.
:InpStartXPosL		= $87d2				;   1 Byte  GetString: Low -X-Eingabeposition.
:InpStartXPosH		= $87d3				;   1 Byte  GetString: High-X-Eingabeposition.
:GS_Xpos		= $87d4				;   1 Word GraphicsString: X-Aktuell
:GS_XposL		= $87d4				;   1 Byte GraphicsString: X-Aktuell
:GS_XposH		= $87d5				;   1 Byte GraphicsString: X-Aktuell
:GS_Ypos		= $87d6				;   1 Byte GraphicsString: Y-Aktuell
:keyBufPointer		= $87d7				;   1 Byte
:MaxKeyInBuf		= $87d8				;   1 Byte
:keyMode		= $87d9				;   1 Byte
:keyBuffer		= $87da				;  16 Byte Tastaturpuffer
:currentKey		= $87ea				;   1 Byte
:KB_LastKeyTab		= $87eb				;   8 Byte
:KB_MultipleKey		= $87f3				;   8 Byte
:BitStrDataMask		= $87fc				;   1 Byte
:BitStr1stBit		= $87fd				;   1 Byte
:BaseUnderLine		= $87fe				;   1 Byte
:NewStream		= $87ff				;   8 Byte

;*** Variablen im Bereich $8800-$8FFF.
:CurCharWidth		= $8807				;   1 Byte
:DI_VecToEntry		= $8808				;   1 Byte
:DI_SelectedIcon	= $8809				;   1 Byte
:AlarmAktiv		= $880a				;   1 Byte
:IRQ_BufAkku		= $880b				;   1 Byte
:DB_Icon_Tab		= $880c				;  68 Byte
:DA_ReturnAdr		= $8850				;   1 Word
:DA_RetStackP		= $8852				;   1 Byte
:DB_ReturnAdr		= $8853				;   1 Word
:DB_RetStackP		= $8855				;   1 Byte
:DB_FilesInTab		= $8856				;   1 Byte
:DB_GetFileX		= $8857				;   1 Byte
:DB_GetFileY		= $8858				;   1 Byte
:DB_FileTabVec		= $8859				;   1 Word
:DB_1stFileInTab	= $885b				;   1 Byte
:DB_SelectedFile	= $885c				;   1 Byte
:DA_ResetScrn		= $885d				;   1 Byte
:LoadFileMode		= $885e				;   1 Byte
:LoadBufAdr		= $885f				;   1 Word Zwischenspeicher ":GetFile"
:VLIR_HdrDirSek		= $8861				;   1 Word
:VLIR_HdrDEntry		= $8863				;   1 Word
:VLIR_HeaderTr		= $8865				;   1 Byte
:VLIR_HeaderSe		= $8866				;   1 Byte
:VerWriteFlag		= $8867				;   1 Byte;Datei schreiben/vergleichen
:StartDTdrv		= $8868				;   1 Byte

:savedmoby		= $88bb				;   1 Byte
:scr80polar		= $88bc				;   1 Byte
:scr80colors		= $88bd				;   1 Byte
:vdcClrMode		= $88be				;   1 Byte
:driveData		= $88bf				;   4 Byte
:ramExpSize		= $88c3				;   1 Byte
:sysRAMFlg		= $88c4				;   1 Byte
:firstBoot		= $88c5				;   1 Byte
:curType		= $88c6				;   1 Byte
:ramBase		= $88c7				;   4 Byte
:inputDevName		= $88cb				;  17 Byte
:DrCCurDkNm		= $88dc				;  18 Byte
:DrDCurDkNm		= $88ee				;  18 Byte
:dir2Head		= $8900				; 256 Byte
:spr0pic		= $8a00				;  64 Byte
:spr1pic		= $8a40				;  64 Byte
:spr2pic		= $8a80				;  64 Byte
:spr3pic		= $8ac0				;  64 Byte
:spr4pic		= $8b00				;  64 Byte
:spr5pic		= $8b40				;  64 Byte
:spr6pic		= $8b80				;  64 Byte
:spr7pic		= $8bc0				;  64 Byte
:obj0Pointer		= $8ff8				;   1 Byte
:obj1Pointer		= $8ff9				;   1 Byte
:obj2Pointer		= $8ffa				;   1 Byte
:obj3Pointer		= $8ffb				;   1 Byte
:obj4Pointer		= $8ffc				;   1 Byte
:obj5Pointer		= $8ffd				;   1 Byte
:obj6Pointer		= $8ffe				;   1 Byte
:obj7Pointer		= $8fff				;   1 Byte
