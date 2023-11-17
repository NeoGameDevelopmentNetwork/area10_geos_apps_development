; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = FD_41!FD_71!FD_81!FD_NM
if :tmp0 = TRUE
;******************************************************************************
;*** Partitionstypen einlesen.
;    Übergabe:		r4 = Zeiger auf Speicher für PartTyp.
;    Rückgabe:		   = 256 Bytes mit Partitionstypen für Partition 0-255.
:xGetPTypeData		jsr	xExitTurbo
			jsr	InitForIO
			jsr	xReadPTypeData
			jmp	DoneWithIO

;*** Partitionstypen einlesen.
;    Übergabe:		r4 = Zeiger auf Speicher für PartTyp.
;    Rückgabe:		   = 256 Bytes mit Partitionstypen für Partition 0-255.
:xReadPTypeData		ldx	#> com_PartTabFD
			lda	#< com_PartTabFD
			ldy	#$06
			jsr	SendComVLen		;Zeiger auf Partitionsdaten.
			bne	:53			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK		;Laufwerk auf Senden schalten.
			bne	:53			;Fehler? => Ja, Abbruch...

			ldy	#$00
::51			jsr	ACPTR			;Partitionsdaten einlesen.
			jsr	DefPTypeGEOS		;Umwandlung: CMD => GEOS.
			sta	(r4L),y			;Partitionstypen speichern.
			iny
			cpy	#$20
			bne	:51

			jsr	UNTALK			;Laufwerk abschalten.

			ldy	#$20			;Partitionen 33-255 löschen.
			lda	#$00			;(CMD-FD max. 32 Partitionen)
::52			sta	(r4L),y
			iny
			bne	:52

			tax				;Flag: "Kein Fehler".
;			ldx	#NO_ERROR
::53			rts

:com_PartTabFD		b "M-R",$00,$2a,$20

;*** Umwandeln der CMD-Partitionskennung nach GEOS-Format.
;    Übergabe:    AKKU = CMD-Partitionstyp
;    Rückgabe:    AKKU = GEOS-Partitionstyp
;    Verändert:   AKKU
;Hinweis: yReg darf nicht verändert werden, da in ":GetPDirEntry"
;das yReg zum speichern des Partitionstyp bereits initialisiert wurde.
:DefPTypeGEOS		cmp	#$00
			beq	:51
			cmp	#$05
			bcs	:51
			sec
			sbc	#$01
			bne	:51
			lda	#$04
::51			rts
endif

;******************************************************************************
::tmp1 = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp1 = TRUE
;******************************************************************************
;*** Partitionstypen einlesen.
;    Übergabe:		r4 = Zeiger auf Speicher für PartTyp.
;    Rückgabe:		   = 256 Bytes mit Partitionstypen für Partition 0-255.
:xGetPTypeData		jsr	xExitTurbo
			jsr	InitForIO
			jsr	xReadPTypeData
			jmp	DoneWithIO

;*** Partitionstypen einlesen.
;    Übergabe:		r4 = Zeiger auf Speicher für PartTyp.
;    Rückgabe:		   = 256 Bytes mit Partitionstypen für Partition 0-255.
:xReadPTypeData		ldx	#> com_PartTabHD
			lda	#< com_PartTabHD
			ldy	#$06
			jsr	SendComVLen		;Zeiger auf Partitionsdaten.
			bne	:52			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK		;Laufwerk auf Senden schalten.
			bne	:52			;Fehler? => Ja, Abbruch...

			ldy	#$00
::51			jsr	ACPTR			;Partitionsdaten einlesen.
			jsr	DefPTypeGEOS		;Umwandlung: CMD => GEOS.
			sta	(r4L),y			;Partitionstypen speichern.
			iny
			cpy	#$ff
			bne	:51

			jsr	UNTALK			;Laufwerk abschalten.

			lda	#$00			;Letztes Byte in Puffer löschen.
			sta	(r4L),y			;(für Partitions-Nr. 255).

			tax				;Flag: "Kein Fehler".
;			ldx	#NO_ERROR
::52			rts

:com_PartTabHD		b "M-R",$00,$82,$ff

;*** Umwandeln der CMD-Partitionskennung nach GEOS-Format.
;    Übergabe:    AKKU = CMD-Partitionstyp
;    Rückgabe:    AKKU = GEOS-Partitionstyp
;    Verändert:   AKKU
;Hinweis: yReg darf nicht verändert werden, da in ":GetPDirEntry"
;das yReg zum speichern des Partitionstyp bereits initialisiert wurde.
:DefPTypeGEOS		cmp	#$00
			beq	:51
			cmp	#$05
			bcs	:51
			sec
			sbc	#$01
			bne	:51
			lda	#$04
::51			rts
endif

;******************************************************************************
::tmp2 = RL_41!RL_71!RL_81!RL_NM
if :tmp2 = TRUE
;******************************************************************************
;*** Partitionstypen einlesen.
;    Übergabe:		r4 = Zeiger auf Speicher für PartTyp.
;    Rückgabe:		   = 256 Bytes mit Partitionstypen für Partition 0-255.
:xGetPTypeData		jsr	xExitTurbo
			jsr	InitForIO
			jsr	xReadPTypeData
			jmp	DoneWithIO

;*** Partitionstypen einlesen.
;    Übergabe:		r4 = Zeiger auf Speicher für PartTyp.
;    Rückgabe:		   = 256 Bytes mit Partitionstypen für Partition 0-255.
:xReadPTypeData		ldx	#r1L			;ZeroPage Register speichern.
::50			lda	zpage,x
			pha
			inx
			cpx	#r5H +1
			bcc	:50

			MoveW	r4 ,r5			;Zeiger auf Zwischenspeicher.
			LoadW	r4 ,dir3Head		;Zeiger auf Sektorpuffer.

			LoadB	r1L,$01			;Track Systempartition.

			LoadB	r3H,$ff			;Part-Nr. der Systempartition.
			LoadB	r3L,$00			;Zeiger auf erste Partition.

;			lda	#$00
::51			lsr				;Sektor mit Partition berechnen.
			lsr
			lsr
			sta	r1H
			jsr	xDsk_SekRead		;Verzeichnis-Sektor einlesen.

			ldx	#$00			;8 Partitionen aus Verzeichnis-
::52			txa				;Sektor einlesen und Partitionstyp
			asl				;in Tabelle übernehmen.
			asl
			asl
			asl
			asl
			tay
			lda	dir3Head +2,y		;Partitionstyp einlesen und
			jsr	DefPTypeGEOS		;von CMD nach GEOS wandeln.
			ldy	r3L
			sta	(r5L),y
			inc	r3L
			inx
			cpx	#8			;Sektor durchsucht?
			bcc	:52			; => Nein, weiter...

			lda	r3L
			cmp	#32			;Alle Partitionen durchsucht?
			bcc	:51			; => Nein, weiter...

			tay				;Partitionen 33-255 löschen.
			lda	#$00			;(CMD-RL max. 32 Partitionen)
::53			sta	(r5L),y
			iny
			bne	:53

			ldx	#r5H			;ZeroPage Register zurücksetzen.
::54			pla
			sta	zpage,x
			dex
			cpx	#r1L
			bcs	:54

			ldx	#NO_ERROR
			rts

;*** Umwandeln der CMD-Partitionskennung nach GEOS-Format.
;    Übergabe:    AKKU = CMD-Partitionstyp
;    Rückgabe:    AKKU = GEOS-Partitionstyp
;    Verändert:   AKKU
;Hinweis: yReg darf nicht verändert werden, da in ":GetPDirEntry"
;das yReg zum speichern des Partitionstyp bereits initialisiert wurde.
:DefPTypeGEOS		cmp	#$00
			beq	:51
			cmp	#$05
			bcs	:51
			sec
			sbc	#$01
			bne	:51
			lda	#$04
::51			rts
endif
