; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp0b = RL_41!RL_71!RL_81!RL_NM!RD_41!RD_71!RD_81!RD_NM
::tmp0c = RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0d = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP!IEC_NM!S2I_NM
::tmp0  = :tmp0a!:tmp0b!:tmp0c!:tmp0d
if :tmp0 = TRUE
;******************************************************************************
;*** Freien Verzeichnis-Sektor suchen.
;    Übergabe:		r10L = Erste Seite für Suche nach freiem Eintrag.
;    Rückgabe:		r5	= Zeiger auf ":diskBlkBuf".
;			yReg	= Zeiger auf Verzeichnis-Eintrag.
;    Geändert:		AKKU,xReg,yReg,r1,r3,r4,r6,r7,r8H
:xGetFreeDirBlk		php				;IRQ-Status zwischenspeichern und
			sei				;IRQs sperren.

			PushB	r6L			;Register ":r6L" speichern.
			PushW	r2			;Register ":r2"  speichern.

			ldx	r10L			;Erste Verzeichnis-Seite
			inx				;festlegen.
			stx	r6L

			jsr	Set_1stDirSek		;Zeiger auf ersten Verzeichnis-
							;Sektor setzen.
::51			jsr	xGetBlock_dskBuf	;Sektor von Diskette lesen.
::52			txa				;Diskettenfehler ?
			bne	:57			;Ja, Abbruch...

			dec	r6L			;Verzeichnis-Seite erreicht ?
			beq	:55			;Ja, weiter...

::53			lda	diskBlkBuf +$00		;Nächster Sektor verfügbar ?
			bne	:54			;Ja, weiter...

			jsr	xCreateNewDirBlk
			jmp	:52

::54			sta	r1L			;Zeiger auf nächsten Sektor
			lda	diskBlkBuf +$01		;setzen und Sektor von Diskette
			sta	r1H			;einlesen.
			jmp	:51

::55			ldy	#$02			;Freien Verzeichnis-Eintrag
			ldx	#NO_ERROR		;innerhalb des Sektors suchen.
::56			lda	diskBlkBuf +$00,y	;Eintrag frei ?
			beq	:57			;Ja, weiter...
			tya
			clc
			adc	#$20			;Zeiger auf nächsten Eintrag.
			tay				;Alle Einträge geprüft ?
			bcc	:56			;Nein, weiter...

			lda	#$01			;Flag: "Nächsten Sektor suchen".
			sta	r6L

			ldy	r10L			;Zeiger auf nächste
			iny				;Verzeichnis-Seite setzen.
			sty	r10L
			cpy	#MaxDirPages		;37 Seiten/8 Dateien = 296 Einträge.
			bcc	:53

			ldx	#FULL_DIRECTORY

::57			PopW	r2			;Register ":r2"  zurücksetzen.
			PopB	r6L			;Register ":r6L" zurücksetzen.

			plp				;IRQ-Status zurücksetzen.
			rts
endif
