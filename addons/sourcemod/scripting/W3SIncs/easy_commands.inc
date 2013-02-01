#include <sourcemod>
#define MAX_PARAMS 16
#if !defined INVALID_ARGS_RESPONSE
 #define INVALID_ARGS_RESPONSE "[SM] Usage: %s"
#endif
#if !defined INVALID_ARGS_RESPONSE_TRANSLATED
 #define INVALID_ARGS_RESPONSE_TRANSLATED "[SM] Usage: %T"
#endif
enum CmdParam
{
	Cmd_All = 0,
	Cmd_Cell,
	Cmd_Float,
	Cmd_String,
	Cmd_Filter,
	Cmd_Filter_Single
};
/* Example:
#include <sourcemod>
#include <easy_commands>
#include <sdktools_functions>
public Plugin:myinfo = 
{
	name = "Slap command!",
	author = "necavi",
	description = "Supplies a single command to slap any player.",
	version = "1.0",
	url = "http://necavi.org"
}

public OnPluginStart()
{
	RegEasyAdminCmd("sm_slap2 <playerfilter> [damage]", Command_Slap, Admin_Cheats, { Cmd_Filter, Cmd_Cell }, 2, 1);
}
public Command_Slap(client, targets[], numTargets, damage)
{
	if(damage < 0)
	{
		damage = 0;
	}
		
	for(new i = 1; i < numTargets; i++)
	{
		SlapPlayer(i, damage);
	}
}  
*/
new Handle:__g_hCmds__ = INVALID_HANDLE;
new Handle:__g_hCmdsFull__ = INVALID_HANDLE;
new Handle:__g_hCmdParamReq__ = INVALID_HANDLE;
new Handle:__g_hCmdParams__ = INVALID_HANDLE;
new Handle:__g_hCmdParamTotal__ = INVALID_HANDLE;
new Handle:__g_hCmdFunc__ = INVALID_HANDLE;
new Handle:__g_hCmdFilterFlags__ = INVALID_HANDLE;
new Handle:__g_hCmdTargetReply__ = INVALID_HANDLE;
new Handle:__g_hCmdIsTranslated__ = INVALID_HANDLE;

stock __InitArrays__()
{
	if(__g_hCmds__ == INVALID_HANDLE)
	{
		__g_hCmds__ = CreateArray(32);
		__g_hCmdsFull__ = CreateArray(64);
		__g_hCmdParams__ = CreateArray(MAX_PARAMS);
		__g_hCmdParamReq__ = CreateArray(1);
		__g_hCmdParamTotal__ = CreateArray(1);
		__g_hCmdFunc__ = CreateArray(1);
		__g_hCmdFilterFlags__ = CreateArray(1);
		__g_hCmdTargetReply__ = CreateArray(1);
		__g_hCmdIsTranslated__ = CreateArray(1);
	}
} 	
stock RegEasyConCmd(String:command[], Function:func, _:params[]={0}, totalParams = 0, reqParams = 0, filterFlags = 0, replyNoTargetFound = true)
{
	__InitArrays__();
	new String:cmd[1][32];
	ExplodeString(command, " ", cmd, sizeof(cmd), sizeof(cmd[]));
	PushArrayArray(__g_hCmdParams__, params);
	PushArrayCell(__g_hCmdParamTotal__, totalParams);
	PushArrayCell(__g_hCmdParamReq__, reqParams);
	PushArrayString(__g_hCmds__, cmd[0]);
	PushArrayString(__g_hCmdsFull__, command);
	PushArrayCell(__g_hCmdFunc__, func);
	PushArrayCell(__g_hCmdFilterFlags__, filterFlags);
	PushArrayCell(__g_hCmdTargetReply__, replyNoTargetFound);
	PushArrayCell(__g_hCmdIsTranslated__, false);
	RegConsoleCmd(cmd[0], __Handle_ConCmd__, command);
}
stock RegEasyAdminCmd(String:command[], Function:func, AdminFlag:flag = Admin_Generic, _:params[] = {0}, totalParams = 0, reqParams = 0, filterFlags = 0, replyNoTargetFound = true)
{
	__InitArrays__();
	new String:cmd[1][32];
	ExplodeString(command, " ", cmd, sizeof(cmd), sizeof(cmd[]));
	PushArrayArray(__g_hCmdParams__, params);
	PushArrayCell(__g_hCmdParamTotal__, totalParams);
	PushArrayCell(__g_hCmdParamReq__, reqParams);
	PushArrayString(__g_hCmds__, cmd[0]);
	PushArrayString(__g_hCmdsFull__, command);
	PushArrayCell(__g_hCmdFunc__, func);
	PushArrayCell(__g_hCmdFilterFlags__, filterFlags);
	PushArrayCell(__g_hCmdTargetReply__, replyNoTargetFound);
	PushArrayCell(__g_hCmdIsTranslated__, false);
	RegAdminCmd(cmd[0], __Handle_ConCmd__, FlagToBit(flag), command);
} 	
stock RegEasyConCmdT(String:command[], Function:func, _:params[]={0}, totalParams = 0, reqParams = 0, filterFlags = 0, replyNoTargetFound = true)
{
	__InitArrays__();
	new String:cmd[1][32];
	ExplodeString(command, " ", cmd, sizeof(cmd), sizeof(cmd[]));
	PushArrayArray(__g_hCmdParams__, params);
	PushArrayCell(__g_hCmdParamTotal__, totalParams);
	PushArrayCell(__g_hCmdParamReq__, reqParams);
	PushArrayString(__g_hCmds__, cmd[0]);
	PushArrayString(__g_hCmdsFull__, command);
	PushArrayCell(__g_hCmdFunc__, func);
	PushArrayCell(__g_hCmdFilterFlags__, filterFlags);
	PushArrayCell(__g_hCmdTargetReply__, replyNoTargetFound);
	PushArrayCell(__g_hCmdIsTranslated__, true);
	RegConsoleCmd(cmd[0], __Handle_ConCmd__, command);
}
stock RegEasyAdminCmdT(String:command[], Function:func, AdminFlag:flag = Admin_Generic, _:params[] = {0}, totalParams = 0, reqParams = 0, filterFlags = 0, replyNoTargetFound = true)
{
	__InitArrays__();
	new String:cmd[1][32];
	ExplodeString(command, " ", cmd, sizeof(cmd), sizeof(cmd[]));
	PushArrayArray(__g_hCmdParams__, params);
	PushArrayCell(__g_hCmdParamTotal__, totalParams);
	PushArrayCell(__g_hCmdParamReq__, reqParams);
	PushArrayString(__g_hCmds__, cmd[0]);
	PushArrayString(__g_hCmdsFull__, command);
	PushArrayCell(__g_hCmdFunc__, func);
	PushArrayCell(__g_hCmdFilterFlags__, filterFlags);
	PushArrayCell(__g_hCmdTargetReply__, replyNoTargetFound);
	PushArrayCell(__g_hCmdIsTranslated__, true);
	RegAdminCmd(cmd[0], __Handle_ConCmd__, FlagToBit(flag), command);
}
public Action:__Handle_ConCmd__(client, args)
{
	decl String:command[32];
	GetCmdArg(0, command, sizeof(command));
	new cmdnum = FindStringInArray(__g_hCmds__, command);
	if(cmdnum > -1)
	{
		if(GetArrayCell(__g_hCmdParamReq__, cmdnum) <= args)
		{
			Call_StartFunction(GetMyHandle(), GetArrayCell(__g_hCmdFunc__,cmdnum));
			Call_PushCell(client);
			new CmdParam:params[GetArrayCell(__g_hCmdParamTotal__,cmdnum)];
			GetArrayArray(__g_hCmdParams__, cmdnum, params);
			new String:buffer[128];
			for(new i = 0; i < GetArrayCell(__g_hCmdParamTotal__, cmdnum); i++)
			{
				if(params[i] == Cmd_All)
				{
					GetCmdArgString(buffer, sizeof(buffer));
					Call_PushString(buffer);
				} else if(params[i] == Cmd_Cell)
				{
					GetCmdArg(i + 1, buffer, sizeof(buffer));
					Call_PushCell(StringToInt(buffer));
				} else if(params[i] == Cmd_Float)
				{
					GetCmdArg(i + 1, buffer, sizeof(buffer));
					Call_PushFloat(StringToFloat(buffer));
				} else if(params[i] == Cmd_Filter || params[i] == Cmd_Filter_Single)
				{
					GetCmdArg(i + 1, buffer, sizeof(buffer));
					decl targets[MaxClients];
					decl String:target_name[32];
					new bool:tn_is_ml;
					new total = ProcessTargetString(buffer, client, targets, MaxClients, GetArrayCell(__g_hCmdFilterFlags__, cmdnum), target_name, sizeof(target_name), tn_is_ml);
					if(total == 0 && bool:GetArrayCell(__g_hCmdTargetReply__, cmdnum))
					{
						ReplyToTargetError(client, total);
						Call_Cancel();
						return Plugin_Handled;
					}
					if(params[i] == Cmd_Filter)
					{
						Call_PushArray(targets, total);
						Call_PushCell(total + 1);
					} else {
						if(total > 0)
						{
							Call_PushCell(targets[i]);
						} else {
							Call_PushCell(-1);
						}
					}
				} else if(params[i] == Cmd_String)
				{
					GetCmdArg(i + 1, buffer, sizeof(buffer));
					Call_PushString(buffer);
				}
			}
			Call_Finish();
		} else {
			new String:reply[64];
			GetArrayString(__g_hCmdsFull__, cmdnum, reply, sizeof(reply));
			if(bool:GetArrayCell(__g_hCmdIsTranslated__, cmdnum))
			{
				ReplyToCommand(client, INVALID_ARGS_RESPONSE_TRANSLATED, reply, client);
			} else {
				ReplyToCommand(client, INVALID_ARGS_RESPONSE, reply);
			}
		}
	}
	return Plugin_Handled;
}

