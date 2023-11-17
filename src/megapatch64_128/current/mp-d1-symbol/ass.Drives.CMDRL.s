; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Laufwerk für Symboltabellen,
;    Macros und AutoAssembler Dateien.

;RAMLink
:DvPart_Symbol = 11
:DvAdr_Symbol  = 10
:DvDir_Symbol  b "",NULL

;--- Laufwerk für Quelltexte

;RAMLink
:DvPart_Kernal = 12
:DvAdr_Kernal  = 11
:DvDir_Kernal  b "",NULL
:DvPart_System = 13
:DvAdr_System  = 11
:DvDir_System  b "",NULL
:DvPart_Disk   = 14
:DvAdr_Disk    = 11
:DvDir_Disk    b "",NULL
:DvPart_Prog   = 15
:DvAdr_Prog    = 11
:DvDir_Prog    b "",NULL

;--- Laufwerk für Bootpartition und
;    Ausgabe des Programmcodes

;RAMLink
:DvPart_Target = 0
:DvAdr_Target  = 8
:DvDir_Target  b "",NULL
