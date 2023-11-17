; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** V361: Dateien löschen / umbenennen.
;    r14 : Zeiger auf Titelzeile.
:SlctFiles		ldx	r14L
			stx	V361e2 +0
			ldx	r14H
			stx	V361e2 +1

			ldx	#$00			;Diskette einlegen.
			b $2c
:SlctFiles_a		ldx	#$ff
			lda	curDrive		;Laufwerk aktivieren.
			jsr	InsertDisk
			cmp	#$01
			beq	L361a0
			lda	#$ff
			rts

;*** DOS-Diskettennamen einlesen.
:L361a0			jsr	DOS_GetSys		;DOS-Verzeichnis einlesen.
			jsr	DOS_GetDskNam		;Diskettennamen einlesen.
			jsr	ClrBox			;Infofenster löschen.

;*** Dateien in Speicher einlesen.
:L361a1			lda	#$00
			sta	V361a0			;Hauptverzeichnis einlesen.
			sta	V361b0			;Zeiger auf Anfang Verzeichnis.

			jsr	i_FillRam
			w	16*256,FileNTab
			b	$00
			jsr	i_FillRam
			w	9 *256,FileDTab
			b	$00

;*** Dateien einlesen und auswerten.
:L361a2			jsr	L361b2			;Verzeichnisse & Dateien einlesen.

;*** Datei-Auswahl-Box.
:L361a3			MoveB	Seite,V361b3+0		;Aktuelle Sektorwerte merken.
			MoveB	Spur,V361b3+1
			MoveB	Sektor,V361b3+2
			MoveW	a8,V361b8

			MoveB	V361a1,V361e1

			lda	#<V361e0
			ldx	#>V361e0
			jsr	SelectBox

			lda	r13L
			beq	:102
			cmp	#$01
			beq	:103
			cmp	#$02
			beq	:101
			cmp	#$80
			bne	:105
			jmp	SlctFiles_a

::101			lda	#$ff
			rts

::102			jsr	L361b0			;Unterverzeichnis öffnen.
			jmp	L361a2			;Dateien einlesen.

::103			lda	V361c0			;Weiterblättern. Ende erricht ?
			bne	:104			;Ja, Zurück zum Anfang...
			LoadB	V361b0,$ff
			jmp	L361a2			;Directory weiterlesen.

::104			LoadB	V361b0,$00
			jmp	L361a2			;Zum Directory-Anfang zurück.

::105			lda	#$00			;Dateien ausgewählt.
			rts				;Zurück zum Programm.

;*** SubDir auswählen.
:L361b0			ldy	#$0f
			lda	(r15L),y		;Zeiger auf Datei-Daten
			jsr	SetPosEntry		;berechnen.

			ldy	#$04			;Ist Cluster = 0 ?
			lda	(r0L),y
			bne	L361b1
			iny
			lda	(r0L),y
			bne	L361b1			;Nein -> SubDir.
			sta	V361a0			;Ja, Zurück zum Hauptverzeichnis.
			sta	V361b0
			sta	V361b2+0
			sta	V361b2+1
			rts

:L361b1			ldy	#$04			;Cluster-Nr. als Startadresse für.
			lda	(r0L),y			;Unterverzeichnis setzen.
			sta	V361b2+0
			iny
			lda	(r0L),y
			sta	V361b2+1
			LoadB	V361a0,1		;Sub-Directory
			ClrB	V361b0			;Dateien aus SubDir lesen.
			rts

;*** SubDirectorys einlesen.
:L361b2			lda	#$00
			sta	V361a1			;Zähler Directorys auf NULL.
			sta	V361a2			;Zähler Dateien auf NULL.
			sta	V361a3			;Zähler Einträge auf NULL.

			LoadW	a6,FileDTab		;Zeiger auf Daten-Tabelle.
			LoadW	a7,FileNTab		;Zeiger auf Datei-Tabelle.

			jsr	DoInfoBox		;Info-Box.
			PrintStrgDB_RdSDir
			lda	#%00010000		;Directory-Einträge in Tabelle
			ldy	#$00			;kopieren.
			jsr	L361b3
			cmp	#$00
			bne	:102
			jsr	ClrBox

::101			jsr	DoInfoBox		;Info-Box.
			PrintStrgDB_RdFile
			LoadB	V361b0,$7f		;Zeiger zurück auf Verzeichnis-Anfang.
			lda	#%00000000		;Datei-Einträge in Tabelle
			ldy	#$01			;kopieren.
			jsr	L361b3
			jsr	ClrBox
::102			rts

;*** Dateien & Directorys einlesen.
:L361b3			sta	:101 +1			;Eintrags-Typ (SubDir/Datei) merken.
			sty	:102 +1
			jsr	ResetDir
			jmp	:104			;Alle Einträge aus Sektor gelesen ?

::101			lda	#%00000000		;Eintrag auf SubDir/Datei testen.
			jsr	L361c0
			cmp	#$00			;$00 = Verzeichnis-Ende ?
			beq	:105			;Ja, Ende...
			cmp	#$ff			;$FF = Ungültiger Eintrag ?
			beq	:103			;Ja, überspringen...

::102			ldx	#$ff			;Eintrag in Tabelle kopieren.
			jsr	L361c1
			jsr	L361b4			;Zeiger auf nächsten Eintrag.
			cmp	#$00			;$00 = Noch Platz in Tabelle ?
			beq	:104			;Ja, weiter...

			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a7L),y
			lda	#$ff			;Speicher voll.
			rts				;Ende.

::103			jsr	L361b4			;Zeiger auf nächsten Eintrag.

::104			CmpBI	V361b7,16		;Alle Einträge aus Sektor gelesen ?
			bne	:101			;Nein, weiter...

			ClrB	V361b7			;Zähler für Sektor-Einträge löschen.
			jsr	GetNxDirSek		;Nächsten Directory-Sektor lesen.
			cpx	#$00			;lesen.
			beq	:101

::105			LoadB	V361c0,$ff		;Verzeichnis-Ende erreicht, Abbruch.
			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a7L),y
			rts				;Ende...

;*** Zeiger auf nächsten Sektor-Eintrag.
:L361b4			pha
			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V361b7			;Eintrag.
			pla
			rts

;*** Datei-Namen testen.
:L361c0			sta	:102 +1			;Datei-Maske merken.

			ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			bne	:101
			rts				;Ja, Ende.

::101			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			beq	:104			;Ja, Datei ignorieren.

			ldy	#$0b
			lda	(a8L),y			;Datei-Maske einlesen.
			and	#%00010000		;Hat Datei gewünschtes
::102			cmp	#%00000000		;Dateiformat ?
			bne	:104			;Nein, Datei ignorieren.
			cmp	#%00010000		;Verzeichnis ?
			beq	:103			;Ja, Kein "Cluster = $0000"-Test.

			ldy	#$1a			;Cluster = 0 ?
			lda	(a8L),y			;Ja, keine gültige Datei.
			bne	:103
			iny
			lda	(a8L),y
			beq	:104

::103			lda	#$7f			;Gültiger Eintrag.
			rts
::104			lda	#$ff			;Ungültiger Eintrag.
			rts

;*** Dateiname in Tabelle übertragen.
:L361c1			inc	V361a1,x		;Zähler (SubDir/Datei) erhöhen.

			lda	#" "			;Trennzeichen für Verzeichnisse.
			cpx	#$00
			beq	:101
			lda	#"."			;Trennzeichen für Dateien.
::101			sta	:107 +1			;Zeichen zwischen "NAME" + "EXT"

			lda	#$00			;Zeiger initialisieren.
			sta	:102 +1
			sta	:106 +1

::102			ldy	#$00			;Datei-Name in Speicher kopieren und
			lda	(a8L),y			;in GEOS-Format konvertieren.
			cmp	#" "
			bcs	:104			;Code < $20 ? Nein, weiter.
::103			lda	#"_"			;Zeichen durch "_"-Code ersetzen.
			bne	:105
::104			cmp	#$7f			;Code > $7F ? Ja, ungültig.
			bcs	:103
::105			inc	:102 +1			;Zeiger auf nächstes Zeichen.
::106			ldy	#$00
			sta	(a7L),y			;Zeichen in Speicher kopieren.
			inc	:106 +1			;Zeiger auf nächstes Zeichen.
::107			lda	#"."			;Trennung zwischen "NAME" + "EXT"
			cpy	#$07			;einfügen.
			beq	:106
			cpy	#$0b
			bne	:102

			lda	#$00
::108			iny				;Dateinamen auf 16 Zeichen
			sta	(a7L),y			;mit $00-Bytes auffüllen.
			cpy	#$0f
			bne	:108

			lda	V361a3			;Nr. des Eintrags in Datei-Tabelle.
			sta	(a7L),y			;(als Zeiger auf Daten-Tabelle).

			ldx	#$00
			lda	#$16			;Daten des Eintrags in Daten-Tabelle.
::109			pha				;Uhrzeit, Datum, Erster Cluster und
			tay				;Datei-Größe.
			lda	(a8L),y
			pha
			txa
			tay
			pla
			sta	(a6L),y
			inx
			pla
			add	$01
			cmp	#$1f
			bne	:109

			AddVBW	 9,a6			;Zeiger auf Tabelle korrigieren.
			AddVBW	16,a7

			inc	V361a3			;Zähler für Anzahl Einträge +1.
			CmpBI	V361a3,255		;Tabelle voll ?
			beq	:110			;Ja, Ende...
			lda	#$00			;Nein, weiter...
			rts
::110			lda	#$ff
			rts

;*** Zeiger auf Eintrag positionieren.
:SetPosEntry		sta	r0L			;Zeiger auf Datei in Daten-Tabelle
			LoadB	r1L,9			;berechnen.
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			AddVW	FileDTab,r0
			rts
;*** Datei-Eintrag suchen.
;    r10 zeigt auf Suchdateiname.
:LookDOSfile		ClrB	V361b0			;Zeiger auf Anfang Verzeichnis.
			jsr	ResetDir

:L361d1			CmpBI	V361b7,16		;Alle Einträge des Sektors durchsucht ?
			bne	L361d2			;Nein, weiter...

			ClrB	V361b7			;Nächsten Sektor lesen.
			jsr	GetNxDirSek
			cpx	#$00
			beq	L361d2

			lda	#$ff			;Datei nicht gefunden.
			rts

;*** Dateiparameter prüfen.
:L361d2			ldy	#$00
			lda	(a8L),y
			bne	L361d3

			lda	#$ff			;Datei nicht gefunden.
			rts

;*** Name in Puffer kopieren und in GEOS-Formt wandeln.
:L361d3			ldy	#$00
			ldx	#$00			;Dateiname in Speicher kopieren und
::101			lda	(a8L),y			;in GEOS-Format konvertieren.
			jsr	ConvertChar
::102			iny
::103			sta	DOSNamBuf1,x		;Zeichen in Speicher kopieren.
			inx
			lda	#"."			;Trennung zwischen "NAME" + "EXT"
			cpx	#8			;einfügen.
			beq	:103
			cpx	#12
			bne	:101

			ldy	#11			;Aktuellen Eintrag mit Suchdatei
::104			lda	DOSNamBuf1,y		;vergleichen.
			cmp	(r10L),y
			bne	L361d4
			dey
			bpl	:104

			lda	#$00			;Datei gefunden.
			rts

;*** Zeiger auf nächste Datei
:L361d4			jsr	L361b4			;Nächsten Eintrag vergleichen.
			jmp	L361d1

;*** Directory initialisieren.
:ResetDir		ldy	V361b0			;Verzeichnis-Startwerte ermitteln ?
			bne	:104			;Nein, weiter...

			ldy	V361a0			;Zeiger auf Anfang Hauptverzeichnis ?
			bne	:101			;Nein, Zeiger auf Unterverzeichnis...

			jsr	DefMdr			;Zeiger auf Beginn Hauptverzeichnis.
			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			lda	MdrSektor +0
			sta	V361a4    +0
			lda	MdrSektor +1
			sta	V361a4    +1
			jmp	:102

::101			lda	V361b2+0		;Zeiger auf Beginn Unterverzeichnis.
			ldx	V361b2+1
			sta	V361b4+0
			stx	V361b4+1
			jsr	Clu_Sek

::102			lda	Seite			;Startposition merken.
			sta	V361b1+0
			sta	V361b3+0
			lda	Spur
			sta	V361b1+1
			sta	V361b3+1
			lda	Sektor
			sta	V361b1+2
			sta	V361b3+2

			MoveB	V361a4,V361b5
			MoveB	SpClu ,V361b6

			lda	#$00
			sta	V361b7			;Zähler Dateien auf 0.
			sta	V361c0			;Verzeichnis-Anfang markieren.
			lda	#<Disk_Sek
			sta	a8L
			sta	V361b8+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V361b8+1
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:103
			jmp	L361e1			;Directory-Position speichern.
::103			jmp	DiskError		;Disketten-Fehler.

::104			cpy	#$7f			;Zeiger auf Anfang Verzeichnis zurück ?
			bne	:105			;Nein, weiterlesen.

			jsr	L361e0			;Directory-Zeiger wieder setzen.
			MoveB	V361b3+0,Seite
			MoveB	V361b3+1,Spur
			MoveB	V361b3+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:106			;Disketten-Fehler.
			MoveW	V361b8,a8
			ClrB	V361c0			;Directory-Ende nicht erreicht.
			rts				;Ende.

::105			jsr	L361e1			;Directory weiterlesen.
			MoveB	V361b3+0,Seite
			MoveB	V361b3+1,Spur
			MoveB	V361b3+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:106			;Disketten-Fehler.
			MoveW	V361b8,a8
			rts

::106			jmp	DiskError		;Disketten-Fehler.

;*** Zeiger auf aktuelle Directory-Position wieder herstellen.
:L361e0			ldy	#$09
::101			lda	V361b9,y
			sta	V361b3,y
			dey
			bpl	:101
			rts

;*** Zeiger auf aktuelle Directory-Position sichern.
:L361e1			ldy	#$09
::101			lda	V361b3,y
			sta	V361b9,y
			dey
			bpl	:101
			rts

;*** Nächsten Sektor lesen.
:GetNxDirSek		lda	V361c0			;Directory-Ende ?
			bne	:101			;Ja, Ende...

			lda	V361a0			;Hauptverzeichnis ?
			bne	L361f0			;Nein, weiter...

			CmpBI	V361b5,1		;Alle Sektoren
			beq	:101			;gelesen ?

			dec	V361b5			;Ja, Ende...
			jsr	Inc_Sek			;Zeiger auf nächsten Sektor richten.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:102

			ldx	#$00			;OK...
			b	$2c
::101			ldx	#$ff			;Directory-Ende...
			stx	V361c0
			rts

::102			jmp	DiskError

;*** Nächster Sektor aus Unterverzeichnis.
:L361f0			CmpBI	V361b6,1		;Alle Sektoren
			beq	:102			;gelesen ?

			dec	V361b6			;Alle Sektoren eines Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im Cluster lesen.
			LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			jsr	D_Read
			txa
			beq	:101
			jmp	DiskError

::101			rts

::102			lda	V361b4+0		;Nächsten Cluster lesen.
			ldx	V361b4+1
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr. merken.
			ldx	r1H
			sta	V361b4+0
			stx	V361b4+1

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
			MoveB	SpClu,V361b6		;Zähler setzen.
			ldx	#$00
::102			stx	V361c0
			rts				;Ende...

::103			jmp	DiskError

;*** Speicher für Dateiname.
:DOSNamBuf1		s 17				;Zwischenspeicher Dateiname.

;*** Variablen und Texte.
:V361a0			b $00				;Directory-Typ.
:V361a1			b $00				;Anzahl Directorys.
:V361a2			b $00				;Anzahl Dateien.
:V361a3			b $00				;Anzahl Einträge.
:V361a4			w $0000				;Anzahl Sektoren im Hauptverzeichnis

;*** Variablen: Lesen des Directory.
:V361b0			b $00				;$00 = Ersten Dir-Sektor ermitteln.
							;$7F = Startwerte auf ersten Directory-Sektor.
							;$FF = Directory weiterlesen.
:V361b1			s $03				;Startadresse Directory (Sektor)
:V361b2			w $0000				;       "               (Cluster)

:V361b3			s $03				;Zeiger auf aktuellen Verzeichnis-Sektor.
:V361b4			w $0000				;Zeiger auf aktuellen Verzeichnis-Cluster.
:V361b5			b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V361b6			b $00				;Zeiger auf Sektor-Nr. in Cluster.
:V361b7			b $00				;Zähler Einträge in Sektor.
:V361b8			w $0000				;Zeiger auf Anfang Eintrag in Sektor.

:V361b9			s $03				;Startadresse aktive Datei-Tabelle (Sektor)
:V361b10		w $0000				;       "                          (Cluster)
:V361b11		b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V361b12		b $00				;Zwischenspeicher: Zeiger auf Sektor in Cluster.
:V361b13		b $00				;Zwischenspeicher: Zähler Einträge in Sektor.
:V361b14		w $0000				;Zwischenspeicher: Zeiger auf Eintrag in Sektor.

:V361c0			b $00				;$FF = Directory-Ende.

;*** Dialognox.
:V361e0			b $80
			b $00
			b $ff
			b $0c
:V361e1			b $00
:V361e2			w Titel_File
			w FileNTab
