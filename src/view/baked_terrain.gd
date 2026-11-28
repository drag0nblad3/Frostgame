class_name BakedTerrain
extends RefCounted
## Immutable board-art bundles; exact geometry matching prevents stale terrain
## after scenario modifiers, checkpoint restoration or destruction.

const STATIC_KINDS := ["ruin","ruin_broken_wall","wall","rubble","platform","tower","hut_wall","null_annex","null_walk","null_lower","null_middle","null_upper","library_shelf","haunted_floor","temple_column","museum_statue","arcane_disc","dreams_well","library_gate","temple_gate","tent_canvas","alien_obelisk","alien_terrace","alien_rib"]


static func supports(piece: TerrainPiece) -> bool:
	return piece.cast_turn<0 and not piece.kind.ground_surface and piece.kind.id in STATIC_KINDS


static func path_for(board: Board,scenario: String) -> String:
	var signature: Array=[5,board.id,board.size,board.has_ground_profiles,board.void_regions]
	for p in board.pieces:
		signature.append([p.kind.id,p.kind.height,p.kind.ground_surface,p.kind.walkable_top,p.rect,p.circular,p.entrance,p.ramp,p.ramp_rotated,p.ramp_start,p.ramp_end,p.level,p.cast_turn])
	return BakedVisuals.DIR+"terrain/%s_%d_%s.scn"%[scenario,GraphicsQuality.mode(),str(signature).sha256_text()]


## Detach the requested art node, so normal BoardView ownership and removal
## semantics are unchanged. The node retains references to its mesh resources.
static func take(bundle: Node3D,child_name: String) -> Node3D:
	if bundle==null:
		return null
	var child := bundle.get_node_or_null(child_name) as Node3D
	if child!=null:
		bundle.remove_child(child)
		child.set_meta("baked_visual",true)
	return child
