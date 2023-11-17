; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dateien einlesen
:CBM_GetFiles		ldy	#27
			lda	Action_Drv
			add	$39
			sta	(r14L),y
			MoveW	r14,V502d0
			MoveW	r10,V502d1

			lda	Action_Drv		;Ziel-Laufwerk aktivieren.
			jsr	NewDrive

			lda	curDrive		;Diskette einlegen.
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01
			beq	GotoTopDir
			lda	#$ff
			rts

;*** Zeiger auf ersten Datei-Eintrag.
:GotoTopDir		jsr	GetDirHead
			txa
			beq	:1
			jmp	DiskError

::1			lda	curDirHead+0
			sta	V502a0    +0
			sta	V502a1    +0
			lda	curDirHead+1
			sta	V502a0    +1
			sta	V502a1    +1
			lda	#$00
			sta	V502a2
			sta	V502a3

;*** Dateien einlesen..
:ReadDirEntry		jsr	ReadFiles		;Dateien einlesen.
			lda	V502b0			;Dateien gefunden ?
			bne	ShowFiles		;Ja, anzeigen.
			bit	V502a3
			bvs	GotoTopDir

;*** Keine Dateien auf Diskette.
:NoCBMfiles		LoadW	r0,V502c0		;Keine Files.
			ClrDlgBoxCSet_Grau
			lda	#$ff
			rts

;*** Datei-Auswahl-Box.
:ShowFiles		MoveB	r1L,V502a1+0
			MoveB	r1H,V502a1+1

			lda	V502a3
			ora	#%01000000
			sta	V502a3

			MoveW	V502d0,r14
			MoveW	V502d1,r15
			lda	#$ff
			ldx	#$10
			ldy	#$00
			jsr	DoScrTab

			ldy	sysDBData
			cpy	#$01
			beq	:2
::1			lda	#$ff
			rts

::2			cpx	#$00
			bne	:4
			bit	V502a3
			bpl	:3
			jmp	GotoTopDir
::3			jmp	ReadDirEntry

::4			lda	#$00
			rts

;*** max. 255 Dateien einlesen.
:ReadFiles		jsr	DoInfoBox
			PrintStrgV502e0

			MoveB	V502a1+0,r1L
			MoveB	V502a1+1,r1H
			MoveW	V502d1  ,r15
			ClrB	V502b0

::1			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			beq	:8
::2			jmp	DiskError

::3			lda	V502a2
			inc	V502a2
			asl
			asl
			asl
			asl
			asl
			tax
			lda	diskBlkBuf+2,x
			beq	:8

;*** Dateien einlesen.
			ldy	#$00
::4			lda	diskBlkBuf+5,x
			cmp	#$20
			bcc	:6
			cmp	#$a0
			bne	:5
			lda	#$00
			beq	:7
::5			cmp	#$7f
			bcc	:7
			sbc	#$20
			bcs	:5
::6			lda	#$20
::7			sta	(r15L),y
			iny
			inx
			cpy	#$10
			bne	:4

			AddVBW	16,r15
			inc	V502b0
			lda	V502b0
			cmp	#$ff
			beq	:10

::8			lda	V502a2
			cmp	#$08
			bne	:3

			lda	#$00
			sta	V502a2
			lda	diskBlkBuf+0
			beq	:9
			sta	r1L
			lda	diskBlkBuf+1
			sta	r1H
			jmp	:1

::9			lda	V502a3
			ora	#%10000000
			sta	V502a3

::10			ldy	#$00
			tya
			sta	(r15L),y

			jsr	ClrBox
			rts

;*** Variablen.
:V502a0			b $00,$00			;Erster Directory Sektor.
:V502a1			b $00,$00			;Aktueller Directory-Sektor.
:V502a2			b $00				;Zeiger auf Eintrag.
:V502a3			b $00				;$FF = Directory-Ende.

:V502b0			b $00				;Anzahl Dateien.

;*** Fehler: "Keine Dateien auf Disk!"
:V502c0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  ,DBoxLeft,DBoxBase1
			w V502c1
			b DBTXTSTR  ,DBoxLeft,DBoxBase2
			w V502c2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V502c1			b PLAINTEXT,BOLDON
			b "Keine Dateien auf",NULL
:V502c2			b "Diskette !",PLAINTEXT,NULL

:V502d0			w $0000
:V502d1			w $0000

:V502e0			b PLAINTEXT,BOLDON
			b GOTOXY
			w IBoxLeft
			b IBoxBase1
			b "Dateien werden"
			b GOTOXY
			w IBoxLeft
			b IBoxBase2
			b "eingelesen..."
			b NULL
