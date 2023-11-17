; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Infobox MegaAssembler.
			b $81
			b DBTXTSTR    ,$10,$0e
			w :1
			b DBTXTSTR    ,$10,$1c
			w :2
			b DBTXTSTR    ,$10,$27
			w :3
			b DBTXTSTR    ,$10,$32
			w :4
			b DBTXTSTR    ,$10,$42
			w :5
			b DBTXTSTR    ,$10,$4d
			w :6
			b DBTXTSTR    ,$10,$58
			w :7
			b DBSYSOPV
			b NULL

::1			b PLAINTEXT,BOLDON
			b "MegaAssembler V"
			b VMajor
			b "."
			b VMinor
			b PLAINTEXT
			b " (Build:"
			b VBuild1
			b VBuild2
			b VBuild3
			b VBuild4
			b VBuild5
			b VBuild6
			b ")"
			b NULL
::2			b "MegaAssembler V2.0 von:",NULL
::3			b "Knupe, Ciprina, Bonse, Goehrke",NULL
::4			b "(c) 1989: Markt & Technik",NULL
::5			b "Update auf MegaAssembler V3/4/5,",NULL
::6			b "Fehlerbeseitigung und Erweiterung:",NULL
::7			b "1997-2023: Markus Kanet",NULL
