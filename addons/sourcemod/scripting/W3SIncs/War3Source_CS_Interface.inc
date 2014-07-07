/**
 * File: War3Source_CS_Interface.inc
 * Description: Functions and stuff to make CS specific races and whatnot
 * Author(s): War3Source Team  
 */

/**
 * Changes a clients armor value.
 *
 * @param client      Client index
 * @param amount      Armor value
 * @noreturn
 */
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

/**
 * Retrieves a clients armor value.
 *
 * @param client      Client index
 * @return              Armor value
 */
stock War3_GetCSArmor(client) {
    new ValveGameEnum:war3Game = War3_GetGame();
    if (war3Game == Game_CS || war3Game == Game_CSGO) {
        return GetEntProp(client, Prop_Send, "m_ArmorValue");
    }
    return 0;
}

/**
 * Returns whether the client is currently wearing a helmet or not.
 *
 * @param client      Client index
 * @return              True if client is wearing a helmet
 */
stock bool:War3_GetCSArmorHasHelmet(client) {
    return bool:GetEntProp(client, Prop_Send, "m_bHasHelmet");
}

/**
 * Gives or removes a helmet from the player.
 *
 * @param client      Client index
 * @param hashelmet   True to give helmet, false to remove
 * @noreturn
 */
stock War3_SetCSArmorHasHelmet(client,bool:hashelmet) {
    return SetEntProp(client, Prop_Send, "m_bHasHelmet",hashelmet? 1:0, 1);
}

/**
 * Restores players armor and helmet.
 *
 * @param client        Client index
 * @noreturn
 */
native War3_RestoreCachedCSArmor(client);