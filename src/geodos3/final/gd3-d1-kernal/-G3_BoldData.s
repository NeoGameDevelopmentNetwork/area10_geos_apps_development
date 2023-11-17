; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Tabelle zum berechnen der Daten für Buchstaben in Fettschrift!
;    Jedes Byte in PLAINTEXT wird durch ein Byte in BOLD ersetzt. Dabei
;    dient das PLAINTEXT-Byte als Zeiger auf die BoldData-Tabelle.
;    Bsp: %00010000 wird zu %00011000
:BoldData		b $00,$01,$03,$03,$06,$07,$07,$07
			b $0c,$0d,$0f,$0f,$0e,$0f,$0f,$0f
			b $18,$19,$1b,$1b,$1e,$1f,$1f,$1f
			b $1c,$1d,$1f,$1f,$1e,$1f,$1f,$1f
			b $30,$31,$33,$33,$36,$37,$37,$37
			b $3c,$3d,$3f,$3f,$3e,$3f,$3f,$3f
			b $38,$39,$3b,$3b,$3e,$3f,$3f,$3f
			b $3c,$3d,$3f,$3f,$3e,$3f,$3f,$3f
			b $60,$61,$63,$63,$66,$67,$67,$67
			b $6c,$6d,$6f,$6f,$6e,$6f,$6f,$6f
			b $78,$79,$7b,$7b,$7e,$7f,$7f,$7f
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $70,$71,$73,$73,$76,$77,$77,$77
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $78,$79,$7b,$7b,$7e,$7f,$7f,$7f
			b $7c,$7d,$7f,$7f,$7e,$7f,$7f,$7f
			b $c0,$c1,$c3,$c3,$c6,$c7,$c7,$c7
			b $cc,$cd,$cf,$cf,$ce,$cf,$cf,$cf
			b $d8,$d9,$db,$db,$de,$df,$df,$df
			b $dc,$dd,$df,$df,$de,$df,$df,$df
			b $f0,$f1,$f3,$f3,$f6,$f7,$f7,$f7
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $e0,$e1,$e3,$e3,$e6,$e7,$e7,$e7
			b $ec,$ed,$ef,$ef,$ee,$ef,$ef,$ef
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f0,$f1,$f3,$f3,$f6,$f7,$f7,$f7
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
			b $f8,$f9,$fb,$fb,$fe,$ff,$ff,$ff
			b $fc,$fd,$ff,$ff,$fe,$ff,$ff,$ff
