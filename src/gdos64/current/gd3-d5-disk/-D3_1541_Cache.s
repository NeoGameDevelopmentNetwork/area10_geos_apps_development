; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0 = TRUE
;******************************************************************************
;*** ShadowRAM initialisieren.
:InitShadowRAM		t "-D3_InitShadow"

;*** Sektor in ShadowRAM gespeichert ?
:IsSekInShadowRAM	ldy	#jobFetch
			jsr	execRamOpJob		;Sektor aus ShadowRAM einlesen.
			ldy	#$00			;LinkBytes verknüpfen.
			lda	(r4L),y			;Ist Ergebnis = $00, dann war Sektor
			iny				;nicht in RAM gespeichert.
			ora	(r4L),y
			rts

;*** Sektor in ShadowRAM vergleichen.
:VerifySekInRAM		ldy	#jobVerify
			jsr	execRamOpJob		;Sektor in ShadowRAM vergleichen.
			and	#%00100000		;Fehler-Bit isolieren.
			rts

;*** Sektor in ShadowRAM speichern.
:SaveSekInRAM		ldy	#jobStash

;*** RAM-Transfer ausführen.
:execRamOpJob		PushW	r0			;Register ":r0", bis ":r3L"
			PushW	r1			;zwischenspeichern.
			PushW	r2
			PushB	r3L

			jsr	DefSekAdrREU		;Zeiger auf Sektor in REU setzen.

			MoveW	r4,r0			;Zeiger auf C64-Speicher setzen.
			LoadW	r2,$0100		;Sektorgröße = 256 Bytes.
			jsr	DoRAMOp			;Speicherzugriff ausführen.
			tax				;Transfer-Status zwischenspeichern.

			PopB	r3L			;Register ":r0" bis ":r3L"
			PopW	r2
			PopW	r1			;zurücksetzen.
			PopW	r0

			txa				;Transfer-Status zurücksetzen.
			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
			rts
endif
