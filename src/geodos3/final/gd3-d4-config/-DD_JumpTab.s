; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Sprungtabelle.
::TestDriveMode		jmp	INIT_DEV_TEST
::InstallDrive		jmp	INIT_DEV_INSTALL
::DeInstallDrive	jmp	INIT_DEV_REMOVE

;*** Sprungtabelle für Sonderfunktionen.
;    Damit andere Programme diese Treiber ebenfalls installieren können,
;    wird die Sprungtabelle nicht an eine feste Adresse gebunden.
;    Stattdessen wird in den Registern ":a0" bis ":a9" eine Vektortabelle
;    angelegt. Diese muß der Anwender vor dem Aufruf der Installations-
;    Routine auf entsprechende Routinen im eigenen Programm richten.
;    Der Installationsroutine darf diese Adressen nicht zerstören!
:a_TestDriveType	jmp	(a0)
:a_TurnOnNewDrive	jmp	(a1)
:a_GetFreeBank		jmp	(a2)
:FindFreeRAM		jmp	(a3)
:a_AllocBank		jmp	(a4)
:AllocRAM		jmp	(a5)
:a_FreeBank		jmp	(a6)
:FreeBankTab		jmp	(a7)
:a_SaveDskDrvData	jmp	(a8)
:a_FindDrive		jmp	(a9)
