; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Modul-Information:
;* Farbprofil aus DACC laden.
;* Farbprofil in DACC speichern.

;*** Symboltabellen.
if .p
;			t "opt.GDOSl10n.ext"
			t "SymbTab_GDOS"
			t "SymbTab_1"
			t "SymbTab_GTYP"
			t "SymbTab_MMAP"
			t "SymbTab_GRFX"
			t "SymbTab_GSPR"
			t "MacTab"

;--- Externe Labels.
			t "s.GD.10.Core.ext"
endif

;*** GEOS-Header.
			n "obj.GD53"
			f DATA

			o VLIR_BASE

;*** Sprungtabelle.
:VlirJumpTable		jmp	xSAVE_COLOR		;Farbprofil in DACC speichern.
			jmp	xLOAD_COLOR		;Farbprofil aus DACC laden.

;*** Farbprofil speichern/speichern.
:xSAVE_COLOR		ldy	#jobStash
			b $2c
:xLOAD_COLOR		ldy	#jobFetch
			jsr	doColorRAMjob		;Farbprofil laden/speichern.

;HINWEIS:
;Auch beim speichern eines Farbprofils
;die Systemfarben übernehmen.
;Speichern erfolgt nur nach dem öffnen
;eines Farbprofils vom DeskTop aus.

;*** Systemfarben übernehmen.
:applyColors		jsr	i_MoveData		;GEOS-Farben übernehmen.
			w	GD_COLOR_GEOS
			w	COLVAR_BASE
			w	COLVAR_SIZE

			lda	C_GEOS_PATTERN		;GEOS-Füllmuster übernehmen.
			sta	BackScrPattern

			lda	C_GEOS_MOUSE		;Standardfarbe Mauszeiger überhmen.
			sta	C_Mouse

			php				;Systemfarben anwenden.
			sei

			ldx	CPU_DATA
			lda	#%00110101
			sta	CPU_DATA

			lda	C_GEOS_MOUSE
			sta	mob0clr
			sta	mob1clr

			lda	C_GEOS_FRAME
			sta	extclr

			stx	CPU_DATA

			plp

			ldx	#NO_ERROR		;Kein Fehler.
			rts

;** Farbprofil/Speichertransfer.
:doColorRAMjob		LoadW	r0,GD_PROFILE
			LoadW	r1,R3A_CPROFILE
			LoadW	r2,R3S_CPROFILE

			lda	MP3_64K_DATA
			sta	r3L

;			ldy	#jobFetch
;			ldy	#jobStash
			jmp	DoRAMOp
