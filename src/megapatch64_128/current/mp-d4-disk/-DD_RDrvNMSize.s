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

			lda	sysDBData
			cmp	#CANCEL			;Auswahl abgebrochen ?
			beq	:51			; => Ja, Ende...
			ldx	#NO_ERROR		; => Nein, Kein Fehler...
			b $2c
::51			ldx	#DEV_NOT_FOUND
			rts

;*** Mehr RAM.
:Add64K			php				;Mausabfrage.
			sei
			lda	#$50
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

			lda	#$50
			jsr	PrntNewSize

			bit	mouseData		;Maustaste noch gedrückt?
			bpl	Add64K			;Ja -> mehr Speicher reservieren.
			ClrB	pressFlag
			rts

;*** Weniger RAM.
:Sub64K			php				;Mausabfrage.
			sei
			lda	#$58
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

			lda	#$58
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
			LoadW	r3 ,($12*8   ) ! DOUBLE_W
			LoadW	r4 ,($12*8+15) ! DOUBLE_W ! ADD1_W
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

			LoadB	r1H,$5b
			LoadW	r11,$0063 ! DOUBLE_W
			lda	#%11000000
			jmp	PutDecimal

;*** Icons für Auswahl Partitionsgröße zeichnen.
;Wird über die Dialogbox-Routine aufgerufen.
:Dlg_DrawIcons		jsr	i_BitmapUp
			w	Icon01
			b	$12 ! DOUBLE_B
			b	$50
			b	Icon01x ! DOUBLE_B
			b	Icon01y

			lda	C_DBoxDIcon
			jsr	i_UserColor
			b	$12 ! DOUBLE_B
			b	$50/8
			b	Icon01x ! DOUBLE_B
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

;*** Dialogbox.
:Dlg_GetSize		b %10000001
			b DB_USR_ROUT
			w Dlg_DrawBoxTitel
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

if Sprache = Deutsch
::53			b PLAINTEXT,BOLDON
			b "Partitionsgröße wählen:",NULL
::54			b "KBytes",NULL
endif

if Sprache = Englisch
::53			b PLAINTEXT,BOLDON
			b "Select partition size:",NULL
::54			b "KBytes",NULL
endif

:Dlg_Graphics1		b MOVEPENTO
			w $0060 ! DOUBLE_W
			b $50
			b FRAME_RECTO
			w $008f ! DOUBLE_W
			b $5f

:Dlg_Graphics2		b NEWPATTERN,$00
			b MOVEPENTO
			w $0061 ! DOUBLE_W
			b $51
			b RECTANGLETO
			w $008e ! DOUBLE_W
			b $5e
			b NULL

;*** Icons
:Icon01
<MISSING_IMAGE_DATA>

:Icon01x		= .x
:Icon01y		= .y
