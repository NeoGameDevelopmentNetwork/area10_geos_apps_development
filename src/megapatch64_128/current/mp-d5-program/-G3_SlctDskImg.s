; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Ergänzung: 25.12.18/M.Kanet
;Da im Bereich GEOS.Editor nicht mehr genügend freier Speicher
;verfügbar ist wird der Bereich für den Laufwerkstreiber genutzt um
;die DiskImage-Verzeichnisliste anzulegen.
;Hinweis: Der bereich wird beim C128 zum Teil auch für den SD2IEC-Code
;         zum wechseln von DiskImages mitverwendet.
:FileNTab		= APP_RAM
:SizeNTab		= 127*17			;BASE_EDITOR_DATA-FileNTab = $1d80
:MaxFileN		= 127				;SizeNTab/17
:FileNTabBuf		= FileNTab + SizeNTab

;*** DiskImage-Auswahl SD2IEC initialisieren.
:SlctDiskImg		ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			cmp	#%00000100		;NativeMode ?
			bne	:101			; => Nein, weiter...

			lda	#<FComCDRoot		;Auf DNP zurück zum Hauptverzeichnis.
			ldx	#>FComCDRoot
			jsr	SendCom
			jsr	OpenRootDir

::101			lda	#<FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldx	#>FComExitDImg
			jsr	SendCom

;*** Neues DiskImage wählen
:NewSlctDImg		jsr	SetFileList		;Verzeichnis einlesen.
			txa				;Fehler ?
			bne	:103			; => Ja, Abbruch...

			jsr	i_MoveData		;Speicher für Verzeichniswechsel
			w	FileNTab + 0		;reservieren.
			w	FileNTab +34
			w	MaxFileN * 17

			ldy	#$0f			;"<=" und ".." - Einträge erzeugen.
::101			lda	DirNavEntry  + 0,y
			sta	FileNTab+ 0,y
			lda	DirNavEntry  +16,y
			sta	FileNTab+17,y
			dey
			bpl	:101

			lda	DirCount		;Anzahl "ActionFiles" korrigieren.
			clc				;(Verzeichnisse und "<=" und "..")
			adc	#$02
			sta	DirCount

::102			LoadW	r0,Dlg_SlctDImg
			LoadW	r5,SlctDEntry
			lda	#$00
			sta	SlctDEntry
			jsr	DoDlgBox		;Dateiauswahlbox öffnen.
			lda	sysDBData
			cmp	#$05			;OPEN-Button.
			bne	:103			; => Nein, Abbruch.
			lda	SlctDEntry
			beq	:104
			jmp	ChangeSDImg		;Auswahl auswerten.

::104			ldx	#$00
			rts

::103			lda	FCom1stDImg+5		;DiskImage im aktuellen Verzeichnis?
			beq	:105			; => Nein, Ende...
			lda	#<FCom1stDImg 		;Erstes DiskImage aktivieren.
			ldx	#>FCom1stDImg
			jsr	SendCom
::105			ldx	#$ff
			rts				;Diskettenfehler ausgeben.

;*** DiskImage öffnen.
:ChangeSDImg		jsr	FindSlctEntry		;Nummer des Eintrages ermitteln.
			cpx	#$00			;Gefunden?
			bne	:100			; => Nein, Fehler...
			cmp	#$00			;"<= (ROOT)" Eintrag gewählt?
			bne	:101			; => Nein, weiter...
			lda	#<FComCDRoot		;SD2IEC-Root aktivieren.
			ldx	#>FComCDRoot
			jsr	SendCom
::100			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

::101			cmp	#$01			;".. (UP)" Eintrag gewählt?
			bne	:102			; => Nein, weiter...
			lda	#<FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldx	#>FComExitDImg
			jsr	SendCom
			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

::102			pha				;Gewählten Eintrag merken.

			ldy	#$00
			ldx	#$03
::103			lda	SlctDEntry,y		;Verzeichnisname in "CD"-Befehl
			beq	:104			;übertragen...
			sta	FComCDir+2,x
			inx
			iny
			cpy	#16
			bne	:103
			lda	#$00
::104			sta	FComCDir+2,x
			stx	FComCDir+0

			lda	#<FComCDir		;Verzeichnis/Image wechseln.
			ldx	#>FComCDir
			jsr	SendCom

			pla
			cmp	DirCount		;Verzeichnis oder DiskImage gewählt?
			bcc	:105			; => Verzeichnis.

			jmp	OpenDisk		;Neues DiskImage öffnen. OpenDisk ist
							;notwendig bei DNP damit max.Track im
							;DiskImage aktualisiert wird.
::105			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

;*** Gewählten Eintrag in der Dateiliste suchen.
:FindSlctEntry		lda	cntEntries +0		;Anzahl Einträge berechnen.
			clc
			adc	cntEntries +1
			clc
			adc	#$02
			sta	r14L
			LoadB	r14H,0			;Zähler auf ersten Eintrag.
			LoadW	r0,SlctDEntry		;Zeiger auf gewählten Eintrag.
			LoadW	r15,FileNTab		;Zeiger auf Datentabelle.

::1			ldx	#r0L
			ldy	#r15L
			jsr	CmpString		;Eintrag vergleichen.
			beq	:2			;Gefunden? => Ja, Ende...

			AddVBW	17,r15			;Zeiger auf nächsten Eintrag.

			inc	r14H			;Zähler erhöhen.
			lda	r14H
			cmp	r14L			;Alle Einträge verglichen?
			bcc	:1			; => Nein, weiter...

			ldx	#$ff			;Fehler: Nicht gefunden.
			rts

::2			lda	r14H			;Nummer des Eintrages in der Liste.
			ldx	#$00			;OK, Eintrag gefunden.
			rts

;*** Kompatible DiskImages einlesen.
:SetFileList		lda	#$00			;Speicher für zuletzt gefundenen
			sta	FCom1stDImg +5		;DiskImage Namen löschen.

			ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			asl
			tay
			lda	DImgTypeList +0,y	;Kennung D64/D71/D81/DNP in
			sta	FComDImgList +5		;Verzeichnis-Befehl eintragen.
			lda	DImgTypeList +1,y
			sta	FComDImgList +6

			lda	#$00			;Anzahl "ActionFiles" löschen.
			sta	DirCount

			lda	#<FComDImgList		;Verzeichnis mit gültigen DiskImages
			ldx	#>FComDImgList		;einlesen.
			jsr	GetDirList
			cpx	#$00			;Fehler ?
			bne	:100			; => Ja, weiter...

			sta	cntEntries +0		;Anzahl gefundener DiskImages merken.
			cmp	#$00			;Mind. ein Eintrag gefunden?
			beq	:101

			ldy	#$00			;Erstes gefundenes DiskImage
::99			lda	FileNTab +0,y		;merken. Wird dazu verwendet bei
			beq	:100			;Abbruch der Auswahlbox ein
			sta	FCom1stDImg +5,y	;gültiges DiskImage wieder zu
			iny				;aktivieren.
			cpy	#$10
			bcc	:99
			lda	#$00
::100			sta	FCom1stDImg +5,y
			iny
			iny
			iny
			sty	FCom1stDImg

			jsr	i_MoveData		;Liste mit DiskImages speichern.
			w	FileNTab		;Mit "<=" und ".." sind max.
			w	FileNTabBuf		;253 weitere Einträge möglich.
			w	17 * MaxFileN

;--- Verzeichnisse einlesen.
::101			lda	#<FComSDirList		;Verzeichnisse einlesen.
			ldx	#>FComSDirList
			jsr	GetDirList
			sta	cntEntries +1		;Anzahl Verzeichnisse merken.
			cpx	#$00
			bne	:106

			sta	DirCount		;Anzahl Verzeichnisse merken.

			ldy	cntEntries +0		;DiskImages gefunden?
			beq	:105			; => Nein, weiter...
			sty	r13H

			ldx	#<FileNTabBuf		;Zeiger auf Zwischenspeicher
			stx	r14L			;mit DiskImages.
			ldx	#>FileNTabBuf
			stx	r14H

			tax
::102			cpx	#MaxFileN		;Dateispeicher voll?
			bcs	:104			; => Ja, weiter...

			ldy	#$0f			;DiskImage in Auswahlliste kopieren.
::103			lda	(r14L),y
			sta	(r15L),y
			dey
			bpl	:103
			AddVBW	17,r14			;Zeiger auf nächsten Eintrag.
			AddVBW	17,r15
			inx
			dec	r13H			;Alle DiskImages übernommen?
			bne	:102			; => Nein, weiter...

::104			txa
::105			ldx	#$00
::106			rts

;*** Aktuelles Verzeichnis einlesen.
;Das Verzeichnis wird über den "$"-Befehl über den seriellen
;Bus eingelesen und in den Dateinamenspeicher übertragen.
:GetDirList		sta	r15L
			stx	r15H

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO

			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.

			bit	STATUS			;Status-Byte prüfen.
			bpl	:102			;OK, weiter...
::101			ldx	#$0d			;Fehler: "Laufwerk nicht bereits".
			jmp	GetDirListEnd		;Abbruch.

::102			lda	#$f0			;Datenkanal aktivieren.
			jsr	SECOND
			bit	STATUS			;Status-Byte prüfen.
			bmi	:101			;Fehler, Abbruch.

::103			ldy	#$00
::104			lda	(r15L),y		;Byte aus Befehl einlesen und
			beq	:104a
			jsr	CIOUT			;an Floppy senden.
			iny
			bne	:104			;Nein, weiter...
::104a			jsr	UNLSN			;Befehl abschliesen.

			lda	#$f0			;Datenkanal öffnen.
			jsr	TALK_CURDRV		;TALK-Signal auf IEC-Bus senden.

			jsr	ACPTR			;Byte einlesen.

			bit	STATUS			;Status testen.
			bpl	:105			;OK, weiter...
			ldx	#$05			;Fehler: "Verzeichnis nicht gefunden".
			jmp	GetDirListEnd

::105			ldy	#$1f			;Verzeichnis-Header
::106			jsr	ACPTR			;überlesen.
			dey
			bne	:106

			jsr	InitDirData

;*** Partitionen aus Verzeichnis einlesen.
::200			jsr	ACPTR			;Auf Verzeichnis-Ende
			cmp	#$00			;testen.
			beq	:300
			jsr	ACPTR			;(2 Byte Link-Verbindung überlesen).

			jsr	ACPTR			;Low-Byte der Zeilen-Nr. überlesen.
			jsr	ACPTR			;High-Byte Zeilen-Nr. überlesen.

::201			jsr	ACPTR			;Weiterlesen bis zum
			cmp	#$00			;Dateinamen.
			beq	:205
			cmp	#$22			; " - Zeichen erreicht ?
			bne	:201			;Nein, weiter...

			ldy	#$00			;Zeichenzähler löschen.
::202			jsr	ACPTR			;Byte aus Dateinamen einlesen.
			cmp	#$22			;Ende erreicht ?
			beq	:203			;Ja, Ende...
			sta	(r15L),y		;Byte in Tabelle übertragen.
			iny
			bne	:202

::203			AddVBW	17,r15			;Zeiger auf nächsten Eintrag.
			inc	cntDirEntry		;Dateinamen, Zähler +1.
			lda	cntDirEntry
			cmp	#MaxFileN		;Speicher voll ?
			beq	:300			;Ja, Ende...

::205			jsr	ACPTR			;Rest der Verzeichniszeile überlesen.
			cmp	#$00
			bne	:205
			jmp	:200			;Nächsten Dateinamen einlesen.

;*** Verzeichnis-Ende.
::300			jsr	UNTALK			;Datenkanal schließen.

			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.

			lda	#$e0			;Laufwerk abschalten.
			jsr	SECOND
			jsr	UNLSN

			ldx	#$00			;Kein Fehler.

;*** Verzeichnis abschließen.
:GetDirListEnd		txa
			pha
			jsr	DoneWithIO		;I/O deaktivieren.
			pla
			tax
			lda	cntDirEntry		;Anzahl Einträge.
			rts				;Ende.

;*** Speicher für Dateieinträge löschen.
:InitDirData		jsr	i_FillRam		;Speicher für Dateinamen löschen.
			w	MaxFileN * 17
			w	FileNTab
			b	$00

			lda	#$00
			sta	cntDirEntry		;Anzahl Einträge löschen.

			lda	#<FileNTab		;Zeiger auf Speicher für Daten.
			sta	r15L
			lda	#>FileNTab
			sta	r15H
			rts

;*** Daten an Floppy senden.
:SendCom		sta	r15L
			stx	r15H
			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO
			jsr	:100			;Befehl senden.
			jmp	DoneWithIO

::100			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			jsr	LISTEN_CURDRV		;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff			;Befehlskanal #15.
			jsr	SECOND			;Sekundär-Adresse nach LISTEN senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:103			;Nein, Abbruch...

			ldy	#$01			;Zähler für Anzahl Bytes einlesen.
			lda	(r15L),y
			sta	r14H
			dey
			lda	(r15L),y
			sta	r14L
			AddVBW	2,r15			;Zeiger auf Befehlsdaten setzen.
			jmp	:102

::101			lda	(r15L),y		;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			bne	:102
			inc	r15H
::102			SubVW	1,r14			;Zähler für Anzahl Bytes korrigieren.
			bcs	:101			;Schleife bis alle Bytes ausgegeben.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::103			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** LISTEN an aktuelles Laufwerk senden.
:LISTEN_CURDRV		lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jmp	LISTEN			;LISTEN-Signal auf IEC-Bus senden.

;*** TALK an aktuelles Laufwerk senden.
:TALK_CURDRV		pha
			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	TALK			;TALK-Signal auf IEC-Bus senden.
			pla
			jmp	TKSA			;Sekundär-Adresse nach TALK senden.

;*** Datei-Auswahlbox.
:Dlg_SlctDImg		b %10000001
			b DBUSRFILES
			w FileNTab
			b CANCEL    ,$00,$00
			b OPEN      ,$00,$00
			b NULL

;*** Gewählter Eintrag aus Liste.
:SlctDEntry		s 17

;*** Befehle zum DiskImage-Wechsel.
:DImgTypeList		b "??647181NP??????"
:FComDImgList		b "$:*.D??=P",NULL
:FComSDirList		b "$:*=B",NULL
:FComCDRoot		w $0004
			b "CD//"
:FComExitDImg		w $0003
			b "CD",$5f
:FComCDir		w $0000
			b "CD:"
			s 17
:FCom1stDImg		w $0000
			b "CD:"
			s 17

;*** Anzahl gefundener Einträge.
:cntDirEntry		b $00

;*** Anzahl Verzeichnis-Einträge (inkl. "<=" und "..")
:DirCount		b $00

;*** Anzahl Dateien und Verzeichnisse.
:cntEntries		b $00,$00
