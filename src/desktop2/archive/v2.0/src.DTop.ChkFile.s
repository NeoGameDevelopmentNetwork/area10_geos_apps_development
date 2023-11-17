; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Überprüfen ob Ziel-Datei bereits existiert.
:checkFileExist		sta	flagRemoveEntry

			lda	a5L			;Zeiger auf Dateiname
			clc				;in aktuellem
			adc	#< $0003		;Verzeichniseintrag.
			sta	r0L
			lda	a5H
			adc	#> $0003
			sta	r0H

			lda	#> buf_TempStr1
			sta	r1H
			lda	#< buf_TempStr1
			sta	r1L

			ldx	#r0L			;Dateiname für
			ldy	#r1L			;Quell-Datei.
			jsr	copyNameA0_16

			jsr	r6_buf_TempStr2

			ldx	#r0L			;Dateiname für
			ldy	#r6L			;Ziel-Datei.
			jsr	copyNameA0_16

			jsr	FindFile		;Ziel-Datei suchen.
			cpx	#FILE_NOT_FOUND
			beq	:done			; => OK, weiter...
			jsr	exitOnDiskErr

			jsr	GetDirHead		;BAM einlesen.

;--- Kein überschreiben auf System-/Programmdisketten.
			lda	GEOS_DISK_TYPE
			beq	:1			; => Arbeitsdiskette.
			jmp	doErrNotAllowed

::1			lda	flagRemoveEntry
			beq	:askreplace		; => File exist...

			lda	#> dirEntryBuf
			sta	r6H
			lda	#< dirEntryBuf
			sta	r6L
			jsr	getDEntryCurBlk
			txa
			beq	:fail

			lda	#$00
			sta	flagRemoveEntry
			beq	:askreplace

;--- Keine Verzeichnis-Datei.
::fail			jsr	findBIconEntry
			cpx	#$ff			;Datei auf Border?
			beq	:2			; => Nein, weiter...

;--- Border-Icon muss manuell gelöscht werden.
			jsr	r5_bufTempStr2

			ldx	#> dbox_DelTarget
			lda	#< dbox_DelTarget
			jsr	openDlgBox		;Datei man. löschen.

			ldx	#CANCEL_ERR
			bne	:err			; => Abbruch...

;--- Ziel-Datei überschreiben?
::2			sta	flagRemoveEntry
::askreplace		jsr	r5_bufTempStr2

			ldx	#> dbox_ReplaceFile
			lda	#< dbox_ReplaceFile
			jsr	openDlgBox		;Datei überschreiben?
			ldx	#CANCEL_ERR
			cmp	#NO			;Nein?
			beq	:err			; => Dann Abbruch...

			jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			lda	#> buf_TempStr2
			sta	r0H
			lda	#< buf_TempStr2
			sta	r0L
			jsr	DeleteFile		;Datei löschen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;--- Eintrag aus Speicher löschen...
			lda	flagRemoveEntry
			beq	:skip
			jsr	removeFileEntry

;--- BAM zurück auf Disk schreiben.
::skip			jsr	PutDirHead		;BAM speichern.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

;			...

;--- Name für Quell- und Ziel-Datei übergeben.
::done			lda	#> buf_TempStr1
			sta	vec2FCopyNmSrc +1
			lda	#< buf_TempStr1
			sta	vec2FCopyNmSrc +0

			lda	#> buf_TempStr2
			sta	vec2FCopyNmTgt +1
			lda	#< buf_TempStr2
			sta	vec2FCopyNmTgt +0

			ldx	#NO_ERROR
::err			rts

;*** Border-Icon-Eintrag suchen.
:findBIconEntry		lda	#ICON_BORDER
			sta	r10L

			lda	r7H
			sta	r11H
			lda	r7L
			sta	r11L

::search		lda	r10L
			jsr	isIconGfxInTab
			beq	:next

			lda	r10L
			jsr	chkCIconOpenDkNm
			beq	:next

			ldx	#r1L
			jsr	setVecIcon2File

			ldx	#r1L
			ldy	#r11L
			lda	#30
			jsr	CmpFString
			bne	:next

			lda	r10L
			jmp	getSlctIconEntry

::next			inc	r10L
			lda	r10L
			cmp	#ICON_BORDER +8
			bne	:search

;--- Hinweis:
;Der BRK-Befehl wird nur erreicht wenn
;sich im Border ein ungültiges Icon
;befindet, das auf keinem geöffneten
;Laufwerk vorhanden ist.
;Der Fall sollte nicht eintreten...
			brk				;Panic!

;*** Dialogbox: Datei vorhanden, überschreiben?
:dbox_ReplaceFile	b %10000001
if LANG = LANG_DE
			b DBVARSTR,$10,$10
			b r5L
			b DBTXTSTR,$10,$20
			w txErrFileExist
			b DBTXTSTR,$10,$30
			w txErrReplace1
			b DBTXTSTR,$10,$40
			w txErrReplace3
endif
if LANG = LANG_EN
;--- Hinweis:
;Alternativer Dialogbox-Text...
			b DBTXTSTR,$10,$10
			w txString_A			;"A <name>..."
;			w txSTring_File			;"The file <name>..."
			b DBVARSTR,$1f,$10
;			b DBVARSTR,$42,$10
			b r5L
			b DBTXTSTR,$10,$20
			w txErrReplace1
			b DBTXTSTR,$10,$30
			w txErrReplace3
endif
			b YES     ,$01,$48
			b NO      ,$11,$48
			b NULL

;*** Dialogbox: Datei zuerst auf Zieldisk löschen.
:dbox_DelTarget		b %10000001
			b DBTXTSTR,$10,$10
			w txString_File
if LANG = LANG_DE
			b DBVARSTR,$2e,$10
endif
if LANG = LANG_EN
			b DBVARSTR,$42,$10
endif
			b r5L
			b DBTXTSTR,$10,$20
			w txErrDelTgtFile
			b DBTXTSTR,$10,$30
			w txErrReplace2
			b OK      ,$11,$48
			b NULL
