; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Sprungtabelle.
:TestDriveMode		jmp	xTestDriveMode
:InstallDrive		jmp	xInstallDrive
:DeInstallDrive		jmp	xDeInstallDrive

;*** Sprungtabelle für Sonderfunktionen.
;    Damit andere Programme diese Treiber ebenfalls installieren können,
;    wird die Sprungtabelle nicht an eine feste Adresse gebunden.
;    Stattdessen wird in den Registern ":a0" bis ":a9" eine Vektortabelle
;    angelegt. Diese muß der Anwender vor dem Aufruf der Installations-
;    Routine auf entsprechende Routinen im eigenen Programm richten.
;    Der Installationsroutine darf diese Adressen nicht zerstören!
:TestDriveType		jmp	(a0)
:TurnOnNewDrive		jmp	(a1)
:GetFreeBank		jmp	(a2)
:GetFreeBankTab		jmp	(a3)
:AllocateBank		jmp	(a4)
:AllocateBankTab	jmp	(a5)
:FreeBank		jmp	(a6)
:FreeBankTab		jmp	(a7)
:SaveDskDrvData		jmp	(a8)
:FindDrive		jmp	(a9)
