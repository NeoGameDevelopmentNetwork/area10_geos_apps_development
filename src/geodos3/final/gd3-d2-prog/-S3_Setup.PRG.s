; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** System-Dateien kopieren.
:CopySystem		lda	PatchSizeKB +2		;Nicht kopierte Dateien vorhanden ?
			ora	PatchSizeKB +3
			beq	:exit			; => Nein, Ende...
			jsr	CopySystemFile		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
::exit			rts

:CopySystemFile		lda	#$ff
			sta	CopyFlgSystem
			lda	#< Inf_CopySystem
			ldx	#> Inf_CopySystem
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$01			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** ReBoot-Dateien kopieren.
:CopyRBoot		lda	PatchSizeKB +4		;Nicht kopierte Dateien vorhanden ?
			ora	PatchSizeKB +5
			beq	:exit			; => Nein, Ende...
			jsr	CopyRBootFile		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
::exit			rts

:CopyRBootFile		lda	#$ff
			sta	CopyFlgRBOOT
			lda	#< Inf_CopyRBoot
			ldx	#> Inf_CopyRBoot
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$02			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** Hintergrundbilder kopieren.
:CopyBackScrn		lda	PatchSizeKB +8		;Nicht kopierte Dateien vorhanden ?
			ora	PatchSizeKB +9
			beq	:exit			; => Nein, Ende...
			jsr	CopyBackScrnFile	;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
::exit			rts

:CopyBackScrnFile	lda	#$ff
			sta	CopyFlgBackScrn
			lda	#< Inf_CopyBkScr
			ldx	#> Inf_CopyBkScr
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$04			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** Bildschirmschoner kopieren.
:CopyScrSaver		lda	PatchSizeKB +10		;Nicht kopierte Dateien vorhanden ?
			ora	PatchSizeKB +11
			beq	:exit			; => Nein, Ende...
			jsr	CopyScrSaverFile	;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
::exit			rts

:CopyScrSaverFile	lda	#$ff
			sta	CopyFlgScrSave
			lda	#< Inf_CopyScrSv
			ldx	#> Inf_CopyScrSv
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$05			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.
