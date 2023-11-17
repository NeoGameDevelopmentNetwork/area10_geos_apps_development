; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Speichererweiterung suchen.
:FindActiveDACC		php
			sei				;I/O-Bereich aktivieren.

if Flag64_128 = TRUE_C64
			lda	CPU_DATA
			pha
			lda	#$37			;I/O-Bereich und Kernal für
			sta	CPU_DATA		;RAMLink-Transfer aktivieren.
endif
if Flag64_128 = TRUE_C128
			lda	MMU			;MMU-Register sichern.
			pha
			lda	#$4e			;Ram1 bis $bfff + IO + Kernal
			sta	MMU			;I/O-Bereich und Kernal für
							;RAMLink-Transfer aktivieren.
			lda	RAM_Conf_Reg		;Konfigurationsregister sichern.
			pha
			and	#%11110000
			ora	#%00000100		;Common Area $0000 bis $0400
			sta	RAM_Conf_Reg
endif

;--- Ergänzung: 27.09.19/M.Kanet
;Zuerst auf GeoRAM testen. Falls vorhanden wird GRAM_BANK_SIZE
;ermittelt und gespeichert.
;Wird zuerst auf eine andere Speichererweiterung getestet, dann wird
;GRAM_BANK_SIZE nicht ermittelt und dem Laufwerkstreiber fehlt
;später dann die Bank-Größe bei der Installation von und auf
;ein GeoRAM-Native-Laufwerk -> Absturz.
			jsr	FindActiveBBG		;BBGRAM testen.
			txa				;GEOS-DACC in BBGRAM ?
			beq	:51			; => Ja, weiter...
			jsr	FindActiveREU		;REU testen.
			txa				;GEOS-DACC in REU ?
			beq	:51			; => Ja, weiter...
			jsr	FindActiveRL		;RAMLink testen.
			txa				;GEOS-DACC in RAMLink ?
			beq	:51			; => Ja, weiter...
			jsr	FindActiveSCPU		;RAMCard testen.
			txa				;GEOS-DACC in RAMCard ?
			beq	:51			; => Ja, weiter...

			ldx	#DEV_NOT_FOUND		;Keine Speichererweiterung
							;erkennt, Fehler ausgeben.
			b $2c
::51			ldx	#NO_ERROR

if Flag64_128 = TRUE_C64
			pla
			sta	CPU_DATA
endif
if Flag64_128 = TRUE_C128
			pla
			sta	RAM_Conf_Reg
			pla
			sta	MMU
endif
			plp

			txa
			bne	:53

			lda	ExtRAM_Size		;Größe des aktuellen DACC
			beq	:54			;einlesen. Weniger als 192K ?
			cmp	#$03
			bcc	:52			; => Ja, Abbruch...
			jmp	PrintActiveDACC

::52			LoadW	r0,Dlg_SmallRam		;Fehler: "DACC-RAM zu klein!".
			jmp	Col1IconDlgBox

::53			LoadW	r0,Dlg_NoRamActiv	;Fehler: "Kein RAM aktiv!".
			jmp	Col1IconDlgBox

::54			LoadW	r0,Dlg_NoRam		;Fehler: "Kein DACC-RAM!".
			jmp	Col1IconDlgBox

;*** Aktive SuperCPU erkennen.
:FindActiveSCPU		jsr	DetectSCPU		;RAMCard testen.
			txa				;RAMCard installiert ?
			bne	:52			; => Nein, Abbruch...

			ldx	#$02			;Zeiger auf erste 64K-Bank in
::51			stx	r3H			;RAMCard setzen.

			jsr	TestCurBankSCPU		;Alle Speicherbänke in RAMCard nach
			txa
			beq	:53			;aktuellem GEOS-DACC untersuchen.

			ldx	r3H			;Zeiger auf nächste Speicherbank.
			inx
			cpx	#$f6			;Alle Speicherbänke durchsucht ?
			bcc	:51			; => Nein, weiter...
::52			ldx	#DEV_NOT_FOUND
			rts				;Nicht gefunden, kein SCPU-DACC.

;--- DACC in RAMCard.
::53			lda	ramExpSize		;SCPU-DACC gefunden.
			cmp	#RAM_MAX_SIZE		;Mehr RAM als erforderlich ?
			bcc	:54			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;RAM begrenzen.
::54			sta	ExtRAM_Size

			lda	#$00
			sta	ExtRAM_Bank  +0
			lda	r3H
			sta	ExtRAM_Bank  +1

			lda	#RAM_SCPU
			sta	ExtRAM_Type

			sta	$d07e

			lda	ExtRAM_Bank  +1		;SuperCPU-Variablen aktualisieren.
			clc				;Neues Ende des belegten RAMs nur
			adc	ExtRAM_Size		;dann setzen, wenn Ende unterhalb
			cmp	$d27d			;GEOS-DACC liegt.
			bcc	:55

			ldx	ExtRAM_Bank  +0
			stx	$d27c
			sta	$d27d

::55			sta	$d07f

			ldx	#NO_ERROR
			ldy	#$00			;Zeiger auf Texttabelle.
			rts

;*** Testcode in 64K-Speicherbank suchen.
:TestCurBankSCPU	LoadW	r0,RAM_TEST_CODE	;Register r0/r1 speichern.
			LoadW	r1,$0000
			LoadW	r2,$0010

			lda	#$ff
			sta	r3L

			lda	r3H			;Speicherbank berechnen.
			sta	:52 +3

			clc
			b $fb				;xce
			b $c2,$10			;rep #$00010000

			b $a0,$00,$00			;ldy #$0000
::51			b $a6,$02			;ldx r0
			b $bf,$00,$00,$00		;lda $00:0000,x
			b $e8				;inx
			b $86,$02			;stx r0
			b $a6,$04			;ldx r1
::52			b $df,$00,$00,$00		;cmp $??:0000,x
			b $d0,$0a			;bne :53
			b $e8				;inx
			b $86,$04			;stx r1

			b $c8				;iny
			b $c4,$06			;cpy r2
			b $d0,$e7			;bne :51
			b $e6,$08			;inc r3L

::53			b $38				;sec
			b $fb				;xce

			ldx	r3L
			rts

;*** Aktive RAMLink erkennen.
:FindActiveRL		jsr	DetectRLNK		;RAMLink testen.
			txa				;RAMLink installiert ?
			bne	:54			; => Nein, Abbruch...

			lda	#$01			;Zeiger auf erste Partition.
			sta	r3H

::51
if Flag64_128 = TRUE_C128
			LoadB	r15L,%001001110		;MMU-Wert für RAMLink-Transfer.
endif
			jsr	GetRLPartEntry		;Partitionsdaten einlesen.

			lda	dirEntryBuf
			cmp	#$07			;DACC-Partition ?
			bne	:53			; => Nein, weiter...

			jsr	TestCurBankRL		;GEOS-DACC in RAMLink ?
			txa
			beq	:55			; => Ja, DACC gefunden...

::53			inc	r3H			;Zeiger auf nächste Partition.
			CmpBI	r3H,32			;Alle Partitionen durchsucht ?
			bcc	:51			; => Nein, weiter...

::54			ldx	#DEV_NOT_FOUND		;DACC nicht in RAMLink.
			rts

;--- DACC in RAMLink.
::55			lda	ramExpSize		;RAMLink-DACC gefunden.
			cmp	#RAM_MAX_SIZE		;Mehr RAM als erforderlich ?
			bcc	:56			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;RAM begrenzen.
::56			sta	ExtRAM_Size

			lda	dirEntryBuf +21
			sta	ExtRAM_Bank  +0
			lda	dirEntryBuf +20
			sta	ExtRAM_Bank  +1

			lda	r3H
			sta	ExtRAM_Part

			lda	#RAM_RL
			sta	ExtRAM_Type

			ldx	#NO_ERROR
			ldy	#$02			;Zeiger auf Texttabelle.
			rts

;*** Testcode in 64K-Speicherbank suchen.
:TestCurBankRL		jsr	$e0a9			;RL-Hardware aktivieren.

			lda	#< RAM_TEST_CODE
			sta	EXP_BASE2 + 2
			lda	#> RAM_TEST_CODE
			sta	EXP_BASE2 + 3

			lda	#$00
			sta	EXP_BASE2 + 4
			lda	dirEntryBuf +21
			sta	EXP_BASE2 + 5
			lda	dirEntryBuf +20
			sta	EXP_BASE2 + 6

			lda	#< $0010
			sta	EXP_BASE2 + 7
			lda	#> $0010
			sta	EXP_BASE2 + 8

			lda	#$00
			sta	EXP_BASE2 + 9
			sta	EXP_BASE2 +10

			lda	#$93
			sta	EXP_BASE2 + 1

			jsr	$fe06			;Job ausführen und

			lda	EXP_BASE2 + 0
			pha
			jsr	$fe0f			;RL-Hardware abschalten.
			pla
			and	#%00100000
			tax
			rts

;*** Aktive C=REU erkennen.
:FindActiveREU		jsr	DetectCREU		;REU testen.
			txa				;REU installiert ?
			bne	:51			; => Nein, Abbruch...

			jsr	TestCurBankREU		;GEOS-DACC in REU ?
			txa
			beq	:52			; => Ja, Ende...

::51			ldx	#DEV_NOT_FOUND		;DACC nicht in REU.
			rts

;--- DACC in REU.
::52			lda	ramExpSize		;REU-DACC gefunden.
			cmp	#RAM_MAX_SIZE		;Mehr RAM als erforderlich ?
			bcc	:53			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;RAM begrenzen.
::53			sta	ExtRAM_Size

			lda	#$00
			sta	ExtRAM_Bank  +0
			sta	ExtRAM_Bank  +1

			lda	#RAM_REU
			sta	ExtRAM_Type

			ldx	#NO_ERROR
			ldy	#$04			;Zeiger auf Texttabelle.
			rts

;*** Testcode in 64K-Speicherbank suchen.
:TestCurBankREU
if Flag64_128 = TRUE_C128
			lda	CLKRATE			;Auf 1MHz umschalten,
			pha				;sonst geht nichts!
			lda	#$00
			sta	CLKRATE
endif

			lda	#< RAM_TEST_CODE
			sta	EXP_BASE1 + 2
			lda	#> RAM_TEST_CODE
			sta	EXP_BASE1 + 3

			lda	#$00
			sta	EXP_BASE1 + 4
			sta	EXP_BASE1 + 5
			sta	EXP_BASE1 + 6

			lda	#< $0010
			sta	EXP_BASE1 + 7
			lda	#> $0010
			sta	EXP_BASE1 + 8

			lda	#$00
			sta	EXP_BASE1 + 9
			sta	EXP_BASE1 +10

			lda	#%10010011
			sta	EXP_BASE1 + 1
::51			lda	EXP_BASE1 + 0
			and	#%01100000
			beq	:51
			and	#%00100000
			tax

if Flag64_128 = TRUE_C128
			pla
			sta	CLKRATE
endif

			rts

;*** Definierenn der GeoRAM-Register.
:GRAM_PAGE_DATA		= $de00
:GRAM_PAGE_SLCT		= $dffe
:GRAM_BANK_SLCT		= $dfff

:GRAM_BSIZE_0K		= 0
:GRAM_BSIZE_16K		= 16
:GRAM_BSIZE_32K		= 32
:GRAM_BSIZE_64K		= 64

;*** Aktive GEORAM/BBGRAM erkennen.
:FindActiveBBG		jsr	DetectGRAM
			txa
			bne	:51

;--- Ergänzung: 23.09.18/M.Kanet
;Bank-Größe muss in jedem Fall ermittelt werden!
;Wird GEOS.MP3 von einem GeoRAM-Native-Laufwerk gestartet, der GEOS-DACC
;liegt aber in einem anderen RAM-Typ dann wird GRAM_BANK_SIZE für den
;Laufwerkstreiber nicht gesetzt!!!
			jsr	GRamGetBankSize		;Bank-Größe ermitteln.
			txa				;Fehler?
			bne	:51			; => Ja, Ende...

			jsr	TestCurBankBBG		;GEOS-DACC in BBGRAM ?
			txa
			beq	:52			; => Ja, Ende...

::51			ldx	#DEV_NOT_FOUND		;DACC nicht in BBGRAM.
			rts

;--- DACC in BBGRAM.
::52			lda	ramExpSize		;BBGRAM-DACC gefunden.
			cmp	#RAM_MAX_SIZE		;Mehr RAM als erforderlich ?
			bcc	:53			; => Nein, weiter...
			lda	#RAM_MAX_SIZE		;RAM begrenzen.
::53			sta	ExtRAM_Size

			lda	#$00
			sta	ExtRAM_Bank  +0
			sta	ExtRAM_Bank  +1

			lda	#RAM_BBG
			sta	ExtRAM_Type

			ldx	#NO_ERROR
			ldy	#$06			;Zeiger auf Texttabelle.
			rts

;*** Testcode in 64K-Speicherbank suchen.
:TestCurBankBBG		lda	#$00
			sta	$dffe
			sta	$dfff

			ldx	#$0f
::51			lda	RAM_TEST_CODE,x
			cmp	$de00        ,x
			bne	:52
			dex
			bpl	:51

			ldx	#NO_ERROR
			b $2c
::52			ldx	#DEV_NOT_FOUND
			rts

;*** Variablen für Speichererkennung.
:RAM_TEST_BUF		s $10
:RAM_TEST_CODE		b "MP3 RAM-TEST 3.0"

;*** Dialogbox: Keine Speichererweiterung.
:Dlg_NoRam		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Information
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$36
			w :103
			b DBTXTSTR ,$0c,$40
			w :104
			b OK       ,$02!DOUBLE_B,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_CancelUpdate
			b NULL

if Sprache = Deutsch
::101			b "Das aktive GEOS-System unterstützt keine",NULL
::102			b "Speichererweiterung. Installation nicht möglich!",NULL
::103			b "GEOS neu starten, den erweiterten Speicher",NULL
::104			b "aktivieren und die Installation wiederholen.",NULL
endif

if Sprache = Englisch
::101			b "The current GEOS-system did not support",NULL
::102			b "extended memory! Installation not possible!",NULL
::103			b "Restart GEOS, install extended memory and",NULL
::104			b "try installation again!",NULL
endif

;*** Dialogbox: Speichererweiterung zu klein.
:Dlg_SmallRam		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Information
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$36
			w :103
			b DBTXTSTR ,$0c,$40
			w :104
			b DBTXTSTR ,$0c,$4a
			w :105
			b OK       ,$02!DOUBLE_B,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_CancelUpdate
			b NULL

if Sprache = Deutsch
::101			b "Der erweiterte Speicher für GEOS ist kleiner als",NULL
::102			b "192Kb. Installation nicht möglich!",NULL
::103			b "Eine andere Speichererweiterung verwenden oder",NULL
::104			b "die Größe des erweiterten Speichers ändern und",NULL
::105			b "Installation wiederholen!",NULL
endif

if Sprache = Englisch
::101			b "Extended memory is smaller than 192Kb.",NULL
::102			b "Installation of GEOS-MegaPatch not possible!",NULL
::103			b "Please use an other ram-expansion or change",NULL
::104			b "size of extended memory for GEOS and retry",NULL
::105			b "MegaPatch-installation!",NULL
endif

;*** Dialogbox: Keine Speichererweiterung.
:Dlg_NoRamActiv		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Information
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$36
			w :103
			b DBTXTSTR ,$0c,$40
			w :104
			b OK       ,$02!DOUBLE_B,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_CancelUpdate
			b NULL

if Sprache = Deutsch
::101			b "Die aktive Speichererweiterung wurde nicht",NULL
::102			b "erkannt. Installation fehlgeschlagen!",NULL
::103			b "Zur MegaPatch-Installation nur CMD RAMCard,",NULL
::104			b "RAMLink, C=REU oder BBGRAM verwenden.",NULL
endif

if Sprache = Englisch
::101			b "The current ram-expansion could not be",NULL
::102			b "identified. Installation has been failed!",NULL
::103			b "Please use RAMCard, RAMLink, C=REU or a",NULL
::104			b "BBGRAM to install the GEOS-MegaPatch!",NULL
endif
