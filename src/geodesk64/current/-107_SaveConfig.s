; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konfiguration speichern.
:xSAVE_CONFIG		lda	#"1"			;Fehlercode setzen.
			sta	notFoundCode

			jsr	TempBootDrive		;Boot-Laufwerk öffnen.
			txa				;Diskettenfehler ?
			bne	:error1			; => Ja, Abbrucb...

			inc	notFoundCode		;Fehlercode setzen.

			lda	#APPLICATION		;GeoDesk suchen.
			sta	r7L
			lda	#$01
			sta	r7H
			LoadW	r6,GD_SYS_NAME
			LoadW	r10,GD_CLASS
			jsr	FindFTypes
			txa				;Diskettenfehler ?
			bne	:error1			; => Ja, Abbruch...

			inc	notFoundCode		;Fehlercode setzen.

			lda	r7H			;Modul gefunden ?
			beq	:open			; => Ja, weiter...
::error1		jmp	:error_sys		; => Nein, Abbruch...

::open			lda	#"1"			;Fehlercode setzen.
			sta	svErrorCode

			LoadW	r0,GD_SYS_NAME		;VLIR-Datei öffnen.
			jsr	OpenRecordFile
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

			inc	svErrorCode		;Fehlercode setzen.

			lda	#$00			;Zeiger auf Boot-Modul.
			jsr	PointRecord
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

			inc	svErrorCode		;Fehlercode setzen.

			LoadW	r2,$1000
			LoadW	r7,VLIR_BOOT_START
			jsr	ReadRecord		;Boot-Modul einlesen.
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

			jsr	CopyGDConfig		;GeoDesk-Variablen übernehmen.

			lda	r7L			;Größe Boot-VLIR-Modul ermitteln.
			sec
			sbc	#<VLIR_BOOT_START
			sta	r2L
			lda	r7H
			sbc	#>VLIR_BOOT_START
			sta	r2H

			inc	svErrorCode		;Fehlercode setzen.

			LoadW	r7,VLIR_BOOT_START
			jsr	WriteRecord		;Boot-Modul speichern.
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

			inc	svErrorCode		;Fehlercode setzen.

			jsr	CloseRecordFile
			txa				;Diskettenfehler?
			bne	:vlir_error		; => Ja, Abbruch...

			jsr	BackTempDrive		;Laufwerk wieder aktivieren.
			txa				;Fehler?
			beq	:exit			; => Nein, Ende.

;--- Fehler beim speichern.
::vlir_error		lda	#<Dlg_SaveError
			ldx	#>Dlg_SaveError
			bne	:errdlg

;--- GeoDosk nicht gefunden.
::error_sys		lda	#<Dlg_GeoDeskNFnd
			ldx	#>Dlg_GeoDeskNFnd
			;bne	:errdlg

;--- Fehler ausgeben.
::errdlg		sta	r0L			;Zeiger auf DialogBox-Daten setzen.
			stx	r0H
			jsr	DoDlgBox		;DialogBox aufrufen.
::exit			jmp	MOD_RESTART		;Menü/FensterManager neu starten.

;*** GeoDesk-/GEOS-Variablen sichern.
:CopyGDConfig		jsr	i_MoveData		;GEOS-Farben speichern.
			w	MP3_COLOR_DATA
			w	GEOS_SYS_COLS_A
			w	(GEOS_SYS_COLS_E - GEOS_SYS_COLS_A)

			jsr	i_MoveData		;GeoDesk-Konfiguration speichern.
			w	GD_VAR_START
			w	VLIR_BOOT_START +SYSVAR_SIZE
			w	GD_VAR_SIZE

			lda	BackScrPattern		;Hintergrundmuster speichern.
			sta	C_GEOS_PATTERN
			rts

;*** Fehler: GeoDesk nicht gefunden.
:Dlg_GeoDeskNFnd	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$0c,$3a
			w :3
			b DBTXTSTR   ,$0c,$44
			w notFoundTxt
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "GeoDesk konnte die System-",NULL
::2			b "Datei nicht finden!",NULL
::3			b "Konfiguration nicht gespeichert!",NULL
:notFoundTxt		b "Fehler: ",BOLDON
:notFoundCode		b "X",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "GeoDesk could not find the",NULL
::2			b "system file!",NULL
::3			b "Configuration was not saved!",NULL
:notFoundTxt		b "Error: ",BOLDON
:notFoundCode		b "X",NULL
endif

;*** Fehler: Fehler beim speichern.
:Dlg_SaveError		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :1
			b DBTXTSTR   ,$0c,$2a
			w :2
			b DBTXTSTR   ,$0c,$3a
			w :3
			b DBTXTSTR   ,$0c,$44
			w svErrorTxt
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::1			b PLAINTEXT
			b "Disk-Fehler beim speichern",NULL
::2			b "der GeoDesk-Konfiguration!",NULL
::3			b "Konfiguration nicht gespeichert!",NULL
:svErrorTxt		b "Fehler: ",BOLDON
:svErrorCode		b "X",NULL
endif
if LANG = LANG_EN
::1			b PLAINTEXT
			b "Disk error when saving the",NULL
::2			b "GeoDesk configuration!",NULL
::3			b "Configuration was not saved!",NULL
:svErrorTxt		b "Error: ",BOLDON
:svErrorCode		b "X",NULL
endif
