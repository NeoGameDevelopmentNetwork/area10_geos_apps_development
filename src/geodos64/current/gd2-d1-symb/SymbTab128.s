; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Startadressen der Ladeprogramme.
:BASE_GEOSBOOT		= $1d00				;startadress geosboot-code.
:BASE_GEOS_SYS		= $4000				;startadress geos-sys-files beim Bootup
:BASE_GEOS_SYS128	= $2fb0				;startadress geos-sys-files bei GEOS2.0 Installation
:BASE_REBOOT		= $4000				;startadress reboot-code.

;*** Speicherbelegung.
:MOUSE_JMP		= $fe80				;start of mouse jump table
:MOUSE_BASE		= $fd00				;start of input driver C128
:END_MOUSE		= $fe7f				;end of input driver C128

;*** ROM-Routinen.
:ROM_BASIC_READY	= $4d2a
:ROM_OUT_STRING		= $55e2
:ROM_OUT_NUMERIC	= $8e32

;*** Variablen im C128-Kernal.
;:VARTAB		= $002b
;:TAPE1			= $00b2
;:PNTR			= $00d3
;:NDX			= $00c6
;:KEYD			= $0277
;:MEMSTR		= $0281
;:MEMSIZ		= $0283
:COLOR			= $0241
;:HIBASE		= $0288
:PAL_NTSC		= $0a03
;:TBUFFR		= $033c
;:NMIINV		= $0318
:CLEAR			= $c142				;Bildschirm löschen

;*** Systemvariablen.
:graphMode		= $003f				;   1 Byte
:DI_VecDefTab		= $0040				;   1 Byte
:DB_VecDefTab		= $0044				;   1 Word
:SetStream		= $0046				;   8 Byte;Zwischenspeicher Zeichensatz.
:DM_MenuType		= $86c0				;   1 Byte
:DM_MenuRange		= $86c1				;   6 Byte
:DM_MenuTabL		= $86c7				;   4 Byte
:DM_MenuTabH		= $86cb				;   4 Byte
:DM_MseOnEntry		= $86cf				;   4 Byte
:DM_MenuPosL		= $86d3				;  15 Byte
:DM_MenuPosH		= $86e2				;  15 Byte
:ProcCurDelay		= $86f1				;  40 Byte Prozesse/20 Zähler/Aktuell
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
:keyMode		= $87d9				;   1 Byte Repeatzähler für Tastaturpuffer
:keyBuffer		= $87da				;  16 Byte Tastaturpuffer
:currentKey		= $87ea				;   1 Byte
:KB_LastKeyTab		= $87eb				;   8 Byte
:KB_MultipleKey		= $87f6				;   8 Byte

;*** Variablen im Bereich $8008-$8FFF.
;			= $87ff
:BitStrDataMask		= $8802				;   1 Byte
:BitStr1stBit		= $8803				;   1 Byte
:BaseUnderLine		= $8804				;   1 Byte
:NewStream		= $8805				;   8 Byte

:CurCharWidth		= $880d				;   1 Byte
:CurStreamCard		= $880e				;   1 Byte
:StrBitXposL		= $880f				;   1 Byte
:StrBitXposH		= $8810				;   1 Byte
:DI_VecToEntry		= $8819				;   1 Byte
:c128_alphaFlag		= $881a				;   1 Byte
:DI_SelectedIcon	= $881b				;   1 Byte
:AlarmAktiv		= $881c				;   1 Byte Zähler für Dauer des Alarms
:DB_Icon_Tab		= $881f				;  68 Byte
:DA_ReturnAdr		= $8863				;   1 Word
:DA_RetStackP		= $8865				;   1 Byte
:DB_ReturnAdr		= $8866				;   1 Word
:DB_RetStackP		= $8868				;   1 Byte
:DB_FilesInTab		= $8869				;   1 Byte
:DB_GetFileX		= $886a				;   1 Byte
:DB_GetFileY		= $886b				;   1 Byte
:DB_FileTabVec		= $886c				;   1 Word
:DB_1stFileInTab	= $886e				;   1 Byte
:DB_SelectedFile	= $886f				;   1 Byte
:DA_ResetScrn		= $8870				;   1 Byte
:DB_DblBit		= $8871				;   1 Byte
:LoadFileMode		= $8872				;   1 Byte
:LoadBufAdr		= $8873				;   1 Word Zwischenspeicher ":GetFile"

:VLIR_HdrDirSek		= $8875				;   1 Word
:VLIR_HdrDEntry		= $8877				;   1 Word
:VLIR_HeaderTr		= $8879				;   1 Byte
:VLIR_HeaderSe		= $887a				;   1 Byte
:VerWriteFlag		= $887b				;   1 Byte Datei schreiben/vergleichen
:StartDTdrv		= $887c				;   1 Byte
:VDC_mob0xpos		= $887d				;   1 Word  X-Position des Sprites 0 für VDC
:VDC_mob1xpos		= $887f				;   1 Word  X-Position des Sprites 1 für VDC
:VDC_mob2xpos		= $8881				;   1 Word  X-Position des Sprites 2 für VDC
:VDC_mob3xpos		= $8883				;   1 Word  X-Position des Sprites 3 für VDC
:VDC_mob4xpos		= $8885				;   1 Word  X-Position des Sprites 4 für VDC
:VDC_mob5xpos		= $8887				;   1 Word  X-Position des Sprites 5 für VDC
:VDC_mob6xpos		= $8889				;   1 Word  X-Position des Sprites 6 für VDC
:VDC_mob7xpos		= $888b				;   1 Word  X-Position des Sprites 7 für VDC
:VDC_Grfx1		= $888d				;   1 Byte  für Grafikberechnung BitmapUp usw.
:VDC_Grfx2		= $888e				;   1 Byte  für Grafikberechnung BitmapUp usw.
:DI_mouseXPos		= $888f				;   1 Byte  Zwischenspeicher für mouseXPos
:SoftSpriteFlag		= $8890				;   1 Byte  Flag für SoftSpriteHandler
:LastmouseXPos		= $8891				;   2 Byte  Letzte Mausposition (SoftSpriteH.)
:LastmouseYPos		= $8893				;   1 Byte  Letzte Mausposition
:c128_BufRAMConf	= $8894				;   1 Byte  Bufferbyte
:c128_BufMMU		= $8895				;   1 Byte  Bufferbyte
:c128_BufAkku		= $8896				;   1 Byte  Bufferbyte
:c128_BufRAMConf2	= $8897				;   1 Byte  Bufferbyte
:c128_BufAkku2		= $8898				;   1 Byte  Bufferbyte
:c128_BufStatus2	= $8899				;   1 Byte  Bufferbyte
:c128_BufMHZ		= $889a				;   1 Byte  Bufferbyte

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

:VDCBaseD600		= $d600				;Basisadresse VDC
:VDCDataD601		= $d601				;Dataregister VDC
:MHZ			= $d030				;Geschwindigkeitsregister (1/2Mhz)
:RAM_Conf_Reg		= $d506				;Ram-Configurations-Register
:Mode_Conf_Reg		= $d505				;Mode-Configurations-Register
:ramExpBase		= $df00				;Basisadresse REU
:MMU			= $ff00				;Memory-Pointer
:ADD1_W			= $2000
:DOUBLE_B		= $80
:DOUBLE_W		= $8000
:SETBANKFILE		= $ff68

:StartBasicReset	= $0e2e
