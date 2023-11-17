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
			w BootText60			;$17
			w BootText61			;$18
;			w BootText62			;HD-Kabel nicht beim Systemstart.
			w BootText70			;$19
			w BootText80			;$1a
			w BootText90			;$1b

if Flag64_128 = TRUE_C128
			w BootText40a			;$1c
			w BootText50a			;$1d
endif

;*** Texte für Start-Sequenz.
if Sprache = Deutsch
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
:BootText16		b CR,CR,"GEOS-DACC WIRD INSTALLIERT IN",CR,NULL
:BootText18		b       " ERWEITERTER SPEICHER",CR,NULL
:BootText19		b CR,CR,"WAHL DER RAMLINK-DACC-PARTITION"
			b CR,   "('SPACE' = WECHSELN, 'RETURN' = OK)",CR,NULL

:BootText20		b CR,CR,"GEOS KANN OHNE RAM NICHT GESTARTET"
			b CR,   "WERDEN. START ABGEBROCHEN...",CR,NULL
:BootText21		b CR,   "INSTALLATIONS-AUTOMATIK AKTIV!"
			b CR,CR,"UM EINE NEUE SPEICHERERWEITERUNG ZU"
			b CR,   "AKTIVIEREN, STARTEN SIE GEOS MIT DER"
endif
if Sprache ! Flag64_128 = Deutsch ! TRUE_C64
			b CR,   "DATEI 'GEOS64.RESET'",NULL
endif
if Sprache ! Flag64_128 = Deutsch ! TRUE_C128
			b CR,   "DATEI 'GEOS128.RESET'",NULL
endif

if Sprache = Deutsch
:BootText22		b CR,CR,"DAS SYSTEM WIRD JETZT INSTALLIERT:",CR,NULL

:BootText30		b CR,   "STARTLAUFWERK INITIALISIEREN",NULL
:BootText31		b CR,   "RAMLINK-PARTITION #",NULL
endif

if Sprache ! Flag64_128 = Deutsch ! TRUE_C64
:BootText40		b CR,CR,"GEOS-KERNAL LADEN.............:",NULL
:BootText50		b       "GEOS-KERNAL INSTALLIEREN......:",NULL
endif
if Sprache ! Flag64_128 = Deutsch ! TRUE_C128
:BootText40		b CR,CR,"GEOS-KERNAL LADEN........BANK0:",NULL
:BootText40a		b       "GEOS-KERNAL LADEN........BANK1:",NULL
:BootText50		b       "GEOS-KERNAL INSTALLIEREN.BANK0:",NULL
:BootText50a		b       "GEOS-KERNAL INSTALLIEREN.BANK1:",NULL
endif

if Sprache = Deutsch
:BootText41		b CR,   "MP3 -KERNAL #? LADEN..........:",NULL
:BootText51		b       "MP3 -KERNAL #? INSTALLIEREN...:",NULL
:BootText52		b       "MP3 -REBOOT INSTALLIEREN......:",NULL

:BootText60		b CR,   "SPEICHER-MANAGEMENT STARTEN...:",NULL
:BootText61		b       "SUPERCPU-MANAGEMENT STARTEN...:",NULL
;BootText62		b       "CMD-HD-KABEL ABSCHALTEN.......:",NULL

:BootText70		b CR,   "GEOS-KERNAL STARTEN...",NULL
:BootText80		b       " ERROR"
			b CR,CR,"KERNAL KONNTE NICHT IN DER SPEICHER-"
			b CR,   "ERWEITERUNG INSTALLIERT WERDEN!"
			b CR,CR,"SPEICHERERWEITERUNG FEHLERHAFT!",CR,NULL
endif

if Sprache = Deutsch
:BootText90		b       "ERWEITERTEN SPEICHER TESTEN...:",NULL
endif

;*** Texte für Start-Sequenz.
if Sprache = Englisch
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
:BootText16		b CR,CR,"GEOS-DACC WILL BE INSTALLED IN",CR,NULL
:BootText18		b       " EXTENDED MEMORY",CR,NULL
:BootText19		b CR,CR,"SELECT RAMLINK-DACC-PARTITION"
			b CR,  "('SPACE' = CHANGE, 'RETURN' = OK)",CR,NULL

:BootText20		b CR,CR,"BOOTING GEOS WITHOUT RAM IS NOT"
			b CR,   "POSSIBLE. START CANCELLED...",CR,CR,NULL
:BootText21		b CR,   "AUTO-INSTALLATION ACTIV!"
			b CR,CR,"TO SELECT A NEW RAM-EXPANSION PLEASE"
endif
if Sprache ! Flag64_128 = Englisch ! TRUE_C64
			b CR,   "BOOT GEOS WITH FILE 'GEOS64.RESET'",NULL
endif
if Sprache ! Flag64_128 = Englisch ! TRUE_C128
			b CR,   "BOOT GEOS WITH FILE 'GEOS128.RESET'",NULL
endif

if Sprache = Englisch
:BootText22		b CR,CR,"THE SYSTEM WILL NOW BE INSTALLED:",CR,NULL

:BootText30		b CR,   "INITIALIZING BOOT-DEVICE",NULL
:BootText31		b CR,   "RAMLINK-PARTITION #",NULL
endif

if Sprache ! Flag64_128 = Englisch ! TRUE_C64
:BootText40		b CR,CR,"GEOS-KERNAL LOAD..............:",NULL
:BootText50		b       "GEOS-KERNAL INSTALL...........:",NULL
endif
if Sprache ! Flag64_128 = Englisch ! TRUE_C128
:BootText40		b CR,CR,"GEOS-KERNAL LOAD.........BANK0:",NULL
:BootText40a		b       "GEOS-KERNAL LOAD.........BANK1:",NULL
:BootText50		b	 "GEOS-KERNAL INSTALL......BANK0:",NULL
:BootText50a		b	 "GEOS-KERNAL INSTALL......BANK1:",NULL
endif

if Sprache = Englisch
:BootText41		b CR,   "MP3 -KERNAL #1 LOAD...........:",NULL
:BootText51		b       "MP3 -KERNAL #1 INSTALL........:",NULL
:BootText52		b       "MP3 -REBOOT INSTALL...........:",NULL

:BootText60		b CR,   "INSTALL MEMORY-MANAGER........:",NULL
:BootText61		b       "INSTALL SUPERCPU-MANAGER......:",NULL
;BootText62		b       "DEACTIVATE CMD-HD-CABLE.......:",NULL

:BootText70		b CR,   "STARTING GEOS...",NULL
:BootText80		b       " ERROR"
			b CR,CR,"UNABLE TO INSTALL THE KERNAL"
			b CR,	 "IN RAM-EXPANSION-UNIT!"
			b CR,CR,"RAM-EXPANSION MIGHT BE CORRUPT!",CR,NULL
endif

if Sprache = Englisch
:BootText90		b       "TESTING EXTENDED MEMORY.......:",NULL
endif
