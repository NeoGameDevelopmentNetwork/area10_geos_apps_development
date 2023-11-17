;--------------------------
;input de luxe version 4.4-
;written 1989/90/2020 by :-
;markus kanet             -
;--------------------------

;ende source max. $b5ff, da
;input-ass max. $9000 bytes
;einliest!!!

;ctrl+k/x muss bei *=1500 enden!

org $0801

:chrget = $0073
:chrgot = $0079
:color  = $0286
:error  = $a437
:newclr = $a659
:getbyt = $b79e
:intprt = $a7ae
:let    = $a9ba
:print  = $aaa0
:chknum = $ad8d
:chkstr = $ad8f
:typmis = $ad99
:frmevl = $ad9e
:chkcom = $aefd
:fndvar = $b08b
:putvar = $b0e7
:facint = $b1aa
:illqua = $b248
:umult  = $b357
:intfac = $b391
:chkdir = $b3a6
:strpoi = $b479
:frestr = $b6a3
:vic17  = $d011
:combyt = $e200
:partst = $e206
:plot   = $e50c
:getpos = $e513
:stupt  = $e56c
:bsout  = $ffd2
:getin  = $ffe4

;-------
b $15,$08,$c6,$07   ;sys-zeile zum
b $9e,$32,$30,$37   ;starten des ms-
b $32,$3a,$85,$20   ;programms, welches
b $44,$45,$20,$4c   ;den basic-anfang
b $55,$58,$45,$00   ;hochsetzt
b $00,$00,$00
;-------
        ldx #$15    ;basic-anfang auf
        ldy #$01    ;$1301 setzen
        stx $2c
        sty $2b
        dey         ;null-byte vor
        sty $1500   ;basic-anfang
        jsr newclr  ;vorhandenes basic-
        jmp intprt  ;programm starten.
;-------
        jmp p0      ;sprungtabelle fuer
        jmp p3      ;printat, idl,
        jmp p1      ;msidl und
        jmp p2      ;chardef
        jmp p4      ;syntax-output
        jmp p5      ;parameter-editor
        jmp p6      ;efkey-editor
;-------
;print-at routine
;-------
:p0     jsr combyt  ;komma ? zahl holen
        cpx #$19    ;>24 ?
        bcs p0a     ;ja, illegal quant.
        stx $d6     ;zeile setzen
        jsr combyt  ;komma ? zahl holen
        cpx #$28    ;>39 ?
        bcs p0a     ;ja, illegal quant.
        stx $d3     ;spalte setzen
        jsr stupt   ;cursor neu setzen
        jsr partst  ;test auf nur
        jsr chkcom  ;curosor setzen
        jmp print   ;weiter mit print
:p0a    jmp illqua  ;illegal quantity
;-------
;assembler-einsprung fuer neuen
;input-befehl
;-------
:p1     jsr ic      ;input vorbereiten
        inc bm      ;aus assembler-modus
        tya         ;schalten
        sta ($7a),y
        jmp p3a     ;einsprung in input
;-------
;zeichencodes aendern
;-------
:p2     jsr chkcom  ;komma ?
        jsr frmevl  ;string holen
        jsr frestr  ;stringdaten holen
        cmp #$04    ;laenge = 4 ?
        bne p2b     ;nein, type mismatch
        ldy #$03
:p2a    lda ($22),y ;zeichen holen
        jsr sub3    ;nach bildschirmcode
        sta k0,y    ;und speichern
        dey
        bpl p2a     ;alle 4 zichen ?
        rts         ;ja, ende
:p2b    jmp typmis  ;type mismatch
;-------
;sys2102,0 = idl-syntax ausgeben
;sys2102,x = parameterfehler anzeigen
;-------
:p4     jsr combyt  ;fehlercode holen
        stx $03     ;und merken
        lda #<p4h   ;"sys 2093" ausgeben
        ldy #>p4h
        jsr $ab1e
        ldy #$00    ;alle parameter aus-
        ldx #$01    ;geben und pruefen
        stx $04     ;ob dieser mit dem
:p4a    cpx $03     ;fehlercode ueber-
        bne p4b     ;einstimmt.
        inc $c7     ;wenn ja, dann
        jsr p4f     ;revers darstellen.
        dec $c7
        jsr p4g     ;komma ausgeben
        jmp p4c     ;schleife
:p4b    jsr p4f
        jsr p4g
:p4c    inc $04
        ldx $04     ;schon alle para-
        cpx #$08    ;meter ausgegeben ?
        bne p4e     ;nein, weiter
:p4d    lda p4i,y
        jsr $ffd2
        iny
        cpy #$1e
        bne p4d
        jmp p4a
:p4e    cpx #$12    ;alle parameter ?
        bne p4a     ;nein, dann weiter.
:p4f    jsr p4g     ;zwei zeichen aus-
:p4g    lda p4i,y   ;geben.
        iny
        jmp $ffd2

:p4h    b $0d,"sys 2093,",0
:p4i    b "ze,sp,la,t$,z$,e$,vo",$0d
        b "       [,fm,hm,po,an,fw,fn,rm,cm,ev,cv]",$0d,$00
;-------
;parameter-editor
;-------
:p5     jsr partst  ;folgt parameter ?
        jsr combyt  ;ja, einlesen
        cpx #$08    ;nur fm-mm ?
        bcc p5a     ;ja, erlaubt
        jmp illqua  ;illegal quantity
:p5a    stx $f7     ;parameter merken
        jsr combyt  ;ein/aus-flag
        cpx #$00    ;0 = ausschalten
        bne p5c
        jsr combyt  ;vorgabewert
        txa         ;einlesen und in
        ldy $f7     ;puffer speichern
        ldx p5f,y
        sta last,x
        jsr p5b     ;aufruf fuer para-
        lda #<h7b   ;meter modifizieren
        ldx #>h7b
        jmp p5d
:p5b    ldx p5e,y   ;startadresse der
        lda p3a+1,x ;routine fuer para-
        sta $22     ;meter ermitteln
        lda p3a+2,x ;und in $22/$23
        sta $23     ;speichern
        rts
:p5c    ldy $f7     ;parameter ein-
        jsr p5b     ;schalten
        lda #<h7
        ldx #>h7
:p5d    ldy #$01    ;routine zum
        sta ($22),y ;de-/aktivieren von
        iny         ;parametern
        txa
        sta ($22),y
        jmp p5      ;pruefen, ob behand-
                    ;lung weiterer para-
                    ;meter erwuenscht
:p5e    b $00,$03,$09,$0c
        b $12,$15,$18,$1b
:p5f    b $00,$01,$02,$03
        b $04,$05,$06,$07
;-------
;editor-tasten definition
;-------
:p6     jsr combyt  ;wert fuer em
        stx em      ;einlesen
        jsr chkcom  ;stringausdruck
        jsr frmevl  ;holen und
        jsr frestr  ;auswerten
        cmp #$00    ;laenge = 0 ?
        bne p6a
        sta efkey+6 ;ja, f8 +
        sta efkey+7 ;shift/return
        rts         ;ausschalten
:p6a    cmp #$02    ;mindestens 2
        bcs p6b     ;zeichen ?
        ldx #$0d    ;nein, fehler
        jmp error
:p6b    stx $22     ;f8 und shift/return
        sty $23     ;neu definieren,
        ldy #$01    ;space = code
:p6c    lda ($22),y ;ueberspringen
        cmp #$20
        beq p6d
        sta efkey+6,y
:p6d    dey
        bpl p6c
        rts         ;ruecksprung
;-------
;neue input-routine
;-------
:p3     jsr init    ;input vorbereiten
;-------
;ermitteln der parameter ze bis vo
;-------
        jsr a1      ;zeile
        jsr a2      ;spalte
        jsr a3      ;laenge
        jsr a4      ;erlaubte tasten
        jsr a5      ;zielvariable
        jsr a6      ;abbruch-tasten
        jsr a7      ;vorgabe
;-------
;ermitteln der optionalen parameter
;-------
:p3a    jsr c1      ;feld-modus
        jsr c2      ;hide-modus
        jsr b1      ;vorgabe ausfuehren
        jsr c3      ;cursorposition
        jsr c4      ;anzahl tasten
        jsr b5      ;farben retten
        jsr c5      ;farbe waehrend und
        jsr c6      ;nach eingabe holen
        jsr c7      ;revers-modus
        jsr c8      ;mehrfarb-modus
        jsr b6      ;eingabefeld setzen
        jsr c9      ;abbruch-variable
        jsr ca      ;cursor-variable
;-------
:p3b    jsr d1      ;taste holen
        jsr d2      ;auswerten
        bcc p3b     ;schleife
;-------
        rts         ;ende der routine
;-------
:init   jsr chkdir  ;direktmodus ?
        ldy #$bf    ;puffer fuer bei
        lda #$00    ;bei der eingabe
:ia     sta tkey,y  ;erlaubte tasten
        dey         ;loeschen
        cpy #$ff
        bne ia
        ldy #$27    ;puffer fuer
:ib     sta ekey,y  ;abbruch-tasten
        dey         ;loeschen
        bpl ib
        jsr h6b     ;cursorzeile und
        stx ze      ;spalte als vorgabe
        sty sp      ;merken
:ic     ldy #$27    ;eingabepuffer
        lda #$20    ;mit space-zeichen
:id     sta ep,y    ;fuellen
        dey
        bpl id
        iny
        sty rf      ;reversflag loeschen
        sty rf+1
        sty mm      ;mehrfarbmodus aus
        sty bm      ;basic-modus
        sty $02
        rts
;-------
:a1     jsr chrgot  ;zeichen holen
        cmp #$3b    ;= semikolon ?
        bne a1a     ;nein
        jsr chrget  ;zeichen holen
        lda #$00    ;return-flag
        sta cr      ;loeschen
        beq a1b     ;weiter
:a1a    jsr h8      ;komma ?
        lda #$0d    ;return-flag setzen
        sta cr
:a1b    jsr getbyt  ;zahl holen
        cpx #$ff    ;=255 ?
        beq a1c     ;ja, ze uebernehmen
        cpx #$19    ;>24 ?
        bcs er0     ;ja, illegal quant.
        stx ze      ;zeile setzen
:a1c    rts
:er0    jmp illqua  ;illegal quantity
;-------
:a2     jsr h8      ;komma &
        jsr getbyt  ;zahl holen
        cpx #$ff    ;=255 ?
        beq a2a     ;ja, sp uebernehmen
        cpx #$28    ;>39 ?
        bcs er0     ;ja, illegal quant.
        stx sp      ;spalte setzen
:a2a    rts
;-------
:a3     jsr h8      ;komma &
        jsr getbyt  ;zahl holen
        txa         ;=0 ?
        beq er0     ;ja, illegal quant.
        clc         ;spaltenwert dazu-
        adc sp      ;addieren
        cmp #$29    ;>40
        bcs er0     ;ja, illegal quant.
        stx la      ;laenge setzen
        rts
;-------
:a4     jsr h8      ;komma holen
        jsr frmevl  ;string einlesen
        jsr frestr  ;stringdaten holen
        cmp #$00    ;laenge=0 ?
        bne a4c     ;nein
:a4a    ldx #$00    ;alle tasten erlaubt
        ldy #$20
:a4b    tya
        sta tkey,x  ;codes von $20-$7f
        ora #$80    ;codes von $a0-$ff
        sta tkey+$60,x
        iny
        inx
        cpx #$60
        bne a4b
        ldx #$bf    ;insgesammt 192
        stx ts      ;tasten moeglich
        rts
:a4c    sta $64     ;anzahl merken
        ldy #$00
        ldx #$00
:a4d    lda ($22),y ;zeichen holen
        cmp #$01    ;=ctrl+a ?
        beq a4a     ;ja, alle tasten
        cmp #$0b    ;=ctrl+k ?
        bne a4f     ;nein
        sty varb
        ldy #$41    ;alle tastencodes
:a4e    tya         ;von $41-$5a erlaubt
        jsr a4l     ;zeichen in puffer
        cpy #$5b    ;schreiben
        bne a4e
        ldy varb
        iny         ;weiter mit
        jmp a4k     ;naechstem zeichen
:a4f    cmp #$07    ;=ctrl+g ?
        bne a4h     ;nein
        sty varb
        ldy #$c1    ;alle tastencodes
:a4g    tya         ;von $c1-$db erlaubt
        jsr a4l     ;zeichen in puffer
        cpy #$db    ;schreiben
        bne a4g
        ldy varb
        iny         ;weiter mit
        jmp a4k     ;naechstem zeichen
:a4h    cmp #$1a    ;=ctrl+z ?
        bne a4j     ;nein
        sty varb
        ldy #$30    ;alle zahlencodes
:a4i    tya         ;von $30-$39 erlaubt
        jsr a4l     ;zeichen in puffer
        cpy #$3a    ;schreiben
        bne a4i
        ldy varb
        iny         ;weiter mit
        jmp a4k     ;naechstem zeichen
:a4j    jsr a4l     ;zeichen in puffer
:a4k    cpy $64     ;schon alle zeichen?
        bne a4d     ;nein
        dex         ;anzahl-1 merken
        stx ts
        rts
:a4l    jsr h2      ;zeichen erlaubt ?
        bcc a4m     ;nein
        jsr b4b     ;zeichen vorhanden ?
        bcs a4m     ;ja
        sta tkey,x  ;alles ok
        inx         ;zeichen in puffer
:a4m    iny         ;naechstes zeichen
        rts
;-------
:a5     jsr h8      ;komma ?
        jsr fndvar  ;variablensyntax
        jsr chkstr  ;stringvariable ?
        lda $47     ;adresse low
        ldx $48     ;und high
        sta zs+0    ;merken
        stx zs+1
        rts
;-------
:a6     jsr h8      ;komma ?
        jsr frmevl  ;string holen
        jsr frestr  ;stringdaten holen
        cmp #$00    ;laenge=0 ?
        bne a6c     ;nein
:a6a    ldy #$27    ;vorgabe fuer
:a6b    lda endkey,y
        sta ekey,y  ;abbruch-tasten in
        dey         ;puffer schreiben
        bpl a6b
        rts
:a6c    sta $61     ;anzahl merken
        ldy #$00
        ldx #$00
:a6d    lda ($22),y ;zeichen holen
        sty vara
        ldy #$1f    ;pruefen, ob taste
:a6e    cmp efkey,y ;editorfunktion hat
        beq a6f     ;wenn ja, dann
        dey         ;uberspringen
        bpl a6e
        sta ekey,x  ;taste erlaubt
        inx         ;und speichern
:a6f    ldy vara
        iny
        cpx #$27    ;puffer voll ?
        beq a6g     ;ja, ende
        cpy $61     ;weiter mit
        bne a6d     ;naechstem zeichen
:a6g    cpx #$00    ;keine gueltige
        beq a6a     ;taste? dann vorgabe
        rts
;-------
:a7     jsr h8      ;komma ?
        jsr frmevl  ;parameter holen
        lda $0d     ;typ als vorgabe
        sta vo
        bne a7b     ;string, weiter
        jsr facint  ;zahl in akku
        cmp #$00    ;>2 ?
        bne er1     ;ja, illegal quant.
        cpy #$02
        bcs er1     ;ja, illegal quant.
:a7a    sty vo      ;vorgabe setzen
        rts
:a7b    jsr frestr  ;stringdaten holen
        sta vo+1    ;laenge
        stx vo+2    ;adresse low- und
        sty vo+3    ;high merken
        tay         ;laenge=0 ?
        beq a7a     ;ja, keine vorgabe
        rts
:er1    jmp illqua  ;illegal quantity
;-------
:b1     jsr h6      ;cursor setzen
        lda #$00    ;cursorposition
        stx $71     ;auf bildschirm und
        sta $72     ;farbram berechnen
        lda #$28    ;zeile mit 40
        ldy #$00    ;multiplizieren
        sta $28
        sty $29
        jsr umult
        stx $f7     ;in vektor $f7/$f8
        sty $f8     ;speichern
        lda $0288   ;startadresse
        sta vara    ;bildschirmspeicher
        sec         ;ermitteln
        lda #$d8
        sbc $0288
        sta varb
        clc         ;spaltenposition
        lda $f7     ;dazuaddieren
        adc sp
        sta $f7
        sta $f9
        lda $f8     ;startadresse
        adc vara    ;bildschirm
        sta $f8     ;dazuaddieren
        clc         ;startadresse im
        adc varb    ;farbram berechnen
        sta $fa     ;(vektor $f9/$fa)

        lda vo      ;vorgabe >0 ?
        bne b1b     ;ja
        jmp bb      ;leeres eingabefeld
:b1b    bmi b1c     ;=255 ? ja, string
        lda la      ;vorgabe vom
        ldx #<b2    ;bildschirm, adresse
        ldy #>b2    ;routine 'getchar'
        jmp b1e     ;zur hauptroutine
:b1c    lda vo+1    ;string als vorgabe
        ldx vo+2
        ldy vo+3
:b1d    stx $22
        sty $23
        ldx #<b3
        ldy #>b3
:b1e    sta $61     ;laenge der vorgabe
        stx b4+1    ;adresse routine
        sty b4+2    ;'getchar'
        ldy #$00    ;modifizieren
        sty $62
        sty $63
:b1f    cpy $61     ;laenge erreicht ?
        beq b1i     ;ja
:b1g    jsr b4      ;zeichen holen
        bcc b1h     ;erlaubt ? nein
        ldy $63     ;ja, dann in
        sta ep,y    ;eingabefeld
        inc $63     ;schreiben
        ldy $63
        cpy la      ;feld voll ?
        beq b1j     ;ja, ende
:b1h    inc $62     ;zeichenzaehler
        ldy $62     ;erhoehen
        cpy $61     ;alle zeichen ?
        bne b1g     ;nein
:b1i    cpy la      ;eingabefeld voll ?
        beq b1j     ;ja, weiter
        lda #$20    ;rest mit space
        sta ep,y    ;fuellen
        iny
        jmp b1i
:b1j    jmp bb      ;ef auf bildschirm
;-------
:b2     lda ($f7),y ;zeichen vom bild-
        jmp sub2    ;schirm, nach ascii
;-------
:b3     lda ($22),y ;zeichen aus string
        rts
;-------
:b4     jsr $ffff   ;zeichen holen
                    ;sprung nach b2/b3
:b4a    jsr h4      ;code bearbeiten
        cmp #$a0    ;shift-space in
        bne b4b     ;space wandeln
        lda #$20
:b4b    stx vara
        ldx ts      ;zeichen erlaubt ?
:b4c    cmp tkey,x
        beq b4d     ;ja
        dex
        cpx #$ff
        bne b4c
        ldx vara    ;zeichen ist nicht
        clc         ;erlaubt
        rts
:b4d    ldx vara    ;zeichen erlaubt
        sec
        rts
;-------
:b5     ldy la      ;farben an position
        dey         ;des eingabefeldes
:b5a    lda ($f9),y ;merken
        sta fw,y    ;gueltig, wenn fw
        sta fn,y    ;oder fn = 255
        dey
        bpl b5a
        rts
;-------
:b6     ldy la      ;eingabefeld
        dey         ;auf dem bildschirm
:b6a    lda ($f7),y ;invertiern oder
        jsr b7      ;in mehrfarbmodus
        sta ($f7),y ;wandeln
        dey
        bpl b6a
        rts
;-------
:b7     stx vara    ;waehrend eingabe
        ldx mm      ;mehrfarbmodus ein?
        bne b7a     ;ja, weiter
        and #$7f    ;bits 0-6 isolieren
        ora rf      ;und invertieren
        jmp b7b
:b7a    and #$3f    ;nach multicolor
        ora cm      ;farbe setzen
:b7b    ldx vara
        rts
;-------
:b8     stx vara    ;nach eingabe
        ldx mm      ;mehrfarbmodus ein?
        bne b8a     ;ja, weiter
        and #$7f    ;bits 0-6 isolieren
        ora rf+1    ;und invertieren
        jmp b8b
:b8a    and #$3f    ;nach multicolor
        ora cm      ;farbe setzen
:b8b    ldx vara
        rts
;-------
:b9     ldy #$00    ;ef. komprimieren
:b9a    cpy po      ;weiter komprimieren
        beq b9c     ;nein, abbruch
        lda ep,y    ;zeichen holen
        cmp #$20    ;=leerfeldcode ?
        bne b9b
        jsr b4b     ;zeichen erlaubt ?
        bcs b9b     ;ja, weiter
        tya         ;pointer ein zeichen
        pha         ;weiter setzen
        iny
        jsr e4b     ;zeichen loeschen
        pla         ;text von rechts
        tay         ;nachschieben
        dec po      ;anzahl zeichen -1
        jmp b9a     ;naechstes zeichen
:b9b    iny         ;weiter mit
        jmp b9a     ;naechstem zeichen
:b9c    rts
;-------
:ba     pha         ;eingabefeld bis
        jsr b9      ;cursor komprimieren
:baa    lda ep,y    ;komprimiertes
        jsr h5      ;eingabefeld auf
        jsr b7      ;bildschirm bringen
        sta ($f7),y
        dey
        bpl baa
        pla         ;akku zurueckholen
        rts         ;ruecksprung
;-------
:bb     ldy la      ;eingabefeld
        dey         ;durch linie
:bba    lda ep,y    ;markieren
        cmp #$20
        bne bbb
        lda k4
        jsr b7      ;invertieren
        sta ($f7),y ;auf bildschirm
        dey         ;gesammtes feld
        bpl bba     ;auf bildschirm ?
        rts         ;ja, ende
:bbb    lda ep,y    ;zeichen holen
        jsr h5      ;verstecken und
        jsr b7      ;invertieren
        sta ($f7),y ;auf bildschirm
        dey         ;schon alle
        bpl bbb     ;zeichen ?
        rts         ;ja, ende
;-------
:c1     jsr h7      ;parameter-test
        bne c1a     ;parameter vorhanden
        ldx last+0  ;wenn nicht, dann
        jmp c1b     ;aus puffer
:c1a    jsr getbyt  ;zahl holen
:c1b    cpx #$02    ;>2 ?
        bcs er2     ;ja, illegal quant.
        stx last+0  ;parameter merken
        stx fm      ;modus setzen
        lda k2      ;leerfeldcode
        cpx #$01    ;erzeugen
        bne c1c
        lda k1
:c1c    sta k4      ;und merken
        rts
:er2    jmp illqua  ;illegal quantity
;-------
:c2     jsr h7      ;parameter-test
        bne c2a     ;parameter vorhanden
        ldx last+1  ;wenn nicht, dann
        jmp c2b     ;aus puffer
:c2a    jsr getbyt  ;zahl holen
:c2b    cpx #$02    ;>2 ?
        bcs er2     ;ja, illegal quant.
        stx last+1  ;parameter merken
        stx hm      ;modus setzen
        rts
;-------
:c3     jsr h7      ;parameter-test
        bne c3a     ;parameter vorhanden
        ldx last+2  ;wenn nicht, dann
        jmp c3b     ;aus puffer
:c3a    jsr getbyt  ;zahl holen
:c3b    cpx #$00    ;=0 ?
        beq er2     ;ja, illegal quant.
        cpx #$ff    ;=255 ?
        beq c3c     ;ja, weiter
        dex         ;mit laenge
        cpx la      ;vergleichen.
        bcs er2     ;zu gross, fehler
        stx po      ;position merken
        inx
        stx last+2  ;und in puffer
        rts
:c3c    stx last+2
        ldy la      ;letztes zeichen
        dey         ;im eingabefeld
:c3d    lda ep,y    ;ermitteln und
        cmp #$20    ;cursor direkt
        bne c3e     ;dahinter setzen
        dey
        bpl c3d
:c3e    iny
        cpy la      ;letztes zeichen
        bne c3f     ;= feldende ?
        dey         ;ja, dann auf
:c3f    sty po      ;letztes zeichen
        rts
;-------
:c4     jsr h7      ;parameter-test
        bne c4a     ;parameter vorhanden
        ldx last+3  ;wenn nicht, dann
        jmp c4b     ;aus puffer
:c4a    jsr getbyt  ;zahl holen
:c4b    cpx #$00    ;=0 ?
        beq c4c     ;ja, keine tasten
        dex         ;max. anzahl auf
        cpx la      ;feldlaenge
        bcs er2     ;begrenzen
        inx
:c4c    stx last+3  ;und merken
        stx an      ;anzahl setzen
        rts
;-------
:c5     jsr h7      ;parameter-test
        bne c5a     ;parameter vorhanden
        ldx last+4  ;wenn nicht, dann
        jmp c5b     ;aus puffer
:c5a    jsr getbyt  ;zahl holen
:c5b    cpx #$ff    ;=255 ?
        beq c5d     ;ja, weiter
        cpx #$10    ;>15 ?
        bcs er3     ;ja, illegal quant.
        txa         ;farbpuffer mit
        ldy la      ;farbcode fuellen
        dey
:c5c    sta ($f9),y
        sta fw,y
        dey
        bpl c5c
:c5d    stx last+4  ;farbe merken
        rts
:er3    jmp illqua  ;illegal quantity
;-------
:c6     jsr h7      ;parameter-test
        bne c6a     ;parameter vorhanden
        ldx last+5  ;wenn nicht, dann
        jmp c6b     ;aus puffer
:c6a    jsr getbyt  ;zahl holen
:c6b    cpx #$ff    ;=255 ?
        beq c6d     ;ja, weiter
        cpx #$10    ;>15 ?
        bcs er3     ;ja, illegal quantity
        txa         ;farbpuffer mit
        ldy la      ;farbcode fuellen
        dey
:c6c    sta fn,y
        dey
        bpl c6c
:c6d    stx last+5  ;farbe merken
        rts
;-------
:c7     jsr h7      ;parameter-test
        bne c7a     ;parameter vorhanden
        ldx last+6  ;wenn nicht, dann
        jmp c7b     ;aus puffer
:c7a    jsr getbyt  ;zahl holen
:c7b    cpx #$04    ;>3 ?
        bcs er3     ;ja, illegal quant.
        stx last+6  ;modus merken
        txa         ;modi fuer waehrend
        ror         ;und nach der
        ror rf      ;eingabe setzen
        ror
        ror rf+1
        rts
;-------
:c8     jsr h7      ;parameter-test
        bne c8a     ;parameter vorhanden
        ldx last+7  ;wenn nicht, dann
        jmp c8b     ;aus puffer
:c8a    jsr getbyt  ;zahl holen
:c8b    cpx #$05    ;>4 ?
        bcs er4     ;ja, illegal quant.
        stx last+7  ;modus merken
        lda vic17   ;modus einschalten
        and #$bf    ;wenn mm<>0
        cpx #$00
        beq c8c
        ora #$40
:c8c    sta vic17   ;register setzen
        stx mm      ;mm setzen
        dex         ;farbcode
        txa         ;definieren
        lsr         ;und merken
        ror
        ror
        sta cm
        rts
:er4    jmp illqua  ;illegal quantity
;-------
:c9     jsr h7      ;parameter-test
        bne c9a     ;parameter vorhanden
        lda last+8  ;wenn nicht, dann
        ldx last+9  ;aus puffer
        jmp c9b
:c9a    jsr fndvar  ;variable pruefen
        jsr chknum  ;numerische var. ?
        lda $45     ;namen merken
        ldx $46
:c9b    sta last+8
        stx last+9
        sta ev      ;namen setzen
        stx ev+1
        rts
;-------
:ca     jsr h7      ;parameter-test
        bne caa     ;parameter vorhanden
        lda last+10 ;wenn nicht, dann
        ldx last+11 ;aus puffer
        jmp cab
:caa    jsr fndvar  ;variable pruefen
        jsr chknum  ;numerische var. ?
        lda $45     ;namen merken
        ldx $46
:cab    sta last+10
        stx last+11
        sta cv
        stx cv+1
        rts
;-------
:d1     clc         ;zeichen von
        lda po      ;tastatur holen
        adc sp
        tay
        jsr h6a
        ldy po      ;cursor auf farbe
        lda fw,y    ;an position des
        sta color   ;ef setzen
        lsr $cc     ;cursor einschalten
        lsr $cc
:d1a    jsr getin   ;warten auf taste
        beq d1a
        ldx $91     ;stop gedrueckt ?
        cpx #$7f
        beq d1a     ;ja, ignorieren
        pha         ;taste merken
        inc $cc     ;cursor abschalten
        ldx #$00
        stx $cf
        inx
        stx $cd
        ldy $d3     ;zeichen am bild-
        lda ($d1),y ;schirm normal-
        jsr b7      ;isieren
        sta ($d1),y
        ldy po      ;farbe setzen
        lda fw,y
        sta ($f9),y
        pla         ;taste wieder
        rts         ;holen und ende
;-------
:d2     ldy #$1f    ;pruefen, ob
:d2a    cmp efkey,y ;gedrueckte taste
        beq d2b     ;editorfunktion hat
        dey
        bpl d2a
        jmp d3      ;nein, weiter
:d2b    tya         ;funktion aufrufen
        asl         ;dazu adresse
        tay         ;nach vektor $55/$56
        lda efadr,y
        sta $55
        lda efadr+1,y
        sta $56
        ldy #$ff    ;nr. fuer shft/ret
        jmp ($0055) ;sprung zur funktion
;-------
:d3     ldy #$27    ;gedrueckte taste=
:d3a    cmp ekey,y  ;abbruchtaste ?
        beq d4      ;ja, weiter
        dey
        bpl d3a     ;normales zeichen
        jsr b4b     ;taste erlaubt ?
        bcc d3b     ;nein, weiter
        jsr ba      ;ef komprimieren
        jsr h4      ;code bearbeiten
        ldy po      ;in eingabepuffer
        sta ep,y    ;schreiben
        jsr h5      ;taste verstecken
        jsr b7      ;und invertieren
        sta ($f7),y ;auf bildschirm
        iny         ;cursor nach rects
        cpy la      ;>laenge ?
        beq d3b     ;ja, nicht aendern
        sty po      ;neue pos merken
:d3b    clc         ;weiter mit eingabe
        rts
;-------
:d4     iny         ;nummer der abbruch-
        sty $05     ;taste merken
        ldx la      ;ganzes eingabefeld
        dex         ;komprimieren
        stx po
        jsr b9      ;ef komprimieren
        ldy la      ;anzahl eingegebener
        dey         ;zeichen ermitteln
:d4a    lda ep,y
        cmp #$20
        bne d4b
        dey
        bpl d4a
:d4b    iny         ;genuegend zeichen ?
        cpy an
        beq d4c     ;ja, weiter
        bcs d4c
        jmp sub1    ;nein, fehler
:d4c    sty po      ;anzahl merken
        ldy la      ;leercodes am ende
        dey         ;des ef in space
:d4d    lda ep,y    ;wandeln
        cmp #$20
        bne d4e
        lda k3
        jsr b8      ;invertieren
        sta ($f7),y ;auf bildschirm
        lda fn,y    ;und farbzustand
        sta ($f9),y ;setzen
        dey
        bpl d4d
        bmi d4f
:d4e    lda ep,y    ;text evtl.
        jsr h5      ;versteckenund
        jsr b8      ;invertieren und
        sta ($f7),y ;auf bildschirm
        lda fn,y    ;farbwerte setzen
        sta ($f9),y
        dey         ;bis anfang
        bpl d4e     ;eingabefeld
:d4f    lda po      ;laenge des strings
        ldx $05     ;bei shift/ret
        bne d4g     ;ganzes feld
        lda la
:d4g    ldx em      ;oder wenn em = 1
        beq d4h     ;ganzes feld
        lda la
:d4h    ldy bm      ;basic/msp-modus
        bne d5
        ldx zs      ;adresse ziel-
        ldy zs+1    ;variable holen
        stx $47     ;und speichern
        sty $48
        jsr strpoi  ;reservieren
        ldy #$02    ;adresse in string-
:d4i    lda $0061,y ;pointer schreiben
        sta ($47),y
        dey
        bpl d4i
        tay         ;keine eingabe ?
        dey         ;ja, dann weiter
        bmi d4k
:d4j    lda ep,y    ;eingabe in re-
        sta ($62),y ;servierten bereich
        dey         ;kopieren
        bpl d4j
:d4k    lda ev      ;name der abbruch-
        ldx ev+1    ;variablen holen
        jsr h1      ;und wert speichern
        jsr h6b     ;cursor-pos holen
        tya
        sec
        sbc sp
        tay
        iny
        sty $05     ;spaltenwert merken
        lda cv      ;name der cursor-
        ldx cv+1    ;variablen holen
        jsr h1      ;und wert speichern
:d4l    lda cr      ;return-flag
        jsr bsout   ;ausgeben
        sec         ;programm beenden
        rts
;-------
:d5     ldx #<ep    ;daten an assembler-
        ldy #>ep    ;programm uebergeben.
        sta $02     ;laenge der eingabe
        stx $03     ;adresse im low- und
        sty $04     ;high-byte format
        jsr h6b     ;cursor-pos holen
        tya
        sec
        sbc sp
        tay
        iny
        sty $06     ;spaltenwert merken
        jmp d4l     ;sonst wie basic
;-------
;funktionen zu editortasten
;-------
:e1     ldy la      ;clr/home
        dey         ;ef loeschen
:e1a    lda k4
        jsr b7
        sta ($f7),y
        lda #$20
        sta ep,y
        dey
        bpl e1a
;-------
:e2     jsr h6      ;home
        lda #$00    ;cursor auf anfang
        sta po      ;des eingabefeldes
        clc         ;setzen
        rts
;-------
:e3     jsr h6b     ;cursor um ein
        iny         ;zeichen nach
        tya         ;rechts bewegen.
        sec
        sbc sp
        cmp la      ;schon am rechten
        bne e3a     ;rand ?
        jmp sub1    ;ja, warnton
:e3a    jsr plot
        inc po
        clc
        rts
;-------
:e4     jsr h6b     ;delete
        cpy sp      ;schon am linken
        bne e4a     ;rand ?
        jmp sub1    ;ja, warnton
:e4a    ldy po      ;zeichen links vom
        jsr e4b
        jmp e5
:e4b    lda ($f7),y ;cursor loeschen
        tax         ;und text rechts vom
        lda ep,y    ;cursor verschieben
        dey
        sta ep,y
        txa
        sta ($f7),y
        iny
        iny
        cpy la
        bne e4b
        dey
        lda k4      ;am ende des ef
        jsr b7      ;leercode einfuegen
        sta ($f7),y
        lda #$20    ;space ans ende des
        sta ep,y    ;eingabepuffers
        rts
;-------
:e5     jsr h6b     ;cursor um ein
        cpy sp      ;zeichen nach links
        bne e5a     ;am linken rand ?
        jmp sub1    ;ja, warnton
:e5a    dey
        jsr plot
        dec po
        clc
        rts
;-------
:e6     jsr h6b     ;insert
        tya         ;zeichen an cursor-
        sec         ;position einfuegen
        sbc sp
        tay
        iny
        cpy la      ;am rechten rand ?
        bne e6a     ;nein, weiter
        dey         ;letztes zeichen
        lda k4      ;loeschen
        jsr b7
        sta ($f7),y
        lda #$20
        sta ep,y
        clc
        rts
:e6a    ldy la      ;text rechts vom
        dey         ;cursor verschieben
:e6b    dey
        lda ($f7),y
        tax
        lda ep,y
        iny
        sta ep,y
        txa
        sta ($f7),y
        dey
        bmi e6c
        cpy po
        bcs e6b
:e6c    iny         ;und luecke mit
        lda k4      ;mit leercode
        jsr b7      ;fuellen
        sta ($f7),y
        lda #$20
        sta ep,y
        clc
        rts
;-------
:e7     ldx bm      ;f8
        beq e7a     ;text in eingabe-
        lda zs      ;feld uebergeben.
        ldx zs+1
        ldy zs+2
        jmp e7b
:e7a    dex         ;basic-modus
        stx $0d
        lda zs      ;zielvariable suchen
        ldx zs+1
        sta $64
        stx $65
        jsr frestr  ;stringdaten holen
:e7b    cmp #$00    ;laenge=0 ?
        bne e7c     ;nein, weiter
        jmp e1      ;ja, ef loeschen
:e7c    jsr b1d     ;text uebergeben
        jsr b6
        clc
        rts
;-------
;diverse unterprogramme
;-------
:h1     sta $45     ;wert einer
        stx $46     ;variablen zuweisen
        jsr putvar  ;variable suchen
        sta $49     ;adresse merken
        sty $4a
        lda $46     ;vorbereitung
        and #$80    ;zum aufruf der
        pha         ;betriebssystem-
        lda #$00    ;routine 'let var='
        pha
        ldy $05     ;uebergabewert holen
        bmi h1a
        lda #$00
        b $2c
:h1a    lda #$ff    ;nach flieskomma
        jsr intfac  ;wandeln
        jmp let     ;let-funktion
;-------
:h2     cmp #$20    ;taste im
        bcc h2a     ;erlaubten bereich
        cmp #$80    ;$20-$7f,$a0-$ff
        bcc h2b
        cmp #$a0
        bcs h2b
:h2a    clc
        rts
:h2b    sec
        rts
;-------
:h3     jsr h4      ;zeichen pruefen
        jsr b4b     ;und in eingabe-
        bcc h3a     ;puffer schreiben
        sta ep,x
        inx
:h3a    rts
;-------
:h4     stx varb    ;zeichen auf
        ldx fm      ;feld-code testen
        beq h4a
        jsr sub3    ;in bildscirmcode
        cmp k1      ;uebereinstimmung
        bne h4b
        lda #$20    ;in space wandeln
:h4b    jsr sub2    ;in ascii-code
:h4a    ldx varb
        rts
;-------
:h5     stx varb    ;zeichen
        jsr sub3    ;verstecken
        ldx hm
        beq h5a
        lda k0
:h5a    ldx varb
        rts
;-------
:h6     ldy sp      ;cursor setzen
:h6a    ldx ze      ;zeile/spalte
        jsr plot
:h6b    jsr getpos  ;cursor-pos holen
        cpy #$28    ;zeile > 40 ?
        bcc h6c
        tya         ;ja, 40 abziehen
        sec         ;um verlaengerte
        sbc #$28    ;bildschirmzeile
        tay         ;auszuschliessen
:h6c    rts
;-------
:h7     inc $02
        jsr chrgot  ;zeichen holen
        beq h7a
        jsr chkcom  ;komma ?
        beq h7a
        cmp #$2c    ;carry- und zero-
:h7a    rts         ;flag setzen
:h7b    lda #$00    ;routine fuer
        rts         ;deaktiven parameter
;-------
:h8     inc $02     ;fehlerbyte erhoehen
        jmp chkcom  ;und komma holen
;-------
;von basic aus aufrufbare
;unterprogramme
;-------
:sub1   jsr sub1f
:sub1a  lda #$9c    ;frequenz low
        ldx #$48    ;frequenz high
        ldy #$00    ;pulsweite
        sta $d400
        stx $d401
        sty $d402
        lda #$08    ;pulsweite
        ldx #$41    ;wellenform
        ldy #$0a    ;huellkurve
        sta $d403
        stx $d404
        sty $d405
        lda #$64    ;huellkurve
        sta $d406
        ldx #$00    ;ton starten
        ldy #$00
:sub1b  iny
        bne sub1b
        stx $d418
        inx
        cpx #$10
        bne sub1b
        ldx #$40    ;tonlaenge
        stx $02
:sub1c  dex
        bne sub1c
        dec $02
        beq sub1d
        ldx #$ff
        jmp sub1c
:sub1d  ldx #$03  ;ton beenden
        ldy #$00
:sub1e  iny
        bne sub1e
        stx $d418
        dex
        bpl sub1e
:sub1f  ldy #$18    ;warnton ausgeben
        lda #$00    ;sid-register
:sub1g  sta $d400,y ;loeschen
        dey
        bpl sub1g
        clc
        rts
;-------
:sub2   and #$7f    ;bc nach ascii
        cmp #$20    ;wandeln
        bcc sub2b
        cmp #$40
        bcc sub2a
        cmp #$60
        bcc sub2c
        adc #$3f
:sub2a  rts
:sub2b  ora #$40
        rts
:sub2c  ora #$20
        rts
;-------
:sub3   sty vara    ;ascii nach bc
        tay         ;wandeln
        sec
        sbc #$a1
        cpy #$ff
        bcs sub3a
        adc #$21
:sub3a  cpy #$c0
        bcs sub3b
        adc #$40
:sub3b  cpy #$a0
        bcs sub3c
        adc #$20
:sub3c  cpy #$60
        bcs sub3d
        sec
        sbc #$20
:sub3d  cpy #$40
        bcs sub3e
        adc #$40
:sub3e  ldy vara
        rts
;-------
;speicher fuer parameter
;-------
:endkey             ;vorgabe fuer
b $0d,$8d,$11,$91   ;abbruch-tasten
b $85,$86,$87,$88
b $89,$8a,$8b,$00
s $1c
;-------
:efkey              ;codes der editor
b $93,$13,$1d,$14   ;tasten
b $9d,$94,$8c,$8d
s $18
:efadr              ;sprungadressen
w e1,e2,e3,e4       ;fuer editor-tasten
w e5,e6,e7,d4
s $30
;-------
:k0   b $23         ;hidecode
:k1   b $64         ;feldcode
:k2   b $20         ;leerfeldcode
:k3   b $20
:k4   b $00         ;fuellcode
:bm   b $00         ;basic/assembler
:em   b $00         ;end-stringlaenge
:cr   b $0d         ;return-flag
:vara b $00         ;zwischenspeicher
:varb b $00
;-------
:ep   s $28         ;eingabepuffer
;-------
:fw   s $28         ;farbpuffer waehrend
:fn   s $28         ;nach eingabe
;-------
:fm   b $00         ;feld-modus
:hm   b $00         ;hidemodus
:po   b $00         ;cursorposition
:an   b $00         ;anzahl tasten
:rf   b $00,$00     ;rever-smodus
:mm   b $00         ;mehrfarb-modus
:cm   b $00         ;farbcode
:ev   b $00,$00     ;name endvariable
:cv   b $00,$00     ;name cursorvar.
;-------
:tkey s $c0         ;erlaubte tasten
:ekey s $28         ;abbruch-tasten
;-------
:ze   b $00         ;zeile
:sp   b $00         ;spalte
:la   b $00         ;laenge
:ts   b $00         ;anzahl tasten
:zs   b $00,$00,$00 ;name zielvariable
                    ;assembler: anzahl
                    ;und adresse des
                    ;strings der bei
                    ;f8 uebergeben wird
:vo   b $00         ;art der vorgabe
      b $00,$00,$00 ;anzahl und adresse
                    ;des vorgabestrings
;-------
:last               ;speicher fuer
b $01,$00,$01,$00   ;optionale parameter
b $ff,$ff,$01,$00   ;(fm,hm,po,an,fw,fn,
b "evcv"            ;rf,mm,ev,cv)
;-------
b "input de luxe v4.3"
b "written 1990 by : m. kanet"
b "stand : 29.09.90 / 13.34"
s $66               ;platz fuer spaetere
                    ;modifikationen
;-------
        brk         ;ende bei $1500 !
;-------
 