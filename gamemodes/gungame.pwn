#include <open.mp>
#include <global_vars> // 1 fajl, amiben global valtozok vannak
#include <rBits>
#include <izcmd>

new
    Bit1: g_PlayerLogged<MAX_PLAYERS>, // 0 & 1
    Bit1: g_PlayerIsSpectating<MAX_PLAYERS>,
    Bit8: g_AdminLevel<MAX_PLAYERS>,
    Bit16:g_PlayerSkin<MAX_PLAYERS>,
    DB: Database
    //PlayerText:loginFade[MAX_PLAYERS]
;

forward SetPlayerSkinFromFs(playerid, skinid); // Ez frissiti a g_PlayerSkin[playerid]-t
forward CameraPan(playerid);
forward SpawnPlayerFromCamPan(playerid);

main()
{
	printf(" =======================================");
	printf("   Elindult a gepezet, %s", VERSION);
	printf(" =======================================");
}

public OnRconLoginAttempt(ip[], password[], success)
{
    new ipAddress[16];
    new name[24];
    new playerid = -1;
    new authorizedLogin = false;
    for (new id = 0; id < MAX_PLAYERS; id++)
    {
        if (!IsPlayerConnected(id)) continue;
        GetPlayerIp(id, ipAddress, sizeof(ipAddress));
        if (!strcmp(ip, ipAddress, true)){ GetPlayerName(id, name, sizeof(name)); playerid = id; authorizedLogin = true; }
    }
    if (!success && playerid != -1 && !authorizedLogin)
    {
        printf("[Warning] RCON login attempt from IP %s, player %s (ID: %i). Kicking player.", ip, name, playerid);
        SendClientMessage(playerid, 0xFF0000FF, "[RCON] Ezt bizony nem gondoltad át...");
        PlayerPlaySound(playerid, 39000, 0.0, 0.0, 0.0); 
        BlockIpAddress(ipAddress, 60 * 60 * 1000); // 1 ora ban
        return 1;
    }

    else if (success && playerid != -1 && !authorizedLogin)
    {
        printf("[Error] Successful RCON login from IP %s, player %s (ID: %i)", ip, name, playerid);
        printf("[Error] Banning player & shutting down server for safety.");
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

    // biztos nem fogom mindig updatelni de eddig jo ha elbaszok valamit es resetelni kell
    DB_ExecuteQuery(Database, "CREATE TABLE IF NOT EXISTS `Players` (\
    `Reg_ID` INTEGER PRIMARY KEY AUTOINCREMENT,\
    `Player` VARCHAR(24),\
    `Password` VARCHAR(64),\
    `GPCI` VARCHAR(41),\
    `Score` INT,\
    `Cash` INT,\
    `Skin_ID` INT,\
    `Admin` INT\
	);");
	
	if(Database)
	{
	    print("[SQLite] Adatbazis sikeresen beolvasva.");
	}
    else
    {
        print("[SQLite] Sikertelen adatbazis beolvasas, a szerver leall. :(");
        exit;
    }

	SetServerRule("reg", "On");
	SetSVarInt("Reg", 1); // 0 OFF, 1 ON
	ToggleChatTextReplacement(true); // % >> #
	SetGameModeText(GAMEMODE);
    SendRconCommand("game.map %s", VERSION);	
    return 1;
}

public OnGameModeExit()
{
    DB_Close(Database);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    SetPlayerSkin(playerid, Bit16_Get(g_PlayerSkin, playerid));
	if(Bit1_Get(g_PlayerLogged, playerid) == 0)
	{
        printf("[kick] Kickelve ID %i, mert nem volt belepve es lespawnolt.", playerid);
	    Kick(playerid);
 	}
}


/*
public OnClientCheckResponse(playerid, actionid, memaddr, retndata)
{
    if (actionid == 0x48)
    {
        new name[24];
        printf("WARNING: The player %s doesn't seem to be using a regular computer!", GetPlayerName(playerid, name, sizeof(name)));
        Kick(playerid);
    }
    return 1;
}
*/

public SetPlayerSkinFromFs(playerid, skinid) Bit16_Set(g_PlayerSkin, playerid, skinid);

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
    SetSpawnInfo(playerid, NO_TEAM, 0, -984.734252, -710.336608, 32.2, 0, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
    KillTimer(CameraPanTimer[playerid]); // ???? ez valamiert neha nem torli rendesen
    DeletePVar(playerid, "camera");
    SetPlayerWeather(playerid, 0);
    SetPlayerTime(playerid, 22, 0);
    SetPlayerVirtualWorld(playerid, 0);
    // printf("%i", CameraPanTimer);
    SpawnPlayer(playerid);
    SetCameraBehindPlayer(playerid);
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
    Bit1_Set(g_PlayerIsSpectating, playerid, 1); // kikapcsolja a SPAWN gombot
    SetTimerEx("CameraPan", 250, false, "i", playerid); // TogglePlayerSpectating utan AZONNAL nem lehet kamerat eltenni mashova
    SetPlayerVirtualWorld(playerid, 255);
    SetPlayerColor(playerid, (random(0xFFFFFF) << 8) + 0xFF);

    new
        DBResult: Result,
        name[MAX_PLAYER_NAME],
        ip[16],
        serial[41]
    ;
    
    GetPlayerName(playerid, name, sizeof(name));
    Result = DB_ExecuteQuery(Database, "SELECT `Player`, `GPCI` FROM `Players` WHERE `Player` = '%s' COLLATE NOCASE", DB_Escape(name));
    
    GetPlayerIp(playerid, ip, sizeof(ip));
    GPCI(playerid, serial, sizeof(serial)); // jelenlegi GPCI
    
    Bit1_Set(g_PlayerLogged, playerid, false);

	SendClientMessageToAll(-1, "{00FFFF}%s {FFFFFF}belépett a szerverre.", name);
    if(DB_GetRowCount(Result))
    {
        new DB_serial[41]; DB_GetFieldStringByName(Result, "GPCI", DB_serial); //  GPCI a DB-bol
        // ha letezik a fiok, de a GPCI nem egyezik az DB-vel ...
     	if (strcmp(DB_serial, serial))
 		{
 		    printf("Kickelve: %s %s", DB_serial, serial);
	 	    BlockIpAddress(ip, 15 * 60 * 1000); // ... 15 percre kitiltja az IP cimet
	 	    return 1;
 		}
 		SetPVarInt(playerid, "login", 0);
        ShowPlayerDialog(playerid, LOGIN, DIALOG_STYLE_PASSWORD, "{00FF00}Beléptetõ rendszer {FFFFFF}:: {00FF00}Bejelentkezés", "{FFFFFF}Üdv a szerveren, {00FFFF}%s{FFFFFF}!\n\nA bejelentkezéshez add meg a jelszavad:", "{00FF00}Belépés", "{FF0000}Kick", DB_Escape(name));
    }
    else
    {
        // ha nem letezik a fiok a DB-be es ki van kapcsolva a reg akkor bannolja
        if (GetSVarInt("reg") == 0)
		{
		    BanEx(playerid, "REG OFF");
            return 1;
		}
		
        ShowPlayerDialog(playerid, REGISTER, DIALOG_STYLE_PASSWORD, "{00FF00}Beléptetõ rendszer {FFFFFF}:: {FF0000}Regisztráció", "{FFFFFF}Üdv a szerveren, {00FFFF}%s{FFFFFF}!\n\nA neved jelenleg nincs regisztrálva.\nA regisztrációhoz adj meg egy jelszót:", "{00FF00}Reg.", "{FF0000}Kick", DB_Escape(name));
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
        "kifagyott vagy crashelt",
        "kilépett",
        "ki lett rúgva",
        "eltûnt",
        "automatikusan ki lett rúgva"
    };
    SendClientMessageToAll(-1, "{DDDDDD}%s {CCCCCC}%s.", playerName, reasons[reason]);

    // ez nem feltetlen a legokosabb dontes, viszont server load szempontjabol szerintem jobb mintha minden skinvaltas utan mentene
    // eddig nem sikerult nem elmenteni a skinemet
    // docs szerint open.mp alatt az OnPlayerDisconnect alatt is elerhetoek a jatekos cuccai, szoval ezzel baj se lehet (remelem)
    DB_ExecuteQuery(Database, "UPDATE `Players` SET `Skin_ID` = %i WHERE `Player` = '%s'", GetPlayerSkin(playerid), playerName);

    Bit1_Set(g_PlayerIsSpectating, playerid, false);
    if(Bit1_Get(g_PlayerLogged, playerid) == 1)
    {
        Bit1_Set(g_PlayerLogged, playerid, false);
    }
    return 1;
}

public OnPlayerText(playerid, text[])
{
    SetPlayerChatBubble(playerid, text, 0xEED2EEAA, 100.0, 10000);
    return 1;
}

public OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    SendDeathMessage(killerid, playerid, reason);
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, WEAPON:weaponid, bodypart)
{
    if (issuerid != INVALID_PLAYER_ID && bodypart == 9)
    {
        SetPlayerHealth(playerid, 0.0);
    }
    return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
    SetPlayerInterior(playerid, 0);
	if(IsPlayerInAnyVehicle(playerid) && GetPlayerVehicleSeat(playerid) == 0)
    {
		new Float:x, Float:y, Float:z;
        new vehicleid = GetPlayerVehicleID(playerid);
        SetPlayerPosFindZ(playerid, fX, fY, fZ);
		GetPlayerPos(playerid, x, y, z);
        SetVehiclePos(vehicleid, x, y, z);
        PutPlayerInVehicle(playerid, vehicleid, 0);
    }
	else
	{
    	SetPlayerPosFindZ(playerid, fX, fY, fZ);
	}
    return 1;
}

public OnPlayerStateChange(playerid, PLAYER_STATE:newstate, PLAYER_STATE:oldstate)
{
	// hippity hoppity this is now my property
    if (oldstate == PLAYER_STATE_ONFOOT && newstate == PLAYER_STATE_DRIVER)
    {
        new vehicleid = GetPlayerVehicleID(playerid);
        AddVehicleComponent(vehicleid, 1010);
		// SetVehicleHealth(vehicleid, INFINITY); // hat ez nem igy mukodik xdd
    }
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
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
    
    if(dialogid == LOGIN)
    {
        if(response)
        {
            // kis magia: ha letezik egy entry amiben a nev es a jelszo egyezik azzal amit megadott, akkor dob vissza valamit
            Result = DB_ExecuteQuery(Database, "SELECT `Player`, `Password`, `Score`, `Admin`, `Skin_ID`, \
            printf('%%d', CASE \
            WHEN `Cash` < -999999999 THEN -999999999 \
            WHEN `Cash` > 999999999 THEN 999999999 \
            ELSE `Cash` END) AS clampCash \
            FROM `Players` WHERE `Player` = '%s' COLLATE NOCASE AND `Password` = '%s'", DB_Escape(name), DB_Escape(inputtext));
            if(DB_GetRowCount(Result))
            {
                new Field[16];
                DB_GetFieldStringByName(Result, "Skin_ID", Field);
                Bit16_Set(g_PlayerSkin, playerid, strval(Field));
                DB_GetFieldStringByName(Result, "Score", Field);
                SetPlayerScore(playerid, strval(Field));
                DB_GetFieldStringByName(Result, "clampCash", Field, 30);
                GivePlayerMoney(playerid, strval(Field));
                DB_GetFieldStringByName(Result, "Admin", Field, 8);
                Bit8_Set(g_AdminLevel, playerid, strval(Field));
                Bit1_Set(g_PlayerLogged, playerid, true);
                Bit1_Set(g_PlayerIsSpectating, playerid, 0); // visszakapcsolja a SPAWN gombot, es ezt el is menti 
                SendClientMessage(playerid, 0x00FF00AA, "Sikeresen bejelentkeztél.");
                TogglePlayerSpectating(playerid, false);
                SetTimerEx("SpawnPlayerFromCamPan", 250, false, "i", playerid);
            }
			// helytelen jelszo
            else
            {
                SetPVarInt(playerid, "logins", GetPVarInt(playerid, "logins")+1);
                if (GetPVarInt(playerid, "logins") == 3) BlockIpAddress(ip, 5 * 60 * 1000);
                ShowPlayerDialog(playerid, LOGIN, DIALOG_STYLE_PASSWORD, "{00FF00}Beléptetõ rendszer {FFFFFF}:: {00FF00}Bejelentkezés", "{FFFFFF}Üdv a szerveren, {00FFFF}%s{FFFFFF}!\n\n{FF0000}Helytelen jelszót adtál meg, próbáld újra. {FFFFFF}({FF0000}%i{FFFFFF}/{FF0000}3{FFFFFF})", "{00FF00}Belépés", "{FF0000}Kick", name, GetPVarInt(playerid, "logins"));
            }
            DB_FreeResultSet(Result);
        }
        else 
        {
            printf("kick 1");
            return Kick(playerid);
        }
    }
    if(dialogid == REGISTER)
    {
        if(response)
        {
            if(strlen(inputtext) > 64 || strlen(inputtext) < 4 || strfind(inputtext, "  ") != -1)
            {
                ShowPlayerDialog(playerid, REGISTER, DIALOG_STYLE_PASSWORD, "{00FF00}Beléptetõ rendszer {FFFFFF}:: {FF0000}Regisztráció", "{FFFFFF}Üdv a szerveren, {00FFFF}%s{FFFFFF}!\n\nA neved jelenleg {00FF00}nincs {FFFFFF}regisztrálva.\n\n{FF0000}A jelszónak {FFFFFF}4-64 {FF0000}karakter között kell lennie.\n{FFFFFF}A regisztrációhoz adj meg egy érvényes jelszót:", "{00FF00}Reg.", "{FF0000}Kick", name);
            }
            else
            {
                DB_ExecuteQuery(Database, "INSERT INTO `Players` (`Reg_ID`, `Player`, `Password`, `Skin_ID`, `GPCI`, `Score`, `Cash`, `Admin`) VALUES(NULL, '%s', '%s', '0', '%s', '0', '25000', '0')", DB_Escape(name), DB_Escape(inputtext), DB_Escape(serial));
                Bit1_Set(g_PlayerLogged, playerid, true); 
                GivePlayerMoney(playerid, 25000);
                SetPlayerScore(playerid, 0);
                SendClientMessage(playerid, 0x00FF00FF, "Sikeresen regisztráltad a {FFFFFF}%s {00FF00}nevet.", name);
                Bit1_Set(g_PlayerIsSpectating, playerid, 0); // visszakapcsolja a SPAWN gombot 
                TogglePlayerSpectating(playerid, false);
                SetTimerEx("SpawnPlayerFromCamPan", 1000, false, "i", playerid);
            }
        }
        else 
        {
            printf("kick 2");
            return Kick(playerid);
        }
    }
    return 1;
}

public OnPlayerCommandReceived(playerid,cmdtext[])
{
    if(Bit1_Get(g_PlayerLogged, playerid) == 0)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Nem használhatsz parancsokat addig, amíg nem jelentkezel be.");
        return 0;
    }

    else if (!IsPlayerSpawned(playerid) || Bit1_Get(g_PlayerIsSpectating, playerid) == 1)
    {
        SendClientMessage(playerid, 0xFF0000FF, "Nem használhatsz parancsokat addig, amíg nem spawnolsz le.");
    }
	return 1;
}

CMD:reg(playerid, params[])
{
        new name[MAX_PLAYER_NAME];
		GetPlayerName(playerid, name, sizeof(name));
		if (g_AdminLevel[playerid])
		{
			// ha ki van kapcsolva, kapcsolja be
			if (GetSVarInt("Reg") == 0)
			{
				SetSVarInt("Reg", 1);
				SetServerRule("reg", "On");
				SendClientMessageToAll(0x00FF00AA, "%s engedélyezte a regisztrációt.", name);
				return 1;
			}
			else
			{
				SetSVarInt("Reg", 0);
				SetServerRule("reg", "Off");
				SendClientMessageToAll(0xFF0000AA, "%s letiltotta a regisztrációt.", name);
				return 1;
			}
		}
		else
		{
			SendClientMessage(playerid, 0xFF0000AA, "Ehhez nincs jogod.");
			return 1;
		}
}
