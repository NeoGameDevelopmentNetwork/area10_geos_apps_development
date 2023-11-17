; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dialogbox: Status anzeigen.
:dBoxChangeDir		b %10000001

			b DBTXTSTR   ,$10,$10
			w :1

			b DB_USR_ROUT
			w uChangeDir
			b DBTXTSTR   ,$10,$20
			w :2
			b DBTXTSTR   ,$28,$20
			w uPathDir
			b DBTXTSTR   ,$10,$2a
			w UCI_STATUS_MSG

			b DB_USR_ROUT
			w uGetPath
			b DBTXTSTR   ,$10,$38
			w :3
			b DBTXTSTR   ,$28,$38
			w UCI_DATA_MSG
			b DBTXTSTR   ,$10,$42
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2			b "CD: ",NULL
::3			b "$: ",NULL
