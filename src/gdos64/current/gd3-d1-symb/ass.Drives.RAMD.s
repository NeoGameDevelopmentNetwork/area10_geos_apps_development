; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- RAM-Laufwerke.

;--- Laufwerk für Symboltabellen,
;    Macros und AutoAssembler Dateien.
:DvPart_Symbol = 0
:DvAdr_Symbol  = 10
:DvDir_Symbol  b "",NULL

;--- Laufwerk für Quelltexte.
:DvPart_Kernal = 0
:DvAdr_Kernal  = 11
:DvDir_Kernal  b "kernal",NULL
:DvPart_Prog   = 0
:DvAdr_Prog    = 11
:DvDir_Prog    b "program",NULL
:DvPart_Config = 0
:DvAdr_Config  = 11
:DvDir_Config  b "config",NULL
:DvPart_Disk   = 0
:DvAdr_Disk    = 11
:DvDir_Disk    b "disk",NULL
:DvPart_GDesk1 = 0
:DvAdr_GDesk1  = 11
:DvDir_GDesk1  b "geodesk1",NULL
:DvPart_GDesk2 = 0
:DvAdr_GDesk2  = 11
:DvDir_GDesk2  b "geodesk2",NULL

;--- Laufwerk für Ausgabe Programmcode.
:DvPart_Target = 0
:DvAdr_Target  = 8
:DvDir_Target  b "",NULL
