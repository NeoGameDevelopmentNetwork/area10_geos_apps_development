; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Partitionsgröße einstellen.
:DoDlg_RDrvNMSize	LoadW	r0,Dlg_GetSize		;Partitionsgröße wählen.
			jsr	DoDlgBox

			ldx	#NO_ERROR		; => Nein, Kein Fehler...
			lda	sysDBData
			cmp	#OK			;Auswahl abgebrochen ?
			beq	:1			; => Ja, Ende...
			ldx	#CANCEL_ERR
::1			rts

;*** Mehr RAM.
:Add64K			php				;Mausabfrage.
			sei
			lda	#$60
			jsr	SetIconArea
			jsr	IsMseInRegion
			plp
			tax
			beq	Sub64K

			ldy	SetSizeRRAM
			cpy	MaxSizeRRAM		;Weiterer Speicher verfügbar?
			bcc	:51			; => Ja, weiter...
			ldx	#NO_FREE_RAM
			rts

::51			iny				;Neue Größe festlegen.
			sty	SetSizeRRAM

			lda	#$60
			jsr	PrntNewSize

			bit	mouseData		;Maustaste noch gedrückt?
			bpl	Add64K			;Ja -> mehr Speicher reservieren.
			ClrB	pressFlag
			rts

;*** Weniger RAM.
:Sub64K			php				;Mausabfrage.
			sei
			lda	#$68
			jsr	SetIconArea
			jsr	IsMseInRegion
			plp
			tax
			beq	:54

			ldy	SetSizeRRAM
			dey				;Speicher weiter reduzierbar?
			cpy	#$02			;Mind 2x64K erforderlich.
			bcs	:51			; => Ja, weiter...
			ldx	#NO_FREE_RAM
			rts

::51			sty	SetSizeRRAM		;Neue Größe festlegen.

			lda	#$68
			jsr	PrntNewSize

			bit	mouseData		;Maustaste noch gedrückt?
			bpl	Sub64K			;Ja -> weniger Speicher reservieren.
			ClrB	pressFlag
::54			rts

;*** Grenzen für Mausabfrage festlegen.
:SetIconArea		sta	r2L
			clc
			adc	#$07
			sta	r2H
			LoadW	r3 ,($12*8   )
			LoadW	r4 ,($12*8+15)
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

;--- Ergänzung: 15.12.18/M.Kanet
;Einheitlich immer die gesamte Laufwerksgröße ausgeben.
;			SubVW	16,r0			;16K für Verzeichnis abziehen.

			LoadB	r1H,$6b
			LoadW	r11,$0063
			lda	#%11000000
			jmp	PutDecimal

;*** Icons für Auswahl Partitionsgröße zeichnen.
;Wird über die Dialogbox-Routine aufgerufen.
:Dlg_DrawIcons		jsr	i_BitmapUp
			w	Icon01
			b	$12
			b	$60
			b	Icon01x
			b	Icon01y

			lda	C_DBoxDIcon
			jsr	i_UserColor
			b	$12
			b	$60/8
			b	Icon01x
			b	Icon01y/8
			rts

;*** Dialogbox.
:Dlg_GetSize		b %01100001
			b $30,$8f
			w $0040,$00ff

			b DB_USR_ROUT
			w DrawDBoxTitel
			b DBGRPHSTR
			w Dlg_Graphics1
			b DBTXTSTR   ,$10,$0b
			w DlgBoxTitle
			b DBTXTSTR   ,$10,$20
			w :53
			b DBTXTSTR   ,$68,$3b
			w :54
			b DB_USR_ROUT
			w PrntCurSize
			b DBOPVEC
			w Add64K
			b DB_USR_ROUT
			w Dlg_DrawIcons
			b OK         ,$02,$48
			b CANCEL     ,$10,$48
			b NULL

if LANG = LANG_DE
::53			b PLAINTEXT
			b "Partitionsgröße wählen:",NULL
::54			b "KBytes",BOLDON,NULL
endif

if LANG = LANG_EN
::53			b PLAINTEXT
			b "Select partition size:",NULL
::54			b "KBytes",BOLDON,NULL
endif

:Dlg_Graphics1		b MOVEPENTO
			w $0060
			b $60
			b FRAME_RECTO
			w $008f
			b $6f

:Dlg_Graphics2		b NEWPATTERN,$00
			b MOVEPENTO
			w $0061
			b $61
			b RECTANGLETO
			w $008e
			b $6e
			b NULL

;*** Icons
:Icon01
<MISSING_IMAGE_DATA>

:Icon01x		= .x
:Icon01y		= .y
