/**
 * File: War3Source_Gamecheck.inc
 * Description: Stocks to check what game is played
 * Author(s): War3Source Team  
 */

// ------------------------------------------------------------------------------------------------------------------------------------------------------

// Use these like a boolean

#define GAMECS GameCS()
#define GAMETF GameTF()
#define GAMEL4D1 GameL4D1()
#define GAMEL4D2 GameL4D2()
#define GAMEL4DANY GameL4DAny()
#define GAMECSGO GameCSGO()
#define GAMECSANY GameCSANY()

// ------------------------------------------------------------------------------------------------------------------------------------------------------

//INTERFACE ONLY VARIABLES, use for determining game type
stock tValveGame;

stock ValveGameEnum:War3_GetGame() 
{
    return ValveGameEnum:tValveGame;
}

//Do not manually call this, this determines the game mode and is called internally in the API
stock DetermineGameMode() 
{
    //DETERMINE GAME TYPE: CS TF ETC
    new String:gameDir[64];
    GetGameFolderName(gameDir, sizeof(gameDir));

    if (StrContains(gameDir, "cstrike", false) == 0) 
    {
        tValveGame = _:Game_CS;
        
        // What is this even?
        ServerCommand("sv_allowminmodels 0");
    } 
    else if (StrContains(gameDir, "dod", false) == 0) 
    {
        tValveGame = _:Game_DOD;
    }
    else if(StrContains(gameDir, "tf", false) == 0)
    {
        tValveGame = _:Game_TF;
    }
    else if(StrContains(gameDir, "left4dead2", false) == 0)
    {
        tValveGame = _:Game_L4D2;
    }
    else if(StrContains(gameDir, "left4dead", false) == 0)
    {
        tValveGame = _:Game_L4D;
    }
    else if(StrContains(gameDir, "csgo", false) == 0)
    {
        tValveGame = _:Game_CSGO;
    }
    else
    {
        SetFailState("[War3Source] Sorry, this game isn't support by War3Source yet. If you think this is a mistake, you probably renamed your game directory. For example, re-naming cstrike to cstrike2 will cause this error. (folder name: %s)", gameDir);
    }
}

stock bool:GameCS() 
{
    return War3_GetGame() == Game_CS;
}
stock bool:GameTF() 
{
    return War3_GetGame() == Game_TF;
}

stock bool:GameL4D1() 
{
    return (War3_GetGame() == Game_L4D);
}

stock bool:GameL4D2() 
{
    return (War3_GetGame() == Game_L4D2);
}

stock bool:GameL4DAny() 
{
    return (War3_GetGame() == Game_L4D || War3_GetGame() == Game_L4D2);
}

stock bool:GameCSGO() 
{
    return War3_GetGame() == Game_CSGO;
}
stock bool:GameCSANY() 
{
    new ValveGameEnum:war3Game = War3_GetGame();
    
    return (war3Game == Game_CS || war3Game == Game_CSGO); 
}