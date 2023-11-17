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
:InitShadowRAM		lda	#>InitWordData		;Zeiger auf Initialisierungswert
			sta	r0H			;für Sektortabelle (2x NULL-Byte!)
			lda	#<InitWordData
			sta	r0L

			ldy	#$00			;Offset in 64K-Bank.
			sty	r1L
			sty	r1H
			sty	r2H			;Anzahl Bytes.
			iny
			iny
			sty	r2L

			iny				;Bank-Zähler initialisieren.
			sty	r3H

			ldy	curDrive		;Zeiger auf erste Bank für
			lda	ramBase -8,y		;Shadow1541-Laufwerk richten.
			sta	r3L

::52			jsr	StashRAM		;Sektor "Nicht gespeichert" setzen.
			inc	r1H			;Zeiger auf nächsten Sektor in Bank.
			bne	:52			;Schleife.

			inc	r3L			;Zeiger auf nächste Bank.
			dec	r3H			;Alle Bänke initialisiert ?
			bne	:52			;Nein, weiter...
			rts

:InitWordData		w $0000

;*** Sektor in ShadowRAM gespeichert ?
:IsSekInShadowRAM	ldy	#$91			;Sektor aus ShadowRAM einlesen.
			jsr	DoRAMOp_Job
			ldy	#$00			;LinkBytes verknüpfen.
			lda	(r4L),y			;Ist Ergebnis = $00, dann war Sektor
			iny				;nicht in RAM gespeichert.
			ora	(r4L),y
			rts

;*** Sektor in ShadowRAM vergleichen.
:VerifySekInRAM		ldy	#$93
			jsr	DoRAMOp_Job
			and	#$20
			rts

;*** Sektor in ShadowRAM speichern.
:SaveSekInRAM		ldy	#$90

;*** RAM-Transfer ausführen.
:DoRAMOp_Job		PushW	r0			;Register ":r0", bis ":r3L"
			PushW	r1			;zwischenspeichern.
			PushW	r2
			PushB	r3L

			jsr	DefSekAdrREU

			MoveW	r4,r0			;Zeiger auf C64-Speicher setzen.
			LoadW	r2,$0100
			jsr	DoRAMOp
			tax				;Transfer-Status zwischenspeichern.

			PopB	r3L			;Register ":r0" bis ":r3L"
			PopW	r2
			PopW	r1			;zurücksetzen.
			PopW	r0

			txa				;Transfer-Status zurücksetzen.
			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
			rts
endif
