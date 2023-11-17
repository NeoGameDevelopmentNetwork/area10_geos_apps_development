; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS64.MakeBoot"
			t "G3_SymMacExt"
			t "G3_V.Cl.64.Apps"

			o $0400

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Installiert auf der"
			h "Startdiskette einen neuen"
			h "Laufwerkstreiber..."
endif

if Sprache = Englisch
			h "Install new diskdriver"
			h "on bootdisk..."
endif

;*** Auf GEOS-MegaPatch testen.
;    GEOS-Boot mit MP3: Rückkehr zum Hauptprogramm.
;    GEOS-Boot mit V2x: Sofortiges Programm-Ende.
;    Programmstart V2x: Fehler ausgeben, zurück zum DeskTop.
:MainInit		jsr	FindMegaPatch		;MegaPatch installiert ?
			jsr	ClearScreen		;Bildschirm löschen und

			LoadW	r0,Dlg_Patch		;Infobox ausgeben. Dadurch wird
			jsr	DoDlgBox		;die MakeBoot-Funktion gestartet!

			ldx	sysDBData
			cpx	#NO_ERROR		;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			LoadW	r0,Dlg_PatchOK		;Abschlußmeldung ausgeben.
			jsr	DoDlgBox

			jmp	EnterDeskTop		;Ende...
::51			jmp	DiskError

;*** Bootdisk erstellen.
:MakeSysDisk		lda	curDrive
			jsr	SetDevice
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:2			; => Nein, weiter...
::1			jmp	:5			; => Ja, abbruch...

::2			jsr	ClrInfoArea
			LoadW	r6,FName1
			jsr	GetMegaFile		;Systemdatei von Diskette laden.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			LoadW	r0,FName1
			jsr	DelMegaFile		;Original-Datei löschen.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			PushW	r1			;Statusanzeige aktualisieren.
			jsr	PrintArea050p
			PopW	r1

;--- Ergänzung: 01.12.19/M.Kanet
;Nur bei DDX-Treibern Register löschen,
;da sonst evtl. Code verändert wird!
			jsr	DDX_Check		;MegaPatch mit DDX?
			bne	:3			; => Nein, weiter...

			PushB	DDRV_EXT_DATA1		;DDX-Variablen in MP33r6 löschen.
			PushB	DDRV_EXT_DATA2

			lda	#$00			;DDX-Register zurücksetzen.
			sta	DDRV_EXT_DATA1
			sta	DDRV_EXT_DATA2

::3			LoadW	r0,DISK_BASE		;Treiber in Systemdatei übertragen.
			LoadW	r2,DISK_DRIVER_SIZE
			jsr	MoveData

			jsr	DDX_Check		;MegaPatch mit DDX?
			bne	:4			; => Nein, weiter...

			PopB	DDRV_EXT_DATA2		;DDX-Variablen zurücksetzen.
			PopB	DDRV_EXT_DATA1

::4			LoadW	FInfoBlock,FName1
			jsr	PutMegaFile		;Systemdatei auf Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:1			; => Ja, Abbruch...

			jsr	PrintArea100p		;Statusanzeige aktualisieren.

			jsr	ClrInfoArea		;Info-Bereich löschen.

			LoadW	r6,FName2
			jsr	GetMegaFile		;Systemdatei von Diskette laden.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

			LoadW	r0,FName2
			jsr	DelMegaFile		;Original-Datei löschen.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

			PushW	r1			;Statusanzeige aktualisieren.
			jsr	PrintArea050p
			PopW	r1

			ldy	#$03
			lda	curDrive		;Startlaufwerk einlesen und in
			sta	(r1L),y			;Systemdatei übertragen.
			tax
			iny
			lda	DiskDrvType		;Laufwerkstyp in Systemdatei
			sta	(r1L),y			;übertragen.
			iny
			lda	RealDrvMode -8,x	;Laufwerksmodi in Systemdatei
			sta	(r1L),y			;übertragen.

			LoadW	FInfoBlock,FName2
			jsr	PutMegaFile		;Systemdatei auf Diskette schreiben.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

			jsr	PrintArea100p		;Abschlußanzeige.

			ldx	#NO_ERROR
::5			stx	sysDBData
			LoadW	appMain,RstrFrmDialogue
			rts

;*** Startprogramm einlesen.
:GetMegaFile		lda	r6L			;Register ":r6" nach ":r0"
			sta	r0L			;kopieren und auf Stack retten.
			pha
			lda	r6H
			sta	r0H
			pha
			jsr	PutString
			jsr	PrintArea000p		;Fortschrittsanzeige.
			pla
			sta	r6H
			pla
			sta	r6L

			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			LoadW	r9,dirEntryBuf		;Infoblock einlesen.
			jsr	GetFHdrInfo

			jsr	i_MoveData		;Infoblock zwischenspeichern.
			w	fileHeader
			w	FInfoBlock
			w	$0100

			lda	dirEntryBuf +1		;Zeiger auf ersten Sektor.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			lda	FInfoBlock  +$48	;Zeiger auf Ladeadresse.
			sta	r7H
			pha
			lda	FInfoBlock  +$47
			sta	r7L
			pha
			LoadW	r2,$6000
			jsr	ReadFile		;Datei einlesen.
			pla
			clc				;Startadresse übergeben (immer
			adc	#$02			;zwei Byte größer, Dummy-Bytes
			sta	r1L			;des BASIC-Modus!).
			pla
			adc	#$00
			sta	r1H
::51			rts

;*** Startdatei löschen.
:DelMegaFile		PushW	r1
			PushW	r0
			jsr	PrintArea025p		;Fortschrittsanzeige.
			PopW	r0
			jsr	DeleteFile
			PopW	r1
			rts

;*** Neue Startdatei speichern.
:PutMegaFile		jsr	PrintArea075p		;Fortschrittsanzeige.

			LoadW	r9  ,FInfoBlock		;Zeiger auf Infoblock
			LoadB	r10L,$00
			jmp	SaveFile		;Datei speichern.

;*** Dialogbox für Diskettenfehler.
:DiskError		stx	r5L
			LoadW	r0,Dlg_DiskError
			jsr	DoDlgBox
			jmp	EnterDeskTop

;*** Dialogbox: Titelzeile ausgeben.
:Dlg_DrawTitle		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$20,$2f
			w	$0040,$00ff
			lda	#$10
			jmp	DirectColor

;*** Dialogbox: Fehlermeldung ausgeben.
:Dlg_DrawError		PushB	r5L
			LoadW	r0,Dlg_ErrText
			jsr	PutString
			PopB	r0L
			LoadB	r0H,$00
			lda	#%11000000
			jmp	PutDecimal

;*** Auf DDX testen.
:DDX_Check		lda	DiskDrvTypeExt +0
			eor	DiskDrvTypeExt +2
			eor	DiskDrvTypeExt +1
			cmp	#"X"			;MegaPatch mit DDX?
			rts

;*** Bildschirm löschen.
:ClearScreen		lda	#ST_WR_FORE		;Bildschirm löschen.
			sta	dispBufferOn

			jsr	GetBackScreen

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$b8,$c7
			w	$0000,$013f
			lda	#%11111111
			jsr	FrameRectangle
			lda	C_WinBack
			jmp	DirectColor

;*** Text ausgeben.
:PrintArea000p		LoadW	r4,118 +2* 000 -1
			lda	#0
			beq	PrintStatus
:PrintArea025p		LoadW	r4,118 +2* 025 -1
			lda	#25
			bne	PrintStatus
:PrintArea050p		LoadW	r4,118 +2* 050 -1
			lda	#50
			bne	PrintStatus
:PrintArea075p		LoadW	r4,118 +2* 075 -1
			lda	#75
			bne	PrintStatus
:PrintArea100p		LoadW	r4,118 +2* 100 -1
			lda	#100
:PrintStatus		pha
			LoadB	r2L,$ba
			LoadB	r2H,$c5
			LoadW	r3,118
			lda	#$01
			jsr	SetPattern
			jsr	Rectangle
			pla
			sta	r0L
			lda	#$00
			sta	r0H
			LoadW	r11,$0052
			LoadB	r1H,$c2
			lda	#"("
			jsr	SmallPutChar
			lda	#%11000000
			jsr	PutDecimal
			lda	#"%"
			jsr	SmallPutChar
			lda	#")"
			jmp	SmallPutChar

;*** Fortschrittsanzeige.
:ClrInfoArea		jsr	i_GraphicsString
			b	NEWPATTERN,$00
			b	MOVEPENTO
			w	$0001
			b	$b9
			b	RECTANGLETO
			w	$013e
			b	$c6
			b	NEWPATTERN,$05
			b	MOVEPENTO
			w	$0076
			b	$ba
			b	RECTANGLETO
			w	$013d
			b	$c5
			b	FRAME_RECTO
			w	$0076
			b	$ba
			b	ESC_PUTSTRING
			w	$0008
			b	$c2
			b	NULL
			rts

;******************************************************************************
;*** MegaPatch installiert ?
;******************************************************************************
			t "-G3_FindMP"
;******************************************************************************

;*** Zwischenspeicher Infoblock.
:FInfoBlock		s 256

;*** Systemtexte.
:FName1			b "GEOS64.1",NULL
:FName2			b "GEOS64.BOOT",NULL

;*** Dialogbox für Diskettenfehler.
:Dlg_DiskError		b %11100001
			b DB_USR_ROUT
			w Dlg_DrawTitle
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$20
			w :52
			b DB_USR_ROUT
			w Dlg_DrawError
			b OK         ,$02,$48
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT,BOLDON
			b "Fehlermeldung",NULL
::52			b "Funktion abgebrochen:",NULL
endif
if Sprache = Englisch
::51			b PLAINTEXT,BOLDON
			b "Systemerror",NULL
::52			b "Function cancelled:",NULL
endif

:Dlg_ErrText		b GOTOXY
			w $0050
			b $50
if Sprache = Deutsch
			b "Diskettenfehler #",NULL
endif
if Sprache = Englisch
			b "Diskerror #",NULL
endif

;*** Dialogbox für "Startdiskette wird konfiguriert".
:Dlg_Patch		b %11100001
			b DB_USR_ROUT
			w Dlg_DrawTitle
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$20
			w :52
			b DBTXTSTR   ,$10,$2c
			w :53
			b DB_USR_ROUT
			w MakeSysDisk
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT,BOLDON
			b "GEOS.MakeBoot",NULL
::52			b "Die Startdiskette wird",NULL
::53			b "konfiguriert. Bitte warten...",NULL
endif
if Sprache = Englisch
::51			b PLAINTEXT,BOLDON
			b "GEOS.MakeBoot",NULL
::52			b "Bootdisk will be configured,",NULL
::53			b "please wait...",NULL
endif

;*** Dialogbox für "Startdiskette konfiguriert".
:Dlg_PatchOK		b %01100001
			b $20,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitle
			b DBTXTSTR   ,$10,$0b
			w :51
			b DBTXTSTR   ,$10,$20
			w :52
			b DBTXTSTR   ,$10,$2a
			w :53
			b DBTXTSTR   ,$10,$34
			w :54
			b DBTXTSTR   ,$10,$44
			w :60
			b DBTXTSTR   ,$10,$4e
			w :61
			b DBTXTSTR   ,$10,$58
			w :62
			b OK         ,$02,$60
			b NULL

if Sprache = Deutsch
::51			b PLAINTEXT,BOLDON
			b "GEOS.MakeBoot",NULL
::52			b "Startdiskette konfiguriert!",NULL
::53			b PLAINTEXT
			b "Sie können MegaPatch jetzt von",NULL
::54			b "dieser Diskette starten.",NULL
::60			b BOLDON
			b "HINWEIS: ",PLAINTEXT
			b "Eine Startdiskette benötigt",NULL
::61			b "zusätzlich eine DeskTop-Anwendung,",NULL
::62			b "z.B. eine Datei `DESK TOP` !",NULL
endif
if Sprache = Englisch
::51			b PLAINTEXT,BOLDON
			b "GEOS.MakeBoot",NULL
::52			b "Bootdisk configured!",NULL
::53			b PLAINTEXT
			b "You can now boot MegaPatch from",NULL
::54			b "this bootdisk.",NULL
::60			b BOLDON
			b "NOTE: ",PLAINTEXT
			b "A complete bootdisk also",NULL
::61			b "requires a desktop application file,",NULL
::62			b "like `DESK TOP` !",NULL
endif
