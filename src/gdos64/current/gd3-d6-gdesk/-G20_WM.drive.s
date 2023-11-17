; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
;Routine  : WM_OPEN_DRIVE
;Parameter: WM_WCODE = Fenster-Nr.
;Rückgabe : -
;Verändert: A,X,Y,r0-r15
;Funktion : Öffnet dem aktuellen Fenster zugeordnetes Laufwerk.
;
.WM_OPEN_DRIVE		lda	curDrive		;Aktuelles Laufwerk
			sta	:tmpDrive		;zwischenspeichern.

			ldx	WM_WCODE		;Fenster-Nummer einlesen.
			ldy	WIN_DRIVE,x		;Laufwerk für Fenster definiert?
			beq	:no_error		; => Nein, Ende.
			lda	driveType -8,y		;Laufwerk verfügbar?
			beq	:err_no_device		; => Ja, weiter...
			tya
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- Hinweis:
;Falls das Fenster im Partitions- oder
;DiskImage-Modus ist, dann nur Laufwerk
;aktivieren, keine Partition oder
;Verzeichnis öffnen.
;Ansonsten wird bei der Rückkehr zum
;DeskTop ein NativeMode-Fenster im
;Partitions-/DiskImage-Browser-Modus
;automatisch geschlossen.
			ldx	WM_WCODE		;Fenster-Nummer einlesen.
			lda	WIN_DATAMODE,x		;Partitions-/DiskImage-Modus ?
			and	#%11000000
			bne	:no_error		; => Ja, Ende...

			ldx	curDrive
			lda	RealDrvMode -8,x	;Partitionen/Unterverzeichnisse?
			and	#SET_MODE_PARTITION!SET_MODE_SUBDIR

;--- Hinweis:
;Um nicht bei jedem Zugriff auf ein
;Fenster (z.B. Scrollbalken) OpenDisk
;aufzurufen, wird nur bei Laufwerken
;mit Partitionen/Unterverzeichnissen
;die aktuelle Disk überprüft und ggf.
;die Partition / Unterverzeichnis
;gewechselt.
;
			bne	:3			; => Partitionen/UVs, weiter...

;Bei FileCopy auf 1541 muss die BAM
;aktualisiert werden, sonst wird ein
;leeres Verzeichnis angezeigt.
			bit	GD_RELOAD_DIR		;Dateien von Disk laden?
			bpl	:no_error		; => Nein, Ende...
			jmp	GetDirHead		;1541/71/81 => Nur BAM einlesen.

;--- Ziel-Partition öffnen.
;OpenPartition nur ausführen, wenn die
;aktuelle Partition nicht die Ziel-
;Partition ist.
::3			sta	:tmpRealDrvMode		;Laufwerksmodus speichern.
			and	#SET_MODE_PARTITION
			beq	:4			; => Keine Partitionen, weiter...

			ldy	WM_WCODE		;Fenster-Nummer einlesen.
			lda	WIN_PART,y		;Partition für Fenster einlesen.
			bne	:3a			; => Partition definiert, weiter...

;--- Hinweis:
;Keine aktive Partiton, z.B. beim
;Wechsel des Laufwerksmodus.
			lda	drivePartData -8,x
			beq	:no_error		; => Keine aktive Partition, Ende...
			bne	:3b			; => Partition setzen.

::3a			ldx	curDrive		;Partition bereits aktiv?
			cmp	drivePartData -8,x
			bne	:3b			; => Ja, weiter...

			cpx	:tmpDrive		;War Laufwerk bereits aktiv ?
			beq	:4			; => Ja, weiter...

;--- Hinweis:
;Laufwerk wurde gewechselt. Dann muss
;auch die Partition geöffnet werden!
::3b			sta	r3H
			jsr	OpenPartition		;Partition für Fenster aktivieren.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

;--- Ziel-Verzeichnis öffnen.
;OpenSubDir nur ausführen, wenn das
;aktuelle Verzeichnis nicht das Ziel-
;Verzeichnis ist.
::4			lda	:tmpRealDrvMode		;Laufwerksmodus einlesen.
			and	#SET_MODE_SUBDIR	;NativeMode-Laufwerk?
			beq	:no_error		; => Nein, Ende...

			ldx	WM_WCODE		;Fenster-Nummer einlesen.
			lda	WIN_SDIR_T,x		;Tr/Se für Verzeichnis einlesen.
;--- Hinweis:
;Keine aktives Verzeichnis, z.B. beim
;Wechsel des Laufwerksmodus.
			beq	:no_error		; => Track $00 => Ende...
			sta	r1L
			ldy	WIN_SDIR_S,x
			sty	r1H

			cmp	curDirHead +32		;Verzeichnis bereits aktiv?
			bne	:5
			cpy	curDirHead +33
			beq	:no_error		; => Ja, Ende...

::5			jmp	OpenSubDir		;Verzeichnis für Fenster aktivieren.

::err_no_device		ldx	#DEV_NOT_FOUND		;Fehler: Laufwerk nicht vorhanden.
			b $2c
::no_error		ldx	#NO_ERROR		;Kein Fehler.
::exit			rts				;Ende.

::tmpDrive		b $00
::tmpRealDrvMode	b $00
