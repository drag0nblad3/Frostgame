extends TestCase


func test_seeded_deck_draw_and_reshuffle() -> void:
	var cards := ["a","b","c","d","e"]
	var a := EventDeck.create(cards,Dice.new(17))
	var b := EventDeck.create(cards,Dice.new(17))
	check_eq(a,b)
	var drawn := []
	for i in cards.size():
		drawn.append(EventDeck.draw(a))
	check_eq(EventDeck.draw(a),null)
	drawn.sort()
	check_eq(drawn,cards)
	check_eq(a["discard"].size(),cards.size())
	EventDeck.reshuffle(a,Dice.new(23))
	check_eq(a["remaining"].size(),cards.size())
	check(a["discard"].is_empty())
	check(BattleSnapshot.plain(a))


func test_development_pack_not_selectable() -> void:
	var core := ContentProfile.new()
	check(not core.allows("scenarios","red_king_squatter"))
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="development"
	var unfinished := ContentProfile.new(["red_king"],packs)
	check(not unfinished.errors().is_empty())
	check(not unfinished.rule("red_king_reality_cracks"))
	var campaign: Dictionary=JsonFile.read("res://data/campaigns/red_king.json")
	check_eq(campaign["stages"].size(),12)
	check_eq(campaign["stages"][6]["campaign_mode"],"ragged_warbands")
