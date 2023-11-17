; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Laufwerk für Symboltabellen,
;    Macros und AutoAssembler Dateien.

;3x1581
:DvPart_Symbol = 0
:DvAdr_Symbol  = 9
:DvDir_Symbol  b "",NULL

;--- Laufwerk für Quelltexte

;3x1581
:DvPart_Kernal = 0
:DvAdr_Kernal  = 0
:DvDir_Kernal  b "",NULL
:DvPart_System = 0
:DvAdr_System  = 0
:DvDir_System  b "",NULL
:DvPart_Disk   = 0
:DvAdr_Disk    = 0
:DvDir_Disk    b "",NULL
:DvPart_Prog   = 0
:DvAdr_Prog    = 0
:DvDir_Prog    b "",NULL

;--- Laufwerk für Bootpartition und
;    Ausgabe des Programmcodes

;3x1581
:DvPart_Target = 0
:DvAdr_Target  = 8
:DvDir_Target  b "",NULL
