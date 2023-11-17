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
; 53000.format-disk.bas - format scsi device
;
; parameter: dv    = cmd-hd device address
;            hd    = cmd-hd config-mode device address
;            sd    = cmd-hd scsi device id
;            sl/sh = cmd-hd scsi data-out buffer
;            sv$(x)= scsi vendor identification
;            sp$(x)= scsi product identification
; return   : -
; temporary: fm$,k$,eb,i,a$,ec(x),e1$,e2$,e3$,he$,by
;

; Format scsi-device

; Set current device address to default address of CMD-HD
53000 dv=h1

; Enable installation mode.
; Note: We can format iomega zip without config mode.
; 53000 gsoub51200:ifes>0thengoto53190
; 53010 dv=hd

; Select format mode.
53020 printtt$
53021 print"  select scsi format method:{down}"
53022 print"   1. standard format"
53023 print"      the recommended format method."
53024 print"      should work for most devices.{down}"
53025 print"   2. alternative format"
53026 print"      if standard format does not work"
53027 print"      for you then try this method.{down}"
53028 print"  select scsi format method (1/2) or"
; "Press <x> to cancel."
53029 gosub9540

; Wait for a key
53030 getk$:ifk$=""thengoto53030
53031 ifk$="1"thenfm$="01":goto53100
53032 ifk$="2"thenfm$="00":goto53100
53033 ifk$=chr$(13)thenk$="x"

; Exit format.
53090 es=2:return

; Format SCSI device.
; Wait for media in device
53100 gosub50700:ifes>2thengoto53090

53102 printtt$
53103 print"  formatting, please wait...{down}{down}"
53104 print"  average time needed to format:{down}"
53105 print"   >about 10min. for a 100mb zip disk"
53106 print"   >about 5secs. for a 1gb scsi2sd"
53107 print

; Erase SCSI data-out buffer
; The data-out buffer includes a defect list for the current medium.
; The "s-c" command will use the RAM at $4000 as data-out buffer.
; The "m-w" command will clear the data-out buffer.
53110 open15,dv,15
53111 sc$=nu$+nu$+nu$+nu$
53112 print#15,"m-w"chr$(sl)chr$(sh)chr$(4)sc$

; FORMAT UNIT command
; The FORMAT UNIT command requests that the device server format the
; medium into application client accessible logical blocks as specified
; in the number of blocks and block length values received in the last
; mode parameter block descriptor in a MODE SELECT command.
; In addition, the device server may certify the medium and create
; control structures for the management of the medium and defects.
;
; Format: 04 18 00 00 01 00
; $04 : FORMAT command
; $18 :
;       $1x : A FMTDATA bit set to "1" specifies that the FORMAT UNIT
;             parameter list shall be transferred from the data-out
;             buffer. The parameter list consists of a parameter list
;             header, followed by an optional initialization pattern
;             descriptor, followed by an optional defect list.
;       $x8 : A CMPLST bit set to one specifies that the defect list
;             included in the FORMAT UNIT parameter list is a complete
;             list of defects. Any existing GLIST shall be discarded
;             by the device server. As a result, the device server shall
;             construct a new GLIST that contains:
;             a) the DLIST, if it is sent by the application client; and
;             b) the CLIST, if certification is enabled (i.e., the
;                device server may add any defects it detects during the
;                format operation).
; $00 : Vendor specific
; $00 : Reserved
; $01 : The fast format (FFMT) field
;       $00 : The device server initializes the medium as specified in
;             the CDB and parameter list before completing the format
;             operation.
;             After successful completion of the format operation, read
;             commands and verify commands are processed as described
;             in SBC-4.
;       $01 : The device server initializes the medium without
;             overwriting the medium (i.e., resources for managing
;             medium access are initialized and the medium is not
;             written) before completing the format operation.
;             After successful completion of the format operation, read
;             commands and verify commands are processed as described
;             in SBC-4.
;             If the device server determines that the options specified
;             in this FORMAT UNIT command are incompatible with the read
;             command and verify command requirements described in
;             SBC-4, then the device server shall not perform the format
;             operation and shall terminate the FORMAT UNIT command with
;             CHECK CONDITION status with the sense key set to ILLEGAL
;             REQUEST and the additional sense code set to INVALID FAST
;             FORMAT COMBINATION.
; $00 : Control
;
; Note: In some rare case format will not work with FFMT set to "1".
; When set FFMT to "0" format may take some time to complete (no fast
; format) but on some medium this seem to be necessary (as seen on a
; 1Gb JAZ disk drive).

; Create SCSI command "FORMAT UNIT"
53120 he$="04180000"+fm$+"00":gosub60100:sc$=by$

; Send SCSI command
53121 gosub59800

; Get SCSI status information
; Backup and reset current error code.
53130 eb=es:gosub59300:es=eb
53132 close15

; Check for errors
53140 ifes=0thengoto53194

; Format error
53190 print"{down}  formatting failed!"
53191 goto 53198

; Test for AutoFormat...
53194 print"{down}  format completed!"
53195 ifmk$=af$thengoto53199

; All done
53198 gosub60400
53199 return
