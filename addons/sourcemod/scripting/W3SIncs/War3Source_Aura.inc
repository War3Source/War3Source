///AURA SYSTEM, keeps track of players aura via distance
//This function registers an aura, returns an number, save it as your AuraID
//by default tracks teammates only
//Track other team will track other team only, if you want to track both teams, use two different auras
//aura not does take account of line of sight
native W3RegisterAura(String:auraShortName[],Float:distance,bool:trackotherteam=false);

//set and unset a player if he has or no longer has the origin of the aura
//removed if player disconnects
//level (optional) is a integer for a priority system, such as teammate has level 1 heal wave and another teammate has level 4 heal wave
//the player recieves the level 4 heal wave and does not stack with level 1 heal wave
native W3SetAuraFromPlayer(tAuraID,client,bool:auraOriginatesFromPlayer=true,level=1);

///is this player under the influence of this aura?
///it means player is within distance of an aura origin (ie a player)
///level of the aura recieved is passed by reference and will be set
native bool:W3HasAura(tAuraID,client,&level);

//forward when a player's aura state changes, ie leaves the area, or dies
//however player may be dead while the aura lingers, always check for alive in your function
forward OnW3PlayerAuraStateChanged(client,tAuraID,bool:inAura,level);

