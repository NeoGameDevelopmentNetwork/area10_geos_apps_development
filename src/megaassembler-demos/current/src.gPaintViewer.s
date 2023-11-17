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
			t "TopSym"
			t "TopSym.MP3"
			t "TopSym.IO"
			t "TopMac"
endif

;
; GEOS-Header definieren.
;
			n "geoPaintViewer"
			c "PaintViewer V1.0",NULL
			a "Markus Kanet",NULL

			f APPLICATION
			z $80 ;Nur GEOS64.

			o APP_RAM
			p MAININIT

			h "GeoPaint-Viewer für GEOS/MegaPatch64"

			i
<MISSING_IMAGE_DATA>

;
; GeoPaint-Viewer einbinden.
;
			t "inc.ReadGPFile"

;
; Hauptprogramm.
;
:MAININIT		jsr	GetBackScreen		;Hintergrund initialisieren.

::doDlgBox		LoadW	r0,dlgSlctFile
			LoadW	r5,dataFileName		;Ablagebereich Dateiname.
			LoadB	r7L,APPL_DATA		;GEOS-Filetyp: APPL_DATA/Dokument.
			LoadW	r10,PaintClass		;GEOS-Klasse : "Paint Image "
			jsr	DoDlgBox		;Dateiauswahlbox anzeigen.

			lda	sysDBData		;Laufwerk wechseln?
			bpl	:nodrive		; => Nein, weiter...
			and	#%00001111
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...
			beq	:doDlgBox		;Dialogbox erneut anzeigen.

::nodrive		cmp	#CANCEL			;Abbruch gewählt?
			beq	:exit			; => Ja, Ende...

			php				;Interrupt sperren.
			sei

			ldx	CPU_DATA		;I/O-Bereich einblenden.
			lda	#IO_IN
			sta	CPU_DATA

::nokey			lda	#$00			;Warten bis keine Taste gedrückt.
			sta	$dc00
			lda	$dc01
			eor	#$ff
			bne	:nokey

			stx	CPU_DATA		;I/O-Bereich ausblenden.

			plp				;Interrupt-Status zurücksetzen.

			LoadB	a0L,$80			;Farben löschen ($00=Nicht löschen).
			LoadW	a2 ,buffer		;1448-Byte-Zwischenspeicher.
			jsr	ViewPaintFile		;GeoPaint-Datei anzeigen.

			php				;Interrupt sperren.
			sei

			ldx	CPU_DATA		;I/O-Bereich einblenden.
			lda	#IO_IN
			sta	CPU_DATA

::wait			lda	#$00			;Warten auf Tastendruck.
			sta	$dc00
			lda	$dc01
			eor	#$ff
			beq	:wait

			stx	CPU_DATA		;I/O-Bereich ausblenden.

			plp				;Interrupt-Status zurücksetzen.

			jmp	MAININIT		;Nächste Datei anzeigen.

::exit			jmp	EnterDeskTop		;Zurück zum DeskTop.

;
; Dateiauswahlbox.
;
:dlgSlctFile		b $81
			b DBGETFILES ! DBSETDRVICON
			b   $00,$00

			b OPEN
			b   $00,$00
			b CANCEL
			b   $00,$00

			b NULL

;
; GEOS-Klasse GeoPaint-Dokumente.
;
:PaintClass		b "Paint Image ",NULL

;
; Zwischenspeicher für Grafikdaten.
;
:buffer
