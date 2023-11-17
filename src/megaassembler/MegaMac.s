; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Makrodefinitionen
; Revision 28.06.89

; *************************************
; *                                   *
; *  LoadB  Adresse, Wert             *
; *                                   *
; *  legt Byte-Wert in Adresse ab     *
; *                                   *
; *************************************

:LoadB			m
			lda	#§1
			sta	§0
			/

; *************************************
; *                                   *
; *  LoadW  Adresse, Wert             *
; *                                   *
; *  legt Word-Wert in Adresse ab     *
; *                                   *
; *************************************

:LoadW			m
			lda	#<§1
			sta	§0
			lda	#>§1
			sta	§0+1
			/

; *************************************
; *                                   *
; *  MoveB  QuellAdresse, Zieladresse *
; *                                   *
; *  Kopiert BYTEwert in Quelladresse *
; *  nach Zieladresse                 *
; *                                   *
; *  Quelle --> Ziel                  *
; *                                   *
; *************************************

:MoveB			m
			lda	§0
			sta	§1
			/

; *************************************
; *                                   *
; *  MoveW  QuellAdresse, Zieladresse *
; *                                   *
; *  Kopiert WORDwert in Quelladresse *
; *  nach Zieladresse                 *
; *                                   *
; *  Quelle --> Ziel                  *
; *                                   *
; *************************************

:MoveW			m
			lda	§0
			sta	§1
			lda	§0+1
			sta	§1+1
			/

; *************************************
; *                                   *
; *  add  Wert                        *
; *                                   *
; *  addiert BYTEWert zum Akku        *
; *                                   *
; *************************************

:add			m
			clc
			adc	#§0
			/

; *************************************
; *                                   *
; *  adda  Adresse                    *
; *                                   *
; *  addiert Inhalt einer Adresse     *
; *  zum Akku                         *
; *                                   *
; *************************************

:adda			m
			clc
			adc	§0
			/

; *************************************
; *                                   *
; *  AddB  Adresse1, Adresse2         *
; *                                   *
; *  addiert Inhalt von Adresse1      *
; *  zum Inhalt von Adresse2          *
; *                                   *
; *  Wert2 = Wert1 + Wert2            *
; *                                   *
; *************************************

:AddB			m
			clc
			lda	§0
			adc	§1
			sta	§1
			/

; *************************************
; *                                   *
; *  AddW  Adresse1, Adresse2         *
; *                                   *
; *  addiert WORDInhalt von           *
; *  Adresse1 und Adresse1+1          *
; *  zum WORDInhalt von               *
; *  Adresse2 und Adresse2+1          *
; *                                   *
; *  Wert2 = Wert1 + Wert2            *
; *                                   *
; *************************************

:AddW			m
			lda	§0
			clc
			adc	§1
			sta	§1
			lda	§0+1
			adc	§1+1
			sta	§1+1
			/

; *************************************
; *                                   *
; *  AddVB  Wert, Adresse             *
; *                                   *
; *  addiert BYTEWert zum             *
; *  Inhalt von Adresse               *
; *                                   *
; *************************************

:AddVB			m
			lda	§1
			clc
			adc	#§0
			sta	§1
			/

; *************************************
; *                                   *
; *  AddVW  Wert, Adresse             *
; *                                   *
; *  addiert WORDWert zum             *
; *  WORDInhalt von                   *
; *  Adresse und Adresse +1           *
; *                                   *
; *************************************

:AddVW			m
			lda	#<§0
			clc
			adc	§1
			sta	§1
			lda	#>§0
			adc	§1+1
			sta	§1+1
			/

; *************************************
; *                                   *
; *  sub  Wert                         *
; *                                   *
; *  subtrahiert BYTEWert vom Akku    *
; *                                   *
; *************************************

:sub			m
			sec
			sbc	#§0
			/

; *************************************
; *                                   *
; *  suba  Adresse                     *
; *                                   *
; *  subtrahiert Inhalt einer Adresse *
; *  vom Akku                         *
; *                                   *
; *************************************

:suba			m
			sec
			sbc	§0
			/

; *************************************
; *                                   *
; *  SubB  Adresse1, Adresse2         *
; *                                   *
; *  subtrahiert Inhalt von Adresse2  *
; *  vom Inhalt von Adresse1          *
; *                                   *
; *  Wert2 = Wert2 - Wert1            *
; *                                   *
; *************************************

:SubB			m
			sec
			lda	§1
			sbc	§0
			sta	§1
			/

; *************************************
; *                                   *
; *  SubW  Adresse1, Adresse2         *
; *                                   *
; *  subtrahiert WORDInhalt           *
; *  von Adresse2 und Adresse2+1      *
; *  vom WORDInhalt                   *
; *  von Adresse1 und Adresse1+1      *
; *                                   *
; *  Wert2 = Wert2 - Wert1            *
; *                                   *
; *************************************

:SubW			m
			lda	§1
			sec
			sbc	§0
			sta	§1
			lda	§1+1
			sbc	§0+1
			sta	§1+1
			/

; *************************************
; *                                   *
; *  SubVB  Wert, Adresse             *
; *                                   *
; *  subtrahiert BYTEWert             *
; *  vom Inhalt von Adresse           *
; *                                   *
; *************************************

:SubVB			m
			sec
			lda	§1
			sbc	#§0
			sta	§1
			/

; *************************************
; *                                   *
; *  SubVW  Wert, Adresse             *
; *                                   *
; *  subtrahiert WORDIWert            *
; *  von Adresse1 und Adresse1+1      *
; *                                   *
; *************************************

:SubVW			m
			lda	§1
			sec
			sbc	#<§0
			sta	§1
			lda	§1+1
			sbc	#>§0
			sta	§1+1
			/

; *************************************
; *                                   *
; *  CmpB  Adresse1, Adresse2         *
; *                                   *
; *  vergleicht Inhalt von Adresse1   *
; *  mit Inhalt von Adresse2          *
; *                                   *
; *************************************

:CmpB			m
			lda	§0
			cmp	§1
			/

; *************************************
; *                                   *
; *  CmpBI  Adresse, Wert             *
; *                                   *
; *  vergleicht Inhalt von Adresse    *
; *  mit Wert                         *
; *                                   *
; *************************************

:CmpBI			m
			lda	§0
			cmp	#§1
			/

; *************************************
; *                                   *
; *  CmpW  Adresse1, Adresse2          *
; *                                   *
; *  vergleicht WORDInhalt            *
; *  von Adresse1 und Adresse1+1      *
; *  mit WORDInhalt                   *
; *  von Adresse2 und Adresse2+1      *
; *                                   *
; *************************************

:CmpW			m
			lda	§0+1
			cmp	§1+1
			bne	:ende
			lda	§0
			cmp	§1
::ende
			/

; *************************************
; *                                   *
; *  CmpWI  Adresse, WORD             *
; *                                   *
; *  vergleicht WORDInhalt            *
; *  von Adresse und Adresse+1        *
; *  mit WORDWert                     *
; *                                   *
; *************************************

:CmpWI			m
			lda	§0+1
			cmp	#>§1
			bne	:ende1
			lda	§0
			cmp	#<§1
::ende1
			/

; *************************************
; *                                   *
; *  PushB  Adresse                   *
; *                                   *
; *  legt Inhalt von Adresse          *
; *  auf den Stack                    *
; *                                   *
; *************************************

:PushB			m
			lda	§0
			pha
			/

; *************************************
; *                                   *
; *  PushW  Adresse                   *
; *                                   *
; *  legt Inhalt von Adresse und      *
; *  Adresse+1 auf den Stack          *
; *                                   *
; *************************************

:PushW			m
			lda	§0+1
			pha
			lda	§0
			pha
			/

; *************************************
; *                                   *
; *  PopB  Adresse                    *
; *                                   *
; *  holt BYTEWert vom Stack zurück   *
; *  und legt den Wert in Adresse ab  *
; *                                   *
; *************************************

:PopB			m
			pla
			sta	§0
			/

; *************************************
; *                                   *
; *  PopW  Adresse                    *
; *                                   *
; *  holt WORDWert vom Stack zurück   *
; *  und legt die Werte in Adresse    *
; *  und Adresse+1 ab                 *
; *                                   *
; *************************************

:PopW			m
			pla
			sta	§0
			pla
			sta	§0+1
			/

; *************************************
; *                                   *
; *  bra  Adresse                     *
; *                                   *
; *  branch always                    *
; *                                   *
; *  verzweige immer zu Adresse       *
; *                                   *
; *************************************

:bra			m
			clv
			bvc	§0
			/

; *************************************
; *                                   *
; *  bge  Adresse                     *
; *                                   *
; *  branch if greater or equal       *
; *                                   *
; *  verzweige, wenn                  *
; *  größer oder gleich               *
; *                                   *
; *************************************

:bge			m
			bcs	§0
			/

; *************************************
; *                                   *
; *  bgt  Adresse                     *
; *                                   *
; *  branch if greater than           *
; *                                   *
; *  verzweige,wenn größer            *
; *                                   *
; *************************************

:bgt			m
			beq	:done
			bcs	§0
::done
			/

; *************************************
; *                                   *
; *  blt  Adresse                     *
; *                                   *
; *  branch if less than              *
; *                                   *
; *  verzweige, wenn kleiner          *
; *                                   *
; *************************************

:blt			m
			bcc	§0
			/

; *************************************
; *                                   *
; *  ble  Adresse                     *
; *                                   *
; *  branch if less or equal          *
; *                                   *
; *  verzweige, wenn                  *
; *  kleiner oder gleich              *
; *                                   *
; *************************************

:ble			m
			beq	§0
			bcc	§0
			/

; *************************************
; *                                   *
; *  sbn  BITNummer                   *
; *                                   *
; *  setze Bit Nummer                 *
; *                                   *
; *  gültig sind nur                  *
; *  Bitwerte von 0 bis 7             *
; *                                   *
; *************************************

:sbn			m
			ora	#2^§0
			/

; *************************************
; *                                   *
; *  sbBn  Adresse, BITNummer         *
; *                                   *
; *  setze Bit Nummer in Adresse      *
; *                                   *
; *  gültig sind nur                  *
; *  Bitwerte von 0 bis 7             *
; *                                   *
; *************************************

:sbBn			m
			lda	§0
			ora	#2^§1
			sta	§0
			/

; *************************************
; *                                   *
; *  sbWn  Adresse, BITNummer         *
; *                                   *
; *  setze Bit Nummer in Adresse      *
; *  bzw. Adresse+1                   *
; *                                   *
; *  gültig sind nur                  *
; *  Bitwerte von 0 bis 15            *
; *                                   *
; *************************************

:sbWn			m
			lda	§0
			ora	#<2^§1
			sta	§0
			lda	§0+1
			ora	#>2^§1
			sta	§0+1
			/

; *************************************
; *                                   *
; *  cbn  BITNummer                   *
; *                                   *
; *  lösche Bit Nummer                *
; *                                   *
; *  gültig sind nur                  *
; *  Bitwerte von 0 bis 7             *
; *                                   *
; *************************************

:cbn			m
			and	#$ff-2^§0
			/

; *************************************
; *                                   *
; *  cbBn  Adresse, BITNummer         *
; *                                   *
; *  lösche Bit Nummer in Adresse     *
; *                                   *
; *  gültig sind nur                  *
; *  Bitwerte von 0 bis 7             *
; *                                   *
; *************************************

:cbBn			m
			lda	§0
			and	#$ff-2^§1
			sta	§0
			/

; *************************************
; *                                   *
; *  cbWn  Adresse, BITNummer         *
; *                                   *
; *  lösche Bit Nummer in Adresse     *
; *  bzw. Adresse+1                   *
; *                                   *
; *  gültig sind nur                  *
; *  Bitwerte von 0 bis 15            *
; *                                   *
; *************************************

:cbWn			m
			lda	§0
			and	#<$ffff-2^§1
			sta	§0
			lda	§0+1
			and	#>$ffff-2^§1
			sta	§0+1
			/

; *************************************
; *                                   *
; *  roln  Anzahl                     *
; *                                   *
; *  rotiert Akku Anzahl-mal links    *
; *  unter Beachtung des              *
; *  Carry-Flags                      *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 8             *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:roln			m
			ldx	#§0
			beq	:done
::10			rol
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  rolBn  Adresse, Anzahl           *
; *                                   *
; *  rotiert Inhalt von Adresse       *
; *  Anzahl-mal links                 *
; *  unter Beachtung des              *
; *  Carry-Flags                      *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 8             *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:rolBn			m
			ldx	#§1
			beq	:done
::10			rol	§0
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  rolWn  Adresse, Anzahl           *
; *                                   *
; *  rotiert Inhalt von Adresse       *
; *  und Adresse+1                    *
; *  Anzahl-mal links                 *
; *  unter Beachtung des              *
; *  Carry-Flags                      *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 16            *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:rolWn			m
			ldx	#§1
			beq	:done
::10			rol	§0
			rol	§0+1
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  rorn  Anzahl                     *
; *                                   *
; *  rotiert Akku Anzahl-mal rechts   *
; *  unter Beachtung des              *
; *  Carry-Flags                      *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 8             *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:rorn			m
			ldx	#§0
			beq	:done
::10			ror
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  rorBn  Adresse, Anzahl           *
; *                                   *
; *  rotiert Inhalt von Adresse       *
; *  Anzahl-mal rechts                *
; *  unter Beachtung des              *
; *  Carry-Flags                      *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 8             *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:rorBn			m
			ldx	#§1
			beq	:done
::10			ror	§0
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  rorWn  Adresse, Anzahl           *
; *                                   *
; *  rotiert Inhalt von Adresse       *
; *  und Adresse+1                    *
; *  Anzahl-mal rechts                *
; *  unter Beachtung des              *
; *  Carry-Flags                      *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 16            *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:rorWn			m
			ldx	#§1
			beq	:done
::10			ror	§0+1
			ror	§0
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  asln  Anzahl                     *
; *                                   *
; *  verschiebt Akku Anzahl-mal       *
; *  links, entspricht der            *
; *  Multiplikation *2^n              *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 8             *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:asln			m
			ldx	#§0
			beq	:done
::10			asl
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  aslBn  Adresse, Anzahl           *
; *                                   *
; *  verschiebt Inhalt von Adresse    *
; *  Anzahl-mal links, entspricht der *
; *  Multiplikation *2^n              *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 8             *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:aslBn			m
			ldx	#§1
			beq	:done
::10			asl	§0
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  aslWn  Adresse, Anzahl           *
; *                                   *
; *  verschiebt Inhalt von Adresse    *
; *  und Adresse+1                    *
; *  Anzahl-mal links, entspricht der *
; *  Multiplikation *2^n              *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 16            *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:aslWn			m
			ldx	#§1
			beq	:done
::10			asl	§0
			rol	§0+1
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  lsrn  Anzahl                     *
; *                                   *
; *  verschiebt Akku Anzahl-mal       *
; *  rechts, entspricht der           *
; *  Division /2^n                    *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 8             *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:lsrn			m
			ldx	#§0
			beq	:done
::10			lsr
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  lsrBn  Adresse, Anzahl           *
; *                                   *
; *  verschiebt Inhalt von Adresse    *
; *  Anzahl-mal rechts, entspricht    *
; *  der Division /2^n                *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 8             *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:lsrBn			m
			ldx	#§1
			beq	:done
::10			lsr	§0
			dex
			bne	:10
::done
			/

; *************************************
; *                                   *
; *  lsrWn  Adresse, Anzahl           *
; *                                   *
; *  verschiebt Inhalt von Adresse    *
; *  und Adresse+1                    *
; *  Anzahl-mal rechts, entspricht    *
; *  der Division /2^n                *
; *                                   *
; *  sinnvoll sind nur                *
; *  Bitwerte von 0 bis 16            *
; *  x-Register wird verändert !      *
; *                                   *
; *************************************

:lsrWn			m
			ldx	#§1
			beq	:done
::10			lsr	§0+1
			ror	§0
			dex
			bne	:10
::done
			/
