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
::loop			lda	UserConfig  -8,x	;RAM-Laufwerk ?
			bmi	:drvRAM			; => Ja, weiter...

			lda	driveType -8,x
;HINWEIS:
;Während Update wird ein 1541/Shadow-
;Laufwerk nicht übernommen und in ein
;1541-Laufwerk umgewandelt.
if FALSE
			cmp	#DrvShadow1541		;1541/Shadow-Laufwerk ?
			beq	:drv41			; => Ja, weiter...
endif
			cmp	#DrvPCDOS		;PCDOS-Laufwerk ?
			beq	:drvDOS			; => Ja, weiter...
			bne	:skip			; => Nein, nächstes Laufwerk.

;--- Ergänzung: 06.08.18/M.Kanet
;Die Extended RAM-Laufwerke für GeoRAM, C=REU und SCPU/RAMCard nutzen
;die Bits #6(SCPU), #5+#4(GeoRAM), #5(C=REU).
;Für diese Laufwerke muss kein Speicher innerhalb des
;GEOS/DACC reserviert werden.
::drvRAM		and	#%01110000		;ExtendedRAM-Laufwerk?
			bne	:skip			; => Ja, weiter...
			txa
			jsr	SetDevice		;Laufwerk aktivieren und

			ldx	curDrive
			lda	UserConfig  -8,x
			and	#%00001111

			cmp	#Drv1541		;RAM41-Laufwerk ?
			beq	:drv41			; => Ja, weiter...

			cmp	#Drv1571		;RAM71-Laufwerk ?
			beq	:drv71			; => Ja, weiter...

			cmp	#Drv1581		;RAM81-Laufwerk ?
			beq	:drv81			; => Ja, weiter...

			cmp	#DrvNative		;RAMNative-Laufwerk ?
			bne	:next			; => Nein, weiter...

			jsr	OpenDisk		;Diskette öffnen.
;			txa				;Fehler ?
;			bne	:next			; => Ja, Laufwerk ignorieren...

			ldx	#$01			;NativeRAM-header einlesen und
			stx	r1L			;Partitionsgröße ermitteln.
			inx
			stx	r1H
			LoadW	r4,diskBlkBuf
			jsr	GetBlock
;			txa				;Fehler ?
;			bne	:next			; => Ja, Laufwerk ignorieren...

::drvNM			ldx	diskBlkBuf +8
			b $2c
::drv41			ldx	#3			;Anzahl 64K-Bänke für RAM41.
			b $2c
::drv71			ldx	#6			;Anzahl 64K-Bänke für RAM71.
			b $2c
::drv81			ldx	#13			;Anzahl 64K-Bänke für RAM81.
			b $2c
::drvDOS		ldx	#1			;Anzahl 64K-Bänke für PCDOS.

			txa				;Anzahl 64K-Bänke addieren.
			clc
			adc	r10L
			sta	r10L

::next			ldx	curDrive
::skip			inx				;Zeiger auf nächstes Laufwerk.
			cpx	#12			;Alle Laufwerke getestet ?
			bcc	:loop			; => Nein, weiter...

			lda	r10L
			cmp	ExtRAM_Size		;Genügend RAM verfügbar ?
			beq	:done			; => Ja, weiter...
			bcs	:errRAMsize		; => Nein, Fehler ausgeben.

;--- Genügend RAM verfügbar.
::done			rts

;--- Zuwenig RAM.
::errRAMsize		lda	ExtRAM_Size
			cmp	#$08 +1			;Mehr als 512K GEOS-DACC ?
			bcc	:errNoRAMdrv		; => Nein, Keine RAM-Laufwerke.

			LoadW	r0,Dlg_LessRAM		;Nicht genügend Speicher für alle
			jsr	DoDlgBox		;RAM-Laufwerke. Fehler anzeigen.

			lda	sysDBData
			cmp	#YES			;RAMNative-Laufwerke erstellen ?
			beq	:errNativeRAM		; => Ja, weiter...
::cancel		jmp	ExitUpdate		;zurück zum DeskTop.

;--- Weitere RAM-Laufwerke löschen.
::errNativeRAM		LoadW	r0,Dlg_ReplaceRAM	;Sicherheitsabfrage: Inhalt der
			jsr	DoDlgBox		;RAM-Laufwerke wirklich löschen ?

			lda	sysDBData
			cmp	#YES			;Inhalt RAM-Laufwerke löschen ?
			bne	:cancel			; => Nein, Abbruch...
			beq	replOtherRAMdrv		; => Ja, weiter...

;--- Alle RAM-Laufwerke löschen.
::errNoRAMdrv		LoadW	r0,Dlg_NoRAMDrv		;Nicht genügend GEOS-DACC für
			jsr	DoDlgBox		;RAM-Laufwerke. Fehler anzeigen.

			lda	sysDBData
			cmp	#OK			;RAM-Laufwerke löschen ?
			bne	:cancel			; => Nein, Abbruch...
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
			w Dlg_InfoRAM1
			b DBTXTSTR ,$10,$26
			w Dlg_InfoRAM2a
			b DBTXTSTR ,$10,$36
			w Dlg_WarnRAM1
			b DBTXTSTR ,$10,$40
			w Dlg_WarnRAM2
			b DBTXTSTR ,$10,$50
			w Dlg_InfoRAM3
			b CANCEL   ,$02,$60
			b OK       ,$1c,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_CancelUpdate
			b NULL

;*** Dialogbox: Zu wenig Speicher für alle RAM-Laufwerke.
:Dlg_LessRAM		b %00000000
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w DlgBoxColor2
			b DBTXTSTR ,$10,$10
			w Dlg_Information
			b DBTXTSTR ,$10,$1c
			w Dlg_InfoRAM1
			b DBTXTSTR ,$10,$26
			w Dlg_InfoRAM2b
			b DBTXTSTR ,$10,$36
			w Dlg_ReplaceRAM1a
			b DBTXTSTR ,$10,$40
			w Dlg_ReplaceRAM2
			b CANCEL   ,$02,$60
			b YES      ,$1c,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_CancelUpdate
			b NULL

;*** Dialogbox: Letzte Warnung.
:Dlg_ReplaceRAM		b $00
			b $20,$97
			w $0010,$012f

			b DB_USR_ROUT
			w DlgBoxColor2
			b DBTXTSTR ,$10,$10
			w Dlg_LastWarn1
			b DBTXTSTR ,$10,$1c
			w Dlg_WarnRAM1
			b DBTXTSTR ,$10,$26
			w Dlg_WarnRAM2
			b DBTXTSTR ,$10,$36
			w Dlg_ReplaceRAM1b
			b DBTXTSTR ,$10,$40
			w Dlg_ReplaceRAM2
			b YES      ,$02,$60
			b CANCEL   ,$1c,$60
			b DBTXTSTR ,$48,$6c
			w Dlg_WarnRAM3
			b NULL

;*** Texte für Dialogboxen.
if LANG = LANG_DE
:Dlg_InfoRAM1		b PLAINTEXT
			b "Es ist nicht genügend erweiterter Speicher verfügbar um",NULL
:Dlg_InfoRAM2a		b "RAM-Laufwerke zu installieren.",NULL
:Dlg_InfoRAM2b		b "alle RAM-Laufwerke unter GDOS zu installieren.",NULL
:Dlg_InfoRAM3		b PLAINTEXT
			b "(Gilt nicht für CMD-RAMLink-Partitionen)",NULL
:Dlg_WarnRAM1		b BOLDON
			b "Wenn Sie die Installation fortsetzen, dann wird",NULL
:Dlg_WarnRAM2		b "der Inhalt aller RAM-Laufwerke gelöscht!",NULL
:Dlg_WarnRAM3		b PLAINTEXT
			b "(NativeRAM installieren)",NULL
:Dlg_LastWarn1		b BOLDON
			b "LETZTE WARNUNG!",NULL
:Dlg_ReplaceRAM1a	b BOLDON
			b "Alle vorhandenen RAM-Laufwerke durch",NULL
:Dlg_ReplaceRAM1b	b BOLDON
			b "Wirklich alle vorhandenen RAM-Laufwerke durch",NULL
:Dlg_ReplaceRAM2	b "ein einzelnes RAMNative-Laufwerk ersetzen ?",NULL
endif

if LANG = LANG_EN
:Dlg_InfoRAM1		b PLAINTEXT
			b "There is not enough extended memory available to",NULL
:Dlg_InfoRAM2a		b "install RAM drives!",NULL
:Dlg_InfoRAM2b		b "install all RAM drives for GDOS.",NULL
:Dlg_InfoRAM3		b PLAINTEXT
			b "(Does not apply to CMD-RAMLink partitions)",NULL
:Dlg_WarnRAM1		b BOLDON
			b "If you continue with the installation, the",NULL
:Dlg_WarnRAM2		b "contents of all RAM drives will be erased!",NULL
:Dlg_WarnRAM3		b PLAINTEXT
			b "(Install NativeRAM)",NULL
:Dlg_LastWarn1		b BOLDON
			b "LAST WARNING!",NULL
:Dlg_ReplaceRAM1a	b BOLDON
			b "Do you want to replace all installed",NULL
:Dlg_ReplaceRAM1b	b BOLDON
			b "Do you really want to replace all installed",NULL
:Dlg_ReplaceRAM2	b "RAM drives with a single RAMNative drive ?",NULL
endif
