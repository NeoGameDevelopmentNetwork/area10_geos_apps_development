; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; HD-ZIP(al).ass - Written by AL(?)
;
; AddOn for HD-ZIP(al).bas for C64/C128 which can be used to
; set a new SCSI device for the CMD-HD.
;
; Additional comments by Markus Kanet
; Version: V1.00 02/07/2020
;

                        ORG     $4000

:newSCSIDevice          JSR     initROMAdr
                        JSR     setSCSIdev
:call_E53D              JMP     $0000                   ;$e53d

:exitConfMode           JSR     initROMAdr

:call_D1BA              JSR     $0000                   ;$d1ba

                        JSR     setSCSIdev
                        BCS     initSysHD               ; => Fehler.

:call_DCB6              JSR     $0000                   ;$dcb6
                        BCS     initSysHD               ; => Fehler.

:call_D09F              JMP     $0000                   ;$d09f

;*** Fehler: CMD-HD neu initialisieren.
:initSysHD
:call_D25E              JSR     $0000                   ;$d25e

                        LDA     #$78
                        JMP     $FF1B

;*** SCSI-Gerät aktivieren.
:setSCSIdev             LDA     #$01
                        STA     $30AA
                        LDA     #$05                    ;SCSI-Geräte-ID.
:call_D10E              JMP     $0000                   ;$d10e

;*** Adresstabelle suchen.
:initROMAdr             LDX     #$00
                        LDY     #$00
                        LDA     #$C0
                        STA     :romRdAdr1 +2
::romRdAdr1             LDA     $C000,Y
                        CMP     romCode1,X
                        BEQ     :11
                        LDX     #$00
::10                    INY
                        BNE     :romRdAdr1
                        INC     :romRdAdr1 +2
                        BNE     :romRdAdr1
                        JMP     call_D25E

::11                    INX
                        CPX     #11
                        BCC     :10

                        SEC                             ;Zeiger auf Adressen-
                        TYA                             ;tabelle berechnen.
                        SBC     #<10
                        STA     romAdrBuf +0
                        LDA     :romRdAdr1 +2
                        SBC     #>10
                        STA     romAdrBuf +1

                        LDA     romAdrBuf +0            ;Zeiger auf Tabelle
                        STA     $F8                     ;einlesen.
                        LDA     romAdrBuf +1
                        STA     $F9

                        LDY     #$1F                    ;Zeiger auf letzte
                        CLC                             ;Adresse $e539 in der
                        LDA     ($F8),Y                 ;Tabelle=Befehl "H".
                        ADC     #$01+3                  ;Rücksprung -1 und
                        STA     call_E53D +1            ;3-Byte-Befehl
                        INY                             ;überspringen.
                        LDA     ($F8),Y
                        PHA
                        ADC     #$00
                        STA     call_E53D +2            ; => $e53d.
                        DEY
                        LDA     ($F8),Y
                        STA     $F8                     ;Zeiger auf $e539!
                        PLA
                        STA     $F9

                        LDY     #$02                    ;E53A JSR $D107
                        LDA     ($F8),Y                 ;Adresse $D107
                        CLC                             ;einlesen und auf
                        ADC     #$07                    ;Adresse $D107+$07
                        STA     call_D10E +1            ;= $D10E korrigieren.
                        INY
                        LDA     ($F8),Y
                        ADC     #$00
                        STA     call_D10E +2

                        LDX     #$00
                        LDY     #$00
                        LDA     #$C0
                        STA     :romRdAdr2 +2
::romRdAdr2             LDA     $C000,Y
                        CMP     romCode2,X
                        BEQ     :21
                        LDX     #$00
::20                    INY
                        BNE     :romRdAdr2
                        INC     :romRdAdr2 +2
                        BNE     :romRdAdr2
                        JMP     call_D25E

::21                    INX
                        CPX     #$0A
                        BCC     :20

                        STY     $F8                     ;Zeiger auf ROM-Code
                        LDA     :romRdAdr2 +2           ;(Adr. JMP-Befehl)
                        STA     $F9

                        LDY     #$01                    ;Adresse des
                        LDA     ($F8),Y                 ;JMP-Befehls lesen
                        PHA                             ; => $D09C
                        CLC                             ;Adresse korrigieren:
                        ADC     #$03                    ; => $D09F
                        STA     call_D09F +1
                        INY
                        LDA     ($F8),Y
                        STA     $F9
                        ADC     #$00
                        STA     call_D09F +2
                        PLA                             ;Zeiger auf Routine
                        STA     $F8                     ;bei $D09C.

                        LDY     #$11                    ;Adresse JSR-Befehl
                        LDA     ($F8),Y                 ;bei $D09C+$11
                        STA     call_D25E +1            ;einlesen:
                        INY                             ;D0AC JSR $D25E
                        LDA     ($F8),Y
                        STA     call_D25E +2

                        LDY     #$01                    ;Adresse JSR-Befehl
                        LDA     ($F8),Y                 ;bei $D09C+$01
                        PHA                             ;einlesen:
                        INY                             ;D09C JSR $D0B4
                        LDA     ($F8),Y
                        STA     $F9
                        PLA                             ;Zeiger auf Routine
                        STA     $F8                     ;bei $D0B4.

                        LDY     #$01                    ;Adresse JSR-Befehl
                        LDA     ($F8),Y                 ;bei $D0B4+$01
                        STA     call_D1BA +1            ;einlesen:
                        INY                             ;D0B4 JSR $D1BA
                        LDA     ($F8),Y
                        STA     call_D1BA +2

                        LDY     #$09                    ;Adresse JSR-Befehl
                        LDA     ($F8),Y                 ;bei $D0B4+$09
                        STA     call_DCB6 +1            ;einlesen:
                        INY                             ;D0BC JSR $DCB6
                        LDA     ($F8),Y
                        STA     call_DCB6 +2

                        RTS

;*** Befehlszeichen ab $E4A8.
;Die Bytes befinden sich im BootROM.
;Im Anschluss an die Bytes findet sich
;eine dazugehörige Tabelle mit den
;Adressen der Befehle.
;Die Adressen werden auf dem Stack
;abgelegt und entsprechen daher dem
;Format: Rücksprungadresse -1
:romCode1               b $4E,$43,$49,$52
                        b $57,$50,$44,$46
                        b $55,$53,$48

;*** ROM-Routine ab $DF2A
:romCode2               b $68,$c9,$08,$f0
                        b $0d,$c9,$06,$f0
                        b $0c,$4c

:romAdrBuf              w $0000                         ;$e4a8
