; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerkstreiber konfigurieren:

;--- Interne Versionsnummer.
:DISKDRV_VERSION	= $30

;**************************************
;***   E X P E R I M E N T E L L!   ***
;**************************************
;--- Shared/Dir-Support (GEOS-Disk V2):
;
;Hinweis: Nur für RAMNative-Treiber!
;Nur zu Testzwecken, wird nicht mehr
;weiterentwickelt/getestet!
;
;Ist Shared/Dir=Enabled, dann wird ein
;systemweites Verzeichnis verwendet um
;zusätzliche Dateien im aktiven Unter-
;verzeichnis einzublenden.
;
;Der Zeiger liegt in Byte 203/204 des
;NativeMode-ROOT-Sektor $01/$01.
;Zusätzlich wird in Byte 218-220 die
;Kennung "2.0" erwartet.
;
;Der Zeiger entspricht den Bytes 0/1
;des Verzeichnis-Headers = Tr/Se auf
;den ersten Verzeichnisblock.
;
;Im Hauptverzeichnis und im system-
;weiten Unterverzeichnis wird nur der
;Borderblock angezeigt.
;Eine V2-Diskette sollte keine Dateien
;im BoderBlock speichern, da diese in
;anderen Unterverzeichnissen nicht mehr
;angezeigt werden.
;Der Inhalt des Borderblock wird nur
;bei V1-Disketten weiterhin in allen
;Unterverzeichnissen angezeigt.
;
;(Nur Werte von $x1xx-$xFxx möglich!)
:SHAREDDIR_ENABLED	= $0400
:SHAREDDIR_DISABLED	= $0800

:TEST_RAMNM_SHARED	= SHAREDDIR_DISABLED
;**************************************
