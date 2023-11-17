; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_GRFX"
			t "SymbTab_GSPR"
endif

;*** GEOS-Header.
			n "obj.SpoolPrinter"
			t "G3_Data.V.Class"

			o PRINTBASE

;******************************************************************************
;Flag_Spooler		b $80				;$80 = Spooler installiert.
;							;$40 = Spooler-Menü starten.
;							;$3f = Zähler für Spooler.
;Flag_SpoolMinB		b $01				;Erste  Bank für Druckerspooler.
;Flag_SpoolMaxB		b $02				;Letzte Bank für Druckerspooler.
;Flag_SpoolADDR		w $0000				;Position in Zwischenspeicher.
;			b $01
;Flag_SpoolCount	b $03				;Verzögerung für Druckerspooler.
;Flag_SplCurDok		b $00				;Aktuelles Dokument.
;Flag_SplMaxDok		b $00				;Max. Anzahl Dokumente im Speicher.
;Flag_SpoolActiv	b $00				;$00 = Spooler noch nicht initialisiert.
;							;$FF = Spooler bereits initialisiert.
;							;Dieses Byte wird gesetzt ($FF) wenn die ersten
;							;Daten in den Speicher übertragen werden. Das Byte
;							;wird erst dann gelöscht ($00) wenn alle Daten aus
;							;dem Puffer gedruckt wurden.
;******************************************************************************

;******************************************************************************
;$F0 =  640 Byte Grafikdaten.
;$F1 =   80 Byte Farbdaten.
;$F2 =  xyz Byte Textdaten.
;      Nach dem $F2-Opcode folgt ein Word mit dem Anzahl der Text-Zeichen,
;      inclusive des Abschluß-$00-Bytes!
;$F3 = xyz Byte Daten (Funktion unklar, Übernahme aus MP3.0/2003)
;$FE = Neues Dokument.
;$FF = Seitenende.
;$00 = Ende.
;******************************************************************************

;*** Sprungtabelle.
:xInitForPrint		ldx	#0
			rts
:xStartPrint		jmp	InitSprites
:xPrintBuffer		jmp	SpoolGrafx		;Grafikdaten speichern.
:xStopPrint		jmp	SpoolStop		;Seitenende markieren.
:xGetDimensions		jmp	SpoolDim		;Seitengröße uebergeben.
:xPrintASCII		jmp	SpoolASCII		;ASCII-Daten speichern.
:xStartASCII		jmp	InitSprites
:xSetNLQ		ldx	#$00			;SetNLQ      , nicht benötigt.
			rts
:xPrintDATA		jmp	SpoolDATA		;Übernahme aus MP3.0/2003.
							;(Genaue Funktion unklar)

;*** Externe Routine zum Aufruf von ":GetDimensions."
;    Dazu wird der Original-Druckertreiber eingelesen und ":GetDimensions"
;    aufgerufen. Danach wirder der Spoolertreiber wieder eingelesen und die
;    Seitenabmessungen an die Applikation zurückgegeben.
:GetPageSizeStart	s $03				;Zwischenspeicher für Register.

:GetOrgDIM_Data		ldx	#$1f
::51			lda	r0L,x			;Register ":r0" bis ":r15"
			pha				;zwischenspeichern.
			dex
			bpl	:51

			jsr	DefPrntAddr		;DruckerSpooler in RAM
			jsr	StashRAM		;aktualisieren.

			jsr	SetADDR_Printer		;Zeiger auf Druckertreiber.
			jsr	FetchRAM		;Druckertreiber einlesen.

			jsr	GetDimensions		;Seitenlänge bestimmen.
			sta	diskBlkBuf +0		;Register zwischenspeichern.
			stx	diskBlkBuf +1
			sty	diskBlkBuf +2

			jsr	DefPrntAddr		;DruckerSpooler aus RAM
			jsr	FetchRAM		;wieder einlesen.

			ldx	#$00
::52			pla
			sta	r0L,x			;Register ":r0" bis ":r15"
			inx				;wieder zurückschreiben.
			cpx	#$20
			bne	:52

			lda	diskBlkBuf +0		;Seitenlaenge an Applikation
			ldx	diskBlkBuf +1		;uebergeben.
			ldy	diskBlkBuf +2
			rts

;*** Zeiger auf DruckerSpooler in REU.
:Temp			LoadW	r0 ,PRINTBASE
			LoadW	r1 ,R3_ADDR_PRNSPLTMP
			LoadW	r2 ,R3_SIZE_PRNSPLTMP
			MoveB	MP3_64K_DATA,r3L
			rts

:DefPrntAddr		= (Temp - GetPageSizeStart) + diskBlkBuf
:GetPageSizeEnd		b $00

;*** Druckdaten an Applikation übergeben.
:SpoolDim		ldy	#$00
::51			lda	GetPageSizeStart,y
			sta	diskBlkBuf      ,y
			iny
			cpy	#(GetPageSizeEnd - GetPageSizeStart)
			bne	:51
			jmp	diskBlkBuf +3

;*** Grafikdaten in Druckspeicher übertragen.
;    Für eine Zeile wird max. an Bytes benötigt:
;    $FE		= Dokumentstart
;      b Dok.-Nr.	= Nr. des aktuellen Dokuments.
;      b "Name",0	= 16 Zeichen Dokumentname + Null-Byte.
;    $F0		= Kennung für Grafikdaten.
;      s 640		= 640-Byte Grafikdaten.
;    $F1		= Kennung für Farbdaten.
;      s 80		= 80-Byte Farbdaten.
;    $00		= Abschlußbyte.
;    $FF		= Seitenende.
;    $00		= Abschlußbyte.
;    --------------------------------------------------------------------------
;    Gesamt:		= max. 744 Bytes.
;******************************************************************************
:SpoolGrafx		jsr	ResetSpoolDelay		;Aktivierungsszeit zurücksetzen.
			jsr	CalcInfoSprite		;Anzeige initialisieren.

::51			lda	#< 744
			ldx	#> 744
			jsr	TestMemFree		;Genügend Speicher für neue Zeile ?
			bcc	:52			; => Ja, weiter...
			jsr	PrintSpoolMem		;Druck-Speicher leeren.
			jmp	:51

::52			lda	r2L			;Zeiger auf Farbdaten retten.
			pha
			lda	r2H
			pha

			jsr	StartNewDok		;Neues Dokument initialisieren.

			lda	#$f0			;Kennbyte für Grafikdaten.
			jsr	SaveByte
			lda	#<640			;Grafikdaten in Druck-Speicher.
			ldx	#>640
			jsr	SaveData

			pla				;Zeiger auf Farbdaten zurücksetzen.
			sta	r0H
			pla
			sta	r0L
			ora	r0H			;Farbe definiert ?
			beq	:53			;Nein, weiter...

			lda	#$f1			;Kennbyte für Farbdaten.
			jsr	SaveByte
			lda	#<80			;Farbdaten in Druck-Speicher.
			ldx	#>80
			jsr	SaveData

::53			jmp	SetEndByte		;Abschlußbyte senden.

;*** Textdaten in Druckspeicher übertragen.
;    Für eine Zeile wird max. an Bytes benötigt:
;    $FE		= Dokumentstart
;      b Dok.-Nr.	= Nr. des aktuellen Dokuments.
;      b "Name",0	= 16 Zeichen Dokumentname + Null-Byte.
;    $F2		= Kennung für Textdaten.
;    $00		= Abschlußbyte.
;    $FF		= Seitenende.
;    $00		= Abschlußbyte.
;    --------------------------------------------------------------------------
;    Gesamt:		= max. 23 + xy Bytes.
;      s xy		= xy-Byte Textdaten.
;******************************************************************************
:SpoolASCII		jsr	ResetSpoolDelay		;Aktivierungsszeit zurücksetzen.
			jsr	CalcInfoSprite		;Anzeige initialisieren.

::51			jsr	GetMaxBytes		;Anzahl Bytes berechnen.
			jsr	TestMemFree		;Genügend Speicher für neue Zeile ?
			bcc	:52			; => Ja, weiter...
			jsr	PrintSpoolMem		;Druck-Speicher ausgeben.
			jmp	:51

::52			jsr	StartNewDok		;Neues Dokument initialisieren.

			lda	#$f2			;Kennbyte für Textdaten.
			jsr	SaveByte
			lda	r5L			;Anzahl Textzeichen in Druck-
			jsr	SaveByte		;Speicher kopieren.
			lda	r5H
			jsr	SaveByte

			lda	r5L			;Textdaten in Druck-Speicher.
			ldx	r5H
			jsr	SaveData
			jmp	SetEndByte		;Abschlußbyte senden.

;*** Anzahl benötigter Bytes für eine Druckzeile ermitteln.
:GetMaxBytes		PushW	r0			;Zeiger auf Textdaten retten.

			ldy	#$01			;Zähler für Textbytes
			sty	r5L			;initialisieren.
			dey
			sty	r5H
::51			lda	(r0L),y			;Textzeichen einlesen.
			beq	:53			;Ende ? => Ja, weiter...
			inc	r0L			;Zeiger auf nächstes Zeichen.
			bne	:52
			inc	r0H

::52			inc	r5L			;Anzahl Zeichen korrigieren.
			bne	:51
			inc	r5H
			bne	:51

::53			PopW	r0			;Zeiger auf Text zurücksetzen.

			lda	r5L			;Anzahl Zusatzbytes addieren.
			clc
			adc	#< 23
			tay
			lda	r5H
			adc	#> 23
			tax
			tya
			rts

;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: In der Version von 2003 wurde der Steuerbefehl $F3
;ergänzt. Genaue Funktion noch unklar.
;*** Daten in Druckspeicher übertragen.
;    Für eine Zeile wird max. an Bytes benötigt:
;    $FE		= Dokumentstart
;      b Dok.-Nr.	= Nr. des aktuellen Dokuments.
;      b "Name",0	= 16 Zeichen Dokumentname + Null-Byte.
;    $F3		= Kennung für Daten.
;    $00		= Abschlußbyte.
;    $FF		= Seitenende.
;    $00		= Abschlußbyte.
;    --------------------------------------------------------------------------
;    Gesamt:		= max. 23 + xy Bytes.
;      s xy		= xy-Byte Daten.
;******************************************************************************
:SpoolDATA		jsr	ResetSpoolDelay		;Aktivierungsszeit zurücksetzen.
			jsr	CalcInfoSprite		;Anzeige initialisieren.

::51			jsr	AddExtraBytes		;Anzahl Bytes berechnen.
			jsr	TestMemFree		;Genügend Speicher für neue Zeile ?
			bcc	:52			; => Ja, weiter...
			jsr	PrintSpoolMem		;Druck-Speicher ausgeben.
			jmp	:51

::52			jsr	StartNewDok		;Neues Dokument initialisieren.

			lda	#$f3			;Kennbyte für Daten.
			jsr	SaveByte
			lda	r5L			;Anzahl Daten in Druck-
			jsr	SaveByte		;Speicher kopieren.
			lda	r5H
			jsr	SaveByte

			lda	r5L			;Daten in Druck-Speicher.
			ldx	r5H
			jsr	SaveData
			jmp	SetEndByte		;Abschlußbyte senden.

;*** Anzahl benötigter Bytes für eine Druckzeile ermitteln.
:AddExtraBytes		lda	r2L
			sta	r5L
			lda	r2H
			sta	r5H
			lda	r5L			;Anzahl Zusatzbytes addieren.
			clc
			adc	#< 23
			tay
			lda	r5H
			adc	#> 23
			tax
			tya
			rts

;*** Neues Dokument beginnen.
:StartNewDok		lda	Flag_SplMaxDok		;Max. Anzahl Dokumente im Spooler?
			beq	ContinueDok		;Nein, weiter.

			bit	FirstByte		;Kennbyte für "Neues Dokument"
			bmi	CancelNewDok		;bereits übertragen ? => Ja, weiter.

:ContinueDok		inc	Flag_SplCurDok
			inc	Flag_SplMaxDok

:ContinueDokOld		lda	#$fe			;Kennbyte für "Neues Dokument"
			jsr	SaveByte		;in Druck-Speicher übertragen.
			lda	Flag_SplCurDok		;Nr. des aktuellen Dokuments
			jsr	SaveByte		;in DruckerSpooler übertragen.
			jsr	SaveDokName		;Dokument-Name übertragen.
			lda	#$ff
			sta	FirstByte
:CancelNewDok		rts

;*** Name des aktuellen Dokuments erstellen.
:SaveDokName		ldy	#$02			;Name definieren. Dazu werden
			lda	day			;Datum und Uhrzeit als Vorein-
			jsr	PutDokNmByte		;stellung übernommen.
			lda	month
			jsr	PutDokNmByte
			lda	hour
			jsr	PutDokNmByte
			lda	minutes
			jsr	PutDokNmByte
			lda	seconds
			jsr	PutDokNmByte

			ldy	#$00
::51			sty	:52 +1			;Dokumentname an Druckerspooler
			lda	DokName,y		;übergeben.
			jsr	SaveByte
::52			ldy	#$ff
			iny
			cpy	#17
			bcc	:51
			rts

;*** DEZIMAL nach ASCII wandeln.
:PutDokNmByte		ldx	#$30
::101			cmp	#10
			bcc	:102
			inx
			sbc	#10
			bcs	:101
::102			adc	#$30
			pha
			txa
			sta	DokName,y
			iny
			pla
			sta	DokName,y
			iny
			iny
			rts

;*** Zähler für Spooler zurücksetzen.
:ResetSpoolDelay	lda	#%10000000		;Zähler für DruckMenü zurücksetzen.
			ora	Flag_SpoolCount
			sta	Flag_Spooler
			rts

;*** Seite abschließen.
:SpoolStop		jsr	CalcInfoSprite		;Anzeige initialisieren.
			jsr	KillSprites		;Sprites abschalten.

			lda	#$ff			;Kennbyte für Seitenende.
			jsr	SaveByte
			jsr	ResetSpoolDelay		;Aktivierungsszeit zurücksetzen.

;*** Abschlußbyte senden.
:SetEndByte		PushW	Flag_SpoolADDR +0	;Zeiger auf Druck-Speicher
			PushB	Flag_SpoolADDR +2	;zwischenspeichern.
			lda	#$00			;$00-Byte als Abschluß-Byte senden.
			jsr	SaveByte
			PopB	Flag_SpoolADDR +2	;Zeiger auf Druck-Speicher
			PopW	Flag_SpoolADDR +0	;zurücksetzen.

			ldx	#$00			;Flag für "Kein Fehler".
			rts

;*** Speicher voll, => ausdrucken und wieder freigeben.
:PrintSpoolMem		ldx	#$00			;ZeroPage speichern.
::52			lda	r0L         ,x
			sta	ZeroPageBuf ,x
			inx
			cpx	#$20
			bne	:52

			jsr	KillSprites		;Sprites abschalten.

			lda	#> :53        -1	;Zeiger auf Routine nach beenden
			pha				;des Druck-Menüs.
			lda	#< :53        -1
			pha
			lda	#> SwapRAM    -1	;Zeiger auf Routine SwapRAM um
			pha				;Speicher wieder zurückzusetzen.
			lda	#< SwapRAM    -1
			pha
			lda	#> LD_ADDR_SPOOLER -1	;Zeiger auf Druck-Menu.
			pha
			lda	#< LD_ADDR_SPOOLER -1
			pha
			jsr	SetADDR_Spooler		;Zeiger auf Routine für Druck-Menü.
			jmp	SwapRAM			;Druck-Menü einlesen. Nach beenden
				 			;von SwapRAM erfolgt ein RTS zu
							;"G3_SpoolAll" (alle Daten drucken).
							;Nach dem Druck-Menü erfolgt ein RTS
							;zu SwapRAM, damit der Speicher
							;wieder zurückgesetzt wird. Mit dem
							;letzten RTS wird das Programm
							;fortgesetzt, IT'S COOL MAN...

::53			jsr	InitSprites		;Anzeige initialisieren.

			ldx	#$00			;ZeroPage zurücksetzen.
::54			lda	ZeroPageBuf ,x
			sta	r0L         ,x
			inx
			cpx	#$20
			bne	:54

			jmp	ContinueDok

;*** Prüfen ob genügend Speicher im DruckerSpooler frei ist.
;    Übergabe: AKKU/XREG = Anzahl Bytes LOW/HIGH.
:TestMemFree		clc
			adc	Flag_SpoolADDR +0
			txa
			adc	Flag_SpoolADDR +1
			lda	#$00
			adc	Flag_SpoolADDR +2
			cmp	Flag_SpoolMaxB
			beq	:51
			bcs	:52
::51			clc
			rts
::52			sec
			rts

;*** Befehlsbyte in Speicher übertragen.
;    Übergabe: AKKU = Befehlsbyte.
:SaveByte		sta	BufferByte		;Befehlsbyte speichern.
			PushW	r0
			LoadW	r0,BufferByte
			LoadW	r2,1
			MoveW	Flag_SpoolADDR +0,r1
			MoveB	Flag_SpoolADDR +2,r3L
			jsr	StashRAM		;Byte in REU kopieren.
			PopW	r0
			lda	#$01
			ldx	#$00
			jmp	AddBytes

;*** Daten in Speicher übertragen.
;    Übergabe: AKKU = Befehlsbyte.
:SaveData		sta	r2L			;Anzahl Bytes speichern.
			stx	r2H

			lda	r2H			;Anzahl Bytes auf Stack retten.
			pha
			lda	r2L
			pha

			lda	Flag_SpoolADDR +0	;Startadresse SpoolerRAM innerhalb
			sta	r1L			;64K-Speicherbank.
			lda	Flag_SpoolADDR +1
			sta	r1H
			ldx	Flag_SpoolADDR +2	;Zeiger auf aktuelle Speicherbank.

			lda	r1L			;Über 64K-Speichergrenze hinweg
			clc				;Datenbytes in REU speichern ?
			adc	r2L
			sta	r3L
			lda	r1H
			adc	r2H
			bcc	:51			; => Nein, weiter...
			ora	r3L
			beq	:51			; => Nein, weiter...

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

			ldx	Flag_SpoolADDR +2	;Zeiger auf aktuelle Speicherbank.
			stx	r3L
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

			ldx	r3L			;Zeiger auf nächste Speicherbank
			inx				;für Restbytes setzen.

::51			stx	r3L			;Zeiger auf Speicherbank setzen.
			jsr	StashRAM		;Bytes in REU kopieren.

			pla
			tay
			pla
			tax
			tya

;*** Anzahl Bytes zu Speicher-Vektor addieren.
;    Übergabe: AKKU/XREG = Anzahl Bytes LOW/HIGH.
:AddBytes		clc
			adc	Flag_SpoolADDR +0
			sta	Flag_SpoolADDR +0
			txa
			adc	Flag_SpoolADDR +1
			sta	Flag_SpoolADDR +1
			lda	#$00
			adc	Flag_SpoolADDR +2
			sta	Flag_SpoolADDR +2
			rts

;*** Sprites initialisieren.
:KillSprites		ldy	#62			;Grafikspeicher für Sprites
::51			lda	spr6Buf   ,y		;zurücksetzen.
			sta	spr6pic   ,y
			lda	spr7Buf   ,y
			sta	spr7pic   ,y
			dey
			bpl	:51

			lda	obj6Buf			;Spritezeiger zurücksetzen.
			sta	obj6Pointer
			lda	obj7Buf
			sta	obj7Pointer

			php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	mobenbleBuf		;Spritedaten zurücksetzen.
			sta	mobenble

			ldy	#$03
::52			lda	sprXYBuf,y
			sta	mob6xpos,y
			dey
			bpl	:52
			lda	sprXYBuf +4
			sta	msbxpos

			lda	mobx2Buf
			sta	mobx2
			lda	moby2Buf
			sta	moby2

			lda	col6Buf
			sta	$d02d
			lda	col7Buf
			sta	$d02e

			stx	CPU_DATA
			plp
			rts

;*** Sprites initialisieren.
:InitSprites		lda	Flag_SplMaxDok
			cmp	#MAX_SPOOL_DOC		;Druckspeicher voll ?
			bcc	:50			; => Nein, weiter...
			ldx	#$0d			;Zuviele Dokumente in
::rts			rts				;Warteschlange, Ende...

::50			ldy	#62			;Spritegrafik retten und
::51			lda	spr6pic   ,y		;Anzeige-Sprites definieren.
			sta	spr6Buf   ,y
			lda	SprBufCalc,y
			sta	spr6pic   ,y
			lda	spr7pic   ,y
			sta	spr7Buf   ,y
			lda	#$ff
			sta	spr7pic   ,y
			dey
			bpl	:51

			lda	obj6Pointer		;Spritezeiger setzen.
			sta	obj6Buf
			lda	obj7Pointer
			sta	obj7Buf

			ldx	#$2e
			stx	obj6Pointer
			inx
			stx	obj7Pointer

			php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			lda	mobenble		;Spritefarben setzen.
			sta	mobenbleBuf

			ldy	#$03
::52			lda	mob6xpos,y
			sta	sprXYBuf,y
			dey
			bpl	:52
			lda	msbxpos
			sta	sprXYBuf +4

			lda	mobx2
			sta	mobx2Buf
			and	#%00111111
			sta	mobx2
			lda	moby2
			sta	moby2Buf
			and	#%00111111
			sta	moby2

			lda	$d02d
			sta	col6Buf
			lda	$d02e
			sta	col7Buf

			lda	#$00
			sta	$d02d
			lda	#$07
			sta	$d02e

			stx	CPU_DATA
			plp

;*** Info-Anzeige berechnen.
:CalcInfoSprite		PushW	r0			;Register ":r0" bis ":r2" sichern.
			PushW	r1
			PushW	r2

			LoadB	r3L,6			;Sprites aktivieren.
			LoadW	r4 ,288			;X-Koordinate
			LoadB	r5L,171			;Y-Koordinate
			jsr	PosSprite
			jsr	EnablSprite
			inc	r3L
			jsr	PosSprite
			jsr	EnablSprite

			lda	Flag_SpoolADDR +1	;Vektor * 21 Pixel (Sprite-Höhe).
			sta	r0L
			lda	Flag_SpoolADDR +2
			sec
			sbc	Flag_SpoolMinB
			sta	r0H
			LoadW	r1,21
			ldx	#r0L
			ldy	#r1L
			jsr	DMult

			lda	#$00			;Ergebnis / Anzahl Druck-Bytes.
			sta	r1L
			lda	Flag_SpoolMaxB
			sec
			sbc	Flag_SpoolMinB
			clc
			adc	#$01
			sta	r1H
			ldx	#r0L
			ldy	#r1L
			jsr	Ddiv

			lda	#20			;Höhe des Anzeigebalken berechnen.
			sec
			sbc	r0L
			bcs	:51a
			lda	#0
::51a			sta	:51 +1
			asl
			clc
::51			adc	#$ff			;Anzeigebalken definieren.
			clc
			adc	#$02
			tay
			lda	#$ff
::52			sta	spr6pic,y
			iny
			iny
			iny
			cpy	#63
			bcc	:52

			PopW	r2			;Register ":r0" bis ":r2"
			PopW	r1
			PopW	r0			;zurücksetzen.
			ldx	#$00			;Flag für "Kein Fehler".
			rts

;*** Druckdatenspeicher.
:BufferByte		b $00
:FirstByte		b $00
:ZeroPageBuf		s 32
:DokName		b "D 00.00/00:00:00",NULL

:spr6Buf		s 63
:spr7Buf		s 63
:obj6Buf		b $00
:obj7Buf		b $00

:col6Buf		b $00
:col7Buf		b $00
:sprXYBuf		s $05
:mobx2Buf		b $00
:moby2Buf		b $00
:mobenbleBuf		b $00

:SprBufCalc		b %00000000,%00000111,%11111111
			b %00100110,%00110000,%10000001
			b %01101001,%01001000,%10000001
			b %00101001,%01001000,%10000001
			b %00101001,%01001000,%10000001
			b %00100110,%00110000,%10000001
			b %00000000,%00000000,%10000001
			b %00000000,%00000000,%10000001
			b %01100100,%00000000,%10000001
			b %01101000,%00000000,%10000001
			b %00010000,%00000111,%10000001
			b %00101100,%00000000,%10000001
			b %01001100,%00000000,%10000001
			b %00000000,%00000000,%10000001
			b %00000000,%00000000,%10000001
			b %00000000,%00110000,%10000001
			b %00000000,%01001000,%10000001
			b %00000000,%01001000,%10000001
			b %00000000,%01001000,%10000001
			b %00000000,%00110000,%10000001
			b %00000000,%00000111,%11111111

;--- Ergänzung: 30.12.18/M.Kanet
;Größe des Spoolers und Druckertreiber im RAM um 1Byte reduziert.
;geoCalc64 nutzt beim Drucken ab $5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert. Wird der gesamte Speicher
;getauscht führt das zum Absturz in geoCalc.
;SetADDR_Printer und SetADDR_PrnSpool dürfen max. bis $7F3E reichen.
;Siehe auch Datei "-G3_SetVecRAM".

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g APP_VAR -1 -1
;******************************************************************************
