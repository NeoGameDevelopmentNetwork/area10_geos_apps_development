; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien einlesen
:SlctFiles		MoveW	r14,V453c1

:SlctFiles_a		ldx	#$00
			lda	curDrive
			jsr	InsertDisk
			cmp	#$01
			beq	L453a0
			lda	#$ff			;Keine Dateien gewählt.
			rts				;Abbruch.

;*** Zeiger auf ersten Datei-Eintrag.
:L453a0			jsr	NewOpenDisk		;BAM einlesen.
			txa
			beq	:101
			jmp	DiskError

::101			lda	curDirHead+0		;Ersten Verzeichnis-Sektor speichern.
			sta	V453a0    +0
			sta	V453a1    +0
			lda	curDirHead+1
			sta	V453a0    +1
			sta	V453a1    +1
			lda	#$00
			sta	V453a2
			sta	V453a3

;*** Dateien einlesen..
:L453a1			jsr	L453b0			;Dateien einlesen.

;*** Datei-Auswahl-Box.
:L453a2			MoveB	r1L,V453a1+0		;Verzeichnis-Position merken.
			MoveB	r1H,V453a1+1
			lda	V453a3
			ora	#%01000000
			sta	V453a3

			lda	#<V453c0
			ldx	#>V453c0
			jsr	SelectBox

			lda	r13L
			cmp	#$01
			beq	:102
			cmp	#$02
			beq	:101
			cmp	#$ff
			beq	:104
			cmp	#$90
			bcc	:105
			beq	:106
::101			lda	#$ff			;Keine Dateien gewählt.
			rts				;Abbruch.

::102			bit	V453a3
			bpl	:103
			jmp	L453a0			;Zum Anfang zurück.
::103			jmp	L453a1			;Directory weiterlesen.

::104			lda	#$00			;Dateien gewählt.
			rts				;Ende.

::105			and	#%00000011
			add	8			;Laufwerksaddresse berechnen und
			jsr	NewDrive		;neues Laufwerk aktivieren.
			jmp	SlctFiles_a

::106			jsr	CMD_NewTarget
			jmp	SlctFiles_a

;*** max. 255 Dateien einlesen.
:L453b0			jsr	DoInfoBox
			PrintStrgDB_RdFile

			lda	#$00
			sta	V453a5
			sta	V453a6

			jsr	L453c1			;Zeiger auf Dateitabelle.
			MoveB	V453a1+0,r1L
			MoveB	V453a1+1,r1H

;*** Max. 255 Dateien einlesen.
:L453b1			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor lesen.
			jsr	GetBlock
			txa
			beq	L453b2
			jmp	DiskError		;Disketten-Fehler.
:L453b2			jmp	L453b5			;Einträge prüfen.

:L453b3			lda	V453a2
			inc	V453a2
			jsr	L453c0
			lda	diskBlkBuf+2,x
			and	#%00001111		;Nur SEQ,PRG,USR Dateien auswählen.
			beq	:101
			cmp	#$04
			bcc	L453b4
::101			jmp	L453b5			;Nächsten Eintrag prüfen.

;*** Datei in Tabelle übertragen.
:L453b4			ldy	#$00
::101			lda	diskBlkBuf+5,x
			cmp	#$a0
			bne	:102
			lda	#$00
::102			sta	(r15L),y
			iny
			inx
			cpy	#$10
			bne	:101

			AddVBW	16,r15			;Zeiger auf nächsten Speicherplatz
			inc	V453a5			;für Datei-Einträge.
			lda	V453a5
			cmp	#$ff			;Speicher voll ?
			beq	L453b6			;Ja, Ende...

;*** Zeiger auf nächste Datei.
:L453b5			lda	V453a2			;Folgt weiterer Eintrag im Sektor ?
			cmp	#$08
			beq	:101			;Nein, nächster Sektor.
			jmp	L453b3			;Nächster Eintrag.

::101			ClrB	V453a2
			lda	diskBlkBuf+0		;Folgt weiterer Verzeichnis-Sektor ?
			beq	:102			;Nein, Ende.
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	L453b1			;Nächsten Verzeichnis-Sektor lesen.

::102			lda	V453a3
			ora	#%10000000
			sta	V453a3

;*** Tabellen-Ende markieren.
:L453b6			ldy	#$00
			tya
			sta	(r15L),y		;Tabellen-Ende markieren.
			jmp	ClrBox

;*** Datei-Eintrag auf Disk suchen.
:FindFileOnDsk		jsr	GetDirHead
			lda	curDirHead +0
			sta	r1L
			lda	curDirHead +1
			sta	r1H
			jmp	RdCBMsek

;*** Datei-Eintrag suchen.
:LookCBMfile		lda	V453a0+0		;Zeiger auf Anfang Verzeichnis.
			sta	r1L
			lda	V453a0+1
			sta	r1H

;*** Nächsten Verzeichnis-Sektor lesen.
:RdCBMsek		LoadW	r4,diskBlkBuf		;Directory-Sektor lesen.
			jsr	GetBlock
			txa
			beq	:101
			jmp	DiskError		;Disketten-Fehler.

::101			lda	#$00
::102			pha				;Zeiger auf Eintrag positionieren.
			jsr	L453c0
			lda	diskBlkBuf+2,x		;Eintrag gelöscht ?
			and	#%00000011		;Nur SEQ,PRG,USR Dateien akzeptieren.
			bne	:105			;Nein, weiter...
::103			pla
			add	1			;Zeiger auf nächsten Eintrag.
			cmp	#$08			;Alle Einträge des Sektors geprüft ?
			bne	:102			;Nein, weiter...

			lda	diskBlkBuf+0		;Zeiger auf nächsten Sektor.
			beq	:104
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	RdCBMsek

::104			lda	#$ff			;Datei nicht gefunden.
			rts

::105			ldy	#$00
::106			lda	diskBlkBuf+5,x		;Eintrag mit Suchdatei vergleichen.
			cmp	#$a0
			bne	:107
			lda	#$00
::107			cmp	(r14L),y
			bne	:103
			iny
			inx
			cpy	#$10
			bne	:106

			pla				;Eintrag gefunden.
			jsr	L453c0			;Zeiger auf Eintrag berechnen.
			lda	#$00			;Datei gefunden.
			rts

;*** AKKU x 32 -> xReg.
:L453c0			asl
			asl
			asl
			asl
			asl
			tax
			rts

;*** Zeiger auf Dateinamenspeicher richten.
:L453c1			LoadW	r15,FileNTab
			rts

;*** Variablen.
:V453a0			b $00,$00			;Erster Directory Sektor.
:V453a1			b $00,$00			;Aktueller Directory-Sektor.
:V453a2			b $00				;Zeiger auf Eintrag.
:V453a3			b $00				;$00 = Verzeichnis geht weier...
							;$FF = Directory-Ende.
:V453a4			b $00				;$00 = Hauptverzeichnis.
							;$FF = Unterverzeichnis.
:V453a5			b $00				;Anzahl Dateien.
:V453a6			b $00				;Anzahl Action-Files

:V453c0			b $04
			b $c0
			b $ff
			b $10
			b $00
:V453c1			w $ffff
			w FileNTab
