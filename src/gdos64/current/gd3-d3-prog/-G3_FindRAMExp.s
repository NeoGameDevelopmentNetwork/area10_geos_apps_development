; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichererweiterung suchen.
:FindRamExp		jsr	Strg_RamExp_Find	;Installationsmeldung ausgeben.

			lda	CPU_DATA
			pha
			lda	#KRNL_BAS_IO_IN		;BASIC-ROM einblenden für
			sta	CPU_DATA		;Zahlenausgabe.

;--- Ergänzung: 27.09.19/M.Kanet
;Reihenfolge der RAM-Erkennung an GD.UPDATE angepasst.
;Vergleiche auch "-G3_FindActDACC".

			jsr	Check_BBG		;Nach GeoRAM suchen und
			jsr	RamEx_SetData		;Test-Ergebnis speichern.

			jsr	Check_REU		;Nach REU suchen und
			jsr	RamEx_SetData		;Test-Ergebnis speichern.

			jsr	Check_RAMLink		;Nach RAMLink suchen und
			jsr	RamEx_SetData		;Test-Ergebnis speichern.

			jsr	Check_RAMCard		;Nach RAMCard suchen und
			jsr	RamEx_SetData		;Test-Ergebnis speichern.

			pla
			sta	CPU_DATA		;GEOS-Bereich einblenden.

			jsr	RamEx_Select		;RAM-Erweiterung wählen.
			txa
			beq	RamEx_Info

			pla				;Rücksprung-Adresse vom
			pla				;Stack löschen.

			lda	#KRNL_BAS_IO_IN		;Standard-ROM-Bereiche einblenden.
			sta	CPU_DATA
			cli
			jmp	ROM_BASIC_READY		;Zurück zum BASIC.

;*** Informtionen über Speichererweiterung ausgeben.
:RamEx_Info		jsr	Strg_RamExp_OK		;Installationsmeldung ausgeben.

			lda	ExtRAM_Name +0		;Verwendete Speichererweiterung
			ldy	ExtRAM_Name +1		;ausgeben.
			jsr	Strg_CurText

;--- RAMLink ? Ja, DACC-Partition wählen.
			lda	BOOT_RAM_TYPE
			cmp	#$ff			;DACC neu wählen?
			beq	:50			; => Ja, weiter...
			cmp	#$00			;Speichererweiterung definiert?
			bne	:51			; => Nein, weiter...

::50			lda	ExtRAM_Type
			cmp	#RAM_RL			;RAMLink installieren ?
			bne	:51			; => Nein, weiter...
			lda	ExtRAM_Part		;Mehr als eine DACC-Partition ?
			bpl	:51			; => Nein, weiter...

			jsr	Strg_RamExp_DACC	;RAMLink-DACC-Partition wählen.
			jsr	RamEx_GetRLPart
			ldx	#NO_ERROR
			rts

;--- Gewählten RAM-Typ und RAM-Größe ausgeben.
::51			lda	#CR			;Leerzeile ausgeben.
			jsr	BSOUT

			jsr	PrntSpace		;Position für Textausgabe über
			jsr	PrntSpace		;Leerzeichen setzen.

			lda	ExtRAM_Size		;Größe des erweiterten Speichers
			jsr	PrintSizeExtRAM		; => max. 4Mb ausgeben.
			jsr	Strg_RamExp_Size	;Installationsmeldung ausgeben.
			ldx	#NO_ERROR
			rts

;*** Daten für Speichererweiterung setzen.
;    Übergabe:		AKKU = RAM-Typ oder $00 wenn nicht verfügbar.
;			xReg = $00, RAMUNIT verfügbar.
;			yReg = RAM-Größe.
:RamEx_SetData		sta	RAMUNIT			;RAM-Typ merken.
			cpx	#$00			;Speichererweiterung erkannt?
			bne	:51			;Nein, weiter...
			tya				;Anzahl 64K-Bänke im DACC.
			cmp	#3			;Weniger als 3x64Kb Speicher?
			bcc	:52			;Ja, Abbruch...
			inc	RAMUNIT_COUNT		;Anzahl RAM_UNITs +1.
			jsr	PrntRSizeExtRAM		;Speicher in KBytes ausgeben.
			jsr	PrntDoublePoint		;Textausgabe formatieren.
			jmp	Strg_OK			;Installationsmeldung ausgeben.

::51			lda	#$00			;RAM nicht verfügbar => 0KByte.
::52			jsr	PrntRSizeExtRAM		;Speicher in KBytes ausgeben.
			jsr	PrntDoublePoint		;Textausgabe formatieren.
			jmp	Strg_Error		;Installationsmeldung ausgeben.

;*** Größe des Speichers ausgeben.
:RamEx_Select		lda	RAMUNIT_COUNT		;Anzahl RAM_UNITs ?
			beq	Check_NoRAM		; => Kein RAM, Ende...

			cmp	#$01			;Mehr als eine RAM-Unit ?
			bne	RamEx_Menu		; => Ja, Auswahlmenü.

			ldy	#$00			;Daten der verfügbaren
::51			jsr	RamEx_CopyData		;Speichererweiterung suchen.

;			lda	ExtRAM_Type		;Daten gefunden ?
			beq	:53			; => Nein, weiter...
;			ldx	ExtRAM_Size
			cpx	#3			;Mind. 3x64KByte Speicher?
			bcc	:53			; => Nein, weiter...
			ldx	#NO_ERROR
			rts

::53			cpy	#4*7			;Zeiger auf die nächsten Daten.
			bcc	:51			;Ende erreicht? => Nein, weiter...

;*** Keine Speichererweiterung gefunden.
:Check_NoRAM		jsr	Strg_RamExp_Exit	;Installationsmeldung ausgeben.
			ldx	#DEV_NOT_FOUND
			rts

;*** Daten der Speichererweiterung übertragen.
;    Übergabe: YReg = Zeiger auf erstes Byte der Daten.
:RamEx_CopyData		ldx	#$00			;Daten der Speichererweiterung
::51			lda	RAMUNIT_DATA,y		;in Systemspeicher übertragen.
			sta	ExtRAM_Type ,x
			iny
			inx
			cpx	#$07
			bcc	:51
			ldx	ExtRAM_Size		;RamUnit Größe einlesen.
			lda	ExtRAM_Type		;RamUnit Typ einlesen.
			rts

;*** Auswahlmenü für Speichererweiterung ausgeben.
:RamEx_Menu		ldx	BOOT_RAM_TYPE		;Speichererweiterung definiert?
			beq	RamEx_SlctRAM		; => Nein, weiter...
			cpx	#$ff			;DACC neu wählen?
			beq	RamEx_SlctRAM		; => Ja, weiter...

			ldy	#$00			;Daten für SCPU/CREU/GRAM/RLNK
::51			jsr	RamEx_CopyData		;einlesen, jeweils 7Bytes.

;			lda	ExtRAM_Type
			cmp	BOOT_RAM_TYPE		;RamUnit gefunden ?
			bne	:52			; => Nein, weiter...
;			ldx	ExtRAM_Size
			cpx	#3			;Mind. 3x64KByte Speicher?
			bcs	:53			; => Ja, weiter...

::52			cpy	#4*7			;Alle RamUnits durchsucht ?
			bcc	:51			; => Nein, weiter...
			jmp	RamEx_SlctRAM		;RamUnit nicht mehr verfügbar,
							;Auswahlmenu darstellen.

;--- Autoselect-Daten auf Gültigkeit testen.
;Ab hier AKKU = BOOT_RAM_TYPE
::53			cmp	#RAM_RL			;RamUnit = RAMLink ?
			bne	:54			; => Nein, weiter...

			lda	BOOT_RAM_PART		;Ist Partition ausgewählt ?
			beq	RamEx_SlctRAM		; => Nein, Menü starten.
			sta	r3H
			jsr	GetRLPartEntry		;Partitionsdaten einlesen.

			lda	dirEntryBuf +0
			cmp	#$07			;Partition = DACC ?
			bne	RamEx_SlctRAM		; => Nein, Menü starten.

			lda	dirEntryBuf +21		;Partitionsdaten für
			sta	ExtRAM_Bank +0		;GEOS-DACC definieren.
			lda	dirEntryBuf +20
			sta	ExtRAM_Bank +1

			lda	dirEntryBuf +28		;Partitionsgröße einlesen.
			cmp	#3			;Mind. 3x64Kb ?
			bcc	RamEx_SlctRAM		; => Nein, Menü starten.
			cmp	#RAM_MAX_SIZE		;Größer 4Mb?
			bcc	:53a			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;DACC auf 4Mb beschränken.
::53a			sta	ExtRAM_Size		;Speichergröße merken.

			lda	r3H			;DACC-Partitionsnummer merken.
			sta	ExtRAM_Part

::54			jsr	Strg_RamExp_Auto	;Installationsmeldung ausgeben.
			ldx	#NO_ERROR
			rts

;*** Auswahlmenü anzeigen.
:RamEx_SlctRAM		jsr	Strg_RamExp_Menu	;Menü ausgeben.

			cli				;IRQ freigeben => Cursor blinkt.

::51			jsr	GETIN			;Auf Taste 1/2/3/4 warten.
			tax				;Taste gedrückt ?
			beq	:51			; => Nein, weiter...

			cpx	#"1"			;Gültige Taste gedrückt ?
			bcc	:51			; => Nein, warten auf gültige Taste.
			cpx	#"5"
			bcs	:51			; => Nein, warten auf gültige Taste.

			txa				;Zeiger auf Speicher der Daten für
			sec				;Speichererweiterung berechnen.
			sbc	#$31
			sta	:52 +1
			asl				;Taste #1 bis #4 => Werte 0-3.
			asl				;Wert x 8.
			asl
			sec				;Da nur 7Bytes => 0-3 abziehen.
::52			sbc	#$ff
			tay				;Ergebnis Taste x 7Bytes = Zeiger.
::53			jsr	RamEx_CopyData		;Daten der RamUnit einlesen.

;			lda	ExtRAM_Type		;Ist RamUnit verfügbar ?
			beq	:51			; => Nein, Taste ungültig...
;			ldx	ExtRAM_Size
			cpx	#3			;Weniger als 3x64KByte?
			bcc	:51			; => Ja, RamUnit ungültig.

			sei

			ldx	#NO_ERROR
			rts

;*** Trennzeichen ausgeben.
:PrntDoublePoint	lda	#":"
			jmp	BSOUT
:PrntSpace		lda	#" "
			jmp	BSOUT

;*** Größe des RAMs ausgeben.
;    Übergabe:		AKKU = Anzahl RAM-Bänke.
:PrintSizeExtRAM	ldx	#$00			;High-Byte 16Bit-Wert der
			stx	r0L			;Speichergröße löschen.
			ldx	#$06			;Anzahl Bänke x 64 ergibt die
::51			asl				;DACC-Größe in KByte.
			rol	r0L
			dex
			bne	:51
			tax
			lda	r0L
			jsr	ROM_OUT_NUMERIC

			jsr	PrntSpace		;Abstand.

			lda	#"K"			;Text "xxx Kb" ausgeben.
			jsr	BSOUT
			lda	#"B"
			jmp	BSOUT

;*** Größe des RAMs rechtsbündig ausgeben.
;    Übergabe:		AKKU = Anzahl RAM-Bänke.
:PrntRSizeExtRAM	sta	r0H

::51			lda	PNTR			;Cursor positionieren.
			cmp	#22			;XPos=22 erreicht?
			bcs	:52			;Ja, weiter...

			lda	#"."			;Name....(xxKb) Füllpunkt ausgeben.
			jsr	BSOUT

			jmp	:51			;Schleife.

::52			lda	#"("			;Größe des DACC rechtsbündig
			jsr	BSOUT			;ausgeben.

			lda	r0H
			ldx	RAMUNIT
			cpx	#RAM_RL			;RAMLink-DACC?
			bne	:52a			;Nein, weiter...
			cmp	#255			;Auswahlmenü anzeigen?
			beq	:61			;Ja, weiter...

::52a			cmp	#1			;Speichergröße formatieren durch
			bcs	:53			;Ausgabe zusätzlicher Leerzeichen.
			jsr	PrntSpace		;0KByte

::53			CmpBI	r0H,2
			bcs	:54
			jsr	PrntSpace		;64KByte

::54			CmpBI	r0H,16
			bcs	:55
			jsr	PrntSpace		;128-996KByte

::55			CmpBI	r0H,157
			bcs	:56
			jsr	PrntSpace		;1024-9216KByte

::56			lda	r0H
			jsr	PrintSizeExtRAM		;Speichergröße ausgeben.
			lda	#")"			;Textausgabe abschließen.
			jmp	BSOUT

;--- RAMLink: Mehr als eine DACC-Partition -> Menü anzeigen.
::61			lda	#< RAM_RL_MENU_TXT	;Menütext ausgeben.
			ldy	#> RAM_RL_MENU_TXT
			jmp	ROM_OUT_STRING

;*** Auswahlmenü für RAMLink-DACC-Partition.
:RamEx_GetRLPart	lda	#$00
			sta	r3H
::51			jsr	GetRLPartNext		;Partitionsdaten einlesen.
;--- Ergänzung: 08.07.18/M.Kanet
;Vor der Ausgabe des Partitionsnamens bei der RAMLink
;das Register r3H sichern und anschließend zurücksetzen.
			lda	r3H
			pha
			jsr	PrintPartName		;Partitionsname ausgeben.
			pla
			sta	r3H

			cli
::52			jsr	GETIN			;Auf Taste warten.
			tax
			beq	:52
			cpx	#" "			;Gültige Taste gedrückt ?
			beq	:51			; => Ja, nächste Partition.
			cpx	#CR
			bne	:52			; => Nein, warten auf gültige Taste.

			lda	dirEntryBuf +28
			cmp	#RAM_MAX_SIZE		;Größer als 4 MByte ?
			bcc	:53			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::53			sta	ExtRAM_Size

			ldx	dirEntryBuf +21		;Startadresse DACC-Partition
			stx	ExtRAM_Bank +0		;definieren.
			ldx	dirEntryBuf +20
			stx	ExtRAM_Bank +1

			lda	r3H			;Partitions-Nr. merken.
			sta	ExtRAM_Part

			lda	#CR			;Leerzeile ausgeben.
			jsr	BSOUT

			sei				;Interrupt sperren, Ende.
			rts

;*** Nächste DACC-Partition suchen.
:GetRLPartNext		inc	r3H			;Zeiger auf nächste Partition.
			CmpBI	r3H,32			;Letzte Partition erreicht ?
			bcc	:51			; => Nein, weiter...
			LoadB	r3H,1			;Zeiger auf erste Partition.
::51			jsr	GetRLPartEntry		;Partitionsdaten einlesen.

			lda	dirEntryBuf +0
			cmp	#$07			;DACC-Partition ?
			bne	GetRLPartNext		; => Nein, weitersuchen.

			lda	dirEntryBuf +28
			cmp	#$03			;Partitionsgröße ausreichend ?
			bcc	:51			; => Nein, weiter...
			rts

;*** Gewählte Partition anzeigen.
;--- Ergänzung: 02.07.18/M.Kanet
;In der MegaPatch/2003-Version wurde die Platzierung
;des Cursors für die Ausgabe der Partition korrigiert.
:PrintPartName		lda	#23			;Cursor positionieren.
			sta	TBLX
			lda	#02
			sta	PNTR

			lda	#"P"			;Partitions-Nr. ausgeben.
			jsr	BSOUT

			CmpBI	r3H,10
			bcs	:51
			lda	#"0"
			jsr	BSOUT

::51			ldx	r3H
			lda	#$00
			jsr	ROM_OUT_NUMERIC

			jsr	PrntSpace

			ldy	#$00			;Partitionsname ausgeben.
::52			lda	dirEntryBuf +3,y
			cmp	#$a0			;SHIFT-SPACE = Ende.
			beq	:53
			cmp	#$61			;A-Z umwandeln nach a-z.
			bcc	:52a
			cmp	#$7e
			bcs	:52a
			sec
			sbc	#$20
::52a			jsr	BSOUT			;Zeichen ausgeben.
			iny
			cpy	#$10
			bcc	:52

::53			lda	dirEntryBuf +28		;Partitionsgröße ausgeben.
			jmp	PrntRSizeExtRAM
