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
:GetUpdateConfig	LoadW	r6,FNamGDUPD
			jsr	FindFile		;Datei "GD.UPDATE" suchen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			jmp	Err_DiskError		;Fehlermeldung ausgeben.

::52			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			lda	fileHeader +160		;Parameter einlesen.
			sta	UserTools  +  0
if GD_NG_MODE = FALSE
			lda	fileHeader +161
			sta	UserTools  +  1
endif

;--- Ergänzung: 05.09.18/M.Kanet
;Bisher wurde nach dem ersten Start von GD.UPDATE die Funktion
;"GEOS.MakeBoot ausführen" abgeschaltet.
;Diese Funktion war ursprünglich während der Entwicklung von MP3 eingeführt
;worden um ohne den GEOS.Editor und MakeBoot eine neue Testversion von MP3
;im laufenden GEOS zu installieren ohne einen Neustart ausführen zu müssen.
;Die Bytes #1 und #2 im Infoblock können auch weiterhin manuell angepasst
;werden, aber für das nächste Stable-Release ist diese Funktion nicht mehr
;automatisch erforderlich, da vom Anwender nicht erwartet.

;--- Ergänzung: 03.03.21/M.Kanet
;Änderung rückgängig gemacht.
;Sinn und Zweck von "GD.UPDATE" ist es nach der Installation über "GD.SETUP"
;die Startdiskette bootfähig zu machen. Das ist nur 1x erforderlich.
;Danach sollte das Programm nur noch dazu genutzt werden um in einem laufenden
;GEOS2-System auf GD3 zu wechseln.

if GD_NG_MODE = FALSE
			lda	#"-"			;MakeBoot-Flag löschen.
			sta	fileHeader +161

			lda	dirEntryBuf+ 19		;Infoblock aktualisieren.
			sta	r1L
			lda	dirEntryBuf+ 20
			sta	r1H
			LoadW	r4,fileHeader
			jsr	PutBlock
endif

			rts

;*** Auf GD3-Laufwerkstreiber testen: Für Update aus GD3 heraus.
:ChkGD3DskDrv		ldx	#$04
::1			lda	:drvTypeCode,x
			cmp	diskDrvRelease,x
			bne	:2
			dex
			bpl	:1

			ldx	#NO_ERROR
			b $2c
::2			ldx	#DEV_NOT_FOUND
			rts

;--- Ergänzung: 07.02.21/M.Kanet
;GD3 verwendet aus Kompatibilitätsgründen die gleiche
;Laufwerkskennung wie GEOS/MegaPatch.
::drvTypeCode		b "MPDD3"

;*** Aktuelle Laufwerks-Konfiguration einlesen.
:Get_UserConfig		ldy	#$03
			lda	#$00
::10			sta	UserConfig  ,y		;Laufwerkstyp löschen.
			sta	UserPConfig ,y		;Partitions-Nr. löschen.
			sta	UserRamBase ,y		;RAM-Adresse löschen.
			dey
			bpl	:10

			ldx	#8
::driveloop		stx	detectDrvAdr

;--- Diskettenlaufwerk. Beim Start von GD.CONFIG hier das aktuelle
;    Laufwerk am ser. Bus installieren.
			lda	driveType   -8,x	;Laufwerk definiert ?
			bne	:testgd3drv 		; => Ja, weiter.
::exit			rts				;$00 = Letztes Laufwerk.

;--- Auf GEOS/GD3-Laufwerk testen.
::testgd3drv		jsr	ChkGD3DskDrv		;Laufwerkstreiber testen.
			txa				;MegaPatch-Laufwerkstreiber?
			bne	:testdrive		; => Nein, weiter...

			ldx	detectDrvAdr
			lda	RealDrvType  -8,x	;MP3-Laufwerkstyp merken.
			bne	:initdevice

::testdrive		ldx	detectDrvAdr
			lda	driveType    -8,x	;GEOS-Laufwerkstyp einlesen.

;--- Laufwerk aktivieren.
::initdevice		pha
			txa
			jsr	SetDevice		;Laufwerk aktivieren.
			pla
			cpx	#NO_ERROR		;Fehler ?
			bne	:nextdrive		; => Ja, weiter...

			ldx	detectDrvAdr
			sta	UserConfig   -8,x	;Laufwerkstyp speichern.

;--- Erkennung Hardware oder RAM-Laufwerk.
			lda	curType			;Aktuellen Laufwerkstyp einlesen.
			bmi	:getramtype		; => RAM-Laufwerk, weiter....

;--- Erkennung der Geräte am ser. Bus.
;    Achtung! Unter gateWay wird hier die RAMLink als Laufwerk mit
;    fester Adresse von #8 bis #11 erkannt. Für GEOSV2 kann die
;    RL-Adresse über die Variable ":DevAdr_RL" ermittelt werden.
;			ldx	detectDrvAdr
			lda	sysDevInfo   -8,x	;Laufwerke stehen ab ":sysDevInfo".
;--- Hinweis:
;In ":sysDevInfo" ist für SD2IEC-Laufwerke
;das Bit#6 durch ":DetectDrive" gesetzt!
			and	#DrvCMD			;CMD/SD2IEC-Laufwerksformat
			sta	r0L			;ermitteln und zwischenspeichern.
			ldx	detectDrvAdr
			lda	driveType    -8,x
			and	#%00001111
			ora	r0L
			sta	UserConfig   -8,x

			and	#%11110000
			cmp	#DrvRAMLink		;Laufwerk vom Typ RAMLink?
			bne	:nextdrive

;--- Ab hier Unterscheidung RAMxy oder RLxy.
;    Bei RLxy wird die aktive Partition erkannt.
::getramtype		lda	Device_RL		;RAMLink verfügbar ?
			beq	:getramconf		; => Nein, RAMxy-Laufwerk...

;--- Ergänzung: 19.10.18/M.Kanet
;Zuerst auf RAMLink-Partition testen. Falls keine RL-partition dann
;weiter mit auswerten eines RAM-Laufwerks.
			lda	detectDrvAdr		;Laufwerksadresse übergeben und
			jsr	FindPartition		;Partition auf RAMLink suchen.
			txa				;Laufwerk = RAMLink-Partition ?
			bne	:getramconf		; => Nein, weiter...

;--- RAMLink-Laufwerk.
::getrlconf		ldx	detectDrvAdr		;Laufwerksadresse einlesen.
			tya				;Aktuelles Laufwerk ist RAMLink-
			sta	UserPConfig  -8,x	;Partition. Informationen für
			lda	curType			;Update-Routine aktualisieren.
			and	#%00001111
			ora	#DrvRAMLink
			sta	UserConfig   -8,x
			bne	:nextdrive

;--- RAM-Laufwerk.
::getramconf		ldx	detectDrvAdr		;Auf RAMnative-Laufwerk testen.
			lda	UserConfig   -8,x
;--- Ergänzung; 06.08.18/M.Kanet
;Sonderbehandlung falls Installation innerhalb von GD3:
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und RAMCard/SuperCPU nutzen
;die Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
			and	#%10001111		;Bits für Extended-RAM-Laufwerke
							;ausblenden.
			cmp	#DrvRAMNM
			bne	:nextdrive		; => Kein RAMNative, weiter...
			lda	ramBase      -8,x	;Bei RAMNative auch die Startadr.
			sta	UserRamBase  -8,x	;im Speicher merken und als Vorgabe
							;für Laufwerksinstallation nutzen.

;--- Nächstes Laufwerk.
::nextdrive		ldx	detectDrvAdr
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
			ldy	sysDevInfo -8,x		;Laufwerke stehen jetzt ab
			cpy	#DrvRAMLink		;":sysDevInfo"
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
:FindPartition		jsr	SetDevice		;Laufwerk aktivieren
			txa				;Laufwerksfehle?
			bne	:51			; => Ja, Abbruch...
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			beq	:52			; => Nein, weiter...
::51			ldx	#DEV_NOT_FOUND
			rts

::52			lda	#$01			;Zeiger auf erste Partition.
			sta	r3H

::53			jsr	GetRLPartEntry		;Partitionsdaten einlesen.

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

			jsr	RL_VerBlock		;RAMLink-Sektor vergleichen.
			txa				;Stimmt Sektor ?
			bne	:55			; => Nein, Abbruch...

			lda	diskBlkBuf + 0		;Sicherheitstest.
			eor	#$ff			;Ein Byte in aktuellem Sektor
			sta	diskBlkBuf + 0		;ändern und in RAMDisk schreiben.
			jsr	PutBlock
			txa
			bne	:54

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
;    als die von der GD3 gestartet wurde!
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
:SetColIcon1		ldy	#$05
			lda	#$01
::51			sta	COLOR_MATRIX +40 * 16 + 4,y
			sta	COLOR_MATRIX +40 * 17 + 4,y
			dey
			bpl	:51
			rts

:SetColIcon2		ldy	#$05
			lda	#$01
::51			sta	COLOR_MATRIX +40 * 16 +30,y
			sta	COLOR_MATRIX +40 * 17 +30,y
			dey
			bpl	:51
			rts

;*** Systemfehler.
:SysErrColor		jsr	i_FillRam		;Farbe löschen.
			w	40 * 25
			w	COLOR_MATRIX
			b	$00

			lda	#$00			;Grafik löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

;*** Dialogbox ohne Icons zeichnen.
:DlgBoxColor		jsr	i_FillRam
			w	40 * 19
			w	COLOR_MATRIX +40 * 2
			b	COLOR_MENU_AREA
			rts

;*** Dialogbox mit Icons zeichnen.
:DlgBoxColor1		jsr	DlgBoxColor
			jmp	SetColIcon1

:DlgBoxColor2		jsr	DlgBoxColor
			jsr	SetColIcon1
			jmp	SetColIcon2

;*** Systemvariablen.
:detectDrvAdr		b $00
