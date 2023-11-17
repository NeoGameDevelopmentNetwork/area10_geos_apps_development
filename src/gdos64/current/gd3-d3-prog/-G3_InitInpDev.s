; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Eingabetreiber beibehalten
:RetainInpDev		lda	Device_Boot
			jsr	SetDevice		;Startlaufwerk öffnen.
			jsr	OpenDisk		;Diskette öffnen.

			jsr	DetectInpDev		;Eingabetreiber wählen.
							;Ergebnis im Y-Reg!

			lda	#< txInpDev2a		;Dialogbox-Text für Joystick.
			ldx	#> txInpDev2a
			cpy	#FALSE			;Joytick ?
			beq	:1			; => Ja, weiter...
			lda	#< txInpDev2b		;Dialogbox-Text für Maus.
			ldx	#> txInpDev2b
::1			sta	r10L			;Zeiger für Dialogbox-Text setzen.
			stx	r10H

			lda	#< newInpDevJoy		;Dateiname für Joystick.
			ldx	#> newInpDevJoy
			cpy	#FALSE			;Joytick ?
			beq	:2			; => Ja, weiter...
			lda	#< newInpDevMse		;Dateiname für Maus.
			ldx	#> newInpDevMse
::2			sta	r1L			;Zeiger für Dateiname setzen.
			stx	r1H

;			LoadW	r1,newInpDevMse		;Dateiname für neuen Eingabetreiber
			LoadW	r2,nameNewInpDev	;in Zwischenspeicher kopieren.
			ldx	#r1L
			ldy	#r2L
			jsr	CopyString

			lda	inputDevName		;Name Eingabegerät definiert ?
			beq	:4			; => Nein, weiter..

			ldy	#0
::3			lda	inputDevName,x		;Name des aktuellen Eingabegerätes
			sta	stdInpDevName,x		;als Vorgabe für gespeicherten
			beq	:4			;Treiber beibehalten.
			inx
			cpx	#16 +1
			bcc	:3

::4			lda	#< nameNewInpDev	;Neuen Eingabetreiber auf
			ldx	#> nameNewInpDev	;Diskette suchen.
			jsr	FindFileAX
;			txa				;Eingabetreiber gefunden ?
			bne	:keepdev		; => Nein, Treiber nicht ersetzen.

			LoadW	r0,Dlg_AskInpDev
			jsr	DoDlgBox		;Abfrage: Treiber installieren ?

			lda	sysDBData
			cmp	#NO
			beq	:keepdev		; => Nein, weiter...

;--- Neuen Treiber auf Disk suchen.
::newdev		ldx	#0
::5			lda	nameNewInpDev,x		;Maustreiber-Bezeichnung
			sta	inputDevName,x		;kopieren.
			beq	:search
			inx
			cpx	#16 +1
			bcc	:5

;--- Aktuellen Treiber auf Disk suchen.
::search		jsr	SearchInpDevice		;Aktuellen Eingabetreiber
;			txa				;auf Diskette suchen.
			bne	:keepdev		; => Nicht gefunden, weiter...

;			ldx	#$00
			stx	r10L
			stx	r10H
			inx
			stx	r7H
			LoadB	r7L,INPUT_DEVICE
			LoadW	r6 ,firstInpDev		;Ersten Eingabetreiber auf
			jsr	FindFTypes		;Diskette suchen.
			txa				;Eingabetreiber gefunden ?
			bne	:keepdev		; => Nein, weiter...

			LoadW	r0,firstInpDev		;Ist aktueller Eingabetreiber der
			LoadW	r1,inputDevName		;erste Eingabetreiber auf Disk ?
			ldx	#r0L
			ldy	#r1L
			jsr	CmpString
			beq	:done			; => Ja, weiter...

			jsr	SwapInpDevice		;Ersten Eingabetreiber auf Disk
			jmp	:done			;mit aktuellem Treiber tauschen.

;--- Vorhandenen Treiber speichern.
::keepdev		ldx	inputDevName		;Maustreiber installiert ?
			bne	:7			; => Ja, weiter...
::6			lda	stdInpDevName,x
			sta	inputDevName  ,x
			beq	:7
			inx
			cpx	#16 +1
			bcc	:6
			bcs	:replace

::7			lda	#< inputDevName		;Eingabetreiber auf
			ldx	#> inputDevName		;Diskette suchen.
			jsr	FindFileAX
;			txa				;Eingabetreiber gefunden ?
			beq	:ok			; => Ja, Treiber nicht ersetzen.

::replace		LoadW	r0,inputDevName		;Vorhandene Treiberdatei löschen.
			jsr	DeleteFile

			LoadW	r9  ,HdrInputDev	;Aktiven Treiber speichern und
			LoadB	r10L,$00		;erneut testen.
			jsr	SaveFile
::ok			jmp	:search

;--- Eingabetreiber installiert.
::done			rts

;*** Aktiven Eingabetreiber erkennen.
:DetectInpDev		php
			sei

			lda	CPU_DATA
			pha
			lda	#IO_IN			;I/O-Bereich einblenden.
			sta	CPU_DATA

			ldy	#$04
			lda	#%11111111		;Abfrage Joystick/Maus.
			cmp	paddleX
			bne	:1
			cmp	paddleY
			bne	:1

			ldy	#FALSE			;Joystick.
			b $2c
::1			ldy	#TRUE			;Maus.

			pla
			sta	CPU_DATA		;CPU-Register zurücksetzen.

			plp
			rts

;*** Aktuellen Treiber auf Disk suchen.
:SearchInpDevice	lda	#< inputDevName
			ldx	#> inputDevName
			jmp	FindFileAX

;*** Ersten Eingabetreiber mit aktuellem Eingabetreiber auf Disk tauschen.
:SwapInpDevice		jsr	SearchInpDevice		;Aktuellen Eingabetreiber
;			txa				;auf Diskette suchen.
			bne	:err			; => Nicht gefunden, Ende...

			lda	r1L			;Position und Inhalt des Verzeichnis
			sta	inputDevTr		;eintrages zwischenspeichern.
			lda	r1H
			sta	inputDevSe
			lda	r5L
			sta	inputDevAddr +0
			lda	r5H
			sta	inputDevAddr +1

			ldy	#30 -1
::1			lda	(r5L)        ,y
			sta	inputDevEntry,y
			dey
			bpl	:1

			lda	#< firstInpDev		;Ersten Eingabetreiber auf
			ldx	#> firstInpDev		;Diskette suchen.
			jsr	FindFileAX
;			txa				;Eingabetreiber gefunden ?
			beq	:found			; => Ja, weiter...
::err			rts

::found			ldy	#30 -1			;Verzeichniseinträge tauschen.
::2			lda	inputDevEntry,y
			pha
			lda	(r5L)        ,y
			sta	inputDevEntry,y
			pla
			sta	(r5L)        ,y
			dey
			bpl	:2

			jsr	PutBlock

			lda	inputDevTr
			sta	r1L
			lda	inputDevSe
			sta	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			lda	inputDevAddr +0
			sta	r5L
			lda	inputDevAddr +1
			sta	r5H

			ldy	#30 -1
::3			lda	inputDevEntry,y
			sta	(r5L)        ,y
			dey
			bpl	:3

			jmp	PutBlock

;*** Eingabetreiber in GD.INI löschen.
;Damit wird nach dem Update der erste
;Eingabetreiber auf Disk installiert.
:ClrConfigInput		jsr	FindGDINI		;GD.INI suchen.
			txa				;Datei gefunden/gültig?
			bne	:err			; => Nein, Abbruch...

;			lda	dirEntryBuf +1		;Ersten Programmsektor einlesen.
;			sta	r1L
;			lda	dirEntryBuf +2
;			sta	r1H
;			LoadW	r4,diskBlkBuf
;			jsr	GetBlock
;			txa
;			bne	:err

;			lda	#NULL			;Name Eingabetreiber löschen.
			sta	diskBlkBuf +2 +184

			jsr	PutBlock
;			txa
;			bne	:err

::err			rts

;*** Dialogbox: Neuen Eingabetreiber aktivieren ?
:Dlg_AskInpDev		b %00000000
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w DlgBoxColor2
			b DBTXTSTR ,$0c,$10
			w Dlg_Information

			b DBTXTSTR ,$0c,$20
			w txInpDev1
			b DBVARSTR ,$0c,$2a
			b r10L

			b DBTXTSTR ,$0c,$36
			w txInpDev3

			b DBTXTSTR ,$0c,$42
			w textCurInpDev
			b DBTXTSTR ,$0c,$4c
			w textNewInpDev

			b DBTXTSTR ,$0c,$5a
			w txInpDev4

			b NO       ,$02,$60
			b YES      ,$1c,$60
			b NULL

if LANG = LANG_DE
:txInpDev1		b PLAINTEXT
			b "Wenn Sie weitermachen, wird ein Eingabetreiber für",NULL
:txInpDev2a		b "einen Joystick und kompatible Geräte an Port1 installiert.",NULL
:txInpDev2b		b "eine C=1351-Maus und kompatible Geräte an Port1 installiert.",NULL
:txInpDev3		b "'NEIN' wählen um den aktiven Eingabetreiber beizubehalten.",NULL
:txInpDev4		b BOLDON
			b "Neuen Eingabetreiber aktivieren?",NULL
endif

if LANG = LANG_EN
:txInpDev1		b PLAINTEXT
			b "If you continue with the installation, an input driver for",NULL
:txInpDev2a		b "joystick and compatible devices will be installed on port1.",NULL
:txInpDev2b		b "C=1351 mice and compatible devices will be installed on port1.",NULL
:txInpDev3		b "Select 'NO' to keep the currently installed input driver!",NULL
:txInpDev4		b BOLDON
			b "Install new input driver?",NULL
endif

;*** Header für Maustreiber-Datei.
:HdrInputDev		w inputDevName
			b $03,$15
			j
<MISSING_IMAGE_DATA>
:HdrB_068		b $81
:HdrB_069		b INPUT_DEVICE
:HdrB_070		b SEQUENTIAL
:HdrB_071		w MOUSE_BASE
:HdrB_073		w MOUSE_BASE + MOUSE_SIZE
:HdrB_075		w MOUSE_BASE
:HdrB_077		b "InputDevice V"		;Klasse.
:HdrB_090		b "1.0"				;Version.
			e ( HdrB_077 + 20 )
:HdrB_097		b "GDOS64"			;Autor.
			e ( HdrB_097 + 20 )
:HdrB_107		e ( HdrB_107 + 52 )
:HdrB_160		b NULL

:newInpDevJoy		b "SuperStick64.1",NULL
:newInpDevMse		b "Mouse1351",NULL
;:newInpDevMse		b "SmartMouse",NULL
;:newInpDevMse		b "SuperMouse64",NULL
;:newInpDevMse		b "MicroMysX1",NULL
;:newInpDevMse		b "MicroMysX2",NULL

:textCurInpDev		b BOLDON
if LANG = LANG_DE
			b "Hinweis:"
			b PLAINTEXT
			b GOTOX
			w $0050
			b "Aktueller Treiber"
endif
if LANG = LANG_EN
			b "Note:"
			b PLAINTEXT
			b GOTOX
			w $0050
			b "Current device"
endif
			b GOTOX
			w $0098
			b "= "
:stdInpDevName		b "InputDevice64"
			e (stdInpDevName +17)

:textNewInpDev		b PLAINTEXT
if LANG = LANG_DE
			b GOTOX
			w $0050
			b "Neuer Treiber"
endif
if LANG = LANG_EN
			b GOTOX
			w $0050
			b "New device"
endif
			b GOTOX
			w $0098
			b "= "
:nameNewInpDev		s 17

:firstInpDev		s 17

:inputDevTr		b $00
:inputDevSe		b $00
:inputDevAddr		w $0000
:inputDevEntry		s 31
