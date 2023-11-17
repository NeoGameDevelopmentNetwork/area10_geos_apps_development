; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

:SYSTEM			= $04

			n	"mod.#00",NULL
			c	"GD_Convert  V1.0",NULL
			a	"M. Kanet",NULL
			f	SYSTEM
			o	$6100
			i
<MISSING_IMAGE_DATA>
			z	$40

;*** Namen der DOS-Tabellen.
:C01			s 16
:C02			b "PC437>GEOS-ASCII"
:C03			b "PC850>GEOS-ASCII"
:C04			b "PCWIN>GEOS-ASCII"
:C05			b "LINUX>GEOS-ASCII"
:C06			b "PC437>PETSCII   "
:C07			b "PC850>PETSCII   "
:C08			b "PCWIN>PETSCII   "
:C09			b "PC437>Mastertext"
:C10			b "PC437>Startexter"
:C11			s 16
:C12			s 16
:C13			s 16
:C14			s 16
:C15			s 16
:C16			s 16
:C17			s 16
:C18			s 16
:C19			s 16
:C20			s 16
:C21			s 16
:C22			s 16
:C23			s 16
:C24			s 16
:C25			s 16
:C26			s 16
:C27			s 16
:C28			s 16
:C29			s 16
:C30			s 16
:C31			s 16
:C32			s 16
:C33			s 16
:C34			s 16
:C35			s 16
:C36			s 16
:C37			s 16
:C38			s 16
:C39			s 16
:C40			s 16

;*** Namen der CBM-Tabellen.
:C41			s 16
:C42			b "GEOS-ASCII>PC437"
:C43			b "GEOS-ASCII>PC850"
:C44			b "GEOS-ASCII>PCWIN"
:C45			b "GEOS-ASCII>LINUX"
:C46			b "PETSCII>PC437   "
:C47			b "PETSCII>PC850   "
:C48			b "PETSCII>PCWIN   "
:C49			b "Mastertext>PC437"
:C50			b "Startexter>PC437"
:C51			s 16
:C52			s 16
:C53			s 16
:C54			s 16
:C55			s 16
:C56			s 16
:C57			s 16
:C58			s 16
:C59			s 16
:C60			s 16
:C61			s 16
:C62			s 16
:C63			s 16
:C64			s 16
:C65			s 16
:C66			s 16
:C67			s 16
:C68			s 16
:C69			s 16
:C70			s 16
:C71			s 16
:C72			s 16
:C73			s 16
:C74			s 16
:C75			s 16
:C76			s 16
:C77			s 16
:C78			s 16
:C79			s 16
:C80			s 16

;*** Namen der CBM-Tabellen.
:C81			s 16
:C82			b "BTX>GEOS-ASCII  "
:C83			b "GEOS-ASCII>BTX  "
:C84			s 16
:C85			s 16
:C86			s 16
:C87			s 16
:C88			s 16
:C89			s 16
:C90			s 16
:C91			s 16
:C92			s 16
:C93			s 16
:C94			s 16
:C95			s 16
:C96			s 16
:C97			s 16
:C98			s 16
:C99			s 16
:C100			s 16
:C101			s 16
:C102			s 16
:C103			s 16
:C104			s 16
:C105			s 16
:C106			s 16
:C107			s 16
:C108			s 16
:C109			s 16
:C110			s 16
:C111			s 16
:C112			s 16
:C113			s 16
:C114			s 16
:C115			s 16
:C116			s 16
:C117			s 16
:C118			s 16
:C119			s 16
:C120			s 16
