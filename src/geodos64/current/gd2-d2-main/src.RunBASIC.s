; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"Sym128.erg"
			t	"TopMac"
			t	"GD_Mac"
			t	"src.GeoDOS.ext"
endif

			n	"mod.#106.obj"
			o	ModStart
			r	EndAreaMenu

			jmp	RunBASIC

;*** BASIC-Files starten.
:RunBASIC		bit	c128Flag
			bpl	:100
			DB_OK	V1060e1
			jmp	InitScreen

::100			lda	Target_Drv
			ldx	#$00
			jsr	InsertDisk
			cmp	#$01
			beq	:101
			jmp	InitScreen

::101			lda	curDrvMode		;CMD-Drive ?
			bmi	:102			;Ja, Partitionen auswählen.
			jmp	GetBasicFile		;Dateien einlesen.

;*** Partitionen einlesen.
::102			jsr	InitCMD2
			txa
			bne	:103

			jsr	GetCurPInfo
			txa
			bne	:104

			sty	V1060b0

			jsr	CMD_AllPart		;Alle Partitionen einlesen.
			cpx	#$00
			bne	:104
			tax
			stx	V1060b1
			bne	:105
::103			jmp	GetNativeDir
::104			jmp	DiskError

::105			lda	FilePTab
			bne	:106

			jsr	i_MoveData
			w	FileNTab+16
			w	FileNTab
			w	16*255
			jsr	i_FillRam
			w	16
			w	FileNTab+16*255
			b	$00

			jsr	i_MoveData
			w	FilePTab+ 1
			w	FilePTab
			w	255
			ClrB	FilePTab+255
			dec	V1060b1

::106			lda	V1060b1
			cmp	#$02
			bcs	:107
			jmp	GetNativeDir

::107			lda	#<V1060d2
			ldx	#>V1060d2
			jsr	SelectBox

			lda	r13L
			beq	:110
			cmp	#$01
			bne	:108
			lda	V1060b0
			jmp	:111			;Verzeichnisse einlesen...

::108			jmp	ExitMenuBASIC		;Nein, zurück zum GeoDOS-Menü.

::110			ldy	r13H
			lda	FilePTab,y
			beq	:108
::111			sta	V1060b2
			jsr	SaveNewPart

;*** NATIVE-Verzeichnis wechseln.
:GetNativeDir		lda	curDrvMode		;CMD-Laufwerk ?
			bpl	:102			;Ja, weiter...

			jsr	GetCurPInfo

			lda	Part_Info +2
			cmp	#$01			;Native-Mode-Partition ?
			bne	:102			;Nein, Dateien einlesen.

			C_Send	V1060c2			;Hauptverzeichnis aktivieren.

			lda	curDrvType
			cmp	#Drv_CMDRL
			beq	:101
;--- Ergänzung: 22.11.18/M.Kanet
;RAMDrive ist der RAMLink ähnlich, daher Kennung angepasst.
			cmp	#Drv_CMDRD
			bne	OpenNativeDir

::101			C_Send	V1060c2
::102			jmp	GetBasicFile

;*** Native-Verzeichnis auswählen.
:OpenNativeDir		jsr	CMD_NativeDir		;Verzeichnisse einlesen.
			cpx	#$00
			bne	:105
			tax
			bne	:106			;Ja, weiter...
::104			jmp	GetBasicFile		;Dateien einlesen.
::105			jmp	DiskError

::106			lda	#<V1060a1		;Verzeichnis auswählen.
			ldx	#>V1060a1
			jsr	SetFileBox

			lda	r13L
			cmp	#$00
			beq	:107
			cmp	#$01			;Klick auf "OK" ?
			beq	GetBasicFile		;Ja, Dateien einlesen.
			jmp	ExitMenuBASIC		;Zurück zu GeoDOS.

::107			ldy	#$00			;Verzeichnis aufrufen.
::108			lda	(r15L),y
			beq	:109
			sta	V1060c1,y
			iny
			cpy	#$10
			bne	:108

::109			tya
			add	3
			sta	V1060c0+0

			C_Send	V1060c0
			jmp	OpenNativeDir

;*** BASIC-Dateien einlesen.
:GetBasicFile		jsr	CMD_Files
			cpx	#$00
			bne	:102
			tax
			bne	:103
			DB_OK	V1060e0
::101			jmp	ExitMenuBASIC		;Zurück zu GeoDOS.
::102			jmp	DiskError

::103			lda	#<V1060a2		;Partition auswählen.
			ldx	#>V1060a2
			jsr	SetFileBox

			lda	r13L
			bne	:101

::104			ldy	#$00
::105			lda	(r15L),y		;Dateiname in Zwischenspeicher.
			beq	:106
			sta	StartBASIC,y
			iny
			cpy	#$10
			bne	:105
::106			sty	LenFileName+1		;Länge des Dateinamens merken.

			ldx	Target_Drv		;Aktuelles Laufwerk merken.
			lda	DriveAdress-8,x
			sta	LoadDrive  +1
			sta	StartDrive +1
			sta	L8035      +1

			lda	V1060b2
			sta	L804E    +1
			jsr	SetNewPart
			jmp	C64BootFile

;*** Partition wieder einstellen.
:ExitMenuBASIC		lda	curDrvMode
			bpl	:1

			lda	V1060b0
			jsr	SaveNewPart
::1			jmp	InitScreen		;Zurück zum GeoDOS-Menü.

;*** Auswahlbox mit Titel.
:SetFileBox		sta	V1060d1+0
			stx	V1060d1+1
			lda	#<V1060d0
			ldx	#>V1060d0
			jmp	SelectBox

;*** Routine zum starten eines BASIC-Files.
:C64BootFile		sei				;IRQ abschalten.
			lda	$01			;Sicherstellen, das neben dem Kernal
			and	#%11000000		;auch das BASIC-ROM eingeblendet ist.
			ora	#%00110111
			sta	$01

			ldy	#$00			;Neue Boot-Routine nach $8000
::101			lda	L8000,y			;kopieren.
			sta	$8000,y
			iny
			bne	:101

			lda	$e394 +1		;Einsprung zur Initialisierung der
			sta	$801c +1		;Vektoren ab ":$0300" aus Original-
			lda	$e394 +2		;Kernal entnehmen. Ist bei einem:
			sta	$801c +2		;Jiffy-DOS ROM = $E4B7.
							;Original  ROM = $E453.
			jmp	$fce2			;C64-Reset auslösen.

;*** Neue Boot-Routine.
:L8000			w	$8009			;Zeiger auf RESET-Routine.
:L8002			w	$8009			;Zeiger auf RESET-Routine.
:L8004			b	$c3,$c2,$cd		;":CBM80"  Kennung "CBM80" für
:L8007			b	$38,$30			;          Neue Boot-Routine.
:L8009			sei
:L800A			ldx	#$ff			;          VIC-Register löschen.
:L800C			stx	$d016
:L800F			jsr	$fda3			;":IOINIT" CIA-Register löschen.
:L8012			jsr	$fd50			;":RAMTAS" RAM-Reset
							;          Kassettenpuffer einrichten.
							;          Bildschirm auf $0400.
:L8015			jsr	$fd15			;":RESTOR" Standard I/O-Vektoren.
:L8018			jsr	$ff5b			;":CINT"   Bildschirm-Editor-Reset.
:L801B			cli				;          IRQ freigeben.
:L801C			jsr	$e453			;":INIVEC" Vektoren ab $0300 setzen.
							;          Bei Jiffy-DOS zusätzlich
							;          F-Tasten und JD-Befehle
							;          wieder aktivieren.
:L801F			jsr	$e3bf			;":INITMP" Reset RAM-Hilfsspeicher.
:L8022			jsr	$e422			;":MSGNEW" Einschaltmeldung/NEW.
:L8025			ldx	#$fb			;          Stapelzeiger löschen.
:L8027			txs
:L8028			stx	$8005			;          CBM80-Kennung löschen.

;*** Partition auf RL aktivieren.
:L802B			jsr	$ffae			;":UNLSN"  Ser. Bus aktivieren.
:L802E			lda	#0
:L8030			jsr	$ffbd
:L8033			lda	#$0f
:L8035			ldx	#$09
:L8037			ldy	#$0f
:L8039			jsr	$ffba
:L803C			jsr	$ffc0			;Befehlskanal öffnen.
:L803F			ldx	#$0f			;Ausgabekanal aktivieren.
:L8041			jsr	$ffc9
:L8044			lda	#$43			;Befehl "CP"+Nr an Gerät senden.
:L8046			jsr	$ffd2			;Zweck: Die eingestellte Partition
:L8049			lda	#$d0			;bei der Dateiauswahl wird beim
:L804B			jsr	$ffd2			;Reset auf den Ausgangswert zurück-
:L804E			lda	#$14			;gesetzt. Damit das File später von
:L8050			jsr	$ffd2			;der RL korrekt geladen werden kann,
:L8053			lda	#$0d			;muß hier die Partition von Hand
:L8055			jsr	$ffd2			;zurückgesetzt werden.
:L8058			jsr	$ffcc			;Standard-I/O.
:L805B			lda	#$0f
:L805D			jsr	$ffc3			;Befehlskanal schließen.

;*** BASIC-Laderoutine nach $0120 kopieren.
:L8060			ldy	#$00
:L8062			lda	$8070,y
:L8065			sta	$0120,y
:L8068			iny
:L8069			cpy	#$48
:L806B			bne	L8062
:L806D			jmp	$0130			;Programm laden.

;*** Routine zum Starten eines BASIC-Files.
:L8070
:StartBASIC		s $10				;Speicher für Dateiname.

:LenFileName		lda	#0			;Dateiname festlegen.
			ldx	#<$0120
			ldy	#>$0120
			jsr	$ffbd

			lda	#$01			;Geräte-/Sekundär-Adresse festlegen.
:LoadDrive		ldx	#$09
			ldy	#$00
			jsr	$ffba

			lda	#$00			;Datei nach $0801 laden.
			ldx	#<$0801
			ldy	#>$0801
			jsr	$ffd5
			stx	$2d			;Endadresse BASIC-File.
			sty	$2e

			lda	#<$a376			;"READY"-Meldung ausgeben.
			ldy	#>$a376
			jsr	$ab1e

			jsr	$a659			;":NEWCLR" BASIC-Vektoren setzen.
			jsr	$a533			;":LNKPRG" Link-Pointer berechnen.

:StartDrive		lda	#0
			sta	$ba

			ClrB	$9d
			jmp	$a7ae			;":INTPRT" RUN-Befehl ausführen.

:EndBASIC		brk

;*** Variablen.
if Sprache = Deutsch
:V1060a0		b PLAINTEXT,"Partition wählen",NULL
:V1060a1		b PLAINTEXT,"Verzeichnis wählen",NULL
:V1060a2		b PLAINTEXT,"BASIC-Programme",NULL
endif

if Sprache = Englisch
:V1060a0		b PLAINTEXT,"Select partition",NULL
:V1060a1		b PLAINTEXT,"Select directory",NULL
:V1060a2		b PLAINTEXT,"BASIC-applications",NULL
endif

:V1060b0		b $00				;Aktuelle Partitions-Nr.
:V1060b1		b $00
:V1060b2		b $00

:V1060c0		w $0000
			b "CD:"
:V1060c1		s 17
:V1060c2		w $0004
			b "CD//"

:V1060d0		b $ff
			b $00
			b $00
			b $10
			b $00
:V1060d1		w $ffff
			w FileNTab

:V1060d2		b $ff
			b $00
			b $00
			b $10
			b $00
			w V1060a0
			w FileNTab

if Sprache = Deutsch
:V1060e0		w :101, :102, ISet_Achtung
::101			b BOLDON,"Keine Dateien auf dieser",NULL
::102			b        "Diskette / Partition !",NULL

:V1060e1		w :101, :102, ISet_Achtung
::101			b BOLDON,"GEOS128: Starten von BASIC-",NULL
::102			b        "Programmen nicht möglich!",NULL
endif

if Sprache = Englisch
:V1060e0		w :101, :102, ISet_Achtung
::101			b BOLDON,"No files found on this",NULL
::102			b        "disk / partition !",NULL

:V1060e1		w :101, :102, ISet_Achtung
::101			b BOLDON,"GEOS128: Not able to",NULL
::102			b        "open BASIC-applications!!",NULL
endif
