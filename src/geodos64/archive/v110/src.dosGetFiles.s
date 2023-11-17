; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L501: Dateien löschen / umbenennen.
:DOS_GetFiles		ldy	#27
			lda	Action_Drv
			add	$39
			sta	(r14L),y
			MoveW	r14,V501d0

			ldx	#$03
::1			lda	r10L,x
			sta	V501d1,x
			dex
			bpl	:1

			lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive
			lda	curDrive		;Diskette einlegen.
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01
			beq	:2
			lda	#$ff
			rts

::2			jsr	DoInfoBox
			PrintStrgV501f0
			jsr	GetBSek			;Boot-Sektor lesen.
			jsr	Load_FAT		;FAT einlesen.
			jsr	ClrBox

;*** Dateien in Speicher einlesen.
:GetDOSfiles		lda	#$00
			sta	V501a0			;Hauptverzeichnis einlesen.
			sta	V501b0			;Zeiger auf Anfang Verzeichnis.
			LoadW	r0,25*256
			MoveW	V501d1,r1
			jsr	ClearRam		;Speicher für Daten löschen.

;*** Dateien einlesen und auswerten.
:GetNxDOSfiles		jsr	ReadDOSfiles		;Einträge einlesen.
			jsr	ClrBox			;Infobox löschen.

			lda	V501a3			;Anzahl Dateien = 0 ?
			bne	ShowDlgBox		;Dateien anzeigen.
			jmp	NoDOSfiles

;*** Datei-Auswahl-Box.
:ShowDlgBox		MoveB	Seite,V501b3+0		;Aktuelle Sektorwerte merken.
			MoveB	Spur,V501b3+1
			MoveB	Sektor,V501b3+2
			MoveW	a8,V501b8

			MoveW	V501d0,r14		;Dateien wählen.
			MoveW	V501d1,r15
			lda	#$ff
			ldx	#$0c
			ldy	V501a1
			jsr	DoScrTab

			ldy	sysDBData		;Ergebiss prüfen.
			cpy	#$01			;"Abbruch" ?
			beq	:2			;Ja, Ende...
::1			lda	#$ff
			rts

::2			cmp	#$00			;Einzel-Auswahl ?
			bne	:3			;Nein, weiter...
			jsr	SlctSubDir		;Unterverzeichnis öffnen.
			jmp	GetNxDOSfiles		;Dateien einlesen.

::3			cpx	#$00			;Dateien ausgewählt ?
			bne	:5			;Ja, Ende.

			lda	V501c0			;Weiterblättern. Ende erricht ?
			bne	:4			;Ja, Zurück zum Anfang...
			LoadB	V501b0,$ff
			jmp	GetNxDOSfiles		;Directory weiterlesen.

::4			LoadB	V501b0,$00
			jmp	GetNxDOSfiles		;Zum Directory-Anfang zurück.

::5			lda	#$00			;Dateien ausgewählt.
			rts				;Zurück zum Programm.

;*** SubDir auswählen.
:SlctSubDir		ldy	#$0f
			lda	(r15L),y		;Zeiger auf Datei-Daten
			jsr	SetPosEntry		;berechnen.

			ldy	#$04			;Ist Cluster = 0 ?
			lda	(r0L),y
			bne	:1
			iny
			lda	(r0L),y
			bne	:1			;Nein -> SubDir.
			sta	V501a0			;Ja, Zurück zum Hauptverzeichnis.
			sta	V501b0
			rts

::1			ldy	#$04			;Cluster-Nr. als Startadresse für.
			lda	(r0L),y			;Unterverzeichnis setzen.
			sta	V501b2+0
			iny
			lda	(r0L),y
			sta	V501b2+1
			LoadB	V501a0,1		;Sub-Directory
			ClrB	V501b0			;Dateien aus SubDir lesen.
			rts

;*** SubDirectorys einlesen.
:ReadDOSfiles		jsr	DoInfoBox		;Info-Box.
			PrintStrgV501f1

			lda	#$00
			sta	V501a1			;Zähler Directorys auf NULL.
			sta	V501a2			;Zähler Dateien auf NULL.
			sta	V501a3			;Zähler Einträge auf NULL.

			MoveW	V501d2,a6		;Zeiger auf Daten-Tabelle.
			MoveW	V501d1,a7		;Zeiger auf Datei-Tabelle.

			lda	#%00010000		;Directory-Einträge in Tabelle
			ldy	#$00			;kopieren.
			jsr	RdNxDOSentry
			cmp	#$00
			bne	:1

			jsr	ClrBoxText
			PrintStrgV501f2

			LoadB	V501b0,$7f		;Zeiger zurück auf Verzeichnis-Anfang.
			lda	#%00000000		;Datei-Einträge in Tabelle
			ldy	#$01			;kopieren.
			jsr	RdNxDOSentry
::1			rts

;*** Dateien & Directorys einlesen.
:RdNxDOSentry		sta	:1 +1			;Eintrags-Typ (SubDir/Datei) merken.
			sty	:2 +1

			jsr	ResetDir
			jmp	:4			;Alle Einträge aus Sektor gelesen ?

::1			lda	#%00000000		;Eintrag auf SubDir/Datei testen.
			jsr	TestDOSentry
			cmp	#$00			;$00 = Verzeichnis-Ende ?
			beq	:5			;Ja, Ende...

			cmp	#$ff			;$FF = Ungültiger Eintrag ?
			beq	:3			;Ja, überspringen...

::2			ldx	#$ff			;Eintrag in Tabelle kopieren.
			jsr	CopyName
			jsr	NxSekEntry		;Zeiger auf nächsten Eintrag.
			cmp	#$00			;$00 = Noch Platz in Tabelle ?
			beq	:4			;Ja, weiter...

			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a7L),y
			lda	#$ff			;Speicher voll.
			rts				;Ende.

::3			jsr	NxSekEntry		;Zeiger auf nächsten Eintrag.

::4			CmpBI	V501b7,16		;Alle Einträge aus Sektor gelesen ?
			bne	:1			;Nein, weiter...

			ClrB	V501b7			;Zähler für Sektor-Einträge löschen.
			jsr	GetNxDirSek		;Nächsten Directory-Sektor lesen.
			cpx	#$00			;lesen.
			beq	:1

::5			LoadB	V501c0,$ff		;Verzeichnis-Ende erreicht, Abbruch.

			lda	#$00			;Tabellen-Ende markieren.
			tay
			sta	(a7L),y
			rts				;Ende...

;*** Zeiger auf nächsten Sektor-Eintrag.
:NxSekEntry		pha
			AddVBW	32,a8			;Zeiger auf nächsten
			inc	V501b7			;Eintrag.
			pla
			rts

;*** Datei-Namen testen.
:TestDOSentry		sta	:2 +1			;Datei-Maske merken.

			ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			bne	:1
			rts				;Ja, Ende.

::1			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			beq	:4			;Ja, Datei ignorieren.

			ldy	#$0b
			lda	(a8L),y			;Datei-Maske einlesen.
			and	#%00010000		;Hat Datei gewünschtes
::2			cmp	#%00000000		;Dateiformat ?
			bne	:4			;Nein, Datei ignorieren.
			cmp	#%00010000		;Verzeichnis ?
			beq	:3			;Ja, Kein "Cluster = $0000"-Test.

			ldy	#$1a			;Cluster = 0 ?
			lda	(a8L),y			;Ja, keine gültige Datei.
			bne	:3
			iny
			lda	(a8L),y
			beq	:4

::3			lda	#$7f			;Gültiger Eintrag.
			rts
::4			lda	#$ff			;Ungültiger Eintrag.
			rts

;*** Dateiname in Tabelle übertragen.
:CopyName		inc	V501a1,x		;Zähler (SubDir/Datei) erhöhen.

			lda	#" "			;Trennzeichen für Verzeichnisse.
			cpx	#$00
			beq	:0
			lda	#"."			;Trennzeichen für Dateien.
::0			sta	:6 +1			;Zeichen zwischen "NAME" + "EXT"

			lda	#$00			;Zeiger initialisieren.
			sta	:1 +1
			sta	:5 +1

::1			ldy	#$00			;Datei-Name in Speicher kopieren und
			lda	(a8L),y			;in GEOS-Format konvertieren.
			cmp	#" "
			bcs	:3			;Code < $20 ? Nein, weiter.
::2			lda	#"_"			;Zeichen durch "_"-Code ersetzen.
			bne	:4
::3			cmp	#$7f			;Code > $7F ? Ja, ungültig.
			bcs	:2
::4			inc	:1 +1			;Zeiger auf nächstes Zeichen.
::5			ldy	#$00
			sta	(a7L),y			;Zeichen in Speicher kopieren.
			inc	:5 +1			;Zeiger auf nächstes Zeichen.
::6			lda	#"."			;Trennung zwischen "NAME" + "EXT"
			cpy	#$07			;einfügen.
			beq	:5
			cpy	#$0b
			bne	:1

			lda	#$00
::7			iny				;Dateinamen auf 16 Zeichen
			sta	(a7L),y			;mit $00-Bytes auffüllen.
			cpy	#$0f
			bne	:7

			lda	V501a3			;Nr. des Eintrags in Datei-Tabelle.
			sta	(a7L),y			;(als Zeiger auf Daten-Tabelle).

			ldx	#$00
			lda	#$16			;Daten des Eintrags in Daten-Tabelle.
::8			pha				;Uhrzeit, Datum, Erster Cluster und
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
			bne	:8

			AddVBW	 9,a6			;Zeiger auf Tabelle korrigieren.
			AddVBW	16,a7

			inc	V501a3			;Zähler für Anzahl Einträge +1.
			CmpBI	V501a3,255		;Tabelle voll ?
			beq	:9			;Ja, Ende...

			lda	#$00			;Nein, weiter...
			rts

::9			lda	#$ff
			rts

;*** Zeiger auf Eintrag positionieren.
:SetPosEntry		sta	r0L			;Zeiger auf Datei in Daten-Tabelle
			LoadB	r1L,9			;berechnen.
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult
			AddW	V501d2,r0
			rts

;*** Keine DOS-Dateien.
:NoDOSfiles		LoadW	r0,V501e0		;Fehler: "Keine Dateien..."
			ClrDlgBoxCSet_Grau
			lda	#$ff
			rts				;Rücksprung zum Programm..

;*** Directory initialisieren.
:ResetDir		ldy	V501b0			;Verzeichnis-Startwerte ermitteln ?
			bne	:3			;Nein, weiter...

			ldy	V501a0			;Zeiger auf Anfang Hauptverzeichnis ?
			bne	:1			;Nein, Zeiger auf Unterverzeichnis...

			jsr	DefMdr			;Zeiger auf Beginn Hauptverzeichnis.
			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			lda	MdrSektor +0
			sta	V501a4    +0
			lda	MdrSektor +1
			sta	V501a4    +1
			jmp	:2

::1			lda	V501b2+0		;Zeiger auf Beginn Unterverzeichnis.
			ldx	V501b2+1
			sta	V501b4+0
			stx	V501b4+1
			jsr	Clu_Sek

::2			lda	Seite			;Startposition merken.
			sta	V501b1+0
			sta	V501b3+0
			lda	Spur
			sta	V501b1+1
			sta	V501b3+1
			lda	Sektor
			sta	V501b1+2
			sta	V501b3+2

			MoveB	V501a4,V501b5
			MoveB	SpClu ,V501b6

			lda	#$00
			sta	V501b7			;Zähler Dateien auf 0.
			sta	V501c0			;Verzeichnis-Anfang markieren.
			lda	#<Disk_Sek
			sta	a8L
			sta	V501b8+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V501b8+1
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:2a
			jmp	SaveDirPos		;Directory-Position speichern.
::2a			jmp	DiskError		;Disketten-Fehler.

::3			cpy	#$7f			;Zeiger auf Anfang Verzeichnis zurück ?
			bne	:4			;Nein, weiterlesen.

			jsr	LoadDirPos		;Directory-Zeiger wieder setzen.
			MoveB	V501b3+0,Seite
			MoveB	V501b3+1,Spur
			MoveB	V501b3+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:5			;Disketten-Fehler.
			MoveW	V501b8,a8
			ClrB	V501c0			;Directory-Ende nicht erreicht.
			rts				;Ende.

::4			jsr	SaveDirPos		;Directory weiterlesen.
			MoveB	V501b3+0,Seite
			MoveB	V501b3+1,Spur
			MoveB	V501b3+2,Sektor
			LoadW	a8,Disk_Sek
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:5			;Disketten-Fehler.
			MoveW	V501b8,a8
			rts

::5			jmp	DiskError		;Disketten-Fehler.

;*** Zeiger auf aktuelle Directory-Position wieder herstellen.
:LoadDirPos		ldy	#$09
::1			lda	V501b9,y
			sta	V501b3,y
			dey
			bpl	:1
			rts

;*** Zeiger auf aktuelle Directory-Position sichern.
:SaveDirPos		ldy	#$09
::1			lda	V501b3,y
			sta	V501b9,y
			dey
			bpl	:1
			rts

;*** Nächsten Sektor lesen.
:GetNxDirSek		LoadW	a8,Disk_Sek		;Zeiger auf Speicher.
			lda	V501c0			;Directory-Ende ?
			bne	:1			;Ja, Ende...

			lda	V501a0			;Hauptverzeichnis ?
			bne	NxSDirSek		;Nein, weiter...

			CmpBI	V501b5,1		;Alle Sektoren
			beq	:1			;gelesen ?

			dec	V501b5			;Ja, Ende...
			jsr	Inc_Sek			;Zeiger auf nächsten Sektor richten.
			jsr	D_Read			;Sektor lesen.
			txa
			bne	:2

			ldx	#$00			;OK...
			b	$2c
::1			ldx	#$ff			;Directory-Ende...
			stx	V501c0
			rts

::2			jmp	DiskError

;*** Nächster Sektor aus Unterverzeichnis.
:NxSDirSek		CmpBI	V501b6,1		;Alle Sektoren
			beq	:2			;gelesen ?

			dec	V501b6			;Alle Sektoren eines Clusters gelesen ?

			jsr	Inc_Sek			;Nächsten Sektor im Cluster lesen.
			jsr	D_Read
			txa
			beq	:1
			jmp	DiskError

::1			rts

::2			lda	V501b4+0		;Nächsten Cluster lesen.
			ldx	V501b4+1
			jsr	Get_Clu
			lda	r1L			;Neue Cluster-Nr. merken.
			ldx	r1H
			sta	V501b4+0
			stx	V501b4+1

;*** Cluster Einlesen.
:GetSDirClu		ldy	FAT_Typ
			bne	:1

			cmp	#$f8			;FAT12. Dir-Ende ?
			bcc	:2			;Nein, weiter...
			cpx	#$0f
			bcc	:2
			ldx	#$ff
			bne	:3			;Ja, Ende...

::1			cmp	#$f8			;FAT16. Dir-Ende ?
			bcc	:2			;Nein, weiter...
			cpx	#$ff
			bne	:2
			ldx	#$ff
			bne	:3			;Ja, Ende...

::2			jsr	Clu_Sek			;Cluster berechnen.
			jsr	D_Read			;Ersten Sektor lesen.
			txa
			bne	:4
			MoveB	SpClu,V501b6		;Zähler setzen.
			ldx	#$00
::3			stx	V501c0
			rts				;Ende...

::4			jmp	DiskError

;*** Variablen und Texte.
:V501a0			b $00				;Directory-Typ.
:V501a1			b $00				;Anzahl Directorys.
:V501a2			b $00				;Anzahl Dateien.
:V501a3			b $00				;Anzahl Einträge.
:V501a4			w $0000				;Anzahl Sektoren im Hauptverzeichnis

;*** Variablen: Lesen des Directory.
:V501b0			b $00				;$00 = Ersten Dir-Sektor ermitteln.
							;$7F = Startwerte auf ersten Directory-Sektor.
							;$FF = Directory weiterlesen.
:V501b1			s $03				;Startadresse Directory (Sektor)
:V501b2			w $0000				;       "               (Cluster)

:V501b3			s $03				;Zeiger auf aktuellen Verzeichnis-Sektor.
:V501b4			w $0000				;Zeiger auf aktuellen Verzeichnis-Cluster.
:V501b5			b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V501b6			b $00				;Zeiger auf Sektor-Nr. in Cluster.
:V501b7			b $00				;Zähler Einträge in Sektor.
:V501b8			w $0000				;Zeiger auf Anfang Eintrag in Sektor.

:V501b9			s $03				;Startadresse aktive Datei-Tabelle (Sektor)
:V501b10		w $0000				;       "                          (Cluster)
:V501b11		b $00				;Zeiger auf Sektor-Nr. im Hauptverzeichnis.
:V501b12		b $00				;Zwischenspeicher: Zeiger auf Sektor in Cluster.
:V501b13		b $00				;Zwischenspeicher: Zähler Einträge in Sektor.
:V501b14		w $0000				;Zwischenspeicher: Zeiger auf Eintrag in Sektor.

:V501c0			b $00				;$FF = Directory-Ende.

;*** Variablen.
:V501d0			w $0000				;Titel.
:V501d1			w $0000				;Startadresse Datei-Tabelle.
:V501d2			w $0000				;Startadresse Daten-Tabelle.

;*** Fehler: "Keine Dateien auf Disk!"
:V501e0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V501e1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V501e2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V501e1			b PLAINTEXT,BOLDON
			b "Keine Dateien auf",NULL
:V501e2			b "Diskette !",PLAINTEXT,NULL

;*** Info: "Disketten-Daten werden eingelesen..."
:V501f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Disketten-Daten"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL

;*** Info: "Suche weitere Unterverzeichnisse..."
:V501f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Suche weitere"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Unterverzeichnisse..."
			b NULL

;*** Info: "Suche Dateien..."
:V501f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Suche Dateien..."
			b NULL
