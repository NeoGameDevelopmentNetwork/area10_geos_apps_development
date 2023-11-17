; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = C_41!C_71!C_81!RD_41!RD_71!RD_81
::tmp0b = RL_41!RL_71!RL_81!FD_41!FD_71!FD_81
::tmp0c = HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP
::tmp0d = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0e = FD_NM!HD_NM!HD_NM_PP!RL_NM!IEC_NM!S2I_NM
::tmp0  = :tmp0a!:tmp0b!:tmp0c!:tmp0d!:tmp0e
if :tmp0 = TRUE
;******************************************************************************
:Flag_BorderBlock	b $00				;$FF = Borderblock aktiv.

;*** Format-Info für GEOS-Diskette.
:GEOS_FormatInfo	b "GEOS format V1.0"
endif

;******************************************************************************
::tmp1a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp1b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp1 = :tmp1a!:tmp1b
if :tmp1 = TRUE
;******************************************************************************
;*** Systemvariablen.
:DiskSize_Lb		b $00				;(Angabe in Kb!)
:DiskSize_Hb		b $00
:LastTrOnDsk		b $7f				;Max. Anzahl Tracks.

:BorderB_Tr		b $00				;Borderblock / ROOT-Verzeichnis.
:BorderB_Se		b $00

:DirHead_Tr		b $01				;Aktueler Verzeichnis-Header.
:DirHead_Se		b $01

:LastSearchTr		b $00				;Letzter Track für Sektorsuche.

:CurSek_BAM		b $00				;Aktueller BAM-Sektor.
:BAM_Modified		b $00				;$FF = BAM verändert.
endif

;******************************************************************************
::tmp2 = RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
if :tmp2!TEST_RAMNM_SHARED = TRUE!SHAREDDIR_ENABLED
;******************************************************************************
;*** Adresse "SharedDir"-Verzeichnis.
:SharedD_Tr		b $00				;Zeiger auf Shared/Dir.
:SharedD_Se		b $00
endif

;******************************************************************************
::tmp3 = RL_41!RL_71!RL_81!RL_NM
if :tmp3 = TRUE
;******************************************************************************
;*** Eintrag für aktuelle Partition.
;    Werden auch in der REU abgespeichert!
:RL_DataStart
:RL_PartNr		b $00
:RL_PartADDR		w $0000
:RL_PartADDR_L		s 32
:RL_PartADDR_H		s 32
:RL_PartTYPE		s 32
:RL_DataEnd
endif

;******************************************************************************
::tmp4 = PC_DOS
if :tmp4 = TRUE
;******************************************************************************
;*** Cluster/Sektor-Umrechnung.
.Seite			b $00
.Spur			b $00
.Sektor			b $00

;*** Systemvariablen.
.DOS_DataArea		w $0000
.Data_Boot		s $03				;Einsprung in Boot-Routine
.Data_Disk_Typ		s $08				;Name des Herstellers & Version
.Data_BpSek		s $02				;Anzahl Bytes pro Sektor        (Word).
.Data_SpClu		s $01				;Anzahl Sektoren pro Cluster    (Byte).
.Data_AreSek		s $02				;Anzahl reservierter Sektoren   (Word).
.Data_Anz_Fat		s $01				;Anzahl File-Allocation-Tables  (Byte).
.Data_Anz_Files		s $02				;Anzahl Eintraege MainDirectory (Word).
.Data_Anz_Sektor	s $02				;Anzahl Sektoren im Volume      (Word).
.Data_Media		s $01				;Media-Descriptor               (Byte).
.Data_SekFat		s $02				;Anzahl Sektoren pro FAT        (Word).
.Data_SekSpr		s $02				;Anzahl Sektoren pro Spur       (Word).
.Data_AnzSLK		s $02				;Anzahl der Schreib-/Lese-Köpfe (Word).
.Data_FstSek		s $02				;Entfernung des ersten Sektors im
							;Volume vom ersten Sektor auf dem
							;Speichermedium                 (Word).

;--- Nichtmehr Bestandteil des BOOT-Sektors.

;*** Variablen zur Verzeichnis-Steuerung.
.Data_1stRDirSek	s $02				;Zeiger auf ersten Verzeichnis-Sektor.
:Data_NumRDirSek	w $0000
:Data_NumSekPCyl	w $0000
.Flag_DirType		b $00				;$00 = Hauptverzeichnis,
							;$FF = Unterverzeichnis.
.Data_1stSDirClu	w $0000				;Zeiger auf ersten SubDir-Cluster.
.Data_ParentSDir	w $0000

;*** Variablen zur Kopierfunktion.
:VecDOS_Sektor		w $0000
:CurDOS_Sek		b $00,$00
:Flag_1stSektor		b $00
:Bytes2Copy		b $00

;*** Zwischenspeicher für Sektor-Alias-Daten.
.Data_AliasSektor	s 16

;*** Variablen zur Treiber-Steuerung.
.Flag_UpdateDir		b $ff				;$FF = Verzeichnis neu einlesen.
.Flag_UpdateDkDv	b $00				;$FF = Treiber aktualisieren.

:RepeatFunction		b $00				;Wiederholungszähler.

;*** Diskettenname.
.DummyDiskName		b "PC-DOS"
			b $a0,$a0,$a0,$a0,$a0,$a0
			b $a0,$a0,$a0,$a0,$a0,$a0
.CurrentDiskName	s 18
endif
