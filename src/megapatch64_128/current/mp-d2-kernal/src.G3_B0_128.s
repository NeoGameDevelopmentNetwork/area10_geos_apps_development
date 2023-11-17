; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "src.GEOS_MP3.ext"
			t "SymbTab128"
			t "SymbTab_1"
			t "MacTab_MAIN"
endif

			n "obj.G3_K128_B0"
			f 3
			c "MegaPatch128V3.0"
			a "MegaCom Software"
			o $c000

;******************************************************************************
; Bank 0 Adressen für SoftSpriteHandler
;******************************************************************************

:VDC_mobenble		=	$1300 ; 1 Byte analog zum VIC je ein Bit pro Spr.
:VDClast_moby2		=	$1301 ; 1 Byte letzte moby2 Vergrößerung
:VDClast_mobx2		=	$1302 ; 1 Byte letzte mobx2 Vergrößerung
:VDClast_mobXPos	=	$1303 ; 8 Word letzte X-Position eines Sprites
:VDClast_mobYPos	=	$1313 ; 8 Byte letzte Y-Postion eines Sprites
:VDC_sprPos		=	$131b ; 8 Word Grafikspeicheradresse für Sprites
:VDC_sprLeng		=	$132b ; 8 Byte Breite für jedes Sprite
:VDC_sprHight		=	$1333 ; 8 Byte Höhe für jedes Sprite
:VDC_spr1pic		=	$133b ;39 Byte Speicherbereich für SpriteDaten
:VDC_spr2pic		=	$1461 ;39 Byte Speicherbereich für SpriteDaten
:VDC_spr3pic		=	$1587 ;39 Byte Speicherbereich für SpriteDaten
:VDC_spr4pic		=	$16ad ;39 Byte Speicherbereich für SpriteDaten
:VDC_spr5pic		=	$17d3 ;39 Byte Speicherbereich für SpriteDaten
:VDC_spr6pic		=	$18f9 ;39 Byte Speicherbereich für SpriteDaten
:VDC_spr7pic		=	$1a1f ;39 Byte Speicherbereich für SpriteDaten
:VDCSprDataBuf1		=	$1b45 ; 7 Byte Datenbuffer1 für Spriteberechnung
:VDCSprDataBuf2		=	$1b4c ; 7 Byte Datenbuffer2 für Spriteberechnung
:VDC_SprMoveFlag	=	$1b54 ; 1 Byte Flag
:VDC_BackScrSpr0	=	$1b55 ;24 Byte Hintergrund unter Maus
:VDCmouseData		=	$1b6d ;24 Byte Mausdaten
:VDC_BackScrSpr1	=	$1c2d ;24 Byte Hintergrund unter Sprite
:InvLineBuffer		=	$1ced ;ByteBuffer für InverLine

;******************************************************************************
;*** Speicher $c000 - $dfff
;******************************************************************************
:B0_C000		t "+G3_B0_C000"

;******************************************************************************
;*** Speicher $e000 - $ffff
;******************************************************************************
:B0_E000		t "+G3_B0_E000"
