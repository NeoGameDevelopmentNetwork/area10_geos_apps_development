; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
;			t "TopMac"
;			t "Sym128.erg"
			t "ext.BuildMod.ext"
endif

			n "geoUTestERAM"
			c "geoUTestERAMV0.1"
			a "Markus Kanet"

			h "Test C=REU/GeoRAM in Ultimate64/II+..."

			o APP_RAM
			p MAININIT

			f APPLICATION
			z $40 ;GEOS 40/80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Sprungtabelle.
:MAININIT		jmp	execTestERAM

;--- geoULib einbinden.
;Systemroutinen:
			t "ulib.C.SymbTab"		;Erweiterte Symboltabelle.
			t "ulib.C.Core"			;UCI-Systemroutinen.

;Optionale Routinen:
			t "ulib._ClkRate128"		;Nur C128: Auf 1/2 MHz umschalten.
			t "ulib._DetectCREU"		;C=REU erkennen.
			t "ulib._SizeCREU"		;Größe C=REU ermitteln.
			t "ulib._DetectGRAM"		;GeoRAM erkennen.
			t "ulib._SizeGRAM"		;Größe GeoRAM ermitteln.

;Erweiterte Programmroutinen:
;			-

;*** Überprüfen ob C=REU/GeoRAM vorhanden.
:execTestERAM		jsr	uTestRAM		;Speichererweiterungen testen.

			lda	#< dBoxStatus
			sta	r0L
			lda	#> dBoxStatus
			sta	r0H
			jsr	DoDlgBox		;Status anzeigen.

;*** Zurück zu GEOS.
:exitDeskTop		jmp	EnterDeskTop		;Ende.

;*** Speichererweiterungen testen.
;Übergabe : -
;Rückgabe : CREU_READY: $00=REU, $0D=Keine REU
;           CREU_SIZE : Anzahl 64K Speicherbänke (255=Sonderfall 16Mb)
;           GRAM_READY: $00=GeoRAM, $0D=Keine GeoRAM
;           GRAM_SIZE : Anzahl 64K Speicherbänke (255=Sonderfall 16Mb)
;Verändert: A,X,Y,r2,r3,diskBlkBuf,fileHeader

:uTestRAM		jsr	ULIB_IO_ENABLE		;IRQ sperren, I/O ein.

			jsr	ULIB_TEST_CREU		;C=REU vorhanden?
			txa
			sta	CREU_READY
			bne	:1			; => Nein, weiter...

			jsr	ULIB_SIZE_CREU		;Größe C=REU ermitteln.
			sty	CREU_SIZE

::1			jsr	ULIB_TEST_GRAM		;GeoRAM vorhanden?
			txa
			sta	GRAM_READY
			bne	:2			; => Nein, weiter...

			jsr	ULIB_SIZE_GRAM		;Größe GeoRAM ermitteln.
			sty	GRAM_SIZE

::2			jmp	ULIB_IO_DISABLE		;I/O aus, IRQ freigeben.

;*** Status C=REU/GeoRAM ausgeben.
:prntCStatus		ldx	#0
			b $2c
:prntGStatus		ldx	#2
			lda	ERAM_DATA +0,x
			bne	:err
			ldx	#< textOK
			ldy	#> textOK
			bne	:prnt
::err			ldx	#< textErr
			ldy	#> textErr
::prnt			stx	r0L
			sty	r0H
			jmp	PutString

;*** Größe C=REU/GeoRAM ausgeben.
:prntCSize		ldx	#0
			b $2c
:prntGSize		ldx	#2
			lda	ERAM_DATA +1,x

			ldy	#9
::1			cmp	tabSize,y
			beq	:2
			dey
			bpl	:1
			iny
::2			tya
			asl
			tax
			lda	vecSize +0,x
			sta	r0L
			lda	vecSize +1,x
			sta	r0H
			jmp	PutString

;*** Variablen.
:ERAM_DATA
:CREU_READY		b $00
:CREU_SIZE		b $00
:GRAM_READY		b $00
:GRAM_SIZE		b $00

;*** Dialogbox: Status anzeigen.
:dBoxStatus		b %10000001

			b DBTXTSTR,$10,$10
			w :1

;--- C=REU:
			b DBTXTSTR   ,$10,$20
			w :2a

			b DBTXTSTR   ,$40,$20
			w :no_text
			b DB_USR_ROUT
			w prntCStatus

			b DBTXTSTR   ,$10,$2a
			w :3

			b DBTXTSTR   ,$40,$2a
			w :no_text
			b DB_USR_ROUT
			w prntCSize

;--- GeoRAM:
			b DBTXTSTR   ,$10,$38
			w :2b

			b DBTXTSTR   ,$40,$38
			w :no_text
			b DB_USR_ROUT
			w prntGStatus

			b DBTXTSTR   ,$10,$42
			w :3

			b DBTXTSTR   ,$40,$42
			w :no_text
			b DB_USR_ROUT
			w prntGSize

			b OK         ,$10,$48
			b NULL

::1			b PLAINTEXT,BOLDON
			b "INFORMATION:"
			b PLAINTEXT,NULL

::2a			b "C=REU: ",NULL
::2b			b "GeoRAM: ",NULL

::3			b "Size: "
::no_text		b NULL

:textOK			b "Enabled",NULL
:textErr		b "Disabled",NULL

:tabSize		b 0,1,2,4,8,16,32,64,128,255

:vecSize		w text0K
			w text64K
			w text128K
			w text256K
			w text512K
			w text1Mb
			w text2Mb
			w text4Mb
			w text8Mb
			w text16Mb

:text0K			b "0Kb",NULL
:text64K		b "64Kb",NULL
:text128K		b "128Kb",NULL
:text256K		b "256Kb",NULL
:text512K		b "512Kb",NULL
:text1Mb		b "1Mb",NULL
:text2Mb		b "2Mb",NULL
:text4Mb		b "4Mb",NULL
:text8Mb		b "8Mb",NULL
:text16Mb		b "16Mb",NULL
