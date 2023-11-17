; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Drucker wählen.
:SelectPrinter		LoadW	V172b1      ,V172b2
			LoadW	VecFileInfo ,V172c0
			LoadW	Vec1File    ,FileNTab
			LoadB	MaxReadFiles,255
			lda	#PRINTER
			ldx	#<PrntFileName
			ldy	#>PrntFileName
			jsr	GetDriver

			bit	c128Flag
			bmi	:101
			rts

::101			jsr	LoadPrinter		;Druckertreiber laden.
			txa
			beq	:102
			rts

::102			LoadW	r0,$7900		;Startadresse Druckertreiber im RAM.
			LoadW	r1,$d9c0		;Startadresse Druckertreiber in REU.
			LoadW	r2,$0640		;Länge Druckertreiber.
			LoadB	r3L,$01			;RAM-Bank.
			sta	r3H
			jsr	MoveBData		;Druckertreiber in RAM kopieren.
			LoadW	r0H,$81			;Zeiger auf Infoblock.
			dec	r1H			;Zeiger auf Speicher für Infoblock.
			LoadW	r2,$0100		;Länge Infoblock.
			jsr	MoveBData		;Infoblock in Speicher verschieben.
			ldx	#$00
			rts

;*** Druckertreiber laden.
:LoadPrinter		jsr	PrepGetFile

			LoadW	r6,PrntFileName
			LoadW	r7,PRINTBASE
			LoadB	r0L,%00000001
			jmp	GetFile

;*** Eingabetreiber wählen.
:SelectInput		LoadW	V172b1,V172b3
			LoadW	VecFileInfo,V172c1
			LoadW	Vec1File,FileNTab
			LoadB	MaxReadFiles,255
			lda	#INPUT_DEVICE
			ldx	#<inputDevName
			ldy	#>inputDevName
			jmp	GetDriver

;*** Drucker/Eingabetreiber wählen.
:GetDriver		sta	FileType
			stx	VecFileName+0
			sty	VecFileName+1

:GetDriver2		jsr	i_FillRam
			w	17 * 256
			w	FileNTab
			b	$00

			jsr	InitGetFile

;*** Treiberdateien suchen.
:LoadFileTab		jsr	InitFileTab

;*** Datei aus Tabelle auswählen.
:DoSlctFile		lda	#<V172b0
			ldx	#>V172b0
			jsr	SelectBox		;Verzeichnisauswahlbox.

			cmp	#$00			;Dateiauswahl ?
			beq	LoadDriver		;Nein, weiter...
			cmp	#$80
			bcc	ExitSelect
			cmp	#$90
			beq	:101

			pha
			jsr	Ld2DrvData
			pla
			and	#%01111111
			add	8			;Neue Laufwerksadr. berechnen.
			jsr	NewDrive		;Laufwerk aktivieren.
			jmp	GetDriver2

::101			jsr	CMD_NewTarget

			jsr	DoInfoBox
			MoveW	VecFileInfo,r0
			jsr	PutString
			jmp	LoadFileTab

;*** Treibername kopieren.
:LoadDriver		MoveW	VecFileName,r0

			ldy	#15
::101			lda	(r15L),y		;Dateiname in
			sta	(r0L),y			;Zwischenspeicher kopieren.
			dey
			bpl	:101

			ldx	#$00
			b $2c

;*** Auswahl beenden.
:ExitSelect		ldx	#$ff
			rts

;*** Dateiauswahl initialisieren.
:InitGetFile		jsr	ClrScreen

			jsr	DoInfoBox

			MoveW	VecFileInfo,r0
			jsr	PutString

			jmp	Sv2DrvData

;*** Dateitabelle initialisieren.
:InitFileTab		jsr	CheckDiskCBM
			txa
			bne	NoFilesOnDsk

			MoveW	Vec1File    ,r6
			MoveB	FileType    ,r7L
			MoveB	MaxReadFiles,r7H
			ClrW	r10
			jsr	FindFTypes

;*** Dateinamen konvertieren.
:PrepFileTab		jsr	ConvertFNames
:NoFilesOnDsk		jmp	ClrBox

;*** Dateienamen nach 16Z. konvertieren.
:ConvertFNames		lda	Vec1File +0
			sta	r14L
			sta	r15L
			lda	Vec1File +1
			sta	r14H
			sta	r15H

::101			CmpB	r7H,MaxReadFiles
			beq	:103

			ldy	#0
::102			lda	(r15L),y		;GEOS 17 Zeichen nach
			sta	(r14L),y		;GeoDOS 16 Zeichen.
			iny
			cpy	#16
			bne	:102

			AddVBW	17,r15
			AddVBW	16,r14

			inc	r7H
			jmp	:101

::103			ldy	#0			;Ende der Tabelle merkieren
			tya
			sta	(r14L),y
			rts

;*** Variablen.
:FileType		b $00				;"PRINTER" oder "INPUT_DEVICE"
:VecFileName		w $0000				;Adresse für Treibername.
:VecFileInfo		w $0000				;Adresse für Infotext.
:Vec1File		w $0000				;Startadresse für Dateinamenspeicher.
:MaxReadFiles		b $00				;Max. Anzahl Dateien.

;*** Dialogboxen.
:V172b0			b $04
			b $ff
			b $00
			b $10
			b $00
:V172b1			w V172b1
			w FileNTab

if Sprache = Deutsch
;*** Titel für Dialogboxen.
:V172b2			b PLAINTEXT,"Druckertreiber wählen",NULL
:V172b3			b PLAINTEXT,"Eingabegerät wählen",NULL

;*** Info: "Druckertreiber werden eingelesen..."
:V172c0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Druckertreiber"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL

;*** Info: "Druckertreiber werden eingelesen..."
:V172c1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Eingabegeräte"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL
endif

if Sprache = Englisch
;*** Titel für Dialogboxen.
:V172b2			b PLAINTEXT,"Select printer",NULL
:V172b3			b PLAINTEXT,"Select input-device",NULL

;*** Info: "Druckertreiber werden eingelesen..."
:V172c0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "printerdriver..."
			b NULL

;*** Info: "Druckertreiber werden eingelesen..."
:V172c1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "inputdriver..."
			b NULL
endif
