; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Register laden.
:Load_Reg		m
			lda	§0
			ldx	§1
			ldy	§2
			/

;*** Register speichern.
:Save_Reg		m
			sta	§0
			stx	§1
			sty	§2
			/

;*** Register laden.
:Load_VReg		m
			lda	#§0
			ldx	#§1
			ldy	#§2
			/

;*** Register mit Sektor-Parametern laden.
:LdSekData		m
			lda	Seite
			ldx	Spur
			ldy	Sektor
			/

;*** Register in Sektor-Parameter übertragen.
:SvSekData		m
			sta	Seite
			stx	Spur
			sty	Sektor
			/

;*** Register mit Job-Code Sektor-Parametern laden.
:LdJSekData		m
			lda	SIDS
			ldx	HDRS+0
			ldy	HDRS+1
			/

;*** Register in Sektor-Parameter für Job-Code übertragen.
:SvJSekData		m
			sta	SIDS
			stx	HDRS+0
			sty	HDRS+1
			/

;*** ZeroPage-Word rotieren.
:RORZWord		m
			ldx	#§0
			ldy	#§1
			jsr	DShiftRight
			/

;*** ZeroPage-Word rotieren.
:ROLZWord		m
			ldx	#§0
			ldy	#§1
			jsr	DShiftLeft
			/

;*** Word rotieren.
:RORWord		m
			lsr	§0+1
			ror	§0
			/

;*** Word rotieren.
:ROLWord		m
			asl	§0
			rol	§0+1
			/

;*** Word nach FAC.
:LoadFAC		m
			lda	§0
			ldx	§0+1
			jsr	Word_FAC
			/

;*** Bits löschen.
:AndB			m
			lda	§0
			and	#§1
			sta	§0
			/

;*** Byte zu Word addieren
:AddVBW			m
			lda	#§0
			clc
			adc	§1
			sta	§1
			bcc	:x_AddVBW
			inc	§1+1
::x_AddVBW
			/

;*** Text ausgeben.
:PrintStrg		m
			lda	#<§0
			sta	r0L
			lda	#>§0
			sta	r0H
			jsr	PutString
			/

;*** Text an Pos x,y ausgeben.
:PrintXY		m
			lda	#<§0
			sta	r11L
			lda	#>§0
			sta	r11H
			lda	#§1
			sta	r1H
			lda	#<§2
			sta	r0L
			lda	#>§2
			sta	r0H
			jsr	PutString
			/

;*** Füllmuster wählen
:Pattern		m
			lda	#§0
			jsr	SetPattern
			/

;*** Rechteck zeichnen.
:FillRec		m
			jsr	i_Rectangle
			b	§0,§1
			w	§2,§3
			/

;*** Rechteck zeichnen.
:FrameRec		m
			jsr	i_FrameRectangle
			b	§0,§1
			w	§2,§3
			b	§4
			/

;*** Anzeige-Bitmap wählen.
:Display		m
			lda	#§0
			sta	dispBufferOn
			/

;*** Farbe in ":COLOR_MATRIX" setzen.
:SetColRam		m
			jsr	i_FillRam
			w	§0
			w	COLOR_MATRIX +§1
			b	§2
			/

;*** Window zeichnen.
:Window			m
			lda	#$01
			jsr	SetPattern
			jsr	i_Rectangle
			b	§0+8, §1+8
			w	§2+8, §3+8
			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	§0, §1
			w	§2, §3
			lda	#%11111111
			jsr	FrameRectangle

			jsr	i_FillRam
			w	(§3 +1 -§2) / 8 -1
			w	COLOR_MATRIX + §0/8 * 40 +§2/8 +1
			b	$61

			lda	#$01
			jsr	SetPattern
			jsr	i_Rectangle
			b	§0  , §0+7
			w	§2+8, §3

			jsr	UseGDFont
			/

;*** Word auf NULL testen.
:CmpW0			m
			lda	§0+1
			bne	:x_CmpW0
			lda	§0+0
::x_CmpW0
			/

;*** Word löschen.
:ClrW			m
			lda	#$00
			sta	§0+0
			sta	§0+1
			/

;*** Byte löschen.
:ClrB			m
			lda	#$00
			sta	§0
			/

;*** Word um 1 erhöhen.
:IncWord		m
			inc	§0+0
			bne	:x_IncWord
			inc	§0+1
::x_IncWord
			/

;*** ":RecoverVector" setzen.
:SetRecVec		m
			lda	#<§0
			sta	RecoverVector+0
			lda	#>§0
			sta	RecoverVector+1
			/

;*** Farbige Dialogbox (wiederherstellen).
:RecDlgBox		m
			ldy	#<§0
			ldx	#>§0
			jsr	DoRecDlgBox
			/

;*** Farbige Dialogbox (wiederherstellen).
:ClrDlgBox		m
			ldy	#<§0
			ldx	#>§0
			jsr	DoClrDlgBox
			/

;*** Warten bis keine Maustaste gedrückt.
:NoMseKey		m
::x_NoMseKey		lda	mouseData
			bpl	:x_NoMseKey
			lda	#$00
			sta	pressFlag
			/

;*** Neue Maus-Position setzen.
:MseXYPos		m
			lda	#<§0
			sta	r11L
			lda	#>§0
			sta	r11H
			ldy	#§1
			sei
			sec
			jsr	StartMouseMode
			cli
			/

;*** Maus-Modus aktivieren.
:StartMouse		m
			sei
			clc
			jsr	StartMouseMode
			cli
			/

;*** Zeichen in DOS-Datei-Name auf Gültigkeit testen.
:TDosNmByt		m
			cmp	#$20
			bcs	:TDNB_2
::TDNB_1		lda	#"_"
			bne	:TDNB_3
::TDNB_2		cmp	#$7f
			bcs	:TDNB_1
::TDNB_3
			/

;*** Floppy auf "TALK" schalten.
:DrvTalk		m
			jsr	$ffab
			ldx	§0
			lda	DriveAdress-8,x
			jsr	$ffb4
			lda	#$ff
			jsr	$ff96
			/

;*** Floppy auf "LISTEN" schalten.
:DrvListen		m
			jsr	$ffae
			ldx	§0
			lda	DriveAdress-8,x
			jsr	$ffb1
			lda	#$ff
			jsr	$ff93
			/

;*** Floppy auf "UNTALK" schalten.
:DrvUnTalk		m
			jsr	$ffab
			/

;*** Floppy auf "UNLISTEN" schalten.
:DrvUnLstn		m
			jsr	$ffae
			/

;*** Laufwerks-Status testen.
:ChkStatus		m
			lda	STATUS
			bne	§0
			/

;*** Bytes an Floppy senden.
:C_Send			m
			lda	#<§0
			ldx	#>§0
			jsr	SendCom
			/

;*** Bytes von Floppy lesen.
:C_Receive		m
			lda	#<§0
			ldx	#>§0
			jsr	GetCom
			/

;*** Bytes an Floppy senden.
:CxSend			m
			lda	#<§0
			ldx	#>§0
			jsr	SendCom_a
			/

;*** Bytes von Floppy lesen.
:CxReceive		m
			lda	#<§0
			ldx	#>§0
			jsr	GetCom_a
			/

;*** Job ausführen.
:Do_Job			m
			lda	#<§0
			ldx	#>§0
			jsr	Wait_Job
			/

;*** GEOS-Turbo deaktivieren und I/O-Bereich einschalten.
:InitSPort		m
			jsr	PurgeTurbo
			jsr	InitForIO
