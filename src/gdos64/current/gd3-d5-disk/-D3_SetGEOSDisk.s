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
;Übergabe: -
;Rückgabe: X = $00: Kein Fehler.
;Geändert: A,X,Y,r1,r3,r4,r5
:xSetGEOSDisk		lda	#1			;Hauptverzeichnis öffnen.
			sta	DirHead_Tr
			sta	DirHead_Se

			jsr	xGetDirHead		;Aktuelle BAM/ROOT-Dir einlesen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;XReg ist bereits $00.
			jsr	ChkDkGEOS_r5		;Auf GEOS-Diskette testen.
;			tay				;":isGEOS" = $FF?
			bne	:exit			; => Ja, ist bereits GEOS-Diskette!

			jsr	CalcCurBlksFree		;Anzahl freier Blocks berechnen.

			ldx	#INSUFF_SPACE
			lda	r4L
			ora	r4H			;Sektor auf Diskette frei ?
			beq	:exit			; => Nein, Abbruch...

			lda	#Tr_BorderBlock		;Zeiger auf ersten Datenblock für
			sta	r3L			;Suche nach freiem Sektor setzen.
			lda	#Se_BorderBlock
			sta	r3H
			jsr	xSetNextFree		;Freien Sektor auf Diskette suchen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

;			MoveB	r3L,r1L			;Wird durch ":clrDiskBlk_r3"
;			MoveB	r3H,r1H			;kopiert.
			jsr	clrDiskBlk_r3		;Inhalt des BorderBlocks löschen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	r1L			;Zeiger auf Borderblock in
			sta	curDirHead +171		;BAM zwischenspeichern.
			lda	r1H
			sta	curDirHead +172

			ldx	#16 -1
::1			lda	GEOS_FormatInfo,x	;GEOS-Formatkennung setzen.
			sta	curDirHead +173,x
			dex
			bpl	:1

			jsr	xPutDirHead		;BAM auf Diskette speichern.
;			txa				;Diskettenfehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts
endif

;******************************************************************************
::tmp1a = RL_81!RL_71!RL_41!RD_81!RD_71!RD_41
::tmp1b = C_41!C_71!C_81!FD_41!FD_71!FD_81!HD_41!HD_71!HD_81
::tmp1c = HD_41_PP!HD_71_PP!HD_81_PP
::tmp1  = :tmp1a!:tmp1b!:tmp1c
if :tmp1 = TRUE
;******************************************************************************
;*** GEOS-Diskette erstellen.
;Übergabe: -
;Rückgabe: X = $00: Kein Fehler.
;Geändert: A,X,Y,r1,r3,r4,r5
:xSetGEOSDisk		jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

;			ldx	#NO_ERROR		;XReg ist bereits $00.
			jsr	ChkDkGEOS_r5		;Auf GEOS-Diskette testen.
;			tay				;":isGEOS" = $FF?
			bne	:exit			; => Ja, ist bereits GEOS-Diskette!

			jsr	CalcCurBlksFree		;Anzahl freier Blocks berechnen.

			jsr	IsDirSekFree		;Freien Verzeichnis-Sektor suchen.
			txa				;Ist Sektor frei ?
			bne	:exit			; => Abbruch wenn kein Sektor frei.

			lda	#Tr_BorderBlock		;Zeiger auf Borderblock.
			sta	r3L
			lda	#Se_BorderBlock
			sta	r3H
			jsr	xSetNextFree		;Borderblock belegen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

;			MoveB	r3L,r1L			;Wird durch ":clrDiskBlk_r3"
;			MoveB	r3H,r1H			;kopiert.
			jsr	clrDiskBlk_r3		;Inhalt des BorderBlocks löschen.
			txa				;Diskettenfehler ?
			bne	:exit			; => Ja, Abbruch...

			lda	r1L			;Zeiger auf Borderblock in
			sta	curDirHead +171		;BAM zwischenspeichern.
			lda	r1H
			sta	curDirHead +172

			ldx	#16 -1
::1			lda	GEOS_FormatInfo,x	;GEOS-Formatkennung setzen.
			sta	curDirHead +173,x
			dex
			bpl	:1

			jsr	xPutDirHead		;BAM auf Diskette speichern.
;			txa				;Diskettenfehler ?
;			bne	:exit			; => Ja, Abbruch...

::exit			rts
endif
