; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Die folgenden Routinen sind nur zu Beginn verfügbar und werden im Verlauf
;*** Installation überschrieben.
;******************************************************************************
;*** Benutzerkonfiguration einlesen.
:GetUpdateConfig	LoadW	r6,FNamMPUPD
			jsr	FindFile		;Datei "GEOS64.MP3" suchen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			jmp	Err_DiskError		;Fehlermeldung ausgeben.

::52			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	fileHeader +160		;Parameter einlesen.
			sta	UserTools  +  0
			lda	fileHeader +161
			sta	UserTools  +  1

;--- Ergänzung: 05.09.18/M.Kanet
;Bisher wurde nach dem ersten Start von GEOS.MP3 die Funktion
;"GEOS.MakeBoot ausführen" abgeschaltet.
;Diese Funktion war ursprünglich während der Entwicklung von MP eingeführt
;worden um ohne den GEOS.Editor und MakeBoot eine neue Testversion von MP
;im laufenden GEOS zu installieren ohne einen Neustart ausführen zu müssen.
;Die Bytes #1 und #2 im Infoblock können auch weiterhin manuell angepasst
;werden, aber für das nächste Stable-Release ist diese Funktion nicht mehr
;automatisch erforderlich, da vom Anwender nicht erwartet.
			rts

;			lda	#"-"			;MakeBoot-Flag löschen.
;			sta	fileHeader +161

;			lda	dirEntryBuf+ 19		;Infoblock aktualisieren.
;			sta	r1L
;			lda	dirEntryBuf+ 20
;			sta	r1H
;			LoadW	r4,fileHeader
;			jmp	PutBlock

;*** Auf MP3-Laufwerkstreiber testen: Für Update aus MP3 heraus.
:ChkMP3DskDrv		ldx	#$04
::1			lda	:10,x
			cmp	DiskDrvTypeCode,x
			bne	:2
			dex
			bpl	:1
			ldx	#NO_ERROR
			b $2c
::2			ldx	#DEV_NOT_FOUND
			rts

::10			b "MPDD3"

;*** Aktuelle Laufwerks-Konfiguration einlesen.
:Get_UserConfig		ldy	#$03
			lda	#$00
::10			sta	UserConfig  ,y		;Laufwerkstyp löschen.
			sta	UserPConfig ,y		;Partitions-Nr. löschen.
			sta	UserRamBase ,y		;RAM-Adresse löschen.
			dey
			bpl	:10

			ldx	#8
::driveloop		stx	DetectCurDrive
			lda	driveType   -8,x	;Laufwerk definiert ?
			bne	:testmp3drv		; => Ja, weiter.
::exit			rts				;$00 = Letztes Laufwerk.

;--- Auf GEOS/MP3-Laufwerkstyp einlesen.
::testmp3drv		jsr	ChkMP3DskDrv		;Laufwerkstreiber testen.
			txa				;MegaPatch-Laufwerkstreiber?
			bne	:testdrive		; => Nein, weiter...

			ldx	DetectCurDrive
			lda	RealDrvType -8,x	;MP3-Laufwerkstyp merken.
			bne	:initdevice

::testdrive		ldx	DetectCurDrive
			lda	driveType   -8,x	;GEOS-Laufwerktyp merken.

;--- Laufwerk aktivieren.
::initdevice		pha
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			pla
			cpx	#NO_ERROR 		;Fehler ?
			bne	:nextdrive		; => Ja, weiter...

			ldx	DetectCurDrive
			sta	UserConfig  -8,x	;Laufwerkstyp speichern.

;--- Erkennung Hardware- oder RAM-Laufwerk.
			lda	curType			;Aktuellen Laufwerktyp einlesen.
			bmi	:getramtype		; => RAM-Laufwerk, weiter....

;--- Erkennung der Geräte am ser. Bus.
;    Achtung! Unter gateWay wird hier die RAMLink als Laufwerk mit
;    fester Adresse von #8 bis #11 erkannt. Für GEOSV2 kann die
;    RL-Adresse über die Variable ":DevAdr_RL" ermittelt werden.
;			ldx	DetectCurDrive
			lda	DriveInfoTab-8,x	;Laufwerke stehen jetzt ab
			and	#%11110000		;":DriveInfoTab".
			sta	r0L			;CMD-Laufwerksformat ermitteln
			lda	driveType   -8,x	;und zwischenspeichern.
			and	#%00001111
			ora	r0L
			sta	UserConfig  -8,x

			and	#%11110000
			cmp	#DrvRAMLink		;Laufwerk vom Typ RAMLink?
			bne	:nextdrive		; => Nein, weiter...

;--- Ab hier Unterscheidung RAMxy oder RLxy.
;    Bei RLxy wird die aktive Partition erkannt.
::getramtype		lda	Device_RL		;RAMLink verfügbar ?
			beq	:getramconf		; => Nein, RAMxy-Laufwerk...

;--- Ergänzung: 19.10.2018/M.Kanet
;Zuerst auf RAMLink-Partition testen. Falls keine RL-Partition dann
;weiter mit auswerten eines RAM-Laufwerks.
			lda	DetectCurDrive		;Laufwerksadresse übergeben und
			jsr	FindPartition		;Partition auf RAMLink suchen.
			txa				;Laufwerk = RAMLink-Partition ?
			bne	:getramconf		; => Nein, weiter...

;--- RAMLink-Laufwerk.
::getrlconf		ldx	DetectCurDrive		;Laufwerksadresse einlesen.
			tya				;Aktuelles Laufwerk ist RAMLink-
			sta	UserPConfig  -8,x	;Partition. Informationen für
			lda	curType			;Update-Routine aktualisieren.
			and	#%00001111
			ora	#DrvRAMLink
			sta	UserConfig   -8,x
			bne	:nextdrive

;--- RAM-Laufwerk.
::getramconf		ldx	DetectCurDrive		;Auf RAMNative-Laufwerk testen.
			lda	UserConfig   -8,x
;--- Ergänzung: 06.08.18/M.Kanet
;Sonderbehandlung falls Installation innerhalb von MegaPatch:
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU nutzen die
;Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
			and	#%10001111		;Bits für Extended-RAM-Laufwerke
							;ausblenden.
			cmp	#DrvRAMNM
			bne	:nextdrive		; => Kein RAMNative, weiter...
			lda	ramBase      -8,x	;Bei RAMNative auch die Startadr.
			sta	UserRamBase  -8,x	;im Speicher merken und als Vorgabe
							;für Laufwerksinstallation nutzen.

;--- Nächstes Laufwerk.
::nextdrive		ldx	DetectCurDrive
			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getestet ?
			bcs	:alldone		; => Ja, Ende...
			jmp	:driveloop		; => Nein, weiter testen...
::alldone		rts

;*** RAMLink suchen und Geräteadresse ermitteln.
:FindRAMLinkAdr		ldx	Device_RL		;RAMLink-Flag speichern.
			beq	:53

			lda	#$08
::51			tax
			ldy	DriveInfoTab -8,x	;Laufwerke stehen jetzt ab
			cpy	#DrvRAMLink		;":DriveInfoTab"
			beq	:54
::52			clc
			adc	#$01			;Zeiger auf nächstes laufwerk.
			cmp	#30			;Alle Laufwerke getestet ?
			bcc	:51			; => Nein, weiter...

::53			lda	#$00			;Keine RAMLink...
			sta	DevAdr_RL
			ldx	#DEV_NOT_FOUND
			rts

::54			sta	DevAdr_RL
			ldx	#NO_ERROR
			rts

;*** Aktive Partition suchen.
;    Übergabe:		AKKU = GEOS-Laufwerk.
;******************************************************************************
;    Die Entscheidung ob das aktuelle Laufwerk eine RAM-Disk oder eine
;    RL-Partition ist, kann nicht über den ":ramExpSize"-Vergleich festgestellt
;    werden. Grund: Ist der GEOS-DACC Teil der RAMCard, dann kann die Start-
;    adresse der aktuellen RL-Partition kleiner sein als die Größe des DACC.
;    Somit ist eine sichere Erkennung nicht möglich.
;******************************************************************************
:FindPartition		jsr	SetDevice		;Laufwerk aktivieren.
			txa
			bne	:51
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			ldx	#DEV_NOT_FOUND
			rts

::52			lda	#$01			;Zeiger auf erste Partition.
			sta	r3H

::53
if Flag64_128 = TRUE_C128
			LoadB	r15L,%01001110		;MMU-Wert für RAMLink-Transfer.
endif
			jsr	GetRLPartEntry		;Partitionsdaten einlesen.

			lda	dirEntryBuf +0		;Partitionstyp vergleichen.
			eor	curType
			and	#%00001111
			bne	:55			; => Falsches Partitionsformat.

			lda	#$08			;Testsektor. Darf nicht $01,$01
			sta	r1L			;sein, da auf RAMLink geschützt ist!
			sta	r1H			;(Native wird dann nicht erkannt)
			LoadW	r4 ,diskBlkBuf
			jsr	GetBlock		;Testsektor einlesen.
			txa				;Diskettenfehler ?
			bne	:55			; => Ja, Abbruch...

if Flag64_128 = TRUE_C128
			LoadB	r15L,%01001110		;MMU-Wert für RAMLink-Transfer.
endif
			jsr	RL_VerBlock		;RAMLink-Sektor vergleichen.
			txa				;Stimmt Sektor ?
			bne	:55			; => Nein, Abbruch...

			lda	diskBlkBuf + 0		;Sicherheitstest.
			eor	#$ff			;Ein Byte in aktuellem Sektor
			sta	diskBlkBuf + 0		;ändern und in RAMDisk schreiben.
			jsr	PutBlock
			txa
			bne	:54

if Flag64_128 = TRUE_C128
			LoadB	r15L,%01001110		;MMU-Wert für RAMLink-Transfer.
endif
			jsr	RL_VerBlock		;Sektor aus aktuellem Laufwerk mit
			txa				;Sektor in RAMLink-Partition
::54			pha				;vergleichen.
			lda	diskBlkBuf + 0
			eor	#$ff
			sta	diskBlkBuf + 0
			jsr	PutBlock
			pla				;Stimmt Sektor ?
			bne	:55			; => Nein, RAMDisk...

			ldx	#NO_ERROR
			ldy	r3H			;Partition übergeben.
			rts

::55			inc	r3H			;Zeiger auf nächste Partition.
			CmpBI	r3H,32			;Alle Partitionen geprüft ?
			bcc	:53			;Nein, weiter...

			ldx	#DEV_NOT_FOUND		;Laufwerk => RAMDisk.
			rts

;*** Boot-Partition auf RAMLink aktivieren.
;    Auf HD/FD nicht notwendig, da hier keine andere Partition aktiv sein kann,
;    als die von der MP3 gestartet wurde!
:OpenBootPart		lda	Device_Boot		;Startlaufwerk aktivieren.
			jsr	SetDevice
			txa
			bne	:54

			ldy	curDrive
			lda	UserConfig  -8,y	;Ist Startlaufwerk eine RAMLink ?
			and	#%11110000
			cmp	#DrvRAMLink
			bne	:54			; => Keine RAMLink, Ende...

			lda	UserPConfig -8,y	; => Nein, Ende...
			sta	com_CP +2		;Partitions-Nr. speichern.

			jsr	ExitTurbo
			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	#$00			;Status-Byte löschen.
			sta	STATUS
			jsr	$ffab
			bit	STATUS			;Fehler aufgetreten ?
			bmi	:52			;Ja, Abbruch...

			lda	DevAdr_RL
			jsr	$ffb1			;Laufwerk aktivieren.
			bit	STATUS			;Fehler aufgetreten ?
			bmi	:52			;Ja, Abbruch...

			lda	#$ff
			jsr	$ff93			;Laufwerk auf Empfang schalten.
			bit	STATUS			;Fehler aufgetreten ?
			bmi	:52			;Ja, Abbruch...

			ldy	#$00
::51			lda	com_CP,y		;Kommando-Befehl an Floppy senden.
			jsr	$ffa8
			iny
			cpy	#$04
			bcc	:51

			jsr	$ffae			;Laufwerk abschalten.

			ldx	#$00
			jmp	DoneWithIO

::52			jsr	$ffae			;Laufwerk abschalten.
			jsr	DoneWithIO
::53			ldx	#DEV_NOT_FOUND
::54			rts

:com_CP			b $43,$d0,$00,CR,NULL

;*** Farbe für Icons bereitstellen.
:SetColIcon1
if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			LoadW	r3,(4*8) *2
			LoadW	r4,((4*8 + 6*8) *2) -1
			LoadB	r2L,16*8
			LoadB	r2H,16*8+2*8-1
			lda	#$0f
			jmp	ColorRectangle		;GEOS 2.0 DirectColor-Routine !
endif

::40			ldy	#$05
			lda	#$01
::51			sta	COLOR_MATRIX + 16*40 + 4,y
			sta	COLOR_MATRIX + 17*40 + 4,y
			dey
			bpl	:51
			rts

:SetColIcon2
if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			LoadW	r3,(30*8) *2
			LoadW	r4,((30*8 + 6*8) *2) -1
			LoadB	r2L,16*8
			LoadB	r2H,16*8+2*8-1
			lda	#$0f
			jmp	ColorRectangle		;GEOS 2.0 DirectColor-Routine !
endif

::40			ldy	#$05
			lda	#$01
::51			sta	COLOR_MATRIX + 16*40 +30,y
			sta	COLOR_MATRIX + 17*40 +30,y
			dey
			bpl	:51
			rts

;*** Dialogbox mit Icons zeichnen.
:Col2IconDlgBox		jsr	SetColIcon2
:Col1IconDlgBox		jsr	SetColIcon1
			jsr	DoDlgBox

if Flag64_128 = TRUE_C128
			bit	graphMode
			bpl	:40
			LoadW	r3,0
			LoadW	r4,639
			LoadB	r2L,16
			LoadB	r2H,159
			lda	#$07
			jmp	ColorRectangle		;GEOS 2.0 DirectColor-Routine !
endif

::40			jsr	i_FillRam
			w	19*40
			w	COLOR_MATRIX + 02*40
			b	$03
			rts
