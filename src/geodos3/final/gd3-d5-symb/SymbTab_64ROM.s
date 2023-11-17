﻿; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprünge im C64-Kernal.
:IOINIT			= $fda3
:CINT			= $ff81				;Reset: Timer, IO, PAL/NTSC, Bildschirm.
:SETMSG			= $ff90				;Dateiparameter definieren.
:SECOND			= $ff93				;Sekundär-Adresse nach LISTEN senden.
:TKSA			= $ff96				;Sekundär-Adresse nach TALK senden.
:ACPTR			= $ffa5				;Byte-Eingabe vom IEC-Bus.
:CIOUT			= $ffa8				;Byte-Ausgabe auf IEC-Bus.
:UNTALK			= $ffab				;UNTALK-Signal auf IEC-Bus senden.
:UNLSN			= $ffae				;UNLISTEN-Signal auf IEC-Bus senden.
:LISTEN			= $ffb1				;LISTEN-Signal auf IEC-Bus senden.
:TALK			= $ffb4				;TALK-Signal auf IEC-Bus senden.
:SETLFS			= $ffba				;Dateiparameter setzen.
:SETNAM			= $ffbd				;Dateiname setzen.
:OPENCHN		= $ffc0				;Datei öffnen.
:CLOSE			= $ffc3				;Datei schließen.
:CHKIN			= $ffc6				;Eingabefile setzen.
:CKOUT			= $ffc9				;Ausgabefile setzen.
:CLRCHN			= $ffcc				;Standard-I/O setzen.
:BSOUT			= $ffd2				;Zeichen ausgeben.
:LOAD			= $ffd5				;Datei laden.
:GETIN			= $ffe4				;Tastatur-Eingabe.
:CLALL			= $ffe7				;Alle Kanäle schließen.
