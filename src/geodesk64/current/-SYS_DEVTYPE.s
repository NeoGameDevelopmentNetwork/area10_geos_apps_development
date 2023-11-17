; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zeiger auf Laufwerks-Info einlesen.
;    Übergabe: YREG =  Laufwerksadresse.
;    Rückhabe: r0 = Zeiger auf Laufwerkstext.
:doGetDevType		LoadW	r0,infoDrvType

			ldx	#$00			;Laufwerkstyp in Tabelle suchen.
::1			lda	RealDrvType -8,y	;Laufwerkstyp einlesen.
			cmp	codeDrvType,x
			beq	:2
			AddVBW	17,r0
			inx
			cpx	#27			;Alle Laufwerkstypen durchsucht?
			bcc	:1			; => Nein, weiter...

::2			tax				;Kein Laufwerk?
			beq	:4			; => Ja, Ende...
			cmp	#$04			;1541-1581?
			bcs	:4			; => Nein, weiter...

			lda	RealDrvMode -8,y
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:4			; => nein, weiter...

;--- Sonderbehandlung für SD2IEC mit 1541/71/81-Treiber.
			lda	#<infoDrvTypeSD41
			ldy	#>infoDrvTypeSD41
			cpx	#Drv1541
			beq	:3
			lda	#<infoDrvTypeSD71
			ldy	#>infoDrvTypeSD71
			cpx	#Drv1571
			beq	:3
			lda	#<infoDrvTypeSD81
			ldy	#>infoDrvTypeSD81
::3			sta	r0L			;Zeiger auf Laufwerkstext
			sty	r0H			;für SD41/71/81-Laufwerk.
::4			rts

;*** Tabelle mit Laufwerkstypen.
:codeDrvType		b $00,$01,$41,$02,$03,$05
			b $81,$82,$83,$84
			b $c4,$a4,$b4
			b $31,$32,$33,$34
			b $11,$12,$13,$14,$15
			b $21,$22,$23,$24
			b $04

;*** Texte für Laufwerkstypen.
:infoDrvType
if LANG = LANG_DE
			b "Kein Laufwerk"
endif
if LANG = LANG_EN
			b "No drive"
endif
			e infoDrvType + 1*17
			b "C=1541"
			e infoDrvType + 2*17
			b "C=1541 (Cache)"
			e infoDrvType + 3*17
			b "C=1571"
			e infoDrvType + 4*17
			b "C=1581"
			e infoDrvType + 5*17
			b "C=1581/DOS"
			e infoDrvType + 6*17
			b "RAM 1541"
			e infoDrvType + 7*17
			b "RAM 1571"
			e infoDrvType + 8*17
			b "RAM 1581"
			e infoDrvType + 9*17
			b "RAM Native"
			e infoDrvType +10*17
			b "SRAM Native"
			e infoDrvType +11*17
			b "CREU Native"
			e infoDrvType +12*17
			b "GRAM Native"
			e infoDrvType +13*17
			b "CMD RL41"
			e infoDrvType +14*17
			b "CMD RL71"
			e infoDrvType +15*17
			b "CMD RL81"
			e infoDrvType +16*17
			b "CMD RLNative"
			e infoDrvType +17*17
			b "CMD FD41"
			e infoDrvType +18*17
			b "CMD FD71"
			e infoDrvType +19*17
			b "CMD FD81"
			e infoDrvType +20*17
			b "CMD FDNative"
			e infoDrvType +21*17
			b "CMD FDPCDOS"
			e infoDrvType +22*17
			b "CMD HD41"
			e infoDrvType +23*17
			b "CMD HD71"
			e infoDrvType +24*17
			b "CMD HD81"
			e infoDrvType +25*17
			b "CMD HDNative"
			e infoDrvType +26*17
			b "SD2IEC Native"
			e infoDrvType +27*17
if LANG = LANG_DE
			b "Unbekannt ?"
endif
if LANG = LANG_EN
			b "Unknown ?"
endif
			e infoDrvType +28*17

;*** Sondertexte für SD2IEC mit 1541/71/81-Treiber.
:infoDrvTypeSD41	b "SD2IEC 1541"
			e infoDrvTypeSD41 +17
:infoDrvTypeSD71	b "SD2IEC 1571"
			e infoDrvTypeSD71 +17
:infoDrvTypeSD81	b "SD2IEC 1581"
			e infoDrvTypeSD81 +17
