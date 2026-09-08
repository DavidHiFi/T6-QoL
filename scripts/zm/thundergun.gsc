#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

init()
{
    // ============================================================
    //  zm_qol BISECT GATE - zmqol_ww          (v1.69.3)
    //  0 = all three OFF (DEFAULT - the mod loads normally)
    //  1 = all three ON    2 = thundergun    3 = tesla    4 = freeze
    //  Three boots crashed at the SAME point with no script error, so
    //  the cause is now narrowed by elimination, not by more guessing.
    //  MUST stay identical to the twin file.
    // ============================================================
    // getdvar, NOT getdvarintdefault: that one lives in mapsmp_utility, which
    // these scripts do not include, and using it here threw
    //     Unresolved external: "getdvarintdefault" with 2 parameters
    // getdvar is a true engine builtin and needs no include. Unset returns "",
    // which PASSES the gate below, so the default is ON.
    str_ww = getdvar( "zmqol_ww" );
    // DEFAULT IS ON: unset gives "", the first test fails, and the gate falls
    // through into the weapon code. Set zmqol_ww to any other value to turn the
    // guns off for a bisect ("1" = all guns on, this gun's own number = only it).
    // (An old v1.69.8 comment here claimed default-off - wrong: "" skips the
    // return. Until v1.69.7 the gate was also shadowed by Plutonium's loose
    // scripts folder, so every early "guns off" test was really guns-on.)
    if ( str_ww != "" && str_ww != "1" && str_ww != "2" )
        return;

    // Pulled from Buried/Origins alongside the freeze gun (custom wonder-weapon FX
    // not yet fully compiled into mod.ff). Gate matches thundergun.csc.
    if (getdvar("mapname") == "zm_buried" || getdvar("mapname") == "zm_tomb") return;
    precachestring(&"ZOMBIE_WEAPON_THUNDERGUN"); // wallbuy hint

    precacheitem("thundergun_zm");
    precacheitem("thundergun_upgraded_zm");

    include_weapon("thundergun_zm");
    add_limited_weapon("thundergun_zm", 1); // 1 player can get it (for box)
    add_zombie_weapon("thundergun_zm", "thundergun_upgraded_zm", &"ZOMBIE_WEAPON_THUNDERGUN", 10, "thunder", "", undefined );

    maps\mp\zombies\_zm_weap_thundergun::init();
}

// ============================================================================
//  THE ZOMBIE SCREAM ON EVERY THUNDERGUN SHOT - REMOVED IN v2.15.1
// ----------------------------------------------------------------------------
//  User, 2026-09-09: *"sometimes when i shoot the thundergun with my mod,
//  theres a sound of a zombie screaming, make sure its just the weapons sounds
//  no weird stuff like that"*.
//
//  IT WAS THIS MOD'S OWN ALIAS, NOT STOCK BO2 AND NOT AN ENGINE ODDITY.
//  Stock's _zm_weap_thundergun::thundergun_knockdown_zombie() calls
//      playsoundatposition( "vox_thundergun_forcehit", self.origin )
//  on every zombie it knocks down (gsc-dump ZM\Core\...\_zm_weap_thundergun.gsc
//  line 295). 🌟 BO2 SHIPS NO SUCH ALIAS - checked against all eight per-map
//  alias sets in zm_qol - dev\parsed\sound_alias_universe\: absent from every
//  one, and absent from zm_union.txt. So in retail zombies that call resolves
//  to nothing and is silent.
//
//  The wonder-weapon port added the alias to mod.all and pointed it at
//      raw\sound\vox\zmb\standard\elec\elec_00.wav
//  - the zombie ELECTROCUTION vocal, one fixed take. That is the scream, and
//  the mod was its only source. The row is deleted from
//  soundbank\mod.all.aliases.additions.csv; nothing else in this mod or in the
//  2,093-file stock dump references the name (grep'd), so the call goes back to
//  being the silent no-op it is in retail.
//
//  📝 FOR THE RECORD, IT IS NOT AN INVENTED SOUND - it just was not this gun's
//  ONLY sound. Black Ops 1 really does scream here: its own
//  raw\soundaliases\wpn_special.csv gives vox_thundergun_forcehit THREE rows,
//  vox\zmb\standard\{elec,sprint,crawl}, each a folder the engine picks a
//  random take from (elec alone holds elec_00..05). The port shipped one row
//  and one take, so instead of BO1's varied crowd noise it replayed the same
//  electrocution cry - which is what made it read as a stray sound.
//  🛑 TO RESTORE IT PROPERLY (not just re-add the old row): ship all three
//  sets, one CSV row per take, from BO1's raw\sound\vox\zmb\standard\.
// ============================================================================
