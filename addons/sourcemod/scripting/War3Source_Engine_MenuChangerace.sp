#pragma dynamic 10000
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
    name = "War3Source - Engine - Menu Changerace",
    author = "War3Source Team",
    description = "Responsible for showing the changerace menu"
};

new Handle:g_hGameMode;
new bool:bSurvivalStarted;
new bool:bStartingArea[MAXPLAYERS];

//race cat defs
new Handle:hUseCategories,Handle:hCanDrawCat;
new String:strCategories[MAXCATS][64];
new CatCount;

public OnPluginStart()
{
    if(GAMEL4DANY)
    {
        g_hGameMode = FindConVar("mp_gamemode");
        if(!HookEventEx("survival_round_start", War3Source_SurvivalStartEvent))
        {
            PrintToServer("[War3Source] Could not hook the survival_round_start event.");
        }
        if(!HookEventEx("round_end", War3Source_RoundEndEvent))
        {
            PrintToServer("[War3Source] Could not hook the round_end event.");
        }
        if(!HookEventEx("player_entered_checkpoint", War3Source_EnterCheckEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_entered_checkpoint event.");
        }
        if(!HookEventEx("player_left_checkpoint", War3Source_LeaveCheckEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_left_checkpoint event.");
        }
        if(!HookEventEx("player_entered_start_area", War3Source_EnterCheckEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_entered_start_area event.");
        }
        if(!HookEventEx("player_left_start_area", War3Source_LeaveCheckEvent))
        {
            PrintToServer("[War3Source] Could not hook the player_left_start_area event.");
        }
    }
    hUseCategories = CreateConVar("war3_racecats","0","If non-zero race categories will be enabled");
    RegServerCmd("war3_reloadcats", Command_ReloadCats);
}

public bool:InitNativesForwards()
{
    hCanDrawCat=CreateGlobalForward("OnW3DrawCategory",ET_Hook,Param_Cell,Param_Cell);
    CreateNative("W3GetCategoryName",Native_GetCategoryName);
    return true;
}

public Action:Command_ReloadCats(args) {
    PrintToServer("[WAR3] forcing race categories to be refreshed..");
    refreshCategories();
    return Plugin_Handled;
}

public War3Source_EnterCheckEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid") > 0)
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
        {
            bStartingArea[client] = true;
            
            if (W3GetPendingRace(client) > 0 && W3GetPendingRace(client) != War3_GetRace(client))
            {
                War3_SetRace(client, W3GetPendingRace(client));
            }
            else 
            {
                decl String:sGameMode[16];
                
                GetConVarString(g_hGameMode, sGameMode, sizeof(sGameMode));
                if (!StrEqual(sGameMode, "survival", false))
                {
                    W3Hint(client, HINT_LOWEST, 1.0, "You can change your race here by typing \"changerace\"");
                }
            }
        }
    }
}

public War3Source_LeaveCheckEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    if(GetEventInt(event,"userid") > 0)
    {
        new client = GetClientOfUserId(GetEventInt(event, "userid"));
        if (ValidPlayer(client, true) && GetClientTeam(client) == TEAM_SURVIVORS)
        {
            decl String:sGameMode[16];
            
            GetConVarString(g_hGameMode, sGameMode, sizeof(sGameMode));
            if (!StrEqual(sGameMode, "survival", false))
            {
                W3Hint(client, HINT_LOWEST, 1.0, "You will not be able to change races during the map.");
            }
            bStartingArea[client] = false;
        }
    }
}

public War3Source_SurvivalStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    bSurvivalStarted = true;
}

public War3Source_RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    bSurvivalStarted = false;
}

public OnWar3Event(W3EVENT:event,client){
    if(event==DoShowChangeRaceMenu){
        if(ValidPlayer(client)&& !W3Denied(DN_ShowChangeRace,client)){
            War3Source_ChangeRaceMenu(client);
        }
    }
}

public bool:HasCategoryAccess(client,i) {
    /*decl String:buffer[32];
    W3GetCategoryAccessFlag(i,buffer,sizeof(buffer));
    if(!StrEqual(buffer, "0", false) || StrEqual(buffer, "", false)) {
        return false;
    }
    else {
        new AdminId:admin = GetUserAdmin(client);
        if(admin != INVALID_ADMIN_ID) {
            new AdminFlag:flag;
            if (!FindFlagByChar(buffer[0], flag))
            {
                War3_ChatMessage(client,"%T","ERROR on admin flag check {flag}",client,buffer);
                return false;
            }
            else
            {
                if (!GetAdminFlag(admin, flag)){
                    return false;
                }
            }
        }
    }*/
    if(CanDrawCategory(client,i)) {
        return true;
    }
    return false;
}

public OnMapStart(){
    // Delay refresh cats helps prevent stack overflow. - el diablo
    CreateTimer(5.0,refresh_cats,_);
}

/* ****************************** Action:refresh_cats ************************** */

public Action:refresh_cats(Handle:timer)
{
    refreshCategories();
}


new String:dbErrorMsg[100];
public OnWar3GlobalError(String:err[]){
    strcopy(dbErrorMsg,sizeof(dbErrorMsg),err);
}

//This just returns the amount of untouched(=level 0) races in the given category
stock GetNewRacesInCat(client,String:category[]) {
    new amount=0;
    new racelist[MAXRACES];
    new racedisplay=W3GetRaceList(racelist);
    for(new i=1;i<racedisplay;i++)
    {
        new String:rcvar[64];
        W3GetCvar(W3GetRaceCell(i,RaceCategorieCvar),rcvar,sizeof(rcvar));
        if(strcmp(category, rcvar, false)==0) {
            amount++;
        }
    }
    return amount;
}

War3Source_ChangeRaceMenu(client,bool:forceUncategorized=false)
{
    if(W3IsPlayerXPLoaded(client))
    {
        //Check for Races Developer:
        //El Diablo: Adding myself as a races developer so that I can double check for any errors
        //in the races content of any server.  This allows me to have all races enabled.
        //I do not have any other access other than all races to make sure that
        //all races work correctly with war3source.
        new String:steamid[32];
        GetClientAuthString(client,steamid,sizeof(steamid));

        SetTrans(client);
        decl Handle:crMenu;
        if( IsCategorized() && !forceUncategorized ) {
            //Revan: the long requested changerace categorie feature
            //TODO:
            //- translation support
            crMenu=CreateMenu(War3Source_CRMenu_SelCat);
            SetMenuExitButton(crMenu,true);
            
            new String:title[400];
            if(strlen(dbErrorMsg)){
                Format(title,sizeof(title),"%s\n \n",dbErrorMsg);
            }
            Format(title,sizeof(title),"%s%T",title,"[War3Source] Select a category",GetTrans()) ;
            if(W3GetLevelBank(client)>0){
                Format(title,sizeof(title),"%s\n%T\n",title,"You Have {amount} levels in levelbank. Say levelbank to use it",GetTrans(), W3GetLevelBank(client));
            }
            SetSafeMenuTitle(crMenu,"%s\n \n",title);
            decl String:strCat[64];
            //Prepend 'All Races' entry.
            AddMenuItem(crMenu,"-1","All Races");
            //At first we gonna add the categories
            for(new i=1;i<CatCount;i++) {
                W3GetCategory(i,strCat,sizeof(strCat));
                if(strlen(strCat)>0) {
                    if(HasCategoryAccess(client,i)) {
                        new amount=GetNewRacesInCat(client,strCat);
                        if(amount>0) {
                            decl String:buffer[64];
                            Format(buffer,sizeof(buffer),"%s (%i new races)",strCat,amount);
                        }
                        AddMenuItem(crMenu,strCat,strCat);
                    }
                }
            }
        }
        else {
            crMenu=CreateMenu(War3Source_CRMenu_Selected);
            SetMenuExitButton(crMenu,true);
            
            new String:title[400], String:rbuf[4];
            if(strlen(dbErrorMsg)){
                Format(title,sizeof(title),"%s\n \n",dbErrorMsg);
            }
            Format(title,sizeof(title),"%s%T",title,"[War3Source] Select your desired race",GetTrans()) ;
            if(W3GetLevelBank(client)>0){
                Format(title,sizeof(title),"%s\n%T\n",title,"You Have {amount} levels in levelbank. Say levelbank to use it",GetTrans(), W3GetLevelBank(client));
            }
            SetSafeMenuTitle(crMenu,"%s\n \n",title);
            // Iteriate through the races and print them out
            decl String:rname[64];
            decl String:rdisp[128];
            
            
            new racelist[MAXRACES];
            new racedisplay=W3GetRaceList(racelist);
            //if(GetConVarInt(W3GetVar(hSortByMinLevelCvar))<1){
            //    for(new x=0;x<War3_GetRacesLoaded();x++){//notice this starts at zero!
            //        racelist[x]=x+1;
            //    }
            //}
            
            for(new i=0;i<racedisplay;i++) //notice this starts at zero!
            {
                new    x=racelist[i];
                
                Format(rbuf,sizeof(rbuf),"%d",x); //DATA FOR MENU!
                
                War3_GetRaceName(x,rname,sizeof(rname));
                new yourteam,otherteam;
                for(new y=1;y<=MaxClients;y++)
                {
                    
                    if(ValidPlayer(y,false))
                    {
                        if(War3_GetRace(y)==x)
                        {
                            if(GetClientTeam(client)==GetClientTeam(y))
                            {
                                ++yourteam;
                            }
                            else
                            {
                                ++otherteam;
                            }
                        }
                    }
                }
                new String:extra[3];
                if(War3_GetRace(client)==x)
                {
                    Format(extra,sizeof(extra),">");
                    
                }
                else if(W3GetPendingRace(client)==x){
                    Format(extra,sizeof(extra),"<");
                    
                }
                Format(rdisp,sizeof(rdisp),"%s%T",extra,"{racename} [L {amount}]",GetTrans(),rname,War3_GetLevel(client,x));
                new minlevel=W3GetRaceMinLevelRequired(x);
                if(minlevel<0) minlevel=0;
                if(minlevel)
                {
                    Format(rdisp,sizeof(rdisp),"%s %T",rdisp,"reqlvl {amount}",GetTrans(),minlevel);
                }
                //if(!HasRaceAccess(client,race)){ //show that it is restricted?
                //    Format(rdisp,sizeof(rdisp),"%s\nRestricted",rdisp);
                //}
                
                
                AddMenuItem(crMenu,rbuf,rdisp,(minlevel<=W3GetTotalLevels(client)||W3IsDeveloper(client))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED||StrEqual(steamid,"STEAM_0:1:35173666",false)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
            }
        }
        DisplayMenu(crMenu,client,MENU_TIME_FOREVER);
    }
    else{
        War3_ChatMessage(client,"%T","Your XP Has not been fully loaded yet",GetTrans());
    }
    
}

public War3Source_CRMenu_SelCat(Handle:menu,MenuAction:action,client,selection)
{
    switch(action) {
    case MenuAction_Select:
        {
            if(ValidPlayer(client))
            {
                SetTrans(client);
                new String:sItem[64],String:title[512],String:rbuf[4],String:rname[64],String:rdisp[128];
                GetMenuItem(menu, selection, sItem, sizeof(sItem));
                if( StringToInt(sItem) == -1 ) {
                    War3Source_ChangeRaceMenu(client,true);
                    return;
                }

                new Handle:crMenu=CreateMenu(War3Source_CRMenu_Selected);
                SetMenuExitButton(crMenu,true);
                Format(title,sizeof(title),"%T","[War3Source] Select your desired race",GetTrans());
                SetSafeMenuTitle(crMenu,"%s\nCategory: %s\n",title,sItem);
                // Iteriate through the races and print them out                
                new racelist[MAXRACES];
                new racedisplay=W3GetRaceList(racelist);
                for(new i=0;i<racedisplay;i++)
                {
                    new    x=racelist[i],String:rcvar[64];
                    W3GetCvar(W3GetRaceCell(x,RaceCategorieCvar),rcvar,sizeof(rcvar));
                    if(strcmp(sItem, rcvar, false)==0) {
                        IntToString(x,rbuf,sizeof(rbuf)); //menudata as string
                        War3_GetRaceName(x,rname,sizeof(rname));
                        decl String:extra[3],yourteam,otherteam;
                        for(new y=1;y<=MaxClients;y++)
                        {
                            
                            if(ValidPlayer(y,false))
                            {
                                if(War3_GetRace(y)==x)
                                {
                                    if(GetClientTeam(client)==GetClientTeam(y))
                                    {
                                        ++yourteam;
                                    }
                                    else
                                    {
                                        ++otherteam;
                                    }
                                }
                            }
                        }
                        strcopy(extra, sizeof(extra), "");
                        if(War3_GetRace(client)==x)
                        {
                            Format(extra,sizeof(extra),">");
                        }
                        else if(W3GetPendingRace(client)==x){
                            Format(extra,sizeof(extra),"<");
                        }
                        Format(rdisp,sizeof(rdisp),"%s%T",extra,"{racename} [L {amount}]",GetTrans(),rname,War3_GetLevel(client,x));
                        new minlevel=W3GetRaceMinLevelRequired(x);
                        if(minlevel<0) minlevel=0;
                        if(minlevel)
                        {
                            Format(rdisp,sizeof(rdisp),"%s %T",rdisp,"reqlvl {amount}",GetTrans(),minlevel);
                        }
                        AddMenuItem(crMenu,rbuf,rdisp,(minlevel<=W3GetTotalLevels(client)||W3IsDeveloper(client))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
                    }
                }
                AddMenuItem(crMenu,"-1","Back");
                DisplayMenu(crMenu,client,MENU_TIME_FOREVER);
            }
        }
    case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}


public War3Source_CRMenu_Selected(Handle:menu,MenuAction:action,client,selection)
{
    if(action==MenuAction_Select)
    {
        if(ValidPlayer(client))
        {
            SetTrans(client);
            //new menuselectindex=selection+1;
            //if(racechosen>0&&racechosen<=War3_GetRacesLoaded())
            
            decl String:SelectionInfo[4];
            decl String:SelectionDispText[256];
            
            new SelectionStyle;
            GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
            new race_selected=StringToInt(SelectionInfo);
            new bool:allowChooseRace=bool:CanSelectRace(client,race_selected); //this is the deny system W3Denyable
            
            if(race_selected==-1) {
                War3Source_ChangeRaceMenu(client); //user came from the categorized cr menu and clicked the back button
                return;
            }            
            else if(allowChooseRace==false){
                War3Source_ChangeRaceMenu(client);//derpy hooves
            }
            
            
        /* MOVED TO RESTRICT ENGINE
            if(allowChooseRace){
                // Minimum level?
                
                new total_level=0;
                new RacesLoaded = War3_GetRacesLoaded();
                for(new x=1;x<=RacesLoaded;x++)
                {
                    total_level+=War3_GetLevel(client,x);
                }
                new min_level=W3GetRaceMinLevelRequired(race_selected);
                if(min_level<0) min_level=0;
                
                if(min_level!=0&&min_level>total_level&&!W3IsDeveloper(client))
                {
                    War3_ChatMessage(client,"%T","You need {amount} more total levels to use this race",GetTrans(),min_level-total_level);
                    War3Source_ChangeRaceMenu(client);
                    allowChooseRace=false;
                }
            }
                */
                
            // GetUserFlagBits(client)&ADMFLAG_ROOT??
            
            
            
            
            ///MOVED TO RESTRICT ENGINE
            /*
            new String:requiredflagstr[32];
            
            W3GetRaceAccessFlagStr(race_selected,requiredflagstr,sizeof(requiredflagstr));  ///14 = index, see races.inc
            
            if(allowChooseRace&&!StrEqual(requiredflagstr, "0", false)&&!StrEqual(requiredflagstr, "", false)&&!W3IsDeveloper(client)){
                
                new AdminId:admin = GetUserAdmin(client);
                if(admin == INVALID_ADMIN_ID) //flag is required and this client is not admin
                {
                    allowChooseRace=false;
                    War3_ChatMessage(client,"%T","Restricted Race. Ask an admin on how to unlock",GetTrans());
                    PrintToConsole(client,"%T","No Admin ID found",client);
                    War3Source_ChangeRaceMenu(client);
                    
                }
                else{
                    decl AdminFlag:flag;
                    if (!FindFlagByChar(requiredflagstr[0], flag)) //this gets the flag class from the string
                    {
                        War3_ChatMessage(client,"%T","ERROR on admin flag check {flag}",client,requiredflagstr);
                        allowChooseRace=false;
                    }
                    else
                    {
                        if (!GetAdminFlag(admin, flag)){
                            allowChooseRace=false;
                            War3_ChatMessage(client,"%T","Restricted race, ask an admin on how to unlock",GetTrans());
                            PrintToConsole(client,"%T","Admin ID found, but no required flag",client);
                            War3Source_ChangeRaceMenu(client);
                        }
                    }
                }
            }
            
            */
            
        
            
                //PrintToChatAll("1");
            decl String:buf[192];
            War3_GetRaceName(race_selected,buf,sizeof(buf));
            if(allowChooseRace&&race_selected==War3_GetRace(client)/*&&(   W3GetPendingRace(client)<1||W3GetPendingRace(client)==War3_GetRace(client)    ) */){ //has no other pending race, cuz user might wana switch back
                
                War3_ChatMessage(client,"%T","You are already {racename}",GetTrans(),buf);
                //if(W3GetPendingRace(client)){
                W3SetPendingRace(client,-1);
                    
                //}
                allowChooseRace=false;
                
            }
        
                
                
                
                
            
            if(allowChooseRace)
            {
                W3SetPlayerProp(client,RaceChosenTime,GetGameTime());
                W3SetPlayerProp(client,RaceSetByAdmin,false);
            
                //has race, set pending, 
                if(War3_GetRace(client)>0&&IsPlayerAlive(client)&&!W3IsDeveloper(client)) //developer direct set (for testing purposes)
                {
                    if(GAMEL4DANY)
                    {
                        if (GetClientTeam(client) == TEAM_INFECTED) {
                            if (IsPlayerGhost(client)) {
                                W3SetPendingRace(client,-1);
                                War3_SetRace(client, race_selected);
                                W3DoLevelCheck(client);
                            }
                        }
                        else {
                            decl String:sGameMode[16];
                            
                            GetConVarString(g_hGameMode, sGameMode, sizeof(sGameMode));
                            if (StrEqual(sGameMode, "survival", false))
                            {
                                if (!bSurvivalStarted)
                                {
                                    W3SetPendingRace(client,-1);
                                    War3_SetRace(client,race_selected);
                                    W3DoLevelCheck(client);
                                }
                            }
                            else if (bStartingArea[client])
                            {
                                W3SetPendingRace(client,-1);
                                War3_SetRace(client,race_selected);
                                W3DoLevelCheck(client);
                            }
                            else
                            {
                                W3SetPendingRace(client,race_selected);
                                
                                War3_ChatMessage(client,"%T","You will be {racename} after death or spawn",GetTrans(),buf);
                            }
                        }
                    }
                    else
                    {
                        W3SetPendingRace(client,race_selected);
                        
                        War3_ChatMessage(client,"%T","You will be {racename} after death or spawn",GetTrans(),buf);
                    }
                }
                //HAS NO RACE, CHANGE NOW
                else //schedule the race change
                {
                    W3SetPendingRace(client,-1);
                    War3_SetRace(client,race_selected);
                    
                    //PrintToChatAll("2");
                    //print is in setrace
                    //War3_ChatMessage(client,"You are now %s",buf);
                    
                    W3DoLevelCheck(client);
                }
            }
        }
//    }
    }
    if(action==MenuAction_End)
    {
        CloseHandle(menu);
    }
}

//category stocks
//Checks if a category exist
stock bool:W3IsCategory(const String:cat_name[]) {
    for(new i=0;i<CatCount;i++) {
        if(strcmp(strCategories[i], cat_name, false)==0) {
            return true; //cat exist
        }
    }
    return false;//no cat founded that is named X
}
//Removes all categories
stock W3ClearCategory() {
    for(new i=0;i<CatCount;i++) {
        strcopy(strCategories[i],64,"");
    }
    CatCount = 0;
}

//Adds a new Category and returns true on success
stock bool:W3AddCategory(const String:cat_name[]) {
    if(CatCount<MAXCATS) {
        strcopy(strCategories[CatCount],64,cat_name);
        /*if(bCreateW3Cvar) {
            //Add a w3cvar for this cat
            decl String:buffer[FACTION_LENGTH],w3cvar;
            strcopy(buffer,sizeof(buffer),cat_name);
            ReplaceString(buffer,sizeof(buffer), " ", "_", false);
            Format(buffer,sizeof(buffer),"\"accessflag_%s\"",buffer);
            w3cvar = W3FindCvar(buffer);
            if(w3cvar==-1)
                w3cvar = W3CreateCvar(buffer,"0","Admin flag required to access this category");
            }
            iCategories[CatCount]=w3cvar;
        }*/
        CatCount++;
        return true;
    }
    War3_LogError("Too much categories!!! (%i/%i) - failed to add new category",CatCount,MAXCATS);
    return false;
}
//Returns a Category Name thing
stock W3GetCategory(iIndex,String:cat_name[],max_size) {
    decl String:buffer[FACTION_LENGTH];
    strcopy(buffer,sizeof(buffer),strCategories[iIndex]);
    ReplaceString(buffer,sizeof(buffer), "_", " ", false);
    strcopy(cat_name,max_size,buffer);
}
//Refreshes Categories
refreshCategories() {
    W3ClearCategory();
    //zeroth cat will not be drawn = perfect hidden cat ;D
    W3AddCategory("hidden");
    decl String:rcvar[64];
    decl racelist[MAXRACES];
    //Loop tru all _avaible_ races
    new racedisplay=W3GetRaceList(racelist);
    for(new i=0;i<racedisplay;i++)
    {
        new x=racelist[i];
        W3GetCvar(W3GetRaceCell(x,RaceCategorieCvar),rcvar,sizeof(rcvar));
        //To avoid multiple-same-named-categories we need to check if the category allready exist
        if(!W3IsCategory(rcvar)) {
            //Add a new category
            W3AddCategory(rcvar);
        }
    }
}
bool:IsCategorized() {
    return GetConVarBool(hUseCategories);
}
//Calls the forward
bool:CanDrawCategory(iClient,iCategoryIndex) {
    decl value;
    Call_StartForward(hCanDrawCat);
    Call_PushCell(iClient);
    Call_PushCell(iCategoryIndex);
    Call_Finish(value);
    if (value == 3 || value == 4)
        return false;
    return true;
}
public _:Native_GetCategoryName(Handle:plugin,numParams)
{
    SetNativeString(2, strCategories[GetNativeCell(1)], GetNativeCell(3), false);
}
