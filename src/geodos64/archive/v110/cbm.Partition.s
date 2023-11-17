; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L403: Partition wählen.
:Partition		stx	PartMode

;*** Partition wählen.
:SlctPart		lda	Action_Drv
			jsr	NewDrive
:InitPartDrv		jsr	InitFileTab		;Laufwerks-Tabelle erzeugen.
			lda	curDrive
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01
			beq	:6
			jmp	L403ExitGD

::6			jsr	OpenDisk		;Diskette öffnen.
			txa
			beq	:7
			jmp	DiskError

::7			lda	curDrive		;Laufwerk in Titel-Zeile.
			add	$39
			sta	V403a0+27
			sta	V403a7

			jsr	DoInfoBox		;Infobox aufbauen.
			PrintStrgV403d0

			jsr	ReadPart		;Partitionen einlesen.
			cpx	#$00
			beq	:8
			jmp	DiskError		;Disketten-Fehler.

::8			jsr	ClrBox

:NewPartSlct		InitSPort			;Aktive Partition einlesen &
			LoadB	V403b0+5,$ff
			CxSend	V403b0			;anzeigen.
			CxReceiveV403b1
			jsr	DoneWithIO

			Display	ST_WR_FORE
			Pattern	0
			FillRec	167,184, 8,311
			lda	#%11111111
			jsr	FrameRectangle
			FrameRec169,182,10,309,%11111111
			FrameRec170,181,11,308,%11111111

			jsr	UseGDFont
			PrintXY	16,178,V403a6

			lda	#$00
::9			pha
			tay
			lda	V403b1+5,y
			cmp	#$20
			bcc	:10
			cmp	#$7f
			bcc	:11
::10			lda	#" "
::11			jsr	SmallPutChar
			pla
			add	1
			cmp	#16
			bne	:9

			LoadW	r14,V403a0		;Auswahlbox.
			LoadW	r15,Memory2
			lda	#$00
			ldx	#$10
			ldy	V403a4
			jsr	DoScrTab

			Display	ST_WR_FORE
			Pattern	2
			FillRec	167,184, 8,311

;*** Auswahl auswerten.
:CheckSelect		lda	r13L			;Rückgabe-Werte einlesen.
			ldx	r13H

			cmp	#$01			;"OK" ausgewählt ?
			beq	:1			;Ja, verlassen...

			CmpBI	sysDBData,1		;"OK" oder "Abbruch" ausgewählt ?
			bne	:1			;Ja, verlassen...

			cpx	V403a4			;Anderes Laufwerk ?
			bcs	:2			;Nein, weiter...
			txa
			asl
			asl
			asl
			asl
			add	9
			tay
			lda	(r14L),y
			sub	$39
			jsr	NewDrive		;Neues Laufwerk aktivieren.
			jmp	InitPartDrv		;Partitionen einlesen.

::1			jmp	L403ExitGD

::2			txa
			suba	V403a4
			sta	V403a2			;Partition wechseln.

;*** Partition wechseln.
:ChangePart		lda	curDrvMode		;RAMLink/-Drive ?
			and	#%01000000
			beq	:2

::1			ldy	V403a2			;Partition auf CMD RL/RD.
			lda	Memory1,y
			beq	:3
			sta	V403b0 + 5

			InitSPort			;GEOS-Turbo aus und I/O einschalten.
			CxSend	V403b0
			CxReceiveV403b1
			jsr	DoneWithIO

			ldx	curDrive
			lda	V403b1+22
			sta	ramBase-8,x
			lda	V403b1+23
			sta	driveData+3

::2			ldy	V403a2			;Partition auf CMD RL/RD/FD/HD.
			lda	Memory1,y
			beq	:3
			sta	V403c0+4

			C_Send	V403c0
			jsr	OpenDisk

::3			lda	PartMode
			bne	L403ExitGD

			lda	V403a4
			cmp	#$01
			beq	ExitToMenu

			jmp	NewPartSlct

;*** Partitions-Auswahl verlassen.
:L403ExitGD		ldx	PartMode
			beq	ExitToMenu
			cpx	#$01
			beq	ExitToDir
			cpx	#$04
			bcc	ExitToOpt
:ExitToMenu		jmp	SetMenu
:ExitToDir		jmp	m_CBM_Dir1
:ExitToOpt		jmp	m_SetOpt1

;*** Laufwerks-Typen in Tabelle.
:InitFileTab		jsr	i_FillRam		;Speicher löschen.
			w	17*256,Memory1
			b	$00

			LoadW	a9,Memory2		;Zeiger auf Anfang Zwischenspeicher.
			ClrB	V403a4			;Anzahl CMD-Drives löschen.

			ldx	#$00
::1			lda	DriveModes,x		;Laufwerks-Typ holen.
			bpl	:3			;CMD-Gerät ? Nein, weiter...

			inc	V403a4			;Ja, Zähler korrigieren.

			txa				;Laufwerks-Namen als Eintrag in
			pha				;Tabelle kopieren.
			asl
			asl
			asl
			asl
			tax
			ldy	#$00
::2			lda	V403a5,x
			sta	(a9L),y
			inx
			iny
			cpy	#$10
			bne	:2

			AddVBW	16,a9

			pla
			tax
::3			inx				;Vier Laufwerke überprüfen.
			cpx	#$04
			bne	:1

			lda	V403a4
			bne	:4
			pla				;Fehler: Kein CMD-Drive !
			pla
			jmp	NoCMDDrv

;*** Tabelle initialisieren...
::4			ldx	PartMode
			bne	:4a
			cmp	#$02			;Nur ein CMD-Drive, Laufwerksauswahl
			bcs	:5			;aus Tabelle entfernen.

::4a			LoadW	a9,Memory2
			ClrB	V403a4

::5			lda	curDrvMode		;Aktuelles Laufwerk CMD-Device ?
			bmi	:6
			lda	Memory2+14		;Nein, Erstes CMD-Drive aktivieren.
			sub	$39
			jsr	NewDrive

::6			rts

;*** Fehler: Laufwerk nicht partitioniert.
:NoPartDrv		lda	curDrive
			add	$39
			sta	V403d2 + 11

			LoadW	r0,V403d1
			RecDlgBoxCSet_Grau
			jmp	L403ExitGD

;*** Fehler: Kein CMD-Laufwerk.
:NoCMDDrv		LoadW	r0,V403d4
			RecDlgBoxCSet_Grau
			jmp	L403ExitGD

;*** Partitionen von Disk einlesen.
:ReadPart		ClrB	V403a3

			InitSPort

			ClrB	STATUS
			ldx	curDrive		;Partitionsverzeichnis einlesen.
			lda	DriveAdress-8,x
			jsr	$ffb1
			bit	STATUS
			bpl	:2
::1			ldx	#$ff
			jmp	DoneWithIO

::2			lda	#$f0			;"$=P:*=x"
			jsr	$ff93
			bit	STATUS
			bmi	:1

			ldy	curDrive		;Partitions-Modus zum aktiven
			lda	driveType-8,y		;Laufwerk ermitteln.
			and	#%00000111
			tay
			lda	V403a8,y
			beq	:2a
			sta	V403a1 +6

::2a			ldy	#$00
::3			lda	V403a1,y
			jsr	$ffa8
			iny
			cpy	#$07
			bne	:3
			jsr	$ffae

			ClrB	STATUS
			ldx	curDrive
			lda	DriveAdress-8,x
			jsr	$ffb4
			lda	#$f0
			jsr	$ff96
			jsr	$ffa5
			bit	STATUS
			bvc	:4
			ldx	#$7f
			jmp	DoneWithIO

::4			ldy	#$1f			;Verzeichnis-Header
::5			jsr	$ffa5			;überlesen.
			dey
			bne	:5

;*** Partitionen aus Verzeichnis einlesen.
:RdCMDPart		jsr	$ffa5			;Auf Verzeichnis-Ende
			cmp	#$00			;testen.
			beq	EndRead
			jsr	$ffa5

			jsr	$ffa5			;Partitionsnummer
			ldx	V403a3			;in Tabelle.
			sta	Memory1,x
			inc	V403a3

::1			jsr	$ffa5			;Weiterlesen bis zum
			cmp	#$22			;Part.-Namen.
			bne	:1

			ldy	#$00
::2			jsr	$ffa5
			cmp	#$22
			beq	:3
			sta	(a9L),y
			iny
			bne	:2
::3			cpy	#$10
			beq	:4
			lda	#$20
			sta	(a9L),y
			iny
			bne	:3
::4			AddVBW	16,a9
			ldy	#$00
			tya
			sta	(a9L),y
::5			jsr	$ffa5
			cmp	#$00
			bne	:5
			jmp	RdCMDPart

;*** Alle Namen eingelesen.
:EndRead		jsr	$ffab
			ClrB	STATUS
			ldx	curDrive
			lda	DriveAdress-8,x
			jsr	$ffb1
			lda	#$e0
			jsr	$ff93
			jsr	$ffae
			jsr	DoneWithIO

			ClrB	V403a2
			CmpBI	V403a4,2		;Mehr als ein Laufwerk ?
			bcs	:1
			CmpBI	V403a3,2		;Nein. Mehr als eine Partition ?
			bcs	:1
			pla				;Nein, Fehler-Meldung.
			pla
			jmp	NoPartDrv

::1			ldx	#$00
			rts

;*** Variablen
:PartMode		b $00				;$00 = Vom Hauptmenü gestartet.
							;$01 = Vom Directory-Menü aufgerufen.
							;$02 = Vom Parameter-Menü "Drucker" gestartet.
							;$03 = Vom Parameter-Menü "Schriftart" aufgerufen.

:V403a0			b PLAINTEXT,REV_ON
			b "Partition wählen         x:"
			b NULL
:V403a1			b "$=P:*=8"
:V403a2			b $00				;Partitions-Nummer.
:V403a3			b $00				;Anzahl Partitionen.
:V403a4			b $00				;Anzahl Laufwerke in Tabelle.
:V403a5			b "Laufwerk A:     "
			b "Laufwerk B:     "
			b "Laufwerk C:     "
			b "Laufwerk D:     "
:V403a6			b PLAINTEXT
			b "Aktive Partition ist "
:V403a7			b "x:",NULL
:V403a8			b $00,"478N",$00,$00,$00

:V403b0			w $0005
			b "G-P",$00,$0d
:V403b1			w $001f
			s $1f

:V403c0			w $0004
			b 67,208,$00,$0d

:V403d0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Partitionsdaten werden"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "eingelesen..."
			b NULL

;*** Fehler: "Laufwerk nicht partitioniert..."
:V403d1			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V403d2
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V403d3
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V403d2			b PLAINTEXT,BOLDON
			b "Laufwerk x: ist nicht",NULL
:V403d3			b "partitioniert !",NULL

;*** Fehler: "Kein CMD-Laufwerk gefunden..."
:V403d4			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V403d5
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V403d6
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V403d5			b PLAINTEXT,BOLDON
			b "Kein CMD-Laufwerk mit",NULL
:V403d6			b "Partitionen gefunden !",NULL

:Memory_a

;*** Speicher für Partitions-Nummern.
:Memory1		= (Memory_a / 256 +1) * 256

;*** Speicher für Partitions-Namen.
:Memory2		= (Memory_a / 256 +2) * 256
