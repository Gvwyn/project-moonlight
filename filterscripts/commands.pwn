#define FILTERSCRIPT
#include <open.mp>
#include <easyDialog>
#include <global_vars>
#include <izcmd>
#include <rBits>
#include <sscanf2>

new DB: Database;

public OnFilterScriptInit()
{
	Database = DB_Open("Server.db");
	return 1;
}

public OnFilterScriptExit()
{
	return 1;
}

public OnPlayerConnect(playerid)
{
    SetPVarInt(playerid, "veh", -1);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	DestroyVehicle(GetPVarInt(playerid, "veh"));
	DeletePVar(playerid, "veh");
	return 1;
}

/*
CMD:cp(playerid, params[])
{
	new Float:size;
	new wtype;
	new baszas[64];
	if(!sscanf(params, "fis[64]", size, wtype))
	{
		new Float:x, Float:y, Float:z, Float:angle;
		GetPlayerPos(playerid, x, y, z);
		if (wtype == 0)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_GROUND_NORMAL, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_GROUND_NORMAL, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else if (wtype == 1)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_GROUND_FINISH, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_GROUND_FINISH, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else if (wtype == 2)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_GROUND_EMPTY, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_GROUND_EMPTY, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else if (wtype == 3)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_AIR_NORMAL, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_AIR_NORMAL, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else if (wtype == 4)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_AIR_FINISH, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_AIR_FINISH, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else if (wtype == 5)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_AIR_ROTATING, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_AIR_ROTATING, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else if (wtype == 6)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_AIR_STROBING, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_AIR_STROBING, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else if (wtype == 7)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_AIR_SWINGING, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_AIR_SWINGING, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else if (wtype == 8)
		{
			SetPlayerRaceCheckpoint(0, CP_TYPE_AIR_BOBBING, x, y, z, 0, 0, 0, size);
			SetPlayerRaceCheckpoint(1, CP_TYPE_AIR_BOBBING, x, y, z, 0, 0, 0, size);
			printf("%i, %f, %f, %f, 0, 0, 0, %f, %s", size, x, y, z, size, baszas);
		}
		else
		{
			SendClientMessage(playerid, 0xFF0000FF, "Ilyen CP_TYPE nincs.");
		}
		return 1;
	}
	else 
	{ 
		SendClientMessage(playerid, 0xFF0000FF, "/cp <meret> <CP_TYPE> <megnevezes>");
		return 1;
	}
}
*/

// parancsok
CMD:help(playerid, params[])
{
	Dialog_Show(playerid, CMDS, DIALOG_STYLE_MSGBOX, "{00FF00}A szerver parancsai",\
	"{00FFFF}/help /cmds\t\t{FFFFFF}Ez a parancs.\n\
	{00FFFF}/t\t\t\t{FFFFFF}Alapvet� teleportok lek�r�se. {AAAAAA}A {FF0000}piros {AAAAAA}kijel�l�ssel a t�rk�pen b�rhova teleport�lhatsz.\n\
	{00FFFF}/v {00AAAA}<ID>\t\t\t{FFFFFF}J�rm�vek leh�v�sa ID alapj�n.\n\
	{006666}/mg\t\t\t{AAAAAA}Minigame v�laszt� megnyit�sa. {AA0000}(Fejleszt�s alatt!)\n\
	{00FFFF}/set {00AAAA}<w> <h> <m> \t{FFFFFF}Id�j�r�s �s id� �ll�t�sa. {AAAAAA}<id�j�r�s> <�ra> <perc>\n\
	{00FFFF}/pos\t\t\t{FFFFFF}Jelenlegi poz�ci� lek�r�se.\n\
	{00FFFF}/skin {00AAAA}<ID> \t\t{FFFFFF}Skin v�lt�s.\n\
	{00FFFF}/sound {00AAAA}<hang_ID> \t{FFFFFF}J�t�kbeli hang lej�tsz�sa ID alapj�n.\n\
	{00FFFF}/ghost \t\t\t{FFFFFF}Szellem m�d ki- �s bekapcsol�sa.\n\
	{00FFFF}/doubloon {00AAAA}<op> <$>\t{FFFFFF}P�nzt tudsz adni, illetve elvenni. {AAAAAA}<op> 0 kivon�s, 1 hozz�ad�s\
	", "{00FF00}OK", "");
	return 1;
}
CMD:cmds(playerid, params[]) { return cmd_help(playerid, params); }

CMD:pos(playerid, params[])
{
	new Float:x, Float:y, Float:z, Float:angle;
	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, angle);
	printf("%f, %f, %f, -- %f", x, y, z, angle);
	SendClientMessage(playerid, 0x33FFAAAA, "Jelenlegi pozici�d: %f, %f, %f; forg�sod: %.2f", x, y, z, angle);
	return 1;
}

CMD:set(playerid, params[])
{
	new w, h, m;
	if(!sscanf(params, "iii", w, h, m))
	{
		SetPlayerWeather(playerid, w);
		SetPlayerTime(playerid, h, m);
		return 1;
	}
	return 0;
}

CMD:sound(playerid, params[])
{
	new sound = 0;
	if(!sscanf(params, "i", sound))
	{
		SendClientMessage(playerid, 0x007AFFFF, "Hang lej�tsz�sa %i ID-vel.", sound);
		PlayerPlaySound(playerid, sound, 0.0, 0.0, 0.0);
		return 1;
	}
	else
	{
		SendClientMessage(playerid, 0xFF0000FF, "/sound <hang_ID>");
		return 1;
	}
}

// jarmu lekeres
CMD:v(playerid, params[])
{
	new vehicleid;
	if(!sscanf(params, "i", vehicleid))
	{
	    if (vehicleid >= 400 && vehicleid <= 611)
	    {
	        new Float:x, Float:y, Float:z, Float:angle;
		    GetPlayerPos(playerid, x, y, z);
		    GetPlayerFacingAngle(playerid, angle);
			DestroyVehicle(GetPVarInt(playerid, "veh"));
		    SetPVarInt(playerid, "veh", CreateVehicle(vehicleid, x, y, z, angle, 1, 1, 60) );
			PutPlayerInVehicle(playerid, GetPVarInt(playerid, "veh"), 0);
			return 1;
	    }
	    else
	    {
	    	SendClientMessage(playerid, 0xFF0000AA, "J�rm�vek 400 �s 611 ID-k k�z�tt vannak. (%i)", vehicleid);
	    	return 1;
	    }
	}
	else
	{
		SendClientMessage(playerid, 0xFF0000AA, "/v <ID>");
		return 1;
	}
}

// ghost mode, at tudsz menni a tobbieken
CMD:ghost(playerid, params[])
{
	if (GetPlayerGhostMode(playerid) == false)
	{
		TogglePlayerGhostMode(playerid, true);
        DisableRemoteVehicleCollisions(playerid, true);
		SendClientMessage(playerid, 0x00AA00FF, "Szellem m�d bekapcsolva.");
		return 1;
	}
	TogglePlayerGhostMode(playerid, false);
	DisableRemoteVehicleCollisions(playerid, false);
	SendClientMessage(playerid, 0xAA0000FF, "Szellem m�d kikapcsolva.");
	return 1;
}

// ikon lerakas
CMD:pickup(playerid, params[])
{
	new Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);
	new object;
	if (!sscanf(params, "i", object))
	{
		CreatePickup(object, 1, x, y, z, -1);
		return 1;
	}
	SendClientMessage(playerid, -1, "Na ezt elbasztad.");
	return 1;
}

CMD:o(playerid, params[])
{
	if (PlayerHasClockEnabled(playerid)) TogglePlayerClock(playerid, false);
	else TogglePlayerClock(playerid, true);
	return 1;
}

// penz allitas
CMD:doubloon(playerid, params[])
{
	new
		DBResult:Result,
		op,
		inputDollars,
		dollars[35],
		clampDollars[25],
		name[24]
	;
	GetPlayerName(playerid, name, 24);
	if (!sscanf(params, "ii", op, inputDollars))
	{
		// printf("%i %i", op, inputDollars);
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
		printf("%s -$- %s", dollars, clampDollars);
		SendClientMessage(playerid, 0x00AA00FF, "P�nzed �t�rva -> $%s", dollars);
		ResetPlayerMoney(playerid);
		GivePlayerMoney(playerid, strval(clampDollars));
		DB_FreeResultSet(Result);
		return 1;
	}
	else
	{
		SendClientMessage(playerid, 0xFF0000AA, "/doubloon <0/1> <$>");
		return 1;
	}
}

CMD:stats(playerid, params[])
{
	new
		DBResult:Result,
		uid[4],
		name[24],
		admin[3],
		pass[64],
		dollars[32],
		dollarsInHand[21],
		score[21],
		id,
		passingID // ez az ID amit majd az adatbazis leker
	;

	// ha adott id-t es VAN ilyen jatekos, akkor id legyen az amit megadott, mas esetben hibauzenet
	if (!sscanf(params, "i", id))
	{
		if (!IsPlayerConnected(id))
		{
			SendClientMessage(playerid, 0xFF0000FF, "Nincs ilyen j�t�kos a szerveren.");
			return 1;
		}
		else passingID = id;
	}
	else passingID = playerid;

	GetPlayerName(passingID, name, sizeof(name));
	Result = DB_ExecuteQuery(Database,\
	"SELECT `UID`, `Player`, `Admin`, `Password`, `Score`, \
	printf('%%,d', CASE \
	WHEN `Cash` < -999999999 THEN -999999999 \
	WHEN `Cash` > 999999999 THEN 999999999 \
	ELSE `Cash` END) AS clampCash, \
	printf('%%,d', `Cash`) AS fCash \
	FROM `Players` \
	WHERE `Player` = '%s'",\
	DB_Escape(name));
	DB_GetFieldStringByName(Result, "Admin", admin, 8);
	if (passingID == playerid || IsPlayerAdmin(playerid)) // ha sajat magan hasznalja, vagy admin hasznalja irja ki a jelszot
	{
		DB_GetFieldStringByName(Result, "Password", pass, 64);
	}
	else pass = "{FFFFFF}Rejtve"; // amugy meg ne, halo
	DB_GetFieldStringByName(Result, "fCash", dollars, 32);
	DB_GetFieldStringByName(Result, "clampCash", dollarsInHand, 21);
	DB_GetFieldStringByName(Result, "Score", score, 21);
	DB_GetFieldStringByName(Result, "UID", uid, 4);
	Dialog_Show(playerid, STATS, DIALOG_STYLE_MSGBOX, "{00FF00}Statisztika",\
	"{FFFFFF}UID:\t\t{00FFFF}%s\n\
	{FFFFFF}N�v:\t\t{%06x}%s {FFFFFF}(Admin: {FF0000}%s{FFFFFF})\n\
	{FFFFFF}Jelsz�: \t\t{00FFFF}%s\n\
	{FFFFFF}P�nz: \t\t{00AA00}$%s\n{FFFFFF}Ebb�l k�zben: \t{007700}$%s\n\
	{FFFFFF}Pont: \t\t{DDDDDD}%s db", "{00FF00}OK", "", uid, GetPlayerColor(playerid) >>> 8, name, admin, pass, dollars, dollarsInHand, score);
	DB_FreeResultSet(Result);

	printf("%i %i, %s", id, passingID, name);
	return 1;

}

// skin allitas
// a skint csak OnPlayerDisconnect-nel fogja elmenteni !!!!
CMD:skin(playerid, params[]) 
{
	new 
		newskin,
		Float:Health
	;
	if(!sscanf(params, "i", newskin) && newskin >= 0 && newskin != 74 && newskin <= 311)
	{
		CallRemoteFunction("SetPlayerSkinFromFs", "ii", playerid, newskin);
		SetPlayerSkin(playerid, newskin);
		return 1;
	}
	SendClientMessage(playerid, 0xFF0000FF, "/skin <ID> {FF2222}(0-311, kiv�ve 74)");
	return 1;
}
