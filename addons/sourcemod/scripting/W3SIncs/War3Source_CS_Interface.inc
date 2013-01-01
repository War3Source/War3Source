/**
 * File: War3Source_CS_Interface.inc
 * Description: Functions and stuff to make CS specific races and whatnot
 * Author(s): War3Source Team  
 */

//sets armor, but does not give any helm
stock War3_SetCSArmor(client, amount) {
	// Revan: thoose armor properities for CS:GO are the same as in CS:Source
	new ValveGameEnum:war3Game = War3_GetGame();
	if (war3Game == Game_CS || war3Game == Game_CSGO) {
		if (amount > 125) {
			amount = 125;
		}
		SetEntProp(client, Prop_Send, "m_ArmorValue", amount);
	}
}

stock War3_GetCSArmor(client) {
	new ValveGameEnum:war3Game = War3_GetGame();
	if (war3Game == Game_CS || war3Game == Game_CSGO) {
		return GetEntProp(client, Prop_Send, "m_ArmorValue");
	}
	return 0;
}

stock War3_GetCSArmorHasHelmet(client) {
	return GetEntProp(client, Prop_Send, "m_bHasHelmet")
}

stock War3_SetCSArmorHasHelmet(client,bool:hashelmet) {
	return SetEntProp(client, Prop_Send, "m_bHasHelmet",hashelmet? 1:0, 1);
}