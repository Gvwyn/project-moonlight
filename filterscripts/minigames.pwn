#define FILTERSCRIPT
#include <open.mp>
#include <global_vars>
#include <easyDialog>
#include <izcmd>
#include <sscanf2>

public OnFilterScriptInit()
{
    printf("Minigamek (filterscript) sikeresen betoltve.");
    return 1;
}

public OnFilterScriptExit()
{
    return 1;
}

CMD:minigames(playerid, params[])
{
	Dialog_Show(playerid, MGs, DIALOG_STYLE_TABLIST_HEADERS,\
	"{FFFF00}Minigame v�laszt� men�", "\
	{FFFFFF}J�t�k megnevez�se\t{FFFFFF}M�dok\t{FFFFFF}K�sz�t�(k)\n\
	{3D85C6}M�rleg\t{AAAAAA}Egy- vagy t�bbj�t�kos\t{CCCCCC}The_Balazs, White",\
	"Kiv�laszt", "{FF0000}M�gse");
	return 1;
}
CMD:minigame(playerid, params[]) return cmd_minigames(playerid, params);
CMD:mg(playerid, params[]) return cmd_minigames(playerid, params);

Dialog:MGs(playerid, response, listitem, inputtext[])
{
	if (response)
	{
		if (listitem == 0)
		{
			// SendClientMessage(playerid, 0xFF0000AA, "Ezen m�g dolgozom, n�zz vissza k�s�bb.");
			Dialog_Show(playerid, ScaleSetup, DIALOG_STYLE_LIST,\
			"{3D85C6}M�rleg minigame indit�s",\
			"{FFFFFF}Singleplayer\n{FFFFFF}Multiplayer", "{00FF00}Choose", "{FF0000}Back");
			return 1;
		}
	}
	return 1;
}

Dialog:ScaleSetup(playerid, response, listitem, inputtext[])
{
	if (response)
	{
		SendClientMessage(playerid, -1, "%i", listitem);
		return 1;
	}
	return 1;
}