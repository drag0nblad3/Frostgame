extends TestCase


func test_crypt_and_tower_ritual_bonuses() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["games"] = 1
	p.data["spells"] = {"raise_zombie": 10, "awareness": 12}
	check(p.choose_base("crypt"))
	check(Rituals.attempt(p.data, 0, "raise_zombie", "", LoadedDice.new([8])))
	check(p.data["prepared_zombie"])
	check_eq(p.deployment()["figures"][0]["campaign_base"], "crypt")
	check(p.choose_base("tower"))
	check(Rituals.attempt(p.data, 0, "awareness", "", LoadedDice.new([10])))
	check(p.data["units"][0]["awareness"])


func test_base_bonus_values() -> void:
	check_eq(BaseRules.casting_bonus("temple", "miraculous_cure"), 3)
	check_eq(BaseRules.casting_bonus("crypt", "animate_skull"), 2)
	check_eq(BaseRules.casting_bonus("library", "heal"), 0)
