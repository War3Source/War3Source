



#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


public Plugin:myinfo=
{
  name="War3Source Menus itemsinfo",
  author="Ownz (DarkEnergy)",
  description="War3Source Core Plugins",
  version="1.0",
  url="http://war3source.com/"
};

public OnWar3Event(W3EVENT:event,client){
  if(event==DoShowItems2InfoMenu){
    ShowMenuItemsinfo(client);
  }
}
ShowMenuItemsinfo(client){
  SetTrans(client);
  new Handle:helpMenu=CreateMenu(ShowMenuItemsinfoSelected);
  SetMenuExitButton(helpMenu,true);
  SetMenuTitle(helpMenu,"%T","[War3Source] Shopmenu items",client);
  decl String:str[64];
  decl String:numstr[4];

  new ItemsLoaded = W3GetItems2Loaded();
  for(new x=1;x<=ItemsLoaded;x++)
  {
    W3GetItem2Name(x,str,sizeof(str));
    IntToString(x,numstr,sizeof(numstr));
    //PrintToChatAll("%s %s",numstr,str);
    AddMenuItem(helpMenu,numstr,str);
  }
  DisplayMenu(helpMenu,client,MENU_TIME_FOREVER);
}

public ShowMenuItemsinfoSelected(Handle:menu,MenuAction:action,client,selection)
{
  if(action==MenuAction_Select)
  {
    decl String:SelectionInfo[4];
    decl String:SelectionDispText[256];
    new SelectionStyle;
    GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
    new itemnum=StringToInt(SelectionInfo);
    if(itemnum>0&&itemnum<=W3GetItems2Loaded())
      ShowMenuItemsinfo2(client,itemnum);
  }
  if(action==MenuAction_End)
  {
    CloseHandle(menu);
  }
}
public ShowMenuItemsinfo2(client,itemnum){
  SetTrans(client);
  new Handle:helpMenu=CreateMenu(ShowMenuItemsinfo2Selected);
  SetMenuExitButton(helpMenu,true);

  decl String:str[256];
  W3GetItem2Name(itemnum,str,255);

  decl String:shortname[16];
  W3GetItem2Shortname(itemnum,shortname,sizeof(shortname));


  decl String:str2[256];
  W3GetItem2Desc(itemnum,str2,sizeof(str2));



  Format(str,sizeof(str),"%T\n%s","[War3Source] Item: {item} (identifier: {id})",client,str,shortname,str2);

  SetMenuTitle(helpMenu,str);

  Format(str,sizeof(str),"%T","Back",client);

  AddMenuItem(helpMenu,"-1",str);
  DisplayMenu(helpMenu,client,MENU_TIME_FOREVER);
}
public ShowMenuItemsinfo2Selected(Handle:menu,MenuAction:action,client,selection)
{
  if(action==MenuAction_Select)
  {
    //decl String:SelectionInfo[4];
    //decl String:SelectionDispText[256];
    //new SelectionStyle;
    //GetMenuItem(menu,selection,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
    //new itemnum=StringToInt(SelectionInfo);
    //if(itemnum>0&&itemnum<=GetItemsLoaded())
    ShowMenuItemsinfo(client);
  }
  if(action==MenuAction_End)
  {
    CloseHandle(menu);
  }
}
