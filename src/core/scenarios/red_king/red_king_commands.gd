class_name RedKingCommands
extends RefCounted
## Stable plain-data scenario commands. Existing scenario rules are authoritative.


static func execute(c: GameController,key: String,args: Dictionary) -> Variant:
	var target:=int(args.get("target",-1))
	var at: Variant=args.get("at")
	match key:
		"exchange": return RealityCracks.answer_exchange(c,target)
		"sinkhole": return RedKingSinkhole.answer_pull(c,str(args.get("choice","")))
		"veil": return RedKingVeil.answer_target(c,target)
		"memory":
			return RedKingMind.answer_memory(c,target,at if at is Vector2 else Vector2.ZERO) if target<0 or at is Vector2 else false
		"reality_exit": return RealityCracks.exit_center(c)
		"ring_switch": return c.state.active()!=null and RedKingRingworld.switch(c,c.state.active())
		"ring_escape": return c.state.active()!=null and RedKingRingworld.escape(c,c.state.active())
		"convergence": return at is Vector2 and RealityConvergence.answer(c,at)
		"hunt": return at is Vector2 and RedKingHunt.answer(c,at)
		"hill_seam": return at is Vector2 and RedKingHill.answer_seam(c,at)
		"shift_ruin":
			var index:=int(args.get("piece",-1))
			return at is Vector2 and index>=0 and index<c.state.board.pieces.size() and RealityCrackTerrain.answer_shift(c,index,at)
	return null
