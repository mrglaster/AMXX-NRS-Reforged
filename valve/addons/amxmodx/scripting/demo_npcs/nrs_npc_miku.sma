#include <amxmodx>
#include <hamsandwich>
#include <fakemeta_util>
#include <engine>
#include <nrs_main>
#include <nrs_const>

//#define WAR3FT_SUPPORT	1

#if defined WAR3FT_SUPPORT
#include <la2a>
#endif

#define	CLASS_NAME				"npc_miku"
#define	CLASS_TIP				"Miku ( Shooting )"
#define NPC_HEALTH 				100.0
#define NPC_SPEED 				260.0
#define NPC_GRAVITY 				250.5
#define NPC_ATTACK 				15.0
#define NPC_DEFENCE 				1.0
#define NPC_HEDEFENCE 				0.0
#define NPC_HITSPEED 				0.0
#define NPC_HITDELAY				0.0
#define NPC_REGENDLY				0.0
#define NPC_HITREGENDLY				0.0
#define NPC_KNOCKBACK				0.5
#define NPC_ANI_DEATH_HEADSHOT			104.0
#define NPC_ANI_DEATH_NORMAL_SIMPLE 		101.0
#define NPC_ANI_DEATH_NORMAL_BACK		107.0
#define NPC_ANI_DEATH_NORMAL_FORWARD 		109.0
#define NPC_ANI_DEATH_NORMAL_SPECIAL 		103.0
#define NPC_ANI_ATTACKED			75.0
#define NPC_ANI_IDLE				1.0
#define NPC_ANI_MADNESS				1.0
#define NPC_ANI_ATTACK				76.0
#define NPC_ANI_RUN				4.0
#define NPC_ANI_WALK				3.0
#define NPC_ANI_JUMP				6.0
#define NPC_EVENT				0.0
#define NPC_ATTACK_RELOADING			2.0
#define NPC_ATTACK_RELOADING_WAITTIME		1.8
#define NPC_ANI_IDLE_SHOOT 			34.0
#define NPC_ANI_RELOAD				35.0
#define NPC_WEAPON_DAMAGE			19.0
#define NPC_WEAPON_CLIP				30.0


new g_class_modelindex
new g_class_pmodel[164] = "models/player/nrs_npc_miku/nrs_npc_miku.mdl"


stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
    
	replace_all(msg, 190, "!g", "^4") 
	replace_all(msg, 190, "!y", "^1") 
	replace_all(msg, 190, "!r", "^3") 
	replace_all(msg, 190, "!b", "^0")
    
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), {0,0,0}, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}


new g_npc_id

public plugin_init() 
{         
	register_plugin("L4D : NPC Classic Zombie","1.0","Good_Hash")
	
	register_concmd("npc_test", "cmd_create")
}


public cmd_create(id)
{
	set_pev(id, pev_health, 10000.0)
}

public event_npc_death(dead_ent, killer)
{
	if ( !pev_valid(dead_ent) || ( get_npc_id(dead_ent) != g_npc_id ))
		return;
	#if defined WAR3FT_SUPPORT
		new to_give = random_num(35, 75)
		change_user_xp(killer, to_give )
		ChatColor(killer, "!gЗа убийство зомби !r+%i!g опыта!", to_give)
	#endif
}
	
public event_npc_init(ent)
{
	if ( !pev_valid(ent) )
		return;
	if ( get_npc_id(ent) == g_npc_id )
	{
		//set_npc_think(ent_id, value)
		set_npc_events(ent, EVENT_SHOOTER)//EVENT_ZOMBIE_VOID)
	}
}


public plugin_precache()
{
	g_class_modelindex = precache_model(g_class_pmodel);
	
	g_npc_id = register_npc(CLASS_NAME, CLASS_TIP)

	if(g_npc_id != -1)
	{
		set_npc_data(g_npc_id, DATA_HEALTH, NPC_HEALTH)
		set_npc_data(g_npc_id, DATA_SPEED, NPC_SPEED)
		set_npc_data(g_npc_id, DATA_ATTACK, NPC_ATTACK)
		set_npc_data(g_npc_id, DATA_SPEED, NPC_SPEED)
		set_npc_data(g_npc_id, DATA_DEFENCE, NPC_DEFENCE)
		set_npc_data(g_npc_id, DATA_HEDEFENCE, NPC_HEDEFENCE)
		set_npc_data(g_npc_id, DATA_HITSPEED, NPC_HITSPEED)
		set_npc_data(g_npc_id, DATA_HITDELAY, NPC_HITDELAY)
		set_npc_data(g_npc_id, DATA_REGENDLY, NPC_REGENDLY)
		set_npc_data(g_npc_id, DATA_HITREGENDLY, NPC_HITREGENDLY)
		set_npc_data(g_npc_id, DATA_KNOCKBACK, NPC_KNOCKBACK)
		set_npc_data(g_npc_id, DATA_ANI_DEATH_HEADSHOT, NPC_ANI_DEATH_HEADSHOT)
		set_npc_data(g_npc_id, DATA_ANI_DEATH_NORMAL_SIMPLE, NPC_ANI_DEATH_NORMAL_SIMPLE)
		set_npc_data(g_npc_id, DATA_ANI_DEATH_NORMAL_BACK, NPC_ANI_DEATH_NORMAL_BACK)
		set_npc_data(g_npc_id, DATA_ANI_DEATH_NORMAL_FORWARD, NPC_ANI_DEATH_NORMAL_FORWARD)
		set_npc_data(g_npc_id, DATA_ANI_DEATH_NORMAL_SPECIAL, NPC_ANI_DEATH_NORMAL_SPECIAL)
		set_npc_data(g_npc_id, DATA_ANI_ATTACKED, NPC_ANI_ATTACKED)
		set_npc_data(g_npc_id, DATA_ANI_IDLE, NPC_ANI_IDLE)
		set_npc_data(g_npc_id, DATA_ANI_MADNESS, NPC_ANI_MADNESS)
		set_npc_data(g_npc_id, DATA_ANI_ATTACK, NPC_ANI_ATTACK)
		set_npc_data(g_npc_id, DATA_ANI_RUN, NPC_ANI_RUN)
		set_npc_data(g_npc_id, DATA_ANI_WALK, NPC_ANI_WALK)
		set_npc_data(g_npc_id, DATA_EVENT, EVENT_SHOOTER)
		set_npc_data(g_npc_id, DATA_ATTACK_RELOADING, NPC_ATTACK_RELOADING)
		set_npc_data(g_npc_id, DATA_MODEL_INDEX, float(g_class_modelindex))
		set_npc_data(g_npc_id, DATA_ATTACK_WAITTIME, NPC_ATTACK_RELOADING_WAITTIME)
		set_npc_data(g_npc_id, DATA_WEAPON_TYPE, WEAPON_M4A1)
		set_npc_data(g_npc_id, DATA_ANI_IDLE_SHOOT, NPC_ANI_IDLE_SHOOT)
		set_npc_data(g_npc_id, DATA_ANI_RELOAD, NPC_ANI_RELOAD)
		set_npc_data(g_npc_id, DATA_WEAPON_DAMAGE, 19.0)
		set_npc_data(g_npc_id, DATA_WEAPON_CLIP, NPC_WEAPON_CLIP)

		
		set_npc_model(g_npc_id, g_class_pmodel)
	}
}
