#include <open.mp>
#include <global_vars>
#include <streamer>
#include <mapandreas>
#include <map-zones>
#include <easyDialog>
#include <Pawn.Regex>
#include <rBits>
#include <izcmd>
#include <sscanf2>
#define MAX_PLAYERS 30
#pragma warning disable 201, 214
// csuf rettenet

#define PRESSED(%0) \
    (((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))

// some cached values
new WelcomingMessage = 0;
new g_PlayerCash[MAX_PLAYERS] = {0, ...};
new g_PlayerActionCooldown[MAX_PLAYERS] = {0, ...}; // cooldown for commands and clickmap teleports (this saves the last tick the player used a command/teleported)
new g_PlayerCooldownViolations[MAX_PLAYERS] = {0, ...}; // strikes per player

// more player data cache + database declaration
new
    Bit1: g_PlayerLogged<MAX_PLAYERS>, // 0 & 1
    Bit1: g_PlayerIsSpectating<MAX_PLAYERS>,
    Bit8: g_AdminLevel<MAX_PLAYERS>,
    Bit16:g_PlayerUID<MAX_PLAYERS>,
    Bit16:g_PlayerSkin<MAX_PLAYERS>,
    DB: Database
;

// X.X.X.X.X:PORT & SUSPICIOUS DOMAIN NAMES
stock AdvertCheck(text[])
{
    static Regex:regex;
    if (!regex) regex = Regex_New(".*\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b|\\b(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}\\b.*");
    return Regex_Check(text, regex);
}

forward UpdateClock();
forward IssueCooldownViolation(playerid);
forward ResetCooldownViolation(playerid);
forward KickPlayer(playerid);
forward BanPlayer(playerid, reason[]);
forward SetMapIconsForPlayer(playerid);
forward SetPlayerSkinFromFs(playerid, skinid); // updates the g_PlayerSkin value, called from filterscripts
forward TeleportPlayerToPublicTp(playerid, areVehiclesAllowed, Float:x, Float:y, Float:z, Float:angle);
forward ResetPlayerCar(playerid);
forward CameraPan(playerid);
forward SpawnPlayerFromCamPan(playerid);

/*
sets the player's money to a value  
*optionally, adds/substracts money too before updating everything*
<playerid\> who
<amount\> the amount to set it to << set this to g_PlayerCash[playerid] if you only want to add/take
<add\> *optional* how much $$ to add/subtract
@returns 0 or 1 based on succession
*/
SetPlayerMoney(playerid, amount, add = 0)
{
    g_PlayerCash[playerid] = amount+add;
    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, amount+add);
    return 1;
}

/*
get hex value from #FFFFFF etc.etc.
i hope whoever decided on this is now suffering in the 8th circle of hell
*/
GetFuckingColors(input[])
{
    new colorStr[9];
    new color;
    strcat(colorStr, input);
    strcat(colorStr, "FF"); // add alpha value otherwise this piece of fucking shit doesnt work
    sscanf(colorStr, "x", color);
    return color;
}

main()
{
	printf(" =======================================");
	printf("  The machine has started, %s", VERSION);
	printf(" =======================================");
}

public OnRconLoginAttempt(ip[], password[], success)
{
    new ipAddress[16];
    new name[MAX_PLAYER_NAME];
    new playerid = -1;
    new authorizedLogin = false;
    for (new id = 0; id < MAX_PLAYERS; id++)
    {
        if (!IsPlayerConnected(id)) continue;
        GetPlayerIp(id, ipAddress, sizeof(ipAddress));
        if (!strcmp(ip, ipAddress, true)){ GetPlayerName(id, name, sizeof(name)); playerid = id; }
    }

    // dont fuck admins pretty please
    for (new n = 0; n < countAdmins; n++)
    {
        if(!strcmp(name, Admins[n])) authorizedLogin = true;
    }

    if (!success && playerid != -1 && !authorizedLogin)
    {
        printf("[warning] RCON login attempt from IP %s, player %s (ID: %i). Kicking player.", ip, name, playerid);
        SendClientMessage(playerid, 0xFF0000FF, "[RCON] You didn't think this through, now did you?");
        PlayerPlaySound(playerid, 39000, 0.0, 0.0, 0.0); 
        BlockIpAddress(ipAddress, 5 * 60 * 1000); // 5 perces ban
        return 1;
    }

    else if (success && playerid != -1 && !authorizedLogin)
    {
        printf("[error] Successful RCON login from IP %s, player %s (ID: %i)", ip, name, playerid);
        printf("[error] Banning player & shutting down server for safety.");
        PlayerPlaySound(playerid, 39000, 0.0, 0.0, 0.0); // lmao
        BanEx(playerid, "unathorized RCON login");
        SendRconCommand("exit");
        return 1;
    }
    return 1;
}

public OnGameModeInit()
{
    Database = DB_Open("Server.db");
    MapAndreas_Init(MAP_ANDREAS_MODE_FULL, MAP_ANDREAS_FULL_FILE);

	if(Database)
	{
	    print("[SQLite] Database loaded.");
	}
    else
    {
        print("[SQLite] Failed to load database, shutting down server.");
        exit;
    }

	SetServerRule("reg", "On");
	SetSVarInt("Reg", 1); // 0 OFF, 1 ON
	ToggleChatTextReplacement(true); // % >> #
	SetGameModeText(GAMEMODE);
    SendRconCommand("game.map %s", VERSION);

    new hours, minutes, seconds;
    gettime(hours, minutes, seconds);
    Clock = TextDrawCreate(546.5, 21.0, "%02d:%02d", hours, minutes);
	TextDrawLetterSize(Clock, 0.65, 2.4);
	TextDrawFont(Clock, TEXT_DRAW_FONT_3);
    SetTimer("UpdateClock", 1000, true);
    return 1;
}

public OnGameModeExit()
{
    DB_Close(Database);
    return 1;
}

public OnPlayerUpdate(playerid)
{
    // anti-money cheat
    // if the player has more/less money than whats in the database, reset the player's hand
    if(Bit1_Get(g_PlayerLogged, playerid) == 1 && IsPlayerSpawned(playerid))
    {
        if (GetPlayerMoney(playerid) != g_PlayerCash[playerid])
        {
            ResetPlayerMoney(playerid);
            GivePlayerMoney(playerid, g_PlayerCash[playerid]);
            return 1;
        }
    }
    return 1;
}

public OnPlayerSpawn(playerid)
{
    new name[MAX_PLAYER_NAME]; GetPlayerName(playerid, name, sizeof(name));
    TextDrawShowForPlayer(playerid, Clock);
	if(Bit1_Get(g_PlayerLogged, playerid) == 0)
	{
        printf("[kick] Kicking %s (ID: %i), because they spawned without logging in.", name, playerid);
	    Kick(playerid);
 	}
}

/*
public OnClientCheckResponse(playerid, actionid, memaddr, retndata)
{
    if (actionid == 0x48)
    {
        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));
        printf("WARNING: %s might be a bot, or from a phone", name);
        Kick(playerid);
    }
    return 1;
}
*/

// updates the textdraw clock and also updates the welcoming message
public UpdateClock()
{
    // clock
    new hours, minutes, seconds;
    gettime(hours, minutes, seconds);
    TextDrawSetString(Clock, "%02d:%02d", hours, minutes);

    // welcoming message
    if (4 < hours && hours < 10)       WelcomingMessage = 0;
    else if (10 < hours && hours < 15) WelcomingMessage = 1;
    else if (15 < hours && hours < 18) WelcomingMessage = 2;
    else if (18 < hours && hours < 21) WelcomingMessage = 3;
    else WelcomingMessage = 4;
    return 1;
}

// returns 1 if player received violation, returns 0 if the player hit the violation limit
public IssueCooldownViolation(playerid)
{
    if(g_PlayerCooldownViolations[playerid] < MAX_VIOLATIONS)
    {
        g_PlayerCooldownViolations[playerid]++;
        return 1;
    }
    else
    {
        SendClientMessage(playerid, 0xFF0000FF, "You were kicked by the server for spamming.");
        SetTimerEx("KickPlayer", 100, false, "i", playerid);
        return 0;
    }
}

public ResetCooldownViolation(playerid) g_PlayerCooldownViolations[playerid] = 0;

public KickPlayer(playerid) Kick(playerid);
public BanPlayer(playerid, reason[]) BanEx(playerid, reason);

public SetMapIconsForPlayer(playerid)
{
    // Los Santos
    SetPlayerMapIcon(playerid, 0, 67.781417, -300.643035, 28.137821, 36, 0, MAPICON_LOCAL);     // spawn
    SetPlayerMapIcon(playerid, 1, 1164.010986, -1339.689086, 31.498193, 22, 0, MAPICON_LOCAL);  // los santos hospital
    SetPlayerMapIcon(playerid, 2, 1555.339233, -1670.605712, 28.395606, 30, 0, MAPICON_LOCAL);  // lspd
    SetPlayerMapIcon(playerid, 3, 1729.310180, -1463.117919, 33.023437, 20, 0, MAPICON_LOCAL);  // lsfd
    SetPlayerMapIcon(playerid, 4, 2580.000000, -2450.891601, 13.622326, 9, 0, MAPICON_LOCAL);   // ls docks
    SetPlayerMapIcon(playerid, 5, 2413.511474, -1218.122680, 32.734375, 49, 0, MAPICON_LOCAL);  // ls night club
    SetPlayerMapIcon(playerid, 6, 1961.646972, -2201.687500, 13.546875, 5, 0, MAPICON_LOCAL);   // ls airport
    SetPlayerMapIcon(playerid, 7, 681.552185, -473.346588, 16.536296, 17, 0, MAPICON_LOCAL);    // dilli club
    return 1;
}

public SetPlayerSkinFromFs(playerid, skinid) Bit16_Set(g_PlayerSkin, playerid, skinid);

// az osszes publikus teleportot ezzel lehet hasznalni
// igy 1x kell a logikat megirnom, utana a teleportokat 1 sorral be tudom rakni
public TeleportPlayerToPublicTp(playerid, areVehiclesAllowed, Float:x, Float:y, Float:z, Float:angle)
{
    if (GetPlayerInterior(playerid) != 0) 
    {
        SendClientMessage(playerid, 0xFF0000FF, "You're not allowed to teleport from interiors.");
        return 1;
    }

    // ha a jatekos BENNE van egy jarmube es a vezeto (0)
    // ha minden igaz GetPlayerVehicleSeat (-1)-et dob vissza ha nincs jarmube
    if(GetPlayerVehicleSeat(playerid) == 0)
    {
        if (!areVehiclesAllowed)
        {
            SendClientMessage(playerid, 0xFF0000FF, "You're not allowed to teleport here with a vehicle.");
            return 1;
        }
        new vehicleid = GetPlayerVehicleID(playerid);
        SetVehicleZAngle(vehicleid, angle);
        SetVehiclePos(vehicleid, x, y, z);
        SetCameraBehindPlayer(playerid);
        return 1; 
    }
    else
    {
        SetPlayerFacingAngle(playerid, angle);
        SetPlayerPos(playerid, x, y, z);
        SetCameraBehindPlayer(playerid);
        return 1;
    }
}

// does NOT check whether or not the player is in a vehicle!!!
public ResetPlayerCar(playerid)
{
    new vehid = GetPlayerVehicleID(playerid);
    new Float:pX, Float:pY, Float:pZ, Float:vehZ;
    GetVehiclePos(vehid, pX, pY, pZ);
    GetVehicleZAngle(vehid, vehZ);
    SetVehiclePos(vehid, pX, pY, pZ);
    SetVehicleZAngle(vehid, vehZ);
    return 1;
}

// AGYBASZAS
public CameraPan(playerid)
{
    // ezekkel probalom lekuzdeni azt a hibat, hogy neha visszadob spawnolas utan ????MIERT????
    if (IsPlayerSpawned(playerid)) return 1; // ha le van spawnolva, ne bassza el a kamerat
    // if (Bit1_Get(g_PlayerIsSpectating, playerid) == 1) return 1; // ha spectate modbol nem lett hivatalosan kiteve, szinten ne

    new playingScene = GetPVarInt(playerid, "camera");
    InterpolateCameraPos(playerid, scenesData[playingScene][0], scenesData[playingScene][1], scenesData[playingScene][2], scenesData[playingScene][3], scenesData[playingScene][4], scenesData[playingScene][5], floatround(scenesData[playingScene][12], floatround_unbiased), CAMERA_MOVE);
    InterpolateCameraLookAt(playerid, scenesData[playingScene][6], scenesData[playingScene][7], scenesData[playingScene][8], scenesData[playingScene][6], scenesData[playingScene][7], scenesData[playingScene][8], floatround(scenesData[playingScene][12], floatround_unbiased), CAMERA_MOVE);
    SetPlayerWeather(playerid, floatround(scenesData[playingScene][9], floatround_unbiased));
    SetPlayerTime(playerid, floatround(scenesData[playingScene][10], floatround_unbiased), floatround(scenesData[playingScene][11], floatround_unbiased));

    if (GetPVarInt(playerid, "camera") < CameraScenes-1) SetPVarInt(playerid, "camera", GetPVarInt(playerid, "camera")+1);
    else SetPVarInt(playerid, "camera", 0);

    CameraPanTimer[playerid] = SetTimerEx("CameraPan", floatround(scenesData[playingScene][12], floatround_unbiased)+100, false, "ii", playerid);
    return 1;
}

public SpawnPlayerFromCamPan(playerid)
{
    SetSpawnInfo(playerid, NO_TEAM, Bit16_Get(g_PlayerSkin, playerid), -50.000122, -278.878814, 5.429687, 180.0, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    KillTimer(CameraPanTimer[playerid]); // ???? ez valamiert neha nem torli rendesen
    DeletePVar(playerid, "camera");
    SetPlayerWeather(playerid, 0);
    SetPlayerTime(playerid, 22, 0);
    SetPlayerVirtualWorld(playerid, 0);
    // printf("%i", CameraPanTimer);
    SetCameraBehindPlayer(playerid);
    SpawnPlayer(playerid);
    Bit1_Set(g_PlayerIsSpectating, playerid, 0);
    return 1;
}

public OnPlayerConnect(playerid)
{
    // if (!IsPlayerUsingOfficialClient(playerid)) Kick(playerid);
    // SendClientCheck(playerid, 0x48, 0, 0, 2);
    TogglePlayerSpectating(playerid, true);
    new randomscene = random(CameraScenes);
    SetPVarInt(playerid, "camera", randomscene);
    Bit1_Set(g_PlayerIsSpectating, playerid, 1); // disables the SPAWN button
    SetTimerEx("CameraPan", 250, false, "i", playerid);
    SetPlayerVirtualWorld(playerid, 255);
    SetMapIconsForPlayer(playerid);
    new
        DBResult: Result,
        name[MAX_PLAYER_NAME],
        ip[16],
        serial[41]
    ;
    
    GetPlayerName(playerid, name, sizeof(name));
    Result = DB_ExecuteQuery(Database, "SELECT `Player`, `GPCI` FROM `Players` WHERE `Player` = '%s' COLLATE NOCASE", DB_Escape(name));
    
    GetPlayerIp(playerid, ip, sizeof(ip));
    GPCI(playerid, serial, sizeof(serial)); // player's current GPCI
    
    Bit1_Set(g_PlayerLogged, playerid, false);

    SendClientMessage(playerid, 0xFFFFFFAA, "%s, {00FFFF}%s{FFFFFF}!", WelcomingMessages[WelcomingMessage], name);
	SendClientMessageToAll(0x00FFFFFF, "%s {FFFFFF}has joined the server.", name);
    SendDeathMessage(INVALID_PLAYER_ID, playerid, 200);
    if(DB_GetRowCount(Result))
    {
        new DB_serial[41]; DB_GetFieldStringByName(Result, "GPCI", DB_serial); //  GPCI a DB-bol
        // ha letezik a fiok, de a GPCI nem egyezik az DB-vel ...
     	if (strcmp(DB_serial, serial))
 		{
 		    printf("[kick] Kicking player #%i %s for GPCI mismatch. %s -- %s", playerid, name, DB_serial, serial);
	 	    BlockIpAddress(ip, 15 * 60 * 1000); // ... 15 percre kitiltja az IP cimet
	 	    return 1;
 		}
 		SetPVarInt(playerid, "login", 0);
        Dialog_Show(playerid, LOGIN, DIALOG_STYLE_PASSWORD, "{00FF00}Login", "{FFFFFF}Your name is registered.\n\nEnter your password below:", "{00FF00}Login", "{FF0000}Kick");
    }
    else
    {
        // if reg is off, block the player's ip for 15 minutes
        if (GetSVarInt("reg") == 0)
		{
            printf("[ban] Kicking player #%i %s, because registration is currently disabled.", playerid, name);
		    BlockIpAddress(ip, 15 * 60 * 1000); // 15 perc
            return 1;
		}
		
        Dialog_Show(playerid, REGISTER, DIALOG_STYLE_PASSWORD, "{00FF00}Account registration", "{FFFFFF}Your name is {FF0000}not {FFFFFF}registered.\n\nEnter a password below to register an account:", "{00FF00}Register", "{FF0000}Kick");
    }
    DB_FreeResultSet(Result);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    new playerName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, playerName, MAX_PLAYER_NAME);
    new reasons[5][] =
    {
        "crashed",
        "left the server",
        "has been kicked",
        "disappeared into thin air",
        "has been automatically kicked"
    };
    SendDeathMessage(INVALID_PLAYER_ID, playerid, 201);
    SendClientMessageToAll(-1, "{AAAAAA}%s {DDDDDD}%s.", playerName, reasons[reason]);

    // player's skin choice is saved when the player leaves the server
    DB_ExecuteQuery(Database, "UPDATE `User_Settings` SET `PlayerSkinID` = %i WHERE `UID` = '%i'", GetPlayerSkin(playerid), Bit16_Get(g_PlayerUID, playerid));
    Bit1_Set(g_PlayerLogged, playerid, false);
    Bit1_Set(g_PlayerIsSpectating, playerid, false);
    Bit8_Set(g_AdminLevel, playerid, 0);
    Bit16_Set(g_PlayerSkin, playerid, 0);
    Bit16_Set(g_PlayerUID, playerid, -1); // -1 to prevent bullshit from happening
    g_PlayerCash[playerid] = 0;
    g_PlayerActionCooldown[playerid] = 0;
    g_PlayerCooldownViolations[playerid] = 0;
    return 1;
}

public OnPlayerText(playerid, text[])
{
    if (GetTickCount() - g_PlayerActionCooldown[playerid] <= CHAT_COOLDOWN)
    {
        IssueCooldownViolation(playerid);
        new Float:cooldown = ( CHAT_COOLDOWN - float( GetTickCount() - g_PlayerActionCooldown[playerid] ) ) / 1000;
        SendClientMessage(playerid, 0xFF0000FF, "Slow down there, partner. Wait another %.2f seconds.", cooldown);
        return 0;
    }
    ResetCooldownViolation(playerid);

    if (AdvertCheck(text) == 1)
    {
        SendClientMessage(playerid, 0xFF0000FF, "You're not allowed to type IP addresses on the public chat.");
        // SetTimerEx("KickPlayer", 250, false, playerid);
        return 0;
    }

    else if (!IsPlayerSpawned(playerid)) return 0;

    new name[MAX_PLAYER_NAME]; GetPlayerName(playerid, name, sizeof(name));
    SendClientMessageToAll(GetPlayerColor(playerid), "%s (%i){DDDDDD}: %s", name, playerid, text);
    SetPlayerChatBubble(playerid, text, -1, 100.0, 10000);
    return 0;
}

public OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    SendDeathMessage(killerid, playerid, reason);
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, WEAPON:weaponid, bodypart)
{
    // headshots are instakill
    if (issuerid != INVALID_PLAYER_ID && bodypart == 9)
    {
        SetPlayerHealth(playerid, 0.0);
    }
    return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
    if (GetTickCount() - g_PlayerActionCooldown[playerid] <= GLOBAL_COOLDOWN)
    {
        IssueCooldownViolation(playerid);
        new Float:cooldown = ( GLOBAL_COOLDOWN - float( GetTickCount() - g_PlayerActionCooldown[playerid] ) ) / 1000;
        SendClientMessage(playerid, 0xFF0000FF, "You're trying to teleport too fast. Wait another %.2f seconds.", cooldown);
        return 1;
    }
    ResetCooldownViolation(playerid);

    new Float:pZ;
    g_PlayerActionCooldown[playerid] = GetTickCount();

    if (GetPlayerInterior(playerid) != 0)
    {
        SendClientMessage(playerid, 0xFF0000FF, "You're not allowed to teleport from interiors.");
        return 1;
    }

    if (!MapAndreas_FindAverageZ(fX, fY, pZ))
    {
        SendClientMessage(playerid, 0xFF0000FF, "Teleport failed.");
        return 1;
    }

    pZ += 1.0; // little height to prevent getting stuck in the ground

    // SetPlayerInterior(playerid, 0);
	if(IsPlayerInAnyVehicle(playerid) && GetVehicleDriver(GetPlayerVehicleID(playerid)) == playerid)
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        new Float:vehZ;
        GetVehicleZAngle(vehicleid, vehZ);
        SetVehiclePos(vehicleid, fX, fY, pZ);
        SetVehicleZAngle(playerid, vehZ);
    }
	else
	{
    	SetPlayerPos(playerid, fX, fY, pZ);
	}
    new MapZone:zone = GetMapZoneAtPoint2D(fX, fY);
    new zonename[MAX_MAP_ZONE_NAME];
    if (zone == INVALID_MAP_ZONE_ID) { strcopy(zonename, UNKNOWN_ZONE_NAME, 12); }
    else GetMapZoneName(zone, zonename);
    SendClientMessage(playerid, 0x00FF00FF, "You teleported to {88FF88}%s {00FF00}at %.2f, %.2f, %.2f.", zonename, fX, fY, pZ);
    return 1;
}

public OnPlayerStateChange(playerid, PLAYER_STATE:newstate, PLAYER_STATE:oldstate)
{
	// hippity hoppity this is now my property
    if ((oldstate == PLAYER_STATE_ONFOOT && newstate == PLAYER_STATE_DRIVER) || (oldstate == PLAYER_STATE_DRIVER && newstate == PLAYER_STATE_DRIVER))
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        AddVehicleComponent(vehicleid, 1010);
		// SetVehicleHealth(vehicleid, INFINITY); // hat ez nem igy mukodik xdd
    }
    return 1;
}

public OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
    // add nitro whenever the player activates it
    if (PRESSED(KEY_FIRE))
    {
        if (IsPlayerInAnyVehicle(playerid))
        {
            AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
        }
    }

    // stops the vehicle instantly
    if (PRESSED(KEY_NO))
    {
        if (IsPlayerInAnyVehicle(playerid))
        {
            ResetPlayerCar(playerid);
        }
    }
    return 1;
}

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if (GetTickCount() - g_PlayerActionCooldown[playerid] <= GLOBAL_COOLDOWN)
    {
        IssueCooldownViolation(playerid);
        new Float:cooldown = ( GLOBAL_COOLDOWN - float( GetTickCount() - g_PlayerActionCooldown[playerid] ) ) / 1000;
        SendClientMessage(playerid, 0xFF0000FF, "Calm down there, partner. Wait another %.2f seconds.", cooldown);
        return 0;
    }
    ResetCooldownViolation(playerid);

    if(Bit1_Get(g_PlayerLogged, playerid) == 0)
    {
        SendClientMessage(playerid, 0xFF0000FF, "You can't use commands until you log in.");
        return 0;
    }

    else if (!IsPlayerSpawned(playerid) || Bit1_Get(g_PlayerIsSpectating, playerid) == 1)
    {
        SendClientMessage(playerid, 0xFF0000FF, "You can't use commands until you spawn.");
        return 0;
    }
	return 1;
}

public OnDialogPerformed(playerid, const dialog[], response, success)
{
    return 1;
}

// FROM THIS POINT ON, ONLY COMMANDS & THEIR DIALOGS SHOULD BE DEFINED
// NOTHING ELSE

Dialog:LOGIN(playerid, response, listitem, inputtext[])
{
    new
        DBResult: Result,
        name[MAX_PLAYER_NAME],
        ip[16],
        serial[41]
    ;

    GetPlayerName(playerid, name, sizeof(name));
    GetPlayerIp(playerid, ip, sizeof(ip));
    GPCI(playerid, serial, sizeof(serial));

    if(response)
    {
        Result = DB_ExecuteQuery(Database, "SELECT players.UID, `Player`, `Password`, `Score`, `Admin`, `PlayerSkinID`, `PlayerColor`, \
        printf('%%d', CASE \
        WHEN `Cash` < -999999999 THEN -999999999 \
        WHEN `Cash` > 999999999 THEN 999999999 \
        ELSE `Cash` END) AS clampCash \
        FROM `Players`, `User_Settings` WHERE players.UID = user_settings.UID AND `Player` = '%s' COLLATE NOCASE AND `Password` = '%s'", DB_Escape(name), DB_Escape(inputtext));
        if(DB_GetRowCount(Result))
        {
            new Field[16]; // what the fuck
            DB_GetFieldStringByName(Result, "UID", Field);
            Bit16_Set(g_PlayerUID, playerid, strval(Field));
            DB_GetFieldStringByName(Result, "PlayerSkinID", Field);
            Bit16_Set(g_PlayerSkin, playerid, strval(Field));
            DB_GetFieldStringByName(Result, "PlayerColor", Field);
            new color = GetFuckingColors(Field);
            SetPlayerColor(playerid, color);
            DB_GetFieldStringByName(Result, "Score", Field);
            SetPlayerScore(playerid, strval(Field));
            DB_GetFieldStringByName(Result, "clampCash", Field, 21);
            SetPlayerMoney(playerid, strval(Field));
            DB_GetFieldStringByName(Result, "Admin", Field, 4);
            Bit8_Set(g_AdminLevel, playerid, strval(Field));
            Bit1_Set(g_PlayerLogged, playerid, true);
            Bit1_Set(g_PlayerIsSpectating, playerid, false); // visszakapcsolja a SPAWN gombot, es ezt el is menti 
            TogglePlayerSpectating(playerid, false);
            SendClientMessage(playerid, 0x00FF00AA, "You successfully logged in.");
            SetTimerEx("SpawnPlayerFromCamPan", 100, false, "i", playerid);
        }
        // wrong password
        else
        {
            SetPVarInt(playerid, "logins", GetPVarInt(playerid, "logins")+1);
            if (GetPVarInt(playerid, "logins") == 3) 
            {
                Dialog_Close(playerid);
                BlockIpAddress(ip, 5 * 60 * 1000); // blocks the IP for 5 minutes
                return 1;
            }
            Dialog_Show(playerid, LOGIN, DIALOG_STYLE_PASSWORD, "{00FF00}Login", "{FF0000}The password you entered is incorrect, try again. {FFFFFF}({FF0000}%i{FFFFFF}/{FF0000}3{FFFFFF})", "{00FF00}Login", "{FF0000}Kick", GetPVarInt(playerid, "logins"));
        }
        DB_FreeResultSet(Result);
    }
    else 
    {
        printf("[kick] Kicking player ID %i %s for trying to skip logging in.", playerid, name);
        return Kick(playerid);
    }
    return 1;
}

Dialog:REGISTER(playerid, response, listitem, inputtext[])
{
    new
        name[MAX_PLAYER_NAME],
        serial[41]
    ;

    GetPlayerName(playerid, name, sizeof(name));
    GPCI(playerid, serial, sizeof(serial));

    if(response)
    {
        if(strlen(inputtext) > 64 || strlen(inputtext) < 4 || strfind(inputtext, "  ") != -1 || strfind(inputtext, "%%") != -1)
        {
            Dialog_Show(playerid, REGISTER, DIALOG_STYLE_PASSWORD, "{00FF00}Account registration", "{FFFFFF}Your name is currently {FF0000}not {FFFFFF}registered.", "{00FF00}Register", "{FF0000}Kick", name);
        }
        else
        {
            DB_ExecuteQuery(Database, "INSERT INTO `Players` (`UID`, `Player`, `Password`, `GPCI`, `Score`, `Cash`, `Admin`) VALUES(NULL, '%s', '%s', '%s', '0', '10000', '0')", DB_Escape(name), DB_Escape(inputtext), DB_Escape(serial));
            DB_ExecuteQuery(Database, "INSERT INTO `User_Settings` (`UID`, `PlayerColor`, `PlayerSpawnPreference`, `PlayerSkinID`) VALUES(NULL, 'AAAAAAFF', '0', '0')");        
 
            Bit1_Set(g_PlayerLogged, playerid, true); 
            SetPlayerMoney(playerid, 10000);
            SetPlayerScore(playerid, 0);
            SetPlayerColor(playerid, 0xAAAAAAFF);
            SendClientMessage(playerid, 0x00FF00FF, "You've successfully registered the username {FFFFFF}%s{00FF00}.", name);
            TogglePlayerSpectating(playerid, false);
            Bit1_Set(g_PlayerIsSpectating, playerid, 0); // visszakapcsolja a SPAWN gombot 
            SetTimerEx("SpawnPlayerFromCamPan", 100, false, "i", playerid);
        }
        return 1;
    }
    else 
    {
        printf("[kick] Kicking player ID %i %s for trying to skip the registration process.", playerid, name);
        return Kick(playerid);
    }
}

CMD:setadmin(playerid, params[])
{
    if (4 == Bit8_Get(g_AdminLevel, playerid) || IsPlayerAdmin(playerid))
    {
        new who, level, name[MAX_PLAYER_NAME];
        if (!sscanf(params, "ii", who, level))
        {
            GetPlayerName(who, name, sizeof(name));            
            DB_ExecuteQuery(Database, "UPDATE `Players` SET `Admin` = %i WHERE `Player` = '%s'", level, name);
            SendClientMessage(playerid, 0xAA0000FF, "%s's (id: %i) admin level is now %s {AA0000}(%i).", name, who, AdminLevels[level], level);
            Bit8_Set(g_AdminLevel, who, level);
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000AA, "/setadmin <id> <level>");
        }
    }
    else
    {
        SendClientMessage(playerid, 0xFF0000AA, "Missing permission(s).");
    }
    return 1;
}

CMD:setpos(playerid, params[])
{
    if (4 == Bit8_Get(g_AdminLevel, playerid) || IsPlayerAdmin(playerid))
    {
        new Float:x, Float:y, Float:z, int;
        if (!sscanf(params, "fffi", x, y, z, int))
        {
            SetPlayerPos(playerid, x, y, z);
            SetPlayerInterior(playerid, int);
        }
    }
    else
    {
        SendClientMessage(playerid, 0xFF0000FF, "Missing permission(s).");
    }
    return 1;
}

// parancsok
CMD:c(playerid, params[])
{
	Dialog_Show(playerid, CMDS, DIALOG_STYLE_MSGBOX, "{00FF00}Commands",\
	"{FFFFFF}Common commands:\n\
    {00FFFF}/t\t\t\t{FFFFFF}Public teleports. {AAAAAA}With the {FF0000}red marker{AAAAAA}, you can teleport anywhere on the map.\n\
	{00FFFF}/v {00AAAA}<ID/name>\t\t{FFFFFF}Spawn vehicles.\n\
	{006666}/mg\t\t\t{AAAAAA}Minigame menu. {AA0000}(currently in development!)\n\
	{00FFFF}/set {00AAAA}<w> <h> <m>\t{FFFFFF}Set weather & time. {AAAAAA}<weather> <hours> <minutes>\n\
	{00FFFF}/pos\t\t\t{FFFFFF}Get your current position coordinates.\n\
	{00FFFF}/skin {00AAAA}<ID>\t\t{FFFFFF}Set any skin.\n\
	{00FFFF}/kill\t\t\t{FFFFFF}You kill yourself.\n\
	{00FFFF}/sound {00AAAA}<ID>\t\t{FFFFFF}Play any sound from its ID.\n\
	{00FFFF}/ghost \t\t\t{FFFFFF}Enable/Disable Ghost mode.\n\
    {FFFFFF}\nVehicle-related commands:\n\
    {00FFFF}/flip \t\t\t{FFFFFF}Flip and reset the car's velocity. {AAAAAA}Alternatively, you can press {00FF00}N.\n\
	", "{00FF00}OK", "");
	return 1;
}

// quick guide
CMD:help(playerid, params[])
{
    Dialog_Show(playerid, HELP, DIALOG_STYLE_MSGBOX, "{00FFFF}Quick guide",\
    "{00FFFF}/c\t{FFFFFF}Commands\n\
    {00FFFF}/t\t{FFFFFF}Teleports\n\
    {00FFFF}/u\t{FFFFFF}User Settings\n\n\
    {FFFFFF}You can teleport anywhere on the\nmap using the {FF0000}red marker{FFFFFF}.\n\
    ", "{00FF00}OK", "");
    return 1;
}

// public teleports list
CMD:t(playerid, params[])
{
    Dialog_Show(playerid, TP, DIALOG_STYLE_MSGBOX, "{5555FF}Public teleports",\
    "{FFFFFF}{00FFFF}Cyan: {FFFFFF}available both on-foot and with vehicles.\n{3333FF}Dark blue: {FFFFFF}only available on-foot.\n\
    You can teleport anywhere on the map using the{FF0000} red marker.\n\n\
    {00FFFF}/ls\t{FFFFFF}Los Santos\t\t\t{00FFFF}/sb\t{FFFFFF}Santa Maria Beach\n\
    {00FFFF}/lsa\t{FFFFFF}Los Santos Airport\t\t{00FFFF}/pc\t{FFFFFF}Palomino Creek\n\
    {00FFFF}/park\t{FFFFFF}Glen Park (Skatepark)\t\t{00FFFF}/mont\t{FFFFFF}Montgomery\n\
    {00FFFF}/vine\t{FFFFFF}Vinewood\t\t\t{00FFFF}/bb\t{FFFFFF}Blueberry\n\
    {00FFFF}/dock\t{FFFFFF}Los Santos Docks\t\t{00FFFF}/dil\t{FFFFFF}Dillimore\n\n\
    \
    {00FFFF}/sf\t{FFFFFF}San Fierro\t\t\t{00FFFF}/mh\t{FFFFFF}Missionary Hill\n\
    {00FFFF}/sfa\t{FFFFFF}San Fierro Airport\t\t{00FFFF}/fv\t{FFFFFF}Foster Valley\n\
    {3333FF}/pier\t{FFFFFF}Pier 69\t\t\t\t{00FFFF}/mc\t{FFFFFF}Mount Chilliad\n\
    {00FFFF}/sfch\t{FFFFFF}San Fierro City Hall\t\t{00FFFF}/ap\t{FFFFFF}Angel Pine\n\
    {00FFFF}/doh\t{FFFFFF}Doherty\n\n\
    \
    {00FFFF}/lv\t{FFFFFF}Las Venturas\t\t\t{00FFFF}/fc\t{FFFFFF}Fort Carson\n\
    {00FFFF}/lva\t{FFFFFF}Las Venturas Airport\t\t{00FFFF}/lp\t{FFFFFF}Las Payasdas\n\
    {3333FF}/kacc\t{FFFFFF}K.A.C.C Military Fuels\t\t{00FFFF}/elq\t{FFFFFF}El Quabrados\n\
    {00FFFF}/golf\t{FFFFFF}Yellow Bell Golf Club\t\t{00FFFF}/bm\t{FFFFFF}Bayside Marina\n\
    {00FFFF}/vm\t{FFFFFF}Verdant Meadow Airfield\n\
    ", "OK", "");
    return 1;
}

// public teleports, by cities

// TEMPLATE:
// CMD:<nev>(playerid, params[]) { TeleportPlayerToPublicTp(playerid, true, 0.0, 0.0, 0.0, 0.0); return 1; }
CMD:ls(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, 2492.593750, -1668.676391, 13.343750, 90.0); return 1; }
CMD:lsa(playerid, params[])     { TeleportPlayerToPublicTp(playerid, true, 1939.983032, -2493.925292, 13.539117, 90.0); return 1; }
CMD:park(playerid, params[])    { TeleportPlayerToPublicTp(playerid, true, 1879.276000, -1394.154785, 13.570312, 360.0); return 1; }
CMD:vine(playerid, params[])    { TeleportPlayerToPublicTp(playerid, true, 895.441711, -1221.350585, 16.976562, 270.0); return 1; }
CMD:dock(playerid, params[])    { TeleportPlayerToPublicTp(playerid, true, 2761.388427, -2456.602783, 13.558331, 0.0); return 1; }
CMD:sb(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, 336.527404, -1798.481811, 4.722227, 90.0); return 1; }
CMD:pc(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, 2343.871093, 229.837203, 26.335937, 180.0); return 1; }
CMD:mont(playerid, params[])    { TeleportPlayerToPublicTp(playerid, true, 1239.928588, 116.286605, 20.003688, 351.0); return 1; }
CMD:bb(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, 65.639747, -246.435531, 1.578125, 360.0); return 1; }
CMD:dil(playerid, params[])     { TeleportPlayerToPublicTp(playerid, true, 702.305541, -457.711364, 16.335937, 180.0); return 1; }

CMD:sf(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, -1754.233398, 952.028137, 24.742187, 180.0); return 1; }
CMD:sfa(playerid, params[])     { TeleportPlayerToPublicTp(playerid, true, -1530.291137, -37.786216, 14.148437, 315.0); return 1; }
CMD:pier(playerid, params[])    { TeleportPlayerToPublicTp(playerid, false, -1640.487670, 1418.418212, 7.187500, 220.0); return 1; }
CMD:sfch(playerid, params[])    { TeleportPlayerToPublicTp(playerid, true, -2749.585449, 372.130157, 4.149552, 0.0); return 1; }
CMD:doh(playerid, params[])     { TeleportPlayerToPublicTp(playerid, true, -2046.949584, -87.866096, 35.164062, 0.0); return 1; }
CMD:mh(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, -2405.159179, -596.091613, 132.648437, 126.0); return 1; }
CMD:fv(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, -2025.607299, -859.810302, 32.171875, 270.0); return 1; }
CMD:mc(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, -2333.505126, -1622.223632, 483.709625, 207.0); return 1; }
CMD:ap(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, -2053.518310, -2527.635498, 30.421875, 48.0); return 1; }

CMD:lv(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, 2118.114257, 1333.812500, 10.547391, 90.0); return 1; }
CMD:lva(playerid, params[])     { TeleportPlayerToPublicTp(playerid, true, 1477.515869, 1697.797729, 10.820308, 180.0); return 1; }
CMD:kacc(playerid, params[])    { TeleportPlayerToPublicTp(playerid, false, 2590.641601, 2790.315185, 10.820312, 90); return 1; }
CMD:golf(playerid, params[])    { TeleportPlayerToPublicTp(playerid, true, 1523.260009, 2773.242431, 10.671875, 90.0); return 1; }
CMD:vm(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, 361.187652, 2501.108398, 16.484375, 89.0); return 1; }
CMD:fc(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, -247.205581, 1216.689575, 19.742187, 270.0); return 1; }
CMD:lp(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, -220.984191, 2605.722656, 62.703125, 0.0); return 1; }
CMD:elq(playerid, params[])     { TeleportPlayerToPublicTp(playerid, true, -1291.563720, 2691.097412, 50.062500, 116.0); return 1; }
CMD:bm(playerid, params[])      { TeleportPlayerToPublicTp(playerid, true, -2261.533447, 2318.244384, 4.812500, 0.0); return 1; }

// END OF public teleports

CMD:database(playerid, params[])
{
    if (4 == Bit8_Get(g_AdminLevel, playerid))
    {
        SendClientMessage(playerid, 0xABCDEFFF, "Connections: %i; Open ResultSets: %i", DB_GetDatabaseConnectionCount(), DB_GetDatabaseResultSetCount());
        return 1;
    }
    return 0;
}

// allow/disable account registration
CMD:reg(playerid, params[])
{
    printf("%i", Bit8_Get(g_AdminLevel, playerid));
    if (2 <= Bit8_Get(g_AdminLevel, playerid))
    {
        new name[MAX_PLAYER_NAME];
        GetPlayerName(playerid, name, sizeof(name));
        // some switcharoo
        if (GetSVarInt("Reg") == 0)
        {
            SetSVarInt("Reg", 1);
            SetServerRule("reg", "On");
            SendClientMessageToAll(0x00FF00AA, "%s enabled account registration.", name);
            return 1;
        }
        else
        {
            SetSVarInt("Reg", 0);
            SetServerRule("reg", "Off");
            SendClientMessageToAll(0xFF0000AA, "%s disabled account registration.", name);
            return 1;
        }
    }
    else
    {
        SendClientMessage(playerid, 0xFF0000AA, "Missing permission(s).");
        return 1;
    }
}

// gives money, kinda ass implementation but it works
// its now kinda doing stuff that i made entire functions for but i made this like the first fucking week
CMD:doubloon(playerid, params[])
{
    if(Bit8_Get(g_AdminLevel, playerid) > 0)
    {
        new
            DBResult:Result,
            op,
            inputDollars,
            dollars[35],
            clampDollars[25],
            name[MAX_PLAYER_NAME]
        ;
        GetPlayerName(playerid, name, 24);
        if (!sscanf(params, "ii", op, inputDollars))
        {
            if (op == 1) DB_ExecuteQuery(Database, "UPDATE `Players` SET `Cash` = `Cash` + %i WHERE `Player` = '%s'", inputDollars, DB_Escape(name));
            else if (op == 0) DB_ExecuteQuery(Database, "UPDATE `Players` SET `Cash` = `Cash` - %i WHERE `Player` = '%s'", inputDollars, DB_Escape(name));

            Result = DB_ExecuteQuery(Database,\
            "SELECT printf('%%d', CASE \
            WHEN `Cash` < -999999999 THEN -999999999 \
            WHEN `Cash` > 999999999 THEN 999999999 \
            ELSE `Cash` END) AS clampCash, \
            printf('%%,d', `Cash`) as fCash \
            FROM `Players` WHERE `Player` = '%s'", DB_Escape(name));
            DB_GetFieldStringByName(Result, "fCash", dollars, 30);
            DB_GetFieldStringByName(Result, "clampCash", clampDollars, 25);
            SendClientMessage(playerid, 0x00AA00FF, "$%s", dollars);
            g_PlayerCash[playerid] = strval(clampDollars);
            SetPlayerMoney(playerid, g_PlayerCash[playerid]);
            DB_FreeResultSet(Result);
            return 1;
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000AA, "/doubloon <0/1> <$>");
            return 1;
        }
    }
    SendClientMessage(playerid, 0xFF0000AA, "Missing permission(s).");
    return 1;
}

// Reset car position and Z angle
CMD:flip(playerid, params[])
{
    if(IsPlayerInAnyVehicle(playerid))
    {
        SendClientMessage(playerid, 0x00FF00FF, "You flipped your vehicle.");
        ResetPlayerCar(playerid);
        return 1;
    }
    SendClientMessage(playerid, 0xFF0000FF, "You are not in a vehicle.");
    return 1;
}

// USER CONTROL PANEL: USER SETTINGS
CMD:u(playerid, params[])
{
	Dialog_Show(playerid, USER, DIALOG_STYLE_LIST, "{00FF00}User Settings", "{00FF00}Change username\n{FF0000}Change password\n{%06x}Change player color\n{00FFFF}Change spawn location", "{00FF00}Choose", "{FF0000}Exit", GetPlayerColor(playerid) >>> 8);
	return 1;
}

Dialog:USER(playerid, response, listitem, inputtext[])
{
	if (response)
    {
        // Change username
        if (listitem == 0)
        {
            SendClientMessage(playerid, 0xFF0000FF, "Not yet implemented.");
        }

        // Change password
        else if (listitem == 1)
        {
            SendClientMessage(playerid, 0xFF0000FF, "Not yet implemented.");	
        }

        // Change player color (& and save it to database)
        else if (listitem == 2)
        {
			// printf("eat shit");
            Dialog_Show(playerid, USERCOLOR, DIALOG_STYLE_INPUT, "{00FF00}User Settings {FFFFFF}>> {00FF00}Change color", "{AAAAAA}Colors use hex values, ranging from {000000}#000000 {AAAAAA}to {FFFFFF}#FFFFFF\n\nCurrent: {%06x}#%06x {FFFFFF}(#%06x)\nEnter your new color below:", "{00FF00}Set", "{FF0000}Back", GetPlayerColor(playerid) >>> 8, GetPlayerColor(playerid) >>> 8, GetPlayerColor(playerid) >>> 8);
		}

        // Change player spawn preference
        else if (listitem == 3)
        {
            SendClientMessage(playerid, 0xFF0000FF, "Not yet implemented.");
        }
    }
    return 1;
}

//Dialog:USER_USERNAME(playerid, response, listitem, inputtext[])
//Dialog:USER_PASSWORD(playerid, response, listitem, inputtext[])
Dialog:USERCOLOR(playerid, response, listitem, inputtext[])
{
    if (response)
    {
        static Regex:regex;
        if (!regex) regex = Regex_New("\\b(?:[0-9a-fA-F]{6})\\b");

        // if its a valid hexadecimal value (checked with a regex)
        if(Regex_Check(inputtext, regex) && strlen(inputtext) == 6)
        {
            new DBResult:DBCall;
            new name[MAX_PLAYER_NAME];
            GetPlayerName(playerid, name, MAX_PLAYER_NAME);
            new color = GetFuckingColors(inputtext);
            SetPlayerColor(playerid, color);
            SendClientMessage(playerid, 0xFFFFFFFF, "Your color is now set to {%s}#%s{FFFFFF}.", inputtext, inputtext);
            DB_ExecuteQuery(Database, "UPDATE `User_Settings` SET `PlayerColor` = '%s' || 'FF' WHERE `UID` = %i", inputtext, Bit16_Get(g_PlayerUID, playerid));
            DB_FreeResultSet(DBCall);
            return 1;
        }

        else
        {
            Dialog_Close(playerid);
            Dialog_Show(playerid, USERCOLOR, DIALOG_STYLE_INPUT, "{00FF00}User Settings {FFFFFF}>> {00FF00}Change color", "{AAAAAA}Colors use hex values, ranging from {000000}#000000 {AAAAAA}to {FFFFFF}#FFFFFF\n\nCurrent: {%06x}#%06x {FFFFFF}(#%06x)\n{FF0000}Invalid color, try again!\n{FFFFFF}Enter your new color below:", "{00FF00}Set", "{FF0000}Back", GetPlayerColor(playerid) >>> 8, GetPlayerColor(playerid) >>> 8, GetPlayerColor(playerid) >>> 8);
        }
    }

	else Dialog_Show(playerid, USER, DIALOG_STYLE_LIST, "{00FF00}User Settings", "{00FF00}Change username\n{FF0000}Change password\n{%06x}Change player color\n{00FFFF}Change spawn location", "{00FF00}Choose", "{FF0000}Exit", GetPlayerColor(playerid) >>> 8);
	return 1;
}
//Dialog:USER_SPAWN(playerid, response, listitem, inputtext[])