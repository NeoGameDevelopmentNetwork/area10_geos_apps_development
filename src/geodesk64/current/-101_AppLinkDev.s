; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** AppLink-Laufwerk öffnen.
.AL_SET_DEVICE		lda	#$00			;Flag löschen: "Disk öffnen".
			sta	Flag_ALOpenDisk

			ldy	#LINK_DATA_DRIVE	;Laufwerksadresse einlesen.
			lda	(r14L),y
			tax

			ldy	#LINK_DATA_DVTYP
			lda	(r14L),y		;RealDrvType für AppLink einlesen.
			ldy	driveType   -8,x	;Laufwerk verfügbar?
			beq	:1			; => Nein, Suche starten...
			cmp	RealDrvType -8,x	;Passt Laufwerk zu AppLink?
			beq	:OpenAppLPart		; => Ja, weiter...

::1			ldx	#$08			;Passendes Laufwerk suchen.
::2			lda	driveType   -8,x	;Laufwerk verfügbar?
			beq	:3			; => Nein, weiter...
			cmp	RealDrvType -8,x	;Passt Laufwerk zu AppLink?
			beq	:OpenAppLPart		; => Ja, weiter...
::3			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#$0c			;Alle Laufwerke durchsucht?
			bcc	:2			; => Nein, weiter...

;--- AppLink-Laufwerk nicht gefunden.
::error			ldx	#$ff
			rts

;--- CMD-Partitionen.
::OpenAppLPart		txa
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			ldx	curDrive		;CMD-Laufwerk mit Partitionen?
			lda	RealDrvMode -8,x
			and	#SET_MODE_PARTITION
			beq	:OpenAppLSubD		; => Nein, weiter...

			ldy	#LINK_DATA_DPART
			lda	(r14L),y		;Partiton definiert?
			beq	:OpenAppLSubD		; => Nein, weiter...
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...
			dex
			stx	Flag_ALOpenDisk		;Flag setzen "Disk geöffnet".

;--- NativeMode-Unterverzeichnisse.
::OpenAppLSubD		ldx	curDrive		;CMD-Laufwerk mit Verzeichnissen?
			lda	RealDrvMode -8,x
			and	#SET_MODE_SUBDIR
			beq	:OpenStdDisk		; => Nein, weiter...

			ldy	#LINK_DATA_DSDIR
			lda	(r14L),y		;Verzeichnis definiert?
			beq	:OpenStdDisk		; => Nein, weiter...
			sta	r1L
			iny
			lda	(r14L),y
			sta	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...
			dex
			stx	Flag_ALOpenDisk		;Flag setzen "Disk geöffnet".

::OpenStdDisk		ldx	#$00
			bit	Flag_ALOpenDisk		;Diskette bereits geöffnet?
			bmi	:end			; => Ja, Ende...

			jsr	OpenDisk		;GEOS/OpenDisk.
			txa				;Diskettenfehler?
			bne	:error			; => Ja, Abbruch...
::end			rts

;*** Variablen.
:Flag_ALOpenDisk	b $00				;$00 = OpenDisk aufrufen.
							;$FF = OpenDisk nicht nötig.
