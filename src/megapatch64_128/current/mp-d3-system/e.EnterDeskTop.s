; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "obj.EnterDeskTop"
			t "G3_SymMacExt"

if Flag64_128 = TRUE_C64
			t "G3_V.Cl.64.Data"
endif
if Flag64_128 = TRUE_C128
			t "G3_V.Cl.128.Data"
endif

			o LD_ADDR_ENTER_DT

;*** DeskTop laden.
:EnterDTsys		sei				;IRQ sperren.
			cld				;"DEZIMAL"-Flag löschen.
			ldx	#$ff			;Wert für "GEOS-Bootvorgang ist
			stx	firstBoot		;aktiv!" setzen.
			txs				;Stackzeiger löschen.

			jsr	GEOS_InitSystem		;GEOS-Variablen zurücksetzen.
			jsr	ResetScreen		;GEOS-Bildschirm löschen.

;*** DeskTop suchen.
:DT_Search		lda	#%10000000		;DeskTop auf RAM-
			jsr	DT_Find			;Laufwerken suchen...
			lda	#%00000000		;DeskTop auf Nicht-RAM-
			jsr	DT_Find			;Laufwerken suchen...

;*** DeskTop-Diskette einlegen.
:DT_NotFound		lda	#>DlgBoxDTdisk		;Dialogbox öffnen.
			sta	r0H			;"Bitte Diskette mit DeskTop
			lda	#<DlgBoxDTdisk		; einlegen..."
			sta	r0L
			jsr	DoDlgBox
			jmp	DT_Search

;*** DeskTop-Datei suchen.
:DT_Find		sta	:52 +1			;Laufwerkstyp merken.

			ldx	#$08
::51			stx	:53 +1			;Zeiger auf Laufwerk speichern.
			lda	driveType -8,x		;Laufwerk verfügbar ?
			beq	:53			;Nein, weiter...
			and	#%10000000
::52			cmp	#$ff			;Laufwerkstyp korrekt ?
			bne	:53			;Nein, weiter...
			txa
			jsr	IsDTonDisk		;DeskTop auf Diskette ?
							;Rückkehr nur, wenn DeskTop
							;nicht gefunden wurde.
::53			ldx	#$ff
			inx
			cpx	#$0c			;Alle Laufwerke getestet ?
			bne	:51			;Nein, weiter...
:ErrLdDeskTop		rts

;*** Neue DeskTop-Diskette öffnen.
:IsDTonDisk		jsr	SetDevice		;Laufwerk aktivieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	ErrLdDeskTop		;Nein, weiter...

			sta	r0L
			lda	#>DeskTopName		;Zeiger auf Dateiname.
			sta	r6H
			lda	#<DeskTopName
			sta	r6L
			jsr	GetFile			;DeskTop-Datei laden.
			txa				;Diskettenfehler ?
			bne	ErrLdDeskTop		;Ja, Abbruch...

			sta	r0L
			lda	fileHeader+$4c		;Zeiger auf Startadresse
			sta	r7H			;DeskTop-Programm im Speicher.
			lda	fileHeader+$4b
			sta	r7L
			jmp	StartAppl

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_ENTER_DT + R2_SIZE_ENTER_DT -1
;******************************************************************************
