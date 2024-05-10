# Project Hell
SA:MP server from the ground up in 2024, because im crazy like that

### current includes, plugins and stuff

- **[open.mp 1.2.0.2670](https://github.com/openmultiplayer)**  
- **[iZCMD 0.2.3.0](https://github.com/YashasSamaga/I-ZCMD)**
- **[easyDialog 2.0](https://github.com/Awsomedude/easyDialog)**
- **[sscanf 2.13.8](https://github.com/Y-Less/sscanf/)**
- **[rBits 1.0.0](https://github.com/Mergevos/pawn-rbits)**
- **[Pawn.Regex 1.2.3-omp](https://github.com/katursis/Pawn.Regex)**
- **[streamer 2.9.6](https://github.com/samp-incognito/samp-streamer-plugin)** !!
- **[MapAndreas 1.2.1](https://github.com/philip1337/samp-plugin-mapandreas)**

> - **CONCEPT:** 
>   - when catching cheaters, instead of an actual ban, shadowban the player, which
>       - blocks every activity for the player on the server, where they could exploit the cheats for gain
>       - puts them away from legit players
>   - with this system, if somebody just wants to fly around, they can, but they cant use their cheats to gain eg. money
>   - ban is reserved for extreme cases, eg. cheats that lag the server, cheats that are difficult to catch etc.

## changelog
- BUILD 29-revision (latest build) last edited: 5/10/2024
    - created the minigame menu
        - started a script for a minigame inspired by Alice In Borderland (Scale) - idea by White
    - **new includes**:
        - **easyDialog**: anti-spoofing, easier way to handle dialogs
        - **streamer**: i fucking hate limits
        - ~~**mathutil:** this shit~~ maybe not
        - **MapAndreas**, allows me to properly use the OnPlayerClickMap teleport MIGHT CAUSE PERFORMANCE ISSUES THO
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
    - most of the server is now translated to English -> some comments may remain in Hungarian, im way too lazy to translate those too
    - SetPlayerMoney function for better code clarity
    - added database table "User_Settings" for certain you know, user settings and all queries are now up to date to this change
    - welcoming message based on the time of the day (good morning, good evening etc.)

- BUILD 28
    - functions handling money now actually work
    - fixed a few issues with the spawning system, hopefully they work as intended now

- BUILD 27
    - **RCON safety features implemented**
    - fixed in an issue where players that are not ID 0 are kicked by the server

- BUILD 0-26 
    - the server now uses SQLite instead of Y_Ini
    - login system implemented
    - some values such as money are now handled by the database, allowing values up to 9,223,372,036,854,775,807 to be stored
    - implemented a few common commands
    - registration is now toggleable