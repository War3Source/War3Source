
/**
 * Description: Manage precaching resources.
 * Author(s): Frenzzy
 */
 
#include "W3SIncs/War3Source_L4D_Interface"

/**
 * Adds a file to the downloadables network string table.
 *
 * @param filename		File that will be added to downloadables table.
 * @noreturn
 */
stock W3AddFile(const String:filename[])
{
	if (FileExists(filename)) {
		AddFileToDownloadsTable(filename);
	} else {
		ThrowError("File \"%s\" not found", filename);
	}
}

/**
 * Add to downloads table and precaches a given sound.
 *
 * @param sound			Name of the sound to download and precache.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return Returns the sound index if precache is true, 0 for error or precache is false. 
 */
stock W3AddSound(const String:sound[], bool:precache = true, bool:preload = true)
{
	decl String:path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "sound/%s", sound);
	if (FileExists(path)) {
		AddFileToDownloadsTable(path);
		if (precache){
			return PrecacheSound(sound, preload);
		}
		
	} else {
		ThrowError("Sound file \"%s\" not found", path);
	}
	return 0;
}
//precache sound    and adds to download table, an older function
stock bool:War3_PrecacheSound(String:sound[]){

	new String:longsound[512];
	
	Format(longsound,sizeof(longsound), "sound/%s", sound);
	
	/* Glider: L4D doesn't allow you to download files from a server, in fact
	 * 		   if you add something to the download table clients won't be
	 * 		   able to connect at all!
	 */
	if(!War3_IsL4DEngine())
	{
		AddFileToDownloadsTable(longsound); 
	}
	
	if(PrecacheSound(sound, true)){
		//PrintToServer("TWar3_PrecacheSound %s",longsound);
		return true;
	}
	else{
		PrintToServer("Fail War3_PrecacheSound %s",longsound);	
	}
	return false;
}

/**
 * Add to downloads table and precaches a given model.
 *
 * @param model			Name of the model to download and precache.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return Returns the model index if precache is true, 0 for error or precache is false. 
 */
stock W3AddModel(const String:model[], bool:precache = true, bool:preload = true)
{
	if (FileExists(model)) {
		AddFileToDownloadsTable(model);
		if (precache)
			return PrecacheModel(model, preload);
		
	} else {
		ThrowError("Model file \"%s\" not found", model);
	}
	return 0;
}

/**
 * Add to downloads table and precaches a given decal.
 *
 * @param decal			Name of the decal to download and precache.
 * @param precache		If precache is true the file will be precached.
 * @param preload		If preload is true the file will be precached before level startup.
 * @return Returns the Decal index if precache is true, 0 for error or precache is false. 
 */
stock W3AddDecal(const String:decal[], bool:precache = true, bool:preload = true)
{
	if (FileExists(decal)) {
		AddFileToDownloadsTable(decal);
		if (precache)
			return PrecacheModel(decal, preload);
	} else {
		ThrowError("Decal file \"%s\" not found", decal);
	}
	return 0;
}

//precache particle    doesn't add to download table
//Revan: Just something I found while searching tru the sm forums
stock War3_PrecacheParticle( const String:p_strEffectName[] )
{
	static s_numStringTable = INVALID_STRING_TABLE;
	if ( s_numStringTable == INVALID_STRING_TABLE  )
		s_numStringTable = FindStringTable( "ParticleEffectNames" );
	AddToStringTable( s_numStringTable, p_strEffectName );
}
