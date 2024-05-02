/*
Egy fajl, amiben globalis valtozok vannak
ilyenek pl a DIALOG-hoz tartozo ID-k
*/
#define VERSION "build 28-sqlite"
#define GAMEMODE "Bumburnyák"
#pragma warning disable 203, 214

new Text:Clock; // ora HH:MM formatumban (jelenleg)

new const countAdmins = 1; // adminok szama
new Admins[1][] = {"The_Balazs"};
new AdminLevels[5][] = {"{DDDDDD}Nem", "{33FF33}Moderátor", "{3333FF}Admin", "{AA0000}Fõadmin", "{FF0000}Tulajdonos"};
// netrol szedett safety feature az adatbazishoz
// SQL injection ellen ved, escapeli a ' jelet
stock DB_Escape(text[])
{
    new
        ret[80 * 2],
        ch,
        i,
        j;
    while ((ch = text[i++]) && j < sizeof (ret))
    {
        if (ch == '\'')
        {
            if (j < sizeof (ret) - 2)
            {
                ret[j++] = '\'';
                ret[j++] = '\'';
            }
        }
        else if (j < sizeof (ret))
        {
            ret[j++] = ch;
        }
        else
        {
            j++;
        }
    }
    ret[sizeof (ret) - 1] = '\0';
    return ret;
}

/*
ez a megkozelites lehet hogy rengeteg agyfaszt fog okozni, de igy lenyegesebben kevesebb memoriat hasznal a jatek
a limited resources miatt jobb, ha minimalizalom a memoria hasznalatot
foleg ha megtobb scenet akarok hozzaadni, akkor lesz feltuno a kulonbseg
mivel nagyresze Float value ezert a lista is az == at kell valtani az utolso 4-et Integerre
emiatt van az ido, idojaras is Float-ba, mert amugy warningokat dobal

az idojarast vegul egysegesre tettem, de az opcio fent marad hogy lehet valtoztatni scenenkent
*/

// mindez a 255-os vilagban tortenik
new const CameraScenes = 8;
new CameraPanTimer[MAX_PLAYERS]; // ezt tartja a timert, ezt majd torli ha spawnol a player

// startX, startY, startZ, endX, endY, endZ, weather, hours, minutes
new const Float:scenesData[8][13] =
{
    // SCENE 0: sbeach dokk fair cucc
    {
        369.8, -1890.0, 8.0, // kamera kezdo pozicio 
        369.8, -2044.0, 8.5, // vegpont
        369.8, -2060.0, 9.0, // kamera ide nez
        3.0,                 // idojaras (-> Int)
        5.0, 15.0,           // ido (-> Int)
        45000.0              // sebesseg (-> Int)
    },

    // SCENE 1
    {
        806.640869, -750.307617, 121.362976,
        740.852966, -662.216918, 74.911552,
        650.517822, -541.257141, 11.127801,
        3.0,
        5.0, 15.0,
        45000.0
    },

    // igen innentol feladtam a lekerekitest
    // SCENE 2:
    {
        -1776.734497, 256.503173, 109.288627,
        -1665.763671, 519.615661, 103.307006,
        -1462.420043, 1001.744140, 92.346252,
        3.0,
        5.0, 15.0,
        45000.0
    },

    // SCENE 3
    {
        -824.180847, -184.772781, 143.394393,
        -921.577331, -365.822326, 113.319999,
        -1059.724853, -622.623840, 70.662361,
        3.0,
        5.0, 15.0,
        45000.0
    },

    // SCENE 4: lv pirate pants
    {
        2028.78, 1673.1, 28.06,
        2028.78, 1565.7, 28.06,
        2028.78, 1433.3, 28.06,
        3.0,
        5.0, 15.0,
        45000.0
    },

    // SCENE 5: sbeach melletti fahaz
    {
        -601.606628, -1503.838134, 112.477554,
        -429.673889, -1467.010620, 90.487838,
        116.046211, -1350.118774, 20.691776,
        3.0,
        5.0, 15.0,
        45000.0
    },

    // SCENE 6: ls madartavlatbol
    {
        2372.665771, -1074.437744, 142.346130,
        2224.519531, -1140.837036, 119.632720,
        1821.445434, -1321.495361, 57.834419,
        3.0,
        5.0, 15.0,
        45000.0
    },


    // SCENE 7: toreno haz
    {
        -597.515441, 725.265319, 52.975185,
        -646.701721, 878.284484, 30.853811,
        -706.424194, 1064.081909, 3.993810,
        3.0,
        5.0, 15.0,
        45000.0
    }
};