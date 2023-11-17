; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Laufwerkstreiber für Bootdiskette.
;Die hier erzeugten Treiberdateien
;werden in s.GEOS64/128.1 eingebunden.
;Im AutoAssembler-Modus sollten die
;hier erzeugten Dateien in -A3_Prog#3.s
;auch wieder gelöscht werden!

;Treiberabhängig ist auch das TurboDOS-
;Modul zu kompilieren!
;			b $f0,"s.1541_Turbo",$00
;			b $f0,"s.1541",$00
;			b $f0,"s.1571_Turbo",$00
;			b $f0,"s.1571",$00

;TurboDOS 1581 für 1581 und CMD FD/HD
;			b $f0,"s.1581_Turbo",$00
;			b $f0,"s.1581",$00
;			b $f0,"s.FD41",$00
;			b $f0,"s.FD71",$00
;			b $f0,"s.FD81",$00
;			b $f0,"s.FDNM",$00
;CMD-HD-Kabel wird nur innerhalb GEOS unterstützt.
;Beim Boot-Vorgang wird TurboDOS verwendet.
;			b $f0,"s.HD41",$00
;			b $f0,"s.HD71",$00
;			b $f0,"s.HD81",$00
;			b $f0,"s.HDNM",$00

;RamLink benötigt kein TurboDOS.
;			b $f0,"s.RL41",$00
;			b $f0,"s.RL71",$00
			b $f0,"s.RL81",$00
;			b $f0,"s.RLNM",$00
