; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Daten für Source-Laufwerk einlesen.
:GetSrcDrvData		ldx	winSource		;Nr. Source-Fenster einlesen.

			ldy	WIN_DRIVE,x		;Laufwerksadresse für Fenster
			sty	sysSource		;einlesen und speichern.

			lda	WIN_REALTYPE,x		;Laufwerkstyp einlesen und
			sta	SourceType		;speichern.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen und
			sta	SourceMode		;speichern.

			lda	WIN_PART,x		;Partition für Fenster
			sta	sysSource +1		;einlesen und speichern.
			lda	WIN_SDIR_T,x		;Unterverzeichnis für Fenster
			sta	sysSource +2		;einlesen und speichern.
			ldy	WIN_SDIR_S,x
			sty	sysSource +3

			sta	SourceSDirOrig +0	;Aktuelles Verzeichnis für
			sty	SourceSDirOrig +1	;SubDir-Copy speichern.

			rts

;*** Daten für Target-Laufwerk einlesen.
:GetTgtDrvData		ldx	winTarget		;Nr. Target-Fenster einlesen.

			ldy	WIN_DRIVE,x		;Laufwerksadresse für Fenster
			sty	sysTarget		;einlesen und speichern.

			lda	WIN_REALTYPE,x		;Laufwerkstyp einlesen und
			sta	TargetType		;speichern.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen und
			sta	TargetMode		;speichern.

			lda	WIN_PART,x		;Partition für Fenster
			sta	sysTarget +1		;einlesen und speichern.
			lda	WIN_SDIR_T,x		;Unterverzeichnis für Fenster
			sta	sysTarget +2		;einlesen und speichern.
			ldy	WIN_SDIR_S,x
			sty	sysTarget +3

			sta	TargetSDirOrig +0	;Aktuelles Verzeichnis für
			sty	TargetSDirOrig +1	;SubDir-Copy speichern.

			rts

;*** Source-Laufwerk öffnen.
;-Laufwerk aktivieren.
;-Partition öffnen.
;-Native-Verzeichnis öffnen.
;-Bei Nicht-CMD/-Native-Laufwerk:
; Diskette öffnen/BAM einlesen.
;-Partition/Verzeichnis für das
; aktuelle Laufwerk speichern.
:OpenSourceDrive	lda	sysSource		;Source-Laufwerk einlesen.
			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			sta	flagOpenDisk		;Flag löschen: "Disk öffnen".

::open_part		lda	sysSource +1		;CMD-Partition definiert?
			beq	:open_sdir		; => Nein, weiter...

			ldx	curDrive		;Ist Partition auf Laufwerk
			cmp	activePart -8,x		;noch aktiv?
			beq	:open_sdir		; => Ja, weiter...
			sta	activePart -8,x		;Neue Partition für Laufwerk.

			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			dec	flagOpenDisk		;Flag setzen "Disk geöffnet".

			ldx	curDrive		;Bei Partitionswechsel immer das
			lda	#$00			;richtige Verzeichnis aktivieren.
			sta	activeNDirTr -8,x
			sta	activeNDirSe -8,x

::open_sdir		lda	sysSource +2		;Native-Verzeichnis definiert?
			beq	:open_disk		; => Nein, weiter...

			ldx	curDrive		;Ist Verzeichnis auf Laufwerk
			cmp	activeNDirTr -8,x	;noch aktiv?
			bne	:1			; => Nein, Verzeichnis öffnen...
			lda	sysSource +3
			cmp	activeNDirSe -8,x
			beq	:open_disk		; => Ja, weiter...

::1			lda	sysSource +2		;Zeiger auf Verzeichnis einlesen
			sta	r1L			;und für ":OpenSubDir" setzen.
			ldy	sysSource +3
			sty	r1H

			ldx	curDrive		;Neues Verzeichnis für Laufwerk.
			sta	activeNDirTr -8,x
			tya
			sta	activeNDirSe -8,x

			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			dec	flagOpenDisk		;Flag setzen "Disk geöffnet".

::open_disk		bit	flagOpenDisk		;Disk geöffnet?
			bmi	:no_error		; => Ja, Ende...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

::no_error		ldx	#NO_ERROR
::error			rts

;*** Target-Laufwerk öffnen.
;-Laufwerk aktivieren.
;-Partition öffnen.
;-Native-Verzeichnis öffnen.
;-Bei Nicht-CMD/-Native-Laufwerk:
; Diskette öffnen/BAM einlesen.
;-Partition/Verzeichnis für das
; aktuelle Laufwerk speichern.
:OpenTargetDrive	lda	sysTarget		;Target-Laufwerk einlesen.
			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			sta	flagOpenDisk		;Flag löschen: "Disk öffnen".

::open_part		lda	sysTarget +1		;CMD-Partition definiert?
			beq	:open_sdir		; => Nein, weiter...

			ldx	curDrive		;Ist Partition auf Laufwerk
			cmp	activePart -8,x		;noch aktiv?
			beq	:open_sdir		; => Ja, weiter...
			sta	activePart -8,x		;Neue Partition für Laufwerk.

			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			dec	flagOpenDisk		;Flag setzen "Disk geöffnet".

			ldx	curDrive		;Bei Partitionswechsel immer das
			lda	#$00			;richtige Verzeichnis aktivieren.
			sta	activeNDirTr -8,x
			sta	activeNDirSe -8,x

::open_sdir		lda	sysTarget +2		;Native-Verzeichnis definiert?
			beq	:open_disk		; => Nein, weiter...

			ldx	curDrive		;Ist Verzeichnis auf Laufwerk
			cmp	activeNDirTr -8,x	;noch aktiv?
			bne	:1			; => Nein, Verzeichnis öffnen...
			lda	sysTarget +3
			cmp	activeNDirSe -8,x
			beq	:open_disk		; => Ja, weiter...

::1			lda	sysTarget +2		;Zeiger auf Verzeichnis einlesen
			sta	r1L			;und für ":OpenSubDir" setzen.
			ldy	sysTarget +3
			sty	r1H

			ldx	curDrive		;Neues Verzeichnis für Laufwerk.
			sta	activeNDirTr -8,x
			tya
			sta	activeNDirSe -8,x

			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			dec	flagOpenDisk		;Flag setzen "Disk geöffnet".

::open_disk		bit	flagOpenDisk		;Disk geöffnet?
			bmi	:no_error		; => Ja, Ende...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

::no_error		ldx	#NO_ERROR
::error			rts

;*** Kopiermodus ermitteln.
;1) Duplizieren: XREG=$00
;Wenn SourceDrv = TargetDrv, dann
;werden die Dateien dupliziert, egal
;ob verschiedene Fenster.
;2) Kopieren: XREG<>$00
;Nur wenn Laufwerk/Partition gleich,
;aber SubDir verschieden, dann werden
;die Datei-Einträge direkt in das
;andere Verzeichnis verschoben, wenn
;Verschieben statt kopieren aktiv.
:testCopyMode		ClrB	flagMoveDirEntry	;Dateien in Verzeichnis kopieren.

			ldx	#INCOMPATIBLE		;Vorgabe: Kopieren.

			ldy	#$00			;Quell-/Ziel-Laufwerk vergleichen.
::1			lda	sysSource,y
			cmp	sysTarget,y		;Laufwerke gleich?
			bne	:2			; => Nein, Abbruch...
			iny
			cpy	#$04
			bcc	:1
			bcs	:duplicate		;Quelle=Ziel, duplizieren.

::2			lda	SourceMode		;Source-Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;Native-Mode-Laufwerk?
			beq	:copy			; => Nein, weiter...

			cpy	#$02			;Nur Verzeichnis unterschiedlich?
			bcc	:copy			; => Nein, kopieren...

			dec	flagMoveDirEntry	;Modus "Kopieren" zwischen
							;NativeMode-Verzeichnissen.
			b $2c				;Modus: Kopieren.
::duplicate		ldx	#NO_ERROR		;Modus: Duplizieren.
::copy			stx	flagDuplicate		;Kopiermodus speichern.
			rts

;*** Partition/Verzeichnisse für Laufwerk A: bis D:
:activePart		b $00,$00,$00,$00
:activeNDirTr		b $00,$00,$00,$00
:activeNDirSe		b $00,$00,$00,$00

;*** Quell-Laufwerk.
:SourceType		b $00
:SourceMode		b $00
:SourceSDirOrig		b $00,$00

;*** Ziel-Laufwerk.
:TargetType		b $00
:TargetMode		b $00
:TargetSDirOrig		b $00,$00

;*** Flag für "Disk geöffnet".
;OpenPartition und OpenSubDir öffnen
;die aktuelle Diskette bereits.
;Ist dieses Flag gesetzt, dann wird
;OpenDisk übersprungen.
:flagOpenDisk		b $00
