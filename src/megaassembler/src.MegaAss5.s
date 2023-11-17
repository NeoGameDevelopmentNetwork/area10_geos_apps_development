; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;MegaAssembler
;Symboldateien und Fehlerberichte
;als geoWrite-Dateien erstellen.
if .p
			t "TopSym"
			t "TopMac"
			t "src.MegaAss0.ext"
			t "src.MegaAss2.ext"

:MaxLinesOnPage		= $3d
:l6000			= $6000
endif

			n "mod.#5"
			o VLIR_BASE

;*** Initialisierung.
:MainInit		LoadB	dispBufferOn,ST_WR_FORE

			bit	Flag_FatalError
			bpl	Get_GW_Version
			jmp	BackToMenu

;*** geoWrite-Version ermitteln.
;    Dazu Quelltext auf Diskette suchen und Textformat bestimmen.
:Get_GW_Version		lda	Opt_SourceDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadW	r6,SelectedFile
			jsr	FindFile

			lda	dirEntryBuf +$13
			sta	r1L
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			lda	diskBlkBuf +$5a
			sec
			sbc	#$30
			asl
			asl
			asl
			asl
			sta	GW_Version
			lda	diskBlkBuf +$5c
			sec
			sbc	#$30
			ora	GW_Version
			sta	GW_Version

			ldy	#$4d
::1			lda	diskBlkBuf,y
			sta	GW_Header ,y
			iny
			cpy	#$a0
			bne	:1

;*** Fehlerliste erzeugen.
:Save_ErrorFile		lda	ErrCount
			beq	Save_SymbFile

			LoadW	r0,ScreenText1
			jsr	PrintCurJob

			lda	Opt_ErrFileDrive
			ldx	#<ErrFileName
			ldy	#>ErrFileName
			jsr	CreateGW_File

			lda	#$00
			sta	Flag_SymbFileOK
			sta	Flag_ExtSFileOK
			lda	#$ff
			sta	Flag_ErrFileOK
			jmp	BackToMenu

;*** Symboltabelle erzeugen.
:Save_SymbFile		lda	#$00
			sta	Flag_ErrFileOK

			bit	Flag_SymbFileOK
			bpl	:2

			bit	Opt_SymbTab
			bpl	:2

			lda	Vec_EndLabels1   +1
			cmp	Vec_StartLabels1 +1
			bne	:1
			lda	Vec_EndLabels1   +0
			cmp	Vec_StartLabels1 +0
			beq	Save_ExtSymbFile

::1			LoadW	r0,ScreenText2
			jsr	PrintCurJob

			LoadW	Vec_DoJob +1,CreateSymFiles
			LoadB	Flag_LabelType ,$00
			lda	Opt_SymbTabDrive
			ldx	#<SymFileName
			ldy	#>SymFileName
			jsr	CreateGW_File
			lda	#$ff
			b $2c
::2			lda	#$00
			sta	Flag_SymbFileOK

;*** ext. Symboltabelle erzeugen.
:Save_ExtSymbFile	bit	Flag_ExtSFileOK
			bpl	:1

			bit	Opt_ExtSymbTab
			bpl	:1

			LoadW	r0,ScreenText3
			jsr	PrintCurJob

			LoadW	Vec_DoJob +1,CreateSymFiles
			LoadB	Flag_LabelType ,$ff
			lda	Opt_SymbTabDrive
			ldx	#<ExtFileName
			ldy	#>ExtFileName
			jsr	CreateGW_File
			lda	#$ff
			b $2c
::1			lda	#$00
			sta	Flag_ExtSFileOK

;*** Zurück zum MegaAssembler.
:BackToMenu		LoadW	r3,SysVarCode1
			LoadW	r4,$6000
			ldx	#r3L
			ldy	#r4L
			jsr	CopyString

			lda	Opt_BootDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk
			jmp	Mod_Menu

;*** Word als ASCII-Text in Dokument einfügen.
:CreateWordHEX		lda	#"$"
			jsr	AddByteToDok
			jmp	CreateCodeHEX

;*** Byte als ASCII-Text in Dokument einfügen.
:CreateByteHEX		lda	#"$"
			jsr	AddByteToDok
			LoadB	r0H,$00

;*** Word oder Byte als ASCII-Text in Dokument einfügen.
:CreateCodeHEX		tya
			pha
			txa
			pha

			lda	r0H
			beq	:1
			lsr
			lsr
			lsr
			lsr
			tay
			lda	DataTab_DEZ_HEX,y
			jsr	AddByteToDok

			lda	r0H
			and	#$0f
			tay
			lda	DataTab_DEZ_HEX,y
			jsr	AddByteToDok

::1			lda	r0L
			lsr
			lsr
			lsr
			lsr
			tay
			lda	DataTab_DEZ_HEX,y
			jsr	AddByteToDok

			lda	r0L
			and	#$0f
			tay
			lda	DataTab_DEZ_HEX,y
			jsr	AddByteToDok

			pla
			tax
			pla
			tay
			rts

;*** Ausgabefenster löschen.
:PrintCurJob		PushW	r0

			lda	#$09
			jsr	SetPattern

			bit	ScreenMode
			bpl	:1

			jsr	i_Rectangle
			b	$00
			b	$0f
			w	$0000
			w	$027f
			jmp	:2

::1			jsr	i_Rectangle
			b	$00
			b	$0f
			w	$0000
			w	$013f

::2			lda	#$0f
			bit	ScreenMode
			bpl	:3
			lda	#$1e
::3			sta	r11L
			lda	#$00
			sta	r11H
			lda	#$0a
			sta	r1H

			PopW	r0
			jmp	PutString

;*** Leeres GW-Dokument erzeugen.
:CreateGW_File		sta	GW_FileDrive
			stx	GW_Header +0
			sty	GW_Header +1

::8			lda	GW_FileDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			MoveW	GW_Header,r6
			jsr	FindFile
			cpx	#$05
			beq	:2
			cpx	#$00
			bne	:1

			MoveW	GW_Header,r0
			jsr	DeleteFile
			jmp	:8

::1			rts

::2			lda	#$00
			sta	r10L
			LoadW	r9,GW_Header
			jsr	SaveFile
			txa
			beq	:4
			rts

;*** Neue GeoWrite-Datei erstellen.
::4			stx	Flag_PageSaved

			MoveW	GW_Header,r0
			jsr	OpenRecordFile
			txa
			beq	:5
			rts

::5			ldx	#$7f
::6			stx	:7 +1
			jsr	AppendRecord
::7			ldx	#$ff
			dex
			bne	:6

			jsr	CloseRecordFile

			lda	#$00
			sta	Poi_CurPage
			jsr	InitNewPage

;*** Daten in geoWrite-Datei schreiben.
:Vec_DoJob		jsr	CreateErrFile

			lda	#$00
			jsr	AddByteToDok
			jsr	SaveTextPage

			lda	Flag_PageSaved
			bne	:1
			rts

::1			lsr
			lsr
			lsr
			lsr
			tay
			lda	DataTab_DEZ_HEX,y
			sta	D01c +10

			lda	Flag_PageSaved
			and	#$0f
			tay
			lda	DataTab_DEZ_HEX,y
			sta	D01c +11

			jsr	i_MoveData
			w	SCREEN_BASE
			w	BACK_SCR_BASE
			w	$1f40

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10,$c7
			w	$0000,$013f

			lda	screencolors
			sta	:2
			jsr	i_FillRam
			w	920
			w	COLOR_MATRIX +2*40
::2			b	$ff

			PushW	RecoverVector
			lda	#$00
			sta	RecoverVector
			sta	RecoverVector +1

			LoadW	r0,DlgFilesNotSaved
			jsr	DoDlgBox

			PopW	RecoverVector

			jsr	i_MoveData
			w	BACK_SCR_BASE
			w	SCREEN_BASE
			w	$1f40
			rts

;*** Neue Textseite vorbereiten.
:InitNewPage		LoadW	a9,StartPageData

			lda	#$00
			sta	a8L
			sta	a8H			;Anzahl Zeilen auf Seite.

			LoadW	:3 +1,TextFormat_V1x

			lda	GW_Version
			cmp	#$20
			bne	:1

			LoadW	:3 +1,TextFormat_V20
			jmp	:2

::1			cmp	#$21
			bne	:2

			LoadW	:3 +1,TextFormat_V21

::2			ldy	a8L
::3			lda	$8000,y			;Wird berechnet!
			cmp	#$ff
			beq	:4
			jsr	AddByteToDok
			inc	a8L
			bne	:2

::4			lda	Flag_AddNEWCARDSET
			beq	:5
			jsr	AddNEWCARDSET
::5			rts

;*** Textseite speichern.
:SaveTextPage		lda	Flag_PageSaved
			beq	:1
			rts

::1			lda	GW_FileDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			MoveW	GW_Header,r0
			jsr	OpenRecordFile

			lda	Poi_CurPage
			jsr	PointRecord

			LoadW	r7,StartPageData

			lda	a9L
			sec
			sbc	#< StartPageData
			sta	r2L
			lda	a9H
			sbc	#> StartPageData
			sta	r2H
			jsr	WriteRecord
			stx	Flag_PageSaved

			jsr	UpdateRecordFile
			jmp	CloseRecordFile

;*** CR-Code in Text übertragen:
:AddCR			lda	#CR

;*** Byte in Dokument einfügen.
:AddByteToDok		tax
			tya
			pha
			txa

			ldy	#$00
			sta	(a9L),y
			inc	a9L
			bne	:1
			inc	a9H

::1			cmp	#CR
			bne	:2
			inc	a8H

			lda	#MaxLinesOnPage
			cmp	a8H
			bne	:2

			lda	#PAGE_BREAK
			jsr	AddByteToDok
			jsr	SaveTextPage

			inc	Poi_CurPage
			jsr	InitNewPage

::2			pla
			tay
			rts

;*** Name der fehlerhaften Textdatei in Dokument übertragen.
:AddErrFilNmToDok	LoadW	a2,InfoText1
			jsr	AddTextToDok

			LoadW	a2,NameOfErrorFile

;*** Text in Dokument einfügen.
:AddTextToDok		tya
			pha
			ldy	#$00
::1			lda	(a2L),y
			beq	:2
			jsr	AddByteToDok
			iny
			bne	:1
::2			pla
			tay
			rts

;*** Seiten-Nr. in Text einfügen.
:AddPageToDok		pha
			LoadW	a2,InfoText2
			jsr	AddTextToDok
			pla
			sta	a0L
			LoadB	a0H,$00
			LoadW	a1 ,$000a
			ldx	#a0L
			ldy	#a1L
			jsr	Ddiv

			lda	r8L
			pha
			ldy	a0L
			lda	DataTab_DEZ_HEX,y
			jsr	AddByteToDok
			pla
			tay
			lda	DataTab_DEZ_HEX,y
			jmp	AddByteToDok

;*** Textzeile mit Fehler in Dokument übertragen.
:AddErrLineToDok	pha
			lda	#"="
			jsr	AddByteToDok
			lda	#">"
			jsr	AddByteToDok
			lda	#" "
			jsr	AddByteToDok

::1			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			pla
			tay
			jsr	GetByteFromSek
			iny
			beq	:3

::2			jsr	GetByteFromSek
			cmp	#NULL
			beq	:4
			cmp	#PAGE_BREAK
			beq	:4

			pha
			jsr	AddByteToDok
			pla
			cmp	#CR
			beq	:5
			iny
			bne	:2

::3			lda	diskBlkBuf +$00
			sta	r1L
			lda	diskBlkBuf +$01
			sta	r1H
			lda	#$01
			pha
			jmp	:1

::4			lda	#CR
			jsr	AddByteToDok
::5			rts

;*** NEWCARDSET in Dokument einfügen.
:AddNEWCARDSET		lda	#NEWCARDSET
			jsr	AddByteToDok
			lda	#$09
			jsr	AddByteToDok

			bit	c128Flag
			bpl	:1
			bit	graphMode
			bpl	:1

			lda	#$20
			b $2c
::1			lda	#$00
			jsr	AddByteToDok

			lda	#$00
			jmp	AddByteToDok

;*** Fehlerdatei erzeugen.
:CreateErrFile		jsr	AddNEWCARDSET

			lda	#$ff
			sta	Flag_AddNEWCARDSET
			lda	#$00
			sta	Poi_ErrCodeTab

			LoadW	r3,SelectedFile
			LoadW	r4,NameOfErrorFile
			ldx	#r3L
			ldy	#r4L
			jsr	CopyString

::1			ldy	Poi_ErrCodeTab
			lda	ErrCodeTab +0,y
			cmp	#$ff
			bne	:2
			rts

::2			lda	ErrCodeTab +2,y
			jsr	NewSetDevice

			ldy	Poi_ErrCodeTab
			lda	ErrCodeTab +3,y
			sta	r1L
			lda	ErrCodeTab +4,y
			sta	r1H
			lda	ErrCodeTab +5,y
			pha
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			pla
			tay
			ldx	#$00
::3			lda	diskBlkBuf +3,y
			cmp	#$a0
			beq	:4
			sta	NameOfErrorFile,x
			iny
			inx
			cpx	#$10
			bcc	:3
::4			lda	#$00
			sta	NameOfErrorFile,x

			jsr	AddErrFilNmToDok

			ldy	Poi_ErrCodeTab
			lda	ErrCodeTab +1,y
			beq	:5

			lda	#TAB
			jsr	AddByteToDok

			ldy	Poi_ErrCodeTab
			lda	ErrCodeTab +1,y
			jsr	AddPageToDok
			jsr	AddCR

			ldy	Poi_ErrCodeTab
			lda	ErrCodeTab +6,y
			jsr	NewSetDevice
			jsr	GetDirHead

			ldy	Poi_ErrCodeTab
			lda	ErrCodeTab +7,y
			sta	r1L
			lda	ErrCodeTab +8,y
			sta	r1H

			lda	ErrCodeTab +9,y
			jsr	AddErrLineToDok

::5			ldy	Poi_ErrCodeTab
			lda	ErrCodeTab +0,y
			jsr	AddErrTextToDok
			jsr	AddCR

::6			lda	Poi_ErrCodeTab
			clc
			adc	#$0a
			sta	Poi_ErrCodeTab
			jmp	:1

;*** Byte aus Sektor einlesen.
:GetByteFromSek		lda	diskBlkBuf,y
			cmp	#NEWCARDSET
			beq	:1
			cmp	#ESC_RULER
			beq	Read_ESC_RULER
			cmp	#ESC_GRAPHICS
			beq	Read_ESC_GRAPHICS
			rts

;*** NEWCARDSET überlesen.
::1			iny
			bne	:2
			jsr	Read_NextSektor
::2			iny
			bne	:3
			jsr	Read_NextSektor
::3			iny
			bne	:4
			jsr	Read_NextSektor
::4			iny
			bne	GetNxBytFromSek
			jsr	Read_NextSektor

;*** Nächstes Byte aus Sektor einlesen.
:GetNxBytFromSek	jmp	GetByteFromSek

;*** Folgesektor einlesen.
:Read_NextSektor	lda	diskBlkBuf +$00
			sta	r1L
			lda	diskBlkBuf +$01
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			ldy	#$02
			rts

;*** ESC_RULER überlesen.
:Read_ESC_RULER		lda	#$1a
			sta	Read_ByteCount

;*** Nächstes Byte aus Sektor überlesen.
:Read_NextByte		iny
			bne	:1
			jsr	Read_NextSektor
::1			dec	Read_ByteCount
			bpl	Read_NextByte

			jmp	GetNxBytFromSek

;*** ESC_GRAPHICS überlesen.
:Read_ESC_GRAPHICS	lda	#$05
			sta	Read_ByteCount
			bne	Read_NextByte

;*** Fehlermeldung in Text übertragen.
:AddErrTextToDok	pha

			ldx	#$00
			and	#$80
			beq	:1
			dex
::1			stx	Flag_MakroError

			LoadW	a2,ErrorText
			jsr	AddTextToDok

			pla
			asl
			tay
			lda	Err_MsgAdrTab -2 +0,y
			sta	a2L
			lda	Err_MsgAdrTab -2 +1,y
			sta	a2H
			jsr	AddTextToDok

			lda	Flag_MakroError
			beq	:2

			LoadW	a2,MakroErrorText
			jsr	AddTextToDok

::2			lda	#CR
			jmp	AddByteToDok

;*** Symboltabelle oder
;    Externe Symboltabelle erzeugen.
:CreateSymFiles		lda	#$00
			sta	Flag_AddNEWCARDSET

			lda	Vec_StartLabels1 +0
			sta	a0L
			lda	Vec_StartLabels1 +1
			sta	a0H

:TestNextLabel		ldy	#$00
			lda	Flag_LabelType		;Externe Labeldatei erzeugen ?
			beq	:1			;Nein, weiter...

			lda	(a0L),y
			and	#%01000000		;Externes Label ?
			beq	:2			;Nein, weiter...

::1			lda	(a0L),y
			and	#%10000000		;Makrobezeichnung ?
			bne	:2			;Ja, weiter...

			ldy	#$01
			lda	(a0L),y
			cmp	#":"
			bne	:3
::2			jmp	:8

::3			lda	#":"
			jsr	AddByteToDok

			ldy	#$00
			lda	(a0L),y
			and	#%00111111		;Anzahl Zeichen in Label.
			sta	Var_LenLabelName
			inc	Var_LenLabelName

			PushW	a0

			inc	a0L
			bne	:4
			inc	a0H

::4			lda	Var_LenLabelName
			sta	a1L
			dec	a1L

::5			lda	(a0L),y
			jsr	AddByteToDok
			inc	a0L
			bne	:6
			inc	a0H
::6			dec	a1L
			bne	:5

			lda	#TAB
			jsr	AddByteToDok
			lda	#"="
			jsr	AddByteToDok
			lda	#" "
			jsr	AddByteToDok

			lda	(a0L),y
			sta	r0L
			inc	a0L
			bne	:7
			inc	a0H
::7			lda	(a0L),y
			sta	r0H
			jsr	CreateWordHEX

			lda	#CR
			jsr	AddByteToDok

			PopW	a0

::8			ldy	#$00
			lda	(a0L),y
			and	#$3f
			clc
			adc	#$03
			tax
			lda	(a0L),y
			and	#$80
			beq	:9
			inx
			inx
::9			txa
			clc
			adc	a0L
			sta	a0L
			lda	a0H
			adc	#$00
			sta	a0H
			lda	a0L
			cmp	Vec_EndLabels1 +0
			bne	:10
			lda	a0H
			cmp	Vec_EndLabels1 +1
			beq	:11
::10			jmp	TestNextLabel

::11			rts

;*** Variablen.
:Read_ByteCount		b $00				;Bytes aus GW-Text überlesen.

:Flag_MakroError	b $00				;$FF = Fehler innerhalb Makro.

:Flag_LabelType		b $00				;$FF = Ext. Labeltabelle erzeugen.
:Var_LenLabelName	b $00				;Länge aktuelles Label.

:Poi_CurPage		b $00				;Zeiger auf aktuelle GW-Seite.
:Flag_PageSaved		b $00				;$00 = Seite gespeichert, <> $00 Fehler.
:Flag_AddNEWCARDSET	b $00				;$FF = NEWCARDSET einfügen.

:Poi_ErrCodeTab		b $00				;Zeiger auf Fehlertabelle.

:NameOfErrorFile	s 17				;Name der Datei mit Fehlerzeile.

:SysVarCode1		b "Rückkehr von der Ausgabe zum Assembler!!",NULL

:InfoText1		b "Text: "
			b NULL
:InfoText2		b "Seite: "
			b NULL
:ErrorText		b "Fehler: "
			b NULL
:MakroErrorText		b CR
			b "Achtung: Fehler ist innerhalb des "
			b "angegebenen Makros!"
			b NULL

:ScreenText1		b PLAINTEXT,BOLDON
			b " Erzeuge Fehlertabelle... "
			b NULL
:ScreenText2		b PLAINTEXT,BOLDON
			b " Erzeuge Symboltabelle... "
			b NULL
:ScreenText3		b PLAINTEXT,BOLDON
			b " Erzeuge ext. Symboltabelle... "
			b NULL

;*** Fehler: "Kann Dateien nicht erzeugen!".
:DlgFilesNotSaved	b $81
			b DBTXTSTR    ,$10,$10
			w D01a
			b DBTXTSTR    ,$10,$20
			w D01b
			b DBTXTSTR    ,$10,$30
			w D01c
			b DBTXTSTR    ,$10,$40
			w D01d
			b DBTXTSTR    ,$10,$50
			w D01e
			b OK          ,$11,$48
			b NULL

:D01a			b BOLDON
			b "Achtung!"
			b PLAINTEXT,NULL
:D01b			b "Aufgrund eines Diskettenfehlers "
			b NULL
:D01c			b "(Nummer: $..) konnte das Erzeugen"
			b NULL
:D01d			b "von Fehler- bzw. Symboldateien"
			b NULL
:D01e			b "nicht beendet werden."
			b NULL

;*** Adressen der Fehlertexte.
:Err_MsgAdrTab		w Err_Msg01, Err_Msg02
			w Err_Msg03, Err_Msg04
			w Err_Msg05, Err_Msg06
			w Err_Msg07, Err_Msg08
			w Err_Msg09, Err_Msg10
			w Err_Msg11, Err_Msg12
			w Err_Msg13, Err_Msg14
			w Err_Msg15, Err_Msg16
			w Err_Msg17, Err_Msg18
			w Err_Msg19, Err_Msg20
			w Err_Msg21, Err_Msg22
			w Err_Msg23, Err_Msg24
			w Err_Msg25, Err_Msg26
			w Err_Msg27, Err_Msg28
			w Err_Msg29, Err_Msg30
			w Err_Msg31, Err_Msg32
			w Err_Msg33, Err_Msg34
			w Err_Msg35, Err_Msg36
			w Err_Msg37, Err_Msg38

:Err_Msg01		b "Label unbekannt",NULL
:Err_Msg02		b "Befehl/Makro unbekannt",NULL
:Err_Msg03		b "Adressierungsart mit diesem Befehl unmöglich",NULL
:Err_Msg04		b "Label doppelt definiert",NULL
:Err_Msg05		b "Bedingter Sprung (branch) zu weit",NULL
:Err_Msg06		b "Wert zu groß (>$ff)",NULL
:Err_Msg07		b "Makroende (/) außerhalb einer Makrodefinition",NULL
:Err_Msg08		b "ungültige Label-/Makrobezeichnung",NULL
:Err_Msg09		b "Labelname als Makro gebraucht",NULL
:Err_Msg10		b "Makroname als Label gebraucht",NULL
:Err_Msg11		b " ')' fehlt ",NULL
:Err_Msg12		b " '(' fehlt ",NULL
:Err_Msg13		b "Argument fehlt",NULL
:Err_Msg14		b " 'o' darf nur einmal benutzt werden",NULL
:Err_Msg15		b " 'if' darf nicht geschachtelt werden",NULL
:Err_Msg16		b " 'else' ohne 'if' ",NULL
:Err_Msg17		b " 'endif' ohne 'if' ",NULL
:Err_Msg18		b "Makros können nicht lokal definiert werden",NULL
:Err_Msg19		b "Makros können nicht in eine "
			b "Symboltabelle eingetragen werden",NULL
:Err_Msg20		b "Lokale Labels können nicht in eine "
			b "Symboltabelle eingetragen werden",NULL
:Err_Msg21		b "Label ist länger als 63 Zeichen",NULL
:Err_Msg22		b "Branch-Sprungziel muß ein Label enthalten",NULL
:Err_Msg23		b "Ungültige Zahlenangabe",NULL
:Err_Msg24		b "Wert zu groß (>$ffff)",NULL
:Err_Msg25		b "Kein Label angegeben",NULL
:Err_Msg26		b "Grafik als File-Icon ungeeignet",NULL
:Err_Msg27		b "Texte im w-Befehl nicht möglich.",NULL
:Err_Msg28		b "String nicht abgeschlossen",NULL
:Err_Msg29		b "Überlauf",NULL
:Err_Msg30		b "ungültige Makroparameterangabe",NULL
:Err_Msg31		b "Anzahl der Makroparameter ungültig",NULL
:Err_Msg32		b "Fehlender oder bereits vergebener Filename",NULL
:Err_Msg33		b "Max. Makroschachtelungstiefe überschritten",NULL
:Err_Msg34		b "Max. Makroparameteranzahl überschritten",NULL
:Err_Msg35		b "VLIR-Datensatz nicht ansprechbar",NULL
:Err_Msg36		b "Grafik als Objektcode-Icon ungeeignet",NULL
:Err_Msg37		b "ungültiger Dateiname",NULL
:Err_Msg38		b "Kein Textname angegeben",NULL

;*** GeoWrite-Variablen.
:GW_FileDrive		b $00
:GW_Version		b $00

;*** Startbytes für geoWrite-Textseite Version 1.x
:TextFormat_V1x		w $0000
			w $01df
			w $0058
			w $0090
			w $00f8
			w $01df
			w $01df
			w $01df
			w $01df
			w $01df
			b NEWCARDSET
			w $204a
			b NULL

			b $ff,$00,$00

;*** Startbytes für geoWrite-Textseite Version 2.0
:TextFormat_V20		b ESC_RULER
			w $0000
			w $01df
			w $0058
			w $0090
			w $00f8
			w $01df
			w $01df
			w $01df
			w $01df
			w $01df
			w $0000
			b $10
			b $00
			b $00
			b $00

			b NEWCARDSET
			w $204a
			b NULL

			b $ff,$00,$00

;*** Startbytes für geoWrite-Textseite Version 2.1
:TextFormat_V21		b ESC_RULER
			w $0000
			w $027f
			w $00b8
			w $0108
			w $0180
			w $027f
			w $027f
			w $027f
			w $027f
			w $027f
			w $0000
			b $10
			b $00
			b $00
			b $00

			b NEWCARDSET
			w $204a
			b NULL

			b $ff,$00,$00

;*** Infoblock für geoWrite-Datei.
:GW_Header		b $00,$ff
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $80 ! USR
			b APPL_DATA
			b VLIR
			w $0000
			w $0000
			w $0000
			b "Write Image Vx.x"
			s $18
			b "geoWrite    V2.1"
			s 26
			s 96

;*** Seitenspeicher für GeoWrite-Text.
:StartPageData
