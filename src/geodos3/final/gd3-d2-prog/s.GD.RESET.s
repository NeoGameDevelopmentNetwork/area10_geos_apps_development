; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** Zusätzliche Symboltabellen.
if .p
			t "SymbTab_64ROM"
endif

;*** GEOS-Header.
			n "GD.RESET"
			t "G3_Boot.V.Class"
			z $80				;nur GEOS64

			o $010e

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "BASIC-Startprogramm"
			h "für GeoDOS64..."
endif
if Sprache = Englisch
			h "BASIC-bootfile"
			h "for GeoDOS64..."
endif

;*** Ladeadresse für BASIC-Programm.
:MainInit		b $10,$01

;*** Kopfdaten BASIC-Zeile.
;    Nur wirksam, wenn die Startdatei über "LOAD'name',8" an den Beginn
;    des BASIC-Speichers geladen wird.

			w $0815				;Link-Pointer auf nächste Zeile.
			w $000f				;Zeilen-Nr.

;*** BASIC-Zeile: LOAD "GD.RESET",PEEK(165),1
			b $93,$22,"GD.RESET",$22,",",$c2,"(186),1",$00

;*** Ende BASIC-Programm markieren.
			w $0000

;*** Start-Programm für GEOS nachladen.
:RUN_GEOS_BOOT		lda	#$0e
			sta	$d020
			ldy	#$06
			sty	$d021

			lda	#$00
			sta	$02
			jsr	SETMSG			;Keine Anzeige von STATUS-Meldungen.

			lda	#$07
			ldy	#>BootName
			ldx	#<BootName
			jsr	SETNAM			;Dateiname festlegen.

			lda	#$01
			ldx	curDevice
			ldy	#$01
			jsr	SETLFS			;Dateiparameter festlegen.

			lda	#$00
			ldx	#$fe
			ldy	#$0f
			jsr	LOAD			;Datei laden.
			bcc	:51			;Fehler ? Nein, weiter...
			jmp	($0302)			;Warmstart ausführen.

::51			lda	#$00			;Automatik für RAM-Erkennung
			sta	BASE_GEOSBOOT +8	;deaktivieren ("-G3_SysBootData").
			jmp	BASE_GEOSBOOT		;Startprogramm ausführen.

;*** Name des Startprogramms.
:BootName		b "GD.BOOT"

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

;*** Startprogramm ausführen.
:l0203			jmp	RUN_GEOS_BOOT		;Boot-Programm starten.
