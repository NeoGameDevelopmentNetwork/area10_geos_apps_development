; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerk und Diskette öffnen.
;    Übergabe: AKKU = Laufwerk
;    Rückgabe: XREG = $00/Fehler
.Sys_SetDrv_Open	jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler?
			bne	:err			; => Ja, Abbruch.

			jsr	QuickOpenDisk
;			txa
;			bne	:err

;			ldx	#NO_ERROR
::err			rts

;*** Einfaches "Diskette öffnen".
.QuickOpenDisk		jsr	GetDirHead		;BAM einlesen.
			txa				;Fehler ?
			beq	:getname		; => Nein, weiter...

			jmp	OpenDisk		;Vollständiges OpenDisk ausführen.

::getname		ldx	#r0L			;Zeiger auf Speicher für
			jsr	GetPtrCurDkNm		;Diskname aktuelles Laufwerk.

			ldy	#18 -1			;Diskname kopieren.
::1			lda	curDirHead +$90,y
			sta	(r0L),y
			dey
			bpl	:1

			ldx	#NO_ERROR		;Kein Fehler...
::err			rts

;*** Partition ermitteln.
;    Übergabe: curDrive = Laufwerk.
;    Rückgabe: $00 oder Partitions-Nr.
.Sys_GetDrv_Part	ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,x	;CMD-Laufwerk?
			and	#SET_MODE_PARTITION
			beq	:1			; => Nein, Ende...
			lda	drivePartData-8,x	;Aktive Partition einlesen.
::1			rts

;*** Verzeichnis ermitteln.
;    Übergabe: curDrive = Laufwerk.
;    Rückgabe: AKKU/XREG = Verzeichnis.
.Sys_GetDrv_SDir	ldx	curDrive		;Laufwerksadresse einlesen.
			lda	RealDrvMode -8,x	;NativeMode-Laufwerk?
			and	#SET_MODE_SUBDIR
			tax
			beq	:1			; => Nein, Ende...
			jsr	GetDirHead		;Verzeichnis-Header einlesen.
			txa				;Fehler?
			beq	:2			; => Nein, weiter...
			lda	#$00			;Kein Verzeichnis aktivieren.
			tax
			rts
::2			lda	curDirHead +32		;Aktives Verzeichnis einlesen.
			ldx	curDirHead +33
::1			rts

;*** Source-Laufwerk.
;    Übergabe: AKKU = Laufwerk 8-11
.Sys_SetDvSource	sta	sysSource		;Laufwerksadresse speichern und
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	Sys_GetDrv_Part		;Ggf. Partitionsdaten einlesen und
			sta	sysSource +1		;speichern (nicht-CMD = $00).
			jsr	Sys_GetDrv_SDir		;Ggf. SubDir einlesen und
			sta	sysSource +2		;speichern (nicht-Native = $00).
			stx	sysSource +3
			rts

;*** Target-Laufwerk.
;    Übergabe: AKKU = Laufwerk 8-11
.Sys_SetDvTarget	sta	sysTarget		;Laufwerksadresse speichern und
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	Sys_GetDrv_Part		;Ggf. Partitionsdaten einlesen und
			sta	sysTarget +1		;speichern (nicht-CMD = $00).
			jsr	Sys_GetDrv_SDir		;Ggf. SubDir einlesen und
			sta	sysTarget +2		;speichern (nicht-Native = $00).
			stx	sysTarget +3
			rts

;*** Aktuelles Laufwerk speichern.
;Hinweis:
;Einsprungsadresse wird aktuell
;nicht verwendet.
::SaveTempDrive		lda	curDrive		;Aktuelles Laufwerk speichern.

;*** Partition setzen.
;    Übergabe: AKKU = Laufwerk.
;    Rückgabe: XREG = $00/Fehler
.Sys_SvTempDrive	pha

			ldy	curDrive		;Aktuelles Laufwerk speichern.
			sty	TempDrive

			lda	RealDrvMode -8,y	;Laufwerksmodus speichern.
			sta	TempMode

			jsr	Sys_GetDrv_Part		;Partition einlesen und
			sta	TempPart		;zwischenspeichern.

			jsr	Sys_GetDrv_SDir		;Verzeichnis einlesen und
			sta	TempSDir +0		;zwischenspeichern.
			stx	TempSDir +1

			pla
			jsr	Sys_SetDrv_Open		;Laufwerk/Diskette öffnen.
;			txa				;Laufwerkfehler?
;			bne	:error			; => Ja, Abbruch...

;			ldx	#NO_ERROR
::error			rts

;*** Aktuelles Laufwerk speichern und
;    Startlaufwerk öffnen.
.TempBootDrive		jsr	FindBootDrive		;Boot-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden?
			bne	:error			; => Nein, Abbruch...

			jsr	Sys_SvTempDrive		;Aktuelles Laufwerk speichern.
			txa				;Laufwerkfehler?
			bne	:error			; => Ja, Abbruch...

			ldx	curDrive		;Zusätzlich ramBase sichern.
			lda	ramBase -8,x
			sta	BootRBase
			sta	LinkRBase

			jmp	OpenBootDrive		;Boot-Laufwerk aktivieren.

::error			rts

;*** Aktuelles Laufwerk speichern und
;    Laufwerk mit AppLink-Konfiguration
;    öffnen.
.TempLinkDrive		jsr	FindLinkDrive		;AppLink-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden?
			bne	:error			; => Nein, Abbruch...

			jsr	Sys_SvTempDrive		;Aktuelles Laufwerk speichern.
			txa				;Laufwerkfehler?
			bne	:error			; => Ja, Abbruch...

			jmp	OpenLinkDrive		;AppLink-Laufwerk öffnen.

::error			rts

;*** Zurück zum Quell-Laufwerk.
.BackTempDrive		lda	TempDrive
			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Laufwerkfehler?
			bne	:exit			; => Ja, Abbruch...

			bit	TempMode		;Laufwerks-Modus einlesen.
			bmi	:open_part		; => Partitioniertes Laufwerk.
			bvs	:open_sdir		; => NativeMode-Laufwerk.
			jmp	QuickOpenDisk		; => Standard-Laufwerk.

::open_part		lda	TempPart
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	TempMode		;NativeMode-Laufwerk?
			bvs	:open_sdir		; => Ja, weiter...
::exit			rts

::open_sdir		lda	TempSDir +0
			sta	r1L
			lda	TempSDir +1
			sta	r1H
			jmp	OpenSubDir		;Verzeichnis öffnen.

;*** Startlaufwerk öffnen.
.OpenBootDrive		jsr	FindBootDrive		;Boot-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden?
			bne	:exit			; => Nein, Abbruch...

			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Laufwerkfehler?
			bne	:exit			; => Ja, Abbruch...

			bit	BootMode		;Laufwerks-Modus einlesen.
			bmi	:open_part		; => Partitioniertes Laufwerk.
			bvs	:open_sdir		; => NativeMode-Laufwerk.
			jmp	QuickOpenDisk		; => Standard-Laufwerk.

::open_part		lda	BootPart
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	BootMode		;NativeMode-Laufwerk?
			bvs	:open_sdir		; => Ja, weiter...
::exit			rts

::open_sdir		lda	BootSDir +0
			sta	r1L
			lda	BootSDir +1
			sta	r1H
			jmp	OpenSubDir		;Verzeichnis öffnen.

;*** Startlaufwerk suchen.
:FindBootDrive		ldx	BootDrive		;Boot-Laufwerk einlesen.
			jsr	:test_drive		;Laufwerk = Boot-Laufwerk?
			beq	:found			; => Ja, Ende...

			ldx	#8			;Zeiger auf erstes Laufwerk und
::loop			cpx	BootDrive		;Laufwerk bereits getestet?
			beq	:skip			; => Ja, überspringen.
			jsr	:test_drive		;Boot-Laufwerkstyp suchern.
			beq	:found			; => Gefunden, Ende...
::skip			inx				;Nächstes Laufwerk.
			cpx	#11 +1			;Laufwerk 8-11 durchsucht?
			bcc	:loop			; => Nein, weiter...

			ldx	#DEV_NOT_FOUND		;Boot-Laufwerk nicht mehr gefunden.
			rts

::found			txa
			ldx	#NO_ERROR		;Boot-Laufwerk gefunden.
			rts

::test_drive		lda	RealDrvType -8,x	;RealDrvType vergleichen.
			cmp	BootType		;Stimmt Laufwerkstyp?
			bne	:failed			; => Nein, Fehler.

			lda	driveType -8,x		;RAM-Laufwerk?
			bpl	:ok			; => Nein, weiter....
			lda	ramBase -8,x		;RAM-Adresse vergleichen.
			cmp	BootRBase		;Stimmt RAM-Adresse?
			bne	:failed			; => Nein, Fehler.

::ok			lda	#$00
			rts

::failed		lda	#$ff
			rts

;*** Laufwerk mit AppLink-Konfiguration öffnen.
.OpenLinkDrive		jsr	FindLinkDrive		;AppLink-Laufwerk suchen.
			cpx	#NO_ERROR		;Laufwerk gefunden?
			bne	:exit			; => Nein, Abbruch...

			jsr	SetDevice		;Laufwerk öffnen.
			txa				;Laufwerkfehler?
			bne	:exit			; => Ja, Abbruch...

			bit	LinkMode		;Laufwerks-Modus einlesen.
			bmi	:open_part		; => Partitioniertes Laufwerk.
			bvs	:open_sdir		; => NativeMode-Laufwerk.
			jmp	QuickOpenDisk		; => Standard-Laufwerk.

::open_part		lda	LinkPart
			sta	r3H
			jsr	OpenPartition		;Partition öffnen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			bit	LinkMode		;NativeMode-Laufwerk?
			bvs	:open_sdir		; => Ja, weiter...
::exit			rts

::open_sdir		lda	LinkSDir +0
			sta	r1L
			lda	LinkSDir +1
			sta	r1H
			jmp	OpenSubDir		;Verzeichnis öffnen.

;*** AppLink-Laufwerk suchen.
:FindLinkDrive		ldx	LinkDrive		;AppLink-Laufwerk einlesen.
			jsr	:test_drive		;Laufwerk = AppLink-Laufwerk?
			beq	:found			; => Ja, Ende...

			ldx	#8			;Zeiger auf erstes Laufwerk und
::loop			cpx	BootDrive		;Laufwerk bereits getestet?
			beq	:skip			; => Ja, überspringen.
			jsr	:test_drive		;AppLink-Laufwerkstyp suchern.
			beq	:found			; => Gefunden, Ende...
::skip			inx				;Nächstes Laufwerk.
			cpx	#11 +1			;Laufwerk 8-11 durchsucht?
			bcc	:loop			; => Nein, weiter...

			ldx	#DEV_NOT_FOUND		;AppLink-Laufwerk nicht gefunden.
			rts

::found			txa
			ldx	#NO_ERROR		;AppLink-Laufwerk gefunden.
			rts

::test_drive		lda	RealDrvType -8,x	;RealDrvType vergleichen.
			cmp	LinkType		;Stimmt Laufwerkstyp?
			bne	:failed			; => Nein, Fehler.

			lda	driveType -8,x		;RAM-Laufwerk?
			bpl	:ok			; => Nein, weiter....
			lda	ramBase -8,x		;RAM-Adresse vergleichen.
			cmp	LinkRBase		;Stimmt RAM-Adresse?
			bne	:failed			; => Nein, Fehler.

::ok			lda	#$00
			rts

::failed		lda	#$ff
			rts
