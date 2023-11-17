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

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

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

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

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
:xExitTurbo		txa
			pha

;--- Ergänzung: 29.06.22/M.Kanet
;geoWrite ändert beim einfügen eines
;PhotoScrap die BAM ohne das TurboDOS
;aktiv ist. Bei 1581/Native daher
;immer dir3Head im Kernal sichern!
			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> TD_ClearCache
			lda	#< TD_ClearCache
			jsr	xTurboRoutine		;Cache auf Disk schreiben.
			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

::51			jsr	StashDriverData		;BAM sichern.

			pla
			tax

			rts
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

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

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

			txa
			pha

;--- Ergänzung: 29.06.22/M.Kanet
;geoWrite ändert beim einfügen eines
;PhotoScrap die BAM ohne das TurboDOS
;aktiv ist. Bei 1581/Native daher
;immer dir3Head im Kernal sichern!
			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			jsr	InitForIO		;I/O aktivieren.

			ldx	#> TD_ClearCache
			lda	#< TD_ClearCache
			jsr	xTurboRoutine		;Cache auf Disk schreiben.
			ldx	#> TD_Stop
			lda	#< TD_Stop
			jsr	xTurboRoutine		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

::51			jsr	StashDriverData		;BAM sichern.

			pla
			tax

			rts
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

			txa
			pha

;--- Ergänzung: 29.06.22/M.Kanet
;geoWrite ändert beim einfügen eines
;PhotoScrap die BAM ohne das TurboDOS
;aktiv ist. Bei 1581/Native daher
;immer dir3Head im Kernal sichern!
			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

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

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

::51			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

			rts
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

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

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

			txa
			pha

;--- Ergänzung: 29.06.22/M.Kanet
;geoWrite ändert beim einfügen eines
;PhotoScrap die BAM ohne das TurboDOS
;aktiv ist. Bei 1581/Native daher
;immer dir3Head im Kernal sichern!
			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			jsr	InitForIO		;I/O aktivieren.

			ldx	#$00
			jsr	TurboRoutine2		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

::51			jsr	StashDriverData		;BAM sichern.

			pla
			tax

			rts
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

			txa
			pha

;--- Ergänzung: 29.06.22/M.Kanet
;geoWrite ändert beim einfügen eines
;PhotoScrap die BAM ohne das TurboDOS
;aktiv ist. Bei 1581/Native daher
;immer dir3Head im Kernal sichern!
			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

			jsr	InitForIO		;I/O aktivieren.

			ldx	#$00
			jsr	TurboRoutine2		;TurboDOS abschalten.
			jsr	waitDataIn_HIGH		;Warten bis Laufwerk bereit.

;--- Ergänzung: 22.05.22/M.Kanet
;Auf Grund des RAMLink+GeoWrite-Bugs
;die Kernal-Routine ":LISTEN"=$FFB1
;vermeiden, siehe TD/RAMLink-Treiber.
			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.

			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

::51			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

			rts
endif

;******************************************************************************
::tmp9 = RD_81
if :tmp9!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		txa
			pha

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

			rts
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
:xExitTurbo		txa
			pha

;--- Ergänzung: 29.06.22/M.Kanet
;geoWrite ändert beim einfügen eines
;PhotoScrap die BAM ohne das TurboDOS
;aktiv ist. Bei 1581/Native daher
;immer dir3Head im Kernal sichern!
			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

::51			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

			rts
endif

;******************************************************************************
::tmp12 = RL_41!RL_71!RL_81
if :tmp12!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		txa
			pha

;--- Ergänzung: 29.06.22/M.Kanet
;geoWrite ändert beim einfügen eines
;PhotoScrap die BAM ohne das TurboDOS
;aktiv ist. Bei 1581/Native daher
;immer dir3Head im Kernal sichern!
			ldy	curDrive
			lda	turboFlags -8,y
;			and	#%01000000		;TurboDOS aktiv?
;			beq	:51			;Nein, Ende...

;--- Ergänzung: 28.03.21/M.Kanet
;Auch der RL-Treiber sendet Befehle
;über den ser.Bus an die RAMLink, daher
;muss auch hier ein evtl. geöffneter
;Befehlskanal geschlossen werden.
;
;--- Ergänzung: 22.05.22/M.Kanet
;GeoWrite verändert ZeroPage-Adressen
;im Bereich von $0080-$00FF. Einige der
;Kernal-Routinen verursachen Probleme,
;wenn hier ungültige Werte vorliegen:
;Innerhalb von GeoWrite wird ab $0094
;ein Zeiger auf die aktuelle Cursor-
;Position innerhalb der Seite abgelegt.
;In Verbindung nur mit einer RAMLink
;(ohne SuperCPU) führt dann ein Aufruf
;von ":LISTEN"=$FFB1 zum Absturz.
;Ursache ist die Adresse $0094 die hier
;ausgelesen wird und in Abhängigkeit
;des Wertes <$80 oder >=$80 das ROM der
;RAMLink umgeschaltet wird. Bei einem
;Wert >=$80 führt das zum Absturz bei
;$ED2D: JMP $(DE34)
;
;Routine komplett deaktiviert.
;			jsr	InitForIO		;I/O aktivieren.
;			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.
;			jsr	DoneWithIO		;I/O abschalten.

;			ldy	curDrive
;			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

::51			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

			rts
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
:xExitTurbo		txa
			pha

;--- Ergänzung: 29.06.22/M.Kanet
;geoWrite ändert beim einfügen eines
;PhotoScrap die BAM ohne das TurboDOS
;aktiv ist. Bei 1581/Native daher
;immer dir3Head im Kernal sichern!
			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;TurboDOS aktiv?
			beq	:51			;Nein, Ende...

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

;--- Ergänzung: 28.03.21/M.Kanet
;Auch der RL-Treiber sendet Befehle
;über den ser.Bus an die RAMLink, daher
;muss auch hier ein evtl. geöffneter
;Befehlskanal geschlossen werden.
;
;--- Ergänzung: 22.05.22/M.Kanet
;GeoWrite verändert ZeroPage-Adressen
;im Bereich von $0080-$00FF. Einige der
;Kernal-Routinen verursachen Probleme,
;wenn hier ungültige Werte vorliegen:
;Innerhalb von GeoWrite wird ab $0094
;ein Zeiger auf die aktuelle Cursor-
;Position innerhalb der Seite abgelegt.
;In Verbindung nur mit einer RAMLink
;(ohne SuperCPU) führt dann ein Aufruf
;von ":LISTEN"=$FFB1 zum Absturz.
;Ursache ist die Adresse $0094 die hier
;ausgelesen wird und in Abhängigkeit
;des Wertes <$80 oder >=$80 das ROM der
;RAMLink umgeschaltet wird. Bei einem
;Wert >=$80 führt das zum Absturz bei
;$ED2D: JMP $(DE34)
;
;Routine komplett deaktiviert.
;			jsr	InitForIO		;I/O aktivieren.
;			jsr	UNLSN			;UNLSN-Signal auf IEC-Bus senden.
;;			jsr	closeLISTEN		;IEC-Bus "CLOSE" an Laufwerk senden.
;			jsr	DoneWithIO		;I/O abschalten.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;Flag "TurboDOS aktiv" löschen.
			sta	turboFlags -8,y

::51			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

			rts
endif
