; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; GEOS-Symbole für Druckanwendungen.
;******************************************************************************

;*** Einsprünge im Druckertreiber.
:InitForPrint		= $7900
:StartPrint		= $7903
:PrintBuffer		= $7906
:StopPrint		= $7909
:GetDimensions		= $790c
:PrintASCII		= $790f
:StartASCII		= $7912
:SetNLQ			= $7915

;--- Ergänzung: 01.07.2018/M.Kanet
;In der Version 2003 wurde im Spooler eine neue Sub-Routine ergänzt.
;":PrintDATA" definiert den globalen Einsprungspunkt für diese Routine.
:PrintDATA		= $7918
