# AREA6510

### geoULib - Demo-Programme

Der Sinn und Zweck der Demo-Programme es nicht(!) vollständige GEOS-Applikationen bereitzustellen, dafür gibt es bereits Programme. Die Demos nutzen lediglich die Routinen aus der geoUlib damit man das Rad nicht immer neu erfinden muss. Der SourceCode zu den Demo-Programmen zeigt wie man die UCI-Befehle in eigenen GEOS-Programmen verwendet.
Man kann alle Demo-Programme verwenden, einige muss man aber zuvor "einrichten", da es keinen FileBrowser und keine Benutzeroberfläche gibt. Wenn die Konfiguration fehlerhaft ist, dann kehrt die Anwendung zum DeskTop zurück, ansonsten erscheint eine Infobox (Ausnahme: geoUGetTime das als AutoExec nur die Uhrzeit einliest, ähnlich wie geoCham64RTC+). Die Konfiguration muss direkt am Angang des Infotextes stehen, alles nach einem RETURN wird ignoriert. Wenn ein Pfad angegeben wird, dann immer der vollständige Pfad, z.B. /Usb0/testfile. Wird kein Pfad angegeben, dann bezieht sich das auf den aktuell eingestellten Pfad, nicht auf den Pfad im Ultimate FileBrowser!

Es folgt eine kurze Beschreibung der Demo-Programme und wie diese zu konfigurieren sind.


##### geoUChDir
Im Infoblock definiert man den Pfad zu einem Verzeichnis in das gewechselt werden soll. Der Pfad kann absolut oder relativ angegeben werden.
**Beispiele:**
```
/Usb0/testdir
testdir
```


##### geoUMakeDir
Im Infoblock definiert man den Pfad zu einem Verzeichnis das erstellt werden soll.
**Beispiele:**
```
/Usb0/testdir
testdir
```


##### geoUDiskMnt
Im Infoblock definiert man das Ultimate-Laufwerk (die IEC-ID aus dem Ultimate-Menü, zweistellig!), das zugehörige GEOS-Laufwerk und den Pfad zum DiskImage das eingelegt werden soll. Dabei wird die passende Imagegröße überprüft.
**Beispiel:**
```
09:B:/Usb0/ULIB/test.d64
```
Im Ultimate-Menü ist 1541A mit ID#9 eingerichtet, unter GEOS ist das Laufwerk als Laufwerk B: installiert.



##### geoUDiskMntF

Im Infoblock definiert man das Ultimate-Laufwerk (die IEC-ID aus dem Ultimate-Menü, zweistellig!). Es kann optional ein Pfad zum DiskImage angegeben werden. Der Pfad wird hier über ChDir gesendet und das DiskImage ohne Pfad gemounted.
**Beispiel:**
```
09:/Usb0/ULIB/test.d64
```
Im Ultimate-Menü ist 1541A mit ID#9 eingerichtet.


##### geoUDiskUMnt
Im Infoblock definiert man Ultimate-Laufwerk dessen DiskImage ausgeworfen werden soll (die IEC-ID aus dem Ultimate-Menü, zweistellig! Danach folgt immer ein ':' ).
**Beispiel:**
```
09:
```
Im Ultimate-Menü ist 1541A mit ID#9 eingerichtet.


##### geoUSwapDisk
Im Infoblock definiert man Ultimate-Laufwerk dessen DiskImage gewechselt werden soll (die IEC-ID aus dem Ultimate-Menü, zweistellig! Danach folgt immer ein ':' ).
**Beispiel:**
```
09:
```
Im Ultimate-Menü ist 1541A mit ID#9 eingerichtet.


##### geoULoadREU
##### * EXPERIMENTELL / DATENVERLUST MÖGLICH *
Im Infoblock definiert man das GEOS-RAM-Laufwerk und den Pfad zum DiskImage, welches in die RAMDisk geladen werden soll. Dabei wird die passende Imagegröße überprüft.
Kann auch als AutoExec verwendet werden, überschreibt dann aber ungefragt den Inhalt der RAMDisk beim Systemstart!
**Beispiel:**
```
C:/Usb0/ULIB/test.d64
```


##### geoUSaveREU
Im Infoblock definiert man das GEOS-RAM-Laufwerk und den Pfad zum DiskImage, in welches die RAMDisk gespeichert werden soll.
**Beispiel:**
```
C:/Usb0/ULIB/test.d64
```


##### geoUDWrite
Im Infoblock definiert man den Pfad zu einer Testdatei, in welche 8000 Byte geschrieben werden können. Dabei wird ein Testbildschirm aus dem 40Z-Modus gespeichert (80Z wird nicht unterstützt).
**Beispiel:**
```
/Usb0/ULIB/testfile
```


##### geoUDRead
Im Infoblock definiert man den Pfad zu einer Testdatei, aus welcher 8000 Byte in den 40Z-Grafikbildschirm geladen werden können. Im 80Z-Modus sieht man daher nichts, im 40Z-Modus baut sich der Bildschirm mit dem Testbild wieder auf.
**Beispiel:**
```
/Usb0/ULIB/testfile
```


##### geoUFileInfo
Im Infoblock definiert man den Pfad zum einem DiskImage, dessen Informationen angezeigt werden sollen.
**Beispiel:**
```
/Usb0/ULIB/test.d64
```


##### geoUFileStat
Im Infoblock definiert man den Pfad zum einem DiskImage, dessen Informationen angezeigt werden sollen. Der Befehl ähnelt FILE_INFO, verwendet aber einen anderen DOS-Befehl und benötigt mit Firmware V3.6a immer den vollständigen Verchnispfad.
**HINWEIS:** Der Befehl FILE_STAT funktioniert aber nicht immer zuverlässig, z.B. nach WRITE_DATA, COPY_FILE oder RENAME_FILE mit anderem Ziel-Verzeichnis: Danach meldet FILE_STAT nur noch den Fehler "82,FILE NOT FOUND", FILE_INFO funktioniert aber noch.
**Beispiel:**
```
/Usb0/ULIB/test.d64
```


##### geoUFileSeek
Im Infoblock definiert man den Pfad zum einem D64-DiskImage, dessen Diskname angezeigt werden soll. Funktioniert nur mit D64!
**Beispiel:**
```
/Usb0/ULIB/test.d64
```


##### geoUDelFile
Im Infoblock definiert man den Pfad zum einer Datei die gelöscht werden soll.
**Beispiel:**
```
/Usb0/ULIB/test.d64
```


##### geoURenFile
Im Infoblock definiert man den Pfad zum einer Datei die umbenannt werden soll. Durch ein Komma getrennt folgt im Anschluss der neue Dateiname.
**Beispiel:**
```
alt.d64,neu.d64
```

Man kann hier auch unterschiedliche Verzeichnisnamen für den alten und neuen Dateinamen angeben. In dem Fall verhält sich RENAME wie ein MOVE-Befehl.
**Beispiel:**
```
datei.d64,/Usb0/testdir/test.d64
```
Verschient die Datei "datei.d64" aus dem aktuellen Verzeichnis in das Verzeichnis und Datei "/Usb0/testdir/test.d64".


##### geoUCopyFile
Im Infoblock definiert man den Pfad zum einer Datei die kopiert werden soll. Durch ein Komma getrennt folgt im Anschluss der Name des Ziel-Verzeichnis.
**Beispiel:**
```
alt.d64,/Usb0/testdir
```


##### geoUEnDiskA
Im Infoblock definiert man das Ultimate-Laufwerk (die IEC-ID aus dem Ultimate-Menü, zweistellig!), das eingeschaltet werden soll.
**Beispiel:**
```
09:
```
Im Ultimate-Menü ist 1541A mit ID#9 eingerichtet.


##### geoUDisDiskA
Im Infoblock definiert man das Ultimate-Laufwerk (die IEC-ID aus dem Ultimate-Menü, zweistellig!), das ausgeschaltet werden soll.
**Beispiel:**
```
09:
```
Im Ultimate-Menü ist 1541A mit ID#9 eingerichtet.


##### geoUSetTime
Das Programm setzt die Uhrzeit im Ultimate auf die aktuelle GEOS- Systemzeit. Wenn die Option "UltiDOS: Allow SetDate" auf "Disabled" steht kann die Uhrzeit nicht gesetzt werden (Fehlermeldung).


##### geoUSaveERAM
Im Infoblock definiert man den Pfad zu einer Datei, in welcher der Inhalt des erweiterten Speichers innerhalb der C=REU oder GeoRAM gespeichert werden soll.
Hinweis: Wegen eines Fehlers in älteren Firmware-Versionen wird der Inhalt des erweiterten RAM bei 16Mb in zwei Schritten gespeichert:
Zuerst das Byte #0, dann die Bytes #1 bis #FF:FFFF. Der Transferstatus zeigt daher an das die Daten ab Offset#1 gespeichert wurden.
**Beispiel:**
```
/Usb0/ULIB/geos.reu
```


##### geoUOpenTCP
Im Infoblock definiert man den Hostnamen und den Port zu einem Server, mit dem eine Verbindung hergestellt werden soll. Host und Port werden durch einen ':' getrennt.
**Beispiel:**
```
 192.168.2.2:2049
```


##### geoUOpenUDP
Im Infoblock definiert man den Hostnamen und den Port zu einem Server, mit dem eine Verbindung hergestellt werden soll. Host und Port werden durch einen ':' getrennt.
**Beispiel:**
```
pool.ntp.org:123
```


##### Sonstiges
Die folgenden Demoprogramme müssen nicht eingerichtet werden:

geoUTestERAM / geoUGetPath / geoUPathUsb0 / geoUPathUsb1 / geoUHomePath / geoUShowTime / geoUGetTime / geoUFreeze / geoUReboot / geoUTarget / geoUGetHWInfo / geoUDrvInfo / geoUDiskPwr / geoUIFCnt / geoUGetMAC / geoUGetIPAdr / geoUReadNTP
