; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; Dialogbox: Kein Ultimate erkannt
;
;Hinweis:
;Nur für DeskAccessories!
;Innerhalb eines DeskAccessory muss
;der Inhalt von :dlgBoxRambuf vor dem
;Aufruf einer Dialogbox gerettet und
;danach wieder zurückgesetzt werden!
;
;Übergabe : -
;Rückgabe : -
;Verändert: A,X,Y,r0-r15

:ULIB_ERR_NO_UDEV_DA

			jsr	i_MoveData		;Zwischenspeicher für
			w dlgBoxRamBuf			;Dialogbox und DeskAccessory
			w :tempBuf			;retten.
			w 417

			jsr	ULIB_ERR_NO_UDEV

			jsr	i_MoveData		;Zwischenspeicher für
			w :tempBuf			;Dialogbox und DeskAccessory
			w dlgBoxRamBuf			;zurücksetzen.
			w 417

			rts

::tempBuf		s 417
