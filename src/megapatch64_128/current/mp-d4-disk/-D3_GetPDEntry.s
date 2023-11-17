; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0b = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Partitionsdaten einlesen.
:xGetPDirEntry		ldx	curDrive
			lda	turboFlags -8,x		;TurboFlag zwischenspeichern.
			pha

			jsr	xExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O aktivieren.
			jsr	xReadPDirEntry		;Partitionsdaten einlesen.
			jsr	DoneWithIO		;I/O abschalten.

			pla				;War TurboDOS installiert?
			bpl	:51			; => Nein, weiter...
			asl				;War TurboDOS aktiv?
			bpl	:51			; => Nein, weiter...
			txa
			pha
			jsr	xEnterTurbo		;TurboDOS wieder aktivieren.
			pla
			tax

::51			rts

;*** Partitionsdaten einlesen.
:xReadPDirEntry		ldx	#ILLEGAL_PARTITION
			lda	r3H
			cmp	#$ff
			beq	:51
			cmp	#PART_MAX +1
			bcs	:53
::51			sta	com_GP +3

			ldx	#> com_GP
			lda	#< com_GP
			jsr	SendCom5Byt		;"G-P"-Befehl senden.
			bne	:53			;Fehler? => Ja, Abbruch...

			jsr	UNLSN			;Laufwerk abschalten.

			jsr	initDevTALK		;Laufwerk auf Senden schalten.
			bne	:53			;Fehler? => Ja, Abbruch...

			ldy	#0
::52			jsr	ACPTR			;Partitionsinformationen
			sta	(r4L),y			;von Laufwerk einlesen.
			iny
			cpy	#30
			bcc	:52

			jsr	ACPTR			;Abschlussbyte einlesen.
			jsr	UNTALK			;Laufwerk abschalten.

			ldy	#$00
			lda	(r4L),y
			jsr	DefPTypeGEOS		;Partitionstyp nach GEOS wandeln.
;			ldy	#$00
			sta	(r4L),y

			ldx	#NO_ERROR
::53			rts

:com_GP			b "G-P",$00,$0d

:GP_DATA		s 32
:GP_DATA_TYPE		= GP_DATA +0
:GP_DATA_INFO		= GP_DATA +1
:GP_DATA_PNR		= GP_DATA +2
endif

;******************************************************************************
::tmp1 = RL_41!RL_71!RL_NM
if :tmp1 = TRUE
;******************************************************************************
;*** Partitionsdaten einlesen.
:xGetPDirEntry

;*** Partitionsdaten einlesen.
;    Übergabe:		r3H	= Partitions-Nr.
;			r4	= Zeiger auf Speicherbereich.
;    Geändert:		AKKU,xReg,yReg,r1,r3H,r4
:xReadPDirEntry		ldx	#ILLEGAL_PARTITION
			lda	r3H
			cmp	#$ff
			beq	:50
			cmp	#PART_MAX +1
			bcs	:55

::50			PushW	r4

			lda	r3H
			pha
			cmp	#$ff
			bne	:51
			lda	RL_PartNr
::51			lsr
			lsr
			lsr
			sta	r1H
			LoadB	r1L,$01
			LoadB	r3H,$ff
			jsr	Set_Dir3Head
			jsr	xDsk_SekRead		;Verzeichnis-Sektor einlesen.
			pla				;Zeiger innerhalb Sektor berechnen.
			sta	r3H
			cmp	#$ff
			bne	:52
			lda	RL_PartNr
::52			and	#%00000111
			asl
			asl
			asl
			asl
			asl
			tax
			inx
			inx

			PopW	r4

			ldy	#$00
::53			lda	dir3Head ,x		;Eintrag in Zwischenspeicher
			sta	(r4L),y			;kopieren.
			inx
			iny
			cpy	#30
			bcc	:53

			lda	r3H
			cmp	#$ff
			bne	:54
			lda	RL_PartNr
::54			ldy	#$02
			sta	(r4L),y

			ldy	#$00
			lda	(r4L),y
			jsr	DefPTypeGEOS
;			ldy	#$00
			sta	(r4L),y

			ldx	#NO_ERROR
::55			rts

:GP_DATA		s 32
:GP_DATA_TYPE		= GP_DATA +0
:GP_DATA_INFO		= GP_DATA +1
:GP_DATA_PNR		= GP_DATA +2
endif

;******************************************************************************
::tmp2 = RL_81
if :tmp2 = TRUE
;******************************************************************************
;*** Partitionsdaten einlesen.
:xGetPDirEntry

;*** Partitionsdaten einlesen.
;    Übergabe:		r3H	= Partitions-Nr.
;			r4	= Zeiger auf Speicherbereich.
;    Geändert:		AKKU,xReg,yReg,r1,r3H,r4
:xReadPDirEntry		ldx	#ILLEGAL_PARTITION
			lda	r3H
			cmp	#$ff
			beq	:50
			cmp	#PART_MAX +1
			bcs	:55

::50			jsr	Save_dir3Head

			PushW	r4

			lda	r3H
			pha
			cmp	#$ff
			bne	:51
			lda	RL_PartNr
::51			lsr
			lsr
			lsr
			sta	r1H
			LoadB	r1L,$01
			LoadB	r3H,$ff
			jsr	Set_Dir3Head
			jsr	xDsk_SekRead		;Verzeichnis-Sektor einlesen.
			pla				;Zeiger innerhalb Sektor berechnen.
			sta	r3H
			cmp	#$ff
			bne	:52
			lda	RL_PartNr
::52			and	#%00000111
			asl
			asl
			asl
			asl
			asl
			tax
			inx
			inx

			PopW	r4

			ldy	#$00
::53			lda	dir3Head ,x		;Eintrag in Zwischenspeicher
			sta	(r4L),y			;kopieren.
			inx
			iny
			cpy	#30
			bcc	:53

			lda	r3H
			cmp	#$ff
			bne	:54
			lda	RL_PartNr
::54			ldy	#$02
			sta	(r4L),y

			ldy	#$00
			lda	(r4L),y
			jsr	DefPTypeGEOS
;			ldy	#$00
			sta	(r4L),y

			ldx	#NO_ERROR
			jmp	Load_dir3Head
::55			rts

:GP_DATA		s 32
:GP_DATA_TYPE		= GP_DATA +0
:GP_DATA_INFO		= GP_DATA +1
:GP_DATA_PNR		= GP_DATA +2
endif
