; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Laufwerkstreiber installieren.
;Übergabe: DrvAdrGEOS = GEOS-Laufwerk A-D/8-11.
;          DrvMode    = Laufwerksmodus $01=1541, $33=RL81...
;Rückgabe: xReg = $00, Laufwerk installiert.
:InstallDriver		jsr	INIT_DEV_TEST		;Freien RAM-Speicher testen.
			cpx	#NO_ERROR		;Ist genügend Speicher frei ?
			beq	:1			; => Ja, weiter.

::no_ram		ldx	#NO_FREE_RAM
			rts

;--- Laufwerkstreiber initialisieren.
::1			lda	DrvMode			;Laufwerksmodus einlesen.
			ldx	DrvAdrGEOS		;GEOS-Laufwerksadresse einlesen.
			jsr	DskDev_Prepare		;Treiber installieren.

;--- RealDrvMode definieren:
;SET_MODE_...
; -> PARTITION/SUBDIR/FASTDISK/SD2IEC
; -> SRAM/CREU/GRAM
			ldx	DrvAdrGEOS		;Laufwerksmodi festlegen.
			lda	#SET_MODE_FASTDISK
			ora	RealDrvMode -8,x
			sta	RealDrvMode -8,x

;--- RAMBase nicht löschen.
;Wird ggf. durch den Editor gesetzt und
;dazu genutzt, um auf ein gültiges
;Verzeichnis zu prüfen.
;			lda	#$00
;			sta	ramBase -8,x

			txa
			clc
			adc	#$39
			sta	DRIVE_NAME +3

			ldy	#6
			jsr	FindFreeRAM		;Freien RAM-Speicher suchen.

			ldx	DrvAdrGEOS
			ldy	ramBase -8,x		;ramBase vordefiniert?
			beq	:2			; => Nein, weiter...

;--- Ergänzung: 21.08.21/M.Kanet
;Wenn Startadressen der RAM-Laufwerke
;nicht lückenlos sind, dann wurde das
;neue RAM-Laufwerk bisher an einer
;anderen Stelle im GEOS-DACC erstellt.
;Da von GD.CONFIG ":ramBase" an die
;INIT-Routine übergeben wird, kann hier
;nun geprüft weden ob an der Vorgabe
;ein RAM-Laufwerk mit passender Größe
;erstellt werden kann.
;Falls nicht, dann wird das Laufwerk
;ab der erste freien Bank erstellt.
			pha				;Erste freie Speicherbank merken.
			tya				;Vorgabe für erste Speicherbank.
			ldy	#6			;Anzahl Speicherbänke.
			jsr	ramBase_Check		;Speicher prüfen.
			pla
			cpx	#NO_ERROR		;Ist gewünschter Speicher frei?
			bne	:2			; => Nein, weiter...

			ldx	DrvAdrGEOS
			lda	ramBase -8,x		;Vorgabe für erste Speicherbank.

::2			pha				;RAM-Speicher in REU belegen.
			ldy	#6
			ldx	#%10000000
			jsr	AllocRAM
			pla
			cpx	#NO_ERROR		;Speicher reserviert ?
			bne	:exit			; => Nein, Installationsfehler.

			ldx	DrvAdrGEOS		;Startadresse RAM-Speicher in
			sta	ramBase   -8,x		;REU zwischenspeichern.

;--- Laufwerkstreiber in REU speichern.
			lda	DrvAdrGEOS		;Aktuelles Laufwerk festlegen.
			sta	curDevice		;Adresse wird für die Routine
			sta	curDrive		;":InitForDskDvJob" benötigt.

			jsr	InitForDskDvJob		;Laufwerkstreiber in GEOS-Speicher
			jsr	StashRAM		;kopieren.
			jsr	DoneWithDskDvJob

;--- BAM erstellen.
			jsr	CreateBAM		;BAM erstellen.

;			ldx	#NO_ERROR
::exit			rts				;Ende.

;*** RAM-Laufwerk bereits installiert ?
:TestCurBAM		jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	:52			; => Ja, Laufwerk initialisieren.

;--- Ergänzung: 18.09.19/M.Kanet
;Da standardmäßig keine GEOS-Disketten mehr erzeugt werden kann der
;GEOS-Format-String nicht als Referenz genutzt werden.
;Byte#2=$41 / Byte#3=$00/$80 verwenden.
if EN_GEOS_DISK = FALSE
			lda	curDirHead +2		;"A" = 1541/71.
			cmp	#$41
			bne	:52
			ldy	curDirHead +3		;$00 = Einseitig.
			beq	:51
			cpy	#$80			;$80 = Doppelseitig.
			bne	:52
endif

if EN_GEOS_DISK = TRUE
			LoadW	r0,curDirHead +$ad
			LoadW	r1,BAM_71a    +$ad
			ldx	#r0L
			ldy	#r1L			;Auf GEOS-Kennung
			lda	#12			;"GEOS-format" testen.
			jsr	CmpFString		;Kennung vorhanden ?
			bne	:52			; => Ja, Directory nicht löschen.
endif

::51			ldx	#NO_ERROR
			b $2c
::52			ldx	#BAD_BAM
			rts

;*** Neue BAM erstellen.
:ClearCurBAM		ldy	#$00			;Speicher für BAM #1 löschen.
			tya
::51			sta	curDirHead,y
			iny
			bne	:51

			ldy	#$00			;BAM für 1571 definieren.
::52			dey				;BAM #1 erzeugen.
			lda	BAM_71a     ,y
			sta	curDirHead  ,y
			tya
			bne	:52
::53			sta	dir2Head    ,y
			iny
			bne	:53

			ldy	#$69
::54			dey				;BAM #2 erzeugen.
			lda	BAM_71b     ,y
			sta	dir2Head    ,y
			tya
			bne	:54

			jsr	PutDirHead		;BAM auf Diskette speichern.
			txa
			bne	:55

			jsr	ClrDiskSekBuf		;Sektorspeicher löschen.

			lda	#$ff			;Hauptverzeichnis löschen.
			sta	diskBlkBuf +$01
			LoadW	r4 ,diskBlkBuf
			LoadB	r1L,$12
			LoadB	r1H,$01
			jsr	PutBlock
			txa
			bne	:55

if EN_GEOS_DISK = TRUE
			lda	#$13			;Sektor $13/$08 löschen.
			sta	r1L			;Ist Borderblock für DeskTop 2.0!
			lda	#$08
			sta	r1H
			jsr	PutBlock
endif

::55			rts

;*** Sektorspeicher löschen.
:ClrDiskSekBuf		ldy	#$00
			tya
::51			sta	diskBlkBuf,y
			dey
			bne	:51
			rts

;*** BAM für RAM41,71-Laufwerke.
:BAM_71a		b $12,$01,$41,$80,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $15,$ff,$ff,$1f,$15,$ff,$ff,$1f
			b $11,$fc,$ff,$07

;--- Ergänzung: 24.03.21/M.Kanet
;Standardmäßig wird keine GEOS-Diskette mehr erzeugtz,
;daher wird auch kein BorderBlock benötigt.
if EN_GEOS_DISK = FALSE
			b $13,$ff,$ff,$07
endif
if EN_GEOS_DISK = TRUE
			b $12,$ff,$fe,$07
endif

			b $13,$ff,$ff,$07,$13,$ff,$ff,$07
			b $13,$ff,$ff,$07,$13,$ff,$ff,$07
			b $13,$ff,$ff,$07,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$12,$ff,$ff,$03
			b $12,$ff,$ff,$03,$11,$ff,$ff,$01
			b $11,$ff,$ff,$01,$11,$ff,$ff,$01
			b $11,$ff,$ff,$01,$11,$ff,$ff,$01
:DRIVE_NAME		b "R","A","M","x","1","5","7","1"
			b $a0,$a0,$a0,$a0,$a0,$a0,$a0,$a0
			b $a0,$a0,"R","D",$a0,"2","A",$a0
			b $a0,$a0,$a0

;--- Ergänzung: 18.09.19/M.Kanet
;Standardmäßig keine GEOS-Diskette erzeugen.
if EN_GEOS_DISK = FALSE
:RDrvBorderTS		b $00,$00			;Kein BorderBlock.
			b $00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00
endif
if EN_GEOS_DISK = TRUE
:RDrvBorderTS		b $13,$08			;BorderBlock.
			b "G","E","O","S"," "
			b "f","o","r","m","a","t"," "
			b "V","1",".","0"
endif

			b $00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$00,$00,$00
			b $00,$00,$00,$00,$00,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$15,$15
			b $15,$15,$15,$15,$15,$15,$00,$13
			b $13,$13,$13,$13,$13,$12,$12,$12
			b $12,$12,$12,$11,$11,$11,$11,$11

:BAM_71b		b $ff,$ff,$1f,$ff,$ff,$1f,$ff,$ff
			b $1f,$ff,$ff,$1f,$ff,$ff,$1f,$ff
			b $ff,$1f,$ff,$ff,$1f,$ff,$ff,$1f
			b $ff,$ff,$1f,$ff,$ff,$1f,$ff,$ff
			b $1f,$ff,$ff,$1f,$ff,$ff,$1f,$ff
			b $ff,$1f,$ff,$ff,$1f,$ff,$ff,$1f
			b $ff,$ff,$1f,$00,$00,$00,$ff,$ff
			b $07,$ff,$ff,$07,$ff,$ff,$07,$ff
			b $ff,$07,$ff,$ff,$07,$ff,$ff,$07
			b $ff,$ff,$03,$ff,$ff,$03,$ff,$ff
			b $03,$ff,$ff,$03,$ff,$ff,$03,$ff
			b $ff,$03,$ff,$ff,$01,$ff,$ff,$01
			b $ff,$ff,$01,$ff,$ff,$01,$ff,$ff
			b $01
