; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

; C64-Kernal routines.
;
; Reassembled (w)2020 by Markus Kanet
; Original authors:
;   Brian Dougherty
;   Doug Fults
;   Jim Defrisco
;   Tony Requist
; (c)1986,1988 Berkeley Softworks
;
; Revision V0.1
; Date: 23/03/16
;
; History:
; V0.1 - Moved all ext. symbols to
;        a separate file.
;

;--- C64-Kernal-Routinen.
:LISTEN			= $ffb1
:TALK			= $ffb4
:SECOND			= $ff93
:CIOUT			= $ffa8
:UNLSN			= $ffae
:UNTALK			= $ffab
:ACPTR			= $ffa5
:TKSA			= $ff96
