// ============================================================================
//  zmqol_dupguard.gsc  -  refuse duplicate perk grants
// ----------------------------------------------------------------------------
//  Stock's own trigger will not sell an owned perk, but free grants (EEs,
//  round rewards, wait_give_perk calls made outside any trigger) can land
//  while the perk is already held - and every effect in the override below
//  (burp exert, vox, blur, perks_active append, num_perks++) then stacks.
//  The stuck burp multi-fire of 2026-09-17 traced to exactly this shape: a
//  stock wait_give_perk grant with no trigger context re-firing the whole
//  bought branch on an already-held perk. Same skip the Wunderfizz already
//  does in givePerk() (hasPerk / has_perk_paused). A paused perk reads as
//  not-held, so power-off re-grants still pass through.
//
//  WHY IT LIVES HERE AND NOT IN quality_of_life.gsc: that file sits on a
//  compiled-bytecode ceiling (add code and unrelated functions fail to link
//  with Unresolved external at map load). This wrapper costs it NOTHING -
//  one replaceFunc line removed there, full behaviour preserved here.
//  Two replaceFuncs on one stock target cannot both take effect, so the one
//  in quality_of_life::main was removed; this is the single replacer and
//  there is no init-order race. The override body itself is untouched and
//  runs for every first grant exactly as before.
// ============================================================================

init()
{
    replaceFunc( maps\mp\zombies\_zm_perks::give_perk, ::zmqol_dupguard_give_perk );
}

zmqol_dupguard_give_perk( perk, bought )
{
    if ( self hasperk( perk ) )
    {
        println( "[zm_qol] give_perk: already holds " + perk + ", duplicate refused" );
        return;
    }

    self scripts\zm\quality_of_life::give_perk( perk, bought );
}
