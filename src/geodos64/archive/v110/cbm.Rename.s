; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L401: Diskette (CBM) umbenennen.
:CBM_Rename		jsr	DoInfoBox
			PrintStrgV401f0
			jsr	SetName
			jmp	SetMenu

;*** FORMAT: Name definieren.
:SetName		lda	curDrive		;Diskette einlegen.
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01
			beq	:1
			rts

::1			jsr	OpenDisk		;Diskette öffnen.
			txa
			beq	:2
			jmp	DiskError		;Disk-Fehler.

::2			jsr	CBM_GetDskNam		;Name einlesen.

			jsr	i_MoveData		;Name in Eingabepuffer kopieren.
			w	cbmDiskName
			w	InpNamBuf
			w	16

			ldy	#15
::3			lda	InpNamBuf,y
			cmp	#$20
			beq	:4
			cmp	#$a0
			bne	:5
::4			dey
			bpl	:3
::5			iny
			lda	#$00
			sta	InpNamBuf,y

::6			jsr	ClrBox
			LoadW	r10,InpNamBuf		;Eingabe des neuen Disketten-Namens.
			LoadW	r0,V401a
			RecDlgBoxL401RVec
			lda	sysDBData
			cmp	#$ff			;Nochmal eingeben.
			beq	:6
			cmp	#$02			;Abbruch.
			bne	:7
			rts

::7			ldx	#$00
::8			lda	InpNamBuf,x
			beq	:9
			inx
			cpx	#$10
			bne	:8
			jmp	SetCBMName

::9			lda	#$a0
::10			sta	InpNamBuf,x
			inx
			cpx	#$10
			bne	:10

;*** Name wieder auf Disk schreiben.
:SetCBMName		jsr	DoInfoBox
			PrintStrgV401f1
			jsr	GetDirHead

			ldy	#15
::1			lda	InpNamBuf,y
			sta	curDirHead + $90,y
			dey
			bpl	:1

			ldx	curDrive		;Sektor mit Disketten-Name
			lda	driveType-8,x		;ermitteln.
			and	#%00000111
			beq	:6			;Typ unbekannt.
			cmp	#$01			;Typ 1541.
			beq	:2
			cmp	#$02			;Typ 1571.
			beq	:2
			cmp	#$03			;Typ 1581.
			beq	:3
			cmp	#$04			;Typ Native.
			beq	:4
			jmp	:6			;Typ unbekannt.
::2			lda	#$12			;Spur $12, Sektor $00.
			ldx	#$00
			jmp	:5
::3			lda	#$28			;Spur $28, Sektor $00.
			ldx	#$00
			jmp	:5
::4			lda	#$01			;Spur $01, Sektor $01.
			ldx	#$01

;*** Sektor mit Name zurück auf Diskette schreiben.
::5			sta	r1L
			stx	r1H
			LoadW	r4,curDirHead
			jsr	PutBlock
			txa
			bne	:7

			lda	curDrvMode
			bmi	RenPartNam		;Partitions-Namen ändern.

::6			jmp	ClrBox

::7			jsr	ClrBox
			jmp	DiskError

;*** Partitionsname ändern.
:RenPartNam		jsr	ClrBoxText
			PrintStrgV401f2

			InitSPort			;GEOS-Turbo aus und I/O aktivieren.
			CxSend	V401e0			;"G-P"-Befehl.
			CxReceiveV401e1			;Partitions-Daten einlesen.

			ldy	#$06
			ldx	#$00			;Name aus Eingabepuffer in "Rename"-
::1			lda	InpNamBuf,x		;Befehl kopieren.
			beq	:2
			cmp	#$a0
			beq	:2
			sta	V401e2,y
			iny
			inx
			cpx	#$10
			bne	:1

::2			cpx	#$00			;Neuer Partitionsname > 0 Zeichen ?
			beq	:5			;Nein, Ende.

			lda	#"="			;"=" als Trennzeichen.
			sta	V401e2,y
			iny

			ldx	#$00
::3			lda	V401e1 + 5,x		;Alten Partitions-Namen einfügen.
			cmp	#$a0
			beq	:4
			sta	V401e2,y
			iny
			inx
			cpx	#$10
			bne	:3

::4			dey
			dey
			sty	V401e2

			CxSend	V401e2			;"R-P"-Befehl senden.
::5			jsr	DoneWithIO
			jmp	ClrBox

;*** Aktuelle Eingabe löschen.
:No_Name		ClrB	InpNamBuf
			LoadB	sysDBData,$ff
			jmp	RstrFrmDialogue

;*** Farben setzen und Titel ausgeben.
:L401Col_1		SetColRam23,7*40+9,$61
			Pattern	1
			FillRec	56,63,72,255

			jsr	UseGDFont
			PrintXY	80,62,V401c
			jmp	UseSystemFont

;*** Farben zurücksetzen..
:L401RVec		PushB	r2L
			SetColRam23,7*40+9,$b1
			PopB	r2L
			rts

;*** Window beenden.
:L401ExitW		LoadB	sysDBData,2
			jmp	RstrFrmDialogue

;*** Disketten-Namen eingeben.
:V401a			b $01
			b 56,135
			w 64,255

			b DB_USR_ROUT
			w L401Col_1

			b CANCEL     , 16, 56
			b DBUSRICON  ,  2, 56
			w V401d0
			b DBUSRICON  ,  0,  0
			w V401d1

			b DBGRPHSTR
			w V401b

			b DBGETSTRING, 20, 24
			b r10L,16

			b NULL

:V401b			b MOVEPENTO
			w 80
			b 77
			b FRAME_RECTO
			w 239
			b 92
			b NULL

:V401c			b PLAINTEXT,REV_ON
			b "Disketten-Name",PLAINTEXT,NULL

:V401d0			w icon_None
			b $00,$00
			b icon_None_x,icon_None_y
			w No_Name
:V401d1			w icon_Close
			b $00,$00
			b icon_Close_x,icon_Close_y
			w L401ExitW

:V401e0			w $0005
			b "G-P",$ff,$0d
:V401e1			w $001f
			s $1f
:V401e2			w $0006
			b "R-P:________________=________________",NULL

;*** Info: "Disketten-Name wird eingelesen..."
:V401f0			b PLAINTEXT,BOLDON
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
:V401f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Schreibe neuen Namen"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "auf Diskette..."
			b NULL

;*** Info: "Partitions-Name wird geändert..."
:V401f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Name der CMD-Partition"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird geändert..."
			b NULL

:InpNamBuf		s 17

:icon_None
<MISSING_IMAGE_DATA>
:icon_None_x = .x
:icon_None_y = .y
