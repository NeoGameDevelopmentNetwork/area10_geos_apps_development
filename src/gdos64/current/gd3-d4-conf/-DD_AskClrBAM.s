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
			lda	DrvAdrGEOS
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
:AskClearCurBAM		ldx	AutoClearBAM		;Flag für "BAM löschen" einlesen.
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:51			; => Ja, Ende...

			lda	DrvAdrGEOS		;Laufwerk in Fehlermeldung
			clc				;übernehmen.
			adc	#"A" -8
			sta	dlgDevAdr

			LoadW	r0,Dlg_ClearBAM
			jsr	DoDlgBox		;Abfrage: "BAM löschen ?"

			ldx	#NO_ERROR
			lda	sysDBData
			cmp	#NO			;BAM löschen ?
			beq	:51			; => Nein, weiter...
			dex
::51			rts

;*** Dialogbox: "BAM löschen ?".
:AskClearBAMboot	bit	firstBoot		;GEOS-BootUp ?
			bpl	:52			; => Ja, Ende...

;--- Hinweis:
;Damit wird die Dialogbox "BAM beim
;Start löschen" nicht angezeigt, wenn
;als Anwendung gestartet.
			bit	DEV_INSTALL_MODE
			bpl	:52

			LoadW	r0,Dlg_AutoClearBAM
			jsr	DoDlgBox		;Abfrage: "BAM automatisch löschen?"

			ldx	#$00
			lda	sysDBData
			cmp	#NO			;BAM während GEOS-BootUp löschen ?
			beq	:51			; => Nein, weiter...
			dex
::51			cpx	AutoClearBAM		;Einstellung geändert ?
			beq	:52

			stx	AutoClearBAM		;Einstellung speichern.

			lda	#TRUE			;Treiber-Einstellungen
			sta	flgUpdDDrvFile		;aktualisieren.

::52			rts

;*** Speicher an ":ramBase"-Position testen.
:ramBase_Check		sta	r0L			;ramBase-Startadresse.
			sty	r0H			;Anzahl 64K-Speicherbänke.

			ldx	ramExpSize		;Speichererweiterung verfügbar ?
			beq	:3			; => Nein, Abbruch...

			clc
			adc	r0H
			cmp	ramExpSize		;Angeforderter Speicher verfügbar ?
			bcs	:3			; => Nein, Abbruch...

::1			ldy	r0L			;Bank-Status einlesen.
			jsr	:get_bank_status	;Ist Speicherbank frei ?
			bne	:3			; => Nein, Abbruch...
			inc	r0L			;Nächste Speicherbank.
			dec	r0H			;Alle Speicherbänke überprüft ?
			bne	:1			; => Nein, weiter...

::2			ldx	#NO_ERROR
			b $2c
::3			ldx	#NO_FREE_RAM
			rts

;*** Tabellenwert für Speicherbank finden.
;    Übergabe: YReg = 64K-Speicherbank-Nr.
;    Rückgabe: AKKU = %00xxxxxx = Frei.
;                     %01xxxxxx = Anwendung.
;                     %10xxxxxx = Laufwerk.
;                     %11xxxxxx = System.
::get_bank_status	tya
			lsr
			lsr
			tax
			lda	RamBankInUse,x
			pha
			tya
			and	#%00000011
			tax
			pla
::11			cpx	#$00
			beq	:12
			asl
			asl
			dex
			bne	:11
::12			and	#%11000000
			rts

;*** Dialogbox.
:Dlg_ClearBAM		b %01100001
			b $30,$8f
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$10,$0b
			w DlgBoxTitle
			b DBTXTSTR ,$10,$20
			w :51
			b DBTXTSTR ,$10,$2a
			w :52
			b YES      ,$02,$48
			b NO       ,$10,$48
			b NULL

if LANG = LANG_DE
::51			b PLAINTEXT
			b "Inhaltsverzeichnis auf",NULL
::52			b "Laufwerk "
:dlgDevAdr		b "X: löschen ?",NULL
endif

if LANG = LANG_EN
::51			b PLAINTEXT
			b "Clear directory",NULL
::52			b "on drive "
:dlgDevAdr		b "X: ?",NULL
endif

;*** Dialogbox.
:Dlg_AutoClearBAM	b %01100001
			b $30,$8f
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$10,$0b
			w DlgBoxTitle
			b DBTXTSTR ,$10,$20
			w :51
			b DBTXTSTR ,$10,$2a
			w :52
			b YES      ,$02,$48
			b NO       ,$10,$48
			b NULL

if LANG = LANG_DE
::51			b PLAINTEXT
			b "Inhaltsverzeichnis bei",NULL
::52			b "jedem Neustart löschen ?",NULL
endif

if LANG = LANG_EN
::51			b PLAINTEXT
			b "Clear directory at",NULL
::52			b "GEOS-startup ?",NULL
endif
