; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;geoConvert
;Dateiauswahl.

;*** Dateimenü aktivieren.
.OpenFiles		LoadW	curMenu,MenuFiles	;Zeiger auf Datei-Menü.
			jmp	StartMenu

;*** Eintrag aus Dateimanü wählen.
:SlctFNameMenuEntry	pha
			lda	FilesOnDisk		;Dateieinträge verfügbar ?
			beq	:101			;Ja, weiter...
::100			pla				;Nein, zurück und
			jmp	ReDoMenu		;Menü neu aufbauen.

::101			lda	FileConvMode		;Konvertierungsmodus einlesen.
			beq	:100			;Modus definiert ? Nein, Ende.

;*** Zeiger auf Listen-Eintrag berechnen.
			pla
			pha
			jsr	SetVecToFNameBuf	;Zeiger auf Dateieintrag.

;*** Weiter oder zum Anfang ?
			ldy	#$01
			lda	(a0L),y
			cmp	#BOLDON			;Datei gewählt ?
			bne	:102			;Ja, weiter...

;*** Dateiliste aktualisieren.
			pla
			jsr	RecoverMenu		;Menü abbauen.

			lda	MenuFiles_MaxEntries
			and	#%00111111
			sec
			sbc	#$02
			clc
			adc	CurFNameEntryInMenu
			sta	CurFNameEntryInMenu

			jsr	AddNextFilesToMenu	;Nächste Dateien einlesen.
			jmp	ReDoMenu		;Dateimenü aktivieren.

;*** Datei zum konvertieren auswählen.
::102			jsr	ClrScreen		;Bildschirm löschen.

			pla
			clc
			adc	CurFNameEntryInMenu
			sec
			sbc	#$01
			ldx	MenuFiles_Entry01 +1
			cpx	#BOLDON
			bne	:103
			sec
			sbc	#$01
::103			jsr	SetVecDirEntry		;Zeiger auf Datei berechnen.

			ldy	#$05
			ldx	#$00
::104			lda	(a0L),y			;Dateiname kopieren.
			beq	:105
			cmp	#$a0
			beq	:105
			sta	CurFileName,x
			iny
			inx
			cpx	#16
			bcc	:104
::105			lda	#$00
			sta	CurFileName,x
			inx
			cpx	#17
			bcc	:105

;*** Verzweigen zur Konvertierungs-Routine.
			lda	FileConvMode		;Konvertierungsroutine
			asl				;aufrufen.
			tax
			ldy	FileConvRout+0,x
			lda	FileConvRout+1,x
			tax
			tya
			jmp	CallRoutine

;*** Dateien einlesen.
.InitFileSlctMenu	lda	#$00			;Zeiger auf erste Datei.
			sta	CurFNameEntryInMenu

.ReadDirEntryToBuf	lda	#$00
			sta	FilesOnDisk		;Datei-Flag löschen.
			sta	MaxFilesOnDsk		;Dateizähler löschen.

			jsr	i_FillRam		;Speicher für Dateieinträge.
			w	DskImgMaxDirFiles*32	;löschen.
			w	DskImgDirData
			b	$00

			LoadB	MenuFiles +6,$01 ! VERTICAL ! CONSTRAINED

			ldy	FileConvMode		;Modus definiert ?
			beq	AddFilesToMenu		;Nein, Abbruch.

			lda	SourceDrive
			jsr	SetDevice
			jsr	NewOpenDisk		;Quell-Diskette öffnen.

			lda	curDirHead +$00
			sta	r1L
			lda	curDirHead +$01
			sta	r1H
			LoadW	r4,diskBlkBuf
			LoadW	a0,DskImgDirData

::101			jsr	GetBlock		;Verzeichnis-Sektor lesen.

			ldx	#$00
::102			jsr	TestCurDirEntry		;Eintrag gültig ?
			bcs	:105			;Nein, weiter...
			txa
			pha
			ldy	#$00
::103			lda	diskBlkBuf,x		;Dateieintrag kopieren.
			sta	(a0L),y
			inx
			iny
			cpy	#$20
			bne	:103
			AddVW	32,a0
			inc	MaxFilesOnDsk
			lda	MaxFilesOnDsk
			cmp	#DskImgMaxDirFiles
			bcc	:104
			pla
			jmp	AddFilesToMenu		;Dateispeicher voll!

::104			pla
			tax
::105			txa
			clc
			adc	#$20
			tax
			bne	:102			;Zeiger auf nächsten Eintrag.

			ldx	diskBlkBuf +1		;Nächsten Verzeichnis-Sektor
			lda	diskBlkBuf +0		;von Diskette einlesen.
			beq	AddFilesToMenu
			stx	r1H
			sta	r1L
			jmp	:101

;*** Dateien gefunden ?
.AddFilesToMenu		lda	MaxFilesOnDsk		;Dateien gefunden ?
			bne	AddNextFilesToMenu	;Ja, weiter...

			LoadW	r4,NoFiles		;Hinweis "Keine Dateien!"
			LoadW	r5,MenuFiles_Entry01
			ldx	#r4L
			ldy	#r5L
			jsr	CopyString

			LoadB	MenuFiles_YPosBottom,2*14+1
			LoadB	MenuFiles_MaxEntries,2 ! VERTICAL ! CONSTRAINED
			LoadB	CurFileName,NULL
			inc	FilesOnDisk
			rts

;*** Weitere Dateien in "Datei-Menü" einblenden.
:AddNextFilesToMenu	lda	CurFNameEntryInMenu
			cmp	MaxFilesOnDsk
			bcc	:100
			lda	#$00
			sta	CurFNameEntryInMenu

::100			lda	CurFNameEntryInMenu
			jsr	SetVecDirEntry

			MoveW	a0,r0
			LoadW	r1,MenuFiles_Entry01
			LoadB	r2L,$01
			LoadB	r2H,$0f

			lda	CurFNameEntryInMenu
			sta	r3L

			lda	MaxFilesOnDsk
			cmp	#MaxFileEntry
			bcc	:103

;			lda	MaxFilesOnDsk
;			sec
			sbc	r3L
			cmp	#MaxFileEntry -1
			bcs	:102

			LoadW	r4,Go1stTextFile
			ldx	#r4L
			lda	#$ff
			jsr	CopyFNameToMenu
			jmp	:103

::102			LoadW	r4,MoreTextFiles
			ldx	#r4L
			lda	#$ff
			jsr	CopyFNameToMenu

::103			ldy	#$02
			lda	(r0L),y
			beq	:104

			AddVW	5,r0
			ldx	#r0L
			lda	#$00
			jsr	CopyFNameToMenu
			AddVW	27,r0
			inc	r3L

			lda	r2L
			cmp	#MaxFileEntry
			beq	:104
			lda	r3L
			cmp	MaxFilesOnDsk
			bcc	:103
::104			lda	r2L
			ora	#VERTICAL ! UN_CONSTRAINED
			sta	MenuFiles_MaxEntries
			lda	r2H
			sta	MenuFiles_YPosBottom
			rts

;*** Prüfen ob Datei-Eintrag für Konvertierungsmodus gültig.
;    X: Zeiger auf 32-Byte-Verzeichniseintrag.
;    Rückgabe:
;    S-Flag: SEC=Eintrag ungültig.
;            CLC=Eintrag gültig.
;    X     : Zeiger auf 32-Byte-Verzeichniseintrag.
:TestCurDirEntry	ldy	FileConvMode		;Konvertierungsmodus gesetzt?
			beq	:101			;Nein, Fehler...

			ldy	diskBlkBuf +$02,x	;CBM-Dateityp einlesen.
			bne	:103			;<>$00 ? Ja, Weiter...
::101			sec				;Eintrag ungültig, Ende.
			rts
::102			clc				;Eintrag gültig, OK.
			rts

::103			ldy	FileConvMode		;Konvertierungsmodus gesetzt?
			cpy	#ConvMode_GEOS_CBM	;ConvMode_GEOS_CBM?
			bne	:104			;Nein, weiter...
			ldy	diskBlkBuf +$18,x	;GEOS-Dateityp einlesen.
			lda	GEOSValidTypeList+1,y	;In der Liste der erlaubten GEOS-Dateitypen?
			bne	:101			;Nein, Dateieintrag ungültig.
			beq	:102			;Ja,   Dateieintrag gültig.

::104			cpy	#ConvMode_CBM_GEOS	;ConvMode_CBM_GEOS?
			bne	:106			;Nein, weiter...
::105			ldy	diskBlkBuf +$15,x	;Datei-Typ REL?
			bne	:101			;Ja,   Dateieintrag ungültig.
			beq	:102			;Nein, Dateieintrag gültig.

::106			cpy	#ConvMode_DISK_D64	;ConvMode_DISK_D64?
			beq	:102			;Ja, Dateieintrag gültig.
			cpy	#ConvMode_DISK_D71	;ConvMode_DISK_D71?
			beq	:102			;Ja, Dateieintrag gültig.
			cpy	#ConvMode_DISK_D81	;ConvMode_DISK_D81?
			beq	:102			;Ja, Dateieintrag gültig.

			cpy	#ConvMode_D64_DISK	;ConvMode_D64_DISK?
			beq	:107			;Ja, weiter...
			cpy	#ConvMode_D71_DISK	;ConvMode_D71_DISK?
			beq	:107			;Ja, weiter...
			cpy	#ConvMode_D81_DISK	;ConvMode_D81_DISK?
			beq	:107			;Ja, weiter...
			cpy	#ConvMode_D64_FILE	;ConvMode_D64_FILE?
			beq	:107			;Ja, weiter...
			cpy	#ConvMode_D71_FILE	;ConvMode_D71_FILE?
			beq	:107			;Ja, weiter...
			cpy	#ConvMode_D81_FILE	;ConvMode_D81_FILE?
			bne	:108			;Nein, weiter...
::107			ldy	diskBlkBuf +$02,x	;CBM-Dateityp einlesen.
			cpy	#$80 ! PRG		;Bei D64->Disk oder D64->File
			beq	:102			;Keine GEOS/VLIR/REL-Dateien abieten.
			cpy	#$80 ! SEQ
			beq	:102
			bne	:101
::108			jmp	:105			;Auf Datei-Typ REL prüfen.

;** Dateiname in Tabelle kopieren, Zeiger auf nächsten Eintrag.
:CopyFNameToMenu	jsr	CopyConvTextEntry
::103			AddVW	17,r1
			AddVB	14,r2H
			inc	r2L
			rts

;*** Text in Dateiauswahl-Menü kopieren.
;    X:  Zeiger auf Vektor mit Original-Text (z.B. r0L, r4L...)
;    A:  $00=Name konvertieren
;        $ff=Name nicht konvertieren (z.B. "<< Hauptmenü")
;    r1: Zeiger auf Zwischenspeicher zum ablegen des texteintrages.
.CopyConvTextEntry	stx	:101 +1
			tax

			ldy	#$00
::101			lda	($ff),y
			cmp	#$a0
			beq	:102
			cpx	#$ff			;Dateiname?
			beq	:101b			;Nein, weiter...

			cmp	#$20			;Sonderzeichen aus Dateinamen löschen.
			bcc	:101a
			cmp	#$7f
			bcc	:101b			;Kein Sonderzeichen, weiter...
::101a			lda	#"-"			;Ersatzzeichen festlegen.

::101b			sta	(r1L),y			;Zeichen aus Text in Zwischenpuffer kopieren.
			iny				;Weiteres Zeichen kopieren?
			cpy	#16
			bcc	:101			;Ja, weiter...
::102			lda	#$00			;Zwischenspeicher mit $00-Bytes auffüllen.
			sta	(r1L),y
			iny
			cpy	#17
			bne	:102
			rts

;*** Zeiger auf Verzeichniseintrag.
.SetVecDirEntry		sta	a0L
			LoadB	a0H,$00
			LoadW	a1 ,$0020
			ldx	#a0L
			ldy	#a1L
			jsr	DMult
			AddVW	DskImgDirData,a0
			rts

;*** Zeiger auf Dateieintrag in PD-Menü kopieren.
:SetVecToFNameBuf	sta	a0L
			LoadB	a0H,$00
			LoadW	a1, $0011
			ldx	#a0L
			ldy	#a1L
			jsr	DMult
			AddVW	MenuFiles_Entry00,a0	;Zeiger auf Eintrag berechnen.
			rts

;*** Variablen.
.FileConvMode		b $00
:FileConvRout		w GotoFirstMenu			;$00
			w Mod_Convert_CVT		;$01  GEOS->CBM
			w Mod_Convert_CVT		;$02  CBM->GEOS
			w Mod_Convert_UUE		;$03  SEQ->UUE
			w Mod_Convert_UUE		;$04  SEQ->UUE Append
			w Mod_Convert_UUE		;$05  UUE->SEQ
			w Mod_DskImg_Create		;$06  DISK->D64
			w Mod_DskImg_Disk		;$07  D64->DISK
			w Mod_DskImg_File		;$08  D64->FILE - D64 wählen
			w Mod_DskImg_File		;$09  D64->File - Datei wählen
			w Mod_Convert_SEQ		;$0a  Split SEQ file
			w Mod_Convert_SEQ		;$0b  Merge SEQ files
			w Mod_DskImg_Create		;$0c  DISK->D81
			w Mod_DskImg_Disk		;$0d  D81->DISK
			w Mod_DskImg_File		;$0e  D81->FILE - D81 wählen
			w Mod_DskImg_File		;$0f  D81->FILE - Datei wählen
			w Mod_Convert_CVT		;$10  CVT->Convert all files
			w Mod_DskImg_Disk		;$11  D71->DISK
			w Mod_DskImg_File		;$12  D71->FILE - D71 wählen
			w Mod_DskImg_File		;$13  D71->FILE - Datei wählen

;*** Daten für Menü.
.MenuFiles		b $00
:MenuFiles_YPosBottom	b $1d
			w $0000
			w $005f

:MenuFiles_MaxEntries	b $02 ! VERTICAL ! UN_CONSTRAINED

			w MenuFiles_Entry00
			b MENU_ACTION
			w OpenMain

			w MenuFiles_Entry01
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry02
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry03
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry04
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry05
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry06
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry07
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry08
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry09
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry10
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry11
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry12
			b MENU_ACTION
			w SlctFNameMenuEntry

			w MenuFiles_Entry13
			b MENU_ACTION
			w SlctFNameMenuEntry

;*** Sondertexte für Dateiauswahl-Menü.
;    Byte $02 muss "BOLDON" sein damit das Programm
;    zwischen Dateiname und Sondertext unterscheiden kann.
if Sprache = Deutsch
:NoFiles		b PLAINTEXT,BOLDON,"Keine Dateien!",NULL
:MoreTextFiles		b PLAINTEXT,BOLDON,">> Weiter",PLAINTEXT,NULL
:Go1stTextFile		b PLAINTEXT,BOLDON,"<< Anfang",PLAINTEXT,NULL
endif
if Sprache = Englisch
:NoFiles		b PLAINTEXT,BOLDON,"No files!     ",NULL
:MoreTextFiles		b PLAINTEXT,BOLDON,">> More  ",PLAINTEXT,NULL
:Go1stTextFile		b PLAINTEXT,BOLDON,"<< Top   ",PLAINTEXT,NULL
endif

;*** Zwischenspeicher für Dateiauswahl-Menü.
if Sprache = Deutsch
:MenuFiles_Entry00	b PLAINTEXT,BOLDON,"<< Hauptmenü ",PLAINTEXT,NULL
endif
if Sprache = Englisch
:MenuFiles_Entry00	b PLAINTEXT,BOLDON,"<< Mainmenu  ",PLAINTEXT,NULL
endif

:MenuFiles_Entry01	s 17
:MenuFiles_Entry02	s 17
:MenuFiles_Entry03	s 17
:MenuFiles_Entry04	s 17
:MenuFiles_Entry05	s 17
:MenuFiles_Entry06	s 17
:MenuFiles_Entry07	s 17
:MenuFiles_Entry08	s 17
:MenuFiles_Entry09	s 17
:MenuFiles_Entry10	s 17
:MenuFiles_Entry11	s 17
:MenuFiles_Entry12	s 17
:MenuFiles_Entry13	s 17
