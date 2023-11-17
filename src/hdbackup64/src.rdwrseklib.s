; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Assembler library for reading and
; writing data from/to CMD-HD ram.
;
; 10 open 15,10,15: open 2,8,2,"name,p,w"
; 20 sys 49152 : rem read data from HD-ram/$4000 to C64/$C200
; 25 sys 49155 : rem write data from C64/$C200 to HD-ram/$4000
; 30 sys 49158 : rem read data from a file/channel #2
; 35 sys 49161 : rem write data to a file/channel #2
; 40 close 2:close 15
;
; Can be used for cbmHDscsi64 to improve writing the
; CMD-HD o.s. to the formmated disk image.
; Could also be used for HDBackup64 to read data
; from a CMD-HD into a image file on an SD2IEC.
;

if .p
			t	"TopSym"
			t	"TopSym.ROM"
			t	"TopMac"
:CMDHD_RAMADR		= $4000
:COMP_RAMBUF		= $c200
endif

			n	"RDWRSEKLIB"
			f	NOT_GEOS

			o	($c000 -2)

:loadAdr		w $c000

:callRdSek		jmp	doReadSek		;Read 512b to C64/$C200.
:callWrSek		jmp	doWriteSek		;Write 512b to HD-ram/$4000.
:callRdData		jmp	doReadData		;Read 512b from a file/channel #2.
:callWrData		jmp	doWriteData		;Write 512b to a file/channel #2.

;*** Read data from CMD-HD ram.
:doReadSek		lda	#<CMDHD_RAMADR
			sta	:rdAdr +0
			lda	#>CMDHD_RAMADR
			sta	:rdAdr +1

			lda	#<COMP_RAMBUF
			sta	:ramAdr +1
			lda	#>COMP_RAMBUF
			sta	:ramAdr +2

			lda	#0
::rdLoop		pha

			ldx	#15
			jsr	CKOUT

			ldy	#0
::1			lda	:com_MR,y
			jsr	BSOUT
			iny
			cpy	#:len_MR
			bcc	:1

			jsr	CLRCHN

			ldx	#15
			jsr	CHKIN

			ldy	#0
::2			jsr	GETIN
::ramAdr		sta	$ffff,y
			iny
			cpy	#32
			bcc	:2

			jsr	CLRCHN

			lda	:rdAdr +0
			clc
			adc	#32
			sta	:rdAdr +0
			bcc	:10
			inc	:rdAdr +1

::10			lda	:ramAdr +1
			clc
			adc	#32
			sta	:ramAdr +1
			bcc	:20
			inc	:ramAdr +2

::20			pla
			clc
			adc	#1
			cmp	#16
			bcc	:rdLoop

			rts

::com_MR		b "M-R"
::rdAdr			w $4000
			b $20
::end_MR
::len_MR		= (:end_MR - :com_MR)

;*** Write data to CMD-HD ram.
:doWriteSek		lda	#<CMDHD_RAMADR
			sta	:wrAdr +0
			lda	#>CMDHD_RAMADR
			sta	:wrAdr +1

			lda	#<COMP_RAMBUF
			sta	:ramAdr +1
			lda	#>COMP_RAMBUF
			sta	:ramAdr +2

			lda	#0
::wrLoop		pha

			ldx	#15
			jsr	CKOUT

			ldy	#0
::1			lda	:com_MW,y
			jsr	BSOUT
			iny
			cpy	#:len_MW
			bcc	:1

			ldy	#0
::2
::ramAdr		lda	$ffff,y
			jsr	BSOUT
			iny
			cpy	#32
			bcc	:2

			jsr	CLRCHN

			lda	:wrAdr +0
			clc
			adc	#32
			sta	:wrAdr +0
			bcc	:10
			inc	:wrAdr +1

::10			lda	:ramAdr +1
			clc
			adc	#32
			sta	:ramAdr +1
			bcc	:20
			inc	:ramAdr +2

::20			pla
			clc
			adc	#1
			cmp	#16
			bcc	:wrLoop

			rts

::com_MW		b "M-W"
::wrAdr			w $4000
			b $20
::end_MW
::len_MW		= (:end_MW - :com_MW)

;*** Read data from a file/channel #2
:doReadData		lda	#<COMP_RAMBUF
			sta	:ramAdr +1
			lda	#>COMP_RAMBUF
			sta	:ramAdr +2

			ldx	#2
			jsr	CHKIN

			ldx	#2
::1			txa
			pha

			ldy	#0
::2			jsr	GETIN
::ramAdr		sta	$ffff,y
			iny
			bne	:2

			inc	:ramAdr +2

			pla
			tax
			dex
			bne	:1

			jsr	CLRCHN

			rts

;*** Write data to a file/channel #2
:doWriteData		lda	#<COMP_RAMBUF
			sta	:ramAdr +1
			lda	#>COMP_RAMBUF
			sta	:ramAdr +2

			ldx	#2
			jsr	CKOUT

			ldx	#2
::1			txa
			pha

			ldy	#0
::2
::ramAdr		lda	$ffff,y
			jsr	BSOUT
			iny
			bne	:2

			inc	:ramAdr +2

			pla
			tax
			dex
			bne	:1

			jsr	CLRCHN

			rts
