; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L301: Diskette (DOS) umbenennen.
:DOS_Rename		jsr	DoInfoBox
			PrintStrgV301i0

			jsr	SetName
			jmp	InitScreen

;*** FORMAT: Name definieren.
:SetName		lda	curDrive		;Prüfen ob Disk im
			ldx	#$00			;Laufwerk.
			jsr	InsertDisk
			cmp	#$01
			beq	:1
			jmp	L301ExitGD

::1			jsr	GetBSek			;Boot-Sektor lesen.
::2			jsr	DOS_GetDskNam		;Disk-Name lesen.
			jsr	ClrBox
			lda	VolNExist
			bpl	:3

			LoadW	r0,V301e0		;Fehler:
			RecDlgBoxCSet_Grau		;"Disk Full"
			jmp	L301ExitGD

::3			ldy	#$0a
::4			lda	dosDiskName,y		;Zeichen aus Datei-Namen einlesen.
			cmp	#$20
			bne	:5
			lda	#$00
::5			sta	V301b0,y		;Leerzeichen ersetzen.
			dey
			bpl	:4

;*** Eingabe des Disketten-Name.
:GetName		LoadW	r10,V301b0
			LoadW	r0,V301a0
			RecDlgBoxL301RVec
			lda	sysDBData
			cmp	#$ff
			beq	GetName
			cmp	#$02
			bne	:1
			jmp	L301ExitGD

::1			lda	V301b0			;Disk-Namen prüfen.
			beq	:2

			LoadW	r0,V301b0
			LoadW	r1,V301c1
			lda	#11
			ldx	#r0L
			ldy	#r1L
			jsr	CmpFString
			bne	ReWrDkNam

::2			lda	VolNExist
			beq	:3
			jmp	L301ExitGD

::3			LoadW	r0,V301d0		;Alten Namen löschen?
			RecDlgBoxCSet_Grau
			lda	sysDBData
			cmp	#$02
			beq	GetName

			jmp	DelDkName

;*** Name auf Disk schreiben.
:ReWrDkNam		ldy	#$00
::4			lda	V301b0,y		;Zeichen aus Datei-Namen einlesen.
::5			cmp	#" "
			bcc	:6
			cmp	#$60
			bcc	:7
			sub	$20
			jmp	:5
::6			lda	#$20			;Ungültige Zeichen durch
::7			sta	V301b1,y		;Leerzeichen ersetzen.
			iny
			cpy	#$0b
			bne	:4

::8			jsr	DoInfoBox
			PrintStrgV301i1

			LoadW	r0,V301b1
			MoveW	a8,r1
			LoadW	r2,32
			jsr	MoveData

			LoadW	a8,Disk_Sek
			jsr	D_Write
			txa
			pha
			jsr	ClrBox
			pla
			bne	:9
			jmp	L301ExitGD

::9			jmp	DiskError

;*** Disketten-Name löschen.
:DelDkName		jsr	DoInfoBox		;Infobox aufbauen.
			PrintStrgV301g0

			jsr	DefMdr
			MoveW	MdrSektor,V301f0
			LoadW	a8,V301z1
::1			jsr	D_Read
			AddVW	512,a8
			jsr	Inc_Sek
			SubVW	1,V301f0
			CmpWI	V301f0,0
			bne	:1

			LoadW	r0,32
			MoveW	a8,r1
			jsr	ClearRam

			LoadW	r0,V301z1
			AddW	DskNamSekNr,r0
			AddW	DskNamEntry,r0
			MoveW	r0,r1
			AddVBW	32,r0
			MoveW	a8,r2
			SubW	r1,r2
			jsr	MoveData

			jsr	DefMdr
			MoveW	MdrSektor,V301f0
			LoadW	a8,V301z1
::2			jsr	D_Write
			AddVW	512,a8
			jsr	Inc_Sek
			SubVW	1,V301f0
			CmpWI	V301f0,0
			bne	:2

			jsr	ClrBox			;Infobox aufbauen.

:L301ExitGD		rts

;*** Eingabefeld löschen.
:No_Name		ClrB	V301b0
			LoadB	sysDBData,$ff
			jmp	RstrFrmDialogue

;*** Farben setzen und Titel ausgeben.
:L301Col_1		SetColRam23,7*40+9,$61
			Pattern	1
			FillRec	56,63,72,255
			jsr	UseGDFont
			PrintXY	80,62,V301a1
			jmp	UseSystemFont

;*** Farben zurücksetzen.
:L301RVec		PushB	r2L
			SetColRam23,7*40+9,$b1
			PopB	r2L
			rts

;*** Window beenden.
:L301ExitW		LoadB	sysDBData,2
			jmp	RstrFrmDialogue

;*** Eingabe Disketten-Name.
:V301a0			b $01
			b 56,135
			w 64,255
			b DB_USR_ROUT
			w L301Col_1
			b CANCEL     , 16, 56
			b DBUSRICON  ,  2, 56
			w V301h0
			b DBUSRICON  ,  0,  0
			w V301h1
			b DBGRPHSTR
			w V301c0
			b DBGETSTRING, 20, 24
			b r10L,11
			b NULL

:V301a1			b PLAINTEXT,REV_ON
			b "Disketten-Name",PLAINTEXT,NULL

:V301b0			s 12
:V301b1			s 11
			b $08,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
			w $0000,$0000
			w $0000
			w $0000,$0000

:V301c0			b MOVEPENTO
			w 80
			b 77
			b FRAME_RECTO
			w 239
			b 92
			b NULL

:V301c1			b "           ",NULL

;*** Hinweis: "Alten Disketten-Namen löschen ?"
:V301d0			b $01
			b 56,127
			w 64,255
			b OK        ,  2, 48
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V301d1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V301d2
			b DB_USR_ROUT
			w ISet_Frage
			b NULL

:V301d1			b PLAINTEXT,BOLDON
			b "Alten Disketten-",NULL
:V301d2			b "Namen löschen ?",PLAINTEXT,NULL

;*** Hinweis: "Kein Platz für Disketten-Name..."
:V301e0			b $01
			b 56,127
			w 64,255
			b OK        , 10, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V301e1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V301e2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V301e1			b PLAINTEXT,BOLDON
			b "Kein Platz für Diskname",NULL
:V301e2			b "im Hauptverzeichnis !",PLAINTEXT,NULL

:V301f0			w $0000

;*** Info: "Disketten-Name wird gelöscht..."
:V301g0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Disketten-Name"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird gelöscht..."
			b NULL

:V301h0			w icon_None
			b $00,$00
			b icon_None_x,icon_None_y
			w No_Name
:V301h1			w icon_Close
			b $00,$00
			b icon_Close_x,icon_Close_y
			w L301ExitW

:icon_None
<MISSING_IMAGE_DATA>
:icon_None_x		= .x
:icon_None_y		= .y

;*** Info: "Disketten-Name wird eingelesen..."
:V301i0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Disketten-Name"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird eingelesen..."
			b NULL

;*** Info: "Schreibe neuen Namen auf Diskette..."
:V301i1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Schreibe neuen Namen"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "auf Diskette..."
			b NULL

;*** Speicher für DOS-Hauptverzeichnis...
:V301z0
:V301z1			= (V301z0 / 256 +1) * 256
