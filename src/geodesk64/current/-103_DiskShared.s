; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Verzeichnis-Liste einlesen.
;    Übergabe: YReg      = $00=Dateien.
;                          $FF=Verzeichnisse.
;              AKKU/XREG = Zeiger auf "$"-Befehl.
;              r15       = Zeiger auf Eintragstabelle.
:GetDirList		sty	ReadDirMode

			sta	r13L			;Zeiger auf
			stx	r13H			;Verzeichnis-Befehl.

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.

			bit	STATUS			;Status-Byte prüfen.
			bpl	:sendDirCmd		;OK, weiter...
::err_no_device		ldx	#DEV_NOT_FOUND		;Fehler: "Laufwerk nicht bereits".
			jmp	GetDirListEnd		;Abbruch.

::sendDirCmd		lda	#$f0			;Datenkanal aktivieren.
			jsr	SECOND
			bit	STATUS			;Status-Byte prüfen.
			bmi	:err_no_device		;Fehler, Abbruch.

			ldy	#$00
::loopCMD		lda	(r13L),y		;Byte aus Befehl einlesen und
			beq	:endCMD
			jsr	CIOUT			;an Floppy senden.
			iny
			bne	:loopCMD		;Nein, weiter...
::endCMD		jsr	UNLSN			;Befehl abschliesen.

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	TALK			;TALK-Signal auf IEC-Bus senden.
			lda	#$f0			;Datenkanal öffnen.
			jsr	TKSA			;Sekundär-Adresse nach TALK senden.

			jsr	ACPTR			;Byte einlesen.

			bit	STATUS			;Status testen.
			bpl	:skipHeader		;OK, weiter...
			ldx	#FILE_NOT_FOUND		;Fehler: "Verz. nicht gefunden".
			jmp	GetDirListEnd

::skipHeader		ldy	#$1f			;Verzeichnis-Header
::loop1			jsr	ACPTR			;überlesen.
			dey
			bne	:loop1

;*** Partitionen aus Verzeichnis einlesen.
::next_line		jsr	ACPTR			;Auf Verzeichnis-Ende
			cmp	#$00			;testen.
			beq	:EOD
			jsr	ACPTR			;(2 Byte Link-Verbindung überlesen).

			jsr	ACPTR			;Low-Byte der Zeilen-Nr. überlesen.
			sta	Blocks +0
			jsr	ACPTR			;High-Byte Zeilen-Nr. überlesen.
			sta	Blocks +1

::startFileName		jsr	ACPTR			;Weiterlesen bis zum
			cmp	#$00			;Dateinamen.
			beq	:next_line		; => Ende der Zeile erreicht.
			cmp	#$22			; " - Zeichen erreicht ?
			bne	:startFileName		;Nein, weiter...

			ldy	#$05			;Zeichenzähler löschen.
::loopFileName		jsr	ACPTR			;Byte aus Dateinamen einlesen.
			cmp	#$22			;Ende erreicht ?
			beq	:testFileExist		;Ja, Ende...
			sta	(r15L),y		;Byte in Tabelle übertragen.
			iny
			cpy	#$05 +16
			bcc	:loopFileName

::testFileExist		jsr	FindDirFile		;Prüfen ob Eintrag bereits als
			txa				;Verzeichnis eingelesen wurde.
			bne	:findEOL		; => Verzeichnis, überspringen...

			ldy	#$02
			lda	DiskImgTyp		;Laufwerkstyp einlesen.
			bit	ReadDirMode		;Verzeichnis-Modus testen.
			bpl	:wrFileType		; => Dateien einlesen.
			lda	#FTYPE_DIR		;"Verzeichnis".
::wrFileType		sta	(r15L),y		;Dateityp speichern.

			ldy	#$03			;Zeiger auf Partitions-Nr.
			lda	ReadDirMode		;Verzeichnis-Modus testen.
			cmp	#$7f			;CMD-Partitionen?
			beq	:wrPartSize		; => Ja, weitere...
			ldy	#$1e			;Zeiger auf Größe setzen.

;--- Partitions-Nr. / Größe speichern.
;An dieser Stelle wird beim einlesen
;der Partitionen über den "$"-Befehl die
;Partitions-Nr. ab $03/$04 gespeichert,
;oder im GEOS-Modus / SD2IEC-DiskImages
;die Größe ab $1e/$1f gespeichert.
;Im ersten Fall wird die Größe der
;Partition im zweiten Schritt ergänzt.
::wrPartSize		lda	Blocks +0		;Größe DiskImage/Partition in
			sta	(r15L),y		;Verzeichnis-Eintrag übernehmen.
			iny
			lda	Blocks +1
			sta	(r15L),y

			jsr	ChkListFull		;Zeiger auf nächsten Eintrag.
			txa				;Liste voll?
			bne	:EOD			; => Ja, Ende...

::findEOL		jsr	ACPTR			;Rest der Zeile überlesen.
			cmp	#$00
			bne	:findEOL
			jmp	:next_line		;Nächsten Dateinamen einlesen.

;*** Verzeichnis-Ende.
::EOD			jsr	UNTALK			;Datenkanal schließen.

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.
			lda	#$e0			;Laufwerk abschalten.
			jsr	SECOND
			jsr	UNLSN

			ldx	#$00			;Kein Fehler.

;*** Verzeichnis abschließen.
:GetDirListEnd		txa
			pha
			jsr	DoneWithIO		;I/O deaktivieren.
			pla
			tax
			rts				;Ende.

;*** Eintrag in Verzeichnis-Liste suchen.
:FindDirFile		ldx	cntEntries +1		;Verzeichnisse vorhanden?
			beq	:file_ok		; => Nein, Ende...
			stx	r11L

			ldx	#r10L
			jsr	ADDR_RAM_x		;Anfang Verzeichnis im RAM.

::next_entry		CmpW	r10,r15			;Aktuellen Eintrag erreicht?
			beq	:set_next_entry		; => Ja, überspringen...

			ldy	#$05			;Dateiname vergleichen.
::loop_compare		lda	(r10L),y
			bne	:compare
			lda	(r15L),y
			beq	:file_exist
			bne	:set_next_entry
::compare		cmp	(r15L),y
			bne	:set_next_entry
			iny
			cpy	#$05 +16
			bcc	:loop_compare
			bcs	:file_exist

::set_next_entry	AddVBW	32,r10			;Zeiger auf nächsten Eintrag.
			dec	r11L			;Alle Einträge verglichen?
			bne	:next_entry		; => Nein, weiter...

			ldx	#$00			;OK.
			b $2c
::file_exist		ldx	#$ff			;Fehler.
::file_ok		rts

;*** Prüfen ob Dateiliste voll ist.
:ChkListFull		AddVBW	32,r15			;Zeiger auf nächsten Eintrag.
			inc	ListEntries

			lda	ListEntries		;Anzahl Einträge einlesen.
			bit	ReadDirMode		;Verzeichnisse oder Dateien suchen?
			bpl	:files			; => Dateien, weiter...

			inc	cntEntries +1		;Anzahl Verzeichnise +1.
			cmp	#100			;Speicher voll ( Anzahl = 100 ) ?
			beq	:list_full		; => Ja, Ende...
			bne	:list_ok		; => Nein, weitersuchen...

::files			inc	cntEntries +0		;Anzahl Dateien +1.
			cmp	#MAX_DIR_ENTRIES	;Speicher voll ( Anzahl = 224 ) ?
			beq	:list_full		; => Ja, Ende...

::list_ok		ldx	#$00			;List ready...
			b $2c
::list_full		ldx	#$ff			;List full...
			rts
