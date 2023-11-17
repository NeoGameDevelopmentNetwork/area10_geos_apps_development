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
:_DRV_INSTALL		jsr	initCopyDriver		;Treiber installieren.

;--- Parallelkabel testen.
			jsr	:testCBMkey		;C=-Taste gedrückt ?
			bne	:1			; => Nein, weiter...

			lda	#%01000000		;Abfrage HD-Kabel aktivieren.
			ora	DDRV_VAR_CONF
			sta	DDRV_VAR_CONF
			bne	:2

::1			lda	DDRV_VAR_CONF
			and	#%11000000		;HD-Kabel abschalten ?
			beq	:no_hd_cable		; => Ja, kein HD-Kabel, Ende...

::2			jsr	DetectRLNK		;CMD-RAMLink verfügbar ?
			txa				;RAMLink verfügbar ?
			bne	:no_hd_cable		; => Kein HD-Kabel, Ende...

			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	TestHDcable		;Auf HD-Kabel testen.
			txa				;HD-Kabel vorhanden ?
			bne	:no_hd_cable		; => Nein, Ende...

			bit	DDRV_VAR_CONF		;HD-Kabel-Auswahlbox anzeigen ?
			bvs	:3			; => Ja, weiter...
			bmi	:use_hd_cable		; => HD-Kabel aktivieren...

::3			lda	GD_APPDRV_NAME		;Name Laufwerkstreiber bekannt ?
			bne	:4			; => Ja, weiter...

			sta	Dlg_EnableHDpp +26

::4			LoadW	r0,Dlg_EnableHDpp	;Dialogbox "HD-Kabel aktivieren ?"
			jsr	DoDlgBox		;Abfrage starten.

			lda	#%00000000		;Keine Auswahl mehr anzeigen.
			sta	DDRV_VAR_CONF

			lda	sysDBData
			cmp	#NO			;HD-Kabel aktivieren ?
			beq	:no_hd_cable		; => Nein, weiter...

;--- TurboPP-Treiber installieren.
::use_hd_cable		jsr	i_MoveData		;Laufwerkstreiber für HD-Kabel
			w	HD_PP			;aktivieren.
			w	DISK_BASE
			w	DISK_DRIVER_SIZE

			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			lda	RealDrvMode -8,x
			ora	#SET_MODE_FASTDISK
			sta	RealDrvMode -8,x

			lda	#%10000000		;HD-Kabel immer ein.
			b $2c
::no_hd_cable		lda	#%00000000		;HD-Kabel immer aus.
			pha

;--- Laufwerkstreiber speichern.
			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Konfiguration HD-Kabel speichern ?
			lda	DDRV_VAR_CONF		;FastPP-Modus aus
			and	#%00111111		;Konfigurationsregister löschen.
			sta	r0L
			pla				;Neuen FastPP-Modus in
			ora	r0L			;Konfigurationsregister übernehmen.
			cmp	DDRV_VAR_CONF		;FastPP-Modus geändert ?
			beq	:done			; => Nein, weiter...

			sta	DDRV_VAR_CONF		;Neuen HD-Kabel-Modus speichern.

			lda	#TRUE			;Treiber-Einstellungen
			sta	flgUpdDDrvFile		;aktualisieren.

::done			ldx	#NO_ERROR
::exit			rts				;Ende.

;--- Auf C=-Taste testen.
::testCBMkey		php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	#%01111111
			sta	cia1base +0
			lda	cia1base +1
			stx	CPU_DATA
			plp
			and	#%00100000
			rts

;*** Auf CMD-HD-Kabel testen.
;Übergabe: XReg = Geräteadresse #8-11
:TestHDcable		lda	curDevice		;Aktuelles Laufwerk speichern.
			pha
			stx	curDevice

			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	#<:hdCable1
			ldx	#>:hdCable1
			ldy	#(17 +6)
			jsr	_DDC_SENDCOMVLEN

			jsr	UNLSN

			lda	#<:hdCable2
			ldx	#>:hdCable2
			ldy	#(25 +6)
			jsr	_DDC_SENDCOMVLEN

			jsr	UNLSN

			lda	#<:FCom_TestHD
			ldx	#>:FCom_TestHD
			ldy	#5
			jsr	_DDC_SENDCOMVLEN

			jsr	UNLSN

			jsr	EN_SET_REC		;RAMLink-Register einschalten.

			ldx	#$98
			lda	$df41
			pha
			lda	$df42
			stx	$df43
			sta	$df42
			pla
			sta	$df41

			lda	#$00
			sta	r0L
			sta	r0H

			lda	$df40
			clc
			adc	#$10
			sta	:testbyte1 +1
			adc	#$10
			sta	:testbyte2 +1

::loop1			lda	$df40
::testbyte1		cmp	#$ff
			beq	:loop2

			inc	r0L
			bne	:loop1
			inc	r0H
			bne	:loop1
			beq	:failed

::loop2			lda	$df40
::testbyte2		cmp	#$ff
			beq	:found

			inc	r0L
			bne	:loop2
			inc	r0H
			bne	:loop2
;			beq	:failed

::failed		lda	#DEV_NOT_FOUND
			b $2c
::found			lda	#NO_ERROR
			pha

			jsr	RL_HW_DIS2		;RAMLink-Register abschalten.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			tax

			pla
			sta	curDevice		;Laufwerksadresse zurücksetzen.

			rts

;--- Test-Routine Teil #1
::hdCable1		b "M-W"
			w $0300
			b 17

			sei
			ldx	#$82
			lda	$8802
			stx	$8803
			sta	$8802
			lda	#$10
			sta	$8000

;--- Test-Routine Teil #2
::hdCable2		b "M-W"
			w $0311
			b 25

			ldx	#$00
			ldy	#$00
::hd1			iny
			bne	:hd1
			inx
			bne	:hd1

;			ldx	#$00
			lda	#$01
::hd2			sta	$8800
::hd3			inx
			bne	:hd3
			clc
			adc	#$01
			bne	:hd2
			cli
			rts

;--- Test-Routine starten
::FCom_TestHD		b "M-E"
			w $0300

;*** Dialogbox: HD-Kabel aktivieren?
:Dlg_EnableHDpp		b %01100001
			b $30,$9f
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$10,$0b
			w DlgBoxTitle
			b DBTXTSTR ,$10,$20
			w :51

			b YES      ,$02,$58
			b NO       ,$10,$58

::b26			b DBTXTSTR ,$10,$2e
			w :52
			b DBTXTSTR ,$10,$38
			w :53
			b DBTXTSTR ,$10,$42
			w :54
			b NULL

if LANG = LANG_DE
::51			b PLAINTEXT
			b "HD-Parallel-Kabel aktivieren?",NULL
::52			b "Die Einstellung wird gespeichert.",NULL
::53			b "Zurücksetzen mit C=-Taste bei",NULL
::54			b "Auswahl der GEOS-Laufwerksadresse.",NULL
endif

if LANG = LANG_EN
::51			b PLAINTEXT
			b "Enable the HD parallel cable?",NULL
::52			b "Your selection will be saved.",NULL
::53			b "Reset by pressing the C= key",NULL
::54			b "while selecting the GEOS drive.",NULL
endif
