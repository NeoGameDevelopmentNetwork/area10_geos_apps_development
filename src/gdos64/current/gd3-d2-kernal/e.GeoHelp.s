; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_CSYS"
			t "SymbTab_CXIO"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"

;--- Zwischenspeicher ZeroPage.
:zpageBuf		= LOAD_HELPSYS - (APP_RAM - zpage)
endif

;*** GEOS-Header.
			n "obj.GeoHelp"
			f DATA

			o LOAD_GEOHELP

;*** Speicherbelegung.
;$0400-$05FF  GeoHelp-Loader.
;$0C00-$0FFF  Zwischenspeicher FarbRAM
;             während Dialogbox.
;$1000-$3BFF  GeoHelp.
;$3C00-$5FFF  Textseite.
;$6000-$7FFF  Zwischenspeicher Grafik
;             während Dialogbox.

;******************************************************************************
;*** Systemvariablen.
;******************************************************************************
:JumpTable		jmp	MainInit

;*** Speicher für Werte des aktuellen Tasks.
:RetAdr			w $0000 ;Zwischenspeicher für Rücksprungadresse.
:StackPointer		b $00   ;Zwischenspeicher für Zeiger auf Stack.
:SaveD000		s 48    ;Zwischenspeicher für I/O-Register $D000-$D02F.
:SvCurDrive		b $00   ;Aktuelles Laufwerk.
:SvFlgSpooler		b $00   ;Kopie von ":Flag_Spooler".

;*** Systemeinsprung für TaskManager.
:MainInit		pla				;Rücksprungadresse merken.
			sta	RetAdr +0
			pla
			sta	RetAdr +1

			tsx				;Stackpointer merken
			stx	StackPointer

;--- Zeichen in Tastaturpuffer löschen.
			lda	#$00			;Löscht die Hile/F1-Taste
			sta	keyData			;aus dem Tastaturpuffer.

;--- Speicherbereiche in REU retten.
			ldx	#$1f			;Register ":r0" bis ":r15" retten.
::50			lda	r0L,x
			pha
			dex
			bpl	:50

			lda	#jobStash		;Bereich retten: $0600-$0FFF => REU.
			jsr	SetRAM_Area1
			lda	#jobStash		;Bereich retten: $3C00-$CFFF => REU.
			jsr	SetRAM_Area2

			ldx	#$00			;Register ":r0" bis ":r15"
::51			pla				;wieder zurückschreiben.
			sta	r0L,x
			inx
			cpx	#$20
			bcc	:51

			ldy	#$00			;ZeroPage-Bereich $0000-$03FF
::52			lda	zpage    +$0000,y	;nach ":zPageBuf" = $4000 kopieren.
			sta	zpageBuf +$0000,y	;Notwendig, da die Daten über
			lda	zpage    +$0100,y	;":StashRAM" kopiert werden und die
			sta	zpageBuf +$0100,y	;Routine die ZeroPage verändert.
			lda	zpage    +$0200,y
			sta	zpageBuf +$0200,y
			lda	zpage    +$0300,y
			sta	zpageBuf +$0300,y
			iny
			bne	:52

			lda	#jobStash		;Bereich retten: $0000-$03FF => REU.
			jsr	SetRAM_ZPage		;(Kopie ab ":zpageBuf" verwenden!)

;--- I/O-Register des aktuellen Tasks einlesen.
			ldx	CPU_DATA
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			ldy	#$00
::14			lda	vicbase,y		;I/O-Register auslesen und in
			sta	SaveD000,y		;Zwischenspeicher kopieren.
			iny
			cpy	#$30
			bcc	:14

			stx	CPU_DATA

;--- Ergänzung: 04.09.21/M.Kanet
;GeoWrite verändert ZeroPage-Adressen
;im Bereich von $0080-$00FF. Einige der
;Kernal-Routinen verursachen Probleme,
;wenn hier ungültige Werte vorliegen:
;Innerhalb von GeoWrite wird ab $0094
;ein Zeiger auf die aktuelle Cursor-
;Position innerhalb der Seite abgelegt.
;In Verbindung nur mit einer RAMLink
;(ohne SuperCPU) führt dann ein Aufruf
;von ":LISTEN"=$FFB1 zum Absturz.
;Ursache ist die Adresse $0094 die hier
;ausgelesen wird und in Abhängigkeit
;des Wertes <$80 oder >=$80 das ROM der
;RAMLink umgeschaltet wird. Bei einem
;Wert >=$80 führt das zum Absturz bei
;$ED2D: JMP $(DE34)
			lda	#$00			;ZeroPage-Adressen
			sta	STATUS			;initialisieren.
			sta	C3PO
			sta	BSOUR

;--- Laufwerk zwischenspeichern.
			lda	curDrive
			sta	SvCurDrive		;Aktuelles Laufwerk speichern.

;--- Spooler abschalten.
			lda	Flag_Spooler
			sta	SvFlgSpooler
			and	#%10000000		;Spooler stoppen.
			sta	Flag_Spooler

;--- GeoHelp starten.
			jsr	SaveGEOS_Data		;GEOS-Variablen speichern.
			jsr	UseSystemFont		;GEOS initialisieren.

			jsr	GEOS_InitVar		;Kernel-Variablen initialisier.

			lda	#jobSwap		;Bereich retten: $1000-$3BFF => REU.
			jsr	SetRAM_GEOHELP

			jsr	LOAD_HELPSYS+3		;HilfeSystem starten.

;*** Zurück zu Anwendung.
:ExitGeoHelp		jsr	waitNoMseKey		;Keine Maustaste gedrückt ?

;--- TurboDOS abschalten.
			lda	SvCurDrive		;Aktuelles Laufwerk zurücksetzen.
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	ExitTurbo		;TurboDOS abschalten.

;--- I/O-Bereich wieder herstellen.
			sei				;IRQ sperren. Wichtig da im Anschluß
							;GEOS-Vektoren (IRQ) gesetzt werden
							;und so Anwender-Code ausgeführt
							;werden kann (liegt aber in der REU)

			ldx	CPU_DATA
			lda	#IO_IN
			sta	CPU_DATA

			ldy	#$2f
::12			lda	SaveD000,y		;I/O-Register zurücksetzen.
			sta	vicbase,y
			dey
			bpl	:12

			stx	CPU_DATA

;--- Speicherbereiche wieder herstellen.
			lda	#jobFetch		;Bereich lesen : $3C00-$CFFF => REU.
			jsr	SetRAM_Area2
			lda	#jobSwap		;Bereich lesen : $1000-$3BFF => REU.
			jsr	SetRAM_GEOHELP
			lda	#jobFetch		;Bereich lesen : $0000-$03FF <= REU.
			jsr	SetRAM_ZPage		;(Als Kopie ab ":APP_RAM" ablegen!)

;--- Ergänzung: 27.10.18/M.Kanet
;Da zu diesem Zeitpunkt kein TurboDOS
;mehr aktiv sein kann, reicht es aus
;nur die ":turboFlags" zu löschen.
;Damit wird sichergestellt, das beim
;nächsten Zugriff auf das Laufwerk das
;TurbDOS neu installiert wird.
			ldx	SvCurDrive
			lda	turboFlags -8,x		;TurboDOS-Status vor dem Aufruf
			pha				;der Hilfe zwischenspeichern.

			ldy	#$03			;Turbo-Flags zwischenspeichern.
			lda	#$00
::13			sta	turboFlags,y
			dey
			bpl	:13

			txa				;Aktuelles Laufwerk zurücksetzen.
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	GetDirHead		;BAM einlesen.

			jsr	PurgeTurbo		;TurboDOS entfernen.
			pla				;War TurboDOS zuvor deaktiviert ?
			beq	:14a			; => Ja, weiter...

			pha
			jsr	EnterTurbo		;TurboDOS aktivieren.
			pla
			asl				;War TurboDOS zuvor aktiv ?
			bmi	:14a			; => Ja, weiter...

			jsr	ExitTurbo		;TurboDOS abschalten.

;--- ZeroPage wieder herstellen.
::14a			ldy	#$00
::14			lda	zpageBuf +$0000,y	;":zpageBuf" = $4000 nach ":zpage".
			sta	zpage    +$0000,y	;Notwendig, da die Daten über
			lda	zpageBuf +$0100,y	;":StashRAM" kopiert werden und die
			sta	zpage    +$0100,y	;Routine die ZeroPage verändert.
			lda	zpageBuf +$0200,y
			sta	zpage    +$0200,y
			lda	zpageBuf +$0300,y
			sta	zpage    +$0300,y
			iny
			bne	:14

			ldx	#$1f			;Register ":r0" bis ":r15" retten.
::15			lda	r0L,x
			pha
			dex
			bpl	:15

			lda	#jobFetch		;Bereich lesen : $0600-$0FFF => REU.
			jsr	SetRAM_Area1

			ldx	#$00			;Register ":r0" bis ":r15"
::16			pla				;wieder zurückschreiben.
			sta	r0L,x
			inx
			cpx	#$20
			bcc	:16

			lda	SvFlgSpooler		;Spoolermenü-Flag setzen.
			sta	Flag_Spooler

			ldx	StackPointer		;Stackpointer zurücksetzen.
			txs

			lda	RetAdr +1		;Rücksprungadresse einlesen.
			pha
			lda	RetAdr +0
			pha

			rts				;Routine beenden.

;*** Warten bis keine Taste gedrückt.
;Hinweis: Darf AKKU nicht verändern!
:waitNoMseKey		php
			sei
			ldx	CPU_DATA
			ldy	#IO_IN
			sty	CPU_DATA
::wait			ldy	cia1base +1
			cpy	#%11111111
			bne	:wait
			stx	CPU_DATA
			plp
			rts

;*** Speicherbereiche speichern/zurückschreiben.
;--- Bereich: $0600-$0FFF.
:SetRAM_Area1		ldy	#0
			b $2c

;--- Bereich: $1000-$3BFF.
:SetRAM_GEOHELP		ldy	#6
			b $2c

;--- Bereich: $3C00-$CFFF.
:SetRAM_Area2		ldy	#12
			b $2c

;--- Bereich: $0000-$03FF.
:SetRAM_ZPage		ldy	#18

			pha

			ldx	#0
::1			lda	:ramtab,y
			sta	r0L,x
			inx
			iny
			cpx	#6
			bne	:1

			lda	HelpSystemBank
			sta	r3L

			pla
			tay

			jmp	DoRAMOp

::ramtab
::x0600_0FFF		w LOAD_GEOHELP +R2S_GEOHELP
			w LOAD_GEOHELP +R2S_GEOHELP
			w (LOAD_HELPSYS - LOAD_GEOHELP) -R2S_GEOHELP

::x1000_3BFF		w LOAD_HELPSYS
			w RHA_HELPSYS
			w RHS_HELPSYS

::x3C00_CFFF		w LOAD_HELPSYS +RHS_HELPSYS
			w LOAD_HELPSYS +RHS_HELPSYS
			w (vicbase - LOAD_HELPSYS) -RHS_HELPSYS

::x4000_43FF		w zpageBuf
			w zpage
			w (APP_RAM - zpage)

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_GEOHELP + R2S_GEOHELP -1
;******************************************************************************
