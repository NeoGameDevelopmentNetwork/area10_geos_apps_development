; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Ersten Druckertreiber auf Diskette suchen/laden.
:LoadDev_Printer	lda	#$ff			;Druckername in RAM löschen.
			sta	PrntFileNameRAM

			lda	#< PrntFileName
			ldx	#> PrntFileName
			ldy	#PRINTER
			jsr	LoadDev_InitFn		;Druckertreiber suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...
			lda	r7H			;Treiber gefunden ?
			bne	:1			; => Nein, Abbruch...

			lda	Flag_LoadPrnt		;Druckertreiber in REU laden ?
			bne	:1			; => Nein, weiter...

			LoadB	r0L,%00000001
			LoadW	r6 ,PrntFileName
			LoadW	r7 ,PRINTBASE
			jsr	GetFile			;Druckertreiber laden.
::1			rts

;*** Ersten Maustreiber auf Diskette suchen/laden.
:LoadDev_Mouse		lda	#< inputDevName
			ldx	#> inputDevName
			ldy	#INPUT_DEVICE
			jsr	LoadDev_InitFn		;Eingabetreiber suchen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...
			lda	r7H			;Treiber gefunden ?
			bne	:1			; => Nein, Abbruch...

			LoadB	r0L,%00000001
			LoadW	r6 ,inputDevName
			LoadW	r7 ,MOUSE_BASE
			jsr	GetFile			;Eingabetreiber laden.
::1			rts

;*** Dateisuche initialisieren.
:LoadDev_InitFn		sta	r6L			;Zeiger auf Namenspeicher.
			stx	r6H

			sty	r7L			;Dateityp.

			ldx	#$01			;Anzahl Dateien.
			stx	r7H

			dex				;Keine GEOS-Klasse.
			stx	r10L
			stx	r10H

			jmp	FindFTypes		;Gerätetreiber suchen.
