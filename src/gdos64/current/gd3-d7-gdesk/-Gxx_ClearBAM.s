; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Verwendung in:
;* mod.111 = Validate.
;* mod.113 = Disk löschen.

;*** BAM löschen.
:ClearBAM		lda	curType			;Laufwerksmodus einlesen.
			and	#ST_DMODES		;Modus-Bits isolieren.
			cmp	#Drv1581		;Typ=1581?
			beq	Is1581			; => Ja, weiter...
			cmp	#DrvNative		;Typ=Native?
			beq	:101			; => Ja, weiter...
			jmp	Is1541_71		; => 1541 oder 1571.
::101			jmp	IsNative		; => NativeMode.

;*** BAM für 1581 erzeugen.
:Is1581			ldy	#16
::101			lda	#40
			sta	dir2Head,y
			sta	dir3Head,y
			iny
			ldx	#4
			lda	#$ff
::102			sta	dir2Head,y
			sta	dir3Head,y
			iny
			dex
			bpl	:102
			tya
			bne	:101

;--- Link-Bytes für BAM-Sektor #1/#2 setzen.
			LoadB	dir2Head+  0,$28
			LoadB	dir2Head+  1,$02
			LoadB	dir3Head+  0,$00
			LoadB	dir3Head+  1,$ff

;--- Anzahl freier Sektoren auf Track #40 (Sek.40/0+1+2 sind durch BAM belegt)
			LoadB	dir2Head+250,37

;--- BAM-Sektoren in der Sektor-Tabelle als belegt markieren.
			LoadB	dir2Head+251,%11111000

;--- Verzeichnis in BAM belegen.
			jsr	AllocDir		;Verzeichnis in BAM belegen.
			txa				;Fehler?
			bne	:disk_error		; => Ja, Abbruch...

;--- Ergänzung: 26.04.19/M.Kanet
;Nach dem reservieren der Verzeichnis-
;Sektoren die BAM auf Disk speichern.
			jmp	PutDirHead		;BAM aktualisieren.
::disk_error		rts

;*** Native-BAM erzeugen.
:IsNative		jsr	InitSek1BAM		;BAM-Sektor #1 erzeugen/speichern.
			txa				;Fehler?
			bne	:disk_error		; => Ja, Abbruch...

			jsr	InitForIO		;I/O-Bereich einblenden.

			LoadB	r6L,$01			;Bam-Sektoren #1/0 - #1/33 belegen.
			LoadB	r6H,$00
::102			jsr	AllocAllDrv
			txa
			bne	:102a
			inc	r6H
			CmpBI	r6H,34
			bcc	:102

::102a			jsr	DoneWithIO		;I/O-Bereich ausblenden.
			txa				;BAM-Fehler?
			bne	:disk_error		; => Ja, Abbruch...

			jsr	PutDirHead		;BAM auf Disk speichern.
			txa
			bne	:disk_error

			jsr	EnterTurbo		;TurboDOS aktivieren.
			txa
			bne	:disk_error

			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	InitSek2BAM		;Sektor #3 bis #33 initialisieren.

			LoadB	r1L,$01
			LoadB	r1H,$03
			LoadW	r4,diskBlkBuf
::106			jsr	WriteBlock
			txa
			beq	:107
			jmp	DoneWithIO		;I/O-Bereich ausblenden.

::107			inc	r1H
			CmpBI	r1H,34
			bcc	:106

			jsr	DoneWithIO		;I/O-Bereich ausblenden.

			jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler?
			bne	:disk_error		; => Ja, Abbruch...

;--- Verzeichnis in BAM belegen.
			jsr	AllocDir		;Verzeichnis in BAM belegen.
			txa				;Fehler?
			bne	:disk_error		; => Ja, Abbruch...

			jmp	PutDirHead		;BAM aktualisieren.
::disk_error		rts

;*** BAM für 1541/1571 erzeugen.
:Is1541_71		pha				;Laufwerktyp speichern.

			LoadB	r1L,1

			ldy	#4
::101			sty	r0L
			jsr	GetSectors

			ldy	r0L
			lda	r1H
			sta	curDirHead+0,y

			lda	#$ff
			sta	curDirHead+1,y
			sta	curDirHead+2,y

			lda	r1H
			sec
			sbc	#16
			tax
			lda	BAM_BitTab-1,x
			sta	curDirHead+3,y
			iny
			iny
			iny
			iny
			inc	r1L
			cpy	#144
			bcc	:101

			dec	curDirHead+72
			LoadB	curDirHead+73,%1111 1110

			pla
			cmp	#Drv1571		;Laufwerkstyp = 1571?
			bne	:103			; => Nein, weiter...

			lda	curDirHead+3		;Doppelseitig?
			beq	:103			; => Nein, weiter...

			jsr	i_FillRam
			w	256,dir2Head
			b	0

			jsr	i_FillRam
			w	105,dir2Head
			b	$ff

			LoadB	r1L,36
			LoadB	r0H,2

			ldy	#221
::102			sty	r0L
			jsr	GetSectors

			ldy	r0L
			lda	r1H
			sta	curDirHead,y

			lda	r1H
			sec
			sbc	#16
			tax
			lda	BAM_BitTab-1,x
			ldx	r0H
			sta	dir2Head,x

			AddVB	3,r0H
			inc	r1L
			iny
			bne	:102

			LoadB	curDirHead+238,0
			sta	dir2Head+51
			sta	dir2Head+52
			sta	dir2Head+53

;--- Verzeichnis in BAM belegen.
::103			jsr	AllocDir		;Verzeichnis in BAM belegen.
			txa				;Fehler?
			bne	:disk_error		; => Ja, Abbruch...

			jmp	PutDirHead		;BAM aktualisieren.
::disk_error		rts

;*** BAM-Sektor #1 löschen.
:InitSek1BAM		ldy	#$20
			lda	#$ff
::101			sta	dir2Head,y
			iny
			bne	:101

;--- Ergänzung: 01.11.18/M.Kanet
;Bei Wheels wird beim belegen von Sektoren in der BAM ggf. die BAM nachgeladen
;falls diese sich noch nicht im Speicher befindet. Daher neue BAM direkt auf
;Disk speichern.
			LoadB	r1L,1			;Zeiger auf BAM-Sektor #1.
			LoadB	r1H,2			;(Track #1/Sektor #2)
			LoadW	r4,dir2Head		;Zeiger auf BAM-Speicher.
			jsr	PutBlock		;BAM-Sektor schreiben.
			txa				;Fehler?
			bne	:102			; => Ja, Abbruch...

			jsr	GetDirHead		;BAM einlesen.
::102			rts

;*** BAM-Sektor #2 löschen.
:InitSek2BAM		ldy	#$00
			lda	#$ff
::101			sta	diskBlkBuf,y
			iny
			bne	:101
			rts

;*** Ersten Directory-Sektor ermitteln.
:Get1stDirBlk		and	#ST_DMODES		;Laufwerkstyp ermtteln.
			cmp	#Drv1581
			beq	:101
			cmp	#DrvNative
			beq	:102

			lda	#18			;1541/1571-Laufwerk:
			ldy	#01			;Sektor 18/1.
			bne	:103

::101			lda	#40			;1581-Laufwerk:
			ldy	#03			;Sektor 40/3.
			bne	:103

::102			lda	curDirHead+0		;Native-Laufwerk:
			ldy	curDirHead+1		;Sektor aus ":curDirHead" entnehmen.
::103			sta	r1L			;Zeiger auf ersten Sektor
			sty	r1H			;im Verzeichnis merken.
			rts

;*** Sektor-Anzahl für Spur-Nr. bestimmen.
:GetSectors		lda	r1L			;Track = $00 ?
			beq	:101			; => Ja, Abbruch.

			lda	curType			;Laufwerkstyp einlesen.
			and	#ST_DMODES		;Laufwerksmodus isolieren.
			cmp	#Drv1541		;1541-Laufwerk ?
			bne	:102			;Nein, weiter...

			CmpBI	r1L,36			;Track von $01 - $33 ?
			bcc	:103			; => Ja, weiter...
::101			ldx	#INV_TRACK		;Fehler "Invalid Track".
			rts				;Abbruch.

::102			cmp	#Drv1571		;1571-Laufwerk ?
			bne	:107			;Nein, weiter...

			CmpBI	r1L,71			;Track von 1 - 70 ?
			bcs	:101			;Nein, Abbruch.

::103			ldy	#7			;Zeiger auf Track-Tabelle.
::104			cmp	Tracks,y		;Track > Tabellenwert ?
			bcs	:105			; => Ja, max. Anzahl Sektoren einlesen.
			dey				;Zeiger auf nächsten Tabellenwert.
			bpl	:104			;Weiteruchen.
			bmi	:101			;Ungültige Track-Adresse.

::105			tya				;1571: auf Track $01-$33 begrenzen.
			and	#%0000 0011
			tay
			lda	Sectors,y		;Anzahl Sektoren einlesen
::106			sta	r1H			;und merken...
			ldx	#NO_ERROR		;"Kein Fehler"...
			rts

::107			ldx	#DEV_NOT_FOUND		;Routine wird nur bei 1541/1571
			rts				;aufgerufen.
							;Bei 1581/Native -> Fehler.

;*** Verzeichnis in BAM belegen.
;Rückgabe: XReg = $00 / Kein Fehler.
:AllocDir		lda	curType			;Ersten Directory-Block einlesen.
			jsr	Get1stDirBlk

			MoveW	r1,curDirHead
			jsr	EnterTurbo		;TurboDOS aktivieren.
			txa				;Diskettenfehler ?
			bne	:102			; => Ja, Abbruch.

			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	AllocChain		;Verzeichnis belegen.
			txa				;Diskettenfehler ?
			bne	:101			; => Ja, Abbruch.

			LoadW	r5,curDirHead
			jsr	ChkDkGEOS
			bit	isGEOS			;GEOS-Diskette ?
			bpl	:101			;Nein, weiter...

			lda	curDirHead+172		;Zeiger auf Borderblock richten.
			sta	r6H
			lda	curDirHead+171
			sta	r6L
			beq	:101
			jsr	AllocAllDrv		;Borderblock belegen.

::101			jsr	DoneWithIO		;I/O-Bereich ausblenden.
::102			rts

;*** Sektor-Kette in der BAM belegen.
:AllocChain		ldx	r1L			;Track = $00 ?
			beq	:104			; => Ja, Ende...

			LoadW	r4,diskBlkBuf		;Zeiger auf Zwischenspeicher.

;*** Link-Bytes des ersten Datenblocks einlesen.
::101			ldx	#> ReadLink		;Routine für 1571/1581/Native etc...
			ldy	#< ReadLink
			lda	curType			;Laufwerkstyp einlesen.
			and	#ST_DMODES		;Laufwerksmodus isolieren.
			cmp	#Drv1541
			bne	:102

			ldx	#> ReadBlock		;Routine für 1541...
			ldy	#< ReadBlock
::102			tya
			jsr	CallRoutine		;"ReadLink" / "ReadBlock" (41).
			txa				;Diskettenfehler ?
			bne	:104			; => Ja, Abbruch.

			MoveW	r1,r6			;Sektor in BAM belegen.
			jsr	AllocAllDrv
			txa				;Diskettenfehler ?
			bne	:104			; => Ja, Abbruch.

			inc	r2L			;Zähler für Sektoren +1.
			bne	:103
			inc	r2H

::103			lda	diskBlkBuf+1		;Zeiger auf nächsten Sektor.
			sta	r1H
			lda	diskBlkBuf+0
			sta	r1L
			bne	:101			;Ende erreicht ? Nein, weiter...
::104			rts

;*** Sektor auf allen Laufwerken belegen.
:AllocAllDrv		jsr	DoneWithIO		;I/O-Bereich ausblenden.

			lda	curType			;Laufwerkstyp einlesen.
			and	#ST_DMODES 		;Laufwerksmodus isolieren.
			cmp	#Drv1541		;Lafwerk vom Typ 1541 ?
			beq	:101			; => Ja, weiter...
			jsr	AllocateBlock		;Sektor in BAM belegen.
			jmp	:103

;*** Sonderbehandlung 1541.
::101			jsr	FindBAMBit		;Prüfen, ob Sektor bereits belegt.
			beq	:102			; => Ja, Fehler "BAD BAM", Abbruch.

			lda	r8H			;Sektor in BAM belegen.
			eor	#$ff
			and	curDirHead,x
			sta	curDirHead,x
			ldx	r7H			;Anzahl freie Sektoren auf Track -1.
			dec	curDirHead,x

			ldx	#NO_ERROR		;Kein Fehler.
			b $2c
::102			ldx	#BAD_BAM		;Fehler "BAD_BAM".
::103			txa
			pha
			jsr	InitForIO		;I/O-Bereich einblenden.
			pla
			tax
			rts

;*** Tabelle mit Tracks, bei denen ein Wechsel der
;    Sektoranzahl/Track stattfindet.
:Tracks			b $01,$12,$19,$1f,$24,$35,$3c,$42
:Sectors		b $15,$13,$12,$11

;*** Tabelle zum belegen von Sektoren in der BAM.
:BAM_BitTab		b %00000001
			b %00000011
			b %00000111
			b %00001111
			b %00011111
