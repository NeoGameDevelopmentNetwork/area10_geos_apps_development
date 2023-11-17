; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;MegaAssembler
;Globale Systemfunktionen für
;Compiler und Linker.
if .p
			t "TopSym"
			t "TopMac"
			t "src.MegaAss0.ext"
endif

			n "mod.#2"
			o $a280
			p $a280

;*** Zeiger auf akt. Sektor in Quellcode-Datei.
.ProgCodeBuf		s 256
.CurPCodeTr		b $00				;Quellcode-Datei: Zeiger auf Track.
.CurPCodeSe		b $00				;Quellcode-Datei: Zeiger auf Sektor.
.Poi_PCodeBuf		b $00				;Quellcode-Datei: Zeiger auf Byte/Sektor.

;*** Zeiger auf aktuyellen Pass.
.curPass		b $00				;$01 = Pass#1, $00 = Pass#2.

;*** Modus für aktuelle Text-Datei.
.Flag_SourceInclude	b $00				;$00 = Quelltext, $FF = IncludeText.
.Flag_DataOrText	b $00				;$00 = Datenfile, $FF = IncludeText

;*** Zwischenspeicher für Zeiger auf Dateiname.
.FileNmVecBuf		w $0000

;*** Laufwerke für Suche nach GW-Datei.
.FindFileDriveTab	s $04

;*** Angaben über geöffnete Makros.
.MakroEntryStack	b $00				;Makro-Verschachtelungstiefe.
.MakroOpenFlags		s MaxOpenMakros
.MakroParData		s MaxOpenMakros *2 *10
.MakroDefTab		s MaxOpenMakros *4
.MakroParIsDef		s MaxOpenMakros *10
.MakroDefStart		b $00				;Laufwerk.
			b $00				;Zwischenspeicher für Angaben der akt.
			b $00				;Include-Datei beim ermitteln der Start-
			b $00				;Daten des akt. Makros.

.MakroVecData_1		b 00,10,20,30,40, 50
.MakroVecData_2		b 00,20,40,60,80,100

;*** Aktuelles Text-Laufwerk.
.VLIR_Drive		b $00
.VLIR_Record		b $00				;Aktueller VLIR-Datensatz.
.VLIR_HdrSektor		b $00,$00
.Vec_CurFileName	w $0000

;*** Aktueller Sektor.
.CurTextLine		s 200
.CurrentSektor		s $04

;*** Startadresse aktuelle Textzeile.
.CurrentTextLine	s $04				;Zeiger auf Start-Sektor.
.Len_CurTextLine	b $00				;Länge der aktuellen Textzeile.
.Poi_CurTextLine	b $00

;*** Zwischenspeicher für IncludeTexte.
.IncludeFileStack	b $00				;Zeiger auf Stack-Speicher.
.IncludeDataDrive	s $05				;Laufwerk.
.IncludeDataTrack	s $05				;Track.
.IncludeDataSektor	s $05				;Sektor.
.IncludeDataByte	s $05				;Byte.
.IncludeVLIR_Hdr	s $05* 2			;VLIR_Sektor.
.IncludeDataRecord	s $05				;VLIR-Zeiger.
.IncludeFileName	s $05*16			;Dateinamen a 16 Byte.

;*** IF-Abfrage-Variablen.
.Ignore2_ELSE_ENDIF	b $00
.Flag_Aktiv_IF		b $00
.Flag_Aktiv_ELSE	b $00

.Code_IF		b "if"   ,NULL
.Code_ELSE		b "else" ,NULL
.Code_ENDIF		b "endif",NULL

;*** Flags für PseudoOpcodes.
.Flag_POpcode_J		b $00				;"J": $FF = Opcode in Bearbeitung.
.Flag_POpcode_I		b $00				;"I": $FF = Opcode in Bearbeitung.
.Flag_POpcode_O		b $00				;"O": $01 = Opcode bereits definiert.
.Flag_DateTimeMode	b $00
.Poi_EntryVLIR		b $00				;"V": Zeigt auf Datensatz VLIR-Datendatei.

;*** Flags für Textzeile.
.Flag_NoTextLines	b $00				;$01 = Keine weiteren Quelltext-Zeilen.
.Flag_EndOfTextFile	b $00				;$01 = Quelltext-Ende erreicht.
.Flag_TxtLineEmpty	b $00
.Flag_TextStringOpen	b $00				;$FF = String in Textzeile geöffnet.

;*** Fehler-Flags.
.Flag_SymbTabFull	b $00
.Flag_AdrModeFound	b $00
.Flag_ParityError	b $00				;$01 = Parity-Error.
.Flag_NoOperand		b $00				;$01 = Kein Operand angegeben.
.Flag_StopSOpcode	b $00
.Flag_MakParCntErr	b $00				;$01 = Anzahl Makroparameter falsch.
.Flag_CurLabelType	b $00				;$01 = Labels als Makroname mißbraucht.
.Flag_CurLabelLokal	b $00
.Flag_CurLabelExtern	b $00				;$01 = Aktuelles Label ist extern.
.Flag_LabelNotOK	b $00
.Flag_LabelNotFound	b $00				;$01 = Label nicht gefunden.
.Flag_LabelIsDefined	b $00				;$01 = Akt. Label ist in Labeltabelle.

;*** Aktueller Assembler-Befehl.
.CurCommandLen		b $00				;Länge des aktuellen Assembler-Befehls.
.CurCommand		s $03

;*** Variablen für Pseudo-Opcodes.
.Flag_ByteOrWord	b $00
.Flag_ByteStringOpen	b $00
.Poi_ByteWordText	b $00
.Poi_FileInfoText	b $00				;Zeiger auf Byte in Infotext.
.CurIconWidth		b $00
.CurIconHight		w $0000

;*** Variablen für Rechenoperationen.
.CurrentPriority	b $00
.CalcPriority		b $00
.CurrentCalcMode	b $00
.Pos_OpenBracket	b $00
.Pos_CloseBracket	b $00

;*** Variablen für aktuelles Label.
.Len_CurLabelName	b $00
.Len_CurLabelEntry	b $00
.LabelValue		w $0000

;*** Anzahl zu kopierender Bytes.
.ByteCopyCount		b $00

;*** Variablen zur Bestimmung des Operanden.
.Len_CurOperand		b $00				;Länge des akt. Operanden (0,1,2-Byte)
.OpcodeModes		s $03				;Adressierungsinfo zu aktuellem Befehl.
.Vec_OpcodeTab		w $0000
.Buf_VecOpcodeTab	w $0000				;Zwischenspeicher ":Vec_OpcodeTab".
.Len_AdrStrgEntry	b $00
.Len_AdrModeEntry	b $00
.Vec_AdrModeEntry	b $00
.Vec_AdrModeTab		w $0000				;Zeiger auf Tab. mit Adressierungsarten.
.Poi_AdrModeLine	b $00
.CurAdrModeChar		b $00

;*** Variablen zur Bestimmung des aktuellen Arguments.
.Poi_NewArgLine		b $00
.Poi_PointInCurArg	b $00
.Poi_1stArgByte		b $00
.Poi_CurArgument	b $00				;Zeiger auf akt. Argument für Befehl.
.Buf_VecNewArgLine	b $00

;*** Umwandlung ASCII => HEX.
.Address		w $0000				;Zwischenspeicher Word-Berechnung.
.Buf_Address		w $0000				;Zwischenspeicher Word-Berechnung.

;*** Zeiger auf Labeltabelle.
.CurLabelName		s 70
.Poi_SortLabelTab	b $00
.Buf_VecStLabelTab	w $0000
.Vec_LabelMemory	b $00
.Vec_LokalLabels	w $0000
.VecCurLabelBuf1	w $0000
.VecCurLabelBuf2	w $0000

;*** Makro-Variablen.
.Poi_CurMakroPar	b $00				;Zeiger auf aktuellen Makroparameter.
.Vec_MakParDefTab	b $00
.Cnt_MakroParameter	b $00

.Poi_StrgValLine	b $00
.Poi_StrgValBuffer	b $00

.PackedDataLine		s 200
.Poi_PackedData		b $00				;Zeiger gepackte Textzeile.

;*** Aktuelle Textzeile/Aktuelle Labelbezeichnung.
.FileIconData		s 128
.CurAdrModeLine		s 200
.StringValueLine	s 200
.CalculationBuffer	s 200
.StringValueBuffer	s 200

;*** Dialogbox: "Datei bereits vorhanden!"
.DlgFileExist		b $00
			b $00  ,$0f
			w $0000,$013f

			b DBTXTSTR    ,$0a,$0a
			w :1
			b YES         ,$1b,$00
			b NO          ,$22,$00
			b NULL

::1			b BOLDON
			b "Objektdatei überschreiben ?",PLAINTEXT,NULL

;*** Original-Icon für QuellCode-Datei.
.Hdr_IconDataOrg	j
<MISSING_IMAGE_DATA>

.Hdr_IconDataEnd

;*** Bitmasken für Adressierungsmodi.
;    Bei ":BM_B2" werden die letzten 6 Byte aus Tabelle
;    ":BM_B3" entnommen (überschneidung).
.BitMask_Byte1		b $40,$20,$10,$08,$04,$02,$01,$00
			b $00,$00,$00,$00,$00,$00,$00
.BitMask_Byte2		b $00,$00,$00,$00,$00,$00,$00,$80
			b $40,$20,$10,$08,$04,$02,$01

;*** Tabelle mit Adressierungsarten.
.AdrModeTab		b $04,$1c,"$$,y"   ,$00
			b $02,$0c,"$$"     ,$00
			b $01,$04,"$"      ,$00
			b $02,$08,"#$"     ,$00
			b $04,$1c,"$$,x"   ,$00
			b $04,$18,"$$,y"   ,$00
			b $03,$14,"$,x"    ,$00
			b $05,$00,"($,x)"  ,$00
			b $05,$10,"($),y"  ,$00
			b $02,$00,"#$"     ,$00
			b $04,$6c,"($$)"   ,$00
			b $03,$14,"$,y"    ,$00
			b $02,$00,"$$"     ,$00
			b $01,$00,"$"      ,$00
			b $01,$08,"a"      ,$00
			b $ff

;*** Tabelle mit Opcodes.
;Byte #1, Grundwert für Opcode
;
;Adressierungsmodi:
;Byte #2, Bit # 7,  ---     Byte #3, Bit # 7, "($,x)"
;Byte #2, Bit # 6, "$$,y"   Byte #3, Bit # 6, "($),y"
;Byte #2, Bit # 5, "$$"     Byte #3, Bit # 5, "#$"
;Byte #2, Bit # 4, "$"      Byte #3, Bit # 4, "($$)"
;Byte #2, Bit # 3, "#$"     Byte #3, Bit # 3, "$,y"
;Byte #2, Bit # 2, "$$,x"   Byte #3, Bit # 2, "$$"
;Byte #2, Bit # 1, "$$,y"   Byte #3, Bit # 1, "$"
;Byte #2, Bit # 0, "$,x"    Byte #3, Bit # 0, "a"

.OpcodeTab		b "jsr",$20,$00,$04
			b "lda",$a1,$3f,$c0
			b "sta",$81,$37,$c0
			b "bne",$d0,$00,$02
			b "jmp",$40,$20,$10
			b "beq",$f0,$00,$02
			b "rts",$60,$00,$00
			b "ldx",$a2,$70,$28
			b "ldy",$a0,$35,$20
			b "cmp",$c1,$3f,$c0
			b "txa",$8a,$00,$00
			b "clc",$18,$00,$00
			b "iny",$c8,$00,$00
			b "bpl",$10,$00,$02
			b "bcc",$90,$00,$02
			b "pla",$68,$00,$00
			b "pha",$48,$00,$00
			b "inc",$e2,$35,$00
			b "bit",$20,$30,$00
			b "tax",$aa,$00,$00
			b "and",$21,$3f,$c0
			b "adc",$61,$3f,$c0
			b "cpy",$c0,$30,$20
			b "inx",$e8,$00,$00
			b "sbc",$e1,$3f,$c0
			b "asl",$02,$35,$01
			b "cpx",$e0,$30,$20
			b "dey",$88,$00,$00
			b "dex",$ca,$00,$00
			b "sec",$38,$00,$00
			b "bcs",$b0,$00,$02
			b "tay",$a8,$00,$00
			b "bmi",$30,$00,$02
			b "stx",$82,$30,$08
			b "sei",$78,$00,$00
			b "tya",$98,$00,$00
			b "php",$08,$00,$00
			b "plp",$28,$00,$00
			b "dec",$c2,$35,$00
			b "sty",$80,$31,$00
			b "ora",$01,$3f,$c0
			b "cli",$58,$00,$00
			b "bvc",$50,$00,$02
			b "eor",$41,$3f,$c0
			b "bvs",$70,$00,$02
			b "rol",$22,$35,$01
			b "ror",$62,$35,$01
			b "lsr",$42,$35,$01
			b "clv",$b8,$00,$00
			b "sed",$f8,$00,$00
			b "cld",$d8,$00,$00
			b "tsx",$ba,$00,$00
			b "txs",$9a,$00,$00
			b "nop",$ea,$00,$00
			b "rti",$40,$00,$00
			b "brk",$00,$00,$00
			b $ff

;*** Fehlertabelle.
.ErrCodeTab		s 256				;Fehlercode-Tabelle.

;*** Startadresse für Labels (sortiert nach alphabetischer Reihenfolge!)
.SortLabelVec		w $0000				;$00 = A...
			w $0000				;$02 = B...
			w $0000				;$04 = C...
			w $0000				;$06 = D...
			w $0000				;$08 = E...
			w $0000				;$0a = F...
			w $0000				;$0c = G...
			w $0000				;$0e = H...
			w $0000				;$10 = I...
			w $0000				;$12 = J...
			w $0000				;$14 = K...
			w $0000				;$16 = L...
			w $0000				;$18 = M...
			w $0000				;$1a = N...
			w $0000				;$1c = O...
			w $0000				;$1e = P...

			w $0000				;$20 = Q...
			w $0000				;$22 = R...
			w $0000				;$24 = S...
			w $0000				;$26 = T...
			w $0000				;$28 = U...
			w $0000				;$2a = V...
			w $0000				;$2c = W...
			w $0000				;$2e = X...
			w $0000				;$30 = Y...
			w $0000				;$32 = Z...
			w $0000				;$34 = Ä...
			w $0000				;$36 = Ö...
			w $0000				;$38 = Ü...
			w $0000				;$3a = _...
			w $0000				;$3c = Nicht erlaubt.
			w $0000				;$3e = Nicht erlaubt.

			w $0000				;$40 = a...
			w $0000				;$42 = b...
			w $0000				;$44 = c...
			w $0000				;$46 = d...
			w $0000				;$48 = e...
			w $0000				;$4a = f...
			w $0000				;$4c = g...
			w $0000				;$4e = h...
			w $0000				;$50 = i...
			w $0000				;$52 = j...
			w $0000				;$54 = k...
			w $0000				;$56 = l...
			w $0000				;$58 = m...
			w $0000				;$5a = n...
			w $0000				;$5c = o...
			w $0000				;$5e = p...

			w $0000				;$60 = q...
			w $0000				;$62 = r...
			w $0000				;$64 = s...
			w $0000				;$66 = t...
			w $0000				;$68 = u...
			w $0000				;$6a = v...
			w $0000				;$6c = w...
			w $0000				;$6e = x...
			w $0000				;$70 = y...
			w $0000				;$72 = z...
			w $0000				;$74 = ä...
			w $0000				;$76 = ö...
			w $0000				;$78 = ü...
			w $0000				;$7a = ß...
			w $0000				;$7c = Nicht erlaubt.
			w $0000				;$7e = Nicht erlaubt.
			w $0000				;$80 = Nicht erlaubt.

;*** Statuszeile ausgeben.
.PrintStatusLine	LoadB	dispBufferOn,ST_WR_FORE
			lda	#$00
			sta	currentMode

			lda	#$09			;Pixelzeilen 0-15 löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00
			b	$0f
.X31			w	$0000
			w	$013f

			jsr	PrintErrCount

			jsr	i_PutString
.X72			w	$0000
			b	$0a
			b	NULL

			LoadW	r0 ,SelectedFile
			jsr	PutString

;*** Include-Text anzeigen.
.PrintIncludeFile	lda	IncludeFileStack
			beq	PrintCodeArea
			jsr	i_PutString
.X78			w	$0000
			b	$0a
			b	NULL

			LoadW	r0,NameOfTextFile
			jsr	PutString

;*** Programmbereich ausgeben.
.PrintCodeArea		lda	curPass
			bne	PrintCurPass

			lda	#"-"			;Trennzeichen zwischen Start-
			sta	AssCodeArea +6		;und Endadresse.

			MoveW	Hdr_LoadAdr,r0		;Anfangsadresse in HEX-ASCII
			jsr	ConvWord_ASCII		;umwandeln.

			ldy	#$03
::1			lda	BufferHEX   +0,y
			sta	AssCodeArea +2,y
			dey
			bpl	:1

			lda	Hdr_EndAdr +0		;Zeiger auf letztes Byte.
			sec				;Hinweis:Im InfoBlock steht für
			sbc	#$01			;SaveFile die EndAdresse +1.
			sta	r0L
			lda	Hdr_EndAdr +1
			sbc	#$00
			sta	r0H			;Endadresse in HEX-ASCII
			jsr	ConvWord_ASCII		;umwandeln.

			ldy	#$03
::2			lda	BufferHEX   +0,y
			sta	AssCodeArea +8,y
			dey
			bpl	:2

			jsr	i_PutString
.X74			w	$0000
			b	$0a
			b	NULL

			LoadW	r0 ,AssCodeArea
			jsr	PutString

;*** Aktuellen Pass ausgeben.
.PrintCurPass		jsr	i_PutString
.X75			w	$0000
			b	$0a
.X75a			b	"P:. "
			b	NULL

;*** Aktuelle Seite ausgeben.
.PrintCurPage		lda	VLIR_Record
			clc
			adc	#$01
			jsr	ConvByte_DezASCII
			stx	Seite+2
			sta	Seite+3

			jsr	i_PutString
.X76			w	$0000
			b	$0a
.Seite			b	"S:..  "
			b	NULL
			rts

;*** Anzahl Fehler ausgeben.
.PrintErrCount		lda	ErrCount		;Fehler aufgetreten ?
			bne	:1
			rts

::1			jsr	i_PutString		;Aktuelle Fehleranzahl
.X37			w	$0000			;auf Bildschirm löschen.
			b	$0a
			b	PLAINTEXT
			b	"  "
			b	GOTOX
.X73			w	$0000
			b	NULL

			bit	ErrOverflow
			bmi	:2

			MoveB	ErrCount,r0L		;Fehleranzahl ausgeben.
			LoadB	r0H,$00
			lda	#%11000000
			jmp	PutDecimal

::2			LoadW	r0,:overflow
			jmp	PutString

::overflow		b BOLDON
			b ">> "
			b PLAINTEXT
			b NULL

;*** Byte in DezimalASCII wandeln.
.ConvByte_DezASCII	ldx	#"0"
::1			cmp	#10
			bcc	:2
			sbc	#10
			inx
			bne	:1
::2			adc	#"0"
			sta	r0L
			stx	r0H
			rts

;*** Word nach HEX wandeln.
.ConvWord_ASCII		lda	r0H
			lsr
			lsr
			lsr
			lsr
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +0
			lda	r0H
			and	#$0f
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +1
			lda	r0L
			lsr
			lsr
			lsr
			lsr
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +2
			lda	r0L
			and	#$0f
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +3
			rts

;*** Byte nach HEX wandeln.
.ConvByte_ASCII		lda	r0L
			lsr
			lsr
			lsr
			lsr
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +0
			lda	r0L
			and	#$0f
			tay
			lda	DataTab_DEZ_HEX,y
			sta	BufferHEX +1
			lda	#$00
			sta	BufferHEX +2
			rts

;*** Word-Wert nach ASCII wandeln.
.ConvASCII_Word_a	lda	BufferHEX +0
			ldx	BufferHEX +1
			jsr	SubASCII_Word
			sta	r0H
			lda	BufferHEX +2
			ldx	BufferHEX +3
			jsr	SubASCII_Word
			sta	r0L
::1			rts

;*** Zeichenpaar nach HEX/Byte wandeln.
:SubASCII_Word		stx	:1 +1
			jsr	IsCharHexByte
			bmi	:3
			asl
			asl
			asl
			asl
			sta	:2 +1
::1			lda	#$ff
			jsr	IsCharHexByte
			bmi	:3
			and	#$0f
::2			ora	#$ff
			ldx	#$00
			rts
::3			pla
			pla
			ldx	#$ff
			rts

;*** Binärzahl berechnen.
.ConvASCII_Bin_a	ldy	#$00
			sty	Address +0
			sty	Address +1
::1			iny
			lda	StringValueLine,y
			beq	:5
			cmp	#" "
			beq	:5
			cmp	#"0"
			beq	:3
			cmp	#"1"
			beq	:2
			cmp	#"o"
			beq	:3
			cmp	#"#"
			beq	:2
			lda	#$17
			rts

::2			sec
			bcs	:4

::3			clc
::4			rol	Address +0
			rol	Address +1
			bcc	:1

::6			lda	#$18
			rts

::5			lda	#$00
			rts

;*** Dezimalzahl berechnen.
.ConvASCII_Dez_a	ldy	#$00
			sty	r0L
			sty	r0H
::1			lda	StringValueLine,y
			cmp	#" "
			bne	:2
			iny
			bne	:1

::2			lda	StringValueLine,y	;Stringende erreicht ?
			beq	:3			;Ja, Ende...

			jsr	IsCharNumber		;Zeichen = Zahl ?
			bmi	:4			;Nein, falsches Format.

			clc				;Werte addieren.
			adc	r0L
			sta	r0L
			lda	#$00
			adc	r0H
			sta	r0H
			bcs	:5			;Überlauf, Zahl zu groß.

			iny
			lda	StringValueLine,y
			bne	:3
			rts

::3			jsr	IsCharNumber		;Zeichen = Zahl ?
			bmi	:4			;Nein, falsches Format.

			lda	r0L
			sta	r1L
			asl
			sta	r2L
			lda	r0H
			sta	r1H
			rol
			sta	r2H

			asl	r1L
			rol	r1H
			asl	r1L
			rol	r1H
			asl	r1L
			rol	r1H
			bcs	:5

			lda	r1L
			clc
			adc	r2L
			sta	r0L
			lda	r1H
			adc	r2H
			sta	r0H
			bcs	:5
			bcc	:2

;*** Ungültiges Zahlenformat.
::4			lda	#$17			;Fehler: "Format ungültig"
			b $2c
::5			lda	#$18			;Fehler: "Zahl zu groß"
			rts

;*** String-Operant in Byte umwandeln (z.B. "a" = $61).
.ConvString_Byte_a	ldy	#$00
::1			lda	(a0L),y
			beq	:5
			cmp	#$22
			bne	:4
			iny
			lda	(a0L),y
			beq	:2
			iny
			lda	(a0L),y
			cmp	#$22
			beq	:3
::2			lda	#$17
			rts

::3			dey
			lda	(a0L),y
			ora	#$80
			dey
			sta	(a0L),y

			lda	#TAB
			iny
			sta	(a0L),y
			iny
			sta	(a0L),y
			dey
::4			iny
			bpl	:1

::5			lda	a0L
			sta	:6 +1
			sta	:7 +1
			lda	a0H
			sta	:6 +2
			sta	:7 +2

			ldy	#$00
			ldx	#$00
::6			lda	$8000,y			;Label wird berechnet!
::7			sta	$8000,x			;Label wird berechnet!
			beq	:9
			cmp	#TAB
			beq	:8
			inx
::8			iny
			bpl	:6
::9			rts

;*** Zeichen testen.
.IsCharHexByte		sty	Load_YReg +1
			ldy	#$0f
			bne	IsCharOK

.IsCharNumber		sty	Load_YReg +1
			ldy	#$09

.IsCharOK		cmp	DataTab_DEZ_HEX,y
			beq	:1
			dey
			bpl	IsCharOK
::1			tya
			pha
:Load_YReg		ldy	#$ff
			pla
			rts

;*** Dateiname/Autor/GEOS-Klasse/Modulname kopieren.
.CopyStringToVec1	sta	r0L
			stx	r0H
			sty	r1L

.CopyStringToVec2	ldy	#$00
.CopyStringToVec3	lda	CurAdrModeLine,y
			beq	:2
			cmp	#$22
			beq	:3
			iny
			bne	CopyStringToVec3
::2			sec
			rts

::3			tya
			tax
			inx
			ldy	#$00
::4			lda	CurAdrModeLine,x	;Zeichen aus Text einlesen.
			sta	(r0L),y			;Zeichen kopieren.
			beq	:6			;Ende ? Ja, weiter...
			cmp	#$22
			beq	:5
			dec	r1L
			beq	:6
			inx
			iny
			bne	:4
			iny
::5			lda	#$00
			sta	(r0L),y
::6			clc
			rts

;*** Neue Textseite initialisieren.
.GetPageStart		bit	Flag_SourceInclude	;Dateimodus testen.
			bpl	:3
			bit	Flag_DataOrText
			bmi	:4

::1			sei				;Fehler! Dateimodus "Include-
			lda	#$36			;Routine liegt unterhalb BASIC
			sta	$01			;$35 falsch, $36 = RAM+I/O.
::2			inc	$d020
			jmp	:2
::3			jmp	Page_SourceFile
::4			jmp	Page_TextFile

;*** Seite aus QuellCode öffnen.
.Page_SourceFile	lda	Opt_SourceDrive
			sta	CurrentSektor +0
			jsr	NewSetDevice

			lda	#<SelectedFile		;Zeiger auf Quelltextname.
			ldx	#>SelectedFile
			sta	Vec_CurFileName +0
			stx	Vec_CurFileName +1

			jsr	GetFileHeader

			lda	VLIR_Record		;Zeiger auf Datensatz einlesen.
			cmp	#61
			bcs	:1
			asl
			tay
			lda	fileHeader +$02,y
			ldx	fileHeader +$03,y
			cmp	#$00			;Ende Textdatei erreicht ?
			bne	:2			;Nein, weiter...
::1			sec
			rts

::2			sta	CurrentSektor +1
			stx	CurrentSektor +2

;*** Ersten Textsektor lesen.
.OpenTextPage		jsr	GetCurrentSektor

			jsr	GetFirstBytePos		;Erstes Byte bestimmen.
			sta	CurrentSektor +3
			jsr	PrintCurPage
			clc
			rts

;*** Seite aus IncludeText öffnen.
.Page_TextFile		lda	VLIR_Drive
			sta	CurrentSektor +0
			jsr	NewSetDevice

			lda	#<NameOfTextFile	;Zeiger auf Includetextname.
			ldx	#>NameOfTextFile
			sta	Vec_CurFileName +0
			stx	Vec_CurFileName +1

			jsr	GetFileHeader

			lda	VLIR_Record		;Zeiger auf Datensatz einlesen.
			cmp	#61
			bcs	:1
			asl
			tay
			lda	fileHeader +$02,y
			ldx	fileHeader +$03,y
			cmp	#$00			;Ende Textdatei erreicht ?
			bne	:2			;Nein, weiter...
::1			sec
			rts

::2			sta	CurrentSektor +1
			stx	CurrentSektor +2
			jmp	OpenTextPage

;*** Neue Textzeile einlesen.
.GetGW_TextLine		lda	Flag_NoTextLines	;Seitenende erreicht ?
			bne	:1			;Ja, Ende...
			lda	Flag_EndOfTextFile	;Textende erreicht ?
			beq	StartNewTextLine	;Nein, weiter...
			lda	#$01
			sta	Flag_NoTextLines
			lda	#$00
			sta	Flag_EndOfTextFile
::1			lda	#$00
			sta	CurTextLine
			rts

;*** Neue Textzeile beginnen.
.StartNewTextLine	lda	#$00
			sta	Flag_TxtLineEmpty
			sta	Len_CurTextLine		;Zeilenlänge = $00.
			sta	Flag_TextStringOpen	;Kein Textstring geöffnet.

			lda	CurrentSektor   +0	;Aktuelles Laufwerk merken.
			sta	CurrentTextLine +0
			lda	CurrentSektor   +1	;Zeiger auf Sektor merken.
			sta	CurrentTextLine +1
			lda	CurrentSektor   +2
			sta	CurrentTextLine +2
			lda	CurrentSektor   +3	;Zeiger auf Byte merken.
			sta	CurrentTextLine +3

;*** Nächstes Byte aus Quelltext auswerten.
.RdNxTextByte		clc
			jsr	GetByteFromText		;Nächstes Byte aus Text lesen.
			bcc	FindGW_Code		;Zeichen gelesen, weiter.
			lda	#$01
			sta	Flag_EndOfTextFile
			jmp	DefEndOfLine

;*** GeoWrite-Steuercode auswerten.
.FindGW_Code		cmp	#$20
			bcs	NoGW_Code
			cmp	#CR
			beq	DefEndOfLine
			cmp	#PAGE_BREAK
			beq	DefEndOfLine
			cmp	#NULL
			bne	GW_FormatCode

;*** Ende Text markieren.
.DefEndOfLine		ldy	Len_CurTextLine
			lda	#$00
			sta	CurTextLine,y
			rts

;*** GeoWrite-Steuercode auswerten.
.GW_FormatCode		cmp	#NEWCARDSET		;NEWCARDSET gefunden ?
			bne	:1			;Nein, weiter...
			jsr	Code_NEWCARDSET		;NEWCARDSET im Text überlesen.
			jmp	RdNxTextByte

::1			cmp	#ESC_RULER		;ESC_RULER gefunden ?
			bne	:2			;Nein, weiter...
			jsr	Code_ESC_RULER		;ESC_RULER im Text überlesen.
			jmp	RdNxTextByte

::2			cmp	#ESC_GRAPHICS
			bne	NoGW_Code
			jsr	Code_ESC_GRAPHICS	;ESC_GRAPHICS im Text überlesen.
			jmp	DefEndOfLine

;*** Andere Textzeichen auswerten.
.NoGW_Code		ldx	Flag_TextStringOpen	;String geöffnet ?
			bne	:3			;Ja, weiter...

			cmp	#";"			;Bemerkungszeichen gefunden ?
			bne	:3			;Nein, weiter...
			jsr	Find_EndOfLine
			jmp	DefEndOfLine

::3			cmp	#$22
			bne	:4
			lda	Flag_TextStringOpen
			eor	#$ff
			sta	Flag_TextStringOpen
			lda	#$22
			bne	:5

::4			cmp	#TAB
			bne	:5
			lda	#" "

::5			ldy	Len_CurTextLine
			sta	CurTextLine,y
			cmp	#" "
			beq	:6

			lda	#$01
			sta	Flag_TxtLineEmpty

::6			lda	Flag_TxtLineEmpty
			bne	:7
			dec	Len_CurTextLine
::7			inc	Len_CurTextLine
			lda	Len_CurTextLine
			cmp	#160
			bcc	:8
			jsr	Find_EndOfLine
			jmp	DefEndOfLine
::8			jmp	RdNxTextByte

;*** NEWCARDSET im Text überlesen.
.Code_NEWCARDSET	clc
			jsr	GetByteFromText
			clc
			jsr	GetByteFromText
			clc
			jmp	GetByteFromText

;*** ESC_RULER im Text überlesen.
.Code_ESC_RULER		ldx	#$1a
::1			stx	:2 +1
			clc
			jsr	GetByteFromText
::2			ldx	#$ff
			dex
			bne	:1
			rts

;*** ESC_GRAPHICS im Text überlesen.
.Code_ESC_GRAPHICS	lda	#" "			;Leerzeichen als Trennzeichen
			jsr	:3			;in akt. Zeile kopieren.
			lda	#ESC_GRAPHICS		;Steuercodebyte ESC_GRAPHICS
			jsr	:3			;in akt. Zeile kopieren.

			ldx	#$04			;ESC_GRAPHICS in Textzeile
::1			stx	:2 +1			;kopieren.
			clc
			jsr	GetByteFromText		;Byte aus Text einlesen und
			jsr	:3			;in akt. Zeile kopieren.

::2			ldx	#$ff
			dex
			bne	:1
			rts

::3			ldy	Len_CurTextLine
			inc	Len_CurTextLine
			sta	CurTextLine,y
			rts

;*** Ende der aktuellen Zeile suchen.
.Find_EndOfLine		clc
			jsr	GetByteFromText
			bcs	:3

			cmp	#NEWCARDSET		;NEWCARDSET gefunden ?
			bne	:1			;Nein, weiter...
			jsr	Code_NEWCARDSET		;NEWCARDSET im Text überlesen.
			jmp	Find_EndOfLine

::1			cmp	#ESC_RULER		;ESC_RULER gefunden ?
			bne	:2			;Nein, weiter...
			jsr	Code_ESC_RULER		;ESC_RULER im Text überlesen.
			jmp	Find_EndOfLine

::2			cmp	#CR
			beq	:3
			cmp	#PAGE_BREAK
			beq	:3
			cmp	#NULL
			bne	Find_EndOfLine
::3			rts

;*** Fehler in Tabelle übernehmen.
.CopyErrCodeInTab	sta	ErrTypeCode		;Fehlercode merken.
			lda	#$01
			sta	Flag_StopSOpcode
			lda	Flag_LabelNotFound
			beq	:1
			rts

::1			lda	MakroEntryStack		;Makros geöffnet ?
			beq	StoreErrorInTab		;Nein, weiter...

			lda	ErrTypeCode		;Fehler innerhalb eines Makros.
			ora	#$80
			sta	ErrTypeCode

;*** Fehlercode in Tabelle suchen.
.StoreErrorInTab	lda	ErrCount
			cmp	#25
			bcc	:1
			lda	#$ff
			sta	ErrOverflow
			rts

::1			ldy	#$00
::2			lda	ErrCodeTab,y		;Ende Fehlertabelle suchen.
			cmp	#$ff			;Tabellenende erreicht ?
			beq	:3			;Ja, Neuen Fehler speichern.
			jsr	FindErrorInErrTab	;Ist Fehler in Tabelle ?
			tya				;Rückkehr nur, wenn Fehler nicht
			clc				;in der Tabelle gefunden wurde!
			adc	#10
			tay
			bne	:2

::3			sty	EndOfErrCodeTab		;Zeiger auf Ende Fehlertabelle.

			inc	ErrCount		;Anzahl Fehler +1.

;*** Fehlereintrag erzugen:
;    Fehler in Quelltext, Includetext, IncludeDatei.
.CreateErrEntry		bit	Flag_SourceInclude
			bpl	:1
			bit	Flag_DataOrText		;Daten-/Textdatei ?
			bne	:1			;Datenfile, weiter...

;*** Fehlereintrag für Datendatei.
			lda	#$00
			ldx	#<NameOfDataFile
			ldy	#>NameOfDataFile
			jmp	:2

;*** Fehlereintrag für Textdatei.
::1			lda	VLIR_Record
			clc
			adc	#$01
			ldx	Vec_CurFileName +0
			ldy	Vec_CurFileName +1

::2			sta	ErrPageCode
			stx	r6L
			sty	r6H
			jsr	FindFileDrvABCD

			ldy	EndOfErrCodeTab		;Zeiger auf Ende Fehlertabelle.

			lda	ErrTypeCode
			jsr	SaveByt2ErrTab
			lda	ErrPageCode
			jsr	SaveByt2ErrTab

			lda	curDrive
			jsr	SaveByt2ErrTab
			lda	r1L
			jsr	SaveByt2ErrTab
			lda	r1H
			jsr	SaveByt2ErrTab
			lda	r5L
			jsr	SaveByt2ErrTab

			lda	CurrentTextLine +0
			jsr	SaveByt2ErrTab
			lda	CurrentTextLine +1
			jsr	SaveByt2ErrTab
			lda	CurrentTextLine +2
			jsr	SaveByt2ErrTab
			lda	CurrentTextLine +3
			jsr	SaveByt2ErrTab

			lda	#$ff
			jsr	SaveByt2ErrTab		;Tabellenende markieren.

			jsr	PrintErrCount		;Anzahl Fehler anzeigen.
			jmp	GetCurrentSektor

;*** Byte in Fehlertabelle speichern.
.SaveByt2ErrTab		sta	ErrCodeTab,y
			iny
			rts

;*** Wurde Fehler bereits bemerkt und gespeichert ?
.FindErrorInErrTab	lda	VLIR_Record
			clc
			adc	#$01
			cmp	ErrCodeTab      +1,y
			bne	ErrorNotFound

			lda	CurrentTextLine +0
			cmp	ErrCodeTab      +6,y
			bne	ErrorNotFound

			lda	CurrentTextLine +1
			cmp	ErrCodeTab      +7,y
			bne	ErrorNotFound

			lda	CurrentTextLine +2
			cmp	ErrCodeTab      +8,y
			bne	ErrorNotFound

			lda	CurrentTextLine +3
			cmp	ErrCodeTab      +9,y
			bne	ErrorNotFound

:IgnoreCurError		pla
			pla
:ErrorNotFound		rts

;*** Beginn der Include-Befehlszeile speichern.
.InitIncludeMode	inc	IncludeFileStack
			ldx	IncludeFileStack

			lda	CurrentTextLine +0	;Aktuelles Laufwerk merken.
			sta	IncludeDataDrive  ,x
			lda	CurrentTextLine +1	;Zeiger auf Sektor merken.
			sta	IncludeDataTrack  ,x
			lda	CurrentTextLine +2	;Zeiger auf Sektor merken.
			sta	IncludeDataSektor ,x
			lda	CurrentTextLine +3	;Zeiger auf Byte merken.
			sta	IncludeDataByte   ,x
			lda	VLIR_Record		;Zeiger auf Datensatz merken.
			sta	IncludeDataRecord ,x

			txa
			asl
			tay
			lda	VLIR_HdrSektor  +0
			sta	IncludeVLIR_Hdr +0,y
			lda	VLIR_HdrSektor  +1
			sta	IncludeVLIR_Hdr +1,y

			txa
			asl
			asl
			asl
			asl
			tax
			ldy	#$00
::1			lda	NameBuffer        ,y
			sta	IncludeFileName   ,x
			inx
			iny
			cpy	#$10
			bne	:1
			lda	#<NameOfTextFile	;Zeiger auf Quelltextname.
			ldx	#>NameOfTextFile
			sta	Vec_CurFileName +0
			stx	Vec_CurFileName +1
			rts

;*** Letzten Eintrag aus IncludeStack kopieren.
.IncludeLastFile	ldx	IncludeFileStack
			bne	:1
			stx	Flag_SourceInclude
			rts

::1			lda	IncludeDataDrive  ,x
			sta	CurrentTextLine +0	;Aktuelles Laufwerk merken.
			sta	CurrentSektor   +0
			sta	VLIR_Drive
			lda	IncludeDataTrack  ,x
			sta	CurrentTextLine +1	;Zeiger auf Sektor merken.
			sta	CurrentSektor   +1
			lda	IncludeDataSektor ,x
			sta	CurrentTextLine +2	;Zeiger auf Sektor merken.
			sta	CurrentSektor   +2
			lda	IncludeDataByte   ,x
			sta	CurrentTextLine +3	;Zeiger auf Byte merken.
			sta	CurrentSektor   +3
			lda	IncludeDataRecord ,x
			sta	VLIR_Record		;Zeiger auf Byte merken.

			txa
			asl
			tay
			lda	IncludeVLIR_Hdr +0,y
			sta	VLIR_HdrSektor  +0
			lda	IncludeVLIR_Hdr +1,y
			sta	VLIR_HdrSektor  +1

			txa
			asl
			asl
			asl
			asl
			tax
			ldy	#$00
::2			lda	IncludeFileName   ,x
			sta	NameOfTextFile    ,y
			inx
			iny
			cpy	#$10
			bne	:2

			lda	#<NameOfTextFile	;Zeiger auf Quelltextname.
			ldx	#>NameOfTextFile
			dec	IncludeFileStack
			bne	:3
			lda	#<SelectedFile		;Zeiger auf Quelltextname.
			ldx	#>SelectedFile
			ldy	#$00
			sty	Flag_SourceInclude
			sty	Flag_DataOrText
::3			sta	Vec_CurFileName +0
			stx	Vec_CurFileName +1
			jmp	GetCurrentSektor

if FALSE
;*** Rechenzeichen auswerten.
.GetCalcMode		ldx	#$00
			cmp	#"+"
			bne	:1
			ldx	#$03
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$01			;Zeiger auf Funktionstabelle.

::1			cmp	#"-"
			bne	:2
			ldx	#$03
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$02			;Zeiger auf Funktionstabelle.

::2			cmp	#"*"
			bne	:3
			ldx	#$04
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$03			;Zeiger auf Funktionstabelle.

::3			cmp	#"/"
			bne	:4
			ldx	#$04
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$04			;Zeiger auf Funktionstabelle.

::4			cmp	#"!"
			bne	:5
			ldx	#$02
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$05			;Zeiger auf Funktionstabelle.

::5			cmp	#"&"
			bne	:6
			ldx	#$02
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$06			;Zeiger auf Funktionstabelle.

::6			cmp	#"="
			bne	:7
			ldx	#$01
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$07			;Zeiger auf Funktionstabelle.

::7			cmp	#"^"
			bne	:8
			ldx	#$05
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$08			;Zeiger auf Funktionstabelle.

::8			cmp	#"<"
			bne	:9
			ldx	#$00
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$09			;Zeiger auf Funktionstabelle.

::9			cmp	#">"
			bne	:10
			ldx	#$00
			stx	CalcPriority		;Priorität festlegen.
			ldx	#$0a			;Zeiger auf Funktionstabelle.
::10			rts

;*** Einsprungadressen für Berechnungen.
.CalculationTypes	w Addition
			w Subtraktion
			w Multiplikation
			w Division
			w Operation_OR
			w Operation_AND
			w CompareWords
			w Potenzieren
			w GetLowByte
			w GetHighByte
endif

if TRUE
;*** Rechenzeichen auswerten.
.GetCalcMode		pha
			ldx	#$00
::1			cmp	CalculationFunc,x
			bne	:2
			lda	CalculationPrio,x
			sta	CalcPriority
			inx
			jmp	:3
::2			inx
			cpx	#10
			bcc	:1
			ldx	#$00
::3			pla
			rts

;*** Einsprungadressen für Berechnungen.
.CalculationTypes	w Addition
			w Subtraktion
			w Multiplikation
			w Division
			w Operation_OR
			w Operation_AND
			w CompareWords
			w Potenzieren
			w GetLowByte
			w GetHighByte
:CalculationFunc	b "+"
			b "-"
			b "*"
			b "/"
			b "!"
			b "&"
			b "="
			b "^"
			b "<"
			b ">"
:CalculationPrio	b $03
			b $03
			b $04
			b $04
			b $02
			b $02
			b $01
			b $05
			b $00
			b $00
endif

;*** Erstes Zeichen aus Rechenspeicher löschen.
.InsChar1stBufPos	ldx	#$80
::1			txa
			beq	:2
			ldx	CalculationBuffer,y	;Alle Zeichen aus Puffer um 1
			sta	CalculationBuffer,y	;Byte verschieben.
			iny
			bne	:1
::2			sta	CalculationBuffer,y
			rts

;*** Erstes Zeichen aus Rechenspeicher löschen.
.Del1stCharFromBuf	lda	CalculationBuffer +1,y
			beq	:1
			sta	CalculationBuffer +0,y
			iny
			bne	Del1stCharFromBuf
::1			sta	CalculationBuffer +0,y
			rts

;*** Unterroutine zum potenzieren zweier Zahlen.
:Sub_Potenzieren	ldx	r1L
			bne	:1
			stx	r2H
			inx
			stx	r2L
			dex
			clc
			rts

::1			lda	r0L
			sta	r1L
			lda	r0H
			sta	r1H
			dex
			bne	:2
			lda	r0L
			sta	r2L
			lda	r0H
			sta	r2H
			clc
			rts

::2			jsr	DMult_r0_r1
			bcs	:3
			lda	r2L
			sta	r0L
			lda	r2H
			sta	r0H
			dex
			bne	:2
			clc
::3			rts

;*** Word in ":r0" und ":r1" multiplizieren.
;    Ergebnis in ":r2".
;    Bei Überlauf wird das C-Flag gesetzt.
:DMult_r0_r1		ldy	#$10
			lda	#$00
			sta	r2L
			sta	r2H
			MoveW	r1,r3

::1			asl	r2L
			rol	r2H
			bcs	:3
			asl	r3L
			rol	r3H
			bcc	:2

			lda	r2L
			clc
			adc	r0L
			sta	r2L
			lda	r2H
			adc	r0H
			sta	r2H
			bcs	:3			;Überlauf, Fehler...

::2			dey
			bne	:1
			rts

::3			sec
			rts

;*** Zwei Words addieren.
:Addition		lda	CalculationBuffer +0,y
			clc
			adc	CalculationBuffer +3,y
			sta	CalculationBuffer +0,y
			lda	CalculationBuffer +1,y
			adc	CalculationBuffer +4,y
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
			rts

;*** Zwei Words subtrahieren.
:Subtraktion		lda	CalculationBuffer +0,y
			sec
			sbc	CalculationBuffer +3,y
			sta	CalculationBuffer +0,y
			lda	CalculationBuffer +1,y
			sbc	CalculationBuffer +4,y
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
			rts

;*** Zwei Words multiplizieren.
:Multiplikation		lda	CalculationBuffer +0,y
			sta	r0L
			lda	CalculationBuffer +1,y
			sta	r0H
			lda	CalculationBuffer +3,y
			sta	r1L
			lda	CalculationBuffer +4,y
			sta	r1H
			tya
			pha
			jsr	DMult_r0_r1
			pla
			tay
			bcs	:1
			lda	r2L
			sta	CalculationBuffer +0,y
			lda	r2H
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
::1			rts

;*** Zwei Words dividieren.
:Division		lda	CalculationBuffer +0,y
			sta	r3L
			lda	CalculationBuffer +1,y
			sta	r3H
			lda	CalculationBuffer +3,y
			sta	r4L
			lda	CalculationBuffer +4,y
			sta	r4H
			tya
			pha
			ldx	#r3L
			ldy	#r4L
			jsr	Ddiv
			pla
			tay
			lda	r3L
			sta	CalculationBuffer +0,y
			lda	r3H
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
			rts

;*** UND-Verknüpfung.
:Operation_AND		lda	CalculationBuffer +0,y
			and	CalculationBuffer +3,y
			sta	CalculationBuffer +0,y
			lda	CalculationBuffer +1,y
			and	CalculationBuffer +4,y
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
			rts

;*** ODER-Verknüpfung.
:Operation_OR		lda	CalculationBuffer +0,y
			ora	CalculationBuffer +3,y
			sta	CalculationBuffer +0,y
			lda	CalculationBuffer +1,y
			ora	CalculationBuffer +4,y
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
			rts

;*** Zwei Words potenzieren.
:Potenzieren		lda	CalculationBuffer +0,y
			sta	r0L
			lda	CalculationBuffer +1,y
			sta	r0H
			lda	CalculationBuffer +3,y
			sta	r1L
			lda	CalculationBuffer +4,y
			beq	:1
			sec
			bcs	:2
::1			tya
			pha
			jsr	Sub_Potenzieren
			pla
			tay
			bcs	:2
			lda	r2L
			sta	CalculationBuffer +0,y
			lda	r2H
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
::2			rts

;*** Zwei Words vergleichen.
:CompareWords		lda	CalculationBuffer +0,y
			cmp	CalculationBuffer +3
			bne	:1
			lda	CalculationBuffer +1,y
			cmp	CalculationBuffer +4
			bne	:1
			lda	#$ff
			bne	:2
::1			lda	#$00
::2			sta	CalculationBuffer +0,y
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
			rts

;*** Low-Byte ermitteln.
:GetLowByte		lda	CalculationBuffer +3,y
			sta	CalculationBuffer +0,y
			lda	#$00
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
			rts

;*** High-Byte ermitteln.
:GetHighByte		lda	CalculationBuffer +4,y
			sta	CalculationBuffer +0,y
			lda	#$00
			sta	CalculationBuffer +1,y
			iny
			iny
			jsr	PrepForNextCalc
			clc
			rts

;*** Rechenspeicher für nächste Berechnung vorbereiten.
:PrepForNextCalc	tya
			pha
::1			lda	CalculationBuffer +3,y
			beq	:2
			sta	CalculationBuffer +0,y
			iny
			lda	CalculationBuffer +3,y
			sta	CalculationBuffer +0,y
			iny
			lda	CalculationBuffer +3,y
			sta	CalculationBuffer +0,y
			iny
			bne	:1
::2			sta	CalculationBuffer +0,y
			pla
			tay
			rts

;*** Datum in Quellcode einfügen.
.DefShortDate		lda	#$00			;K-Opcode.
			b $2c
.DefLongDate		lda	#$ff			;L-Opcode.
			sta	Flag_DateTimeMode

			lda	day
			jsr	AddHexByte
			jsr	AddDatePoint
			lda	month
			jsr	AddHexByte
			jsr	AddDatePoint
			lda	year
			jmp	AddHexByte

;*** Uhrzeit in Quellcode einfügen.
.DefShortTime		lda	#$00
			b $2c
.DefLongTime		lda	#$ff
			sta	Flag_DateTimeMode

			lda	hour
			jsr	AddHexByte
			jsr	AddTimeColon
			lda	minutes
			jmp	AddHexByte

;*** Byte in HEX wandeln und in Quellcode einfügen.
:AddHexByte		sta	r0L
			jsr	ConvByte_DezASCII
			lda	r0H
			jsr	AddProgByte
			lda	r0L
			jmp	AddProgByte

;*** Trennzeichen einfügen.
:AddDatePoint		lda	#"."
			b $2c
:AddTimeColon		lda	#":"
			bit	Flag_DateTimeMode
			bpl	:1
			jsr	AddProgByte
::1			rts

;*** Include-Dateiname definieren.
.TestTextFileName	ldy	#$0f
::1			lda	NameOfTextFile,y
			sta	NameBuffer    ,y
			dey
			bpl	:1

			ldx	#$ff			;Modus: Include-Text.
			stx	Flag_SourceInclude
			inx				;Include-Dateiname löschen.
			stx	NameOfTextFile

			lda	#<NameOfTextFile
			ldx	#>NameOfTextFile
			ldy	#16
			jsr	CopyStringToVec1	;Dateiname einlesen.
			lda	NameOfTextFile		;Name definiert ?
			beq	:2			;Nein, Fehler...

			LoadW	r3,NameOfTextFile	;Dateiname prüfen.
			LoadW	r4,SelectedFile
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			beq	:2

			LoadW	r3,NameOfTextFile
			LoadW	r4,ObjectFileName
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			bne	:3

::2			lda	#$20			;Dateiname ungültig.
			rts
::3			lda	#$00
			rts

;*** VLIR-Dateiname testen.
.TestVlirFileName	lda	#$00
			sta	NameOfDataFile

			LoadW	r0 ,NameOfDataFile
			LoadB	r1L,16
			jsr	CopyStringToVec3
			lda	NameOfDataFile
			beq	:2

			LoadW	r3,NameOfDataFile
			LoadW	r4,SelectedFile
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			beq	:2

			LoadW	r3,NameOfDataFile
			LoadW	r4,NameOfTextFile
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			beq	:2

			LoadW	r3,NameOfDataFile
			LoadW	r4,ObjectFileName
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			bne	:3

::2			lda	#$20
			rts
::3			lda	#$00
			rts

;*** Datendateiname testen.
.TestDataFileName	lda	#$00
			sta	NameOfDataFile

			lda	#<NameOfDataFile
			ldx	#>NameOfDataFile
			ldy	#16
			jsr	CopyStringToVec1
			lda	NameOfDataFile
			beq	:1

			LoadW	r3,NameOfDataFile
			LoadW	r4,SelectedFile
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			beq	:1

			LoadW	r3,NameOfDataFile
			LoadW	r4,NameOfTextFile
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			beq	:1

			LoadW	r3,NameOfDataFile
			LoadW	r4,ObjectFileName
			ldx	#r3L
			ldy	#r4L
			jsr	CmpString
			bne	:2

::1			lda	#$20
			rts
::2			lda	#$00
			rts

;*** Icon über "i" oder "j" in Programmcode einbinden.
.Insert24BitIcon_a	lda	dispBufferOn
			pha
			lda	#ST_WR_BACK
			sta	dispBufferOn
.X08			jsr	$8000			;Wird geändert, je nach
							;Bildschirm-Modus!
			lda	PackedDataLine +4
			asl
			tay
			lda	fileHeader +2,y
			sta	r1L
			lda	fileHeader +3,y
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			jsr	i_BitmapUp
			w	diskBlkBuf +5
			b	$00,$00,$03,$15

			jsr	GetCurrentSektor

.X09			jsr	$8000

			bit	Flag_POpcode_I
			bpl	InsIconGrafxData
			jmp	CopyHeaderIcon

;*** Icon-Daten einfügen.
.InsIconGrafxData	lda	#$bf
			jsr	AddProgByte

			ldy	#$00
::1			sty	:2 +1
			lda	FileIconData,y
			jsr	AddProgByte
::2			ldy	#$ff
			iny
			cpy	#$3f
			bne	:1

			pla
			sta	dispBufferOn
			lda	#$00
			sta	Flag_POpcode_J
			rts

;*** Dateiheader-Icon erzeugen.
.CopyHeaderIcon		ldy	#$3e
::1			lda	FileIconData,y
			sta	Header  +$05,y
			dey
			bpl	:1

			lda	#$00
			sta	Flag_POpcode_I
			pla
			sta	dispBufferOn
			rts

;*** Datei-Icon (40-Zeichen-Modus) berechnen.
.CreateIcon40		LoadW	r1   ,FileIconData

			ldx	#$00
::1			stx	:5 +1
			jsr	GetScanLine

			ldy	#$00
			ldx	#$02
::2			stx	:4 +1

			lda	(r1L),y
			tax
			lda	(r6L),y
			sta	(r1L),y
			txa
			sta	(r6L),y

			inc	r1L
			bne	:3
			inc	r1H

::3			lda	r6L
			clc
			adc	#8
			sta	r6L
			bcc	:4
			inc	r6H

::4			ldx	#$ff
			dex
			bpl	:2

::5			ldx	#$00
			inx
			cpx	#$15
			bne	:1

			rts

;*** Datei-Icon (80-Zeichen-Modus) berechnen.
.CreateIcon80		LoadW	r0   ,BACK_SCR_BASE
			LoadW	r1   ,FileIconData

			ldx	#$14
::1			stx	:3 +1

			ldy	#$02
::2			lda	(r0L),y
			tax
			lda	(r1L),y
			sta	(r0L),y
			txa
			sta	(r1L),y
			dey
			bpl	:2

			lda	r0L
			clc
			adc	#80
			sta	r0L
			bcc	:4
			inc	r0H

::4			lda	r1L
			clc
			adc	#3
			sta	r1L
			bcc	:3
			inc	r1H

::3			ldx	#$ff
			dex
			bpl	:1
			rts

;*** Grafik in Text einfügen.
.InsertGraphics_a	ldy	#$03			;Aktuelle Sektordaten speichern.
::1			lda	CurrentSektor   ,y
			pha
			dey
			bpl	:1

			lda	PackedDataLine+4	;Zeiger auf VLIR-Datensatz mit
			asl				;Icon-Daten einlesen.
			tay
			lda	fileHeader    +2,y
			tax
			lda	fileHeader    +3,y
			tay
			sec				;Ersten Sektor mit Icon-Daten
			jsr	GetByteFromText		;einlesen und Icon-Breite
			sta	r11H			;zwischenspeichern.
			sta	CurIconWidth
			clc
			jsr	GetByteFromText		;Icon-Höhe einlesen.
			sta	r12L
			sta	CurIconHight  +0
			clc
			jsr	GetByteFromText
			sta	r12H
			sta	CurIconHight  +1

			jsr	AddIconData		;Icon-daten aus Quellcode ein-
							;lesen und in Programmcode
							;übertragen.
			ldy	#$00
::2			pla
			sta	CurrentSektor,y		;Sektordaten zurücksetzen.
			iny
			cpy	#$04
			bne	:2

			lda	curPass			;Pass #1 ?
			bne	:3			; => Nein, weiter...
			inc	IconCounter +0		;Icon-Zähler korrigieren.
			bne	:3
			inc	IconCounter +1
			bne	:3
			inc	IconCounter +2
			bne	:3
			inc	IconCounter +3
::3			jmp	GetCurrentSektor	;Ende...

;*** Icon-Daten in Programmcode übertragen.
:AddIconData		lda	#$00
			sta	r6L
			sta	r6H
			sta	r7L
			sta	r9L

::1			lda	r11H			;Zähler für Icon-Breite
			sta	r9H			;initialisieren.

::2			jsr	AddIconLine		;Ein Byte aus Zeile übertragen.
			dec	r9H			;Zeile komplett ?
			bne	:2			; => Nein, weiter...

			lda	r12L			;Zähler für Zeile korrgieren.
			bne	:3
			dec	r12H
::3			dec	r12L

			lda	r12L
			ora	r12H			;Alle Zeilen übertragen ?
			bne	:1			; => Nein, weiter...
			rts

;*** Zeile mit Icon-Daten an Programm übertragen.
:AddIconLine		lda	r9L
			and	#$7f			;Noch Bytes im Puffer ?
			beq	CODE_TEST		; => Nein, weiter...

			bit	r9L			;Gepackte Daten ?
			bpl	CODE_01_7F		; => Ja, weiter...

;*** Doppelt gepackte daten.
:CODE_80_FF		jsr	DoublePacked
			ldx	r6L
			bne	:1
			jsr	AddIconByte
::1			dec	r9L
			rts

;*** Einfach gepackte Daten.
:CODE_01_7F		lda	r7H			;Datenbyte einlesen.
			dec	r9L			;Zähler korrigieren.
			rts

;*** Neues befehlsbyte auswerten.
:CODE_TEST		jsr	DoublePacked		;Befehlsbyte einlesen und
			sta	r9L			;zwischenspeichern.

			jsr	AddIconByte
			cmp	#$dc			;Doppelt gepackte Daten ?
			bcc	SinglePacked		; => Nein, weiter...

			sbc	#$dc			;Anzahl Bytes in den doppelt
			sta	r7L			;gepackte Daten.
			sta	r6H

			jsr	DoublePacked		;Anzahl Wiederholungen
			jsr	AddIconByte		;berechnen und speichern.
			sec
			sbc	#$01
			sta	r6L

			lda	r10H
			sta	r8H
			lda	r10L
			sta	r8L
			jmp	CODE_TEST

;*** Einfach gepacktes Datenbyte einlesen.
:SinglePacked		cmp	#$80			;Gepackte Daten ?
			bcs	AddIconLine		; => Ja, weiter...
			jsr	DoublePacked
			sta	r7H
			jsr	AddIconByte
			jmp	AddIconLine

;*** Doppelt gepacktes Datenbyte einlesen.
:DoublePacked		clc
			jsr	GetByteFromText
			ldx	r6L			;Ende doppelt gepackter Daten ?
			beq	:1			; => Ja, weiter...
			dec	r6H			;Alle Bytes gesendet ?
			bne	:1			; => Nein, weiter...

			ldx	r8H			;Zeiger auf erstes Byte der
			stx	r10H			;aktuellen Datensequenz.
			ldx	r8L
			stx	r10L
			ldx	r7L			;Anzahl Bytes zurücksetzen.
			stx	r6H
			dec	r6L			;Zähler Wiederholungen -1.
::1			rts

;*** Byte in Programm einfügen.
:AddIconByte		tay				;ZeroPage retten.
			ldx	#$00
::1			lda	r0L,x
			pha
			inx
			cpx	#$20
			bcc	:1

			tya				;Datenbyte hinzufügen.
			pha
			jsr	AddProgByte
			pla
			tay

			ldx	#$1f			;ZeroPage zurücksetzen.
::2			pla
			sta	r0L,x
			dex
			bpl	:2
			tya
			rts

;*** Platz für neues Label in Symbolspeicher schaffen.
;Übergabe: YReg = Anzahl Zeichen in Label.
;          a3   = Startadresse Labelgruppe ("A", "B"...)
.InsSpaceForLabel	sty	:1 +1

			lda	a3L
			sta	r0L
			clc
::1			adc	#$ff
			sta	r1L
			lda	a3H
			sta	r0H
			adc	#$00
			sta	r1H

			lda	SortLabelVec +$7a
			sec
			sbc	r0L
			sta	r2L
			lda	SortLabelVec +$7b
			sbc	r0H
			sta	r2H
			ora	r2L
			beq	:2
			jmp	MoveData
::2			rts

;*** Labelname testen.
.TestLabelName		ldy	#$00
			lda	(r0L),y
			beq	:2
			cmp	#":"
			bne	:1

			ldy	#$01
			lda	(r0L),y
			beq	:2
::1			lda	(r0L),y
			beq	:4
			cmp	#$30
			bcc	:2
			cmp	#$3a
			bcc	:3
			cmp	#$41
			bcc	:2
			cmp	#$5e
			bcc	:3
			cmp	#$5f
			beq	:3
			cmp	#$61
			bcc	:2
			cmp	#$7f
			bcc	:3
::2			sec
			rts

::3			iny
			bne	:1
			sec
			rts

::4			clc
			rts

;*** "Makro geöffnet"-Flags löschen.
.ClrMakOpenFlags	ldy	#(MaxOpenMakros -1)
			lda	#$00
::1			sta	MakroOpenFlags,y
			dey
			bpl	:1
			rts

;*** Aktuelles label als "Label in Makro" markieren.
.SetFlag_LabelInMak1
			lda	MakroEntryStack
			bne	:1
			rts

::1			ldy	#$00
::2			lda	MakroOpenFlags   ,y
			ldx	Len_CurLabelName
			sta	CurLabelName     ,x
			inc	Len_CurLabelName
			iny
			cpy	MakroEntryStack
			bne	:2
			rts

;*** "Label in Makro"-Flag in aktuellem Label setzen.
.SetFlag_LabelInMak2
			lda	MakroEntryStack
			bne	:1
			rts

::1			ldy	#$00
::2			lda	MakroOpenFlags   ,y
			ldx	Len_CurLabelName
			sta	StringValueLine  ,x
			inc	Len_CurLabelName
			iny
			cpy	MakroEntryStack
			bne	:2
			rts

;*** Beginn der Include-Befehlszeile speichern.
.MakroNextEntry_a	inc	MakroEntryStack
			lda	MakroEntryStack
			asl
			asl
			tax

			lda	CurrentTextLine +0	;Aktuelles Laufwerk merken.
			sta	MakroDefTab     +0,x
			lda	CurrentTextLine +1	;Zeiger auf Sektor merken.
			sta	MakroDefTab     +1,x
			lda	CurrentTextLine +2	;Zeiger auf Sektor merken.
			sta	MakroDefTab     +2,x
			lda	CurrentTextLine +3	;Zeiger auf Byte merken.
			sta	MakroDefTab     +3,x
			rts

;*** Letzten Eintrag aus IncludeStack kopieren.
.MakroLastEntry		lda	MakroEntryStack
			asl
			asl
			tax
			lda	MakroDefTab     +0,x
			sta	CurrentTextLine +0	;Aktuelles Laufwerk merken.
			sta	CurrentSektor   +0
			sta	VLIR_Drive
			lda	MakroDefTab     +1,x
			sta	CurrentTextLine +1	;Zeiger auf Sektor merken.
			sta	CurrentSektor   +1
			lda	MakroDefTab     +2,x
			sta	CurrentTextLine +2	;Zeiger auf Sektor merken.
			sta	CurrentSektor   +2
			lda	MakroDefTab     +3,x
			sta	CurrentTextLine +3	;Zeiger auf Byte merken.
			sta	CurrentSektor   +3

			dec	MakroEntryStack
			bne	:3
			lda	#$00
			sta	Flag_LabelNotFound
::3			jmp	GetCurrentSektor

;*** Ziel-Adresse Branch-Befehl (BCC,BEQ,BNE...) berechnen.
.GetBranchTarget	lda	curPass			;Pass#1/#2?
			bne	:2			; => Pass#1, überspringen...

			lda	ProgEndAdr     +0	;Aktuelle Adresse einlesen.
			clc				;Max. Spungziel addieren.
;--- Hinweis:
;In MegaAss V2-V4.6 führt ein Sprung
;von 128 Bytes nach vorne zu keinem
;Fehler, im erzeugten Programm findet
;aber ein Sprung nach hinten statt.
;
;Der Fehler tritt erst ab einem Sprung
;von 129 Bytes nach vorne auf.
;
;Ein Sprung nach vorne darf aber max.
;127 Bytes betragen. Addiert man noch
;die beiden Bytes für den Branch-Befehl
;ist die Grenze nicht $82 sondern liegt
;bei $7F +2 = $81...
;			adc	#$82
			adc	#$81
			tax
			lda	ProgEndAdr     +1
			adc	#$00
			tay
			txa

			sec				;Ziel-Adresse abziehen.
			sbc	Address        +0
			tya
			sbc	Address        +1
			beq	:1			; => Gültig, weiter...

			lda	#$00
			clc
			rts

::1			lda	ProgEndAdr     +0
			clc
			adc	#$02
			sta	Vec_AdrModeTab +0
			lda	ProgEndAdr     +1
			adc	#$00
			sta	Vec_AdrModeTab +1

			lda	Address        +0
			sec
			sbc	Vec_AdrModeTab +0
			sta	Address        +0

::2			lda	#$00
			sta	Address        +1
			clc
			lda	#$01
			rts

;*** Aktuellen Sektor lesen,
.GetCurrentSektor	lda	CurrentSektor +0	;Textlaufwerk öffnen.
			jsr	NewSetDevice

			lda	CurrentSektor +1
			ldx	CurrentSektor +2
			sta	r1L
			stx	r1H
			LoadW	r4,diskBlkBuf
			jmp	GetBlock_TestKey	;Textsektor lesen.

;*** Datei-header einlesen.
.GetFileHeader		lda	VLIR_Drive
			jsr	NewSetDevice

			lda	VLIR_HdrSektor +0
			ldx	VLIR_HdrSektor +1
			sta	r1L
			stx	r1H
			LoadW	r4,fileHeader
			jmp	GetBlock

;*** Anzahl zu überlesender Bytes zu Beginn einer GeoWrite-Seite berechnen.
.GetFirstBytePos	lda	#$19
			ldy	diskBlkBuf +$02
			cpy	#$11
			bne	:1
			lda	#$1c
::1			rts

;*** Byte aus Datei (SEQ/VLIR) einlesen.
; C-Flag gelöscht: Byte einlesen.
; C-Flag gesetzt : Sektor setzen, Byte einlesen.
.GetByteFromText	bcc	:3			;Nächstes Byte lesen.
			bcs	:5

;*** Abbruch, kein weiteres Byte mehr verfügbar!
::1			sec				;Kein Byte verfügbar!
			rts

;*** Nächsten Sektor einlesen.
::2			ldx	diskBlkBuf +$00		;Nächster Sektor verfügbar ?
			beq	:1			;Nein, Ende.
			ldy	diskBlkBuf +$01
::5			stx	CurrentSektor +1	;Zeiger auf neuen Sektor
			sty	CurrentSektor +2	;zwischenspeichern.
			stx	r1L
			sty	r1H
			lda	#$01
			sta	CurrentSektor +3
			LoadW	r4,diskBlkBuf
			jsr	GetBlock_TestKey	;Neuen Sektor einlesen.

::3			inc	CurrentSektor +3	;Zeiger auf nächstes Byte.
			beq	:2			;Überlauf, neuen Sektor lesen.

			lda	diskBlkBuf +$00		;Letzter Sektor ?
			bne	:4			;Nein, weiter...

			ldx	diskBlkBuf +$01
			inx
			cpx	CurrentSektor +3	;Letztes Byte erreicht ?
			beq	:1			;Ja, Abbruch.

;*** Byte aus Sektor einlesen.
::4			ldy	CurrentSektor +3
			lda	diskBlkBuf +$00,y
			clc
			rts

;*** Sektor lesen und auf Abbruch testen.
.GetBlock_TestKey	lda	Opt_MouseCancel		;Abbruch im Menü deaktiviert?
			bne	:1			; => Ja, Block einlesen.

			php
			sei
			ldx	$01			;RAM-Status einlesen.
			lda	#$35			;I/O-Bereich einblenden.
			sta	$01
			lda	$dc01			;Tastenstatus auslesen.
			stx	$01			;RAM-Status zurücksetzen.
			plp

			cmp	#$ff			;Wurde Taste gedrückt?
			beq	:1			; => Nein, weiter...

			ldx	#$00
			stx	Flag_AutoAssInWork	;AutoAssembler beenden.
			dex
			stx	Flag_StopAssemble	;Assembler abbrechen.

::1			jmp	GetBlock		;Nächsten Block einlesen.

;*** Datei auf aktuellem Laufwerk suchen.
;    Wird die Datei nicht gefunden, dann auf
;    das andere Laufwerk wechseln.
.FindFileDrvABCD	MoveW	r6,FileNmVecBuf

			lda	#$00
			sta	:1 +1
::1			ldx	#$ff
			cpx	#$04
			beq	:2
			lda	FindFileDriveTab,x
			bne	:4
::2			lda	Opt_SourceDrive
			jsr	NewSetDevice
			ldx	#$05
::3			rts

::4			jsr	NewSetDevice

			MoveW	FileNmVecBuf,r6
			jsr	FindFile
			txa
			beq	:3

			inc	:1 +1
			jmp	:1

;*** Leere Datei erzeugen.
.EXT_SaveObjFile	lda	ProgLoadAdr  +0
			sta	Hdr_LoadAdr  +0
			lda	ProgLoadAdr  +1
			sta	Hdr_LoadAdr  +1

			lda	ProgEndAdr   +0
			clc
			adc	#$01
			sta	Hdr_EndAdr   +0
			lda	ProgEndAdr   +1
			adc	#$00
			sta	Hdr_EndAdr   +1

			lda	ProgLoadAdr  +0
			sta	Hdr_StartAdr +0
			lda	ProgLoadAdr  +1
			sta	Hdr_StartAdr +1

			jsr	GetDirHead
			txa
			beq	:2
::1			rts

::2			stx	InfoBlockTr
			stx	InfoBlockSe

			lda	Hdr_GEOS_Type		;GEOS-Dateityp = "Nicht GEOS"?
			bne	:doGEOSHdr

			stx	Header +0		;Infoblock auf Disk speichern.
			dex
			stx	Header +1
			jmp	:doEntry

;--- Infoblock erzeugen.
;			ldx	#$01			;Zeiger auf ersten Disk-Sektor.
::doGEOSHdr		inx
			stx	r3L
			stx	r3H
			jsr	SetNextFree		;Freien Sektor suchen.
			txa				;Diskfehler?
			bne	:1			; => Ja, Abbruch...

			lda	r3L			;Tr/Se für Infoblock speichern.
			sta	InfoBlockTr
			lda	r3H
			sta	InfoBlockSe

			jsr	PutDirHead		;BAM speichern.
			txa				;Diskfehler?
			bne	:1			; => Ja, Abbruch...

			stx	Header +0		;Infoblock auf Disk speichern.
			dex
			stx	Header +1

			lda	InfoBlockTr
			sta	r1L
			lda	InfoBlockSe
			sta	r1H
			LoadW	r4 ,Header
			jsr	PutBlock
			txa				;Diskfehler?
			bne	:1			; => Ja, Abbruch...

;--- Leere Datei erzeugen.
::doEntry		lda	Hdr_EndAdr  +0		;Tabelle mit Tr/Se für
			sec				;Programmdatei erzeugen.
			sbc	ProgLoadAdr +0
			sta	r2L
			lda	Hdr_EndAdr  +1
			sbc	ProgLoadAdr +1
			sta	r2H

			LoadW	r6 ,fileTrScTab
			jsr	BlkAlloc		;Sektoren reservieren.
			txa				;Diskfehler?
			bne	:1			; => Ja, Abbruch...

			jsr	PutDirHead		;BAM speichern.
			txa				;Diskfehler?
			bne	:1			; => Ja, Abbruch...

			tay				;Leeren Sektor erzeugen.
::3			sta	diskBlkBuf,y
			iny
			bne	:3
			lda	Hdr_GEOS_Type		;GEOS-Dateityp = "Nicht GEOS"?
			beq	:3a			; => Kein Infoblock.
			iny
::3a			sty	r6L			;Block-Zähler löschen.

			LoadW	r4 ,diskBlkBuf		;Reservierte Sektoren auf
			LoadW	r5 ,fileTrScTab		;Disk mit $00 füllen.
::4			ldy	#$00
			lda	(r5L),y			;Letzter Sektor gelöscht?
			beq	:7			; => Ja, Ende.
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			iny
			lda	(r5L),y
			sta	diskBlkBuf +0
			iny
			lda	(r5L),y
::5			sta	diskBlkBuf +1
			lda	#$02
			clc
			adc	r5L
			sta	r5L
			bcc	:6
			inc	r5H
::6			inc	r6L			;Block-Zähler +1
			jsr	PutBlock		;Sektor speichern.
			jmp	:4			;Weiter mit nächstem Block.

;--- Verzeichnis-Eintrag erzeugen.
::7			lda	#$00
			sta	r10L
			jsr	GetFreeDirBlk

			lda	Header     +$44
			sta	diskBlkBuf ,   y
			iny
			lda	fileTrScTab +0
			sta	diskBlkBuf ,   y
			iny
			lda	fileTrScTab +1
			sta	diskBlkBuf ,   y
			iny
			ldx	#$00
::8			lda	ObjectFileName,x
			beq	:9
			sta	diskBlkBuf ,   y
			iny
			inx
			cpx	#$10
			bne	:8
::9			cpx	#$10
			beq	:10
			lda	#$a0
			sta	diskBlkBuf ,   y
			iny
			inx
			bne	:9
::10			lda	Hdr_GEOS_Type		;GEOS-Dateityp = "Nicht GEOS"?
			beq	:10a
			lda	InfoBlockTr
::10a			sta	diskBlkBuf ,   y
			iny
			lda	Hdr_GEOS_Type		;GEOS-Dateityp = "Nicht GEOS"?
			beq	:10b
			lda	InfoBlockSe
::10b			sta	diskBlkBuf ,   y
			iny
			lda	Hdr_FileStruct
			sta	diskBlkBuf ,   y
			iny
			lda	Hdr_GEOS_Type
			sta	diskBlkBuf ,   y
			iny
			ldx	#$00
::11			lda	year       ,   x
			sta	diskBlkBuf ,   y
			iny
			inx
			cpx	#$05
			bne	:11
			lda	r6L			;Anzahl Blocks.
			sta	diskBlkBuf ,   y
			iny
			lda	#$00
			sta	diskBlkBuf ,   y
			jsr	PutBlock
			jsr	PutDirHead

			LoadW	r6,ObjectFileName
			jsr	FindFile
			txa
			bne	:12

			lda	#$02
			sta	Poi_PCodeBuf

			lda	dirEntryBuf +1
			sta	CurPCodeTr
			sta	r1L
			lda	dirEntryBuf +2
			sta	CurPCodeSe
			sta	r1H
			LoadW	r4,ProgCodeBuf
			jsr	GetBlock

			lda	Opt_SourceDrive
			jmp	NewSetDevice
::12			rts

;*** Verzeichnis-Eintrag.
:InfoBlockTr		b $00
:InfoBlockSe		b $00

;*** Byte in Programmcode einfügen.
.AddProgByte		inc	ProgEndAdr +0
			bne	:1
			inc	ProgEndAdr +1

::1			ldx	curPass			;Pass #2 ?
			bne	:4			;Nein, weiter...

			ldx	Flag_AssembleError
			bne	:4

			ldy	Poi_PCodeBuf		;Zeiger auf Datensektor.
			sta	ProgCodeBuf,y		;Byte in Sektor speichern.
			inc	Poi_PCodeBuf		;Datensektor voll ?
			bne	:3			;Nein, weiter...

			lda	#$02			;Zeiger auf erstes Byte für
			sta	Poi_PCodeBuf		;Nächsten Sektor.

			PushB	curDrive

			lda	Opt_TargetDrive
			jsr	NewSetDevice		;Ausgabelaufwerk öffnen.
			jsr	EnterTurbo
			jsr	InitForIO

			lda	CurPCodeTr
			sta	r1L
			lda	CurPCodeSe
			sta	r1H
			LoadW	r4,ProgCodeBuf
			jsr	WriteBlock		;Datensektor speichern.

			lda	ProgCodeBuf +0
			beq	:2
			ldx	ProgCodeBuf +1
			sta	CurPCodeTr
			stx	CurPCodeSe
			sta	r1L
			stx	r1H
			jsr	ReadBlock		;Speicher für nächsten Sektor
::2			jsr	DoneWithIO

			pla				;einlesen.
			jsr	NewSetDevice

::3			inc	ByteCounter +0
			bne	:4
			inc	ByteCounter +1
			bne	:4
			inc	ByteCounter +2
			bne	:4
			inc	ByteCounter +3
::4			rts

;*** Assembler-Befehl in Programmcode schreiben.
.EXT_WriteAssToPrg	lda	CurCommandLen		;Befehl definiert ?
			beq	:2			;Nein, weiter...

			lda	CurCommand +0		;Assembler-Befehl in
			jsr	AddProgByte		;Programm übertragen.
			dec	CurCommandLen
			beq	:1

			lda	CurCommand +1		;Operand-LOW-Byte in
			jsr	AddProgByte		;Programm übertragen.
			dec	CurCommandLen
			beq	:1

			lda	CurCommand +2		;Operand-HIGH-Byte in
			jsr	AddProgByte		;Programm übertragen.
			lda	#$00
			sta	CurCommandLen

::1			lda	curPass			;Befehlszähler korrigieren.
			beq	:2
			inc	CodeCounter +0
			bne	:2
			inc	CodeCounter +1
			bne	:2
			inc	CodeCounter +2
			bne	:2
			inc	CodeCounter +3

::2			rts

;*** Letzten Sektor auf Diskette speichern.
;    Endadresse festlegen.
.UpdatePrgCode		lda	Flag_AssembleError
			beq	:1
			rts

::1			lda	Opt_TargetDrive
			jsr	NewSetDevice
			lda	CurPCodeTr
			sta	r1L
			lda	CurPCodeSe
			sta	r1H
			LoadW	r4,ProgCodeBuf
			jsr	PutBlock

			ldx	#$00
			stx	Header +$00
			dex
			stx	Header +$01

			lda	ProgUserEndAdr +0
			ora	ProgUserEndAdr +1
			beq	:2

			lda	ProgUserEndAdr +0
			sta	Hdr_EndAdr     +0
			lda	ProgUserEndAdr +1
			sta	Hdr_EndAdr     +1

::2			LoadW	r6,ObjectFileName
			jsr	FindFile

			lda	dirEntryBuf +$13
			sta	r1L
			lda	dirEntryBuf +$14
			sta	r1H
			LoadW	r4,Header
			jmp	PutBlock
