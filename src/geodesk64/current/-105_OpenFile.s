; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Anwendung starten auf die ":a0" zeigt.
:StartFile_a0		LoadW	r6,fileName
			ldx	#a0L 			;Dateiname aus Verzeichnis-Eintrag
			ldy	#r6L			;in Puffer kopieren.
			jsr	SysCopyFName

			ldy	#15
::1			lda	fileName,y		;Dateiname als Vorgabe für
			sta	AppFName,y		;Anwendungsname kopieren.
			dey
			bpl	:1

			ldy	#$18			;Dateityp auswerten.
			lda	(a0L),y
			beq	:start_basic		; => BASIC-Programm.
			cmp	#APPLICATION		;Anwendung?
			beq	:start_appl		; => Ja, weiter...
			cmp	#AUTO_EXEC		;AutoExec?
			beq	:start_appl		; => Ja, weiter...
			cmp	#APPL_DATA		;Dokument?
			beq	:start_doc		; => Ja, weiter...
			cmp	#DESK_ACC		;Hilfsmittel?
			beq	:start_da		; => Ja, weiter...
			cmp	#SYSTEM			;System-Datei (GeoDesk-Farben)?
			beq	:start_system		; => Ja, weiter...

			jmp	OpenFTypError		; => Keine gültige Datei.

::start_appl		jmp	OpenAppl
::start_doc		jmp	OpenDoc
::start_auto		jmp	OpenAppl
::start_da		jmp	OpenDA
::start_basic		jmp	OpenBASIC
::start_system		jmp	OpenSystem

;*** Unbekannter Dateityp.
:OpenFTypError		ldx	#$82			;"UNKNOWN_FTYPE"
			b $2c

;*** Allgemeiner Dateifehler.
:OpenFNamError		ldx	#$83			;"FILENAME_ERROR"
			b $2c

;*** AppLink nicht gefunden.
:OpenALnkError		ldx	#$85			;"ALNK_NOT_FOUND"
			lda	#<fileName
			ldy	#>fileName
			bne	OpenError

;*** Anwendung für Dokument nicht gefunden.
:OpenFAppError		ldx	#$84			;"APPL_NOT_FOUND"
			lda	#<AppClass
			ldy	#>AppClass
			bne	OpenError

;*** Nicht mit GEOS64 kompatibel.
:OpenG64Error		ldx	#INCOMPATIBLE		;"INCOMPATIBLE"
			lda	#<AppFName
			ldy	#>AppFName
			bne	OpenError

;*** Allgemeiner Laufwerksfehler.
:OpenDiskError		MoveB	r1L,errDrvInfoT		;Track/Sektor für Laufwerksfehler
			MoveB	r1H,errDrvInfoS		;zwischenspeichern.

			ldy	curDrive		;Partition für Laufwerksfehler
			lda	RealDrvMode -8,y	;zwischenspeichern.
			and	#SET_MODE_PARTITION
			beq	:1
			lda	drivePartData -8,y
::1			sta	errDrvInfoP

			lda	#$00			;Kein Dateiname.
			ldy	#$00
;			beq	OpenError

;*** Fehlermeldung ausgeben und zurück zum DeskTop.
:OpenError		stx	errDrvCode		;Fehlercode speichern.

			sta	r0L			;Zeiger auf Dateiname
			sty	r0H			;zwischenspeichern.
			ora	r0H			;Dateiname vorhanden?
			beq	:1			; => Nein, weiter...

			LoadW	r6,dataFileName		;Dateiname in Zwischenspeicher.
			ldx	#r0L			;Muss an eine freie Stelle im RAM
			ldy	#r6L			;kopiert werden, da Sub-Modul
			jsr	CopyString		;sonst evtl. den Namen überschreibt.

			lda	#<dataFileName
			ldy	#>dataFileName
::1			sta	errDrvInfoF +0
			sty	errDrvInfoF +1

			jsr	SUB_STATMSG		;Fehlermeldung ausgeben.

			jmp	MOD_RESTART		;Menü/FensterManager neu starten.

;*** Datei laden vorbereiten.
:PrepGetFile		jsr	ResetScreen		;Bildschirm löschen.

:PrepGetFileDA		jsr	UseSystemFont		;Standardzeichensatz.

			jsr	i_FillRam		;dlgBoxRamBuf löschen.
			w	417
			w	dlgBoxRamBuf
			b	$00

			ldx	#r15H			;ZeroPage löschen.
			lda	#$00
::loop			sta	$0000,x
			dex
			cpx	#r0L
			bcs	:loop
			rts

;*** Name der Anwendung die gestartet werden soll.
;Hinweis:
;Steht für Sub-Module nicht zur
;Verfügfung! ":dataFileName" nutzen.
:fileName		s 17
:AppFName		s 17
:AppClass		s 17
:DocDName		s 17

;*** Applink auf anderen Laufwerken suchen.
;    Übrgabe: a0 = Zeiger auf Dateiname.
:StartApplink_a0	ldy	#0			;Dateiname kopieren.
::1			lda	(a0L),y
			sta	fileName,y
			beq	:2
			iny
			cpy	#16
			bcc	:1

::2			jsr	IsFileOnDsk		;Datei auf allen Laufwerken suchen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			LoadW	a0,dirEntryBuf -2
			jmp	StartFile_a0		;Datei öffnen.

::error			jmp	OpenALnkError		;Fehlermeldung anzeigen.

;*** Datei auf allen Laufwerken suchen.
:IsFileOnDsk		lda	#%10000000		;Anwendung auf
			jsr	FindFileAllDrv		;RAM-Laufwerken suchen.
			txa				;Gefunden?
			beq	:1			; => Ja, Ende...
			lda	#%00000000		;Anwendung auf
			jsr	FindFileAllDrv		;Disk-Laufwerken suchen.
::1			rts

;*** Datei auf den Laufwerken A: bis D: suchen.
;
;--- Hinweis:
;Die Suche nach einer bestimmten Datei
;wird auch hier verwendet:
; -105_OpenEditor -> ":FindEditor"
; -105_OpenFile   -> ":FindAppFile"
; -105_OpenFile   -> ":StartApplink_a0"
;
:FindFileAllDrv		sta	:2 +1			;Laufwerkstyp speichern.

			ldx	curDrive
			stx	r15L
::1			stx	r15H
			lda	driveType -8,x		;Laufwerk verfügbar?
			beq	:3			; => Nein, weiter...
			and	#%10000000
::2			cmp	#$ff			;Gesuchter Laufwerkstyp?
			bne	:3			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Disk-Fehler?
			bne	:3			; => Ja, weiter...

			LoadW	r6,fileName
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...

			LoadW	r6,fileName		;Datei-Modus testen.
			jsr	ChkFlag_40_80		;Gefundene Anwendung für GEOS64?
			txa				;DiskFehler/Inkompatibel?
			beq	:5			; => Nein, Ende...

::3			ldx	r15H			;Zeiger auf nächstes Laufwerk.
			inx
			cpx	#12			;Laufwerk > 11?
			bcc	:6			; => Nein, weiter...
			ldx	#$08
::6			cpx	r15L			;Alle Laufwerke durchsucht?
			bne	:1			;Auf nächstem Laufwerk weitersuchen.

::4			ldx	#$ff			;Nicht gefunden.

;--- Falls Anwendung nicht gefunden, Laufwerk zurücksetzen.
::5			txa				;Fehler?
			beq	:7			; => Nein, weiter...
			pha
			lda	r15L 			;Vorheriges Laufwerk wieder
			jsr	SetDevice		;aktivieren.
			pla
			tax
::7			rts

;*** Anwendung oder AutoExec starten.
:OpenAppl		jsr	ChkFlag_40_80		;40/80Z-Flag testen.
			cpx	#INCOMPATIBLE		;Inkompatibel mit GEOS64?
			beq	:error_40_80		; => Ja, Abbruch...
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			sei				;GEOS-Reset #0.
			cld
			ldx	#$ff
			txs

			jsr	GEOS_InitSystem		;GEOS-Reset #1.
			jsr	PrepGetFile

			lda	#>EnterDeskTop -1	;Bei Fehler zurück zum
			pha				;DeskTop.
			lda	#<EnterDeskTop -1
			pha

;			LoadB	r0L,$00			;Wird durch ":PrepGetFile" gelöscht.
			LoadW	r6,AppFName
			jmp	GetFile			;Datei laden/starten.
::error			jmp	OpenFNamError		;Dateifehler => Abbruch.
::error_40_80		jmp	OpenG64Error		;Inkompatibel => Abbruch.

;*** Dokument starten.
:OpenDoc		ldx	#r14L			;Zeiger auf Aktuelle Diskette.
			jsr	GetPtrCurDkNm

			ldy	#16 -1
::0			lda	(r14L),y		;Diskname kopieren.
			sta	DocDName,y
			dey
			bpl	:0

;			LoadW	r6,fileName		;Zeiger auf Dateiname bereits in r6.
			LoadW	r0,AppFName
			ldx	#r6L
			ldy	#r0L
			jsr	CopyString

;			LoadW	r6,fileName		;Zeiger auf Dateiname bereits in r6.
			jsr	LoadDokInfos		;Dokument-Daten einlesen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::error			jmp	OpenFNamError		;Dateifehler => Abbruch.
::error_app		jmp	OpenFAppError		;Anwendung fehlt => Abbruch.
::error_40_80		jmp	OpenG64Error		;Inkompatibel => Abbruch.

::1			jsr	IsApplOnDsk		;Anwendung suchen.
			cpx	#INCOMPATIBLE
			beq	:error_40_80
			txa				;Gefunden?
			bne	:error_app		; => Nein, Abbruch...

			ldy	#16 -1			;Dokument- und Diskname
::2			lda	DocDName,y		;in Systemspeicher kopieren.
			sta	dataDiskName,y
			lda	fileName,y
			sta	dataFileName,y
			dey
			bpl	:2

			sei				;GEOS-Reset #0.
			cld
			ldx	#$ff
			txs

			jsr	GEOS_InitSystem		;GEOS-Reset #1.
			jsr	PrepGetFile

			lda	#>EnterDeskTop -1	;Bei Fehler zurück zum
			pha				;DeskTop.
			lda	#<EnterDeskTop -1
			pha

			LoadW	r2,dataDiskName
			LoadW	r3,dataFileName
			LoadW	r6,AppFName
			LoadB	r0L,%10000000
			jmp	GetFile			;Anwendung+Dokument starten.

;*** Hilfsmittel laden.
:OpenDA			jsr	ChkFlag_40_80		;40/80Z-Flag testen.
			cpx	#INCOMPATIBLE		;Inkompatibel mit GEOS64?
			beq	:error_40_80		; => Ja, Abbruch...
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			bit	GD_DA_BACKSCRN		;Hintergrund zurücksetzen ?
			bmi	:1			; => Nein, weiter...
			jsr	ResetScreen		;Bildschirm löschen.

::1			jsr	PrepGetFileDA		;":dlgBoxRamBuf" löschen.

			LoadW	r6,AppFName		;Zeiger auf Dateiname.
			LoadB	r0L,%00000000
;			LoadB	r10L,$00		;Wird durch ":PrepGetFile" gelöscht.
			jsr	GetFile			;DA laden.
			txa
			bne	:error

			lda	GD_DA_RELOAD_DIR
			beq	:no_reload
			bmi	:all_update

::top_update		jsr	SET_LOAD_DISK		;Optional: Oberstes Fenster von Disk
			jmp	MOD_UPDATE		;neu laden... -> Langsam...
::all_update		jmp	MOD_REBOOT		;Optional: Alle Fenster neu.
::no_reload		jmp	MOD_INITWM		;Menü/FensterManager neu starten.
::error			jmp	OpenFNamError		;Dateifehler => Abbruch.
::error_40_80		jmp	OpenG64Error		;Inkompatibel => Abbruch.

;*** BASIC-Anwendung starten.
:OpenBASIC		LoadW	r0,Dlg_ExitBASIC
			jsr	DoDlgBox

			lda	sysDBData		;Abbruch ?
			cmp	#CANCEL
			beq	:exit			; => Nein, weiter...

			LoadW	r6,AppFName		;Zeiger auf Dateiname.
			jmp	ExitBApplRUN		;BASIC-Datei laden/starten.
::exit			jmp	MOD_RESTART		;Menü/FensterManager neu starten.

;*** Dialogboxen.
:Dlg_ExitBASIC		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :2
			b DBTXTSTR   ,$10,$2e
			w fileName
			b DBTXTSTR   ,$0c,$3c
			w :3
			b YES        ,$01,$50
			b CANCEL     ,$11,$50
			b NULL

if LANG = LANG_DE
::2			b PLAINTEXT
			b "GEOS beenden und die BASIC-Datei"
			b BOLDON,NULL
::3			b PLAINTEXT
			b "laden und starten?",NULL
endif
if LANG = LANG_EN
::2			b PLAINTEXT
			b "Quit GEOS and load the BASIC file"
			b BOLDON,NULL
::3			b PLAINTEXT
			b "and then run the file?",NULL
endif

;*** Systemdatei öffnen.
;An dieser Stelle werden nur die
;geoDesk-Farbdateien geladen.
:OpenSystem		;LoadW	r6,fileName		;Zeiger auf Dateiname.
			jsr	FindFile		;Farbdatei suchen.
			txa				;Fehler?
			beq	:1			; => Nein, weiter...
::error			jmp	OpenFNamError		; => Abbruch.

::1			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;GEOS-Header einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			LoadW	r0,fileHeader +77
			LoadW	r1,:colConfigClass
			ldx	#r0L
			ldy	#r1L
			jsr	CmpString		;GeoDesk-Farbdatei?
			bne	:exit			; => Nein, Ende...

			LoadW	r6,fileName		;Zeiger auf Dateiname.
			jsr	LoadColConfig_r6	;Farbdaten einlesen.

			jmp	MOD_REBOOT		;Desktop neu zeichnen.
::exit			jmp	MOD_RESTART		;Ohne Update zurück zum DeskTop...

::colConfigClass	b "geoDeskCol  V1.0",NULL

;*** Dokument-Infos einlesen.
;    Übergabe: r6 = Zeiger auf Dateiname.
:LoadDokInfos		;LoadW	r6,fileName		;Zeiger auf Dateiname bereits in r6.
			jsr	FindFile		;Dateieintrag suchen.
			txa				;Fehler ?
			bne	:2			; => Ja, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
			txa				;Fehler ?
			bne	:2			; => Ja, Abbruch...

			ldy	#11			;"Class" der Application einlesen.
::1			lda	fileHeader+$75,y
			sta	AppClass,y
			dey
			bpl	:1

			ldx	#NO_ERROR		;Kein Fehler...
::2			rts				;Ende.

;*** Applikation suchen.
:IsApplOnDsk		lda	#%10000000		;Anwendung auf
			jsr	FindApplFile		;RAM-Laufwerken suchen.
			txa				;Gefunden?
			beq	:1			; => Ja, Ende...
			lda	#%00000000		;Anwendung auf
			jsr	FindApplFile		;Disk-Laufwerken suchen.
::1			rts

;*** Anwendung auf den Laufwerken A: bis D: suchen.
:FindApplFile		sta	:2 +1			;Laufwerkstyp speichern.

;--- Hinweis:
;Die Suche nach einer bestimmten Datei
;wird auch hier vrwendet:
; -105_OpenEditor -> ":FindEditor"
; -105_OpenFile   -> ":FindAppFile"
; -105_OpenFile   -> ":StartApplink_a0"

			ldx	curDrive
			stx	r15L
::1			stx	r15H
			lda	driveType -8,x		;Laufwerk verfügbar?
			beq	:3			; => Nein, weiter...
			and	#%10000000
::2			cmp	#$ff			;Gesuchter Laufwerkstyp?
			bne	:3			; => Nein, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren.

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Disk-Fehler?
			bne	:3			; => Ja, weiter...

			LoadW	r6,AppFName		;Anwendung  suchen.
			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,AppClass
			jsr	FindFTypes
			txa				;Fehler?
			bne	:3			; => Ja, Abbruch...
			lda	r7H			;Datei gefunden?
			bne	:3			; => Nein, weiter suchen...

			LoadW	r6,AppFName		;Datei-Modus testen.
			jsr	ChkFlag_40_80		;Gefundene Anwendung für GEOS64?
			txa
			beq	:5			; => Ja, Ende...

::3			ldx	r15H			;Zeiger auf nächstes Laufwerk.
			inx
			cpx	#12			;Laufwerk > 11=
			bcc	:6			; => Nein, weiter...
			ldx	#$08
::6			cpx	r15L			;Alle Laufwerke durchsucht?
			bne	:1			;Auf nächstem Laufwerk weitersuchen.

::4			ldx	#$ff			;Nicht gefunden.

;--- Falls Anwendung nicht gefunden, Laufwerk zurücksetzen.
::5			txa				;Fehler?
			beq	:7			; => Nein, weiter...
			pha
			lda	r15L 			;Vorheriges Laufwerk wieder
			jsr	SetDevice		;aktivieren.
			pla
			tax
::7			rts

;*** C128/40/80Z-Modus testen.
;    Übergabe: r6 = Zeiger auf Dateiname.
:ChkFlag_40_80		;LoadW	r6,AppFName		;Zeiger auf Dateiname bereits in r6.
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:4			; => Ja, Abbruch.

			LoadW	r9,dirEntryBuf		;Infoblock einlesen.
			jsr	GetFHdrInfo
			txa				;Info-Block gefunden ?
			bne	:4			; => Nein, BASIC-File, Abbruch...

;--- Hinweis:
;Unter GEOS gibt es kein Flag für "Nur GEOS128". Eine Anwendung die für den
;40+80Z-Modus entwickelt wurde kann auch für GEOS64 existieren. Es kann aber
;auch eine reine GEOS128-Anwendung sein.
;Unter GEOS64 werden daher GEOS64, 40ZOnly und 40/80Z akzeptiert.
			lda	fileHeader+$60		;40/80Z-Flag einlesen.
			cmp	#$c0			;Nur 80Z?
			bne	:2			; => Nein, weiter...
::1			ldx	#INCOMPATIBLE		; => Nur GEOS128, Abbruch.
			b $2c
::2			ldx	#NO_ERROR		; => Anwendung OK.
::4			rts

;*** Anwendung wählen.
:SelectAppl		lda	#APPLICATION		;GEOS-Anwednungen.
			b $2c
:SelectAuto		lda	#AUTO_EXEC		;GEOS-Autostart.
			b $2c
:SelectDA		lda	#DESK_ACC		;GEOS-Hilfsmittel.
			sta	r7L

			lda	#$00			;GEOS-Klasse löschen.
			sta	r10L
			sta	r10H

;*** Anwendung/Dokument wählen.
:SelectAnyFile		jsr	OpenFile		;Datei auswählen.
			txa				;Diskettenfehler ?
			beq	:openfile
::exit			jmp	MOD_RESTART		;Menü/FensterManager neu starten.

::openfile		LoadW	r6,dataFileName
			jsr	FindFile		;Datei suchen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			LoadW	a0,dirEntryBuf -2	;Datei öffnen.
			jmp	StartFile_a0

;*** Dokument wählen.
:SelectDocument		ldx	#0			;Alle Dokumente.
			b $2c
:SelectDocWrite		ldx	#2			;GeoWrite-Dokumente.
			b $2c
:SelectDocPaint		ldx	#4			;GeoPaint-Dokumente.
			lda	ApplClass +0,x		;GEOS-Klasse fürr Dokumente setzen.
			sta	r10L
			lda	ApplClass +1,x
			sta	r10H
			LoadB	r7L,APPL_DATA		;GEOS-Dokumente.
			jmp	SelectAnyFile		;Datei auswählen.

;*** Liste der Anwendungsklassen.
:ApplClass		w $0000
			w AppClassWrite
			w AppClassPaint
:AppClassWrite		b "Write Image ",NULL
:AppClassPaint		b "Paint Image ",NULL
