#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#include <stocklib_officerspy/player>
#include <stocklib_officerspy/tf/tf_player>

ConVar os_gmc_bot_backstab_fix;

public Plugin myinfo =
{
	name = "[TF2] Officer Spy Game Mod Changes",
	author = "Officer Spy",
	description = "Game-specific changes for general gameplay.",
	version = "0.0.0",
	url = ""
};

public void OnPluginStart()
{
	os_gmc_bot_backstab_fix = CreateConVar("sm_os_gmc_bot_backstab_fix", "1", "Fix bot players instant killing MiniBosses with backstabs.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Player_OnTakeDamage);
}

public Action Player_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (IsValidClientIndex(attacker))
	{
		if (os_gmc_bot_backstab_fix.BoolValue && BasePlayer_IsBot(attacker) && TF2_IsMiniBoss(victim) && damagecustom == TF_CUSTOM_BACKSTAB)
		{
			float bonusDmg = TF2Attrib_HookValueFloat(1.0, "mult_dmg", weapon);
			damage = 250.0 * bonusDmg;
			
			float armorPiercing = TF2Attrib_HookValueFloat(25.0, "armor_piercing", attacker);
			damage *= ClampFloat(armorPiercing / 100.0, 0.25, 1.25);
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

stock bool IsValidClientIndex(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}

stock float ClampFloat(const float val, const float minVal, const float maxVal)
{
	if (val < minVal)
		return minVal;
	else if (val > maxVal)
		return maxVal;
	else
		return val;
}