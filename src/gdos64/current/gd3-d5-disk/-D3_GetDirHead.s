; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp0a!TEST_RAMNM_SHARED = TRUE!SHAREDDIR_DISABLED
;******************************************************************************
;*** BAM von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetDirHead		jsr	Set_DirHead		;Zeiger auf BAM setzen.
			jsr	xReadBlock		;Verzeichnis-Header einlesen.
			txa				;Diskettenfehler?
			bne	:51			; => Ja, Abbruch...

;			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM
			lda	#$02			;Ersten BAM-Sektor von Diskette
			jsr	xGetBAMBlock		;einlesen.
;			txa				;Diskettenfehler?
;			bne	:51			; => Ja, Abbruch...

;--- Hinweis:
;Immer die Adresse des Borderblock in
;der aktuellen BAM ablegen, auch wenn
;in einem Unterverzeichnis keine GEOS-
;Kennung enthalten ist.
;":OpenDisk" prüft den ROOT-BAM-Block
;auf eine GEOS-Kennung und setzt dann
;das Flag ":isGEOS".
;Anwendungen können bei gesetztem Flag
;":isGEOS" die Adresse des Borderblock
;direkt aus der BAM einlesen, auch bei
;einem geöffneten Unterverzeichnis.
;Rückgabe Adresse Borderblock in A/Y
;für Routine ":xGetBorderBlock"!
			lda	BorderB_Tr		;Evtl. Adresse eines Borderblock
			sta	curDirHead +171		;für Unterverzeichnis übernehmen.
			ldy	BorderB_Se
			sty	curDirHead +172

::51			rts
endif

;******************************************************************************
::tmp0b = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp0b!TEST_RAMNM_SHARED = TRUE!SHAREDDIR_ENABLED
;******************************************************************************
;*** BAM von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetDirHead		jsr	Set_DirHead		;Zeiger auf BAM setzen.
			jsr	xReadBlock		;Verzeichnis-Header einlesen.
			txa				;Diskettenfehler?
			bne	:51			; => Ja, Abbruch...

;			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM
			lda	#$02			;Ersten BAM-Sektor von Diskette
			jsr	xGetBAMBlock		;einlesen.
;			txa				;Diskettenfehler?
;			bne	:51			; => Ja, Abbruch...

			lda	SharedD_Tr		;Shared/Dir vorhanden?
			beq	:setBorder		; => Nein, weiter...

			lda	DirHead_Tr
			cmp	#Tr_1stDirSek
			bne	:50
			lda	DirHead_Se
			cmp	#Se_1stDirSek		;ROOT-Verzeichnis aktiv?
			beq	:setBorder		; => Ja, Shared/Dir ignorieren.

::50			ldy	SharedD_Se		;Shared/Dir-Verzeichnis aktiv?
			lda	SharedD_Tr
			cmp	curDirHead +0
			bne	:setDir
			cpy	curDirHead +1
			bne	:setDir			; => Nein, weiter...

;--- Hinweis:
;Immer die Adresse des Borderblock in
;der aktuellen BAM ablegen, auch wenn
;in einem Unterverzeichnis keine GEOS-
;Kennung enthalten ist.
;":OpenDisk" prüft den ROOT-BAM-Block
;auf eine GEOS-Kennung und setzt dann
;das Flag ":isGEOS".
;Anwendungen können bei gesetztem Flag
;":isGEOS" die Adresse des Borderblock
;direkt aus der BAM einlesen, auch bei
;einem geöffneten Unterverzeichnis.
;Rückgabe Adresse Borderblock in A/Y
;für Routine ":xGetBorderBlock"!
::setBorder		lda	BorderB_Tr		;Evtl. Adresse eines Borderblock
			ldy	BorderB_Se		;für Unterverzeichnis übernehmen.

::setDir		sta	curDirHead +171		;Borderblock/SharedDir setzen.
			sty	curDirHead +172

::51			rts
endif

;******************************************************************************
::tmp1 = RL_41!RD_41
if :tmp1 = TRUE
;******************************************************************************
;*** BAM von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetDirHead		jsr	SetBAM_TrSe		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xReadBlock		;BAM-Sektor einlesen.
			rts
endif

;******************************************************************************
::tmp2 = RL_71!RD_71
if :tmp2 = TRUE
;******************************************************************************
;*** BAM von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetDirHead		jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xReadBlock		;BAM-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...

			ldy	curDrive
;			lda	curDirHead +3		;Diskettenmodus einlesen.
			lda	#%10000000
			sta	doubleSideFlg-8,y	;RAM-Laufwerk immer doppelseitig!
;			bpl	:51			; => SingleSided, weiter...

			jsr	SetBAM_TrSe2		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xReadBlock		;BAM-Sektor lesen.
::51			rts
endif

;******************************************************************************
::tmp3 = RL_81!RD_81
if :tmp3 = TRUE
;******************************************************************************
;*** BAM von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetDirHead		jsr	SetBAM_TrSe1		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xReadBlock		;BAM-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			jsr	SetBAM_TrSe2		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xReadBlock		;BAM-Sektor lesen.
			txa				;Diskettenfehler ?
			bne	:51			; => Ja, Abbruch...
			jsr	SetBAM_TrSe3		;Zeiger auf BAM-Sektor/-Speicher.
			jsr	xReadBlock		;BAM-Sektor lesen.
::51			rts
endif

;******************************************************************************
::tmp4 = C_41!FD_41!HD_41!HD_41_PP
if :tmp4 = TRUE
;******************************************************************************
;*** BAM von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetDirHead		jsr	xEnterTurbo		;TurboDOS aktivieren.
;			txa				;Laufwerksfehler ?
			bne	:51			; => Ja, Abbruch...
			jsr	InitForIO		;I/O-Bereich einblenden.
			jsr	SetBAM_TrSe		;Zeiger auf Track/Sektor/Speicher.
			jsr	xReadBlock		;Sektor von Diskette lesen.
			jsr	DoneWithIO		;I/O-Bereich ausblenden.
::51			rts				;Ende...
endif

;******************************************************************************
::tmp5 = C_71!FD_71!HD_71!HD_71_PP!C_81!FD_81!HD_81!HD_81_PP
if :tmp5 = TRUE
;******************************************************************************
;*** BAM von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetDirHead		lda	#< xReadBlock
			ldx	#> xReadBlock
			jmp	doDirHeadJob		;BAM von Diskette einlesen.
endif

;******************************************************************************
::tmp8 = RL_NM!FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
if :tmp8 = TRUE
;******************************************************************************
;*** BAM von Diskette einlesen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4
:xGetDirHead		jsr	Set_DirHead		;Zeiger auf BAM setzen.
			jsr	xGetBlock		;Verzeichnis-Header einlesen.
			txa				;Diskettenfehler?
			bne	:51			; => Ja, Abbruch...

;			lda	#$00			;BAM-Sektor im Speicher löschen.
			sta	CurSek_BAM
			lda	#$02			;Ersten BAM-Sektor von Diskette
			jsr	xGetBAMBlock		;einlesen.
;			txa				;Diskettenfehler?
;			bne	:51			; => Ja, Abbruch...

;--- Hinweis:
;Immer die Adresse des Borderblock in
;der aktuellen BAM ablegen, auch wenn
;in einem Unterverzeichnis keine GEOS-
;Kennung enthalten ist.
;":OpenDisk" prüft den ROOT-BAM-Block
;auf eine GEOS-Kennung und setzt dann
;das Flag ":isGEOS".
;Anwendungen können bei gesetztem Flag
;":isGEOS" die Adresse des Borderblock
;direkt aus der BAM einlesen, auch bei
;einem geöffneten Unterverzeichnis.
;Rückgabe Adresse Borderblock in A/Y
;für Routine ":xGetBorderBlock"!
			lda	BorderB_Tr		;Evtl. Adresse eines Borderblock
			sta	curDirHead +171		;für Unterverzeichnis übernehmen.
			ldy	BorderB_Se
			sty	curDirHead +172

::51			rts
endif
