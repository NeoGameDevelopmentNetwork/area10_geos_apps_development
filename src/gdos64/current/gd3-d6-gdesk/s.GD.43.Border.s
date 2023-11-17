; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Datei mit BorderBlock tauschen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_DISK"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
endif

;*** GEOS-Header.
			n "obj.GD43"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	SwapBorder

;*** Datei mit Borderblock tauschen.
:SwapBorder		jsr	GetBorderBlock		;Borderblock überprüfen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...
;			tya				;GEOS-Diskette?
;			bne	:exit			; => Nein, Abbruch...

			MoveB	r1L,r13L		;Adresse Borderblock sichern.
			MoveB	r1H,r13H
			LoadW	r4,fileHeader
			jsr	GetBlock		;Borderblock einlesen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			MoveW	fileEntryVec,r0		;Zeiger auf Datei-Eintrag.
			LoadW	r11,fileHeader		;Zeiger auf Borderblock.

			lda	#$ff			;Flag setzen:
			sta	r14L			;"Eintrag nicht gefunden".

::search		ldy	#$02
			lda	(r11L),y		;Freier Eintrag im Borderblock?
			bne	:byte			; => Nein, weiter...

			lda	r14L
			cmp	#$ff			;Erster freier Eintrag?
			bne	:byte			; => Nein, weiter...

			lda	r11L			;Adresse des ersten freien Eintrag
			sta	r14L			;zwischenspeichern.

::byte			lda	(r0L),y
			cmp	(r11L),y		;Eintrag gefunden?
			bne	:next			; => Nein, nächster Eintrag...
			iny
			cpy	#$20			;Alle Bytes überprüft?
			bcc	:byte			; => Nein, weiter...

			jmp	Move2Disk		;Borderblock => Verzeichnis.

::next			AddVBW	32,r11			;Alle Einträge geprüft?
			bcc	:search			; => Nein, weiter...

			jmp	Move2Border		;Verzeichnis => Borderblock.

::exit			rts				;Abbruch...

;*** BorderBlock: Dateien in Verzeichnis übertragen.
:Move2Disk		lda	#$00			;Zeiger auf Verzeichnisanfang.
			sta	r10L
			jsr	GetFreeDirBlk		;Freien Eintrag suchen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			tya				;Zeiger auf Verzeichniseintrag
			and	#%11100000		;berechnen.
			clc
			adc	#< diskBlkBuf
			sta	r12L
			lda	#$00
			adc	#> diskBlkBuf
			sta	r12H

			ldy	#2
::copy			lda	(r11L),y		;Verzeichniseintrag vom Borderblock
			sta	(r12L),y		;in Verzeichnis verschieben.
			lda	#$00
			sta	(r11L),y
			iny
			cpy	#32
			bcc	:copy

;			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnisblock aktualisieren.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			MoveB	r13L,r1L
			MoveB	r13H,r1H
			LoadW	r4,fileHeader
			jsr	PutBlock		;Borderblock aktualisieren.
;			txa				;Diskettenfehler?
;			bne	:exit			; => Ja, Abbruch...

;			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** BorderBlock: Dateien in Verzeichnis übertragen.
:Move2Border		lda	r14L
			cmp	#$ff			;Eintrag in Borderblock frei?
			bne	:init			; => Ja, weiter...

			LoadW	r0,Dlg_BorderFull
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

			ldx	#NO_ERROR
			rts

::init			sta	r11L			;Verzeichniseintrag in Borderblock
			lda	#> fileHeader		;berechnen.
			sta	r11H

			ldy	#5			;Dateiname in Zwischenspeicher
			ldx	#0			;kopieren.
::1			lda	(r0L),y
			cmp	#$a0
			beq	:2
			sta	dataFileName,x
			iny
			inx
			cpx	#16
			bcc	:1
::2			lda	#NULL			;Ende Dateiname markieren.
			sta	dataFileName,x

			LoadW	r6,dataFileName
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			lda	r5L			;Position Verzeichniseintrag
			and	#%11100000		;berechnen.
			sta	r5L

			ldy	#2
::copy			lda	(r5L),y			;Verzeichniseintrag vom Verzeichnis
			sta	(r11L),y		;in Borderblock verschieben.
			lda	#$00
			sta	(r5L),y
			iny
			cpy	#32
			bcc	:copy

			PushB	r1L			;Adresse Verzeichnisblock
			PushB	r1H			;zwischenspeichern.

			MoveB	r13L,r1L		;Zeiger auf Borderblock.
			MoveB	r13H,r1H
			LoadW	r4,fileHeader
			jsr	PutBlock		;Borderblock speichern.

			PopB	r1H			;Position Verzeichnisblock
			PopB	r1L			;zurücksetzen.

			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnisblock aktualisieren.
;			txa				;Diskettenfehler?
;			bne	:exit			; => Ja, Abbruch...

;			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** Fehler: Borderblock voll.
:Dlg_BorderFull		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Borderblock voll! Der Borderblock",NULL
::3			b "kann max. 8 Dateien aufnehmen!",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Border block full! The border block",NULL
::3			b "can hold a maximum of 8 files!",NULL
endif

;*** Endadresse testen:
			g BASE_DIRDATA
;***
