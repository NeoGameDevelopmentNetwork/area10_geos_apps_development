; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** CMD-Partitionen über GEOS/MP3 einlesen.
:READ_PART_DATA		jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO

			LoadW	r0,comInitDisk		;"I0:"-Befehl senden.
			LoadB	r2L,3			;Bei einer CMD-HD mit einem externen
			jsr	SendFloppyCom		;SCSI-Laufwerk wird damit bei einem
			jsr	UNLSN			;Medien-Wechsel die Partitions-
							;tabelle von Disk neu eingelesen.

			jsr	DoneWithIO		;I/O abschalten.

;--- Hinweis:
;Partitionen einlesen, ":OpenDisk"
;hier wirklich erforderlich ?
;			jsr	OpenDisk		;Diskette öffnen. Bei CMD-HD/FD
;							;wird dabei auch eine gültige
;							;Partition aktiviert.

			jsr	i_FillRam		;Speicher initialisieren.
			w	partTypeBuf_S
			w	partTypeBuf
			b	$00

			LoadW	r4,partTypeBuf		;Zeiger auf Zwischenspeicher.
			jsr	GetPTypeData		;CMD-Partitionsdaten abrufen.

			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O einschalten.
			jsr	InitForIO

			lda	#$00			;Anzahl Einträge löschen.
			sta	ListEntries

			LoadB	r3H,1			;Zeiger auf Partition #1.
			LoadW	r4,partEntryBuf		;Zeiger auf Zwischenspeicher.

			jsr	ADDR_RAM_r15		;Zeiger auf Speicher für Daten.

::read_part		ldx	r3H
			lda	partTypeBuf,x		;Partitionstyp einlesen.
			cmp	DiskImgTyp		;Mit Laufwerkstyp vergleichen.
			bne	:next_part		; => Fehler, weiter...

			jsr	ReadPDirEntry		;Partitionseintrag einlesen.
			txa				;Fehler?
			bne	:next_part		; => Ja, nächste Partition.

			lda	partEntryBuf		;Partition definiert?
			beq	:next_part		; => Nein, nächste Partition.

			ldy	#$02
			lda	DiskImgTyp		;Partitions-Typ speichern.
			sta	(r15L),y
			iny
			lda	r3H			;Partitions-Nr. speichern.
			sta	(r15L),y

			ldy	#$05
			ldx	#$03
::loop_name		lda	partEntryBuf,x		;Partitions-Name speichern.
			cmp	#$a0
			beq	:exit_loop_name
			sta	(r15L),y
			iny
			inx
			cpx	#$03+16
			bcc	:loop_name

::exit_loop_name	jsr	getPartSize		;Partitionsgröße einlesen.

			ldy	#$1e			;Partitionsgröße in
			sta	(r15L),y		;Eintrag kopieren.
			iny
			txa
			sta	(r15L),y

			jsr	ChkListFull		;Zeiger auf nächsten Eintrag.
			txa				;Liste voll?
			bne	:exit			; => Ja, Ende...

::next_part		inc	r3H			;Zeiger auf nächsten Eintrag.
			lda	r3H
			cmp	#255			;Alle Partitionen geeprüft?
			bcc	:read_part		; => Nein, weitere...

::exit			ldx	#NO_ERROR		;Kein Fehler.
			jmp	DoneWithIO		;I/O abchalten.

:comInitDisk		b "I0:"

;*** Reservierter Speicher.
;Hinweis:
;Der reservierte Speicher ist nicht
;initialisiert!

;--- Speicher für Partitonstypen.
;Je 1 Byte für jede Partition, Wert von
;$00-$04 für Partitionstyp.
;partTypeBuf		s 256

;*** CMD-Partitionsgröße ermitteln.
:getPartSize		ldy	#$02
			lda	(r15L),y		;Partitionstyp einlesen.
			cmp	#DrvNative		;NativeMode?
			beq	:native			; => Nein, weiter...

			sec				;Zeiger auf Partitionsgröße
			sbc	#$01			;berechnen.
			asl
			tay
			lda	partSizeData+0,y	;Low-Byte.
			ldx	partSizeData+1,y	;High-Byte.
			bne	:exit

::native		ldy	#$03			;Bei NativeMode Cluster-Anzahl
			lda	(r15L),y		;einlesen.
			sta	r3H
			jsr	ReadPDirEntry
			txa				;Fehler?
			beq	:get_native_size	; => Nein, weiter...

			lda	#$00
			tax				;Partitionsgröße löschen.
			beq	:exit			; => Ende...

::get_native_size	lda	partEntryBuf+29		;Partitionsgröße in 512Byte Cluster
			asl				;in 256Byte Blocks umrechnen.
			pha
			lda	partEntryBuf+28
			rol
			tax
			pla
::exit			rts
