class_name FieldGuide
extends RefCounted
## Concise original instructions for the current digital rules.

const OVERVIEW := """CAMERA
Drag to orbit. Pinch or use the mouse wheel to zoom. Drag with two fingers or the right mouse button to pan.

TURNS
Wizard, Apprentice, Soldier and Creature phases repeat. Select a highlighted friendly figure to activate it. Wizards and apprentices can bring nearby soldiers into their phase. The Group command performs movement first, then remaining actions.

ACTIONS
Most figures get two actions. At least one must be movement (or a permitted replacement such as reloading). A second move is half speed. Choose a command, then tap a highlighted target or destination. End finishes the activation.

COMBAT
Opposed d20 rolls determine who wins melee; excess attack total over Armour causes damage. Adjacent allies may support a fight. Shooting requires range and line of sight. A melee winner may stay or push back if legal.

SPELLS
Choose Cast, then a spell and target. Resolve the roll; empowerment spends available power first and then Health. Some spells allow the target to resist. Do not spend all your Health unless necessary.

TREASURE
Move beside a token and Collect when enemies are not too close. Carrying ordinary treasure slows the bearer. Use Exit on a legal table edge to secure it. The Library requires a doorway. Most secured treasure wins.

MORE INFORMATION
Inspect shows effective stats, equipment and status for any figure. Menu → Briefing explains the current scenario. The combat log records rolls and events. Save battle creates a local checkpoint."""
const TIPS := {
	"select": "Activate one of the highlighted figures; a caster can also activate nearby soldiers.",
	"move": "A second move is half speed. Enemy contact ends movement.",
	"fight": "Both fighters roll. The winner can hurt the loser and may push back.",
	"shoot": "A shot uses Shoot against the target's Fight and situational defence.",
	"collect": "Move next to treasure and keep enemies away. Ordinary treasure halves movement.",
	"exit": "Leave from a highlighted edge to secure carried loot.",
	"spell_menu": "Choose a spell; available targets are highlighted after selection.",
	"empower": "Power is spent before Health. Check the target number before confirming.",
	"resist": "Meet the casting result to resist. Some figures can spend power or Health.",
	"push": "A legal push breaks contact; useful for retreating with treasure.",
	"group_select": "The group makes its movement passes before second actions."
}


static func tip(mode: String) -> String:
	return str(TIPS.get(mode, ""))
