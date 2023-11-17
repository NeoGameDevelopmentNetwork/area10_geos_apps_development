; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neue GD.INI erzeugen.
:CreateNewGDINI		lda	#8
			ldy	#> :com_Delete
			ldx	#< :com_Delete
			jsr	SETNAM			;Dateiname festlegen.

			lda	#15
			ldx	curDevice
			ldy	#15
			jsr	SETLFS
			jsr	OPENCHN			;OPEN 15,x,15,"S:GD.INI"

			lda	#15
			jsr	CLOSE			;Befehlskanal schließen.

;--- Neue GD.INI speichern.
			lda	#6
			ldy	#> FNamGDINI
			ldx	#< FNamGDINI
			jsr	SETNAM			;Dateiname festlegen.

			lda	#5
			ldx	curDevice
			ldy	#1
			jsr	SETLFS
			jsr	OPENCHN			;OPEN 5,x,1,"GD.INI"

			ldx	STATUS			;Fehler?
			bne	:error			; => Ja, Abbruch...

			ldx	#5
			jsr	CKOUT			;Ausgabe in Datei.

			ldy	#0
::1			lda	CFG_GDOS,y		;GDOS64-Konfiguration speichern.
			jsr	CIOUT
			iny
			cpy	#254
			bne	:1

			ldy	#0
::2			lda	CFG_GDESK,y		;GeoDesk-Konfiguration speichern.
			jsr	CIOUT
			iny
			cpy	#254
			bne	:2

			ldx	STATUS
::error			txa
			pha

			jsr	CLRCHN			;Standard-I/O herstellen.

			lda	#5
			jsr	CLOSE			;Datei schließen.

			pla
			tax

			rts

;--- Befehl  zum löschen der GD.INI
::com_Delete		b "S:GD.INI"

;*** GDOS64 Konfiguration.
:CFG_GDOS		t "-G3_StdConfig"
:CFG_GDOS_END		e CFG_GDOS +254

;*** GeoDesk Konfiguration.
:CFG_GDESK		t "-G3_StdConfigGD"
:CFG_GDESK_END		e CFG_GDESK +254
