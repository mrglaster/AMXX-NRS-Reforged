/**

*	Last update:
*	  9/<>/2023
*
*	Credits:
*	  Good_Hash for 'NPC REGISTER SYSTEM' used as prototype
*	  rtxa for his modification of BugfixedHL
*
*	This plugin is provided as is (no warranties).
*
*/


#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "NRS: Reforged HL Edition"
#define VERSION "0.1"
#define AUTHOR "Glaster/Safety1st"



public plugin_init() {
	register_plugin( PLUGIN, VERSION, AUTHOR )
	register_dictionary( "nrs_main_hl.txt" )


#if defined DEBUG
	server_print( "Max entities %d", global_get(glb_maxEntities) )
#endif
}