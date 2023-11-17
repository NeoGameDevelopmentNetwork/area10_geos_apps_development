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

;--- Laufwerk für Quelltexte.
:DvPart_Kernal = 0
:DvAdr_Kernal  = 11
:DvPart_System = 0
:DvAdr_System  = 11
:DvPart_Prog   = 0
:DvAdr_Prog    = 11
:DvPart_Disk   = 0
:DvAdr_Disk    = 11
:DvPart_Config = 0
:DvAdr_Config  = 11

;--- Laufwerk für Bootpartition und
;    Ausgabe des Programmcodes.
:DvPart_Target = 0
:DvAdr_Target  = 8
