; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Texte ausgeben.
:Strg_Titel		lda	#$00			;BootText00
			b $2c
:Strg_Autor		lda	#$01			;BootText00a
			b $2c
:Strg_OK		lda	#$02			;BootText01
			b $2c
:Strg_Error		lda	#$03			;BootText02
			b $2c
:Strg_RamExp_Find	lda	#$04			;BootText10
			b $2c
:Strg_RamExp_SCPU	lda	#$05			;BootText11
			b $2c
:Strg_RamExp_RL		lda	#$06			;BootText12
			b $2c
:Strg_RamExp_REU	lda	#$07			;BootText13
			b $2c
:Strg_RamExp_BBG	lda	#$08			;BootText14
			b $2c
:Strg_RamExp_Menu	lda	#$09			;BootText15
			b $2c
:Strg_RamExp_OK		lda	#$0a			;BootText16
			b $2c
:Strg_RamExp_Size	lda	#$0b			;BootText18
			b $2c
:Strg_RamExp_DACC	lda	#$0c			;BootText20
			b $2c
:Strg_RamExp_Exit	lda	#$0d			;BootText20
			b $2c
:Strg_RamExp_Auto	lda	#$0e			;BootText21
			b $2c
:Strg_Initialize	lda	#$0f			;BootText22
			b $2c
:Strg_DvInit_Info	lda	#$10			;BootText30
			b $2c
:Strg_DvInit_RL		lda	#$11			;BootText31
			b $2c
:Strg_LdGEOS_1		lda	#$12			;BootText40
			b $2c
:Strg_LdGEOS_2		lda	#$13			;BootText41
			b $2c
:Strg_Install_1		lda	#$14			;BootText50
			b $2c
:Strg_Install_2		lda	#$15			;BootText51
			b $2c
:Strg_Install_R		lda	#$16			;BootText52
			b $2c
:Strg_MgrRAM		lda	#$17			;BootText60
			b $2c
:Strg_MgrSCPU		lda	#$18			;BootText61
			b $2c
;Strg_MgrHD		lda	#$19			;BootText62
;			b $2c
:Strg_InitGEOS		lda	#$19			;BootText70
			b $2c
:Strg_LoadError		lda	#$1a			;BootText80
			b $2c
:Strg_TestRAMExp	lda	#$1b			;BootText80

if Flag64_128 = TRUE_C128
			b $2c
:Strg_LdGEOS_128	lda	#$1c			;BootText40a
			b $2c
:Strg_Install_128	lda	#$1d			;BootText50a
endif

			asl
			tax
			lda	StrgVecTab1 +0,x	;Zeiger auf Text einlesen.
			ldy	StrgVecTab1 +1,x

;*** Textausgabe.
;Beim C128 wird der Text über BSOUT ausgegeben. Grund dafür könnte
;sein das :ROM_OUT_STRING beim C128 anders funktioniert als am C64.
:Strg_CurText		php
			sei

if Flag64_128 = TRUE_C64
			tax
			lda	CPU_DATA		;BASIC-ROM aktivieren.
			pha
			lda	#$37
			sta	CPU_DATA
			txa
			jsr	ROM_OUT_STRING		;Text ausgeben.
			pla
			sta	CPU_DATA
endif

if Flag64_128 = TRUE_C128
			sta	r0L			;Zeiger auf Text speichern.
			sty	r0H

			lda	MMU			;RAM bis $3fff sonst ROM und IO
			pha
			lda	#$00
			sta	MMU

::loop			ldy	#0			;Zeiger auf erstes Byte im Speicher.
			lda	(r0),y			;Textzeichen einesen.
			beq	:end			;NULL = Textende erreicht?
			jsr	BSOUT			;Nein, Zeichen über ROM ausgeben.
			inc	r0L			;Zeiger auf nächsten Zeichen.
			bne	:loop
			inc	r0H
			jmp	:loop			;Weiter mit nächstem Zeichen.

::end			pla
			sta	MMU			;MMU-Register zurücksetzen.
endif

;			jsr	Strg_Delay		;Ausgabeverzögerung.

			plp
			rts

;--- Ergänzung: 06.09.18/M.Kanet
;Verzögerung der Ausgabe von Systemtexten deaktiviert.
;Wurde eingeführt um beim Start Systemmeldungen und Fehler erkennen zu können.
if FALSE
:Strg_Delay		lda	TEXT_OUT_DELAY
			bne	:50

			lda	#%01111111
			sta	cia1base + 0
			lda	cia1base + 1		;Tastatur einlesen.
			and	#%00100000		;CBM gedrückt ?
			bne	:54			; => Nein, weiter...
			dec	TEXT_OUT_DELAY

::50			ldx	#$20			;Warteschleife...
::51			lda	$d012
::52			cmp	$d012
			beq	:52
::53			cmp	$d012
			bne	:53
			dex
			bne	:51
::54			rts
endif
