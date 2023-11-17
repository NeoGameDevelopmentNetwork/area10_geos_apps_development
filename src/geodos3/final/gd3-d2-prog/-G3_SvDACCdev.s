; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichererweiterung in Startprogramme übertragen.
;--- Ergänzung: 03.03.21/M.Kanet:
;Wird von GD.BOOT und GD.UPDATE
;gemeinsam verwendet.
:SaveConfigDACC		LoadW	r6,FNamGBOOT		;"GD.BOOT" modifizieren.
			jsr	FindFile
			txa
			bne	:51

			jsr	:save_config

::51			LoadW	r6,FNamRBOOT		;"RBOOT64.BOOT" modifizieren.
			jsr	FindFile
			txa
			beq	:save_config
;--- Ergänzung: 07.02.21/M.Kanet
;Bei "FILE_NOT_FOUND" keinen Fehler ausgeben, da evtl.
;RBOOT nicht über das Setup installiert wurde.
			cpx	#FILE_NOT_FOUND		;RBOOT nicht gefunden?
			bne	:52			; => Diskfehler ausgeben.
			ldx	#NO_ERROR		;Nicht installiert, kein Fehler.
::52			rts

;*** Konfiguration speichern.
::save_config		lda	dirEntryBuf +1		;Ersten Programmsektor einlesen.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa				;Diskettenfehler ?
			bne	:62			; => Ja, Abbruch...

;--- Startadresse in Programmblock:
;    (inkl. Sektor-Link-Bytes!)
::data_start		= 2+ (SYS_DACCVAR_START - L_KernelData)
;--- Anzahl Datenbytes.
::data_size		= (SYS_DACCVAR_END - SYS_DACCVAR_START)

;			ldx	#0
::61			lda	ExtRAM_Type,x		;DACC-Daten speichern.
			sta	diskBlkBuf + :data_start,x
			inx
			cpx	#:data_size
			bcc	:61

			jsr	PutBlock		;Sektor wieder auf Disk speichern.
::62			rts
