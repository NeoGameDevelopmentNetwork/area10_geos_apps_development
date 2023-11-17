; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;--- Hinweis:
;":xGetAllSerDrives" muss am Anfang der
;Quelltext-Datei stehen, da andere
;Dateien vor dem Include-Befehl "t"
;ein externes Label ergänzen!

;*** Alle Laufwerke am ser.Bus erkennen.
:xGetAllSerDrives	jsr	DetectAllDrives		;Alle Laufwerke erkennen.

			ldx	#8
::1			lda	sysDevInfo   -8,x	;Laufwerkstyp speichern.
			beq	:3

			cpx	#12			;GEOS-Laufwerk A: bis D:?
			bcs	:2			; => Nein, weiter..

			lda	driveType    -8,x	;GEOS-Laufwerk aktiv ?
			beq	:2			; => Nein, weiter...
			bmi	:2			; => RAM-Laufwerk, weiter...

;--- Ergänzung: 02.04.21/M.Kanet
;Beim ersten Startvorgang können noch
;keine Laufwerke eingerichtet sein.
;--- Ergänzung: 12.06.21/M.Kanet
;Mit Ausnahme des Boot-Laufwerks wenn
;das neue Treiber-Modell genutzt wird:
;Ist eine 1581 als A: und B: im System
;gespeichert, Laufwerk 8: aber eine
;1541, dann wird die erste freie 1581
;auf die Adresse A: getauscht.
;Wird das Boot-Laufwerk nicht als GEOS-
;Laufwerk reserviert, dann wird hier
;das Boot-Laufwerk getauscht und fehlt
;dann für die weitere Installation.
if GD_NG_MODE = FALSE
			bit	firstBoot		;GEOS-BootUp ?
			bpl	:2			; => Ja, weiter...
endif
			lda	#$ff			;Laufwerk als belegt markieren.
			b $2c
::2			lda	#$00
			sta	sysDevGEOS   -8,x

			tay				;GEOS-Laufwerk ?
			beq	:3			; => Nein, weiter...

;--- Bei SD2IEC-Laufwerk aktiven GEOS-Modus übernehmen.
;Bei der Erkennung wird bei aktiver
;"M-R"-Emulation das Laufwerk z.B. als
;1581 erkannt, auch wenn aktuell als
;SD2IEC-Native konfiguriert.
			lda	sysDevInfo   -8,x
			and	#%01000000		;SD2IEC-Laufwerk ?
			beq	:3			; => Nein, weiter...

			lda	driveType    -8,x	;GEOS-Laufwerksmodus einlesen.
			and	#%00001111
			ora	#%01000000		;SD2IEC-Flag wieder setzen.
			sta	sysDevInfo   -8,x	;Laufwerkstyp speichern.

::3			inx
			cpx	#29 +1			;Alle Laufwerke getestet?
			bcc	:1			; => Nein, weiter...
			rts

;*** Tabelle mit belegten GEOS-Geräteadressen.
:sysDevGEOS		s $18
