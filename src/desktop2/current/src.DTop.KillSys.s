; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemdateien von Disk löschen.
;Ab $3573 im Speicher:
;Zufälliger Test auf Systemdiskette.
;Test ob Datei#2 = "GEOS BOOT".
;Test ob Datei#2 = Typ "SYSTEM_BOOT".
;Prüfsumme Datei#1 "GEOS" testen.
;Prüfsumme Datei#2 "GEOS BOOT" testen.
;Ggf. die ersten drei Dateien löschen.
;Kopierschutz?
:sysDkDelSysFiles	lda	#%00000011		;Auf 1 von 4 testen.
			and	random			;Zufallswert OK?
			bne	:exit			; => Nein, Ende...

			lda	GEOS_DISK_TYPE
			cmp	#"B"			;$42 = Startdiskette.
			bne	:exit			; => Nein, Ende...

;--- Datei "GEOS BOOT" vorhanden?
			ldy	#$09
::1			lda	dirDiskBuf +$20 +$05,y
			cmp	nameGEOSBOOT,y
			bne	:2			; => Nein, weiter...
			dey
			bpl	:1
			bmi	:3

;--- "SYSTEM_BOOT"-Datei vorhanden??
::2			lda	dirDiskBuf +$20 +$18
			cmp	#SYSTEM_BOOT
			beq	delSystemFiles
			rts

;--- CRC-Prüfsumme testen.
::3			ldx	dirDiskBuf +$04
			lda	dirDiskBuf +$03
			jsr	makeSysFileCRC
			bne	:exit

			cpy	#> $19fa		;Prüfsumme!
			bne	delSystemFiles
			cmp	#< $19fa
			bne	delSystemFiles

			ldx	dirDiskBuf +$20 +$04
			lda	dirDiskBuf +$20 +$03
			jsr	makeSysFileCRC
			bne	:exit

			cpy	#> $4ae7		;Prüfsumme!
			bne	delSystemFiles
			cmp	#< $4ae7
			bne	delSystemFiles

;--- Prüfung OK, nichts löschen.
::exit			rts

;*** Systemdateien von Disk löschen.
;Löscht die Einträge im Speicher und
;schreibt den Block zurück auf Disk.
:delSystemFiles		lda	#NULL
			ldy	#2
::1			sta	dirDiskBuf,y
			iny
			cpy	#32 *3
			bne	:1
			jmp	updateDirBlock

;*** Datei-Prüfsumme erstellen.
;Übergabe: A/X = Tr/Se erster Datenblock.
;Rückgabe: Y/A = 16Bit-CRC-Prüfsumme.
:makeSysFileCRC		stx	r1H
			sta	r1L

			lda	#> buf_diskSek1
			sta	r0H
			lda	#< buf_diskSek1
			sta	r0L

			ldy	#$00
			tya
::1			sta	(r0L),y
			iny
			bne	:1

::next			jsr	getDiskBlock
			jsr	exitOnDiskErr

			ldy	diskBlkBuf +1
			sty	r1H
			iny
			lda	#$00
			ldx	diskBlkBuf +0
			stx	r1L
			beq	:2

			tay
			lda	#$02

::2			sta	r2L
			clc
::3			dey
			lda	diskBlkBuf,y
			adc	(r0L),y
			sta	(r0L),y
			cpy	r2L
			bne	:3

			lda	r1L
			bne	:next

			ldy	#$00
			sty	r1L
			iny
			sty	r1H
			jsr	CRC

			ldy	r2H
			lda	r2L
			ldx	#NO_ERROR
			rts
