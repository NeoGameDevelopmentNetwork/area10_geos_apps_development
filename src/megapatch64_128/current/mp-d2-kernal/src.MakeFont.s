; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t	"TopSym"
			t	"TopMac"
endif

			n	"MakeFont"
			c	"MakeFont    V1.0",NULL
			a	"Markus Kanet",NULL
			o	$1000
			p	Start

t "-BSWFonts.d"
t "-BSWFonts.e"

:Start			jsr	makeFont9de
			jsr	makeFont9en
			jsr	makeFont128de
			jsr	makeFont128en
			jmp	EnterDeskTop

:makeFontFile		MoveW	HdrB000,r0
			jsr	DeleteFile

			LoadB	r10L,0			;Directoryseite.
			LoadW	r9,HdrB000		;Infoblock.
			jsr	SaveFile
			txa
			bne	:err

			MoveW	HdrB000,r0
			jsr	OpenRecordFile
			txa
			bne	:err

;			lda	#0
::loop			pha
			jsr	AppendRecord
			pla
			adc	#1
			cmp	#126
			bcc	:loop

			jsr	CloseRecordFile
			txa
			bne	:err

			rts

::err			jmp	Panic

:makeFont9de		LoadW	HdrB000,NAME_FONT9d
			LoadW	HdrB097,(BSWd_FontEnd-BSWd_Font)
			LoadW	HdrB128,$0010
			LoadW	HdrB130,$0409 ;%00000010:00-001001
			jsr	makeFontFile

			LoadW	r0,NAME_FONT9d
			jsr	OpenRecordFile
			txa
			bne	:err

			lda	#9
			jsr	PointRecord

			LoadW	r7,BSWd_Font
			LoadW	r2,(BSWd_FontEnd-BSWd_Font)
			jsr	WriteRecord
			txa
			bne	:err

			jsr	CloseRecordFile
			txa
			bne	:err
			rts

::err			jmp	Panic

:makeFont9en		LoadW	HdrB000,NAME_FONT9e
			LoadW	HdrB097,(BSWe_FontEnd-BSWe_Font)
			LoadW	HdrB128,$0011
			LoadW	HdrB130,$0449 ;%00000010:01-001001
			jsr	makeFontFile

			LoadW	r0,NAME_FONT9e
			jsr	OpenRecordFile
			txa
			bne	:err

			lda	#9
			jsr	PointRecord

			LoadW	r7,BSWe_Font
			LoadW	r2,(BSWe_FontEnd-BSWe_Font)
			jsr	WriteRecord
			txa
			bne	:err

			jsr	CloseRecordFile
			txa
			bne	:err
			rts

::err			jmp	Panic

:makeFont128de		LoadW	HdrB000,NAME_FONT128d
			LoadW	HdrB097,(BSW128d_FontEnd-BSW128d_Font)
			LoadW	HdrB128,$0020
			LoadW	HdrB130,$0809 ;%00001000:00-001001
			jsr	makeFontFile

			LoadW	r0,NAME_FONT128d
			jsr	OpenRecordFile
			txa
			bne	:err

			lda	#9
			jsr	PointRecord

			LoadW	r7,BSW128d_Font
			LoadW	r2,(BSW128d_FontEnd-BSW128d_Font)
			jsr	WriteRecord
			txa
			bne	:err

			jsr	CloseRecordFile
			txa
			bne	:err
			rts

::err			jmp	Panic

:makeFont128en		LoadW	HdrB000,NAME_FONT128e
			LoadW	HdrB097,(BSW128e_FontEnd-BSW128e_Font)
			LoadW	HdrB128,$0021
			LoadW	HdrB130,$0849 ;%00001000:01-001001
			jsr	makeFontFile

			LoadW	r0,NAME_FONT128e
			jsr	OpenRecordFile
			txa
			bne	:err

			lda	#9
			jsr	PointRecord

			LoadW	r7,BSW128e_Font
			LoadW	r2,(BSW128e_FontEnd-BSW128e_Font)
			jsr	WriteRecord
			txa
			bne	:err

			jsr	CloseRecordFile
			txa
			bne	:err
			rts

::err			jmp	Panic

;*** Info-Block.
:HdrB000		w NAME_FONT9d
:HdrB002		b $03,$15
			b $bf
			b %11111111,%11111111,%11111111
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00000001
			b %10111111,%10000000,%00000001
			b %10011000,%10000000,%00001001
			b %10011000,%00000000,%00011001
			b %10011110,%00000000,%00111101
			b %10011000,%11100111,%10011001
			b %10011001,%10110110,%11011001
			b %10011001,%10110110,%11011001
			b %10011001,%10110110,%11011001
			b %10111100,%11100110,%11001101
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00000001
			b %10000000,%00000000,%00000001
			b %11111111,%11111111,%11111111

:HdrB068		b $83				;USR.
:HdrB069		b FONT				;GEOS-Systemdatei.
:HdrB070		b VLIR				;GEOS-Dateityp VLIR.
:HdrB071		w $0000,$ffff,$0000		;Programm-Anfang/-Ende/-Start.
:HdrB077		b "GeoFont     "		;Klasse
:HdrB089		b " 2.0"			;Version
:HdrB093		b NULL
:HdrB094		s 3				;Reserviert
:HdrB097		w $0000				;12 Words für Datensatzlänge
			s 22
:HdrB121		s 7				;Reserviert
:HdrB128		w $0000				;Font-ID 0-1023
;$0009 %00000000:00-001001 = BSW9
;$0809 %00001000:00-001001 = BSW128
:HdrB130		w $0000				;12 Words / 1 je Punktgröße
			s 22
:HdrB154		s 6				;Reserviert
:HdrB160		b "GEOS BSW-Font",NULL
:HdrEnd			s (HdrB000+256)-HdrEnd

:ND_Record		b $00
:ND_Class		= HdrB077

:NAME_FONT9d		b "fnt.BSW9.de",NULL
:NAME_FONT128d		b "fnt.BSW128.de",NULL
:NAME_FONT9e		b "fnt.BSW9.en",NULL
:NAME_FONT128e		b "fnt.BSW128.en",NULL
