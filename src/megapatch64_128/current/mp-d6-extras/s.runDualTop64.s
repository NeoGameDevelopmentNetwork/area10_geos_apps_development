; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			t "G3_SymMacExt"

			n "runDualTop64"
			f AUTO_EXEC
			a "Markus Kanet"
			c "runDualTop  V1.0"
			z $80
			i
<MISSING_IMAGE_DATA>
if Sprache = Deutsch
			h "* DualTop64 als DeskTop..."
			h "Für MegaPatch64/Deutsch"
endif
if Sprache = Englisch
			h "* Use DualTop64 as DeskTop..."
			h "For MegaPatch64/English"
endif

;*** DeskTop-Name und Systemmeldung patchen.
:MainInit		jsr	i_MoveData
			w	xDeskTopName
			w	DeskTopName
			w	DeskTopNameEnd-DeskTopName

			jsr	i_MoveData
			w	xDlgBoxDTopMsg1
			w	DlgBoxDTopMsg1
			w	DlgBoxDTopMsg1End-DlgBoxDTopMsg1
			jsr	i_MoveData
			w	xDlgBoxDTopMsg2
			w	DlgBoxDTopMsg2
			w	DlgBoxDTopMsg2End-DlgBoxDTopMsg2

			jmp	EnterDeskTop

;*** Neuer DeskTop-Name.
:xDeskTopName		b "DUAL_TOP"

;Speicher bis zur max. Länge mit NULL-Bytes auffüllen.
			e xDeskTopName+(DeskTopNameEnd-DeskTopName)

;*** Neue Systemmeldung.
if Sprache = Deutsch
:xDlgBoxDTopMsg1	b $18 ;BOLDON
			b "Bitte eine Diskette einlegen"

;Speicher bis zur max. Länge mit NULL-Bytes auffüllen.
			e xDlgBoxDTopMsg1+(DlgBoxDTopMsg1End-DlgBoxDTopMsg1)

:xDlgBoxDTopMsg2	b "die DUAL_TOP enthält!"

;Speicher bis zur max. Länge mit NULL-Bytes auffüllen.
			e xDlgBoxDTopMsg2+(DlgBoxDTopMsg2End-DlgBoxDTopMsg2)
endif

if Sprache = Englisch
:xDlgBoxDTopMsg1	b $18 ;BOLDON
			b "Please insert a disk"

;Speicher bis zur max. Länge mit NULL-Bytes auffüllen.
			e xDlgBoxDTopMsg1+(DlgBoxDTopMsg1End-DlgBoxDTopMsg1)

:xDlgBoxDTopMsg2	b "with DUAL_TOP!"

;Speicher bis zur max. Länge mit NULL-Bytes auffüllen.
			e xDlgBoxDTopMsg2+(DlgBoxDTopMsg2End-DlgBoxDTopMsg2)
endif
