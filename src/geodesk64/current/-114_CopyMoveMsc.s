; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Flag setzen "Disk aktualisieren".
:setReloadDir		lda	#$ff
			sta	reloadDir
			rts

;*** Datum für Vergleich sichern.
:copySourceDate		ldy	#$00
			b $2c
:copyTargetDate		ldy	#$06
			ldx	#19			;Jahr 19xx...
			lda	dirEntryBuf +23		;Jahr einlesen.
			cmp	#80			;Jahr >= 1980?
			bcs	:1			; => Ja, weiter...
			inx				;Jahr 20xx...
::1			sta	sourceDate +1,y		;Jahr.
			txa
			sta	sourceDate +0,y		;Jahrtausend.

			lda	dirEntryBuf +24		;Monat.
			sta	sourceDate +2,y
			lda	dirEntryBuf +25		;Tag.
			sta	sourceDate +3,y

			lda	dirEntryBuf +26		;Stunde.
			sta	sourceDate +4,y
			lda	dirEntryBuf +27		;Stunde.
			sta	sourceDate +5,y

			rts

:sourceDate		b $00,$00,$00,$00,$00,$00
:targetDate		b $00,$00,$00,$00,$00,$00

;*** Verzeichnis-Eintrag kopieren.
;    Übergabe: r5 = Verzeichnis-Eintrag.
:copyDirEntry		ldy	#30 -1			;Verzeichnis-Eintrag in
::1			lda	(r5L),y			;Zwischenspeicher kopieren.
			sta	dirEntryBuf,y
			dey
			bpl	:1
			rts

;*** Datei-/Verzeichnis-Name kopieren.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;    Rückgabe: curFileName = Datei-/Verzeichnis-Name.
:copyFileName		LoadW	r10,dirEntryBuf +3
			LoadW	r11,curFileName
			ldx	#r10L
			ldy	#r11L
			jsr	SysCopyName

			ldy	#15			;Kopie des Dateinamens in
::1			lda	curFileName,y		;Zwischenspeicher kopieren.
			sta	origFileName,y		;Wird für Dateien verschieben
			dey				;benötigt um die Datei auf dem
			bpl	:1			;Source-Laufwerk zu löschen.
			rts

;*** Aktuellen Disk-/Verzeichnis-Namen kopieren.
:copyDirName		ldx	#r4L			;Zeiger auf aktuellen
			jsr	GetPtrCurDkNm		;Disk-/Verzeichnis-Namen setzen.

			LoadW	r0,newDirName
			ldx	#r4L
			ldy	#r0L
			jmp	SysCopyName		;Name in Zwischenspeicher kopieren.

;*** Auf Schreibschutz testen.
:testWrProtOn		lda	dirEntryBuf		;Dateityp einlesen.
			and	#%0100 0000		;Schreibschutz aktiv?
			beq	:no_error		; => Nein, weiter...

			PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			LoadW	r0,Dlg_ErrWrProt	;Fehler ausgeben:
			jsr	DoDlgBox		;"Datei schreibgeschützt".

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag
			PopB	r1H			;zurücksetzen.
			PopB	r1L

			lda	sysDBData		;Auf Schreibschutz testen.
			cmp	#YES			;Schreibschutz ignorieren?
			beq	:no_error		; => Ja, Datei löschen.

			cmp	#NO			;Schreibschutz akzeptieren?
			bne	:cancel			; => Nein, weiter...

			lda	#$ff
			sta	dirNotEmpty		;Verzeichnis-Inhalte nicht löschen.

::skip_file		ldx	#$7f			;Rückmeldung: "Nicht löschen".
			rts

::cancel		ldx	WM_WCODE
			ldy	WIN_DRIVE,x
			lda	RealDrvMode -8,y
			and	#SET_MODE_SUBDIR	;Native-Mode Laufwerk?
			beq	:1			; => Nein, weiter...

			lda	curDirHead +32		;Verzeichnis als "Aktuell" für
			sta	WIN_SDIR_T,x		;Fenster setzen. Nach Rückkehr
			lda	curDirHead +33		;zu GeoDesk zeigt das Fenster
			sta	WIN_SDIR_S,x		;die schreibgeschützte Datei an.

::1			ldx	#$ff			;Rückmeldung: "Abbruch".
			rts

::no_error		ldx	#NO_ERROR		;Rückmeldung: "Löschen".
			rts

;*** Variablen.
:dirNotEmpty		b $00				;Datei schreibgeschützt.
							;Eltern-Verzeichnis nicht löschen.

;*** Fehler: Datei ist Schreibgeschützt.
:Dlg_ErrWrProt		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w curFileName
			b DBTXTSTR   ,$0c,$40
			w :4
			b NO         ,$01,$50
			b CANCEL     ,$11,$50
			b YES        ,$09,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Die Datei ist schreibgeschützt!",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Schreibschutz ignorieren?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "The file is write protected!",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Ignore write protection?",NULL
endif
