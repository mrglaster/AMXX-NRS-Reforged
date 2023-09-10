#include <amxmodx>
#include <amxmisc>
#tryinclude <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs> 
#include <dhudmessage>
//#pragma dynamic 65536


#define RADIANS_TO_DEGREES(%1) ((%1) * 57.29577951308232)
#define SWITCH_METHOD_VER_ANG_THRESHOLD 30.0
#define VER_HOR_ASPECT_RATIO 0.75
//#define DEBUG 1
#if defined DEBUG
new Float:g_think_delay[33]
#endif


#tryinclude "nrs_main.cfg"


#define PLUGIN 							"NPC REGISTER SYSTEM : Public Edition"
#define	TITLE							"[NRS]"
#define VERSION 						"4.45"
#define AUTHOR 							"Good_Hash"


#define MAX_NPC  						1056
#define MAX_CLASSES 						35
#define MAX_DATA						46
#define CUSTOM_MOVE_OFF						-999.9

#include <nrs_const>

#define GetPlayerHullSize(%1)  ( ( pev ( %1, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN )
    
// some engine ways to do..
enum
{
	THINK_DEATH = 1,
	THINK_REMOVE,
	THINK_DESTROY = 3
}



// weapon section
enum
{
	WEAPON_TYPE = 0,
	WEAPON_NAME,
	WEAPON_DAMAGE,
	WEAPON_SPEED,
	WEAPON_RECOIL,
	WEAPON_RADIUS
}



enum
{
	TASK_INIT = 1044,
	TASK_WAKEUP,
	TASK_DAMAGE,
	TASK_RESET
}

new const bullet_gib[][] = {
	"npc_shared_sounds/bullet_gib_01.wav",
	"npc_shared_sounds/bullet_gib_02.wav",
	"npc_shared_sounds/bullet_gib_03.wav",
	"npc_shared_sounds/bullet_gib_04.wav",
	"npc_shared_sounds/bullet_gib_05.wav",
	"npc_shared_sounds/bullet_gib_06.wav"
}

new maxentities
new bool:b_Mode
stock spr_bomb, cache_laserbeam, gibtype

new  bool:g_roundstarted, bool:g_roundended, bool:g_gamestarted, g_maxplayers, g_hamnpc, g_fwd_reset, g_fwd_npc_damage_start, g_fwd_npc_damage_delayed, g_fwd_death, g_fwd_hook_catched, g_fwd_missile_catched, g_fwd_casting_range, g_fwd_casting_outrange, g_fwd_npc_kills, g_fwd_npc_damage, g_fwd_initiation, g_fwd_gamestart, g_fwd_roundend, g_fwd_result, 
	g_sprite, cache_blood, cache_bloodspray,
	Float:g_fRemovecheck_timer, g_class_name[MAX_CLASSES+1][MAX_NPC], g_classcount, g_class_desc[MAX_CLASSES+1][MAX_NPC], g_class_pmodel[MAX_CLASSES+1][164], 
	g_npc_ids[MAX_NPC], bool:g_npc_inattack[MAX_NPC], bool:g_valid_npc[MAX_NPC], g_npc_berserker[MAX_NPC], Float:g_npc_attack_delay[MAX_NPC], Float:g_class_data[MAX_CLASSES+1][MAX_DATA], bool:g_summoned_npc[MAX_NPC],
	bool:g_ent_jumped[MAX_NPC]
    
new g_Created_Npc = 0, g_To_Remove[MAX_NPC][2], g_Remover_Eng = 0, bool:g_disabled_Ent_Forwards, HamHook:g_entTrace, HamHook:g_entTakeDamage, HamHook:g_entThink, HamHook:g_entTouch,
	/*Float:g_fGetWay[MAX_NPC][3],*/ g_Entity_HIT_PLACE[MAX_NPC][33], g_madness[MAX_NPC], g_class_id[MAX_NPC], Float:g_ent_events[MAX_NPC], g_think[MAX_NPC], npc_victim[MAX_NPC],
	Float:g_think_jump_cd[MAX_NPC], Float:g_last_attack_reloadtime[MAX_NPC],  Float:g_last_jump_anim[MAX_NPC],
	g_owner[MAX_NPC], g_drag_i[MAX_NPC], g_hooked[MAX_NPC], bool:g_unable2move[MAX_NPC], bool:g_mage[MAX_NPC], bool:g_boss[MAX_NPC], 
	npc_custom_enemy[MAX_NPC], Float:npc_custom_targets[MAX_NPC], Float:npc_custom_foes[MAX_NPC], npc_custom_animation[MAX_NPC], Float:npc_custom_move[MAX_NPC][3], Float:g_custommoving_speed[MAX_NPC]
    
new Float:g_reach_point[MAX_NPC][3], Float:g_last_enemy_seek[MAX_NPC], Float:g_last_attack_time[MAX_NPC], Float:g_touch_cd[MAX_NPC], Float:npc_hudinfo_delay[33], Float:g_Last_Good_Z[MAX_NPC]
new gMsgScreenFade, g_SyncHUD[2], g_tv[33], g_tv_custom[MAX_NPC], camera[ 33 ], Float:g_tv_sleep_time[MAX_NPC], Float:g_control_hud[33], Float:g_SavedOrigin[33][3]
new const g_camera_model[] =  "models/shell.mdl"

// Got pain?
#define PA_LOW  5.0
#define PA_HIGH 25.0

// Spawn-system
new const SPAWNS_FILE[] = "%s/nrs_configs/npc_%s.cfg"
const MAX_SPAWNS = 128
new Float:g_spawns[MAX_SPAWNS][3], g_total_spawns, Float:g_spawns_boss[MAX_SPAWNS][3], g_total_spawns_boss

// Learning system..
// Beta version, it can't be perfect, as I want =(
/*const g_max_waypoints = 5000
new g_got_ways = 0, g_waypoints = 0, g_done_waypoints[33], Float:g_Ways[33][g_max_waypoints][3], Float:way_delay[33], bool:g_way_founded[MAX_NPC], g_npc_way[MAX_NPC]*/
#define max_way_points	100
new Float:g_way_point[MAX_NPC][3], npc_way_target[MAX_NPC], g_way_counter[MAX_NPC], bool:g_way_jump_counter[MAX_NPC][max_way_points], g_way_point_index[MAX_NPC]
new Float:point[MAX_NPC][max_way_points][3], last_npc_created, Float:extra = 0.15
new const Float:MY_FOV = 30.0 // 60.0
new const Float:MY_FOV_POWER = 35.0//35.0
new const Float:MY_JUMP_POWER = 35.0
new const MAX_CHECKS = 6
		

// Including system..
// For learning another npc..
new Float:g_custom_npc[MAX_NPC], Float:g_custom_npc_speed[MAX_NPC]


// Weapon system.
new g_clip[MAX_NPC], g_npc_weapon[MAX_NPC], Float:g_shoot_reloadtime[MAX_NPC], Float:g_2damage[MAX_NPC]
new const ent_weapon_m4a1[] = "models/p_m4a1.mdl"


// Health-bar system..
new g_health_bar[MAX_NPC], Float:g_health_bar_z[MAX_NPC]
new const ClassHp[] = "BossHp"
new const BossSpriteHp[] = "sprites/npc/hp.spr"

// 4 Native
#define MAX_LOAD_MAPS	45
new bool:NOT_BB = true, bool:z_okay, MAPS_COUNT = 0, MAP_LOAD_NAME[MAX_LOAD_MAPS][125]


// New damage delay
#define UPDATE_TIME		0.1
#define ENTITY_CLASS		"nrs_set_task"
#define D_ent			0
#define D_victim		1
#define D_damage		2
#define D_damage_time		3
#define D_speed_time		4
#define D_corpse_time		5
#define D_env_damage_time	6
#define D_reset_speed_time	7
#define D_ALL			8
new g_THINKER_DELAY[MAX_NPC][D_ALL]

new npc_user_victim[33], npc_user_attacker[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary("nrs_main.txt")
	
	
	new Mode[32];
	formatex(Mode, 31, "NRS : Public Edition v%s", VERSION);
	register_cvar(Mode, VERSION, FCVAR_SERVER | FCVAR_SPONLY);
	
	g_disabled_Ent_Forwards = true;
	maxentities = get_global_int(GL_maxEntities);
	g_maxplayers = get_maxplayers();
	g_SyncHUD[0] = CreateHudSyncObj( 1 );
	g_SyncHUD[1] = CreateHudSyncObj( 2 );
	gMsgScreenFade = get_user_msgid("ScreenFade");
	
	new file[64]
	get_configsdir(file, 63)
	format(file, 63, "%s/bh_cvars.cfg", file)
	
	if(file_exists(file)) 
		server_cmd("exec %s", file)
		
	
	register_clcmd("say /npc", 			"NRS_Admin_Menu"							);
	register_clcmd("say /npc100", 			"NRS_Admin_Menu100"							);
	register_clcmd("say /tvtest",			"TV_test"								);
	register_clcmd("say /tvstop",			"TV_stop"								);
	//register_clcmd("say /tv",			"Watch_Zombie"								);
	register_clcmd("say /debug",			"DEBUG_MODE"								);
	//register_clcmd( "drop", 				"Got_Drop_Command"							);
	
	register_forward(FM_Touch, 			"bullet_touch"								);
	register_forward(FM_TraceLine,			"traceline"		, 1						);
	#if defined DEBUG
	register_forward(FM_PlayerPreThink, "client_think") // debug only!
	#endif
	register_event("DeathMsg",			"hook_death"		,"a"						);
	register_event("Damage" , 			"event_Damage" 		, "b" 			, "2>0"			);
	register_logevent("logevent_round_start", 2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_think(ClassHp, 				"Boss_ThinkHp"								);
	
	
	set_task( 10.0, "checkTimeleft" );
	
	
	g_fwd_initiation = CreateMultiForward("event_npc_init", ET_IGNORE, FP_CELL)
	g_fwd_npc_kills = CreateMultiForward("event_npc_kills", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwd_death = CreateMultiForward("event_npc_death", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwd_casting_range = CreateMultiForward("event_npc_casting_range", ET_IGNORE, FP_CELL, FP_CELL, FP_FLOAT)
	g_fwd_missile_catched = CreateMultiForward("event_missile_catch", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_fwd_hook_catched = CreateMultiForward("event_hook_catch", ET_IGNORE, FP_CELL, FP_CELL, FP_FLOAT)
	g_fwd_casting_outrange = CreateMultiForward("event_npc_casting_outrange", ET_IGNORE, FP_CELL)
	g_fwd_npc_damage = CreateMultiForward("event_npc_damage", ET_IGNORE, FP_CELL, FP_CELL, FP_FLOAT)
	g_fwd_npc_damage_start = CreateMultiForward("event_npc_damage_start", ET_CONTINUE, FP_CELL)
	g_fwd_npc_damage_delayed = CreateMultiForward("event_npc_damage_delayed", ET_IGNORE, FP_CELL)
	g_fwd_gamestart = CreateMultiForward("event_gamestarted", ET_IGNORE)
	g_fwd_roundend = CreateMultiForward("event_round_ended", ET_IGNORE)
	g_fwd_reset = CreateMultiForward("event_npc_reset", ET_IGNORE)
	
	
	
	new iMapName[53], tFile[150], cfgdir[32], Len, i=0
	get_mapname( iMapName, 52 ); 
	
	if ( equali(iMapName, "zp_boss_dangerous") || equali(iMapName, "npc_dangerous")  )
	{
		z_okay = false
	}else z_okay = true
	
	get_configsdir(cfgdir, 63)
	format(tFile, charsmax(tFile), "%s/nrs_configs/surviral_mod_config.cfg", cfgdir)
	if(file_exists(tFile))
	{
		while(i < MAX_LOAD_MAPS && read_file(tFile, i , MAP_LOAD_NAME[MAPS_COUNT], 63, Len))
		{
			i++
			if(MAP_LOAD_NAME[MAPS_COUNT][0] == ';' || !Len)
			{
				continue
			}
			MAPS_COUNT++
		}
	}
	
	for ( i = 0; i < MAPS_COUNT; i++ )
	{
		if ( equali(iMapName, MAP_LOAD_NAME[i]) || containi(iMapName, "tls_" ) !=- 1 || containi(iMapName, "zs_" ) !=- 1 || containi(iMapName, "npc_" ) !=- 1 )
		{
			b_Mode = true;
		}
	}
	
	if ( containi(iMapName, "tls_" ) != -1 )
		NOT_BB = false
		
	set_task(5.0, "check_ent_destroy")
}

public DEBUG_MODE(id)
{
	if ( is_user_admin(id) )
		set_pev(id, pev_maxspeed, 1000.0)
}
	
#if defined DEBUG
public client_think(id)
{
	if ( g_think_delay[id] <= get_gametime() )
	{
		if ( is_user_alive(id) )
		{
			new Float:fOrigin[3], Float:OriginAngle[3], Float:hitOrigin[3], Float:origin2[3], hitent, Float:got_distance
			
			pev(id, pev_origin, fOrigin)
			pev(id, pev_angles, OriginAngle)//entity_get_vector(id,EV_VEC_v_angle,OriginAngle)
			origin2[0] = fOrigin[0] + (floatcos(OriginAngle[1] + MY_FOV, degrees) * MY_FOV_POWER); 
			origin2[1] = fOrigin[1] + (floatsin(OriginAngle[1] + MY_FOV, degrees) * MY_FOV_POWER); 
			origin2[2] = fOrigin[2]// + (floatsin(-OriginAngle[0] + MY_FOV, degrees) * 38.0); 
			hitent = trace_line(id, fOrigin, origin2, hitOrigin) 
			got_distance = vector_distance(fOrigin, hitOrigin)
						
			if ( hitent || got_distance <= MY_FOV_POWER)
				Create_TE_BEAMPOINTS(fOrigin, origin2, g_sprite, 0, 0, 1, 15, 0, 255, 0, 0, 255, 0)
			else 
				Create_TE_BEAMPOINTS(fOrigin, origin2, g_sprite, 0, 0, 1, 15, 0, 0, 255, 0, 255, 0)
						
			origin2[0] = fOrigin[0] + (floatcos(OriginAngle[1] - MY_FOV, degrees) * MY_FOV_POWER); 
			origin2[1] = fOrigin[1] + (floatsin(OriginAngle[1] -MY_FOV, degrees) *  MY_FOV_POWER); 
			origin2[2] = fOrigin[2]// + (floatsin(-OriginAngle[0] - MY_FOV, degrees) * 38.0); 
			hitent = trace_line(id, fOrigin, origin2, hitOrigin) 
			got_distance = vector_distance(fOrigin, hitOrigin)
			if ( hitent || got_distance <= MY_FOV_POWER)
				Create_TE_BEAMPOINTS(fOrigin, origin2, g_sprite, 0, 0, 1, 15, 0, 255, 0, 0, 255, 0)
			else 
				Create_TE_BEAMPOINTS(fOrigin, origin2, g_sprite, 0, 0, 1, 15, 0, 0, 255, 0, 255, 0)
			
			new Float:fOriginJump[3]
			fOriginJump = fOrigin
			fOriginJump[2] -= 38.0
			origin2[0] = fOriginJump[0] + (floatcos(OriginAngle[1], degrees) * MY_JUMP_POWER); 
			origin2[1] = fOriginJump[1] + (floatsin(OriginAngle[1], degrees) *  MY_JUMP_POWER); 
			origin2[2] = fOriginJump[2] + (floatsin(-OriginAngle[0], degrees) *  MY_JUMP_POWER); 
			hitent = trace_line(id, fOrigin, origin2, hitOrigin) 
			if ( vector_distance(origin2, hitOrigin)<21.0)
			{
				Create_TE_BEAMPOINTS(fOriginJump, hitOrigin, g_sprite, 0, 0, 1, 15, 0, 255, 255, 0, 255, 0)
				set_hudmessage(0, 255, 0, -0.2, -1.0,_,0.99, 0.99, _,_,-1)
				show_hudmessage(id, "My Origin: %i %i %i^nJump (%s): %i", floatround(fOrigin[0]),floatround(fOrigin[1]), floatround(fOrigin[2]),
				"Y", floatround(vector_distance(origin2, hitOrigin)))
			}
			else
			{
				Create_TE_BEAMPOINTS(fOriginJump, hitOrigin, g_sprite, 0, 0, 1, 15, 0, 255, 0, 0, 255, 0)
				set_hudmessage(0, 255, 0, -0.2, -1.0,_,0.99, 0.99, _,_,-1)
				show_hudmessage(id, "My Origin: %i %i %i^nJump (%s): %i", floatround(fOrigin[0]),floatround(fOrigin[1]), floatround(fOrigin[2]),
				"N", floatround(vector_distance(origin2, hitOrigin)))
			}
		}
		g_think_delay[id] = get_gametime()+1.0
	}
}
#endif


public checkTimeleft( ) 
{
	register_think( ENTITY_CLASS, "fwdThink_Updater" );
	
	new iEntityTimer = create_entity( "info_target" );
	entity_set_string( iEntityTimer, EV_SZ_classname, ENTITY_CLASS );
	entity_set_float( iEntityTimer, EV_FL_nextthink, get_gametime() + UPDATE_TIME );
}



public check_ent_destroy()
{
	if ( get_cvar_num("nrs_builder")) NOT_BB = false;
}

public plugin_end()
{
	logevent_round_start()
}



public event_Damage(id) 
{
	if ( !is_user_alive(id) || is_user_bot(id) || is_user_connected( get_user_attacker(id) )  ) 
		return;
	
	new Float:fVec[3];
	fVec[0] = random_float(PA_LOW , PA_HIGH);
	fVec[1] = random_float(PA_LOW , PA_HIGH);
	fVec[2] = random_float(PA_LOW , PA_HIGH);
	entity_set_vector(id , EV_VEC_punchangle , fVec);
	ScreenFade(id, random_num(2,5), 255, 0, 0, 90)
}

stock ScreenFade(id, Timer, Colors1, Colors2, Colors3, Alpha)
{
	if(!is_user_connected(id)) return
	
	message_begin(MSG_ONE_UNRELIABLE, gMsgScreenFade, _, id);
	write_short((1<<12) * Timer)
	write_short(1<<12)
	write_short(0)
	write_byte(Colors1)
	write_byte(Colors2)
	write_byte(Colors3)
	write_byte(Alpha)
	message_end()
}


public Boss_ThinkHp(Hp)
{
	new szMaxFrames[4], max_frames, Float:current_frame, npc = g_health_bar[Hp]
	if (!pev_valid(npc) )
	{
		if ( pev_valid(Hp) )
			remove_entity(Hp)
		return
	}
	
	static Float: Origin[3], Float:Procent, Float:f_health
	
	pev(Hp, pev_targetname, szMaxFrames, 3)
	max_frames = str_to_num(szMaxFrames)
	
	pev(npc, pev_health, f_health)
	Procent = f_health * 100.0 / g_class_data[g_class_id[npc]][DATA_HEALTH]
	if ( Procent > 100.0) Procent = 100.0
	
	current_frame = Procent * max_frames / 100
	
	set_pev(Hp, pev_frame, current_frame)
	pev(npc, pev_origin, Origin)
	Origin[2] += g_health_bar_z[Hp]
	set_pev(Hp, pev_origin, Origin)
	set_pev(Hp, pev_nextthink, get_gametime() + 0.1)
}


public TV_test(id)
{
	attach_view(id, last_npc_created)
}
public TV_stop(id)
	attach_view(id, id)

public Watch_Zombie(id)
{
	if ( !is_user_admin(id) )
		return PLUGIN_HANDLED
		
	if ( g_tv[id] < 1 )
		pev(id, pev_origin, g_SavedOrigin[id])
		
	if ( Switch_Zombie(id, 0) )
	{
		new Float:tO[3]
		
		tO[0] = g_SavedOrigin[id][0]
		tO[1] = g_SavedOrigin[id][1]
		tO[2] = -2500.9
		set_pev(id, pev_origin, tO)
	}
	
	return PLUGIN_HANDLED
}

public Switch_Zombie(id, last)
{	
	new NPC = FindNPC(id, last)
	
	if ( pev_valid(camera[id]) )
		attach_view(id, camera[id])
	else
	{
		create_camera( id )
		if ( camera[id])
			attach_view(id, camera[id])
		else
			attach_view(id, NPC)
	}
	
	if ( NPC > 33 )
		return 1
	return 0
}


stock FindNPC(id, start = 0)
{
	if ( !start || start > MAX_NPC )
		start = 1;
	
	new i, bool:found = false
	for ( i=start; i<MAX_NPC; ++i )
	{
		if ( pev_valid(i) && !is_user_connected(i) )
		{
			if ( g_valid_npc[i] && pev(i, pev_health) )
			{
				g_tv[id] = i
				found = true
			}
		}
	}
	if ( !found )
	{
		for ( i=1; i<start; ++i )
		{
			if ( pev_valid(i) && !is_user_connected(i) )
			{
				if ( g_valid_npc[i] )
				{
					g_tv[id] = i
				}
			}
		}
	}
	if ( !pev_valid(g_tv[id]) )
		g_tv[id] = id
	else
		g_tv_custom[g_tv[id]] = 3
		
	return g_tv[id]
}

public client_connect(id)
{
	g_tv[id] = 0
	npc_user_victim[id] = npc_user_attacker[id] = 1
}


	
stock bomb_led(const Float:point[3]) 
{ 
	#if defined DEBUG
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_GLOWSPRITE) 
	engfunc(EngFunc_WriteCoord, point[0]) 
	engfunc(EngFunc_WriteCoord, point[1]) 
	engfunc(EngFunc_WriteCoord, point[2]) 
	write_short(spr_bomb) 
	write_byte(1) 
	write_byte(3) 
	write_byte(255) 
	message_end() 
	#endif
} 


/*public client_PreThink(id)
{
	if ( is_user_connected(id) )
	{
		static buttons, oldbuttons;
		buttons = pev(id, pev_button);
		oldbuttons = pev(id, pev_oldbuttons)
		
		if ( g_tv[id] && !is_user_connected(g_tv[id]) )
		{
			if ( !pev_valid(g_tv[id]) || !pev(g_tv[id], pev_health) )
			{
				g_tv[id] = 0
				attach_view(id,id)
				g_tv_custom[g_tv[id]] = 0
				//g_Ways[id][random_num(0, g_done_waypoints[id])]
				
				if(camera[id] > 0 && pev_valid(camera[id]))
				{
					remove_entity(camera[id])
					camera[id] = 0
				}
				 //set_pev(id, pev_origin, g_SavedOrigin[id] )
				
				return
			}
			
			new ent = g_tv[id];
			new idle_anim = true
			
			if ( g_tv_custom[ent] == 3 )
			{
				new Float: flAngles[ 3 ];
	
				pev( id, pev_angles, flAngles );
			
				new Float: ConAngles[ 3 ];
				if ( g_class_data[g_class_id[ent]][DATA_WEAPON_TYPE] <= WEAPON_KNIFE )
					ConAngles[ 0 ] = 0.0;
				ConAngles[ 1 ] = flAngles[ 1 ];
				ConAngles[ 2 ] = flAngles[ 2 ];
				entity_set_vector( ent, EV_VEC_angles, ConAngles );
				set_pev(ent, pev_v_angle, ConAngles)
				
				// addon
				set_pev(ent, pev_angles, ConAngles)
				set_pev(ent, pev_view_ofs, ConAngles)
			}
			
			if(pev_valid(camera[id])) // credits for camera to Sam Tsuki (mc_oberon)
			{
				new Float: iOrigin[ 3 ], Float: CamOrigin[ 3 ];
				entity_get_vector( ent, EV_VEC_origin, iOrigin );
				new Float: v_angle[ 3 ], Float: angles[ 3 ];
				entity_get_vector( ent, EV_VEC_angles, angles );
				entity_get_vector( ent, EV_VEC_v_angle, v_angle );
				for( new Float: i = 200.0; i >= 0.0; i -= 0.1 )
				{
					CamOrigin[ 0 ] = floatcos( v_angle[ 1 ], degrees ) * -i;
					CamOrigin[ 1 ] = floatsin( v_angle[ 1 ], degrees ) * -i;
					CamOrigin[ 2 ] = i - ( i / 4 );
					CamOrigin[ 0 ] += iOrigin[ 0 ];
					CamOrigin[ 1 ] += iOrigin[ 1 ];
					CamOrigin[ 2 ] += iOrigin[ 2 ];
					if( PointContents( CamOrigin ) != CONTENTS_SOLID && PointContents( CamOrigin ) != CONTENTS_SKY )
						break;
				}
				v_angle[ 0 ] = 20.0
				entity_set_origin( camera[ id ], CamOrigin );
				entity_set_vector( camera[ id ], EV_VEC_angles, v_angle );
				entity_set_vector( camera[ id ], EV_VEC_v_angle, v_angle );
			}
	
			
			if ((buttons & IN_ATTACK2) && (oldbuttons & IN_ATTACK2))
			{
				if  ( g_control_hud[id] < get_gametime() )
					Switch_Zombie_ControlMode(ent)
			}
			
			if  ( g_control_hud[id] < get_gametime() )
			{
				set_hudmessage(0, 255, 50, -0.15, -0.75, _, _, 2.5)
				
				new mode[50]
				switch ( g_tv_custom[ent] )
				{
					case 1 : formatex(mode, 49, "%L", id,"NRS_CONTROLL_MODE_1")
					case 2 : formatex(mode, 49, "%L", id,"NRS_CONTROLL_MODE_2")
					case 3 : formatex(mode, 49, "%L", id,"NRS_CONTROLL_MODE_3")
					default: formatex(mode, 49, "%L", id,"NRS_CONTROLL_MODE_0")
				}
				
				ShowSyncHudMsg(id, g_SyncHUD[1], "%L", LANG_PLAYER, "NRS_HUD_CONTROLL", pev(ent, pev_health), g_clip[ent], mode);
				g_control_hud[id] = get_gametime()+0.9
			}
				
			if (buttons & IN_USE)
			{
				g_tv_custom[ent] = 0
				g_tv[id] = 0;
				attach_view(id, id )
				set_pev(id, pev_origin, g_SavedOrigin[id] )
				if(camera[id] > 0 && pev_valid(camera[id])) 
				{
					remove_entity(camera[id])
					camera[id] = 0
				}
			}
			
			if ( g_last_attack_reloadtime[ent] >= get_gametime() || g_tv_sleep_time[ent] >= get_gametime() )
			{
				return
			}
				
			if(buttons & IN_MOVELEFT)
			{
				Simulate_Walking_Strafe(g_tv[id], true)
				idle_anim = false;
			}
			if(buttons & IN_MOVERIGHT)
			{
				Simulate_Walking_Strafe(g_tv[id])
				idle_anim = false;
			}
			if (buttons & IN_FORWARD)
			{
				if ( oldbuttons & IN_MOVERIGHT )
					Simulate_Walking(ent, true, false, true)
				else if ( oldbuttons & IN_MOVELEFT )
					Simulate_Walking(ent, true, true, false)
				else
					Simulate_Walking(ent)
				idle_anim = false;
			}
			if (buttons & IN_BACK)
			{
				if ( oldbuttons & IN_MOVERIGHT )
					Simulate_Walking(ent, false, false, true)
				else if ( oldbuttons & IN_MOVELEFT )
					Simulate_Walking(ent, false, true, false)
				else
					Simulate_Walking(ent, false)
				idle_anim = false;
			}
			if(buttons & IN_JUMP)
			{
				if (oldbuttons & IN_FORWARD ) 
					Simulate_Forward_Jump(ent)
				else if (oldbuttons & IN_BACK ) 
					Simulate_Forward_Jump(ent, true)
				else
					Simulate_Jump(ent)
				idle_anim = false;
			}
			if ((buttons & IN_ATTACK) && (oldbuttons & IN_ATTACK))
			{
				Simulate_Attack ( ent )
				idle_anim = false;
			}
			
			switch( g_ent_events[ent] )
			{
				case EVENT_SLEEP:
				{
					NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_IDLE]) );
				}
				default:
				{
					if ( idle_anim && (g_last_attack_reloadtime[ent] <= get_gametime() || g_tv_sleep_time[ent] >= get_gametime()) )
						NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_IDLE]) );
				}
			}
		}
	}
}*/

public Got_Drop_Command(id)
{
	if ( is_user_connected(id) && g_tv[id] && g_tv[id]>33 )
		Switch_Zombie(id, g_tv[id]+1)
		
	return PLUGIN_CONTINUE
}


// projects a center of a player's feet base (originally by P34nut, improved)
stock Float:fm_distance_to_floor2(index, ignoremonsters = 1) {
	new Float:start[3], Float:dest[3], Float:end[3];
	pev(index, pev_origin, start);
	dest[0] = start[0];
	dest[1] = start[1];
	dest[2] = -8191.0;

	engfunc(EngFunc_TraceLine, start, dest, ignoremonsters, index, 0);
	get_tr2(0, TR_vecEndPos, end);

	pev(index, pev_absmin, start);
	new Float:ret = start[2] - end[2];

	return ret > 0 ? ret : 0.0;
}



public NRS_Shoot( shooter, victim, Float:Origin[3], Float:VicOrigin[3] )
{
	if ( !pev_valid(shooter) )
		return
		
	if ( g_clip[shooter] > 0 )
	{
		if ( g_shoot_reloadtime[shooter]> get_gametime() )
			return
		create_laze(Origin, VicOrigin, {255,0,0})
		g_shoot_reloadtime[shooter] = get_gametime()+random_float(0.5, 1.0)
		g_clip[shooter]--
		emit_sound(shooter, CHAN_WEAPON, "weapons/m4a1-1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
		fake_take_damage(shooter, victim, g_class_data[g_class_id[shooter]][DATA_WEAPON_DAMAGE])
	}
	else
	{
		g_tv_sleep_time[shooter] = get_gametime() + 2.5
		NRS_set_animation(shooter, floatround(g_class_data[g_class_id[shooter]][DATA_ANI_RELOAD]) );
		task_exists(shooter+911) ? 0 : set_task(2.6, "reset_clip", shooter+911)
		task_exists(shooter+912) ? 0 : set_task(0.1, "nice_reload_anim", shooter+911)
	}		
}

public nice_reload_anim(ent)
{
	ent -= 911
	if ( !pev_valid(ent) )
		return
	NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_RELOAD]) );
	#if defined g_Cstrike
		emit_sound(ent, CHAN_WEAPON, "weapons/m4a1_clipout.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
	#endif
}

public reset_clip(ent)
{
	ent -= 911
	if ( !pev_valid(ent) )
		return
	g_clip[ent] = floatround(g_class_data[g_class_id[ent]][DATA_WEAPON_CLIP])
	#if defined g_Cstrike
		emit_sound(ent, CHAN_WEAPON, "weapons/m4a1_boltpull.wav", 0.8, ATTN_NORM, 0, PITCH_NORM)
	#endif
}

public bullet_clip(ent)
{
	ent -= 909
	if ( !pev_valid(ent) )
		return
	entity_set_int(ent, EV_INT_movetype, 5)
	entity_set_int(ent, EV_INT_solid, 1)
}

public remove_bullet(ent)
{
	ent -= 910
	if ( !pev_valid(ent) )
		return
	remove_entity(ent)
}



create_laze(const Float:start[3], const Float:end[3], const color[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BEAMPOINTS)	// temp entity event
	write_coord(floatround(start[0]))		// startposition: x
	write_coord(floatround(start[1]))		// startposition: y
	write_coord(floatround(start[2]))		// startposition: z
	write_coord(floatround(end[0]))		// endposition: x
	write_coord(floatround(end[1]))		// endposition: y
	write_coord(floatround(end[2]))		// endposition: z
	write_short(cache_laserbeam)	// sprite index
	write_byte(0)			// start frame
	write_byte(0)			// framerate
	write_byte(1)			// life in 0.1's
	write_byte(10)			// line width in 0.1's
	write_byte(0)			// noise amplitude in 0.01's
	write_byte(color[0])		// color: red
	write_byte(color[1])		// color: green
	write_byte(color[2])		// color: blue
	write_byte(200)			// brightness
	write_byte(255)			// scroll speed in 0.1's
	message_end()
}


public bullet_touch(ent, target)
{
	if ( pev_valid(ent) )
	{
		new classname[32]
		
		entity_get_string(ent, EV_SZ_classname, classname, 31)
		if ( pev_valid(target) )
		{
			new classname2[32]
			entity_get_string(target, EV_SZ_classname, classname2, 31)
			
			if(equal(classname, "npc_bullet") && equal(classname2, classname))
				return
		}

		if(equal(classname, "npc_bullet") )
		{	
			if ( g_valid_npc[target] || is_user_alive(target) )
				fake_take_damage(ent, target, g_2damage[ent])
			
			remove_entity(ent)
		}
	}

}


stock Simulate_Attack ( ent )
{
	if ( g_last_attack_reloadtime[ent] >= get_gametime() )
		return
	
	if ( g_class_data[g_class_id[ent]][DATA_WEAPON_TYPE] > WEAPON_KNIFE )
	{
		//NRS_Shoot( ent )
		NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_IDLE_SHOOT]), 1 );
		return
	}
	
	static victim
	victim = FindVictim(ent)
				
	static Float:Origin[3], Float:VicOrigin[3], Float:distance
	new Float:ftime
	if  (g_npc_berserker[ent])
		ftime = g_class_data[g_class_id[ent]][DATA_MADANI_ATTACK_WAIT];
	else
		ftime = g_class_data[g_class_id[ent]][DATA_ATTACK_WAITTIME];
	
	pev(ent, pev_origin, Origin)
	pev(victim, pev_origin, VicOrigin)
				
	distance = vector_distance(Origin, VicOrigin)		
			
	if(is_user_alive(victim))
	{
		if(distance <= 60.0)
		{				
			//witch_attack(ent, victim)
			//entity_set_float(ent, EV_FL_nextthink, get_gametime() + ftime);
		}
	}
		
	g_tv_sleep_time[ent] = get_gametime() + ftime
	NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_ATTACK]) );
}


stock Switch_Zombie_ControlMode(ent)
{
	if ( g_tv_custom[ent] >= 3 )
		g_tv_custom[ent] = 0
	else
		g_tv_custom[ent]++
}

stock Simulate_Jump(ent)
{
	if ( g_last_jump_anim[ent] >= get_gametime() )
		return
		
	NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_JUMP]) );
	
	static Float:Direction[3]
	static Float:viewAngles[3]
	
	pev(ent, pev_v_angle, viewAngles)
	angle_vector(viewAngles, ANGLEVECTOR_UP, Direction);
	xs_vec_mul_scalar(Direction, 450.0, Direction)
	set_pev(ent, pev_velocity, Direction)
	
	g_last_jump_anim[ent] =get_gametime()+1.0;
}

stock Simulate_Forward_Jump(ent, back = false)
{
	if ( g_last_jump_anim[ent] >= get_gametime() )
		return
		
	NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_JUMP]) );
	
	static Float:Direction[3]
	static Float:viewAngles[3]
	static Float:Temp_Z
	
	pev(ent, pev_v_angle, viewAngles)
	angle_vector(viewAngles, ANGLEVECTOR_UP, Direction);
	xs_vec_mul_scalar(Direction, 450.0, Direction)
	Temp_Z = Direction[2]
	
	pev(ent, pev_v_angle, viewAngles)
	angle_vector(viewAngles, ANGLEVECTOR_FORWARD, Direction);
	xs_vec_mul_scalar(Direction, 0.8*g_class_data[g_class_id[ent]][DATA_SPEED], Direction)
	if ( back ) xs_vec_neg(Direction, Direction)
	Direction[2] = Temp_Z
	set_pev(ent, pev_velocity, Direction)
	
	g_last_jump_anim[ent] =get_gametime()+1.0;
}


stock Simulate_Walking_Strafe(ent, back = false)
{
	if ( g_last_jump_anim[ent] >= get_gametime() )
		return
		
	NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_RUN]) );
	
	static Float:Direction[3]
	static Float:viewAngles[3]
	
	pev(ent, pev_v_angle, viewAngles)
	angle_vector(viewAngles, ANGLEVECTOR_RIGHT, Direction);
	xs_vec_mul_scalar(Direction, 0.8*g_class_data[g_class_id[ent]][DATA_SPEED], Direction)
	if ( back ) xs_vec_neg(Direction, Direction)
	set_pev(ent, pev_velocity, Direction)
}
	
	
	
stock Simulate_Walking(ent, _forward = true, left = false, right = false)
{
	if ( g_last_jump_anim[ent] >= get_gametime() )
		return
		
	NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_RUN]) );
	
	static Float:Direction[3], Float:Endirection[3]
	static Float:viewAngles[3]
	
	pev(ent, pev_v_angle, viewAngles)
	angle_vector(viewAngles, ANGLEVECTOR_FORWARD, Direction);
	xs_vec_mul_scalar(Direction, 0.8*g_class_data[g_class_id[ent]][DATA_SPEED], Direction)
	if (! _forward ) xs_vec_neg(Direction, Direction)
	
	Endirection[ 0 ] = Direction[ 0 ]
	Endirection[ 1 ] = Direction[ 1 ]
	Endirection[ 2 ] = Direction[ 2 ]
	

	if ( left || right )
	{
		//pev(ent, pev_v_angle, viewAngles)
		angle_vector(viewAngles, ANGLEVECTOR_RIGHT, Direction);
		xs_vec_mul_scalar(Direction, 0.8*g_class_data[g_class_id[ent]][DATA_SPEED], Direction)
		if ( left ) xs_vec_neg(Direction, Direction)
		
		Endirection[ 0 ] += Direction[ 0 ]*0.5
		Endirection[ 1 ] += Direction[ 1 ]*0.5
		Endirection[ 2 ] += Direction[ 2 ]*0.5
	}
	
	if ( fm_distance_to_floor2(ent) > 10.0 )
		Endirection[ 2 ] = 0.0
		
	set_pev(ent, pev_velocity, Endirection)
}



stock create_camera( id ) // credits to Sam Tsuki (mc_oberon)
{	
	new Float: v_angle[ 3 ], Float:T_origin[3], Float: angles[ 3 ];
	entity_get_vector( id, EV_VEC_origin, T_origin );
	entity_get_vector( id, EV_VEC_v_angle, v_angle );
	entity_get_vector( id, EV_VEC_angles, angles );

	new ent = create_entity( "info_target" );

	entity_set_string( ent, EV_SZ_classname, "nrs_cam" );

	entity_set_int( ent, EV_INT_solid, 0 );
	entity_set_int( ent, EV_INT_movetype, MOVETYPE_NOCLIP );
	entity_set_edict( ent, EV_ENT_owner, id );
	entity_set_model( ent, g_camera_model );

	new Float:mins[ 3 ];
	mins[ 0 ] = -1.0;
	mins[ 1 ] = -1.0;
	mins[ 2 ] = -1.0;

	new Float:maxs[ 3 ];
	maxs[ 0 ] = 1.0;
	maxs[ 1 ] = 1.0;
	maxs[ 2 ] = 1.0;

	entity_set_size( ent, mins, maxs );

	entity_set_origin( ent, T_origin );
	entity_set_vector( ent, EV_VEC_v_angle, v_angle );
	entity_set_vector( ent, EV_VEC_angles, angles );

	Util_SetRendering( ent, kRenderFxGlowShell, { 0.0, 0.0, 0.0 }, kRenderTransAlpha, 0.0 );

	camera[ id ] = ent;

	return 1;
}

Util_SetRendering( iEntity, kRenderFx = kRenderFxNone, {Float,_}: fVecColor[ 3 ] = {0.0, 0.0, 0.0 }, kRender = kRenderNormal, Float: flAmount = 0.0 )  // credits to Sam Tsuki (mc_oberon)
{ 
	set_pev( iEntity, pev_renderfx, kRenderFx );
	set_pev( iEntity, pev_rendercolor, fVecColor );
	set_pev( iEntity, pev_rendermode, kRender );
	set_pev( iEntity, pev_renderamt, flAmount );
}
	
	

	

stock Search_Way(ent, Float:target[3])
{
	static Float:npc_origin[3]

	g_way_counter[ent] = 0
	pev(ent, pev_origin, npc_origin)
	//A_star_pathfinder(ent, npc_origin, target)
	
	if ( g_way_counter[ent] < 1 )
		return
	
	g_last_enemy_seek[ent] =get_gametime()+1.5
	g_way_point[ent] = point[ent][0]
	g_way_point_index[ent] = 1
}


stock is_waymove_complete(ent, Float:npc_origin[3], Float:point[][3])
{
	// get current point
	new Float:originCP[3], Float:originCPR[3]
	get_point(ent, originCP, 0, 0)
	get_point(ent, originCPR, 0, 1)
	
	// check dist
	if (vector_distance(npc_origin, originCP)<=50.0 || vector_distance(npc_origin, originCPR)<=50.0 /*|| !get_can_see(npc_origin, originCP)*/) return 1
	
	return 0
}

is_move_complete(Float:ent_origin[3], Float:point_origin[3])
{
	ent_origin[2] = point_origin[2] = 0.0
	// check dist
	
	if (vector_distance(ent_origin, point_origin)<=100.0 /*|| !get_can_see(ent_origin, point_origin)*/) return 1
	
	return 0
}

stock NRS_is_move_complete(ent, Float:point_origin[3])
{
	
	new Float:ent_origin[3], i, gindex = 0
	pev(ent, pev_origin, ent_origin)
		
	if ( vector_distance(point_origin, ent_origin)  <= 1.850*g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX] ) 
	{
		// Delete used coord!
		for ( i = g_way_point_index[ent]; i < g_way_counter[ent]; i++ )
		{
			gindex++
			point[ent][gindex] = point[ent][i+1]
		}
		g_way_counter[ent] = gindex
		
		return 1
	}
	
	return 0
	
	/*new Float:ent_origin[3], new_dist_id = 0, Float:min_dist = 9999.9
	pev(ent, pev_origin, ent_origin)
	
	new Float:dist = vector_distance(ent_origin, point_origin);
	
	#if defined DEBUG
	set_hudmessage(0, 0, 255, -0.15, -1.0, _,0.9,0.9,_,_,-1)
	show_hudmessage(0, "DEBUG : is_move_complete :^n   Distance = %i from %i", floatround(dist), floatround(1.844*g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX]))
	#endif
	
	if ( dist <= 1.850*g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX] ) return 1
	
	min_dist = dist
	
	for ( new i = g_way_point_index[ent]; i < g_way_counter[ent]; i++ )
	{
		dist = vector_distance(point[ent][i], target);
		if ( min_dist>= dist ) 
		{
			//booly = true
			min_dist = dist
			new_dist_id = i;
		}
	}
	if ( new_dist_id ) 
	{
		if ( g_way_point_index[ent] < new_dist_id )
		{
			g_way_point_index[ent] = new_dist_id
			if ( min_dist <= 1.850*g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX] ) return 1
		}
	}
	else
	{
		dist = vector_distance(ent_origin, target);
		if ( min_dist >= dist ) NRS_get_next_point(ent, target)
	}
	
	return 0*/
}


stock get_point(ent, Float:point[3])
{
	point = g_way_point[ent]
	return 1
}


stock find_closes_way(ent, Float:ent_origin[3])
{
	if (!g_waypoints || npc_way_target[ent] > 32 ) return 0;
	
	new Float:originW[3], way = -1, Float:dist, Float:distmin
	ent_origin[2] += g_class_data[g_class_id[ent]][DATA_MIN_MAX_Z_MAX]
	
	for(new w=0; w<=g_done_waypoints[npc_way_target[ent]]; w++)
	{
		originW = g_Ways[npc_way_target[ent]][w]
		dist = vector_distance(ent_origin, originW)
		
		if ((!distmin || dist<=distmin) && get_can_see(ent_origin, originW))
		{
			distmin = dist
			way = w
		}	
	}	
	if ( way > -1 )
		g_way_founded[ent] = true
	
	return way
}



stock get_can_see(Float:ent_origin[3], Float:target_origin[3])
{
	new Float:hit_origin[3]
	trace_line(-1, ent_origin, target_origin, hit_origin)						

	if (!vector_distance(hit_origin, target_origin)) return 1;

	return 0;
}


public bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}




/*stock Check_Ways(Float:this_point[3])
{
	for( i = 0; i < g_waypoints; ++i )
	{		
		this_point[2] = 0.0
		if (vector_distance(this_point, origin2)<=2*npc_size_width)
		{
			// oz
			origin1 = origin
			origin2 = originE
			origin1[0] = origin2[0] = origin1[1] = origin2[1] = 0.0
			if (vector_distance(origin1, origin2)<=npc_size_height) return 0;
		}
	}
}*/


public plugin_natives()
{
	register_library("npc_register_system")
	//register_native("l4d_class_tank_set", "native_infection_tank", 1)
	//register_native("l4d_class_tank_get", "native_is_infection_tank", 1)
	register_native("nrs_user_victim", "native_nrs_user_victim", 1)
	register_native("nrs_user_attacker", "native_nrs_user_attacker", 1)
	
	register_native("register_npc", "native_register_npc", 1)
	register_native("create_npc", "native_create_npc", 1);
	register_native("get_npc_id", "native_get_npc_id", 1)
	register_native("get_npc_classname_id", "native_get_npc_classname_id", 1)
	register_native("set_npc_model", "native_set_npc_model", 1)
	register_native("set_npc_data", "native_set_npc_data", 1)
	register_native("get_npc_data", "native_get_npc_data", 1)
	register_native("get_npc_classum", "native_get_npc_classum", 1)
	register_native("npc_game_started", "native_game_started", 1)
	register_native("set_npc_think", "native_set_npc_think", 1)
	register_native("set_npc_events", "native_set_npc_events", 1)
	register_native("get_npc_events", "native_get_npc_events", 1)
	register_native("set_npc_mage", "native_set_npc_mage", 1)
	register_native("set_npc_boss", "native_set_npc_boss", 1)
	register_native("set_npc_targets", "native_set_npc_targets", 1)
	register_native("set_npc_foes", "native_set_npc_foes", 1)
	register_native("npc_do_damage", "native_npc_do_damage", 1)
	register_native("npc_take_aoe_damage", "native_npc_take_aoe_damage", 1)
	register_native("npc_do_aoe_damage", "native_npc_do_aoe_damage", 1)
	register_native("npc_do_drag", "native_npc_drag", 1)
	register_native("get_npc_target", "native_npc_get_target", 1)
	register_native("npc_do_dragend", "native_npc_dragend", 1)
	register_native("npc_set_animation", "native_npc_set_anim", 1)
	register_native("npc_set_berserker", "native_npc_set_berserker", 1)
	register_native("npc_set_attack_delay", "native_npc_set_attack_delay", 1)
	register_native("npc_reset_animation", "native_reset_anim", 1)
	register_native("npc_set_move", "native_npc_set_move", 1)
	register_native("npc_reset_move", "native_reset_move", 1)
	register_native("is_npc_mode", "native_npc_mode", 1)
	
	register_native("set_npc_victim", "native_set_npc_victim", 1)
	register_native("npc_reset", "native_reset", 1)
	register_native("npc_shoot", "native_npc_shoot", 1)	
	register_native("npc_set_custom_heeting", "native_npc_set_custom_heeting", 1)
	register_native("npc_get_creatednum", "native_npc_get_creatednum", 1)
	register_native("is_nrs_npc", "native_is_nrs_npc", 1)
	register_native("get_npc_boss", "native_get_npc_boss", 1)
	
	
	// Left 4 Dead natives..
	//register_native("l4d_npc_call", "native_npc_call", 1)
	register_native("npc_timecall", "native_npc_timecall", 1)
	// Left 4 Dead natives..
}


public native_set_npc_victim(ent, victim)
	npc_custom_enemy[ent] = victim
public native_get_npc_boss(ent)
	return g_boss[ent] ? 1 : 0
public native_is_nrs_npc(ent)
	return g_valid_npc[ent] ? 1 : 0
public native_npc_mode()
	return b_Mode
public native_npc_get_creatednum()
	return g_Created_Npc;
	
public native_npc_take_aoe_damage(inflictor, Float:Radius, Float:damage)
{
	static  i, Float:creatorOrigin[3], Float:fOrigin[3], Float:fDistance, Float:fTmpDmg;
	pev(inflictor, pev_origin, creatorOrigin)
	
	for ( i=32; i<MAX_NPC; ++i )
	{
		if ( pev_valid(i) )
		{
			if ( g_valid_npc[i] && i!=inflictor )
			{
				pev(i, pev_origin, fOrigin)
				fDistance = vector_distance(creatorOrigin, fOrigin);
				if(fDistance <= Radius)
				{
					if ( fDistance <= Radius*0.5 )
						fTmpDmg = damage
					else
						fTmpDmg = damage - (damage / Radius) *0.5* fDistance;
					
					if ( fTmpDmg > 0.0 )
						fake_take_damage(inflictor, i, fTmpDmg)
				}
			}
		}
	}
	
	return 1
}


public native_npc_do_aoe_damage(inflictor, Float:Radius, Float:damage)
{
	static  i, Float:creatorOrigin[3], Float:fOrigin[3], Float:fDistance, Float:fTmpDmg;
	pev(inflictor, pev_origin, creatorOrigin)
	
	for ( i=1; i<g_maxplayers;i++ )
	{
		if ( is_user_alive(i) )
		{
			pev(i, pev_origin, fOrigin)
			fDistance = vector_distance(creatorOrigin, fOrigin);
			if(fDistance <= Radius)
			{
				if ( fDistance <= Radius*0.5 )
					fTmpDmg = damage
				else
					fTmpDmg = damage - (damage / Radius) *0.5* fDistance;
					
				if ( fTmpDmg > 0.0 )
					fake_take_damage(inflictor, i, fTmpDmg)
			}
			
		}
	}
	
	return 1
}



public native_reset()
{
	ExecuteForward(g_fwd_reset, g_fwd_result) 
	
	
	new i, ent = -1;
	for (i=1; i<33; ++i)
		if ( is_user_connected(i) )
		{
			FindNPC(i, 0)
		}
		
	for ( i=0; i< g_classcount; ++i )
	{
		while ((ent = find_ent_by_class(ent, g_class_name[i])))  
			if(pev_valid(ent)) 
				NRS_Npc_Remove(ent)
	}
	/*while ((ent = find_ent_by_class(ent, "npc_bullet")))
			if(pev_valid(ent)) 
				remove_entity(ent)	
	while ((ent = find_ent_by_class(ent, "npc_weapon")))
			if(pev_valid(ent)) 
				remove_entity(ent)	*/
	
	if ( !g_disabled_Ent_Forwards )
	{
		DisableHamForward( g_entTakeDamage ) 
		DisableHamForward( g_entThink ) 
		DisableHamForward( g_entTouch ) 
		DisableHamForward( g_entTrace ) 
		g_disabled_Ent_Forwards = true;
	}
	
	arrayset(g_npc_ids,-1,g_Created_Npc+1)
	g_Created_Npc = 0;
}

public native_set_npc_targets(ent, Float:value)
	npc_custom_targets[ent] = value
	
public native_set_npc_foes(ent, Float:value)
	npc_custom_foes[ent] = value

public native_nrs_user_victim(id, value)
	npc_user_victim[id] = value
public native_nrs_user_attacker(id, value)
	npc_user_attacker[id] = value
	
	
public native_npc_set_anim(ent, value, Float:lenght)
{
	npc_custom_animation[ent] = value
	fast_anim_fix(ent, lenght)
}

public native_reset_anim(ent)
	npc_custom_animation[ent] = -1

public native_npc_set_move(ent, Float:Speed, Float:fOriginX, Float:fOriginy, Float:fOriginZ)
{
	npc_custom_move[ent][0] = fOriginX
	npc_custom_move[ent][1] = fOriginy
	npc_custom_move[ent][2] = fOriginZ
	
	g_custommoving_speed[ent] = Speed
}

public native_reset_move(ent)
{
	npc_custom_move[ent][0] = npc_custom_move[ent][1] = npc_custom_move[ent][2] = CUSTOM_MOVE_OFF
}
	
	

public native_npc_set_berserker(ent, value)
	g_npc_berserker[ent] = value

public native_npc_set_attack_delay(ent, Float:value)
	g_npc_attack_delay[ent] = value

public plugin_precache()
{
	gibtype = precache_model("models/rockgibs.mdl")
	precache_model(g_camera_model)
	precache_model(BossSpriteHp)
	precache_model(ent_weapon_m4a1)
	
	spr_bomb = precache_model("sprites/ledglow.spr") 
	cache_laserbeam = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	
	new Float:z_version
	
	if(module_exists("cstrike") && is_module_loaded("cstrike") != -1 )
	{
		const fake = (1<<1)
		#if fake & (1<<1)
			log_amx("[NRS] Cstrike support activated!")
			#define g_Cstrike 1
		#endif
	}
	
	if ( LibraryExists("biohazardf", LibType_Library) )
	{
		if(cvar_exists("bh_version"))
		{
			z_version = get_cvar_float("bh_version")
			if ( z_version > 0.0 )
			{
				const fake2 = 1
				log_amx("[NRS] Biohazard support activated!")
				#if fake2 & (1<<1)
					#define g_Bio 1
				#endif
			}
		}
	}
	if(cvar_exists("zp_version") )
	{
		z_version = get_cvar_float("zp_version")
		if ( z_version > 0.0 )
		{
			if (  z_version >= 5.0 && LibraryExists("zp50_core", LibType_Library) )
			{
				const fake3 = 1
				log_amx("[NRS] Zombie Plague %f support activated!", z_version)
				#if fake3 & (1<<1)
					#define	g_Zp5 1
				#endif
			} 
			if ( z_version == 4.3 )
			{
				const fake4 = 1
				log_amx("[NRS] Zombie Plague %f support activated!", z_version)
				#if fake4 & (1<<1)
					#define g_Zp43 1
				#endif
			}
		}
	}
	
	load_spawn_points();
	
	new i, mdl_index
	for(i = 0; i < g_classcount; i++)
	{
		mdl_index = engfunc(EngFunc_PrecacheModel, g_class_pmodel[i])
		set_pdata_int(0, 491, mdl_index, 5) 
	}
	for(i = 0; i < sizeof(bullet_gib); i++)
		engfunc(EngFunc_PrecacheSound, bullet_gib[i])	
		
	cache_blood = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
	cache_bloodspray = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")
	g_sprite = engfunc(EngFunc_PrecacheModel, "sprites/zbeam4.spr");
}



load_spawn_points()
{
	// Check for spawns points of the current map
	new cfgdir[32], mapname[32], filepath[100], linedata[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), SPAWNS_FILE, cfgdir, mapname)
	
	// Load spawns points
	if (file_exists(filepath))
	{
		new file = fopen(filepath,"rt"), row[4][6], boss
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata))
			
			// invalid spawn
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
			// get spawn point data
			parse(linedata,row[0],5,row[1],5,row[2],5,row[3],5)
			
			// origin
			boss = str_to_num(row[0])
			if (boss && g_total_spawns_boss<MAX_SPAWNS)
			{
				g_spawns_boss[g_total_spawns_boss][0] = floatstr(row[1])
				g_spawns_boss[g_total_spawns_boss][1] = floatstr(row[2])
				g_spawns_boss[g_total_spawns_boss][2] = floatstr(row[3])
				g_total_spawns_boss++
			}
			else if (g_total_spawns<MAX_SPAWNS)
			{
				g_spawns[g_total_spawns][0] = floatstr(row[1])
				g_spawns[g_total_spawns][1] = floatstr(row[2])
				g_spawns[g_total_spawns][2] = floatstr(row[3])
				g_total_spawns++
			}
		}
		if (file) fclose(file)
	}
}
stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}



public hook_death()
{
	new killer = read_data(1);
	new victim = read_data(2);
	
	if(!pev_valid(killer) || !pev_valid(victim) )
		return;
	
	if ( is_user_connected ( victim ) )
	{
		new i;
		for ( i = 1; i < MAX_NPC; ++i )
			if ( pev_valid(i) )
				if ( pev(i, pev_owner) == victim )
					fake_take_damage(i, i, 666666.0)
	}
}




public L4D_create_npc_spawnpoint(Float:vf_OriginalOrigin[3], ent)
{
	if ( !ent )
		return 0
	
	new Float:vf_NewOrigin[ 3 ];
	static i_Attempts, i_Distance;
	i_Distance = floatround(g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX]*2.0);
	
	while ( i_Distance < 1000 )
	{
		i_Attempts = 128;
		
		while ( i_Attempts-- )
		{
			vf_NewOrigin[ 0 ] = random_float ( vf_OriginalOrigin[ 0 ] - i_Distance, vf_OriginalOrigin[ 0 ] + i_Distance );
			vf_NewOrigin[ 1 ] = random_float ( vf_OriginalOrigin[ 1 ] - i_Distance, vf_OriginalOrigin[ 1 ] + i_Distance );
			if ( random_num(0,1) && z_okay ) 
				vf_NewOrigin[ 2 ] = random_float ( vf_OriginalOrigin[2 ] - i_Distance, vf_OriginalOrigin[ 2 ] + i_Distance );//vf_NewOrigin[ 2 ] = /*random_float ( vf_OriginalOrigin[ 2 ] - i_Distance,*/ vf_OriginalOrigin[ 2 ] + i_Distance //);
			
			engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize ( ent ), ent, 0 );
			
			// --| Free space found.
			if ( get_tr2 ( 0, TR_InOpen ) && !get_tr2 ( 0, TR_AllSolid ) && !get_tr2 ( 0, TR_StartSolid ) )
			{
				// --| Set the new origin .
				entity_set_origin(ent, vf_NewOrigin)//engfunc ( EngFunc_SetOrigin, ent, vf_NewOrigin );
				return 1;
			}
		}
		
		i_Distance += 32;
	}
	
	// --| Could not be found.
	return 0;
}

stock Float:NRS_point_create(ent, Float:vf_OriginalOrigin[3])
{
	new Float:vf_NewOrigin[ 3 ];
	static i_Attempts, i_Distance;
	i_Distance = 250;
	
	while ( i_Distance < 2000 )
	{
		i_Attempts = 128;
		
		while ( i_Attempts-- )
		{
			vf_NewOrigin[ 0 ] = random_float ( vf_OriginalOrigin[ 0 ] - i_Distance, vf_OriginalOrigin[ 0 ] + i_Distance );
			vf_NewOrigin[ 1 ] = random_float ( vf_OriginalOrigin[ 1 ] - i_Distance, vf_OriginalOrigin[ 1 ] + i_Distance );
			if ( random_num(0,1) )  vf_NewOrigin[ 2 ] = /*random_float ( vf_OriginalOrigin[ 2 ] - i_Distance, */vf_OriginalOrigin[ 2 ] + i_Distance// );
			
			engfunc ( EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize ( ent ), ent, 0 );
			
			// --| Free space found.
			if ( get_tr2 ( 0, TR_InOpen ) && !get_tr2 ( 0, TR_AllSolid ) && !get_tr2 ( 0, TR_StartSolid ) )
			{
				// --| Set the new origin .
				return vf_NewOrigin;
			}
		}
		
		i_Distance += 32;
	}
	
	// --| Could not be found.
	return vf_OriginalOrigin;
}

public NRS_Extra_Power(ent)
{
	if (!g_hamnpc)
	{
		g_entTakeDamage = RegisterHamFromEntity(Ham_TakeDamage, ent, "fw_TakeDamage")
		g_entThink = RegisterHamFromEntity(Ham_Think, ent, "fw_think")
		g_entTouch = RegisterHamFromEntity(Ham_Touch, ent, "fw_touch")
		g_entTrace = RegisterHamFromEntity(Ham_TraceAttack, ent, "fw_tTraceAttack")
		g_hamnpc = 1
	}
	else
	{
		if ( g_disabled_Ent_Forwards )
		{
			EnableHamForward( g_entTakeDamage ) 
			EnableHamForward( g_entThink ) 
			EnableHamForward( g_entTouch ) 
			EnableHamForward( g_entTrace ) 
			g_disabled_Ent_Forwards = false;
		}
	}
}


public get_num_ents()
{
	new i, count;
	for(i=1;i<maxentities;i++)
	{
		if(is_valid_ent(i))
			count++
	}
	return count;
}



public give_weapon(ent)
{
	if ( get_num_ents() > (maxentities - 50) )
		return
		
	new entWeapon = create_entity("info_target")

	entity_set_string(entWeapon, EV_SZ_classname, "npc_weapon")
	
	entity_set_int(entWeapon, EV_INT_movetype, MOVETYPE_FOLLOW)
	entity_set_int(entWeapon, EV_INT_solid, SOLID_NOT)
	entity_set_edict(entWeapon, EV_ENT_aiment, ent)
	
	switch(g_class_data[g_class_id[ent]][DATA_WEAPON_TYPE])
	{
		case WEAPON_M4A1: 
		{
			#if defined g_Cstrike
				entity_set_model(entWeapon, ent_weapon_m4a1)
			#endif
		}
		default:
		{
			#if defined g_Cstrike
				entity_set_model(entWeapon, ent_weapon_m4a1) 
			#endif
		}
	}
	
	g_clip[ent] = floatround(g_class_data[g_class_id[ent]][DATA_WEAPON_CLIP])
	g_npc_weapon[ent] = entWeapon
}


public NRS_create_npc(Float:myOrigin[3],class_id)
{
	if ( g_roundended )
		return -1;
	
	if ( class_id<0 || class_id > g_classcount )
	{
		//log_amx("%s Bad npc id! %i", TITLE, class_id)
		return -1;
	}
	
	g_Created_Npc += 1;
	
	if ( g_Created_Npc >= MAX_NPC )
	{
		g_Created_Npc--
		return -1;
	}
	
	
	if ( get_num_ents() > (maxentities - 50) )
	{
		g_Created_Npc--
		return -1
	}
	
	
	new ent = create_entity("info_target")
	/*if ( ent >= MAX_NPC )
	{
		if ( !pev_valid ( ent ) )
			return -1;
		else
		{
			remove_entity(ent);
			return -1;
		}
	}*/
	
	dllfunc(DLLFunc_Spawn, ent)

	entity_set_string(ent, EV_SZ_classname, g_class_name[class_id])
	
	set_pev(ent, pev_health, g_class_data[class_id][DATA_HEALTH])
	
	entity_set_model(ent, g_class_pmodel[class_id])
	entity_set_int(ent, EV_INT_modelindex, floatround(g_class_data[class_id][DATA_MODEL_INDEX]))	
	
	switch ( g_class_data[class_id][DATA_MATERIAL] )
	{
		case MATERIAL_MISSILE :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_SLIDEBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLYMISSILE)
		}
		case MATERIAL_VECHILE :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_SLIDEBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
		}
		case MATERIAL_BODY :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP)
		}
		case MATERIAL_FVECHILE :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLYMISSILE)
		}
		default :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP)
		}	
	}
	
	
	entity_set_float(ent, EV_FL_animtime, get_gametime())
	entity_set_float(ent, EV_FL_framerate,1.0)
	entity_set_float(ent, EV_FL_gravity, g_class_data[class_id][DATA_GRAVITY])
	entity_set_float(ent, EV_FL_takedamage, 1.0)
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1)
	
	new Float:maxs[3]
	new Float:mins[3]
	
	if ( g_class_data[class_id][DATA_MATERIAL] ==  MATERIAL_MISSILE )
	{
		maxs[0] = maxs[1] = maxs[2] = 5.0
		mins[0] = mins[1] = mins[2] = -5.0
	}
	else
	{	
		maxs[0] = maxs[1] = g_class_data[class_id][DATA_MIN_MAX_XY_MAX]
		maxs[2] = g_class_data[class_id][DATA_MIN_MAX_Z_MAX]
		mins[0] = mins[1] = g_class_data[class_id][DATA_MIN_MAX_XY_MIN]
		mins[2] =g_class_data[class_id][DATA_MIN_MAX_Z_MIN]
	}
	entity_set_size(ent, mins, maxs)
	
	entity_set_byte(ent, EV_BYTE_controller1, 125)
	entity_set_byte(ent, EV_BYTE_controller2, 125)
	entity_set_byte(ent, EV_BYTE_controller3, 125)
	entity_set_byte(ent, EV_BYTE_controller4, 125)	
	set_pev(ent, pev_owner, 0)
	
	native_reset_move(ent)
	
	npc_custom_targets[ent] = TARGET_ALL
	npc_custom_foes[ent] = FOE_ALL
	g_Last_Good_Z[ent] = 0.0
	g_custom_npc[ent] = CUSTOM_OFF
	g_madness[ent] = 0
	g_think[ent] = 0
	g_mage[ent] = false
	g_boss[ent] = false
	npc_victim[ent] = 0
	g_class_id[ent] = class_id
	g_valid_npc[ent] = true;
	g_npc_berserker[ent] = 0;
	g_npc_attack_delay[ent] = 0.0
	
	g_tv_sleep_time[ent] = 0.0
	g_npc_inattack[ent] = false
	g_last_attack_time[ent] = 0.0
	g_last_attack_reloadtime[ent] = 0.0
	
	g_THINKER_DELAY[ent][D_reset_speed_time] = 0
	g_THINKER_DELAY[ent][D_ent] = 0
	g_THINKER_DELAY[ent][D_corpse_time] = 0
	g_THINKER_DELAY[ent][D_damage] = 0
	g_THINKER_DELAY[ent][D_damage_time] = 0
	g_THINKER_DELAY[ent][D_env_damage_time] = 0
	g_THINKER_DELAY[ent][D_speed_time] = 0
	g_THINKER_DELAY[ent][D_victim] = 0
	
	/*if ( g_class_data[class_id][DATA_MATERIAL] )
	{
		myOrigin[0] += 20
		myOrigin[1] += 60
		myOrigin[2] += 140
		entity_set_origin(ent, myOrigin)
	}
	else */
	if ( g_total_spawns < 1 )
	{
		if ( !L4D_create_npc_spawnpoint(myOrigin, ent) )
		{
			g_Created_Npc--
			remove_entity(ent);
			return -1;
		}
	}
	else
	{
		if (!collect_spawn(ent, myOrigin))
		{
			g_Created_Npc--
			remove_entity(ent);
			return -1;
		}
	}
	
	
	// Global Task Remover
	g_npc_ids[g_Created_Npc == 1 ? 0 : g_Created_Npc-1] = ent;
	// Global Task Remover
	
	
	drop_to_floor(ent)
	
	if (!g_hamnpc)
	{
		g_entTakeDamage = RegisterHamFromEntity(Ham_TakeDamage, ent, "fw_TakeDamage")
		g_entThink = RegisterHamFromEntity(Ham_Think, ent, "fw_think")
		g_entTouch = RegisterHamFromEntity(Ham_Touch, ent, "fw_touch")
		g_entTrace = RegisterHamFromEntity(Ham_TraceAttack, ent, "fw_tTraceAttack")
		g_hamnpc = 1
	}
	else
	{
		if ( g_disabled_Ent_Forwards )
		{
			EnableHamForward( g_entTakeDamage ) 
			EnableHamForward( g_entThink ) 
			EnableHamForward( g_entTouch ) 
			EnableHamForward( g_entTrace ) 
			g_disabled_Ent_Forwards = false;
		}
	}
	
	g_ent_events[ent] = g_class_data[g_class_id[ent]][DATA_EVENT];
	
	if ( g_class_data[class_id][DATA_WEAPON_TYPE] > WEAPON_KNIFE )
	{
		give_weapon(ent)
	}
	
	
	ExecuteForward(g_fwd_initiation, g_fwd_result, ent)
	last_npc_created = ent
	return ent;
}


/*new Float:npc_size_width = 16.0,
Float:npc_size_height = 75.0*/
stock collect_spawn(ent, Float:fOrigin[3])
{
	new bool:is_boss = false, spawns, Float:receivedDist, myid, Float:origin[3], Float:tempSmallestDist = 99999.0, smallestDist_ID = 0

	if ( g_boss[ent] && g_total_spawns_boss)
	{
		spawns = g_total_spawns_boss
		is_boss = true
		myid = random(g_total_spawns_boss)
		origin = g_spawns_boss[myid]
	}
	else
	{
		spawns = g_total_spawns_boss
		myid = random(g_total_spawns)
		origin = g_spawns[myid]
	}
		
	for (new i = 0; i < spawns; i++ )
	{
		if ( is_boss )
		{
			myid = random(g_total_spawns_boss)
			origin = g_spawns_boss[myid]
		}else
		{
			myid = random(g_total_spawns)
			origin = g_spawns[myid]
		}
		if ( check_spawn(origin) )
		{
			receivedDist = vector_distance(fOrigin, origin)
			if ( receivedDist <= tempSmallestDist )
			{
				smallestDist_ID = myid;
				tempSmallestDist = receivedDist
			}
		}
	}
	
	
	if ( !smallestDist_ID )
	if (!L4D_create_npc_spawnpoint(origin, ent))
	{
		smallestDist_ID = 0
	}
	
	
	
	
	/*new szClass[10], szTarget[7], */
	new Float:VicOrigin[3]
	for(new i = 0; i <= maxentities; i++) 
	{ 
		if(!pev_valid(i) || g_valid_npc[i]) 
			continue 

		
		if ( !check_hitent(i) )
			continue
		
		
		if(entity_get_int(i, EV_INT_solid) == SOLID_BSP)
			get_brush_entity_origin(i, VicOrigin);
		else
			entity_get_vector(i,EV_VEC_origin,VicOrigin);
		if (vector_distance(VicOrigin, origin) < 100.0 )
		{
			gib_death(VicOrigin)
			remove_entity(i)
		}
	}
    
    
	if ( smallestDist_ID )
	{
		entity_set_origin(ent, g_boss[ent] ? g_spawns_boss[smallestDist_ID] : g_spawns[smallestDist_ID])
		return 1
	}
	
	return 0;
}
stock check_spawn(Float:origin[3])
{
	new Float:npc_size_width
	new Float:npc_size_height
	
	new Float:originE[3], Float:origin1[3], Float:origin2[3]
	new i;
	/*for( i = 0; i < g_classcount; ++i )
	{
		while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", g_class_name[i])) != 0)
		{	
			pev(ent, pev_origin, originE)
			if ( g_class_id[ent] )
			{
				npc_size_width = g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX]
				npc_size_height =  g_class_data[g_class_id[ent]][DATA_MIN_MAX_Z_MAX]
			}
			else
			{
				npc_size_width = 16.0
				npc_size_height =  75.0
			}
			
			// xoy
			origin1 = origin
			origin2 = originE
			origin1[2] = origin2[2] = 0.0
			if (vector_distance(origin1, origin2)<= npc_size_width)
			{
				// oz
				origin1 = origin
				origin2 = originE
				origin1[0] = origin2[0] = origin1[1] = origin2[1] = 0.0
				if (vector_distance(origin1, origin2)<=npc_size_height) return 0;
			}
		}
	}*/
	if ( !g_Created_Npc )
	{
		return 1;
	}
		
	new ent;
	
	for ( i = 0; i < g_Created_Npc; i++ )
	{
		ent = g_npc_ids[i]
		
		if ( !pev_valid(ent) || !g_valid_npc[ent] )
		{
			continue
		}
		
		pev(ent, pev_origin, originE)
		if ( g_class_id[ent] )
		{
			npc_size_width = g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX]
			npc_size_height =  g_class_data[g_class_id[ent]][DATA_MIN_MAX_Z_MAX]
		}
		else
		{
			npc_size_width = 26.0
			npc_size_height =  75.0
		}
			
		// xoy
		origin1 = origin
		origin2 = originE
		origin1[2] = origin2[2] = 0.0
		if (vector_distance(origin1, origin2)<= npc_size_width)
		{
			// oz
			origin1 = origin
			origin2 = originE
			origin1[0] = origin2[0] = origin1[1] = origin2[1] = 0.0
			if (vector_distance(origin1, origin2)<=npc_size_height) return 0;
		}
	}
			
	return 1;
}



public fw_tTraceAttack(iEnt, attacker, Float: damage, Float: direction[3], trace, damageBits) 
{ 
	if(!is_valid_ent(iEnt)) 
		return; 
	
	if ( !g_valid_npc[iEnt] )
		return
	
	if ( !is_user_alive(attacker) )
		return
	
	if(g_think[iEnt] == THINK_DEATH )
		return
	
	new Float: end[3]
	get_tr2(trace, TR_vecEndPos, end); 
	create_blood(iEnt, end)
	
	
	if ( g_class_data[g_class_id[iEnt]][DATA_KNOCKBACK] > 0.0 )
	{
		// Get victim's velocity
		static Float:velocity[3]
		pev(iEnt, pev_velocity, velocity)
		
		velocity[2] = 0.0
		if ( !g_npc_inattack[iEnt] )
		{
			// Use weapon power on knockback calculation
			xs_vec_mul_scalar(direction, damage*g_class_data[g_class_id[iEnt]][DATA_KNOCKBACK], direction)
			xs_vec_add(velocity, direction, direction)
			
			// Set the knockback'd victim's velocity
			set_pev(iEnt, pev_velocity, direction)	
		}
	}
}


stock create_blood(ent, const Float:origin[3])
{
	static COLOR_INDEX;
	COLOR_INDEX = floatround(g_class_data[g_class_id[ent]][DATA_BLOOD_COLOR]);
	
	if ( is_user_alive(ent) )
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE) 
		engfunc(EngFunc_WriteCoord, origin[0]) 
		engfunc(EngFunc_WriteCoord, origin[1]) 
		engfunc(EngFunc_WriteCoord, origin[2]) 
		write_short(cache_bloodspray) 
		write_short(cache_blood) 
		write_byte(COLOR_INDEX) // color index DATA_BLOOD_COLOR
		write_byte(3) // size 
		message_end() 
	}
	else
	switch ( g_class_data[g_class_id[ent]][DATA_MATERIAL] )
	{
		case MATERIAL_BODY :
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte(TE_BLOODSPRITE) 
			engfunc(EngFunc_WriteCoord, origin[0]) 
			engfunc(EngFunc_WriteCoord, origin[1]) 
			engfunc(EngFunc_WriteCoord, origin[2]) 
			write_short(cache_bloodspray) 
			write_short(cache_blood) 
			write_byte(COLOR_INDEX) // color index 
			write_byte(20) // size 
			message_end() 
		}
		default :
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte(TE_SPARKS) 
			engfunc(EngFunc_WriteCoord, origin[0]) 
			engfunc(EngFunc_WriteCoord, origin[1]) 
			engfunc(EngFunc_WriteCoord, origin[2]) 
			message_end() 
		}	
	}
}


public traceline(Float:v1[3], Float:v2[3], noMonsters, pentToSkip)
{
	new entity1 = pentToSkip;
	new entity2 = get_tr(TR_pHit); // victim
	
	if(!is_valid_ent(entity2)) 
		return;
	
	if(is_user_alive(entity1))
	{
		new hitbox = get_tr(TR_iHitgroup)
		g_Entity_HIT_PLACE[entity2][entity1] = hitbox;	
		if ( hitbox == 8 )
			set_tr( TR_iHitgroup, random_num(1,5) );
		
		//static phit, hitgroup, Float:dist
		//dist = get_user_aiming(entity1, phit, hitgroup)
		
		//if ( g_flashlight[entity1] )
		//	flash_player(entity1, phit, dist)
		
		//#if defined DEBUG
		if( g_summoned_npc[entity2] && npc_hudinfo_delay[entity1] < get_gametime() )
		{
			if ( get_user_team(entity1) != get_user_team(pev(entity2, pev_owner)))
				set_hudmessage(255, 0, 0, 0.56, 0.69, 0, 0.5+0.1, 0.5, 0.3, 1.0, -1)
			else
				set_hudmessage(0, 255, 0, 0.56, 0.69, 0, 0.5+0.1, 0.5, 0.3, 1.0, -1)
			ShowSyncHudMsg(entity1, g_SyncHUD[0], "%L", LANG_PLAYER, "NRS_NPC_INFO_SUMMONED", pev(entity2, pev_health));
			npc_hudinfo_delay[entity1] = get_gametime()+0.5;
		}
		else if ( g_boss[entity2] && npc_hudinfo_delay[entity1] < get_gametime())
		{
			set_hudmessage(0, 0, 255, 0.56, 0.69, 0, 0.5+0.1, 0.5, 0.3, 1.0, -1)
			ShowSyncHudMsg(entity1, g_SyncHUD[0], "%L", LANG_PLAYER, "NRS_NPC_INFO_SUMMONED", pev(entity2, pev_health));
			npc_hudinfo_delay[entity1] = get_gametime()+0.5;
		}
		//#endif
	}
	
	return;
}


public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{	
	if (victim == attacker)
		return HAM_IGNORED
	
	if (!pev_valid(victim) )
		return HAM_IGNORED
		
	if (!pev(victim, pev_health) )
		return HAM_SUPERCEDE
		
	if ( !pev_valid(attacker) )
		return HAM_IGNORED
	
	if (is_user_connected(victim) && is_user_connected(attacker))
		return HAM_SUPERCEDE
	
	if (!g_valid_npc[victim] )
	{
		new classname[32]
		entity_get_string(victim, EV_SZ_classname, classname, 31)
		if(equal(classname, "npc_bullet"))
		{}
		else
			return HAM_IGNORED
	}
	
	
		
	new bool:alive_attacker = true
	
	if ( !is_user_alive(attacker) )
		alive_attacker = false
	
	if ( alive_attacker && !npc_user_attacker[attacker] )
		return HAM_SUPERCEDE
		
		
	// fix hit body damage
	if (damage_type & DMG_BULLET)
	{
		emit_sound(victim, CHAN_AUTO, bullet_gib[random_num(0, charsmax(bullet_gib))], 0.8, ATTN_NORM, 0, PITCH_NORM)
	}
	else if ( damage_type & DMG_SLASH /*|| damage_type & (1 << 24)*/ )
	{}
	else
		return HAM_SUPERCEDE
	
	if( g_summoned_npc[victim] )
		if ( get_user_team(attacker) == get_user_team(pev(victim, pev_owner)) )
			return HAM_SUPERCEDE
		
	if ( npc_custom_foes[victim] > FOE_ALL )
	{
		#if defined g_Bio
			if ( npc_custom_foes[victim] == FOE_HUMAN && is_user_zombie( attacker ) )
				return HAM_SUPERCEDE
			else if ( npc_custom_foes[victim] == FOE_ZOMBIE && !is_user_zombie( attacker ) )
				return HAM_SUPERCEDE
		#endif
		#if defined g_Zp43
			if ( npc_custom_foes[victim] == FOE_HUMAN && zp_get_user_zombie( attacker ) )
				return HAM_SUPERCEDE
			if ( npc_custom_foes[victim] == FOE_ZOMBIE && !zp_get_user_zombie( attacker ) )
				return HAM_SUPERCEDE
		#endif
		#if defined g_Zp5
			if ( npc_custom_foes[victim] == FOE_HUMAN && zp_core_is_zombie( attacker ) )
				return HAM_SUPERCEDE
			if ( npc_custom_foes[victim] == FOE_ZOMBIE && !zp_core_is_zombie( attacker ) )
				return HAM_SUPERCEDE
		#endif
	}
		
	
	if (g_think[victim] == THINK_DEATH ) return HAM_SUPERCEDE
		
	new hitpart
	if ( alive_attacker )
		hitpart = g_Entity_HIT_PLACE[victim][attacker];
	else
		hitpart = HIT_GENERIC
	
	if ( alive_attacker )
	{
		// get attacker aim
		new aimOrigin[3], Float:origin[3];
		get_user_origin(attacker, aimOrigin, 3)
		pev(victim, pev_origin, origin);
		if ( hitpart == HIT_HEAD && g_class_data[g_class_id[victim]][DATA_MATERIAL] == MATERIAL_BODY)
		{
			new iOrigin[3];
			FVecIVec ( origin, iOrigin );
			NPC_HEADSHOT_BLOOD(victim, iOrigin);
		}

			
		damage = float(get_damage_body(hitpart, damage))
		
			
		// set new damage
		SetHamParamFloat(4, damage)
		ExecuteForward(g_fwd_npc_damage, g_fwd_result, victim, attacker, damage)
	}
		
	
	//FakeBleed(victim)
	
	
	// NPC die
	if (0.0 < pev(victim, pev_health) <= damage)
	{
		/*if ( alive_attacker ) cs_set_user_money(attacker, cs_get_user_money(attacker)+300);
		if ((damage_type & DMG_BULLET) && alive_attacker) 
		{
			new i_ammo, i_clip
			new idgun = get_user_weapon(attacker, i_clip, i_ammo)
			new x_ammo = AMMO_TO_GIVE;
			if ( pev_valid(idgun) && idgun != 29)
				cs_set_user_bpammo(attacker, idgun, i_ammo+x_ammo)
		}*/
		
		NRS_killed_Npc(victim, floatround(damage), hitpart)
		//if ( g_boss[victim] ) native_set_npc_boss(victim, false)
		
		/*for (new j = 0; j<MAX_NPC; j++)
			if ( g_health_bar[j] == victim )
			{
				g_health_bar[j] = 0
				g_health_bar_z[j] = 0.0
				remove_entity(j)
			}*/
		
		/*if ( alive_attacker )
		{
			new i 
			for (i=1; i<33; ++i)
			if ( is_user_connected(i) )
			{
				if ( g_tv[i] == victim )
				{
					g_tv[i] = 0
					attach_view(i,i)
					set_pev(i, pev_origin, g_SavedOrigin[i])
					if(pev_valid(camera[i])) 
					{
						remove_entity(camera[i])
						camera[i] = 0
					}
				}
			}
		}*/
		npc_way_target[victim] = 0
		
		ExecuteForward(g_fwd_death, g_fwd_result, victim, attacker)
		
		return HAM_SUPERCEDE
	}
	else
	{
		/*g_last_enemy_seek[victim] = 0.0;
		new parm[3];
		parm[0] = victim;
		parm[1] = attacker;
		//NPC_return_target(parm);*/
	}
	
	return HAM_IGNORED
}


NRS_killed_Npc(ent, damage, hitpart)
{
	set_pev(ent, pev_health, 0.0)
	
	static Float:reset[3]
	entity_set_size(ent, reset, reset)
	entity_set_vector(ent, EV_VEC_velocity, reset)
	
	if ( g_npc_weapon[ent] && pev_valid(g_npc_weapon[ent]) )
		remove_entity(g_npc_weapon[ent])
			
	NRS_PlayDeath(ent, damage, hitpart );
	if ( g_boss[ent] )
	{
		new vOrigin[3], Float:fOrigin[3]
		pev(ent, pev_origin, fOrigin)
		FVecIVec(fOrigin,vOrigin)
		Super_Killed(vOrigin)
	}
	
		
	g_think[ent] = THINK_DEATH
	
	new Float:ftime;
	if ( g_boss[ent] )
		ftime = 20.0
	else
		ftime = 5.0
	g_THINKER_DELAY[ent][D_corpse_time] = floatround(ftime+get_gametime())
	//set_task(ftime+1.0, "NRS_remove_it", ent+515)
	
}


Super_Killed(vec1[3])
{
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
    write_byte(TE_LAVASPLASH); 
    write_coord(vec1[0]); 
    write_coord(vec1[1]); 
    write_coord(vec1[2]); 
    message_end(); 
} 


NRS_PlayDeath(ent,damage, hitpart )
{
	new class_id = g_class_id[ent];
	if  ( !class_id  )
	{
		NRS_set_animation( ent, 110 )
		return
	}
		
	if ( hitpart == HIT_HEAD )
		NRS_set_animation( ent, floatround(g_class_data[class_id][DATA_ANI_DEATH_HEADSHOT]) )
	else
	if ( damage > 100 )
	{
		if ( hitpart == HIT_HEAD )
			NRS_set_animation( ent, floatround(g_class_data[class_id][DATA_ANI_DEATH_HEADSHOT]) )
		else
			NRS_set_animation( ent, floatround(g_class_data[class_id][DATA_ANI_DEATH_NORMAL_BACK]) )
	}
	else
	{
		if ( hitpart == HIT_HEAD )
			NRS_set_animation( ent, floatround(g_class_data[class_id][DATA_ANI_DEATH_HEADSHOT]) )
		else
		{
			new My_anim = random_num(1,3)
			switch ( My_anim)
			{
				case 1 : NRS_set_animation( ent, floatround(g_class_data[class_id][DATA_ANI_DEATH_NORMAL_SIMPLE]) );
				case 2 : NRS_set_animation( ent, floatround(g_class_data[class_id][DATA_ANI_DEATH_NORMAL_SPECIAL]) );
				case 3 : NRS_set_animation( ent, floatround(g_class_data[class_id][DATA_ANI_DEATH_NORMAL_FORWARD]) );
			}
		}
	}
}


stock get_damage_body(body, Float:damage)
{
	switch (body)
	{
		case HIT_HEAD: damage *= 4.0
		case HIT_STOMACH: damage *= 1.25
		case HIT_LEFTLEG: damage *= 0.75
		case HIT_RIGHTLEG: damage *= 0.75
		case HIT_LEFTARM: damage *= 0.75
		case HIT_RIGHTARM: damage *= 0.75
		default: damage *= 1.0
	}
	
	return floatround(damage);
}


public NPC_HEADSHOT_BLOOD (ent,  iOrigin[3] )
{
	static COLOR_INDEX;
	COLOR_INDEX = floatround(g_class_data[g_class_id[ent]][DATA_BLOOD_COLOR]);
	
	switch ( g_class_data[g_class_id[ent]][DATA_MATERIAL] )
	{
		case MATERIAL_BODY :
		{
			message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin );
			write_byte( TE_BLOODSTREAM );
			write_coord( iOrigin[ 0 ] );
			write_coord( iOrigin[ 1 ] );
			write_coord( iOrigin[ 2 ] + 30 );
			write_coord( random_num( -20, 20 ) );
			write_coord( random_num( -20, 20 ) );
			write_coord( random_num( 50, 300 ) );
			write_byte( COLOR_INDEX );
			write_byte( random_num( 100, 200 ) );
			message_end();
			
			message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin );
			write_byte( TE_BLOODSTREAM );
			write_coord( iOrigin[ 0 ] );
			write_coord( iOrigin[ 1 ] );
			write_coord( iOrigin[ 2 ] + 10 );
			write_coord( random_num( -360, 360 ) );
			write_coord( random_num( -360, 360 ) );
			write_coord( -10 );
			write_byte( COLOR_INDEX );
			write_byte( random_num( 50, 100 ) );
			message_end();
		}
		default :
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
			write_byte(TE_SPARKS) 
			write_coord( iOrigin[ 0 ] );
			write_coord( iOrigin[ 1 ] );
			write_coord( iOrigin[ 2 ] );
			/*engfunc(EngFunc_WriteCoord, iOrigin[0]) 
			engfunc(EngFunc_WriteCoord, iOrigin[1]) 
			engfunc(EngFunc_WriteCoord, iOrigin[2]) */
			message_end() 
		}	
	}
}

public native_npc_shoot(iEnt, Float:fOrigin[3])
	npc_bullet_attack(iEnt, fOrigin)


public npc_bullet_attack(iEnt, Float:fOrigin[3])
{
	new ent = NRS_create_npc(fOrigin, native_get_npc_classname_id("npc_bullet"))
	if(pev_valid(ent))
	{
		new bool:got = false, Float:targetForigin[3]	
		//entity_set_size(ent, Float:{-1.0,-1.0,-1.0}, Float:{1.0,1.0,1.0})		
		set_pev(ent, pev_origin, fOrigin)		
		//entity_set_int(ent, EV_INT_solid, 1)
		//entity_set_int(ent, EV_INT_movetype, 5)
		g_owner[ent] = iEnt
		
		new i
		for ( i = 1; i <33; ++i )
		{
			if (is_user_alive(i) )
				if ( fm_is_ent_visible(iEnt, i) )
				{
					pev(i, pev_origin, targetForigin)
					got = true
				}
		}
		
		if ( !got )
			remove_entity(ent)
		else
			g_reach_point[ent] = targetForigin
	}
}


public NRS_remove_it(ent)
{
	if ( ent > MAX_NPC )
		ent -= 515
		
	if ( !pev_valid(ent) )
		return
	NRS_Npc_Remove(ent)
}

public fw_think(ent)
{
	if ( !pev_valid(ent) )
		return HAM_IGNORED;

	
	if ( !g_valid_npc[ent] && g_custom_npc[ent] <= CUSTOM_OFF )
		return HAM_IGNORED;
		
	//if ( pev(ent, pev_deadflag) == DEAD_DYING )
	//	return HAM_IGNORED
		
	if(g_think[ent] == THINK_DEATH )
	{
		g_think[ent] = THINK_REMOVE
		return HAM_IGNORED
	}
	if (g_think[ent] == THINK_REMOVE)
	{
		NRS_Npc_Remove(ent)
		return HAM_IGNORED
	}
	
	if ( get_gametime() >= g_fRemovecheck_timer )
	{
		new i;
		for ( i = 0; i < g_Remover_Eng; ++i )
		{
			if ( g_To_Remove[g_Remover_Eng][0] == ent )
				if ( time() >= g_To_Remove[g_Remover_Eng][1])
				{
					g_To_Remove[g_Remover_Eng][0] = -1;
					g_To_Remove[g_Remover_Eng][1] = 0;
					//NRS_killed_Npc(ent, pev(ent, pev_health), HIT_GENERIC)
					fake_take_damage(ent, ent, 666666.0)
					g_Remover_Eng--;
				}
		}
		g_fRemovecheck_timer = get_gametime() + 1.5;
	}
	
	if ( g_custom_npc[ent] == CUSTOM_HOTSEEK )
	{
		NRS_FollowHot(ent)
		return HAM_HANDLED
	}
	
	new class_id = g_class_id[ent];
	
	if ( g_tv_sleep_time[ent] >= get_gametime() )
	{
		if ( g_last_attack_reloadtime[ent] < get_gametime() )
		{
			if ( g_npc_inattack[ent] )
				g_npc_inattack[ent] = false;
				
			if ( g_clip[ent] < 1 && g_ent_events[ent] == EVENT_SHOOTER )
			{
			}
			else
			if  (g_npc_berserker[ent])
				NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_MADANI_IDLE]) );
			else
			NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_ANI_MADNESS]) );
		}
		
		entity_set_float(ent, EV_FL_nextthink, g_tv_sleep_time[ent] - get_gametime() )
		return PLUGIN_CONTINUE
	}

	if ( g_npc_inattack[ent] )
		g_npc_inattack[ent] = false;
				
	if ( g_tv_custom[ent] != 3 )
	{
		switch( g_ent_events[ent] )
		{
			case EVENT_SLEEP:
			{
				if  (g_npc_berserker[ent])
					NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_MADANI_IDLE]) );
				else
					NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_ANI_IDLE]) );
			}
			case EVENT_ZOMBIE_VOID:
			{
				//Search_Way(ent)
			}
			case EVENT_WAKEUP:
			{
				NRS_WakeUp(ent)
			}
			case EVENT_AGRESSION:
			{
				NRS_Agression_Loop(ent)
			}
			case EVENT_SUPPORT:
			{
				NRS_FollowCreator(ent)
			}
			case EVENT_MISSILE:
			{
				NRS_FollowHot(ent)
			}
			case EVENT_POINT:
			{
				NRS_Reach_Point(ent)
			}
			case EVENT_CUSTOM:
			{
				if ( npc_custom_animation[ent] > -1 )
					NRS_set_animation(ent,  npc_custom_animation[ent] );
				if ( npc_custom_move[ent][0] != CUSTOM_MOVE_OFF && npc_custom_move[ent][1] != CUSTOM_MOVE_OFF && npc_custom_move[ent][2] != CUSTOM_MOVE_OFF )
				{
					static Float:Origin[3]
					pev(ent, pev_origin, Origin)
					ent_custom_move_to(ent, g_custommoving_speed[ent], Origin, npc_custom_move[ent])//npc_move(ent, Origin, npc_custom_move[ent])
				}
			}
			case EVENT_SHOOTER:
			{
				NRS_Agression_Loop(ent, 1)
			}
			default:
			{
				if ( g_mage[ent] )
					NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_ANI_CASTING]) );
				else
					NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_ANI_IDLE]) );
			}
		}
	}
	
	entity_set_float(ent, EV_FL_nextthink, halflife_time() + 0.1)
	
	return HAM_HANDLED
}


stock NRS_Agression_Loop ( ent , distanced = 0 )
{
	static victim
	victim = FindVictim(ent)
	
	static Float:VicOrigin[3]
	pev(victim, pev_origin, VicOrigin)
	
	static Float:Origin[3], Float:distance		
	pev(ent, pev_origin, Origin)
	
	if ( distanced )
	{
		if(victim != 0 && get_can_see(Origin, VicOrigin))
		{
			if ( g_class_data[g_class_id[ent]][DATA_WEAPON_TYPE] > WEAPON_KNIFE )
			{
				NRS_Shoot( ent, victim, Origin, VicOrigin )
				ent_aim_at(ent, Origin, VicOrigin)
				NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_IDLE_SHOOT]), 1 );
				return
			}
		}
		else
			if ( !g_tv_custom[ent] )
				{}
		return
	}
	
	distance = vector_distance(Origin, VicOrigin)		
				
	if(is_user_alive(victim))
	{
		if ( Check_Forward_Attack(ent, Origin, VicOrigin, distance) )
			Search_Way(ent, VicOrigin)
		else
		if ( g_last_enemy_seek[ent] < get_gametime() ) 
		{
			Search_Way(ent, VicOrigin)
		}
		
		if(distance <= g_class_data[g_class_id[ent]][DATA_ATTACK_DISTANCE])
		{
			witch_attack(ent, victim)
			
			new Float:ftime
			if  (g_npc_berserker[ent])
			{
				ftime = g_class_data[g_class_id[ent]][DATA_MADANI_ATTACK_TIME];
			}
			else
				ftime = g_class_data[g_class_id[ent]][DATA_ATTACK_RELOADING];
			g_last_attack_reloadtime[ent] =get_gametime()+ ftime
			if  (g_npc_berserker[ent])
			{
				ftime = g_class_data[g_class_id[ent]][DATA_MADANI_ATTACK_WAIT];
			}
			else
				ftime = g_class_data[g_class_id[ent]][DATA_ATTACK_WAITTIME];
			g_tv_sleep_time[ent] = get_gametime() + ftime
			entity_set_float( ent, EV_FL_nextthink, g_last_attack_reloadtime[ent] )
		}
		else 
		{
			entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.15)
			if ( g_touch_cd[ent] < get_gametime() && g_think_jump_cd[ent] < get_gametime()  )
			{
				new Float:OriginAngle[3], Float:hitOrigin[3], Float:origin2[3], Float:got_distance
				new Float:NEED_DIST = vector_distance(Origin, point[ent][g_way_point_index[ent]]);
				pev(ent, pev_angles, OriginAngle)
				origin2[0] = Origin[0] + (floatcos(OriginAngle[1] + MY_FOV, degrees) * NEED_DIST); 
				origin2[1] = Origin[1] + (floatsin(OriginAngle[1] + MY_FOV, degrees) * NEED_DIST); 
				origin2[2] = Origin[2]
				trace_line(ent, Origin, origin2, hitOrigin) 
				got_distance = vector_distance(Origin, hitOrigin)
				
				
				if ( got_distance < NEED_DIST/*MY_FOV_POWER*/)
				{
					g_last_jump_anim[ent] = get_gametime() + 0.55
				}
				
				g_think_jump_cd[ent] = get_gametime() + 2.0
			}
		}
		npc_move(ent, Origin, VicOrigin)
	} 
	else
	{	
		NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_IDLE]))
	}
}


Check_Forward_Attack(ent, Float:entOrigin[3], Float:victimOrigin[3], Float:distance)
{
	if(get_can_see(entOrigin, victimOrigin) && distance <= 1.5*g_class_data[g_class_id[ent]][DATA_ATTACK_DISTANCE])
		return true
	return false
}


stock NRS_Reach_Point(ent)
{
	new Float:npc_origin[3]
	pev(ent, pev_origin, npc_origin)
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.75)
	npc_move(ent, npc_origin, g_reach_point[ent])
}


stock NRS_FollowHot(ent)
{
	static victim
	new owner
	victim = FindVictim(ent)
				
	static Float:Origin[3], Float:VicOrigin[3], Float:distance, tpos[3], Float:Fpos[3]
				
	pev(ent, pev_origin, Origin)
	pev(victim, pev_origin, VicOrigin)
				
	distance = vector_distance(Origin, VicOrigin)		
				
	if(is_user_alive(victim))
	{
		if(distance <= 70.0)
		{
			new owner
			if ( g_owner[ent] < 1 )
				owner = pev(ent, pev_owner)
			else
				owner = g_owner[ent];
			ExecuteForward(g_fwd_missile_catched, g_fwd_result, ent, owner, victim)
			//entity_set_float(ent, EV_FL_nextthink, get_gametime() + 55.0)
		} 
		//else 
		//{
		//}
		
		npc_move(ent, Origin, VicOrigin)
	}
	else
	{
		owner = pev(ent,pev_owner)
		if ( owner )
		{
			get_user_origin ( owner, tpos, 3)
			IVecFVec(tpos, Fpos)
			npc_move(ent, Origin, Fpos)
		}
		//velocity_by_aim(owner, 2500, velocity);
		//set_pev(ent, pev_velocity, velocity);
	}
	
	entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.15)
}


stock NRS_FollowCreator ( ent )
{
	static owner, bool:moving = true;
	owner = pev(ent, pev_owner)
	
	if ( !owner )
	{
		g_ent_events[ent] = EVENT_AGRESSION
		return;
	}
				
	static Float:Origin[3], Float:VicOrigin[3], Float:distance
				
	pev(ent, pev_origin, Origin)
	pev(owner, pev_origin, VicOrigin)
				
	distance = vector_distance(Origin, VicOrigin)		
				
	if(is_user_alive(owner))
	{
		moving = true;
		
		if(distance <= 550.0)
		{
			if ( g_last_enemy_seek[ent] < get_gametime() ) 
			{
				// sounds..
				g_last_enemy_seek[ent] =get_gametime()+random_float(1.5, 6.0);
			}
		}
		if(distance <= 150.0)
		{
			if ( g_last_enemy_seek[ent] > get_gametime() ) 
				ExecuteForward(g_fwd_casting_range, g_fwd_result, ent, owner, distance)
			moving = false;
		} 
		else 
		{
			if ( g_last_enemy_seek[ent] > get_gametime() ) 
				ExecuteForward(g_fwd_casting_outrange, g_fwd_result, ent)
			entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.15)
		}
		
		//g_last_enemy_seek[ent] =get_gametime()+random_float(1.5, 6.0);
		
		if ( moving ) 
			npc_move(ent, Origin, VicOrigin) 
		else 
			NRS_set_animation( ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_IDLE]) );
	} 
	else
	{	
		//Search_Way(ent)
	}
}


public witch_attack_environmental(ent, wall)
{
	new class_id = g_class_id[ent];
	
	if ( g_class_data[class_id][DATA_MATERIAL] == MATERIAL_MISSILE )
		return
		
	if ( g_last_attack_time[ent] <= get_gametime() )
	{
		ExecuteForward(g_fwd_npc_damage_start, g_fwd_result, ent);
		if (g_fwd_result >= PLUGIN_HANDLED)
		{
			return;
		}
		
		g_npc_inattack[ent] = true;
		if  (g_npc_berserker[ent])
			NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_MADANI_ATTACK]) );
		else
			NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_ANI_ATTACK]) );
		
		new damagee = g_npc_berserker[ent] ? 2 : 1;
		
		new parm[3];
		parm[0] = ent;
		parm[1] = wall
		parm[2] = damagee
		
		new Float:time4ko 
		if  (!g_npc_attack_delay[ent])
		{
			if  (g_npc_berserker[ent])
				time4ko = g_class_data[class_id][DATA_MADANI_ATTACK_WAIT]
			else
				time4ko = g_class_data[class_id][DATA_ATTACK_WAITTIME]
		}
		else
			time4ko = g_npc_attack_delay[ent];
		
		//set_task( time4ko*0.3, "NRS_delayed_env_damage", TASK_DAMAGE + wall, parm, 3 );
		g_THINKER_DELAY[ent][D_ent] = ent;
		g_THINKER_DELAY[ent][D_victim] = wall;
		g_THINKER_DELAY[ent][D_damage] = damagee;
		g_THINKER_DELAY[ent][D_env_damage_time] = floatround(time4ko*0.3+get_gametime())
		
		
		time4ko = g_class_data[class_id][DATA_MADANI_ATTACK_TIME]
		g_last_attack_time[ent] =get_gametime()+time4ko
		time4ko = g_class_data[class_id][DATA_ATTACK_RELOADING]
		g_last_attack_reloadtime[ent] =get_gametime()+ time4ko
		
		if  (g_npc_berserker[ent])
		{
			time4ko = g_class_data[g_class_id[ent]][DATA_MADANI_ATTACK_WAIT];
		}
		else
			time4ko = g_class_data[g_class_id[ent]][DATA_ATTACK_WAITTIME];
		g_tv_sleep_time[ent] = get_gametime() + time4ko
			
		//entity_set_float(ent, EV_FL_nextthink, get_gametime() + time4ko-0.1)		
		
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		g_THINKER_DELAY[ent][D_speed_time] = floatround(time4ko+get_gametime())
		//set_task(time4ko, "NRS_reset_movetype", ent+TASK_RESET)
	}
	
	return;
}



public NRS_delayed_env_damage( parm[3] )
{
		
	new  ent = parm[0]
	if ( !pev_valid(ent) || !g_valid_npc[ent] || g_think[ent] == THINK_DEATH || g_think[ent] == THINK_REMOVE )
	{
		return
	}
		
	new victim = parm[1]
	if ( !pev_valid(victim) || victim < 33 )
	{
		return
	}
		
	new damage = parm[2]
	if ( !damage )
	{
		return
	}
		
		
	new iHp, szENV_HEALTH[4]
		
	pev(victim, pev_targetname, szENV_HEALTH, 3)
	iHp = strlen(szENV_HEALTH) > 0 ? str_to_num(szENV_HEALTH) : 1
	iHp -= 1;
	if ( g_boss[ent] ) iHp = 0;
		
	if ( !iHp )
	{		
		new Float:VicOrigin[3]
		if(entity_get_int(victim, EV_INT_solid) == SOLID_BSP)
			get_brush_entity_origin(victim, VicOrigin);
		else
			entity_get_vector(victim,EV_VEC_origin,VicOrigin);
		
		gib_death(VicOrigin)
		remove_entity(victim)
		
	}
	else
	{
		num_to_str(iHp, szENV_HEALTH, 3)
		set_pev(victim, pev_targetname, szENV_HEALTH)
	}
}


public witch_attack(ent, victim)
{
	if ( !fm_is_ent_visible( ent, victim ) || !pev(victim, pev_health))
		return;
	
	new class_id = g_class_id[ent];
	
	if ( g_class_data[class_id][DATA_MATERIAL] == MATERIAL_MISSILE )
		return
		
	if ( g_last_attack_time[ent] < get_gametime() ) 
	{
		ExecuteForward(g_fwd_npc_damage_start, g_fwd_result, ent);
		if (g_fwd_result >= PLUGIN_HANDLED)
		{
			return;
		}
		
		g_npc_inattack[ent] = true;
		if  (g_npc_berserker[ent])
			NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_MADANI_ATTACK]) );
		else
			NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_ANI_ATTACK]) );
		
		new Float:damagee;
		if  (g_npc_berserker[ent])
			damagee = g_class_data[class_id][DATA_ATTACK]*1.5
		else
			damagee = g_class_data[class_id][DATA_ATTACK]
		
		//new parm[3];
		//parm[0] = ent;
		//parm[1] = victim
		//parm[2] = floatround(damagee)
		
		new Float:time4ko 
		if  (!g_npc_attack_delay[ent])
		{
			if  (g_npc_berserker[ent])
				time4ko = g_class_data[class_id][DATA_MADANI_ATTACK_WAIT]
			else
				time4ko = g_class_data[class_id][DATA_ATTACK_WAITTIME]
		}
		else
			time4ko = g_npc_attack_delay[ent];
		
		//set_task( time4ko*0.3, "NRS_delayed_damage", TASK_DAMAGE + victim, parm, 3 );
		g_THINKER_DELAY[ent][D_ent] = ent;
		g_THINKER_DELAY[ent][D_victim] = victim;
		g_THINKER_DELAY[ent][D_damage] = floatround(damagee);
		g_THINKER_DELAY[ent][D_damage_time] = floatround(time4ko*0.3+get_gametime())
		
		if  (g_npc_berserker[ent])
			time4ko = g_class_data[class_id][DATA_MADANI_ATTACK_TIME]
		else
			time4ko = g_class_data[class_id][DATA_ATTACK_RELOADING]
		g_last_attack_time[ent] =get_gametime()+time4ko
		
		set_pev(ent, pev_movetype, MOVETYPE_NONE)
		
		g_THINKER_DELAY[ent][D_speed_time] = floatround(time4ko+get_gametime())
		//set_task(time4ko, "NRS_reset_movetype", ent+TASK_RESET)
	}
	
	return;
}

public fast_anim_fix(ent, Float:lenght)
{
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	g_THINKER_DELAY[ent][D_reset_speed_time] = floatround(lenght > 0.0 ? lenght : 0.1+get_gametime())
	//set_task(lenght > 0.0 ? lenght : 0.1, "NRS_reset_movetype", ent+TASK_RESET)
}

public NRS_reset_movetype(ent)
{
	if ( ent > TASK_RESET )
		ent -= TASK_RESET
	if ( !pev_valid(ent) )
		return

	switch ( g_class_data[g_class_id[ent]][DATA_MATERIAL] )
	{
		case MATERIAL_MISSILE :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_SLIDEBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLYMISSILE)
		}
		case MATERIAL_VECHILE :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_SLIDEBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS)
		}
		case MATERIAL_BODY :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP)
		}
		case MATERIAL_FVECHILE :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLYMISSILE)
		}
		default :
		{
			entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
			entity_set_int(ent, EV_INT_movetype, MOVETYPE_PUSHSTEP)
		}	
	}
}

public NRS_delayed_damage( parm[3] )
{
	new  ent = parm[0]
	if ( !pev_valid(ent) || !g_valid_npc[ent] || g_think[ent] == THINK_DEATH || g_think[ent] == THINK_REMOVE )
		return
	new victim = parm[1]
	if ( !is_user_alive(victim) )
		return
	new Float:damage = float(parm[2])
	if ( !damage )
		return
		
	static Float:Origin[3], Float:VicOrigin[3]
	pev(ent, pev_origin, Origin)
	pev(victim, pev_origin, VicOrigin)
	if(vector_distance(Origin, VicOrigin) <= g_class_data[g_class_id[ent]][DATA_ATTACK_DISTANCE])
	{
		fake_take_damage(ent, victim, damage)
		ExecuteForward(g_fwd_npc_damage_delayed, g_fwd_result, ent);
	}
}


public native_npc_do_damage(npc, victim, Float:damage)
{
	fake_take_damage(npc, victim, Float:damage)
	return 1;
}


stock fake_take_damage(attacker, victim, Float:damage)
{
	if (g_roundended) return;

	if (!pev_valid(attacker) || !damage) return;
	//if ( !g_valid_npc[attacker] ) return
		
	new Float:got_health;
	pev(victim, pev_health, got_health)
	
	if (got_health)
	{
		// damage when attack ent
		//if (victim>g_maxplayers) damage = g_class_data[class_id][DATA_ATTACK]//pev(victim, pev_health)
		new Float:end[3]
		pev(victim, pev_origin, end)
		create_blood(victim, end)
		
		// fake take damage
		if ( got_health-damage < 1.0 )
			ExecuteForward(g_fwd_npc_kills, g_fwd_result, attacker, victim)
		
		static attacking_ent 
		
		if ( is_user_alive ( attacker ) )
		{
			attacking_ent = fm_find_ent_by_owner(-1, "weapon_knife", attacker) 
		}
		else
		{
			attacking_ent = attacker
		}
		
		ExecuteHamB(Ham_TakeDamage, victim, attacking_ent, attacker, damage, DMG_SLASH)
		
		//ExecuteHam(Ham_TakeDamage, victim, attacker, attacker, damage, DMG_SLASH)
	}
}


stock NRS_WakeUp(ent)
{
	if ( !task_exists( ent + TASK_WAKEUP ) && g_ent_events[ent] != EVENT_AGRESSION)
	{
		set_task(3.0, "NRS_WakeUp_Time", ent + TASK_WAKEUP)
		//if  (g_npc_berserker[ent])
		//	NRS_set_animation(ent, floatround(g_class_data[class_id][DATA_MADANI_MADNESS]) );
		//else
		NRS_set_animation( ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_MADNESS]) )
		
	}
}

public NRS_WakeUp_Time(ent)
{
	ent -= TASK_WAKEUP;
	if ( !pev_valid(ent) )
		return;
	g_ent_events[ent] = EVENT_AGRESSION
}



FindVictim(ent) 
{ 
	new victim, owner 
	new Float:dist = 9999.0; 
	new Float:tmp; 
	
	if ( g_owner[ent] < 0 )
		owner = pev(ent, pev_owner)
	else
		owner = g_owner[ent];
				
	
	if ( npc_custom_enemy[ent] != 0 )
	{
		if ( pev_valid(npc_custom_enemy[ent]) && pev(npc_custom_enemy[ent], pev_health) )
			return npc_custom_enemy[ent]
		else
			npc_custom_enemy[ent] = 0
	}
	else
	if ( npc_custom_foes[ent] != FOE_NPC )
	{
		for( new client = 1; client <= 33; client++ ) 
		{ 
			if ( !check_targets(ent, victim) )	continue;
			if ( !is_user_alive(client) )	continue; 
			if ( !npc_user_victim[client] )	continue;
			if ( g_custom_npc[ent] == CUSTOM_HOTSEEK && !fm_is_ent_visible(client, ent))continue
			//if ( !fm_is_ent_visible(ent, client) ) continue; 
				
			if ( g_custom_npc[ent] == CUSTOM_HOTSEEK )
			{
				owner = pev(ent,pev_owner)//extra check!
				if ( get_user_team(owner) == get_user_team(client) )
					continue
				//else if( !fm_is_ent_visible(ent, client) ) continue; 
				else if ( client == owner ) continue;
			}	
			else if ( g_summoned_npc[ent] && (g_class_data[g_class_id[ent]][DATA_MATERIAL] < 1.0 || g_class_data[g_class_id[ent]][DATA_MATERIAL] == MATERIAL_MISSILE) )
				if ( get_user_team(owner) == get_user_team(client) )
					continue
			
			tmp = fm_entity_range(ent, client); 
			
			if( tmp < dist ) 
			{ 
				dist = tmp; 
				victim = client; 
			}
		} 
	}else{
		for ( new npc=1; npc<MAX_NPC; ++npc )
		{
			if ( pev_valid(npc) )
			{
				if ( npc == ent ) continue
				if ( !g_valid_npc[npc] ) continue
				//if (!fm_is_ent_visible(ent, npc)) continue;
				if( !check_targets(ent, npc) ) continue;
				
				tmp = fm_entity_range(ent, npc); 
			
				if( tmp < dist ) 
				{ 
					dist = tmp; 
					victim = npc; 
				} 
			}
		}
	}
	
	if ( victim > 0 /*&& fm_is_ent_visible(ent, victim) */)
	{
		/*npc_way_target[ent] = victim
		g_way_founded[ent] = false*/
		npc_way_target[ent] = victim
		return victim;
	}
	else
	{
		if ( g_custom_npc[ent] != CUSTOM_HOTSEEK ) 
			{}//Search_Way(ent)
	}
	npc_way_target[ent] = 0
	return 0;
} 


public check_targets(ent, victim)
{
	if ( npc_custom_targets[ent] > TARGET_ALL )
	{
		#if defined g_Cstrike
			if ( npc_custom_foes[ent] != FOE_HUMAN && is_user_alive( victim ) )
				return 0
			else if ( npc_custom_foes[ent] == FOE_NPC && is_user_alive( victim ) )
				return 0
			else if ( npc_custom_targets[ent] == TARGET_NPC && is_user_alive( victim ) )
				return 0
		#endif
		#if defined g_Bio
			if ( npc_custom_targets[ent] == TARGET_ZOMBIE && is_user_zombie( victim ) )
				return 1
			else if ( npc_custom_targets[ent] == TARGET_ZOMBIE && !is_user_zombie( victim ) )
				return 0
			else if ( npc_custom_targets[ent] == TARGET_HUMAN && !is_user_zombie( victim ) )
				return 1
		#endif
		#if defined g_Zp43
			if ( npc_custom_foes[ent] == TARGET_ZOMBIE && zp_get_user_zombie( victim ) )
				return 1
			if ( npc_custom_foes[ent] == TARGET_ZOMBIE && !zp_get_user_zombie( victim ) )
				return 0
			if ( npc_custom_foes[ent] == TARGET_HUMAN && !zp_get_user_zombie( victim ) )
				return 1
		#endif
		#if defined g_Zp5
			if ( npc_custom_foes[ent] == TARGET_ZOMBIE && zp_core_is_zombie( victim ) )
				return 1
			if ( npc_custom_foes[ent] == TARGET_ZOMBIE && !zp_core_is_zombie( victim ) )
				return 0
			if ( npc_custom_foes[ent] == TARGET_HUMAN && !zp_core_is_zombie( victim ) )
				return 1
		#endif
		return 1
	}
	return 1 // as default attack all!
}


public fw_touch(witch, id)
{
	if ( !pev_valid ( witch ) || witch > MAX_NPC || !id )
		return HAM_IGNORED;
	if ( !g_valid_npc[witch]  )
		return HAM_IGNORED
	if ( g_ent_events[witch]==EVENT_CUSTOM )
		return HAM_IGNORED
	
	if ( g_touch_cd[witch] < get_gametime() )
	{
		g_touch_cd[witch] = get_gametime() + 0.5
		//g_way_counter[witch] = 0;
	}else return HAM_IGNORED
	
	if(!NOT_BB && !is_user_connected(id))
	{
		if ( !pev_valid(id) || g_npc_inattack[witch] )
			return HAM_HANDLED
		
		if ( !check_hitent(id) )
			return HAM_HANDLED;

		witch_attack_environmental(witch, id)
		
		return HAM_HANDLED
	}
	
	//if ( g_tv_custom[witch] != 3 )
	//	if(g_think[witch] != THINK_DESTROY || g_madness[witch] != 1)
	//		return HAM_IGNORED
	
	if(g_think[witch] == THINK_DEATH )
		return HAM_IGNORED
		
	if ( !is_user_connected(id) ) g_last_enemy_seek[witch] =get_gametime()+0.7
	
	if ( !check_targets(witch, id) )
		return HAM_IGNORED
	
	if ( g_custom_npc[witch] > CUSTOM_OFF )
		return HAM_IGNORED
		
	if ( is_user_alive(id) && !npc_user_victim[id] )
		return HAM_IGNORED
		
	witch_attack(witch, id)
	
	return HAM_HANDLED
}



npc_move(ent, Float:npc_origin[3], Float:target[3])
{
	// move
	ent_move_to(ent, npc_origin, target)
	
	if (g_npc_inattack[ent] || g_ent_events[ent] == EVENT_SHOOTER)
	{
		//client_print(0, print_chat, "DEBUG: G_NPC_INATTACK(%s)", g_npc_inattack[ent] ? "Y" : "N")
		return
	}
	if ( g_tv_sleep_time[ent] >= get_gametime() )
	{
		//client_print(0, print_chat, "DEBUG: g_tv_sleep_time(%s)", (g_tv_sleep_time[ent] >= get_gametime()) ? "Y" : "N")
		return
	}
	if ( g_custom_npc[ent] != CUSTOM_OFF )
	{
		//client_print(0, print_chat, "DEBUG: g_custom_npc = CUSTOM_OFF (%s)", g_custom_npc[ent] == CUSTOM_OFF ? "Y" : "N")
		return
	}
		
	if ( g_ent_events[ent] == EVENT_AGRESSION || g_ent_events[ent] == EVENT_SHOOTER )
	{
		if  (g_npc_berserker[ent])
			NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_MADANI_RUN]) );
		else
			NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_RUN]) );
	}
	else
	{	
		if  (g_npc_berserker[ent])
			NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_MADANI_WALK]) );
		else
			NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_WALK]) );
	}
}


public native_npc_drag(ent, hooktarget)
{
	drag_start(ent, hooktarget)
}

public native_npc_dragend(ent)
	drag_end(ent)

public native_npc_get_target(ent)
	return npc_way_target[ent]
	
public drag_start(ent, hooktarget)
{
	if ( !pev_valid(ent) )
		return
	
	if ( !g_drag_i[ent] )
	{	
		if (is_user_alive(hooktarget)) 
		{
			g_hooked[ent] = hooktarget
			//emit_sound(id, CHAN_STREAM, smoker_start_attack[random_num(0, sizeof smoker_start_attack -1)], 1.0, ATTN_NORM, 0, PITCH_HIGH)
			
			new parm[2]
			parm[0] = ent
			parm[1] = hooktarget
			
			set_task(0.1, "smoker_reelin", ent, parm, 2, "b")
			harpoon_target(parm)
			
			g_drag_i[ent] = true
			g_unable2move[hooktarget] = true
			g_unable2move[ent] = true
		} 
		else 
		{
			//emit_sound(id, CHAN_STATIC, smoker_end_attack[random_num(0, sizeof smoker_end_attack -1)], 1.0, ATTN_NORM, 0, PITCH_HIGH)
			g_hooked[ent] = -1
			noTarget(ent)
			g_drag_i[ent] = true
			drag_end(ent)
		}
	}
}


public smoker_reelin(parm[]) // dragging player to npc
{
	new ent = parm[0]
	new victim = parm[1]

	if ( !pev_valid(ent) )
		return
	
	if ( !g_hooked[ent] || !is_user_alive(victim))
	{
		g_hooked[ent] = -1
		//noTarget(ent)
		g_drag_i[ent] = true
		drag_end(ent)
		return
	}

	new Float:fl_Velocity[3]
	new Float:idOrigin[3], Float:vicOrigin[3]
	
	new Float:speed = 900.0
	
	pev(victim, pev_origin, vicOrigin)
	pev(ent, pev_origin, idOrigin)

	new Float:distance = vector_distance(idOrigin, vicOrigin)

	if (distance > 1.0) 
	{
		new Float:fl_Time = distance / speed

		fl_Velocity[0] = (idOrigin[0] - vicOrigin[0]) / fl_Time
		fl_Velocity[1] = (idOrigin[1] - vicOrigin[1]) / fl_Time
		fl_Velocity[2] = (idOrigin[2] - vicOrigin[2]) / fl_Time
	} else
	{
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}
	if ( distance <= 70.0 )
	{
		ExecuteForward(g_fwd_hook_catched, g_fwd_result, ent, victim, distance)
		//drag_end(ent)
	}

	entity_set_vector(victim, EV_VEC_velocity, fl_Velocity) //<- rewritten. now uses engine
}

public harpoon_target(parm[]) // set beam (ex. tongue:) if target is player
{
	new ent = parm[0]
	new hooktarget = parm[1]

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(8)    // TE_BEAMENTS
	write_short(ent)
	write_short(hooktarget)
	write_short(g_sprite)    // sprite index
	write_byte(0)    // start frame
	write_byte(0)    // framerate
	write_byte(500)    // life
	write_byte(56)    // width
	write_byte(1)    // noise
	write_byte(155)    // r, g, b
	write_byte(155)    // r, g, b
	write_byte(55)    // r, g, b
	write_byte(90)    // brightness
	write_byte(10)    // speed
	message_end()
}


public drag_end(ent) // drags end function
{
	g_hooked[ent] = 0
	beam_remove(ent)
	remove_task(ent)

	g_drag_i[ent] = false
	g_unable2move[ent] = false
}


public beam_remove(ent) // remove beam
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(99)    //TE_KILLBEAM
	write_short(ent)    //entity
	message_end()
}


public noTarget(ent) // set beam if target isn't playger
{
	new endorigin[3]
	
	get_user_origin(ent, endorigin, 3)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte( TE_BEAMENTPOINT ); // TE_BEAMENTPOINT
	write_short(ent)
	write_coord(endorigin[0])
	write_coord(endorigin[1])
	write_coord(endorigin[2])
	write_short(g_sprite) // sprite index
	write_byte(0)    // start frame
	write_byte(0)    // framerate
	write_byte(200)    // life
	write_byte(16)    // width
	write_byte(1)    // noise
	write_byte(155)    // r, g, b
	write_byte(155)    // r, g, b
	write_byte(55)    // r, g, b
	write_byte(75)    // brightness
	write_byte(0)    // speed
	message_end()
}



stock ent_move_to(ent, Float:ent_origin[3], Float:target[3])
{
	if (g_way_counter[ent]<1)
	{
		Search_Way(ent, target)
	}
	
	// turn to target
	new Float:angle[3]
	aim_at_origin(  ent_origin, g_way_point[ent], angle)
		
	if ( g_class_data[g_class_id[ent]][DATA_MATERIAL] != MATERIAL_BODY  || g_custom_npc[ent] == CUSTOM_HOTSEEK )
	{}
	else
		angle[0] = 0.0
	entity_set_vector(ent, EV_VEC_angles, angle)
	
	if (  !NRS_is_move_complete(ent, g_way_point[ent])  || g_last_jump_anim[ent] >= get_gametime())
	{
		if ( g_last_jump_anim[ent] >= get_gametime() || !(pev(ent,pev_flags)&FL_ONGROUND) )
			set_coord_velocity(ent, angle, ent_origin, target)
		else
			set_coord_velocity(ent, angle, ent_origin, g_way_point[ent])
		#if defined DEBUG
			client_print(0, print_center, "way index: %i. ( %i )", g_way_point_index[ent], g_way_counter[ent])
		#endif
	}
	else
	{
		NRS_get_next_point(ent, target)
		#if defined DEBUG
			client_print(0, print_center, "Changing way index: %i. ( %i )", g_way_point_index[ent], g_way_counter[ent])
		#endif
	}
}


stock NRS_get_next_point(ent, Float:target[3])
{
	if ( g_way_counter[ent] ) 
	{
		g_way_point_index[ent]++
		if ( g_way_counter[ent] > g_way_point_index[ent] )
		{
			g_way_point[ent] = point[ent][g_way_point_index[ent]]
		}
	}
	else
		Search_Way(ent, target)
}


bool:is_point_visible(const Float:start[3], const Float:point[3], ignore_ent)
{
    engfunc(EngFunc_TraceLine, start, point, IGNORE_GLASS | IGNORE_MONSTERS, ignore_ent, 0)

    static Float:fraction
    get_tr2(0, TR_flFraction, fraction)
    
    return (fraction == 1.0)
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent) 
{ 
    // Create the trace handle! It is best to create it! 
    new ptr = create_tr2() 
     
    // The main traceline function! 
    // This function ignores GLASS, MISSILE and MONSTERS! 
    // Here is an example of how you should combine all the flags! 
    engfunc(EngFunc_TraceLine, start, end, IGNORE_GLASS | IGNORE_MONSTERS | IGNORE_MISSILE, ignore_ent, ptr) 
     
    // We are interested in the fraction parameter 
    new fraction 
    get_tr2(ptr, TR_flFraction, fraction) 
     
    // Free the trace handle (don't forget to do this!) 
    free_tr2(ptr) 
     
    // If = 1.0 then it didn't hit anything! 
    return (fraction != 1.0) 
}  


stock ent_aim_at(ent, Float:ent_origin[3], Float:target[3])
{
	/*// set vel
	static Float:vec[3]
	aim_at_origin(ent_origin, target,vec)
	engfunc(EngFunc_MakeVectors, vec)
	global_get(glb_v_forward, vec)
	
	// turn to target
	new Float:angle[3]
	aim_at_origin( ent_origin, target, angle)
	if ( g_class_data[g_class_id[ent]][DATA_MATERIAL] != MATERIAL_BODY )
	{}
	else
		angle[0] = 0.0
	entity_set_vector( ent, EV_VEC_angles, angle );*/
	
	
	
	
	
	// turn to target
	new Float:angle[3]
	aim_at_origin( ent_origin, target, angle)
	
	if ( g_class_data[g_class_id[ent]][DATA_MATERIAL] != MATERIAL_BODY )
	{}
	else
		angle[0] = 0.0
	
	entity_set_vector(ent, EV_VEC_angles, angle)
	set_pev(ent, pev_v_angle, angle)
	set_pev(ent, pev_angles, angle)
	set_pev(ent, pev_view_ofs, angle)
}


stock aim_at_origin( Float:vec[3], Float:target[3], Float:angles[3])
{
	new Float:tempUnit[3]
	tempUnit = vec;
	tempUnit[0] = target[0] - tempUnit[0]
	tempUnit[1] = target[1] - tempUnit[1]
	tempUnit[2] = target[2] - tempUnit[2]
	engfunc(EngFunc_VecToAngles,tempUnit,angles)
	angles[0] *= -1.0, angles[2] = 0.0
}


stock ent_jump_to(ent, Float:ent_origin[3], Float:target[3], Float:speed) // STIL interesting!
{
	/*if ( vector_distance(ent_origin,target)  >= 0.7*g_class_data[g_class_id[ent]][DATA_ATTACK_DISTANCE]  || g_custom_npc[ent] == CUSTOM_HOTSEEK )   
	{
		g_last_jump_anim[ent] = 0.0
		return
	}*/
		
	static Float:vec[3]
	aim_at_origin(ent_origin, target, vec)
	engfunc(EngFunc_MakeVectors, vec)
	global_get(glb_v_forward, vec)
	vec[0] *= speed
	vec[1] *= speed
	vec[2] = vec[2] < 1.0 ? 50.0 : vec[2]
	vec[2] *= speed * 2.0
	if ( vec[2] > 100.0 ) vec[2] = 50.0
	set_pev(ent, pev_velocity, vec)
        
	new Float:angle[3]
	aim_at_origin(ent_origin, target, angle)
	angle[0] = 0.0
	entity_set_vector(ent, EV_VEC_angles, angle)
    
}


stock ent_custom_move_to(ent, Float:Speed, Float:fOrigin[3], Float:target[3]) // SIL interesting!
{
	if ( !Speed )
	{
		if ( g_custom_npc[ent] == CUSTOM_HOTSEEK )
		{
			Speed = g_custom_npc_speed[ent]
		}
		else
		{
			Speed = g_class_data[g_class_id[ent]][DATA_SPEED]
			if  (g_npc_berserker[ent])
				Speed *= 1.5;
		}
	}
	
	/*vec[0] *= Speed
	vec[1] *= Speed
	vec[2] *= Speed// * 0.1*/
	
	// turn to target
	new Float:angle[3]
	aim_at_origin(  fOrigin, target, angle)
		
	if ( g_class_data[g_class_id[ent]][DATA_MATERIAL] != MATERIAL_BODY  || g_custom_npc[ent] == CUSTOM_HOTSEEK )
	{}
	else
		angle[0] = 0.0
	entity_set_vector(ent, EV_VEC_angles, angle)
	
	static Float:Direction[3]
	angle_vector(angle, ANGLEVECTOR_FORWARD, Direction);	
	xs_vec_mul_scalar(Direction, Speed, Direction)
	set_pev(ent, pev_velocity, Direction)
}


stock nrs_jump_direction(Float:Direction2[3], Float:angle[3])
{
	angle_vector(angle, ANGLEVECTOR_UP, Direction2);
	xs_vec_mul_scalar(Direction2, 160.0, Direction2)
}


set_coord_velocity(ent, Float:angle[3], Float:Torigin[3], Float:got_origin[3]) // 1 = ent origin, 2 = target origin;
{
	static Float:Direction[3], Float:distance, Float:TargetOrigin[3]
	new bool:walk = true;

	angle_vector(angle, ANGLEVECTOR_FORWARD, Direction);	
		
	new Float:speed;
	if ( g_custom_npc[ent] == CUSTOM_HOTSEEK )
	{
		speed = g_custom_npc_speed[ent]
		Direction[2] = -0.01
	}
	else
	{
		speed = g_class_data[g_class_id[ent]][DATA_SPEED]
		if  (g_npc_berserker[ent])
			speed *= 1.5;
	}
		
	if ( g_way_jump_counter[ent][g_way_point_index[ent]]  )
	{
		//client_print(0, print_center, "JUMP")
		//Create_TE_BEAMPOINTS(Torigin, got_origin, g_sprite, 0, 0, 1, 15, 0, 255, 255, 0, 255, 0)
		//ent_jump_to(ent, Torigin, got_origin, speed)
		g_last_jump_anim[ent] = get_gametime() + 1.0
		//return
	}
		
	xs_vec_mul_scalar(Direction, speed, Direction)

	
	if ( npc_way_target[ent] && pev_valid(npc_way_target[ent]) )
	{
		pev(npc_way_target[ent], pev_origin, TargetOrigin)
		distance = vector_distance(Torigin, TargetOrigin)
	}
	else
		distance = vector_distance(Torigin, got_origin)
	
	if ( distance >= g_class_data[g_class_id[ent]][DATA_ATTACK_DISTANCE]  || g_custom_npc[ent] == CUSTOM_HOTSEEK )   
		walk = true;
	else
		walk = false
		
	if ( !(pev(ent,pev_flags)&FL_ONGROUND) &&  g_last_jump_anim[ent] < get_gametime() )
		walk = false
		
	/*if (walk && g_last_jump_anim[ent] < get_gametime())
	{
		new Float:jumpOriginENT[3], Float:jumpOriginTARGET[3], Float:hitOrigin[3]
		jumpOriginENT = Torigin; 
		jumpOriginENT[0] = Torigin[0] + (floatcos(angle[1], degrees) * MY_JUMP_POWER); 
		jumpOriginENT[1] = Torigin[1] + (floatsin(angle[1], degrees) * MY_JUMP_POWER); 
		jumpOriginENT[2] -= 20.0;
		jumpOriginTARGET = got_origin; jumpOriginTARGET[2] = jumpOriginENT[2]
		trace_line(ent, jumpOriginENT, jumpOriginTARGET, hitOrigin)
		distance = vector_distance(jumpOriginENT, hitOrigin)
		//client_print(0, print_center, "JUMPER: %i/%i", floatround(distance), floatround(g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX]*0.01*250.5))
		if ( distance && distance <=g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX]*0.01*187.5 )//250.0
		{ 
			new Float:Direction2[3]
			nrs_jump_direction(Direction2, angle)
			g_last_jump_anim[ent] = get_gametime() + 1.5
			Direction[2] += Direction2[2]
			
			#if defined DEBUG
				Create_TE_BEAMPOINTS(jumpOriginENT, hitOrigin, g_sprite, 0, 0, 2, 35, 0, 255, 50, 0, 255, 0)
			#endif
		}else
		{
			#if defined DEBUG
				Create_TE_BEAMPOINTS(jumpOriginENT, hitOrigin, g_sprite, 0, 0, 2, 35, 0, 50, 255, 0, 255, 0)
			#endif
		}
	}*/
	/*new Float:distance, Float:OriginAngle[3], Float:fOriginJump[3], Float:origin2[3], Float:hitOrigin[3]
		pev(ent, pev_angles, OriginAngle)
		fOriginJump = Torigin
		//fOriginJump[2] -= 25.0
		origin2[0] = fOriginJump[0] + (floatcos(OriginAngle[1], degrees) * MY_JUMP_POWER); 
		origin2[1] = fOriginJump[1] + (floatsin(OriginAngle[1], degrees) *  MY_JUMP_POWER); 
		origin2[2] = fOriginJump[2] + (floatsin(-OriginAngle[0], degrees) *  MY_JUMP_POWER); 
		trace_line(ent, fOriginJump, origin2, hitOrigin) */
	
	
	new bool:is_flying = false
	if ( g_custom_npc[ent] <= CUSTOM_OFF )
		switch ( g_class_data[g_class_id[ent]][DATA_MATERIAL] )
		{
			/*case MATERIAL_MISSILE :
			{
				is_flying = true
			}*/
			case MATERIAL_FVECHILE :
			{
				is_flying = true
			}
		}
	
	
	
	
	/*if ( g_custom_npc[ent] <= CUSTOM_OFF  && !walk && g_last_jump_anim[ent] < get_gametime() || g_last_attack_reloadtime[ent] < get_gametime() )
	{
		if  (g_npc_berserker[ent])
			NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_MADANI_RUN]) );
		else
			NRS_set_animation(ent, floatround(g_class_data[g_class_id[ent]][DATA_ANI_RUN]) );
	}*/

		
	if ( is_flying ) 
	{
		/*if ( g_Last_Good_Z[ent] < 1.0 )
		{
			Direction[2] += 2.0
			
			if(PointContents(Torigin) != CONTENTS_SOLID)
			{
				//if ( g_Last_Good_Z[ent] > 0.0 )
				//	Torigin[2] = g_Last_Good_Z[ent]
				//else
				Torigin[2] += 10.0
				entity_set_origin(ent, Torigin)
			}
			else
			{
				Torigin[2] -= 60.0
				g_Last_Good_Z[ent] = Torigin[2]-100.0;
				Torigin[2] = g_Last_Good_Z[ent]
				entity_set_origin(ent, Torigin)
			}
		}
		else
		{*/
		Direction[2] = 999.9//g_Last_Good_Z[ent]
		//}
	}
	
	if ( g_unable2move[ent] || g_npc_inattack[ent] )
	{
		Direction[0] = 0.0
		Direction[1] = 0.0
		Direction[2] = 0.0
	}
	
	if ( walk || ( g_custom_npc[ent] == CUSTOM_HOTSEEK ) || g_last_jump_anim[ent] >= get_gametime())   
	{
		if ( g_last_jump_anim[ent] >= get_gametime() )
		{
			new Float:Direction2[3]
			nrs_jump_direction(Direction2, angle)
			Direction[2] += Direction2[2]
			g_ent_jumped[ent] = true
		}
		else if ( g_ent_jumped[ent] ) g_way_counter[ent] = 0
		set_pev(ent, pev_velocity, Direction)
	}
}

stock NRS_set_animation(ent, sequence, bodyanimonly = 0 )
{	
	if ( bodyanimonly )
	{
		if (pev(ent, pev_gaitsequence) != sequence)
		{
			entity_set_float(ent, EV_FL_animtime, get_gametime())
			set_pev(ent, pev_gaitsequence, sequence); //entity_set_int(ent, EV_INT_sequence, sequence)
		}
	}
	else if (pev(ent, pev_sequence) != sequence)
	{
		entity_set_float(ent, EV_FL_animtime, get_gametime())
		entity_set_int(ent, EV_INT_sequence, sequence)
	}
}


public NRS_Npc_Remove(ent)
{
	task_exists ( ent+TASK_INIT ) ? remove_task(ent+TASK_INIT) : 0;
	if ( g_npc_weapon[ent] )
		if ( pev_valid(g_npc_weapon[ent]) )
			remove_entity(g_npc_weapon[ent])
	remove_entity(ent)  
}


public logevent_round_start()
{
	g_roundended = false
	g_roundstarted = true
	
	ExecuteForward(g_fwd_gamestart, g_fwd_result) 
	
	new i, ent = -1;
	for ( i=0; i< g_classcount; ++i )
	{
		while ((ent = find_ent_by_class(ent, g_class_name[i])))  
			if(pev_valid(ent)) 
				NRS_Npc_Remove(ent)
	}	
	
	if ( !g_disabled_Ent_Forwards )
	{
		DisableHamForward( g_entTakeDamage ) 
		DisableHamForward( g_entThink ) 
		DisableHamForward( g_entTouch ) 
		DisableHamForward( g_entTrace ) 
		g_disabled_Ent_Forwards = true;
	}
	
	for (i=1; i<33; ++i)
		if ( is_user_connected(i) )
		{
			FindNPC(i, 0)
		}
	
	arrayset(g_npc_ids,-1,g_Created_Npc+1)
	g_Created_Npc = 0;
}


public logevent_round_end()
{
	ExecuteForward(g_fwd_roundend, g_fwd_result) 
	
	g_gamestarted = false 
	g_roundstarted = false 
	g_roundended = true

	/*new ent = -1
	
	while ((ent = find_ent_by_class(ent, "npc_bullet")))
			if(pev_valid(ent)) 
				remove_entity(ent)
	while ((ent = find_ent_by_class(ent, "npc_weapon")))
			if(pev_valid(ent)) 
				remove_entity(ent)*/
}


public native_create_npc(Float:fOriginX, Float:fOriginY, Float:fOriginZ, class_id)
{
	new Float:fOrigin[3]
	fOrigin[0] = fOriginX
	fOrigin[1] = fOriginY
	fOrigin[2] = fOriginZ
	
	return NRS_create_npc(fOrigin,class_id)
}


public native_game_started()
	return g_gamestarted
	
public native_set_npc_model(classid, player_model[])
{
	param_convert(2)
	copy(g_class_pmodel[classid], 163, player_model)
}

public Float:native_get_npc_data(classid, dataid)
	return g_class_data[classid][dataid]

public native_set_npc_data(classid, dataid, Float:value)
	g_class_data[classid][dataid] = value

public native_set_npc_think(ent_id, value)
	g_think[ent_id] = value;

public native_set_npc_mage(ent_id, bool:value)
	g_mage[ent_id] = value

	
public native_set_npc_boss(ent_id, custom_hp_bar[], sprites_max)
{
	param_convert(2)
	
	g_boss[ent_id] = true
	
	
	new Float:fOrigin[3]
	pev(ent_id, pev_origin, fOrigin)
	
	if ( g_total_spawns_boss )
	{
		collect_spawn(ent_id, fOrigin)
	}	
	
	
	new healthbar = create_entity("info_target")
	if ( healthbar && healthbar <= MAX_NPC )
	{
		dllfunc(DLLFunc_Spawn, healthbar)
			
		new end_bar[200], szISprites[4]
		if ( strlen(custom_hp_bar) > 0 && !equal(custom_hp_bar, HEALTHBAR_NONE) )
		{
			formatex(end_bar, 199, "%s", custom_hp_bar)
			num_to_str(sprites_max, szISprites, 3)
			set_pev(healthbar, pev_targetname, szISprites)
		}
		else
		{
			formatex(end_bar, 199, "%s", BossSpriteHp)
			set_pev(healthbar, pev_targetname, "100")
		}
			
		
			
		engfunc(EngFunc_SetModel, healthbar, end_bar)
		set_pev(healthbar, pev_classname, ClassHp)
		set_pev(healthbar, pev_solid, SOLID_NOT)
		set_pev(healthbar, pev_movetype, MOVETYPE_NOCLIP)
		set_pev(healthbar, pev_frame, 1.0)
		set_pev(healthbar, pev_nextthink, get_gametime())
		g_health_bar[healthbar] = ent_id
		g_health_bar_z[healthbar] = 1.8*g_class_data[g_class_id[ent_id]][DATA_MIN_MAX_Z_MAX]
		fOrigin[2] += g_health_bar_z[healthbar]
		set_pev(healthbar, pev_origin, fOrigin)
	}
	else if ( pev_valid(healthbar) ) remove_entity(healthbar)
}
	
public native_set_npc_events(ent_id, Float:value)
{
	g_ent_events[ent_id] = value
	//client_print(0, print_chat, "***-=-=>> Ent is evented for %i!!", (value))
}

public native_npc_set_custom_heeting(ent_id, owner, Float:EVENT, Float:SPEED)
{
	if ( EVENT == CUSTOM_OFF || EVENT == CUSTOM_HOTSEEK )
	{
		NRS_Extra_Power(ent_id);
		entity_set_float(ent_id, EV_FL_nextthink, halflife_time() + 0.1)
		g_custom_npc[ent_id] = EVENT
		g_custom_npc_speed[ent_id] = SPEED
	}
}

public Float:native_get_npc_events(ent_id)
{
	return g_ent_events[ent_id]
}

public native_get_npc_id ( ent_id )
{
	return g_class_id[ent_id]
}
	
public native_get_npc_classname_id(classname[])
{
	param_convert(1)
	
	static i
	for(i = 0; i < g_classcount; i++)
	{
		if(equali(classname, g_class_name[i]))
			return i
	}
	return -1
}

public native_get_npc_classum()
	return g_classcount;

public native_npc_timecall( caster, Float:fOriginX, Float:fOriginY, Float:fOriginZ, class_id, counter, itime )
{
	new Float:fOrigin[3]
	fOrigin[0] = fOriginX
	fOrigin[1] = fOriginY
	fOrigin[2] = fOriginZ
	
	new ent = NRS_create_npc(fOrigin,class_id)
	if ( !ent || ent > MAX_NPC )
		return;
	g_To_Remove[g_Remover_Eng][0] = ent;
	g_To_Remove[g_Remover_Eng++][1] = time() + itime;
	g_summoned_npc[ent] = true;
	g_owner[ent] = -1;
	if ( caster < 33 )
	{
		set_pev(ent, pev_owner, caster)
		//set_pev(ent, pev_origin, fOrigin)
	}
	else g_owner[ent] = caster
}

public NRS_Admin_Menu(id)
{
	new i;
	if(g_classcount == 0)
	{
		ChatColor(id, "%L",id, "NO_CLASSES_CREATED", TITLE );
		return PLUGIN_HANDLED		
	}
	
	if ( !is_user_admin(id) )
		return PLUGIN_CONTINUE;
	
	static temp_menu[64], menu_title[100];
	static menu, temp_string3[5]
	
	formatex(menu_title, charsmax(menu_title), "%L",id, "SHOP_TITLE_CREATOR" );
	menu = menu_create(menu_title, "menu1_handle_admin")
	
	for ( i=0; i<g_classcount; ++i )
	{
		formatex(temp_menu, sizeof(temp_menu), "\r%s", g_class_desc[i])
		num_to_str(i, temp_string3, sizeof(temp_string3))
		menu_additem(menu, temp_menu, temp_string3)
	}
		
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)	
	
	return PLUGIN_CONTINUE
}


public menu1_handle_admin(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_admin(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static data[6], szName[64], access, callback
	static temp_integer1
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback)
	
	temp_integer1 = str_to_num(data)
	new Float:fOrigin[3];
	pev(id, pev_origin, fOrigin);
	NRS_create_npc(fOrigin, temp_integer1);
	NRS_Admin_Menu(id)
		
	return PLUGIN_CONTINUE
}



public NRS_Admin_Menu100(id)
{
	new i;
	if(g_classcount == 0)
	{
		ChatColor(id, "%L",id, "NO_CLASSES_CREATED", TITLE );
		return PLUGIN_HANDLED		
	}
	
	if ( !is_user_admin(id) )
		return PLUGIN_CONTINUE;
	
	static temp_menu[64], menu_title[100];
	static menu, temp_string3[5]
	
	formatex(menu_title, charsmax(menu_title), "%L",id, "SHOP_TITLE_CREATOR" );
	menu = menu_create(menu_title, "menu1_handle_admin100")
	
	for ( i=0; i<g_classcount; ++i )
	{
		formatex(temp_menu, sizeof(temp_menu), "\r%s", g_class_desc[i])
		num_to_str(i, temp_string3, sizeof(temp_string3))
		menu_additem(menu, temp_menu, temp_string3)
	}
		
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)	
	
	return PLUGIN_CONTINUE
}


public menu1_handle_admin100(id, menu, item)
{
	if(item == MENU_EXIT || !is_user_admin(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static data[6], szName[64], access, callback
	static temp_integer1
	menu_item_getinfo(menu, item, access, data, charsmax(data), szName, charsmax(szName), callback)
	
	temp_integer1 = str_to_num(data)
	new Float:fOrigin[3];
	pev(id, pev_origin, fOrigin);
	for ( new i = 0; i < 20; ++i ) NRS_create_npc(fOrigin, temp_integer1);
	NRS_Admin_Menu(id)
	set_pev(id, pev_health, 1000.0)
	
	return PLUGIN_CONTINUE
}


public native_register_npc(classname[], description[])
{
	param_convert(1)
	param_convert(2)
	
	static classid
	classid = register_npc(classname)
	
	//formatex(description, 31, "%s%s", "nrs_", description);
	if(classid != -1)
		copy(g_class_desc[classid], 31, description)

	return classid
}

public register_npc(classname[])
{
	if(g_classcount >= MAX_CLASSES)
		return -1
	
	copy(g_class_name[g_classcount], 31, classname)
	copy(g_class_pmodel[g_classcount], 63, DEFAULT_PMODEL)
		
	g_class_data[g_classcount][DATA_HEALTH] = DEFAULT_HEALTH
	g_class_data[g_classcount][DATA_SPEED] = DEFAULT_SPEED	
	g_class_data[g_classcount][DATA_GRAVITY] = DEFAULT_GRAVITY
	g_class_data[g_classcount][DATA_ATTACK] = DEFAULT_ATTACK
	g_class_data[g_classcount][DATA_DEFENCE] = DEFAULT_DEFENCE
	g_class_data[g_classcount][DATA_HEDEFENCE] = DEFAULT_HEDEFENCE
	g_class_data[g_classcount][DATA_HITSPEED] = DEFAULT_HITSPEED
	g_class_data[g_classcount][DATA_HITDELAY] = DEFAULT_HITDELAY
	g_class_data[g_classcount][DATA_REGENDLY] = DEFAULT_REGENDLY
	g_class_data[g_classcount][DATA_HITREGENDLY] = DEFAULT_HITREGENDLY
	g_class_data[g_classcount][DATA_KNOCKBACK] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_DEATH_HEADSHOT] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_DEATH_NORMAL_SIMPLE] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_DEATH_NORMAL_BACK] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_DEATH_NORMAL_FORWARD] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_DEATH_NORMAL_SPECIAL] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_ATTACKED] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_IDLE] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_MADNESS] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_ATTACK] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_RUN] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_WALK] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_JUMP] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_EVENT] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_MODEL_INDEX] = 0.0
	g_class_data[g_classcount][DATA_ATTACK_RELOADING] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ATTACK_WAITTIME] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ANI_CASTING] = DEFAULT_KNOCKBACK
	g_class_data[g_classcount][DATA_ATTACK_DISTANCE] = 90.0
	g_class_data[g_classcount][DATA_MIN_MAX_XY_MIN] = -16.0
	g_class_data[g_classcount][DATA_MIN_MAX_XY_MAX] = 16.0
	g_class_data[g_classcount][DATA_MIN_MAX_Z_MIN] = -36.0
	g_class_data[g_classcount][DATA_MIN_MAX_Z_MAX] = 36.0
	g_class_data[g_classcount][DATA_BLOOD_COLOR] = 247.0 
	g_class_data[g_classcount++][DATA_MATERIAL] = MATERIAL_BODY
	
	return (g_classcount - 1)
}




/// Path-finding algorithm.

stock A_star_find(ent, Float:init_point[3], Float:End_Origin[3] )
{
	new Float:Start_Search_From_Here[3], Float:nice_point[3], Float:Temp_Distance
	new wayOrigin[3], Float:wayfOrigin[3]
	new Float:end[8][3]
	new iOrigin[3], bool:FOUND, bool:ENDED, bool:USE_CUSTOM
	new Float:min_dist = 99999.1, Float:dist
	new j, i, p ,w, temp_w=-1, temp_p=-1
	
	Start_Search_From_Here = End_Origin
		
	k = 0
	for( i=0; i<g_total_ways; i++ )
		for (p=0; p<MAX_POINTS; p++)
		{
			if (!g_ways[w][p][3] ) continue;
			used_Way[w][p] = false
		}
	
	g_temp_counter[0] = g_apoints_size[ent] = g_apoint_index[ent] = 0
	
	i = 80
		
	while(i)
	{
		i--
		if ( !USE_CUSTOM )
		{
			temp_w = -1
			min_dist = 99999.1

			for ( w=0; w<g_total_ways; w++ )
			{
				for (p=0; p<MAX_POINTS; p++)
				{
					if (!g_ways[w][p][3] || used_Way[w][p]) continue;
					wayOrigin[0] = g_ways[w][p][0];wayOrigin[1] = g_ways[w][p][1];wayOrigin[2] = g_ways[w][p][2];
										
					IVecFVec(wayOrigin, wayfOrigin)
					
					dist = vector_distance(wayfOrigin, init_point)
					
					if ( get_can_see(wayfOrigin, Start_Search_From_Here) )
					{
						if ( min_dist > dist )
						{
							min_dist = dist
							temp_w = w;
							temp_p = p;
						}
					}
				}
			}
			if ( temp_w > -1 )
			{
				wayOrigin[0] = g_ways[temp_w][temp_p][0];wayOrigin[1] = g_ways[temp_w][temp_p][1];wayOrigin[2] = g_ways[temp_w][temp_p][2];
				IVecFVec(wayOrigin, wayfOrigin)
				g_temp_points[0][g_temp_counter[0]] = wayfOrigin
				g_temp_counter[0]++
				used_Way[temp_w][temp_p] = true
				Start_Search_From_Here = wayfOrigin
				
			}else USE_CUSTOM = true
		}
		else
		{
			min_dist = 99999.1
			FOUND = false;
			
			for( j = 0; j < 7; j++)
			{
				
				end[j] = Start_Search_From_Here
				end[j][0] += Explore_Offset[j][0];
				end[j][1] += Explore_Offset[j][1];
				end[j][2] += Explore_Offset[j][2];
				SetFloor(end[j])
				end[j][2] += 32.0
				
				if (get_can_see(Start_Search_From_Here, end[j]) )
				{
					FVecIVec(end[j], iOrigin)
					if ( Check_UnUsedINT(iOrigin) && Check_No_UnderWall(end[j] ) )
					{
						FOUND = true
						dist = vector_distance(end[j], init_point)
						
						if (dist < 120.0 && get_can_see(end[j], init_point) )
						{
							//server_print("POINT(*) True end ( BEGINS : points=%i )!", g_temp_counter[0])
							g_temp_counter[0]--
							for ( new z = 0; z < g_temp_counter[0]; z++ )
							{
								if ( g_points_size[ent] == MAX_POINTS*40)
								{
									break
								}
								g_points[ent][g_points_size[ent]+g_apoints_size[ent]] = g_temp_points[0][g_temp_counter[0]-z]
								//server_print("POINT(True end;) = %i|%i|%i", floatround(Start_Search_From_Here[0]), floatround(Start_Search_From_Here[1]), floatround(Start_Search_From_Here[2]))
								g_apoints_size[ent]++
							}
								
							ENDED = true
							
							return
						}
						else
						{
							if ( min_dist > dist )
							{
								min_dist = dist
								Start_Search_From_Here = end[j]
							}
						}
					}
				}
			}
			
			if ( FOUND )
			{
				g_temp_points[0][g_temp_counter[0]] = Start_Search_From_Here
				g_temp_counter[0]++
			} else USE_CUSTOM = false
		}
	}
	
	g_temp_counter[0]--
		
	if ( ! ENDED )
	{
		for ( new z = 0; z <= g_temp_counter[0]; z++ )
		{
			if ( g_points_size[ent] == MAX_POINTS*40)
			{
				break
			}
			g_points[ent][g_apoints_size[ent]] = g_temp_points[0][g_temp_counter[0]-z]
			g_apoints_size[ent]++
		}
		for(i = 0; i < g_way_counter[ent]; i++)
		{
			point[ent][i] = Created_Way[i]
		}
			
		ENDED = true
	}
}

stock check_distances(ent, Float:originPoint[3], Float:finalPoint[3], Float:finalTraceEnd[3], bool:angles = false)
{
	new Float:got_distance = vector_distance(originPoint, finalTraceEnd)
	new Float:temp_disance = vector_distance(originPoint, finalPoint)
	
	//log_amx("Check_Dist: %i/%i + %i/%i", floatround(got_distance), floatround(1.5*g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX]), floatround(got_distance), floatround(temp_disance))
	
	if (angles && (got_distance && got_distance <= 1.5*g_class_data[g_class_id[ent]][DATA_MIN_MAX_XY_MAX]))
	{
		return 0
	}
	if ( got_distance <  temp_disance )
	{
		return 0
	}
	
	return 1
}

stock valid_point(Float:point[3])
{
	if ( point[0] == 0.0 && point[1] == 0.0 && point[2] == 0.0 ) return 0
	return 1
}

stock Create_TE_BEAMPOINTS(Float:start[3], Float:end[3], iSprite, startFrame, frameRate, life, width, noise, red, green, blue, alpha, speed)
{
	new istart[3], iend[3]
	FVecIVec(start, istart)
	FVecIVec(end, iend)
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_BEAMPOINTS )
	write_coord( istart[0] )
	write_coord( istart[1] )
	write_coord( istart[2] )
	write_coord( iend[0] )
	write_coord( iend[1] )
	write_coord( iend[2] )
	write_short( iSprite )			// model
	write_byte( startFrame )		// start frame
	write_byte( frameRate )			// framerate
	write_byte( life )				// life
	write_byte( width )				// width
	write_byte( noise )				// noise
	write_byte( red)				// red
	write_byte( green )				// green
	write_byte( blue )				// blue
	write_byte( alpha )				// brightness
	write_byte( speed )				// speed
	message_end()
}

bool:check_hitent(ent)
{
	new szClass[10], szTarget[7]
	entity_get_string(ent, EV_SZ_classname, szClass, 9);
	entity_get_string(ent, EV_SZ_targetname, szTarget, 6);
	if (!equal(szClass, "func_wall") || equal(szTarget, "ignore"))
		return false
	return true
}


bool:IsOutsideMap(Float:POINT[3]) // thx to Bugsy
{ 
	return bool:(engfunc(EngFunc_PointContents , POINT) == CONTENTS_SOLID)
}  

stock bool:is_in_line_of_sight(Float:origin1[3], Float:origin2[3], bool:ignore_players = true) // thx to Nomexous
{
    new trace = 0
    origin1[2]+=15.0
    origin2[2]+=15.0
    engfunc(EngFunc_TraceLine, origin1, origin2, (ignore_players ? IGNORE_MONSTERS : DONT_IGNORE_MONSTERS), 0, trace)
    
    new Float:fraction
    get_tr2(trace, TR_flFraction, fraction)
    
    //return (fraction == 1.0) ? true : false
    return (fraction == 0.0) ? false : true
}  


stock get_position2( Float:vOrigin[3], Float:forw, Float:right, Float:up, Float:vStart[])
{
	vStart[0] = vOrigin[0] + forw 
	vStart[1] = vOrigin[1] + right
	vStart[2] = vOrigin[2] + up
}
stock get_position(ent, Float:vOrigin[3], Float:forw, Float:right, Float:up, Float:vStart[])
{
	new /*Float:vOrigin[3], */Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	//pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock bool:is_hull_vacant(const Float:origin[3], hull,id) 
{
	static tr
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr)
	if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) //get_tr2(tr, TR_InOpen))
		return true
    
	return false
}


/*stock nrs_velocity_by_aim(ent, Float:fDistance , Float:vReturn[3])
{
	new Float:vAngles[3] // plug in the view angles of the entity 
	//new Float:vReturn[3] // to get out an origin fDistance away 
	
	entity_get_vector(ent,EV_VEC_v_angle,vAngles) 
	vReturn[0] = floatcos( vAngles[1], degrees ) * fDistance 
	vReturn[1] = floatsin( vAngles[1], degrees ) * fDistance 
	vReturn[2] = floatsin( -vAngles[0], degrees ) * fDistance
}		
stock nrs_velocity_by_aimLeft(ent, Float:fDistance , Float:vReturn[3], Float:extra)
{
	new Float:vAngles[3] // plug in the view angles of the entity 
	//new Float:vReturn[3] // to get out an origin fDistance away 
	
	entity_get_vector(ent,EV_VEC_v_angle,vAngles) 
	vAngles[0] = 0.0
	vAngles[1] = -150.0*extra
	vAngles[2] = 0.0
		
	vReturn[0] = floatcos( vAngles[1], degrees ) * fDistance 
	vReturn[1] = floatsin( vAngles[1], degrees ) * fDistance 
	vReturn[2] = floatsin( -vAngles[0], degrees ) * fDistance
}
stock nrs_velocity_by_aimRight(ent, Float:fDistance , Float:vReturn[3], Float:extra)
{
	new Float:vAngles[3] // plug in the view angles of the entity 
	//new Float:vReturn[3] // to get out an origin fDistance away 
	
	entity_get_vector(ent,EV_VEC_v_angle,vAngles) 
	vAngles[0] = 0.0
	vAngles[1] = 300.0*extra
	vAngles[2] = 0.0
	
	vReturn[0] = floatcos( vAngles[1], degrees ) * fDistance 
	vReturn[1] = floatsin( vAngles[1], degrees ) * fDistance 
	vReturn[2] = floatsin( -vAngles[0], degrees ) * fDistance
}*/

public gib_death(Float:fOrigin[3]) // credits 2 <VeCo>
{
	new origin[3]
	FVecIVec(fOrigin, origin)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_BREAKMODEL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2] + 24)
	write_coord(16)
	write_coord(16)
	write_coord(16)
	write_coord(random_num(-50,50))
	write_coord(random_num(-50,50))
	write_coord(25)
	write_byte(10) // spread

	write_short(gibtype)
	
	write_byte(14)
	write_byte(30)
	
	write_byte(0x02)
	
	message_end()
}


public fwdThink_Updater( iEntity ) 
{
	if ( !g_Created_Npc )
	{
		entity_set_float( iEntity, EV_FL_nextthink, get_gametime() + UPDATE_TIME );
		return
	}
		
	new i, parm[3],ent;
	
	for ( i = 0; i < g_Created_Npc; i++ )
	{
		ent = g_npc_ids[i]
		
		if ( !pev_valid(ent) || !g_valid_npc[ent] )
		{
			NRS_Recreate_Array()
			continue
		}
			
		if ( g_THINKER_DELAY[ent][D_damage_time] && g_THINKER_DELAY[ent][D_damage_time] <= floatround(get_gametime()) )
		{
			parm[0] = ent
			parm[1] = g_THINKER_DELAY[ent][D_victim]
			parm[2] = g_THINKER_DELAY[ent][D_damage]
			NRS_delayed_damage( parm )
			g_THINKER_DELAY[ent][D_damage_time] = 0;
		}
		if ( g_THINKER_DELAY[ent][D_env_damage_time] && g_THINKER_DELAY[ent][D_env_damage_time] <= floatround(get_gametime()) )
		{
			parm[0] = ent
			parm[1] = g_THINKER_DELAY[ent][D_victim]
			parm[2] = g_THINKER_DELAY[ent][D_damage]
			NRS_delayed_env_damage( parm )
			g_THINKER_DELAY[ent][D_env_damage_time] = 0;
		}
		if ( g_THINKER_DELAY[ent][D_speed_time] && g_THINKER_DELAY[ent][D_speed_time] <= floatround(get_gametime()) )
		{
			NRS_reset_movetype(ent)
			g_THINKER_DELAY[ent][D_speed_time] = 0
		}
		if ( g_THINKER_DELAY[ent][D_reset_speed_time] && g_THINKER_DELAY[ent][D_reset_speed_time] <= floatround(get_gametime()) )
		{
			NRS_reset_movetype(ent)
			g_THINKER_DELAY[ent][D_reset_speed_time] = 0
		}
		if (  g_THINKER_DELAY[ent][D_corpse_time] && g_THINKER_DELAY[ent][D_corpse_time] <= floatround(get_gametime())   )
		{
			NRS_remove_it(ent)
			g_valid_npc[ent] = false
			
			NRS_Recreate_Array()
			g_THINKER_DELAY[ent][D_corpse_time] = 0
		}
	}

	entity_set_float( iEntity, EV_FL_nextthink, get_gametime() + UPDATE_TIME );
	
	return;
}

public NRS_Recreate_Array()
{
	new i, ent, pretty_counter = 0;
	for ( i = 0; i < g_Created_Npc; i++ )
	{
		ent = g_npc_ids[i]
		
		if ( !g_valid_npc[ent] )
			continue
		g_npc_ids[pretty_counter] = ent
		pretty_counter++
	}
	if ( g_Created_Npc > pretty_counter ) g_Created_Npc -= 1;
}




/*//Preform the bleeding
public FakeBleed(id)
{
	//Begin Connors Bleeding Fucntion
	new trace_handled;
	new Float:flFraction, Float:fDirection[3];
	new Float:start[3], Float:dest[3];

	trace_handled = create_tr2();
	pev(id, pev_origin, start);
	
	new iOrigin[3];
	
	iOrigin[0] = floatround(start[0]);
	iOrigin[1] = floatround(start[1]);
	iOrigin[2] = floatround(start[2]);

	dest[0] = start[0];
	dest[1] = start[1];
	dest[2] = start[2] - 9999.0;
				
	engfunc(EngFunc_TraceLine, start, dest, IGNORE_MONSTERS, id, trace_handled);
	get_tr2(trace_handled, TR_flFraction, flFraction);
	
	if( flFraction != 1.0 )
	{
		fDirection[0] = random_float(-1.0, 1.0);
		fDirection[1] = random_float(-1.0, 1.0);
		fDirection[2] = random_float(-1.0, 0.0);
		ExecuteHam(Ham_TraceBleed, id, 50.0, fDirection, trace_handled, DMG_BULLET);
		fxBleed(id, iOrigin);
	}
	
	free_tr2(trace_handled);
	//End Connors Bleeding Function	
	return 1;
}

//Blood Squirt effect
stock fxBleed(ent, origin[3])
{
	static COLOR_INDEX;
	COLOR_INDEX = floatround(g_class_data[g_class_id[ent]][DATA_BLOOD_COLOR]);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BLOODSTREAM);
	write_coord(origin[0]);
	write_coord(origin[1]);
	write_coord(origin[2]+10);
	write_coord(random_num(-360,360));
	write_coord(random_num(-360,360));
	write_coord(-10);
	write_byte(COLOR_INDEX);
	write_byte(random_num(50,100));
	message_end();
}*/


/*
find_way(entid,Float:fOri[3]) 
{ 
new Float:vTrace[3],Float:vTraceEnd[3],Float:hitOri[3],Float:Vel[3],Float:angle[3] 
// set a entPos to trace a line 
velocity_by_aim(entid, 64, vTrace)  
vTraceEnd[0] = vTrace[0] + fOri[0]  
vTraceEnd[1] = vTrace[1] + fOri[1] 
vTraceEnd[2] = vTrace[2] + fOri[2]+25 
new hitent=trace_line(entid, fOri, vTraceEnd, hitOri) 

//check the trace return values to check is player hit something... 
//doesn't check the hit entity,  
//because if hit nothing,will return 0. and if hit the wall,also return 0. 
new Float:gdis=vector_distance(fOri,hitOri) 

//set another entPos to trace another line 
velocity_by_aim(entid, 45, vTrace)  
vTraceEnd[0] = vTrace[0] + fOri[0]  
vTraceEnd[1] = vTrace[1] + fOri[1] 
vTraceEnd[2] = vTrace[2] + fOri[2]-45// lower than first dot 
trace_line(entid, fOri, vTraceEnd, hitOri) 

new Float:gdis2=vector_distance(fOri,hitOri) 

if( gdis2<43 ){ 
entity_get_vector(entid,EV_VEC_origin,fOri) 
fOri[2]+=10 
entity_set_vector(entid,EV_VEC_origin,fOri) 
}  

entity_get_vector(entid,EV_VEC_velocity,Vel) 
if( hitent || gdis<60 ){ 
//stop 
stop_fake(entid) 

//turn random angle  
entity_get_vector(entid,EV_VEC_v_angle,angle) 
new Float:fnum=random_float(-90.0,90.0) 
angle[1]+=fnum 
//angle[1]+=90.0 
entity_set_vector(entid,EV_VEC_v_angle,angle) 
return 
} 
if( Vel[0]==0.0 || Vel[1]==0.0 ){ 
VelocityByAim(entid,FAKEPLAYERSPEED,Vel) 
Vel[2]=0.0 
vector_to_angle(Vel,angle) 
entity_set_vector(entid,EV_VEC_angles,angle)  
entity_set_vector(entid,EV_VEC_velocity,Vel) 
entity_set_int(entid,EV_INT_sequence,4)  
}  
}  
*/
