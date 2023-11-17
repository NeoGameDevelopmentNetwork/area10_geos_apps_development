; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"

:mport = $dc01
:mpddr = $dc03

endif

			n	"mod.#108.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	SetCMDtime

;*** CMD-Uhren setzen.
;    SmartMouse wird als Gerät #7
;    angesprochen!
:SetCMDtime		jsr	InitForIO		;BASIC-I/O-Kanaäle schließen.
			jsr	CLALL			;Ein weglassen dieser Befehle kann bei
			jsr	DoneWithIO		;verschiedenen Konfigurationen zum
							;Aufhängen des Systems führen!
			jsr	UseSystemFont		;Systemzeichensatz aktivieren.

;*** Echtzeit-Uhren suchen.
			jsr	DoInfoBox
			PrintStrgV1062k0

			ClrB	V1062c0			;Anzahl Laufwerke auf NULL.

			lda	#7			;Gerät #7 = SmartMouse.
			sta	V1062c4

::101			pha
			PrintStrgV1062k0
			pla
			pha
			sta	r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal
			lda	#" "
			jsr	SmallPutChar
			pla

			pha
			jsr	GetRTCmode		;Uhrzeit einlesen.
			txa				;Keine RTC in CMD-Laufwerk ?
			bne	:102			;Ja, kein RTC-Drive...

			inc	V1062c0			;Anzahl Drives mit RTC korrigieren.

::102			pla				;Zeiger auf Laufwerk einlesen.
			add	1
			cmp	#30
			bcc	:101			;Laufwerke A: bis D: testen.

			jsr	ClrBox

;*** Bildschirm aufbauen.
::103			jsr	ClrScreen
			jsr	i_C_MenuTitel
			b	$00,$00,$28,$01
			jsr	i_C_MenuBack
			b	$00,$01,$28,$18

			jsr	UseGDFont
			PrintXY	$0008,$06,V1062b0

			FrameRec$37,$b8,$0000,$013f,%11111111
			FrameRec$b8,$c7,$0000,$013f,%11111111
			FillPRec$00,$30,$37,$0008,$0067

			LoadB	V1062a0,3

			lda	V1062c0
			beq	:104
			PrintStrgV1062h0
			FrameRec$47,$50,$006f,$00d0,%11111111
			jsr	i_ColorBox
			b	$0e,$09,$0c,$01,$01
			inc	V1062a0

::104			jsr	i_C_Register
			b	$01,$06,$0c,$01
			PrintStrgV1062h1
			FrameRec$5f,$68,$006f,$00b0,%11111111
			jsr	i_ColorBox
			b	$0e,$0c,$08,$01,$01
			FrameRec$77,$80,$006f,$00b0,%11111111
			jsr	i_ColorBox
			b	$0e,$0f,$08,$01,$01

			jsr	ReadDrvRTC		;Aktuelle Uhrzeit aus erstem RTC-Gerät
							;einlesen.
			LoadB	V1062c2,$ff
			jsr	DoClockGEOS		;GEOS-Uhr starten.

			StartMouse			;Maus starten.
			NoMseKey			;Warten bis keine Maustaste gedrückt.

			lda	#15
			ldx	V1062c0
			beq	:105
			lda	#20
::105			sta	:106 +2
			jsr	i_C_MenuMIcon
::106			b	$00,$01,$14,$03

			LoadW	r0,HelpFileName
			lda	#<SetCMDtime
			ldx	#>SetCMDtime
			jsr	InstallHelp		;Online-Hilfe installieren.

			LoadW	r0,V1062a0
			jmp	DoIcons			;Menü starten.

;*** Zurück zu GeoDOS.
:L1062ExitGD		ldx	#0			;Prozesse abschalten.
			jsr	FreezeProcess
			ldx	#0			;Prozesse abschalten.
			jsr	BlockProcess
			jsr	ClrScreen		;Bildschirm löschen.
			jmp	InitScreen		;Zurück zu GeoDOS.

;*** Uhrzeit aus Laufwerk auslesen.
:ReadDrvRTC		lda	V1062c0			;RTC-Uhr verfügbar ?
			bne	:100			;Ja, weiter...
			rts				;Ende.

::100			lda	V1062c4			;Zeiger auf RTC-Gerät einlesen.
			cmp	#30			;Max. Adresse #30 erreicht ?
			bcc	:101			;Nein, weiter...
			lda	#$07			;Zurück auf erstes RTC-Gerät.
			sta	V1062c4
::101			jsr	GetRTCmode		;RTC-Gerät verfügbar ?
			txa				;Ja, RTC-Zeit auslesen.
			beq	:103
::102			inc	V1062c4			;Zeiger auf nächstes Gerät.
			jmp	:100			;Uhrzeit einlesen.

::103			php				;Uhrzeit nach GEOS/GeoDOS wandeln.
			sei

			lda	V1062e1+0		;Wochentag in Zwischenspeicher.
			sta	V1062e3+0

			lda	V1062e1+4		;12-Stunden-Anzeige nach 24h umrechnen.
			ldx	V1062e1+7
			bne	:104
			cmp	#12
			bne	:105
			lda	#0
			beq	:105
::104			cmp	#12
			beq	:105
			add	12
::105			sta	V1062e1+4

			ldx	#$05			;GEOS-Uhrzeit in
::106			lda	V1062e1+1,x
			sta	V1062e3+1,x		;Zwischenspeicher kopieren.
			dex
			bpl	:106

			plp

			jsr	SetCPUtime		;C64-Zeit setzen.

			FillPRec$00,$88,$a7,$0020,$011f
			jsr	i_C_MenuBack
			b	$04,$11,$20,$03

			CmpBI	V1062c4,$08
			bcs	:107

;*** Zeit eingelesen aus SmartMouse.
			PrintStrgV1062k2
			jmp	:108

;*** Zeit eingelesen aus Laufwerk.
::107			PrintStrgV1062k3

			FrameRec$97,$a0,$006f,$0088,%11111111
			jsr	i_ColorBox
			b	$0e,$13,$03,$01,$01
			FillPRec$00,$98,$9f,$0070,$0087

			LoadW	r11,$0074
			LoadB	r1H,$9e
			MoveB	V1062c4,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

::108			inc	V1062c4
			rts

;*** RTC-Uhren setzen.
:SetAllRTCs		lda	V1062c0			;RTC-Laufwerke vorhanden ?
			bne	:101			;Ja, weiter...
			jmp	L1062ExitGD		;Zurück zu GeoDOS.

::101			ldx	#$00			;Uhrzeit korrigieren.
			lda	V1062e3+4
			bne	:102
			lda	#12
			bne	:104
::102			cmp	#12			;Stunde > 12 ?
			bcc	:104			;Nein, weiter...
			beq	:103
			sbc	#12			;Ja, 12 abziehen und
::103			inx				;AM/PM-Flag setzen.
::104			sta	V1062e3+4
			stx	V1062e3+7

;*** Uhrzeit an Laufwerk senden.
			lda	#7
::105			pha
			jsr	GetRTCmode		;Auf RTC-Gerät testen.
			txa				;RTC-Gerät verfügbar ?
			bne	:106			;Nein, weiter...
			pla
			pha
			jsr	SendTimeRTC		;Uhrzeit aktualisieren.
::106			pla
			add	1
			cmp	#30			;Zeiger auf näöchstes RTC-Gerät.
			bne	:105

			jmp	L1062ExitGD		;Zurück zu GeoDOS.

;*** Uhrzeit auf RTC-Drive setzen.
:SendTimeRTC		cmp	#$08			;RTC-Gerät prüfen.
			bcs	:101			;SmartMouse ?
			jmp	SendSM_RTC		;Ja, weiter...

::101			pha
			lda	Target_Drv
			jsr	NewDrive
			jsr	PurgeTurbo
			jsr	InitForIO

			pla
			tax
			PushB	curDevice
			stx	curDevice

			ClrB	STATUS			;Gerät aktivieren.
			jsr	UNLSN
			lda	curDevice
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND

			ldy	#0			;Neue Laufwerksadresse senden ?
::102			lda	V1062e2,y
			jsr	CIOUT
			iny
			cpy	#13
			bne	:102

			jsr	UNLSN			;OK!

			PopB	curDevice
			jmp	DoneWithIO

;*** Uhrzeit auf RTC-SmartMouse setzen.
:SendSM_RTC		bit	c128Flag
			bpl	:101
			rts

::101			lda	Target_Drv
			jsr	NewDrive
			jsr	PurgeTurbo

			jsr	InitForIO		;Uhrzeit einlesen.
			jsr	SM_RdClk
			jsr	DoneWithIO

			ldx	V1062d0  +0
			cpx	#$ff			;SmartMouse verfügbar ?
			beq	:103			;Nein, übergehen.

			lda	V1062e3 +0		;Wochentag.
			add	1
			jsr	DEZtoBCD
			sta	V1062d0  +5

			lda	V1062e3 +1		;Jahr.
			jsr	DEZtoBCD
			sta	V1062d0  +6

			lda	V1062e3 +2		;Monat.
			jsr	DEZtoBCD
			sta	V1062d0  +4

			lda	V1062e3 +3		;Tag.
			jsr	DEZtoBCD
			sta	V1062d0  +3

			lda	V1062e3 +4		;Stunde.
			jsr	DEZtoBCD
			ldx	V1062e3 +7
			beq	:102
			ora	#%10100000
::102			sta	V1062d0  +2

			lda	V1062e3 +5		;Minute.
			jsr	DEZtoBCD
			sta	V1062d0  +1

			lda	V1062e3 +6		;Sekunde.
			jsr	DEZtoBCD
			sta	V1062d0  +0

			jsr	InitForIO		;Uhrzeit aktualisieren.
			jsr	SM_WrClk
			jsr	DoneWithIO

::103			rts

;*** Laufwerk auf RTC prüfen und Uhrzeit einlesen.
:GetRTCmode		cmp	#$07			;SmartMouse ?
			bne	:102			;Nein, weiter...
			bit	c128Flag		;C128 ?
			bmi	:101			;Ja, Fehler!
			jmp	GetRTCmodeSM		;Sonderbehandlung für SmartMouse.
::101			ldx	#$ff
			rts

::102			pha
			lda	Target_Drv
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			jsr	PurgeTurbo		;GEOS-Turbo deaktivieren und
			jsr	InitForIO		;I/O einschalten.
			pla

::103			tax
			PushB	curDevice
			stx	curDevice

			ClrB	STATUS			;Befehlskanal zum Gerät öffnen.
			jsr	UNLSN
			lda	curDevice
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND

			lda	STATUS
			beq	:105
			jsr	UNLSN
::104			ldx	#$ff
			jmp	:115

::105			ldy	#$00			;Befehl zum lesen dr Uhrzeit an
::106			sty	:107 +1			;Gerät senden.
			lda	V1062e0,y
			jsr	CIOUT
::107			ldy	#$ff
			iny
			cpy	#$04
			bcc	:106

			jsr	UNLSN

			ClrB	STATUS
			jsr	UNTALK
			lda	curDevice
			jsr	TALK
			lda	#$ff
			jsr	TKSA

			lda	STATUS
			beq	:108
			jsr	UNTALK
			ldx	#$ff
			jmp	:115

::108			ldy	#$00			;Uhrzeit einlesen.
::109			sty	:110 +1
			jsr	ACPTR
::110			ldy	#$ff
			sta	V1062e4,y
			iny
			cpy	#$09
			bcc	:109

			pha
::111			lda	STATUS
			bne	:112
			jsr	ACPTR
			jmp	:111

::112			jsr	UNTALK
			pla

			ldx	#$ff
			cmp	#$0d
			bne	:115

			ldy	#$08			;Uhrzeit in Zwischenspeicher kopieren.
::113			lda	V1062e4,y
			sta	V1062e1,y
			dey
			bne	:113

			lda	V1062e4 +0		;Wochentag testen.
			cmp	#$07			;Wochentag im gültigen Bereich ?
			bcc	:114			;Ja, weiter...
			lda	#$06			;Ungültiger Wochentag.
::114			sta	V1062e1 +0

			ldx	#$00
::115			stx	:116 +1

			PopB	curDevice
			jsr	DoneWithIO		;I/O abschalten.

			lda	Target_Drv
			jsr	NewDrive		;Lauufwerk wieder zurücksetzen.
::116			ldx	#$00
			rts

;*** SmartMouse auf RTC prüfen und Uhrzeit einlesen.
:GetRTCmodeSM		jsr	PurgeTurbo		;GEOS-Turbo deaktivieren und
			jsr	InitForIO		;I/O einschalten.

			jsr	SM_RdClk		;Uhrzeit einlesen.

			ldx	V1062d0  +0
			cpx	#$ff			;SmartMouse verfügbar ?
			beq	:103			;Nein, übergehen.

			lda	V1062d0  +5		;Wochentag.
			jsr	BCDtoDEZ
			sub	1
			bcs	:101
			lda	#$00
::101			cmp	#$07
			bcc	:102
			lda	#$06
::102			sta	V1062e1 +0

			lda	V1062d0  +6		;Jahr.
			jsr	BCDtoDEZ
			sta	V1062e1 +1

			lda	V1062d0  +4		;Monat.
			jsr	BCDtoDEZ
			sta	V1062e1 +2

			lda	V1062d0  +3		;Tag.
			jsr	BCDtoDEZ
			sta	V1062e1 +3

			lda	V1062d0  +2		;Stunde.
			jsr	SM_ConvHour1
			sta	V1062e1 +4
			stx	V1062e1 +7

			lda	V1062d0  +1		;Minute.
			jsr	BCDtoDEZ
			sta	V1062e1 +5

			lda	V1062d0  +0		;Sekunde.
			jsr	BCDtoDEZ
			sta	V1062e1 +6

			LoadB	V1062e1 +8,$0d

			ldx	#$00
::103			jmp	DoneWithIO

;*** SmartMouse-Zeitsystem korrigieren.
:SM_ConvHour1		cmp	#%10000000
			bcc	:101
			pha
			and	#%00100000
			tax
			pla
			and	#%00011111
			jmp	BCDtoDEZ

::101			and	#%00111111
			jsr	BCDtoDEZ
			ldx	#$00
			rts

			ldx	#$00
			cmp	#12
			bcc	:102
			dex
			rts

::102			cmp	#$00
			bne	:103
			lda	#12
::103			rts

;*** GEOS-Uhrzeit auf Bildschirm.
:DoClockGEOS		LoadW	r0,V1062f0		;Uhrzeit-Prozess aktivieren.
			lda	#1
			jsr	InitProcesses
			ldx	#0
			jsr	RestartProcess
			ldx	#0
			jmp	EnableProcess

;*** GEOS-Uhrzeit ausgeben.
:ShowGEOS_DT		php
			sei
			ldx	#$05			;GEOS-Uhrzeit in
::101			lda	year,x			;Zwischenspeicher kopieren.
			sta	V1062e3+1,x
			dex
			bpl	:101
			plp

;*** Uhrzeit aus Zwischenspeicher ausgeben.
:Show_DT		jsr	UseGDFont
			ClrB	currentMode

			jsr	ShowNewWDay

			LoadW	r11,$0074
			LoadB	r1H,$66

			lda	V1062e3+3
			jsr	PrintNum
			lda	#"."
			jsr	SmallPutChar
			lda	V1062e3+2		;Monat.
			jsr	PrintNum
			lda	#"."
			jsr	SmallPutChar
			lda	V1062e3+1		;Jahr.
			jsr	PrintNum

			LoadW	r11,$0074
			LoadB	r1H,$7e

			lda	V1062e3+4		;Stunde.
			jsr	PrintNum
			lda	#":"
			jsr	SmallPutChar
			lda	V1062e3+5		;Minute.
			jsr	PrintNum
			lda	#"."
			jsr	SmallPutChar
			lda	V1062e3+6		;Sekunde.

;*** Zahl ausgeben.
:PrintNum		jsr	DEZtoASCII
			pha
			txa
			jsr	SmallPutChar
			pla
			jmp	SmallPutChar

;*** Wochentag anzeigen.
:ShowNewWDay		lda	V1062c0			;Kein RTC-Drive,
			bne	:101
			rts

::101			lda	V1062e3+0
			cmp	V1062c2
			beq	:102
			sta	V1062c2

			pha
			FillPRec$00,$48,$4f,$0070,$00cf
			pla

			asl
			tax
			lda	V1062i0+0,x
			sta	r0L
			lda	V1062i0+1,x
			sta	r0H

			LoadW	r11,$0074
			LoadB	r1H,$4e
			jsr	PutString

::102			rts

;*** Neue Uhrzeit eingeben.
:SetNewTime		lda	#$00
			sta	V1062c3
			sta	V1062c1

			lda	mouseOn
			and	#%10011111
			sta	mouseOn

			LoadW	keyVector,InputKey
			LoadW	r0,V1062f1
			lda	#1
			jsr	InitProcesses
			ldx	#0
			jsr	RestartProcess
			ldx	#0
			jmp	EnableProcess

;*** Cursor setzen.
:SetCursor		lda	V1062c3
			eor	#$ff
			sta	V1062c3

			ldx	V1062c1
			lda	V1062g0,x
			sta	r3L
			add	7
			sta	r4L
			lda	#$00
			sta	r3H
			sta	r4H
			lda	V1062g1,x
			sta	r2L
			add	7
			sta	r2H
			jmp	InvertRectangle

;*** Cursor löschen.
:ClrCursor		php
			sei
			bit	V1062c3
			bpl	:101
			jsr	SetCursor
::101			plp
			rts

;*** Abfragemodus starten.
:SM_Setup		php
			sei
			sta	V1062d3
			pla
			sta	V1062d4
			lda	mport
			sta	V1062d1
			lda	mpddr
			sta	V1062d2
			lda	#%11111111
			sta	mport
			lda	#%00001010
			sta	mpddr
			lda	V1062d3
			rts

;*** Abfragemodus beenden.
:SM_Exit		sta	V1062d3
			lda	V1062d1
			sta	mport
			lda	V1062d2
			sta	mpddr
			lda	V1062d4
			pha
			lda	V1062d3
			plp
			rts

;*** Uhrzeit einlesen.
:SM_RdClk		jsr	SM_Setup
			lda	#$bf			;burst rd clk cmd
			jsr	SM_SendCom		;send it
			ldy	#00
::101			jsr	SM_GetByte
			sta	V1062d0,y
			iny
			cpy	#$08
			bcc	:101
			jsr	SM_End1
			jmp	SM_Exit

;*** Uhrzeit speichern.
:SM_WrClk		jsr	SM_Setup
			jsr	SM_SndWP_0		;send SM_WP_off cmd
			lda	#$be			;burst wr clk cmd
			jsr	SM_SendCom		;send it
			ldy	#00
			jsr	SM_Output
::101			lda	V1062d0,y
			jsr	SM_SendByte
			iny
			cpy	#$08
			bcc	:101
			jsr	SM_End1
			jsr	SM_Input
			jsr	SM_SndWP_1		;send SM_WP_on cmd
			jmp	SM_Exit

;*** Schreibschutz ändern.
:SM_SndWP_0		lda	#$00
			b $2c
:SM_SndWP_1		lda	#$80
			pha
			lda	#$8e
			jsr	SM_SendCom
			jsr	SM_Output
			pla
			jsr	SM_Com1
			jmp	SM_End1

;*** Befehl an SmartMouse senden.
:SM_SendCom		pha
			jsr	SM_Init1		;SM_Output
			pla
:SM_Com1		jsr	SM_SendByte
			jmp	SM_Input

;*** Byte von SmartMouse einlesen.
:SM_GetByte		ldx	#08
::101			jsr	SM_Init3
			lda	mport
			lsr
			lsr
			lsr
			ror	V1062d3
			jsr	SM_End2
			dex
			bne	:101
			lda	V1062d3
			rts

;*** Byte an SmartMouse senden.
:SM_SendByte		sta	V1062d3
			ldx	#08
::101			jsr	SM_Init3
			lda	#00
			ror	V1062d3
			rol
			asl
			asl
			ora	#%11110001		;set io bit
			sta	mport
			jsr	SM_End2
			dex
			bne	:101
			rts

;*** Warten bis SMartMouse bereit.
:SM_Init1		jsr	SM_Output
			jsr	SM_Init3
:SM_Init2		lda	#%11110111
			b $2c
:SM_Init3		lda	#%11111101
			and	mport
			sta	mport
			rts

;*** SmartMouse deaktivieren.
:SM_End1		lda	#%00001000
			b $2c
:SM_End2		lda	#%00000010
			ora	mport
			sta	mport
			rts

;*** Datenrichtung bestimmen.
:SM_Output		lda	#%00001110
			b $2c
:SM_Input		lda	#%00001010
			sta	mpddr
			rts

;*** Tasten auswerten.
:InputKey		php
			sei
			lda	keyData
			cmp	#$30
			bcc	CRSR_RIGHT
			cmp	#$3a
			bcs	CRSR_RIGHT
			cmp	#$01
			bne	InputNum
			jmp	BootHelp

;*** Zahl 0-9 eingeben.
:InputNum		jsr	ClrCursor

			ldy	V1062c1
			ldx	V1062g2,y
			lda	V1062e3,x		;Aktuellen Wert einlesen und
			jsr	HEXtoASCII		;in ASCII-Format wandeln.
			ldx	#0
			lda	V1062c1			;Cursor-Position berechnen.
			lsr
			bcc	:101
			inx
::101			lda	keyData			;Neuen Wert in Zwischenspeicher
			sta	r15L,x			;übertragen.

			jsr	ASCIItoHEX		;Zahl nach Hexadezimal wandeln.

			pha
			lda	V1062c1			;Zeiger auf max./min.-Werte
			lsr				;berechnen.
			tax
			pla
			cmp	V1062g3,x		;Neuen Wert mit max. Wert vergleichen.
			beq	:103			;Identisch, weiter...
			bcc	:102			;Kleiner, auf min. Wert testen.
			lda	V1062g3,x		;max. Wert einlesen.
			bne	:103			;Weiter...
::102			cmp	V1062g4,x		;Neuen Wert mit min. Wert vergleichen.
			bcs	:103			;Größer, Wert in Ordnung.
			lda	V1062g4,x
::103			ldy	V1062c1
			ldx	V1062g2,y
			sta	V1062e3,x		;Neuen Wert in Zwischenspeicher.

			jsr	HEXtoASCII		;Zahl nach ASCII wandeln.
			lda	V1062c1
			and	#%11111110
			tax
			lda	V1062g0,x		;X-Koordinate einlesen.
			add	1
			sta	r11L
			ClrB	r11H
			lda	V1062g1,x		;Y-Koordinate einlesen.
			add	6
			sta	r1H

			lda	r15L			;10er-Stelle ausgeben.
			jsr	SmallPutChar
			lda	r15H			;1er-Stelle ausgeben.
			jsr	SmallPutChar
			jmp	i_CRSR_RIGHT		;Cursor um 1 Stelle nach rechts.

;*** "Cursor nach rechts".
:CRSR_RIGHT		cmp	#30
			bne	CRSR_LEFT
			jsr	ClrCursor
:i_CRSR_RIGHT		ldx	V1062c1
			inx
			cpx	#12
			bne	:101
			ldx	#0
::101			stx	V1062c1
			plp
			rts

;*** "Cursor nach links".
:CRSR_LEFT		cmp	#8
			bne	CRSR_DOWN
			jsr	ClrCursor
			ldx	V1062c1
			bne	:101
			ldx	#12
::101			dex
			stx	V1062c1
			plp
			rts

;*** "Wochentag +1".
:CRSR_DOWN		cmp	#17
			bne	CRSR_UP
			ldx	V1062e3
			inx
			cpx	#7
			bne	:101
			ldx	#0
::101			stx	V1062e3
			jsr	ShowNewWDay
			plp
			rts

;*** "Wochentag -1".
:CRSR_UP		cmp	#16
			bne	RETURN_KEY
			ldx	V1062e3
			bne	:101
			ldx	#7
::101			dex
			stx	V1062e3
			jsr	ShowNewWDay
			plp
			rts

;*** RETURN: Uhrzeit übernehmen.
:RETURN_KEY		cmp	#13
			beq	:101
			plp
			rts

::101			plp

			jsr	ClrCursor

			lda	mouseOn
			ora	#%00100000
			sta	mouseOn

;*** Neue Uhrzeit setzen.
:SetCPUtime		jsr	InitForIO		;I/O aktivieren.

			ldx	#$05			;Werte aus Zwischenspeicher in
::101			lda	V1062e3+1,x		;GEOS-Datumspeicher kopieren.
			sta	year,x
			dex
			bpl	:101

			lda	V1062e3+4		;Stunde nach BCD wandeln.
			jsr	DEZtoBCD
			sed				;AM/PM-Flag berechnen.
			cmp	#$13
			bcc	:102
			sbc	#$12
			ora	#%10000000
::102			tax
			and	#%10000000
			sta	r0L
			lda	$dc0b
			ldy	$dc08
			txa
			sta	$dc0b			;Stunde setzen.
			cld
			lda	V1062e3+5
			jsr	DEZtoBCD		;Minute nach BCD wandeln.
			sta	$dc0a			;Minute setzen.
			lda	V1062e3+6
			jsr	DEZtoBCD		;Sekunde nach BCD wandeln.
			sta	$dc09			;Sekunde setzen.
			ClrB	$dc08
			jsr	DoneWithIO		;I/O abschalten.
			jmp	DoClockGEOS		;Neue Uhrzeit anzeigen.

;*** Dezimal nach BCD.
:DEZtoBCD		ldx	#0
::101			cmp	#10
			bcc	:102
			inx
			sbc	#10
			bcs	:101
::102			sta	r0L
			txa
			asl
			asl
			asl
			asl
			ora	r0L
			rts

;*** BCD nach Dezimal wandeln.
:BCDtoDEZ		pha
			and	#%11110000
			lsr
			lsr
			lsr
			lsr
			tay
			lda	#$00
			cpy	#$00
			beq	:102
::101			add	10
			dey
			bne	:101
::102			sta	r0L
			pla
			and	#%00001111
			adda	r0L
			rts

;*** DEZ nach ASCII.
:DEZtoASCII		ldx	#"0"
::101			cmp	#10
			bcc	:102
			inx
			sbc	#10
			bcs	:101
::102			adc	#"0"
			rts

;*** HEX nach ASCII wandeln.
:HEXtoASCII		ldx	#$30
::101			cmp	#10
			bcc	:102
			inx
			sbc	#10
			bcs	:101
::102			adc	#$30
			stx	r15L
			sta	r15H
			rts

;*** ASCII nach HEX wandeln.
:ASCIItoHEX		lda	r15L
			sub	$30
			tax
			lda	r15H
			sub	$30
			tay
			lda	#0
::101			cpx	#0
			beq	:102
			add	10
			dex
			bne	:101
::102			cpy	#0
			beq	:103
			add	1
			dey
			bne	:102
::103			rts

;*** Name der Hilfedatei.
:HelpFileName		b "08,GDH_System",NULL

;*** Menüicons.
:V1062a0		b $04
			w $0000
			b $00

			w Icon_00
			b $00,$08,$05,$18
			w L1062ExitGD

			w Icon_03
			b $05,$08,$05,$18
			w SetNewTime

			w Icon_01
			b $0a,$08,$05,$18
			w SetAllRTCs

			w Icon_02
			b $0f,$08,$05,$18
			w ReadDrvRTC

if Sprache = Deutsch
;*** Titelzeile.
:V1062b0		b PLAINTEXT
			b "GEOS-Uhrzeit & CMD Real-Time-Clock",NULL
endif

if Sprache = Englisch
;*** Titelzeile.
:V1062b0		b PLAINTEXT
			b "GEOS-time & CMD Real-Time-Clock",NULL
endif

;*** Variablen.
:V1062c0		b $00				;Anzahl RTC-Uhren.
:V1062c1		b $00				;Cursor-Position.
:V1062c2		b $00				;Aktueller Wochentag.
:V1062c3		b $00				;$FF = Cursor ist sichtbar.
:V1062c4		b $00				;Adr. RTC-Uhr.

;*** SmartMouse-Zwischenspeicher.
:V1062d0		s $08				;Uhrzeit-Daten.
:V1062d1		b $00
:V1062d2		b $00
:V1062d3		b $00
:V1062d4		b $00

;*** RTC-Uhr-Befehle.
:V1062e0		b "T-RD"
:V1062e1		s $09
:V1062e2		b "T-WD"
:V1062e3		b $00,$00,$00,$00,$00,$00,$00,$00,$0d
:V1062e4		s $09

;*** Prozess-Tabellen.
:V1062f0		w ShowGEOS_DT
			w 20
:V1062f1		w SetCursor
			w 10

;*** Parameter für Eingabefelder.
:V1062g0		b $73,$7a,$88,$8f,$9d,$a4
			b $73,$7a,$88,$8f,$9d,$a4
:V1062g1		b $60,$60,$60,$60,$60,$60
			b $78,$78,$78,$78,$78,$78
:V1062g2		b   3,  3,  2,  2,  1,  1
			b   4,  4,  5,  5,  6,  6
:V1062g3		b  31, 12, 99, 23, 59, 59
:V1062g4		b   1,  1,  0,  0,  0,  0

if Sprache = Deutsch
;*** Bildschirmtexte.
:V1062h0		b PLAINTEXT
			b GOTOXY
			w $0020
			b $4e
			b "Wochentag:"
			b NULL

:V1062h1		b PLAINTEXT
			b GOTOXY
			w $000c
			b $36
			b "GEOS-Uhrzeit"
			b GOTOXY
			w $0020
			b $66
			b "Datum    :"
			b GOTOXY
			w $0020
			b $7e
			b "Uhrzeit  :"
			b GOTOXY
			w $0008
			b $c4
			b "Aktuelle GEOS-Uhrzeit"
			b NULL

;*** Klartexte für Wochentage.
:V1062i0		w V1062j0
			w V1062j1
			w V1062j2
			w V1062j3
			w V1062j4
			w V1062j5
			w V1062j6

:V1062j0		b "Sonntag",NULL
:V1062j1		b "Montag",NULL
:V1062j2		b "Dienstag",NULL
:V1062j3		b "Mittwoch",NULL
:V1062j4		b "Donnerstag",NULL
:V1062j5		b "Freitag",NULL
:V1062j6		b "Samstag",NULL

;*** Infoboxen.
:V1062k0		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Suche Echtzeituhren..."
:V1062k1		b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Laufwerk: "
			b NULL

:V1062k2		b PLAINTEXT
			b GOTOXY
			w $0020
			b $93
			b "Uhrzeit wurde eingelesen aus"
			b GOTOXY
			w $0020
			b $9e
			b "CMD SmartMouse"
			b NULL

:V1062k3		b PLAINTEXT
			b GOTOXY
			w $0020
			b $93
			b "Uhrzeit wurde eingelesen aus"
			b GOTOXY
			w $0020
			b $9e
			b "Laufwerk: "
			b NULL
endif

if Sprache = Englisch
;*** Bildschirmtexte.
:V1062h0		b PLAINTEXT
			b GOTOXY
			w $0020
			b $4e
			b "Day       :"
			b NULL

:V1062h1		b PLAINTEXT
			b GOTOXY
			w $000c
			b $36
			b "GEOS-time"
			b GOTOXY
			w $0020
			b $66
			b "Date     :"
			b GOTOXY
			w $0020
			b $7e
			b "Time     :"
			b GOTOXY
			w $0008
			b $c4
			b "Current GEOS-time"
			b NULL

;*** Klartexte für Wochentage.
:V1062i0		w V1062j0
			w V1062j1
			w V1062j2
			w V1062j3
			w V1062j4
			w V1062j5
			w V1062j6

:V1062j0		b "Sunday",NULL
:V1062j1		b "Monday",NULL
:V1062j2		b "Tuesday",NULL
:V1062j3		b "Wednesday",NULL
:V1062j4		b "Thursday",NULL
:V1062j5		b "Friday",NULL
:V1062j6		b "Saturday",NULL

;*** Infoboxen.
:V1062k0		b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for RTC..."
:V1062k1		b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Device: "
			b NULL

:V1062k2		b PLAINTEXT
			b GOTOXY
			w $0020
			b $93
			b "GEOS-time updated from"
			b GOTOXY
			w $0020
			b $9e
			b "CMD SmartMouse"
			b NULL

:V1062k3		b PLAINTEXT
			b GOTOXY
			w $0020
			b $93
			b "GEOS-time updated from"
			b GOTOXY
			w $0020
			b $9e
			b "Drive : "
			b NULL
endif

;*** Icons.
if Sprache = Deutsch
:Icon_00
<MISSING_IMAGE_DATA>

:Icon_01
<MISSING_IMAGE_DATA>

:Icon_02
<MISSING_IMAGE_DATA>

:Icon_03
<MISSING_IMAGE_DATA>

endif

if Sprache = Englisch
:Icon_00
<MISSING_IMAGE_DATA>

:Icon_01
<MISSING_IMAGE_DATA>

:Icon_02
<MISSING_IMAGE_DATA>

:Icon_03
<MISSING_IMAGE_DATA>

endif
