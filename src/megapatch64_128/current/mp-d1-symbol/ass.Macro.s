﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:OPEN_BOOT		m
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
			LoadW	a0,:END_BOOT
			rts
::END_BOOT
			/

:OPEN_SYMBOL		m
			b $f1
			lda	#DvAdr_Symbol
			bne	:1
;---
			bit	c128Flag
			bpl	:screen
			bit	graphMode
			bmi	:init
::screen		lda	screencolors
			sta	:color
			jsr	i_FillRam
			w	25*40
			w	COLOR_MATRIX
::color			b	$bf
			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10,$c7
			w	$0000,$013f
;---
::init			lda	a2L
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
::2			lda	DvDir_Symbol
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

:OPEN_KERNAL		m
			b $f1
			lda	#DvAdr_Kernal
			bne	:1
;---
			bit	c128Flag
			bpl	:screen
			bit	graphMode
			bmi	:init
::screen		lda	screencolors
			sta	:color
			jsr	i_FillRam
			w	25*40
			w	COLOR_MATRIX
::color			b	$bf
			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10,$c7
			w	$0000,$013f
;---
::init			lda	a2L
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
			lda	#DvPart_Kernal
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_Kernal
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_Kernal
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
			LoadW	a0,:END_KERNAL
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
::91			b "Diskette einlegen: Kernal",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_KERNAL		b $f2,DvAdr_Kernal
			/

:OPEN_SYSTEM		m
			b $f1
			lda	#DvAdr_System
			bne	:1
;---
			bit	c128Flag
			bpl	:screen
			bit	graphMode
			bmi	:init
::screen		lda	screencolors
			sta	:color
			jsr	i_FillRam
			w	25*40
			w	COLOR_MATRIX
::color			b	$bf
			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10,$c7
			w	$0000,$013f
;---
::init			lda	a2L
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
			lda	#DvPart_System
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_System
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_System
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
			LoadW	a0,:END_SYSTEM
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
::91			b "Diskette einlegen: System",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_SYSTEM		b $f2,DvAdr_System
			/

:OPEN_PROG		m
			b $f1
			lda	#DvAdr_Prog
			bne	:1
;---
			bit	c128Flag
			bpl	:screen
			bit	graphMode
			bmi	:init
::screen		lda	screencolors
			sta	:color
			jsr	i_FillRam
			w	25*40
			w	COLOR_MATRIX
::color			b	$bf
			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10,$c7
			w	$0000,$013f
;---
::init			lda	a2L
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
			lda	#DvPart_Prog
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_Prog
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_Prog
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
			LoadW	a0,:END_PROG
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
::91			b "Diskette einlegen: Programme",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_PROG		b $f2,DvAdr_Prog
			/

:OPEN_DISK		m
			b $f1
			lda	#DvAdr_Disk
			bne	:1
;---
			bit	c128Flag
			bpl	:screen
			bit	graphMode
			bmi	:init
::screen		lda	screencolors
			sta	:color
			jsr	i_FillRam
			w	25*40
			w	COLOR_MATRIX
::color			b	$bf
			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$10,$c7
			w	$0000,$013f
;---
::init			lda	a2L
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
			lda	#DvPart_Disk
			beq	:2
			sta	r3H
			jsr	OpenPartition
			jsr	OpenDisk
::2			lda	DvDir_Disk
			beq	:3
			jsr	OpenRootDir
			txa
			bne	:3
			LoadW	r6,DvDir_Disk
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
			LoadW	a0,:END_DISK
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
::91			b "Diskette einlegen: Disk",NULL
::92			b "Laufwerk: "
::93			b "X",NULL

::END_DISK		b $f2,DvAdr_Disk
			/
