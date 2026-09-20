#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;
#include clientscripts\mp\zombies\_zm_weapons;
#include clientscripts\mp\zm_transit;

main()
{
    // zm_qol: CLIENT HALF of the Diner buildable riot shield. Must be set here,
    // in main(), because clientscripts\mp\zombies\_zm_buildables::init() (called
    // from _zm.csc:60) does `level.buildable_piece_count = 0` and THEN
    // `[[ level.init_buildables ]]()`. This .csc's main() runs before _zm.csc's
    // init list - the same ordering Who's Who relies on - so the pointer is in
    // place when that call comes, and our count is set after the reset, not
    // before it. See the server twin in zm_transit.gsc.
    zmqol_diner_shield_init();

    if (is_not_busdepot())
	{
	   return;
	}

    replaceFunc(clientscripts\mp\zm_transit::include_weapons, ::include_weapons);
}

// ============================================================================
//  zm_qol: DINER BUILDABLE RIOT SHIELD - client half.  EXACT TWIN of
//  scripts\zm\zm_transit\zm_transit.gsc::zmqol_diner_shield_init().
//
//  🛑 THE GATE MUST MATCH THE SERVER'S CHARACTER FOR CHARACTER. Both sides read
//  only replicated route dvars, so a remote client cannot disagree with the server.
//  If they ever did, the two
//  clientfield sets would differ in width and every player is dropped at load
//  with EXE_CLIENT_FIELD_MISMATCH.
//
//  zgrief is excluded because this mod's own include_weapons() below already
//  excludes riotshield_zm there (stock's gate, kept), so in grief the buildable
//  would assemble a weapon the level does not carry.
//
//  WHAT GETS REGISTERED. The first add_zombie_buildable() triggers
//  register_clientfields(), which is
//      registerclientfield( "toplayer", "buildable", 1,
//                           getminbitcountfornum( level.buildable_piece_count ), "int" )
//  on BOTH sides. 27 is stock TranZit's own number (zm_transit_buildables.gsc:12
//  and zm_transit_buildables.csc:7), so this is 5 bits - identical to what
//  classic TranZit already registers, and parity rather than a number of our
//  own choosing. Diner survival measured 54 toplayer in the v1.63.1 dump, so
//  54 -> 59 with room to spare.
// ============================================================================
zmqol_diner_shield_enabled()
{
	return getdvar( "ui_zm_mapstartlocation" ) == "diner" && getdvar( "ui_gametype" ) != "zgrief";
}

zmqol_diner_shield_init()
{
	if ( !zmqol_diner_shield_enabled() )
		return;

	level.init_buildables = ::zmqol_diner_init_buildables;
}

zmqol_diner_init_buildables()
{
	// include first: add_zombie_buildable() returns immediately if
	// level.zombie_include_buildables[name] is undefined (_zm_buildables.csc:19).
	clientscripts\mp\zombies\_zm_buildables::include_zombie_buildable( "riotshield_zm" );
	level.buildable_piece_count = 27;
	clientscripts\mp\zombies\_zm_buildables::add_zombie_buildable( "riotshield_zm" );
	level thread clientscripts\mp\zombies\_zm_buildables::set_clientfield_buildables_code_callbacks();
}

is_not_busdepot()
{
	return !getdvar("ui_gametype") == "zclassic" && getdvar("mapname") == "zm_transit" && getdvar("ui_zm_mapstartlocation") == "transit";
}

include_weapons()
{
    gametype = getdvar( #"ui_gametype" );
    include_weapon( "knife_zm", 0 );
    include_weapon( "frag_grenade_zm", 0 );
    include_weapon( "claymore_zm", 0 );
    include_weapon( "sticky_grenade_zm", 0 );
    include_weapon( "m1911_zm", 0 );
    include_weapon( "m1911_upgraded_zm", 0 );
    include_weapon( "python_zm" );
    include_weapon( "python_upgraded_zm", 0 );
    include_weapon( "judge_zm" );
    include_weapon( "judge_upgraded_zm", 0 );
    include_weapon( "kard_zm", 0 ); //
    include_weapon( "kard_upgraded_zm", 0 );
    include_weapon( "fiveseven_zm" );
    include_weapon( "fiveseven_upgraded_zm", 0 );
    include_weapon( "beretta93r_zm", 0 );
    include_weapon( "beretta93r_upgraded_zm", 0 );
    include_weapon( "fivesevendw_zm" );
    include_weapon( "fivesevendw_upgraded_zm", 0 );
    include_weapon( "ak74u_zm", 0 );
    include_weapon( "ak74u_upgraded_zm", 0 );
    include_weapon( "mp5k_zm", 0 );
    include_weapon( "mp5k_upgraded_zm", 0 );
    include_weapon( "qcw05_zm", 0 ); //
    include_weapon( "qcw05_upgraded_zm", 0 );
    include_weapon( "870mcs_zm", 0 );
    include_weapon( "870mcs_upgraded_zm", 0 );
    include_weapon( "rottweil72_zm", 0 );
    include_weapon( "rottweil72_upgraded_zm", 0 );
    include_weapon( "saiga12_zm", 0 ); //
    include_weapon( "saiga12_upgraded_zm", 0 );
    include_weapon( "srm1216_zm", 0 ); //
    include_weapon( "srm1216_upgraded_zm", 0 );
    include_weapon( "m14_zm", 0 );
    include_weapon( "m14_upgraded_zm", 0 );
    include_weapon( "saritch_zm", 0 ); //
    include_weapon( "saritch_upgraded_zm", 0 );
    include_weapon( "m16_zm", 0 );
    include_weapon( "m16_gl_upgraded_zm", 0 );
    include_weapon( "xm8_zm" );
    include_weapon( "xm8_upgraded_zm", 0 );
    include_weapon( "type95_zm" );
    include_weapon( "type95_upgraded_zm", 0 );
    include_weapon( "tar21_zm" );
    include_weapon( "tar21_upgraded_zm", 0 );
    include_weapon( "galil_zm" );
    include_weapon( "galil_upgraded_zm", 0 );
    include_weapon( "fnfal_zm" );
    include_weapon( "fnfal_upgraded_zm", 0 );
    include_weapon( "dsr50_zm" );
    include_weapon( "dsr50_upgraded_zm", 0 );
    include_weapon( "barretm82_zm", 0 ); //
    include_weapon( "barretm82_upgraded_zm", 0 );
    include_weapon( "rpd_zm" );
    include_weapon( "rpd_upgraded_zm", 0 );
    include_weapon( "hamr_zm" );
    include_weapon( "hamr_upgraded_zm", 0 );
    include_weapon( "usrpg_zm" );
    include_weapon( "usrpg_upgraded_zm", 0 );
    include_weapon( "m32_zm", 0 ); //
    include_weapon( "m32_upgraded_zm", 0 );
    include_weapon( "cymbal_monkey_zm" );
    include_weapon( "emp_grenade_zm", 0 );
    // Added weapons
    include_weapon( "beretta93r_extclip_zm", 0 );
    include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
    include_weapon( "ak74u_extclip_zm", 0 );
    include_weapon( "ak74u_extclip_upgraded_zm", 0 );
    include_weapon( "uzi_zm" );
    include_weapon( "uzi_upgraded_zm", 0 );
    include_weapon( "thompson_zm" );
    include_weapon( "thompson_upgraded_zm", 0 );
    include_weapon( "ak47_zm" );
    include_weapon( "ak47_upgraded_zm", 0 );
    include_weapon( "mp40_stalker_zm" );
    include_weapon( "mp40_stalker_upgraded_zm", 0 );
    include_weapon( "scar_zm" );
    include_weapon( "scar_upgraded_zm", 0 );
    include_weapon( "mg08_zm" );
    include_weapon( "mg08_upgraded_zm", 0 );
    include_weapon( "minigun_alcatraz_zm" );
    include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
    include_weapon( "evoskorpion_zm" );
    include_weapon( "evoskorpion_upgraded_zm", 0 );
    include_weapon( "hk416_zm" );
    include_weapon( "hk416_upgraded_zm", 0 );
    include_weapon( "ksg_zm" );
    include_weapon( "ksg_upgraded_zm", 0 );
    include_weapon( "pdw57_zm" );
    include_weapon( "pdw57_upgraded_zm", 0 );
    include_weapon( "mp44_zm" );
    include_weapon( "mp44_upgraded_zm", 0 );
    include_weapon( "ballista_zm" );
    include_weapon( "ballista_upgraded_zm", 0 );
    include_weapon( "rnma_zm" );
    include_weapon( "rnma_upgraded_zm", 0 );
    include_weapon( "an94_zm" );
    include_weapon( "an94_upgraded_zm", 0 );
    include_weapon( "svu_zm" );
    include_weapon( "svu_upgraded_zm", 0 );
    include_weapon( "lsat_zm" );
    include_weapon( "lsat_upgraded_zm", 0);
    include_weapon( "c96_zm" );
    include_weapon( "c96_upgraded_zm", 0);

    if ( gametype != "zgrief" )
    {
        include_weapon( "ray_gun_zm" );
        include_weapon( "ray_gun_upgraded_zm", 0 );
        include_weapon( "jetgun_zm", 0 );
        include_weapon( "riotshield_zm", 0 );
        include_weapon( "knife_ballistic_zm", 0 ); //
        include_weapon( "knife_ballistic_upgraded_zm", 0 );
        include_weapon( "knife_ballistic_bowie_zm", 0 );
        include_weapon( "knife_ballistic_bowie_upgraded_zm", 0 );

        if ( is_true( level.raygun2_included ) && !isdemoplaying() )
        {
            include_weapon( "raygun_mark2_zm", hasdlcavailable( "dlc3" ) );
            include_weapon( "raygun_mark2_upgraded_zm", 0 );
        }
    }
}
