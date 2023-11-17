; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;"TurboDOS nicht aktiv".
			beq	:exit

			txa
			pha

			lda	turboFlags -8,y
			and	#%10111111		;"TurboDOS nicht aktiv".
			sta	turboFlags -8,y

			jsr	InitForIO		;I/O aktivieren.
			jsr	closeLISTEN		;Befehlskanal schließen.
			jsr	DoneWithIO		;I/O deaktivieren.

			pla
			tax

::exit			rts
endif

;******************************************************************************
::tmp1 = C_71!FD_41!FD_71!HD_41!HD_71
if :tmp1!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%01000000		;"TurboDOS nicht aktiv".
			beq	:exit

			txa
			pha

			lda	turboFlags -8,y
			and	#%10111111		;"TurboDOS nicht aktiv".
			sta	turboFlags -8,y

			jsr	InitForIO		;I/O aktivieren.
			jsr	closeLISTEN		;Befehlskanal schließen.
			jsr	DoneWithIO		;I/O deaktivieren.

			pla
			tax

::exit			rts
endif

;******************************************************************************
::tmp2 = C_81
if :tmp2!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y		;Diskette geöffnet?
			and	#%01000000
			beq	:exit			; => Nein, weiter...

			txa
			pha

			lda	turboFlags -8,y
			and	#%10111111		;"TurboDOS nicht aktiv".
			sta	turboFlags -8,y

			jsr	InitForIO		;I/O aktivieren.
			jsr	closeLISTEN		;Befehlskanal schließen.
			jsr	DoneWithIO		;I/O deaktivieren.

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::exit			rts
endif

;******************************************************************************
::tmp3 = FD_81!HD_81
if :tmp3!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y		;Diskette geöffnet?
			and	#%01000000
			beq	:51			; => Nein, weiter...

			txa
			pha

			lda	turboFlags -8,y
			and	#%10111111		;"TurboDOS nicht aktiv".
			sta	turboFlags -8,y

			jsr	InitForIO		;I/O aktivieren.
			jsr	closeLISTEN		;Befehlskanal schließen.
			jsr	DoneWithIO		;I/O deaktivieren.

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp4 = FD_NM!HD_NM
if :tmp4!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    ACHTUNG! Hier muß unbedingt auch der aktuelle Treiber zurück in die REU
;    kopiert werden, da einige Variablen/Speicherbereiche geändert wurden.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xExitTurbo		lda	#$08			;Sektor-Interleave auf
			sta	interleave		;Vorgabewert zurücksetzen.

			ldy	curDrive
			lda	turboFlags -8,y		;Diskette geöffnet ?
			and	#%01000000
			beq	:51			; => Nein, weiter...

			txa
			pha

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;"TurboDOS nicht aktiv".
			sta	turboFlags -8,y

			jsr	InitForIO		;I/O aktivieren.
			jsr	closeLISTEN		;Befehlskanal schließen.
			jsr	DoneWithIO		;I/O deaktivieren.

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif

;******************************************************************************
::tmp5 = IEC_NM!S2I_NM
if :tmp5!TDOS_MODE = TRUE!TDOS_DISABLED
;******************************************************************************
;*** TurboDOS deaktivieren.
;    ACHTUNG! Hier muß unbedingt auch der aktuelle Treiber zurück in die REU
;    kopiert werden, da einige Variablen/Speicherbereiche geändert wurden.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:xExitTurbo		ldy	curDrive
			lda	turboFlags -8,y		;Diskette geöffnet ?
			and	#%01000000
			beq	:51			; => Nein, weiter...

			txa
			pha

			jsr	xPutBAMBlock		;BAM auf Diskette aktualisieren.
							;(KEINE FEHLERABFRAGE!!!)

			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM

			ldy	curDrive
			lda	turboFlags -8,y
			and	#%10111111		;"TurboDOS nicht aktiv".
			sta	turboFlags -8,y

			jsr	InitForIO		;I/O aktivieren.
			jsr	closeLISTEN		;Befehlskanal schließen.
			jsr	DoneWithIO		;I/O deaktivieren.

			jsr	StashDriverData		;Variablen sichern.

			pla
			tax

::51			rts
endif
