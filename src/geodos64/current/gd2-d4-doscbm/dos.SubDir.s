; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
			t	"src.DOSDRIVE.ext"
endif

			n	"mod.#303.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaDOS

			jmp	DOS_MakeDir
			jmp	DOS_ReMakeDir

			t	"-DOS_SetName"
			t	"-DOS_SlctSubDir"

;*** L303: Unterverzeichnisse löschen.
:DOS_ReMakeDir		lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V303b1
			jsr	SlctSubDir		;Verzeichnisse einlesen.
			tax
			beq	DeleteSDir
::101			jmp	L303ExitGD		;Zurück zu GeoDOS.

;*** Löschen von Verzeichnissen.
:DeleteSDir		lda	V351a0			;Hauptverzeichnis gewählt ?
			bne	:102			;Nein, weiter...

			lda	V351a1			;Unterverzeichnisse vorhanden ?
			bne	:101

			DB_OK	V303g0			;Fehler: "Keine weiteren
			jmp	L303ExitGD		;        "Unterverzeichnisse !"

::101			DB_OK	V303f0			;Fehler: "Hauptverzeichnis kann
			jmp	DOS_ReMakeDir		;         nicht gelöscht werden !".

::102			jsr	DoInfoBox		;Info: "Verzeichnisstruktur
			PrintStrgV303e0			;       wird überprüft..."

			lda	V351a1			;Mehr als zwei Unterverzeichnisse ?
			cmp	#$03			;("." & ".."-Verzeichnisse übergehen)
			bcc	:103			;Nein, weiter...

			jsr	ClrBox			;Infobox löschen.
			DB_OK	V303h0			;Fehler: "Bitte zuerst alle Unter-
			jmp	DOS_ReMakeDir		;         verzeichnisse löschen !"

::103			jsr	FindFiles		;Dateien im Verzeichnis ?
			beq	:105			;Nein, weiter...

			jsr	ClrBox			;Infobox löschen.

			DB_UsrBoxV303k0
			CmpBI	sysDBData,3
			beq	:104
			jmp	DOS_ReMakeDir		;Nein, neues Verzeichnis wählen.

::104			jsr	DoInfoBox		;Info: "Dateien werden gelöscht..."
			PrintStrgV303e2
			jsr	DelFiles		;Alle Dateien löschen.

::105			jsr	ClrBoxText		;Info: "Verzeichnis wird gelöscht..."
			PrintStrgV303e3

			ClrB	V351b0			;Zeiger auf Verzeichniskopf
			jsr	ResetDir		;zurücksetzen.

			ldy	#$1a			;Start-Cluster des aktuellen
			lda	(a8L),y			;Verzeichnisses ermitteln.
			sta	V303a3+0
			iny
			lda	(a8L),y
			sta	V303a3+1

			ldy	#$3a			;Zeiger auf "Vaterverzeichnis"
			lda	(a8L),y			;zurücksetzen.
			sta	V351b2+0
			tax
			iny
			lda	(a8L),y
			sta	V351b2+1
			tay				;Cluster-Nr. des "Vaterverzeichnis"
			bne	:106			;= $0000 ? Nein, weiter...
			txa
			bne	:106
			sta	V351a0			;Ja, Hauptverzeichnis aktivieren.

::106			jsr	FindSDirEntry		;Verzeichnis-Eintrag suchen.

			jsr	DoDelDOSfile		;Verzeichnis löschen.

			jsr	ClrBoxText		;Info: "Diskettenverzeichnis wird
			PrintStrgV303e1			;       aktualisiert..."

			jsr	Save_FAT		;FAT speichern.

			jsr	ClrBox			;Infobox löschen.

			jmp	DOS_ReMakeDir		;Neues Verzeichnis wählen.

;*** Dateien im Verzeichnis ?
:FindFiles		ClrB	V351b0			;Zeiger auf Verzeichniskopf
			jsr	ResetDir		;zurücksetzen.

			ClrB	V351a2			;Zählen für Anzahl Dateien löschen.
			AddVBW	32*2,a8			;"." und ".."-Verzeichnisse übergehen.

::101			ldy	#$00
			lda	(a8L),y			;Zeichen aus Datei-Eintrag lesen.
			beq	:103			;$00 = Verzeichnis-Ende.
			cmp	#$e5			;$E5 = Gelöschter Eintrag.
			beq	:102

			inc	V351a2			;Zähler Dateien +1.

::102			AddVBW	32,a8			;Zeiger auf nächsten Eintrag.
			inc	V351b7

			CmpBI	V351b7,16		;Alle Einträge eines Sektors geprüft ?
			bne	:101			;Nein, weiter...

			ClrB	V351b7			;Nächsten Verzeichnis-Sektor lesen.
			jsr	GetNxDirSek
			cpx	#$00			;Verzeichnis-Ende erreicht ?
			beq	:101			;Nein, weiter...

::103			lda	V351a2			;Anzahl Dateien einlesen.
			rts				;Ende...

;*** Dateien im Verzeichnis löschen.
:DelFiles		ClrB	V351b0			;Zeiger auf Verzeichniskopf
			jsr	ResetDir		;zurücksetzen.

::101			ldy	#$00
			lda	(a8L),y			;Zeichen aus Datei-Eintrag lesen.
			beq	:103			;$00 = Verzeichnis-Ende.
			cmp	#$e5			;$E5 = Gelöschter Eintrag.
			beq	:102

			jsr	DoDelDOSfile		;Datei löschen.

::102			AddVBW	32,a8			;Zeiger auf nächsten Eintrag.
			inc	V351b7

			CmpBI	V351b7,16		;Alle Einträge eines Sektors geprüft ?
			bne	:101			;Nein, weiter...

			ClrB	V351b7			;Nächsten Verzeichnis-Sektor lesen.
			jsr	GetNxDirSek
			cpx	#$00			;Verzeichnis-Ende erreicht ?
			beq	:101			;Nein, weiter...

::103			rts

;*** Eintrag suchen.
:FindSDirEntry		ClrB	V351b0			;Zeiger auf Verzeichniskopf
			jsr	ResetDir		;zurücksetzen.

::101			ldy	#$00
			lda	(a8L),y			;Zeichen aus Datei-Eintrag lesen.
			beq	:103			;$00 = Verzeichnis-Ende.
			cmp	#$e5			;$E5 = Gelöschter Eintrag.
			beq	:102

			ldy	#$1a
			lda	(a8L),y			;Cluster-Nr. mit Start-Cluster des
			cmp	V303a3+0		;aktuellen Verzeichnisses vergleichen.
			bne	:102
			iny
			lda	(a8L),y
			cmp	V303a3+1
			bne	:102
			rts				;Verzeichnis-Eintrag gefunden.

::102			AddVBW	32,a8			;Zeiger auf nächsten Eintrag.
			inc	V351b7

			CmpBI	V351b7,16		;Alle Einträge eines Sektors geprüft ?
			bne	:101			;Nein, weiter...

			ClrB	V351b7			;Nächsten Verzeichnis-Sektor lesen.
			jsr	GetNxDirSek
			cpx	#$00			;Verzeichnis-Ende erreicht ?
			beq	:101			;Nein, weiter...

::103			ldx	#$4a
			jmp	DiskError

;*** Einzelne DOS-Datei löschen.
:DoDelDOSfile		ldy	#$00			;Dateiname löschen.
			lda	#$e5
			sta	(a8L),y

			PushW	a8			;Veränderten Dir-Sektor speichern.
			LoadW	a8,Disk_Sek
			jsr	D_Write
			PopW	a8

			ldy	#$1a			;Start-Cluster einlesen.
			lda	(a8L),y
			sta	r1L
			iny
			lda	(a8L),y
			sta	r1H

			ClrW	r4

::101			lda	r1L			;Zeiger auf aktuellen Cluster.
			ldx	r1H
			cmp	#$00
			bne	:102
			cpx	#$00
			beq	:103
::102			jsr	Get_Clu			;Link auf nächsten Cluster lesen.
			PushW	r1			;Link-Wert merken.
			lda	r2L
			ldx	r2H
			jsr	Set_Clu			;Aktuellen Cluster freigeben.
			pla				;Zeiger auf nächsten Cluster.
			sta	r1L
			tay
			pla
			sta	r1H
			and	#%00001111
			cmp	#$0f			;Datei-Ende erreicht ?
			bne	:101			;Nein, nächsten Cluster löschen.
			cpy	#$f8
			bcc	:101

::103			LoadB	BAM_Modify,$ff		;FAT als "verändert" kennzeichnen.
			rts				;Ende.

;*** Ziel-Verzeichnis wählen.
:DOS_MakeDir		lda	Target_Drv
			jsr	NewDrive

			LoadW	r14,V303b0		;Titel-Zeile.
			jsr	SlctSubDir		;Verzeichnisse einlesen.
			tax
			beq	CreateSDir
::101			jmp	L303ExitGD		;Zurück zu GeoDOS.

;*** Anlegen neuer Verzeichnisse.
:CreateSDir		jsr	DoInfoBox		;Info: "Verzeichnisstruktur
			PrintStrgV303e0			;       wird überprüft..."

			jsr	GetFreeClu		;Freien Cluster suchen.

			lda	r2L			;Cluster-Nr. merken.
			sta	V303a0+0
			ldx	r2H
			stx	V303a0+1
			ldy	#<$fff8			;Cluster als belegt kennzeichnen.
			sty	r4L
			ldy	#>$fff8
			sty	r4H
			jsr	Set_Clu

			lda	V303a0+0		;Cluster-Inhalt löschen.
			ldx	V303a0+1
			jsr	ClearClu

			jsr	FreeDirEntry		;Freien Verzeichnis-Eintrag suchen.

			jsr	ClrBox			;Info-Box löschen.

;*** Namen eingeben.
:InputName		jsr	NewDirName		;Neuen Verzeichnisnamen eingeben.
			txa
			beq	SetEntry		;Verzeichnisname übernehmen.
			bmi	:101
			jmp	AskNxDir		;Weiteres Verzeichnis erstellen ?
::101			jmp	UpdateFAT		;Zurück zu GeoDOS.

;*** Eintrag erzeugen.
:SetEntry		jsr	DoInfoBox		;Info: "Verzeichnisstruktur
			PrintStrgV303e0			;       wird überprüft..."

			LoadW	r0,V303c0		;Dateiname ins DOS-Format wandeln.
			LoadW	r1,V303c1
			jsr	ConvNameDOS
			txa
			beq	:101

			jsr	ClrBox			;Infobox löschen.
			DB_OK	V303j0			;Fehler: "Dateiname bereits
							;         vergeben !"
			jmp	InputName		;Neuen Verzeichnisnamen eingeben.

::101			LoadW	r10,V303c1
			jsr	LookDOSfile		;Dateiname im DOS-Verzeichnis suchen.
			tax				;Eintrag gefunden ?
			bne	:102			;Nein, weiter...

			jsr	ClrBox			;Infobox löschen.
			DB_OK	V303i0			;Fehler: "Dateiname bereits
							;         vergeben !"
			jmp	InputName		;Neuen Verzeichnisnamen eingeben.

::102			jsr	ClrBoxText		;Info: "Verzeichnis wird erstellt..."
			PrintStrgV303e4

			jsr	SetGEOSDate		;Datum für Eintrag erzeugen.
			jsr	MakeSubEntry		;Unterverzeichnis-Eintrag erstellen.
			LoadB	BAM_Modify,$ff		;FAT als "verändert" kennzeichnen.

			jsr	ClrBox			;Infobox löschen.

;*** Weitere Verzeichnisse erstellen ?
:AskNxDir		DB_UsrBoxV303l0			;        erstellen ?"

			CmpBI	sysDBData,4
			beq	UpdateFAT		;Nein, zurück zu GeoDOS.
			jmp	CreateSDir		;Weiteres Verzeichnis erstellen.

;*** FAT aktualisieren.
:UpdateFAT		jsr	DoInfoBox		;Info: "Diskettenverzeichnis
			PrintStrgV303e1			;       wird aktualisiert..."

			jsr	Save_FAT		;FAT auf Diskette schreiben.

			jsr	ClrBox			;Infobox löschen.

;*** Zurück zu GeoDOS.
:L303ExitGD		jmp	InitScreen		;Ende.

;*** Verzeichnisnamen in Eingabespeicher löschen.
:ClrNameBuf		lda	#$00
			ldy	#16
::101			sta	V303c0,y
			dey
			bpl	:101
			rts

;*** "." und ".." Eintrag erstellen.
:MakeSubEntry		ldy	#$00
			ldx	#$00
::101			lda	V303c1,y		;Dateiname vom GEOS-Format in
			sta	V303c2,x		;DOS-Format wandeln.
			iny
			inx
			cpy	#$08
			bne	:102
			iny
::102			cpy	#$0c
			bne	:101

			jsr	FreeDirEntry		;Freien Directory-Eintrag suchen.

			LoadW	r14,V303c2		;Verzeichnis-Name.
			MoveW	V303a0,r15		;Start-Cluster.
			jsr	MakeEntry		;Eintrag erzeugen.

			LoadW	a8,Disk_Sek		;Verzeichnis-Sektor schreiben.
			jsr	D_Write
			txa
			beq	:104
::103			jmp	DiskError		;Disketten-Fehler.

::104			lda	V303a0+0		;Ersten Cluster des neuen
			ldx	V303a0+1		;Unterverzeichnisses einlesen.
			jsr	Clu_Sek
			jsr	D_Read
			txa
			bne	:103			;Disketten-Fehler.

			LoadW	r14,V303d0		;"." - Verzeichnis.
			MoveW	V303a0,r15		;Start-Cluster.
			jsr	MakeEntry		;Eintrag erzeugen.
			AddVBW	32,a8
			LoadW	r14,V303d1		;".." - Verzeichnis.
			MoveW	V351b2,r15		;Start-Cluster "Vaterverzeichnis".
			jsr	MakeEntry		;Eintrag erzeugen.

			LoadW	a8,Disk_Sek		;Verzeichnis-Sektor schreiben.
			jsr	D_Write
			txa
			beq	:105
			jmp	DiskError		;Disketten-Fehler.

::105			rts				;Ende.

;*** Verzeichnis-Eintrag erstellen.
:MakeEntry		ldy	#$0a
::101			lda	(r14L),y		;Datei-Namen in Verzeichnis-Eintrag
			sta	(a8L),y			;kopieren.
			dey
			bpl	:101

			ldy	#$0b
			lda	#%00010000		;Datei-Attribut "Unterverzeichnis".
			sta	(a8L),y

			ldx	#$03
			ldy	#$19
::102			lda	V303a2,x		;Datum & Uhrzeit in
			sta	(a8L),y			;Verzeichnis-Eintrag kopieren.
			dey
			dex
			bpl	:102

			ldy	#$1a
			lda	r15L			;Cluster-Nr. in
			sta	(a8L),y			;Verzeichnis-Eintrag kopieren.
			iny
			lda	r15H
			sta	(a8L),y
			iny
			lda	#$00
::103			sta	(a8L),y			;Bytes für Dateigröße löschen.
			iny
			cpy	#$20
			bne	:103

			rts

;*** Verzeichnis-Name eingeben.
:NewDirName		jsr	ClrNameBuf
			LoadW	r0,V303c0
			LoadW	r1,V303c0
			LoadB	r2L,$00
			LoadB	r2H,$ff
			LoadW	r3,V303b2
			jsr	dosSetName
			cmp	#$01
			bne	:101

			lda	V303c0			;Leeres Eingabefeld ?
			beq	:102			;Ja, Name nicht ändern.
			ldx	#$00			;Name ändern.
			rts

::101			cmp	#$02			;CANCEL ?
			bne	:103

::102			ldx	#$7f			;Name nicht ändern.
			rts
::103			ldx	#$ff			;Zurück zu GeoDOS.
			rts

;*** Datum der Dateien auf GEOS-Standard-Zeit setzen.
:SetGEOSDate		lda	hour
			asl
			asl
			asl
			ldx	#$05
::101			asl
			rol	V303a2+0
			rol	V303a2+1
			dex
			bne	:101

			lda	minutes
			asl
			asl
			ldx	#$06
::102			asl
			rol	V303a2+0
			rol	V303a2+1
			dex
			bne	:102

			ldx	#$05
::103			asl	V303a2+0
			rol	V303a2+1
			dex
			bne	:103

			sec
			lda	year
			sbc	#80
			bcs	:104
			adc	#100
::104			asl
			ldx	#$07
::105			asl
			rol	V303a2+2
			rol	V303a2+3
			dex
			bne	:105

			lda	month
			asl
			asl
			asl
			asl
			ldx	#$04
::106			asl
			rol	V303a2+2
			rol	V303a2+3
			dex
			bne	:106

			lda	day
			asl
			asl
			asl
			ldx	#$05
::107			asl
			rol	V303a2+2
			rol	V303a2+3
			dex
			bne	:107

			rts

;*** Suche nach freiem Eintrag im Verzeichnis.
:FreeDirEntry		lda	Target_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive

			ClrB	V351b0			;Zeiger auf Verzeichniskopf
			jsr	ResetDir		;zurücksetzen.
			jmp	L303a1			;Alle Einträge aus Sektor gelesen ?

:L303a0			ldy	#$00			;Ende des Directory
			lda	(a8L),y			;erreicht ?
			beq	:101
			cmp	#$e5			;Code = $E5 = Datei gelöscht ?
			bne	:102			;Ja, ignorieren.
::101			rts				;Freier Eintrag für Unterverzeichnis.

::102			AddVBW	32,a8
			inc	V351b7			;Eintrag.

:L303a1			CmpBI	V351b7,16		;Ende erreicht ?
			bne	L303a0			;Nein, weiter...
			ClrB	V351b7

			jsr	GetNxDirSek		;Directory-Sektor
			cpx	#$00			;lesen.
			beq	L303a0

			lda	V351a0
			bne	L303a2

			ldx	#$49
			jmp	DiskError		;Fehler: "Diskette voll".

;*** Freien Cluster suchen.
:L303a2			jsr	GetFreeClu

			lda	r2L			;Cluster-Nummer merken.
			pha
			sta	r4L
			lda	r2H
			pha
			sta	r4H
			pla				;Zeiger auf neuen Cluster korrigieren.
			tax
			pla
			jsr	Set_Clu

			LoadW	r4,$fff8		;Letzten Cluster kennzeichnen.
			lda	r2L
			ldx	r2H
			jsr	Set_Clu

			lda	r2L			;Cluster löschen.
			ldx	r2H
			jsr	ClearClu

			LoadB	BAM_Modify,$ff		;FAT als "verändert" kennzeichnen.
			jmp	FreeDirEntry		;Freien Eintrag gefunden.

;*** Clusterinhalt löschen.
:ClearClu		sta	V303a1+0
			stx	V303a1+1
			jsr	GetSDirClu

			jsr	i_FillRam		;DOS-Puffer löschen.
			w	512,Disk_Sek
			b	$00

			lda	SpClu			;Neuen Cluster auf Diskette schreiben.
::101			pha
			jsr	D_Write
			txa
			beq	:102
			jmp	DiskError		;Disketten-Fehler.

::102			jsr	Inc_Sek
			pla
			sub	$01
			bne	:101

			lda	V303a1+0
			ldx	V303a1+1
			jsr	Clu_Sek
			jsr	D_Read
			txa
			beq	:103
			jmp	DiskError		;Disketten-Fehler.

::103			rts

;*** Freien Cluster suchen.
:GetFreeClu		LoadW	r2,$0002		;Zeiger auf ersten Cluster.

::101			lda	r2L
			ldx	r2H
			jsr	Get_Clu
			CmpW0	r1			;Ist Cluster frei ?
			beq	:102			;Ja...

			IncWord	r2			;Nein, Zeiger auf nächsten Cluster.
			SubVW	1,FreeClu
			CmpW0	FreeClu			;Alle Cluster belegt ?
			bne	:101			;Nein, weiter...
			ldx	#$49
			jmp	DiskError		;Fehler: "Diskette voll".

::102			rts

;*** Variablen.
:V303a0			w $0000				;Erster Cluster für SubDir.
:V303a1			w $0000				;Zwischenspeicher Cluster-Nummer.
:V303a2			s $04				;Zwischenspeicher Datum & Uhrzeit.
:V303a3			w $0000				;Cluster für zu löschendes Unterverzeichnis.

if Sprache = Deutsch
:V303b0			b PLAINTEXT,"Verzeichnis erstellen",NULL
:V303b1			b PLAINTEXT,"Verzeichnis löschen",NULL
:V303b2			b PLAINTEXT,"Verzeichnisname",NULL
endif

if Sprache = Englisch
:V303b0			b PLAINTEXT,"Create directory",NULL
:V303b1			b PLAINTEXT,"Delete directory",NULL
:V303b2			b PLAINTEXT,"Name of directory",NULL
endif

:V303c0			s 17				;Eingabe Dateiname.
:V303c1			s 17				;Eingabe Dateiname.
:V303c2			s 17				;Verzeichnis-Dateiname.

:V303d0			b ".          "
:V303d1			b "..         "

if Sprache = Deutsch
;*** Texte für Infoboxen.
:V303e0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnisstruktur"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird überprüft..."
			b NULL

:V303e1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Diskettenverzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird aktualisiert..."
			b NULL

:V303e2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Dateien werden"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "gelöscht..."
			b NULL

:V303e3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "gelöscht..."
			b NULL

:V303e4			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "angelegt..."
			b NULL
endif

;*** Texte für Infoboxen.
if Sprache = Englisch
:V303e0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Analyzing"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory-system..."
			b NULL

:V303e1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Update current"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "disk-directory..."
			b NULL

:V303e2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Delete selected"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "files..."
			b NULL

:V303e3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Delete selected"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory..."
			b NULL

:V303e4			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Create selected"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory..."
			b NULL
endif

if Sprache = Deutsch
;*** Fehler: "Hauptverzeichnis kann nicht gelöscht werden!"
:V303f0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Das Hauptverzeichnis kann",NULL
::102			b        "nicht gelöscht werden !",NULL

;*** Fehler: "Diskette hat keine Unterverzeichnisse !"
:V303g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Diese Diskette hat keine",NULL
::102			b        "Unterverzeichnisse!",NULL

;*** Fehler: "Zuerst Verzeichnisse löschen!"
:V303h0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Bitte löschen Sie zuerst",NULL
::102			b        "alle Unterverzeichnisse!",NULL

;*** Fehler: "Datei bereits vorhanden!"
:V303i0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Dieser Dateiname ist",NULL
::102			b        "bereits vergeben !",NULL

;*** Fehler: "Name ungültig!"
:V303j0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Der Verzeichnisname",NULL
::102			b        "ist ungültig !",NULL

;*** Infobox: "Alle Dateien löschen ?"
:V303k0			w V303k1,V303k2,ISet_Frage
			b NO,YES
:V303k1			b BOLDON,"Verzeichnis ist nicht leer!",NULL
:V303k2			b        "Alle Dateien löschen ?",NULL

;*** Infobox: "Weitere Verzeichnisse erstellen ?"
:V303l0			w V303l1,V303l2,ISet_Frage
			b NO,YES
:V303l1			b BOLDON,"Möchten Sie ein weiteres",NULL
:V303l2			b        "Unterverzeichnis erstellen ?",NULL
endif

if Sprache = Englisch
;*** Fehler: "Hauptverzeichnis kann nicht gelöscht werden!"
:V303f0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Root-directory could",NULL
::102			b        "not be deleted!",NULL

;*** Fehler: "Diskette hat keine Unterverzeichnisse !"
:V303g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"No sub-directorys",NULL
::102			b        "found on disk!",NULL

;*** Fehler: "Zuerst Verzeichnisse löschen!"
:V303h0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Please delete sub-",NULL
::102			b        "directorys first!",NULL

;*** Fehler: "Datei bereits vorhanden!"
:V303i0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Selected filename",NULL
::102			b        "already exist !",NULL

;*** Fehler: "Name ungültig!"
:V303j0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Selected directory-",NULL
::102			b        "name is illegal !",NULL

;*** Infobox: "Alle Dateien löschen ?"
:V303k0			w V303k1,V303k2,ISet_Frage
			b NO,YES
:V303k1			b BOLDON,"Directory not empty!",NULL
:V303k2			b        "Delete all files ?",NULL

;*** Infobox: "Weitere Verzeichnisse erstellen ?"
:V303l0			w V303l1,V303l2,ISet_Frage
			b NO,YES
:V303l1			b BOLDON,"Create another",NULL
:V303l2			b        "sub-directory ?",NULL
endif

:EndProgrammCode
