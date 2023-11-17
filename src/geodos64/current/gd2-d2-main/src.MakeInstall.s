; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
			t "TopMac"
endif

			o PRINTBASE
			p InstallFile
			f APPLICATION
			n "MakeInstall"
			a "M. Kanet"
			c "MakeInstall V1.0"
			i
<MISSING_IMAGE_DATA>
			z $40
			h "Erstellt eine AutoStart-Datei um die aktuelle Desktop- Oberfläche automatisch zu starten..."

:StartInitFile

:MainInit		ldy	#$00
			bit	c128Flag
			bpl	:101
			ldy	#$06
::101			ldx	#$00
::102			lda	V001a0,y
			sta	r0L,x
			lda	V001a1,y
			sta	r3L,x
			iny
			inx
			cpx	#$06
			bne	:102

			ldx	#r3L
			ldy	#r0L
			jsr	CopyString

			ldx	#r4L
			ldy	#r1L
			jsr	CopyString

			ldx	#r5L
			ldy	#r2L
			jsr	CopyString

			lda	#$08
			jsr	SetDevice
			jmp	EnterDeskTop

;*** Text für DeskTop-Name.
:V001a0			w $c3cf,$c3d9,$c3f6
			w $c9bb,$c9c8,$c9e0

:V001a1			w V001b0,V001b1,V001b2
			w V001c0,V001c1,V001c2

:V001b0			s $10
:V001b1			s $20
:V001b2			s $20

:V001c0			s $10
:V001c1			s $20
:V001c2			s $20

:EndInitFile		brk

;*** InstallFile erzeugen.
:InstallFile		ldy	#$00
			bit	c128Flag
			bpl	:101
			ldy	#$06
::101			ldx	#$00
::102			lda	V001a0,y
			sta	r0L,x
			lda	V001a1,y
			sta	r3L,x
			iny
			inx
			cpx	#$06
			bne	:102

			ldx	#r0L
			ldy	#r3L
			jsr	CopyString

			ldx	#r1L
			ldy	#r4L
			jsr	CopyString

			ldx	#r2L
			ldy	#r5L
			jsr	CopyString

			lda	#<Boot64
			ldx	#>Boot64
			bit	c128Flag
			bpl	:103
			lda	#<Boot128
			ldx	#>Boot128

::103			sta	r6L
			stx	r6H

			ldy	#$00
			ldx	#$00
::104			lda	(r6L),y
			beq	:105
			sta	FileName,x
			iny
			inx
			bne	:104

::105			ldy	#$00
::106			lda	(r0L),y
			sta	FileName,x
			beq	:107
			iny
			inx
			bne	:106

::107			lda	#NULL
			sta	FileName+16

			LoadW	r0,FileName
			jsr	DeleteFile

			LoadW	r9,HdrB000
			LoadB	r10L,$00
			jsr	SaveFile

			LoadW	r6,FileName
			jsr	FindFile

			lda	dirEntryBuf +19
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			ldx	#$a0
			ldy	#$00
::108			lda	HdrInfo1,y
			beq	:109
			sta	diskBlkBuf,x
			inx
			iny
			bne	:108

::109			ldy	#$00
::110			lda	FileName,y
			iny
			cmp	#"/"
			bne	:110
::111			lda	FileName,y
			beq	:112
			sta	diskBlkBuf,x
			inx
			iny
			bne	:111

::112			ldy	#$00
::113			lda	HdrInfo2,y
			sta	diskBlkBuf,x
			beq	:114
			inx
			iny
			bne	:113

::114			jsr	PutBlock

			jmp	EnterDeskTop

;*** Info-Block.
:HdrB000		w FileName
			b $03,$15
			j
<MISSING_IMAGE_DATA>
			b $83
			b AUTO_EXEC
			b SEQUENTIAL
			w StartInitFile
			w EndInitFile
			w MainInit
			b "InstallDT   V"		;Klasse.
			b "1.0",NULL			;Version.
			s $02				;Reserviert.
			b $40				;40/80-Zeichen.
			b "MakeInstall"			;Autor.
:HdrEnd			s (HdrB000+256)-HdrEnd

:HdrInfo1		b "Startet ",NULL
:HdrInfo2		b " als",CR
			b "neue DeskTop-Oberfläche...",NULL

:Boot64			b "GO64/",NULL
:Boot128		b "GO128/",NULL
:FileName		s $11
