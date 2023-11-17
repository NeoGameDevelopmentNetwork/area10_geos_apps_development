; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS64"
			t "G3_SymMacExt"
			t "G3_V.Cl.64.Boot"

			o $010e

			z $80
			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Startprogramm für"
			h "GEOS-MegaPatch 64..."
endif

if Sprache = Englisch
			h "Startfile for"
			h "GEOS-MegaPatch 64..."
endif

;*** Ladeadresse für BASIC-Programm.
:MainInit		b $10,$01

;*** Kopfdaten BASIC-Zeile.
;    Nur wirksam, wenn die Startdatei über "LOAD'name',8" an den Beginn
;    des BASIC-Speichers geladen wird.

			w $0813				;Link-Pointer auf nächste Zeile.
			w $000f				;Zeilen-Nr.

;*** BASIC-Zeile: LOAD "GEOS",PEEK(165),1
			b $93,$22,"GEOS64",$22,",",$c2,"(186),1",$00

;*** Ende BASIC-Programm markieren.
			w $0000

;*** Start-Programm für GEOS nachladen.
:RUN_GEOS_BOOT		lda	#$0e
			sta	$d020
			ldy	#$06
			sty	$d021

			lda	#$00
			sta	$02
			jsr	$ff90			;Keine Anzeige von STATUS-Meldungen.

			lda	#$0b
			ldy	#>BootName
			ldx	#<BootName
			jsr	$ffbd			;Dateiname festlegen.

			lda	#$01
			ldx	$ba
			ldy	#$01
			jsr	$ffba			;Dateiparameter festlegen.

			lda	#$00
			ldx	#$fe
			ldy	#$0f
			jsr	$ffd5			;Datei laden.
			bcc	:51			;Fehler ? Nein, weiter...
			jmp	($0302)			;Warmstart ausführen.
::51			jmp	$1000			;Startprogramm ausführen.

;*** Name des Startprogramms.
:BootName		b "GEOS64.BOOT"

;*** Stackspeicher mit $02-Bytes füllen. Beim Rücksprung aus der LOAD-
;    Routine findet das Kernal die Adresse $0202 als neue Rücksprung-Adresse
;    vor und startet dadurch automatisch das Boot-Programm.
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02,$02,$02,$02,$02,$02
			b $02,$02,$02

;*** Startprogramm ausführen.
:l0203			jmp	RUN_GEOS_BOOT		;Boot-Programm starten.
