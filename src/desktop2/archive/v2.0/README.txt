; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

Source-Code DESK TOP V2

Reassembled (w)2020-2023:
Markus Kanet

Version:
"deskTop  GE V2.0" - 11.10.1988 / 17:02
"deskTop AM  V2.0" - 19.08.1988 / 13:35

2023/03/25

Das ist der Source-Code zum GEOS DeskTop V2. Der Code ist für GEOS/MegaAssembler V4.9 oder höher optimiert.

Wenn der Source-Code bearbeitet werden soll, dann ist der Druckertreiber "MegaAss-100.prn" zu verwenden, da die Seiten teilweise mehr als 60 Zeilen lang sind.

Der Source-Code erzeugt ein 1:1-Abbild der originalen, deutschen DeskTop-Datei, inkl. Programmier- und Tippfehler. Im Text finden sich an einigen Stellen entsprechende Hinweise dazu.

Eine englische Version von DeskTop V2 kann mit Hilfe dieses Source-Code ebenfalls erzeugt werden. Diese Version wird aber auf Grundlage des deutschen Source-Code übersetzt, da dieser einige Optimierungen gegenüber dem Code der US-Version enthält. Die englische Version ist daher kein 1:1-Abbild der Original-Version.

Eine Erweiterung auf vier Laufwerke oder Support für NativeMode ist nur mit großem Aufwand nachrüstbar, da an vielen Stellen nur auf 1541/71/81 getestet wird, was zusätzliche Sonderbehandlungen für NativeMode erfordern würde.

Zum assemblieren können die Dateien "ass.DESKTOIP_DE" oder "ass.DESKTOP_EN" und die AutoAssembler-Option des MegaAssembler verwendet werden.
ACHTUNG! Beide Versionen erzeugen eine Datei mit dem Namen "DESK TOP", da dies die Standardvorgabe des GEOS-Kernal ist. Sollen beide Versionen assembliert werden, dann muss die zuerst erstellte Datei nach dem assemblieren umbenannt werden. Diese Datei wird vom GEOS-Kernal dann allerdings nicht mehr erkannt.

Markus Kanet
