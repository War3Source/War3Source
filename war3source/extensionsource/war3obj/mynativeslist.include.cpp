const sp_nativeinfo_t MyNatives[] = 
{
	{"CreateObj",			CreateObj},
	{"SetObj",					SetObj},
	{"GetObj",					GetObj},
	{"DeleteObj",					DeleteObj},
	{"GetObjStr",					GetObjStr},
	{"SetObjStr",					SetObjStr},

	{"CreateCellReference",					CreateCellReference},
	{"CellDereference",					CellDereference},
	{"SetCellByReference",					SetCellByReference},


	{NULL,							NULL}, // last entry is null, it marks the end for all the loop operations.
};

