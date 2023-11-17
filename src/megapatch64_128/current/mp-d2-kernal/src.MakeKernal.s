; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			t "G3_SymMacExt"

			n "MP_MakeKernal"
			f APPLICATION
			c "MegaPatch   V3.0"

if Flag64_128 = TRUE_C64
			a "Markus Kanet"
			z $40				;GEOS 64/128 40/80 Zeichen
;			z $80				;Assemblieren unter GEOS128
							;ist damit nicht möglich, da
							;MakeKernal nicht startet!
endif
if Flag64_128 = TRUE_C128
			a "M.Kanet/W.Grimm"
			z $40				;GEOS 64/128 40/80 Zeichen
endif

			o $0400
			p $0400

if Flag64_128 = TRUE_C64
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
:FileName1		b "tmp.G3_Kernal64",NULL
:FileName2		b "obj.G3_Kernal64",NULL
endif

if Flag64_128 = TRUE_C128
;*** Kernal-Datei packen.
;Bank 1
;$9D80 - $9FFF = $0d80 - $0FFF
;$A000 - $BFFF = (entfällt)
;$C000 - $FFFF = $1000 - $4FFF

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
			w	$3000
			w	$1000
			w	$4000

			lda	#< $0d80		;Größe für neue Datei setzen.
			sta	InfoSektor +$47
			lda	#> $0d80
			sta	InfoSektor +$48
			lda	#< $5000
			sta	InfoSektor +$49
			lda	#> $5000
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
:FileName1		b "tmp.Kernal_Bank1",NULL
:FileName2		b "obj.G3_K128_B1",NULL
endif
