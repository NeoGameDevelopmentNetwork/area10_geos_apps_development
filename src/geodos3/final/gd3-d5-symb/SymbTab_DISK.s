; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Einsprungadressen innerhalb Laufwerkstreiber.
:Get1stDirEntry		= $9030
:GetNxtDirEntry		= $9033
:GetBlock_dskBuf	= $903c
:PutBlock_dskBuf	= $903f
:AllocateBlock		= $9048
:ReadLink		= $904b
:GetBAMBlock		= $9056
:PutBAMBlock		= $9059
:SendCommand		= $906b
