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
:STATUS_H		= $30

;--- Fortschrittsbalken.
:STATUS_CNT_X1		= STATUS_X +16
:STATUS_CNT_X2		= (STATUS_X + STATUS_W) -24 -1
:STATUS_CNT_W		= (STATUS_CNT_X2 - STATUS_CNT_X1) +1
:STATUS_CNT_Y1		= (STATUS_Y + STATUS_H) -16
:STATUS_CNT_Y2		= (STATUS_Y + STATUS_H) -16 +8 -1

;--- Optional für StatusBox:
:INFO_X0		= STATUS_X +56
:INFO_Y1		= STATUS_Y +26

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	sysPrntInfoBox		;Status-Box anzeigen.
			jsr	sysPrntStatBar		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont

			LoadW	r0,jobInfTxCreate	;"DiskImage erstellen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxFile		;"DiskImage:"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,newImageName
			jmp	PutString

;*** Status-Box "Formatieren" anzeigen.
:DrawFormatBox		jsr	sysPrntInfoBox		;Status-Box anzeigen.

			jsr	UseSystemFont

			LoadW	r0,jobInfTxCreate	;"DiskImage erstellen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxFormat		;"DiskImage wird formatiert..."
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,infoTxWait		;"Bitte etwas Geduld!"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1 +10
			jmp	PutString

;*** Texte.
if LANG = LANG_DE
:jobInfTxCreate		b PLAINTEXT,BOLDON
			b "DISKIMAGE ERSTELLEN"
			b PLAINTEXT,NULL

:infoTxFile		b "DiskImage: ",NULL
:infoTxFormat		b "DiskImage wird formatiert...",NULL
:infoTxWait		b "Bitte etwas Geduld!",NULL
endif
if LANG = LANG_EN
:jobInfTxCreate		b PLAINTEXT,BOLDON
			b "CREATING DISK IMAGE"
			b PLAINTEXT,NULL

:infoTxFile		b "DiskImage: ",NULL
:infoTxFormat		b "Formatting disk image...",NULL
:infoTxWait		b "Please be patient!",NULL
endif
