; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#110.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	SwapDrives

;*** Laufwerke tauschen.
:SwapDrives		lda	Source_Drv		;Laufwerke prüfen.
			ldx	Target_Drv		;Wenn Drv1 > Drv2 dann umtauschen.
			cmp	Target_Drv
			bcc	:101
			tax
			lda	Target_Drv
			sta	Source_Drv
			stx	Target_Drv
::101			cpx	#11			;Laufwerk D: tauschen ?
			bne	:107			;Nein, weiter...

			tay
			lda	DriveTypes-8,y
			cmp	#Drv_64Net		;Quell-Laufwerk = 64Net ?
			bne	:102			;Nein, weiter...

			lda	driveType -8,y
			and	#%00000111
			cmp	#%00000010		;1571-Partition auf 64Net ?
			beq	:103			;Ja, nicht möglich!
			bne	:106			;Nein, tauschen...

::102			lda	DriveModes-8,y
			and	#%00000010		;Ist Drv1 Laufwerk D: kompatibel ?
			beq	:106			;Ja, weiter...

::103			tya				;Laufwerk merken.
			add	$39
			sta	V110f1+16

			ldy	#$03			;RAMLink / RAMDrive vorhanden ?
::104			lda	DriveTypes,y
			cmp	#Drv_CMDRL
			beq	:105
;--- Ergänzung: 22.11.18/M.Kanet
;RAMDrive ist der RAMLink ähnlich, daher Kennung angepasst.
			cmp	#Drv_CMDRD
			beq	:105
			dey
			bpl	:104

			lda	Source_Drv		;Nein, weiter...
			bne	:107

::105			DB_CANCELV110f0			;Fehler: Drv1 kann nicht auf D:
			jmp	InitScreen		;getauscht werden.

::106			tya

::107			sta	a9L			;Laufwerksadressen merken.
			stx	a9H

;*** Ist Laufwerk #1 = 64Net ?
			tay
			lda	DriveTypes-8,y
			cmp	#Drv_64Net
			bne	:108
			tya
			jsr	SetDevice
			lda	a9H
			jmp	:109

;*** Ist Laufwerk #2 = 64Net ?
::108			lda	DriveTypes-8,x
			cmp	#Drv_64Net
			bne	:110
			txa
			jsr	SetDevice
			lda	a9L
::109			jsr	ChangeDiskDevice

::110			lda	a9L			;Laufwerksadressen merken.
			add	$39
			sta	V110e1+ 9
			lda	a9H
			add	$39
			sta	V110e1+16
			jsr	DoInfoBox
			PrintStrgV110e0
			jsr	ChangeDrive		;Laufwerke vertauschen.
			jmp	InitScreen		;Neuer Bildaufbau.

;*** Geräteadressen tauschen.
:ChangeDrive		lda	#8
::100			pha
			jsr	SetDevice		;Turbo-Routinen aus allen Laufwerken
			jsr	PurgeTurbo		;löschen (auch wenn nicht aktiv, um
			pla				;Probleme mit 2xRL zu umgehen...)
			add	1
			cmp	#12
			bne	:100

			ldx	Source_Drv		;Quell- und Ziellaufwerk gleich ?
			ldy	Target_Drv		;(Gilt hier nur für RAMLink mit 2x
			lda	DriveAdress-8,x		; 1581-Partition. Andere Fälle werden
			sta	V110a2			; bereits bei der Laufwerksauswahl
			lda	DriveAdress-8,y		; abgefangen, z.B. A:1541 mit A:1541
			sta	V110a3			; tauschen oder ähnliches...)
			cmp	DriveAdress-8,x
			bne	:101
			jmp	ChangeDrvData

::101			ldx	Source_Drv
			lda	DriveAdress-8,x
			cmp	Source_Drv
			beq	:102

			ldx	Source_Drv
			jsr	IsDrvOnline
			bne	:102

			jsr	GetFreeAdr
			txa
			bne	:104
			ldx	Source_Drv
			ldy	V110a1
			jsr	SwapDskAdr

::102			ldx	Target_Drv
			lda	DriveAdress-8,x
			cmp	Target_Drv
			beq	:103

			ldx	Target_Drv
			jsr	IsDrvOnline
			bne	:103

			jsr	GetFreeAdr
			txa
			bne	:104
			ldx	Target_Drv
			ldy	V110a1
			jsr	SwapDskAdr

::103			jsr	GetFreeAdr		;Nach freier Geräteadresse für
			txa				;Laufwerkstausch suchen.
			beq	ChangeDrv1		;$00 = OK
::104			rts				;Kein Tausch möglich, kommt nicht vor,
							;nur zur Sicherheit...

;*** Quell-Laufwerk auf Zwischenadresse verschieben.
:ChangeDrv1		ldx	Source_Drv		;Echtes Laufwerk mit Quell-Adresse
			lda	DriveAdress-8,x		;vorhanden ?
			beq	:101			;Nein, weiter...
			tax				;Ja, Laufwerk auf Zwischen-Adresse
			ldy	V110a1			;verschieben.
			jsr	SwapDskAdr

			ldx	Source_Drv		;Interne Tabelle mit Geräteadressen
			lda	DriveAdress-8,x		;umrechnen.
			ldx	V110a1
			jsr	ChangeTabAdr
			jmp	ChangeDrv2

::101			jsr	IsDrvOnline		;Ist Laufwerk vorhanden ?
			bne	ChangeDrv2

			ldx	Source_Drv		;Drv #1 auf Zwischenadresse umstellen.
			ldy	V110a1
			jsr	SwapDskAdr

			lda	Source_Drv		;Interne Tabelle mit Geräteadressen
			ldx	V110a1
			jsr	ChangeTabAdr

;*** Ziel-Laufwerk auf Quell-Laufwerk verschieben.
:ChangeDrv2		ldx	Target_Drv		;Echtes Laufwerk mit Quell-Adresse
			lda	DriveAdress-8,x		;vorhanden ?
			beq	:101			;Nein, weiter...
			tax				;Ja, Laufwerk auf Zwischen-Adresse
			ldy	Source_Drv		;verschieben.
			jsr	SwapDskAdr

			ldx	Target_Drv		;Interne Tabelle mit Geräteadressen
			lda	DriveAdress-8,x		;umrechnen.
			ldx	Source_Drv
			jsr	ChangeTabAdr
			jmp	ChangeDrv3

::101			jsr	IsDrvOnline		;Ist Laufwerk vorhanden ?
			bne	ChangeDrv3

			ldx	Target_Drv		;Drv #1 auf Zwischenadresse umstellen.
			ldy	Source_Drv
			jsr	SwapDskAdr

			lda	Target_Drv		;Interne Tabelle mit Geräteadressen
			ldx	Source_Drv
			jsr	ChangeTabAdr

;*** Zwischenspeicher auf Ziel-Laufwerk verschieben.
:ChangeDrv3		ldx	Source_Drv		;Echtes Laufwerk mit Quell-Adresse
			lda	DriveAdress-8,x		;vorhanden ?
			beq	:101			;Nein, weiter...
			tax				;Ja, Laufwerk auf Zwischen-Adresse
			ldy	Target_Drv		;verschieben.
			jsr	SwapDskAdr

			ldx	Source_Drv		;Interne Tabelle mit Geräteadressen
			lda	DriveAdress-8,x		;umrechnen.
			ldx	Target_Drv
			jsr	ChangeTabAdr
			jmp	ChangeDrvData

::101			ldx	V110a1
			jsr	IsDrvOnline
			bne	ChangeDrvData

			ldx	V110a1			;Drv #1 auf Zwischenadresse umstellen.
			ldy	Target_Drv
			jsr	SwapDskAdr

			lda	V110a1			;Interne Tabelle mit Geräteadressen
			ldx	Target_Drv
			jsr	ChangeTabAdr

;*** Laufwerksvariablen tauschen.
:ChangeDrvData		ldx	Source_Drv
			ldy	Target_Drv

::106			lda	ramBase    -8,x		;HIGH-Byte Bank in REU tauschen.
			pha				;LOW-Byte in "driveData +3" darf
			lda	ramBase    -8,y		;nicht verändert werden!
			sta	ramBase    -8,x
			pla
			sta	ramBase    -8,y

			lda	driveType  -8,x		;GEOS Laufwerkstypen tauschen.
			pha
			lda	driveType  -8,y
			sta	driveType  -8,x
			pla
			sta	driveType  -8,y

			lda	turboFlags -8,x		;TurboFlags tauschen.
			pha				;(Sicher ist sicher...)
			lda	turboFlags -8,y
			sta	turboFlags -8,x
			pla
			sta	turboFlags -8,y

			lda	DriveTypes -8,x		;GeoDOS Laufwerkstypen tauschen.
			pha				;(z.B. FD4,RL,RAM41,HD,1571,64Net..)
			lda	DriveTypes -8,y
			sta	DriveTypes -8,x
			pla
			sta	DriveTypes -8,y

			lda	DriveModes -8,x		;GeoDOS Laufwerksmodi tauschen.
			pha				;(z.B. DOS-Kompatibel,CMD-Drive,...)
			lda	DriveModes -8,y
			sta	DriveModes -8,x
			pla
			sta	DriveModes -8,y

			lda	DriveAdress-8,x		;GeoDOS CMD-Partitionen tauschen.
			pha				;(Notwendig wenn 2x RL aktiv ist um
			lda	DriveAdress-8,y		; zu wissen welche Part. auf welchem
			sta	DriveAdress-8,x		; Laufwerk eingestellt ist...)
			pla
			sta	DriveAdress-8,y

			lda	DrivePart  -8,x		;GeoDOS CMD-Partitionen tauschen.
			pha				;(Notwendig wenn 2x RL aktiv ist um
			lda	DrivePart  -8,y		; zu wissen welche Part. auf welchem
			sta	DrivePart  -8,x		; Laufwerk eingestellt ist...)
			pla
			sta	DrivePart  -8,y

			cpx	AppDrv			;Falls Startlaufwerk getauscht wurde,
			bne	:107			;neue Geräteadresse für Startlaufwerk
			sty	AppDrv			;festlegen.
			jmp	:108

::107			cpy	AppDrv
			bne	:108
			stx	AppDrv

::108			lda	ramExpSize		;REU vorhanden ?
			beq	:115			;Nein, Treiber nicht tauschen,
							;da keine REU vorhanden.
			ldx	Source_Drv		;C64-RAM mit Treiber #1 tauschen.
			jsr	SwapDriver
			ldx	Target_Drv		;Treiber #1 mit Treiber #2 tauschen.
			jsr	SwapDriver
			ldx	Source_Drv		;Treiber #2 mit C64-RAM (z.Zt. in der
			jsr	SwapDriver		;REU!) tauschen.

::115			lda	Source_Drv		;Zeiger auf Infozeile
			jsr	DefPosInfo		;berechnen.
			sta	r0L
			stx	r0H

			lda	Target_Drv
			jsr	DefPosInfo
			sta	r1L
			stx	r1H

			ldy	#$07			;Text in Infozeile tauschen.
::116			lda	(r0L),y
			pha
			lda	(r1L),y
			sta	(r0L),y
			pla
			sta	(r1L),y
			dey
			bpl	:116

			lda	Source_Drv		;Laufwerk #1 aktivieren.
			jsr	SetDevice		;(Variablen neu setzen).
			jsr	NewOpenDisk

			lda	Target_Drv		;Laufwerk #2 aktivieren.
			jsr	SetDevice
			jmp	NewOpenDisk

;*** Laufwerk vorhanden ?
;    Laufwerksadresse im xReg!
:IsDrvOnline		stx	:101 +1

			jsr	InitForIO

			jsr	UNTALK
			ClrB	STATUS			;Status-Byte löschen.
::101			lda	#$ff
			jsr	LISTEN			;Laufwerk aktivieren.
			PushB	STATUS			;Status-Byte merken.
			jsr	UNLSN			;Laufwerk abschalten.
			jsr	DoneWithIO
			pla
			rts

;*** Laufwerksadressen in Tabelle ändern.
:ChangeTabAdr		ldy	#$03
::101			cmp	DriveAdress,y
			bne	:102
			pha
			txa
			sta	DriveAdress,y
			pla
::102			dey
			bpl	:101
			rts

;*** Geräteadresse swappen.
:SwapDskAdr		tya
			add	32
			sta	V110b1			;Ziel-Adresse #1 berechnen.
			tya
			add	64
			sta	V110b2			;Ziel-Adresse #2 berechnen.
			stx	V110a0			;Laufwerksadresse merken.

			jsr	PurgeTurbo		;GEOS-Turbo aus.
			jsr	InitForIO		;I/O aktivieren.
			ClrB	STATUS			;Gerät aktivieren.
			jsr	UNLSN
			lda	V110a0
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND

			ldy	#$00			;Neue Laufwerksadresse senden ?
::101			lda	V110b0,y
			jsr	CIOUT
			iny
			cpy	#$08
			bne	:101

			jsr	UNLSN			;OK!
			jmp	DoneWithIO

;*** C64-RAM mit Speicher in REU tauschen.
:SwapDriver		LoadW	r0,$9000		;Startadresse C64-Speicher.
			lda	V110c0-8,x		;Adresse Treiber in REU.
			sta	r1L
			lda	V110c1-8,x
			sta	r1H
			LoadW	r2,$0d80		;Länge der Treiber in Bytes.
			LoadB	r3L,$00			;Bank in REU.
			jmp	SwapRAM			;Speicher tauschen.

;*** Position in Infozeile berechnen.
:DefPosInfo		sub	8
			asl
			asl
			asl
			ldx	#>Drive_ASCII
			add	 <Drive_ASCII
			bcc	:101
			inx
::101			rts

;*** Freie Geräte-Adresse suchen.
:GetFreeAdr		ldx	#12			;Suche ab Adr. #12.
::101			stx	curDevice		;(Adr. 8-11 für GEOS reserviert...)
			jsr	InitForIO		;I/O aktivieren.

			ClrB	STATUS			;Laufwerk aktivieren.
			jsr	UNTALK
			lda	curDevice
			jsr	LISTEN
			lda	#$ef
			jsr	SECOND
			jsr	UNLSN

			jsr	DoneWithIO		;I/O abschalten.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:102
			ldx	curDevice		;Zeiger auf nächstes Laufwerk.
			inx
			cpx	#30			;Bis max. Gerät #29 (max. RL) testen.
			bne	:101			;Ende erreicht ? Nein, weiter...
			ldx	#$0d			;Laufwerkswechsel nicht möglich.
			rts				;(Dürfte nicht vorkommen!)

::102			lda	curDevice		;Zwischadr. für Laufwerkstausch
			sta	V110a1			;merken.

			ldx	#$00			;OK.
			rts

;*** Variablen für Laufwerkstausch.
:V110a0			b $00
:V110a1			b $00
:V110a2			b $00				;Neue Adr. Quell-Laufwerk.
:V110a3			b $00				;Neue Adr. Ziel -Laufwerk.
:V110a4			b $00				;Laufwerk #1.
:V110a5			b $00				;Laufwerk #1.

:V110b0			b "M-W",$77,$00,$02
:V110b1			b $00
:V110b2			b $00

:V110c0			b $00,$80,$00,$80
:V110c1			b $83,$90,$9e,$ab

:V110d0			b $08,$08,$08,$09,$09,$0a
:V110d1			b $09,$0a,$0b,$0a,$0b,$0b

if Sprache = Deutsch
:V110e0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Ändere Geräteadressen"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
:V110e1			b "Laufwerk x: und x:..."
			b NULL

:V110f0			w V110f1,V110f2,ISet_Achtung
:V110f1			b BOLDON,"Laufwerktausch x:",NULL
:V110f2			b        "mit D: nicht möglich!",NULL
endif

if Sprache = Englisch
:V110e0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Change address"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
:V110e1			b "of drive x: and x:..."
			b NULL

:V110f0			w V110f1,V110f2,ISet_Achtung
:V110f1			b BOLDON,"Swapping drive x:",NULL
:V110f2			b        "and D: not possible!",NULL
endif
