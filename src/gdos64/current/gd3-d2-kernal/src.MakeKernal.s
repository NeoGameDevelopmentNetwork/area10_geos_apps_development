; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Symboltabellen.
if .p
			t "SymbTab_1"
			t "SymbTab_GDOS"
			t "SymbTab_GTYP"
			t "MacTab"
endif

;*** GEOS-Header.
			n "MakeKernal"
			c "GDOS_pack   V3.0"
			t "opt.Author"
			f APPLICATION
			z $40 ;GEOS64 oder GEOS128 40/80 Zeichen

			o $0400
			p $0400

;*** Kernal-Datei packen.
;$9D80 - $9FFF = $0D80 - $0FFF
;$A000 - $BF3F = (entfällt)
;$BF40 - $FE7F = $1000 - $4F3F

:MainInit		LoadW	r6,FileName1		;Datei suchen.
			jsr	FindFile
			txa				;Gefunden ?
			beq	PackFile		;Ja, weiter...
:ExitPacker		jmp	EnterDeskTop

:PackFile		lda	dirEntryBuf +1		;Datei einlesen.
			sta	r1L
			lda	dirEntryBuf +2
			sta	r1H
			LoadW	r7,$0d80
			LoadW	r2,$7000
			jsr	ReadFile

			lda	dirEntryBuf +19		;Infoblock einlesen.
			sta	r1L
			lda	dirEntryBuf +20
			sta	r1H
			LoadW	r4,InfoSektor
			jsr	GetBlock

			LoadW	r0,FileName1		;Quell-Datei löschen.
			jsr	DeleteFile
			LoadW	r0,FileName2		;Ziel-Datei löschen.
			jsr	DeleteFile

			jsr	i_MoveData		;Datei packen.
			w	$2f40
			w	$1000
			w	$40c0

			lda	#< $0d80		;Größe für neue Datei setzen.
			sta	InfoSektor +$47
			lda	#> $0d80
			sta	InfoSektor +$48
			lda	#< $50c0
			sta	InfoSektor +$49
			lda	#> $50c0
			sta	InfoSektor +$4a

			lda	#< FileName2		;Zeiger auf Dateiname.
			sta	InfoSektor +$00
			lda	#> FileName2
			sta	InfoSektor +$01

			LoadW	r9  ,InfoSektor		;Neue Datei speichern.
			LoadB	r10L,$00
			jsr	SaveFile
			jmp	ExitPacker		;Ende...

;*** Variablen.
:InfoSektor		s 256
:FileName1		b "tmp.GD_Kernal64",NULL
:FileName2		b "obj.GD_Kernal64",NULL
