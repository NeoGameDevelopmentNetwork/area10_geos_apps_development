; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

;*** Menü: Hauptmenü.
:dm_MainMenu		b $00
			b $0c

if LANG = LANG_DE
			w $0000
			w $00d8
endif
if LANG = LANG_EN
			w $0000
			w $00c9
endif

			b $07 ! HORIZONTAL ! UN_CONSTRAINED

			w dmtx_geos
			b DYN_SUB_MENU
			w dynMenu_geos

			w dmtx_file
			b DYN_SUB_MENU
			w dynMenu_file

			w dmtx_view
			b DYN_SUB_MENU
			w dynMenu_view

			w dmtx_disk
			b DYN_SUB_MENU
			w dynMenu_disk

			w dmtx_select
			b DYN_SUB_MENU
			w dynMenu_slct

			w dmtx_page
			b DYN_SUB_MENU
			w dynMenu_page

			w dmtx_options
			b DYN_SUB_MENU
			w dynMenu_opt
;---

;*** Menü: geos.
:dm_geos		b $0c
:dm_geos_y1		b $44

if LANG = LANG_DE
			w  0*8
			w  0*8 +12*8 -1
endif
if LANG = LANG_EN
			w  0*8
			w  0*8 +10*8 -1
endif

:dm_geos_count		b 4 ! VERTICAL

			w dmtx_info_g
			b MENU_ACTION
			w menuInfoGEOS

			w dmtx_info_d
			b MENU_ACTION
			w menuInfoDTOP

			w dmtx_printer
			b MENU_ACTION
			w menuSlctPrint

			w dmtx_input
			b MENU_ACTION
			w menuSlctInput

			w tabNameDeskAcc +0 *17
			b MENU_ACTION
			w menuOpenDA

			w tabNameDeskAcc +1 *17
			b MENU_ACTION
			w menuOpenDA

			w tabNameDeskAcc +2 *17
			b MENU_ACTION
			w menuOpenDA

			w tabNameDeskAcc +3 *17
			b MENU_ACTION
			w menuOpenDA

			w tabNameDeskAcc +4 *17
			b MENU_ACTION
			w menuOpenDA

			w tabNameDeskAcc +5 *17
			b MENU_ACTION
			w menuOpenDA

			w tabNameDeskAcc +6 *17
			b MENU_ACTION
			w menuOpenDA

			w tabNameDeskAcc +7 *17
			b MENU_ACTION
			w menuOpenDA
;---

;*** Menü: Datei.
:dm_file		b $0c
			b $6f

if LANG = LANG_DE
			w  4*8
			w  4*8 +11*8 -1
endif
if LANG = LANG_EN
			w  4*8
			w  4*8 +11*8 -1
endif

			b 7 ! VERTICAL

			w dmtx_fopen
			b MENU_ACTION
			w menuFileOpen

			w dmtx_fcopy
			b MENU_ACTION
			w menuFileCopy

			w dmtx_frename
			b MENU_ACTION
			w menuFileRName

			w dmtx_info
			b MENU_ACTION
			w menuFileInfo

			w dmtx_fprint
			b MENU_ACTION
			w menuFilePrint

			w dmtx_fdelete
			b MENU_ACTION
			w menuFileDel

			w dmtx_fundelete
			b MENU_ACTION
			w menuFileUndel
;---

;*** Menü: Anzeige.
:dm_view		b $0c
			b $57

if LANG = LANG_DE
			w  7*8
			w  7*8 +8*8 -1
endif
if LANG = LANG_EN
			w  6*8
			w  6*8 +6*8 -1
endif

			b 5 ! VERTICAL

			w dmtx_viewpic
			b MENU_ACTION
			w menuViewMode

			w dmtx_viewsize
			b MENU_ACTION
			w menuViewMode

			w dmtx_viewtype
			b MENU_ACTION
			w menuViewMode

			w dmtx_viewdate
			b MENU_ACTION
			w menuViewMode

			w dmtx_viewname
			b MENU_ACTION
			w menuViewMode
;---

;*** Menü: Diskette.
:dm_disk		b $0c
			b $6f

if LANG = LANG_DE
			w 12*8
			w 12*8 +11*8 -1
endif
if LANG = LANG_EN
			w 10*8
			w 10*8 +8*8 -1
endif

			b 7 ! VERTICAL

			w dmtx_dopen
			b MENU_ACTION
			w menuDiskOpen

			w dmtx_dclose
			b MENU_ACTION
			w menuDiskClose

			w dmtx_drename
			b MENU_ACTION
			w menuDiskRName

			w dmtx_dcopy
			b MENU_ACTION
			w menuDiskCopy

			w dmtx_dvalidate
			b MENU_ACTION
			w menuDiskValid

			w dmtx_ddelete
			b MENU_ACTION
			w menuDiskErease

			w dmtx_dformat
			b MENU_ACTION
			w menuDiskFormat
;---

;*** Menü: Wahl.
:dm_select		b $0c
			b $37

if LANG = LANG_DE
			w 17*8
			w 17*8 +14*8 -1
endif
if LANG = LANG_EN
			w 13*8
			w 13*8 +10*8 -1
endif

			b 3 ! VERTICAL

			w dmtx_slctall
			b MENU_ACTION
			w menuSlctAll

			w dmtx_slctpage
			b MENU_ACTION
			w menuSlctPage

			w dmtx_slctborder
			b MENU_ACTION
			w menuSlctBorder
;---

;*** Menü: Seite.
:dm_page		b $0c
			b $27

if LANG = LANG_DE
			w 21*8
			w 21*8 +9*8 -1
endif
if LANG = LANG_EN
			w 17*8
			w 17*8 +8*8 -1
endif

			b 2 ! VERTICAL

			w dmtx_pageadd
			b MENU_ACTION
			w menuPageAdd

			w dmtx_pagedel
			b MENU_ACTION
			w menuPageDel
;---

;*** Menü: Options.
:dm_options		b $0c
			b $47

if LANG = LANG_DE
			w 24*8
			w 24*8 +8*8 -1
endif
if LANG = LANG_EN
			w 20*8
			w 20*8 +9*8 -1
endif

			b 4 ! VERTICAL

			w dmtx_optclock
			b MENU_ACTION
			w menuOptClock

			w dmtx_optreset
			b MENU_ACTION
			w menuOptReset

			w dmtx_optbasic
			b MENU_ACTION
			w menuOptBasic

			w dmtx_optkeys
			b MENU_ACTION
			w menuOptKeys
