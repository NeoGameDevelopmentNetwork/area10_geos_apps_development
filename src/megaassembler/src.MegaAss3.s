; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;MegaAssembler
;Compiler-Fehlermeldungen.
if .p
			t "TopSym"
			t "TopMac"
			t "src.MegaAss0.ext"
			t "src.MegaAss2.ext"
endif

			n "mod.#3"
			o $4000

.prepErr		ldy	#0
::1a			lda	CurLabelName,y
			sta	labelName,y
			iny
			cpy	#70
			bcc	:1a

			ldy	#0
::1b			lda	CurTextLine,y
			sta	textLine,y
			iny
			cpy	#200
			bcc	:1b

			ldx	#< $013f
			ldy	#> $013f
			bit	c128Flag
			bpl	:set
			bit	graphMode
			bpl	:set
			ldx	#< $027f
			ldy	#> $027f
::set			stx	:right +0
			sty	:right +1

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10
			b	$c7
			w	$0000
::right			w	$013f

			lda	screencolors
			sta	:col
			jsr	i_FillRam
			w	920
			w	COLOR_MATRIX +2*40
::col			b	$ff

			rts

;*** Bereich- und Programm-Adresse in Fehlermeldung schreiben.
.SetAreaAdress		sty	r0L
			stx	r0H
			jsr	ConvWord_ASCII		;umwandeln.

			ldy	#3
::1			lda	BufferHEX,y
			sta	DlgAreaErr2 +1,y
			dey
			bpl	:1

			lda	ProgEndAdr +0
			ldx	ProgEndAdr +1
			sta	r0L
			stx	r0H
			jsr	ConvWord_ASCII		;umwandeln.

			ldy	#3
::2			lda	BufferHEX,y
			sta	DlgAreaErr4 +1,y
			dey
			bpl	:2

			rts

;*** Dialogbox: "Pass1 und Pass2 unterschiedlich!"
.DlgPassError		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w :1
			b DBTXTSTR    ,$18,$29
			w :4
			b DBTXTSTR    ,$10,$36
			w :2
			b DBTXTSTR    ,$10,$41
			w :3
			b OK          ,$02,$48
			b NULL

::1			b "Ab dem Quelltext-Label"
			b BOLDON,NULL
::2			b PLAINTEXT
			b "stimmen die ermittelten Adressen"
			b NULL
::3			b "in Pass1 und Pass2 nicht überein!"
			b NULL

::4			b ":"
:labelName		s 70

;*** Dialogbox: "Speichergrenze überschritten!"
.DlgAreaOverflow	b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w :2
			b DBTXTSTR    ,$10,$27
			w :3
			b DBTXTSTR    ,$10,$34
			w DlgAreaErr1
			b DBTXTSTR    ,$10,$3f
			w DlgAreaErr3
			b OK          ,$02,$48
			b NULL

::2			b "Das Programm überschreitet die"
			b NULL
::3			b "definierte Bereichsgrenze:"
			b BOLDON,NULL
:DlgAreaErr1		b "Adresse Bereich: "
:DlgAreaErr2		b "$...."
			b BOLDON,NULL
:DlgAreaErr3		b "Adresse Programm: "
:DlgAreaErr4		b "$...."
			b BOLDON,NULL

;*** Dialogbox: "Testlabel überschritten!"
.DlgLabelAdress		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w :2
			b DBTXTSTR    ,$10,$27
			w :3
			b DBTXTSTR    ,$10,$34
			w DlgAreaErr1
			b DBTXTSTR    ,$10,$3f
			w DlgAreaErr3
			b OK          ,$02,$48
			b NULL

::2			b "Die vordefinierte Adresse"
			b NULL
::3			b "wurde überschritten:"
			b BOLDON,NULL

;*** Dialogbox: "Makroname fehlt".
.DlgNoMakroName		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w D01b
			b DBTXTSTR    ,$18,$29
			w textLine
			b DBTXTSTR    ,$10,$36
			w D01c
			b OK          ,$02,$48
			b NULL

:textLine		s 200

;*** Dialogobx: "Kann Datendatei nicht lesen!"
.DlgRdDataFile		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w D05a
			b DBTXTSTR    ,$18,$29
			w NameOfDataFile
			b DBTXTSTR    ,$10,$36
			w D05b
			b DBTXTSTR    ,$10,$41
			w D05c
			b OK          ,$02,$48
			b NULL

;*** Dialogobx: "Kann Textdatei nicht lesen!"
.DlgRdTextFile		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w D09a
			b DBTXTSTR    ,$18,$29
			w NameOfTextFile
			b DBTXTSTR    ,$10,$36
			w D05b
			b DBTXTSTR    ,$10,$41
			w D05c
			b OK          ,$02,$48
			b NULL

;*** Dialogobx: "Kann Textdatei nicht finden!"
.DlgFindTxtFile		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w D09a
			b DBTXTSTR    ,$18,$29
			w NameOfTextFile
			b DBTXTSTR    ,$10,$36
			w D07b
			b OK          ,$02,$48
			b NULL

;*** Dialogobx: "Kann Datendatei nicht finden!"
.DlgFindDatFile		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w D05a
			b DBTXTSTR    ,$18,$29
			w NameOfDataFile
			b DBTXTSTR    ,$10,$36
			w D07b
			b OK          ,$02,$48
			b NULL

;*** Dialogbox: "Makrodefinition nicht beendet".
.DlgMakroDef		b $81
			b DBTXTSTR     ,$10,$0e
			w DlgHeader1
			b DBTXTSTR     ,$10,$1c
			w D10b
			b OK           ,$02,$48
			b NULL

;*** Dialogbox: "Symbolspeicher ist voll!"
.DlgIncStackFull	b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader1
			b DBTXTSTR    ,$10,$1c
			w D11b
			b OK          ,$02,$48
			b NULL

;*** Dialogbox: "Makrospeicher ist voll!"
.DlgMakStackFull	b $81
			b DBTXTSTR    ,$10,$10
			w DlgHeader1
			b DBTXTSTR    ,$10,$1c
			w D12b
			b OK          ,$02,$48
			b NULL

;*** Dialogbox: "Symbolspeicher ist voll!"
.DlgSymbTabFull		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader1
			b DBTXTSTR    ,$10,$1c
			w D13b
			b OK          ,$02,$48
			b NULL

;*** Dialogobx: "Kann Objektdatei nicht speichern!"
.DlgSaveError		b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w D14a
			b DBTXTSTR    ,$10,$27
			w D14b
			b DBTXTSTR    ,$10,$32
			w D14c
			b OK          ,$02,$48
			b NULL

;*** Dialogobx: "Kann Quelltextdatei nicht finden!"
.DlgSourceNotFound	b $81
			b DBTXTSTR    ,$10,$0e
			w DlgHeader2
			b DBTXTSTR    ,$10,$1c
			w D09b
			b DBTXTSTR    ,$18,$29
			w SelectedFile
			b DBTXTSTR    ,$10,$36
			w D07b
			b OK          ,$02,$48
			b NULL

.DlgHeader1		b BOLDON
			b "Achtung!"
			b PLAINTEXT,NULL
.DlgHeader2		b BOLDON
			b "Schwerer Fehler!"
			b PLAINTEXT,NULL

:D05a			b "Die Datendatei"
			b BOLDON,NULL
:D05b			b PLAINTEXT
			b "kann wegen eines Diskettenfehlers"
			b NULL
:D05c			b "nicht gelesen werden !"
			b NULL
:D09a			b "Die Textdatei"
			b BOLDON,NULL
:D07b			b PLAINTEXT
			b "ist nicht zu finden!"
			b NULL
:D09b			b "Die Quelltextdatei"
			b BOLDON,NULL

:D01b			b "Bei der Makrodefinition"
			b NULL
:D01c			b "fehlt ein (gültiger) Makroname."
			b NULL
:D10b			b "Das Ende der Makrodefinition fehlt."
			b NULL
:D11b			b "Speicher für Includetexte ist voll!"
			b NULL
:D12b			b "Speicher für Makrotexte ist voll!"
			b NULL
:D13b			b "Speicher für Symbole/Makros ist voll!"
			b NULL
:D14a			b "Die Objektcodedatei kann wegen"
			b NULL
:D14b			b "eines Diskettenfehlers nicht"
			b NULL
:D14c			b "erzeugt werden !"
			b NULL
