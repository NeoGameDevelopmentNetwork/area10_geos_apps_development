; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp0 = C_41!C_71!C_81!IEC_NM!S2I_NM
if :tmp0 = TRUE
;******************************************************************************
;*** Reservierter Speicher.
;ACHTUNG: Reserviert für interne Funktionen und künftige Erweiterungen.
;         Diese Adressen sind in SymbTab_2 als externe Adressen definiert.
;
;         Wird die Adresse hier verschoben, dann ist die Datei SymbTab_2
;         ebenfalls anzupassen!
;
;         Diese Adressen existieren erst ab Nov.2019, daher vor der
;         Nutzung auf die Kennung "DDX" testen.
:DDX			b "DDX",NULL

;*** SD2IEC-Flag für RealDrvMode.
;ACHTUNG: MegaPatch-Systemadresse:
;         Hier speichert INIT_1541/71/81/SD2IEC die Kennung für ein
;         SD2IEC nach der automatischen Erkennung!
;
;SD2IEC = %00000010
;         Wird in EnterTurbo in RealDrvMode gespeichert.
:xFlag_SD2IEC		b $00

;*** Reservierter Speicher.
;ACHTUNG: MegaPatch-Systemadresse:
;         Nur für GeoRAM-Native/INIT_RAMNM_GRAM.
;         Für alle anderen Treiber ist diese Adresse frei/ungenutzt.
::xGeoRAMBSize		b $00

;*** Reservierter Speicher für künftige Erweiterungen.
:DDX_DATA1		b $00
:DDX_DATA2		b $00

;*** Erweiterte Einspungtabelle.
:xInitForDDrvOp		jmp	InitForDskDvJob
:xDoneWithDDrvOp	jmp	DoneWithDskDvJob

;******************************************************************************
			g EndOfDDX
;******************************************************************************

endif

;******************************************************************************
::tmp1a = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU
::tmp1b = RL_41!RL_71!RL_81!RL_NM!FD_41!FD_71!FD_81!FD_NM
::tmp1c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp1d = PC_DOS
::tmp1  = :tmp1a!:tmp1b!:tmp1c!:tmp1d
if :tmp1 = TRUE
;******************************************************************************
;*** Reservierter Speicher.
;ACHTUNG: Reserviert für interne Funktionen und künftige Erweiterungen.
;         Diese Adressen sind in SymbTab_2 als externe Adressen definiert.
;
;         Wird die Adresse hier verschoben, dann ist die Datei SymbTab_2
;         ebenfalls anzupassen!
;
;         Diese Adressen existieren erst ab Nov.2019, daher vor der
;         Nutzung auf die Kennung "DDX" testen.
:DDX			b "DDX",NULL

;*** Reservierter Speicher.
;ACHTUNG: MegaPatch-Systemadresse:
;         Nur für 1541/71/81/SD2IEC und INIT_1541/71/81/SD2IEC.
;         Für alle anderen Treiber ist diese Adresse frei/ungenutzt.
::xFlag_SD2IEC		b $00

;*** Reservierter Speicher.
;ACHTUNG: MegaPatch-Systemadresse:
;         Nur für GeoRAM-Native/INIT_RAMNM_GRAM.
;         Für alle anderen Treiber ist diese Adresse frei/ungenutzt.
::xGeoRAMBSize		b $00

;*** Reservierter Speicher für künftige Erweiterungen.
:DDX_DATA1		b $00
:DDX_DATA2		b $00

;*** Erweiterte Einspungtabelle.
:xInitForDDrvOp		jmp	InitForDskDvJob
:xDoneWithDDrvOp	jmp	DoneWithDskDvJob

;******************************************************************************
			g EndOfDDX
;******************************************************************************

endif

;******************************************************************************
::tmp2 = RD_NM_GRAM
if :tmp2 = TRUE
;******************************************************************************
;*** Reservierter Speicher.
;ACHTUNG: Reserviert für interne Funktionen und künftige Erweiterungen.
;         Diese Adressen sind in SymbTab_2 als externe Adressen definiert.
;
;         Wird die Adresse hier verschoben, dann ist die Datei SymbTab_2
;         ebenfalls anzupassen!
;
;         Diese Adressen existieren erst ab Nov.2019, daher vor der
;         Nutzung auf die Kennung "DDX" testen.
:DDX			b "DDX",NULL

;*** Reservierter Speicher.
;ACHTUNG: MegaPatch-Systemadresse:
;         Nur für 1541/71/81/SD2IEC und INIT_1541/71/81/SD2IEC.
;         Für alle anderen Treiber ist diese Adresse frei/ungenutzt.
::xFlag_SD2IEC		b $00

;*** Bank-Größe 16/32/64Kb.
;ACHTUNG: MegaPatch-Systemadresse:
;         Hier speichert INIT_RAMNM_GRAM den Wert für die Bankgröße
;         nach der automatischen Erkennung!
:xGeoRAMBSize		b $00

;*** Reservierter Speicher für künftige Erweiterungen.
:DDX_DATA1		b $00
:DDX_DATA2		b $00

;*** Erweiterte Einspungtabelle.
:xInitForDDrvOp		jmp	InitForDskDvJob
:xDoneWithDDrvOp	jmp	DoneWithDskDvJob

;******************************************************************************
			g EndOfDDX
;******************************************************************************

endif
