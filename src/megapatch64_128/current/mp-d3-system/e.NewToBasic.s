; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.NewToBasic"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o LD_ADDR_TOBASIC

if Flag64_128 = TRUE_C64
;*** Nach BASIC verlassen.
:xToBasic		ldy	#$27			;Befehlsstring auf gültige
::101			lda	(r0L),y			;Zeichen testen.
			cmp	#$41
			bcc	:102
			cmp	#$5b
			bcs	:102
			sbc	#$3f
::102			sta	BasicCommand,y		;Befehl in Zwischenspeicher.
			dey
			bpl	:101

			lda	r5H			;BASIC-File nachladen ?
			beq	:104			;Nein, weiter...

			iny
			tya
::103			sta	$0800,y
			iny
			bne	:103

			sec				;Ladeadresse BASIC-Datei -2.
			lda	r7L			;(Zeiger auf $07ff, dadurch
			sbc	#$02			; wird die Startadresse im
			sta	r7L			; ersten Sektor der Datei
			lda	r7H			; überlesen...)
			sbc	#$00
			sta	r7H

			lda	(r7L),y			;Inhalt der Adressen $07ff und
			pha				;$0800 sichern.
			iny
			lda	(r7L),y
			pha
			lda	r7H			;Ladeadresse merken.
			pha
			lda	r7L
			pha
			lda	(r5L),y			;Zeiger auf ersten Sektor der
			sta	r1L			;BASIC-Datei.
			iny
			lda	(r5L),y
			sta	r1H
			lda	#$ff
			sta	r2L
			sta	r2H
			jsr	ReadFile		;BASIC-Datei laden.
			pla				;ladeadresse zurück nach ":r0".
			sta	r0L
			pla
			sta	r0H

			ldy	#$01			;Inhalt der Adressen $07ff und
			pla				;$0800 wieder zurückschreiben.
			sta	(r0L),y
			dey
			pla
			sta	(r0L),y

::104			jsr	GetDirHead		;BAM einlesen.
			jsr	PurgeTurbo		;GEOS-Turbo abschalten.

			lda	sysRAMFlg
			sta	sysFlgCopy

			jsr	Copy_RAM_to_REU		;Kernal in REU aktualisieren.

;*** Nach BASIC verlassen.
:JumpToBasic		sei

			lda	#$36			;BASIC+Kernal einblenden.
			sta	CPU_DATA

			ldy	#$02
::101			lda	$0800,y			;BASIC-Daten
			sta	BasicBackData,y		;zwischenspeichern.
			dey
			bpl	:101

			lda	r7H			;Endadresse speichern.
			sta	EndBasicH
			lda	r7L
			sta	EndBasicL

			inc	CPU_DATA		;BASIC-ROM einblenden.

			ldx	#$ff			;Stackzeiger löschen.
			txs

			lda	#$00			;VIC initialisieren.
			sta	grcntrl2

			jsr	IOINIT			;":$FDA3" CIA-Register löschen.

;--- Ergänzung: 07.04.19/M.Kanet
;Reset-Routinen zusammengefasst.
			jsr	$fd50			;":RAMTAS" RAM-Reset
							;          Kasettenpuffer setzen.
							;          Bildschirm auf $0400.
			jsr	$fd15			;":RESTOR" Standard I/O-Vektoren.
			jsr	$ff5b			;":CINT"   Bildschirm-Editor-Reset.

			ldx	curDevice

			lda	#$00
			tay
::102			sta	$0002,y			;ZeroPage löschen.
			sta	$0200,y
			sta	$0300,y
			iny
			bne	:102

			stx	curDevice

			lda	#> $a000		;Ende BASIC-RAM.
			sta	MEMSIZ +1

			lda	#< TBUFFR		;Startadresse
			sta	TAPE1  +0		;Kassettenpuffer.
			lda	#> TBUFFR
			sta	TAPE1  +1

			lda	#> $0800		;Startadresse BASIC-RAM.
			sta	MEMSTR +1
			lsr
			sta	HIBASE			;Zeiger auf Bildschirmanfang.

			jsr	SetKernalVec		;Kernal-Vektoren setzen.
			jsr	CINT			;Bildschirm initialisieren.

			lda	#> NewNMI		;NMI-Routine setzen.
			sta	NMIINV +1
			lda	#< NewNMI
			sta	NMIINV +0

			lda	#$06			;Wartezeit nach Reset.
			sta	ResetTimer

			lda	$dd0d			;I/O zurücksetzen.
			lda	#$ff
			sta	$dd04
			sta	$dd05
			lda	#$81
			sta	$dd0d
			lda	#$81			;Bit #7 =1, 50Mhz-Uhr !!!
			sta	$dd0e

			jsr	SCPU_OptOff		;Keine Optimierung für GEOS.
			sta	$d07b			;Software-Speed 20Mhz.

;--- Ergänzung: 07.04.19/M.Kanet
;Kein CLI-Befehl unter GEOS V2.
;:L801B			cli				;IRQ freigeben.

			jmp	($a000)

;*** Neue NMI-Routine.
:NewNMI			pha
			tya
			pha

			lda	$dd0d

			dec	ResetTimer		;Timer abgelaufen ?
			bne	:104			;Nein, weiter...

			lda	#$7f
			sta	$dd0d

			lda	#> SystemReBoot		;SystemReBoot über NMI.
			sta	NMIINV +1		; (Druck auf RESTORE)
			lda	#< SystemReBoot
			sta	NMIINV +0

			ldy	#$02
::101			lda	BasicBackData,y
			sta	$0800,y
			dey
			bpl	:101

;--- Ergänzung: 08.04.19/M.Kanet
;Die End-Adresse muss auch nach EAL
;geschrieben werden, da sonst einige
;Programme nicht korrekt starten.
			lda	EndBasicH		;Endadresse BASIC-Programm.
			sta	VARTAB +1
			sta	EAL +1
			lda	EndBasicL
			sta	VARTAB +0
			sta	EAL +0

			iny
::102			lda	BasicCommand,y		;BASIC-Befehl
			beq	:103			;auf Bildschirm ausgeben.
			sta	($d1),y
			lda	#$0e			;Farb-RAM setzen.
			sta	$d8f0,y
			iny
			bne	:102

::103			tya				;Befehl ausführen ?
			beq	:104			;Nein, weiter...

;--- Ergänzung: 07.04.19/M.Kanet
;BASIC-Linkzeiger korrigieren.
			jsr	$a68e			;":STXTPT" CHRGET = Programmanfang.
			jsr	$a533			;":LNKPRG" Linkzeiger neu berechnen.

			lda	#$28			;Zeiger auf Cursor-Spalte.
			sta	PNTR

			lda	#$01			;Eine Taste im Puffer.
			sta	NDX

			lda	#$0d			;<RETURN> in Tastaturpuffer.
			sta	KEYD

::104			pla				;NMI abschließen.
			tay
			pla
			rti

;*** Daten für BASIC-Befehl.
:BasicCommand		s 40				;40 Byte für BASIC-Befehl.

:ResetTimer		b $00
:BasicBackData		b $00,$00,$00
:EndBasicL		b $00
:EndBasicH		b $00
endif

if Flag64_128 = TRUE_C128
;*** Nach BASIC verlassen.
:xToBasic		jsr	JumpB0_Basic		;Kommandostring (r0) nach $0e00

			lda	r5H			;kein File nachladen
			beq	:52

			iny
			tya
::51			sta	$1c00,y
			iny
			bne	:51

			SubVW	2,r7

			lda	(r7L),y
			pha
			iny
			lda	(r7L),y
			pha

			PushW	r7

			lda	(r5L),y
			sta	r1L
			iny
			lda	(r5L),y
			sta	r1H

			lda	#$ff
			sta	r2L
			sta	r2H
			jsr	ReadFile

			PopW	r0

			ldy	#1
			pla
			sta	(r0L),y
			dey
			pla
			sta	(r0L),y

			LoadB	r5L,$00

::52			jsr	NewDisk
			txa
			pha

			jsr	PurgeTurbo

			lda	sysRAMFlg
			sta	sysFlgCopy

			jsr	Copy_RAM_to_REU		;Kernal in REU aktualisieren.

::55			pla				;Fehler an BASIC-Routine übergeben.
			jmp	JumpB0_Basic2
endif

;*** Kernal-Daten in REU aktualisieren.
:Copy_RAM_to_REU	ldy	#0			;Systemvariablen Teil #1 und #2
::1			ldx	#0			;und Mauszeiger in REU retten.
::2			lda	SaveDataRAM,y
			sta	r0L        ,x
			iny
			inx
			cpx	#7
			bcc	:2

			txa
			pha
			tya
			pha
			jsr	StashRAM
			pla
			tay
			pla
			tax

			cpy	#3*7
			bcc	:1
			rts

;*** Transferdaten.
;    Diese Variablen werden vor dem verlassen zum BASIC in der REU
;    aktualisiert, damit beim RBOOT (SYS49152,RBOOTxz) die Werte korrekt
;    wieder hergestellt werden.
:SaveDataRAM		w $8400				;Systemvariablen Teil #1 speichern.
			w R1_ADDR_SYS_VAR1		;$8400 = Start SysVar#1 in RAM.
			w R1_SIZE_SYS_VAR1		;$7900 = Start SysVar#1 in REU.
			b $00

			w OS_VAR_MP			;Systemvariablen Teil #2 speichern.
			w OS_VAR_MP-$9d80+$b900		;$9D80 = Start SysVar#2 in RAM.
			w R3_SIZE_MPVARBUF		;$B900 = Start SysVar#2 in REU.
			b $00

			w mousePicData			;Aktuellen Mauszeiger retten.
			w $fc40
			w $0040
			b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_TOBASIC + R2_SIZE_TOBASIC -1
;******************************************************************************
