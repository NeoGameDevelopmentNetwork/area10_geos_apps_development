; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Ladeadresse für BASIC-Programm.
:BASIC_LOAD		b $01,$08

;*** Kopfdaten BASIC-Zeile.
;    Nur wirksam, wenn die Startdatei über "LOAD'name',8" an den Beginn
;    des BASIC-Speichers geladen wird.

::L0801			w $080b				;Link-Pointer auf nächste Zeile.
::L0803			w $0040				;Zeilen-Nr.

;*** BASIC-Zeile: SYS "GD.RBOOT",PEEK(165),1
::L0805			b $9e,$32,$30,$36,$31,$00

;*** Ende BASIC-Programm markieren.
::L080B			w $0000

;*** Start-Programm für GEOS aufrufen.
:JMPTAB			jmp MainInit
