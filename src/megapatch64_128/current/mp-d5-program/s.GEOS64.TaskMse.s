; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

			n "GEOS64.TaskMse"
			c "TaskManSet V1.0"
			a "M.Kanet/W.Grimm"
			t "G3_SymMacExt"

			f $06
			z $80

			i
<MISSING_IMAGE_DATA>

if Sprache = Deutsch
			h "TaskManager über linke+rechte Maustaste starten"
endif

if Sprache = Englisch
			h "Press left and right mouse-button to start TaskManager"
endif

;*** TaskManager über Maustasten starten.
:PatchTaskMan		lda	#%01111111
			sta	TaskManKey1 +1
			lda	#%11101110
			sta	TaskManKey2 +1
			jmp	EnterDeskTop
