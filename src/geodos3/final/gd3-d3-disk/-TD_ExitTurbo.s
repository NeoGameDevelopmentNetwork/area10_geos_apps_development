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
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa				;xReg zwischenspeichern.
			pha

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			pla				;xReg wieder zurücksetzen.
			tax

::51			rts
endif

;******************************************************************************
::tmp1 = C_71!PC_DOS
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa				;xReg zwischenspeichern.
			pha

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			pla				;xReg wieder zurücksetzen.
			tax

::51			rts
endif

;******************************************************************************
::tmp2 = C_81
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> TD_ClearCache
			lda	#< TD_ClearCache
			jsr	xTurboRoutine		;Cache auf Disk schreiben.
			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;BAM sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp3 = FD_41!FD_71!HD_41!HD_71
if :tmp3!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa				;xReg zwischenspeichern.
			pha

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> TD_ClearCache
			lda	#< TD_ClearCache
			jsr	xTurboRoutine		;Cache auf Disk schreiben.
			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			pla				;xReg wieder zurücksetzen.
			tax

::51			rts
endif

;******************************************************************************
::tmp4 = FD_81!HD_81
if :tmp4!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> TD_ClearCache
			lda	#< TD_ClearCache
			jsr	xTurboRoutine		;Cache auf Disk schreiben.
			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;BAM sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp5 = FD_NM!HD_NM!IEC_NM!S2I_NM
if :tmp5!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    ACHTUNG! Hier muß unbedingt auch der aktuelle Treiber zurück in die REU
;    kopiert werden, da einige Variablen/Speicherbereiche geändert wurden.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> TD_ClearCache
			lda	#< TD_ClearCache
			jsr	xTurboRoutine		;Cache auf Disk schreiben.
			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp6 = HD_41_PP!HD_71_PP
if :tmp6!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa				;xReg zwischenspeichern.
			pha

			jsr	InitForIO		;I/O aktivieren.

			ldx	#$00
			jsr	TurboRoutine2		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			pla				;xReg wieder zurücksetzen.
			tax

::51			rts
endif

;******************************************************************************
::tmp7 = HD_81_PP
if :tmp7!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

			jsr	InitForIO		;I/O aktivieren.

			ldx	#$00
			jsr	TurboRoutine2		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;BAM sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp8 = HD_NM_PP
if :tmp8!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    ACHTUNG! Hier muß unbedingt auch der aktuelle Treiber zurück in die REU
;    kopiert werden, da einige Variablen/Speicherbereiche geändert wurden.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

			jsr	InitForIO		;I/O aktivieren.

			ldx	#$00
			jsr	TurboRoutine2		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp9 = RD_81
if :tmp9!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp10 = RD_41!RD_71
if :tmp10!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y
			rts
endif

;******************************************************************************
::tmp11 = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp11!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    ACHTUNG! Hier muß unbedingt auch der aktuelle Treiber zurück in die REU
;    kopiert werden, da einige Variablen/Speicherbereiche geändert wurden.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp12 = RL_41!RL_71!RL_81
if :tmp12!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

;--- Ergänzung: 28.03.21/M.Kanet
;Auch der RL-Treiber sendet Befehle
;über den ser.Bus an die RAMLink, daher
;muss auch hier ein evtl. geöffneter
;Befehlskanal geschlossen werden.
			jsr	InitForIO		;I/O aktivieren.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp13 = RL_NM
if :tmp13!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    ACHTUNG! Hier muß unbedingt auch der aktuelle Treiber zurück in die REU
;    kopiert werden, da einige Variablen/Speicherbereiche geändert wurden.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			txa
			pha

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

;--- Ergänzung: 28.03.21/M.Kanet
;Auch der RL-Treiber sendet Befehle
;über den ser.Bus an die RAMLink, daher
;muss auch hier ein evtl. geöffneter
;Befehlskanal geschlossen werden.
			jsr	InitForIO		;I/O aktivieren.

			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif
