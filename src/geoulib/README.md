# AREA6510

### geoULib
geoULib is a collection of assembler routines to communicate with Ultimate devices (U64, UII+) under GEOS via the Ultimate Control Interface (UCI).
The routines are developed for use with the GEOS-MegaAssembler, but should be convertible for other assemblers as well.

To use the routines of geoULib you have to include some include files in your own source code:
```
        t "ulib.C.SymbTab"
        t "ulib.C.Core"
```
Depending on the used routines further include files are needed. You can find more information in the source code of the demo programs.

Then include the DOS or CONTROL routines into your source code:
```
        t "_dos.00.Target"
        t "_dos.09.DelFile"
        t "_dos.11.ChDir"
```

The code to call the geoULib routine to delete a file could look like this:
```
:uDeleteFile
        jsr ULIB_IO_ENABLE    ;Disable IRQ, enable I/O.
        jsr ULIB_SEND_ABORT   ;Send ABORT.

        jsr _UCID_SET_TARGET1 ;Use target DOS1.

        lda #< uPathDir       ;Change directory.
        sta r6L
        lda #> uPathDir
        sta r6H
        jsr _UCID_CHANGE_DIR
        txa                   ;Error?
        bne :err              ; => Yes, abort...

        lda #< uFileName      ;Set filename.
        sta r6L
        lda #> uFileName
        sta r6H
        jsr _UCID_DELETE_FILE ;Delete file...

::err   jmp ULIB_IO_DISABLE   ;Disable I/O, enable IRQ.
```

#### geoULib demo applications
The sub directory 'demos' includes the source code documentation for some demo applications that will demonstrate how to use the geoULib code in own applications.
These demos are not designed to be complete applications since they do not have a comfortable user interface. Instead you have to edit the GEOS infoblock and add a path to a directory or a file to test these demos. Using a full path (like /Usb0/testdir/test.d64) is recommende.
