; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Zeiger auf Textausgabe-Strings.
:StrgVecTab1		w BootText00			;$00
			w BootText00a			;$01
			w BootText01			;$02
			w BootText02			;$03
			w BootText10			;$04
			w BootText11			;$05
			w BootText12			;$06
			w BootText13			;$07
			w BootText14			;$08
			w BootText15			;$09
			w BootText16			;$0a
			w BootText18			;$0b
			w BootText19			;$0c
			w BootText20			;$0d
			w BootText21			;$0e
			w BootText22			;$0f
			w BootText30			;$10
			w BootText31			;$11
			w BootText40			;$12
			w BootText41			;$13
			w BootText50			;$14
			w BootText51			;$15
			w BootText52			;$16
			w BootText53			;$17
			w BootText54			;$18
			w BootText60			;$19
			w BootText61			;$1a
;			w BootText62			;HD-Kabel nicht beim Systemstart.
			w BootText70			;$1b
			w BootText80			;$1c
			w BootText90			;$1d
			w BootText99			;$1e

;*** Texte für Start-Sequenz.
if LANG = LANG_DE
:BootText01		b       " OK",CR,NULL
:BootText02		b       " N.V.",CR,NULL

:BootText10		b       "AUSWAHL DES ERWEITERTEN SPEICHERS:"
			b CR,   "HINWEIS: JEDE SPEICHERERWEITERUNG WIRD"
			b CR,   "         NUR BIS 4096KB UNTERSTUETZT!",CR,NULL
:BootText14		b       "  (1) GEORAM/BBGRAM",NULL
:BootText13		b       "  (2) C=/CMD REU",NULL
:BootText12		b       "  (3) CMD RAMLINK",NULL
:BootText11		b       "  (4) CMD RAMCARD",NULL
:BootText15		b CR,   "IHRE WAHL...................... ?",NULL
:BootText16		b CR,CR,"GDOS-DACC WIRD INSTALLIERT IN",CR,NULL
:BootText18		b       " ERWEITERTER SPEICHER",CR,NULL
:BootText19		b CR,CR,"WAHL DER RAMLINK-DACC-PARTITION"
			b CR,   "('SPACE' = WECHSELN, 'RETURN' = OK)",CR,NULL

:BootText20		b CR,CR,"GDOS KANN OHNE RAM NICHT GESTARTET"
			b CR,   "WERDEN. START ABGEBROCHEN...",CR,NULL
:BootText21		b CR,   "INSTALLATIONS-AUTOMATIK AKTIV!"
			b CR,CR,"UM EINE NEUE SPEICHERERWEITERUNG ZU"
			b CR,   "AKTIVIEREN, STARTEN SIE GDOS MIT DER"
			b CR,   "DATEI 'GD.RESET'",NULL
:BootText22		b CR,CR,"DAS SYSTEM WIRD JETZT GELADEN:",CR,NULL

:BootText30		b CR,   "STARTLAUFWERK INITIALISIEREN",NULL
:BootText31		b CR,   "RAMLINK  : PARTITION #",NULL

:BootText40		b CR,CR,"GEOS-KERNAL LADEN.............:",NULL
:BootText50		b       "GEOS-KERNAL INSTALLIEREN......:",NULL

:BootText41		b CR,   "GDOS-KERNAL LADEN.............:",NULL
:BootText51		b       "GDOS-KERNAL INSTALLIEREN......:",NULL
:BootText52		b       "GDOS-REBOOT INSTALLIEREN......:",NULL

:BootText53		b CR,   "LAUFWERKSTREIBER LADEN........:",NULL
:BootText54		b       "LAUFWERKSTREIBER INSTALLIEREN.:",NULL

:BootText60		b CR,   "SPEICHER-MANAGEMENT STARTEN...:",NULL
:BootText61		b       "SUPERCPU-MANAGEMENT STARTEN...:",NULL
;:BootText62		b       "CMD-HD-KABEL ABSCHALTEN.......:",NULL

:BootText70		b CR,   "GDOS-KERNAL STARTEN...",NULL
:BootText80		b       " ERROR"
			b CR,CR,"KERNEL KONNTE NICHT IN DER SPEICHER-"
			b CR,   "ERWEITERUNG INSTALLIERT WERDEN!"
			b CR,CR,"SPEICHERERWEITERUNG FEHLERHAFT!",CR,NULL
:BootText90		b       "ERWEITERTEN SPEICHER TESTEN...:",NULL
:BootText99		b       " ERROR"
			b CR,CR,"GDOS KONNTE NICHT GELADEN WERDEN:"
			b CR,   "FEHLER BEIM LADEN VON DATEIEN!",CR,NULL
endif

;*** Texte für Start-Sequenz.
if LANG = LANG_EN
:BootText01		b       " OK",CR,NULL
:BootText02		b       " N.A.",CR,NULL

:BootText10		b       "SELECT EXTENDED MEMORY:"
			b CR,   "NOTE: RAM-EXPANSIONS WILL BE SUPPORTED"
			b CR,   "      TO A MAXIMUM SIZE OF 4096KB!",CR,NULL
:BootText14		b       "  (1) GEORAM/BBGRAM",NULL
:BootText13		b       "  (2) C=/CMD REU",NULL
:BootText12		b       "  (3) CMD RAMLINK",NULL
:BootText11		b       "  (4) CMD RAMCARD",NULL
:BootText15		b CR,   "YOUR CHOICE.................... ?",NULL
:BootText16		b CR,CR,"GDOS-DACC WILL BE INSTALLED IN",CR,NULL
:BootText18		b       " EXTENDED MEMORY",CR,NULL
:BootText19		b CR,CR,"SELECT RAMLINK-DACC-PARTITION"
			b CR,   "('SPACE' = CHANGE, 'RETURN' = OK)",CR,NULL

:BootText20		b CR,CR,"BOOTING GDOS WITHOUT RAM IS NOT"
			b CR,   "POSSIBLE. START CANCELLED...",CR,NULL
:BootText21		b CR,   "AUTO-INSTALLATION ACTIV!"
			b CR,CR,"TO SELECT A NEW RAM-EXPANSION PLEASE"
			b CR,   "BOOT GDOS WITH FILE 'GD.RESET'",NULL
:BootText22		b CR,CR,"THE SYSTEM WILL NOW BE LOADED:",CR,NULL

:BootText30		b CR,   "INITIALIZING BOOT-DEVICE",NULL
:BootText31		b CR,   "RAMLINK  : PARTITION #",NULL

:BootText40		b CR,CR,"LOAD    GEOS-KERNAL...........:",NULL
:BootText50		b       "INSTALL GEOS-KERNAL...........:",NULL

:BootText41		b CR,   "LOAD    GDOS-KERNAL...........:",NULL
:BootText51		b       "INSTALL GDOS-KERNAL...........:",NULL
:BootText52		b       "INSTALL GDOS-REBOOT...........:",NULL

:BootText53		b CR,   "LOAD    DISK DRIVER...........:",NULL
:BootText54		b       "INSTALL DISK DRIVER...........:",NULL

:BootText60		b CR,   "INSTALL MEMORY-MANAGER........:",NULL
:BootText61		b       "INSTALL SUPERCPU-MANAGER......:",NULL
;:BootText62		b       "DEACTIVATE CMD-HD-CABEL.......:",NULL

:BootText70		b CR,   "STARTING GDOS...",NULL
:BootText80		b       " ERROR"
			b CR,CR,"UNABLE TO INSTALL THE KERNAL"
			b CR,   "IN THE RAM-EXPANSION-UNIT!"
			b CR,CR,"RAM-EXPANSION MIGHT BE CORRUPT!",CR,NULL
:BootText90		b       "TESTING EXPANDED MEMORY.......:",NULL
:BootText99		b       " ERROR"
			b CR,CR,"UNABLE TO LOAD GDOS SYSTEM MODULES:"
			b CR,   "ERROR WHILE LOADING FILES!",CR,NULL
endif
