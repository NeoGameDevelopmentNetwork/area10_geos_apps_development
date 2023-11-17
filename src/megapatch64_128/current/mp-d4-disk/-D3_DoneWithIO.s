; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp00a = C_41!C_71!C_81!PC_DOS
::tmp00b = FD_41!FD_71!FD_81!RL_41!RL_71!RL_81
::tmp00c = HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP
::tmp00d = RD_41!RD_71!RD_81
::tmp00  = :tmp00a!:tmp00b!:tmp00c!:tmp00d
if :tmp00 = TRUE
;******************************************************************************
;*** I/O abschalten.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU
:xDoneWithIO		sei
endif

;******************************************************************************
::tmp01a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp01b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp01  = :tmp01a!:tmp01b
if :tmp01 = TRUE
;******************************************************************************
;*** I/O abschalten.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU
:xDoneWithIO		sei
			lda	#$00			;I/O-Modus löschen.
			sta	IO_Activ
endif

;******************************************************************************
::tmp02 = PC_DOS
if Flag64_128!:tmp02!TDOS_MODE = TRUE_C64!TRUE!TDOS_ENABLED
;******************************************************************************
;--- Ergänzung: 16.11.19/M.Kanet
;Beim PCDOS-Treiber wird der Turbo
;durch ":InitForIO" abgeschaltet.
::resetTC64		LoadB	$d0fe,$2a		;Konfigurationsregister einschalten.

			lda	TC64Speed_Buf		;Original TC64-Speed einlesen und
			sta	$d0f3			;TC64 wieder zurücksetzen.

			LoadB	$d0fe,$ff		;Konfigurationsregister ausschalten.
endif

;******************************************************************************
::tmp09a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp09b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp09  = :tmp09a!:tmp09b
if Flag64_128!:tmp09!TDOS_MODE = TRUE_C64!TRUE!TDOS_DISABLED
;******************************************************************************
;--- Ergänzung: 03.10.20/M.Kanet
;Bei den Kernal-Treibern wird der Turbo
;durch ":InitForIO" abgeschaltet.
::resetTC64		LoadB	$d0fe,$2a		;Konfigurationsregister einschalten.

			lda	TC64Speed_Buf		;Original TC64-Speed einlesen und
			sta	$d0f3			;TC64 wieder zurücksetzen.

			LoadB	$d0fe,$ff		;Konfigurationsregister ausschalten.
endif

;******************************************************************************
::tmp03a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp03b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp03c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp03d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp03  = :tmp03a!:tmp03b!:tmp03c!:tmp03d
if Flag64_128!:tmp03 = TRUE_C128!TRUE
;******************************************************************************
;--- Ergänzung: 21.07.18/M.Kanet
;DoneWithIO/RAMLink/RAMDisk/NativeMode:
;In der Version von 2003 wird nicht auf den C128/1MHz-Modus umgeschaltet.
;Die Register müssen aber trotzdem gesichert werden für den Fall das andere
;Routinen zwischen :InitForIO und :DonewithIO das Register verändert haben.
			lda	CLKRATE_Buf
			sta	CLKRATE
endif

;******************************************************************************
::tmp04a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp04b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp04c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp04d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp04  = :tmp04a!:tmp04b!:tmp04c!:tmp04d
if :tmp04 = TRUE
;******************************************************************************
			lda	mobenble_Buf		;Sprites wieder aktivieren.
			sta	mobenble

			lda	#$7f			;NMIs sperren.
			sta	$dd0d
			lda	$dd0d

			lda	grirqen_Buf		;IRQ-Maskenregister zurücksetzen.
			sta	grirqen
endif

;******************************************************************************
::tmp05a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp05b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp05c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp05d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp05  = :tmp05a!:tmp05b!:tmp05c!:tmp05d
if Flag64_128!:tmp05 = TRUE_C64!TRUE
;******************************************************************************
			lda	CPU_RegBuf		;CPU-Register zurücksetzen.
			sta	CPU_DATA
endif

;******************************************************************************
::tmp06a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp06b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp06c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp06d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp06  = :tmp06a!:tmp06b!:tmp06c!:tmp06d
if :tmp06 = TRUE
;******************************************************************************
			lda	IRQ_RegBuf		;IRQ-Status zurücksetzen.
			pha
			plp
			rts
endif

;******************************************************************************
::tmp07a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp07b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp07c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp07d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp07  = :tmp07a!:tmp07b!:tmp07c!:tmp07d
if Flag64_128!:tmp07 = TRUE_C64!TRUE
;******************************************************************************
;*** Neue IRQ/NMI-Routine.
:NewIRQ			pla
			tay
			pla
			tax
			pla
:NewNMI			rti
endif

;******************************************************************************
::tmp08a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp08b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp08c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp08d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp08  = :tmp08a!:tmp08b!:tmp08c!:tmp08d
if Flag64_128!:tmp08 = TRUE_C128!TRUE
;******************************************************************************
;*** Neue IRQ/NMI-Routine.
:NewIRQ			pla
			sta	MMU
			pla
			tay
			pla
			tax
			pla
:NewNMI			rti
endif
