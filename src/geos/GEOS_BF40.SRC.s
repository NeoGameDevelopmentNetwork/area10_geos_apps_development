; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS_BF40.OBJ"
			f $06
			c "KERNAL_BF40 V1.0"
			a "M. Kanet"
			o $bf40
			p $c22c
			i
<MISSING_IMAGE_DATA>

.OrgMouseData		b $fc,$00,$00,$f8		;Daten für Mauszeiger.
			b $00,$00,$f0,$00
			b $00,$f8,$00,$00
			b $dc,$00,$00,$8e
			b $00,$00,$07,$00
			b $00,$03,$00,$00

.Icon_CANCEL		b $05,$ff,$82,$fe
			b $80,$04,$00,$82
			b $03,$80,$04,$00
			b $b2,$03,$86,$30
			b $c0,$00,$00,$c3
			b $86,$30,$c0,$00
			b $00,$c3,$8f,$3c
			b $f3,$ed,$9c,$f3
			b $8f,$36,$db,$8d
			b $b6,$db,$99,$b6
			b $db,$0d,$b0,$db
			b $9f,$b6,$db,$0d
			b $b0,$db,$99,$b6
			b $db,$0d,$b6,$db
			b $99,$bc,$f3,$07
			b $9c,$db,$80,$04
			b $00,$82,$03,$80
			b $04,$00,$82,$03
			b $80,$04,$00,$81
			b $03,$06,$ff,$81
			b $7f

.Icon_OK		b $05,$ff,$82,$fe
			b $80,$04,$00,$82
			b $03,$80,$04,$00
			b $b8,$03,$80,$00
			b $f8,$c6,$00,$03
			b $80,$01,$8c,$cc
			b $00,$03,$80,$01
			b $8c,$d8,$00,$03
			b $80,$01,$8c,$f0
			b $00,$03,$80,$01
			b $8c,$e0,$00,$03
			b $80,$01,$8c,$f0
			b $00,$03,$80,$01
			b $8c,$d8,$00,$03
			b $80,$01,$8c,$cc
			b $00,$03,$80,$00
			b $f8,$c6,$00,$03
			b $80,$04,$00,$82
			b $03,$80,$04,$00
			b $81,$03,$06,$ff
			b $81,$7f,$05,$ff

			b $7f,$05,$ff			;Füllbytes.
