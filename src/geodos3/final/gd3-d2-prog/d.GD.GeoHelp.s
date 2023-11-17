; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Dialogboxen
;******************************************************************************
;*** Dialogbox: "GeoHelp fehlerhaft".
:Dlg_SysErrBox		b %01100001
			b $30,$97
			w $0030,$010f

			b DB_USR_ROUT
			w Dlg_DrawError
			b DBTXTSTR ,$0c,$0b
			w D00a
			b DBTXTSTR ,$28,$20
			w D02a
			b DBTXTSTR ,$28,$2a
			w D02b
			b DBTXTSTR ,$28,$34
			w D02c
			b OK       ,$14,$50
			b NULL

;*** Dialogbox: "Auslagerungsdatei nicht erstellt".
:Dlg_PrnSwapErr		b %01100001
			b $30,$97
			w $0030,$010f

			b DB_USR_ROUT
			w Dlg_DrawError
			b DBTXTSTR ,$0c,$0b
			w D00a
			b DBTXTSTR ,$28,$20
			w D03a
			b DBTXTSTR ,$28,$2a
			w D03b
			b DBTXTSTR ,$28,$34
			w D03c
			b OK       ,$14,$50
			b NULL

;*** Dialogbox: "Druckertreiber nicht geladen".
:Dlg_LdPrnDrvErr	b %01100001
			b $30,$97
			w $0030,$010f

			b DB_USR_ROUT
			w Dlg_DrawError
			b DBTXTSTR ,$0c,$0b
			w D00a
			b DBTXTSTR ,$28,$20
			w D04a
			b DBTXTSTR ,$28,$2a
			w D04b
			b DBTXTSTR ,$28,$34
			w D04c
			b OK       ,$14,$50
			b NULL
