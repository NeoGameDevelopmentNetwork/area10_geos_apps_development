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
endif

			n	"mod.#103.obj"
			o	DrvSlctBase
			r	EndAreaCBM

;*** L103: Source & Target-Drive wählen.
;    xReg = Source-Typ ($00=CBM, $FF=DOS)
;    yReg = Target-Typ ($00=CBM, $FF=DOS)
;    AKKU = Schreibschutz/Laufwerkswahl.
;           %1xxxxxxx Schreibschutz Target-Drive.
;           %x1xxxxxx Schreibschutz Source-Drive.
;           %xx1xxxxx Source & Target dürfen identisch sein.
;           %xxx1xxxx Nur BASIC-Kompatible Laufwerke wählen.
;           %xxxx1xxx Kein CopyScrap darstellen.
;           %xxxxx1xx CMD-NativeMode-Laufwerke.
;--- Ergänzung: 22.11.18/M.Kanet
;Für bestimmte Routinen auch "Nicht-CMD"-Laufwerke für
;NativeMode erlauben (Verzeichnis erstellen/löschen/wechseln).
;           %xxxxxx1x NativeMode-Laufwerke (RAMNative, SD2IEC).
;           %xxxxxxx0 Nur Action-Drive wählen.
;           %xxxxxxx1 Source- & Target-Drive wählen.

:Pos0x			= 40
:Pos0y			= 56

:Icon0x			= Pos0x+ 64
:IconAx			= Pos0x+ 16
:IconBx			= Pos0x+ 56
:IconCx			= Pos0x+ 96
:IconDx			= Pos0x+136
:Icon0y			= Pos0y+ 32
:IconSy			= Pos0y+  0
:IconTy			= Pos0y+ 72

;*** Parameter speichern.
:GetSTDrive		stx	DrvTypS			;Laufwerks-Typ Source.
			sty	DrvTypT			;Laufwerks-Typ Target.

			tsx
			stx	StackPointer

			ldx	#$07			;Parameter speichern.
;--- Ergänzung: 22.11.18/M.Kanet
;Fehlerbeseitigung:
;Im Original-Code von 1997 wurde bei jedem Aufruf ein weiteres Bit
;zu den Optionsspeichern hinzugefügt da die Optionen zuvor nicht
;initialisiert/gelöscht werden. Umm Probleme beim Abfragen dieser
;Optionen zu vermeiden wurde der Code auf LDA/STA umgestellt.
::101			lsr
;			ror	V103a10,x		;Falsch! %10000000 -> +%1 -> %11000000.
			pha
			bcs	:102
			lda	#%00000000
			b $2c
::102			lda	#%10000000
			sta	V103a10,x
			pla
			dex
			bpl	:101

			MoveB	Source_Drv,DrvNumS
			MoveB	Target_Drv,DrvNumT

;*** Native-Laufwerk wählen ?
			jsr	IsNativeOK		;Nur Rückkehr, falls Native vorhanden.

;*** Laufwersanzahl prüfen.
:CheckForDrv		bit	V103a17			;Source/Target wählen ?
			bpl	:101			;Nein, weiter...
			bit	V103a12			;Identische Laufwerke möglich ?
			bmi	:101			;Ja, weiter...

			CmpBI	CBM_Count,2		;Mehr als 1 Laufwerk ?
			bcs	:101			;Ja, weiter...

			jmp	ErrCode_6		;Fehler: "Nur 1 Laufwerk!".

::101			bit	DrvTypS			;DOS-Laufwerk wählen ?
			bmi	:102
			bit	DrvTypT
			bpl	:105

::102			CmpBI	DOS_Count,1		;DOS-Laufwerk verfügbar ?
			bcs	:103			;Ja, weiter...

			jmp	ErrCode_5		;Fehler: "Kein DOS-Laufwerk!".

::103			ldx	#8			;DOS-Laufwerk suchen.
			jsr	FindDOSdrv

			bit	DrvTypS			;Vorgabe DOS-Laufwerk für
			bpl	:104			;Source/Target-Laufwerk ermitteln.

			stx	DrvNumS
			bmi	:105

::104			stx	DrvNumT

;*** Suche nach CBM-Laufwerk.
::105			CmpBI	CBM_Count,1		;Nur ein CBM-Laufwerk vorhanden ?
			bne	GetNumDrv		;Nein, Laufwerk wählen.

			ldx	#8			;CBM-Laufwerk suchen und als
			jsr	FindCBMdrv		;Vorgabe für Source/Target wählen.
			stx	DrvNumS
			stx	DrvNumT

;*** Anzahl Laufwerke ermitteln.
:GetNumDrv		bit	V103a17			;Source/Target wählen ?
			bmi	:103			;Ja, weiter...
			bit	DrvTypT			;Ziel-Laufwerk = DOS ?
			bmi	:102			;Ja, weiter...

			bit	TempTrgtMode		;Vorgabe übernehmen ?
			bmi	:101			;Ja, weiter...

			CmpBI	CBM_Count,1		;Mehr als 1 CBM-Laufwerk ?
			bne	DoDrvBox		;Ja, Laufwerk wählen.
::101			jmp	IsDrvT_OK		;Vorgabe CBM-Laufwerk automatisch

::102			CmpBI	DOS_Count,1		;Mehr als 1 DOS-Laufwerk ?
			bne	DoDrvBox		;Ja, Laufwerk wählen.
			jmp	IsDrvT_OK		;Vorgabe DOS-Laufwerk automatisch
							;als Ziel-Laufwerk übernehmen.

::103			CmpBI	CBM_Count,1		;Source/Target wählen. Nur ein
			bne	DoDrvBox		;Laufwerk verfügbar ? Nein, wählen.
			jmp	IsDrvS_OK		;Ja, Vorgabe testen.#

;*** Laufwerksauswahl.
:DoDrvBox		Display	ST_WR_FORE
			LoadW	r0,V103c0		;Laufwerk wählen.
			DB_RecBoxL103RVec
			tsx
			stx	StackPointer
			lda	sysDBData
			bmi	:51
			cmp	#$01
			beq	IsDrvS_OK
			ldx	#$ff			;Abbruch...
			rts

::51			lda	HelpVector +0
			ldx	HelpVector +1
			jmp	CallRoutine

;*** Hilfe starten.
:StartHelp		lda	keyData
			cmp	#CR
			bne	:51
			lda	#$01
			b $2c
::51			lda	#$ff
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Online-Hilfe installieren.
:InitSlctHelp		LoadW	r0,HelpFileName
			LoadW	keyVector,$0000
			lda	#<DoDrvBox
			ldx	#>DoDrvBox
			jsr	InstallHelp

			lda	keyVector  +0
			sta	HelpVector +0
			lda	keyVector  +1
			sta	HelpVector +1
			LoadW	keyVector,StartHelp
			rts

;*** Source-Drive testen.
:IsDrvS_OK		bit	V103a17			;Quell-Laufwerk wählen ?
			bpl	IsDrvT_OK		;Nein, weiter...

			lda	DrvNumS
			jsr	TestDrive		;Laufwerk verfügbar ?
			bne	DoDrvBoxAgain		;Nein, anderes Laufwerk wählen.

			lda	DrvNumS
			jsr	TstBASICDrv		;BASIC-Laufwerk ?
			bne	DoDrvBoxAgain		;Nein, anderes Laufwerk wählen.

			ldx	DrvTypS			;DOS-Drive wählen ?
			beq	:101			;Nein, weiter...
			lda	DrvNumS
			jsr	TstDOSDrv		;Laufwerk = DOS-Laufwerk ?
			bne	DoDrvBoxAgain		;Nein, anderes Laufwerk wählen.

::101			bit	V103a11			;Schreibschutz testen ?
			bpl	IsDrvT_OK		;Nein, weiter...

			lda	DrvNumS
			jsr	GetWrProt		;Diskette schreibgeschützt ?
			beq	IsDrvT_OK
:DoDrvBoxAgain		jmp	DoDrvBox		;Ja, anderes Laufwerk wählen.

;*** Target-Drive Testen.
:IsDrvT_OK		lda	DrvNumT
			jsr	TestDrive		;Laufwerk verfügbar ?
			bne	DoDrvBoxAgain		;Nein, anderes Laufwerk wählen.

			lda	DrvNumT
			jsr	TstBASICDrv		;BASIC-Laufwerk ?
			bne	DoDrvBoxAgain		;Nein, anderes Laufwerk wählen.

			ldx	DrvTypT			;DOS-Drive wählen ?
			beq	:101			;Nein, weiter...
			lda	DrvNumT
			jsr	TstDOSDrv		;Laufwerk = DOS-Laufwerk ?
			bne	DoDrvBoxAgain		;Nein, anderes Laufwerk wählen.

::101			bit	V103a10			;Schreibschutz testen ?
			bpl	IsConfig_OK		;Nein, weiter...

			lda	DrvNumT
			jsr	GetWrProt		;Diskette schreibgeschützt ?
			beq	IsConfig_OK		;Ja, anderes Laufwerk wählen.
			ldx	#$ff			;Abbruch...
			rts

;*** Konfiguration testen.
:IsConfig_OK		lda	DrvNumT
			bit	V103a17
			bpl	:101
			bit	V103a12			;Identische Laufwerke möglich ?
			bmi	:101			;Ja, keine Überprüfung.
			cmp	DrvNumS			;Beide gleich ?
			bne	:101			;Nein, weiter...
			jsr	WrongConfig		;Fehler, Source & Target gleich.
			jmp	DoDrvBox

::101			sta	Target_Drv
			ldx	DrvNumS
			stx	Source_Drv
			ldx	#$00
			stx	TempTrgtMode
			jmp	NewDrive		;Laufwerk aktivieren.

;*** NativeMode-Laufwerk wählen ?
;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für RAMNative/SD2IEC als NativeMode ergänzt.
:IsNativeOK		bit	V103a16			;RAMNative/SD2IEC?
			bmi	:102			; => Ja, weiter...
			bit	V103a15			;CMD-Native?
			bmi	:102			; => Ja, weiter...
::101			rts				;Ende, Kein NativeMode.

::102			ldx	#8
::103			lda	DriveModes-8,x
;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für RAMNative/SD2IEC als NativeMode ergänzt.
			bit	V103a16			;RAMNative/SD2IEC?
			bmi	:103b			; => Ja, weiter...
			cmp	#%10000000		;CMD-Laufwerk ?
			bcc	:103a			; => Nein, weiter...
::103b			and	#%00100000		;NativeMode ?
			bne	:104			; => Ja, weiter...
::103a			inx
			cpx	#12
			bne	:103

			jmp	ErrCode_7		;Fehler: "Kein NATIVE-Laufwerk!"

::104			ldy	DrvNumT
			lda	DriveModes-8,y
			and	#%00100000
			bne	:105
			stx	DrvNumT
::105			rts

;*** Farben zurücksetzen.
:L103RVec		jsr	i_C_ColorClr
			b	$00,$00,$28,$17
			FillPRec$00,$20,$9f,$28,$0117
			rts

;*** Window beenden.
:L103ExitW_a		lda	#$02
			b $2c
:L103ExitW_b		lda	#$01
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Grafik auf Bildschirm.
:PutGrafik		jsr	i_C_MenuBack
			b	$05,$04,$1e,$10
			jsr	i_C_MenuTitel
			b	$05,$04,$1e,$01

			FillPRec$00,$20,$27,$0028,$0117

if Sprache = Deutsch
			jsr	UseGDFont
			Print	$0038,$26
			b	PLAINTEXT,"Laufwerk wählen",NULL
endif

if Sprache = Englisch
			jsr	UseGDFont
			Print	$0038,$26
			b	PLAINTEXT,"Select drive",NULL
endif

			LoadW	r0,C64			;C64-Icon ausgeben.
			LoadB	r1L,Icon0x/8
			LoadB	r1H,Icon0y
			LoadB	r2L,C64_x
			LoadB	r2H,C64_y
			jsr	BitmapUp

			jsr	i_ColorBox
			b	Icon0x/8,Icon0y/8,C64_x,C64_y/8,$01

			bit	V103a17			;Source/Target wählen ?
			bpl	:101			;Nein, weiter...
			bit	V103a14			;"Copy-Scrap" ausgeben ?
			bmi	:101			;Nein, weiter...

			LoadW	r0,CopyInfo
			LoadB	r1L,Icon0x / 8 +14
			LoadB	r1H,Icon0y     - 4
			LoadB	r2L,CopyInfo_x
			LoadB	r2H,CopyInfo_y
			jsr	BitmapUp

::101			bit	V103a17			;Source/Target wählen ?
			bpl	:102			;Nein, weiter...

			LoadW	r0,V103d0
			jsr	GraphicsString
			ldx	#Pos0y			;Quell-Laufwerke ausgeben.
			ldy	DrvTypS
			lda	#$00
			jsr	IconOnScreen

::102			LoadW	r0,V103d1
			jsr	GraphicsString
			ldx	#Pos0y+72		;Ziel-Laufwerke ausgeben.
			ldy	DrvTypT
			lda	#$01
			jsr	IconOnScreen

			bit	V103a17			;Source/Target wählen ?
			bpl	:105			;Nein, weiter...
			bit	V103a12			;Dürfen Source & Target gleich sein ?
			bmi	:104			;Ja, weiter...

			lda	DrvNumS
			cmp	DrvNumT			;Source & Target gleich ?
			bne	:104			;Nein, weiter...
			tax
			ldy	#$00
			jsr	GetNewDrv		;Neues Quell-Laufwerk wählen.
			beq	:103			;Gefunden ? Ja, weiter...

			lda	V103a4+0		;Neues Quell-Laufwerk wählen.
			ldx	V103a4+1
			ldy	#$ff
			jsr	GetNewDrv

::103			lda	V103a4+0		;Vorgabelaufwerk für Source/Target
			sta	DrvNumS			;in Zwischenspeicher für Laufwerks-
			lda	V103a4+1		;auswahl übertragen.
			sta	DrvNumT

::104			jsr	Source_Line		;Verbindungslinien zeichen.
::105			jsr	Target_Line

::106			MseXYPos220,60
			jsr	i_C_MenuDIcon
			b	$1b,$07,$06,$02
			jsr	i_C_MenuDIcon
			b	$1b,$10,$06,$02

			ldx	#"1"
			ldy	#"0"
			lda	V103a17
			beq	:107
			ldx	#"1"
			ldy	#"1"
::107			stx	HelpFileName+0
			sty	HelpFileName+1
			jmp	InitSlctHelp

;*** Icon-Daten kopieren.
:IconOnScreen		stx	V103a1			;Y-Koordinate für Icons.
			sty	V103a2			;Nur DOS-Laufwerke anzeigen ?
			sta	V103a3			;Source/Target.

			lda	#$00
::101			pha
			tax

			lda	IconXPos,x		;X/Y-Koordinate für Laufwerks-
			sta	r1L			;Icon definieren.
			lda	V103a1
			sta	r1H

			jsr	SetStdDrv

;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für RAMNative/SD2IEC als NativeMode ergänzt.
			bit	V103a16			;SD2IEC/RAMNative-Laufwerk wählen ?
			bmi	:101a			;Ja, Laufwerk testen...
			bit	V103a15			;NativeMode-Laufwerk wählen ?
			bpl	:102			;Nein, weiter...

::101a			pla
			pha
			tax
			lda	DriveModes,x
			bit	V103a16			;SD2IEC/RAMNative-Laufwerk?
			bmi	:101b			;Ja, Laufwerk testen...
			cmp	#%10000000		;CMD-Laufwerk?
			bcc	:103			;Nein, Laufwerk ungültig...
::101b			and	#%00100000		;NativeMode ?
			beq	:103			;Nein, Laufwerk ungültig...

::102			bit	V103a2			;DOS-Laufwerk wählen ?
			bpl	:104			;Nein, weiter...

			pla
			pha
			tax
			lda	DriveModes,x
			and	#%00010000		;Aktuelles Laufwerk = DOS-Kompatibel ?
			bne	:104			;Ja, weiter...

::103			jsr	SetRedDrv		;Laufwerk nicht verfügbar!
			lda	#$00
			beq	:105

::104			pla
			pha
			tax
			lda	DriveTypes,x		;Laufwerkstyp einlesen. Verfügbar ?
			beq	:103			;Nein -> Sonderbehandlung.
::105			asl
			asl
			tay
			lda	IconType+0,y		;Startadresse Icon-Daten.
			sta	r0L
			lda	IconType+1,y
			sta	r0H
			lda	IconType+2,y		;Abmessungen der Icon-Grafik.
			sta	r2L
			lda	IconType+3,y
			sta	r2H

			jsr	BitmapUp		;Grafik auf Bildschirm.

			pla
			add	1			;Laufwerk 1-4 darstellen.
			cmp	#4
			bne	:101

			ldy	V103a3
			lda	DrvTypS,y
			beq	:106
			ldx	DrvNumS,y		;DOS-Laufwerk in Tabelle belegen.
			jsr	FindDOSdrv
			txa
			ldy	V103a3
			sta	DrvNumS,y
::106			rts

;*** Farbe für Icon setzen.
:SetRedDrv		lda	#$21
			b $2c
:SetStdDrv		lda	#$01
			pha
			jsr	DefIconArea
			pla
			sta	r7L
			jmp	RecColorBox

:DefIconArea		ldx	#$07
			CmpBI	V103a1,Pos0y
			beq	:101
			ldx	#$10
::101			stx	r5H
			lda	r1L
			sta	r5L
			LoadB	r6L,$03
			LoadB	r6H,$02
			rts

;*** Laufwerks-Icon wurde angelickt.
:SelectDrive		ClrB	V103a0
::101			lda	V103a0
			asl
			asl
			asl
			tax
			ldy	#$00
::102			lda	IconRegions,x
			sta	r2L,y
			inx
			iny
			cpy	#$06
			bne	:102

			php				;Prüfen ob Maus auf
			sei				;aktivem Icon (Nr. in ":V103a0")
			jsr	IsMseInRegion
			plp
			tax
			bne	ClkOnSDrv

			inc	V103a0
			lda	V103a0
			cmp	#$09
			bne	:101

;*** Mausklick beenden.
:NoClick		NoMseKey
			rts

;*** Mausklick auf Quell-Laufwerk ?
:ClkOnSDrv		lda	V103a0			;Klick auf C64-Icon ignorieren.
			beq	NoClick
			cmp	#$05			;Klick auf Source-Drive ?
			bcs	ClkOnTDrv		;Nein, Target-Drive angeklickt.

			bit	V103a17			;Auswahl Source-Drive erlaubt ?
			bpl	:103			;Nein, Mausklick ignorieren.

			add	$07
			tax

			lda	DriveTypes-8,x		;Laufwerk verfügbar ?
			beq	:103			;Nein, Abbruch.

;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für RAMNative/SD2IEC als NativeMode ergänzt.
			bit	V103a16			;SD2IEC/RAMNative-Laufwerk ?
			bmi	:101a			;Ja, Laufwerk testen...
			bit	V103a15			;NativeMode-Laufwerk ?
			bpl	:101			;Nein, weiter...

::101a			lda	DriveModes-8,x
			bit	V103a16			;SD2IEC/RAMNative-Laufwerk ?
			bmi	:101b			;Ja, Laufwerk testen...
			cmp	#%10000000		;CMD-Laufwerk ?
			bcc	:103			;Nein, Abbruch.
::101b			and	#%00100000		;Ist Laufwerk = NATIVE ?
			beq	:103			;Nein, Abbruch.

::101			bit	DrvTypS			;DOS-Laufwerk wählen ?
			bpl	:102			;Nein, weiter...

			lda	DriveModes-8,x
			and	#%00010000		;Ist Laufwerk = DOS ?
			beq	:103			;Nein, Abbruch.

::102			txa
			ldx	DrvNumT
			ldy	#$ff
			jmp	SetNewDrv		;Neues Source-Drive setzen.

::103			jmp	NoClick

;*** Mausklick auf Ziel-Laufwerk ?
:ClkOnTDrv		add	$03
			tax

			lda	DriveTypes-8,x		;Laufwerk verfügbar ?
			beq	:104

;--- Ergänzung: 22.11.18/M.Kanet
;Unterstützung für RAMNative/SD2IEC als NativeMode ergänzt.
			bit	V103a16			;SD2IEC/RAMNative-Laufwerk ?
			bmi	:101a			;Ja, Laufwerk testen...
			bit	V103a15			;NATIVE-Laufwerk wählen ?
			bpl	:101			;Nein, weiter...

::101a			lda	DriveModes-8,x
			bit	V103a16			;NativeMode-Laufwerk ?
			bmi	:101b			;Nein, weiter...
			cmp	#%10000000		;CMD-Laufwerk ?
			bcc	:104			;Nein, Abbruch.
::101b			and	#%00100000		;Ist Laufwerk = NATIVE ?
			beq	:104			;Nein, Abbruch.

::101			bit	DrvTypT			;DOS-Laufwerk wählen ?
			bpl	:102			;Nein, weiter...

			lda	DriveModes-8,x
			and	#%00010000		;Ist Laufwerk = DOS ?
			beq	:104			;Nein, Abbruch...

::102			bit	V103a17			;Source/Target wählen ?
			bmi	:103			;Ja, Sonderbehandlung.

			stx	DrvNumT			;Laufwerk speichern.
			jsr	Target_Line		;Anzeige aktualisieren.
			jsr	NoClick

			LoadB	sysDBData,1		;Auswahl beenden.
			jmp	RstrFrmDialogue

::103			lda	DrvNumS			;Neues Source/Target-Laufwerk
			ldy	#$00			;anzeigen.
			jsr	SetNewDrv
::104			jmp	NoClick

;*** Neue Laufwerkskonfig anzeigen.
:SetNewDrv		sta	V103a4+0		;Source-Drive.
			stx	V103a4+1		;Target-Drive.
			sty	V103a4+2		;Source/Target ändern.

			bit	V103a12			;Identische Laufwerke möglich ?
			bmi	:101			;Ja, weiter...

			cmp	V103a4+1		;Source/Target identisch ?
			bne	:101			;Nein, weiter...

			jsr	GetNewDrv1		;Neue Kombination ermitteln.
			bne	:103			;Nicht möglich ? Daa abbruch.

::101			lda	V103a4+0		;Neues Source-Drive ?
			cmp	DrvNumS
			beq	:102
			sta	DrvNumS			;Ja, zwischenspeichern.
			jsr	Source_Line		;Anzeige aktualisieren.

::102			lda	V103a4+1		;Neues Target-Drive ?
			cmp	DrvNumT
			beq	:103
			sta	DrvNumT			;Ja, zwischenspeichern.
			jsr	Target_Line		;Anzeige aktualisieren.

::103			rts

;*** Neue Laufwerkskombination vorgeben.
:GetNewDrv		sta	V103a4+0
			stx	V103a4+1
			sty	V103a4+2

:GetNewDrv1		tya				;Source-Drive ändern ?
			bne	:104			;Nein, weiter...

			bit	DrvTypS			;Source = DOS ?
			bmi	:103			;Ja, weiter...

			ldx	V103a4+0		;Neues CBM-Laufwerk suchen.
			jsr	OtherCBMdrv
			cpx	V103a4+0
			beq	:102
			stx	V103a4+0
::101			ldx	#$00
			rts
::102			ldx	#$ff
			rts

::103			ldx	V103a4+0		;Neues DOS-Laufwerk suchen.
			jsr	OtherDOSdrv
			cpx	V103a4+0
			beq	:102
			stx	V103a4+0
			bne	:101

::104			bit	DrvTypT			;Target = DOS ?
			bmi	:105			;Ja, weiter...

			ldx	V103a4+1		;Neues CBM-Laufwerk suchen.
			jsr	OtherCBMdrv
			cpx	V103a4+1
			beq	:102
			stx	V103a4+1
			bne	:101

::105			ldx	V103a4+1		;Neues DOS-Laufwerk suchen.
			jsr	OtherDOSdrv
			cpx	V103a4+1
			beq	:102
			stx	V103a4+1
			bne	:101

;*** Laufwerk testen.
:TestDrive		tax
			lda	DriveTypes-8,x		;Laufwerk verfügbar ?
			beq	:101			;Nein, Abbruch.
			cmp	#Drv_Unknown
			bcs	:101

			txa				;Laufwerk aktivieren.
			jsr	SetDevice
			txa
			bne	:100			;Nein, weiter.

			jsr	PurgeTurbo		;Turbo abschalten und Diskette öffnen.
			jsr	EnterTurbo		;TurboFlags aktualisieren! WICHTIG!
			txa				;Sonst bei 1541 evtl. Laufwerksfehler!
			beq	TestOK

::100			ldx	#$0d			;Laufwerksfehler.
			jmp	DiskError

;*** Fehler: Laufwerk nicht verfügbar!
::101			txa
			add	$39
			sta	V103f0+11
			jmp	ErrCode_1		;Fehler: "Laufwerk nicht verfügbar!"

:TestOK			ldx	#$00			;OK!
			rts

;*** Auf DOS-Laufwerk testen.
:TstDOSDrv		tax
			lda	DriveModes-8,x		;DOS-Kompatibel ?
			and	#%00010000		;Ja, 1581, FD2 oder FD4.
			bne	TestOK
			txa				;Kein DOS-Drive.
			add	$39
			sta	V103f0+11
			jmp	ErrCode_0		;Fehler: "Kein DOS-Laufwerk!"

;*** Auf BASIC-Laufwerk testen.
:TstBASICDrv		tax				;Gewähltes Laufwerk
			bit	V103a13
			bpl	TestOK

			lda	DriveModes-8,x
			and	#%00000100
			bne	TestOK

			txa				;Kein DOS-Drive.
			add	$39
			sta	V103f0+11
			jmp	ErrCode_4		;Fehler: "Kein BASIC-Laufwerk!"

;*** Quell- und Ziel-Laufwerk sind gleich.
:WrongConfig		jmp	ErrCode_3		;Fehler: "Laufwerke identisch!"

;*** Fehlermeldungen.
:ErrCode_0		ldx	#$00			;"Laufwerk nicht DOS-Kompatibel"
			b $2c
:ErrCode_1		ldx	#$04			;"Laufwerk nicht verfügbar"
			b $2c
:ErrCode_2		ldx	#$08			;"Laufwerk ist schreibgeschützt"
			b $2c
:ErrCode_3		ldx	#$0c			;"Source & Target sind gleich"
			b $2c
:ErrCode_4		ldx	#$10			;"Laufwerk nicht BASIC-Kompatibel"
			ldy	#$00
::101			lda	V103e0,x
			sta	V103e1,y
			inx
			iny
			cpy	#$04
			bne	:101

			ldx	StackPointer
			txs

			DB_UsrBoxV103e1
			CmpBI	sysDBData,2		;Neues Laufwerk wählen ?
			beq	:102			;Ja, weiter...
			jmp	DoDrvBox 		;Nein, zurück zum Hauptmenü.
::102			ldx	#$ff
			rts

;*** Fehlermeldungen.
:ErrCode_5		ldx	#$14			;"Kein DOS-Laufwerk vorhanden!"
			b $2c
:ErrCode_6		ldx	#$18			;"Nur ein Laufwerk vorhanden!"
			b $2c
:ErrCode_7		ldx	#$1c			;"Kein NATIVE-Laufwerk vorhanden!"
			ldy	#$00
::101			lda	V103e0,x
			sta	V103e2,y
			inx
			iny
			cpy	#$04
			bne	:101

			ldx	StackPointer
			txs

			DB_CANCELV103e2
			ldx	#$ff
			rts

;*** Schreibschutz testen.
:GetWrProt		tax
			ldy	DriveTypes-8,x
			lda	V103a20,y
			pha
			lda	V103a21,y
			pha
			txa
			jmp	NewDrive

;*** Kein Schreibschutz.
:WrProtOK		ldx	#$00
			rts

;*** Disk ist Schreibgeschützt.
:WrProtErr		lda	curDrive
			add	$39
			sta	V103f4+23
			jmp	ErrCode_2

;*** Schreibschutz bei 1541/1571.
:Wr1541_71		jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO
			CxSend	V103b0
			CxReceiveV103b1
			jsr	DoneWithIO

			lda	V103b1+2
			and	#%00010000
			bne	:101
			jmp	WrProtErr
::101			ldx	#$00
			rts

;*** Schreibschutz bei 1581.
;--- Ergänzung: 23.10.18/M.Kanet
;Sonderbehandlung für SD2IEC:
;Beim SD2IEC ist im 1581-Modus das DOS-Bit gelöscht da das Laufwerk nicht
;mit Job-Queues/-Codes umgehen kann. Daher Schreibschutz wie 64Net testen.
:Wr1581			lda	curDrvMode		;Laufwerksmodus einlesen.
			and	#%00010000		;DOS-Bit gesetzt?
			beq	Wr64Net			; => Nein, SD2IEC... weiter...

			ldx	#$28
			bit	curDrvMode
			bmi	:101
			ldx	#$02
::101			stx	V103b2 +5
			stx	V103b3 +5

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO
			CxSend	V103b2

::102			CxSend	V103b3
			CxReceiveV103b1
			lda	V103b1 +2
			bmi	:102
			pha
			jsr	DoneWithIO
			pla
			cmp	#$02
			bcc	:104
			cmp	#$08
			bne	:103
			jmp	WrProtErr

::103			lda	curDrive
			ldx	#$7f
			jsr	InsertDisk
			cmp	#$01
			beq	Wr1581

			ldx	#$ff
			rts
::104			ldx	#$00
			rts

;*** Schreibschutz bei 64Net/SD2IEC.
:Wr64Net		LoadW	r4,diskBlkBuf
			lda	#$01
			sta	r1L
			sta	r1H
			jsr	GetBlock
			jsr	PutBlock
			cpx	#$26
			bne	:101
			jmp	WrProtErr

::101			ldx	#$00
			rts

;*** DOS-Laufwerk suchen.
:FindDOSdrv		lda	DriveModes-8,x
			and	#%00010000
			beq	OtherDOSdrv
::101			rts

:OtherDOSdrv		ldy	#$03
::101			inx
			cpx	#12
			bcc	:102
			ldx	#8
::102			lda	DriveModes-8,x
			and	#%00010000
			bne	:103
			dey
			bpl	:101

			ldx	#$ff
::103			rts

;*** CBM-Laufwerk suchen.
:FindCBMdrv		lda	DriveTypes-8,x
			beq	OtherCBMdrv
::101			rts

:OtherCBMdrv		ldy	#$03
::101			inx
			cpx	#12
			bcc	:102
			ldx	#8
::102			lda	DriveTypes-8,x
			bne	:103
			dey
			bpl	:101

			ldx	#$ff
::103			rts
;*** Verbindung zwischen C64 und
;    Source-Drive darstellen.
:Source_Line		jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO  ,<IconAx   ,>IconAx   ,IconSy+17
			b	RECTANGLETO,<IconDx+23,>IconDx+23,IconSy+31
			b	NULL

			Pattern	1

			lda	DrvNumS
			jsr	GetDrvXpos1
			LoadB	r2L,IconSy+16
			LoadB	r2H,IconSy+24
			jsr	Rectangle

			lda	DrvNumS
			jsr	GetDrvXpos2
			LoadB	r2L,IconSy+23
			LoadB	r2H,IconSy+25
			jsr	Rectangle

			FillRec	IconSy+24,IconSy+31,Icon0x+23,Icon0x+25
			rts

;*** Verbindung zwischen C64 und
;    Target-Drive darstellen.
:Target_Line		jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO  ,<IconAx   ,>IconAx   ,IconTy-16
			b	RECTANGLETO,<IconDx+23,>IconDx+23,IconTy- 2
			b	NULL

			Pattern	1

			lda	DrvNumT
			jsr	GetDrvXpos1
			LoadB	r2L,IconTy-8
			LoadB	r2H,IconTy-1
			jsr	Rectangle

			lda	DrvNumT
			jsr	GetDrvXpos2
			LoadB	r2L,IconTy-9
			LoadB	r2H,IconTy-7
			jsr	Rectangle

			FillRec	IconTy-16,IconTy-8,Icon0x+23,Icon0x+25
			rts

;*** X-Koordinaten für Verbindungslinien berechnen.
:GetDrvXpos1		sub	$08
			tax
			ldy	DrvLine_x1,x
			dey
			tya
			clc
			sta	r3L
			adc	#$02
			sta	r4L
			lda	#$00
			sta	r3H
			sta	r4H
			rts

:GetDrvXpos2		sub	$08
			tax
			lda	DrvLine_x1,x
			cpx	#$02
			bcs	:101
			sta	r3L
			LoadB	r4L,Icon0x+24
			jmp	:102

::101			sta	r4L
			LoadB	r3L,Icon0x+24

::102			lda	#$00
			sta	r3H
			sta	r4H
			rts

;*** Variablen.
:StackPointer		b $00
:StackBuf1		w $0000
:StackBuf2		w $0000
:HelpVector		w $0000

:HelpFileName		b "10,GDH_Grundlagen",NULL

:DrvTypS		b $00				;Typ Source-Laufwerk.
:DrvTypT		b $00				;Typ Target-Laufwerk.
:DrvNumS		b $00				;Source-Laufwerk.
:DrvNumT		b $00				;Target-Laufwerk.
:V103a0			b $00				;Icon-Zähler für Test-Routine.
:V103a1			b $00				;Zwischenspeicher Icon-Ausgabe.
:V103a2			b $00				;Zwischenspeicher Icon-Ausgabe.
:V103a3			b $00				;$00 = Source, $01 = Target.
:V103a4			s $03				;Neue Laufwerkswahl.

:V103a10		b $00				;$80 = Schreibschutz TargetDrv.
:V103a11		b $00				;$40 = Schreibschutz SourceDrv.
:V103a12		b $00				;$20 = Identische Laufwerke möglich.
:V103a13		b $00				;$10 = BASIC-Kompatibles Laufwerk.
:V103a14		b $00				;$08 = Kein CopyScrap darstellen.
:V103a15		b $00				;$04 = Nur NativeMode-Laufwerke.
:V103a16		b $00				;$02 = unbelegt.
:V103a17		b $00				;$01 = Quell- und Ziellaufwerk.

;*** DriveType-Datentabelle.
:V103a20		b >WrProtOK -1
			b >Wr1541_71-1,>Wr1541_71-1,>Wr1581   -1
			b >WrProtOK -1,>WrProtOK -1,>WrProtOK -1,>WrProtOK -1
			b >WrProtOK -1,>WrProtOK -1,>WrProtOK -1
			b >Wr1581   -1,>Wr1581   -1,>Wr1581   -1
			b >Wr64Net  -1
			b >Wr1581   -1,>Wr1581   -1,>Wr1581   -1
			b >Wr64Net  -1
:V103a21		b <WrProtOK -1
			b <Wr1541_71-1,<Wr1541_71-1,<Wr1581   -1
			b <WrProtOK -1,<WrProtOK -1,<WrProtOK -1,<WrProtOK -1
			b <WrProtOK -1,<WrProtOK -1,<WrProtOK -1
			b <Wr1581   -1,<Wr1581   -1,<Wr1581   -1
			b <Wr64Net  -1
			b <Wr1581   -1,<Wr1581   -1,<Wr1581   -1
			b <Wr64Net  -1

:V103b0			w $0006
			b "M-R",$00,$1c,$01
:V103b1			w $0001
			b $00
:V103b2			w $0007
			b "M-W",$02,$00,$01,$b6
:V103b3			w $0006
			b "M-R",$02,$00,$01

;*** Laufwerksauswahlbox.
:V103c0			b %00100000
			b 32,159
			w 40,279

			b DB_USR_ROUT
			w PutGrafik

			b DBOPVEC
			w SelectDrive

			b OK       , 22, 24
			b CANCEL   , 22, 96

			b NULL

;*** Rahmen für Laufwerk-Icons.
:V103d0			b MOVEPENTO
			w $0037
			b $37
			b FRAME_RECTO
			w $0050
			b $48

			b MOVEPENTO
			w $005f
			b $37
			b FRAME_RECTO
			w $0078
			b $48

			b MOVEPENTO
			w $0087
			b $37
			b FRAME_RECTO
			w $00a0
			b $48

			b MOVEPENTO
			w $00af
			b $37
			b FRAME_RECTO
			w $00c8
			b $48

			b NULL

:V103d1			b MOVEPENTO
			w $0037
			b $7f
			b FRAME_RECTO
			w $0050
			b $90

			b MOVEPENTO
			w $005f
			b $7f
			b FRAME_RECTO
			w $0078
			b $90

			b MOVEPENTO
			w $0087
			b $7f
			b FRAME_RECTO
			w $00a0
			b $90

			b MOVEPENTO
			w $00af
			b $7f
			b FRAME_RECTO
			w $00c8
			b $90

			b NULL

;*** Zeiger auf Fehlermeldung.
:V103e0			w V103f0 ,V103f1		;$00
			w V103f0 ,V103f3		;$04
			w V103f4 ,V103f5		;$08
			w V103f6 ,V103f7		;$0c
			w V103f0 ,V103f9		;$10

			w V103f10,V103f11		;$14
			w V103f12,V103f13		;$18
			w V103f14,V103f11		;$1c

;*** Abbruch-Fehlerbox.
:V103e1			w $ffff,$ffff,ISet_Achtung
			b CANCEL,OK

;*** Abbruch-Fehlerbox.
:V103e2			w $ffff,$ffff,ISet_Achtung

if Sprache = Deutsch
;*** Fehlertexte.
:V103f0			b PLAINTEXT,BOLDON,"Laufwerk x: ist nicht"						,NULL
:V103f1			b 	"DOS-Kompatibel !" ,NULL
:V103f3			b 	"verfügbar !" ,NULL
:V103f4			b PLAINTEXT,BOLDON,"Diskette in Laufwerk x:"						,NULL
:V103f5			b 	"ist schreibgeschützt !" ,NULL
:V103f6			b PLAINTEXT,BOLDON,"Quell- und Ziel-"							,NULL
:V103f7			b 	"Laufwerk sind gleich!" ,NULL
:V103f9			b 	"BASIC-kompatibel!" ,NULL
:V103f10		b PLAINTEXT,BOLDON,"Kein DOS-kompatibles"						,NULL
:V103f11		b 	"Laufwerk verfügbar!" ,NULL
:V103f12		b PLAINTEXT,BOLDON,"Funktion mit nur einem"						,NULL
:V103f13		b 	"Laufwerk nicht möglich!" ,NULL
:V103f14		b PLAINTEXT,BOLDON,"Kein CMD-NativeMode"						,NULL
endif

if Sprache = Englisch
;*** Fehlertexte.
:V103f0			b PLAINTEXT,BOLDON,"Drive    x: is not"							,NULL
:V103f1			b 	"compatible to DOS!" ,NULL
:V103f3			b 	"available !" ,NULL
:V103f4			b PLAINTEXT,BOLDON,"No access -  drive x:"						,NULL
:V103f5			b 	"is write protected !" ,NULL
:V103f6			b PLAINTEXT,BOLDON,"Source- and target-"						,NULL
:V103f7			b 	"drive are identical!" ,NULL
:V103f9			b 	"compatible to BASIC!" ,NULL
:V103f10		b PLAINTEXT,BOLDON,"No DOS-compatible"							,NULL
:V103f11		b 	"diskdrive found!" ,NULL
:V103f12		b PLAINTEXT,BOLDON,"Not possible with only"						,NULL
:V103f13		b 	"one drive installed!" ,NULL
:V103f14		b PLAINTEXT,BOLDON,"No Native-compatible"						,NULL
endif

;*** Adresse, x- & y-Werte der Laufwerk-Icons
:IconType		w NoDrive
			b NoDrive_x,NoDrive_y
::01			w Drive_41
			b Drive_41_x,Drive_41_y
::02			w Drive_71
			b Drive_71_x,Drive_71_y
::03			w Drive_81
			b Drive_81_x,Drive_81_y
::04			w Drive_R41
			b Drive_R41_x,Drive_R41_y
::05			w Drive_R71
			b Drive_R71_x,Drive_R71_y
::06			w Drive_R81
			b Drive_R81_x,Drive_R81_y
::07			w Drive_RDisk
			b Drive_RDisk_x,Drive_RDisk_y
::08			w Drive_RDisk
			b Drive_RDisk_x,Drive_RDisk_y
::09			w Drive_RL
			b Drive_RL_x,Drive_RL_y
::10			w Drive_RD
			b Drive_RD_x,Drive_RD_y
::11			w Drive_FD2
			b Drive_FD2_x,Drive_FD2_y
::12			w Drive_FD4
			b Drive_FD4_x,Drive_FD4_y
::13			w Drive_HD
			b Drive_HD_x,Drive_HD_y
::14			w Drive_64Net
			b Drive_64Net_x,Drive_64Net_y
::15			w Drive_DOS
			b Drive_DOS_x,Drive_DOS_y
::16			w Drive_DOS
			b Drive_DOS_x,Drive_DOS_y
::17			w Drive_DOS
			b Drive_DOS_x,Drive_DOS_y
;---IECBus Native
::18			w Drive_81
			b Drive_81_x,Drive_81_y

;*** x-Position der Laufwerk-Icons.
:IconXPos		b IconAx / 8
			b IconBx / 8
			b IconCx / 8
			b IconDx / 8

;*** Position der Verbindungslinien.
:DrvLine_x1		b IconAx+12
			b IconBx+12
			b IconCx+12
			b IconDx+12

;*** Bereich für Laufwerk-Icons.
:IconRegions		b Pos0y+ 32,Pos0y+ 55
			w Pos0x+ 64,Pos0x+119,NULL
			b IconSy+0,IconSy+15
			w IconAx+0,IconAx+23,NULL
			b IconSy+0,IconSy+15
			w IconBx+0,IconBx+23,NULL
			b IconSy+0,IconSy+15
			w IconCx+0,IconCx+23,NULL
			b IconSy+0,IconSy+15
			w IconDx+0,IconDx+23,NULL
			b IconTy+0,IconTy+15
			w IconAx+0,IconAx+23,NULL
			b IconTy+0,IconTy+15
			w IconBx+0,IconBx+23,NULL
			b IconTy+0,IconTy+15
			w IconCx+0,IconCx+23,NULL
			b IconTy+0,IconTy+15
			w IconDx+0,IconDx+23,NULL

;*** Icons.
:NoDrive
<MISSING_IMAGE_DATA>
:NoDrive_x		= .x
:NoDrive_y		= .y

:Drive_41
<MISSING_IMAGE_DATA>
:Drive_41_x		= .x
:Drive_41_y		= .y

:Drive_71
<MISSING_IMAGE_DATA>
:Drive_71_x		= .x
:Drive_71_y		= .y

:Drive_81
<MISSING_IMAGE_DATA>
:Drive_81_x		= .x
:Drive_81_y		= .y

:Drive_FD2
<MISSING_IMAGE_DATA>
:Drive_FD2_x		= .x
:Drive_FD2_y		= .y

:Drive_FD4
<MISSING_IMAGE_DATA>
:Drive_FD4_x		= .x
:Drive_FD4_y		= .y

:Drive_HD
<MISSING_IMAGE_DATA>
:Drive_HD_x		= .x
:Drive_HD_y		= .y

:Drive_64Net
<MISSING_IMAGE_DATA>
:Drive_64Net_x		= .x
:Drive_64Net_y		= .y

;*** Icons.
:Drive_R41
<MISSING_IMAGE_DATA>
:Drive_R41_x		= .x
:Drive_R41_y		= .y

:Drive_R71
<MISSING_IMAGE_DATA>
:Drive_R71_x		= .x
:Drive_R71_y		= .y

:Drive_R81
<MISSING_IMAGE_DATA>
:Drive_R81_x		= .x
:Drive_R81_y		= .y

:Drive_RDisk
<MISSING_IMAGE_DATA>
:Drive_RDisk_x		= .x
:Drive_RDisk_y		= .y

:Drive_RL
<MISSING_IMAGE_DATA>
:Drive_RL_x		= .x
:Drive_RL_y		= .y

:Drive_RD
<MISSING_IMAGE_DATA>
:Drive_RD_x		= .x
:Drive_RD_y		= .y

:Drive_DOS
<MISSING_IMAGE_DATA>
:Drive_DOS_x		= .x
:Drive_DOS_y		= .y

:C64
<MISSING_IMAGE_DATA>
:C64_x			= .x
:C64_y			= .y

:CopyInfo
<MISSING_IMAGE_DATA>
:CopyInfo_x		= .x
:CopyInfo_y		= .y
