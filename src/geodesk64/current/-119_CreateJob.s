; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DiskImage erstellen.
:doCreateJob		LoadB	reloadDir,$ff		;Laufwerksinhalt neu laden.

			lda	diskImgName		;DiskImage-Name definiert?
			bne	:0			; => Ja, weiter...

			jsr	createDiskName		;Standard-Name erzeugen.

::0			ldx	#$00			;Name DiskImage kopieren.
::1			lda	diskImgName,x
			beq	:2
			sta	newImageName,x
			inx
			cpx	#12
			bcc	:1

::2			lda	#"."			;Suffix für DiskImage schreiben.
			sta	newImageName,x
			inx
			lda	#"D"
			sta	newImageName,x
			inx

			ldy	#$00			;Format-Mode in Zeiger auf
			lda	formatMode		;Datentabelle umwandeln.
::3			lsr
			bcs	:4
			iny
			iny
			bne	:3

::4			lda	dImgSuffix +0,y		;Suffix für Image-Typ einlesen und
			sta	newImageName,x		;in DiskImage-Name speichern.
			inx
			lda	dImgSuffix +1,y
			sta	newImageName,x
			inx
			lda	#NULL
			sta	newImageName,x

			tya
			lsr
			clc
			adc	#$01
			sta	dImgType		;Modus 1-4 für 1541/71/81/NM.

			ClrB	statusPos		;Track-Zähler löschen.
			jsr	DrawStatusBox		;Status-Box anzeigen.

			ldy	dImgType
			beq	:5
			dey				;1541-Modus?
			beq	CreateD64		; => Ja, D64 erstellen.
			dey				;1571-Modus?
			beq	CreateD71		; => Ja, D71 erstellen.
			dey				;1581-Modus?
			beq	CreateD81		; => Ja, D81 erstellen.
			dey				;Native-Modus?
			beq	CreateDNP		; => Ja, DNP erstellen.

::5			ldx	#DEV_NOT_FOUND
			rts

;*** SD2IEC DiskImage erstellen.
;Zum erstellen der DskImages wird der
;"P"-Befehl verwendet der ausserhalb
;eines DiskImages auch für Dateien
;verwendet werden kann um den Zeiger
;auf ein bestimmtes Byte zu setzen.
:CreateD64		lda	#35			;Anzahl Tracks 1541 = 35.
			bne	DoCreateDImg		;Größe in KBytes für Info-Anzeige.

:CreateD71		lda	#70			;Anzahl Tracks 1571 = 70.
			bne	DoCreateDImg		;Größe in KBytes für Info-Anzeige.

:CreateD81		lda	#80			;Anzahl Tracks 1581 = 80.
			bne	DoCreateDImg		;Größe in KBytes für Info-Anzeige.

:CreateDNP		lda	dImgSize		;Anzahl Tracks Native = Variabel.
			cmp	#2			;Größe in KBytes für Info-Anzeige.
			bcs	DoCreateDImg		; => Mehr als 2Tracks, weiter...
			lda	#2			;Mindestens 2Tracks für DNP setzen.

;*** DiskImage erstellen.
;    Übergabe: AKKU = Anzahl Tracks 1-255.
:DoCreateDImg		sta	statusMax		;Anzahl Tracks speichern.

			jsr	doSDCom_New		;Befehl für "Neues DiskImage".

			jsr	OpenDImgFile		;Neues DiskImage anlegen.
			txa				;Diskettenfehler?
			bne	:1			; => Ja, Abbruch...

			jsr	CloseDImgFile		;DiskImage schließen.

			jsr	doSDCom_Append		;Befehl für "An DiskImage anhängen".

			jsr	WriteTracks		;DiskImage mit $00-Bytes füllen.
			txa				;Fehler?
			bne	:1			; => Ja, Abbruch...

			jsr	DrawFormatBox		;"DiskImage wird formatiert..."

			jsr	doSDCom_CD		;"CD:DiskImage"
			jsr	doSDCom_NEW		;"N0:DiskImage,01"

			jsr	NewDisk			;Diskette öffnen.
							;NewDisk erforderlich um den
							;Format-Befehl abzuwarten...

;--- Hinweis:
;Wird die Disk nicht neu initialisiert
;dann erhält GEOS beim lesen der BAM
;vom SD2IEC evtl. noch Reste des
;vorherigen DiskImage mit der falschen
;Anzahl an Tracks im DiskImage.
			lda	#<initNewDisk		;Disk initialisieren, sonst BAM des
			ldx	#>initNewDisk		;vorherigen DiskImages noch aktiv.
			jsr	SendCom			;ID-Format-Befehl senden.

;--- Hinweis:
;Ab hier ist das DiskImage erstellt und
;formatiert. AUch ist das DiskImage
;bereits geöffnet.
;Ist das DiskImage aber nicht mit dem
;Laufwerk kompatibel muss ein "CD<-"
;erfolgen um das Image zu verlassen.
;GEOS kann das DiskImage ohne den
;passenden Treiber nicht nutzen.
			ldy	curDrive		;Ist erstelles DiskImage kompatibel
			lda	driveType -8,y		;mit dem aktuellen Laufwerk?
			and	#%0000 1111
			cmp	dImgType
			beq	:2			; => Ja, weiter...

			lda	GD_SD_COMPAT_WARN	;Warnung anzeigen?
			beq	:3			; => Nein, weiter...

			LoadW	r0,Dlg_InfoDImgErr
			jsr	DoDlgBox		;Info: "DiskImage inkompatibel!"

::3			lda	#<exitDImg		;DiskImage wieder verlassen.
			ldx	#>exitDImg		;Falsches Image-Format, Editor muss
			jsr	SendCom			;manuell gestartet werden.

			ldx	#NO_ERROR
			rts

::2			LoadW	r0,Dlg_InfoDImgOK
			jsr	DoDlgBox		;Abfrage: "DiskImage öffnen?"
			lda	sysDBData		;Rückmeldung einlesen.
			cmp	#YES			;"JA"?
			bne	:3			; => Nein, Browser-Mode.

			jsr	OpenDisk		;Aktualisiert bei NativeMode die
			txa				;Anzahl der Tracks auf Disk.
			bne	:1

			ldy	WM_WCODE
;			lda	#%0000 0000		;DiskImage-Auswahl abschalten.
			sta	WIN_DATAMODE,y		;DiskImage ist aktiv.

::1			rts				;Diskettefehler anzeigen.

;*** DiskImage öffnen.
;Beim ersten Aufruf wird der Modus "W" = schreiben aktiviert.
;Danach wird "A" für APPEND = Anhängen verwendet.
:OpenDImgFile		lda	curDrive
			jsr	SetDevice
			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			ClrB	STATUS			;Fehler-Flag löschen.

			lda	FComSDImgFLen		;Dateiname setzen.
			ldx	#<FComSDImgNm
			ldy	#>FComSDImgNm
			jsr	SETNAM
			lda	STATUS			;Fehler?
			bne	:1			; => Ja, Abbruch...

			lda	#2			;Datenkanal festlegen.
			ldx	curDrive
			ldy	#2
			jsr	SETLFS
			lda	STATUS			;Fehler?
			bne	:1			; => Ja, Abbruch...

			jsr	OPENCHN			;Datenkanal öffnen.
			bcc	:2			; => OK, kein Fehler...

::1			jsr	CloseDImgFile		;Datenkanal schließen.
			ldx	#DEV_NOT_FOUND		;Fehler/DiskImage nicht erstellt.
			rts

::2			ldx	#$02			;Ausgabekanal festlegen.
			jsr	CKOUT
			ldx	#NO_ERROR
			rts

;*** DiskImage öffnen.
:CloseDImgFile		lda	#$02			;Datenkanal schließen.
			jsr	CLOSE
			jsr	CLRCHN
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** SDImage-Befehl erzeugen.
:doSDCom_New		lda	#"W"			;Datei erstellen.
			b $2c
:doSDCom_Append		lda	#"A"			;An Datei anhängen.
			pha

			ldx	#0			;Name DiskImage kopieren.
::1			lda	newImageName,x
			beq	:2
			sta	FComSDImgFNm,x
			inx
			cpx	#16
			bcc	:1
::2			lda	#","			;",P,W/A" anhängen.
			sta	FComSDImgFNm,x
			inx
			lda	#"P"
			sta	FComSDImgFNm,x
			inx
			lda	#","
			sta	FComSDImgFNm,x
			inx
			pla
			sta	FComSDImgFNm,x
			inx
			lda	#NULL
			sta	FComSDImgFNm,x
			inx
			inx
			inx
			stx	FComSDImgFLen		;Länge Dateiname.
			rts

;*** CD-Befehl erzeugen.
:doSDCom_CD		ldx	#$00			;Name DiskImage kopieren.
::1			lda	newImageName,x
			beq	:2
			sta	cdDiskImage0,x
			inx
			cpx	#16
			bcc	:1
::2			txa				;Länge Befehl berechnen.
			clc
			adc	#3
			sta	cdDiskImage +0		;Länge Befehl speichern.
			lda	#$00
			sta	cdDiskImage +1

			lda	#<cdDiskImage
			ldx	#>cdDiskImage
			jmp	SendCom			;In DiskImage wechseln.

;*** ID-Befehl erzeugen.
:doSDCom_NEW		ldx	#$00			;Name DiskImage kopieren.
::1			lda	newImageName,x
			beq	:2
			sta	idDiskImage0,x
			inx
			cpx	#16
			bcc	:1
::2			lda	#","
			sta	idDiskImage0,x
			inx
			lda	#"0"
			sta	idDiskImage0,x
			inx
			lda	#"1"
			sta	idDiskImage0,x
			inx

			txa				;Länge Befehl berechnen.
			clc
			adc	#2
			sta	idDiskImage +0		;Länge Befehl speichern.
			lda	#$00
			sta	idDiskImage +1

			lda	#<idDiskImage
			ldx	#>idDiskImage
			jmp	SendCom			;ID-Format-Befehl senden.

;*** DiskImage mit $00-Bytes füllen.
;Zum erstellen der DiskImages wird der
;"P"-Befehl verwendet der ausserhalb
;eines DiskImages auch für Dateien
;verwendet werden kann um den Zeiger
;auf ein bestimmtes Byte zu setzen.
:WriteTracks		ldx	#$00			;"P"-Befehl initialisieren.
			stx	FCom_SetPos +2		;Bytes.
			stx	FCom_SetPos +3		;Sektoren.
			stx	FCom_SetPos +4		;Tracks.
			stx	FCom_SetPos +5		;Ungenutzt (Max. 16Mb möglich).
			inx
			stx	statusPos		;Zeiger auf Track #1.

::101			jsr	GetMaxSek		;Anzahl Sektoren / Track ermitteln.

			jsr	sysPrntStatus		;Fortschrittsbalken aktualisieren.

			jsr	OpenDImgFile		;DiskImage-Datei öffnen.
			txa				;Diskettenfehler?
			bne	:103			; => Ja, Abbruch...

::102			inc	FCom_SetPos +3		;Byte-Zähler anpassen.
			bne	:102a
			inc	FCom_SetPos +4		;Mehr als 65536 Sektoren?
			beq	:103			; => Ja, Abbruch...
::102a			dec	curTrackSek		;Zeiger auf letztes Byte gesetzt?
			bne	:102			; => Nein, nächster Sektor.

::104			lda	#15			;"P"-Befehl an SD2IEC senden.
			ldx	curDrive
			tay
			jsr	SETLFS
			lda	#$00
			jsr	SETNAM
			jsr	OPENCHN			;Befehlskanal öffnen.

			jsr	UNTALK

			lda	curDrive		;Aktuelles Laufwerk auf Befehls-
			jsr	LISTEN			;empfang vorbereiten.

			lda	#15 ! %11110000
			jsr	SECOND			;Daten über Befehls-Kanal senden.
			ldy	#$00
::106			tya
			pha
			lda	FCom_SetPos,y
			jsr	BSOUT
			pla
			iny
			cpy	#7
			bcc	:106

			jsr	UNLSN

			lda	#15			;Befehls- und Datenkanal schließen.
			jsr	CLOSE
			jsr	CloseDImgFile

			lda	statusPos
			inc	statusPos
			cmp	statusMax		;Alle Tracks erzeugt?
			bcc	:101			; => Nein, weiter...
			jsr	sysPrntStatus		;Fortschrittsbalken aktualisieren.
			ldx	#NO_ERROR
			rts

::103			jsr	CloseDImgFile
			ldx	#DEV_NOT_FOUND
			rts

:FCom_SetPos		b "P",$02,$00,$00,$00,$00,$0d

;*** Sektor-Anzahl für Spur-Nr. bestimmen (1541/71/81/Native).
;    Übergabe: statusPos   = Track-Adresse.
;    Rückgabe: curTrackSek = Anzahl Sektoren.
:GetMaxSek		ldx	dImgType		;Laufwerkstyp einlesen.
			beq	:102			; => 0 = Fehler.
			dex				;1541?
			beq	GetSectors		; => Ja, Sektoranzahl ermitteln.
			dex				;1571?
			beq	GetSectors		; => Ja, Sektoranzahl ermitteln.
			dex				;1581?
			bne	:101			; => Nein, weiter...

			LoadB	curTrackSek,40		;Immer 80Sek/Track.
			ldx	#NO_ERROR		;Kein Fehler.
			rts

::101			dex				;NativeMode?
			bne	:102			; => Nein, Abbruch...

			stx	curTrackSek		;Immer 256/Sek/Track.
;			ldx	#NO_ERROR		;Kein Fehler.
			rts

::102			ldx	#DEV_NOT_FOUND		;Unbekanntes Laufwerk.
			rts

;*** Sektor-Anzahl für Spur-Nr. bestimmen (1541/71).
:GetSectors		lda	statusPos		;Track = $00 ?
			beq	:101			; => Ja, Abbruch.

			ldy	dImgType		;Laufwerkstyp festlegen.
			dey				;1541-Laufwerk ?
			bne	:102			; => Nein, weiter...

			CmpBI	statusPos,36		;Track von $01 - $33 ?
			bcc	:103			; => Ja, weiter...

::101			ldx	#INV_TRACK		;Fehler "Invalid Track".
			rts				;Abbruch.

::102			dey				;1571-Laufwerk ?
			bne	:107			; => Nein, weiter...

			CmpBI	statusPos,71		;Track von $00 - $46 ?
			bcs	:101			; => Nein, Abbruch.

::103			ldy	#7			;Zeiger auf Track-Tabelle.
::104			cmp	Tracks,y		;Track > Tabellenwert ?
			bcs	:105			;Ja, max. Anzahl Sektoren einlesen.
			dey				;Zeiger auf nächsten Tabellenwert.
			bpl	:104			;Weiteruchen.
			bmi	:101			;Ungültige Track-Adresse.

::105			tya				;1571: Auf Track $01-$33 begrenzen.
			and	#%0000 0011
			tay
			lda	Sectors,y		;Anzahl Sektoren einlesen
::106			sta	curTrackSek		;und merken...

			ldx	#NO_ERROR		;"Kein Fehler"...
			rts

::107			ldx	#DEV_NOT_FOUND		;Routine wird nur bei 1541/1571
			rts				;aufgerufen. 1581/Native -> Fehler.

;*** Neuen Disknamen erzeugen.
;    Übergabe: r10 = Zeiger auf Speicher Diskname.
;Hinweis:
;Der erzeugte Name hat das Format:
; "SDIMG-hhmmss"
:createDiskName		ldx	#$00			;Prefix für neuen Namen kopieren.
::1			lda	dImgPrefix,x
			sta	diskImgName,x
			inx
			cpx	#6
			bcc	:1

::2			lda	hour			;Aktuelle Uhrzeit
			jsr	DEZ2ASCII		;in Vorgabename kopieren.
			stx	diskImgID +0
			sta	diskImgID +1
			lda	minutes
			jsr	DEZ2ASCII
			stx	diskImgID +2
			sta	diskImgID +3
			lda	seconds
			jsr	DEZ2ASCII
			stx	diskImgID +4
			sta	diskImgID +5
			rts

;*** Daten an Floppy senden.
;    Übergabe: AKKU/XREG lo/hi Zeiger auf Befehlsdaten:
;              w $xxxx = Anzahl Bytes.
;              b xx    = Befehlsbytes.
:SendCom		sta	r0L			;Zeiger auf Befehl speichern.
			stx	r0H

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO
			jsr	:sendcom		;Befehl senden.
			jmp	DoneWithIO

;--- Befehlsbytes an Laufwerk senden.
::sendcom		jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff			;Befehlskanal #15.
			jsr	SECOND			;Sekundär-Adr. nach LISTEN senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:3			;Nein, Abbruch...

			ldy	#$01			;Zähler für Anzahl Bytes einlesen.
			lda	(r0L),y
			sta	r1H
			dey
			lda	(r0L),y
			sta	r1L
			AddVBW	2,r0			;Zeiger auf Befehlsdaten setzen.
			jmp	:2

::1			lda	(r0L),y			;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			bne	:2
			inc	r0H
::2			SubVW	1,r1			;Zähler Anzahl Bytes korrigieren.
			bcs	:1			;Schleife bis alle Bytes ausgegeben.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::3			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** DiskImage-Format wählen.
;Im RegisterMenü wird dabei immer nur
;eine Option aktiviert und die anderen
;Optionen deaktiviert.
:SlctD64		lda	#%00000001
			b $2c
:SlctD71		lda	#%00000010
			b $2c
:SlctD81		lda	#%00000100
			b $2c
:SlctDNP		lda	#%00001000
			sta	formatMode		;Neuen Format-Modus speichern.

;--- RegisterMenü-Optionen aktuelisieren.
			LoadW	r15,modeD64
			jsr	RegisterUpdate

			LoadW	r15,modeD71
			jsr	RegisterUpdate

			LoadW	r15,modeD81
			jsr	RegisterUpdate

			LoadW	r15,modeDNP
			jmp	RegisterUpdate

;*** Button invertieren und Laufwerksgröße ausgeben.
;    Übergabe: AKKU = 0: 64Kb weniger.
;                     1: 64Kb mehr.
;                     2: Stdandard-Größen.
;              Der Wert wird für das invertieren des
;              Icons verwendet.
:PrntNewSize		pha
			jsr	SetIconArea		;Icon-Bereich definieren.
			jsr	InvertRectangle		;Icon invertieren.
			jsr	PrntCurSize		;Neue Größe anzeigen.
			jsr	SCPU_Pause		;Pause...
			pla
			jsr	SetIconArea		;Icon-Bereich definieren.
			jmp	InvertRectangle		;Anzeige zurücksetzen.

;*** Laufwerksgröße ausgeben.
:PrntCurSize		lda	#$00			;Füllmuster setzem.
			jsr	SetPattern

			jsr	i_Rectangle		;Anzeigebereich löschen.
			b	RPos1_y +RLine1_4
			b	RPos1_y +RLine1_4 +$07
			w	RPos1_x +RWidth3
			w	R1SizeX1 -$08 -$08 -$18

;--- Größe in KBytes.
			lda	dImgSize		;Anzahl Spuren in freien
			sta	r0L			;Speicher umrechnen.
			LoadB	r0H,0
			ldx	#r0L
			ldy	#6			;2^6 = 64.
			jsr	DShiftLeft		;Jede Spur = 64Kb.

			LoadB	r1H,RPos1_y +RLine1_4 +$06
			LoadW	r11,RPos1_x +RWidth3 +$02
			lda	#%11000000
			jsr	PutDecimal

			lda	#"K"			;"Kb" ausgeben.
			jsr	SmallPutChar
			lda	#"b"
			jsr	SmallPutChar

;--- Anzahl Tracks.
			lda	dImgSize
			sta	r0L
			lda	#$00
			sta	r0H
			LoadB	r1H,RPos1_y +RLine1_4 +$06
			LoadW	r11,R1SizeX1 -$08 -$08 -$10 -$20
			lda	#%11000000
			jsr	PutDecimal

			lda	#"T"			;"T" ausgeben für "Tracks".
			jmp	SmallPutChar

;*** Grenzen für +/- Icons festlegen.
;    Übergabe: AKKU = 0: 64Kb weniger.
;                     1: 64Kb mehr.
;                     2: Stdandard-Größen.
:SetIconArea		tax

;--- Y-Position setzen.
			LoadB	r2L,RPos1_y +RLine1_4
			LoadB	r2H,RPos1_y +RLine1_4 +$07

			txa				;64Kb weniger?
			bne	:1			; => Nein, weiter...

;--- "<" / 64Kb weniger.
			LoadW	r3,R1SizeX1 -$08 -$08 -$18 +$01
			LoadW	r4,R1SizeX1 -$08 -$08 -$18 +$08
			rts

::1			dex				;64Kb mehr?
			bne	:2			; => Nein, weiter...

;--- ">" / 64Kb mehr.
			LoadW	r3,R1SizeX1 -$08 -$08 -$08 +$01
			LoadW	r4,R1SizeX1 -$08 -$08 -$08 +$08
			rts

;--- "+>" / Standardformate.
::2			LoadW	r3,R1SizeX1 -$08 -$08 -$10 +$01
			LoadW	r4,R1SizeX1 -$08 -$08 -$10 +$08
			rts

;*** DiskImage +64K.
:Add64K			ldx	dImgSize
			cpx	#$ff			;Weiterer Speicher verfügbar?
			bcc	:1			; => Ja, weiter...
			rts

::1			inx
			stx	dImgSize		;Neue Imagegröße speichern.

			lda	#1 			;Position für ">"-Icon.
			jsr	PrntNewSize		;Neue Größe anzeigen.
			jmp	SlctDNP			;DNP-Option aktivieren.

;*** DiskImage -64K.
:Sub64K			ldx	dImgSize		;Speicher weiter reduzierbar?
			cpx	#$03			;Mind 2x64K erforderlich.
			bcs	:1			; => Ja, weiter...
			rts

::1			dex
			stx	dImgSize		;Neue Größe festlegen.

			lda	#0 			;Position für "<"-Icon.
			jsr	PrntNewSize		;Neue Größe anzeigen.
			jmp	SlctDNP			;DNP-Option aktivieren.

;*** Nächste Standardgröße setzen.
:NextStd		lda	dImgSize		;Aktuelle Größe einlesen.
			cmp	#$10			; > 1Mb?
			bcs	:1			; => Ja, weiter...
			lda	#$10			;1Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::1			cmp	#$20			; > 2Mb?
			bcs	:2			; => Ja, weiter...
			lda	#$20			;2Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::2			cmp	#$40			; > 4Mb?
			bcs	:3			; => Ja, weiter...
			lda	#$40			;4Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::3			cmp	#$80			; > 8Mb?
			bcs	:4			; => Ja, weiter...
			lda	#$80			;8Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::4			cmp	#$c0			; > 12Mb?
			bcs	:5			; => Ja, weiter...
			lda	#$c0			;12Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::5			cmp	#$ff			; > 16Mb?
			bcs	:6			; => Ja, weiter...
			lda	#$ff			;16Mb als neue Größe setzen.
			bne	:newsize		;Neue Größe speichern.

::6			lda	#$02			;Auf Minimum zurücksetzen.

;--- Neue größe speichern/anzeigen.
::newsize		sta	dImgSize		;Neue Imagegröße speichern.

			lda	#2 			;Position für "+"-Icon.
			jsr	PrntNewSize		;Neue Größe anzeigen.
			jmp	SlctDNP			;DNP-Option aktivieren.

;*** Variablen.
:dImgType		b $00				;Image-Modus 1/D64, 2/D71, 3/D81, 4/DNP.

;--- Name für DiskImage mit Suffix.
:newImageName		s 17

;--- Suffix für DiskImages.
:dImgSuffix		b "647181NP"

;--- Standard max. 6Zeichen +Uhrzeit.
:dImgPrefix		b "SDIMG-",NULL

;--- Name für DiskImage ohne Suffix.
:diskImgName		b "SDIMG-"
:diskImgID		b "xxxxxx"
			b NULL

;--- Format-Modus für Register-Menü.
:formatMode		b %00000100			;%00000001 D64
							;%00000010 D71
							;%00000100 D81
							;%00001000 DNP
:formatModeTab		b %0000 0100			;???
			b %0000 0001			;D64
			b %0000 0010			;D71
			b %0000 0100			;D81
			b %0000 1000			;DNP
			b %0000 0100			;???
			b %0000 0100			;???
			b %0000 0100			;???

;--- NativeMode:
;    Gewählte DiskImage-Größe.
:dImgSize		b $40

;--- Datei erstellen/anhängen.
:FComSDImgFLen		b $00
:FComSDImgNm		b $40,"0:"
:FComSDImgFNm		b "1234567890123456"
			b ",P,W",NULL

;--- DiskImage öffnen.
:cdDiskImage		w $0000
			b "CD:"
:cdDiskImage0		s 17

;--- DiskImage formatieren.
:idDiskImage		w $0000
			b "N:"
:idDiskImage0		b "1234567890123456"
			b ",01"
			b NULL

;--- BAM aktualisieren.
:initNewDisk		w $0004
			b "I0:",CR

;--- DiskImage verlassen.
:exitDImg		w $0003
			b "CD",$5f

;*** Tabelle mit Tracks, bei denen ein Wechsel der
;    Sektoranzahl/Track stattfindet.
:Tracks			b $01,$12,$19,$1f,$24,$35,$3c,$42
:Sectors		b $15,$13,$12,$11
:curTrackSek		b $00				;Anzahl Sektoren für aktuellen Track.

;*** Info: DiskImage erstellt, öffnen?
:Dlg_InfoDImgOK		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$18,$30
			w :3
			b DBTXTSTR   ,$38,$30
			w newImageName
			b DBTXTSTR   ,$0c,$40
			w :4
			b YES        ,$01,$50
			b NO         ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "DiskImage erfolgreich erstellt!",NULL
::3			b BOLDON
			b "Datei:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Das erstellte DiskImage öffnen?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Disk image successfully created!",NULL
::3			b BOLDON
			b "File:",PLAINTEXT,NULL
::4			b PLAINTEXT
			b "Open the created disk image?",NULL
endif

;*** Info: DiskImage erstellt, nicht kompatibel!
:Dlg_InfoDImgErr	b %01100001
			b $30,$9f
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$0c,$30
			w :3
			b DBTXTSTR   ,$0c,$3a
			w :4
			b DBTXTSTR   ,$0c,$48
			w :5
			b DBTXTSTR   ,$0c,$52
			w :6
			b OK         ,$01,$58
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "DiskImage erfolgreich erstellt!",NULL
::3			b PLAINTEXT
			b "Das erstellte DiskImage ist nicht mit",NULL
::4			b "dem Laufwerk kompatibel!",NULL
::5			b "Zum öffnen des DiskImages GEOS.Editor",NULL
::6			b "starten und Laufwerkstreiber wechseln.",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Disk image successfully created!",NULL
::3			b PLAINTEXT
			b "The created disk image is not",NULL
::4			b "compatibel with the drive!",NULL
::5			b "To open the disk image please start",NULL
::6			b "GEOS.Editor and switch disk driver.",NULL
endif
