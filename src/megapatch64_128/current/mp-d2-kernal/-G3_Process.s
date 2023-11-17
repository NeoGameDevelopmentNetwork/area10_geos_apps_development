; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Prozesstabelle initialisieren.
:xInitProcesses		ldx	#$00			;Prozesse in Tabelle löschen.
			stx	MaxProcess
			sta	r1L			;Anzahl Prozesse merken.
			sta	r1H			;Zähler für Prozesse auf Start.
			tax
			lda	#%00100000		;Alle Prozesse auf "FROZEN"
::1			sta	ProcStatus-1,x		;zurückstellen.
			dex
			bne	:1

			ldy	#$00
::2			lda	(r0L),y			;Prozess-Routine in Tabelle.
			sta	ProcRout  +0,x
			iny
			lda	(r0L),y
			sta	ProcRout  +1,x
			iny
			lda	(r0L),y			;Prozess-Zähler in Tabelle.
			sta	ProcDelay +0,x
			iny
			lda	(r0L),y
			sta	ProcDelay +1,x
			iny
			inx
			inx
			dec	r1H			;Alle Prozesse eingelesen ?
			bne	:2			;Nein, weiter...
			lda	r1L			;Anzahl Prozesse merken.
			sta	MaxProcess
			rts

;*** Prozesse ausführen.
:ExecProcTab		ldx	MaxProcess		;Prozesse aktiv ?
			beq	:3			;Nein, weiter...
			dex				;Zeiger auf letzten Prozess.
::1			lda	ProcStatus,x		;Aktueller Prozess aktiv ?
			bpl	:2			;Nein, weiter...
			and	#%01000000		;Prozess-Pause aktiv ?
			bne	:2			;Ja, übergehen.
			lda	ProcStatus,x
			and	#%01111111
			sta	ProcStatus,x
			txa
			pha
			asl
			tax
			lda	ProcRout+0,x		;Adresse für Prozessroutine
			sta	r0L			;einlesen.
			lda	ProcRout+1,x
			sta	r0H
			jsr	ExecProcRout		;Prozessroutine ausführen.
			pla
			tax
::2			dex				;Zeiger auf nächsten
			bpl	:1			;Prozess.
::3			rts

if Flag64_128 = TRUE_C64
;*** Routine beim 128er unter IO-Bereich aus Speichermangel
;*** Prozesstabelle korrigieren.
:PrepProcData		lda	#$00
			tay
			tax
			cmp	MaxProcess		;Prozesse definiert ?
			beq	:4			;Nein, Ende...

::1			lda	ProcStatus,x
			and	#%00110000		;Prozess eingefroren ?
			bne	:3			;Ja, übergehen.

			lda	ProcCurDelay+0,y	;Zähler korrigieren.
			bne	:2			;(Zähler besteht aus 1 Word!)
			pha
			lda	ProcCurDelay+1,y
			sec
			sbc	#$01
			sta	ProcCurDelay+1,y
			pla
::2			sec
			sbc	#$01
			sta	ProcCurDelay+0,y
			ora	ProcCurDelay+1,y	;Zähler = $0000 ?
			bne	:3			;Nein, weiter...

			jsr	ResetProcDelay		;Prozess aktivieren.

			lda	ProcStatus,x
			ora	#%10000000
			sta	ProcStatus,x

::3			iny
			iny
			inx
			cpx	MaxProcess		;Alle Prozesse geprüft ?
			bne	:1			; => Nein, weiter...

::4			rts
endif

;*** Prozess wieder starten.
:xRestartProcess	lda	ProcStatus,x
			and	#%10011111
			sta	ProcStatus,x
:ResetProcDelay		txa
			pha
			asl
			tax
			lda	ProcDelay   +0,x
			sta	ProcCurDelay+0,x
			lda	ProcDelay   +1,x
			sta	ProcCurDelay+1,x
			pla
			tax
			rts

;*** Prozess sofort starten.
:xEnableProcess		lda	ProcStatus,x
			ora	#%10000000
			bne	NewProcStatus

;*** Prozess nicht mehr ausführen.
:xBlockProcess		lda	ProcStatus,x
			ora	#%01000000
			bne	NewProcStatus

;*** Prozess wieder ausführen.
:xUnblockProcess	lda	ProcStatus,x
			and	#%10111111
			jmp	NewProcStatus

;*** Prozess-Zähler einfrieren.
:xFreezeProcess		lda	ProcStatus,x
			ora	#%00100000
			bne	NewProcStatus

;*** Prozess-Zähler freigeben.
:xUnfreezeProcess	lda	ProcStatus,x
			and	#%11011111
:NewProcStatus		sta	ProcStatus,x
			rts

if Flag64_128 = TRUE_C64;Routine beim 128er unter IO-Bereich aus Speichermangel
;*** Sleep-Wartezeit korrigieren.
:DecSleepTime		ldx	MaxSleep		;Sleep-Routinen aktiv ?
			beq	:4			;Nein, Ende...
			dex
::1			lda	SleepTimeL,x		;Wartezeit (Word)
			bne	:2			;korrigieren.
			ora	SleepTimeH,x
			beq	:3
			dec	SleepTimeH,x
::2			dec	SleepTimeL,x
::3			dex
			bpl	:1
::4			rts
endif

;*** Alle Sleep-Routinen ausführen wenn Wartezeit = $0000.
:ExecSleepJobs		ldx	MaxSleep		;Sleep-Routinen aktiv ?
			beq	:3			;Nein, Ende...
			dex
::1			lda	SleepTimeL,x
			ora	SleepTimeH,x		;Wartezeit abgelaufen ?
			bne	:2			;Nein, weiter...
			lda	SleepRoutH,x		;Sleep-Routine einlesen.
			sta	r0H
			lda	SleepRoutL,x
			sta	r0L
			txa
			pha
			jsr	Del1stSleep		;Ersten Eintrag löschen.
			jsr	DoSleepJob		;Sleep-Routine aufrufen.
			pla
			tax
::2			dex
			bpl	:1			;Nächsten Sleep testen.
::3			rts

;*** SLEEP-Routine aufrufen.
:DoSleepJob		jsr	SetNxByte_r0
;			inc	r0L
;			bne	ExecProcRout
;			inc	r0H

;*** Prozess-Routine ausführen.
:ExecProcRout		jmp	(r0)

;*** Eintrag aus SLEEP-Tabelle löschen.
:Del1stSleep		php
			sei
::1			inx
			cpx	MaxSleep
			beq	:2
			lda	SleepTimeL  ,x
			sta	SleepTimeL-1,x
			lda	SleepTimeH  ,x
			sta	SleepTimeH-1,x
			lda	SleepRoutL  ,x
			sta	SleepRoutL-1,x
			lda	SleepRoutH  ,x
			sta	SleepRoutH-1,x
			jmp	:1

::2			dec	MaxSleep
			plp
			rts

;*** GEOS-Pause einlegen.
:xSleep			php
			pla
			tay
			sei
			ldx	MaxSleep
			lda	r0L
			sta	SleepTimeL,x
			lda	r0H
			sta	SleepTimeH,x
			pla
			sta	SleepRoutL,x
			pla
			sta	SleepRoutH,x
			inc	MaxSleep
			tya
			pha
			plp
			rts
