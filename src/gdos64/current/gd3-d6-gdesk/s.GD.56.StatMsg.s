; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Statusmeldung anzeigen.

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GERR"
			t "SymbTab_GTYP"
			t "SymbTab_DTYP"
			t "SymbTab_DBOX"
			t "SymbTab_CHAR"
			t "MacTab"

;--- Labels für GeoDesk64.
			t "TopSym.GD"

;--- Externe Labels.
			t "s.GD.10.Core.ext"

;--- Statusmeldungen.
;Wegen fehlendem Symbolspeicher als
;HEX-Werte direkt im Code enthalten.
;
;Siehe auch "TopSym.GD".
;
;PRNT_UPDATED		= $80 ! %01000000
;PRNT_NOT_UPDATED	= $80
;INPT_UPDATED		= $81 ! %01000000
;INPT_NOT_UPDATED	= $81
;UNKNOWN_FTYPE		= $82
;FILENAME_ERROR		= $83
;APPL_NOT_FOUND		= $84
;ALNK_NOT_FOUND		= $85
;SKIP_DIRECTORY		= $86
;GMOD_NOT_FOUND		= $87
;SENDTO_DRV_ERR		= $88
endif

;*** GEOS-Header.
			n "obj.GD56"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xSTATMSG

;*** Fehler-/Statusmeldung ausgeben.
:xSTATMSG		lda	curDrive		;Aktuelles Laufwerk einlesen und
			tay				;zwischenspeichern.
			clc
			adc	#"A" -8			;Laufwerk nach ASCII wandeln.
			sta	:drv

			lda	:gd_bufadr_lo -8,y
			sta	:txDrvType +0
			lda	:gd_bufadr_hi -8,y
			sta	:txDrvType +1		;Laufwerkstyp ermitteln.

			ldy	#0			;Fehlercode suchen.
::1			lda	errDataTab,y
			cmp	#$ff			;Ende Tabelle erreicht?
			beq	:2			; => Ja, Unbekannter Fehler.
			cmp	errDrvCode		;Fehlercode gefunden?
			beq	:2			; => Ja, weiter...
			iny
			cpy	#64			;Ende Tabelle erreicht?
			bne	:1			; => Nein, weitersuchen...

::2			tya				;Zeiger auf Textmeldung
			asl				;Zeile #1/#2 berechnen.
			asl
			tax
			lda	errDataVec +0,x		;Zeile #1.
			sta	:txDrvMsg1 +0
			lda	errDataVec +1,x
			sta	:txDrvMsg1 +1
			lda	errDataVec +2,x		;Zeile #2.
			sta	:txDrvMsg2 +0
			lda	errDataVec +3,x
			sta	:txDrvMsg2 +1

			bit	errDrvCode		;Info oder Fehler?
			bvc	:setError		; => Fehler, weiter...

::setInfo		lda	#< Dlg_Titel_Info	;Titelzeile "Info".
			ldx	#> Dlg_Titel_Info
			bne	:setHeader

::setError		lda	#< Dlg_Titel_Err	;Titelzeile "Fehler".
			ldx	#> Dlg_Titel_Err
;			bne	:setHeader

::setHeader		sta	:errHeader +0		;Zeiger auf Titelzeile speichern.
			stx	:errHeader +1

			lda	errDrvCode		;Fehlercode nach ASCII wandeln.
			jsr	HEX2ASCII
			stx	errCode +4
			sta	errCode +5
			stx	errFName +4
			sta	errFName +5

			lda	errDataInfo,y		;Track/Sektor oder Dateiname?
			beq	:errInfo		; => Track/Sektor, weiter...

;--- Dateiname aufbereiten
::errFName		LoadW	:txErrInfo,errFName

			lda	errDrvInfoF +0		;Zeiger auf Dateiname.
			sta	r0L
			lda	errDrvInfoF +1
			sta	r0H

			ldy	#$00
			lda	r0L
			ora	r0H			;Dateiname angegeben?
			beq	:nameFillUp		; => Nein, weiter...

::3			lda	(r0L),y
			beq	:nameFillUp
			cmp	#$20			;Auf Sonderzeichen testen.
			bcc	:4
			cmp	#$7f
			bcc	:5
::4			lda	#GD_REPLACE_CHAR	;Sonderzeichen ersetzen.
::5			sta	errFName +7,y		;Zeichen in Dateiname kopieren.
			iny
			cpy	#$10
			bcc	:3
			bcs	:nameDone

::nameFillUp		cpy	#$10			;Rest Dateiname löschen.
			bcs	:nameDone
			lda	#" "
			sta	errFName +7,y
			iny
			bne	:nameFillUp
::nameDone		beq	:doMsg

;--- Track/Sektor aufbereiten.
::errInfo		LoadW	:txErrInfo,errCode

			lda	errDrvInfoT		;Track nach ASCII wandeln.
			jsr	HEX2ASCII
			stx	errCode +7
			sta	errCode +8

			lda	errDrvInfoS		;Sektor nach ASCII wandeln.
			jsr	HEX2ASCII
			stx	errCode +10
			sta	errCode +11

			lda	errDrvInfoP		;Partition nach ASCII wandeln.
			jsr	HEX2ASCII
			stx	errCode +13
			sta	errCode +14

::doMsg			LoadW	r0,:dlgErrBox
			jmp	DoDlgBox		;Fehlermeldung anzeigen.

;*** Zeiger auf Laufwerkstypen.
::gd_bufadr_lo		b < GD_DRVTYPE_A
			b < GD_DRVTYPE_B
			b < GD_DRVTYPE_C
			b < GD_DRVTYPE_D
::gd_bufadr_hi		b > GD_DRVTYPE_A
			b > GD_DRVTYPE_B
			b > GD_DRVTYPE_C
			b > GD_DRVTYPE_D

;*** Fehler: Keine Diskette in Laufwerk.
::dlgErrBox		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
::errHeader		w Dlg_Titel_Err
			b DBTXTSTR   ,$0c,$20
			w :0
			b DBTXTSTR   ,$40,$5a
::txErrInfo		w errCode
if LANG = LANG_DE
			b DBTXTSTR   ,$50,$20
endif
if LANG = LANG_EN
			b DBTXTSTR   ,$40,$20
endif
::txDrvType		w $ffff
			b DBTXTSTR   ,$0c,$30
::txDrvMsg1		w $ffff
			b DBTXTSTR   ,$0c,$3c
::txDrvMsg2		w $ffff
			b OK         ,$01,$50
			b NULL

if LANG = LANG_DE
::0			b BOLDON
			b "Laufwerk: "
::drv			b $ff
			b ":",NULL
endif
if LANG = LANG_EN
::0			b BOLDON
			b "Drive: "
::drv			b $ff
			b ":",NULL
endif

:errCode		b PLAINTEXT
			b "( $00:00x00/00 )",NULL
:errFName		b PLAINTEXT
			b "( $00:                 )",NULL

;*** Tabelle mit Fehlertexten.
:errDataVec		w m00a,m00b			;NO_ERROR
			w m01a,m01b			;NO_BLOCKS
			w m02a,m02b			;INV_TRACK
			w m03a,m03b			;INSUFF_SPACE
			w m04a,m04b			;FULL_DIRECTORY
			w m05a,m05b			;FILE_NOT_FOUND
			w m06a,m06b			;BAD_BAM
			w m07a,m07b			;UNOPENED_VLIR
			w m08a,m08b			;INV_RECORD
			w m09a,m09b			;OUT_OF_RECORDS
			w m0Aa,m0Ab			;STRUCT_MISMAT
			w m0Ba,m0Bb			;BFR_OVERFLOW
			w m0Ca,m0Cb			;CANCEL_ERR
			w m0Da,m0Db			;DEV_NOT_FOUND
			w m0Ea,m0Eb			;INCOMPATIBLE
			w m20a,m20b			;HDR_NOT_THERE
			w m21a,m21b			;NO_SYNC
			w m22a,m22b			;DBLK_NOT_THERE
			w m23a,m23b			;DAT_CHKSUM_ERR
			w m25a,m25b			;WR_VER_ERR
			w m26a,m26b			;WR_PR_ON
			w m27a,m27b			;HDR_CHKSUM_ERR
			w m29a,m29b			;DSK_ID_MISMAT
			w m2Ea,m2Eb			;BYTE_DEC_ERR
			w m30a,m30b			;NO_PARTITION
			w m31a,m31b			;PART_FORMAT_ERR
			w m32a,m32b			;ILLEGA_PARTITION
			w m33a,m33b			;NO_PART_FD_ERR
			w m40a,m40b			;ILLEGAL_DEVICE
			w m60a,m60b			;NO_FREE_RAM
			w m73a,m73b			;DOS_MISMATCH
			w mC0a,mC0b			;PRNT_UPDATED
			w m80a,m80b			;PRNT_NOT_UPDATED
			w mC1a,mC1b			;INPT_UPDATED
			w m81a,m81b			;INPT_NOT_UPDATED
			w m82a,m82b			;UNKNOWN_FTYPE
			w m83a,m83b			;FILENAME_ERROR
			w m84a,m84b			;APPL_NOT_FOUND
			w m85a,m85b			;ALNK_NOT_FOUND
			w m86a,m86b			;SKIP_DIRECTORY
			w m87a,m87b			;GMOD_NOT_FOUND
			w m88a,m88b			;GMOD_NOT_FOUND
			w mFFa,mFFb			;UNKNOWN_ERROR

;*** Fehlermeldungen.
:errDataTab
::e00			b NO_ERROR
::e01			b NO_BLOCKS
::e02			b INV_TRACK
::e03			b INSUFF_SPACE
::e04			b FULL_DIRECTORY
::e05			b FILE_NOT_FOUND
::e06			b BAD_BAM
::e07			b UNOPENED_VLIR
::e08			b INV_RECORD
::e09			b OUT_OF_RECORDS
::e0A			b STRUCT_MISMAT
::e0B			b BFR_OVERFLOW
::e0C			b CANCEL_ERR
::e0D			b DEV_NOT_FOUND
::e0E			b INCOMPATIBLE
::e20			b HDR_NOT_THERE
::e21			b NO_SYNC
::e22			b DBLK_NOT_THERE
::e23			b DAT_CHKSUM_ERR
::e25			b WR_VER_ERR
::e26			b WR_PR_ON
::e27			b HDR_CHKSUM_ERR
::e29			b DSK_ID_MISMAT
::e2E			b BYTE_DEC_ERR
::e30			b NO_PARTITION
::e31			b PART_FORMAT_ERR
::e32			b ILLEGAL_PARTITION
::e33			b NO_PART_FD_ERR
::e40			b ILLEGAL_DEVICE
::e60			b NO_FREE_RAM
::e73			b DOS_MISMATCH

;--- GeoDesk Meldungen.
::eC0			b $c0				;Drucker intalliert.
::e80			b $80				;Drucker nicht intalliert.
::eC1			b $c1				;Eingabegerät intalliert.
::e81			b $81				;Eingabegerät nicht intalliert.
::e82			b $82				;Unbekannter Dateityp.
::e83			b $83				;Dateifehler.
::e84			b $84				;Anwendung fehlt.
::e85			b $85				;Applink nicht gefunden.
::e86			b $86				;Verzeichnis wird übersprungen.
::e87			b $87				;GeoDesk-Modul nicht installiert.
::e88			b $88				;Ungültiges Laufwerk für "Senden an...".

;--- Unbekannter Fehler
::eFF			b $ff

;*** Fehlerinformation.
; $00 = Track/Sektor/Partition.
; $ff = Dateiname.
:errDataInfo
::e00			b $00
::e01			b $00
::e02			b $00
::e03			b $00
::e04			b $00
::e05			b $ff
::e06			b $00
::e07			b $00
::e08			b $00
::e09			b $00
::e0A			b $00
::e0B			b $00
::e0C			b $00
::e0D			b $00
::e0E			b $ff
::e20			b $00
::e21			b $00
::e22			b $00
::e23			b $00
::e25			b $00
::e26			b $00
::e27			b $00
::e29			b $00
::e2E			b $00
::e30			b $00
::e31			b $00
::e32			b $00
::e33			b $00
::e40			b $00
::e60			b $00
::e73			b $00

;--- GeoDesk Fehlermeldungen.
::eC0			b $ff				;Drucker intalliert.
::e80			b $ff				;Drucker nicht intalliert.
::eC1			b $ff				;Eingabegerät intalliert.
::e81			b $ff				;Eingabegerät nicht intalliert.
::e82			b $ff				;Unbekannter Dateityp.
::e83			b $ff				;Dateifehler.
::e84			b $ff				;Anwendung fehlt.
::e85			b $ff				;Applink nicht gefunden.
::e86			b $ff				;Verzeichnis wird übersprungen.
::e87			b $ff				;GeoDesk-Modul nicht installiert.
::e88			b $00				;Ungültiges Laufwerk für "Senden an...".

;--- Unbekannter Fehler
::eFF			b $00

if LANG = LANG_DE
;--- SAMPLE:
;m21a			b PLAINTEXT
;			b "SYNC-Markierung nicht gefunden!",NULL
;m21b			b "(Kein Medium/unformatiert/fehlerhaft)",NULL

;--- 00: NO_ERROR
:m00a			b PLAINTEXT
			b "Vorgang erfolgreich beendet:",NULL
:m00b			b "Es ist kein Fehler aufgetreten!",NULL

;--- 01: NO_BLOCKS
:m01a			b PLAINTEXT
			b "Es sind nicht genügend freie Blöcke",NULL
:m01b			b "auf dem Datenträger verfügbar!",NULL

;--- 02: INV_TRACK
:m02a			b PLAINTEXT
			b "Datenblock nicht lesbar:",NULL
:m02b			b "Spur-/Blockadresse ist ungültig!",NULL

;--- 03: INSUFF_SPACE
:m03a			b PLAINTEXT
			b "Es ist nicht genügend freier Speicher",NULL
:m03b			b "auf dem Medium verfügbar!",NULL

;--- 04: FULL_DIRECTORY
:m04a			b PLAINTEXT
			b "Verzeichnis ist voll, weitere Dateien",NULL
:m04b			b "können nicht angelegt werden!",NULL

;--- 05: FILE_NOT_FOUND
:m05a			b PLAINTEXT
			b "Die Datei wurde im Verzeichnis /",NULL
:m05b			b "auf Diskette nicht gefunden!",NULL

;--- 06: BAD_BAM
:m06a			b PLAINTEXT
			b "Die Blocktabelle ist fehlerhaft!",NULL
:m06b			b "Bitte `Diskette überprüfen` verwenden!",NULL

;--- 07: UNOPENED_VLIR
:m07a			b PLAINTEXT
			b "Daten können nicht gelesen werden:",NULL
:m07b			b "Datendatei wurde nicht geöffnet!",NULL

;--- 08: INV_RECORD
:m08a			b PLAINTEXT
			b "Zugriff auf Daten nicht möglich:",NULL
:m08b			b "Der Datensatz existiert nicht!",NULL

;--- 09: OUT_OF_RECORDS
:m09a			b PLAINTEXT
			b "Schreiben der Daten nicht möglich:",NULL
:m09b			b "Kein freier Datensatz verfügbar!",NULL

;--- 0A: STRUCT_MISMAT
:m0Aa			b PLAINTEXT
			b "Zugriff auf Daten nicht möglich:",NULL
:m0Ab			b "Falsches Dateiformat!",NULL

;--- 0B: BUFFER_OVERFLOW
:m0Ba			b PLAINTEXT
			b "Die Datenmenge überschreitet den",NULL
:m0Bb			b "zur Verfügung stehenden Speicher!",NULL

;--- 0C: CANCEL_ERR
:m0Ca			b PLAINTEXT
			b "Der Vorgang wurde auf Grund eines",NULL
:m0Cb			b "Fehlers abgebrochen!",NULL

;--- 0D: DEV_NOT_FOUND
:m0Da			b PLAINTEXT
			b "Das angeforderte Geräte existiert",NULL
:m0Db			b "nicht oder ist nicht ansprechbar!",NULL

;--- 0E: INCOMPATIBLE
:m0Ea			b PLAINTEXT
			b "Diese Anwendung ist nicht mit dem",NULL
:m0Eb			b "aktiven GEOS-System kompatibel!",NULL

;--- 20: HDR_NOT_THERE
:m20a			b PLAINTEXT
			b "Fehler beim Zugriff auf Datenblock:",NULL
:m20b			b "Header nicht gefunden!",NULL

;--- 21: NO_SYNC
:m21a			b PLAINTEXT
			b "SYNC-Markierung nicht gefunden!",NULL
:m21b			b "(Kein Medium/unformatiert/fehlerhaft)",NULL

;--- 22: DBLK_NOT_THERE
:m22a			b PLAINTEXT
			b "Zugriff auf Daten nicht möglich:",NULL
:m22b			b "Datenblock nicht gefunden!",NULL

;--- 23: DATA_CHECKSUM_ERR
:m23a			b PLAINTEXT
			b "Prüfsummenfehler im Datenblock!",NULL
:m23b			b "(Medium fehlerhaft/nicht formatiert)",NULL

;--- 25: WR_VER_ERR
:m25a			b PLAINTEXT
			b "Fehler beim schreiben der Daten:",NULL
:m25b			b "Überprüfung fehlgeschlagen!",NULL

;--- 26: WR_PR_ON
:m26a			b PLAINTEXT
			b "Fehler beim schreiben der Daten:",NULL
:m26b			b "Medium ist schreibgeschützt!",NULL

;--- 27: HDR_CHKSUM_ERR
:m27a			b PLAINTEXT
			b "Prüfsummenfehler im Datenheader!",NULL
:m27b			b "(Medium fehlerhaft/nicht formatiert)",NULL

;--- 29: DSK_ID_MISMAT
:m29a			b PLAINTEXT
			b "Fehler beim Zugriff auf das Laufwerk:",NULL
:m29b			b "Schreibschutz / Falsche Disk-ID!",NULL

;--- 2E: BYTE_DEC_ERR
:m2Ea			b PLAINTEXT
			b "Zugriff auf Daten nicht möglich:",NULL
:m2Eb			b "Datenbyte-Decodierungsfehler!",NULL

;--- 30: NO_PARTITION
:m30a			b PLAINTEXT
			b "Fehler beim Zugriff auf das Laufwerk:",NULL
:m30b			b "Keine gültige Partition gefunden!",NULL

;--- 31: PART_FORMAT_ERR
:m31a			b PLAINTEXT
			b "Fehler beim Zugriff auf das Laufwerk:",NULL
:m31b			b "Falsches Partitionsformat!",NULL

;--- 32: ILLEGAL_PARTITION
:m32a			b PLAINTEXT
			b "Fehler beim Zugriff auf das Laufwerk:",NULL
:m32b			b "Ungültige Partitionsnummer!",NULL

;--- 33: NO_PART_FD_ERR
:m33a			b PLAINTEXT
			b "Fehler beim Zugriff auf das Laufwerk:",NULL
:m33b			b "Diskette ist nicht partitioniert!",NULL

;--- 40: ILLEGAL_DEVICE
:m40a			b PLAINTEXT
			b "Fehler beim Zugriff auf das Laufwerk:",NULL
:m40b			b "Funktion wird nicht unterstützt!",NULL

;--- 60: NO_FREE_RAM
:m60a			b PLAINTEXT
			b "Laufwerk nicht möglich:",NULL
:m60b			b "Nicht genügend Speicher verfügbar!",NULL

;--- 73: DOS_MISMATCH
:m73a			b PLAINTEXT
			b "Zugriff auf Medium nicht möglich:",NULL
:m73b			b "Ungültige DOS-Kennung gefunden!",NULL

;--- FF: UNKNOWN_ERROR
:mFFa			b PLAINTEXT
			b "Unbekannter Fehler:",NULL
:mFFb			b "Funktion wird abgebrochen!",NULL
endif

if LANG = LANG_DE
;--- C0: PRNT_UPDATED
:mC0a			b PLAINTEXT
			b "Der ausgewählte Drucker wurde",NULL
:mC0b			b "im System installiert!",NULL

;--- 80: PRNT_NOT_UPDATED
:m80a			b PLAINTEXT
			b "Drucker wurde nicht installiert:",NULL
:m80b			b "Gerätetreiber nicht gefunden!",NULL

;--- C1: INPT_UPDATED
:mC1a			b PLAINTEXT
			b "Das ausgewählte Eingabegerät wurde",NULL
:mC1b			b "im System installiert!",NULL

;--- 81: INPT_NOT_UPDATED
:m81a			b PLAINTEXT
			b "Eingabegerät wurde nicht installiert:",NULL
:m81b			b "Gerätetreiber nicht gefunden!",NULL

;--- 82: UNKNOWN_FTYPE
:m82a			b PLAINTEXT
			b "Datei kann nicht geöffnet werden:",NULL
:m82b			b "Dateityp unbekannt!",NULL

;--- 83: FILENAME_ERROR
:m83a			b PLAINTEXT
			b "Datei kann nicht geöffnet werden:",NULL
:m83b			b "Nicht gefunden / Dateityp ungültig!",NULL

;--- 84: APPL_NOT_FOUND
:m84a			b PLAINTEXT
			b "Datei kann nicht geöffnet werden:",NULL
:m84b			b "Anwendung/Dokument nicht gefunden!",NULL

;--- 85: ALNK_NOT_FOUND
:m85a			b PLAINTEXT
			b "Datei kann nicht geöffnet werden:",NULL
:m85b			b "AppLink-Datei nicht gefunden!",NULL

;--- 86: SKIP_DIRECTORY
:m86a			b PLAINTEXT
			b "Verzeichnis kann nicht ersetzt werden:",NULL
:m86b			b "Vor dem kopieren Verzeichnis löschen!",NULL

;--- 87: GMOD_NOT_FOUND
:m87a			b PLAINTEXT
			b "Das angeforderte GeoDesk-Modul ist",NULL
:m87b			b "nicht installiert oder geladen!",NULL

;--- 88: SENDTO_DRV_ERR
:m88a			b PLAINTEXT
			b "Das Quell-Laufwerk kann nicht als",NULL
:m88b			b "Ziel-Laufwerk verwendet werden!",NULL
endif

if LANG = LANG_EN
;--- SAMPLE:
;m21a			b PLAINTEXT
;			b "SYNC mark not found!",NULL
;m21b			b "(No media/unformatted/bad disk)",NULL

;--- 00: NO_ERROR
:m00a			b PLAINTEXT
			b "Job completed:",NULL
:m00b			b "No error has occurred!",NULL

;--- 01: NO_BLOCKS
:m01a			b PLAINTEXT
			b "There are not enough free blocks",NULL
:m01b			b "available on the drive!",NULL

;--- 02: INV_TRACK
:m02a			b PLAINTEXT
			b "Data block not readable:",NULL
:m02b			b "Track-/block address not valid!",NULL

;--- 03: INSUFF_SPACE
:m03a			b PLAINTEXT
			b "There is not enough free space",NULL
:m03b			b "available on the drive!",NULL

;--- 04: FULL_DIRECTORY
:m04a			b PLAINTEXT
			b "Directory is full, no more files",NULL
:m04b			b "can be created!",NULL

;--- 05: FILE_NOT_FOUND
:m05a			b PLAINTEXT
			b "The file was not found in the",NULL
:m05b			b "directory / on disk!",NULL

;--- 06: BAD_BAM
:m06a			b PLAINTEXT
			b "The block table is faulty!",NULL
:m06b			b "Please use `Validate disk`!",NULL

;--- 07: UNOPENED_VLIR
:m07a			b PLAINTEXT
			b "Cannot read data:",NULL
:m07b			b "Data file was not opened!",NULL

;--- 08: INV_RECORD
:m08a			b PLAINTEXT
			b "Cannot access data::",NULL
:m08b			b "The record does not exist!",NULL

;--- 09: OUT_OF_RECORDS
:m09a			b PLAINTEXT
			b "Cannot write data:",NULL
:m09b			b "No free record available!",NULL

;--- 0A: STRUCT_MISMAT
:m0Aa			b PLAINTEXT
			b "Cannot access data::",NULL
:m0Ab			b "Wrong file format!",NULL

;--- 0B: BUFFER_OVERFLOW
:m0Ba			b PLAINTEXT
			b "The amount of data exceeds the",NULL
:m0Bb			b "available memory!",NULL

;--- 0C: CANCEL_ERR
:m0Ca			b PLAINTEXT
			b "The job was aborted due to",NULL
:m0Cb			b "an error!",NULL

;--- 0D: DEV_NOT_FOUND
:m0Da			b PLAINTEXT
			b "The requested device does not",NULL
:m0Db			b "exist or is not addressable!",NULL

;--- 0E: INCOMPATIBLE
:m0Ea			b PLAINTEXT
			b "This application is not compatible",NULL
:m0Eb			b "with the current GEOS system!",NULL

;--- 20: HDR_NOT_THERE
:m20a			b PLAINTEXT
			b "Cannot access data block:",NULL
:m20b			b "Header not found!",NULL

;--- 21: NO_SYNC
:m21a			b PLAINTEXT
			b "SYNC mark not found!",NULL
:m21b			b "(No media/unformatted/bad disk)",NULL

;--- 22: DBLK_NOT_THERE
:m22a			b PLAINTEXT
			b "Cannot access data:",NULL
:m22b			b "Data block not found!",NULL

;--- 23: DATA_CHECKSUM_ERR
:m23a			b PLAINTEXT
			b "Cheksum error in data block!",NULL
:m23b			b "(Disk faulty/not formatted)",NULL

;--- 25: WR_VER_ERR
:m25a			b PLAINTEXT
			b "Cannot write data:",NULL
:m25b			b "Verify data failed!",NULL

;--- 26: WR_PR_ON
:m26a			b PLAINTEXT
			b "Cannot write data:",NULL
:m26b			b "Disk is write protected!",NULL

;--- 27: HDR_CHKSUM_ERR
:m27a			b PLAINTEXT
			b "Checksum error in data header!",NULL
:m27b			b "(Disk faulty/not formatted)",NULL

;--- 29: DSK_ID_MISMAT
:m29a			b PLAINTEXT
			b "Cannot access disk drive:",NULL
:m29b			b "Bad / wrong disk ID!",NULL

;--- 2E: BYTE_DEC_ERR
:m2Ea			b PLAINTEXT
			b "Cannot access data:",NULL
:m2Eb			b "Data byte decoding error!",NULL

;--- 30: NO_PARTITION
:m30a			b PLAINTEXT
			b "Cannot access disk drive:",NULL
:m30b			b "No valid partition found!",NULL

;--- 31: PART_FORMAT_ERR
:m31a			b PLAINTEXT
			b "Cannot access disk drive:",NULL
:m31b			b "Wrong partition format!",NULL

;--- 32: ILLEGAL_PARTITION
:m32a			b PLAINTEXT
			b "Cannot access disk drive:",NULL
:m32b			b "Invalid partition number!",NULL

;--- 33: NO_PART_FD_ERR
:m33a			b PLAINTEXT
			b "Cannot access disk drive:",NULL
:m33b			b "No partitions on diskette!",NULL

;--- 40: ILLEGAL_DEVICE
:m40a			b PLAINTEXT
			b "Cannot access disk drive:",NULL
:m40b			b "Operation not supported!",NULL

;--- 60: NO_FREE_RAM
:m60a			b PLAINTEXT
			b "Drive can not be inmstalled:",NULL
:m60b			b "No enough memory available!",NULL

;--- 73: DOS_MISMATCH
:m73a			b PLAINTEXT
			b "Cannot access disk drive:",NULL
:m73b			b "Bad / faulty DOS indicator on disk!",NULL

;--- FF: UNKNOWN_ERROR
:mFFa			b PLAINTEXT
			b "Unknown error:",NULL
:mFFb			b "Operation will be aborted!",NULL
endif

if LANG = LANG_EN
;--- C0: PRNT_UPDATED
:mC0a			b PLAINTEXT
			b "The selected printer driver",NULL
:mC0b			b "has been installed!",NULL

;--- 80: PRNT_NOT_UPDATED
:m80a			b PLAINTEXT
			b "Printer could not be installed:",NULL
:m80b			b "Device driver not found!",NULL

;--- C1: INPT_UPDATED
:mC1a			b PLAINTEXT
			b "The selected input driver",NULL
:mC1b			b "has been installed!",NULL

;--- 81: INPT_NOT_UPDATED
:m81a			b PLAINTEXT
			b "Input device could not be installed:",NULL
:m81b			b "Device driver not found!",NULL

;--- 82: UNKNOWN_FTYPE
:m82a			b PLAINTEXT
			b "File cannot be opened:",NULL
:m82b			b "Unknown file type!",NULL

;--- 83: FILENAME_ERROR
:m83a			b PLAINTEXT
			b "File cannot be opened:",NULL
:m83b			b "File not found / not valid!",NULL

;--- 84: APPL_NOT_FOUND
:m84a			b PLAINTEXT
			b "File cannot be opened:",NULL
:m84b			b "Application for document is missing!",NULL

;--- 85: ALNK_NOT_FOUND
:m85a			b PLAINTEXT
			b "File cannot be opened:",NULL
:m85b			b "AppLink file not found!",NULL

;--- 86: SKIP_DIRECTORY
:m86a			b PLAINTEXT
			b "Directory can not be replaced:",NULL
:m86b			b "Delete directory before copying!",NULL

;--- 87: GMOD_NOT_FOUND
:m87a			b PLAINTEXT
			b "Requested GeoDesk module not",NULL
:m87b			b "installed or loaded!",NULL

;--- 88: SENDTO_DRV_ERR
:m88a			b PLAINTEXT
			b "The source drive cannot be used",NULL
:m88b			b "as the destination drive!",NULL
endif

;*** Endadresse testen:
			g BASE_DIRDATA
;***
