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

#define	CLASS_NAME				"npc_cso_zm3"
#define	CLASS_TIP				"CSO Zombie (3)"
#define NPC_HEALTH 				250.0
#define NPC_SPEED 				220.0
#define NPC_GRAVITY 				250.5
#define NPC_ATTACK 				15.0
#define NPC_DEFENCE 				1.0
#define NPC_HEDEFENCE 				0.0
#define NPC_HITSPEED 				0.0
#define NPC_HITDELAY				0.0
#define NPC_REGENDLY				0.0
#define NPC_HITREGENDLY				0.0
#define NPC_KNOCKBACK				1.0
#define NPC_ANI_DEATH_HEADSHOT			104.0
#define NPC_ANI_DEATH_NORMAL_SIMPLE 		101.0
#define NPC_ANI_DEATH_NORMAL_BACK		107.0
#define NPC_ANI_DEATH_NORMAL_FORWARD 		109.0
#define NPC_ANI_DEATH_NORMAL_SPECIAL 		103.0
#define NPC_ANI_ATTACKED			99.0
#define NPC_ANI_IDLE				1.0
#define NPC_ANI_MADNESS				75.0
#define NPC_ANI_ATTACK				76.0
#define NPC_ANI_RUN				4.0
#define NPC_ANI_WALK				3.0
#define NPC_ANI_JUMP				6.0
#define NPC_EVENT				1.0
#define NPC_ATTACK_RELOADING			1.034
#define NPC_ATTACK_RELOADING_WAITTIME		1.8


new g_class_modelindex
new g_class_pmodel[164] = "models/player/nrs_cso_big/nrs_cso_big.mdl"


new const zombie_death[][] = {
	"npc_shared_sounds/zombi_death_1.wav",
	"npc_shared_sounds/zombi_death_2.wav"
}
new const zombie_pain[][] = {
	"npc_shared_sounds/zombi_hurt_01.wav",
	"npc_shared_sounds/zombi_hurt_02.wav"
}
stock zombie_sound_precache()
{
	new i;
	for(i = 0; i < sizeof(zombie_death); i++)
		engfunc(EngFunc_PrecacheSound, zombie_death[i])
	for(i = 0; i < sizeof(zombie_pain); i++)
		engfunc(EngFunc_PrecacheSound, zombie_pain[i])
}


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
	register_plugin("CSO : NPC Classic Zombie","1.0","Good_Hash")
}



public event_npc_death(dead_ent, killer)
{
	if ( !pev_valid(dead_ent) || ( get_npc_id(dead_ent) != g_npc_id ))
		return;
	
	emit_sound(dead_ent, CHAN_AUTO, zombie_death[random_num(0, charsmax(zombie_death))], 0.8, ATTN_NORM, 0, PITCH_NORM)
	
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
		set_npc_events(ent, EVENT_AGRESSION)//EVENT_ZOMBIE_VOID)
		if ( random_num(0,10) <= 3 )
			npc_set_berserker(ent, 1)
	}
}

public event_npc_damage(ent, victim, Float:damage)
	if ( pev_valid(ent) )
		if ( get_npc_id(ent) == g_npc_id )
		{
			if ( is_user_alive(victim) )
				if ( random_num(0,10) <= 3 )
					npc_set_berserker(ent, 1)
			emit_sound(victim, CHAN_AUTO, zombie_pain[random_num(0, charsmax(zombie_pain))], damage > 50.0 ? 1.0 : 0.8, ATTN_NORM, 0, PITCH_NORM)
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
		set_npc_data(g_npc_id, DATA_EVENT, NPC_EVENT)
		set_npc_data(g_npc_id, DATA_ATTACK_RELOADING, NPC_ATTACK_RELOADING)
		set_npc_data(g_npc_id, DATA_MODEL_INDEX, float(g_class_modelindex))
		set_npc_data(g_npc_id, DATA_ATTACK_WAITTIME, NPC_ATTACK_RELOADING_WAITTIME)
		
		
		// Berserker ability..
		set_npc_data(g_npc_id, DATA_MADANI_ATTACK, NPC_ANI_ATTACK)
		set_npc_data(g_npc_id, DATA_MADANI_ATTACK_TIME, NPC_ATTACK_RELOADING)
		set_npc_data(g_npc_id, DATA_MADANI_ATTACK_WAIT, NPC_ATTACK_RELOADING_WAITTIME)
		set_npc_data(g_npc_id, DATA_MADANI_IDLE, NPC_ANI_IDLE)
		set_npc_data(g_npc_id, DATA_MADANI_WALK, NPC_ANI_RUN)
		set_npc_data(g_npc_id, DATA_MADANI_RUN, NPC_ANI_RUN)
		
		
		set_npc_model(g_npc_id, g_class_pmodel)
		set_npc_data(g_npc_id, DATA_BLOOD_COLOR, 194.0)
	}
	
	zombie_sound_precache()
}
