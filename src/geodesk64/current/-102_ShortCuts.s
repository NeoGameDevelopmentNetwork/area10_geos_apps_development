; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Tastenabfrage installieren.
:InitShortCuts

;--- Hinweis:
;Es gibt in GeoDesk keine andere
;Tastenabfrage, daher ist keyVector
;immer undefiniert / $0000.
if FALSE
			lda	keyVector +0
			ldx	keyVector +1

			cmp	#<GD_SHORTCUTS		;Tastenabfrage bereits aktiv?
			bne	:1			; => Nein, weiter...
			cpx	#>GD_SHORTCUTS
			beq	:2			; => Ja, Ende...

::1			sta	oldKeyVector +0		;Zeiger auf existierende
			stx	oldKeyVector +1		;Tastenabfrage zwischenspeichern.
endif

			lda	#<GD_SHORTCUTS		;Zeiger auf neue Tastenabfrage.
			sta	keyVector +0
			lda	#>GD_SHORTCUTS
			sta	keyVector +1
::2			rts

;*** Alte keyVector-Routine.
;
;Hinweis:
;Wird aktuell nicht verwendet.
;
if FALSE
:oldKeyVector		w $0000
endif

;*** Neue Tastenabfrage für ShortCuts.
:GD_SHORTCUTS		php				;IRQ sperren.
			sei

			ldx	CPU_DATA		;Warten bis keine Taste gedrückt.
			lda	#$35			;TODO: Es können sich aber noch
			sta	CPU_DATA		;Tasten im GEOS-Tastaturpuffer
::11			lda	#$ff			;befinden die unter VICE im WARP-
			sta	CIA_PRA			;Modus den ShortCut mehrfach
			lda	CIA_PRB			;ausführen.
			cmp	#$ff
			bne	:11
			stx	CPU_DATA

;--- Fenster-Nr. testen.
			ldx	WM_STACK		;Fenster-Nr. vom Stack holen.
			bmi	:1			; => $FF = Kein Fenster aktiv.
			stx	WM_WCODE		;Als aktives Fenster setzen.

;--- ShortCut in Tabelle suchen.
;    Übergabe: XReg = Fenster-Nr.
::1			ldy	#$00

;--- Benötigt ShortCut ein Fenster?
::2			lda	keyTab +0,y		;Ende der Tabelle erreicht ?
			beq	:exit			; => Ja, Ende...

			lda	keyTab +1,y		;Fenster erforderlich?
			bpl	:3			; => Nein, weiter...

			ldx	WM_STACK		;Fenster-Nr. vom Stack holen.
			beq	:4			; => $00 = DeskTop, Ende...
			bmi	:4			; => $FF = Kein Fenster aktiv.

;--- ShortCut im Partitions-/DiskImage-Browser möglich?
			and	#%01000000		;Im Part./Image-Browser möglich?
			beq	:3			; => Ja, weiter...

			lda	WIN_DATAMODE,x
			and	#%11000000		;Partitions-/DiskImage-Wechsel ?
			bne	:4			; => Ja, nicht möglich, weiter...

;--- ShortCut suchen...
::3			lda	keyTab +0,y		;ShortCut einlesen.
			cmp	keyData			;Mit aktueller Taste vergleichen.
			beq	:10			; => ShortCut gefunden, weiter...
::4			iny
			iny				;Zeiger auf nächsten ShortCut.
			bne	:2			; => Weitersuchen...
			beq	:exit			;Ende.

;--- ShortCut gefunden.
::10			plp

			lda	routTab +0,y		;Zeiger auf ShortCut-Routine.
			ldx	routTab +1,y
			jmp	CallRoutine		;ShortCut-Routine ausführen.

;--- Kein passender ShortCut gefunden.
::exit			plp

;--- Hinweis:
;Es gibt in GeoDesk keine andere
;Tastenabfrage, daher ist keyVector
;immer undefiniert / $0000.
if FALSE
			lda	oldKeyVector +0
			ldy	oldKeyVector +1
			jmp	CallRoutine
endif
			rts

;*** ShortCut-Tabelle.
;    Byte#1: Tastaturcode.
;    Byte#2: ShortCut-Optionen.
;            Bit%7 = 1 : Nur wenn Fenster geöffnet.
;            Bit%6 = 1 : Nicht im Part./DiskImage-Browser möglich.
;            Wenn Bit%6 = 1, dann muss auch Bit%7 = 1 sein, da der
;            Partitions-/DiskImage-Browser ein Fenster erfordert.
;
:keyTab			b $e8,%00000000			;C= + H : Hilfe anzeigen.
			b $f7,%11000000			;C= + W : Alle auswählen.
			b $d7,%11000000			;C= SHIFT + W : Nichts auswählen.
			b $e3,%10000000			;C= + C : Alle Fenster schließen.
			b $f9,%10000000			;C= + Y : Aktives Fenster schließen.
			b $f3,%10000000			;C= + S : Alle Fenster plazieren.
			b $ec,%10000000			;C= + L : Alle Fenster autom. anordnen.
			b $f6,%11000000			;C= + V : Validate.
			b $fa,%11000000			;C= + Z : Datei öffnen.
			b $f1,%11000000			;C= + Q : Datei-Eigenschaften.
			b $e4,%11000000			;C= + D : Datei löschen.
			b $ee,%11000000			;C= + N : Disk-Eigenschaften.
			b $e5,%11000000			;C= + E : Disk löschen.
			b $e2,%11000000			;C= + B : Disk bereinigen.
			b $e6,%11000000			;C= + F : Disk formatieren.
			b $ea,%11000000			;C= + J : Partition/DiskImage wechseln.
			b $b8,%00000000			;C= + 8 : Laufwerk A:/8 öffnen.
			b $b9,%00000000			;C= + 9 : Laufwerk B:/9 öffnen.
			b $b0,%00000000			;C= + 0 : Laufwerk C:/10 öffnen.
			b $b1,%00000000			;C= + 1 : Laufwerk D:/11 öffnen.
			b $a8,%10000000			;C= SHIFT + 8 : Laufwerk A:/8 wechseln.
			b $a9,%10000000			;C= SHIFT + 9 : Laufwerk B:/9 wechseln.
			b $bd,%10000000			;C= SHIFT + 0 : Laufwerk C:/10 wechseln.
			b $a1,%10000000			;C= SHIFT + 1 : Laufwerk D:/11 wechseln.
			b $e1,%00000000			;C= + A : Arbeitsplatz öffnen.
			b $01,%10000000			;F1 : Icons/Text-Modus.
			b $03,%10000000			;F3 : Details/Kompakt-Modus.
			b $05,%10000000			;F5 : Nach Name sortieren.
			b $06,%10000000			;F6 : Nach Datum/abwärts sortieren.
			b $0e,%11000000			;F7 : Nur Dokumente anzeigen.
			b $0f,%11000000			;F8 : Nur Anwendungen anzeigen.
			b $14,%10000000			;<- : Ein Verzeichnis zurück.
			b $94,%10000000			;C= + <- : Hauptverzeichnis öffnen.
			b $f5,%11000000			;C= + U : Verzeichnis erstellen.
			b $10,%10000000			;CRSR UP : Nach oben scrollen.
			b $11,%10000000			;CRSR DN : Nach unten scrollen.
			b $08,%10000000			;CRSR LEFT : Seite zurück.
			b $1e,%10000000			;CRSR RIGHT : Seite vor.
			b $90,%10000000			;C= + CRSR UP : Zum Anfang.
			b $91,%10000000			;C= + CRSR DN : Zum Ende.
			b $12,%10000000			;HOME : Zum Anfang.
			b $13,%10000000			;CLR/HOME : Zum Ende.
			b $ef,%11000000			;C= + O : Verzeichnis ordnen.
			b $c5,%00000000			;C= SHIFT + E : GEOS.Editor starten.
			b $f4,%11000000			;C= + T : Dateien tauschen.
			b $f2,%11000000			;C= + R : Verzeichnis neu laden.
			b $a3,%00000000			;C= + # : Zwei-Fenster-Modus ein/aus.
			b $f8,%00000000			;C= + X : Rechts-Klick-Menü.
			b $7d,%11000000			;(at) : Nur gelöschte Dateien anzeigen.
			b NULL

;*** ShortCut-Routinen.
:routTab		w SUB_SHOWHELP			;Hilfe anzeigen.
			w PF_SELECT_ALL			;Alle auswählen.
			w PF_SELECT_NONE		;Nichts auswählen.
			w WM_CLOSE_ALL_WIN		;Alle Fenster schließen.
			w WM_CLOSE_CURWIN		;Aktives Fenster schließen.
			w WM_FUNC_SORT			;Alle Fenster plazieren.
			w WM_FUNC_POS			;Alle Fenster autom. anordnen.
			w MOD_VALIDATE			;Validate.
			w MseClkFileWin			;Datei öffnen.
			w PF_FILE_INFO			;Datei-Eigenschaften.
			w PF_DEL_FILE			;Datei löschen.
			w MOD_DISKINFO			;Disk-Eigenschaften.
			w MOD_CLRDISK			;Disk löschen.
			w MOD_PURGEDISK			;Disk bereinigen.
			w PF_FORMAT_DISK		;Disk formatieren.
			w PF_SWAP_DSKIMG		;Partition/DiskImage wechseln.
			w PF_OPEN_DRV_A			;Laufwerk A:/8 öffnen.
			w PF_OPEN_DRV_B			;Laufwerk B:/9 öffnen.
			w PF_OPEN_DRV_C			;Laufwerk C:/10 öffnen.
			w PF_OPEN_DRV_D			;Laufwerk D:/11 öffnen.
			w NewDriveCurWinA		;Laufwerk A:/8 wechseln.
			w NewDriveCurWinB		;Laufwerk B:/9 wechseln.
			w NewDriveCurWinC		;Laufwerk C:/10 wechseln.
			w NewDriveCurWinD		;Laufwerk D:/11 wechseln.
			w OpenMyComputer		;Arbeitsplatz öffnen.
			w PF_VIEW_ICONS			;Icons/Text-Modus.
			w PF_VIEW_DETAILS		;Details/Kompakt-Modus.
			w PF_SORT_NAME			;Nach Name sortieren.
			w PF_SORT_DATE_NEW		;Nach Datum/abwärts sortieren.
			w PF_FILTER_DOCS		;Nur Dokumente anzeigen.
			w PF_FILTER_APPS		;Nur Anwendungen anzeigen.
			w PF_OPEN_PARENT		;Ein Verzeichnis zurück.
			w PF_OPEN_ROOT			;Hauptverzeichnis öffnen.
			w PF_CREATE_DIR			;Verzeichnis erstellen.
			w WM_FUNC_MOVE_UP		;Nach oben scrollen.
			w WM_FUNC_MOVE_DN		;Nach unten scrollen.
			w WM_FUNC_PAGE_UP		;Seite zurück.
			w WM_FUNC_PAGE_DN		;Seite vor.
			w WM_FUNC_MOVE_TOP		;Zum Anfang.
			w WM_FUNC_MOVE_END		;Zum Ende.
			w WM_FUNC_MOVE_TOP		;Zum Anfang.
			w WM_FUNC_MOVE_END		;Zum Ende.
			w MOD_DIRSORT			;Verzeichnis sortieren.
			w MENU_SETUP_EDIT		;GEOS.Editor starten.
			w PF_SWAP_ENTRIES		;Dateien tauschen.
			w PF_RELOAD_DISK		;Verzeichnis neu laden.
			w switchDWinMode		;Zwei-Fenster-Modus ein/aus.
			w WM_CHK_KBD			;Rechts-Klick-Menü.
			w PF_VIEW_DELFILES		;Nur gelöschte Dateien anzeigen.
