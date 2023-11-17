; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0  = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Neuen Verzeichnis-Sektor erstellen.
;    Übergabe:		r1 = Aktueller Verzeichnis-Track/Sektor.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r3,r4,r7,r8H
:xCreateNewDirBlk	PushW	r6			;Register ":r6" zwischenspeichern.

			lda	r1H			;Aktuellen Verzeichnis-Sektor als
			sta	r3H			;Startwert für Suche nach freien
			lda	r1L			;Verzeichnis-Sektor setzen.
			sta	r3L
			jsr	SetNextFreeAll		;Freien Sektor suchen.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

			lda	r3H			;Freien Sektor als LinkBytes in
			sta	diskBlkBuf +$01		;aktuellem Verzeichnis-Sektor
			lda	r3L			;eintragen.
			sta	diskBlkBuf +$00
			jsr	xPutBlock_dskBuf	;Sektor auf Diskette speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

;			MoveB	r3L,r1L			;Wird durch ":clrDiskBlk_r3"
;			MoveB	r3H,r1H			;kopiert.
			jsr	clrDiskBlk_r3		;Verzeichnis-Sektor löschen.

::51			PopW	r6			;Register ":r6" zurücksetzen.
::52			rts
endif

;******************************************************************************
::tmp1b = C_41!C_71!C_81!FD_41!FD_71!FD_81!HD_41!HD_71!HD_81
::tmp1a = RL_41!RL_71!RL_81!RD_41!RD_71!RD_81
::tmp1c = HD_41_PP!HD_71_PP!HD_81_PP
::tmp1  = :tmp1a!:tmp1b!:tmp1c
if :tmp1 = TRUE
;******************************************************************************
;*** Neuen Verzeichnis-Sektor erstellen.
;    Übergabe:		r1 = Aktueller Verzeichnis-Track/Sektor.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r3,r4,r7,r8H
:xCreateNewDirBlk	jsr	IsDirSekFree		;Freien Verzeichnis-Sektor suchen.
			txa				;Ist Sektor frei ?
			bne	:52			; => Abbruch wenn kein Sektor frei.

			PushW	r6			;Register ":r6" zwischenspeichern.

			lda	r1H			;Aktuellen Verzeichnis-Sektor als
			sta	r3H			;Startwert für Suche nach freien
			lda	r1L			;Verzeichnis-Sektor setzen.
			sta	r3L
			jsr	xSetNextFree		;Freien Sektor suchen.

			lda	r3H			;Freien Sektor als LinkBytes in
			sta	diskBlkBuf +$01		;aktuellem Verzeichnis-Sektor
			lda	r3L			;eintragen.
			sta	diskBlkBuf +$00
			jsr	xPutBlock_dskBuf	;Sektor auf Diskette speichern.
			txa				;Diskettenfehler ?
			bne	:51			;Ja, Abbruch...

;			MoveB	r3L,r1L			;Wird durch ":clrDiskBlk_r3"
;			MoveB	r3H,r1H			;kopiert.
			jsr	clrDiskBlk_r3		;Verzeichnis-Sektor löschen.

::51			PopW	r6			;Register ":r6" zurücksetzen.
::52			rts
endif
