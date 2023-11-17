; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n	"GD_CONVERT",NULL

			h	"Übersetzungstabellen"
			h	"für GeoDOS 64"
			h	""
			h	"(c) 1995-2023: M.Kanet"

			m

			-   "mod.#00"			;00

;*** Namen der DOS-Tabellen.
			-   				;01 "Übersetzung 1:1 "
			-   "mod.#02"			;02 "PC437>GEOS-ASCII"
			-   "mod.#03"			;03 "PC850>GEOS-ASCII"
			-   "mod.#04"			;04 "PCWIN>GEOS-ASCII"
			-   "mod.#05"			;05 "LINUX>GEOS-ASCII"
			-   "mod.#06"			;06 "PC437>PETSCII   "
			-   "mod.#07"			;07 "PC850>PETSCII   "
			-   "mod.#08"			;08 "PCWIN>PETSCII   "
			-   "mod.#09"			;09 "PC437>Mastertext"
			-   "mod.#10"			;10 "PC437>Startexter"
			-	30

;*** Namen der CBM-Tabellen.
			-  				;41 "Übersetzung 1:1 "
			-   "mod.#42"			;42 "GEOS-ASCII>PC437"
			-   "mod.#43"			;43 "GEOS-ASCII>PC850"
			-   "mod.#44"			;44 "GEOS-ASCII>PCWIN"
			-   "mod.#45"			;45 "GEOS-ASCII>LINUX"
			-   "mod.#46"			;46 "PETSCII   >PC437"
			-   "mod.#47"			;47 "PETSCII   >PC850"
			-   "mod.#48"			;48 "PETSCII   >PCWIN"
			-   "mod.#49"			;49 "Mastertext>PC437"
			-   "mod.#50"			;50 "Startexter>PC437"
			-	30

;*** Namen der TXT-Tabellen.
			-  				;81 "Übersetzung 1:1 "
			-   "mod.#82"			;82 "BTX>GEOS-ASCII  "
			-   "mod.#83"			;83 "GEOS-ASCII>BTX  "
			-   37
			/
