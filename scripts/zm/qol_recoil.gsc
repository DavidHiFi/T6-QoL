#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;

// ============================================================================
//  PRE-NERF RECOIL TOGGLE - user request 2026-09-15, the GAME 3 tab.
//
//  WHAT THE MOD ALREADY DOES, so the row is understood before it is read:
//  zm_qol ships Treyarch's LAUNCH-DAY copies of eight gun families - barretm82,
//  dsr50, fiveseven, hamr, rpd, tar21, type95, xm8, base and Pack-a-Punched.
//  They sit loose in weapons\ and weapons\zm\, which overrides the map
//  fastfile's post-patch copy of the same asset name. That is the whole of the
//  "pre-nerf recoil" feature: no script, just the defs. See commit 8974af8.
//
//  🛑 WHY THIS IS NOT A LIVE DVAR READ, unlike every other row in the mod.
//  Recoil is read out of the weapon def when the map loads and is never looked
//  at again. There is no dvar for it - all 2,758 entries of the BO2 dvar
//  reference were searched and nothing matches recoil / viewkick / gunkick /
//  kickscale - and no script function sets it, confirmed across the whole stock
//  script tree (maps, clientscripts, animscripts, codescripts: zero hits for
//  setviewkick / setweaponstat / kickscale). A dvar row alone would be a dead
//  switch, which is exactly why the feature was refused in v1.99.95.
//
//  🌟 SO IT IS DONE THE WAY PACK-A-PUNCH IS DONE: ship both versions of the gun
//  under different names and hand the player whichever the row asks for. Each
//  "_tu" twin in weapons\zm\ is the mod's OWN def with only the recoil fields
//  written over from Treyarch's post-patch values, so the twin keeps this mod's
//  camo, hud icons, attachments and ammo. The seven fields, measured by
//  diffing against zm_transit_patch.ff and cross-checked against zm_buried.ff
//  (18 defs, zero disagreement): adsSpread, adsViewKickPitchMin/Max,
//  adsViewKickYawMin/Max, adsViewKickCenterSpeed, hipViewKickCenterSpeed
//  ( plus hipSpreadStandMin/Max on one gun ).
//
//  🛑 DEFAULT 1 = PRE-NERF = EXACTLY WHAT THE MOD SHIPS TODAY. init() returns
//  before it touches a single thing when the row is left alone, so a player who
//  never opens the menu runs byte-for-byte the mod they ran yesterday: no
//  precaches, no table writes, no threads. Every cost in this file is opt-in.
//
//  🛑 THE HONEST LIMIT, stated rather than buried: precacheitem() only works
//  during level init, so the twins can only exist on a map that started with
//  the row already off. Flipping the row mid-match therefore takes effect on
//  the NEXT map load, and the row's description says so.
// ============================================================================

//  The pairs this file can substitute. Left = what the mod ships (launch-day
//  recoil), right = its post-patch twin in weapons\zm\.
//
//  📝 NOT LISTED, and deliberately: gl_tar21_zm, gl_type95_zm, gl_xm8_zm,
//  fivesevenlh_upgraded_zm and fivesevendw_upgraded_zm already carry Treyarch's
//  POST-patch values in the copies this mod ships - measured, not assumed - so
//  they were never pre-nerfed and have nothing to switch to.
zmqol_recoil_pairs()
{
    a = [];
    a[ "barretm82_zm" ]              = "barretm82_tu_zm";
    a[ "barretm82_upgraded_zm" ]     = "barretm82_upgraded_tu_zm";
    a[ "barretm82qol_zm" ]           = "barretm82qol_tu_zm";
    a[ "barretm82qol_upgraded_zm" ]  = "barretm82qol_upgraded_tu_zm";
    a[ "dsr50_zm" ]                  = "dsr50_tu_zm";
    a[ "dsr50_upgraded_zm" ]         = "dsr50_upgraded_tu_zm";
    a[ "fiveseven_zm" ]              = "fiveseven_tu_zm";
    a[ "fiveseven_upgraded_zm" ]     = "fiveseven_upgraded_tu_zm";
    a[ "hamr_zm" ]                   = "hamr_tu_zm";
    a[ "hamr_upgraded_zm" ]          = "hamr_upgraded_tu_zm";
    a[ "rpd_zm" ]                    = "rpd_tu_zm";
    a[ "rpd_upgraded_zm" ]           = "rpd_upgraded_tu_zm";
    a[ "tar21_zm" ]                  = "tar21_tu_zm";
    a[ "tar21_upgraded_zm" ]         = "tar21_upgraded_tu_zm";
    a[ "tar21qol_zm" ]               = "tar21qol_tu_zm";
    a[ "tar21qol_upgraded_zm" ]      = "tar21qol_upgraded_tu_zm";
    a[ "type95_zm" ]                 = "type95_tu_zm";
    a[ "type95_upgraded_zm" ]        = "type95_upgraded_tu_zm";
    a[ "xm8_zm" ]                    = "xm8_tu_zm";
    a[ "xm8_upgraded_zm" ]           = "xm8_upgraded_tu_zm";
    return a;
}

//  ============================================================================
//  🛑 DISABLED IN CODE, 2026-09-15, AND THE REASON IS MEASURED, NOT GUESSED.
//
//  Turning the row off crashed the game on every map load. TWO crashes, both
//  deterministic, both ending on the same weapon, the second with no file
//  changes of any kind during the run:
//
//    Exception Code: 0xC0000005
//    last gsc error message 'unknown weapon titus6_explosive_dart_upgraded_zm'
//    gsc callstack: quality_of_life::zmqol_include_variant
//                   quality_of_life::zmqol_mp_weapons_init
//
//  🌟 THIS MOD IS ALREADY AT THE ENGINE'S WEAPON-ASSET CEILING. The twenty
//  twins precached below are twenty assets this mod has no room for, and the
//  pool runs out partway through zmqol_mp_weapons_init(). The gun it dies on -
//  titus6_explosive_dart_upgraded_zm - is NOT one of ours and is NOT the cause:
//  it is simply whatever was being registered when the pool ran dry. Exactly
//  the same trap as the quality_of_life.gsc bytecode ceiling, where the named
//  symbol is never the culprit. Do not go and "fix" the Titus.
//
//  So the whole "ship both and swap" design is sound in every respect except
//  the one that matters here: it needs +20 weapon slots, and there are none.
//  Making it work needs slots FREED, or the recoil files chosen before the
//  game starts (installer/Optionals), not a bigger weapon list.
//
//  The early return below is deliberate and must stay until that is solved.
//  Everything under it is kept, working and reviewed, for whoever picks it up.
//  ============================================================================
init()
{
    //  🛑 HARD OFF. Not a dvar read - the archived dvar is exactly what put a
    //  player into a crash loop, because prenerf_recoil=0 persists across
    //  launches and every subsequent map load died. Nothing below runs.
    return;

    //  Everything past here is unreachable by design. It is kept rather than
    //  deleted because it is complete and reviewed, and the only thing wrong
    //  with it is that the weapon pool has no room - see the banner above.
    if ( getdvarintdefault( "prenerf_recoil", 1 ) )
        return;

    //  🛑 ORIGINS IS HELD BACK, ON PURPOSE. zm_tomb is already against an asset
    //  ceiling: zm_tomb.gsc:1557 had to free FOURTEEN slots against a ten-slot
    //  overage to make the Crazy Place load at all, and it paid for them by
    //  dropping seven guns from that location's box. Twenty more precaches is
    //  exactly the shape of change that turns a map which loads today into one
    //  that does not. Origins therefore keeps launch-day recoil whatever this
    //  row says, and the row's description says so rather than lying about it.
    //  📝 This is a held position, not a measured one - the honest way to lift
    //  it is to measure Origins' real headroom, not to assume it has some.
    if ( isdefined( level.script ) && level.script == "zm_tomb" )
        return;

    //  🛑 PRECACHE HERE, REGISTER LATER, AND THE SPLIT IS NOT OPTIONAL.
    //  precacheitem() only works before the first frame, but the tables this
    //  feature reads - level.zombie_weapons, level.zombie_include_weapons - are
    //  filled by the map's own added_weapons() which has not necessarily run
    //  when this mod's main() does. So the twins are precached unconditionally
    //  here, and which of them are actually usable is worked out afterwards by
    //  zmqol_recoil_late_register(), once the map has finished registering.
    pairs = zmqol_recoil_pairs();
    foreach ( base, twin in pairs )
        precacheitem( twin );

    level thread zmqol_recoil_late_register();
}

//  Runs after the map has registered its weapons, which is the first moment
//  level.zombie_weapons can be trusted. Waiting on the blackscreen flag is the
//  same point the mod's other late work uses, and it is far past registration.
zmqol_recoil_late_register()
{
    flag_wait( "initial_blackscreen_passed" );

    //  🛑 EVERY PAIR IS LIVE, NOT JUST THE ONES IN THIS MAP'S BOX. An earlier
    //  cut gated this on level.zombie_weapons[base] being registered, which
    //  looked tidy and was wrong: all twenty twins are precached above, and a
    //  gun can reach the player without ever being a box entry on this map -
    //  the mod's own .give command is the obvious one, and Town is exactly the
    //  survival map where a family like the Type 25 may not be registered at
    //  all. Gating the swap on box registration made the row silently do
    //  nothing for those guns. The PaP clone below is still gated, because
    //  THAT genuinely needs a base registration to copy.
    level.zmqol_recoil_swap = zmqol_recoil_pairs();

    zmqol_recoil_register();
    level thread zmqol_recoil_onplayerconnect();
}

//  ADDITIVE ONLY. Nothing that already exists is removed or rewritten - the
//  twins are added ALONGSIDE the stock entries. That matters twice over:
//  level.zombie_include_weapons is left alone, so no twin can ever come out of
//  the mystery box as its own result; and every stock lookup for the original
//  name keeps working exactly as before for anyone who never turns this on.
zmqol_recoil_register()
{
    foreach ( base, twin in level.zmqol_recoil_swap )
    {
        if ( !isdefined( level.zombie_weapons ) || !isdefined( level.zombie_weapons[ base ] ) )
            continue;

        struct = level.zombie_weapons[ base ];

        //  🛑 A FRESH STRUCT, NOT A REFERENCE. Structs are handles in GSC:
        //  assigning level.zombie_weapons[twin] = struct and then writing
        //  .upgrade_name would rewrite the BASE gun's registration as well and
        //  send every stock Pack-a-Punch to a twin. The fields copied here are
        //  exactly the ones add_zombie_weapon() sets (_zm_weapons.gsc:568-583)
        //  plus the default_attachment that add_attachments() may add at :611.
        twin_struct = spawnstruct();
        twin_struct.weapon_name      = twin;
        twin_struct.weapon_classname = "weapon_" + twin;
        twin_struct.hint             = struct.hint;
        twin_struct.cost             = struct.cost;
        twin_struct.vox              = struct.vox;
        twin_struct.vox_response     = struct.vox_response;
        twin_struct.ammo_cost        = struct.ammo_cost;

        //  Never a box result in its own right. The box reads
        //  level.zombie_include_weapons, which this file never writes, and this
        //  keeps the struct's own answer consistent with that.
        twin_struct.is_in_box = 0;

        if ( isdefined( struct.default_attachment ) )
            twin_struct.default_attachment = struct.default_attachment;

        //  Point the twin's upgrade at the TWIN'S upgraded form, not the stock
        //  one - otherwise Pack-a-Punching a post-patch gun hands back a
        //  launch-day gun and the row silently half-works.
        twin_struct.upgrade_name = struct.upgrade_name;

        if ( isdefined( struct.upgrade_name ) && isdefined( level.zmqol_recoil_swap[ struct.upgrade_name ] ) )
        {
            upgraded = level.zmqol_recoil_swap[ struct.upgrade_name ];
            twin_struct.upgrade_name = upgraded;

            //  is_weapon_upgraded() and get_base_weapon_name() are both table
            //  lookups against this array (_zm_weapons.gsc:1892, :1976), so
            //  registering here is what makes the twin read as "upgraded".
            //  Guarded: add_zombie_weapon() creates the array, but a map that
            //  registered nothing would leave it undefined and the write would
            //  throw rather than quietly do nothing.
            if ( !isdefined( level.zombie_weapons_upgraded ) )
                level.zombie_weapons_upgraded = [];

            level.zombie_weapons_upgraded[ upgraded ] = twin;
        }

        level.zombie_weapons[ twin ] = twin_struct;
    }
}

zmqol_recoil_onplayerconnect()
{
    //  🛑 THE ALREADY-CONNECTED PLAYERS FIRST. This thread starts after the
    //  blackscreen, by which point everyone in the game has long since fired
    //  "connected" - waiting only on the notify would cover nobody in a normal
    //  match and quietly leave the row doing nothing.
    foreach ( player in level.players )
        player thread zmqol_recoil_player_watch();

    for ( ;; )
    {
        level waittill( "connected", player );
        player thread zmqol_recoil_player_watch();
    }
}

//  Swaps on acquisition rather than on a timer tick the player can feel: the
//  poll is cheap, and a gun that has just come out of the box is being raised
//  anyway, so the re-equip reads as part of the pull.
zmqol_recoil_player_watch()
{
    self endon( "disconnect" );

    for ( ;; )
    {
        wait 0.5;

        if ( !isdefined( self ) || !isalive( self ) )
            continue;

        //  🛑 NOT WHILE DOWNED. In last stand the player is holding a pistol
        //  the game handed them and their real weapons are held aside; a
        //  take/give in that state is how you lose a gun for the rest of the
        //  match. The next tick after the revive picks it up anyway.
        if ( isdefined( self.laststand ) && self.laststand )
            continue;

        //  Re-read every tick. If the player turns the row back ON mid-match
        //  we stop substituting immediately; what they are already holding
        //  stays as it is until the next map, which the row's text says.
        if ( getdvarintdefault( "prenerf_recoil", 1 ) )
            continue;

        weapons = self getweaponslistprimaries();

        foreach ( weapon in weapons )
        {
            //  Attachment forms carry a "+" suffix and are a different asset
            //  again; leave them entirely alone rather than half-convert them.
            if ( issubstr( weapon, "+" ) )
                continue;

            if ( !isdefined( level.zmqol_recoil_swap[ weapon ] ) )
                continue;

            self zmqol_recoil_swap_weapon( weapon, level.zmqol_recoil_swap[ weapon ] );
        }
    }
}

zmqol_recoil_swap_weapon( from, to )
{
    if ( !self hasweapon( from ) || self hasweapon( to ) )
        return;

    clip  = self getweaponammoclip( from );
    stock = self getweaponammostock( from );
    b_in_hand = ( self getcurrentweapon() == from );

    self takeweapon( from );
    self giveweapon( to );

    //  Carry the ammo across rather than handing back a full gun - this is a
    //  substitution, not a refill, and a free top-up would be a real gameplay
    //  change hiding inside a recoil toggle.
    self setweaponammoclip( to, clip );
    self setweaponammostock( to, stock );

    if ( b_in_hand )
        self switchtoweapon( to );
}
