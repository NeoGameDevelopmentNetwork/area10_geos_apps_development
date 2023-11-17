; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;
; cbmSCSIcopy64
;
; 39700.directory-next-block.bas - define next directory block
;

; Define next directory sector
; 1541/1571
; Track  1-17: 17 tracks / 21 sectors
; Track 18-24:  7 tracks / 19 sectors
; Track 25-30:  6 tracks / 18 sectors
; Track 31-35:  5 tracks / 17 sectors
39700 iftr>0thend0=d0+(tr-1)*21
39701 iftr>=18andtr<25thend0=d0+(tr-17-1)*19
39702 iftr>=25andtr<31thend0=d0+(tr-7-17-1)*18
39703 iftr>=31andtr<36thend0=d0+(tr-6-7-17-1)*17
; 1571
; Track 36-52: 17 tracks / 21 sectors
; Track 53-59:  7 tracks / 19 sectors
; Track 60-65:  6 tracks / 18 sectors
; Track 66-70:  5 tracks / 17 sectors
39710 iftr>=36andtr<53thend0=d0+(tr-5-6-7-17-1)*21
39711 iftr>=53andtr<60thend0=d0+(tr-17-5-6-7-17-1)*19
39712 iftr>=60andtr<66thend0=d0+(tr-7-17-5-6-7-17-1)*18
39713 iftr>=66andtr<71thend0=d0+(tr-6-7-17-5-6-7-17-1)*17

39720 d0=d0+se
39721 return

; 1581
39730 d0=d0+(tr-1)*40+se
39740 return

; Native
39750 d0=d0+(tr-1)*256+se
39760 return
