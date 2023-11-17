; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Konvertierungstabellen einlesen.
:LoadConvIndex		jsr	OpenSysDrive

			LoadW	r6,V173a0
			LoadB	r7L,SYSTEM
			LoadB	r7H,$01
			LoadW	r10,V173a1
			jsr	FindFTypes
			txa
			bne	:101

			lda	r7H
			beq	:102

			lda	#$05
::101			pha
			jsr	OpenUsrDrive
			pla
			tax
			rts

::102			jsr	PrepGetFile

			LoadB	r0L,%00000001
			LoadW	r6 ,V173a0
			LoadW	r7 ,FileNTab
			jsr	GetFile
			txa
			bne	:101

			ldy	#$0f
::103			lda	V173c0,y
			sta	FileNTab+00*16,y
			dey
			bpl	:103

			jsr	OpenUsrDrive
			ldx	#$00
			rts

;*** Auswahlmenü Konvertierungstabelle.
:GetCTabDOS		LoadW	V173b1,V173b2
			LoadB	r3L,1
			lda	#<FileNTab + 01 * 16
			ldx	#>FileNTab + 01 * 16
			ldy	#39
			jmp	GetConvTab

:GetCTabCBM		LoadW	V173b1,V173b3
			LoadB	r3L,41
			lda	#<FileNTab + 41 * 16
			ldx	#>FileNTab + 41 * 16
			ldy	#39
			jmp	GetConvTab

:GetCTabTXT		LoadW	V173b1,V173b4
			LoadB	r3L,1
			lda	#<FileNTab + 01 * 16
			ldx	#>FileNTab + 01 * 16
			ldy	#119
;			jmp	GetConvTab

:GetConvTab		sta	r0L
			stx	r0H
			sty	r3H

			LoadW	r1,FileNTab +16
			LoadW	r2,FilePTab + 1

			ldy	#$00
::101			lda	(r0L),y
			beq	:102
			sta	(r1L),y
			iny
			cpy	#$10
			bcc	:101

			ldy	#$00
			lda	r3L
			sta	(r2L),y

			AddVBW	16,r1
			IncWord	r2

::102			AddVBW	16,r0

			dec	r3H
			beq	:103

			inc	r3L
			CmpBI	r3L,120
			bcc	:101

::103			ldy	#$0f
			lda	#$00
::104			sta	(r1L),y
			dey
			bpl	:104

			AddVBW	16,r1
			CmpW	r1,DOS_Driver
			bcc	:103

;*** Tabelle wählen.
:SlctConvFile		lda	#<V173b0
			ldx	#>V173b0
			jsr	SelectBox

			lda	r13L
			beq	:101
			ldx	#$ff
			rts

::101			ldx	r13H
			lda	FilePTab,x
			cmp	#00
			beq	:103
			cmp	#40
			beq	:102
			cmp	#80
			bne	:103
::102			lda	#$00
::103			sta	r10L

			ldx	#$00
			rts

;*** Variablen.
:V173a0			s 17
:V173a1			b "GD_Convert  ",NULL

:V173b0			b $00
			b $00
			b $00
			b $10
			b $00
:V173b1			w V173b1
			w FileNTab

if Sprache = Deutsch
:V173b2			b PLAINTEXT
			b "Tabelle DOS > CBM",NULL
:V173b3			b PLAINTEXT
			b "Tabelle CBM > DOS",NULL
:V173b4			b PLAINTEXT
			b "Tabelle CBM > CBM",NULL

:V173c0			b "1:1 Übertragung ",NULL
endif

if Sprache = Englisch
:V173b2			b PLAINTEXT
			b "Format DOS > CBM",NULL
:V173b3			b PLAINTEXT
			b "Format CBM > DOS",NULL
:V173b4			b PLAINTEXT
			b "Format CBM > CBM",NULL

:V173c0			b "Convert 1:1     ",NULL
endif
