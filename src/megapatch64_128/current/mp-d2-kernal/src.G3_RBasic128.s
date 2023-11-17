; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "SymbTab_1"
			t "SymbTab128"
			t "MacTab_MAIN"
			t "G3_V.Cl.128.Data"
endif

			n "obj.ResetBasic"
			o StartBasicReset

;Reset-Routine ins Basic

:BasicReset		ldx	#$00			;Standard Kernel
			stx	MMU
			dex
			txs				;Stapel löschen
			tax
			bne	:1
			lda	curDevice		;Laufwerk aktivieren
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND
			lda	#$49			;Commando senden (I:0)
			jsr	CIOUT
			lda	#$3a
			jsr	CIOUT
			lda	#$30
			jsr	CIOUT
			jsr	UNLSN			;Laufwerk abmelden
			lda	curDevice		;Laufwerk anmelden
			jsr	LISTEN
			lda	#$ef
			jsr	SECOND
			jsr	UNLSN
::1			ldx	#$0a			;MMU Initialisierungstabelle
::2			lda	$e04b,x			;aktivieren
			sta	$d500,x
			dex
			bpl	:2
			sta	$0a04			;NMI-Status auf $00
			jsr	$e0cd			;NMI, IRQ und ZeroPage-Rout.
			jsr	$e242			;EXROM Eingang prüfen
			jsr	$e109			;Kernel IOINIT
			jsr	$f63d			;Tastaturabfrage RUN/STOP und
			lda	#$00			;Shift
			sta	$0a02			;Kernel Warm-/Kaltstart Status
			jsr	$e093			;Kernel RAMTAS
			jsr	$e056			;Kernel RESTORE
			jsr	$c000			;Init Editor und Screen
			lda	$0e2d			;Basicprogramm starten?
			beq	:3			;>nein
			cli
			jmp	($0a00)

::3			jsr	$417a			;BASIC initialisieren
			jsr	$4251
			jsr	$4045
			jsr	$419b
			lda	$0a04
			ora	#$01
			sta	$0a04
			ldx	#$03			;Basic Warmstart bei $4003
			stx	$0a00
			ldx	#$fb			;Stapelzeiger setzen
			txs
			LoadW	$0318,NewNMI		;Neue NMI-Routine installieren
			lda	#$00
			sta	$0e2c
			lda	#$06
			sta	$0e28
			lda	$dd0d
			lda	#$ff
			sta	$dd04
			sta	$dd05
			lda	#$81
			sta	$dd0d
			lda	#$01
			sta	$dd0e
			jmp	$401c			;Basic READY

:NewNMI			lda	$dd0d
			dec	$0e28
			bne	:6
			lda	#$01
			sta	$0e28
			ldy	$0e2c
			inc	$0e2c
			lda	$0e00,y
			bne	:5
			lda	#$7f
			sta	$dd0d
			ldx	#$02
::4			lda	$0e29,x
			sta	$1c00,x
			dex
			bpl	:4
			lda	#$0d
::5			sta	$034a
			lda	#$01
			sta	$d0
::6			jmp	$ff33			;Rückspr. aus NMI über IRQ_End
