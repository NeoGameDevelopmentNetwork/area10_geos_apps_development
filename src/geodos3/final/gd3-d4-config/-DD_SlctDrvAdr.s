; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Laufwerksadresse wählen.
;Rückgabe: XReg = $00, OK
;               > $00, Abbruch
;          AKKU = Laufwerk #8-#11
:SlctGEOSadr		ldx	#3			;Für Laufwerksauswahl alle
::1			lda	driveType ,x		;Typen als "Vorhanden" markieren.
			bne	:2			;Wichtig für Dialogbox-Code
			lda	#$ff			;"DRIVE" = $07.
			sta	driveType ,x
::2			dex
			bpl	:1

			LoadW	r0,:dlgSlctNewDev
			jsr	DoDlgBox		;Laufwerksadresse wählen.

			ldx	#0			;Änderungen an ":driveType" wieder
::3			ldy	driveType ,x		;Rückgängig machen.
			iny
			bne	:4
			lda	#$00
			sta	driveType ,x
::4			inx
			cpx	#4
			bcc	:3

			ldx	sysDBData		;"Abbruch" gewählt ?
			bpl	:dlg_cancel		; => Ja, Ende...

			txa
			and	#%00001111		;Gewähltes Laufwerk ermitteln und

			ldx	#NO_ERROR
			b $2c
::dlg_cancel		ldx	#CANCEL_ERR
			rts

;*** Dialogbox: "GEOS-Laufwerksadresse wählen:"
::dlgSlctNewDev		b %01100001
			b $30,$8f
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$0c,$0b
			w :t01
			b DBTXTSTR ,$0c,$20
			w :t02
			b DBTXTSTR ,$0c,$2a
			w :t03
			b DBVARSTR ,$10,$3a
			b r5L
			b DRIVE    ,$02,$48
			b CANCEL   ,$11,$48
			b NULL

if Sprache = Deutsch
::t01			b PLAINTEXT,BOLDON
			b "LAUFWERK INSTALLIEREN",0
::t02			b "Bitte Adresse für das neue",NULL
::t03			b "Laufwerk unter GEOS wählen:",0
endif

if Sprache = Englisch
::t01			b PLAINTEXT,BOLDON
			b "INSTALL DISK DRIVE",0
::t02			b "Please select the GEOS",NULL
::t03			b "address for the disk drive:",0
endif
