; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; SourceCode zu geoHDscsi
; 2019/2020: Markus Kanet
; für GEOS mit MegaPatchh 64/128 V3.3+
; Schriftart: 81'Assembler
; Druckertreiber: MegaAss-100.prn
;
if .p
			t "TopSym"
			t "TopMac"
			t "Sym128.erg"

;--- Zusätzliche Labels MP3/Kernal:
			t "TopSym.MP3"
			t "TopSym.ROM"

;--- Zusätzliche Labels GEOS128:
:DB_DblBit		= $8871

;--- Spracheinstellungen.
;Der Wert für LANG wird als WORD
;definiert da der Wert mit TRUE/FALSE
;kombiniert werden muss, z.B. DEBUG.
:LANG_DE		= $4000
:LANG_EN		= $8000
:LANG			= LANG_DE

;--- Programmeinstellungen.
:TESTUI			= FALSE				;TRUE: Nur UI testen.
:TESTDLG		= FALSE				;TRUE: Dialogboxen testen.
:INFOMODE		= TRUE				;TRUE: Ohne SCSI-Geräte starten.
:PLUS			= 1				;1: CMD89-Autostart einbinden.
endif

;--- Hinweis:
;Vergleiche Variable ":applClass"!
if LANG = LANG_DE
			n "geoHDscsi"
			c "geoHDscsi   V1.020"
			h "Wechseln von Geräten am SCSI-Bus der CMD-HD. Nur GEOS-MegaPatch 64/128!"
endif
if LANG = LANG_EN
			n "geoHDscsi-en"
			c "geoHDscsiE  V1.020"
			h "Switch devices on the SCSI bus from your CMD-HD. GEOS-MegaPatch 64/128 only!"
endif

			f APPLICATION

			o APP_RAM
			p MainInit

			a "Markus Kanet"

;			z $00				;Nur 40Z-Modus.
			z $40				;40- und 80-Zeichen.
;			z $80				;Nur GEOS64.
;			z $c0				;Nur 80-zeichen.

			i
<MISSING_IMAGE_DATA>

;*** Hauptprogramm.
:MainInit		lda	curDrive		;Aktuelles Laufwerk speichern.
			sta	applDrive
			jsr	findApplication		;Anwendung suchen.
			txa				;Datei gefunden?
			bne	:0			; => Nein, weiter...

			lda	fileHeader +$90		;Eject-Flag einlesen und
			sta	ecjectMedia		;als Vorgabe festlegen.

;--- Anpassen der Dialogboxen.
::0			ldy	#$00			;Anpassung C64/C128 und
			bit	c128Flag		;40/80-Zeichen-Modus.
			bpl	:1
			bit	graphMode		;Bildschirmmodus einlesen.
			bpl	:2			; => 40-Zeichen.
			ldy	#$80			; => 80-Zeichen.
::2			sty	DB_DblBit		;Icons verdoppeln.
::1			sty	curScrnMode		;Bildschirm-Modus speichern.

			jsr	InitDBoxData		;Dialogboxen anpassen.

;--- Test des UI:
;Aufruf aller Dialogboxen zum testen
;der Größe/Position in 40/80-Zeichen.
if TESTDLG=TRUE
			jsr	testDlgBoxUI		;Dialogboxen testen.
endif

;--- Auf GEOS/MegaPatch testen.
			jsr	Test_GEOS_MP		;Auf GEOS/MegaPatch testen.
			txa				;Fehler?
			bne	ExitRegMenu		; => Ja, Abbruch...

;--- Bildschirm initialisieren.
			jsr	GetBackScreen		;Hintergrundbild laden.

if TESTUI=TRUE
			lda	#10			;Für TestUI:
			sta	devAdrHD		;Laufwerksadresse #10.
			jmp	doRegMenu
endif

;--- CMD-HD suchen/SCSI abfragen.
			jsr	findDevCMDHD		;CMD-HD unter GEOS suchen.
			cpx	#$00			;Laufwerk gefunden?
			bne	drive_found		; => Ja, weiter...

:err_no_cmdhd		lda	#<Dlg_ErrorNoHD		;Fehler: Keine CMD-HD.
			ldx	#>Dlg_ErrorNoHD
if INFOMODE=FALSE
			bne	dlg_error
:err_no_scsi		lda	#<Dlg_ErrorNoSCSI	;Fehler: Keine SCSI-Geräte.
			ldx	#>Dlg_ErrorNoSCSI
endif
:dlg_error		sta	r0L
			stx	r0H
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

;--- Zurück zum DeskTop.
:ExitRegMenu		jmp	EnterDeskTop		;Zurück zum DeskTop.

;--- Laufwerk mit SCSI-Geräten gefunden.
:drive_found		stx	devAdrHD		;Adresse CMD-HD sichern.

			LoadW	r0,IBox_Searching	;"Suche SCSI-Laufwerke..."
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

			bit	devErrorHD		;Laufwerksfehler?
			bmi	err_no_cmdhd		; => Ja, Abbruch...

;--- Hinweis:
;Falls erste CMD-HD ohne SCSI-Geräte:
;Menü trotzdem anzeigen (Info-Modus).
if INFOMODE=FALSE
			lda	scsiDevCount		;Anzahl gefundener SCSI-Geräte.
			cmp	#$02			;Weniger als zwei gefunden?
			bcc	err_no_scsi		; => Ja, Abbruch...
endif

;*** Registermenü initialisieren.
:doRegMenu		jsr	InitRegData		;Register-Menü initialisieren.

			jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			jsr	RegisterSetFont		;Register-Font aktivieren.

			lda	#<RegMenu40		;Zeiger auf 40-Zeichen-Menü.
			ldx	#>RegMenu40
			ldy	#$00
			bit	curScrnMode		;Bildschirm-Modus abfragen.
			bpl	:1			; => 40-Zeichen, weiter...
			lda	#<RegMenu80		;Zeiger auf 80-Zeichen-Menü.
			ldx	#>RegMenu80
::1			sta	r0L			;Zeiger auf Register-Menü.
			stx	r0H
			jsr	DoRegister		;Register-Menü starten.

;--- Icon-Menü "Beenden" initialisieren.
:doIconMenu		bit	curScrnMode		;Bildschirm-Modus abfragen.
			bpl	:40			; => 40-Zeichen, weiter...

::80			lda	IconExitPos80 +0	;X-Position für Farbe.
			sta	:x80

			lda	IconExitPos80 +1	;Y-Position für Farbe.
			lsr				;In CARDs umrechnen.
			lsr
			lsr
			sta	:y80

			lda	C_RegisterExit80	;Farbe für "X"-Icon setzen.
			jsr	i_UserColor
::x80			b	(R80SizeX0/8) +1
::y80			b	(R80SizeY0/8) -1
			b	IconExit_x ! DOUBLE_B
			b	IconExit_y/8

			LoadW	r0,IconMenu80		;Zeiger auf "X"-Icon-Menü.
			jmp	DoIcons			;Icon-Menü aktivieren.

::40			lda	IconExitPos40 +0	;X-Position für Farbe.
			sta	:x40

			lda	IconExitPos40 +1	;Y-Position für Farbe.
			lsr				;In CARDs umrechnen.
			lsr
			lsr
			sta	:y40

			lda	C_RegisterExit40	;Farbe für "X"-Icon setzen.
			jsr	i_UserColor
::x40			b	(R40SizeX0/8) +1
::y40			b	(R40SizeY0/8) -1
			b	IconExit_x
			b	IconExit_y/8

			LoadW	r0,IconMenu40		;Zeiger auf "X"-Icon-Menü.
			jmp	DoIcons			;Icon-Menü aktivieren.

;*** Dialogboxen an 80-Zeichen anpassen.
:InitDBoxData		bit	curScrnMode		;Bildschirm-Modus abfragen.
			bmi	:80			; => 80-Zeichen, weiter...
			rts

;--- Standard-Dialogbox:
;b $30,$8f
;w $0040,$00ff
::80			lda	dlg00T1 +1		;Links.
			ora	#>DOUBLE_W
			sta	dlg00T1 +1
			sta	dlg80_01a +1
if INFOMODE=FALSE
			sta	dlg80_02a +1
endif
			sta	dlg80_03a +1
			sta	dlg80_04a +1
			sta	dlg80_05a +1
			sta	dlg80_06a +1
			sta	dlg80_07a +1
			sta	dlg80_11a +1
			sta	dlg80_12a +1

			lda	dlg00T1 +3		;Rechts.
			ora	#>DOUBLE_W!ADD1_W
			sta	dlg00T1 +3
			sta	dlg80_01a +3
if INFOMODE=FALSE
			sta	dlg80_02a +3
endif
			sta	dlg80_03a +3
			sta	dlg80_04a +3
			sta	dlg80_05a +3
			sta	dlg80_06a +3
			sta	dlg80_07a +3
			sta	dlg80_11a +3
			sta	dlg80_12a +3

;--- Infobox:
;b $40,$6f
;w $0050,$00ef

			lda	dlg00T2 +1		;Links.
			ora	#>DOUBLE_W
			sta	dlg00T2 +1
			sta	dlg80_08a +1
			sta	dlg80_09a +1
			sta	dlg80_10a +1

			lda	dlg00T2 +3		;Rechts.
			ora	#>DOUBLE_W!ADD1_W
			sta	dlg00T2 +3
			sta	dlg80_08a +3
			sta	dlg80_09a +3
			sta	dlg80_10a +3

			rts

;*** Test des UI:
;Aufruf aller Dialogboxen zum testen
;der Größe/Position in 40/80-Zeeichen.
if TESTDLG=TRUE
:testDlgBoxUI		LoadW	r0,Dlg_NoMP
			jsr	DoDlgBox
			LoadW	r0,Dlg_SaveEject
			jsr	DoDlgBox
			LoadW	r0,Dlg_ErrSaveEject
			jsr	DoDlgBox
			LoadW	r0,Dlg_ErrorNoHD
			jsr	DoDlgBox
			LoadW	r0,Dlg_DevBlocked
			jsr	DoDlgBox
			LoadW	r0,Dlg_ErrBlkSize
			jsr	DoDlgBox
			LoadW	r0,Dlg_ErrSysPart
			jsr	DoDlgBox
			LoadW	r0,Dlg_InsertMedia
			jsr	DoDlgBox
			LoadW	r0,Dlg_ParkHDD
			jsr	DoDlgBox
			LoadW	r0,IBox_Searching
			jsr	DoDlgBox
			LoadW	r0,IBox_Testing
			jsr	DoDlgBox
			LoadW	r0,IBox_Connect
			jmp	DoDlgBox
endif

;*** Pause für UI-Test.
if TESTUI=TRUE
:testPauseUI		ldx	#10
::1			jsr	SCPU_Pause		;MegaPatch: 1/10sec Pause.
			dex				;Wartezeit abgelaufen?
			bne	:1			; => Nein, weiter...
			rts
endif

;*** Auf GEOS-MegaPatch testen.
:Test_GEOS_MP		lda	MP3_CODE +0		;MegaPatch-Kennung prüfen.
			cmp	#"M"
			bne	:1
			lda	MP3_CODE +1
			cmp	#"P"
			beq	:2

::1			LoadW	r0,Dlg_NoMP		;Kein GEOS-MegaPatch.
			jsr	DoDlgBox		;Fehler ausgeben.

			ldx	#$ff			;Fehler -> Zurück zum DeskTop.
			b $2c
::2			ldx	#$00			;Kein Fehler.
			rts

;*** Titelzeile in Dialogbox löschen.
;Verwendet für allg. Dialogboxen.
:Dlg_DrawTitel1		lda	#$00			;Füllmuster setzen.
			jsr	SetPattern
			jsr	i_Rectangle		;Titelzeile löschen.
			b	$30,$3f
:dlg00T1		w	$0040,$00ff		;Wird durch :InitDBoxData angepasst.
			lda	C_DBoxTitel		;Farbe setzen.
			jsr	DirectColor
			jmp	UseSystemFont		;Standard-Schriftart.

;*** Titelzeile in Dialogbox löschen.
;Verwendet für "Searching..."
;Verwendet für "Testing..."
;Verwendet für "Connecting..."
:Dlg_DrawTitel2		lda	#$00			;Füllmuster setzen.
			jsr	SetPattern
			jsr	i_Rectangle		;Titelzeile löschen.
			b	$40,$4f
:dlg00T2		w	$0050,$00ef		;Wird durch :InitDBoxData angepasst.
			lda	C_DBoxTitel		;Farbe setzen.
			jsr	DirectColor
			jmp	UseSystemFont		;Standard-Schriftart.

;*** HEX-Zahl nach ASCII wandeln.
;    Übergabe: AKKU = Hex-Zahl.
;    Rückgabe: AKKU/XREG = LOW/HIGH-Nibble Hex-Zahl.
:HEX2ASCII		pha				;HEX-Wert speichern.
			lsr				;HIGH-Nibble isolieren.
			lsr
			lsr
			lsr
			jsr	:1			;HIGH-Nibble nach ASCII wandeln.
			tax				;Ergebnis zwischenspeichern.

			pla				;HEX-Wert zurücksetzen und
							;nach ASCII wandeln.
::1			and	#%00001111
			clc
			adc	#"0"
			cmp	#$3a			;Zahl größer 10?
			bcc	:2			;Ja, weiter...
			clc				;Hex-Zeichen nach $A-$F wandeln.
			adc	#$07
::2			rts

;*** Dezimalzahl nach ASCII wandeln.
;    Übergabe: AKKU = Dezimal-Zahl 0-99.
;    Rückgabe: XREG/AKKU = 10er/1er Dezimalzahl.
:DEZ2ASCII		ldx	#"0"
::1			cmp	#10			;Restwert < 10?
			bcc	:2			; => Ja, weiter...
;			sec
			sbc	#10			;Restwert -10.
			inx				;10er-Zahl +1.
			cpx	#"9" +1			;10er-Zahl > 9?
			bcc	:1			; => Nein, weiter...
			dex				;Wert >99, Zahl auf
			lda	#9			;99 begrenzen.
::2			clc				;1er-Zahl nach ASCII wandeln.
			adc	#"0"
			rts

;*** Auf gültiges Zeichen prüfen.
:testChar		cmp	#" "			;ASCII < $20?
			bcs	:1			; => Nein, weiter...
			lda	#" "			;Sonderzeichen durch Leerzeichen
::2			rts				;ersetzen.

::1			cmp	#$7f			;ASCII > $7e +1?
			bcc	:2			; => Nein, Zeichen OK.
			and	#%01111111		;Bit%7 löschen und Zeichen
			jmp	testChar		;erneut testen.

;*** CMD-HD suchen.
;Hierbei wird nicht der serielle Bus
;durchsucht, sondern nur ":RealDrvType"
;von GEOS/MegaPatch ausgewertet.
;Ist in ":devAdrHD" bereits die Adresse
;einer CMD-HD (8-11) gespeichert, dann
;wird die Adresse ignoriert und eine
;weitere CMD-HD gesucht.
;Rückgabe: XREG = Adresse CMD-HD.
;                 $00 = Nicht vorhanden.
:findDevCMDHD		ldy	#4			;Max. 4 GEOS-Laufwerke prüfen.
			ldx	devAdrHD		;Aktuelles HD-Laufwerk einlesen.
			beq	:init			; => Nicht deiniert, weiter...
::loop			inx				;Zeiger auf nächste Adresse.
			cpx	#12			;Ende erreicht?
			bcc	:1			; => Nein, weiter...
::init			ldx	#8			;Start Suche ab Laufwerk 8/A.
::1			cpx	devAdrHD		;Aktuelles Laufwerk?
			beq	:exit			; => Ja, keine HD gefunden.
			dey				;Alle Laufwerke durchsucht?
			bmi	:exit			; => Ja, keine HD gefunden.

			lda	driveType -8,x		;Laufwerk definiert?
			beq	:loop			; => Nein, weiter...
			bmi	:loop			; => RAM-Laufwerk...

			lda	RealDrvType -8,x	;RealDrvType einlesen.
			bmi	:loop			; => RAM-Laufwerk...
			and	#%00110000		;CMD-Bits isolieren.
			cmp	#%00100000		;CMD-HD?
			bne	:loop			; => Nein, weiter...

			rts

::exit			ldx	#$00			;Keine weitere CMD-HD gefunden.
			rts

;*** Befehl an Laufwerk senden.
;Übergabe: AKKU/XREG = Zeiger auf Befehl.
;          YREG = Anzahl Bytes.
:sendCom		sta	r0L			;Adresse des Befehls.
			stx	r0H
			sty	r1L			;Anzahl Bytes im Befehl.

			jsr	devLISTEN		;Laufwerk auf "Empfang" schalten.
			bcs	:exit			; => Fehler, Abbruch...

			ldy	#$00
::1			lda	(r0L),y
			jsr	CIOUT			;Zeichen über IEC-Bus ausgeben.
			iny
			dec	r1L			;Alle Zeichen gesendet?
			bne	:1			; => Nein, weiter...

			jmp	UNLSN			;UNLSN auf IEC-Bus senden.

::exit			rts

;*** Daten aus HDRAM lesen.
;Übergabe: AKKU/XREG = Zeiger auf Datenspeicher.
;          YREG = Anzahl Bytes.
:readData		sta	r0L			;Adresse des Datenspeicher.
			stx	r0H
			sty	r1L			;Anzahl zu empfangender Bytes.

			jsr	devTALK			;Laufwerk auf "Senden" schalten.

			ldy	#$00
::1			jsr	ACPTR			;Byte über IEC-Bus empfangen.
			sta	(r0L),y			;Byte in Datenspeicher schreiben.
			iny
			dec	r1L			;Alle Bytes empfangen?
			bne	:1			; => Nein, weiter...

			jmp	UNTALK			;Laufwerk abschalten.

;*** Laufwerk auf LISTEN schalten.
:devLISTEN		lda	curDevice		;Aktuelle Geräteadresse.
:chkDevExist		ldx	#$00			;Fehlerstatus löschen.
			stx	STATUS

			jsr	LISTEN			;LISTEN auf IEC-Bus senden.
			lda	#$6f
			jsr	SECOND			;Sekundäradresse für IEC-Bus.

			lda	STATUS			;Fehler aufgetreten?
			clc
			bpl	:exit			; => Nein, weiter...
			jsr	UNLSN
			sec				;Laufwerksfehler.

::exit			rts

;*** Laufwerk auf TALK schalten.
:devTALK		lda	curDevice		;Aktuelle Geräteadresse.
			jsr	TALK			;TALK auf IEC-Bus senden.
			lda	#$6f
			jmp	TKSA			;Sekundäradresse für TALK.

;*** Installer für "COPYRIGHT CMD 89"
;In der PLUS-Version ist auch die
;AutoStart-Datei für die CMD-HD mit
;enthalten.
;Dadurch entfällt die Notwendigkeit
;die Datei "COPYRIGHT CMD 89" auf der
;Startpartition zu installieren.
if PLUS=1
:writeCMD89		lda	#$00			;HDRAM-Zeiger zurücksetzen.
			sta	ramAdr			; => $8E00.
::loop			jsr	wrDatHD			;16Bytes in HDRAM kopieren.
			lda	ramAdr
			clc
			adc	#$10			;Insgesamt 14*16 Bytes.
			sta	ramAdr
			cmp	#$e0			;Alle Daten übertragen?
			bcc	:loop			; => Nein, weiter...
			rts

;*** AutoStart-Code an CMDHD senden.
:wrDatHD		jsr	devLISTEN		;Laufwerk auf "Empfang" schalten.

			ldy	#$00
::1			lda	wrPrgHD,y		;"M-W"-Befehl senden.
			jsr	CIOUT			;Zeichen über IEC-Bus ausgeben.
			iny
			cpy	#$06
			bcc	:1

			ldy	ramAdr			;16 Datenbytes senden.
			ldx	#$00
::2			lda	CMD89data,y
			jsr	CIOUT			;Zeichen über IEC-Bus ausgeben.
			iny
			inx
			cpx	#$10			;Alle Datenbytes gesendet?
			bcc	:2			; => Nein, weiter...

			jmp	UNLSN			;Laufwerk abschalten.

;--- CMDHD-AutoStart-Datei.
;Am Anfang der Datei befinden sich
;2 Bytes für die Ladeadresse ($8E00)
;und 1 Byte für die Größe ($DF).
;Am Ende steht noch 1 Byte Prüfsumme.
:CMD89begin		d "COPYRIGHT CMD 89"
:CMD89data		= CMD89begin +3
:CMD89end
;---

;*** Befehl zum senden der Daten.
:wrPrgHD		b "M-W"
:ramAdr			w $8e00
			b 16
endif

;*** SCSI-Informationen einlesen.
;Informationen zu den Geräten am
;SCSI-Bus einlesen.
:callFindSCSI		lda	#$00			;Fehler-Flag löschen.
			sta	devErrorHD

			ldy	#$07			;"Aktiviert"-Status aller
;			lda	#$00			;Geräte zurücksetzen.
::1			sta	scsiEnabled,y
			dey
			bpl	:1

			lda	devAdrHD
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler?
			bne	:error

			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	scsiGetSysAdr		;Boot-Adresse/SWAP-Status abfragen.
			jsr	scsiGetCurID		;Aktuelle SCSI-ID einlesen.

			ldx	#$00
			stx	scsiDevCount		;Anzahl Geräte löschen.
::loop			stx	scsiNewID		;Aktuelle SCSI-ID.

			lda	#$ff			;Gerätedaten zurücksetzen.
			sta	scsiID,x		; => SCSI-ID.
			sta	scsiIdent,x		; => Laufwerkstyp.
			sta	scsiRemovable,x		; => Wechselmedium.
			txa				;Hinweis: Hersteller und Gerätename
			asl				;muss nicht gelöscht werden, da nur
			tay				;angezeigt wenn Gerät vorhanden.
			lda	#$00			; => Mediengröße.
			sta	scsiSize0 +0,y
			sta	scsiSize0 +1,y

			jsr	scsiCkStatRdy		;Laufwerk bereit?
			bmi	:next			; => Laufwerk nicht vorhanden.
			bne	:skip			; => Kein Medium eingelegt.

			jsr	scsiChkBlkSize		;Blockgröße testen/Größe einlesen.
			bne	:next			; => Kein Medium/Ungültig.

::skip			jsr	scsiGetDevInfo		;Geräte-Informationen einlesen.
			bmi	:next

			inc	scsiDevCount		;Anzahl Laufwerke +1.
			jsr	getDevName		;Hersteller/Gerätename übernehmen.
			jsr	getDevSize		;Mediengröße übernehmen.

::next			ldx	scsiNewID
			inx				;Zeiger auf nächste ID.
			cpx	#8			;Alle IDs überprüft?
			bcs	:exit			; => Ja, Ende...
			jmp	:loop			; => Weitersuchen...

::exit			jsr	DoneWithIO		;I/O-Bereich abschalten.

;--- Kein Fehler.
			ldx	#$00
			b $2c

;--- Fehler beim aktivieren der CMD-HD.
::error			ldx	#$ff
			stx	devErrorHD		;Fehler-Flag setzen.
			rts

;*** Systempartition suchen.
:callFindSysP		jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	scsiChkSysPart		;Systempartition testen.

			jsr	DoneWithIO		;I/O-Bereich abschalten.

			stx	devErrorHD		;Fehler-Flag setzen.
			rts

;*** SCSI-Gerät wechseln.
:callSwitchDev		jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

;--- Programm in HD-RAM installieren.
;Hierbei wird die CMD-AutoStart-Datei
;"COPYRIGHT CMD 89" im RAM der CMD-HD
;installiert. Diese Datei wird dann
;nicht mehr auf der Startpartition
;benötigt.
if PLUS=1
			jsr	writeCMD89		;AUTOSTART-Code installieren.
endif

			ldx	scsiNewID
			lda	scsiIdent,x		;Ist Gerät eine Festplatte?
			bne	:1			; => Nein, weiter...

;--- Evtl. geparkte HDD starten.
			jsr	scsiCkStatRdy		;Ist Laufwerk bereit?
			beq	:1			; => Ja, weiter...

			jsr	scsiStartUNIT		;Festplatte starten.

::1			lda	scsiNewID		;SCSI-ID in Programm für CMD-HD
			sta	comSWITCH_lda +1	;übernehmen.
			lda	#<comSWITCH		;Programm in HDRAM übertragen.
			ldx	#>comSWITCH
			ldy	#11
			jsr	sendCom
			lda	#<comEXECUTE		;Programm im HDRAM ausführen.
			ldx	#>comEXECUTE		;Hierbei wird eine Routine aus dem
			ldy	#5			;AUTOSTART-Code ausgeführt.
			jsr	sendCom

;--- Ggf. Geräteadressen korrigieren.
			lda	bootAdrHD
			cmp	curDevice		;Boot-Adresse HD = GEOS-Adresse?
			beq	:wait			; => Ja, weiter...

			sta	curDevice		;Boot-Adresse als aktuelles Gerät.

			lda	bootSwapHD		;War SWAP-Taste gedrückt?
			bpl	:2			; => Nein, weiter...

			and	#%01111111		;Geräteadresse 8/9 aus SWAP-Status
			pha				;ermitteln.
			clc
			adc	#"0"
			sta	comSWAP89 +2		;SWAP-Befehl definieren.
			lda	#<comSWAP89		;SWAP-Befehl an Laufwerk senden.
			ldx	#>comSWAP89
			ldy	#3
			jsr	sendCom

			pla
			sta	curDevice		;SWAP-Adresse als aktuelles Gerät.

::2			lda	devAdrHD
			cmp	curDevice		;Aktuelle Adresse HD = GEOS-Adresse?
			beq	:pause			; => Ja, weiter...

			lda	curDrive
			sta	comSWAPX +3		;"U0>x"-Befehl definieren.
			lda	#<comSWAPX		;"U0>x"-Befehl an Laufwerk senden.
			ldx	#>comSWAPX
			ldy	#4
			jsr	sendCom

			lda	curDrive		;GEOS-Laufwerk als aktuelles Gerät.
			sta	curDevice

;--- Pause für SWAP-Befehl...
;Ohne diese Pause von ca.2sec hängt
;sich die CMD-HD auf. Der Wert ist
;angelehnt an SCSIConnect.
::pause			ldx	#20
::3			jsr	SCPU_Pause		;MegaPatch: 1/10sec Pause.
			dex				;Wartezeit abgelaufen?
			bne	:3			; => Nein, weiter...

::wait			jsr	scsiCkStatRdy		;Ist Laufwerk bereit?
			bmi	:wait			; => Nein, weiter warten...

			jsr	scsiChkBlkSize		;Mediengröße einlesen und in
			jsr	getDevSize		;Register-Menü übernehmen.

;--- CMD89 in HD-RAM installieren.
;Nach dem RESET ist der AUTOSTART-Code
;nicht mehr im Speicher der CMD-HD.
;Durch das erneute installieren wird
;das vorhandensein der Datei auf der
;Standardpartition nach einem RESET
;für andere Programme simuliert.
if PLUS=1
			jsr	writeCMD89		;AUTOSTART-Code installieren.
endif

			jmp	DoneWithIO		;I/O-Bereich abschalten.

;*** Boot-/SWAP-Adresse CMD-HD.
:scsiGetSysAdr		lda	#<comGETADR
			ldx	#>comGETADR
			ldy	#6
			jsr	sendCom			;Daten aus CMD-HD auslesen.
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Byte über IEC-Bus empfangen.
			sta	bootAdrHD		;Boot-Adresse CMD-HD einlesen.
			jsr	ACPTR			;Dummy-Byte über IEC-Bus empfangen.
			jsr	ACPTR			;Dummy-Byte über IEC-Bus empfangen.
			jsr	ACPTR			;Byte über IEC-Bus empfangen.
			sta	bootSwapHD		;SWAP-Status CMD-HD einlesen.
			jmp	UNTALK			;Laufwerk abschalten.

;*** Aktuelle SCSI-ID einlesen.
:scsiGetCurID		lda	#<comGETID
			ldx	#>comGETID
			ldy	#6
			jsr	sendCom
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;SCSI-ID über IEC-Bus empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			lsr				;SCSI-ID in Zeiger auf
			lsr				;Gerätetabelle umwandeln.
			lsr
			lsr
			tax
			lda	#$ff
			sta	scsiEnabled,x		;Aktuelles Gerät = "Aktiv".
			stx	devAdrHD_ID		;Geräte-ID speichern.
			rts

;*** SCSI-Geräte auf "READY" testen.
;Rückgabe: AKKU = $00/$02 READY.
;               > $80 Not READY.
:scsiCkStatRdy		lda	scsiNewID		;Neue SCSI-ID einlesen und
			sta	scsiREADY_id		;für SCSI-Befehl "READY" speichern.

			lda	#<scsiREADY		;SCSI-Befehl "UNIT READY" zur
			ldx	#>scsiREADY		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiREADY
			ldx	#>scsiREADY
			ldy	#12
			jsr	sendCom
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Byte über IEC-Bus empfangen.
			ldx	scsiNewID
			sta	scsiErrByte,x		;Fehlerbyte zwischenspeichern.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			rts

;*** Blockgröße testen.
:scsiChkBlkSize		jsr	scsiGetCapacity		;SCSI-Befehl "READ CAPACITY".

			ldx	scsiDataBuf8 +6		;High-Byte Blockgröße.
			lda	scsiDataBuf8 +7		;Low-Byte Blockgröße.
			bne	:error
			cpx	#$02			;Blockgröße 512 Bytes?
			bne	:error			; => Nein, Fehler...

			ldx	#$00			;Blockgröße = 512 Bytes.
			rts

::error			ldx	#$ff			;Blockgröße <> 512 Bytes.
			rts

;*** Mediengröße einlesen.
:scsiGetCapacity	lda	scsiNewID		;Neue SCSI-ID einlesen und für
			sta	scsiCAPACITY_id		;SCSI-Befehl "CAPACITY" speichern.

			lda	#<scsiCAPACITY		;SCSI-Befehl "READ CAPACITY" zur
			ldx	#>scsiCAPACITY		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiCAPACITY
			ldx	#>scsiCAPACITY
			ldy	#12
			jsr	sendCom

			lda	#<scsiCAPACITY_mr	;Laufwerksbefehl "M-R".
			ldx	#>scsiCAPACITY_mr
			ldy	#6
			jsr	sendCom
			lda	#<scsiDataBuf8		;Ergebniss von "READ CAPACITY"
			ldx	#>scsiDataBuf8		;aus dem RAM der CMD-HD einlesen.
			ldy	#8
			jmp	readData

;*** Geräte-Informationen einlesen.
:scsiGetDevInfo		lda	scsiNewID		;Neue SCSI-ID einlesen und für
			sta	scsiINQUIRY_id		;SCSI-Befehl "INQUIRY" speichern.

			lda	#<scsiINQUIRY		;SCSI-Befehl "INQUIRY" zur
			ldx	#>scsiINQUIRY		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiINQUIRY
			ldx	#>scsiINQUIRY
			ldy	#12
			jsr	sendCom

			lda	#<scsiINQUIRY_mr	;Laufwerksbefehl "M-R".
			ldx	#>scsiINQUIRY_mr
			ldy	#6
			jsr	sendCom
			lda	#<scsiDataBuf24		;Ergebniss von "INQUIRY"
			ldx	#>scsiDataBuf24		;aus dem RAM der CMD-HD einlesen.
			ldy	#36
			jsr	readData

			lda	scsiDataBuf24 +0	;"DEVICE TYPE" einlesen.
			and	#%00011111		;Nur Bit%0-%4 relevant.
			tax
			cpx	#$08			;"DEVICE TYPE" > 8?
			bcs	:not_supported		; => Ja, nich unterstützt.

			lda	scsiTypes,x		;Interne Geräteklasse einlesen.
			bmi	:not_supported		; => $FF: Nicht unterstützt.
			bne	:1			; => Keine Festplatte.

			bit	scsiDataBuf24 +1	;Laufwerk mit Wechselmedium?
			bpl	:1			; => Nein, weiter...
			lda	#$01			; => IomegaZIP.

::1			ldx	scsiNewID
			sta	scsiIdent,x		;Geräteklasse speichern.
			txa
			sta	scsiID,x		;Geräte-ID speichern.
			lda	scsiDataBuf24 +1	;$00 = Fest, $80 = Wechselmedium.
			sta	scsiRemovable,x		;Wechselmedium-Flag speichrn.

			ldx	#$00			;Gültiges Gerät erkannt.
			rts

::not_supported		ldx	#$ff			;Gerät nicht unterstützt.
			rts

;*** SCSI-Gerät starten.
;Rückgabe: AKKU = $00: OK.
:scsiStartUNIT		lda	scsiNewID		;Neue SCSI-ID einlesen und für
			sta	scsiSTARTUNIT_id	;SCSI-Befehl "START UNIT" speichern.

			lda	#<scsiSTARTUNIT		;SCSI-Befehl "START UNIT" zur
			ldx	#>scsiSTARTUNIT		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiSTARTUNIT
			ldx	#>scsiSTARTUNIT
			ldy	#12
			jsr	sendCom
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Byte über IEC-Bus empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			rts

;*** SCSI-Gerät anhalten.
;Bei Wechselmedien -> Medium auswerfen.
:scsiStopUNIT		ldx	devAdrHD_ID		;Neue SCSI-ID einlesen und für
			stx	scsiSTOPUNIT_id		;SCSI-Befehl "STOP UNIT" speichern.

			ldy	scsiIdent,x		;Geräteklasse einlesen.
			lda	scsiEjMode,y		;EJECT-Mode für "STOP UNIT" prüfen.
			beq	:1			; => Nicht auswerfen, weiter...
			bit	ecjectMedia		;Medium auswerfen?
			bmi	:1			; => Ja, weiter...
			lda	#$01			;Medium laden/nicht auswerfen.
::1			sta	scsiSTOPUNIT_ej		;EJECT-Mode speichern.

			lda	#<scsiSTOPUNIT		;SCSI-Befehl "STOP UNIT" zur
			ldx	#>scsiSTOPUNIT		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiSTOPUNIT
			ldx	#>scsiSTOPUNIT
			ldy	#12
			jsr	sendCom
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Byte über IEC-Bus empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			rts

;*** Systempartition suchen.
:scsiChkSysPart		jsr	scsiCkStatRdy		;Ist Laufwerk bereit?
			bmi	:exit			; => Laufwerk nicht vorhanden.
			beq	:ok

			jsr	scsiStartUNIT		;Geparkte HDD aktivieren.

			jsr	scsiCkStatRdy		;Ist Laufwerk bereit?
			bne	:exit			; => Laufwerk nicht bereit.

::ok			jsr	scsiChkBlkSize		;Blockgröße/Mediengröße einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	scsiNewID		;Neue SCSI-ID einlesen und
			sta	scsiREAD_id		;für SCSI-Befehl "READ" speichern.

			lda	#$00			;Adresse des ersten Datensektors
			ldx	#$02			;der eingelesen werden soll.
			sta	scsiREAD_adr +0		;Die Suche beginnt ab dem 2ten
			sta	scsiREAD_adr +1		;512Byte-Datensektor.
			sta	scsiREAD_adr +2
			stx	scsiREAD_adr +3

			sta	r1H			;Sektorzähler initialisieren.

::loop			lda	#<scsiREAD		;SCSI-Befehl "READ".
			ldx	#>scsiREAD
			ldy	#16
			jsr	sendCom

			lda	#<scsiREAD_mr		;Laufwerksbefehl "M-R".
			ldx	#>scsiREAD_mr		;Der Sektor liegt ab $4000 im
			ldy	#6			;RAM der CMD-HD.
			jsr	sendCom
			lda	#<scsiDataBuf16		;Prüfbytes aus dem RAM der CMD-HD
			ldx	#>scsiDataBuf16		;einlesen (16Bytes).
			ldy	#16
			jsr	readData

			ldx	#16			;Daten Systempartition vergleichen.
::chk			lda	scsiDataBuf16 -1,x
			cmp	codeSysPartHD -1,x
			bne	:next			;Nicht gefunden, weiter...
			dex				;Alle 16 Bytes überprüft?
			bne	:chk			; => Nein, weiter...

;			ldx	#$00			;OK: Systempartition gefunden!
::exit			rts

::next			dec	r1H			;Sektorzähler korrigieren.
			beq	:not_found		; => 256 Sektoren durchsucht, Ende.

			jsr	blkReadNx128		;Zeiger auf nächsten Sektor.
			jsr	chkEndOfDisk		;Ende Medium erreicht?
			bcc	:loop			; => Nein, weitersuchen...

::not_found		ldx	#$7f			;Fehler: Keine Systempartition!
			rts

;*** SCSI-Blockadresse erhöhen.
;Dabei werden 128 Sektoren a 512Bytes
;übersprungen = 64Kb.
;Die Systempartition kann nur innerhalb
;eines 64Kb Speicherbereichs beginnen.
;256 Testvorgänge a 64Kb entsprechen
;16Mb, d.h. es werden nur die ersten
;Bereiche des Mediums durchsucht.
:blkReadNx128		lda	#$80
			clc
			adc	scsiREAD_adr +3
			sta	scsiREAD_adr +3
			bcc	:1
			inc	scsiREAD_adr +2
			bne	:1
			inc	scsiREAD_adr +1
			bne	:1
			inc	scsiREAD_adr +0
::1			rts

;*** SCSI-Blockadresse testen.
;Die Routine überprüft ob die aktuelle
;SCSI-Blockadresse noch innerhalb des
;Mediums liegt.
;:scsiREAD_adr = Aktueller Sektor.
;:scsiDataBuf8 = "READ CAPACITY"-Daten.
:chkEndOfDisk		lda	scsiREAD_adr +0
			cmp	scsiDataBuf8 +0
			bne	:1
			lda	scsiREAD_adr +1
			cmp	scsiDataBuf8 +1
			bne	:1
			lda	scsiREAD_adr +2
			cmp	scsiDataBuf8 +2
			bne	:1
			lda	scsiREAD_adr +3
			cmp	scsiDataBuf8 +3
::1			rts

;*** Kennung für CMD-HD Systempartition.
:codeSysPartHD		b "CMD HD  "
			sta	$8803
			stx	$8802
			nop
			rts

;*** Laufwerksdaten einlesen.
:getDevName		lda	scsiNewID		;Zeiger auf Textspeicher für
			asl				;Hersteller und Gerätename setzen.
			asl
			tay
			ldx	#0
::1			lda	scsiNameTab +0,y
			sta	r2L,x
			iny
			inx
			cpx	#4
			bcc	:1

			ldx	scsiNewID		;Geräte-Klasse in Text wandeln.
			lda	scsiIdent,x
			asl
			asl
			tax
			ldy	#0
::2			lda	scsiTypeTx,x
			sta	(r2L),y
			inx
			iny
			cpy	#3
			bne	:2

			lda	#":"			;Trennung Geräte-Klasse und
			sta	(r2L),y			;Herstellername.
			iny

			ldx	#0
;			ldy	#4			;Herstellername einlesen.
::3			lda	scsiDataBuf24 +8,x
			jsr	testChar		;Nur gültige ASCII Zeichen einlesen.
			sta	(r2L),y			;Zeichen in Speicher übernehmen.
			iny
			inx
			cpx	#8
			bcc	:3

			ldy	#0			;Gerätename einlesen.
::4			lda	scsiDataBuf24 +16,y
			jsr	testChar		;Nur gültige ASCII Zeichen einlesen.
			sta	(r3L),y			;Zeichen in Speicher übernehmen.
			iny
			cpy	#16
			bcc	:4

			rts

;*** Mediengröße ermitteln.
:getDevSize		ldy	#3			;Kapazität von 128-MByte-Blocks
::1			lsr	scsiDataBuf8 +0		;nach MByte umrechnen.
			ror	scsiDataBuf8 +1		;Byte #1/#2 enhalten dann die Größe
			ror	scsiDataBuf8 +2		;in MByte im High/Low-Format.
			dey				;Byte #0 muß $00 sein, sonst ist
			bne	:1			;das Medium > 65535 MByte.
							;Byte #3 entfällt.

			lda	scsiNewID
			tay				;Zeiger Geräte-ID.
			asl
			tax				;Zeiger auf Speicher Mediengröße.

			lda	scsiErrByte,y		;Medium im Laufwerk?
			bne	:no_media		; => Nein, weiter...

			lda	scsiDataBuf8 +0		;Mehr als 65535 MByte?
			beq	:normal_media		; => Nein, weiter...

;--- Medium zu groß.
::large_media		lda	#$ff			;Größe auf "65535"($FFFF) begrenzen.
			tay
			bne	:set_media_size

;--- Kein Medium.
::no_media		lda	#$00			;Größe auf "0"(Kein Medium) setzen.
			tay
			beq	:set_media_size

;--- Größe einlesen.
::normal_media		lda	scsiDataBuf8 +1		;Größe im High/Low-Format setzen.
			ldy	scsiDataBuf8 +2

;--- Größe speichern.
::set_media_size	sta	scsiSize0 +1,x
			tya
			sta	scsiSize0 +0,x
			rts

;*** Registerkarte initialisieren.
;Wird auch beim wechseln der CMD-HD
;aufgerufen -> HD-Info aktualisieren.
:InitRegData		lda	devAdrHD		;Adresse CMD-HD in Text wandeln.
			clc
			adc	#"A" -$08
			sta	scsiHDInfo_ga

			lda	bootAdrHD		;Boot-Adresse der CMD-HD in
			jsr	DEZ2ASCII		;Text wandeln.
			cpx	#"0"			;Zahl >= 10?
			bne	:1			; => Ja, weiter...
			tax				;Einstellige Geräte-Adresse.
			lda	#" "
::1			stx	scsiHDInfo_sa +0	;10er.
			sta	scsiHDInfo_sa +1	;1er.

			bit	curScrnMode		;Bildschirm-Modus abfragen.
			bmi	InitOptMode		; => 80-Zeichen, weiter...

;--- 40-Zeichen:
;Seitendaten in Register-Menü kopieren.
			lda	regMenuPage		;Daten für Register-Menü Seite #1/#2
			asl				;in Systemtabelle übertragen.
			tay
			lda	regMenuPTab +0,y
			sta	r0L
			lda	regMenuPTab +1,y
			sta	r0H
			LoadW	r1,RTabMenu40_opt
			LoadW	r2,RTabMenu1_1len
			jsr	MoveData

;*** Checkboxen für Menü definieren.
;Ein aktives oder nicht vorhandenes
;Gerät kann nicht ausgewählt werden.
:InitOptMode		bit	curScrnMode		;Bildschirm-Modus abfragen.
			bmi	:80			; => 80-Zeichen, weiter...

::40			lda	regMenuPage		;Aktuelle Register-Seite in
			asl				;Zeiger auf erste Checkbox
			asl				;umrechnen.
			tay
			lda	#$04
			sta	r0L
			LoadW	:adr +1,RTabMenu40_opt
			jmp	:init

::80			ldy	#$00			;80-Zeichen: Nur eine Seite.
			lda	#$08
			sta	r0L
			LoadW	:adr +1,RTabMenu80_opt

::init			lda	#$00			;Zähler für Geräte 1-X der
			sta	r0H			;aktuellen Seite löschen.

::loop			ldx	r0H
			lda	regMenuETab,x		;Zeiger auf Menü-Eintrag des
			tax				;aktuellen Laufwerks.

			lda	scsiID,y		;SCSI-ID einlesen.
			bmi	:disable		; => $FF: Gerät nicht vorhanden.
			lda	scsiEnabled,y		;Ist das Gerät aktuell aktiv?
			beq	:enable			; => Nein, weiter...

::disable		lda	#BOX_OPTION_VIEW	;Modus für Checkbox: Nur anzeigen.
			b $2c
::enable		lda	#BOX_OPTION		;Modus für Checkbox: Ändern.
::adr			sta	RTabMenu40_opt,x	;Register-Option definieren.

			inc	r0H			;Zeiger auf nächste Zeile.

			iny
			dec	r0L			;Ende der Seite erreicht?
			bne	:loop			; => Nein, weiter...

::end			rts

;*** SCSI-Name ausgeben.
:PutScsiName0		ldx	#0
			b $2c
:PutScsiName1		ldx	#1
			b $2c
:PutScsiName2		ldx	#2
			b $2c
:PutScsiName3		ldx	#3
			b $2c
:PutScsiName4		ldx	#4
			b $2c
:PutScsiName5		ldx	#5
			b $2c
:PutScsiName6		ldx	#6
			b $2c
:PutScsiName7		ldx	#7

			lda	scsiID,x		;Ist Gerät verfügbar?
			bmi	:exit			; => Nein, Ende...

			txa				;Zeiger auf Tabelle mit der
			asl				;Speicheradresse für die beiden
			asl				;Textzeilen #1/#2 berechnen.
			tay

			lda	scsiNameTab +0,y	;Adresse Textzeile #1 einlesen.
			sta	r0L
			lda	scsiNameTab +1,y
			sta	r0H

			lda	scsiNameTab +2,y	;Adresse Textzeile #2 speichern.
			pha
			lda	scsiNameTab +3,y
			pha

			PushW	r11			;X-Koordinate sichern.

			jsr	PutString		;Textzeile #1 ausgeben.

			PopW	r11			;X-Koordinate zurücksetzen.

			lda	r1H			;Y-Koordinate Zeile #2 berechnen.
			clc
			adc	#$08
			sta	r1H

			pla				;Adresse Textzeile #2 setzen.
			sta	r0H
			pla
			sta	r0L
			jmp	PutString		;Textzeile #2 ausgeben.

;--- Text "(Kein Gerät)" ausgeben.
::exit			LoadW	r0,scsiNoDevice		;Hinweistext ausgeben.
			jmp	PutString

;*** "Eject-Flag" speichern.
:RMenuSaveEject		jsr	findApplication		;Anwendung suchen.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			lda	ecjectMedia		;Eject-Flag in Infoblock speichern.
			sta	fileHeader +$90

			lda	dirEntryBuf +19		;Tr/Se Infoblock.
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,fileHeader		;Zeiger auf Infoblock.
			jsr	PutBlock		;Infoblock speichern.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			LoadW	r0,Dlg_SaveEject
			jsr	DoDlgBox		;"Einstllung gespeichert".
			jmp	:exit

::error			LoadW	r0,Dlg_ErrSaveEject
			jsr	DoDlgBox		;"Einstllung nicht gespeichert".

::exit			lda	devAdrHD		;Laufwerk zurücksetzen.
			jsr	SetDevice
			jmp	PurgeTurbo

;*** Anwendung suchen.
:findApplication	lda	applDrive
			jsr	SetDevice		;Startlaufwerk aktivieren.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			jsr	OpenDisk		;Diskette öffnen.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			LoadB	r7L,APPLICATION
			LoadB	r7H,1
			LoadW	r10,applClass
			LoadW	r6,applName
			jsr	FindFTypes		;Anwendung/GEOS-Klasse suchen.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			lda	r7H			;Datei gefunden?
			bne	:error			; => Nein, Abbruch...

			LoadW	r6,applName
			jsr	FindFile		;Verzeichniseintrag einlesen.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			LoadW	r9,dirEntryBuf
			jsr	GetFHdrInfo		;Infoblock einlesen.
::error			rts

;*** 40-Zeichen: Seite wechseln.
:RMenuSlctPage		lda	regMenuPage		;Aktuell nur zwei Seiten:
			eor	#%00000001		;Aktuelle Seite invertieren.
			sta	regMenuPage

			jsr	InitRegData		;Daten für neue Seite aktualisieren.
			jmp	RegisterNextOpt		;Registerkarte aktualisieren.

;*** Neue CMD-HD auswählen.
:RMenuSlctHD		bit	r1L			;Aufbau Registermenü?
			bmi	:1			; => Nein, weiter...
			LoadW	r0,scsiHDInfo		;Nur HD-Info ausgeben.
			jmp	PutString

::1			lda	#4			;Zähler für Laufwerkssuche.
			sta	cntDrvHDerr

			lda	devAdrHD		;Aktuelle HD-Adresse sichern.
			sta	bakAdrHD

::loop			jsr	findDevCMDHD		;Weitere CMD-HD suchen.
			cpx	#$00			;Weiteres Laufwerk gefunden?
;--- Hinweis:
;Aktuell wird bei nur einer CMD-HD die
;aktuelle Seite aktualisiert.
;			beq	:exit			; => Nein, Ende...
			bne	:2			; => Ja, weiter...

			stx	cntDrvHDerr
			ldx	bakAdrHD
::2			stx	devAdrHD		;Neue GEOS-Adresse CMD-HD setzen.

::reset			LoadW	r0,IBox_Searching
			jsr	DoDlgBox		;SCSI-Geräte suchen.

			lda	cntDrvHDerr		;Alle Laufwerke durchsucht?
			beq	:reload_page		; => Ja, Abbruch...

;--- Hinweis:
;Es gibt mind. eine gültige CMD-HD, da
;das Register-Menü bereits aufgebaut
;wurde. Wenn die zweite CMD-HD einen
;Fehler meldet, dann wird hier die
;nächste bzw. irgendwann auch wieder
;die erste CMD-HD gefunden.
			bit	devErrorHD		;Fehler?
			bpl	:reload_page		; => Nein, weiter...

			dec	cntDrvHDerr		;Alle Laufwerke durchsucht?
			bne	:loop			; => Ja, Abbruch...

			lda	bakAdrHD		;Auf letzte CMD-HD
			sta	devAdrHD		;zurücksetzen.
			jmp	:reset			; => Daten einlesen, dann Abbruch...

::reload_page		lda	#$00			;Auf Seite #1 zurücksetzen.
			sta	regMenuPage

			jsr	InitRegData		;Daten für neue Seite aktualisieren.
			jmp	RegisterNextOpt		;Registerkarte aktualisieren.

::exit			rts

;*** Neue SCSI wählen.
:RMenuSlctDv1		ldx	#$00			;Gerät #0/#4 aktivieren.
			b $2c
:RMenuSlctDv2		ldx	#$01			;Gerät #1/#5 aktivieren.
			b $2c
:RMenuSlctDv3		ldx	#$02			;Gerät #2/#6 aktivieren.
			b $2c
:RMenuSlctDv4		ldx	#$03			;Gerät #3/#7 aktivieren.
			b $2c
:RMenuSlctDv5		ldx	#$04			;Gerät #4 aktivieren (80-Zeichen).
			b $2c
:RMenuSlctDv6		ldx	#$05			;Gerät #5 aktivieren (80-Zeichen).
			b $2c
:RMenuSlctDv7		ldx	#$06			;Gerät #6 aktivieren (80-Zeichen).
			b $2c
:RMenuSlctDv8		ldx	#$07			;Gerät #7 aktivieren (80-Zeichen).
			cpx	#$04
			bcs	:80

			stx	r0L
			lda	regMenuPage		;Zeiger auf SCSI-Gerät berechnen.
			asl
			asl
			clc
			adc	r0L
			tax

::80			lda	scsiEnabled,x		;Wurde Laufwerk ausgewählt?
			bpl	:not_supported		; => Nein, Abbruch...

			lda	scsiID,x		;Ist Gerät verfügbar?
			bpl	:init			; => Nein, Abbruch...
::not_supported		jmp	:exit

;--- Laufwerk testen...
::init			stx	scsiNewID		;Als neues SCSI-Gerät festlegen.

if TESTUI = FALSE
			jsr	testDevAdrHD		;Ist Boot-Adresse der CMD-HD
			bne	:not_supported		;aktuell belegt? => Ja, Abbruch...

			jsr	testMediaReady		;Medium eingelegt?

			lda	devErrorHD		;Auf "Abbruch" Dialogbox testen.
			bne	:not_supported		; => Abbruch.

			LoadW	r0,IBox_Testing		;Systempartition testen.
			jsr	DoDlgBox		;(Unterprogramm in Dialogbox).

			lda	devErrorHD		;Fehler-Flag abfragen.
			bmi	:errBlkSize		; => Falsche Blockgröße.
			bne	:errSysPart		; => Keine Systempartition.

			LoadW	r0,IBox_Connect		;SCSI-Gerät aktivieren.
			jsr	DoDlgBox		;(Unterprogramm in Dialogbox).

			jsr	testStopDevice		;HDD parken / Medium auswerfen.
endif

			lda	devAdrHD		;Adresse CMD-HD.
			jsr	SetDevice		;Laufwerk aktivieren.

if TESTUI = FALSE
			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			LoadW	r0,comInitDisk		;"I0:"-Befehl senden.
			LoadB	r2L,4			;Bei einer CMD-HD mit einem externen
			jsr	SendFloppyCom		;SCSI-Laufwerk wird damit bei einem
			jsr	UNLSN			;Medien-Wechsel die Partitions-
							;tabelle von Disk neu eingelesen.

			jsr	DoneWithIO		;I/O-Bereich abschalten.
endif

			jsr	OpenDisk		;Diskette öffnen.
							;Hinweis: Bei der CMD-HD kann es
							;unter Umständen passieren, das die
							;interne Partitionstabelle korrupt
							;ist. OpenDisk ruft die interne
							;Routine "LogNewPart" auf, welche
							;dann eine gültige Partition sucht
							;und aktiviert.

			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			ldy	#$07			;"Aktiviert"-Status aller
			lda	#$00			;Geräte zurücksetzen.
::1			sta	scsiEnabled,y
			dey
			bpl	:1

if TESTUI = TRUE
			ldx	scsiNewID		;Aktivieren der Checkbox wieder
			lda	#$ff
			sta	scsiEnabled,x		;rückgängig machen.
endif

if TESTUI = FALSE
			jsr	scsiGetCurID		;Aktuelle SCSI-ID einlesen.

			jsr	getPartInfo		;Aktuelle Partition abfragen.
endif

			jsr	DoneWithIO		;I/O-Bereich abschalten.

if TESTUI = FALSE
			jsr	testPartition		;Prüfen ob akt. Partition gültig.
endif

			jsr	InitOptMode		;Daten für neue Seite aktualisieren.
			jmp	RegisterNextOpt		;Registerkarte aktualisieren.

;--- Fehler: Keine Systempartition.
::errSysPart		LoadW	r0,Dlg_ErrSysPart
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			jmp	:exit

;--- Fehler: Blockgröße nicht 512Bytes.
::errBlkSize		LoadW	r0,Dlg_ErrBlkSize
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

;--- Fehler: Zurück zum Register-Menü.
::exit			ldx	scsiNewID		;Aktivieren der Checkbox wieder
			inc	scsiEnabled,x		;rückgängig machen.

			jsr	InitOptMode		;Daten für neue Seite aktualisieren.
			jmp	RegisterNextOpt		;Registerkarte aktualisieren.

;*** Prüfen ob BootAdr CMD-HD belegt.
;Beim wechseln des SCSI-Gerätes wird
;ein Reset an der CMD-HD ausgeführt.
;Dadurch wird das Laufwerk auf die
;Standard-Geräteadresse zurückgesetzt.
;Wenn diese Adresse aber aktuell durch
;ein anderes Gerät belegt ist (z.B.
;durch tauschen von Geräten über den
;GEOS.Editor) dann würden nach dem
;Reset zwei Geräte die gleiche Adresse
;verwendet.
; => Wechseln dann nicht möglich!
:testDevAdrHD		lda	bootAdrHD		;Boot-Adresse der CMD-HD einlesen.
			cmp	#12			;Adr. größer 8-11?
			bcs	:1			; => Ja, weiter...

			cmp	curDrive		;Boot-Adresse = aktuelles Laufwerk?
			bne	:1			; => Nein, weiter...

::0			ldx	#$00			;Laufwerk kann gewechselt werden.
			rts

::1			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.
			lda	bootAdrHD
			jsr	chkDevExist		;Existiert ein Gerät am ser.Bus mit
			php				;der Boot-Adresse der CMD-HD?
			jsr	UNLSN
			jsr	DoneWithIO		;I/O-Bereich abschalten.
			plp
			bcs	:0			; => Nein, Kein Fehler.

			LoadW	r0,Dlg_DevBlocked
			jsr	DoDlgBox		;Fehler: Adresse aktuell belegt.

			ldx	#$ff			;Fehler: Wechseln nicht möglich!
			rts

;*** Auf Medium in Laufwerk warten.
:testMediaReady		ldx	scsiNewID		;Aktuelles Gerät einlesen.
			lda	scsiIdent,x		;Ist SCSI-Gerät = Festplatte?
			beq	:exit			; => Ja, weiter...

			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	scsiCkStatRdy		;Ist Laufwerk bereit?

			pha
			jsr	DoneWithIO		;I/O-Bereich abschalten.
			pla
			beq	:exit			; => Laufwerk bereit, weiter...

			LoadW	r0,Dlg_InsertMedia
			jsr	DoDlgBox		;"Bitte Medium einlegen!"

			lda	sysDBData		;Rückmeldung Dialogbox einlesen.
			cmp	#OK			;"OK" gedrückt?
			beq	testMediaReady		; => Ja, weiter...

;--- Fehler: ein Medium/Abbruch.
			ldx	#$ff
			b $2c

;--- Laufwerk bereit.
::exit			ldx	#$00
			stx	devErrorHD		;Fehler-Flag setzen.
			rts

;*** HDD parken/Medium auswerfen.
:testStopDevice		ldx	devAdrHD_ID		;Aktuelle SCSI-ID einlesen.
			lda	scsiIdent,x		;Ist Gerät eine Festplatte?
			bne	:1			; => Nein, weiter...

			LoadW	r0,Dlg_ParkHDD
			jsr	DoDlgBox		;Frage: "Festplatte parken?"

			lda	sysDBData		;Rückmeldung Dialogbox einlesen.
			cmp	#YES			;"Ja" geählt?
			bne	:2			; => Nein, weiter...

;--- Medium auswerfen oder HDD parken.
::1			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	scsiStopUNIT		;Laufwerk deaktivieren.

			jsr	DoneWithIO		;I/O-Bereich abschalten.

::2			rts

;*** Partitionsinformationen abfragen.
:getPartInfo		lda	#<comGETPART		;SCSI-Befehl "READ".
			ldx	#>comGETPART
			ldy	#4
			jsr	sendCom
			lda	#<curPartInfo		;Prüfbytes aus dem RAM der CMD-HD
			ldx	#>curPartInfo		;einlesen (16Bytes).
			ldy	#31
			jsr	readData

			ldx	curPartInfo		;Partitionstyp einlesen und
			beq	:2			;von CMD nach GEOS wandeln.
			dex
			bne	:1
			ldx	#$04
::1			cpx	#$05
			bcc	:2
			ldx	#$00
::2			stx	curPartInfo
			rts

;*** Partition auf Gültigkeit testen.
:testPartition		lda	curPartInfo		;Partitionstyp einlesen und
			cmp	curType			;Partition GEOS-kompatibel?
			beq	:end			; => Ja, weiter...

			LoadW	r0,Dlg_SlctPart		;Neue Partition auswählen.
			LoadW	r5,partName
			jsr	DoDlgBox

::end			rts

;*** Dialogbox-Titel.
if LANG = LANG_DE
:Dlg_Titel_Error	b PLAINTEXT,BOLDON
			b "FEHLER"
			b NULL
:Dlg_Titel_Info		b PLAINTEXT,BOLDON
			b "INFORMATION"
			b NULL
endif
if LANG = LANG_EN
:Dlg_Titel_Error	b PLAINTEXT,BOLDON
			b "ERROR"
			b NULL
:Dlg_Titel_Info		b PLAINTEXT,BOLDON
			b "INFORMATION"
			b NULL
endif

;*** Kein GEOS-MegaPatch.
:Dlg_NoMP		b $81

			b DBTXTSTR   ,$10,$10
			w Dlg_Titel_Error
			b DBTXTSTR   ,$10,$24
			w :101
			b DBTXTSTR   ,$10,$30
			w :102
			b CANCEL     ,$02,$48
			b NULL

if LANG = LANG_DE
::101			b PLAINTEXT
			b "Dieses Programm ist nur mit",NULL
::102			b "GEOS-MegaPatch V3 lauffähig!",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "This program requires the",NULL
::102			b "GEOS-MegaPatch V3!",NULL
endif

;*** Fehler: Keine CMD-HD unter GEOS.
:Dlg_ErrorNoHD		b %01100001
			b $30,$8f
:dlg80_01a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$2b
			w :102
			b DBTXTSTR   ,$0c,$3b
			w :103
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Aktuell ist kein CMD-HD-Laufwerk",NULL
::102			b "unter GEOS eingerichtet!",NULL
::103			b "Programm wird beendet.",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "There is currently no CMD-HD",NULL
::102			b "drive configured under GEOS!",NULL
::103			b "Program will be cancelled.",NULL
endif

;*** Fehler: Keine weiteren SCSI-Geräte.
if INFOMODE=FALSE
:Dlg_ErrorNoSCSI	b %01100001
			b $30,$8f
:dlg80_02a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b OK         ,$01,$48
			b NULL
endif

;--- Dialogbox-Texte.
if INFOMODE!LANG = FALSE!LANG_DE
::101			b PLAINTEXT
			b "Keine weiteren SCSI-Geräte gefunden!",NULL
::102			b "Programm wird beendet.",NULL
endif
if INFOMODE!LANG = FALSE!LANG_EN
::101			b PLAINTEXT
			b "No more SCSI devices found!",NULL
::102			b "Program will be cancelled.",NULL
endif

;*** Fehler: Boot-Adr. CMD-HD blockiert.
:Dlg_DevBlocked		b %01100001
			b $30,$8f
:dlg80_03a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b DBTXTSTR   ,$0c,$3b
			w :103
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "SCSI-Laufwerk wechseln nicht möglich!",NULL
::102			b "Boot-Adresse der CMD-HD ist durch",NULL
::103			b "ein anderes Laufwerk belegt.",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Switching SCSI-device not possible!",NULL
::102			b "Boot address of the CMD-HD is",NULL
::103			b "currently is use by another device.",NULL
endif

;*** Fehler: Falsche Blockgröße.
:Dlg_ErrBlkSize		b %01100001
			b $30,$8f
:dlg80_04a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "SCSI-Blockgröße ungültig!",NULL
::102			b "(Entspricht nicht 512 Bytes)",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "SCSI block size not valid!",NULL
::102			b "(Does not match 512 Bytes)",NULL
endif

;*** Fehler: Keine Systempartition.
:Dlg_ErrSysPart		b %01100001
			b $30,$8f
:dlg80_05a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Keine Systempartition gefunden!",NULL
::102			b "(CREATE.SYS nicht ausgeführt?)",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "No system partition found!",NULL
::102			b "(CREATE.SYS not run?)",NULL
endif

;*** Info: Medium einlegen.
:Dlg_InsertMedia	b %01100001
			b $30,$8f
:dlg80_06a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b OK         ,$01,$48
			b CANCEL     ,$11,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Bitte Medium in Laufwerk einlegen!",NULL
::102			b "Zum Menü zurück mit <ABBRUCH>.",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Please insert media in device!",NULL
::102			b "Back to menu with <CANCEL>.",NULL
endif

;*** Info: Festplatte parken?.
:Dlg_ParkHDD		b %01100001
			b $30,$8f
:dlg80_07a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b YES        ,$01,$48
			b NO         ,$11,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Festplatte der CMD-HD parken?",NULL
::102			b "(Laufwerk wird angehalten)",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Park disk drive in CMD-HD?",NULL
::102			b "(Drive will be set to sleep mode)",NULL
endif

;*** Info: Eject-Flag gespeichert.
:Dlg_SaveEject		b %01100001
			b $30,$8f
:dlg80_11a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Die Einstellung wurde gespeichert!",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "The setting has been saved!",NULL
endif

;*** Fehler: Eject-Flag nicht gespeichert.
:Dlg_ErrSaveEject	b %01100001
			b $30,$8f
:dlg80_12a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$2b
			w :102
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Die Einstellung konnte nicht in",NULL
::102			b "der Anwendung gespeichert werden!",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "The setting could not be saved!",NULL
::102			b NULL
endif

;*** Partitionsauswahlbox.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL

;*** AutoClose für Dialogboxen.
:IBoxInit		LoadW	appMain,IBoxClose
			rts

:IBoxClose		php
			sei
			lda	#$00
			sta	appMain +0
			sta	appMain +1
			plp

			lda	#OK
			sta	sysDBData
			jmp	RstrFrmDialogue

;*** Info: Suche SCSI-Laufwerke
:IBox_Searching		b %01100001
			b $40,$6f
:dlg80_08a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

if TESTUI=TRUE
			b DB_USR_ROUT
			w testPauseUI
endif
if TESTUI=FALSE
			b DB_USR_ROUT
			w callFindSCSI
endif
			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Suche SCSI-Laufwerke...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Searching for SCSI devices...",NULL
endif

;*** Info: Suche System-Partition.
:IBox_Testing		b %01100001
			b $40,$6f
:dlg80_09a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

if TESTUI=TRUE
			b DB_USR_ROUT
			w testPauseUI
endif
if TESTUI=FALSE
			b DB_USR_ROUT
			w callFindSysP
endif

			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Suche System-Partition...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Searching system partition...",NULL
endif

;*** Info: SCSI-Laufwerk wird angeschlossen.
:IBox_Connect		b %01100001
			b $40,$6f
:dlg80_10a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

if TESTUI=TRUE
			b DB_USR_ROUT
			w testPauseUI
endif
if TESTUI=FALSE
			b DB_USR_ROUT
			w callSwitchDev
endif

			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Laufwerk wird angeschlossen...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Connecting SCSI device...",NULL
endif

;*** SCSI-Befehlstabelle.
;Kommentare aus dem "SCSI Reference Manual" von Seagate:
;https://www.seagate.com/files/staticfiles/support/docs/manual/Interface Manuals/100293068i.pdf

;--- 00h / 6 Bytes.
;SCSI-Befehl: TEST UNIT READY
; -Operation Code $00
; -Reserved 4 Bytes
; -Control
;Rückgabe: 1 Byte
;$00    : OK
;$02    : No media
;$8x    : Not ready
:scsiREADY		b "S-C"
:scsiREADY_id		b $00
			w $4000
			b $00,$00,$00,$00,$00,$00

;--- 12h / 6 Bytes.
;SCSI-Befehl: INQUIRY
; -Operation Code $12
; -EVPD Bit%0=0: Standard INQUIRY data
; -Page Code
; -Allocation length Hi/Lo
; -Control
;Rückgabe: 36 Bytes
;$00    : Bit %0-%4 = Device type.
;$08-$0F: T10 Vendor identification
;$10-$1F: Product identification
;$20-$23: Product revision level
;Aktuell nicht verwendet:
;$24-$2B: Drive serial number
:scsiINQUIRY		b "S-C"
:scsiINQUIRY_id		b $00
			w $4000
			b $12,$00,$00,$00,$24,$00
:scsiINQUIRY_mr		b "M-R"
			w $4000
			b $24

;--- 25h / 10 Bytes.
;SCSI-Befehl: READ CAPACITY
; -Operation Code $25
; -Reserved/Obsolete
; -Logical Block Address 4 Bytes (Obsolete)
; -Reserved
; -Reserved
; -Reserved/PMI(Obsolete)
; -Control
;Rückgabe: 8 Bytes
;$00-$03: MSB...LSB Anzahl 512-Blocks.
;$04-$07: MSB...LSB Blockgröße.
;         Muss $00,$00,$02,$00 sein!
:scsiCAPACITY		b "S-C"
:scsiCAPACITY_id	b $00
			w $4000
			b $25,$00,$00,$00,$00,$00
:scsiCAPACITY_mr	b "M-R"
			w $4000
			b $08

;--- 1Bh / 6 Bytes.
;SCSI-Befehl: START/STOP UNIT
; -Operation Code $1b
; -Immediate Bit%0=1
;  The device server shall return status as
;  soon as the CDB has been validated.
; -Reserved
; -Power condition modifier
;  $00 = Process LOEJ and START bits.
; -LOEJ/START
;  Bit%0=0 STOP
;  Bit%0=1 START
;  Bit%1=0 No action regarding loading/ejecting medium.
;  Bit%1=1 and Bit%0=0 Eject medium.
;  Bit%1=1 and Bit%0=1 Load medium.
; -Control
:scsiSTARTUNIT		b "S-C"
:scsiSTARTUNIT_id	b $00
			w $4000
			b $1b,$00,$00,$00,$01,$00

:scsiSTOPUNIT		b "S-C"
:scsiSTOPUNIT_id	b $00
			w $4000
			b $1b,$01,$00,$00,$00,$00
:scsiSTOPUNIT_ej	= scsiSTOPUNIT +10

;--- 28h / 10 Bytes.
;SCSI-Befehl: READ
; -Operation Code $28
; -Data
; -Logical Block Address 4 Bytes
; -Group number
; -Transfer length MSB
; -Transfer length LSB
; -Control
:scsiREAD		b "S-C"
:scsiREAD_id		b $00
			w $4000
			b $28,$00
:scsiREAD_adr		b $00,$00,$00,$00
			b $00,$00,$01,$00
:scsiREAD_mr		b "M-R"
			w $41f0
			b $10

;*** Allgemeine Laufwerksbefehle.
;--- Aktuelle ID der CMD-HD einlesen.
:comGETID		b "M-R"
			w $9000
			b $01

;--- Boot-Adresse/SWAP-Status einlesen.
:comGETADR		b "M-R"
			w $90e1
			b $04

;--- Adresse CMD-HD korrigieren.
:comSWAP89		b "S-x"				;SWAP 8/9.
:comSWAPX		b "U0>",$00			;Adresse ändern.

;--- SCSI-ID wechseln.
;Dies ist ein kleines Programm das in
;der CMD-HD installiert wird und über
;den AUTOSTART-Code die ID wechselt:
;
;$4000 a9 00    lda #id
;$4002 4c 0f 8e jmp $8e0F
;
:comSWITCH		b "M-W"
			w $4000
			b $05
:comSWITCH_lda		b $a9,$00
			b $4c,$0f,$8e

;--- Programm in der CMD-HD ausführen.
:comEXECUTE		b "M-E"
			w $4000

;--- Partitionsinformationen abfragen.
:comGETPART		b "G-P",$ff
:curPartInfo		s 31
:partName		s 17

;--- Medium initialisieren.
:comInitDisk		b "I0:",CR

;*** Variablen für CMD-HD.
:devErrorHD		b $00				;Fehlerstatus CMD-HD.
:cntDrvHDerr		b $00				;Zähler für HD-Fehler.
:bakAdrHD		b $00				;Aktuelle GEOS-Adresse CMD-HD.
:devAdrHD		b $00				;Aktuelle GEOS-Adresse CMD-HD.
:devAdrHD_ID		b $00				;Aktuelle ID der CMD-HD.
:bootAdrHD		b $00				;Boot-Adresse der CMD-HD.
:bootSwapHD		b $00				;SWAP-Status der CMD-HD.

;*** Datenspeicher für SCSI-Daten.
:scsiDataBuf8		s $08				;Speicher für "CAPACITY".
:scsiDataBuf16		s $10				;Speicher für Suche Systempartition.
:scsiDataBuf24		s $24				;Speicher für "INQUIRY".

;*** Informationen über SCSI-Geräte.
:scsiDevCount		b $00				;Anzahl Geräte.
:scsiNewID		b $00				;Neue SCSI-ID.
:scsiOldID		b $00				;Bisherige SCSI-ID.

:scsiErrByte		s $08				;Fehlerbyte für jede ID.

;--- Intern: SCSI-Gerätetypen.
;Nur "DEVICE TYPE" = 0,5,7 erlaubt.
;$00 = Direct-access device/Festplatte
;      (ZIP meldet sich als Festplatte)
;$02 = CDROM device
;$03 = Optical memory device
:scsiTypes		b $00,$ff,$ff,$ff
			b $ff,$02,$ff,$03

;--- Intern: Wechselmedien.
:scsiEjMode		b $00,$02,$02,$02

;--- Aktivierte Geräte.
;$FF = Laufwerk aktiviert. Wird durch
;Auswahl der CheckBox im Menü gesetzt.
if TESTUI=FALSE
:scsiEnabled		b $00,$00,$00,$00
			b $00,$00,$00,$00
endif
if TESTUI=TRUE
:scsiEnabled		b $ff,$00,$00,$00
			b $00,$00,$00,$00
endif

;--- Intern: Liste mit SCSI-IDs.
;Hinweis: Die DEBUG-Werte sind nur für
;die Versionen zum testen des UI.
if TESTUI=TRUE
:scsiID			b $00,$ff,$ff,$ff
			b $ff,$05,$ff,$ff
endif
if TESTUI=FALSE
:scsiID			b $ff,$ff,$ff,$ff
			b $ff,$ff,$ff,$ff
endif

;--- Intern: Liste mit Gerätetypen.
:scsiIdent		b $ff,$ff,$ff,$ff
			b $ff,$ff,$ff,$ff

;--- Intern: Laufwerk mit Wechselmedium.
:scsiRemovable		b $00,$00,$00,$00
			b $00,$00,$00,$00

;*** Variablen für Register-Menü.
:C_RegisterExit40	b $0d	 			;Farbe "Close"-Icon 40-Zeichen.
:C_RegisterExit80	b $05				;Farbe "Close"-Icon 80-Zeichen.
:curScrnMode		b $00
:ecjectMedia		b $00

:applDrive		b $00
if LANG = LANG_DE
:applClass		b "geoHDscsi   V",NULL
endif
if LANG = LANG_EN
:applClass		b "geoHDscsiE  V",NULL
endif
:applName		s 17

:regMenuPage		b $00				;Aktuelle Register-Seite.
:regMenuETab		b 0,11,22,33			;Position der "Aktiv"-Checkboxen
			b 44,55,66,77			;im Register-Menü.

:regMenuPTab		w scsiDataP1			;Daten für Register-Menü Seite #1.
			w scsiDataP2			;Daten für Register-Menü Seite #2.

;--- Geräte-IDs für Register-Menü.
:scsiID0		b $00
:scsiID1		b $01
:scsiID2		b $02
:scsiID3		b $03
:scsiID4		b $04
:scsiID5		b $05
:scsiID6		b $06
:scsiID7		b $07

;--- Intern: Liste der Geräteklassen.
:scsiTypeTx		b "hdd",NULL
			b "zip",NULL
			b "cd ",NULL
			b "mo ",NULL

;--- Hinweistext Register-Menü.
:scsiNoDevice		b PLAINTEXT
if LANG = LANG_DE
			b "(Kein Laufwerk)",NULL
endif
if LANG = LANG_EN
			b "(No device)",NULL
endif

;--- Status-Info CMD-HD.
:scsiHDInfo		b PLAINTEXT
:scsiHDInfo_ga		b "A:"
			b "CMD-HD "
			b "Boot:"
:scsiHDInfo_sa		b "00"
			b NULL

;--- Zeiger auf Texte Register-Menü.
;Für hersteller/Gerätename werden zwei
;Textzeilen benötigt. Diese Tabelle
;beinhaltet Zeiger auf Zeile#1/#2 für
;die SCSI-IDs 0-7.
:scsiNameTab		w scsiName0a,scsiName0b
			w scsiName1a,scsiName1b
			w scsiName2a,scsiName2b
			w scsiName3a,scsiName3b
			w scsiName4a,scsiName4b
			w scsiName5a,scsiName5b
			w scsiName6a,scsiName6b
			w scsiName7a,scsiName7b

if TESTUI=TRUE
;--- Textzeile #1: Hersteller.
;Laut SCSI-Definition nur 8 Zeichen.
:scsiName0a		b "XXX: CODESRC    ",NULL
:scsiName1a		s 17
:scsiName2a		s 17
:scsiName3a		s 17
:scsiName4a		s 17
:scsiName5a		b "XXX: IOMEGA     ",NULL
:scsiName6a		s 17
:scsiName7a		s 17

;--- Textzeile #2: Gerätename.
;Laut SCSI-Definition nur 16 Zeichen.
:scsiName0b		b "          SD2IEC",NULL
:scsiName1b		s 17
:scsiName2b		s 17
:scsiName3b		s 17
:scsiName4b		s 17
:scsiName5b		b "ZIP 100         ",NULL
:scsiName6b		s 17
:scsiName7b		s 17

;--- Laufwerksgröße.
;$0000       = Kein Medium.
;$0001-$FFFE = Größe in MByte.
;$FFFF       = Medium > 16 GByte.
:scsiSize0		w $0800
:scsiSize1		w $0000
:scsiSize2		w $0000
:scsiSize3		w $0000
:scsiSize4		w $0000
:scsiSize5		w $0080
:scsiSize6		w $0000
:scsiSize7		w $0000
endif

if TESTUI=FALSE
;--- Textzeile #1: Hersteller.
;Laut SCSI-Definition nur 8 Zeichen.
:scsiName0a		s 17
:scsiName1a		s 17
:scsiName2a		s 17
:scsiName3a		s 17
:scsiName4a		s 17
:scsiName5a		s 17
:scsiName6a		s 17
:scsiName7a		s 17

;--- Textzeile #2: Gerätename.
;Laut SCSI-Definition nur 16 Zeichen.
:scsiName0b		s 17
:scsiName1b		s 17
:scsiName2b		s 17
:scsiName3b		s 17
:scsiName4b		s 17
:scsiName5b		s 17
:scsiName6b		s 17
:scsiName7b		s 17

;--- Laufwerksgröße.
;$0000       = Kein Medium.
;$0001-$FFFE = Größe in MByte.
;$FFFF       = Medium > 16 GByte.
:scsiSize0		w $0000
:scsiSize1		w $0000
:scsiSize2		w $0000
:scsiSize3		w $0000
:scsiSize4		w $0000
:scsiSize5		w $0000
:scsiSize6		w $0000
:scsiSize7		w $0000
endif

;******************************************************************************
;*** Register-Menü 40-Zeichen.
;******************************************************************************
;*** Register-Tabelle.
:R40SizeY0		= $28
:R40SizeY1		= $a7
:R40SizeX0		= $0028
:R40SizeX1		= $010f

:RegMenu40		b R40SizeY0			;Register-Größe.
			b R40SizeY1
			w R40SizeX0
			w R40SizeX1

			b 1				;Anzahl Registerkarten.

			w RTabName40_1			;Register: "CMD-HD".
			w RTabMenu40_1

;*** Registerkarten-Icons.
:RTabName40_1		w RTabIcon1
			b RCardIcon40X_1
			b R40SizeY0 -$08
			b RTabIcon1_x
			b RTabIcon1_y

;*** Icon für Seitenwechsel.
:RIcon_Page		w SlctPage
			b $00,$00
			b SlctPage_x
			b SlctPage_y
			b $01

:PosSlctPage_x		= (R40SizeX1  +1) -$10
:PosSlctPage_y		= (R40SizeY1  +1) -$10

;*** Icon für "Eject-Flag speichern".
:R40Icon_SaveOpt	w SaveOpt
			b $00,$00
			b SaveOpt_x
			b SaveOpt_y
			b $0f

;*** Rahmen um "SaveOpt"-Icon.
:R40Icon_Frame		w $0000
			b $00
			b ESC_GRAPHICS
			b MOVEPENTO
			w R40Pos_x +112
			b R40Pos_y +RLine1_5 -1
			b FRAME_RECTO
			w R40Pos_x +120
			b R40Pos_y +RLine1_5 +8
			b NULL

;******************************************************************************
;*** Register-Menü 40-Zeichen.
;******************************************************************************
;*** Daten für Register "CMD-HD".
:R40Pos_x  = R40SizeX0 +$10
:R40Pos_y  = R40SizeY0 +$10

:R40Tab0  = $0000					;Position Checkbox.
:R40Tab1  = $0020					;Position SCSI-ID.
:R40Tab2  = $0030					;Position Hersteller/Gerätename.
:R40Tab3  = $00a8					;Position Mediengröße.

:RLine1_1 = $00						;Zeile #1: ID #0/#4.
:RLine1_2 = $18						;Zeile #2: ID #1/#5.
:RLine1_3 = $30						;Zeile #3: ID #2/#6.
:RLine1_4 = $48						;Zeile #4: ID #3/#7.
:RLine1_5 = $60						;Zeile #5: Medien auswerfen.

:RTabMenu40_1		b 20				;Anzahl Elemente.

			b BOX_ICON			;----------------------------------------
				w R40T01a
				w RMenuSlctPage
				b PosSlctPage_y
				w PosSlctPage_x
				w RIcon_Page
				b $00
			b BOX_USEROPT			;----------------------------------------
				w $0000
				w RMenuSlctHD
				b R40SizeY1 -15,R40SizeY1 -8
				w R40SizeX0 +8 ,R40SizeX0 +111
			b BOX_OPTION			;----------------------------------------
				w R40T02a
				w $0000
				b R40Pos_y +RLine1_5
				w R40Pos_x +104
				w ecjectMedia
				b %11111111
			b BOX_ICON			;----------------------------------------
				w R40Icon_Frame
				w RMenuSaveEject
				b R40Pos_y +RLine1_5
				w R40Pos_x +112
				w R40Icon_SaveOpt
				b $00

;--- DUMMY-Daten.
;Platzhalter für Daten Seite#1/#2.
;Beachte: ":regMenuETab" !!!

;--- Auswahlbox.
:RTabMenu40_opt
:RTabMenu40_1a		s 11
:RTabMenu40_1b		s 11
:RTabMenu40_1c		s 11
:RTabMenu40_1d		s 11

;--- SCSI-ID.
			s 11
			s 11
			s 11
			s 11

;--- SCSI-Manufacturer.
			s 11
			s 11
			s 11
			s 11

;--- SCSI-Größe.
			s 11
			s 11
			s 11
			s 11

:RTabMenu1_1end
:RTabMenu1_1len		= RTabMenu1_1end - RTabMenu40_opt
;---

;******************************************************************************
;*** Register-Menü 40-Zeichen (Fortsezung).
;******************************************************************************
;--- Spalten-Beschriftung.
:R40T01a		w R40Pos_x -$08
			b R40Pos_y +RLine1_1 -$04
if LANG = LANG_DE
			b "Aktiv"
endif
if LANG = LANG_EN
			b "Active"
endif

			b GOTOXY
			w R40Pos_x +R40Tab1
			b R40Pos_y +RLine1_1 -$04
			b "ID"

			b GOTOXY
			w R40Pos_x +R40Tab2
			b R40Pos_y +RLine1_1 -$04
if LANG = LANG_DE
			b "SCSI-Laufwerk"
endif
if LANG = LANG_EN
			b "SCSI device"
endif

			b GOTOXY
			w R40Pos_x +R40Tab3
			b R40Pos_y +RLine1_1 -$04
			b "MByte"
			b NULL

;--- Eject Media.
:R40T02a		w R40Pos_x +124
			b R40Pos_y +RLine1_5 +$06
if LANG = LANG_DE
			b "Auswerfen"
endif
if LANG = LANG_EN
			b "Eject media"
endif
			b NULL

;******************************************************************************
;*** Register-Menü 40-Zeichen (Fortsezung).
;******************************************************************************
;*** SCSI-Daten Seite #1.
:scsiDataP1		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv1
				b R40Pos_y +RLine1_1
				w R40Pos_x +R40Tab0
				w scsiEnabled +0
				b %11111111
			b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv2
				b R40Pos_y +RLine1_2
				w R40Pos_x +R40Tab0
				w scsiEnabled +1
				b %11111111
			b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv3
				b R40Pos_y +RLine1_3
				w R40Pos_x +R40Tab0
				w scsiEnabled +2
				b %11111111
			b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv4
				b R40Pos_y +RLine1_4
				w R40Pos_x +R40Tab0
				w scsiEnabled +3
				b %11111111

;--- SCSI-ID.
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_1
				w R40Pos_x +R40Tab1
				w scsiID0
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_2
				w R40Pos_x +R40Tab1
				w scsiID1
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_3
				w R40Pos_x +R40Tab1
				w scsiID2
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_4
				w R40Pos_x +R40Tab1
				w scsiID3
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT

;******************************************************************************
;*** Register-Menü 40-Zeichen (Fortsezung).
;******************************************************************************
;--- SCSI-Manufacturer.
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName0
				b R40Pos_y +RLine1_1
				b R40Pos_y +RLine1_1 +15
				w R40Pos_x +R40Tab2
				w R40Pos_x +R40Tab2  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName1
				b R40Pos_y +RLine1_2
				b R40Pos_y +RLine1_2 +15
				w R40Pos_x +R40Tab2
				w R40Pos_x +R40Tab2  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName2
				b R40Pos_y +RLine1_3
				b R40Pos_y +RLine1_3 +15
				w R40Pos_x +R40Tab2
				w R40Pos_x +R40Tab2  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName3
				b R40Pos_y +RLine1_4
				b R40Pos_y +RLine1_4 +15
				w R40Pos_x +R40Tab2
				w R40Pos_x +R40Tab2  +111

;--- SCSI-Size.
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_1
				w R40Pos_x +R40Tab3
				w scsiSize0
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_2
				w R40Pos_x +R40Tab3
				w scsiSize1
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_3
				w R40Pos_x +R40Tab3
				w scsiSize2
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_4
				w R40Pos_x +R40Tab3
				w scsiSize3
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT

;******************************************************************************
;*** Register-Menü 40-Zeichen (Fortsezung).
;******************************************************************************
;*** SCSI-Daten Seite #2.
:scsiDataP2		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv1
				b R40Pos_y +RLine1_1
				w R40Pos_x
				w scsiEnabled +4
				b %11111111
			b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv2
				b R40Pos_y +RLine1_2
				w R40Pos_x
				w scsiEnabled +5
				b %11111111
			b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv3
				b R40Pos_y +RLine1_3
				w R40Pos_x
				w scsiEnabled +6
				b %11111111
			b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv4
				b R40Pos_y +RLine1_4
				w R40Pos_x
				w scsiEnabled +7
				b %11111111

;--- SCSI-ID.
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_1
				w R40Pos_x +R40Tab1
				w scsiID4
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_2
				w R40Pos_x +R40Tab1
				w scsiID5
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_3
				w R40Pos_x +R40Tab1
				w scsiID6
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_4
				w R40Pos_x +R40Tab1
				w scsiID7
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT

;******************************************************************************
;*** Register-Menü 40-Zeichen (Fortsezung).
;******************************************************************************
;--- SCSI-Manufacturer.
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName4
				b R40Pos_y +RLine1_1
				b R40Pos_y +RLine1_1 +15
				w R40Pos_x +R40Tab2
				w R40Pos_x +R40Tab2  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName5
				b R40Pos_y +RLine1_2
				b R40Pos_y +RLine1_2 +15
				w R40Pos_x +R40Tab2
				w R40Pos_x +R40Tab2  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName6
				b R40Pos_y +RLine1_3
				b R40Pos_y +RLine1_3 +15
				w R40Pos_x +R40Tab2
				w R40Pos_x +R40Tab2  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName7
				b R40Pos_y +RLine1_4
				b R40Pos_y +RLine1_4 +15
				w R40Pos_x +R40Tab2
				w R40Pos_x +R40Tab2  +111

;--- SCSI-Size.
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_1
				w R40Pos_x +R40Tab3
				w scsiSize4
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_2
				w R40Pos_x +R40Tab3
				w scsiSize5
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_3
				w R40Pos_x +R40Tab3
				w scsiSize6
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R40Pos_y +RLine1_4
				w R40Pos_x +R40Tab3
				w scsiSize7
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT

;******************************************************************************
;*** Register-Menü 80-Zeichen.
;******************************************************************************
;*** Register-Tabelle.
:R80SizeY0		= $28
:R80SizeY1		= $a7
:R80SizeX0		= $0028
:R80SizeX1		= $0257

:RegMenu80		b R80SizeY0			;Register-Größe.
			b R80SizeY1
			w R80SizeX0
			w R80SizeX1

			b 1				;Anzahl Registerkarten.

			w RTabName80_1			;Register: "CMD-HD".
			w RTabMenu80_1

;*** Registerkarten-Icons.
:RTabName80_1		w RTabIcon1
			b RCardIcon80X_1 ! DOUBLE_B
			b R80SizeY0 -$08
			b RTabIcon1_x ! DOUBLE_B
			b RTabIcon1_y

;*** Icon für "Eject-Flag speichern".
:R80Icon_SaveOpt	w SaveOpt
			b $00,$00
			b SaveOpt_x ! DOUBLE_B
			b SaveOpt_y
			b $0e

;*** Rahmen um "SaveOpt"-Icon.
:R80Icon_Frame		w $0000
			b $00
			b ESC_GRAPHICS
			b MOVEPENTO
			w R80Pos_x +R80Tab4 +$08 ! DOUBLE_W
			b R80Pos_y +RLine1_5 -$01
			b FRAME_RECTO
			w R80Pos_x +R80Tab4 +$10 ! DOUBLE_W
			b R80Pos_y +RLine1_5 +$08
			b NULL

;******************************************************************************
;*** Register-Menü 80-Zeichen.
;******************************************************************************
;*** Daten für Register "CMD-HD".
:R80Pos_x  = R80SizeX0 -$08
:R80Pos_y  = R80SizeY0 +$10

:R80Tab0  = $0000					;Position Checkbox.
:R80Tab1  = $0010					;Position SCSI-ID.
:R80Tab2  = $0060					;Position Hersteller/Gerätename.
:R80Tab3  = $00e0					;Position Mediengröße.
:R80Tab4  = $0090					;Position Checkbox.
:R80Tab5  = $00a0					;Position SCSI-ID.
:R80Tab6  = $0180					;Position Hersteller/Gerätename.
:R80Tab7  = $0200					;Position Mediengröße.

;RLine1_1 = $00						;Zeile #1: ID #0/#4.
;RLine1_2 = $18						;Zeile #2: ID #1/#5.
;RLine1_3 = $30						;Zeile #3: ID #2/#6.
;RLine1_4 = $48						;Zeile #4: ID #3/#7.
;RLine1_5 = $60						;Zeile #5: Medien auswerfen.

:RTabMenu80_1		b 35				;Anzahl Elemente.

			b BOX_USEROPT			;----------------------------------------
				w R80T01a
				w RMenuSlctHD
				b R80SizeY1 -15,R80SizeY1 -8
				w R80SizeX0 +16,R80SizeX0 +127
			b BOX_OPTION			;----------------------------------------
				w R80T02a
				w $0000
				b R80Pos_y +RLine1_5
				w R80Pos_x +R80Tab4 ! DOUBLE_W
				w ecjectMedia
				b %11111111
			b BOX_ICON			;----------------------------------------
				w R80Icon_Frame
				w RMenuSaveEject
				b R80Pos_y +RLine1_5
				w R80Pos_x +R80Tab4 +8 ! DOUBLE_W
				w R80Icon_SaveOpt
				b $00

;--- Auswahlbox.
:RTabMenu80_opt
:RTabMenu80_1a		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv1
				b R80Pos_y +RLine1_1
				w R80Pos_x +R80Tab0 ! DOUBLE_W
				w scsiEnabled +0
				b %11111111
:RTabMenu80_1b		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv2
				b R80Pos_y +RLine1_2
				w R80Pos_x +R80Tab0 ! DOUBLE_W
				w scsiEnabled +1
				b %11111111
:RTabMenu80_1c		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv3
				b R80Pos_y +RLine1_3
				w R80Pos_x +R80Tab0 ! DOUBLE_W
				w scsiEnabled +2
				b %11111111
:RTabMenu80_1d		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv4
				b R80Pos_y +RLine1_4
				w R80Pos_x +R80Tab0 ! DOUBLE_W
				w scsiEnabled +3
				b %11111111
:RTabMenu80_1e		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv5
				b R80Pos_y +RLine1_1
				w R80Pos_x +R80Tab4 ! DOUBLE_W
				w scsiEnabled +4
				b %11111111
:RTabMenu80_1f		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv6
				b R80Pos_y +RLine1_2
				w R80Pos_x +R80Tab4 ! DOUBLE_W
				w scsiEnabled +5
				b %11111111
:RTabMenu80_1g		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv7
				b R80Pos_y +RLine1_3
				w R80Pos_x +R80Tab4 ! DOUBLE_W
				w scsiEnabled +6
				b %11111111
:RTabMenu80_1h		b BOX_OPTION			;----------------------------------------
				w $0000
				w RMenuSlctDv8
				b R80Pos_y +RLine1_4
				w R80Pos_x +R80Tab4 ! DOUBLE_W
				w scsiEnabled +7
				b %11111111

;******************************************************************************
;*** Register-Menü 80-Zeichen (Fortsezung).
;******************************************************************************
;--- SCSI-ID.
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_1
				w R80Pos_x +R80Tab1 ! DOUBLE_W
				w scsiID0
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_2
				w R80Pos_x +R80Tab1 ! DOUBLE_W
				w scsiID1
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_3
				w R80Pos_x +R80Tab1 ! DOUBLE_W
				w scsiID2
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_4
				w R80Pos_x +R80Tab1 ! DOUBLE_W
				w scsiID3
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_1
				w R80Pos_x +R80Tab5 ! DOUBLE_W
				w scsiID4
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_2
				w R80Pos_x +R80Tab5 ! DOUBLE_W
				w scsiID5
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_3
				w R80Pos_x +R80Tab5 ! DOUBLE_W
				w scsiID6
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_4
				w R80Pos_x +R80Tab5 ! DOUBLE_W
				w scsiID7
				b $01 ! NUMERIC_BYTE ! NUMERIC_LEFT

;******************************************************************************
;*** Register-Menü 80-Zeichen (Fortsezung).
;******************************************************************************
;--- SCSI-Manufacturer.
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName0
				b R80Pos_y +RLine1_1
				b R80Pos_y +RLine1_1 +15
				w R80Pos_x +R80Tab2
				w R80Pos_x +R80Tab2  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName1
				b R80Pos_y +RLine1_2
				b R80Pos_y +RLine1_2 +15
				w R80Pos_x +R80Tab2
				w R80Pos_x +R80Tab2  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName2
				b R80Pos_y +RLine1_3
				b R80Pos_y +RLine1_3 +15
				w R80Pos_x +R80Tab2
				w R80Pos_x +R80Tab2 +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName3
				b R80Pos_y +RLine1_4
				b R80Pos_y +RLine1_4 +15
				w R80Pos_x +R80Tab2
				w R80Pos_x +R80Tab2 +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName4
				b R80Pos_y +RLine1_1
				b R80Pos_y +RLine1_1 +15
				w R80Pos_x +R80Tab6
				w R80Pos_x +R80Tab6  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName5
				b R80Pos_y +RLine1_2
				b R80Pos_y +RLine1_2 +15
				w R80Pos_x +R80Tab6
				w R80Pos_x +R80Tab6  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName6
				b R80Pos_y +RLine1_3
				b R80Pos_y +RLine1_3 +15
				w R80Pos_x +R80Tab6
				w R80Pos_x +R80Tab6  +111
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w PutScsiName7
				b R80Pos_y +RLine1_4
				b R80Pos_y +RLine1_4 +15
				w R80Pos_x +R80Tab6
				w R80Pos_x +R80Tab6  +111

;******************************************************************************
;*** Register-Menü 80-Zeichen (Fortsezung).
;******************************************************************************
;--- SCSI-Größe.
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_1
				w R80Pos_x +R80Tab3
				w scsiSize0
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_2
				w R80Pos_x +R80Tab3
				w scsiSize1
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_3
				w R80Pos_x +R80Tab3
				w scsiSize2
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_4
				w R80Pos_x +R80Tab3
				w scsiSize3
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_1
				w R80Pos_x +R80Tab7
				w scsiSize4
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_2
				w R80Pos_x +R80Tab7
				w scsiSize5
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_3
				w R80Pos_x +R80Tab7
				w scsiSize6
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
			b BOX_NUMERIC_VIEW		;----------------------------------------
				w $0000
				w $0000
				b R80Pos_y +RLine1_4
				w R80Pos_x +R80Tab7
				w scsiSize7
				b $05 ! NUMERIC_WORD ! NUMERIC_RIGHT
;---

;******************************************************************************
;*** Register-Menü 80-Zeichen (Fortsezung).
;******************************************************************************
;--- Spalten-Beschriftung.
:R80T01a		w R80Pos_x +R80Tab0  -$04 ! DOUBLE_W
			b R80Pos_y +RLine1_1 -$04
if LANG = LANG_DE
			b "Aktiv"
endif
if LANG = LANG_EN
			b "Active"
endif

			b GOTOXY
			w R80Pos_x +R80Tab1 ! DOUBLE_W
			b R80Pos_y +RLine1_1 -$04
			b "ID"

			b GOTOXY
			w R80Pos_x +R80Tab2
			b R80Pos_y +RLine1_1 -$04
if LANG = LANG_DE
			b "SCSI-Laufwerk"
endif
if LANG = LANG_EN
			b "SCSI device"
endif

			b GOTOXY
			w R80Pos_x +R80Tab3
			b R80Pos_y +RLine1_1 -$04
			b "MByte"

			b GOTOXY
			w R80Pos_x +R80Tab4  -$04 ! DOUBLE_W
			b R80Pos_y +RLine1_1 -$04
if LANG = LANG_DE
			b "Aktiv"
endif
if LANG = LANG_EN
			b "Active"
endif

			b GOTOXY
			w R80Pos_x +R80Tab5 ! DOUBLE_W
			b R80Pos_y +RLine1_1 -$04
			b "ID"

			b GOTOXY
			w R80Pos_x +R80Tab6
			b R80Pos_y +RLine1_1 -$04
if LANG = LANG_DE
			b "SCSI-Laufwerk"
endif
if LANG = LANG_EN
			b "SCSI device"
endif

			b GOTOXY
			w R80Pos_x +R80Tab7
			b R80Pos_y +RLine1_1 -$04
			b "MByte"
			b NULL

;--- Eject Media.
:R80T02a		w R80Pos_x +R80Tab4  +$14 ! DOUBLE_W
			b R80Pos_y +RLine1_5 +$06
if LANG = LANG_DE
			b "Medium auswerfen"
endif
if LANG = LANG_EN
			b "Eject media"
endif
			b NULL

;******************************************************************************
;*** Register-Menü.
;******************************************************************************
;*** Icons für Registerkarten.
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIcon40X_1		= (R40SizeX0/8) +3
;RCardIcon40X_2		= RCardIcon40X_1 + RTabIcon1_x
:RCardIcon80X_1		= (R80SizeX0/8) +1
;RCardIcon80X_2		= RCardIcon40X_1 + RTabIcon1_x

;*** Register-Funktions-Icons.
:SlctPage
<MISSING_IMAGE_DATA>

:SlctPage_x		= .x
:SlctPage_y		= .y

:SaveOpt
<MISSING_IMAGE_DATA>

:SaveOpt_x		= .x
:SaveOpt_y		= .y

;******************************************************************************
;*** Icon-Menü "Beenden".
;******************************************************************************
:IconMenu40		b $01
			w $0000
			b $00

			w IconExit
:IconExitPos40		b (R40SizeX0/8) +1
			b R40SizeY0 -$08
			b IconExit_x
			b IconExit_y
			w ExitRegMenu

:IconMenu80		b $01
			w $0000
			b $00

			w IconExit
:IconExitPos80		b (R80SizeX0/8) +3
			b R80SizeY0 -$08
			b IconExit_x ! DOUBLE_B
			b IconExit_y
			w ExitRegMenu

;*** Icon zum schließen des Menüs.
:IconExit
<MISSING_IMAGE_DATA>

:IconExit_x		= .x
:IconExit_y		= .y
