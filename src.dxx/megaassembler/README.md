# Area6510

### MegaAssembler V5
The original MegaAssembler V2.0 is ok for average sized projects, but when you are working on very large projects there are some things that could have been done better:

##### Select source files
The Menu of MegaAssembler where you can select the source file only shows the first 13 entries on disk. If you have more source files you have to find a way to work around that.
Version 3.x and later now shows only the first 12 entries but includes an extra entry to display the next 12 entries.

##### Compiling many source files
By default the MegaAssembler compiles only one source file at a time.
Version 3.x introduces the AutoAssembler mode where you create a configuration file including the sources that need to be compiled. If the AutoAss-option is enabled you can select the configuration file and MegaAssembler will then compile all source files without having to select the source files manually from the menu.

##### Symbol table
The free memory for the symbol table was about 16Kb only. Version 3.x has been reworked to save some memory and thus the symbol table offers now about 24Kb memory.

##### Miscellaneous
Some new OpCodes got included like 'h' to add text to the info block of GEOS files ok 'k'/'l' to add the current date in short/long format to the source code as a text string. Available Opcodes can be displayed from the 'Exit' menu.
