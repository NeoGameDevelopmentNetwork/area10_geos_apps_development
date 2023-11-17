; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskette validieren.
:doValidateJob		lda	#$00
			sta	ErrorFiles		;Anzahl gelöschter Dateien = $00.

			jsr	DrawStatusBox		;Statusbox vorbereiten.

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

:StartValid2		ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Kein NativeMode, weiter...

			jsr	OpenRootDir		;Hauptverzeichnis öffnen.
			txa				;Diskettenfehler ?
			bne	:3			; => Ja, Abbruch.
			beq	:2			; => Nein, weiter...

::1			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:3			; => Ja, Abbruch.

::2			jsr	ClearBAM		;Leere BAM im Speicher erzeugen.
			txa				;Diskettenfehler ?
			beq	StartValidDsk		; => Nein, weiter...

::3			rts				;Diskettenfehler, Ende...

;*** Verzeichnis validieren.
:StartValidDsk		jsr	prntDiskInfo		;Diskname ausgeben.

			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:1			; => Nein, weiter...

			bit	ChkNMSubD		;Verzeichnis-Header prüfen?
			bpl	:1			; => Nein, weiter...
			jsr	VerifyNMDir		;Verzeichnis-Header prüfen.

::1			jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler ?
			beq	:2
			rts

::2			jsr	InitForIO		;IO aktivieren.

			lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk
::3			jsr	ValidateDir		;Verzeichnis-Sektor in BAM belegen.
			txa				;Diskettenfehler ?
			bne	:4			;Ja, Abbruch.

			lda	fileHeader+1		;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Sektor richten.
			lda	fileHeader+0
			sta	r1L
			bne	:3			;Nächsten Sektor belegen.

			LoadW	r5,curDirHead
			jsr	ChkDkGEOS
			bit	isGEOS			;GEOS-Diskette ?
			bpl	:5			;Nein, weiter...

			lda	curDirHead+172		;Zeiger auf Borderblock richten.
			sta	r1H
			lda	curDirHead+171
			sta	r1L			;Borderblock verfügbar ?
			beq	:5			;Nein, weiter...

			jsr	ValidateDir		;Borderblock belegen.
			txa				;Diskettenfehler ?
			beq	:5			;Nein, weiter...

;--- Diskettenfehler, Abbruch zum DeskTop.
::4			jsr	DoneWithIO		;I/O abschalten.

			cpx	#$fe			;Abbruch durch Anwender?
			beq	:exit			; => Ja, Ende...
			cpx	#$ff			;Neustart?
			bne	:exit			; => Nein, Ende...

			jsr	SCPU_Pause		;3sec. Pause.
			jsr	SCPU_Pause		;(Funktioniert nicht unter VICE
			jsr	SCPU_Pause		; im WARP-Modus!)

			jsr	DrawStatusBox		;Statusbox vorbereiten.

			jmp	StartValid2		;Validate erneut starten.

;--- Unterverzeichnisse aufräumen.
::5			jsr	DoneWithIO		;IO abschalten.
			jsr	PutDirHead		;BAM auf Diskette schreiben.

			ldx	WM_WCODE
			ldy	WIN_DRIVE,x		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,y	;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:7			; => Nein, weiter...

			jsr	ValidSDir		;Unterverzeichnisse validieren.
			txa				;Diskettenfehler ?
			bne	:exit			; => Nein, weiter...

;--- Ende, BAM im Speicher aktualisieren.
::7			jsr	OpenDisk		;Disk öffnen, Ende.
::exit			rts

;*** Unterverzeichnisse Validieren.
:ValidSDir		lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk

			LoadW	r4,fileHeader		;Zeiger auf Zwischenspeicher.
::101			jsr	GetBlock		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:105			;Ja, Abruch.

			ldy	#$02
::102			lda	fileHeader,y		;Dateityp einlesen.
			and	#FTYPE_MODES		;Dateityp-Flag isolieren.
			cmp	#FTYPE_DIR		;Verzeichnis ?
			beq	:107			;Ja, Verzeichnis validieren.

::103			tya				;Zeiger auf nächsten Eintrag.
			clc
			adc	#$20
			tay				;Letzter Eintrag überprüft ?
			bcc	:102			;Nein, weiter...

			lda	fileHeader+1		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	fileHeader+0
			sta	r1L			;Ende erreicht ?
			bne	:101			;Nein, weiter...

::104			ldx	curDirHead+$22		;Hauptverzeichnis ?
			ldy	curDirHead+$23
			cpx	#$00
			bne	:106			;Nein, zum vorherigen Verzeichnis.
			cpy	#$00
			bne	:106			;Nein, zum vorherigen Verzeichnis.

			ldx	#$00			;Ja, Ende...
::105			rts

;*** Übergeordnetes Verzeichnis öffnen.
::106			lda	curDirHead+$24		;Zeiger auf PARENT-Spur merken.
			pha
			lda	curDirHead+$25		;Zeiger auf PARENT-Sektor merken.
			pha
			lda	curDirHead+$26		;Zeiger auf PARENT-Eintrag merken.
			pha
			txa				;Zeiger auf neuen Verzeichniszweig
			pha				;zwischenspeichern.
			tya
			pha
			jsr	PutDirHead		;BAM speichern.
			pla
			sta	r1H
			pla
			sta	r1L
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			pla				;Zeiger auf PARENT-Eintrag
			sta	:106a +1 		;wiederherstellen.
			pla
			sta	r1H
			pla
			sta	r1L

			txa				;Diskettenfehler ?
			bne	:105			;Ja, Abruch.

			LoadW	r4,fileHeader
			jsr	GetBlock		;PARENT-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:105			;Ja, Abruch.
::106a			ldy	#$ff
			jmp	:103			;Zeiger auf nächsten Eintrag.

;*** Neues Unterverzeichnis öffnen.
::107			tya
			pha
			jsr	PutDirHead
			pla
			tay
			lda	fileHeader+1,y
			sta	r1L
			lda	fileHeader+2,y
			sta	r1H
			jsr	OpenSubDir		;Unterverzeichnis öffnen.
			txa				;Diskettenfehler ?
			bne	:108			;Ja, Abruch.

			jsr	prntDiskInfo		;Verzeichnisname ausgeben.

			jsr	ValSDirChain		;Verzeichniszweig validieren.
			txa				;Diskettenfehler ?
			bne	:108			;Nein, weiter...
			jmp	ValidSDir		;Dateien im Verzeichnis validieren.
::108			rts				;Ja, Abbruch.

;*** Verzeichniszweig validieren.
:ValSDirChain		jsr	EnterTurbo		;GEOS-Turbo aktivieren.
			txa				;Diskettenfehler ?
			bne	:103			;Ja, Abbruch....

			jsr	InitForIO		;IO aktivieren.

			lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk
::101			jsr	ValidateDir		;Verzeichnis-Sektor in BAM belegen.
			txa				;Diskettenfehler ?
			bne	:102			;Ja, Abbruch.

			lda	fileHeader+1		;Zeiger auf nächsten Verzeichnis-
			sta	r1H			;Sektor richten.
			lda	fileHeader+0
			sta	r1L
			bne	:101			;Nächsten Sektor belegen.
::102			jmp	DoneWithIO
::103			rts

;*** Alle Dateien im aktuellen Verzeichnis-Sektor belegen.
;    Übergabe: r1 = Tr/Se für Verzeichnis-Sektor.
:ValidateDir		MoveB	r1L,curDirSek +0	;Zeiger auf Track/Sektor merken.
			MoveB	r1H,curDirSek +1
			LoadW	r4,fileHeader		;Dir_Sektor einlesen.
			jsr	ReadBlock
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	r4L			;Zeiger auf Dateityp erzeugen.
			clc
			adc	#2
			sta	r5L
			lda	r4H
			adc	#00
			sta	r5H

::101			bit	KillErrorFile		;Defekte Datei automatisch löschen?
			bpl	:100			; => Nein, weiter...

			php				;Tastaturabfrage:
			sei				;RUN/STOP für "Validate beenden"
			ldx	CPU_DATA		;gedrückt ?
			lda	#$35
			sta	CPU_DATA
			ldy	#%01111111
			sty	CIA_PRA
			ldy	CIA_PRB
			stx	CPU_DATA
			plp

			cpy	#%01111111		;Validate abbrechen?
			beq	:cancel			; => Ja, Ende...

::100			ldy	#0			;Dateityp einlesen.
			lda	(r5L),y			;Datei korrekt geschlossen ?
			bmi	:103			;Ja, weiter...
			beq	:102			;Gelöschte Datei ? -> Übergehen.

			bit	CloseFiles		;Dateien schließen ?
			bpl	:102			;Nein, -> löschen.
			ora	#%10000000		;"Closed"-Bit setzen.
			sta	(r5L),y
			jmp	:103

;--- Geöffnete Datei löschen.
::102			lda	#$00			;Eintrag löschen, da geöffnete
			tay				;Datei ggf. beschädigt.
			sta	(r5L),y
			jmp	:105

;--- Dateityp auswerten.
::103			ldy	#22
			lda	(r5L),y			;GEOS-Filetyp einlesen.
			cmp	#TEMPORARY		;TEMPORARY?
			beq	:102			; => Ja, löschen...

::104			jsr	prntStatus		;Aktuelle Datei ausgeben.

			jsr	ValidateFile		;Datei validieren.
			txa				;Diskettenfehler ?
			beq	:105			; => Nein, weiter...

;--- Datei Defekt, Fehlerbehandlung.
			jsr	infoBadFile		;Hinweis: Datei beschädigt.

			bit	KillErrorFile		;Defekte Datei automatisch löschen?
			bpl	:exit			; => Nein, weiter...

			ldy	#$00			;Dateieintrag löschen.
			tya
			sta	(r5L),y

			jsr	:writeDirSek		;Verzeichnis-Sektor schreiben.
			txa				;Disk-/Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...

			inc	ErrorFiles		;Anzahl defekter Dateien +1.

			ldx	#$ff			;Validate wiederholen.
			b $2c
::cancel		ldx	#$fe			;Abbruch durch Anwender.
::exit			rts

;--- Weiter mit nächstem Eintrag.
::105			lda	r5L			;Zeiger auf nächsten Dir_Eintrag.
			clc
			adc	#32
			sta	r5L
			bcs	:writeDirSek
			jmp	:101

;--- Verzeichnis-Sektor auf Disk speichern.
::writeDirSek		MoveB	curDirSek +0,r1L	;Zeiger auf Track/Sektor einlesen.
			MoveB	curDirSek +1,r1H
			LoadW	r4,fileHeader		;Zeiger auf Dir_Sektor.
			jsr	WriteBlock		;Sektor schreiben.
			txa
			bne	:exit
			jmp	VerWriteBlock		;Sektor-Verify.

;*** Einzelne Datei validieren.
; r1 - Tr/Se für aktuellen Verzeichnis-Sektor.
; r5 - Zeiger auf den Directory-Eintrag
;      (wird aktualisiert)
:ValidateFile		lda	#0
			sta	r2L			;Zähler für belegte Blöcke
			sta	r2H			;löschen.

			ldy	#22
			lda	(r5L),y			;GEOS-Filetyp einlesen.
			beq	:104			;$00 = "nicht GEOS" ? Ja, weiter...

			ldy	#19			;Zeiger auf Track/Sektor Info-Block.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			jsr	AllocChain		;Info-Block belegen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

			jsr	readCurDirSek		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

			ldy	#21
			lda	(r5L),y			;Dateistruktur einlesen.
			beq	:104			;$00 = Seq ? Ja, weiter...

;--- VLIR-Dateien.
;    VLIR-Header einlesen und alle VLIR-Datensätze
;    in der BAM als belegt kennzeichnen.
			ldy	#1			;Zeiger auf Tr/Se VLIR-Header.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			LoadW	r4,fileTrScTab
			jsr	ReadBlock		;VLIR-Header einlesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

			ldy	#2			;Zeiger auf ersten VLIR-Datensatz.
::101			tya				;Wurden bereits alle 254 VLIR-
			beq	:104			;Datensätze belegt ? yReg = $00/Ja!

			lda	fileTrScTab,y		;Startadresse Track/Sektor des VLIR-
			sta	r1L			;Datensatzes nach ":r1" kopieren.
			iny
			ldx	fileTrScTab,y
			stx	r1H

			iny
			lda	r1L			;VLIR-Datensatz vorhanden ?
			beq	:103			;Nein, weiter...

::102			tya				;yReg sichern.
			pha
			jsr	AllocChain		;VLIR-Datensatz belegen.
			pla
			tay				;yReg zurücksetzen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.
			beq	:101			;Nein, nächsten Datensatz belegen.

::103			txa				;Sektor = $FF ? Datensatz übergehen.
			bne	:101			;Sektor = $00 ? Vorzeitig beenden.

;--- Datensatz belegen.
;    VLIR = Nur VLIR-Header belegen.
;    SEQ  = Datei belegen.
::104			jsr	readCurDirSek		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

			ldy	#1			;Zeiger auf Tr/Se Startsektor.
			jsr	CopySekAdr		;Sektor-Adresse nach ":r1" kopieren.
			jsr	AllocChain		;Datei belegen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

;--- Dateigröße korrigieren.
::105			jsr	readCurDirSek		;Verzeichnis-Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:107			;Ja, Abbruch.

			bit	ChkFileSize		;Dateilänge korrigieren ?
			bpl	:106			;Nein, weiter...

			ldy	#28			;Anzahl der belegten Sektoren in
			lda	r2L			;Dateieintrag kopieren.
			sta	(r5L),y
			iny
			lda	r2H
			sta	(r5L),y

::106			ldx	#0
::107			rts

;*** Track/Sektor aus Dateieintrag einlesen.
:CopySekAdr		lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H
			rts

;*** Verzeichnis-Sektor einlesen.
:readCurDirSek		MoveB	curDirSek +0,r1L
			MoveB	curDirSek +1,r1H
			LoadW	r4,diskBlkBuf
			jmp	ReadBlock		;Verzeichnis-Sektor einlesen.

;*** Unterverzeichnis-Header überprüfen.
;Version #2: Prüft das gesamte Verzeichnis.
:VerifyNMDir		jsr	GetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:99			; => Ja, Abbruch...

			jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O aktivieren.

			ldx	#$00			;Verzeichnis-Ebene zurücksetzen.
			stx	DirLevel
			txa
			sta	DirParentTr,x		;Tabelle mit Verzeichns-Daten
			sta	DirParentSe,x		;initialisieren.
			sta	DirEntryTr ,x
			sta	DirEntrySe ,x
			sta	DirEntryByt,x
			inx				;Zeiger auf ersten Verzeichnis-
			txa				;Sektor (ROOT) setzen.

;--- Neues Verzeichnis beginnen.
::98			ldy	DirLevel		;Start-Sektor in Tabelle schreiben.
			sta	DirRootTr  ,y		;$01/$01 bei ROOT, sonst Header für
			sta	r1L			;aktuelles Unterverzeichnis.
			txa
			sta	DirRootSe  ,y
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf Datenspeicher.
			jsr	ReadBlock		;Header-Sektor einlesen.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch...

			lda	diskBlkBuf +0		;Zeiger auf ersten vVerzeichnis-
			ldx	diskBlkBuf +1		;Sektor einlesen.

;--- Verzeichnis-Sektoren einlesen.
::101			sta	r1L			;Verzeichnis-Sektor setzen.
			stx	r1H
			jsr	ReadBlock		;Sektor einlesen.
			txa				;Diskettenfehler?
			beq	:102			; => Nein, weiter...
::100			jsr	DoneWithIO		;I/O abschalten und
::99			rts				;Diskettenfehler ausgeben.

;--- Verzeichnis-Einträge überprüfen.
::102			ldy	#$02
			lda	(r4L),y			;Dateityp einlesen.
			beq	:103			; => $00, keine Datei.
			and	#FTYPE_MODES
			cmp	#FTYPE_DIR		;Typ "Verzeichnis"?
			bne	:103			; => Nein, weiter...

			ldx	#FULL_DIRECTORY		;Fehler: "Full directory?"
			ldy	DirLevel		;Level-Zähler erhöhen.
			cpy	#15			;Max. Schachteltiefe erreicht?
			beq	:99			; => Ja, Fehler...
			iny				;Verschachtelung +1.
			sty	DirLevel		;(In Unterverzeichnis wechseln)
			jsr	UpdateHeader		;Verzeichnis-Header aktualisieren.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch...

			ldx	r1H			;Zeiger auf neuen Verzeichnis-Header
			lda	r1L			;einlesen. Ende erreicht?
			bne	:98			; => Nein, neues Verz. beginnen.
			beq	:104			; => Verzeichnis-Ende erreicht.

::103			clc				;Zeiger auf nächsten Eintrag.
			lda	r4L
			adc	#$20
			sta	r4L			;Sektor-Ende erreicht?
			bne	:102			; => Nein, weiter...

			ldx	diskBlkBuf +1		;Nächsten Sektor einlesen.
			lda	diskBlkBuf +0		;Letzter Verzeichnis-Sektor?
			bne	:101			; => Nein, weiter...

::104			ldx	DirLevel		;ROOT-Verzeichnis?
			beq	:106			; => Ja, Ende...

			lda	DirEntryTr ,x		;Zeiger auf letzte Position im
			sta	r1L			;Eltern-Verzeichnis setzen.
			lda	DirEntrySe ,x
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	ReadBlock		;Sektor wieder einlesen.
			txa				;Diskettenfehler?
			bne	:100			; => Ja, Abbruch.
			ldx	DirLevel		;Zeiger auf zuletzt geprüften
			lda	DirEntryByt,x		;Verzeichnis-Eintrag.
			sta	r4L
			dec	DirLevel		;Verschachtelung -1.
			jmp	:103			;Verzeichnis weiter testen.

::106			jmp	DoneWithIO		;I/O abschalten und Ende.

;*** Verzeichnis-Header einlesen und anpassen.
:UpdateHeader		ldx	DirLevel		;Zeiger auf Datentabelle einlesen.
			dex
			lda	DirRootTr  ,x		;Header vorheriges Verzeichnis
			inx				;als Zeiger auf Eltern-Verzeichnis
			sta	DirParentTr,x		;setzen.
			dex
			lda	DirRootSe  ,x
			inx
			sta	DirParentSe,x

			lda	r1L			;Position im Eltern-Verzeichnis
			sta	DirEntryTr ,x		;für aktuelles Verzeichnis merken.
			lda	r1H
			sta	DirEntrySe ,x
			lda	r4L
			sta	DirEntryByt,x

			ldy	#$03
			lda	(r4L),y			;Track/Sektor für neuen
			sta	r1L			;Verzeichnis-Header setzen.
			iny
			lda	(r4L),y
			sta	r1H
			LoadW	r4,fileHeader		;Zeiger auf Zwischenspeicher.
			jsr	ReadBlock		;Verzeichnis-Header einlesen.
			txa				;Diskettenfehler?
			bne	:101			; => Ja, Abbruch...

			lda	r1L			;Tr/Se für Header des aktuellen
			sta	fileHeader +32		;Verz. in Header übertragen.
			lda	r1H
			sta	fileHeader +33

			ldx	DirLevel		;Track/Sektor für Header des Eltern-
			lda	DirParentTr,x		;Verz. in Header übertragen.
			sta	fileHeader +34
			lda	DirParentSe,x
			sta	fileHeader +35

			lda	DirEntryTr ,x		;Zeiger auf zugehörigen Eltern-
			sta	fileHeader +36		;Verzeichnis-Sektor in Header
			lda	DirEntrySe ,x		;übertragen.
			sta	fileHeader +37
			lda	DirEntryByt,x		;Zeiger auf Verzeichnis-Eintrag
			clc				;in Header übertragen.
			adc	#$02			;(Byte zeigt auf Byte#0=Dateityp).
			sta	fileHeader +38

			jmp	WriteBlock		;Verzeichnis-Header schreiben.
::101			rts

;*** Meldung ausgeben: Datei beschädigt!
;Hinweis:
;XReg und r5 nicht verändern.
:infoBadFile		txa				;Fehlercode und Zeiger auf
			pha				;Verzeichnis-Eintrag sichern.
			PushW	r5

			jsr	DoneWithIO		;GEOS-Kernal einblenden.

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,txtDeleteInfo	;"Datei beschädigt..."
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,curFileName
			jsr	PutString		;Dateiname anzeigen.

			jsr	InitForIO		;Disk I/O wieder aktivieren.

			PopW	r5			;Zeiger auf Verzeichnis-Eintrag und
			pla				;Fehlercode zurücksetzen.
			tax
			rts

;*** Aktuelle Datei.
:curFileName		s 17

;*** Zwischenspeicher Verzeichnis-Sektor.
:curDirSek		b $00,$00

;*** Texte.
:txtStatusOK		b "Status: OK",NULL
if LANG = LANG_DE
:txtDeleteInfo		b "Datei beschädigt: ",NULL
endif
if LANG = LANG_EN
:txtDeleteInfo		b "File is corrupt: ",NULL
endif

;*** GeoDOS-Variablen.
:ErrorFiles		b $00				;Anzahl defekter Dateien.
:ChkNMSubD		b $00				;Unterverzeichnis-Header prüfen.
:ChkFileSize		b $ff				;Dateilängen korrigieren.
:KillErrorFile		b $00				;Defekte Dateien löschen.
:CloseFiles		b $ff				;$FF = Dateien schließen.

;*** GeoDOS/Verzeichnisse prüfen.
:DirLevel		b $00
:DirRootTr		s 16
:DirRootSe		s 16
:DirParentTr		s 16
:DirParentSe		s 16
:DirEntryTr		s 16
:DirEntrySe		s 16
:DirEntryByt		s 16
