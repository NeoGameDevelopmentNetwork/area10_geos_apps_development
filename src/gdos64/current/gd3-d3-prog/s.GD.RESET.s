; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "opt.GDOSl10n.ext"
			t "SymbTab_CSYS"
			t "SymbTab_CROM"
;			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_GRFX"
			t "SymbTab_CHAR"
;			t "MacTab"

;--- Build Legacy-Mode?
;Set to "FALSE" or "TRUE"...
:LEGACY = FALSE
endif

;*** GEOS-Header.
			n "GD.RESET"
			c "GDOSBOOT    V3.0"
			t "opt.Author"
;--- Hinweis:
;Startprogramme können von DESKTOP 2.x
;nicht kopiert werden.
;			f SYSTEM_BOOT ;Typ Startprogramm.
			f SYSTEM      ;Typ Systemdatei.
			z $80 ;nur GEOS64

			o $010e

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "BASIC-Startprogramm"
			h "für GDOS64..."
endif
if LANG = LANG_EN
			h "BASIC bootfile"
			h "for GDOS64..."
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
:RUN_GEOS_BOOT		lda	#%00010101		;%0001xxxx: screenmem is at $0400
			sta	grmemptr		;%xxxx010x: charmem is at $1000

if LEGACY = TRUE
			lda	#14			;Rahmenfarbe...
			sta	extclr
			ldy	#6			;Bildschirmfarbe...
			sty	bakclr0
			sta	COLOR			;Textfarbe...
endif
if LEGACY = FALSE
			lda	#0			;Rahmen-/Bildschirmfarbe...
			sta	extclr
			sta	bakclr0

			lda	#15			;Textfarbe...
			sta	COLOR

			jsr	CLEAR			;Bildschirm löschen.

			lda	#< BootText00		;GDOS-Info.
			ldy	#> BootText00
			jsr	ROM_OUT_STRING

			lda	#< BootText00a		;GDOS-Version.
			ldy	#> BootText00a
			jsr	ROM_OUT_STRING
endif

			lda	#$00
			sta	$02
			jsr	SETMSG			;Keine Anzeige von STATUS-Meldungen.

			lda	#len_BootName
			ldy	#> BootName
			ldx	#< BootName
			jsr	SETNAM			;Dateiname festlegen.

			lda	#1
			ldx	curDevice
;			ldy	#1
			tay
			jsr	SETLFS			;Dateiparameter festlegen.

			lda	#$00			;LOAD nach BASE_GEOSBOOT = $1000.
			ldx	#< (BASE_GEOSBOOT -2)
			ldy	#> (BASE_GEOSBOOT -2)
			jsr	LOAD			;Datei laden.
			bcc	:51			;Fehler ? Nein, weiter...
			jmp	($0302)			;Warmstart ausführen.

;--- Ergänzung: 09.04.21/M.Kanet
;Direkt nach dem Bootvorgang ist noch
;ein Befehlskanal auf dem Boot-Laufwerk
;geöffnet. LTDND/$0098 = 1
;Zur einfacheren Fehlersuche mit leerer
;Tabelle starten -> CLALL aufrufen.
::51			jsr	CLALL			;Alle Laufwerkskanäle schließen.

			lda	#$ff			;Automatik für RAM-Erkennung
			sta	BASE_GEOSBOOT +3	;deaktivieren (":BOOT_RAM_TYPE").

			jmp	BASE_GEOSBOOT		;Startprogramm ausführen.

;*** Name des Startprogramms.
:BootName		b "GD.BOOT"
:end_BootName
:len_BootName		= ( end_BootName - BootName )

;*** Startmeldungen.
if LEGACY = FALSE
			t "-G3_PrntCoreInf"
endif

;*** Stackspeicher mit $02-Bytes füllen.
;Beim Rücksprung aus der LOAD-Routine
;findet der Kernal die Adresse $0202
;als neue Rücksprung-Adresse vor, kehrt
;zur Adresse $0202+1=$0203 zurück und
;startet automatisch das Boot-Programm.
:FillUpBytes		b $02,$02,$02,$02,$02,$02,$02,$02
::008			b $02,$02,$02,$02,$02,$02,$02,$02
::016			b $02,$02,$02,$02,$02,$02,$02,$02
::024			b $02,$02,$02,$02,$02,$02,$02,$02
::032			b $02,$02,$02,$02
if LEGACY = TRUE
::036			b                 $02,$02,$02,$02
::040			b $02,$02,$02,$02,$02,$02,$02,$02
::048			b $02,$02,$02,$02,$02,$02,$02,$02
::056			b $02,$02,$02,$02,$02,$02,$02,$02
::064			b $02,$02,$02,$02,$02,$02,$02,$02
::072			b $02,$02,$02,$02,$02,$02,$02,$02
::080			b $02,$02,$02,$02,$02,$02,$02,$02
::088			b $02,$02,$02,$02,$02,$02,$02,$02
::096			b $02,$02,$02,$02,$02,$02,$02,$02
::104			b $02,$02,$02,$02,$02,$02,$02,$02
::112			b $02,$02,$02,$02,$02,$02,$02,$02
::120			b $02,$02,$02,$02,$02,$02,$02,$02
::128			b $02,$02,$02,$02,$02,$02,$02,$02
::136			b $02,$02,$02,$02,$02,$02
endif

;*** Startprogramm ausführen.
:l0203			jmp	RUN_GEOS_BOOT		;Boot-Programm starten.

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
:l0206
if l0206 = $0206
else
"Endadresse <> $0206!!! Füllbytes?"
endif
;			g $0206
;******************************************************************************
