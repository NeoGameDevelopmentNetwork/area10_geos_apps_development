; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; hdPartInit
;
; 38100.hdpart-delete.bas - delete partition
;
; parameter: dv    = cmd-hd device address
;            sd    = cmd-hd scsi device id
;            so    = system area offset
;            pl    = partition number
; return   : pn    = deleted partition
;            pt()  = partition data: type
;            pn$() = partition data: name
;            ps()  = partition data: size
; temporary: pn,ba,bh,bm,bl,pt,pt$,kb$,i
;

; Delete partition from configuration file
38100 printtt$:print"  remove partition from config:{down}"

; Enter partition number to delete
38110 input"  which partition (1-254) ";pn
38111 if(pn<1)or(pn>254)thengoto38199
38112 ifpt(pn)=0thengoto38199

; Print partition entry
38120 printli$
38121 printright$(sp$+str$(pn),4);" ";

; Print partition name
38122 print"'";pn$(pn);"'";

; Print partition size
38125 printright$(sp$+str$(ps(pn)*2),6);" ";

; Print partition type
38126 pt=pt(pn):gosub48900:printpt$
38127 printli$;"{down}"

; Delete partition?
38130 print"  delete partition (y/n) ? ";
38140 getkb$:ifkb$=""thengoto38140
38141 if(kb$="y")or(kb$="Y")thengoto38150
38142 if(kb$="n")or(kb$="N")thengoto38199
38143 goto38140

; Delete partition
38150 printkb$;"{down}"
38160 pt(pn)=0:pn$(pn)="":ps(pn)=0:pa(pn)=0

; Partition deleted
38190 print"  partition deleted!"
38191 gosub30300

; Wait a second...
38195 gosub51800

; All done
38199 return

