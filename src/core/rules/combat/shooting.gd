class_name Shooting
extends RefCounted
## Shooting: d20 + Shoot against the target's d20 + Fight + cover. Only the
## shooter can deal damage.

const WRAITH := "gear_rk_wraith_bow"
const LIGHT_COVER := 2
const HEAVY_COVER := 4
const INTERVENING := 1


## Range is measured base edge to base edge.
static func distance(a: Figure, b: Figure) -> float:
	return BattleSpace.edge_distance(a,b)


## Why `shooter` can't shoot `target`, or "" if the shot is allowed.
static func blocked_reason(board: Board, figures: Array[Figure], shooter: Figure, target: Figure,wraith: bool=false,ammo: bool=false) -> String:
	if shooter.spell_effects.has("blinding_light"):
		return "blinded"
	if shooter.ranged == null:
		return "no missile weapon"
	if Swimming.prevents_bow(shooter):
		return "cannot fire bow or crossbow in deep water"
	if shooter.ranged.needs_reload and not shooter.loaded:
		return "needs to reload"
	if not target.in_play() or target == shooter or not IllusionRules.visible_to(figures, shooter, target):
		return "not a target"
	if ammo and (wraith or not MagicAmmo.ready(shooter)):
		return "no enchanted ammunition"
	if RuleHooks.any("objective_figure", [target]) and not ammo and not WeaponActions.magic_attack(shooter,shooter.ranged):
		return "pylon requires magical shooting"
	if target.side == shooter.side and not Contact.in_combat(figures, target):
		return "not an enemy"
	if Contact.in_combat(figures, shooter):
		return "in combat"
	if distance(shooter, target) > shooter.ranged.range_in:
		return "out of range"
	if wraith:
		if not ActiveGear.ready(shooter,WRAITH) or shooter.ranged.id!="bow" or wraith_line(board,shooter,target)==null:
			return "no wraith shot"
	elif not LineOfSight.check_figures(board, shooter, target).clear:
		return "no line of sight"
	return ""


## Could `shooter` shoot `target` if it stood at `at`? (range, sight, target free)
static func possible_from(board: Board, figures: Array[Figure], shooter: Figure, at: Vector2, target: Figure) -> bool:
	return possible_from_world(board,figures,shooter,Vector3(at.x,board.height_at(at),at.y),target)


## Shared candidate-shot test for the movement planner. Current-shot
## authorization still goes through GameController.can_shoot.
static func possible_from_world(board: Board,figures: Array[Figure],shooter: Figure,at: Vector3,target: Figure) -> bool:
	if shooter.ring_side!=target.ring_side or shooter.ranged==null or not target.in_play() or not IllusionRules.visible_to(figures,shooter,target) or Contact.in_combat(figures,target):
		return false
	var relation:=RealityCrackGeometry.cross_relation(board,Vector2(at.x,at.z),target.pos)
	var range_in:=RealityCrackGeometry.world_distance(board,at,Vector3(target.pos.x,target.elevation,target.pos.y))
	if (range_in if relation!=0 else maxf(range_in-2.0*Figure.BASE_RADIUS,0.0))>shooter.ranged.range_in:
		return false
	return LineOfSight.check_from_world(board,shooter,at,target).clear


## Bonus to the target's roll from terrain.
static func target_mod(los: LineOfSight.Result) -> int:
	var m := los.intervening * INTERVENING
	if los.cover == TerrainKind.Cover.HEAVY:
		m += HEAVY_COVER
	elif los.cover == TerrainKind.Cover.LIGHT:
		m += LIGHT_COVER
	return m


## The same situational defence modifier drives previews and resolution.
static func defence_modifier(board: Board,shooter: Figure,target: Figure,wraith: bool=false) -> int:
	var los := BattleSpace.sight(board,shooter,target)
	if wraith:
		var special := wraith_line(board,shooter,target)
		if special!=null:
			los=special
		else:
			los.intervening+=1
	if not wraith and not board.reality_sphere and not board.ringworld and RuleHooks.first("sight",[board,shooter.pos,target.pos,shooter])==null:
		BodySight.cover(board,shooter,BattleSpace.center(shooter),target,los)
	FigureCover.apply(board,shooter,target,BattleSpace.center(shooter)+Vector3.UP*1.5,los)
	return target_mod(los)+(1 if shooter.moves_taken>0 else 0)-(2 if target.def.traits.has("large") else 0)


## Rolls the shot. Returns {s_roll, t_roll, s_total, t_total, mod, dmg}.
static func resolve(dice: Dice, board: Board, shooter: Figure, target: Figure, critical_hits: bool = false, storm_penalty: int = 0) -> Dictionary:
	return resolve_rolls(board, shooter, target, dice.d20(), dice.d20(), critical_hits, storm_penalty)


static func resolve_rolls(board: Board, shooter: Figure, target: Figure, sr: int, tr: int, critical_hits: bool = false, storm_penalty: int = 0,wraith: bool=false,ammo: bool=false) -> Dictionary:
	var mod := defence_modifier(board,shooter,target,wraith)
	var null_target := ScenarioNull.muted(target)
	var magic_shoot := 0 if null_target else (1 if ammo else MagicEquipment.bonus(shooter, "shoot", shooter.ranged.id))
	var magic_damage := 0 if null_target or ammo else MagicEquipment.bonus(shooter, "damage", shooter.ranged.id)
	var magical := not null_target and (ammo or WeaponActions.magic_attack(shooter,shooter.ranged))
	var st := sr + RuleHooks.total("shoot_modifier", [shooter]) + mini(shooter.effective_shoot() + magic_shoot - (0 if null_target else storm_penalty) + (1 if not null_target and not ammo and shooter.spell_effects.has("enchant_weapon") else 0) + (3 if HolyLantern.glow(target) else 0), 10) + shooter.roll_penalty()
	var tt := tr + mini(target.effective_fight() + Melee.secret_hrut_bonus(target,shooter) + mod, 10) + target.roll_penalty() + target.shooting_defence_penalty()
	var dmg := 0
	if (not critical_hits and st > tt) or (critical_hits and tr != 20 and (sr == 20 or st > tt)):
		dmg = Damage.amount(st, shooter.ranged.damage_mod + magic_damage, target.effective_armour() + MagicEquipment.bonus(target, "arrow_armour"), sr, critical_hits and not target.def.traits.has("immune_critical"))
		if dmg > 0 and not null_target and shooter.spell_effects.has("elemental_hammer"):
			dmg += 5
	if (target.spell_effects.has("potion_invulnerability") or target.def.traits.has("immune_normal")) and not magical:
		dmg = 0
	if target.def.traits.has("antithetical_magic") and WeaponActions.magic_attack(shooter,shooter.ranged) and shooter.ranged.id=="genie_bolt":
		dmg=0
	if RuleHooks.any("objective_figure", [target]) and not magical:
		dmg=0
	if target.def.traits.has("missile_resistant") and shooter.ranged.id in ["bow","crossbow","javelin"] and not magical:
		dmg=mini(dmg,2)
	return {"s_roll": sr, "t_roll": tr, "s_total": st, "t_total": tt, "mod": mod, "dmg": dmg}


static func wraith_line(board: Board,f: Figure,t: Figure) -> LineOfSight.Result:
	if not board.floor_layout.is_empty():
		return floor_wraith_line(board,f,t)
	if board.reality_sphere or f.ring_side!=t.ring_side or RuleHooks.first("sight", [board, f.pos, t.pos, f]) != null:
		return null
	var best: LineOfSight.Result=null
	for piece in board.pieces:
		if piece.kind.ground_surface or piece.kind.id in ["red_king_portal","red_king_sinkhole_orb","reality_portal","reality_hoof"] or (not Geom.crosses(f.pos,t.pos,piece.rect) and not piece.rect.has_point(t.pos)):
			continue
		if not piece.kind.blocks_los and piece.kind.cover==TerrainKind.Cover.NONE:
			continue
		var result := LineOfSight.plain_check(board,f.pos,t.pos,f,piece)
		if result.clear and (best==null or target_mod(result)<target_mod(best)):
			best=result
	return best


static func floor_wraith_line(board: Board,f: Figure,t: Figure) -> LineOfSight.Result:
	if f.ring_side!=t.ring_side or board.reality_sphere or (board.darkness and Shooting.distance(f,t)>12.0) or BattleBoundary.blocks_segment(board.boundaries,f.pos,t.pos,"sight",f):
		return null
	var a:=Vector3(f.pos.x,f.elevation+1.5,f.pos.y)
	var b:=Vector3(t.pos.x,t.elevation+1.0,t.pos.y)
	var blocks: Array[AABB]=[]
	for solid in board.floor_geometry().solids:
		if LayeredSight.intersects(a,b,solid):
			blocks.append(solid)
	for p in board.pieces:
		if p.surface_id.is_empty() or not p.kind.blocks_los:
			continue
		var volume:=AABB(Vector3(p.rect.position.x,p.base_height,p.rect.position.y),Vector3(p.rect.size.x,p.kind.height,p.rect.size.y))
		if not blocks.has(volume) and LayeredSight.intersects(a,b,volume):
			blocks.append(volume)
	if blocks.size()>1:
		return null
	var result:=LineOfSight.Result.new()
	LineOfSight.floor_cover(board,Vector3(f.pos.x,f.elevation,f.pos.y),Vector3(t.pos.x,t.elevation,t.pos.y),result)
	if blocks.is_empty():
		if result.cover==0 and result.intervening==0:
			return null
		if result.cover>0:
			result.cover=0
		else:
			result.intervening=maxi(0,result.intervening-1)
	else:
		result.intervening+=1
	return result
