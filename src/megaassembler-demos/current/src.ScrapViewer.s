; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Symboltabellen einbinden.
;
if .p
			t	"TopSym"
			t	"TopMac"
endif

;
; GEOS-Header definieren.
;
			n	"ScrapViewer"
			c	"ScrapViewer V1.0",NULL
			a	"Markus Kanet",NULL

			f	APPLICATION
			z	$80 ;Nur GEOS64.

			o	APP_RAM

			h	"A simple Photoscrap viewer, use Cursor keys and a,b,c,d to select drive."

			i
<MISSING_IMAGE_DATA>

;
; Fensterdaten definieren:
;
; Linke, obere Ecke Dialogbox:
:WINPOS_X		= $05				;Cards
:WINPOS_Y		= $18				;Pixel
;
; Breite/Höhe für Dialogbox:
:WINDOW_X		= $1d				;Cards
:WINDOW_Y		= $70				;Pixel
;
; Offset für Scrap-Anzeige:
:OFFSET_X		= $01				;Cards
:OFFSET_Y		= $08				;Pixel
;
; max. Breite/Höhe für Scrap-Anzeige:
:CLIP_X			= WINDOW_X -OFFSET_X*2
:CLIP_Y			= WINDOW_Y -OFFSET_Y*2
;
; Ladeadresse für Photoscrap:
:SCRAP_BASE		= $1000
:SCRAP_SIZE		= $7000
;
; Startadresse Photoscrap_Daten:
:SCRAP_DATA		= SCRAP_BASE +3

; Größe Photoscrap.
:scrapWidth		= SCRAP_BASE +0
:scrapHeight		= SCRAP_BASE +1

;
; Photoscrap-Viewer
;
:Start			LoadW	r0,dbox			;Zeiger auf Dialogbox-Daten.
			jsr	DoDlgBox		;Dialogbox öffnen.

::exit			jmp	EnterDeskTop		;Zurück zum DeskTop.

;
; Anzeigebereich Photoscrap löschen.
;
:ClearClip		lda	#2
			jsr	SetPattern		;Füllmuster setzen.

; Linke, obere Ecke definieren.
			LoadB	r2L,(WINPOS_Y +OFFSET_Y)
			LoadW	r3 ,(WINPOS_X +OFFSET_X) *8

; Rechte, untere Ecke definieren.
			LoadB	r2H,(WINPOS_Y +OFFSET_Y +CLIP_Y) -1
			LoadW	r4 ,(WINPOS_X +OFFSET_X +CLIP_X) *8 -1

; Anzeigebereich löschen.
			jsr	Rectangle

			rts

;
; Photoscrap einlesen
;
:loadPScrap		LoadW	r6,ScrapName		;Zeiger auf Dateiname.
			jsr	FindFile		;Photoscrap suchen.
			txa				;Diskettenfehler?
			bne	:err			; => Ja, Abbruch...

if FALSE
			jsr	i_FillRam		;Debug-Modus:
			w	$7000			;Speicher löschen.
			w	$1000
			b	$bd
endif

			lda	dirEntryBuf +1		;Zeiger auf ersten Track/Sektor
			sta	r1L			;des Photoscrap einlesen.
			lda	dirEntryBuf +2
			sta	r1H

			LoadW	r7,SCRAP_BASE		;Ladeadresse definieren.
			LoadW	r2,SCRAP_SIZE		;Max. Puffergröße festlegen.
			jsr	ReadFile		;Photoscrap einlesen.
			txa				;Diskettenfehler?
			beq	:done			; => Nein, Ende...

::err			ldx	#$ff			;Flag setzen: "Kein Scrap im Speicher"
::done			stx	Flag_ScrapOK		;Scrap-Status speichern.

			rts

;
; Dialogbox-Menü initialisieren
;
:InitDBoxMenu		lda	#ST_WR_FORE		;Nur in Vordergrund schreiben.
			sta	dispBufferOn

			lda	#< keyDBoxMenu		;Tastaturabfrage installieren.
			sta	keyVector +0
			lda	#> keyDBoxMenu
			sta	keyVector +1

			jsr	ClearClip		;Anzeigebereich löschen.

;
; Anzeige für Photoscrap initialisieren
;
:DrawFirstClip		jsr	loadPScrap		;Photoscrap-Datei laden.

			bit	Flag_ScrapOK		;Photoscrap im Speicher?
			bmi	ScrapError		; => Fehlermeldung ausgeben.

::ok			jmp	InitPhotoScrap

;
; Kein Photoscrap vorhanden
; Fehlermeldung anzeigen
;
:ScrapError		LoadW	r11,(WINPOS_X +OFFSET_X) *8 +16
			LoadB	r1H, WINPOS_Y +OFFSET_Y     +16

			LoadW	r0,Text_NoData
			jsr	PutString

			rts

;
; Photoscrap initialisieren
;
:InitPhotoScrap		lda	#$00			;Offset für Scrap-Anzeige
			sta	clipXPos		;initialisieren.
			sta	clipYPos +0
			sta	clipYPos +1

; Koordinate für Scrap-Ausgabe:
; - x-Koordinate in Cards.
; - y-Koordinate in Pixel.
			LoadB	r1L,WINPOS_X +OFFSET_X
			LoadB	r1H,WINPOS_Y +OFFSET_Y

; Größe für Scrap-Ausgabe:
; - x-Größe in Cards.
; - y-Größe in Pixel.
			LoadB	r2L,CLIP_X
			LoadB	r2H,CLIP_Y

; Offset für Scrap-Ausgabe:
; - x-Offset in Cards.
; - y-Offset in Pixel.
			MoveB	clipXPos,r11L
:DrawCurClip		MoveW	clipYPos,r12

;
; Ausschnitt Photoscrap anzeigen
;
:DrawCurYClip		LoadW	r0,SCRAP_DATA		;Zeiger auf Scrap-Daten.

			lda	scrapWidth
			sec
			sbc	r11L			;Anzahl Cards am Anfang überlesen.
			bcc	:small_x
;			sec
			sbc	r2L
			sta	r11H			;Anzahl Cards am Ende überlesen.
			bcs	:print

;
; Photoscrap ist schmaler als Anzeige
;
::small_x		lda	#0
			sta	r11L			;Keine Cards am Angang überlesen.
			sta	r11H			;Keine Cards am Ende überlesen.

			lda	scrapWidth		;Max. Breite Photoscrap setzen.
			sta	r2L

;
; Aktuellen Ausschnitt anzeigen.
;
::print			jsr	defClipSize		;Höhe Photoscrap testen.
			jmp	BitmapClip		;Ausschnitt anzeigen.

;
; Höhe Photoscrap-Ausschnitt prüfen
;
:defClipSize		lda	scrapHeight +1		;Höhe > 256 Pixel?
			bne	:1			; => Ja, kein Test erforderlich.

			lda	scrapHeight +0		;Höhe > 200 Pixel?
			cmp	r2H
			bcs	:1			; => Ja, weiter...
			sta	r2H			;Max. Höhe festlegen.

::1			lda	scrapWidth		;Breite > 40 Cards?
			cmp	r2L
			bcs	:2			; => Ja, weiter...
			sta	r2L			;Max. Breite festlegen.

::2			rts				;Ende.

;
; Tastaturabfrage
;
:keyDBoxMenu		lda	keyData			;Tastencode einlesen.
			ldx	#0			;Zeiger auf Anfang Tastentabelle.
::1			cmp	tabKeyData,x		;Tastencode gefunden?
			beq	execKey			; => Ja, ausführen.
			inx
			cpx	#MAX_KEYS		;Alle Tasten geprüft?
			bcc	:1			; => Nein, weiter...
::exit			rts				;Zurück zur Mainloop.

;
; Tastenroutine ausführen
;
:execKey		txa
			asl
			tay
			lda	tabKeyAdr +0,y		;Adresse für Tastenroutine
			ldx	tabKeyAdr +1,y		;einlesen und ausführen.
			jmp	CallRoutine

;
; Tastencodes für Menüfunktionen
;
:tabKeyData		b $1e				;right, MoveLeft
			b $08				;left , MoveRight
			b $11				;down , MoveDown
			b $10				;up   , MoveUp
			b $61				;a    , Laufwerk A:
			b $62				;b    , Laufwerk B:
			b $63				;c    , Laufwerk C:
			b $64				;d    , Laufwerk D:
			b $78				;x    , Desktop
			b $0d				;RET  , Desktop

:tabKeyDataEnd
:MAX_KEYS		= tabKeyDataEnd - tabKeyData

;
; Adressen der Menüroutinen.
;
:tabKeyAdr		w MoveLeft
			w MoveRight
			w MoveDown
			w MoveUp
			w OpenDriveA
			w OpenDriveB
			w OpenDriveC
			w OpenDriveD
			w EnterDeskTop
			w EnterDeskTop

;
; Tastenmenü: Laufwerk wechseln
;
:OpenDriveA		ldx	#8			;Laufwerk A:
			b $2c
:OpenDriveB		ldx	#9			;Laufwerk B:
			b $2c
:OpenDriveC		ldx	#10			;Laufwerk C:
			b $2c
:OpenDriveD		ldx	#11			;Laufwerk D:

			lda	driveType -8,x		;Ist Laufwerk verfügbar?
			beq	:exit			; => Nein, Abbruch...

			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			lda	#$ff
			sta	Flag_ScrapOK		;Scrap-Status löschen.
			jsr	ClearClip		;Anzeigebereich löschen.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	DrawFirstClip		;Photoscrap anzeigen.

::exit			rts				;Ende.

;
; Ausschnitt nach links schieben
;
:leftCol0 = SCREEN_BASE +(WINPOS_Y +OFFSET_Y)*40 +(WINPOS_X +OFFSET_X +1) *8
:leftCol1 = leftCol0 -8
:MoveLeft		bit	Flag_ScrapOK		;Photoscrap im Speicher?
			bmi	:exit			; => Nein, Ende...

			lda	clipXPos		;Ausschnitt bereits am
			clc				;rechten Rand?
			adc	#CLIP_X
			bcs	:exit
			cmp	scrapWidth
			bcc	:ok			; => Nein, verschieben...

::exit			rts

;
; Ausschnitt verschieben
;
::ok			inc	clipXPos		;Offset für Anzeige ändern.

			LoadW	r0,leftCol0		;Spalte #1
			LoadW	r1,leftCol1		;Spalte #0

			ldx	#CLIP_X			;Breite des Ausschnitts
			dex				;von Cards nach Pixel wandeln.
			txa				;Achtung: Max. 32 Cards!
			asl
			asl
			asl
			sta	r2L
			lda	#$00
			sta	r2H

			lda	#(CLIP_Y/8)		;Zeilenzähler initialisieren.
::loop			pha
			jsr	MoveData		;Daten verschieben.
			AddVW	40*8,r0			;Zeiger auf nächste Zeile.
			AddVW	40*8,r1			;Zeiger auf nächste Zeile.
			pla
			sec
			sbc	#$01			;Alle Zeilen verschoben?
			bne	:loop			; => Nein, weiter...

; x-Koordinate setzen.
			lda	#WINPOS_X +OFFSET_X -1
			clc
			adc	#CLIP_X
			sta	r1L

; y-Koordinate setzen.
			LoadB	r1H,WINPOS_Y +OFFSET_Y

; Größe des Ausschnitts definieren.
			LoadB	r2L,1			;Breite in Cards.
			LoadB	r2H,CLIP_Y		;Höhe in Pixel.

; x-Offset berechnen.
			lda	clipXPos		;x-Offset in Cards.
			clc
			adc	#CLIP_X
			sta	r11L
			dec	r11L

; Letzte Spalte ausgeben.
			jsr	DrawCurClip		;Daten über BitmapClip ausgeben.

			rts				;Ende.

;
; Ausschnitt nach rechts schieben
;
:rightCol0 = SCREEN_BASE +(WINPOS_Y +OFFSET_Y)*40 +(WINPOS_X +OFFSET_X) *8
:rightCol1 = rightCol0 +8
:MoveRight		bit	Flag_ScrapOK		;Photoscrap im Speicher?
			bmi	:exit			; => Nein, Ende...

			ldx	clipXPos		;Bereits am linken Rand?
			bne	:ok			; => Nein, verschieben...

::exit			rts

;
; Ausschnitt verschieben
;
::ok			dex
			stx	clipXPos		;Offset für Anzeige ändern.

			LoadW	r0,rightCol0		;Spalte #x -1
			LoadW	r1,rightCol1		;Spalte #x

			ldx	#CLIP_X			;Breite des Ausschnitts
			dex				;von Cards nach Pixel wandeln.
			txa				;Achtung: Max. 32 Cards!
			asl
			asl
			asl
			sta	r2L
			lda	#$00
			sta	r2H

			lda	#(CLIP_Y/8)		;Zeilenzähler initialisieren.
::loop			pha
			jsr	MoveData		;Daten verschieben.
			AddVW	40*8,r0			;Zeiger auf nächste Zeile.
			AddVW	40*8,r1			;Zeiger auf nächste Zeile.
			pla
			sec
			sbc	#$01			;Alle Zeilen verschoben?
			bne	:loop			; => Nein, weiter...

; x-/y-Koordinate setzen.
			LoadB	r1L,WINPOS_X +OFFSET_X
			LoadB	r1H,WINPOS_Y +OFFSET_Y

; Größe des Ausschnitts definieren.
			LoadB	r2L,1			;Breite in Cards.
			LoadB	r2H,CLIP_Y		;Höhe in Pixel.

; x-Offset setzen.
			MoveB	clipXPos,r11L		;x-Offset in Cards.

; Erste Spalte ausgeben.
			jsr	DrawCurClip		;Daten über BitmapClip ausgeben.

			rts				;Ende.

;
; Ausschnitt nach unten schieben
;
:downCol0 = SCREEN_BASE +(WINPOS_Y +OFFSET_Y)*40 +(WINPOS_X +OFFSET_X)*8
:downCol1 = downCol0 +40*8
:MoveDown		bit	Flag_ScrapOK		;Photoscrap im Speicher?
			bmi	:exit			; => Nein, Ende...

			lda	clipYPos +0
			clc
			adc	#CLIP_Y
			sta	r1L
			lda	clipYPos +1
			adc	#$00
			sta	r1H

			CmpW	r1,scrapHeight		;Bereits am unteren Rand?
			bcc	:ok			; => Nein, verschieben...

::exit			rts

;
; Ausschnitt verschieben
;
::ok			lda	clipYPos +0		;Offset für Anzeige ändern.
			clc
			adc	#8
			sta	clipYPos +0
			bcc	:1
			inc	clipYPos +1

::1			LoadW	r0,downCol1		;Zeile #y -1
			LoadW	r1,downCol0		;Zeile #y

			LoadW	r2,CLIP_X *8		;Anzahl Bytes in einer Zeile.

			lda	#(CLIP_Y/8) -1		;Zeilenzähler initialisieren.
::loop			pha
			jsr	MoveData		;Daten verschieben.
			AddVW	40*8,r0			;Zeiger auf nächste Zeile.
			AddVW	40*8,r1			;Zeiger auf nächste Zeile.
			pla
			sec
			sbc	#$01			;Alle Zeilen verschoben?
			bne	:loop			; => Nein, weiter...

; x-/y-Koordinate setzen.
			LoadB	r1L,WINPOS_X +OFFSET_X
			LoadB	r1H,WINPOS_Y +OFFSET_Y +CLIP_Y -8

; Größe des Ausschnitts definieren.
			LoadB	r2L,CLIP_X		;Breite in Cards.
			LoadB	r2H,8			;Höhe in Pixel.

; x-Offset setzen.
			MoveB	clipXPos,r11L		;x-Offset in Cards.

; y-Offset setzen.
			lda	clipYPos +0		;y-Offset in Pixel.
			clc
			adc	#< (CLIP_Y -8)
			sta	r12L
			lda	clipYPos +1
			adc	#> (CLIP_Y -8)
			sta	r12H

; Unterste Spalte ausgeben.
			jsr	DrawCurYClip		;Daten über BitmapClip ausgeben.

			rts				;Ende.

;
; Ausschnitt nach oben schieben
;
:upCol = SCREEN_BASE +(WINPOS_Y +OFFSET_Y)*40 +(WINPOS_X +OFFSET_X)*8
:upCol0 = upCol +(CLIP_Y/8 -1)*40*8
:upCol1 = upCol0 -40*8
:MoveUp			bit	Flag_ScrapOK		;Photoscrap im Speicher?
			bmi	:exit			; => Nein, Ende...

			lda	clipYPos +0
			ora	clipYPos +1		;Bereits am oberen Rand?
			bne	:ok			; => Nein, verschieben...

::exit			rts

;
; Ausschnitt verschieben
;
::ok			lda	clipYPos +0		;Offset für Anzeige ändern.
			sec
			sbc	#< $0008
			sta	clipYPos +0
			bcs	:1
			dec	clipYPos +1

::1			LoadW	r0,upCol1		;Zeile #1
			LoadW	r1,upCol0		;Zeile #0

			LoadW	r2,CLIP_X *8		;Anzahl Bytes in einer Zeile.

			lda	#(CLIP_Y/8) -1		;Zeilenzähler initialisieren.
::loop			pha
			jsr	MoveData		;Daten verschieben.
			SubVW	40*8,r0			;Zeiger auf nächste Zeile.
			SubVW	40*8,r1			;Zeiger auf nächste Zeile.
			pla
			sec
			sbc	#$01			;Alle Zeilen verschoben?
			bne	:loop			; => Nein, weiter...

; x-/y-Koordinate setzen.
			LoadB	r1L,WINPOS_X +OFFSET_X
			LoadB	r1H,WINPOS_Y +OFFSET_Y

; Größe des Ausschnitts definieren.
			LoadB	r2L,CLIP_X		;Breite in Cards.
			LoadB	r2H,8			;Höhe in Pixel.

; x-Offset setzen.
			MoveB	clipXPos,r11L		;x-Offset in Cards.

; y-Offset setzen.
			MoveW	clipYPos,r12		;y-Offset in Pixel.

; Oberste Spalte ausgeben.
			jsr	DrawCurYClip		;Daten über BitmapClip ausgeben.

			rts				;Ende.

;
; Variablen
;
:ScrapName		b "Photo Scrap",NULL

:Flag_ScrapOK		b $00   ;$FF = kein Scrap im Speicher.
:Text_NoData		b " * No data * ",NULL

:clipXPos		b $00   ;x-Offset
:clipYPos		w $0000 ;y-offset

;
; Dialogbox für Anzeige Photoscrap.
;
:dbox			b $01
			b WINPOS_Y
			b WINPOS_Y +WINDOW_Y +3*8 -1
			w WINPOS_X *8
			w WINPOS_X *8 +WINDOW_X *8 -1

			b DB_USR_ROUT
			w InitDBoxMenu

			b DBTXTSTR
			b 8
			b WINDOW_Y +3*8 -8
			w :text1

			b DBTXTSTR
			b 8
			b WINDOW_Y +3*8 -12 -8
			w :text2

			b OK
			b WINDOW_X -6 -1
			b WINDOW_Y +3*8 -16 -8

			b NULL

::text1			b "Laufwerk wählen: Tasten A bis D"
			b NULL

::text2			b "Ausschnitt wählen mit Cursor-Tasten"
			b NULL
