; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Verknüpfungen für DeskTop
.LinkData		b $01

if LANG = LANG_DE
::1a			b "Arbeitsplatz"		;17Z. AppLink-Name.
::1b			s 17 - (:1b - :1a)
::2a			b "Arbeitsplatz"		;17Z. Dateiname.
::2b			s 17 - (:2b - :2a)
endif
if LANG = LANG_EN
::1a			b "My Computer"			;17Z. AppLink-Name.
::1b			s 17 - (:1b - :1a)
::2a			b "My Computer"			;17Z. Dateiname.
::2b			s 17 - (:2b - :2a)
endif

			b $80				;Typ: $00=Anwendung.
							;     $80=Arbeitsplatz.
							;     $FF=Laufwerk.
							;     $FE=Drucker.
							;     $FD=Verzeichnis.
			b $02				;Icon XPos (Cards).
			b $01				;Icon YPos (Cards).
			b $ff,$ff,$ff			;Farbdaten (3x3 Bytes).
			b $ff,$ff,$ff			; => C_GDesk_MyComp
			b $ff,$ff,$ff
			b $00				;Laufwerk: Adresse.
			b $00				;Laufwerk: RealDrvType.
			b $00				;Laufwerk: Partition.
			b $00,$00			;Laufwerk: SubDir Tr/Se.
			b $00,$00,$00			;Verzeichnis-Eintrag.
			b $00				;Fensteroptionen.
							; Bit#7 = 1 : Gelöschte Dateien
							; Bit#6 = 1 : Icons anzeigen
							; Bit#5 = 1 : Größe in Kb
							; Bit#4 = 1 : Details anzeigen

;--- Hinweis:
;Wenn der AppLink-Datensatz vergrößert
;wird, dann genügend Speicher für den
;Arbeitsplatz-AppLink bereitstellen.
:LinkDataCheck		= (LinkData + LINK_DATA_BUFSIZE) +1
			e LinkDataCheck

;--- Speicher für AppLink-Daten.
			s (LINK_COUNT_MAX-1)*LINK_DATA_BUFSIZE
.LinkDataEnd

;*** Desktop-Icons.
.appLinkIBufA

;--- Arbeitsplatz-Icon.
			j
<MISSING_IMAGE_DATA>

;--- Benutzer-AppLink-Icons.
.appLinkIBufU		s (LINK_COUNT_MAX-1)*LINK_ICON_BUFSIZE

.appLinkIBufE
