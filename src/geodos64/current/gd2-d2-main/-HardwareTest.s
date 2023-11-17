; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerke überprüfen.
:InitTest		lda	#$00
			sta	RL_CONNECT

			jsr	PurgeTurbo
			jsr	InitForIO
			jsr	CLALL			;CLALL, Standard I/O.
			jsr	DoneWithIO

			lda	curDrive
			sta	SystemDrive

			jsr	KillTurboDOS
			jsr	GetAllFD

::100			LoadB	curDrvTest,8		;Laufwerksnummer.

::101			bit	ScreenMode
			bmi	:101a
			lda	curDrvTest		;Laufwerksnummer ausgeben.
			tax
			add	$39
			sta	V151a0+9
			lda	V151a1-8,x		;Test-Hinweis ausgeben.
			sta	r1H
			LoadW	r11,64
			PrintStrgV151a0

::101a			ldx	curDrvTest
			lda	driveType-8,x		;Laufwerks-Typ ermitteln.
			bne	:102			;Kein Laufwerk...
			sta	DriveTypes -8,x
			sta	DriveModes -8,x
			sta	DriveAdress-8,x
			sta	curTestMode
			beq	:103

::102			jsr	TestCurDrive
::103			jsr	PrintDrive

			inc	curDrvTest
			CmpBI	curDrvTest,12
			bcc	:101

;*** Auf SuperCPU testen.
			bit	ScreenMode
			bmi	:104

			jsr	InitForIO
			PushB	$d0b2
			jsr	DoneWithIO
			pla
			bmi	:104

if Sprache = Deutsch
			Print	64,142
			b	"SuperCPU aktiv!",NULL
endif

if Sprache = Englisch
			Print	64,142
			b	"SuperCPU activ!",NULL
endif

::104			rts

;*** Test-Ergebnis ausgeben.
:PrintDrive		ldy	curDrvTest
			lda	DrvSD2IEC  -8,y
			beq	:100
			lda	DriveTypes -8,y
			ldx	#<V151f4
			ldy	#>V151f4
			cmp	#Drv_1541		;Typ 1541?
			beq	:90
			ldx	#<V151f5
			ldy	#>V151f5
			cmp	#Drv_1571		;Typ 1571?
			beq	:90
			ldx	#<V151f6
			ldy	#>V151f6
			cmp	#Drv_1581		;Typ 1581?
			bne	:100
::90			stx	r0L
			sty	r0H
			jmp	:100a

::100			lda	curTestMode
			asl
			asl
			asl
			sta	r0L
			ClrB	r0H
			AddVW	V151f0,r0

::100a			lda	curDrvTest
			sub	8
			asl
			asl
			asl
			tax
			ldy	#$00
::101			lda	(r0L),y
			sta	Drive_ASCII,x
			inx
			iny
			cpy	#$07
			bne	:101

			bit	ScreenMode
			bmi	:102

			ldx	curDrvTest		;Einzel-Test beendet, Laufwerks-Typ
			lda	V151a1-8,x		;in Info-Box ausgeben.
			sta	r1H
			LoadW	r11,148
			jsr	PutString

			ldy	curDrvTest
			lda	DriveAdress-8,y
			beq	:102
			sta	r0L
			lda	#$00
			sta	r0H
			sta	r1L 			;Physikalische Geräteadresse
			ldy	#$07			;ausgeben.
			jsr	DoZahl24Bit
			lda	#":"
			jsr	SmallPutChar

::102			rts

;*** Auf allen Laufwerken TurboDOS entfernen.
:KillTurboDOS		lda	#11
::101			pha
			tax
			ldy	driveType-8,x
			beq	:102
			jsr	SetDevice
			jsr	PurgeTurbo
::102			pla
			sub	1
			cmp	#8
			bcs	:101
			rts

;*** Laufwerke 8-29 auf Existenz testen.
:GetAllFD		lda	#$08
			jsr	SetDevice
			jsr	PurgeTurbo
			jsr	InitForIO

			LoadB	curDrvTest,29

::101			jsr	IEC_Send_U0		;Reset/User-Vektoren zurücksetzen.
			lda	#$0f
			jsr	CLOSE

			lda	STATUS
			bne	:103

			ldx	curDrvTest
			txa
			sta	IECBusDrvAdr -8,x

			jsr	GetCMD_Typ
			jsr	ChkCMD_Code
			cmp	#Drv_None
			beq	:103

			ldx	curDrvTest
			sta	IECBusDrvType-8,x

			cmp	#Drv_CMDRL
			beq	:102
			cmp	#Drv_CMDRD
			bne	:103
::102			stx	RL_CONNECT

::103			CmpBI	curDrvTest,8
			beq	:104
			dec	curDrvTest
			jmp	:101

::104			jsr	DoneWithIO

			lda	SystemDrive
			jmp	SetDevice

;*** Befehl "U0" an Floppy senden.
;(Reset/User-Vektoren zurücksetzen)
:IEC_Send_U0		lda	#$0f			;Geräteadresse und Sekundäradresse
			tay				;setzen.
			ldx	curDrvTest
			jsr	SETLFS

			lda	#$02			;Zeiger auf "U0"-Befehl.
			ldx	#<V151e0
			ldy	#>V151e0
			jsr	SETNAM

			jmp	OPENCHN			;Befehlskanal öffnen.

;*** CMD-Kennungen einlesen.
:GetCMD_Typ		jsr	IEC_Send_U0		;Reset/User-Vektoren zurücksetzen.

			lda	#<V151b0
			ldx	#>V151b0
			ldy	#$06
			jsr	SendCMD_Code

			lda	#<V151b1
			ldx	#>V151b1
			ldy	#$06
			jsr	GetCMD_Code

			lda	#<V151b2
			ldx	#>V151b2
			ldy	#$06
			jsr	SendCMD_Code

			lda	#<V151b3
			ldx	#>V151b3
			ldy	#$04
			jsr	GetCMD_Code

			lda	#$0f
			jmp	CLOSE

;*** CMD-Erkennung senden.
:SendCMD_Code		sta	r0L
			stx	r0H
			sty	r1L

			ldx	#$0f
			jsr	CKOUT

			lda	#$00
			sta	:101 +1
::101			ldy	#$ff
			cpy	r1L
			beq	:102
			lda	(r0L),y
			jsr	$ffd2
			inc	:101 +1
			jmp	:101

::102			jmp	CLRCHN

;*** CMD-Erkennung empfangen.
:GetCMD_Code		sta	r0L
			stx	r0H
			sty	r1L

			ClrB	STATUS

			ldx	#$0f
			jsr	CHKIN

			lda	#$00
			sta	:101 +4
::101			jsr	$ffe4
			ldy	#$ff
			cpy	r1L
			beq	:102
			sta	(r0L),y
			inc	:101 +4
			jmp	:101

::102			jmp	CLRCHN

;*** CMD-Erkennung.
:ChkCMD_Code		LoadW	a0,V151b1
			LoadW	a1,V151b3

			lda	#<V151c0		;ROM-Kennung auf "CMD_RL" testen.
			ldx	#>V151c0
			jsr	CompareCMD
			bne	:101
			lda	#Drv_CMDRL
			rts

::101			lda	#<V151c1		;ROM-Kennung auf "CMD_RD" testen.
			ldx	#>V151c1
			jsr	CompareCMD
			bne	:102
			lda	#Drv_CMDRD
			rts

::102			lda	#<V151c2		;ROM-Kennung auf "CMD_FD" testen.
			ldx	#>V151c2
			jsr	CompareCMD
			bne	:105

			lda	#<V151c4		;ROM-Kennung auf "2000" testen.
			ldx	#>V151c4
			jsr	CompareCMD2
			bne	:104
::103			lda	#Drv_CMDFD2
			rts

::104			lda	#<V151c5		;ROM-Kennung auf "4000" testen.
			ldx	#>V151c5
			jsr	CompareCMD2
			bne	:103
			lda	#Drv_CMDFD4
			rts

::105			lda	#<V151c3		;ROM-Kennung auf "CMD_HD" testen.
			ldx	#>V151c3
			jsr	CompareCMD
			bne	:106
			lda	#Drv_CMDHD
			rts

::106			lda	#Drv_None		;Kein CMD-Laufwerk.
			rts

;*** CMD-Erkennungstexte vergleichen.
:CompareCMD		ldy	#$06
			b $2c
:CompareCMD2		ldy	#$04
			sta	a2L
			stx	a2H

			lda	#a0L
			cpy	#$06
			beq	:101
			lda	#a1L
::101			sta	:103 +1

::102			dey
::103			lda	(a0L),y
			cmp	(a2L),y
			bne	:104
			tya
			bne	:102
::104			rts

;*** Nächstes Laufwerk überprüfen.
:TestCurDrive		lda	curDrvTest
			jsr	SetDevice		;Laufwerk aktivieren.
			jsr	PurgeTurbo		;TurboDOS entfernen.

			jsr	Test64Net		;Auf 64Net testen.
			txa
			bne	:103			;Kein 64Net.
			jmp	Is64Net			;=> 64Net vorhanden.

::103			ldy	curDrvTest
			lda	driveType-8,y		;Laufwerkstyp ermitteln.
			beq	:105
			bmi	:104			;RAM-Laufwerk ? Ja, weiter.

			and	#%00110000		;"gateWay"-RAM-Laufwerk ? Ja, weiter.
			cmp	#%00110000
			beq	:104
			jmp	TestFD_Drv		;Echtes Laufwerk erkennen.
::104			jmp	TestRAM_Drv		;RAM-Laufwerk erkennen.
::105			jmp	GEOS_NODRIVE		;Unbekanntes Laufwerk.

;*** Auf physikalisches Laufwerk testen.
:TestFD_Drv		lda	driveType-8,y		;Laufwerkstyp ermitteln.
			and	#%00001111
			cmp	#$01
			beq	:2
			cmp	#$02
			beq	:3
			cmp	#$03
			beq	:4
			cmp	#$04
			beq	:5
			cmp	#$05
			beq	:6
::1			jmp	GEOS_NODRIVE
::2			jmp	Is1541
::3			jmp	Is1571
::4			jmp	Is1581
::5			jmp	IsNative
::6			jmp	IsDOS

;*** Auf physikalisches Laufwerk testen.
:TestRAM_Drv		lda	driveType-8,y		;Laufwerkstyp ermitteln.
			and	#%00001111
			cmp	#$01
			beq	:1
			cmp	#$02
			beq	:2
			cmp	#$03
			beq	:3
			cmp	#$04
			beq	:4
			jmp	GEOS_NODRIVE
::1			jmp	IsRAM41
::2			jmp	IsRAM71
::3			jmp	IsRAM81
::4			jmp	IsRAMnat

;*** Ist "echtes" Laufwerk noch eingeschaltet ?
:IsDriveOnLine		ldy	curDrvTest
			ldx	DriveAdress-8,y
			beq	:102

			jsr	PurgeTurbo
			jsr	InitForIO

			ldy	curDrvTest
			ldx	DriveAdress-8,y
			lda	#$02
			tay
			jsr	SETLFS
			lda	#$00
			jsr	SETNAM
			jsr	OPENCHN
			lda	#$02
			jsr	CLOSE

			lda	STATUS
			pha
			jsr	DoneWithIO
			pla
			tax
			beq	:102
			ldx	#$ff
::102			rts

;*** Kein Laufwerk.
:GEOS_NODRIVE		ldy	#Drv_None
			b $2c

;*** Unbekanntes Laufwerk.
:GEOS_UNKNOWN		ldy	#Drv_Unknown

;*** Laufwerk ohne Geräteadresse.
:SetNoDrvAdr		ldx	#$00

;*** Laufwerk mit Geräteadresse definieren.
;Übergabe:		YReg	Laufwerkstyp
;			XReg	IECBus-Adresse.
:SetStdDrive		sty	curTestMode
			lda	V151f2       ,y
			ldy	curDrvTest
			sta	DriveTypes -8,y
::101			ldy	curTestMode
			lda	V151f3       ,y
			ldy	curDrvTest
			sta	DriveModes -8,y
			txa
			sta	DriveAdress-8,y

			jsr	IsDriveOnLine
			txa
			bne	GEOS_NODRIVE

;--- Ergänzung: 23.10.18/M.Kanet
;Sonderbehandlung für SD2IEC:
;Bei einer 1581 wird das Bit #4="DOS-Kompatibles Laufwerk" gesetzt.
;Das führt u.a. dazu das bei der Routine "Diskette im Laufwerk" Job-Queues
;im RAM der 1581 genutzt werden um auf eine Diskette zu testen. Das lesen
;eines Sektors über "GetBlock" würde bei einer DOS-formatierten Diskette
;nicht funktionieren. Das SD2IEC unterstützt aber keine Job-Queues.
;Daher bei SD2IEC das DOS-Flag löschen.
			ldy	curDrvTest
			lda	DriveTypes -8,y		;Laufwerkstyp einlesen.
			cmp	#Drv_1541		;Typ 1541?
			beq	:102			; => Nein, Ende...
			cmp	#Drv_1571		;Typ 1571?
			beq	:102			; => Nein, Ende...
			cmp	#Drv_1581		;Typ 1581?
			beq	:102			; => Nein, Ende...
			cmp	#Drv_Native		;Typ Native?
			bne	:103			; => Nein, Ende...
;			lda	DriveModes -8,y		;DOS-Bit gesetzt?
;			and	#%00010000
;			beq	:102			; => Nein, Ende...

::102			jsr	TestSD2IEC		;SD2IEC-Erkennung starten.
			txa				;$00 = 1581, $ff = SD2IEC.
			beq	:103			;Kein SD2IEC => Ende...

			ldy	curDrvTest		;SD2IEC: DOS-Bit löschen.
			lda	DriveModes -8,y
			and	#%11101111
			ora	#%00000001		;SD2IEC-Kennung setzen.
			sta	DriveModes -8,y

			lda	#$ff			;SD2IEC-Laufwerk merken.
			sta	DrvSD2IEC  -8,y

			ldx	#$00
::103			rts

;*** Auf 1581 oder SD2IEC testen.
;Dazu den Befehl "M-R",$00,$03,$03 senden.
;Die Rückmeldung "00,(OK,00,00)" deutet auf ein SD2IEC hin.
:TestSD2IEC		jsr	PurgeTurbo
			jsr	InitForIO

			lda	#$0f			;Befehlskanal öffnen.
			tay
			ldx	curDrvTest
			jsr	SETLFS
			lda	#$00
			jsr	SETNAM

;--- Ergänzung: 21.11.18/M.Kanet
;Das SD2IEC unterstützt nur "U0>id" zum wechseln der
;Geräteadressen. Andere U0-Befehle sind nicht implementiert.
;			jsr	IEC_Send_U0

			jsr	OPENCHN

			lda	#<V151e3
			ldx	#>V151e3
			ldy	#$06
			jsr	SendCMD_Code

			lda	#<V151e4
			ldx	#>V151e4
			ldy	#$03
			jsr	GetCMD_Code

			lda	#$0f
			jsr	CLOSE

			ldx	#$ff			;Vorgabe: SD2IEC.
			lda	V151e4 +0		;Rückmeldung auswerten.
			cmp	#"0"			;"00," ?
			bne	:101			; => Nein, Ende...
			lda	V151e4 +1
			cmp	#"0"
			bne	:101
			lda	V151e4 +2
			cmp	#","
			beq	:102
::101			ldx	#$00			;Kein SD2IEC.
::102			jmp	DoneWithIO

;*** Auf 64Net testen.
:Test64Net		ldy	#$04
::101			lda	V151c6,y
			cmp	$904f,y
			bne	:102
			dey
			bpl	:101
			ldx	#$00
			rts

::102			ldx	#$ff
			rts

;*** Auf 64Net testen.
:Is64Net		ldx	curDrvTest		;Aktuelles Test-Laufwerk.
			lda	driveType -8,x		;Laufwerksmodus einlesen.
			and	#%00000111
			cmp	#%00000100
			bcc	:1
			lda	#%00000000
::1			asl				;Modus ??,41,71,81 in Laufwerks-
			tay				;bezeichnung übertragen.
			lda	V151d0 +0,y
			sta	V151f1 +5
			lda	V151d0 +1,y
			sta	V151f1 +6

			ldy	#Drv_64Net
			jmp	SetNoDrvAdr

;*** 1541-Laufwerk erkannt.
:Is1541			ldx	curDrvTest		;Aktuelles Testlaufwerk.
			ldy	IECBusDrvType-8,x	;Laufwerk vorhanden ?
			bne	:101			;Typ <> $00, CMD-Laufwerk.
			ldy	#Drv_1541		;1541-Laufwerk.
::101			jmp	SetStdDrive		;Erkennung abgeschlossen.

;*** 1571-Laufwerk erkannt.
:Is1571			ldx	curDrvTest		;Aktuelles Testlaufwerk.
			ldy	IECBusDrvType-8,x	;Laufwerk vorhanden ?
			bne	:101			;Typ <> $00, CMD-Laufwerk.
			ldy	#Drv_1571		;1571-Laufwerk.
::101			jmp	SetStdDrive		;Erkennung abgeschlossen.

;*** 1581-Laufwerk erkannt.
:Is1581			ldx	curDrvTest		;Aktuelles Testlaufwerk.
			ldy	IECBusDrvType-8,x	;Laufwerk vorhanden ?
			bne	:101			;Typ <> $00, CMD-Laufwerk.
			ldy	#Drv_1581		;1581-Laufwerk.
::101			jmp	SetStdDrive		;Erkennung abgeschlossen.

;*** Native-Laufwerk erkannt.
:IsNative		ldx	curDrvTest		;Aktuelles Testlaufwerk.
			ldy	IECBusDrvType-8,x	;Laufwerk vorhanden ?
			bne	IsCMD			;Typ <> $00, CMD-Laufwerk.
			ldy	#Drv_Native		;IECBus-Laufwerk.
			jmp	SetStdDrive		;Erkennung abgeschlossen.

;*** NATIVE-Laufwerk erkannt.
:IsCMD			ldx	curDrvTest		;Aktuelles Testlaufwerk.
			ldy	IECBusDrvType-8,x	;Laufwerk vorhanden ?
			bne	:102			;Typ <> $00, CMD-Laufwerk.
::101			jmp	GEOS_UNKNOWN		;NATIVE nur auf CMD erkennen.

::102			cpy	#Drv_CMDFD2		;"CMD xx" nach "CMD+xx"
			beq	:103			;konvertieren.
			cpy	#Drv_CMDFD4
			beq	:104
			cpy	#Drv_CMDHD
			beq	:105

::103			ldy	#Drv_CMDFD2nat
			b $2c
::104			ldy	#Drv_CMDFD4nat
			b $2c
::105			ldy	#Drv_CMDHDnat
			jmp	SetStdDrive

;*** PCDOS-Laufwerk erkannt.
:IsDOS			ldx	curDrvTest		;Aktuelles Testlaufwerk.
			ldy	IECBusDrvType-8,x	;Laufwerk vorhanden ?
			bne	:102			;Typ <> $00, CMD-Laufwerk.
			ldy	#Drv_DOS_1581		;1581-Laufwerk.
::101			jmp	SetStdDrive		;Erkennung abgeschlossen.

::102			cpy	#Drv_CMDFD2		;"CMD xx" nach "CMD+xx"
			beq	:103			;konvertieren.
			cpy	#Drv_CMDFD4
			beq	:104
			jmp	GEOS_UNKNOWN		;NATIVE nur auf CMD erkennen.

::103			ldy	#Drv_DOS_FD2
			b $2c
::104			ldy	#Drv_DOS_FD4
			jmp	SetStdDrive

;--- Ergänzung: 21.11.18/M.Kanet
;Mit der Einführung der SuperRAM-Treiber für C=REU und GeoRAM in MegaPatch
;Kann auch ein RAMLaufwerk ausserhalb des GEOS-DACC genutzt werden.
;Daher muss die Erkennungsroutine RAMLink oder nicht angepasst werden.
;*** Auf RAM41-Laufwerk testen.
:IsRAM41		jsr	TestRAM_DACC		;RL-Partition oder RAM-Laufwerk ?
			bcs	Test_RL_ExRAM		;-> Partition, RL/RD erkennen.
:SetRAM41		ldy	#Drv_R1541		;RAM41-Laufwerk erkannt.
			jmp	SetNoDrvAdr		;Laufwerk ohne Geräteadresse setzen.

;*** Auf RAM71-Laufwerk testen.
:IsRAM71		jsr	TestRAM_DACC		;RL-Partition oder RAM-Laufwerk ?
			bcs	Test_RL_ExRAM		;-> Partition, RL/RD erkennen.
:SetRAM71		ldy	#Drv_R1571
			jmp	SetNoDrvAdr

;*** Auf RAM81-Laufwerk testen.
:IsRAM81		jsr	TestRAM_DACC		;RL-Partition oder RAM-Laufwerk ?
			bcs	Test_RL_ExRAM		;-> Partition, RL/RD erkennen.
:SetRAM81		ldy	#Drv_R1581
			jmp	SetNoDrvAdr

;*** Auf RAMNative-Laufwerk testen.
:IsRAMnat		jsr	TestRAM_DACC		;RL-Partition oder RAM-Laufwerk ?
			bcs	Test_RL_ExRAM		;-> Partition, RL/RD erkennen.
:SetRAMnat		jsr	GetDirHead		;GateWay-RAMDisk?
			lda	curDirHead +1		;Die GateWay-Native-RAMDisk hat nur
			cmp	#$22			;5 BAM-Sektoren, $22 bei CMD-Native.
			bcc	:101
			lda	curDirHead +2
			cmp	#"H"
			bne	:101
			ldy	#Drv_RNAT		;RAMNative (C=REU/GeoRAM)
			b $2c
::101			ldy	#Drv_GWRD		;GateWay RAMDisk.
			jmp	SetNoDrvAdr

;*** Laufwerkstyp erkennen und ggf. nach gateWay konvertieren.
;GateWay:		RL81	%00110011
;			RLNat	%00110100
:Test_RL_ExRAM		ldx	RL_CONNECT		;RAMLink/RAMDrive vorhanden?
			bne	:101			; => Ja, weiter...

;--- Ergänzung: 08.11.18/M.Kanet
;Ab hier Auswertung Laufwerkstyp ausserhalb GEOS-DACC aber kein
;RAMLink/RAMDrive-Laufwerk.
::100			ldx	curDrvTest
			lda	driveType -8,x
			and	#%00001111

			cmp	#$01			;RAM41/71/81 sind bisher nicht
			beq	SetRAM41		;möglich. Mit MP3 sind nur "Extended
			cmp	#$02			;RAMNative"-Laufwerke auf C=REU,
			beq	SetRAM71		;GeoRAM oder SuperRAM möglich.
			cmp	#$03
			beq	SetRAM81
			cmp	#$04
			beq	SetRAMnat
			jmp	GEOS_UNKNOWN

;--- Ergänzung: 11.11.18/M.Kanet
;Ab hier Auswertung ob RAMLink-Partition oder
;MegaPatch "Extended RAMNative"-Laufwerk.
::101			jsr	TestRAM_RL
			bcs	:100			;Keine RAMLink.

;Ab hier nur noch RAMLink oder RAMDrive.
			ldx	RL_CONNECT
			ldy	IECBusDrvType -8,x

			ldx	curDrvTest
			lda	driveType -8,x
			and	#%00110000		;GEOS / GateWay?
			bne	:120			; => GateWay.

;--- GEOS.
			lda	driveType -8,x
			and	#%00000111
			cmp	#$04
			beq	:112

;--- GEOS: CMD RAMLink / RAMDrive 41/71/81.
::110			cpy	#Drv_CMDRD
			beq	:111
			ldy	#Drv_CMDRL
			b $2c
::111			ldy	#Drv_CMDRD
			ldx	RL_CONNECT
			jmp	SetStdDrive

;--- GEOS: CMD RAMLink / RAMDrive Native.
::112			cpy	#Drv_CMDRD
			beq	:113
			ldy	#Drv_CMDRLNat
			b $2c
::113			ldy	#Drv_RAMDrvNat
			ldx	RL_CONNECT
			jmp	SetStdDrive

;--- GateWay.
::120			lda	driveType -8,x
			and	#%00000111
			cmp	#$04
			beq	:132

;--- GateWay: CMD RAMLink / RAMDrive 41/71/81.
::130			cpy	#Drv_CMDRD
			beq	:131
			ldy	#Drv_CMDRL_GW
			b $2c
::131			ldy	#Drv_RAMDrv_GW
			ldx	RL_CONNECT
			jmp	SetStdDrive

;--- GateWay: CMD RAMLink / RAMDrive Native.
::132			cpy	#Drv_CMDRD
			beq	:133
			ldy	#Drv_CMDRLNat_GW
			b $2c
::133			ldy	#Drv_RAMDrvNat_GW
			ldx	RL_CONNECT
			jmp	SetStdDrive

;*** RAM-Laufwerksmodus testen Teil #1.
;   (RAM-Laufwerk im DACC-Speicher oder Ext.RAM bzw. Partition in RL/RD)
:TestRAM_DACC		ldx	curDrvTest		;Aktuelles Test-Laufwerk.
			lda	driveType -8,x		;Laufwerksmodus einlesen.
			and	#%00010000		;GateWay BIT #4 gesetzt ?
			bne	:105			; => Ja, RAMLink, weiter

;--- Prüfen ob RAM-Laufwerk im GEOS-DACC ist oder nicht.
			lda	curDrvTest
			jsr	SetDevice

			jsr	InitTestRAM
			txa
			bne	:106

			lda	#<diskBlkBuf
			sta	r0L
			lda	#>diskBlkBuf
			sta	r0H
			lda	#$00
			sta	r1L
			sta	r1H
			lda	#<$0100
			sta	r2L
			lda	#>$0100
			sta	r2H
			lda	#$00
			sta	r3L

::101			jsr	FetchRAM

			ldy	#$0f
::102			lda	diskBlkBuf +$c0,y
			cmp	TestDataCode   ,y
			bne	:103
			dey
			bpl	:102
			bmi	:106

::103			inc	r3L
			beq	:104
			lda	r3L
			cmp	ramExpSize
			bcc	:101

::104			jsr	ExitTestRAM
::105			sec				;Kein RAM-Laufwerk im GEOS-DACC.
			rts

::106			jsr	ExitTestRAM
			clc				;RAM-Laufwerk im GEOS-DACC.
			rts

;*** RAM-Laufwerksmodus testen Teil #2.
;   (RAM-Laufwerk im erweiterten Speicher oder Partition in RL/RD)
:TestRAM_RL		lda	curDrvTest
			jsr	SetDevice

			jsr	InitTestRAM
			txa
			bne	:104

			LoadB	r1L,1
			LoadB	r1H,0
			LoadW	r4,diskBlkBuf
			LoadB	r3H,1			;Partition #1.

;--- Ergänzung: 24.11.18/M.Kanet
;Partitionstyp ermitteln.
;Nur gültige Partitionen testen. Wird hier auch eine RL-DACC-Partition
;getestet dann verursacht das einlesen über RL/EXEC_SEC_REC einen
;Systemabsturz.
::101			jsr	GetRLPartInf		;Partitionstyp einlesen.
			cmp	#$00			;Nur testen wenn 41/71/81 oder Native.
			beq	:103
			cmp	#$05
			bcs	:103

			jsr	RL_SekRead		;Sektor aus RL-Partition lesen.
			txa
			bne	:103

			ldy	#$0f
::102			lda	diskBlkBuf +$c0,y
			cmp	TestDataCode   ,y
			bne	:103
			dey
			bpl	:102
			bmi	:105

::103			inc	r3H
			lda	r3H
			cmp	#32			;Max. Partitionen auf RL: 1-31.
			bcc	:101

::104			jsr	ExitTestRAM		;Kein RAMLink-Laufwerk.
			sec
			rts

::105			jsr	ExitTestRAM		;RAMLink-Laufwerk.
			clc
			rts

;*** Testdaten erzeugen.
:InitTestRAM		php
			sei
			ldx	CPU_DATA
			lda	#$35
			sta	CPU_DATA

			ldy	#$0f			;Testsektor aus Zufallsdaten
::101			tya				;erzeugen.
			eor	random +0
			eor	$d012
			sta	TestDataCode,y
			lda	random +1
			eor	$d012
			eor	TestDataCode,y
			sta	TestDataCode,y
			dey
			bpl	:101

			stx	CPU_DATA
			plp

			LoadB	r1L,1			;Block aus RAMDisk einlesen.
			LoadB	r1H,0
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:103

			ldy	#$0f			;Daten mit Testdaten austauschen.
::102			lda	diskBlkBuf +$c0,y
			sta	TestDataBuf    ,y
			lda	TestDataCode   ,y
			sta	diskBlkBuf +$c0,y
			dey
			bpl	:102

			jmp	PutBlock		;Testblock zurückschreiben.
::103			rts

;*** Inhalt Testsektor wieder herstellen.
:ExitTestRAM		LoadB	r1L,1			;Block aus RAMDisk einlesen.
			LoadB	r1H,0
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
			txa
			bne	:102

			ldy	#$0f			;Daten mit Testdaten austauschen.
::101			lda	TestDataBuf    ,y
			sta	diskBlkBuf +$c0,y
			dey
			bpl	:101

			jmp	PutBlock		;Testblock zurückschreiben.
::102			rts

;*** Sektor über Partitions-Register einlesen.
;    Übergabe:		r1   = Track/Sektor.
;			r3H  = Partitions-Nr.
;			r4   = Sektorspeicher.
;    Rückgabe:		-
;    Geändert:		AKKU,xReg,yReg
:RL_SekRead		ldy	#$80
			b $2c
:RL_SekWrite		ldy	#$90
			b $2c
:RL_SekVerify		ldy	#$a0
			b $2c
:RL_SekSwap		ldy	#$b0
:RL_DoSekJob		php				;IRQ-Status zwischenspeichern
			sei

			bit	c128Flag		;C64/C128 ?
			bmi	:101			; => C128, MMU setzen.

			lda	CPU_DATA		;CPU_DATA auf ROM setzen.
			pha
			lda	#$36
			sta	CPU_DATA
			bne	:102

::101			lda	MMU			;Konfiguration sichern.
			pha
			lda	#%01001110		;RAM-BANK#1 bis $bfff + IO + Kernal.
			sta	MMU			;für RAMLink-Transfer aktivieren.

			lda	RAM_Conf_Reg		;Konfiguration sichern
			pha
			and	#%11110000
			ora	#%00000100		;Common Area $0000 bis $0400.
			sta	RAM_Conf_Reg

::102			tya
			pha
			jsr	EN_SET_REC		;RL-Hardware aktivieren.
			pla
			sta	$de20			;Job-Code setzen.

			lda	r1L			;Sektor-Daten setzen.
			sta	$de21
			lda	r1H
			sta	$de22
			lda	r4L
			sta	$de23
			lda	r4H
			sta	$de24
			lda	r3H
			sta	$de25

			bit	c128Flag
			bpl	:103
			lda	#$01
			sta	$de26			;C128 RAM-Bank #1

::103			jsr	EXEC_REC_SEC		;Sektor-Jobcode ausführen.

			lda	$de20			;Fehlerstatus einlesen und
			sta	RLErrorCode		;zwischenspeichern.

			jsr	RL_HW_DIS2		;RL-Hardware abschalten.

			bit	c128Flag		;C64/C128 ?
			bmi	:104			; => C128, MMU setzen.

			pla				;CPU_DATA zurücksetzen.
			sta	CPU_DATA
			bne	:105

::104			pla				;MMU zurücksetzen.
			sta	RAM_Conf_Reg
			pla
			sta	MMU

::105			ldx	RLErrorCode
			plp				;IRQ-Status zurücksetzen.
			rts

;*** RAMLink-Partitionstyp einlesen.
;Übergabe:		r3H = Partitionsnummer.
:GetRLPartInf		lda	#$00
			ldx	r3H
			beq	:101
			cpx	#32
			bcc	:102
::101			rts

::102			jsr	PurgeTurbo		;TurboDOS deaktivieren.
			jsr	InitForIO		;I/O aktivieren.

			ldx	RL_CONNECT
			lda	#$0f
			tay
			jsr	SETLFS
			lda	#$00
			jsr	SETNAM
			jsr	OPENCHN

			lda	r3H			;Partitions-Nummer in "G-P" schreiben.
			sta	V151b4+3

			ldx	#$0f			;Ausgabekanal setzen.
			jsr	CKOUT

			lda	#$00			;"G-P" auf IECBus senden.
			sta	:103 +1
::103			ldy	#$ff
			cpy	#$05
			beq	:104
			lda	V151b4,y
			jsr	CHROUT
			inc	:103 +1
			jmp	:103

::104			jsr	CLRCHN			;Ausgabekanal schließen.

			ldx	#$0f			;Eingabekanal setzen.
			jsr	CHKIN

			lda	#$00			;Daten über IECBus empfangen und
			sta	:105 +4			;in Zwischenspeicher schreiben.
::105			jsr	GETIN
			ldy	#$ff
			cpy	#$1f
			beq	:106
			sta	V151b5,y
			inc	:105 +4
			jmp	:105

::106			jsr	CLRCHN			;Eingabekanal schließen.

			lda	#$0f
			jsr	CLOSE
			jsr	DoneWithIO
			lda	V151b5   + 0
			rts

;*** Variablen für :InitDrive.
:IECBusDrvAdr		s 24
:IECBusDrvType		s 24
:RL_CONNECT		b $00
:SystemDrive		b $00
:DrvSD2IEC		s $04

:curDrvTest		b $00				;Zähler für Laufwerke
:curTestMode		b $00
:ScreenMode		b $00

:TestDataBuf		s 16
:TestDataCode		s 16
:RLErrorCode		b $00

;*** Ausgabetext für Laufwerkssuche.
if Sprache = Deutsch
:V151a0			b "Laufwerk A:"
			b GOTOX
			w $0094
			b "Test...",NULL
endif

if Sprache = Englisch
:V151a0			b "Drive    A:"
			b GOTOX
			w $0094
			b "Test...",NULL
endif

:V151a1			b 96,107,118,129		;Ausgabezeilen.

;*** Variablen & Texte.
:V151b0			b "M-R",$a0,$fe,$06
:V151b1			s $06
:V151b2			b "M-R",$f0,$fe,$04
:V151b3			s $04
:V151b4			b "G-P",$ff,$0d
:V151b5			s 31

;*** CMD-ROM-Kennung.
:V151c0			b "CMD RL"
:V151c1			b "CMD RD"
:V151c2			b "CMD FD"
:V151c3			b "CMD HD"
:V151c4			b "2000"
:V151c5			b "4000"
:V151c6			b "64NET"

;*** Partitionstypen für 64Net.
:V151d0			b "??417181"

;*** Daten für Laufwerkserkennung.
:V151e0			b "U0"
:V151e3			b "M-R",$00,$03,$03
:V151e4			s $03

;*** Laufwerkstexte.
:V151f0

if Sprache = Deutsch
			b "(kein) ",NULL
endif

if Sprache = Englisch
			b "(none) ",NULL
endif
			b "1541   ",NULL
			b "1571   ",NULL
			b "1581   ",NULL
			b "RAM1541",NULL
			b "RAM1571",NULL
			b "RAM1581",NULL
			b "RAMNM+ ",NULL
			b "GWRAM+ ",NULL
			b "CMD RL ",NULL
			b "CMD RD ",NULL
			b "CMD FD2",NULL
			b "CMD FD4",NULL
			b "CMD HD ",NULL
:V151f1			b "64Net  ",NULL
			b "DOS_81 ",NULL
			b "DOS_FD2",NULL
			b "DOS_FD4",NULL
			b "SD2IEC+",NULL
			b "CMD RL ",NULL
			b "RAMDrv ",NULL
			b "CMD+RL ",NULL
			b "CMD+RD ",NULL
			b "CMD+RL ",NULL
			b "CMD+RD ",NULL
			b "CMD+FD2",NULL
			b "CMD+FD4",NULL
			b "CMD+HD ",NULL
			b "Typ ???",NULL

;--- Ergänzung: 21.11.18/M.Kanet
;Kennung für SD2IEC mit "file based memory emulation".
:V151f4			b "1541-SD",NULL
:V151f5			b "1571-SD",NULL
:V151f6			b "1581-SD",NULL

;*** Laufwerkstypen.
:V151f2			b Drv_None			;Kein Laufwerk.
			b Drv_1541			;Commodore 1541 (I,C,II).
			b Drv_1571			;Commodore 1571.
			b Drv_1581			;Commodore 1581.
			b Drv_R1541			;RAM-Drive 170 Kbyte = 1541.
			b Drv_R1571			;RAM-Drive 340 Kbyte = 1571.
			b Drv_R1581
			b Drv_RNAT			;RAM-Drive 790 Kbyte = 1581.
			b Drv_GWRD			;RAM-Drive Native.
			b Drv_CMDRL			;CMD RAMLink.
			b Drv_CMDRD			;RAMDrive.
			b Drv_CMDFD2			;CMD FD2000.
			b Drv_CMDFD4			;CMD FD4000.
			b Drv_CMDHD			;CMD HD.
			b Drv_64Net			;64Net
			b Drv_DOS_1581			;PCDOS 1581
			b Drv_DOS_FD2			;PCDOS FD2000
			b Drv_DOS_FD4			;PCDOS FD4000
			b Drv_Native			;IECBus Native-Mode.
			b Drv_CMDRL			;gateWay CMD RAMLink.
			b Drv_CMDRD			;gateWay RAMDrive.
			b Drv_CMDRL			;Native-Mode CMD RAMLink.
			b Drv_CMDRD			;Native-Mode RAMDrive.
			b Drv_CMDRL			;gateWay CMD RAMLink Native-Mode.
			b Drv_CMDRD			;gateWay RAMDrive Native-Mode.
			b Drv_CMDFD2			;Native-Mode CMD FD2000.
			b Drv_CMDFD4			;Native-Mode CMD FD4000.
			b Drv_CMDHD			;Native-Mode CMD HD.
			b Drv_None			;Unbekanntes Laufwerk.

;*** DriveModes
; %1xxxxxxx		= CMD Kompatibles Laufwerk.
; %x1xxxxxx		= CMD RAMLink oder RAMDrive-Laufwerk.
; %xx1xxxxx		= Native-Mode Laufwerk.
; %xxx1xxxx		= DOS Kompatibles Laufwerk.
; %xxxx1xxx		= RAM-Laufwerk.
; %xxxxx1xx		= BASIC-Kompatibles Laufwerk.
; %xxxxxx1x		= Drive D: inkompatibel wenn RL am Computer.
;                (Unter GEOS 2.x wegen driveData+3)
;--- Ergänzung: 21.11.18/M.Kanet
;SD2IEC-Laufwerke in DriveModes markieren.
; %xxxxxxx1		= SD2IEC Laufwerk.
;                (Wird durch :SetStdDrive gesetzt)
:V151f3			b %00000000			;Kein Laufwerk
			b %00000100			;1541
			b %00000110			;1571
			b %00010100			;1581
			b %00001000			;RAM 1541
			b %00001010			;RAM 1571
			b %00001000			;RAM 1581
			b %00101000			;RAM Native
			b %00101000			;GateWay RAMDisk
			b %11001100			;CMD RAMLink
			b %11001100			;CMD RAMDrive
			b %10010100			;CMD FD2
			b %10010100			;CMD FD4
			b %10000100			;CMD HD
			b %00000000			;64Net
			b %00110000			;PCDOS 1581
			b %00110000			;PCDOS FD2000
			b %00110000			;PCDOS FD4000
			b %00100100			;IECBus   Native
			b %10001100			;gateWay CMD RL
			b %10001100			;gateWay RAMDrive
			b %11101100			;CMD RL   Native
			b %11101100			;RAMDrive Native
			b %10101100			;CMD RL   Native GateWay
			b %10101100			;RAMDrive Native GateWay
			b %10110100			;CMD FD2  Native
			b %10110100			;CMD FD4  Native
			b %10100100			;CMD HD   Native
			b %00000000			;Unbekanntes Laufwerk
