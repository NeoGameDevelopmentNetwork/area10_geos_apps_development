; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** SuperCPU-Register.
:SCPU_HW_EN		= $d07e
:SCPU_HW_DIS		= $d07f
:SCPU_HW_CHECK		= $d0bc
:SCPU_HW_OPT		= $d0b4
:SCPU_HW_NORMAL		= $d07a
:SCPU_HW_TURBO		= $d07b
:SCPU_HW_SPEED		= $d0b8
:SCPU_HW_VIC_OPT	= $d074
:SCPU_HW_VIC_B2		= $d074
:SCPU_HW_VIC_B1		= $d075
:SRAM_FIRST_PAGE	= $d27c
:SRAM_FIRST_BANK	= $d27d
:SRAM_LAST_PAGE		= $d27e
:SRAM_LAST_BANK		= $d27f

;--- Sprungtabelle für 16Bit-DoRAMOp:
:SRAM_USER_PAGE		= $d300				;Free RAM $D300-$D3FF.
:SRAM_D300_STASH	= SRAM_USER_PAGE +0
:SRAM_D300_FETCH	= SRAM_USER_PAGE +3
:SRAM_D300_SWAP		= SRAM_USER_PAGE +6
:SRAM_D300_VERIFY	= SRAM_USER_PAGE +9

;--- Ergänzung: 08.07.18/M.Kanet
;Adressen für Prüfung der SuperCPU-Version.
:SCPU_ROM_VER		= $e487
