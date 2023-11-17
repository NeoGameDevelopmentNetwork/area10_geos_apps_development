; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmHDscsi64
;
; 59200.scsi-inquiry.bas - INQUIRY
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
; return   : si(x) = device type
;            sv$(x)= scsi vendor identification
;            sp$(x)= scsi product identification
;            sr$(x)= scsi revision level
; temporary: i,a$,he$,sc$,by$
;

;--- 6 Bytes
;SCSI command  : INQUIRY
; -Operation Code $12
; -EVPD Bit%0=0: Standard INQUIRY data
; -Page Code
; -Allocation length Hi/Lo
; -Control
;Return        : 36 Bytes
;$00           : Bit %0-%4 = Device type
;$01           : Bit %7 = Removable media
;$08-$0F       : T10 Vendor identification
;$10-$1F       : Product identification
;$20-$23       : Product revision level
;Currently not used:
;$24-$2B       : Drive serial number
;scsiINQUIRY     b "S-C"
;scsiINQUIRY_id  b $00
;                w $4000
;                b $12,$00,$00,$00,$24,$00
;scsiINQUIRY_mr  b "M-R"
;                w $4000
;                b $24

; SCSI INQUIRY data
59200 he$="120000002400":gosub60100: sc$=by$
59210 open15,dv,15
59220 gosub59900:rem send scsi command
59230 print#15,"m-r"chr$(sl)chr$(sh)chr$(36)

; Get device type
59240 get#15,a$:si(sd)=asc(a$+nu$)

; Get removable media
59241 get#15,a$:sm(sd)=asc(a$+nu$)

; Unused bytes
59242 get#15,a$,a$,a$,a$,a$,a$

; Clear device info
59250 sv$(sd)="":sp$(sd)="":sr$(sd)=""

; Read vendor data
59251 fori=0to7:get#15,a$:gosub60300:sv$(sd)=sv$(sd)+a$:next

; Read product information
59252 fori=0to15:get#15,a$:gosub60300:sp$(sd)=sp$(sd)+a$:next

; Read product revision
59253 fori=0to3:get#15,a$:gosub60300:sr$(sd)=sr$(sd)+a$:next

59260 close15
59290 return
