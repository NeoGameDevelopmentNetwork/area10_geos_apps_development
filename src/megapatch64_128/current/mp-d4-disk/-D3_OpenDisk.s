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
			sta	:driveTypeBuf		;zwischenspeichern.
			and	#%10111111		;Shadow-Bit löschen und
			sta	driveType -8,y 		;zurückschreiben.
			sta	curType

			jsr	xNewDisk		;Neue Diskette initialisieren.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			bit	:driveTypeBuf		;Shadow1541 ?
			bvc	:skip_cache		;Nein, weiter...

			jsr	VerifySekInRAM		;BAM in ShadowRAM gespeichert ?
			beq	:skip_cache		; => Ja, weiter...

			jsr	InitShadowRAM		;ShadowRAM löschen.
			jsr	SetBAM_TrSe		;Zeiger auf BAM-Sektor setzen.
			jsr	SaveSekInRAM		;BAM in ShadowRAM speichern.

::skip_cache		jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

;			ldx	#NO_ERROR

;--- Laufwerksdaten zurücksetzen.
::err			lda	:driveTypeBuf
			ldy	curDrive
			sta	driveType -8,y		;Laufwerkstyp zurücksetzen.
			sta	curType

			txa				;Z-Flag setzen.
			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!

::driveTypeBuf		b $00
endif

;******************************************************************************
::tmp1 = C_71!C_81!RD_41!RD_71!RD_81
if :tmp1 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

;			ldx	#NO_ERROR
			txa				;Z-Flag setzen.
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp2 = PC_DOS
if :tmp2 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xChkDkGEOS 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

;			ldx	#NO_ERROR
			txa				;Z-Flag setzen.
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp3 = FD_41!HD_41!HD_41_PP
if :tmp3 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

;--- Hinweis:
;Direkt nach dem Boot-Vorgang ist hier
;drivePartData=0, es wird dann auch
;nicht die aktive Partition über die
;Routine "xLogNewPart" ermittelt.
			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition bekannt?
			bne	:3			; => Partition einlesen.

;--- Gültige Partition suchen.
::2			jsr	xLogNewPart		;Gültige Partition suchen.
			txa				;Partition gefunden ?
			bne	:dskerr			; => Nein, Abbruch...

;--- Aktive Partition testen.
::3			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

			lda	curDirHead +2		;Partitionsformat testen.
			cmp	#$41
			bne	:2
			lda	curDirHead +3
			bne	:2

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.

			ldx	#NO_ERROR
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp4 = FD_71!HD_71!HD_71_PP
if :tmp4 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

;--- Hinweis:
;Direkt nach dem Boot-Vorgang ist hier
;drivePartData=0, es wird dann auch
;nicht die aktive Partition über die
;Routine "xLogNewPart" ermittelt.
			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition bekannt?
			bne	:3			; => Partition einlesen.

;--- Gültige Partition suchen.
::2			jsr	xLogNewPart		;Gültige Partition suchen.
			txa				;Partition gefunden ?
			bne	:dskerr			; => Nein, Abbruch...

;--- Aktive Partition testen.
::3			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

			lda	curDirHead +2		;Partitionsformat testen.
			cmp	#$41
			bne	:2
			lda	curDirHead +3
			cmp	#$80
			bne	:2

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.

			ldx	#NO_ERROR
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp5 = FD_81!HD_81!HD_81_PP
if :tmp5 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

;--- Hinweis:
;Direkt nach dem Boot-Vorgang ist hier
;drivePartData=0, es wird dann auch
;nicht die aktive Partition über die
;Routine "xLogNewPart" ermittelt.
			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition bekannt?
			bne	:3			; => Partition einlesen.

;--- Gültige Partition suchen.
::2			jsr	xLogNewPart		;Gültige Partition suchen.
			txa				;Partition gefunden ?
			bne	:dskerr			; => Nein, Abbruch...

;--- Aktive Partition testen.
::3			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

			lda	dir3Head +2		;Partitionsformat testen.
			cmp	#$44
			bne	:2
			lda	dir3Head +3
			cmp	#$bb
			bne	:2

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.

			ldx	#NO_ERROR
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp6 = FD_NM!HD_NM!HD_NM_PP
if :tmp6 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

;--- Hinweis:
;Direkt nach dem Boot-Vorgang ist hier
;drivePartData=0, es wird dann auch
;nicht die aktive Partition über die
;Routine "xLogNewPart" ermittelt.
			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition bekannt?
			bne	:3			; => Partition einlesen.

;--- Gültige Partition suchen.
::2			jsr	xLogNewPart		;Gültige Partition suchen.
			txa				;Partition gefunden ?
			bne	:dskerr			; => Nein, Abbruch...

;--- Aktive Partition testen.
::3			jsr	xEnterTurbo		;LogNewPart führt ":ExitTurbo" aus.
			jsr	xGetDiskSize		;Partitionsgröße einlesen.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

			jsr	xGetDirHead		; => Neue Partition aktivieren.
			txa				;Diskettenfehler ?
			bne	:2			; => Ja, Abbruch...

			lda	curDirHead +2		;Partitionsformat testen.
			cmp	#$48
			bne	:2
			lda	curDirHead +3
			bne	:2

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

			ldx	curDrive
			ldy	drivePartData-8,x	;Aktive Partition einlesen.

			ldx	#NO_ERROR
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif

;******************************************************************************
::tmp7 = RL_41!RL_71
if :tmp7 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk

;--- Hinweis:
;":FindRAMLink" in MP3.3r7 entfernt.
;Unter MP128 kann damit das System
;nicht mehr auf der RAMLink installiert
;werden -> Absturz.
			jsr	FindRAMLink		;RAMLink-Adresse suchen.
			txa				;RAMLink gefunden?
			bne	:dskerr

;--- Hinweis:
;Im RAMLink-Treiber entspricht die
;Routine :xNewDisk = :xEnterTurbo.
;:FindRAMLink führt ExitTurbo aus, es
;muss daher im Anschluss :EnterTurbo
;ausgeführt werden.
			jsr	xNewDisk		;Diskette/Partition testen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

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
:xOpenDisk

;--- Hinweis:
;":FindRAMLink" in MP3.3r7 entfernt.
;Unter MP128 kann damit das System
;nicht mehr auf der RAMLink installiert
;werden -> Absturz.
			jsr	FindRAMLink		;RAMLink-Adresse suchen.
			txa				;RAMLink gefunden?
			bne	:dskerr

;--- Hinweis:
;Im RAMLink-Treiber entspricht die
;Routine :xNewDisk = :xEnterTurbo.
;:FindRAMLink führt ExitTurbo aus, es
;muss daher im Anschluss :EnterTurbo
;ausgeführt werden.
			jsr	xNewDisk		;Diskette/Partition testen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

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
:xOpenDisk

;--- Hinweis:
;":FindRAMLink" in MP3.3r7 entfernt.
;Unter MP128 kann damit das System
;nicht mehr auf der RAMLink installiert
;werden -> Absturz.
			jsr	FindRAMLink		;RAMLink-Adresse suchen.
			txa				;RAMLink gefunden?
			bne	:dskerr

;--- Hinweis:
;Im RAMLink-Treiber entspricht die
;Routine :xNewDisk = :xEnterTurbo.
;:FindRAMLink führt ExitTurbo aus, es
;muss daher im Anschluss :EnterTurbo
;ausgeführt werden.
			jsr	xNewDisk		;Diskette/Partition testen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDiskSize		;Diskettengröße ermitteln.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDirHead		;Aktuelle BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

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
::tmp10a = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp10b = IEC_NM!S2I_NM
::tmp10 = :tmp10a!:tmp10b
if :tmp10 = TRUE
;******************************************************************************
;*** Diskette öffnen.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg,r1,r4,r5
:xOpenDisk		jsr	xNewDisk		;Neue Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDiskSize		;Diskettengröße ermitteln.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	xGetDirHead		;BAM einlesen.
			txa				;Diskettenfehler ?
			bne	:dskerr			; => Ja, Abbruch...

			jsr	ChkDkGEOS_r5 		;Auf GEOS-Diskette testen.

			lda	#$00			; => Kein Fehler.
::dskerr		pha				;Fehlerstatus zwischenspeichern.

;--- Disketten-Informationen einlesen.
			ldx	#r5L
			jsr	GetPtrCurDkNm		;Zeiger auf Diskname setzen.

			lda	#$00			;Diskname für den Fall eines
			tay				;Fehlers löschen.
			sta	(r5L),y

			pla				;Fehlerstatus zurücksetzen.
			tax				;Disk-/Laufwerksfehler?
			bne	:err			; => Ja, Abbruch...

			ldy	#18 -1			;Diskname für GEOS-System kopieren.
::name			lda	curDirHead +$90,y
			sta	(r5L),y
			dey
			bpl	:name

;			ldx	#NO_ERROR		;Flag: "Kein Fehler"...
			txa				;Z-Flag setzen.
::err			rts				;Kein Befehl mehr nach LDX #xx. Es
							;gibt Programme die ohne TXA nur
							;mittels BEQ xz auf Fehler testen!
endif
