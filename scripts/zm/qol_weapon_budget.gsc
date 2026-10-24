// Called at the original PSR position in zmqol_mp_weapons_init(), after
// its MP-weapons gate and pap_attach_qol table setup, inside the precache window.
// Five charge stages in each tier cost ten variant names.
// The client box list in zm_expanded.csc uses the same mapname gate.
register_psr()
{
    map = getdvar( "mapname" );
    if ( map == "zm_prison" || map == "zm_tomb" )
    {
        println( "[zm_qol] weapon budget: Storm PSR held back on " + map );
        return;
    }

    scripts\zm\quality_of_life::zmqol_add_mp_weapon( "metalstorm_mms_zm", "metalstorm_mms_upgraded_zm", &"WEAPON_METALSTORM", 1000, "sniper" );
    scripts\zm\quality_of_life::zmqol_include_variant( "metalstorm2_mms_zm" );
    scripts\zm\quality_of_life::zmqol_include_variant( "metalstorm3_mms_zm" );
    scripts\zm\quality_of_life::zmqol_include_variant( "metalstorm4_mms_zm" );
    scripts\zm\quality_of_life::zmqol_include_variant( "metalstorm5_mms_zm" );
    scripts\zm\quality_of_life::zmqol_include_variant( "metalstorm2_mms_upgraded_zm" );
    scripts\zm\quality_of_life::zmqol_include_variant( "metalstorm3_mms_upgraded_zm" );
    scripts\zm\quality_of_life::zmqol_include_variant( "metalstorm4_mms_upgraded_zm" );
    scripts\zm\quality_of_life::zmqol_include_variant( "metalstorm5_mms_upgraded_zm" );
    println( "[zm_qol] weapon budget: Storm PSR registered on " + map );
}
