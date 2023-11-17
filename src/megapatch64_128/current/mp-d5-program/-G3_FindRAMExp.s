; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichererweiterung suchen.
;Beim Aufruf der Routine ist die MMU wie folgt konfiguriert:
;Bank#0 aktiviert da hier das KERNAL-ROM ist.
;CommonArea $0000-$3FFF aktiviert da hier das Startprogramm liegt.
;ROM und I/O-Bereich aktiviert für Hardware-Erkennung.
:FindRamExp		jsr	Strg_RamExp_Find	;Installationsmeldung ausgeben.

if Flag64_128 = TRUE_C64
			lda	CPU_DATA
			pha
			lda	#$37			;BASIC-ROM einblenden für
			sta	CPU_DATA		;Zahlenausgabe.
endif
if Flag64_128 = TRUE_C128
;--- Ergänzung: 08.09.18/M.Kanet
;Bank#0 aktivieren da hier das GEOS-System liegt.
;CommonArea $0000-$3FFF aktivieren da hier das Startprogramm liegt.
;ROM und I/O-Bereich aktivieren für Hardware-Erkennung.
;Hinweis: Die Version 3.01 hat die REU ebenfalls mit Bank#0/VIC-Bank#0
;getestet. CLKRATE muss auf 1MHz geschaltet werden da die Hardware nur so
;zuverlässig funktioniert. VICE unterstützt auch 2MHz.
			lda	MMU			;Bank#1 + ROM + I/O aktiv.
			pha
			lda	#%00001110
			sta	MMU
			lda	RAM_Conf_Reg		;CommonArea $0000-$3FFF + Bank#1VIC.
			pha
			lda	#%00000111
			sta	RAM_Conf_Reg
			lda	CLKRATE			;Takt auf 1MHz schalten wegen
			pha				;C=REU-Erkennung. Sonst geht nichts!
			lda	#$00
			sta	CLKRATE
endif

;--- Ergänzung: 27.09.19/M.Kanet
;Reihenfolge der RAM-Erkennung an GEOS.MP3 angepasst.
;Vergleiche auch "-G3_FindActDACC".

			jsr	Check_BBG		;Nach GeoRAM suchen und
			jsr	RamEx_SetData		;Test-Ergebnis speichern.

			jsr	Check_REU		;Nach REU suchen und
			jsr	RamEx_SetData		;Test-Ergebnis speichern.

			jsr	Check_RAMLink		;Nach RAMLink suchen und
			jsr	RamEx_SetData		;Test-Ergebnis speichern.

			jsr	Check_RAMCard		;Nach RAMCard suchen und
			jsr	RamEx_SetData		;Test-Ergebnis speichern.

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA		;GEOS-Bereich einblenden.
endif
if Flag64_128 = TRUE_C128
			pla
			sta	CLKRATE			;Takt zurücksetzen.
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU			;GEOS-Bereich + I/O einblenden.
endif

			jsr	RamEx_Select		;RAM-Erweiterung wählen.
			txa
			beq	RamEx_Info

			pla				;Rücksprung-Adresse vom
			pla				;Stack löschen.

if Flag64_128 = TRUE_C64
			lda	#$37			;Standard-ROM-Bereiche einblenden.
			sta	CPU_DATA
			cli
			jmp	ROM_BASIC_READY		;Zurück zum BASIC.
endif
if Flag64_128 = TRUE_C128
			lda	#%00000111		;CommonArea $000-$3FFF aktiv.
			sta	RAM_Conf_Reg
			lda	#%00000000		;Bank#0, ROM aktiv + I/O.
			sta	MMU
			cli
			rts
endif

;*** Informtionen über Speichererweiterung ausgeben.
:RamEx_Info		jsr	Strg_RamExp_OK		;Installationsmeldung ausgeben.

			lda	ExtRAM_Name +0		;Verwendete Speichererweiterung
			ldy	ExtRAM_Name +1		;ausgeben.
			jsr	Strg_CurText

;--- RAMLink ? Ja, DACC-Partition wählen.
			lda	BOOT_RAM_TYPE		;Erst-Start von MP3 ?
			bne	:51			; => Nein, weiter...

			lda	ExtRAM_Type
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
;    Übergabe:		AKKU = RAM-Typ od. $00 wenn nicht verfügbar.
;			xReg = $00, RAMUNIT verfügbar.
;			yReg = RAM-Größe.
:RamEx_SetData		sta	RAMUNIT			;RAM-Typ merken..
			cpx	#NO_ERROR		;Speichererweiterung erkannt?
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
:RamEx_Menu		ldx	BOOT_RAM_TYPE		;Installationsautomatik ?
			beq	RamEx_SlctRAM		; => Nein, weiter...

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
if Flag64_128 = TRUE_C128
			LoadB	r15L,%00001110		;MMU-Wert für RamLink Transfer
endif
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

			cli				;IRQ freiegeben => Cursor blinkt.

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
			sec				;Da nur 7Bytes => 1-4 abziehen.
::52			sbc	#$ff
			tay				;Ergebnis Taste x 7Bytes = Zeiger.
::53			jsr	RamEx_CopyData		;Daten der RamUnit einlesen.

;			lda	ExtRAM_Type		;Ist RamUnit verfügbar ?
			beq	:51			; => Nein, Taste ungültig...
;			ldx	ExtRAM_Size		;Weniger als 3x64KByte?
			cpx	#3			; => Ja, RAM_UNIT ungültig.
			bcc	:51

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
			ldx	#$06			;Anzahl 64Bänke x 64 ergibt die
::51			asl				;DACC-Größein KByte.
			rol	r0L
			dex
			bne	:51
			tax
			lda	r0L

if Flag64_128 = TRUE_C128
;Vor der Ausgabe von Zeichen über Kernal-Funktionen
;den Kernal+ROM-Bereich einblenden.
			tay
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU
			tya
endif

			jsr	ROM_OUT_NUMERIC

if Flag64_128 = TRUE_C128
			pla
			sta	MMU			;MMU-Register zurücksetzen.
endif

			jsr	PrntSpace		;Abstand.

			lda	#"K"			;Text "xxx Kb" ausgeben
			jsr	BSOUT
			lda	#"B"
			jmp	BSOUT

;*** Größe des RAMs rechtsbündig ausgeben.
;    Übergabe:		AKKU = Anzahl RAM-Bänke.
:PrntRSizeExtRAM	sta	r0H

::51			lda	PNTR			;Cursor positionieren.
			cmp	#22			;XPos=22 erreicht?
			bcs	:52			;Ja, weiter...

			lda	#"."			;NAME....(xxKb) Füllpunkt ausgeben.
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
			bcs	:54a
			jsr	PrntSpace		;128-996KByte

::54a			CmpBI	r0H,157
			bcs	:55
			jsr	PrntSpace		;1024-9216KByte

::55			lda	r0H
			jsr	PrintSizeExtRAM		;Speichergröße ausgeben.
			lda	#")"			;Textausgabe abschließen.
			jmp	BSOUT

;--- RAMLink: mehr als eine DACC-Partition -> Menü anzeigen.
::61

;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: Vor der Ausgabe von Zeichen über Kernal-Funktionen
;den Kernal-Bereich einblenden.
if Flag64_128 = TRUE_C128
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU
endif

			lda	#<RAM_RL_MENU_TXT	;Menütext ausgebe.
			ldy	#>RAM_RL_MENU_TXT
			jsr	ROM_OUT_STRING

if Flag64_128 = TRUE_C128
			pla
			sta	MMU			;MMU-Register zurücksetzen.
endif

			rts

;*** Auswahlmenü für RAMLink-DACC-Partition.
:RamEx_GetRLPart	lda	#$00
			sta	r3H
::51			jsr	GetRLPartNext		;Partitionsdaten einlesen.
;--- Ergänzung: 08.07.18/M.Kanet
;Code-Rekonstruktion: Vor der Ausgabe des Partitionsnamens bei der RAMLink
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
::51
if Flag64_128 = TRUE_C128
			LoadB	r15L,%00001110		;MMU-Wert für RamLink Transfer
endif

			jsr	GetRLPartEntry		;Partitionsdaten einlesen.

			lda	dirEntryBuf +0
			cmp	#$07			;DACC-Partition ?
			bne	GetRLPartNext		; => Nein, weitersuchen.

			lda	dirEntryBuf +28
			cmp	#$03			;Partitionsgröße ausreichend ?
			bcc	:51			; => Nein, weiter...
			rts

;*** Gewählte Partition anzeigen.
;--- Ergänzung: 02.07.18/M.Kanet
;Code-Rekonstruktion: In der Version von 2003 wurde die Platzierung
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

if Flag64_128 = TRUE_C128
;Vor der Ausgabe von Zeichen über Kernal-Funktionen
;den Kernal+ROM-Bereich einblenden.
			tay
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU
			tya
endif

			jsr	ROM_OUT_NUMERIC

if Flag64_128 = TRUE_C128
			pla
			sta	MMU			;MMU-Register zurücksetzen.
endif

			jsr	PrntSpace

			ldy	#$00			;Partitionsname ausgeben.
::52			lda	dirEntryBuf +3,y
			cmp	#$a0			;SHIFT-SPACE = ENDE
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

;*** Auf RAMCard testen.
:Check_RAMCard		jsr	Strg_RamExp_SCPU	;Installationsmeldung ausgeben.
			jsr	DetectSCPU		;Installierte SuperCPU erkennen.
			txa				;SuperCPU verfügbar?
			bne	:51			; => Nein, Ende.

			jsr	sysGetBCntSRAM		;Anzahl Speicherbänke ermitteln.
			lda	SRAM_BANK_COUNT		;Speicher verfügbar?
			beq	:51			; => Nein, Ende.

;--- SuperCPU mit RAMCard gefunden.
			ldy	SRAM_FREE_START		;Start des freien RAMs in der
			sty	RAMBANK_SCPU+1		;RAMCard zwischenspeichern.

			ldy	SRAM_BANK_COUNT
			tya
			cpy	#RAM_MAX_SIZE		;Größer als 4 MByte ?
			bcc	:50			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::50			sta	RAMSIZE_SCPU

			ldx	#NO_ERROR		;RAMCard erkannt.
			b $2c
::51			ldx	#DEV_NOT_FOUND		;Keine RAMCard erkannt.

			lda	#$00
			cpx	#NO_ERROR
			bne	:52
			lda	#RAM_SCPU		;Kennung für RAMCard speichern.
			sta	RAMUNIT_SCPU

::52			rts

;*** Auf C=REU/CMD-REU testen.
:Check_REU		jsr	Strg_RamExp_REU		;Installationsmeldung ausgeben.
			jsr	DetectCREU		;Installierte C=REU erkennen.
			txa				;C=REU verfügbar?
			bne	:51			; => Nein, Ende.

			jsr	sysGetBCntCREU		;Anzahl Speicherbänke ermitteln.
			lda	CREU_BANK_COUNT		;Speicher verfügbar?
			beq	:51			; => Nein, Ende.

;--- C=REU gefunden.
			ldy	CREU_BANK_COUNT
			tya
			cpy	#RAM_MAX_SIZE		;Größer als 4 MByte ?
			bcc	:50			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::50			sta	RAMSIZE_REU

			ldx	#NO_ERROR		;C=REU erkannt.
			b $2c
::51			ldx	#DEV_NOT_FOUND		;Keine C=REU erkannt.

			lda	#$00
			cpx	#NO_ERROR
			bne	:52
			lda	#RAM_REU		;Kennung für C=REU speichern.
			sta	RAMUNIT_REU

::52			rts

;*** Auf GeoRAM/BBGRAM testen.
:Check_BBG		jsr	Strg_RamExp_BBG		;Installationsmeldung ausgeben.

;--- Ergänzung: 27.08.18/M.Kanet
;Umschalten auf Bank#1 mit CommonArea + IO aktiv.
;Dadurch werden die Variablenn zur GeoRAM-Konfiguration in Bank#1 gespeichert
;von wo aus der RAM-Treiber dann auch im GEOS-Kernal installiert wird.
;--- Ergänzung: 09.09.18/M.Kanet
;Ist bei :FindRAMExp bereits gesetzt!
;			lda	MMU
;			pha
;			lda	#$7e
;			sta	MMU

			jsr	DetectGRAM		;Installierte GeoRAM erkennen.
			txa				;GeoRAM verfügbar?
			bne	:51			; => Nein, Ende.

			jsr	sysGetBCntGRAM		;Anzahl Speicherbänke ermitteln.
			lda	GRAM_BANK_VIRT64	;Speicher verfügbar?
			beq	:51			; => Nein, Ende.

;--- GeoRAM/BBGRAM gefunden.
			lda	GRAM_BANK_SIZE
			sta	Code3a + (DvRAM_GRAM_BSIZE - DvRAM_GRAM_START) +1
			ldx	#%11111110		;Bankgröße 64Kb: Page #255, Bank #0.
			ldy	#%00000000
			cmp	#$40
			beq	:49
			ldx	#%01111110		;Bankgröße 32Kb: Page #127, Bank #1.
			ldy	#%00000001
			cmp	#$20
			beq	:49
			ldx	#%00111110		;Bankgröße 16Kb: Page  #63, Bank #3.
			ldy	#%00000011
::49			stx	Code3a + (DvRAM_GRAM_SYSP - DvRAM_GRAM_START) +1
			sty	Code3a + (DvRAM_GRAM_SYSB - DvRAM_GRAM_START) +1

			ldy	GRAM_BANK_VIRT64
			tya
			cpy	#RAM_MAX_SIZE		;Größer als 4 MByte ?
			bcc	:50			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::50			sta	RAMSIZE_BBG

			ldx	#NO_ERROR		;GeoRAM erkannt.
			b $2c
::51			ldx	#DEV_NOT_FOUND		;Keine GeoRAM erkannt.

;			pla
;			sta	MMU

			lda	#$00
			cpx	#NO_ERROR
			bne	:52
			lda	#RAM_BBG		;Kennung für GeoRAM speichern.
			sta	RAMUNIT_BBG

::52			rts

;*** Auf RAMLink testen.
:Check_RAMLink		jsr	Strg_RamExp_RL		;Installationsmeldung ausgeben.
			jsr	DetectRLNK		;Installierte RAMLink erkennen.
			txa				;RAMLink verfügbar?
			bne	:51			; => Nein, Ende.

			jsr	GetSizeRAM_RL		;RAMLink-Speicher ermitteln.

			cpy	#$00			;Speicher in RAMLink installiert ?
			beq	:51			; => Nein, weiter...

			ldx	#NO_ERROR		;RAMLink erkannt.
			b $2c
::51			ldx	#DEV_NOT_FOUND		;Keine RAMLink erkannt.

			lda	#$00
			cpx	#NO_ERROR
			bne	:52
			lda	#RAM_RL			;Kennung für RAMLink speichern.
			sta	RAMUNIT_RL

::52			rts

;*** Größe des RAMLink-Speichers ermitteln.
:GetSizeRAM_RL		ldx	#$00
			stx	r3L
			inx				;Partitions-Nr. auf #1 setzen.
			stx	r3H

::51
if Flag64_128 = TRUE_C128
			LoadB	r15L,%00001110		;MMU-Wert für RamLink Transfer
endif
			jsr	GetRLPartEntry		;Partitonsdaten einlesen.

			lda	dirEntryBuf +0
			cmp	#$07			;DACC-Partition?
			bne	:53			; => Nein, weiter...

			lda	dirEntryBuf +28		;Partitionsgröße einlesen.
			cmp	#$03			;Mind. 192Kb ?
			bcc	:53			; => Nein, weiter...
			sta	RAMSIZE_RL		;Partitionsgröße merken.

			ldx	dirEntryBuf +21		;Startadresse der Partition
			stx	RAMBANK_RL  +0		;einlesen.
			ldx	dirEntryBuf +20
			stx	RAMBANK_RL  +1

			lda	r3H			;Partitionsnummer merken.
			sta	RAMPART_RL

			inc	r3L			;DACC-Partitionszähler +1.
::53			inc	r3H			;Zähler auf nächste Partition.
			CmpBI	r3H,32			;Ende erreicht (max. 32Part.)?
			bcc	:51			;Nein, weiter...

			dec	r3L			;Nur eine DACC gefunden?
			beq	:54			; => Ja, Ende...
			lda	#$ff			;$FF = Auswahlmenü anzeigen.
			tay
			sty	RAMPART_RL
			bne	:56

::54			lda	RAMSIZE_RL		;Tatsächliche Größe ins Y-Register
			tay				;kopieren.
			cmp	#RAM_MAX_SIZE		;Größer als 4 MByte ?
			bcc	:55			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;Größe DACC auf 4 MByte begrenzen.
::55			sta	RAMSIZE_RL
::56			rts				;Ende...

;*** RAMLink-Startpartition suchen.
:FindRL_Part		jsr	Strg_DvInit_Info	;Installationsmeldung ausgeben.

			lda	Boot_Type
			and	#%11110000		;CMD-Geräte-Daten isolieren.
			cmp	#DrvRAMLink		;CMD-RAMLink ?
			beq	:51			; => Ja, weiter...
			rts

::51			jsr	Strg_DvInit_RL		;Installationsmeldung ausgeben.

			php
			sei

if Flag64_128 = TRUE_C64
;--- Ergänzung: 10.09.18/M.Kanet
;Beim C128 ist ROM + I/O bereits aktiv.
;Beim C64 müsste das auch bereits der Fall sein. Der Befehl
;könnte also in Zukunft entfallen.
			lda	CPU_DATA		;Kernal-ROM + I/O einblenden.
			pha
			lda	#$36
			sta	CPU_DATA
endif

			jsr	GetPartInfo		;Daten der aktiven Partition
							;einlesen.
if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif

			plp

;			lda	GP_Data   +21		;RAM-Startadresse speichern.
;			sta	Boot_Part + 0		;HighByte reicht, da der MP3-RL-
			lda	GP_Data   +20		;Treiber die Adresse selbst
			sta	Boot_Part + 1		;ermittelt!

			ldx	GP_Data   + 2		;Partitions-Nr. ausgeben.
			stx	Boot_Part + 0
			lda	#$00

if Flag64_128 = TRUE_C128
;Vor der Ausgabe von Zeichen über Kernal-Funktionen
;den Kernal+ROM-Bereich einblenden.
			tay
			lda	MMU			;Bank#0, RAM bis $3FFF ROM + I/O.
			pha
			lda	#$00
			sta	MMU
			tya
endif

			jsr	ROM_OUT_NUMERIC

if Flag64_128 = TRUE_C128
			pla
			sta	MMU			;MMU-Register zurücksetzen.
endif

			rts

;*** Daten an Floppy senden.
:GetPartInfo		lda	#$00
			sta	STATUS			;Status löschen.

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			lda	RL_BootAddr
			jsr	LISTEN			;LISTEN-Signal auf IEC-Bus senden.
			lda	#$ff
			jsr	SECOND			;Sekundär-Adr. nach LISTEN senden.

			bit	STATUS			;Laufwerk vorhanden ?
			bmi	:52			;Nein, Abbruch...

			ldy	#$00
::51			lda	GP_Befehl,y		;Byte aus Speicher
			jsr	CIOUT			;lesen & ausgeben.
			iny
			cpy	#$05
			bne	:51

			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			jmp	ReadPartInfo

::52			jsr	UNLSN			;UNLISTEN-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** Daten von Floppy empfangen.
:ReadPartInfo		lda	#$00
			sta	STATUS			;Status löschen.

			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.

			lda	RL_BootAddr
			jsr	TALK			;TALK-Signal auf IEC-Bus senden.
			lda	#$ff
			jsr	TKSA			;Sekundär-Adresse nach TALK senden.

			bit	STATUS			;Laufwerk vorhanden ?
			bmi	:52			;Nein, Abbruch...

			ldy	#$00
::51			jsr	ACPTR			;Byte einlesen und in
			sta	GP_Data,y		;Speicher schreiben.
			iny
			cpy	#31
			bne	:51

			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			ldx	#$00			;Flag: "Kein Fehler!"
			rts
::52			jsr	UNTALK			;UNTALK-Signal auf IEC-Bus senden.
			ldx	#$ff			;Flag: "Fehler!"
			rts

;*** RAM-Erkennung.
:RAMUNIT_COUNT		b $00
:RAMUNIT		b $00

;******************************************************************************
;*** Start der RAMUNIT Daten.
;******************************************************************************
:RAMUNIT_DATA

:RAMUNIT_BBG		b $00				;$00 = BBG-RAM nicht verfügbar.
:RAMSIZE_BBG		b $00				;DACC-Größe.
:RAMBANK_BBG		w $0000				;Dummy-Byte.
:RAMPART_BBG		b $00				;Dummy-Byte.
:RAMNAME_BBG		w BootText14

:RAMUNIT_REU		b $00				;$00 = C=REU nicht verfügbar.
:RAMSIZE_REU		b $00				;DACC-Größe.
:RAMBANK_REU		w $0000				;Dummy-Byte.
:RAMPART_REU		b $00				;Dummy-Byte.
:RAMNAME_REU		w BootText13

:RAMUNIT_RL		b $00				;$00 = RAMLink nicht verfügbar.
:RAMSIZE_RL		b $00				;DACC-Größe.
:RAMBANK_RL		w $0000				;DACC-Startadresse.
:RAMPART_RL		b $00				;DACC-Partition.
:RAMNAME_RL		w BootText12

:RAMUNIT_SCPU		b $00				;$00 = RAMCARD nicht verfügbar.
:RAMSIZE_SCPU		b $00				;DACC-Größe.
:RAMBANK_SCPU		w $0000				;DACC-Startadresse.
:RAMPART_SCPU		b $00				;Dummy-Byte.
:RAMNAME_SCPU		w BootText11
;******************************************************************************

:RAM_RL_MENU_TXT	b " -MENU- )",0
