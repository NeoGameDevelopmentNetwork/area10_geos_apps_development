; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Diskettenfehler.
;*** Zeiger auf Dialogbox-Tabellen.
:DskErrVecTab		w Dlg_DiskError
			w Dlg_GEOS_ID_ERR
			w Dlg_EXTRACT_ERR
			w Dlg_ANALYZE_ERR
			w Dlg_CRCFILE_ERR

;*** Dialogbox: Diskettenfehler.
:Dlg_DiskError		b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w DskErrTitel
			b DBTXTSTR ,$10,$20
			w DlgT_01_01
			b DB_USR_ROUT
			w PrntErrCode
			b OK       ,$10,$48
			b NULL

;*** Dialogbox: Diskettenfehler.
:Dlg_GEOS_ID_ERR	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w DskErrTitel
			b DBTXTSTR ,$10,$20
			w DlgT_02_01
			b DBTXTSTR ,$10,$2a
			w DlgT_02_02
			b DB_USR_ROUT
			w PrntErrCode
			b OK       ,$10,$48
			b NULL

;*** Dialogbox: Diskettenfehler.
:Dlg_EXTRACT_ERR	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w DskErrTitel
			b DBTXTSTR ,$10,$20
			w DlgT_03_01
			b DBTXTSTR ,$10,$2a
			w DlgT_03_02
			b DB_USR_ROUT
			w PrntErrCode
			b OK       ,$10,$48
			b NULL

;*** Dialogbox: Diskettenfehler.
:Dlg_ANALYZE_ERR	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w DskErrTitel
			b DBTXTSTR ,$10,$20
			w DlgT_04_01
			b DBTXTSTR ,$10,$2a
			w DlgT_04_02
			b DB_USR_ROUT
			w PrntErrCode
			b OK       ,$10,$48
			b NULL

;*** Dialogbox: Diskettenfehler.
:Dlg_CRCFILE_ERR	b $81
			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR ,$10,$0b
			w DskErrTitel
			b DBTXTSTR ,$10,$20
			w DlgT_05_01
			b DBTXTSTR ,$10,$2a
			w DlgT_05_02
			b OK       ,$10,$48
			b NULL

;*** Dialogbox: Diskette wechseln.
:Dlg_InsertDisk		b %00000000
			b $30,$3f
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DB_USR_ROUT
			w Dlg_FlipDiskInit

			b DBTXTSTR ,$06,$0b
			w DlgT_06_01
			b DBTXTSTR ,$72,$0b
			w FNameStartMP

			b OK       ,$18 ! DOUBLE_B,$00
			b CANCEL   ,$1e ! DOUBLE_B,$00

			b DB_USR_ROUT
			w Dlg_FlipDiskCol

			b NULL
