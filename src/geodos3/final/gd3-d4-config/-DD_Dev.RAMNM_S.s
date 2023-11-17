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
:InstallDriver		lda	#"S"			;Kennung für RAM-Laufwerk/GEOS-DACC.
			ldx	#"R"
			ldy	#"C"
			jsr	SetRDrvName

;--- RAMCard suchen.
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
			lda	#SET_MODE_SUBDIR!SET_MODE_FASTDISK!SET_MODE_SRAM
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

::skip_ram		jsr	SRAM_GET_SIZE		;Freien Speicher ermitteln.
			txa				;Fehler ?
			bne	:2			; => Ja, Abbruch...

			lda	SRAM_BANK_COUNT		;Max. Speicher in RAMCard.
			b $2c
::2			lda	#$00			;Kein Speicher verfügbar.

;--- Ergänzung: 16.08.18/M.Kanet
;Im Vergleich zu anderen Speichererweiterungen besitzt die RAMCard ein
;internes Speichermanagement. Der von GEOS reservierte Speicher ist hier
;bereits als "belegt" markiert. Die jetzt ermittelte Anzahl der freien
;Speicherbänke steht somit komplett für das SCPU-Laufwerk zur Verfügung.
;			cmp	#$00			;Speicher verfügbar?
;			beq	:4			;Nein, Abbruch...
;			ldy	ramExpSize		;Zeiger auf erste Bank ermitteln.
;			ldx	GEOS_RAM_TYP		;GEOS-DACC-Typ einlesen.
;			cpx	#RAM_SCPU		;RAMCard = GEOS-DACC?
;			beq	:3			;Ja, Speicher beginnt hinter DACC.
;			ldy	SRAM_FREE_START		;Erste freie Speicherbank.
;			lda	SRAM_FREE_END		;Letzte freie Speicherbank.
;::3			sty	MinFreeRRAM		;Freien Speicher berechnen.
;			cmp	MinFreeRRAM
;			bcc	:2
;			sta	MaxFreeRRAM
;			sec
;			sbc	MinFreeRRAM
::4			sta	MaxSizeRRAM
			cmp	#2			;Mind 2x64K verfügbar?
			bcc	:no_ram			; => Nein, Abbruch...

;--- Treiber installieren.
			ldx	DrvAdrGEOS		;Laufwerksdaten setzen.
			lda	SRAM_FREE_START		;Erste Speicherbank definieren.
			sta	ramBase     -8,x

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

			ldx	DrvAdrGEOS
			lda	SetSizeRRAM		;Größe RAMNative-Laufwerk
			cmp	DrvDataSize -8,x	;geändert ?
			beq	:skip_upd		; => Nein, weiter...
			sta	DrvDataSize -8,x	;Neue Vorgabe speichern.
			jsr	UpdateDskDrvData	;Einstellngen aktualisieren.

;--- Speichermanagement aktualisieren.
::skip_upd		lda	SRAM_FREE_START
			jsr	LOCK_SRAM		;RAMCard Speicher reservieren.

;--- Laufwerk initialisieren.
			jsr	InitRDrvNM		;RAMNative-Laufwerk initialisieren.
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

;*** Speicher in RAMCard freigeben.
;    Übergabe: -
:LOCK_SRAM		php				;IRQ sperren.
			sei

			lda	CPU_DATA		;I/O-Bereich aktivieren.
			pha
			lda	#IO_IN
			sta	CPU_DATA

			sta	SCPU_HW_EN		;SuperCPU-Register aktivieren.

			ldy	DrvAdrGEOS		;Größe des freien Speichers in
			lda	ramBase   -8,y		;der SuperCPU korrigieren.
			clc
			adc	SetSizeRRAM
			sta	SRAM_FIRST_BANK		;First available Bank.
			lda	#$00
			sta	SRAM_FIRST_PAGE		;First available Page.

			sta	SCPU_HW_DIS		;SuperCPU-Register abschalten.

			pla
			sta	CPU_DATA		;I/O-Bereich ausblenden.

			plp				;IRQ-Status zurücksetzen.
			rts
