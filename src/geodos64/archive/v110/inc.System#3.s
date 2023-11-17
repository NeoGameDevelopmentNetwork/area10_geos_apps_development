; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** L060: Diskette einlegen.
;  Akku = Laufwerksadresse
;  xReg = $00, Testen, wenn OK, dann zurück, sonst Hinweis.
;         $7F, Nur Hinweis, nicht testen.
;         $FF, Hinweis, danach testen.
.InsertDisk		stx	V060a0
			jsr	NewDrive
			lda	Action_Drv
			add	$39			;Laufwerk merken.
			sta	V060b2 + 9
			ldx	V060a0			;Zuerst testen ?
			beq	:3			;Ja, weiter.
::1			LoadW	r0,V060b0		;Hinweis ausgeben.
			RecDlgBoxCSet_Grau
			lda	sysDBData
			ldx	V060a0			;Testen ?
			cpx	#$7f			;Nein, Ende.
			beq	:2
			cmp	#$02			;"Abbruch" gewählt ?
			bne	:3			;Nein, weiter.
::2			rts				;Ende.

::3			jsr	ChkDskInDrv		;Diskette im Laufw.?
			cpx	#$ff			;Nein, -> Hinweis.
			beq	:1
			lda	#$01			;Ja, Ende.
			rts

;*** Prüfen ob Disk eingelegt ist.
:ChkDskInDrv		ldy	curDrvType
			lda	V060d0,y
			pha
			lda	V060d1,y
			pha
			rts

;*** Diskette im Laufwerk.
:Disk_OK		ldx	#$00
			rts

;*** Diskette im Laufwerk (1541/71) ?
:Dsk1541
:Dsk1571		InitSPort			;GEOS-Turbo aus und I/O einschalten.
			CxSend	V060c0
			CxSend	V060c1
			jsr	DoneWithIO
			Do_Job	V060c2
			cmp	#$02
			bcs	NoDisk
			bcc	Disk_OK			;Disk im Laufwerk.

;*** Diskette im Laufwerk (1581) ?
:Dsk1581		C_Send	V060c0			;"BUMP"...
			lda	#$92			;IS DISK IN DRIVE ?"...
			jsr	SendJob
			cmp	#$02
			bcc	Disk_OK
:NoDisk			ldx	#$ff			;Keine Disk.
			rts

;*** Daten für "InsertDisk"
:V060a0			b $00
:V060b0			b $01
			b 56,127
			w 64,255
			b OK        ,  2, 48
			b CANCEL    , 16, 48
			b DBTXTSTR  , 56, 24
			w V060b1
			b DBTXTSTR  , 56, 34
			w V060b2
			b DB_USR_ROUT
			w ISet_Achtung
			b NULL

:V060b1			b PLAINTEXT,BOLDON
			b "Bitte Diskette in",NULL
:V060b2			b "Laufwerk x: einlegen!",PLAINTEXT,NULL

:V060c0			w $0003
			b "I0:"
:V060c1			w $0008
			b "M-W",$0a,$00,$02,$12,$00
:V060c2			w $0007
			b "M-W",$02,$00,$01,$80

:V060d0			b >Disk_OK-1
			b >Dsk1541-1,>Dsk1571-1,>Dsk1581-1
			b >Disk_OK-1,>Disk_OK-1,>Disk_OK-1
			b >Disk_OK-1,>Disk_OK-1
			b >Dsk1581-1,>Dsk1581-1,>Dsk1581-1
:V060d1			b <Disk_OK-1
			b <Dsk1541-1,<Dsk1571-1,<Dsk1581-1
			b <Disk_OK-1,<Disk_OK-1,<Disk_OK-1
			b <Disk_OK-1,<Disk_OK-1
			b <Dsk1581-1,<Dsk1581-1,<Dsk1581-1

;*** Disk-Fehler abfangen.
.DiskError		lda	curDrive		;Disk-Fehler ausgeben
			add	$39
			sta	V061a2+9
			stx	L061a1+1
			jsr	ClrScreen
			LoadW	r0,V061a0
			ClrDlgBoxCSet_Grau
			jmp	InitScreen

;*** Infobox anzeigen.
:L061a0			jsr	ISet_Achtung
			PrintXY	120,90,V061a2
:L061a1			ldx	#$00
			stx	r0L
			ClrB	r0H
			lda	#%11000000
			jmp	PutDecimal

;*** Variablen.
:V061a0			b $01
			b 56,127
			w 64,255
			b OK        , 16, 48
			b DBTXTSTR  , 56, 24
			w V061a1
			b DB_USR_ROUT
			w L061a0
			b NULL

:V061a1			b PLAINTEXT,BOLDON
			b "Disketten-Fehler !",NULL
:V061a2			b "Laufwerk x: #"
			b PLAINTEXT,NULL
