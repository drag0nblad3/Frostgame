class_name PotionActions
extends RefCounted

var c: GameController
var catalog: Dictionary
const POINTS := ["explosive_cocktail", "teleportation"]
const COATINGS := ["poison", "fairy_dust"]
## Only effects that still need floor-aware placement/route contracts.



func _init(controller: GameController) -> void:
	c = controller
	catalog = CampaignInventory.catalog()


func can_drink(id: String, target: Figure = null) -> bool:
	var f := c.state.active()
	if f == null or not f.in_play() or f.spell_effects.has("plane_walk") or f.actions_left <= 0 or c.awaiting_reaction() or not c.state.pending_cast.is_empty() or c.state.group.movement_pass() or Contact.in_combat(c.state.figures, f):
		return false
	if ScenarioNull.muted(f) or ScenarioNull.muted(target) or FuryRules.target(c.state, f) != null:
		return false
	if f.moves_taken > 0 and not c.can_act():
		return false
	if not catalog.has(id) or not catalog[id]["live"] or id in CampaignPotions.VAULT_ONLY:
		return false
	if target == null:
		target = f
	if target != f and (f.def.id != "apothecary" or not target.in_play() or target.side != f.side or Shooting.distance(f, target) > 1.0):
		return false
	if target!=f and not c.state.board.floor_layout.is_empty() and not LineOfSight.check_figures(c.state.board,f,target).clear:
		return false
	if Contact.in_combat(c.state.figures, target):
		return false
	if id in POINTS + COATINGS + ["fire_breath", "empowerment", "darkness", "burrowing", "null", "ethereal_vacuum"] and target != f:
		return false
	if id == "explosive_cocktail" and not c.can_act():
		return false
	if id == "burrowing" and (f.actions_left < 2 or f.moves_taken > 0 or not c.can_move()):
		return false
	if id == "fire_breath" and (f.actions_left < 2 or f.moves_taken > 0):
		return false
	if id == "shatterstar" and (target != f or f.def.role not in ["wizard", "apprentice"] or f.actions_left < 2 or f.moves_taken > 0 or f.acted or f.spell_effects.has("potion_shatterstar")):
		return false
	if id == "empowerment" and (f.def.role not in ["wizard", "apprentice"] or f.empowerment_used):
		return false
	if id in COATINGS and not can_coat(f, id, f.melee) and not can_coat(f, id, f.ranged):
		return false
	if id == "shrinking" and (target.treasure_id < 0 or target.shrunk_treasure_id >= 0):
		return false
	if id == "darkness" and c.state.board.darkness:
		return false
	if id == "healing" and target.health >= target.def.health:
		return false
	return source(f,id,target)>=0


func drink(id: String, target: Figure = null) -> bool:
	var f := c.state.active()
	if target == null:
		target = f
	if not can_drink(id, target) or id in POINTS + COATINGS:
		return false
	var success := _consume(f,id,target)
	_spend_drink(f)
	if not success:
		return true
	match id:
		"shrinking":
			target.shrunk_treasure_id = target.treasure_id
			target.spell_effects["potion_shrinking"] = true
		"null":
			GlobalConsumables.nullify(c)
		"ethereal_vacuum":
			GlobalConsumables.vacuum(c, f)
		"elemental_absorption":
			target.spell_effects["potion_elemental_absorption"] = 5
		"fire_breath":
			f.spell_effects["potion_fire_breath"] = true
		"empowerment":
			f.empowerment_used = true
			f.spell_effects["potion_empowerment"] = true
		"darkness":
			c.state.board.darkness = true
			c.emit("darkness", {"id": f.id})
		"healing":
			c._magic._heal(target, 5)
		"restoration":
			c._magic._heal(target, target.def.health)
			target.poisoned = false
			for effect in ["slow", "curse", "furious_quill", "petrify", "blinding_light", "plague_of_insects"]:
				target.spell_effects.erase(effect)
			target.petrified_skip = false
		"invisibility":
			target.spell_effects["invisibility"] = true
			c._magic.illusions.sweep()
		_:
			target.spell_effects["potion_" + id] = true
	_report(f, target, id)
	return true


func source(f: Figure,id: String,target: Figure=null) -> int:
	var ordinary := -1
	for i in f.items.size():
		var item: Dictionary=f.items[i]
		if item.get("potion","")!=id:
			continue
		var gear := str(item.get("gear",""))
		if gear in [RedKingCampaignGear.POTION_STAFF,RedKingCampaignGear.GOLDEN_BOTTLE]:
			if MagicEquipment.suppressed(f) or (target!=null and target!=f) or (gear==RedKingCampaignGear.POTION_STAFF and f.destroyed_weapons.has("staff")) or (gear==RedKingCampaignGear.GOLDEN_BOTTLE and int(item.get("bottle_doses",0))<=0):
				continue
		if item.get("enchanted",false):
			return i
		if ordinary<0:
			ordinary=i
	return ordinary


func _consume(f: Figure,id: String,target: Figure=null) -> bool:
	var index := source(f,id,target)
	if index<0:
		return false
	var item: Dictionary=f.items[index]
	var gear := str(item.get("gear",""))
	if gear==RedKingCampaignGear.POTION_STAFF:
		item.erase("potion")
		return true
	if gear==RedKingCampaignGear.GOLDEN_BOTTLE:
		item["bottle_doses"]=int(item["bottle_doses"])-1
		if int(item["bottle_doses"])==0:
			item.erase("potion")
		var roll := c.dice.d20()
		var success := StatRoll.succeeds(roll,f.effective_will()+f.roll_penalty(),4)
		c.emit("creature_test",{"id":f.id,"trait":"golden_bottle","roll":roll,"success":success})
		if not success:
			c.poison(f)
		return success
	var roll := RedKingMaterials.use_potion(f.items,index,c.dice)
	if roll>0:
		c.emit("enchanted_vial",{"id":f.id,"roll":roll,"retained":roll>=19})
	return true

func _spend_drink(f: Figure) -> void:
	if f.moves_taken == 0 and not c.state.group.in_progress():
		f.actions_left -= 1
	else:
		c._spend(f)
	

func _report(f: Figure, target: Figure, id: String) -> void:
	c.emit("potion_used", {"id": f.id, "target": target.id, "potion": id})
	c.emit("spell_effect", {"id": target.id, "spell": "potion_" + id})


func can_place(id: String, at: Vector2) -> bool:
	if not c.state.board.floor_layout.is_empty() or not can_drink(id):
		return false
	var f := c.state.active()
	if id == "teleportation":
		return c._magic.movement.can_land(f, f, "teleport", at)
	return id == "explosive_cocktail" and c.state.board.contains(at) and f.pos.distance_to(at) <= 8.0 and LineOfSight.check(c.state.board, f.pos, at).clear


func points(id: String) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if not can_drink(id):
		return out
	var f := c.state.active()
	if id == "teleportation":
		return c._magic.movement.points(f, f, "teleport")
	for x in range(-8, 9):
		for y in range(-8, 9):
			var at := f.pos.round() + Vector2(x, y)
			if can_place(id, at):
				out.append(at)
	return out


func use_at(id: String, at: Vector2) -> bool:
	if not can_place(id, at):
		return false
	var f := c.state.active()
	var success := _consume(f,id)
	if id=="teleportation":
		_spend_drink(f)
		if success:
			c._magic.movement.move(f,at,true)
	else:
		c._spend(f)
		if success:
			c._magic.terrain.apply(f,"grenade",at,false)
	if not success:
		return true
	_report(f, f, id)
	return true


func cocktail_floor_legal(n: Vector3i) -> bool:
	if c.state.board.floor_layout.is_empty() or not can_drink("explosive_cocktail"):
		return false
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	if not layout.contains(n,0.0):
		return false
	var at:=layout.world(n)
	return Vector3(f.pos.x,f.elevation,f.pos.y).distance_to(at)<=8.001 and c._magic.terrain.can_place_floor(f,"grenade",n)


func cocktail_floor_points(index: int=-1,first_only: bool=false) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	if c.state.board.floor_layout.is_empty() or not can_drink("explosive_cocktail"):
		return out
	for n in BattlePlacement.nodes(c.state.board,c.state.active().pos,8.0,index):
		if cocktail_floor_legal(n):
			out.append(n)
			if first_only:
				break
	return out


func cocktail_on_floor(n: Vector3i) -> bool:
	if not cocktail_floor_legal(n):
		return false
	var f:=c.state.active()
	var layout:=c.state.board.floor_geometry()
	var success:=_consume(f,"explosive_cocktail")
	c._spend(f)
	if success:
		c._magic.terrain.apply(f,"grenade",layout.point(n),false,14,false,layout.surface_id(n))
		_report(f,f,"explosive_cocktail")
	return true


func teleport_floor_points(index: int=-1,first_only: bool=false) -> Array[Vector3i]:
	if c.state.board.floor_layout.is_empty() or not can_drink("teleportation"):
		return []
	return BattlePlacement.teleports(c.state,c.state.active(),24.0,index,first_only)


func teleport_on_floor(n: Vector3i) -> bool:
	var f:=c.state.active()
	if c.state.board.floor_layout.is_empty() or not can_drink("teleportation") or not BattlePlacement.teleport_legal(c.state,f,n):
		return false
	var success:=_consume(f,"teleportation")
	_spend_drink(f)
	if success:
		c._magic.movement.move_floor(f,n,true,false,"teleport")
		_report(f,f,"teleportation")
	return true


static func can_coat(f: Figure, id: String, w: WeaponDef) -> bool:
	if w == null or w.id in ["natural", "unarmed"] or f.destroyed_weapons.has(w.id):
		return false
	if id == "poison":
		return w.id != "staff" and f.poison_weapon == ""
	return id == "fairy_dust" and not WeaponActions.magical(f, w) and not f.spell_effects.has("potion_fairy_dust")


func coat(id: String, ranged: bool) -> bool:
	var f := c.state.active()
	if not can_drink(id):
		return false
	var w := f.ranged if ranged else f.melee
	if not can_coat(f, id, w):
		return false
	var success := _consume(f,id)
	_spend_drink(f)
	if not success:
		return true
	if id == "poison":
		f.poison_weapon = w.id
	else:
		f.spell_effects["potion_fairy_dust"] = w.id
	_report(f, f, id)
	return true


func can_breathe(t: Figure) -> bool:
	var f := c.state.active()
	return c.can_act() and f.spell_effects.has("potion_fire_breath") and not f.spell_effects.has("blinding_light") and t != null and t != f and t.in_play() and t.side != f.side and IllusionRules.visible_to(c.state.figures, f, t) and not BeautyActions.blocked(c.state, f, t) and Shooting.distance(f, t) <= 6.0 and LineOfSight.check_figures(c.state.board,f,t).clear


func breathe(t: Figure) -> bool:
	if not can_breathe(t):
		return false
	var f := c.state.active()
	c._magic.beauty.authorize(f, ShotTarget.participants(c.state.figures, t), _breathe_authorized.bind(f, t))
	return true


func _breathe_authorized(f: Figure, t: Figure) -> void:
	if not f.in_play() or not t.in_play():
		return
	f.spell_effects.erase("potion_fire_breath")
	c._spend(f)
	c._magic.illusions.reveal(f)
	c._magic._shot(f, ShotTarget.randomize(c.dice, c.state.figures, t), 3, f.pos, true)


static func absorb(t: Figure, damage: int) -> int:
	var pool := int(t.spell_effects.get("potion_elemental_absorption", 0))
	var amount := mini(pool, damage)
	if amount > 0:
		if pool == amount:
			t.spell_effects.erase("potion_elemental_absorption")
		else:
			t.spell_effects["potion_elemental_absorption"] = pool - amount
	return damage - amount
