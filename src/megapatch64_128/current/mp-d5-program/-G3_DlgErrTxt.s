; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Dialogbox: Fehler beim installieren des GEOS/MP3-Kernels.
:Dlg_RamVerError	b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Attention
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$30
			w :103
			b DBTXTSTR ,$0c,$3a
			w :104
			b DBTXTSTR ,$0c,$4a
			w Dlg_RBootGEOS1
			b DBTXTSTR ,$0c,$54
			w Dlg_RBootGEOS2
			b NULL

if Sprache = Deutsch
::101			b "Installation ist fehlgeschlagen. Das MegaPatch-",NULL
::102			b "Kernel konnte nicht in die Speichererweiterung",NULL
::103			b "übertragen werden!",NULL
::104			b "Bitte die Speichererweiterung auf Fehler prüfen!",NULL
endif

if Sprache = Englisch
::101			b "Installation has been failed. MegaPatch-kernel",NULL
::102			b "could not be stored in your ram-expansion!",NULL
::103			b "",NULL
::104			b "Please check the ram-expansion for errors!",NULL
endif

;*** Dialogbox: Diskettenfehler.
:Dlg_DiskError		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Attention
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$36
			w :103
			b DBTXTSTR ,$0c,$46
			w Dlg_RBootGEOS1
			b DBTXTSTR ,$0c,$50
			w Dlg_RBootGEOS2
			b DB_USR_ROUT
			w PrntDskErrCode
			b NULL

if Sprache = Deutsch
::101			b "Installation auf Grund eines Diskettenfehlers",NULL
::102			b "auf dem Startlaufwerk fehlgeschlagen.",NULL
::103			b "Fehlercode:",NULL
endif

if Sprache = Englisch
::101			b "Installation has been failed because a",NULL
::102			b "diskerror was detected!",NULL
::103			b "Code:",NULL
endif

;*** Dialogbox: Kein Start-Laufwerk gefunden.
:Dlg_NoDkDvErr		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Attention
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$30
			w :103
			b DBTXTSTR ,$0c,$46
			w Dlg_RBootGEOS1
			b DBTXTSTR ,$0c,$50
			w Dlg_RBootGEOS2
			b NULL

if Sprache = Deutsch
::101			b "Die Installation kann nicht fortgesetzt",NULL
::102			b "werden, da für das Start-Laufwerk kein",NULL
::103			b "Laufwerkstreiber gefunden wurde!",NULL
endif

if Sprache = Englisch
::101			b "The installation can not be continued",NULL
::102			b "because there was no disk-driver found",NULL
::103			b "for the current startup-drive!",NULL
endif

;*** Dialogbox: "Datei xy fehlt".
:Dlg_FNotFound		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Attention
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBVARSTR ,$2c,$36
			b r9L
			b DBTXTSTR ,$0c,$46
			w Dlg_RBootGEOS1
			b DBTXTSTR ,$0c,$50
			w Dlg_RBootGEOS2
			b NULL

if Sprache = Deutsch
::101			b "Installation fehlgeschlagen. Die Folgende Datei",NULL
::102			b "wurde nicht gefunden:",NULL
endif

if Sprache = Englisch
::101			b "Installation has been failed. The following",NULL
::102			b "file was not found:",NULL
endif

;*** Texte für alle Dialogboxen.
if Sprache = Deutsch
:Dlg_Attention		b PLAINTEXT,BOLDON
			b "ACHTUNG!",NULL
:Dlg_RBootGEOS1		b "Aktives Kernel wurde teilweise überschrieben,",NULL
:Dlg_RBootGEOS2		b "GEOS muß neu gestartet werden...",NULL
endif

if Sprache = Englisch
:Dlg_Attention		b PLAINTEXT,BOLDON
			b "ATTENTION!",NULL
:Dlg_RBootGEOS1		b "Active kernel has been partly overwritten.",NULL
:Dlg_RBootGEOS2		b "Please restart your GEOS-system...",NULL
endif
