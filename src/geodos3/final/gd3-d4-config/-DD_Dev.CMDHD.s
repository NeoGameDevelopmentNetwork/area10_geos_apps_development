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
:InstallDriver		lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	DskDev_Prepare		;Treiber installieren.

;--- RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
			lda	#NULL
			jsr	:set_drv_data

;--- Parallelkabel testen.
::1			jsr	:testCBMkey		;C=-Taste gedrückt ?
			bne	:2			; => Nein, weiter...

			lda	#$7f			;Abfrage HD-Kabel aktivieren.
			sta	FastPPmode
			bne	:3

::2			lda	FastPPmode		;HD-Kabel abschalten ?
			beq	:no_hd_cable		; => Kein HD-Kabel, Ende...

::3			jsr	DetectRLNK		;CMD-RAMLink verfügbar ?
			txa				;RAMLink verfügbar ?
			bne	:no_hd_cable		; => Kein HD-Kabel, Ende...

			jsr	TestHDcable		;Auf HD-Kabel testen.
			bne	:no_hd_cable		; => Kein HD-Kabel, Ende...

			lda	FastPPmode		;HD-Kabel aktivieren ?
			bmi	:use_hd_cable		; => Ja, weiter...

			LoadW	r0,Dlg_EnableHDpp	;Dialogbox "HD-Kabel aktivieren ?"
			jsr	DoDlgBox		;Abfrage starten.

			lda	sysDBData
			cmp	#NO			;HD-Kabel aktivieren ?
			beq	:no_hd_cable		; => Nein, weiter...

;--- TurboPP-Treiber installieren.
::use_hd_cable		jsr	i_MoveData		;Laufwerkstreiber für HD-Kabel
			w	HD_PP			;aktivieren.
			w	DISK_BASE
			w	SIZE_DDRV_DATA

;--- RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
			lda	#SET_MODE_FASTDISK
			jsr	:set_drv_data

			lda	#$ff			;HD-Kabel immer ein.
			b $2c
::no_hd_cable		lda	#$00			;HD-Kabel immer aus.
			pha

;--- Laufwerkstreiber speichern.
			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- Konfiguration HD-Kabel speichern ?
			pla
			cmp	FastPPmode		;FastPPmode geändert ?
			beq	:done			; => Nein, weiter...
			sta	FastPPmode		;Neuen HD-Kabel-Modus speichern.
			jsr	UpdateDskDrvData	;Einstellungen aktualisieren.

::done			ldx	#NO_ERROR
::exit			rts				;Ende.

;--- ":RealDrvMode" definieren.
;Übergabe: AKKU = NULL oder SET_MODE_FASTDISK
::set_drv_data		ldx	DrvAdrGEOS		;Laufwerksmodi festlegen.
			ora	#SET_MODE_PARTITION
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x

			lda	driveType   -8,x	;Bei NativeMode auch
			and	#%00000111		;Unterverzeichnisse erlauben.
			cmp	#DrvNative
			bne	:cbm
			lda	#SET_MODE_SUBDIR
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x
::cbm			rts

;--- Auf C=-Taste testen.
::testCBMkey		php
			sei
			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA
			lda	#%01111111
			sta	CIA_PRA
			lda	CIA_PRB
			stx	CPU_DATA
			plp
			and	#%00100000
			rts

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
			b DBTXTSTR ,$10,$2e
			w :52
			b DBTXTSTR ,$10,$38
			w :53
			b DBTXTSTR ,$10,$42
			w :54
			b YES      ,$02,$58
			b NO       ,$10,$58
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT,BOLDON
			b "HD-Parallel-Kabel aktivieren?",NULL
::52			b PLAINTEXT
			b "Die Einstellung wird gespeichert.",NULL
::53			b "Zurücksetzen mit C=-Taste bei",NULL
::54			b "Auswahl der GEOS-Laufwerksadresse.",NULL
endif

if Sprache = Englisch
::51			b PLAINTEXT,BOLDON
			b "Enable the HD parallel cable?",NULL
::52			b PLAINTEXT
			b "You selection will be saved.",NULL
::53			b "Reset by pressing the C=-key",NULL
::54			b "while selecting the GEOS drive.",NULL
endif
