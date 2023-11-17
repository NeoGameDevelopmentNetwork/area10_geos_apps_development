; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neuen Drucker definieren.
.setNewPrinter		jsr	updatePrntName
			jsr	updatePrntStatus

			ldx	#r5L
			jsr	setVecOpenDkNm

			lda	#> PrntDiskName
			sta	r6H
			lda	#< PrntDiskName
			sta	r6L

			ldx	#r5L
			ldy	#r6L
			lda	#18
			jsr	copyNameA0_a

;*** RBOOT-Kernal aktualisieren.
:updateRBootData	txa
			pha

			lda	sysRAMFlg
			and	#%00100000
			beq	:2

			ldy	#6			;Zeiger auf REU.
::1			lda	geosRBootData,y
			sta	r0,y
			dey
			bpl	:1

			jsr	StashRAM		;Update RAM-RBoot.

::2			pla
			tax
			rts

;*** Daten für GEOS-Variablen in REU/RBoot.
:geosRBootData		w GEOS_VAR_DATA			;$8400 - $88ff
			w GEOS_VAR_RBOOT		;$7900 - $7dff
			w GEOS_VAR_SIZE			;$0500 Byte
			b $00

;*** Neues Eingabegerät definieren.
.setNewInputDev		lda	#$00			;Nur laden.
			sta	r0L

			lda	#> inputDevName
			sta	r6H
			lda	#< inputDevName
			sta	r6L

			jsr	GetFile			;Eingabetreiber.
			txa				;Diskfehler?
			bne	:err			; => Ja, Abbruch...

			lda	version
			cmp	#$13			;GEOS 1.0 - 1.2?
			bcc	:init			; => Kein RBoot...

			lda	sysRAMFlg
			and	#%00100000		;RAM-RBoot?
			beq	:init			; => Nein, weiter...

			ldy	#6			;Zeiger auf REU.
::1			lda	mouseRBootData,y
			sta	r0,y
			dey
			bpl	:1

			jsr	StashRAM		;Maustreiber in REU.

::init			jsr	InitMouse		;Maustreiber starten.

::ok			ldx	#NO_ERROR		;Kein Fehler.
			beq	:update			; => Ende...

::err			cpx	#FILE_NOT_FOUND
			beq	:ok

::update		jmp	updateRBootData

;*** Daten für Maustreiber in REU/RBoot.
:mouseRBootData		w MOUSE_BASE			;Maustreiber Kernal.
			w MOUSE_RBOOT			;Maustreiber RBoot.
			w MOUSE_SIZE			;Größe Maustreiber.
			b $00				;RBoot-Bank in REU.
