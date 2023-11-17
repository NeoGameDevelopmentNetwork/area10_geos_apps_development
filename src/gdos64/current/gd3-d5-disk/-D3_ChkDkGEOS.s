; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp1a = FD_NM!HD_NM!HD_NM_PP!RL_NM!IEC_NM!S2I_NM
::tmp1b = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp1  = :tmp1a!:tmp1b
if :tmp1 = TRUE
;******************************************************************************
;*** NativeMode: Auf GEOS-Diskette testen.
:ChkRootGEOS		lda	#1			;Tr/Se für ROOT-Verzeichnisheader.
			sta	r1L
			sta	r1H

;			LoadW	r4,curDirHead		;Zeiger auf aktuelle BAM.
			jsr	curDirHead_r4		;Zeiger auf aktuelle BAM.
			jsr	xGetBlock		;Verzeichnisheader einlesen.
			txa				;Diskettenfehler ?
			bne	notGEOS			; => Ja, Abbruch...

			ldy	curDirHead +171		;Evtl. Adresse eines Borderblock
			sty	BorderB_Tr		;für Unterverzeichnisse sichern.
			ldy	curDirHead +172
			sty	BorderB_Se
endif

;******************************************************************************
::tmp2 = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp2!TEST_RAMNM_SHARED = TRUE!SHAREDDIR_ENABLED
;******************************************************************************
;			ldx	#$00
;			txa
			tay				;Zeiger Shared/Dir in X/Y löschen.

			lda	curDirHead +218		;"2"
			eor	curDirHead +219		;"."
			eor	curDirHead +220		;"0"
			cmp	#$2c			;"Shared/Dir" vorhanden?
			bne	:1			; => Nein, weiter...

			ldx	curDirHead +203		;Evtl. Adresse eines Shared/Dir
			ldy	curDirHead +204		;für Unterverzeichnisse sichern.

::1			stx	SharedD_Tr		;Adresse Shared/Dir speichern.
			sty	SharedD_Se

;*** Auf GEOS-Diskette in ":curDirHead" testen.
:ChkDkGEOS_r5		jsr	curDirHead_r5		;Zeiger auf aktuelle BAM.

;*** Auf GEOS-Diskette in ":r5" testen.
:xChkDkGEOS		lda	SharedD_Tr		;Shared/Dir vorhanden?
			bne	diskGEOS		; => Ja, GEOS-Diskette.
endif

;******************************************************************************
::tmp3 = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp3!TEST_RAMNM_SHARED = TRUE!SHAREDDIR_DISABLED
;******************************************************************************
;*** Auf GEOS-Diskette in ":curDirHead" testen.
:ChkDkGEOS_r5		jsr	curDirHead_r5		;Zeiger auf aktuelle BAM.

;*** Auf GEOS-Diskette in ":r5" testen.
:xChkDkGEOS
endif

;******************************************************************************
::tmp4a = C_41!C_71!C_81!RD_41!RD_71!RD_81
::tmp4b = RL_41!RL_71!RL_81!FD_41!FD_71!FD_81
::tmp4c = HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP
::tmp4d = FD_NM!HD_NM!HD_NM_PP!RL_NM!IEC_NM!S2I_NM
::tmp4  = :tmp4a!:tmp4b!:tmp4c!:tmp4d
if :tmp4 = TRUE
;******************************************************************************
;*** Auf GEOS-Diskette in ":curDirHead" testen.
:ChkDkGEOS_r5		jsr	curDirHead_r5		;Zeiger auf aktuelle BAM.

;*** Auf GEOS-Diskette in ":r5" testen.
:xChkDkGEOS
endif

;******************************************************************************
::tmp9a = C_41!C_71!C_81!RD_41!RD_71!RD_81
::tmp9b = RL_41!RL_71!RL_81!FD_41!FD_71!FD_81
::tmp9c = HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP
::tmp9d = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp9e = FD_NM!HD_NM!HD_NM_PP!RL_NM!IEC_NM!S2I_NM
::tmp9  = :tmp9a!:tmp9b!:tmp9c!:tmp9d!:tmp9e
if :tmp9 = TRUE
;******************************************************************************
;*** GEOS-Formatstring testen.
;Übergabe: r5 = Zeiger auf aktuelle BAM.
;               Hinweis: ":curDirHead" nicht direkt verwenden!
;Rückgabe: A  = $00, Keine GEOS-Diskette.
;Geändert: A,X,Y
::testFrmtGEOS		ldy	#173
::1			lda	(r5L),y			;":r5" an Stelle von ":curDirHead"!
			cmp	GEOS_FormatInfo -173,y
			bne	notGEOS			; => Keine GEOS-Diskette, weiter...
			iny				;Zeiger auf nächstes Zeichen.
			cpy	#173 +12		;Max. 12 Zeichen verglichen?
			bcc	:1			; => Nein, weiter...

;--- Änderung: 01.07.18/M.Kanet
;Die ursprüngliche Routine übergab den Status-Code für ":isGEOS" im A-Register
;und wurde ggf. über den BIT/b $2c-Befehl übersprungen. Der BIT-Befehl kann
;jedoch das Z-Flag beeinflussen, so das eine GEOS-Diskette in seltenen Fällen
;als eine "Nicht GEOS"-Diskette erkannt werden konnte.
;Siehe auch Routine "GetBorderBlock".
:diskGEOS		ldy	#$ff
			b $2c				;BIT verändert ggf. das Z-Flag!
:notGEOS		ldy	#$00
			tya				;Z-Flag setzen.
			sta	isGEOS			;Flag GEOS-Diskette setzen.
			rts
endif
