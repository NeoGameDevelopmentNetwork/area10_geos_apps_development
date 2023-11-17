; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
			t "G3_SymMacExt"

;*** GEOS-Header.
			n "obj.EnterDeskTop"
			t "G3_Data.V.Class"

			o LD_ADDR_ENTER_DT

;--- Hinweis:
;GD.CONFIG erstellt eine Prüfsumme um
;zu testen ob die Standard-Routine zum
;laden desk DeskTops verwendet wird.
;CRC = $B831, Länge $C4=196 Bytes.

;*** DeskTop laden.
:EnterDTsys		sei				;IRQ sperren.
			cld				;"DEZIMAL"-Flag löschen.
			ldx	#$ff			;Wert für "GEOS-Bootvorgang ist
			stx	firstBoot		;aktiv!" setzen.
			txs				;Stackzeiger löschen.

			jsr	GEOS_InitSystem		;GEOS-Variablen zurücksetzen.
			jsr	ResetScreen		;GEOS-Bildschirm löschen.

;*** DeskTop suchen.
:DT_Search		jsr	DT_Find_SYSTEM		;System-DeskTop suchen.
			jsr	DT_Find_GDESK		;"GeoDesk64" suchen.
			jsr	DT_Find_DUALT		;"DUAL_TOP" suchen.
			jsr	DT_Find_TOPDT		;"TOP DESK" suchen.
			jsr	DT_Find_DESKT		;"DESK TOP" suchen.

;*** DeskTop-Diskette einlegen.
:DT_NotFound		lda	#>DlgBoxDTdisk		;Dialogbox öffnen.
			sta	r0H			;"Bitte Diskette mit DeskTop
			lda	#<DlgBoxDTdisk		; einlegen..."
			sta	r0L
			jsr	DoDlgBox
			jmp	DT_Search

;*** Bestimmte DeskTop-Datei suchen.
:DT_Find_SYSTEM		lda	#<DeskTopName		;System-DeskTop-Datei.
			ldx	#>DeskTopName		;Wird in der Kernal-Datei
			bne	DT_FindByName		;definiert.
:DT_Find_GDESK		lda	#<otherGDESK		;"GeoDesk64".
			ldx	#>otherGDESK
			bne	DT_FindByName
:DT_Find_DUALT		lda	#<otherDUALT		;"DUAL_TOP".
			ldx	#>otherDUALT
			bne	DT_FindByName
:DT_Find_TOPDT		lda	#<otherTOPDT		;"TOP DESK".
			ldx	#>otherTOPDT
			bne	DT_FindByName
:DT_Find_DESKT		lda	#<otherDESKT		;"DESK TOP".
			ldx	#>otherDESKT
;			bne	DT_FindByName

:DT_FindByName		sta	vecNameDT +0
			stx	vecNameDT +1

			lda	#%10000000		;DeskTop auf RAM-
			jsr	DT_Find			;Laufwerken suchen...
			lda	#%00000000		;DeskTop auf Nicht-RAM-
;			jsr	DT_Find			;Laufwerken suchen...

;*** DeskTop-Datei suchen.
:DT_Find		sta	:52 +1			;Laufwerkstyp merken.

			ldx	#8
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
			cpx	#12			;Alle Laufwerke getestet ?
			bne	:51			;Nein, weiter...
:ErrLdDeskTop		rts

;*** Neue DeskTop-Diskette öffnen.
:IsDTonDisk		jsr	SetDevice		;Laufwerk aktivieren.
			jsr	OpenDisk		;Diskette öffnen.
			txa				;Diskettenfehler ?
			bne	ErrLdDeskTop		;Nein, weiter...

			sta	r0L
			MoveW	vecNameDT,r6		;Zeiger auf Dateiname.
			jsr	GetFile			;DeskTop-Datei laden.
			txa				;Diskettenfehler ?
			bne	ErrLdDeskTop		;Ja, Abbruch...

			sta	r0L
			lda	fileHeader+$4c		;Zeiger auf Startadresse
			sta	r7H			;DeskTop-Programm im Speicher.
			lda	fileHeader+$4b
			sta	r7L
			jmp	StartAppl

;*** Zeiger auf DeskTop-Name.
:vecNameDT		w $0000

;*** Alternative DeskTop-Dateien.
:otherGDESK		b "GeoDesk64",NULL
:otherDUALT		b "DUAL_TOP",NULL
:otherTOPDT		b "TOP DESK",NULL
:otherDESKT		b "DESK TOP",NULL

;******************************************************************************
;*** Endadresse testen.
;******************************************************************************
			g LD_ADDR_ENTER_DT + R2_SIZE_ENTER_DT -1
;******************************************************************************
