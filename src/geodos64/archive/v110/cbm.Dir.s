; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L402: Verzeichnis ausgeben.
;Max. Anzahl GEOS-Filetypen. Der letzte Datei-Typ ist "GEOS ???".
:LastGEOSType		= 23
:SetCMDRoot		= $9050				;Nur gateWay! Hauptverzeichnis aktivieren.
:SetCMD_Dir		= $9053				;Nur gateWay! Verzeichnis aktivieren.

:CBM_Dir		MoveW	otherPressVec,VekBuf1
			LoadB	icon_Tab1,9		;Bei RAM-Laufwerk und CMD HD keinen

			lda	curDrvType		;Diskwechsel erlauben.
			cmp	#Drv_CMDHD
			beq	:1
			ldx	curDrive
			lda	DriveModes-8,x
			and	#%00001000
			beq	:2
::1			jsr	i_MoveData
			w	icon_Tab1b,icon_Tab1a
			w	icon_Tab1End-icon_Tab1b
			dec	icon_Tab1

::2			lda	curDrvMode
			bmi	:3
			CmpBI	icon_Tab1,9
			beq	:2a

			jsr	i_MoveData
			w	icon_Tab1b,icon_Tab1a
			w	icon_Tab1End-icon_Tab1b
			dec	icon_Tab1
			jmp	:3

::2a			jsr	i_MoveData
			w	icon_Tab1c,icon_Tab1b
			w	icon_Tab1End-icon_Tab1c
			dec	icon_Tab1

::3			LoadW	r0,icon_Tab1a
			ldx	icon_Tab1
			ldy	#$02
			lda	#$07
::4			sta	(r0L),y
			add	3
			pha
			AddVBW	8,r0
			pla
			dex
			cpx	#$04
			bne	:4

			ldx	#$00			;Diskette einlegen.
			b $2c
:GetDisk		ldx	#$ff
			lda	curDrive
			jsr	InsertDisk
			cmp	#$01
			beq	:1
			jmp	L402ExitGD

::1			jsr	SaveCMD_Dir		;Native-Mode-Verzeichnis speichern.

:GetDir			jsr	CBM_GetDskNam		;Disk-Name ermitteln.
			jsr	UseGDFont
			jsr	SetWin			;Directory-Fenster aufbauen.

;*** Ausgabe der ersten Directory-Seite.
:Start_Dir		jsr	PrnDskName		;BAM einlesen.
			jsr	ClrDirCount		;Directory-Zähler löschen.
			lda	#$00
			sta	V402a2			;Zeiger "Directory-Ende" löschen.
			sta	V402a5			;Zeiger innerhalb Sektor löschen.
			sta	RAM_Modify		;Flag für Directory neu lesen.
			lda	curDirHead +0		;Zeiger auf ersten Directory-Sektor.
			sta	V402a4+0
			lda	curDirHead +1
			sta	V402a4+1
			LoadW	otherPressVec,SlctFile

;*** Ausgabe der nächsten Directory Seite.
:ShowNxFiles		jsr	NextPage

;*** Directory-Icons aktivieren.
:DoDirIcons		LoadW	r0,icon_Tab1
			jsr	DoIcons
			StartMouse
			NoMseKey
			rts

;*** Anderes Laufwerk.
:L402ExitDrv		jsr	LoadCMD_Dir
			jsr	ClrWin
			jmp	m_CBM_Dir +3

;*** Partition wechseln.
:L402OtherPart		MoveB	VekBuf1,otherPressVec
			jsr	ClrWin
			jsr	LoadCMD_Dir
			ldx	#$01
			jmp	m_SlctPart1

;*** Zurück zu geoDOS.
:CMD_RootDir		jsr	ResetDirHead
			bne	L402ExitGD
			jmp	Start_Dir

:L402ExitGD		jsr	LoadCMD_Dir
			SetColRam36,202,$b1
			jmp	InitScreen

;*** Directory-Zähler löschen.
:ClrDirCount		lda	#$00
			sta	UsedBlocks+0		;Anzahl Blocks in Directory löschen.
			sta	UsedBlocks+1
			sta	DirFiles+0		;Anzahl Files in Directory löschen.
			sta	DirFiles+1
			rts

;*** Dateigrößen addieren.
:AddBlocks_a		ldy	#$1f			;Datei-Größe aus aktuellem
							;Directory-Eintrag im RAM holen.
			lda	(a7L),y			;Datei-Größe High-Byte.
			tax
			dey
			lda	(a7L),y			;Datei-Größe Low-Byte.
:AddBlocks_b		clc				;Datei-Größe zum Gesamtzähler
			adc	UsedBlocks+0		;belegter Sektoren addieren.
			sta	UsedBlocks+0
			txa
			adc	UsedBlocks+1
			sta	UsedBlocks+1
:IncFiles		IncWord	DirFiles		;Anzahl Einträge im Directory +1.
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
			FillRec	177,183,16,311
			FillRec	48,183,303,311

			FillRec	40,47,16,302
			SetColRam36,202,$61
			rts

;*** Disketten-Namen ausgeben.
:PrnDskName		jsr	GetDirHead
			txa
			beq	:1
			jmp	DiskError

::1			jsr	CBM_GetDskNam		;Disk-Name ermitteln.
			jsr	UseGDFont
			PrintXY	24,46,V402d0
			PrintStrgcbmDiskName
			LoadB	currentMode,NULL
			rts

;*** Directory-Fenster löschen und
;    ":otherPressVec" wieder herstellen.
:ClrWin			MoveW	VekBuf1,otherPressVec
			Display	ST_WR_FORE ! ST_WR_BACK

;*** Bitmap löschen.
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

;*** Ausgabe einer Directory-Seite.
:NextPage		jsr	DoInfoBox		;Infobox aufbauen.
			PrintStrgV402b0

			jsr	ClrBackWin

			lda	V402a2			;Directory-Ende erreicht ?
			bne	:2			;Ja, Directory-Infos ausgeben.

			jsr	ReadFiles		;16 Einträge einlesen.
			lda	V402a1			;Directory-Ende erreicht ?
			beq	:2			;Ja, Directory-Infos ausgeben.

			LoadW	a7,V402z2		;Zeiger innerhalb des Sektors setzen.
			LoadB	V402c0,54		;Y-Pos. für Ausgabe Directory-Eintrag.
			ClrB	V402a0

::1			jsr	DoFile			;Eintrag ausgeben.
			jsr	AddBlocks_a		;Dateigrößen addieren, Anzahl Files +1.

			AddVBW	32,a7			;Zeiger auf nächsten Directory-

			inc	V402a0
			CmpB	V402a0,V402a1		;Alle Einträge ausgegeben ?
			bne	:1			;Nein, weiter...

			jmp	:3			;Daten auf Bildschirm darstellen.

;*** Abschluß-Infos erzeugen.
::2			MoveW	VekBuf1,otherPressVec
			jsr	GetDirInfo		;Directory-Info-Seite erstellen.

;*** Daten auf Bildschirm darstellen.
::3			jsr	CSet_Grau

			jsr	i_RecoverRectangle
			b	48,175
			w	9,302

			Display	ST_WR_FORE
			rts

;*** 16 weitere Files einlesen.
:ReadFiles		LoadW	r15,V402z2		;Zeiger auf Anfang Zwischenspeicher.

			ClrB	V402a1
			jsr	i_FillRam		;Startadressen für Position der
			w	16*2,V402a3		;"Directory-Einträge im RAM" löschen.
			b	$00

			MoveB	V402a4+0,r1L		;Sektor-Adresse Einlesen.
			MoveB	V402a4+1,r1H
::1			LoadW	r4,diskBlkBuf		;Directory-Sektor einlesen.
			jsr	GetBlock
			txa
			beq	:2
			jmp	DiskError

::2			MoveB	V402a5,r4L		;Zeiger auf nächsten Eintrag.

::3			CmpBI	V402a1,16		;16 Einträge eingelesen ?
			beq	:7			;Ja, Ende...

			ldy	#$02			;Prüfen ob Eintrag gültig.
			lda	(r4L),y
			bpl	:5			;Ungültig, nächster Eintrag.

			ldy	#$1f			;Eintrag in das RAM kopieren.
::4			lda	(r4L),y
			sta	(r15L),y
			dey
			bpl	:4

			lda	V402a1			;Anfangsadresse des aktuellen
			asl				;Directory-Eintrags in Tabelle
			tax				;eintragen.
			lda	r15L
			sta	V402a3 +0,x
			lda	r15H
			sta	V402a3 +1,x
			inc	V402a1			;Anzahl Einträge auf Seite erhöhen.

			AddVBW	32,r15

::5			AddVB	32,r4L			;Zeiger auf nächsten Eintrag richten.
			sta	V402a5
			cmp	#$00			;Alle Einträge des aktuellen Sektors
			bne	:3			;gelesen ? Nein, weiter...

			lda	diskBlkBuf+0		;Zeiger auf nächsten Directory-
			beq	:6			;Sektor richten.
			sta	r1L
			sta	V402a4+0
			lda	diskBlkBuf+1
			sta	r1H
			sta	V402a4+1
			jmp	:1

::6			LoadB	V402a2,$ff		;Directory-Ende kennzeichnen.
::7			rts

;*** Datei-Eintrag ausgeben.
:DoFile			LoadW	r11,16			;X-Pos. auf Startwert setzen.
			MoveB	V402c0,r1H		;Y-Pos. setzen.

			lda	#$05			;Zeiger auf Anfang Datei-Name.
::1			pha
			tay
			lda	(a7L),y			;Zeichen aus Datei-Name holen.
			cmp	#$20			;Nur Zeichen zwischen $20 bis $7f
			bcc	:2			;ausgeben (GEOS-Zeichenbereich), die
			cmp	#$7f			;anderen Zeichen durch $20 ersetzen.
			bcc	:3
			cmp	#$a0			;anderen Zeichen durch $20 ersetzen.
			beq	:21
::2			lda	#"-"
			b $2c
::21			lda	#" "
::3			jsr	SmallPutChar		;Zeichen ausgeben.
			pla
			add	$01			;Zeiger auf nächstes Zeichen setzen.
			cmp	#$15			;Ende Name erreicht ?
			bne	:1			;Nein, weiter...

			AddVBW	18,r11			;X-Pos. korrigieren.

			jsr	InitForBA		;Datei-Größe berechnen.
			ldy	#$1f
			lda	(a7L),y
			tax
			dey
			lda	(a7L),y
			jsr	Word_FAC
			jsr	x_FLPSTR		;Größe in ASCII-String wandeln.
			jsr	DoneWithBA

			ldy	#$05			;Datei-Größe ausgeben.
			jsr	Do_ZFAC

			AddVBW	12,r11			;X-Pos. korrigieren.

			jsr	Print_DT		;Datum und Uhrzeit ausgeben.
			AddVBW	8,V402c0		;Y-Pos für Ausgabezeile korrigieren.
			rts

;*** Datum & Uhrzeit ausgeben.
:Print_DT		ldy	#$1b			;Ausgabe: Tag
			lda	(a7L),y
			tay
			lda	#$02
			jsr	Do_Zahl

			lda	#$2e
			jsr	SmallPutChar

			ldy	#$1a			;Ausgabe: Monat
			lda	(a7L),y
			tay
			lda	#$02
			jsr	Do_Zahl

			lda	#$2e
			jsr	SmallPutChar

			ldy	#$19			;Ausgabe: Jahr
			lda	(a7L),y
			tay
			lda	#$02
			jsr	Do_Zahl

			AddVBW	12,r11

			ldy	#$1c			;Ausgabe: Stunde
			lda	(a7L),y
			tay
			lda	#$02
			jsr	Do_Zahl

			lda	#$3a
			jsr	SmallPutChar

			ldy	#$1d			;Ausgabe: Minute
			lda	(a7L),y
			tay
			lda	#$02
			jmp	Do_Zahl

;*** Diskettenkapazitäten ausgeben.
:GetDirInfo		Display	ST_WR_BACK

			jsr	InitForBA		;Anzahl Dateien im Verzeichnis in
			LoadFAC	DirFiles		;ASCII-String wandeln.
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl Dateien ausgeben.
			PrintXY	16,64,V402e0
			jsr	PutInfoEntry

			jsr	InitForBA		;Anzahl belegter Blöcke im
			LoadFAC	UsedBlocks		;Directory in ASCII-String wandeln.
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl belegter Blöcke ausgeben.
			PrintXY	16,76,V402e1
			jsr	PutInfoEntry

			jsr	GetCurDskBAM		;BAM der aktuellen Diskette einlesen.
			jsr	InitForBA		;Anzahl belegter Blöcke auf
			sec				;Diskette in ASCII-String wandeln.
			lda	r3L
			sbc	r4L
			tay
			lda	r3H
			sbc	r4H
			tax
			tya
			jsr	Word_FAC
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl belegter Blöcke ausgeben.
			PrintXY	16,88,V402e2
			jsr	PutInfoEntry

			jsr	GetCurBAMInfo
			jsr	InitForBA		;Anzahl freier Sektoren in
			LoadFAC	r4			;ASCII-String wandeln.
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Anzahl freier Sektoren ausgebn.
			PrintXY	16,100,V402e3
			jsr	PutInfoEntry

			jsr	GetCurBAMInfo		;BAM-Werte berechnen.
			jsr	InitForBA		;Gesamt-Anzahl Sektoren auf Diskette
			LoadFAC	r3			;in ASCII-String wandeln.
			jsr	x_FLPSTR
			jsr	DoneWithBA

			jsr	UseSystemFont		;Gesamt-Anzahl Sektoren ausgeben.
			PrintXY	16,112,V402e4
			jsr	PutInfoEntry

			jsr	UseSystemFont
			PrintXY	16,132,V402e5
			rts

;*** Cursor positionieren und Zahlenwert ausgeben..
:PutInfoEntry		LoadW	r11,184			;Cursor-Position für Doppelpunkt.

			lda	#":"			;Doppelpunkt setzen.
			jsr	SmallPutChar

			LoadB	currentMode,0		;Schriftstile löschen.
			LoadW	r11,192			;Cursor-Position für Directory-Daten.
			jsr	UseGDFont		;geoDOS-Font aktivieren.

			ldy	#$07			;Zahlenwert ausgeben.
			jsr	Do_ZFAC
			rts

;*** BAM der aktuellen Diskette einlesen.
:GetCurDskBAM		jsr	GetDirHead
:GetCurBAMInfo		LoadW	r5,curDirHead
			jsr	CalcBlksFree
			rts

;*** CMD-Laufwerk testen.
:TestCMD_Drv		ldy	curDrive
			lda	DriveModes-8,y
			and	#%00100000
			rts

;*** CMD-Verzeichnis speichern.
:SaveCMD_Dir		jsr	TestCMD_Drv
			beq	:1
			jsr	GetDirHead
			lda	curDirHead+$20
			sta	V402a6 +0
			lda	curDirHead+$21
			sta	V402a6 +1
::1			rts

;*** CMD-Verzeichnis speichern.
:LoadCMD_Dir		jsr	TestCMD_Drv
			beq	:1
			MoveW	V402a6,r1
			jsr	SetCMD_Dir
::1			rts

;*** Verzeichnis-Kopf einlesen.
:ResetDirHead		jsr	TestCMD_Drv
			beq	:1
			jsr	SetCMDRoot
			lda	#$00
			b $2c
::1			lda	#$ff
			rts

;*** Neues CMD-Verzeichnis öffnen.
:NewCMD_Dir		ldy	#$03
			lda	(a6L),y
			sta	r1L
			iny
			lda	(a6L),y
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:1
			jmp	DiskError

::1			lda	diskBlkBuf+0
			sta	V402a4    +0
			lda	diskBlkBuf+1
			sta	V402a4    +1
			ClrB	V402a2

			ldy	#$03
			lda	(a6L),y
			sta	r1L
			iny
			lda	(a6L),y
			sta	r1H
			jsr	SetCMD_Dir
			txa
			beq	:2
			jmp	DiskError

::2			rts

;*** Datei auswählen und Infos darstellen..
:SlctFile		NoMseKey

			LoadB	r2L,48			;Prüfen ob Datei-Eintrag
			LoadB	r2H,175			;angelickt wurde.
			LoadW	r3,9
			LoadW	r4,302
			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			bne	:1
			rts				;Mausklick außerhalb Directory-Seite.

::1			lda	mouseYPos		;Zeiger auf aktuellen Eintrag
			lsr				;berechnen.
			lsr
			lsr
			sub	$06
			asl
			tax
			lda	V402a3 +0,x		;Startadresse des Eintrags im
			sta	a6L			;RAM ermitteln.
			lda	V402a3 +1,x
			sta	a6H
			bne	:2			;Adresse = $0000 ?
			rts				;Ja, kein gültiger Eintrag.

;*** Native-Mode-Verzeichnis ?
::2			jsr	TestCMD_Drv
			beq	EntryIsFile

			ldy	#$02
			lda	(a6L),y
			and	#%00000111
			cmp	#$06
			bne	EntryIsFile
			jsr	NewCMD_Dir
			jsr	PrnDskName
			jmp	ShowNxFiles

;*** Datei-Informationen ausgeben.
:EntryIsFile		jsr	HideWin

			ldy	#$05			;Name der Datei in Titel-Zeile
			ldx	#$00			;eintragen.
::1			lda	(a6L),y
			cmp	#$20
			bcc	:2
			cmp	#$7f
			bcc	:4
			cmp	#$a0
			beq	:3
::2			lda	#"-"
			b $2c
::3			lda	#" "
::4			sta	V402f0+9,x
			iny
			inx
			cpx	#$10
			bne	:1

			LoadW	r0,V402f0		;Info-Fenster öffnen.
			jsr	SetExtraWin

			LoadW	r11,248			;Datei-Typ ausgeben.
			ldy	#$02
			lda	(a6L),y
			and	#%00000111
			asl
			asl
			sta	r15L
			LoadB	r15H,4
::5			ldy	r15L
			lda	V402l0,y
			jsr	SmallPutChar
			inc	r15L
			dec	r15H
			bne	:5
			ClrB	currentMode

;*** Datei-Informationen ausgeben.
:DoFileInfo		ldy	#$15			;Einlesen von Spur und Sektor des
			lda	(a6L),y			;Info-Blocks.
			sta	V402f1			;Flag für "Info-Block vorhanden".
			beq	:1			;Falls Spur = 0, Kein Info-Block.
			sta	r1L
			iny
			lda	(a6L),y
			sta	r1H
			LoadW	r4,fileHeader		;Zeiger auf Speicher für Info-Block.
			jsr	GetBlock		;Info-Block einlesen.
			txa
			beq	:1
			jmp	DiskError

::1			PrintXY	40,68,V402g0		;Datei-Format.
			LoadW	r0,V402h0		;Text für "Commodore-Format".
			ldy	#$18
			lda	(a6L),y
			beq	:2
			LoadW	r0,V402h1		;Text für "GEOS-Sequentiell".
			lda	fileHeader +$46
			beq	:2
			LoadW	r0,V402h2		;Text für "GEOS-VLIR".
::2			jsr	PutString		;Datei-Format ausgeben.

			PrintXY	40,77,V402g1		;GEOS-Datei-Typ.
			lda	V402f1			;Falls keine GEOS-Datei, überspringen.
			beq	:3
			lda	fileHeader +$45
			cmp	#LastGEOSType		;Wert kleiner 22 ?
			bcc	:3			;Ja, weiter...
			lda	#LastGEOSType		;Nein, Datei ist "Nicht GEOS".
::3			asl				;Zeiger auf Text für GEOS-Typ
			tax				;berechnen.
			lda	V402i0 +0,x		;Startadresse Text einlesen.
			sta	r0L
			lda	V402i0 +1,x
			sta	r0H
			jsr	PutString		;GEOS-Datei-Typ ausgeben.

			PrintXY	40,86,V402g2		;Klasse.
			lda	V402f1			;Falls keine GEOS-Datei, überspringen.
			beq	:5
			lda	#$00
::4			pha
			tax
			lda	fileHeader +$4d,x
			bne	:41
			pla
			jmp	:5
::41			jsr	SmallPutChar
			pla
			add	$01
			cmp	#$12
			bne	:4

::5			PrintXY	40,95,V402g3		;Autor.
			lda	V402f1			;Falls keine GEOS-Datei, überspringen.
			beq	:7
			ldy	#19
::51			lda	fileHeader +$61,y
			beq	:52
			cmp	#$20			;Auf gültigen Autoren-Namen testen.
			bcc	:7
			cmp	#$7f
			bcs	:7
::52			dey
			bpl	:51
			lda	#$00
::6			pha
			tax
			lda	fileHeader +$61,x
			bne	:61
			pla
			jmp	:7
::61			jsr	SmallPutChar
			pla
			add	$01
			cmp	#$14
			bne	:6

::7			PrintXY	40,104,V402g4		;Datum & Zeit.
			PushW	a7
			MoveW	a6,a7
			jsr	Print_DT
			PopW	a7

			PrintXY	40,113,V402g5		;Dateigröße ausgeben.
			ldy	#$1e
			lda	(a6L),y			;Dateigröße aus Directory-Eintrag
			sta	r0L			;einlesen und merken.
			iny
			lda	(a6L),y
			sta	r0H
			lda	#%11000000
			jsr	PutDecimal		;Word ausgeben.
			LoadW	r0,V402g6
			jsr	PutString

;*** Ausgabe der Datei-Informationen (Fortsetzung).
			PrintXY	40,122,V402g7		;GEOS-Modus ausgeben
			lda	V402f1			;Falls keine GEOS-Datei, überspringen.
			beq	:8
			lda	fileHeader +$60
			lsr
			lsr
			lsr
			lsr
			lsr
			lsr
			asl				;Zeiger auf Text für GEOS-Modus
			tax				;berechnen.
			lda	V402i1 +0,x
			sta	r0L
			lda	V402i1 +1,x
			sta	r0H
			jsr	PutString		;GEOS-Modus ausgeben.

::8			PrintXY	40,131,V402g8		;Schreibschutz.
			LoadW	r0,V402m0		;Text für "Schreibschutz nicht aktiv".
			ldy	#$02
			lda	(a6L),y
			and	#%01000000
			beq	:9
			LoadW	r0,V402m0		;Text für "Schreibschutz nicht aktiv".
::9			jsr	PutString		;Schreibschutz-Modus ausgeben.

			lda	V402f1			;Falls keine GEOS-Datei, überspringen.
			beq	:10
			LoadW	r0,fileHeader +4
			LoadB	r1L,5			;Position für Datei-Icon.
			LoadB	r1H,142
			lda	fileHeader +2		;Größe des Datei-Icons.
			sta	r2L
			lda	fileHeader +3
			sta	r2H
			jsr	BitmapUp		;Datei-Icon ausgaben.
			jsr	UseSystemFont
			PrintXY	72,150,V402n0

::10			LoadW	r0,icon_Tab2		;Icons aktivieren.
			jsr	DoIcons
			StartMouse			;Maus aktivieren.
			NoMseKey
			rts

;*** Datei-Info-Box oder Drucker-Box schließen.
:ExitPrintDir
:ExitFileInfo		jsr	ClrExtraWin
			LoadW	otherPressVec,SlctFile

			lda	RAM_Modify
			bne	:1

			jsr	ShowWin
			jmp	DoDirIcons

::1			jmp	GetDir

;*** Directory drucken.
:PrintDir		jsr	HideWin			;Directory-Fenster löschen.

			LoadW	r0,V402o0
			jsr	SetExtraWin
			jsr	UseSystemFont

			PrintXY	48,70,V402o1		;Text für Drucker-Box ausgeben.
			LoadW	r0,PrntFileName
			jsr	PutString

			LoadW	r0,V402o2		;Anzahl Zeilen/Seite ausgeben.
			jsr	GraphicsString
			jsr	PrintLines
			LoadW	r0,V402o4		;Papier-Modus ausgeben.
			jsr	GraphicsString
			LoadW	r0,V402o5		;Papier-Modus ausgeben.
			jsr	GraphicsString

			LoadW	otherPressVec,SlctPaper
			LoadW	r0,icon_Tab3		;Icons aktivieren.
			jsr	DoIcons
			rts

;*** Icon-Position speichern.
:SaveIconPos		ldx	#$05
::1			lda	r2L,x
			sta	V402q0,x
			dex
			bpl	:1
			rts

;*** Icon-Position laden.
:LoadIconPos		ldx	#$05
::1			lda	V402q0,x
			sta	r2L,x
			dex
			bpl	:1
			rts

;*** Eine Zeile weniger...
:Sub1Line		jsr	SaveIconPos
			jsr	InvertRectangle
::1			ldx	V402p0
			cpx	#15
			beq	:2
			dec	V402p0
			jsr	PrintLines
			lda	mouseData
			bpl	:1
::2			jsr	LoadIconPos
			jsr	InvertRectangle
			rts

;*** Eine Zeile mehr...
:Add1Line		jsr	SaveIconPos
			jsr	InvertRectangle
::1			ldx	V402p0
			cpx	#255
			beq	:2
			inc	V402p0
			jsr	PrintLines
			lda	mouseData
			bpl	:1
::2			jsr	LoadIconPos
			jsr	InvertRectangle
			rts

;*** Anzahl Zeilen pro Seite ausgeben.
:PrintLines		LoadW	r0,V402o2		;Anzeige-Feld löschen.
			jsr	GraphicsString

			LoadB	currentMode,64		;Anzahl Zeilen ausgeben.
			LoadW	r11,223
			LoadB	r1H,98
			MoveB	V402p0,r0L
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
			beq	SlctDirType

			lda	V402o4+1		;Papier-Modus wechseln.
			eor	#$02
			sta	V402o4+1

			LoadW	r0,V402o4
			jsr	GraphicsString

			NoMseKey
			rts

;*** Directory lang-/kurzform...
:SlctDirType		LoadB	r2L,123			;Testen ob Maus innerhalb
			LoadB	r2H,130			;Auswahl-Icon.
			LoadW	r3,48
			LoadW	r4,55
			php
			sei
			jsr	IsMseInRegion
			plp
			tax
			bne	:1
			rts				;Nein, Mausklick ignorieren.

::1			lda	V402o5+1		;Papier-Modus wechseln.
			eor	#$02
			sta	V402o5+1

			LoadW	r0,V402o5
			jsr	GraphicsString

			NoMseKey
			rts

;*** Drucker wählen.
:SlctPrinter		jsr	ClrExtraWin		;Drucker-Box löschen.
			jsr	GetStartDrv
			LoadB	RAM_Modify,$ff		;Directory im RAM als "zerstört"
							;kennzeichnen.

			LoadB	r7L,PRINTER		;Druckertreiber suchen.
			LoadB	r7H,255
			LoadW	r10,$0000
			LoadW	r6,V402z0
			jsr	FindFTypes
			txa
			beq	:1
			jmp	DiskError

::1			jsr	GetWorkDrv
			CmpBI	r7H,255			;Druckertreiber gefunden ?
			bne	:3			;Ja, Drucker auswählen.
::2			jmp	PrintDir		;Zurück zum Druck-Modus.

::3			lda	#<V402z0		;Datei-Namen der Druckertreiber
			sta	r0L			;in 16-Byte-Format wandeln.
			sta	r1L
			lda	#>V402z0
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

			LoadW	r14,V402o14		;Drucker-Auswahlbox.
			LoadW	r15,V402z0
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

			jsr	DoInfoBox
			PrintStrgV402o9

			jsr	GetStartDrv
			LoadW	r6,PrntFileName
			LoadB	r0L,0
			jsr	GetFile			;Drucker-Treiber laden.
			txa
			beq	:2
			cpx	#$05			;Fehler: Treiber nicht gefunden ?
			beq	:1			;Ja, Meldung ausgeben.
			jmp	DiskError

::1			jsr	GetWorkDrv
			jsr	ClrBox
			LoadW	r0,V402o10		;Fehler: "Druckertreiber nicht ..."
			ClrDlgBoxCSet_Grau
			jsr	ShowWin			;Directory-Seite wieder aufbauen.
			jmp	DoDirIcons		;Zurück zum Directory-Modus.

;*** Directory-Ausdruck initialisieren.
::2			jsr	GetWorkDrv
			jsr	ClrBox

			lda	#$00
			sta	V402p2			;Zeiger für Eintrag in Sektor auf 0.
			sta	V402p3			;Zähler für Seiten-Nr. auf 0.
			jsr	ClrDirCount
			jsr	Get1stDirEntry

			ldy	#$00			;Titel-Zeile in Zwischenspeicher.
::3			lda	V402r0,y
			sta	V402z0,y
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
::5			lda	V402z0,y
			sta	V402r0,y
			beq	:6
			iny
			bne	:5
::6			ldy	#$00			;Disketten-Name in Titel-Zeile
::7			lda	cbmDiskName,y		;eintragen.
			cmp	#$a0
			bne	:8
			lda	#" "
::8			sta	V402r1+17,y
			iny
			cpy	#$10
			bne	:7

			StartMouse
			NoMseKey

;*** Einzelne Seite drucken.
:NewPage		jsr	PrintHeader		;Seiten-Kopf drucken.
::1			lda	pressFlag		;Drucken abbrechen ?
			bne	:7			;Ja, zurück zum Directory-Modus.

			ldx	V402o5+1
			bne	:2
			CmpBI	V402p1,1
			bcs	:3
			jmp	:5
::2			CmpBI	V402p1,3
			bcs	:3
			jmp	:5

::3			jsr	GetDirLine		;Einzelne Druck-Zeile erzeugen.
			bne	:6			;Directory-Ende, Infos drucken.

			ldy	#$1f			;Datei-Größe addieren.
			lda	(r4L),y
			tax
			dey
			lda	(r4L),y
			jsr	AddBlocks_b
			jsr	PrnASCIILine		;Eintrag ausgeben.
			jsr	GetLDirLine		;Langes Directory erzeugen.
			beq	:4
			SubVB	2,V402p1
::4			dec	V402p1			;Seite voll ?
			jmp	:1

::5			jsr	StopPrint		;Seiten-Vorschub.
			jsr	ClrBox
			jsr	WaitNewPage		;Bei Einzel-Blatt, warten auf Papier.
			cmp	#$02			;Abbruch ?
			beq	:8			;Ja, Zurück zum Directory-Modus.
			jmp	NewPage			;Nein, nächste Seite.

::6			jsr	PrnDirInfo		;Directory-Informationen drucken.
::7			jsr	StopPrint		;Seiten-Vorschub...
			jsr	ClrBox
::8			jmp	GetDir			;Zurück zum Directory-Modus.

;*** ASCII-Zeile drucken.
:PrnASCIILine		LoadW	r0,V402z0
:PrnTempLine		LoadW	r1,V402z2
			jmp	PrintASCII

;*** Eintrag erzeugen.
:GetDirLine		ldx	V402p2			;Alle Einträge eines Sektors
			cpx	#$08			;gedruckt ?
			bne	:3			;Nein, weiter...
			lda	diskBlkBuf+0		;Nächsten Directory-Sektor einlesen.
			bne	:1
			lda	#$ff			;Directory-Ende.
			rts

::1			ldx	diskBlkBuf+1
			sta	r1L
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:2

			txa				;Fehler: Seiten-Vorschub...
			pha
			jsr	StopPrint
			pla
			tax
			jmp	DiskError		;...und Disketten-Fehler ausgeben.

::2			ldx	#$00			;Zeiger innerhalb des Directory-
::3			txa				;Sektors berechnen.
			inx
			stx	V402p2
			asl
			asl
			asl
			asl
			asl
			clc
			adc	#<diskBlkBuf
			sta	r4L
			lda	#>diskBlkBuf
			sta	r4H

			ldy	#$02
			lda	(r4L),y			;Datei-Typ-Byte einlesen.
			bpl	GetDirLine		;Typ < $80, ungültiger Eintrag.

			ldx	#$00
			lda	#$20			;Druckzeile mit 7 Leerzeichen
::4			sta	V402z0,x		;beginnen.
			inx
			cpx	#$07
			bne	:4

			ldy	#$05			;Datei-Name in Zwischenspeicher.
::5			lda	(r4L),y
			cmp	#$20
			bcc	:51
			cmp	#$7f
			bcc	:6
			cmp	#$a0
			beq	:52

;*** Eintrag erzeugen (Fortsetzung).
::51			lda	#"-"
			b $2c
::52			lda	#" "
::6			sta	V402z0,x
			iny
			inx
			cpy	#$15
			bne	:5

			lda	#$20			;Zwei Leerzeichen einfügen.
			sta	V402z0+0,x
			sta	V402z0+1,x
			inx
			inx

			ldy	#$02
			lda	(r4L),y			;Datei-Typ-Byte einlesen.
			pha				;Byte merken.
			and	#%00000111		;Datei-Typ isolieren.
			asl
			asl
			tay
			LoadB	r0L,4
::7			lda	V402l0,y		;Datei-Typ in Zwischenspeicher.
			sta	V402z0,x
			inx
			iny
			dec	r0L
			bne	:7
			pla
			and	#%01000000		;Schreibschutz-Flag isolieren.
			beq	:8
			lda	#"*"			;Datei ist schreibgeschützt.
			bne	:9
::8			lda	#" "			;Datei ist nicht schreibgeschützt.
::9			sta	V402z0,x
			inx
			lda	#" "			;Ein Leerzeichen einfügen.
			sta	V402z0,x
			inx

			txa				;Zeiger innerhalb Zwischenspeicher
			pha				;merken.
			jsr	InitForBA		;Datei-Größe in ASCII-String
			ldy	#$1f			;wandeln.
			lda	(r4L),y
			tax
			dey
			lda	(r4L),y
			jsr	Word_FAC
			jsr	x_FLPSTR
			jsr	DoneWithBA
			pla				;Zeiger innerhalb Zwischenspeicher
			tax				;wieder herstellen.

			ldy	#$00			;Datei-Größe in Zwischenspeicher
::10			lda	$0100,y			;kopieren.
			beq	:11
			sta	V402z0,x
			inx
			iny
			bne	:10
::11			cpy	#$08			;Datei-Größe auf 8 Zeichen mit
			bcs	:12			;Leerzeichen auffüllen.
			lda	#" "
			sta	V402z0,x
			inx
			iny
			bne	:11

::12			ldy	#$1b			;Datum in Zwischenspeicher
			lda	(r4L),y			;übertragen.
			jsr	HexASCII_a
			lda	#"."
			sta	V402z0,x
			inx
			dey
			lda	(r4L),y
			jsr	HexASCII_a
			lda	#"."
			sta	V402z0,x
			inx
			dey
			lda	(r4L),y
			jsr	HexASCII_a

			lda	#" "			;Zwei Leerzeichen einfügen.
			sta	V402z0+0,x
			sta	V402z0+1,x
			inx
			inx

			ldy	#$1c			;Uhrzeit in Zwischenspeicher
			lda	(r4L),y			;übertragen.
			jsr	HexASCII_a
			lda	#":"
			sta	V402z0,x
			inx
			iny
			lda	(r4L),y
			jsr	HexASCII_a

			lda	#" "			;Zwei Leerzeichen einfügen.
			sta	V402z0+0,x
			sta	V402z0+1,x
			inx
			inx

;*** Eintrag erzeugen (Fortsetzung).
			ldy	#$18			;GEOS-Datei-Typ einlesen.
			lda	(r4L),y
			beq	:13
			cmp	#LastGEOSType
			bcc	:13
			lda	#LastGEOSType
::13			asl
			tay
			lda	V402i0 +0,y
			sta	r0L
			lda	V402i0 +1,y
			sta	r0H

			ldy	#$00
::14			lda	(r0L),y			;GEOS-Datei-Typ in Zwischenspeicher.
			beq	:15
			sta	V402z0,x
			inx
			iny
			bne	:14

::15			lda	#$0d			;Ende des Zwischenspeichers markieren.
			sta	V402z0,x
			lda	#$00
			sta	V402z0+1,x
			lda	#$00
			rts

;*** Directory-Informationen drucken.
:PrnDirInfo		lda	V402p1			;Noch Platz für 6 Zeilen ?
			cmp	#$08
			bcs	:2
			jsr	StopPrint		;Nein, Seiten-Vorschub...
			jsr	WaitNewPage		;Warten auf neue Seite.
			cmp	#$02			;Abbruch ?
			bne	:1			;Nein, Directory-Daten drucken.
			rts

::1			jsr	PrintHeader		;Bei neuer Seite, Seiten-Kopf drucken.
::2			LoadB	V402z0 +0,$0d		;Eine Leerzeile ausgeben.
			LoadB	V402z0 +1,$00
			jsr	PrnASCIILine

			LoadW	r0,V402r5		;Anzahl Dateien im Directory.
			MoveW	DirFiles,r1
			LoadB	r2L,38
			LoadB	r2H,6
			jsr	NumASCII
			jsr	PrnTempLine

			LoadW	r0,V402r6		;Anzahl Blocks im Directory.
			MoveW	UsedBlocks,r1
			LoadB	r2L,38
			LoadB	r2H,6
			jsr	NumASCII
			jsr	PrnTempLine

			jsr	GetCurDskBAM		;Disketten-Informationen einlesen.
			LoadW	r0,V402r7		;Anzahl belegter Blocks.
			sec
			lda	r3L
			sbc	r4L
			sta	r1L
			lda	r3H
			sbc	r4H
			sta	r1H
			LoadB	r2L,38
			LoadB	r2H,6
			jsr	NumASCII
			jsr	PrnTempLine

			jsr	GetCurBAMInfo
			LoadW	r0,V402r8		;Anzahl freier Sektoren.
			MoveW	r4,r1
			LoadB	r2L,38
			LoadB	r2H,6
			jsr	NumASCII
			jsr	PrnTempLine

			jsr	GetCurBAMInfo
			LoadW	r0,V402r9		;Gesamt-Anzahl Sektoren.
			MoveW	r3,r1
			LoadB	r2L,38
			LoadB	r2H,6
			jsr	NumASCII
			jsr	PrnTempLine

			LoadW	r0,V402r10		;Anschluß-Info.
			jsr	PrnTempLine
			rts

;*** Langes Directory.
:GetLDirLine		lda	V402o5+1
			bne	:1
			rts

::1			ldy	#$15			;Datei-Name in Zwischenspeicher.
::2			lda	(r4L),y
			bne	:3
			ldx	#$00
			jmp	:15

::3			sta	r1L
			iny
			lda	(r4L),y
			sta	r1H

			PushW	r4
			LoadW	r4,fileHeader
			jsr	GetBlock
			txa
			beq	:4
			jmp	DiskError

::4			PopW	r4

			ldy	#19
::5			lda	fileHeader +$61,y
			beq	:6
			cmp	#$20
			bcc	:7
			cmp	#$7f
			bcs	:7
::6			dey
			bpl	:5
			jmp	:8
::7			ldy	#19
			lda	#" "
::71			sta	fileHeader +$61,y
			dey
			bpl	:71
::8			ldx	#$07
			ldy	#$00
::9			lda	fileHeader +$61,y
			bne	:91
			lda	#" "
::91			sta	V402z0,x
			iny
			inx
			cpy	#20
			bne	:9

			ldy	#$05
			lda	#$20
::10			sta	V402z0+0,x
			inx
			dey
			bne	:10

			lda	fileHeader +$60
			lsr
			lsr
			lsr
			lsr
			lsr
			lsr
			asl				;Zeiger auf Text für GEOS-Modus
			tay				;berechnen.
			lda	V402i1 +0,y
			sta	r0L
			lda	V402i1 +1,y
			sta	r0H

			ldy	#$00
::11			lda	(r0L),y
			beq	:12
			sta	V402z0,x
			iny
			inx
			bne	:11
::12			lda	#$20
::13			sta	V402z0,x
			inx
			iny
			cpy	#$18
			bne	:13

			ldy	#$00
::14			lda	fileHeader +$4d,y
			beq	:15
			sta	V402z0,x
			iny
			inx
			cpy	#$12
			bne	:14

::15			lda	#$0d
			sta	V402z0+0,x
			lda	#$00
			sta	V402z0+1,x
			jsr	PrnASCIILine
			lda	#$0d
			sta	V402z0+0
			lda	#$00
			sta	V402z0+1
			jsr	PrnASCIILine

			lda	#$ff
			rts

;*** Seiten-Kopf drucken.
:PrintHeader		jsr	InitForPrint
			jsr	StartASCII
			txa
			beq	InitPage
			pla
			pla
:PrnNotReady		LoadW	r0,V402o12
			ClrDlgBoxCSet_Grau
			jmp	GetDir

:InitPage		jsr	SetNLQ
			jsr	InfoPrnPage

			inc	V402p3

			lda	V402p0
			sub	$05
			ldx	V402o5+1
			beq	:1
			sub	$01
::1			sta	V402p1
			lda	V402p3
			jsr	HexASCII_b
			sta	V402r1+76
			txa
			sta	V402r1+75

			LoadW	r0,V402r0
			jsr	PrnTempLine
			LoadW	r0,V402r1
			jsr	PrnTempLine
			LoadW	r0,V402r2
			jsr	PrnTempLine
			ldx	V402o5+1
			beq	:2
			LoadW	r0,V402r3
			jsr	PrnTempLine
::2			LoadW	r0,V402r4
			jmp	PrnTempLine

;*** Info: "Seite wird gedruckt..."
:InfoPrnPage		jsr	DoInfoBox
			PrintStrgV402o6
			rts

;*** Warten auf neues Blatt Papier...
:WaitNewPage		lda	V402o4 +1		;Einzelblatt-Modus ?
			beq	:1			;Ja, Info-Box.
			LoadW	r0,V402o7		;Warten auf neues Blatt Papier.
			ClrDlgBoxCSet_Grau
			lda	sysDBData
::1			rts

;*** HEX-Zahl nach ASCII wandeln.
:HexASCII_a		pha
			lda	#"0"			;Zehner-Stelle auf "0" setzen.
			sta	V402z0+0,x
			pla
::1			cmp	#$0a			;Zahl < 10 ?
			bcc	:2			;Ja, Ende...
			inc	V402z0,x		;Nein, Zehner-Stelle erhöhen.
			sub	10			;Zahl = Zahl -10.
			bne	:1			;Zahl = 0 ? Nein, weiter...
::2			add	$30			;ASCII-Zahl erzeugen und
			sta	V402z0+1,x		;Einer-Stelle setzen.
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
:NumASCII		jsr	InitForBA		;Zahl in ":r1" in ASCII-String ab
			LoadFAC	r1
			jsr	x_FLPSTR
			jsr	DoneWithBA

			ldy	r2L			;Zeiger auf Adresse für Zahlenstring.
			ldx	#$00
::1			lda	$0100,x			;ASCII-Zeichen aus Zahlenstring
			beq	:2			;einlesen. Zeichen = 0 ? Ja, Ende...
			sta	(r0L),y			;In Ziel-String eintragen.
			iny				;Weiter mit nächstem Zeichen.
			inx
			bne	:1
::2			cpx	r2H			;String auf gewünschte Länge mit
			bcs	:3			;Leerzeichen auffüllen.
			lda	#$20
			sta	(r0L),y
			iny
			inx
			bne	:2
::3			rts

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
			w	CMD_RootDir

			w	icon_Weiter
			b	1,16
			b	icon_Weiter_x,icon_Weiter_y
			w	ShowNxFiles

			w	icon_Root
			b	4,16
			b	icon_Root_x,icon_Root_y
			w	Start_Dir

:icon_Tab1a		w	icon_Disk
			b	7,16
			b	icon_Disk_x,icon_Disk_y
			w	GetDisk

:icon_Tab1b		w	icon_Partition
			b	10,16
			b	icon_Partition_x,icon_Partition_y
			w	L402OtherPart

:icon_Tab1c		w	icon_Drive
			b	13,16
			b	icon_Drive_x,icon_Drive_y
			w	L402ExitDrv

			w	icon_Print
			b	16,16
			b	icon_Print_x,icon_Print_y
			w	PrintDir

			w	icon_Ende
			b	19,16
			b	icon_Ende_x,icon_Ende_y
			w	L402ExitGD
:icon_Tab1End

;*** Icon-Tabelle für Datei-Info Box.
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
:icon_Weiter_x		= .x
:icon_Weiter_y		= .y

:icon_Root
<MISSING_IMAGE_DATA>
:icon_Root_x		= .x
:icon_Root_y		= .y

:icon_Disk
<MISSING_IMAGE_DATA>
:icon_Disk_x		= .x
:icon_Disk_y		= .y

:icon_Partition
<MISSING_IMAGE_DATA>
:icon_Partition_x	= .x
:icon_Partition_y	= .y

:icon_Drive
<MISSING_IMAGE_DATA>
:icon_Drive_x		= .x
:icon_Drive_y		= .y

:icon_Print
<MISSING_IMAGE_DATA>
:icon_Print_x		= .x
:icon_Print_y		= .y

:icon_Ende
<MISSING_IMAGE_DATA>
:icon_Ende_x		= .x
:icon_Ende_y		= .y

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

;*** Variablen.
:UsedBlocks		w $0000				;Anzahl belegter Blocks
:DirFiles		w $0000				;Anzahl Files
:VekBuf1		w $0000				;otherPressVektor
:RAM_Modify		b $00				;$FF = Dir im Speicher zerstört.

:V402a0			b $00				;Zähler: Anzahl Dateien auf aktueller Seite.
:V402a1			b $00				;Zähler: Anzahl Dateien im RAM-Speicher.
:V402a2			b $00				;$FF = Ende erreicht.
:V402a3			s 16*2				;Adr. Eintrag im RAM.
:V402a4			b $00,$00			;Nr. des aktuellen Directory-Sektors.
:V402a5			b $00				;Zeiger auf aktuellen Eintrag.
:V402a6			b $00,$00			;Zeiger auf CMD-Verzeichnis.

:V402b0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Bitte warten!"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Seite wird aufgebaut..."
			b PLAINTEXT,NULL

:V402c0			b $00				;Zeile für Ausgabe Dir-Eintrag.

:V402d0			b PLAINTEXT,REV_ON,"CBM: ",NULL

:V402e0			b PLAINTEXT,BOLDON,"Dateien im Verzeichnis",NULL
:V402e1			b PLAINTEXT,BOLDON,"Blocks im Verzeichnis belegt",NULL
:V402e2			b PLAINTEXT,BOLDON,"Blocks auf Diskette belegt",NULL
:V402e3			b PLAINTEXT,BOLDON,"Blocks auf Diskette verfügbar",NULL
:V402e4			b PLAINTEXT,BOLDON,"Blocks auf Diskette gesamt",NULL
:V402e5			b PLAINTEXT,BOLDON
			b "1 Block auf Disk entspricht 254 Bytes",NULL

:V402f0			b PLAINTEXT,REV_ON
			b "Datei:                 ",NULL
:V402f1			b $00

:V402g0			b "Format: ",NULL
:V402g1			b "Typ   : ",NULL
:V402g2			b "Klasse: ",NULL
:V402g3			b "Autor : ",NULL
:V402g4			b "Datum : ",NULL
:V402g5			b "Größe : ",NULL
:V402g6			b " Block(s)",NULL
:V402g7			b "Modus : ",NULL
:V402g8			b "Schreibschutz: ",NULL

:V402h0			b "Commodore",NULL
:V402h1			b "Sequentiell",NULL
:V402h2			b "GEOS - VLIR",NULL

:V402i0			w V402j0 ,V402j1 ,V402j2 ,V402j3 ,V402j4
			w V402j5 ,V402j6 ,V402j7 ,V402j8 ,V402j9
			w V402j10,V402j11,V402j12,V402j13,V402j14
			w V402j15,V402j99,V402j17,V402j99,V402j99
			w V402j99,V402j21,V402j22,V402j99

:V402i1			w V402k0 ,V402k1 ,V402k2 ,V402k3

:V402j0			b "Nicht GEOS",NULL
:V402j1			b "BASIC",NULL
:V402j2			b "Assembler",NULL
:V402j3			b "Datenfile",NULL
:V402j4			b "System-Datei",NULL
:V402j5			b "DeskAccessory",NULL
:V402j6			b "Anwendung",NULL
:V402j7			b "Dokument",NULL
:V402j8			b "Zeichensatz",NULL
:V402j9			b "Druckertreiber",NULL
:V402j10		b "Eingabetreiber",NULL
:V402j11		b "Disk-Driver",NULL
:V402j12		b "Startprogramm",NULL
:V402j13		b "Temporär",NULL
:V402j14		b "Selbstausführend",NULL
:V402j15		b "Eingabetreiber 128",NULL
:V402j17		b "gateWay-Dokument",NULL
:V402j21		b "geoShell-Kommando",NULL
:V402j22		b "geoFAX Druckertreiber",NULL
:V402j99		b "GEOS ???",NULL

:V402k0			b "GEOS 40 Zeichen",NULL
:V402k1			b "GEOS 40 & 80 Zeichen",NULL
:V402k2			b "GEOS 64",NULL
:V402k3			b "GEOS 128, 80 Zeichen",NULL

:V402l0			b "DEL SEQ PRG USR REL CBM DIR ??? "

:V402m0			b "Nicht aktiv",NULL
:V402m1			b "Aktiv",NULL

:V402n0			b PLAINTEXT,BOLDON
			b "Datei-"
			b GOTOXY
			w 72
			b 160
			b "Icon"
			b NULL

;*** Titel für Verzeichnis drucken.
:V402o0			b PLAINTEXT,REV_ON
			b "Verzeichnis drucken",PLAINTEXT,NULL

;*** Text für Druck-Box.
:V402o1			b PLAINTEXT,BOLDON
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
			w 60
			b 130
			b "Ausführliches Directory drucken"
			b GOTOXY
			w 48
			b 80
			b "Drucker: ",NULL

;*** Box für "Anzahl Zeilen/Seite"
:V402o2			b MOVEPENTO
			w 216
			b 90
			b FRAME_RECTO
			w 247
			b 101
:V402o3			b NEWPATTERN, $00
			b MOVEPENTO
			w 217
			b 91
			b RECTANGLETO
			w 246
			b 100
			b NULL

;*** Auswahl: "Einzelblatt-Papier"
:V402o4			b NEWPATTERN, $00
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

;*** Auswahl: "Langes Directory"
:V402o5			b NEWPATTERN, $00
			b MOVEPENTO
			w 48
			b 123
			b RECTANGLETO
			w 55
			b 130
			b FRAME_RECTO
			w 48
			b 123
			b NULL

;*** Info: "Seite wird gedruckt..."
:V402o6			b PLAINTEXT,BOLDON
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
:V402o7			b $01
			b 56,127
			w 64,255
			b OK        ,  2, 48
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V402o8a
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V402o8b
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V402o8a		b PLAINTEXT,BOLDON
			b "Bitte ein neues Blatt",NULL
:V402o8b		b "Papier einlegen!",NULL

;*** Info: "Druckertreiber wird geladen..."
:V402o9			b PLAINTEXT,BOLDON
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
:V402o10		b $01
			b 56,127
			w 64,255
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V402o11a
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V402o11b
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V402o11a		b PLAINTEXT,BOLDON
			b "Kann Druckertreiber",NULL
:V402o11b		b "nicht finden!",NULL

;*** Hinweis: "Drucker nicht ansprechbar!"
:V402o12		b $01
			b 56,127
			w 64,255
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V402o13a
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V402o13b
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V402o13a		b PLAINTEXT,BOLDON
			b "Drucker ist nicht",NULL
:V402o13b		b "ansprechbar !",NULL

;*** Titel: "Drucker wählen".
:V402o14		b PLAINTEXT,REV_ON
			b "Drucker wählen",PLAINTEXT,NULL

;*** Variablen & Texte für "Directory drucken".
:V402p0			b $40				;Anzahl Zeilen / Seite.
:V402p1			b $00				;Zähler für Zeilen während Druckvorgang...
:V402p2			b $00				;Anzahl Einträge in Dir-Sektor.
:V402p3			b $00				;Seiten-Nr.

:V402q0			s $06				;Speicher für Icon-Daten.

:V402r0			b "       geoDOS - Directory                   Erstellt am "
			b "xx.xx.xx um xx:xx Uhr",$0d,NULL
:V402r1			b "       Diskette:                                        "
			b "            Seite: xx",$0d,$0d,NULL
:V402r2			b "       Datei-Name        Typ S  Länge  Datum     Zeit   "
			b "GEOS-Datei-Typ",$0d,NULL
:V402r3			b "       Name des Autors          GEOS-Modus              "
			b "GEOS-Klasse",$0d,NULL
:V402r4			b "       -------------------------------------------------"
			b "---------------------",$0d,NULL
:V402r5			b "       Anzahl Dateien im Verzeichnis : xxxxx",$0d,NULL
:V402r6			b "       Blocks im Verzeichnis         : xxxxx",$0d,NULL
:V402r7			b "       Blocks auf Diskette belegt    : xxxxx",$0d,NULL
:V402r8			b "       Blocks auf Diskette frei      : xxxxx",$0d,NULL
:V402r9			b "       Anzahl Blocks auf Diskette    : xxxxx",$0d,NULL
:V402r10		b "       1 Block auf Diskette entspricht 254 Bytes.",$0d,NULL

;*** Startadresse Zwischenspeicher.
;    Directory der aktuellen Diskette.
;    Auswahl Druckertreiber.
;    Berechnung Druckdaten.
:V402z0
:V402z1			= V402z0 / 256
:V402z2			= (V402z1 + 1)*256
