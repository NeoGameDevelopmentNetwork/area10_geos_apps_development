; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;SourceCode of ZP/SCSI-Connect 1.5
;Original version by VCA West 2003
;
;Disassembled Dec.2019 by M.Kanet
;including modifications for C64.
;
;128+/64+ versions do include the CMD
;autostart file "COPYRIGHT CMD 89" to
;allow switch devices without needing
;the original file on default partition
;on the CMD-HD. Requires BootROM 2.80!
;
if .p
:COMPUTER		= 64				;Für C64 assemblieren.
;COMPUTER		= 128				;Für C128 assemblieren.
:PLUS			= 0				;PLUS-Version 1/0.
							;1=Inkl. "COPYRIGHT CMD 89".
endif

;*** Allgemeine Systemvariablen.
if .p
:NULL			= $00				;NULL-Byte.
:CR			= $0d				;"Cariage return".

:DEVSTAT		= $90				;Status-Byte für IEC-Bus.
:DEVADR			= $ba				;IEC-Bus Geräteadresse.

:STACK			= $0100				;Prozessor-Stack.

:SECOND			= $ff93				;Sekundäradresse für LISTEN.
:TKSA			= $ff96				;Sekundäradresse für TALK.
:ACPTR			= $ffa5				;Zeichen von IEC-Bus einlesen.
:CIOUT			= $ffa8				;Zeichen auf IEC-Bus ausgeben.
:UNTALK			= $ffab				;Alle Laufwerke UNTALK.
:UNLSN			= $ffae				;Alle Laufwerke UNLISTEN.
:LISTEN			= $ffb1				;Laufwerk auf LISTEN schalten.
:TALK			= $ffb4				;Laufwerk auf TALK schalten.

:PLOT			= $fff0				;Cursorposition setzen.

:TIMETSEC		= $a2				;RTC-Uhr, 1/60sek Register.

;*** Steuercodes für Bildschirmausgabe.
:CHAROFF		= $0b				;Disable character set change.
:CHARON			= $0c				;Enable character set change.
:SETLOWER		= $0e				;Set lower/upper case charset.
:CRSRHOME		= $13				;Cursor Home.
:CLRSCRN		= $93				;Clear screen and CCursor Home.

;*** Steuercodes für Inline-Text.
;Siehe Routine ":printText".
:sCOLOR1		= $e0				;Setzt Farbe #1 / vecColData.
:sCOLOR2		= $e1				;Setzt Farbe #2 / vecColData.
;--- $e2/$e3 werden nicht verwendet.
:sCOLOR3		= $e2				;Setzt Farbe #3 / vecColData.
:sUSRCOL		= $e3				;Setzt Farbe #4 / Ungenutzt.
;---
:sSETPOS		= $e4				;$e4, Zeile, Spalte.
							;     Zeile=$FF: Nicht ändern.
:sRPTCHR		= $e5				;$e5, Zeichen, Anzahl.
:sCLRLIN		= $e6				;$e6, Zeile.
:sCENTER		= $e7				;Text zentriert ausgeben.
:sDOCENT		= $e8				;Bisherigen Text zentrieren.
endif

;*** Adressen & Variablen C128.
if COMPUTER=128
:ERRVEC			= $0300

:DEZASCII		= $f9fb				;Kernal-Routine DEZ->ASCII.

:EN2MHZ128		= $77b6				;1/2-MHz umschalten.
:SETMMU128		= $02dd				;MMU-Register setzen.
:VDCCOL128		= $ce5c				;VDC-Farbtabelle.
:SETREG128		= $cdcc				;VDC-Register setzen.

:CLRWIN128		= $c142				;Fenster löschen.
:SCRWIN128		= $ca24				;Fenstergröße setzen.

:DELLINE		= $c4a5				;Zeile löschen.
:SCROUT			= $c72d				;Zeichen ausgeben.
:KGETIN			= $eeef				;Direkter Kernal-Einsprung!

:WINBOT128		= $e4				;Fenstergröße.
:WINTOP128		= $e5
:WINLFT128		= $e6
:WINRGT128		= $e7

:PNTR			= $ec				;Cursor-Spalte.
:TBLX			= $eb				;Cursor-Zeile.

;*** Steuercodes für Bildschirmausgabe.
:BLINKON		= $0f				;C128: Flash Text.
:BLINKOFF		= $8f				;C128: Unflash Text.

;*** Farbe C128:
; Bit%7=1: Alternat.Zeichensatz = EIN
; Bit%6=1: Inverse Darstelleung = EIN
; Bit%5=1: Unterstreichen = EIN
; Bit%4=1: Blinken = EIN
; Bit%3-0: Farbwert 0 bis 15
:COLOR128		= $f1

:ZPBUF1			= $24				;Zwischenspeicher in
:ZPBUF2			= $25				;Zero-Page für verschiedene
:ZPBUF3			= $26				;Funktionen.
:ZPBUF4			= $27
:STRVEC			= $ce
:ZPVEC1			= $28
endif

;*** Adressen & Variablen C64.
if COMPUTER=64
;DEZASCII		= DEZASC64			;Interne Routine DEZ->ASCII.

:CLEAR64		= $e544				;Bildschirm löschen.

:DELLINE		= $e9ff				;Zeile löschen.
;SCROUT			= $e716				;Direkter Kernal-Einsprung!
:SCROUT			= $ffd2				;Zeichen ausgeben.
;KGETIN			= $f142				;Direkter Kernal-Einsprung!
:KGETIN			= $ffe4				;Zeichen eingeben.

:PNTR			= $d3				;Cursor-Spalte.
:TBLX			= $d6				;Cursor-Zeile.

;*** Farbe C64.
:COLOR64		= $0286				;Aktuelle Zeichenfarbe.
:RVS			= $c7				;Bit%0=1: RVS=ON.

:ZPBUF1			= $22				;Zwischenspeicher in
:ZPBUF2			= $23				;Zero-Page für verschiedene
:ZPBUF3			= $24				;Funktionen.
:ZPBUF4			= $25
:STRVEC			= $26
:ZPVEC1			= $28
endif

;*** C128: BASIC-Header / Startadresse.
if COMPUTER!PLUS=128
			n "SCSI-CONNECT 1.5"
endif
if COMPUTER!PLUS=129
			n "SCSI-CONNECT128+"
endif

if COMPUTER=128
			f $01				;BASIC-Programm.
			o $1c01 -2			;Adresse -2 wegen Ladeadresse.
			w $1c01				;Ladeadresse für BASIC.

:BASLINE		w l1c32				;Zeiger nächste Zeile.
			w $07d3				;2003
			b $de," ",$9c			;GRAPHIC CLR
			b ": "
			b $9e," 7220"			;SYS 7220
			b ": "
			b $8f," "			;REM
			b "ZP-CONNECT"
			b " 1.5, "
			b "VCA WEST"
			b " 2003"
			b NULL				;Zeilenende.

:l1c32			b NULL				;Programmende.
			b NULL
:l1c34
endif

;*** C64: BASIC-Header / Startadresse.if COMPUTER=64
if COMPUTER!PLUS=64
			n "SCSI-CONNECT64"
endif
if COMPUTER!PLUS=65
			n "SCSI-CONNECT64+"
endif

if COMPUTER=64
			f $01				;BASIC-Programm.
			o $0801 -2			;Adresse -2 wegen Ladeadresse.
			w $0801				;Ladeadresse für BASIC.

			w l080b				;Zeiger nächste Zeile.
			w $07e3				;2019
			b $9e,"2061"			;SYS2061
			b NULL

:l080b			b NULL				;Programmende.
			b NULL
:l080d
endif

;*** Einsprung aus BASIC.
;C64=$080d, C128=$1c34.
:JMPTABLE		jmp	MAININIT

if COMPUTER=64
;*** Dezimalzahl nach ASCII wandeln.
;Beim C64 gibt es keinen Einsprung im
;Kernal für DEZASCII.
:DEZASCII		ldx	#"0"			;Start-Wert für HIGH-Byte.
			sec
::1			sbc	#10			;Dez.10 vom AKKU subtrahieren.
			bcc	:2			; => Unterlauf, Exit.
			inx				;HIGH-Byte +1.
			bcs	:1			;Unbedingter Sprung.
::2			adc	#"0"+10			;Unterlauf abfangen, LOW-Byte.
			rts
endif

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
:wrDatHD		jsr	devLISTEN		;Laufwerk auf Empfang.

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

			jmp	doUNLSN			;Laufwerk abschalten.

;--- CMDHD-AutoStart-Datei.
;Am Anfang der Datei befinden sich
;2 Bytes für die Ladeadresse ($8E00)
;und 1 Byte für die Größe ($DF).
:CMD89begin		d "COPYRIGHT CMD 89"
:CMD89data		= CMD89begin +3
:CMD89end
;---

;*** Befehl zum senden der Daten.
:wrPrgHD		b "M-W"
:ramAdr			w $8e00
			b 16
endif

;*** Programm-Variablenspeicher.
:backColor		b $0c
:vecColData		b $01				;$CE5D: Hellblau
			b $02				;$CE5E: Gelb
			b $03				;$CE5F: Blau

:scsiComIdx		b $00				;Befehlsindex, immer $00?

:repeatCom		b $02				;Wiederholung für SCSI-Befehle.

;*** "EJECT Media"-Info.
;Für den SCSI START-Befehl
:ejectInfo		b $00				;Festplatte.
			b $00				;ZIP-Laufwerk.
			b $02				;CDROM-Laufwerk.
			b $02				;MO-Laufwerk.

;*** 52Byte an Speicher für Variablen.
;Duch :MAININIT mit $00 initialisiert.
:dataBuf

;--- SCSI-Buffer für 8 Bytes.
:scsiBuf8		b $00,$00,$00,$00
			b $00,$00,$00,$00
:blkSizeHi		= scsiBuf8 +6
:blkSizeLo		= scsiBuf8 +7
;---

;--- SCSI-Buffer für 16 Bytes.
:scsiBuf16		b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
			b $00,$00,$00,$00
;---

:scsiErrByt		b $00
:countSCSI		b $00
:tabSCSIAdr		b $00,$00,$00,$00,$00,$00

;--- Liste der Laufwerkstypen:
;$00 = Festplatte
;$01 = ZIP-Laufwerk
;$02 = CDROM-Laufwerk
;$03 = MO-Laufwerk
:tabSCSITyp		b $00,$00,$00,$00,$00,$00

;--- Liste der Medientypen:
;$00 = Fesplatte
;$xx = Wechselmedium
:tabSCSIDsk		b $00,$00,$00,$00,$00,$00

;--- Laufwerksadresse für Meldung:
;    "Bitte Diskette einlegen!"
:diskDrvAdr		b $00

:scsiCurTyp		b $00
:scsiCurDsk		b $00
:sysAdrHD		b $00				;Bei der Suche gefunde HD-Adr.
:stdAdrHD		b $00				;Über Konfig gelesene HD-Adr.
:swapModeHD		b $00				;SwapMode-Status.
:scsiBootID		b $00
:scsiBootTyp		b $00
:endDataBuf
;---

;*** SCSI-Befehlstabelle.
;Kommentare aus dem "SCSI Reference Manual" von Seagate:
;https://www.seagate.com/files/staticfiles/support/docs/manual/Interface Manuals/100293068i.pdf

:scsiDataTab

;--- LDA #$00 / 6 Bytes.
;SCSI-Befehl: TEST UNIT READY
; -Operation Code $00
; -Reserved 4 Bytes
; -Control
:scom1			b $00,$00,$00,$00,$00,$00
:scsiCom1		= scom1 - scsiDataTab

;--- LDA #$06 / 6 Bytes.
;SCSI-Befehl: INQUIRY
; -Operation Code $12
; -EVPD Bit%0=0: Standard INQUIRY data
; -Page Code
; -Allocation length Hi/Lo
; -Control
:scom2			b $12,$00,$00,$00,$02,$00
:scsiCom2		= scom2 - scsiDataTab

;--- LDA #$0c / 10 Bytes.
;SCSI-Befehl: READ CAPACITY
; -Operation Code $25
; -Reserved/Obsolete
; -Logical Block Address 4 Bytes (Obsolete)
; -Reserved
; -Reserved
; -Reserved/PMI(Obsolete)
; -Control
:scom3			b $25,$00,$00,$00,$00,$00
			b $00,$00,$00,$00
:scsiCom3		= scom3 - scsiDataTab

;--- LDA #$16 / 10 Bytes.
;SCSI-Befehl: READ
; -Operation Code $28
; -Data
; -Logical Block Address 4 Bytes
; -Group number
; -Transfer length MSB
; -Transfer length LSB
; -Control
:scom4			b $28,$00,$00,$00,$00,$00
			b $00,$00,$01,$00
:scsiBlkAdr		= scom4 +2
:scsiCom4		= scom4 - scsiDataTab

;--- LDA #$20 / 6 Bytes.
;SCSI-Befehl: STOP UNIT
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
:scom5			b $1b,$01,$00,$00,$00,$00
:ejectMode		= scom5 +4
:scsiCom5		= scom5 - scsiDataTab

;--- LDA #$26 / 6 Bytes.
;SCSI-Befehl: START UNIT
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
:scom6			b $1b,$00,$00,$00,$01,$00
:scsiCom6		= scom6 - scsiDataTab

;*** Datentabelle für Laufwerksbefehle.
:comDataTab
:txtCMDHD		b "CMD HD"

;--- LDY #$06
:com1			b $06
			b "M-R",$a0,$fe,$06
:comHDCode		= com1 - comDataTab

;--- LDY #$0D
:com2			b $06
			b "M-R",$00,$90,$01
:comRdDat1		= com2 - comDataTab

;--- LDY #$14
:com3			b $06
			b "M-R",$e1,$90,$04
:comRdDat2		= com3 - comDataTab

;--- LDY #$1B
;Software SWAP-Befehl der CMD-HD.
:com4			b $03
			b "S-"
:swapAdrHD		b $00
:comSCSI1		= com4 - comDataTab

;--- LDY #$1F
;*** Ungenutzer Programmcode **********
;Erzeugt einen Spungbefehl im HD-RAM.
;Wird durch :mkJmpTab1 gesetzt.
;Adresse: $4000 JMP $8E03 oder
;               JMP $8E06
;Wird aktuell nicht verwendet.
;Benötigt die CMD-AutoStart Datei!
:com5			b $09
			b "M-W",$00,$40
			b $03
			b $4c
:jmpWrDat1		b $03,$8e
:comWrDat1		= com5 - comDataTab
;**************************************

;--- LDY #$29
;Erzeugt ein Programm im RAM der HD:
;Adresse: $4000 LDA #$xx
;         $4002 jmp $8Eyy
;               xx = $8E0F/$8E12
;Wird durch ":execPrgHD" definiert,
;aktuell wird aber $0F verwendet!
;Benötigt die CMD-AutoStart Datei!
:com6			b $0b
			b "M-W",$00,$40,$05,$a9
:ldaDevID		b $00,$4c
:romAdrLo		b $12,$8e
:comWrDat2		= com6 - comDataTab

;--- LDY #$35
:com7			b $05
			b "M-E",$00,$40
:comExec1		= com7 - comDataTab

;--- LDY #$3B
:com8			b $06
			b "M-R"
:rdAdrLo		b $00
:rdAdrHi		b $40
:rdBytCnt		b $00
:comRdDat3		= com8 - comDataTab

;--- LDY #$42
;Header für SCSI-Befehle.
;Nach dem Header werden noch die SCSI
;Operation codes/data bytes gesendet.
;Siehe ":scsiDataTab".
:com9			b $86				;Bit%7=1: Kein UNLSN senden.
			b "S-C"
:scsiCurID		b $00				;SCSI device number/ID.
			w $4000				;SCSI data buffer in HD-RAM.
:comSCSI2		= com9 - comDataTab

;*** Hauptprogramm.
:MAININIT
if COMPUTER=128
			jsr	SETMMU128		;MMU-Register auf $00.
			jsr	EN2MHZ128		;VIC aus / 2MHz-Modus ein.
endif

			lda	#$00			;Variablenspeicher löschen.
			ldx	#(endDataBuf-dataBuf)
::1			sta	dataBuf -1,x
			dex
			bne	:1

if COMPUTER=128
			jsr	SCRWIN128		;Bldschirm als Fenster setzen.

			jsr	setBackCol		;Hintergrundfarbe setzen.

			lda	COLOR128		;REVERSE-Modus einschalten.
			ora	#%01000000
			sta	COLOR128
endif

if COMPUTER=64
			lda	RVS			;REVERSE-Modus einschalten.
			ora	#%00000001
			sta	RVS
endif

			jsr	printText
			b CHAROFF
			b SETLOWER
			b sCOLOR1
			b CLRSCRN
			b sRPTCHR," ",80
			b sSETPOS,$00,$00
			b sCENTER

if COMPUTER=128
;			b "SYSTEM-"
;			b "LAUFWERK FUER "
;			b "CONTROLLER "
;			b "WECHSELN "
;			b "V1.5, "
;			b "(C) "
;			b "VCA "
;			b "WEST 2003"

			b $d3,"YSTEM-"
			b $cc,"AUFWERK FUER "
			b $c3,"ONTROLLER "
			b "WECHSELN "
			b $d6,"1.5, "
			b "(",$c3,") "
			b $d6,$c3,$c1," "
			b $d7,"EST 2003"
			b NULL
endif

if COMPUTER=64
;			b "SCSI-"
;			b "LAUFWERK FUER "
;			b "CONTROLLER "
;			b "WECHSELN"

			b $d3,$c3,$d3,$c9,"-"
			b $cc,"AUFWERK FUER "
			b $c3,"ONTROLLER "
			b "WECHSELN"
			b NULL
endif

if COMPUTER=128
			lda	COLOR128		;REVERSE-Modus abschalten.
			and	#%10111111
			sta	COLOR128

			lda	#$02
			sta	WINTOP128		;128: Obere Grenze Fenster.
			lda	#$14
			sta	WINLFT128		;128: Linke Grenze Fenster.
			lda	#$3b
			sta	WINRGT128		;128: Rechte Grenze Fenster.
endif

if COMPUTER=64
			lda	RVS			;REVERSE-Modus abschalten.
			and	#%11111110
			sta	RVS
endif

;--- Hardware (SuperCPU/RAMLink) initialisieren.
			jsr	iniCMDSYS

;--- CMD-HD suchen...
			jsr	findCMDHD		;CMD-HD suchen.
			bcc	foundHD			; => Gefunden, weiter...

;--- Keine CMD-HD gefunden.
			jsr	printText
			b sSETPOS,$05,$00
			b sCLRLIN
			b sCENTER

if COMPUTER=128
			b BLINKON
endif

;			b "KEIN "
;			b "CONTROLLER "
;			b "IN "
;			b "SICHT !"

			b $cb,"EIN "
			b $c3,"ONTROLLER "
			b "IN "
			b $d3,"ICHT !"

if COMPUTER=128
			b BLINKOFF
endif

			b NULL

			jmp	prgEXIT

;*** CMD-HD vorhanden.
:foundHD		lda	DEVADR			;Aktuelle Geräteadresse.
			sta	sysAdrHD

			ldy	#comRdDat2
			jsr	sendCom
			jsr	devTALK
			jsr	ACPTR			;Zeichen über IEC-Bus einlesen.
			sta	stdAdrHD		;Byte ab $90e1.
			jsr	ACPTR			;Zeichen über IEC-Bus einlesen.
			jsr	ACPTR			;Zeichen über IEC-Bus einlesen.
			jsr	ACPTR			;Zeichen über IEC-Bus einlesen.
			sta	swapModeHD		;Byte ab $90e4.
			jsr	doUNTALK

			ldy	#comRdDat1
			jsr	sendCom
			jsr	devTALK
			jsr	ACPTR			;Zeichen über IEC-Bus einlesen.
			pha				;Byte ab $9000.
			jsr	doUNTALK
			pla
			lsr
			lsr
			lsr
			lsr
			sta	scsiBootID
			sta	scsiCurID		;CMD-HD SCSI-ID sichern.
			tax
			jsr	getSCSIType
			sta	scsiBootTyp
			tax
			lda	ejectInfo,x
			sta	ejectMode		;Medien-Modus speichern.

			jsr	searchSCSI

			lda	countSCSI		;SCSI-Geräte gefunden;
			bne	:slctSCSI		; => Ja, weiter...

;--- Fehler: Keine weiteren Geräte.
			jsr	printText
			b sSETPOS,$05,$00
			b sCLRLIN
			b sCENTER

if COMPUTER=128
			b BLINKON
endif

;			b "KEIN WEITERES "
;			b "SCSI-"
;			b "LAUFWERK IN "
;			b "SICHT!"

			b $cb,"EIN WEITERES "
			b $d3,$c3,$d3,$c9,"-"
			b $cc,"AUFWERK IN "
			b $d3,"ICHT!"

			b CR
			b NULL

			jmp	prgEXIT

;--- Mindestens 1 weiteres SCSI-Gerät.
::slctSCSI		ldx	#$00
			jsr	setSCSIdat
			lda	countSCSI
			cmp	#$02
			bcc	:enableSCSI

;--- Mehrere Geräte, Auswahl anzeigen.
			jsr	slctSCSIdv

;--- Ausgewähltes Gerät aktivieren.
::enableSCSI		lda	scsiCurDsk		;Wechselmedium?
			beq	:1			; => Nein, weiter...

			jsr	chkMedia
			cmp	#$03			;STOP gedrückt?
			bne	:1			; => Nein, weiter...
			jmp	prgEXIT			;Programm beenden.

::1			jsr	chkSCSIDev
			bcc	:connectDev
			jmp	prgEXIT			; => Laufwerk ungültig.

;--- Laufwerk anschließen.
::connectDev		lda	scsiCurID
			ora	#$30
			sta	:newID

			jsr	printText
			b CLRSCRN
			b sSETPOS,$05,$00
			b sCENTER
;			b "LAUFWERK "
			b $cc,"AUFWERK "
			b sCOLOR2
::newID			b "*"
			b sCOLOR1
			b " WIRD ANGESCHLOSSEN"
			b NULL

;--- Programm in HD-RAM installieren.
;Hierbei wird die CMD-AutoStart-Datei
;"COPYRIGHT CMD 89" im RAM der CMD-HD
;installiert. Diese Datei wird dann
;nicht mehr auf der Startpartition
;benötigt.
if PLUS=1
			jsr	writeCMD89
endif

;--- Programm in HD-RAM ausführen.
;Dabei wird der AKKU mit der neuen
;SCSI-ID geladen und dann über einen
;JMP-Befehl Teile der CMD-AutoStart-
;Datei ausgeführt.
			jsr	execPrgHD

;--- VERMUTUNG:
;Setzt das Programm im HD-RAM die
;Geräteadresse auf Standard zurück?
;Dann wäre stdAdrHD die echte Geräteadr.
;und in swapModeHD wäre ein Flag für
;"SWAP aktiv" mit Adresse 8/9+Bit%7=1.
			lda	stdAdrHD
			sta	DEVADR			;Aktuelle Geräteadresse.

;--- Laufwerksadresse auf #8/#9 ändern?
			lda	swapModeHD
			bpl	:noSwap

;--- Ja, SWAP 8/9 an Laufwerk senden.
			and	#$7f
			pha
			ora	#$30
			sta	swapAdrHD
			ldy	#comSCSI1
			jsr	sendCom

;--- Warteschleife.
;Notwendig um den SWAP-Befehl über den
;seriellen Bus abzuwarten.
			lda	#$00			;24H-Echtzeit-Uhr als
			sta	TIMETSEC		;Zähler für Warteschleife
::wait			lda	TIMETSEC		;verwenden: 120 x 1/60sek.
			cmp	#$78			; => 2Sek. Pause.
			bcc	:wait

			pla				;SWAP-Adresse als neue
			sta	DEVADR			;Laufwerksadresse setzen.

::noSwap		clc

;--- War Bootlaufwerk eine Festplatte?
			lda	scsiBootTyp
			bne	:noHDD			; => Keine Festplatte.

;--- Ja, Festplatte parken?
			jsr	printText
			b sSETPOS,$07,$00
			b sCLRLIN
			b sCENTER

;			b "FESTPLATTE PARKEN ? "

			b $c6,"ESTPLATTE PARKEN ? "

			b "J/N"
			b NULL

			jsr	waitYesNo
::noHDD			bcs	prgEXIT

;--- Bei CDROM/MO Medium auswerfen.
			lda	scsiBootID
			sta	scsiCurID
			lda	#scsiCom5		;SCSI: "STOP UNIT"
			jsr	scsiCom

;*** Programm beenden.
:prgEXIT		jsr	resCMDSYS		;RAMLink/SCPU zurücksetzen.

			jsr	printText
			b CRSRHOME
			b CRSRHOME
			b CHARON
			b NULL

if COMPUTER=128
			ldx	#$80
			jmp	(ERRVEC)		;Fehler ausgeben.
endif
if COMPUTER=64
			rts
endif

;*** CMD-HD-Laufwerk suchen.
;Dabei wird nur das erste Laufwerk am
;seriellen Bus gesucht. Weitere CMDHD
;werden ignoriert.
:findCMDHD		ldx	#8			;Geräte von #8 bis #29 testen.
::1			stx	DEVADR
			jsr	devLISTEN
			bcs	:4

			jsr	doUNLSN

			ldy	#comHDCode
			jsr	sendCom

			jsr	devTALK

			ldy	#$00
			ldx	#$00
::2			jsr	ACPTR			;Zeichen über IEC-Bus einlesen.
			cmp	txtCMDHD,x
			bne	:3
			iny
::3			inx
			cpx	#$06
			bcc	:2

			jsr	doUNTALK

			cpy	#$06
			clc
			beq	:exit

::4			ldx	DEVADR
			inx
			cpx	#30			;Max. Geräte #8 bis #29 testen.
			bcc	:1

::exit			rts

;*** SCSI-Geräte #0 bis #7 suchen.
:searchSCSI		ldx	#$00
			stx	countSCSI

::1			stx	scsiCurID
			cpx	scsiBootID		;Aktuelles SCSI-Gerät = HD?
			beq	:2			; => Ja, weiter...

			jsr	getSCSIType		;SCSI-Gerät verfügbar?
			bcs	:2			; => Nein, weiter...

			ldx	countSCSI
			sta	tabSCSITyp,x
			lda	scsiCurID
			sta	tabSCSIAdr,x

			lda	#scsiCom1		;SCSI: "TEST UNIT READY"
			jsr	scsiCom			;Ist Laufwerk bereit?

			ldx	countSCSI
			sta	tabSCSIDsk,x
			inc	countSCSI

::2			ldx	scsiCurID
			inx
			cpx	#$07
			bcc	:1

			rts

;*** SCSI-Laufwerkstyp ermitteln.
;Rückgabe: CARRY-Flag=0: Weiteres SCSI-Gerät.
;                    =1: Kein SCSI-Gerät.
:getSCSIType		lda	#scsiCom2		;SCSI: "INQUIRY"
			jsr	scsiCom
			bne	:noSCSI

			ldx	#<scsiBuf16
			ldy	#>scsiBuf16
			lda	#$02
			jsr	devGetByt

			lda	scsiBuf16		;Erstes Datenbyte.
			and	#$1f
			tax
			cpx	#$08			;SCSI-Gerät #0-#7?
			bcs	:noSCSI			; => Nein, Abbruch...

			lda	devTypes,x
			bmi	:noSCSI			; => Unbekannt...
			bne	:newSCSI		; => CROM/MO.

							;AKKU ist NULL!
			bit	scsiBuf16 +1
			bpl	:newSCSI		; => CMD-HD.
			lda	#$01			; => ZIP-Laufwerk.

::newSCSI		clc				;Weiteres SCSI-Gerät gefunden.
			rts

::noSCSI		sec				;Kein SCSI-Gerät gefunden.
			rts

;*** Medientypen.
:devTypes		b $00				;Festplatte.
			b $ff				;Unbekannt, evtl. ZIP.
			b $ff				;Unbekannt.
			b $ff				;Unbekannt.
			b $ff				;Unbekannt.
			b $02				;CDROM-Laufwerk.
			b $ff				;Unbekannt.
			b $03				;MO-Laufwerk.

;*** SCSI-Gerät auswählen.
:slctSCSIdv		jsr	printText
			b sSETPOS,$04,$07
;			b "LAUFWERK"
			b $cc,"AUFWERK"
			b sRPTCHR," ",10
;			b "TYP"
			b $d4,"YP"
			b sSETPOS,$05,$06
			b sRPTCHR,$c0,29
			b NULL

;--- Liste der SCSI-Geräte ausgeben.
			ldx	#$00
::1			stx	ZPBUF2
			lda	#sCOLOR1
			jsr	prnDvEntry
			ldx	ZPBUF2
			inx
			cpx	countSCSI
			bcc	:1

			jsr	printText
			b sSETPOS,$ff,$06
			b sRPTCHR,$c0,29
			b CR,CR
			b sSETPOS,$ff,$0b
;			b "CRSDOWN"
			b $c3,$d2,$d3,$c4,$cf,$d7,$ce
			b sCOLOR2
			b "/"
			b sCOLOR1
;			b "RETURN"
			b $d2,$c5,$d4,$d5,$d2,$ce
			b sCOLOR2
			b "/"
			b sCOLOR1
;			b "STOP"
			b $d3,$d4,$cf,$d0
			b NULL

;--- Auswahlmenü.
			ldx	#$00
:mnSelect		stx	ZPBUF2

			lda	#sCOLOR2
			jsr	prnDvEntry

:mnWaitKey		jsr	waitKey
			cmp	#$03			;STOP
			bne	:1
			jmp	prgEXIT

::1			cmp	#$0d			;RETURN
			beq	mnSlctDev
			cmp	#$11			;CRSRDOWN
			bne	mnWaitKey

;--- Nächsten Entrag in Liste wählen.
			lda	#sCOLOR1
			jsr	prnDvEntry

			ldx	ZPBUF2
			inx
			cpx	countSCSI
			bcc	:2
			ldx	#$00
::2			jmp	mnSelect

;--- Neues SCSI-Gerät auswählen.
:mnSlctDev
if COMPUTER=128
			jsr	CLRWIN128
endif
if COMPUTER=64
			jsr	CLEAR64
endif

			ldx	ZPBUF2

;*** Daten für SCSI-Gerät einlesen.
;Übergabe: XREG = Tabellenzeiger.
:setSCSIdat		lda	tabSCSIAdr,x
			sta	diskDrvAdr
			sta	scsiCurID
			lda	tabSCSITyp,x
			sta	scsiCurTyp
			lda	tabSCSIDsk,x
			sta	scsiCurDsk
			rts

;*** SCSI-Gerät ausgeben.
;Übergabe: AKKU = Farbecode $e0/sCOLOR1 oder $e1/sCOLOR2
;          ZPBUF2 = Zeiger auf Gerätetabelle.
:prnDvEntry		sta	:entryCol

			ldx	ZPBUF2
			txa
			clc
			adc	#$06
			sta	:entryPosY

			lda	tabSCSIAdr,x
			ora	#$30
			sta	:entryAdr

			jsr	printText
::entryCol		b $00
			b sSETPOS
::entryPosY		b $00,$0a
::entryAdr		b $00
			b sSETPOS,$ff,$16
			b NULL

;--- Gerätetyp einlesen und
;    Zeiger auf Laufwerkstext einlesen.
			lda	tabSCSITyp,x
			asl
			tax
			lda	drvTxVec +0,x
			ldy	drvTxVec +1,x
			jmp	inlineTxt		;Laufwerkstext ausgeben.

;*** Zeiger auf Laufwerkstexte.
:drvTxVec		w :txtHD
			w :txtZIP
			w :txtCDROM
			w :txtMO

;*** Laufwerkstexte.
::txtHD
;			b "FESTPLATTE"
			b $c6,"ESTPLATTE"
			b sCOLOR1,CR,NULL

::txtZIP
;			b "ZIP-LAUFWERK"
			b $da,$c9,$d0,"-",$cc,"AUFWERK"
			b sCOLOR1,CR,NULL

::txtCDROM
;			b "CD-ROM LESER"
			b $c3,$c4,"-",$d2,"OM ",$cc,"ESER"
			b sCOLOR1,CR,NULL

::txtMO
;			b "MO-LAUFWERK"
			b $cd,$cf,"-",$cc,"AUFWERK"
			b sCOLOR1,CR,NULL

;*** Auf Laufwerksmedium testen.
:chkMedia		lda	scsiCurTyp
			bne	insertDsk		; => Keine Festplatte, weiter.

			lda	#scsiCom6		;SCSI: "START UNIT"
			jsr	scsiCom
			bne	:debug
			rts				;Kein Fehler, Ende.

::debug			brk				;Absicht? BRK-Befehl!
							;Evtl. Debug-Code um am C128
							;den Monitor zu starten.

;*** Auf Diskette im Laufwerk warten.
:insertDsk		lda	diskDrvAdr
			ora	#$30
			sta	:diskAdr

			jsr	printText
			b sSETPOS,$05,$04
			b sCLRLIN
			b sCENTER

if COMPUTER=128
			b BLINKON
endif

;			b "DISKETTE IN "
;			b "LAUFWERK "

			b $c4,"ISKETTE IN "
			b $cc,"AUFWERK "

			b sCOLOR2
::diskAdr		b $00
			b sCOLOR1
			b " EINLEGEN"
			b sDOCENT
			b sSETPOS,$07,$00
			b sCENTER
			b "ODER "

;			b "STOP"
			b $d3,$d4,$cf,$d0

			b " DRUECKEN"

if COMPUTER=128
			b BLINKOFF
endif

			b NULL

;--- Warten bis Medium eingelegt.
:waitMedia		lda	#scsiCom1		;SCSI: "TEST UNIT READY"
			jsr	scsiCom			;Disk eingelegt?
			beq	:1			; => Ja, weiter...

			jsr	getNewKey
			cmp	#$03			;STOP?
			bne	waitMedia		; => Nein, warten...

::1			pha

if COMPUTER=128
			jsr	CLRWIN128
endif
if COMPUTER=64
			jsr	CLEAR64
endif

			pla
			rts

;*** Block-Adresse der System-Partition.
:sysPartAdr		b $00,$00,$00,$02

;*** Kennung für CMD-HD Systempartition.
:sysPartHD		b "CMD HD  "
			sta	$8803
			stx	$8802
			nop
			rts

;*** Neues SCSI-Laufwerk testen.
;Dabei wird geprüft ob es eine gültige
;Blockgröße von 512 Bytes hat und ob es
;eine Systempartition gibt.
;Rückgabe: C-Flag=0: OK.
;                =1: Fehler.
:chkSCSIDev		lda	#scsiCom3		;SCSI: "READ CAPACITY"
			jsr	scsiCom
			ldx	#<scsiBuf8
			ldy	#>scsiBuf8
			lda	#$08
			jsr	devGetByt
			ldx	#$00
			lda	#$01
			jsr	inc4BWord

			ldx	blkSizeHi		;Blockgröße 512Bytes?
			lda	blkSizeLo
			cpx	#$02
			bne	:1
			cmp	#$00
::1			beq	findSysP		; => Ja, weiter...

;--- SCSI-Laufwerk ungültig.
			jsr	printText
			b sSETPOS,$05,$00
			b sCLRLIN
			b sCENTER
;			b "BLOCKLAENGE"
			b $c2,"LOCKLAENGE"
			b " NICHT 512 "
;			b "BYTES"
			b $c2,"YTES"

if COMPUTER=128
			b BLINKOFF
endif

			b NULL

			sec
			rts

;*** Systempartition suchen.
;Die Systempartition beinhaltet eine
;"CMD HD"-Kennung und ein paar weitere
;Assembler-Bytes. Siehe ":sysPartHD".
;Diese Routine liest Daten von der
;Position der Systempartition auf Disk
;und sucht nach der Kennung.
:findSysP		jsr	printText
			b sSETPOS,$05,$00
			b sCLRLIN
			b sCENTER

if COMPUTER=128
			b BLINKON
endif

;			b "SYSTEM-"
;			b "PARTITION"
			b $d3,"YSTEM-"
			b $d0,"ARTITION"
			b " WIRD GESUCHT"

if COMPUTER=128
			b BLINKOFF
endif

			b NULL

			lda	#<$41f0			;Adresse der "CMD HD"-Kennung
			sta	rdAdrLo			;Innerhalb des Datenblocks.
			lda	#>$41f0
			sta	rdAdrHi

			ldx	#$04
::1			lda	sysPartAdr -1,x
			sta	scsiBlkAdr -1,x
			dex
			bne	:1

			lda	#$00
			sta	ZPBUF4

::loop1			lda	#scsiCom4		;SCSI: "READ"
			jsr	scsiCom
			ldx	#<scsiBuf16
			ldy	#>scsiBuf16
			lda	#$10
			jsr	devGetByt

			ldx	#$10
::2			lda	scsiBuf16 -1,x
			cmp	sysPartHD -1,x
			bne	:3
			dex
			bne	:2

::3			clc
			beq	:exitLoop

			dec	ZPBUF4
			sec
			beq	:exitLoop

			ldx	#(scsiBlkAdr - scsiBuf8)
			lda	#$80
			jsr	inc4BWord
			ldx	#(scsiBlkAdr - scsiBuf8)
			ldy	#$00
			jsr	chkEndOfP
			bcc	:loop1

::exitLoop		lda	#<$4000			;"M-R"-Befehl zurücksetzen.
			sta	rdAdrLo
			lda	#>$4000
			sta	rdAdrHi
			bcc	:exit			; => Kein Fehler, weiter...

;--- Medium ohne System-Partition.
			jsr	printText
			b sSETPOS,$05,$00
			b sCLRLIN
			b sCENTER

if COMPUTER=128
			b BLINKON
endif

;			b "KEINE "
;			b "SYSTEM-"
;			b "PARTITION"
			b $cb,"EINE "
			b $d3,"YSTEM-"
			b $d0,"ARTITION"
			b " VORHANDEN"

if COMPUTER=128
			b BLINKOFF
endif

			b NULL

;			sec				;C-Flag für Fehler ist noch gesetzt!
::exit			rts

;*** CMD-Hardware (SuperCPU/RAMLink) zurücksetzen.
:resCMDSYS		sec
			b $24				;BIT-Befehl für 1Byte.

;*** CMD-Hardware (SuperCPU/RAMLink) initialisieren.
:iniCMDSYS		clc
			bit	$d0b0			;SuperCPU verfügbar?
			bmi	:ramlink		; => Nein, weiter...

;--- SuperCPU/System-RAM
;Die Register ab $D200 sind Teil des
;System-RAM der SuperCPU. Die genaue
;Funktion ist unklar/undokumentiert.
;Evtl. Turbo an/aus oder VDC-Opt?
			bit	$d200
			bvc	:2

			lda	$d202
			and	#$7f
			bcc	:1
			ora	#$80
::1			sta	$d07e			;Hardware-Register ein.
			sta	$d202
			sta	$d07f			;Hardware-Register aus.
::2			rts

;--- RAMLink.
;Die Register ab $DF00 sind Teil des
;System-RAM der RAMLink. Die genaue
;Funktion ist unklar/undokumentiert.
::ramlink		lda	$e0a9
			eor	#$78			;RAMLink-OS verfügbar?
			bne	:4			; => Nein, Ende...
			sta	$df7e			;RAMLink aktivieren.
			sta	$dfc0			;RAMLink/Variablen-RAM ein.
			sta	$df82
			lda	$de65			;RAMLink/Variable einlesen.
			and	#$7f
			bcc	:3
			ora	#$80
::3			sta	$de65			;RAMLink/Variable setzen.
			sta	$df7f			;RAMLink deaktivieren.
::4			rts

;*** Ungenutzer Programmcode **********
;Der folgender Programme-Code wird im
;aktuellen Programm nicht mehr genutzt.
:mkJmpTab1		lda	#$06			;Konfigurationsmodus an?
			b $2c
:mkJmpTab2		lda	#$03			;Konfigurationsmodus aus?
			sta	jmpWrDat1
			ldy	#comWrDat1
			jsr	sendCom			;JMP-Tabelle erzeugen.
			ldy	#comExec1
			jsr	sendCom			;Kernal-Funktion ausführen.
			rts

;*** SCSI-Gerät wechseln.
;Vermutung: Der ungenutzte Code könnte
;Früher dazu genutzt worden sein, um
;über den Konfigurationsmodus das SCSI-
;Gerät zu wechseln, ähnlich HD-ZIP.
;Evtl. wurde das Binary später geändert
;um ohne den Konfigurationsmodus zu
;funktionieren.
:unknown		jsr	mkJmpTab1		;Konfigurationsmodus an?

			lda	#30			;Geräteadresse Konfiguations-
			sta	DEVADR			;Modus setzen.

			lda	#$12
			b $2c
;**************************************

;*** Unterprogramm im HD-RAM starten.
;Der Code erzeugt im HD-RAM ab $4000
;ein neues Programm, das Code im HD-RAM
;ab $8E00 ausführt.
;In diesem Bereich liegt der AUTOSTART-
;Code der Datei "copyright cmd 89".
;Die Datei muss auf der Startpartition
;der ersten SCSI-Laufwerks der CMD-HD
;liegen (->Native im Hauptverzeichnis).
:execPrgHD		lda	#$0f
			sta	romAdrLo		;Einspungadresse HD-RAM.

			lda	scsiCurID		;Aktuelle ID in AKKU für
			sta	ldaDevID		;Programm in HD-RAM setzen.

			ldy	#comWrDat2
			jsr	sendCom			;Programm in HD-RAM schreiben.
			ldy	#comExec1
			jsr	sendCom			;Programm in HD-RAM ausführen.
			rts

;*** SCSI Befehl über "S-C" senden.
;Übergabe: AKKU = Zeiger Befehlstabelle.
;Rückgabe: Z-Flag=1: Befehl gesendet.
;                =0: Fehler.
:scsiCom		sta	ZPBUF3

			lda	repeatCom		;Wie oft soll der Befehl
			sta	ZPBUF2			;gesendet werden?

::repeat		ldy	#comSCSI2
			jsr	sendCom

;--- Funktion unklar.
;Das zweite Befehlsbyte ist immer <32,
;:scsiComIdx ist immer $00.
;Daher wird hier das zweite Byte  mit
;$00 verknüpft. Das Ergebnis entspricht
;daher immer dem Original-Byte?
			ldy	ZPBUF3
			lda	scsiDataTab +1,y
			and	#$1f
			sta	ZPBUF1

			lda	scsiComIdx
			asl
			asl
			asl
			asl
			asl
			ora	ZPBUF1
			sta	scsiDataTab +1,y
;---

			lda	scsiDataTab +0,y
			lsr
			lsr
			lsr
			lsr
			lsr
			tax
			lda	scsiComLen,x
			bne	:ok

;--- Ungültige Befehlslänge, Abbruch!
::debug			jsr	doUNLSN			;UNLSN senden.

			brk				;Absicht? BRK-Befehl!
							;Evtl. Debug-Code um am C128
							;den Monitor zu starten.

;--- SCSI-Befehlsbytes an Laufwerk.
::ok			tax
::1			lda	scsiDataTab,y
			jsr	CIOUT			;Zeichen über IEC-Bus ausgeben.
			iny
			dex				;Alle Zeichen gesendet?
			bne	:1			; => Nein, weiter...
			jsr	doUNLSN

			jsr	devTALK			;Laufwerk auf TALK schalten.
			jsr	ACPTR			;Zeichen über IEC-Bus einlesen.
			sta	scsiErrByt
			pha				;Fehlerstatus auf STACK.
			jsr	doUNTALK		;Laufwerk auf UNTALK schalten.
			pla				;Fehlerstatus wieder einlesen.

			clc				;Fehlerstatus prüfen.
			beq	:exit			;$00=OK? => Ja, Ende...

			dec	ZPBUF2			;Nochmal versuchen.
			bne	:repeat

::exit			tax
			rts

;*** Anzahl zusätzlicher Datenbytes.
;Die Befehle liegen bei :scsiDataTab.
:scsiComLen		b $06				;Befehl: $00,$12,$1b
			b $0a				;Befehl: $24,$28

;--- Ungenutzte Daten?
;Die SCSI-Befehls-ID wird durch 2^5
;geteilt, daher können aktuell nur
;Index-Werte von 0 oder 1 entstehen.
;Vermutung: Könnte zu der Theorie
;passen, das die Original-Version des
;Binaries nachträglich geändert wurde.
			b $0a
			b $00
			b $10
			b $0c
			b $00
			b $00
;---

;*** Laufwerk auf LISTEN schalten.
:devLISTEN		lda	#$6f
			pha
			lda	#$00
			sta	DEVSTAT			;Fehlerstatus löschen.
			lda	DEVADR			;Aktuelle Geräteadresse.
			jsr	LISTEN			;LISTEN auf IEC-Bus senden.
			pla
			jsr	SECOND			;Sekundäradresse für IEC-Bus.
			lda	DEVSTAT			;Fehlerstatus einlesen.
			clc				;Fehler?
			bpl	:exit			; => Nein, weiter...
			pha
			jsr	doUNLSN			;UNLSN senden.
			pla
			sec				;Fehler.
::exit			rts

:doUNLSN		jmp	UNLSN			;UNLSN auf IEC-Bus senden.

;*** Laufwerk auf TALK schalten.
:devTALK		lda	#$6f
			pha
			lda	#$00
			sta	DEVSTAT			;Fehlerstatus löschen.
			lda	DEVADR			;Aktuelle Geräteadresse.
			jsr	TALK			;TALK auf IEC-Bus senden.
			pla
			jsr	TKSA			;Sekundäradresse für TALK.
			lda	DEVSTAT			;Fehlerstatus einlesen.
			bmi	errNoDev		; => Fehler, Abbruch...
			rts

:doUNTALK		jmp	UNTALK			;UNTALK auf IEC-Bus senden.

;*** Befehl an Laufwerk senden.
;Übergabe: YREG = Zeiger auf Befehl in
;                 der Datentabelle.
;Format: #1 = Anzahl Bytes.
;             Wenn Bit%7 gesetzt, dann
;             wird kein UNLSN gesendet.
;        #x = Datenbytes.
:sendCom		jsr	devLISTEN
			bcs	errNoDev

			lda	comDataTab +0,y
			php
			and	#$7f
			tax
::1			lda	comDataTab +1,y
			jsr	CIOUT			;Zeichen über IEC-Bus ausgeben.
			iny
			dex
			bne	:1
			plp
			bmi	:exit
			jmp	doUNLSN
::exit			rts

;*** Fehler: DEVICE NOT PRESENT!
:errNoDev		jsr	doUNTALK

			lda	DEVADR			;Aktuelle Geräteadresse.
			jsr	DEZASCII
			cpx	#"0"
			bne	:1
			ldx	#" "
::1			stx	:l10
			sta	:l1

			jsr	printText
			b sSETPOS,$09,$08
			b sCLRLIN

if COMPUTER=128
			b BLINKON
endif

;			b "DEVICE"
			b $c4,"EVICE"
			b " #"
			b sCOLOR2
::l10			b "*"
::l1			b "*"
			b sCOLOR1
			b " NOT PRESENT !"

			b CR
			b NULL

			jmp	prgEXIT

;*** Inline-Text ausgeben.
;Aufruf mit:
;  jsr printText
;  b "Text"
;  b NULL
;
;"Text" kann auch Steuerzeichen zur
;formatierung beinhalten.
;Siehe Abschnitt "Systemvariablen".
:printText		php				;Prozessor-Status sichern.

			pha				;Prozessor-Register sichern.
			txa
			pha
			tya
			pha

			tsx				;Rücksprungadresse einlesen.
			lda	STACK +5,x
			ldy	STACK +6,x

			clc				;Zeiger auf Inline-Text
			adc	#$01			;berechnen.
			bcc	:1
			iny

::1			jsr	inlineTxt		;Text ausgeben.

			tsx				;Rücksprungadresse
			sec				;korrigieren.
			lda	STRVEC +0
			sbc	#$01
			sta	STACK +5,x
			lda	STRVEC +1
			sbc	#$00
			sta	STACK +6,x

			pla				;Reset Prozessor-Register.
			tay
			pla
			tax
			pla

			plp				;Reset Prozessor-Status.
			rts				;Zurück zum Programm.

;*** Textstring ausgeben.
:inlineTxt		sta	STRVEC +0		;Zeiger auf Textdaten.
			sty	STRVEC +1

:doNxChar		jsr	getStrChar		;Zeichen einlesen.
			beq	endOfTxt		; => String-Ende erreicht.

			cmp	#sSETPOS
			bne	:2

			jsr	getStrChar		;Zeile einlesen.
			tax				;Zeile setzen?
			bpl	:1			; => Ja, weiter...

			sec				;Cursor-Position einlesen.
			jsr	doCrsrPos		;Akt. Zeile in XReg einlesen.

::1			jsr	getStrChar		;Spalte einlesen.
			tay				;Neue Spalte.
			clc				;Cursor-Position setzen.
			jsr	doCrsrPos
			jmp	:next

::2			cmp	#sRPTCHR		;Zeichen wiederholen.
			bne	:4
			jsr	getStrChar
			pha
			jsr	getStrChar
			tax
			pla
::3			jsr	doPrnChar
			dex
			bne	:3
			jmp	:next

::4			cmp	#sCLRLIN		;Zeile löschen.
			bne	:5
			ldx	TBLX			;Cursor-Zeile.
			jsr	DELLINE			;Zeile löschen.
			jmp	:next

;--- Hinweis: $E3 wird nicht verwendet.
::5			cmp	#sCOLOR1		;$E0-$E3 = Farbe.
			bcc	:6
			cmp	#sUSRCOL +1
			bcs	:6
			sec
			sbc	#sCOLOR1		;$E0-$E3 -> $00-$03.
			jsr	setTextCol
			jmp	:next

::6			cmp	#sCENTER
			beq	:7
			cmp	#sDOCENT
			bne	:8

::7			jsr	chkCenter
			jmp	:next

::8			jsr	doPrnChar
::next			jmp	doNxChar
:endOfTxt		rts

;*** Zeichen aus Inline-String einlesen.
:yRegBuf		b $00
:getStrChar		sty	yRegBuf
			ldy	#$00
			lda	(STRVEC),y
			inc	STRVEC +0
			bne	:1
			inc	STRVEC +1
::1			ldy	yRegBuf
			ora	#$00			;CPU-Flags AKKU-Inhalt setzen.
			rts

;*** Zeichen auf Bildschirm ausgeben.
:doPrnChar		jmp	SCROUT			;Bildschirm-Zeichen ausgeben.

;*** Cursor-Position lesen/setzen.
; CARRY-Flag=0: Position setzen.
; CARRY-Flag=1: Position lesen.
;Übergabe: XREG = Zeile.
;          YREG = Spalte.
:doCrsrPos		jmp	PLOT			;Cursorpos. lesen/setzen.

if COMPUTER=128
:setBackCol		ldx	backColor		;Wert in Data-Register VCR.
			lda	VDCCOL128 -1,x
			ldx	#$1a			;Bit  %0-3 Hintergrund+Rahmen.
			jmp	SETREG128		;Farbe im VDC setzen.
endif

:setTextCol		tax

if COMPUTER=128
			lda	COLOR128		;Nur Farbwert löschen.
			and	#%11110000
			sta	COLOR128
			lda	vecColData,x
			tax
			lda	VDCCOL128 -1,x
			ora	COLOR128
			sta	COLOR128
			rts
endif
if COMPUTER=64
			lda	vecColData,x
			tax
			lda	VICCOL64 -1,x
			sta	COLOR64
			rts

:VICCOL64		b $0e				;Hellblau.
			b $07				;Gelb.
			b $05				;Grün.
endif

;*** Zentrierte Textausgabe?
:chkCenter		cmp	#sDOCENT
			bne	cntCharCent
			rts

;*** Anzahl Zeichen zählen.
;Für zentrierte Textausgabe benötigt.
:cntCharCent		lda	STRVEC +0
			pha
			lda	STRVEC +1
			pha
			ldx	#$ff
::nxChar		jsr	getStrChar
			beq	setCenter		;Ende? => Ja, Text ausgeben.

			cmp	#sDOCENT		;Bisherigen Text zentrieren?
			beq	setCenter		; => Ja, Text ausgeben.

			pha
			and	#$7f
			cmp	#$20
			pla
			bcc	:testCode
			cmp	#$ff
			bcs	:testCode
			sec
			sbc	#$e0
			sec
			sbc	#$20
::testCode		bcc	:loop
			inx
::loop			jmp	:nxChar

;*** Cursor-Position berechnen.
;Für zentrierte Textausgabe benötigt.
:setCenter		lda	ZPBUF2
			pha
			stx	ZPBUF2
			sec
if COMPUTER=128
			lda	WINRGT128
endif
if COMPUTER=64
			lda	#39
endif
			sbc	PNTR			;Cursor-Spalte.
			sec
			sbc	ZPBUF2
			bcs	:1
			lda	#$00
::1			lsr
			clc
			adc	PNTR			;Aktuelle Cursor-Spalte.
			sta	PNTR			;Neue Cursor-Spalte.
			pla
			sta	ZPBUF2
			pla
			sta	STRVEC +1
			pla
			sta	STRVEC +0
			rts

;*** Auf Tasten J/N warten.
:waitYesNo		jsr	waitKey
			cmp	#"J"
			clc
			beq	:1
			cmp	#"N"
			bne	waitYesNo
::1			rts

;*** Auf Tastendruck warten.
:waitKey		jsr	getNewKey		;Tastendruck einlesen.
			beq	waitKey			; => Kein taste, warten...
			rts

;*** Taste über Kernal einlesen.
:getNewKey		jmp	KGETIN			;Kernal/GETIN von Tastatur.

;*** Zeichen über IEC-Bus empfangen.
;Übergabe: XReg/YReg = Zeiger auf Puffer.
;          AAKKU = Anzahl Bytes.
:devGetByt		stx	ZPVEC1 +0
			sty	ZPVEC1  +1
			sta	rdBytCnt
			ldy	#comRdDat3
			jsr	sendCom
			jsr	devTALK
			ldx	rdBytCnt
			ldy	#$00
::1			jsr	ACPTR			;Zeichen über IEC-Bus einlesen.
			sta	(ZPVEC1),y
			iny
			dex
			bne	:1
			jsr	doUNTALK
			rts

;*** SCSI-Blockadresse erhöhen.
;Die Adresse besteht aus 4 Bytes im
;MSB...LSB-Format.
;Die Routine wird für zwei Bereiche
;verwendet und entweder um
;  1Byte erhöht -> :chkSCSIDev oder um
;128Byte erhöht -> :findSysP
;Übergabe: XREG/AKKU = $00/$01 oder
;                      $xx/$80
;          xx = (scsiBlkAdr - scsiBuf8)
:inc4BWord		clc
			adc	scsiBuf8 +3,x
			sta	scsiBuf8 +3,x
			bcc	:1
			inc	scsiBuf8 +2,x
			bne	:1
			inc	scsiBuf8 +1,x
			bne	:1
			inc	scsiBuf8 +0,x
::1			rts

;*** SCSI-Blockadresse testen.
;Die Routine überprüft ob die aktuelle
;SCSI-Blockadresse noch innerhalb der
;Systempartition liegt.
;Übergabe: XREG/YREG = $xx/$00
;          xx = (scsiBlkAdr - scsiBuf8)
;Da XREG hier immer <>$00 ist, wird
;immer :scsiBlkAdr/XREG mit der Adresse
;:scsiBuf8/YREG verglichen!!!
:chkEndOfP		lda	scsiBuf8 +0,x
			cmp	scsiBuf8 +0,y
			bne	:1
			lda	scsiBuf8 +1,x
			cmp	scsiBuf8 +1,y
			bne	:1
			lda	scsiBuf8 +2,x
			cmp	scsiBuf8 +2,y
			bne	:1
			lda	scsiBuf8 +3,x
			cmp	scsiBuf8 +3,y
::1			rts
