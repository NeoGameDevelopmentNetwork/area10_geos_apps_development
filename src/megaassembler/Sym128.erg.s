; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Systemvariablen für den C128
; Version 13.07.1989
; Revision 07.10.2022:
; AccessCache, SetColorMode, ColorCard
; und ColorRectangle ergänzt.

:AccessCache = $c2ef
:ADD1_W = $2000
:ColorCard = $c2f8
:ColorRectangle = $c2fb
:DoBOp = $c2ec
:DOUBLE_B = $80
:DOUBLE_W = $8000
:graphMode = $3f
:HideOnlyMouse = $c2f2
:MoveBData = $c2e3
:NormalizeX = $c2e0
:SetColorMode = $c2f5
:SetMsePic		= $c2da
:SetNewMode = $c2dd
:SwapBData		= $c2e6
:TempHideMouse = $c2d7
:VerifyBData = $c2e9
