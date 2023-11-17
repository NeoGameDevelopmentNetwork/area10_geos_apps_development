; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Hinweis:
;":GEOS_ID" muss am Anfang der
;Quelltext-Datei stehen, da andere
;Dateien vor dem Include-Befehl "t"
;ein externes Label ergänzen!

;*** Seriennummer des GEOS-Systems.
;Wird nur dann benötigt wenn eine
;bootfähige GD3-Version erstellt
;werden soll.
;
;Wird GD3 über das Update installiert,
;dann muß die ID nicht geändert werden.
;Die GEOS-ID gehört zu "s.GD3_KERNAL".
;
::GEOS_ID		w $0c64  ;Neue Standard-ID.
;			w $962b  ;Markus Kanet
