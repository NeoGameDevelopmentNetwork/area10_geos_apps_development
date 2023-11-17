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
			t "SymbTab_GDOS"
			t "SymbTab_CSYS"
			t "SymbTab_CXIO"
			t "SymbTab_GEXT"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
;			t "MacTab"

;--- Externe Labels.
			t "s.GD3_KERNAL.ext"
endif

;*** GEOS-Header.
			n "obj.InitSystem"
			f DATA

			o LOAD_INIT_SYS

;*** Kernal-Variablen initialisieren.
:xInitGEOS		lda	#%00101111
			sta	CPU_DDR
			lda	#KRNL_IO_IN
			sta	CPU_DATA

			ldx	#$07
			lda	#$ff
::1			sta	KB_MultipleKey,x
			sta	KB_LastKeyTab ,x
			dex
			bpl	:1

			stx	keyMode
			stx	cia1base +2		;Port A: Bit=1 (read/write)
			inx
			stx	keyBufPointer
			stx	MaxKeyInBuf
			stx	cia1base +3		;Port B: Bit=0 (read only)
			stx	cia1base +15		;CIA#1: Init Control Timer B.
			stx	cia2base +15		;CIA#2: Init Control Timer B.

			lda	PAL_NTSC		;PAL/NTSC-Flag auslesen.
			lsr				;Bit%0: PAL = %0, NTSC = %1
			txa				;= lda #$00
			ror				;= Bit%7 = 0/1
			sta	cia1base +14		;Uhrzeit-Flag für PAL/NTSC
			sta	cia2base +14		;korrigieren. SCPU64-V1-Bug!!!

			lda	cia2base +0
			and	#%00110000		;CLOCK_OUT/DATA_OUT übernehmen.
			ora	#%00000101		;VIC-Bank#2: $8000-$BFFF.
			sta	cia2base +0
			lda	#%00111111
			sta	cia2base +2		;Port A: Bit=1 (read/write)
			lda	#$7f
			sta	cia1base +13		;Bit%7=0: Dann löschen der
			sta	cia2base +13		;IRQ-Maskenbit mit Bit%0-4=1.

;--- Hinweis:
;Die Adresse grmemptr = $d018 wird auf
;$38=%00111000 gesetzt. Damit liegt der
;Bildschirmspeicher bei $8C00-$8FFF und
;die Spritepointer bei $8FF8.
			ldy	#0
::3			lda	InitVICdata,y		;Neuen Wert für VIC-Register
			cmp	#$aa			;einlesen. Code $AA ?
			beq	:4			;Ja, übergehen.
			sta	vicbase    ,y		;Neuen VIC-Wert schreiben.
::4			iny
			cpy	#(InitVICend - InitVICdata)
			bne	:3

			jsr	SetKernalVec		;IO-Vektoren initialisieren.

			lda	#RAM_64K
			sta	CPU_DATA

			jsr	SetMseFullWin		;Mausgrenzen zurücksetzen.
			jsr	SCPU_SetOpt		;GEOS-Optimierung festlegen.

			jsr	SetADDR_InitSys
			jmp	SwapRAM

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LOAD_INIT_SYS + R2S_INIT_SYS -1
;******************************************************************************
