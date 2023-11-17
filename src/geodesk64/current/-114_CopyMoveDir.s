; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Verzeichnis auf Source-/Target-Laufwerk öffnen.
;    Übergabe: dirEntryBuf = Verzeichnis-Eintrag.
;Hinweis:
;Wenn das Verzeichnis auf dem Target-
;Laufwerk nicht existiert, dann wird
;ein neues Verzeichnis erstellt.
;Hinweis #2:
;Wenn Ziel-Laufwerk kein NativeMode-
;Laufwerk ist, dann werden Dateien in
;das Hauptverzeichnis kopiert.
:doOpenDirectory	lda	dirEntryBuf +1		;Tr/Se für neuen Verzeichnis-
			sta	sysSource +2		;Header in Laufwerksdaten speichern.
			lda	dirEntryBuf +2
			sta	sysSource +3

			lda	TargetMode		;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			jsr	OpenTargetDrive		;Target-Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			jsr	checkTargetDir		;Ziel-Verzeichnis überprüfen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

::1			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

::error			rts

;*** Ziel-Verzeichnis überprüfen.
;    Übergabe: dirEntryBuf = 30Byte Verzeichnis-Eintrag.
;Hinweis:
;Ziel-Laufwerk muss aktiv sein.
;Wenn das Verzeichnis nicht existiert,
;dann wird es neu erstellt.
:checkTargetDir		LoadW	r0,dirEntryBuf +3	;Zeiger auf Verzeichnisname.
			LoadW	r1,newDirName		;Zeiger auf Zwischenspeicher.
			ldx	#r0L
			ldy	#r1L
			jsr	SysCopyName		;Name in Zwischenspeicher kopieren.

::1			LoadW	r6,newDirName		;Zeiger auf Verzeichnisname.
			jsr	FindFile		;Verzeichnis auf Disk suchen.
			cpx	#FILE_NOT_FOUND		;Nicht gefunden?
			beq	:2			; => Ja, weiter...
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			bit	GD_REUSE_DIR		;In Verzeichnis kopieren?
			bmi	:3			; => Ja, weiter...

			LoadW	r6,newDirName		;Zeiger auf Verzeichnisname.
			ldx	#$ff			;Neuer Verzeichnisname.
			jsr	GetNewName		;Neuen Namen eingeben.
			txa				;CANCEL?
			bne	:error			; => Ja, Abbruch...

			LoadW	r0,newName		;Zeiger auf Verzeichnisname.
			LoadW	r1,newDirName		;Zeiger auf Zwischenspeicher.
			ldx	#r0L
			ldy	#r1L
			jsr	SysCopyName		;Name in Zwischenspeicher kopieren.
			jmp	:1			;Erneut überprüfen.

::2			jsr	MakeNDir		;Verzeichnis erstellen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			LoadW	r6,newDirName		;Zeiger auf Verzeichnisname.
			jsr	FindFile		;Verzeichnis auf Disk suchen.
			txa				;Gefunden?
			bne	:error			; => Nein, Abbruch...

::3			lda	dirEntryBuf +1		;Zeiger auf Verzeichnis-Header
			sta	sysTarget +2		;einlesen und als aktives
			lda	dirEntryBuf +2		;Verzeichnis für Target-Laufwerk
			sta	sysTarget +3		;speichern.

::error			rts

;*** Variablen.
:newDirName		s 17

;*** Eltern-Verzeichnis auf Source-/Target-Laufwerk öffnen.
;Hinweis:
;r1/r5 dürfen nicht verändert werden.
;(:doCopyDir/:GetNxtDirEntry).
:openParentDir		PushB	r1L			;Zeiger auf Verzeichnis-Eintrag
			PushB	r1H			;zwischenspeichern.
			PushW	r5

			lda	TargetMode		;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			jsr	OpenTargetDrive		;Target-Laufwerk öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	curDirHead +34		;Tr/Se für Eltern-Verzeichnis
			sta	sysTarget +2		;einlesen und in Laufwerksdaten.
			ldx	curDirHead +35		;speichern.
			stx	sysTarget +3

			sta	r1L			;Zeiger auf Eltern-Verzeichnis.
			stx	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- Hinweis:
;Routine wird nur von doCopyDir
;aufgerufen, das Source-Laufwerk muss
;also ein NativeMode-Laufwerk sein.
::1			;lda	SourceMode		;Laufwerksmodus einlesen.
			;and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			;beq	:exit			; => Nein, weiter...

			jsr	OpenSourceDrive		;Source-Laufwerk öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	curDirHead +34		;Tr/Se für Eltern-Verzeichnis
			sta	sysSource +2		;einlesen und in Laufwerksdaten.
			ldx	curDirHead +35		;speichern.
			stx	sysSource +3

			sta	r1L			;Zeiger auf Eltern-Verzeichnis.
			stx	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

::exit			PopW	r5			;Zeiger auf Verzeichnis-Eintrag für
			PopB	r1H			;":GetNxtDirEntry" zurücksetzen.
			PopB	r1L

			rts
