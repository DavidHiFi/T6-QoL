#include clientscripts\mp\zombies\_zm_weapons;

init()
{
	// MUST match the server gate in teslagun.gsc (tomb/prison were server-gated but
	// never client-gated — fixed for consistency).
	// MUST stay identical to the gate in teslagun.gsc -- see the reasoning there. zm_prison
	// removed 2026-08-02; Buried and Origins stay off permanently (bit/clientfield ceiling).
	if (getdvar("mapname") == "zm_tomb" || getdvar("mapname") == "zm_buried") return;
	include_weapon("tesla_gun_zm");
	
	clientscripts\mp\zombies\_zm_weap_tesla::init();
}
