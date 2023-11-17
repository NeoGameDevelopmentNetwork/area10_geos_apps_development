; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- RAMLink-Laufwerke.

;--- Laufwerke für Symboltabellen,
;    Makros und AutoAssembler Dateien.
:DvPart_Symbol  = 11
:DvAdr_Symbol   = 10
:DvDir_Symbol   b "",NULL

;--- Laufwerk für Quelltexte.
:DvPart_Main    = 12
:DvAdr_Main     = 11
:DvDir_Main     b "",NULL
:DvPart_Convert = 13
:DvAdr_Convert  = 11
:DvDir_Convert  b "",NULL
:DvPart_DosCbm  = 14
:DvAdr_DosCbm   = 11
:DvDir_DosCbm   b "",NULL
:DvPart_Tools   = 15
:DvAdr_Tools    = 11
:DvDir_Tools    b "",NULL

;--- Laufwerk für Ausgabe Programmcode.
:DvPart_Target  = 0
:DvAdr_Target   = 8
:DvDir_Target   b "",NULL
