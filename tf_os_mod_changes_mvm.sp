#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#include <stocklib_officerspy/tf/tf_gamerules>
#include <stocklib_officerspy/tf/tf_player>
#include <stocklib_officerspy/tf/tf_obj>

#define TF_DMG_CUSTOM_NONE	0

//The overriden damage from sentry bsuters against other giant robots in CTFPlayer::OnTakeDamage
#define SB_MAX_DMG_VS_MINIBOSS	600.0

ConVar os_gmc_mvm_bot_backstab_fix;
ConVar os_gmc_mvm_sentrybuster_damage_fix;
ConVar os_gmc_mvm_miniboss_kill_object_on_touch;

public Plugin myinfo =
{
	name = "[TF2] Officer Spy Game Mod Changes MvM",
	author = "Officer Spy",
	description = "Game-specific changes specifically for Mann vs Machine.",
	version = "1.0.2",
	url = ""
};

public void OnPluginStart()
{
	os_gmc_mvm_bot_backstab_fix = CreateConVar("sm_os_gmc_mvm_bot_backstab_fix", "1", "Fix bot players instantly killing MiniBosses with backstabs.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	os_gmc_mvm_sentrybuster_damage_fix = CreateConVar("sm_os_gmc_mvm_sentrybuster_damage_fix", "1", "Fix sentry busters instantly killing human MiniBosses and RED MiniBosses.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	os_gmc_mvm_miniboss_kill_object_on_touch = CreateConVar("sm_os_gmc_mvm_miniboss_kill_object_on_touch", "1", "Let human MiniBosses kill objects on touch.", FCVAR_NOTIFY);
}

public void OnMapStart()
{
	if (!TF2_IsMannVsMachineMode())
		LogError("This mod is meant to be used with the Mann vs Machine game mode.");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Player_OnTakeDamage);
	SDKHook(client, SDKHook_Touch, Player_TouchPost);
}

public Action Player_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	bool bChanged = false;
	
	if (BaseEntity_IsPlayer(attacker))
	{
		if (os_gmc_mvm_bot_backstab_fix.BoolValue)
		{
			if (damagecustom == TF_CUSTOM_BACKSTAB && BasePlayer_IsBot(attacker) && TF2_IsMiniBoss(victim))
			{
				float bonusDmg = TF2Attrib_HookValueFloat(1.0, "mult_dmg", weapon);
				damage = 250.0 * bonusDmg;
				
				float armorPiercing = TF2Attrib_HookValueFloat(25.0, "armor_piercing", attacker);
				damage *= ClampFloat(armorPiercing / 100.0, 0.25, 1.25);
				
				bChanged = true;
			}
		}
		
		if (os_gmc_mvm_sentrybuster_damage_fix.BoolValue)
		{
			if (damagecustom == TF_DMG_CUSTOM_NONE && damagetype & DMG_BLAST && damage > SB_MAX_DMG_VS_MINIBOSS && IsSentryBuster(attacker) && !IsSentryBuster(victim) && BasePlayer_IsBot(attacker) && TF2_IsMiniBoss(victim))
			{
				if (BasePlayer_IsBot(victim))
				{
					//Game already handles this for bots on the same team
					//Override damage against bots if teams are different
					if (GetClientTeam(attacker) != GetClientTeam(victim))
					{
						damage = SB_MAX_DMG_VS_MINIBOSS;
						
						bChanged = true;
					}
				}
				else
				{
					//Override damage against humans regardless of team
					damage = SB_MAX_DMG_VS_MINIBOSS;
					
					bChanged = true;
				}
			}
		}
	}
	
	return bChanged ? Plugin_Changed : Plugin_Continue;
}

public void Player_TouchPost(int entity, int other)
{
	if (os_gmc_mvm_miniboss_kill_object_on_touch.BoolValue)
	{
		if (!IsFakeClient(entity))
		{
			if (TF2_IsMiniBoss(entity))
			{
				if (BaseEntity_IsBaseObject(other))
				{
					if (TF2_GetObjectType(other) != TFObject_Sentry || TF2_IsMiniBuilding(other))
					{
						float damage = float(BaseEntity_GetHealth(other));
						//Do we really care about damage force?
						
						SDKHooks_TakeDamage(other, entity, entity, 4 * damage, DMG_BLAST);
					}
				}
			}
		}
	}
}

bool IsSentryBuster(int client)
{
	//TODO: find a better way to tell
	char model[PLATFORM_MAX_PATH]; GetClientModel(client, model, PLATFORM_MAX_PATH);
	
	return StrEqual(model, "models/bots/demo/bot_sentry_buster.mdl");
}

stock bool IsValidClientIndex(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}