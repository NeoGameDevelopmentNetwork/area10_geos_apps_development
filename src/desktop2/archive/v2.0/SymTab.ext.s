; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; Extended symbol table for DESK TOP
;
; Reassembled (w)2020 by Markus Kanet
; Original authors:
;   Brian Dougherty
;   Doug Fults
;   Jim Defrisco
;   Tony Requist
; (c)1986,1988 Berkeley Softworks
;
; Revision V0.1
; Date: 23/03/16
;
; History:
; V0.1 - Moved all ext. symbols to
;        a separate file.
;

;--- Application-Register.
;a0L = DeskPad-Seite.
;a0H = Directory-Seite für Suche nach freiem Eintrag.
;a1L = Anzahl Directory-Seiten im Speicher.
;a1H = Laufwerk Source-Disk.
;a2L = Laufwerk Target-Disk.
;a2H = %1xxxxxxx: Dateiwahl aktiv.
;      %x1xxxxxx: Datei-DnD aktiv.
;      %xx1xxxxx: Dateiwahl Border.
;a3L = Zuletzt angeklicktes Icon Files/Border.
;a3H = Icon für DnD auf Laufwerk / FileCopy.
;a4L = $ff: Gew. Icon ist auf aktueller Diskette.
;a4H = Zeiger auf Icon in Tabelle.
;a5  = Zeiger auf dirDiskBuf/Dateieintrag.
;a6L = Zeiger auf letzte gewählte Datei im Selected-Stack.
;a6H = Aktuell geöffnetes Laufwerk.
;a7L = Anzeige-Modus.
;      0: Piktogramme.
;      1: Dateigröße.
;      2: Dateityp.
;      3: Datum.
;      4: Dateiname.
;a7H = Anzahl Dateien auf Disk.
;a8L = Anzahl Dateien auf Seite (Textmodus).
;a8H = $ff: Papierkorb voll.
;a9L = DeskTop-Modul im Speicher.
;a9H = $00: Bei Modul-Lade-Fehler kein Rücksprung.

;--- Füllmuster.
;Hinweis: Wenn für das DeskPad ein
;anderes Muster als $00 verwendet wird,
;dann reicht ggf. der Screen-Buffer für
;den Hintergrund während einer Dialog-
;box nicht mehr aus um die komplette
;Vordergrund-Grafik zu speichern!
;($00-Bytes werden gepackt abgelegt)
:PAT_DESKTOP		= $02				;Default: 2
:PAT_DESKPAD		= $00				;Default: 0
.PAT_TITLE		= $09				;Default: 9

;--- Bildschirmbereiche.
:AREA_FULLPAD_Y0	= $10
:AREA_FULLPAD_Y1	= $8f
:AREA_FULLPAD_X0	= $0008
:AREA_FULLPAD_X1	= $0107
:FULLPAD_CX		= (AREA_FULLPAD_X1 -AREA_FULLPAD_X0 +1)/2

.AREA_FILEPAD_Y0	= $29
.AREA_FILEPAD_Y1	= $76
.AREA_FILEPAD_X0	= $0009
.AREA_FILEPAD_X1	= $0106

:AREA_PADPAGE_Y0	= $29
:AREA_PADPAGE_Y1	= $8a
:AREA_PADPAGE_X0	= $0009
:AREA_PADPAGE_X1	= $0106

:AREA_DSKNAME_Y0	= $11
:AREA_DSKNAME_Y1	= $1b
:AREA_DSKNAME_X0	= $0009
:AREA_DSKNAME_X1	= $0106

:AREA_DSKSTAT_Y0	= $1d
:AREA_DSKSTAT_Y1	= $27
:AREA_DSKSTAT_X0	= $0009
:AREA_DSKSTAT_X1	= $0106

;--- Rechter Systembereich.
:AREA_DRIVES_Y0		= $0d
:AREA_DRIVES_Y1		= $8b
:AREA_DRIVES_X0		= $0108
:AREA_DRIVES_X1		= $013f

;--- Unterer Systembereich.
:PRNAME_Y0		= $b7
:PRNAME_Y1		= $c7
:PRNAME_X0		= $0003
:PRNAME_X1		= $003f
:PRNAME_CX		= $0023

:AREA_BORDER_Y0		= $90
:AREA_BORDER_Y1		= $c7
:AREA_BORDER_X0		= $002f
:AREA_BORDER_X1		= $0118

:TRASH_Y0		= $b0
:TRASH_Y1		= $b9
:TRASH_X0		= $00fd
:TRASH_X1		= $013f
:TRASH_CX		= $0123

;--- GEOS/Datei-Info.
.AREA_INFOBOX_Y0	= $28
.AREA_INFOBOX_Y1	= $b5
.AREA_INFOBOX_X0	= $0048
.AREA_INFOBOX_X1	= $00ef

;--- System-Icons.
.ICON_PAD		= 0
.ICON_BORDER		= 8
:ICON_TRASH		= 16
:ICON_PRINT		= 17
:ICON_PGNAV		= 18				;Page- oder Scroll-Icon.
:ICON_CLOSE		= 19
.ICON_DRVA		= 20
:ICON_DRVB		= 21
:ICON_DRVC		= 22
:MAX_ICONS		= 23

;--- Systemfehler.
:ERR_INSERTDT		= 0
:ERR_MXBORDER		= 1
:ERR_OPENFILE		= 2
:ERR_DISKCOPY		= 3
:ERR_NOMULTIF		= 4
.ERR_FILEPRNT		= 5
:ERR_OTHERDSK		= 6

;--- GEOS-Speicherbelegung.
.zpage			= $0000

:GEOS_VAR_DATA		= $8400
:GEOS_VAR_RBOOT		= $7900
:GEOS_VAR_SIZE		= $0500

:OS_BASE		= $8000

:PADCOLDATA		= $8fe8
:DESKPADCOL		= $8ff0

;--- GEOS-Laufwerkstreiber.
;DISK_BASE		= $9000
:DISK_SIZE		= $0d80

.CreateNewDirBlk	= $9039
.GetDiskBlkBuf		= $903c
.PutDiskBlkBuf		= $903f

:dir3Head		= $9c80

:OFF_DISK_TYPE		= $bd
:GEOS_DISK_TYPE		= curDirHead +OFF_DISK_TYPE

;--- GEOS-Maustreiber.
;MOUSE_BASE		= $fe80
:MOUSE_RBOOT		= $fac0
:MOUSE_SIZE		= $017a

;--- C64-VIC-Register.
:mob0clr		= $d027
:mob1clr		= $d028
:extclr			= $d020
.cia1base		= $dc00

;--- Laufwerkdefinitionen.
:ST_DTYPES		= %00001111
:ST_DMODES		= %00000111

.CBMDIR			= $05

.Drv1541		= $01
.Drv1571		= $02
.Drv1581		= $03
;DrvNative		= $04
;DrvPCDOS		= $05

:DBLSIDED_DISK		= $80

;--- GEOS-Fehlercodes.
.NO_ERROR		= $00
.INV_TRACK		= $02
:INSUFF_SPACE		= $03
.FULL_DIRECTORY		= $04
.FILE_NOT_FOUND		= $05
:BAD_BAM		= $06
;STRUCT_MISMAT		= $0a
.BFR_OVERFLOW		= $0b
.CANCEL_ERR		= $0c
.DEV_NOT_FOUND		= $0d

;--- Speicherbelegung DeskTop:
;
;--- Bereich $0200-$02ff:
:bufOpenDiskNm		= $0200				;18 Byte, Name geöffnete Disk.
:bufDiskNmA		= $0212				;18 Byte, Name Disk Laufwerk A:
:bufDiskNmB		= $0224				;18 Byte, Name Disk Laufwerk B:
:bufDiskNmC		= $0236				;18 Byte, Name Disk Laufwerk C:
:flagDrivesRdy		= $0248				;Byte, $ff=Laufwerke getestet.
:flagEnablSwapDk	= $0249				;Byte, $ff=Kein Diskwechsel.
:flagRemoveEntry	= $024a				;Byte, $ff=Dateieintrag löschen.
:batchStatus		= $024b				;Byte, $ff=Job abgeschlossen.
:flagLockMseDrv		= $024c				;Mauszeiger eingrenzen: "DRIVES"
:flagDiskRdy		= $024d				;Byte, $ff=Diskette gültig.
:v024e			= $024e				;Byte, nur :moveBorderToPad ???
:curPosStrWidth		= $024f				;Byte, Pos. in :getStringWidth
.flagUpdClock		= $0250				;Flag, $00=Uhrzeit aktualisieren.
							;Wird in mod#5 auf $FF gesezt.
:bufTrSePrefs		= $0251				;Tr/Se "Preferences".
:bufTrSePadCol		= $0253				;Tr/Se "Pad Color Pref".
.vec1stInput		= $0255				;Zeiger auf Verzeichnintrag
							;erster Eingabetreiber auf Disk.
:vec1stPrint		= $0257				;Zeiger auf Verzeichnintrag
							;erster Druckertreiber auf Disk.

;--- Bereich $0300-$03ff:
:tabBIconDkNm		= $0334				;8x18 Zeichen:
							;Diskname für Border-Icons.
:tabVecSysIconNm	= $03c4				;2x23 Byte:
							;Zeiger auf Icon-Namen.
.vecIconPrntName	= $03e6				;Word:
							;Zeiger auf Druckername.

:bufTempDataVec		= $03f2				;Word, Start Kopierspeicher.
:bufTempDataSize	= $03f4				;Word, Größe Kopierspeicher.
.nmDkSrc		= $03f6				;Word, Zeiger Name Quell-Disk.
.nmDkTgt		= $03f8				;Word, Zeiger Name Ziel-Disk.
.vec2FCopyNmSrc		= $03fa				;Word, Zeiger Name Quell-Datei.
.vec2FCopyNmTgt		= $03fc				;Word, Zeiger Name Ziel-Datei.
:bufRecoverVec		= $03fe				;Word, RecoverRectangle-Routine.

;--- Bereich ab $0400:
:APPRAM_1A		= $0406

.tempDirEntry		= $0406				;30 Byte (Verzeichniseintrag)
:tabIconMenu		= $0424				;Byte: Anzahl Icons.
							;Word: X-Koordinate.
							;Byte: Y-Koordinate.
:tabIconData		= $0428				;23x8 Byte:
							;Tabelle für DoIcons-Menü.
:bufVecFreeDir		= $04e0				;Byte, Zeiger Directory-Eintrag.
:bufAdrFreeDir		= $04e1				;Track/Sektor Directory-Eintrag.
:jobInfFCopy		= $04e3				;Tabelle.
:searchTrSe		= $04e7				;Track/Sektor.
:adr1stDataBlk		= $04e9				;Erster Track/Sektor.
:flagDkDrvRdy		= $04eb				;Byte, $02 = Src/Tgt-Drv. Ready.
:flagBootDT		= $04ec				;Byte, $ff = DeskTop neu starten.
:flagFileCopy		= $04ed				;Byte, $ff = FileCopy aktiv.
:flagDuplicate		= $04ee				;Byte, $ff = Duplicate file.
:bufTmpBlkDatVec	= $04ef				;Word, Zeiger DiskCopy-Speicher.
:countLastByt		= $04f1				;Byte, Rest letzter Block/Copy.
:countBlocks		= $04f2				;Byte, Blockzähler.
:drvCurBlkSe		= $04f3				;Byte, Aktueller Sektor.
:drvCurBlkTr		= $04f4				;Byte, Aktueller Track.
:drvCurTrMaxSek		= $04f5				;Byte, Max. Anzahl Tracks.
:flagWriteVerify	= $04f6				;Byte, $00 = Write, $ff = Verify.
:tabBlkStatus		= $04f7				;40 Byte
.dvTypSource		= $0520				;Byte, Quell-Lfwk:1=41/2=71/3=81.
.dvTypTarget		= $0521				;Byte, Ziel-Lfwk:1=41/2=71/3=81.
:drvMaxTracks		= $0522				;Byte, max. Tracks
.drv1stDirTr		= $0523				;Erster Verzeichnisblock/Track.
.drv1stDirSe		= $0524				;Erster Verzeichnisblock/Sektor.
:flag_DnDActive		= $0525				;Byte, $01 = DnD Aktiv.
:tabBIconDEntry		= $0526				;8x32 Bytes: Verzeichniseinträge
							;für die 8 Border-Icons.
:tabBIconBitmaps	= $0626				;8x68 Bytes: Border-Icon-Daten.
							;$00,$0f,$03,$15,Icon-Bitmap.
.tabFIconBitmaps	= $0846				;8x68 Bytes: Datei-Icon-Daten.
							;$00,$0f,$03,$15,Icon-Bitmap.
							;Bei Text-Anzeige:
							;Speicher für sortierte Tabelle.
.tabNameDeskAcc		= $0a66				;8x17 Byte:
							;Dateinamen für DAs im geos-Menü.
.topTxEntry		= $0aee				;Word, Zeiger auf ersten Eintrag.
:flagDriverReady	= $0af0				;Byte, $ff = Zweiter Treiber RAM.
:bufDskDrvAdr		= $0af1				;Byte, Adr. für zweiten Treiber.
:bufDiskDriver		= $0af2				;$0d80 Byte bis $1871:
							;Zweiter Laufwerkstreiber
:flagKeepMsePos		= $1872				;Byte, $ff = Mauspos. behalten.
:bufMouseYPos		= $1873				;Byte, Zwischenspeicher für
:bufMouseXPos		= $1874				;Word, Mauszeiger X-/Y-Position.
:bufCurCopyFile		= $1876				;30 Byte
.bufLastDelEntry	= $1894				;30 Byte, zuletzt gelöschte Datei
:tabSlctFiles		= $18b2				;144 Byte:
							;$x. = High-Nibble:
							;      Lowbyte Adr. dirDiskBuf
							;$.y = Low-Nibble:
							;      Directory-Seite 0-17
							;$1f = Dateien im Border.
.stringCurDate		= $1942				;10 Zeichen, Datum.
.stringCurTime		= $194c				; 7 Zeichen, Uhrzeit.
							;10 Zeichen, Uhrzeit (AM/PM).

;--- Startadresse Application-Speicher.
:DTOP_BASE		= $1956

;--- Verschiedene Zwischenspeicher.
.tempDataBuf		= $6600				;Zwischenspeicher, u.a. für den
							;Grafik-Bildschirm u. FileCopy.
:sizeDataBuf		= $1700				;Größe des Zwischenspeichers.

.dirDiskBuf		= $6d00				;Zwischenspeicher:
							;max. 18 Verzeichnisblocks.
:vlirHdrBuf		= $7d00				;Zwischenspeicher:
							;VLIR-Header.

;--- Zwischenspeicher für Verzeichnis, BoderBlock, BAM...
.buf_diskSek1		= spr2pic			;= $8a80
:buf_diskSek2		= $7e00				;Zwischenspeicher.
.buf_diskSek3		= $7f00				;Zwischenspeicher.

;--- Zwischenspeicher für Datei-/Disknamen.
.buf_TempName		= spr6pic			;= $8b80

;--- Zwischenspeicher für Text-Strings.
:buf_TempStr0		= $8bbc				;String, max.20 Byte.
.buf_TempStr1		= $8bd0				;String, max.20 Byte.
.buf_TempStr2		= $8be4				;String, max.20 Byte.

;--- Max. Anzahl Verzeichnisblocks.
:MAX_DIR_BLK		= (buf_diskSek3 - dirDiskBuf) /256
