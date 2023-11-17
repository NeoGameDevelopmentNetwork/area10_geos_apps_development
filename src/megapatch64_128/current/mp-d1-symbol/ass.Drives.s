; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Laufwerk für Symboltabellen,
;    Macros und AutoAssembler Dateien.

;2xRAMNative
:DvPart_Symbol = 0
:DvAdr_Symbol  = 10
:DvDir_Symbol  b "",NULL

;--- Laufwerk für Quelltexte

;2xRAMNative
:DvPart_Kernal = 0
:DvAdr_Kernal  = 11
:DvDir_Kernal  b "kernal",NULL
:DvPart_System = 0
:DvAdr_System  = 11
:DvDir_System  b "system",NULL
:DvPart_Disk   = 0
:DvAdr_Disk    = 11
:DvDir_Disk    b "disk",NULL
:DvPart_Prog   = 0
:DvAdr_Prog    = 11
:DvDir_Prog    b "program",NULL

;--- Laufwerk für Bootpartition und
;    Ausgabe des Programmcodes

;2xRAMNative
:DvPart_Target = 0
:DvAdr_Target  = 8
:DvDir_Target  b "",NULL
