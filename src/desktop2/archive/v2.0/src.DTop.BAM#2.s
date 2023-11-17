; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:flagUpdDiskType	b $00				;1 = Validate, 36 = DiskCopy.

;*** Neue BAM erstellen.
;Dabei wird ein BAM für eine "volle"
;Diskette erzeugt und anschließend alle
;verfügbaren Datenblöcke in der BAM
;als "frei" markiert.

;-- Aufruf aus DiskCopy.
;Nur wenn Source=1541 und Target=1571.
;Dabei werden nur die Tracks 36-70 in
;der BAM als frei markiert und die Disk
;als Doppelseitig gekennzeichnet.
:createNewBAM		lda	#36			;Disk-Typ nur bei
			bne	initNewBAM		;mehr als 36 Tracks.

;--- Aufruf aus Validate:
;Nur BAM initialisieren.
.clearCurBAM		ldy	#$04
			lda	#$00
::clr			sta	curDirHead,y
			iny
			cpy	#$90
			bne	:clr

			lda	#$01			;Disk-Typ übernehmen.
:initNewBAM		sta	flagUpdDiskType

			ldy	#$dd			;BAM 1541 löschen.
			lda	#$00
::1			sta	curDirHead,y
			iny
			bne	:1

			ldy	dvTypSource
			cpy	#Drv1571
			bcc	:cont			; => 1541, weiter...
			bne	:is1581			; => 1581, weiter...

::is1571		ldy	#$00
::2			sta	dir2Head,y		;Nur dir2Head
			iny				;initialisieren.
			bne	:2
			beq	:cont

::is1581		ldy	#$10			;dir2Head/dir3Head
::3			sta	dir2Head,y		;initialisieren.
			sta	dir3Head,y
			iny
			bne	:3

::cont			lda	#$00
			jsr	initFreeBlkData

::next			lda	drvCurBlkSe
			sta	r6H
			lda	drvCurBlkTr
			sta	r6L
			cmp	drvMaxTracks
			beq	:4
			bcs	:exit

::4			jsr	freeBlockInBAM
			jsr	getFreeNextBlock
			clv
			bvc	:next

::exit			rts

;*** Einzelnen Block in BAM freigeben.
;Bei 1541 wird dabei auch die Anzahl
;der freien Blocks auf dem aktuellen
;Track gezählt.
:freeBlockInBAM		lda	dvTypSource
			cmp	#Drv1571		;1571?
			bcc	:is1541			; => 1541, weiter...
			bne	:freeblk		; => 1581, weiter...

;--- 1571:
;Nur ab Track 36 den Disk-Typ (1S/2S)
;überprüfen und ggf. festlegen.
;Nur bei DiskCopy! Bei Validate ist
;der Vergleichswert immer FALSE und die
;Routine wird beendet.
;Unterhalb von Track 36 müssen auch
;keine Blocks freigegeben werden, da
;die BAM hier von der Quell-Diskette
;übernommen wurde.
			lda	r6L			;Validate?
			cmp	flagUpdDiskType
			bcc	:exit			; => Nein, Ende...

;--- 1571:
;Auf Track 53 müssen keine Blocks
;freigegeben werden.
			cmp	#$35			;Track 53 / Nur 1571.
			bne	:freeblk

;--- Diskmodus setzen.
			lda	#DBLSIDED_DISK
			sta	curDirHead +3
::exit			rts

;--- 1571/1581: Nur Block freigeben.
::freeblk		jmp	FreeBlock

;--- 1541: Block freigeben und freie Blocks zählen.
::is1541		jsr	FindBAMBit
			lda	r8H
			eor	curDirHead,x
			sta	curDirHead,x
			ldx	r7H
			inc	curDirHead,x
			rts

;*** Track für Wechsel Sektoranzahl prüfen.
:getPoiMaxSekOnTr	ldx	#0
::1			cmp	tabTrSekChange,x
			bcc	:done
			inx
			bne	:1
::done			rts

;*** Max. Track für Sektor-Anzahl aus ":tabMaxSekOnTr".
:tabTrSekChange		b $12,$19,$1f,$24
