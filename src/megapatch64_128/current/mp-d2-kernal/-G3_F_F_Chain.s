; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Sektorkette auf Disk freigeben.
:FreeSeqChain		lda	r1H
			ldx	r1L
			beq	:3

			ldy	#$00
			sty	r2L			;Blocks löschen.
			sty	r2H

::1			sta	r1H
			stx	r1L

			sta	r6H
			stx	r6L
			jsr	FreeBlock		;Sektor freigeben.
			txa				;Diskettenfehler ?
			bne	:3			;Ja, Abbruch...

			inc	r2L			;Anzahl gelöschte Blocks
			bne	:2			;um 1 erhöhen.
			inc	r2H

::2			jsr	GetBlock_dskBuf		;Sektor einlesen.
			txa				;Diskettenfehler ?
			bne	:3			;Ja, Abbruch...

			lda	diskBlkBuf +1		;Noch ein Sektor ?
			ldx	diskBlkBuf +0
			bne	:1			;Nächsten Sektor freigeben.

::3			rts

;--- Ergänzung: 01.07.18/M.Kanet
;Neue FollowChain-Routine.
;Bei der Original-Version wurde in :r3 keine gültige Sektortabelle
;erzeugt wenn der erste Sektor in :r1L/:r1H=$0/Bytes (letzter Sektor) ist.
;Ausserdem wird bei erfolgreichem anlegen der Tabelle in :r1L/:r1H
;nicht das letzte Spur/Sektor-Paar übergeben (:r1L=$0/Ende, :r1H=Bytes)
;
;Benötigter Speicher: 51Bytes
;
;*** Sektorkette verfolgen und
;    Track/Sektor-Tabelle anlegen.
;    Übergabe: r1L/r1H Spur/Sektor
;              r3      Zeiger auf Tabellenspeicher
:xFollowChain		lda	r3H
			pha

			ldy	#$00
			lda	r1H			;Erste Spur/Sektor-Adresse in
			ldx	r1L			;Sektortabelle kopieren.
::1			iny
			sta	(r3L),y			;Sektor-Adresse eintragen.
			dey
			txa
			sta	(r3L),y			;Spur-Adresse eintragen.
							;Spur = $00 ?
			beq	:4			;Ja, Ende...
			iny
			iny
			bne	:2			;Block-Ende erreicht?
			inc	r3H			;Zeiger auf nächsten Block.
::2			tya
			pha
			jsr	GetBlock_dskBuf		;Sektor einlesen.
			pla
			tay
			txa				;Diskettenfehler ?
			bne	:4			;Ja, Abbruch...

			lda	diskBlkBuf +1		;Zeiger auf nächsten Sektor.
			sta	r1H
			ldx	diskBlkBuf +0
			stx	r1L
			jmp	:1

::4			pla
			sta	r3H
			rts
