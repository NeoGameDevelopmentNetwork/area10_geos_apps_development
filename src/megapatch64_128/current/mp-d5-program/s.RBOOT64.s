; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "RBOOT64"
			t "G3_SymMacExt"
			t "G3_V.Cl.64.Boot"

			o $010e

			z $80
			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "RBOOT-Programm für"
			h "GEOS-MegaPatch 64..."
endif

if Sprache = Englisch
			h "RBOOT-file for"
			h "GEOS-MegaPatch 64..."
endif

;*** Ladeadresse für BASIC-Programm.
:MainInit		b $10,$01

;*** Kopfdaten BASIC-Zeile.
;    Nur wirksam, wenn die Startdatei über "LOAD'name',8" an den Beginn
;    des BASIC-Speichers geladen wird.

			w $0814				;Link-Pointer auf nächste Zeile.
			w $000f				;Zeilen-Nr.

;*** BASIC-Zeile: LOAD "RBOOT64",PEEK(165),1
			b $93,$22,"RBOOT64",$22,",",$c2,"(186),1",$00

;*** Ende BASIC-Programm markieren.
			w $0000

;*** Start-Programm für GEOS nachladen.
:RUN_RBOOT_SYS		lda	#$0e
			sta	$d020
			ldy	#$06
			sty	$d021

			lda	#$00
			sta	$02
			jsr	$ff90			;Keine Anzeige von STATUS-Meldungen.

			lda	#$0c
			ldy	#>BootName
			ldx	#<BootName
			jsr	$ffbd			;Dateiname festlegen.

			lda	#$01
			ldx	$ba
			ldy	#$01
			jsr	$ffba			;Dateiparameter festlegen.

			lda	#$00
			ldx	#$00
			ldy	#$20
			jsr	$ffd5			;Datei laden.
			bcc	InitRBOOT		;Fehler ? Nein, weiter...
			jmp	($0302)			;Warmstart ausführen.
:InitRBOOT		jmp	$1000			;Startprogramm ausführen.

;*** Name des Startprogramms.
:BootName		b "RBOOT64.BOOT"

;*** Stackspeicher mit $02-Bytes füllen. Beim Rücksprung aus der LOAD-
;    Routine findet das Kernal die Adresse $0202 als neue Rücksprung-Adresse
;    vor und startet dadurch automatisch das Boot-Programm.

:FillUpBytes		b $02,$02,$02,$02,$02,$02,$02,$02
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
			b $02

;*** Startprogramm ausführen.
:AutoStart		jmp	RUN_RBOOT_SYS		;Boot-Programm starten.
