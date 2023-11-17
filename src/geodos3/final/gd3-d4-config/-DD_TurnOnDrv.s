; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dialogbox: "Neues Laufwerk einschalten!".
;    Übergabe:		AKKU =	Adresse des Ziel-Laufwerks #8 - #11.
:TurnOnNewDrive		ldx	#$ff
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:err			; => Ja, Abbruch...

			sta	:curDevice		;Laufwerksadr. speichern und
			clc				;Text für Dialogbox initialisieren.
			adc	#$39
			sta	:t04

;--- Laufwerksadressen im Bereich #8 - #11 "deaktivieren".
			jsr	FreeDrvAdrGEOS		;Laufwerke #8 bis #11 auf
			txa				;Addresse #20 bis #23 umstellen
			bne	:err

;--- Dialogbox ausgeben.
			LoadW	r0,:dlgSetNewDev
			jsr	DoDlgBox		;Dialogbox: Laufwerk einschalten.

;--- Laufwerksadressen wieder zurücksetzen.
			jsr	PurgeTurbo		;GEOS-Turbo aus und I/O aktivieren.
			jsr	InitForIO

			lda	#8			;Nach neuem Laufwerk mit Adresse
::1			sta	r15H			;von #8 bis #19 suchen.
			jsr	FindSBusDevice		;Laufwerk vorhanden ?
			beq	:2			; => Ja, weiter...

			lda	r15H
			clc
			adc	#$01			;Zeiger auf nächstes Laufwerk.
			cmp	#20			;Alle Laufwerke getestet ?
			bcc	:1			; => Nein, weiter...

			jsr	DoneWithIO		;I/O abschalten.
			jmp	:3			;Kein neues Laufwerk, Ende...

::2			ldx	r15H			;Geräteadresse auf Ziel-Laufwerk
			ldy	:curDevice		;umschalten. Das neue Laufwerk hat
			jsr	SwapDiskDevAdr		;nun die benötigte GEOS-Adresse!

			ldy	:curDevice
			jsr	ClrDrvAdrGEOS

			jsr	DoneWithIO

::3			jsr	ResetDrvAdrGEOS		;Die restlichen Laufwerksadressen
			txa				;wieder auf die alten Adressen
			bne	:err			;zurücksetzen.

;--- Dialogbox auswerten.
			ldx	#$ff
			lda	sysDBData
			cmp	#OK			;Wurde "OK"-Icon gewählt ?
			bne	:err			; => Nein, weiter...
			inx
::err			rts

;--- Variablen.
::curDevice		b $00

;*** Dialogbox: "Laufwerk einschalten. Geräteadresse = #8 bis #19"
::dlgSetNewDev		b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBTXTSTR ,$0c,$0b
			w :t01
			b DBTXTSTR ,$0c,$20
			w :t02
			b DBTXTSTR ,$0c,$2a
			w :t03
			b DBTXTSTR ,$0c,$40
			w :t05
			b OK       ,$01,$50
			b CANCEL   ,$11,$50
			b NULL

if Sprache = Deutsch
::t01			b PLAINTEXT,BOLDON
			b "HINWEIS",0
::t02			b "Bitte schalten Sie jetzt",NULL
::t03			b "das neue Laufwerk "
::t04			b "x: ein!",NULL
::t05			b PLAINTEXT
			b "(Geräteadresse #8 bis #19)",NULL
endif

if Sprache = Englisch
::t01			b PLAINTEXT,BOLDON
			b "NOTICE",0
::t02			b "Please switch on the new",NULL
::t03			b "disk-drive "
::t04			b "x: now!",NULL
::t05			b PLAINTEXT
			b "(Set address from #8 to #19)",NULL
endif
