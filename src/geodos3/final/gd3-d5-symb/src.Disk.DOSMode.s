; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DOS-Modus definieren:
;(Nur Werte von $x1xx-$xFxx möglich!)
:TDOS_ENABLED		= $0100				;GEOS-TurboDOS verwenden.
:TDOS_DISABLED		= $0200				;Standard-FloppyDOS verwenden.

:DEFAULT		= TDOS_ENABLED			;Vorgabe-Modus.

;--- Hinweis#1:
;TDOS_MODE wird in jedem Treiber auf
;TDOX_xyz gesetzt und innerhalb der
;Include-Dateien mit ":Flag64_128"
;verknüpft:
;TRUE_C64  = $8000 ! TDOS_MODE...
;TRUE_C128 = $F000 ! TDOS_MODE...
;TDOS_MODE kann hier nur $x1xx-$xFxx
;für die Verknüpfung nutzen.

;--- Hinweis#2:
;Für die folgenden Treiber gibt es
;eine Version für den ser.Bus. Diese
;Treiber können daher entweder das
;GEOS-TurboDOS (TDOS_ENABLED) oder das
;FloppyDOS (TDOS_DISABLED) verwenden.
:TDOS_C_41		= DEFAULT			;1541/SD2IEC-41.
:TDOS_C_71		= DEFAULT			;1571/SD2IEC-71.
:TDOS_C_81		= DEFAULT			;1581/SD2IEC-81.

:TDOS_IEC_NM		= DEFAULT			;IECBUS-Treiber, durch S2I ersetzt.
:TDOS_S2I_NM		= DEFAULT			;SD2IEC NativeMode.

:TDOS_FD_41		= DEFAULT			;CMD-FD-Laufwerke.
:TDOS_FD_71		= DEFAULT
:TDOS_FD_81		= DEFAULT
:TDOS_FD_NM		= DEFAULT

:TDOS_HD_41		= DEFAULT			;CMD-HD/serieller Bus.
:TDOS_HD_71		= DEFAULT
:TDOS_HD_81		= DEFAULT
:TDOS_HD_NM		= DEFAULT

;--- Hinweis:
;Für die folgenden Treiber gibt es
;keine Version für den ser.Bus. Diese
;Treiber sind daher immer ENABLED.
:TDOS_HD_41_PP		= TDOS_ENABLED			;Parallelport-Treiber für die
:TDOS_HD_71_PP		= TDOS_ENABLED			;CMD-HD/RL immer ENABLED.
:TDOS_HD_81_PP		= TDOS_ENABLED
:TDOS_HD_NM_PP		= TDOS_ENABLED

:TDOS_PC_DOS		= TDOS_ENABLED			;PCDOS immer ENABLED.

:TDOS_RD_41		= TDOS_ENABLED			;RAM-Laufwerke immer ENABLED.
:TDOS_RD_71		= TDOS_ENABLED
:TDOS_RD_81		= TDOS_ENABLED
:TDOS_RD_NM		= TDOS_ENABLED
:TDOS_RD_NM_SCPU	= TDOS_ENABLED
:TDOS_RD_NM_CREU	= TDOS_ENABLED
:TDOS_RD_NM_GRAM	= TDOS_ENABLED

:TDOS_RL_41		= TDOS_ENABLED			;RAMLink-Partitionen immer ENABLED.
:TDOS_RL_71		= TDOS_ENABLED
:TDOS_RL_81		= TDOS_ENABLED
:TDOS_RL_NM		= TDOS_ENABLED
