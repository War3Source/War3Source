native War3_SetRaceConfigString(raceID, String:key[], String:value[]);
native War3_SetRaceConfigFloat(raceID, String:key[], Float:value);
native War3_SetRaceConfigInt(raceID, String:key[], value);
native War3_SetRaceConfigBool(raceID, String:key[], bool:value);
native War3_SetRaceConfigArray(raceID, String:key[], any:value[], maxlen, KvDataTypes:type = KvData_Float);
// Note! Allows you to define arrays that use strings for keys!
native War3_SetRaceConfigArrayValue(raceID, String:array[], String:key[], String:value[]);
native War3_SetRaceGlobalConfigString(String:key[], String:value[]);

native Float:War3_GetRaceConfigFloat(raceID, String:key[]);
native War3_GetRaceConfigInt(raceID, String:key[]);
native bool:War3_GetRaceConfigBool(raceID, String:key[]);
native War3_GetRaceConfigArray(raceID, String:key[], any:array[], maxlen, KvDataTypes:type = KvData_Float);
// Note! Allows you to define arrays that use strings for keys!
native War3_GetRaceConfigArrayValue(raceID, String:array[], String:key[], String:value[]);
native War3_GetRaceConfigString(raceID, String:key[], String:value[]);
native War3_GotoRaceConfigArray(raceID, String:array[]);
native bool:War3_GetRaceConfigArrayNextValue(String:value[]);

native War3_SetItemConfigString(ItemID, String:key[], String:value[]);
native War3_SetItemConfigFloat(ItemID, String:key[], Float:value);
native War3_SetItemConfigInt(ItemID, String:key[], value);
native War3_SetItemConfigBool(ItemID, String:key[], bool:value);
native War3_SetItemConfigArray(ItemID, String:key[], any:array[], maxlen, KvDataTypes:type = KvData_Float);
// Note! Allows you to define arrays that use strings for keys!
native War3_SetItemConfigArrayValue(ItemID, String:array[], String:key[], String:value[]);
native War3_SetItemGlobalConfigString(String:key[], String:value[]);

native Float:War3_GetItemConfigFloat(ItemID, String:key[]);
native War3_GetItemConfigInt(ItemID, String:key[]);
native bool:War3_GetItemConfigBool(ItemID, String:key[]);
native War3_GetItemConfigArray(ItemID, String:key[], any:value[], maxlen, KvDataTypes:type = KvData_Float);
// Note! Allows you to define arrays that use strings for keys!
native War3_GetItemConfigArrayValue(ItemID, String:array[], String:key[], String:value[]);
native War3_GetItemConfigString(ItemID, String:key[], String:value[]);
native War3_GotoItemConfigArray(raceID, String:array[]);
native bool:War3_GetItemConfigArrayNextValue(String:value[]);