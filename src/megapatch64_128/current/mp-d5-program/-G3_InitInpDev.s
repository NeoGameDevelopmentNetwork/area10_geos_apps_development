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
							;Ergebniss im Y-Reg!

			ldx	#$00			;Informationen für Joystick/Maus
::52			lda	DeviceInfo +0,y		;kopieren.
			sta	r0L        +0,x
			iny
			inx
			cpx	#$04
			bcc	:52

			LoadW	r2,NewMouseDriver
			ldx	#r1L
			ldy	#r2L
			jsr	CopyString

			jsr	Col2IconDlgBox		;Abfrage: Treiber installieren ?

			lda	sysDBData
			cmp	#NO
			beq	:55			; => Nein, weiter...

			LoadW	r6,NewMouseDriver	;Neuen Eingabetreiber auf
			jsr	FindFile		;Diskette suchen.
			txa				;Eingabetreiber gefunden ?
			bne	:55			; => Nein, weiter...

::53			lda	NewMouseDriver,x	;Maustreiber-Bezeichnung
			sta	inputDevName  ,x	;kopieren.
			inx
			cpx	#17
			bcc	:53

::54			LoadW	r6,inputDevName		;Aktuellen Eingabetreiber auf
			jsr	FindFile		;Diskette suchen.
			txa				;Eingabetreiber gefunden ?
			bne	:55			; => Nein, weiter...

			stx	r10L
			stx	r10H
			inx
			stx	r7H
if Flag64_128 = TRUE_C64
			lda	#INPUT_DEVICE
endif
if Flag64_128 = TRUE_C128
			lda	#INPUT_128
endif
			sta	r7L
			LoadW	r6 ,FirstInpDev		;Ersten Eingabetreiber auf
			jsr	FindFTypes		;Diskette suchen.
			txa				;Eingabetreiber gefunden ?
			bne	:55			; => Nein, weiter...

			LoadW	r0,FirstInpDev		;Ist aktueller Eingabetreiber der
			LoadW	r1,inputDevName		;erste Eingabetreiber auf Disk ?
			ldx	#r0L
			ldy	#r1L
			jsr	CmpString
			beq	:58			; => Ja, weiter...

			jsr	SwapInpDevice		;Ersten Eingabetreiber auf Disk
			txa				;mit aktuellem Treiber tauschen.
			beq	:58			; => Fehler ? Nein, weiter...

::55			ldx	inputDevName		;Maustreiber installiert ?
			bne	:57
::56			lda	OldMouseDriver,x
			sta	inputDevName  ,x
			inx
			cpx	#$10
			bcc	:56

::57			LoadW	r0,inputDevName
			jsr	DeleteFile

			LoadW	r9  ,HdrInputDev	;Aktiven Treiber speichern und
			LoadB	r10L,$00		;erneut testen.
			jsr	SaveFile
			jmp	:54

::58			LoadW	r0,Strg_InputDev
			jsr	PutString

			LoadW	r0,inputDevName
			jmp	PutString

;*** Aktiven Eingabetreiber erkennen.
:DetectInpDev		php
			sei

if Flag64_128 = TRUE_C64
			lda	CPU_DATA
			pha
			lda	#$37			;I/O-Bereich und Kernal für
			sta	CPU_DATA		;RAMLink-Transfer aktivieren.
endif
if Flag64_128 = TRUE_C128
			lda	MMU			;MMU-Register sichern.
			pha
			lda	#$4e			;Ram1 bis $bfff + IO + Kernal
			sta	MMU			;I/O-Bereich und Kernal für
							;RAMLink-Transfer aktivieren.
			lda	RAM_Conf_Reg		;Konfigurationsregister sichern.
			pha
			and	#%11110000
			ora	#%00000100		;Common Area $0000 bis $0400
			sta	RAM_Conf_Reg
endif

			lda	$d419			;Abfrage Joystick/Maus.
			cmp	#$ff
			bne	:51
			lda	$d41a
			cmp	#$ff
			bne	:51
			ldy	#$00
			b $2c
::51			ldy	#$04

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif
			plp
			rts

;*** Ersten Eingabetreiber mit aktuellem Eingabetreiber auf Disk tauschen.
:SwapInpDevice		LoadW	r6,inputDevName		;Aktuellen Eingabetreiber
			jsr	FindFile		;auf Diskette suchen.
			txa				;Eingabetreiber gefunden ?
			bne	:52			; => Nein, Ende...

			lda	r1L			;Position und Inhalt des Verzeichnis
			sta	inputDevTr		;eintrages zwischenspeichern.
			lda	r1H
			sta	inputDevSe
			lda	r5L
			sta	inputDevAddr +0
			lda	r5H
			sta	inputDevAddr +1

			ldy	#$1d
::51			lda	(r5L)        ,y
			sta	inputDevEntry,y
			dey
			bpl	:51

			LoadW	r6,FirstInpDev		;Ersten Eingabetreiber auf
			jsr	FindFile		;Diskette suchen.
			txa				;Eingabetreiber gefunden ?
			beq	:53			; => Ja, weiter...
::52			rts

::53			ldy	#$1d			;Verzeichniseinträge tauschen.
::54			lda	inputDevEntry,y
			pha
			lda	(r5L)        ,y
			sta	inputDevEntry,y
			pla
			sta	(r5L)        ,y
			dey
			bpl	:54

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

			ldy	#$1d
::55			lda	inputDevEntry,y
			sta	(r5L)        ,y
			dey
			bpl	:55

			jmp	PutBlock

;*** Installierten Eingabetreiber anzeigen.
:Strg_InputDev		b ESC_GRAPHICS
			b NEWPATTERN,$00
			b MOVEPENTO
			w $0000 ! DOUBLE_W
			b $b8
			b RECTANGLETO
			w $013f ! DOUBLE_W ! ADD1_W
			b $c7
			b ESC_PUTSTRING
			w $0010 ! DOUBLE_W
			b $c0
			b PLAINTEXT,BOLDON

if Sprache = Deutsch
			b "Eingabetreiber: ",NULL
endif

if Sprache = Englisch
			b "Input-device: ",NULL
endif

;*** Dialogbox: Joysticktreiber aktivieren ?
:Dlg_AskJoyDev		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Information
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$30
			w Dlg_UseInpDev1
			b DBTXTSTR ,$0c,$3a
			w Dlg_UseInpDev2
			b DBTXTSTR ,$0c,$4a
			w Dlg_UseInpDev3
			b NO       ,$02!DOUBLE_B,$60
			b YES      ,$1c!DOUBLE_B,$60
			b NULL

if Sprache = Deutsch
::101			b "Wenn Sie weitermachen, wird ein Eingabe-",NULL
::102			b "treiber für Joystick und kompatible Geräte",NULL
endif

if Sprache = Englisch
::101			b "If you continue a inputdriver is activated for",NULL
::102			b "joystick and compatible devices connected to",NULL
endif

;*** Dialogbox: Maustreiber aktivieren ?
:Dlg_AskMseDev		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Information
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$30
			w Dlg_UseInpDev1
			b DBTXTSTR ,$0c,$3a
			w Dlg_UseInpDev2
			b DBTXTSTR ,$0c,$4a
			w Dlg_UseInpDev3
			b NO       ,$02!DOUBLE_B,$60
			b YES      ,$1c!DOUBLE_B,$60
			b NULL

if Sprache = Deutsch
::101			b "Wenn Sie weitermachen, wird ein Eingabe-",NULL
::102			b "treiber für C=1351 und kompatible Geräte",NULL
endif

if Sprache = Englisch
::101			b "If you continue a inputdriver is activated for",NULL
::102			b "C=1351 and compatible devices connected to",NULL
endif

if Sprache = Deutsch
:Dlg_UseInpDev1		b "an Port1 aktiviert. Wählen Sie 'NEIN' um",NULL
:Dlg_UseInpDev2		b "den aktiven Eingabetreiber beizubehalten.",NULL
:Dlg_UseInpDev3		b "Neuen Eingabetreiber aktivieren?",NULL
endif

if Sprache = Englisch
:Dlg_UseInpDev1		b "port1. Choose 'NO' to retain the currently",NULL
:Dlg_UseInpDev2		b "installed inputdriver!",NULL
:Dlg_UseInpDev3		b "Install new inputdriver?",NULL
endif

;*** Header für Maustreiber-Datei.
:HdrInputDev		w inputDevName
			b $03,$15
			j
<MISSING_IMAGE_DATA>
:HdrB_068		b $81
if Flag64_128 = TRUE_C64
:HdrB_069		b INPUT_DEVICE
endif
if Flag64_128 = TRUE_C128
:HdrB_069		b INPUT_128
endif
:HdrB_070		b SEQUENTIAL
:HdrB_071		w MOUSE_BASE
:HdrB_073		w END_MOUSE -1
:HdrB_075		w MOUSE_BASE
:HdrB_077		b "InputDevice V"		;Klasse.
:HdrB_090		b "1.0"				;Version.
:HdrB_093		b $00,$00,$00
if Flag64_128 = TRUE_C64
:HdrB_096         b $00					;Reserviert.
endif
if Flag64_128 = TRUE_C128
:HdrB_096         b $40					;GEOS128 40/80 Zeichen.
endif
if Flag64_128 = TRUE_C64
:HdrB_097		b "MegaPatch 64"		;Autor.
			b $00,$00,$00,$00
			b $00,$00,$00,$00
endif
if Flag64_128 = TRUE_C128
:HdrB_097		b "MegaPatch 128"		;Autor.
			b $00,$00,$00,$00
			b $00,$00,$00
endif
:HdrB_117		s 17
:HdrB_134		s 26
;--- Infotext wird durch SaveFile gelöscht.
:HdrB_160		b "* Maus/Joystick MegaPatch-Backup"
::HdrEnd		s 96 - (:HdrEnd - HdrB_160)

:FirstInpDev		s 17
:inputDevTr		b $00
:inputDevSe		b $00
:inputDevAddr		w $0000
:inputDevEntry		s 31

:DeviceInfo		w Dlg_AskJoyDev,:51
			w Dlg_AskMseDev,:52

if Flag64_128 = TRUE_C64
::51			b "SuperStick64.1",NULL
::52			b "SuperMouse64",NULL
endif
if Flag64_128 = TRUE_C128
::51			b "SuperStick128.1",NULL
::52			b "SuperMouse128",NULL
endif

:NewMouseDriver		s 17
if Flag64_128 = TRUE_C64
:OldMouseDriver		b "Input64",NULL
endif
if Flag64_128 = TRUE_C128
:OldMouseDriver		b "Input128",NULL
endif
