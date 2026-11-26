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
	return bool(data.get("red_king_secret_hrut",false)) and bool(data.get("red_king_use_secret_hrut",false)) and RedKingCampaign.active(data) and RedKingCampaign.next_id(data)!="red_king_mind"


## The next wizard survival check consumes the entitlement. Digital policy:
## retain the original if already fully recovered; otherwise keep the higher roll.
static func survival_roll(data: Dictionary,raw: int,dice: Dice) -> int:
	if not data.get("red_king_survival_reroll",false):
		return raw
	data.erase("red_king_survival_reroll")
	return maxi(raw,dice.d20()) if raw+1<=8 else raw
