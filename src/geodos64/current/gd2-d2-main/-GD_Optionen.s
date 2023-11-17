; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
; Funktion		: Systemvariablen.
; Datum			: 05.07.97
; Aufruf		: -
; Übergabe		: -
; Rückgabe		: -
; Verändert		: -
; Variablen		: -
; Routinen		: -
;******************************************************************************

;*** GeoDOS-Parameter.
.CTabCBMtoDOS		s 17				;Übersetzung 1:1
.CTabDOStoCBM		s 17				;Übersetzung 1:1
.CTabCBMtoCBM		s 17				;Übersetzung 1:1

;*** Name der eingestellten Schriftart.
.UsedGWFont		b "BSW- GEOS System",NULL
.UsedPointSize		b $09

;*** Copy-Optionen.
.LinesPerPage		w $0040				;Anzahl Zeilen/Seite (WORD!).
.LinkFiles		b $00				;DOS-Dateien kombinieren.

.SetDateTime		b $00				;Datum der Quell-Datei übernehmen.
.OverWrite		b $ff				;Vor dem löschen von Dateien fragen.
.FileNameFormat		b $00				;DOS nach CBM: Name im '8+3'-Format.

.CBMFileType		b $81				;CBM-Datei-Typ "SEQ".
.DOS_LfMode		b $00				;"LF" nich ignorieren.

.FileNameMode		b $00				;DOS-Namen vorschlagen.
.CBM_LfMode		b $00				;"LF" nicht einfügen.
.DOS_TargetDir		b $00				;Typ Ziel-Verzeichnis ($FF = SubDir)
.DOS_TargetClu		w $0000				;Cluster für Ziel-Verzeichnis.
.DOS_FfMode		b $00				;DOS-Seitenvorschub ignorieren.

.GW_Version		b $00				;geoWrite-Text V2.0
.GW_FirstPage		w $0001				;Nr. der ersten Seite.
.GW_PageLength		w $02f0				;Länge einer Seite -> Druckertreiber.
.GW_PageData		b ESC_RULER
.GW_LRand		w $0000				;Linker Rand.
.GW_RRand		w $01df				;Rechter Rand.
.GW_Tab1		w $01df				;Tabulator #1.
.GW_Tab2		w $01df				;Tabulator #2.
.GW_Tab3		w $01df				;Tabulator #3.
.GW_Tab4		w $01df				;Tabulator #4.
.GW_Tab5		w $01df				;Tabulator #5.
.GW_Tab6		w $01df				;Tabulator #6.
.GW_Tab7		w $01df				;Tabulator #7.
.GW_Tab8		w $01df				;Tabulator #8.
.GW_AbsatzTab		w $0000				;Absatz-Tabulator.
.GW_Format		b %00010000			;Formatierung.
.GW_Reserve		s $03				;Reserviert.
.GW_Font		b NEWCARDSET
.GW_FontID		w $0009				;Font-ID & Punktgröße.
.GW_Style		b $00				;Schriftstil.

.CBM_FfMode		b $00				;GW-Seitenvorschub ignorieren.

.CBM_FileTMode		b $00				;$00 = Dateityp unverändert.
							;$FF = Dateityp ändern.

.Txt_LfMode		b $00				;$00 = LF unverändert.
							;$7F = LF ignorieren.
							;$FF = LF einfügen.
.Txt_FfMode		b $00				;$00 = FF unverändert.
							;$7F = FF ignorieren.
							;$FF = FF einfügen.
.GW_Modify		b $00				;$00 = Alles ändern.
							;$7F = Nur Zeichensatz ändern.
							;$FF = Nur Formatierung ändern.
