; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Partitions-Informationen löschen.
; Datum			: 05.07.97
; Aufruf		: JSR  ClrPartInfo
; Übergabe		: -
; Rückgabe		: -
; Verändert		: AKKU,xReg,yReg
;			  r0  bis r2
; Variablen		: -Part_InfoDaten Aktuelle Partition
; Routinen		: -i_FillRam Speicherbereich löschen
;******************************************************************************

;*** Neue Partition auf Laufwerk anmelden.
.ClrPartInfo		jsr	i_FillRam
			w	$0020
			w	Part_Info +2
			b	$00
			rts
