; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** DiskImages und Verzeichnisse einlesen.
:READ_SD2IEC_DATA	lda	#$00			;Anzahl Einträge löschen.
			sta	ListEntries

			sta	cntEntries +0		;Anzahl Dateien = 0.
			sta	cntEntries +1		;Anzahl Verzeichnisse = 0.

			jsr	getModeSD2IEC		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:sd_img_mode		; => DiskImage-Modus aktiv.
			cpx	#$ff
			beq	:sd_dir_mode		; => Verzeichnis-Modus aktiv.
			rts				;Fehler, Abbruch...

::sd_img_mode		lda	#<FComExitDImg		;Aktives DiskImage verlassen.
			ldx	#>FComExitDImg
			jsr	SendCom

::sd_dir_mode		lda	DiskImgTyp
			asl
			tay
			lda	DImgTypeList +0,y	;Kennung D64/D71/D81/DNP in
			sta	FComDImgList +5		;Verzeichnis-Befehl eintragen.
			lda	DImgTypeList +1,y
			sta	FComDImgList +6

			jsr	ADDR_RAM_r15		;Anfang Verzeichnis im RAM.

;*** Verzeichnisse hinzufügen.
::addDirData		PushW	r15			;Zeiger auf Dateiliste speichern.

			lda	#<FComSDirList		;Liste mit Verzeichnissen einlesen.
			ldx	#>FComSDirList
			ldy	#$ff
			jsr	GetDirList

			PopW	a1			;Zeiger auf Dateiliste.
			lda	cntEntries +1		;Anzahl Verzeichnisse.
			sta	a0L
			ClrB	a0H
			jsr	xSORT_ALL_FILES		;Verzeichnisse sortieren.

;*** Dateienn hinzufügen.
::addFileData		PushW	r15			;Zeiger auf Dateiliste speichern.

			lda	#<FComDImgList		;Liste mit DiskImages einlesen.
			ldx	#>FComDImgList
			ldy	#$00
			jsr	GetDirList

			PopW	a1			;Zeiger auf Dateiliste.
			lda	cntEntries +0		;Anzahl Dateien.
			sta	a0L
			ClrB	a0H
			jmp	xSORT_ALL_FILES		;Disk-Images sortieren.

;*** Daten an Floppy senden.
:SendCom		sta	r0L
			stx	r0H

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO
			jsr	:100			;Befehl senden.
			jmp	DoneWithIO

::100			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.

			lda	#$00
			sta	STATUS			;Status löschen.
			lda	curDrive
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff			;Befehlskanal #15.
			jsr	SECOND			;Sekundär-Adr. nach LISTEN senden.

			lda	STATUS			;Laufwerk vorhanden ?
			bne	:103			;Nein, Abbruch...

			ldy	#$01			;Zähler für Anzahl Bytes einlesen.
			lda	(r0L),y
			sta	r1H
			dey
			lda	(r0L),y
			sta	r1L
			AddVBW	2,r0			;Zeiger auf Befehlsdaten setzen.
			jmp	:102

::101			lda	(r0L),y			;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			bne	:102
			inc	r0H
::102			SubVW	1,r1			;Zähler Anzahl Bytes korrigieren.
			bcs	:101			;Schleife bis alle Bytes ausgegeben.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts

::103			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts
