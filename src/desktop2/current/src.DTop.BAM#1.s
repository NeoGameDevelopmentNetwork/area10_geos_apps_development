; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Modus für initFreeBlkData.
:flagGetBlkInfo		b $00				;$ff = Block-Status ermitteln.

;*** Liste mit freien Blocks erstellen.
:initFreeBlkData	sta	flagGetBlkInfo

			ldy	dvTypSource
			lda	tabDrvTracks,y
			sta	drvMaxTracks

			lda	tabDrv1stDirTr,y
			sta	drv1stDirTr
			lda	tabDrv1stDirSe,y
			sta	drv1stDirSe

;--- Hinweis:
;Für NativeMode müsste die Suche ab
;Track1 / Sektor 64 beginnen.
			ldy	#$01			;Sucher nach einem
			sty	drvCurBlkTr		;freien Block ab
			dey				;Tr.1 / Se=0.
			sty	drvCurBlkSe

;*** Suche auf neuem Track starten.
:getFreeBlkNextTr	jsr	initTabBlkData

;*** Nöchsten freien Sektor auf Track finden.
:getFreeNextBlock	jsr	findFreeBlkOnTr
			bcc	:err
			inc	drvCurBlkTr
			lda	drvCurBlkTr
			cmp	drvMaxTracks
			bcc	getFreeBlkNextTr
			beq	getFreeBlkNextTr
::err			rts

;*** max. Anzahl Tracks.
:tabDrvTracks		b $23,$23,$46,$50

;*** Erster Verzeichnis-Track/Sektor.
:tabDrv1stDirTr		b $12,$12,$12,$28
:tabDrv1stDirSe		b $01,$01,$01,$03

;*** Liste mit möglichen Blocks erstellen.
;Die Tabelle umfasst nur 40 Blocks und
;ist damit für NativeMode untauglich.
:initTabBlkData		ldy	#40 -1			;Max. 40 Sek./Track
			lda	#$00			;für 1581 verfügbar.
::1			sta	tabBlkStatus,y
			dey
			bpl	:1

			lda	dvTypSource
			cmp	#Drv1581
			bne	:not1581

::is1581		lda	#40
			sta	drvCurTrMaxSek
			bne	:cont

::not1581		lda	drvCurBlkTr
			cmp	#36			;Track > 35?
			bcc	:2			; => Nein, weiter...
			sec
			sbc	#35			;Track nach 1-35.

;--- Nicht verfügbare Blocks auf Track markieren.
;Nur 1541/1571 und Tracks mit weniger
;als 21 Blocks. Die Bytes 22-40 werden
;werden nur für eine 1581 verwendet.
::2			jsr	getPoiMaxSekOnTr

			lda	tabMaxSekOnTr,x
			sta	drvCurTrMaxSek
			tay
::3			cpy	#$15			;Nicht verfügbare
			beq	:cont			;Blocks markieren.
			lda	#$ff
			sta	tabBlkStatus,y
			iny
			bne	:3

;--- Block-Status ermitteln?
::cont			lda	flagGetBlkInfo
			beq	:exit			; => Kein Status.

;--- Tabelle mit freien Blocks auf Track erstellen.
			lda	drvCurBlkTr
			sta	r6L
			lda	#$00
			sta	r6H
::4			jsr	FindBAMBit		;Block frei/belegt?
			beq	:5			;Belegt, weiter...

			ldy	r6H
			lda	#$ff
			sta	tabBlkStatus,y
::5			inc	r6H
			lda	r6H
			cmp	drvCurTrMaxSek
			bcc	:4
::exit			rts

;*** Anzahl Sektoren je Track 1541/1571.
:tabMaxSekOnTr		b $15,$13,$12,$11

;*** Sektor-Interleave für FileCopy.
;RAMDisk und 1571 = 7, sonst 8.
:diskInterleave		b $08

;*** Freien Block in Sektortabelle suchen.
;Rückgabe: C-Flag=1: Kein Block frei...
;          C-Flag=0: Block frei -> Y/drvCurBlkSe = Sektor.
:findFreeBlkOnTr	lda	diskInterleave
			clc
			adc	drvCurBlkSe
			cmp	drvCurTrMaxSek
			bcc	:1
			sec
			sbc	drvCurTrMaxSek

::1			tay
			lda	tabBlkStatus,y
			beq	:4			; => Block frei...

			ldx	drvCurTrMaxSek
::2			iny
			cpy	drvCurTrMaxSek
			bcc	:3			;1541, weiter...
			tya				;Sonderbehandlung für
			sec				;1571/Track > 35.
			sbc	drvCurTrMaxSek
			tay
::3			lda	tabBlkStatus,y
			beq	:4			; => Block frei...
			dex
			bpl	:2			; => Weitersuchen...

			sec
			rts

::4			sty	drvCurBlkSe
			lda	#$ff
			sta	tabBlkStatus,y
			clc
			rts
