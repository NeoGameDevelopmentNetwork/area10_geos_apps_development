; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zeiger auf Laufwerk-Icons für DoIcons-Menü.
:vecDrvIconsL		b > tabIconDriveA
			b > tabIconDriveB
			b > tabIconDriveC
:vecDrvIconsH		b < tabIconDriveA
			b < tabIconDriveB
			b < tabIconDriveC

;*** Diskname und Icon aktualisieren.
:setNewDriveData	ldx	#r1L
			jsr	setVecDkNmBuf
			ldy	#r1L
			jsr	r2_curDirHeadNm
			lda	#18
			jsr	CopyFString

			jsr	move_r1_r0
			jsr	getIconNumCurDrv

			ldx	#%01000000
			stx	r1L

;*** Laufwerk-Icons für DoIcons und DeskTop übernehmen.
;Übergabe: A   = Icon-Nr. 20/21/22 für Laufwerk A/B/C
;          r0  = Zeiger auf Diskname.
;          r1L = %01000000 = Disk geöffnet.
;                %00000000 = Disk geschlossen.
;                %10000000 = Disk-Icon invertieren.
:updDriveIcons		tay

			lda	r1L
			sta	flagTempData

			lda	r0H
			pha
			lda	r0L
			pha
			tya
			jsr	clrDeskPadIcon

			tay
			pla
			sta	r0L
			pla
			sta	r0H
			tya
			jsr	saveVecIconNm_r0

			pha
			sec
			sbc	#ICON_DRVA		;Zeiger Icon 14/15
			tay				;für Laufwerk A/B.
			lda	vecDrvIconsL,y
			sta	r0H
			lda	vecDrvIconsH,y
			sta	r0L
			pla
			pha
			jsr	add1Icon2Tab
			pla
			tay

			lda	flagTempData
			and	#%01000000		;Disk geöffnet?
			bne	:1			; => Ja, weiter...

;--- "Keine Disk"-Icon anzeigen.
			tya
			pha

			ldx	#r5L
			jsr	setRegXIconData

			lda	#< icon_NoDisk
			ldy	#$00
			sta	(r5L),y
			iny
			lda	#> icon_NoDisk
			sta	(r5L),y
			pla
			tay

;--- Einzelnes Laufwerk-Icon anzeigen.
::1			lda	#> AREA_DRIVES_X0
			sta	leftMargin +1
			lda	#< AREA_DRIVES_X0
			sta	leftMargin +0
			tya
			pha
			jsr	prntIconTab1

			lda	flagTempData
			and	#%01000000		;Diskette geöffnet?
			beq	:4			; => Nein, weiter...

			pla
			pha

			cmp	#ICON_DRVA		;Laufwerk A?
			bne	:2			; => Nein, weiter...

;--- Laufwerk A: anzeigen.
			lda	#  $18 +16
			sta	r1H
			lda	#> $23 *8 +2
			sta	r11H
			lda	#< $23 *8 +2
			sta	r11L
			lda	#"A"
			clv
			bvc	:3

::2			cmp	#ICON_DRVB		;Laufwerk B?
			bne	:4			; => Nein, weiter...

;--- Laufwerk B: anzeigen.
			lda	#  $3c +16
			sta	r1H
			lda	#> $23 *8 +2
			sta	r11H
			lda	#< $23 *8 +2
			sta	r11L
			lda	#"B"
::3			jsr	PutChar

::4			pla

;--- Laufwerk-Icon invertieren?
;flagTempData: Bit%7=1: Invertieren.
			ldx	flagTempData
			bpl	:5

			jsr	invertIcon

::5			lda	#$00
			sta	leftMargin +0
			sta	leftMargin +1
			rts

;*** Daten für Laufwerk-Icons.
:tabIconDriveA		w icon_DiskDrive
			b $23,$18,$03,$15
			w func_OpenDrvAB

:tabIconDriveB		w icon_DiskDrive
			b $23,$3c,$03,$15
			w func_OpenDrvAB

:tabIconDriveC		w icon_DiskDrive
			b $23,$68,$03,$15
			w func_SwapDriveC
