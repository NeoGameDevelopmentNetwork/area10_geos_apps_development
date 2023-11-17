; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExtEdit"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_RLNK"
			t "SymbTab_64ROM"
			t "SymbTab_DCMD"
			t "SymbTab_DBOX"

;--- SuperCPU-Register.
;Werden für das freigeben von Speicher
;eines SuperRAM-Laufwerks benötigt.
;Da der freie Symbolspeicher aber nicht
;mehr ausreicht, nur die benötigten
;Register direkt einbinden.
;			t "SymbTab_SCPU"
:SCPU_HW_EN		= $d07e
:SCPU_HW_DIS		= $d07f
:SRAM_FIRST_BANK	= $d27d
endif

;*** GEOS-Header.
			n "GD.CONF.DRIVES"
			c "GDC.DRIVES  V1.0"
			t "G3_Sys.Author"
			f SYSTEM
			z $80				;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Laufwerke konfigurieren"
endif
if Sprache = Englisch
			h "Configure drive"
endif

;*** Zusätzliche Symbole.
if .p
;--- Laufwerke am ser.Bus erkennen.
;GetAllSerDrives	= xGetAllSerDrives

;--- Sprungtabelle für Installationsroutine.
:DDrv_TestMode		= BASE_DDRV_INIT +0
:DDrv_Install		= BASE_DDRV_INIT +3
:DDrv_DeInstall		= BASE_DDRV_INIT +6

;--- Ergänzung: 25.12.18/M.Kanet
;Da im Bereich GD.CONFIG nicht mehr genügend freier Speicher
;verfügbar ist, wird der Bereich für den Laufwerkstreiber genutzt um
;die DiskImage-Verzeichnisliste anzulegen.
:FileNTab		= APP_RAM
:MaxFileN		= 127
:SizeNTab		= MaxFileN*17
:FileNTabBuf		= FileNTab + SizeNTab
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	InitMain
:SaveData		jmp	SaveConfig
:CheckData		jmp	CheckConfig
;******************************************************************************

;******************************************************************************
;*** GD.DRIVES - Systemroutinen.
;******************************************************************************
			t "-GC_Drives.Core"
;******************************************************************************

;******************************************************************************
;*** Daten für Taskmanager.
;******************************************************************************
			t "-G3_TaskManData"
;******************************************************************************

;******************************************************************************
;*** GD.DRIVES - Shared code.
;******************************************************************************
			t "-D3_PurgeAllTD"		;TurboDOS deaktivieren.
			t "-DD_SlctDrvAdr"		;GEOS-Laufwerksadresse wählen.
			t "-DD_SetDDrvAdr"		;Laufwerk auf neue Adresse setzen.
			t "-DD_TurnOnDrv"		;Dialog: Laufwerk einschalten.
			t "-DD_SwapDAdrTab"		;Geräteadressen von #8-11 tauschen.
			t "-DD_FindDrvType"		;Laufwerkstyp am ser.Bus suchen.
			t "-DD_SwapDrvAdr"		;Geräteadresse umschalten.
			t "-DD_GetFreeAdr"		;Freie Geräteadresse #20-28 suchen.
			t "-DD_FindSBusDev"		;Gerät am ser.Bus testen.
			t "-DD_DDrvUnload"		;Gerätetreiber deaktivieren.
			t "-DD_DDrvClrDat"		;Laufwerksdaten löschen.
			t "-DD_SD2IEC_DIMG"		;SD2IEC: DiskImage wechseln.
;******************************************************************************

;*** Sprungtabelle installieren.
;    Wichtige Routinen, die auch von den Installationsroutinen der
;    Laufwerkstreiber aufgerufen werden können, sind in einer Sprungtabelle
;    im Bereich ":a0" bis ":a9" gespeichert. Der Einsprung erfolgt über
;    einen "JMP (a0)"-Befehl... Rouinen siehe Tabelle bei ":tab".
:InstallJumpTab		ldx	#0
::1			lda	:tab,x			;Zeiger auf Register einlesen.
			sta	r0L			;(":a0" bis ":a9").
			inx
			lda	:tab,x
			sta	r0H
			inx
			ldy	#$00
			lda	:tab,x			;Vektor auf Installationsroutine
			sta	(r0L),y			;einlesen und in Sprungtabelle
			inx				;kopieren.
			iny
			lda	:tab,x
			sta	(r0L),y
			inx
			cpx	#4*10
			bne	:1
			rts

;*** Sprungtabelle für Installationsroutinen der Laufwerkstreiber.
::tab			w a0,TestDriveType
			w a1,TurnOnNewDrive
			w a2,GetFreeBank
			w a3,GetFreeBankTab
			w a4,AllocBank_Disk
			w a5,AllocBankT_Disk
			w a6,FreeBank
			w a7,FreeBankTab
			w a8,SaveDskDrvData
			w a9,FindDriveType

;*** Treiberdatei auf aktuellem Laufwerk suchen.
:LookForDkDvFile	LoadW	r6 ,DDRV_FILE
			LoadB	r7L,SYSTEM
			LoadB	r7H,1
			LoadW	r10,DDRV_FVER
			jsr	FindFTypes		;Treiberdatei suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...
			ldx	r7H			;Datei gefunden ?
			beq	:2			; => Ja, Ende...

::1			ldx	#FILE_NOT_FOUND		;Fehler: "FILE NOT FOUND!".
::2			rts

;*** Kopie der Laufwerkstreiber-Datei suchen.
;    Übergabe:		xReg = Installationslaufwerk.
:FindCopyDkDvFile	stx	:tmdrive		;Installationslaufwerk speichern.

			ldx	#NO_ERROR
			ldy	MP3_64K_DISK		;Treiber im RAM gespeichert ?
			bne	:3			; => Ja, Ende...

			jsr	FindDiskDrvFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	:2			; => Nein, Abbruch...

			ldy	:tmdrive		;Soll Installationslaufwerk mit
			cpy	DDRV_FDRV		;Treiberdatei gewechselt werden ?
			bne	:3			; => Nein, Ende.

;--- Weitere Kopie der Treiberdatei suchen, da Laufwerk mit aktueller
;    Kopie gewechselt werden soll.
::1			ldy	DDRV_FDRV		;Laufwerk mit aktueller Kopie der
			lda	driveType -8,y		;Treiberdatei deaktivieren.
			pha
			tya				;Laufwerksadresse speichern da
			pha				;":DDRV_FDRV" geändert wird.
			lda	#$00
			sta	driveType -8,y
			jsr	FindDkDvAllDrv		;Treiberdatei suchen.
			pla
			tay
			pla				;Laufwerksregister wieder
			sta	driveType -8,y		;zurücksetzen.
			txa				;Weitere Kopie gefunden ?
			beq	:3
			jmp	Err_NoDkCopy		; => Nein, Fehler...
::2			jmp	Err_NoDkFile
::3			rts

::tmdrive		b $00

;*** Informationen zu den Laufwerkstreibern laden.
:GetDrvInfo		lda	MP3_64K_DISK		;"Treiber von Diskette laden ?"
			beq	GetDrvInfoDisk		; => Ja, weiter...

;*** Laufwerkstreiber aus RAM installieren.
:GetDrvInfoRAM		jsr	SetDiskDatReg		;Treiber bereits im RAM. Treiber-
			jsr	FetchRAM		;Informationen einlesen.

			ldy	#5
::1			lda	:sysCode,y
			cmp	DRVINF_VERSION,y
			bne	:reset
			dey
			bpl	:1
			bmi	:ok

::reset			jsr	TurnOffDskDvRAM
			jmp	GetDrvInfoDisk

::ok			ldx	#NO_ERROR
			rts

::sysCode		b "G3DC10"

;*** Laufwerkstreiber von Diskette installieren.
:GetDrvInfoDisk		jsr	FindDiskDrvFile		;Laufwerkstreiber-Datei suchen.
			txa				;Datei gefunden ?
			beq	:found			; => Ja, weiter...
::not_found		rts

::found			LoadW	r0 ,DDRV_FILE
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			jsr	PointRecord		;Zeiger auf ersten Datensatz.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			LoadW	r2,6 +DDRV_MAX +DDRV_MAX*17 +DDRV_MAX*2
			LoadW	r7,DRVINF_VERSION
			jsr	ReadRecord		;Infos über verfügbare Treiber
			txa				;einlesen. Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			jsr	CloseRecordFile

::err			rts

;*** Nr. des Laufwerkstreibers berechnen.
;    Übergabe:		AKKU	= Laufwerkstyp ($01,$41,$83,$23 usw...)
;    Rückgabe:		AKKU	= Nr. des Treibers in VLIR-Datei #0-#62.
;				  $FF = unbekanntes Laufwerk.
;			xReg	= Nr. Eintrag in Typentabelle.
:GetDrvModVec		tax				;Typ = $00 ?
			beq	:exit			; => Ja, Ende...

			ldx	#1			;Zeiger auf Typen-Tabelle.
::loop			ldy	DRVINF_TYPES,x		;Typ aus Tabelle einlesen.
			beq	:unknown		; => Ende erreicht ? Ja, Ende...
			cmp	DRVINF_TYPES,x		;Mit aktuellem Modus vergleichen.
			beq	:found			; => Gefunden ? Ja, weiter...
			inx				;Zeiger auf nächsten Typ.
			cpx	#DDRV_MAX		;Max. Anzahl Typen durchsucht ?
			bne	:loop			; => Nein, weiter...

::unknown		lda	#$ff			;Modus: "Kein Laufwerk".
::exit			rts				;Ende.

::found			txa				;Zeiger auf VLIR-Tabelle einlesen.
			asl
			tax
			lda	DRVINF_RECORDS +0,x
			ldy	DRVINF_RECORDS +1,x
			pha
			txa
			lsr
			tax
			pla
			rts

;*** Zeiger auf Name Laufwerkstreiber.
;Übergabe: XReg = Nummer.
;Rückgabe: r0   = Zeiger auf Name.
:SetDrvNmVec		stx	r0L			;Zeiger auf Laufwerkstyp berechnen.
			LoadB	r1L,17

			ldx	#r0L
			ldy	#r1L
			jsr	BBMult

			AddVW	DRVINF_NAMES,r0
			rts

;*** Installationsroutine und Laufwerkstreiber einlesen.
;    Übergabe:		AKKU	= Laufwerkstyp.
;    Rückgabe:		xReg	= Fehlermeldung.
:LoadDkDvData		tax				;Laufwerkstyp = $00 ?
			beq	:2

			jsr	GetDrvModVec		;Vektor auf Datensatz mit Treiber
			ldx	#DEV_NOT_FOUND
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:2			; => Ja, Ende...
			sta	DDRV_REC_INIT		;ermitteln und speichern.
			sty	DDRV_REC_DISK
			tax				;Kein Treiber gefunden ?
			beq	:2			; => Ja, Ende...

			lda	MP3_64K_DISK		;Treiber in RAM ?
			bne	:1			; => Nein, weiter...

			jsr	FindDiskDrvFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	:2			; => Nein, Abbruch...
			jmp	LoadDkDvDisk		;Treiber von Diskette laden.
::1			jmp	LoadDkDvRAM		;Treiber aus RAM einlesen.
::2			rts

;*** Treiber aus RAM laden.
:LoadDkDvRAM		LoadW	r0,BASE_DDRV_INIT
			lda	DDRV_REC_INIT
			jsr	SetVecDskInREU
			jsr	FetchDskDrv

			LoadW	r0,BASE_DDRV_DATA
			lda	DDRV_REC_DISK
			jsr	SetVecDskInREU
			jmp	FetchDskDrv

;*** Treiber von Diskette laden.
:LoadDkDvDisk		LoadW	r0 ,DDRV_FILE
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa
			bne	:1

			lda	DDRV_REC_INIT
			jsr	PointRecord		;Zeiger auf Installationsroutine.
			txa				;Datensatz verfügbar ?
			bne	:1			; => Nein, abbruch...
			ldx	#DEV_NOT_FOUND
			tya				;Datensatz leer ?
			beq	:1			; => Ja, Abbruch...

			LoadW	r2,SIZE_DDRV_INIT
			LoadW	r7,BASE_DDRV_INIT
			jsr	ReadRecord		;Installationsroutine einlesen.
			txa				;Diskettenfehler ?
			bne	:1			; => Nein, weiter...

			lda	DDRV_REC_DISK
			jsr	PointRecord		;Zeiger auf Laufwerkstreiber.
			txa				;Datensatz verfügbar ?
			bne	:1			; => Nein, abbruch...
			ldx	#DEV_NOT_FOUND
			tya				;Datensatz leer ?
			beq	:1			; => Ja, Abbruch...

			LoadW	r2,SIZE_DDRV_DATA
			LoadW	r7,BASE_DDRV_DATA
			jsr	ReadRecord		;Laufwerkstreiber einlesen.

::1			txa
			pha
			jsr	CloseRecordFile
			jsr	PurgeTurbo
			pla
			tax
			rts

;*** Speicher für RAM-Laufwerkstreiber reservieren.
:AllocRAMDskDrv		ldy	#$02
			jsr	GetFreeBankLTab		;2x64Kb Speicher suchen.
			cpx	#NO_ERROR		;Speicher frei ?
			bne	:err			; => Nein, Abbruch...

;			lda	r0L
			sta	MP3_64K_DISK
			ldx	#%11000000
			ldy	#$02
			jsr	AllocateBankTab		;Speicher reservieren.

::err			rts

;*** Speicher für RAM-Laufwerkstreiber reservieren.
:FreeRAMDskDrv		lda	MP3_64K_DISK		;2x64K Speicher freigeben.
			ldy	#$02
			jsr	FreeBankTab

;--- "Treiber in RAM" deaktivieren.
::off			lda	#$00
			sta	MP3_64K_DISK
			rts

;*** Laufwerkstreiber in REU kopieren.
:LoadDkDv2RAM		jsr	FindDiskDrvFile		;Datei mit Laufwerkstreiber suchen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			jsr	GetDrvInfoDisk		;Treiber-Informationen einlesen.
			txa				;Fehler ?
			bne	:err			; => Ja, Abbruch...

			LoadW	r0,DDRV_FILE
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa				;Fehler ?
			beq	:1			; => Nein, weiter...

::err			jmp	Err_NoDkFile		;Treiber-Datei nicht gefunden.

::1			jsr	i_FillRam
			w	256 *2
			w	DRVINF_START
			b	$00

			LoadW	r13 ,SIZE_EDITOR_DATA

			lda	MP3_64K_DISK		;Speicherbank festlegen.
			sta	r15L

			lda	#$01			;Zeiger auf ersten Laufwerkstreiber.
			sta	r15H

::2			lda	r15H
			jsr	PointRecord		;Zeiger auf nächsten Datensatz.
			txa				;Datensatz verfügbar ?
			bne	:4			; => Nein, weiter...
			tya				;Datensatz leer ?
			beq	:4			; => Ja, weiter...

			LoadW	r2,SIZE_DDRV_INIT + SIZE_DDRV_DATA
			LoadW	r7,BASE_DDRV_INIT
			jsr	ReadRecord		;Datensatz einlesen.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, weiter...

			lda	r7L			;Größe des eingelesenen
			sec				;Datensatzes berechnen.
			sbc	#<BASE_DDRV_INIT
			sta	r2L
			lda	r7H
			sbc	#>BASE_DDRV_INIT
			sta	r2H

			LoadW	r0 ,BASE_DDRV_INIT
			MoveW	r13,r1

			lda	r15L			;Speicherbank setzen.
			sta	r3L

;--- Hinweis:
;":StashDskDrv" prüft ob der aktuelle
;Treiber noch in die aktuelle 64K-Bank
;passt. Falls nicht wird die Speicher-
;bank entsprechend korrigiert.
			jsr	StashDskDrv		;Treiber in DACC kopieren.

			lda	r15H			;Position des aktuellen Datensatz
			asl				;in REU zwischenspeichern.
			tax
			lda	r1L
			sta	DRVINF_START +0,x
			lda	r1H
			sta	DRVINF_START +1,x
			lda	r2L
			sta	DRVINF_SIZE +0,x
			lda	r2H
			ldy	r3L			;Treiber innerhalb der ersten
			cpy	MP3_64K_DISK		;Speicherbank ?
			beq	:3			; => Ja, weiter...
			ora	#%10000000		;Speicherbit Bank#2 setzen.
::3			sta	DRVINF_SIZE +1,x

			AddW	r2,r13			;Position für nächsten Datensatz.
			bcc	:4			; => Speicherbank unverändert.
			inc	r15L			;Zeiger auf nächste Speicherbank.

::4			inc	r15H			;Alle 127 Datensätze eingelesen ?
			bpl	:2			; => Nein, weiter...

			jsr	CloseRecordFile		;Treiber-Datei wieder schließen und

			jsr	SetDiskDatReg		;Treiberinformationen in
			jsr	StashRAM		;REU zwischenspeichern.
			ldx	#NO_ERROR
			rts

::5			LoadW	r0,Dlg_ErrLdDk2RAM
			jsr	DoDlgBox
			ldx	#$ff
			rts

;*** Zeiger auf DACC für Laufwerksdaten setzen.
:SetDiskDatReg		LoadW	r0,BASE_EDITOR_DATA
			LoadW	r1,$0000
			LoadW	r2,SIZE_EDITOR_DATA
			lda	MP3_64K_DISK
			sta	r3L
			rts

;*** Laufwerkstreiber in Speicher kopieren.
:StashDskDrv		lda	r3L
			pha
			lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha
			lda	r1H			;Startadresse in REU retten.
			pha
			lda	r1L
			pha

			lda	r1L			;Über 64K-Speichergrenze hinweg
			clc				;Datenbytes in REU speichern ?
			adc	r2L
			sta	r3H
			lda	r1H
			adc	r2H
			bcc	:1			; => Nein, weiter...
			ora	r3H
			beq	:1			; => Nein, weiter...

			lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha

			lda	#$00			;Anzahl Bytes innerhalb
			sec				;aktueller 64K-Speicherbank
			sbc	r1L			;berechnen.
			sta	r2L
			lda	#$00
			sbc	r1H
			sta	r2H

			jsr	StashRAM		;Daten in REU speichern.

			lda	#$00			;Zeiger auf anfang der nächsten
			sta	r1L			;Speicherbank.
			sta	r1H

			pla				;Anzahl Bytes in nächster
			sec				;Speicherbank berechnen.
			sbc	r2L
			sta	r2L
			pla
			sbc	r2H
			sta	r2H

			inc	r3L			;Zeiger auf nächste Speicherbank

::1			jsr	StashRAM		;Bytes in REU kopieren.

			pla
			sta	r1L
			pla
			sta	r1H
			pla
			sta	r2L
			pla
			sta	r2H
			pla
			sta	r3L
			rts

;*** Laufwerkstreiber aus Speicher einlesen.
:FetchDskDrv		lda	r1L			;Über 64K-Speichergrenze hinweg
			clc				;Datenbytes in REU speichern ?
			adc	r2L
			sta	r3H
			lda	r1H
			adc	r2H
			bcc	:1			; => Nein, weiter...
			ora	r3H
			beq	:1			; => Nein, weiter...

			lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha

			lda	#$00			;Anzahl Bytes innerhalb
			sec				;aktueller 64K-Speicherbank
			sbc	r1L			;berechnen.
			sta	r2L
			lda	#$00
			sbc	r1H
			sta	r2H

			jsr	FetchRAM		;Daten in REU speichern.

			lda	#$00			;Zeiger auf anfang der nächsten
			sta	r1L			;Speicherbank.
			sta	r1H

			pla				;Anzahl Bytes in nächster
			sec				;Speicherbank berechnen.
			sbc	r2L
			sta	r2L
			pla
			sbc	r2H
			sta	r2H

			inc	r3L			;Zeiger auf nächste Speicherbank

::1			jmp	FetchRAM		;Bytes in REU kopieren.

;*** Installationsroutine auf Diskette aktualisieren.
;    Übergabe:		AKKU	= Laufwerkstyp
;			r2	= Größe der Installationsroutine.
;    Rückgabe:		xReg	= Fehlermeldung.
:SaveDskDrvData		sta	DDRV_TYPE		;Variablen zwischenspeichern.
			lda	r2L
			sta	DDRV_SIZE +0
			lda	r2H
			sta	DDRV_SIZE +1

			jsr	FindDiskDrvFile		;Treiberdatei suchen.
			txa				;Datei gefunden ?
			bne	:3			; => Nein, Abbruch...

			lda	DDRV_TYPE
			jsr	GetDrvModVec		;Vektor auf Datensatz mit Treiber
			cmp	#$ff			;Unbekanntes Laufwerk ?
			beq	:4			; => Ja, Ende...
			sta	DDRV_REC_INIT		;Datensätze speichern.
			sty	DDRV_REC_DISK

			lda	MP3_64K_DISK		;Treiber in RAM ?
			beq	:1			; => Nein, weiter...

			LoadW	r0,BASE_DDRV_INIT	;Treiber im RAM aktualisieren.
			lda	DDRV_REC_INIT
			jsr	SetVecDskInREU
			jsr	StashDskDrv

::1			LoadW	r0 ,DDRV_FILE
			jsr	OpenRecordFile		;Treiber-Datei öffnen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

			lda	DDRV_REC_INIT
			jsr	PointRecord		;Zeiger auf Installationsroutine.

			lda	DDRV_SIZE +0
			sta	r2L
			lda	DDRV_SIZE +1
			sta	r2H
			LoadW	r7,BASE_DDRV_INIT
			jsr	WriteRecord		;Installationsroutine speichern.
			txa				;Diskettenfehler ?
			beq	:5			; => Ja, Abbruch...

::2			jsr	CloseRecordFile		;Treiberdatei schließen.
::3			jsr	PurgeTurbo		;GEOS-Turbo abschalten und
::4			ldx	#DEV_NOT_FOUND		;Fehlermeldung übergeben.
			rts

::5			jsr	UpdateRecordFile
			txa
			bne	:2

			jsr	CloseRecordFile		;Treiber-Datei wieder schließen und
			jmp	PurgeTurbo		;GEOS-Turbo abschalten, Ende...

;*** Zeiger auf VLIR-Datensatz in REU.
:SetVecDskInREU		asl
			tax
			lda	DRVINF_START +0,x
			sta	r1L
			lda	DRVINF_START +1,x
			sta	r1H
			lda	DRVINF_SIZE +0,x
			sta	r2L
			lda	DRVINF_SIZE +1,x
			pha
			and	#%01111111
			sta	r2H
			lda	MP3_64K_DISK
			sta	r3L
			pla
			and	#%10000000
			beq	:1
			inc	r3L
::1			rts

;*** Neuen Laufwerksmodus auswählen.
:SlctNewDrvMode		LoadW	r0,Dlg_SlctDMode
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Laufwerkstyp auswählen.

			ldx	#CANCEL_ERR
			lda	sysDBData
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:exit			; => Ja, Ende...

			ldx	DB_GetFileEntry
			ldy	DRVINF_TYPES,x		;Laufwerksmodus einlesen.

			ldx	#NO_ERROR
::exit			rts

;*** Partition oder DiskImage wechseln.
:OpenNewDisk		jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:sd2iec			; => Ja, Abbruch...

;--- CMD-Laufwerk: Partition wechseln.
::cmd			ldx	curDrive
			lda	RealDrvMode -8,x	;Partitioniertes Laufwerk ?
			bpl	:sd2iec			; => Nein, Ende...

			LoadW	r0,Dlg_SlctPart
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Partition auswählen.

			jsr	OpenDisk		;Diskette öffnen, dabei aktive
							;Partition auf Gültigkeit testen.

;--- Ergänzung: 15.12.18/M.Kanet
;Auf SD2IEC testen und ggf. DiskImage-Wechsel ausführen.
::sd2iec		ldx	curDrive
			lda	RealDrvMode -8,x	;Partitioniertes Laufwerk ?
			bmi	:exit			; => Ja, weiter...
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:exit			; => Nein, Ende...

			jsr	SlctDiskImg		;DiskImage wechseln.

::exit			rts

;*** Laufwerkstreiber-Datei.
:DDRV_FDRV		b $00
:DDRV_FILE		s 17
:DDRV_FVER		t "src.Disk.Build"
:DDRV_TYPE		b $00
:DDRV_REC_INIT		b $00
:DDRV_REC_DISK		b $00
:DDRV_SIZE		w $0000

;*** Dialogbox: "Laufwerkstreiber nicht gefunden!"
:Dlg_NoDskFile		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_ERR
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$20,$36
			w :3
			b DBTXTSTR   ,$0c,$42
			w :4
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::1			b "Laden der Laufwerkstreiber",NULL
::2			b "ist nicht möglich. Die Datei",NULL
::3			b "GD.DISK",NULL
::4			b "wurde nicht gefunden!",NULL
endif
if Sprache = Englisch
::1			b "Unable to load drivedrivers.",NULL
::2			b "The following system-file ",NULL
::3			b "GD.DISK",NULL
::4			b "was not found on any drive!",NULL
endif

;*** Dialogbox: "Laufwerksmodus wählen:"
:Dlg_SlctDMode		b $81
			b DBUSRFILES
			w DRVINF_NAMES
			b CANCEL    ,$00,$00
			b DBUSRICON ,$00,$00
			w :icon
			b NULL

::icon			w Icon_01
			b $00,$00,Icon_01x,Icon_01y
			w :exit

::exit			lda	#OPEN
			sta	sysDBData
			jmp	RstrFrmDialogue

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_REGISTER
;******************************************************************************
