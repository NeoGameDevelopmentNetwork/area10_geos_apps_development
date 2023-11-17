; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;******************************************************************************
;*** Die Sprungtabelle zum setzen der RAM-Vektoren für die externen
;*** MP3-Routinen liegt unveränderlich am Ende des Bereichs $C000-$CFFF!!!
;******************************************************************************
:MP3_EXT_ROUT		= 20
:MP3_EXT_TabBytes	= MP3_EXT_ROUT *6
:MP3_EXT_VecBytes	= MP3_EXT_ROUT *3 -2
.Mem_CFFF_Temp		e $d000 -MP3_EXT_TabBytes -MP3_EXT_VecBytes -22
.Mem_CFFF
;******************************************************************************

;*** Zeiger auf externe Routinen in REU.
:MP3_64K_ADDR		w LD_ADDR_TASKMAN    ,R2_ADDR_TASKMAN    ,R2_SIZE_TASKMAN
			w LD_ADDR_REGISTER   ,R2_ADDR_REGISTER   ,R2_SIZE_REGISTER
			w LD_ADDR_ENTER_DT   ,R2_ADDR_ENTER_DT   ,R2_SIZE_ENTER_DT
			w LD_ADDR_TOBASIC    ,R2_ADDR_TOBASIC    ,R2_SIZE_TOBASIC
			w LD_ADDR_PANIC      ,R2_ADDR_PANIC      ,R2_SIZE_PANIC
			w LD_ADDR_GETNXDAY   ,R2_ADDR_GETNXDAY   ,R2_SIZE_GETNXDAY
			w LD_ADDR_DOALARM    ,R2_ADDR_DOALARM    ,R2_SIZE_DOALARM
			w LD_ADDR_GETFILES   ,R2_ADDR_GETFILES   ,R2_SIZE_GETFILES
			w LD_ADDR_GFILDATA   ,R2_ADDR_GFILDATA   ,R2_SIZE_GFILDATA
			w LD_ADDR_GFILMENU   ,R2_ADDR_GFILMENU   ,R2_SIZE_GFILMENU
			w LD_ADDR_DB_SCREEN  ,R2_ADDR_DB_SCREEN  ,R2_SIZE_DB_SCREEN
			w SCREEN_BASE        ,R2_ADDR_DB_GRAFX   ,R2_SIZE_DB_GRAFX
			w COLOR_MATRIX       ,R2_ADDR_DB_COLOR   ,R2_SIZE_DB_COLOR
			w LD_ADDR_GETBSCRN   ,R2_ADDR_GETBSCRN   ,R2_SIZE_GETBSCRN
			w LD_ADDR_SCRSAVER   ,R2_ADDR_SCRSAVER   ,R2_SIZE_SCRSAVER
			w LD_ADDR_SPOOLER    ,R2_ADDR_SPOOLER    ,R2_SIZE_SPOOLER

;--- Ergänzung: 30.12.18/M.Kanet
;Größe des Spoolers und Druckertreiber im RAM um 1Byte reduziert.
;geoCalc64 nutzt beim Drucken ab $$5569 eine Routine ab $7F3F. Diese Adresse
;ist aber noch für Druckertreiber reserviert. Wird der gesamte Speicher
;getauscht führt das zum Absturz in geoCalc.
;Mit der folgenden Anpassung dürfen Spooler+Treiber max. bis $7F3E reichen.
if Flag64_128 = TRUE_C64
.GCalcFix1		w PRINTBASE          ,R2_ADDR_PRNSPOOL   ,R2_SIZE_PRNSPOOL -1
			w fileHeader         ,R2_ADDR_PRNSPHDR   ,R2_SIZE_PRNSPHDR
endif
if Flag64_128 = TRUE_C128
.GCalcFix1		w PRINTBASE          ,R2_ADDR_PRNSPOOL   ,R2_SIZE_PRNSPOOL
			w fileHeader         ,R2_ADDR_PRNSPHDR   ,R2_SIZE_PRNSPHDR
endif

if Flag64_128 = TRUE_C64
.GCalcFix2		w PRINTBASE          ,R2_ADDR_PRINTER    ,R2_SIZE_PRINTER -1
			w fileHeader         ,R2_ADDR_PRNTHDR    ,R2_SIZE_PRNTHDR
endif
if Flag64_128 = TRUE_C128
;Beim 128er liegt der Druckertreiber nicht in der Speichererweiterung,
;sondern unter dem IO-Bereich!
.GCalcFix2		w $d9c0              ,PRINTBASE          ,R2_SIZE_PRINTER
			w $d8c0              ,fileHeader         ,R2_SIZE_PRNTHDR
endif

;*** Zeiger auf neue GEOS-Routinen im RAM.
;    ACHTUNG!!! Neue Vektoren hier einfügen und nicht am Ende, da sonst
;    die Sprungtabelle verschoben wird.
.SetADDR_PrntHdr	ldy	#$14 *6 -1		;Drucker #2.
			b $2c
.SetADDR_Printer	ldy	#$13 *6 -1		;Drucker #1.
			b $2c
.SetADDR_PrnSpHdr	ldy	#$12 *6 -1		;Drucker-Spooler #1.
			b $2c
.SetADDR_PrnSpool	ldy	#$11 *6 -1		;Drucker-Spooler #2.
			b $2c
.SetADDR_Spooler	ldy	#$10 *6 -1		;Spooler-Routine.
			b $2c
.SetADDR_ScrSaver	ldy	#$0f *6 -1		;Bildschirmschoner.
			b $2c
.SetADDR_BackScrn	ldy	#$0e *6 -1		;Hintergrundbild.
			b $2c
.SetADDR_DB_COLS	ldy	#$0d *6 -1		;Farben.
			b $2c
.SetADDR_DB_GRFX	ldy	#$0c *6 -1		;Grafik.
			b $2c
.SetADDR_DB_SCRN	ldy	#$0b *6 -1		;Dialogbox-Bildschirm löschen.
			b $2c
.SetADDR_GFilMenu	ldy	#$0a *6 -1		;GetFile - Box/Icons ausgeben.
			b $2c
.SetADDR_GFilData	ldy	#$09 *6 -1		;GetFile - Dateien einlesen.
			b $2c
.SetADDR_GetFiles	ldy	#$08 *6 -1		;GetFile
			b $2c
.SetADDR_DoAlarm	ldy	#$07 *6 -1		;DoAlarm
			b $2c
.SetADDR_GetNxDay	ldy	#$06 *6 -1		;GetNextDay
			b $2c
.SetADDR_PANIC		ldy	#$05 *6 -1		;PANIC!-Box
			b $2c
.SetADDR_ToBASIC	ldy	#$04 *6 -1		;ToBASIC
			b $2c
.SetADDR_EnterDT	ldy	#$03 *6 -1		;EnterDeskTop.
			b $2c
.SetADDR_Register	ldy	#$02 *6 -1		;Register
			lda	MP3_64K_SYSTEM
			bne	SetADDR

.SetADDR_TaskMan	ldy	#$01 *6 -1
			lda	Flag_TaskBank
:SetADDR		sta	r3L

			ldx	#$05
::1			lda	MP3_64K_ADDR,y
			sta	r0L         ,x
			dey
			dex
			bpl	:1
			rts
