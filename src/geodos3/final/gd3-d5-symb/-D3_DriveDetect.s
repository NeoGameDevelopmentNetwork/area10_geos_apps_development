; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Geräteerkennung.
;
;Wird von GD.SETUP und GD.UPDATE
;verwendet. Übergabe der Laufwerke in
;":sysDevInfo".
;

;*** Laufwerke am ser.Bus erkennen.
:DetectAllDrives	ldy	#8			;Informationstabelle löschen.
			lda	#$00
::1			sta	sysDevInfo -8,y
			iny
			cpy	#29 +1
			bcc	:1

			lda	curDrive		;GEOS-TurboDOS auf allen
			pha				;Laufwerken abschalten.
			jsr	purgeAllDrvTurbo

			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	HWDetect		;Laufwerke erkennen.

			jsr	DoneWithIO		;I/O abschalten.

			pla
			jsr	SetDevice		;Aktuelles Laufwerk zurücksetzen.

;--- Alle Laufwerke erkannt, Ende.
			ldx	#NO_ERROR		; => "OK".
			rts

;*** Geräte am ser.Bus erkennen.
:HWDetect		lda	#$08			;Zeiger auf erstes Laufwerk.
			sta	curDevice

::loop			jsr	DetectCurDrive		;Laufwerk in AKKU testen.

::next			inc	curDevice		;Nächstes Laufwerk.
			lda	curDevice
			cmp	#29 +1			;Alle Laufwerke getestet?
			bcc	:loop			; => Nein, weiter...

			rts				;Ende.
