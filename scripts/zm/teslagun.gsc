#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;


init()
{
    // Buried and Origins stay off permanently -- those two are at the engine's bit/clientfield
    // ceiling and adding anything more crashes them. Everything else gets all three guns.
    //
    // zm_prison REMOVED from this gate 2026-08-02. It was excluded in SRS 1.0 back when the
    // wonder-weapon fx were not reaching the client at all; build.bat now packs fx/ into mod.iwd
    // (BUILD RULE 1 -- the Linker cannot bake FxEffectDef, so the iwd is the only route), which is
    // what SRS 1.0's own build.bat names as the fix for the guns firing with no VFX. Neither this
    // script nor _zm_weap_tesla registers a clientfield, so it adds no bit pressure to MotD.
    // MUST stay identical to the gate in teslagun.csc -- a server/client mismatch here is the
    // InitGame -> ShutdownGame-at-0:00 failure with a completely clean log.
    if(getdvar(#"mapname") == "zm_tomb" || getdvar(#"mapname") == "zm_buried") return;
    precachestring(&"ZOMBIE_WEAPON_TESLA"); // wallbuy hint

    precacheitem("tesla_gun_zm");
    precacheitem("tesla_gun_upgraded_zm");

    include_weapon("tesla_gun_zm");
    add_limited_weapon("tesla_gun_zm", 1); // 1 player can get it (for box)
    add_zombie_weapon("tesla_gun_zm", "tesla_gun_upgraded_zm", &"ZOMBIE_WEAPON_TESLA", 10, "tesla", "", undefined );

    maps\mp\zombies\_zm_weap_tesla::init();
}
