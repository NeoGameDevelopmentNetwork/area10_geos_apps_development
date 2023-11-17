; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_CSYS"
			t "SymbTab_CROM"
			t "SymbTab_CXIO"
			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_KEYS"
			t "SymbTab_GRFX"
;			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
endif

;*** GEOS-Header.
			n "obj.NewToBasic"
			f DATA

			o LOAD_TOBASIC

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
			jsr	PurgeTurbo		;TurboDOS entfernen.

			lda	sysRAMFlg
			sta	sysFlgCopy

			ldy	#$00			;Systemvariablen Teil #1 und #2
::105			ldx	#$00			;und Mauszeiger in REU retten.
::106			lda	SaveDataRAM,y
			sta	r0L        ,x
			iny
			inx
			cpx	#$07
			bcc	:106

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
			bcc	:105

;*** Nach BASIC verlassen.
:JumpToBasic		sei

			lda	#KRNL_IO_IN		;Kernal einblenden.
			sta	CPU_DATA

::waitnokey		lda	#%00000000
			sta	cia1base +0
			lda	cia1base +1
			cmp	#%11111111		;Taste noch gedrückt?
			bne	:waitnokey		; => Ja, warten...

			ldy	#$02
::101			lda	$0800,y			;BASIC-Daten
			sta	BasicBackData,y		;zwischenspeichern.
			dey
			bpl	:101

			lda	r7H			;Endadresse speichern.
			sta	EndBasicH
			lda	r7L
			sta	EndBasicL

;			inc	CPU_DATA		;BASIC-ROM einblenden.
			lda	#KRNL_BAS_IO_IN		;KERNAL+BASIC ROM einblenden.
			sta	CPU_DATA

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
			sta	nmivec +1
			lda	#< NewNMI
			sta	nmivec +0

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
			sta	nmivec +1		; (Druck auf RESTORE)
			lda	#< SystemReBoot
			sta	nmivec +0

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

			lda	#KEY_CR			;<RETURN> in Tastaturpuffer.
			sta	KEYD

::104			pla				;NMI abschließen.
			tay
			pla
			rti

;*** Transferdaten.
;    Diese Variablen werden vor dem verlassen zum BASIC in der REU
;    aktualisiert, damit beim RBOOT (SYS49152,RBOOTxz) die Werte korrekt
;    wieder hergestellt werden.
:SaveDataRAM		w $8400				;Systemvariablen Teil #1 speichern.
			w R1A_SYS_VAR1			;$8400 = Start SysVar#1 in RAM.
			w R1S_SYS_VAR1			;$7900 = Start SysVar#1 in REU.
			b $00

::offset = R1A_SYS_PRG1 + (EXTVAR_BASE - OS_LOW)
			w EXTVAR_BASE			;Systemvariablen Teil #2 speichern.
			w :offset			;$9D80 = Start SysVar#2 in RAM.
			w EXTVAR_SIZE			;$B900 = Start SysVar#2 in REU.
			b $00

			w mousePicData			;Aktuellen Mauszeiger retten.
			w R1A_RBOOTMSE
			w R1S_RBOOTMSE
			b $00

;*** Daten für BASIC-Befehl.
:BasicCommand		s 40				;40 Byte für BASIC-Befehl.

:ResetTimer		b $00
:BasicBackData		b $00,$00,$00
:EndBasicL		b $00
:EndBasicH		b $00

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_TOBASIC + R2S_TOBASIC -1
;******************************************************************************
