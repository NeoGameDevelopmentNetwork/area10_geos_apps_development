; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:OPEN_TARGET		m
			b $f1
			lda	#DvAdr_Target
			beq	:2
			jsr	SetDevice
			jsr	OpenDisk
			lda	#DvPart_Target
			beq	:1
			sta	r3H
			jsr	OpenPartition
::1			jsr	OpenDisk
::2			lda	DvDir_Target
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_Target
			jsr	FindFile
			txa
			bne	:3
			lda	dirEntryBuf +0
			and	#%00000111
			cmp	#$06
			bne	:3
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir
::3			lda	a1L
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	a0,:END_TARGET
			rts
::END_TARGET
			/

:OPEN_SYMBOL		m
			b $f1
			lda	#DvAdr_Symbol
			bne	:1
			lda	a2L
			sec
			sbc	#8
			clc
			adc	#"A"
			sta	:93
			LoadW	r0,:90
			jsr	DoDlgBox
			jsr	MouseUp
::0			lda	mouseData
			bpl	:0
			LoadB	pressFlag,NULL
			jsr	MouseOff
			jmp	:2

::1			jsr	SetDevice
			lda	#DvPart_Symbol
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_Target
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_Symbol
			jsr	FindFile
			txa
			bne	:3
			lda	dirEntryBuf +0
			and	#%00000111
			cmp	#$06
			bne	:3
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir
::3			lda	a1L
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	a0,:END_SYMBOL
			rts

::90			b $01
			b $30
			b $72
			w $0040!DOUBLE_W
			w $00ff!DOUBLE_W!ADD1_W
			b DBTXTSTR,$10,$0e
			w :91
			b DBTXTSTR,$10,$1e
			w :92
			b OK,$02,$30
			b NULL
::91			b "Diskette einlegen: Symbol",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_SYMBOL		b $f2,DvAdr_Symbol
			/

:OPEN_MAIN		m
			b $f1
			lda	#DvAdr_Main
			bne	:1
			lda	a2L
			sec
			sbc	#8
			clc
			adc	#"A"
			sta	:93
			LoadW	r0,:90
			jsr	DoDlgBox
			jsr	MouseUp
::0			lda	mouseData
			bpl	:0
			LoadB	pressFlag,NULL
			jsr	MouseOff
			jmp	:2

::1			jsr	SetDevice
			lda	#DvPart_Main
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_Main
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_Main
			jsr	FindFile
			txa
			bne	:3
			lda	dirEntryBuf +0
			and	#%00000111
			cmp	#$06
			bne	:3
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir
::3			lda	a1L
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	a0,:END_MAIN
			rts

::90			b $01
			b $30
			b $72
			w $0040!DOUBLE_W
			w $00ff!DOUBLE_W!ADD1_W
			b DBTXTSTR,$10,$0e
			w :91
			b DBTXTSTR,$10,$1e
			w :92
			b OK,$02,$30
			b NULL
::91			b "Diskette einlegen: GD-MAIN",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_MAIN		b $f2,DvAdr_Main
			/

:OPEN_CONVERT		m
			b $f1
			lda	#DvAdr_Convert
			bne	:1
			lda	a2L
			sec
			sbc	#8
			clc
			adc	#"A"
			sta	:93
			LoadW	r0,:90
			jsr	DoDlgBox
			jsr	MouseUp
::0			lda	mouseData
			bpl	:0
			LoadB	pressFlag,NULL
			jsr	MouseOff
			jmp	:2

::1			jsr	SetDevice
			lda	#DvPart_Convert
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_Convert
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_Convert
			jsr	FindFile
			txa
			bne	:3
			lda	dirEntryBuf +0
			and	#%00000111
			cmp	#$06
			bne	:3
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir
::3			lda	a1L
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	a0,:END_CONVERT
			rts

::90			b $01
			b $30
			b $72
			w $0040!DOUBLE_W
			w $00ff!DOUBLE_W!ADD1_W
			b DBTXTSTR,$10,$0e
			w :91
			b DBTXTSTR,$10,$1e
			w :92
			b OK,$02,$30
			b NULL
::91			b "Diskette einlegen: GD-CONVERT",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_CONVERT		b $f2,DvAdr_Convert
			/

:OPEN_DOSCBM		m
			b $f1
			lda	#DvAdr_DosCbm
			bne	:1
			lda	a2L
			sec
			sbc	#8
			clc
			adc	#"A"
			sta	:93
			LoadW	r0,:90
			jsr	DoDlgBox
			jsr	MouseUp
::0			lda	mouseData
			bpl	:0
			LoadB	pressFlag,NULL
			jsr	MouseOff
			jmp	:2

::1			jsr	SetDevice
			lda	#DvPart_DosCbm
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_DosCbm
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_DosCbm
			jsr	FindFile
			txa
			bne	:3
			lda	dirEntryBuf +0
			and	#%00000111
			cmp	#$06
			bne	:3
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir
::3			lda	a1L
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	a0,:END_DOSCBM
			rts

::90			b $01
			b $30
			b $72
			w $0040!DOUBLE_W
			w $00ff!DOUBLE_W!ADD1_W
			b DBTXTSTR,$10,$0e
			w :91
			b DBTXTSTR,$10,$1e
			w :92
			b OK,$02,$30
			b NULL
::91			b "Diskette einlegen: GD-DOSCBM",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_DOSCBM		b $f2,DvAdr_DosCbm
			/

:OPEN_HELP		m
			b $f1
			lda	#DvAdr_Help
			bne	:1
			lda	a2L
			sec
			sbc	#8
			clc
			adc	#"A"
			sta	:93
			LoadW	r0,:90
			jsr	DoDlgBox
			jsr	MouseUp
::0			lda	mouseData
			bpl	:0
			LoadB	pressFlag,NULL
			jsr	MouseOff
			jmp	:2

::1			jsr	SetDevice
			lda	#DvPart_Help
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_Help
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_Help
			jsr	FindFile
			txa
			bne	:3
			lda	dirEntryBuf +0
			and	#%00000111
			cmp	#$06
			bne	:3
			lda	dirEntryBuf +1
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			jsr	OpenSubDir
::3			lda	a1L
			jsr	SetDevice
			jsr	OpenDisk
			LoadW	a0,:END_HELP
			rts

::90			b $01
			b $30
			b $72
			w $0040!DOUBLE_W
			w $00ff!DOUBLE_W!ADD1_W
			b DBTXTSTR,$10,$0e
			w :91
			b DBTXTSTR,$10,$1e
			w :92
			b OK,$02,$30
			b NULL
::91			b "Diskette einlegen: GD-HELP",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_HELP		b $f2,DvAdr_Help
			/
