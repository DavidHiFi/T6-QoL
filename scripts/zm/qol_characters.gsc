// Optional character packs register slots 4-7 during init, before the first wait.
// The map still owns characterindex 0-3, voices, quests and team selection.
// This module changes only the body, viewhands and portrait slot.
#include maps\mp\_utility;

init()
{
    roster();
    level.qol_character_portrait = ::portrait_slot;
}

roster()
{
    if ( !isdefined( level.qol_characters ) )
        level.qol_characters = [];
}

register( slot, name, body, hands )
{
    roster();
    if ( slot < 4 || slot > 7 || isdefined( level.qol_characters[slot] ) )
        return;

    precachemodel( body );
    precachemodel( hands );
    character = spawnstruct();
    character.name = name;
    character.body = body;
    character.hands = hands;
    level.qol_characters[slot] = character;
}

available_pick( pick )
{
    if ( pick >= 0 && pick <= 4 )
        return true;
    if ( pick < 5 || pick > 8 )
        return false;
    roster();
    return isdefined( level.qol_characters[pick - 1] );
}

selection_help()
{
    roster();
    text = "^5.character 1-4 ^7to choose, ^5.character 0 ^7for default";
    for ( slot = 4; slot < 8; slot++ )
    {
        if ( isdefined( level.qol_characters[slot] ) )
            text += ", ^5" + ( slot + 1 ) + " ^7" + level.qol_characters[slot].name;
    }
    return text;
}

// Called by the existing per-player option watcher. True means this pack owns
// the appearance for this pass. No registration means an immediate no-op.
update( pick )
{
    roster();
    slot = -1;
    if ( pick >= 5 && pick <= 8 )
        slot = pick - 1;
    else if ( pick == 0 )
    {
        client = self getentitynumber();
        if ( client >= 4 && client <= 7 )
            slot = client;
    }

    if ( slot < 4 || !isdefined( level.qol_characters[slot] ) )
    {
        if ( isdefined( self.qol_character_slot ) )
        {
            self.qol_character_slot = undefined;
            self.favorite_wall_weapons_list = [];
            self [[ level.givecustomcharacters ]]();
        }
        return false;
    }

    if ( !isdefined( self.characterindex ) || ( isdefined( self.is_zombie ) && self.is_zombie ) )
        return false;

    character = level.qol_characters[slot];
    if ( !isdefined( self.qol_character_slot ) || self.qol_character_slot != slot || self.model != character.body || isdefined( self.zmqol_char_respawned ) )
    {
        self setmodel( character.body );
        self setviewmodel( character.hands );
        self.qol_character_slot = slot;
        self.zmqol_char_respawned = undefined;
    }
    return true;
}

// QolEightPlayerPoints calls this through level.qol_character_portrait.
// The UI pack table maps the slot to a linked material; -1 uses its faction.
portrait_slot()
{
    if ( isdefined( self.qol_character_slot ) && ( !isdefined( self.is_zombie ) || !self.is_zombie ) )
        return self.qol_character_slot;
    if ( isdefined( self.characterindex ) && self.characterindex >= 0 && self.characterindex < 4 )
        return self.characterindex;
    return -1;
}
