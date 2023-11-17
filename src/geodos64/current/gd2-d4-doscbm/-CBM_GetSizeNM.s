; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
:NO_ERROR		= $00
:DEV_NOT_FOUND		= $0d
:NO_FREE_RAM		= $60
:MMU			= $ff00
endif

;*** Partitionsgröße einstellen.
:DoDlg_RDrvNMSize
			jsr	i_C_DBoxTitel
			b	$06,$05,$1c,$01
			jsr	i_C_DBoxBack
			b	$06,$06,$1c,$0b

			jsr	i_C_DBoxDIcon
			b	$08,$0e,$06,$02
			jsr	i_C_DBoxDIcon
			b	$1a,$0e,$06,$02

			jsr	UseGDFont

			LoadB	dispBufferOn,ST_WR_FORE

			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$28,$2f
			w	$0030,$010f

			jsr	i_PutString
			w	$0038
			b	$2e
			b	PLAINTEXT
			b	"NATIVE-MODE"
			b	NULL

			jsr	UseSystemFont

			LoadW	r0,Dlg_GetSize		;Partitionsgröße wählen.
			jsr	DoDlgBox

			jsr	ClrScreen

			lda	sysDBData
			cmp	#CANCEL			;Auswahl abgebrochen ?
			beq	:51			; => Ja, Ende...
			ldx	#NO_ERROR		; => Nein, Kein Fehler...
			b $2c
::51			ldx	#DEV_NOT_FOUND
			rts

;*** Mehr RAM.
:Add64K			lda	#10
			sta	ClkCount
			lda	#1
			sta	AddValue

::50			php				;Mausabfrage.
			sei
			lda	#$48
			jsr	SetIconArea
			jsr	IsMseInRegion
			plp
			tax
			beq	Sub64K

			lda	SetSizeRRAM
			cmp	MaxSizeRRAM		;Weiterer Speicher verfügbar?
			bcc	:51			; => Ja, weiter...
			ldx	#NO_FREE_RAM
			rts

::51			clc
			adc	AddValue 		;Neue Größe festlegen.
			bcc	:52
			lda	MaxSizeRRAM
::52			sta	SetSizeRRAM

			lda	#$48
			jsr	PrntNewSize

			bit	mouseData		;Maustaste noch gedrückt?
			bmi	:53			; -> Nein, Ende...
			dec	ClkCount		;Ja -> mehr Speicher reservieren.
			bne	:50
			lda	AddValue
			cmp	#100
			beq	:50
			cmp	#10
			bcc	:60
			lda	#100
			b $2c
::60			lda	#10
			sta	AddValue
			bne	:50

::53			ClrB	pressFlag
			rts

;*** Weniger RAM.
:Sub64K			lda	#10
			sta	ClkCount
			lda	#1
			sta	AddValue

::50			php				;Mausabfrage.
			sei
			lda	#$50
			jsr	SetIconArea
			jsr	IsMseInRegion
			plp
			tax
			beq	:54

			lda	SetSizeRRAM		;Speicher weiter reduzierbar?
			cmp	#$03			;Mind 2x64K erforderlich.
			bcs	:51			; => Ja, weiter...
			ldx	#NO_FREE_RAM
			rts

::51			sec
			sbc	AddValue
			bcs	:52
::51a			lda	#$02
::52			cmp	#$02
			bcc	:51a
			sta	SetSizeRRAM		;Neue Größe festlegen.

			lda	#$50
			jsr	PrntNewSize

			bit	mouseData		;Maustaste noch gedrückt?
			bmi	:53
			dec	ClkCount		;Ja -> weniger Speicher reservieren.
			bne	:50
			lda	AddValue
			cmp	#100
			beq	:50
			cmp	#10
			bcc	:60
			lda	#100
			b $2c
::60			lda	#10
			sta	AddValue
			bne	:50

::53			ClrB	pressFlag
::54			rts

;*** Grenzen für Mausabfrage festlegen.
:SetIconArea		sta	r2L
			clc
			adc	#$07
			sta	r2H
			LoadW	r3 ,($1e*8   )
			LoadW	r4 ,($1e*8+15)
			rts

;*** Warteschleife von 1 Sekunde.
:SCPU_Pause		php
			sei

			bit	c128Flag
			bmi	:101

			lda	CPU_DATA
			pha
			lda	#%00110101
			sta	CPU_DATA
			bne	:102

::101			lda	MMU
			pha
			lda	#%01111110
			sta	MMU

::102			lda	$dc08
::103			cmp	$dc08
			beq	:103

			bit	c128Flag
			bmi	:104

			pla
			sta	CPU_DATA
			bne	:105

::104			pla
			sta	MMU

::105			plp
			rts

;*** Button invertieren und Laufwerksgröße ausgeben.
:PrntNewSize		pha
			jsr	SetIconArea
			jsr	InvertRectangle
			jsr	PrntCurSize
			jsr	SCPU_Pause
			pla
			jsr	SetIconArea
			jmp	InvertRectangle

;*** Laufwerksgröße ausgeben.
:PrntCurSize		LoadW	r0,Dlg_Graphics2
			jsr	GraphicsString

			lda	SetSizeRRAM		;Anzahl Spuren in freien
			sta	r0L			;Speicher umrechnen.
			lda	#$40			;Jede Spur = 64Kb.
			sta	r1L
			ldx	#r0L
			ldy	#r1L
			jsr	BBMult

			LoadB	r1H,$53
			LoadW	r11,$0043
			lda	#%11000000
			jsr	PutDecimal

			lda	SetSizeRRAM
			sta	r0L
			lda	#$00
			sta	r0H
			LoadB	r1H,$53
			LoadW	r11,$00a3
			lda	#%11000000
			jmp	PutDecimal

;*** Icons für Auswahl Partitionsgröße zeichnen.
;Wird über die Dialogbox-Routine aufgerufen.
:Dlg_DrawIcons		jsr	i_BitmapUp
			w	Icon01
			b	$1e
			b	$48
			b	Icon01x
			b	Icon01y

			lda	C_DBoxDIcon
			jsr	i_UserColor
			b	$1e
			b	$48/8
			b	Icon01x
			b	Icon01y/8
			rts

;*** Systemvariablen.
;Max. verfügbarer Speicher für das RAMNative-Laufwerk.
:MaxSizeRRAM		b $00

;Gewählte Laufwerksgröße.
;Bei den ExtendedRAM-Laufwerken für SuperCPU, C=REU und GeoRAM wird dieser
;Wert auch für einen Neustart in der Systemdatei für die Laufwerkstreiber
;gespeichert.
:SetSizeRRAM		b $00

;Gewählte Laufwerksgröße.
;Bei den RAMNative-Laufwerken für den GEOS-Speicher wird die gewählte Größe
;für einen Neustart für jedes Laufwerk getrennt gespeichert. Damit können
;auch mehrere RAMNative-Laufwerke installiert und beim Systemstart automatisch
;konfiguriert werden.
;Für die ExtendedRAM-Laufwerke werden diese Werte nicht benötigt, hier wird
;direkt :SetSizeRRAM verwendet.
:DskSizeA		b $00
:DskSizeB		b $00
:DskSizeC		b $00
:DskSizeD		b $00

;*** Zähler für variable Größenänderung DiskImage-Größe.
:ClkCount		b $00
:AddValue		b $01

;*** Dialogbox.
:Dlg_GetSize		b %00100000
			b 48,135
			w 48,271
			b DBGRPHSTR
			w Dlg_Graphics1
			b DBTXTSTR   ,$10,$10
			w :53
			b DBTXTSTR   ,$3b,$21
			w :54
			b DBTXTSTR   ,$8b,$23
			w :55
			b DBTXTSTR   ,$10,$33
			w :56
			b DB_USR_ROUT
			w PrntCurSize
			b DBOPVEC
			w Add64K
			b DB_USR_ROUT
			w Dlg_DrawIcons
			b OK         ,$02,$40
			b CANCEL     ,$14,$40
			b NULL

if Sprache = Deutsch
::53			b PLAINTEXT,BOLDON
			b "Größe des DNP-DiskImage:",NULL
::54			b "KBytes =",NULL
::55			b "Tracks",NULL
::56			b PLAINTEXT
			b "1024 Kb = 16 Tracks, 1 Track = 64 Kb"
			b BOLDON
			b NULL
endif

if Sprache = Englisch
::53			b PLAINTEXT,BOLDON
			b "Size of the DNP disk image:",NULL
::54			b "KBytes =",NULL
::55			b "Tracks",NULL
::56			b PLAINTEXT
			b "1024 Kb = 16 Tracks, 1 Track = 64 Kb"
			b BOLDON
			b NULL
endif

:Dlg_Graphics1		b MOVEPENTO
			w $0040
			b $48
			b FRAME_RECTO
			w $0067
			b $57
			b MOVEPENTO
			w $00a0
			b $48
			b FRAME_RECTO
			w $00b7
			b $57

:Dlg_Graphics2		b NEWPATTERN,$00
			b MOVEPENTO
			w $0041
			b $49
			b RECTANGLETO
			w $0066
			b $56
			b NEWPATTERN,$00
			b MOVEPENTO
			w $00a1
			b $49
			b RECTANGLETO
			w $00b6
			b $56
			b NULL

;*** Icons
:Icon01
<MISSING_IMAGE_DATA>

:Icon01x		= .x
:Icon01y		= .y
