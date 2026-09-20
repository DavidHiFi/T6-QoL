#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

init()
{
    // Pulled from Buried/Origins alongside the freeze gun (custom wonder-weapon FX
    // not yet fully compiled into mod.ff). Map gate matches thundergun.csc.
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
