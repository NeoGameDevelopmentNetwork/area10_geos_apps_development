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

			LoadB	r10L,3			;3x64K für GEOS/MP3.

			ldx	#$08
::51			lda	UserConfig  -8,x	;RAM-Laufwerk ?
			bpl	:54			; => Nein, weiter...
;--- Ergänzung: 06.08.18/M.Kanet
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU nutzen die
;Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
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
::56			LoadW	r0,Dlg_LessRAM		;Mehr als ein RAMNative-Laufwerk
			jsr	Col2IconDlgBox		;angeschlossen. Fehler anzeigen.

			lda	sysDBData
			cmp	#YES			;RAMNative-Laufwerke löschen ?
			beq	:58			; => Ja, weiter...
::57			jmp	ExitUpdate		;zurück zum DeskTop.

;--- Weitere RAM-Laufwerke löschen.
::58			LoadW	r0,Dlg_ReplaceRAM	;Mehr als ein RAM-Laufwerk
			jsr	Col2IconDlgBox		;angeschlossen. Fehler anzeigen.

			lda	sysDBData
			cmp	#YES			;RAMNative-Laufwerke löschen ?
			bne	:57			; => Ja, weiter...

			ldy	#$00
			ldx	#$08
::59			lda	UserConfig  -8,x	;Laufwerkstyp einlesen.
			bpl	:61			; => Nein, weiter...
			tya				;Erster RAMNative-Laufwerk ?
			bne	:60			; => Ja, weiter...
			lda	#DrvRAMNM		;RAMNative-Laufwerk löschen.
			b $2c
::60			lda	#$00
			sta	UserConfig  -8,x
			iny				;Anzahl RAMNative-Laufwerk +1.
::61			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getestet ?
			bcc	:59			; => Nein, weiter...
			rts				;Installation fortsetzen.

;*** Dialogbox: Keine Speichererweiterung.
:Dlg_LessRAM		b %00000000
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Information
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$30
			w :103
			b DBTXTSTR ,$0c,$40
			w Dlg_ReplaceRAM1
			b DBTXTSTR ,$0c,$4a
			w Dlg_ReplaceRAM2
			b CANCEL   ,$02!DOUBLE_B,$60
			b YES      ,$1c!DOUBLE_B,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_CancelUpdate
			b NULL

if Sprache = Deutsch
::101			b "Es ist nicht genügend erweiterter Speicher",NULL
::102			b "vefügbar um alle RAM-Laufwerke unter",NULL
::103			b "GEOS-MegaPatch zu installieren!",NULL
endif
if Sprache = Englisch
::101			b "Not enough extended memory available to",NULL
::102			b "configure all currently installed ram-drives",NULL
::103			b "for GEOS-MegaPatch!",NULL
endif

;*** Dialogbox: Keine Speichererweiterung.
:Dlg_ReplaceRAM		b $00
			b $20,$97
			w $0010 ! DOUBLE_W
			w $012f ! DOUBLE_W ! ADD1_W

			b DBTXTSTR ,$0c,$10
			w Dlg_Information
			b DBTXTSTR ,$0c,$1c
			w :101
			b DBTXTSTR ,$0c,$26
			w :102
			b DBTXTSTR ,$0c,$36
			w Dlg_ReplaceRAM1
			b DBTXTSTR ,$0c,$40
			w Dlg_ReplaceRAM2
			b YES      ,$02!DOUBLE_B,$60
			b CANCEL   ,$1c!DOUBLE_B,$60
			b DBTXTSTR ,$48,$6c
			w :103
			b NULL

if Sprache = Deutsch
::101			b "Wenn Sie weitermachen wird der Inhalt aller",NULL
::102			b "RAM-Laufwerke vollständig gelöscht!",NULL
::103			b "(NativeRAM installieren)",NULL
endif
if Sprache = Englisch
::101			b "If you continue all files stored in all ram-",NULL
::102			b "drives will be erased!",NULL
::103			b "(Install NativeRAM)",NULL
endif

;*** Texte für alle Dialogboxen.
if Sprache = Deutsch
:Dlg_ReplaceRAM1	b "Alle RAM-Laufwerke durch ein NativeRAM-",NULL
:Dlg_ReplaceRAM2	b "Laufwerk ersetzen ?",NULL
endif

if Sprache = Englisch
:Dlg_ReplaceRAM1	b "Replace all installed ram-drives with a",NULL
:Dlg_ReplaceRAM2	b "single NativeRAM-drive ?",NULL
endif
