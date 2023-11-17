; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Bank-Adressen für TaskManager.
:BankTaskAdr		s 9

;*** Flag für "Bank durch Task belegt".
:BankTaskActive		s 9

;*** Max. verfügbare Tasks.
:MaxTaskInstalled	b MAX_TASK_ACTIV
