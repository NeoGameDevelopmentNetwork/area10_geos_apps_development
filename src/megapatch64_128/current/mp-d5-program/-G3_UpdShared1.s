; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zurück zum DeskTop.
;Startlaufwerk wieder aktivieren. Bei GEOSv2 kann sonst der DeskTop
;nicht gefunden werden wenn zuletzt auf Laufwerk #10/#11 zugegriffen wurde.
:ExitUpdate		lda	RecoverVecBuf +0
			sta	RecoverVector +0
			lda	RecoverVecBuf +1
			sta	RecoverVector +1

			lda	Device_Boot
			jsr	SetDevice
			jsr	OpenDisk

;--- 40Z-Farben löschen.
if Flag64_128 = TRUE_C128
			lda	graphMode		;Grafikmodus einlesen.
			bne	:80			; ->80 Zeichen.
endif

			LoadW	r0,40*25
			LoadW	r1,COLOR_MATRIX
			lda	screencolors
			sta	r2L
			jsr	FillRam

if Flag64_128 = TRUE_C128
			jmp	:40

;--- 80Z-Farben löschen.
::80			LoadW	r3,0
			LoadW	r4,639
			LoadB	r2L,0
			LoadB	r2H,199
			lda	scr80colors
			jsr	ColorRectangle		;GEOS 2.0 DirectColor-Routine !
endif

;--- Bildschirm löschen.
::40			lda	#$02
			jsr	SetPattern
			lda	#ST_WR_FORE
			sta	dispBufferOn
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000 ! DOUBLE_W
			w	$013f ! DOUBLE_W ! ADD1_W

			jmp	EnterDeskTop

;*** Speichererweiterung in Startprogramme übertragen.
:SaveConfigRAM		LoadW	r6,FNamGBOOT		;"GEOS64.BOOT" modifizieren.
			jsr	FindFile
			txa
			bne	:51

			jsr	SaveRamType

::51			LoadW	r6,FNamRBOOT		;"RBOOT64.BOOT" modifizieren.
			jsr	FindFile
			txa
			beq	SaveRamType
			cpx	#FILE_NOT_FOUND		;RBOOT gefunden? Falls nein, kein
			bne	:52			;Fehler ausgeben da RBOOT optional.
			ldx	#$00
::52			rts

;*** Konfiguration speichern.
:SaveRamType		lda	dirEntryBuf +1		;Ersten Programmsektor einlesen.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Abbruch...

::51			lda	ExtRAM_Type   ,x	;RAM_Daten speichern.
			sta	diskBlkBuf +14,x
			inx
			cpx	#$05
			bcc	:51

			jsr	PutBlock		;Sektor wieder auf Disk speichern.
::52			rts

;*** Fehlercode ausgeben.
:PrntDskErrCode		LoadB	r1H,$56
			LoadW	r11,$0060 ! DOUBLE_W
			lda	#"-"
			jsr	PutChar

			lda	DskErrCode
			sta	r0L
			lda	#$00
			sta	r0H
			lda	#%11000000
			jsr	PutDecimal

			lda	#"-"
			jmp	PutChar
