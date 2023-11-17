; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Gelöschte Dateien wieder herstellen.
:xRECOVERY		lda	WM_DATA_MAXENTRY +0
if MAXENTRY16BIT = TRUE
			ora	WM_DATA_MAXENTRY +1
endif
			bne	:1			; => Dateien vorhanden, weiter...
			jmp	MOD_RESTART		;Keine Dateien, Abbruch...

;--- Zeiger auf ersten Verzeichnis-Sektor.
::1			lda	#$00
			sta	updateDir		;Verzeichnis-Update zurücksetzen.
			sta	filesRecovered		;Anzahl Dateien zurücksetzen.
			sta	recoveryError		;Anzahl Fehler zurücksetzen.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	Get1stDirEntry		;Zeiger erster Verzeichnis-Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			bne	:findfile		; => Ja, weiter...
			jmp	:cancel			;Ende...

;--- Zeiger auf Anfang Dateiliste.
::findfile		MoveB	r1L,curDirSek +0	;Zeiger auf Track/Sektor
			MoveB	r1H,curDirSek +1	;zwischenspeichern.

			LoadW	a9,BASE_DIR_DATA	;Zeiger auf Verzeichnisdaten.

			ClrB	a8L			;Dateizähler löschen.
if MAXENTRY16BIT = TRUE
			sta	a8H
endif

;--- Verzeichnis-Eintrag auswerten.
::loop			ldy	#$00
			lda	(a9L),y			;Auswahlk-Flag einlesen.
			and	#GD_MODE_MASK		;Datei ausgewählt?
			beq	:skip_file		; => Nein, weiter...
			iny
			iny
			lda	(a9L),y			;Datei gelöscht?
			bne	:skip_file		; => Nein, weiter...

;--- Markierte Datei im Verzeichnis suchen.
			dey
			dey
::2			lda	(r5L),y			;Verzeichnis-Eintrag mit aktuellem
			iny				;Dateieintrag vergleichen.
			iny
			cmp	(a9L),y
			bne	:skip_file
			dey
;			dey
;			iny
			cpy	#30			;Eintrag geprüft?
			bcc	:2			; => Nein, weiter...

			jsr	CopyFName		;Dateiname für Fehlermeldung.

			jsr	chkGeosHeader		;GEOS-Header testen.
			txa				;Header OK?
			bne	:next_file		; => Nein, weiter...

			jsr	recoverFile		;Datei wiederherstellen.
			txa				;Diskettenfehler ?
			beq	:next_file		; => Nein, weiter...

			cpx	#BAD_BAM		;Datei bereits überschrieben ?
			bne	:error			; => Nein, Fehler ausgeben.

			LoadW	r0,Dlg_ErrBadBAM	;BAM belegt / Datei überschrieben.
			jsr	DoDlgBox		;Fehlermeldung anzeigen.

			lda	sysDBData
			cmp	#CANCEL			;VALIDATE ausführen?
			beq	:cancel			; => Nein, Abbruch...
			bne	:next_file		;VALIDATE ausführen.

;--- Laufwerksfehler.
::error			jsr	doXRegStatus		;Fehlermeldung ausgeben.
			jmp	:cancel			;Funktion abbrechen.

;--- Weiter mit nächster Datei.
::skip_file		inc	a8L			;Dateizähler +1.
if MAXENTRY16BIT = TRUE
			bne	:3
			inc	a8H
endif
::3
if MAXENTRY16BIT = TRUE
			lda	a8H			;Alle Dateien geprüft?
			cmp	WM_DATA_MAXENTRY +1
			bne	:4
endif
			lda	a8L
			cmp	WM_DATA_MAXENTRY +0
::4			bcs	:next_file		; => Ja, weiter...

			AddVBW	32,a9			;Nächsten Dateieintrag suchen.
			jmp	:loop

;--- Weiter mit nächsten Eintrag.
::next_file		jsr	GetNxtDirEntry		;Zeiger auf nächsten Eintrag.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...
			cpy	#$ff			;Verzeichnis-Ende erreicht?
			beq	:cancel
			jmp	:findfile		; => Nein, weiter...

;--- Verzeichnis bearbeitet.
::cancel		lda	recoveryError		;Dateien wiederhergestellt?
			bne	:5			; => Nein, weiter...
			lda	filesRecovered		;Dateien wiederhergestellt?
			beq	:exit_Recover		; => Nein, weiter...

			lda	#<Dlg_RecoverOK		;Dateien wiederhergestellt.
			ldx	#>Dlg_RecoverOK
			bne	:6
::5			lda	#<Dlg_RecoverErr	;Fehler beim wiederherstellen.
			ldx	#>Dlg_RecoverErr
::6			sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Hinweis: "Validate empfohlen".

			lda	sysDBData
			cmp	#YES			;VALIDATE ausführen?
			bne	:reload			; => Nein, Ende...
			jmp	xVALIDATE		;VALIDATE ausführen.

::exit_Recover		bit	updateDir		;BAM verändert?
			bmi	:reload			; => Ja, weiter...
			jmp	MOD_RESTART		;Zurück zum DeskTop.

::reload		jsr	SET_LOAD_DISK		;Verzeichnis neu einlesen.
			jmp	MOD_UPDATE		;Zurück zum DeskTop.

;*** Verzeichnis-Sektor auf Disk speichern.
:recoverFile		LoadB	updateDir,$ff		;Dateien evtl. wiederhergestellt.
							;":ValidateFile" setzt auch den
							;Dateiauswahl-Modus für die
							;aktuelle Datei zurück!

			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			jsr	InitForIO		;I/O aktivieren.

			jsr	setFileType		;Dateityp temporär setzen.

			jsr	ValidateFile		;Datei validieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			jsr	setFileType		;Dateityp erneut setzen, da die
							;Routine ":ValidateFile" am Ende
							;den Verzeichnis-Sektor erneut
							;einlesen muss.
							;":AllocChain" verändert den Inhalt
							;von ":diskBlkBuf"!

;			MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor
;			MoveB	curDirSek +1,r1H	;wieder zurücksetzen.
			LoadW	r4,diskBlkBuf		;Zeiger auf Dir_Sektor.
			jsr	WriteBlock		;Sektor schreiben.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...
			jsr	VerWriteBlock		;Sektor-Verify.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			inc	filesRecovered		;Anzahl Dateien +1.

::exit			jsr	DoneWithIO		;I/O abschalten.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	PutDirHead		;BAM aktualisieren.
;			txa				;Fehler?
;			bne	:error			; => Ja, Abbruch...

			MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor
			MoveB	curDirSek +1,r1H	;wieder zurücksetzen.

;			ldx	#NO_ERROR

::error			cpx	#NO_ERROR
			beq	:x
			inc	recoveryError		;Anzahl Fehler +1.
::x			rts

;*** GEOS-Dateiheader testen.
:chkGeosHeader		PushB	r1L			;Zeiger auf aktuellen
			PushB	r1H			;Verzeichniseintrag
			PushW	r4			;zwischenspeichern.
			PushW	r5

			ldy	#19			;GEOS-Header einlesen.
			lda	(r5L),y
			beq	:ok			; => Kein Header, Ende...
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			LoadW	r4,fileHeader
			jsr	GetBlock		;Header-Block einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			ldy	#0
::1			lda	fileHeader,y		;GEOS-Headerkennung testen.
			cmp	headerCode,y
			bne	:badHeader		; => Header beschädigt, Abbruch...
			iny
			cpy	#5
			bcc	:1
			bcs	:ok			; => Header OK, Ende...

::badHeader		LoadW	r0,Dlg_BadHdr
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

			ldx	#STRUCT_MISMAT		;Header beschädigt.
			b $2c
::ok			ldx	#NO_ERROR		;Header OK.

::error			cpx	#NO_ERROR
			beq	:x
			inc	recoveryError		;Anzahl Fehler +1.

::x			PopW	r5			;Zeiger auf aktuellen
			PopW	r4			;Verzeichniseintrag wieder
			PopB	r1H			;zurücksetzen.
			PopB	r1L
			rts

;*** Dateityp speichern.
:setFileType		ldy	#1			;Zeiger auf erstenn Datensektor
			jsr	CopySekAdr		;einlesen.
			LoadW	r4,fileHeader
			jsr	ReadBlock		;Datensektor einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	fileHeader +2		;Auf Verzeichnis testen.
			cmp	#$48
			bne	:isFile			; => Datei.
			lda	fileHeader +3
;			cmp	#$00
			beq	:isDir			; => Verzeichnis.

::isFile		ldx	#%10000000 ! PRG	;Standard: Dateityp = PRG.
			ldy	#21
			lda	(r5L),y			;Dateistruktur einlesen.
			beq	:setFType		; => SEQ, weiter...
			ldx	#%10000000 ! USR	;VLIR: Dateityp = USR.
			b $2c
::isDir			ldx	#%10000000 ! $06	;Verzeichnis: Dateityp = DIR.
::setFType		txa
			ldy	#0
			sta	(r5L),y			;CBM-Dateityp setzen.

			MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor
			MoveB	curDirSek +1,r1H	;wieder zurücksetzen.

			ldx	#NO_ERROR
::exit			rts

;*** Dateinamen kopieren.
:CopyFName		ldx	#0
			ldy	#5
::1			lda	(a9L),y
			beq	:2
			cmp	#$a0
			beq	:2
			sta	fileNameBuf,x
			iny
			inx
			cpx	#16
			bcc	:1
::2			lda	#$00
::3			sta	fileNameBuf,x
			iny
			inx
			cpx	#16
			bcc	:3
			rts

;*** Variablen.
:updateDir		b $00
:filesRecovered		b $00
:recoveryError		b $00
:headerCode		b $00,$ff,$03,$15,$bf
:fileNameBuf		s 17

;*** Fehler: Datei konnte nicht wieder hergestellt werden.
:Dlg_ErrBadBAM		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$10,$2c
			w fileNameBuf
			b DBTXTSTR   ,$0c,$44
			w dlgRecoverTx03
			b OK         ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Datei wurde teilweise überschrieben:"
			b BOLDON,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "File was partly overwritten:"
			b BOLDON,NULL
endif

;*** Fehler: Infoblock beschädigt.
:Dlg_BadHdr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$10,$2c
			w fileNameBuf
			b DBTXTSTR   ,$0c,$44
			w dlgRecoverTx03
			b OK         ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Der GEOS-Infoblock ist beschädigt!"
			b BOLDON,NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The GEOS infoblock is damaged!"
			b BOLDON,NULL
endif

;*** Hinweis: Dateien wieder hergestellt, Validate ausführen.
:Dlg_RecoverOK		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$3c
			w dlgRecoverTx01
			b DBTXTSTR   ,$0c,$48
			w dlgRecoverTx02
			b YES        ,$01,$50
			b NO         ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Dateien wurden wiederhergestellt.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "File recovery successful.",NULL
endif

;*** Hinweis: Dateien wieder hergestellt, Validate ausführen.
:Dlg_RecoverErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$2c
			w :3
			b DBTXTSTR   ,$0c,$3c
			w dlgRecoverTx01
			b DBTXTSTR   ,$0c,$48
			w dlgRecoverTx02
			b YES        ,$01,$50
			b NO         ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Einige Dateien konnten nicht",NULL
::3			b "wiederhergestellt werden.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Some files could not be recovered.",NULL
::3			b NULL
endif

if LANG = LANG_DE
:dlgRecoverTx01		b PLAINTEXT
			b "Überprüfung des Laufwerks empfohlen!",NULL
:dlgRecoverTx02		b "Laufwerk überprüfen?",NULL
:dlgRecoverTx03		b PLAINTEXT
			b "Wiederherstellen nicht möglich!",NULL
endif
if LANG = LANG_EN
:dlgRecoverTx01		b PLAINTEXT
			b "Validate disk is recommended!",NULL
:dlgRecoverTx02		b "Start disk validate?",NULL
:dlgRecoverTx03		b PLAINTEXT
			b "File recovery is not possible!",NULL
endif
