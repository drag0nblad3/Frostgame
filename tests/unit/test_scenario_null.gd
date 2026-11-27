extends TestCase


func test_silent_tower_layout_and_magic() -> void:
	var s := ScenarioLoader.load_id("silent_tower", db(), terrain())
	var c := GameController.new(s, Dice.new(7))
	var f := s.figure(1)
	var t := s.figure(2)
	f.pos = Vector2(18, 18)
	f.surface_id="tower_roof"
	f.elevation=s.board.floor_geometry().height(s.board.floor_geometry().node(f.surface_id,f.pos))
	f.actions_left = 2
	s.active_id = f.id
	check_eq(f.elevation, 10.0)
	f.spell_effects["strength"] = true
	f.spell_effects["fleet_feet"] = true
	f.elemental_shield = 3
	f.items.append({"gear": "gear_ring_power1", "gear_info": {"type": "ring", "bonus": {"will": 2}}})
	f.items.append({"potion": "healing"})
	f.health -= 2
	ScenarioNull.enter(c, f)
	check(f.spell_effects.is_empty())
	check_eq(f.elemental_shield, 0)
	check_eq(MagicEquipment.bonus(f, "will"), 0)
	check_eq(PowerPool.available(f), 0)
	check(not c._potions.can_drink("healing"))
	check(not c.can_cast("strength", f.id))
	check_eq(c.history.back().data["xp"], 40)
	var count := c.history.size()
	ScenarioNull.enter(c, f)
	check_eq(c.history.size(), count)
	check(not c._magic.movement.can_land(t, t, "teleport", f.pos))
	check(ScenarioNull.protected_treasure(s, Vector2(18, 18)))
	check(ScenarioNull.protected_treasure(s, Vector2(10, 18)))
	check(not ScenarioNull.protected_treasure(s, Vector2(5, 5)))
	f.pos = Vector2(18, 8)
	f.surface_id="street"
	f.elevation = 0
	check_eq(MagicEquipment.bonus(f, "will"), 2)
	check_eq(PowerPool.available(f), 1)
	check(c.can_cast("strength", f.id))


func test_silent_tower_real_move_cancels_magic() -> void:
	var s := ScenarioLoader.load_id("silent_tower", db(), terrain())
	var c := GameController.new(s, Dice.new(4))
	var f := s.figure(1)
	f.pos = Vector2(18, 13.5)
	f.actions_left = 2
	f.spell_effects["fleet_feet"] = true
	s.active_id = f.id
	s.forced_combat = false
	check(c.move_on_floor(s.board.floor_geometry().node("street",Vector2(18,15.5))))
	check(f.spell_effects.is_empty())
	check(s.tower_visitors.has(f.id))
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c), db())
	check(restored != null)
	check(restored.state.tower_visitors.has(f.id))
	check(ScenarioNull.muted(restored.state.figure(f.id)))
