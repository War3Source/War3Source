//adapted from http://forums.alliedmods.net/showthread.php?t=146674
#define CONVAR_NAME_SIZE 64
//returns cellreferenceid
#define  Pointer Handle

/**********************
 * creates a pointer (handle) to some variable, 
 * must be global or static as their memory address don't change, 
 * else it would write to random places in memory
 */ 
native Pointer:CreateCellReference(&any:cell);

/**********************
 * Get the value of what the pointer is pointing at, AKA get the value of the global/static variable
 */ 
native CellDereference(Pointer:cellreferenceid);

/**********************
 * Set the value of what the pointer is pointing at, AKA set the value of the global/static variable
 */ 
native SetCellByReference(Pointer:cellreferenceid,any:value);


enum ConVarType
{
	ConVarBool,
	ConVarInt,
	ConVarFloat//,
	//ConVarString
}
stock static Handle:ConVarTrie = INVALID_HANDLE;


/**
 * Links ConVar to an int.
 *
 * @param convar		ConVar to link.
 * @param buffer		Buffer to link to.
 * @return				True on success, false otherwise.
 */
stock bool:LinkConVar(const Handle:convar, &buffer)
{
	return LinkConVar_(convar, ConVarInt, buffer);
}

/**
 * Links ConVar to a float.
 *
 * @param convar		ConVar to link.
 * @param buffer		Buffer to link to.
 * @return				True on success, false otherwise.
 */
stock bool:LinkConVarFloat(const Handle:convar, &Float:buffer)
{
	return LinkConVar_(convar, ConVarFloat, buffer);
}



/**
 * Creates a new integer console variable and links it to a provided buffer.
 *
 * @param name			Name of new convar.
 * @param defaultvalue	String containing the default value of new convar.
 * @param buffer		Buffer to link to.
 * @param description	Optional description of the convar.
 * @param flags			Optional bitstring of flags determining how the convar
 *						should be handled. See FCVAR_* constants for more
 *						details.
 * @param hasmin		Optional boolean that determines if the convar has a
 *						minimum value.
 * @param min			Minimum floating point value that the convar can have if
 *						hasmin is true.
 * @param hasmax		Optional boolean that determines if the convar has a
 *						maximum value.
 * @param max			Maximum floating point value that the convar can have if
 *						hasmax is true.
 * @return				A handle to the newly created convar. If the convar
 *						already exists, a handle to it will still be returned.
 * @error				Convar name is blank or is the same as an existing
 *						console command.
 */
stock Handle:CreateConVarLinkedInt(const String:name[], const String:defaultvalue[], &buffer, const String:description[] = "", flags = 0, bool:hasmin = false, Float:min = 0.0, bool:hasmax = false, Float:max = 0.0)
{
	new Handle:convar = CreateConVar(name, defaultvalue, description, flags, hasmin, min, hasmax, max);
	if (!LinkConVar(convar, ConVarInt, buffer))
	{
		CloseHandle(convar);
		return INVALID_HANDLE;
	}
	return convar;
}

/**
 * Creates a new float console variable and links it to a provided buffer.
 *
 * @param name			Name of new convar.
 * @param defaultvalue	String containing the default value of new convar.
 * @param buffer		Buffer to link to.
 * @param description	Optional description of the convar.
 * @param flags			Optional bitstring of flags determining how the convar
 *						should be handled. See FCVAR_* constants for more
 *						details.
 * @param hasmin		Optional boolean that determines if the convar has a
 *						minimum value.
 * @param min			Minimum floating point value that the convar can have if
 *						hasmin is true.
 * @param hasmax		Optional boolean that determines if the convar has a
 *						maximum value.
 * @param max			Maximum floating point value that the convar can have if
 *						hasmax is true.
 * @return				A handle to the newly created convar. If the convar
 *						already exists, a handle to it will still be returned.
 * @error				Convar name is blank or is the same as an existing
 *						console command.
 */
stock Handle:CreateConVarLinkedFloat(const String:name[], const String:defaultvalue[], &Float:buffer, const String:description[]= "", flags = 0, bool:hasmin = false, Float:min = 0.0, bool:hasmax = false, Float:max = 0.0)
{
	new Handle:convar = CreateConVar(name, defaultvalue, description, flags, hasmin, min, hasmax, max);
	if (!LinkConVar(convar, ConVarFloat, buffer))
	{
		CloseHandle(convar);
		return INVALID_HANDLE;
	}
	return convar;
}

/**
 * Creates a new string console variable and links it to a provided buffer.
 *
 * @param name			Name of new convar.
 * @param defaultvalue	String containing the default value of new convar.
 * @param buffer		Buffer to link to.
 * @param size			Size of the provided buffer.
 * @param description	Optional description of the convar.
 * @param flags			Optional bitstring of flags determining how the convar
 *						should be handled. See FCVAR_* constants for more
 *						details.
 * @return				A handle to the newly created convar. If the convar
 *						already exists, a handle to it will still be returned.
 * @error				Convar name is blank or is the same as an existing
 *						console command.
 */
//stock Handle:CreateConVarLinkedString(const String:name[], const String:defaultvalue[], String:buffer[], const size, const String:description[] = "", flags = 0)
//{
//	new Handle:convar = CreateConVar(name, defaultvalue, description, flags);
//	if (!LinkConVarString(convar, buffer, size))
//	{
//		CloseHandle(convar);
//		return INVALID_HANDLE;
//	}
//	return convar;
//}

////////////////////////////////////////////////////////////////////////////////
// Internal functions below this line
////////////////////////////////////////////////////////////////////////////////

stock static bool:LinkConVar_(const Handle:convar, const ConVarType:type, &any:buffer)
{
	if (convar == INVALID_HANDLE)
	{
		return false;
	}
	if (ConVarTrie == INVALID_HANDLE)
	{
		ConVarTrie = CreateTrie();
	}
	decl String:convarname[CONVAR_NAME_SIZE];
	GetConVarName(convar, convarname, CONVAR_NAME_SIZE);
	switch (type)
	{
		case ConVarInt:
		{
			SetTrieValue(ConVarTrie, convarname, CreateCellReference(buffer));
			HookConVarChange(convar, ConVarIntChange);
			buffer = GetConVarInt(convar);
		}
		case ConVarFloat:
		{
			SetTrieValue(ConVarTrie, convarname, CreateCellReference(buffer));
			HookConVarChange(convar, ConVarFloatChange);
			buffer = GetConVarFloat(convar);
		}
	}
	return true;
}


public ConVarIntChange(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	ConVarChange(convar, ConVarInt, newvalue);
}

public ConVarFloatChange(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	ConVarChange(convar, ConVarFloat, newvalue);
}

//public ConVarStringChange(Handle:convar, const String:oldvalue[], const String:newvalue[])
//{
//	ConVarChange(convar, ConVarString, newvalue);
//}

stock static ConVarChange(const Handle:convar, const ConVarType:type, const String:newvalue[])
{
	decl String:convarname[CONVAR_NAME_SIZE];
	GetConVarName(convar, convarname, CONVAR_NAME_SIZE);
	new Handle:buffer;
	if (!GetTrieValue(ConVarTrie, convarname, buffer))
	{
		return;
	}
	switch (type)
	{
		case ConVarInt:
		{
			SetCellByReference(buffer, GetConVarInt(convar));
		}
		case ConVarFloat:
		{
			SetCellByReference(buffer, GetConVarFloat(convar));
		}
		//case ConVarString:
		//{
		//	SetHandleString(buffer, newvalue, GetHandleStringSize(buffer));
		//}
	}
}