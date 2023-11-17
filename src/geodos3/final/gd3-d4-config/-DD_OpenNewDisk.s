; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Partition oder DiskImage öffnen.
:OpenNewDisk		jsr	OpenDisk		;Diskette öffnen.
;			txa				;Keine Fehlerprüfung falls
;			beq	:skip_disk		;Partition ungültig.

			ldx	curDrive
			lda	RealDrvMode -8,x	;Partitioniertes Laufwerk ?
			bmi	:CMD			; => Ja, weiter...
			and	#SET_MODE_SD2IEC	;SD2IEC-Laufwerk?
			beq	:exit			; => Nein, Ende...

;--- SD2IEC: DiskImage öffnen.
::SD2IEC		jsr	:set_swap_data		;SwapFile erstellen und ggf.
			jsr	StashRAM		;Registermenü sichern.

			jsr	SlctDiskImg		;DiskImage wechseln.

			jsr	:set_swap_data		;Speicherbereich aus SwapFile
			jsr	FetchRAM		;wieder herstellen.

			clc
			bcc	:exit

::set_swap_data		LoadW	r0,FileNTab
			LoadW	r1,$0000
			LoadW	r2,SizeNTab
			MoveB	MP3_64K_DATA,r3L
			rts

;--- CMD-Laufwerk: Partition wechseln.
::CMD			LoadW	r0,Dlg_SlctPart
			LoadW	r5,dataFileName
			jsr	DoDlgBox		;Partition auswählen.
			jsr	OpenDisk		;Diskette öffnen.
;			clc
;			bcc	:exit

::exit			rts

;*** Dialogbox: Partition wählen.
:Dlg_SlctPart		b $81
			b DBGETFILES!DBSELECTPART ,$00,$00
			b CANCEL                  ,$00,$00
			b OPEN                    ,$00,$00
			b NULL
