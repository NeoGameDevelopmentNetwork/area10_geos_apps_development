; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Editor starten.
:OpenEditor		jsr	FindEditor		;GEOS.Editor suchen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			LoadW	a0,dirEntryBuf -2	;Zeiger auf Verzeichnis-Eintrag.
			jmp	StartFile_a0		;Anwendung starten.

::error			jmp	OpenFNamError		;Fehler ausgeben => Desktop.

;*** GEOS.Editor auf Disk suchen.
:FindEditor		lda	bootName +1
			cmp	#"D"
			bne	:MP3
			lda	bootName +7
			cmp	#"V"
			beq	:GD3

::MP3			lda	#<FNameEdit64		;GEOS.Editor.
			ldx	#>FNameEdit64
			bne	:cfg

::GD3			lda	#<FNameGCfg64		;GD.Config.
			ldx	#>FNameGCfg64
;			bne	:cfg

::cfg			sta	r0L			;Name für "GEOS64.Editor".
			stx	r0H

			LoadW	r6,fileName

			ldx	#r0L
			ldy	#r6L
			jsr	CopyString

			lda	#%10000000		;GEOS.Editor auf
			jsr	FindEditFile		;RAM-Laufwerken suchen.
			txa
			beq	:1

			lda	#%00000000		;GEOS.Editor auf
			jsr	FindEditFile		;Disk-Laufwerken suchen.

::1			rts

;*** Datei auf den Laufwerken A: bis D: suchen.
:FindEditFile		sta	:2 +1

;--- Hinweis:
;Die Suche nach einer bestimmten Datei
;wird auch hier vrwendet:
; -105_OpenEditor -> ":FindEditor"
; -105_OpenFile   -> ":FindAppFile"

			ldx	curDrive
			stx	r15L
::1			stx	r15H
			lda	driveType -8,x		;Laufwerk verfügbar?
			beq	:3			; => Nein, weiter...
			and	#%10000000
::2			cmp	#$ff			;Gesuchter Laufwerkstyp?
			bne	:3			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Disk-Fehler?
			bne	:3			; => Ja, weiter...

			LoadW	r6,fileName
			jsr	FindFile		;Editor-Datei-Eintrag suchen.
			txa				;Gefunden?
			beq	:5			; => Ja, Ende...

::3			ldx	r15H			;Zeiger auf nächstes Laufwerk.
			inx
			cpx	#12			;Laufwerk > 11?
			bcc	:6			; => Nein, weiter...
			ldx	#$08			;Auf Laufwerk #8 zurücksetzen.
::6			cpx	r15L			;Alle Laufwerke durchsucht?
			bne	:1			;Auf nächstem Laufwerk weitersuchen.

::4			ldx	#$ff			;Nicht gefunden.

;--- Falls Editor nicht gefunden, Laufwerk zurücksetzen.
::5			txa
			beq	:7
			pha
			lda	r15L 			;Vorheriges Laufwerk wieder
			jsr	SetDevice		;aktivieren.
			pla
			tax
::7			rts

:FNameEdit64		b "GEOS64.Editor",NULL
:FNameGCfg64		b "GD.CONFIG",NULL
