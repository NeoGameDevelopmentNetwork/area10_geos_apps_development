; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Kernal in REU kopieren.
;******************************************************************************
;*** Aktuelles GEOS-Kernal in REU kopieren.
:CopyKernal2REU		lda	sysRAMFlg
			ora	#%00100000		;Flag "Kernal in REU gespeichert".
			sta	sysRAMFlg		;(für ReBoot-Funktion).

			ldy	#0 *8			;Systemvariablen in REU kopieren.
			jsr	setVecKernalData
			jsr	StashRAM

;			ldy	#1 *8			;Laufwerkstreiber in REU kopieren.
;			jsr	setVecKernalData
;			jsr	StashRAM

			ldy	#1 *8			;Kernal Teil #1 in REU kopieren.
			jsr	setVecKernalData
			jsr	StashRAM

			ldy	#2 *8			;Kernal Teil #2 in REU kopieren.
			jsr	setVecKernalData
			jsr	StashRAM

;--- Kernal sichern.
;Dazu die Daten aus dem Kernal in einen
;Zwischenspeicher kopieren, damit auch
;Daten unterhalb des I/O-Bereichs von
;StashRAM gesichert werden können.
			ldy	#3 *8			;Kernal Teil #3 in REU kopieren.
			jsr	setVecKernalData

			lda	#>  R1S_SYS_PRG3
			sta	r4L			;$30 x 256 Bytes kopieren.

			LoadW	r5 ,$d000		;Startadresse Bereich $D000-$FFFF.

::loop			php				;Kernaldaten in temporären
			sei				;Zwischenspeicher kopieren.
			ldy	#$00
::1			lda	(r5L),y
			sta	diskBlkBuf,y
			iny
			bne	:1
			plp

			jsr	StashRAM		;Zwischenspeicher nach REU.

			inc	r5H
			inc	r1H
			dec	r4L			;Alle Kernaldaten kopiert ?
			bne	:loop			; => Nein, weiter...

			ldy	#4 *8			;Mauszeiger in REU kopieren.
			jsr	setVecKernalData
			jmp	StashRAM

;*** Speicherbereich in REU sichern.
;Übergabe: YReg   = Zeiger auf Tabelle.
;Rückgabe: r0-r3L = Zeiger auf RAM/REU.
:setVecKernalData	ldx	#0
::1			lda	RBootMemData,y		;Daten für StashRAM aus Tabelle
			sta	r0,x			;einlesen und nach r0-r3L schreiben.
			iny
			inx
			cpx	#7			;Alle Bytes kopiert?
			bcc	:1			; => Nein, weiter...

			jmp	StashRAM

;*** Liste der Datenbereiche.
:RBootMemData		w $8400				;Systemvariablen in REU kopieren.
			w R1A_SYS_VAR1			;C64: $8400-$88FF
			w R1S_SYS_VAR1			;REU: $7900-$7DFF
			b $00				;Speicherbank
			b $ff				;Dummy-Byte

;--- Hinweis:
; -> Entfällt, alle Treiber
;    sind bereits in der REU!
;			w $9000				;Laufwerkstreiber in REU kopieren.
;			w $8300				;C64: $9000-$9D7F
;			w $0d80				;REU: $8300-$907F
;			b $00				;Speicherbank
;			b $ff				;Dummy-Byte

			w $9d80				;Kernal Teil #1 in REU kopieren.
			w R1A_SYS_PRG1			;C64: $9D80-$9FFF
			w R1S_SYS_PRG1			;REU: $B900-$BB7F
			b $00				;Speicherbank
			b $ff				;Dummy-Byte

			w $bf40				;Kernal Teil #2 in REU kopieren.
			w R1A_SYS_PRG2			;C64: $BF40-$CFFF
			w R1S_SYS_PRG2			;REU: $BB80-$CC3F
			b $00				;Speicherbank
			b $ff				;Dummy-Byte

			w diskBlkBuf			;Kernal Teil #3 in REU kopieren.
			w R1A_SYS_PRG3			;C64: $D000-$FFFF
			w $0100				;REU: $CC40-$FC3F
			b $00				;Speicherbank
			b $ff				;Dummy-Byte

			w mousePicData			;Mauszeiger in REU kopieren.
			w R1A_RBOOTMSE			;C64: mousePicData
			w R1S_RBOOTMSE			;REU: $fc40-$fc7f
			b $00				;Speicherbank
			b $ff				;Dummy-Byte
