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
:STATUS_H		= $40

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
:INFO_Y3		= STATUS_Y +48

;*** Status-Box anzeigen.
:DrawStatusBox		jsr	sysPrntInfoBox		;Status-Box anzeigen.
			jsr	sysPrntStatBar		;Fortschrittsbalken initialisieren.

			jsr	UseSystemFont		;GEOS-Font für Titel aktivieren.

			LoadW	r0,jobInfTxDelete	;"Leere Sektoren löschen"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxTrack		;"Spur:"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jmp	PutString

;*** Info-Box "Formatieren" anzeigen.
:DrawFormatBox		jsr	sysPrntInfoBox		;Status-Box anzeigen.

			jsr	UseSystemFont		;GEOS-Font aktivieren.

			LoadW	r0,jobInfTxFormat	;"Diskette formatieren"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,STATUS_Y +12
			jsr	PutString

			jsr	ResetFontGD		;GD-Font aktivieren.

			LoadW	r0,infoTxDrive		;"Laufwerk"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y1
			jsr	PutString

			LoadW	r0,textDrive		;"X:"
			LoadW	r11,INFO_X0
			jsr	PutString

			LoadW	r0,infoTxFormat		;"Disk wird formatiert"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y3
			jsr	PutString

			jmp	prntDiskInfo		;Disknamen ausgeben.

;*** Disk-/Verzeichnisname ausgeben.
:prntDiskInfo		LoadW	r0,infoTxDisk		;"Diskette"
			LoadW	r11,STATUS_X +8
			LoadB	r1H,INFO_Y2
			jsr	PutString

if FALSE
			ldx	#r1L			;Zeiger auf Diskname setzen.
			jsr	GetPtrCurDkNm

			LoadW	r0,curDiskName		;Diskname in Zwischenspeicher
			ldx	#r1L			;kopieren.
			ldy	#r0L
			jsr	SysCopyName
endif

			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y2
;			LoadW	r0,curDiskName
			LoadW	r0,textDrvName
			jmp	smallPutString		;Disk-/Verzeichnisname ausgeben.

;*** Status-Zeile aktualisieren.
;    Übergabe: r1L = Aktueller Track.
;              maxTrack = Max.Anzahl an Tracks auf Medium.
;
;Hinweis:
;r1/r4 dürfen nicht verändert werden:
;Enthalten Werte für WriteBlock!
;
:prntStatus		PushW	r1			;Zeiger Verzeichnis-Eintrag sichern.
			PushW	r4			;Adr. Zwischenspeicher sichern.

			MoveB	r1L,r0L			;Track-Adresse kopieren.
			ClrB	r0H

			LoadW	r11,INFO_X0
			LoadB	r1H,INFO_Y1
			lda	#$00 ! SET_LEFTJUST ! SET_SUPRESS
			jsr	PutDecimal

			LoadW	r0,infoTxMaxTr		;" von " ausgeben.
			jsr	PutString

			MoveB	maxTrack,r0L		;Max. Track einlesen.
			ClrB	r0H
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Max. Track ausgeben.

			lda	#" "
			jsr	SmallPutChar		;Anzeige korrigieren.

			jsr	sysPrntStatus		;Fortschrittsbalken aktulisieren.

			PopW	r4			;Zeiger Verz.Eintrag zurücksetzen.
			PopW	r1			;Adr. Zwischenspeicher zurücksetzen.

			rts

;*** Texte.
if LANG = LANG_DE
:jobInfTxFormat		b PLAINTEXT,BOLDON
			b "DISKETTE FORMATIEREN"
			b PLAINTEXT,NULL

:infoTxFormat		b "Bitte warten, Diskette wird formatierert...",NULL
:infoTxDrive		b "Laufwerk:",NULL

:jobInfTxDelete		b PLAINTEXT,BOLDON
			b "FREIE SEKTOREN LÖSCHEN"
			b PLAINTEXT,NULL

:infoTxDisk		b "Diskette: ",NULL
:infoTxTrack		b "Spur: ",NULL
:infoTxMaxTr		b " von ",NULL
endif
if LANG = LANG_EN
:jobInfTxFormat		b PLAINTEXT,BOLDON
			b "FORMAT DISK"
			b PLAINTEXT,NULL

:infoTxFormat		b "Please wait, disk will be formatted...",NULL
:infoTxDrive		b "Drive:",NULL

:jobInfTxDelete		b PLAINTEXT,BOLDON
			b "CLEAR UNUSED SECTORS"
			b PLAINTEXT,NULL

:infoTxDisk		b "Disk: ",NULL
:infoTxTrack		b "Track: ",NULL
:infoTxMaxTr		b " of ",NULL
endif

:curDiskName		s 17
