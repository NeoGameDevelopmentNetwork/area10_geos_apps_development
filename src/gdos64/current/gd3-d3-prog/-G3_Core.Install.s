; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Die folgenden Routinen werden von "GD.BOOT" und "GD.UPDATE"
;*** gemeinsam verwendet. Änderungen wirken sich auf beide Programme aus!!!
;******************************************************************************

;*** GEOS-Variablenspeicher löschen.
:InitSys_ClrVar		LoadW	r0,$8000		;Zeiger auf Variablenspeicher.

			ldx	#$10			;Speicherbereich löschen. ACHTUNG!
			ldy	#$00			;Nicht über FillRam, da das GEOS-
			tya				;Kernal zu diesem Zeitpunkt noch
::51			sta	(r0L),y			;nicht installiert ist!
			iny
			bne	:51
			inc	r0H
			dex
			bne	:51

			rts

;*** Farb-RAM löschen.
;    Übergabe: AKKU = Farbwert.
:InitSys_ClrCol		ldy	#$00
::52			sta	COLOR_MATRIX +$0000,y
			sta	COLOR_MATRIX +$0100,y
			sta	COLOR_MATRIX +$0200,y
			sta	COLOR_MATRIX +$02e8,y
			iny
			bne	:52

			rts

;*** Laufwerkstreiber installieren.
;Übergabe: r0 = Zeiger auf Laufwerkstreiber.
:CopySys_DISK		LoadW	r1,DISK_BASE		;Laufwerkstreiber aus Startdatei
							;nach $9000 kopieren.

			ldx	#> DISK_DRIVER_SIZE
			jsr	copy256Bytes

			ldy	#< DISK_DRIVER_SIZE
			jsr	copyUsrBytes

			rts

;*** GEOS-Kernal installieren.
;Übergabe: r0 = Zeiger auf Kernaldaten.
:CopySys_GEOS		LoadW	r1,OS_LOW		;GEOS-Kernal aus Startdatei
							;nach $9D80-9FFF kopieren.
			ldx	#$02
			jsr	copy256Bytes

			ldy	#$80
			jsr	copyUsrBytes
			lda	#$80
			jsr	addUsrBytes_r0

			LoadW	r1,$bf40		;GEOS-Kernal aus Startdatei
							;nach $BF40-FFFF kopieren.
			ldx	#$40
			jsr	copy256Bytes
			ldy	#$c0
			jsr	copyUsrBytes

			rts

;*** Daten in RAM kopieren.
:copy256Bytes		ldy	#$00
::1			lda	(r0L),y
			sta	(r1L),y
			iny
			bne	:1
			inc	r0H
			inc	r1H
			dex
			bne	:1
			rts

:copyUsrBytes		dey
			lda	(r0L),y
			sta	(r1L),y
			tya
			bne	copyUsrBytes
			rts

:addUsrBytes_r0		clc
			adc	r0L
			sta	r0L
			bcc	:1
			inc	r0H
::1			rts

;*** GDOS-Kernal installieren.
:CopySys_GDOS		lda	#$00			;Kernal-Funktionen in REU
::gd_loop1		pha				;kopieren.
			asl
			sta	:gd_tmp +1
			asl
			clc
::gd_tmp		adc	#$ff
			tay
			ldx	#$00
::gd_loop2		lda	GDOS_BANK_DATA,y	;Zeiger auf Position in Startdatei
			sta	r0L,x			;einlesen.
			iny
			inx
			cpx	#$06
			bcc	:gd_loop2

			lda	MP3_64K_SYSTEM		;Speicherbank festlegen.
			sta	r3L

			jsr	BOOT_STASHRAM		;Daten in REU kopieren.
			jsr	BOOT_VERIFYRAM		;Daten überprüfen.
			and	#%00100000
			tax

			pla
			cpx	#$00			;Fehler?
			bne	:err			; => Ja, Abbruch...

			clc
			adc	#$01
			cmp	#GDOS_EXT_MODULES	;Alle Datenblöcke kopiert ?
			bcc	:gd_loop1		; => Nein, weiter...

;--- Bildschirmschoner.
;Standard-Bildschirmschoner wird beim
;Systemstart automatisch geladen.
if FALSE
			jsr	SetADDR_ScrSaver
			jsr	SwapRAM

			jsr	i_FillRam
			w	R2S_SCRSAVER
			w	LOAD_SCRSAVER
			b	$00

			jsr	SetADDR_ScrSaver
			jsr	SwapRAM
endif

			ldx	#NO_ERROR
::err			rts

;*** RBOOT-Kernal installieren.
;    Rückgabe: xReg=$00: Kein Fehler.
:CopySys_RBOOT		ldx	#$00			;Zeiger auf ReBoot-Datentabelle.
			lda	GEOS_RAM_TYP		;RAM-Typ einlesen.
			cmp	#RAM_SCPU		;SuperCPU ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_RL			;RAMLink ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_REU		;C=REU ?
			beq	:51			;Ja, weiter...
			inx
			inx
			cmp	#RAM_BBG		;BBGRAM ?
			beq	:51			;Ja, weiter...
			ldx	#$04

::51			lda	Vec_ReBoot +0,x		;Startadresse für ReBoot-Routine
			sta	r0L			;einlesen.
			lda	Vec_ReBoot +1,x
			sta	r0H

			ldy	#3			;Für RAMLink und SuperCPU die
			lda	RamBankFirst +0		;Adresse der ersten Speicherbank
			sta	(r0L),y			;in ReBoot-Code übernehmen.
			iny				;Bei C=REU und GEORAM ohne
			lda	RamBankFirst +1		;Funktion (immer $0000).
			sta	(r0L),y

			lda	#$00
			sta	r1L
			ldx	#> R1A_REBOOT		;Startadresse in REU.
			stx	r1H
			sta	r2L
			ldx	#> R1S_REBOOT		;Anzahl Bytes.
			stx	r2H
;			lda	#$00
			sta	r3L			;GEOS-Speicherbank.
			jsr	BOOT_STASHRAM		;Daten in REU kopieren.
			jsr	BOOT_VERIFYRAM		;Daten überprüfen.
			and	#%00100000		;Fehler?
			tax
			rts

;*** DACC-Informationen setzen.
:InitSys_SetDACC	ldx	ExtRAM_Size		;Größe des ermittelten Speichers
			cpx	#3			;Weniger als 3x64Kb?
			bcc	:err			; => Ja, Abbruch...
			cpx	#RAM_MAX_SIZE		;an GEOS übergeben.
			bcc	:1
			ldx	#RAM_MAX_SIZE
::1			stx	ramExpSize

			dex				;Speicherbereich für Megapatch-
			stx	MP3_64K_SYSTEM		;Kernal in REU festlegen.
			dex
			stx	MP3_64K_DATA
			ldx	#$00			;Laufwerkstreiber von
			stx	MP3_64K_DISK		;Diskette installieren.

			lda	ExtRAM_Bank  +0
			sta	RamBankFirst +0
			lda	ExtRAM_Bank  +1
			sta	RamBankFirst +1

			lda	ExtRAM_Type		;RAM-Typ an GEOS übergeben.
			sta	GEOS_RAM_TYP

;			ldx	#NO_ERROR		;XReg ist bereits #0 = Kein Fehler.
			b $2c
::err			ldx	#DEV_NOT_FOUND
			rts
