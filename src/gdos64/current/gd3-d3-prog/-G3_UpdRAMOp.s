; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Ersatz für GEOS 2.x-StashRAM.
;--- Ergänzung: 25.10.18/M.Kanet
;Beim Update von einem GEOS 2.0/GeoRAM mit mehr RAM als vom RAM-Treiber
;unterstützt wird kommt es zu einen Systemabsturz.
;Ursache ist die im GEOS-2.0r verwendete Bankgröße von max. 16Kb und die
;durch GD3 verwendete variable Bankgröße von 16/32/64Kb:
;GEOS-2.0r speichert die Daten fälschlicherweise mit einer Bank-Größe von
;16Kb in einer GeoRAM >4Mb und GD3 greift nach dem Update mit einer
;Bankgröße von 32/64Kb auf die Daten zu.
;Daher wird hier die GD3-Routine für GeoRAM-StashRAM verwendet. Bei allen
;anderen RAMTreibern kann die GEOS-Routine verwendet werden.
;
; Beschreibung:
;    GEOS2.0r        GEOS 2r!    GD3
;    4Mb-GRAM  ==>      16Mb-GRAM
;   +-------+   0K  +-------+-------+
; B0! 16K.1 !       ! 16K.1 ! 16K.1 !B0
;   +-------+  16K  +-------+       !
; B1! 16K.2 !       !       ! 16K.2 !
;   +-------+  32K  +-------+       !
; B2! 16K.3 !       !       ! 16K.3 !
;   +-------+  48K  +-------+       !
; B3! 16K.4 !       !       ! 16K.4 !
;   +-------+  64K  +-------+-------+
; B4! 16K.5 !       ! 16K.2 ! 16K.5 !B1
;   +-------+  80K  +-------+       !
; B5! 16K.  !       !       ! 16K.6 !
;   +-------+  96K  +-------+       !
; B6! 16K.. !       !       ! 16K.7 !
;   +-------+ 112K  +-------+       !
; ..! 16K.. !       !       ! 16K.8 !
;   +-------+ 128K  +-------+-------+
; ..! 16K.. !       ! 16K.3 ! 16K.. !B2
;   +-------+ 144K  +-------+       !
; ..! 16K.. !       !       ! 16K.. !

;*** StashRAM für GEOS 2.0r.
;Bei C=REU, SCPU, RL wird der GEOS-Treiber verwendet.
:GD3StashRAM		lda	ExtRAM_Type		;RAM-Typ einlesen.
			cmp	#RAM_BBG		;Typ = BBG/GeoRAM?
			beq	:101			; => Ja, Sonderroutine verwenden.
			jmp	StashRAM
::101			jmp	StashRAM_GRAM

;*** VerifyRAM für GEOS 2.0r.
;Bei C=REU, SCPU, RL wird der GEOS-Treiber verwendet.
:GD3VerifyRAM		lda	ExtRAM_Type		;RAM-Typ einlesen.
			cmp	#RAM_BBG		;Typ = BBG/GeoRAM?
			beq	:101			; => Ja, Sonderroutine verwenden.
			jmp	VerifyRAM
::101			jmp	VerifyRAM_GRAM
