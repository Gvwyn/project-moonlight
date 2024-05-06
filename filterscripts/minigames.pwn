#define FILTERSCRIPT
#include <open.mp>
#include <global_vars>
#include <streamer>
#include <easyDialog>
#include <izcmd>
#include <sscanf2>

public OnFilterScriptInit()
{
    printf("Minigames filterscript is loaded in.");
    return 1;
}

public OnFilterScriptExit()
{
    return 1;
}

CMD:minigames(playerid, params[])
{
	Dialog_Show(playerid, MGs, DIALOG_STYLE_TABLIST_HEADERS,\
	"{FFFF00}Minigames", "\
	{FFFFFF}Minigame\t{FFFFFF}Modes\t{FFFFFF}Creators\n\
	{3D85C6}The Scale\t{AAAAAA}Single & Multiplayer\t{CCCCCC}The_Balazs, White",\
	"Select", "{FF0000}Cancel");
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
			Dialog_Close(playerid);
			// SendClientMessage(playerid, 0xFF0000AA, "Ezen még dolgozom, nézz vissza késõbb.");
			Dialog_Show(playerid, ScaleSetup, DIALOG_STYLE_LIST,\
			"{3D85C6}Mérleg minigame inditás",\
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