; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41
if :tmp0 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldy	curDrive
			lda	driveType -8,y		;Laufwerkstyp einlesen und
			sta	driveTypeCopy		;zwischenspeichern.
			and	#%10111111		;Shadow-Bit löschen und
			sta	driveType -8,y 		;zurückschreiben.
			sta	curType

			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00
			tay
			sta	(r5L),y

			jsr	xNewDisk		;Neue Diskette initialisieren.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			bit	driveTypeCopy		;Shadow1541 ?
			bvc	:51			;Nein, weiter...

			jsr	VerifySekInRAM		;BAM in ShadowRAM gespeichert ?
			beq	:51			;Ja, weiter...

			jsr	InitShadowRAM		;ShadowRAM löschen.
			jsr	SetBAM_TrSe		;Zeiger auf BAM-Sektor setzen.
			jsr	SaveSekInRAM		;BAM in ShadowRAM speichern.

;--- Disketten-Informationen einlesen.
::51			ldy	#18 -1
::52			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:52

			jsr	xChkDkGEOS 		;auf GEOS-Diskette testen.

			ldx	#NO_ERROR
::53			lda	driveTypeCopy
			ldy	curDrive
			sta	driveType -8,y		;Laufwerkstyp zurücksetzen.
			sta	curType
			rts

:driveTypeCopy		b $00
endif

;******************************************************************************
::tmp1 = C_71!RD_41!RD_71!PC_DOS
if :tmp1 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00
			tay
			sta	(r5L),y

			jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

;--- Disketten-Informationen einlesen.
			ldy	#18 -1
::51			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:51

			jsr	xChkDkGEOS 		;auf GEOS-Diskette testen.

			ldx	#NO_ERROR
::52			rts
endif

;******************************************************************************
::tmp2 = C_81!RD_81
if :tmp2 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00
			tay
			sta	(r5L),y

			jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:53			;Ja, Abbruch...

;--- Disketten-Informationen einlesen.
			ldy	#18 -1
::51			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:51

			jsr	xChkDkGEOS 		;auf GEOS-Diskette testen.

			ldx	#NO_ERROR
::53			rts
endif

;******************************************************************************
::tmp3 = FD_41!HD_41!HD_41_PP
if :tmp3 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00			;Vorhandenen Diskettennamen
			tay				;löschen, falls keine Diskette im
			sta	(r5L),y			;Lauafwerk.

			jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

::1			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

;--- Hinweis:
;Direkt nach dem Boot-Vorgang ist hier
;drivePartData=0, es wird dann auch
;nicht die aktive Partition über die
;Routine "xLogNewPart" ermittelt.
			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition bekannt?
			beq	:2			; => Partition einlesen.

			lda	curDirHead +2		;Partitionsformat testen.
			cmp	#$41
			bne	:2
			lda	curDirHead +3
			beq	:3

;--- Gültige Partition suchen.
::2			jsr	xLogNewPart		;Gültige Partition suchen.
			txa				;Partition gefunden ?
			bne	:5			; => Nein, Abbruch...
			jsr	xGetDirHead		; => Neue Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

;--- Disketten-Informationen einlesen.
::3			ldy	#18 -1			;Diskettenname kopieren,.
::4			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:4

			jsr	xChkDkGEOS 		;auf GEOS-Diskette testen.

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.
			ldx	#NO_ERROR
::5			rts
endif

;******************************************************************************
::tmp4 = FD_71!HD_71!HD_71_PP
if :tmp4 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00			;Vorhandenen Diskettennamen
			tay				;löschen, falls keine Diskette im
			sta	(r5L),y			;Lauafwerk.

			jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

::1			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

;--- Hinweis:
;Direkt nach dem Boot-Vorgang ist hier
;drivePartData=0, es wird dann auch
;nicht die aktive Partition über die
;Routine "xLogNewPart" ermittelt.
			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition bekannt?
			beq	:2			; => Partition einlesen.

			lda	curDirHead +2		;Partitionsformat testen.
			cmp	#$41
			bne	:2
			lda	curDirHead +3
			cmp	#$80
			beq	:3

;--- Gültige Partition suchen.
::2			jsr	xLogNewPart		;Gültige Partition suchen.
			txa				;Partition gefunden ?
			bne	:5			; => Nein, Abbruch...
			jsr	xGetDirHead		; => Neue Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

;--- Disketten-Informationen einlesen.
::3			ldy	#18 -1			;Diskettenname kopieren,.
::4			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:4

			jsr	xChkDkGEOS 		;auf GEOS-Diskette testen.

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.
			ldx	#NO_ERROR
::5			rts
endif

;******************************************************************************
::tmp5 = FD_81!HD_81!HD_81_PP
if :tmp5 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00			;Vorhandenen Diskettennamen
			tay				;löschen, falls keine Diskette im
			sta	(r5L),y			;Lauafwerk.

			jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:6			; => Ja, Abbruch...

::1			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

;--- Hinweis:
;Direkt nach dem Boot-Vorgang ist hier
;drivePartData=0, es wird dann auch
;nicht die aktive Partition über die
;Routine "xLogNewPart" ermittelt.
			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition bekannt?
			beq	:2			; => Partition einlesen.

			lda	dir3Head +2		;Partitionsformat testen.
			cmp	#$44
			bne	:2
			lda	dir3Head +3
			cmp	#$bb
			beq	:3

;--- Gültige Partition suchen.
::2			jsr	xLogNewPart		;Gültige Partition suchen.
			txa				;Partition gefunden ?
			bne	:6			; => Nein, Abbruch...
			jsr	xGetDirHead		; => Neue Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:6			; => Ja, Abbruch...

;--- Disketten-Informationen einlesen.
::3			ldy	#18 -1
::4			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:4

			jsr	xChkDkGEOS 		;auf GEOS-Diskette testen.

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.
			ldx	#NO_ERROR
::6			rts
endif

;******************************************************************************
::tmp6 = FD_NM!HD_NM!HD_NM_PP
if :tmp6 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00			;Vorhandenen Diskettennamen
			tay				;löschen, falls keine Diskette im
			sta	(r5L),y			;Lauafwerk.

			jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

::1			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

;--- Hinweis:
;Direkt nach dem Boot-Vorgang ist hier
;drivePartData=0, es wird dann auch
;nicht die aktive Partition über die
;Routine "xLogNewPart" ermittelt.
			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition bekannt?
			beq	:2			; => Partition einlesen.

			lda	curDirHead +2		;Partitionsformat testen.
			cmp	#$48
			bne	:2
			lda	curDirHead +3
			beq	:3

;--- Gültige Partition suchen.
::2			jsr	xLogNewPart		;Gültige Partition suchen.
			txa				;Partition gefunden ?
			bne	:5			; => Nein, Abbruch...
			jsr	xGetDirHead		; => Neue Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:5			; => Ja, Abbruch...

;--- Disketten-Informationen einlesen.
::3			ldy	#18 -1			;Diskettenname kopieren,.
::4			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:4

			jsr	xChkDkGEOS 		;Auf GEOS-Diskette testen.

			jsr	xGetDiskSize

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.
			ldx	#NO_ERROR
::5			rts
endif

;******************************************************************************
::tmp7 = RL_41!RL_71
if :tmp7 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00
			tay
			sta	(r5L),y

;--- Hinweis:
;:FindRAMLink wurde in 3.3r7 entfernt.
;Unter MP128 kann damit das System
;nicht mehr auf der RAMLink installiert
;werden -> Absturz.
			jsr	FindRAMLink		;RAMLink-Adresse suchen.
			txa				;RAMLink gefunden?
			bne	:err

;--- Hinweis:
;Im RAMLink-Treiber entspricht die
;Routine :xNewDisk = :xEnterTurbo.
;:FindRAMLink führt ExitTurbo aus, es
;muss daher im Anschluss :EnterTurbo
;ausgeführt werden.
			jsr	xNewDisk		;Diskette/Partition testen.
			txa				;Diskettenfehler ?
			bne	:err			;Ja, Abbruch...

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:err			;Ja, Abbruch...

;--- Disketten-Informationen einlesen.
			ldy	#18 -1
::51			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:51

			jsr	xChkDkGEOS 		;Auf GEOS-Diskette testen.

			MoveW	RL_PartADDR,r3		;Startadr. Partition nach ":r3".

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.
			lda	RL_DEV_ADDR		;Geräteadresse RL in AKKU.
			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp8 = RL_81
if :tmp8 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00
			tay
			sta	(r5L),y

;--- Hinweis:
;:FindRAMLink wurde in 3.3r7 entfernt.
;Unter MP128 kann damit das System
;nicht mehr auf der RAMLink installiert
;werden -> Absturz.
			jsr	FindRAMLink		;RAMLink-Adresse suchen.
			txa				;RAMLink gefunden?
			bne	:err

;--- Hinweis:
;Im RAMLink-Treiber entspricht die
;Routine :xNewDisk = :xEnterTurbo.
;:FindRAMLink führt ExitTurbo aus, es
;muss daher im Anschluss :EnterTurbo
;ausgeführt werden.
			jsr	xNewDisk		;Diskette/Partition testen.
			txa				;Diskettenfehler ?
			bne	:err			;Ja, Abbruch...

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:err			;Ja, Abbruch...

;--- Disketten-Informationen einlesen.
			ldy	#18 -1
::51			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:51

			jsr	xChkDkGEOS 		;Auf GEOS-Diskette testen.

			MoveW	RL_PartADDR,r3		;Startadr. Partition nach ":r3".

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.
			lda	RL_DEV_ADDR		;Geräteadresse RL in AKKU.
			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp9 = RL_NM
if :tmp9 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00
			tay
			sta	(r5L),y

;--- Hinweis:
;:FindRAMLink wurde in 3.3r7 entfernt.
;Unter MP128 kann damit das System
;nicht mehr auf der RAMLink installiert
;werden -> Absturz.
			jsr	FindRAMLink		;RAMLink-Adresse suchen.
			txa				;RAMLink gefunden?
			bne	:err

;--- Hinweis:
;Im RAMLink-Treiber entspricht die
;Routine :xNewDisk = :xEnterTurbo.
;:FindRAMLink führt ExitTurbo aus, es
;muss daher im Anschluss :EnterTurbo
;ausgeführt werden.
			jsr	xNewDisk		;Diskette/Partition testen.
			txa				;Diskettenfehler ?
			bne	:err			;Ja, Abbruch...

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:err			;Ja, Abbruch...

;--- Disketten-Informationen einlesen.
			ldy	#18 -1
::51			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:51

			jsr	xChkDkGEOS 		;Auf GEOS-Diskette testen.

			jsr	xGetDiskSize		;Diskettengröße ermitteln.

			MoveW	RL_PartADDR,r3		;Startadr. Partition nach ":r3".

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.
			lda	RL_DEV_ADDR		;Geräteadresse RL in AKKU.
			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp10 = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp10 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00
			tay
			sta	(r5L),y

			jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	xGetDiskSize		;Diskettengröße ermitteln.

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

;--- Disketten-Informationen einlesen.
			ldy	#18 -1
::51			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:51

			jsr	xChkDkGEOS 		;auf GEOS-Diskette testen.

			ldx	#NO_ERROR
::52			rts
endif

;******************************************************************************
::tmp11 = IEC_NM!S2I_NM
if :tmp11 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskettenname.

			lda	#$00
			tay
			sta	(r5L),y

			jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

			jsr	xGetDiskSize		;Diskettengröße ermitteln.
			txa				;Diskettenfehler ?
			bne	:52			;Ja, Abbruch...

;--- Disketten-Informationen einlesen.
			ldy	#18 -1
::51			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:51

			jsr	xChkDkGEOS 		;auf GEOS-Diskette testen.
;			ldx	#NO_ERROR		;XReg ist noch $00 = Kein Fehler.
::52			rts
endif
