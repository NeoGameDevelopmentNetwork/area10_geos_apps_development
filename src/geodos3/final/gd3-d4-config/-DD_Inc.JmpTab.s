; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Haupt-Sprungtabelle.
;******************************************************************************
:JMP_INSTALL		jmp	APPL_DEV_INSTALL	;Laufwerk installieren.
:JMP_INSTALL_CFG	jmp	CFG_DEV_INSTALL		;Installation über GD.CONFIG.
:JMP_TESTMODE		jmp	INIT_DEV_TEST		;Nur Laufwerkmodus testen.
;******************************************************************************
