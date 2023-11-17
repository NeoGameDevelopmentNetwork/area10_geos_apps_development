; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neues Gerät aktivieren.
:xSetDevice		nop				;Füllbefehl wichtig, da einige
							;Programme daran die Version
							;von GEOS erkennen!

			cmp	curDevice		;Aktuelles Laufwerk ?
			beq	:102			;Ja, weiter...
			pha				;Neue Adresse speichern.
			lda	curDevice		;Aktuelles Laufwerk lesen.
			cmp	#$08			;Diskettenlaufwerk ?
			bcc	:101			;Nein, weiter...
			cmp	#$0c
			bcs	:101			;Nein, weiter...
			jsr	ExitTurbo		;Turbo-DOS abschalten.

::101			pla				;Neues Laufwerk festlegen.
			sta	curDevice

::102			cmp	#$08			;Diskettenlaufwerk ?
			bcc	:103			;Nein, Ende...
			cmp	#$0c
			bcs	:103			;Nein, Ende...

			tay
			lda	driveType   -8,y	;GEOS-Variablen aktualisieren.
			sta	curType
			cpy	curDrive		;War Laufwerk bereits aktiv ?
			beq	:103			;Ja, weiter...
			sty	curDrive

;--- Ergänzung: 24.01.21/M.Kanet
;DESKTOP2 wechselt bei zwei im System
;installierten Laufwerken auch auf das
;Laufwerk #10, auch wenn das Laufwerk
;nicht im System installiert ist.
;Wenn zuvor kein Treiber für dieses
;Laufwerk verwendet wurde, wird der
;Bereich für den Laufwerkstreiber im
;RAM mit $00-Bytes gefüllt wenn der
;Treiber aus der REU für das Laufwerk
;eingelesen werden soll.
			cmp	#$00			;Laufwerk installiert?
			beq	:103			; => Nein, weiter...

;<*>			bit	sysRAMFlg		;REU verfügbar ?
;<*>			bvc	:103			;Nein, weiter...
			jsr	InitForDskDvJob

;			jsr	SetVecCurDkDv		;RAM-Register speichern und

;			ldy	curDrive		;yReg unverändert!!!
;			lda	DskDrvBaseL -8,y	;Zeiger auf Laufwerkstreiber
;			sta	r1L			;in REU in ZeroPage kopieren.
;			lda	DskDrvBaseH -8,y
;			sta	r1H
							;REU-Register einlesen.
			jsr	FetchRAM		;Treiber aus REU nach RAM.
;			jsr	SetVecCurDkDv		;RAM-Register zurücksetzen.
			jsr	DoneWithDskDvJob

::103			lda	Flag_ScrSaver		;Status für Bilschirmschoner.
			bmi	:104
			lda	#%01000000		;Bildschirmschoner neu starten.
			sta	Flag_ScrSaver

::104			ldx	#$00			;OK!
			rts

if 0=1
;*** Austausch der REU-Register mit dem
;    Speicherbereich ":r0L - r3L".
.SetVecCurDkDv		ldx	#$06
::101			lda	r0L        ,x
			pha
			lda	CopyDrvData,x
			sta	r0L        ,x
			pla
			sta	CopyDrvData,x
			dex
			bpl	:101
			rts

;*** Transferdaten für ":SetDevice".
:CopyDrvData		w $9000				;RAM-Adresse Laufwerkstreiber.
			w $0000				;REU-Adresse Laufwerkstreiber.
			w $0d80				;Länge Laufwerkstreiber.
			b $00				;BANK in REU.

;*** Ladeadressen der Laufwerkstreiber.
.DskDrvBaseL		b < $8300
			b < $9080
			b < $9e00
			b < $ab80
.DskDrvBaseH		b > $8300
			b > $9080
			b > $9e00
			b > $ab80
endif
