; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Anwendungsstart.
:APPL_DEV_INSTALL	lda	MP3_CODE +0		;Kennbyte für GeoDOS/MegaPatch.
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
			bne	:exit			; => Nein, Ende...
;---

			jsr	GetBackScreen		;Hintergrundbild laden.

			jsr	SaveDrvAppName		;Name Treiberdatei speichern.
							;Muss vor FindDiskCore ausgeführt
							;werden, da dann ":dirEntryBuf"
							;verändert wird.

			jsr	FindDiskCore		;GD.DISK.CORE nachladen.
			txa
			bne	:error

			bit	firstBoot		;GEOS-BootUp ?
			bpl	BOOT_DEV_INSTALL	; => Ja, automatisch installieren.
			jmp	INIT_DEV_INSTALL	; => Nein, manuell installieren.

::error			LoadW	r0,dlg_NoCoreErr
			jsr	DoDlgBox		;Dialogbox ausgeben.

::exit			jmp	EnterDeskTop

;*** GEOS-BootUp.
:BOOT_DEV_INSTALL	lda	curDrive		;Boot-Laufwerk speichern.
			sta	:tmpdevice

			lda	#$00			; -> Anwendung.
			sta	DEV_INSTALL_MODE	;Installationsmodus speichern.

			jsr	INIT_DEV_TEST		;Laufwerksinstallation testen.
			txa	 			;Kann Laufwerk installiert werden ?
			bne	:error			; => Nein, ohne Fehler beenden...

if EN_CHECK_MINST = TRUE
			jsr	INIT_DEV_MINST		;Auf Mehrfach-Installation testen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...
endif

			lda	DrvAdrGEOS		;Laufwerksadresse bereits
			bne	:auto			;festgelegt ?

			jsr	INIT_DEV_ADR		;Geräteadresse festlegen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

::auto			jsr	DO_DEV_INSTALL		;Laufwerk installieren.
			txa	 			;Wurde Laufwerk installiert ?
			bne	:error			; => Nein, Abbruch...

;--- Ergänzung: 10.04.21/M.Kanet
;Bei der Rückkehr zu AutoBoot muss das
;ursprüngliche Boot-Laufwerk wieder
;aktiviert werden!
;AutoBoot setzt das laden von AUTOEXEC
;Programmen nur vom aktuellen Laufwerk
;fort, das Boot-Laufwerk darf nicht
;gewechselt werden!!!
::error			lda	:tmpdevice		;Boot-Laufwerk zurücksetzen.
			jsr	SetDevice

;--- Ende, zurück zu AutoBoot...
			jmp	EnterDeskTop		;Zurück zum DeskTop.

::tmpdevice		b $00

;*** Treiber über GD.CONFIG installieren.
:CFG_DEV_INSTALL	lda	#$ff			; -> GD.CONFIG.
			b $2c

;*** Laufwerk installieren.
:INIT_DEV_INSTALL	lda	#$00			; -> Anwendung.
			sta	DEV_INSTALL_MODE	;Installationsmodus speichern.

			jsr	INIT_DEV_TEST		;Laufwerksinstallation testen.
			txa	 			;Kann Laufwerk installiert werden ?
			bne	:error			; => Nein, Abbruch...

if EN_CHECK_MINST = TRUE
			jsr	INIT_DEV_MINST		;Auf Mehrfach-Installation testen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...
			tya				;Laufwerksadresse definiert ?
			bne	:1			; => Ja, weiter...
endif

			jsr	INIT_DEV_ADR		;Geräteadresse festlegen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

::1			jsr	DO_DEV_INSTALL		;Laufwerk installieren.
			txa	 			;Wurde Laufwerk installiert ?
			bne	:error			; => Nein, Abbruch...

			bit	firstBoot		;GEOS-BootUp ?
			bpl	:skip_disk		; => Ja, weiter...

;--- Diskette/Partition öffnen.
if EN_SELECT_PART
			jsr	OpenNewDisk		;Neue Partition öffnen.
endif

;--- DiskImage öffnen.
if EN_SELECT_DIMG
			jsr	OpenNewDisk		;Neues DiskImage öffnen.
endif

;--- Ende.
::skip_disk		ldx	#NO_ERROR		;Bedingter Sprung...
			beq	:exit

;--- Fehler!
::error			bit	DEV_INSTALL_MODE	;GD.CONFIG-Modus ?
			bmi	:back2cfg		; => Ja, keinen Fehler ausgeben.

			jsr	devErr_Install		;Fehler ausgeben.

			ldx	#DEV_NOT_FOUND

;--- Ende, zurück zu DeskTop/GD.CONFIG.
::exit			bit	DEV_INSTALL_MODE	;Anwendung/GD.CONFIG ?
			bmi	:back2cfg		; => GD.CONFIG.
			jmp	EnterDeskTop		;Zurück zum DeskTop.
::back2cfg		rts				;Zurück zu GD.CONFIG.

;*** Installation ausführen.
:DO_DEV_INSTALL		ldx	DrvAdrGEOS
			lda	driveType -8,x		;War Laufwerk bereits installiert ?
			beq	:install		; => Nein, weiter...

			ldy	#$00			;Vorgabe für ":ramBase".
			and	#%10000000		;RAM-Laufwerk ?
			beq	:1			; => Nein, weiter...

			lda	DrvMode			;RAM-Laufwerk installieren ?
			bpl	:1			; => Nein, weiter...
			ldy	ramBase -8,x		; => Ja, ":ramBase" retten.

::1			tya				;Vorgabewert für ":ramBase"
			pha				;zwischenspeichern.

			jsr	INIT_DEV_REMOVE		;Aktuellen Treiber deinstallieren.

			pla
			ldy	DrvAdrGEOS		;":ramBase" wieder herstellen.
			sta	ramBase -8,y

			txa				;Installationsfehler ?
			bne	:error			; => Ja, Abbruch...

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
::install		lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	DskDev_Prepare		;Neuen Treiber aktivieren.

			jsr	InitDiskDrive		;Laufwerk initialisieren.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			jsr	InstallDriver		;Laufwerkstreiber installieren.
			txa				;Wurde Laufwerk installiert ?
			bne	:error			; => Nein, Abbruch...

;--- Laufwerkstest -> ":InstallDriver"
;			lda	#$00			;Laufwerkswechsel erzwingen.
;			sta	curDevice
;			lda	DrvAdrGEOS		;Laufwerk aktivieren und Treiber
;			jsr	SetDevice		;erneut aus GEOS-DACC einlesen.
;			txa
;			bne	:error

;--- Kernal in REU aktualisieren.
			jsr	CopyKernal2REU		;Kernal für RBOOT aktualisieren.

			ldx	#NO_ERROR
::error			rts

;*** Laufwerk deinstallieren.
;Übergabe: DrvAdrGEOS = Laufwerksadresse.
:INIT_DEV_REMOVE	ldx	DrvAdrGEOS
			jsr	DskDev_Unload		;RAM-Speicher freigeben.

			jsr	PurgeTurbo		;TurboDOS abschalten, da jetzt
							;":turboFlags" gelöscht werden!
			ldx	DrvAdrGEOS
			jmp	DskDev_ClrData		;Laufwerksdaten zurücksetzen.

;*** Auf Mehrfach-Installation testen.
if EN_CHECK_MINST = TRUE
:INIT_DEV_MINST		lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	ChkDrvMInst		;Laufwerk bereits installiert?
			txa
			beq	:exit			; => Nein, weiter...

			bit	DEV_INSTALL_MODE	;Aufruf aus GD.CONFIG ?
			bmi	:exit			; => Ja, Ende...
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:exit

			sty	DrvAdrGEOS		;Vorhandenes Laufwerk als
			ldx	#NO_ERROR		;neue Adresse vorgeben.

::exit			rts
endif

;*** Laufwerksadresse abfragen.
:INIT_DEV_ADR		ldx	#NO_ERROR
			bit	DEV_INSTALL_MODE	;Aufruf aus GD.CONFIG ?
			bmi	:exit			; => Ja, weiter...

			LoadW	r5,DrvName
			jsr	SlctGEOSadr		;GEOS-Laufwerksadresse wählen.
			cpx	#NO_ERROR		;Abbruch ?
			bne	:exit			; => Ja, Ende...
			sta	DrvAdrGEOS		;GEOS-Adresse speichern.

::exit			rts

;*** Installationsmodus.
:DEV_INSTALL_MODE	b $00				;$00=Anwendung, $FF=GD.CONFIG.

;*** Dialogbox: "GD.DISK.CORE nicht gefunden!"
:dlg_NoCoreErr		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR   ,$0c,$0b
			w DlgBoxTitle
			b DBTXTSTR   ,$0c,$20
			w :t01
			b DBTXTSTR   ,$0c,$2c
			w :t02
			b DBTXTSTR   ,$0c,$36
			w :t03
			b OK         ,$01,$50
			b NULL

if Sprache = Deutsch
::t01			b "Installation abgebrochen!",NULL
::t02			b "Die Systemdatei 'GD.DISK.CORE'",NULL
::t03			b "wurde nicht gefunden!",NULL
endif

if Sprache = Englisch
::t01			b "Unable to install drive!",NULL
::t02			b "System file 'GD.DISK.CORE'",NULL
::t03			b "was not found!",NULL
endif
