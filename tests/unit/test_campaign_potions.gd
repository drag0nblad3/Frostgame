extends TestCase


func test_preservation_and_revival() -> void:
	var d := {"games": 1, "units": [{"id": 0, "type": "apprentice", "dead": true, "death_game": 1, "miss": 0, "injuries": 0}], "loot": [{"potion": "preservation", "kind": "potion"}, {"potion": "life", "kind": "potion"}], "last_report": []}
	check(CampaignPotions.use(d, 0, 0, db(), Dice.new(1)))
	d["games"] = 6
	check(CampaignPotions.preserved(d, d["units"][0]))
	check(CampaignPotions.use(d, 0, 0, db(), Dice.new(1)))
	check(not d["units"][0]["dead"])
	check(d["loot"].is_empty())


func test_construct_oil_once() -> void:
	var d := {"games": 1, "units": [{"id": 0, "type": "small_construct", "dead": false, "miss": 0, "injuries": 0}], "loot": [{"potion": "construct_oil", "kind": "potion"}, {"potion": "construct_oil", "kind": "potion"}], "last_report": []}
	check(CampaignPotions.use(d, 0, 0, db(), Dice.new(1)))
	check(d["units"][0]["construct_oiled"])
	check(not CampaignPotions.use(d, 0, 0, db(), Dice.new(1)))
