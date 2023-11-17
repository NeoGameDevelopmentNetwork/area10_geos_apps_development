; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Aktuellen Laufwerkstreiber durch GD3-Treiber ersetzen.
;    Wichtig da alte Treiber oder neuere Wheels-Treiber Funktionen im Kernel
;    aufrufen, das neue GD3-Kernel aber bereits installiert ist. Das führt
;    dann zum Systemabsturz. Deshalb wird hier der aktive Treiber durch den
;    GD3-Treiber ersetzt.
;    Die anderen Laufwerke erhalten die neuen Treiber durch GD.CONFIG.
:LoadSysDiskDev		ldx	Device_Boot		;In Tabelle Treiber für aktuelles
			lda	UserConfig -8,x		;Laufwerk suchen. Der korrekte
			ldy	#0			;Laufwerkstyp wird zuvor über
::loop			ldx	tempDrvTypes,y		;":CheckSizeRAM/:Get_UserConfig"
			beq	:next			;ermittelt und gespeichert.
			cmp	tempDrvTypes,y
			beq	:found
::next			iny
			cpy	#DDRV_MAX
			bcc	:loop

::err			LoadW	r0,Dlg_NoDkDvErr	;Treiber nicht gefunden,
			jmp	DoDlgBox		;Installation abbrechen.

::found			tya
			jsr	LoadNewDkDrv		;Neuen Laufwerkstreiber laden.
			txa				;Laufwerksfehler ?
			bne	:err			; => Ja, Abbruch...

;Laufwerkstreiber für aktuelles Laufwerk
;laden und in REU zwischenspeichern.
;Der Treiber darf erst aktiviert werden
;wenn der GD3-Kernel aktiv ist!

;--- Ergänzung: 15.09.18/M.Kanet
;Der GeoRAMNative-Treiber benötigt einen Wert zur Bank-Größe der aktuellen
;GeoRAM. Der Wert wird bei der Installation über den GEOS.Editor im Treiber
;gespeichert. An dieser Stelle wird der Treiber aber direkt aus der System-
;datei eingelesen.  Daher muss der Wert für die Bank-Größe hier manuell an
;den Treiber übergeben werden.
;Vorher auf ein aktives MegaPatch-System testen. Ausserhalb von MegaPatch
;gibt es keinen GeoRAMNative-Treiber!
;Ohne diese Anpassung wird bei der Installtion unter MegaPatch von einem
;GeoRAMNative-Laufwerk auf das gleiche GeoRAMNative-Laufwerk einn Wert von
;#00 als BankGröße angesetzt da dies der Standardwert im Treiber ist.
			lda	UPDEOF + (diskDrvRelease - $9000) +0
			cmp	#"M"
			bne	:skip
			lda	UPDEOF + (diskDrvRelease - $9000) +4
			cmp	#"3"
			bne	:skip
			ldx	Device_Boot
			lda	UserConfig -8,x		;Aktuellen Laufwerkstyp einlesen.
			cmp	#DrvRAMNM_GRAM		;GeoRAMNative-Laufwerk?
			bne	:skip			; => Nein, weiter...

;--- Ergänzung: 27.09.19/M.Kanet
;Die Bank-Größe wird bei der Erkennung des aktuellen GEOS-DACC von der
;Routine ":FindActiveDACC" in "-G3_FindActDACC" gesetzt. Daher muss in
;dieser Routine auch zuerst auf eine GeoRAM getestet werden, damit dieser
;Wert in jedem Fall ermittelt wird.
			lda	GRAM_BANK_SIZE		;Bank-Größe speichern.
			sta	UPDEOF + (GeoRAMBSize - DISK_BASE)

::skip			lda	#< UPDEOF
			sta	r0L
			lda	#> UPDEOF
			sta	r0H
			ldx	#$00
			stx	r1L
			stx	r1H
			lda	#< R1S_DSKDEV_A
			sta	r2L
			lda	#> R1S_DSKDEV_A
			sta	r2H
			stx	r3L
			jmp	StashRAM
