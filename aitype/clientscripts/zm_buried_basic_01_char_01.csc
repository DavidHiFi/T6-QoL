#include character\clientscripts\c_zom_zombie_buried_civilian1;

main()
{
    character\clientscripts\c_zom_zombie_buried_civilian1::main();
    self._aitype = "zm_buried_basic_01_char_01";
}

#using_animtree("zm_buried_basic");

precache( ai_index )
{
    // Electric Cherry stun (2026-09-28): the server twin's five dummy refs on
    // the list the client's own compiled aitype bakes. The client aitypes carry
    // no reference_anims_from_animtree() of their own - stock's are bare
    // dispatcher shells (see zm_transit_basic_01.csc 25-54, where the wave-gun
    // route's refs live in its precache()) - so the refs go at the top of THIS
    // precache block, ahead of the character precaches, exactly as the
    // transit/nuked/highrise overrides carry them.

    dummy_anim_ref = %ai_zombie_afterlife_stun_a;
    dummy_anim_ref = %ai_zombie_afterlife_stun_b;
    dummy_anim_ref = %ai_zombie_afterlife_stun_c;
    dummy_anim_ref = %ai_zombie_afterlife_stun_d;
    dummy_anim_ref = %ai_zombie_afterlife_stun_e;

    character\clientscripts\c_zom_zombie_buried_civilian1::precache();
    usefootsteptable( ai_index, "default_ai" );
    precacheanimstatedef( ai_index, #animtree, "zm_buried_basic" );
    setdemolockonvalues( ai_index, 100, 60, -15, 60, 30, -5, 60 );
}
