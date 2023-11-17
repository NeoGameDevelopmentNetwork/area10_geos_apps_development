; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Systemvariablen.
;    Werden bei GEOS.BOOT verwendet, müssen als Füllbytes auch bei "RBOOT.GEOS"
;    beibehalten werden, damit ":BOOT_RAM_TYPE" bei beiden Programmen an der
;    gleichen Adresse steht!
;    Diese Adresse wird direkt modifiziert! Nicht verschieben!
;
;*** Verschiedene Startlaufwerk-Konfigurationen.
;    Mögliche Werte für BOOT_MODE:
;    (Kombinieren mit SET_MODE_xx ! SET_MODE_yy)
;SET_MODE_PARTITION = %10000000;CMD-Partitionen.
;SET_MODE_SUBDIR    = %01000000;CMD-NativeMode-Verzeichnisse.
;SET_MODE_FASTDISK  = %00100000;CMD FD/HD/RL/RAMDISK
;RAMLink:
;:Boot_Drive		b $08				;Laufwerks-Adresse.
;:Boot_Type		b DrvRL81			;Laufwerks-Typ.
;:Boot_Mode		b SET_MODE_PARTITION!SET_MODE_FASTDISK
;:Boot_Part		w $0000				;Boot-Partition.
;CMD-HD:
;:Boot_Drive		b $08				;Laufwerks-Adresse.
;:Boot_Type		b DrvHD81			;Laufwerks-Typ.
;:Boot_Mode		b SET_MODE_PARTITION!SET_MODE_FASTDISK
;:Boot_Part		w $0000				;Boot-Partition.
;1581:
:Boot_Drive		b $08				;Laufwerks-Adresse.
:Boot_Type		b Drv1581			;Laufwerks-Typ.
:Boot_Mode		b NULL
:Boot_Part		w $0000				;Boot-Partition.

;*** Variablen.
:Device_SCPU		b $00
:Device_RL		b $00

;*** Dieses Byte darf nicht verschoben werden, da hier direkt von "GEOS.MP3"
;    die installierte REU gespeichert wird!
:BOOT_RAM_TYPE		b $00				;$00 = RAM nicht gewählt.
							;$10 = RAMCard gewählt.
							;$20 = BBGRAM  gewählt.
							;$40 = C=REU   gewählt.
							;$80 = RAMLink gewählt.
:BOOT_RAM_SIZE		b $00
:BOOT_RAM_BANK		w $0000
:BOOT_RAM_PART		b $00
