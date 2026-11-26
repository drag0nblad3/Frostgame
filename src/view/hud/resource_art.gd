class_name ResourceArt
extends RefCounted

const ICONS := {
	"kennel": preload("res://assets/glyphs/resource_kennel.svg"),
	"giant_cauldron": preload("res://assets/glyphs/resource_giant_cauldron.svg"),
	"enchanters_workshop": preload("res://assets/glyphs/resource_enchanters_workshop.svg"),
	"crystal_ball": preload("res://assets/glyphs/resource_crystal_ball.svg"),
	"scriptorium": preload("res://assets/glyphs/resource_scriptorium.svg"),
	"celestial_telescope": preload("res://assets/glyphs/resource_celestial_telescope.svg"),
	"summoning_circle": preload("res://assets/glyphs/resource_summoning_circle.svg"),
	"carrier_pigeons": preload("res://assets/glyphs/resource_carrier_pigeons.svg"),
	"arcane_candle": preload("res://assets/glyphs/resource_arcane_candle.svg"),
	"summoning_candle": preload("res://assets/glyphs/resource_summoning_candle.svg"),
	"sarcophagus_of_healing": preload("res://assets/glyphs/resource_sarcophagus_of_healing.svg")
}


static func icon(id: String) -> Texture2D:
	return ICONS.get(id,ActionArt.ICONS["items"])
