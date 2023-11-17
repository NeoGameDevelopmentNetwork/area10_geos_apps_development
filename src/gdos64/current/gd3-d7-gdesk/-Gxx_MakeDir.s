; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Verzeichnis erstellen.
;  -81.MakeSDir
;  -83.FileCopy
;

;*** Unterverzeichnis anlegen.
;Verzeichnis über GEOS-Routinen erstellen.
;Sektorsuche ab TR01/SE64 = CMD-Standard.
;    Übergabe: newDirName = Verzeichnis-Name.
:MakeNDir		jsr	OpenDisk		;Disk öffnen/BAM einlesen.
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

			lda	dir2Head +8		;Max. Anzahl Tracks einlesen und
			sta	maxTrack		;zwischenspeichern.

			LoadB	r6L,1			;Zeiger auf ersten Datensektor.
			LoadB	r6H,64

::loop			jsr	FindBAMBit		;Ist Sektor belegt ?
			beq	:next			; => Ja, weiter...

			MoveB	r6L,NewDirHd +0		;1.Reservierten Sektor merken.
			MoveB	r6H,NewDirHd +1

;--- Hinweis:
;Gemäß CMD-RAMLink-Handbuch S4-4,
;"NativeMode SubDirectories":
; >> This "file" is initially two blocks long, and consists of
; >> a directory header block and the first directory block.
; >> These two blocks are always located next to each
; >> other on the same track, and if two adjacent blocks
; >> cannot be found, no directory will be created.

			inc	r6H			;Zeiger auf nächsten Sektor.
			beq	:ntrack			; -> Letzten Sektor überspringen.

			jsr	FindBAMBit		;Ist Sektor belegt ?
			bne	:found			; => Nein, weiter...

;--- Hinweis:
;Kein passendes Sektor-Paar gefunden,
;Suche ab nächstem Sektor fortsetzen.
::next			inc	r6H			;wieder freigeben.
			bne	:continue
::ntrack		inc	r6L
			beq	:err_full

::continue		lda	maxTrack
			cmp	r6L
			bcs	:loop

::err_full		ldx	#INSUFF_SPACE		;Keine zwei Sektoren verfügbar.
::error			rts				; -> Fehler, Abbruch...

;--- Freies Sektoren-Paar gefunden.
::found			MoveB	r6L,NewDirSk +0		;2.Reservierten Sektor merken.
			MoveB	r6H,NewDirSk +1

			jsr	AllocateBlock		;2.Sektor reservieren.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

;			MoveB	NewDirHd +0,r6L
;			MoveB	NewDirHd +1,r6H
			dec	r6H

			jsr	AllocateBlock		;1.Sektor reservieren.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

			jsr	MakeNDirEntry		;Neuen Verzeichnis-Eintrag erzeugen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

			jsr	MakeNDirHead		;Neuen Verzeichnis-Header erzeugen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

			jsr	MakeNDirSek		;Leeren Verzeichnis-Sektor erzeugen.
			txa				;Fehler ?
			bne	:error			; => Ja, Abbruch...

			jmp	PutDirHead		;BAM aktualisieren.

;*** Neuen Verzeichnis-Eintrag erzeugen.
:MakeNDirEntry		LoadB	r10L,0			;Gesamtes Verzeichnis nach freiem
			jsr	GetFreeDirBlk		;Eintrag durchsuchen.
			txa				;Leeren Eintrag gefunden?
			bne	:error			; => Nein, Abbruch.

			MoveB	r1L,DirEntry+0		;Sektor mit leerem Verzeichnis-
			MoveB	r1H,DirEntry+1		;Eintrag merken.
			sty	    DirEntry+2		;Zeiger auf Verzeichnis-Eintrag merken.

			lda	#$86			;Typ "Unterverzeichnis".
			sta	diskBlkBuf,y
			iny
			lda	NewDirHd+0		;Zeiger auf neuen Verzeichnis-Header
			sta	diskBlkBuf,y		;übernehmen.
			iny
			lda	NewDirHd+1
			sta	diskBlkBuf,y
			iny

			jsr	CopyDirName		;Verzeichnis-Name kopieren.

			lda	#$00
			sta	diskBlkBuf,y		;Tr/Se für Info-Block löschen.
			iny
			sta	diskBlkBuf,y
			iny
			sta	diskBlkBuf,y		;GEOS-Dateistruktur: 0 = Sequentiell.
			iny
			sta	diskBlkBuf,y		;GEOS-Dateityp: 0 =  Nicht GEOS.
			iny
			lda	year			;Jahr/Monat/Tag übernehmen.
			sta	diskBlkBuf,y
			iny
			lda	month
			sta	diskBlkBuf,y
			iny
			lda	day
			sta	diskBlkBuf,y
			iny
			lda	hour			;Stunde/Minute übernehmen.
			sta	diskBlkBuf,y
			iny
			lda	minutes
			sta	diskBlkBuf,y
			iny
			lda	#$02			;Größe des neuen Unterverzeichnis:
			sta	diskBlkBuf,y		;1Block Header und 1Block Verzeichnis.
			iny
			lda	#$00
			sta	diskBlkBuf,y
			LoadW	r4,diskBlkBuf		;Verzeichnis aktualisieren.
			jsr	PutBlock
			txa				;Fehler?
			bne	:error			; => Ja, Abbruch...

;--- Hinweis:
;":GetFreeDirBlk" legt ggf. einen neuen
;Verzeichnis-Sektor an und markiert den
;Block in der aktuellen BAM im Speicher
;als "belegt". Daher BAM speichern...
;
;Wird durch ":MakeNDir" aufgerufen.
;			jsr	PutDirHead		;BAM aktualisieren.
;			txa				;Fehler?
;			bne	:error			; => Ja, Abbruch...
::error			rts

;*** Neuen Verzeichnis-Header erstellen.
;Dazu wird als Vorlage der aktuelle Header in curDirHead
;verwendet und modifiziert.
:MakeNDirHead		ldx	#$00			;curDirHead kopieren als Vorlage
::11			lda	curDirHead,x		;für neuen Verzeichnis-Header.
			sta	diskBlkBuf,x
			inx
			cpx	#39
			bcc	:11
			lda	#$00			;Reservierte Bytes löschen.
::12			sta	diskBlkBuf,x
			inx
			bne	:12

			lda	NewDirSk  +0		;Zeiger auf ersten Verzeichnis-
			sta	diskBlkBuf+$00		;Sektor übernehmen.
			lda	NewDirSk  +1
			sta	diskBlkBuf+$01

;--- Ergänzung: 06.12.18/M.Kanet
;Wenn der Header erstellt wird prüft GEOS nicht auf den
;Header-Sektor und wechselt daher auch nicht den Disknamen.
			ldy	#$04			;Verzeichnis-Name kopieren.
			jsr	CopyDirName
;			ldy	#$90
;			jsr	CopyDirName

			lda	#$a0			;Füllbytes.
			sta	diskBlkBuf+$14
			sta	diskBlkBuf+$15

			ldx	curDirHead+$a2		;Disk-ID.
			stx	diskBlkBuf+$16		;Hinweis: Durch den GEOS-Treiber
			ldx	curDirHead+$a3		;werden die Daten für den Disknamen
			stx	diskBlkBuf+$17		;ab Byte $90 abgebildet.

			sta	diskBlkBuf+$18		;Füllbyte.

			ldx	curDirHead+$a5		;DOS-Version.
			stx	diskBlkBuf+$19

			ldx	curDirHead+$a6		;Disk format type.
			stx	diskBlkBuf+$1a

			sta	diskBlkBuf+$1b		;Füllbytes.
			sta	diskBlkBuf+$1c

			lda	#$00
			sta	diskBlkBuf+$1d
			sta	diskBlkBuf+$1e
			sta	diskBlkBuf+$1f

			lda	NewDirHd  +0		;Tr/Se für Verzeichnis-Header in
			sta	diskBlkBuf+$20		;neuen Header eintragen.
			sta	r1L			;Tr/Se auch nach r1L/r1H für
			lda	NewDirHd  +1		;späteres PutBlock.
			sta	diskBlkBuf+$21
			sta	r1H

			lda	curDirHead+$20		;Tr/Se für aktuelles Verzeichnis
			sta	diskBlkBuf+$22		;als Tr/Se für Parent-Directory setzen.
			lda	curDirHead+$21
			sta	diskBlkBuf+$23

			lda	DirEntry  +0		;Tr/Se/Byte in neuen Header übernehmen
			sta	diskBlkBuf+$24		;als Zeiger auf den zugehörigen
			lda	DirEntry  +1		;Verzeichnis-Eintrag.
			sta	diskBlkBuf+$25
			lda	DirEntry  +2
			sta	diskBlkBuf+$26

			LoadW	r4,diskBlkBuf		;Neuen Verzeichnis-Header schreiben.
			jmp	PutBlock

;*** Leeren Verzeichnis-Sektor erzeugen.
:MakeNDirSek		ldx	#$00			;Sektorinhalt löschen.
			txa
::11			sta	diskBlkBuf,x
			inx
			bne	:11
			dex				;$00/$FF für "Verzeichnis-Ende"
			stx	diskBlkBuf+1		;setzen.

			lda	NewDirSk  +0		;Tr/Se für leeren Verzeichnis-Sektor
			sta	r1L			;setzen.
			lda	NewDirSk  +1
			sta	r1H
			LoadW	r4,diskBlkBuf		;Zeiger auf diskBlkBuf.
			jmp	PutBlock		;Verzeichnis-Sektor schreiben.

;*** Verzeichnis-Name nach diskBlkBuf schreiben.
;Wird zum erstellen des Verzeichnis-Eintrages und
;zum erstellen des neuen Verzeichnis-Headers benötigt.
;Übergabe: YReg = Zeiger auf diskBlkBuf.
:CopyDirName		ldx	#$00
::11			lda	newDirName,x		;Ende Dateiname erreicht?
			beq	:12			; => Ja, weiter...
			cmp	#$a0			;Ende Dateiname erreicht?
			beq	:13			; => Ja, weiter...
			sta	diskBlkBuf,y		;Zeichen nach diskBlkBuf kopieren.
			iny				;Zeiger auf nächstes Zeichen.
			inx				;Zähler erhöhen.
			cpx	#16			;Max. 16Zeichen gelesen?
			bcc	:11			; => Nein, weiter...
			bcs	:14			; => Ja, Ende...

::12			lda	#$a0			;Dateinamen mit $A0 bis 16Z. auffüllen.
::13			sta	diskBlkBuf,y
			iny
			inx				;Zähler erhöhen.
			cpx	#16			;Max. 16Zeichen erreicht?
			bcc	:13			; => Nein, weiter...

::14			rts

;
;Original-Code aus GEODOS.
;Hier nur die einfache Variante:
;Für BASIC-kompatible Verzeichnisse
;nur Großbuchstaben verwenden.
;Keine automatische Konvertierung.
;
if FALSE
;*** Verzeichnisname von GEOS nach PETSCII konvertieren.
;ConvDirName		ldx	#$00
::10			lda	newDirName,x		;Ende Dateiname erreicht?
			beq	:12			; => Ja, Ende...
			cmp	#" "			;Gültiges Zeichen?
			bcc	:11			; => Nein, mit "X" ersetzen.
			cmp	#$80
			bcs	:11			; => Nein, mit "X" ersetzen.
			tay				;Zeichen konvertieren durch einlesen
			lda	:100 -32,y		;Ersatzzeichen aus Tabelle.
			b $2c
::11			lda	#$58			;Ungültiges Zeichen.
			sta	dirName,x
			inx
			cpx	#16
			bcc	:10
			bcs	:14

::12			lda	#$00			;Dateinamen mit $A0 bis 16Z. auffüllen.
::13			sta	dirName,x
			inx				;Zähler erhöhen.
			cpx	#16			;Max. 16Zeichen erreicht?
			bcc	:13			; => Nein, weiter...
::14			rts

::100			b $20,$21,$22,$23,$58,$25,$26,$27
			b $28,$29,$58,$2b,$58,$2d,$2e,$58

			b $30,$31,$32,$33,$34,$35,$36,$37
			b $38,$39,$3a,$3b,$3c,$3d,$3e,$58

;--- Convert GEOS -> PETSCII
;Die folgenden 64Byte erzeugen Verzeichnisnamen
;analog zu den BASIC-Befehlen:
;Kleinbuchstaben/GEOS -> Kleinbuchstaben/BASIC.
;Verzeichnis-Wechsel über `cd:abcABC` möglich.
;Wird aber unter GEOS als Großbuchstaben angezeigt.
;			b $40,$c1,$c2,$c3,$c4,$c5,$c6,$c7
;			b $c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
;			b $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7
;			b $d8,$d9,$da,$c1,$cf,$d5,$5e,$2d

;			b $27,$41,$42,$43,$44,$45,$46,$47
;			b $48,$49,$4a,$4b,$4c,$4d,$4e,$4f
;			b $50,$51,$52,$53,$54,$55,$56,$57
;			b $58,$59,$5a,$41,$4f,$55,$d3,$58

;--- Convert GEOS -> GEOS
;Die folgenden 64Byte erzeugen Verzeichnisnamen
;die kompatibel zu den BASIC-Befehlen sind:
;Kleinbuchstaben/GEOS -> Großbuchstaben/BASIC.
;Verzeichnis-Wechsel über `cd:abcABC` möglich.
;Namen sind aber nicht mehr GEOS-Kompatibel da
;die Zeichen größer > $80 sind.
;			b $40,$41,$42,$43,$44,$45,$46,$47
;			b $48,$49,$4a,$4b,$4c,$4d,$4e,$4f
;			b $50,$51,$52,$53,$54,$55,$56,$57
;			b $58,$59,$5a,$41,$4f,$55,$5e,$2d

;			b $27,$c1,$c2,$c3,$c4,$c5,$c6,$c7
;			b $c8,$c9,$ca,$cb,$cc,$cd,$ce,$cf
;			b $d0,$d1,$d2,$d3,$d4,$d5,$d6,$d7
;			b $d8,$d9,$da,$c1,$cf,$d5,$d3,$58

;--- Convert GEOS -> GEOS
;Die folgenden 64Byte erzeugen Verzeichnisnamen
;die inkompatibel zu den BASIC-Befehlen sind:
;Kleinbuchstaben/GEOS -> Großbuchstaben/BASIC.
;Verzeichnis-Wechsel über `cd:abcABC` nicht möglich.
;Hier nur Großbuchstaben verwenden!
			b $40,$41,$42,$43,$44,$45,$46,$47
			b $48,$49,$4a,$4b,$4c,$4d,$4e,$4f
			b $50,$51,$52,$53,$54,$55,$56,$57
			b $58,$59,$5a,$5b,$5c,$5d,$5e,$5f

			b $60,$61,$62,$63,$64,$65,$66,$67
			b $68,$69,$6a,$6b,$6c,$6d,$6e,$6f
			b $70,$71,$72,$73,$74,$75,$76,$77
			b $78,$79,$7a,$7b,$7c,$7d,$7e,$58
endif

;*** Variablen für neue MDir-Routine.
:maxTrack		b $00
:NewDirHd		b $00,$00
:NewDirSk		b $00,$00
:DirEntry		b $00,$00,$00
