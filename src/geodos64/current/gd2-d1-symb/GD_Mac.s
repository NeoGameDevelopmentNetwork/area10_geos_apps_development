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
			bcc	:Exit
			inc	§1+1
::Exit
			/

;*** Word auf NULL testen.
:CmpW0			m
			lda	§0+1
			bne	:Exit
			lda	§0+0
::Exit
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
			bne	:Exit
			inc	§0+1
::Exit
			/

;*** Text ausgeben.
:PrintStrg		m
			lda	#<§0
			ldx	#>§0
			jsr	PutText
			/

;*** Text an Pos x,y ausgeben.
:PrintXY		m
			lda	#<§0
			sta	r11L
			lda	#>§0
			sta	r11H
			ldy	#§1
			lda	#<§2
			ldx	#>§2
			jsr	PutXYText
			/

;*** Inline-Textausgabe.
:Print			m
			jsr	i_PutString
			w	§0
			b	§1
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
:FillPRec		m
			jsr	i_GraphicsString
			b	NEWPATTERN,§0
			b	MOVEPENTO
			w	§3
			b	§1
			b	RECTANGLETO
			w	§4
			b	§2
			b	NULL
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

;*** Window zeichnen.
:Window			m
			lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	§0  , §0+7
			w	§2  , §3
			jsr	i_Rectangle
			b	§0+8, §1
			w	§2  , §3
			lda	#%11111111
			jsr	FrameRectangle

			jsr	i_C_MenuClose
			b	§2/8  ,§0/8  ,              $01,              $01
			jsr	i_C_MenuTitel
			b	§2/8+1,§0/8  ,(§3 +1 -§2) /8 -1,              $01
			jsr	i_C_MenuBack
			b	§2/8  ,§0/8+1,(§3 +1 -§2) /8   ,(§1 +1 -§0) /8 -1

			jsr	i_BitmapUp
			w	Icon_Close
			b	§2/8  ,§0    ,              $01,              $08

			jsr	UseGDFont
			/

;*** Dialogbox.
:DB_RecBox		m
			lda	#<§0
			ldx	#>§0
			jsr	DBRECVBOX
			/

;*** Farbige Dialogbox.
:DB_UsrBox		m
			lda	#<§0
			ldx	#>§0
			jsr	DoUserBox
			/

;*** Farbige "OK"-Dialogbox.
:DB_OK			m
			lda	#<§0
			ldx	#>§0
			jsr	BOX_OK
			/

;*** Farbige "CANCEL"-Dialogbox.
:DB_CANCEL		m
			lda	#<§0
			ldx	#>§0
			jsr	BOX_CANCEL
			/

;*** Warten bis keine Maustaste gedrückt.
:NoMseKey		m
::Loop			lda	mouseData
			bpl	:Loop
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

;*** Floppy auf "TALK" schalten.
:DrvTalk		m
			jsr	UNTALK
			ldx	§0
			lda	DriveAdress-8,x
			jsr	TALK
			lda	#$ff
			jsr	TKSA
			/

;*** Floppy auf "LISTEN" schalten.
:DrvListen		m
			jsr	UNLSN
			ldx	§0
			lda	DriveAdress-8,x
			jsr	LISTEN
			lda	#$ff
			jsr	SECOND
			/

;*** Floppy auf "UNTALK" schalten.
:DrvUnTalk		m
			jsr	UNTALK
			/

;*** Floppy auf "UNLISTEN" schalten.
:DrvUnLstn		m
			jsr	UNLSN
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

;*** Ende ***
