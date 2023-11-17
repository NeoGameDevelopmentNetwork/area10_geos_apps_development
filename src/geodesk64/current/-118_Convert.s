; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien von/nach CVT konvertieren.
:xCONVERT		jsr	COPY_FILE_NAMES		;Dateinamen in Speicher kopieren.

			ldx	slctFiles		;Dateien ausgewählt?
			bne	:initConvert		; => Nein, Ende...
			jmp	:exit

;--- Zeiger auf erste Datei.
::initConvert		jsr	WM_LOAD_BACKSCR		;Bildschirm zurücksetzen.

			ClrB	statusPos		;Zeiger auf erste Datei.
			jsr	DrawStatusBox		;Status-Box anzeigen.
			jsr	prntDiskInfo		;Disk-/Verzeichnisname ausgeben.

			ldx	curDrive
			lda	RealDrvMode -8,x	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode-Laufwerk?
			beq	:initNxFree		; => Nein, weiter...
			lda	#64			;Suche ab $01/$40 = CMD-Standard.
::initNxFree		sta	NxFreeSek +1
			lda	#1
			sta	NxFreeSek +0

			lda	#< SYS_FNAME_BUF	;Zeiger auf Tabelle mit
			sta	curFileVec +0		;Dateinamen.
			lda	#> SYS_FNAME_BUF
			sta	curFileVec +1

			lda	slctFiles		;Max.Anzahl Dateien für Statusbox.
			sta	statusMax

			sei
			clc				;Mauszeigerposution nicht ändern.
			jsr	StartMouseMode		;Mausabfrage starten.
			cli				;Interrupt zulassen.

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

;--- Dateien konvertieren.
::loop			lda	pressFlag		;Konvertieren abbrechen?
			beq	:1			; => Nein, weiter...
			jmp	:end			; => Ja, Ende...

::1			MoveW	curFileVec,r6
			jsr	FindFile
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	prntStatus		;Verzeichnis/Datei anzeigen.

			lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			and	#%10000000		;Datei geschlossen?
			beq	:next_file		; => Nein, überspringen.

			lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			and	#%01000000		;Datei schreibgeschützt?
			bne	:next_file		; => Ja, überspringen.

			lda	dirEntryBuf +0		;CBM-Dateityp einlesen.
			and	#%00001111		;Dateityp-Bits isolieren.
			cmp	#PRG			;Dateiytp PRG?
			beq	:continue		; => Ja, weiter.
			cmp	#SEQ			;Dateiytp SEQ?
			beq	:continue		; => Ja, weiter.
			cmp	#USR			;Dateiytp USR?
			bne	:next_file		; => Nein, überspringen.

;--- Datei-/Verzeichnis-Name kopieren.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;    Rückgabe: curFileName = Datei-/Verzeichnis-Name.
::continue		LoadW	r10,dirEntryBuf +3
			LoadW	r11,curFileName
			ldx	#r10L
			ldy	#r11L
			jsr	SysCopyName

			jsr	DoConvert1File		;Datei umwandeln.
			txa				;Fehler?
			beq	:next_file		; => Nein, weiter...
			cpx	#$ff			;Falsches Format?
			bne	:error			; => Nein, Fehler, Abbruch...

			LoadW	r0,Dlg_ErrNoCVT		;"Keine CVT/G98-Datei".
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

			lda	sysDBData
			cmp	#YES			;Weiter konvertieren?
			bne	:end			; => Nein, Abbruch...

::next_file		inc	statusPos
			jsr	sysPrntStatus		;Fortschrittsbalken aktualisieren.

			lda	statusPos
			cmp	slctFiles		;Alle Dateien konvertiert?
			beq	:end			; => Ja, Ende...

			AddVBW	17,curFileVec		;Zeiger auf nächste Datei.
			jmp	:loop			;Weiter konvertieren.

;--- Disk-/Laufwerksfehler.
;    Übergabe: XReg = Fehlercode.
::error

;--- Hinweis:
;SUB_STATMSG ruft intern EXEC_MODULE
;auf. Dadurch wird der aktuelle
;Bildschirminhalt gespeichert.
;Nach dem Ende der Hauptroutine wird
;dann WM_LOAD_BACKSCR aufgerufen.
;Daher: Bildschirminhalt zurücksetzen.
;Nur bei "MOD_UPDATE_WIN" erforderlich.
;			txa				;Fehlercode zwischenspeichern.
;			pha
;			jsr	WM_LOAD_BACKSCR		;Bildschirminhalt zurücksetzen.
;			pla
;			tax				;Fehlercode wiederherstellen.

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	PurgeTurbo		;Laufwerksfehler, TurboDOS-Reset.

::end			jsr	SET_LOAD_DISK		;Verzeichnis von Disk neu einlesen.
::exit			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;--- SYS_COPYFNAME:
;slctFiles		b $00
;--- Siehe VLIR-Header:
;SYS_FNAME_BUF		s MAX_DIR_ENTRIES * 17

;*** Aktuelle Datei.
:curFileVec		w $0000				;Zeiger auf aktuelle Datei.
:curFileName		s 17

;*** Fehler: Keine CVT-Datei.
:Dlg_ErrNoCVT		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$2e
			w :3
			b DBTXTSTR   ,$38,$2e
			w curFileName
			b DBTXTSTR   ,$0c,$3c
			w :4
			b DBTXTSTR   ,$0c,$46
			w :5
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "Datei nicht im CVT/G98-Format!",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b "Mit der Konvertierung von weiteren",NULL
::5			b "Dateien fortfahren?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "File not in CVT/G98 format!",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b "Continue converting next files?",NULL
::5			b "",NULL
endif
