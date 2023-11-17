; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** V350: Zielverzeichnis wählen.
;    AKKU: Zeiger auf Laufwerk.
;    r14 : Zeiger auf Titelzeile.
:SlctSubDir		ldx	r14L
			stx	V350e2 +0
			ldx	r14H
			stx	V350e2 +1

			jsr	NewDrive

			ldx	#$00			;Diskette einlegen.
			b $2c
:SlctSubDir_a		ldx	#$ff
			lda	curDrive
			jsr	InsertDisk
			cmp	#$01
			beq	L350a0
			lda	#$ff
			rts

;*** Systemdaten einlesen.
:L350a0			jsr	DOS_GetSys		;DOS-Verzeichnis einlesen.
			jsr	DOS_GetDskNam		;Diskettennamen einlesen.
:L350a1			jsr	ClrBox			;Infofenster löschen.

;*** Dateien in Speicher einlesen.
:L350a2			lda	#$00
			sta	V350a0			;Hauptverzeichnis einlesen.
			sta	V350b0			;Zeiger auf Anfang Verzeichnis.

			jsr	i_FillRam
			w	16*256,FileNTab
			b	$00
			jsr	i_FillRam
			w	2 *256,FileDTab3
			b	$00

;*** Dateien einlesen und auswerten.
:L350a3			jsr	ReadSubDir		;Einträge einlesen.

			lda	V350e1			;Anzahl Dateien = 0 ?
			bne	L350a5			;Dateien anzeigen.
:L350a4			MoveB	V350a0,r0L
			lda	#$00
			rts

;*** Datei-Auswahl-Box.
:L350a5			MoveB	Seite ,V350b3+0		;Aktuelle Sektorwerte merken.
			MoveB	Spur  ,V350b3+1
			MoveB	Sektor,V350b3+2
			MoveW	a8,V350b8

			lda	#<V350e0
			ldx	#>V350e0
			jsr	SelectBox

			lda	r13L
			beq	L350a6
			cmp	#$01
			beq	L350a7
			cmp	#$80
			beq	:101
			lda	#$ff
			rts

::101			jmp	SlctSubDir_a

:L350a6			jsr	L350b0			;Unterverzeichnis öffnen.
			jmp	L350a3			;Dateien einlesen.

:L350a7			MoveB	V350a0,r0L
			MoveW	V350b2,r1
			lda	#$00			;Dateien ausgewählt.
			rts				;Zurück zum Programm.

:L350a8			LoadB	V350b0,$00
			jmp	L350a3			;Zum Directory-Anfang zurück.

;*** SubDir auswählen.
:L350b0			ldx	#$00
			stx	V350a0
			stx	V350b0
			lda	r13H
			asl
			bcc	:101
			inx
::101			clc
			adc	#<FileDTab3
			sta	a6L
			txa
			adc	#>FileDTab3
			sta	a6H

			ldy	#$01			;Ist Cluster = 0 ?
			lda	(a6L),y
			tax
			dey
			lda	(a6L),y
			bne	:103			;Nein -> SubDir.
			cpx	#$00
			bne	:103
			sta	V350b2+0
			sta	V350b2+1
			rts

::103			sta	V350b2+0		;Cluster-Nr. als Startadresse für.
			stx	V350b2+1		;Unterverzeichnis setzen.
			sta	Dir_Entry+$1a
			stx	Dir_Entry+$1b

			MoveB	r13H,r0L
			ClrB	r0H
			ldx	#r0L
			ldy	#$04
			jsr	DShiftLeft
			AddVW	FileNTab,r0

			ldy	#$00
			ldx	#$00
::104			lda	(r0L),y
			bne	:105
			lda	#" "
::105			sta	Dir_Entry,x
			cpy	#$07
			bne	:106
			iny
::106			iny
			inx
			cpx	#$0b
			bne	:104

			dec	V350a0			;Sub-Directory
			rts

;*** SubDirectorys einlesen.
:ReadSubDir		ClrB	V350e1			;Zähler Directorys auf NULL.

			LoadW	a6,FileDTab3		;Zeiger auf Daten-Tabelle.
			LoadW	a7,FileNTab		;Zeiger auf Datei-Tabelle.

			jsr	DoInfoBox		;Info-Box.
			PrintStrgDB_RdSDir

;*** Dateien & Directorys einlesen.
:L350c0			jsr	ResetDir
			jmp	:104			;Alle Einträge aus Sektor gelesen ?

::101			jsr	TestFileName
			cmp	#$00			;$00 = Verzeichnis-Ende ?
			beq	:105			;Ja, Ende...
			cmp	#$ff			;$FF = Ungültiger Eintrag ?
			beq	:103			;Ja, überspringen...

::102			jsr	CopyCurEntry
			jsr	PoiToNxSek		;Zeiger auf nächsten Eintrag.
			cmp	#$00			;$00 = Noch Platz in Tabelle ?
			beq	:104			;Ja, weiter...
			jmp	:106 			;Ende.

::103			jsr	PoiToNxSek		;Zeiger auf nächsten Eintrag.

::104			CmpBI	V350b7,16		;Alle Einträge aus Sektor gelesen ?
			bne	:101			;Nein, weiter...

			ClrB	V350b7			;Zähler für Sektor-Einträge löschen.
			jsr	GetNxDirSek		;Nächsten Directory-Sektor lesen.
			cpx	#$00			;lesen.
			beq	:101

::105			LoadB	V350c0,$ff		;Verzeichnis-Ende erreicht, Abbruch.

::106			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a7L),y

			jmp	ClrBox

;*** Zeiger auf nächsten Sektor-Eintrag.
:PoiToNxSek		pha
			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V350b7			;Eintrag.
			pla
			rts

;*** Datei-Namen testen.
:TestFileName		ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			bne	:101
			rts				;Ja, Ende.

::101			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			beq	:104			;Ja, Datei ignorieren.

			ldy	#$0b
			lda	(a8L),y			;Ist Eintrag = Verzeichnis ?
			and	#%00010000		;Hat Datei gewünschtes
::102			beq	:104			;Nein, Datei ignorieren.

::103			lda	#$7f			;Gültiger Eintrag.
			rts
::104			lda	#$ff			;Ungültiger Eintrag.
			rts

;*** Dateiname in Tabelle übertragen.
:CopyCurEntry		lda	#$00			;Zeiger initialisieren.
			sta	:101 +1
			sta	:105 +1

::101			ldy	#$00			;Datei-Name in Speicher kopieren und
			lda	(a8L),y			;in GEOS-Format konvertieren.
			cmp	#" "
			bcs	:103			;Code < $20 ? Nein, weiter.
::102			lda	#"_"			;Zeichen durch "_"-Code ersetzen.
			bne	:104
::103			cmp	#$7f			;Code > $7F ? Ja, ungültig.
			bcs	:102
::104			inc	:101 +1			;Zeiger auf nächstes Zeichen.
::105			ldy	#$00
			sta	(a7L),y			;Zeichen in Speicher kopieren.
			inc	:105 +1			;Zeiger auf nächstes Zeichen.
::106			lda	#" "			;Trennung zwischen "NAME" + "EXT"
			cpy	#$07			;einfügen.
			beq	:105
			cpy	#$0b
			bne	:101

			lda	#$00
::107			iny				;Dateinamen auf 16 Zeichen
			sta	(a7L),y			;mit $00-Bytes auffüllen.
			cpy	#$10
			bne	:107

			ldy	#$1a			;Ersten Cluster der Datei
			lda	(a8L),y			;einlesen und speichern.
			pha
			iny
			lda	(a8L),y
			ldy	#$01
			sta	(a6L),y
			dey
			pla
			sta	(a6L),y

			AddVBW	 2,a6			;Zeiger auf Tabelle korrigieren.
			AddVBW	16,a7

			inc	V350e1			;Zähler SubDir erhöhen.
			CmpBI	V350e1,255		;Tabelle voll ?
			beq	:108			;Ja, Ende...
			lda	#$00			;Nein, weiter...
			rts
::108			lda	#$ff
			rts

;*** Datei-Eintrag suchen.
;    r10 zeigt auf Suchdateiname.
:LookDOSfile		ClrB	V350b0			;Zeiger auf Anfang Verzeichnis.
			jsr	ResetDir

:L350d0			CmpBI	V350b7,16		;Alle Einträge des Sektors durchsucht ?
			bne	:101			;Nein, weiter...

			ClrB	V350b7			;Nächsten Sektor lesen.
			jsr	GetNxDirSek
			cpx	#$00
			beq	:101

			lda	#$ff			;Datei nicht gefunden.
			rts

;*** Dateiparameter prüfen.
::101			ldy	#$00
			lda	(a8L),y
			bne	:102

			lda	#$ff
			rts

;*** Name in Puffer kopieren und in GEOS-Formt wandeln.
::102			ldy	#$00
			ldx	#$00			;Dateiname in Speicher kopieren und
::103			lda	(a8L),y			;in GEOS-Format konvertieren.
			cmp	#" "
			bcs	:105			;Code < $20 ? Nein, weiter.
::104			lda	#"_"			;Zeichen durch "_"-Code ersetzen.
			bne	:106
::105			cmp	#$7f			;Code > $7F ? Ja, ungültig.
			bcs	:104
::106			iny
::107			sta	DOSNamBuf1,x		;Zeichen in Speicher kopieren.
			inx
			lda	#"."			;Trennung zwischen "NAME" + "EXT"
			cpx	#$08			;einfügen.
			beq	:107
			cpx	#$0c
			bne	:103

			ldy	#$0b			;Aktuellen Eintrag mit Suchdatei
::108			lda	DOSNamBuf1,y		;vergleichen.
			cmp	(r10L),y
			bne	:109
			dey
			bpl	:108

			lda	#$00			;Datei gefunden.
			rts

;*** Zeiger auf nächste Datei
::109			jsr	PoiToNxSek		;Nächsten Eintrag vergleichen.
			jmp	L350d0

;*** Directory initialisieren.
:ResetDir		ldy	V350b0			;Verzeichnis-Startwerte ermitteln ?
			bne	:104			;Nein, weiter...

			bit	V350a0			;Zeiger auf Anfang Hauptverzeichnis ?
			bmi	:101			;Nein, Zeiger auf Unterverzeichnis...

			jsr	DefMdr			;Zeiger auf Beginn Hauptverzeichnis.
			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			lda	MdrSektor +0
			sta	V350a1    +0
			lda	MdrSektor +1
			sta	V350a1    +1
			jmp	:102

::101			lda	V350b2+0		;Zeiger auf Beginn Unterverzeichnis.
			ldx	V350b2+1
			sta	V350b4+0
			stx	V350b4+1
			jsr	Clu_Sek

::102			lda	Seite			;Startposition merken.
			sta	V350b1+0
			sta	V350b3+0
			lda	Spur
			sta	V350b1+1
			sta	V350b3+1
			lda	Sektor
			sta	V350b1+2
			sta	V350b3+2

			MoveB	V350a1,V350b5
			MoveB	SpClu ,V350b6

			lda	#$00
			sta	V350b7			;Zähler Dateien auf 0.
			sta	V350c0			;Verzeichnis-Anfang markieren.
			lda	#<Disk_Sek
			sta	a8L
			sta	V350b8+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V350b8+1
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:103
			jmp	SaveDirPos		;Directory-Position speichern.
::103			jmp	DiskError		;Disketten-Fehler.

::104			cpy	#$7f			;Zeiger auf Anfang Verzeichnis zurück ?
			bne	:105			;Nein, weiterlesen.

			jsr	LoadDirPos		;Directory-Zeiger wieder setzen.
			MoveB	V350b3+0,Seite
			MoveB	V350b3+1,Spur
			MoveB	V350b3+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:106			;Disketten-Fehler.
			MoveW	V350b8,a8
			ClrB	V350c0			;Directory-Ende nicht erreicht.
			rts				;Ende.

::105			jsr	SaveDirPos		;Directory weiterlesen.
			MoveB	V350b3+0,Seite
			MoveB	V350b3+1,Spur
			MoveB	V350b3+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:106			;Disketten-Fehler.
			MoveW	V350b8,a8
			rts

::106			jmp	DiskError		;Disketten-Fehler.

;*** Zeiger auf aktuelle Directory-Position wieder herstellen.
:LoadDirPos		ldy	#$09
::101			lda	V350b9,y
			sta	V350b3,y
			dey
			bpl	:101
			rts

;*** Zeiger auf aktuelle Directory-Position sichern.
:SaveDirPos		ldy	#$09
::101			lda	V350b3,y
			sta	V350b9,y
			dey
			bpl	:101
			rts

;*** Nächsten Sektor lesen.
:GetNxDirSek		lda	V350c0			;Directory-Ende ?
			bne	:101			;Ja, Ende...

			bit	V350a0			;Hauptverzeichnis ?
			bmi	:110			;Nein, weiter...

			CmpBI	V350b5,1		;Alle Sektoren
			beq	:101			;gelesen ?

			dec	V350b5			;Ja, Ende...
			jsr	Inc_Sek			;Zeiger auf nächsten Sektor richten.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:102

			ldx	#$00			;OK...
			b	$2c
::101			ldx	#$ff			;Directory-Ende...
			stx	V350c0
			rts

::102			jmp	DiskError

;*** Nächster Sektor aus Unterverzeichnis.
::110			CmpBI	V350b6,1		;Alle Sektoren
			beq	:112			;gelesen ?

			dec	V350b6			;Alle Sektoren eines Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im Cluster lesen.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jsr	D_Read
			txa
			beq	:111
			jmp	DiskError

::111			rts

::112			lda	V350b4+0		;Nächsten Cluster lesen.
			ldx	V350b4+1
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr. merken.
			ldx	r1H
			sta	V350b4+0
			stx	V350b4+1

;*** Cluster Einlesen.
:GetSDirClu		cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:101			;Nein, weiter...
			cpx	#$0f
			bcc	:101
			ldx	#$ff
			bne	:102			;Ja, Ende...

::101			jsr	Clu_Sek			;Cluster berechnen.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jsr	D_Read			;Ersten Sektor lesen.
			txa
			bne	:103
			MoveB	SpClu,V350b6		;Zähler setzen.
			ldx	#$00
::102			stx	V350c0
			rts				;Ende...

::103			jmp	DiskError

;*** Variablen und Texte.
:DOSNamBuf1		s 17				;Zwischenspeicher Dateiname.

:V350a0			b $00				;Directory-Typ.
:V350a1			w $0000				;Anzahl Sektoren im Hauptverzeichnis

;*** Variablen: Lesen des Directory.
:V350b0			b $00				;$00 = Ersten Dir-Sektor ermitteln.
							;$7F = Startwerte auf ersten Directory-Sektor.
							;$FF = Directory weiterlesen.
:V350b1			s $03				;Startadresse Directory (Sektor)
:V350b2			w $0000				;       "               (Cluster)

:V350b3			s $03				;Zeiger auf aktuellen Verzeichnis-Sektor.
:V350b4			w $0000				;Zeiger auf aktuellen Verzeichnis-Cluster.
:V350b5			b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V350b6			b $00				;Zeiger auf Sektor-Nr. in Cluster.
:V350b7			b $00				;Zähler Einträge in Sektor.
:V350b8			w $0000				;Zeiger auf Anfang Eintrag in Sektor.

:V350b9			s $03				;Startadresse aktive Datei-Tabelle (Sektor)
:V350b10		w $0000				;       "                          (Cluster)
:V350b11		b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V350b12		b $00				;Zwischenspeicher: Zeiger auf Sektor in Cluster.
:V350b13		b $00				;Zwischenspeicher: Zähler Einträge in Sektor.
:V350b14		w $0000				;Zwischenspeicher: Zeiger auf Eintrag in Sektor.

:V350c0			b $00				;$FF = Directory-Ende.

;*** Variablen.
:V350e0			b $80
			b $00
			b $00
			b $0c
:V350e1			b $00
:V350e2			w $ffff
			w FileNTab
