; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- RAMLink-Laufwerke.

;--- Laufwerk für Symboltabellen,
;    Macros und AutoAssembler Dateien.
:DvPart_Symbol = 10
:DvAdr_Symbol  = 10
:DvDir_Symbol  b "",NULL

;--- Laufwerk für Quelltexte.
:DvPart_Kernal = 11
:DvAdr_Kernal  = 11
:DvDir_Kernal  b "",NULL
:DvPart_Prog   = 12
:DvAdr_Prog    = 11
:DvDir_Prog    b "",NULL
:DvPart_Config = 13
:DvAdr_Config  = 11
:DvDir_Config  b "",NULL
:DvPart_Disk   = 14
:DvAdr_Disk    = 11
:DvDir_Disk    b "",NULL
:DvPart_GDesk1 = 15
:DvAdr_GDesk1  = 11
:DvDir_GDesk1  b "",NULL
:DvPart_GDesk2 = 16
:DvAdr_GDesk2  = 11
:DvDir_GDesk2  b "",NULL

;--- Laufwerk für Ausgabe Programmcode.
:DvPart_Target = 0
:DvAdr_Target  = 8
:DvDir_Target  b "",NULL
