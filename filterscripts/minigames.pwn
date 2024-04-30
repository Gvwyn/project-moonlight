#define FILTERSCRIPT
#include <open.mp>
#include <easyDialog>
#include <izcmd>
#include <sscanf2>
#include <global_vars>

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
	"{3C377C}Mi{4F4B89}ni{625E96}ga{7673A3}me {8A87B0}v�{7673A3}la{625E96}sz{4F4B89}t�", "\
	{D8D7E4}J�t�k megnevez�se\t{D8D7E4}K�sz�t�(k)\n\
	{3D85C6}M�rleg\t{FFFFFF}The_Balazs, White",\
	"Kiv�laszt", "{FF0000}M�gse");
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
			printf("called");
			Dialog_Show(playerid, SCALEGAMESETUP, DIALOG_STYLE_MSGBOX,\
			"{3D85C6}M�rleg",\
			"a jatek szabalyzata majd itt lesz de lusta vagyok",\
			"{00FF00}Ind�t�s", "{FF0000}M�gse");
		}
	}
	return 1;
}