; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Module installieren.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_APPS"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
endif

;*** GEOS-Header.
			n "obj.GD00.Mod"
			c "GeoDesk.Mod V0.1"
			t "opt.Author"
			f APPLICATION
			z $80 ;nur GEOS64

;--- Hinweis:
;Die aktuelle GEOS-Klasse von GeoDesk
;liegt ab BASE_GEODESK +17 im Speicher!
;Startadresse für GeoDesk.mod muss hier
;angepasst werden, sonst überschreibt
;GeoDesk.mod die Klasse => Kein 'LOAD'.
			o BASE_GEODESK +$0100
			p MainInit

			i
<MISSING_IMAGE_DATA>

;*** System initialisieren.
:MainInit		jsr	checkGeoDesk		;Auf GeoDesk im RAM testen.

			lda	#APPLICATION		;GeoDesk über die GEOS-Klasse
			sta	r7L			;suchen.
			lda	#$01
			sta	r7H
			LoadW	r6 ,bootGDeskName
			LoadW	r10,bootGDeskClass
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			lda	r7H			;Modul gefunden ?
			beq	:found			; => Nein, Abbruch...

::error			jmp	error_sys		;Fehlermeldung ausgeben.

::found			LoadW	r6,bootGDeskName
			jsr	FindFile		;Verzeichniseintrag suchen.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

;			lda	#$00
			sta	changes			;Anzahl Änderungen zurücksetzen.

			MoveB	r1L,a2L			;Verzeichnissektor speichern.
			MoveB	r1H,a2H

			MoveW	r5 ,a3			;Verzeichnisposition speichern.

			lda	dirEntryBuf +1		;Zeiger auf VLIR-Sektor speichern.
			sta	a4L
			lda	dirEntryBuf +2
			sta	a4H

			LoadW	r6,modFileName
			jsr	FindFile		;GEODESNK.mod suchen.
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			MoveB	r1L,a5L			;Verzeichnissektor speichern.
			MoveB	r1H,a5H

			MoveW	r5 ,a6			;Verzeichnisposition speichern.

			lda	dirEntryBuf +1		;Zeiger auf VLIR-Sektor speichern.
			sta	a7L
			lda	dirEntryBuf +2
			sta	a7H

;*** Auswahlmenü anzeigen.
:OpenModMenu		MoveB	a4L,r1L
			MoveB	a4H,r1H
			LoadW	r4,fileHeader
			jsr	GetBlock

			LoadW	r0,modNameTab

			ldx	#0
;--- Installierte Module markieren.
::1			lda	modGD,x			;GeoDesk-Modul-Nr. einlesen.
			clc				;+1 für Boot-Loader.
			adc	#$01
			asl
			tay
			lda	fileHeader +2,y		;Modul installiert?
			beq	:2			; => Nein, weiter...
			lda	#"*"			;Modul ist installiert.
			b $2c
::2			lda	#" "			;Modul nicht instaliert.

			ldy	#0
			sta	(r0L),y			;Modul-Status speichern.

;--- Geladene Module markieren.
			bit	gDeskActive		;Von GeoDesk aus gestartet?
			bpl	:3			; => Nein, weiter...

			ldy	modGD,x			;GeoDesk-Modul-Nr. einlesen.
			lda	GD_DACC_ADDR_B,y	;Modul aktuell geladen?
			beq	:3			; => Nein, weiter...
			lda	#"="			;Modul geladen.
			b $2c
::3			lda	#" "			;Modul nicht geladen/Keine Info.

			ldy	#1
			sta	(r0L),y			;Modul-Status speichern.

			AddVBW	17,r0			;Zeiger auf nächstes Modul.

			inx
			cpx	#MAX_MODULES		;Alle Module getestet?
			bcc	:1			; => Nein, weiter...

			lda	#NULL			;Modul-Auswahl löschen.
			sta	dataFileName

			LoadW	r5,dataFileName
			LoadW	r0,Dlg_SlctFile
			jsr	DoDlgBox		;Modul auswählen.

			lda	sysDBData
			cmp	#OK			;OK gewählt ?
			beq	:done			; => Ja, Ende...

			cmp	#$82			;Alle installieren?
			beq	:all			; => Ja, weiter...
			cmp	#$83			;Alle entfernen?
			beq	:none			; => Ja, weiter...
			cmp	#$85			;GeoDesk neu starten?
			beq	:restart		; => Ja, weiter...
			cmp	#$86			;Info anzeigen?
			beq	:info			; => Ja, weiter...

;--- Modul installieren.
			ldx	dataFileName		;Eintrag ausgewählt?
			beq	:done			; => Nein, Ende...

			ldx	DB_GetFileEntry		;Ausgewähltes Modul
			stx	modSlct			;zwischenspeichern.

			cmp	#$84			;Modul temporär laden?
			beq	:loadmod		; => Ja, weiter...

			jsr	prepareInstall		;Modul in Systemdatei installieren.
			txa				;Fehler?
			bne	error_sys		; => Ja, Abbruch...

			jmp	OpenModMenu		;Modul-Menü erneut anzeigen.

;--- Alle Module installieren.
::all			jsr	installAll		;Alle Module installieren.
			txa				;Fehler?
			bne	error_sys		; => Ja, Abbruch...

			jmp	OpenModMenu		;Modul-Menü erneut anzeigen.

;--- Alle Module entfernen.
::none			jsr	installNone		;Alle Module entfernen.
			txa				;Fehler?
			bne	error_sys		; => Ja, Abbruch...

			jmp	OpenModMenu		;Modul-Menü erneut anzeigen.

;--- Modul laden.
::loadmod		jsr	loadModule		;Modul in RAM laden.
			txa				;Fehler?
			beq	:l1			; => Nein, weiter...

			cpx	#$ff			;Fehler: "Bereits geladen"?
			bne	error_sys		; => Nein, Abbruch...

::l1			jmp	OpenModMenu		;Modul-Menü erneut anzeigen.

;--- Infobox anzeigen.
::info			LoadW	r0,Dlg_InfoBox
			jsr	DoDlgBox		;Infobox anzeigen.

			jmp	OpenModMenu		;Modul-Menü erneut anzeigen.

;--- Installation beenden.
::done			lda	changes			;Veränderungen durchgeführt?
			beq	:exit			; => Nein, Ende...

			LoadW	r0,Dlg_Restart
			jsr	DoDlgBox		;Statusmeldung ausgeben.

			lda	sysDBData		;Rückmeldung einlesen.
			cmp	#YES			;GeoDesk starten?
			bne	:exit			; => Nein, weiter...

::restart		LoadW	r6,bootGDeskName
			LoadB	r0L,%00000000
			jsr	GetFile			;GeoDesk laden/starten.

::exit			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** GeoDesk/GeoDesk.mod nicht gefunden.
:error_sys		LoadW	r0,Dlg_GDOS_Error
			jsr	DoDlgBox		;Statusmeldung ausgeben.

			jmp	EnterDeskTop		;Zurück zum DeskTop.

;*** Icon-Routinen für Module installieren/entfernen.
:DB_Module		lda	#$81			;Modul installieren/entfernen.
			b $2c
:DB_AllMod		lda	#$82			;Alle Module installieren.
			b $2c
:DB_NoMod		lda	#$83			;Alle Module entfernen.
			b $2c
:DB_LoadMod		lda	#$84			;Modul temporär laden.
			b $2c
:DB_Reset		lda	#$85			;GeoDesk neu starten.
			b $2c
:DB_Info		lda	#$86			;Infobox anzeigen.
			sta	sysDBData

			jmp	RstrFrmDialogue		;Modul-Auswahl beenden.

;*** Alle Module installieren.
:installAll		lda	#$00
			b $2c
:installNone		lda	#$ff
			sta	installMode		;Installationsmodus festlegen.

			LoadW	r0,bootGDeskName	;VLIR-Header einlesen.
			jsr	OpenRecordFile
			txa				;Diskettenfehler ?
			bne	:exit

			jsr	CloseRecordFile		;VLIR-Datei schließen.
;			txa				;Diskettenfehler ?
;			bne	:exit			; => Ja, Abbruch...

			jsr	i_MoveData		;VLIR-Header in Zwischenspeicher
			w	fileHeader		;kopieren, da ":fileHeader" während
			w	fileHdrBuf		;der Installation verändert wird.
			w	$0100

			lda	#$00
::1			pha
			sta	modSlct			;Modulnummer speichern.
			tax
			lda	modGD,x			;Zeiger auf GeoDesk-Datensatz.
			clc				;+1 für Boot-Loader.
			adc	#$01
			asl
			tay

			ldx	#NO_ERROR		;Flag: "Kein Fehler".
			lda	installMode		;Installieren oder entfernen?
			bne	:remove			; => Modul entfernen, weiter...

::install		lda	fileHdrBuf +2,y		;Track=$00: Nicht installiert.
			bne	:next			; => Installiert, weiter...
			beq	:exec			; => Nicht installiert...

::remove		lda	fileHdrBuf +2,y		;Track=$00: Nicht installiert.
			beq	:next			; => Nicht installiert, weiter...
;			bne	:exec			; => installiert...

::exec			jsr	prepareInstall		;Modul bearbeiten.

::next			pla

			cpx	#NO_ERROR		;Fehler?
			bne	:exit			; => Ja, Abbruch...

			clc
			adc	#$01			;Zeiger auf nächstes Modul.
			cmp	#MAX_MODULES		;Alle Module bearbeitet?
			bcc	:1			; => Nein, weiter...

			ldx	#NO_ERROR		;Kein Fehler, Ende...
::exit			rts

;*** Installation vorbereiten.
:prepareInstall		LoadW	r0,bootGDeskName	;VLIR-Header einlesen.
			jsr	OpenRecordFile
			txa				;Diskettenfehler ?
			bne	:error

::1			ldx	modSlct
			lda	modGD,x			;Zeiger auf GeoDesk-Datensatz.
			clc				;+1 für Boot-Loader.
			adc	#$01
			asl
			tax
			lda	fileHeader +2,x		;Track=$00: Nicht installiert.
			sta	installMode

			jsr	CloseRecordFile
			txa				;Diskettenfehler ?
			bne	:error			; => Ja, Abbruch...

			lda	#$ff			;Moduländerungen setzen.
			sta	changes

			lda	installMode		;Laden/Entfernen?
			bne	:remove			; => Entfernen, weiter...

::install		jsr	ModInstall		;Modul installieren.

			ldx	#NO_ERROR
			rts

::remove		jsr	ModRemove		;Modul entfernen.

			ldx	#NO_ERROR
::error			rts				; => Ja, Abbruch...

;*** Modul temporär laden.
:loadModule		ldx	modSlct			;Ausgewähltes Modul.
			ldy	modGD,x			;VLIR-Datensatz für Modul.
			lda	GD_DACC_ADDR_B,y	;Modul aktuell installiert?
			beq	:load			; => Nein, weiter...

			ldx	#$ff			;Fehler: "Bereits installiert".
::exit			rts

::load			jsr	getGDeskInfo		;GeoDesk-Speicherbelegung einlesen.

			MoveB	a7L,r1L
			MoveB	a7H,r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header GEODESK.mod einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	modSlct			;Ausgewähltes Modul.
			clc				;+1 für Menü-Rotuine.
			adc	#$01
			asl
			tax
			lda	fileHeader +2,x		;Track/Sektor für Modul einlesen.
			sta	r1L
			lda	fileHeader +3,x
			sta	r1H
			LoadW	r7,VLIR_BASE
			LoadW	r2,(OS_BASE - VLIR_BASE)
			jsr	ReadFile		;Modul in Speicher einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	r7L			;Modulgröße berechnen.
			sec
			sbc	#< VLIR_BASE
			sta	r2L
			lda	r7H
			sbc	#> VLIR_BASE
			sta	r2H

			lda	#< VLIR_BASE		;Startadresse Modul im Speicher.
			sta	r0L
			lda	#> VLIR_BASE
			sta	r0H

;--- Modul in Bank#1 installieren.
			lda	gDeskBank1		;Speicherbank#1.
			sta	r3L

			lda	gDeskB1addr +0		;Endadresse in Speicherbank#1.
			sta	r1L
			lda	gDeskB1addr +1
			sta	r1H

			lda	r1L			;Kann Modul in Speicherbank#1
			clc				;installiert werden?
			adc	r2L
			lda	r1H
			adc	a2H
			bcc	:ok			; => Ja, weiter...

			lda	gDeskBank2		;Speicherbank#1.
			sta	r3L

			lda	gDeskB2addr +0		;Endadresse in Speicherbank#2.
			sta	r1L
			lda	gDeskB2addr +1
			sta	r1H

::ok			jsr	StashRAM		;Modul in DACC speichern.

			ldx	modSlct			;Ausgewähltes Modul.
			lda	modGD,x			;VLIR-Modul für GeoDesk einlesen.
			tay
			asl
			asl
			tax

			lda	r3L			;Modul-Informationen im
			sta	GD_DACC_ADDR_B,y	;Speicher aktualisieren.
			lda	r1L
			sta	GD_DACC_ADDR +0,x
			lda	r1H
			sta	GD_DACC_ADDR +1,x
			lda	r2L
			sta	GD_DACC_ADDR +2,x
			lda	r2H
			sta	GD_DACC_ADDR +3,x

			LoadW	r0,GDA_SYSTEM		;Modul-Informationen in GeoDesk
			LoadW	r1,DACC_GEODESK		;aktualisieren.
			LoadW	r2,GDS_SYSTEM
			lda	gDeskBank1
			sta	r3L

			jsr	StashRAM

			ldx	#NO_ERROR		;Kein Fehler, Ende...
			rts

;*** Modul installieren.
:ModInstall		ldx	modSlct			;Ausgewähltes Modul.

			txa				;Zeiger auf Modul-Datensatz.
			clc				;+1 für Menü-Rotuine.
			adc	#$01
			asl
			sta	a0L

			lda	modGD,x			;Zeiger auf GeoDesk-Datensatz.
			clc				;+1 für Boot-Loader.
			adc	#$01
			asl
			sta	a0H

			jsr	:swap_data		;Modul-Informationen korrigieren.

			jsr	SwapVlirSet		;Datensatz verschieben.

::swap_data		ldx	#0			;Modul- und GeoDesk-Daten für
::1			lda	a5L,x			;Swap-Routine tauschen
			pha
			lda	a2L,x
			sta	a5L,x
			pla
			sta	a2L,x
			inx
			cpx	#6
			bcc	:1
			rts

;*** Modul de-installieren.
:ModRemove		ldx	modSlct			;Ausgewähltes Modul.

			txa				;Zeiger auf Modul-Datensatz.
			clc				;+1 für Menü-Rotuine.
			adc	#$01
			asl
			sta	a0H

			lda	modGD,x			;Zeiger auf GeoDesk-Datensatz.
			clc				;+1 für Boot-Loader.
			adc	#$01
			asl
			sta	a0L

;			jmp	SwapVlirSet		;Datensatz verschieben.

;*** VLIR-Datensatz tauschen.
;Das Modul wird dabei nicht kopiert,
;sondern nur die Link-Bytes zwischen
;GEODESK und GEODESK.mod ausgeauscht.
:SwapVlirSet		MoveB	a4L,r1L			;Zeiger auf VLIR-Header #1 setzen.
			MoveB	a4H,r1H

			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header #1 einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;--- Datensatzlänge ermitteln.
;			lda	#$00			;Datensatzgröße zurücksetzen.
			sta	installSize

			ldx	a0L			;Adresse Datensatz einlesen.
			lda	fileHeader +2,x
			sta	modVlirTr
			sta	r1L
			lda	fileHeader +3,x
			sta	modVlirSe
			sta	r1H

			LoadW	r4,diskBlkBuf

::loop			jsr	GetBlock		;Block aus Datensatz einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			inc	installSize		;Anzahl Blocks +1.

			lda	diskBlkBuf +0		;Ende Datensatz erreicht?
			beq	:write			; => Ja, weiter...

			sta	r1L			;Zeiger auf nächsten Block.
			lda	diskBlkBuf +1
			sta	r1H
			jmp	:loop			;Weiter mit nächstem Block.
::err			jmp	EnterDeskTop		;Zurück zum DeskTop.

;--- Datensatz freigeben.
::write			ldx	a0L			;Datensatz in VLIR-Header #1
			lda	#$00			;als "Reserviert" markieren.
			sta	fileHeader +2,x
			lda	#$ff
			sta	fileHeader +3,x

			MoveB	a4L,r1L			;Zeiger auf VLIR-Header #1 setzen.
			MoveB	a4H,r1H

			LoadW	r4,fileHeader
			jsr	PutBlock		;VLIR-Header #1 speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;--- Dateigröße korrigieren.
			MoveB	a2L,r1L			;Zeiger auf Dateieintrag #1.
			MoveB	a2H,r1H

			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

			MoveW	a3,r5			;Zeiger auf Verzeichnis-Eintrag #1.

			ldy	#28			;Dateigröße #1 korrigieren.
			lda	(r5L),y
			sec
			sbc	installSize
			sta	(r5L),y
			iny
			lda	(r5L),y
			sbc	#$00
			sta	(r5L),y

;			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnis-Sektor #1 speichern.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;--- Datensatz ergänzen.
			MoveB	a7L,r1L			;Zeiger auf VLIR-Header #2 setzen.
			MoveB	a7H,r1H

			LoadW	r4,fileHeader
			jsr	GetBlock		;VLIR-Header #2 einlesen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

			ldx	a0H			;Datensatz in VLIR-Header #2
			lda	modVlirTr		;übertragen.
			sta	fileHeader +2,x
			lda	modVlirSe
			sta	fileHeader +3,x

;			LoadW	r4,fileHeader
			jsr	PutBlock		;VLIR-Header #2 speichern.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

;--- Dateigröße korrigieren.
			MoveB	a5L,r1L			;Zeiger auf Dateieintrag #2.
			MoveB	a5H,r1H

			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Verzeichnis-Sektor #2 einlesen.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

			MoveW	a6,r5			;Zeiger auf Verzeichnis-Eintrag #2.

			ldy	#28			;Dateigröße #2 korrigieren.
			lda	(r5L),y
			clc
			adc	installSize
			sta	(r5L),y
			iny
			lda	(r5L),y
			adc	#$00
			sta	(r5L),y

;			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Verzeichnis-Sektor #2 speichern.
;			txa				;Fehler?
;			bne	:err			; => Ja, Abbruch...

			rts

;*** Auf GeoDesk im RAM testen.
:checkGeoDesk		ldx	#$00
			ldy	#19 -1
::1			lda	bootGDeskClass,y	;GeoDesk-Klasse im RAM suchen.
			cmp	GD_SYS_CLASS,y
			bne	:2			; => Nicht gefunden, Abbruch...
			dey				;Alle Zeichen getestet?
			bpl	:1			; => Nein, weiter...
			dex				;Flag setzen: GeoDesk im RAM.
::2			stx	gDeskActive

			txa				;Aus GeoDesk gestartet?
			beq	:end			; => Nein, keine Zusatz-Funktionen.

			ldx	#DBUSRICON		;Zusatz-Funktionen freischalten.
::end			stx	dlgNoInstall
			rts

;*** GeoDesk-Daten einlesen.
:getGDeskInfo		lda	#$00
			sta	r0L			;Zeiger auf r1L/r2L.
			sta	r0H			;VLIR-Modul.

			sta	r1L			;Endadresse Bank#1.
			sta	r1H
			sta	r2L			;Endadresse Bank#2.
			sta	r2H

			sta	r3L			;Bank-Pointer.

::init			ldx	r3L
			lda	GD_RAM_GDESK1,x		;Aktuelle Speicherbank einlesen.
			sta	r3H

			ldx	r0H
::loop			lda	GD_DACC_ADDR_B,x	;Modul installiert?
			beq	:next			; => Nein, weiter...
			cmp	r3H			;In aktueller Bank installiert?
			beq	:test			; => Ja, weiter...

			inc	r3L			;Zeiger auf nächste Speicherbank.
			ldx	r3L
			cpx	#2			;Alle Bänke überprüft?
			beq	:end			; => Ja, Ende...

			inc	r0L			;Bank-Pointer korrigieren.
			inc	r0L
			bne	:init			;Modul erneut testen.

::test			txa				;Startadresse Modul einlesen.
			asl
			asl
			tay
			ldx	r0L			;Größere Startadresse gefunden?
			lda	GD_DACC_ADDR +1,y
			cmp	r1H,x
			bne	:cmp
			lda	GD_DACC_ADDR +0,y
			cmp	r1L,x
::cmp			bcc	:next			; => Nein, weiter...

			lda	GD_DACC_ADDR +2,y	;Neue Größe letztes Modul.
			sta	r4L,x
			lda	GD_DACC_ADDR +3,y
			sta	r4H,x
			lda	GD_DACC_ADDR +0,y	;Neue Adresse letztes Modul.
			sta	r1L,x
			lda	GD_DACC_ADDR +1,y
			sta	r1H,x

::next			inc	r0H			;Zeiger auf nächstes Modul
			ldx	r0H
			cpx	#GD_VLIR_COUNT		;Alle Module getestet?
			bcc	:loop			; => Nein, weiter...

::end			lda	r1L			;Ladeadresse für neues Modul in
			clc				;Speicherbank#1 berechnen.
			adc	r4L
			sta	gDeskB1addr +0
			lda	r1H
			adc	r4H
			sta	gDeskB1addr +1
			lda	GD_RAM_GDESK1
			sta	gDeskBank1

			lda	r2L			;Ladeadresse für neues Modul in
			clc				;Speicherbank#2 berechnen.
			adc	r5L
			sta	gDeskB2addr +0
			lda	r2H
			adc	r5H
			sta	gDeskB2addr +1
			lda	GD_RAM_GDESK2
			sta	gDeskBank2

			rts

;*** Titelzeile in Dialogbox löschen.
:drawDBoxTitle		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$20,$2f
			w	$0040,$00ff
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** Variablen.
:gDeskActive		b $00				;$FF = GeoDesk Aktiv.

:gDeskBank1		b $00				;Angaben zu GeoDesk-Speicherbank.
:gDeskBank2		b $00
:gDeskB1addr		w $0000
:gDeskB2addr		w $0000

:changes		b $00				;$FF = Module wurden verändert.
:installMode		b $00				; >0 = Modul entfernen.
:installSize		b $00				;Größe für Modul.

;*** GEOS-Klasse für GeoDesk.
:bootGDeskClass		t "opt.GDesk.Build"
			e bootGDeskClass +21
:bootGDeskName		s 17

;*** Dateiname für Modul.
:modFileName		b "GEODESK.mod"
			e modFileName +17

:modVlirTr		b $00
:modVlirSe		b $00

:modSlct		b $00				;Ausgewähltes Modul.

;*** Auswahlbox für Module.
:Dlg_SlctFile		b %10000001
			b DBUSRFILES
			w modNameTab
			b OK         ,$00,$00
			b DBUSRICON  ,$00,$00
			w Data_NoMod
			b DBUSRICON  ,$00,$00
			w Data_AllMod
			b DBUSRICON  ,$00,$00
			w Data_Module
			b DBUSRICON  ,$00,$00
			w Data_Info
:dlgNoInstall		b DBUSRICON  ,$00,$00
			w Data_Load
			b DBUSRICON  ,$00,$00
			w Data_Reset
			b NULL

;*** Moduldaten.
:MAX_MODULES		= 9

;*** Modul-Namen.
:modNameTab
if LANG = LANG_DE
:t01			b "  Hilfeseite"
endif
if LANG = LANG_EN
:t01			b "  Help page"
endif
			e t01 +17

if LANG = LANG_DE
:t02			b "  Dateien ordnen"
endif
if LANG = LANG_EN
:t02			b "  Organize files"
endif
			e t02 +17

:t03			b "  Convert"
			e t03 +17

if LANG = LANG_DE
:t04			b "  Diashow /GP"
endif
if LANG = LANG_EN
:t04			b "  Slide show /GP"
endif
			e t04 +17

if LANG = LANG_DE
:t05			b "  Senden an..."
endif
if LANG = LANG_EN
:t05			b "  Send to..."
endif
			e t05 +17

if LANG = LANG_DE
:t06			b "  Disk-Werkzeuge"
endif
if LANG = LANG_EN
:t06			b "  Disk utilities"
endif
			e t06 +17

if LANG = LANG_DE
:t07			b "  CMD-Werkzeuge"
endif
if LANG = LANG_EN
:t07			b "  CMD utilities"
endif
			e t07 +17

if LANG = LANG_DE
:t08			b "  Icon-Manager"
endif
if LANG = LANG_EN
:t08			b "  Icon manager"
endif
			e t08 +17

if LANG = LANG_DE
:t09			b "  SD-Werkzeuge"
endif
if LANG = LANG_EN
:t09			b "  SD utilities"
endif
			e t09 +17

			b NULL

:modNameTab_end

;--- Überprüfung Modulnamen.
:modCheck1		= ((modNameTab_end - modNameTab) -1) /17
if modCheck1 = MAX_MODULES
::true
else
::error			Anzahl Modulnamen passt nicht zu ":modNameTab"!
endif

;*** Modul-Nummern.
:modGD			b GMOD_INFO
			b GMOD_DIRSORT
			b GMOD_FILECVT
			b GMOD_GPSHOW
			b GMOD_SENDTO
			b GMOD_CBMDISK
			b GMOD_CMDPART
			b GMOD_ICONMAN
			b GMOD_SD2IEC
:modGD_end

;--- Überprüfung Modulnummern.
:modCheck2		= (modGD_end - modGD)
if modCheck2 = MAX_MODULES
::true
else
::error			Anzahl Module passt nicht zu ":modGD"!
endif

;*** GeoDesk neu starten.
:Dlg_Restart		b %10000001

			b DB_USR_ROUT
			w drawDBoxTitle

			b DBTXTSTR   ,$08,$0b
			w dlgStatTxInfo
			b DBTXTSTR   ,$0c,$20
			w dlgStatTxMod
			b DBTXTSTR   ,$0c,$2e
			w dlgStatTxLoad

			b YES        ,$01,$48
			b NO         ,$11,$48

			b NULL

:dlgStatTxInfo		b PLAINTEXT, BOLDON
			b "INFORMATION:",NULL

if LANG = LANG_DE
:dlgStatTxMod		b PLAINTEXT
			b "Module wurden installiert/entfernt.",NULL
:dlgStatTxLoad		b PLAINTEXT,BOLDON
			b "GeoDesk jetzt neu starten?",NULL
endif
if LANG = LANG_EN
:dlgStatTxMod		b PLAINTEXT
			b "Modules have been installed/removed.",NULL
:dlgStatTxLoad		b PLAINTEXT,BOLDON
			b "Restart GeoDesk now?",NULL
endif

;*** Dialogboxen.
:Dlg_GDOS_Error		b %10000001

			b DB_USR_ROUT
			w drawDBoxTitle

			b DBTXTSTR   ,$08,$0b
			w :1
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2a
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4

			b OK         ,$11,$48
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT,BOLDON
			b "FEHLER!",NULL
::2			b "GeoDesk konnte das Modul",NULL
::3			b "nicht laden oder entfernen!",NULL
::4			b "Programm wird beendet.",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT,BOLDON
			b "ERROR!",NULL
::2			b "GeoDesk could not load or",NULL
::3			b "remove the module!",NULL
::4			b "Exiting now.",NULL
endif

;*** Infobox.
:dbInfoLine0  = $10
:dbInfoLine1  = $18
:dbInfoLine2  = $30
:dbInfoLine3  = $48
:dbInfoLine4  = $60
:dbInfoLine5  = $78
:dbInfoLine9  = $88
:dbInfoTop    = $10
:dbInfoHeight = $9f
:dbInfoLeft   = $0010
:dbInfoWidth  = $0117
:dbInfoTab0   = $10
:dbInfoTab1   = $01
:dbInfoTab2   = dbInfoLeft +$08 +$30 +$04
:dbInfoTab3   = $1b

:Dlg_InfoBox		b %00000001
			b dbInfoTop ,dbInfoTop  +dbInfoHeight
			w dbInfoLeft,dbInfoLeft +dbInfoWidth

			b OK         ,dbInfoTab3 ,dbInfoLine9

			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine1
			w Data_Load
			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine2
			w Data_Reset
			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine3
			w Data_Module
			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine4
			w Data_AllMod
			b DBUSRICON  ,dbInfoTab1 ,dbInfoLine5
			w Data_NoMod

			b DBTXTSTR   ,dbInfoTab0 ,dbInfoLine0
			w :text
			b NULL

if LANG = LANG_DE
::text			b PLAINTEXT,BOLDON
			b "GEODESK-Module verwalten"
			b PLAINTEXT

			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine1 -4 +10
			b "Ausgewähltes Modul temporär laden"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine1 -4 +10 +10
			b "= Modul ist derzeit in GeoDesk geladen"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine2 -4 +10
			b "GeoDesk neu starten"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine2 -4 +10 +10
			b "Temporäre Module werden dabei entfernt"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine3 -4 +10
			b "Ausgewähltes Modul instalieren/entfernen"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine3 -4 +10 +10
			b "* Modul wird beim Systemstart geladen"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine4 +10
			b "Alle Module in GeoDesk-Systemdatei instalieren"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine5 +10
			b "Alle Module aus GeoDesk-Systemdatei entfernen"

			b NULL
endif
if LANG = LANG_EN
::text			b PLAINTEXT,BOLDON
			b "Manage GEODESK modules"
			b PLAINTEXT

			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine1 -4 +10
			b "Temporary load the selected module"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine1 -4 +10 +10
			b "= Module is currently loaded in GeoDesk"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine2 -4 +10
			b "Restart GeoDesk"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine2 -4 +10 +10
			b "Temporary loaded modules will be removed"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine3 -4 +10
			b "Install/remove the selected module"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine3 -4 +10 +10
			b "* Module will be loaded on system boot"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine4 +10
			b "Install all modules in GeoDesk system file"
			b GOTOXY
			w dbInfoTab2
			b dbInfoTop +dbInfoLine5 +10
			b "Remove all modules from GeoDesk system file"

			b NULL
endif

;*** Dialogbox-Icons.
:Icon_Module
<MISSING_IMAGE_DATA>

:Icon_Module_x = .x
:Icon_Module_y = .y

:Data_Module		w Icon_Module
			b $00,$00
			b Icon_Module_x,Icon_Module_y
			w DB_Module

:Icon_AllMod
<MISSING_IMAGE_DATA>

:Icon_AllMod_x = .x
:Icon_AllMod_y = .y

:Data_AllMod		w Icon_AllMod
			b $00,$00
			b Icon_AllMod_x,Icon_AllMod_y
			w DB_AllMod

:Icon_NoMod
<MISSING_IMAGE_DATA>

:Icon_NoMod_x = .x
:Icon_NoMod_y = .y

:Data_NoMod		w Icon_NoMod
			b $00,$00
			b Icon_NoMod_x,Icon_NoMod_y
			w DB_NoMod

:Icon_Load
<MISSING_IMAGE_DATA>

:Icon_Load_x = .x
:Icon_Load_y = .y

:Data_Load		w Icon_Load
			b $00,$00
			b Icon_Load_x,Icon_Load_y
			w DB_LoadMod

:Icon_Reset
<MISSING_IMAGE_DATA>

:Icon_Reset_x = .x
:Icon_Reset_y = .y

:Data_Reset		w Icon_Reset
			b $00,$00
			b Icon_Reset_x,Icon_Reset_y
			w DB_Reset

:Icon_Info
<MISSING_IMAGE_DATA>

:Icon_Info_x = .x
:Icon_Info_y = .y

:Data_Info		w Icon_Info
			b $00,$00
			b Icon_Info_x,Icon_Info_y
			w DB_Info

;*** Zwischenspeicher VLIR-Header.
:fileHdrBuf
