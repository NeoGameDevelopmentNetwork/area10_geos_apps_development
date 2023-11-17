; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR   ,$10,$10
			w :1

			b DBTXTSTR   ,$10,$20
			w UCI_DATA_MSG
			b DBTXTSTR   ,$10,$2a
			w UCI_STATUS_MSG

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL
