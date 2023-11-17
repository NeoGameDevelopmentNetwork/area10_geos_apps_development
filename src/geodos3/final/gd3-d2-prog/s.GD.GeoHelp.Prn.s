; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; GeoHelp.Edit.Prn V1.00a
; Kein echter Druckertreiber!

; Zum editieren der Hilfedateien.

; (w) 1996 by M. Kanet
; Quelltext im MegaAssembler-Format

			n	"GD.GEOHELP.PRN",NULL
			c	"Printdriver V2.1",NULL
			a	"GeoDOS 64",NULL
			f	9

			o	$7900
			p	$7900

			z	$40

			i
<MISSING_IMAGE_DATA>
;*** Treiber-Einsprungadressen.
:l7900			jmp	NoFunc			;InitForPrint
:l7903			jmp	NoFunc			;StartPrint
:l7906			jmp	NoFunc			;PrintBuffer
:l7909			jmp	NoFunc
:l790c			jmp	GetDim
:l790f			jmp	NoFunc
:l7912			jmp	NoFunc
:l7915			jmp	NoFunc

;*** Max. Anzahl Zeichen / Zeile und max. Anzahl Zeilen
;    ermitteln. (Ein Zeichen = 8 Grafikpunkte).
;    y=$3d 61 Zeilen, $41 65 Zeilen, $5a Standard
:GetDim			ldx	#$50			;Max. Anzahl Zeichen (cards).
			ldy	#$ff			;Max. Anzahl Zeilen.
			lda	#$00			;Ohne Bedeutung ???
			rts				;Ende.

;*** Abbruch.
:NoFunc			ldx	#$00
			rts
