/*
	 __  _ _ _ _ _                  _ _     _ _
	|__||  _ _ _  |       /\       |   \   |   |
	 __ | |     | |      /  \      |    \  |   |
	|  || |_ _ _| |     / /\ \     |     \ |   |
	|  ||    _ _ /     / /__\ \    |      \|   |
	|  ||  _ _ _ \    /        \   |   |\      |
	|  || |     | |  /    _ _   \  |   | \     |
	|  || |_ _ _| | /   /    \   \ |   |  \    |
	|__||_ _ _ _ _|/_ _/      \_ _\|_ _|   \_ _|
	
	Author:
	    Inferno
	    
	Project site:
	    www.Inferno-Site.tk
	    
 	Changelog:
		0.1 First version of the script running on the file system mFile
		0.2 Add the ability to ban players from the list (TAB)
		1.0 Added ability to choose between a MySQL mFile
*/


#include <a_samp>
#include <zcmd>
#include <sscanf2>

//------------------------------------------------------------------------------
//configuration script
#define MySQL_ON 1 						// The choice between writing mFile or MySQL (0 = mFile || 1 = MySQL)
#define TAB_BAN 1                       // Turn on (1) / Turn off (0) banning players from list (TAB)
#define TB_BAN_REASON 5                 // id dialogue to ban players from the list (TAB)
#define TB_Version "1.0" 				// Version of filterscript (not modify!)
#define TB_Dir "Bany/%s.ban" 			// Product bans recording in system mFile
#define MYSQL_HOST ""	      			// Host database
#define MYSQL_USER ""					// User database
#define MYSQL_PASS ""         			// Password database
#define MYSQL_DB   ""         			// Name database
//------------------------------------------------------------------------------
#if MySQL_ON == 0
#include <mfile>
#endif
#if MySQL_ON == 1
#include <a_mysql>
#endif


#define KOLOR_CZERWONY 0xFF2F2FFF


new TB_PlayerIP[MAX_PLAYERS][16];
new TB_PlayerName[MAX_PLAYERS][MAX_PLAYER_NAME];
new TB_String[256];
new TB_Query[256];
new TB_Wybral[MAX_PLAYERS];
new TB_File[128];
#if MySQL_ON == 1
#pragma unused TB_File
#endif

new Text: TimeBanTD;

enum TB_DefaultReasonEnum
{
	nazwa[128],
	miesiace,
	dni,
	godziny,
	minuty
}
#define MAX_REASON 5 // Iloœæ powodów bana.
new TB_DefaultReason[MAX_REASON][TB_DefaultReasonEnum] =
{
//Powód bana, miesi¹ce, dni, godziny, minuty
	{" ", 0, 0, 0, 0}, // nie ruszaæ!
	{"Offenses administration/player", 0, 7, 0, 0},
	{"Cheat", 12, 0, 0, 0},
	{"DM", 0, 1, 0, 0},
	{"Spam", 0, 0, 5, 0}
};


public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
#if TAB_BAN == 1
	new s[1500];
	strcat(s, "{FFFFFF}Mon.\tDays\tHou.\tMin.\tReason\n");
    for(new n=1; n != MAX_REASON; n++)
    {
		format(TB_String, sizeof TB_String, "{C0C0C0}%d\t%d\t%d\t%d\t%s\n",
		    TB_DefaultReason[n][miesiace],
		    TB_DefaultReason[n][dni],
		    TB_DefaultReason[n][godziny],
		    TB_DefaultReason[n][minuty],
		    TB_DefaultReason[n][nazwa]
		);
		strcat(s, TB_String);
	}
 	ShowPlayerDialog(playerid, TB_BAN_REASON, DIALOG_STYLE_LIST, "Ban plist", s, "Ban", "Exit");
 	TB_Wybral[playerid]=clickedplayerid;
#endif
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == TB_BAN_REASON)
	{
	    if(response)
	    {
			if(listitem==0)
			{
			    new s[1000];
				strcat(s, "{FFFFFF}Mon.\tDays\tHou.\tMin.\tReason\n");
			    for(new n=1; n != MAX_REASON; n++)
			    {
					format(TB_String, sizeof TB_String, "{C0C0C0}%d\t%d\t%d\t%d\t%s\n",
					    TB_DefaultReason[n][miesiace],
					    TB_DefaultReason[n][dni],
					    TB_DefaultReason[n][godziny],
					    TB_DefaultReason[n][minuty],
					    TB_DefaultReason[n][nazwa]
					);
					strcat(s, TB_String);
				}
			 	ShowPlayerDialog(playerid, TB_BAN_REASON, DIALOG_STYLE_LIST, "Ban plist", s, "Ban", "Exit");
			 	return 1;
			}
	        print("1");
     		BanPlayer(TB_Wybral[playerid], playerid, TB_DefaultReason[listitem][miesiace], TB_DefaultReason[listitem][dni], TB_DefaultReason[listitem][godziny], TB_DefaultReason[listitem][minuty], TB_DefaultReason[listitem][nazwa]);
			printf("%d, %d, %d, %d, %d, %d, %s", TB_Wybral[playerid], playerid, TB_DefaultReason[listitem][miesiace], TB_DefaultReason[listitem][dni], TB_DefaultReason[listitem][godziny], TB_DefaultReason[listitem][minuty], TB_DefaultReason[listitem][nazwa]);
		}
	}
	return 1;
}
public OnFilterScriptInit()
{
	print("-----------------------------------");
	print("FS name: iBan");
	print("Author: Inferno");
	print("Website: www.inferno-site.tk");
	printf("Version: %s", TB_Version);
	print("\tLOADED");
	print("-----------------------------------");
	
#if MySQL_ON == 0
	mCreateDir("Bany");
#endif
#if MySQL_ON == 1
    mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS);
    if(mysql_ping() == -1)
	{
	    printf("[DataBase]Error 001: error when connecting to the database.");
	    SendRconCommand("exit");
	}
	else
	{
	    printf("[DataBase]: Successfully connected to the database.");
	}
	mysql_query("CREATE TABLE IF NOT EXISTS `bany` (\
				  `IP` varchar(255) NOT NULL,\
				  `Czas` int(255) NOT NULL,\
				  `Powod` varchar(255) NOT NULL,\
				  `Admin` varchar(255) NOT NULL,\
				  `Nick` varchar(255) NOT NULL,\
				  `Data` varchar(255) NOT NULL);");
#endif
	
	TimeBanTD = TextDrawCreate(6.000000, 299.000000, " ");
	TextDrawBackgroundColor(TimeBanTD, 255);
	TextDrawFont(TimeBanTD, 1);
	TextDrawLetterSize(TimeBanTD, 0.180000, 0.799999);
	TextDrawColor(TimeBanTD, -1);
	TextDrawSetOutline(TimeBanTD, 1);
	TextDrawSetProportional(TimeBanTD, 1);
	return 1;
}

public OnPlayerConnect(playerid)
{
    GetPlayerIp(playerid, TB_PlayerIP[playerid], 16);
    GetPlayerName(playerid, TB_PlayerName[playerid], MAX_PLAYER_NAME);
    
	CheckBans(playerid);
	return 1;
}

CMD:ban(playerid, params[])
{
	new player, mounth, days, hours, minutes, reason[128];
	if(sscanf(params, "iiiiis[128]", player, mounth, days, hours, minutes, reason))
	    return SendClientMessage(playerid, -1, "U¿yj: /ban <id> <months> <days> <hours> <minutes> <reason of ban>");
    BanPlayer(player, playerid, mounth, days, hours, minutes, reason);
    return 1;
}

CheckBans(playerid)
{
#if MySQL_ON == 0
	format(TB_File, sizeof TB_File, TB_Dir, TB_PlayerIP[playerid]);
	if(mFileExist(TB_File))
	{
		if(gettime() <= mGetInt(TB_File, "Czas"))
		{
		    SendClientMessage(playerid, KOLOR_CZERWONY, "------------------------------------------[ BANNED ]------------------------------------------");
			format(TB_String, sizeof TB_String, "Nick received a ban on the: %s", mGetString(TB_File, "Nick"));
			SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
			format(TB_String, sizeof TB_String, "Admin who banned you: %s", mGetString(TB_File, "Admin"));
			SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
			WyswietlCzasBana(playerid);
			format(TB_String, sizeof TB_String, "Reason of ban: %s", mGetString(TB_File, "Powod"));
			SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
			format(TB_String, sizeof TB_String, "Date of imposition of ban: %s", mGetString(TB_File, "Data"));
			SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
			SendClientMessage(playerid, KOLOR_CZERWONY, "-----------------------------------------------------------------------------------------------------");
			Kick(playerid);
		}
		else
		{
		    SendClientMessage(playerid, KOLOR_CZERWONY, "Your time has passed ban. Please observe the rules in the future!");
		    mRemoveFile(TB_File);
		}
	}
#endif
#if MySQL_ON == 1
	new MTime, MPowod[255], MAdmin[64], MNick[64], MData[50];

	format(TB_Query, sizeof(TB_Query), "SELECT * FROM `bany` WHERE `IP`='%s'", TB_PlayerIP[playerid]);
	mysql_query(TB_Query);
    mysql_store_result();
	mysql_fetch_row_format(TB_Query);

	if(mysql_num_rows()!=0) //Gdy znaleziono
	{
	    mysql_free_result();
	    
	    format(TB_Query, sizeof(TB_Query), "SELECT `Czas`, `Powod`, `Admin`, `Nick`, `Data` FROM `bany` WHERE `IP`='%s'", TB_PlayerIP[playerid]);
     	mysql_query(TB_Query);
      	mysql_store_result();
		mysql_fetch_row_format(TB_Query);
		printf("%s", TB_Query);
		if(!mysql_num_rows()) return 1;
		printf("%s", TB_Query);
		sscanf(TB_Query, "p<|>is[255]s[64]s[64]s[50]", MTime, MPowod, MAdmin, MNick, MData);
		mysql_free_result();
	    if(gettime() <= MTime)
	    {
	        SendClientMessage(playerid, KOLOR_CZERWONY, "------------------------------------------[ BANNED ]------------------------------------------");
			format(TB_String, sizeof TB_String, "Nick received a ban on the: %s", MNick);
			SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
			format(TB_String, sizeof TB_String, "Admin who banned you: %s", MAdmin);
			SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
			WyswietlCzasBanaMySQL(playerid, MTime);
			format(TB_String, sizeof TB_String, "Reason of ban: %s",MPowod);
			SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
			format(TB_String, sizeof TB_String, "Date of imposition of ban: %s", MData);
			SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
			SendClientMessage(playerid, KOLOR_CZERWONY, "-----------------------------------------------------------------------------------------------------");
			Kick(playerid);
		}
		else
		{
		    SendClientMessage(playerid, KOLOR_CZERWONY, "Your time has passed ban. Please observe the rules in the future!");
		    format(TB_Query, sizeof(TB_Query), "DELETE FROM `bany` WHERE `IP` = '%s'", TB_PlayerIP[playerid]);
		    mysql_query(TB_Query);
		}
	    return 1;
	}
#endif
	return 1;
}
#if MySQL_ON == 1
WyswietlCzasBanaMySQL(playerid, atime)
{
    new CzasBana, Days, Hours, Minutes;
	CzasBana = atime - gettime();
	if(CzasBana >= 86400)
	{
		Days = CzasBana / 86400;
		CzasBana = CzasBana - (Days * 86400);
	}
	if(CzasBana >= 3600)
	{
		Hours = CzasBana / 3600;
		CzasBana = CzasBana - (Hours * 3600);
	}
	if(CzasBana >= 60)
	{
		Minutes = CzasBana / 60;
		CzasBana = CzasBana - (Minutes * 60);
	}

	format(TB_String, sizeof TB_String, "Left ban: %d Days, %d Hours i %d Minutes", Days, Hours, Minutes);
	SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);

}
#endif
#if MySQL_ON == 0
WyswietlCzasBana(playerid)
{
    format(TB_File, sizeof TB_File, TB_Dir, TB_PlayerIP[playerid]);

    new CzasBana, Days, Hours, Minutes;
	CzasBana = mGetInt(TB_File, "Czas") - gettime();
	if(CzasBana >= 86400)
	{
		Days = CzasBana / 86400;
		CzasBana = CzasBana - (Days * 86400);
	}
	if(CzasBana >= 3600)
	{
		Hours = CzasBana / 3600;
		CzasBana = CzasBana - (Hours * 3600);
	}
	if(CzasBana >= 60)
	{
		Minutes = CzasBana / 60;
		CzasBana = CzasBana - (Minutes * 60);
	}
	
	format(TB_String, sizeof TB_String, "Left ban: %d Days, %d Hours i %d Minutes", Days, Hours, Minutes);
	SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);

}
#endif
stock BanPlayer(playerid, banedid, mounth, days, hours, minutes, reason[])
{
	new TB_Minutes = minutes*60;
	new TB_Hours = (hours*60)*60;
	new TB_Days = ((days*24)*60)*60;
	new TB_Mounth = (((mounth*30)*24)*60)*60;
	new TimeBan = TB_Minutes+TB_Hours+TB_Days+TB_Mounth;
	
	new Godzina, Minuta, Second,
	    Rok, Miesiac, Dzien, BanDate[64];
    gettime(Godzina, Minuta, Second);
    getdate(Rok, Miesiac, Dzien);
    format(BanDate, 64, "%d.%d.%d %d:%d", Dzien, Miesiac, Rok, Godzina, Minuta);
	
#if MySQL_ON == 0
    format(TB_File, sizeof TB_File, TB_Dir, TB_PlayerIP[playerid]);
    if(!mFileExist(TB_File))
    {
        mCreateFile(TB_File);
        mSetInt(TB_File, "Czas", gettime()+TimeBan);
        mSetString(TB_File, "Powod", reason);
        mSetString(TB_File, "Admin", TB_PlayerName[banedid]);
        mSetString(TB_File, "Nick", TB_PlayerName[playerid]);
        mSetString(TB_File, "Data", BanDate);
    }
#endif
#if MySQL_ON == 1
    format(TB_Query, sizeof(TB_Query), "INSERT INTO `bany` SET `IP`='%s', `Czas`='%d', `Powod`='%s', `Admin`='%s', `Nick`='%s', `Data`='%s'",
        TB_PlayerIP[playerid],
        gettime()+TimeBan,
        reason,
        TB_PlayerName[banedid],
        TB_PlayerName[playerid],
        BanDate);
	mysql_query(TB_Query);
#endif
    format(TB_String, sizeof TB_String, "~r~Ban\
										~n~~y~Player: ~w~%s\
										~n~~y~Admin: ~w~%s\
										~n~~y~Time: ~w~%dMonth, %dDays, %dHours i %dMinutes\
										~n~~y~Reason: ~w~%s.",
										TB_PlayerName[playerid],
										TB_PlayerName[banedid],
										mounth, days, hours, minutes,
										reason);
	TextDrawSetString(TimeBanTD, TB_String);
	TextDrawShowForAll(TimeBanTD);
	SetTimer("TB_SchowajBan", 10*1000, false);
    Kick(playerid);
}

CMD:unban(playerid, params[])
{
	if(isnull(params))
	    return SendClientMessage(playerid, KOLOR_CZERWONY, "U¿yj: /unban <IP>");
    UnBanIP(playerid, params);
    return 1;
}

stock UnBanIP(playerid, IP[])
{
#if MySQL_ON == 0
    format(TB_File, sizeof TB_File, TB_Dir, IP);
	if(mFileExist(TB_File))
	{
	    mRemoveFile(TB_File);
	    format(TB_String, sizeof(TB_String), "Unbanned IP %s.", IP);
	    SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
	}
	else
	{
	    SendClientMessage(playerid, KOLOR_CZERWONY, "Not found the banned IP list!");
	}
#endif
#if MySQL_ON == 1
	format(TB_Query, sizeof(TB_Query), "SELECT * FROM `bany` WHERE `IP`='%s'", IP);
	mysql_query(TB_Query);
    mysql_store_result();
	mysql_fetch_row_format(TB_Query);

	if(mysql_num_rows()!=0) //Gdy znaleziono
	{
	    format(TB_Query, sizeof(TB_Query), "DELETE FROM `bany` WHERE `IP` = '%s'", IP);
	    mysql_query(TB_Query);
	    format(TB_String, sizeof(TB_String), "Unbanned IP %s.", IP);
	    SendClientMessage(playerid, KOLOR_CZERWONY, TB_String);
	}
	else
	{
	    SendClientMessage(playerid, KOLOR_CZERWONY, "Not found the banned IP list!");
	}
	mysql_free_result();
#endif
}

forward TB_SchowajBan();
public TB_SchowajBan()
{
	TextDrawHideForAll(TimeBanTD);
}
