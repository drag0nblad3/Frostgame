class_name BattleEquipmentAction
extends RefCounted
## Stable command payloads shared by input, AI and replay. The existing gear
## and potion rules remain responsible for validation and effects.


static func points(c: GameController,key: String,index: int=-1) -> Array:
	var layered := not c.state.board.floor_layout.is_empty()
	match key:
		"ring_teleport":
			return GearActions.teleport_floor_points(c,index) if layered else GearActions.teleport_points(c)
		"bottle_imp":
			return GearActions.bottle_floor_points(c).keys() if layered else GearActions.bottle_points(c)
		"potion_teleportation":
			return c._potions.teleport_floor_points(index) if layered else c._potions.points("teleportation")
		"potion_explosive_cocktail":
			return c._potions.cocktail_floor_points(index) if layered else c._potions.points("explosive_cocktail")
	return []


static func execute(c: GameController,key: String,args: Dictionary={}) -> bool:
	if not BattleSnapshot.plain(args):
		return false
	return BattleRecord.run(c,"equipment",{"key":key,"args":args},func() -> bool: return _apply(c,key,args))


static func _apply(c: GameController,key: String,args: Dictionary) -> bool:
	var at: Variant=args.get("at")
	var layered := not c.state.board.floor_layout.is_empty()
	match key:
		"ring_teleport","bottle_imp","potion_teleportation","potion_explosive_cocktail":
			if (layered and not at is Vector3i) or (not layered and not at is Vector2):
				return false
			if layered and (at.z<0 or at.z>=c.state.board.floor_geometry().surfaces.size()):
				return false
			match key:
				"ring_teleport":
					return GearActions.teleport_on_floor(c,at) if layered else GearActions.teleport(c,at)
				"bottle_imp":
					return GearActions.bottle_on_floor(c,at) if layered else GearActions.bottle_imp(c,at)
				"potion_teleportation":
					return c._potions.teleport_on_floor(at) if layered else c._potions.use_at("teleportation",at)
				"potion_explosive_cocktail":
					return c._potions.cocktail_on_floor(at) if layered else c._potions.use_at("explosive_cocktail",at)
		"drink":
			var target := c.state.figure(int(args.get("target",-1)))
			if args.has("target") and target==null:
				return false
			return c._potions.drink(str(args.get("id","")),target)
		"coat":
			return c._potions.coat(str(args.get("id","")),bool(args.get("ranged",false)))
		"breathe":
			return c._potions.breathe(c.state.figure(int(args.get("target",-1))))
		"arm":
			return GearActions.arm(c,str(args.get("id","")))
		"transfer":
			return GearActions.transfer(c,c.state.figure(int(args.get("target",-1))),int(args.get("amount",0)))
		"horn":
			var index := int(args.get("piece",-1))
			if index<0 or index>=c.state.board.pieces.size():
				return false
			return GearActions.horn(c,c.state.board.pieces[index])
		_:
			var result: Variant=RuleHooks.first("equipment_command",[c,key,args])
			return bool(result) if result!=null else false
	return false
