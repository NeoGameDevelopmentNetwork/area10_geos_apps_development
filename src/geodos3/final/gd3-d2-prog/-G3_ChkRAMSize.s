; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** RAM-Speicher testen.
:CheckSizeRAM		jsr	FindRAMLinkAdr		;RAMLink verfügbar ?
			jsr	Get_UserConfig		;Laufwerkserkennung.
			jsr	OpenBootPart		;Boot-Partition aktivieren.

			LoadB	r10L,3			;3x64K für GEOS/GD3.

			ldx	#$08
::51			lda	UserConfig  -8,x	;RAM-Laufwerk ?
			bpl	:54			; => Nein, weiter...
;--- Ergänzung: 06.08.18/M.Kanet
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU/RAMCard nutzen
;die Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
;Für diese Laufwerke muss kein Speicher innerhalb des
;GEOS/DACC reserviert werden.
			and	#%01110000		;ExtendedRAM-Laufwerk?
			bne	:54			; => Ja, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren und
			jsr	OpenDisk		;Diskette öffnen.

			ldx	curDrive
			lda	UserConfig  -8,x
			and	#%00001111

			ldx	#3			;Anzahl 64K-Bänke für RAM41.
			cmp	#$01			;RAM41-Laufwerk ?
			beq	:52			; => Ja, weiter...

			ldx	#6			;Anzahl 64K-Bänke für RAM71.
			cmp	#$02			;RAM71-Laufwerk ?
			beq	:52			; => Ja, weiter...

			ldx	#13			;Anzahl 64K-Bänke für RAM81.
			cmp	#$03			;RAM81-Laufwerk ?
			beq	:52			; => Ja, weiter...

			cmp	#$04			;RAMNative-Laufwerk ?
			bne	:53			; => Nein, weiter...

			ldx	#$01			;NativeRAM-header einlesen und
			stx	r1L			;Partitionsgröße ermitteln.
			inx
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock

			ldx	diskBlkBuf +8
::52			txa				;Anzahl 64K-Bänke addieren.
			clc
			adc	r10L
			sta	r10L

::53			ldx	curDrive
::54			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getestet ?
			bcc	:51			; => Nein, weiter...

			lda	r10L
			cmp	ExtRAM_Size		;Genügend RAM verfügbar ?
			beq	:55			; => Ja, weiter...
			bcs	:56			; => Nein, Fehler ausgeben.

;--- Genügend RAM verfügbar.
::55			rts

;--- Zuwenig RAM.
::56			lda	ExtRAM_Size
			cmp	#$08 +1			;Mehr als 512K GEOS-DACC ?
			bcc	:59			; => Nein, Keine RAM-Laufwerke.

			LoadW	r0,Dlg_LessRAM		;Nicht genügend Speicher für alle
			jsr	DoDlgBox		;RAM-Laufwerke. Fehler anzeigen.

			lda	sysDBData
			cmp	#YES			;RAMNative-Laufwerke erstellen ?
			beq	:58			; => Ja, weiter...
::57			jmp	ExitUpdate		;zurück zum DeskTop.

;--- Weitere RAM-Laufwerke löschen.
::58			LoadW	r0,Dlg_ReplaceRAM	;Sicherheitsabfrage: Inhalt der
			jsr	DoDlgBox		;RAM-Laufwerke wirklich löschen ?

			lda	sysDBData
			cmp	#YES			;Inhalt RAM-Laufwerke löschen ?
			bne	:57			; => Nein, Abbruch...
			beq	replOtherRAMdrv		; => Ja, weiter...

;--- Alle RAM-Laufwerke löschen.
::59			LoadW	r0,Dlg_NoRAMDrv		;Nicht genügend GEOS-DACC für
			jsr	DoDlgBox		;RAM-Laufwerke. Fehler anzeigen.

			lda	sysDBData
			cmp	#OK			;RAM-Laufwerke löschen ?
			bne	:57			; => Nein, Abbruch...
			beq	replAllRAMdrv		; => Ja, weiter...

;*** RAM-Laufwerke ersetzen.
:replOtherRAMdrv	ldy	#$00
			b $2c
:replAllRAMdrv		ldy	#$01
			ldx	#$08
::1			lda	UserConfig  -8,x	;Laufwerkstyp einlesen.
			bpl	:3			; => Nein, weiter...
			tya				;Erster RAMNative-Laufwerk ?
			bne	:2			; => Ja, weiter...
			lda	#DrvRAMNM		;RAMNative-Laufwerk löschen.
			b $2c
::2			lda	#$00
			sta	UserConfig  -8,x
			iny				;Anzahl RAMNative-Laufwerk +1.
::3			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getestet ?
			bcc	:1			; => Nein, weiter...
			rts				;Installation fortsetzen.

;*** Dialogbox: Nicht genügend DACC für RAM-Laufwerke.
:Dlg_NoRAMDrv		b %00000000
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w DlgBoxColor2
			b DBTXTSTR ,$10,$10
			w Dlg_Information
			b DBTXTSTR ,$10,$1c
			w :101
			b DBTXTSTR ,$10,$26
			w :102
			b DBTXTSTR ,$10,$36
			w :103
			b DBTXTSTR ,$10,$40
			w :104
			b DBTXTSTR ,$10,$50
			w :105
			b CANCEL   ,$02,$60
			b OK       ,$1c,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_CancelUpdate
			b NULL

if Sprache = Deutsch
::101			b "Es ist nicht genügend erweiterter Speicher",NULL
::102			b "vefügbar um RAM-Laufwerke zu installieren!",NULL
::103			b "Wenn Sie weitermachen, dann wird der Inhalt",NULL
::104			b "aller RAM-Laufwerke vollständig gelöscht!",NULL
::105			b "(Gilt nicht für CMD-RAMLink-Partitionen)",NULL
endif

if Sprache = Englisch
::101			b "Not enough extended memory available to",NULL
::102			b "configure RAM drives!",NULL
::103			b "If you continue, the contents of all RAM",NULL
::104			b "drives will be completely erased!",NULL
::105			b "(Does not apply to CMD-RAMLink partitions)",NULL
endif

;*** Dialogbox: Keine Speichererweiterung.
:Dlg_LessRAM		b %00000000
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w DlgBoxColor2
			b DBTXTSTR ,$10,$10
			w Dlg_Information
			b DBTXTSTR ,$10,$1c
			w :101
			b DBTXTSTR ,$10,$26
			w :102
			b DBTXTSTR ,$10,$30
			w :103
			b DBTXTSTR ,$10,$40
			w Dlg_ReplaceRAM1
			b DBTXTSTR ,$10,$4a
			w Dlg_ReplaceRAM2
			b CANCEL   ,$02,$60
			b YES      ,$1c,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_CancelUpdate
			b NULL

if Sprache = Deutsch
::101			b "Es ist nicht genügend erweiterter Speicher",NULL
::102			b "vefügbar um alle RAM-Laufwerke unter",NULL
::103			b "GEOS zu installieren!",NULL
endif

if Sprache = Englisch
::101			b "Not enough extended memory available to",NULL
::102			b "configure all currently installed ram-drives",NULL
::103			b "for GEOS!",NULL
endif

;*** Dialogbox: Keine Speichererweiterung.
:Dlg_ReplaceRAM		b $00
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w DlgBoxColor2
			b DBTXTSTR ,$10,$10
			w Dlg_Information
			b DBTXTSTR ,$10,$1c
			w :101
			b DBTXTSTR ,$10,$26
			w :102
			b DBTXTSTR ,$10,$36
			w Dlg_ReplaceRAM1
			b DBTXTSTR ,$10,$40
			w Dlg_ReplaceRAM2
			b YES      ,$02,$60
			b CANCEL   ,$1c,$60
			b DBTXTSTR ,$48,$6c
			w :103
			b NULL

if Sprache = Deutsch
::101			b "Wenn Sie weitermachen wird der Inhalt aller",NULL
::102			b "RAM-Laufwerke vollständig gelöscht!",NULL
::103			b "(NativeRAM installieren)",NULL
endif

if Sprache = Englisch
::101			b "If you continue, all contents of all RAM",NULL
::102			b "drives will be completely erased!",NULL
::103			b "(Install NativeRAM)",NULL
endif

if Sprache = Deutsch
:Dlg_ReplaceRAM1	b "Alle RAM-Laufwerke durch ein NativeRAM-",NULL
:Dlg_ReplaceRAM2	b "Laufwerk ersetzen ?",NULL
endif

if Sprache = Englisch
:Dlg_ReplaceRAM1	b "Replace all installed ram-drives with a",NULL
:Dlg_ReplaceRAM2	b "single NativeRAM-drive ?",NULL
endif
