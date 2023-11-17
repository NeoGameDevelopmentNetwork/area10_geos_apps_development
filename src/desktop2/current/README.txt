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
DeskTop 64 V2.1

2023/03/25

Das ist der Source-Code zum GEOS DeskTop V2. Der Code ist für GEOS/MegaAssembler V4.9 oder höher optimiert.

Wenn der Source-Code bearbeitet werden soll, dann ist der Druckertreiber "MegaAss-100.prn" zu verwenden, da die Seiten teilweise mehr als 60 Zeilen lang sind.

Mit Hilfe des Source-Code kann sowohl die deutsche als auch die englische Version erzeugt werden.. GEOS/DeskTop64 V2.1 enthält einige Ergänzungen und Korrekturen, ist aber ausschließlich für den Einsatz unter GEOS 64 V2.x vorgesehen!

* Kein löschen von Systemdateien bei "ungültigen" Disketten.
* Kein schreiben der GEOS-Seriennummer auf Programmdisketten.
* Anzeige von sehr langen Druckernamen beim Druckersymbol.
* Fehler in Screenbuffer Routine für Dialogbox behoben.
* Optionen/Beenden ruft die Routine EnterDeskTop auf.
  (Rückkehr zur installierten DeskTop-Oberfläche).
* Nicht verwendeter Code wurde entfernt.
* Unnötige Befehle auf Grund von Makros entfernt.
* Unnötige Spungbefehle entfernt.

Eine Erweiterung auf vier Laufwerke oder Support für NativeMode ist nur mit großem Aufwand nachrüstbar, da an vielen Stellen nur auf 1541/71/81 getestet wird, was zusätzliche Sonderbehandlungen für NativeMode erfordern würde.

Zum assemblieren können die Dateien "ass.DESKTOIP_DE" oder "ass.DESKTOP_EN" und die AutoAssembler-Option des MegaAssembler verwendet werden.
ACHTUNG! Beide Versionen erzeugen eine Datei mit dem Namen "DESK TOP", da dies die Standardvorgabe des GEOS-Kernal ist. Sollen beide Versionen assembliert werden, dann muss die zuerst erstellte Datei nach dem assemblieren umbenannt werden. Diese Datei wird vom GEOS-Kernal dann allerdings nicht mehr erkannt.

Über das Programm "RunDESKTOP" kann DESKTOP auch von anderen System-Oberflächen aus gestartet werden. Dabei wird nach der GEOS-Klasse von "DESK TOP" gesucht, der Dateiname spielt dabei keine Rolle.

Markus Kanet
