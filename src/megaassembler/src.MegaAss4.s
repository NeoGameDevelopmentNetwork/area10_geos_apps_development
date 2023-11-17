; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;MegaAssembler
;Compiler, Hauptschleife Pass1/Pass2.
if .p
			t "TopSym"
			t "TopMac"
			t "src.MegaAss0.ext"
			t "src.MegaAss2.ext"
			t "src.MegaAss3.ext"
endif

			n "mod.#4"
			o VLIR_BASE

;*** Systemeinsprung MegaAssembler.
:MainInit		jmp	StartMegaAss

;*** Zeiger auf Beginn des Labelspeichers.
;    Wird bei der Initialisierung eingelesen!
			w	StartLabelArea

;*** Pass #1 und Pass #2 ausführen.
:StartPass_1_2		sei
			jsr	MouseOff

			lda	#$00
			sta	Flag_NoTextLines
			sta	Flag_EndOfTextFile

:OpenNewPage		jsr	GetPageStart		;Neue Textseite beginnen.
			bcc	:1			;Seite verfügbar, weiter...
			jmp	EndCurTextFile		;Textende erreicht.

::1			LoadB	dispBufferOn,ST_WR_FORE

;*** Nächste Textzeile compilieren.
:CompileNextLine	jsr	GetGW_TextLine		;Neue Textzeile einlesen.

			lda	Flag_NoTextLines	;Seitenende gefunden ?
			beq	CompileCurLine		;Nein, weiter...

			inc	VLIR_Record
			jmp	StartPass_1_2

;*** Aktuelle Zeile compilieren.
:CompileCurLine		lda	Ignore2_ELSE_ENDIF
			beq	:1
			jsr	Check_ENDIF
			jmp	CompileNextLine

::1			jsr	PackTextLine
			bne	:5
			lda	Flag_StopAssemble
			bne	:5

::2			jsr	FindPOpcode

			lda	Flag_ParityError
			beq	:3
			jsr	Err_Pass_1_2
			jmp	:5

::3			lda	Flag_FatalError
			beq	WritePrgData

::5			lda	curPass
			bne	:6
			jsr	doDelObjFile		;Objectcode löschen.
::6			jmp	CreateSysFiles

;*** Assembler-Befehl in Programmcode schreiben.
:WritePrgData		jsr	EXT_WriteAssToPrg
			jmp	CompileNextLine

;*** Assemblierung fortsetzen.
:EndCurTextFile		bit	Flag_SourceInclude
			bpl	:1

			jsr	ExitIncludeFile
			jmp	CompileNextLine

::1			lda	#$00
			sta	VLIR_Record
			jsr	PrintCurPage

			lda	#$00
			sta	Flag_POpcode_O
			sta	Ignore2_ELSE_ENDIF
			dec	curPass			;Nächsten Pass ausführen.
			beq	:6
			jmp	EndOfAssemble		;Pass #2 erledigt, weiter...

;*** Vorbereitung für Pass #2.
::6			inc	X75a +2

			lda	ProgMaxEndAdr +0	;Auf Bereichsüberschreitung
			ora	ProgMaxEndAdr +1	;Quellcode testen.
			beq	:8

			lda	ProgMaxEndAdr +0	;Auf Bereichsüberschreitung
			ldx	ProgMaxEndAdr +1	;Quellcode testen.
			cpx	ProgEndAdr    +1
			bne	:7
			cmp	ProgEndAdr    +0
::7			bcs	:8
			jmp	Err_AreaOverflow	;Fehler: "Programm zu groß".

::8			lda	ProgLoadAdr+0
			cmp	ProgEndAdr +0
			bne	:3
			lda	ProgLoadAdr+1
			cmp	ProgEndAdr +1
			bne	:3

			lda	ProgEndAdr +0
			bne	:2
			dec	ProgEndAdr +1
::2			dec	ProgEndAdr +0
			jmp	CreateSysFiles

::3			lda	ProgEndAdr +0
			bne	:4
			dec	ProgEndAdr +1
::4			dec	ProgEndAdr +0

			jsr	InitPass2
			bcc	:5
			jmp	CreateSysFiles

::5			jsr	PrintStatusLine

			LoadW	ProgEndAdr,$0400

			lda	#<StartLabelArea
			ldx	#>StartLabelArea
			sta	Vec_StartLabelTab +0
			stx	Vec_StartLabelTab +1
			sta	Vec_LokalLabels  +0
			stx	Vec_LokalLabels  +1

			jsr	ClrMakOpenFlags
			jmp	StartPass_1_2

;*** Assemblieung beendet.
:EndOfAssemble		jsr	UpdatePrgCode

			lda	#$ff
			sta	Flag_FileCreated

			lda	ErrCount
			beq	:1
			lda	#$00
			sta	Flag_FileCreated

::1			bit	Flag_FileCreated
			bmi	:2
			lda	Flag_AssembleError
			bne	:2
			jsr	doDelObjFile		;Objectcode löschen.
::2			jmp	CreateSysFiles

;*** Fehler: "Datei bereits vorhanden!"
:Err_FileExist		bit	Opt_OverWrite
			bpl	:1

			LoadW	r0,DlgFileExist
			jsr	DoDlgBox		;Fehler beim assemblieren.

			jsr	PrintStatusLine
			lda	sysDBData
			cmp	#YES
			bne	:2

::1			jsr	doDelObjFile		;Objectcode löschen.
			jmp	InitPass2

::2			sec
:Err_Exit		rts

;*** Datei löschen.
;Übergabe: A/X = Zeiger auf Dateiname.
;Rückgabe: X = Fehlercode.
:doDelObjFile		lda	#< ObjectFileName
			ldx	#> ObjectFileName
:doDeleteFile		sta	r0L
			stx	r0H
			jmp	DeleteFile

;*** Verschiedene Fehlermeldungen.
:Err_LabelNotFound	lda	Flag_LabelNotOK
			bne	Err_Exit
			lda	#$01
			jmp	CopyErrCodeInTab

:Err_UnknownCom		lda	#$02
			b $2c
:Err_BadAdrMode		lda	#$03
			b $2c
:Err_LabelUsed		lda	#$04
			b $2c
:Err_ByteOverflow	lda	#$06
			jsr	CopyErrCodeInTab
			jmp	Add1ToCurCodeLen

:Err_BranchError	lda	#$05
			jsr	CopyErrCodeInTab
			lda	#$01
			sta	CurCommandLen
			jmp	Add1ToCurCodeLen

;*** Pass #2 initialisieren.
:InitPass2		lda	Flag_AssembleError
			beq	:1
			clc
			rts

::1			lda	Opt_TargetDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			LoadW	r6,ObjectFileName
			jsr	FindFile
			txa
			bne	Err_SaveFile
			jmp	Err_FileExist

;*** Fehler: "Bereich überschritten".
:Err_AreaOverflow	sta	ProgErrAdr +0
			sty	ProgErrAdr +1

			lda	#<DlgAreaOverflow
			ldy	#>DlgAreaOverflow
			jmp	FatalError		;Fehler beim assemblieren.

;*** Fehler: "Label überschritten".
:Err_LabelAdress	lda	Address +0
			sta	ProgErrAdr +0
			lda	Address +1
			sta	ProgErrAdr +1

			lda	#<DlgLabelAdress
			ldy	#>DlgLabelAdress
			jmp	FatalError		;Fehler beim assemblieren.

;*** Fehler: "Pass1 und Pass2 unterschiedlich!"
:Err_Pass_1_2		lda	#<DlgPassError
			ldy	#>DlgPassError
			bne	FatalError		;Fehler beim assemblieren.

;*** Fehler: "Kann Objektdatei nicht speichern!"
:Err_SaveFile		cpx	#$05
			beq	SaveObjectFile

			lda	#<DlgSaveError
			ldy	#>DlgSaveError
			bne	FatalError		;Fehler beim speichern.

;*** Objektdatei speichern.
:SaveObjectFile		jsr	EXT_SaveObjFile
			txa
			beq	NoErr1
			lda	#<DlgSaveError
			ldy	#>DlgSaveError
			bne	FatalError		;Fehler beim speichern.
:NoErr1			clc
			rts

;*** Symbolspeicher testen.
;Übergabe: AKKU = Anzahl Zeichen in Label.
:TestSymbTabFull	clc
			adc	SortLabelVec +$7a
			lda	#$00
			adc	SortLabelVec +$7b
			cmp	#>EndLabelArea
			bcc	NoErr1

;--- Symboltabelle ist voll!
			lda	#<DlgSymbTabFull
			ldy	#>DlgSymbTabFull
;			bne	FatalError		;Fehler beim assemblieren.

;*** Abbruchfehler.
:FatalError		ldx	StackVector
			txs

			pha
			tya
			pha

			jsr	LoadErrText

			ldy	ProgErrAdr +0
			ldx	ProgErrAdr +1
			jsr	SetAreaAdress

			ldx	#$ff
			stx	Flag_FatalError
			stx	Flag_StopAssemble
			inx
			stx	Flag_AutoAssInWork

			jsr	SaveRecVec
			jsr	ClrRecVec

			jsr	prepErr

			pla
			sta	r0H
			pla
			sta	r0L
			jsr	DoDlgBox
			jsr	LoadRecVec

;*** Symboltabellen erzeugen.
:CreateSysFiles		ldx	StackVector
			txs

			cli
			jsr	MouseUp

			bit	Flag_FatalError		;Fataler Fehler aufgetreten ?
			bmi	:0			; => Ja, weiter...

			lda	ErrCount		;Fehler aufgetreten ?
			bne	:1			; => Nein, weiter...

::0			lda	#$00
			sta	ErrCount		;Fehlerzähler löschen.
			sta	ErrFileName		;Keine Fehlerliste.
			sta	Flag_ErrFileOK

::1			bit	Flag_StopAssemble	;Vorgang abbrechen ?
			bpl	:2			; => Nein, weiter...

			lda	#$00
			sta	SymFileName		;Keine Symboltabelle.
			sta	Flag_SymbFileOK
			sta	ExtFileName		;Keine ext.Symboltabelle.
			sta	Flag_ExtSFileOK
			beq	:error

::2			bit	Opt_SymbTab		;Symboltabelle erzeugen ?
			bmi	:3			; => Ja, weiter...

			lda	#$00
			sta	SymFileName		;Keine Symboltabelle.
			sta	Flag_SymbFileOK

::3			bit	Flag_ExtLabelFound	;ext.Labels vorhanden ?
			bpl	:4			; => Nein, keine ext.SymbTab.
			bit	Opt_ExtSymbTab		;ext.Symboltabelle erzeugen ?
			bmi	:labels			; => Ja, weiter...

::4			lda	#$00
			sta	ExtFileName		;Keine ext.Symboltabelle.
			sta	Flag_ExtSFileOK

;--- Anfang/Ende Symbolspeicher setzen.
::labels		lda	#<StartLabelArea
			sta	Vec_StartLabels1 +0
			ldx	#>StartLabelArea
			stx	Vec_StartLabels1 +1

			lda	SortLabelVec +$7a
			ldx	SortLabelVec +$7b
			bne	:doData

;--- Bei Fehler keine Symboltabellen.
::error			;lda	#<ErrCodeTab
			;ldx	#>ErrCodeTab
			lda	#<StartLabelArea
			ldx	#>StartLabelArea

::doData		sta	Vec_EndLabels1 +0
			stx	Vec_EndLabels1 +1

			lda	Opt_BootDrive
			jsr	NewSetDevice
			jsr	NewOpenDisk
			jmp	Mod_DoSysFile

;*** Fehlertexte einladen.
:LoadErrText		jsr	FindMegaAss		;MegaAssembler suchen.

			LoadW	r0,NameMegaAss
			jsr	OpenRecordFile		;MegaAss-Datei öffnen.

			lda	#$03
			jsr	PointRecord		;Zeiger auf VLIR-Modul.

			lda	#$00
			sta	r2L
			sta	r7L
			lda	#$20
			sta	r2H			; => $20
			asl
			sta	r7H			; => $40
if FALSE
			LoadW	r7,$4000
			LoadW	r2,$2000
endif
			jsr	ReadRecord		;Programmteil einlesen.
			jmp	CloseRecordFile		;VLIR-Datei schliesen.

;*** Word-Wert nach ASCII wandeln.
:ConvASCII_Word		stx	:1 +1
			jsr	ConvASCII_Word_a
			cpx	#$00
			bne	:2
::1			ldx	#$ff
			rts

::2			lda	#$17
			jmp	NumFormatError

;*** Binärzahl berechnen.
:ConvASCII_Binary	jsr	ConvASCII_Bin_a
			cmp	#$00
			bne	NumFormatError
			rts

;*** Dezimalzahl berechnen.
:ConvASCII_Dezimal	jsr	ConvASCII_Dez_a
			cmp	#$00
			bne	NumFormatError
			rts

;*** Fehlerhaftes Zahlenformat
:NumFormatError		jsr	CopyErrCodeInTab

;*** Kein Operand angegeben.
:SetFlagNoOperand	lda	#$80
			sta	Flag_NoOperand
			sta	r0H
			asl
			sta	r0L
			clc
			rts

;*** String-Operant in Byte umwandeln (z.B. "a" = $61).
:ConvString_Byte	jsr	ConvString_Byte_a
			cmp	#$00
			beq	:1
			jsr	CopyErrCodeInTab
			lda	#$00
			sta	(a0L),y
::1			rts

;*** Include-Datei definieren.
:DefTextFile		jsr	TestTextFileName
			cmp	#$00
			beq	:1
			jsr	CopyErrCodeInTab
			jmp	PrepForNextLine

;*** Include-Stack voll ?
::1			jsr	IncludeNextFile

			LoadW	r6,NameOfTextFile
			jsr	FindFileDrvABCD
			txa
			beq	:2

			lda	#<DlgFindTxtFile
			ldy	#>DlgFindTxtFile
			jmp	FatalError		;Fehler beim assemblieren.

;*** Datei auswerten.
::2			lda	dirEntryBuf +$15
			beq	:3
			lda	dirEntryBuf +$16
			cmp	#APPL_DATA
			beq	OpenIncludeFile

::3			lda	#$26			;Falscher Dateityp.
			jsr	CopyErrCodeInTab
			jmp	ExitIncludeFile

;*** Neue Datei öffnen.
:OpenIncludeFile	lda	curDrive
			sta	VLIR_Drive
			sta	CurrentSektor +0

			lda	#$00
			sta	VLIR_Record

			lda	#$ff
			sta	Flag_DataOrText

			lda	dirEntryBuf    +1
			sta	VLIR_HdrSektor +0
			lda	dirEntryBuf    +2
			sta	VLIR_HdrSektor +1

			jsr	PrintStatusLine

			LoadW	r0,NameOfTextFile
			jsr	OpenRecordFile
			txa
			beq	IncludeTxtFileOK

			lda	#<DlgRdTextFile
			ldy	#>DlgRdTextFile
			jmp	FatalError		;Fehler beim assemblieren.

;*** Include-Textfile gefunden.
:IncludeTxtFileOK	jsr	GetPageStart
			jmp	PrepForNextLine

;*** Zurück zur Quelltext-Datei.
:ExitIncludeFile	jsr	IncludeLastFile
			jsr	PrintStatusLine

			lda	#$00
			sta	Flag_NoTextLines
			sta	Flag_EndOfTextFile
			jsr	GetGW_TextLine		;Textzeile übergehen.
			jmp	PrepForNextLine

;*** Aktuelle Datei in IncludeSpeicher kopieren.
:IncludeNextFile	ldx	IncludeFileStack	;Max. 5 Verschachtelungen von
			cpx	#$04			;Include-Dateien.
			bne	:1

			lda	#<DlgIncStackFull
			ldy	#>DlgIncStackFull
			jmp	FatalError		;Fehler beim assemblieren.

;*** Beginn der Include-Befehlszeile speichern.
::1			jmp	InitIncludeMode

;*** PhotoScrap-Datei einbinden.
:DefPhotoScrap		jsr	DefVLIRParam

			ldy	#$02
::1			lda	diskBlkBuf,y
			beq	:2
			iny
			iny
			bne	:1
::2			dey
			dey
			beq	IllegalVLIR		; => Album leer.
			ldx	Poi_EntryVLIR
::3			dey
			dey
			beq	IllegalVLIR		; =: Kein Scrap in Album.
			dex
			bpl	:3

			ldx	diskBlkBuf +0,y
			beq	IllegalVLIR
			lda	diskBlkBuf +1,y
			tay
			sec
			jsr	GetByteFromText
			bcs	EndCopyDataFile
			sta	CurIconWidth
			jsr	GetByteFromText
			bcs	EndCopyDataFile
			sta	CurIconHight  +0
			jsr	GetByteFromText
			bcs	EndCopyDataFile
			sta	CurIconHight  +1
			bcc	CopyDataFile

;*** VLIR-Datei einbinden.
:DefVLIRFile		jsr	DefVLIRParam

			lda	Poi_EntryVLIR
			asl
			tay
			ldx	diskBlkBuf +$02,y
			beq	IllegalVLIR
			lda	diskBlkBuf +$03,y
			tay
			sec

;*** Nächstes Zeichen aus Datendatei.
:CopyDataFile		jsr	GetByteFromText
			bcs	EndCopyDataFile
			jsr	AddProgByte
			clc
			jmp	CopyDataFile

:RestoreCurSek		ldy	#$00
::1			lda	CurSekDataBuf,y
			sta	CurrentSektor,y
			iny
			cpy	#$04
			bcc	:1
			rts

;*** VLIR-Datensatz ungültig.
:IllegalVLIR		lda	#$23
:SetVLIR_Error		jsr	CopyErrCodeInTab
:EndCopyDataFile	jsr	RestoreCurSek
			jsr	GetCurrentSektor
			jmp	PrepForNextLine

;*** Datendatei einbinden.
:DefDataFile		jsr	TestDataFileName
			cmp	#$00
			beq	:1
			jsr	CopyErrCodeInTab
			jmp	PrepForNextLine

::1			jsr	IncludeNextFile

			LoadW	r6,NameOfDataFile
			jsr	FindFileDrvABCD
			txa
			beq	AddDataByte2Code

			lda	#<DlgFindDatFile
			ldy	#>DlgFindDatFile
			jmp	FatalError		;Fehler beim assemblieren.

;*** Datendatei in Programmcode einfügen.
:AddDataByte2Code	ldx	dirEntryBuf +$01
			ldy	dirEntryBuf +$02
			sec

;*** Nächstes Zeichen aus Datendatei.
:GetNextDataByte	jsr	GetByteFromText
			bcs	:1
			jsr	AddProgByte
			clc
			jmp	GetNextDataByte
::1			jmp	ExitIncludeFile

;*** Parameter für VLIR/PhotoScrap definieren.
:DefVLIRParam		ldy	#$ff
::1			iny
			lda	CurAdrModeLine,y
			sta	StringValueLine,y
			cmp	#","
			bne	:1

			lda	#$00
			sta	StringValueLine,y
			iny
			tya
			pha
			jsr	ConvStrg2Val

			lda	Address +0
			sta	Poi_EntryVLIR
			pla
			tay

			jsr	TestVlirFileName
			cmp	#$00
			beq	:2
			jsr	CopyErrCodeInTab
			jmp	PrepForNextLine

::2			LoadW	r6,NameOfDataFile
			jsr	FindFileDrvABCD
			txa
			beq	:4
			lda	#<DlgFindDatFile
			ldy	#>DlgFindDatFile
			jmp	FatalError		;Fehler beim assemblieren.

::4			lda	dirEntryBuf +$17	;VLIR-Datei ?
			bne	:5			;Nein, Fehler...

			lda	#$24
			jmp	SetVLIR_Error

::5			ldy	#$03
::6			lda	CurrentSektor,y
			sta	CurSekDataBuf,y
			dey
			bpl	:6

			ldx	dirEntryBuf +$01
			ldy	dirEntryBuf +$02
			stx	r1L
			sty	r1H
			LoadW	r4,diskBlkBuf
			jmp	GetBlock

:CurSekDataBuf		s $04

;*** Neues Makro definieren.
:DefMakroName		lda	curPass
			beq	:2
			lda	Flag_LabelIsDefined
			bne	:1
			jmp	Err_NoMakroName

::1			jsr	DefMakroStartPar	;Start der Makro-Definition
							;merken.

::2			jsr	GetGW_TextLine		;Textzeile einlesen.

			lda	Flag_NoTextLines	;Textende erreicht ?
			bne	:3			;Ja, Fehler "/" fehlt.
			lda	CurTextLine
			cmp	#"/"			;Makroende erreicht ?
			bne	:2			;Nein, weitersuchen.
			rts

;*** "/" nicht gefunden, Assemblierung abbrechen.
::3			LoadB	Flag_FatalError,$01
			jmp	Err_MakroDef

;*** Makrostartadresse in Labeldefinition eintragen.
:DefMakroStartPar	PushW	a3

			MoveW	VecCurLabelBuf2,a3

			ldy	#$00
			lda	(a3L),y
			and	#%01000000
			beq	:2
			lda	#$13
::1			jsr	CopyErrCodeInTab

			PopW	a3
			rts

::2			ldy	#$01
			lda	(a3L),y
			cmp	#":"
			bne	:3
			lda	#$12
			bne	:1

::3			lda	#$02
			jsr	TestSymbTabFull

			MoveW	Buf_VecStLabelTab,a3
			ldy	#$02
			jsr	InsSpaceForLabel

			ldx	Poi_SortLabelTab
			inx
			inx
			lda	#$02
			jsr	MovSLabelStartAdr

			ldy	#$00			;Makroangaben speichern.
			lda	CurrentTextLine +0	;Laufwerk.
			sta	(a3L),y
			iny
			lda	CurrentTextLine +1	;Track-Adresse.
			sta	(a3L),y
			iny
			lda	CurrentTextLine +2	;Sektor-Adresse.
			sta	(a3L),y
			iny
			lda	CurrentTextLine +3	;Zeiger auf erstes Byte.
			sta	(a3L),y

			MoveW	VecCurLabelBuf2,a3	;Zeiger auf erstes Byte.

			ldy	#$00
			lda	(a3L),y			;Label als Makro
			and	#%00111111		;kennzeichnen.
			ora	#%10000000
			sta	(a3L),y
			PopW	a3
			rts

;*** Makrodefinition abschließen.
:DefEndMakro		lda	MakroEntryStack
			bne	:1
			lda	#$07
			jsr	CopyErrCodeInTab
			jmp	PrepForNextLine

::1			jsr	MakroLastEntry

			lda	#$00
			sta	CurCommandLen

			ldx	MakroEntryStack
			inx
			lda	MakroVecData_1,x
			sta	a0L

			ldy	a0L
			ldx	#$09
::4			lda	MakroParIsDef,y
			cmp	#$ff
			beq	:5
			lda	#$00
			sta	MakroParIsDef,y
			iny
			dex
			bmi	:6
			jmp	:4

::5			lda	#$01
			sta	Flag_MakParCntErr

::6			lda	curPass
			bne	:7
			lda	Flag_MakParCntErr
			beq	:7
			lda	#$1f
			sta	ErrTypeCode
			jsr	StoreErrorInTab

::7			lda	#$00
			sta	Flag_MakParCntErr
			jsr	GetGW_TextLine
			jmp	PrepForNextLine

;*** Aktuelle Datei in IncludeSpeicher kopieren.
:MakroNextEntry		ldx	MakroEntryStack		;Max. 5 Verschachtelungen von
			cpx	#MaxOpenMakros		;Include-Dateien.
			bne	:1
			jsr	Find_EndOfLine		;Stack voll, Zeile überlesen.

			lda	#<DlgMakStackFull
			ldy	#>DlgMakStackFull
			jmp	FatalError		;Fehler beim assemblieren.
::1			jmp	MakroNextEntry_a

;*** Fehler: "Makrodefinition nicht beendet".
:Err_MakroDef		lda	#<DlgMakroDef
			ldy	#>DlgMakroDef
			jmp	FatalError		;Fehler beim assemblieren.

;*** Fehler: "Makroname fehlt".
:Err_NoMakroName	lda	#<DlgNoMakroName
			ldy	#>DlgNoMakroName
			jmp	FatalError		;Fehler beim assemblieren.

;*** Makroparameter-Nr. einlesen (&0 - &9).
:GetMakroParNr		ldy	#$01
			lda	StringValueLine,y
			jsr	IsCharNumber		;Makroparameter 0 - 9 ?
			bpl	:1			;Ja, weiter...

			lda	#$1e			;Fehler: "Parameter ungültig!"
			jsr	CopyErrCodeInTab
			jmp	:3

::1			asl
			ldx	MakroEntryStack
			clc
			adc	MakroVecData_2,x
			tay
			lda	MakroParData -20,y	;Wert für Parameter §0 - §9
			sta	Address +0		;in Zwischenspeicher einlesen.
			iny
			lda	MakroParData -20,y
			sta	Address +1
			dey
			tya
			lsr
			tay
			lda	MakroParIsDef,y		;War Parameter definiert ?
			bne	:2			;Ja, weiter...
			lda	#$01
			sta	Flag_MakParCntErr	;Ungültige Parameter-Nr.

::2			lda	#$80			;Parameter wurde angesprochen.
			sta	MakroParIsDef,y

::3			lda	Len_CurOperand
			cmp	#$01
			bne	:4

			lda	curPass
			beq	:4

			lda	#$00
			sta	Address +1

::4			jmp	ChkLen_CurOperand

;*** Berechnung ausführen.
:doCalc			ldy	#$00
			sty	CurrentCalcMode		;Berechnungsmodus löschen.

::1			lda	StringValueLine  ,y	;Ende erreicht ?
			beq	:3			;Ja, weiter...
			sta	CalculationBuffer,y	;In Zwischenspeicher kopieren.

			jsr	GetCalcMode		;Berechnungsmodus ermitteln.
			txa				;Modus gefunden ?
			beq	:2			;Nein, weiter...
			stx	CurrentCalcMode		;Ja, merken.

::2			iny				;Zeiger auf nächstes Zeichen.
			bne	:1			;Weitertesten.

::3			sta	CalculationBuffer,y	;Ende markieren (NULL-Byte).

			lda	CurrentCalcMode		;Berechnungsmodus definiert ?
			bne	:4			;Ja, weiter...
			jmp	Test_POpcodes		;Ungültig, auf Pseudos testen.

::4			lda	#$00
			sta	Poi_StrgValLine		;Zeiger auf erstes Zeichen.

::5			ldy	Poi_StrgValLine
			ldx	#$00
::6			lda	CalculationBuffer,y	;Zwischenspeicher umkopieren.
			sta	StringValueLine  ,x
			beq	:8
			stx	Poi_StrgValBuffer	;String-Länge merken.

			jsr	GetCalcMode		;Berechnungsmodus ermitteln.
			txa				;Modus gefunden ?
			beq	:7			;Nein, weiter...

			ldx	Poi_StrgValBuffer
			lda	#$00			;String-Ende markieren.
			sta	StringValueLine,x
			beq	:8

::7			ldx	Poi_StrgValBuffer
			inx
			iny
			bne	:6			;String weiter auswerten.

::8			lda	StringValueLine		;Zeichen im String vorhanden ?
			bne	:10			;Ja, weiter...
			lda	Poi_StrgValLine
			beq	:9

			lda	#$0d			;Fehler: "Argument fehlt".
			jsr	NumFormatError
			lda	#$02
			rts

::9			ldy	#$00			;Label mit $0000-Wert
			sty	Address +0		;vorbelegen und in String
			sty	Address +1		;einfügen.
			jsr	InsChar1stBufPos
			lda	#"0"
			sta	StringValueLine
			bne	:11

::10			jsr	Test_POpcodes		;Pseudo-Opcodes testen.
			bcc	:11			;Gefunden, weiter...
			jsr	SetFlagNoOperand	;Adresse mit $8000 belegen,
			lda	#$02			;Ende.
			sec
			rts

::11			ldy	Poi_StrgValLine
			iny
			lda	CalculationBuffer +0,y
			bne	:12
			dey
			lda	Address +0
			sta	CalculationBuffer +0,y
			lda	Address +1
			sta	CalculationBuffer +1,y
			lda	#$00
			sta	CalculationBuffer +2,y
			beq	:16

::12			jsr	GetCalcMode
			txa
			beq	:13

			ldy	Poi_StrgValLine
			jsr	InsChar1stBufPos

::13			ldy	Poi_StrgValLine
			lda	Address +0
			sta	CalculationBuffer +0,y
			lda	Address +1
			sta	CalculationBuffer +1,y
			inc	Poi_StrgValLine
			inc	Poi_StrgValLine

::14			ldy	Poi_StrgValLine
			lda	CalculationBuffer +0,y
			beq	:16
			jsr	GetCalcMode
			txa
			bne	:15

			jsr	Del1stCharFromBuf
			jmp	:14

::15			inc	Poi_StrgValLine
			jmp	:5

::16			lda	#$05
			sta	CurrentPriority

::17			ldy	#$02
::18			lda	CalculationBuffer +0,y
			beq	:19
			jsr	GetCalcMode

			lda	CalcPriority
			cmp	CurrentPriority
			beq	:20
			iny
			iny
			iny
			bne	:18

::19			dec	CurrentPriority
			bpl	:17
			bmi	:24

::20			dex
			txa
			asl
			tax
			lda	CalculationTypes,x
			sta	:21 +1
			inx
			lda	CalculationTypes,x
			sta	:21 +2
			dey
			dey

::21			jsr	diskBlkBuf +$00
			bcc	:17
			lda	curPass
			bne	:22
			lda	#$1d
			jsr	CopyErrCodeInTab
::22			jsr	SetFlagNoOperand
			lda	#$02
			rts

::24			lda	CalculationBuffer +0
			sta	Address +0
			lda	CalculationBuffer +1
			sta	Address +1
;--- Hinweis:
;LDA-Befehl unnötig, Z-Flag bereits
;durch den voherigen Befehl gesetzt.
;			lda	Address +1
			beq	:25

			lda	#$02
			clc
			rts

::25			lda	#$01
			clc
			rts

;*** Pseudo-Labels ".p", ".x" und ".y" auswerten.
:Test_POpcodes		lda	StringValueLine +0
			cmp	#"."			;PseudoOpecode ?
			bne	:4			;Nein, weiter...

			lda	StringValueLine +1
			cmp	#"x"			;Befehl ".x" ?
			bne	:1			;Nein, weiter...
			lda	CurIconWidth		;Icon-Breite übergeben.
			sta	Address +0
			lda	#$00
			sta	Address +1
			jmp	ChkLen_CurOperand

::1			cmp	#"y"			;Befehl ".y" ?
			bne	:2			;Nein, weiter...
			lda	CurIconHight +0		;Icon-Höhe übergeben.
			sta	Address      +0
			lda	CurIconHight +1
			sta	Address      +1
			jmp	ChkLen_CurOperand

::2			cmp	#"p"			;Pass an Quellcode übergeben ?
			bne	:4			;Nein, weiter...

			lda	curPass
			beq	:3			; => Pass #1.

			lda	#$ff			; => Pass #2.
::3			sta	Address +0
			sta	Address +1
			jmp	ChkLen_CurOperand

::4			cmp	#$40			;Makroparameter aufrufen ?
			bne	:5			;Nein, weiter...
			jmp	GetMakroParNr		;Parameter einlesen.

::5			cmp	#"$"			;Hexzahl auswerten ?
			beq	:9			;Ja, weiter...
			pha
			and	#$80
			beq	:6
			pla
			and	#$7f
			sta	Address +0
			lda	#$00
			sta	Address +1
			jmp	ChkLen_CurOperand

::6			pla
			cmp	#"%"
			bne	:7
			jsr	ConvASCII_Binary	;Binärzahl einlesen.
			jmp	ChkLen_CurOperand

::7			jsr	IsCharNumber
			bmi	:8

			jsr	ConvASCII_Dezimal	;Dezimal-Zahl einlesen.
			MoveW	r0,Address
			jmp	ChkLen_CurOperand
::8			jmp	GetMaxLenAssOp

::9			lda	#"0"			;HEX-Zahl einlesen.
			sta	BufferHEX +0
			sta	BufferHEX +1
			sta	BufferHEX +2
			sta	BufferHEX +3
			ldy	#$00
			sty	BufferHEX +4
			sty	r0L
			sty	r0H

::10			lda	StringValueLine,y
			beq	:11
			cmp	#" "
			beq	:11
			iny
			bne	:10

::11			dey
			lda	StringValueLine,y
			cmp	#"$"
			bne	:13

::12			lda	#$17
			jmp	NumFormatError

::13			sta	BufferHEX +3
			dey
			lda	StringValueLine,y
			cmp	#"$"
			beq	:15
			sta	BufferHEX +2
			dey
			lda	StringValueLine,y
			cmp	#"$"
			beq	:15
			sta	BufferHEX +1
			dey
			lda	StringValueLine,y
			cmp	#"$"
			beq	:15
			sta	BufferHEX +0
			dey
			lda	StringValueLine,y
			cmp	#"$"
			beq	:15
::14			jmp	:12

::15			cpy	#$00
			bne	:14
			jsr	ConvASCII_Word
			MoveW	r0,Address +0

;*** Länge des Operanden testen.
:ChkLen_CurOperand	lda	Address +1
			beq	:1
			lda	#$02
			b $2c
::1			lda	#$01
			clc
			rts

;*** Textzeile aus GeoWrite-Text packen.
:PackTextLine		lda	#$00
			sta	Poi_CurTextLine
			sta	CurLabelName
			sta	PackedDataLine
			sta	CurAdrModeLine
			sta	StringValueLine
			sta	Flag_ParityError
			sta	Flag_CurLabelExtern

::1			ldy	Poi_CurTextLine
			lda	CurTextLine,y
			bne	:2
			rts

::2			cmp	#" "
			bne	:3
			inc	Poi_CurTextLine
			jmp	:1

::3			cmp	#":"			;Label.
			beq	:5
			cmp	#"."			;Externes Label.
			beq	:4
			jmp	:12

::4			lda	#$ff
			sta	Flag_CurLabelExtern
			sta	Flag_ExtLabelFound

::5			lda	#$00
			sta	Flag_LabelIsDefined

			inc	Poi_CurTextLine

			LoadW	a0,CurLabelName
			jsr	ConvertTextLine
			php

			lda	CurLabelName
			cmp	#":"			;Lokales Label ?
			beq	:9			;Ja, weiter...

			jsr	ClrMakOpenFlags

			lda	curPass
			bne	:9

			ldy	#$00
::18			lda	CurLabelName,y
			sta	StringValueLine,y
			beq	:19
			iny
			bne	:18

::19			jsr	ConvLabelToWord
			bcs	:9

			lda	Flag_LabelNotOK
			bne	:9

			lda	Flag_CurLabelType
			bne	:9

			lda	ErrCount
			bne	:8

::6			lda	ProgEndAdr  +0
			cmp	Buf_Address +0
			bne	:7
			lda	ProgEndAdr  +1
			cmp	Buf_Address +1
			beq	:8

::7			lda	#$01
			sta	Flag_ParityError

::8			MoveW	a3,Vec_LokalLabels

::9			lda	ProgEndAdr  +0
			sta	Buf_Address +0
			lda	ProgEndAdr  +1
			sta	Buf_Address +1
			lda	#$00
			sta	Flag_CurLabelType
			jsr	ChkCurLabel
			php
			lda	curPass
			beq	:10
			MoveW	Vec_StartLabelTab,Vec_LokalLabels
::10			plp
			bcc	:11
			plp
			jmp	Err_LabelUsed		;Fehler:Label bereits definiert.

::11			plp
			bcc	:12
			rts

::12			ldy	Poi_CurTextLine
			lda	CurTextLine,y
			cmp	#" "
			bne	:13
			inc	Poi_CurTextLine
			bne	:12

::13			cmp	#"="
			bne	:14
			sta	PackedDataLine +0
			lda	#$00
			sta	PackedDataLine +1
			inc	Poi_CurTextLine
			bne	:15

::14			LoadW	a0,PackedDataLine
			jsr	ConvertTextLine
			bcc	:15
			rts

::15			ldy	Poi_CurTextLine
			lda	CurTextLine,y
			bne	:16
			rts

::16			cmp	#" "
			bne	:17
			inc	Poi_CurTextLine
			jmp	:15

::17			LoadW	a0,CurAdrModeLine

			lda	#$00
			sta	Poi_PackedData

:ReadDataByte		ldy	Poi_CurTextLine
			lda	CurTextLine,y
			dec	ByteCopyCount
			bpl	SavePackedByte

			ldx	#$00
			stx	ByteCopyCount
			cmp	#ESC_GRAPHICS
			bne	:1
			ldx	#$04
			stx	ByteCopyCount

::1			cmp	#$00
			bne	SavePackedByte
			rts

;*** Byte speichern, weiter mit nächstem Byte.
:SavePackedByte		ldy	Poi_PackedData
			sta	(a0L),y
			inc	Poi_PackedData
			inc	Poi_CurTextLine
			iny
			lda	#$00
			sta	(a0L),y
			jmp	ReadDataByte

;*** Textzeile konvertieren.
:ConvertTextLine	lda	#$00
			sta	Poi_PackedData

:ConvNextByte		ldy	Poi_CurTextLine
			lda	CurTextLine,y
			cmp	#" "
			beq	:1
			cmp	#ESC_GRAPHICS
			beq	CopyESC_GRAPHICS
			cmp	#$00
			bne	:2
			sec
			rts
::1			clc
			rts

::2			ldy	Poi_PackedData
			sta	(a0L),y
			inc	Poi_PackedData
			inc	Poi_CurTextLine
			iny
			lda	#$00
			sta	(a0L),y
			jmp	ConvNextByte

;*** ESC_GRAPHICS kopieren.
:CopyESC_GRAPHICS	ldx	#$05
::1			stx	:2 +1

			ldy	Poi_PackedData
			sta	(a0L),y
			inc	Poi_PackedData
			inc	Poi_CurTextLine

			ldy	Poi_CurTextLine
			lda	CurTextLine,y
::2			ldx	#$ff
			dex
			bne	:1

			ldy	Poi_PackedData
			lda	#$00
			sta	(a0L),y
			jmp	ConvNextByte

;*** Aktuelle Zeile beenden.
:PrepForNextLine	lda	#$00
			sta	CurCommandLen
			rts

;*** Pseudo-Opcodes auswerten.
:FindPOpcode		ldy	#$00
			sty	Flag_FatalError
			sty	OpcodeModes +0
			sty	OpcodeModes +1
			sty	OpcodeModes +2
			lda	PackedDataLine
			bne	:1
			sta	CurCommandLen
			rts

::1			cmp	#"="			;Label definieren ?
			bne	NoLabelDef		;Nein, weiter...
			LoadB	Flag_ParityError,$00
			lda	curPass			;Pass #1 ?
			bne	:2			;Ja, weiter...
			jmp	EndFindPOpcode		;Definition übergehen.

::2			lda	Flag_LabelIsDefined
			bne	:3
			lda	#$19
			jsr	CopyErrCodeInTab
			jmp	PrepForNextLine

::3			jsr	ConvOp			;Operand (nicht POpcode) testen.
			bcc	:4			; => Label verfügbar.

			jsr	Err_LabelNotFound	; => Fehler, "Label not found".

::4			MoveW	Buf_VecStLabelTab,r0

			ldy	#$00
			lda	Address     +0
			sta	Buf_Address +0
			sta	(r0L),y
			iny
			lda	Address     +1
			sta	Buf_Address +1
			sta	(r0L),y
			jmp	PrepForNextLine

;*** Kein Label definieren.
:NoLabelDef		lda	PackedDataLine +0
			cmp	#ESC_GRAPHICS
			bne	:1
			jmp	InsertGraphics

::1			lda	#$00
			sta	Flag_POpcode_I
			sta	Flag_POpcode_J
			lda	PackedDataLine +1
			beq	:2
			lda	#$00
			sta	Flag_LabelIsDefined
			jmp	FindNextPOpcode

::2			lda	PackedDataLine +0
			cmp	#"m"
			bne	:3
			jmp	DefMakroName

::3			ldx	#$00
			stx	Flag_LabelIsDefined
::4			lda	POpcodeTab,x
			beq	FindNextPOpcode
			cmp	PackedDataLine +0
			bne	:5
			txa
			asl
			tay
			lda	POpcodeAdr +0,y
			ldx	POpcodeAdr +1,y
			jmp	CallRoutine

::5			inx
			bne	:4

;*** Zeiger auf nächstes Zeichen.
:FindNextPOpcode	lda	PackedDataLine +0,y
			beq	:1
			iny
			jmp	NoLabelDef

::1			cpy	#$00
			beq	EndFindPOpcode
			cpy	#$03
			bne	:2
			jmp	FindAssOpcode

::2			jsr	Check_IF
			bcc	EndFindPOpcode
			jmp	NoCodeFound
:EndFindPOpcode		jmp	PrepForNextLine

;*** Testmarke prüfen.
:DefUpfillMem		jsr	ConvPOp
			jsr	testAdrArea
			beq	:1
			bcc	:2
			jmp	Err_LabelAdress
::1			jmp	PrepForNextLine

::2			lda	Address    +0
			sec
			sbc	ProgEndAdr +0
			sta	a0L
			lda	Address    +1
			sbc	ProgEndAdr +1
			sta	a0H
			jmp	SendZeroBytes

;*** Adresse testen.
:DefCheckAdr		jsr	ConvPOp
			jsr	testAdrArea
			beq	:1
			bcc	:1
			jmp	Err_LabelAdress
::1			jmp	PrepForNextLine

;*** Adresse testen.
:testAdrArea		MoveW	Address,LastTestAdr
			CmpW	ProgEndAdr,Address
			rts

;*** Ladeadresse definieren.
:DefLoadAdr		lda	Flag_POpcode_O
			beq	:1
			lda	#$0e
			jsr	CopyErrCodeInTab
			jmp	PrepForNextLine

::1			LoadB	Flag_POpcode_O,$01
			jsr	PrepParam

			lda	Address     +0
			sta	ProgEndAdr  +0
			sta	ProgLoadAdr +0
			lda	Address     +1
			sta	ProgEndAdr  +1
			sta	ProgLoadAdr +1
			jmp	PrepForNextLine

;*** Startadresse definieren.
:DefStartAdr		jsr	ConvPOp
			MoveW	Address,Header +$4b
			jmp	PrepForNextLine

;*** Endadresse definieren.
:DefEndAdr		jsr	ConvPOp
			MoveW	Address,ProgUserEndAdr
			jmp	PrepForNextLine

;*** Bereichsgrenze definieren.
:DefMaxEndAdr		jsr	ConvPOp
			MoveW	Address,ProgMaxEndAdr
			jmp	PrepForNextLine

;*** GEOS-Dateityp definieren.
:DefGEOS_Type		jsr	ConvPOp
			MoveB	Address,Header +$45
			jmp	PrepForNextLine

;*** Icon für Objectdatei definieren.
:DefObjIcon		lda	#$ff
			sta	Flag_POpcode_I
			bne	defIconData

;*** Header-Icon im Quelltext definieren.
:DefHdrIcon		lda	#$ff
			sta	Flag_POpcode_J

:defIconData		jsr	i_MoveData
			w	CurAdrModeLine
			w	PackedDataLine
			w	$001e
			jmp	FindPOpcode

;*** Dateiname definieren.
:DefFileName		lda	#<ObjectFileName
			ldx	#>ObjectFileName
			ldy	#16
			jsr	CopyStringToVec1
			bcs	:5

			LoadB	CurCommandLen,$00

			lda	ObjectFileName
			beq	:5

			LoadW	r3,ObjectFileName
			LoadW	r4,SelectedFile
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString		;Dateinamen identisch?
			bne	rts0			; => Nein, Ende...

::5			lda	#$01
			sta	Flag_AssembleError
			lda	#$20
			jmp	CopyErrCodeInTab

;*** GEOS-Klasse definieren.
:DefFileClass		lda	#<Hdr_Class
			ldx	#>Hdr_Class
			ldy	#Hdr_ClassLen
			jsr	CopyStringToVec1
			jmp	PrepForNextLine

;*** Autor definieren.
:DefAutorName		lda	#<Hdr_Author
			ldx	#>Hdr_Author
			ldy	#Hdr_AuthorLen
			jsr	CopyStringToVec1
			jmp	PrepForNextLine

;*** Bildschirm-Flag definieren.
:DefScrnFlag		jsr	ConvPOp
			MoveB	Address,Header +$60
:rts0			rts

;*** "H": Infotext aus Linktext einlesen.
:DefInfoText		lda	curPass			;Pass #1 ?
			beq	:exit			;Nein, Definition übergehen.

			LoadW	r0,Hdr_Info

			ldx	#95
			lda	Poi_FileInfoText
			beq	:3

			cmp	#95
			bcc	:2
			lda	#$00

::2			tay
			lda	#CR
			sta	(r0L),y
			iny

			tya
			clc
			adc	r0L
			sta	r0L
			lda	#$00
			adc	r0H
			sta	r0H

			sty	r1L
			lda	#95
			sec
			sbc	r1L
			tax

::3			stx	r1L
			jsr	CopyStringToVec2
			lda	Poi_FileInfoText
			beq	:4
			iny
::4			tya
			clc
			adc	Poi_FileInfoText
			sta	Poi_FileInfoText

::exit			rts

;*** Pseudo-Opcode: "s".
:DefBlockTab		lda	#$00
			sta	Flag_StopSOpcode

			jsr	ConvOp
			bcc	:3

			lda	Flag_LabelNotOK
			bne	:1
			jsr	Err_LabelNotFound

::1			lda	curPass
			beq	:2
			lda	#$01
			sta	Flag_AssembleError
::2			jmp	PrepForNextLine

::3			lda	Flag_StopSOpcode
			bne	:1

			MoveW	Address,a0

;*** $00-Bytes an Programm schicken.
;    Anzahl in ":a0".
:SendZeroBytes		lda	#$00
			jsr	AddProgByte

			lda	a0L
			bne	:1
			dec	a0H
::1			dec	a0L
			lda	a0L
			ora	a0H
			bne	SendZeroBytes

			jmp	PrepForNextLine

;*** Pseudo-Opcode: "w".
:DefWordTab		lda	#$ff
			b $2c

;*** Pseudo-Opcode: "b".
:DefByteTab		lda	#$00
			sta	Flag_ByteOrWord

:DefByteWordTab		ldx	#$00
			ldy	#$00
			sty	Flag_ByteStringOpen
::1			lda	CurAdrModeLine,y
			sta	CurAdrModeLine,x
			beq	:5
			cmp	#$22
			bne	:2
			lda	Flag_ByteStringOpen
			eor	#$ff
			sta	Flag_ByteStringOpen
::2			cmp	#" "
			bne	:3
			lda	Flag_ByteStringOpen
			beq	:4
::3			inx
::4			iny
			bne	:1

::5			lda	Flag_ByteStringOpen
			beq	:6
			lda	#$1c
			jsr	CopyErrCodeInTab
			jmp	FinishCurLine

::6			ldy	#$00
			sty	Poi_ByteWordText

;*** Nächstes Zeichen aus Byte/Word-Tabelle einlesen.
:GetNextTabByte		lda	CurAdrModeLine,y
			beq	:2
			cmp	#","
			beq	:2
			cmp	#$22
			bne	:1
			jmp	StringFoundInTab

::1			iny
			bpl	GetNextTabByte

::2			sta	CurAdrModeChar
			cpy	#$00
			bne	:3
			lda	#$0d
			jsr	CopyErrCodeInTab
			jmp	PrepForNextLine

::3			tya
			ldy	Poi_ByteWordText
			sta	Poi_ByteWordText

			ldx	#$00
::4			lda	CurAdrModeLine,y
			sta	StringValueLine,x
			inx
			iny
			cpy	Poi_ByteWordText
			bne	:4

			lda	#$00
			sta	StringValueLine,x
			jsr	ConvStrg2Val
			bcc	:5
			lda	curPass
			bne	:6
			jsr	Err_LabelNotFound
			jmp	:6

::5			bit	Flag_ByteOrWord
			bmi	:6
			lda	Address +1
			beq	:6
			lda	Flag_NoOperand
			bne	:6
			lda	curPass
			bne	:6
			jsr	Err_ByteOverflow

::6			lda	Address +0
			jsr	AddProgByte
			bit	Flag_ByteOrWord
			bpl	:7
			lda	Address +1
			jsr	AddProgByte

::7			lda	CurAdrModeChar
			beq	FinishCurLine

			inc	Poi_ByteWordText
			ldy	Poi_ByteWordText
			jmp	GetNextTabByte

;*** Nächste Zeile beginnen.
:FinishCurLine		jmp	PrepForNextLine

;*** String in Byte/Word-Tabelle gefunden.
:StringFoundInTab	bit	Flag_ByteOrWord
			bpl	AddStringBytes
			lda	#$1b
			jsr	CopyErrCodeInTab
			jmp	FinishCurLine

;*** Textstring übernehmen.
:AddStringBytes		iny
::1			lda	CurAdrModeLine,y
			cmp	#$22
			beq	:2
			sty	:3 +1
			jsr	AddProgByte
::3			ldy	#$ff
			iny
			bpl	:1

::2			iny
			lda	CurAdrModeLine,y
			beq	FinishCurLine
			iny
			sty	Poi_ByteWordText
			jmp	GetNextTabByte

;*** Grafik in Text einfügen.
:InsertGraphics		jsr	GetFileHeader

			bit	Flag_POpcode_J
			bmi	Insert24BitIconJ

			bit	Flag_POpcode_I
			bmi	Insert24BitIconI

			jsr	InsertGraphics_a
			jmp	PrepForNextLine

;*** Icon über "i" oder "j" in Programmcode einbinden.
:Insert24BitIconI	lda	#$24
			b $2c
:Insert24BitIconJ	lda	#$1a

			ldx	PackedDataLine +1
			cpx	#$03
			beq	:1

			jsr	CopyErrCodeInTab
			jmp	PrepForNextLine

::1			jmp	Insert24BitIcon_a

;*** Opcode in Tabelle suchen.
:FindAssOpcode		LoadW	Vec_OpcodeTab,OpcodeTab

::1			MoveW	Vec_OpcodeTab,r4

			ldy	#$00
			lda	(r4L),y
			cmp	PackedDataLine,y
			bne	:2
			iny
			lda	(r4L),y
			cmp	PackedDataLine,y
			bne	:2
			iny
			lda	(r4L),y
			cmp	PackedDataLine,y
			beq	:7

::2			lda	Vec_OpcodeTab +0
			ldx	Vec_OpcodeTab +1
			clc
			adc	#$06
			sta	Vec_OpcodeTab +0
			bcc	:3
			inx
::3			stx	Vec_OpcodeTab +1
			sta	r4L
			stx	r4H

			ldy	#$00
			lda	(r4L),y
			cmp	#$ff
			bne	:1
			jmp	NoCodeFound

::5			lda	CurAdrModeLine
			beq	:6
			lda	curPass
			beq	:6
			jmp	Err_BadAdrMode

::6			lda	OpcodeModes +0
			sta	CurCommand +0
			lda	#$01
			sta	CurCommandLen
			rts

::7			lda	Vec_OpcodeTab    +0
			sta	Buf_VecOpcodeTab +0
			sta	a0L
			lda	Vec_OpcodeTab    +1
			sta	Buf_VecOpcodeTab +1
			sta	a0H

			ldy	#$03
			lda	(a0L),y
			sta	OpcodeModes +0
			iny
			lda	(a0L),y
			sta	OpcodeModes +1
			iny
			lda	(a0L),y
			sta	OpcodeModes +2

			lda	OpcodeModes +1
			ora	OpcodeModes +2
			bne	:8
			jmp	:5

::8			lda	CurAdrModeLine +0
			bne	:9
			sta	CurAdrModeLine +1
			lda	#"a"
			sta	CurAdrModeLine +0

::9			jsr	PrepParam
			bcc	:10
			lda	curPass
			bne	:10
			jsr	Err_LabelNotFound
			jmp	Add1ToCurCodeLen

::10			lda	Flag_NoOperand
			bne	:12
			lda	CurCommandLen
			bne	:11
			lda	curPass
			bne	:11
			jsr	Err_BranchError
			lda	#$02
			sta	CurCommandLen
			rts

::11			jsr	FindCurAdrMode
			bcc	:12
			lda	curPass
			bne	:12
			jmp	Err_BadAdrMode

::12			lda	CurAdrModeLine +0	;Befehl auf "Akkumulator"
			cmp	#"a"			;beziehen (z.B. asl a) ?
			bne	Add1ToCurCodeLen	;Nein, weiter...
			lda	CurAdrModeLine +1
			beq	:13
			cmp	#" "
			bne	Add1ToCurCodeLen
::13			lda	#$00
			sta	CurCommandLen

;*** Länge des aktuellen Befehls +1.
:Add1ToCurCodeLen	inc	CurCommandLen
			rts

;*** Nach IF/ELSE/ENDIF-Opcode suchen.
:Check_IF		LoadW	a8,Code_IF
			jsr	:compare		;IF?
			bne	:5			; => Nein, weiter...

			lda	Flag_Aktiv_IF
			ora	Flag_Aktiv_ELSE
			beq	:1

			lda	#$0f			;Fehler: "IF geschachtelt".
			jmp	CopyErrCodeInTab

::1			jsr	ConvOp			;String in Zahl wandeln.
			bcc	:3			;Zahl gültig, weiter...

			lda	Flag_LabelNotOK
			bne	:2
			jmp	Err_LabelNotFound

::3			lda	Address +0
			ora	Address +1
			beq	:4

			lda	#$00
			b $2c
::4			lda	#$01
			sta	Ignore2_ELSE_ENDIF
			lda	#$01
			sta	Flag_Aktiv_IF
			clc
::2			rts

::5			LoadW	a8,Code_ELSE
			jsr	:compare		;ELSE?
			bne	:7			; => Nein, weiter...

			lda	Flag_Aktiv_IF
			bne	:6

			lda	#$10
			jsr	CopyErrCodeInTab
			clc
			rts

::6			lda	#$01
			sta	Ignore2_ELSE_ENDIF
			b $2c
::8			lda	#$00
			sta	Flag_Aktiv_ELSE

			lda	#$00
			sta	Flag_Aktiv_IF

			clc
			rts

::7			LoadW	a8,Code_ENDIF
			jsr	:compare		;ENDIF?
			bne	:9			; => Nein, weiter...

			lda	Flag_Aktiv_IF
			ora	Flag_Aktiv_ELSE
			bne	:8

			lda	#$11
			jsr	CopyErrCodeInTab
			clc
			rts

::9			sec
			rts

;--- String mit gepackten Daten vergleichen.
::compare		LoadW	a9,PackedDataLine
			ldx	#a8L
			ldy	#a9L
			jmp	CmpString

;*** Auf IF/ELSE/ENDIF testen.
;    Flags entsprechend setzen.
:Check_ENDIF		ldy	#$00
			ldx	#$00
::1			lda	CurTextLine,y
			sta	CurTextLine,x
			beq	:3
			cmp	#" "
			beq	:2
			inx
::2			iny
			bne	:1

::3			LoadW	a8,Code_IF
			jsr	:compare		;IF?
			bne	:4			; => Nein, weiter...

			lda	#$0f			;Fehler: "IF geschachtelt".
			jmp	CopyErrCodeInTab

::4			LoadW	a8,Code_ELSE
			jsr	:compare		;ELSE?
			beq	:5			; => Ja, ELSE-Flag setzen.

			LoadW	a8,Code_ENDIF
			jsr	:compare		;ENDIF?
			bne	:6			; => Nein, Ende...

			lda	#$00			;ELSE-Flag zurücksetzen.
			b $2c
::5			lda	#$01
			sta	Flag_Aktiv_ELSE
			lda	#$00
			sta	Ignore2_ELSE_ENDIF
			sta	Flag_Aktiv_IF		;IF-Flag zurücksetzen.

::6			rts

;--- Auf Pseudo-Opcodes "IF", "ELSE", "ENDIF".
::compare		LoadW	a9,CurTextLine
			ldx	#a8L
			ldy	#a9L
			jmp	CmpString

;*** Kein Ass-Opcode erkannt.
:NoCodeFound		ldy	#$00
::15			lda	PackedDataLine,y
			sta	StringValueLine,y
			beq	:16
			iny
			bne	:15

::16			jsr	ConvLabelToWord
			bcc	:2

			lda	Flag_LabelNotOK
			bne	:1
			jsr	Err_UnknownCom

::1			clc
			jmp	PrepForNextLine

::2			lda	Flag_CurLabelType
			bne	:3

			lda	#$09
			jsr	CopyErrCodeInTab
			clc
			jmp	PrepForNextLine

::3			ldx	MakroEntryStack
			inx
			ldy	MakroVecData_1,x
			sty	a0L
			ldx	#$09
::4			lda	#$00
			sta	MakroParIsDef,y
			iny
			dex
			bpl	:4

			lda	a0L
			asl
			sta	Vec_MakParDefTab

			lda	#$00
			sta	Poi_CurArgument
			sta	Poi_CurMakroPar
			sta	Cnt_MakroParameter

::5			ldy	#$00
::6			lda	CurAdrModeLine,y
			bne	:7
			jmp	:14
::7			iny
			cmp	#" "
			beq	:6

			ldx	#$00
::8			ldy	Poi_CurArgument
			lda	CurAdrModeLine,y
			cmp	#NULL
			beq	:9
			cmp	#","
			beq	:9
			sta	StringValueLine,x
			inc	Poi_CurArgument
			inx
			jmp	:8

::9			lda	#$00
			sta	StringValueLine,x
			cpx	#$00
			bne	:10
			sta	Address +0
			sta	Address +1
			beq	:11

::10			jsr	ConvStrg2Val
			bcc	:11

			LoadW	Address,diskBlkBuf

			lda	curPass
			bne	:11
			jsr	Err_LabelNotFound
			lda	#$01
			sta	Flag_LabelNotFound

::11			lda	Vec_MakParDefTab
			clc
			adc	Poi_CurMakroPar
			tay
			lda	Address +0
			sta	MakroParData -20,y
			iny
			lda	Address +1
			sta	MakroParData -20,y
			dey

			tya
			lsr
			tay
			lda	#$ff
			sta	MakroParIsDef,y
			inc	Poi_CurMakroPar
			inc	Poi_CurMakroPar

			ldy	Poi_CurArgument
			lda	CurAdrModeLine,y
			bne	:12

			lda	Poi_CurMakroPar
			sta	CurCommandLen
			dec	CurCommandLen
			jmp	:14

::12			inc	Poi_CurArgument
			ldx	Cnt_MakroParameter
			inx
			cpx	#$0b
			bne	:13

			lda	#$22
			jsr	CopyErrCodeInTab
			jmp	:14
::13			jmp	:5

::14			lda	#$00
			sta	CurCommandLen

;*** Start der Makrodefinition in Tabelle kopieren.
;    5 Makrosverschachtelungen möglich!
:SaveStartOfMakro	jsr	MakroNextEntry

			ldx	MakroEntryStack
			inc	MakroOpenFlags -1,x

			lda	MakroDefStart  +0
			sta	CurrentSektor  +0
			jsr	NewSetDevice

			lda	MakroDefStart  +1
			sta	CurrentSektor  +1
			lda	MakroDefStart  +2
			sta	CurrentSektor  +2
			lda	MakroDefStart  +3
			sta	CurrentSektor  +3
			jsr	GetCurrentSektor
			jmp	GetGW_TextLine

;*** Operand nach Zahl wandeln, mit LabelFehler-Auswertung.
:ConvPOp		jsr	ConvOp
			bcc	:1
			bit	Opt_POpcodeTest
			bpl	:1
			lda	curPass
			bne	:1
			jsr	Err_LabelNotFound
::1			rts

;*** Operand nach Zahl wandeln.
:ConvOp			ldy	#$00
::1			lda	CurAdrModeLine,y
			sta	StringValueLine,y
			beq	ConvStrg2Val
			iny
			bne	:1

;*** Labelwert ermitteln.
:ConvStrg2Val		LoadW	a0,StringValueLine	;Zeiger auf Stringspeicher.
			jsr	ConvString_Byte

			ldy	#$00
			ldx	#$00
			stx	Flag_NoOperand
::1			lda	StringValueLine,y	;Leerzeichen bis zum Argument
			sta	StringValueLine,x	;ausfiltern.
			beq	:3
			cmp	#" "
			beq	:2
			inx
::2			iny
			bne	:1

::3			ldy	#$00			;Textzeile zwischenspeichern.
::4			lda	StringValueLine  ,y
			sta	StringValueBuffer,y
			beq	:5
			iny
			bne	:4

::5			lda	#$ff			;"Klammer"-Flag löschen.
			sta	Pos_OpenBracket

			ldy	#$00
::6			lda	StringValueBuffer,y	;Zeichen aus Textzeile lesen.
			beq	:9			;Ende erreicht ? Ja, weiter...
			cmp	#"("			;Klammerausdruck öffnen ?
			bne	:7			;Nein, weiter...
			sty	Pos_OpenBracket		;Klammer-Textposition merken.
			beq	:8

::7			cmp	#")"			;Klammerausdruck schließen ?
			bne	:8			;Nein, weiter...
			sty	Pos_CloseBracket	;Klammer-Textposition merken.
			beq	:13

::8			iny				;Zeiger auf nächstes Byte.
			bne	:6			;Weitertesten.

::9			CmpBI	Pos_OpenBracket,$ff	;Klammerausdruck öffnen ?
			bne	:12			;Ja, weiter...

			jsr	doCalc			;Ausdruck berechnen.
			pha
			bcs	:11

			lda	OpcodeModes +1		;Auf Verzweigungsbefehl
			bne	:10			;testen (BCC,BEQ,BNE...)
			lda	OpcodeModes +2
			cmp	#$02
			bne	:10
			pla				;Verzweigungsbefehl
			jmp	GetBranchTarget		;gefunden, auswerten...

::10			clc
::11			pla
			rts

::12			lda	#$0b			;Fehler: "')' fehlt!"
			jmp	NumFormatError

::13			CmpBI	Pos_OpenBracket,$ff	;Klammerausdruck öffnen ?
			bne	:14			;Nein, weiter...

			lda	#$0c			;Fehler: "'(' fehlt!"
			jmp	NumFormatError

::14			ldy	Pos_OpenBracket
			iny
			ldx	#$00
::15			lda	StringValueBuffer,y	;Klammerausdruck in
			sta	StringValueLine  ,x	;Zwischenspeicher kopieren.
			cmp	#")"
			beq	:16
			inx
			iny
			bne	:15

::16			lda	#$00
			sta	StringValueLine,x
			jsr	doCalc			;Klammerausdruck berechnen.
			bcc	:17			;OK, weiter...

			jsr	SetFlagNoOperand
			sec
			rts

::17			MoveW	Address,r0		;Wert nach ":r0" kopieren.
			jsr	ConvWord_ASCII		;Nach ASCII wandeln.

			ldy	#$00
::18			lda	StringValueBuffer,y	;ASCII-Wert zurückschreiben.
			sta	StringValueLine,y
			iny
			cpy	Pos_OpenBracket
			bne	:18

			lda	#"$"
			sta	StringValueLine,y
			iny

			ldx	#$00
::19			lda	BufferHEX,x		;HEX-Wert in Textzeile
			sta	StringValueLine,y	;einfügen.
			iny
			inx
			cpx	#$04
			bne	:19

			ldx	Pos_CloseBracket
			inx
::20			lda	StringValueBuffer,x
			beq	:21
			sta	StringValueLine,y
			iny
			inx
			bne	:20

::21			sta	StringValueLine,y	;Nächste Ebene aus Textstring
			jmp	ConvStrg2Val		;konvertieren.

;*** Argument eines Assembler-Befehls auswerten.
;    Ein a-Argument (geoProgrammer) wird ignoriert.
;    Bsp. "asl a" wird zu "asl".
:PrepParam		lda	#$02			;2-Byte-Operand als Vorgabe.
			sta	Len_CurOperand

			ldx	OpcodeModes +1
			bne	:1
			ldx	OpcodeModes +2
			cpx	#$02
			bne	:1
			dec	Len_CurOperand		;1-Byte-Operand als Vorgabe.
::1			ldx	#$00
			stx	StringValueLine

			ldy	#$00
			sty	Flag_ByteStringOpen
::2			lda	CurAdrModeLine,y
			sta	CurAdrModeLine,x
			beq	:6
			cmp	#$22
			bne	:3
			lda	Flag_ByteStringOpen
			eor	#$ff
			sta	Flag_ByteStringOpen

::3			cmp	#" "
			bne	:4
			lda	Flag_ByteStringOpen
			beq	:5
::4			inx
::5			iny
			bne	:2
::6			stx	Poi_NewArgLine

			LoadW	a0,CurAdrModeLine
			jsr	ConvString_Byte

			lda	CurAdrModeLine +1
			bne	:7
			lda	CurAdrModeLine +0
			cmp	#"a"
			bne	:7
			lda	#$ff
			sta	CurCommandLen
			clc
			rts

::7			lda	#$ff
			sta	Poi_PointInCurArg

			ldy	#$00
::8			lda	CurAdrModeLine,y
			beq	:10
			cmp	#","
			bne	:9
			sty	Poi_PointInCurArg
			beq	:11
::9			iny
			bne	:8

::10			lda	#$ff
			sta	Poi_PointInCurArg
			bne	:12
::11			dey
			bpl	:12
			jmp	:18

::12			lda	CurAdrModeLine
			cmp	#"#"
			bne	:13

			lda	#$01
			sta	Len_CurOperand
			sta	Poi_1stArgByte
			ldx	Poi_NewArgLine
			inx
			stx	Buf_VecNewArgLine
			jmp	GetOpData

::13			cmp	#"("
			bne	:14

			lda	Poi_PointInCurArg
			cmp	#$ff
			bne	:16

			lda	#$01
			sta	Poi_1stArgByte
			ldx	Poi_NewArgLine
			dex
			stx	Buf_VecNewArgLine
			jmp	GetOpData

::14			lda	#$00
			sta	Poi_1stArgByte

			lda	Poi_PointInCurArg
			cmp	#$ff
			beq	:15

			lda	Poi_PointInCurArg
			sta	Buf_VecNewArgLine
			jmp	GetOpData

::15			lda	Poi_NewArgLine
			sta	Buf_VecNewArgLine
			jmp	GetOpData

::16			ldy	Poi_NewArgLine
			lda	CurAdrModeLine -1,y
			cmp	#")"
			beq	:17

			lda	#$01
			sta	Poi_1stArgByte
			ldx	Poi_PointInCurArg
			dex
			stx	Buf_VecNewArgLine
			jmp	GetOpData

::17			lda	#$01
			sta	Poi_1stArgByte
			lda	Poi_PointInCurArg
			sta	Buf_VecNewArgLine
			jmp	GetOpData

::18			lda	#"("
			sta	CurAdrModeLine +0
			sta	CurAdrModeLine +1
			lda	#NULL
			sta	CurAdrModeLine +2
			lda	#$02
			sta	CurCommandLen
			clc
			rts

;*** Unmittelbare Adressierung (lda #Wert).
:GetOpData		ldx	#$00
			ldy	Poi_1stArgByte
::1			lda	CurAdrModeLine,y
			sta	StringValueLine,x
			beq	:2
			lda	#TAB
			sta	CurAdrModeLine,y
			inx
			iny
			cpy	Buf_VecNewArgLine
			bne	:1

::2			lda	#$00
			sta	StringValueLine,x
			jsr	ConvStrg2Val
			php
			sta	CurCommandLen
			ldy	Poi_NewArgLine
			tya
			tax
			inx
::3			lda	CurAdrModeLine,y
			sta	CurAdrModeLine,x
			cmp	#$09
			beq	:4
			dex
			dey
			bpl	:3

::4			ldy	#$00
::5			lda	CurAdrModeLine,y
			cmp	#TAB
			beq	:6
			iny
			bne	:5

::6			lda	#"$"
			sta	CurAdrModeLine +0,y
			ldx	CurCommandLen
			cpx	#$02
			bne	:7
			sta	CurAdrModeLine +1,y

::7			ldy	#$00
			ldx	#$00
::8			lda	CurAdrModeLine,y
			sta	CurAdrModeLine,x
			beq	:10
			cmp	#TAB
			beq	:9
			inx
::9			iny
			bne	:8

::10			lda	CurCommandLen
			cmp	#$02
			bne	:11
			lda	Len_CurOperand
			sta	CurCommandLen
::11			plp
			tax
			rts

;*** Länge des Arguments für aktuellen Assemblerbefehl ermitteln.
:GetMaxLenAssOp		jsr	ConvLabelToWord
			bcs	:2

			lda	Flag_CurLabelType
			beq	:1

			lda	#$0a
			jsr	CopyErrCodeInTab
			lda	#$01
			sta	Flag_LabelNotOK
			jmp	:2

::1			MoveW	Buf_Address,Address
			clc
			jmp	ChkLen_CurOperand

::2			MoveW	Buf_VecOpcodeTab,r0
			ldy	#$04
			lda	(r0L),y
			bne	:3
			iny
			lda	(r0L),y
			cmp	#$02
			bne	:3
			lda	#$01
			rts

::3			lda	#$02
			sec
			rts

;*** Opcode für Adressierungsart finden.
:FindCurAdrMode		ldy	#$00
			lda	#$00
			sta	Vec_AdrModeEntry
::1			lda	CurAdrModeLine,y
			beq	:3
			cmp	#" "
			beq	:2
			iny
			bne	:1

::2			lda	#$00
			sta	CurAdrModeLine,y
::3			sty	Len_AdrModeEntry

			LoadW	Vec_AdrModeTab,AdrModeTab
::4			MoveW	Vec_AdrModeTab,r0

			ldy	#$00
			lda	(r0L),y
			sta	Len_AdrStrgEntry	;Länge Adressierungsstring.
			cmp	#$ff			;Tabellenende erreicht ?
			bne	:5			;Nein, weiter...
			jmp	:15

::5			cmp	Len_AdrModeEntry	;Länge prüfen.
			beq	:6			;Stimmt, weiter...
			jmp	:11

::6			lda	Vec_AdrModeTab +0	;Zeiger auf Adressierungs-
			clc				;textstring richten.
			adc	#$02
			sta	Vec_AdrModeTab +0
			bcc	:7
			inc	Vec_AdrModeTab +1

::7			MoveW	Vec_AdrModeTab,r3	;Mit aktuellem Argument
			LoadW	r4,CurAdrModeLine	;vergleichen.
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			beq	:8			;Stimmt, weiter...
			jmp	:13

::8			SubVW	1,Vec_AdrModeTab

			ldy	Vec_AdrModeEntry

			lda	BitMask_Byte1,y		;Adressierungsmodi #0 bis #7
			and	OpcodeModes+1		;überprüfen.
			beq	:9			;Nicht möglich, weiter..
			jmp	:10			;Möglich, Opcode berechnen.

::9			lda	BitMask_Byte2,y		;Adressierungsmodi #8 bis #14
			and	OpcodeModes+2		;überprüfen.
			bne	:10			;Möglich, Opcode berechnen.
			jmp	:12			;Nicht möglich, weiter..

::10			MoveW	Vec_AdrModeTab,r0	;Opcode berechnen.

			ldy	#$00
			lda	(r0L),y
			ora	OpcodeModes +0
			sta	CurCommand  +0
			lda	Address     +0
			sta	CurCommand  +1
			lda	Address     +1
			sta	CurCommand  +2
			lda	#$00
			sta	Flag_AdrModeFound
			clc
			rts

::11			inc	Len_AdrStrgEntry
::12			inc	Len_AdrStrgEntry
::13			inc	Len_AdrStrgEntry
			inc	Vec_AdrModeEntry

			lda	Vec_AdrModeTab +0	;Zeiger auf nächsten
			clc				;Adressierungsmodus.
			adc	Len_AdrStrgEntry
			sta	Vec_AdrModeTab +0
			bcc	:14
			inc	Vec_AdrModeTab +1
::14			jmp	:4

::15			lda	Flag_AdrModeFound
			beq	DefNextAdrMode
			lda	#$00
			sta	Flag_AdrModeFound
			sec
			rts

;*** Falls aktueller Adressierungsmodus als Byte angegeben wurde, und diese
;    Adressierungsart nicht möglich ist, Modus "Word" definieren.
:DefNextAdrMode		ldy	#$00
::1			lda	CurAdrModeLine,y
			beq	:2
			cmp	#"$"
			beq	:3
			iny
			bne	:1
::2			sec
			rts

::3			sty	Poi_AdrModeLine
::4			iny
			lda	CurAdrModeLine   ,y
			beq	:5
			cmp	#"$"
			beq	:2
			bne	:4

::5			iny
::6			lda	CurAdrModeLine -1,y
			sta	CurAdrModeLine   ,y
			dey
			cpy	Poi_AdrModeLine
			bne	:6

			ldy	Poi_AdrModeLine
			iny
			lda	#"$"
			sta	CurAdrModeLine   ,y

			inc	CurCommandLen

			lda	#$01
			sta	Flag_AdrModeFound
			jmp	FindCurAdrMode

;*** Aktuelles Label testen.
;    In Pass #1 in Tabelle einfügen.
:ChkCurLabel		lda	curPass
			bne	:1
			clc
			rts

::1			LoadW	r0,CurLabelName
			jsr	TestLabelName
			bcc	:2
			jmp	:9

::2			lda	CurLabelName
			cmp	#":"			;Lokales Label definieren ?
			bne	:3			;Nein, weiter...
			lda	Flag_CurLabelExtern	;Als "extern" markiert ?
			beq	:3			;Nein, weiter...
			lda	#$14			;Fehler "Lok. Label als extern"
			jsr	CopyErrCodeInTab
			clc
			rts

::3			MoveW	Buf_Address,LabelValue

			ldy	#$00
::4			lda	CurLabelName,y		;Labellänge testen.
			beq	:5			;Labels dürfen nicht länger als
			cmp	#" "			;63 Zeichen sein!
			beq	:5
			iny
			bne	:4

::5			sty	Len_CurLabelName
			cpy	#$40
			bcc	:6
			lda	#$15			;Fehler "Label zu lang!"
			jsr	CopyErrCodeInTab
			clc
			rts

::6			lda	CurLabelName
			cmp	#":"			;Lokales Label definiert ?
			bne	:8			;Nein, weiter...

			lda	Len_CurLabelName
			pha
			lda	Flag_CurLabelType
			pha

			ldy	#$00
::11			lda	CurLabelName,y
			sta	StringValueLine,y
			beq	:12
			iny
			bne	:11

::12			jsr	ConvLabelToWord
			bcs	:7

			pla
			pla
			jsr	Err_LabelUsed		;Fehler:Label bereits definiert.
			clc
			rts

::7			pla
			sta	Flag_CurLabelType
			pla
			sta	Len_CurLabelName

			jsr	SetFlag_LabelInMak1

			lda	Len_CurLabelName
			clc
			adc	#$03
			sta	Len_CurLabelEntry

			lda	Vec_StartLabelTab +0
			sta	a3L
			lda	Vec_StartLabelTab +1
			sta	a3H
			jmp	InsLabel2CharArea

::8			sec
			sbc	#$41			;Zeiger auf Tabelle mit den
			bpl	:10			;sortierten Labels berechnen.

::9			lda	#$08			;Fehler: "Ungültige Labelbez."
			jsr	CopyErrCodeInTab
			clc
			rts

::10			asl
			sta	Poi_SortLabelTab	;Tabellenzeiger speichern.

			lda	Len_CurLabelName
			clc
			adc	#$03
			clc
			adc	Flag_CurLabelType
			sta	Len_CurLabelEntry

			ldy	Poi_SortLabelTab	;Labels mit gleichem
			lda	SortLabelVec +0,y	;Anfangsbuchstaben vorhanden ?
			cmp	SortLabelVec +2,y
			bne	ExistLabelInTab		;Ja, weiter...
			lda	SortLabelVec +1,y
			cmp	SortLabelVec +3,y
			bne	ExistLabelInTab		;Ja, weiter...
			jmp	AddNewCharLabel		;Neuen Buchstaben einfügen.

;*** Ist Label bereits vorhanden ?
:ExistLabelInTab	ldy	Poi_SortLabelTab
			lda	SortLabelVec +0,y
			sta	a3L
			lda	SortLabelVec +1,y
			sta	a3H

::1			ldy	#$00
			lda	(a3L),y
			and	#$3f
			tax
			inc	Len_CurLabelName
			iny

::2			lda	CurLabelName -1,y
			cmp	(a3L),y
			bne	:3
			dex
			beq	:4
			iny
			cpy	Len_CurLabelName
			bne	:2

			dec	Len_CurLabelName	;Label nicht gefunden...
			jmp	InsLabel2CharArea

::3			php
			dec	Len_CurLabelName
			plp
			bcs	:5
			jmp	InsLabel2CharArea

::4			iny
			cpy	Len_CurLabelName
			php
			dec	Len_CurLabelName
			plp
			bne	:5

			jsr	Err_LabelUsed		;Fehler:Label bereits definiert.

			ldy	#$00
::8			lda	CurLabelName,y
			sta	StringValueLine,y
			beq	:9
			iny
			bne	:8

::9			jsr	ConvLabelToWord

			lda	a3L
			sta	Vec_StartLabelTab +0
			lda	a3H
			sta	Vec_StartLabelTab +1
			clc
			rts

::5			ldy	#$00
			lda	(a3L),y
			and	#%10000000
			php
			lda	(a3L),y
			and	#%10111111
			plp
			beq	:6
			and	#%01111111
			clc				;Ein Zeichen zusätzlich für
			adc	#$02			;lokale Labels => ":".

::6			clc				;Zeiger auf nächstes Label in
			adc	#$03			;aktuellem Bereich berechnen.
			clc
			adc	a3L
			sta	a3L
			bcc	:10
			inc	a3H

::10			ldy	Poi_SortLabelTab	;Bereichsende erreicht ?
			iny
			iny
			lda	a3L
			cmp	SortLabelVec +0,y
			bne	:7			;Nein, weiter...
			lda	a3H
			cmp	SortLabelVec +1,y
			bne	:7			;Nein, weiter...
			jmp	InsLabel2CharArea	;Label noch nicht vorhanden.

::7			ldy	#$01
			lda	(a3L),y
			cmp	#":"
			beq	:5
			jmp	:1

;*** Neuen Buchstabenbereich anlegen.
:AddNewCharLabel	ldy	Poi_SortLabelTab
			lda	SortLabelVec +2,y
			sta	a3L
			lda	SortLabelVec +3,y
			sta	a3H

:InsLabel2CharArea	lda	#$01
			sta	Flag_LabelIsDefined

			lda	Len_CurLabelEntry
			jsr	TestSymbTabFull

			ldy	Len_CurLabelEntry
			jsr	InsSpaceForLabel

			lda	Len_CurLabelEntry
			ldx	Poi_SortLabelTab
			inx
			inx
			jsr	MovSLabelStartAdr

			ldy	#$00
			lda	Len_CurLabelName
			ldx	Flag_CurLabelExtern
			beq	:1
			ora	#%01000000		;Label als "extern" markieren.
::1			sta	(a3L),y

			MoveW	a3,VecCurLabelBuf2	;Zeiger auf aktuelles
							;Label zwischenspeichern.

			inc	a3L			;Zeiger auf Labelnamen
			bne	:2			;berechnen.
			inc	a3H

::2			LoadW	r3,CurLabelName

			ldx	Len_CurLabelName
			dex
			ldy	#$00
::3			lda	CurLabelName,y
			sta	(a3L),y
			iny
			dex
			bpl	:3

			lda	a3L
			clc
			adc	Len_CurLabelName
			sta	a3L
			bcc	:5
			inc	a3H

::5			ldy	#$00
			lda	LabelValue +0
			sta	(a3L),y
			iny
			lda	LabelValue +1
			sta	(a3L),y
			dey

			tya
			clc
			adc	a3L
			sta	Buf_VecStLabelTab +0
			lda	a3H
			adc	#$00
			sta	Buf_VecStLabelTab +1

			lda	CurLabelName
			cmp	#":"
			beq	:4

			lda	Buf_VecStLabelTab +0
			clc
			adc	#$02
			sta	Vec_StartLabelTab +0
			lda	Buf_VecStLabelTab +1
			adc	#$00
			sta	Vec_StartLabelTab +1

::4			clc
			rts

;*** Startadressen der Bereiche mit sortierten Labels verschieben.
:MovSLabelStartAdr	sta	:2 +1

::1			lda	SortLabelVec +0,x
			clc
::2			adc	#$ff
			sta	SortLabelVec +0,x
			bcc	:3
			inc	SortLabelVec +1,x
::3			inx
			inx
			cpx	#$7c
			bne	:1
			rts

;*** Label in Tabelle suchen und Wert ermitteln.
:ConvLabelToWord	ldy	#$00
			sty	Flag_CurLabelLokal
			sty	Flag_LabelNotOK

			LoadW	r0,StringValueLine
			jsr	TestLabelName
			bcs	:4

::1			lda	StringValueLine,y
			beq	:2
			cmp	#" "
			beq	:2
			iny
			bne	:1

::2			sty	Len_CurLabelName
			lda	StringValueLine
			cmp	#":"
			bne	:3

			jsr	SetFlag_LabelInMak2

			MoveW	Vec_LokalLabels,a3

			lda	#$ff
			sta	Flag_CurLabelLokal
			bne	:7

::3			sec
			sbc	#$41
			bpl	:5

::4			lda	#$01
			sta	Flag_LabelNotOK
			lda	#$08			;Fehler: "Ungültige Labelbez."
			jmp	CopyErrCodeInTab

::5			asl
			sta	Vec_LabelMemory

			tay
			lda	SortLabelVec +0,y
			cmp	SortLabelVec +2,y
			bne	:6
			lda	SortLabelVec +1,y
			cmp	SortLabelVec +3,y
			bne	:6
			sec
			rts

::6			lda	SortLabelVec +0,y
			sta	a3L
			lda	SortLabelVec +1,y
			sta	a3H
::7			lda	Flag_CurLabelLokal
			beq	:8
			ldy	#$01
			lda	(a3L),y
			cmp	#":"
			beq	:8
			sec
			rts

::8			ldy	#$00
			lda	(a3L),y
			sta	Flag_CurLabelType
			and	#$3f
			cmp	Len_CurLabelName
			bne	:11

			tax

			inc	a3L
			bne	:9
			inc	a3H

::9			lda	StringValueLine,y
			cmp	(a3L),y
			bne	:12
			iny
			dex
			bne	:9

			lda	Flag_CurLabelType
			and	#$80
			bne	:17

			lda	(a3L),y
			sta	Buf_Address +0
			iny
			lda	(a3L),y
			sta	Buf_Address +1
			iny
			tya
			clc
			adc	a3L
			sta	a3L
			bcc	:10
			inc	a3H
::10			lda	#$00
			sta	Flag_CurLabelType
			clc
			rts

::17			lda	(a3L),y
			sta	MakroDefStart +0
			iny
			lda	(a3L),y
			sta	MakroDefStart +1
			iny
			lda	(a3L),y
			sta	MakroDefStart +2
			iny
			lda	(a3L),y
			sta	MakroDefStart +3
			iny
			tya
			clc
			adc	a3L
			sta	a3L
			bcc	:18
			inc	a3H
::18			lda	#$ff
			sta	Flag_CurLabelType
			clc
			rts

::11			inc	a3L
			bne	:12
			inc	a3H

::12			lda	Flag_CurLabelType
			and	#$3f
			clc
			adc	#$02
			tax
			lda	Flag_CurLabelType
			bpl	:13
			inx
			inx

::13			txa
			clc
			adc	a3L
			sta	a3L
			bcc	:19
			inc	a3H

::19			ldy	Vec_LabelMemory
			iny
			iny
			lda	a3L
			cmp	SortLabelVec +0,y
			bne	:14
			lda	a3H
			cmp	SortLabelVec +1,y
			bne	:14
			sec
			rts

::14			lda	a3L
			cmp	SortLabelVec +$7a
			bne	:15
			lda	a3H
			cmp	SortLabelVec +$7b
			beq	:16
::15			jmp	:7

::16			sec
			rts

;*** MegaAssembler-PseudoOpcodes.
:POpcodeTab		b "bwonsteg/cifdazvpqrjhklxyu"
			b NULL

;*** Sprungziele für OpCodes
;* = Neue Funktionen in MegaAssV3
:POpcodeAdr		w DefByteTab			; b  8-Bit-Wert in Code einfügen
			w DefWordTab			; w 16-Bit-Wert in Code einfügen
			w DefLoadAdr			; o Programm-Ladeadresse
			w DefFileName			; n Dateiname
			w DefBlockTab			; s Anzahl Leerbytes einfügen
			w DefTextFile			; t externe Code-Datei einlesen
			w DefUpfillMem			; e Adr.prüfen/00-Bytes einfügen
			w DefCheckAdr			; g Adr.prüfen
			w DefEndMakro			; / Makro abschliesen
			w DefFileClass			; c GEOS-Klasse festlegen
			w DefObjIcon			; i Icon für Objektdatei
			w DefGEOS_Type			; f GEOS-Dateityp festlegen
			w DefDataFile			; d seq.Datendatei einbinden
			w DefAutorName			; a Autor
			w DefScrnFlag			; z C128 Bildschirmmodus
			w DefVLIRFile			; v VLIR-Datensatz einbinden
			w DefStartAdr			; p Startadresse festlegen
			w DefEndAdr			; q Endadresse festlegen
			w DefMaxEndAdr			;*r Max. Endadresse festlegen
			w DefHdrIcon			; j Grafik für Header einfügen
			w DefInfoText			;*h Text für Header festlegen
			w DefShortDate			;*k yymmdd
			w DefLongDate			;*l yy.mm.dd
			w DefShortTime			;*x hhmm
			w DefLongTime			;*y hh:mm
			w DefPhotoScrap			;*u PhotoScrap-Datei einbinden

;******************************************************************************
;*** Beginn Symbolspeicher.
;******************************************************************************
:StartLabelArea
:EndLabelArea		= MAX_LABEL_AREA

;******************************************************************************
;*** Initialisierung MegaAssembler.
;******************************************************************************
;*** Die folgenden Daten werden nur direkt nach dem
;    Start benötigt und werden danach durch die
;    Symboltabelle überschrieben.
:StartMegaAss		tsx
			stx	StackVector

;*** Bildschirm löschen.
:InitScreen		jsr	SetXpos40_80

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10
			b	$c7
			w	$0000
:X99			w	$013f

			lda	screencolors
			pha
			and	#%00001111
			sta	r0L
			pla
			asl
			asl
			asl
			asl
			ora	r0L
			sta	:1

			jsr	i_FillRam
			w	920
			w	COLOR_MATRIX +2*40
::1			b	$bf

;*** Variablen-Datei einlesen.
			jsr	FindMegaAss		;MegaAssembler suchen.
			LoadW	r0,NameMegaAss
			jsr	OpenRecordFile		;MegaAss-Datei öffnen.
			lda	#$02
			jsr	PointRecord		;Zeiger auf VLIR-Modul.
			LoadW	r7,$a280
			LoadW	r2,($bf3f - $a280)
			jsr	ReadRecord		;Programmteil einlesen.
			jsr	CloseRecordFile		;VLIR-Datei schliesen.

			jsr	SetXpos40_80

;*** Dateinamen für "Symboltabelle", "ext. Symboltabelle" und
;    "Fehlerliste" erzeugen.
:DefSysFiles		ldy	#$00
::1			lda	SelectedFile,y		;Name des Quelltextes als
			sta	ErrFileName ,y		;Vorgabe kopieren.
			sta	SymFileName ,y
			sta	ExtFileName ,y
			beq	:2
			iny
			bne	:1
::2			tya
			bne	:3
			rts

::3			cpy	#$0c
			bcc	:4
			ldy	#$0c

::4			lda	#"."			;"." als Trennung einfügen.
			sta	ErrFileName,y
			sta	SymFileName,y
			sta	ExtFileName,y
			iny
			lda	#"e"			;".err"-Kennung erzeugen.
			sta	ErrFileName,y
			lda	#"s"			;".sym"-Kennung erzeugen.
			sta	SymFileName,y
			lda	#"e"			;".ext"-Kennung erzeugen.
			sta	ExtFileName,y
			iny
			lda	#"r"			;".err"-Kennung erzeugen.
			sta	ErrFileName,y
			lda	#"y"			;".sym"-Kennung erzeugen.
			sta	SymFileName,y
			lda	#"x"			;".ext"-Kennung erzeugen.
			sta	ExtFileName,y
			iny
			lda	#"r"			;".err"-Kennung erzeugen.
			sta	ErrFileName,y
			lda	#"m"			;".sym"-Kennung erzeugen.
			sta	SymFileName,y
			lda	#"t"			;".ext"-Kennung erzeugen.
			sta	ExtFileName,y
			iny
			lda	#$00
			sta	ErrFileName,y		;Ende Dateiname markieren.
			sta	SymFileName,y
			sta	ExtFileName,y

;*** Infoblock definieren.
			jsr	i_MoveData
			w	 Hdr_IconDataOrg
			w	 Hdr_IconData
			w	(Hdr_IconDataEnd - Hdr_IconDataOrg)
;			lda	Hdr_IconDataEnd
			lda	#$00
			ldx	#$04
			sta	ProgLoadAdr    +0
			stx	ProgLoadAdr    +1
			sta	ProgEndAdr     +0
			stx	ProgEndAdr     +1
			sta	ProgStartAdr   +0
			stx	ProgStartAdr   +1
			sta	ProgUserEndAdr +0
			sta	ProgUserEndAdr +1
			sta	ProgMaxEndAdr  +0
			sta	ProgMaxEndAdr  +1
			sta	LastTestAdr    +0
			sta	LastTestAdr    +1

			sta	Hdr_LoadAdr    +0
			stx	Hdr_LoadAdr    +1
			sta	Hdr_EndAdr     +0
			stx	Hdr_EndAdr     +1
			sta	Hdr_StartAdr   +0
			stx	Hdr_StartAdr   +1

			jsr	i_FillRam
			w	(Hdr_EndData - Hdr_Class)
			w	 Hdr_Class
			b	$00

			lda	#$80 ! PRG
			sta	Hdr_CBM_Type
			lda	#APPLICATION
			sta	Hdr_GEOS_Type
			lda	#SEQUENTIAL
			sta	Hdr_FileStruct
			lda	#$00
			sta	Hdr_ScrnMode
			lda	#"?"
			sta	Hdr_Class  +0
			sta	Hdr_Class  +1
			sta	Hdr_Class  +2
			sta	Hdr_Author +0
			sta	Hdr_Author +1
			sta	Hdr_Author +2

			lda	Opt_ErrFileDrive
			jsr	NewSetDevice		;Laufwerk aktivieren.
			jsr	NewOpenDisk		;Diskette öffnen.

			lda	#< ErrFileName
			ldx	#> ErrFileName
			jsr	doDeleteFile		;Fehlerdatei löschen.

			lda	Opt_SymbTabDrive
			jsr	NewSetDevice		;Laufwerk aktivieren.
			jsr	NewOpenDisk		;Diskette öffnen.

			lda	#< SymFileName
			ldx	#> SymFileName
			jsr	doDeleteFile		;Symboltabelle löschen.

			lda	#< ExtFileName
			ldx	#> ExtFileName
			jsr	doDeleteFile		;ext. Symboltabelle löschen.

			lda	#$ff
			sta	Flag_SymbFileOK
			sta	Flag_ExtSFileOK

			lda	Opt_SourceDrive
			jsr	NewSetDevice		;Laufwerk aktivieren.
			jsr	NewOpenDisk

;*** Assembler initialisieren.
			lda	#$00
			sta	Flag_DataOrText
			sta	NameOfTextFile
			sta	Flag_POpcode_O
			sta	ErrCount
			sta	Flag_SourceInclude
			sta	Flag_ExtLabelFound
			sta	Ignore2_ELSE_ENDIF
			sta	Flag_AssembleError
			sta	Flag_StopAssemble
			sta	currentMode

;*** Laufwerkstabelle erzeugen.
:InitDriveTab		ldx	#$00
			stx	r1L
			stx	r1H
			lda	Opt_SourceDrive
			sta	FindFileDriveTab +0
			sta	r1L
			inx
			lda	Opt_TargetDrive
			cmp	FindFileDriveTab +0
			beq	:5
			sta	FindFileDriveTab +1
			sta	r1H
			inx
::5			ldy	#$00
::1			lda	#$00
			sta	FindFileDriveTab,x
			tya
			clc
			adc	#$08
			sta	r0L
			cmp	r1L
			beq	:2
			cmp	r1H
			beq	:2
			lda	driveType,y
			bpl	:2
			lda	r0L
			sta	FindFileDriveTab,x
			inx
::2			iny
			cpy	#$04
			bne	:1

			ldy	#$00
::3			tya
			clc
			adc	#$08
			sta	r0L
			cmp	r1L
			beq	:4
			cmp	r1H
			beq	:4
			lda	driveType,y
			beq	:4
			bmi	:4
			lda	r0L
			sta	FindFileDriveTab,x
			inx
::4			iny
			cpy	#$04
			bne	:3

;*** Tabelle mit Zeiger auf Labelsadressen löschen.
:ClrLabelVec		ldy	#$7f
::1			lda	#>StartLabelArea
			sta	SortLabelVec +0,y
			dey
			lda	#<StartLabelArea
			sta	SortLabelVec +0,y
			dey
			bpl	:1

			lda	#<StartLabelArea
			ldx	#>StartLabelArea
			sta	Vec_StartLabelTab +0
			stx	Vec_StartLabelTab +1
			sta	Vec_LokalLabels   +0
			stx	Vec_LokalLabels   +1
			sta	Vec_StartLabels2  +0
			stx	Vec_StartLabels2  +1

			lda	#$00
			sta	Vec_EndLabels2
			sta	Vec_EndLabels2 +1

			jsr	ClrMakOpenFlags

			ldy	#$ff
::3			sta	ErrCodeTab,y
			iny
			bne	:3
			sta	ErrCount
			sta	ErrOverflow

			lda	#$ff			;Ende Tabelle markieren.
			sta	ErrCodeTab

;*** SourceCode-Datei öffnen.
:StartAssemble		lda	Opt_SourceDrive
			sta	VLIR_Drive
			jsr	NewSetDevice
			jsr	NewOpenDisk

			lda	#$00
			sta	VLIR_Record		;Zeiger auf Datensatz #1.

			lda	#$01
			sta	curPass
			lda	#"1"
			sta	X75a +2

			LoadW	r6,SelectedFile		;Zeiger auf Quelltextname.
			jsr	FindFile		;Quelltext öffnen.
			txa
			beq	:1
			lda	#<DlgSourceNotFound
			ldy	#>DlgSourceNotFound
			jmp	FatalError

::1			lda	dirEntryBuf +1
			ldx	dirEntryBuf +2
			sta	VLIR_HdrSektor +0
			stx	VLIR_HdrSektor +1

			jsr	PrintStatusLine
			jmp	StartPass_1_2

;*** 40/80-Zeichen Words definieren.
:initW			ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			ora	r1L
			beq	initErr
			iny
			lda	(r0L),y
			sta	r2L
			iny
			lda	(r0L),y
			sta	r2H
			ldy	#$00
			lda	r2L
			sta	(r1L),y
			iny
			lda	r2H
			sta	(r1L),y

			lda	r0L
			clc
			adc	#4
			sta	r0L
			bcc	:2
			inc	r0H

::2			jmp	initW

:initErr		rts

;*** 40/80-Zeichen Bytes definieren.
:initB			ldy	#$00
			lda	(r0L),y
			sta	r1L
			iny
			lda	(r0L),y
			sta	r1H
			ora	r1L
			beq	initErr

			iny
			lda	(r0L),y
			ldy	#$00
			sta	(r1L),y

			lda	r0L
			clc
			adc	#3
			sta	r0L
			bcc	:1
			inc	r0H

::1			jmp	initB

;*** Bildschirm-Koordinaten anpassen.
:SetXpos40_80		lda	c128Flag		;C128-Modus ?
			bpl	:1			;Nein, 40-Zeichen aktivieren.
			lda	graphMode		;80-Zeichen-Modus aktiv ?
			bmi	:2			;Ja, weiter...

::1			LoadW	r0,:40w			;40-Zeichen-Modus.
			jsr	initW
			LoadW	r0,:40b
			jmp	initB

::2			LoadW	r0,:80w			;80-Zeichen-Modus.
			jsr	initW
			LoadW	r0,:80b
			jmp	initB

;*** 40-Zeichen-Daten.
::40w			w X08 +1           ,CreateIcon40
			w X09 +1           ,CreateIcon40
			w X31 +2           ,$013f
			w X37              ,$0008
			w X72              ,$0020
			w X73              ,$000c
			w X74              ,$00c0
			w X75              ,$0108
			w X76              ,$0120
			w X78              ,$0069
			w DlgFileExist +5  ,$013f
			w X99              ,$013f
			w $0000

::40b			w DlgFileExist +13
			b $1b
			w DlgFileExist +16
			b $22
			w $0000

;*** 80-Zeichen-Daten.
::80w			w X08 +1           ,CreateIcon80
			w X09 +1           ,CreateIcon80
			w X31 +2           ,$027e
			w X37              ,$0010
			w X72              ,$0040
			w X73              ,$0018
			w X74              ,$0180
			w X75              ,$0210
			w X76              ,$0240
			w X78              ,$00d2
			w DlgFileExist +5  ,$027f
			w X99              ,$027f
			w $0000

::80b			w DlgFileExist +13
			b $9b
			w DlgFileExist +16
			b $a2
			w $0000
