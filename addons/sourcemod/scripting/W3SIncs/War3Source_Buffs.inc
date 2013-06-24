/**
 * File: War3Source_Buffs.inc
 * Description: Stocks regarding Buffs
 * Author(s): War3Source Team  
 */

//=======================================================================
//                             NATIVE / STOCKS
//=======================================================================

// Easy natives to apply a W3Buff based on a skill/item

// THESE PERMAMENTLY links to the player's skill level and changes the buffs acordingly
// If player has race/skill, the value[] corresponding to the level is applied on the buff
// values = array (usually length 5, with 0th index included, zeroth index is ignored however, internally it calls a resetbuff function to restore default value)
// of values to set the buff as, CELLS please (int or float, determined by buff itself)
// MAX LENGTH of values is 32
// RECALL safe
// no return
native War3_AddSkillBuff(raceID, skill_ID, W3Buff:buff, any:values[]);

// THESE PERMAMENTLY links to the player's skill level and changes the buffs acordingly
// If player has race/skill, the value[] corresponding to the level is applied on the buff
// values = array (usually length 5, with 0th index included, zeroth index is ignored however, internally it calls a resetbuff function to restore default value)
// of values to set the buff as, CELLS please (int or float, determined by buff itself)
// MAX LENGTH of values is 32
// RECALL safe
// no return
native War3_AddItemBuff(item_ID, W3Buff:buff, any:value);

// THESE PERMAMENTLY links to the player's skill level and changes the buffs acordingly
// If player has race/skill, the value[] corresponding to the level is applied on the buff
// values = array (usually length 5, with 0th index included, zeroth index is ignored however, internally it calls a resetbuff function to restore default value)
// of values to set the buff as, CELLS please (int or float, determined by buff itself)
// Beware of duplicate aura short names
// MAX LENGTH of values is 32
// RECALL safe
// no return
native War3_AddAuraSkillBuff(race_ID, skill_ID, W3Buff:buff, any:values[], 
                             String:auraShortName[], Float:distance, 
                             bool:trackotherteam);

//is a buff index valid? X > 0 and X <  MaxBuffLoopLimitTemp
stock ValidBuff(W3Buff:buffindex) {
    if(_:buffindex>=0&&_:buffindex<MaxBuffLoopLimit) {
        return true;

    }
    ThrowError("invalid buff index (%d)",buffindex);
    return false;
}

/*
 * set a buff, identified as coming from a race
 * value can be int float bool, but has to be consistant, agreed upon by war3 main plugin
 * 
 */
native War3_SetBuff(client,W3Buff:buffindex,raceid,any:value);

/*
 * set a buff, identified as coming from a item
 * 
 */
native War3_SetBuffItem(client,W3Buff:buffindex,itemid,any:value);
native W3BuffCustomOFFSET(); //get offset for custom buff modifier indexes. use War3_SetBuffItem(client,buffindex,W3BuffCustomOFFSET() + NUMBER,value) (YES, ITEM)

///RESETS a particular buff from your race on this client
native W3ResetBuffRace(client,W3Buff:buffindex,raceid);

// Reset a particular buff from a item on thsi client
native W3ResetBuffItem(client, W3Buff:buffindex, itemid);

///RESETS ALL BUFFS PERTAINGIN TO THIS CLIENT AND RACE, basically fully getting rid if all buffs attatched to this player from your race
native W3ResetAllBuffRace(client, raceid);

//set player shell glowish color (blood mage, shadow hunter), highest override priority takes effect, all integers
stock W3SetPlayerColor(client, raceid, r, g, b, a = 255,
        overridepriority = GLOW_DEFAULT) {
    War3_SetBuff(client, iGlowRed, raceid, r);
    War3_SetBuff(client, iGlowGreen, raceid, g);
    War3_SetBuff(client, iGlowBlue, raceid, b);
    War3_SetBuff(client, iGlowAlpha, raceid, a);
    War3_SetBuff(client, iGlowPriority, raceid, overridepriority);
    War3_SetBuff(client, fGlowSetTime, raceid, GetGameTime());
}
stock W3ResetPlayerColor(client, raceid) {
    W3SetPlayerColor(client, raceid, 255, 255, 255, _, 0);
}

//getting buffs
native W3GetBuffLoopLimit(); //buff loop size , item count + race count + others, loop from 0 to <this return value
native any:W3GetBuff(client,W3Buff:buffindex,RaceIDorItemID,IPassedItemID=false);
native bool:W3GetBuffHasTrue(client,W3Buff:buffindex); //does this buff have one true (activated?)
native W3GetBuffSumInt(client,W3Buff:buffindex);
native Float:W3GetBuffStackedFloat(client,W3Buff:buffindex); //get buff stacked value of an buff, use appropriately
native Float:W3GetBuffSumFloat(client,W3Buff:buffindex);
native Float:W3GetBuffMinFloat(client,W3Buff:buffindex);
native Float:W3GetBuffMaxFloat(client,W3Buff:buffindex);
native W3GetBuffLastValue(client,W3Buff:buffindex);
native W3GetBuffMinInt(client,W3Buff:buffindex);

//calculate player speed next frame
native W3ReapplySpeed(client);

//get the effective speed multipler for TF
native W3GetSpeedMulti(client); 

stock bool:W3HasImmunity(client,War3Immunity:immunityindex) 
{
    if(!ValidPlayer(client))
    {
        return false;
    }
    //add magic immunity etc later
    if(immunityindex==Immunity_Abilities) {
        return W3GetBuffHasTrue(client,bImmunityAbilities);
    }
    if(immunityindex==Immunity_Items) {
        return W3GetBuffHasTrue(client,bImmunityItems);
    }
    if(immunityindex==Immunity_Skills) {
        return W3GetBuffHasTrue(client,bImmunitySkills);
    }
    if(immunityindex==Immunity_Ultimates) {
        return W3GetBuffHasTrue(client,bImmunityUltimates);
    }
    if(immunityindex==Immunity_Wards) {
        return W3GetBuffHasTrue(client,bImmunityWards);
    }

    return false;

}
//Is the player immune to other people's skills
stock bool:IsSkillImmune(client) {
    return W3GetBuffHasTrue(client,bImmunitySkills);
}

//Is the player immune to other people's ultimates
stock bool:IsUltImmune(client) {
    return W3GetBuffHasTrue(client,bImmunityUltimates);
}

//is player stunned?
stock bool:Stunned(client) {
    return W3GetBuffHasTrue(client,bStunned);
}

//is player silenced?
//block active skill ACTIVATION
//silence still should allow skill PROC, item PROC, and item ACTIVATION
//auto cast spells should be blocked
stock bool:Silenced(client,printSilenced=true) {
    new bool:silenced=(W3GetBuffHasTrue(client,bSilenced)||Stunned(client));
    if(silenced&&printSilenced) {
        if(IsPlayerAlive(client)) {
            if(Stunned(client))
            {
                PrintHintText(client,"%T","You are stunned",client);
            }
            else
            {
                PrintHintText(client,"%T","You are silenced",client);
            }
        }
        if(Stunned(client))
        {
            PrintToConsole(client,"%T","You are stunned, cannot activate skill",client);
        }
        else
        {
            PrintToConsole(client,"%T","You are silenced, cannot activate skill",client);
        }
    }
    return silenced;
}

//is player hexed? (OUR definition is: no skill proc, usually from chance based skills)
stock bool:Hexed(client,printmsg=true) {
    new bool:status=(W3GetBuffHasTrue(client,bHexed)||W3GetBuffHasTrue(client,bStunned));
    if(status&&printmsg) {

        if(Stunned(client))
        {
            PrintToConsole(client,"%T","You are stunned, cannot proc skill",client);
        }
        else
        {
            PrintToConsole(client,"%T","You are hexed, cannot proc skill",client);
        }
    }
    return status;
}

//is player perplexed, (no item activation, no item proc by chance)
stock bool:Perplexed(client,printmsg=true) {
    new bool:perplexed=(W3GetBuffHasTrue(client,bPerplexed)||W3GetBuffHasTrue(client,bStunned));
    if(perplexed&&printmsg) {

        if(Stunned(client))
        {
            PrintToConsole(client,"%T","You are stunned, cannot activate item",client);
        }
        else
        {
            PrintToConsole(client,"%T","You are perplexed, cannot activate item",client);
        }
    }
    return perplexed;
}