; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp0b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp0 = :tmp0a!:tmp0b
if :tmp0 = TRUE
;******************************************************************************
;*** Systemvariablen.
:DiskSize_Lb		b $00				;(Angabe in Kb!)
:DiskSize_Hb		b $00
:LastTrOnDsk		b $7f

:DirHead_Tr		b $01
:DirHead_Se		b $01

:LastSearchTr		b $00

:CurSek_BAM		b $00
:BAM_Modified		b $00
endif

;******************************************************************************
::tmp1 = RL_41!RL_71!RL_81!RL_NM
if :tmp1 = TRUE
;******************************************************************************
;*** Eintrag für aktuelle Partition.
;    Werden auch in der REU abgespeichert!
:RL_DataStart
:RL_DEV_ADDR		b $00
:RL_PartNr		b $00
:RL_PartADDR		w $0000
:RL_PartADDR_L		s 32
:RL_PartADDR_H		s 32
:RL_PartTYPE		s 32
:RL_DATA_READY		b $00
:RL_DataEnd
endif

;******************************************************************************
::tmp2 = PC_DOS
if :tmp2 = TRUE
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
