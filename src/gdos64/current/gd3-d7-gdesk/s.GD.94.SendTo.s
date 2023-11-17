; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Dateien senden.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CROM"
			t "SymbTab_GDOS"
			t "SymbTab_GEXT"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
;			t "SymbTab_MMAP"
			t "SymbTab_APPS"
;			t "SymbTab_GRFX"
			t "SymbTab_CHAR"
;			t "SymbTab_KEYS"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
			t "e.Register.ext"

;--- Variablen für Status-Box:
:STATUS_X		= $0040
:STATUS_W		= $00c0
:STATUS_Y		= $30
:STATUS_H		= $50

;--- Fortschrittsbalken.
:STATUS_CNT_X1		= STATUS_X +16
:STATUS_CNT_X2		= (STATUS_X + STATUS_W) -24 -1
:STATUS_CNT_W		= (STATUS_CNT_X2 - STATUS_CNT_X1) +1
:STATUS_CNT_Y1		= (STATUS_Y + STATUS_H) -16
:STATUS_CNT_Y2		= (STATUS_Y + STATUS_H) -16 +8 -1

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_Y1		= STATUS_Y +26
:INFO_Y2		= STATUS_Y +36
:INFO_Y3		= STATUS_Y +46
endif

;*** GEOS-Header.
			n "obj.GD94"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xSENDFILESMENU		;Menü anzeigen.
			jmp	xSENDFILESPRNT		;Dateien an Drucker senden.
			jmp	xSENDFILESDRV1		;Dateien an Laufwerk#1 senden.
			jmp	xSENDFILESDRV2		;Dateien an Laufwerk#2 senden.

;*** Systemroutinen.
			t "-SYS_STATMSG"
			t "-SYS_DISKFILE"
			t "-Gxx_IBoxCore"
			t "-Gxx_IBoxDisk"
			t "-Gxx_IBoxFile"

;*** "Senden an"-Menü anzeigen.
:xSENDFILESMENU		lda	#$ff			;Vorgabe für "Abbruch".
			sta	jobCode

			jsr	initWriteType1
			jsr	initWriteType2

			LoadW	r0,RegMenu1		;Zeiger auf Register-Menü.
			jmp	ENABLE_REG_MENU		;Register-Menü starten.

;*** Zurück zum DeskTop.
:ExitRegMenuUser	jsr	sys_LdBackScrn		;Bildschirm zurücksetzen.

			lda	exitCode		;Fehler aufgetreten?
			bne	:exit			; => Ja, Abbruch...

			lda	jobCode			;"Senden"-Icon gewählt?
			bmi	:exit			; => Nein, Abbruch...

			cmp	#$01			;Laufwerk#1?
			beq	:1			; => Ja, weiter...
			cmp	#$02			;Laufwerk#2?
			beq	:2			; => Ja, weiter...

			lda	#< xSENDFILESPRNT	;Senden an Drucker.
			ldx	#> xSENDFILESPRNT
			bne	:exec

::1			lda	#< xSENDFILESDRV1	;Senden an Laufwerk#1.
			ldx	#> xSENDFILESDRV1
			bne	:exec

::2			lda	#< xSENDFILESDRV2	;Senden an Laufwerk#2.
			ldx	#> xSENDFILESDRV2

::exec			jmp	CallRoutine		;"Senden an" ausführen.

;--- Menü beenden.
::exit			jsr	SET_LOAD_CACHE		;Verzeichnis von Cache einlesen.
			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Icon "Senden an" gewählt.
;    Rückgabewerte "ExecRegMenuUser":
;    $00 = DeskTop           exitCode = $00
;    $FF = RegisterMenü      exitCode = $FF
;    $xx = Ausführen/Fehler  exitCode = $7F
:ExecRegMenuUser	ldx	#NO_ERROR		;Zurück zum DeskTop.
			rts

;*** Register-Menü.
:R1SizeY0		= $28
:R1SizeY1		= $9f
:R1SizeX0		= $0028
:R1SizeX1		= $010f

:RegMenu1		b R1SizeY0			;Register-Größe.
			b R1SizeY1
			w R1SizeX0
			w R1SizeX1

			b 1				;Anzahl Einträge.

			w RegTName1			;Register: "SENDEN".
			w RegTMenu1

;*** Register-Icons.
:RegTName1		w RTabIcon1
			b RCardIconX_1,R1SizeY0 -$08
			b RTabIcon1_x,RTabIcon1_y

if LANG = LANG_DE
:RTabIcon1
<MISSING_IMAGE_DATA>

endif

if LANG = LANG_EN
:RTabIcon1
<MISSING_IMAGE_DATA>

endif

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIconX_1		= (R1SizeX0/8) +3
:RCardIconX_2		= RCardIconX_1 + RTabIcon1_x

;*** System-Icons einbinden.
if .p
:EnableMSelect		= FALSE
:EnableMSlctUp		= FALSE
:EnableMUpDown		= TRUE
:EnableMButton		= FALSE
endif
			t "-SYS_ICONS"

;*** Icons.
:RIcon_UpDown		w Icon_MUpDown
			b %00000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_MUpDown_x,Icon_MUpDown_y
			b USE_COLOR_INPUT

:RIcon_SendDrv1		w Icon_SendDrv1
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SendDrv1_x,Icon_SendDrv1_y
			b USE_COLOR_INPUT

:Icon_SendDrv1
<MISSING_IMAGE_DATA>

:Icon_SendDrv1_x	= .x
:Icon_SendDrv1_y	= .y

:RIcon_SendDrv2		w Icon_SendDrv2
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SendDrv2_x,Icon_SendDrv2_y
			b USE_COLOR_INPUT

:Icon_SendDrv2
<MISSING_IMAGE_DATA>

:Icon_SendDrv2_x	= .x
:Icon_SendDrv2_y	= .y

:RIcon_SendPrnt		w Icon_SendPrnt
			b %10000000			;Bit%7=1: iconSelFlag beachten.
							;Bit%6=1: Kein Icon-Status anzeigen.
			b $00				;Reserved for future use.
			b Icon_SendPrnt_x,Icon_SendPrnt_y
			b USE_COLOR_INPUT

:Icon_SendPrnt
<MISSING_IMAGE_DATA>

:Icon_SendPrnt_x	= .x
:Icon_SendPrnt_y	= .y

;*** Daten für Register "SENDEN AN".
:RPos1_x  = R1SizeX0 +$10
:RPos1_y  = R1SizeY0 +$10
:RTab1_1  = $0080
:RTab1_2  = $0068
:RTab1_3  = $0048
:RTab1_4  = $00c0
:RTab1_5  = $0058
:RTab1_6  = $00d0
:RTab1_7  = $0038
:RTab1_8  = $0080
:RTab1_9  = $0080
:RTab1_10 = $0000
:RTab1_11 = $0078
:RLine1_1 = $00
:RLine1_2 = $10
:RLine1_3 = $30
:RLine1_4 = $50
:RLine1_5 = $40

:RegTMenu1		b 23

;--- Drucker.
			b BOX_FRAME
				w R1T01
				w $0000
				b RPos1_y +RLine1_1 -$05
				b RPos1_y +RLine1_1 +$18 +$06
				w R1SizeX0 +$08
				w R1SizeX1 -$08 -$10 +1
			b BOX_ICON
				w $0000
				w execSendPrinter
				b RPos1_y +RLine1_1
				w R1SizeX1 -$10
				w RIcon_SendPrnt
				b NO_OPT_UPDATE
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_1 -$01
				b RPos1_y +RLine1_1 +$08
				w R1SizeX0 +RTab1_2 +$08
				w R1SizeX0 +RTab1_2 +$08 +$08
::u01a			b BOX_NUMERIC
				w R1T04
				w $0000
				b RPos1_y +RLine1_1
				w R1SizeX0 +RTab1_2
				w GD_SENDTO_PRN
				b 1!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setPrntAdr
				b RPos1_y +RLine1_1
				w R1SizeX0 +RTab1_2 +$08
				w RIcon_UpDown
				b (:u01a - RegTMenu1 -1)/11 +1
			b BOX_USEROPT
				w R1T09
				w switchSendLFCR
				b RPos1_y +RLine1_2
				b RPos1_y +RLine1_2 +$07
				w RPos1_x
				w RPos1_x +$07
			b BOX_OPTION
				w R1T10
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_7
				w GD_SENDTO_XPRN
				b %00010000
			b BOX_OPTION
				w R1T11
				w $0000
				b RPos1_y +RLine1_2
				w RPos1_x +RTab1_8
				w GD_SENDTO_XPRN
				b %00001000
			b BOX_OPTION
				w R1T12
				w $0000
				b RPos1_y +RLine1_1
				w RPos1_x +RTab1_9
				w GD_SENDTO_XPRN
				b %10000000

;--- Laufwerk#1.
			b BOX_FRAME
				w R1T02
				w $0000
				b RPos1_y +RLine1_3 -$05
				b RPos1_y +RLine1_3 +$28 +$06
				w R1SizeX0 +$08
				w R1SizeX0 +RTab1_1 -$18
			b BOX_ICON
				w $0000
				w execSendDrive1
				b RPos1_y +RLine1_3
				w R1SizeX0 +RTab1_1 -$18
				w RIcon_SendDrv1
				b NO_OPT_UPDATE
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_3 -$01
				b RPos1_y +RLine1_3 +$08
				w R1SizeX0 +RTab1_3 +$08
				w R1SizeX0 +RTab1_3 +$08 +$10
:u02a			b BOX_NUMERIC
				w R1T05
				w $0000
				b RPos1_y +RLine1_3
				w R1SizeX0 +RTab1_3
				w GD_SENDTO_DRV1
				b 2!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setPrntDrv1
				b RPos1_y +RLine1_3
				w R1SizeX0 +RTab1_3 +$10
				w RIcon_UpDown
				b (u02a - RegTMenu1 -1)/11 +1
			b BOX_OPTION
				w R1T07
				w setWriteType1
				b RPos1_y +RLine1_4
				w R1SizeX0 +RTab1_5
				w GD_SENDTO_XDRV1
				b %10000000
:u02b			b BOX_OPTION
				w R1T13
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_10
				w GD_SENDTO_XDRV1
				b %01000000

;--- Laufwerk#2.
			b BOX_FRAME
				w R1T03
				w $0000
				b RPos1_y +RLine1_3 -$05
				b RPos1_y +RLine1_3 +$28 +$06
				w R1SizeX0 +RTab1_1 -1
				w R1SizeX1 -$08
			b BOX_ICON
				w $0000
				w execSendDrive2
				b RPos1_y +RLine1_3 +$18
				w R1SizeX0 +RTab1_1 -$10
				w RIcon_SendDrv2
				b NO_OPT_UPDATE
			b BOX_FRAME
				w $0000
				w $0000
				b RPos1_y +RLine1_3 -$01
				b RPos1_y +RLine1_3 +$08
				w R1SizeX0 +RTab1_4 +$08
				w R1SizeX0 +RTab1_4 +$08 +$10
:u03a			b BOX_NUMERIC
				w R1T06
				w $0000
				b RPos1_y +RLine1_3
				w R1SizeX0 +RTab1_4
				w GD_SENDTO_DRV2
				b 2!NUMERIC_LEFT!NUMERIC_BYTE
			b BOX_ICON
				w $0000
				w setPrntDrv2
				b RPos1_y +RLine1_3
				w R1SizeX0 +RTab1_4 +$10
				w RIcon_UpDown
				b (u03a - RegTMenu1 -1)/11 +1
			b BOX_OPTION
				w R1T08
				w setWriteType2
				b RPos1_y +RLine1_4
				w R1SizeX0 +RTab1_6
				w GD_SENDTO_XDRV2
				b %10000000
:u03b			b BOX_OPTION
				w R1T14
				w $0000
				b RPos1_y +RLine1_5
				w RPos1_x +RTab1_11
				w GD_SENDTO_XDRV2
				b %01000000

;*** Texte für Register "SENDEN AN".
if LANG = LANG_DE
:R1T01			b "DRUCKER",NULL
:R1T02			b "LAUFWERK#1",NULL
:R1T03			b "LAUFWERK#2",NULL
:R1T04			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Geräteadresse:",NULL
:R1T05			w RPos1_x
			b RPos1_y +RLine1_3 +$06
			b "Adresse:",NULL
:R1T06			w R1SizeX0 +RTab1_1 +$08
			b RPos1_y +RLine1_3 +$06
			b "Adresse:",NULL
:R1T07			w RPos1_x
			b RPos1_y +RLine1_4 +$06 -$04
			b "GeoWrite"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_4 +$06 +$04
			b "Dokumente:",NULL
:R1T08			w R1SizeX0 +RTab1_1 +$08
			b RPos1_y +RLine1_4 +$06 -$04
			b "GeoWrite"
			b GOTOXY
			w R1SizeX0 +RTab1_1 +$08
			b RPos1_y +RLine1_4 +$06 +$04
			b "Dokumente:",NULL
:R1T09			w RPos1_x +$0c
			b RPos1_y +RLine1_2 +$06
			b "LF/CR",NULL
:R1T10			w RPos1_x +RTab1_7 +$0c
			b RPos1_y +RLine1_2 +$06
			b "FormFeed",NULL
:R1T11			w RPos1_x +RTab1_8 +$0c
			b RPos1_y +RLine1_2 +$06
			b "PETSCII",NULL
:R1T12			w RPos1_x +RTab1_9 +$0c
			b RPos1_y +RLine1_1 +$06
			b "GEOS>UTF",NULL
:R1T13			w RPos1_x +RTab1_10 +$0c
			b RPos1_y +RLine1_5 +$06
			b "Konvertieren",NULL
:R1T14			w RPos1_x +RTab1_11 +$0c
			b RPos1_y +RLine1_5 +$06
			b "Konvertieren",NULL
endif
if LANG = LANG_EN
:R1T01			b "PRINTER",NULL
:R1T02			b "DRIVE#1",NULL
:R1T03			b "DRIVE#2",NULL
:R1T04			w RPos1_x
			b RPos1_y +RLine1_1 +$06
			b "Device address:",NULL
:R1T05			w RPos1_x
			b RPos1_y +RLine1_3 +$06
			b "Address:",NULL
:R1T06			w R1SizeX0 +RTab1_1 +$08
			b RPos1_y +RLine1_3 +$06
			b "Address:",NULL
:R1T07			w RPos1_x
			b RPos1_y +RLine1_4 +$06 -$04
			b "GeoWrite"
			b GOTOXY
			w RPos1_x
			b RPos1_y +RLine1_4 +$06 +$04
			b "Documents:",NULL
:R1T08			w R1SizeX0 +RTab1_1 +$08
			b RPos1_y +RLine1_4 +$06 -$04
			b "GeoWrite"
			b GOTOXY
			w R1SizeX0 +RTab1_1 +$08
			b RPos1_y +RLine1_4 +$06 +$04
			b "Documents:",NULL
:R1T09			w RPos1_x +$0c
			b RPos1_y +RLine1_2 +$06
			b "LF/CR",NULL
:R1T10			w RPos1_x +RTab1_7 +$0c
			b RPos1_y +RLine1_2 +$06
			b "FormFeed",NULL
:R1T11			w RPos1_x +RTab1_8 +$0c
			b RPos1_y +RLine1_2 +$06
			b "PETSCII",NULL
:R1T12			w RPos1_x +RTab1_9 +$0c
			b RPos1_y +RLine1_1 +$06
			b "GEOS>UTF",NULL
:R1T13			w RPos1_x +RTab1_10 +$0c
			b RPos1_y +RLine1_5 +$06
			b "Convert",NULL
:R1T14			w RPos1_x +RTab1_11 +$0c
			b RPos1_y +RLine1_5 +$06
			b "Convert",NULL
endif

;*** Drucker-Adresse wechseln.
:setPrntAdr		lda	mouseYPos		;Position Mauszeiger einlesen.
			and	#%00000111		;Up/Down?
			cmp	#4			; Y>=4?
			bcc	:down			; => Ja, runterzählen...

::up			lda	GD_SENDTO_PRN		;Drucker-Adresse = $00?
			beq	:setprn			; => Ja, auf Standard setzen.
			sec
			sbc	#1			;Adresse -1.
			cmp	#4			;Adresse gültig?
			bcs	:u1			; => Ja, weiter...
			lda	#7			;Adresse zurücksetzen.
::u1			sta	GD_SENDTO_PRN		;Neue Adresse setzen.
			rts

::down			lda	GD_SENDTO_PRN		;Drucker-Adresse = $00?
			beq	:setprn			; => Ja, auf Standard setzen.
			clc
			adc	#1			;Adresse +1.
			cmp	#8			;Adresse gültig?
			bcc	:d1			; => Ja, weiter...
::setprn		lda	#4			;Adresse zurücksetzen.
::d1			sta	GD_SENDTO_PRN		;Neue Adresse setzen.
			rts

;*** Drucker-Adresse wechseln.
:setPrntDrv1		ldx	#0
			b $2c
:setPrntDrv2		ldx	#(GD_SENDTO_DRV2 - GD_SENDTO_DRV1)

			lda	mouseYPos		;Position Mauszeiger einlesen.
			and	#%00000111		;Up/Down?
			cmp	#4			; Y>=4?
			bcc	:down			; => Ja, runterzählen...

::up			lda	GD_SENDTO_DRV1,x	;Laufwerks-Adresse einlesen.
			sec
			sbc	#1			;Adresse -1.
			cmp	#8			;Adresse gültig?
			bcs	:u1			; => Ja, weiter...
			lda	#29			;Adresse zurücksetzen.
::u1			sta	GD_SENDTO_DRV1,x	;Neue Adresse setzen.
			rts

::down			lda	GD_SENDTO_DRV1,x	;Laufwerks-Adresse einlesen.
			clc
			adc	#1			;Adresse +1.
			cmp	#30			;Adresse gültig?
			bcc	:d1			; => Ja, weiter...
			lda	#8			;Adresse zurücksetzen.
::d1			sta	GD_SENDTO_DRV1,x	;Neue Adresse setzen.
			rts

;*** LF/CR senden.
:switchSendLFCR		bit	r1L			;Register-Menü aufbauen?
			bpl	updateSendLFCR		; => Ja, weite...

			lda	GD_SENDTO_XPRN		;Aktuellen Modus einlesen und
			and	#%01100000		;auf nächsten Modus wechseln.
			beq	:1
			cmp	#%01000000
			beq	:2
			lda	#%00000000		; => LF/CR nicht verändern.
			b $2c
::1			lda	#%01000000		; => LF anhängen.
			b $2c
::2			lda	#%01100000		; => CR durch LF ersetzen.
::3			sta	r0L
			lda	GD_SENDTO_XPRN		;Aktuellen Modus einlesen und
			and	#%10011111		;LF/CR-Bits löschen.
			ora	r0L			;Neuen Modus für LF/CR festlegen.
			sta	GD_SENDTO_XPRN

;*** LF/CR senden.
;RegisterMenü / Tri-State-Option.
:updateSendLFCR		lda	GD_SENDTO_XPRN		;Aktuellen Modus einlesen.
			and	#%01100000
			beq	:off
			cmp	#%01000000
			bne	:all

::top			lda	#$02			; => LF ergänzen
			b $2c
::all			lda	#$01			; => CR durch LF ersetzen.
			b $2c
::off			lda	#$00			; => Keine Veränderung
			jsr	SetPattern		;Füllmuster setzen.

			jsr	i_Rectangle		;Tri-State-Option anzeigen.
			b RPos1_y +RLine1_2 +1
			b RPos1_y +RLine1_2 +6
			w RPos1_x +1
			w RPos1_x +6

			rts

;*** Konvertierung setzen.
:setWriteType1		ldx	#0
			b $2c
:setWriteType2		ldx	#(GD_SENDTO_DRV2 - GD_SENDTO_DRV1)

			lda	GD_SENDTO_XDRV1,x	;GeoWrite-Modus?
			bmi	:1			; => Ja, weiter...

			and	#%10111111		;Konvertierung deaktivieren.
			sta	GD_SENDTO_XDRV1,x

			lda	#BOX_OPTION_VIEW
			b $2c
::1			lda	#BOX_OPTION

			cpx	#0
			bne	:2

			sta	u02b

			ldx	#< u02b			;Konvertieren Laufwerk #1.
			ldy	#> u02b
			bne	:3

::2			sta	u03b

			ldx	#< u03b			;Konvertieren Laufwerk #1.
			ldy	#> u03b

::3			stx	r15L			;Konvertieren sperren/freigeben.
			sty	r15H

			jmp	RegisterUpdate		;Register-Menü aktualisieren.

;*** Konvertierung initialisieren.
:initWriteType1		ldx	#0
			b $2c
:initWriteType2		ldx	#(GD_SENDTO_DRV2 - GD_SENDTO_DRV1)

			lda	GD_SENDTO_XDRV1,x	;GeoWrite-Modus?
			bmi	:1			; => Ja, weiter...

			lda	#BOX_OPTION_VIEW
			b $2c
::1			lda	#BOX_OPTION

			cpx	#0
			bne	:2

			sta	u02b
			rts

::2			sta	u03b
			rts

;*** Dateien senden.
:xSENDFILESDRV1		ldx	#0
			b $2c
:xSENDFILESDRV2		ldx	#(GD_SENDTO_DRV2 - GD_SENDTO_DRV1)

			lda	GD_SENDTO_DRV1,x	;Laufwerksadresse gültig?
			bne	:setDrvData		; => Ja, weiter...
			jmp	xSENDFILESMENU		; => Nein, Menü aufrufen...

::setDrvData		ldy	GD_SENDTO_XDRV1,x	;"Nur GeoWrite-Dokumente"-Flag
			sty	convMode		;einlesen und speichern.

;			lda	#DEVADR			;Geräteadresse im AKKU!
			ldx	#< CIOUT		;Zeichenausgabe 1:1 auf IEC-Bus.
			ldy	#> CIOUT
			bne	setTargetDev

:xSENDFILESPRNT		ldx	#< convPrntData		;Zeichen für Druckausgabe
			ldy	#> convPrntData		;konvertieren.

			lda	GD_SENDTO_PRN		;Druckeradresse gültig?
			beq	exitSendFiles		; => Nein, Abbruch...

:setTargetDev		stx	a9L			;Routine für Zeichenausgabe
			sty	a9H			;festlegen.

			sta	targetDevice		;Ausgabegerät festlegen.

			cmp	#12			;GEOS-Laufwerk?
			bcs	:1			; => Nein, weiter...
			tax
			lda	driveType -8,x		;RAM-Laufwerk?
			bmi	:1			; => Ja, weiter...
			cpx	curDrive		;Ziel = Quelle?
			beq	exitDrvError		; => Ja, Fehler...

::1			jsr	testTargetDev		;Ziel-Laufwerk testen.
			txa				;Fehler?
			bne	exitError		; => Ja, Abbruch...

			jsr	countFiles		;Dateinamen in Speicher kopieren.

			lda	slctFiles		;Dateien ausgewählt?
			beq	exitSendFiles		; => Nein, Ende...

			sei
			clc				;Mauszeigerposution nicht ändern.
			jsr	StartMouseMode		;Mausabfrage starten.
			cli				;Interrupt zulassen.

			jsr	waitNoMseKey		;Warten bis keine M-Taste gedrückt.

;--- Zeiger auf erste Datei.
			ClrB	statusPos		;Zeiger auf erste Datei.
			jsr	DrawStatusBox		;Status-Box anzeigen.
			jsr	_ext_PrntDInfo		;Disk-/Verzeichnisname ausgeben.

			lda	slctFiles		;Max.Anzahl Dateien für Statusbox.
			sta	statusMax

			jsr	DoSendFiles		;Dateien senden.
			txa				;Fehler?
			bne	exitError		; => Ja, Abbruch...

:exitSendFiles		jsr	SET_LOAD_CACHE		;Verzeichnis von Cache einlesen.
			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** Fehler: Gleiches Laufwerk.
:exitDrvError		ldx	#$88			;Fehler: "SENDTO_DRV_ERR"

:exitError		lda	curDrive		;Quell-Laufwerk.
			sta	r1L
			lda	targetDevice		;Ziel-Laufwerk.
			sta	r1H

			jsr	doXRegStatus		;Disk-/Laufwerksfehler ausgeben.

			jsr	SET_LOAD_CACHE		;Verzeichnis von Cache einlesen.
			jmp	MOD_UPDATE		;Zurück zum Hauptmenü.

;*** "Senden an" ausführen.
:execSendPrinter	lda	#$00			;"Senden an Drucker"-Icon.
			b $2c
:execSendDrive1		lda	#$01			;"Senden an Laufwerk#1"-Icon.
			b $2c
:execSendDrive2		lda	#$02			;"Senden an Laufwerk#2"-Icon.
			sta	jobCode			;JobCode speichern.

			jmp	EXEC_REG_ROUT		;Menü beenden und Dateien senden.

;*** Dateien zählen.
:countFiles		lda	fileEntryCount		;Anzahl Dateien >0 ?
			bne	:find_files		; => Dateien vorhanden, weiter...

			sta	slctFiles		;Dateizähler löschen.
			rts

::find_files		LoadW	a0,BASE_DIRDATA		;Zeiger auf Verzeichnis-Daten.

			lda	#$00			;Dateizähler auf Angang.
			sta	a2L

			sta	slctFiles		;Dateizähler initialisieren.

::loop			ldy	#$00
			lda	(a0L),y			;Datei ausgewählt?
			beq	:next_file		; => Nein, weiter...

			inc	slctFiles
			lda	slctFiles
			cmp	#255
			beq	:end

::next_file		inc	a2L			;Dateizähler +1.

::1			AddVBW	32,a0			;Nächster Verzeichnis-Eintrag.

			lda	a2L			;Alle markierte Einträge kopiert?
			cmp	fileEntryCount
::2			bcc	:loop			; => Nein, weiter...

::end			rts

;*** Dateien senden.
:DoSendFiles		LoadW	a0,BASE_DIRDATA		;Zeiger auf Verzeichnis-Daten.

			lda	#$00			;Dateizähler auf Angang.
			sta	a2L

::loop			ldy	#$00
			lda	(a0L),y			;Datei ausgewählt?
			beq	:next_file		; => Nein, weiter...

			jsr	initFileData		;Verzeichnis-Eintrag speichern.
			txa				;Fehler?
			bne	:next_file		; => Ja, nächste Datei.

			jsr	_ext_UpdStatus		;Verzeichnis/Datei anzeigen.

			jsr	initDataChan		;Ausgabekanal initialisieren.
			jsr	SendDataStream		;Datei senden.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			inc	statusPos
			jsr	_ext_PrntStat		;Fortschrittsbalken aktualisieren.

::next_file		inc	a2L			;Dateizähler +1.

::1			AddVBW	32,a0			;Nächster Verzeichnis-Eintrag.

			lda	a2L			;Alle markierte Einträge kopiert?
			cmp	fileEntryCount
::2			bcc	:loop			; => Nein, weiter...

			ldx	#NO_ERROR
::error			rts

;*** Ziel-Laufwerk testen.
:testTargetDev		lda	curDevice		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	openFComChan		;Befehlskanal öffnen.
;			bcs	:error

			lda	#NO_ERROR		;Fehler-Status löschen.
			sta	STATUS

			jsr	CLRCHN			;I/O zurücksetzen.
			jsr	closeFComChan		;Befehlskanal schließen.

			ldx	STATUS
			beq	:ok

::error			ldx	#DEV_NOT_FOUND

::ok			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

			rts				;Ende.

;*** Daten für Ein-/Ausgabe festlegen.
:initFileData		lda	#0			;IGNORE-Zähler zurücksetzen.
			sta	initIGNORE

			ldy	#$17
			lda	(a0L),y			;GEOS-Dateiformat einlesen und
			sta	copyMode		;zwischenspeichern.

			ldx	targetDevice
			cpx	#8			;Drucker oder Laufwerk?
			bcs	:testmode		; => Laufwerk, weiter...

;--- Druckerausgabe.
			tax				;Drucker:
			beq	:init_source		; => SEQ-Datei, senden...
			bne	:test_geowrite		; => VLIR-Datei, Format testen...

;--- Laufwerk.
::testmode		bit	convMode		;GeoWrite only?
			bmi	:mode2			; => Ja, weiter...

::mode1			tax				;SEQ/Textdatei?
			beq	:init_source		; => Ja, weiter...
			bne	:err			; => Nein, Abbruch...

::mode2			tax				;VLIR/GeoWrite?
			beq	:err			; => Nein, Abbruch...

::test_geowrite		ldy	#$15			;Zeiger auf VLIR-Header
			lda	(a0L),y			;in Zwischenspeicher einlesen.
			beq	:err
			sta	r1L
			iny
			lda	(a0L),y
			sta	r1H

			LoadW	r4,fileHeader		;Zeigr auf VLIR-Header.
			jsr	GetBlock		;VLIR-Header einlesen.
			txa				;Fehler?
			bne	:err			; => Ja, Abbruch...

			LoadW	r0,classWrite
			LoadW	r1,fileHeader +$4d
			lda	#12 +1
			ldx	#r0L
			ldy	#r1L
			jsr	CmpFString		;GeoWrite?
			bne	:err			; => Nein, Abbruch...

			lda	fileHeader +$4d +12 +1
			cmp	#"1"			;GeoWrite V1.x?
			bne	:init_source		; => Nein, weiter...

			lda	#20			;WriteImage v1.1 beginnt mit
			sta	initIGNORE		;10 Words...
			bne	:init_source

::err			ldx	#STRUCT_MISMAT		;VLIR-Datei, Fehler.
			rts

::init_source		ldy	#$03			;Zeiger auf ersten Datensektor
			lda	(a0L),y			;in Zwischenspeicher einlesen.
			sta	a1L
			iny
			lda	(a0L),y
			sta	a1H

			ldx	targetDevice
			cpx	#8			;Drucker oder Laufwerk?
			bcc	:done			; => Drucker, weiter...

			ldy	#$05			;Dateiname übernehmen.
			ldx	#0
::3			lda	(a0L),y
			beq	:4
			cmp	#$a0
			beq	:4
			sta	copyName,x
			sta	curFileName,x
			iny
			inx
			cpx	#16
			bcc	:3

::4			lda	#NULL			;Dateiname für Infobox
			sta	curFileName,x		;abschließen.

			lda	#","			;Format für Datenkanal festlegen.
			sta	copyName,x
			inx

			ldy	#$02
			lda	(a0L),y
			and	#ST_FMODES
			cmp	#PRG
			beq	:2
			lda	#"S"			;SEQ-Datei = ",S,..."
			b $2c
::2			lda	#"P"			;PRG-Datei = ",P,..."
			sta	copyName,x		;CBM-Dateiformat festlegen.
			inx

			lda	#","
			sta	copyName,x
			inx

			lda	#"W"			;Modus: Datei "schreiben".
			sta	copyName,x
			inx

			txa
			sta	lenCopyName		;Länge "DATEINAME" speichern.
			clc
			adc	#2
			sta	lenTestName		;Länge "(AT):DATEINAME" speichern.

::done			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Datenstream in Datei senden.
:SendDataStream		lda	copyMode		;SEQ oder VLIR?
			bne	:sendWritePages

;--- Einzeldatei senden.
::sendDataFile		jsr	SendFileData
			jmp	SendFormFeed

;--- GeoWrite-Seiten senden.
::sendWritePages	MoveB	a1L,r1L			;Zeiger auf VLIR-Header.
			MoveB	a1H,r1H
			LoadW	r4,fileHeader		;Zeiger auf Anfang Zwischenspeicher.
			jsr	GetBlock		;VLIR-Header einlesen.
			txa				;Fehler?
			bne	:sendError		; => Ja, Abbruch...

			inx				;Seitenzähler initialisieren.
			txa

::sendPage		sta	a3L			;Seitenzähler speichern.
			asl
			tay
			lda	fileHeader +0,y		;Zeiger auf VLIR-Datensatz
			beq	:nextPage		;einlesen.
			sta	a1L
			lda	fileHeader +1,y
			sta	a1H
			jsr	SendFileData		;Seite senden.
			txa				;Fehler?
			bne	:sendError		; => Ja, Abbruch...

::nextPage		inc	a3L			;Zeiger auf nächste Seite.
			lda	a3L
			cmp	#61 +1			;Alle Seiten gesendet?
			bcc	:sendPage		; => Nein, weiter...

			jsr	SendFormFeed

			ldx	#NO_ERROR
::sendError		rts

;*** Datei/Datensatz senden.
:SendFileData		lda	initIGNORE		;WriteImage v1.1 beginnt mit
			sta	a3H			;10 Words, sonst 0 Bytes...

::read			jsr	LoadDataBuf		;Daten in Zwischenspeicher laden.
			txa				;Datei-Ende erreicht?
			beq	:write			; => Nein, weiter...
			cpx	#$ff			;Fehler?
			bne	:nodata			; => Ja, Abbruch...

::write			ldx	r4H
			cpx	#> BUF_START		;Daten im Zwischenspeicher?
			beq	:nodata			; => Nein, Ende...

			pha	 			;"Datei-Ende"-Status speichern.
			jsr	SendDataBuf		;Daten an Zielgerät senden.
			pla				;Datei-Ende erreicht?
			beq	:read			; => Nein, weiter...

			ldx	#NO_ERROR		;Kein Fehler.
::nodata		rts

;*** FormFeed senden.
:SendFormFeed		lda	targetDevice
			cmp	#8			;Drucker oder Laufwerk?
			bcs	:end			; => Laufwerk, weiter...

			lda	curDevice		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	openFComChan		;Befehlskanal öffnen.
;			bcs	:error

			jsr	openDataChan		;Datenkanal öffnen.
;			bcs	:error

			ldx	#5			;Ausgabekanal festlegen.
			jsr	CKOUT

			lda	#PAGE_BREAK		;FormFeed an Drucker senden.
			jsr	SendDataByte

::error			jsr	CLRCHN			;I/O zurücksetzen.
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

::end			rts				;Ende.

;*** Datei in Zwischenspeicher laden.
:LoadDataBuf		jsr	EnterTurbo		;TurboDOS aktivieren.
			jsr	InitForIO		;I/O-Bereich einblenden.

			LoadW	r4,BUF_START		;Zeiger auf Anfang Zwischenspeicher.

			lda	a1L			;Track/Sektor einlesen.
			ldx	a1H
::read			sta	r1L			;Aktuelle Track/Sektor-Adresse
			stx	r1H			;speichern.

			jsr	ReadBlock		;Block von Diskette einlesen.
			txa				;Laufwerksfehler?
			bne	:error			; => Ja, Abbruch...

			ldy	#$01			;Zeiger auf nächsten Sektor
			lda	(r4L),y			;einlesen.
			tax
			dey
			lda	(r4L),y

			inc	r4H			;Zeiger auf Zwischenspeicher
			ldy	r4H			;aktualisieren.
			cpy	#> BUF_END		;Puffer voll?
			beq	:full			; => Ja, Ende...

			tay				;Weitere Daten vorhanden?
			bne	:read			; => Ja, nächsten Sektor einlesen.
			beq	:end			; => Nein, Ende...

::full			sta	a1L			;Zeiger auf nächsten Sektor
			stx	a1H			;zwischenspeichern.

			ldx	#$00			;Dateiende nicht erreicht.
			b $2c
::end			ldx	#$ff			;Dateiende erreicht.

::error			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Zwischenspeicher in Datei schreiben.
:SendDataBuf		lda	curDevice		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	openFComChan		;Befehlskanal öffnen.
;			bcs	:error

			jsr	openDataChan		;Datenkanal öffnen.
;			bcs	:error

			lda	#NO_ERROR		;Fehler-Status löschen.
			sta	STATUS

			ldx	#5			;Ausgabekanal festlegen.
			jsr	CKOUT

			LoadW	r4,BUF_START		;Zeiger auf Anfang Zwischenspeicher.

::next_sek		ldy	#0			;Link-Byte einlesen und
			lda	(r4L),y			;zwischenspeichern.
			pha				;Letzter Sektor?
			bne	:1			; => Nein, weiter...
			iny
			lda	(r4L),y			;Letztes Byte im letzten Sektor.
			b $2c
::1			lda	#255			;Letztes Byte im aktuellen Sektor.
			sta	r5L

			ldy	#2 -1			;Zeiger auf erstes Byte -1.
::2			iny				;Zeiger auf nächstes Byte.

			ldx	copyMode		;SEQ oder VLIR?
			beq	:4			; => SEQ, weiter...

			ldx	a3H			;Zeichen ignorieren?
			beq	:4			; => Nein, weiter...
			dec	a3H			;Byte-Zähler korrigieren.
			jmp	:skip			;Weiter mit nächstem Byte...

::4			lda	(r4L),y			;Aktuelles Zeichen einlesen.
			bne	:send			; => Kein $00-Byte, weiter...

			ldx	targetDevice
			cpx	#8			;Drucker oder Laufwerk?
			bcc	:skip			; => Drucker, ignorieren...

			bit	convMode		;Text konvertieren?
			bvs	:skip			; => Ja, NULL-Byte ignorieren...

::send			jsr	SendDataByte		;Byte-Ausgabe auf IEC-Bus.

::skip			ldx	STATUS			;Fehler?
			bne	:3			; => Ja, Abbruch...
			cpy	r5L			;Alle Bytes gesendet?
			bne	:2			; => Nein, weiter...

::3			pla				;Folgen weitere Daten?
			beq	:done			; => Nein, Ende...
			txa				;Fehler aufgetreten?
			bne	:done			; => Ja, Abbruch...

			inc	r4H			;Zeiger auf Zwischenspeicher
			lda	r4H			;aktualisieren.
			cmp	#> BUF_END		;Ende Puffer erreicht?
			bne	:next_sek		; => Nein, weiter...

::done			pha				;Fehler-Status zwischenspeichern.

			jsr	CLRCHN			;I/O zurücksetzen.
			jsr	closeDataChan		;Datenkanal schließen.
			jsr	closeFComChan		;Befehlskanal schließen.

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			pla
			tax				;Fehlerstatus setzen.

			pla
			sta	curDevice		;Aktuelles Laufwerk zurücksetzen.

			rts				;Ende.

;*** Zeichenausgabe.
:SendDataByte		ldx	copyMode		;GeoWrite oder Textdatei?
			beq	:sendbyte		; => Textdatei, weiter...

			cmp	#NULL			;NULL-Byte?
			beq	:sendbyte		; => Ja, senden...
			cmp	#NEWCARDSET		;Neuer Font?
			beq	:skip_cardset		; => Ja, ignorieren...
			cmp	#ESC_RULER		;Seitenanfang?
			beq	:skip_ruler		; => Ja, ignorieren...
			cmp	#ESC_GRAPHICS		;Grafik?
			beq	:skip_graphics		; => Ja, durch Text ersetzen...

			cmp	#PAGE_BREAK		;Neue Seite?
			bne	:senddatabyte		; => Nein, weiter...

			ldx	targetDevice
			cpx	#8			;Drucker oder Laufwerk?
			bcs	:skip_page		; => Laufwerk, weiter...

			lda	GD_SENDTO_XPRN
			and	#%00010000		;FormFeed senden?
			beq	:cr			; => Nein, weiter...

			lda	#PAGE_BREAK		;FormFeed an Drucker senden.
			b $2c
::cr			lda	#CR

::sendbyte		jmp	(a9)			;Zeichenausgabe oder Konvertierung.

::senddatabyte		bit	convMode		;Text konvertieren?
			bvc	:sendbyte		; => Nein, Byte senden...

			jmp	convPrntData		;LF/UTF konvertieren.

;--- NEWCARDSET.
::skip_cardset		lda	#3			;3 Bytes ignorieren...
			b $2c

;--- ESC_RULER.
::skip_ruler		lda	#26			;26 Bytes ignorieren...
			sta	a3H

			rts				;1 Byte ignorieren...

;--- PAGE_BREAK.
::skip_page		bit	convMode		;Text konvertieren?
			bvc	:sendbyte		; => Nein, Byte senden...

			lda	#CR
			jmp	:senddatabyte

;--- ESC_GRAPHICS.
::skip_graphics		lda	#4			;4 Bytes ignorieren...
			sta	a3H

			tya				;YReg zwischenspeichern.
			pha

			ldy	#0			;Ersatztext senden.
::sg1			lda	dummyGraphics,y
			beq	:sg2
			jsr	:senddatabyte
			iny
			bne	:sg1

::sg2			pla
			tay				;YReg zurücksetzen.

			rts

;*** Drucker: Daten konvertieren.
:convPrntData		bit	GD_SENDTO_XPRN		;GEOS/DE nach UTF8 wandeln?
			bpl	:1			; => Nein, weiter...

;--- GEOS>UTF8.
			ldx	#0			;Ersatzzeichen suchen.
::u1			cmp	:geosdata,x		;UTF8-Code gefunden?
			beq	:u2			; => Ja, weit
			inx
			cpx	:maxdata		;Alle Zeichen durchsucht?
			bne	:u1			; => Nein, weiter...
			beq	:1			; => Ja, weiter..

::u2			lda	:utf8head,x		;Ausgabe UTF8-Header-Code.
			jsr	CIOUT
			lda	:utf8data,x		;UTF8-Zeichen einlesen und
			jmp	CIOUT			;Zeichen ausgeben.

;--- LF/CR.
::1			cmp	#CR			;Zeilenumbruch?
			bne	:2			; => Nein, weiter...

			lda	GD_SENDTO_XPRN
			and	#%01100000
			beq	:lc1			; => Keine Veränderung.
			cmp	#%01000000
			bne	:lc2			; => CR durch LF ersetzen.

			lda	#CR			;LF an CR anhängen.
			jsr	CIOUT

::lc2			lda	#LF			;LF senden.
			b $2c
::lc1			lda	#CR			;CR senden.
			jmp	CIOUT

;--- PETSCII.
::2			ldx	targetDevice
			cpx	#8			;Drucker oder Laufwerk?
			bcs	:3			; => Laufwerk, Byte senden...

			pha
			lda	GD_SENDTO_XPRN		;PETSCII konvertieren?
			and	#%00001000
			tax
			pla

			dex
			bmi	:3			; => Nein, weiter...

			cmp	#65			;"a" bis "z" ?
			bcc	:pt2			; => Nein, weiter...
			cmp	#91
			bcs	:pt2			; => Nein, weiter...
::pt1			clc
			adc	#32			;Nach ASCII wandeln und ausgeben.
			jmp	CIOUT

::pt2			cmp	#193			;"A" bis "Z" ?
			bcc	:pt4			; => Nein, weiter...
			cmp	#219
			bcs	:pt4			; => Nein, weiter...
::pt3			sec
			sbc	#128			;Nach ASCII wandeln und ausgeben.
::pt4			jmp	CIOUT

;--- Keine Konvertierung.
::3			jmp	CIOUT			;Zeichen ausgeben.

;--- Zeichentabelle GEOS/UTF8-Zeichen.
::geosdata		b $5b,$5c,$5d
			b $7b,$7c,$7d,$7e
			b $40,$00,$00,$00
			b $00,$00,$00,$00
			b $00

;--- Max. Anzahl UTF8-Zeichen.
::maxdata		b (:maxdata - :geosdata)

;--- Zeichentabelle UTF8-Zeichen.
::utf8data		b $84,$96,$9c
			b $a4,$b6,$bc,$9f
			b $a7,$00,$00,$00
			b $00,$00,$00,$00
			b $00

;--- UTF8-Header.
::utf8head		b $c3,$c3,$c3
			b $c3,$c3,$c3,$c3
			b $c2,$00,$00,$00
			b $00,$00,$00,$00
			b $00

;*** Befehlskanal öffnen.
:openFComChan		lda	targetDevice
			cmp	#8			;Drucker oder Laufwerk?
			bcc	:error			; => Drucker, Abbruch...

			lda	#0
			jsr	SETNAM			;Keine Daten für Befehlskanal.

			lda	#15
			tay
			ldx	targetDevice
			jsr	SETLFS			;Daten für Befehlskanal.

			jsr	OPENCHN			;Befehlskanal #15 öffnen.
;			bcs	:error

::error			rts

;*** Befehlskanal schließen.
:closeFComChan		lda	targetDevice
			cmp	#8			;Drucker oder Laufwerk?
			bcc	:error			; => Drucker, Abbruch...

			lda	#15			;Befehlskanal schließen.
			jsr	CLOSE

::error			rts

;*** Ausgabekanal schließen.
:closeDataChan		lda	#5			;Datenkanal schließen.
			jmp	CLOSE

;*** Zieldatei erstellen.
:initDataChan		lda	curDevice		;Aktuelles Laufwerk
			pha				;zwischenspeichern.

			jsr	ExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			lda	lenTestName
			ldx	#< testName
			ldy	#> testName
			jsr	SETNAM			;Dateiname für "überschreiben".

			lda	#5
			tay
			ldx	targetDevice
			jsr	SETLFS			;Daten für Zieldatei.

			jsr	OPENCHN			;Zieldatei ersetzen/erzeugen.
;			bcs	:error

::error			jsr	CLRCHN			;I/O zurücksetzen.

			lda	#5			;Zieldatei schließen.
			jsr	CLOSE

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			lda	#"A"			;Dateiname für "Anhängen"
			ldx	lenCopyName		;anpassen.
			dex
			sta	copyName,x

			pla				;Aktuelles Laufwerk zurücksetzen.
			sta	curDevice

			rts				;Ende.

;*** Ausgabekanal öffnen.
:openDataChan		lda	targetDevice
			cmp	#8			;Laufwerk oder Drucker?
			bcs	:drive			; => Laufwerk, weiter...

;--- Druckerkanal öffnen.
::printer		lda	#NULL
			jsr	SETNAM			;Kein Dateiname.

			lda	#5
			ldx	targetDevice
			ldy	#1
			jsr	SETLFS			;Daten für Druckerkanal.

			jsr	OPENCHN			;Druckerkanal öffnen.
;			bcs	:prnterr

::prnterr		rts

;--- Zieldatei öffnen.
::drive			lda	lenCopyName
			ldx	#< copyName
			ldy	#> copyName
			jsr	SETNAM			;Dateiname.

			lda	#5
			tay
			ldx	targetDevice
			jsr	SETLFS			;Daten für Zieldatei.

			jsr	OPENCHN			;Zieldatei öffnen.
;			bcs	:error

::error			rts

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	_ext_InitIBox		;Status-Box anzeigen.
			jsr	_ext_InitStat		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont

			LoadW	r0,jobInfTxConv		;"Dateien senden"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxRemain		;"Auswahl:"
			LoadW	r11,STATUS_X +8		;(Anzahl verbleibender Dateien)
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,infoTxFile		;"Datei"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y3
			jmp	PutString

;*** TexteStatusBox.
if LANG = LANG_DE
:jobInfTxConv		b PLAINTEXT,BOLDON
			b "DATEIEN SENDEN"
			b PLAINTEXT,NULL

:infoTxFile		b "Datei: ",NULL
:infoTxDir		b "Verzeichnis: ",NULL
:infoTxDisk		b "Diskette: ",NULL
:infoTxRemain		b "Verbleibend: ",NULL
endif
if LANG = LANG_EN
:jobInfTxConv		b PLAINTEXT,BOLDON
			b "SENDING FILES"
			b PLAINTEXT,NULL

:infoTxFile		b "Filename: ",NULL
:infoTxDir		b "Directory: ",NULL
:infoTxDisk		b "Disk: ",NULL
:infoTxRemain		b "Remaining: ",NULL
endif

;*** DiskName für StatusBox.
:curDiskName		s 17

;*** Variablen.
:testName		b $40,":"
:copyName		s 16+4

:convMode		b $00				;Bit%7=1: GeoWrite.
:copyMode		b $00				;Bit%0=0: SEQ/Textdatei.
							;Bit%0=1: VLIR/GeoWrite.
:initIGNORE		b $00				;Anzahl Bytes bei Seitenanfang ignorieren.

:slctFiles		b $00
:curFileName		s 17

:lenTestName		b $00
:lenCopyName		b $00

:targetDevice		b 11

:jobCode		b $00

:classWrite		b "Write Image V"
:dummyGraphics		b "                "
			b "<MISSING_IMAGE_DATA>"
			b CR,NULL

;*** Zwischenspeicher.
:DATABUF

:BUF_START		= (DATABUF /256 +1) *256
:BUF_END		= BASE_DIRDATA

;*** Endadresse testen:
			g BASE_DIRDATA
;***
