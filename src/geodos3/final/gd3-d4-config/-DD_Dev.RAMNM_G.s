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
:InstallDriver		lda	#"G"			;Kennung für RAM-Laufwerk/GEOS-DACC.
			ldx	#"E"
			ldy	#"O"
			jsr	SetRDrvName

;--- GeoRAM suchen.
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
			lda	#SET_MODE_SUBDIR!SET_MODE_FASTDISK!SET_MODE_GRAM
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

::skip_ram		jsr	GRAM_GET_SIZE		;Größe der C=REU ermitteln.
			txa				;Fehler aufgetreten?
			bne	:2			;Ja, Kein Speicher verfügbar...

			lda	GRAM_BANK_VIRT64	;Anzahl 64K-Bänke einlesen.
			b $2c
::2			lda	#$00
			cmp	#$00			;Speicher verfügbar?
			beq	:4			;Nein, Abbruch...
			ldy	ramExpSize		;Zeiger auf erste Bank ermitteln.
			ldx	GEOS_RAM_TYP		;GEOS-DACC-Typ einlesen.
			cpx	#RAM_BBG		;GeoRAM = GEOS-DACC?
			beq	:3			;Ja, Speicher beginnt hinter DACC.
			ldy	#$00			;Nein, Speicher beginnt bei Bank #0.
::3			sty	MinFreeRRAM		;Freien Speicher berechnen.
			cmp	MinFreeRRAM
			bcc	:2
			sta	MaxFreeRRAM
			sec
			sbc	MinFreeRRAM
::4			sta	MaxSizeRRAM
			cmp	#2			;Mind 2x64K verfügbar?
			bcc	:no_ram			; => Nein, Abbruch...

;--- Treiber installieren.
			ldx	DrvAdrGEOS		;Laufwerksdaten setzen.
			lda	MinFreeRRAM		;Erste Speicherbank definieren.
			sta	ramBase     -8,x

			lda	GRAM_BANK_SIZE
			sta	GeoRAMBSize		;Bank-Größe in Treiber speichern.

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
