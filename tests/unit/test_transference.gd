extends TestCase


func test_ring_transfers_selected_amount() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 0, Vector2(13, 10)), fig("thug", 1, Vector2(25, 25))], Dice.new(1))
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"gear": "gear_ring_transference"})
	var t := c.state.figure(2)
	t.health -= 3
	check_eq(GearActions.transfer_max(c, t), 3)
	check(not GearActions.transfer(c, t, 4))
	check(GearActions.transfer(c, t, 2))
	check_eq(f.health, 12)
	check_eq(t.health, t.def.health - 1)
	check_eq(f.actions_left, 1)
	check(not GearActions.transfer(c, t, 1))


func test_ring_caster_only() -> void:
	var d := {"units": [{"type": "thug", "dead": false}], "loot": [{"kind": "gear", "gear": "gear_ring_transference", "owner": -1}]}
	check(not CampaignInventory.assign_item(d, 0, 0, db()))
