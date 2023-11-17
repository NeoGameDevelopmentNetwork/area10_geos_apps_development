; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** GEOS-Seriennummer auf Disk schreiben.
:writeSerialGEOS	lda	GEOS_DISK_TYPE
			cmp	#"P"			;$50 = Hauptdiskette.
			beq	:2

;--- Keine Hauptdiskette.
::1			rts

;--- Bereits installiert?
::2			lda	curDirHead +$be
			ora	curDirHead +$bf
			bne	:1			; => Ja, Ende...

;--- Seriennummer einlesen.
			jsr	GetSerialNumber

;--- Seriennummer "verschlüsseln".
;Dabei wir die Serien-Nummer um 1Bit
;nach links verschieben, das Überlauf-
;bit rechts wieder einfügen.
			lda	r0L
			asl
			rol	r0H
			adc	#$00
			sta	curDirHead +$be
			lda	r0H
			sta	curDirHead +$bf

;--- BAM aktualisieren.
			jsr	PutDirHead

;--- BAM einlesen.
;Falls Disk schreibgeschützt wird beim
;nächsten Aufruf erneut versucht die
;Seriennummer zu schreiben.
			jmp	GetDirHead
