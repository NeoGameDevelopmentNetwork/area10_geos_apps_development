; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk		bit	curType			;Shadow1541 ?
			bvc	:1			; => Nein, weiter...

			jsr	InitShadowRAM		;ShadowRAM löschen.
::1
endif

;******************************************************************************
::tmp1 = C_71!C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!IEC_NM!S2I_NM
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk
endif

;******************************************************************************
::tmp2 = C_41!C_71!C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!IEC_NM!S2I_NM
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
			jsr	xEnterTurbo
;			txa
			bne	:err
			stx	RepeatFunction
			inx
			stx	r1L
			stx	r1H

			jsr	InitForIO		;I/O aktivieren.
endif

;******************************************************************************
::tmp2a = C_41
if :tmp2a!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;--- Ergänzung: 29.03.22/M.Kanet:
;geoPublish führt bei der Installation
;Code aus welcher nach dem "sta d0L"-
;Befehl im 1541-Treiber sucht.
;Die anschließenden sechs Bytes werden
;ausgelesen und in die Installations-
;routine eingebunden.
::loop			lda	#> TD_NewDisk		;NewDisk ausführen.
			sta	d0H
			lda	#< TD_NewDisk
			sta	d0L
			jsr	xTurboRoutine_r1
			jsr	xGetDiskError		;Fehler/Wiederholungszähler holen.
;---
endif

;******************************************************************************
::tmp2b = C_71!C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!IEC_NM!S2I_NM
if :tmp2b!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
::loop			ldx	#> TD_NewDisk		;NewDisk ausführen.
			lda	#< TD_NewDisk
			jsr	xTurboRoutSet_r1
			jsr	xGetDiskError		;Fehler/Wiederholungszähler holen.
endif

;******************************************************************************
::tmp2c = C_41!C_71!C_81!FD_41!FD_71!FD_81!FD_NM!PC_DOS!IEC_NM!S2I_NM
if :tmp2c!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;			txa				;Fehler?
			beq	:exit			;= > Nein, weiter...

			inc	RepeatFunction		;Wiederholungszähler setzen.
			cpy	RepeatFunction		;Alle Versuche fehlgeschlagen?
			beq	:exit			; => Ja, Abbruch...
			bcs	:loop			;NewDisk nochmal senden.

::exit			jsr	DoneWithIO		;I/O abschalten.

::err			rts
endif

;******************************************************************************
::tmp4a = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp4b = RL_41!RL_71!RL_81!RL_NM!RD_41!RD_71!RD_81!RD_NM
::tmp4c = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp4  = :tmp4a!:tmp4b!:tmp4c
if :tmp4!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren und neue Diskette öffnen.
:xNewDisk = xEnterTurbo
endif
