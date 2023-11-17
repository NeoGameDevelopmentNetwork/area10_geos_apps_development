; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = FD_NM
if :tmp0 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xGetDiskSize		jsr	Save_RegData

			jsr	InitForIO

			lda	#$7f			;Vorgabewert falls BAM
			sta	LastTrOnDsk		;ungültig ist.

			ldx	#$01			;BAM-Sektor $01/$02 einlesen.
			stx	r1L			;Dieser Sektor beinhaltet in
			inx				;Byte #8 die max. Track-Anzahl.
			stx	r1H
			LoadW	r4 ,dir3Head
			jsr	xReadBlock		;Sektor einlesen.
			txa				;Disk-Fehler ?
			bne	:52			; => Ja, Abbruch...

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8		;Max. Anzahl an Tracks
			sta	LastTrOnDsk		;zwischenspeichern.

			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE		;BAM nicht gefunden.
::52			jsr	DoneWithIO
			jmp	Load_RegData
endif

;******************************************************************************
::tmp1 = HD_NM
if :tmp1 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xGetDiskSize		jsr	Save_RegData

			jsr	InitForIO

			lda	#$7f			;Vorgabewert falls BAM
			sta	LastTrOnDsk		;ungültig ist.

			ldx	#$01			;BAM-Sektor $01/$02 einlesen.
			stx	r1L			;Dieser Sektor beinhaltet in
			inx				;Byte #8 die max. Track-Anzahl.
			stx	r1H
			LoadW	r4 ,dir3Head
			jsr	xReadBlock		;Sektor einlesen.
			txa				;Disk-Fehler ?
			bne	:52			; => Ja, Abbruch...

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8		;Max. Anzahl an Tracks
			sta	LastTrOnDsk		;zwischenspeichern.

			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE		;BAM nicht gefunden.
::52			jsr	DoneWithIO
			jmp	Load_RegData
endif

;******************************************************************************
::tmp2 = HD_NM_PP
if :tmp2 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xGetDiskSize		jsr	Save_RegData

			jsr	InitForIO

			lda	#$7f			;Vorgabewert falls BAM
			sta	LastTrOnDsk		;ungültig ist.

			ldx	#$01			;BAM-Sektor $01/$02 einlesen.
			stx	r1L			;Dieser Sektor beinhaltet in
			inx				;Byte #8 die max. Track-Anzahl.
			stx	r1H
			LoadW	r4 ,dir3Head
			jsr	xReadBlock		;Sektor einlesen.
			txa				;Disk-Fehler ?
			bne	:52			; => Ja, Abbruch...

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8		;Max. Anzahl an Tracks
			sta	LastTrOnDsk		;zwischenspeichern.

			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE		;BAM nicht gefunden.
::52			jsr	DoneWithIO
			jsr	Load_dir3Head
			jmp	Load_RegData
endif

;******************************************************************************
::tmp3 = RL_NM
if :tmp3 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xGetDiskSize		jsr	Save_RegData

			lda	#$01			;Vorgabewert falls BAM
			sta	LastTrOnDsk		;ungültig ist.

			ldx	#$01			;BAM-Sektor $01/$02 einlesen.
			stx	r1L			;Dieser Sektor beinhaltet in
			inx				;Byte #8 die max. Track-Anzahl.
			stx	r1H
			LoadW	r4 ,dir3Head
			lda	RL_PartNr		;Partitionsgröße!
			sta	r3H
			jsr	xDsk_SekRead		;Sektor einlesen.
			txa				;Disk-Fehler ?
			bne	:52			; => Ja, Abbruch...

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8		;Max. Anzahl an Tracks
			sta	LastTrOnDsk		;zwischenspeichern.

			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE		;BAM nicht gefunden.
::52			jmp	Load_RegData
endif

;******************************************************************************
::tmp4 = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp4 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xGetDiskSize		jsr	Save_RegData

			lda	#$01			;Vorgabewert falls BAM
			sta	LastTrOnDsk		;ungültig ist.

			ldx	#$01			;BAM-Sektor $01/$02 einlesen.
			stx	r1L			;Dieser Sektor beinhaltet in
			inx				;Byte #8 die max. Track-Anzahl.
			stx	r1H
			LoadW	r4 ,dir3Head
			jsr	xDsk_SekRead		;Sektor einlesen.
			txa				;Disk-Fehler ?
			bne	:52			; => Ja, Abbruch...

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8		;Max. Anzahl an Tracks
			sta	LastTrOnDsk		;zwischenspeichern.

			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE		;BAM nicht gefunden.
::52			jmp	Load_RegData
endif

;******************************************************************************
::tmp5 = IEC_NM!S2I_NM
if :tmp5 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xGetDiskSize		jsr	Save_RegData

			lda	#$7f			;Vorgabewert falls BAM
			sta	LastTrOnDsk		;ungültig ist.

			ldx	#$01			;BAM-Sektor $01/$02 einlesen.
			stx	r1L			;Dieser Sektor beinhaltet in
			inx				;Byte #8 die max. Track-Anzahl.
			stx	r1H
			LoadW	r4 ,dir3Head
			jsr	xGetBlock		;Sektor einlesen.
			txa				;Disk-Fehler ?
			bne	:52			; => Ja, Abbruch...

			lda	#"H"
			cmp	dir3Head +2
			bne	:51
			eor	#%11111111
			cmp	dir3Head +3
			bne	:51

			lda	dir3Head +8		;Max. Anzahl an Tracks
			sta	LastTrOnDsk		;zwischenspeichern.

			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE		;BAM nicht gefunden.
::52			jmp	Load_RegData
endif
