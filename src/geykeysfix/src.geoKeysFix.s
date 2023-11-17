; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"TopMac"
endif

:PutKeyInBuffer		= $c0f1
:MP3_CODE		= $c014
:MP64NEWKEY		= $fcb8
:MP128NEWKEY		= $c8d5
:GKEY64NEWKEY		= $fd30
:GKEY128NEWKEY		= $c8fc
:DEBUG64		= $fc20
:DEBUG128		= $c7ec

			n	"geoKeysFixMP3"
			c	"geoKeysFix  V1.6",NULL
			a	"Markus Kanet",NULL
			f	AUTO_EXEC
			o	APP_RAM
			z	$40
			h	"geoKeysFix behebt ein Problem mit dem Tastaturtreiber von geoKeys in GEOS/MegaPatch."
			i
<MISSING_IMAGE_DATA>

:MAININIT		lda	MP3_CODE +0		;Auf MP3/G3-Kennung testen.
			cmp	#"M"
			bne	:exit			; => Kein MP3/G3...
			lda	MP3_CODE +1
			cmp	#"P"
			bne	:exit			; => Kein MP3/G3...

;--- Ist MP3-Treiber noch aktiv?
			lda	PutKeyInBuffer +1
			sta	r0L
			lda	PutKeyInBuffer +2
			sta	r0H

			ldy	#$00			;Die ersten beiden Bytes des
			lda	(r0L),y			;Tastaturtreibers testen.
			cmp	#$08			;PHP
			bne	:newkeys		; => Nein, PutKeyInBuf ersetzen.
			iny
			lda	(r0L),y
			cmp	#$78			;SEI
			beq	:exit			; => Ja, Ende...

;--- Zeiger auf NewKeyInBuffer von geoKeys.
::newkeys		bit	c128Flag		;Auf C128 testen.
			bmi	:keys128		; => C128, weiter...

::keys64		lda	#<GKEY64NEWKEY
			sta	PutKeyInBuffer +1
			ldx	#>GKEY64NEWKEY
			stx	PutKeyInBuffer +2
			bne	:testkeys

::keys128		lda	#<GKEY128NEWKEY
			sta	PutKeyInBuffer +1
			ldx	#>GKEY128NEWKEY
			stx	PutKeyInBuffer +2

;--- Tastatur-Treiber testen.
::testkeys		sta	r0L			;Zeiger auf NewKeyInBuf-Routine.
			stx	r0H

;Passender Treiber aktiv?
			ldy	#$00			;Die ersten beiden Bytes des
			lda	(r0L),y			;Tastaturtreibers testen.
			cmp	#$08			;PHP
			bne	:nokeys			; => Nein, PutKeyInBuf abschalten.
			iny
			lda	(r0L),y
			cmp	#$78			;SEI
			beq	:no_debug		; => Ja, Debug-Code abschalten...

;--- Falscher Treiber.
;PutKeyInBuffer deaktivieren.
::nokeys		lda	#$60			;RTS
			sta	PutKeyInBuffer +0

			lda	#$ea			;NOP
			sta	PutKeyInBuffer +1
			sta	PutKeyInBuffer +2
			bne	:exit

;Debug-Code deaktivieren.
;Setzt COLOR_MATRIX+0 wenn ShiftLock gedrückt und kopiert
;COLOR_MATRIX+2 nach COLOR_MATRIX+0 wenn nicht mehr gedrückt.
;Führt zu Farb-Fehlern bei Programmen die COLOR_MATRIX nutzen.
::no_debug		lda	#$ea			;NOP

			bit	c128Flag		;Auf C128 testen.
			bmi	:128			; => C128, weiter...

::64			ldy	#$0c			;Debug-Code geoKeys64 abschalten.
::64a			sta	DEBUG64,y
			dey
			bpl	:64a
			bmi	:exit

::128			ldy	#$0c			;Debug-Code geoKeys128 abschalten.
::128a			sta	DEBUG128,y
			dey
			bpl	:128a

;--- Zurück zum DeskTop.
::exit			jmp	EnterDeskTop
