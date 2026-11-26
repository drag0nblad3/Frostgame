class_name TerrainKind
extends RefCounted
## One kind of terrain piece (data/terrain.json).

enum Cover { NONE, LIGHT, HEAVY }

var id := ""
var name := ""
var blocks_los := false
var blocks_move := false
var cover: int = Cover.NONE
## Movement through the piece costs this many inches per inch (rough = 2).
var move_mult := 1.0
## Model height in inches (view only until elevation rules exist).
var height := 1.0
var walkable_top := false
var stairs := false
var ground_surface := false


static func from_dict(kind_id: String, d: Dictionary) -> TerrainKind:
	var k := TerrainKind.new()
	k.id = kind_id
	k.name = d.get("name", kind_id)
	k.blocks_los = d.get("blocks_los", false)
	k.blocks_move = d.get("blocks_move", false)
	k.cover = int(d.get("cover", 0))
	k.move_mult = float(d.get("move_mult", 1))
	k.height = float(d.get("height", 1))
	k.walkable_top = d.get("walkable_top", false)
	k.stairs = d.get("stairs", false)
	k.ground_surface = d.get("ground_surface", false)
	return k
