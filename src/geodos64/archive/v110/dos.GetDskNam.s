; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L350: Datenträgername ermitteln.
:DOS_GetDskNam		jsr	GetMdrSek		;Anzahl Sektoren im Hautpverzeichnis.
			MoveW	MdrSektor,V350a0
			lda	#$00
			sta	VolNExist
			sta	DskNamSekNr+0
			sta	DskNamSekNr+1
			jsr	DefMdr			;Zeiger auf Hauptverzeichnis.

::1			ClrW	DskNamEntry
			LoadW	a8,Disk_Sek		;Directory-Sektor lesen.
			jsr	D_Read
			txa
			beq	:2
			jmp	DiskError

::2			ldx	#$10
::3			ldy	#$00
			lda	(a8L),y			;Auf Disketten-Namen prüfen.
			beq	:6
			ldy	#$0b
			lda	(a8L),y
			and	#%00001000
			bne	:7

::4			AddVBW	32,DskNamEntry		;Nicht gefunden.
			AddVBW	32,a8
			dex
			bne	:3			;Weitersuchen...

			jsr	Inc_Sek			;Zeiger auf nächsten Sektor
			IncWord	DskNamSekNr		;im Hauptverzeichnis.
			SubVW	1,V350a0
			CmpW0	V350a0
			beq	:5
			jmp	:1

::5			lda	#$ff			;Kein Platz im
			b	$2c			;Directory für Name.

::6			lda	#$7f			;Kein Disk-Name.
			sta	VolNExist
			LoadW	r0,V350a1
			jmp	:8

::7			MoveW	a8,r0			;Name gefunden.
::8			ldy	#$00
::9			lda	(r0L),y
			beq	:10
			TDosNmByt
::10			sta	dosDiskName,y
			iny
			cpy	#$0b
			bne	:9

			rts

:V350a0			w	$0000
:V350a1			s	12
