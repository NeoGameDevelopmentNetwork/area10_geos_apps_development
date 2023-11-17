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
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			ora	xFlag_SD2IEC
			sta	RealDrvMode -8,y

			lda	turboFlags  -8,y	;TurboRoutinen in FloppyRAM ?
			bmi	:51			;Ja, weiter...

			jsr	InitTurboDOS		;TuroDOS installieren.
			txa				;Laufwerksfehler ?
			bne	:exit			;Ja, Abbruch...

			ldx	curDrive
			lda	#%10000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags -8,x		;setzen.

::51			and	#%01000000		;TurboDOS bereits aktiv ?
			bne	:ok			;Ja, weiter...

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#> ExecTurboDOS
			lda	#< ExecTurboDOS
			jsr	SendCom5Byt		;"M-E" ausführen.
			bne	:55			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			ldy	#$21			;Warteschleife.
::52			dey
			bne	:52

			jsr	waitDataIn_LOW		;Warten bis TurboDOS aktiv.

			ldx	curDrive
			lda	turboFlags -8,x
			ora	#%01000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,x		;setzen.

;--- I/O aktiv: Kein Fehler.
			ldx	#NO_ERROR		;Flag "Kein Fehler"...

;--- I/O aktiv: Fehler.
::55			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			b $2c

;--- I/O inaktiv: Kein Fehler.
::ok			ldx	#NO_ERROR		;Flag "Kein Fehler"...
::error			txa

;--- I/O inaktiv: Fehler.
::exit			rts				;Ende...

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w TD_Start
endif

;******************************************************************************
::tmp1 = C_71
if :tmp1!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			lda	#$06			;Sektor-Interleave für 1571
			sta	interleave		;festlegen.

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			ora	xFlag_SD2IEC
			sta	RealDrvMode -8,y

			lda	turboFlags  -8,y	;TurboRoutinen in FloppyRAM ?
			bmi	:51			;Ja, weiter...

			jsr	InitTurboDOS		;TuroDOS installieren.
			txa				;Laufwerksfehler ?
			bne	:exit			;Ja, Abbruch...

			ldx	curDrive
			lda	#%10000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags -8,x		;setzen.

::51			and	#%01000000		;TurboDOS bereits aktiv ?
			bne	:ok			;Ja, weiter...

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#> ExecTurboDOS
			lda	#< ExecTurboDOS
			jsr	SendCom5Byt		;"M-E" ausführen.
			bne	:55			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			ldy	#$21			;Warteschleife.
::52			dey
			bne	:52

			jsr	waitDataIn_LOW		;Warten bis TurboDOS aktiv.

			ldx	curDrive
			lda	turboFlags -8,x
			ora	#%01000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,x		;setzen.

;--- I/O aktiv: Kein Fehler.
			ldx	#NO_ERROR		;Flag "Kein Fehler"...

;--- I/O aktiv: Fehler.
::55			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			b $2c

;--- I/O inaktiv: Kein Fehler.
::ok			ldx	#NO_ERROR		;Flag "Kein Fehler"...
::error			txa

;--- I/O inaktiv: Fehler.
::exit			rts				;Ende...

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w TD_Start
endif

;******************************************************************************
::tmp2 = C_81
if :tmp2!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			ora	xFlag_SD2IEC
			sta	RealDrvMode -8,y

			lda	turboFlags  -8,y	;TurboRoutinen in FloppyRAM ?
			bmi	:51			;Ja, weiter...

			jsr	InitTurboDOS		;TuroDOS installieren.
			txa				;Laufwerksfehler ?
			bne	:exit			;Ja, Abbruch...

			ldx	curDrive
			lda	#%10000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags -8,x		;setzen.

::51			and	#%01000000		;TurboDOS bereits aktiv ?
			bne	:ok			;Ja, weiter...

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#> ExecTurboDOS
			lda	#< ExecTurboDOS
			jsr	SendCom5Byt		;"M-E" ausführen.
			bne	:55			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			ldy	#$21			;Warteschleife.
::52			dey
			bne	:52

			jsr	waitDataIn_LOW		;Warten bis TurboDOS aktiv.

			ldx	curDrive
			lda	turboFlags -8,x
			ora	#%01000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,x		;setzen.

;--- I/O aktiv: Kein Fehler.
			ldx	#NO_ERROR		;Flag "Kein Fehler"...

;--- I/O aktiv: Fehler.
::55			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			b $2c

;--- I/O inaktiv: Kein Fehler.
::ok			ldx	#NO_ERROR		;Flag "Kein Fehler"...
::error			txa

;--- I/O inaktiv: Fehler.
::exit			rts				;Ende...

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w TD_Start
endif

;******************************************************************************
::tmp2a = S2I_NM
if :tmp2a!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			lda	#$01			;Sektor-Interleave für SD2IEC
			sta	interleave		;festlegen.

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			ora	xFlag_SD2IEC
			sta	RealDrvMode -8,y

			lda	turboFlags  -8,y	;TurboRoutinen in FloppyRAM ?
			bmi	:51			;Ja, weiter...

			jsr	InitTurboDOS		;TuroDOS installieren.
			txa				;Laufwerksfehler ?
			bne	:exit			;Ja, Abbruch...

			ldx	curDrive
			lda	#%10000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags -8,x		;setzen.

::51			and	#%01000000		;TurboDOS bereits aktiv ?
			bne	:ok			;Ja, weiter...

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#> ExecTurboDOS
			lda	#< ExecTurboDOS
			jsr	SendCom5Byt		;"M-E" ausführen.
			bne	:55			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			ldy	#$21			;Warteschleife.
::52			dey
			bne	:52

			jsr	waitDataIn_LOW		;Warten bis TurboDOS aktiv.

			ldx	curDrive
			lda	turboFlags -8,x
			ora	#%01000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,x		;setzen.

;--- I/O aktiv: Kein Fehler.
			ldx	#NO_ERROR		;Flag "Kein Fehler"...

;--- I/O aktiv: Fehler.
::55			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			b $2c

;--- I/O inaktiv: Kein Fehler.
::ok			ldx	#NO_ERROR		;Flag "Kein Fehler"...
::error			txa

;--- I/O inaktiv: Fehler.
::exit			rts				;Ende...

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w TD_Start
endif

;******************************************************************************
::tmp3 = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM!IEC_NM!PC_DOS
if :tmp3!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			lda	#$01			;Sektor-Interleave für FD/HD
			sta	interleave		;festlegen.

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			sta	RealDrvMode -8,y

			lda	turboFlags  -8,y	;TurboRoutinen in FloppyRAM ?
			bmi	:51			;Ja, weiter...

			jsr	InitTurboDOS		;TuroDOS installieren.
			txa				;Laufwerksfehler ?
			bne	:exit			;Ja, Abbruch...

			ldx	curDrive
			lda	#%10000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags -8,x		;setzen.

::51			and	#%01000000		;TurboDOS bereits aktiv ?
			bne	:ok			;Ja, weiter...

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#> ExecTurboDOS
			lda	#< ExecTurboDOS
			jsr	SendCom5Byt		;"M-E" ausführen.
			bne	:55			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			ldy	#$21			;Warteschleife.
::52			dey
			bne	:52

			jsr	waitDataIn_LOW		;Warten bis TurboDOS aktiv.

			ldx	curDrive
			lda	turboFlags -8,x
			ora	#%01000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,x		;setzen.

;--- I/O aktiv: Kein Fehler.
			ldx	#NO_ERROR		;Flag "Kein Fehler"...

;--- I/O aktiv: Fehler.
::55			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			b $2c

;--- I/O inaktiv: Kein Fehler.
::ok			ldx	#NO_ERROR		;Flag "Kein Fehler"...
::error			txa

;--- I/O inaktiv: Fehler.
::exit			rts				;Ende...

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w TD_Start
endif

;******************************************************************************
::tmp4 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp4!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			lda	#$01			;Sektor-Interleave für FD/HD
			sta	interleave		;festlegen.

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			sta	RealDrvMode -8,y

			lda	turboFlags  -8,y
			bmi	:51

			jsr	InitTurboDOS
			txa
			bne	:exit

			ldx	curDrive
			lda	#%10000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags -8,x		;setzen.

::51			and	#%01000000		;TurboDOS bereits aktiv ?
			bne	:ok			;Ja, weiter...

			jsr	InitForIO		;I/O-Bereich einblenden.

			ldx	#> ExecTurboDOS
			lda	#< ExecTurboDOS
			jsr	SendCom5Byt		;"M-E" ausführen.
			bne	:55			;Fehler? => Ja, Abbruch...

			jsr	UNLSN

;			ldy	#$21			;Warteschleife.
;::52			dey				;Für CMD-HD/PP nicht erforderlich.
;			bne	:52

			jsr	waitDataIn_LOW		;Warten bis TurboDOS aktiv.

			ldx	curDrive
			lda	turboFlags -8,x
			ora	#%01000000		;Flag für "TurboDOS ist aktiv"
			sta	turboFlags -8,x		;setzen.

;--- I/O aktiv: Kein Fehler.
			ldx	#NO_ERROR		;Flag "Kein Fehler"...

;--- I/O aktiv: Fehler.
::55			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			b $2c

;--- I/O inaktiv: Kein Fehler.
::ok			ldx	#NO_ERROR		;Flag "Kein Fehler"...
::error			txa

;--- I/O inaktiv: Fehler.
::exit			rts				;Ende...

;*** Befehl zum aktivieren des TurboDOS.
:ExecTurboDOS		b "M-E"
			w TD_Start
endif

;******************************************************************************
::tmp5 = RL_41!RL_71!RL_81!RL_NM
if :tmp5!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			sta	RealDrvMode -8,y

			jsr	initRAMLink		;RAMLink-Daten initialisieren.
			txa
			bne	:exit

			lda	RL_PartADDR +0		;Kompatibilität mit GEOS V2.
			sta	driveData +3

			ldy	curDrive
			lda	#%11000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags  -8,y	;und "TurboDOS ist aktiv" setzen.

			ldx	#NO_ERROR		;Z-Flag analog zu den anderen
::error			txa				;Treibern setzen.
::exit			rts

;*** RAMLink initialisieren.
:initRAMLink		lda	sysRAMLink		;RAMLink-Adresse bekannt?
			bne	:51			; => Ja, weiter...

			jsr	FindRAMLink		;RAMLink-Adresse/ser.Bus suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

::51			jsr	RL_DataCheck		;RAMLink-Daten testen.
;			txa
;			bne	:exit

::exit			rts

;*** RAMLink-Daten testen.
:RL_DataCheck		lda	RL_PartTYPE		;Wurden Part.-Informationen bereits
			bne	:51			;eingelesen ? => Ja, weiter...
			jsr	getRLPartList		;Partitionsliste einlesen.

::51			ldx	RL_PartNr		;Aktive Partition ermittelt ?
			beq	:52			; => Nein, weiter...
			ldy	curDrive

;--- Ergänzung: 18.10.18/M.Kanet
;Der Test ramBase=0 -> updRLPartInfo ist immer TRUE wenn nur eine Partition
;auf der RAMLink existiert, z.B. nach einer Neu-Initialisierung. Dann beginnt
;die Partition bei $00:$0000.
;Daher prüfen ob drivePartData=0, wenn ja dann erste Partition wählen.
			lda	drivePartData-8,y
			beq	:52

			lda	ramBase     - 8,y
;			beq	:52			; => Erste Partition installieren.
			cmp	RL_PartADDR_H  ,x	;Wurde Partition gewechselt ?
			beq	:53			; => Nein, weiter...
::52			jsr	updRLPartInfo
			b $2c
::53			ldx	#NO_ERROR

			ldy	curDrive
			lda	#$00
			cpx	#NO_ERROR
			bne	:54
			lda	RL_PartNr		;Partitions-Nr. zwischenspeichern.
::54			sta	drivePartData -8,y

::55			txa				;Z-Flag analog zu den anderen
							;Treibern setzen.
			rts

;*** Aktuelle Partitions-Nr. bestimmen.
:updRLPartInfo		lda	r0L
			pha

			ldx	#0			;Zeiger auf erste Partition.
			stx	r0L
			inx
			ldy	curDrive		;Aktuelle Laufwerks-Adresse.
::51			lda	RL_PartTYPE,x
			eor	curType
			and	#%00001111		;Partitionsformat gültig ?
			bne	:52			; => Nein, weiter...

			lda	r0L			;Erste Partition gefunden ?
			bne	:51a			; => Ja, weiter...
			stx	r0L			;Erste Partition merken.

::51a			txa				;Partition gefunden?
			cmp	drivePartData -8,y
			beq	:53			; => Ja, weiter...

			lda	ramBase -8,y		;Partitionsadresse einlesen.
			cmp	RL_PartADDR_H,x		;Partition gefunden?
			beq	:53			; => Ja, weiter...

::52			inx				;Zeiger auf nächste Partition.
			cpx	#PART_MAX +1		;Alle Partitionen durchsucht ?
			bcc	:51			;Nein, weiter...

			ldx	r0L			;Erste Partition gefunden ?
			beq	:no_part		; => Nein, Fehler...

::53			stx	RL_PartNr
			lda	RL_PartADDR_L,x		;Startadresse Partition in
			sta	RL_PartADDR +0		;Laufwerkstreiber übertragen.
			lda	RL_PartADDR_H,x
			sta	RL_PartADDR +1

;--- Hinweis:
;":ExitTurbo" ruft intern die Routine
;":StashDriverData" auf und sichert
;dann über ":Save_RegData" auch die
;ZeroPage-Register.
			jsr	xExitTurbo		;TurboDOS abschalten.

;			jsr	StashDriverData		;Laufwerksinformationen speichern.

;--- Hinweis:
;Nach ":Save_RegData" darf keine andere
;Routine mehr diese Routine aufrufen!
;Die Routine wird durch ":ExitTurbo"
;aufgerufen, die Register sind noch
;zwischengespeichert.
;			jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.

			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	RL_PartNr
			sta	r3H
			jsr	xSwapPartition		;Partition wechseln.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.

			b $2c
::no_part		ldx	#NO_PARTITION		;Keine Partition gefunden.

			pla
			sta	r0L
			rts
endif

;******************************************************************************
::tmp6 = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU
if :tmp6!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			sta	RealDrvMode -8,y

			lda	#%11000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags  -8,y	;und "TurboDOS ist aktiv" setzen.

			ldx	#NO_ERROR		;Z-Flag analog zu den anderen
::error			txa				;Treibern setzen.
			rts
endif

;******************************************************************************
::tmp7 = RD_NM_GRAM
if :tmp7!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
;*** TurboDOS aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xEnterTurbo		;lda	curDrive
			;jsr	SetDevice

			ldy	curDrive
			ldx	#DEV_NOT_FOUND
			lda	driveType -8,y		;DESKTOP 2.x: GDOS-Daten nur bei
			beq	:error			;vorhandenem Laufwerk setzen.

			lda	diskDrvType
			sta	RealDrvType -8,y
			lda	#DISKDRV_OPTS
			ora	GeoRAMBSize
			sta	RealDrvMode -8,y

			lda	#%11000000		;Flag für "TurboDOS in FloppyRAM"
			sta	turboFlags  -8,y	;und "TurboDOS ist aktiv" setzen.

			ldx	#NO_ERROR		;Z-Flag analog zu den anderen
::error			txa				;Treibern setzen.
			rts
endif
