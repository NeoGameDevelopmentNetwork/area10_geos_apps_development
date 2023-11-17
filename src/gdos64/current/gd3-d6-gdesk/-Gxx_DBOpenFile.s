; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Datei auswählen.
;Übergabe  : r7L  = Datei-Typ.
;            r10  = Datei-Klasse.
;Rückgabe  : ":dataFileName" = Name der usgewählten Datei.
;            xReg = $00, Datei wurde ausgewählt.
:DBoxOpenFile		lda	#< :Dlg_SlctFile
			sta	r0L
			lda	#> :Dlg_SlctFile
			sta	r0H

			lda	#< dataFileName
			sta	r5L
			lda	#> dataFileName
			sta	r5H

			lda	#255
			sta	r7H

			lda	r7L			;GEOS-Dateityp zwischenspeichern.
			pha

			lda	r10L			;GEOS-Klasse zwischenspeichern.
			pha
			lda	r10H
			pha

			jsr	DoDlgBox		;Datei auswählen.

			pla				;GEOS-Klasse zurücksetzen.
			sta	r10H
			pla
			sta	r10L

			pla				;GEOS-Dateityp zurücksetzen.
			sta	r7L

			lda	sysDBData		;Laufwerk wechseln ?
			bpl	:icon			; => Nein, weiter...

			and	#%00001111
			jsr	SetDevice		;Neues Laufwerk aktivieren.

			jmp	DBoxOpenFile		; => Ja, gültiges Laufwerk suchen.

::icon			cmp	#DISK			;Partition wechseln ?
			beq	DBoxOpenFile		; => Ja, weiter...

			ldx	#$ff
			cmp	#CANCEL			;Abbruch gewählt ?
			beq	:exit			; => Ja, Abbruch...
			inx
::exit			rts

::Dlg_SlctFile		b %10000001

			b DBGETFILES!DBSETDRVICON ,$00,$00

			b DISK                    ,$00,$00

			b CANCEL                  ,$00,$00
			b OK                      ,$00,$00

			b NULL
