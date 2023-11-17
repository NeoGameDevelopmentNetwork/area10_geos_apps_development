; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Liste mit Partitions-Typen.
:DImgTypeList		b "??647181NP??????"		;SD2IEC.

;*** DiskImage-Typ.
:DiskImgTyp		b $00				;$01-$04 für DiskImage-Typ.

;*** Partitions-Verzeichnis abrufen.
:FComDImgList		b "$:*.D??=P",NULL		;Nur DiskImages.
:FComSDirList		b "$:*=B",NULL			;Nur Verzeichnisse.

;*** Anzahl Dateien und Verzeichnisse.
:cntEntries		b $00,$00			;Dateien/Verzeichnisse getrennt.
:ListEntries		b $00				;Anzahl Gesamteinträge.

;*** Verzeichnis-Typ.
:ReadDirMode		b $00				;$00=Dateien, $FF=Verzeichnisse.

;*** Befehle zum DiskImage-Wechsel.
:FComCDRoot		w $0004				;Befehl: Zu "ROOT" wechseln.
			b "CD//"
:FComExitDImg		w $0003				;Befehl: Eine Ebene zurück.
			b "CD",$5f

;*** SD2IEC-DiskImage/Verzeichnis-Befehl.
:FComCDir		w $0000				;Befehl: Verzeichnis/Image wechseln.
			b "CD:"
			s 17

;*** Zwischenspeicher für Partitionsdaten.
:partEntryBuf		s 30

;*** Größe für 1541/71/81-Partitionen.
:partSizeData		w 684				;Anzahl Blocks: 1541.
			w 1368				;Anzahl Blocks: 1571.
			w 3200				;Anzahl Blocks: 1581.

;*** Partitionsgröße.
:Blocks			w $0000				;Anzahl Blocks letzter Eintrag.
