; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
::tmp00a = C_41!C_71!C_81!PC_DOS
::tmp00b = FD_41!FD_71!FD_81!RL_41!RL_71!RL_81
::tmp00c = HD_41!HD_71!HD_81!HD_41_PP!HD_71_PP!HD_81_PP
::tmp00d = RD_41!RD_71!RD_81
::tmp00  = :tmp00a!:tmp00b!:tmp00c!:tmp00d
if :tmp00 = TRUE
;******************************************************************************
;*** I/O - Bereich aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
:xInitForIO		php
			pla
			sta	IRQ_RegBuf		;IRQ-Status speichern.
			sei
endif

;******************************************************************************
::tmp01a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp01b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp01  = :tmp01a!:tmp01b
if :tmp01 = TRUE
;******************************************************************************
;*** I/O - Bereich aktivieren.
;    Übergabe:		-
;    Rückgabe:		-
;    Geändert:		AKKU,yReg
;Bei NativeMode muss beim einlesen von
;BAM-Sektoren geprüft werden, ob der
;aktuelle BAM-Sektor im Speicher auf
;Disk aktualisiert werden muss.
;Falls ja muss die Routine wissen ob
;":InitForIO" bereits aufgerufen wurde.
;Mit diesem Flag kann hier dann ein
;doppelter Aufruf der Routine erkannt
;und ignoriert werden.
;In anderen Treibern ist dafür aber
;kein Platz mehr im Speicher (C=1571).
:xInitForIO		bit	IO_Activ		;I/O-Modus bereits aktiv?
			bpl	:init			; => Nein, weiter...
			rts				;Ende...

::init			dec	IO_Activ		;"I/O-Aktiv"-Flag setzen.

			php
			pla
			sta	IRQ_RegBuf		;IRQ-Status speichern.
			sei
endif

;******************************************************************************
::tmp02a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp02b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp02c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp02d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp02  = :tmp02a!:tmp02b!:tmp02c!:tmp02d
if Flag64_128!:tmp02 = TRUE_C64!TRUE
;******************************************************************************
			lda	CPU_DATA
			sta	CPU_RegBuf		;CPU-Status speichern.
			lda	#$36			;I/O + Kernal einblenden.
			sta	CPU_DATA
endif

;******************************************************************************
::tmp03a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp03b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp03c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp03d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp03  = :tmp03a!:tmp03b!:tmp03c!:tmp03d
if :tmp03 = TRUE
;******************************************************************************
			lda	grirqen			;IRQ-Maskenregister speichern.
			sta	grirqen_Buf
			ldy	#$00
			sty	grirqen
endif

;******************************************************************************
::tmp04a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp04b = FD_41!FD_71!FD_81!FD_NM
::tmp04c = HD_41!HD_71!HD_81!HD_NM
::tmp04  = :tmp04a!:tmp04b!:tmp04c
if Flag64_128!:tmp04 = TRUE_C128!TRUE
;******************************************************************************
			lda	CLKRATE			;Takt-Frequenz speichern.
			sta	CLKRATE_Buf
;			ldy	#$00
			sty	CLKRATE
endif

;******************************************************************************
::tmp05a = RL_41!RL_71!RL_81!RL_NM
::tmp05b = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp05c = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp05  = :tmp05a!:tmp05b!:tmp05c
if Flag64_128!:tmp05 = TRUE_C128!TRUE
;******************************************************************************
;--- Ergänzung: 21.07.18/M.Kanet
;InitForIO/RAMDisk/RAMLink/HD-ParallelPort:
;In der Version von 2003 wird nicht auf den C128/1MHz-Modus umgeschaltet.
;Die Register müssen aber trotzdem gesichert werden für den Fall das andere
;Routinen zwischen :InitForIO und :DoneWithIO das Register verändert haben.
			lda	CLKRATE			;Takt-Frequenz speichern.
			sta	CLKRATE_Buf
;			ldy	#$00
;			sty	CLKRATE
endif

;******************************************************************************
::tmp15 = PC_DOS
if Flag64_128!:tmp15!TDOS_MODE = TRUE_C64!TRUE!TDOS_ENABLED
;******************************************************************************
;--- Ergänzung: 16.11.19/M.Kanet
;Das TC64 schaltet beim Zugriff auf den
;seriellen Bus automatisch auf 1MHz.
;Beim PCDOS-Treiber muss der FastMode
;aber komplett abgeschaltet werden oder
;das System friert evtl. komplett ein.
::slowDownTC64		LoadB	$d0fe,$2a		;Konfigurationsregister einschalten.

			lda	$d0f3			;Aktuellen TC64-Speed einlesen.
			sta	TC64Speed_Buf
			and	#%01100000		;TurboMode=OFF, AutoIEC=OFF,
			ora	#%00011100		;SlowDown=100%
			sta	$d0f3			;TC64 auf 1MHz schalten.

			LoadB	$d0fe,$ff		;Konfigurationsregister ausschalten.
endif

;******************************************************************************
::tmp23a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp23b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp23  = :tmp23a!:tmp23b
if Flag64_128!:tmp23!TDOS_MODE = TRUE_C64!TRUE!TDOS_DISABLED
;******************************************************************************
;--- Ergänzung: 03.10.20/M.Kanet
;Das TC64 schaltet beim Zugriff auf den
;seriellen Bus automatisch auf 1MHz.
;Beim kopieren von D81-Images mit den
;neuen Kernal-Treibern und SD2IEC,
;GeoDesk64 waren im Ziel-D81 einzelne
;Bytes fehlerhaft.
;Test: AutoIEC=OFF und SlowDown=100%
::slowDownTC64		LoadB	$d0fe,$2a		;Konfigurationsregister einschalten.

			lda	$d0f3			;Aktuellen TC64-Speed einlesen.
			sta	TC64Speed_Buf
			and	#%01100000		;TurboMode=OFF, AutoIEC=OFF,
			ora	#%00011100		;SlowDown=100%
			sta	$d0f3			;TC64 auf 1MHz schalten.

			LoadB	$d0fe,$ff		;Konfigurationsregister ausschalten.
endif

;******************************************************************************
::tmp06a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp06b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp06c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp06d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp06  = :tmp06a!:tmp06b!:tmp06c!:tmp06d
if :tmp06 = TRUE
;******************************************************************************
			lda	mobenble		;Aktive Sprites zwischenspeichern.
			sta	mobenble_Buf
			sty	mobenble		;Sprites abschalten.

			lda	#%01111111		;VIC-Interrupt sperren.
			sta	grirq
			sta	$dc0d			;IRQs sperren.
			sta	$dd0d			;NMIs sperren.
endif

;******************************************************************************
::tmp07 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp07 = TRUE
;******************************************************************************
			bit	$dc0d			;Haben diese Befehle eine Funktion?
			bit	$dd0d
endif

;******************************************************************************
::tmp08a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp08b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp08c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp08d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp08  = :tmp08a!:tmp08b!:tmp08c!:tmp08d
if :tmp08 = TRUE
;******************************************************************************
			LoadW	irqvec,NewIRQ		;IRQ-Routine abschalten.
			LoadW	nmivec,NewNMI		;NMI-Routine abschalten.

			lda	#$3f			;Datenrichtungsregister A setzen.
			sta	$dd02			;(Serieller Bus)
			sty	$dd05			;Timer A löschen.
			iny
			sty	$dd04
endif

;******************************************************************************
::tmp09a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp09b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp09c = HD_41!HD_71!HD_81!HD_NM
::tmp09d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp09  = :tmp09a!:tmp09b!:tmp09c!:tmp09d
if :tmp09 = TRUE
;******************************************************************************
			lda	#$81			;NMI-Register initialisieren.
			sta	$dd0d
			lda	#$09			;Timer A starten.
			sta	$dd0e
endif

;******************************************************************************
::tmp10 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp10 = TRUE
;******************************************************************************
			lda	#$81
			sta	$dd0d
			lda	$dd0e
			and	#$80
			ora	#$09
			sta	$dd0e
endif

;******************************************************************************
::tmp11a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp11b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp11c = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp11  = :tmp11a!:tmp11b!:tmp11c
if :tmp11!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
			ldy	#$2c			;Warteschleife bis Ser. Bus
::wait			lda	rasreg			;initialisiert (Turbo-Routinen!)
			cmp	d2H
			beq	:wait
			sta	d2H
			dey
			bne	:wait
endif

;******************************************************************************
::tmp12a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp12b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp12  = :tmp12a!:tmp12b
if :tmp12!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
			lda	$dd00
			and	#%00000111		;Byte zum aktivieren des Turbo-
			sta	d2L			;Modus ermitteln.
			ora	#%00110000		;Byte zum abschalten des Turbo-
			sta	d2H			;Modus ermitteln.
			lda	d2L
			ora	#%00010000		;Byte zum pausieren des Turbo-
			sta	DD00_RegBuf		;Modus ermitteln.
endif

;******************************************************************************
::tmp13 = HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
if :tmp13!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
			lda	$dd00
			and	#%00000111
			sta	d2L
			ora	#%00010000
			sta	d2H
endif

;******************************************************************************
::tmp14a = C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp14b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp14  = :tmp14a!:tmp14b
if :tmp14!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
			ldy	#$1f
::loop1			lda	NibbleByteH,y
			and	#%11110000
			ora	d2L
			sta	NibbleByteH,y
			dey
			bpl	:loop1
endif

;******************************************************************************
::tmp16a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp16b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp16c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp16d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp16  = :tmp16a!:tmp16b!:tmp16c!:tmp16d
if :tmp16 = TRUE
;******************************************************************************
			rts
endif

;******************************************************************************
::tmp17a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp17b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp17c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp17d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp17  = :tmp17a!:tmp17b!:tmp17c!:tmp17d
if :tmp17 = TRUE
;******************************************************************************
:IRQ_RegBuf		b $00
:mobenble_Buf		b $00
:grirqen_Buf		b $00
endif

;******************************************************************************
::tmp18a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp18b = FD_41!FD_71!FD_81!FD_NM
::tmp18c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp18  = :tmp18a!:tmp18b!:tmp18c
if :tmp18!TDOS_MODE = TRUE!TDOS_ENABLED
;******************************************************************************
:DD00_RegBuf		b $00
endif

;******************************************************************************
::tmp19a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp19b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp19c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp19d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp19  = :tmp19a!:tmp19b!:tmp19c!:tmp19d
if Flag64_128!:tmp19 = TRUE_C64!TRUE
;******************************************************************************
:CPU_RegBuf		b $00
endif

;******************************************************************************
::tmp20a = C_41!C_71!C_81!IEC_NM!S2I_NM!PC_DOS
::tmp20b = FD_41!FD_71!FD_81!FD_NM!RL_41!RL_71!RL_81!RL_NM
::tmp20c = HD_41!HD_71!HD_81!HD_NM!HD_41_PP!HD_71_PP!HD_81_PP!HD_NM_PP
::tmp20d = RD_41!RD_71!RD_81!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp20  = :tmp20a!:tmp20b!:tmp20c!:tmp20d
if Flag64_128!:tmp20 = TRUE_C128!TRUE
;******************************************************************************
:CLKRATE_Buf		b $00
endif

;******************************************************************************
::tmp21a = FD_NM!HD_NM!HD_NM_PP!IEC_NM!S2I_NM
::tmp21b = RL_NM!RD_NM!RD_NM_SCPU!RD_NM_CREU!RD_NM_GRAM
::tmp21  = :tmp21a!:tmp21b
if :tmp21 = TRUE
;******************************************************************************
:IO_Activ		b $00
endif

;******************************************************************************
::tmp22 = PC_DOS
if Flag64_128!:tmp22!TDOS_MODE = TRUE_C64!TRUE!TDOS_ENABLED
;******************************************************************************
:TC64Speed_Buf		b $00
endif

;******************************************************************************
::tmp24a = C_41!C_71!C_81!IEC_NM!S2I_NM
::tmp24b = FD_41!FD_71!FD_81!FD_NM!HD_41!HD_71!HD_81!HD_NM
::tmp24  = :tmp24a!:tmp24b
if Flag64_128!:tmp24!TDOS_MODE = TRUE_C64!TRUE!TDOS_DISABLED
;******************************************************************************
:TC64Speed_Buf		b $00
endif
