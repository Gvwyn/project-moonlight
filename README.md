# Project Hell
SA:MP server from the ground up in 2024, because im crazy like that

### current includes and plugins the server utilizes

- **[open.mp 1.2.0.2670](https://github.com/openmultiplayer)**  
- **[iZCMD 0.2.3.0](https://github.com/YashasSamaga/I-ZCMD)**
- **[easyDialog 2.0](https://github.com/Awsomedude/easyDialog)**
- **[sscanf 2.13.8](https://github.com/Y-Less/sscanf/)**
- **[rBits 1.0.0](https://github.com/Mergevos/pawn-rbits)**
- **[Pawn.Regex 1.2.3-omp](https://github.com/katursis/Pawn.Regex)**
- **[streamer 2.9.6](https://github.com/samp-incognito/samp-streamer-plugin)** !!

## changelog

- BUILD 0-26
    - the server now uses SQLite instead of Y_Ini
    - login system implemented
    - some values such as money is now handled by the database, allowing values up to 9,223,372,036,854,775,807 to be stored
    - implemented a few common commands  
    - registration is now toggleable
  
- BUILD 26
    - **RCON safety features implemented**
    - fixed in an issue where players that are not ID 0 are kicked by the server

- BUILD 27
    - functions handling money now actually work
    - fixed a few issues with the spawning system, hopefully they work as intended now

- BUILD 28-revision: *renamed!*
    - created the minigame menu
        - started a script for a minigame inspired by Alice In Borderland (Scale) - idea by White
    - **new includes**:
        - **easyDialog**: anti-spoofing, easier way to handle dialogs
        - **streamer**: i fucking hate limits
        - ~~**mathutil:** this shit~~ maybe not
    - wrote my own IsNaN function because mathutil gave me a fucking headache (and it also didnt work)
    - added a world clock to the top right corner, currently displaying GMT+2 time
    - /v now allows trains to be spawned (its a bit wacky if i do say so myself lmao)
    - fixed an issue where vehicles spawned from /v were teleported back to the location they were spawned at after 60 seconds
    - the beginning of an **anti-cheat**: you cant give yourself money with cheats anymore
        - the money is only manipulated on the server side, meaning if the player has the wrong amount, the player is at fault
    - /setadmin command, plus a few admin commands
    - /kill & /kys commands
    - updated public chat format
        - PLAYER (ID): \<TEXT\>
    - **public teleports** (ls, lv, sf etc.) -> i made it easy to expand later
        - i created roughly 30 teleports (for now)
    - **anti-advert**, now IP addresses and suspicious domain names are blocked by the server


> language support soon!  

> - **CONCEPT:** 
>   - when catching cheaters, instead of an actual ban, shadowban the player, which
>       - blocks every activity for the player on the server, where they could exploit the cheats for gain
>       - puts them away from legit players
>   - with this system, if somebody just wants to fly around, they can, but they cant use their cheats to gain eg. money
>   - ban is reserved for extreme cases, eg. cheats that lag the server, cheats that are difficult to catch etc.