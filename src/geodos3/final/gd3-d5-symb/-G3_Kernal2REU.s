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

			LoadW	r0 ,$8400		;Systemvariablen in REU kopieren.
			LoadW	r1 ,$7900		;C64: $8400-$88FF
			LoadW	r2 ,$0500		;REU: $7900-$7DFF
			LoadB	r3L,$00
			jsr	StashRAM

;			LoadW	r0 ,DISK_BASE		;Laufwerkstreiber in REU kopieren.
;			LoadW	r1 ,$8300		;C64: $9000-$9D7F
;			LoadW	r2 ,$0d80		;REU: $8300-$907F
;			LoadB	r3L,$00			;(Entfällt, alle Treiber sind
;			jsr	StashRAM		; bereits in der REU!)

			LoadW	r0 ,OS_LOW		;Kernal Teil #1 in REU kopieren.
			LoadW	r1 ,$b900		;C64: $9D80-$9FFF
			LoadW	r2 ,$0280		;REU: $B900-$BB7F
;			LoadB	r3L,$00
			jsr	StashRAM

			LoadW	r0 ,$bf40		;Kernal Teil #2 in REU kopieren.
			LoadW	r1 ,$bb80		;C64: $BF40-$CFFF
			LoadW	r2 ,$10c0		;REU: $BB80-$CC3F
;			LoadB	r3L,$00
			jsr	StashRAM

			LoadW	r0 ,OS_VARS		;Kernal Teil #3 in REU kopieren.
			LoadW	r1 ,$cc40		;C64: $D000-$FFFF
			LoadW	r2 ,$0100		;REU: $CC40-$FC3F
;			LoadB	r3L,$00

			LoadB	r4L,$30			;$30 x 256 Bytes kopieren.
			LoadW	r5 ,$d000		;Startadresse.

;--- Kernal sichern.
;Dazu die Daten aus dem Kernal in einen
;Zwischenspeicher kopieren, damit auch
;Daten unterhalb des I/O-Bereichs von
;StashRAM gesichert werden können.
::loop			php				;Kernaldaten in temporären
			sei				;Zwischenspeicher kopieren.
			ldy	#$00
::1			lda	(r5L),y
			sta	diskBlkBuf +$00,y
			iny
			bne	:1
			plp

			jsr	StashRAM		;Zwischenspeicher nach REU.

			inc	r5H
			inc	r1H
			dec	r4L			;Alle Kernaldaten kopiert ?
			bne	:loop			; => Nein, weiter...

			LoadW	r0 ,mousePicData	;Mauszeiger in REU kopieren.
			LoadW	r1 ,$fc40		;C64: mousePicData
			LoadW	r2 ,$003f		;REU: $fc40-$fc7f
;			LoadB	r3L,$00
			jmp	StashRAM
