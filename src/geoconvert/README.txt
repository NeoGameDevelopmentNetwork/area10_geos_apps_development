; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

How to install from source using MegaAssembler:
Open the file 'sys.Release' using geoWrite and set the language:

For german language:
  .Sprache = Deutsch

For english language:
  .Sprache = Englisch

When using MegaAssembler > 3.x you can use the AutoAssembler
mode to build and link the program automatically.
Select 'ass.geoConv.DE' or 'ass.geoConv.EN' to build the application.

When using MegaAssembler 2.x you have to compile and link the
application manually:
-src.geoConvert
-src.DImgToFile
-src.DImgToDisk
-src.DImgCreate
-src.ConvCVT
-src.ConvUUE
-src.ConvSEQ
-src.MainMenu

After you have compiled these parts you have to link the application suing 'lnk.geoConvert.D' or 'lnk.geoConvert.E'.
