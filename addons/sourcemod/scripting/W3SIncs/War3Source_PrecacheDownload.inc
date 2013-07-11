/**
 * File: War3Source_PreacacheDownload.inc
 * Description: Various functions for precaching or adding to the download table
 * Author(s): War3Source Team  
 */
/**
 * Adds a file to the downloadables network string table.
 *
 * @param filename        File that will be added to downloadables table.
 * @noreturn
 */
stock War3_AddFile(const String:filename[])
{
    if (FileExists(filename)) 
    {
        AddFileToDownloadsTable(filename);
    } 
    else 
    {
        ThrowError("File \"%s\" not found", filename);
    }
}

/**
 * Add to downloads table and precaches a given sound.
 *
 * @param sound            Name of the sound to download and precache.
 * @param precache         If precache is true the file will be precached.
 * @param preload          If preload is true the file will be precached before level startup.
 * 
 * @return True if successfully precached, false otherwise.
 */
stock bool:War3_AddCustomSound(const String:sound[], bool:precache = true, bool:preload = true)
{
    decl String:path[PLATFORM_MAX_PATH];
    Format(path, sizeof(path), "sound/%s", sound);
    if (FileExists(path)) 
    {
        AddFileToDownloadsTable(path);
        if (precache)
        {
            return PrecacheSound(sound, preload);
        }
        
    } 
    else 
    {
        War3_LogError("Sound file \"%s\" not found", path);
    }
    
    return false;
}

/**
 * Add to downloads table and precaches a given model.
 *
 * @param model            Name of the model to download and precache.
 * @param precache        If precache is true the file will be precached.
 * @param preload        If preload is true the file will be precached before level startup.
 * 
 * @return Model index or 0
 */
stock War3_AddCustomModel(const String:model[], bool:precache = true, bool:preload = true)
{
    if (FileExists(model)) 
    {
        AddFileToDownloadsTable(model);
        if (precache)
        {
            return PrecacheModel(model, preload);
        }
        
    } 
    else 
    {
        ThrowError("Model file \"%s\" not found", model);
    }
    
    return 0;
}

/**
 * Add to downloads table and precaches a given decal.
 *
 * @param decal            Name of the decal to download and precache.
 * @param precache        If precache is true the file will be precached.
 * @param preload        If preload is true the file will be precached before level startup.
 * 
 * @return True if successfully precached, false otherwise.
 */
stock War3_AddCustomDecal(const String:decal[], bool:precache = true, bool:preload = true)
{
    if (FileExists(decal)) 
    {
        AddFileToDownloadsTable(decal);
        if (precache)
        {
            return PrecacheModel(decal, preload);
        }
        
    } 
    else 
    {
        ThrowError("Decal file \"%s\" not found", decal);
    }
    
    return false;
}

/**
 * Precache a particle without adding it to the download table
 */
stock War3_PrecacheParticle( const String:p_strEffectName[] )
{
    static s_numStringTable = INVALID_STRING_TABLE;
    if (s_numStringTable == INVALID_STRING_TABLE)
    {
        s_numStringTable = FindStringTable("ParticleEffectNames");
    }
    AddToStringTable(s_numStringTable, p_strEffectName );
}