class_name RedKingMindRewards
extends RefCounted
## Bonus round: no standard treasure, survival, or base income rolls.
## Special rewards are retained as explicit entitlements for later integration.
static func settle(data: Dictionary,c: GameController,side: int) -> bool:
	if side!=0 or not c.state.over or not data.get("red_king_secured_kalamon",false):
		return false
	var cards: Array=c.state.scenario_data.get("mind_rewards",[])
	var xp := 0
	var report: Array[String]=[]
	for card: String in cards:
		match card:
			"A","K": xp+=10
			"Q","J": xp+=15
			"10","9": xp+=20
			"8":
				data["red_king_secret_hrut"]=true
				report.append("Secret of the Hrut earned for a future encounter.")
			"7":
				data["red_king_survival_reroll"]=true
				report.append("One future wizard survival reroll earned.")
			"6","5":
				var pending: Array=data.get("red_king_pending_rewards",[])
				pending.append("treasure" if card=="6" else "artefact")
				data["red_king_pending_rewards"]=pending
				report.append("Expansion reward roll reserved.")
	var wizard := RedKingMind.wizard(c.state)
	if wizard!=null and ActiveGear.has(wizard,"gear_rk_ring_of_destiny"):
		xp+=20
	data["xp"]=int(data.get("xp",0))+xp
	data["red_king_secured_kalamon"]=false
	data["red_king_mind_completed"]=true
	report.push_front("Mindscape: %d memories, +%d XP. No survival roll."%[cards.size(),xp])
	data["last_report"]=report
	for kind: String in data.get("red_king_pending_rewards",[]):
		var id := "artefact" if kind=="artefact" else RedKingRewards.result(c.dice.d20(),c.dice.d20())
		RedKingRewards.award(data,id,c.dice)
	data.erase("red_king_pending_rewards")
	return true


static func secret_selected(data: Dictionary) -> bool:
	return bool(data.get("red_king_secret_hrut",false)) and bool(data.get("red_king_use_secret_hrut",false)) and RedKingCampaign.next_id(data)!="red_king_mind"


## Choice: 0 decline, 1 reroll but keep original, 2 accept reroll.
## Headless callers retain the previous automatic policy.
static func survival_roll(data: Dictionary,raw: int,dice: Dice,choice: int=-1) -> int:
	if not data.get("red_king_survival_reroll",false):
		return raw
	data.erase("red_king_survival_reroll")
	if choice==0:
		return raw
	if choice in [1,2]:
		var second := dice.d20()
		return raw if choice==1 else second
	return maxi(raw,dice.d20()) if raw+1<=8 else raw


static func survival_outcome(data: Dictionary,s: GameState,f: Figure,raw: int) -> String:
	var roll := raw+(0 if f.used_gear.get(DeathMask.EVER,false) else 1)
	if ActiveGear.has(f,"gear_rk_ring_of_destiny"):
		roll=RedKingGear.destiny_survival(roll)
	var outcome := "Full recovery"
	if roll<=2:
		outcome="Death"
	elif roll<=4:
		outcome="Permanent injury"
	elif roll<=6:
		outcome="Recover with sarcophagus" if not RedKingCampaign.suppress_base_after(data,s.scenario_special) and data.get("resources",[]).has("sarcophagus_of_healing") else "Miss next battle"
	elif roll<=8:
		outcome="Lose carried items"
	return "%d — %s"%[roll,outcome]
