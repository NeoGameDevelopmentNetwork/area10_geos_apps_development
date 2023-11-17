; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Auf SD2IEC testen.
;Dazu den Befehl "M-R",$00,$03,$03 senden.
;Die Rückmeldung "00,(OK,00,00)" deutet auf ein SD2IEC hin.
;
;--- Ergänzung: 19.12.07/M.Kanet
;Dieser Code wurde bereits am 26.12.2018 vereinfacht.
;Die Änderung führt aber zu Screengarbage auf dem 80Z-Bildschirm
;des C128 wenn versucht wird ein Laufwerk zu installieren:
; - Laufwerk #10 nicht vorhanden,
; - Laufwerk #11 ist 1571, aber nicht im Editor eingerichtet.
; - Laufwerk #10 als 1571 einrichten.
;Deaktiviert man Laufwerk #10 und richtet die 1571 jetzt als
;Laufwerk #11 ein, dann werden weitere fehlerhafte Pixel im VDC-RAM
;dargestellt. Der Fehler scheint auch nur 1541/71/81 zu betreffen und
;die einzigen Änderungen zwischen dem 16.12.18 und 26.12.18
;betreffen die TestSD2IEC-Routine.
;
;*** NICHT MEHR ÄNDERN ***
;
:TestSD2IEC		tya				;1541: Y-Reg sichern.
			pha

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	DrvAdrGEOS		;Laufwerksadresse einlesen und
			jsr	FindSBusDevice		;testen ob Laufwerk aktiv.
			bne	:1			; => Nein, Abbruch...

			lda	#15
			tay
			ldx	DrvAdrGEOS
			jsr	SETLFS			;Kanal, Laufwerk, Sekundäradresse.

			jsr	OPENCHN			;Befehlskanal öffnen.

			lda	#<FComTest		;"M-R"-Befehl senden.
			ldx	#>FComTest
			ldy	#$06
			jsr	SendFCom

			lda	#<FComReply		;Ergebnis einlesen.
			ldx	#>FComReply
			ldy	#$03
			jsr	GetFData

			lda	#15			;Befehlskanal schließen.
			jsr	CLOSE

			ldx	#$ff			;Vorgabe: SD2IEC.
			lda	FComReply +0		;Rückmeldung auswerten.
			cmp	#"0"			;"00," ?
			bne	:1			; => Nein, Ende...
			lda	FComReply +1
			cmp	#"0"
			bne	:1
			lda	FComReply +2
			cmp	#","
			beq	:2
::1			ldx	#NO_ERROR		;Kein SD2IEC.
::2			jsr	DoneWithIO		;I/O-Bereich deaktivieren.
			pla
			tay
			rts

:FComTest		b "M-R",$00,$03,$03
:FComReply		s $03

;*** Floppy-Befehl senden.
:SendFCom		sta	r0L			;Ziger auf Floppy-Befehl.
			stx	r0H
			sty	r1L			;Anzahl Zeichen im Floppy-Befehl.

			ldx	#15
			jsr	CKOUT			;Ausgabekanal festlegen.

			lda	#$00			;Zeiger auf erstes Zeichen.
			sta	:1 +1
::1			ldy	#$ff
			cpy	r1L			;Alle Zeichen gesendet?
			beq	:2			; => Ja, Ende...
			lda	(r0L),y
			jsr	BSOUT			;Zeichen aus IEC-Bus senden.
			inc	:1 +1
			jmp	:1			;Weiter mit nächstem Zeichen.

::2			jmp	CLRCHN			;Ausgabekanal zurücksetzen.

;*** Rückmeldung von Floppy empfangen.
:GetFData		sta	r0L			;Ziger auf Datenspeicher.
			stx	r0H
			sty	r1L			;Anzahl Zeichen.

			lda	#$00
			sta	STATUS			;Status-Flag löschen.

			ldx	#15
			jsr	CHKIN			;Empfangskanal festlegen.

			lda	#$00			;Zeiger auf erstes Zeichen.
			sta	:3 +1
::1			jsr	GETIN			;Daten über IEC-Bus einlesen.
::3			ldy	#$ff
			cpy	r1L			;Alle Daten eingelesen?
			beq	:2			; => Ja, Ende...
			sta	(r0L),y			;Daten zwischenspeichern.
			inc	:3 +1
			jmp	:1			;Weiter mit nächstem Zeichen.

::2			jmp	CLRCHN			;Ausgabekanal zurücksetzen.

;*** Diskettenstatus einlesen.
:skipDrvStatus		jsr	UNTALK			;Laufwerk abschalten.

			lda	#$00			;Status-Byte löschen.
			sta	STATUS

			lda	curDrive		;Laufwerksadresse verwenden.
			jsr	TALK			;Laufwerk aktivieren.
			bit	STATUS			;Laufwerksfehler?
			bmi	:error			; => Ja, Abbruch...

			lda	#15 ! %11110000
;			ora	#$f0			;"OPEN".
			jsr	TKSA			;Laufwerk auf Senden schalten.
			bit	STATUS			;Fehler aufgetreten ?
			bmi	:error			; => Nein, Ende...

::loop			jsr	ACPTR			;Fehlerstatus überspringen.
			lda	STATUS
			beq	:loop

::error			jmp	UNTALK			;Laufwerk abschalten.

;*** Laufwerks-ROM für SD2IEC laden.
:LoadDriveROM		sta	FComLoadROM +8		;DOS-Kennung speichern.
			stx	FComLoadROM +9

			jsr	PurgeTurbo		;TurboDOS entfernen.
			jsr	InitForIO		;I/O-Bereich aktivieren.

			ldx	DrvAdrGEOS
			lda	#15
			tay
			jsr	SETLFS
			jsr	OPENCHN			;Befehlskanal öffnen.

			lda	#<FComLoadROM		;"XR:"-Befehl senden.
			ldx	#>FComLoadROM
			ldy	#$0e
			jsr	SendFCom

			lda	#15
			jsr	CLOSE			;Befehlskanal schließen.

;--- Hinweis:
;Evtl. verstehen nicht alle SD2IEC den
;"XR"-Befehl, daher ggf. Fehlerstatus
;am Laufwerk auslesen/löschen.
			jsr	skipDrvStatus		;Fehlerstatus überspringen.

			jmp	DoneWithIO		;I/O-Bereich abschalten.

:FComLoadROM		b "XR:DOS15??.BIN"
