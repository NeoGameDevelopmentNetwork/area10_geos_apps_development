; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Kernal #1.
:KERNAL__1		OPEN_BOOT
			OPEN_SYMBOL

;--- BuildID.
			b $f0,"src.Kernal.Build",$00	;Build-ID/Revision

			OPEN_KERNAL

;--- Maustreiber.
			t "-A3_Kernal#1"

;--- MegaPatch Kernal.
			t "-A3_Kernal#2"

;--- Joysticktreiber.
;    Diese werden nicht in den Kernal eingebunden und werden nur der
;    Logik nach hier zusammen mit dem Maustreiber kompiliert.
			t "-A3_Kernal#3"

;--- MegaPatch Kernal packen.
			b $f1
			LoadW	r0,40*25		;Bildschirm löschen.
			LoadW	r1,COLOR_MATRIX
			lda	screencolors
			sta	r2L
			jsr	FillRam

			lda	#DvAdr_Target		;Auf Ziel-Laufwerk umschalten
			jsr	SetDevice		;und Diskette öffnen.
			txa
			bne	:201
			jsr	OpenDisk
			txa
			bne	:201

;*** Packer laden und starten:
;    r0L  Bit0=0: Programm laden und starten.
;         Bit0=1: Programm laden aber nicht starten.
;         Bit6=0: Datenfile nicht ausdrucken.
;         Bit6=1: Datenfile ausdrucken.
;         Bit7=0: Kein Datenfile nachladen.
;         Bit7=1: Datenfile nachladen.
;    r2         : Zeiger auf Namen der Datendiskette.
;    r3         : Zeiger auf Namen des Datenfiles.
;    r6         : zeiger auf Dateiname.
;    r10L $00   : Muß für DeskAccessories $00 sein.
			LoadB	r0L,%00000000
			LoadW	r6 ,:101
			jsr	GetFile			;Kernal-Packer laden.
			txa
			bne	:301
			jmp	EnterDeskTop		;Fehler: Zum DeskTop zurück.

::101			b "MP_MakeKernal",$00

::201			LoadW	r0,:801			;Laufwerk mit MP_MakeKernal
			jsr	DoDlgBox		;kann nicht geöffnen werden.
			jsr	MouseUp
::202			lda	mouseData
			bpl	:202
			LoadB	pressFlag,NULL
			jsr	MouseOff
			jmp	EnterDeskTop		;Fehler: Zum DeskTop zurück.

::301			LoadW	r0,:901			;MP_MakeKernal kann nicht
			jsr	DoDlgBox		;gestartet werden.
			jsr	MouseUp
::302			lda	mouseData
			bpl	:302
			LoadB	pressFlag,NULL
			jsr	MouseOff
			jmp	EnterDeskTop		;Fehler: Zum DeskTop zurück.

::801			b $01
			b $30
			b $72
			w $0040!DOUBLE_W
			w $00ff!DOUBLE_W!ADD1_W
			b DBTXTSTR,$10,$0e
			w :810
			b DBTXTSTR,$10,$1e
			w :811
			b DBTXTSTR,$10,$28
			w :812
			b OK,$02,$30
			b NULL
::810			b "Diskettenfehler!",NULL
::811			b "Kann Laufwerk mit 'MP_MakeKernal'",NULL
::812			b "nicht öffnen!",NULL

::901			b $01
			b $30
			b $72
			w $0040!DOUBLE_W
			w $00ff!DOUBLE_W!ADD1_W
			b DBTXTSTR,$10,$0e
			w :910
			b DBTXTSTR,$10,$1e
			w :911
			b DBTXTSTR,$10,$28
			w :912
			b OK,$02,$30
			b NULL
::910			b "Systemfehler!",NULL
::911			b "Kann 'MP_MakeKernal' nicht",NULL
::912			b "starten!",NULL
