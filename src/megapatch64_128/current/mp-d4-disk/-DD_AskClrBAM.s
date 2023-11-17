; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** BAM für RAM-Laufwerk erzeugen.
:CreateBAM		lda	curDrive		;Aktuellen Laufwerk einlesen und
			pha				;zwischenspeichern.
			lda	DriveAdr
			jsr	SetDevice		;Neues Laufwerk aktivieren.

;--- RAM-Laufwerk bereits installiert ?
::51			jsr	TestCurBAM		;BAM testen.
			txa				;Ist BAM gültig ?
			bne	:52			; => Nein, weiter...

			jsr	AskClearCurBAM		;Laufwerk formatieren ?
			txa
			beq	:53			; => Nicht löschen, weiter...

::52			jsr	ClearCurBAM		;Aktuelles Laufwerk löschen.
			txa				;Diskettenfehler ?
			bne	:54			; => Ja, Ende...

::53			jsr	AskClearBAMboot		;Abfrage "BAM immer löschen ?"

			ldx	#NO_ERROR		;Kein Fehler...
			b $2c
::54			ldx	#DEV_NOT_FOUND		;Nicht installiert.
			stx	:55 +1
			pla
			jsr	SetDevice		;Laufwerk zurücksetzen.
::55			ldx	#$ff
			rts

;*** Dialogbox: "Aktuelle BAM löschen ?".
:AskClearCurBAM		bit	firstBoot		;GEOS-BootUp ?
			bmi	:51			; => Nein, weiter...
			ldx	AutoClearBAM		;Flag für "BAM löschen" einlesen.
			rts

::51			lda	DriveAdr
			clc
			adc	#$39
			sta	DrvName +9
			LoadW	r0,Dlg_ClearBAM
			jsr	DoDlgBox		;Abfrage: "BAM löschen ?"

			ldx	#NO_ERROR
			lda	sysDBData
			cmp	#NO			;BAM löschen ?
			beq	:52			; => Nein, weiter...
			dex
::52			rts

;*** Dialogbox: "BAM löschen ?".
:AskClearBAMboot	bit	firstBoot		;GEOS-BootUp ?
			bmi	:51			; => Nein, weiter...
			rts

::51			LoadW	r0,Dlg_AutoClearBAM
			jsr	DoDlgBox		;Abfrage: "BAM automatisch löschen?"

			ldx	#$00
			lda	sysDBData
			cmp	#NO			;BAM während GEOS-BootUp löschen ?
			beq	:52			; => Nein, weiter...
			dex
::52			cpx	AutoClearBAM
			beq	:53
			stx	AutoClearBAM

			jsr	UpdateDiskInit		;Init-Routine aktualisieren.

::53			lda	DriveAdr
			jsr	SetDevice		;Laufwerk aktivieren.
			jmp	OpenDisk		;Diskette öffnen.

;*** Init-Routine aktualisieren.
:UpdateDiskInit		lda	DriveMode		;INIT-Routine im Laufwerkstreiber
			ldx	#< DSK_INIT_SIZE	;aktualisieren. Damit werden die
			stx	r2L			;Vorgabe-Werte in die Systemdatei
			ldx	#> DSK_INIT_SIZE	;geschrieben und können beim
			stx	r2H			;beim Systemstart abgerufen werden.
			jmp	SaveDskDrvData

;*** Titel für Dialogbox zeichnen.
:Dlg_DrawBoxTitel	lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$20,$2f
			w	$0040 ! DOUBLE_W,$00ff ! DOUBLE_W ! ADD1_W
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** Speicher an ":ramBase"-Position testen.
;Dies kann nicht über die MegaPatch-
;Speicheradressen erfolgen, da GEOS-
;Editor eine temporäre Tabelle nutzt.
:ramBase_Check		sta	r0L			;ramBase-Startadresse.
			sty	r0H			;Anzahl 64K-Speicherbänke.

			ldx	ramExpSize		;Speichererweiterung verfügbar ?
			beq	:3			; => Nein, Abbruch...

			clc
			adc	r0H
			cmp	ramExpSize		;Angeforderter Speicher verfügbar ?
			bcs	:3			; => Nein, Abbruch...

::1			lda	r0L			;Aktuelle Bank-Adresse.
			jsr	AllocateBank		;Bank reservieren.
			txa				;Fehler ?
			bne	:3			; => Ja, Abruch...

			lda	r0L			;Bank wieder freigeben.
			jsr	FreeBank

			inc	r0L			;Nächste Speicherbank.
			dec	r0H			;Alle Speicherbänke überprüft ?
			bne	:1			; => Nein, weiter...

::2			ldx	#NO_ERROR		;Genügend Speicher frei.
			b $2c
::3			ldx	#NO_FREE_RAM		;Nicht genügend Speicher frei.
			rts

;*** Variablen.
:AutoClearBAM		b $00

;*** Dialogbox.
:Dlg_ClearBAM		b %11100001
			b DB_USR_ROUT
			w Dlg_DrawBoxTitel
			b DBTXTSTR ,$10,$0b
			w DlgBoxTitle
			b DBTXTSTR ,$10,$20
			w :51
			b DBTXTSTR ,$10,$2a
			w DrvName
			b YES      ,$02,$48
			b NO       ,$10,$48
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT,BOLDON
			b "Inhaltsverzeichnis auf",NULL
:DrvName		b "Laufwerk X: löschen ?",NULL
endif

if Sprache = Englisch
::51			b PLAINTEXT,BOLDON
			b "Clear directory",NULL
:DrvName		b "on drive X: ?",NULL
endif

;*** Dialogbox.
:Dlg_AutoClearBAM	b %11100001
			b DB_USR_ROUT
			w Dlg_DrawBoxTitel
			b DBTXTSTR ,$10,$0b
			w DlgBoxTitle
			b DBTXTSTR ,$10,$20
			w :51
			b DBTXTSTR ,$10,$2a
			w :52
			b YES      ,$02,$48
			b NO       ,$10,$48
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT,BOLDON
			b "Inhaltsverzeichnis bei",NULL
::52			b "jedem Neustart löschen ?",NULL
endif

if Sprache = Englisch
::51			b PLAINTEXT,BOLDON
			b "Clear directory at",NULL
::52			b "GEOS-startup ?",NULL
endif
