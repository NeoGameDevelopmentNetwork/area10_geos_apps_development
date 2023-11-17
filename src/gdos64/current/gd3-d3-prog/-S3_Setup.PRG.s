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
:CopyExtras		lda	PatchSizeKB +8		;Nicht kopierte Dateien vorhanden ?
			ora	PatchSizeKB +9
			beq	:exit			; => Nein, Ende...
			jsr	CopyExtraFiles		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
::exit			rts

:CopyExtraFiles		lda	#$ff
			sta	CopyFlgExtras
			lda	#< Inf_CopyExtras
			ldx	#> Inf_CopyExtras
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$04			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.

;*** Hilfesystem kopieren.
:CopyHelpSys		lda	PatchSizeKB +10		;Nicht kopierte Dateien vorhanden ?
			ora	PatchSizeKB +11
			beq	:exit			; => Nein, Ende...
			jsr	CopyHelpFiles		;Dateien kopieren und
			jmp	CopyMenu		;zurück zum Hauptmenü.
::exit			rts

:CopyHelpFiles		lda	#$ff
			sta	CopyFlgHelp
			lda	#< Inf_CopyHelp
			ldx	#> Inf_CopyHelp
			jsr	ViewInfoBox		;Infomeldung ausgeben.
			lda	#$05			;Systemdateien aus Archiv
			jmp	ExtractFiles		;entpacken.
