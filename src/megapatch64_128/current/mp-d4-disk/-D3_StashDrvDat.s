; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0b = RL_41!RL_71!RL_NM!RD_NM
::tmp0c = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0  = :tmp0a!:tmp0b!:tmp0c
if :tmp0 = TRUE
;******************************************************************************
:StashDriverData	jsr	InitForDskDvJob		;Zeiger auf Laufwerkstreiber in RAM.
			jsr	Save_RegData		;ZeroPage-Register speichern.

			LoadW	r0 , S_DRIVER_DATA
			AddVW	    (S_DRIVER_DATA-DISK_BASE    ),r1
			LoadW	r2 ,(E_DRIVER_DATA-S_DRIVER_DATA)
			jsr	StashRAM		;Variablen sichern.

			jsr	Load_RegData		;ZeroPage-Register zurücksetzen.
			jmp	DoneWithDskDvJob
endif

;******************************************************************************
::tmp1 = RL_81
if :tmp1 = TRUE
;******************************************************************************
:StashDriverData	jsr	InitForDskDvJob		;Zeiger auf Laufwerkstreiber in RAM.
			jsr	Save_RegData		;ZeroPage-Register speichern.

			LoadW	r0 , S_DRIVER_DATA
			AddVW	    (S_DRIVER_DATA-DISK_BASE    ),r1
			LoadW	r2 ,(E_DRIVER_DATA-S_DRIVER_DATA)
			jsr	StashRAM		;Variablen sichern.

			jsr	Load_RegData		;ZeroPage-Register zurücksetzen.
			jsr	DoneWithDskDvJob

			jsr	Save_RegData		;ZeroPage-Register speichern.
			jsr	Save_dir3Head		;3ten BAM-Sektor sichern.
			jmp	Load_RegData		;ZeroPage-Register zurücksetzen.
endif

;******************************************************************************
::tmp2 = C_81!FD_81!HD_81!HD_81_PP!RD_81
if :tmp2 = TRUE
;******************************************************************************
:StashDriverData	jsr	Save_RegData		;ZeroPage-Register speichern.
			jsr	Save_dir3Head		;3ten BAM-Sektor sichern.
			jmp	Load_RegData		;ZeroPage-Register zurücksetzen.
endif
