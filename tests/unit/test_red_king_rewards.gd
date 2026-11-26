extends TestCase


func test_tables_and_central_bonus() -> void:
	var table := RedKingRewards.tables()
	check_eq(table["first"].size(),19)
	check_eq(table["second"].size(),19)
	check_eq(table["artefacts"].size(),20)
	check_eq(RedKingRewards.result(1,1),"gear_rk_lantern_of_holy_light")
	check_eq(RedKingRewards.result(20,19),"gear_rk_book_of_wisdom")
	check_eq(RedKingRewards.result(2,20),"artefact")
	var d := {"loot":[],"last_report":[],"pending_treasure":[{"token":0,"central":true,"rk_exchange":true,"first":12},{"token":1,"central":true,"rk_artefact":true,"first":10}]}
	check(RedKingRewards.exchange(d,Dice.new(14)))
	check(d["pending_treasure"][0].has("rk_roll"))
	check_eq(RedKingRewards.offer(d,d["pending_treasure"][0]),"")
	d["pending_treasure"][0]["rk_roll"]=[1,18]
	check(RedKingRewards.resolve_bonus(d,true,Dice.new(14)))
	check_eq(d["loot"].size(),1)
	check(RedKingRewards.catalog()[d["loot"][0]["gear"]]["artefact"])
	check(not d["loot"][0]["unlocked"])
	check_eq(RedKingRewards.offer(d,d["pending_treasure"][0]),"")


func test_artefact_uniqueness() -> void:
	var d := {"loot":[],"last_report":[]}
	var dice := Dice.new(84)
	for i in 20:
		check(RedKingRewards.award(d,"artefact",dice))
	check_eq(d["red_king_found_artefacts"].size(),20)
	check(not RedKingRewards.award(d,"artefact",dice))
	check_eq(d["loot"].size(),20)
