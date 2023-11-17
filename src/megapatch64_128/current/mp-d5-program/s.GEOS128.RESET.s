; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS128.RESET"
			t "G3_SymMacExt"
			t "G3_V.Cl.128.Boot"

			o $1c01-2

			z $40
			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "Startprogramm für"
			h "GEOS-MegaPatch 128..."
endif

if Sprache = Englisch
			h "Startfile for"
			h "GEOS-MegaPatch 128..."
endif

;*** Ladeadresse für BASIC-Programm.
:MainInit		w	$1c01

;*** Kopfdaten BASIC-Zeile.
			w $1c0b				;Link-Pointer auf nächste Zeile.
			w $0000				;Zeilen-Nr.

;*** BASIC-Zeile: SYS 7181
			b $9e,"7181",$00

;*** Ende BASIC-Programm markieren.
			w $0000

;*** Start-Programm für GEOS nachladen.
:RUN_GEOS_BOOT		lda	#$00
			sta	MMU
			lda	#$00
			jsr	SETMSG
			lda	#0			;($3f) RAM 0 (für Speicher)
			ldx	#0			;($3f) RAM 0 (für Dateiname)
			jsr	SETBANKFILE
			lda	#12			;Länge Dateiname
			ldx	#<BootName
			ldy	#>BootName
			jsr	SETNAM
			lda	#$50
			ldx	curDevice
			ldy	#$01
			jsr	SETLFS
			lda	#$00			;Flag für Load
			ldx	#$ff			;Bank1 Daten und Ausführ-
			ldy	#$ff			;routine an Basic-Ladeadresse
			jsr	LOAD			;laden
			bcc	:2			;>OK
::1			jmp	($0302)			;Warmstart ausführen.

::2			sei	 			;Interrupt sperren

			LoadW	$fa,BASE_GEOSBOOT
::4			lda	#$fa
			sta	$02b9
			ldy	#0			;Startprogramm von Bank 0 nach Bank 1
			lda	($fa),y			;kopieren
			ldx	#$01
			jsr	$ff77
			inc 	$fa
			bne	:4
			inc	$fb
			lda	$fb
			cmp	#$40
			bne	:4

			lda	#$00			;Automatik für RAM-Erkennung
			sta	BASE_GEOSBOOT+10	;deaktivieren.
			jmp	BASE_GEOSBOOT		;Startprogramm ausführen in Bank 0

;*** Name des Startprogramms.
:BootName		b "GEOS128.BOOT"

			g	BASE_GEOSBOOT
