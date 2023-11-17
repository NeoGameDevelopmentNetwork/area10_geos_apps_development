; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Neuen Namen eingeben.
;    Übergabe: r6 = Zeiger auf Name.
;              XREG = $00/$FF für Datei-/Verzeichnisname.
:GetNewName		stx	dlgBoxMode

			LoadW	r10,newName		;Original-Name in
			ldx	#r6L			;Eingabespeicher kopieren.
			ldy	#r10L
			jsr	SysFilterName

			jsr	i_MoveData		;Original-Dateiname speichern.
			w	newName
			w	oldName
			w	16

			jsr	AddSuffix		;Suffix "_x" für neuen Namen.

;--- HINWEIS:
;    Übergabe: r6  = Original Name.
;              r10 = Neuer Name.
::restart		PushW	r6			;Zeiger auf Original-Name sichern.

			lda	#<dlgBox_Text1a
			sta	dlgMsgInfo +0
			lda	#>dlgBox_Text1a
			sta	dlgMsgInfo +1

			ldx	#<Dlg_GetNewDName	;Neuer Verzeichnisname.
			ldy	#>Dlg_GetNewDName
			lda	dlgBoxMode
			bmi	:0

			pha

			lda	#<dlgBox_Text1b		;Neuer Dateiname ohne "Löschen".
			sta	dlgMsgInfo +0
			lda	#>dlgBox_Text1b
			sta	dlgMsgInfo +1

			pla
			bne	:0

			ldx	#<Dlg_GetNewFName	;Neuer Dateiname mit "Löschen".
			ldy	#>Dlg_GetNewFName

::0			stx	r0L
			sty	r0H
			jsr	DoDlgBox		;Neuen Namen eingeben.

			jsr	WM_WAIT_NOMSEKEY	;Warten bis keine M-Taste gedrückt.

			PopW	r6			;Zeiger Original-Name zurücksetzen.

			lda	sysDBData
			cmp	#CANCEL			;Abbruch gewählt?
			beq	:cancel			; => Ja, Ende...

			cmp	#YES			;Datei überschreiben?
			beq	:delete			; => Ja, weiter...
			cmp	#NO			;Datei überspringen?
			beq	:skip			; => Ja, weiter...

			ldy	#$00			;Alter/Neuer Name vergleichen.
::1			lda	(r6L),y
			cmp	newName,y
			bne	:ok
			tax
			beq	:ok
			iny
			cpy	#16
			bcc	:1
			bcs	:restart		; => Name unverändert, Neustart...

::ok			ldx	#NO_ERROR		;Neuer Name OK.
			b $2c
::skip			ldx	#$fd			;Datei überspringen.
			b $2c
::delete		ldx	#$fe			;Datei löschen.
			b $2c
::cancel		ldx	#$ff			;Abbruch gewählt.
			rts

;*** Suffix "_1", "_2"... anhängen.
;Suffix an Name anhängen.
;-Name < 2 Zeichen:
; Suffix wird angehängt.
;-Name < 14 Zeichen:
; Die letzten beiden Zeichen werden
; auf ein Suffix geprüft. Bei einem
; Suffix wird der Zähler erhöht.
;-Name >= 15 Zeichen:
; Die letzten beiden Zeichen werden
; mit dem Suffix überschrieben.
;
;Der Suffix wird nur von "0" bis "8"
;erhöht. Ist der Suffix "_9", dann
;wird der Suffix zurückgesetzt.
;
:AddSuffix		ldy	#$00			;Ende Dateiname suchen.
::1			lda	newName,y		;Ende erreicht?
			beq	:2			; => Ja, weiter...
			iny				;Weitersuchen.
			cpy	#16 +1			;Ende erreicht?
			bcc	:1			; => Nein, weiter...

::2			cpy	#2			;Weniger als 3 Zeichen?
			bcc	:5			; => Ja, weiter...

			lda	newName -2,y		;Letztes Zeichen einlesen.
			cmp	#"_"			;Zeichen <> "_"?
			bne	:3			; => Ja, neuer Suffix.

			ldx	newName -1,y		;Suffix einlesen.
			cpx	#"0"			;Suffix < "0"?
			bcc	:3			; => Ja, neuer Suffix.
			cpx	#"9"			;Suffix >= "9"?;
			bcs	:3			; => Ja, neuer Suffix.

			dey				;Zeiger auf Suffix korrigieren.

			inx				;Suffix +1.
			bne	:6

::3			cpy	#14 +1			;Max. 14 Zeichen?
			bcc	:5			; => Nein, weiter...
			ldy	#14			;Die letzten 2 Zeichen ersetzen.

::5			ldx	#"0"			;Neuen Suffix schreiben.
			lda	newName -1,y
			cmp	#"_"
			beq	:6
			lda	#"_"
			sta	newName,y
			iny
::6			txa
			sta	newName,y

			lda	#$00			;Rest des Namens löschen.
::7			iny
			sta	newName,y
			cpy	#16
			bcc	:7
			rts

;*** Titelzeile in Dialogbox löschen.
:Dlg_DrawTitel2		lda	#$00
			jsr	SetPattern
			jsr	i_Rectangle
			b	$18,$27
			w	$0040,$00ff
			lda	C_DBoxTitel
			jsr	DirectColor
			jmp	UseSystemFont

;*** Variablen.
:dlgBoxMode		b $00
:newName		s 17
:oldName		s 17

;*** Neuen Verzeichnisnamen eingeben.
:Dlg_GetNewDName	b %01100001
			b $30,$97
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
:dlgMsgInfo		w dlgBox_Text1a
			b DBTXTSTR   ,$0c,$2b
			w dlgBox_Text2
			b DBTXTSTR   ,$30,$2b
			w oldName
			b DBTXTSTR   ,$0c,$3a
			w dlgBox_Text3
			b DBTXTSTR   ,$0c,$45
			w dlgBox_Text2
			b DBGETSTRING,$30,$45 -6
			b r10L,16
;HINWEIS:
;GetString muss mit RETURN beendet
;werden, da "OK" kein NULL-Byte setzt!
;			b OK         ,$01,$50
;			b DBTXTSTR   ,$3b,$5c
;			w dlgBox_Text6
			b DBTXTSTR   ,$0c,$56
			w dlgBox_Text4
			b CANCEL     ,$11,$50
			b NULL

;*** Neuen Dateinamen eingeben.
:Dlg_GetNewFName	b %01100001
			b $18,$a7
			w $0040,$00ff

			b DB_USR_ROUT
			w Dlg_DrawTitel2
			b DBTXTSTR   ,$0c,$0b
			w Dlg_Titel_Info
			b DBTXTSTR   ,$0c,$20
			w dlgBox_Text1b
			b DBTXTSTR   ,$0c,$2b
			w dlgBox_Text2
			b DBTXTSTR   ,$30,$2b
			w oldName
			b DBTXTSTR   ,$0c,$3a
			w dlgBox_Text3
			b DBTXTSTR   ,$0c,$45
			w dlgBox_Text2
			b DBGETSTRING,$30,$45 -6
			b r10L,16
;HINWEIS:
;GetString muss mit RETURN beendet
;werden, da "OK" kein NULL-Byte setzt!
;			b OK         ,$01,$50
;			b DBTXTSTR   ,$3b,$5c
;			w dlgBox_Text6
			b DBTXTSTR   ,$0c,$57
			w dlgBox_Text4
			b CANCEL     ,$11,$50

			b DBTXTSTR   ,$0c,$62
			w dlgBox_Text4a
			b DBTXTSTR   ,$0c,$74
			w dlgBox_Text5
			b YES        ,$01,$78
			b DBTXTSTR   ,$3b,$84
			w dlgBox_Text7
			b NO         ,$11,$78
			b NULL

if LANG = LANG_DE
:dlgBox_Text1a		b PLAINTEXT
			b "Das Verzeichnis existiert bereits!"
			b NULL
:dlgBox_Text1b		b PLAINTEXT
			b "Die folgende Datei existiert bereits!"
			b NULL
:dlgBox_Text2		b BOLDON
			b "Name:"
			b PLAINTEXT,NULL
:dlgBox_Text3		b "Bitte neuen Namen eingeben:"
			b NULL
:dlgBox_Text4		b BOLDON
			b "Weiter mit 'RETURN'"
			b PLAINTEXT,NULL
:dlgBox_Text4a		b "oder alternativ:"
			b NULL
:dlgBox_Text5		b BOLDON
			b "Die vorhandene Datei löschen?"
			b PLAINTEXT,NULL
:dlgBox_Text7		b PLAINTEXT
			b "(Löschen)"
			b NULL
endif
if LANG = LANG_EN
:dlgBox_Text1a		b PLAINTEXT
			b "The directory does already exist!"
			b NULL
:dlgBox_Text1b		b PLAINTEXT
			b "The file does already exists!"
			b NULL
:dlgBox_Text2		b BOLDON
			b "Name:"
			b PLAINTEXT,NULL
:dlgBox_Text3		b "Please enter a new name:"
			b NULL
:dlgBox_Text4		b BOLDON
			b "Continue with 'RETURN'"
			b PLAINTEXT,NULL
:dlgBox_Text4a		b "Alternatively:"
			b NULL
:dlgBox_Text5		b BOLDON
			b "Delete existing file?"
			b PLAINTEXT,NULL
:dlgBox_Text7		b PLAINTEXT
			b "(Delete)"
			b NULL
endif
