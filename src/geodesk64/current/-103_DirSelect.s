; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** BASIC/SD-ROOT-Verzeichnis öffnen.
:dirRootSD		jsr	getModeSD2IEC		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:image			; => DiskImage-Modus aktiv.
			cpx	#$ff
			beq	:directory		; => Verzeichnis-Modus aktiv.
			rts				;Fehler, Abbruch...

::image			lda	#<FComExitDImg		;Aktives DiskImage verlassen.
			ldx	#>FComExitDImg
			jsr	SendCom

::directory		lda	#<FComCDRoot		;Root aktivieren.
			ldx	#>FComCDRoot
			jsr	SendCom
			jmp	getDiskData		;Neues Verzeichnis einlesen.

;*** BASIC/Ein SD-Verzeichnis zurück.
:dirOpenSD		jsr	getModeSD2IEC		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:1			; => DiskImage-Modus aktiv.
			cpx	#$ff
			beq	:1			; => Verzeichnis-Modus aktiv.
			rts				;Fehler, Abbruch...

::1			lda	#<FComExitDImg		;Ein SD2IEC-Verzeichnis zurück.
			ldx	#>FComExitDImg
			jsr	SendCom
			jmp	getDiskData		;Neues Verzeichnis einlesen.

;*** Verzeichnis oder DiskImage öffnen.
:dirOpenEntry		jsr	getModeSD2IEC		;SD2IEC-Modus testen.
			cpx	#$00			;Verzeichnis oder DiskImage?
			beq	:0			; => DiskImage-Modus aktiv.
			cpx	#$ff
			beq	:0			; => Verzeichnis-Modus aktiv.
			rts				;Fehler, Abbruch...

::0			ldy	#$05
			ldx	#$03
::1			lda	(a0L),y			;Verzeichnisname in "CD"-Befehl
			beq	:2			;übertragen...
			cmp	#$a0
			beq	:2
			sta	FComCDir+2,x
			inx
			iny
			cpy	#$05+16
			bne	:1
::2			lda	#$00			;Befehl abschließen.
			sta	FComCDir+2,x
			stx	FComCDir+0		;Länge Befehl setzen.

			lda	#<FComCDir		;Verzeichnis/Image wechseln.
			ldx	#>FComCDir
			jsr	SendCom

			ldy	#$02
			lda	(a0L),y
			and	#FTYPE_MODES		;Dateityp isolieren.
			cmp	#FTYPE_DIR		;Verzeichnis-Wechsel?
			beq	:exit			; => Nein weiter...

			lda	curType
			and	#DRIVE_MODES		;Laufwerksmodus einlesen.
			cmp	#DrvNative		;NativeMode?
			bne	:3			; => Ja, weiter...
			jmp	OpenRootDir		;Native: Hauptverzeichnis öffnen.
::3			jmp	OpenDisk		;Disk öffnen/CalcBlksFree.

::exit			ldx	#$ff			;Flag setzen: "Dateien einlesen".
::error			rts
