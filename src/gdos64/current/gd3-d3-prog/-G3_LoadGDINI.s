; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GD.INI-Datei einlesen.
:LoadGDINI		LoadW	r6,FNamGDINI
			jsr	FindFile		;GD.INI-Datei suchen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	dirEntryBuf +1
			ldx	dirEntryBuf +2
			jsr	:readGDINIdata		;GDOS-Konfiguration einlesen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			ldx	#INCOMPATIBLE
			lda	diskBlkBuf +2		;Dateiversion überprüfen.
			cmp	#GDINI_VER		;GD.INI-Datei gültig?
			bne	:err			; => Nein, Abbruch...
			lda	diskBlkBuf +3		;Kennbyte überprüfen.
			cmp	#$c0			;GD.INI-Datei gültig?
			bne	:err			; => Nein, Abbruch...

			lda	#< R3A_CFG_GDOS
			ldx	#> R3A_CFG_GDOS
			ldy	#R3S_CFG_GDOS
			jsr	:saveGDINIdata

			lda	diskBlkBuf +0
			ldx	diskBlkBuf +1
			jsr	:readGDINIdata		;GeoDesk-Konfiguration einlesen.
			txa				;Diskettenfehler ?
			bne	:err			; => Ja, Abbruch...

			lda	#< R3A_CFG_GDSK
			ldx	#> R3A_CFG_GDSK
			ldy	#R3S_CFG_GDSK
			jsr	:saveGDINIdata

			ldx	#NO_ERROR
::err			rts

;--- Konfiguration einlesen.
::readGDINIdata		sta	r1L
			stx	r1H

			LoadW	r4,diskBlkBuf
			jmp	GetBlock		;GDOS-Konfiguration einlesen.

;--- Konfiguration in DACC sichern.
::saveGDINIdata		sta	r1L
			stx	r1H

			sty	r2L
			lda	#$00
			sta	r2H

			lda	#< diskBlkBuf +2
			sta	r0L
			lda	#> diskBlkBuf +2
			sta	r0H

			lda	MP3_64K_DATA
			sta	r3L

			jmp	StashRAM
