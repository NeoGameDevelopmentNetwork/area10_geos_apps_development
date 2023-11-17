; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Verwendung in:
;* mod.113 = Disk löschen.
;* mod.116 = Disk kopieren.

;*** Zeiger auf nächsten Sektor.
:GetNextSekAdr		lda	curType			;Laufwerksmodus einlesen.
			bne	:1			; => Gültig, weiter...
::err			ldx	#INV_TRACK		;Laufwerksmodus ungültig.
			rts

::1			and	#ST_DMODES		;Laufwerksmodus isolieren.
			cmp	#Drv1541		;Typ 1541?
			beq	:1541			; => Ja, weiter...
			cmp	#Drv1571		;Typ 1571?
			beq	:1571			; => Ja, weiter...
			cmp	#Drv1581		;Typ 1581?
			beq	:1581			; => Ja, weiter...
			cmp	#DrvNative		;Typ Native?
			beq	:Native			; => Ja, weiter...
			bne	:err			;Ungültig, Abbruch...

;--- 1541: Zeiger auf nächsten Sektor.
::1541			inc	r1H			;Sektor +1.

			ldx	r1L
			lda	r1H
			cmp	MaxSek_41_71 -1,x	;Letzter Sektor überschritten?
			bcc	:ok			; => Nein, weiter...

			ldx	#35			;Max. Anzahl Tracks.
			bne	:nextTrack		;Auf letzten Track testen.

;--- 1571: Zeiger auf nächsten Sektor.
::1571			ldy	curDrive		;1571/Doppelseitig?
			lda	doubleSideFlg -8,y
			bpl	:1541			; => Nein, 1571/Einseitig.

			inc	r1H			;Sektor +1.

			ldx	r1L
			lda	r1H
			cmp	MaxSek_41_71 -1,x
			bcc	:ok

			ldx	#70			;Max. Anzahl Tracks.
			bne	:nextTrack		;Auf letzten Track testen.

;--- 1581: Zeiger auf nächsten Sektor.
::1581			inc	r1H			;Sektor +1.

			ldx	r1L
			lda	r1H
			cmp	#40
			bcc	:ok

			ldx	#80			;Max. Anzahl Tracks.
			bne	:nextTrack		;Auf letzten Track testen.

;--- Native: Zeiger auf nächsten Sektor.
::Native		inc	r1H			;Sektor +1.
			bne	:ok			; => OK, weiter...

			ldx	maxTrack

;--- Ende Track erreicht, Zeiger auf nächsten Track.
::nextTrack		inc	r1L			;Spur +1.
			beq	:exit			; => NativeMode: Ende erreicht.

			lda	#$00			;Zeiger auf ersten Sektor
			sta	r1H			;zurücksetzen.

			cpx	r1L			;Letzte Spur überschritten?
			bcs	:ok			; => Nein, weiter...

::exit			ldx	#INV_TRACK		;Ende erreicht.
			rts

::ok			ldx	#NO_ERROR		;Kein Fehler.
			rts

;*** Anzahl Sektoren pro Spur, 1571.
:MaxSek_41_71		b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$13,$13,$13,$13,$13,$13,$13
			b $12,$12,$12,$12,$12,$12,$11,$11
			b $11,$11,$11
::1571			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$13,$13,$13,$13,$13,$13,$13
			b $12,$12,$12,$12,$12,$12,$11,$11
			b $11,$11,$11
