#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define UBERCHAIN_VERSION "0.1"
#define SLOT_PRIMARY 0
#define SLOT_SECONDARY 1
#define SLOT_MELEE 2

new Handle:g_NoPrimary = INVALID_HANDLE;
new Handle:g_OpposingSlots = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Uberchain Helper",
	author = "Forward Command Post",
	description = "A plugin to help with uberchain duels.",
	version = UBERCHAIN_VERSION,
	url = "http://fwdcp.net"
}

public OnPluginStart()
{
	g_NoPrimary = CreateConVar("sm_uberchain_noprimary", "1", "determines whether the uberchain plugin will remove and block primary weapons", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_OpposingSlots = CreateConVar("sm_uberchain_opposingslots", "1", "determines whether the uberchain plugin will force medics to have only one weapon and one medigun out at a time", FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanSwitchTo, NoPrimary);
	SDKHook(client, SDKHook_WeaponCanUse, NoPrimary);
	SDKHook(client, SDKHook_WeaponSwitchPost, SwitchPartnerWeapon);
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (GetConVarBool(g_NoPrimary))
	{
		TF2_RemoveWeaponSlot(client, SLOT_PRIMARY);
	}
	
	if (GetConVarBool(g_OpposingSlots))
	{
		new teammate = FindTeammate(client);
		
		if (IsPlayerAlive(teammate))
		{
			decl String:currentWeapon[64];
			decl String:teammateWeapon[64];
			GetClientWeapon(client, currentWeapon, sizeof(currentWeapon));
			GetClientWeapon(teammate, teammateWeapon, sizeof(teammateWeapon));
			
			new primary = GetPlayerWeaponSlot(client, SLOT_PRIMARY);
			new secondary = GetPlayerWeaponSlot(client, SLOT_SECONDARY);
			new melee = GetPlayerWeaponSlot(client, SLOT_MELEE);
			
			if (StrEqual(teammateWeapon, "tf_weapon_syringegun_medic") || StrEqual(teammateWeapon, "tf_weapon_crossbow") || StrEqual(teammateWeapon, "tf_weapon_bonesaw"))
			{
				if (!StrEqual(currentWeapon, "tf_weapon_medigun"))
				{
					EquipPlayerWeapon(client, secondary);
				}
			}
			else if (StrEqual(teammateWeapon, "tf_weapon_medigun"))
			{
				if (StrEqual(currentWeapon, "tf_weapon_medigun"))
				{	
					if (GetConVarBool(g_NoPrimary))
					{
						EquipPlayerWeapon(client, melee);
					}
					else
					{
						EquipPlayerWeapon(client, primary);
					}
				}
			}
		}
	}
}

public Action:NoPrimary(client, weapon)
{
	if (!GetConVarBool(g_NoPrimary))
	{
		return Plugin_Continue;
	}
	decl String:weaponClass[512];
	GetEdictClassname(weapon, weaponClass, sizeof(weaponClass));
	
	if (StrEqual(weaponClass, "tf_weapon_syringegun_medic") || StrEqual(weaponClass, "tf_weapon_crossbow"))
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public SwitchPartnerWeapon(client, weapon)
{
	if (!GetConVarBool(g_OpposingSlots))
	{
		return;
	}
	
	new teammate = FindTeammate(client);
		
	if (IsPlayerAlive(teammate))
	{
		decl String:teammateWeapon[64];
		GetClientWeapon(teammate, teammateWeapon, sizeof(teammateWeapon));
		
		new teammatePrimary = GetPlayerWeaponSlot(teammate, SLOT_PRIMARY);
		new teammateSecondary = GetPlayerWeaponSlot(teammate, SLOT_SECONDARY);
		new teammateMelee = GetPlayerWeaponSlot(teammate, SLOT_MELEE);
		
		if (weapon == GetPlayerWeaponSlot(client, SLOT_PRIMARY) || weapon == GetPlayerWeaponSlot(client, SLOT_MELEE))
		{
			if (!StrEqual(teammateWeapon, "tf_weapon_medigun"))
			{
				EquipPlayerWeapon(teammate, teammateSecondary);
			}
		}
		else if (weapon == GetPlayerWeaponSlot(client, SLOT_SECONDARY))
		{
			if (StrEqual(teammateWeapon, "tf_weapon_medigun"))
			{	
				if (GetConVarBool(g_NoPrimary))
				{
					EquipPlayerWeapon(teammate, teammateMelee);
				}
				else
				{
					EquipPlayerWeapon(teammate, teammatePrimary);
				}
			}
		}
	}
}

FindTeammate(client)
{
	new team = GetClientTeam(client);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientConnected(i) && IsClientInGame(i) && team == GetClientTeam(i))
		{
			return i;
		}
	}
	
	return 0;
}