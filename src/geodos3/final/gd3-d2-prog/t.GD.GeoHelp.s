; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Deutsch:Texte
;******************************************************************************
if Sprache = Deutsch
:D00a			b PLAINTEXT,BOLDON,									"Fehlermeldung",0
:D00b			b PLAINTEXT,BOLDON,									"Information",0

:D02a			b	 "Das Hilfe-System ist fehlerhaft",0
:D02b			b	 "oder die angeforderte Hilfeseite",0
:D02c			b	 "konnte nicht geladen werden!",0

:D03a			b	 "Auslagerungsdatei für Drucker-",0
:D03b			b	 "treiber konnte nicht erstellt",0
:D03c			b	 "werden. Ausdruck abgebrochen!",0

:D04a			b	 "Aktueller Druckertreiber konnte",0
:D04b			b	 "nicht geladen werden.",0
:D04c			b	 "Ausdruck abgebrochen!",0

;*** Texte für Bildaufbau.
:HelpText01		b GOTOXY,$08,$00,$06, PLAINTEXT
			b	 "Hilfesystem",0
:HelpText02		b GOTOXY,$10,$00,$c2, PLAINTEXT
			b	 "Seite wird gedruckt... ",0
:HelpText03		b GOTOXY,$00,$00,$0e, PLAINTEXT
			b	 "Hilfesystem: ",0
:TextPage		b GOTOX,$da,$00, "Seite: ",0
:HelpTextIndex		b CR,	 "`2Übersicht Textdokumente:`"
			b PLAINTEXT, CR,0

;*** Datei nicht verfügbar.
:FileNotFound		b CR,CR
			b "`2Fehler `: `361Datei nicht gefunden!",CR
:FNF_1			b "`2Datei  `: `3b1"
:FNF_1a			b "________________",CR,CR,CR,CR
			b "`2*** ENDE ***",CR,0

;*** Seite nicht verfügbar.
:PageNotFound		b CR,CR
			b "`2Fehler `: `361Seite nicht verfügbar!",CR
:PNF_1			b "`2Datei  `: `3b1"
:PNF_1a			b "________________",CR
:PNF_2			b "`2Seite  `: `3b1"
:PNF_2a			b "__",CR,CR,CR,CR
			b "`2*** ENDE ***",CR,0

;*** Seite nicht verfügbar.
:FormatError		b CR,CR
			b "`2Fehler `: `361Falsches Text-Format!",CR
:FE_1			b "`2Datei  `: `3b1"
:FE_1a			b "________________",CR,CR
			b "Format V2.0 oder höher wird benötigt!",CR,CR,CR,CR
			b "`2*** ENDE ***",CR,0
endif

;******************************************************************************
;*** English:Text
;******************************************************************************
if Sprache = Englisch
:D00a			b PLAINTEXT,BOLDON,									"Systemerror",0
:D00b			b PLAINTEXT,BOLDON,									"Information",0

:D02a			b	 "The help-system is corrupt",0
:D02b			b	 "or the requested help page",0
:D02c			b	 "could not be loaded!",0

:D03a			b	 "Not able to create swapfile",0
:D03b			b	 "for current printer driver!",0
:D03c			b	 "Printing is cancelled!",0

:D04a			b	 "The current printer driver",0
:D04b			b	 "could not be loaded.",0
:D04c			b	 "Printing is cancelled!",0

;*** Texte für Bildaufbau.
:HelpText01		b GOTOXY,$08,$00,$06, PLAINTEXT
			b	 "Helpsystem",0
:HelpText02		b GOTOXY,$10,$00,$c2, PLAINTEXT
			b	 "Printing current page... ",0
:HelpText03		b GOTOXY,$00,$00,$0e, PLAINTEXT
			b	 "Helpsystem: ",0
:TextPage		b GOTOX,$da,$00, "Page: ",0
:HelpTextIndex		b CR,	 "`2Available textfiles:`"
			b PLAINTEXT, CR,0

;*** Datei nicht verfügbar.
:FileNotFound		b CR,CR
			b "`2Error `: `361File not found!",CR
:FNF_1			b "`2File  `: `3b1"
:FNF_1a			b "________________",CR,CR,CR,CR
			b "`2*** END ***",CR,0

;*** Seite nicht verfügbar.
:PageNotFound		b CR,CR
			b "`2Error `: `361Page not available!",CR
:PNF_1			b "`2File  `: `3b1"
:PNF_1a			b "________________",CR
:PNF_2			b "`2Page  `: `3b1"
:PNF_2a			b "__",CR,CR,CR,CR
			b "`2*** END ***",CR,0

;*** Seite nicht verfügbar.
:FormatError		b CR,CR
			b "`2Error `: `361Illegal text-format!",CR
:FE_1			b "`2File  `: `3b1"
:FE_1a			b "________________",CR,CR
			b "Version 2.x or higher is required!",CR,CR,CR,CR
			b "`2*** END ***",CR,0
endif
