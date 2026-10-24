// The Storm PSR has five charge stages in each tier: ten variant names.
// Mob and Origins overflow the native weapon registry with the full roster.
// Keep this policy outside quality_of_life.gsc's compiled-size ceiling.
// The client box list in zm_expanded.csc uses the same two-map gate.
psr_enabled()
{
    map = getdvar( "mapname" );
    return map != "zm_prison" && map != "zm_tomb";
}

add_psr( base, upgraded, hint, cost, vox )
{
    if ( psr_enabled() )
        scripts\zm\quality_of_life::zmqol_add_mp_weapon( base, upgraded, hint, cost, vox );
}

include_psr_variant( weapon )
{
    if ( psr_enabled() )
        scripts\zm\quality_of_life::zmqol_include_variant( weapon );
}
