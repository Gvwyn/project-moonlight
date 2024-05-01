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
	Dialog_Show(playerid, MINIGAMES, DIALOG_STYLE_TABLIST_HEADERS,\
	"{3C377C}Mi{4F4B89}ni{625E96}ga{7673A3}me {8A87B0}vá{7673A3}la{625E96}sz{4F4B89}tó", "\
	{D8D7E4}Játék megnevezése\t{D8D7E4}Készítõ(k)\n\
	{3D85C6}Mérleg\t{FFFFFF}The_Balazs, White",\
	"Kiválaszt", "{FF0000}Mégse");
	return 1;
}
CMD:minigame(playerid, params[]) return cmd_minigames(playerid, params);
CMD:mg(playerid, params[]) return cmd_minigames(playerid, params);

Dialog:MINIGAMES(playerid, response, listitem, inputtext[])
{
	if (response)
	{
		if (listitem == 0)
		{
			SendClientMessage(playerid, 0xFF0000AA, "Ezen még dolgozom, nézz vissza késõbb.");
		}
	}
	return 1;
}