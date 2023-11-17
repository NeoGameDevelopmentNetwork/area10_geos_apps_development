; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_71
if :tmp0 = TRUE
;******************************************************************************
;*** BAM von Diskette laden/auf Diskette schreiben.
;    Übergabe:		AKKU/XReg: Zeiger auf xReadBlock/xWriteBlock
;    Rückgabe:		xReg     : Fehler
;    Geändert:		AKKU,xReg,yReg,r1,r4
:doDirHeadJob		sta	:job1 +1
			stx	:job1 +2
			sta	:job2 +1
			stx	:job2 +2

			jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	:52			; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor #1.
::job1			jsr	$ffff			;BAM-Sektor lesen/schreiben.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			ldy	curDrive
			lda	curDirHead +3		;Diskettenmodus einlesen.
			sta	doubleSideFlg-8,y	;1541-Diskette ?
			bpl	:51			; => Ja, Ende...

			jsr	SetBAM_TrSe2		;Zeiger auf BAM-Sektor #2.
::job2			jsr	$ffff			;BAM-Sektor lesen/schreiben.
::51			jsr	DoneWithIO		;I/O-Bereich ausblenden und Ende...
::52			rts
endif

;******************************************************************************
::tmp1 = FD_71!HD_71!HD_71_PP
if :tmp1 = TRUE
;******************************************************************************
;*** BAM von Diskette laden/auf Diskette schreiben.
;    Übergabe:		AKKU/XReg: Zeiger auf xReadBlock/xWriteBlock
;    Rückgabe:		xReg     : Fehler
;    Geändert:		AKKU,xReg,yReg,r1,r4
:doDirHeadJob		sta	:job1 +1
			stx	:job1 +2
			sta	:job2 +1
			stx	:job2 +2

			jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	:52			; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor #1.
::job1			jsr	$ffff			;BAM-Sektor lesen/schreiben.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			ldy	curDrive
;			lda	curDirHead +3		;Diskettenmodus einlesen.
			lda	#%10000000
			sta	doubleSideFlg-8,y	;FD71/HD71 immer doppelseitig!
;			bpl	:51			; => SingleSided, weiter...

			jsr	SetBAM_TrSe2		;Zeiger auf BAM-Sektor #2.
::job2			jsr	$ffff			;BAM-Sektor lesen/schreiben.
::51			jsr	DoneWithIO		;I/O-Bereich ausblenden und Ende...
::52			rts
endif

;******************************************************************************
::tmp2 = C_81!FD_81!HD_81!HD_81_PP
if :tmp2 = TRUE
;******************************************************************************
;*** BAM von Diskette laden/auf Diskette schreiben.
;    Übergabe:		AKKU/XReg: Zeiger auf xReadBlock/xWriteBlock
;    Rückgabe:		xReg     : Fehler
;    Geändert:		AKKU,xReg,yReg,r1,r4
:doDirHeadJob		sta	:job1 +1
			stx	:job1 +2
			sta	:job2 +1
			stx	:job2 +2
			sta	:job3 +1
			stx	:job3 +2

			jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	:52			; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor #1.
::job1			jsr	$ffff			;BAM-Sektor lesen/schreiben.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	SetBAM_TrSe2		;Zeiger auf BAM-Sektor #2.
::job2			jsr	$ffff			;BAM-Sektor lesen/schreiben.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			jsr	SetBAM_TrSe3		;Zeiger auf BAM-Sektor #2.
::job3			jsr	$ffff			;BAM-Sektor lesen/schreiben.
::51			jsr	DoneWithIO		;I/O-Bereich ausblenden und Ende...
::52			rts
endif
