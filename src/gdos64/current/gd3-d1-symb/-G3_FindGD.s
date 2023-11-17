; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf GDOS-Kernal testen.
;    GEOS-Boot mit GDOS: Rückkehr zum Hauptprogramm.
;    GEOS-Boot mit V2x : Sofortiges Programm-Ende.
;    Programmstart V2x : Fehler ausgeben, zurück zum DeskTop.
:FindGD3		lda	bootName +1		;GDOS-Kernal aktiv ?
			cmp	#"D"			;"GDOS64-V3"
			bne	:51			; => Nein, weiter...
			lda	bootName +7
			cmp	#"V"
			beq	:54			; => Ja, GDOS64.

if FALSE
			lda	MP3_CODE +0		;Kennbyte für GDOS.
			cmp	#"M"			;GDOS installiert ?
			bne	:51			; => Nein, Abbruch...
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:51			; => Nein, Abbruch...

;--- Ergänzung: 14.03.21/M.Kanet
;Unter GEOS/MegaPatch ist die Routine
;":InitForDskDvJob" an einer anderen
;Stelle im Kernal.
			lda	InitForDskDvJob
			cmp	#$ac			;LDY-Befehl ?
			beq	:54			; => Ja, Ende...
endif

::51			bit	firstBoot		;GEOS-BootUp ?
			bpl	:53			;Keine Meldung ausgeben.

			lda	screencolors		;Bildschirm löschen.
			sta	:52
			jsr	i_FillRam
			w	1000
			w	COLOR_MATRIX
::52			b	$00

			lda	#$0b			;Bildschirm löschen.
			jsr	SetPattern
			jsr	i_Rectangle
			b	$00,$c7
			w	$0000,$013f

			lda	#< Dlg_WrongGEOS	;Fehlermeldung ausgeben.
			ldx	#> Dlg_WrongGEOS
			sta	r0L
			stx	r0H
			jsr	DoDlgBox
::53			jmp	EnterDeskTop
::54			rts

;*** Dialogbox: Falsche GEOS-Version.
:Dlg_WrongGEOS		b $81
			b DBTXTSTR,$0c,$10
			w :101
			b DBTXTSTR,$0c,$1a
			w :102
			b DBTXTSTR,$0c,$2a
			w :103
			b DBTXTSTR,$0c,$34
			w :104
			b DBTXTSTR,$0c,$3e
			w :105
			b OK      ,$10,$48
			b NULL

if LANG = LANG_DE
::101			b PLAINTEXT,BOLDON
			b "Der 'GDOS-Kernal' ist nicht",NULL
::102			b "in Ihrem System installiert!",NULL
::103			b "Booten Sie 'GEOS' erneut von",NULL
::104			b "einer GDOS64-Systemdiskette",NULL
::105			b "um das Programm zu starten.",NULL
endif

if LANG = LANG_EN
::101			b PLAINTEXT,BOLDON
			b "The 'GDOS-Kernal' is not",NULL
::102			b "installed in your System!",NULL
::103			b "Boot 'GEOS' from a GDOS64",NULL
::104			b "systemdisk bevor you start",NULL
::105			b "this program.",NULL
endif
