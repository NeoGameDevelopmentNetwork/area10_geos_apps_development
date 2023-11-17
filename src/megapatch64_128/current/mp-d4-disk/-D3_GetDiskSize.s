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

			lda	#$7f
			sta	LastTrOnDsk

			ldx	#$01
			stx	r1L
			inx
			stx	r1H
			jsr	Set_Dir3Head
			jsr	xReadBlock
			txa
			bne	:52

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8
			sta	LastTrOnDsk		;zwischenspeichern.
			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb		;Gesamtspeicher in KBytes umrechnen.
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE
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

			lda	#$7f
			sta	LastTrOnDsk

			ldx	#$01
			stx	r1L
			inx
			stx	r1H
			jsr	Set_Dir3Head
			jsr	xReadBlock
			txa
			bne	:52

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8
			sta	LastTrOnDsk		;zwischenspeichern.
			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb		;Gesamtspeicher in KBytes umrechnen.
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE
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

			lda	#$7f
			sta	LastTrOnDsk

			ldx	#$01
			stx	r1L
			inx
			stx	r1H
			jsr	Set_Dir3Head
			jsr	xReadBlock
			txa
			bne	:52

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8
			sta	LastTrOnDsk		;zwischenspeichern.
			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb		;Gesamtspeicher in KBytes umrechnen.
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE
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

			ldx	#$01
			stx	LastTrOnDsk

;			ldx	#$01
			stx	r1L
			inx
			stx	r1H
			lda	RL_PartNr
			sta	r3H
			jsr	Set_Dir3Head
			jsr	xDsk_SekRead
			txa
			bne	:52

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8		;Letzten verfügbaren Track
			sta	LastTrOnDsk		;zwischenspeichern.

			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb		;Gesamtspeicher in KBytes umrechnen.
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE
::52			jmp	Load_RegData
endif

;******************************************************************************
::tmp4 = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp4 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xGetDiskSize		jsr	Save_RegData

			ldx	#$01
			stx	LastTrOnDsk

;			ldx	#$01
			stx	r1L
			inx
			stx	r1H
			jsr	Set_Dir3Head
			jsr	xDsk_SekRead
			txa
			bne	:52

			lda	dir3Head +2
			cmp	#$48
			bne	:51

			lda	dir3Head +8		;Letzten verfügbaren Track
			sta	LastTrOnDsk		;zwischenspeichern.

			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00
			stx	DiskSize_Lb

			lsr	DiskSize_Hb		;Gesamtspeicher in KBytes umrechnen.
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE
::52			jmp	Load_RegData
endif

;******************************************************************************
::tmp5 = IEC_NM!S2I_NM
if :tmp5 = TRUE
;******************************************************************************
;*** Diskette aktivieren.
:xGetDiskSize		jsr	Save_RegData

			lda	#$7f
			sta	LastTrOnDsk

			ldx	#$01
			stx	r1L
			inx
			stx	r1H
			jsr	Set_Dir3Head
			jsr	xGetBlock
			txa
			bne	:52

			lda	#"H"
			cmp	dir3Head +2
			bne	:51
			eor	#%11111111
			cmp	dir3Head +3
			bne	:51

			lda	dir3Head +8
			sta	LastTrOnDsk		;zwischenspeichern.
			sta	DiskSize_Hb		;Gesamtspeicher in KBytes berechnen.
;			ldx	#$00			;XReg ist bereits $00!
			stx	DiskSize_Lb

			lsr	DiskSize_Hb		;Gesamtspeicher in KBytes umrechnen.
			ror	DiskSize_Lb
			lsr	DiskSize_Hb
			ror	DiskSize_Lb

;			ldx	#NO_ERROR		;XReg ist bereits #NULL = NO_ERROR
			b $2c
::51			ldx	#HDR_NOT_THERE		;BAM nicht gefunden.
::52			jmp	Load_RegData
endif
