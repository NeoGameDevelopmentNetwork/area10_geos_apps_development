; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** "MyComputer" öffnen.
:OpenMyComputer		lda	WM_MYCOMP		;Ist "MyComputer" bereits geöffnet?
			beq	:1			; => Nein, weiter...
			jsr	WM_WIN2TOP		;Fenster "MyComputer" an erster
			jmp	WM_DRAW_ALL_WIN		;Stelle anordnen.

::1			jsr	WM_IS_WIN_FREE		;Freies Fenster suchen.
			cpx	#NO_ERROR		;Ist noch ein Fenster frei?
			bne	exitMyComp		; => Ende, kein Fenster mehr frei.

			sta	WM_MYCOMP		;Fenster-Nr. für "MyComputer"
							;speichern.

			jsr	WM_CLR_WINDRVDAT	;Keine Laufwerksdaten speichern.

			LoadW	r0,WIN_MYCOMP
			LoadB	r1L,$00			;Fenster-Optionen löschen.
			jmp	WM_OPEN_WINDOW

;*** "MyComputer" aktualisieren.
:UpdateMyComputer	lda	WM_MYCOMP		;Ist "MyComputer" bereits geöffnet?
			beq	exitMyComp		; => Nein, weiter...
			jsr	WM_WIN2TOP		;"MyComputer" nach oben und
			jmp	WM_UPDATE		;Fensterinhalt aktualisieren.

;*** "MyComputer" schliesen.
;    (Aufruf über FensterManager).
:CloseMyComputer	lda	#$00
			sta	WM_MYCOMP
:exitMyComp		rts

;*** Icons für "MyComputer" anzeigen.
;    Aufruf aus Fenster-Manager.
;    Übergabe: r0 = Aktueller Eintrag.
;              r1L/r1H = XPos/YPos.
;              r2L/r2H = MaxX/MaxY.
;              r3L/r3H = GridX/GridY
:DrawMyComputer		jsr	WM_TEST_ENTRY_X		;Platz für weiteres Icon?
			bcc	:1			; => Ja, weiter...

			ldx	#$00			; => Kein Icon ausgegeben.
			rts

::1			AddVBW	3,r1L			;Für Icon-Anzeige XPos +3 Cards.

			ldx	r0L			;Aktueller Eintrag.
			cpx	#$04			;Laufwerk (Eintrag 0-3)?
			bcs	:5			; => Nein, weiter...

			lda	driveType,x		;Laufwerk installiert?
			beq	:5			; => Nein, weiter...

			ldx	#$00
::2			lda	r0L,x			;ZeroPage r0-r4 sichern.
			pha
			inx
			cpx	#(r4H - r0L) +1
			bcc	:2

			lda	r0L			;Laufwerk für aktuellen
			clc				;Eintrag aktivieren.
			adc	#$08
			jsr	Sys_SetDrv_Open		;Laufwerk wechseln und
							;Diskette öffnen.

;--- Hinweis:
;":SetDevice" und ":OpenDisk" durch
;die neue Routine ":Sys_SetDrv_Open"
;ersetzet.
;			jsr	SetDevice		;Laufwerk öffnen.

;--- Hinweis:
;":OpenDisk" durch ":QuickOpenDisk"
;ersetzt, da der test auf eine GEOS-
;Diskete nicht erforderlich ist.
;			jsr	OpenDisk		;Diskette öffnen.
;			jsr	QuickOpenDisk		;Diskette öffnen.

;--- Hinweis:
;Nicht zum Hauptverzeichnis wechseln.
;Wechselt man z.B. mit geoDirSelect
;das Verzeichnis dann würde hier immer
;wieder zu ROOT gewechselt werden.
;			ldx	curDrive
;			lda	RealDrvMode -8,x
;			and	#SET_MODE_SUBDIR
;			beq	:3
;			jsr	OpenRootDir

::3			ldx	#(r4H - r0L)		;ZeroPage r0-r4 zurücksetzen.
::4			pla
			sta	r0L,x
			dex
			bpl	:4

::5			lda	r0H			;Zeiger auf Eintrag sichern.
			pha
			lda	r0L
			pha

			asl
			tax
			lda	WP_Colors +0,x		;Zeiger auf Farbdaten für
			sta	r8L			;aktuellen Eintrag einlesen.
			lda	WP_Colors +1,x
			sta	r8H

			lda	WP_IconData +0,x	;Zeiger auf Icondaten für
			sta	r0L			;aktuellen Eintrag einlesen.
			lda	WP_IconData +1,x
			sta	r0H

			lda	WP_IconName +0,x	;Zeiger auf Name für
			sta	r5L			;aktuellen Eintrag einlesen.
			lda	WP_IconName +1,x
			sta	r5H

			ldy	#$00			;Name für Eintrag löschen.
			sty	dataFileName
			LoadW	r4,dataFileName		;Zeiger auf Name für Eintrag.

			pla
			pha
			cmp	#$04			;Laufwerk?
			bcs	:6			; => Nein, weiter...

			tax
			lda	driveType,x		;Laufwerk vorhanden?
			beq	:7			; => Nein, weiter...

::6			ldx	#r5L			;Name für Eintrag kopieren.
			ldy	#r4L
			jsr	SysCopyName

::7			PushB	r1L			;Icon mit Name ausgeben.
			PushB	r1H

			LoadB	r2L,$03
			LoadB	r2H,$15
			LoadB	r3L,$00			;Daten aus Farbtabelle kopieren.
			LoadB	r3H,4
;			LoadW	r4,dataFileName		;Zeiger auf Name bereits gesetzt.
			jsr	GD_FICON_NAME		;Icon+Name ausgeben.

			pla				;Y-Pos für Textausgabe.
			sta	r1H
			pla				;X-Pos für Textausgabe.
			sta	r11L

			pla
			cmp	#$04			;Laufwerk ausgeben?
			bcs	:8			; => Nein, Weiter...

			pha				;Laufwerk speichern.
			jsr	PrntGeosDrvName		;Laufwerksname A: bis D: ausgeben.
			pla				;Laufwerk zurücksetzen.

::8			sta	r0L			;Zeiger auf Eintrag zurücksetzen.
			pla
			sta	r0H
			ldx	#$ff			; => Ein Icon ausgegeben.
			rts

;*** Laufwerk A: bis D: für Laufwerks-Icon ausgeben.
;    Übergabe: AKKU = Laufwerk #0 bis #3.
;              r1H  = YPos/oben.
;              r11L = XPos/links in Cards.
:PrntGeosDrvName	pha				;Laufwerk merken.

			lda	r1H			;Y-Pos setzen.
			clc
			adc	#$06
			sta	r1H

			lda	#$00			;X-Pos von CARDs nach Pixel wandeln.
			sta	r11H
			ldx	#r11L
			ldy	#$03
			jsr	DShiftLeft

			AddVBW	2,r11L			;X-Pos setzen.

			pla				;Laufwerksbezeichnung A: bis D:
			clc				;an Icon ausgeben.
			adc	#"A"			;Laufwerk 0 - 3 nach A - D wandeln
			jsr	SmallPutChar		;und ausgeben.

			lda	#":"			;Laufwerksbuchstabe abschließen.
			jmp	SmallPutChar

;*** Zeiger auf Icons in "MyComputer".
:WP_IconData		w Icon_Drive
			w Icon_Drive
			w Icon_Drive
			w Icon_Drive
			w Icon_Printer
			w Icon_Input

;*** Zeiger auf Namen in "MyComputer".
:WP_IconName		w DrACurDkNm
			w DrBCurDkNm
			w DrCCurDkNm
			w DrDCurDkNm
			w PrntFileName
			w inputDevName

;*** Zeiger auf Farben in "MyComputer".
:WP_Colors		w Color_Drive
			w Color_Drive
			w Color_Drive
			w Color_Drive
			w Color_Prnt
			w Color_Inpt

;*** Farb-Tabelle für "MyComputer"-Icons.
:Color_Drive		b $05,$05,$05,$0f,$0f,$0f,$09,$09,$09
:Color_Prnt		b $15,$15,$05,$bf,$bf,$b5,$b9,$b9,$b9
:Color_Inpt		b $05,$05,$05,$05,$01,$05,$b9,$09,$b9
:Color_SDir		b $75,$75,$75,$75,$75,$75,$79,$79,$79
;--- Hinweis:
;Standardfarbe für AppLinks wird durch
;C_GDesk_ALIcon gesetzt.
;Color_Std		b $01,$01,$01,$01,$01,$01,$01,$01,$01
