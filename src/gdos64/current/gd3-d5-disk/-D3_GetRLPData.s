; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = RL_41!RL_71!RL_81!RL_NM
if :tmp0 = TRUE
;******************************************************************************
;*** Partitions-Informationen einlesen.
:getRLPartList		jsr	xExitTurbo		;TurboDOS abschalten.
			jsr	InitForIO		;I/O-Bereich einblenden.

			jsr	Save_RegData		;Register ":r0" bis ":r5" speichern.
endif

;******************************************************************************
::tmp1 = RL_81
if :tmp1 = TRUE
;******************************************************************************
			jsr	Save_dir3Head		;BAM-Sektor #3 zwischenspeichern.
endif

;******************************************************************************
::tmp2 = RL_41!RL_71!RL_81!RL_NM
if :tmp2 = TRUE
;******************************************************************************
			lda	#0			;Partitionszähler zurücksetzen.
			sta	r3L
			jsr	getRLPartSek		;Ersten Sektor einlesen.

::loop			ldy	#0
::1			ldx	r3L
			lda	dir3Head  + 2,y		;Partitionstyp einlesen, nach GEOS
			jsr	DefPTypeGEOS		;wandeln und zwischenspeichern.
			sta	RL_PartTYPE  ,x

			lda	dir3Head  +22,y		;Partitionsadresse einlesen und
			sta	RL_PartADDR_H,x		;zwischenspeichern.
			lda	dir3Head  +23,y
			sta	RL_PartADDR_L,x

			inc	r3L

			tya				;Zeiger auf nächsten Eintrag.
			clc
			adc	#32
			tay				;Alle Einträge ausgelesen?
			bne	:1			; => Nein, weiter...

			inc	r1H
			lda	r1H
			cmp	#4			;Alle Sektoren getestet?
			bcs	:done			; => Ja, Ende...

			jsr	xDsk_SekRead		;Nächsten Sektor einlesen.
			jmp	:loop			; => Weiter...

::done
endif

;******************************************************************************
::tmp3 = RL_81
if :tmp3 = TRUE
;******************************************************************************
			jsr	Load_dir3Head		;BAM-Sektor #3 wieder einlesen.
endif

;******************************************************************************
::tmp4 = RL_41!RL_71!RL_81!RL_NM
if :tmp4 = TRUE
;******************************************************************************
			jsr	Load_RegData		;Register ":r0" bis ":r5" laden.

			jmp	DoneWithIO		;I/O-Bereich ausblenden.

;*** Sektor aus RL-Systembereich lesen.
;Übergabe: AKKU = Sektor_Adresse.
:getRLPartSek		ldx	#1			;Partitionsliste.
			b $2c
:getRLSysData		ldx	#0			;Systembereich.
			stx	r1L
			sta	r1H
			LoadB	r3H,255			;Systempartition.
			jsr	dir3Head_r4		;Zeiger auf Zwischenspeicher.
			jmp	xDsk_SekRead		;Verzeichnis-Sektor einlesen.
endif
