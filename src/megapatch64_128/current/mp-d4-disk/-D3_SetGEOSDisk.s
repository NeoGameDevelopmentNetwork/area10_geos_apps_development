; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0b = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** GEOS-Diskette erstellen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r3,r4
:xSetGEOSDisk		lda	DirHead_Tr		;Haupt-/Unterverzeichnis ?
			ldx	DirHead_Se
			cmp	#$01
			bne	:1			; => Unterverzeichnis.
			cpx	#$01
			bne	:1			; => Unterverzeichnis.

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:exitSetGDisk		; => Ja, Abbruch...

			jmp	:SetGEOSCode		;GEOS-Kennung erzeugen.

::1			pha				;Aktuelles Verzeichnis speichern.
			txa
			pha
			jsr	xOpenRootDir		;Hauptverzeichnis öffnen.
			txa
			bne	:failSetGDisk

			jsr	:SetGEOSCode		;GEOS-Kennung erzeugen.
			txa				;Fehler ?
			bne	:failSetGDisk		; => Ja, Abbruch...

			pla				;Vorheriges Verzeichnus wieder
			sta	r1H			;aktivieren.
			pla
			sta	r1L
			jmp	xOpenSubDir

::failSetGDisk		pla
			pla
::exitSetGDisk		rts

::SetGEOSCode		jsr	CalcCurBlksFree		;Anzahl freier Blocks berechnen.

			ldx	#INSUFF_SPACE
			lda	r4L
			ora	r4H			;Sektor auf Diskette frei ?
			beq	:exitSetGDisk		; => Nein, Abbruch...

			LoadB	r3L,Tr_1stDataSek
			LoadB	r3H,Se_1stDataSek
			jsr	xSetNextFree		;Freien Sektor auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:exitSetGDisk		; => Ja, Abbruch...

;			MoveB	r3L,r1L			;Wird durch ":clrDiskBlk_r3"
;			MoveB	r3H,r1H			;kopiert.
			jsr	clrDiskBlk_r3		;Inhalt des BorderBlocks löschen.
			txa				;Diskettenfehler ?
			bne	:exitSetGDisk		; => Ja, Abbruch...

			lda	r1L			;Zeiger auf BorderBlock in
			ldy	r1H			;BAM zwischenspeichern.
			sta	curDirHead +171
			sty	curDirHead +172

			ldx	#16 -1
::2			lda	FormatText     ,x	;GEOS-Formatkennung setzen.
			sta	curDirHead +173,x
			dex
			bpl	:2

			jmp	xPutDirHead		;BAM auf Diskette speichern.
endif

;******************************************************************************
::tmp1a = RL_81!RL_71!RL_41!RD_81!RD_71!RD_41
::tmp1b = C_41!C_71!C_81!FD_41!FD_71!FD_81!HD_41!HD_71!HD_81
::tmp1c = HD_41_PP!HD_71_PP!HD_81_PP
::tmp1  = :tmp1a!:tmp1b!:tmp1c
if :tmp1 = TRUE
;******************************************************************************
;*** GEOS-Diskette erstellen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r3,r4
:xSetGEOSDisk		jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:exitSetGDisk		; => Ja, Abbruch...

			jsr	CalcCurBlksFree		;Anzahl freier Blocks berechnen.

			jsr	IsDirSekFree		;Freien Verzeichnis-Sektor suchen.
			txa				;Ist Sektor frei ?
			bne	:exitSetGDisk		; => Abbruch wenn kein Sektor frei.

			lda	#Tr_BorderBlock		;Zeiger auf BorderBlock.
			sta	r3L
			lda	#Se_BorderBlock
			sta	r3H
			jsr	SetNextFree		;BorderBlock belegen.
			txa				;Diskettenfehler ?
			bne	:exitSetGDisk		; => Ja, Abbruch...

;			MoveB	r3L,r1L			;Wird durch ":clrDiskBlk_r3"
;			MoveB	r3H,r1H			;kopiert.
			jsr	clrDiskBlk_r3		;Inhalt des BorderBlocks löschen.
			txa				;Diskettenfehler ?
			bne	:exitSetGDisk		; => Ja, Abbruch...

			lda	r1L			;Zeiger auf BorderBlock in
			sta	curDirHead +171		;BAM zwischenspeichern.
			lda	r1H
			sta	curDirHead +172

			ldx	#16 -1
::1			lda	FormatText     ,x	;GEOS-Formatkennung setzen.
			sta	curDirHead +173,x
			dex
			bpl	:1

			jsr	xPutDirHead		;BAM auf Diskette speichern.
::exitSetGDisk		rts
endif
