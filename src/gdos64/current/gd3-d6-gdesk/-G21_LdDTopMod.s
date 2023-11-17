; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Routinen für Dateifenster.
:extWin_User1		lda	#0  *3			;Programm-Routine #1.
			b $2c
:extWin_User2		lda	#1  *3			;Programm-Routine #2.
			b $2c
:extWin_User3		lda	#2  *3			;Programm-Routine #3.
			b $2c
:extWin_InitCount	lda	#3  *3			;Zeiger auf Anfang/Zähler löschen.
			b $2c
:extWin_InitData	lda	#4  *3			;Verzeichnisdaten zurücksetzen.
			b $2c
:extWin_InitWin		lda	#5  *3			;Fenster initialisieren.
			b $2c
:extWin_InitWGrid	lda	#6  *3			;Raster initialisieren.
			b $2c
.extWin_GetData		lda	#7  *3			;Dateien einlesen.
			b $2c
:extWin_GetCache	lda	#8  *3			;Dateien aus Cache einlesen.
			b $2c
.extWin_PrntEntry	lda	#9  *3			;Eintrag ausgeben.
			b $2c
:extWin_SlctMode	lda	#10 *3			;Auswahlmodus festlegen.
			b $2c
.extWin_SSlctData	lda	#11 *3			;Einzel-Auswahl.
			b $2c
.extWin_MSlctData	lda	#12 *3			;Mehrfach-Auswahl.
			b $2c
.extWin_WinUpdate	lda	#13 *3			;Fensterinhalt speichern.
			b $2c
:extWin_ResetData	lda	#14 *3			;Dateien in Speicher laden.
			b $2c
:extWin_Unselect	lda	#15 *3			;Auswahl aufheben.
			b $2c
:extWin_LMenu		lda	#16 *3			;Menü linker Mausklick.
			b $2c
:extWin_RMenu		lda	#17 *3			;Menü rechter Mausklick.

			ldx	WM_DATA_OPTIONS
			beq	:exit

			pha

			txa
			jsr	GetDTopMod

			pla

			clc
			adc	#< BASE_GDMENU
			tay
			lda	#$00
			adc	#> BASE_GDMENU
			tax
			tya
			jmp	CallRoutine

::exit			rts

;*** QuickSelect Eingabegerät.
.EXT_INPUTDBOX		lda	#%01000000		;Eingabetreiber wählen.
			b $2c
.EXT_INPUTLOAD		lda	#%00100000		;Eingabetreiber laden.
			b $2c
.EXT_INPUTQUICK		lda	#%00010000		;QuickSelect Eingabetreiber.
			b $2c
.EXT_PRINTDBOX		lda	#%11000000		;Druckertreiber wählen.
			b $2c
.EXT_PRINTLOAD		lda	#%10100000		;Druckertreier laden.
			b $2c
.EXT_PRINTALNK		lda	#%10010000		;Druckertreier für AppLink wählen.
			b $2c
.EXT_PRINTLDERR		lda	#%10001000		;Drucker-AppLink-Fehler.
			sta	r10L

			lda	#GEXT_SETINPUT
			bne	LdDTopMod 		;Taskleiste zeichnen.

;*** Desktop zeichnen.
:MainDTopRedraw		lda	#%00000000
			b $2c
:MainDTopUpdAppl	lda	#%01000000
			b $2c
:MainDTopUpdate		lda	#%10000000
			sta	r10L

			lda	#GEXT_DRAWDTOP		;Desktop, AppLinks und
;			jmp	LdDTopMod 		;Taskleiste zeichnen.

;*** Menü-Modul nachladen und starten.
;Übergabe: xReg = Modul-Nummer.
:LdDTopMod		jsr	GetDTopMod
			jmp	BASE_GDMENU		;Modul starten.

;*** Menü-Modul nachladen.
:GetDTopMod		cmp	GD_VLIR_MODX
			beq	:exit

			sta	GD_VLIR_MODX

;--- Hinweis:
;Einige Routinen (:extWin_PrntEntry)
;übergeben in :r0 bis :r15 Parameter,
;daher die Adressen für FetchRAM vor
;dem Aufruf retten.

			tay

			ldx	#r3L
::save			lda	zpage,x
			pha
			dex
			cpx	#r0L
			bcs	:save

			tya

			tax
			asl
			asl
			tay

			lda	GD_DACC_ADDR_B,x	;Speicherbank für VLIR-Modul
			sta	r3L			;einlesen.

			ldx	#$00
::1			lda	GD_DACC_ADDR,y		;Adresse des Moduls in der REU und
			sta	r1L,x			;Größe des Moduls kopieren.
			iny
			inx
			cpx	#$04
			bcc	:1

			lda	#< BASE_GDMENU		;Startadresse Modul im Speicher.
			sta	r0L
			lda	#> BASE_GDMENU
			sta	r0H

			jsr	FetchRAM		;Modul einlesen.

			ldx	#r0L
::load			pla
			sta	zpage,x
			inx
			cpx	#r3L +1
			bcc	:load

;--- Hinweis:
;Menüroutinen sichern den Bildschirm
;vor dem öffnen des PopUp-Menüs.
;			jsr	sys_SvBackScrn		;Aktuellen Bildschirm speichern.

::exit			rts
