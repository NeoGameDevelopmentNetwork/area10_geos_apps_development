; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_CHAR"
			t "SymbTab_SCPU"
			t "SymbTab_DBOX"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
			t "e.Register.ext"
			t "s.GDC.Config.ext"
			t "s.GDC.E.GEOS.ext"
			t "o.DiskCore.ext"
endif

;*** GEOS-Header.
			n "GD.CONF.GEOS"
			c "GDC.GEOS    V1.0"
			t "opt.Author"
			f SYSTEM
			z $80 ;nur GEOS64

			o BASE_CONFIG_TOOL

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "GEOS-System konfigurieren"
endif
if LANG = LANG_EN
			h "Configure the GEOS system"
endif

;******************************************************************************
;*** Sprungtabelle.
;******************************************************************************
:MainInit		jmp	InitMenu
:SaveData		jmp	SaveConfig
:CheckData		ldx	#$00
			rts
;******************************************************************************
;*** Systemkennung.
;******************************************************************************
			b "GDCONF10"
;******************************************************************************

;*** Menü initialisieren.
:InitMenu		jsr	e_GetSCPUdata		;SCPU erkennen / SpedFlag auslesen.

			bit	Copy_firstBoot		;GEOS-BootUp - Menüauswahl ?
			bpl	DoAppStart		; => Ja, keine Parameterübernahme.

;--- Erststart initialisieren.
			jsr	SaveConfig		;Variablen aktualisieren.

;*** Menü starten.
:DoAppStart		jsr	InitSCPUopt		;Menü-Optionen für SCPU setzen.

			jsr	GetMoveDataMode		;MoveData-Modus erkennen.
			jsr	GetSerCodeGEOS		;GEOS-ID einlesen.
			jsr	GetNameDT		;Name DeskTop-Datei einlesen.

;--- Ergänzung: 03.01.19/M.Kanet
;Option für QWERTZ ergänzt.
if LANG = LANG_DE
			jsr	GetQWERTZMode		;Tastatur-Modus einlesen.
endif

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Suchroutine für
;RTCs darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	_DDC_DETECTALL		;Geräte am ser.Bus erkennen.
;------------------------------------------------------------------------------

			jsr	e_SetClockGEOS		;Uhrzeit setzen.

			jsr	GetSysInfo		;Systeminformationen einlesen.

			lda	#< RegisterTab		;Register-Menü installieren.
			ldx	#> RegisterTab
			jmp	EnableRegMenu

;*** Aktuelle Konfiguration speichern.
:SaveConfig		lda	Flag_MenuStatus		;Variablen aktualisieren.
			sta	BootMenuStatus

			lda	Flag_SetMLine
			sta	BootMLineMode

			lda	Flag_SetColor
			sta	BootColsMode

			lda	Flag_CrsrRepeat
			sta	BootCRSR_Repeat

;--- Ergänzung: 03.01.19/M.Kanet
;Option für QWERTZ ergänzt.
if LANG = LANG_DE
			jsr	GetQWERTZMode		;Tastatur-Modus einlesen.
endif

			lda	Flag_Optimize
			sta	BootOptimize

			lda	SCPU_SpeedMode
			sta	BootSpeed

			lda	BootRAM_Flag
			and	#%01111111
			sta	BootRAM_Flag
			lda	sysRAMFlg
			and	#%10000000
			ora	BootRAM_Flag
			sta	BootRAM_Flag

			jsr	GetNameDT		;Name DeskTop-Datei einlesen.

			ldx	#NO_ERROR		;Flag: "Kein Fehler!"
			rts

;--- Ergänzung: 03.01.19/M.Kanet
;Option für QWERTZ ergänzt.

;*** QWERTZ-Tastatur aktiv?
if LANG = LANG_DE
:GetQWERTZMode		ldx	#%10000000
			lda	key0z
			cmp	#"y"
			beq	:1
			ldx	#%00000000
::1			stx	BootQWERTZ
			rts
endif

;*** Menü für Cursor-Anzeige initialisieren.
:Init_CRSR_Menu		ldy	#0
::1			lda	TEST_CRSR_STRG,y
			sta	TEST_BUFFER   ,y
			beq	:2
			iny
			bne	:1
::2			rts

;*** Neuen Wert für CURSOR-Speed eingeben.
:Swap_CRSR_Speed	lda	r1L			;Register-Grafikaufbau ?
			beq	Draw_CRSR_Speed		; => Ja, Ende...

			lda	mouseXPos		;Neuen Wert für Verzögerungszeit
			sec				;berechnen.
			sbc	#< $0048
			cmp	#1
			bcs	:1
			lda	#1
::1			lsr
			lsr
			sta	Flag_CrsrRepeat

;*** Verzögerungszeit für Cursor anzeigen.
:Draw_CRSR_Speed	lda	C_InputField		;Farbe für Schiebeegler setzen.
			jsr	DirectColor

			jsr	i_BitmapUp		;Schieberegler ausgeben.
			w	Icon_SETCRSR
			b	$09,$58,Icon_SETCRSR_x,Icon_SETCRSR_y

			ldx	#$09			;Position für Schieberegler
			lda	Flag_CrsrRepeat		;berechnen.
			lsr
			bcs	:1
			dex
::1			sta	:2 +1
			txa
			clc
::2			adc	#$ff
			sta	:6 +0

			ldx	#$01			;Breite des Regler-Icons
			lda	Flag_CrsrRepeat		;berechnen.
			lsr				;Bei 0.5, 1.5, 2.5 usw... 1 CARD.
			bcs	:3			;Bei 1.0, 2.0, 3.0 usw... 2 CARDs.
			inx
::3			stx	:6 +2

			ldx	#< Icon_SETPOS2		;Typ für Regler-Icon ermitteln.
			ldy	#> Icon_SETPOS2
			lda	Flag_CrsrRepeat
			lsr
			bcs	:4			; => Typ #1, 0.5, 1.5, 2.5 usw...
			ldx	#< Icon_SETPOS1		; => Typ #1, 1.0, 2.0, 3.0 usw...
			ldy	#> Icon_SETPOS1
::4			stx	:5 +0
			sty	:5 +1

			jsr	i_BitmapUp		;Schieberegler anzeigen.
::5			w	Icon_SETCRSR
::6			b	$06,$5b,$ff,$05
			rts

;*** SuperCPU erkennen.
:InitSCPUopt		bit	SCPU_Enabled		;SCPU aktiv?
			bpl	:off

			lda	#< UpdateSCPUopt	;SCPU-Geschwindigkeitsanzeige
			sta	appMain  +0		;installieren.
			lda	#> UpdateSCPUopt
			sta	appMain  +1

::1			lda	#BOX_OPTION
			b $2c
::off			lda	#BOX_OPTION_VIEW
			sta	RegTMenu3a		;1MHz on/off.
			sta	RegTMenu3b		;Optimizations on/off.
			rts

;*** Taktfrequenz für SCPU umschalten.
:SwapSFlagSCPU		bit	SCPU_Enabled		;SuperCPU aktiviert ?
			bpl	:1			; => Nein, Ende...

			jsr	GetCurSFlagSCPU
			eor	#%01000000
			sta	BootSpeed

			jsr	e_SetSFlagSCPU
			jsr	UpdateSCPUopt		;Taktfrequenz aktualisieren.

::1			rts

;*** Taktfrequenz für SCPU erkennen.
;    Übergabe:		-
;    Rückgabe:		AKKU	= $40, SuperCPU =>  1Mhz.
;			       = $00, SuperCPU => 20Mhz.
:GetCurSFlagSCPU	php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	SCPU_HW_SPEED
			stx	CPU_DATA
			plp
			and	#%01000000		;Bit 6=0, SCPU mit 20 Mhz.
			rts

;*** Taktfrequenz SCPU abfragen und anzeigen.
;    Diese Routine wird über ":appMain" aufgerufen und ist nur
;    bei eingeschalteter SCPU aktiv!
:UpdateSCPUopt		CmpBI	regMenuCurrent,3	;Ist Registerkarte für SCPU aktiv ?
			bne	:1			; => Nein, weiter...

			jsr	GetCurSFlagSCPU		;Aktuellen SCPU-Takt einlesen.
			cmp	SCPU_SpeedMode		;Hat sich SCPU-Takt geändert ?
			beq	:1			; => Nein, weiter...
			sta	SCPU_SpeedMode		;Neuen Takt zwischenspeichern und
			sta	BootSpeed		;anzeigen.

			LoadW	r15,RegTMenu3a		;Registerkarte aktualisieren.
			jsr	RegisterUpdate

::1			rts

;*** Optimierung für SCPU umschalten.
:SwapOptModeSCPU	bit	SCPU_Enabled		;SuperCPU aktiviert ?
			bpl	:1			; => Nein, Ende...

			lda	Flag_Optimize
			sta	BootOptimize
			jsr	SCPU_SetOpt		;Neue Optimierung aktivieren.

::1			rts

;*** MoveData-Option definieren.
;--- Ergänzung: 21.07.18/M.Kanet
;MOVEDATA funktioniert zwar theoretisch mit allen Speichererweiterungen, da
;aber GEORAM/BBGRAM keinen eigenen Chip dafür verwenden, sind diese
;Speichererweiterungen hier evtl. langsamer als die Standard-Routinen.
;Daher wird die MOVEDATA-Option nur noch mit einer C=REU freigeschaltet.
:GetMoveDataMode	ldx	#BOX_OPTION_VIEW
			bit	SCPU_Enabled		;SCPU aktiv?
			bmi	:1			; => Ja, MOVEDATA deaktivieren.
			lda	GEOS_RAM_TYP		;Speichererweiterung testen.
			and	#%01000000		;C=REU ?
			beq	:1			; => Nein, MOVEDATA deaktivieren.
			ldx	#BOX_OPTION
::1			stx	RegTMenu4b
			cpx	#BOX_OPTION		;MOVEDATA verfügbar?
			beq	:2			; => Ja, Ende...
			lda	sysRAMFlg		;Nicht verfügbar, dann zur
			and	#%01111111		;Sicherheit die Option abschalten.
			sta	sysRAMFlg		;sysRAMFlg und BootRAM_Flag
			sta	sysFlgCopy		;getrennt behandeln.
			lda	BootRAM_Flag
			and	#%01111111
			sta	BootRAM_Flag
::2			rts

;*** *** Laufwerk mit CMD-Uhr anzeigen.
:PutSetClkInfo		jsr	FindTypeRTCdrv		;Zeiger auf RTC-Uhr-Text
			txa				;berechnen und RTC-Gerät anzeigen.
			asl
			tax
			lda	VecRTCtext +0,x
			sta	r0L
			lda	VecRTCtext +1,x
			sta	r0H
			LoadW	r11,$005c
			LoadB	r1H,$66
			jmp	PutString

;*** Neues Gerät mit RTC-Uhr wählen.
:SetNewClkDev		jsr	FindTypeRTCdrv		;Zeiger auf nächstes RTC-Gerät.

			lda	TabRTCtypes,x
			cmp	#$ff
			bne	:1
			ldx	#$ff
::1			inx
			lda	TabRTCtypes,x
			sta	BootRTCdrive		;Keine Uhr setzen ?
			beq	:2			; => Ja, Ende...
			cmp	#$ff			;AutoDetect ?
			beq	:2			; => Ja, Ende...

			jsr	e_FindRTCdev		;RTC-Gerät suchen.
			txa				;RTC-Fehler ?
			bne	SetNewClkDev		; => Ja, nächstes RTC-Gerät.

::2			jsr	SetCurClkTime

			rts

;*** Laufwerkstyp erkennen für RTC-Echtzeituhr.
:FindTypeRTCdrv		ldx	#$00
::1			lda	TabRTCtypes,x		;Modus aus Tabelle mit
			cmp	BootRTCdrive		;Konfiguration vergleichen.
			beq	:2			; => Gefunden, Ende...
			inx
			cmp	#$ff			;Letzten Modus geprüft ?
			bne	:1			; => Nein, weitersuchen.
			ldx	#$00			;RTC-Gerät unbekannt, keine Uhr.
::2			rts

;*** Aktuelle Uhrzeit einlesen.
:SetCurClkTime		jsr	e_SetClockGEOS		;Uhrzeit einlesen.

;*** Uhrzeit ausgeben.
:DrawCurRTCtime		lda	#0
			jsr	SetPattern
			jsr	i_Rectangle
			b $78,$7f
			w $0064,$00df

			lda	BootRTCdrive		;Keine Uhr setzen ?
			beq	:exit

			LoadW	r11,$0064
			LoadB	r1H,$7e
			ClrB	currentMode

			lda	#"="
			jsr	SmallPutChar
			lda	#">"
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			lda	day
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar
			lda	month
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar
			lda	year
			jsr	:prntNum

			lda	#" "
			jsr	SmallPutChar

			lda	hour
			jsr	:prntNum
			lda	#":"
			jsr	SmallPutChar
			lda	minutes
			jsr	:prntNum
			lda	#"."
			jsr	SmallPutChar
			lda	seconds
;			jsr	:prntNum

;--- Dezimal-Zahl 00-99 ausgeben.
::prntNum		jsr	:DEZ2ASCII		;Zahl von DEZ nach ASCII wandeln.
			pha
			txa
			jsr	SmallPutChar		;10er ausgeben.
			pla
			jmp	SmallPutChar		;1er ausgeben.

;*** Dezimalzahl nach ASCII wandeln.
;    Übergabe: AKKU = Dezimal-Zahl 0-99.
;    Rückgabe: XREG/AKKU = 10er/1er Dezimalzahl.
::DEZ2ASCII		ldx	#"0"
::1			cmp	#10			;Restwert < 10?
			bcc	:2			; => Ja, weiter...
;			sec
			sbc	#10			;Restwert -10.
			inx				;10er-Zahl +1.
			cpx	#"9" +1			;10er-Zahl > 9?
			bcc	:1			; => Nein, weiter...
			dex				;Wert >99, Zahl auf
			lda	#9			;99 begrenzen.
::2			clc				;1er-Zahl nach ASCII wandeln.
			adc	#"0"
::exit			rts

;*** GEOS-Code ändern.
:SetNewGEOS_ID		jsr	GetNewCodeGEOS		;ASCII nach GEOS-ID wandeln.
			sty	SerialNumber +0		;Neue GEOS-ID installieren.
			sta	SerialNumber +1

;*** GEOS-ID nach ASCII-Text umwandeln.
:GetSerCodeGEOS		jsr	GetSerialNumber

			lda	r0L
			pha
			lda	r0H
			jsr	SysHEX2ASCII
			stx	GEOS_ID_ASCII +0
			sta	GEOS_ID_ASCII +1
			pla
			jsr	SysHEX2ASCII
			stx	GEOS_ID_ASCII +2
			sta	GEOS_ID_ASCII +3
			rts

;*** ASCII-Text in GEOS-ID umwandeln.
:GetNewCodeGEOS		lda	GEOS_ID_ASCII +2
			ldx	GEOS_ID_ASCII +3
			jsr	:1
			tay
			lda	GEOS_ID_ASCII +0
			ldx	GEOS_ID_ASCII +1
::1			jsr	:2
			asl
			asl
			asl
			asl
			sta	r0L
			txa
			jsr	:2
			ora	r0L
			rts

::2			and	#%01111111
			cmp	#$60
			bcc	:3
			sbc	#$20
::3			sec
			sbc	#$30
			cmp	#10
			bcc	:4
			sbc	#$07
::4			rts

;*** GEOS-ID auf Diskette speichern.
:SaveGEOS_IDtoDsk	lda	SystemDevice		;Startlaufwerk aktivieren.
			jsr	SetDevice
			txa				;Fehler?
			bne	:err_not_found		; => Ja, Abbruch...
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:err_not_found		; => Ja, Abbruch...
			LoadW	r6,FNameG1
			jsr	FindFile		;Systemdatei mit GEOS-ID suchen.
			txa				;Datei gefunden? ?
			beq	:continue		; => Ja, weiter...

::err_not_found		LoadW	r0,Dlg_SvIDErrSys	;Fehler: Datei nicht gefunden.
			jmp	DoDlgBox

;--- GEOS-ID suchen.
::continue		lda	#< SerialNumber
			sec
			sbc	#< OS_LOW -2		;2 Bytes für Dummy-WORD am Beginn
			sta	r10L			;der Startdatei abziehen.
			lda	#> SerialNumber		;(BASIC-Loader!)
			sbc	#> OS_LOW -2
			sta	r10H

			LoadW	r4,diskBlkBuf
			lda	dirEntryBuf +1		;Sektor mit GEOS-ID innerhalb
			ldx	dirEntryBuf +2		;der Startdatei suchen.
::loop1			sta	r1L
			stx	r1H
			jsr	GetBlock
			txa
			bne	:err_disk

			CmpWI	r10,254			;Sektor gefunden ?
			bcc	:save_id		; => Ja, weiter...

			SubVW	254,r10

			ldx	diskBlkBuf +1
			lda	diskBlkBuf +0
			bne	:loop1

::err_disk		LoadW	r0,Dlg_SvIDErrDsk	;Fehler: Nicht gespeichert.
			jmp	DoDlgBox

;--- GEOS-ID speichern.
::save_id		jsr	GetSerialNumber		;Aktuelle GEOS-ID einlesen.

			ldx	r10L			;LowByte der GEOS-ID speichern.
			inx
			inx
::write_low		lda	r0L
			sta	diskBlkBuf,x
			inx				;HighByte noch innerhalb Sektor ?
			bne	:write_high		; => Ja, weiter...

			jsr	PutBlock		;Aktuellen Sektor speichern.
			txa
			bne	:err_disk

			lda	diskBlkBuf +0		;Nächsten Sektor einlesen.
			ldx	diskBlkBuf +1
			sta	r1L
			stx	r1H
			jsr	GetBlock
			txa
			bne	:err_disk

			ldx	#$02			;Zeiger auf erstes Byte.
::write_high		lda	r0H			;HighByte der GEOS-ID speichern.
			sta	diskBlkBuf,x
			jsr	PutBlock
			txa
			bne	:err_disk

			LoadW	r0,Dlg_SvID_OK		;GEOS-ID gespeichert.
			jmp	DoDlgBox

;*** Name DeskTop-Datei einlesen.
:GetNameDT		ldy	#0
::1			lda	DBoxDTopName,y
			beq	:2
			sta	BootNameDT,y
			iny
			cpy	#DBoxDTopNmLen		;DBoxDTopNmLen 7(DE)/12(EN) Bytes.
			bcc	:1
			lda	#NULL			;Textspeicher mit NULL-Bytes
::2			sta	BootNameDT,y		;auffüllen.
			iny
			cpy	#DTopFileNmLen +1
			bcc	:2

			ldy	#0
::3			lda	DeskTopName,y
			beq	:4
			sta	BootFileDT,y
			iny
			cpy	#DTopFileNmLen
			bcc	:3
			lda	#NULL
::4			sta	BootFileDT,y
			iny
			cpy	#DTopFileNmLen +1
			bcc	:4

			rts

;*** Name DeskTop-Datei festlegen.
:UpdateNameDT		lda	r1L			;Register-Grafikaufbau ?
			beq	:exit			; => Ja, Ende...
			jsr	e_SetNameDT		;DeskTop-Name festlegen.
::exit			rts

;*** Anzeige-Name DeskTop zurücksetzen.
:ResetNameDT		lda	r1L			;Register-Grafikaufbau ?
			beq	:exit			; => Ja, Ende...

			LoadW	r0,STD_NAME_DT
			jsr	CopyNameDT

::exit			rts

:CopyNameDT		ldy	#0
::1			lda	(r0L),y
			beq	:2
			sta	BootNameDT,y
			sta	DBoxDTopName,y
			iny
			cpy	#DBoxDTopNmLen		;DBoxDTopNmLen 7(DE)/12(EN) Bytes.
			bcc	:1
			bcs	:3
::2			lda	#NULL
			sta	BootNameDT,y
			lda	#" "
			sta	DBoxDTopName,y
			iny
			cpy	#DBoxDTopNmLen		;DBoxDTopNmLen 7(DE)/12(EN) Bytes.
			bcc	:2

::3			rts

;*** Name DeskTop-Datei zurücksetzen.
:ResetFileDT		lda	r1L			;Register-Grafikaufbau ?
			beq	:exit			; => Ja, Ende...

			LoadW	r0,STD_FILE_DT
			jsr	CopyFileDT

::exit			rts

:CopyFileDT		ldy	#0
::1			lda	(r0L),y
			beq	:2
			sta	BootFileDT,y
			sta	DeskTopName,y
			iny
			cpy	#DTopFileNmLen
			bcc	:1
			lda	#$00
::2			sta	BootFileDT,y
			sta	DeskTopName,y
			iny
			cpy	#DTopFileNmLen +1
			bcc	:2

			rts

;*** DeskTop-Name suchen.
:FindNameDT		ldy	#0
::1			sty	r0L
			tya
			asl
			asl
			asl
			asl
			tax

			ldy	#0
::2			lda	TAB_NAME_DT,x
			beq	:found
			cmp	DBoxDTopName,y
			bne	:3
			inx
			iny
			cpy	#DBoxDTopNmLen		;DBoxDTopNmLen 7(DE)/12(EN) Bytes.
			bcc	:2
			bcs	:found

::3			ldy	r0L
			iny
			cpy	#4
			bcc	:1

			ldy	#0
			b $2c
::found			ldy	r0L
			rts

;*** DeskTop-Datei suchen.
:FindFileDT		ldy	#0
::1			sty	r0L
			tya
			asl
			asl
			asl
			tax

			ldy	#0
::2			lda	TAB_FILE_DT,x
			beq	:found
			cmp	DeskTopName,y
			bne	:3
			inx
			iny
			cpy	#DTopFileNmLen
			bcc	:2
			bcs	:found

::3			ldy	r0L
			iny
			cpy	#4
			bcc	:1

			ldy	#0
			b $2c
::found			ldy	r0L
			rts

;*** DeskTop-Name wechseln.
:SwapNameDT		jsr	FindNameDT

			iny
			cpy	#4
			bcc	:1
			ldy	#0

::1			tya
			asl
			asl
			asl
			asl
			clc
			adc	#< TAB_NAME_DT
			sta	r0L
			lda	#0
			adc	#> TAB_NAME_DT
			sta	r0H

			jmp	CopyNameDT

;*** DeskTop-Datei wechseln.
:SwapFileDT		jsr	FindFileDT

			iny
			cpy	#4
			bcc	:1
			ldy	#0

::1			tya
			asl
			asl
			asl
			clc
			adc	#< TAB_FILE_DT
			sta	r0L
			lda	#0
			adc	#> TAB_FILE_DT
			sta	r0H

			jmp	CopyFileDT

;*** Systeminformationen einlesen.
:GetSysInfo		jsr	SetADDR_EnterDT		;ext. EnterDT-Routine nach
			jsr	FetchRAM		;":LOAD_ENTER_DT" = $7E00 einlesen.

;			LoadW	r0,LOAD_ENTER_DT	;Startadresse EnterDT-Routine.
			LoadW	r1,$00c4		;Länge EnterDT-Routine.
			jsr	CRC			;Prüfsumme berechnen.

;--- Hinweis:
;GD.CONFIG erstellt eine Prüfsumme um
;zu testen ob die Standard-Routine zum
;laden desk DeskTops verwendet wird.
;CRC = $B831, Länge $C4=196 Bytes.
			ldx	#$00
			CmpWI	r2,$b831		;Stimmt CRC-Prüfsumme ?
			beq	:1			; => Ja, Standard-DeskTop.
			dex				; => Nein, RAM-DeskTop.
::1			stx	GEOS_DESKTOP

;--- GDOS-Kernal aktiv ?
;GD.CONFIG kann auch von MP3 aus gestartet werden.
			ldx	#$ff
			lda	bootName +1		;GDOS-Kernal aktiv ?
			cmp	#"D"			;"GDOS64-V3"
			bne	:3			; => Nein, weiter...
			lda	bootName +7
			cmp	#"V"
			bne	:3			; => Nein, weiter...
			lda	bootName +8
			cmp	#"3"
			beq	:4			; => Ja, GDOS64.
::3			inx				; => Nein, GEOS/MegaPatch.
::4			stx	GDOS_KERNAL		;Kernal-Info speichern.

;--- Hilfesystem aktiv ?
			ldy	#$00
			cpx	#$ff			;GDOS-Kernal ?
			bne	:5			; => Nein, weiter...
			ldy	HelpSystemActive	;Status Hilfesystem einlesen.
::5			sty	HELP_SYSTEM

;--- Alle Laufwerkstreiber im RAM ?
			lda	MP3_64K_DISK		;Laufwerkstreiber im RAM ?
			beq	:6			; => Nein, weiter...
			lda	#$ff			;Alle Laufwerkstreiber im RAM.
::6			sta	RAM_DRIVER

			rts

;*** Variablen.
:GEOS_ID_ASCII		s $05
:TEST_BUFFER		s 17
:GEOS_DESKTOP		b $ff
:GDOS_KERNAL		b $ff
:HELP_SYSTEM		b $ff
:RAM_DRIVER		b $ff

;*** RTC-Gerät.
:RTC_Type		b $00

;*** Zeiger auf Texte für RTC-Geräte.
:VecRTCtext		w Text_NORTC
			w Text_TC64
			w Text_U64II
			w Text_CMD_SM
			w Text_CMD_RL
			w Text_CMD_FD
			w Text_CMD_HD
			w Text_AUTO

;*** Tabelle mit RTC-Geräten.
:TabRTCtypes		b $00				;Deaktiviert
			b $fc				;TurboChameleon64
			b $fd				;Ultimate64/II(+)
			b $fe				;CMD-SmartMouse
			b DrvRAMLink			;CMD-RAMlink
			b DrvFD				;CMD-FD
			b DrvHD				;CMD-HD
			b $ff				;Auto-Detect

;*** GEOS-ID.
:FNameG1		b "GD.BOOT.1",NULL

;*** DeskTop-Name.
if LANG = LANG_DE
:STD_NAME_DT		b "GEODESK"
			b NULL
endif
if LANG = LANG_EN
:STD_NAME_DT		b "GEODESK V1.0"
			b NULL
endif
:STD_FILE_DT		b "GEODESK",$00
			b NULL

;--- Hinweis:
;Immer 16 Zeichen ohne NULL-Kennung!
;Zeiger auf Tabelle wird berechnet.
if LANG = LANG_DE
;Stringlänge genau 7(DE) Zeichen.
;RULER --------------1234567---------
:TAB_NAME_DT		b "GEODESK"
::GEODESK		s 16 - (:GEODESK - TAB_NAME_DT)
			b "DUALTOP"
::DUALTOP		s 16 - (:DUALTOP - TAB_NAME_DT -16)
			b "TOPDESK"
::TOPDESK		s 16 - (:TOPDESK - TAB_NAME_DT -32)
			b "DESKTOP"
::DESKTOP		s 16 - (:DESKTOP - TAB_NAME_DT -48)
endif
if LANG = LANG_EN
;Stringlänge genau 12(EN) Zeichen.
;RULER --------------123456789012----
:TAB_NAME_DT		b "GEODESK V1.0"
::GEODESK		s 16 - (:GEODESK - TAB_NAME_DT)
			b "DUALTOP V3.0"
::DUALTOP		s 16 - (:DUALTOP - TAB_NAME_DT -16)
			b "TOPDESK V5.0"
::TOPDESK		s 16 - (:TOPDESK - TAB_NAME_DT -32)
			b "DESKTOP V2.0"
::DESKTOP		s 16 - (:DESKTOP - TAB_NAME_DT -48)
endif

;--- Hinweis:
;Immer 8 Zeichen ohne NULL-Kennung!
;Zeiger auf Tabelle wird berechnet.
:TAB_FILE_DT		b "GEODESK",$00
			b "DUAL_TOP"
			b "TOP DESK"
			b "DESK TOP"

;*** Blinkfrequenz testen.
if LANG = LANG_DE
:TEST_CRSR_STRG		b "<Hier klicken>",0
endif
if LANG = LANG_EN
:TEST_CRSR_STRG		b "<Click here>",0
endif

;*** RTC auswählen.
if LANG = LANG_DE
:Text_NORTC		b "(Deaktiviert)",0
endif
if LANG = LANG_EN
:Text_NORTC		b "(Deactivated)",0
endif

:Text_TC64		b "TC64 v1/v2",0
:Text_U64II		b "Ultimate64/II+",0
:Text_CMD_SM		b "CMD SmartMouse",0
:Text_CMD_RL		b "CMD RAMLink",0
:Text_CMD_FD		b "CMD FD",0
:Text_CMD_HD		b "CMD HD",0
:Text_AUTO		b "AutoDetect",0

;*** Dialogbox: Systemdatei 'GD.BOOT.1' nicht gefunden.
:Dlg_SvIDErrSys		b %01100001
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
			b DBTXTSTR   ,$0c,$38
			w :3
			b DBTXTSTR   ,$0c,$42
			w :4
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b "Systemdatei nicht gefunden:",0
::2			b "  >> GD.BOOT.1",0
::3			b "GEOS-ID konnte nicht auf Disk",0
::4			b "gespeichert werden!",0
endif
if LANG = LANG_EN
::1			b "Systemfile not found:",0
::2			b "  >> GD.BOOT.1",0
::3			b "GEOS-ID could not been",0
::4			b "saved to disk!",0
endif

;*** Dialogbox: GEOS-ID kann wegen DiskError nicht gespeichert werden.
:Dlg_SvIDErrDsk		b %01100001
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
			b DBTXTSTR   ,$0c,$34
			w :3
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b "Speichern der GEOS-ID auf",0
::2			b "Grund eines Diskettenfehlers",0
::3			b "abgebrochen!",0
endif
if LANG = LANG_EN
::1			b "Unable to save GEOS-ID to",0
::2			b "disk because a disk error",0
::3			b "was detected!",0
endif

;*** Dialogbox: GEOS-ID gespeichert.
:Dlg_SvID_OK		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DLG_T_INF
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b "Speichern der GEOS-ID",0
::2			b "erfolgreich beendet!",0
endif
if LANG = LANG_EN
::1			b "Saving the GEOS-ID to disk",0
::2			b "successfully completed!",0
endif

;*** Register-Menü.
:RegisterTab		b $30,$bf
			w $0038,$0137

			b 7				;Anzahl Einträge.

			w RegTName1			;Register: "Menü".
			w RegTMenu1

			w RegTName2			;Register: "Tastatur".
			w RegTMenu2

			w RegTName3			;Register: "SuperCPU".
			w RegTMenu3			;Siehe auch ":UpdateSCPUOpt" !!!

			w RegTName4			;Register: "C=REU".
			w RegTMenu4

			w RegTName5			;Register: "UHRZEIT".
			w RegTMenu5

			w RegTName6			;Register: "GEOS-ID".
			w RegTMenu6

			w RegTName7			;Register: "SYSINFO".
			w RegTMenu7

:RegTName1		w RTabIcon1
			b RegCardIconX_1,$28,RTabIcon1_x,RTabIcon1_y

:RegTName2		w RTabIcon2
			b RegCardIconX_2,$28,RTabIcon2_x,RTabIcon2_y

:RegTName3		w RTabIcon3
			b RegCardIconX_3,$28,RTabIcon3_x,RTabIcon3_y

:RegTName4		w RTabIcon4
			b RegCardIconX_4,$28,RTabIcon4_x,RTabIcon4_y

:RegTName5		w RTabIcon5
			b RegCardIconX_5,$28,RTabIcon5_x,RTabIcon5_y

:RegTName6		w RTabIcon6
			b RegCardIconX_6,$28,RTabIcon6_x,RTabIcon6_y

:RegTName7		w RTabIcon7
			b RegCardIconX_7,$28,RTabIcon7_x,RTabIcon7_y

;*** System-Icons.
:RIcon_Select		w Icon_MSelect
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MSelect_x,Icon_MSelect_y
			b USE_COLOR_INPUT

:RIcon_Button		w Icon_MButton
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MButton_x,Icon_MButton_y
			b USE_COLOR_INPUT

;*** Daten für Register "MENU".
:RegTMenu1		b 7

			b BOX_FRAME
				w RegTText1_01
				w $0000
				b $40,$af
				w $0040,$012f

			b BOX_OPTION
				w RegTText1_02
				w $0000
				b $48
				w $0110
				w Flag_MenuStatus
				b %10000000
			b BOX_OPTION
				w RegTText1_03
				w $0000
				b $58
				w $0110
				w Flag_MenuStatus
				b %00100000
			b BOX_OPTION
				w RegTText1_04
				w $0000
				b $68
				w $0110
				w Flag_SetMLine
				b %10000000
			b BOX_OPTION
				w RegTText1_05
				w $0000
				b $78
				w $0110
				w Flag_MenuStatus
				b %01000000
			b BOX_OPTION
				w RegTText1_06
				w $0000
				b $88
				w $0110
				w Flag_MenuStatus
				b %00010000

			b BOX_OPTION
				w RegTText1_07
				w $0000
				b $a0
				w $0110
				w Flag_SetColor
				b %10000000

;*** Texte für Register "MENU".
if LANG = LANG_DE
:RegTText1_01		b	 "MENÜ-OBERFLÄCHE",0
:RegTText1_02		b	$48,$00,$4e, "Aktuellen Eintrag invertieren:",0
:RegTText1_03		b	$48,$00,$5e, "Menü-Anzeige verbessern:",0
:RegTText1_04		b	$48,$00,$6e, "Menü-Trennlinien setzen:",0
:RegTText1_05		b	$48,$00,$7e, "Stop am unteren Menü-Rand:",0
:RegTText1_06		b	$48,$00,$8e, "Icon-Status in Register-Menüs:",0
:RegTText1_07		b	$48,$00,$9e, "Farbe in allen System- und "
			b GOTOXY,$48,$00,$a6, "Standard-Dialogboxen anzeigen:",0
endif
if LANG = LANG_EN
:RegTText1_01		b	 "MENU INTERFACE",0
:RegTText1_02		b	$48,$00,$4e, "Invert current menu entry:",0
:RegTText1_03		b	$48,$00,$5e, "Improve menu display:",0
:RegTText1_04		b	$48,$00,$6e, "Insert lines between entries:",0
:RegTText1_05		b	$48,$00,$7e, "Stop at bottom of menu:",0
:RegTText1_06		b	$48,$00,$8e, "Icon status in register menus:",0
:RegTText1_07		b	$48,$00,$9e, "Show color in all standard"
			b GOTOXY,$48,$00,$a6, "and system dialog boxes:",0
endif

;*** Daten für Register "TASTATUR".
if LANG = LANG_DE
:RegTMenu2		b 5

			b BOX_FRAME
				w RegTText2_01
				w Init_CRSR_Menu
				b $40,$87
				w $0040,$012f
			b BOX_USER
				w RegTText2_02
				w Swap_CRSR_Speed
				b $58,$5f
				w $004c,$0087
			b BOX_STRING
				w RegTText2_03
				w $0000
				b $78
				w $00a8
				w TEST_BUFFER
				b 16

			b BOX_FRAME
				w RegTText2_04
				w $0000
				b $98,$af
				w $0040,$012f
			b BOX_OPTION
				w RegTText2_05
				w e_InitQWERTZ
				b $a0
				w $0120
				w BootQWERTZ
				b %10000000
endif

if LANG = LANG_EN
:RegTMenu2		b 3

			b BOX_FRAME
				w RegTText2_01
				w Init_CRSR_Menu
				b $40,$af
				w $0040,$012f
			b BOX_USER
				w RegTText2_02
				w Swap_CRSR_Speed
				b $58,$5f
				w $004c,$0087
			b BOX_STRING
				w RegTText2_03
				w $0000
				b $98
				w $0048
				w TEST_BUFFER
				b 16
endif

;*** Texte für Register "TASTATUR".
if LANG = LANG_DE
:RegTText2_01		b	 "GESCHWINDIGKEIT",0
:RegTText2_02		b 	$48,$00,$4d, "Wiederholfrequenz bei Texteingaben:"
			b GOTOXY,$48,$00,$66, "<+>"
			b GOTOXY,$78,$00,$66, "<->",0
:RegTText2_03		b	$48,$00,$7e, "Eingabe testen:"
			b GOTOXY,$a8,$00,$5e, "Zum testen Eingabefeld"
			b GOTOXY,$a8,$00,$66, "anklicken, beenden mit"
			b GOTOXY, $a8,$00,$6e, "der 'RETURN'-Taste.",0
:RegTText2_04		b	 "TASTATUR",0
:RegTText2_05		b	$48,$00,$a6, "QWERTZ-Tastaturlayout verwenden:",0
endif
if LANG = LANG_EN
:RegTText2_01		b	 "KEYBOARD-SPEED",0
:RegTText2_02		b	$48,$00,$4d, "Repeatfrequency when enter text:"
			b GOTOXY,$48,$00,$66, "<+>"
			b GOTOXY,$78,$00,$66, "<->",0
:RegTText2_03		b	$48,$00,$7e, "Test settings:"
			b GOTOXY,$48,$00,$86, "Click here to test your settings,"
			b GOTOXY,$48,$00,$8e, "press 'RETURN' to exit.",0
endif

;*** Daten für Register "SUPERCPU".
:RegTMenu3		b 5

			b BOX_FRAME
				w RegTText3_01
				w $0000
				b $40,$af
				w $0040,$012f
			b BOX_OPTION_VIEW
				w RegTText3_02
				w $0000
				b $48
				w $0110
				w SCPU_Enabled
				b %11111111
:RegTMenu3a		b BOX_OPTION
				w RegTText3_03
				w SwapSFlagSCPU
				b $58
				w $0110
				w SCPU_SpeedMode
				b %11111111
:RegTMenu3b		b BOX_OPTION
				w RegTText3_04
				w SwapOptModeSCPU
				b $68
				w $0110
				w Flag_Optimize
				b %00000011
			b BOX_OPTION_VIEW
				w RegTText3_05
				w $0000
				b $78
				w $0110
				w SCPU_Enabled
				b %11111111

;*** Texte für Register "SUPERCPU".
if LANG = LANG_DE
:RegTText3_01		b	 "CMD SUPERCPU",0
:RegTText3_02		b	$48,$00,$4e, "SuperCPU aktiviert:"
			b GOTOXY,$48,$00,$96, "Hinweis:"
			b GOTOXY,$48,$00,$9e, "Die SuperCPU wird beim Start von"
			b GOTOXY,$48,$00,$a6, "GEOS automatisch erkannt",0
:RegTText3_03		b	$48,$00,$5e, "1MHz-Modus aktivieren:",0
:RegTText3_04		b	$48,$00,$6e, "Optimierung deaktivieren:",0
:RegTText3_05		b	$48,$00,$7e, "16Bit-MoveData aktiviert:",0
endif
if LANG = LANG_EN
:RegTText3_01		b	 "CMD SUPERCPU",0
:RegTText3_02		b	$48,$00,$4e, "SuperCPU enabled:"
			b GOTOXY,$48,$00,$96, "Note:"
			b GOTOXY,$48,$00,$9e, "SuperCPU is detected automatically"
			b GOTOXY,$48,$00,$a6, "when you boot into GEOS.",0
:RegTText3_03		b	$48,$00,$5e, "Enable 1MHz mode:",0
:RegTText3_04		b	$48,$00,$6e, "Disable optimization:",0
:RegTText3_05		b	$48,$00,$7e, "16Bit MoveData enabled:",0
endif

;*** Daten für Register "MOVEDATA".
:RegTMenu4		b 2

			b BOX_FRAME
				w RegTText4_01
				w $0000
				b $40,$af
				w $0040,$012f
:RegTMenu4b		b BOX_OPTION
				w RegTText4_02
				w $0000
				b $50
				w $0110
				w sysRAMFlg
				b %10000000

;*** Texte für Register "MOVEDATA".
if LANG = LANG_DE
:RegTText4_01		b	 "MOVEDATA",0
:RegTText4_02		b	$48,$00,$4e, "Schnellen Speichertransfer"
			b GOTOXY,$48,$00,$56, "für GEOS-Routinen aktivieren:"
			b GOTOXY,$48,$00,$96, "Hinweis:"
			b GOTOXY,$48,$00,$9e, "Diese Routinen können nur mit einer"
			b GOTOXY,$48,$00,$a6, "Commodore-REU genutzt werden!",0
endif
if LANG = LANG_EN
:RegTText4_01		b	 "MOVEDATA",0
:RegTText4_02		b	$48,$00,$4e, "Use fast memory transfer"
			b GOTOXY,$48,$00,$56, "for GEOS routines:"
			b GOTOXY,$48,$00,$96, "Note:"
			b GOTOXY,$48,$00,$9e, "You need a Commodore REU to"
			b GOTOXY,$48,$00,$a6, "use this special routines!",0
endif

;*** Daten für Register "GEOS-UHR".
:RegTMenu5		b 5

			b BOX_FRAME
				w RegTText5_01
				w _DDC_DETECTALL
				b $40,$af
				w $0040,$012f
::u01			b BOX_USEROPT_VIEW
				w RegTText5_02
				w PutSetClkInfo
				b $60,$67
				w $0058,$00c7
			b BOX_FRAME
				w $0000
				w $0000
				b $5f,$68
				w $00c8,$00d0
			b BOX_ICON
				w $0000
				w SetNewClkDev
				b $60
				w $00c8
				w RIcon_Select
				b (:u01 - RegTMenu5 -1)/11 +1
			b BOX_ICON
				w RegTText5_03
				w SetCurClkTime
				b $70
				w $0058
				w RIcon_Button
				b (:u01 - RegTMenu5 -1)/11 +1

;*** Texte für Register "GEOS-UHR".
;--- Hinweis:
;Turbo-Mode im Ultimate64 wurde mit der
;Firmware V1.34 eingeführt:
;https://ultimate64.com/OlderFirmware
;
if LANG = LANG_DE
:RegTText5_01		b	 "UHRZEIT SETZEN",0
:RegTText5_02		b	$48,$00,$4e, "Das Datum wird beim Start aus"
			b GOTOXY,$48,$00,$56, "diesem Gerät ausgelesen:",0
:RegTText5_03		b	$64,$00,$76, "Datum/Uhrzeit aktualisieren"
			b GOTOXY,$48,$00,$8c, "Ultimate64-Anwender:"
			b GOTOXY,$48,$00,$96, "Firmware V1.34 "
			b                      "wird nicht unterstützt!"
			b GOTOXY,$48,$00,$9e, " -> C64 and cartridge settings"
			b GOTOXY,$48,$00,$a6, " -> Command interface = ENABLED",0
endif
if LANG = LANG_EN
:RegTText5_01		b	 "SET CLOCK",0
:RegTText5_02		b	$48,$00,$4e, "The current date will be taken"
			b GOTOXY,$48,$00,$56, "from this device:",0
:RegTText5_03		b	$64,$00,$76, "Update GEOS time and date"
			b GOTOXY,$48,$00,$8c, "Ultimate64 users:"
			b GOTOXY,$48,$00,$96, "Firmware V1.34 is not supported!"
			b GOTOXY,$48,$00,$9e, " -> C64 and cartridge settings"
			b GOTOXY,$48,$00,$a6, " -> Command interface = ENABLED",0
endif

;*** Daten für Register "GEOS".
:RegTMenu6		b 12

;--- GEOS-ID.
			b BOX_FRAME
				w RegTText6_01
				w $0000
				b $40,$6f
				w $0040,$012f
::u01			b BOX_STRING
				w RegTText6_02
				w SetNewGEOS_ID
				b $60
				w $0060
				w GEOS_ID_ASCII
				b $04
			b BOX_ICON
				w $0000
				w SaveGEOS_IDtoDsk
				b $60
				w $0098
				w RIcon_Button
				b (:u01 - RegTMenu6 -1)/11 +1

;--- DESKTOP.
			b BOX_FRAME
				w RegTText6_03
				w $0000
				b $80,$af
				w $0040,$012f
::u02			b BOX_STRING
				w RegTText6_04
				w UpdateNameDT
				b $88
				w $0120 - DBoxDTopNmLen*8
				w BootNameDT
				b DBoxDTopNmLen
			b BOX_FRAME
				w $0000
				w $0000
				b $87,$90
				w $0120,$0128
			b BOX_ICON
				w $0000
				w SwapNameDT
				b $88
				w $0120
				w RIcon_Select
				b (:u02 - RegTMenu6 -1)/11 +1
			b BOX_ICON
				w $0000
				w ResetNameDT
				b $88
				w $0048
				w RIcon_Button
				b (:u02 - RegTMenu6 -1)/11 +1

::u03			b BOX_STRING
				w RegTText6_05
				w UpdateNameDT
				b $98
				w $0120 - DTopFileNmLen*8
				w BootFileDT
				b DTopFileNmLen
			b BOX_FRAME
				w $0000
				w $0000
				b $97,$a0
				w $0120,$0128
			b BOX_ICON
				w $0000
				w SwapFileDT
				b $98
				w $0120
				w RIcon_Select
				b (:u03 - RegTMenu6 -1)/11 +1
			b BOX_ICON
				w $0000
				w ResetFileDT
				b $98
				w $0048
				w RIcon_Button
				b (:u03 - RegTMenu6 -1)/11 +1

;*** Texte für Register "GEOS".
if LANG = LANG_DE
:RegTText6_01		b	 "GEOS ID",0
:RegTText6_02		b	$48,$00,$4e, "Die aktuelle GEOS-ID. Erforderlich für"
			b GOTOXY,$48,$00,$56, "verschiedene GEOS-Anwendungen."
			b GOTOXY,$48,$00,$66, "ID:"
			b GOTOXY,$a4,$00,$66, "ID auf Disk speichern",0
:RegTText6_03		b	 "DESKTOP",0
:RegTText6_04		b	$54,$00,$8e, "Text für DialogBox:",0
:RegTText6_05		b	$54,$00,$9e, "Dateiname:"
			b GOTOXY,$4c,$00,$aa, "+GeoDesk64/"
			b	   "DUAL_TOP/"
			b	   "TOP DESK/"
			b	   "DESK TOP",0
endif
if LANG = LANG_EN
:RegTText6_01		b 	 "GEOS ID",0
:RegTText6_02		b	$48,$00,$4e, "The current GEOS-ID. Required for"
			b GOTOXY,$48,$00,$56, "various GEOS applications."
			b GOTOXY,$48,$00,$66, "ID:"
			b GOTOXY,$a4,$00,$66, "Save ID to disk",0
:RegTText6_03		b	 "DESKTOP",0
:RegTText6_04		b	$54,$00,$8e, "Dialog box text:",0
:RegTText6_05		b	$54,$00,$9e, "File name:"
			b GOTOXY,$4c,$00,$aa, "+GeoDesk64/"
			b	   "DUAL_TOP/"
			b	   "TOP DESK/"
			b	   "DESK TOP",0
endif

;*** Daten für Register "?".
:RegTMenu7		b 8

;--- Position/X:
:xo1 = $50
:xo2 = $c0

;--- Textzeilen.
:xt0 = $48
:xt1 = xo1 +14
:xt2 = xo2 +14

;--- Copyright.
:xc1 = xt0
:xc2 = xt0
:xd1 = xc1 +70
:xd2 = xc2 +70

;--- Position/Y:
:yo1 = $58
:yo2 = $68
:yo3 = $78
:yo4 = $88

;--- Textzeilen.
:yt0 = $4e
:yt1 = yo1 +6
:yt2 = yo2 +6
:yt3 = yo3 +6
:yt4 = yo4 +6

;--- Copyright.
:yc1 = $a0
:yc2 = $a9

;--- GEOS-ID.
			b BOX_FRAME
				w RegTText7_01
				w $0000
				b $40,$af
				w $0040,$012f
;--- Kernal / RAM-DeskTop.
			b BOX_OPTION_VIEW
				w RegTText7_02
				w $0000
				b yo1
				w xo1
				w GDOS_KERNAL
				b %11111111
			b BOX_OPTION_VIEW
				w RegTText7_03
				w $0000
				b yo1
				w xo2
				w GEOS_DESKTOP
				b %11111111
;--- Disk2RAM / Hilfesystem.
			b BOX_OPTION_VIEW
				w RegTText7_04
				w $0000
				b yo2
				w xo1
				w RAM_DRIVER
				b %11111111
			b BOX_OPTION_VIEW
				w RegTText7_05
				w $0000
				b yo2
				w xo2
				w HELP_SYSTEM
				b %10000000
;--- TaskManager / Spooler.
			b BOX_OPTION_VIEW
				w RegTText7_06
				w $0000
				b yo3
				w xo1
				w Flag_TaskAktiv
				b %10000000
			b BOX_OPTION_VIEW
				w RegTText7_07
				w $0000
				b yo3
				w xo2
				w Flag_Spooler
				b %10000000
;--- ScreenSaver.
			b BOX_OPTION_VIEW
				w RegTText7_08
				w $0000
				b yo4
				w xo1
				w Flag_ScrSaver
				b %10000000

;*** Texte für Register "?".
if LANG = LANG_DE
:RegTText7_01		b	 "Systeminformationen"
			b GOTOXY,xt0,$00,yt0, "Build-ID: "
			t 	 "opt.GDOS.Build"
			b GOTOXY,xc1,$00,yc1, "GEOS-Kernal"
			b GOTOXY,xd1,$00,yc1, "by: Berkeley Softworks"
			b GOTOXY,xc2,$00,yc2, "GDOS-Update"
			b GOTOXY,xd2,$00,yc2, "by: Markus Kanet"
			b	 NULL
:RegTText7_02		b	xt1,$00,yt1, "GDOS64-V3",0
:RegTText7_03		b	xt2,$00,yt1, "RAM-DeskTop",0
:RegTText7_04		b	xt1,$00,yt2, "Treiber im RAM",0
:RegTText7_05		b	xt2,$00,yt2, "Hilfesystem",0
:RegTText7_06		b	xt1,$00,yt3, "TaskManager",0
:RegTText7_07		b	xt2,$00,yt3, "Drucker-Spooler",0
:RegTText7_08		b	xt1,$00,yt4, "Bildschirmschoner deaktiviert",0
endif
if LANG = LANG_EN
:RegTText7_01		b	 "System information"
			b GOTOXY,yt0,$00,yt0, "Build-ID: "
			t 	 "opt.GDOS.Build"
			b GOTOXY,xc1,$00,yc1, "GEOS-Kernal"
			b GOTOXY,xd1,$00,yc1, "by: Berkeley Softworks"
			b GOTOXY,xc2,$00,yc2, "GDOS-Update"
			b GOTOXY,xd2,$00,yc2, "by: Markus Kanet"
			b	 NULL
:RegTText7_02		b	xt1,$00,yt1, "GDOS64-V3",0
:RegTText7_03		b	xt2,$00,yt1, "RAM deskTop",0
:RegTText7_04		b	xt1,$00,yt2, "Driver in RAM",0
:RegTText7_05		b	xt2,$00,yt2, "Help system",0
:RegTText7_06		b	xt1,$00,yt3, "TaskManager",0
:RegTText7_07		b	xt2,$00,yt3, "Printer spooler",0
:RegTText7_08		b	xt1,$00,yt4, "Screensaver disabled",0
endif

;*** System-Icons einbinden.
if .p
:EnableMSelect		= TRUE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= FALSE
:EnableMButton		= TRUE
endif
			t "-SYS_ICONS"

;*** Icons.
:Icon_SETCRSR
<MISSING_IMAGE_DATA>
:Icon_SETCRSR_x		= .x
:Icon_SETCRSR_y		= .y

:Icon_SETPOS1
<MISSING_IMAGE_DATA>
:Icon_SETPOS1_x		= .x
:Icon_SETPOS1_y		= .y

:Icon_SETPOS2
<MISSING_IMAGE_DATA>
:Icon_SETPOS2_x		= .x
:Icon_SETPOS2_y		= .y

;*** Register-Icons.
if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>
:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>
:RTabIcon1_x		= .x
:RTabIcon1_y		= .y
endif

if LANG = LANG_DE
:RTabIcon2
<MISSING_IMAGE_DATA>
:RTabIcon2_x		= .x
:RTabIcon2_y		= .y
endif

if LANG = LANG_EN
:RTabIcon2
<MISSING_IMAGE_DATA>
:RTabIcon2_x		= .x
:RTabIcon2_y		= .y
endif

:RTabIcon3
<MISSING_IMAGE_DATA>
:RTabIcon3_x		= .x
:RTabIcon3_y		= .y

:RTabIcon4
<MISSING_IMAGE_DATA>
:RTabIcon4_x		= .x
:RTabIcon4_y		= .y

if LANG = LANG_DE
:RTabIcon5
<MISSING_IMAGE_DATA>
:RTabIcon5_x		= .x
:RTabIcon5_y		= .y
endif

if LANG = LANG_EN
:RTabIcon5
<MISSING_IMAGE_DATA>
:RTabIcon5_x		= .x
:RTabIcon5_y		= .y
endif

:RTabIcon6
<MISSING_IMAGE_DATA>
:RTabIcon6_x		= .x
:RTabIcon6_y		= .y

:RTabIcon7
<MISSING_IMAGE_DATA>
:RTabIcon7_x		= .x
:RTabIcon7_y		= .y

;*** X-Koordinate der Register-Icons.
:RegCardIconX_1		= $07
:RegCardIconX_2		= RegCardIconX_1 + RTabIcon1_x
:RegCardIconX_3		= RegCardIconX_2 + RTabIcon2_x
:RegCardIconX_4		= RegCardIconX_3 + RTabIcon3_x
:RegCardIconX_5		= RegCardIconX_4 + RTabIcon4_x
:RegCardIconX_6		= RegCardIconX_5 + RTabIcon5_x
:RegCardIconX_7		= RegCardIconX_6 + RTabIcon6_x

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g RegMenuBase
;******************************************************************************
