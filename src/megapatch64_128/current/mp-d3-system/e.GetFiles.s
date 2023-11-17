; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.GetFiles"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			t "-G3_FBoxSize"

			o LD_ADDR_GETFILES

;*** Steuercode: DBGETFILES
:DB_GetFiles		lda	Flag_TaskAktiv		;Taskmanager sperren
			sta	Copy_TaskAktiv
			lda	#$ff
			sta	Flag_TaskAktiv

			lda	Flag_DBoxType		;Dialogbox-Kennbyte einlesen und
			sta	Copy_DBoxType		;zwischenspeichern.
			lda	#%01000001		;Farbe für alle Icons setzen.
			sta	Flag_DBoxType		;Wichtig für Icons deren Größe
							;unterhalb der min. Größe für Farbe
							;liegt (sh. GeoFAX V1.6! bei der
							;Dateiauswahlbox!)
			lda	#$00
			sta	DB_1stFileInTab		;Zeiger auf erste Datei.
			sta	DB_SelectedFile		;Erste Datei auswählen.
			sta	Flag_SortFiles		;Sort-Modus löschen.
			sta	Flag_PartSlct		;Partitions-Flag löschen.

			jsr	DB_DefIRetAdr		;Rücksprungadressen definieren.
			jsr	DB_TestDskIcon		;"DISK"-Icon suchen.
			jsr	DB_TestOpenIcon		;"OPEN"-Icon suchen.

			jsr	SwapFNameBuf		;Speicher für Dateispeicher retten.

			lda	#$00			;Anzeige-Bereich für Tabellen-
			jsr	SetPattern		;einträge löschen.
			jsr	i_Rectangle
			b	Y_FWin,Y_FWin + H_FWin - 1
			w	X_FWin ! DOUBLE_W
			w	(X_FWin + B_FWin - 1) ! DOUBLE_W ! ADD1_W

			jsr	DB_DrawDBInf		;Dialogbox-Informationen ausgeben.

			pla				;Rücksprungadresse merken.
			sta	DB_KernalAdr +0		;Programm kehrt dadurch direkt
			pla				;zu ":DoDlgBox" zurück und
			sta	DB_KernalAdr +1		;nicht in die Kernal-Routine.
			rts				;Dies geschieht erst wenn ein
							;Icon angewählt wird. Dann wird
							;der Speicher wiederhergestellt
							;und zum Anwender-Hauptprogramm
							;zurückgekehrt.

;*** Dialogbox-Informationen ausgeben.
:DB_DrawDBInf		jsr	UseFontG3
			jsr	DB_DrawTitel		;Titelzeile ausgeben.
			jsr	DB_DrawNmBox		;Eingabefeld zeichnen.
			jsr	DB_DrawVModOpt		;Text für Modus-Wechsel ausgeben.
			jsr	DB_DrawFInfText		;Text für Infoanzeige ausgeben.
			jsr	DB_DrawSortIcon		;Zusatz-Icons anzeigen.
			jsr	DB_InitFTab		;Dateiliste initialisieren.
			jmp	DB_InitKeyBChk		;Tastaturabfrage starten.

;*** Speicherberich für Dateinamen freimachen bzw.
;    vor verlassen der Box wieder zurücksetzen.
:SwapFNameBuf		LoadW	r0,DB_FNAME_BUF
			LoadW	r1,R3_ADDR_FNAMES
			LoadW	r2,R3_SIZE_FNAMES
			lda	MP3_64K_DATA
			sta	r3L
			jmp	SwapRAM

;*** Gewählte Datei öffnen.
;    (Doppelklick oder Namenseingabe).
:DB_OpenSlctFile	bit	Flag_PartSlct		;Partitionsauswahl über "DISK"-Icon
			bpl	:51			;aktiv ? => Nein, weiter...
			jmp	DB_PART_OK		;Partition aktivieren.

::51			bit	DB_GetFilesOpt		;Partitionsauswahlbox ?
			bpl	:52			; => Nein, weiter...
			jsr	DB_OPEN_PART		;Neue Partition aktivieren.

::52			jsr	DB_CopyFName		;Dateiname kopieren.

			lda	#OPEN			;Anwahl des "öffnen"-Icons
			sta	sysDBData		;simulieren.

			lda	#<RstrFrmDialogue	;Dialogbox beenden.
			sta	r0L
			lda	#>RstrFrmDialogue
			sta	r0H
			bne	DB_ExitNewBox

;*** DB Über Icon beenden.
;    Alle Rücksprung-Adressen der Icons werden auf diese Tabelle umgelenkt.
;    Rückkehr zum Hauptprogramm erfolgt erst nach zurücksetzen des Speichers.
:DB_IconExit		lda	#$00			;Einsprung-Tabelle für Icons.
			b $2c
			lda	#$02
			b $2c
			lda	#$04
			b $2c
			lda	#$06
			b $2c
			lda	#$08
			b $2c
			lda	#$0a
			b $2c
			lda	#$0c
			b $2c
			lda	#$0e
			pha
			jsr	DB_CopyFName		;Eintrag kopieren.
			pla
			tay
			lda	DB_RoutVec +0,y		;Rücksprung-Adresse für
			sta	r0L			;Hauptprogramm ermitteln.
			lda	DB_RoutVec +1,y
			sta	r0H

;*** Auswahlbox beenden.
:DB_ExitNewBox		lda	r0L			;Rücksprung zum ausgewählten Icon.
			sec
			sbc	#$01
			tax
			lda	r0H
			sbc	#$00
			pha
			txa
			pha

			lda	DB_KernalAdr +1		;Zurück zur Kernal-Routine.
			pha
			lda	DB_KernalAdr +0
			pha

			jsr	PromptOff

			lda	#$00
			sta	keyVector     +0
			sta	keyVector     +1
			sta	otherPressVec +0
			sta	otherPressVec +1

			jsr	SwapFNameBuf		;Speicherbereiche restaurieren.
			jsr	DB_ResetScreen		;Bildschirm wieder herstellen.

			lda	Copy_TaskAktiv
			sta	Flag_TaskAktiv

			lda	Copy_DBoxType		;Original-Kopfbyte der Dialogbox
			sta	Flag_DBoxType		;wieder herstellen.

			jsr	SetADDR_GetFiles	;Zeiger auf Originalspeicher und
			jmp	SwapRAM			;Speicher zurücksetzen.

;*** Neue Partition über "DISK"-Icon öffnen.
:DB_SlctPart		lda	#%10000000		;Flag setzen: "Partition wählen".
			sta	DB_GetFilesOpt

			jsr	SetADDR_GFilData	;Partitionen einlesen. Diese
			jsr	SwapRAM			;werden in den Speicherbereich für
			jsr	LD_ADDR_GFILPART	;die Dateinamen kopiert!

			lda	DB_FilesInTab		;Partitionen auf Disk ?
			beq	:52			; => Nein, weiter...
			lda	#$ff
			sta	Flag_PartSlct		;Flag für Partitions-Auswahl setzen.

			ldy	#4 +2*8 -1		;Neue Icon-Tabelle für
::51			lda	Dlg_PartIcons,y		;Partitions-Auswahlbox erzeugen.
			sta	DB_Icon_Tab  ,y
			dey
			bpl	:51
			iny

::52			jsr	SetADDR_GFilMenu	;Auswahlbox neu zeichnen und
			jsr	SwapRAM			;Partitionsliste anzeigen.
			jsr	LD_ADDR_GFILICON
			jmp	DB_DrawDBInf

;*** Neue Partition aktivieren.
:DB_PART_OK		jsr	DB_OPEN_PART		;Neue Partition aktivieren.
:DB_PART_CANCEL		jmp	(AdrDiskIconRout)	;"DISK"-Icon-Routine aufrufen.

;*** Neue Partition aktivieren.
:DB_OPEN_PART		ldx	DB_SelectedFile
			lda	DB_PDATA_BUF ,x		;Partitions-Nr. einlesen und
			sta	DB_GetFileEntry		;zwischenspeichern.
			sta	r3H
			jmp	OpenPartition		;Partition öffnen.

;*** Bildschirm zurücksetzen.
:DB_ResetScreen		PushW	DB_VecDefTab
			LoadW	DB_VecDefTab ,DB_FBoxData
			jsr	SetADDR_DB_SCRN		;Bildschirm unter Auswahlbox wieder
			jsr	SwapRAM			;aus REU einlesen.
			jsr	DB_SCREEN_LOAD
			PopW	DB_VecDefTab
			rts

;*** Dateiname kopieren.
;    Der Dateiname muß zuerst zwischengespeichert werden, da die Zieladresse
;    auch im Bereich der Dialogbox liegen könnte. Der Eintrag wird später
;    vom Kernal an die richtige Stelle kopiert.
:DB_CopyFName		lda	DB_SelectedFile
			sta	DB_GetFileEntry
			ldx	#r1L			;Zeiger auf Eintrag
			jsr	DB_SetFileNam		;in Tabelle berechnen.

			ldy	#$00			;Eintrag kopieren (incl. 0-Byte!)
::51			lda	(r1L)          ,y	;Zeichen einlesen. Ende erreicht ?
			beq	:52			; => Ja, Ende...
			sta	DB_SlctFileName,y
			iny
			cpy	#17
			bcc	:51
			bcs	:53
::52			sta	DB_SlctFileName,y
			iny
			cpy	#17
			bcc	:52
::53			rts

;*** Rücksprungsadressen der Icons korrigieren.
;    Da nach einem Mausklick auf ein Icon zuerst der Speicher zurückgesetzt
;    werden muß, wird die Rücksprungadresse der icons ausgelesen und durch
;    eine interne Adresse ersetzt. Diese setzt dann den Speicher auf den
;    Ausgangswert, aktiviert wieder die Kernal-Dialogbox-Routine und kehrt
;    erst dann zur Applikation zurück.
:DB_DefIRetAdr		ldy	#$00			;Rücksprungadressen der Icons
::51			cpy	DB_Icon_Tab		;einlesen und durch interne Sprung-
			beq	:53			;tabelle ersetzen.

			tya
			pha

			asl
			tax
			asl
			asl
			tay
			lda	DB_Icon_Tab +10,y	;Rücksprungadresse speichern.
			sta	DB_RoutVec  + 0,x
			lda	DB_Icon_Tab +11,y
			sta	DB_RoutVec  + 1,x

			pla
			pha
			sta	:52 +1
			asl
			clc
::52			adc	#$ff
			clc
			adc	#< DB_IconExit		;Neue Rücksprungadresse in
			sta	DB_Icon_Tab +10,y	;interne Tabelle berechnen.
			lda	#$00
			adc	#> DB_IconExit
			sta	DB_Icon_Tab +11,y

			pla
			tay
			iny
			bne	:51
::53			rts

;*** Partitionswechsel über "DISK"-Icon initialisieren.
:DB_TestDskIcon		ldx	curDrive		;Laufwerksmodi einlesen.
			lda	RealDrvMode -8,x	;Werden Partitionen unterstützt ?
			bpl	:51			; => Nein, Ende...

			lda	#< Icon_DISK
			ldx	#> Icon_DISK
			jsr	DB_IsIconInTab		;"DISK"-Icon suchen.
			txa				;Icon gefunden ?
			bne	:51			; => Nein, weiter...

			tya				;Zeiger auf Icon in Tabelle
			asl				;berechnen.
			asl
			asl
			tay
			lda	DB_Icon_Tab +10,y	;Icon-Sprungadresse einlesen und
			sta	AdrDiskIconRout  + 0	;zwischenspeichern.
			lda	DB_Icon_Tab +11,y
			sta	AdrDiskIconRout  + 1
			lda	#< DB_SlctPart		;"DISK"-Icon auf eigene Routine
			sta	DB_Icon_Tab +10,y	;umleiten.
			lda	#> DB_SlctPart
			sta	DB_Icon_Tab +11,y
::51			rts

;*** "OPEN"-Routine auf Routine ":DB_OpenSlctFile" umlenken.
;    Damit wird sichergestellt das ein Doppelklick gleich behandelt wird
;    wie ein Klick auf das "OPEN"-Icon.
:DB_TestOpenIcon	lda	#< Icon_OPEN
			ldx	#> Icon_OPEN
			jsr	DB_IsIconInTab		;"OPEN"-Icon suchen.
			txa				;Icon gefunden ?
			bne	:51			; => Nein, weiter...

			tya				;Zeiger auf Icon in Tabelle
			asl				;berechnen.
			asl
			asl
			tay
			lda	#< DB_OpenSlctFile	;"OPEN"-Icon auf eigene Routine
			sta	DB_Icon_Tab +10,y	;umleiten.
			lda	#> DB_OpenSlctFile
			sta	DB_Icon_Tab +11,y
::51			rts

;*** Befindet sich Icon in Tabelle ?
:DB_IsIconInTab		sta	:52 +1			;Zeiger auf Icon-Bitmap speichern.
			stx	:53 +1

			ldy	#$00
::51			cpy	DB_Icon_Tab		;Alle Icons geprüft ?
			beq	:56			; => Ja, Ende...
			jsr	DB_GetIconAdr		;Bitmap-Adresse einlesen und
::52			cmp	#$ff			;mit Adresse für System-Icon
			bne	:54			;vergleichen.
::53			cpx	#$ff			;Wenn System-Icon gefunden, dann
			beq	:55			;Icon positionieren.
::54			iny				;Zeiger auf nächstes Icon und
			bne	:51			;weitertesten.
::55			ldx	#$00
			b $2c
::56			ldx	#$05
			rts

;*** Zeiger auf Bitmap aus Icon-Tabelle einlesen.
:DB_GetIconAdr		sty	:51 +1
			tya
			asl
			asl
			asl
			tay
			lda	DB_Icon_Tab + 4,y
			ldx	DB_Icon_Tab + 5,y
::51			ldy	#$ff
			rts

;*** Titelzeile der Dialogbox zeichnen.
:DB_DrawTitel		jsr	DB_TEXT_NumEntry	;X/Y-Position festlegen.
			lda	DB_FilesInTab		;Anzahl Dateien in Tabelle nach
			sta	r0L			;":r0" kopieren und ausgeben.
			lda	#$00
			sta	r0H
			lda	#%11000000
			jsr	PutDecimal

			lda	#<BOX_Text2		;Text => "xyz Datei(en)".
			ldx	#>BOX_Text2
			bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvc	:51			; => Nein, weiter...
			lda	#<BOX_Text5		;Text => "1 Eintrag".
			ldx	#>BOX_Text5
			ldy	DB_FilesInTab
			cpy	#$02
			bcc	:51
			lda	#<BOX_Text6		;Text => "xyz Einträge".
			ldx	#>BOX_Text6
::51			sta	r0L			;Zeiger auf Text nach ":r0" und
			stx	r0H			;Text ausgeben.
			jsr	PutString

			bit	DB_GetFilesOpt		;Partition auswählen ?
			bmi	DB_ViewPartTitel	; => Titelzeile ausgeben.
			bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvc	DB_ViewFBoxTitel	; => Dateiliste anzeigen.

;*** Anzeige des Titels: "Bitte wählen:"
:DB_ViewUserTitel	jsr	DB_TEXT_UserBox
			jmp	PutString

;*** Anzeige des Titels: "Partition wählen:"
:DB_ViewPartTitel	jsr	DB_TEXT_PartBox
			jmp	PutString

;*** Anzeige des Titels: "Datei wählen:"
:DB_ViewFBoxTitel	lda	curDrive		;Laufwerk in Zwischenspeicher
			clc				;eintragen.
			adc	#$39
			sta	DB_DNameBuf +0
			lda	#":"
			sta	DB_DNameBuf +1

			ldx	#r0L			;Zeiger auf Diskettennamen
			jsr	GetPtrCurDkNm		;berechnen.

			ldy	#$00
::51			lda	(r0L)         ,y	;Byte aus Diskettenname einlesen.
			cmp	#$a0			;Ende erreicht ?
			bne	:52			;Nein, weiter...
			lda	#$00			;$00-Byte als Ende-Kennung.
::52			sta	DB_DNameBuf +2,y	;Byte in Zwischenspeicher kopieren.
			tax
			beq	:53
			iny
			cpy	#$10
			bne	:51

::53			jsr	DB_TEXT_FileBox		;Zeiger auf Text für Titelzeile und
			jsr	PutString		;Laufwerksdaten ausgeben.

			lda	#","
			jsr	SmallPutChar
			lda	#" "
			jsr	SmallPutChar

			PushB	r1H
			PushW	r11
			LoadW	r5,curDirHead
			jsr	CalcBlksFree		;Freien Speicher berechnen.
			PopW	r11
			PopB	r1H

			ldx	#r4L			;Anzahl freie Blocks in KBytes
			ldy	#$02			;umrechnen.
			jsr	DShiftRight
			MoveW	r4,r0
			lda	#%11000000
			jsr	PutDecimal		;Freie KBytes ausgeben.
			LoadW	r0,BOX_Text1		;Zeiger auf Text für Titelzeile und
			jmp	PutString		;Text ausgeben.

;*** Anzeigefeld vorbereiten.
:DB_ColBoxFrame		jsr	DirectColor		;Farbe setzen.
			jsr	Rectangle		;Anzeige-Bereich löschen.
			jsr	DB_UpsizeBox		;Größe für Rahmen berechnen und
			lda	#%11111111		;Rahmen um Anzeige-Bereich
			jmp	FrameRectangle		;darstellen.

;*** Options-Icon anzeigen.
:DB_DrawOptIcon		ldx	#r3L
			ldy	#$03
			jsr	DShiftRight

			lda	r3L

if Flag64_128 = TRUE_C128
			ora	#%10000000		;Double-Bit setzen
endif
			sta	r1L
			MoveB	r2L,r1H
			LoadB	r2L,$01 ! DOUBLE_B
			LoadB	r2H,$08
			LoadW	r0,Icon_Option
			jmp	BitmapUp

;*** Eingabefeld für Dateinamen zeichnen.
:DB_DrawNmBox		jsr	DB_AREA_NmBox		;Eingabefeld zeichnen.
			lda	C_InputField
			jsr	DirectColor
			jsr	DB_UpsizeBox
			lda	#%11111111
			jsr	FrameRectangle

			jsr	DB_TEXT_NmBox		;Zeiger auf Text für Eingabefeld
			jmp	PutString		;und Text ausgeben.

;*** Optionsfeld "von Datei-Informationen" ausgeben.
:DB_DrawVModOpt		bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvs	RTS_01			; => Ja, Ende...

			jsr	DB_TEXT_VMode		;Zeiger auf Text für Optionsfeld
			jsr	PutString		;und Text ausgeben.

;*** Anzeigemodus anzeigen.
:DB_ViewVMode		lda	#$00
			jsr	SetPattern
			jsr	DB_AREA_VMode
			lda	C_InputField
			jsr	DB_ColBoxFrame

			bit	Flag_ViewFInfo
			bmi	RTS_01
			jsr	DB_AREA_VMode
			jmp	DB_DrawOptIcon

;*** Texte für Informations-Anzeige ausgeben.
:DB_DrawFInfText	bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvs	RTS_01			; => Ja, Ende...
			bit	Flag_ViewFInfo		;Anzeige aktiv ?
			bmi	RTS_01			; => Nein, Ende...
			lda	DB_FilesInTab		;Dateien im Speicher ?
			beq	RTS_01			; => Nein, Ende...

			jsr	DB_TEXT_FSizeInf	;Zeiger auf Infotext und
			jsr	PutString		;Text ausgeben.
			jsr	DB_TEXT_WProt		;Zeiger auf Infotext und
			jmp	PutString		;Text ausgeben.

;*** Modus für Anzeige der Datei-Informationen ändern.
:DB_SwapVMode		bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvs	RTS_01			;Ja, weiter...

			lda	Flag_ViewFInfo		;Modus umschalten.
			eor	#%10000000
			sta	Flag_ViewFInfo

			jsr	DB_ViewVMode		;Anzeige aktualisieren.
			lda	Flag_ViewFInfo
			tax				;Anzeige-Modus aktiviert ?
			beq	:51			; => Ja, weiter...

			jsr	DB_AREA_FInfArea	;Grenzen für Anzeigefeld für
			lda	C_FBoxBack		;Datei-Infoirmationen setzen und
			jsr	DirectColor		;Bereich löschen.
			jsr	Rectangle
			jsr	DB_UpsizeBox
			jmp	Rectangle

::51			jsr	DB_DrawFInfText		;Informationstexte anzeigen und
			jmp	DB_DrawFInfo		;Datei-Informationen zeigen.
:RTS_01			rts

;*** Schreibschutz-Modus ändern.
:DB_SwapWProt		bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvs	RTS_01			; => Ja, Ende...
			bit	Flag_ViewFInfo		;Info-Anzeige aktiv ?
			bmi	RTS_01			; => Nein, Ende...

			lda	DB_SelectedFile
			ldx	#r6L
			jsr	DB_SetFileNam		;Zeiger auf Eintrag berechnen.
			jsr	FindFile		;Datei auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	RTS_01			; => Ja, Abbruch...

			ldy	#$00
			lda	(r5L),y
			eor	#%01000000
			sta	dirEntryBuf +0
			sta	(r5L),y			;Schreibschutz-Flag ändern und
			LoadW	r4,diskBlkBuf		;Eintrag zurück auf Diskette
			jsr	PutBlock		;übertragen.
			txa				;Diskettenfehler ?
			bne	RTS_01			; => Ja, Abbruch...

			jmp	DB_ViewWProt		;Anzeige aktualisieren.

;*** Zusatz-Icons anzeigen.
:DB_DrawSortIcon	bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvs	RTS_01			; => Ja, Abbruch...
			ldx	DB_FilesInTab		;Mehr als 1 Datei ?
			cpx	#$02			;Mehr als eine Datei im Speicher ?
			bcc	RTS_01			;Nein, weiter...
			jsr	DB_TEXT_Sort
			jsr	PutString
			jsr	DB_AREA_Sort		;Feld für Schreibschutz zeichnen.
			lda	C_InputField
			jmp	DB_ColBoxFrame

;*** Datei-Information anzeigen.
:DB_DrawFInfo		bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvc	:52			; => Nein, weiter...
::51			rts

::52			lda	#$00			;Feld für Datei-Info zeichnen.
			jsr	SetPattern
			jsr	DB_AREA_FInfo
			lda	C_InputField
			jsr	DB_ColBoxFrame

			jsr	DB_AREA_FSize		;Feld für Dateigröße zeichnen.
			lda	C_InputField
			jsr	DB_ColBoxFrame

			jsr	DB_AREA_WProt		;Feld für Schreibschutz zeichnen.
			lda	C_InputField
			jsr	DB_ColBoxFrame

			lda	DB_SelectedFile
			ldx	#r6L
			jsr	DB_SetFileNam		;Vektor auf Eintrag berechnen.
			PushW	r6			;Zeiger auf Dateiname retten.
			jsr	FindFile		;Datei auf Diskette suchen.
			PopW	r6			;Zeiger auf Dateiname zurücksetzen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			ldy	#$00
::53			lda	(r6L)      ,y		;Dateiname in Zwischenspeicher
			sta	DB_FNameBuf,y		;übertragen.
			beq	:54
			iny
			bne	:53
::54			jsr	DB_TEXT_FName		;Zeiger auf Dateiname und ausgeben.
			jsr	PutString

			jsr	DB_TEXT_FInfo		;Zeiger auf Datei-Info setzen.
			lda	dirEntryBuf +25		;Datum ausgeben: Tag.
			jsr	DB_PrntNum_Pnt
			lda	dirEntryBuf +24		;Datum ausgeben: Monat.
			jsr	DB_PrntNum_Pnt
			lda	dirEntryBuf +23		;Datum ausgeben: Jahr.
			jsr	DB_PrntNum
			lda	#" "			;Trennzeichen ausgeben.
			jsr	SmallPutChar
			lda	dirEntryBuf +26		;Uhrzeit ausgeben: Stunde.
			jsr	DB_PrntNum
			lda	#":"			;Trennzeichen ausgeben.
			jsr	SmallPutChar
			lda	dirEntryBuf +27		;Uhrzeit ausgeben: Minute.
			jsr	DB_PrntNum

			jsr	DB_TEXT_FSize		;Zeiger auf Datei-Größe setzen.
			lda	dirEntryBuf +28		;Dateigröße einlesen.
			sta	r0L
			lda	dirEntryBuf +29
			sta	r0H
			ldx	#r0L			;Anzahl Blocks in KBytes umrechnen.
			ldy	#$02
			jsr	DShiftRight
			lda	r0L
			ora	r0H			;Dateigröße = 0 ?
			bne	:55			; => Nein, weiter...
			inc	r0L			;Mindestgröße auf 1 KByte setzen.
::55			lda	#%11000000
			jsr	PutDecimal		;Dateigröße ausgeben.
			lda	#" "
			jsr	SmallPutChar
			lda	#"K"
			jsr	SmallPutChar
			lda	#"b"
			jsr	SmallPutChar

;*** Anzeige des Schreibschutz-Status aktualisieren.
:DB_ViewWProt		lda	#$00			;Schreibschutz-Zustand ausgeben.
			jsr	SetPattern
			jsr	DB_AREA_WProt
			lda	C_InputField
			jsr	DB_ColBoxFrame

			bit	dirEntryBuf
			bvc	:51
			jsr	DB_AREA_WProt
			jmp	DB_DrawOptIcon
::51			rts

;*** Zahl und "." als Trennzeichen zwischen Datum ausgeben.
:DB_PrntNum_Pnt		jsr	DB_PrntNum
			lda	#"."
			jmp	SmallPutChar

;*** Zahl ausgeben.
:DB_PrntNum		cmp	#10			;Zahl größer als 10?
			bcs	:1			;>ja
			pha				;Zahl sichern
			lda	#"0"			;führende NULL ausgeben
			jsr	SmallPutChar
			pla				;Zahl wiederherstellen
::1			sta	r0L			;und ausgeben
			lda	#$00
			sta	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Dateien im Speicher sortieren.
:DB_SortFiles		bit	Flag_GetFiles		;Anwender-Einträge zeigen ?
			bvs	:51			; => Ja, Ende...
			bit	Flag_SortFiles		;Dateien bereits sortiert ?
			bmi	:51			; => Ja, Ende...
			ldx	DB_FilesInTab
			cpx	#$02			;Mehr als eine Datei im Speicher ?
			bcs	:52			;Ja, Weiter...
::51			rts

::52			ldx	DB_FilesInTab		;Zeiger auf Dateiname
			dex				;berechnen.
			stx	r14L
			LoadB	r15L,17
			ldx	#r14L
			ldy	#r15L
			jsr	BBMult
			AddVW	DB_FNAME_BUF,r14
			LoadW	r15,DB_FNAME_BUF

::53			MoveW	r14,r13			;Zeiger auf letzte Datei.

::54			jsr	DB_SortName		;Einträge sortieren.
			CmpW	r13,r15
			beq	:55
			SubVW	17,r13
			jmp	:54

::55			AddVBW	17,r15
			CmpW	r14,r15			;Alle Dateien sortiert ?
			bne	:53			;Nein, weiter...

			lda	#$ff			;Dateien sortiert.
			sta	Flag_SortFiles

			lda	#$00			;Zum Anfang der Tabelle.
			sta	DB_SelectedFile
			sta	DB_1stFileInTab
			jsr	DB_DrawFTab
			jsr	InvertCurName

			jsr	DB_AREA_Sort		;Farbe für "Liste sortieren"-Feld
			lda	C_InputFieldOff		;auf "inaktives Optionsfeld" ändern.
			jsr	DirectColor

			jsr	DB_AREA_Sort
			jmp	DB_DrawOptIcon

;*** Dateieinträge vergleichen und sortieren.
:DB_SortName		ldy	#$00
			lda	(r15L),y
			jsr	:61
			sta	:51 +1
			lda	(r13L),y
			jsr	:61
::51			cmp	#$ff
			bcc	:56
			beq	:52
			bcs	:59

::52			lda	(r13L),y
			cmp	(r15L),y
			beq	:58
			bcc	:63
			jmp	SwapEntry		;Einträge tauschen.

::54			ldy	#$00			;Zeichen vergleichen.
::55			lda	(r13L),y
			cmp	(r15L),y
			bcs	:57
::56			jmp	SwapEntry		;Einträge tauschen.

::57			bne	:59
::58			iny				;Weitervergleichen bis
			cpy	#$10			;alle 11 Zeichen geprüft.
			bne	:55
::59			rts

::61			cmp	#$61
			bcc	:63
			cmp	#$7e
			bcs	:63
::62			sub	$20
::63			rts

;*** Einträge vertauschen.
:SwapEntry		ldy	#$0f			;Einträge tauschen.
::51			lda	(r13L),y
			tax
			lda	(r15L),y
			sta	(r13L),y
			txa
			sta	(r15L),y
			dey
			bpl	:51
			rts

;*** Datei/Scroll-Icons auswählen.
:DB_TestMouse		lda	mouseData		;Maustaste gedrückt ?
			bmi	WaitNoMKey		;Nein, weiter...

			lda	#$00
::51			sta	:52 +1			;Gewählter Mausbereich
			jsr	DB_AREA_AKKU		;ermitteln.
			jsr	IsMseInRegion
			tax
			beq	:52			;Gefunden ? Nein, weiter auswerten.

			lda	:52 +1			;Zeiger aus Sprungtabelle
			asl				;berechnen.
			tay
			ldx	DB_AREA_JmpVec +1,y
			lda	DB_AREA_JmpVec +0,y
			jmp	CallRoutine		;Maus-Routine ausführen.

::52			lda	#$ff
			clc
			adc	#$01			;Zeiger auf nächsten Bereich.
			cmp	#$07			;Alle Bereiche überprüft ?
			bcc	:51			;Nen, weiter...

;*** Warten bis keine Maustaste gedrückt.
:WaitNoMKey		NoMseKey
			rts

;*** DBGETFILES: Datei auswählen.
:DB_SlctNewFile		lda	mouseData		;Maustaste gedrückt ?
			bmi	:54			; => Nein, weiter...

			lda	mouseYPos		;Eintrag ermitteln.
			sec
			sbc	#Y_FWin
			lsr
			lsr
			lsr
			clc
			adc	DB_1stFileInTab
			cmp	DB_FilesInTab		;Gültiger Eintrag gewählt ?
			bcs	:54			; => Nein, weiter...

			ldx	dblClickCount		;Ist Doppelklick aktiv ?
			beq	:51			; => Nein, weiter...
			cmp	DB_SelectedFile		;Doppelklick auf Datei ?
			beq	:52			; => Ja, Datei öffnen.
			ldx	#$00			;Doppelklick-Zähler löschen.
			stx	dblClickCount

::51			pha
			lda	DB_SelectedFile		;Aktuellen Eintrag ermitteln und
			sec				;invertieren aufheben.
			sbc	DB_1stFileInTab
			jsr	PrintName
			pla
			sta	DB_SelectedFile		;Neuen Eintrag festlegen und
			sec				;invertieren.
			sbc	DB_1stFileInTab
			jsr	InvertName
			jsr	DoMenuSleep
			rts

::52			bit	Flag_PartSlct		;Partitions-Auswahl aktiv ?
			bmi	:53			; => Ja, weiter...
			jmp	DB_OpenSlctFile		;Datei öffnen.
::53			jmp	DB_PART_OK		;Partition öffnen.
::54			rts

;*** Auf Doppelklick testen.
:DoMenuSleep		lda	#$1e			;Zähler für Doppelklick-Pause
			sta	dblClickCount		;festlegen.
			lda	selectionFlash
			sta	r0L
			lda	#$00
			sta	r0H
			jmp	Sleep			;Pause ausführen.

;*** Zeiger auf Dateinamen berechnen.
;    Übergabe:		AKKU = Zeiger auf Eintrag.
;			xReg = Zeiger auf ZeroPage-Adresse in der
;				Vektor abgelegt wird.
;    Dabei kann jede ZeroPage-Adresse verwendet werden: r0-r15 und a0-a9.
:DB_SetFileNam		sta	r0L

			lda	#$11			;Zeiger auf Eintrag berechnen.
			sta	r1L			;Formel:  Eintrag * 17 Zeichen
			txa
			pha
			ldy	#r0L
			ldx	#r1L
			jsr	BBMult
			pla
			tax

			lda	r1L			;Vektor auf Eintrag in ZeroPage
			clc				;übertragen.
			adc	#<DB_FNAME_BUF
			sta	zpage +0,x
			lda	r1H
			adc	#>DB_FNAME_BUF
			sta	zpage +1,x
			rts

;*** Tastaturabfrage installieren.
:DB_InitKeyBChk		jsr	MouseUp			;Maus aktivieren.

			lda	#$00			;Eingabefeld löschen.
			jsr	SetPattern		;(Suche nach Eintrag)
			jsr	DB_AREA_NmBox
			jsr	Rectangle

			ClrB	currentMode		;Textstil löschen.

			lda	#<DB_DB_SearchName
			ldx	#>DB_DB_SearchName
			ldy	DB_FilesInTab		;Dateien in Tabelle ?
			bne	:51			;Ja, weiter...
			lda	#$00
			tax
::51			sta	keyVector +0		;Tastaturabfrage aktivieren.
			stx	keyVector +1
			ora	keyVector +1		;Tastaturabfrage installiert ?
			bne	:52			; => Ja, weiter...
			rts

::52			LoadW	r0 ,DB_SearchName	;Abschluß-Routine.
			jsr	DB_StartInput

			lda	keyVector +0		;Zeiger auf Kernal-Routine für
			sta	DB_KeyBVec+0		;Tastatur-Abfrage retten.
			lda	keyVector +1
			sta	DB_KeyBVec+1

			lda	#< DB_TstCrsrKeys	;Routine zur Abfrage der Cursor-
			sta	keyVector +0		;Tasten installen.
			lda	#> DB_TstCrsrKeys
			sta	keyVector +1
			rts

;<*> Routine komplett neu.
;*** Tastatur abfragen.
;    Ist der gesuchte Eintrag in der Tabelle enthalten, wird dieser Eintrag
;    geöffnet. Dabei müssen alle Zeichen übereinstimmen! Im anderen Fall wird
;    der nächste ähnliche Eintrag angezeigt.
:DB_DB_SearchName	LoadW	r2,DB_SearchName	;Zeiger auf Suchstring.

			lda	DB_SearchName		;Suchname definiert ?
			bne	:2			; => Ja, weiter...

;--- Nächsten Eintrag in Tabelle wählen.
			ldx	DB_SelectedFile		;Zeiger auf nächsten Eintrag.
			inx
			cpx	DB_FilesInTab
			beq	:1
			txa
::1			jsr	DB_SetNewFile
			jmp	DB_InitKeyBChk

;--- Tabelle nach gesuchtem Namen durchsuchen.
::2			lda	#$00
			sta	r4L
::3			lda	r4L			;Zeiger auf Dateiname.
			cmp	DB_FilesInTab		;Tabellenende erreicht ?
			beq	:11			; => Ja, nicht gefunden.
			ldx	#r3L
			jsr	DB_SetFileNam		;Zeiger auf Eintrag berechnen.

			ldx	#r2L
			ldy	#r3L
			jsr	CmpString		;Gesuchter Eintrag gefunden ?
			bne	:4			; => Nein, weiter...

			lda	r4L			;Eintrag öffnen.
			sta	DB_SelectedFile
			jmp	DB_OpenSlctFile

::4			inc	r4L			;Zeiger auf nächsten Eintrag und
			bne	:3			;weitersuchen.

;--- Tabelle nach ähnlichen Namen durchsuchen.
::11			lda	DB_SelectedFile
::12			clc
			adc	#$01
			cmp	DB_FilesInTab
			bne	:13
			lda	#$00
::13			cmp	DB_SelectedFile
			beq	:15
			jsr	:21
			cpx	#$ff
			beq	:14
			bne	:12

::14			jsr	DB_SetNewFile
::15			jmp	DB_InitKeyBChk

;--- Aktuellen Eintrag vergleichen.
::21			pha
			ldx	#r3L
			jsr	DB_SetFileNam		;Zeiger auf Eintrag berechnen.

			ldy	#$00
::22			lda	(r2L),y			;Ende Suchname erreicht ?
			bne	:23			; => Nein, weiter...
			pla
			ldx	#$ff			;Ähnlichen Eintrag gefunden.
			rts

::23			lda	(r3L),y			;Ende Tabellen-Eintrag erreicht ?
			beq	:24			; => Ja, Eintrag nicht identisch.
			cmp	(r2L),y			;Eintrag vergleichen.
			bne	:24			; => Eintrag nicht identisch.
			iny
			jmp	:22			;Nächstes Zeichen vergleichen.

::24			pla
			ldx	#$00			;Keinen Eintrag gefunden.
			rts

;*** Auf Cursor-Tasten prüfen.
:DB_TstCrsrKeys		pha
			lda	keyData			;Aktuelle Taste einlesen.
			cmp	# 17			;Cursor down ?
			beq	DB_CursorDown		; => Ja, weiter...
			cmp	# 16			;Cursor up ?
			beq	DB_CursorUp		; => Ja, weiter...
			cmp	#$ae			;Cursor right ?
			beq	DB_CursorRight		; => Ja, weiter...
			cmp	#$ac			;Cursor left ?
			beq	DB_CursorLeft		; => Ja, weiter...
			cmp	#141			;C= + RETURN ?
			beq	:51			; => Ja, weiter...
			pla
			jmp	(DB_KeyBVec)		;Kernal-Routine aufrufen.
::51			pla				;C= + RETURN, markierte
			jmp	DB_OpenSlctFile		;Datei öffnen.

;*** Nächste Datei auswählen.
:DB_CursorDown		pla

			ldx	DB_SelectedFile
			inx				;Zeiger auf nächsten Eintrag.
			cpx	DB_FilesInTab		;Cursor down möglich ?
			bcc	:51			; => Ja, weiter...
			ldx	DB_FilesInTab		;Zeiger auf letzten Eintrag.
			dex
::51			txa
			jmp	DB_SetNewFile		;Markierten Eintrag zeigen.

;*** Vorherige Datei auswählen.
:DB_CursorUp		pla
			ldx	DB_SelectedFile		;Cursor up möglich ?
			beq	:51			; => Nein, Ende...
			dex				;Zeiger auf vorherigen Eintrag.
::51			txa
			jmp	DB_SetNewFile		;Markierten Eintrag zeigen.

;*** Letzte Datei auswählen.
:DB_CursorRight		pla
			ldx	DB_FilesInTab		;Zeiger auf letzten Eintrag.
			dex
			txa
			jmp	DB_SetNewFile		;Markierten Eintrag zeigen.

;*** Erste Datei auswählen.
:DB_CursorLeft		pla
			lda	#$00			;Zeiger auf ersten Eintrag.

;*** Neue markierte Datei setzen und Eintrag anzeigen.
:DB_SetNewFile		pha
			jsr	PrintCurName		;Aktullen Eintrag löschen.
			pla
			cmp	DB_FilesInTab		;Eintrag gültig ?
			bcc	:51			; => Ja, weiter...
			ldx	DB_FilesInTab		;Zeiger auf letzte Datei setzen.
			dex
			txa
::51			sta	DB_SelectedFile		;Markierte Datei merken.

			cmp	DB_1stFileInTab		;Oberhalb des Anzeigefensters ?
			bcs	:52			; => Nein, weiter...
			sta	DB_1stFileInTab		;Neuen Seitenanfang setzen.
			bcc	:54

::52			sec				;Testen ob Eintrag noch innerhalb
			sbc	DB_1stFileInTab		;der aktiven Seite ist.
			cmp	#TabScrollY
			bcc	:55			; => Ja, weiter...

			lda	DB_SelectedFile		;Neuen Wert für ersten Eintrag
			sec				;auf aktueller Seite ermitteln.
			sbc	#TabScrollY -1
			bcs	:53
			lda	#$00
::53			sta	DB_1stFileInTab
::54			jmp	DB_DrawFTab		;Aktuelle Seite neu aufbauen.
::55			jmp	InvertCurName		;Neuen Eintrag invertieren.

;*** Eingaberoutine aktivieren.
:DB_StartInput		LoadB	r1L,$00			;Standard-Fehlerroutine.
			LoadB	r1H,Y_NBox		;Y-Koordinate.
			LoadB	r2L,16			;16 Zeichen.
							;X-Koordinate.

if Flag64_128 = TRUE_C128
			LoadW	r11,(X_NBox  + $02) ! DOUBLE_W
			LoadW	rightMargin,(X_NBox + B_NBox -1) * 2 + 1
			bit	graphMode
			bmi	:80

endif

if Flag64_128 = TRUE_C64
			LoadW	r11,X_NBox  + $02	;X-Koordinate GEOS64
endif

			LoadW	rightMargin,X_NBox + B_NBox -1  ;GEOS64/128 40Zeichen
::80			jsr	GetString

			php				;Cursor-Farbe festlegen.
			sei

if Flag64_128 = TRUE_C64
			ldx	CPU_DATA		;Nur C64
			lda	#$35
			sta	CPU_DATA
endif
			lda	C_InputField
			lsr
			lsr
			lsr
			lsr
			sta	$d028

if Flag64_128 = TRUE_C64
			stx	CPU_DATA		;Nur C64
endif

			plp
::52			rts

;*** Dateiliste initialisieren.
:DB_InitFTab		lda	#$00
			sta	DB_1stFileInTab		;Zeiger auf erste Datei.
			sta	DB_SelectedFile		;Erste Datei auswählen.

			lda	DB_FilesInTab		;Scrollbalken initialisieren.
			sta	MoveBarData  +3

if Flag64_128 = TRUE_C128
			lda	#BarDataX		;40 Zeichen-Breite des Balkens
			bit	graphMode		;Grafikmodus?
			bpl	:40			;>40 Zeichen
			asl				;>80 Zeichen dann Breite verdoppeln
::40			sta	MoveBarData		;Balkenbreite setzen
endif
			LoadW	r0,MoveBarData
			jsr	InitBalken

			lda	#<DB_TestMouse		;Zeiger auf Routine für Mausabfrage.
			ldx	#>DB_TestMouse
			ldy	DB_FilesInTab		;Dateien in Tabelle ?
			bne	:51			; => Ja, weiter...
			lda	#$00			;Keine Mausabfrage.
			tax
::51			sta	otherPressVec+0		;Mausabfrage installieren.
			stx	otherPressVec+1

			jsr	DB_DrawFTab		;Datei-Tabelle darstellen.
			jmp	InvertCurName		;Aktuelle Datei anzeigen.

;*** Dateiliste ausgeben.
:DB_DrawFTab		jsr	DB_NewPosBalken		;Tabellenposition einlesen und
							;Anzeigebalken setzen.
:DB_DrawNewFTab		lda	#$00			;Dateizähler löschen
::51			pha				;Zeiger auf Eintrag merken.
			jsr	PrintName		;Eintrag ausgeben.
			pla
			clc
			adc	#$01			;Zähler für Anzahl Einträge +1.
			cmp	#TabScrollY		;'7' Einträge ausgegeben ?
			bne	:51			;Nein, weiter...

			jsr	DB_TstCurEntry		;Eintrag auf Gültigkeit testen.
			jmp	InvertCurName		;Aktuellen Namen anzeigen.

;*** Neuen Eintrag in Tabelle ausgeben.
:DB_PrnNewEntry		jsr	PrintName		;Eintrag ausgeben.
			jsr	DB_TstCurEntry		;Eintrag auf Gültigkeit testen.
			bcc	:51			; => Gültig, weiter...
			lda	DB_SelectedFile
			sec
			sbc	DB_1stFileInTab
			jmp	InvertName
::51			rts

;*** Aktuellen Eintrag auf Gültigkeit testen.
:DB_TstCurEntry		lda	DB_1stFileInTab		;Aktuellen Eintrag ausgeben.
			cmp	DB_SelectedFile
			beq	:51
			bcs	:52
			clc
			adc	#TabScrollY -1
			cmp	DB_SelectedFile
			beq	:51
			bcc	:52
::51			clc
			rts

::52			sta	DB_SelectedFile		;Zeiger auf erste Datei auf
			sec
			rts

;*** Eintrag ausgeben: Invertieren.
:InvertCurName		lda	DB_SelectedFile		;Aktuellen Dateinamen
			sec				;invertieren.
			sbc	DB_1stFileInTab
:InvertName		ldy	DB_FilesInTab		;Dateien in Tabelle ?
			beq	:51			;Nein, übergehen.
			ldx	#%00100000
			bne	DB_PutFileName
::51			rts

;*** Eintrag ausgeben: Nicht invertieren.
:PrintCurName		lda	DB_SelectedFile
			sec
			sbc	DB_1stFileInTab
:PrintName		ldy	DB_FilesInTab		;Dateien in Tabelle ?
			beq	:51			;Nein, übergehen.
			ldx	#%00000000
			beq	DB_PutFileName
::51			rts

;*** Eintrag ausgeben.
;    Übergabe:		AKKU = Zeiger auf Eintrag.
;			xReg = Wert für currentMode
;			       ($20 = Eintrag invertieren)
:DB_PutFileName		stx	currentMode		;Textstil festlegen.

			tay				;Grenze für rechten Rand
			PushW	rightMargin		;zwischenspeichern.
			tya

			pha				;Rechteck-Bereich für aktuellen
			asl				;Eintrag definieren.
			asl
			asl
			clc
			adc	#Y_FWin +6
			pha
			tax
			inx
			stx	r2H
			sub	6
			sta	r2L

			lda	#< X_FWin		;Linker  Rand für Bereich
			sta	r3L			;definieren.
			lda	#> X_FWin

if Flag64_128 = TRUE_C128				;Double-Bit und ADD1_W einblenden
			ora	#%10100000		;ergibt 1 Leerpixel zwischen Rand
endif							;und invertiertem Balken
			sta	r3H

			lda	#< X_FWin + B_FWin -9	;Rechter Rand für Bereich und
			sta	r4L			;für Textausgabe definieren.
			sta	rightMargin +0
			lda	#> X_FWin + B_FWin -9
			sta	r4H
			sta	rightMargin +1

if Flag64_128 = TRUE_C128
			bit	graphMode		;Grafikmodus?
			bpl	:40			;>40 Zeichen
			lda	r4H			;Double-Bit bei r4 einblenden (kein
			ora	#%10000000		;ADD1_W!) ergibt 1 Leerpixel
			sta	r4H			;zwischen Rand und invertiertem
							;Balken
			asl	rightMargin +0		;rechte Randbegrenzung/80Zeichen
			rol	rightMargin +1		;anpassen (verdoppeln)
::40
endif
			lda	currentMode		;Eintrag invertieren ?
			beq	:51			; => Nein, weiter...
			lda	#$01			; => Ja, Füllmuster #01 wählen.
::51			jsr	SetPattern
			jsr	Rectangle

			pla
			sta	r1H			;Y-Koordinate festlegen.
			LoadW	r11,X_FWin +2    	;X-Koordinate festlegen.

if Flag64_128 = TRUE_C128
			bit	graphMode		;80Z/X-Koordinate der Textausgabe
			bpl	:40a			;verdoppeln
			asl	r11L			;Funktioniert nicht mit DOUBLE_W da
			rol	r11H			;SmallPutChar dies nicht unterstützt
::40a
endif
			pla
			clc
			adc	DB_1stFileInTab		;Zeiger auf Eintrag.
			cmp	DB_FilesInTab		;Gültiger Eintrag ?
			bcs	:54			; => Nein, Ende...

			tay				;Y-Koordinate speichern.
			PushB	r1H
			tya
			ldx	#r0L
			jsr	DB_SetFileNam		;Zeiger auf Eintrag berechnen.
			PopB	r1H			;Y-Koordinate zurücksetzen.

			ldy	#$00			;Eintrag ausgeben.
::52			sty	:53 +1
			lda	(r0L),y
			beq	:54
			jsr	DB_ConvertChar		;Nur Zeichen von $20-$7E.
			jsr	SmallPutChar		;Zeichen ausgeben.
::53			ldy	#$ff
			iny
			cpy	#17
			bne	:52

::54			PopW	rightMargin		;Rechten Rand zurücksetzen.

			ldx	currentMode
			lda	#$00
			sta	currentMode
			txa				;Gewählte Datei anzeigen ?
			beq	:55			; => Nein, weiter...
			bit	Flag_ViewFInfo		;Info-Anzeige aktiv ?
			bmi	:55			; => Nein, weiter...
			jsr	DB_DrawFInfo		;Datei-Informationen anzeigen.
::55			rts				;Ende.

;*** Balken verschieben.
:DB_MoveBar		lda	DB_FilesInTab
			cmp	#TabScrollY
			bcc	:51
			jsr	IsMseOnPos		;Position der Maus ermitteln.
			cmp	#$01			;Oberhalb des Anzeigebalkens ?
			beq	:52			;Ja, eine Seite zurück.
			cmp	#$02			;Auf dem Anzeigebalkens ?
			beq	:53			;Ja, Balken verschieben.
			cmp	#$03			;Unterhalb des Anzeigebalkens ?
			beq	:54			;Ja, eine Seite vorwärts.
::51			rts

::52			jmp	DB_LastPage
::53			jmp	DB_MoveToPos
::54			jmp	DB_NextPage

;*** Balken verschieben.
:DB_MoveToPos		jsr	StopMouseMove		;Mausbewegung einschränken.

:DB_TestNxMove		jsr	UpdateMouse		;Mausdaten aktualisieren.

			ldx	mouseData		;Maustaste noch gedrückt ?
			bmi	:52			; => Nein, neue Position anzeigen.

			lda	inputData		;Wurde Maus bewegt ?
			beq	DB_TestNxMove		; => Nein, keine Bewegung, Schleife.

::51			jsr	UpdateMouse		;Mausdaten aktualisieren.

			lda	inputData		;Wurde Maus bewegt ?
			beq	DB_TestNxMove		; => Nein, keine Bewegung, Schleife.

			cmp	#$06			;Maus nach unten ?
			beq	DB_MoveDOWN		; => Ja, auswerten.
			cmp	#$02			;Maus nach oben ?
			beq	DB_MoveUP		; => Ja, auswerten.
			bne	DB_TestNxMove		; => Nein, Schleife...

;--- Balken neu positionieren.
::52			jsr	DB_DefNew1stFile	;Position in Dateiliste berechnen.
			ClrB	pressFlag		;Maustastenklick löschen.
			jsr	DB_SetWindow_b		;Fenstergrenzen zurücksetzen.
			jmp	DB_DrawNewFTab		;Dateiliste anzeigen.

;--- Balken nach oben.
:DB_MoveUP		lda	SB_Top			;Am oberen Rand ?
			beq	DB_TestNxMove		; =: Ja, Abbruch...
			dec	mouseTop
			dec	mouseBottom
			dec	SB_Top
			dec	SB_End
			jsr	PrintCurBalken		;Neue Balkenposition ausgeben.
			jmp	DB_TestNxMove		;Schleife...

;--- Balken nach unten.
:DB_MoveDOWN		lda	SB_MaxYlen
			sec
			sbc	#$01
			cmp	SB_End			;Am unteren Rand ?
			beq	DB_TestNxMove		; => Ja, Abbruch...
			inc	mouseTop
			inc	mouseBottom
			inc	SB_Top
			inc	SB_End
			jsr	PrintCurBalken		;Neue Balkenposition ausgeben.
			jmp	DB_TestNxMove		;Schleife...

;*** Mausposition in Listenposition umrechnen.
:DB_DefNew1stFile	lda	SB_Top			;Aktuelle Mausposition in
			sta	r10L			;Position in Tabelle umrechnen.
			lda	SB_MaxEntry
			sec
			sbc	SB_MaxEScr
			sta	r11L
			ldx	#r10L
			ldy	#r11L
			jsr	BBMult
			lda	SB_End
			sec
			sbc	SB_Top
			sta	r0L
			inc	r0L
			lda	SB_MaxYlen
			sec
			sbc	r0L
			sta	r11L
			lda	#$00
			sta	r11H
			ldx	#r10L
			ldy	#r11L
			jsr	Ddiv

			lda	r10L			;Neue Position des Balkens
			sta	DB_1stFileInTab		;festlegen.
			rts

;*** Anzeigebalken neu Positionieren.
:DB_NewPosBalken	lda	DB_1stFileInTab
			jmp	SetPosBalken

;*** Dateiliste weiterscrollen.
:DB_NextScroll		jsr	SCPU_Pause
			lda	mouseData		;Dauerfunktion ?
			rts

;*** Eine Seite vorwärts.
:DB_NextPage		lda	DB_1stFileInTab
			add	TabScrollY * 2
			cmp	DB_FilesInTab
			bcc	:51
			jmp	DB_EndPage

::51			lda	DB_1stFileInTab
			add	TabScrollY
			sta	DB_1stFileInTab
			jmp	DB_DrawFTab

;*** Eine Seite zurück.
:DB_LastPage		lda	DB_1stFileInTab
			cmp	#TabScrollY
			bcs	:51
			jmp	DB_TopPage

::51			lda	DB_1stFileInTab
			sec
			sbc	#TabScrollY
			sta	DB_1stFileInTab
			jmp	DB_DrawFTab

;*** Zum Anfang der Dateiliste bewegen.
:DB_TopPage		lda	#$00
			cmp	DB_1stFileInTab
			beq	:51
			sta	DB_1stFileInTab
			jsr	DB_DrawFTab
::51			rts

;*** Zum Ende der Dateiliste bewegen.
:DB_EndPage		lda	DB_FilesInTab
			sec
			sbc	#TabScrollY
			bcc	:51
			beq	:51
			cmp	DB_1stFileInTab
			beq	:51
			sta	DB_1stFileInTab
			jsr	DB_DrawFTab
::51			rts

;*** Eine Datei vorwärts.
:DB_NextFile		jsr	DB_NextFile_a
			bcs	DB_NextFile_b
			jsr	StopMouseMove		;Mausbewegung einschränken.
			jsr	InvertRectangle		;Icon invertieren.

::51			jsr	DB_NextFile_a		;Scrolling möglich ?
			bcs	:52			;Nein, Abbrch.
			jsr	DB_NextFile_c		;Eine Datei vorwärts.
			jsr	DB_NextScroll		;Weiterscrollen ?
			beq	:51			;Ja, weiter...
::52			lda	#$02			;Scrolling abschließen.
			jmp	DB_EndScrolling

;*** Nächste Datei noch vorhanden ?
:DB_NextFile_a		lda	DB_1stFileInTab		;Tabellen-Ende erreicht ?
			add	TabScrollY
			cmp	DB_FilesInTab
:DB_NextFile_b		rts

;*** Bildschirm scrollen.
:DB_NextFile_c		php				;IRQ sperren.
			sei

if Flag64_128 = TRUE_C128
			bit	graphMode		;Grafikmodus?
			bpl	:40			;>40 Zeichen
			LoadW	r0,TabFirstL80		;>80Zeichen
			ldx	#TabScrollY - 1
::51a			clc				;Zeiger auf Grafik-Daten berechnen.
			lda	r0L
			sta	r1L			;r1 = r0
			adc	#<640			;r0 = r0 + 640
			sta	r0L
			lda	r0H
			sta	r1H
			adc	#>640
			sta	r0H
			txa				;X-Register sichern
			pha				;da dies verändert wird!
			jsr	DB_CopyScrnData80
			pla
			tax				;X-Register wiederherstellen
			dex
			bne	:51a
			beq	:80
::40
endif
			LoadW	r0,TabFirstL

			ldx	#TabScrollY -1
::51			clc				;Zeiger auf Grafik-Daten berechnen.
			lda	r0L
			sta	r1L			;r1 = r0
			adc	#<320			;r0 = r0 + 320
			sta	r0L
			lda	r0H
			sta	r1H
			adc	#>320
			sta	r0H
			jsr	DB_CopyScrnData
			dex
			bne	:51

::80			plp

			inc	DB_1stFileInTab		;Tabellenzeiger korrigieren.
			jsr	DB_NewPosBalken

			lda	#TabScrollY -1
			jsr	DB_PrnNewEntry
			clc
			rts

;*** Eine Datei zurück.
:DB_LastFile		jsr	DB_LastFile_a
			bcs	DB_LastFile_b
			jsr	StopMouseMove		;Mausbewegung einschränken.
			jsr	InvertRectangle		;Icon invertieren.

::51			jsr	DB_LastFile_a		;Scrolling möglich ?
			bcs	:52			;Nein, Abbrch.
			jsr	DB_LastFile_c		;Eine Datei zurück.
			jsr	DB_NextScroll		;Weiterscrollen ?
			beq	:51			;Ja, weiter...
::52			lda	#$01			;Scrolling abschließen.
			jmp	DB_EndScrolling

;*** Nächste Datei noch vorhanden ?
:DB_LastFile_a		lda	DB_1stFileInTab		;Tabellenanfang erreicht ?
			bne	:51			;Nein, -> Scrolling.
			sec				;Abbruch.
			rts
::51			clc
:DB_LastFile_b		rts

;*** Bildschirm scrollen.
:DB_LastFile_c		php				;IRQ sperren.
			sei

if Flag64_128 = TRUE_C128
			bit	graphMode		;Grafikmodus?
			bpl	:40			;>40 Zeichen
			LoadW	r0,TabLastL80		;>80 Zeichen
			ldx	#TabScrollY - 1
::51a			sec				;Zeiger auf Grafik-Daten berechnen.
			lda	r0L
			sta	r1L			;r1 = r0
			sbc	#<640			;r0 = r0 - 640
			sta	r0L
			lda	r0H
			sta	r1H
			sbc	#>640
			sta	r0H
			txa				;X-Register sichern
			pha				;da dieses verändert wird!
			jsr	DB_CopyScrnData80
			pla
			tax				;X-Register wiederherstellen
			dex
			bne	:51a
			beq	:80
::40
endif
			LoadW	r0,TabLastL

			ldx	#TabScrollY -1
::51			sec				;Zeiger auf Grafik-Daten berechnen.
			lda	r0L
			sta	r1L
			sbc	#<320
			sta	r0L
			lda	r0H
			sta	r1H
			sbc	#>320
			sta	r0H
			jsr	DB_CopyScrnData
			dex
			bne	:51

::80			plp

			dec	DB_1stFileInTab		;Tabellen-Zeiger korrigieren.
			jsr	DB_NewPosBalken

			lda	#$00
			jsr	DB_PrnNewEntry
			clc				;Weiterscrollen.
			rts

;*** Icon Re-Invertieren.
:DB_EndScrolling	pha				;Akku zwischenspeichern.
			jsr	DB_SetWindow_b		;Fenstergrenzen zurücksetzen.
			pla
			jsr	DB_AREA_AKKU
			jmp	InvertRectangle		;Icon Reinvertieren.

;*** Fenstergrenzen setzen.
:DB_SetWindow_a		ldy	#$00
			b $2c
:DB_SetWindow_b		ldy	#$06

if Flag64_128 = TRUE_C128
			bit	graphMode		;Im 80Z-Modus spezielle Tabelle
			bpl	:40			;verwenden für Fenstergrenzen
			tya
			clc
			adc	#12
			tay
::40
endif

			ldx	#$00
::51			lda	MseMoveAreas,y
			sta	mouseTop,x
			iny
			inx
			cpx	#$06
			bne	:51
			rts

;*** Bildschirmdaten kopieren.
:DB_CopyScrnData	ldy	#$00			;Grafikzeilen a 144 Byte (18 * 8)
::51			lda	(r0L),y			;verschieben.
			sta	(r1L),y
			iny
			cpy	#TabScrollX
			bne	:51
			rts

if Flag64_128 = TRUE_C128
;*** Bildschirmdaten kopieren (80 Zeichen Modus)
:DB_CopyScrnData80
			LoadB	r2L,8
			PushW	r0
			PushW	r1
			ldx	#24			;Copybit 7 in Reg. 24 setzen
			jsr	GetVDC
			sta	:CopyBit+1		;Bit retten
			ora	#%10000000
			jsr	SetVDC
::copy			lda	r0H			;Copy von r0
			ldx	#32
			jsr	SetVDC
			inx
			lda	r0L
			jsr	SetVDC
			lda	r1H			;nach r1
			ldx	#18
			jsr	SetVDC
			inx
			lda	r1L
			jsr	SetVDC			;in Y wird Lowbyte übergeben
::weiter		lda	#TabScrollX80		;Anzahl zu verschiebende Bytes
			ldx	#30			;WordCount-Register
			jsr	SetVDC

			clc				;Zeiger auf nächste Zeile
			lda	r0L
			adc	#80			;r0 = r0 + 80
			sta	r0L
			bcc	:1
			inc	r0H
::1			clc
			lda	r1L
			adc	#80			;r1 = r1 + 80
			sta	r1L
			bcc	:2
			inc	r1H

::2			dec	r2L			;alle 8 Zeilen durch?
			bne	:copy			;>nein dann weiter

			PopW	r1			;>ja dann Ende
			PopW	r0

::CopyBit		lda	#$00			;wird berechnet!
			ldx	#24			;Copybit 7 in Reg. 24 zurücksetzen
			jmp	SetVDC
endif

;*** Zeichen nach GEOS-ASCII wandeln.
:DB_ConvertChar		cmp	#$00
			beq	:51
			cmp	#$a0
			bne	:52
::51			lda	#" "
::52			cmp	#$20
			bcc	:51
			cmp	#$7f
			bcc	:53
			sbc	#$20
			jmp	:52
::53			rts

;*** Bereichsgrenzen definieren.
:DB_AREA_Sort		lda	#$04
			b $2c
:DB_AREA_WProt		lda	#$05
			b $2c
:DB_AREA_VMode		lda	#$06
			b $2c
:DB_AREA_NmBox		lda	#$07
			b $2c
:DB_AREA_FInfo		lda	#$08
			b $2c
:DB_AREA_FSize		lda	#$09
			b $2c
:DB_AREA_FInfArea	lda	#$0a

;*** Bereichs-Koordinaten einlesen.
;    Übrgabe:		AKKU = Zeiger auf Tabelle.
:DB_AREA_AKKU		asl
			sta	:51 +1
			asl
			clc
::51			adc	#$ff
			tay
			ldx	#$00
::52			lda	DB_AREA_Data,y
			sta	r2L         ,x
			iny
			inx
			cpx	#$06
			bcc	:52

if Flag64_128 = TRUE_C128
			lda	r3H			;X-Koordinaten mit DOUBLE_W
			ora	#%10000000		;verknüpfen
			sta	r3H
			lda	r4H
			ora	#%10100000		;DOUBLE_W + ADD1_W
			sta	r4H
::40
endif
			rts

;*** Grenzen für Rechteck um ein Pixel vergößern.
:DB_UpsizeBox		dec	r2L
			inc	r2H
			SubVW	1,r3
			AddVW	1,r4
			rts

;*** Größe der Box berechnen.
:DB_TEXT_UserBox	lda	#$00
			b $2c
:DB_TEXT_FileBox	lda	#$01
			b $2c
:DB_TEXT_PartBox	lda	#$02
			b $2c
:DB_TEXT_NumEntry	lda	#$03
			b $2c
:DB_TEXT_NmBox		lda	#$04
			b $2c
:DB_TEXT_FName		lda	#$05
			b $2c
:DB_TEXT_FInfo		lda	#$06
			b $2c
:DB_TEXT_FSizeInf	lda	#$07
			b $2c
:DB_TEXT_FSize		lda	#$08
			b $2c
:DB_TEXT_WProt		lda	#$09
			b $2c
:DB_TEXT_VMode		lda	#$0a
			b $2c
:DB_TEXT_Sort		lda	#$0b
			sta	:51 +1
			asl
			asl
			clc
::51			adc	#$ff
			tay
			lda	DB_TEXT_Data +0,y
			sta	r0L
			lda	DB_TEXT_Data +1,y
			sta	r0H
			lda	DB_TEXT_Data +2,y
			sta	r1H
			lda	DB_TEXT_Data +3,y
			sta	r11L
			lda	DB_TEXT_Data +4,y

if Flag64_128 = TRUE_C128
			ora	#%10000000		;Double-Bit setzen
endif
			sta	r11H
			rts

;*** Positionen für Text-Ausgabe.
:DB_TEXT_Data		w BOX_Text4
			b Y_DBox+ 6
			w (X_DBox+ 8) ! DOUBLE_W

			w DB_DNameBuf
			b Y_DBox+ 6
			w (X_DBox+ 8) ! DOUBLE_W

			w BOX_Text3
			b Y_DBox+ 6
			w (X_DBox+ 8) ! DOUBLE_W

			w $0000
			b Y_DBox+ 6
			w (X_DBox+ B_DBox -76) ! DOUBLE_W

			w BOX_Text7
			b Y_NBox- 3
			w X_NBox ! DOUBLE_W

			w DB_FNameBuf
			b Y_Info+ 6
			w (X_Info+ 4) ! DOUBLE_W

			w $0000
			b Y_Info+14
			w (X_Info+ 4) ! DOUBLE_W

			w BOX_Text8
			b Y_Size+ 6
			w X_NBox ! DOUBLE_W

			w $0000
			b Y_Size+ 6
			w (X_Size+ 4) ! DOUBLE_W

			w BOX_Text9
			b Y_WPrt+ 6
			w X_NBox ! DOUBLE_W

			w BOX_Text10
			b Y_VMod+ 6
			w X_FWin ! DOUBLE_W

			w BOX_Text11
			b Y_Sort+ 6
			w (X_Sort+ B_Sort + 4) ! DOUBLE_W

if Sprache = Deutsch
:BOX_Text1		b PLAINTEXT,"K frei",NULL
:BOX_Text2		b PLAINTEXT," Datei(en)",NULL
:BOX_Text3		b PLAINTEXT,"Partition wählen:",NULL
:BOX_Text4		b PLAINTEXT,"Bitte wählen:",NULL
:BOX_Text5		b PLAINTEXT," Eintrag",NULL
:BOX_Text6		b PLAINTEXT," Einträge",NULL
:BOX_Text7		b PLAINTEXT,"Eintrag suchen:",NULL
:BOX_Text8		b PLAINTEXT,"Dateigröße:",NULL
:BOX_Text9		b PLAINTEXT,"Schreibschutz:",NULL
:BOX_Text10		b PLAINTEXT,"Datei-Informationen",NULL
:BOX_Text11		b PLAINTEXT,"Dateien"
			b GOTOXY
			w X_Sort ! DOUBLE_W
			b Y_Sort +14
			b "sortieren",NULL
endif

if Sprache = Englisch
:BOX_Text1		b PLAINTEXT,"K free",NULL
:BOX_Text2		b PLAINTEXT," File(s)",NULL
:BOX_Text3		b PLAINTEXT,"Select partition:",NULL
:BOX_Text4		b PLAINTEXT,"Please select:",NULL
:BOX_Text5		b PLAINTEXT," Entry",NULL
:BOX_Text6		b PLAINTEXT," Entries",NULL
:BOX_Text7		b PLAINTEXT,"Search entry:",NULL
:BOX_Text8		b PLAINTEXT,"Filesize:",NULL
:BOX_Text9		b PLAINTEXT,"Write protected:",NULL
:BOX_Text10		b PLAINTEXT,"File-information",NULL
:BOX_Text11		b PLAINTEXT,"Sort"
			b GOTOXY
			w X_Sort ! DOUBLE_W
			b Y_Sort +14
			b "files",NULL
endif

;*** Variablen.
:DB_RoutVec		s 8*2				;Rücksprungadressen der Icons.
:DB_KernalAdr		w $0000				;Kernal-Rücksprung-Adresse.
:DB_KeyBVec		w $0000
:Copy_TaskAktiv		s 1				;Kopie des Taskflag
:Copy_DBoxType		b $00				;Kopfbyte der Original-Dialogbox.
:Flag_SortFiles		b $00				;Sortieren, $FF = Nicht möglich.
:Flag_ViewFInfo		b $00				;Info-Anzeige, $00 = Anzeige aktiv.
:DB_SearchName		s 17				;Dateisuche über Tastatur.
:DB_DNameBuf		s 19				;Diskname : 1 +1 +16 +1 Zeichen.
:DB_FNameBuf		s 17				;dateiname:       16 +1 Zeichen.

;*** Variablen für Partitionsauswahl.
:AdrDiskIconRout	w $0000
:Flag_PartSlct		b $00

;*** Fenstergrenzen.
:MseMoveAreas		b $00				;Vollbild 40 Zeichen
			b $c7
			w $0000
			w $013f

			b Y_DBox			;Dialogbox 40 Zeichen
			b Y_DBox + H_DBox -1
			w X_DBox
			w X_DBox + B_DBox -1

if Flag64_128 = TRUE_C128
			b $00				;Vollbild 80 Zeichen
			b $c7
			w $0000
			w $027f

			b Y_DBox			;Dialogbox 80 Zeichen
			b Y_DBox + H_DBox -1
			w (X_DBox) * 2 + 1
			w (X_DBox + B_DBox -1) * 2 + 1
endif

;*** Daten für Scrollbalken.
:BarDataX = (X_FWin + B_FWin - 8)/8     ;X-Koordinate (Definition)
:MoveBarData		b BarDataX            ;X-Koordinate.
			b (Y_FWin           ) ;Y-Koordinate.
			b (H_FWin        -16) ;Höhe des Balken in Pixel.
			b $00                 ;Max. Einträge in Tabelle.
			b TabScrollY          ;Max. Einträge auf einer Seite.
			b $00                 ;Zeiger auf ersten Eintrag.

;*** Abfrage-Bereiche.
:DB_AREA_Data		b Y_FWin              ,Y_FWin + H_FWin - 1
			w X_FWin              ,X_FWin + B_FWin - 9
			b Y_FWin + H_FWin -16 ,Y_FWin + H_FWin - 9
			w X_FWin + B_FWin - 8 ,X_FWin + B_FWin - 1
			b Y_FWin + H_FWin - 8 ,Y_FWin + H_FWin - 1
			w X_FWin + B_FWin - 8 ,X_FWin + B_FWin - 1
			b Y_FWin              ,Y_FWin + H_FWin -15
			w X_FWin + B_FWin - 8 ,X_FWin + B_FWin - 1
			b Y_Sort              ,Y_Sort + H_Sort - 1
			w X_Sort              ,X_Sort + B_Sort - 1
			b Y_WPrt              ,Y_WPrt + H_WPrt - 1
			w X_WPrt              ,X_WPrt + B_WPrt - 1
			b Y_VMod              ,Y_VMod + H_VMod - 1
			w X_VMod              ,X_VMod + B_VMod - 1
			b Y_NBox              ,Y_NBox + H_NBox - 1
			w X_NBox              ,X_NBox + B_NBox - 1
			b Y_Info              ,Y_Info + H_Info - 1
			w X_Info              ,X_Info + B_Info - 1
			b Y_Size              ,Y_Size + H_Size - 1
			w X_Size              ,X_Size + B_Size - 1
			b Y_Info              ,Y_WPrt + H_WPrt - 1
			w X_Info              ,X_Info + B_Info - 1

;*** Sprungtabelle für Mausabfrage-Bereiche.
:DB_AREA_JmpVec		w DB_SlctNewFile
			w DB_LastFile
			w DB_NextFile
			w DB_MoveBar
			w DB_SortFiles
			w DB_SwapWProt
			w DB_SwapVMode

;*** Dialogbox: Partition wählen.
:Dlg_PartIcons		b $02
			w $0000
			b $00

			w Icon_OPEN
			b $00 ! DOUBLE_B,$00,$06 ! DOUBLE_B,$10
			w DB_PART_OK

			w Icon_CANCEL
			b $00 ! DOUBLE_B,$00,$06 ! DOUBLE_B,$10
			w DB_PART_CANCEL

;******************************************************************************
; Funktion		: Auswahltabelle
; Datum			: 02.07.97
; Aufruf		: JSR  InitBalken
; Übergabe		: r0 = Zeiger auf Datentabelle.
;			  b    Zeiger auf xPos        (in CARDS!)
;			  b    Zeiger auf yPos        (in PIXEL!)
;			  b    max. Länge des Balken  (in PIXEL!)
;			  b    max. Anzahl Einträge in Tabelle.
;			  b    max. Einträge auf einer Seite.
;			  b    Tabellenzeiger = Nr. der ersten Datei auf der Seite!
;
;'InitBalken'		Muß als erstes aufgerufen werden um die Daten (r0-r2) für
;			den Anzeigebalken zu definieren und den Balken auf dem
;			Bildschirm auszugeben.
;'SetPosBalken'		Setzt den Füllbalken auf neue Position. Dazu muß im AKKU die
;			neue Position des Tabellenzeigers übergeben werden.
;'PrintBalken'		Zeichnet den Anzeige- und Füllbalken erneut. Dazu muß aber
;			vorher mindestens 1x 'InitBalken' aufgerufen worden sein!
;'ReadSB_Data'		Übergibt folgende Werte an die aufrufende Routine:
;			r0L = SB_XPos      Byte  X-Position Balken in CARDS.
;			r0H = SB_YPos      Byte  Y-Position in Pixel.
;			r1L = SB_MaxYlen   Byte  Länge des Balkens.
;			r1H = SB_MaxEntry  Byte  Anzahl Einträge in Tabelle.
;			r2L = SB_MaxEScr   Byte  Anzahl Einträge auf Seite.
;			r2H = SB_PosEntry  Byte  Aktuelle Position in Tabelle.
;			r3  = SB_PosTop    Word  Startadresse im Grafikspeicher.
;			r4L = SB_Top       Byte  Oberkante Füllbalken.
;			r4H = SB_End       Byte  Unterkante Füllbalken.
;			r5L = SB_Length    Byte  Länge Füllbalken.
;'IsMseOnPos'		Mausklick auf Anzeigebalken auswerten. Ergebnis im AKKU:
;			$01 = Mausklick Oberhalb Füllbalken.
;			$02 = Mausklick auf Füllbalken.
;			$03 = Mausklick Unterhalb Füllbalken.
;'StopMouseMove'	Schränkt Mausbewegung ein.
;'SetRelMouse'		Setzt neue Mausposition. Wird beim Verschieben des
;			Füllbalkens benötigt. Vorher muß ein 'JSR SetPosBalken'
;			erfolgen!
;******************************************************************************

;*** Balken initialiseren.
:InitBalken		ldy	#$05			;Paraeter speichern.
::51			lda	(r0L),y
			sta	SB_XPos,y
			dey
			bpl	:51

			jsr	Anzeige_Ypos		;Position Anzeigebalken berechnen.
			jsr	Balken_Ymax		;Länge des Füllbalkens anzeigen.

			lda	SB_XPos

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			lsr				;/2  da X-Koordinate für Balken berechnet
			ora	#%10000000		;DOUBLE-Bit setzen für Scroll-Icons
::40
endif
			sta	:52 +0
			sta	:53 +0
			sta	:54 +0

			lda	SB_YPos			;Position für "UP"-Icon berechnen.
			adda	SB_MaxYlen
			sta	:52 +1

			lda	SB_YPos			;Position für "DOWN"-Icon berechnen.
			adda	SB_MaxYlen
			add	8
			sta	:53 +1

			lda	SB_YPos			;Position für Balken berechnen.
			lsr
			lsr
			lsr
			sta	:54 +1

			lda	SB_MaxYlen		;Länge des Farbbalkens berechnen.
			lsr
			lsr
			lsr
			add	2
			sta	:54 +3

			jsr	i_BitmapUp		;"UP"-Icon ausgeben.
			w	Icon_UP
::52			b	$17,$ff,$01 ! DOUBLE_B,$08
			jsr	i_BitmapUp		;"DOWN"-Icon ausgeben.
			w	Icon_DOWN
::53			b	$17,$ff,$01 ! DOUBLE_B,$08
			lda	C_Balken
			jsr	i_UserColor
::54			b	$00,$00,$01 ! DOUBLE_B,$00

			jmp	PrintBalken		;Balken ausgeben.

;*** Neue Balkenposition defnieren und anzeigen.
:SetPosBalken		sta	SB_PosEntry		;Neue Position Füllbalken setzen.

;*** Balken ausgeben.
:PrintBalken		jsr	Balken_Ypos		;Y-Position Füllbalken berechnen.

:PrintCurBalken		MoveW	SB_PosTop,r0		;Grafikposition berechnen.

			ClrB	r1L			;Zähler für Balkenlänge löschen.

if Flag64_128 = TRUE_C128
			bit	graphMode		;Grafikmodus?
			bpl	:40			;>40 Zeichen

			jsr	HideOnlyMouse		;80 Zeichen Mauspfeil entfernen

::51a			lda	SB_Length		;Balkenlänge = $00 ?
			beq	:54a			;Ja, kein Füllbalken anzeigen.

			ldx	r1L
			cpx	SB_Top			;Anfang Füllbalken erreicht ?
			beq	:53a			;Ja, Quer-Linie ausgeben.
			bcc	:54a			;Kleiner, dann Hintergrund ausgeben.
			cpx	SB_End			;Ende Füllbalken erreicht ?
			beq	:53a			;Ja, Quer-Linie ausgeben.
			bcs	:54a			;Größer, dann Hintergrund ausgeben.
			inx
			cpx	SB_MaxYlen		;Ende Anzeigebalken erreicht ?
			beq	:54a			;Ja, Quer-Linie ausgeben.

::52a			lda	#0			;Wert für Füllbalken.
			b $2c
::53a			lda	#1
			b $2c
::54a			lda	#2
			asl
			tay
			lda	r0H
			ldx	#18
			jsr	SetVDC
			lda	r0L
			inx
			jsr	SetVDC
			ldx	#31
			lda	:GrafBalken,y
			jsr	SetVDC			;1. Byte in Grafikspeicher schreiben.
			iny
			lda	:GrafBalken,y
			jsr	SetVDC			;2. Byte in Grafikspeicher schreiben.
			inc	r1L
			CmpB	r1L,SB_MaxYlen		;Gesamte Balkenlänge ausgegeben ?
			beq	:56a			;Ja, Abbruch...

			AddVW	80,r0			;Zeiger auf nächstes Byte berechnen.
			ldy	#$00
			beq	:51a			;Schleife...
::56a			jmp	ExecMseKeyb		;80 Zeichen Mauspfeil wieder darstellen

::GrafBalken		b	%00111110,%01111100
			b	%00111111,%11111100
			b	%00000000,%00000000
::40
endif

			lda	SB_YPos			;Zeiger innerhalb Grafik-CARD be-
			and	#%00000111		;rechnen (Wert von $00-$07).
			tay

::51			lda	SB_Length		;Balkenlänge = $00 ?
			beq	:54			;Ja, kein Füllbalken anzeigen.

			ldx	r1L
			cpx	SB_Top			;Anfang Füllbalken erreicht ?
			beq	:53			;Ja, Quer-Linie ausgeben.
			bcc	:54			;Kleiner, dann Hintergrund ausgeben.
			cpx	SB_End			;Ende Füllbalken erreicht ?
			beq	:53			;Ja, Quer-Linie ausgeben.
			bcs	:54			;Größer, dann Hintergrund ausgeben.
			inx
			cpx	SB_MaxYlen		;Ende Anzeigebalken erreicht ?
			beq	:54			;Ja, Quer-Linie ausgeben.

::52			lda	#%01100110		;Wert für Füllbalken.
			b $2c
::53			lda	#%01111110
			b $2c
::54			lda	#%00000000
			sta	(r0L),y			;Byte in Grafikspeicher schreiben.
			inc	r1L
			CmpB	r1L,SB_MaxYlen		;Gesamte Balkenlänge ausgegeben ?
			beq	:56			;Ja, Abbruch...

			iny
			cpy	#8			;8 Byte in einem CARD gespeichert ?
			bne	:51			;Nein, weiter...

			AddVW	320,r0			;Zeiger auf nächstes CARD berechnen.
			ldy	#$00
			beq	:51			;Schleife...
::56			rts				;Ende.

;*** Position des Anzeigebalken berechnen.
:Anzeige_Ypos

if Flag64_128 = TRUE_C128
			bit	graphMode		;Grafikmodus?
			bpl	:40			;>40 Zeichen
			MoveB	SB_XPos,r0L		;r0 = $0000 + X-Cards
			lda	#$00
			sta	r0H
			ldy	SB_YPos			;Zeiger auf Y-Position
			iny
::1			dey
			beq	:52			;>fertig dann weiter
			AddVW	80,r0
			jmp	:1
::40
endif
			MoveB	SB_XPos,r0L		;Zeiger auf X-CARD berechnen.
			LoadB	r0H,NULL
			ldx	#r0L
			ldy	#$03
			jsr	DShiftLeft
			AddVW	SCREEN_BASE,r0		;Zeiger auf Grafikspeicher.

			lda	SB_YPos			;Zeiger auf Y-Position
			lsr				;berechnen.
			lsr
			lsr
			tay
			beq	:52
::51			AddVW	40*8,r0
			dey
			bne	:51
::52			MoveW	r0,SB_PosTop		;Grafikspeicher-Adresse merken.
			rts

;*** Länge des Balken berechnen.
:Balken_Ymax		lda	#$00
			ldx	SB_MaxEScr
			cpx	SB_MaxEntry		;Balken möglich ?
			bcs	:51			;Nein, weiter...
			MoveB	SB_MaxYlen,r0L		;Länge Balken berechnen.
			MoveB	SB_MaxEScr,r1L
			jsr	Mult_r0r1
			MoveB	SB_MaxEntry,r1L
			jsr	Div_r0r1
			CmpBI	r0L,8			;Balken kleiner 8 Pixel ?
			bcs	:51			;Nein, weiter...
			lda	#$08			;Mindestgröße für Balken.
::51			sta	SB_Length
			rts

;*** Position des Balken berechnen.
:Balken_Ypos		ldx	#NULL
			ldy	SB_Length
			CmpB	SB_MaxEScr,SB_MaxEntry
			bcs	:51

			MoveB	SB_PosEntry,r0L
			lda	SB_MaxYlen
			suba	SB_Length
			sta	r1L
			jsr	Mult_r0r1
			lda	SB_MaxEntry
			suba	SB_MaxEScr
			sta	r1L
			jsr	Div_r0r1
			lda	r0L
			tax
			adda	SB_Length
			tay
::51			stx	SB_Top
			dey
			sty	SB_End
			rts

:Mult_r0r1		ldx	#r0L			;Multiplikation durchführen.
			ldy	#r1L
			jmp	BBMult

:Div_r0r1		LoadB	r1H,NULL		;Division durchführen.
			ldx	#r0L
			ldy	#r1L
			jmp	Ddiv

;*** Balken initialiseren.
:ReadSB_Data		ldx	#$0a
::51			lda	SB_XPos,x
			sta	r0L,x
			dex
			bpl	:51
			rts

;*** Mausklick überprüfen.
:IsMseOnPos		lda	mouseYPos
			suba	SB_YPos
			cmp	SB_Top
			bcc	:53
::51			cmp	SB_End
			bcc	:52
			lda	#$03
			b $2c
::52			lda	#$02
			b $2c
::53			lda	#$01
			rts

;*** Mausbewegung kontrollieren.
:StopMouseMove		lda	mouseXPos +0
			sta	mouseLeft +0
			sta	mouseRight+0
			lda	mouseXPos +1
			sta	mouseLeft +1
			sta	mouseRight+1
			lda	mouseYPos
			jmp	SetNewRelMse

:SetRelMouse		lda	#$ff
			adda	SB_Top

:SetNewRelMse		sta	mouseTop
			sta	mouseBottom
			suba	SB_Top
			sta	SetRelMouse+1
			rts

;*** Variablen.
:SB_XPos		b $00				;r0L
:SB_YPos		b $00				;r0H
:SB_MaxYlen		b $00				;r1L
:SB_MaxEntry		b $00				;r1H
:SB_MaxEScr		b $00				;r2L
:SB_PosEntry		b $00				;r2H

:SB_PosTop		w $0000				;r3
:SB_Top			b $00				;r4L
:SB_End			b $00				;r4H
:SB_Length		b $00				;r5L

;*** Systemicons.
:Icon_UP
<MISSING_IMAGE_DATA>

:Icon_DOWN
<MISSING_IMAGE_DATA>

:Icon_Option
<MISSING_IMAGE_DATA>

;*** Spezial-Zeichensatz.
			t "-G3_UseFontG3"

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_GETFILES + R2_SIZE_GETFILES -1
;******************************************************************************
