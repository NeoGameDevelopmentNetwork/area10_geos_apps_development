; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Variablen für Status-Box:
:STATUS_X		= $0040
:STATUS_W		= $00c0
:STATUS_Y		= $30
:STATUS_H		= $50

;--- Fortschrittsbalken.
:STATUS_CNT_X1		= STATUS_X +16
:STATUS_CNT_X2		= (STATUS_X + STATUS_W) -24 -1
:STATUS_CNT_W		= (STATUS_CNT_X2 - STATUS_CNT_X1) +1
:STATUS_CNT_Y1		= (STATUS_Y + STATUS_H) -16
:STATUS_CNT_Y2		= (STATUS_Y + STATUS_H) -16 +8 -1

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_Y1		= STATUS_Y +26
:INFO_Y2		= STATUS_Y +36
:INFO_Y3		= STATUS_Y +46

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	sysPrntInfoBox		;Status-Box anzeigen.
			jsr	sysPrntStatBar		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont

			LoadW	r0,jobInfTxDelete	;"Dateien löschen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxRemain		;"Auswahl:"
			LoadW	r11,STATUS_X +8		;(Anzahl verbleibender Dateien)
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,infoTxFile		;"Datei"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y3
			jmp	PutString

;*** Texte.
if LANG = LANG_DE
:jobInfTxDelete		b PLAINTEXT,BOLDON
			b "DATEIEN LÖSCHEN"
			b PLAINTEXT,NULL

:infoTxFile		b "Datei: ",NULL
:infoTxDir		b "Verzeichnis: ",NULL
:infoTxDisk		b "Diskette: ",NULL
:infoTxRemain		b "Verbleibend: ",NULL
endif
if LANG = LANG_EN
:jobInfTxDelete		b PLAINTEXT,BOLDON
			b "DELETING FILES"
			b PLAINTEXT,NULL

:infoTxFile		b "Filename: ",NULL
:infoTxDir		b "Directory: ",NULL
:infoTxDisk		b "Disk: ",NULL
:infoTxRemain		b "Remaining: ",NULL
endif

:curDiskName		s 17
