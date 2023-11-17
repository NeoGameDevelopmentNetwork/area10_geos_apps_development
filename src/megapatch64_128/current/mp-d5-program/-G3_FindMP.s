; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf GEOS-MegaPatch testen.
;    GEOS-Boot mit MP3: Rückkehr zum Hauptprogramm.
;    GEOS-Boot mit V2x: Sofortiges Programm-Ende.
;    Programmstart V2x: Fehler ausgeben, zurück zum DeskTop.
:FindMegaPatch		lda	MP3_CODE +0		;Kennbyte für MegaPatch.
			cmp	#"M"			;MegaPatch installiert ?
			bne	:1			;Nein, weiter...
			lda	MP3_CODE +1
			cmp	#"P"
			beq	:4

::1			bit	firstBoot		;GEOS-BootUp ?
			bpl	:3			;Keine Meldung ausgeben.

			lda	screencolors		;Bildschirm löschen.
			sta	:2
			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::2			b	$00

			lda	#$0b			;Bildschirm löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000 ! DOUBLE_W,$013f ! DOUBLE_W ! ADD1_W

			lda	#<Dlg_WrongGEOS		;Fehlermeldung ausgeben.
			ldx	#>Dlg_WrongGEOS
			sta	r0L
			stx	r0H
			jsr	DoDlgBox
::3			jmp	EnterDeskTop
::4			rts

;*** Dialogbox: Falsche GEOS-Version.
:Dlg_WrongGEOS		b $81
			b DBTXTSTR,$0c,$10
			w :1
			b DBTXTSTR,$0c,$1a
			w :2
			b DBTXTSTR,$0c,$2a
			w :3
			b DBTXTSTR,$0c,$34
			w :4
			b DBTXTSTR,$0c,$3e
			w :5
			b OK      ,$10,$48
			b NULL

if Sprache = Deutsch
::1			b PLAINTEXT,BOLDON
			b "Das 'GEOS-MegaPatch' ist nicht",NULL
::2			b "in Ihrem System installiert!",NULL
::3			b "Booten Sie 'GEOS' erneut von",NULL
::4			b "einer MegaPatch-Systemdiskette",NULL
::5			b "um das Programm zu starten.",NULL
endif

if Sprache = Englisch
::1			b PLAINTEXT,BOLDON
			b "The 'GEOS-MegaPatch' is not",NULL
::2			b "installed in your System!",NULL
::3			b "Boot 'GEOS' once more from",NULL
::4			b "an MegaPatch-Systemdisk",NULL
::5			b "bevor you run this program.",NULL
endif
