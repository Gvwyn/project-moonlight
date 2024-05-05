# Project Hell - SA:MP szerver @ open.mp

### jelenlegi includeok, pluginok stb...

- **[open.mp 1.2.0.2670](https://github.com/openmultiplayer)**  
- **[iZCMD](https://github.com/YashasSamaga/I-ZCMD)**
- **[easyDialog](https://github.com/Awsomedude/easyDialog)**
- **[sscanf](https://github.com/Y-Less/sscanf/)**
- **[rBits](https://github.com/Mergevos/pawn-rbits)**
- **[Pawn.Regex](https://github.com/katursis/Pawn.Regex)**


## changelog

- BUILD 0-26
    - Y_INI levaltva -> SQLite
    - login&reg rendszer, ehhez meno hatter
    - penz erteke 64 bites limitek kozott az alap 32 helyett
    - nehany alap parancs  
    - reg ki-be kapcsolhato
  
- BUILD 26
    - **RCON ENTRY vedelem**
    - javitva egy hiba ami miatt kidob mindenkit aki nem ID 0

- BUILD 27
    - penzt kezelo parancsok mostmar mukodnek
    - spawnolassal kapcsolatos javitasok, amik lehet nem fognak mukodni rendesen

- BUILD 28-revision: atnevezve!
    - minigame menu letrehozva
        - elkezdtem a merleg minigamet, amit White ajanlott, innen is puszi
    - **easyDialog** include-t hasznalok mostmar, bolond dialog spoofing ellen
    - ora jobb fentre, HH:MM formatumban (meg lehet csinositani rajta)
    - /v parancs ~~mostmar letiltja a vonatokat~~ vonatokat IS le lehet kerni :)
    - mostmar nem rakja vissza 60 sec utan a jarmuveket oda, ahova lespawnoltuk
    - **anti-cheat** kezdete: nem tudsz tobbe penzt addolni magadnak csalassal
        - a penzt csakis az adatbazisban van hivatalosan manipulalva, igy ha elteres van a jatekos baszott el valamit
    - /setadmin parancs, plusz egyeb admin parancsok -> javitva az admin szintek lekerese
    - /kill & /kys parancs
    - updated chat kiiras formatum
        - PLAYER (ID): \<TEXT\>
    - **publikus teleportok** (ls, lv, sf etc.) -> ezeket konnyu lesz boviteni
        - letrehoztam jopar alap teleportot ~30 db
    - **anti-ip**-kiiras, 5 sorban Regex-nek koszonhetoen (gecisok idobe telt mukodesre birni...)

> language support soon!
