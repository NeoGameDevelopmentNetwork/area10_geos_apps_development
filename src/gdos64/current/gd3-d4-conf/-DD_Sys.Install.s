; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Installation als Anwendung.
:_DRV_APPINSTALL	lda	bootName +1		;GDOS-Kernal aktiv ?
			cmp	#"D"			;"GDOS64-V3"
			bne	:exit			; => Nein, Abbruch...
			lda	bootName +7
			cmp	#"V"
			beq	:start			; => Ja, weiter...

if FALSE
			lda	MP3_CODE +0		;Kennung für GDOS.
			cmp	#"M"			;GEOS-Update installiert ?
			bne	:exit			; => Nein, Ende...
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:exit

;--- Ergänzung: 14.03.21/M.Kanet
;Unter GEOS/MegaPatch ist die Routine
;":InitForDskDvJob" an einer anderen
;Stelle im Kernal.
			lda	InitForDskDvJob
			cmp	#$ac			;LDY-Befehl ?
			beq	:start			; => Ja, weiter...
;---
endif

::exit			jmp	EnterDeskTop		;Kein GDOS64, Ende...

;--- Initialisierung.
::start			jsr	GetBackScreen		;Hintergrundbild laden.

			jsr	SaveDrvAppName		;Name Treiberdatei speichern.

;--- DiskCore nachladen.
			LoadW	r0,BASE_DDRV_CORE
			LoadW	r1,R2A_DDRVCORE
			LoadW	r2,R2S_DDRVCORE
			lda	MP3_64K_SYSTEM
			sta	r3L
			jsr	FetchRAM		;DiskCore einlesen.

			lda	BASE_DDRV_CORE +4	;Version von DiskCore
			cmp	#DISKCORE_VER_HI	;überprüfen.
			bne	:exit
			lda	BASE_DDRV_CORE +5
			cmp	#DISKCORE_VER_LO
			bne	:exit			; => Versionsfehler, Abbruch...

;*** Installation als Anwendung.
			lda	#$00			; Modus -> Anwendung.
			b $2c

;*** Installation über GD.CONFIG.
:_DRV_CFGINSTALL	lda	#$ff			; Modus -> GD.CONFIG.
			sta	DEV_INSTALL_MODE	;Installationsmodus speichern.

			lda	#FALSE			;Treiber-Einstellungen nicht
			sta	flgUpdDDrvFile		;aktualisieren.

;--- GEOS-Adresse wählen.
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:prepare		; => Ja, weiter...

			bit	DEV_INSTALL_MODE	;Aufruf aus GD.CONFIG ?
			bmi	:prepare		; => Ja, weiter...

if EN_TEST_EXTRAM = TRUE
			jsr	initTestExtRAM

			tya				;Ziel-Laufwerk.
			cpx	#NO_ERROR		;Fehler ?
			beq	:setadr			; => Nein, Adresse wählen...
			cpx	#CANCEL_ERR		;Laufwerk bereits vorhanden ?
			beq	:slctadr		; => Nein, weiter...
			jmp	:cancel			; => Ja, Abbruch...
endif

::slctadr		LoadW	r5,DrvName
			jsr	_DDC_SLCTGEOSADR	;GEOS-Laufwerksadresse wählen.
			cpx	#NO_ERROR		;Abbruch ?
			bne	:error			; => Ja, Ende...

::setadr		sta	DrvAdrGEOS		;GEOS-Adresse speichern.

;--- Laufwerkstreiber zwischenspeichern.
::prepare		tay
;			ldy	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	_DDC_DRVBACKUP		;Aktuellen Treiber sichern.

;--- Aktuellen Treiber deinstallieren.
			ldx	DrvAdrGEOS
			lda	driveType -8,x		;Laufwerk installiert ?
			beq	:init			; => Nein, Ende...

			ldy	#$00			;Vorgabe für ":ramBase".
;			ldx	DrvAdrGEOS
;			lda	driveType -8,x		;Laufwerkstyp einlesen.
			and	#%10000000		;RAM-Laufwerk ?
			beq	:1			; => Nein, weiter...

			lda	DrvMode			;RAM-Laufwerk installieren ?
			bpl	:1			; => Nein, weiter...
;			ldx	DrvAdrGEOS
			ldy	ramBase -8,x		; => Ja, ":ramBase" retten.

::1			tya				;Vorgabewert für ":ramBase"
			pha				;zwischenspeichern.

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Deinstallations-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
			jsr	PurgeTurbo		;TurboDOS entfernen.

			ldx	DrvAdrGEOS
			jsr	_DDC_DEVUNLOAD		;RAM-Speicher freigeben.
			ldx	DrvAdrGEOS
			jsr	_DDC_DEVCLRDATA		;Laufwerksdaten zurücksetzen.
;------------------------------------------------------------------------------

			pla
			ldx	DrvAdrGEOS		;":ramBase" wieder herstellen.
			sta	ramBase -8,x

;--- Ergänzung: 28.08.21/M.Kanet
;Vor dem ersten Zugriff auf die
;Laufwerksroutinen muss der passende
;Laufwerkstreiber installiert werden.
;PurgeTurbo und InitForIO können sonst
;von einem inkompatiblen Treiber aus
;aufgerufen werden.
;Beispiel ist ein Bootlaufwerk-Treiber
;für 1541/Shadow der bei PurgeTurbo das
;ShadowRAM neu initialisiert, aber für
;das neue Laufwerk evtl. kein ShadowRAM
;benötigt wird. Das führte bisher dazu
;das auf Grund von ":ramBase" = 0 die
;GEOS-Speicherbank beschädigt wird.
;InitShadowRAM löscht jeweils die Bytes
;#0/#1 jedes 256Byte-Blocks im RAM was
;in diesem Fall sämtliche Treiber im
;GEOS-DACC beschädigt hat.
;Der 1541/Shadow-Treiber wurde jetzt
;entsprechend angepasst.
;
;Der aktuelle Treiber muss auch für
;NativeRAM temporär installiert werden:
;Die NM-Treiber testen die BAM um die
;Größe eines bereits installierten
;Laufwerks auszulesen und die Größe
;für die Installation zu übernehmen.
::init			jsr	initCopyDriver		;Treiber temporär installieren.

;--- Installationsbereitschaft testen.
;C=15xx  : Kein Test.
;C=1541s : Freien Speicher suchen.
;RAMxy   : Freien Speicher suchen.
;ExtRAM  : Kein Test.
;CMD-FD  : Kein Test.
;CMD-HD  : Kein Test.
;CMD-RL  : Hardware suchen.
;SD2IEC  : Kein Test.
;PCDOS   : Freien Speicher suchen.
			jsr	initTestInstall		;Laufwerksinstallation testen.
			txa				;Kann Laufwerk installiert werden ?
			bne	:error			; => Nein, Abbruch...

;------------------------------------------------------------------------------
; DRIVECORE
;
;Vor dem Aufruf der Installations-
;routine darf auf dem aktiven Laufwerk
;das TurboDOS nicht mehr aktiv sein!
;
::install		jsr	PurgeTurbo		;TurboDOS entfernen.

;--- Hinweis:
;Nach Dialogbox "Laufwerk einschalten"
;wird ":_DDC_DETECTALL" aufgerufen.
;Dabei ist der neue Laufwerkstyp in
;":driveType" bereits temporär gesetzt.
; => ":initCopyDriver"
			ldy	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen und
			lda	#NULL			;":driveType" löschen.
			sta	driveType -8,y

			jsr	DO_DEV_INSTALL		;Laufwerk installieren.
;------------------------------------------------------------------------------
			txa	 			;Wurde Laufwerk installiert ?
			bne	:error			; => Nein, Abbruch...

;--- Diskette/Partition öffnen.
if EN_SELECT_PART
			lda	DDRV_VAR_CONF
			and	#%00100000		;Partition auswählen ?
			bne	:skip_disk		; => Nein, weiter...
			jsr	_DDC_OPENMEDIA		;Neue Partition öffnen.
			ldx	#NO_ERROR		;Kein Fehler...
			beq	:exit			; => Ende...
endif

;--- DiskImage öffnen.
if EN_SELECT_DIMG
			lda	DDRV_VAR_CONF
			and	#%00100000		;DiskImage auswählen ?
			bne	:skip_disk		; => Nein, weiter...
			jsr	_DDC_OPENMEDIA		;Neues DiskImage öffnen.
			ldx	#NO_ERROR		;Kein Fehler...
			beq	:exit			; => Ende...
endif

;--- Ende.
;Falls keine Partition/DiskImage über
;":_DDC_OPENMEDIA" geöffnet wurde, dann
;mindestens 1x ":OpenDisk" ausführen.
;Bei einer RAMLink wird dabei auch die
;Routine ":EnterTurbo" ausgeführt.
;Dabei wird dann die RAMLink-Adresse
;und die Partitionsliste ermittelt und
;im Treiber gespeichert.
::skip_disk		jsr	OpenDisk		;Diskette/Medium öffnen.
;			txa				;Keine Fehlerprüfung falls
;			bne	:error			;Partition ungültig.
			ldx	#NO_ERROR		;Kein Fehler...
			beq	:exit			; => Ende...

;--- Fehler!
::error			txa
			pha

			ldy	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	_DDC_DRVRESTORE		;Treiber wieder herstellen.

			pla
			tax

			cpx	#NO_ERROR		;Laufwerk installiert ?
			beq	:exit			; => Ja, Ende...
			cpx	#CANCEL_ERR		;Durch Anwender abgebrochen ?
			beq	:exit			; => Ja, Ende...

;--- Fehler ausgeben.
::cancel		bit	DEV_INSTALL_MODE	;GD.CONFIG-Modus ?
			bmi	:back2cfg		; => Ja, keinen Fehler ausgeben.

			jsr	devErr_Install		;Fehler ausgeben.

;			ldx	#DEV_NOT_FOUND

;--- Ende, zurück zu DeskTop/GD.CONFIG.
::exit			bit	DEV_INSTALL_MODE	;Anwendung/GD.CONFIG ?
			bmi	:back2cfg		; => GD.CONFIG.
			jmp	EnterDeskTop		;Zurück zum DeskTop.
::back2cfg		rts				;Zurück zu GD.CONFIG.

;*** Installation ausführen.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk
;          DrvMode    = Laufwerkstyp
;
;TurboDOS muss deaktiviert sein!
;
:DO_DEV_INSTALL		jsr	initTestDevice		;Laufwerk initialisieren.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

;--- Treiber installieren.
::install		jsr	_DRV_INSTALL		;Laufwerkstreiber installieren.
			txa				;Wurde Laufwerk installiert ?
			bne	:error			; => Nein, Abbruch...

;--- Kernal in REU aktualisieren.
			bit	DEV_INSTALL_MODE	;GD.CONFIG?
			bpl	:1			; => Ja, Kernal manuell updaten.
			bit	firstBoot		;GEOS-BootUp?
			bpl	:2			; => Ja, Update durch GD.CONFIG.

::1			jsr	_DDC_UPDATEKERNAL	;Kernal für RBOOT aktualisieren.

::2			lda	flgUpdDDrvFile
			cmp	#FALSE			;Flag gesetzt: "Treiber updated" ?
			beq	:skip_update		; => Nein, weiter...

			jsr	UpdDDrvFile		;Einstellungen aktualisieren.

::skip_update		ldx	#NO_ERROR

;--- Laufwerk zurücksetzen.
;Bei einem Fehler ggf. den bisherigen
;Treiber wieder herstellen.
::error			rts

;*** Installationsmodus.
:DEV_INSTALL_MODE	b $00				;$00=Anwendung, $FF=GD.CONFIG.
