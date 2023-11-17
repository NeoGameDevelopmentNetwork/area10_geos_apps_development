; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- 1581-Laufwerke.

;--- Laufwerk für Symboltabellen,
;    Macros und AutoAssembler Dateien.
:DvPart_Symbol = 0
:DvAdr_Symbol  = 9
:DvDir_Symbol  b "",NULL

;--- Laufwerk für Quelltexte.
:DvPart_Kernal = 0
:DvAdr_Kernal  = 0
:DvDir_Kernal  b "",NULL
:DvPart_Prog   = 0
:DvAdr_Prog    = 0
:DvDir_Prog    b "",NULL
:DvPart_Config = 0
:DvAdr_Config  = 0
:DvDir_Config  b "",NULL
:DvPart_Disk   = 0
:DvAdr_Disk    = 0
:DvDir_Disk    b "",NULL
:DvPart_GDesk1 = 0
:DvAdr_GDesk1  = 0
:DvDir_GDesk1  b "",NULL
:DvPart_GDesk2 = 0
:DvAdr_GDesk2  = 0
:DvDir_GDesk2  b "",NULL

;--- Laufwerk für Ausgabe Programmcode.
:DvPart_Target = 0
:DvAdr_Target  = 8
:DvDir_Target  b "",NULL
