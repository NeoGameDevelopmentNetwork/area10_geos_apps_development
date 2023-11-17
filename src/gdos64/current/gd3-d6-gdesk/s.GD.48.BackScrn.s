; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Hintergrundbild wählen.

;*** Symboltabellen.
if .p
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DISK"
			t "SymbTab_APPS"
			t "SymbTab_MMAP"
			t "SymbTab_GRFX"
			t "SymbTab_CHAR"
			t "SymbTab_DBOX"
			t "SymbTab_KEYS"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
endif

;*** GEOS-Header.
			n "obj.GD48"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	SelectBackScrn

;*** GeoPaint-Loader.
			t "-G3_ReadGPFile"

;*** Hintergrundbild wechseln.
:SelectBackScrn		lda	#< AppClassPaint	;GEOS-Klasse für
			sta	r10L			;GeoPaint-Dokumente setzen.
			lda	#> AppClassPaint
			sta	r10H
			LoadB	r7L,APPL_DATA
			jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			beq	:openfile
::exit			jmp	MOD_RESTART		;Menü/FensterManager neu starten.

::openfile		lda	dataFileName		;Datei ausgewählt?
			beq	:exit			; => Nein, Ende...

			LoadW	r6,dataFileName
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			LoadB	a0L,%10000000		;Farb-RAM löschen.
			LoadW	a2,GrfxData		;Zeiger auf Zwischenspeicher.
			jsr	ViewPaintFile		;Hintergrundbild anzeigen.
			txa				;Fehler ?
			bne	NoBackScrn		; => Ja, kein Startbild.

;*** Hintergrundgrafik speichern.
			lda	MP3_64K_SYSTEM		;Zeiger auf MP3-Systembank.
			sta	r3L

			LoadW	r0,SCREEN_BASE
			LoadW	r1,R2A_BS_GRAFX
			LoadW	r2,R2S_BS_GRAFX
			jsr	StashRAM		;Grafik speichern.
			LoadW	r0,COLOR_MATRIX
			LoadW	r1,R2A_BS_COLOR
			LoadW	r2,R2S_BS_COLOR
			jsr	StashRAM		;Farbe speichern.

			lda	#TRUE			;Flag setzen:
			sta	Flag_BackScrn		;Hintergrundbild geladen.

			jsr	GetColProfile

			lda	#TRUE			;Hintergrundbild aktiv.
			b $2c

;*** Kein Startbild, Hintergrund löschen.
:NoBackScrn		lda	#FALSE			;Kein Hintergrundbild aktiv.
			sta	GD_BACKSCRN

			lda	sysRAMFlg
			and	#%11110111
			bit	GD_BACKSCRN		;GeoDesk-Hintergrundbild verwenden?
			bpl	:1			; => Nein, weiter...
			ora	#%00001000		; => Ja, System-Wert ändern.
::1			sta	sysRAMFlg
			sta	sysFlgCopy

			jmp	MOD_REBOOT		;Zurück zum Desktop.

;*** Passendes Farbprofil für Zufallsbild suchen.
:GetColProfile		ldy	#0
::1			lda	dataFileName,y		;Name Grafikdatei übernehmen.
			beq	:2			;(Nur die ersten 12 Zeichen)
			sta	configColName,y
			iny
			cpy	#12
			bcc	:1

::2			ldx	#0
::3			lda	configColExt,x		;Erweiterung ".col" anhängen.
			sta	configColName,y
			iny
			inx
			cpx	#4
			bcc	:3

			lda	#NULL			;Ende-Kennung schreiben.
			sta	configColName,y

			LoadW	r6,configColName	;Zeiger auf Dateiname setzen.
			jsr	FindFile		;Datei suchen.
			txa				;Gefunden ?
			bne	:exit			; => Nein, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			LoadW	r0,fileHeader +77	;Klasse des Farbprofils prüfen.
			LoadW	r1,configColClass
			ldx	#r0L
			ldy	#r1L
			jsr	CmpString
			bne	:exit			; => Kein, Farbprofil, Abbruch...

			LoadB	r0L,%00000001
			LoadW	r6,configColName
			LoadW	r7,GD_PROFILE		;Startadresse Farb-/Musterdaten.
			jsr	GetFile			;Datei einlesen.
			txa				;Fehler?
			bne	:exit			; => Nein, Ende...

			jsr	SUB_SAVECOL		;Farbprofil in DACC speichern.

::exit			rts

;*** Datei auswählen.
;    Übergabe:		r7L  = Datei-Typ.
;			r10  = Datei-Klasse.
;    Rückgabe:		In ":dataFileName" steht der Dateiname.
;			xReg = $00, Datei wurde ausgewählt.
:OpenFile		MoveB	r7L,:OpenFile_Type
			MoveW	r10,:OpenFile_Class

::1			ldx	curDrive
			lda	driveType -8,x		;Aktuelles Laufwerk gültig?
			bne	:3			; => Ja, weiter...

			ldx	#8			;Gültiges Laufwerk suchen.
::2			lda	driveType -8,x
			bne	:3
			inx
			cpx	#12
			bcc	:2
			ldx	#$ff
			rts

::3			txa				;Laufwerk aktivieren.
			jsr	SetDevice

;--- Dateiauswahlbox.
::4			lda	#$00			;Speicher für Dateiname
			sta	dataFileName		;löschen.

			MoveB	:OpenFile_Type ,r7L
			MoveW	:OpenFile_Class,r10
			LoadW	r5 ,dataFileName
			LoadB	r7H,255
			LoadW	r0,:Dlg_SlctFile
			jsr	DoDlgBox		;Datei auswählen.

			lda	sysDBData		;Laufwerk wechseln ?
			bpl	:5			; => Nein, weiter...

			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.
			txa				;Laufwerksfehler ?
			beq	:4			; => Nein, weiter...
			bne	:1			; => Ja, gültiges Laufwerk suchen.

::5			cmp	#DISK			;Partition wechseln ?
			beq	:4			; => Ja, weiter...
			ldx	#$ff
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:6			; => Ja, Abbruch...
			inx
::6			rts

::OpenFile_Type		b $00
::OpenFile_Class	w $0000

::Dlg_SlctFile		b $81
			b DBGETFILES!DBSETDRVICON ,$00,$00
			b CANCEL                  ,$00,$00
			b DISK                    ,$00,$00
			b OK                      ,$00,$00
			b NULL

;*** Variablen.
:SystemDevice		b $00
:AppClassPaint		b "Paint Image ",NULL
:configColClass		b "geoDeskCol  V1.0",NULL
:configColExt		b ".col"
:configColName		s 17
:fileName		s 17

;*** Zwischenspeicher.
:DATABUF

;--- Speicher für Dateiauswahl.
:FNameBuf		= DATABUF

;--- Speicher für GeoPaint-Daten.
;Benötigter Speicher für eine Zeile:
; Grafikdaten: 1280 Bytes (80 Cards x 8 Bytes x 2 Zeilen)
; Reserviert :    8 Bytes
; Farbdaten  :  160 Bytes (80 Cards x 2 Zeilen)
;             ------------
;              1448 Bytes
;
:GrfxData		= FNameBuf   +(256 * 17)

:DATABUFEND		= GrfxData   +(640 * 2) +8 +(80 * 2)
:DATABUFSIZE		= (DATABUFEND - DATABUF)

;*** Endadresse testen:
			g OS_BASE - DATABUFSIZE
;***
