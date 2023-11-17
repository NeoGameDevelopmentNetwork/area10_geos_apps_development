; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerkstreiber installieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk installiert.
:InstallDriver		lda	#"R"			;Kennung für RAM-Laufwerk/GEOS-DACC.
			ldx	#"A"
			ldy	#"M"
			jsr	SetRDrvName

			jsr	INIT_DEV_TEST		;Freien RAM-Speicher testen.
			txa				;Ist genügend Speicher frei ?
			beq	:1			; => Ja, weiter.

::no_ram		ldx	#NO_FREE_RAM
			rts

;--- Laufwerkstreiber initialisieren.
::1			lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	DskDev_Prepare		;Treiber installieren.

;--- RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
			ldx	DrvAdrGEOS		;Laufwerksmodi festlegen.
			lda	#SET_MODE_SUBDIR!SET_MODE_FASTDISK
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x

;--- RAMBase nicht löschen.
;Wird ggf. durch den Editor gesetzt und
;dazu genutzt, um auf ein gültiges
;Verzeichnis zu prüfen.
;			lda	#$00
;			sta	ramBase -8,x

;--- Verfügbares RAM ermitteln.
			ldx	DrvAdrGEOS		;Vorgabewert für Größe des
			lda	DrvDataSize -8,x	;RAMNative-Laufwerk setzen.
			beq	:skip_ram
			sta	SetSizeRRAM

::skip_ram		jsr	GetMaxSize		;Max. mögliche Größe ermitteln.
			txa				;Laufwerk möglich?
			bne	:error			;Nein, Abbruch.

			lda	MaxSizeRRAM
			cmp	#$02			;Mind 1x64K verfügbar?
			bcc	:error			; => Ja, weiter...

;--- Laufwerkstreiber speichern.
			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Größe des Laufwerks bestimmen.
			jsr	GetCurPartSize		;Laufwerksgröße übernehmen.
			jsr	SetPartSizeData		;Größe festlegen.
			txa				;Abbruch ?
			bne	:cancel			; => Ja, Ende..

;--- Installation fortsetzen.
			lda	MinFreeRRAM		;Adresse erste Speicherbank.

			ldx	DrvAdrGEOS
			ldy	ramBase -8,x		;ramBase vordefiniert?
			beq	:2			; => Nein, weiter...

;--- Ergänzung: 21.08.21/M.Kanet
;Wenn Startadressen der RAM-Laufwerke
;nicht lückenlos sind, dann wurde das
;neue RAM-Laufwerk bisher an einer
;anderen Stelle im GEOS-DACC erstellt.
;Da vom GEOS.Editor ":ramBase" an die
;INIT-Routine übergeben wird, kann hier
;nun geprüft weden ob an der Vorgabe
;ein RAM-Laufwerk mit passender Größe
;erstellt werden kann.
;Falls nicht, dann wird das Laufwerk
;ab der erste freien Bank erstellt.
			pha				;Erste freie Speicherbank merken.
			tya				;Vorgabe für erste Speicherbank.
			ldy	SetSizeRRAM		;Anzahl Speicherbänke.
			jsr	ramBase_Check		;Speicher prüfen.
			pla
			cpx	#NO_ERROR		;Ist gewünschter Speicher frei?
			bne	:2			; => Nein, weiter...

			ldx	DrvAdrGEOS
			lda	ramBase -8,x		;Vorgabe für erste Speicherbank.

::2			pha				;Speicher für Laufwerk in
			ldy	SetSizeRRAM		;GEOS-DACC reservieren.
			ldx	#%10000000
			jsr	AllocRAM
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:error			; => Nein, Installationsfehler.

			ldx	DrvAdrGEOS		;Startadresse Laufwerk in
			sta	ramBase -8,x		;GEOS-DACC zwischenspeichern.

			lda	SetSizeRRAM		;Größe RAMNative-Laufwerk
			cmp	DrvDataSize -8,x	;geändert ?
			beq	:skip_upd		; => Nein, weiter...
			sta	DrvDataSize -8,x	;Neue Vorgabe speichern.
			jsr	UpdateDskDrvData	;Einstellungen aktualisieren.

;--- Laufwerk initialisieren.
::skip_upd		jsr	InitRDrvNM		;RAMNative-Laufwerk initialisieren.
			txa				;Vorgang erfolgreich?
			beq	:exit			;Ja, Ende...
			bne	:error

::cancel		ldx	#CANCEL_ERR		;Abbruch.
::error			txa
			pha

			ldx	DrvAdrGEOS
			jsr	INIT_DEV_REMOVE		;Laufwerk nicht installiert.

			pla
			tax

;			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** Max. freien Speicher ermitteln.
;    Rückgabe:    MinFreeRRAM = Startbank für Laufwerk im RAM.
;                 MaxSizeRRAM = Max. Größe für Laufwerk.
;Dazu wird die max. RAM-größe als Startwert gesetzt und dann der Wert
;so lange rediziert bis der größte Speicherblock für ein RAMNative-Laufwerk
;gefunden wurde.
:GetMaxSize		ldy	ramExpSize		;Max. Größe für Laufwerk
			sty	r2L			;ermitteln.

::51			ldy	r2L
			beq	:53
			jsr	FindFreeRAM
			cpx	#NO_ERROR
			beq	:52
			dec	r2L
			jmp	:51

;--- Freien Speicher gefunden.
::52			sta	MinFreeRRAM
			sty	MaxSizeRRAM
			rts

;--- Kein Speicher frei.
::53			ldy	#$00
			sty	MaxSizeRRAM
			ldx	#NO_FREE_RAM
			rts
