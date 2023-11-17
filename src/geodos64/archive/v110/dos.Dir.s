; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L302: Verzeichnis ausgeben.
:DOS_Dir		MoveW	otherPressVec,VekBuf1

			ldx	#$00
			b $2c
:GetDisk		ldx	#$ff
			lda	curDrive
			jsr	InsertDisk
			cmp	#$01
			beq	:1
			jmp	L302ExitGD

::1			jsr	DoInfoBox		;Infobox aufbauen.
			PrintStrgV302g0

			jsr	GetBSek			;Boot-Sektor lesen.
			jsr	Load_FAT		;FAT einlesen.
			jsr	ReDoBox			;Dialogbox abbauen.

:GetDir			jsr	DOS_GetDskNam		;Disk-Name ermitteln.
			jsr	UseGDFont
			jsr	SetWin			;Disk-Name ausgeben.

:GoRootDir		lda	#$00			;Hauptverzeichnis aktivieren.
			b	$2c
:GoSubDir		lda	#$ff			;Unterverzeichnis aktivieren.
			sta	DirTyp

:Start_Dir		LoadW	otherPressVec,SlctEntry
			jsr	Do1stInit		;Initialisieren.
			jsr	PrnSDirNam

:ShowNxFiles		jsr	NextPage
			ClrB	RAM_Modify

:DoDirIcons		Display	ST_WR_FORE
			LoadW	r0,icon_Tab1		;Icons aufbauen.
			jsr	DoIcons
			StartMouse
			NoMseKey
			rts

;*** Zurück zu geoDOS.
:L302ExitGD		jsr	ClrWin
			jmp	SetMenu

;*** Anderes Laufwerk.
:L302ExitDrv		jsr	ClrWin
			jmp	m_DOS_Dir +3

;*** Directory-Zähler löschen.
:ClrDirCount		lda	#$00
			sta	UsedByte+0		;Anzahl Bytes in Directory löschen.
			sta	UsedByte+1
			sta	UsedByte+2
			sta	UsedByte+3
			sta	DirFiles+0		;Anzahl Files in Directory löschen.
			sta	DirFiles+1
			rts

;*** Dateigrößen addieren.
:AddBlocks_a		ldy	#$0b			;Prüfen ob Eintrag = Datei.
			lda	(a7L),y
			and	#%00001000
			beq	:2
::1			rts				;Keine Datei.

::2			lda	(a7L),y
			and	#%00010000
			bne	:1

			ldy	#$1a			;Prüfen ob Start-Cluster = 0.
			lda	(a7L),y
			bne	:3			;Nein, Gültige Datei.
			iny
			lda	(a7L),y
			beq	:1			;Ja, Keine Datei.

::3			ldy	#$1c			;Datei-Größe aus aktuellem
							;Directory-Eintrag im RAM holen.
			lda	(a7L),y			;Datei-Größe Low-Byte.
			pha
			iny
			lda	(a7L),y			;Datei-Größe Middle-Byte.
			tax
			iny
			lda	(a7L),y			;Datei-Größe High-Byte.
			tay
			pla

:AddBlocks_b		clc				;Datei-Größe zum Gesamtzähler
			adc	UsedByte+0		;belegter Bytes addieren.
			sta	UsedByte+0
			txa
			adc	UsedByte+1
			sta	UsedByte+1
			tya
			adc	UsedByte+2
			sta	UsedByte+2

:IncFiles		IncWord	DirFiles		;Anzahl Einträge im Directory +1.
			rts

;*** Anzahl freier Cluster berechnen.
:CalcFreeClu		jsr	InitForBA		;Anzahl freier Sektoren berechnen.
			jsr	Max_Free
			jsr	DoneWithBA

			LoadW	a1,FAT			;Zeiger auf FAT bereitstellen.
			lda	#$00
			sta	CountClu+0		;Zähler Cluster Initialisieren.
			sta	CountClu+1
			sta	CountFreeClu+0		;Zähler freie Cluster Initialisieren.
			sta	CountFreeClu+1

::1			clc				;Zeiger auf Cluster in FAT setzen und
			lda	CountClu		;Zeiger einlesen.
			adc	#$02
			tay
			lda	CountClu+1
			adc	#$00
			tax
			tya
			jsr	Get_Clu
			CmpW0	r1
			bne	:2

			IncWord	CountFreeClu		;Anzahl freie Cluster um 1 erhöhen.
::2			IncWord	CountClu		;Zähler +1 bis alle Cluster geprüft.
			CmpW	CountClu,Free_Clu
			bne	:1
			rts

;*** Directory-Fenster aufbauen.
:SetWin			Display	ST_WR_BACK
			jsr	ClrWinBitMap

			Display	ST_WR_FORE ! ST_WR_BACK

			Pattern	0
			FillRec	40,176,8,303
			lda	#%11111111
			jsr	FrameRectangle

			Pattern	1
			FillRec	177,183, 16,311
			FillRec	 48,183,303,311

			FillRec	 40, 47, 16,302
			SetColRam36,202,$61

			jsr	UseGDFont
			PrintXY	24,46,V302e0
			PrintStrgdosDiskName
			ClrB	currentMode
			rts

;*** Directory-Fenster löschen und
;    ":otherPressVec" wieder herstellen.
:ClrWin			MoveW	VekBuf1,otherPressVec
			Display	ST_WR_FORE ! ST_WR_BACK

;*** Bitmap löschen
:ClrWinBitMap		SetColRam920,40,$b1
			Pattern	2
			FillRec	8,191,0,319
			rts

;*** Directory-Fenster im Vordergrund löschen.
:HideWin		SetColRam36,202,$b1
			Display	ST_WR_FORE
			Pattern	2
			FillRec	40,183,8,311
			rts

;*** Directory-Fenster wieder herstellen.
:ShowWin		SetColRam36,202,$61
			jsr	i_RecoverRectangle
			b	40,183
			w	8,311
			rts

;*** Neue Seite vorbereiten.
:ClrBackWin		Display	ST_WR_BACK
			Pattern	0
			FillRec	48,175,9,302
			jmp	UseGDFont

;*** Zusatzfenster für Datei-Info und Drucken öffnen.
:SetExtraWin		PushW	r0			;Zeiger auf Titel zwischenspeichern.

			MoveW	VekBuf1,otherPressVec
			Display	ST_WR_FORE

			Window	48,167,32,279

			PopW	r0
			LoadW	r11,48
			LoadB	r1H,54
			jmp	PutString

;*** Zusatzfenster für Datei-Info und Drucken löschen.
:ClrExtraWin		SetColRam30,6*40+5,$b1
			Pattern	2
			FillRec	48,175,32,287
			rts

;*** SubDir-Namen in Titelzeile.
:PrnSDirNam		Display	ST_WR_FORE ! ST_WR_BACK
			Pattern	1
			FillRec	40,47,184,303

			lda	DirTyp			;Verzeichnis-Typ testen.
			bne	:1			;Unterverzeichnis ? Ja, weiter...
			rts

::1			jsr	UseGDFont
			LoadW	r11,184			;Cursor setzen.
			LoadB	r1H,46
			LoadB	currentMode,32
			lda	#"."			;Name des Unterverzeichnisses
			jsr	SmallPutChar		;"../name" ausgeben.
			lda	#"."
			jsr	SmallPutChar
			lda	#"/"
			jsr	SmallPutChar
			lda	#$00
::2			pha
			tay
			lda	Dir_Entry,y		;Byte aus Verzeichnis-Eintrag lesen
			TDosNmByt			;Zeichen prüfen und
			jsr	SmallPutChar		;ausgeben.
			pla
			cmp	#$07
			bne	:3
			pha
			AddVBW	8,r11
			pla
::3			add	$01
			cmp	#$0b
			bne	:2
			rts

;*** Zeiger auf Directory-Anfang.
:Do1stInit		jsr	ClrDirCount		;Directory-Zähler löschen.

			lda	#$00
			sta	V302a0
			sta	V302a7
			LoadW	V302a1,Disk_Sek

			lda	DirTyp			;Directory-Modus. Unterverzeichnis ?
			bne	:2			;Ja, weiter...
::1			sta	DirTyp			;Einsprung aus SubDir. Modus
							;"Hauptverzeichnis" setzen. Im Haupt-
							;verzeichnis ohne Funktion.
			jsr	GetMdrSek		;Anzahl Sektoren im Hauptverzeichnis.
			MoveW	MdrSektor,V302a3
			jsr	DefMdr			;Zeiger auf Anfang Hauptverzeichnis.

			jmp	:4

;*** Zeiger auf Unterverzeichnis.
::2			LoadW	a1,FAT			;Zeiger auf FAT.
			ClrB	V302a6			;Nr. des Sektors im Cluster löschen.

			lda	Dir_Entry+26		;Cluster-Nummer lesen.
			sta	V302a4+0
			sta	V302a5+0
			ldx	Dir_Entry+27
			stx	V302a4+1
			stx	V302a5+1
			cmp	#$00			;Cluster = 0 ? Ja,
			bne	:3			;Zeiger auf Hauptverzeichnis.
			cpx	#$00
			beq	:1

::3			jsr	Clu_Sek			;Cluster umrechnen.

::4			MoveB	Seite,V302a2+0		;Adresse des aktuellen Sektors im
			MoveB	Spur,V302a2+1		;Unterverzeichnis merken.
			MoveB	Sektor,V302a2+2
			rts

;*** Aktuellen Directory-Sektor lesen.
:RdCurDirSek		MoveB	V302a2+0,Seite		;Zeiger auf Sektor richten.
			MoveB	V302a2+1,Spur
			MoveB	V302a2+2,Sektor

			LoadW	a8,Disk_Sek		;Zeiger auf Anfang Zwischenspeicher.
			jsr	D_Read			;Sektor lesen.
			txa
			beq	:1
			jmp	DiskError		;Disketten-Fehler.

::1			MoveW	V302a1,a8		;Zeiger auf aktuellen Eintrag.
			rts

;*** Nächsten Verzeichnis-Sektor lesen.
:RdNxDirSek		lda	DirTyp			;Hauptverzeichnis ?
			bne	:2			;Nein, weiter...

			SubVW	1,V302a3		;Zähler Verzeichnis-Sektoren -1.
			CmpW0	V302a3			;Ende erreicht ?
			bne	:1			;Nein, weiter...

			sec				;Directory-Ende erreicht.
			rts

::1			jsr	Inc_Sek			;Zeiger auf nächsten Sektor.
			jmp	:6			;Nächsten Sektor lesen.

;*** Nächsten Sektor eines SubDirs einlesen.
::2			inc	V302a6			;Zeiger auf nächsten Sektor innerhalb
			CmpB	V302a6,SpClu		;des aktuellen Clusters.
			beq	:3			;Kein weiterer Sektor im Cluster -->

			jmp	:1			;Nächsten Sektor des Clusters lesen.

::3			ClrB	V302a6

			lda	V302a5+0		;Aktuelle Cluster-Nr. lesen.
			ldx	V302a5+1
			jsr	Get_Clu			;Zeiger auf nächsten Cluster.

			lda	r1L			;Nr. des neuen Clusters einlesen.
			ldx	r1H

			ldy	FAT_Typ			;Auf letzten Cluster des Unterver-
			bne	:4			;zeichnisses testen.

			cmp	#$f8			;12-Bit-FAT.
			bcc	:5
			cpx	#$0f
			bcc	:5
			sec
			rts

::4			cmp	#$f8			;16-Bit-FAT.
			bcc	:5
			cpx	#$ff
			bne	:5
			sec
			rts

::5			sta	V302a5+0
			stx	V302a5+1
			jsr	Clu_Sek			;Cluster umrechnen.

::6			MoveB	Seite,V302a2+0		;Adresse des aktuellen Sektors merken.
			MoveB	Spur,V302a2+1
			MoveB	Sektor,V302a2+2

			lda	#<Disk_Sek		;Zeiger auf Zwischenspeicher richten.
			sta	a8L
			sta	V302a1+0
			lda	#>Disk_Sek
			sta	a8H
			sta	V302a1+1

			jsr	D_Read			;Sektor lesen.
			txa
			beq	:7
			clc				;Disketteb-Fehler.
			rts

::7			ldx	#$00			;Kein Fehler.
			stx	V302a0			;Zeiger auf ersten Eintrag im Sektor.
			clc
			rts

;*** 16 Einträge ins RAM einlesen.
:ReadFiles		jsr	RdCurDirSek		;Aktuelen Verzeichnis-Sektor lesen.

			LoadW	a7,V302z1		;Zeiger auf Zwischenspeicher.
			ClrB	V302b0			;Anzahl Files im RAM löschen.

::1			CmpBI	V302b0,16		;16 Einträge im Speicher ?
			bne	:2			;Nein, weiter...

			MoveW	a8,V302a1		;Ja, Position innerhalb des Directory-
							;Sektors merken.
			LoadB	V302a7,$00		;Directory-Ende nicht erreicht.
			rts

::2			ldy	#$00			;Byte aus Eintrag lesen.
			lda	(a8L),y			;Byte = $00 ?
			bne	:3			;Nein, weiter.
			LoadB	V302a7,$ff		;Directory-Ende kennzeichnen.
			rts				;Ja, Ende des Directorys.

::3			cmp	#$e5			;Datei gelöscht ?
			bne	:7			;Nein, weiter...
::4			AddVBW	32,a8			;Zeiger auf nächsten Eintrag richten.
			inc	V302a0			;Zähler Einträge/Sektor +1.
			CmpBI	V302a0,16		;16 Einträge geprüft ?
			bne	:1

			jsr	RdNxDirSek		;Nächsten Directory-Sektor lesen.
			bcc	:5			;Weiteren Sektor gefunden ? Ja, weiter.
			LoadB	V302a7,$ff		;Directory-Ende kennzeichnen.
			rts				;Ende.

::5			txa
			beq	:6
			jmp	DiskError		;Disketten-Fehler.

::6			jmp	:1

::7			ldy	#$0b
			lda	(a8L),y
			tax
			and	#%00001000		;Volume-Name ?
			bne	:4			;Ja, ignorieren.
			txa
			and	#%00010000		;Unterverzeichnis ?
			bne	:8			;Ja, weiter...
			ldy	#$1a			;Cluster = 0 ?
			lda	(a8L),y
			bne	:8			;Nein, weiter...
			iny
			lda	(a8L),y
			beq	:4			;Ja, ignorieren.

::8			lda	V302b0			;Startadresse des Directory-Eintrags
			asl				;in Tabelle schreiben.
			tax
			lda	a7L
			sta	V302b1+0,x
			lda	a7H
			sta	V302b1+1,x

			ldy	#$1f			;Eintrag in das RAM kopieren.
::9			lda	(a8L),y
			sta	(a7L),y
			dey
			bpl	:9

			AddVBW	32,a7
			inc	V302b0			;Zähler erhöhen.
			jmp	:4

;*** 16 Datei-Namen ausgeben.
:NextPage		jsr	DoInfoBox		;Infobox aufbauen.
			PrintStrgV302g1

			jsr	ClrBackWin
			Display	ST_WR_BACK
			jsr	UseGDFont

			jsr	i_FillRam		;Speicher für Directory-Einträge
			w	16*32,V302z1		;löschen.
			b	$00
			jsr	i_FillRam		;Speicher für Zeiger auf
			w	16*2,V302b1		;Directory-Einträge löschen.
			b	$00

			lda	V302a7			;Directory-Ende schon erreicht.
			bne	:3			;Ja, Directory-Infos ausgeben.

			jsr	ReadFiles		;16 Directory-Einträge lesen.
			lda	V302b0			;Einträge gefunden ?
			beq	:3			;Nein, Directory-Infos ausgeben.

			LoadB	V302c0,54		;Y-Koordinate für Text-Ausgabe.

			LoadW	a7,V302z1		;Zeiger auf Directory-Tabelle.
			ClrB	V302c1			;Anzahl Einträge auf 0.

;*** 16 Datei-Namen ausgeben (Fortsetzung).
::1			ldy	#$00
			lda	(a7L),y			;Directory-Ende erreicht ?
			beq	:2			;Ja, Tabelle ausgeben.

			jsr	DoFile			;Eintrag ausgeben.
			jsr	AddBlocks_a		;Datei-Größen addieren.

			AddVB	8,V302c0		;Y-Koordinate auf nächste Zeile.
			AddVBW	32,a7			;Zeiger auf nächsten Eintrag.
			inc	V302c1			;Zähler Dateien +1.
			CmpBI	V302c1,16		;Seite ausgegeben ?
			bne	:1			;Nein, weiter...

::2			lda	V302b0			;Einträge ausgegeben ?
			bne	:4			;Ja, weiter...
::3			jsr	GetDirInfo		;Nein, Directory-Infos ausgeben.

::4			jsr	CSet_Grau		;Seite auf Bildschirm.
			jsr	i_RecoverRectangle
			b	48,175
			w	9,302

			rts

;*** Datei-Eintrag ausgeben.
:DoFile			LoadW	r11,16			;X-Koordinate.
			MoveB	V302c0,r1H		;Y-Koordinate.

::1			lda	#$00			;Datei-Name ausgeben.
::2			pha
			tay
			lda	(a7L),y			;Zeichen lesen.
			TDosNmByt			;Zeichen prüfen.
			jsr	SmallPutChar
			pla
			cmp	#$07			;Zwischen Name & Extension ein
			bne	:5			;Leerzeichen einfügen.
			pha
			AddVBW	8,r11
			pla
::5			add	$01
			cmp	#$0b
			bne	:2

			AddVBW	18,r11			;X-Koordinate korrigieren.

			ldy	#$0b			;Auf Sub-Directory testen.
			lda	(a7L),y
			and	#%00010000
			beq	:6			;Kein SubDir, weiter...

			LoadW	r0,V302e1		;"<SubDir>" ausgeben.
			jsr	PutString
			jmp	:7

::6			jsr	InitForBA		;Dateilänge ausgeben.
			lda	#<V302d0
			ldy	#>V302d0
			jsr	MOVMA
			ldy	#$1f
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			jsr	Word_FAC
			jsr	x_MULT
			jsr	MOVFA
			ldy	#$1d
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			jsr	Word_FAC
			jsr	ADDFAC
			jsr	x_FLPSTR
			jsr	DoneWithBA

			ldy	#$09
			jsr	Do_ZFAC

::7			AddVBW	12,r11			;X-Koordinate korrigieren.

;*** Datum & Zeit ausgeben.
:Print_DT		jsr	GetBinDate

			ldy	V302k1+0		;Ausgabe: Tag.
			lda	#$02
			jsr	Do_Zahl
			lda	#$2e
			jsr	SmallPutChar

			ldy	V302k1+1		;Ausgabe: Monat.
			lda	#$02
			jsr	Do_Zahl
			lda	#$2e
			jsr	SmallPutChar

			ldy	V302k1+2		;Ausgabe: Jahr.
::1			cpy	#100
			bcc	:2
			tya
			sbc	#100
			tay
			bcs	:1
::2			lda	#$02
			jsr	Do_Zahl

			AddVBW	12,r11

			ldy	V302k1+3		;Ausgabe: Stunde.
			lda	#$02
			jsr	Do_Zahl
			lda	#$3a
			jsr	SmallPutChar

			ldy	V302k1+4		;Ausgabe: Minute.
			lda	#$02
			jmp	Do_Zahl

;*** Datum berechnen (r11L - r13L).
:GetBinDate		ldy	#$18			;Tag berechnen.
			lda	(a7L),y
			sta	r15L
			iny
			lda	(a7L),y
			sta	r15H
			lda	r15L
			and	#%00011111
			sta	V302k1+0

			RORZWordr15L,5

			lda	r15L			;Monat berechnen.
			and	#%00001111
			sta	V302k1+1

			RORZWordr15L,4

			lda	r15L			;Jahr berechnen.
			and	#%01111111
			clc
			adc	#80
			sta	V302k1+2

			ldy	#$16			;Uhrzeit berechnen.
			lda	(a7L),y
			sta	r15L
			iny
			lda	(a7L),y
			sta	r15H

			RORZWordr15L,5

			lda	r15L			;Minute berechnen.
			and	#%00111111
			sta	V302k1+4

			RORZWordr15L,6

			lda	r15L			;Stunde berechnen.
			and	#%00011111
			sta	V302k1+3
			rts

;*** Diskettenkapazitäten ausgeben.
:GetDirInfo		jsr	CalcFreeClu

			jsr	InitForBA		;Anzahl Dateien nach ASCII wandeln.
			LoadFAC	DirFiles
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl Dateien ausgeben.
			PrintXY	20,64,V302f0
			jsr	PutInfoEntry

			jsr	InitForBA		;Anzahl Bytes im Directory berechnen.
			lda	#<V302d0
			ldy	#>V302d0
			jsr	MOVMA
			LoadFAC	UsedByte+2
			jsr	x_MULT
			jsr	MOVFA
			LoadFAC	UsedByte
			jsr	ADDFAC
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl Bytes im Directory ausgeben.
			PrintXY	20,76,V302f1
			jsr	PutInfoEntry
			jsr	PrnTxtByte

			jsr	InitForBA		;Anzahl belegter Cluster berechnen.
			sec
			lda	Free_Clu+0
			sbc	CountFreeClu
			tay
			lda	Free_Clu+1
			sbc	CountFreeClu+1
			tax
			tya
			jsr	Word_FAC
			jsr	MOVFA
			LoadFAC	Clu_Byte
			jsr	x_MULT
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl belegter Cluster ausgeben.
			PrintXY	20,88,V302f2
			jsr	PutInfoEntry
			jsr	PrnTxtByte

			jsr	InitForBA		;Anzahl freier Cluster berechnen.
			LoadFAC	CountFreeClu
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl freier Cluster ausgeben.
			PrintXY	20,100,V302f3
			jsr	PutInfoEntry

			jsr	InitForBA		;Anzahl freier Bytes berechnen.
			LoadFAC	CountFreeClu
			jsr	MOVFA
			LoadFAC	Clu_Byte
			jsr	x_MULT
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl freier Bytes ausgeben.
			PrintXY	20,112,V302f4
			jsr	PutInfoEntry
			jsr	PrnTxtByte

			jsr	InitForBA		;Anzahl Gesamt-Bytes berechnen.
			lda	#<Free_Byte
			ldy	#>Free_Byte
			jsr	MOVMF
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl Gesamt-Bytes ausgeben.
			PrintXY	20,124,V302f5
			jsr	PutInfoEntry

:PrnTxtByte		jsr	UseSystemFont
			LoadW	r0,V302f6
			jmp	PutString

;*** Cursor positionieren.
:PutInfoEntry		LoadW	r11,170

			lda	#":"
			jsr	SmallPutChar

			LoadB	currentMode,0
			LoadW	r11,190
			jsr	UseGDFont

			ldy	#$07
			jmp	Do_ZFAC

;*** SubDir auswählen.
:SlctEntry		lda	mouseData
			bpl	:2
::1			ClrB	pressFlag
			rts

::2			LoadB	r2L,48			;Prüfen ob gültiger Datei-Eintrag
			LoadB	r2H,175			;angeklickt wurde.
			LoadW	r3,9
			LoadW	r4,302
			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			beq	:1			;Kein Eintrag, abbruch.

			lda	mouseYPos		;Prüfen ob angeklickter Eintrag
			lsr				;ein Unterverzeichnis ist.
			lsr
			lsr
			tax
			sub	$06
			asl
			tay
			lda	V302b1+0,y
			sta	a7L
			lda	V302b1+1,y
			sta	a7H

			cmp	#$00
			bne	:3
			lda	a7L
			beq	:1

::3			ldy	#$0b
			lda	(a7L),y
			and	#%00010000
			bne	SlctSubDir		;Ja, neues Unterverzeichnis öffnen.
			jmp	SlctFile 		;Nein, Datei-Info ausgeben.

;*** Unterverzeichnis öffnen.
:SlctSubDir		txa				;Eintrag invertieren.
			asl
			asl
			asl
			sta	r2L
			add	$07
			sta	r2H
			Display	ST_WR_FORE
			jsr	InvertRectangle

			MoveW	a7,r0			;Daten des Directorys in
			LoadW	r1,Dir_Entry		;Zwischenspeicher kopieren.
			LoadW	r2,32
			jsr	MoveData

			NoMseKey

			LoadB	DirTyp,$ff		;Unterverzeichnis ausgeben.
			jmp	Start_Dir

;*** Datei-Info-Box verlassen.
:ExitFileInfo
:ExitPrintDir		jsr	ClrExtraWin
			LoadW	otherPressVec,SlctEntry

			lda	RAM_Modify		;Wurde RAM verändert ?
			bne	:1			;Ja, Directory neu lesen.

			jsr	ShowWin			;Nein, Bildschirm wieder aufbauen.
			jmp	DoDirIcons		;Menüs aktivieren.

::1			jsr	SetWin			;Fenster aufbauen.
			jmp	Start_Dir		;Directory neu lesen.

;*** Datei-Info-Fenster.
:SlctFile		jsr	HideWin			;Fenster verstecken.

			ldy	#$00
			ldx	#$09
::1			lda	(a7L),y			;Name der Datei in Titel-Zeile
			TDosNmByt			;eintragen.
::4			sta	V302h0,x
			inx
			cpy	#$07
			bne	:5
			inx
::5			iny
			cpy	#$0b
			bne	:1

			LoadW	r0,V302h0		;Info-Fenster aufbauen.
			jsr	SetExtraWin

			PrintXY	40,72,V302h1		;Datum & Uhrzeit ausgeben.
			jsr	Print_DT

			PrintXY	40,82,V302h2
			jsr	InitForBA		;Datei-Größe berechnen.
			lda	#<V302d0
			ldy	#>V302d0
			jsr	MOVMA
			ldy	#$1f
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			jsr	Word_FAC
			jsr	x_MULT
			jsr	MOVFA
			ldy	#$1d
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			jsr	Word_FAC
			jsr	ADDFAC
			jsr	x_FLPSTR
			jsr	DoneWithBA

			lda	#$00			;Datei-Größe ausgeben.
::6			pha
			tay
			lda	$0101,y
			beq	:7
			jsr	SmallPutChar
			pla
			add	$01
			bne	:6
			pha
::7			pla
			LoadW	r0,V302h3
			jsr	PutString

			PrintXY	40,100,V302h4		;"Read-Only"-Status ausgeben.
			LoadW	r0,V302h5
			ldy	#$0b
			lda	(a7L),y
			pha
			and	#%00000001
			beq	:8
			LoadW	r0,V302h6
::8			jsr	PutString

			PrintXY	40,110,V302h7		;"Hidden-Datei"-Status ausgeben.
			LoadW	r0,V302h8
			pla
			pha
			and	#%00000010
			beq	:9
			LoadW	r0,V302h9
::9			jsr	PutString

			PrintXY	40,120,V302h10		;"System-Datei"-Status ausgeben.
			LoadW	r0,V302h8
			pla
			and	#%00000100
			beq	:10
			LoadW	r0,V302h9
::10			jsr	PutString

			LoadW	r0,icon_Tab2		;Icon-Tabelle aktivieren.
			jsr	DoIcons
			StartMouse			;Maus aktivieren.
			NoMseKey
			rts

;*** Directory drucken.
:PrintDir		jsr	HideWin			;Directory-Fenster löschen.

			LoadW	r0,V302i0
			jsr	SetExtraWin
			jsr	UseSystemFont

			PrintXY	48,70,V302i1		;Text für Drucker-Box ausgeben.
			LoadW	r0,PrntFileName
			jsr	PutString

			LoadW	r0,V302i2		;Anzahl Zeilen/Seite ausgeben.
			jsr	GraphicsString
			jsr	PrintLines
			LoadW	r0,V302i4		;Papier-Modus ausgeben.
			jsr	GraphicsString

			LoadW	otherPressVec,SlctPaper
			LoadW	r0,icon_Tab3		;Icons aktivieren.
			jsr	DoIcons
			rts

;*** Icon-Position speichern.
:SaveIconPos		ldx	#$05
::1			lda	r2L,x
			sta	V302k0,x
			dex
			bpl	:1
			rts

;*** Icon-Position laden.
:LoadIconPos		ldx	#$05
::1			lda	V302k0,x
			sta	r2L,x
			dex
			bpl	:1
			rts

;*** Eine Zeile weniger...
:Sub1Line		jsr	SaveIconPos
			jsr	InvertRectangle
::1			ldx	V302j0
			cpx	#15
			beq	:2
			dec	V302j0
			jsr	PrintLines
			lda	mouseData
			bpl	:1
::2			jsr	LoadIconPos
			jsr	InvertRectangle
			rts

;*** Eine Zeile mehr...
:Add1Line		jsr	SaveIconPos
			jsr	InvertRectangle
::1			ldx	V302j0
			cpx	#255
			beq	:2
			inc	V302j0
			jsr	PrintLines
			lda	mouseData
			bpl	:1
::2			jsr	LoadIconPos
			jsr	InvertRectangle
			rts

;*** Anzahl Zeilen pro Seite ausgeben.
:PrintLines		LoadW	r0,V302i2		;Anzeige-Feld löschen.
			jsr	GraphicsString

			LoadB	currentMode,64		;Anzahl Zeilen ausgeben.
			LoadW	r11,223
			LoadB	r1H,98
			MoveB	V302j0,r0L
			ClrB	r0H
			lda	#%11000000
			jsr	PutDecimal

			lda	#" "
			jsr	SmallPutChar
			rts

;*** Einzel-/Endloßpapier...
:SlctPaper		LoadB	r2L,107			;Testen ob Maus innerhalb
			LoadB	r2H,114			;Auswahl-Icon.
			LoadW	r3,48
			LoadW	r4,55
			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			beq	:1

			lda	V302i4+1		;Papier-Modus wechseln.
			eor	#$02
			sta	V302i4+1

			LoadW	r0,V302i4
			jsr	GraphicsString

			NoMseKey
::1			rts

;*** Drucker wählen.
:SlctPrinter		jsr	ClrExtraWin		;Drucker-Box löschen.
			jsr	GetStartDrv
			LoadB	RAM_Modify,$ff		;Directory im RAM als "zerstört"
							;kennzeichnen.

			LoadB	r7L,PRINTER		;Druckertreiber suchen.
			LoadB	r7H,255
			LoadW	r10,$0000
			LoadW	r6,V302z1
			jsr	FindFTypes
			txa
			beq	:1
			jmp	DiskError

::1			jsr	GetWorkDrv
			CmpBI	r7H,255			;Druckertreiber gefunden ?
			bne	:3			;Ja, Drucker auswählen.
::2			jmp	PrintDir		;Zurück zum Druck-Modus.

::3			lda	#<V302z1		;Datei-Namen der Druckertreiber
			sta	r0L			;in 16-Byte-Format wandeln.
			sta	r1L
			lda	#>V302z1
			sta	r0H
			sta	r1H

::4			ldy	#$00
::5			lda	(r1L),y			;$00-Bytes im Datei-Namen
			bne	:6			;durch "SHIFT-SPACE" ersetzen.
			lda	#$a0
::6			sta	(r0L),y
			iny
			cpy	#$10			;Ende Datei-Namen erreicht ?
			bne	:5
			AddVBW	16,r0			;Zeiger auf nächsten Datei-Namen.
			AddVBW	17,r1
			inc	r7H
			CmpBI	r7H,255			;Ende der Tabelle erreicht ?
			bne	:4			;Nein, weiter...

			ldy	#$00			;Tabellen-Ende markieren.
			tya
			sta	(r0L),y

			LoadW	r14,V302i13		;Drucker-Auswahlbox.
			LoadW	r15,V302z1
			lda	#$00
			ldx	#$10
			ldy	#$00
			jsr	DoScrTab

			ldy	sysDBData		;Druckertreiber gewählt ?
			cpy	#$01
			beq	:7
			jmp	PrintDir		;Ja, zurück zum Druck-Modus.

::7			ldy	#$0f			;Neuen Druckertreiber setzen.
::8			lda	(r15L),y
			sta	PrntFileName,y
			dey
			bpl	:8
			jmp	PrintDir		;Ja, zurück zum Druck-Modus.

;*** Directory drucken.
:StartPrnDir		jsr	ClrExtraWin		;Drucker-Box löschen.
			jsr	DoInfoBox		;Info-Box ausgeben.
			PrintStrgV302i8

			jsr	GetStartDrv
			LoadW	r6,PrntFileName
			LoadB	r0L,0
			jsr	GetFile			;Drucker-Treiber laden.
			txa
			beq	:2
			cpx	#$05			;Fehler: Treiber nicht gefunden ?
			beq	:1			;Ja, Meldung ausgeben.
			jmp	DiskError		;Disketten-Fehler.

::1			jsr	GetWorkDrv
			jsr	ClrBox
			LoadW	r0,V302i9		;Fehler: "Druckertreiber nicht ..."
			ClrDlgBoxCSet_Grau
			jsr	ShowWin			;Directory-Seite wieder aufbauen.
			jmp	DoDirIcons		;Zurück zum Directory-Modus.

;*** Directory-Ausdruck initialisieren.
::2			jsr	GetWorkDrv
			jsr	ClrBox

			ClrB	V302j3			;Zähler für Seiten-Nr. auf 0.
			jsr	Do1stInit		;Zeiger auf Anfang Directory.

			ldy	#$00			;Titel-Zeile in Zwischenspeicher.
::3			lda	V302l0,y
			sta	V302z1,y
			beq	:4
			iny
			bne	:3

::4			ldx	#$38			;Datum des Directory-Ausdrucks in
			lda	day			;Titel-Zeile eintragen.
			jsr	HexASCII_a
			inx
			lda	month
			jsr	HexASCII_a
			inx
			lda	year
			jsr	HexASCII_a
			ldx	#$44			;Uhrzeit des Directory-Ausdrucks in
			lda	hour			;Titel-Zeile eintragen.
			jsr	HexASCII_a
			inx
			lda	minutes
			jsr	HexASCII_a

			ldy	#$00			;Titel-Zeile zurückschreiben.
::5			lda	V302z1,y
			sta	V302l0,y
			beq	:6
			iny
			bne	:5

::6			ldy	#$00			;Disketten-Name in Titel-Zeile
::7			lda	dosDiskName,y		;eintragen.
			cmp	#" "
			bcc	:7a
			cmp	#$7f
			bcc	:7b
::7a			lda	#" "
::7b			sta	V302l1+17,y
			iny
			cpy	#$0b
			bne	:7

			LoadW	r0,V302m3
			lda	DirTyp			;Directory-Typ testen.
			beq	:11			;Hauptverzeichnis ? Ja, weiter...

			lda	#"."			;Name des Unterverzeichnisses in
			sta	V302l1+44		;Titel-Zeile eintragen.
			sta	V302l1+45
			lda	#"/"
			sta	V302l1+46
			ldy	#$00
			ldx	#$00
::9			lda	Dir_Entry,y
			sta	V302l1+47,x
			inx
			cpy	#$07
			bne	:10
			inx
::10			iny
			cpy	#$0b
			bne	:9

			LoadW	r0,V302m4
::11			ldy	#$00			;Verzeichnis-Typ in Titel-Zeile
::12			lda	(r0L),y			;eintragen.
			beq	:13
			sta	V302l1+32,y
			iny
			bne	:12

::13			StartMouse
			NoMseKey
			jsr	RdCurDirSek

;*** Einzelne Seite drucken.
:NewPage		jsr	PrintHeader		;Seiten-Kopf drucken.
::1			lda	pressFlag		;Drucken abbrechen ?
			bne	:6			;Ja, zurück zum Directory-Modus.

			CmpBI	V302j1,1		;Noch Platz für einen Eintrag auf
			bcs	:2			;aktueller Seite ?
			jmp	:4			;Nein, Seiten-Vorschub...

::2			jsr	GetDirLine		;Einzelne Druck-Zeile erzeugen.
			bne	:5			;Directory-Ende, Infos drucken.
			MoveW	a8,a7
			jsr	AddBlocks_a
			jsr	PrnASCIILine		;Eintrag ausgeben.
::3			dec	V302j1			;Seite voll ?
			jmp	:1

::4			jsr	StopPrint		;Seiten-Vorschub.
			jsr	ClrBox
			jsr	WaitNewPage		;Bei Einzel-Blatt, warten auf Papier.
			cmp	#$02			;Abbruch ?
			beq	:7			;Ja, Zurück zum Directory-Modus.
			jmp	NewPage			;Nein, nächste Seite.

::5			jsr	PrnDirInfo		;Directory-Informationen drucken.
::6			jsr	StopPrint		;Seiten-Vorschub...
			jsr	ClrBox
::7			jsr	SetWin
			jmp	Start_Dir		;Zurück zum Directory-Modus.

;*** ASCII-Zeile drucken.
:PrnASCIILine		LoadW	r0,V302z1
:PrnTempLine		LoadW	r1,V302z1 +256
			jmp	PrintASCII

;*** Eintrag erzeugen.
:GetDirLine		ldx	V302a0			;Alle Einträge eines Sektors
			cpx	#$10			;gedruckt ?
			bne	:2			;Nein, weiter...
			jsr	RdNxDirSek		;Nächsten Directory-Sektor einlesen.
			bcc	:1
			lda	#$ff			;Directory-Ende.
			rts

::1			txa				;Disketten-Fehler ?
			beq	:2			;Nein, weiter...

			txa				;Fehler: Seiten-Vorschub...
			pha
			jsr	StopPrint
			pla
			tax
			jmp	DiskError		;...und Disketten-Fehler ausgeben.

::2			MoveB	V302a0+0,a8L		;Zeiger auf Directory-Eintrag im
			ClrB	a8H			;aktuellen Sektor berechnen.
			ldx	#a8L
			ldy	#$05
			jsr	DShiftLeft
			AddVW	Disk_Sek,a8

			inc	V302a0			;Zähler Einträge erhöhen.

			ldy	#$00			;Directory-Ende erreicht ?
			lda	(a8L),y
			bne	:3			;Nein, weiter...
			lda	#$ff			;Ja, Ende...
			rts

::3			cmp	#$e5			;Gelöschter Eintrag ?
			bne	:5			;Nein, ausgeben.
::4			jmp	GetDirLine

::5			ldy	#$0b
			lda	(a8L),y
			tax
			and	#%00001000		;Volume-Name ?
			bne	:4			;Ja, ignorieren.
			txa
			and	#%00010000		;Unterverzeichnis ?
			bne	:6			;Ja, weiter...
			ldy	#$1a			;Cluster = 0 ?
			lda	(a8L),y
			bne	:6			;Nein, weiter...
			iny
			lda	(a8L),y
			beq	:4			;Ja, ignorieren.

::6			ldx	#$00
			lda	#$20			;Druckzeile mit 7 Leerzeichen
::7			sta	V302z1,x		;beginnen.
			inx
			cpx	#$07
			bne	:7

			ldy	#$00			;Datei-Name in Zwischenspeicher.
::8			lda	(a8L),y
			sta	V302z1,x
			inx
			cpy	#$07
			bne	:9
			inx
::9			iny
			cpy	#$0b
			bne	:8

;*** Directory-Eintrag erzeugen (Fortsetzung).
			lda	#$20			;Zwei Leerzeichen einfügen.
			sta	V302z1+0,x
			sta	V302z1+1,x
			inx
			inx

			ldy	#$0b			;Unterverzeichnis ?
			lda	(a8L),y
			and	#%00010000
			beq	:11			;Nein, weiter...

			ldy	#$00			;Keine Datei-Größe ausgeben, sondern
::10			lda	V302e1,y		;Text "<Sub-Dir>" ausgeben.
			beq	:13
			sta	V302z1,x
			inx
			iny
			bne	:10

::11			txa				;Datei-Größe berechnen.
			pha
			jsr	InitForBA
			lda	#<V302d0
			ldy	#>V302d0
			jsr	MOVMA
			ldy	#$1f
			lda	(a8L),y
			tax
			dey
			lda	(a8L),y
			jsr	Word_FAC
			jsr	x_MULT
			jsr	MOVFA
			ldy	#$1d
			lda	(a8L),y
			tax
			dey
			lda	(a8L),y
			jsr	Word_FAC
			jsr	ADDFAC
			jsr	x_FLPSTR
			jsr	DoneWithBA
			pla
			tax

			ldy	#$00
::12			lda	$0101,y			;Datei-Größe in Eintrag schreiben.
			beq	:13
			sta	V302z1,x
			inx
			iny
			bne	:12
::13			lda	#$20			;Zeiger auf Position für Datum
			sta	V302z1,x		;setzen. Alle Zeichen bis dahin mit
			inx				;Leerzeichen löschen.
			cpx	#$20
			bne	:13

			txa				;Datum berechnen.
			pha
			MoveW	a8,a7
			jsr	GetBinDate
			pla
			tax

			lda	V302k1+0		;Datum in Eintrag schreiben.
			jsr	HexASCII_a
			lda	#"."
			sta	V302z1,x
			inx
			lda	V302k1+1
			jsr	HexASCII_a
			lda	#"."
			sta	V302z1,x
			inx
			lda	V302k1+2
::14			cmp	#100
			bcc	:15
			sbc	#100
			bcs	:14
::15			jsr	HexASCII_a

			lda	#" "			;Zwei Leerzeichen einfügen.
			sta	V302z1+0,x
			sta	V302z1+1,x
			inx
			inx

			lda	V302k1+3		;Uhrzeit in Eintrag schreiben.
			jsr	HexASCII_a
			lda	#":"
			sta	V302z1,x
			inx
			lda	V302k1+4
			jsr	HexASCII_a

			lda	#" "			;Zwei Leerzeichen einfügen.
			sta	V302z1+0,x
			sta	V302z1+1,x
			inx
			inx

;*** Eintrag erzeugen (Fortsetzung).
			lda	#"-"			;Datei-Attribute in Klar-Text.
			sta	V302z1,x

			ldy	#$0b			;"Read-Only"-Status prüfen.
			lda	(a8L),y
			pha
			and	#%00000001
			beq	:16

			LoadW	r0,V302m0
			jsr	CopyAttr

::16			pla				;"Hidden-Datei"-Status prüfen.
			pha
			and	#%00000010
			beq	:17

			LoadW	r0,V302m1
			jsr	CopyAttr

::17			pla				;"System-Datei"-Status prüfen.
			and	#%00000100
			beq	:18

			LoadW	r0,V302m2
			jsr	CopyAttr

::18			lda	V302z1,x
			cmp	#"-"
			beq	:19
			dex
			dex
::19			inx
			lda	#$0d			;Ende des Zwischenspeichers markieren.
			sta	V302z1,x
			lda	#$00
			sta	V302z1+1,x

			lda	#$00
			rts

;*** Text für Attribut in Druckzeile kopieren.
:CopyAttr		ldy	#$00
::1			lda	(r0L),y
			beq	:2
			sta	V302z1,x
			inx
			iny
			bne	:1
::2			lda	#","
			sta	V302z1,x
			inx
			rts

;*** Directory-Informationen drucken.
:PrnDirInfo		lda	V302j1			;Noch Platz für 6 Zeilen ?
			cmp	#$08
			bcs	:2
			jsr	StopPrint		;Nein, Seiten-Vorschub...
			jsr	WaitNewPage		;Warten auf neue Seite.
			cmp	#$02			;Abbruch ?
			bne	:1			;Nein, Directory-Daten drucken.
			rts

::1			jsr	PrintHeader		;Bei neuer Seite, Seiten-Kopf drucken.
::2			LoadB	V302z1 +0,$0d		;Eine Leerzeile ausgeben.
			LoadB	V302z1 +1,$00
			jsr	PrnASCIILine

			LoadW	r0,V302l4		;Anzahl Dateien im Directory.
			MoveW	DirFiles,r1
			LoadB	r3L,38
			LoadB	r3H,9
			jsr	NumASCII_a
			jsr	PrnTempLine

			LoadW	r0,V302l5		;Anzahl Blocks im Directory.
			MoveW	UsedByte+0,r1
			MoveW	UsedByte+2,r2
			LoadB	r3L,38
			LoadB	r3H,9
			jsr	NumASCII_b
			jsr	PrnTempLine

			jsr	CalcFreeClu		;Disketten-Informationen einlesen.
			jsr	InitForBA		;Anzahl belegter Cluster berechnen.
			sec
			lda	Free_Clu+0
			sbc	CountFreeClu
			tay
			lda	Free_Clu+1
			sbc	CountFreeClu+1
			tax
			tya
			jsr	Word_FAC
			jsr	MOVFA
			LoadFAC	Clu_Byte
			jsr	x_MULT
			jsr	x_FLPSTR
			jsr	DoneWithBA

			LoadW	r0,V302l6		;Anzahl belegter Blocks.
			LoadB	r3L,38
			LoadB	r3H,9
			jsr	NumASCII_c
			jsr	PrnTempLine

			LoadW	r0,V302l7		;Anzahl freier Sektoren.
			MoveW	CountFreeClu,r1
			LoadB	r3L,38
			LoadB	r3H,9
			jsr	NumASCII_a
			jsr	PrnTempLine

			jsr	InitForBA
			LoadFAC	CountFreeClu
			jsr	MOVFA
			LoadFAC	Clu_Byte
			jsr	x_MULT
			jsr	x_FLPSTR
			jsr	DoneWithBA

			LoadW	r0,V302l8		;Gesamt-Anzahl Sektoren.
			LoadB	r3L,38
			LoadB	r3H,9
			jsr	NumASCII_c
			jsr	PrnTempLine

			jsr	InitForBA
			lda	#<Free_Byte
			ldy	#>Free_Byte
			jsr	MOVMF
			jsr	x_FLPSTR
			jsr	DoneWithBA

			LoadW	r0,V302l9		;Anschluß-Info.
			LoadB	r3L,38
			LoadB	r3H,9
			jsr	NumASCII_c
			jsr	PrnTempLine
			rts

;*** HEX-Zahl nach ASCII wandeln.
:HexASCII_a		pha
			lda	#"0"			;Zehner-Stelle auf "0" setzen.
			sta	V302z1+0,x
			pla
::1			cmp	#$0a			;Zahl < 10 ?
			bcc	:2			;Ja, Ende...
			inc	V302z1,x		;Nein, Zehner-Stelle erhöhen.
			sub	10			;Zahl = Zahl -10.
			bne	:1			;Zahl = 0 ? Nein, weiter...
::2			add	$30			;ASCII-Zahl erzeugen und
			sta	V302z1+1,x		;Einer-Stelle setzen.
			inx
			inx
			rts

;*** HEX-Zahl nach ASCII wandeln.
:HexASCII_b		ldx	#"0"			;Zehner-Stelle auf "0" setzen.
::1			cmp	#10			;Zahl < 10 ?
			bcc	:2			;Ja, Ende...
			inx				;Nein, Zehner-Stelle erhöhen.
			sub	10			;Zahl = Zahl -10.
			bne	:1			;Zahl = 0 ? Nein, weiter...
::2			add	$30			;ASCII-Zahl erzeugen.
			rts

;*** Zahl in ASCII wandeln.
:NumASCII_a		ClrW	r2

:NumASCII_b		jsr	InitForBA		;Anzahl Bytes im Directory berechnen.
			lda	#<V302d0
			ldy	#>V302d0
			jsr	MOVMA
			LoadFAC	r2
			jsr	x_MULT
			jsr	MOVFA
			LoadFAC	r1
			jsr	ADDFAC
			jsr	x_FLPSTR
			jsr	DoneWithBA

:NumASCII_c		ldy	r3L			;Zeiger auf Adresse für Zahlenstring.
			ldx	#$00
::1			lda	$0100,x			;ASCII-Zeichen aus Zahlenstring
			beq	:2			;einlesen. Zeichen = 0 ? Ja, Ende...
			sta	(r0L),y			;In Ziel-String eintragen.
			iny				;Weiter mit nächstem Zeichen.
			inx
			bne	:1
::2			cpx	r3H			;String auf gewünschte Länge mit
			bcs	:3			;Leerzeichen auffüllen.
			lda	#$20
			sta	(r0L),y
			iny
			inx
			bne	:2
::3			rts

;*** Seiten-Kopf drucken.
:PrintHeader		jsr	InitForPrint		;Druckertreiber initialisieren.
			jsr	StartASCII		;Drucker auf ASCII vorbereiten.
			txa
			beq	InitPage		;Kein Fehler, Seite initialisieren.
			pla				;Rücksprung-Adresse vom Stapel holen.
			pla
:PrnNotReady		LoadW	r0,V302i11 		;Drucker nicht verfügbar.
			ClrDlgBoxCSet_Grau
			jsr	SetWin
			jmp	Start_Dir

:InitPage		jsr	InfoPrnPage		;Info-Box ausgeben.
			jsr	SetNLQ			;Drucker auf NLQ vorbereiten.

			inc	V302j3			;Seiten-Nummer korrigieren.

			lda	V302j0			;Anzahl Zeilen pro Seite berechnen.
			sub	$05
::1			sta	V302j1
			lda	V302j3			;Seiten-Nummer in Titel-Zeile.
			jsr	HexASCII_b
			stx	V302l1+75
			sta	V302l1+76

			LoadW	r0,V302l0		;Header ausdrucken.
			jsr	PrnTempLine
			LoadW	r0,V302l1
			jsr	PrnTempLine
			LoadW	r0,V302l2
			jsr	PrnTempLine
			LoadW	r0,V302l3
			jmp	PrnTempLine

;*** Info: "Seite wird gedruckt..."
:InfoPrnPage		jsr	DoInfoBox
			PrintStrgV302i5
			rts

;*** Warten auf neues Blatt Papier...
:WaitNewPage		lda	V302i4 +1		;Einzelblatt-Modus ?
			beq	:1			;Ja, Info-Box.
			jsr	ClrBox
			LoadW	r0,V302i6		;Warten auf neues Blatt Papier.
			ClrDlgBoxCSet_Grau
			lda	sysDBData
::1			rts

;*** Icon-Tabelle
:icon_Tab1		b	9
			w	$0000
			b	$00

			w	icon_Close
			b	$00,$00
			b	icon_Close_x,icon_Close_y
			w	ExitDT_a

			w	icon_Close
			b	$01,$28
			b	icon_Close_x,icon_Close_y
			w	L302ExitGD

			w	icon_Weiter
			b	1,16
			b	icon_Weiter_x,icon_Weiter_y
			w	ShowNxFiles

			w	icon_Root
			b	4,16
			b	icon_Root_x,icon_Root_y
			w	GoRootDir

			w	icon_SubD
			b	7,16
			b	icon_SubD_x,icon_SubD_y
			w	GoSubDir

			w	icon_Drive
			b	13,16
			b	icon_Drive_x,icon_Drive_y
			w	L302ExitDrv

			w	icon_Print
			b	16,16
			b	icon_Print_x,icon_Print_y
			w	PrintDir

			w	icon_Ende
			b	19,16
			b	icon_Ende_x,icon_Ende_y
			w	L302ExitGD

			w	icon_Disk
			b	10,16
			b	icon_Disk_x,icon_Disk_y
			w	GetDisk

;*** Icon-Tabelle
:icon_Tab2		b	3
			w	228
			b	148

			w	icon_Close
			b	$00,$00
			b	icon_Close_x,icon_Close_y
			w	ExitDT

			w	icon_Close
			b	$04,$30
			b	icon_Close_x,icon_Close_y
			w	ExitFileInfo

			w	icon_OK
			b	$1c,$90
			b	icon_OK_x,icon_OK_y
			w	ExitFileInfo

;*** Icons für "Print Dirctory"
:icon_Tab3		b	7
			w	52
			b	148

			w	icon_Close
			b	$00,$00
			b	icon_Close_x,icon_Close_y
			w	ExitDT

			w	icon_Close
			b	$04,$30
			b	icon_Close_x,icon_Close_y
			w	ExitPrintDir

			w	icon_OK
			b	$06,$90
			b	icon_OK_x,icon_OK_y
			w	StartPrnDir

			w	icon_SelPrn
			b	$0f,$90
			b	icon_SelPrn_x,icon_SelPrn_y
			w	SlctPrinter

			w	icon_CancelPrnt
			b	$1b,$90
			b	icon_CancelPrnt_x,icon_CancelPrnt_y
			w	ExitPrintDir

			w	icon_Sub1
			b	$19,$5a
			b	icon_Sub1_x,icon_Sub1_y
			w	Sub1Line

			w	icon_Add1
			b	$1f,$5a
			b	icon_Add1_x,icon_Add1_y
			w	Add1Line

;*** Directory-Icons.
:icon_Weiter
<MISSING_IMAGE_DATA>
:icon_Weiter_x = .x
:icon_Weiter_y = .y

:icon_Root
<MISSING_IMAGE_DATA>
:icon_Root_x = .x
:icon_Root_y = .y

:icon_SubD
<MISSING_IMAGE_DATA>
:icon_SubD_x = .x
:icon_SubD_y = .y

:icon_Disk
<MISSING_IMAGE_DATA>
:icon_Disk_x = .x
:icon_Disk_y = .y

:icon_Drive
<MISSING_IMAGE_DATA>
:icon_Drive_x = .x
:icon_Drive_y = .y

:icon_Print
<MISSING_IMAGE_DATA>
:icon_Print_x = .x
:icon_Print_y = .y

:icon_Ende
<MISSING_IMAGE_DATA>
:icon_Ende_x = .x
:icon_Ende_y = .y

:icon_OK
<MISSING_IMAGE_DATA>
:icon_OK_x		= .x
:icon_OK_y		= .y

:icon_SelPrn
<MISSING_IMAGE_DATA>
:icon_SelPrn_x		= .x
:icon_SelPrn_y		= .y

:icon_CancelPrnt
<MISSING_IMAGE_DATA>
:icon_CancelPrnt_x	= .x
:icon_CancelPrnt_y	= .y

:icon_Sub1
<MISSING_IMAGE_DATA>
:icon_Sub1_x		= .x
:icon_Sub1_y		= 12

:icon_Add1
<MISSING_IMAGE_DATA>
:icon_Add1_x		= .x
:icon_Add1_y		= 12

;*** Variablen zur Steuerung des Directorys.
:DirTyp			b $00				;$00 = Stammverzeichnis
							;$ff = Unterverzeichnis
:UsedByte		s $04				;Anzahl verbrauchter Bytes.
:DirFiles		w $0000				;Anzahl Files im Directory.
:VekBuf1		w $0000				;Speicher für ":otherPressVektor".
:CountClu		w $0000				;Zähler für ":CalcFreeClu".
:CountFreeClu		w $0000				;Zähler für ":CalcFreeClu".
:RAM_Modify		b $00				;Zwischenspeicher zerstört.

:V302a0			b $00				;Nr. des aktuellen Eintrages im Sektor.
:V302a1			w $0000				;Zwischenspeicher für Zeiger innerhalb des
							;Sektors auf Directory-Eintrag.
:V302a2			s $03				;Seite,Spur,Sektor des aktuellen Directory-Sektors.
:V302a3			b $00				;Anzahl Sektoren im Hauptverzeichnis.
:V302a4			w $0000				;Nr. des Start-Clusters des Unterverzeichnisses.
:V302a5			w $0000				;Nr. des aktuellen Unterverzeichnis-Clusters.
:V302a6			b $00				;Nr. des Sektors im aktuellen Cluster.
:V302a7			b $00				;$FF = Directory-Ende.

:V302b0			b $00				;Anzahl Einträge im RAM.
:V302b1			s 16*2				;Startadresse der Directory-Einträge im RAM.

:V302c0			b $00				;Y-Koordinate für Directory-Ausgabe.
:V302c1			b $00				;Anzahl ausgegebener Einträge.

:V302d0			b $91,$00,$00,$00,$00

:V302e0			b PLAINTEXT,REV_ON
			b "MS-DOS: ",NULL
:V302e1			b "<Sub Dir>",NULL
:V302e2			b PLAINTEXT,REV_ON
			b "Datei:         .   ",NULL

:V302f0			b PLAINTEXT,BOLDON,"Dateien im Directory",NULL
:V302f1			b PLAINTEXT,BOLDON,"Bytes im Directory",NULL
:V302f2			b PLAINTEXT,BOLDON,"Belegter Speicher",NULL
:V302f3			b PLAINTEXT,BOLDON,"Freie Cluster",NULL
:V302f4			b PLAINTEXT,BOLDON,"Verfügbarer Speicher",NULL
:V302f5			b PLAINTEXT,BOLDON,"Speicher gesamt",NULL
:V302f6			b BOLDON," Byte(s)",NULL

;*** Info: "Disketten-Daten werden eingelesen..."
:V302g0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Disketten-Daten"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "werden eingelesen..."
			b NULL

;*** Info: "Seite wird aufgebaut..."
:V302g1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Bitte warten!"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Seite wird aufgebaut..."
			b PLAINTEXT,NULL

;*** Texte für Datei-Info.
:V302h0			b PLAINTEXT,REV_ON
			b "Datei:         .   ",PLAINTEXT,NULL
:V302h1			b "Datum : ",NULL
:V302h2			b "Größe : ",NULL
:V302h3			b " Byte(s)",NULL
:V302h4			b "Schreibschutz: ",NULL
:V302h5			b "Nicht aktiv",NULL
:V302h6			b "Aktiv",NULL
:V302h7			b "Versteckt    : ",NULL
:V302h8			b "Nein",NULL
:V302h9			b "Ja",NULL
:V302h10		b "System-Datei : ",NULL

;*** Titel für Verzeichnis drucken.
:V302i0			b PLAINTEXT,REV_ON
			b "Verzeichnis drucken",PLAINTEXT,NULL

;*** Text für Druck-Box.
:V302i1			b PLAINTEXT,BOLDON
			b "Ausdruck des aktuellen Verzeichnisses."
			b GOTOXY
			w 48
			b 98
			b "Anzahl Zeilen pro Seite:"
			b GOTOXY
			w 60
			b 114
			b "Einzelblatt-Papier verwenden"
			b GOTOXY
			w 48
			b 80
			b "Drucker: ",NULL

;*** Box für "Anzahl Zeilen/Seite"
:V302i2			b MOVEPENTO
			w 216
			b 90
			b FRAME_RECTO
			w 247
			b 101
:V302i3			b NEWPATTERN, $00
			b MOVEPENTO
			w 217
			b 91
			b RECTANGLETO
			w 246
			b 100
			b NULL

;*** Auswahl: "Einzelblatt-Papier"
:V302i4			b NEWPATTERN, $00
			b MOVEPENTO
			w 48
			b 107
			b RECTANGLETO
			w 55
			b 114
			b FRAME_RECTO
			w 48
			b 107
			b NULL

;*** Info: "Seite wird gedruckt..."
:V302i5			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Bitte warten!"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Seite wird gedruckt..."
			b PLAINTEXT,NULL

;*** Hinweis: "Bitte neues Blatt Papier einlegen!"
:V302i6			b $01
			b 56,127
			w 64,255
			b OK        ,  2, 48
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V302i7a
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V302i7b
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V302i7a		b PLAINTEXT,BOLDON
			b "Bitte ein neues Blatt",NULL
:V302i7b		b "Papier einlegen!",NULL

;*** Info: "Druckertreiber wird geladen..."
:V302i8			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Druckertreiber wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "geladen..."
			b PLAINTEXT,NULL

;*** Hinweis: "Kann Druckertreiber nicht finden!"
:V302i9			b $01
			b 56,127
			w 64,255
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V302i10a
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V302i10b
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V302i10a		b PLAINTEXT,BOLDON
			b "Kann Druckertreiber",NULL
:V302i10b		b "nicht finden!",NULL

;*** Hinweis: "Drucker nicht ansprechbar!"
:V302i11		b $01
			b 56,127
			w 64,255
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V302i12a
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V302i12b
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V302i12a		b PLAINTEXT,BOLDON
			b "Drucker ist nicht",NULL
:V302i12b		b "ansprechbar !",NULL

;*** Titel: "Drucker wählen".
:V302i13		b PLAINTEXT,REV_ON
			b "Drucker wählen",PLAINTEXT,NULL

;*** Variablen & Texte für "Directory drucken".
:V302j0			b $40				;Anzahl Zeilen / Seite.
:V302j1			b $00				;Zähler für Zeilen während Druckvorgang...
:V302j2			b $00				;Anzahl Einträge in Dir-Sektor.
:V302j3			b $00				;Seiten-Nr.

:V302k0			s $06				;Speicher für Icon-Daten.
:V302k1			s $05				;Speicher für DOS-Datum.

:V302l0			b "       geoDOS - Directory                   Erstellt am "
			b "xx.xx.xx um xx:xx Uhr",$0d,NULL
:V302l1			b "       Diskette: xxxxxxxxxxx                            "
			b "            Seite: xx",$0d,$0d,NULL
:V302l2			b "       Datei-Name    Länge      Datum     Zeit   "
			b "Attribute",$0d,NULL
:V302l3			b "       ------------------------------------------"
			b "----------------------------",$0d,NULL

:V302l4			b "       Anzahl Dateien im Verzeichnis : xxxxxxxx",$0d,NULL
:V302l5			b "       Bytes im Verzeichnis          : xxxxxxxx"
			b " Bytes",$0d,NULL
:V302l6			b "       Belegter Speicher             : xxxxxxxx"
			b " Bytes",$0d,NULL
:V302l7			b "       Freie Cluster                 : xxxxxxxx",$0d,NULL
:V302l8			b "       Verfügbarer Speicher          : xxxxxxxx"
			b " Bytes",$0d,NULL
:V302l9			b "       Speicher gesamt               : xxxxxxxx"
			b " Bytes",$0d,NULL

:V302m0			b "Read-Only",NULL
:V302m1			b "Versteckt",NULL
:V302m2			b "System",NULL
:V302m3			b "Hauptverzeichnis           ",NULL
:V302m4			b "Verzeichnis:",NULL

;*** Startadresse Zwischenspeicher.
;    Directory der aktuellen Diskette.
;    Auswahl Druckertreiber.
;    Berechnung Druckdaten.
:V302z0
:V302z1			= (V302z0 / 256 +1) * 256
