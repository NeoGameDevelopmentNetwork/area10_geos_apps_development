; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L500: Dateien umbenennen
:DOS_RenFile		LoadW	r10,Memory		;Zeiger auf Datei-Speicher.
			LoadW	r11,Memory+16*256
			LoadW	r14,V500e0		;Titel.
			jsr	DOS_GetFiles		;Dateien auswählen.
			tax
			beq	:2
::1			jmp	L500ExitGD		;Ende.

::2			MoveW	r15,a5			;Zeiger auf Namenstabelle nach ":a5".

::3			lda	#12			;Neuen Dateinamen eingeben.
			jsr	NewFileName
			txa
			bmi	:1			;Zurück zu geoDOS.
			bne	:8			;Name nicht ändern.

			jsr	ConvertDOS		;Name ins DOS-Format wandeln.

			jsr	DoInfoBox
			PrintStrgV500f1

			LoadW	r10,DOSNamBuf2		;Prüfen ob Datei schon vorhanden.
			jsr	LookDOSfile
			tay
			bne	:4

			jsr	ClrBox			;Fehler: "Name bereits vergeben..:"
			LoadW	r0,V500b0
			ClrDlgBoxCSet_Grau
			jmp	:3

::4			LoadW	r10,V500a1		;Datei suchen.
			jsr	LookDOSfile
			tay
			bne	:9

			ldx	#$00
			ldy	#$00
::5			lda	DOSNamBuf2,x		;Neuen Dateinamen schreiben.
			beq	:7
			cmp	#"."
			beq	:6
			sta	(a8L),y
			iny
::6			inx
			cpy	#$0b
			bne	:5

::7			cpy	#$0b			;Auf 11 Zeichen mit Leerzeichen
			beq	:8			;auffüllen.
			lda	#" "
			sta	(a8L),y
			inx
			iny
			bne	:7

::8			LoadW	a8,Disk_Sek		;Directory-Sektor schreiben.
			jsr	D_Write
			txa
			beq	:9
			jmp	DiskError		;Disketten-Fehler.

::9			jsr	ClrBox

			AddVBW	16,a5			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a5L),y			;Tabellen-Ende erreicht ?
			beq	:10			;Ja, Ende.
			jmp	:3			;Nein, weiter...

::10			jmp	L500ExitGD		;Zurück zu geoDOS.

;*** L500: Dateien löschen.
:DOS_DelFile		LoadW	r10,Memory		;Zeiger auf Datei-Tabelle.
			LoadW	r11,Memory +16*256
			LoadW	r14,V500e1		;Titel.
			jsr	DOS_GetFiles		;Dateien auswählen.
			tax
			beq	:2
::1			jmp	L500ExitGD		;Zurück zu geoDOS.

::2			MoveW	r15,a5			;Zeiger auf Datei-Tabelle nach ":a5".
			ClrB	V500d0

:ChkNxDfile		lda	V500d0			;Sicherheitsabfrage ?
			bne	DelDfile_a		;Nein, automatisch löschen.

			jsr	AskToDelFile		;Sicherheitsabfrage.
			cmp	#$00
			bne	:1
			jmp	WriteNewFAT		;FAT schreiben und Ende.

::1			cmp	#$02			;Datei überspringen.
			bne	:2
			jmp	DelNxDfile

::2			cmp	#$03
			bne	DelDfile
			LoadB	V500d0,$ff		;Alle Dateien automatisch löschen.

:DelDfile		jsr	DoInfoBox		;Hinweis: "Datei wird gelöscht..."
:DelDfile_a		PrintStrgV500f0

			lda	#12
			jsr	PrnFileName

			MoveW	a5,r10			;Datei-Eintrag suchen.
			jsr	LookDOSfile
			tay
			bne	DelNxDfile

			jsr	DoDelDOSfile		;DOS-Datei löschen.

			jsr	ClrBoxText

			lda	V500d0
			bne	DelNxDfile
			jsr	ClrBox

:DelNxDfile		AddVBW	16,a5			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a5L),y			;Tabellen-Ende erreicht ?
			beq	:1			;Ja, Ende.
			jmp	ChkNxDfile		;Nein, weiter...

::1			lda	V500d0
			beq	WriteNewFAT
			jsr	ClrBox

;*** Falls Dateien gelöscht, FAT aktualisieren.
:WriteNewFAT		jsr	DoInfoBox
			PrintStrgV500f2
			jsr	Save_FAT		;FAT aktualisieren.
			jsr	ClrBox
			jmp	L500ExitGD		;Zurück zu geoDOS.

;*** Dateinamen konvertieren.
:ConvertDOS		ldy	#$00
			ldx	#$00
::1			lda	InpNamBuf,x		;Zeichen aus Dateinamen einlesen.
			beq	:2
			cmp	#"."			;Punkt ?
			beq	:3			;Ja, Abbruch.
			cmp	#" "			;Leerzeichen ?
			bne	:4			;Nein, weiter...
			inx				;Ja, überlesen.
			cpx	#$10
			bne	:1
::2			lda	#$20			;Dateinamen oder Extension auf
			sta	DOSNamBuf2,y		;volle Länge mit Leerzeichen auffüllen.
			iny
::3			cpy	#$08			;Ende Dateiname erreicht ?
			beq	:6			;Ja, weiter.
			cpy	#$0b			;Ende Extension erreicht ?
			bne	:2			;Nein, weiter auffüllen.
			beq	:7			;Ja, Ende.
::4			cmp	#$60			;Zeichen auf Zulässigkeit testen.
			bcc	:5
			sub	$20
			bcs	:4
::5			sta	DOSNamBuf2,y		;Zeichen in Dateinamen schreiben.
			iny
::6			inx				;Weiter mit nächstem Zeichen.
			cpy	#$0b			;Ende erreicht ?
			bne	:1			;Nein, weiter...

::7			lda	#$00			;Rest des Dateinamens löschen.
			sta	DOSNamBuf2,y
			iny
			cpy	#$10
			bne	:7

			ldy	#$0a			;Punkt zwischen Namen und Extension
::8			lda	DOSNamBuf2,y		;einfügen.
			iny
			sta	DOSNamBuf2,y
			dey
			dey
			cpy	#$07
			bne	:8
			iny
			lda	#"."			;Punkt in Dateinamen einfügen.
			sta	DOSNamBuf2,y
			rts

;*** Vorhandene DOS-Datei löschen.
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

::7			lda	r1L			;Zeiger auf aktuellen Cluster
			ldx	r1H
			cmp	#$00
			bne	:8
			cpx	#$00
			beq	:9
::8			jsr	Get_Clu			;Link auf nächsten Cluster lesen.
			PushW	r1			;Link-Wert merken.
			lda	r2L
			ldx	r2H
			jsr	Set_Clu			;Aktuellen Cluster freigeben.
			pla				;Nächsten Cluster bestimmen.
			sta	r1L
			tay
			pla
			sta	r1H
			and	#%00001111
			cmp	#$0f			;Datei-Ende erreicht ?
			bne	:7			;Nein, nächsten Cluster löschen.
			cpy	#$f8
			bcc	:7
::9			LoadB	BAM_Modify,$ff
			rts

;*** L500: Dateien umbenennen
:CBM_RenFile		LoadW	r10,Memory		;Zeiger auf Datei-Speicher.
			LoadW	r14,V500e0		;Titel.
			jsr	CBM_GetFiles		;Dateien auswählen.
			tax
			beq	:2
::1			jmp	L500ExitGD		;Zurück zu geoDOS.

::2			MoveW	r15,a5			;Zeiger auf Datei-Tabelle nach ":a5".

::3			lda	#16			;Neuen Dateinamen eingeben.
			jsr	NewFileName
			txa
			bmi	:1			;Zurück zu geoDOS.
			bne	:8			;Name nicht ändern.

			LoadW	r14,InpNamBuf		;Prüfen ob Datei schon vorhanden.
			jsr	LookCBMfile
			tay
			bne	:4

			LoadW	r0,V500b0		;Fehler: "Name bereits vergeben..."
			ClrDlgBoxCSet_Grau
			jmp	:3

::4			LoadW	r14,V500a1		;Datei suchen.
			jsr	LookCBMfile
			tay
			bne	:8

			ldy	#$00
::5			lda	InpNamBuf,y		;Neuen Dateinamen schreiben.
			beq	:6
			sta	diskBlkBuf+5,x
			inx
			iny
			cpy	#$10
			bne	:5

::6			cpy	#$10			;Auf 16 Zeichen mit "SHIFTSPACE"
			beq	:7			;auffüllen.
			lda	#$a0
			sta	diskBlkBuf+5,x
			inx
			iny
			bne	:6

::7			LoadW	r4,diskBlkBuf		;Directory-Sektor schreiben.
			jsr	PutBlock
			txa
			beq	:8
			jmp	DiskError		;Disketten-Fehler.

::8			AddVBW	16,a5			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a5L),y			;Tabellen-Ende erreicht ?
			bne	:3			;Nein, weiter...

			jmp	L500ExitGD		;Ja, zurück zu geoDOS.

;*** Zurück zu geoDOS.
:L500ExitGD		jmp	InitScreen		;Ende...

;*** CBM-Dateien löschen.
:CBM_DelFile		LoadW	r10,Memory		;Zeiger auf Datei-Speicher.
			LoadW	r14,V500e1		;Titel.
			jsr	CBM_GetFiles		;Dateien auswählen.
			tax
			beq	:2
::1			jmp	L500ExitGD		;Zurück zu geoDOS.

::2			MoveW	r15,a5			;Zeiger auf Datei-Tabelle nach ":a5".
			ClrB	V500d0

:ChkNxCfile		lda	V500d0			;Sicherheitsabfrage ?
			bne	DelCfile_a		;Nein, automatisch löschen.

			jsr	AskToDelFile		;Sicherheitsabfrage.
			cmp	#$00
			bne	:1
			jmp	L500ExitGD		;Zurück zu geoDOS.

::1			cmp	#$02			;Datei überspringen.
			bne	:2
			jmp	DelNxCfile

::2			cmp	#$03
			bne	DelCfile
			LoadB	V500d0,$ff		;Alle Dateien automatisch löschen.

:DelCfile		jsr	DoInfoBox		;Hinweis: "Datei wird gelöscht..."
:DelCfile_a		PrintStrgV500f0

			lda	#16			;Dateiname ausgeben.
			jsr	PrnFileName

			MoveW	a5,r14			;Datei-Eintrag suchen.
			jsr	LookCBMfile
			tay
			bne	DelNxCfile

			txa				;CBM-Datei löschen.
			pha
			ldy	#$00
::3			lda	diskBlkBuf+2,x
			sta	dirEntryBuf,y
			inx
			iny
			cpy	#$1e
			bne	:3
			pla
			tax

			lda	#$00
			sta	diskBlkBuf+2,x
			jsr	PutBlock
			txa
			beq	:5
::4			jmp	DiskError		;Disketten-Fehler.

::5			LoadW	r9,dirEntryBuf		;Sektoren freigeben.
			jsr	FreeFile
			txa
			bne	:4

			jsr	ClrBoxText

			lda	V500d0
			bne	DelNxCfile
			jsr	ClrBox

:DelNxCfile		AddVBW	16,a5			;Zeiger auf nächste Datei.

			ldy	#$00
			lda	(a5L),y			;Tabellen-Ende erreicht ?
			beq	:1			;Ja, Ende...
			jmp	ChkNxCfile		;Nein, weiter...

::1			lda	V500d0
			beq	:2
			jsr	ClrBox
::2			jmp	L500ExitGD		;Zurück zu geoDOS.

;*** Dateinamen ausgeben.
:PrnFileName		sta	:3 +1			;Max. Länge Dateiname.
			lda	#$22
			jsr	SmallPutChar
			lda	#$00
::1			pha
			tay
			lda	(a5L),y
			beq	:4
			jsr	SmallPutChar
::2			pla
			add	1
::3			cmp	#$10
			bne	:1
			pha
::4			pla
			lda	#$22
			jmp	SmallPutChar

;*** Einzel-Datei umbenennen.
:NewFileName		sta	V500a2a+1

			ldy	#$0f			;Dateiname in Puffer kopieren.
::1			lda	(a5L),y
			sta	V500a1,y
			dey
			bpl	:1

			jsr	i_FillRam		;Eingabe-Puffer löschen.
			w	17,InpNamBuf
			b	$00

::2			LoadW	r10,InpNamBuf		;Dialogbox zur Eingabe des neuen
			LoadW	r0,V500a2		;Dateinamens.
			ClrDlgBoxL500RVec_1

			lda	sysDBData
			cmp	#$ff
			beq	:2

			cmp	#$0d			;RETURN ?
			beq	:5			;Ja, Name übernehmen.
			cmp	#$02			;CANCEL ?
			bne	:4

::3			ldx	#$7f			;Name nicht ändern.
			rts

::4			ldx	#$ff			;Zurück zu geoDOS.
			rts

::5			lda	InpNamBuf		;Leeres Eingabefeld ?
			beq	:3			;Ja, Name nicht ändern.

			ldx	#$00			;Name ändern.
			rts

;*** Dialogbox verlassen.
:L500ExitW		LoadB	sysDBData,1
			jmp	RstrFrmDialogue

;*** Farben zurücksetzen.
:L500RVec_1		PushB	r2L
			jsr	i_FillRam
			w	24,COLOR_MATRIX+6*40+8
			b	$b1
			PopB	r2L
			rts

;*** Dialogbox vorbereiten.
:L500Col_1		jsr	i_FillRam
			w	23,COLOR_MATRIX+6*40+9
			b	$61

			Pattern	1
			FillRec	48,55,72,255
			jsr	UseGDFont
			PrintXY	80,54,V500a0
			jsr	UseSystemFont
			PrintXY	80,68,V500a6
			PrintStrgV500a1
			rts

;*** Eingabefeld löschen.
:No_Name		ClrB	InpNamBuf
			LoadB	sysDBData,$ff
			jmp	RstrFrmDialogue

;*** Frage: "Datei löschen ?"
:AskToDelFile		jsr	CSet_Grau
			LoadW	r0,V500c0
			ClrDlgBoxL500RVec_2
			lda	sysDBData
			rts

;*** Farben setzen.
:L500Col_2		SetColRam23,7*40+9,$61
			Pattern	1
			FillRec	56,63,72,255

			jsr	UseGDFont
			PrintXY	80,62,V500c3
			jsr	UseSystemFont

			jsr	ISet_Frage

			sbBn	currentMode,6
			LoadB	r1H,111
			LoadW	r11,80

			lda	#16			;Dateiname ausgeben.
			jmp	PrnFileName

;*** Farben zurücksetzen.
:L500RVec_2		PushB	r2L
			SetColRam23,7*40+9,$b1
			jsr	CSet_Grau
			PopB	r2L
			rts

:L080ExitW_a		lda	#$00			;"Close"-Icon.
			b $2c

:L080ExitW_b		lda	#$01			;"JA"-Icon.
			b $2c

:L080ExitW_c		lda	#$02			;"NEIN"-Icon.
			b $2c

:L080ExitW_d		lda	#$03			;"NAME"-Icon.
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Datei-Eintrag suchen.
:LookDOSfile		ClrB	V501b0			;Zeiger auf Anfang Verzeichnis.
			jsr	ResetDir

::1			CmpBI	V501b7,16		;Alle Einträge des Sektors durchsucht ?
			bne	:2			;Nein, weiter...

			ClrB	V501b7			;Nächsten Sektor lesen.
			jsr	GetNxDirSek
			cpx	#$00
			beq	:2

			lda	#$ff			;Datei nicht gefunden.
			rts

::2			ldy	#$00
			ldx	#$00			;Dateiname in Speicher kopieren und
::3			lda	(a8L),y			;in GEOS-Format konvertieren.
			cmp	#" "
			bcs	:5			;Code < $20 ? Nein, weiter.
::4			lda	#"_"			;Zeichen durch "_"-Code ersetzen.
			bne	:6
::5			cmp	#$7f			;Code > $7F ? Ja, ungültig.
			bcs	:4
::6			iny
::7			sta	DOSNamBuf1,x		;Zeichen in Speicher kopieren.
			inx
			lda	#"."			;Trennung zwischen "NAME" + "EXT"
			cpx	#$08			;einfügen.
			beq	:7
			cpx	#$0c
			bne	:3

			ldy	#$0b			;Aktuellen Eintrag mit Suchdatei
::8			lda	DOSNamBuf1,y		;vergleichen.
			cmp	(r10L),y
			bne	:9
			dey
			bpl	:8

			lda	#$00			;Datei gefunden.
			rts

::9			jsr	NxSekEntry		;Nächsten Eintrag vergleichen.
			jmp	:1

;*** Datei-Eintrag suchen.
:LookCBMfile		lda	V502a0+0		;Zeiger auf Anfang Verzeichnis.
			sta	r1L
			lda	V502a0+1
			sta	r1H

::0			LoadW	r4,diskBlkBuf		;Directory-Sektor lesen.
			jsr	GetBlock
			txa
			beq	:1
			jmp	DiskError		;Disketten-Fehler.

::1			lda	#$00
::2			pha				;Zeiger auf Eintrag positionieren.
			asl
			asl
			asl
			asl
			asl
			tax
			lda	diskBlkBuf+2,x		;Eintrag gelöscht ?
			bne	:5			;Nein, weiter...
::3			pla
			add	1			;Zeiger auf nächsten Eintrag.
			cmp	#$08			;Alle Einträge des Sektors geprüft ?
			bne	:2			;Nein, weiter...

			lda	diskBlkBuf+0		;Zeiger auf nächsten Sektor.
			beq	:4
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	:0

::4			lda	#$ff			;Datei nicht gefunden.
			rts

::5			ldy	#$00
::6			lda	diskBlkBuf+5,x		;Eintrag mit Suchdatei vergleichen.
			cmp	#$20
			bcc	:8
			cmp	#$a0
			bne	:7
			lda	#$00
			beq	:9
::7			cmp	#$7f
			bcc	:9
			sbc	#$20
			bcs	:7
::8			lda	#$20
::9			cmp	(r14L),y
			bne	:3
			iny
			inx
			cpy	#$10
			bne	:6

			pla
			asl
			asl
			asl
			asl
			asl
			tax
			lda	#$00			;Datei gefunden.
			rts

;*** Variablen.
:V500a0			b PLAINTEXT,REV_ON
			b "Neuer Dateiname",NULL

:V500a1			s 17

;*** Dialogbox "Name eingeben".
:V500a2			b $01
			b 48,135
			w 64,255

			b CANCEL     , 16, 64
			b DBUSRICON  ,  0,  0
			w V500a4
			b DBUSRICON  ,  2, 64
			w V500a5
			b DB_USR_ROUT
			w L500Col_1
			b DBGRPHSTR
			w V500a3
			b DBGETSTRING, 20, 32
:V500a2a		b r10L,16
			b NULL

:V500a3			b MOVEPENTO
			w 80
			b 77
			b FRAME_RECTO
			w 239
			b 92
			b NULL

:V500a4			w icon_Close
			b $00,$00
			b icon_Close_x,icon_Close_y
			w L500ExitW

:V500a5			w icon_None
			b $00,$00
			b icon_None_x,icon_None_y
			w No_Name

:V500a6			b PLAINTEXT,BOLDON
			b "Datei: ",NULL

:icon_None
<MISSING_IMAGE_DATA>
:icon_None_x		= .x
:icon_None_y		= .y

;*** Fehler: "Datei existiert bereits"
:V500b0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V500b1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V500b2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V500b1			b PLAINTEXT,BOLDON
			b "Dieser Dateiname ist",NULL
:V500b2			b "bereits vergeben !",PLAINTEXT,NULL

:InpNamBuf		s 17
:DOSNamBuf1		s 17
:DOSNamBuf2		s 17

;*** Sicherheitsabfrage.
:V500c0			b $01				;Fenster-Abmessungen.
			b 56,151
			w 64,255
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V500c1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V500c2

			b DBUSRICON ,  0,  0
			w V500c4
			b DBUSRICON ,  2, 72
			w V500c5
			b DBUSRICON , 16, 72
			w V500c6
			b DBUSRICON ,  9, 72
			w V500c7

			b DB_USR_ROUT			;Icon platzieren.
			w L500Col_2
			b NULL

:V500c1			b PLAINTEXT,BOLDON
			b "Die folgende Datei auf",NULL
:V500c2			b "Diskette löschen ?",PLAINTEXT,NULL

:V500c3			b PLAINTEXT,REV_ON,"Information",PLAINTEXT,NULL

:V500c4			w icon_Close
			b $00,$00
			b icon_Close_x,icon_Close_y
			w L080ExitW_a

:V500c5			w icon_Ja
			b $00,$00
			b icon_Ja_x,icon_Ja_y
			w L080ExitW_b

:V500c6			w icon_Nein
			b $00,$00
			b icon_Nein_x,icon_Nein_y
			w L080ExitW_c

:V500c7			w icon_Alle
			b $00,$00
			b icon_Alle_x,icon_Alle_y
			w L080ExitW_d

:icon_Ja
<MISSING_IMAGE_DATA>
:icon_Ja_x		= .x
:icon_Ja_y		= .y

:icon_Nein
<MISSING_IMAGE_DATA>
:icon_Nein_x		= .x
:icon_Nein_y		= .y

:icon_Alle
<MISSING_IMAGE_DATA>
:icon_Alle_x		= .x
:icon_Alle_y		= .y

:V500d0			b $00

:V500e0			b PLAINTEXT,REV_ON
			b "Dateien umbenennen       x:",NULL
:V500e1			b PLAINTEXT,REV_ON
			b "Dateien löschen          x:",NULL

:V500f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Datei wird gelöscht..."
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b NULL

:V500f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "überprüft..."
			b NULL

:V500f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Disketten-Verzeichnis"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird aktualisiert..."
			b NULL
