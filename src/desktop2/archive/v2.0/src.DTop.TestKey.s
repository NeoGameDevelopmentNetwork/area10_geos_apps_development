; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Tastaturabfrage.
:u_keyVector		lda	flagLockMseDrv
			ora	menuNumber		;Hauptmenü?
			bne	exit5			; => Nein, Ende...

			lda	keyData
			ldx	diskOpenFlg		;Diskette geöffnet?
			beq	chkSKeyDisk		; => Ja, weiter...

			ldx	a7L			;Icon-Modus?
			bne	chkSKeyDisk		; => Nein, weiter...

;--- Hinweis:
;ShortCuts für Datei-operationen werden
;nur im Hauptmenü und einer Ansicht im
;Icon-Modus ausgewertet.
:chkSKeyFile		ldy	#maxShortCuts -1
::1			cmp	tabShortCuts1,y
			beq	:2
			dey
			bpl	:1
			bmi	chkSKeysPage

;--- Datei-ShortCut gefunden.
::2			ldx	tabKeyVec1H,y
			lda	tabKeyVec1L,y
			jmp	CallRoutine

;*** ShortCut-Tasten, Teil #1.
:tabShortCuts1		b $fa				;CBM+Z
			b $e8				;CBM+H
			b $ed				;CBM+M
			b $e4				;CBM+D
			b $f1				;CBM+Q
			b $f0				;CBM+P
			b $f5				;CBM+U
			b $f3				;CBM+S
			b $f4				;CBM+T
			b $f7				;CBM+W
			b $f8				;CBM+X
			b $f9				;CBM+Y
			b $e7				;CBM+G
			b $10				;CRSR-UP
			b $11				;CRSR-DOWN
:endShortCuts1
:maxShortCuts		= endShortCuts1 - tabShortCuts1

;*** ShortCuts für Seitenwechsel.
:chkSKeysPage		cmp	#"0"			;Taste "0"?
			bne	:1			; => Nein, weiter...
			lda	#10 -1			;Seite #10 öffnen.
			bne	:newpage

::1			tay
			cmp	#"9" +1			;Taste "1" bis "9"?
			bcs	:2			; => Nein, weiter...
			sec
			sbc	#$31			;Seite #1-9 öffnen.
			bcs	:newpage

::2			tya
			cmp	#$40			;Taste SHIFT+"3"?
			bne	:3			; => Nein, weiter...
			lda	#13 -1			;Seite #13 öffnen.
			bne	:newpage

::3			cmp	#$2f			;Taste SHIFT+"7"?
			bne	:4			; => Nein, weiter...
			lda	#17 -1			;Seite #17 öffnen.
			bne	:newpage

::4			cmp	#$29			;Taste SHIFT+"9"?
			bcs	chkSKeysSlct
			cmp	#$21			;Taste SHIFT+"1"?
			bcc	chkSKeysSlct

			and	#%00001111
			clc
			adc	#$09			;Seite #11-18 öffnen.
::newpage		jmp	openNewPadPage		;Neue Seite öffnen.

;*** ShortCuts für Dateiauwahl.
:chkSKeysSlct		tya

;--- Auswahl vom Border.
			cmp	#"1" +$70		;C=SHIFT + "1"-"8".
			bcc	chkSKeyDisk
			cmp	#"8" +$70 +1
			bcc	slctFileBorder

;--- Auswahl vom DeskPad.
			cmp	#"1" +$80		;C= + "1"-"8".
			bcc	chkSKeyDisk
			cmp	#"8" +$80 +1
			bcc	slctFileCurPage

;*** ShortCuts für Diskette.
:chkSKeyDisk		ldy	#maxOtherKeys -1
::1			cmp	tabShortCuts2,y
			beq	:exec
			dey
			bpl	:1
			bmi	:exit

;--- Laufwerk/Disk-ShortCut gefunden.
::exec			ldx	tabKeyVec2H,y
			lda	tabKeyVec2L,y
			jsr	CallRoutine

::exit			rts

;*** ShortCut-Tasten, Teil #2.
:tabShortCuts2		b $e1				;CBM+A
			b $e2				;CBM+B
			b $c1				;CBM+SHIFT+A
			b $c2				;CBM+SHIFT+B
			b $e3				;CBM+C
			b $e9				;CBM+I
			b $ee				;CBM+N
			b $eb				;CBM+K
			b $ef				;CBM+O
			b $e5				;CBM+E
			b $f6				;CBM+V
			b $e6				;CBM+F
			b $f2				;CBM+R
:endShortCuts2
:maxOtherKeys		= endShortCuts2 - tabShortCuts2

;*** ShortCut-Routinen, Teil #2.
:tabKeyVec2H		b > keybOpenDrvA		;CBM+A
			b > keybOpenDrvB		;CBM+B
			b > keybSwapDrvAC		;CBM+SHIFT+A
			b > keybSwapDrvBC		;CBM+SHIFT+B
			b > keybDiskClose		;CBM+C
			b > keybSlctInput		;CBM+I
			b > keybDiskRName		;CBM+N
			b > keybDiskCopy		;CBM+K
			b > keybDiskOpen		;CBM+O
			b > keybDiskErease		;CBM+E
			b > keybDiskValid		;CBM+V
			b > keybDiskFormat		;CBM+F
			b > keybOptReset		;CBM+R

:tabKeyVec2L		b < keybOpenDrvA		;CBM+A
			b < keybOpenDrvB		;CBM+B
			b < keybSwapDrvAC		;CBM+SHIFT+A
			b < keybSwapDrvBC		;CBM+SHIFT+B
			b < keybDiskClose		;CBM+C
			b < keybSlctInput		;CBM+I
			b < keybDiskRName		;CBM+N
			b < keybDiskCopy		;CBM+K
			b < keybDiskOpen		;CBM+O
			b < keybDiskErease		;CBM+E
			b < keybDiskValid		;CBM+V
			b < keybDiskFormat		;CBM+F
			b < keybOptReset		;CBM+R

;*** Dateiauswahl im Border.
:slctFileBorder		sec
			sbc	#"1" +$70 -8
			bne	keybSlctFile

;*** Dateiauswahl im Deskpad.
:slctFileCurPage	sec
			sbc	#"1" +$80 -0

;*** Datei auswählen.
:keybSlctFile		tay
			jsr	disableFileDnD
			tya
			jsr	isIconGfxInTab
			bne	:ok			; => Icon, weiter...
			rts

;--- Icon gefunden.
::ok			tya				;Zeiger auf Eintrag
			sta	r0L			;berechnen.
			jsr	getSlctIconEntry
			cpx	#$ff			;Bereits gewählt?
			beq	slctNewFile		; => Nein, weiter...

;*** Datei abwählen.
::selected		jsr	findFSlctEntryX
			jmp	unselectJobIcon

;*** Datei auswählen.
.slctNewFile		jsr	chkSameFileSlct
			jmp	doJobSelectFile

;*** ShortCut-Routinen, Teil #1.
:tabKeyVec1L		b < keybFileOpen		;CBM+Z
			b < keybFileCopy		;CBM+H
			b < keybFileRName		;CBM+M
			b < keybFileDel			;CBM+D
			b < keybFileInfo		;CBM+Q
			b < keybFilePrint		;CBM+P
			b < keybFileUndel		;CBM+U
			b < keybPageAdd			;CBM+S
			b < keybPageDel			;CBM+T
			b < keybSlctAll			;CBM+W
			b < keybSlctPage		;CBM+X
			b < keybSlctBorder		;CBM+Y
			b < keybGo1stSlct		;CBM+G
			b < keybPageUp			;CRSR-UP
			b < keybPageDown		;CRSR-DOWN

:tabKeyVec1H		b > keybFileOpen		;CBM+Z
			b > keybFileCopy		;CBM+H
			b > keybFileRName		;CBM+M
			b > keybFileDel			;CBM+D
			b > keybFileInfo		;CBM+Q
			b > keybFilePrint		;CBM+P
			b > keybFileUndel		;CBM+U
			b > keybPageAdd			;CBM+S
			b > keybPageDel			;CBM+T
			b > keybSlctAll			;CBM+W
			b > keybSlctPage		;CBM+X
			b > keybSlctBorder		;CBM+Y
			b > keybGo1stSlct		;CBM+G
			b > keybPageUp			;CRSR-UP
			b > keybPageDown		;CRSR-DOWN
