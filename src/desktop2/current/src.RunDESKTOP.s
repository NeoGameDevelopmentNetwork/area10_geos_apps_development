; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

if .p
			t "TopSym"
;			t "TopMac"
			t "lang.DESKTOP.ext"
endif

			n "RunDESKTOP"
			c "runDESKTOP  V1.0"
			a "Markus Kanet"
			o APP_RAM
			z $00
			f APPLICATION

			i
<MISSING_IMAGE_DATA>

if LANG = LANG_DE
			h "Startet Systemdatei"
			h " => 'DESK TOP'..."
endif
if LANG = LANG_EN
			h "Run system file"
			h " => 'DESK TOP'..."
endif

;*** Hauptprogramm.
:MainInit		lda	curDrive
			cmp	#8
			beq	:ok
			cmp	#9
			bne	:exit

::ok			lda	#< nameDESKTOP
			sta	r6L
			lda	#> nameDESKTOP
			sta	r6H

			lda	#< classDESKTOP
			sta	r10L
			lda	#> classDESKTOP
			sta	r10H

			lda	#SYSTEM
			sta	r7L
			lda	#1
			sta	r7H
			jsr	FindFTypes
			txa
			bne	:exit

			lda	r7H
			bne	:exit

			lda	#< nameDESKTOP
			sta	r6L
			lda	#> nameDESKTOP
			sta	r6H
			jsr	FindFile
			txa
			bne	:exit

;			lda	#%00000000
			sta	r0L

			lda	#< dirEntryBuf
			sta	r9L
			lda	#> dirEntryBuf
			sta	r9H

			lda	#> EnterDeskTop -1
			pha
			lda	#< EnterDeskTop -1
			pha

			jmp	LdApplic

::exit			jmp	EnterDeskTop

;*** Variablen.
:nameDESKTOP		s 17

if LANG = LANG_DE
:classDESKTOP		b "deskTopDE   V2",NULL
endif
if LANG = LANG_EN
:classDESKTOP		b "deskTopEN   V2",NULL
endif
