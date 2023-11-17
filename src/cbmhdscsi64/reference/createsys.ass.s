; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; createsys.ass - Written by C.M.D.
; Version: V1.12
;
; This code is attached to 'CREATE.SYS' and 'REWRITE DOS'.
;
; Additional comments by Markus Kanet
; Version: V1.00 02/08/2020
;

if .p
:UNLSN                  = $ffae                         ;Send UNLISTEN to IEC bus.
:CIOUT                  = $ffa8                         ;Send byte to IEC bus.
:LISTEN                 = $ffb1                         ;Send LISTEN to IEC bus.
:SECOND                 = $ff93                         ;Send secondary address.
endif

;*** Startadress CREATESYS.ASS/WRITEDOS.ASS
;This assembler code is attached to the
;CREATE.SYS/REWRITE.DOS basic program.
;
;The code is used to create hashes for
;system files and send sector data to the
;CMD-HD to be written on disk.
;
;The code is fully relocatable.

                        o       $xxxx

:sysml0                 clc                             ;REWRITE.DOS:
                        bcc     createHash              ; -> sys ml

:sysml3                 clc                             ;CREATE.SYS/REWRITE.DOS:
                        bcc     sendData                ; -> sys ml+3

;*** Create HASH.
;This assembler code is also used in
;REWRITE.DOS to create checksums.
:createHash             sei

                        lda     #$20

                        ldx     $fa                     ;C64/C128?
                        beq     :101                    ; -> C64, continue...

                        lda     #$3f                    ;Set MMU/C128.
                        sta     $ff00

                        lda     #$40

::101                   sta     $fc
                        lda     #$00
                        sta     $fb

                        tax
::102                   ldy     #$00
::103                   clc
                        adc     ($fb),Y
                        bcc     :104
                        inx
::104                   iny
                        bne     :103
                        inc     $fc

                        ldy     $fc
                        cpy     $af
                        bcc     :102

                        sta     $fb
                        stx     $fc

                        lda     $fa                     ;C64/C128?
                        beq     :105                    ; -> C64, continue...

                        lda     #$00                    ;Set MMU/C128.
                        sta     $ff00

::105                   cli
                        rts

;*** Send 32 Bytes to CMD-HD.
;Faster then BASIC code in CREATE.SYS
:sendData               lda     $ba
                        jsr     LISTEN
                        lda     #$6f
                        jsr     SECOND

                        lda     #"M"
                        jsr     CIOUT
                        lda     #"-"
                        jsr     CIOUT
                        lda     #"W"
                        jsr     CIOUT

                        lda     $fb
                        jsr     CIOUT
                        lda     #$03
                        jsr     CIOUT

                        lda     #$20
                        jsr     CIOUT

                        ldy     #$00

::201                   ldx     $fa                     ;C64/C128?
                        beq     :202                    ; -> C64, continue...

                        ldx     #$3f                    ;Set MMU/C128.
                        stx     $ff00

::202                   lda     ($fb),Y

                        ldx     $fa                     ;C64/C128?
                        beq     :203                    ; -> C64, continue...

                        ldx     #$00                    ;Set MMU/C128.
                        stx     $ff00

::203                   jsr     CIOUT
                        iny
                        cpy     #$20
                        bcc     :201

                        jsr     UNLSN

                        lda     $fb
                        clc
                        adc     #$20
                        sta     $fb
                        bcc     :204
                        inc     $fc

::204                   cli
                        rts
