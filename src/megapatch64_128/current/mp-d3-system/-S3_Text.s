; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Text für Copyright-Hinweis.
:LOGO_TEXT		b PLAINTEXT,BOLDON
if Flag64_128 = TRUE_C64
			b GOTOXY
			w (LOGO_2_x *8 +8) ! DOUBLE_W
			b $08
			b "1998-2000:Markus Kanet"
			b GOTOXY
			w (LOGO_2_x *8 +8) ! DOUBLE_W
			b $12
			b "2018-2023:Markus Kanet"
endif
if Flag64_128 = TRUE_C128
			b GOTOXY
			w (LOGO_2_x *8 +8) ! DOUBLE_W
			b $08
			b "1998-2003:Kanet/Grimm"
			b GOTOXY
			w (LOGO_2_x *8 +8) ! DOUBLE_W
			b $12
			b "2018-2023:Markus Kanet"
endif
:Build_ID		b GOTOXY
			w (LOGO_2_x *8 +8) ! DOUBLE_W
			b $1c
			d "obj.BuildID"
			b NULL

;*** Systemtexte.
if Sprache = Deutsch
:NoDrvText		b PLAINTEXT,"Laufwerk ?",NULL
:NoDskText		b PLAINTEXT,"Diskette ?",NULL
:KFreeText		b PLAINTEXT,"Kb frei",NULL
endif
if Sprache = Englisch
:NoDrvText		b PLAINTEXT,"Drive ?",NULL
:NoDskText		b PLAINTEXT,"Disk ?",NULL
:KFreeText		b PLAINTEXT,"Kb free",NULL
endif

:InfoNoREU		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $3a
if Sprache = Deutsch
			b "Keine Speichererweiterung erkannt!"
endif
if Sprache = Englisch
			b "No ram expansion unit detected!"
endif
			b NULL

:InfoText2		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $3a
if Sprache = Deutsch
			b "Freier Speicher auf Ziel-Diskette: "
endif
if Sprache = Englisch
			b "Free space on target-disk: "
endif
			b NULL

:ExtractFName		b PLAINTEXT
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $b6
if Sprache = Deutsch
			b "Entpacke Datei: "
endif
if Sprache = Englisch
			b "Extracting file: "
endif
			b NULL

;*** Texte für Diskettenfehler.
:DskErrCode		b $00
:DskErrInfText		b PLAINTEXT,BOLDON
			b GOTOXY
			w $0050 ! DOUBLE_W
			b $74
if Sprache = Deutsch
			b "Fehler-Code:"
endif
if Sprache = Englisch
			b "Error-code:"
endif
			b NULL

:DskErrTitel		b PLAINTEXT,BOLDON
if Sprache = Deutsch
			b "Installation fehlgeschlagen:"
endif
if Sprache = Englisch
			b "Installation failed:"
endif
			b NULL

:DlgInfoTitel		b PLAINTEXT,BOLDON
			b "Information:"
			b NULL

if Sprache = Deutsch
:DlgT_01_01		b "Unbekannter Fehler!",NULL
:DlgT_02_01		b "Die GEOS-ID konnte nicht",NULL
:DlgT_02_02		b "gespeichert werden!",NULL
:DlgT_03_01		b "Die Datei konnte nicht",NULL
:DlgT_03_02		b "entpackt werden!",NULL
endif
if Flag64_128 ! Sprache = TRUE_C64 ! Deutsch
:DlgT_04_01		b "Die Datei 'SetupMP64d'",NULL
endif
if Flag64_128 ! Sprache = TRUE_C128 ! Deutsch
:DlgT_04_01		b "Die Datei 'SetupMP128d'",NULL
endif
if Sprache = Deutsch
:DlgT_04_02		b "ist fehlerhaft!",NULL
:DlgT_05_01		b "Prüfsummenfehler in",NULL
endif
if Flag64_128 ! Sprache = TRUE_C64 ! Deutsch
:DlgT_05_02		b "Datei 'SetupMP64d'!",NULL
endif
if Flag64_128 ! Sprache = TRUE_C128 ! Deutsch
:DlgT_05_02		b "Datei 'SetupMP128d'!",NULL
endif
if Sprache = Deutsch
:DlgT_06_01		b PLAINTEXT
			b "Disk einlegen mit:"
			b NULL
endif

if Sprache = Englisch
:DlgT_01_01		b "Unknown Diskerror!",NULL
:DlgT_02_01		b "Not able to write GEOS-ID",NULL
:DlgT_02_02		b "to Systemdisk!",NULL
:DlgT_03_01		b "Not able to extract",NULL
:DlgT_03_02		b "this file!",NULL
endif
if Flag64_128 ! Sprache = TRUE_C64 ! Englisch
:DlgT_04_01		b "The file 'SetupMP64e'",NULL
endif
if Flag64_128 ! Sprache = TRUE_C128 ! Englisch
:DlgT_04_01		b "The file 'SetupMP128e'",NULL
endif
if Sprache = Englisch
:DlgT_04_02		b "is partly destroyed!",NULL
:DlgT_05_01		b "Checksum-error in",NULL
endif
if Flag64_128 ! Sprache = TRUE_C64 ! Englisch
:DlgT_05_02		b "file 'SetupMP64e'!",NULL
endif
if Flag64_128 ! Sprache = TRUE_C128 ! Englisch
:DlgT_05_02		b "file 'SetupMP128e'!",NULL
endif
if Sprache = Englisch
:DlgT_06_01		b PLAINTEXT
			b "Insert disk with:"
			b NULL
endif

:InfoText0		b PLAINTEXT
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Bitte haben Sie einen kleinen Augenblick Geduld,"
endif
if Sprache = Englisch
			b "Please be patient while 'SetupMP' examines"
endif
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $68
if Sprache = Deutsch
			b "während 'SetupMP' das Archiv mit den gepackten"
endif
if Sprache = Englisch
			b "the archive including packaged MegaPatch files."
endif
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $70
if Sprache = Deutsch
			b "MegaPatch-Dateien untersucht."
endif
if Sprache = Englisch
			b ""
endif
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $80
if Sprache = Deutsch
			b "Dieser Vorgang kann einige Minuten dauern..."
endif
if Sprache = Englisch
			b "This process can take several minutes..."
endif

:InfoText0a		b GOTOXY
			w $0010 ! DOUBLE_W
			b $9e
if Sprache = Deutsch
			b "* Archiv auf Fehler untersuchen..."
endif
if Sprache = Englisch
			b "* Checking archive for errors..."
endif
			b NULL

:InfoText0b		b GOTOXY
			w $0010 ! DOUBLE_W
			b $a8
if Sprache = Deutsch
			b "* Datei-Informationen einlesen..."
endif
if Sprache = Englisch
			b "* Loading file information..."
endif
			b NULL

:InfoText0c		b GOTOXY
			w $0010 ! DOUBLE_W
			b $94
if Sprache = Deutsch
			b "Installationsdatei: "
endif
if Sprache = Englisch
			b "Installation file: "
endif
			b NULL

:InfoText0d		b GOTOXY
			w $0010 ! DOUBLE_W
			b $94
if Sprache = Deutsch
			b "Eine Setup-Datei wurde nicht gefunden!"
endif
if Sprache = Englisch
			b "Cannot find a required setup file!"
endif
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $9c
if Sprache = Deutsch
			b "Bitte Diskette wechseln bzw. wenden!"
endif
if Sprache = Englisch
			b "Please change or flip diskette!"
endif
			b NULL

;*** Setup starten.
:Icon_Tab0		b $01
			w $0000
			b $00

			w Icon_07
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_07x ! DOUBLE_B
			b Icon_07y
			w SlctTarget

;*** Setup starten.
:Icon_Text0		b PLAINTEXT
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Installationsprogramm für GEOS - MegaPatch"
endif
if Sprache = Englisch
			b "Installation program for GEOS - MegaPatch"
endif
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $70
if Sprache = Deutsch
			b "Das Programm  wird Sie während der Installation"
endif
if Sprache = Englisch
			b "This program  will help you  to install the GEOS-"
endif
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $78
if Sprache = Deutsch
			b "des GEOS-MegaPatch unterstützen."
endif
if Sprache = Englisch
			b "MegaPatch on your computer."
endif
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $88
if Sprache = Deutsch
			b "Mit der Taste '!' kann der Installationsvorgang"
endif
if Sprache = Englisch
			b "If you want to cancel the MegaPatch-installation"
endif
			b GOTOXY
			w $0010 ! DOUBLE_W
			b $90
if Sprache = Deutsch
			b "jederzeit beendet werden."
endif
if Sprache = Englisch
			b "please press the '!'-key."
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Installation"
endif
if Sprache = Englisch
			b "Continue with"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "fortsetzen"
endif
if Sprache = Englisch
			b "installation"
endif
			b NULL

;*** Ziel-Laufwerk wählen.
:Icon_Tab1		b $05
			w $0000
			b $00

			w Icon_08
			b Icon1x ! DOUBLE_B
			b Icon1y
			b Icon_08x ! DOUBLE_B
			b Icon_08y
			w SlctDrvA

			w Icon_08
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_08x ! DOUBLE_B
			b Icon_08y
			w SlctDrvB

			w Icon_08
			b Icon2x ! DOUBLE_B
			b Icon1y
			b Icon_08x ! DOUBLE_B
			b Icon_08y
			w SlctDrvC

			w Icon_08
			b Icon2x ! DOUBLE_B
			b Icon2y
			b Icon_08x ! DOUBLE_B
			b Icon_08y
			w SlctDrvD

			w Icon_14
			b IconX1x ! DOUBLE_B
			b IconX1y
			b Icon_14x ! DOUBLE_B
			b Icon_14y
			w SlctTarget

;*** Ziel-Laufwerk wählen.
:Icon_Text1		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Wählen Sie das Laufwerk, auf das die"
endif
if Sprache = Englisch
			b "Please select the drive to which the"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Systemdateien kopiert werden sollen:"
endif
if Sprache = Englisch
			b "system files should be copied to:"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $6a
if Sprache = Deutsch
			b "Hinweis: Leerdisk empfohlen! Nicht auf"
endif
if Sprache = Englisch
			b "Note: Blank disk recommended! Do not"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $72
if Sprache = Deutsch
			b "eine GEOS V2 Bootdisk installieren!"
endif
if Sprache = Englisch
			b "install on a GEOS V2 bootdisk!"
endif

			b GOTOXY
			w IconT1x  -41 ! DOUBLE_W
			b IconT1ay +3
			b "A:"
			b GOTOXY
			w IconT1x  -41 ! DOUBLE_W
			b IconT2ay +3
			b "B:"
			b GOTOXY
			w IconT2x  -41 ! DOUBLE_W
			b IconT1ay +3
			b "C:"
			b GOTOXY
			w IconT2x  -41 ! DOUBLE_W
			b IconT2ay +3
			b "D:"
			b NULL

;*** Installationsmodus wählen.
:Icon_Tab2		b $02
			w $0000
			b $00

			w Icon_00
			b Icon1x ! DOUBLE_B
			b Icon1y
			b Icon_00x ! DOUBLE_B
			b Icon_00y
			w CopyAllFiles

			w Icon_01
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_01x ! DOUBLE_B
			b Icon_01y
			w CopySlctFiles

;*** Installationsmodus wählen.
:Icon_Text2		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Installationsprogramm für GEOS - MegaPatch"
endif
if Sprache = Englisch
			b "Installation program for GEOS - MegaPatch"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Bitte wählen Sie die Art der Installation:"
endif
if Sprache = Englisch
			b "Please choose the type of installation:"
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT1y
if Sprache = Deutsch
			b "Komplette Installation mit allen Dateien"
endif
if Sprache = Englisch
			b "Complete installation with all files"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT1ay
if Sprache = Deutsch
			b "auf Diskette oder CMD-Partition."
endif
if Sprache = Englisch
			b "on disk or CMD-partition."
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Benutzerdefinierte Installation oder"
endif
if Sprache = Englisch
			b "User defined installation / update an"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "ändern einer Startdiskette."
endif
if Sprache = Englisch
			b "existing system-disk."
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay+9
if Sprache = Deutsch
			b "(Empfohlen für 1541-Startdisketten)"
endif
if Sprache = Englisch
			b "(Recommended for 1541-installation)"
endif
			b NULL

;*** Vorhandene Installation löschen.
:Icon_Tab11		b $03
			w $0000
			b $00

			w Icon_13
			b Icon1x ! DOUBLE_B
			b Icon1y
			b Icon_13x ! DOUBLE_B
			b Icon_13y
			w DeleteSysFiles

			w Icon_07
			b Icon2x ! DOUBLE_B
			b Icon1y
			b Icon_07x ! DOUBLE_B
			b Icon_07y
			w CopyFiles

			w Icon_12
			b Icon2x ! DOUBLE_B
			b Icon2y
			b Icon_12x ! DOUBLE_B
			b Icon_12y
			w ExitToDeskTop

;*** Vorhandene Installation löschen.
:Icon_Text11		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Das Ziel-Laufwerk enthält bereits Dateien"
endif
if Sprache = Englisch
			b "The target drive includes some files of"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "des GEOS-MegaPatch. Sollen die vorhandenen"
endif
if Sprache = Englisch
			b "GEOS-MegaPatch. Should the existing files"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $68
if Sprache = Deutsch
			b "Dateien gelöscht werden ?"
endif
if Sprache = Englisch
			b "be deleted ?"
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT1y
if Sprache = Deutsch
			b "Systemdateien"
endif
if Sprache = Englisch
			b "Delete"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT1ay
if Sprache = Deutsch
			b "löschen"
endif
if Sprache = Englisch
			b "Systemfiles"
endif

			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT1y
if Sprache = Deutsch
			b "Installation"
endif
if Sprache = Englisch
			b "Continue with"
endif
			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT1ay
if Sprache = Deutsch
			b "fortsetzen"
endif
if Sprache = Englisch
			b "installation"
endif

			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Setup"
endif
if Sprache = Englisch
			b "Cancel"
endif
			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "abbrechen"
endif
if Sprache = Englisch
			b "Setup"
endif
			b NULL

;*** Nicht genügend freier Speicher.
:Icon_Tab3		b $02
			w $0000
			b $00

			w Icon_07
			b Icon1x ! DOUBLE_B
			b Icon1y
			b Icon_07x ! DOUBLE_B
			b Icon_07y
			w CopyMenu

			w Icon_09
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_09x ! DOUBLE_B
			b Icon_09y
			w SlctTarget

;*** Nicht genügend freier Speicher.
:Icon_Text3		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Nicht genügend freier Speicher verfügbar"
endif
if Sprache = Englisch
			b "Not enough space available on the"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "um alle Dateien zu entpacken!"
endif
if Sprache = Englisch
			b "selected target drive!"
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT1y
if Sprache = Deutsch
			b "Installation forsetzen und nicht"
endif
if Sprache = Englisch
			b "Continue with installation and copy"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT1ay
if Sprache = Deutsch
			b "alle Dateien kopieren."
endif
if Sprache = Englisch
			b "only selected files."
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Ein anderes Laufwerk für die"
endif
if Sprache = Englisch
			b "Choose another target drive and try"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "Installation wählen."
endif
if Sprache = Englisch
			b "installation again."
endif
			b NULL

;*** Benutzerdefinierte Installation.
:Icon_Tab4		b $06
			w $0000
			b $00

			w Icon_02
			b Icon6x1 ! DOUBLE_B
			b Icon6y1
			b Icon_02x ! DOUBLE_B
			b Icon_02y
			w CopySystem

			w Icon_03
			b Icon6x2 ! DOUBLE_B
			b Icon6y1
			b Icon_03x ! DOUBLE_B
			b Icon_03y
			w CopyRBoot

			w Icon_06
			b Icon6x3 ! DOUBLE_B
			b Icon6y1
			b Icon_06x ! DOUBLE_B
			b Icon_06y
			w CopyDskDvMenu

			w Icon_04
			b Icon6x1 ! DOUBLE_B
			b Icon6y2
			b Icon_04x ! DOUBLE_B
			b Icon_04y
			w CopyBackScrn

			w Icon_05
			b Icon6x2 ! DOUBLE_B
			b Icon6y2
			b Icon_05x ! DOUBLE_B
			b Icon_05y
			w CopyScrSaver

			w Icon_07
			b Icon6x3 ! DOUBLE_B
			b Icon6y2
			b Icon_07x ! DOUBLE_B
			b Icon_07y
			w RunMP3Menu

;*** Benutzerdefinierte Installation.
:Icon_Text4		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Kopieren Sie jetzt die MegaPatch-Dateien."
endif
if Sprache = Englisch
			b "Now you can copy the MegaPatch files."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Ein '*' markiert benötigte Systemdateien."
endif
if Sprache = Englisch
			b "The '*' marks required system files."
endif

			b GOTOXY
			w (IconT6x1+46) ! DOUBLE_W
			b Icon6y1+8
			b "*"
			b GOTOXY
			w IconT6x1 ! DOUBLE_W
			b IconT6y1_1
if Sprache = Deutsch
			b "Startdateien"
endif
if Sprache = Englisch
			b "Start-files"
endif

			b GOTOXY
			w IconT6x2 ! DOUBLE_W
			b IconT6y1_1
if Sprache = Deutsch
			b "ReBoot System"
endif
if Sprache = Englisch
			b "ReBoot system"
endif

			b GOTOXY
			w (IconT6x3+46) ! DOUBLE_W
			b Icon6y1+8
			b "*"
			b GOTOXY
			w IconT6x3 ! DOUBLE_W
			b IconT6y1_1
if Sprache = Deutsch
			b "Laufwerks-"
endif
if Sprache = Englisch
			b "DiskDriver"
endif
			b GOTOXY
			w IconT6x3 ! DOUBLE_W
			b IconT6y1_2
if Sprache = Deutsch
			b "treiber"
endif
if Sprache = Englisch
			b ""
endif

;*** Benutzerdefinierte Installation.
			b GOTOXY
			w IconT6x1 ! DOUBLE_W
			b IconT6y2_1
if Sprache = Deutsch
			b "Hintergrund-"
endif
if Sprache = Englisch
			b "Background-"
endif
			b GOTOXY
			w IconT6x1 ! DOUBLE_W
			b IconT6y2_2
if Sprache = Deutsch
			b "Bilder"
endif
if Sprache = Englisch
			b "Pictures"
endif

			b GOTOXY
			w IconT6x2 ! DOUBLE_W
			b IconT6y2_1
if Sprache = Deutsch
			b "Bildschirm-"
endif
if Sprache = Englisch
			b "ScreenSaver"
endif
			b GOTOXY
			w IconT6x2 ! DOUBLE_W
			b IconT6y2_2
if Sprache = Deutsch
			b "schoner"
endif
if Sprache = Englisch
			b ""
endif

			b GOTOXY
			w IconT6x3 ! DOUBLE_W
			b IconT6y2_1
if Sprache = Deutsch
			b "Installation"
endif
if Sprache = Englisch
			b "Continue with"
endif
			b GOTOXY
			w IconT6x3 ! DOUBLE_W
			b IconT6y2_2
if Sprache = Deutsch
			b "fortsetzen"
endif
if Sprache = Englisch
			b "installation"
endif
			b NULL

;*** Alle Laufwerkstreiber kopieren ?
:Icon_Tab5		b $02
			w $0000
			b $00

			w Icon_00
			b Icon1x ! DOUBLE_B
			b Icon1y
			b Icon_00x ! DOUBLE_B
			b Icon_00y
			w CopyDskDev

			w Icon_01
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_01x ! DOUBLE_B
			b Icon_01y
			w CopySlctDkDv

;*** Alle Laufwerkstreiber kopieren ?
:Icon_Text5		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Bitte wählen Sie den Modus zum Kopieren der"
endif
if Sprache = Englisch
			b "Please choose the copy-mode for the MegaPatch"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "einzelnen Laufwerkstreiber:"
endif
if Sprache = Englisch
			b "disk-driver installation:"
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT1y
if Sprache = Deutsch
			b "Alle Laufwerkstreiber kopieren"
endif
if Sprache = Englisch
			b "Copy all disk-drivers"
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Nur bestimmte Laufwerkstreiber"
endif
if Sprache = Englisch
			b "Copy selected disk-drivers only"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "für die Installation wählen."
endif
if Sprache = Englisch
			b ""
endif
			b NULL

;*** Laufwerkstreiber auswählen.
:Icon_Tab6		b $04
			w $0000
			b $00

			w Icon_10
			b Icon4x1 ! DOUBLE_B
			b Icon4y
			b Icon_10x ! DOUBLE_B
			b Icon_10y
			w NextDkDrv

			w Icon_11
			b Icon4x2 ! DOUBLE_B
			b Icon4y
			b Icon_11x ! DOUBLE_B
			b Icon_11y
			w ReSlctDkDrv

			w Icon_07
			b Icon4x3 ! DOUBLE_B
			b Icon4y
			b Icon_07x ! DOUBLE_B
			b Icon_07y
			w ModifyDriver

			w Icon_12
			b Icon4x4 ! DOUBLE_B
			b Icon4y
			b Icon_12x ! DOUBLE_B
			b Icon_12y
			w ExitToDeskTop

;*** Laufwerkstreiber auswählen.
:Icon_Text6		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Soll der folgende Laufwerkstreiber auf der"
endif
if Sprache = Englisch
			b "Should the following disk-driver be installed"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Startdiskette installiert werden ?"
endif
if Sprache = Englisch
			b "to the system-disk ?"
endif
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $70
if Sprache = Deutsch
			b "Laufwerkstreiber für"
endif
if Sprache = Englisch
			b "Disk-driver for"
endif

			b GOTOXY
			w IconT4x1 ! DOUBLE_W
			b IconT4y1
if Sprache = Deutsch
			b "Kopieren"
endif
if Sprache = Englisch
			b "Copy"
endif

			b GOTOXY
			w IconT4x2 ! DOUBLE_W
			b IconT4y1
if Sprache = Deutsch
			b "Nicht"
endif
if Sprache = Englisch
			b "Do not"
endif
			b GOTOXY
			w IconT4x2 ! DOUBLE_W
			b IconT4y2
if Sprache = Deutsch
			b "Kopieren"
endif
if Sprache = Englisch
			b "Copy"
endif

			b GOTOXY
			w IconT4x3 ! DOUBLE_W
			b IconT4y1
if Sprache = Deutsch
			b "Installation"
endif
if Sprache = Englisch
			b "Continue with"
endif
			b GOTOXY
			w IconT4x3 ! DOUBLE_W
			b IconT4y2
if Sprache = Deutsch
			b "fortsetzen"
endif
if Sprache = Englisch
			b "installation"
endif

			b GOTOXY
			w IconT4x4 ! DOUBLE_W
			b IconT4y1
if Sprache = Deutsch
			b "Setup"
endif
if Sprache = Englisch
			b "Cancel"
endif
			b GOTOXY
			w IconT4x4 ! DOUBLE_W
			b IconT4y2
if Sprache = Deutsch
			b "abbrechen"
endif
if Sprache = Englisch
			b "Setup"
endif
			b NULL

:Icon_Text6a		b PLAINTEXT
if Sprache = Deutsch
			b " - Laufwerk ?"
endif
if Sprache = Englisch
			b " - drive ?"
endif
			b NULL

;*** Startdiskette untersuchen.
:Icon_Tab7		b $02
			w $0000
			b $00

			w Icon_02
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_02x ! DOUBLE_B
			b Icon_02y
			w CheckFiles

			w Icon_12
			b Icon2x ! DOUBLE_B
			b Icon2y
			b Icon_12x ! DOUBLE_B
			b Icon_12y
			w ExitToDeskTop

;*** Startdiskette untersuchen.
:Icon_Text7		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Das kopieren der Systemdateien ist beendet."
endif
if Sprache = Englisch
			b "System files were copied."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $64
if Sprache = Deutsch
			b "Die Startdiskette wird jetzt auf fehlende"
endif
if Sprache = Englisch
			b "The system disk will now be checked for"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $6c
if Sprache = Deutsch
			b "Dateien untersucht."
endif
if Sprache = Englisch
			b "missing files."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $78
if Sprache = Deutsch
			b "Nach der Überprüfung wird MegaPatch installiert"
endif
if Sprache = Englisch
			b "After this is done MegaPatch will be installed"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $80
if Sprache = Deutsch
			b "und die Diskette für den Start konfiguriert."
endif
if Sprache = Englisch
			b "and the disk will be configured for booting."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $8c
if Sprache = Deutsch
			b "Die Installation ist noch nicht beendet!"
endif
if Sprache = Englisch
			b "Installation is not yet completed!"
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Startdiskette"
endif
if Sprache = Englisch
			b "Check"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "überprüfen"
endif
if Sprache = Englisch
			b "system-disk"
endif

			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Setup"
endif
if Sprache = Englisch
			b "Cancel"
endif
			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "abbrechen"
endif
if Sprache = Englisch
			b "Setup"
endif
			b NULL

;*** MegaPatch starten.
:Icon_Tab8		b $02
			w $0000
			b $00

			w Icon_07
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_07x ! DOUBLE_B
			b Icon_07y
			w InstallMP

			w Icon_12
			b Icon2x ! DOUBLE_B
			b Icon2y
			b Icon_12x ! DOUBLE_B
			b Icon_12y
			w ExitToDeskTop

;*** MegaPatch starten.
:Icon_Text8		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Die Diskette wurde überprüft und alle MegaPatch"
endif
if Sprache = Englisch
			b "The system disk was checked and all MegaPatch"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Systemdateien sind vorhanden."
endif
if Sprache = Englisch
			b "system files do exist."
endif

			b GOTOXY
			w $0018 ! DOUBLE_W
			b $74
if Sprache = Deutsch
			b "MegaPatch kann jetzt installiert werden."
endif
if Sprache = Englisch
			b "MegaPatch can now be installed."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $80
if Sprache = Deutsch
			b "Nach Abschluss der Installation bitte noch die"
endif
if Sprache = Englisch
			b "After installation is completed please copy the"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $88
if Flag64_128 ! Sprache = TRUE_C64 ! Deutsch
			b "Datei `DESK TOP` auf die Bootdisk kopieren."
endif
if Flag64_128 ! Sprache = TRUE_C128 ! Deutsch
			b "Datei `128 DESKTOP` auf die Bootdisk kopieren."
endif
if Flag64_128 ! Sprache = TRUE_C64 ! Englisch
			b "file `DESK TOP` to the bootdisk."
endif
if Flag64_128 ! Sprache = TRUE_C128 ! Englisch
			b "file `128 DESKTOP` to the bootdisk."
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Installation"
endif
if Sprache = Englisch
			b "Continue with"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "fortsetzen"
endif
if Sprache = Englisch
			b "installation"
endif
			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Setup"
endif
if Sprache = Englisch
			b "Cancel"
endif
			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "abbrechen"
endif
if Sprache = Englisch
			b "Setup"
endif
			b NULL

;*** MegaPatch starten.
:Icon_Tab8a		b $01
			w $0000
			b $00

			w Icon_12
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_12x ! DOUBLE_B
			b Icon_12y
			w ExitToDeskTop

;*** MegaPatch kann nicht installiert werden.
:Icon_Text8a		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Die ausgewählten MegaPatch-Systemdateien"
endif
if Sprache = Englisch
			b "The selected MegaPatch system files have"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "wurden kopiert."
endif
if Sprache = Englisch
			b "been copied."
endif

			b GOTOXY
			w $0018 ! DOUBLE_W
			b $74
if Sprache = Deutsch
			b "MegaPatch kann nicht installiert werden:"
endif
if Sprache = Englisch
			b "MegaPatch can not be installed:"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $80
if Sprache = Deutsch
			b "Es wurde keine Speichererweiterung erkannt,"
endif
if Sprache = Englisch
			b "No ram expansion unit detected, please"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $88
if Sprache = Deutsch
			b "bitte Kompatibilität von GEOS und REU prüfen!"
endif
if Sprache = Englisch
			b "check compatibility of GEOS and REU!"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Setup"
endif
if Sprache = Englisch
			b "Exit"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "beenden"
endif
if Sprache = Englisch
			b "Setup"
endif
			b NULL

;*** Dateien fehlen, DeskTop starten.
:Icon_Tab9		b $03
			w $0000
			b $00

			w Icon_02
			b Icon3x1 ! DOUBLE_B
			b Icon3y
			b Icon_02x ! DOUBLE_B
			b Icon_02y
			w CopyMenu

			w Icon_07
			b Icon3x2 ! DOUBLE_B
			b Icon3y
			b Icon_07x ! DOUBLE_B
			b Icon_07y
			w InstallMP

			w Icon_12
			b Icon3x3 ! DOUBLE_B
			b Icon3y
			b Icon_12x ! DOUBLE_B
			b Icon_12y
			w ExitToDeskTop

;*** Dateien fehlen, DeskTop starten.
:Icon_Text9		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Es wurden nicht alle Systemdateien auf der"
endif
if Sprache = Englisch
			b "Some system files were missing on the bootdisk."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Startdiskette gefunden. Die fehlenden Dateien"
endif
if Sprache = Englisch
			b "The missing files are optional and are not"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $68
if Sprache = Deutsch
			b "sind aber optional und nicht erforderlich."
endif
if Sprache = Englisch
			b "really required for the bootdisk."
endif

			b GOTOXY
			w $0018 ! DOUBLE_W
			b $74
if Sprache = Deutsch
			b "MegaPatch kann jetzt installiert werden."
endif
if Sprache = Englisch
			b "MegaPatch can now be installed."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $80
if Sprache = Deutsch
			b "Nach Abschluss der Installation bitte noch die"
endif
if Sprache = Englisch
			b "After installation is completed please copy the"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $88
if Flag64_128 ! Sprache = TRUE_C64 ! Deutsch
			b "Datei `DESK TOP` auf die Bootdisk kopieren."
endif
if Flag64_128 ! Sprache = TRUE_C128 ! Deutsch
			b "Datei `128 DESKTOP` auf die Bootdisk kopieren."
endif
if Flag64_128 ! Sprache = TRUE_C64 ! Englisch
			b "file `DESK TOP` to the bootdisk."
endif
if Flag64_128 ! Sprache = TRUE_C128 ! Englisch
			b "file `128 DESKTOP` to the bootdisk."
endif

;*** Dateien fehlen, DeskTop starten.
			b GOTOXY
			w IconT3x1 ! DOUBLE_W
			b IconT3y
if Sprache = Deutsch
			b "Dateien"
endif
if Sprache = Englisch
			b "Add extra"
endif
			b GOTOXY
			w IconT3x1 ! DOUBLE_W
			b IconT3ay
if Sprache = Deutsch
			b "kopieren"
endif
if Sprache = Englisch
			b "files"
endif
			b GOTOXY
			w IconT3x2 ! DOUBLE_W
			b IconT3y
if Sprache = Deutsch
			b "Installation"
endif
if Sprache = Englisch
			b "Continue with"
endif
			b GOTOXY
			w IconT3x2 ! DOUBLE_W
			b IconT3ay
if Sprache = Deutsch
			b "fortsetzen"
endif
if Sprache = Englisch
			b "installation"
endif
			b NULL

;*** Fehlende Dateien kopieren.
:Icon_Tab10		b $02
			w $0000
			b $00

			w Icon_02
			b Icon1x ! DOUBLE_B
			b Icon2y
			b Icon_02x ! DOUBLE_B
			b Icon_02y
			w CopyMenu

			w Icon_12
			b Icon2x ! DOUBLE_B
			b Icon2y
			b Icon_12x ! DOUBLE_B
			b Icon_12y
			w ExitToDeskTop

;*** Fehlende Dateien kopieren.
:Icon_Text10		b PLAINTEXT
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $58
if Sprache = Deutsch
			b "Es wurden nicht alle Systemdateien auf der"
endif
if Sprache = Englisch
			b "The bootdisk is missing some required"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $60
if Sprache = Deutsch
			b "Startdiskette gefunden."
endif
if Sprache = Englisch
			b "system files."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $6c
if Sprache = Deutsch
			b "MegaPatch kann damit nicht gestartet werden."
endif
if Sprache = Englisch
			b "MegaPatch cannot be started from this disk."
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $78
if Sprache = Deutsch
			b "Bitte fehlende Systemdateien ergänzen."
endif
if Sprache = Englisch
			b "Please add the missing system files."
endif

			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Systemdateien"
endif
if Sprache = Englisch
			b "Copy"
endif
			b GOTOXY
			w IconT1x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "kopieren"
endif
if Sprache = Englisch
			b "system files"
endif

			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT2y
if Sprache = Deutsch
			b "Setup"
endif
if Sprache = Englisch
			b "Cancel"
endif
			b GOTOXY
			w IconT2x ! DOUBLE_W
			b IconT2ay
if Sprache = Deutsch
			b "abbrechen"
endif
if Sprache = Englisch
			b "Setup"
endif
			b NULL

;*** Information über Kopierstatus.
:Inf_Wait		b GOTOXY
			w $0018 ! DOUBLE_W
			b $5a
			b PLAINTEXT,OUTLINEON
if Sprache = Deutsch
			b "Bitte warten!"
endif
if Sprache = Englisch
			b "Please wait!"
endif
			b GOTOXY
			w $0018 ! DOUBLE_W
			b $70
			b PLAINTEXT
			b NULL

if Sprache = Deutsch
:Inf_DelSysFiles	b "Systemdateien werden gelöscht...",NULL
:Inf_CopySystem		b "Systemdateien werden kopiert...",NULL
:Inf_CopyRBoot		b "ReBoot-Routine wird kopiert...",NULL
:Inf_CopyBkScr		b "Hintergrundbild wird kopiert...",NULL
:Inf_CopyScrSv		b "Bildschirmschoner werden kopiert...",NULL
:Inf_CopyDskDrv		b "Laufwerkstreiber werden kopiert...",NULL
:Inf_InstallMP		b "Systemdiskette wird untersucht...",NULL
:Inf_ChkDkSpace		b "Zieldiskette wird überprüft...",NULL
endif
if Sprache = Englisch
:Inf_DelSysFiles	b "Deleting Systemfiles...",NULL
:Inf_CopySystem		b "Copying System-files...",NULL
:Inf_CopyRBoot		b "Copying ReBoot-files...",NULL
:Inf_CopyBkScr		b "Copying Background-picture...",NULL
:Inf_CopyScrSv		b "Copying ScreenSaver...",NULL
:Inf_CopyDskDrv		b "Copying DiskDrivers...",NULL
:Inf_InstallMP		b "Checking system disk...",NULL
:Inf_ChkDkSpace		b "Checking target disk...",NULL
endif

:InfoText1		b PLAINTEXT
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $76
if Sprache = Deutsch
			b "Bitte haben Sie einen kleinen Augenblick"
endif
if Sprache = Englisch
			b "Please be patient for a moment, while"
endif
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $80
if Sprache = Deutsch
			b "Geduld, während Setup die Startdiskette"
endif
if Sprache = Englisch
			b "Setup configures the MegaPatch system-disk..."
endif
			b GOTOXY
			w $0020 ! DOUBLE_W
			b $8a
if Sprache = Deutsch
			b "für MegaPatch konfiguriert..."
endif
if Sprache = Englisch
			b ""
endif
			b NULL
