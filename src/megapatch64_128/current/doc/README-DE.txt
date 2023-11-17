; UTF-8 Byte Order Mark (BOM), do not remove!
;
; Area6510 (c) by Markus Kanet
;
; This file is used to document the source code, not for
; creating an executable program.
;

GEOS MEGAPATCH 64/128
Installationshinweise - Stand: 2023/01/19

Diese Diskette enthält die aktuellen Versionen von GEOS-MegaPatch.

In der aktuellen Version ist TOPDESK als Desktop-Oberfläche nicht mehr enthalten.
TOPDESK, der mit MegaPatch von 2000/2003 veröffentlicht wurde, kann weiterhin verwendet werden. Gleiches gilt für den ursprünglichen DESKTOP von GEOS 2.x.

Eine kurze Anleitung zu GEOS-MegaPatch ist in der Datei "USER-MANUAL-DE" enthalten.

ANFORDERUNGEN
- GEOS 64/128 V2.x oder GEOS-MegaPatch 64/128 V3.x
- Ein Laufwerk vom Typ 1541/1571 (bei Installation von einem D64 benötigen Sie dann eine doppelseitige Festplatte) und ein zweites Laufwerk als Ziel oder ein einzelnes 1581 (bei Installation von einem D81) für Quell- und Ziellaufwerk.
- Die Installation auf einem RAM1541-Laufwerk ist mit mindestens 512K RAM möglich (RAM1571 mit 512K funktioniert nicht, mit 1Mb sollte auch ein RAM1581 funktionieren). Eine RAM1571 mit 512K wird in eine NativeMode RAMDisk umgewandelt.
- C=1351 kompatibles Eingabegerät, Joystick funktioniert auch. Verwenden Sie Port #1.
- Nur C128: 64Kb VDC RAM.

INSTALLATION
Starten Sie die Datei "SETUPMP_64" oder "SETUPMP_128" und folgen Sie den Anweisungen am Bildschirm.
Wenn das Ziel-Laufwerk weniger als 300Kb freien Speicher hat, sollten Sie das benutzerdefinierte Setup verwenden und nur die erforderlichen Systemdateien und Laufwerkstreiber installieren.
Stellen Sie sicher, dass Sie eine Datei namens "DESK TOP" (C64) oder "128 DESKTOP" (C128) auf dem Start-Laufwerk haben. Dies kann entweder DESKTOP V2 oder eine beliebige TOPDESK-Version sein.

Nicht alle Desktop-Anwendungen unterstützen alle Funktionen der MegaPatch-Laufwerkstreiber. Die TOPDESK-Version von 2000/2003 weist einige bekannte Fehler auf (Disk-Copy, Validate, insbesondere im NativeMode).

UNTERSTÜTZTE HARDWARE
C64/C64C (PAL/NTSC), C128/C128D, C64 Reloaded, 1541/II, 1571, 1581, CMD FD2000, CMD F4000, CMD HD (inkl. Parallelkabel), CMD RAMLink, CMD SuperCPU 64/128, SD2IEC (mit aktueller Firmware), C=1351, CMD SmartMouse, Joystick, C=REU, CMD REU XL, GeoRAM, BBGRAM, CMD RAMCard, 64Net (seit Jahr 2000/2003 ungetestet). TurboChameleon64. Tom+/MicroMys-Adapter mit USB/PS2-Maus.

NICHT UNTERSTÜTZTE HARDWARE:
Ultimate64 mit einer Firmware > 1.29. Ab dieser Version wird der TurboModus unterstützt: Mit bestimmten Einstellungen kann MegaPatch eventuell nicht installiert werden.

C128 mit weniger als 64KB VDC RAM.

SD2IEC wird mit der dateibasierten Speicheremulation als 1541/1571/1581 erkannt (siehe SD2IEC Handbuch -> "XR"-Befehl). Die Geräteadresse wird automatisch konfiguriert, mit Ausnahme des Start-Laufwerks. Verwenden Sie den 1541/1571/1581-Laufwerkstreiber.
Für NativeMode müssen Sie das SD2IEC mit der richtigen Geräteadresse konfigurieren (z.B. Laufwerk D: = Gerät #11) und verwenden Sie den "SD2IEC"-Treiber. Eine dateibasierte Speicheremulation ist für den NativeMode nicht erforderlich.
Verwenden Sie den GEOS.Editor und die Schaltfläche "DiskImage/Partition wechseln" auf der Register-Karte "LAUFWERKE" (der untere Pfeil für jedes Laufwerk), um DiskImages zu wechseln.
Das aktuelle DiskImage kann nicht gespeichert werden. Beim nächsten Start bleibt das aktuelle DiskImage aktiv.

BEHOBENE PROBLEME
- Die Installation über GEOS.MP3 ersetzt mehrere RAMNative-Laufwerke durch ein einzelnes Laufwerk.
- Der Bildschirmschoner wird bei jedem Neustart wieder aktiviert.
- Der 1541-Cache-Treiber lässt sich nicht fehlerfrei installieren bzw. de-installieren und gibt unter Umständen Systemspeicher frei was zum Absturz führen kann.
- Das ReBoot-System ist "Optional", wurde aber bei der Prüfung der Startdiskette als "fehlende Systemdatei" erkannt: Die Installation kann nicht fortgesetzt werden.
- Die Überprüfung der Systemdateien der Startdiskette war fehlerhaft und wurde behoben.
- Fehlerhafte Farbdarstellung im MegaPatch-Logo behoben.
- Beim C128 wurde im Setup-Programm andere Farben für den Autoren-Hinweis verwendet.
- Fehler in der Farbdarstellung mit Startbild "Megascreen.pic" behoben.
- Zu langer Dateiname für das Startbild überschreibt den Dateinamen für den voreingestellten Drucker.
- Die fehlerhafte Installation im 40Zeichen-Modus des C128 wurde behoben.
- Fehlerhafte Farbdarstellung in Dialogboxen im Setup-Programm im 80Zeichen-Modus des C128 behoben.
- Die Option "Schneller Speichertransfer für C=REU/MoveData" wird nicht mehr bei jedem Neustart deaktiviert und wird nur noch bei einer C=REU als Speichererweiterung freigeschaltet.
- Der Bildschirmschoner 64erMove arbeitet jetzt mit C=REU und MoveData zusammen.
- 64erMove lässt sich jetzt auch im Editor speichern (falscher Dateiname).
- Im GEOS.Editor wurden einige Einstellungen nicht aktualisiert wenn diese durch andere Einstellungen verändert werden. Dadurch wurden (X)-Optionen als "Aktiviert" dargestellt obwohl die Option deaktiviert wurde.
- GEOS.BOOT startet jetzt die System-Uhrzeit, auch wenn diese zuvor außerhalb von GEOS angehalten wurde.
- Sofortige Aktualisierung der freien/belegten Speicherbänke in GEOS bei Änderungen im Editor.
- Das Systemdatum wird jetzt standardmäßig auf 1.1.2018 gesetzt wenn keine RTC-Uhr gefunden wird.
- Bei Verwendung einer Speichererweiterung mit 16.384KByte wurde die Größe nicht korrekt erkannt. Der Fehler wurde behoben, allerdings lassen sich nur 255x64KByte = 16.320JByte verwenden.
- Bei Verwendung von mehr als einer Setup-Diskette wird jetzt nach einem Diskettenwechsel die neue Diskette initialisiert und GEOS-interne Systemvariablen aktualisiert um ggf. einen fehlerhaften Diskettenwechsel zu erkennen.
- Beim starten ohne Hintergrundbild wird im 80Zeichen-Modus des C128 jetzt die Hintergrundfarbe auf Standard gesetzt. Notwendig da 128DUALTOP den Farbspeicher beim starten nicht löscht.
- Die automatische Erkennung einer RTC zum setzen der Uhrzeit führt bei installiertem Parallelkabel der 1571 zu einem Systemstillstand.
- Wird GEOS.MP3 von GEOS128v2/DESKTOPv2 im 80Z-Modus gestartet, dann ist evtl. das DB_DblBit-Flag nicht korrekt gesetzt. DialogBox-Icons werden dann nicht automatisch in der Breite gedoppelt.
- Löschen des Bildschirms beim verlassen von GEOS.MP3 da sonst GEOS128v2/DESKTOPv2 mit falschen Farben angezeigt wird.
- Das X-Register muß bei Verwendung von ":MoveData" unverändert bleiben. Zumindest TopDesk v4.1 hat hier Probleme wenn das X-Register verändert wird.
- Im TaskManager128 führt das Auslesen der Laufwerks-Kennbytes aus der REU über FetchRAM in die ZeroPage zu einem Fehler ("Die Laufwerkskonfiguration wurde geändert").
- Beim wechseln des aktuellen Tasks wird TurboDOS in allen Laufwerken deaktiviert, da VICE ansonsten auf Hardware-Laufwerken (1541,71,81...) mit einem DISK-JAM abstürzen kann.
- geoPaint stürzt beim verschieben des Bild-Ausschnitts bei aktivierter REU-MoveData-Option ab.
- geoPaint stürzt beim wieder herstellen einer geänderten Zeichnung ab.
- Probleme bei der Installation mit verteiltem Setup auf 2x1541-Disketten behoben.
- Fehler in de ToBASIC-Routine behoben. Unter MegaPatch64 war es damit nicht möglich BASIC-Befehle oder -Programme zu starten.
- Der SuperMouse64-Treiber wurde an das TurboChameleon64 angepasst.
- Der GEOS-BorderBlock wurde für 1541/1571-Laufwerke im Verzeichnis-Bereich erstellt, analog zum 1581-Format. Track/Sektor für den BorderBlock in Anlehnung an GEOS v2 angepasst.
- RAM51/71/81 werden nicht mehr automatisch als "GEOS-Diskette" erstellt (enspricht NativeMode).
  HINWEIS: MegaPatch V3.3r5 und älter löscht nicht-GEOS RAM-Laufwerke während des Startvorgangs.
- Die Laufwerkstreiber FD71/HD71/RL71 setzen das ":doubleSideFlg" nicht korrekt. Anwendungen, welche dieses Flag auswerten, kopieren evtl. nur die "erste Seite" einer entsprechenden Partition.
- Probleme mit DualTop128 behoben (NewMoveData).
- C= Zeichen im MegaPatch128 Font/Englisch seit Version 3.0/2000 fehlerhaft.
- Die Routine ":SetNextFree" belegte auf NativeMode-Laufwerken in seltenen Fällen für das Hauptverzeichnis reservierte Blocks für Dateien, wodurch die Anzahl der belegten Blocks auf Diskette nicht korrekt angezeigt wird.
- Im Gegensatz zu GEOS-V2 testet DoRAMOp die Bank in r3L nicht auf Gültigkeit.

BEHOBENE PROBLEME (Fortsetzung)
- GateWay zeigte bei Datei-Info ein beschädigtes Datei-Icon an.
- DualTop128 invertiert beim vor- und zurückblättern in der Dateiliste über die Pfeile den jeweils nächsten oder vorherigen Dateieintrag. Hier der Wert in ":curPattern" auf $xxF0=Muster#0 getestet und der Wert war bei MP128 von Beginn an ein anderer. Das führt dazu das der Dateiname mit REVON=Invers ausgegeben wird. Bei DualTop64 tritt der Fehler nicht auf (Test auf $xx00).
- Wird über den TaskManager versucht ein Dokument zu öffnen dessen Anwendung nicht gefunden werden kann, dann wurde ein ungültiger neuer Task in der Taskliste angelegt. Beim beenden des TaskManagers stürzt MegaPatch dann ab.
- Der PacMan-Bildschirmschoner löscht bei einem Richtungswechsel die letzte Pixel-Spalte nicht korrekt. Bei Verwendung eines TurboChameleon64 schaltete der Bildschirmschoner nicht in den 1MHz-Modus und die Sprite-Bewegungen waren zu schnell.
- Die GetString-Routine funktionierte bei gesetztem Bit ST_WR_BACK in dispBufferOn nicht korrekt, da alle Eingaben nur in den Hintergrundbildschirm geschrieben wurden.
- Fehler in DoDlgBox in MegaPatch128 behoben. Hier wurde das Flag DB_DblBit nicht immer korrekt gesetzt und bei einer Dialogbox ohne Schatten gar nicht gesetzt. Einige System-Icons wurden daher falsch am Bildschirm positioniert.
- Fehler in der Dateiauswahlbox in MegaPatch128 behoben. Hier wurde das DB_DblBit nicht gesetzt und in seltenen Fällen wurden System-Icons nur mit der halben Breite angezeigt.
- Fehler im RegisterMenü für MegaPatch128 behoben: Die Breite des Checkbox-Icon wurde immer verdoppelt, auch wenn der Optionsfeld-Rahmen nicht mit doppelter Breite definiert wurde. Dadurch wurde das Checkbox-Icon breiter als das eigentliche Optionsfeld angezeigt.
- Fehler beim öffnen eines GeoWrite-Dokuments auf einem NativeMode-Laufwerk behoben wenn anschließend in GeoWrite "Edit/Ausschneiden" gewählt wird.

BEHOBENE PROBLEME IN DEN TESTVERSIONEN 2018-2023
- MP3 lässt sich auf einem C128 mit RAMLink und SuperCPU nicht installieren (GEOS.Editor hängt sich auf bzw. GEOS.MakeBoot stürzt ab wegen fehlender Umschaltung auf 1MHz in den Laufwerkstreibern zu RAMDrive, RAMlink und CMDHD mit Parallelkabel)
- Die Systemstart-Meldungen wurden überarbeitet inkl. der Autorenhinweise.
- StartMP_64 unter GEOS128 als "Nur unter GEOS64 lauffähig" kennzeichnen.
- Im GEOS.Editor Klarstellung der Option C=REU-MoveData: Diese Option ist mit einer SuperCPU deaktiviert, da hier 16Bit-MoveData der SuperCPU verwendet wird.
- Systemstart-Meldungen aufräumen für einen übersichtlicheren Startvorgang.
- GEOS.Editor zeigt unter DESKTOP 2.x im 80Zeichen-Modus einige Icons mit der falschen Breite an. Dies liegt daran das DESKTOP das DblBit nicht aktiviert.
- Installationsfehler mit SuperCPU/RAMCard als GEOS-DACC und GeoRAM-Native-Laufwerk als Setup-Laufwerk (Quelle und Ziel) beseitigt. GRAM_BANK_SIZE wurde nicht ermittelt da SuperCPU/RAMCard=GEOS-DACC.
- RAM81-Laufwerke konnten nicht in Verbindung mit RAMLink-Laufwerken genutzt werden.
- Bei Verwendung einer CMDHD+CMDRAMLink+Parallelkabel wird bei NativeMode-Partitionen die falsche Laufwerksgröße angezeigt.
- Wechselt man bei MP128 das Laufwerk von dem aus der Editor gestartet wurde kann es zu einem Fehler kommen ("Editor teilweise zerstört...").
- Bei einem Update von GEOS MegaPatch auf eine neue Versionn stürzt das Update bei Verwendung eines GeoRAM-Native-Laufwerks als Ziel-Laufwerk ab.
- Einfrieren des Systems bei Verwendung eines TurboChameleon64 und dem PCDOS-Treiber: Der PCDOS-Laufwerkstreiber wird jetzt beim Zugriff auf das Laufwerk in den 1MHz-Modus geschaltet.
- Mit dem Update vom 26.12.2018 wurde die Routine zu Erkennung eines SD2IEC für die 1541/71/81- Laufwerkstreiber abgeändert, was zu zu Problemen unter MegaPatch128 führt, z.B. Absturz bei der Installation eines Laufwerks oder Pixelfehler im VDC-Bildschirm/80Z-Modus.
- Ein SD2IEC ohne "M-R"-Emulation wurde bei der Installation eines neuen Laufwerks auf eine andere Adresse getauscht. Das führt zu einem Systemabsturz.
- Im GEOS.Editor führte eine Änderung bei der Laufwerkserkennung dazu, das vorhandene Laufwerke ignoriert wurden.
- Der Versuch einen GeoRAM, CREU oder SuperRAM-Native-Treiber mehrfach zu installieren führt zu einem Systemabsturz.
- Das 1541-Shadow-Laufwerk nutzt den reservierten RAM-Speicher nicht und greift daher immer auf die Diskette zu anstatt Daten aus dem Shadow-RAM zu lesen.
- Beim beenden eines aktiven Tasks bleibt der TaskManager in einer Mausabfrage hängen, wenn die Maus zuvor vom Programm oder Kernal deaktiviert wurde.
- geoPublish stürzt bei der Installation ab, da im geänderten 1541-Laufwerkstreiber die erforderlichen Installationsdaten nicht mehr enthalten waren. Ab 3.3r10 behoben.
- Fehler beim einfügen von PhotoScraps in geoWrite auf 1581/NativeMode-Laufwerken behoben.
- MegaPatch128/geoPaint128 stürzt beim TaskWechsel ab. Der Fehler ist seit 3.3r9 enthalten und kann das System zum Absturz bringen wenn die Anwendung eine eigene Interrupt-Routine einbindet. Der Fehler kann, abhängig von der Anwendung, auch Auswirkungen auf MegaPatch64 haben.
- Setup für MegaPatch/DE und MegaPatch/US verwendete die gleichen Setup-Dateinamen.

ERWEITERUNGEN / ÄNDERUNGEN
- Der GEOS.Editor wurde um eine Fortschrittsanzeige beim Systemstart erweitert.
- In der Datei GEOS128.BOOT wird jetzt vor dem Zugriff auf die Register ab $Dxxx der I/O-Bereich aktiviert.
- Im GEOS.Editor wurde die Möglichkeit ergänzt die GEOS-Seriennummer zu ändern und zu speichern.
- Unterstützung von GeoRAM/C=REU mit 16Mb. Die Größe wird beim Systemstart angezeigt. Die Speichererweiterungen werden bei Verwendung als GEOS-DACC weiterhin nur bis 4Mb unterstützt.
- Neue Laufwerkstreiber GeoRAM-Native/C=REU-Native. Die Treiber erlauben es den ungenutzten Speicher einer GeoRAM/C=REU als RAM-Laufwerk zu nutzen, ähnlich dem SuperRAM-Treiber.
- HD-kompatibler-NativeMode-Treiber ohne Parallelkabel-Unterstützung für Support von DNP unter SD2IEC (IECBus NativeMode). Wurde durch den SD2IEC-Treiber ersetzt, ist aber noch im SourceCode verfügbar.
- Beim Start wird der erweiterte Speicher getestet, abfragen der erweiterten Speichergröße beim Start-Vorgang: Bei weniger als 192Kb Rückkehr zum BASIC.
- Neuer SD2IEC-Treiber: IECBus-NM funktioniert mit dem SD2IEC auf Grund der Einschränkungen im TurboDOS nur bis ca.8mb(127 Tracks). Der neue SD2IEC umgeht das Problem durch spezifische TurboDOS-Befehle. Daher funktioniert der Treiber nur noch mit SD2IEC.
- Auf SD2IEC/IECBusNM sind jetzt auch Unterverzeichnisse möglich.
- Bei allen Laufwerken wird jetzt beim lesen/screiben von Sektoren auf gültige Track/Sektor-Adressen geprüft.
- Änderung im Bereich 1581/NM-Laufwerken: Gemäß GEOS 2.x wird bei allen Laufwerkstypen der Diskname bei Byte $90 im BAM-Sektor eingeblendet. Anwendungen die den Disknamen ab Byte $04 in der BAM ändern funktionieren nicht mehr. Änderung entspricht dem Verhalten von GEOS 2.x!
- TaskManager128: Beim öffnen einer neuen Anwendung wird das Bildschirm-Flag ausgewertet und entsprechend der 40- oder 80-Zeichen-Bildschirm aktiviert.
- Im GEOS.Editor kann jetzt der Laufwerksmodus des SD2IEC zwischen 1541/1571/1581 oder SD2IEC/Native gewechselt werden.
- Wechsel des DiskImages auf SD2IEC ist mit dem GEOS.Editor möglich.
- Setzen der Mausgrenzen unter MP128 beim wechsel zwischen 40/80-Bildschirmmodus.
- CMD-HD-Kabel ist jetzt standardmäßig deaktiviert.
- Neue Option "GeoCalc-Fix" im GEOS.Editor unter "DRUCKER". Wenn der Druckertreiber im RAM gespeichert ist oder der Druckerspooler aktiv ist, dann wird die max. Größe von Druckertreibern reduziert um kompatibel mit GeoCalc zu sein.
- MegaPatch/Deutsch: Im GEOS.Editor wurde die Option "QWERTZ" ergänzt. Damit kann man die Tasten "Z" und "Y" auf der Tastatur zu tauschen. Funktioniert nicht mit geoKeys.
- :RealDrvMode unterstützt nun auch SD2IEC: Ist Bit #1 gesetzt dann ist das aktuelle Laufwerk ein SD2IEC-Laufwerk.
- Zusätzliche Adressen für Anwenderprogramme in allen Laufwerkstreibern ergänzt. Für eine genauere Beschreibung siehe Angaben im Handbuch für Programmierer.
- Im Register-Menü kann für BOX_ICON festgelegt werden, ob das Icon beim anklicken Blinken soll oder nicht. Zusätzlich kann man im GEOS.Editor die Voreinstellung für ältere Programme ändern.
- Neues Autostart-Programm GEOS.ColorEditor zum ändern der Systemfarben. Die Einstellungen werden dann beim Systemstart automatisch geladen.

BEKANNTE PROBLEME:
- Der InfoBlock bei GEOS.1 und GEOS.BOOT geht beim Update/MakeBoot verloren (GEOS-SaveFile-Routine löscht InfoBlock).
- Unter VICE führt ein Wechsel des Laufwerkstyps von 1581 nach 1571 zu einem instabielen Laufwerk. Bei Zugriff auf das Laufwerk hängt das System dann in einer Endlosschleife.

ANMERKUNGEN
Im ChangeLog zur Version von 2003 wurde folgende !änderung aufgelistet:
> Die Kernel-Routinen InitForIO und DoneWithIO wurden so geändert, daß
> bei Zugriffen auf Ram-Laufwerke nicht mehr auf 1Mhz zurückgeschaltet wird.

Dies ist nur teilweise richtig:
Die Routinen InitForIO und DoneWithIO verändern das CLKRATE-Register bei $D030 nicht mehr. Die RAM-Routinen für die C=REU hingegen setzen das Register weiterhin auf 1MHz. Ein Kommentar lässt vermuten das die für den C=REU-Chip erforderlich ist.

Die Version von 2003 ist in der Lage PC64 als Emulator zu erkennen. Beim Emulator VICE gibt es dazu keine Möglichkeit wenn man nicht zusätzliche Register einschaltet die das dann ermöglichen.

TopDesk64/128 und GeoDOS nutzen eigene Routinen zum Verlassen nach BASIC. Hier wird ein "Kaltstart" ausgeführt der bei der SuperCPU mit RAMCard den gesamten Speicher wieder freigibt.
DualTop nutzt systemkonform die GEOS-Routine "ToBASIC". Diese Routine führt nur einen "Warmstart" aus, der von MegaPatch reservierte Speicher der SuperCPU bleibt damit als "Reserviert" gekennzeichnet und steht auch nach der Nutzung anderer Programme für einen schnellen Neustart zur Verfügung.
Hinweis: Programme die das Speichermanagement der SuperCPU nicht beachten, können den Speicher der SuperCPU und damit den Systemspeicher von MegaPatch überschreiben.
Will man den gesamten Speicher der SuperCPU/RAMCard wieder freigeben ist es ausreichend ein 'SYS64738' auszuführen oder den C64 aus- und wieder einzuschalten.

TopDeskV4 zeigt für die neuen (unbekannten) Laufwerke GeoRAM-Native/C=REU-Native/IECBus-Native das 1581-Icon an. Mit TopDeskV5 sollte das Problem behoben sein.

Unter VICE/x128 kann ein falsches SETUP dazu führen das sich MegaPatch unter GEOS 2.x nicht installieren lässt (System hängt nach dem entpacken der Dateien). VICE sollte für Tests nur mit Standard-Einstellungen und ohne WARP-Modus verwendet werden! Dies kann evtl. auch auf den Fehler beim Wechsel des Laufwerktyps zurückzuführen sein (siehe bekannte Probleme).

Die Autostartdatei 'RUN_DUALTOP' startet die DeskTop-Oberfläche "DUAL_TOP" automatisch beim Systemstart. Der Nachteil des Startprogrammes ist das hier auch der erste Drucker- und Maustreiber auf Disk installiert wird, egal welcher Treiber in GEOS.Editor eingestellt ist.

geoCalc64 stürzt bei der Verwendung von Druckerspooler oder "Druckertreiber im RAM" beim drucken einer Datei ab. Das Problem liegt an geoCalc selbst das einen für die Druckertreiber reservierten Speicherbereich nutzt (Adresse $7F3F, Aufruf aus geoCalc ab $5569). Siehe "GeoCalc-Fix"-Option im GEOS.Editor (nur MegaPatch64).

Es gibt mit V3.3r7 auch TurboDOS-freie Laufwerkstreiber. Diese sind zwar extrem langsam, können aber als Grundlage für neue Laufwerke ohne FloppySpeeder verwendet werden.

MEGAPATCH 64/128 * 1998-2023
Markus Kanet
