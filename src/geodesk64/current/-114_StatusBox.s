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
:INFO_X1		= STATUS_X +96
:INFO_Y1		= STATUS_Y +26
:INFO_Y2		= STATUS_Y +36
:INFO_Y3		= STATUS_Y +46
:INFO_Y4		= STATUS_Y +56

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	sysPrntInfoBox		;Status-Box anzeigen.
			jsr	sysPrntStatBar		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont		;GEOS-Font für Titel aktivieren.

			lda	#<jobInfTxCopy		;"Dateien kopieren"
			ldx	#>jobInfTxCopy
			bit	flagMoveFiles
			bpl	:1
			lda	#<jobInfTxMove		;"Dateien verschieben"
			ldx	#>jobInfTxMove
::1			sta	r0L
			stx	r0H
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
			jsr	PutString

			LoadW	r0,infoTxBlocks		;"Blocks"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y4
			jsr	PutString

			LoadW	r0,infoTxStruct		;"Typ"
			LoadW	r11,STATUS_X +80
			LoadB	r1H,INFO_Y4
			jmp	PutString		;Titelzeile ausgeben.

;*** Anzeigebereich Dateistruktur löschen.
:clrFStructInfo		lda	#$00
			jsr	SetPattern

			jsr	i_Rectangle
			b	INFO_Y4 -6
			b	INFO_Y4 +1
			w	INFO_X1
			w	(STATUS_X + STATUS_W) -8
			rts

;*** Texte.
if LANG = LANG_DE
:jobInfTxCopy		b PLAINTEXT,BOLDON
			b "DATEIEN KOPIEREN"
			b PLAINTEXT,NULL
:jobInfTxMove		b PLAINTEXT,BOLDON
			b "DATEIEN VERSCHIEBEN"
			b PLAINTEXT,NULL

:infoTxFile		b "Datei: ",NULL
:infoTxDir		b "Verzeichnis: ",NULL
:infoTxDisk		b "Diskette: ",NULL
:infoTxRemain		b "Verbleibend: ",NULL
:infoTxBlocks		b "Blocks: ",NULL
:infoTxStruct		b "Typ: ",NULL
endif
if LANG = LANG_EN
:jobInfTxCopy		b PLAINTEXT,BOLDON
			b "COPYING FILES"
			b PLAINTEXT,NULL
:jobInfTxMove		b PLAINTEXT,BOLDON
			b "MOVING FILES"
			b PLAINTEXT,NULL

:infoTxFile		b "File: ",NULL
:infoTxDir		b "Directory: ",NULL
:infoTxDisk		b "Disk: ",NULL
:infoTxRemain		b "Remaining: ",NULL
:infoTxBlocks		b "Blocks: ",NULL
:infoTxStruct		b "Type: ",NULL
endif

:curDiskName		s 17
