; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; SourceCode für geoSCSIcopy64
; 2020: Markus Kanet
; für GEOS mit MegaPatch 64/128 V3.3+
; Schriftart: 81'Assembler
; Druckertreiber: GeoHelp.Edit.prn
;
if .p
			t "TopSym"
			t "TopMac"
			t "Sym128.erg"

;--- Zusätzliche Labels MP3/Kernal:
			t "TopSym.MP3"
			t "TopSym.ROM"

;--- Zusätzliche Labels GEOS128:
:DB_DblBit		= $8871

;--- Spracheinstellungen.
;Der Wert für LANG wird als WORD
;definiert da der Wert mit TRUE/FALSE
;kombiniert werden muss, z.B. DEBUG.
:LANG_DE		= $4000
:LANG_EN		= $8000
:LANG			= LANG_DE

;--- Programmeinstellungen.
:TESTUI			= FALSE				;TRUE: Nur UI testen.
:TESTDLG		= FALSE				;TRUE: Dialogboxen testen.

;--- TestUI: Anzahl Demo Ppartitionen.
:cntTestUIsrcP		= 11
:cntTestUItgtP		= 9

;--- CMD-Partitionsformate.
:cmdPartNative		= 1
:cmdPart1541		= 2
:cmdPart1571		= 3
:cmdPart1581		= 4
:cmdPart1581CPM		= 5
:cmdPartPrntBuf		= 6
:cmdPartForeign		= 7

;--- Fehler-Codes.
:gScErr_OK		= 0
:gScErr_NoMP		= 1
:gScErr_DevNotRdy	= 13
:gScErr_UpdNM		= 20
:gScErr_UpdPart		= 25
:gScErr_NotRdy		= 40
:gScErr_BlkSize		= 100
:gScErr_RdPTabSek	= 128
:gScErr_RdDirData	= 144
:gScErr_NoSysP		= 200
:gScErr_SysDvP		= 208
:gScErr_PartFrmt	= 240
:gScErr_CopyRdSek	= 250
:gScErr_CopyWrSek	= 251
:gScErr_BadSCSI		= 252
:gScErr_FindSCSI	= 253
:gScErr_RdBlkSCSI	= 254
;gScErr_CopySCSI	= 255

;--- Status-Flags.
:DRVREADY		= $ff
:NOTREADY		= $00
:SETDEVSRC		= $00
:SETDEVTGT		= $80
endif

;--- Hinweis:
;Vergleiche Variable ":applClass"!
if LANG = LANG_DE
			n "geoSCSIcopy64"
			c "geoSCSIcopy V0.050"
			h "Partitionen kopieren zwischen SCSI-Geräten der CMD-HD. Nur GEOS-MegaPatch 64/128!"
endif
if LANG = LANG_EN
			n "geoSCSIcopy64E"
			c "geoSCSIcopyEV0.050"
			h "Copy partitions between SCSI devices connected to your CMD-HD. GEOS-MegaPatch 64/128 only!"
endif

			f APPLICATION

			o APP_RAM
			p MainInit

			a "Markus Kanet"

;			z $00				;Nur 40Z-Modus.
			z $40				;40- und 80-Zeichen.
;			z $80				;Nur GEOS64.
;			z $c0				;Nur 80-Zeichen.

			i
<MISSING_IMAGE_DATA>

;--- Zeichensatz für Partitionstabelle.
:FontG3			v 7,"fnt.GeoDesk"

;*** Programm-Daten/Variablen.
:curScrnMode		b $00				;40Z/80Z-Modus.
:devAdrHD		b $00				;Aktuelle GEOS-Adresse CMD-HD.
:devErrorHD		b $00				;Fehlerstatus CMD-HD.
:partSyncMode		b $00				;$FF = Sync Quell-/Ziel-Part-Nr.
:size64Kb		b "65536",NULL

;*** Allgemeine Laufwerksbefehle.
:comINIT		b "I0:"				;Disk initialisieren.
:comGETID		b "M-R"				;Aktuelle ID der CMD-HD einlesen.
			w $9000
			b $01
:comGETPART		b "G-P"				;Aktuelle Partition einlesen.
;--- Nicht trennen/verschieben!
:comSETPART		b $43,$d0			;"cP"+Partition = Partition setzen.
:activePart		b $00				;Partitionsnummer.
;--- Nicht trennen/verschieben!
:comWRSIZE		b "M-W"				;Größe NativeMode korrigieren.
			w scsiBufAdr +8
			b $01
:updateNative		b $00				;Größe der Native-Partition.
;---

;*** Variablen: Partition kopieren.
:copyStartSrc		s 3				;Quelle: Startadresse Partition.
:copyStartTgt		s 3				;Ziel  : Startadresse Partition.
:copySize		s 2				;Größe der Partition.
:sectorCount		s 2				;Anzahl Sektoren zum kopieren.
:tgtPTypeData		s 256				;Liste mit gültigen Partitionen.

;*** Variablen: Fortschrittsanzeige.
:statusPos		b $00				;Aktueller Wert.
:statusMax		b $00				;Maximaler Wert.
:infoTx0pct		b "0%",NULL
:infoTx100pct		b "100%",NULL
:statusCount		b 0,255,22,43,100,100,255,255
:statusMode		b $00				;$FF = Native/Foreign/PrintBuf

;*** Dialogbox für Verzeichnisanzeige.
:Dlg_ShowDir		b $81
			b DBUSRFILES
			w dirFileDataBuf
			b OK         ,$00,$00
			b NULL

;*** Variablen: Verzeichnisanzeige.
:dirPartType		b $00				;Partitionstyp Verzeichnisanzeige.
:startPAdrLBA		s $04				;Start-Adresse der Partition.
:curDirAdrBLK		w $0000				;Aktuelle Block-Adresse.
:curDirAdrLBA		s $04				;Aktuelle LBA-Adresse.
:curSekOffset		w $0000				;LBA-Offset innerhalb 512B-Sektor.
:dirBlkTr		b $00				;Verzeichnis-Spur.
:dirBlkSe		b $00				;Verzeichnis-Sektor.

;*** Vorgabetext für leeres Verzeichnis.
if LANG = LANG_DE
:emptyDisk		b "Leere Disk",NULL
endif
if LANG = LANG_EN
:emptyDisk		b "Empty disk",NULL
endif

;*** Daten für ersten Verzeichnis-Sektor.
; -> Native, 1541, 1571, 1581
:dirStartSek		w 0				;512B-Block Native: #1/1
			w 178				;512B-Block 1541  : #18/0
			w 178				;512B-Block 1571  : #18/0
			w 780				;512B-Block 1581  : #40/0
:dirBlkOffset		w 256				;Offset Native: #1/1
			w 256				;Offset 1541  : #18/0
			w 256				;Offset 1541  : #18/0
			w 0				;Offset 1581  : #40/0

;*** Anzahl Sektoren/Spur für 1541/71.
:SekPerTrack		b 00				; 0
::1541			b 21,21,21,21,21,21		; 1- 6
			b 21,21,21,21,21,21		; 7-12
			b 21,21,21,21,21		;13-17
			b 19,19,19,19,19,19,19		;18-24
			b 18,18,18,18,18,18		;23-30
			b 17,17,17,17,17		;31-35
::1571			b 21,21,21,21,21,21		; 1- 6
			b 21,21,21,21,21,21		; 7-12
			b 21,21,21,21,21		;13-17
			b 19,19,19,19,19,19,19		;18-24
			b 18,18,18,18,18,18		;23-30
			b 17,17,17,17,17		;31-35

;*** SCSI-Geräte-Informationen.
:scsiSrcID		b $00				;SCSI-ID Quelle.
:scsiSrcIDtx		b "00:",NULL			;SCSI-ID/Textformat.
:scsiSrcVendor		s 17				;Typ/Hersteller.
:scsiSrcModel		s 17				;Gerätetyp.
:scsiSrcAdrSysP		s 4				;Startadresse Systempartition.
:scsiSrcAdrPTab		s 4				;Startadresse Partitionstabelle.
:scsiTgtID		b $00				;SCSI-ID Quelle.
:scsiTgtIDtx		b "00:",NULL			;SCSI-ID/Textformat.
:scsiTgtVendor		s 17				;Typ/Hersteller.
:scsiTgtModel		s 17				;Gerätetyp.
:scsiTgtAdrSysP		s 4				;Startadresse Systempartition.
:scsiTgtAdrPTab		s 4				;Startadresse Partitionstabelle.

;*** Datenspeicher für SCSI-Daten.
:scsiDataBuf8		s $08				;Speicher für "CAPACITY".
:scsiDataBuf16		s $10				;Speicher für Suche Systempartition.
:scsiDataBuf24		s $24				;Speicher für "INQUIRY".

;*** Informationen über SCSI-Geräte.
:scsiDevCurID		b $00				;Aktuelle ID der CMD-HD.
:scsiDevCount		b $00				;Anzahl Geräte.
:scsiComID		b $00				;Neue SCSI-ID.
:scsiAdrSysPart		s $04				;Startadresse Systempartition.
:scsiAdrPTable		s $04				;Startadresse Partitionstabelle.

;--- Intern: SCSI-Gerätetypen.
;Nur "DEVICE TYPE" = 0,5,7 erlaubt.
;$00 = Direct-Access device/Festplatte
;      (ZIP meldet sich als Festplatte)
;$02 = CDROM device
;$03 = Optical memory device
:scsiTypes		b $00,$ff,$ff,$ff
			b $ff,$02,$ff,$03

;--- Intern: Wechselmedien.
:scsiEjMode		b $00,$02,$02,$02

;--- Intern: Liste mit SCSI-IDs.
;Hinweis: Die DEBUG-Werte sind nur für
;die Versionen zum testen des UI.
if TESTUI=TRUE
:scsiID			b $00,$ff,$ff,$ff
			b $ff,$05,$ff,$ff
endif
if TESTUI=FALSE
:scsiID			b $ff,$ff,$ff,$ff
			b $ff,$ff,$ff,$ff
endif

;--- Intern: Liste mit Gerätetypen.
if TESTUI=TRUE
:scsiIdent		b $00,$ff,$ff,$ff
			b $ff,$01,$ff,$ff
endif
if TESTUI=FALSE
:scsiIdent		b $ff,$ff,$ff,$ff
			b $ff,$ff,$ff,$ff
endif

;--- Intern: Laufwerk mit Wechselmedium.
:scsiRemovable		b $00,$00,$00,$00
			b $00,$00,$00,$00

;--- Intern: Liste der Geräteklassen.
;Hinweis: Es müssen zwei Zeichen sein!
:scsiTypeTx		b "H:"
			b "Z:"
			b "C:"
			b "M:"

;--- Zeiger auf Texte Register-Menü.
;Für Hersteller/Gerätename werden zwei
;Textzeilen benötigt. Diese Tabelle
;beinhaltet Zeiger auf Zeile#1/#2 für
;die SCSI-IDs 0-7.
:scsiNameTab		w scsiName0a,scsiName0b
			w scsiName1a,scsiName1b
			w scsiName2a,scsiName2b
			w scsiName3a,scsiName3b
			w scsiName4a,scsiName4b
			w scsiName5a,scsiName5b
			w scsiName6a,scsiName6b
			w scsiName7a,scsiName7b

if TESTUI=TRUE
;--- Textzeile #1: Hersteller.
;Laut SCSI-Definition nur 8 Zeichen.
;Hier: 10Zeichen inkl. Type-Code.
:scsiName0a		b "H:CODESRC       ",NULL
:scsiName1a		s 17
:scsiName2a		s 17
:scsiName3a		s 17
:scsiName4a		s 17
:scsiName5a		b "Z:IOMEGA        ",NULL
:scsiName6a		s 17
:scsiName7a		s 17

;--- Textzeile #2: Gerätename.
;Laut SCSI-Definition nur 16 Zeichen.
:scsiName0b		b "         SCSI2SD",NULL
:scsiName1b		s 17
:scsiName2b		s 17
:scsiName3b		s 17
:scsiName4b		s 17
:scsiName5b		b "DVD-ROM SD-M1401",NULL
:scsiName6b		s 17
:scsiName7b		s 17
endif

if TESTUI=FALSE
;--- Textzeile #1: Hersteller.
;Laut SCSI-Definition nur 8 Zeichen.
;Hier: 10Zeichen inkl. Type-Code.
:scsiName0a		s 17
:scsiName1a		s 17
:scsiName2a		s 17
:scsiName3a		s 17
:scsiName4a		s 17
:scsiName5a		s 17
:scsiName6a		s 17
:scsiName7a		s 17

;--- Textzeile #2: Gerätename.
;Laut SCSI-Definition nur 16 Zeichen.
:scsiName0b		s 17
:scsiName1b		s 17
:scsiName2b		s 17
:scsiName3b		s 17
:scsiName4b		s 17
:scsiName5b		s 17
:scsiName6b		s 17
:scsiName7b		s 17
endif

;*** SCSI-Befehlstabelle.
;Kommentare aus dem "SCSI Reference Manual" von Seagate:
;https://www.seagate.com/files/staticfiles/support/docs/manual/Interface Manuals/100293068i.pdf

;--- Lage SCSI-Buffer.
:scsiBufAdr		= $3000

;--- 00h / 6 Bytes.
;SCSI-Befehl: TEST UNIT READY
; -Operation Code $00
; -Reserved 4 Bytes
; -Control
;Rückgabe: 1 Byte
;$00    : OK
;$02    : No media
;$8x    : Not ready
:scsiREADY		b "S-C"
:scsiREADY_id		b $00
			w scsiBufAdr
			b $00,$00,$00,$00,$00,$00

;--- 12h / 6 Bytes.
;SCSI-Befehl: INQUIRY
; -Operation Code $12
; -EVPD Bit%0=0: Standard INQUIRY data
; -Page Code
; -Allocation length Hi/Lo
; -Control
;Rückgabe: 36 Bytes
;$00    : Bit %0-%4 = Device type.
;$08-$0F: T10 Vendor identification
;$10-$1F: Product identification
;$20-$23: Product revision level
;Aktuell nicht verwendet:
;$24-$2B: Drive serial number
:scsiINQUIRY		b "S-C"
:scsiINQUIRY_id		b $00
			w scsiBufAdr
			b $12,$00,$00,$00,$24,$00
:scsiINQUIRY_mr		b "M-R"
			w scsiBufAdr
			b $24

;--- 25h / 10 Bytes.
;SCSI-Befehl: READ CAPACITY
; -Operation Code $25
; -Reserved/Obsolete
; -Logical Block Address 4 Bytes (Obsolete)
; -Reserved
; -Reserved
; -Reserved/PMI(Obsolete)
; -Control
;Rückgabe: 8 Bytes
;$00-$03: MSB...LSB Anzahl 512-Blocks.
;$04-$07: MSB...LSB Blockgröße.
;         Muss $00,$00,$02,$00 sein!
:scsiCAPACITY		b "S-C"
:scsiCAPACITY_id	b $00
			w scsiBufAdr
			b $25,$00,$00,$00,$00,$00
:scsiCAPACITY_mr	b "M-R"
			w scsiBufAdr
			b $08

;--- 1Bh / 6 Bytes.
;SCSI-Befehl: START/STOP UNIT
; -Operation Code $1b
; -Immediate Bit%0=1
;  The device server shall return status as
;  soon as the CDB has been validated.
; -Reserved
; -Power condition modifier
;  $00 = Process LOEJ and START bits.
; -LOEJ/START
;  Bit%0=0 STOP
;  Bit%0=1 START
;  Bit%1=0 No action regarding loading/ejecting medium.
;  Bit%1=1 and Bit%0=0 Eject medium.
;  Bit%1=1 and Bit%0=1 Load medium.
; -Control
:scsiSTARTUNIT		b "S-C"
:scsiSTARTUNIT_id	b $00
			w scsiBufAdr
			b $1b,$00,$00,$00,$01,$00

;scsiSTOPUNIT		b "S-C"
;scsiSTOPUNIT_id	b $00
;			w scsiBufAdr
;			b $1b,$01,$00,$00,$00,$00
;scsiSTOPUNIT_ej	= scsiSTOPUNIT +10

;--- 28h / 10 Bytes.
;SCSI-Befehl: READ
; -Operation Code $28
; -Data
; -Logical Block Address 4 Bytes
; -Group number
; -Transfer length MSB
; -Transfer length LSB
; -Control
:scsiREAD		b "S-C"
:scsiREAD_id		b $00
			w scsiBufAdr
			b $28,$00
:scsiREAD_adr		b $00,$00,$00,$00
			b $00
:scsiREAD_count		b $00,$01
			b $00
:scsiREAD_mr		b "M-R"
:scsiREAD_mradr		w scsiBufAdr +$01f0
:scsiREAD_mrcnt		b $10

;--- 2Ah / 10 Bytes.
;--- 2Eh / 10 Bytes.
;SCSI-Befehl: WRITE / WRITE+VERIFY
; -Operation Code $2a / $2e
; -Data
; -Logical Block Address 4 Bytes
; -Group number
; -Transfer length MSB
; -Transfer length LSB
; -Control
;--- Hinweis:
;Aktuell wird 2Eh / WRITE+VERIFY von
;VICE 3.5 nicht unterstützt.
:scsiWRITE		b "S-C"
:scsiWRITE_id		b $00
			w scsiBufAdr
			b $2a,$00
:scsiWRITE_adr		b $00,$00,$00,$00
			b $00
:scsiWRITE_count	b $00,$01
			b $00

;--- 03h / 6 Bytes.
;SCSI-Befehl: REQUEST SENSE
; -Operation Code $03
; -DESC 0=Request fixed sense data
; -Reserved
; -Reserved
; -Allocation length
; -Control
:scsiSENSE		b "S-C"
:scsiSENSE_id		b $00
			w scsiBufAdr
			b $03
			b $00
			b $00,$00
			b $12
			b $00
:scsiSENSE_mr		b "M-R"
:scsiSENSE_mradr	w scsiBufAdr
:scsiSENSE_mrcnt	b $12
:scsiSENSE_buf		s $12

;*** Dialogbox-Titel.
if LANG = LANG_DE
:Dlg_Titel_Error	b PLAINTEXT,BOLDON
			b "FEHLER"
			b NULL
:Dlg_Titel_Info		b PLAINTEXT,BOLDON
			b "INFORMATION"
			b NULL
endif
if LANG = LANG_EN
:Dlg_Titel_Error	b PLAINTEXT,BOLDON
			b "ERROR"
			b NULL
:Dlg_Titel_Info		b PLAINTEXT,BOLDON
			b "INFORMATION"
			b NULL
endif

;*** Fehler: Keine CMD-HD unter GEOS.
:Dlg_ErrorNoHD		b %01100001
			b $30,$8f
:dlg80_01a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$2b
			w :102
			b DBTXTSTR   ,$0c,$3b
			w :103
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Aktuell ist kein CMD-HD-Laufwerk",NULL
::102			b "unter GEOS eingerichtet!",NULL
::103			b "Programm wird beendet.",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "There is currently no CMD-HD",NULL
::102			b "drive configured under GEOS!",NULL
::103			b "Program will be cancelled.",NULL
endif

;*** Fehler: Falsche Blockgröße.
:Dlg_ErrBlkSize		b %01100001
			b $30,$8f
:dlg80_04a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "SCSI-Blockgröße ungültig!",NULL
::102			b "(Entspricht nicht 512 Bytes)",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "SCSI block size not valid!",NULL
::102			b "(Does not match 512 Bytes)",NULL
endif

;*** Fehler: Partitionsfehler.
:Dlg_ErrRdPart		b %01100001
			b $30,$8f
:dlg80_02a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Fehler beim einlesen der",NULL
::102			b "Partitionstabelle!",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Error reading partition table!",NULL
::102			b "",NULL
endif

;*** Fehler: Keine Systempartition.
:Dlg_ErrSysPart		b %01100001
			b $30,$8f
:dlg80_05a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b OK         ,$01,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Keine Systempartition gefunden!",NULL
::102			b "(CREATE.SYS nicht ausgeführt?)",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "No system partition found!",NULL
::102			b "(CREATE.SYS not run?)",NULL
endif

;*** Info: Medium einlegen.
:Dlg_InsertMedia	b %01100001
			b $30,$8f
:dlg80_06a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$30
			w :102
			b OK         ,$01,$48
			b CANCEL     ,$11,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Bitte Medium in Laufwerk einlegen!",NULL
::102			b "Zum Menü zurück mit <ABBRUCH>.",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Please insert media in device!",NULL
::102			b "Back to menu with <CANCEL>.",NULL
endif

;*** Fehler: Laufwerksfehler.
:Dlg_DiskError		b %01100001
			b $30,$8f
:dlg80_03a		w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel1
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Error
			b DBTXTSTR   ,$0c,$20
			w :101
			b DBTXTSTR   ,$0c,$34
			w :102
			b OK         ,$11,$48
			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Es ist ein Fehler aufgetreten!",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "An error has occurred!",NULL
endif
::102			b "$"
;dlg_DskErrTxt		b "00",NULL
:dlg_DskErrTxt		b "00:"
			s 18*2
			b NULL

;*** InfoBox: Suche SCSI-Laufwerke.
:IBox_Searching		b %01100001
			b $40,$6f
:dlg80_08a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

if TESTUI=TRUE
			b DB_USR_ROUT
			w wait1Second
endif
if TESTUI=FALSE
			b DB_USR_ROUT
			w callFindSCSI
endif
			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Suche SCSI-Laufwerke...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Searching for SCSI devices...",NULL
endif

;*** InfoBox: Suche System-Partition.
:IBox_FindSysP		b %01100001
			b $40,$6f
:dlg80_09a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

if TESTUI=TRUE
			b DB_USR_ROUT
			w wait1Second
endif
if TESTUI=FALSE
			b DB_USR_ROUT
			w callFindSysP
endif

			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Suche System-Partition...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Searching system partition...",NULL
endif

;*** InfoBox: Partitionen einlesen.
:IBox_ReadPTab		b %01100001
			b $40,$6f
:dlg80_07a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

if TESTUI=TRUE
			b DB_USR_ROUT
			w wait1Second
endif
if TESTUI=FALSE
			b DB_USR_ROUT
			w callReadPTab
endif
			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Partitionen einlesen...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Reading partition data...",NULL
endif

;*** InfoBox: Verzeichnis einlesen.
:IBox_ReadDir		b %01100001
			b $40,$6f
:dlg80_10a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

if TESTUI=TRUE
			b DB_USR_ROUT
			w wait1Second
endif
if TESTUI=FALSE
			b DB_USR_ROUT
			w callReadDir
endif
			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Verzeichnis einlesen...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Reading directory...",NULL
endif

;*** InfoBox: Partition kopieren.
:IBox_CopyPart		b %01100001
			b $40,$77
:dlg80_11a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

			b DB_USR_ROUT
			w callCopyPart

			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Partition wird kopiert...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Copying partition...",NULL
endif

;*** InfoBox: Größe NM anpassen.
:IBox_UpdateNM		b %01100001
			b $40,$77
:dlg80_12a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

			b DB_USR_ROUT
			w callUpdateNM

			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Partitionsgröße anpassen...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Updating partition size...",NULL
endif

;*** InfoBox: Partition aktualisieren.
:IBox_UpdPData		b %01100001
			b $40,$77
:dlg80_13a		w $0050,$00ef

			b DB_USR_ROUT
			w Dlg_DrawTitel2

			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w :101

			b DB_USR_ROUT
			w callUpdPData

			b DB_USR_ROUT
			w IBoxInit

			b NULL

;--- Dialogbox-Texte.
if LANG = LANG_DE
::101			b PLAINTEXT
			b "Partitionsdaten aktualisieren...",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "Updating partition data...",NULL
endif

;******************************************************************************
;*** Hauptprogramm
;******************************************************************************
:MainInit		ldy	#$00			;Anpassung C64/C128 und
			bit	c128Flag		;40/80-Zeichen-Modus.
			bpl	:1
			bit	graphMode		;Bildschirmmodus einlesen.
			bpl	:2			; => 40-Zeichen.
			ldy	#$80			; => 80-Zeichen.
::2			sty	DB_DblBit		;Icons verdoppeln.
::1			sty	curScrnMode		;Aktueller Bildschirm-Modus.

			jsr	InitDBoxData		;Dialogboxen anpassen.

;--- Test des UI:
;Aufruf aller Dialogboxen zum testen
;der Größe/Position in 40/80-Zeichen.
if TESTDLG=TRUE
			jsr	testDlgBoxUI		;Dialogboxen testen.
endif

;--- Auf GEOS/MegaPatch testen.
			jsr	Test_GEOS_MP		;Auf GEOS/MegaPatch testen.
			txa				;Fehler?
			beq	MainProg		; => Nein, weiter...
			jmp	EnterDeskTop		;Programm beenden.

;--- Bildschirm initialisieren.
:MainProg		jsr	GetBackScreen		;Hintergrundbild laden.

if TESTUI=TRUE
;--- CMD-HD festlegen.
			ldx	#10			;Für TestUI:
			jmp	drive_found		;Laufwerksadresse festlegen.
endif

if TESTUI=FALSE
;--- CMD-HD suchen/SCSI abfragen.
			jsr	findDevCMDHD		;CMD-HD unter GEOS suchen.
			cpx	#$00			;Laufwerk gefunden? XReg=Adresse.
			bne	drive_found		; => Ja, weiter...
endif

;--- Keine CMD-HD gefunden.
:err_no_cmdhd		LoadW	r0,Dlg_ErrorNoHD	;Fehler: Keine CMD-HD.
			jsr	DoDlgBox		;Fehlermeldung ausgeben.

;--- Zurück zum DeskTop.
:ExitRegMenu		jmp	EnterDeskTop		;Zurück zum DeskTop.

;--- Laufwerk mit SCSI-Geräten gefunden.
:drive_found		stx	devAdrHD		;Adresse CMD-HD sichern.

			jsr	initDevInfo		;"Suche SCSI-Laufwerke..."
			txa				;Laufwerksfehler?
			beq	:initSrcData		; => Nein, weiter...

			jsr	findDevCMDHD		;CMD-HD unter GEOS suchen.
			cpx	#$00			;Neue CMD-HD gefunden?
			beq	err_no_cmdhd		; => Nein, Abbruch...
			bne	drive_found		;Adresse CMD-HD sichern.

;--- SCSI: Quelle einlesen.
::initSrcData		jsr	initDevSrcID		;SCSI-Gerätedaten/Quelle einlesen.

			jsr	initDevSrcPTab		;Partitionen einlesen.
			ldx	devErrorHD		;Fehler aufgetreten?
			beq	:initTgtData		; => Nein, weiter...
			jsr	rdPTabError		; => Fehlermeldung ausgeben.
			lda	#NOTREADY		;Flag setzen: Laufwerk nicht bereit.
			sta	cmdPartSrcRdy

;--- SCSI: Ziel einlesen.
::initTgtData		jsr	initDevTgtID		;SCSI-Gerätedaten/Ziel einlesen.

			jsr	initDevTgtPTab		;Partitionen einlesen.
			ldx	devErrorHD		;Fehler aufgetreten?
			beq	doRegMenu		; => Nein, weiter...
			jsr	rdPTabError		; => Fehlermeldung ausgeben.
			lda	#NOTREADY		;Flag setzen: Laufwerk nicht bereit.
			sta	cmdPartTgtRdy

;*** Registermenü initialisieren.
:doRegMenu		jsr	SetADDR_Register	;Register-Routine einlesen.
			jsr	FetchRAM

			jsr	RegisterSetFont		;Register-Font aktivieren.

			bit	curScrnMode		;Bildschirm-Modus abfragen.
			bpl	:40			; => 40-Zeichen, weiter...

;--- Register-Menü 80Z starten.
::80			LoadW	r0,RegMenu80		;Zeiger auf 80-Zeichen-Menü.
			jsr	DoRegister		;Register-Menü starten.

;--- Icon-Menü "Beenden" 80Z starten.
			lda	IconExitPos80 +0	;X-Position für Farbe.
			sta	:x80

			lda	IconExitPos80 +1	;Y-Position für Farbe.
			lsr				;In CARDs umrechnen.
			lsr
			lsr
			sta	:y80

			lda	C_RegisterExit80	;Farbe für "X"-Icon setzen.
			jsr	i_UserColor
::x80			b	(R80SizeX0/8) +1
::y80			b	(R80SizeY0/8) -1
			b	IconExit_x ! DOUBLE_B
			b	IconExit_y/8

			LoadW	r0,IconMenu80		;Zeiger auf "X"-Icon-Menü.
			jmp	DoIcons			;Icon-Menü aktivieren.

;--- Register-Menü 40Z starten.
::40			LoadW	r0,RegMenu40		;Zeiger auf 40-Zeichen-Menü.
			jsr	DoRegister		;Register-Menü starten.

;--- Icon-Menü "Beenden" 40Z starten.
			lda	IconExitPos40 +0	;X-Position für Farbe.
			sta	:x40

			lda	IconExitPos40 +1	;Y-Position für Farbe.
			lsr				;In CARDs umrechnen.
			lsr
			lsr
			sta	:y40

			lda	C_RegisterExit40	;Farbe für "X"-Icon setzen.
			jsr	i_UserColor
::x40			b	(R40SizeX0/8) +1
::y40			b	(R40SizeY0/8) -1
			b	IconExit_x
			b	IconExit_y/8

			LoadW	r0,IconMenu40		;Zeiger auf "X"-Icon-Menü.
			jmp	DoIcons			;Icon-Menü aktivieren.

;*** Fehler beim einlesen der Partitionen.
:rdPTabError		txa
			pha
			LoadW	r0,Dlg_ErrRdPart	;Fehler: Partitionen einlesen.
			jsr	DoDlgBox		;Fehlermeldung ausgeben.
			pla
			tax
;			jmp	systemError		;Diskfehler ausgeben.

;*** Systemfehler ausgeben.
;Übergabe: XReg = Fehler-Code.
:systemError		txa				;Fehler-Code nach ASCII wandeln.
			jsr	HEX2ASCII
			stx	dlg_DskErrTxt +0	;Fehler-Code in Dialogbox
			sta	dlg_DskErrTxt +1	;eintragen.
			lda	#NULL
			sta	dlg_DskErrTxt +2

			LoadW	r0,Dlg_DiskError
			jmp	DoDlgBox		;Fehlermeldung ausgeben.

;*** Partition kopieren.
:doStartCopy		bit	cmdPartSrcRdy		;Quell-Laufwerk bereit?
			bpl	:exit			; => Nein, Abbruch...
			bit	cmdPartTgtRdy
			bpl	:exit			; => Nein, Abbruch...
			lda	cmdPartSrc
			beq	:exit			; => Nein, Abbruch...
			lda	cmdPartTgt
			beq	:exit			; => Nein, Abbruch...
			lda	cmdPartSrcTyp		;Partitionstyp für Quell und
			cmp	cmdPartTgtTyp		;Ziel identisch?
			beq	:init			; => Ja, weiter...
::exit			rts				;Abbruch.

::init			lda	#$00			;Fehlerstatus löschen.
			sta	devErrorHD

if TESTUI=FALSE
			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	scsiSrcID		;SCSI-ID Quelle einlesen und
			sta	scsiComID		;als aktuelle SCSI-ID festlegen.

			jsr	scsiSendREADY		;Laufwerk bereit?
			bmi	:init_error		; => Laufwerk nicht vorhanden.
			beq	:ok			; => Laufwerk bereit.

			jsr	scsiSendSTART		;Geparkte HDD aktivieren.

			jsr	scsiSendREADY		;Laufwerk bereit?
			bne	:init_error		; => Laufwerk nicht bereit.

::ok			lda	scsiTgtID		;SCSI-ID Ziel einlesen und
			sta	scsiComID		;als aktuelle SCSI-ID festlegen.

			jsr	scsiSendREADY		;Laufwerk bereit?
			beq	:init_ok		; => Ja, weiter...

			jsr	scsiSendSTART		;Geparkte HDD aktivieren.
			jsr	scsiSendREADY		;Laufwerk bereit?
			bne	:init_error		; => Laufwerk nicht bereit.

::init_ok		ldx	#gScErr_OK		;Laufwerk bereit.
			b $2c
::init_error		ldx	#gScErr_DevNotRdy	;Laufwerk nicht bereit.

			jsr	DoneWithIO		;I/O-Bereich abschalten.
			txa				;Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...
endif
			ldx	#$00			;Flag löschen: Größe NativeMode
			stx	updateNative		;Partition korrigieren.

			lda	cmdPartSrcTyp		;Partitionstyp für Quell und
			cmp	#cmdPartNative		;Type NativeMode?
			bne	:3			; => Nein, weiter...

			ldx	cmdPartSrcSize +0	;Partitionsgröße prüfen.
			cpx	cmdPartTgtSize +0	;Erlaubt ist kleinere oder gleich
			bcc	:2			;große Partitionen zu kopieren.
			beq	:1
			bcs	:exit			; => Groß nach klein, Abbruch...
::1			lda	cmdPartSrcSize +1
			cmp	cmdPartTgtSize +1
			beq	:3			; => Gleich groß...
			bcs	:exit			; => Groß nach klein, Abbruch...

::2			lda	cmdPartTgtSize +1	;Größe der NativeMode-Partition
			asl				;aus High/Low der SCSI-Blockzahl
			lda	cmdPartTgtSize +0	;ermitteln.
			rol
			sta	updateNative		;Anzahl Spuren in Partition.

::3			lda	#$00			;Flag löschen: Aktive Partition
			sta	activePart		;aktualisieren.

			lda	scsiDevCurID		;Aktuelle ID der CMD-HD =
			cmp	scsiTgtID		;Ziel-Laufwerk?
			bne	:4			; => Nein, weiter...
if TESTUI=TRUE
			lda	cmdPartTgt		;Für TestUI:
			sta	activePart		;Ziel-Partition als Aktiv setzen.
endif
if TESTUI=FALSE
			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.
			jsr	getActivePart		;Aktiev Partition einlesen.
			jsr	DoneWithIO		;I/O-Bereich abschalten.
endif
::4			lda	scsiSrcID		;Quell-ID für SCSI-READ setzen.
			sta	scsiREAD_id
			lda	scsiTgtID		;Ziel-ID für SCSI-WRITE setzen.
			sta	scsiWRITE_id

			ldy	#02			;Start-Adresse der Quelle/Ziel
::10			lda	cmdPartSrcAdr,y		;Partition in SCSI-Befehle
			sta	scsiREAD_adr +1,y	;übertragen.
			lda	cmdPartTgtAdr,y
			sta	scsiWRITE_adr +1,y
			dey
			bpl	:10

			lda	cmdPartSrcSize +0	;Partitionsgröße einlesen.
			sta	copySize +0 		;Hinweis:
			lda	cmdPartSrcSize +1	;SCSI-Format verwendet High/Mid/Low
			sta	copySize +1		;Format, nicht Low/High!

			lda	#> $0010		;Größe SCSI-Kopierpuffer:
			sta	sectorCount +0		;16 x 512 Bytes = 8192 Bytes.
			lda	#< $0010		;Der Puffer reicht von $3000-$4FFF.
			sta	sectorCount +1

			lda	#$00			;Fortschrittsanzeige initialisieren.
			sta	statusPos

			ldx	cmdPartSrcTyp		;Partitionsformat einlesen.
			cpx	#$08			;Modus #0 bis #7.
			bcs	:errPartFrmt
			lda	statusCount,x		;Anzahl Kopiervorgänge einlesen.
			bne	:set_count		; => Größer 0, weiter...
::errPartFrmt		ldx	#gScErr_PartFrmt	;Fehler: Unbekanntes Format.
			jmp	:error			;Abbruch

::set_count		sta	statusMode		;Zähler-Modus speichern.
			cmp	#255			;NativeMode ?
			bne	:11			; => Nein, weiter...
			lda	copySize +1		;Max. High-Byte = $80 (FOREIGN):
			asl				;$8000 * 512 = 16.384Kb
			lda	copySize +0		;Max. Wert = $80*2 > $100.
			rol
			cmp	#$00			;Überlauf?
			bne	:11			; => Nein, weiter...
			lda	#$ff			;Status von 0-255.
::11			sta	statusMax		;Max. Status-Wert speichern.

			LoadW	r0,IBox_CopyPart	;InfoBox: Partition kopieren.
			jsr	DoDlgBox		;Startet auch den Kopiervorgang!

			ldx	devErrorHD		;Fehler aufgetreten?
			bne	senseError		; => Ja, Abbruch...

			lda	cmdPartSrcTyp
			cmp	#cmdPartNative		;Ziel-Partiton Typ NativeMode?
			bne	:21			; => Nein, weiter...

;--- Größe NativeMode-Partition korrigieren.
			lda	updateNative		;Partitionsgröße korrigieren?
			beq	:21			; => Nein, weiter...

::update1		LoadW	r0,IBox_UpdateNM	;InfoBox: Partitionsgröße anpassen.
			jsr	DoDlgBox		;Anpassung wird dabei ausgeführt.

			ldx	devErrorHD		;Fehler aufgetreten?
			bne	:error			; => Ja, Abbruch...

;--- Partitionsdaten im RAM der CMD-HD aktualisieren.
::21			lda	scsiDevCurID		;Aktuelle ID der CMD-HD =
			cmp	scsiTgtID		;Ziel-Laufwerk?
			bne	:done			; => Nein, weiter...

			lda	activePart		;Aktive Partition aktualisieren?
			beq	:done			; => Nein, weiter...

::update2		LoadW	r0,IBox_UpdPData	;InfoBox: Partition aktualisieren.
			jsr	DoDlgBox		;Wird dadurch auch ausgeführt...

			ldx	devErrorHD		;Fehler aufgetreten?
			bne	:error			; => Ja, Abbruch...
::done			rts				;Kein Fehler, Ende.

::error			jmp	systemError		;Fehlermeldung ausgeben.

;*** Systemfehler ausgeben.
;Übergabe: devErrorHD    = Fehler-Code.
;          scsiSENSE_buf = SCSI Fixed Sense Data.
:senseError		lda	devErrorHD		;Fehler-Code nach ASCII wandeln.
			jsr	HEX2ASCII
			stx	dlg_DskErrTxt +0	;Fehler-Code in Dialogbox
			sta	dlg_DskErrTxt +1	;eintragen.
			lda	#":"
			sta	dlg_DskErrTxt +2

			ldx	#0			;"Fixed Sense Data" nach ASCII
			ldy	#3			;wandeln und in DialogBox schreiben.
::1			txa
			pha
			lda	scsiSENSE_buf,x
			jsr	HEX2ASCII
			sta	dlg_DskErrTxt+1,y	;Fehler-Code in Dialogbox
			txa				;eintragen.
			sta	dlg_DskErrTxt+0,y
			iny
			iny
			pla
			tax
			inx
			cpx	#14			;Die ersten 14 Byte übertragen?
			bcc	:1			; => Nein, weiter...

			LoadW	r0,Dlg_DiskError
			jmp	DoDlgBox		;Fehlermeldung ausgeben.

;*** InfoBox: Partition kopieren.
:callCopyPart		jsr	sysPrntStatBar		;Fortschrittsanzeige initialisieren.

			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

;--- 16 x 512B-Block kopieren.
;Die Daten werden dabei in den internen
;SCSI-Buffer der CMD-HD eingelesen und
;von dort direkt auf das Ziel-Gerät
;kopiert. Adresse/Größe im Format LBA
;(Reverse Byte Order!)
::loop			lda	sectorCount +0		;Anzahl zu kopierende Sektoren
			ldx	sectorCount +1		;einlesen (Standard = 16).

			cmp	copySize +0		;Mit verbleibender Anzahl an
			bcc	:11			;Sektoren vergleichen.
			cpx	copySize +1		;HighByte=0, LowByte vergleichen.
			bcc	:11			; => kleiner, weiter...

			lda	copySize +0		;Max. 16 Sektoren verbleibend
			ldx	copySize +1		;zum kopieren.

;--- Anzahl 512-Byte-Blocks.
::11			sta	scsiREAD_count +0	;Anzahl Sek. für SCSI-Befehle.
			sta	scsiWRITE_count +0
			stx	scsiREAD_count +1
			stx	scsiWRITE_count +1

if TESTUI=FALSE
			jsr	scsiSendREAD		;SCSI-Befehl "READ" senden.
			bcc	:12			; => Kein Fehler, weiter...
			bmi	:errRdNotRdy		; => Laufwerksfehler, Abbruch...
			jsr	scsiSendREAD		;SCSI-Befehl "READ" wiederholen.
			bcc	:12
::errRdNotRdy		jmp	:errRdSCSI		; => Lesefehler.

::12			jsr	scsiSendWRITE		;SCSI-Befehl "WRITE" senden.
			bcc	:13			; => Kein Fehler, weiter...
			bmi	:errWrNotRdy		; => Laufwerksfehler, Abbruch...
			jsr	scsiSendWRITE		;SCSI-Befehl "WRITE" wiederholen.
			bcc	:13
::errWrNotRdy		jmp	:errWrSCSI		; => Schreibfehler.
endif

::13			jsr	DoneWithIO		;I/O-Bereich abschalten.

			lda	statusMode		;Zähler-Modus einlesen.
			cmp	#255			;NativeMode?
			beq	:13a			; => Ja, weiter...

;--- 1541/71/81/81CPM
			lda	statusPos		;Status +1 Durchlauf.
			cmp	statusMax		;Ende erreicht?
			beq	:13b			; => Ja, nicht ändern.
			clc
			adc	#$01
			sta	statusPos
			bne	:13b

;--- Native/Foreign/PrintBuf
::13a			lda	statusMax		;Aktuellen Status korrigieren.
			lsr				;Max.Tracks - Tracks übrig
			sec				;= aktuelle Position.
			sbc	copySize +0
			bcc	:13b			; => Unterlauf bei 16Mb-Partition.
			asl
			sta	statusPos

::13b			jsr	sysPrntStatus		;Fortschrittsanzeige aktualisieren.
			jsr	InitForIO		;I/O-Bereich aktivieren.

if TESTUI=TRUE
			jsr	SCPU_Pause		;TestUI: Verzögerung.
endif

			lda	scsiREAD_adr +3		;Aktuelle Quell-Adresse korrigieren.
			clc
			adc	sectorCount +1
			sta	scsiREAD_adr +3
			lda	scsiREAD_adr +2
			adc	sectorCount +0
			sta	scsiREAD_adr +2
			lda	scsiREAD_adr +1
			adc	#$00
			sta	scsiREAD_adr +1

			lda	scsiWRITE_adr +3	;Aktuelle Ziel-Adresse korrigieren.
			clc
			adc	sectorCount +1
			sta	scsiWRITE_adr +3
			lda	scsiWRITE_adr +2
			adc	sectorCount +0
			sta	scsiWRITE_adr +2
			lda	scsiWRITE_adr +1
			adc	#$00
			sta	scsiWRITE_adr +1

			lda	copySize +1		;Anzahl verbleibende 512B-Blocks
			sec				;korrigieren.
			sbc	sectorCount +1
			sta	copySize +1
			lda	copySize +0
			sbc	sectorCount +0
			sta	copySize +0
			bcc	:done
			ora	copySize +1		;Alle Sektoren kopiert?
			beq	:done			; => Ja, Ende...
			jmp	:loop			; => Weitere Sektoren kopieren.

::done			jsr	DoneWithIO		;I/O-Bereich abschalten.

			lda	statusMax
			sta	statusPos
			jsr	sysPrntStatus		;Fortschritsanzeige aktualisieren.

			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	wait1Second		;Verzögerung.

			ldx	#gScErr_OK		;Kein Fehler.
			beq	:exit

::errRdSCSI		lda	#gScErr_CopyRdSek	;Fehler: Sektoren lesen.
			b $2c
::errWrSCSI		lda	#gScErr_CopyWrSek	;Fehler: Sektoren schreiben.
			pha
if TESTUI=FALSE
			jsr	scsiSendSENSE		;Fehler-Status abfragen.
endif
			pla
			tax
::exit			stx	devErrorHD		;Fehler-Code speichern.
			jmp	DoneWithIO		;I/O-Bereich abschalten.

;*** InfoBox: Größe NM anpassen.
:callUpdateNM		jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	cmdPartTgtAdr +2	;Zeiger auf den 2ten 512B-Sektor
			clc				;berechnen. Der Sektor beinhaltet
			adc	#$01			;Die Blocks #01/02 und #01/03.
			sta	scsiREAD_adr +3		;Im Block #01/02 steht die Anzahl
			sta	scsiWRITE_adr +3	;der Spuren in der Partition.
			lda	cmdPartTgtAdr +1
			adc	#$00
			sta	scsiREAD_adr +2
			sta	scsiWRITE_adr +2
			lda	cmdPartTgtAdr +0
			adc	#$00
			sta	scsiREAD_adr +1
			sta	scsiWRITE_adr +1

			lda	scsiTgtID		;Neue SCSI-ID einlesen und
			sta	scsiREAD_id		;für SCSI-Befehl "READ" und
			sta	scsiWRITE_id		;SCSI-Befehl "WRITE" speichern.

			lda	#<scsiBufAdr		;Adresse SCSI-Puffer festlegen.
			sta	scsiREAD_mradr +0
			lda	#>scsiBufAdr
			sta	scsiREAD_mradr +1

if TESTUI=FALSE
;--- Hinweis:
;Zum testen wird der gesamte 256B-Block eingelesen, damit die Werte im
;Speicher im DEBUG-Modus überprüft werden können.
;Ein SCSI-READ-Befehl wäre ausreichend, da nur ein Byte geändert wird.
			jsr	rd256ByteBlk		;SCSI-Befehl "READ".
			txa				;Laufwerksfehler?
			bne	:update_error		; => Ja, Abbruch...

			lda	#<comWRSIZE		;Laufwerksbefehl "M-R".
			ldx	#>comWRSIZE		;Der Sektor liegt ab ":scsiBufAdr"
			ldy	#7			;(= $3000) im RAM der CMD-HD.
			jsr	sendCom
			bcs	:update_error		; => Laufwerksfehler.

			jsr	scsiSendWRITE		;SCSI-Befehl "WRITE" senden.
			bcs	:update_error		; => Laufwerksfehler.
endif

			jsr	wait1Second		;Verzögerung, damit InfoBox lesbar.

			ldx	#gScErr_OK		;Kein Fehler.
			b $2c
::update_error		ldx	#gScErr_UpdNM		;Update-NativeMode-Fehler.
			stx	devErrorHD

			jmp	DoneWithIO		;I/O-Bereich abschalten.

;*** InfoBox: Partition aktualisieren.
;Dabei wird die BAM im Cache der CMD-HD
;aktualisiert.
:callUpdPData		jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

if TESTUI=FALSE
::update		lda	#<comSETPART		;Floppy-Befehl "C-P".
			ldx	#>comSETPART
			ldy	#3
			jsr	sendCom
			bcs	:update_error		; => Laufwerksfehler.

			lda	#<comINIT		;Floppy-Befehl "I0:".
			ldx	#>comINIT
			ldy	#3
			jsr	sendCom
			bcs	:update_error		; => Laufwerksfehler.
endif

			jsr	wait1Second		;Verzögerung, damit InfoBox lesbar.

			ldx	#gScErr_OK		;Kein Fehler.
			b $2c
::update_error		ldx	#gScErr_UpdPart		;Update-PartInfo-Fehler.
			jmp	DoneWithIO		;I/O-Bereich abschalten.

;*** Fortschrittsanzeige.
;    Übergabe:  statusPos = Aktueller Eintrag.
;               statusMax = Max. Anzahl Einträge.
;    Variablen: STATUS_X      = Status-Box links.
;               STATUS_W      = Breite Status-Box.
;               STATUS_Y      = Status-Box oben.
;               STATUS_H      = Höhe Status-Box.
;               STATUS_CNT_W  = Breite Fortschrittsanzeige.
;               STATUS_CNT_X1 = Fortschrittsanzeige links.
;               STATUS_CNT_X2 = Fortschrittsanzeige rechts.
;               STATUS_CNT_Y1 = Fortschrittsanzeige oben.
;               STATUS_CNT_Y2 = Fortschrittsanzeige unten.
;--- Variablen für Status-Box:
;Größe Infoxbox:	b $40,$77
;			w $0050,$00ef
:STATUS_X		= $0050
:STATUS_W		= $00ef - STATUS_X +1
:STATUS_Y		= $40
:STATUS_H		= $77   - STATUS_Y +1

;--- Fortschrittsbalken.
:STATUS_CNT_X1		= STATUS_X +16
:STATUS_CNT_X2		= (STATUS_X + STATUS_W) -24 -1
:STATUS_CNT_W		= (STATUS_CNT_X2 - STATUS_CNT_X1) +1
:STATUS_CNT_Y1		= (STATUS_Y + STATUS_H) -16
:STATUS_CNT_Y2		= (STATUS_Y + STATUS_H) -16 +8 -1

;*** Fortschrittsanzeige aktualisieren.
:sysPrntStatus		ldx	statusPos		;Erster Eintrag?
			bne	:2			; => Nein, weiter...
::1			rts				; => Ja, nur Werte ausgeben.

;--- Speicherübersicht ausgeben.
::2			inx
			cpx	statusMax		;Mehr als ein Eintrag?
			bne	:3			; => Ja, weiter...

			lda	#$00
			sta	r8L			;Rest-Wert für %-Balken löschen
			sta	r8H			;für "Ganzen %-Balken füllen".
			beq	:4			;Fortschrittsanzeige darstellen.

;--- Prozentwert für Fortschrittsanzeige berechnen.
::3			LoadW	r3,STATUS_CNT_W
			MoveB	statusPos,r5L
			ldx	#r3L
			ldy	#r5L
			jsr	BMult			;Breite_Balken * Position.

			MoveB	statusMax,r5L
			LoadB	r5H,0
			ldx	#r3L
			ldy	#r5L
			jsr	Ddiv			;(Breite_Balken * Position)/Gesamt.

			lda	r3L			;Prozentwert = 0?
			ora	r3H
			beq	:1			; => Ja, nichts ausgeben.

			lda	r3L			;Füllwert für Fortschrittsanzeige
			clc				;berechnen.
			adc	#< STATUS_CNT_X1
			sta	r4L
			lda	r3H
			adc	#> STATUS_CNT_X1
			sta	r4H

			CmpWI	r4,STATUS_CNT_X2	;Füllwert > Breite_Balken?
			bcc	:5			; => Nein, weiter...

::4			LoadW	r4,STATUS_CNT_X2	;Max. Breite Füllwert setzen.

::5			lda	r8L			;Restwert = 0?
			ora	r8H
			beq	:6			; => Ja, weiter...

			CmpW	r4,STATUS_CNT_X2	;Fortschrittsbalken aktualisieren.
			bne	:6

			SubVW	3,r4			;Füllwert reduzieren. 100% noch
							;nicht erreicht, daher nicht den
							;ganzen Infobalken füllen.

::6			LoadB	r2L,STATUS_CNT_Y1
			LoadB	r2H,STATUS_CNT_Y2
			LoadW	r3,STATUS_CNT_X1

			bit	curScrnMode		;40Z-Bildschirm-Modus?
			bpl	:40			; => Ja, weiter...

			lda	r3H 			;80Z-Modus:
			ora	#>DOUBLE_W		;X-Koordinaten verdoppeln.
			sta	r3H
			lda	r4H
			ora	#$00 ! $80 ! $20	;>DOUBLE_W ! >ADD1_W
			sta	r4H

::40			lda	#$02			;Füllmuster setzen.
			jsr	SetPattern

			jmp	Rectangle		;Fortschrittsanzeige.

;*** Status-Box mit Fortschrittsbalken.
:sysPrntStatBar		LoadB	r2L,STATUS_CNT_Y1 -1
			LoadB	r2H,STATUS_CNT_Y2 +1
			LoadW	r3,STATUS_CNT_X1 -1
			LoadW	r4,STATUS_CNT_X2 +1

			bit	curScrnMode		;40Z-Bildschirm-Modus?
			bpl	:40a			; => Ja, weiter...

			lda	r3H 			;80Z-Modus:
			ora	#>DOUBLE_W		;X-Koordinaten verdoppeln.
			sta	r3H
			lda	r4H
			ora	#$00 ! $80 ! $20	;>DOUBLE_W ! >ADD1_W
			sta	r4H

::40a			lda	#%11111111
			jsr	FrameRectangle		;Rahmen um Fortschrittsanzeige.

			LoadB	r2L,STATUS_CNT_Y1
			LoadB	r2H,STATUS_CNT_Y2
			LoadW	r3,STATUS_CNT_X1
			LoadW	r4,STATUS_CNT_X2

			bit	curScrnMode		;40Z-Bildschirm-Modus?
			bpl	:40b			; => Ja, weiter...

			lda	r3H 			;80Z-Modus:
			ora	#>DOUBLE_W		;X-Koordinaten verdoppeln.
			sta	r3H
			lda	r4H
			ora	#$00 ! $80 ! $20	;>DOUBLE_W ! >ADD1_W
			sta	r4H

::40b			jsr	Rectangle		;Fortschrittsanzeige löschen.

			lda	C_InputField		;Farbe für Fortschrittsanzeige.
			jsr	DirectColor

			LoadW	r11,STATUS_CNT_X1 -14
			LoadB	r1H,STATUS_CNT_Y1 +6

			bit	curScrnMode		;40Z-Bildschirm-Modus?
			bpl	:40c			; => Ja, weiter...

			AddVW	2,r11			;80Z: X-Koordinate korrigieren.

			lda	r11H 			;80Z-Modus:
			ora	#>DOUBLE_W		;X-Koordinaten verdoppeln.
			sta	r11H

::40c			LoadW	r0,infoTx0pct		;Text "0%" ausgeben.
			jsr	PutString

			LoadW	r11,STATUS_CNT_X2 +3
			LoadB	r1H,STATUS_CNT_Y1 +6

			bit	curScrnMode		;40Z-Bildschirm-Modus?
			bpl	:40d			; => Ja, weiter...

			AddVW	4,r11			;80Z: X-Koordinate korrigieren.

			lda	r11H 			;80Z-Modus:
			ora	#>DOUBLE_W		;X-Koordinaten verdoppeln.
			sta	r11H

::40d			LoadW	r0,infoTx100pct		;Text "100%" ausgeben.
			jmp	PutString

;*** Verzeichnis anzeigen.

;--- Verzeichnis Quell-Laufwerk anzeigen.
:doDirSource		bit	cmdPartSrcRdy		;Quell-Laufwerk bereit?
			bpl	exitDirectory		; => Nein, Abbruch...

			jsr	findSrcPart		;Partition in Tabelle suchen.

			ldx	cmdPartSrcTyp		;Partitionstyp Quell-Laufwerk.
			ldy	scsiSrcID		;SCSI-ID Quell-Laufwerk.
			jmp	doDirectory		; => Weiter...

;--- Verzeichnis Ziel-Laufwerk anzeigen.
:doDirTarget		bit	cmdPartTgtRdy		;Ziel-Laufwerk bereit?
			bpl	exitDirectory		; => Nein, Abbruch...

			jsr	findTgtPart		;Partition in Tabelle suchen.

			ldx	cmdPartTgtTyp		;Partitionstyp Ziel-Laufwerk.
			ldy	scsiTgtID		;SCSI-ID Ziel-Laufwerk.
			jmp	doDirectory		; => Weiter...

:exitDirectory		rts

;*** Verzeichnis anzeigen.
:doDirectory		stx	dirPartType		;Partitionstyp speichern.
			sty	scsiREAD_id		;SCSI-ID speichern.

			cpx	#cmdPartNative		;Native?
			beq	:ok			; => Ja, weiter...
			cpx	#cmdPart1541		;1541?
			beq	:ok			; => Ja, weiter...
			cpx	#cmdPart1571		;1571?
			beq	:ok			; => Ja, weiter...
			cpx	#cmdPart1581		;1581?
			bne	exitDirectory		; => Nein, Abbruch...

::ok			lda	partFound
			cmp	#$ff			;Partition in Tabelle gefunden?
			beq	exitDirectory		; => Nein, Abbruch...
			jsr	setAdrPartData		;Zeiger auf Partitionsdaten.

;--- Startadresse der Partition kopieren.
;Im Partitionseintrag liegt die Adresse
;in Byte #2 - #4 als High/Mid/Low vor.
;Der SCSI-Befehl benötigt 4 Adr.-Bytes.
			ldy	#4
			lda	(r15L),y		;Low-Byte.
			sta	startPAdrLBA +3
			dey
			lda	(r15L),y		;Middle-Byte.
			sta	startPAdrLBA +2
			dey
			lda	(r15L),y		;High-Byte.
			sta	startPAdrLBA +1
			lda	#$00			;Nicht verwendet.
			sta	startPAdrLBA +0		;254 Part. a 16Mb = $7F:0000 Blocks.

			jsr	setSwapFileBuf		;Partitionsdaten in REU auslagern.
			jsr	StashRAM		;Wird für Verzeichnis benötigt.

if TESTUI=FALSE
			LoadW	r0,DATABUF_SIZE		;Speicherbereich löschen.
			LoadW	r1,dirFileDataBuf
			jsr	ClearRam

			jsr	i_MoveData		;Text "Leere Disk" in
			w	emptyDisk		;Verzeichnisdaten übertragen.
			w	dirFileDataBuf
			w	17
endif

			LoadW	r0,IBox_ReadDir		;InfoBox: Verzeichnis einlesen.
			jsr	DoDlgBox		;Wird dabei auch gleich eingelesen!

			LoadW	r0,Dlg_ShowDir		;MegaPatch-Dateiauswahlbox
			LoadW	r5,dirFileDataBuf	;zur Anzeige Verzeichnis-Inhalt.
			jsr	DoDlgBox

::1			jsr	setSwapFileBuf		;Partitionsdaten aus REU wieder
			jmp	FetchRAM		;einlesen und zurück zum Menü.

;*** Zeiger auf Speicher für SwapFile.
:setSwapFileBuf		LoadW	r0,dirFileDataBuf
			LoadW	r1,$0000		;Start SwapFile in REU.
			LoadW	r2,DATABUF_SIZE		;Größe Datenspeicher.
			lda	MP3_64K_DATA		;MegaPatch-Systemspeicherbank.
			sta	r3L
			rts

;*** Zeiger auf LBA-Sektor berechnen.
;Wandelt relative 256B-Block-Adresse in
;eine 512B-Sektor-Adresse um.
:convBLK2LBA		lda	dirPartType
			cmp	#cmdPartNative		;CMD-Typ: Native.
			bne	:1

;--- NativeMode.
::native		ldx	dirBlkTr		;Spur-Adresse korrigieren und
			dex				;als HighByte setzen.
			stx	curDirAdrBLK +1
			lda	dirBlkSe		;Sektor-Adresse als Low-Byte setzen.
			sta	curDirAdrBLK +0
			jmp	setDirAdrLBA		;Adresse umrechnen.

::1			ldx	#$00			;Block-Zähler löschen.
			stx	curDirAdrBLK +0
			stx	curDirAdrBLK +1

			cmp	#cmdPart1581		;CMD-Typ: Native.
			bne	:41_71

;--- 1581.
::1581			ldx	dirBlkTr		;Anzahl Spuren als Zähler setzen.
::10			dex				;Letzte Spur erreicht?
			beq	addSekToAdr		; => Ja, weiter...
			lda	curDirAdrBLK +0		;40 Blocks zu Zähler addieren.
			clc
			adc	#40
			sta	curDirAdrBLK +0
			bcc	:10
			inc	curDirAdrBLK +1
			bcs	:10			; => Weiter mit nächster Spur.

;--- 1541/1571.
::41_71			ldy	#$01
::20			cpy	dirBlkTr		;Aktuelle Spur = Gesuchte Spur?
			beq	addSekToAdr		; => Ja, weiter

			lda	curDirAdrBLK +0		;Blocks je Spur zu Zähler addieren.
			clc
			adc	SekPerTrack,y
			sta	curDirAdrBLK +0
			bcc	:21
			inc	curDirAdrBLK +1
::21			iny
			bne	:20			; => Weiter mit nächster Spur.

;*** Sektor-Adresse zu Block-Zähler addieren.
:addSekToAdr		lda	curDirAdrBLK +0		;Sektor-Adresse zu Zähler addieren.
			clc
			adc	dirBlkSe
			sta	curDirAdrBLK +0
			bcc	setDirAdrLBA
			inc	curDirAdrBLK +1

;*** 256B-Block-Adresse in 512B-LBA wandeln.
:setDirAdrLBA		lda	#$00			;Die oberen beiden Bytes der
			sta	curDirAdrLBA +0		;4-Byte-LBA-Adresse löschen.
			sta	curDirAdrLBA +1
			lda	curDirAdrBLK +1		;Block/2 = 512-Byte-LBA-Adresse.
			lsr
			sta	curDirAdrLBA +2
			lda	curDirAdrBLK +0
			ror
			sta	curDirAdrLBA +3
			ldx	#$00
			bcc	:1
			inx
::1			lda	#$00			;Offset für 256B-Block innerhalb
			sta	curSekOffset +0		;des 512B-Sektors festlegen.
			stx	curSekOffset +1

;*** Start-Adresse Partition zur relativen LBA-Addresse addieren.
:addPStartAdr		lda	curDirAdrLBA +3
			clc
			adc	startPAdrLBA +3
			sta	curDirAdrLBA +3
			lda	curDirAdrLBA +2
			adc	startPAdrLBA +2
			sta	curDirAdrLBA +2
			lda	curDirAdrLBA +1
			adc	startPAdrLBA +1
			sta	curDirAdrLBA +1
			lda	curDirAdrLBA +0
			adc	startPAdrLBA +0
			sta	curDirAdrLBA +0
			rts

;*** InfoBox: Verzeichnis einlesen.
:callReadDir		jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	dirPartType		;Partitionstyp in Zeiger auf
			sec				;Tabelle mit den Startadressen
			sbc	#$01			;des erstenn BAM-Sektor umrechnen.
			asl
			tax
			lda	dirStartSek +0,x	;Die Startadresse des ersten
			sta	curDirAdrLBA +3		;BAM-Sektors kann nur zwei-stellig
			lda	dirStartSek +1,x	;sein, da eine Partition mit 16Mb
			sta	curDirAdrLBA +2		;max. $7F80 512B-Sektoren umfasst.
			lda	#$00			;Ungenutze Bytes löschen.
			sta	curDirAdrLBA +1
			sta	curDirAdrLBA +0

			lda	dirBlkOffset +0,x	;Offset für BAM-Block innerhalb
			sta	curSekOffset +0		;des 512B-Sektors.
			lda	dirBlkOffset +1,x
			sta	curSekOffset +1

			jsr	addPStartAdr		;Startadresse Partition addieren.

			jsr	readBlkOffset		;256B-Block ab Offset lesen.
			txa				;Laufwerksfehler?
			bne	:errRdDirSek		; => Ja, Abbruch...

			lda	diskBlkBuf +0		;Zeiger auf ersten Verzeichnis-
			sta	dirBlkTr		;Sektor einlesen und speichern.
			lda	diskBlkBuf +1
			sta	dirBlkSe

			LoadW	r14,dirFileDataBuf

::nx_block		jsr	convBLK2LBA		;Block-Adresse LBA umrechnen.
			jsr	readBlkOffset		;256B-Block ab Offset lesen.
			txa				;Laufwerksfehler?
			bne	:errRdDirSek		; => Ja, Abbruch...

;			ldx	#$00			;Zeiger auf 256B-Block.
::nx_entry		lda	diskBlkBuf +2,x		;Eintrag definiert?
			beq	:5			; => Nein, weiter...

			ldy	#0			;Dateiname kopieren.
::1			lda	diskBlkBuf +5,x
			cmp	#$a0			;Ende erreicht?
			beq	:2			; => Ja, weiter...
			jsr	testChar		;Ungültige Zeichen filtern.
			sta	(r14L),y
			inx
			iny
			cpy	#16			;Ganzer Name kopiert?
			bcc	:1			; => Nein, weiter...

::2			lda	#$00			;Rest Dateiname inkl.
::3			sta	(r14L),y		;NULL-Byte löschen.
			iny
			cpy	#16 +1
			bcc	:3

			lda	r14L			;Zeiger auf Namensspeicher
			clc				;korrigieren.
			adc	#17
			sta	r14L
			bcc	:5
			inc	r14H
::5			txa				;XReg auf nächsten 32Byte-
			and	#%11100000		;Eintrag setzen.
			clc
			adc	#$20
			tax				;Alle Einträge durchsucht?
			bne	:nx_entry		; => Nein, weiter...

			ldx	diskBlkBuf +0		;Folgt weiterer Verzeichnisblock?
			beq	:done			; => Nein, Ende...
			stx	dirBlkTr
			lda	diskBlkBuf +1		;Zeiger auf nächsten Verzeichnis-
			sta	dirBlkSe		;block einlesen.
			jmp	:nx_block		; => Weitere Dateien einlesen.

::done			ldx	#gScErr_OK		;Kein Fehler.
			b $2c
::errRdDirSek		ldx	#gScErr_RdDirData	;Fehler: Verzeichnis einlesen.
			stx	devErrorHD		;Fehler-Code speichern.

			jmp	DoneWithIO		;I/O-Bereich abschalten.

;*** CMD-HD suchen.
;Hierbei wird nicht der serielle Bus
;durchsucht, sondern nur ":RealDrvType"
;von GEOS/MegaPatch ausgewertet.
;Ist in ":devAdrHD" bereits die Adresse
;einer CMD-HD (8-11) gespeichert, dann
;wird die Adresse ignoriert und eine
;weitere CMD-HD gesucht.
;Rückgabe: XREG = Adresse CMD-HD.
;                 $00 = Nicht vorhanden.
:findDevCMDHD		ldy	#4			;Max. 4 GEOS-Laufwerke prüfen.
			ldx	devAdrHD		;Aktuelles HD-Laufwerk einlesen.
			beq	:init			; => Nicht definiert, weiter...
::loop			inx				;Zeiger auf nächste Adresse.
			cpx	#12			;Ende erreicht?
			bcc	:1			; => Nein, weiter...
::init			ldx	#8			;Start Suche ab Laufwerk 8/A.
::1			cpx	devAdrHD		;Aktuelles Laufwerk?
			beq	:exit			; => Ja, keine HD gefunden.
			dey				;Alle Laufwerke durchsucht?
			bmi	:exit			; => Ja, keine HD gefunden.

			lda	driveType -8,x		;Laufwerk definiert?
			beq	:loop			; => Nein, weiter...
if TESTUI=FALSE
			bmi	:loop			; => RAM-Laufwerk...

			lda	RealDrvType -8,x	;RealDrvType einlesen.
			bmi	:loop			; => RAM-Laufwerk...
			and	#%00110000		;CMD-Bits isolieren.
			cmp	#%00100000		;CMD-HD?
			bne	:loop			; => Nein, weiter...
endif

			rts				;CMD-HD gefunden, Adr. in XReg.

::exit			ldx	#gScErr_OK		;Keine weitere CMD-HD gefunden.
			rts

;*** Nächstes SCSI-Gerät suchen.
;Übergabe: AKKU = Aktuelle SCSI-ID
;Rückgabe: AKKU = Neue SCSI-ID
:getNextSCSI		sta	r0L			;Aktuelle ID zwischenspeichern.
			tax
::1			inx				;Zeiger auf nächste ID.
			cpx	#$07			;NarrowSCSI max. SCSI-ID #0-#6.
			bcc	:2
			ldx	#$00			;Ab ID#0 weitersuchen.
::2			lda	scsiID,x
			cpx	r0L			;Alle IDs durchsucht?
			beq	:3			; => Ja, Ende...
			cmp	#$ff			;ID verfügbar?
			beq	:1			; => Nein, weiter...
::3			rts

;*** Geräteliste initialisieren.
;Übergabe: devAdrHD = Aktuelle CMD-HD.
;InfoBox : ":callFindSCSI"
:initDevInfo		LoadW	r0,IBox_Searching	;"Suche SCSI-Laufwerke..."
			jsr	DoDlgBox		;Infobox ausgeben/Suche starten.

			ldx	devErrorHD		;Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...

;--- SCSI-Geräteadressen festlegen.
if TESTUI=FALSE
			ldx	scsiDevCurID		;Aktuelle SCSI-ID als Quelle.
			lda	scsiID,x		;Gerätestatus abfragen.
			cmp	#$ff			;Laufwerk bereit?
			bne	:1			; => Ja, weiter...
			txa
			jsr	getNextSCSI		;Nächste SCSI-Adresse suchen.
			cmp	#$ff			;Laufwerk bereit?
			bne	:1			; => Ja, weiter...

			ldx	#gScErr_DevNotRdy	;Kein SCSI-Gerät angeschlossen.
			bne	:exit			; => Abbruch...

::1			sta	scsiSrcID		;SCSI-ID speichern.

			jsr	getNextSCSI		;Nächste SCSI-Adresse als Ziel.
			sta	scsiTgtID		;SCSI-ID speichern.
endif
if TESTUI=TRUE
			lda	#$00			;TestUI: Dummy ID festlegen.
			sta	scsiSrcID		;SCSI-ID Quelle.
			lda	#$05
			sta	scsiTgtID		;SCSI-ID Ziel.
endif

			ldx	#gScErr_OK
::exit			rts

;*** InfoBox: SCSI-Geräte suchen.
:callFindSCSI		lda	#$00			;Fehler-Flag löschen.
			sta	devErrorHD

			lda	devAdrHD
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler?
			bne	:error

			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	scsiGetCurID		;Aktuelle SCSI-ID einlesen.

			ldx	#$00
			stx	scsiDevCount		;Anzahl Geräte löschen.
::loop			stx	scsiComID		;Aktuelle SCSI-ID.

			lda	#$ff			;Gerätedaten zurücksetzen.
			sta	scsiID,x		; => SCSI-ID.
			sta	scsiIdent,x		; => Laufwerkstyp.
			sta	scsiRemovable,x		; => Wechselmedium.
							;Hinweis: Hersteller und Gerätename
							;muss nicht gelöscht werden, da nur
							;angezeigt wenn Gerät vorhanden.

			jsr	scsiSendREADY		;Laufwerk bereit?
			beq	:ok			; => Ja, weiter...
			bmi	:next			; => Laufwerk nicht vorhanden.

			jsr	scsiSendSTART		;Geparkte HDD aktivieren.

			jsr	scsiSendREADY		;Laufwerk bereit?
			bne	:skip			; => Kein Medium eingelegt.

::ok			jsr	scsiChkBlkSize		;Blockgröße testen/Größe einlesen.
			txa
			bne	:next			; => Kein Medium/Ungültig.

::skip			jsr	scsiSendINQUIRY		;Geräte-Informationen einlesen.
			bmi	:next

			inc	scsiDevCount		;Anzahl Laufwerke +1.
			jsr	getDevName		;Hersteller/Gerätename übernehmen.

::next			ldx	scsiComID
			inx				;Zeiger auf nächste ID.
			cpx	#7			;Alle IDs überprüft?
			bcs	:exit			; => Ja, Ende...
			jmp	:loop			; => Weitersuchen...

::exit			jsr	DoneWithIO		;I/O-Bereich abschalten.

;--- Kein Fehler.
			ldx	#gScErr_OK		;Kein Fehler.
			b $2c

;--- Fehler beim aktivieren der CMD-HD.
::error			ldx	#gScErr_FindSCSI	;Fehler: Laufwerk aktivieren.
			stx	devErrorHD		;Fehler-Flag setzen.
			rts

;******************************************************************************
;*** Verschiedene Unterprogramme
;******************************************************************************

;*** Auf GEOS-MegaPatch testen.
:Test_GEOS_MP		lda	MP3_CODE +0		;MegaPatch-Kennung prüfen.
			cmp	#"M"
			bne	:1
			lda	MP3_CODE +1
			cmp	#"P"
			beq	:2

::1			LoadW	r0,Dlg_NoMP		;Kein GEOS-MegaPatch.
			jsr	DoDlgBox		;Fehler ausgeben.

			ldx	#gScErr_NoMP		;Fehler -> Zurück zum DeskTop.
			b $2c
::2			ldx	#gScErr_OK		;Kein Fehler.
			rts

;*** Kein GEOS-MegaPatch.
:Dlg_NoMP		b $81

			b DBTXTSTR   ,$10,$10
			w Dlg_Titel_Error
			b DBTXTSTR   ,$10,$24
			w :101
			b DBTXTSTR   ,$10,$30
			w :102
			b CANCEL     ,$02,$48
			b NULL

if LANG = LANG_DE
::101			b PLAINTEXT
			b "Dieses Programm ist nur mit",NULL
::102			b "GEOS-MegaPatch V3 lauffähig!",NULL
endif
if LANG = LANG_EN
::101			b PLAINTEXT
			b "This program requires the",NULL
::102			b "GEOS-MegaPatch V3!",NULL
endif

;*** Titelzeile in Dialogbox löschen.
;Verwendet für allg. Dialogboxen.
:Dlg_DrawTitel1		lda	#$00			;Füllmuster setzen.
			jsr	SetPattern
			jsr	i_Rectangle		;Titelzeile löschen.
			b	$30,$3f
:dlg00T1		w	$0040,$00ff		;Wird durch :InitDBoxData angepasst.
			lda	C_DBoxTitel		;Farbe setzen.
			jsr	DirectColor
			jmp	UseSystemFont		;Standard-Schriftart.

;*** Titelzeile in Dialogbox löschen.
;Verwendet für InfoBox-Dialoge.
:Dlg_DrawTitel2		lda	#$00			;Füllmuster setzen.
			jsr	SetPattern
			jsr	i_Rectangle		;Titelzeile löschen.
			b	$40,$4f
:dlg00T2		w	$0050,$00ef		;Wird durch :InitDBoxData angepasst.
			lda	C_DBoxTitel		;Farbe setzen.
			jsr	DirectColor
			jmp	UseSystemFont		;Standard-Schriftart.

;*** AutoClose für Infoboxen.
:IBoxInit		LoadW	appMain,IBoxClose	;Exit in MainLoop einbinden.
			rts

:IBoxClose		php				;Aufruf aus GEOS/MainLoop:
			sei				;Einbindung löschen.
			lda	#$00
			sta	appMain +0
			sta	appMain +1
			plp

			lda	#OK
			sta	sysDBData
			jmp	RstrFrmDialogue		;DialogBox beenden.

;*** Dezimalzahl nach ASCII wandeln.
;    Übergabe: AKKU = Dezimal-Zahl 0-99.
;    Rückgabe: XREG/AKKU = 10er/1er Dezimalzahl.
:DEZ2ASCII		ldx	#"0"
::1			cmp	#10			;Restwert < 10?
			bcc	:2			; => Ja, weiter...
;			sec
			sbc	#10			;Restwert -10.
			inx				;10er-Zahl +1.
			cpx	#"9" +1			;10er-Zahl > 9?
			bcc	:1			; => Nein, weiter...
			dex				;Wert >99, Zahl auf
			lda	#9			;99 begrenzen.
::2			clc				;1er-Zahl nach ASCII wandeln.
			adc	#"0"
			rts

;*** HEX-Zahl nach ASCII wandeln.
;    Übergabe: AKKU = Hex-Zahl.
;    Rückgabe: AKKU/XREG = LOW/HIGH-Nibble Hex-Zahl.
:HEX2ASCII		pha				;HEX-Wert speichern.
			lsr				;HIGH-Nibble isolieren.
			lsr
			lsr
			lsr
			jsr	:1			;HIGH-Nibble nach ASCII wandeln.
			tax				;Ergebnis zwischenspeichern.

			pla				;HEX-Wert zurücksetzen und
							;nach ASCII wandeln.
::1			and	#%00001111
			clc
			adc	#"0"
			cmp	#$3a			;Zahl größer 10?
			bcc	:2			;Ja, weiter...
			clc				;Hex-Zeichen nach $A-$F wandeln.
			adc	#$07
::2			rts

;*** Auf gültiges Zeichen prüfen.
:testChar		cmp	#" "			;ASCII < $20?
			bcs	:1			; => Nein, weiter...
::3			lda	#" "			;Sonderzeichen durch Leerzeichen
::2			rts				;ersetzen.

::1			cmp	#$7f
			beq	:3			;ASCII > $7e +1?
			bcc	:2			; => Nein, Zeichen OK.
			and	#%01111111		;Bit%7 löschen und Zeichen
			jmp	testChar		;erneut testen.

;*** Pause...
:wait1Second		ldx	#10
::1			jsr	SCPU_Pause		;MegaPatch: 1/10sec Pause.
			dex				;Wartezeit abgelaufen?
			bne	:1			; => Nein, weiter...
			rts

;******************************************************************************
;*** Dialogbox anpassen/testen.
;******************************************************************************

;*** Dialogboxen an 80-Zeichen anpassen.
:InitDBoxData		bit	curScrnMode		;Bildschirm-Modus abfragen.
			bmi	:80			; => 80-Zeichen, weiter...
			rts				; => 40-Zeichen, Ende.

;--- Standard-Dialogbox:
;b $30,$8f
;w $0040,$00ff
::80			lda	dlg00T1 +1		;Links.
			ora	#>DOUBLE_W
			sta	dlg00T1 +1
			sta	dlg80_01a +1
			sta	dlg80_02a +1
			sta	dlg80_03a +1
			sta	dlg80_04a +1
			sta	dlg80_05a +1
			sta	dlg80_06a +1

			lda	dlg00T1 +3		;Rechts.
			ora	#>DOUBLE_W!ADD1_W
			sta	dlg00T1 +3
			sta	dlg80_01a +3
			sta	dlg80_02a +3
			sta	dlg80_03a +3
			sta	dlg80_04a +3
			sta	dlg80_05a +3
			sta	dlg80_06a +3

;--- Infobox:
;b $40,$6f
;w $0050,$00ef

			lda	dlg00T2 +1		;Links.
			ora	#>DOUBLE_W
			sta	dlg00T2 +1
			sta	dlg80_07a +1
			sta	dlg80_08a +1
			sta	dlg80_09a +1
			sta	dlg80_10a +1
			sta	dlg80_11a +1
			sta	dlg80_12a +1
			sta	dlg80_13a +1

			lda	dlg00T2 +3		;Rechts.
			ora	#>DOUBLE_W!ADD1_W
			sta	dlg00T2 +3
			sta	dlg80_07a +3
			sta	dlg80_08a +3
			sta	dlg80_09a +3
			sta	dlg80_10a +3
			sta	dlg80_11a +3
			sta	dlg80_12a +3
			sta	dlg80_13a +3

			rts

;*** Test des UI:
;Aufruf aller Dialogboxen zum testen
;der Größe/Position in 40/80-Zeichen.
if TESTDLG=TRUE
:testDlgBoxUI		LoadW	r0,Dlg_NoMP
			jsr	DoDlgBox

			LoadW	r0,Dlg_ErrorNoHD
			jsr	DoDlgBox
			LoadW	r0,Dlg_ErrBlkSize
			jsr	DoDlgBox
			LoadW	r0,Dlg_ErrSysPart
			jsr	DoDlgBox
			LoadW	r0,Dlg_ErrRdPart
			jsr	DoDlgBox
			LoadW	r0,Dlg_InsertMedia
			jsr	DoDlgBox
;			LoadW	r0,Dlg_DiskError
;			jsr	DoDlgBox
			jsr	systemError
			jsr	senseError

			LoadW	r0,IBox_Searching
			jsr	DoDlgBox
			LoadW	r0,IBox_FindSysP
			jsr	DoDlgBox
			LoadW	r0,IBox_ReadPTab
			jsr	DoDlgBox
			LoadW	r0,IBox_ReadDir
			jsr	DoDlgBox
			LoadW	r0,IBox_CopyPart
			jsr	DoDlgBox
			LoadW	r0,IBox_UpdateNM
			jsr	DoDlgBox
			LoadW	r0,IBox_UpdPData
			jsr	DoDlgBox

			rts
endif

;******************************************************************************
;*** Laufwerksbefehle senden/Daten empfangen.
;******************************************************************************

;*** Befehl an Laufwerk senden.
;Übergabe: AKKU/XREG = Zeiger auf Befehl.
;          YREG = Anzahl Bytes.
:sendCom		sta	r0L			;Adresse des Befehls.
			stx	r0H
			sty	r1L			;Anzahl Bytes im Befehl.

			jsr	devLISTEN		;Laufwerk auf "Empfang" schalten.
			bcs	:exit			; => Fehler, Abbruch...

			ldy	#$00
::1			lda	(r0L),y
			jsr	CIOUT			;Zeichen über IEC-Bus ausgeben.
			iny
			dec	r1L			;Alle Zeichen gesendet?
			bne	:1			; => Nein, weiter...

			jmp	UNLSN			;UNLSN auf IEC-Bus senden.

::exit			rts

;*** Aktuelle Partition einlesen.
:getActivePart		lda	#<comGETPART
			ldx	#>comGETPART
			ldy	#3
			jsr	sendCom			;"G-P"-Befehl senden.
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Partitionstyp.
			jsr	ACPTR			;Nicht verwendet.
			jsr	ACPTR			;Partitionsnummer.
			sta	activePart
			jmp	UNTALK			;Laufwerk abschalten.

;*** Daten aus HDRAM lesen.
;Übergabe: AKKU/XREG = Zeiger auf Datenspeicher.
;          YREG = Anzahl Bytes.
:readData		sta	r0L			;Adresse des Datenspeicher.
			stx	r0H
			sty	r1L			;Anzahl zu empfangender Bytes.

			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			bcs	:error

			ldy	#$00
::1			jsr	ACPTR			;Byte über IEC-Bus empfangen.
			sta	(r0L),y			;Byte in Datenspeicher schreiben.
			iny
			dec	r1L			;Alle Bytes empfangen?
			bne	:1			; => Nein, weiter...

			jmp	UNTALK			;Laufwerk abschalten.

::error			rts

;*** Laufwerk auf LISTEN schalten.
:devLISTEN		lda	curDevice		;Aktuelle Geräteadresse.
:chkDevExist		ldx	#$00			;Fehlerstatus löschen.
			stx	STATUS

			jsr	LISTEN			;LISTEN auf IEC-Bus senden.
			lda	#$6f
			jsr	SECOND			;Sekundäradresse für IEC-Bus.

			lda	STATUS			;Fehler aufgetreten?
			clc
			bpl	:exit			; => Nein, weiter...
			jsr	UNLSN
			sec				;Laufwerksfehler.

::exit			rts

;*** Laufwerk auf TALK schalten.
:devTALK		lda	curDevice		;Aktuelle Geräteadresse.
			jsr	TALK			;TALK auf IEC-Bus senden.
			lda	#$6f
			jmp	TKSA			;Sekundäradresse für TALK.

;*** 256-Byte Block einlesen.
:readBlkOffset		ldx	#$03			;Adresse des Verzeichnis-Sektors
::1			lda	curDirAdrLBA,x		;in SCSI-Read-Befehl übertragen.
			sta	scsiREAD_adr,x
			dex
			bpl	:1

			lda	#<scsiBufAdr		;Offset zur Adresse SCSI-Buffer
			clc				;addieren. Der 256B-Block beginnt
			adc	curSekOffset +0		;damit entweder bei:
			sta	scsiREAD_mradr +0	; => ":scsiBufAdr" +$0000 oder
			lda	#>scsiBufAdr		; => ":scsiBufAdr" +$0100
			adc	curSekOffset +1
			sta	scsiREAD_mradr +1

:rd256ByteBlk		ldx	#$00
			stx	scsiREAD_count +0	;Anzahl 512-Byte-Blocks = 1.
			inx
			stx	scsiREAD_count +1

			lda	#128			;Anzahl Bytes für "M-R".
			sta	scsiREAD_mrcnt		;(256B-Block / 2)

			jsr	scsiSendREAD		;SCSI-Befehl "READ" senden.
			bcs	:errComDev

			lda	#<scsiREAD_mr		;Laufwerksbefehl "M-R".
			ldx	#>scsiREAD_mr		;Der Sektor liegt ab :scsiBufAdr
			ldy	#6			;(= $3x00) im RAM der CMD-HD.
			jsr	sendCom
			bcs	:errComDev

			lda	#<diskBlkBuf +0		;Daten des 256B-Blocks
			ldx	#>diskBlkBuf +0		;einlesen (128 Bytes).
			ldy	#128
			jsr	readData
			bcs	:errComDev

			lda	scsiREAD_mradr +0	;"M-R"-Adresse auf die nächsten
			clc				;128 Byte setzen.
			adc	#128
			sta	scsiREAD_mradr +0
			bcc	:1
			inc	scsiREAD_mradr +1

::1			lda	#<scsiREAD_mr		;Laufwerksbefehl "M-R".
			ldx	#>scsiREAD_mr		;Der Sektor liegt ab :scsiBufAdr
			ldy	#6			;(= $3x80) im RAM der CMD-HD.
			jsr	sendCom
			bcs	:errComDev

			lda	#<diskBlkBuf +128	;Die letzten 128 Byte des
			ldx	#>diskBlkBuf +128	;256B-Block einlesen.
			ldy	#128
			jsr	readData
			bcs	:errComDev

			ldx	#gScErr_OK		;Kein Fehler:
			b $2c
::errComDev		ldx	#gScErr_RdBlkSCSI	;Fehler: Sektor einlesen.
			rts

;******************************************************************************
;*** SCSI-Routinen.
;******************************************************************************

;*** Geräte-Informationen einlesen.
:scsiSendINQUIRY	lda	scsiComID		;Neue SCSI-ID einlesen und für
			sta	scsiINQUIRY_id		;SCSI-Befehl "INQUIRY" speichern.

			lda	#<scsiINQUIRY		;SCSI-Befehl "INQUIRY" zur
			ldx	#>scsiINQUIRY		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiINQUIRY
			ldx	#>scsiINQUIRY
			ldy	#12
			jsr	sendCom
			bcs	:not_ready		; => Fehler, Abbruch...

			lda	#<scsiINQUIRY_mr	;Laufwerksbefehl "M-R".
			ldx	#>scsiINQUIRY_mr
			ldy	#6
			jsr	sendCom
			bcs	:not_ready		; => Fehler, Abbruch...
			lda	#<scsiDataBuf24		;Ergebniss von "INQUIRY"
			ldx	#>scsiDataBuf24		;aus dem RAM der CMD-HD einlesen.
			ldy	#36
			jsr	readData
			bcs	:not_ready		; => Fehler, Abbruch...

			lda	scsiDataBuf24 +0	;"DEVICE TYPE" einlesen.
			and	#%00011111		;Nur Bit%0-%4 relevant.
			tax
			cpx	#$08			;"DEVICE TYPE" > 8?
			bcs	:not_supported		; => Ja, nich unterstützt.

			lda	scsiTypes,x		;Interne Geräteklasse einlesen.
			bmi	:not_supported		; => $FF: Nicht unterstützt.
			bne	:1			; => Keine Festplatte.

			bit	scsiDataBuf24 +1	;Laufwerk mit Wechselmedium?
			bpl	:1			; => Nein, weiter...
			lda	#$01			; => IomegaZIP.

::1			ldx	scsiComID
			sta	scsiIdent,x		;Geräteklasse speichern.
			txa
			sta	scsiID,x		;Geräte-ID speichern.
			lda	scsiDataBuf24 +1	;$00 = Fest, $80 = Wechselmedium.
			sta	scsiRemovable,x		;Wechselmedium-Flag speichrn.

			ldx	#gScErr_OK		;Gültiges Gerät erkannt.
			rts

::not_supported		ldx	#gScErr_BadSCSI		;Gerät nicht unterstützt.
			rts

::not_ready		ldx	#gScErr_NotRdy		;Fehler: Laufwerk nicht bereit.
			rts

;*** SCSI-Geräte auf "READY" testen.
;Rückgabe: AKKU = $00/$02 READY.
;               > $80 Not READY.
:scsiSendREADY		lda	scsiComID		;Neue SCSI-ID einlesen und
			sta	scsiREADY_id		;für SCSI-Befehl "READY" speichern.

			lda	#<scsiREADY		;SCSI-Befehl "UNIT READY" zur
			ldx	#>scsiREADY		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiREADY
			ldx	#>scsiREADY
			ldy	#12
			jsr	sendCom
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Fehler-Byte über IEC-Bus empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			rts

;*** Mediengröße einlesen.
;Rückgabe: C-Flag=1: Fehler.
:scsiSendCAPACITY	lda	scsiComID		;Neue SCSI-ID einlesen und für
			sta	scsiCAPACITY_id		;SCSI-Befehl "CAPACITY" speichern.

			lda	#<scsiCAPACITY		;SCSI-Befehl "READ CAPACITY" zur
			ldx	#>scsiCAPACITY		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiCAPACITY
			ldx	#>scsiCAPACITY
			ldy	#12
			jsr	sendCom
			bcs	:exit			; => Fehler, Abbruch...

			lda	#<scsiCAPACITY_mr	;Laufwerksbefehl "M-R".
			ldx	#>scsiCAPACITY_mr
			ldy	#6
			jsr	sendCom
			bcs	:exit			; => Fehler, Abbruch...

			lda	#<scsiDataBuf8		;Ergebniss von "READ CAPACITY"
			ldx	#>scsiDataBuf8		;aus dem RAM der CMD-HD einlesen.
			ldy	#8
			jmp	readData
::exit			rts

;*** SCSI-Gerät starten.
;Rückgabe: AKKU = $00: OK.
:scsiSendSTART		lda	scsiComID		;Neue SCSI-ID einlesen und für
			sta	scsiSTARTUNIT_id	;SCSI-Befehl "START UNIT" speichern.

			lda	#<scsiSTARTUNIT		;SCSI-Befehl "START UNIT" zur
			ldx	#>scsiSTARTUNIT		;Sicherheit 2x senden.
			ldy	#12			;In seltenen Fällen wird der Befehl
			jsr	sendCom			;sonst nicht korrekt ausgeführt.
			lda	#<scsiSTARTUNIT
			ldx	#>scsiSTARTUNIT
			ldy	#12
			jsr	sendCom
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Fehler-Byte über IEC-Bus empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			rts

;*** READ an SCSI-Gerät senden.
;Rückgabe: C-FLAG=1: Fehler.
:scsiSendREAD		lda	#<scsiREAD		;Zeiger auf SCSI-Befehl "READ".
			ldx	#>scsiREAD
			ldy	#16			;Länge SCSI-Befehl.
			jsr	sendCom			;Befehl an Laufwerk senden.
			bcs	:exit			; => Fehler, Abbruch...
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Fehler-Byte über IEC-Bus empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			clc				;Flag setzen: Kein Fehler.
			beq	:exit			; => Kein Fehler, Ende...
			sec				;Flag setzen: Fehler.
::exit			rts

;*** WRITE an SCSI-Gerät senden.
;Rückgabe: C-FLAG=1: Fehler.
:scsiSendWRITE		lda	#<scsiWRITE		;Zeiger auf SCSI-Befehl "WRITE".
			ldx	#>scsiWRITE
			ldy	#16			;Länge SCSI-Befehl.
			jsr	sendCom			;Befehl an Laufwerk senden.
			bcs	:exit			; => Fehler, Abbruch...
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;Fehler-Byte über IEC-Bus empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			clc				;Flag setzen: Kein Fehler.
			beq	:exit			; => Kein Fehler, Ende...
			sec				;Flag setzen: Fehler.
::exit			rts

;*** REQUEST SENSE an SCSI-Gerät senden.
;Rückgabe: C-FLAG=1: Fehler.
:scsiSendSENSE		lda	#<scsiSENSE		;Zeiger auf SCSI-Befehl "SENSE".
			ldx	#>scsiSENSE
			ldy	#12			;Länge SCSI-Befehl.
			jsr	sendCom			;Befehl an Laufwerk senden.
			bcs	:exit			; => Fehler, Abbruch...

			lda	#<scsiSENSE_mr		;Laufwerksbefehl "M-R".
			ldx	#>scsiSENSE_mr
			ldy	#6
			jsr	sendCom
			bcs	:exit			; => Fehler, Abbruch...

			lda	#<scsiSENSE_buf		;Ergebniss von "REQUEST SENSE"
			ldx	#>scsiSENSE_buf		;aus dem RAM der CMD-HD einlesen.
			ldy	#18
			jmp	readData
::exit			rts

;******************************************************************************
;*** SCSI-Management.
;******************************************************************************

;*** Aktuelle SCSI-ID einlesen.
:scsiGetCurID		lda	#<comGETID		;"M-R"-Befehl an Laufwerk senden.
			ldx	#>comGETID
			ldy	#6
			jsr	sendCom
			jsr	devTALK			;Laufwerk auf "Senden" schalten.
			jsr	ACPTR			;SCSI-ID über IEC-Bus empfangen.
			pha
			jsr	UNTALK			;Laufwerk abschalten.
			pla
			lsr				;SCSI-ID in Zeiger auf
			lsr				;Gerätetabelle umwandeln.
			lsr
			lsr
			sta	scsiDevCurID		;Geräte-ID speichern.
			rts

;*** Blockgröße testen.
:scsiChkBlkSize		jsr	scsiSendCAPACITY	;SCSI-Befehl "READ CAPACITY".
			bcs	:not_ready		; => Fehler, Abbruch...

			ldx	scsiDataBuf8 +6		;High-Byte Blockgröße.
			lda	scsiDataBuf8 +7		;Low-Byte Blockgröße.
			bne	:error
			cpx	#$02			;Blockgröße 512 Bytes?
			bne	:error			; => Nein, Fehler...

			ldx	#gScErr_OK		;Blockgröße = 512 Bytes.
			rts

::error			ldx	#gScErr_BlkSize		;Blockgröße <> 512 Bytes.
			rts

::not_ready		ldx	#gScErr_NotRdy		;Fehler: Laufwerk nicht bereit.
			rts

;*** Systempartition suchen.
:scsiChkSysPart		jsr	scsiSendREADY		;Laufwerk bereit?
			beq	:ok			; => Ja, weiter...
			bmi	:not_ready		; => Kein Medium eingelegt.

			jsr	scsiSendSTART		;Geparkte HDD aktivieren.

			jsr	scsiSendREADY		;Laufwerk bereit?
			bne	:not_ready

::ok			jsr	scsiChkBlkSize		;Blockgröße/Mediengröße einlesen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch...

			lda	scsiComID		;Neue SCSI-ID einlesen und
			sta	scsiREAD_id		;für SCSI-Befehl "READ" speichern.

;--- SCSI-READ definieren.
;Hinweis:
;Innerhalb des Testsektors liegt die
;CMD-HD-Kennung ab $01f0 im Speicher.
			lda	#<scsiBufAdr +$01f0
			sta	scsiREAD_mradr +0
			lda	#>scsiBufAdr +$01f0
			sta	scsiREAD_mradr +1
;Hinweis:
;Die CMD-HD-Kennung ist 16 Byte groß.
			lda	#$10
			sta	scsiREAD_mrcnt

			lda	#$00			;Adresse des ersten Datensektors
			ldx	#$02			;der eingelesen werden soll.
			sta	scsiREAD_adr +0		;Die Suche beginnt ab dem 2ten
			sta	scsiREAD_adr +1		;512Byte-Datensektor.
			sta	scsiREAD_adr +2
			stx	scsiREAD_adr +3

			sta	scsiREAD_count +0	;Anzahl 512-Byte-Blocks.
			dex
			stx	scsiREAD_count +1

			sta	r1H			;Sektorzähler initialisieren.

::loop			jsr	scsiSendREAD		;SCSI-Befehl "READ" senden.
			bcs	:not_found

			lda	#<scsiREAD_mr		;Laufwerksbefehl "M-R".
			ldx	#>scsiREAD_mr		;Der Sektor liegt ab :scsiBufAdr
			ldy	#6			;(= $3000) im RAM der CMD-HD.
			jsr	sendCom
			lda	#<scsiDataBuf16		;Prüfbytes aus dem RAM der CMD-HD
			ldx	#>scsiDataBuf16		;einlesen (16Bytes).
			ldy	#16
			jsr	readData

			ldx	#16			;Daten Systempartition vergleichen.
::chk			lda	scsiDataBuf16 -1,x
			cmp	codeSysPartHD -1,x
			bne	:next			;Nicht gefunden, weiter...
			dex				;Alle 16 Bytes überprüft?
			bne	:chk			; => Nein, weiter...

;			ldx	#gScErr_OK		;OK: Systempartition gefunden!
::exit			rts

::next			dec	r1H			;Sektorzähler korrigieren.
			beq	:not_found		; => 256 Sektoren durchsucht, Ende.

			jsr	blkReadNx128		;Zeiger auf nächsten Sektor.
			jsr	chkEndOfDisk		;Ende Medium erreicht?
			bcc	:loop			; => Nein, weitersuchen...

::not_found		ldx	#gScErr_NoSysP		;Fehler: Keine Systempartition!
			rts

::not_ready		ldx	#gScErr_NotRdy		;Fehler: Laufwerk nicht bereit.
			rts

;*** SCSI-Blockadresse erhöhen.
;Dabei werden 128 Sektoren a 512Bytes
;übersprungen = 64Kb.
;Die Systempartition kann nur innerhalb
;eines 64Kb Speicherbereichs beginnen.
;256 Testvorgänge a 64Kb entsprechen
;16Mb, d.h. es werden nur die ersten
;Bereiche des Mediums durchsucht.
:blkReadNx128		lda	#$80
			clc
			adc	scsiREAD_adr +3
			sta	scsiREAD_adr +3
			bcc	:1
			inc	scsiREAD_adr +2
			bne	:1
			inc	scsiREAD_adr +1
			bne	:1
			inc	scsiREAD_adr +0
::1			rts

;*** SCSI-Blockadresse testen.
;Die Routine überprüft ob die aktuelle
;SCSI-Blockadresse noch innerhalb des
;Mediums liegt.
;:scsiREAD_adr = Aktueller Sektor.
;:scsiDataBuf8 = "READ CAPACITY"-Daten.
:chkEndOfDisk		lda	scsiREAD_adr +0
			cmp	scsiDataBuf8 +0
			bne	:1
			lda	scsiREAD_adr +1
			cmp	scsiDataBuf8 +1
			bne	:1
			lda	scsiREAD_adr +2
			cmp	scsiDataBuf8 +2
			bne	:1
			lda	scsiREAD_adr +3
			cmp	scsiDataBuf8 +3
::1			rts

;*** Kennung für CMD-HD Systempartition.
:codeSysPartHD		b "CMD HD  "
			sta	$8803
			stx	$8802
			nop
			rts

;*** Auf Medium im Laufwerk testen.
:scsiMediaREADY		jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

if TESTUI=FALSE
::loop			jsr	scsiSendREADY		;Laufwerk bereit?
			bmi	:noDevice		; => Laufwerk nicht vorhanden.
			beq	:ok			; => Medium eingelegt.

			jsr	scsiSendSTART		;Geparkte HDD aktivieren.

			jsr	scsiSendREADY		;Laufwerk bereit?
			beq	:ok			; => Medium eingelegt.

			jsr	DoneWithIO		;I/O-Bereich abschalten.

			LoadW	r0,Dlg_InsertMedia
			jsr	DoDlgBox		;Dialogbox anzeigen.

			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			lda	sysDBData
			cmp	#CANCEL			;Rückmeldung auswerten.
			beq	:notReady		; => Abbruch...
			bne	:loop			; => Laufwerk testen...
endif

::ok			ldx	#gScErr_OK
			b $2c
::notReady		ldx	#gScErr_NotRdy
			b $2c
::noDevice		ldx	#gScErr_DevNotRdy
			jmp	DoneWithIO		;I/O-Bereich abschalten.

;******************************************************************************
;*** SCSI-Informationen einlesen.
;******************************************************************************

;*** Laufwerksdaten einlesen.
:getDevName		lda	scsiComID		;Zeiger auf Textspeicher für
			asl				;Hersteller und Gerätename setzen.
			asl
			tay
			ldx	#0
::1			lda	scsiNameTab +0,y
			sta	r2L,x
			iny
			inx
			cpx	#4
			bcc	:1

			ldx	scsiComID		;Geräte-Klasse in Text wandeln.
			lda	scsiIdent,x
			asl
			tax
			ldy	#0
			lda	scsiTypeTx +0,x
			sta	(r2L),y
			iny
			lda	scsiTypeTx +1,x
			sta	(r2L),y

			ldx	#0
			ldy	#2			;Herstellername einlesen.
::3			lda	scsiDataBuf24 +8,x
			jsr	testChar		;Nur gültige ASCII Zeichen einlesen.
			sta	(r2L),y			;Zeichen in Speicher übernehmen.
			iny
			inx
			cpx	#8
			bcc	:3

			ldy	#0			;Gerätename einlesen.
::4			lda	scsiDataBuf24 +16,y
			jsr	testChar		;Nur gültige ASCII Zeichen einlesen.
			sta	(r3L),y			;Zeichen in Speicher übernehmen.
			iny
			cpy	#16
			bcc	:4

			rts

;******************************************************************************
;*** Register-Menü-Funktionen.
;******************************************************************************

;*** Daten Quell-SCSI-Gerät auslesen.
;Dazu zuvor ":callFindSCSI" ausgeführt
;worden sein, damit die Geräte-Daten in
;der Namenstabelle abgelegt werden.
:copySrcDevInfo		lda	scsiSrcID		;SCSI-ID Quell-Laufwerk.
			pha

			jsr	DEZ2ASCII		;ID nach ASCII wandeln.
			stx	scsiSrcIDtx +0
			sta	scsiSrcIDtx +1

			pla				;SCSI-ID in Zeiger auf Tabelle
			asl				;;mit Position der Texte für
			asl				;Hersteller/Gerätetyp berechnen.
			tay
			ldx	#0
::1			lda	scsiNameTab +0,y
			sta	r2L,x
			iny
			inx
			cpx	#4
			bcc	:1

			ldy	#0
::2			lda	(r2L),y			;Hersteller aus SCSI-Daten
			sta	scsiSrcVendor,y		;auslesen und speichern.
			lda	(r3L),y			;Gerätetyp aus SCSI-Daten
			sta	scsiSrcModel,y		;auslesen und speichern.
			iny
			cpy	#17
			bcc	:2

			rts

;*** Daten Ziel-SCSI-Gerät auslesen.
;Dazu zuvor den Befehl INQUIRY an das
;SCSI-Laufwerk senden.
:copyTgtDevInfo		lda	scsiTgtID		;SCSI-ID Quell-Laufwerk.
			pha

			jsr	DEZ2ASCII		;ID nach ASCII wandeln.
			stx	scsiTgtIDtx +0
			sta	scsiTgtIDtx +1

			pla				;SCSI-ID in Zeiger auf Tabelle
			asl				;;mit Position der Texte für
			asl				;Hersteller/Gerätetyp berechnen.
			tay
			ldx	#0
::1			lda	scsiNameTab +0,y
			sta	r2L,x
			iny
			inx
			cpx	#4
			bcc	:1

			ldy	#0
::2			lda	(r2L),y			;Hersteller aus SCSI-Daten
			sta	scsiTgtVendor,y		;auslesen und speichern.
			lda	(r3L),y			;Gerätetyp aus SCSI-Daten
			sta	scsiTgtModel,y		;auslesen und speichern.
			iny
			cpy	#17
			bcc	:2

			rts

;*** Zeiger auf Partitionsdaten setzen.
;Übergabe: AKKU = Zeiger auf Partitionseintrag.
:setAdrPartData		sta	r15L			;Partitions-Nummer.

			lda	#24			;Länge Partitions-Eintrag.
			sta	r0L			;(Beim einlesen reduziert 30->24)

			ldx	#r15L			;Partitions-Nr. x 24 Bytes.
			ldy	#r0L
			jsr	BBMult

			bit	modeSrcTgt		;Adresse Datenspeicher für
			bmi	:target			;Quelle- oder Ziel addieren.

::source		lda	#<partDataBufSrc	;Startadresse Partitionstabelle
			ldy	#>partDataBufSrc	;für Quell-Laufwerk.
			bne	addAYr15		;A/X zu r15 addieren.

::target		lda	#<partDataBufTgt	;Startadresse Partitionstabelle
			ldy	#>partDataBufTgt	;für Ziel-Laufwerk.
			bne	addAYr15		;A/X zu r15 addieren.

;*** Zeiger auf nächsten Eintrag in Partitionstabelle.
:add24r15		lda	#< 24
			ldy	#> 24

;*** A/Y zu r15 addieren.
:addAYr15		clc				;Ziel-Adresse berechnen.
			adc	r15L
			sta	r15L
			tya
			adc	r15H
			sta	r15H
			rts

;*** SCSI-ID Quell-Laufwerk initialisieren.
:initDevSrcID		lda	#NOTREADY		;Flag: "Laufwerk nicht bereit"
			sta	cmdPartSrcRdy

			lda	scsiSrcID		;SCSI-ID einlesen und für SCSI
			sta	scsiComID		;Befehl zwischenspeichern.
			LoadW	r0,IBox_FindSysP	;InfoBox: "Systempart. suchen".
			jsr	DoDlgBox		;(Suche wird automatisch gestartet)

			ldx	devErrorHD		;Laufwerksfehler?
			beq	:ok			; => Nein, weiter...
			cpx	#gScErr_NoSysP		;Keine Systempartition?
			bne	:exit			; => Ja, Abbruch...

			LoadW	r0,Dlg_ErrSysPart	;Fehler: "Keine Systempartition".
			jmp	DoDlgBox		;Fehlermeldung ausgeben, Abbruch.

::ok			ldy	#3			;Startadresse der Systempartition
::1			lda	scsiAdrSysPart,y	;und Partitionstabelle speichern.
			sta	scsiSrcAdrSysP,y	;Hinweis: HIGH/MID/LOW-Format!
			lda	scsiAdrPTable,y
			sta	scsiSrcAdrPTab,y
			dey
			bpl	:1

			lda	#DRVREADY		;Flag: "Laufwerk bereit"
			sta	cmdPartSrcRdy

::exit			rts

;*** Partitionen Quell-Laufwerk einlesen.
:initDevSrcPTab		lda	#$00			;Fehler-Flag löschen.
			sta	devErrorHD

			bit	cmdPartSrcRdy		;Ist Laufwerk bereit?
			bpl	:exit			; => Nein, Ende...

::source		lda	scsiSrcID		;SCSI-ID Quell-Laufwerk einlesen.
			sta	scsiComID		;SCSI-ID zwischenspeichern.
			LoadW	a0,partDataBufSrc	;Zeiger auf Part.-Namen-Speicher.
			LoadW	a1,scsiSrcAdrPTab	;Zeiger auf Part.-Nr.-Speicher.
			LoadW	r0,IBox_ReadPTab	;InfoBox: "Partitionen einlesen"
			jsr	DoDlgBox		;(Wird automatisch ausgeführt)

if TESTUI=TRUE
			lda	#cntTestUIsrcP		;TestUI: Max. Anzahl Partitionen.
endif
if TESTUI=FALSE
			lda	devErrorHD		;Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...
			lda	a3H			;Anzahl Partitionen einlesen.
endif
			sta	pTabMaxSrc		;Max.Partitionen speichern.

			jsr	srcPartInit		;Quell-Partition initialisieren.

::exit			rts

;*** SCSI-ID Quell-Laufwerk initialisieren.
:initDevTgtID		lda	#NOTREADY		;Flag: "Laufwerk nicht bereit"
			sta	cmdPartTgtRdy

			lda	scsiTgtID		;SCSI-ID einlesen und für SCSI
			sta	scsiComID		;Befehl zwischenspeichern.
			LoadW	r0,IBox_FindSysP	;InfoBox: "Systempart. suchen".
			jsr	DoDlgBox		;(Suche wird automatisch gestartet)

			ldx	devErrorHD		;Laufwerksfehler?
			beq	:ok			; => Nein, weiter...
			cpx	#gScErr_NoSysP		;Keine Systempartition?
			bne	:exit			; => Ja, Abbruch...

			LoadW	r0,Dlg_ErrSysPart	;Fehler: "Keine Systempartition".
			jmp	DoDlgBox		;Fehlermeldung ausgeben, Abbruch.

::ok			ldy	#3			;Startadresse der Systempartition
::1			lda	scsiAdrSysPart,y	;und Partitionstabelle speichern.
			sta	scsiTgtAdrSysP,y	;Hinweis: HIGH/MID/LOW-Format!
			lda	scsiAdrPTable,y
			sta	scsiTgtAdrPTab,y
			dey
			bpl	:1

			lda	#DRVREADY		;Flag: "Laufwerk bereit"
			sta	cmdPartTgtRdy

::exit			rts

;*** Partitionen Quell-Laufwerk einlesen.
:initDevTgtPTab		lda	#$00			;Fehler-Flag löschen.
			sta	devErrorHD

			bit	cmdPartTgtRdy		;Ist Laufwerk bereit?
			bpl	:exit			; => Nein, Ende...

			lda	scsiTgtID		;SCSI-ID Ziel-Laufwerk einlesen.
			cmp	scsiSrcID		;Gleich wie Quell-LKaufwerk?
			beq	:1			; => Ja, weiter...
			sta	scsiComID		;SCSI-ID zwischenspeichern.
			LoadW	a0,partDataBufTgt	;Zeiger auf Part.-Namen-Speicher.
			LoadW	a1,scsiTgtAdrPTab	;Zeiger auf Part.-Nr.-Speicher.
			LoadW	r0,IBox_ReadPTab	;InfoBox: "Partitionen einlesen"
			jsr	DoDlgBox		;(Wird automatisch ausgeführt)

if TESTUI=TRUE
::1			lda	#cntTestUItgtP		;TestUI: Max. Anzahl Partitionen.
endif
if TESTUI=FALSE
			lda	devErrorHD		;Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...
			lda	a3H			;Anzahl Partitionen einlesen.
			jmp	:2			; => Weiter...

;--- Quell=Ziel:
;Partition aus Quell-Laufwerk kopieren.
::1			jsr	i_MoveData		;Partitionen Quell-Laufwerk in
			w	partDataBufSrc		;Speicher für Ziel-Laufwerk
			w	partDataBufTgt		;kopieren.
			w	DATABUF_SIZE

			lda	pTabMaxSrc		;Anzahl Partitionen einlesen.
endif

::2			sta	pTabMaxTgt		;Max.Partitionen speichern.

			jsr	tgtPartInit		;Ziel-Partition initialisieren.

::exit			rts

;*** Quell-Partition initialisieren.
:srcPartInit		lda	#$01			;Partition #1 als Standard für
			sta	cmdPartSrc		;Quell-Laufwerk setzen.

			lda	#$00			;Partitionstabelle auf Anfang.
			sta	pTabPosSrc

;*** Quell-Partition aktualisieren.
:srcPartUpdate		lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			sta	modeSrcTgt

			lda	#NOTREADY		;Flag: Quell-Laufwerk nicht bereit.
			sta	cmdPartSrcRdy

			lda	scsiSrcID		;Neue SCSI-ID speichern und
			sta	scsiComID		;Laufwerksdaten aktualisieren.
			jsr	scsiMediaREADY		;Auf Medium im Laufwerk testen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch, "Kein Medium"...

			jsr	findSrcPart		;Erste Partition suchen.
			lda	partFound
			cmp	#$ff			;Partition gefunden?
			beq	:exit			; => Nein, Abbruch...

			ldx	#DRVREADY		;Flag: Quell-Laufwerk bereit.
			stx	cmdPartSrcRdy

;			lda	partFound
			sta	pTabPosSrc		;Position Partitionstabelle.
			jsr	setAdrPartData		;Zeiger auf Partitionseintrag.
			jsr	copySrcPData		;Daten einlesen.

::exit			rts

;*** Ziel-Partition initialisieren.
:tgtPartInit		lda	#$00			;Partition #1 als Standard für
:tgtPartInitSync	sta	cmdPartTgt		;Ziel-Laufwerk setzen.

			lda	#$00			;Partitionstabelle auf Anfang.
			sta	pTabPosTgt

;*** Ziel-Partition aktualisieren.
:tgtPartUpdate		lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			lda	#NOTREADY		;Flag: Ziel-Laufwerk nicht bereit.
			sta	cmdPartTgtRdy

			lda	scsiTgtID		;Neue SCSI-ID speichern und
			sta	scsiComID		;Laufwerksdaten aktualisieren.
			jsr	scsiMediaREADY		;Auf Medium im Laufwerk testen.
			txa				;Fehler?
			bne	:exit			; => Ja, Abbruch, "Kein Medium"...

			jsr	makeValidPTab		;Gültige Partition suchen.

			jsr	findTgtPart		;Erste Partition suchen.
			lda	partFound
			cmp	#$ff			;Partition gefunden?
			beq	:exit			; => Nein, Abbruch...

			ldx	#DRVREADY		;Flag: Ziel-Laufwerk bereit.
			stx	cmdPartTgtRdy

;			lda	partFound
			jsr	findValidPTabPos
			stx	pTabPosTgt		;Position Partitionstabelle.
			jsr	setAdrPartData		;Zeiger auf Partitionseintrag.
			jsr	copyTgtPData		;Daten einlesen.

::exit			rts

;*** Liste mit gültigen Partitionen erstellen
:makeValidPTab		lda	modeSrcTgt		;Ausgabemodus zwischenspeichern.
			pha

			lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			lda	#$00
			sta	r14L
::1			cmp	pTabMaxTgt		;Alle Partitionen durchsucht?
			beq	:clrBuf			; => Ja, Ende...

			sta	r14H
			jsr	setAdrPartData		;Zeiger auf Partitionseintrag.

			ldy	#$01
			lda	(r15L),y
			cmp	cmdPartSrcTyp		;Partitionstyp gültig?
			bne	:2			; => Nein, weiter...

			ldx	r14L
			lda	r14H
			sta	tgtPTypeData,x		;Partitions-Nummer in Tabelle der
			inc	r14L			;gültigen Partitionen eintragen.

::2			lda	r14H			;Alle Partitionen durchsucht?
			clc
			adc	#$01
			cmp	#255
			bcc	:1			; => Nein, weiter...

::clrBuf		ldx	r14L			;Den Rest der Liste mit den
			lda	#$ff			;gültigen Partitionen löschen.
::3			sta	tgtPTypeData,x
			inx
			bne	:3

			pla				;Ausgabemodus zurücksetzen.
			sta	modeSrcTgt

			lda	r14L			;Anzahl gültige Partitionen.
			sta	pTabMaxTgtBuf

			rts

;*** Pos. für Partition in Liste suchen.
:findValidPTabPos	ldx	#$00
::1			cmp	tgtPTypeData,x		;Partition gefunden?
			beq	:2			; => Ja, weiter...
			inx				;Alle Partitionen durchsucht?
			bne	:1			; => Nein, weiter...
;			ldx	#$00			;Partition nicht gefunden.

::2			pha				;Partitions-Nummer speichern.

			txa				;Ist Position+4 in Tabelle gültig?
			clc				;Ggf. die Position korrigeren für
			adc	#$04			;den Fall das weniger als vier
			cmp	pTabMaxTgtBuf		;Partitionen nach der aktuellen
			bcc	:4			;Position verfügbar sind.
			lda	pTabMaxTgtBuf		;Entspricht der Funktion "Zum Ende
			sec				;springen über die Positions-Icons.
			sbc	#$04
			bcs	:3

			lda	#$00			;Position auf Anfang setzen.

::3			tax				;Neue Position übernehmen.

::4			pla				;Partitions-Nummer zurücksetzen.
			rts

;*** InfoBox: Systempartition suchen.
:callFindSysP		ldy	#$03			;Adressen für Systempartition und
			lda	#$00			;Partitionstabelle löschen.
::1			sta	scsiAdrSysPart,y
			sta	scsiAdrPTable,y
			dey
			bpl	:1

			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			jsr	scsiChkSysPart		;Systempartition testen.
			txa				;Laufwerksfehler?
			bne	:exit			; => Ja, Abbruch...

			lda	scsiREAD_adr +3		;Startadresse der Systempartition
			sec				;berechnen. Der übermittelte Wert
			sbc	#$02			;zeigt auf den 3ten SCSI-Sektor mit
			sta	scsiREAD_adr +3		;der CMD-HD-Kennung.
			bcs	:2
			lda	#$ff
			dec	scsiREAD_adr +2
			cmp	scsiREAD_adr +2
			bne	:2
			dec	scsiREAD_adr +1
			cmp	scsiREAD_adr +1
			bne	:2
			dec	scsiREAD_adr +0

::2			ldy	#$03			;Anfang System-Partition merken.
::3			lda	scsiREAD_adr,y
			sta	scsiAdrSysPart,y
			dey
			bpl	:3

			jsr	blkReadNx128		;System-Partition +128 Blocks =
							;Anfang Partitionstabelle.

			ldy	#$03			;Adresse Partitionstabelle merken.
::4			lda	scsiREAD_adr,y
			sta	scsiAdrPTable,y
			dey
			bpl	:4

;			ldx	#gScErr_OK
::exit			jsr	DoneWithIO		;I/O-Bereich abschalten.

			stx	devErrorHD		;Fehler-Flag setzen.
			rts

;*** InfoBox: Partitionstabelle einlesen.
:callReadPTab		MoveW	a0,r1			;Speicher für Partitionsdaten
			LoadW	r0,DATABUF_SIZE		;löschen.
			jsr	ClearRam

			lda	devAdrHD		;Adresse CMD-HD-Laufwerk.
			jsr	SetDevice		;Laufwerk aktivieren.
			txa				;Laufwerksfehler?
			beq	:0			; => Nein, weiter...
			jmp	:errSysDev		; => Ja, Abbruch...

::0			jsr	PurgeTurbo		;GEOS-Turbo aus und
			jsr	InitForIO		;I/O-Bereich aktivieren.

			ldy	#$03			;Startadresse Partitionstabelle
::1			lda	(a1L),y			;einlesen und in SCSI-Befehl "READ"
			sta	scsiREAD_adr,y		;übertragen.
			dey
			bpl	:1

			lda	scsiComID		;Neue SCSI-ID einlesen und
			sta	scsiREAD_id		;für SCSI-Befehl "READ" speichern.

			LoadB	a2L,16			;Anzahl 512-Byte-Sektoren.

			lda	#$00
			sta	a3L			;Aktuelle Partitions-Nr.
			sta	a3H			;Partitionszähler initialisieren.

::loop_nx512		lda	#<scsiBufAdr		;Zeiger auf SCSI-Buffer in CMD-HD.
			sta	scsiREAD_mradr +0
			lda	#>scsiBufAdr
			sta	scsiREAD_mradr +1

			LoadB	a2H,2			;Anzahl 256-Byte-Blocks / Sektor.

::loop_nx256		jsr	rd256ByteBlk		;256B-Block aus 512B-Sektor lesen.
			txa				;Laufwerksfehler?
			beq	:start_copy		; => Nein, weiter...
			jmp	:errComDev		; => Ja, Abbruch...

::start_copy		ldx	#$00
::loop_nx32		lda	diskBlkBuf +2,x		;Partitionstyp einlesen.
			beq	:next_entry		; => Nicht definiert, weiter...
			cmp	#$08			;Partitionstyp gültig?
			bcs	:next_entry		; => Nein, weiter...

			pha
			ldy	#$00
			lda	a3L			;Partitionsnummer in
			sta	(a0L),y			;Eintrag kopieren.
			iny
			pla				;Partitionstyp in
			sta	(a0L),y			;Eintrag kopieren.

			iny				;Start-Adresse in
			lda	diskBlkBuf +21,x	;Eintrag kopieren.
			sta	(a0L),y
			iny
			lda	diskBlkBuf +22,x	;Der CMD-Format "G-P" liefert
			sta	(a0L),y			;nur die unteren drei Bytes der
			iny				;Startadresse zurück, daher wird
			lda	diskBlkBuf +23,x	;das höchste/4.Byte ignoriert.
			sta	(a0L),y

			iny				;Partitionsgröße in
			lda	diskBlkBuf +30,x	;Eintrag kopieren.
			sta	(a0L),y
			iny				;Da Partitionen max. 16Mb groß
			lda	diskBlkBuf +31,x	;sind ($7F80 oder $8000 Sektoren)
			sta	(a0L),y			;nur Byte #0/#1 kopieren.

::2			iny				;Partitionsname in
			lda	diskBlkBuf +5,x		;Eintrag kopieren.
			cmp	#$a0			;Ende erreicht?
			beq	:3			; => Ja, weiter...
			jsr	testChar		;Nur gültige Zeichen einlesen.
			sta	(a0L),y
			inx
			cpy	#23
			bcc	:2

::3			lda	#$00			;Rest Partitionsname löschen.
::4			sta	(a0L),y
			iny
			cpy	#24
			bcc	:4

			inc	a3H			;Anzahl Partitionen +1.

			lda	a0L			;Zeiger auf nächsten
			clc				;Partitionseintrag setzen.
			adc	#24
			sta	a0L
			bcc	:next_entry
			inc	a0H

::next_entry		inc	a3L			;Partitionszähler +1.

			txa				;X-Register auf Eintrag in
			and	#%11100000		;256B-Block zurücksetzen.
			clc
			adc	#32			;Zeiger auf nächsten Eintrag.
			tax				;Ende erreicht?
			bne	:loop_nx32		; => Nein, weiter...

			lda	#<scsiBufAdr +256	;Zeiger auf nächsten 256B-Block in
			sta	scsiREAD_mradr +0	;512B-Sektor setzen.
			lda	#>scsiBufAdr +256
			sta	scsiREAD_mradr +1

			dec	a2H			;Alle 256B-Blocks eingelesen?
			beq	:next_block		; => Ja, nächster 512B-Sektor.
			jmp	:loop_nx256		; => Nein, nächster 256B-Block.

::next_block		inc	scsiREAD_adr +3		;Zeiger auf nächsten SCSI-Sektor.
			bne	:6
			inc	scsiREAD_adr +2
			bne	:6
			inc	scsiREAD_adr +1
			bne	:6
			inc	scsiREAD_adr +0

::6			dec	a2L			;Partitionstabelle durchsucht?
			beq	:done			; => Ja, Ende...
			jmp	:loop_nx512		; => Weiter...

;--- Kein Fehler.
::done			ldx	#gScErr_OK		;Flag: "Kein Fehler".
			b $2c

;--- Kommunikationsfehler.
::errComDev		ldx	#gScErr_RdPTabSek	;Flag: "Partitionsfehler".
::exit			jsr	DoneWithIO		;I/O-Bereich abschalten.

			b $2c

;--- Fehler beim aktivieren der CMD-HD.
::errSysDev		ldx	#gScErr_SysDvP		;Laufwerksfehler.
			stx	devErrorHD		;Fehler-Flag setzen.
			rts

;*** Daten für neue Quell-Partition auslesen.
:copySrcPData		bit	cmdPartSrcRdy		;Laufwerk bereit?
			bmi	:ok			; => Ja, weiter...

			lda	#$00			;Laufwerk nicht bereit.
			ldy	#24 -1			;Partitionsdaten löschen.
::clr_src		sta	cmdPartSrcBuf,y
			dey
			bpl	:clr_src
			sta	cmdPartSrcTxt		;Partitionsformat löschen.
			rts

::ok			ldy	#24 -1			;Partitionsdaten in
::1			lda	(r15L),y		;Zwischenspeicher kopieren.
			sta	cmdPartSrcBuf,y
			dey
			bpl	:1

			lda	cmdPartSrcTyp		;Partitionstyp einlesen.
			cmp	#$08			;Gültiger Partitionstyp?
			bcc	:2			; => Ja, weiter...
			lda	#$08			;Unbekannt, Vorgabe => "SYSTEM".
::2			asl
			asl
			asl
			tax
			ldy	#0			;Partitionstext in Langform
::3			lda	pTypeTxLong,x		;in Partitionsdaten schreiben.
			sta	cmdPartSrcTxt,y
			inx
			iny
			cpy	#8
			bcc	:3

			rts

;*** Daten für neue Ziel-Partition auslesen.
:copyTgtPData		bit	cmdPartTgtRdy		;Laufwerk bereit?
			bmi	:ok			; => Ja, weiter...

			lda	#$00			;Laufwerk nicht bereit.
			ldy	#24 -1			;Partitionsdaten löschen.
::clr_tgt		sta	cmdPartTgtBuf,y
			dey
			bpl	:clr_tgt
			sta	cmdPartTgtTxt		;Partitionsformat löschen.
			rts

::ok			ldy	#24 -1			;Partitionsdaten in
::1			lda	(r15L),y		;Zwischenspeicher kopieren.
			sta	cmdPartTgtBuf,y
			dey
			bpl	:1

			lda	cmdPartTgtTyp		;Partitionstyp einlesen.
			cmp	#$08			;Gültiger Partitionstyp?
			bcc	:2			; => Ja, weiter...
			lda	#$08			;Unbekannt, Vorgabe => "SYSTEM".
::2			asl
			asl
			asl
			tax
			ldy	#0			;Partitionstext in Langform
::3			lda	pTypeTxLong,x		;in Partitionsdaten schreiben.
			sta	cmdPartTgtTxt,y
			inx
			iny
			cpy	#8
			bcc	:3

			rts

;*** Register-Funktion: Nächste CMD-HD suchen.
:reg_findNxHD		jsr	findDevCMDHD		;CMD-HD unter GEOS suchen.

			cpx	#$00			;Neue CMD-HD gefunden?
			beq	:exit			; => Nein, weiter...

			stx	devAdrHD		;Adresse CMD-HD sichern.

if TESTUI=FALSE
			jsr	initDevInfo		;"Suche SCSI-Laufwerke..."
			txa				;Laufwerksfehler?
			bne	reg_findNxHD		; => Ja, weitersuchen...
endif

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:update80hd		; => 80Z, weiter...

::update40hd		LoadW	r15,RTabMenu40_HD	;Register-Option: Geräteadresse.
			jsr	RegisterUpdate		;Registermenü aktualisieren.
			jmp	:endUpdate

::update80hd		LoadW	r15,RTabMenu80_HD	;Register-Option: Geräteadresse.
			jsr	RegisterUpdate		;Registermenü aktualisieren.

::endUpdate		lda	#$01
			sta	cmdPartSrc
			jsr	reg_updateSrcDev	;Quell-Laufwerk aktualisieren.
			lda	#$00
			sta	cmdPartTgt
			jsr	reg_updateTgtDev	;Ziel-Laufwerk aktualisieren.

::exit			rts				;Ende.

;*** Register-Funktion: Quelle/Ziel tauschen.
:reg_swapDevices	lda	scsiSrcID		;SCSI-Geräte-IDs tauschen.
			ldx	scsiTgtID
			sta	scsiTgtID
			stx	scsiSrcID

			lda	cmdPartSrc		;Partitions-Nummern tauschen.
			ldx	cmdPartTgt
			sta	cmdPartTgt
			stx	cmdPartSrc

			lda	pTabPosSrc		;Pos. in Partitionstabelle
			ldx	pTabPosTgt		;tauschen.
			sta	pTabPosTgt
			stx	pTabPosSrc

			lda	pTabMaxSrc		;Max. Anzahl Partitionen in
			ldx	pTabMaxTgt		;Partitionstabelle tauschen.
			sta	pTabMaxTgt
			stx	pTabMaxSrc

			lda	cmdPartSrcRdy		;Laufwerksstatus tauschen.
			ldx	cmdPartTgtRdy
			sta	cmdPartTgtRdy
			stx	cmdPartSrcRdy

			LoadW	r0,partDataBufSrc	;Partitionsdaten tauschen.
			LoadW	r1,partDataBufTgt

			ldx	#$00
::loop			ldy	#$00			;Aktuellen Partitionseintrag
::entry			lda	(r0L),y			;tauschen.
			pha
			lda	(r1L),y
			sta	(r0L),y
			pla
			sta	(r1L),y
			iny
			cpy	#24
			bcc	:entry

			AddVW	24,r0			;Zeiger auf nächsten Eintrag.
			AddVW	24,r1

			inx				;Alle Einträge getauscht?
			bne	:loop			; => Nein, weiter...

			bit	cmdPartSrcRdy
			bmi	:updateSrc

			jsr	srcPartInit		;Quell-Partition initialisieren.

::updateSrc		lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			sta	modeSrcTgt

			lda	scsiSrcID		;SCSI-ID Quell-Laufwerk einlesen.
			sta	scsiComID		;Als aktuelle SCSI-ID festlegen.
			jsr	copySrcDevInfo		;Daten für Quell-Laufwerk einlesen.
			jsr	prnt_id			;Ausgabe SCSI-ID.
			jsr	prnt_dev		;Ausgabe SCSI-Gerät.

			jsr	srcPartUpdate		;Quell-Partition aktualisieren.
			jsr	reg_prntSrcPTab		;Partitionstabelle ausgeben.

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:update80src		; => 80Z, weiter...

::update40src		LoadW	r15,RTabMenu40_1e	;40Z: Partitionsname aktualisieren.
			jsr	RegisterUpdate

			jmp	:updateTgt

::update80src		LoadW	r15,RTabMenu80_1e	;80Z: Partitionsname aktualisieren.
			jsr	RegisterUpdate

::updateTgt		lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			lda	scsiTgtID		;SCSI-ID Ziel-Laufwerk einlesen.
			sta	scsiComID		;Als aktuelle SCSI-ID festlegen.
			jsr	copyTgtDevInfo		;Daten für Ziel-Laufwerk einlesen.
			jsr	prnt_id			;Ausgabe SCSI-ID.
			jsr	prnt_dev		;Ausgabe SCSI-Gerät.

			jsr	tgtPartInit		;Ziel-Partition initialisieren.
			jsr	reg_prntTgtPTab		;Partitionstabelle anzeigen.

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:update80tgt		; => 80Z, weiter...

::update40tgt		LoadW	r15,RTabMenu40_1f	;40Z: Partitionsname aktualisieren.
			jsr	RegisterUpdate

			jmp	:endUpdate

::update80tgt		LoadW	r15,RTabMenu80_1f	;80Z: Partitionsname aktualisieren.
			jsr	RegisterUpdate

::endUpdate		rts

;*** Register-Funktion: Ausgabe SCSI-Geräte ID.
:reg_prntSrcID		lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			sta	modeSrcTgt

			lda	scsiSrcID		;Aktuelle SCSI-ID einlesen und
			sta	scsiComID		;zwischenspeichern.

			bit	r1L			;Register anzeigen/ändern?
			bpl	prnt_id			; => Nur anzeigen, weiter...

			jsr	getNextSCSI		;Nächste SCSI-Adresse suchen.
			cmp	scsiSrcID		;SCSI-ID geändert?
			beq	:exit			; => Nein, Abbruch...
			sta	scsiSrcID		;Neue SCSI-ID speichern und
			sta	scsiComID		;Laufwerksdaten aktualisieren.

			jsr	scsiMediaREADY		;Auf Medium im Laufwerk testen.
							;Auswertung nicht erforderlich, da
							;ggf. "Kein Medium" angezeigt wird.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

			jmp	updateSrcID
::exit			rts				;Abbruch.

:reg_prntTgtID		lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			lda	scsiTgtID		;Aktuelle SCSI-ID einlesen und
			sta	scsiComID		;zwischenspeichern.

			bit	r1L			;Register anzeigen/ändern?
			bpl	prnt_id			; => Nur anzeigen, weiter...

			jsr	getNextSCSI		;Nächste SCSI-Adresse suchen.
			cmp	scsiTgtID		;SCSI-ID geändert?
			beq	:exit			; => Nein, Abbruch...
			sta	scsiTgtID		;Neue SCSI-ID speichern und
			sta	scsiComID		;Laufwerksdaten aktualisieren.

			jsr	scsiMediaREADY		;Auf Medium im Laufwerk testen.
							;Auswertung nicht erforderlich, da
							;ggf. "Kein Medium" angezeigt wird.
;			txa				;Fehler?
;			bne	:exit			; => Ja, Abbruch...

			jmp	updateTgtID
::exit			rts				;Abbruch.

;*** ID/Gerät für Quelle/Ziel ausgeben.
:prnt_id		jsr	setIdXPos		;Ausgabeposition festlegen.

			lda	#R40Area1_2y0 +RLine1_1 +$06
			sta	r1H			;Ausgabezeile festlegen.

			lda	scsiComID		;SCSI-ID einlesen und Bit %0-%2
			and	#%00000111		;isolieren (Nur Adr #0-#7 gültig).
			clc				;Nach ASCII wandeln.
			adc	#"0"
			jmp	SmallPutChar		;SCSI-ID ausgeben.

;*** Register-Menü:
;    X-Position für Ausgabe SCSI-ID festlegen.
:setIdXPos		bit	modeSrcTgt		;Ausgabemodus Quelle oder Ziel?
			bmi	:target			; => Ziel, weiter...

::source		bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:source80		; => 80Z, weiter...

::source40		lda	#<R40Area1_2x0 +$10
			ldx	#>R40Area1_2x0 +$10
			jmp	:setXpos

::source80		lda	#<R80Area1_2x0 +$20
			ldx	#>R80Area1_2x0 +$20
			jmp	:setXpos

::target		bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:target80		; => 80Z, weiter...

::target40		lda	#<R40Area1_3x0 +$10
			ldx	#>R40Area1_3x0 +$10
			jmp	:setXpos

::target80		lda	#<R80Area1_3x0 +$20
			ldx	#>R80Area1_3x0 +$20

::setXpos		clc				;X-Position um 1px korrigieren und
			adc	#$01			;als Ausgabeposition speichern.
			sta	r11L
			bcc	:1
			inx
::1			stx	r11H
			rts

;*** Register-Funktion: Ausgabe SCSI-Geräte ID/Typ.
:reg_prntSrcDev		lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			b $2c
:reg_prntTgtDev		lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt		;Ausgabemodus speichern.

;*** ID/Gerät für Quelle/Ziel ausgeben.
:prnt_dev		jsr	setDevWin		;Textausgabe einschränken.
			jsr	clrRegOptArea		;Optionsfeld löschen.

			jsr	setDevXPos		;Ausgabeposition festlegen.

			lda	#R40Area1_2y0 +RLine1_1 +$06
			sta	r1H			;Ausgabezeile festlegen.

			bit	modeSrcTgt		;Ausgabemodus Quelle oder Ziel?
			bmi	:target1		; => Ziel, weiter...

::source1		lda	#<scsiSrcVendor		;Quelle: Gerätehersteller.
			ldx	#>scsiSrcVendor
			bne	:1
::target1		lda	#<scsiTgtVendor		;Ziel: Gerätehersteller.
			ldx	#>scsiTgtVendor
::1			sta	r0L
			stx	r0H
			jsr	PutString		;Gerätehersteller ausgeben.

			jsr	setDevXPos		;Ausgabeposition festlegen.

			lda	#R40Area1_2y0 +RLine1_1 +$08 +$06
			sta	r1H			;Ausgabezeile festlegen.

			bit	modeSrcTgt		;Ausgabemodus Quelle oder Ziel?
			bmi	:target2		; => Ziel, weiter...

::source2		lda	#<scsiSrcModel		;Quelle: Gerätetyp.
			ldx	#>scsiSrcModel
			bne	:2
::target2		lda	#<scsiTgtModel		;Ziel: Gerätetyp.
			ldx	#>scsiTgtModel
::2			sta	r0L
			stx	r0H
			jsr	PutString		;Gerätetyp ausgeben.

			jmp	resetTxtArea		;Grenzen für Textausgabe löschen.

;*** Register-Menü:
;    X-Position für Ausgabe SCSI-Gerät festlegen.
:setDevXPos		bit	modeSrcTgt		;Ausgabemodus Quelle oder Ziel?
			bmi	:target			; => Ziel, weiter...

::source		bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:source80		; => 80Z, weiter...

::source40		lda	#<R40Area1_2x0 +$20
			ldx	#>R40Area1_2x0 +$20
			jmp	:setXpos

::source80		lda	#<R80Area1_2x0 +$40
			ldx	#>R80Area1_2x0 +$40
			jmp	:setXpos

::target		bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:target80		; => 80Z, weiter...

::target40		lda	#<R40Area1_3x0 +$20
			ldx	#>R40Area1_3x0 +$20
			jmp	:setXpos

::target80		lda	#<R80Area1_3x0 +$40
			ldx	#>R80Area1_3x0 +$40

::setXpos		clc				;X-Position um 1px korrigieren und
			adc	#$01			;als Ausgabeposition speichern.
			sta	r11L
			bcc	:1
			inx
::1			stx	r11H
			rts

;*** Register-Funktion: Ausgabe SCSI-Geräte ID/Typ.
:reg_updateSrcDev	lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			sta	modeSrcTgt

			lda	scsiSrcID		;SCSI-ID einlesen und für SCSI
			sta	scsiComID		;Befehl zwischenspeichern.
			jsr	scsiMediaREADY		;Auf Medium im Laufwerk testen.
			txa				;Fehler?
			bne	exitSrcID		; => Ja, Abbruch...

:updateSrcID		jsr	initDevSrcID		;Laufwerksdaten initialisieren.

			jsr	copySrcDevInfo		;Daten für Quell-Laufwerk einlesen.
			jsr	prnt_id			;Ausgabe SCSI-ID.
			jsr	prnt_dev		;Ausgabe SCSI-Gerät.

			lda	#$00
			bit	cmdPartSrcRdy		;Laufwerk bereit?
			bpl	:update			; => Nein, weiter...

			jsr	initDevSrcPTab		;Partitionstabelle initialisieren.
			ldx	devErrorHD		;Fehler aufgetreten?
			bne	exitSrcID		; => Ja, Abbruch...

			jsr	findSrcPart		;Partition suchen.
			txa
::update		jsr	prntSrcPart		;Partitionsdaten ausgeben.

			lda	#$00			;Zeiger auf Anfang der Tabelle.
			sta	pTabPosSrc
			jmp	reg_prntSrcPTab		;Partitionstabelle ausgeben.

:exitSrcID		rts

;*** Register-Menü:
;    Ausgabe SCSI-Geräte ID/Typ.
:reg_updateTgtDev	lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			lda	scsiTgtID		;SCSI-ID einlesen und für SCSI
			sta	scsiComID		;Befehl zwischenspeichern.
			jsr	scsiMediaREADY		;Auf Medium im Laufwerk testen.
			txa				;Fehler?
			bne	exitTgtID		; => Ja, Abbruch...

:updateTgtID		jsr	initDevTgtID		;Laufwerksdaten initialisieren.

			jsr	copyTgtDevInfo		;Daten für Ziel-Laufwerk einlesen.
			jsr	prnt_id			;Ausgabe SCSI-ID.
			jsr	prnt_dev		;Ausgabe SCSI-Gerät.

			lda	#$00
			bit	cmdPartTgtRdy		;Laufwerk bereit?
			bpl	:update			; => Nein, weiter...

			jsr	initDevTgtPTab		;Partitionstabelle initialisieren.
			ldx	devErrorHD		;Fehler aufgetreten?
			bne	exitTgtID		; => Ja, Abbruch...

			jsr	findTgtPart		;Partition suchen.
			txa
::update		jsr	prntTgtPart		;Partitionsdaten ausgeben.

			lda	#$00			;Zeiger auf Anfang der Tabelle.
			sta	pTabPosTgt
			jmp	reg_prntTgtPTab		;Partitionstabelle ausgeben.

:exitTgtID		rts

;*** Register-Funktion: Ausgabe Partitionstyp.
:reg_prntSrcPTyp	lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			sta	modeSrcTgt

			jsr	setPTypeWin		;Grenzen für Partitionstyp-Feld.
			jsr	clrRegOptArea		;Optionsfeld löschen.

			bit	cmdPartSrcRdy		;Quell-Laufwerk bereit?
			bmi	prntPTypInfo		; => Ja, Partitionsdaten ausgeben.
			bpl	prntPTypNoMedia		; => Nein, "Kein Medium eingeelegt"

:reg_prntTgtPTyp	lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			jsr	setPTypeWin		;Grenzen für Partitionstyp-Feld.
			jsr	clrRegOptArea		;Optionsfeld löschen.

			bit	cmdPartTgtRdy		;Ziel-Laufwerk bereit?
			bmi	prntPTypInfo		; => Ja, Partitionsdaten ausgeben.
;			bpl	prntPTypNoMedia		; => Nein, "Kein Medium eingeelegt"

;*** Kein Medum im Laufwerk.
:prntPTypNoMedia	jmp	resetTxtArea		;Grenzen für Textausgabe löschen.

;*** Quelle-/Ziel-Partitionen anzeigen.
:prntPTypInfo		lda	leftMargin +0		;Linke Position Quelle/Ziel für
			clc				;aus den gesetzten Textgrenzen
			adc	#$02			;berechnen.
			sta	r11L
			lda	leftMargin +1
			adc	#$00
			sta	r11H

			lda	#R40Area1_2y0 +RLine1_2 +$06
			sta	r1H			;Ausgabezeile festlegen.

			bit	modeSrcTgt		;Quell- oder Ziel-Laufwerk?
			bmi	:target1		; => Ziel-Laufwerk.

::source1		lda	#<cmdPartSrcTxt		;Quelle: Partitionstyp.
			ldx	#>cmdPartSrcTxt
			bne	:1
::target1		lda	#<cmdPartTgtTxt		;Ziel: Partitionstyp.
			ldx	#>cmdPartTgtTxt
::1			sta	r0L
			stx	r0H
			jsr	PutString		;Partitionstyp ausgeben.

			jmp	resetTxtArea		;Grenzen für Textausgabe löschen.

;*** Register-Funktion: Ausgabe Partitionsname/Größe.
:reg_prntSrcPart	lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			sta	modeSrcTgt

			jsr	setPInfoWin		;Grenzen für Partitionsinfo-Feld.
			jsr	clrRegOptArea		;Optionsfeld löschen.

			bit	cmdPartSrcRdy		;Quell-Laufwerk bereit?
			bmi	prntPartInfo		; => Ja, Partitionsdaten ausgeben.
			bpl	prntPartNoMedia		; => Nein, "Kein Medium eingeelegt"

:reg_prntTgtPart	lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			jsr	setPInfoWin		;Grenzen für Partitionsinfo-Feld.
			jsr	clrRegOptArea		;Optionsfeld löschen.

			bit	cmdPartTgtRdy		;Ziel-Laufwerk bereit?
			bmi	prntPartInfo		; => Ja, Partitionsdaten ausgeben.
;			bpl	prntPartNoMedia		; => Nein, "Kein Medium eingeelegt"

;*** Kein Medum im Laufwerk.
:prntPartNoMedia	jsr	setPartXPos		;Ausgabeposition festlegen.

			lda	#R40Area1_2y0 +RLine1_3 +$06
			sta	r1H			;Ausgabezeile festlegen.

			LoadW	r0,noMedia		;Text "Kein Medium eingelegt!"
			jsr	PutString		;ausgeben.

			jmp	resetTxtArea		;Grenzen für Textausgabe löschen.

;*** Quelle-/Ziel-Partitionen anzeigen.
:prntPartInfo		jsr	setPartXPos		;Ausgabeposition festlegen.

			lda	#R40Area1_2y0 +RLine1_3 +$06
			sta	r1H			;Ausgabezeile festlegen.

			bit	modeSrcTgt		;Quell- oder Ziel-Laufwerk?
			bmi	:target1		; => Ziel-Laufwerk.

::source1		lda	#<cmdPartSrcNam		;Quelle: Partitionsname.
			ldx	#>cmdPartSrcNam
			bne	:1
::target1		lda	#<cmdPartTgtNam		;Ziel: Partitionsname.
			ldx	#>cmdPartTgtNam
::1			sta	r0L
			stx	r0H
			jsr	PutString		;Partitionsname ausgeben.

			jsr	setPartXPos		;Ausgabeposition festlegen.

			lda	#R40Area1_2y0 +RLine1_3 +$08 +$06
			sta	r1H			;Ausgabezeile festlegen.

			LoadW	r0,RxxT01d		;Text "Größe:" ausgeben.
			jsr	PutString

			bit	modeSrcTgt		;Quell- oder Ziel-Laufwerk?
			bmi	:target2		; => Ziel-Laufwerk.

::source2		lda	cmdPartSrcSize +1	;Quelle: Partitionsgröße.
			ldx	cmdPartSrcSize +0	;(Reverse byte order!)
			bne	:2
::target2		lda	cmdPartTgtSize +1	;Ziel: Partitionsgröße.
			ldx	cmdPartTgtSize +0	;(Reverse byte order!)
::2			sta	r0L
			stx	r0H
			lsr	r0H			;512-Byte-Blocks / 2 = Kb.
			ror	r0L
			lda	#SET_LEFTJUST!SET_SUPRESS
			jsr	PutDecimal		;Partitionsgröße ausgeben.

			lda	#"K"			;Text "Kb" ausgeben.
			jsr	SmallPutChar
			lda	#"b"
			jsr	SmallPutChar

			jmp	resetTxtArea		;Grenzen für Textausgabe löschen.

;*** X-Position für Ausgabe Partition festlegen.
:setPartXPos		bit	modeSrcTgt		;Quell- oder Ziel-Laufwerk?
			bmi	:target			; => Ziel-Laufwerk.

::source		bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:source80		; => 80Z, weiter...

::source40		lda	#<R40Area1_2x0 +$08
			ldx	#>R40Area1_2x0 +$08
			jmp	:setXpos

::source80		lda	#<R80Area1_2x0 +$10
			ldx	#>R80Area1_2x0 +$10
			jmp	:setXpos

::target		bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:target80		; => 80Z, weiter...

::target40		lda	#<R40Area1_3x0 +$08
			ldx	#>R40Area1_3x0 +$08
			jmp	:setXpos

::target80		lda	#<R80Area1_3x0 +$10
			ldx	#>R80Area1_3x0 +$10

::setXpos		clc				;X-Position um 1px korrigieren und
			adc	#$01			;als Ausgabeposition speichern.
			sta	r11L
			bcc	:1
			inx
::1			stx	r11H
			rts

;*** Register-Funktion: Ausgabe Partitionstabelle.
:reg_prntSrcPTab	lda	cmdPartSrcRdy		;Laufwerksstatus einlesen und
			pha				;zwischenspeichern.

			lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			jmp	prntPTabInfo

:reg_prntTgtPTab	lda	cmdPartTgtRdy		;Laufwerksstatus einlesen und
			pha				;zwischenspeichern.

			lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			jmp	prntPTabInfo

;*** Kein Medum im Laufwerk.
:prntPTabNoMedia	jsr	setPTabXPos1		;Ausgabeposition festlegen.

			lda	#R40Area1_2y0 +RLine1_4 +$06
			sta	r1H			;Ausgabezeile festlegen.

			LoadW	r0,noMedia		;Text "Kein Medium eingelegt!"
			jsr	PutString		;ausgeben.

			jmp	exitPTabInfo		;Zeichensatz zurücksetzen.

;*** Quell-/Ziel-Partitionstabelle.
:prntPTabInfo		sta	modeSrcTgt		;Ausgabemodus speichern.

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:init			; => 80Z, weiter...

::40			LoadW	r0,FontG3		;40Z/SmallFont aktivieren.
			jsr	LoadCharSet

::init			jsr	setPTabWin		;Textgrenzen setzen.

			jsr	clrRegOptArea		;Optionsfeld löschen.

			pla				;Flag: "Laufwerk bereit?" einlesen.
			bpl	prntPTabNoMedia		; => Nicht bereit, Abbruch...

			bit	modeSrcTgt		;Quell- oder Ziel-Laufwerk?
			bmi	:target			; => Ziel-Laufwerk.

::source		LoadW	r14,cmdPartSrcList
			lda	pTabPosSrc
			ldx	pTabMaxSrc		;Partitionen vorhanden?
			beq	prntPTabNoMedia		; => Nein, Abbruch...
			bne	:prntList		; => Ja, weiter...

::target		LoadW	r14,cmdPartTgtList
			lda	pTabPosTgt
			ldx	pTabMaxTgtBuf		;Partitionen vorhanden?
			beq	prntPTabNoMedia		; => Nein, Abbruch...

::prntList		sta	pTabCurPos		;Aktuelle Pos. in Tabelle.
			stx	pTabMaxCount		;Max. Anzahl an Partitionen.

			ldy	#$00
			sty	pTabCount		;Ausgabezähler löschen.
			lda	#$ff			;Liste der angezeigten Partitionen
::0			sta	(r14L),y		;in der Tabelle löschen.
			iny
			cpy	#$04
			bcc	:0

::loop			lda	pTabCurPos		;Zeiger auf Partition einlesen.
			bit	modeSrcTgt		;Quelle oder Ziel?
			bpl	:10			; => Quelle, weiter...
			tax
			lda	tgtPTypeData,x		;Ziel-Partition einlesen.
::10			jsr	setAdrPartData		;Zeiger auf Partitionseintrag.

			ldy	#$01
			lda	(r15L),y		;Partitionstyp einlesen.

			bit	modeSrcTgt		;Quelle oder Ziel?
			bpl	:1			; => Quelle, weiter...

			cmp	cmdPartSrcTyp		;Typ wie Quell-Laufwerk?
			bne	:2			; => Nein, Partition überspringen.

::1			ldy	pTabCount		;angezeigten Partitionen eintragen.
			lda	pTabCurPos		;Partition in die Liste der
			sta	(r14L),y

			jsr	prntPartEntry		;Partitionseintrag ausgeben.

			inc	pTabCount
			lda	pTabCount		;Partitionszähler +1.
			cmp	#$04			;Ist Tabelle voll?
			bcs	:4			; => Ja, Ende...

::2			inc	pTabCurPos		;Partitionszähler +1.
			lda	pTabCurPos
			cmp	pTabMaxCount		;Alle Partitionen durchsucht?
			bcc	:loop			; => Nein, weiter...

::4			ldy	#$00
			lda	(r14L),y		;Mind. 1 Partition gefunden?
			beq	exitPTabInfo		; => Nein, Ende...

			bit	modeSrcTgt		;Quelle oder Ziel?
			bmi	:5			; => Ziel-Laufwerk.
			sta	pTabPosSrc		;Aktuelle Position Quell-Laufwerk.
			bpl	exitPTabInfo
::5			sta	pTabPosTgt		;Aktuelle Position Ziel-Laufwerk.

:exitPTabInfo		jsr	resetTxtArea		;Textgrenzen zurücksetzen.
			jmp	RegisterSetFont		;Zeichensatz zurücksetzen.

;*** Partitionsdaten ausgeben.
:prntPartEntry		lda	pTabCount		;Listenzähler einlesen.
			asl				;Y-Position für Ausgabe berechnen.
			asl
			asl
			clc
			adc	windowTop
			clc
			adc	#$06
			sta	r1H

			jsr	setPTabXPos1		;X-Position/Spalte: Part.-Nr.
			jsr	doPrntPartNr		;Partitions-Nr. ausgeben.

			jsr	setPTabXPos2		;X-Position/Spalte: Part.-Typ.
			jsr	doPrntPType		;Partitionstyp ausgeben.

			jsr	setPTabXPos3		;X-Position/Spalte: Part.-Größe.
			jsr	doPrntPSize		;Partitionsgröße ausgeben.

			jsr	setPTabXPos4		;X-Position/Spalte: Part.-Name.
			jsr	doPrntPName		;Partitionsname ausgeben.

			ldy	#$00
			lda	(r15L),y		;Partitions-Nummer einlesen.
			bit	modeSrcTgt		;Quell- oder Ziel-Laufwerk?
			bmi	:target			; => Ziel-Laufwerk.
::source		cmp	cmdPartSrc		;Aktive Quell-Partition gefunden?
			clc
			bcc	:compare		;Unbedingter Sprung...
::target		cmp	cmdPartTgt		;Aktive Ziel-Partition gefunden?
::compare		bne	:exit			; => Nein, weiter...

			lda	pTabCount		;X/Y-Position für Bereich der
			asl				;aktiven Partition innerhalb der
			asl				;Partitionstabelle berechnen.
			asl
			clc
			adc	windowTop
			sta	r2L
			clc
			adc	#$07
			sta	r2H
			MoveW	leftMargin,r3
			MoveW	rightMargin,r4
			jsr	InvertRectangle		;Aktive Partition invertieren.

::exit			rts

;*** Ausgabebereich Register-Optionsfeld löschen.
:clrRegOptArea		lda	#$00			;Fülllmuster setzen.
			jsr	SetPattern

			MoveB	windowTop,r2L		;Grenzen für Partitionstabelle
			MoveB	windowBottom,r2H	;festlegen.
			MoveW	leftMargin,r3
			MoveW	rightMargin,r4
			jmp	Rectangle		;Bereich löschen.

;*** X-Position für Ausgabe Partitionstabelle festlegen.
:setPTabXPos1		ldy	#$00			;Nummer.
			b $2c
:setPTabXPos2		ldy	#$01			;Typ.
			b $2c
:setPTabXPos3		ldy	#$02			;Größe.
			b $2c
:setPTabXPos4		ldy	#$03			;Name.

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:80			; => 80Z, weiter...

::40			lda	pTabXPos40,y		;40Z: Spaltenposition einlesen.
			bne	:setXPos

::80			lda	pTabXPos80,y		;80Z: Spaltenposition einlesen.

::setXPos		clc				;Spalten-Position zum linken Rand
			adc	leftMargin +0		;addieren.
			sta	r11L
			lda	leftMargin +1
			adc	#$00
			sta	r11H
			rts

;*** Partitionsnummer aussgeben.
:doPrntPartNr		ldy	#$00
			lda	(r15L),y		;Partitionsnummer einlesen und
			sta	r0L			;speichern.
			lda	#$00			;High-Byte löschen.
			sta	r0H
			lda	#SET_LEFTJUST!SET_SUPRESS
			jmp	PutDecimal		;Partitionsnummer ausgeben.

;*** Partitionstyp ausgeben.
:doPrntPType		ldy	#$01
			lda	(r15L),y		;Partitionstyp einlesen und
			tax				;Kennung aus Tabelle einlesen.
			lda	pTypeTxShort,x
			jmp	SmallPutChar		;Partitionstyp ausgeben.

;*** Partitionsgröße in Blocks ausgeben.
:doPrntPSize		ldy	#$06
			lda	(r15L),y		;Low-Byte Partitionsgröße einlesen.
			asl				;(Reverse byte order!)
			sta	r0L
			dey
			lda	(r15L),y		;Low-Byte Partitionsgröße einlesen.
			rol				;Anzahl Sektoren/2 = Anzahl Blocks.
			sta	r0H
			ora	r0L
			beq	:1
			lda	#SET_LEFTJUST!SET_SUPRESS
			jmp	PutDecimal		;Blockanzahl ausgeben.

::1			LoadW	r0,size64Kb		;64K als Text ausgeben.
			jmp	PutString

;*** Register-Menü:
;    Ausgabe Partitionstabelle.
;    -> Partitionsname ausgeben.
:doPrntPName		ldy	#$07			;Zeiger auf Anfang Partitionsname.
::2			tya
			pha
			lda	(r15L),y		;Zeichen einlesen, Ende erreicht?
			beq	:3			; => Ja, weiter...
			jsr	SmallPutChar		;Zeichen ausgeben.
::3			pla
			tay
			iny
			cpy	#$07 +16		;Alle Zeichen ausgegeben?
			bcc	:2			; => Nein, weiter...
			rts

;*** Register-Funktion: Neue Quell-Partition eingeben.
:reg_findSrcPart	jsr	findSrcPart		;Quell-Partition suchen.
			txa				;Partitions-Nr.
			jmp	prntSrcPart		;Neue Partition ausgeben.

;*** Quell-Partition suchen.
;Übergabe: cmdPartSrc = Gesuchte Partition.
;Rückgabe: partFound  = 255, nicht gefunden.
:findSrcPart		lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			sta	modeSrcTgt

			lda	#$ff			;Flag löschen: "Partition OK".
			sta	partFound

			lda	#$00			;Zeiger auf Anfang der
			jsr	setAdrPartData		;Partitionstabelle setzen.

			ldx	#$00			;Partitionszähler löschen.
::1			cpx	pTabMaxSrc		;Alle Partitionen durchsucht?
			bcs	:4			; => Ja, Abbruch...

			ldy	#$00
			lda	(r15L),y		;Partitions-Nr. einlesen.
			cmp	cmdPartSrc		;Gesuchte Partition gefunden?
			beq	:4			; => Ja, weiter...
			bcs	:2			;Nr ist größer => Weiter...
			stx	partFound		;Partition merken.

::2			jsr	add24r15		;Zeiger auf nächste Partition.

			inx				;Alle Partitionen suchsucht?
			bne	:1			; => Nein, weiter...

			ldx	partFound		;Letzte Partition einlesen.
::4			stx	partFound		;Nr. Partition in Tabelle speichern.
			rts

;*** Register-Funktion: Neue Ziel-Partition suchen.
:reg_findTgtPart	jsr	findTgtPart		;Ziel-Partition suchen.
			txa				;Partitions-Nr.
			jmp	prntTgtPart		;Neue Partition ausgeben.

;*** Ziel-Partition suchen.
;Übergabe: cmdPartTgt = Gesuchte Partition.
;Rückgabe: partFound  = 255, nicht gefunden.
:findTgtPart		lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			lda	#$ff			;Flag löschen: "Partition OK".
			sta	partFound

			lda	#$00			;Zeiger auf Anfang der
			jsr	setAdrPartData		;Partitionstabelle setzen.

			ldx	#$00			;Partitionszähler löschen.
::1			cpx	pTabMaxTgt		;Alle Partitionen durchsucht?
			bcs	:3			; => Ja, Abbruch...

			ldy	#$01
			lda	(r15L),y		;Partitionstyp einlesen.
			cmp	cmdPartSrcTyp		;Gleich wie Quell-Laufwerk?
			bne	:2			; => Nein, weiter...

			ldy	cmdPartTgt		;Erste oder bestimmte Part. suchen?
			bne	:5a			; => Bestimmte Partition suchen.
			stx	partFound		;Erste Partition merken.
			beq	:4			; => Erste Partition gefunden...

::5a			ldy	#$00
			lda	(r15L),y		;Partitions-Nr. einlesen.
			cmp	cmdPartTgt		;Gesuchte Partition gefunden?
			beq	:4			; => Ja, weiter...
			bcs	:2			;Nr ist größer => Weiter...
::5			stx	partFound		;Partition merken.

::2			jsr	add24r15		;Zeiger auf nächste Partition.

			inx				;Alle Partitionen suchsucht?
			bne	:1			; => Nein, weiter...

::3			ldx	partFound		;Letzte Partition einlesen.
::4			stx	partFound		;Nr. Partition in Tabelle speichern.
			rts

;*** Register-Funktion: Neue Partition aus Partitionstabelle setzen.
:reg_setSrcPart		bit	r1L			;Partition aus Tabelle wählen?
			bmi	:updatePart		; => Ja, weiter...
			jmp	initSrcPart		;Partitionstabelle ausgeben.

::updatePart		lda	#SETDEVSRC		;Ausgabemodus: Quell-Laufwerk.
			sta	modeSrcTgt

			lda	mouseYPos		;Mausposition auswerten.
			sec
			sbc	#R40Area1_2y0 +RLine1_4
			bcc	exitSrcPart		; => Ausserhalb Partitionstabelle.
			cmp	#4*8
			bcs	exitSrcPart		; => Ausserhalb Partitionstabelle.
			lsr
			lsr
			lsr
			tax
			lda	cmdPartSrcList,x	;Partitions-Nr. in Tabelle einlesen.
			cmp	#$ff			;Partition vorhanden?
			beq	exitSrcPart		; => Nein, Abbruch...
			cmp	pTabMaxSrc		;Partition gültig?
			bcc	prntSrcPart		; => Ja, Partition ausgeben.
:exitSrcPart		rts				;Abbruch.

;*** Partition aus Partitionstabelle anzeigen.
:prntSrcPart		jsr	setAdrPartData		;Zeiger auf Partitionseintrag.

			jsr	copySrcPData		;Partitionsdaten einlesen.

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:update80		; => 80Z, weiter...

::update40		LoadW	r15,RTabMenu40_1a	;40Z: Partitions-Nr. aktualisieren.
			jsr	RegisterUpdate

;--- Hinweis:
;Inaktive Infobox, die mit DirectColor
;eingefärbt wird, nicht über die
;RegisterFunktion aktualisieren, da die
;Farbe sonst zurückgesetzt wird.
;			LoadW	r15,RTabMenu40_1c	;40Z: Partitionstyp aktualisieren.
;			jsr	RegisterUpdate

;			LoadW	r15,RTabMenu40_1e	;40Z: Partitionsname aktualisieren.
;			jsr	RegisterUpdate

			jmp	:endUpdate

::update80		LoadW	r15,RTabMenu80_1a	;80Z: Partitions-Nr. aktualisieren.
			jsr	RegisterUpdate

;--- Hinweis:
;Inaktive Infobox, die mit DirectColor
;eingefärbt wird, nicht über die
;RegisterFunktion aktualisieren, da die
;Farbe sonst zurückgesetzt wird.
;			LoadW	r15,RTabMenu80_1c	;80Z: Partitionstyp aktualisieren.
;			jsr	RegisterUpdate

;			LoadW	r15,RTabMenu80_1e	;80Z: Partitionsname aktualisieren.
;			jsr	RegisterUpdate

::endUpdate		jsr	reg_prntSrcPTyp		;Quell-Partitionstyp ausgeben.
			jsr	reg_prntSrcPart		;Quell-Partition ausgeben.
			jsr	reg_prntSrcPTab		;Quell-Partitionstabelle ausgeben.

			bit	partSyncMode		;Quelle/Ziel synchronisieren?
			bmi	:1			; => Ja, weiter...

			lda	cmdPartSrcTyp		;Partitionstyp von
			cmp	cmdPartTgtTyp		;Quell und Ziel gleich?
			beq	exitSrcPart		; => Ja, weiter...

			lda	#$00			;Partitionstabelle auf Angfang.
			beq	:2

::1			lda	cmdPartSrc		;Sync: Partition setzen.

::2			jsr	tgtPartInitSync		;Partitionsliste initialisieren.

			lda	partFound
			jmp	prntTgtPart		;Ziel-Partition aktualisieren.

;*** Partitionstabelle anzeigen.
:initSrcPart		lda	C_InputField		;Farbe setzen.
			jsr	DirectColor
			jsr	setBorder		;Rahmen setzen.
			lda	#%11111111
			jsr	FrameRectangle
			jmp	reg_prntSrcPTab		;Quell-Partitionstabelle ausgeben.

;*** Register-Funktion: Neue Partition aus Partitionstabelle setzen.
:reg_setTgtPart		bit	r1L			;Partition aus Tabelle wählen?
			bmi	:updatePart		; => Ja, weiter...
			jmp	initTgtPart		;Partitionstabelle ausgeben.

::updatePart		lda	#SETDEVTGT		;Ausgabemodus: Ziel-Laufwerk.
			sta	modeSrcTgt

			lda	mouseYPos		;Mausposition auswerten.
			sec
			sbc	#R40Area1_3y0 +RLine1_4
			bcc	exitTgtPart		; => Ausserhalb Partitionstabelle.
			cmp	#4*8
			bcs	exitTgtPart		; => Ausserhalb Partitionstabelle.
			lsr
			lsr
			lsr
			tax
			lda	cmdPartTgtList,x	;Partitions-Nr. in Tabelle einlesen.
			tax
			lda	tgtPTypeData,x
			cmp	#$ff			;Partition vorhanden?
			beq	exitTgtPart		; => Nein, Abbruch...
			cmp	pTabMaxTgt		;Partition gültig?
			bcc	prntTgtPart		; => Ja, Partition ausgeben.
:exitTgtPart		rts				;Abbruch.

:prntTgtPart		jsr	setAdrPartData		;Zeiger auf Partitionseintrag.

			jsr	copyTgtPData		;Partitionsdaten einlesen.

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:update80		; => 80Z, weiter...

::update40		LoadW	r15,RTabMenu40_1b	;40Z: Partitions-Nr. aktualisieren.
			jsr	RegisterUpdate

;--- Hinweis:
;Inaktive Infobox, die mit DirectColor
;eingefärbt wird, nicht über die
;RegisterFunktion aktualisieren, da die
;Farbe sonst zurückgesetzt wird.
;			LoadW	r15,RTabMenu40_1d	;40Z: Partitionstyp. aktualisieren.
;			jsr	RegisterUpdate

;			LoadW	r15,RTabMenu40_1f	;40Z: Partitionsname aktualisieren.
;			jsr	RegisterUpdate

			jmp	:endUpdate

::update80		LoadW	r15,RTabMenu80_1b	;80Z: Partitions-Nr. aktualisieren.
			jsr	RegisterUpdate

;--- Hinweis:
;Inaktive Infobox, die mit DirectColor
;eingefärbt wird, nicht über die
;RegisterFunktion aktualisieren, da die
;Farbe sonst zurückgesetzt wird.
;			LoadW	r15,RTabMenu80_1d	;80Z: Partitionstyp aktualisieren.
;			jsr	RegisterUpdate

;			LoadW	r15,RTabMenu80_1f	;80Z: Partitionsname aktualisieren.
;			jsr	RegisterUpdate

::endUpdate		jsr	reg_prntTgtPTyp		;Ziel-Partitionstyp ausgeben.
			jsr	reg_prntTgtPart		;Ziel-Partition ausgeben.
			jmp	reg_prntTgtPTab		;Ziel-Partitionstabelle ausgeben.

;*** Partitionstabelle anzeigen.
:initTgtPart		lda	C_InputField		;Farbe setzen.
			jsr	DirectColor
			jsr	setBorder		;Rahmen setzen.
			lda	#%11111111
			jsr	FrameRectangle
			jmp	reg_prntTgtPTab		;Ziel-Partitionstabelle ausgeben.

;*** Register-Funktion: Partitionstabelle/Quelle vorwärts.
:reg_PTabSrcDn		lda	pTabMaxSrc		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			ldx	pTabPosSrc		;Position einlesen.
			inx				;Zeiger auf nächste Partition.
			cpx	pTabMaxSrc		;Letzte Partition?
			bcs	:exit			; => Ja, Abbruch...
			txa
			clc
			adc	#$04 -1
			cmp	pTabMaxSrc		;ScrollDown möglich?
			bcs	:exit			; => Nein, Ende...
			stx	pTabPosSrc		;Neue Position setzen.
			jmp	reg_prntSrcPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Quelle zurück.
:reg_PTabSrcUp		lda	pTabMaxSrc		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			ldx	pTabPosSrc		;Bereits am Anfang der Tabelle.
			beq	:exit			; => Ja, Abbruch...
			dex
			stx	pTabPosSrc		;Neue Position speichern.
			jmp	reg_prntSrcPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Quelle Seite zurück.
:reg_PTabSrcPr		lda	pTabMaxSrc		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			lda	pTabPosSrc		;Bereits am Anfang der Tabelle?
			beq	:exit			; => Ja, Abbruch...
			sec
			sbc	#$04			;Seite zurück möglich?
			bcs	:1			; => Ja, weiter...
			lda	#$00			;Zum Anfang der Tabelle.
::1			sta	pTabPosSrc		;Neue Position speichern.
			jmp	reg_prntSrcPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Quelle Seite vorwärts.
:reg_PTabSrcNx		lda	pTabMaxSrc		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			lda	pTabPosSrc		;Bereits am Anfang der Tabelle?
			clc				;Zeiger auf nächste Seite.
			adc	#$04			;Überlauf?
			bcs	reg_PTabSrcEnd		; => Ja, zum Ende springen.
			tax
			clc
			adc	#$04 -1			;Zeiger auf nächste Seite.
			cmp	pTabMaxSrc		;Letzte Partition erreicht?
			bcs	reg_PTabSrcEnd		; => Ja, zum Ende springen.
			stx	pTabPosSrc		;Neue Position speichern.
			jmp	reg_prntSrcPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Quelle zum Anfang.
:reg_PTabSrcTop		lda	pTabMaxSrc		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			lda	#$00			;Zum Anfang der Tabelle.
			cmp	pTabPosSrc		;Position geändert?
			beq	:exit			; => Nein, Ende...
			sta	pTabPosSrc		;Neue Position speichern.
			jmp	reg_prntSrcPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Quelle zum Ende.
:reg_PTabSrcEnd		lda	pTabMaxSrc		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
::1			lda	pTabMaxSrc
			sec
			sbc	#$04			;Bereits am Anfang der Tabelle?
			bcs	:2			; => Nein, weiter...
			lda	#$00			;Zum Anfang der Tabelle.
::2			cmp	pTabPosSrc		;Position geändert?
			beq	:exit			; => Nein, Ende...
			sta	pTabPosSrc		;Neue Position speichern.
			jmp	reg_prntSrcPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Ziel vorwärts.
:reg_PTabTgtDn		lda	pTabMaxTgtBuf		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			ldx	pTabPosTgt		;Position einlesen.
			inx				;Zeiger auf nächste Partition.
			cpx	pTabMaxTgtBuf		;Letzte Partition?
			bcs	:exit			; => Ja, Abbruch...
			txa
			clc
			adc	#$04 -1
			cmp	pTabMaxTgtBuf		;ScrollDown möglich?
			bcs	:exit			; => Nein, Ende...
			stx	pTabPosTgt		;Neue Position setzen.
			jmp	reg_prntTgtPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Ziel zurück.
:reg_PTabTgtUp		lda	pTabMaxTgtBuf		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			ldx	pTabPosTgt		;Bereits am Anfang der Tabelle.
			beq	:exit			; => Ja, Abbruch...
			dex
			stx	pTabPosTgt		;Neue Position speichern.
			jmp	reg_prntTgtPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Ziel Seite zurück.
:reg_PTabTgtPr		lda	pTabMaxTgtBuf		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			lda	pTabPosTgt		;Bereits am Anfang der Tabelle?
			beq	:exit			; => Ja, Abbruch...
			sec
			sbc	#$04			;Seite zurück möglich?
			bcs	:1			; => Ja, weiter...
			lda	#$00			;Zum Anfang der Tabelle.
::1			sta	pTabPosTgt		;Neue Position speichern.
			jmp	reg_prntTgtPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Ziel Seite vorwärts.
:reg_PTabTgtNx		lda	pTabMaxTgtBuf		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			lda	pTabPosTgt		;Bereits am Anfang der Tabelle?
			clc				;Zeiger auf nächste Seite.
			adc	#$04			;Überlauf?
			bcs	reg_PTabTgtEnd		; => Ja, zum Ende springen.
			tax
			clc
			adc	#$04 -1			;Zeiger auf nächste Seite.
			cmp	pTabMaxTgtBuf		;Letzte Partition erreicht?
			bcs	reg_PTabTgtEnd		; => Ja, zum Ende springen.
			stx	pTabPosTgt		;Neue Position speichern.
			jmp	reg_prntTgtPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Ziel zum Anfang.
:reg_PTabTgtTop		lda	pTabMaxTgtBuf		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
			lda	#$00			;Zum Anfang der Tabelle.
			cmp	pTabPosTgt		;Position geändert?
			beq	:exit			; => Nein, Ende...
			sta	pTabPosTgt		;Neue Position speichern.
			jmp	reg_prntTgtPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Register-Funktion: Partitionstabelle/Ziel zum Ende.
:reg_PTabTgtEnd		lda	pTabMaxTgtBuf		;Partitionen vorhanden?
			beq	:exit			; => Nein, Abbruch...
::1			lda	pTabMaxTgtBuf
			sec
			sbc	#$04			;Bereits am Anfang der Tabelle?
			bcs	:2			; => Nein, weiter...
			lda	#$00			;Zum Anfang der Tabelle.
::2			cmp	pTabPosTgt		;Position geändert?
			beq	:exit			; => Nein, Ende...
			sta	pTabPosTgt		;Neue Position speichern.
			jmp	reg_prntTgtPTab		;Partitionstabelle ausgeben.
::exit			rts

;*** Textgrenzen für Geräte-Infobox setzen.
:setDevWin		bit	modeSrcTgt		;Ausgabemodus Quelle oder Ziel?
			bmi	:target			; => Ziel, weiter...
::source		ldy	#$00			;Zeiger auf Fensterdaten für
			b $2c				;Quelle oder Ziel.
::target		ldy	#$06

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:80			; => 80Z, weiter...
::40			lda	#<devWinPos40		;Fensterdaten für 40Z-Modus.
			ldx	#>devWinPos40
			bne	:init
::80			lda	#<devWinPos80		;Fensterdaten für 80Z-Modus.
			ldx	#>devWinPos80
::init			sta	r0L
			stx	r0H

			jsr	setTxtArea		;Textausgabegrenzen setzen.

;*** Hintergrundfarbe für inaktives Optionsfeld setzen.
:setOptOffCol		ldx	#$00
::1			lda	windowTop,x		;Textgrenzen für Quelle/Ziel für
			sta	r2L,x			;40Z oder 80Z setzen.
			inx
			cpx	#$06
			bcc	:1

			lda	C_InputFieldOff		;Farbe für inaktives Optionsfeld.
			jmp	DirectColor		;Farbe setzen.

;*** Textgrenzen für Partitionstyp-Infobox setzen.
:setPTypeWin		bit	modeSrcTgt		;Ausgabemodus Quelle oder Ziel?
			bmi	:target			; => Ziel, weiter...
::source		ldy	#$00			;Zeiger auf Fensterdaten für
			b $2c				;Quelle oder Ziel.
::target		ldy	#$06

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:80			; => 80Z, weiter...
::40			lda	#<pTypeWinPos40		;Fensterdaten für 40Z-Modus.
			ldx	#>pTypeWinPos40
			bne	:init
::80			lda	#<pTypeWinPos80		;Fensterdaten für 80Z-Modus.
			ldx	#>pTypeWinPos80
::init			sta	r0L
			stx	r0H

			jsr	setTxtArea		;Textausgabegrenzen setzen.
			jmp	setOptOffCol		;Farbe für inaktives Optionsfeld.

;*** Textgrenzen für Partitions-Infobox setzen.
:setPInfoWin		bit	modeSrcTgt		;Ausgabemodus Quelle oder Ziel?
			bmi	:target			; => Ziel, weiter...
::source		ldy	#$00			;Zeiger auf Fensterdaten für
			b $2c				;Quelle oder Ziel.
::target		ldy	#$06

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:80			; => 80Z, weiter...
::40			lda	#<pInfoWinPos40		;Fensterdaten für 40Z-Modus.
			ldx	#>pInfoWinPos40
			bne	:init
::80			lda	#<pInfoWinPos80		;Fensterdaten für 80Z-Modus.
			ldx	#>pInfoWinPos80
::init			sta	r0L
			stx	r0H

			jsr	setTxtArea		;Textausgabegrenzen setzen.
			jmp	setOptOffCol		;Farbe für inaktives Optionsfeld.

;*** Textgrenzen für Partitionstabelle setzen.
:setPTabWin		bit	modeSrcTgt		;Ausgabemodus Quelle oder Ziel?
			bmi	:target			; => Ziel, weiter...
::source		ldy	#$00			;Zeiger auf Fensterdaten für
			b $2c				;Quelle oder Ziel.
::target		ldy	#$06

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:80			; => 80Z, weiter...
::40			lda	#<pTabWinPos40		;Fensterdaten für 40Z-Modus.
			ldx	#>pTabWinPos40
			bne	:init
::80			lda	#<pTabWinPos80		;Fensterdaten für 80Z-Modus.
			ldx	#>pTabWinPos80
::init			sta	r0L
			stx	r0H

;*** Grenzen für Textausgabe setzen.
;Übergabe: r0 = Zeiger auf Tabelle
;               mit oben/unten/links/rechts.
:setTxtArea		ldx	#$00
::1			lda	(r0L),y			;Textgrenzen für Quelle/Ziel für
			sta	windowTop,x		;40Z oder 80Z setzen.
			iny
			inx
			cpx	#$06
			bcc	:1
			rts

;*** Textgrenzen zurücksetzen.
:resetTxtArea		LoadB	windowTop,0		;Oberen Rand zurücksetzen.
			LoadB	windowBottom,199	;Oberen Rand zurücksetzen.

			bit	curScrnMode		;40Z- oder 80Z-Modus?
			bmi	:80			; => 80Z, weiter...

::40			lda	#<320 -1		;40Z: Rechter Rand bei 320Pixel -1.
			ldx	#>320 -1
			bne	:setWin

::80			lda	#<640 -1		;80Z: Rechter Rand bei 640Pixel -1.
			ldx	#>640 -1

::setWin		ldy	#0			;Linken Rand zurücksetzen.
			sty	leftMargin +0
			sty	leftMargin +1
			sta	rightMargin +0		;Rechten Rand zurücksetzen.
			stx	rightMargin +1
			rts

;*** Position für Rahmen/Partitionstabelle setzen.
:setBorder		dec	r2L			;Koordinaten für Ausgabebereich um
			inc	r2H			;1Pixel nach aussen versetzen.

			lda	r3L
			bne	:1
			dec	r3H
::1			dec	r3L

			inc	r4L
			bne	:2
			inc	r4H

::2			rts

;******************************************************************************
;*** Variablen für Register-Menü.
;******************************************************************************

;*** Farben für EXIT-Icon.
:C_RegisterExit40	b $0d	 			;Farbe "Close"-Icon 40-Zeichen.
:C_RegisterExit80	b $05				;Farbe "Close"-Icon 80-Zeichen.

;*** Formatierung von Zahlen-Option in Register-Menü.
:DIGIT_2_BYTE		= $02 ! NUMERIC_RIGHT ! NUMERIC_SET0 ! NUMERIC_BYTE
:DIGIT_3_BYTE		= $03 ! NUMERIC_LEFT  ! NUMERIC_SET0 ! NUMERIC_BYTE

;*** Ausgabemodus Quelle oder Ziel.
:modeSrcTgt		b $00				;$00 = Quelle / $80 = Ziel.

;*** Partitionssuche.
:partFound		b $00				;$FF = Nicht gefunden oder Part-Nr.

;*** Systemtexte.
if LANG = LANG_DE
:noMedia		b "(Nicht bereit)",NULL
endif
if LANG = LANG_EN
:noMedia		b "(Not ready)",NULL
endif

;*** Partitionsdaten.
if TESTUI=TRUE
:cmdPartSrcRdy		b $ff				;Quelle: $FF = Laufwerk bereit.
;--- 24 Bytes
:cmdPartSrcBuf
:cmdPartSrc		b $01				;Partitions-Nr.
:cmdPartSrcTyp		b cmdPartNative			;Partitionstyp.
:cmdPartSrcAdr		b $00,$01,$80			;Startadresse.
:cmdPartSrcSize		w $1000				;Partitionsgröße.
:cmdPartSrcNam		b "1234567890123456"		;Partitionsname.
			b NULL
;---
:cmdPartSrcTxt		b "NATIVE ",NULL		;Partitionstyp/Textformat.
:cmdPartSrcList		b $00,$00,$00,$00		;Liste der angezeigten Partitionen.

:cmdPartTgtRdy		b $ff				;Ziel: $FF = Laufwerk bereit.
;--- 24 Bytes
:cmdPartTgtBuf
:cmdPartTgt		b $02				;Partitions-Nr.
:cmdPartTgtTyp		b cmdPartNative			;Partitionstyp.
:cmdPartTgtAdr		b $00,$01,$80			;Startadresse.
:cmdPartTgtSize		w $1000				;Partitionsgröße.
:cmdPartTgtNam		b "WWWWWWWWWWWWWWWW"		;Partitionsname.
			b NULL
;---
:cmdPartTgtTxt		b "NATIVE ",NULL		;Partitionstyp/Textformat.
:cmdPartTgtList		b $00,$00,$00,$00		;Liste der angezeigten Partitionen.
endif

if TESTUI=FALSE
:cmdPartSrcRdy		b $00				;Quelle: $FF = Laufwerk bereit.
;--- 24 Bytes
:cmdPartSrcBuf
:cmdPartSrc		b $00				;Partitions-Nr.
:cmdPartSrcTyp		b $00				;Partitionstyp.
:cmdPartSrcAdr		s 3				;Startadresse Partition.
:cmdPartSrcSize		s 2				;Partitionsgröße.
:cmdPartSrcNam		s 17				;Partitionsname.
;---
:cmdPartSrcTxt		s 8				;Partitionstyp/Textformat.
:cmdPartSrcList		b $00,$00,$00,$00		;Liste der angezeigten Partitionen.

:cmdPartTgtRdy		b $00				;Ziel: $FF = Laufwerk bereit.
;--- 24 Bytes
:cmdPartTgtBuf
:cmdPartTgt		b $00				;Partitions-Nr.
:cmdPartTgtTyp		b $00				;Partitionstyp.
:cmdPartTgtAdr		s 3				;Startadresse Partition.
:cmdPartTgtSize		s 2				;Partitionsgröße.
:cmdPartTgtNam		s 17				;Partitionsname.
;---
:cmdPartTgtTxt		s 8				;Partitionstyp/Textformat.
:cmdPartTgtList		b $00,$00,$00,$00		;Liste der angezeigten Partitionen.
endif

;*** Daten für Partitionstabelle.
if TESTUI=TRUE
:pTabPosSrc		b $00				;Quelle: Position in Tabelle.
:pTabPosTgt		b $02				;Ziel: Position in Tabelle.
:pTabMaxSrc		b $08				;Quelle: Max. Anzahl an Partitionen.
:pTabMaxTgt		b $08				;Ziel: Max. Anzahl an Partitionen.
:pTabMaxTgtBuf		b $00				;Ziel: Max. Anzahl gültiger Part.
endif

if TESTUI=FALSE
:pTabPosSrc		b $00				;Quelle: Position in Tabelle.
:pTabPosTgt		b $00				;Ziel: Position in Tabelle.
:pTabMaxSrc		b $00				;Quelle: Max. Anzahl an Partitionen.
:pTabMaxTgt		b $00				;Ziel: Max. Anzahl an Partitionen.
:pTabMaxTgtBuf		b $00				;Ziel: Max. Anzahl gültiger Part.
endif

:pTabCurPos		b $00				;Aktuelle Position.
:pTabCount		b $00				;Zähler für Zeilen/Ausgabe.
:pTabMaxCount		b $00				;Max. Einträge in Tabelle.

;*** Texte für Partitionstyp.
:pTypeTxShort		b "-N478CPFS"
:pTypeTxLong		b "EMPTY  ",NULL
			b "Native ",NULL
			b "1541   ",NULL
			b "1571   ",NULL
			b "1581   ",NULL
			b "1581CPM",NULL
			b "PRNTBUF",NULL
			b "FOREIGN",NULL
			b "SYSTEM ",NULL

;*** Allemeine Register-Beschriftung.
:RxxT01a		b "CMD-HD"
			b NULL

:RxxT01b
if LANG = LANG_DE
			b "<QUELLE>"
endif
if LANG = LANG_EN
			b "<SOURCE>"
endif
			b NULL

:RxxT01c
if LANG = LANG_DE
			b "<ZIEL>"
endif
if LANG = LANG_EN
			b "<TARGET>"
endif
			b NULL

if LANG = LANG_DE
:RxxT01d		b "Größe: ",NULL
endif
if LANG = LANG_EN
:RxxT01d		b "Size: ",NULL
endif

;******************************************************************************
;*** Variablen für Register-Menü.
;******************************************************************************

;*** Position Geräte-Infobox.
:devWinPos40
::source		b R40Area1_2y0 +RLine1_1
			b R40Area1_2y0 +RLine1_1 +$10 -1
			w R40Area1_2x0 +$20
			w R40Area1_2x0 +$20 +$68 -1

::target		b R40Area1_3y0 +RLine1_1
			b R40Area1_3y0 +RLine1_1 +$10 -1
			w R40Area1_3x0 +$20
			w R40Area1_3x0 +$20 +$68 -1

:devWinPos80
::source		b R80Area1_2y0 +RLine1_1
			b R80Area1_2y0 +RLine1_1 +$10 -1
			w R80Area1_2x0 +$40
			w R80Area1_2x0 +$40 +$70 -1

::target		b R80Area1_3y0 +RLine1_1
			b R80Area1_3y0 +RLine1_1 +$10 -1
			w R80Area1_3x0 +$40
			w R80Area1_3x0 +$40 +$70 -1

;*** Position Partitionstyp-Infobox.
:pTypeWinPos40
::source		b R40Area1_2y0 +RLine1_2
			b R40Area1_2y0 +RLine1_2 +$07
			w R40Area1_2x0 +$50
			w R40Area1_2x0 +$50 +8*8 -1

::target		b R40Area1_3y0 +RLine1_2
			b R40Area1_3y0 +RLine1_2 +$07
			w R40Area1_3x0 +$50
			w R40Area1_3x0 +$50 +8*8 -1

:pTypeWinPos80
::source		b R80Area1_2y0 +RLine1_2
			b R80Area1_2y0 +RLine1_2 +$07
			w R80Area1_2x0 +$60
			w R80Area1_2x0 +$60 +12*8 -1

::target		b R80Area1_3y0 +RLine1_2
			b R80Area1_3y0 +RLine1_2 +$07
			w R80Area1_3x0 +$60
			w R80Area1_3x0 +$60 +12*8 -1

;*** Position Partitions-Infobox.
:pInfoWinPos40
::source		b R40Area1_2y0 +RLine1_3
			b R40Area1_2y0 +RLine1_3 +$10 -1
			w R40Area1_2x0 +$08
			w R40Area1_2x0 +$08 +$88 -1

::target		b R40Area1_3y0 +RLine1_3
			b R40Area1_3y0 +RLine1_3 +$10 -1
			w R40Area1_3x0 +$08
			w R40Area1_3x0 +$08 +$88 -1

:pInfoWinPos80
::source		b R80Area1_2y0 +RLine1_3
			b R80Area1_2y0 +RLine1_3 +$10 -1
			w R80Area1_2x0 +$10
			w R80Area1_2x0 +$10 +$b0 -1

::target		b R80Area1_3y0 +RLine1_3
			b R80Area1_3y0 +RLine1_3 +$10 -1
			w R80Area1_3x0 +$10
			w R80Area1_3x0 +$10 +$b0 -1

;*** Position Partitionstabelle.
:pTabWinPos40
::source		b R40Area1_2y0 +RLine1_4
			b R40Area1_2y1 -$18
			w R40Area1_2x0 +$08
			w R40Area1_2x1 -$08

::target		b R40Area1_3y0 +RLine1_4
			b R40Area1_3y1 -$18
			w R40Area1_3x0 +$08
			w R40Area1_3x1 -$08

:pTabWinPos80
::source		b R80Area1_2y0 +RLine1_4
			b R80Area1_2y1 -$18
			w R80Area1_2x0 +$10
			w R80Area1_2x1 -$10

::target		b R80Area1_3y0 +RLine1_4
			b R80Area1_3y1 -$18
			w R80Area1_3x0 +$10
			w R80Area1_3x1 -$10

;*** Spalten-Position Partitionstabelle.
:pTabXPos40		b $01,$10,$18,$34
:pTabXPos80		b $02,$1c,$28,$4c

;******************************************************************************
;*** Register-Menü 40-Zeichen.
;******************************************************************************
;*** Register-Tabelle.
:R40SizeY0		= $10
:R40SizeY1		= $b7
:R40SizeX0		= $0008
:R40SizeX1		= $0137

:RegMenu40		b R40SizeY0			;Register-Größe.
			b R40SizeY1
			w R40SizeX0
			w R40SizeX1

			b 1				;Anzahl Registerkarten.

			w RTabName40_1			;Register: "CMD-HD".
			w RTabMenu40_1

;*** Registerkarten-Icons.
:RTabName40_1		w RTabIcon1
			b RCardIcon40X_1
			b R40SizeY0 -$08
			b RTabIcon1_x
			b RTabIcon1_y

;*** Registerkarten-Texte.
:R40T01_00		w R40Area1_1x0 +$08
			b R40Area1_1y0 +RLine1_0 +6
if LANG = LANG_DE
			b "GERÄT:"
endif
if LANG = LANG_EN
			b "DEVICE:"
endif
			b NULL

:R40T01_01		w R40Area1_2x0 +$08
			b R40Area1_2y0 +RLine1_2 +6
			b "P"
			b NULL

:R40T01_02		w R40Area1_3x0 +$08
			b R40Area1_3y0 +RLine1_2 +6
			b "P"
			b NULL

:R40T01_03
if LANG = LANG_DE
			w R40Area1_2x0 +$50 -$18
			b R40Area1_2y0 +RLine1_2 +6
			b "Typ"
endif
if LANG = LANG_EN
			w R40Area1_2x0 +$50 -$1c
			b R40Area1_2y0 +RLine1_2 +6
			b "Type"
endif
			b NULL

:R40T01_04
if LANG = LANG_DE
			w R40Area1_3x0 +$50 -$18
			b R40Area1_3y0 +RLine1_2 +6
			b "Typ"
endif
if LANG = LANG_EN
			w R40Area1_3x0 +$50 -$1c
			b R40Area1_3y0 +RLine1_2 +6
			b "Type"
endif
			b NULL

:R40T01_05		w R40SizeX1 -$40 +1
			b R40Area1_1y0 +8
			b "Start"
			b GOTOXY
			w R40SizeX1 -$40 +1
			b R40Area1_1y0 +$08 +8
			b "Copy"
			b NULL

:R40T01_06		w R40Area1_2x0 +$08
			b R40Area1_2y0 +RLine1_1 +6
			b "I"
			b NULL

:R40T01_07		w R40Area1_3x0 +$08
			b R40Area1_3y0 +RLine1_1 +6
			b "I"
			b NULL

:R40T01_08
			w R40SizeX1 -$94 +1
			b R40Area1_1y0 +8
if LANG = LANG_DE
			b "Geräte"
endif
if LANG = LANG_EN
			b "Swap"
endif
			b GOTOXY
			w R40SizeX1 -$94 +1
			b R40Area1_1y0 +$08 +8
if LANG = LANG_DE
			b "tauschen"
endif
if LANG = LANG_EN
			b "devices"
endif
			b NULL

:R40T01_09		w R40Area1_1x0 +$5c
			b R40Area1_1y0 +RLine1_0 +6
			b "SYNC:"
			b NULL

;******************************************************************************
;*** Register-Menü 40-Zeichen.
;******************************************************************************
;*** Daten für Register "CMD-HD".
:R40Pos_x  = R40SizeX0 +$10
:R40Pos_y  = R40SizeY0 +$10

:R40Tab0  = $0000					;Position Checkbox.
:R40Tab1  = $0030					;Position SCSI-INFO/Part.-Name.
:R40Tab2  = $0030	+$0088 + $08			;Position Partoitionstabelle.

:RLine1_0 = $08						;Zeile #0: CMD-HD-Gerät.
:RLine1_1 = $08						;Zeile #1: CMD-HD/SCSI-Gerät.
:RLine1_2 = $20						;Zeile #2: Partition Nr/Typ.
:RLine1_3 = $30						;Zeile #3: Partition Name/Größe.
:RLine1_4 = $48						;Zeile #4: Partitionstabelle

;--- CMD-HD-Adresse.
:R40Area1_1x0 = R40SizeX0 +$08
:R40Area1_1x1 = R40SizeX0 +$98 -1
:R40Area1_1y0 = R40SizeY0 +$08
:R40Area1_1y1 = R40SizeY0 +$20 -1

;--- CMD-HD Source.
:R40Area1_2x0 = R40SizeX0 +$00
:R40Area1_2x1 = R40SizeX0 +$98 -1
:R40Area1_2y0 = R40SizeY0 +$28
:R40Area1_2y1 = R40SizeY1 -$00

;--- CMD-HD Target.
:R40Area1_3x0 = R40SizeX1 -$98 +1
:R40Area1_3x1 = R40SizeX1 -$00
:R40Area1_3y0 = R40SizeY0 +$28
:R40Area1_3y1 = R40SizeY1 -$00

:RTabMenu40_1		b 36				;Anzahl Elemente.

			b BOX_FRAME			;----------------------------------------
				w RxxT01a
				w $0000
				b R40Area1_1y0,R40Area1_1y1
				w R40Area1_1x0,R40Area1_1x1

:RTabMenu40_HD		b BOX_NUMERIC_VIEW		;----------------------------------------
				w R40T01_00
				w $0000
				b R40Area1_1y0 +RLine1_0
				w R40Area1_1x0 +$38
				w devAdrHD
				b DIGIT_2_BYTE
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_findNxHD
				b R40Area1_1y0 +RLine1_0
				w R40Area1_1x0 +$48
				w R40Icon_NxHD
				b $00
			b BOX_OPTION			;----------------------------------------
				w R40T01_09
				w $0000
				b R40Area1_1y0 +RLine1_0
				w R40Area1_1x0 +$80
				w partSyncMode
				b %11111111

			b BOX_ICON			;----------------------------------------
				w R40T01_08
				w reg_swapDevices
				b R40Area1_1y0
				w R40SizeX1 -$60 +1
				w R40Icon_swapDev
				b $00
			b BOX_ICON			;----------------------------------------
				w R40T01_05
				w doStartCopy
				b R40Area1_1y0
				w R40SizeX1 -$20 +1
				w R40Icon_doCopy
				b $00

			b BOX_ICON			;----------------------------------------
				w $0000
				w doDirSource
				b R40Area1_2y1 -$18 +1
				w R40Area1_2x1 -$18 +1
				w R40Icon_DInfo
				b $00

			b BOX_ICON			;----------------------------------------
				w $0000
				w doDirTarget
				b R40Area1_3y1 -$18 +1
				w R40Area1_3x1 -$18 +1
				w R40Icon_DInfo
				b $00

;******************************************************************************
;*** Register-Menü 40-Zeichen.
;******************************************************************************
;--- SOURCE
			b BOX_FRAME			;----------------------------------------
				w RxxT01b
				w copySrcDevInfo
				b R40Area1_2y0,R40Area1_2y1
				w R40Area1_2x0,R40Area1_2x1
			b BOX_USEROPT			;----------------------------------------
				w R40T01_06
				w reg_prntSrcID
				b R40Area1_2y0 +RLine1_1
				b R40Area1_2y0 +RLine1_1 +$08 -1
				w R40Area1_2x0 +$10
				w R40Area1_2x0 +$10 +$08 -1
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w reg_prntSrcDev
				b R40Area1_2y0 +RLine1_1
				b R40Area1_2y0 +RLine1_1 +$10 -1
				w R40Area1_2x0 +$20
				w R40Area1_2x0 +$20 +$68 -1
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_updateSrcDev
				b R40Area1_2y0 +RLine1_1
				w R40Area1_2x1 -$10 +1
				w R40Icon_PLast
				b $00
:RTabMenu40_1a		b BOX_NUMERIC			;----------------------------------------
				w R40T01_01
				w reg_findSrcPart
				b R40Area1_2y0 +RLine1_2
				w R40Area1_2x0 +$10
				w cmdPartSrc
				b DIGIT_3_BYTE
:RTabMenu40_1c		b BOX_USEROPT_VIEW		;----------------------------------------
				w R40T01_03
				w reg_prntSrcPTyp
				b R40Area1_2y0 +RLine1_2
				b R40Area1_2y0 +RLine1_2 +$08 -1
				w R40Area1_2x0 +$50
				w R40Area1_2x0 +$50 +8*$08 -1
:RTabMenu40_1e		b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w reg_prntSrcPart
				b R40Area1_2y0 +RLine1_3
				b R40Area1_2y0 +RLine1_3 +$10 -1
				w R40Area1_2x0 +$08
				w R40Area1_2x0 +$08 +$88 -1
			b BOX_USER			;----------------------------------------
				w $0000
				w reg_setSrcPart
				b R40Area1_2y0 +RLine1_4
				b R40Area1_2y1 -$18
				w R40Area1_2x0 +$08
				w R40Area1_2x1 -$08
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcUp
				b R40Area1_2y1 -$18 +1
				w R40Area1_2x0 +$08 +$00
				w R40Icon_PUp
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcDn
				b R40Area1_2y1 -$10 +1
				w R40Area1_2x0 +$08 +$00
				w R40Icon_PDown
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcPr
				b R40Area1_2y1 -$18 +1
				w R40Area1_2x0 +$08 +$10
				w R40Icon_PLast
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcNx
				b R40Area1_2y1 -$18 +1
				w R40Area1_2x0 +$08 +$18
				w R40Icon_PNext
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcTop
				b R40Area1_2y1 -$18 +1
				w R40Area1_2x0 +$08 +$20
				w R40Icon_PTop
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcEnd
				b R40Area1_2y1 -$10 +1
				w R40Area1_2x0 +$08 +$20
				w R40Icon_PEnd
				b $00

;--- TARGET
			b BOX_FRAME			;----------------------------------------
				w RxxT01c
				w copyTgtDevInfo
				b R40Area1_3y0,R40Area1_3y1
				w R40Area1_3x0,R40Area1_3x1
			b BOX_USEROPT			;----------------------------------------
				w R40T01_07
				w reg_prntTgtID
				b R40Area1_3y0 +RLine1_1
				b R40Area1_3y0 +RLine1_1 +$08 -1
				w R40Area1_3x0 +$10
				w R40Area1_3x0 +$10 +$08 -1
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w reg_prntTgtDev
				b R40Area1_3y0 +RLine1_1
				b R40Area1_3y0 +RLine1_1 +$10 -1
				w R40Area1_3x0 +$20
				w R40Area1_3x0 +$20 +$68 -1
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_updateTgtDev
				b R40Area1_3y0 +RLine1_1
				w R40Area1_3x1 -$10 +1
				w R40Icon_PLast
				b $00
:RTabMenu40_1b		b BOX_NUMERIC			;----------------------------------------
				w R40T01_02
				w reg_findTgtPart
				b R40Area1_3y0 +RLine1_2
				w R40Area1_3x0 +$10
				w cmdPartTgt
				b DIGIT_3_BYTE
:RTabMenu40_1d		b BOX_USEROPT_VIEW		;----------------------------------------
				w R40T01_04
				w reg_prntTgtPTyp
				b R40Area1_3y0 +RLine1_2
				b R40Area1_3y0 +RLine1_2 +$08 -1
				w R40Area1_3x0 +$50
				w R40Area1_3x0 +$50 +8*$08 -1
:RTabMenu40_1f		b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w reg_prntTgtPart
				b R40Area1_3y0 +RLine1_3
				b R40Area1_3y0 +RLine1_3 +$10 -1
				w R40Area1_3x0 +$08
				w R40Area1_3x0 +$08 +$88 -1
			b BOX_USER			;----------------------------------------
				w $0000
				w reg_setTgtPart
				b R40Area1_3y0 +RLine1_4
				b R40Area1_3y1 -$18
				w R40Area1_3x0 +$08
				w R40Area1_3x1 -$08
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtUp
				b R40Area1_3y1 -$18 +1
				w R40Area1_3x0 +$08 +$00
				w R40Icon_PUp
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtDn
				b R40Area1_3y1 -$10 +1
				w R40Area1_3x0 +$08 +$00
				w R40Icon_PDown
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtPr
				b R40Area1_3y1 -$18 +1
				w R40Area1_3x0 +$08 +$10
				w R40Icon_PLast
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtNx
				b R40Area1_3y1 -$18 +1
				w R40Area1_3x0 +$08 +$18
				w R40Icon_PNext
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtTop
				b R40Area1_3y1 -$18 +1
				w R40Area1_3x0 +$08 +$20
				w R40Icon_PTop
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtEnd
				b R40Area1_3y1 -$10 +1
				w R40Area1_3x0 +$08 +$20
				w R40Icon_PEnd
				b $00

;******************************************************************************
;*** Register-Menü 80-Zeichen.
;******************************************************************************
;*** Register-Tabelle.
:R80SizeY0		= $10
:R80SizeY1		= $b7
:R80SizeX0		= $0070
:R80SizeX1		= $020f

:RegMenu80		b R80SizeY0			;Register-Größe.
			b R80SizeY1
			w R80SizeX0
			w R80SizeX1

			b 1				;Anzahl Registerkarten.

			w RTabName80_1			;Register: "CMD-HD".
			w RTabMenu80_1

;*** Registerkarten-Icons.
:RTabName80_1		w RTabIcon1
			b RCardIcon80X_1 ! DOUBLE_B
			b R80SizeY0 -$08
			b RTabIcon1_x ! DOUBLE_B
			b RTabIcon1_y

;*** Registerkarten-Texte.
:R80T01_00		w R80Area1_1x0 +$08
			b R80Area1_1y0 +RLine1_0 +6
if LANG = LANG_DE
			b "GERÄT:"
endif
if LANG = LANG_EN
			b "DEVICE:"
endif
			b NULL

:R80T01_01		w R80Area1_2x0 +$10
			b R80Area1_2y0 +RLine1_2 +6
			b "P"
			b NULL

:R80T01_02		w R80Area1_3x0 +$10
			b R80Area1_3y0 +RLine1_2 +6
			b "P"
			b NULL

:R80T01_03
if LANG = LANG_DE
			w R80Area1_2x0 +$60 -$18
			b R80Area1_2y0 +RLine1_2 +6
			b "Typ"
endif
if LANG = LANG_EN
			w R80Area1_2x0 +$60 -$20
			b R80Area1_2y0 +RLine1_2 +6
			b "Type"
endif
			b NULL

:R80T01_04
if LANG = LANG_DE
			w R80Area1_3x0 +$60 -$18
			b R80Area1_3y0 +RLine1_2 +6
			b "Typ"
endif
if LANG = LANG_EN
			w R80Area1_3x0 +$60 -$20
			b R80Area1_3y0 +RLine1_2 +6
			b "Type"
endif
			b NULL

:R80T01_05		w (R80SizeX1 -$60 +1)/2 ! DOUBLE_W
			b R80Area1_1y0 +8
			b "Start"
			b GOTOXY
			w (R80SizeX1 -$60 +1)/2 ! DOUBLE_W
			b R80Area1_1y0 +$08 +8
			b "Copy"
			b NULL

:R80T01_06		w R80Area1_2x0 +$10
			b R80Area1_2y0 +RLine1_1 +6
			b "I"
			b NULL

:R80T01_07		w R80Area1_3x0 +$10
			b R80Area1_3y0 +RLine1_1 +6
			b "I"
			b NULL

:R80T01_08		w (R80SizeX1 -$d8 +1)/2 ! DOUBLE_W
			b R80Area1_1y0 +8
if LANG = LANG_DE
			b "Geräte"
endif
if LANG = LANG_EN
			b "Swap"
endif
			b GOTOXY
			w (R80SizeX1 -$d8 +1)/2 ! DOUBLE_W
			b R80Area1_1y0 +$08 +8
if LANG = LANG_DE
			b "tauschen"
endif
if LANG = LANG_EN
			b "devices"
endif
			b NULL

:R80T01_09		w R80Area1_1x0 +$6c
			b R80Area1_1y0 +RLine1_0 +6
			b "SYNC:"
			b NULL

;******************************************************************************
;*** Register-Menü 80-Zeichen.
;******************************************************************************
;*** Daten für Register "CMD-HD".
:R80Pos_x  = R80SizeX0 +$10
:R80Pos_y  = R80SizeY0 +$10

;RLine1_0 = $08						;Zeile #1: ID #0/#4.
;RLine1_1 = $08						;Zeile #2: ID #1/#5.
;RLine1_2 = $20						;Zeile #3: ID #2/#6.
;RLine1_3 = $30						;Zeile #4: ID #3/#7.
;RLine1_4 = $48						;Zeile #5: Medien auswerfen.

;--- CMD-HD-Adresse.
:R80Area1_1x0 = R80SizeX0 +$10
:R80Area1_1x1 = R80SizeX0 +$c0 -1
:R80Area1_1y0 = R80SizeY0 +$08
:R80Area1_1y1 = R80SizeY0 +$20 -1

;--- CMD-HD Source.
:R80Area1_2x0 = R80SizeX0 +$00
:R80Area1_2x1 = R80SizeX0 +$d0 -1
:R80Area1_2y0 = R80SizeY0 +$28
:R80Area1_2y1 = R80SizeY1 -$00

;--- CMD-HD Target.
:R80Area1_3x0 = R80SizeX1 -$d0 +1
:R80Area1_3x1 = R80SizeX1 -$00
:R80Area1_3y0 = R80SizeY0 +$28
:R80Area1_3y1 = R80SizeY1 -$00

:RTabMenu80_1		b 36				;Anzahl Elemente.

			b BOX_FRAME			;----------------------------------------
				w RxxT01a
				w $0000
				b R80Area1_1y0,R80Area1_1y1
				w R80Area1_1x0,R80Area1_1x1

:RTabMenu80_HD		b BOX_NUMERIC_VIEW		;----------------------------------------
				w R80T01_00
				w $0000
				b R80Area1_1y0 +RLine1_0
				w R80Area1_1x0 +$40
				w devAdrHD
				b DIGIT_2_BYTE
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_findNxHD
				b R80Area1_1y0 +RLine1_0
				w (R80Area1_1x0 +$50)/2 ! DOUBLE_W
				w R80Icon_NxHD
				b $00
			b BOX_OPTION			;----------------------------------------
				w R80T01_09
				w $0000
				b R80Area1_1y0 +RLine1_0
				w (R80Area1_1x0 +$90)/2 ! DOUBLE_W
				w partSyncMode
				b %11111111

			b BOX_ICON			;----------------------------------------
				w R80T01_08
				w reg_swapDevices
				b R80Area1_1y0
				w (R80SizeX1 -$a0 +1)/2 ! DOUBLE_W
				w R80Icon_swapDev
				b $00
			b BOX_ICON			;----------------------------------------
				w R80T01_05
				w doStartCopy
				b R80Area1_1y0
				w (R80SizeX1 -$38 +1)/2 ! DOUBLE_W
				w R80Icon_doCopy
				b $00

			b BOX_ICON			;----------------------------------------
				w $0000
				w doDirSource
				b R80Area1_2y1 -$18 +1
				w (R80Area1_2x1 -$28 +1)/2 ! DOUBLE_W
				w R80Icon_DInfo
				b $00

			b BOX_ICON			;----------------------------------------
				w $0000
				w doDirTarget
				b R80Area1_3y1 -$18 +1
				w (R80Area1_3x1 -$28 +1)/2 ! DOUBLE_W
				w R80Icon_DInfo
				b $00

;******************************************************************************
;*** Register-Menü 80-Zeichen.
;******************************************************************************
;--- SOURCE
			b BOX_FRAME			;----------------------------------------
				w RxxT01b
				w copySrcDevInfo
				b R80Area1_2y0,R80Area1_2y1
				w R80Area1_2x0,R80Area1_2x1
			b BOX_USEROPT			;----------------------------------------
				w R80T01_06
				w reg_prntSrcID
				b R80Area1_2y0 +RLine1_1
				b R80Area1_2y0 +RLine1_1 +$08 -1
				w R80Area1_2x0 +$18
				w R80Area1_2x0 +$18 +$18 -1
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w reg_prntSrcDev
				b R80Area1_2y0 +RLine1_1
				b R80Area1_2y0 +RLine1_1 +$10 -1
				w R80Area1_2x0 +$40
				w R80Area1_2x0 +$40 +$70 -1
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_updateSrcDev
				b R80Area1_2y0 +RLine1_1
				w (R80Area1_2x1 -$20 +1)/2 ! DOUBLE_W
				w R80Icon_PLast
				b $00
:RTabMenu80_1a		b BOX_NUMERIC			;----------------------------------------
				w R80T01_01
				w reg_findSrcPart
				b R80Area1_2y0 +RLine1_2
				w R80Area1_2x0 +$18
				w cmdPartSrc
				b DIGIT_3_BYTE
:RTabMenu80_1c		b BOX_USEROPT_VIEW		;----------------------------------------
				w R80T01_03
				w reg_prntSrcPTyp
				b R80Area1_2y0 +RLine1_2
				b R80Area1_2y0 +RLine1_2 +$08 -1
				w R80Area1_2x0 +$60
				w R80Area1_2x0 +$60 +12*$08 -1
:RTabMenu80_1e		b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w reg_prntSrcPart
				b R80Area1_2y0 +RLine1_3
				b R80Area1_2y0 +RLine1_3 +$10 -1
				w R80Area1_2x0 +$10
				w R80Area1_2x0 +$10 +$b0 -1
			b BOX_USER			;----------------------------------------
				w $0000
				w reg_setSrcPart
				b R80Area1_2y0 +RLine1_4
				b R80Area1_2y1 -$18
				w R80Area1_2x0 +$10
				w R80Area1_2x1 -$10
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcUp
				b R80Area1_2y1 -$18 +1
				w (R80Area1_2x0 +$10 +$00)/2 ! DOUBLE_W
				w R80Icon_PUp
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcDn
				b R80Area1_2y1 -$10 +1
				w (R80Area1_2x0 +$10 +$00)/2 ! DOUBLE_W
				w R80Icon_PDown
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcPr
				b R80Area1_2y1 -$18 +1
				w (R80Area1_2x0 +$10 +$20)/2 ! DOUBLE_W
				w R80Icon_PLast
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcNx
				b R80Area1_2y1 -$18 +1
				w (R80Area1_2x0 +$10 +$30)/2 ! DOUBLE_W
				w R80Icon_PNext
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcTop
				b R80Area1_2y1 -$18 +1
				w (R80Area1_2x0 +$10 +$40)/2 ! DOUBLE_W
				w R80Icon_PTop
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabSrcEnd
				b R80Area1_2y1 -$10 +1
				w (R80Area1_2x0 +$10 +$40)/2 ! DOUBLE_W
				w R80Icon_PEnd
				b $00

;--- TARGET
			b BOX_FRAME			;----------------------------------------
				w RxxT01c
				w copyTgtDevInfo
				b R80Area1_3y0,R80Area1_3y1
				w R80Area1_3x0,R80Area1_3x1
			b BOX_USEROPT			;----------------------------------------
				w R80T01_07
				w reg_prntTgtID
				b R80Area1_3y0 +RLine1_1
				b R80Area1_3y0 +RLine1_1 +$08 -1
				w R80Area1_3x0 +$18
				w R80Area1_3x0 +$18 +$18 -1
			b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w reg_prntTgtDev
				b R80Area1_3y0 +RLine1_1
				b R80Area1_3y0 +RLine1_1 +$10 -1
				w R80Area1_3x0 +$40
				w R80Area1_3x0 +$40 +$70 -1
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_updateTgtDev
				b R80Area1_3y0 +RLine1_1
				w (R80Area1_3x1 -$20 +1)/2 ! DOUBLE_W
				w R80Icon_PLast
				b $00
:RTabMenu80_1b		b BOX_NUMERIC			;----------------------------------------
				w R80T01_02
				w reg_findTgtPart
				b R80Area1_3y0 +RLine1_2
				w R80Area1_3x0 +$18
				w cmdPartTgt
				b DIGIT_3_BYTE
:RTabMenu80_1d		b BOX_USEROPT_VIEW		;----------------------------------------
				w R80T01_04
				w reg_prntTgtPTyp
				b R80Area1_3y0 +RLine1_2
				b R80Area1_3y0 +RLine1_2 +$08 -1
				w R80Area1_3x0 +$60
				w R80Area1_3x0 +$60 +12*$08 -1
:RTabMenu80_1f		b BOX_USEROPT_VIEW		;----------------------------------------
				w $0000
				w reg_prntTgtPart
				b R80Area1_3y0 +RLine1_3
				b R80Area1_3y0 +RLine1_3 +$10 -1
				w R80Area1_3x0 +$10
				w R80Area1_3x0 +$10 +$b0 -1
			b BOX_USER			;----------------------------------------
				w $0000
				w reg_setTgtPart
				b R80Area1_3y0 +RLine1_4
				b R80Area1_3y1 -$18
				w R80Area1_3x0 +$10
				w R80Area1_3x1 -$10
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtUp
				b R80Area1_3y1 -$18 +1
				w (R80Area1_3x0 +$10 +$00)/2 ! DOUBLE_W
				w R80Icon_PUp
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtDn
				b R80Area1_3y1 -$10 +1
				w (R80Area1_3x0 +$10 +$00)/2 ! DOUBLE_W
				w R80Icon_PDown
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtPr
				b R80Area1_3y1 -$18 +1
				w (R80Area1_3x0 +$10 +$20)/2 ! DOUBLE_W
				w R80Icon_PLast
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtNx
				b R80Area1_3y1 -$18 +1
				w (R80Area1_3x0 +$10 +$30)/2 ! DOUBLE_W
				w R80Icon_PNext
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtTop
				b R80Area1_3y1 -$18 +1
				w (R80Area1_3x0 +$10 +$40)/2 ! DOUBLE_W
				w R80Icon_PTop
				b $00
			b BOX_ICON			;----------------------------------------
				w $0000
				w reg_PTabTgtEnd
				b R80Area1_3y1 -$10 +1
				w (R80Area1_3x0 +$10 +$40)/2 ! DOUBLE_W
				w R80Icon_PEnd
				b $00

;******************************************************************************
;*** Icon-Menü "Beenden".
;******************************************************************************
:IconMenu40		b $01
			w $0000
			b $00

			w IconExit
:IconExitPos40		b (R40SizeX0/8) +1
			b R40SizeY0 -$08
			b IconExit_x
			b IconExit_y
			w ExitRegMenu

:IconMenu80		b $01
			w $0000
			b $00

			w IconExit
:IconExitPos80		b (R80SizeX0/8) +2
			b R80SizeY0 -$08
			b IconExit_x ! DOUBLE_B
			b IconExit_y
			w ExitRegMenu

;*** Icon zum schließen des Menüs.
:IconExit
<MISSING_IMAGE_DATA>

:IconExit_x		= .x
:IconExit_y		= .y

;*** Icons für Registerkarten.
:RTabIcon1
<MISSING_IMAGE_DATA>

:RTabIcon1_x		= .x
:RTabIcon1_y		= .y

;*** X-Koordinate der Register-Icons.
:RCardIcon40X_1		= (R40SizeX0/8) +3
;RCardIcon40X_2		= RCardIcon40X_1 + RTabIcon1_x
:RCardIcon80X_1		= (R80SizeX0/8)/2 +3
;RCardIcon80X_2		= RCardIcon40X_1 + RTabIcon1_x

;*** Icon: Start copy.
:startCopy
<MISSING_IMAGE_DATA>

:startCopy_x		= .x
:startCopy_y		= .y

:R40Icon_doCopy		w startCopy
			b $00,$00
			b startCopy_x
			b startCopy_y
			b $01
:R80Icon_doCopy		w startCopy
			b $00,$00
			b startCopy_x !DOUBLE_B
			b startCopy_y
			b $0f

;*** Icon: Laufwerke tauschen.
:swapDev
<MISSING_IMAGE_DATA>

:swapDev_x		= .x
:swapDev_y		= .y

:R40Icon_swapDev	w swapDev
			b $00,$00
			b swapDev_x
			b swapDev_y
			b $01
:R80Icon_swapDev	w swapDev
			b $00,$00
			b swapDev_x !DOUBLE_B
			b swapDev_y
			b $0f

;******************************************************************************
;*** Register-Funktions-Icons.
;******************************************************************************
;*** Icon: ScrollUp.
:partUp
<MISSING_IMAGE_DATA>

:partUp_x		= .x
:partUp_y		= .y

:R40Icon_PUp		w partUp
			b $00,$00
			b partUp_x
			b partUp_y
			b $01
:R80Icon_PUp		w partUp
			b $00,$00
			b partUp_x ! DOUBLE_B
			b partUp_y
			b $0f

;*** Icon: ScrollDown.
:partDown
<MISSING_IMAGE_DATA>

:partDown_x		= .x
:partDown_y		= .y

:R40Icon_PDown		w partDown
			b $00,$00
			b partDown_x
			b partDown_y
			b $01
:R80Icon_PDown		w partDown
			b $00,$00
			b partDown_x ! DOUBLE_B
			b partDown_y
			b $0f

;*** Icon: Seite zurück.
;*** Icon: SCSI-Gerät aktualisieren.
:partLast
<MISSING_IMAGE_DATA>

:partLast_x		= .x
:partLast_y		= .y

:R40Icon_PLast		w partLast
			b $00,$00
			b partLast_x
			b partLast_y
			b $01
:R80Icon_PLast		w partLast
			b $00,$00
			b partLast_x ! DOUBLE_B
			b partLast_y
			b $0f

;*** Icon: Seite vorwärts.
:partNext
<MISSING_IMAGE_DATA>

:partNext_x		= .x
:partNext_y		= .y

:R40Icon_PNext		w partNext
			b $00,$00
			b partNext_x
			b partNext_y
			b $01
:R80Icon_PNext		w partNext
			b $00,$00
			b partNext_x ! DOUBLE_B
			b partNext_y
			b $0f

;*** Icon: Anfang.
:partTop
<MISSING_IMAGE_DATA>

:partTop_x		= .x
:partTop_y		= .y

:R40Icon_PTop		w partTop
			b $00,$00
			b partTop_x
			b partTop_y
			b $01
:R80Icon_PTop		w partTop
			b $00,$00
			b partTop_x ! DOUBLE_B
			b partTop_y
			b $0f

;*** Icon: Ende.
:partEnd
<MISSING_IMAGE_DATA>

:partEnd_x		= .x
:partEnd_y		= .y

:R40Icon_PEnd		w partEnd
			b $00,$00
			b partEnd_x
			b partEnd_y
			b $01
:R80Icon_PEnd		w partEnd
			b $00,$00
			b partEnd_x ! DOUBLE_B
			b partEnd_y
			b $0f

;*** Icon: Directory.
:diskInfo
<MISSING_IMAGE_DATA>

:diskInfo_x		= .x
:diskInfo_y		= .y

:R40Icon_DInfo		w diskInfo
			b $00,$00
			b diskInfo_x
			b diskInfo_y
			b $01
:R80Icon_DInfo		w diskInfo
			b $00,$00
			b diskInfo_x ! DOUBLE_B
			b diskInfo_y
			b $0f

;*** Icon: Nächste CMD-HD suchen.
:iconNextHD
<MISSING_IMAGE_DATA>

:iconNextHD_x		= .x
:iconNextHD_y		= .y

:R40Icon_NxHD		w iconNextHD
			b $00,$00
			b iconNextHD_x
			b iconNextHD_y
			b $01
:R80Icon_NxHD		w iconNextHD
			b $00,$00
			b iconNextHD_x ! DOUBLE_B
			b iconNextHD_y
			b $0f

;******************************************************************************
;*** Datenspeicher.
;******************************************************************************

;*** Partitionsdaten von $3D00 bis $6CFF
:DATABUF_ENDADR		= LD_ADDR_REGISTER
:DATABUF_SIZE		= 256*24
:DATABUF_COUNT		= 2
:DATABUF_START		= DATABUF_ENDADR - DATABUF_SIZE * DATABUF_COUNT

if TESTUI=FALSE
;--- Max. Programm-Bereich.
:maxProgAdr		g DATABUF_START

;--- Speicher: Quell-Partitionen.
:partDataBufSrc		= DATABUF_START
;--- Speicher: Ziel-Partitionen.
:partDataBufTgt		= DATABUF_START +DATABUF_SIZE
;--- Speicher für Dateinamen.
:dirFileDataBuf		= partDataBufTgt
endif

if TESTUI=TRUE
;--- Max. Programm-Bereich.
:maxProgAdr		e DATABUF_START

;--- Speicher: Quell-Partitionen.
:partDataBufSrc

;--- Speicher: Ziel-Partitionen.
;partDataBufTgt

;--- Dummy-Partitionsdaten.
:part001
::number		b $01
::type			b $04
::start			b $00,$01,$00
::size512		b $06,$40
::name			b "1581#1          "
			b NULL
:part002
::number		b $02
::type			b $02
::start			b $00,$01,$00
::size512		b $01,$56
::name			b "1541#1          "
			b NULL
:part003
::number		b $03
::type			b $03
::start			b $00,$02,$00
::size512		b $02,$ac
::name			b "1571#1          "
			b NULL
:part004
::number		b $04
::type			b $04
::start			b $00,$03,$00
::size512		b $06,$40
::name			b "1581#1          "
			b NULL
:part005
::number		b $05
::type			b $01
::start			b $00,$04,$00
::size512		b $04,$00
::name			b "Native#1        "
			b NULL
:part006
::number		b $06
::type			b $02
::start			b $00,$05,$00
::size512		b $01,$56
::name			b "1541#2          "
			b NULL
:part007
::number		b $07
::type			b $03
::start			b $00,$06,$00
::size512		b $02,$ac
::name			b "1571#2          "
			b NULL
:part008
::number		b $08
::type			b $04
::start			b $00,$07,$00
::size512		b $06,$40
::name			b "1581#2          "
			b NULL
:part009
::number		b $09
::type			b $01
::start			b $00,$08,$00
::size512		b $7f,$80
::name			b "NATIVE#2        "
			b NULL
:part010
::number		b $0a
::type			b $06
::start			b $00,$08,$00
::size512		b $80,$00
::name			b "FOREIGN#2       "
			b NULL
:part011
::number		b $0b
::type			b $07
::start			b $00,$08,$00
::size512		b $80,$00
::name			b "PRNTBUF#1       "
			b NULL

			e DATABUF_START +DATABUF_SIZE
;--- Speicher: Ziel-Partitionen.
:partDataBufTgt

:part001a
::number		b $02
::type			b $03
::start			b $00,$01,$00
::size512		b $02,$ac
::name			b "1571#1          "
			b NULL
:part002a
::number		b $0a
::type			b $01
::start			b $00,$01,$00
::size512		b $06,$40
::name			b "NATIVE#1        "
			b NULL
:part003a
::number		b $01
::type			b $04
::start			b $00,$01,$00
::size512		b $06,$40
::name			b "1581#1          "
			b NULL
:part004a
::number		b $04
::type			b $04
::start			b $00,$01,$00
::size512		b $06,$40
::name			b "1581#2          "
			b NULL
:part005a
::number		b $12
::type			b $04
::start			b $00,$01,$00
::size512		b $06,$40
::name			b "1581#3          "
			b NULL
:part006a
::number		b $13
::type			b $04
::start			b $00,$01,$00
::size512		b $06,$40
::name			b "1581#4          "
			b NULL
:part007a
::number		b $14
::type			b $04
::start			b $00,$01,$00
::size512		b $06,$40
::name			b "1581#5          "
			b NULL
:part008a
::number		b $2a
::type			b $06
::start			b $00,$01,$00
::size512		b $80,$00
::name			b "FOREIGN#1       "
			b NULL
:part009a
::number		b $30
::type			b $01
::start			b $00,$01,$00
::size512		b $7f,$80
::name			b "NATIVE#2        "
			b NULL

;--- Speicher für Dateinamen.
:dirFileDataBuf		b "1234567890123456",NULL
			b "1234567890123456",NULL
			b "1234567890123456",NULL
			b NULL
endif
