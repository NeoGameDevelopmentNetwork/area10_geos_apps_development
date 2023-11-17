; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- RAMDisk-Laufwerke.

;--- Laufwerke für Symboltabellen,
;    Makros und AutoAssembler Dateien.
:DvPart_Symbol  = 0
:DvAdr_Symbol   = 10
:DvDir_Symbol   b "",NULL

;--- Laufwerk für Quelltexte.
:DvPart_Main    = 0
:DvAdr_Main     = 11
:DvDir_Main     b "MAIN",NULL
:DvPart_Convert = 0
:DvAdr_Convert  = 11
:DvDir_Convert  b "CONVERT",NULL
:DvPart_DosCbm  = 0
:DvAdr_DosCbm   = 11
:DvDir_DosCbm   b "DOSCBM",NULL
:DvPart_Tools   = 0
:DvAdr_Tools    = 11
:DvDir_Tools    b "TOOLS",NULL

;--- Laufwerk für Ausgabe Programmcode.
:DvPart_Target  = 0
:DvAdr_Target   = 8
:DvDir_Target   b "",NULL
