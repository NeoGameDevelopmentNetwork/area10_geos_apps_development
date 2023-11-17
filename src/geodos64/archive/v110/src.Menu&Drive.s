; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Anzahl Icons für Menü.
:MaxIcons		= 3

;*** L071: Bildschirm aufbauen.
:NewScreen		Display	ST_WR_FORE ! ST_WR_BACK
			jsr	UseGDFont

			SetColRam920,1*40+0,$b1
			Pattern	2
			FillRec	8,191,0,319

			LoadB	COLOR_MATRIX,$b1
			SetColRam39,0*40+1,$16
			Pattern	0
			FillRec	0,7,0,319

			PrintXY	96,6,Titel_Zeile
			lda	#"-"
			jsr	SmallPutChar
			PrintStrgVersion

			SetColRam40,960,$5d
			Pattern	1
			FillRec	192,199,0,319

			PrintXY	0,198,InfoLine

;*** Menüs aufbauen.
:NewMenu		ldx	#$fd			;Zurück zur MainLoop.
			txs

			lda	AppDrv			;Start-Laufwerk aktivieren.
			jsr	NewDrive

			jsr	UseSystemFont		;Menü aktivieren.
			Display	ST_WR_FORE
			LoadB	iconSelFlag,ST_FLASH
			ClrW	otherPressVec
			LoadW	RecoverVector,RecoverRectangle

			jsr	InitForIO
			lda	#$00			;Farben.
			sta	$d027
			sta	$d020
			jsr	DoneWithIO

			php				;Maus-Position speichern..
			sei
			PushW	mouseXPos
			PushB	mouseYPos

			LoadW	r0,icon_Tab1		;Icons.
			jsr	DoIcons
			LoadW	r0,Main_Menu		;Menüs.
			lda	#$ff
			jsr	DoMenu

			pla
			tay
			PopW	r11
			sec
			jsr	StartMouseMode		;Maus aktivieren.
			plp
			rts				;Zur Mainloop.

;*** GEOS-Farben auf Standardwerte.
:OrgGEOSCol		MoveB	screencolors,:1
			jsr	i_FillRam
			w	1000,COLOR_MATRIX
::1			b	$00

			Pattern	2
			FillRec	160,199,0,319
			FillRec	0,159,0,319

			jmp	SetGEOSCol

;*** Laufwerke ermitteln.
:SetDrvDat		lda	DriveModes+1		;Laufwerks-Typen ermitteln.
			and	#%00001000
			bne	:2			;Falls Laufwerk B: =RAM, B: bevorzugen.
::1			ldx	#8			;Laufwerk A:
			ldy	#9			;LaufwerK B:
			bne	:3
::2			ldx	#9			;Laufwerk B:
			ldy	#8			;Laufwerk A:
::3			stx	V071a0+0
			sty	V071a0+1
			lda	DriveTypes-8,x
			bne	:4
			sta	V071a0+0
::4			lda	DriveTypes-8,y
			bne	:5
			sta	V071a0+1
::5			rts

;*** geoWrite suchen.
:Get_gW_Appl		jsr	SetDrvDat		;Laufwerke ermitteln.
			lda	#$00			;Suche auf Laufwerk x: starten.
::4			sta	V071a1
			tax
			lda	V071a0,x
			beq	:7
			jsr	NewDrive		;Neues Laufwerk setzen.
			txa
			bne	:5
			jsr	OpenDisk		;Diskette öffnen.
			txa
			beq	:6
::5			ClrB	gW_Boot			;geoWrite nicht gefunden.
			rts

::6			LoadB	r7L,APPLICATION		;geoWrite suchen.
			LoadB	r7H,1
			LoadW	r10,V071b0
			LoadW	r6,V071b1
			jsr	FindFTypes
			txa
			bne	:7
			lda	r7H
			bne	:7
			MoveB	Action_Drv,gW_Boot
			rts

::7			lda	V071a1 			;geoWrite auf nächstem Laufwerk suchen.
			add	1
			cmp	#2
			bne	:4
			jmp	:5

;*** geoWrite-Menü.
:RunGW			jsr	Get_gW_Appl
			lda	gW_Boot
			beq	gW_NotFound
			LoadW	r0,RunGW_Menu
			lda	#$01
			jsr	DoMenu
::1			rts

;*** Fehler: "geoWrite nicht gefunden!"
:gW_NotFound		jsr	UseSystemFont
			LoadW	r0,V071h0
			RecDlgBoxCSet_Grau
			jmp	SetMenu

;*** geoWrite starten.
:Get_gW			lda	gW_Boot
			beq	:1
			jsr	NewDrive
			txa
			beq	:2
::1			jmp	ExitRunMenu

::2			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,V071b0
			LoadW	r6,V071b1
			jsr	FindFTypes
			txa
			bne	:1
			lda	r7H
			bne	gW_NotFound
			jsr	PrepareExit
			LoadW	r6,V071b1
			LoadB	r0L,%00000000
			jsr	GetFile
			jmp	DiskError

;*** Auswahlmenü "RunUp".
:RunUp			LoadW	r0,RunUp_Menu
			lda	#$01
			jmp	DoMenu

;*** Zurück zum Hauptmenü.
:ExitRunMenu		jsr	RecoverAllMenus
			jmp	NewMenu

;*** Auswahl-Tabelle laden.
:Get_SlctTab		sta	:2 +1			;Datei-Typ für Auswahlbox.
			stx	:7 +1			;Zeiger auf Titel.
			sty	:8 +1
			MoveB	r10L,:2a +1
			MoveB	r10H,:2b +1
			jsr	RecoverAllMenus		;Menüs löschen.

;*** Dateien einlesen.
::0			jsr	i_FillRam		;Speicher löschen.
			w	256*17,V072z1
			b	$00

			ldx	#$00			;Einträge für Laufwerk A: und B:
			lda	DriveTypes +0		;erzeugen.
			beq	:0a
			inx
::0a			lda	DriveTypes +1
			beq	:1
			inx
::1			stx	V071e0
			txa
			asl
			asl
			asl
			asl
			sta	r2L
			ClrB	r2H
			txa
			beq	:2
			LoadW	r0,V071c0
			LoadW	r1,V072z1
			jsr	MoveData

			clc
			lda	r1L
			adc	r2L
			sta	r6L			;Low: Zeiger auf Datei-Name.
			sta	r14L			;Low: Zeiger auf Anfang Tabelle.
			sta	r15L			;Low: Zeiger auf Anfang Tabelle.
			lda	r1H
			adc	r2H
			sta	r6H			;High: Zeiger auf Datei-Name.
			sta	r14H			;High: Zeiger auf Anfang Tabelle.
			sta	r15H			;High: Zeiger auf Anfang Tabelle.

::2			lda	#$00			;Datei-Typ für Tabelle.
			sta	r7L
			LoadB	r7H,255			;Max. 255 Dateien einlesen.
::2a			lda	#$ff
			sta	r10L
::2b			lda	#$ff
			sta	r10H
			jsr	FindFTypes		;Dateien suchen.
			txa
			beq	:3
			jmp	DiskError		;Disketten-Fehler.

::3			CmpBI	r7H,255			;Alle Dateien geprüft ?
			beq	:6			;Ja, weiter.

			ldy	#$00
::4			lda	(r15L),y		;Dateienamen-Tabelle konvertieren.
			sta	(r14L),y
			iny
			cpy	#$10
			bne	:4
			AddVBW	16,r14			;Zeiger auf nächsten Eintrag.
			AddVBW	17,r15			;Zeiger auf nächsten Eintrag.
			inc	r7H
			jmp	:3

::6			ldy	#$00			;Tabellen-Ende markieren.
			tya
			sta	(r14L),y

::7			lda	#$ff			;Zeiger auf Titelzeile.
			sta	r14L
::8			lda	#$ff
			sta	r14H
			LoadW	r15,V072z1		;Zeiger auf Tabelle.
			lda	#$00			;Einzel-Datei-Auswahl.
			ldx	#$10			;Namen 16 Zeichen lang.
			ldy	V071e0			;Keine "Action-Files".
			jsr	DoScrTab		;Auswahl-Tabelle.

			CmpBI	sysDBData,1		;Abbruch ?
			bne	:11			;Ja, Ende...

::9			cpx	V071e0			;Laufwerk wechseln ?
			bcs	:10			;Nein, weiter...
			txa
			add	$08
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa
			beq	:91
			jmp	DiskError		;Disketten-Fehler.
::91			jmp	:0			;Neue Tabelle einlesen.

::10			ldy	#$10
			lda	#$00
			sta	(r15L),y		;Ende des Datei-Eintrag markieren.

			ldx	#$00			;Eintrag ab ":r15". OK!
			b $2c
::11			ldx	#$ff			;Abbruch!

			txa				;Zurück.
			rts

;*** Desk-Accessoires laden.
:Get_DAs		LoadW	r10,$0000		;":Class" nicht überprüfen.
			lda	#DESK_ACC
			ldx	#<V071d0
			ldy	#>V071d0
			jsr	Get_SlctTab		;Auswahlbox.
			beq	:1
			jmp	NewMenu			;Zum Menü zurück.

::1			jsr	OrgGEOSCol
			MoveW	r15,r6			;DA laden.
			LoadB	r10L,$00
			jsr	GetFile
			txa
			beq	:2
			jmp	DiskError		;Disketten-Fehler.
::2			jmp	NewScreen		;Zum Menü zurück.

;*** Anwendungen laden.
:Get_Apps		LoadW	r10,$0000		;":Class" nicht überprüfen.
			lda	#APPLICATION
			ldx	#<V071d1
			ldy	#>V071d1
			jsr	Get_SlctTab		;Auswahlbox.
			beq	:1
			jmp	NewMenu			;Zum Menü zurück.

::1			jsr	OrgGEOSCol
			MoveW	r15,r6			;Anwendung laden.
			LoadB	r0L,%00000000
			jsr	GetFile
			jmp	EnterDeskTop		;Bei Fehler, Abbruch zum DeskTop.

;*** Dokument laden.
:Get_AllDoks		LoadW	r10,$0000		;":Class" nicht überprüfen.
			ldx	#<V071d2
			ldy	#>V071d2
			jmp	Get_Doks
:Get_gW_Doks		LoadW	r10,V071b2
			ldx	#<V071d3
			ldy	#>V071d3
:Get_Doks		lda	#APPL_DATA
			jsr	Get_SlctTab		;Auswahlbox.
			beq	:2
::1			jmp	NewMenu			;Zum Menü zurück.

::2			ldy	#$0f
::21			lda	(r15L),y
			sta	V071f1,y
			dey
			bpl	:21

			MoveW	r15,r6			;Datei suchen.
			jsr	FindFile
			txa
			bne	:21a
			LoadW	r9,dirEntryBuf		;Info-Block laden.
			jsr	GetFHdrInfo
			txa
			beq	:22
::21a			jmp	DiskError		;Disketten-Fehler.

::22			ldy	#$0b			;Klasse in Speicher übertragen.
::3			lda	fileHeader+$75,y
			sta	V071f2,y
			dey
			bpl	:3
			ldx	#r0L			;Disketten-Name in Speicher
			jsr	GetPtrCurDkNm		;übertragen.
			ldy	#$0f
::31			lda	(r0L),y
			sta	V071f3,y
			dey
			bpl	:31

			jsr	SetDrvDat		;Laufwerke ermitteln.

			ldx	#$00
::4			stx	V071f4
			lda	V071a0,x
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			txa
			bne	:42
			jsr	OpenDisk		;Diskette öffnen.
			txa
			bne	:42
::41			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,V071f2
			LoadW	r6,V071f0
			jsr	FindFTypes		;Applikation suchen.
			txa
			beq	:43
::42			jmp	DiskError		;Disketten-Fehler.
::43			lda	r7H			;Applikation gefunden ?
			beq	:5			;Ja, weiter.
			ldx	V071f4			;Nächstes Laufwerk.
			inx
			cpx	#$02
			bne	:4
			jmp	NewMenu			;Keine Applikation, zurück zum Menü.

::5			jsr	OrgGEOSCol
			LoadW	r2,V071f3		;Dokument laden.
			LoadW	r3,V071f1
			LoadW	r6,V071f0
			LoadB	r0L,%10000000
			jsr	GetFile
			jmp	EnterDeskTop		;Bei Fehler, zurück zum DeskTop.

;*** Icons & Menüs.
:icon_Tab1		b MaxIcons
			w $0000
			b $00

			w icon_Close
			b 0,0
			b icon_Close_x,icon_Close_y
			w ExitDT_a

			w icon_gW
			b 2,164
			b icon_gW_x,icon_gW_y
			w RunGW

			w icon_RunUp
			b 35,164
			b icon_RunUp_x,icon_RunUp_y
			w RunUp

:icon_RunUp
<MISSING_IMAGE_DATA>
:icon_RunUp_x		= .x
:icon_RunUp_y		= .y

:icon_gW
<MISSING_IMAGE_DATA>
:icon_gW_x		= .x
:icon_gW_y		= .y

;*** Programme laden.
:RunUp_Menu		b 98,155
			w 184,303
			b 4 ! VERTICAL ! CONSTRAINED

			w Menu0_Text1
			b MENU_ACTION
			w Get_Apps

			w Menu0_Text2
			b MENU_ACTION
			w Get_AllDoks

			w Menu0_Text3
			b MENU_ACTION
			w Get_DAs

			w Menu0_Text4
			b MENU_ACTION
			w ExitRunMenu

:Menu0_Text1		b PLAINTEXT,BOLDON
			b "Anwendung starten",NULL
:Menu0_Text2		b PLAINTEXT,BOLDON
			b "Dokument öffnen",NULL
:Menu0_Text3		b PLAINTEXT,BOLDON
			b "Desk-Accessories",NULL
:Menu0_Text4		b PLAINTEXT,BOLDON
			b "Zurück zu geoDOS",NULL

;*** Programme laden.
:RunGW_Menu		b 98,141
			w 16,135
			b 3 ! VERTICAL ! CONSTRAINED

:IsGWonDsk		w Menu0_Text5
			b MENU_ACTION
			w Get_gW

			w Menu0_Text6
			b MENU_ACTION
			w Get_gW_Doks

			w Menu0_Text7
			b MENU_ACTION
			w ExitRunMenu

:Menu0_Text5		b PLAINTEXT,BOLDON
			b "geoWrite starten",NULL
:Menu0_Text6		b PLAINTEXT,BOLDON
			b "geoWrite-Dokumente",NULL
:Menu0_Text7		b PLAINTEXT,BOLDON
			b "Zurück zu geoDOS",NULL

;*** Daten für Haupt-Menü.
:Main_Menu		b 8,23
			w 0,208
			b 4 ! HORIZONTAL ! UN_CONSTRAINED

			w Menu1_Text1
			b SUB_MENU
			w Menu1_Sub1

			w Menu2_Text1
			b SUB_MENU
			w Menu2_Sub1

			w Menu3_Text1
			b SUB_MENU
			w Menu3_Sub1

			w Menu4_Text1
			b SUB_MENU
			w Menu4_Sub1

:Menu1_Text1		b PLAINTEXT,BOLDON
			b "GEOS",NULL
:Menu2_Text1		b "Kopieren",NULL
:Menu3_Text1		b "DOS Menü",NULL
:Menu4_Text1		b "CBM Menü",NULL

:Menu1_Sub1		b 23,80
			w 0,63
			b 4 ! VERTICAL ! CONSTRAINED

			w Menu1_STxt1
			b MENU_ACTION
			w m_Info

			w Menu1_STxt2
			b MENU_ACTION
			w ExitDT_a

			w Menu1_STxt3
			b MENU_ACTION
			w ExitDT

			w Menu1_STxt4
			b MENU_ACTION
			w ExitBasic

:Menu1_STxt1		b PLAINTEXT,BOLDON
			b "Info",NULL
:Menu1_STxt2		b "DeskTop",NULL
:Menu1_STxt3		b "Verlassen",NULL
:Menu1_STxt4		b "BASIC",NULL

:Menu2_Sub1		b 23, 94
			w 33,130
			b 5 ! VERTICAL ! CONSTRAINED

			w Menu2_STxt1
			b MENU_ACTION
			w m_SetOptions

			w Menu2_STxt2
			b MENU_ACTION
			w m_DOStoCBM

			w Menu2_STxt3
			b MENU_ACTION
			w m_CBMtoDOS

			w Menu2_STxt4
			b MENU_ACTION
			w m_DOStoGW

			w Menu2_STxt5
			b MENU_ACTION
			w m_GWtoDOS

:Menu2_STxt1		b PLAINTEXT,BOLDON,"Parameter",NULL
:Menu2_STxt2		b "DOS -> CBM",NULL
:Menu2_STxt3		b "CBM -> DOS",NULL
:Menu2_STxt4		b "DOS -> geoWrite",NULL
:Menu2_STxt5		b "geoWrite -> DOS",NULL

:Menu3_Sub1		b 23,94
			w 86,204
			b 5 ! VERTICAL ! CONSTRAINED

			w Menu3_STxt1
			b MENU_ACTION
			w m_DOS_Format

			w Menu3_STxt2
			b MENU_ACTION
			w m_DOS_Dir

			w Menu3_STxt3
			b MENU_ACTION
			w m_DOS_Rename

			w Menu3_STxt4
			b MENU_ACTION
			w m_DOS_RenFile

			w Menu3_STxt5
			b MENU_ACTION
			w m_DOS_DelFile

:Menu3_STxt1		b PLAINTEXT,BOLDON
			b "Formatieren",NULL
:Menu3_STxt2		b "Directory anzeigen",NULL
:Menu3_STxt3		b "Diskette umbenennen",NULL
:Menu3_STxt4		b "Dateien umbenennen",NULL
:Menu3_STxt5		b "Dateien löschen",NULL

:Menu4_Sub1		b 23,108
			w 146,264
			b 6 ! VERTICAL ! CONSTRAINED

			w Menu4_STxt1
			b MENU_ACTION
			w m_CBM_Format

			w Menu4_STxt2
			b MENU_ACTION
			w m_CBM_Dir

			w Menu4_STxt3
			b MENU_ACTION
			w m_SlctPart

			w Menu4_STxt4
			b MENU_ACTION
			w m_CBM_Rename

			w Menu4_STxt5
			b MENU_ACTION
			w m_CBM_RenFile

			w Menu4_STxt6
			b MENU_ACTION
			w m_CBM_DelFile

:Menu4_STxt1		b PLAINTEXT,BOLDON
			b "Formatieren",NULL
:Menu4_STxt2		b "Directory anzeigen",NULL
:Menu4_STxt3		b "Partitionen",NULL
:Menu4_STxt4		b "Diskette umbenennen",NULL
:Menu4_STxt5		b "Dateien umbenennen",NULL
:Menu4_STxt6		b "Dateien löschen",NULL

;*** Titel-Zeile.
:Titel_Zeile		b PLAINTEXT,"geoDOS 64"
			b NULL

;*** Variablen.
:V071a0			b $00,$00
:V071a1			b $00

:V071b0			b "geoWrite    ",NULL
:V071b1			s 17
:V071b2			b "Write Image ",NULL

:V071c0			b "Laufwerk A:     "
			b "Laufwerk B:     "

:V071d0			b PLAINTEXT,REV_ON
			b "Desk-Accessories",NULL
:V071d1			b PLAINTEXT,REV_ON
			b "Anwendungen",NULL
:V071d2			b PLAINTEXT,REV_ON
			b "Dokumente",NULL
:V071d3			b PLAINTEXT,REV_ON
			b "geoWrite-Dokumente",NULL

:V071e0			b $00

:V071f0			s 17
:V071f1			s 17
:V071f2			s 13
:V071f3			s 17
:V071f4			b $00

:V071g0			w $0000

;*** Lade-Fehler.
:V071h0			b $01
			b 56,127
			w 64,255
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V071h1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V071h2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V071h1			b PLAINTEXT,BOLDON
			b "geoWrite nicht auf",NULL
:V071h2			b "Laufwerk A: oder B: !",NULL

;*** L072: Source & Target-Drive wählen.
;    xReg = Source-Typ ($00=CBM, $FF=DOS)
;    yReg = Target-Typ ($00=CBM, $FF=DOS)
;    AKKU = Schreibschutz/Laufwerkswahl.
;           %00xxxxxx Kein Schreibschutz.
;           %01xxxxxx Schreibschutz Source-Drive.
;           %10xxxxxx Schreibschutz Target-Drive.
;           %11xxxxxx Schreibschutz Source- & Target-Drive.
;           %xxxxxxx0 Nur Action-Drive wählen.
;           %xxxxxxx1 Source- & Target-Drive wählen.

:Pos0x			= 40
:Pos0y			= 56
:Icon0x			= Pos0x+ 64
:IconAx			= Pos0x+ 16
:IconBx			= Pos0x+ 56
:IconCx			= Pos0x+ 96
:IconDx			= Pos0x+136
:Icon0y			= Pos0y+ 32
:IconSy			= Pos0y+  0
:IconTy			= Pos0y+ 72

:GetSTDrive		stx	V072a0			;Laufwerks-Typ Source.
			sty	V072a1			;Laufwerks-Typ Target.
			pha
			and	#%11000000		;Schreibschutz.
			sta	V072a2
			pla
			and	#%00000001		;Source-Drive wählen ?
			sta	V072a3

			MoveB	Source_Drv,V072a6
			MoveB	Target_Drv,V072a7

::1			LoadW	r0,V072d0		;Laufwerk wählen.
			RecDlgBoxL072RVec
			lda	sysDBData
			cmp	#$01
			beq	:2
::1a			ldx	#$ff			;Abbruch...
			rts

::2			lda	V072a6
			jsr	TestDrive		;Laufwerk testen.
			bne	:1			;Fehler.
			ldx	V072a0			;DOS-Drive wählen ?
			beq	:3			;Nein, weiter...
			lda	V072a6
			jsr	TstDOSDrv
			bne	:1
::3			bit	V072a2			;Schreibschutz testen ?
			bvc	:4			;Nein, weiter...
			lda	V072a6
			jsr	GetWrProt
			bmi	:1a
			bne	:1

::4			lda	V072a7
			jsr	TestDrive		;Laufwerk testen.
			bne	:1			;Fehler.
			ldx	V072a1			;DOS-Drive wählen ?
			beq	:5			;Nein, weiter...
			lda	V072a7
			jsr	TstDOSDrv
			bne	:1

::5			bit	V072a2			;Schreibschutz testen ?
			bpl	:6			;Nein, weiter...
			lda	V072a7
			jsr	GetWrProt
			bmi	:1a
			bne	:1

::6			lda	V072a7			;Source & Target-Drive vergleichen.
			ldx	V072a3
			beq	:7
			cmp	V072a6			;Beide gleich ?
			bne	:7			;Nein, weiter...
			jsr	WrongConfig		;Fehler, Source & Target gleich.
			jmp	:1
::7			sta	Target_Drv
			ldx	V072a6
			stx	Source_Drv
			jsr	NewDrive		;Laufwerk aktivieren.
			rts

;*** Farben zurücksetzen.
:L072RVec		PushB	r2L
			jsr	i_FillRam
			w	30,COLOR_MATRIX+4*40+5
			b	$b1
			PopB	r2L
			rts

;*** Window beenden.
:L072ExitW		LoadB	sysDBData,2
			jmp	RstrFrmDialogue

;*** Laufwerks-Icon wurde angelickt.
:SelectDrive		ClrB	V072a8
::1			lda	V072a8
			asl
			asl
			asl
			tax
			ldy	#$00
::2			lda	IconRegions,x
			sta	r2L,y
			inx
			iny
			cpy	#$06
			bne	:2

			php				;Prüfen ob Maus auf
			sei				;aktivem Icon (Nr. in ":V072a8")
			jsr	IsMseInRegion
			plp
			tax
			bne	:4
			inc	V072a8
			lda	V072a8
			cmp	#$09
			bne	:1

::3			NoMseKey
			rts

::4			lda	V072a8			;Klick auf C64-Icon ignorieren.
			beq	:3
			cmp	#$05			;Klick auf Source-Drive ?
			bcs	:6			;Nein, Target-Drive angeklickt.

			ldx	V072a3			;Auswahl Source-Drive erlaubt ?
			beq	:5			;Nein, Mausklick ignorieren.
			add	$07
			tax
			lda	DriveTypes-8,x
			beq	:3
			stx	V072a6
			jsr	Source_Line		;Neues Source-Drive setzen.
::5			jmp	:3

::6			add	$03
			tax
			lda	DriveTypes-8,x
			beq	:3
			stx	V072a7
			jsr	Target_Line		;Neues Target-Drive setzen.
			jsr	:3
			lda	V072a3
			beq	:7
			rts

::7			LoadB	sysDBData,1
			jmp	RstrFrmDialogue

;*** Laufwerk testen.
:TestDrive		tax
			lda	DriveTypes-8,x
			beq	:3
			txa
			jsr	SetDevice
			txa
			beq	:2
::1			ldx	#$0d
			jmp	DiskError
::2			ldx	#$00
			rts

;*** Fehler: Laufwerk nicht verfügbar!
::3			txa
			add	$39
			sta	V072f1+11
			LoadW	r0,V072f0
			ClrDlgBoxCSet_Grau
			ldx	#$ff
			rts

;*** Auf DOS-Laufwerk testen.
:TstDOSDrv		tax				;Gewähltes Laufwerk
			lda	DriveModes-8,x		;DOS-Kompatibel ?
			and	#%00010000		;Ja, 1581, FD2 oder FD4.
			bne	:1

			txa				;Kein DOS-Drive.
			add	$39
			sta	V072e1+11
			LoadW	r0,V072e0
			ClrDlgBoxCSet_Grau
			ldx	#$ff
			rts

::1			ldx	#$00
			rts

;*** Quell- und Ziel-Laufwerk sind gleich.
:WrongConfig		LoadW	r0,V072h0
			ClrDlgBoxCSet_Grau
			rts

;*** Schreibschutz testen.
:GetWrProt		tax
			ldy	DriveTypes-8,x
			lda	V072a4,y
			pha
			lda	V072a5,y
			pha
			txa
			jsr	NewDrive
			rts

;*** Kein Schreibschutz.
:WrProtOK		ldx	#$00
			rts

;*** Disk ist Schreibgeschützt.
:WrProtErr		lda	curDrive
			add	$39
			sta	V072g1+23
			LoadW	r0,V072g0
			ClrDlgBoxCSet_Grau
			CmpBI	sysDBData,$01
			beq	:1

			ldx	#$ff
			rts
::1			ldx	#$7f
			rts

;*** Schreibschutz bei 1541/1571.
:Wr1541_71		InitSPort			;GEOS-Turbo aus und I/O einschalten.
			CxSend	V072c0
			CxReceiveV072c1
			jsr	DoneWithIO

			lda	V072c1+2
			and	#%00010000
			bne	:1
			jmp	WrProtErr
::1			ldx	#$00
			rts

;*** Schreibschutz bei 1581.
:Wr1581			lda	#$b6
			jsr	SendJob
			cmp	#$02
			bcc	:4
			cmp	#$08
			bne	:3
			jmp	WrProtErr

::3			lda	curDrive
			ldx	#$7f
			jsr	InsertDisk
			cmp	#$01
			beq	Wr1581

			ldx	#$ff
			rts
::4			ldx	#$00
			rts

;*** Grafik auf Bildschirm.
:PutGrafik		SetColRam29,4*40+6,$61

			Pattern	1
			FillRec	32,39,48,279

			jsr	UseGDFont
			PrintXY	58,38,V072b0
			jsr	UseSystemFont

			LoadW	r0,C64
			LoadB	r1L,Icon0x / 8
			LoadB	r1H,Icon0y
			LoadB	r2L,C64_x
			LoadB	r2H,C64_y
			jsr	BitmapUp

			lda	V072a3
			beq	:1

			LoadW	r0,CopyInfo
			LoadB	r1L,Icon0x / 8 +14
			LoadB	r1H,Icon0y     - 4
			LoadB	r2L,CopyInfo_x
			LoadB	r2H,CopyInfo_y
			jsr	BitmapUp

::1			ClrB	V072a8
::2			lda	V072a3
			beq	:4
			ldx	V072a8
			lda	DriveTypes,x
			asl
			asl
			asl
			tax
			ldy	#$00
::3			lda	IconType,x
			sta	r0L,y
			inx
			iny
			cpy	#$06
			bne	:3
			ldx	V072a8
			lda	IconXPos,x
			sta	r1L
			LoadB	r1H,Pos0y
			jsr	BitmapUp

::4			ldx	V072a8
			lda	DriveTypes,x
			asl
			asl
			asl
			tax
			ldy	#$00
::5			lda	IconType,x
			sta	r0L,y
			inx
			iny
			cpy	#$06
			bne	:5
			ldx	V072a8
			lda	IconXPos,x
			sta	r1L
			LoadB	r1H,Pos0y+72
			jsr	BitmapUp

::6			inc	V072a8
			CmpBI	V072a8,4
			beq	:7
			jmp	:2

::7			lda	V072a3
			beq	:8
			jsr	Source_Line
::8			jsr	Target_Line

			MseXYPos220,60
			rts

;*** Verbindung zwischen C64 und
;    Source-Drive darstellen.
:Source_Line		jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO  ,<IconAx   ,>IconAx   ,IconSy+16
			b	RECTANGLETO,<IconDx+23,>IconDx+23,IconSy+31
			b	NULL

			Pattern	1

			lda	V072a6
			sub	$08
			tax
			ldy	DrvLine_x1,x
			dey
			tya
			clc
			sta	r3L
			adc	#$02
			sta	r4L
			lda	#$00
			sta	r3H
			sta	r4H
			LoadB	r2L,IconSy+16
			LoadB	r2H,IconSy+24
			jsr	Rectangle

			lda	V072a6
			sub	$08
			tax
			lda	DrvLine_x1,x
			cpx	#$02
			bcs	:1
			sta	r3L
			LoadB	r4L,Icon0x+24
			jmp	:2

::1			sta	r4L
			LoadB	r3L,Icon0x+24

::2			lda	#$00
			sta	r3H
			sta	r4H
			LoadB	r2L,IconSy+23
			LoadB	r2H,IconSy+25
			jsr	Rectangle

			FillRec	IconSy+24,IconSy+31,Icon0x+23,Icon0x+25
			rts

;*** Verbindung zwischen C64 und
;    Target-Drive darstellen.
:Target_Line		jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO  ,<IconAx   ,>IconAx   ,IconTy-16
			b	RECTANGLETO,<IconDx+23,>IconDx+23,IconTy- 1
			b	NULL

			Pattern	1

			lda	V072a7
			sub	$08
			tax
			ldy	DrvLine_x1,x
			dey
			tya
			clc
			sta	r3L
			adc	#$02
			sta	r4L
			lda	#$00
			sta	r3H
			sta	r4H
			LoadB	r2L,IconTy-8
			LoadB	r2H,IconTy-1
			jsr	Rectangle

			lda	V072a7
			sub	$08
			tax
			lda	DrvLine_x1,x
			cpx	#$02
			bcs	:1
			sta	r3L
			LoadB	r4L,Icon0x+24
			jmp	:2

::1			sta	r4L
			LoadB	r3L,Icon0x+24

::2			lda	#$00
			sta	r3H
			sta	r4H
			LoadB	r2L,IconTy-9
			LoadB	r2H,IconTy-7
			jsr	Rectangle

			FillRec	IconTy-16,IconTy-8,Icon0x+23,Icon0x+25
			rts

;*** Variablen.
:V072a0			b $00				;Typ Source-Laufwerk.
:V072a1			b $00				;Typ Target-Laufwerk.
:V072a2			b $00				;Schreibschutz.
:V072a3			b $00				;Anzahl Laufwerke.
:V072a4			b >WrProtOK -1
			b >Wr1541_71-1,>Wr1541_71-1,>Wr1581   -1
			b >WrProtOK -1,>WrProtOK -1,>WrProtOK -1
			b >WrProtOK -1,>WrProtOK -1
			b >Wr1581   -1,>Wr1581   -1,>Wr1581   -1
:V072a5			b <WrProtOK -1
			b <Wr1541_71-1,<Wr1541_71-1,<Wr1581   -1
			b <WrProtOK -1,<WrProtOK -1,<WrProtOK -1
			b <WrProtOK -1,<WrProtOK -1
			b <Wr1581   -1,<Wr1581   -1,<Wr1581   -1
:V072a6			b $00				;Source-Laufwerk.
:V072a7			b $00				;Target-Laufwerk.
:V072a8			b $00

:V072b0			b PLAINTEXT,REV_ON,"Laufwerk wählen",NULL

:V072c0			w $0006
			b "M-R",$00,$1c,$01
:V072c1			w $0001
			b $00

:V072d0			b $01
			b 32,159
			w 40,279
			b DB_USR_ROUT
			w PutGrafik
			b DBOPVEC
			w SelectDrive
			b DBUSRICON,  0,  0		;Close-Icon
			w V072d1
			b OK	 ,22,24
			b CANCEL ,22,96
			b NULL

:V072d1			w icon_Close
			b 0,0
			b icon_Close_x,icon_Close_y
			w L072ExitW

;*** "Laufwerk nicht DOS-Kompatibel"
:V072e0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V072e1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V072e2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V072e1			b PLAINTEXT,BOLDON
			b "Laufwerk x: ist nicht",NULL
:V072e2			b "DOS-Kompatibel !",PLAINTEXT,NULL

;*** "Laufwerk nicht verfügbar"
:V072f0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V072f1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V072f2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V072f1			b PLAINTEXT,BOLDON
			b "Laufwerk x: ist nicht",NULL
:V072f2			b "verfügbar !",PLAINTEXT,NULL

;*** "Laufwerk ist schreibgeschützt"
:V072g0			b $01
			b 56,127
			w 64,255
			b OK        ,  2, 48
			b CANCEL    , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V072g1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V072g2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V072g1			b PLAINTEXT,BOLDON
			b "Diskette in Laufwerk x:",NULL
:V072g2			b "ist schreibgeschützt !",PLAINTEXT,NULL

;*** "Source & Target sind gleich"
:V072h0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V072h1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V072h2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V072h1			b PLAINTEXT,BOLDON
			b "Das Quell- und Ziel-",NULL
:V072h2			b "Laufwerk sind gleich!",PLAINTEXT,NULL

;*** Adresse, x- & y-Werte der Laufwerk-Icons
:IconType		w NoDrive,NULL
			b NoDrive_x,NoDrive_y ,NULL,NULL
			w Drive_41,NULL
			b Drive_41_x,Drive_41_y ,NULL,NULL
			w Drive_71,NULL
			b Drive_71_x,Drive_71_y ,NULL,NULL
			w Drive_81,NULL
			b Drive_81_x,Drive_81_y ,NULL,NULL
			w Drive_R41,NULL
			b Drive_R41_x,Drive_R41_y ,NULL,NULL
			w Drive_R71,NULL
			b Drive_R71_x,Drive_R71_y ,NULL,NULL
			w Drive_R81,NULL
			b Drive_R81_x,Drive_R81_y ,NULL,NULL
			w Drive_RL,NULL
			b Drive_RL_x,Drive_RL_y ,NULL,NULL
			w Drive_RD,NULL
			b Drive_RD_x,Drive_RD_y ,NULL,NULL
			w Drive_FD2,NULL
			b Drive_FD2_x,Drive_FD2_y ,NULL,NULL
			w Drive_FD4,NULL
			b Drive_FD4_x,Drive_FD4_y ,NULL,NULL
			w Drive_HD,NULL
			b Drive_HD_x,Drive_HD_y ,NULL,NULL

;*** x-Position der Laufwerk-Icons.
:IconXPos		b IconAx / 8
			b IconBx / 8
			b IconCx / 8
			b IconDx / 8

;*** Position der Verbindungslinien.
:DrvLine_x1		b IconAx+12
			b IconBx+12
			b IconCx+12
			b IconDx+12

;*** Bereich für Laufwerk-Icons.
:IconRegions		b Pos0y+ 32,Pos0y+ 55
			w Pos0x+ 64,Pos0x+119,NULL

			b IconSy+0,IconSy+15
			w IconAx+0,IconAx+23,NULL
			b IconSy+0,IconSy+15
			w IconBx+0,IconBx+23,NULL
			b IconSy+0,IconSy+15
			w IconCx+0,IconCx+23,NULL
			b IconSy+0,IconSy+15
			w IconDx+0,IconDx+23,NULL

			b IconTy+0,IconTy+15
			w IconAx+0,IconAx+23,NULL
			b IconTy+0,IconTy+15
			w IconBx+0,IconBx+23,NULL
			b IconTy+0,IconTy+15
			w IconCx+0,IconCx+23,NULL
			b IconTy+0,IconTy+15
			w IconDx+0,IconDx+23,NULL

:NoDrive
<MISSING_IMAGE_DATA>
:NoDrive_x		= .x
:NoDrive_y		= .y

:Drive_41
<MISSING_IMAGE_DATA>
:Drive_41_x		= .x
:Drive_41_y		= .y

:Drive_71
<MISSING_IMAGE_DATA>
:Drive_71_x		= .x
:Drive_71_y		= .y

:Drive_81
<MISSING_IMAGE_DATA>
:Drive_81_x		= .x
:Drive_81_y		= .y

:Drive_FD2
<MISSING_IMAGE_DATA>
:Drive_FD2_x		= .x
:Drive_FD2_y		= .y

:Drive_FD4
<MISSING_IMAGE_DATA>
:Drive_FD4_x		= .x
:Drive_FD4_y		= .y

:Drive_HD
<MISSING_IMAGE_DATA>
:Drive_HD_x		= .x
:Drive_HD_y		= .y

:Drive_R41
<MISSING_IMAGE_DATA>
:Drive_R41_x		= .x
:Drive_R41_y		= .y

:Drive_R71
<MISSING_IMAGE_DATA>
:Drive_R71_x		= .x
:Drive_R71_y		= .y

:Drive_R81
<MISSING_IMAGE_DATA>
:Drive_R81_x		= .x
:Drive_R81_y		= .y

:Drive_RL
<MISSING_IMAGE_DATA>
:Drive_RL_x		= .x
:Drive_RL_y		= .y

:Drive_RD
<MISSING_IMAGE_DATA>
:Drive_RD_x		= .x
:Drive_RD_y		= .y

:C64
<MISSING_IMAGE_DATA>
:C64_x			= .x
:C64_y			= .y

:CopyInfo
<MISSING_IMAGE_DATA>
:CopyInfo_x		= .x
:CopyInfo_y		= .y

;*** Speicher.
:V072z0
:V072z1			=(V072z0 / 256 +1) * 256
