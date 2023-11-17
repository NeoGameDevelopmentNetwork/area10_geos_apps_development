# Area6510

### cbmHDscsi64
The goal of this project is to format and initialize a SCSI device connected to a CMD-HD easily and without additional programs.

So far you need llformat, createsys, rewrite dos, system header, hddos and geoshd. Additionally you have to set the CMD-HD into configuration mode by pressing several buttons.

Pressing the buttons on the CMD-HD is no longer absolutely necessary: Using various HD-ROM routines, this can also be done by software.

#### Modules
This directory includes the BASIC code for cbmHDscsi64 splitted into several smaller modules with additional comments.

#### Reference
This directory does include some programs that have been analyzed to understand how a medium has to be initialized, so that the medium can be used later as a hard disk via the CMD-HD.
