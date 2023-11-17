; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien einlesen
:SlctPrnFile		stx	V454a10
			MoveW	r14,V454b1

:SlctPrnFil_a		lda	curDrive
			ldx	#$00			;Diskette einlegen.
			jsr	InsertDisk
			cmp	#$01
			beq	L454a0
			lda	#$ff			;Keine Dateien gewählt.
			rts				;Abbruch.

;*** Zeiger auf ersten Datei-Eintrag.
:L454a0			lda	curDrive
			jsr	NewDrive
			jsr	NewOpenDisk		;BAM einlesen.
			txa
			beq	:101
			jmp	DiskError

::101			lda	curDirHead+0		;Ersten Verzeichnis-Sektor speichern.
			sta	V454a0    +0
			sta	V454a1    +0
			lda	curDirHead+1
			sta	V454a0    +1
			sta	V454a1    +1
			lda	#$00
			sta	V454a2
			sta	V454a3

;*** Dateien einlesen..
:L454a1			jsr	L454b0			;Dateien einlesen.

;*** Datei-Auswahl-Box.
:L454a2			MoveB	r1L,V454a1+0		;Verzeichnis-Position merken.
			MoveB	r1H,V454a1+1
			lda	V454a3
			ora	#%01000000
			sta	V454a3

			lda	#<V454b0
			ldx	#>V454b0
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

::102			bit	V454a3
			bpl	:103
			jmp	L454a0			;Zum Anfang zurück.
::103			jmp	L454a1			;Directory weiterlesen.

::104			lda	#$00			;Dateien gewählt.
			rts				;Ende.

::105			and	#%00000011
			add	8			;Laufwerksaddresse berechnen und
			jsr	NewDrive		;neues Laufwerk aktivieren.
			jmp	SlctPrnFil_a

::106			jsr	CMD_NewTarget
			jmp	SlctPrnFil_a

;*** max. 255 Dateien einlesen.
:L454b0			jsr	DoInfoBox
			PrintStrgDB_RdFile

			lda	#$00
			sta	V454a5
			sta	V454a6

			jsr	L454c1			;Zeiger auf Dateitabelle.
			MoveB	V454a1+0,r1L
			MoveB	V454a1+1,r1H

;*** Max. 255 Dateien einlesen.
:L454b1			LoadW	r4,diskBlkBuf		;Verzeichnis-Sektor lesen.
			jsr	GetBlock
			txa
			beq	L454b2
			jmp	DiskError		;Disketten-Fehler.
:L454b2			jmp	L454b6			;Einträge prüfen.

:L454b3			lda	V454a2
			inc	V454a2
			jsr	L454c0
			lda	diskBlkBuf+2,x
			and	#%00001111		;Nur SEQ,PRG,USR Dateien auswählen.
			beq	L454b4
			cmp	#$04
			bcc	L454b5
:L454b4			jmp	L454b6			;Nächsten Eintrag prüfen.

;*** Datei in Tabelle übertragen.
:L454b5			lda	V454a10
			beq	:102
			bmi	:101

			lda	diskBlkBuf+23,x
			bne	L454b6
			beq	:102

;*** Infoblock der Datei einlesen.
::101			lda	diskBlkBuf+23,x
			beq	L454b6
			lda	diskBlkBuf+24,x
			cmp	#APPL_DATA
			bne	L454b6

			jsr	L454c2
			bne	L454b6

;*** Datei in Speicher übernehmen.
::102			ldy	#$00
::103			lda	diskBlkBuf+5,x
			cmp	#$a0
			bne	:104
			lda	#$00
::104			sta	(r15L),y
			iny
			inx
			cpy	#$10
			bne	:103

			AddVBW	16,r15			;Zeiger auf nächsten Speicherplatz
			inc	V454a5			;für Datei-Einträge.
			lda	V454a5
			cmp	#$ff			;Speicher voll ?
			beq	L454b7			;Ja, Ende...

;*** Zeiger auf nächste Datei.
:L454b6			lda	V454a2			;Folgt weiterer Eintrag im Sektor ?
			cmp	#$08
			beq	:101			;Nein, nächster Sektor.
			jmp	L454b3			;Nächster Eintrag.

::101			ClrB	V454a2
			lda	diskBlkBuf+0		;Folgt weiterer Verzeichnis-Sektor ?
			beq	:102			;Nein, Ende.
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	L454b1			;Nächsten Verzeichnis-Sektor lesen.

::102			lda	V454a3
			ora	#%10000000
			sta	V454a3

;*** Tabellen-Ende markieren.
:L454b7			ldy	#$00
			tya
			sta	(r15L),y		;Tabellen-Ende markieren.
			jmp	ClrBox

;*** Datei-Eintrag auf Disk suchen.
:FindFileOnDsk		jsr	GetDirHead
			MoveW	curDirHead,r1
			jmp	RdCBMsek

;*** Datei-Eintrag suchen.
:LookCBMfile		MoveW	V454a0,r1		;Zeiger auf Anfang Verzeichnis.

;*** Nächsten Verzeichnis-Sektor lesen.
:RdCBMsek		LoadW	r4,diskBlkBuf		;Directory-Sektor lesen.
			jsr	GetBlock
			txa
			beq	:101
			jmp	DiskError		;Disketten-Fehler.

::101			lda	#$00
::102			pha				;Zeiger auf Eintrag positionieren.
			jsr	L454c0
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
			jsr	L454c0			;Zeiger auf Eintrag berechnen.

			lda	#$00			;Datei gefunden.
			rts

;*** AKKU x 32 -> xReg.
:L454c0			asl
			asl
			asl
			asl
			asl
			tax
			rts

;*** Zeiger auf Dateinamenspeicher richten.
:L454c1			LoadW	r15,FileNTab
			rts

;*** Infoblock einlesen.
:L454c2			lda	diskBlkBuf+21,x
			ora	diskBlkBuf+22,x
			beq	:104

			txa
			pha
			PushW	r1

			lda	diskBlkBuf+21,x
			sta	r1L
			lda	diskBlkBuf+22,x
			sta	r1H
			LoadW	r4,fileHeader		;Fileheader einlesen.
			jsr	GetBlock
			txa
			beq	:101
			jmp	DiskError		;Disketten-Fehler.

::101			PopW	r1
			pla
			tax

			ldy	#$00			;Auf GeoWrite-Dokument testen.
::102			lda	V454a11,y
			beq	:103
			cmp	fileHeader+77,y
			bne	:104
			iny
			bne	:102

::103			lda	#$00
			rts
::104			lda	#$ff
			rts

;*** Variablen.
:V454a0			b $00,$00			;Erster Directory Sektor.
:V454a1			b $00,$00			;Aktueller Directory-Sektor.
:V454a2			b $00				;Zeiger auf Eintrag.
:V454a3			b $00				;$00 = Verzeichnis geht weier...
							;$FF = Directory-Ende.
:V454a4			b $00				;$00 = Hauptverzeichnis.
							;$FF = Unterverzeichnis.
:V454a5			b $00				;Anzahl Dateien.
:V454a6			b $00				;Anzahl Action-Files

:V454a10		b $00				;$00 = Alle Dateien.
							;$40 = Nur sequentielle Dateien.
							;$80 = Nur GeoWrite-Dokumente.
:V454a11		b "Write Image ",NULL

:V454b0			b $04
			b $c0
			b $ff
			b $10
			b $00
:V454b1			w $ffff
			w FileNTab
