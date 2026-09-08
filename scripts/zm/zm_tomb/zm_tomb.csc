#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;
#include clientscripts\mp\zombies\_zm_weapons;
#include clientscripts\mp\zm_tomb;
#include clientscripts\mp\zombies\_zm;
#include clientscripts\mp\zm_tomb_classic;

//  The Crazy Place's built Pack-a-Punch (zmqol_cp_pap_client_model below) uses
//  the same tree stock's zm_tomb_capture_zones.csc uses for pap_cs. This is a
//  per-entity useanimtree() only - NO scriptmodelsuseanimtree() (the tree is
//  already registered on both sides by the map: zm_tomb.gsc:110 /
//  zm_tomb.csc:103), so the ordered list ERROR_CATALOGUE §4 is about is not
//  touched. This file loads on Origins only, where the tree exists.
#using_animtree( "fxanim_props_dlc4" );

main()
{
    replaceFunc(clientscripts\mp\zm_tomb::include_weapons, ::include_weapons);

    // --- Origins survival, The Crazy Place: client half. The server half is
    //     scripts\zm\replaced\zm_tomb_gamemodes.gsc, hooked from
    //     scripts\zm\zm_tomb\zm_tomb.gsc::main(). Ship the two together. ---
    replaceFunc(clientscripts\mp\zm_tomb::init_gamemodes, ::init_gamemodes);

    level thread zmqol_cp_pap_client_model();
}

// ============================================================================
//  zmqol_cp_pap_client_model  -  THE CRAZY PLACE'S PACK-A-PUNCH STANDS BUILT.
//                                                                   (v2.14.25)
// ----------------------------------------------------------------------------
//  The server half is scripts\zm\locs\zm_tomb_loc_crazy_place.gsc::
//  zmqol_cp_pap_built_pose(): it ghost()s the server's machine (collision
//  kept) and draws nothing. This is what draws the machine, and it is a copy
//  of how stock draws the SAME model on classic Origins:
//
//    * zm_tomb_capture_zones.csc::get_pack_a_punch_model() - the client-only
//      map entity "pap_cs": waittill_dobj, then if !hasanimtree():
//      useanimtree( #animtree ) + mapshaderconstant( lcn, 2, "ScriptVector0", 1 ).
//    * zm_tomb_capture_zones.csc::play_pap_anim() - on the initial snapshot
//      (bnewent / binitialsnap) every assembled piece is
//      setanim( anim, 1.0, 0.0, 0.0 ) + setanimtime( anim, 1.0 ): weight 1,
//      RATE 0, time 1.0 - a snap to the last frame that never plays and so
//      never ends. Six pieces, fxanim_zom_tomb_packapunch_pc1..pc6_anim, all
//      in zm_tomb.ff (Unlinker --list; pc7 is NOT in the fastfile).
//
//  Stock's pap_cs stands at the Excavation Site and cannot be moved from a
//  client script, so each local client spawns its OWN p6_zm_tm_packapunch
//  (precached by zm_tomb_capture_zones::precache_everything on every gametype,
//  and again by the location's precache()) at the chamber machine's exact
//  struct origin and angles - (10340, -7906, -412), (0, 0, 0), the same two
//  numbers scripts\zm\locs\zm_tomb_loc_crazy_place.gsc::struct_init() gives the
//  server struct; change one, change both. Client-spawned script_models
//  taking setmodel + anims is stock practice (_zm_magicbox_tomb.csc:100 for
//  the spawn, zm_prison_weap_quest.csc for spawn + setanim).
//
//  🛑 v2.14.23 tried the six anims on the SERVER machine at rate 1 and the
//  heap never changed (2:10 PM boot, 2026-09-08). Nothing in stock animates
//  this model server-side; this is the stock way.
//
//  Runs once per local client after waitforallclients(), as stock's
//  init_custom_pap() does. No clientfield: the pose never changes.
// ============================================================================
zmqol_cp_pap_client_model()
{
    if ( getdvar( "mapname" ) != "zm_tomb" || getdvar( "ui_zm_mapstartlocation" ) != "crazy_place" )
        return;

    waitforallclients();

    a_players = getlocalplayers();

    for ( localclientnum = 0; localclientnum < a_players.size; localclientnum++ )
        level thread zmqol_cp_pap_client_model_for( localclientnum );
}

zmqol_cp_pap_client_model_for( localclientnum )
{
    m_pap = spawn( localclientnum, ( 10340, -7906, -412 ), "script_model" );
    m_pap.angles = ( 0, 0, 0 );
    m_pap setmodel( "p6_zm_tm_packapunch" );
    m_pap waittill_dobj( localclientnum );

    if ( !m_pap hasanimtree() )
    {
        m_pap useanimtree( #animtree );
        m_pap mapshaderconstant( localclientnum, 2, "ScriptVector0", 1 );
    }

    a_anims = [];
    a_anims[0] = %fxanim_zom_tomb_packapunch_pc1_anim;
    a_anims[1] = %fxanim_zom_tomb_packapunch_pc2_anim;
    a_anims[2] = %fxanim_zom_tomb_packapunch_pc3_anim;
    a_anims[3] = %fxanim_zom_tomb_packapunch_pc4_anim;
    a_anims[4] = %fxanim_zom_tomb_packapunch_pc5_anim;
    a_anims[5] = %fxanim_zom_tomb_packapunch_pc6_anim;

    for ( i = 0; i < a_anims.size; i++ )
    {
        m_pap setanim( a_anims[i], 1.0, 0.0, 0.0 );
        m_pap setanimtime( a_anims[i], 1.0 );
    }

    if ( !isdefined( level.zmqol_cp_pap_client_models ) )
        level.zmqol_cp_pap_client_models = [];

    level.zmqol_cp_pap_client_models[localclientnum] = m_pap;

    println( "[zm_qol] CLIENT crazy place pap: built pose - own p6_zm_tm_packapunch spawned at (10340,-7906,-412) for local client " + localclientnum + ", 6 assembly anims snapped to their last frame (rate 0, time 1.0)" );

    //  v2.14.26 - MEASUREMENT for the machine's collision (server side,
    //  zm_tomb_loc_crazy_place.gsc::zmqol_cp_pap_collision): where each of the
    //  six moved pieces ends up in the built pose, relative to the machine.
    //  The bone names are the model's own (p6_zm_tm_packapunch dump: part1_jnt
    //  .. part6_jnt, roller_01..06_jnt). A frame later so the snap has applied.
    wait 0.1;

    a_tags = [];
    a_tags[0] = "part1_jnt";
    a_tags[1] = "part2_jnt";
    a_tags[2] = "part3_jnt";
    a_tags[3] = "part4_jnt";
    a_tags[4] = "part5_jnt";
    a_tags[5] = "part6_jnt";

    for ( i = 0; i < a_tags.size; i++ )
    {
        v_o = m_pap gettagorigin( a_tags[i] );
        v_a = m_pap gettagangles( a_tags[i] );

        if ( !isdefined( v_o ) || !isdefined( v_a ) )
        {
            println( "[zm_qol] CLIENT crazy place pap: piece " + a_tags[i] + " - tag not found" );
            continue;
        }

        v_rel = v_o - m_pap.origin;

        println( "[zm_qol] CLIENT crazy place pap: piece " + a_tags[i] + " built at rel (" + int( v_rel[0] ) + "," + int( v_rel[1] ) + "," + int( v_rel[2] ) + ") angles (" + int( v_a[0] ) + "," + int( v_a[1] ) + "," + int( v_a[2] ) + ")" );
    }
}

// ============================================================================
//  init_gamemodes  (CLIENT)
//
//  Same defect as zm_prison\zm_prison.csc - see the long comment there for the
//  mechanism and the _zm.csc line numbers.
//
//  Origins is worse than Mob of the Dead: stock
//  clientscripts\mp\zm_tomb::init_gamemodes registers ONLY zclassic, while
//  scripts\zm\replaced\zm_tomb_gamemodes.gsc adds zstandard AND zgrief on the
//  server (The Crazy Place, v2.14.0). With the client registering neither, its
//  start_zombie_gametype() bails, the loading state is never released, and the
//  map hangs on the loading screen instead of starting.
//
//  🛑 v2.14.4 - THE THREE LOCATION FUNCS ARE undefined, AND THAT IS MEASURED.
//  v2.14.3 pointed crazy_place at zm_tomb_classic's client funcs, copying what
//  already ships on Die Rise and Buried. Booting Origins survival on 2026-09-06
//  at 6:40 PM ended in EXE_CLIENT_FIELD_MISMATCH, and the game's own dump named
//  every field: 36 in set [world] (piece_quadrotor_*, piece_riotshield_*,
//  piece_staff_*, piece_record_*, staff_player1-4, quest_state1-4) plus
//  "craftable" in set [toplayer], all "not registered on the server".
//
//  WHY, from the dumps rather than from the names:
//    * clientscripts\mp\zm_tomb_classic.csc is NOTHING BUT craftables - its
//      precache() and main() are empty and premain() is two calls,
//      zm_tomb_craftables::include_craftables() and ::init_craftables(). The
//      second one calls register_clientfields(), which is those 36 world
//      fields; add_zombie_craftable() then makes _zm_craftables.csc register
//      "craftable" on [toplayer]. That is the whole 37.
//    * On the SERVER those same registrations live in
//      maps\mp\zm_tomb_craftables::init_craftables, and its only caller is
//      maps\mp\zm_tomb_classic.gsc - the zclassic location. The Crazy Place
//      runs scripts\zm\locs\zm_tomb_loc_crazy_place instead, which has no
//      craftables at all, so the server registers none of the 37.
//    * Die Rise is NOT the same case and its fix stays: there the survival
//      locations run stock scripts that DO include the buildables server-side,
//      so its client half has to run them too.
//
//  Working precedent: BO2-Reimagined's own client zm_tomb replacement
//  registers all four of its Origins survival arenas exactly this way -
//  add_map_location_gamemode( mode, loc, undefined, undefined, undefined ).
//
//  Registering the mode with add_map_gamemode is still REQUIRED and still does
//  the real work: _zm.csc::start_zombie_gametype returns early unless
//  level.gamemode_map_location_main[gamemode] is defined, and add_map_gamemode
//  is what sets it to []. The per-location entries are then undefined and every
//  call site is isdefined-guarded, so nothing runs client-side for this
//  location - which is exactly what the server does.
// ============================================================================
init_gamemodes()
{
    add_map_gamemode( "zclassic", undefined, undefined );
    add_map_gamemode( "zstandard", undefined, undefined );
    add_map_gamemode( "zgrief", undefined, undefined );

    add_map_location_gamemode( "zclassic", "tomb", clientscripts\mp\zm_tomb_classic::precache, clientscripts\mp\zm_tomb_classic::premain, clientscripts\mp\zm_tomb_classic::main );

    //  v2.14.4 - all three funcs undefined. See the banner above: pointing them
    //  at zm_tomb_classic is what produced EXE_CLIENT_FIELD_MISMATCH.
    add_map_location_gamemode( "zstandard", "crazy_place", undefined, undefined, undefined );
    add_map_location_gamemode( "zgrief", "crazy_place", undefined, undefined, undefined );
}

include_weapons()
{
    include_weapon( "hamr_zm" );
    include_weapon( "hamr_upgraded_zm", 0 );
    include_weapon( "mg08_zm" );
    include_weapon( "mg08_upgraded_zm", 0 );
    include_weapon( "type95_zm", 0 ); //
    include_weapon( "type95_upgraded_zm", 0 );
    include_weapon( "galil_zm" );
    include_weapon( "galil_upgraded_zm", 0 );
    include_weapon( "fnfal_zm", 0 ); //
    include_weapon( "fnfal_upgraded_zm", 0 );
    include_weapon( "m14_zm", 0 );
    include_weapon( "m14_upgraded_zm", 0 );
    include_weapon( "mp44_zm", 0 );
    include_weapon( "mp44_upgraded_zm", 0 );
    include_weapon( "scar_zm" );
    include_weapon( "scar_upgraded_zm", 0 );
    include_weapon( "870mcs_zm", 0 );
    include_weapon( "870mcs_upgraded_zm", 0 );
    include_weapon( "ksg_zm", 0 ); //
    include_weapon( "ksg_upgraded_zm", 0 );
    include_weapon( "srm1216_zm", 0  ); //
    include_weapon( "srm1216_upgraded_zm", 0 );
    include_weapon( "ak74u_zm", 0 );
    include_weapon( "ak74u_upgraded_zm", 0 );
    include_weapon( "ak74u_extclip_zm", 0 ); //
    include_weapon( "ak74u_extclip_upgraded_zm", 0 );
    include_weapon( "pdw57_zm", 0 ); //
    include_weapon( "pdw57_upgraded_zm", 0 );
    include_weapon( "thompson_zm" );
    include_weapon( "thompson_upgraded_zm", 0 );
    include_weapon( "qcw05_zm", 0 ); //
    include_weapon( "qcw05_upgraded_zm", 0 );
    include_weapon( "mp40_zm", 0 );
    include_weapon( "mp40_upgraded_zm", 0 );
    include_weapon( "mp40_stalker_zm" );
    include_weapon( "mp40_stalker_upgraded_zm", 0 );
    include_weapon( "evoskorpion_zm" );
    include_weapon( "evoskorpion_upgraded_zm", 0 );
    include_weapon( "ballista_zm", 0 );
    include_weapon( "ballista_upgraded_zm", 0 );
    include_weapon( "dsr50_zm", 0 ); //
    include_weapon( "dsr50_upgraded_zm", 0 );
    include_weapon( "beretta93r_zm", 0 );
    include_weapon( "beretta93r_upgraded_zm", 0 );
    include_weapon( "beretta93r_extclip_zm", 0 ); //
    include_weapon( "beretta93r_extclip_upgraded_zm", 0 );
    include_weapon( "kard_zm", 0 ); //
    include_weapon( "kard_upgraded_zm", 0 );
    include_weapon( "fiveseven_zm", 0 );
    include_weapon( "fiveseven_upgraded_zm", 0 );
    include_weapon( "python_zm", 0 ); //
    include_weapon( "python_upgraded_zm", 0 );
    include_weapon( "c96_zm", 0 );
    include_weapon( "c96_upgraded_zm", 0 );
    include_weapon( "fivesevendw_zm" );
    include_weapon( "fivesevendw_upgraded_zm", 0 );
    include_weapon( "m32_zm" );
    include_weapon( "m32_upgraded_zm", 0 );
    include_weapon( "beacon_zm", 0 );
    include_weapon( "tomb_shield_zm", 0 );
    include_weapon( "claymore_zm", 0 );
    include_weapon( "cymbal_monkey_zm" );
    include_weapon( "frag_grenade_zm", 0 );
    include_weapon( "knife_zm", 0 );
    include_weapon( "ray_gun_zm" );
    include_weapon( "ray_gun_upgraded_zm", 0 );
    include_weapon( "sticky_grenade_zm", 0 );
    include_weapon( "staff_air_zm", 0 );
    include_weapon( "staff_air_upgraded_zm", 0 );
    include_weapon( "staff_fire_zm", 0 );
    include_weapon( "staff_fire_upgraded_zm", 0 );
    include_weapon( "staff_lightning_zm", 0 );
    include_weapon( "staff_lightning_upgraded_zm", 0 );
    include_weapon( "staff_water_zm", 0 );
    include_weapon( "staff_water_zm_cheap", 0 );
    include_weapon( "staff_water_upgraded_zm", 0 );
    include_weapon( "staff_revive_zm", 0 );
    // ========================================================================
    //  🛑 v2.14.2 - EXACT TWIN OF zm_tomb.gsc::added_weapons()'s OWN SKIP.
    //  Read the long banner above that function for why the Crazy Place cannot
    //  afford these seven pairs (its four perk machines cost ten precacheitem
    //  calls stock's own _zm_perks::init() skips on every other Origins
    //  survival location, and v2.14.0 crashed at load because of it).
    //
    //  🛑 THIS HALF IS NOT BOOKKEEPING. include_weapon() here ends in
    //  addzombieboxweapon( weapon, getweaponmodel( weapon ), ... ) - a model
    //  lookup on a weapon the server never precached is the as50_zm client
    //  crash documented in zm_expanded.csc::zmqol_mp_weapons_init(). If the two
    //  lists ever disagree the map dies on the CLIENT instead of the server.
    //
    //  Same dvar test as the server's zmqol_loc_spawns_perk_machines(), and the
    //  same one zmqol_add_crazy_place_wallbuys() already uses client-side.
    //  📝 knife_ballistic_* is not in this list and never was - it is not a box
    //  weapon - so the server keeping it needs no twin here.
    // ========================================================================
    // Added weapons
    include_weapon( "uzi_zm" );
    include_weapon( "uzi_upgraded_zm", 0 );
    include_weapon( "ak47_zm" );
    include_weapon( "ak47_upgraded_zm", 0 );
    include_weapon( "minigun_alcatraz_zm" );
    include_weapon( "minigun_alcatraz_upgraded_zm", 0 );
    include_weapon( "hk416_zm" );
    include_weapon( "hk416_upgraded_zm", 0 );
    include_weapon( "rnma_zm" );
    include_weapon( "rnma_upgraded_zm", 0 );
    include_weapon( "an94_zm" ); 
    include_weapon( "an94_upgraded_zm", 0 );
    include_weapon( "lsat_zm" );
    include_weapon( "lsat_upgraded_zm", 0 );
    include_weapon( "svu_zm" );
    include_weapon( "svu_upgraded_zm", 0 );
    // Tranzit weapons
    include_weapon( "xm8_zm" );
    include_weapon( "xm8_upgraded_zm", 0 );
    include_weapon( "rpd_zm" );
    include_weapon( "rpd_upgraded_zm", 0 );
    //  🛑 v2.14.4 - THE SEVEN PAIRS ARE GONE ON ALL OF ORIGINS, not just
    //  the Crazy Place. Exact twin of the same removal in
    //  zm_tomb.gsc::added_weapons() - read the banner there for the classic
    //  Origins crash dump that forced it. The two lists must never disagree:
    //  include_weapon() here ends in addzombieboxweapon( w, getweaponmodel( w ),
    //  ... ), a model lookup on a weapon the server never precached, which is
    //  the as50_zm client crash in zm_expanded.csc::zmqol_mp_weapons_init().
    println( "[zm_qol] CLIENT origins: added weapons holds back 7 pair(s), matching the server (v2.14.4)" );

    //  🛑 OUTSIDE THE SKIP ON PURPOSE - twin of the same two pairs in
    //  zm_tomb.gsc::added_weapons(). The root script precaches and registers
    //  Origins' private M16 and Olympia on every location, so the client has to
    //  include them on every location too or the box cannot draw them. Read the
    //  banner beside them on the server for the full reason.
    include_weapon( "m16qol_zm" );
    include_weapon( "m16qol_upgraded_zm", 0 );
    include_weapon( "rottweil72qol_zm" );
    include_weapon( "rottweil72qol_upgraded_zm", 0 );
    include_weapon( "m1911_zm" );
    include_weapon( "m1911_upgraded_zm", 0);

    // ========================================================================
    //  v2.9.1 - THE THREE ORIGINS COPIES THAT ARE REGISTERED FROM A ROOT
    //  SCRIPT, so their client half cannot live where the other six do.
    //
    //  quality_of_life.gsc registers the XPR-50 through zmqol_add_mp_weapon()
    //  and the M16 / Olympia through zmqol_wallbuy_box_add(), both of which run
    //  on every map and swap in the private Origins copy via
    //  zmqol_tomb_weapon(). Their client twins in zm_expanded.csc cannot make
    //  that swap: level.script is never used by any stock .csc in the 618-file
    //  client dump, so there is no verified way to test the map client-side.
    //  This file only ever loads on Origins, so the includes simply go here.
    //
    //  📝 The twins in zm_expanded.csc still include the STOCK m16_zm /
    //  rottweil72_zm / as50_zm here as well. That is harmless: the server never
    //  registers those three on Origins, so they can never be a box result, and
    //  they name the SAME view models as the copies - so even the box's spin
    //  visual is identical.
    // ========================================================================
    //  🛑 ONLY the XPR-50 here. The M16 and the Olympia are already included
    //  above - this map's own list carries them - and include_weapon() twice
    //  for one name would be a duplicate, not a second entry.
    include_weapon( "as50qol_zm" );
    include_weapon( "as50qol_upgraded_zm", 0 );


    if ( is_true( level.raygun2_included ) && !isdemoplaying() )
    {
        include_weapon( "raygun_mark2_zm", hasdlcavailable( "dlc3" ) );
        include_weapon( "raygun_mark2_upgraded_zm", 0 );
    }
}