; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#403.obj"
			o	ModStart
			q	EndProgrammCode
			r	EndAreaCBM

			jmp	Partition
			jmp	MakeNDir
			jmp	DelNDir
			jmp	SlctNDir

			t	"-CBM_SetName"

;*** L403: Partition wählen.
:Partition		lda	Target_Drv
			jsr	NewDrive

:InitPartDrv		jsr	i_FillRam
			w	18*256,FilePTab
			b	$00

			ldx	#$00			;Partitionslaufwerkstabelle
			ldy	#8			;erstellen.
::101			lda	DriveModes-8,y
;--- Ergänzung: 23.11.18/M.Kanet
;Bei SD2IEC über Partitionswechsel den Wechsel des
;aktuellen DiskImages ermöglichen.
			and	#%10000001		;CMD/SD2IEC?
			beq	:102			; => Nein, weiter...
			bmi	:101a			; => CMD-Laufwerk = OK.
			cpy	AppDrv			; => SD2IEC, Systemlaufwerk?
			beq	:102			; => Ja, Wechsel nicht möglich.
::101a			tya				;Gültiges Laufwerk in Tabelle
			sta	V403b1,x		;übernehmen.
			inx
::102			iny
			cpy	#12
			bne	:101

			txa				;Mindestens ein Laufwerk?
			bne	:103			; => Ja, weiter...
::102a			jmp	NoCMDDrv		;Fehler: Kein CMD/SD2IEC-Laufwerk.

::103			sta	V403b2			;Anzahl CMD-Laufwerke merken.

			lda	curDrvMode		;Aktuelles Laufwerk vom Typ CMD
			and	#%10000001		;oder SD2IEC ?
			beq	:103a			; => Nein, weiter...
			bmi	:104			; => CMD-Laufwerk, OK.
			lda	curDrive		;SD2IEC-Laufwerk. Systemlaufwerk
			cmp	AppDrv			;aktiv?
			bne	:104			; => Nein, weiter...
;--- Ergänzung: 23.11.18/M.Kanet
;Beim SD2IEC kann das DiskImage auf dem Systemlaufwerk nicht gewechselt
;werden. In der Liste der gültigen Laufwerke wird das Laufwerk daher auch
;nich aufgenommen. Falls das Systemlaufwerk das aktive Laufwerk ist wird
;hier auf das erste gültige Laufwerk gewechselt.
::103a			lda	V403b1			;Erstes CMD-Laufwerk aktivieren.
			jsr	NewDrive

;--- Ergänzung: 23.11.18/M.Kanet
;Auswerten ob CMD- oder SD2IEC-Laufwerk und
;entsprechendes Unterprogramm zum Partition oder
;DiskImage-Wechsel aufrufen.
::104			lda	curDrvMode		;Aktuelles Laufwerk auswerten.
;			and	#%10000001		;Kann nur CMD- oder SD2IEC sein.
			bpl	:105			; => Bit#7=0, kein CMD.
			jmp	InitPartSlct		; => CMD: Partition auswählen.
::105			jmp	InitDImgSlct		; => SD2IEC: DiskImage auswählen.

;*** Auswahl auswerten.
:CheckSelect		lda	r13L			;Rückmeldung Dialogbox auswerten.
			bne	:101			; => Kein Eintrag gewählt, weiter...

			MoveB	r13H,V403b0		;Gewählten Eintrag merken.
;--- Ergänzung: 23.11.18/M.Kanet
;Auswerten ob CMD- oder SD2IEC-Laufwerk.
			lda	curDrvMode		;Aktuelles Laufwerk auswerten.
			and	#%10000001
			bpl	:100
			jmp	ChangePart		; => CMD: Partition wechseln.
::100			jmp	ChangeSDImg		; => SD2IEC: DiskImage wechseln.

::101			cmp	#$01			;OK?
			beq	:102			; => Ja, weiter...
			cmp	#$02			;Abbruch?
			bne	:104			; => Nein, weiter...
::102			lda	curDrvMode		;Aktuellen Laufwerks-Typ einlesen.
			and	#%00000001		;SD2IEC?
			beq	:103			; => Nein, weiter...
			lda	r13L			;Sicherstellen das auf allen SD2IEC
			jmp	ExitSDImgSlct		;ein DiskImage aktiv ist.

::103			lda	r13L
::104			cmp	#$80			;Laufwerkswechsel?
			bcc	L403ExitGD		; => Nein, weiter...
			cmp	#$90			;Partitionswechel?
			bcs	L403ExitGD		; => Ja, weiter...

			and	#%01111111		;Neues Laufwerk isolieren.
			clc
			adc	#$08
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			jmp	InitPartDrv		;Partitionen einlesen.

;*** Partitions-Auswahl verlassen.
:L403ExitGD		jmp	InitScreen

;*** Fehler: Laufwerk nicht partitioniert.
:NoPartDrv		lda	curDrive
			add	$39
			sta	V403g0 + 16

			DB_OK	V403g0
			jmp	L403ExitGD

;*** Fehler: Kein CMD/SD2IEC-Laufwerk.
:NoCMDDrv		DB_OK	V403g1
			jmp	L403ExitGD

;*** Partitionsauswahl CMD-Laufwerke initialisieren.
:InitPartSlct		jsr	CheckDiskCBM		;Neue Diskette öffnen.
			txa				;Diskette im Laufwerk ?
			bne	NewPartSlct		;Nein, weiter...
			jsr	CMD_Part		;Partitionen einlesen.
			cpx	#$00			;Fehler ?
			bne	:101			; => Ja, Abbruch...

			ldx	V403b2
			cpx	#$02			;Mehr als 1 CMD-Laufwerk ?
			bcs	NewPartSlct		;Ja, weiter...

			cmp	#$02			;Mehr als 1 Partition auf Laufwerk ?
			bcs	NewPartSlct		;Ja, weiter...
			jmp	NoPartDrv		;Laufwerk nicht partitioniert.
::101			jmp	DiskError		;Diskettenfehler ausgeben.

:NewPartSlct		lda	#<V403c0		;Partition auswählen.
			ldx	#>V403c0
			jsr	SelectBox
			jmp	CheckSelect		;Rückmeldung Dialogbox auswerten.

;*** Partition wechseln.
:ChangePart		ldy	V403b0			;Partition auf CMD RL/RD.
			lda	FilePTab,y
			beq	:101
			jsr	SaveNewPart		;Neue Partition aktivieren.
			txa				;Fehler?
			bne	:102			; => Ja, neue Partition wählen.

::101			jsr	InitCMD2
			lda	V403b2			;Anzahl Partitionen einlesen.
			cmp	#$01			;Mehr als eine Partition gefunden?
			beq	L403ExitGD		; => Nein, Abbruch.
::102			jmp	NewPartSlct

;*** DiskImage-Auswahl SD2IEC initialisieren.
:InitDImgSlct		lda	#$00			;Verzeichnis anzeigen.
			sta	DirListMode
			jsr	CheckDiskCBM		;Neue Diskette öffnen.
			txa				;Diskette im Laufwerk ?
			bne	NewSlctDImg		;Nein, weiter...

			ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			cmp	#%00000100		;NativeMode ?
			bne	:101			; => Nein, weiter...

			C_Send	V403d7			;Auf DNP zurück zum Hauptverzeichnis.
			jsr	New_CMD_Root

::101			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler?
			bne	:102			; => Ja, weiter...
			jsr	PutDirHead		;BAM aktualisieren (Cache im Treiber).

::102

;--- DiskImages anzeigen.
;DiskImage im aktiven Laufwerk aktiv. Das DiskImage nicht mehr
;automatisch verlassen sondern Datei-Browser starten.
;Falls man das DiskImage auf einem anderen Laufwerk wechseln will müsste
;man sonst zuerst auf dem aktiven Laufwerk wieder ein DiskImage auswählen.
;			C_Send	V403d6			;Aktives DiskImage verlassen.
;			lda	#$00			;DiskImages anzeigen.
;			sta	DirListMode

;--- Alternativ: Start mit Dateibrowser.
			lda	#$ff			;Verzeichnis anzeigen.
			sta	DirListMode

			ldy	#$00
::103			lda	curDirHead+$90,y	;Disk-Name einlesen.
			cmp	#$a0			;Falls mit Verzeichnis-Anzeige
			beq	:104			;gestartet wird ist der Titel noch
			sta	V403l4a,y		;ohne Inhalt. Beim Wechsel eines
			iny				;DiskImages wird hier dann der
			cpy	#16			;DiskImage-Name eingetragen.
			bcc	:103
::104			lda	#$00
			sta	V403l4a,y

;*** Neues DiskImage wählen
:NewSlctDImg		jsr	SD_Image		;Verzeichnis einlesen.
			txa				;Fehler ?
			bne	:103			; => Ja, Abbruch...

			jsr	i_MoveData		;Speicher für Verzeichniswechsel
			w	FileNTab + 0		;reservieren.
			w	FileNTab +32
			w	254 * 16

			ldy	#$0f			;"<=" und ".." - Einträge erzeugen.
::101			lda	V403l1  + 0,y
			sta	FileNTab+ 0,y
			lda	V403l1  +16,y
			sta	FileNTab+16,y
			dey
			bpl	:101

			lda	V403c2a			;Anzahl "ActionFiles" korrigieren.
			clc
			adc	#$02
			sta	V403c2a

			lda	#<V403c2		;DiskImage auswählen.
			ldx	#>V403c2
			ldy	DirListMode
			bpl	:102
			lda	#<V403c3		;Dateibrowser für DiskImage.
			ldx	#>V403c3
::102			jsr	SelectBox
			jmp	CheckSelect		;Auswahl auswerten.
::103			jmp	DiskError		;Diskettenfehler ausgeben.

;*** Kompatible DiskImages einlesen.
:SD_Image		lda	#$00			;Speicher für zuletzt gefundenen
			sta	V403k5 +5		;DiskImage Namen löschen.

			ldy	curDrive		;DiskImage-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			asl
			tay
			lda	V403k3 +0,y		;Kennung D64/D71/D81/DNP in
			sta	V403k1 +4		;Verzeichnis-Befehl eintragen.
			lda	V403k3 +1,y
			sta	V403k1 +5

			lda	#$00			;Anzahl "ActionFiles" löschen.
			sta	V403c2a

			lda	DirListMode		;Neues Verzeichnis einlesen.
			beq	:98
			jsr	DoInfoBox		;Meldung "Verzeichnisse einlesen..."
			PrintStrgDB_RdFile

			lda	#<V403k6		;Dateien im aktuellen DiskImage
			ldx	#>V403k6		;einlesen.
			ldy	#$01
			jmp	InitDir

::98			jsr	DoInfoBox		;Meldung "DiskImages einlesen..."
			PrintStrgV403l3

;--- DiskImages einlesen.
			lda	#<V403k1		;Verzeichnis mit gültigen DiskImages
			ldx	#>V403k1		;einlesen.
			ldy	#$08
			jsr	InitDir
			cpx	#$00			;Fehler ?
			bne	:100			; => Ja, weiter...

			sta	V403k0 +0		;Anzahl gefundener DiskImages merken.
			cmp	#$00			;Mind. ein Eintrag gefunden?
			beq	:101

			ldy	#$00			;Erstes gefundenes DiskImage
::99			lda	FileNTab +32,y		;merken. Wird dazu verwendet bei
			beq	:100			;Abbruch der Auswahlbox ein
			sta	V403k5 +5,y		;gültiges DiskImage wieder zu
			iny				;aktivieren.
			cpy	#$10
			bcc	:99
			lda	#$00
::100			sta	V403k5 +5,y
			iny
			iny
			iny
			sty	V403k5

			jsr	i_MoveData		;Liste mit DiskImages speichern.
			w	FileNTab		;Mit "<=" und ".." sind max.
			w	TempDataBuf		;253 weitere Einträge möglich.
			w	16 * 253

;--- Verzeichnisse einlesen.
::101			lda	#<V403k2		;Verzeichnisse einlesen.
			ldx	#>V403k2
			ldy	#$05
			jsr	InitDir
			sta	V403k0 +1		;Anzahl Verzeichnisse merken.
			cpx	#$00
			bne	:106

			sta	V403c2a			;Anzahl Verzeichnisse merken.

			ldy	V403k0 +0		;DiskImages gefunden?
			beq	:105			; => Nein, weiter...

			ldx	#<TempDataBuf		;Zeiger auf Zwischenspeicher
			stx	r14L			;mit DiskImages.
			ldx	#>TempDataBuf
			stx	r14H

			tax
::102			cpx	#255 -2			;Dateispeicher voll?
			bcs	:104			; => Ja, weiter...

			ldy	#$0f			;DiskImage in Auswahlliste kopieren.
::103			lda	(r14L),y
			sta	(r15L),y
			dey
			bpl	:103
			AddVBW	16,r14			;Zeiger auf nächsten Eintrag.
			jsr	Add_16_r15
			inx
			dec	V403k0 +0		;Alle DiskImages übernommen?
			bne	:102			; => Nein, weiter...

::104			txa
::105			ldx	#$00
::106			rts

;*** DiskImage öffnen.
:ChangeSDImg		lda	V403b0			;"<= (ROOT)" Eintrag gewählt?
			bne	:101			; => Nein, weiter...
			lda	DirListMode		;Dateibrowser?
			bpl	:100			; => Nein, weiter...
			C_Send	V403d6			;Aktives DiskImage verlassen.
::100			C_Send	V403d7			;SD2IEC-Root aktivieren.
			lda	#$00			;Verzeichnisse/DiskImages anzeigen.
			sta	DirListMode
			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

::101			cmp	#$01			;".. (UP)" Eintrag gewählt?
			bne	:102			; => Nein, weiter...
			C_Send	V403d6			;Ein SD2IEC-Verzeichnis zurück.
			lda	#$00			;Verzeichnisse/DiskImages anzeigen.
			sta	DirListMode
			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

::102			bit	DirListMode		;Dateibrowser aktiv?
			bmi	:105			; => Dateiauswahl ignorieren.

			pha				;Gewählten Eintrag merken.

			ldy	#$00
			ldx	#$03
::103			lda	(r15L),y		;Verzeichnisname in "CD"-Befehl
			beq	:104			;übertragen...
			sta	V403d3,x
			sta	V403l4a,y
			inx
			iny
			cpy	#16
			bne	:103
			lda	#$00
::104			sta	V403d3,x
			sta	V403l4a,y
			stx	V403d2

			C_Send	V403d2			;Verzeichnis/Image wechseln.

			pla
			cmp	V403c2a			;Verzeichnis oder DiskImage gewählt?
			bcc	:105			; => Verzeichnis.

			jsr	OpenDisk		;Neues DiskImage öffnen. OpenDisk ist
							;notwendig bei DNP damit max.Track im
							;DiskImage aktualisiert wird.
			lda	#$ff			;Verzeichnis anzeigen.
			sta	DirListMode
::105			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

;*** Bei Abbruch letztes DiskImage aktivieren.
:ExitSDImgSlct		cmp	#$02			;"Abbruch" ?
			bne	:101			; => Nein, weiter...

			lda	V403k5+5		;DiskImage im aktuellen Verzeichnis?
			beq	:101			; => Nein, Fehler ausgeben...
			C_Send	V403k5			;Erstes DiskImage aktivieren.

::101			ldy	#$08
::102			lda	DriveTypes -8,y		;Laufwerk vorhanden?
			beq	:103			; => Nein, weiter...
			lda	DriveModes -8,y
			and	#%00000001		;Prüfen ob auf allen SD2IEC-Laufwerken
			beq	:103			;ein DiskImage eingelegt ist.
			tya
			pha
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	OpenDisk		;Neues DiskImage öffnen. OpenDisk ist
							;notwendig bei DNP damit max.Track im
							;DiskImage aktualisiert wird.
			pla
			tay
			txa				;Diskettenfehler?
			bne	:104			; => Ja, DiskImage wählen.
::103			iny				;Zeiger auf nächstes Laufwerk.
			cpy	#12			;Alle Laufwerke geprüft?
			bcc	:102			; => Nein, weiter...

;--- Ergänzung: 09.12.18/M.Kanet
;Bei "-InsertDisk" wird bereits NewDisk ausgeführt.
;Der zu Testzwecken hier eingeführte Code behebt nicht das Problem das
;in seltenen Fällen mit C=-Laufwerken auftritt (Laufwerk nicht ansprechbar)
;nachdem auf ein SD2IEC zugegriffen wurde.
;			lda	Target_Drv		;Ziel-Laufwerk wieder
;			jsr	NewDrive		;aktivieren. "NewDisk" über TurboDOS
;			jsr	NewDisk			;senden und Laufwerk initialisieren.

			jmp	L403ExitGD		;Zurück zu GeoDOS.

::104			tya
			clc
			adc	#$39
			sta	V403m1a

			DB_OK	V403m0			;Fehler: "Kein aktives DiskImage".

			lda	#$00			;Verzeichnisse/DiskImages anzeigen.
			sta	DirListMode
			jmp	NewSlctDImg		;Neues Verzeichnis einlesen.

;*** Verzeichnis wechseln.
:SlctNDir		C_Send	V403d7			;Hauptverzeichnis aktivieren.
			jsr	New_CMD_Root

::101			jsr	SetTargetNDir		;Ziel-Verzeichnis wählen.
			cpx	#$ff			;"Abbruch" ?
			beq	:102			;ja, Ende...
			cpy	#$01
			beq	:102

			cmp	#$ff			;Weitere Verzeichnisse vorhanden ?
			beq	:101			;Ja, weiter...

			lda	V403d1			;Hauptverzeichnis ?
			bne	:101			;Nein, weiter...

			DB_OK	V403g4			;Fehler: "Keine Unterverzeichnisse..."
::102			jmp	L403ExitGD		;Zurück zu GeoDOS...

;*** Verzeichnis erstellen.
:MakeNDir		bit	curDrvMode		;CMD-Laufwerk?
			bpl	:100			; => Nein, weiter...

			ldy	curDrive
			lda	DrivePart -8,y		;Partition definiert?
			beq	:100			; => Nein, weiter...
			jsr	SetNewPart		;Partition aktivieren.

::100			C_Send	V403d7			;Hauptverzeichnis aktivieren.
			jsr	New_CMD_Root

::101			jsr	SetTargetNDir		;Ziel-Verzeichnis wählen.
			cpx	#$ff			;Abbruch ?
			bne	:103			;Nein, weiter...
::102			jmp	L403ExitGD		;Zurück zu GeoDOS.

::103			LoadW	r0 ,V403e0		;Name für Verzeichnis eingeben.
			LoadW	r1 ,V403e1
			LoadB	r2L,$00
;--- Ergänzung: 23.11.18/M.Kanet
;r2H=$00 => Kein Vorgabetext.
			LoadB	r2H,$00
			LoadW	r3,V403a2
			jsr	cbmSetName
			cmp	#$01			;"OK" ?
			beq	:104			;Ja, weiter...
			cmp	#$03			;"EXIT" ?
			beq	:102			;Ja, Zurück zu GeoDOS.
			jmp	:109			;Weiter...

::104			jsr	ConvDirName		;Verzeichnisname konvertieren.

			jsr	DoInfoBox		;Info: "Prüfe Verzeichnis..."
			PrintStrgV403f3

			jsr	IsDirOnDsk		;Ist Verzeichnisname schon vergeben ?
			cmp	#$ff
			bne	:105			;Nein, weiter...

			jsr	ClrBox
			DB_OK	V403g2			;Fehler: "Name bereits vergeben..."
			jmp	:103

::105			jsr	ClrBoxText		;Info: "Verzeichnis wird angelegt..."
			PrintStrgV403f2

			ldy	#$00
			ldx	#$03
::106			lda	V403e1,y		;Verzeichnisname in "MD"-Befehl
			beq	:107			;übertragen.
			sta	V403d5,x
			inx
			iny
			cpy	#16
			bne	:106
			lda	#$00
::107			sta	V403d5,x
			stx	V403d4

			jsr	MakeNDirSys		;Verzeichnis anlegen.
			txa				;Fehler aufgetreten?
			bne	:107a			; => Ja, Fehler ausgeben.

			jsr	IsDirOnDsk		;Verzeichnis suchen...
			cmp	#$ff			;Gefunden ?
			beq	:108			;Ja, weiter...

			jsr	ClrBox
::107a			DB_OK	V403g3			;Fehler: "Kann SubDir nicht anlegen!"
			jmp	:103

::108			jsr	ClrBox

::109			DB_UsrBoxV403h0			;Weiteres Verzeichnis anlegen?
			CmpBI	sysDBData,4
			beq	:110			; => Nein, Ende...
			jmp	:101			; => Ja, Weiter...

::110			jmp	L403ExitGD		;Zurück zu GeoDOS...

;*** Unterverzeichnis anlegen.
;Bei CMD-Laufwerken bis bisher mit "MD:", auf anderen
;Laufwerken wie RAMNative/SD2IEC mit GEOS-Routinen.
:MakeNDirSys		ldx	curDrive
			lda	DriveModes-8,x		;Laufwerksdaten einlesen.
			bpl	:101			; => Kein CMD-Laufwerk, weiter...
			C_Send	V403d4			;Bei CMD-Laufwerk Befehl: "MD".
;--- Ergänzung: 02.12.18/M.Kanet
;Der "I0:"-Befehl ist notwendig da sonst beim nächsten "OpenDisk" die
;BAM des neu angelegten UV über das GEOS-TurboDOS eingelesen wird.
			C_Send	V403d8			;Befehl "I0:" aktualisiert die BAM.
			ldx	#$00
::100			rts

;--- Ergänzung: 23.11.18/M.Kanet
;Bei SD2IEC oder RAMNative Verzeichnis über
;GEOS-Routinen erstellen.
;Sektorsuche ab TR01/SE64 = CMD-Standard.
::101			LoadB	r3L,1			;Freien Sektor für neuen
			LoadB	r3H,64			;Verzeichnis-Header suchen.
			jsr	SetNextFree
			txa				;Fehler?
			bne	:100			; => Ja, Abbruch...

			lda	r3L
			ldx	r3H
::102			sta	NewDirHd+0		;Reservierten Sektor merken.
			stx	NewDirHd+1

			jsr	SetNextFree		;Sektor für neues Verzeichnis suchen.
			txa				;Fehler?
			bne	:100			; => Ja, Abbruch...

;--- Ergänzung: 06.12.18/M.Kanet
;Gemäß CMD-RAMLink-Handbuch S4-4, "NativeMode SubDirectories":
; >> This "file" is initially two blocks long, and consists of
; >> a directory header block and the first directory block.
; >> These two blocks are always located next to each
; >> other on the same track, and if two adjacent blocks
; >> cannot be found, no directory will be created.
			lda	r3L
			ldx	r3H
			cmp	NewDirHd +0
			bne	:103
			cpx	#$00
			beq	:103
			dex
			cpx	NewDirHd +1
			beq	:110

;--- Ergänzung: 23.12.18/M.Kanet
;Falls kein passendes Sektor-Paar gefunden wurde, muss der zuvor reservierte
;Sektor vor der nächsten Suche wieder freigegeben werden.
::103			lda	NewDirHd +0		;Sektor für Verzeichnis-Header
			sta	r6L			;wieder freigeben.
			lda	NewDirHd +1
			sta	r6H
			jsr	FreeBlock
			txa
			bne	:100

			lda	r3L			;Zweiten Verzeichnis-Sektor als
			ldx	r3H			;Startwert für neue Sektor-Suche
			bne	:102			;verwenden.
			beq	:100			;Track ungültig, Fehler.

::110			inx
			sta	NewDirSk +0		;Reservierten Sektor merken.
			stx	NewDirSk +1

			jsr	MakeNDirEntry		;Neuen Verzeichnis-Eintrag erzeugen.
			txa				;Fehler?
			bne	:100			; => Ja, Abbruch...

			jsr	MakeNDirHead		;Neuen Verzeichnis-Header erzeugen.
			txa				;Fehler?
			bne	:100			; => Ja, Abbruch...

			jsr	MakeNDirSek		;Leeren Verzeichnis-Sektor erzeugen.
			txa				;Fehler?
			bne	:100			; => Ja, Abbruch...

			jmp	PutDirHead		;BAM aktualisieren.

;*** Neuen Verzeichnis-Eintrag erzeugen.
:MakeNDirEntry		LoadB	r10L,0			;Gesamtes Verzeichnis nach freiem
			jsr	GetFreeDirBlk		;Eintrag durchsuchen.
			txa				;Leeren Eintrag gefunden?
			beq	:11			; => Ja, weiter...
::10			rts				;Fehler, Abbruch.

::11			MoveB	r1L,DirEntry+0		;Sektor mit leerem Verzeichnis-
			MoveB	r1H,DirEntry+1		;Eintrag merken.
			sty	    DirEntry+2		;Zeiger auf Verzeichnis-Eintrag merken.

			lda	#$86			;Typ "Unterverzeichnis".
			sta	diskBlkBuf,y
			iny
			lda	NewDirHd+0		;Zeiger auf neuen Verzeichnis-Header
			sta	diskBlkBuf,y		;übernehmen.
			iny
			lda	NewDirHd+1
			sta	diskBlkBuf,y
			iny

			jsr	CopyDirName		;Verzeichnis-Name kopieren.

			lda	#$00
			sta	diskBlkBuf,y		;Tr/Se für Info-Block löschen.
			iny
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y		;GEOS-Dateistruktur: 0 = Sequentiell.
			iny
			sta	diskBlkBuf,y		;GEOS-Dateityp: 0 =  Nicht GEOS.
			iny
			lda	year			;Jahr/Monat/Tag übernehmen.
			sta	diskBlkBuf,y
			iny
			lda	month
			sta	diskBlkBuf,y
			iny
			lda	day
			sta	diskBlkBuf,y
			iny
			lda	hour			;Stunde/Minute übernehmen.
			sta	diskBlkBuf,y
			iny
			lda	minutes
			sta	diskBlkBuf,y
			iny
			lda	#$02			;Größe des neuen Unterverzeichnis:
			sta	diskBlkBuf,y		;1Block Header und 1Block Verzeichnis.
			iny
			lda	#$00
			sta	diskBlkBuf,y
			LoadW	r4,diskBlkBuf		;Verzeichnis aktualisieren.
			jmp	PutBlock

;*** Neuen Verzeichnis-Header erstellen.
;Dazu wird als Vorlage der aktuelle Header in curDirHead
;verwendet und modifiziert.
:MakeNDirHead		ldx	#$00			;curDirHead kopieren als Vorlage
::11			lda	curDirHead,x		;für neuen Verzeichnis-Header.
			sta	diskBlkBuf,x
			inx
			cpx	#39
			bcc	:11
			lda	#$00			;Reservierte Bytes löschen.
::12			sta	diskBlkBuf,x
			inx
			bne	:12

			lda	NewDirSk  +0		;Zeiger auf ersten Verzeichnis-
			sta	diskBlkBuf+$00		;Sektor übernehmen.
			lda	NewDirSk  +1
			sta	diskBlkBuf+$01

;--- Ergänzung: 06.12.18/M.Kanet
;Wenn der Header erstellt wird prüft GEOS nicht auf den
;Header-Sektor und wechselt daher auch nicht den Disknamen.
			ldy	#$04			;Verzeichnis-Name kopieren.
			jsr	CopyDirName
;			ldy	#$90
;			jsr	CopyDirName

			lda	#$a0			;Füllbytes.
			sta	diskBlkBuf+$14
			sta	diskBlkBuf+$15

			ldx	curDirHead+$a2		;Disk-ID.
			stx	diskBlkBuf+$16		;Hinweis: Durch den GEOS-Treiber
			ldx	curDirHead+$a3		;werden die Daten für den Disknamen
			stx	diskBlkBuf+$17		;ab Byte $90 abgebildet.

			sta	diskBlkBuf+$18		;Füllbyte.

			ldx	curDirHead+$a5		;DOS-Version.
			stx	diskBlkBuf+$19

			ldx	curDirHead+$a6		;Disk format type.
			stx	diskBlkBuf+$1a

			sta	diskBlkBuf+$1b		;Füllbytes.
			sta	diskBlkBuf+$1c

			lda	#$00
			sta	diskBlkBuf+$1d
			sta	diskBlkBuf+$1e
			sta	diskBlkBuf+$1f

			lda	NewDirHd  +0		;Tr/Se für Verzeichnis-Header in
			sta	diskBlkBuf+$20		;neuen Header eintragen.
			sta	r1L			;Tr/Se auch nach r1L/r1H für
			lda	NewDirHd  +1		;späteres PutBlock.
			sta	diskBlkBuf+$21
			sta	r1H

			lda	curDirHead+$20		;Tr/Se für aktuelles Verzeichnis
			sta	diskBlkBuf+$22		;als Tr/Se für Parent-Directory setzen.
			lda	curDirHead+$21
			sta	diskBlkBuf+$23

			lda	DirEntry  +0		;Tr/Se/Byte in neuen Header übernehmen
			sta	diskBlkBuf+$24		;als Zeiger auf den zugehörigen
			lda	DirEntry  +1		;Verzeichnis-Eintrag.
			sta	diskBlkBuf+$25
			lda	DirEntry  +2
			sta	diskBlkBuf+$26

			LoadW	r4,diskBlkBuf		;Neuen Verzeichnis-Header schreiben.
			jmp	PutBlock

;*** Leeren Verzeichnis-Sektor erzeugen.
:MakeNDirSek		ldx	#$00			;Sektorinhalt löschen.
			txa
::11			sta	diskBlkBuf,x
			inx
			bne	:11
			dex				;$00/$FF für "Verzeichnis-Ende"
			stx	diskBlkBuf+1		;setzen.

			lda	NewDirSk  +0		;Tr/Se für leeren Verzeichnis-Sektor
			sta	r1L			;setzen.
			lda	NewDirSk  +1
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf diskBlkBuf.
			jmp	PutBlock		;Verzeichnis-Sektor schreiben.

;*** Verzeichnis-Name nach diskBlkBuf schreiben.
;Wird zum erstellen des Verzeichnis-Eintrages und
;zum erstellen des neuen Verzeichnis-Headers benötigt.
;Übergabe: YReg = Zeiger auf diskBlkBuf.
:CopyDirName		ldx	#$00
::11			lda	V403e1,x		;Ende Dateiname erreicht?
			beq	:12			; => Ja, weiter...
			cmp	#$a0			;Ende Dateiname erreicht?
			beq	:13			; => Ja, weiter...
			sta	diskBlkBuf,y		;Zeichen nach diskBlkBuf kopieren.
			iny				;Zeiger auf nächstes Zeichen.
			inx				;Zähler erhöhen.
			cpx	#$10			;Max. 16Zeichen gelesen?
			bcc	:11			; => Nein, weiter...
			bcs	:14			; => Ja, Ende...

::12			lda	#$a0			;Dateinamen mit $A0 bis 16Z. auffüllen.
::13			sta	diskBlkBuf,y
			iny
			inx				;Zähler erhöhen.
			cpx	#$10			;Max. 16Zeichen erreicht?
			bcc	:13			; => Nein, weiter...

::14			rts

;*** Verzeichnisname von GEOS nach PETSCII konvertieren.
:ConvDirName		ldx	#$00
::10			lda	V403e1,x		;Ende Dateiname erreicht?
			beq	:12			; => Ja, Ende...
			cmp	#" "			;Gültiges Zeichen?
			bcc	:11			; => Nein, mit "X" ersetzen.
			cmp	#$80
			bcs	:11			; => Nein, mit "X" ersetzen.
			tay				;Zeichen konvertieren durch einlesen
			lda	:100 -32,y		;Ersatzzeichen aus Tabelle.
			b $2c
::11			lda	#$58			;Ungültiges Zeichen.
			sta	V403e1,x
			inx
			cpx	#$10
			bcc	:10
::12			rts

::100			b $20,$21,$22,$23,$58,$25,$26,$27
			b $28,$29,$58,$2b,$58,$2d,$2e,$58

			b $30,$31,$32,$33,$34,$35,$36,$37
			b $38,$39,$3a,$3b,$3c,$3d,$3e,$58

;--- Convert GEOS -> PETSCII
;Die folgenden 64Byte erzeugen Verzeichnisnamen
;analog zu den BASIC-Befehlen:
;Kleinbuchstaben/GEOS -> Kleinbuchstaben/BASIC.
;Verzeichnis-Wechsel über `cd:abcABC` möglich.
;Wird aber unter GEOS als Großbuchstaben angezeigt.
;			b $40,$c1,$c2,$c3,$c4,$c5,$c6,$c7
;			b $c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
;			b $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7
;			b $d8,$d9,$da,$c1,$cf,$d5,$5e,$2d

;			b $27,$41,$42,$43,$44,$45,$46,$47
;			b $48,$49,$4a,$4b,$4c,$4d,$4e,$4f
;			b $50,$51,$52,$53,$54,$55,$56,$57
;			b $58,$59,$5a,$41,$4f,$55,$d3,$58

;--- Convert GEOS -> GEOS
;Die folgenden 64Byte erzeugen Verzeichnisnamen
;die kompatibel zu den BASIC-Befehlen sind:
;Kleinbuchstaben/GEOS -> Großbuchstaben/BASIC.
;Verzeichnis-Wechsel über `cd:abcABC` möglich.
;Namen sind aber nicht mehr GEOS-Kompatibel da
;die Zeichen größer > $80 sind.
;			b $40,$41,$42,$43,$44,$45,$46,$47
;			b $48,$49,$4a,$4b,$4c,$4d,$4e,$4f
;			b $50,$51,$52,$53,$54,$55,$56,$57
;			b $58,$59,$5a,$41,$4f,$55,$5e,$2d

;			b $27,$c1,$c2,$c3,$c4,$c5,$c6,$c7
;			b $c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
;			b $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7
;			b $d8,$d9,$da,$c1,$cf,$d5,$d3,$58

;--- Convert GEOS -> GEOS
;Die folgenden 64Byte erzeugen Verzeichnisnamen
;die inkompatibel zu den BASIC-Befehlen sind:
;Kleinbuchstaben/GEOS -> Großbuchstaben/BASIC.
;Verzeichnis-Wechsel über `cd:abcABC` nicht möglich.
;Hier nur Großbuchstaben verwenden!
			b $40,$41,$42,$43,$44,$45,$46,$47
			b $48,$49,$4a,$4b,$4c,$4d,$4e,$4f
			b $50,$51,$52,$53,$54,$55,$56,$57
			b $58,$59,$5a,$5b,$5c,$5d,$5e,$5f

			b $60,$61,$62,$63,$64,$65,$66,$67
			b $68,$69,$6a,$6b,$6c,$6d,$6e,$6f
			b $70,$71,$72,$73,$74,$75,$76,$77
			b $78,$79,$7a,$7b,$7c,$7d,$7e,$58

;*** Verzeichnis löschen.
:DelNDir		C_Send	V403d7			;Hauptverzeichnis aktivieren.
			jsr	New_CMD_Root

::101			jsr	SetTargetNDir		;Ziel-Verzeichnis wählen.
			cmp	#$ff			;Weitere Verzeichnisse vorhanden ?
			beq	:103			;Ja, weiter...

			DB_OK	V403g4			;Fehler: "Keine Unterverzeichnisse..."
::102			jmp	L403ExitGD		;Zurück zu GeoDOS...

::103			cpx	#$ff			;"Abbruch" ?
			beq	:102			;Ja, zurück zu GeoDOS.

			lda	V403d1			;Hauptverzeichnis ?
			bne	:104			;Nein, weiter...

			DB_OK	V403g6			;Fehler: "Kann ROOT nicht löschen!"
			jmp	:101

::104			jsr	DoInfoBox		;Info: "Prüfe Verzeichnis..."
			PrintStrgV403f3

			jsr	IsNextDir		;Weitere Unterverzeichnisse ?
			cmp	#$00
			beq	:105			;Nein, weiter...

			jsr	ClrBox
			DB_OK	V403g5			;Fehler: "Erst SubDirs löschen!"
			jmp	:101

::105			jsr	IsNextFile		;Dateien vorhanden ?
			cmp	#$00
			beq	:107			;Nein, weiter...

			jsr	ClrBox
			DB_UsrBoxV403h1
			CmpBI	sysDBData,3
			beq	:106
			jmp	:101			;Nein, Verzeichnis wählen...

::106			jsr	DoInfoBox		;Info: "Lösche Dateien..."
			PrintStrgV403f0

			jsr	DelAllFiles		;Alle Dateien löschen...

::107			jsr	ClrBoxText		;Info: "Lösche Verzeichnis..."
			PrintStrgV403f1

			jsr	GetDirHead		;BAM einlesen.

			lda	curDirHead+36		;Zeiger auf Startsektor des
			ldx	curDirHead+37		;aktuellen Verzeichnisses merken.
			sta	a0L
			stx	a0H
			lda	curDirHead+38
			sta	a1L

			lda	curDirHead+34		;Verzeichnis zurücksetzen.
			ldx	curDirHead+35
			sta	r1L
			stx	r1H
			jsr	New_CMD_SubD
			C_Send	V403d6

			MoveW	a0,r1			;Verzeichnis löschen...
			LoadW	r4,diskBlkBuf
			jsr	GetBlock		;Aktuellen Verzeichnis-Sektor lesen.
			txa
			beq	:108
			jmp	DiskError		;Diskettenfehler.

::108			ldy	#$00			;Verzeichnis-Eintrag
			ldx	a1L			;in GEOS-Speicher kopieren.
::109			lda	diskBlkBuf,x
			sta	dirEntryBuf,y
			inx
			iny
			cpy	#$1e
			bne	:109

			ldx	a1L
			lda	#$00
			sta	diskBlkBuf,x		;Eintrag als "gelöscht" markieren.
			LoadW	r4,diskBlkBuf
			jsr	PutBlock		;Eintrag auf Diskette
			txa				;zurückschreiben.
			bne	:110

			LoadW	r9,dirEntryBuf		;Verzeichnissektoren freigeben...
			jsr	FreeFile
			txa
			beq	:111
::110			jmp	DiskError		;Diskettenfehler...

::111			jsr	ClrBox			;Weitere Verzeichnisse löschen...
			jmp	:101

;*** Ziel-Verzeichnis wählen.
:SetTargetNDir		jsr	GetNDir			;Verzeichnisse einlesen.
			bne	:101			;Weitere Verzeichnisse vorhanden ?
			ldx	#$00			;Nein, Ende...
			rts

::101			lda	#<V403c1		;Ziel-Verzeichnis wählen.
			ldx	#>V403c1
			jsr	SelectBox

			lda	r13L			;Verzeichnis gewählt ?
			beq	:103			;Ja, weiter...
			cmp	#$01
			bne	:102			;Ja, Ende...

			lda	#$ff			;Verzeichnis bestätigt...
			ldx	#$00			;und ausgewählt...
			ldy	r13L
			rts

::102			lda	#$ff			;Abbruch...
			ldx	#$ff
			rts

::103			ldy	#$00
			ldx	#$03
::104			lda	(r15L),y		;Verzeichnisname in "CD"-Befehl
			beq	:105			;übertragen...
			sta	V403d3,x
			inx
			iny
			cpy	#16
			bne	:104
			lda	#$00
::105			sta	V403d3,x
			stx	V403d2

			lda	r13H
			asl
			tay
			lda	FileDTab+0,y		;GEOS-Native-Verzeichnis aktivieren.
			sta	r1L
			lda	FileDTab+1,y
			sta	r1H
			jsr	New_CMD_SubD
			bit	curDrvMode
			bpl	:106
			C_Send	V403d2			;CMD-Native-Verzeichnis aktivieren.
::106			jsr	InitCMD3
			jmp	SetTargetNDir		;Weitere Verzeichnisse anzeigen...

;*** Dateityp-Byte einlesen.
:GetFileTyp		asl
			asl
			asl
			asl
			asl
			tax
			rts

;*** Enthält aktuelles Verzeichnis weitere Verzeichnisse ?
:IsNextDir		lda	#$00			;Verzeichnisse suchen,...
			b $2c
:IsNextFile		lda	#$ff			;Dateien suchen...
			sta	r12H

			jsr	GetDirHead		;BAM einlesen.

			lda	curDirHead+0		;Zeiger auf ersten DIR-Sektor...
			ldx	curDirHead+1
::101			sta	r1L
			stx	r1H

			LoadW	r4,diskBlkBuf		;DIR-Sektor einlesen...
			jsr	GetBlock
			txa
			beq	:102
			jmp	DiskError		;Diskettenfehler.

::102			lda	#$00			;Zeiger auf ersten Eintrag.
			sta	r13L

::103			jsr	GetFileTyp
			lda	diskBlkBuf+2,x
			beq	:105			;Ja, übergehen...
			and	#%00001111
			bit	r12H			;Verzeichnisse suchen ?
			bmi	:104			;Nein, weiter...

			cmp	#$06			;Verzeichnis ?
			beq	:106			;Ja, Abbruch...
			bne	:105			;Nein, weiter...

::104			cmp	#$00			;Datei ?
			bne	:106			;Ja, Abbruch...

::105			inc	r13L			;Zeiger auf nächsten Eintrag.
			CmpBI	r13L,8			;Alle Einträge geprüft ?
			bne	:103			;Nein, weiter...

			ldx	diskBlkBuf+1		;Zeiger auf nächsten DIR-Sektor.
			lda	diskBlkBuf+0		;Ende erreicht ?
			beq	:107			;Ja, Ende...
			jmp	:101			;Nein, weiter...

::106			lda	#$ff			;"Abbruch"...
::107			rts

;*** Verzeichnisse einlesen.
:GetNDir		jsr	DoInfoBox		;Infobox anzeigen.
			PrintStrgV403f4

			jsr	i_FillRam		;Speicher für Namen löschen.
			w	256*16,FileNTab
			b	$00
			jsr	i_FillRam		;Speicher für Daten löschen.
			w	256* 2,FileDTab
			b	$00

			jsr	GetDirHead		;BAM einlesen...

			LoadW	r14,FileNTab
			LoadW	r15,FileDTab
			ClrB	V403d1

			lda	curDirHead+32		;Hauptverzeichnis ?
			ldx	curDirHead+33
			cmp	#$01
			bne	:101
			cpx	#$01
			beq	:103

::101			ldy	#$0f			;Nein, "." und ".." - Einträge
::102			lda	V403d0  + 0,y		;erzeugen.
			sta	FileNTab+ 0,y
			lda	V403d0  +16,y
			sta	FileNTab+16,y
			dey
			bpl	:102

			ldy	#$01
			sty	FileDTab  + 0
			sty	FileDTab  + 1
			ldy	curDirHead+34
			sty	FileDTab  + 2
			ldy	curDirHead+35
			sty	FileDTab  + 3
			AddVBW	32,r14
			AddVBW	4 ,r15
			inc	V403d1
			inc 	V403d1

::103			lda	V403d1			;Zeiger auf ersten Eintrag-Sektor.
			sta	r13H

			lda	curDirHead+0		;Zeiger auf ersten DIR-Sektor...
			ldx	curDirHead+1
::104			sta	r1L
			stx	r1H

			LoadW	r4,diskBlkBuf		;DIR-Sektor einlesen.
			jsr	GetBlock
			txa
			beq	:105
			jmp	DiskError		;Diskettenfehler...

::105			lda	#$00			;Zeiger auf ersten Directory-Eintrag.
			sta	r13L
::106			jsr	GetFileTyp
			lda	diskBlkBuf+2,x
			and	#%00001111
			cmp	#$06			;Directory ?
			bne	:109			;Nein, weiter...

			ldy	#$00
			lda	diskBlkBuf+3,x		;Startsektor einlesen und in
			sta	(r15L),y		;Tabelle übertragen...
			iny
			lda	diskBlkBuf+4,x
			sta	(r15L),y

			ldy	#$00
::107			lda	diskBlkBuf+5,x		;Dateiname in Tabelle übernehmen.
			cmp	#$a0
			bne	:108
			lda	#$00
::108			sta	(r14L),y
			inx
			iny
			cpy	#$10
			bne	:107

			AddVBW	16,r14
			AddVBW	2 ,r15
			inc	r13H
			CmpB	r13H,255		;Tabelle voll ?
			beq	:110			;Ja, Ende...

::109			inc	r13L
			CmpBI	r13L,8			;Alle Einträge geprüft ?
			bne	:106			;Nein, weiter...
			ldx	diskBlkBuf+1		;Nächsten DIR-Sektor lesen...
			lda	diskBlkBuf+0		;Ende erreicht ?
			beq	:110			;Ja, Ende...
			jmp	:104			;Nein, weiter...

::110			jsr	ClrBox
			lda	r13H
			rts
;*** Alle Dateien löschen.
:DelAllFiles		jsr	GetDirHead		;BAM einlesen.

			lda	curDirHead+0		;Zeiger auf ersten DIR-Sektor...
			ldx	curDirHead+1
::101			sta	a0L
			stx	a0H
			sta	r1L
			stx	r1H
			LoadW	r4,TempDataBuf		;DIR-Sektor einlesen...
			jsr	GetBlock
			txa
			beq	:103
::102			jmp	DiskError		;Diskettenfehler.

::103			lda	#$00			;Zeiger auf ersten Eintrag.
			sta	r13L
::104			jsr	GetFileTyp
			ldy	TempDataBuf+2,x		;Datei = $00 ?
			beq	:106			;Ja, übergehen...

			pha
			ldy	#$00			;Eintrag in Zwischenspeicher.
::105			lda	TempDataBuf+2,x
			sta	dirEntryBuf ,y
			inx
			iny
			cpy	#$1e
			bne	:105
			pla
			tax
			lda	#$00			;Dateityp-Byte löschen...
			sta	TempDataBuf+2,x

			LoadW	r9,dirEntryBuf
			jsr	FreeFile
			txa
			bne	:102

::106			inc	r13L			;Zeiger auf nächsten Eintrag.
			CmpBI	r13L,8			;Alle Einträge geprüft ?
			beq	:107
			jmp	:104			;Nein, weiter...

::107			MoveW	a0,r1
			LoadW	r4,TempDataBuf		;Sektor zurückschreiben.
			jsr	PutBlock
			txa
			bne	:102

			ldx	TempDataBuf+1		;Zeiger auf nächsten DIR-Sektor.
			lda	TempDataBuf+0		;Ende erreicht ?
			beq	:108			;Ja, Ende...
			jmp	:101			;Nein, weiter...
::108			rts				;"OK"....

;*** Datei schon vorhanden ?
:IsDirOnDsk		jsr	GetDirHead		;BAM einlesen.

			lda	curDirHead+0		;Zeiger auf ersten DIR-Sektor...
			ldx	curDirHead+1
::101			sta	r1L
			stx	r1H
			LoadW	r4,diskBlkBuf		;DIR-Sektor einlesen...
			jsr	GetBlock
			txa
			beq	:102
			jmp	DiskError		;Diskettenfehler.

::102			lda	#$00			;Zeiger auf ersten Eintrag.
			sta	r13L
::103			jsr	GetFileTyp
			lda	diskBlkBuf+2,x		;Datei = $00 ?
			beq	:107			;Ja, übergehen...

			lda	diskBlkBuf+3,x		;Zeiger auf Verzeichnis-Header
			sta	r11L			;zwischenspeichern.
			lda	diskBlkBuf+4,x
			sta	r11H

			ldy	#$00
::104			lda	diskBlkBuf+5,x		;Dateiname in Zwischenspeicher...
			cmp	#$a0
			bne	:105
			lda	#$00
::105			sta	V403e2,y
			inx
			iny
			cpy	#$10
			bne	:104

			ldy	#$00
::106			lda	V403e1,y		;Dateinamen vergleichen...
			cmp	V403e2,y
			bne	:107
			iny
			cpy	#16
			bne	:106
			jmp	:108			;Übereinstimmung, Fehler...

::107			inc	r13L			;Zeiger auf nächsten Eintrag.
			CmpBI	r13L,8			;Alle Einträge geprüft ?
			bne	:103			;Nein, weiter...

			ldx	diskBlkBuf+1		;Zeiger auf nächsten DIR-Sektor.
			lda	diskBlkBuf+0		;Ende erreicht ?
			beq	:109			;Ja, Ende...
			jmp	:101			;Nein, weiter...

::108			lda	#$ff			;"Verzeichnis vorhanden"...
::109			rts

;*** Variablen
if Sprache = Deutsch
:V403a2			b PLAINTEXT,"Verzeichnisname",PLAINTEXT,NULL
endif

if Sprache = Englisch
:V403a2			b PLAINTEXT,"Name of directory",PLAINTEXT,NULL
endif

:V403b0			b $00				;Partitions-Nummer.
:V403b1			s $04				;CMD-Laufwerke.
:V403b2			b $00				;Anzahl Laufwerke in Tabelle.

;*** Auswahlbox für Partitionen.
:V403c0			b $64
			b $00
			b $00
			b $10
			b $00
			w Titel_Part
			w FileNTab

;*** Auswahlbox für Zielverzeichnis.
:V403c1			b $ff
			b $00
			b $00
			b $10
			b $00
			w Titel_SDir
			w FileNTab

;*** Auswahlbox für SD-Images.
:V403c2			b $64
			b $00
			b $00
			b $10
:V403c2a		b $02
			w V403l2
			w FileNTab

;*** Dateibrowser für DiskImage.
:V403c3			b $64
			b $00
			b $00
			b $10
:V403c3a		b $02
			w V403l4
			w FileNTab

;*** Variablen & Texte...
:V403d0			b ".               "
			b "..              "
:V403d1			b $00
:V403d2			w $0000
:V403d3			b "CD:"
			s 17
:V403d4			w $0000
:V403d5			b "MD:"
			s 17
:V403d6			w $0003
			b "CD",$5f
:V403d7			w $0004
			b "CD//"
:V403d8			w $0003
			b "I0:"

:V403e0			s 17
:V403e1			s 17
:V403e2			s 17

;*** Variablen für neue MDir-Routine.
:NewDirHd		b $00,$00
:NewDirSk		b $00,$00
:DirEntry		b $00,$00,$00

;*** Variablen für SD-Image-Wechsel.
:DirListMode		b $00
:V403k0			b $00,$00
:V403k1			b "$:*D64=P",NULL
:V403k2			b "$:*=B",NULL
:V403k3			b "??647181NP??????"
:V403k4			b "$:1234567890123456=B",NULL
:V403k5			w $0000
			b "CD:"
			s 17
:V403k6			b "$",NULL

;*** Texte für Dateiauswahlbox.
if Sprache = Deutsch
:V403l1			b "<=        (ROOT)"
			b "..      (ZURÜCK)"
:V403l2			b PLAINTEXT,"DiskImage wählen",NULL
:V403l3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "DiskImages auf SD-"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Karte einlesen..."
			b NULL
:V403l4			b "Inhalt: "
:V403l4a		s 17
endif
if Sprache = Englisch
:V403l1			b "<=        (ROOT)"
			b "..          (UP)"
:V403l2			b PLAINTEXT,"Select DiskImage",NULL
:V403l3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Reading disk images"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "on SD card..."
			b NULL
:V403l4			b "Content: "
:V403l4a		s 17
endif

if Sprache = Deutsch
:V403m0			w V403m1,V403m2,ISet_Achtung
:V403m1			b BOLDON,"Kein DiskImage auf",NULL
:V403m2			b        "Laufwerk "
:V403m1a		b        "A: ausgewählt !",NULL
endif
if Sprache = Englisch
:V403m0			w V403m1,V403m2,ISet_Achtung
:V403m1			b BOLDON,"No disk-image",NULL
:V403m2			b        "selected on drive "
:V403m1a		b        "A: !",NULL
endif

if Sprache = Deutsch
;*** Infotexte.
:V403f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Dateien werden"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "gelöscht...",NULL

:V403f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "gelöscht...",NULL

:V403f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnis wird"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "angelegt...",NULL

:V403f3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Verzeichnisstruktur"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "wird überprüft...",NULL

:V403f4			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Suche weitere"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "Unterverzeichnisse...",NULL
endif

if Sprache = Englisch
;*** Infotexte.
:V403f0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Deleting selected"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "files...",NULL

:V403f1			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Deleting selected"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory...",NULL

:V403f2			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Creating selected"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory...",NULL

:V403f3			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Analayzing"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "directory...",NULL

:V403f4			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Searching for"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "subdirectories...",NULL
endif

if Sprache = Deutsch
;*** Fehler: "Laufwerk nicht partitioniert..."
:V403g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Laufwerk x: ist nicht",NULL
::102			b        "partitioniert !",NULL

;*** Fehler: "Kein CMD-Laufwerk gefunden..."
:V403g1			w :101, :102, ISet_Achtung
::101			b BOLDON,"Kein CMD/SD2IEC Laufwerk",NULL
::102			b        "mit Partitionen verfügbar !",NULL

;*** Fehler: "Dateiname bereits vergeben!"
:V403g2			w :101, :102, ISet_Achtung
::101			b BOLDON,"Dieser Dateiname ist",NULL
::102			b        "bereits vergeben !",NULL

;*** Fehler: "Kann Verzeichnis nicht anlegen!"
:V403g3			w :101, :102, ISet_Achtung
::101			b BOLDON,"Das Verzeichnis konnte",NULL
::102			b        "nicht angelegt werden!",NULL

;*** Fehler: "Diskette hat keine Unterverzeichnisse !"
:V403g4			w :101, :102, ISet_Achtung
::101			b BOLDON,"Diese Diskette hat keine",NULL
::102			b        "Unterverzeichnisse!",NULL

;*** Fehler: "Zuerst Verzeichnisse löschen!"
:V403g5			w :101, :102, ISet_Achtung
::101			b BOLDON,"Bitte löschen Sie zuerst",NULL
::102			b        "alle Unterverzeichnisse!",NULL

;*** Fehler: "Hauptverzeichnis kann nicht gelöscht werden!"
:V403g6			w :101, :102, ISet_Achtung
::101			b BOLDON,"Das Hauptverzeichnis kann",NULL
::102			b        "nicht gelöscht werden !",NULL

;*** Infobox: "Weitere Verzeichnisse erstellen ?"
:V403h0			w :101, :102,ISet_Frage
			b NO,YES
::101			b BOLDON,"Möchten Sie ein weiteres",NULL
::102			b        "Unterverzeichnis erstellen ?",NULL

;*** Infobox: "Alle Dateien löschen ?"
:V403h1			w :101, :102,ISet_Frage
			b NO,YES
::101			b BOLDON,"Verzeichnis ist nicht leer!",NULL
::102			b        "Alle Dateien löschen ?",NULL
endif

if Sprache = Englisch
;*** Fehler: "Laufwerk nicht partitioniert..."
:V403g0			w :101, :102, ISet_Achtung
::101			b BOLDON,"Drive    x:",NULL
::102			b        "No partitions found!",NULL

;*** Fehler: "Kein CMD-Laufwerk gefunden..."
:V403g1			w :101, :102, ISet_Achtung
::101			b BOLDON,"No CMD/SD2IEC drive with",NULL
::102			b        "partitions found !",NULL

;*** Fehler: "Dateiname bereits vergeben!"
:V403g2			w :101, :102, ISet_Achtung
::101			b BOLDON,"Filename already",NULL
::102			b        "exist on disk !",NULL

;*** Fehler: "Kann Verzeichnis nicht anlegen!"
:V403g3			w :101, :102, ISet_Achtung
::101			b BOLDON,"Cannot create",NULL
::102			b        "selected directory!",NULL

;*** Fehler: "Diskette hat keine Unterverzeichnisse !"
:V403g4			w :101, :102, ISet_Achtung
::101			b BOLDON,"No subdirectories",NULL
::102			b        "found on disk!",NULL

;*** Fehler: "Zuerst Verzeichnisse löschen!"
:V403g5			w :101, :102, ISet_Achtung
::101			b BOLDON,"Please delete all sub-",NULL
::102			b        "directories first!",NULL

;*** Fehler: "Hauptverzeichnis kann nicht gelöscht werden!"
:V403g6			w :101, :102, ISet_Achtung
::101			b BOLDON,"Root-diirectory cannot",NULL
::102			b        "be deleted !",NULL

;*** Infobox: "Weitere Verzeichnisse erstellen ?"
:V403h0			w :101, :102,ISet_Frage
			b NO,YES
::101			b BOLDON,"Would you like to create",NULL
::102			b        "another directory ?",NULL

;*** Infobox: "Alle Dateien löschen ?"
:V403h1			w :101, :102,ISet_Frage
			b NO,YES
::101			b BOLDON,"Directory not empty!",NULL
::102			b        "Delete all files ?",NULL
endif

:EndProgrammCode

;*** Speicher für Verzeichnissektor.
;    Speicher für Verzeichnisdaten/SD2IEC.
:TempDataBuf		brk

;******************************************************************************
			e FilePTab - 16*253
;******************************************************************************
